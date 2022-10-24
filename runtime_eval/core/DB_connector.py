# Database Connectors
import pyodbc
import signal
import subprocess
from threading import Timer
from core.cardinality_estimation_quality.cardinality_estimation_quality import *
import numpy as np
import pandas as pd
import xml.etree.ElementTree as ET
import xmltodict, json
import sqlite3 as sql
from collections import *
import subprocess, threading
import logging as logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

## import couchbase stuffs
# import couchbase.search as FT
# import couchbase.subdocument as SD
# # import jwt  # from PyJWT
# from couchbase.cluster import Cluster, ClusterOptions, PasswordAuthenticator, ClusterTimeoutOptions
# from couchbase.exceptions import *
# from couchbase.search import SearchOptions
# from couchbase.exceptions import TimeoutException

import time
import json
from datetime import timedelta
import re
import signal

class Postgres_Connector:
    def __init__(self, server='localhost', username='postgres', password='postgres', db_name='imdbload'):
        self.server = server
        self.username = username
        self.password = password
        self.db_name = db_name

        if db_name:
            self.db_url = f"host={server} port=5432 user={username} dbname={db_name} password={password} options='-c statement_timeout={6000000}' "
            self.init_db(db_name)
    
    def _reset_connection(self,):
        if self.db_name:
            self.db_url = f"host={server} port=5432 user={username} dbname={db_name} password={password} options='-c statement_timeout={600000}' "
            self.init_db(db_name)
        else:
            logging.info("Database name not defnied.")

    def init_db(self, db_name):
        db = self.db_url.format(db_name)
        PG = Postgres(db)
        self.db = PG
        return PG

    def disable_parallel(self):
        logging.warning("parallel disabled.")
        self.execute(
            'LOAD \'pg_hint_plan\';SET max_parallel_workers_per_gather=0;SET max_parallel_workers=0;', set_env=True)

    def explain(self, query, execute=False):
        q = QueryResult(None)
        q.query = query
        q.explain(self.db, execute=execute, timeout=0)
        return self.extract_explained_CardEst_qualities(q.result)

    # def execute(self, query, set_env=False, timeout=None, disable_lip=None, show_plan=False, disable_parallel=False, disable_nestloop=False):
    #     if disable_parallel:
    #         self.disable_parallel()
        
    #     if disable_nestloop:
    #         logging.warning("Nested loop join is disabled. ")
    #         self.execute('SET enable_nestloop to FALSE;', set_env=True)
    #         query = query.replace("NestLoop", "HashJoin")

    #     # ==============================
    #     # res = self.db.execute(f"EXPLAIN {query};", set_env=False)
    #     # print(res)
    #     # print(query)
    #     # ==============================

    #     if show_plan:
    #         if 'explain analyze' not in query:
    #             if '*/' in query: # when there is pg_hint_plan
    #                 query = query.replace('*/', '*/ EXPLAIN ANALYZE VERBOSE ')
    #             else:
    #                 query = 'EXPLAIN ANALYZE VERBOSE ' + query
        
    #     start_time = time.time()
    #     res = self.db.execute(query, set_env=set_env)
    #     end_time = time.time()
        
    #     if res is not None:
    #         q = {
    #             'execution_cost':  # end_time - start_time,
    #             'result_size': len(res),
    #             'result_rows': res,
    #             'end_to_end_executing_cost'
    #         }
    #     else:
    #         q = {
    #             'execution_cost': end_time - start_time
    #         }
    #     if show_plan:
    #         q['plan'] = res
    #     # print(res)
    #     if disable_nestloop:
    #         self.execute('SET enable_nestloop to TRUE;', set_env=True)
    #     return q

    def execute(self, query, set_env=False, timeout=None, disable_lip=None, show_plan=False, disable_parallel=False, disable_op=None):
        if disable_parallel:
            self.disable_parallel()
        
        if disable_op is not None and not set_env:
            assert disable_op in ['nestloop', 'mergejoin', 'both'], f'not supported op disabling {disable_op}'
            logging.warning(f"{disable_op} join is disabled. ")
            if disable_op == 'both':
                self.execute(f'SET enable_nestloop to FALSE;', set_env=True)
                self.execute(f'SET enable_mergejoin to FALSE;', set_env=True)
            else:
                self.execute(f'SET enable_{disable_op} to FALSE;', set_env=True)

        # ==============================
        # res = self.db.execute(f"EXPLAIN {query};", set_env=False)
        # print(res)
        # print(query)
        # ==============================

        if show_plan:
            if 'explain' not in query.lower():
                if '*/' in query: # when there is pg_hint_plan
                    query = query.replace('*/', '*/ EXPLAIN ANALYZE VERBOSE ')
                else:
                    query = 'EXPLAIN ANALYZE VERBOSE ' + query
        
        start_time = time.time()
        q, res = None, None
        # if not set_env :
        #     q = QueryResult(None)
        #     q.query = query
        #     # try:
        #     q.explain(self.db, execute=True, timeout=0 if timeout is None else timeout*1000)
        #     # except Exception as e:
        #     #     q.execution_cost = -timeout
        #     #     q.cardinalities = {'actual': -1}
        # else:
        if True:
            res = self.db.execute(query, set_env=True)
        end_time = time.time()
        
        if q is not None:
            ret = {
                'execution_cost': q.execution_time/1000, # end_time - start_time,
                'result_size': q.cardinalities['actual'],
                'result_rows': q.cardinalities['actual'],
                'end_to_end_executing_cost': end_time - start_time
            }
            if show_plan:
                ret['plan'] = q.query_plan
        else:
            ret = {
                'execution_cost': end_time - start_time,
                'end_to_end_executing_cost': end_time - start_time,
                # 'result_size': q.cardinalities['actual'],
                'result_rows': res
            }        

        if disable_op is not None and not set_env:
            if disable_op == 'both':
                self.execute(f'SET enable_nestloop to TRUE;', set_env=True)
                self.execute(f'SET enable_mergejoin to TRUE;', set_env=True)
            else:
                self.execute(f'SET enable_{disable_op} to TRUE;', set_env=True)

        return ret


    def extract_explained_CardEst_qualities(self, q_dict):
        all_quality_pairs = []
        def parse_json_node(plan_dict_node):
            if len(all_quality_pairs) > 0:
                return
            if isinstance(plan_dict_node, dict):
                if 'Actual Rows' in plan_dict_node and 'Plan Rows' in plan_dict_node:
                    all_quality_pairs.append((plan_dict_node['Actual Rows'], plan_dict_node['Plan Rows']))
                    # print("found qualities: ")
                for node in plan_dict_node:
                    parse_json_node(plan_dict_node[node])
            elif isinstance(plan_dict_node, list):
                for node in plan_dict_node:
                    parse_json_node(node)
            else:
                pass
        parse_json_node(q_dict)
        return all_quality_pairs[0]


class Mssql_Connector:
    
    def __init__(self, server='localhost', username='SA', password='SQLServer123', db_name=None):

        self.server = server
        self.username = username
        self.password = password
        self.db_name = db_name

        if db_name:
            cnxn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' +
                                  server+';DATABASE='+db_name+';UID='+username+';PWD=' + password)
            cursor = cnxn.cursor()
            self.cursor = cursor
            # cnxn.commit()
            # self.cursor.execute(f'USE master; ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ADAPTIVE_JOINS = OFF; USE {db_name};')
            # cnxn.commit()

    # def _prevent_int_overflow(self, query):
    #     if 'count' in query.lower():
    #         query = query.replace('COUNT', 'COUNT_BIG')
    #         query = query.replace('count', 'COUNT_BIG')
    #     if 'sum(' in query.lower():
    #         query = query.replace('SUM(', 'SUM(CONVERT(BIGINT, ')
    #         SUM(CONVERT(BIGINT, t.Amount))

    
    def execute(self, query, set_env=False):
        if not set_env:
            # print("Executing query: {}".format(query))
            # if 'go' not in query.lower():
                # query += ''
            start_time = time.time()
            # try:
            self.cursor.execute(query)
            # except:
            #     print(f"Error in query: \n{query}")
            res_size = 0
            rows = []
            row = self.cursor.fetchone()
            while row:
                rows.append(row)
                row = self.cursor.fetchone()
                res_size += 1
            end_time = time.time()
            q = {
                'execution_cost': end_time - start_time,
                'result_size': res_size,
                'result_rows': rows
            }
            # exit(1)
            return q
        else:
            self.cursor.execute(query)

    def explain(self, query, execute=True):
        # getting the query plan with XML format

        # self.execute('SET SHOWPLAN_TEXT ON;', set_env=True)
        # self.execute('SET SHOWPLAN_ALL ON;', set_env=True)
        self.execute('SET SHOWPLAN_XML ON;', set_env=True)
        # self.execute('SET STATISTICS PROFILE ON;', set_env=True)
        # self.execute('SET STATISTICS XML ON;', set_env=True)

        # self.execute('SET SHOWPLAN_XML OFF;', set_env=True)
        # self.execute(
        #     'ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_ADAPTIVE_JOINS = OFF;', set_env=True)

        self.cursor.execute(query)
        rows = []
        row = self.cursor.fetchall()
        while row:
            rows.append(row)
            row = self.cursor.fetchall()
        self.execute('SET SHOWPLAN_XML OFF;', set_env=True)
        
        raw_xml_plan = rows[0][0][0]
        est_card = self.extract_explained_CardEst_qualities(raw_xml_plan)
        actual_rows = self.execute(query.replace('*', 'COUNT(*)'))['result_rows'][0][0]
        return (actual_rows, int(float(est_card)))

    def extract_explained_CardEst_qualities(self, raw_xml_plan):
        plan_root = ET.fromstring(raw_xml_plan)

        def search_plan_nodes(root):
            if 'RelOp' in root.tag:
                return root.attrib['EstimateRows']
            for c in root:
                n = search_plan_nodes(c)
                if n is not None:
                    return n
        est_card = search_plan_nodes(plan_root)
        return est_card


class SQLite_Connector:
    def __init__(self, db_file_dir='/mnt/sqlite_storage/imdb/', db_name='imdb.db', cmd_execute=True):
        if not cmd_execute:
            self.conn = sql.connect(os.path.join(db_file_dir, db_name), timeout=10)
            self.cursor = self.conn.cursor()
            self.execute('analyze;')
        else:
            self.db_file_dir = db_file_dir
            self.db_name = db_name
            self.cmd_execute('analyze;')

    def explain(self, query, execute=False):
        pass

    def execute_timer_thread(self, query):
        cursor = self.conn.cursor()
        cursor.execute(query)

    def _sql_rm_comments(self, sql):
        q = ''
        for l in sql.split('\n'):
            if l.strip(' ').startswith('--'):
                continue
            else:
                q += l + '\n'
        return q

    def cmd_execute(self, query, timeout=None, disable_lip=False):
        # subprocess.call(["sqlite3", "xxx.db", ".mode tabs", ".import file.tsv table_name"])
        query = self._sql_rm_comments(query)
        
        if disable_lip:
            cmds = [
                'sqlite3', 
                f'{os.path.join( self.db_file_dir, self.db_name)}',
                '-cmd',
                '.testctrl optimization 0x00080000',
                query
            ]
            logging.info("LIP optimization is disabled.")
            # subprocess.run(cmds)
            # cmds = [
            #     'sqlite3', 
            #     f'{os.path.join( self.db_file_dir, self.db_name)}',
            #     '-cmd',
            #     '.testctrl optimization 0x00100000'
            # ]
            # subprocess.run(cmds)
        
        else:
            cmds = [
                'sqlite3', 
                f'{os.path.join( self.db_file_dir, self.db_name)}',
                query
            ]

        q = {}
        try:
            start_time = time.time()
            executor = subprocess.run(cmds, timeout=timeout)
            end_time = time.time()
            q['execution_cost'] = end_time - start_time
        except Exception as exc:
            logging.warning(f"Error msg: {exc}")
            q['execution_cost'] = -1
        finally:
            if disable_lip:
                cmds = [
                    'sqlite3', 
                    f'{os.path.join( self.db_file_dir, self.db_name)}',
                    '-cmd',
                    '.testctrl optimization 0',
                    ''
                ]
                subprocess.run(cmds)
            return q

    def execute(self, query, timeout=None, disable_lip=False, show_plan=True):
        if show_plan:
            self.cmd_execute("EXPLAIN QUERY PLAN " + query, timeout, disable_lip=disable_lip)
        return self.cmd_execute(query, timeout, disable_lip=disable_lip)

        # def _handler():
        #     logging.warning(f"Error in executing {query} with timeout {timeout}")
        #     signal.alarm(0)
        #     raise Exception("End of execution time.")
        
        # if disable_lip: 
        #     self.execute('.testctrl optimization 0x00080000')
        #     self.execute('.testctrl optimization 0x00100000')
        
        # q = {}
        # start_time = time.time()

        # try:
        #     self.cursor.execute(query)          
        # except Exception as exc:
        #     logging.warning(f"Error msg: {exc}")
        #     q['execution_cost'] = -1
        #     return q

        # rows = self.cursor.fetchall()
        # end_time = time.time()
        # q = {
        #     'execution_cost': end_time - start_time,
        #     'result_size': len(rows),
        #     'result_rows': rows
        # }
            
        # if disable_lip: 
        #     self.execute('.testctrl optimization 0')
        
        # # signal.alarm(0)
        
        # return q

    def extract_explained_CardEst_qualities(self, q_dict):
        pass


class DB_instance:

    def __init__(self, engine_name, db_name):
        self.engine_name = engine_name
        self.db_name = db_name
        if engine_name == 'postgres':
            self.connector = Postgres_Connector(db_name=db_name)
        elif engine_name == 'postgres_pg_lip':
            self.connector = PG_LIP_Connector(db_name=db_name)
        elif engine_name == 'mssql':
            self.connector = Mssql_Connector(db_name=db_name)
        elif engine_name == 'sqlite':
            self.connector = SQLite_Connector(db_file_dir=f'/mnt/sqlite_storage/{db_name}/', db_name=f'{db_name}.db')
        else:
            assert False, f"{engine_name} not implemented"  

    def show_db_info(self):
        if self.engine_name == 'postgres':
            q = f"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' and table_catalog = '{self.db_name}';"
            rows = self.execute(q, set_env=True, show_plan=False)['result_rows']
            self.table_sizes = {}
            for t in rows:
                self.table_sizes[t[0]] = 0
            for t in self.table_sizes:
                q = f"SELECT COUNT(*) FROM {t};"
                self.table_sizes[t] = self.execute(q, set_env=True, show_plan=False)['result_rows'][0][0]
                print(f"Table {t}, with {self.table_sizes[t]} rows.")

        if self.engine_name == 'mssql':
            q = f"SELECT TABLE_NAME FROM {self.db_name}.INFORMATION_SCHEMA.TABLES;;"
            rows = self.execute(q)['result_rows']
            self.table_sizes = {}
            for t in rows:
                self.table_sizes[t[0]] = 0
            for t in self.table_sizes:
                q = f"SELECT COUNT(*) FROM {t};"
                self.table_sizes[t] = self.execute(q)['result_rows'][0][0]
                print(f"Table {t}, with {self.table_sizes[t]} rows.")
        
        # if self.engine_name == 'mssql':
        #     q = f"SELECT TABLE_NAME FROM {self.db_name}.INFORMATION_SCHEMA.TABLES;;"
        #     rows = self.execute(q)['result_rows']
        #     self.table_sizes = {}
        #     for t in rows:
        #         self.table_sizes[t[0]] = 0
        #     for t in self.table_sizes:
        #         q = f"SELECT COUNT(*) FROM {t};"
        #         self.table_sizes[t] = self.execute(q)['result_rows'][0][0]
        #         print(f"Table {t}, with {self.table_sizes[t]} rows.")

    def execute(self, query, timeout=None, disable_lip=False, show_plan=True, disable_parallel=False, disable_op=None, set_env=False):
        return self.connector.execute(query, timeout=timeout, disable_lip=disable_lip, show_plan=show_plan, 
                                      disable_parallel=disable_parallel,
                                      disable_op=disable_op, set_env=set_env)

    def explain_card(self, query):
        return self.connector.explain(query, execute=True)

class PG_LIP_Connector(Postgres_Connector):
    def __init__(self, server='localhost', username='postgres', password='postgres', db_name='imdbload'):
        super(PG_LIP_Connector, self).__init__(server, username, password, db_name)
        self.db_name=db_name
        # self.connections = [Postgres_Connector(db_name=self.db_name) for _ in range(8)]
    
    def load_functions(self, load_func_sql_file):
        with open(load_func_sql_file, 'r') as f:
            func_sql = f.read()
        self.execute(func_sql, set_env=True)
        # self.disable_parallel()
    
    def _beautify_sql(self, sql):
        lines = sql.strip('\n').strip(' ').split('\n')
        final_lines = []
        for l in lines:
            if not l.strip(' ').startswith('--') and not len(l) == 0:
                final_lines.append(l)
        if len(final_lines) > 0:
            return '\n'.join(final_lines)
        else:
            return None

    def profile_lip_query(self, prepare_sqls, profile_sql, get_plan=False, disable_op=None):


        def bf_building_thread(sql, n):
            conn = self.connections[n % 8]
            res = conn.execute(sql, set_env=True)
            return res

        def is_not_empty_sql(sql):
            is_empty = False
            for line in sql.replace(' ', '').strip('\n').split('\n'):
                if not line.strip().startswith('--'):
                    return True
            return False

        q = {
            'lip_build_overhead': 0,
            'lip_execution_cost': -1
        }
        
        # self.disable_parallel()
        for idx, sql in enumerate(prepare_sqls):
            if is_not_empty_sql(sql):
                res = self.execute(sql, set_env=True)
                if idx >= 2:
                    q['lip_build_overhead'] += res['execution_cost']

        # self.threads = []
        # pended_sql = []
        # for idx, sql in enumerate(prepare_sqls[2:]):
        #     if is_not_empty_sql(sql):
        #         if 'pg_lip_bloom_bit_and' in sql:
        #             pended_sql.append(sql)
        #             # res = self.execute(sql, set_env=True)
        #         else:
        #             # time.sleep(random.randint(1, 20))
        #             thread = threading.Thread(target=bf_building_thread, args=(sql, idx))
        #             thread.start()
        #         self.threads.append(thread)
        
        # start_time = time.time()
        # for idx in range(len(self.threads)):
        #     self.threads[idx].join()
        # end_time = time.time()
    
        # for sql in pended_sql:
        #     res = self.execute(sql, set_env=True)

        # q['lip_build_overhead'] = end_time - start_time
        # print("Build overhead: ", q['lip_build_overhead'])
        

        profile_sql = self._beautify_sql(profile_sql)

        if disable_op is not None:
            profile_sql = profile_sql.replace("Leading", '-')

        if get_plan:
            if 'explain analyze' not in profile_sql.lower():
                if '*/' in profile_sql:
                    profile_sql = profile_sql.replace('*/', '*/ EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS) \n')
                else:
                    profile_sql = 'EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS) \n' + profile_sql
            res = self.execute(profile_sql, set_env=False, disable_op=disable_op, show_plan=True)
            q['lip_execution_cost'] = res['execution_cost']
            q['plan'] =  res['result_rows']
        else:
            res = self.execute(profile_sql, set_env=False, disable_op=disable_op)
            q['lip_execution_cost'] = res['execution_cost']
        
        return q


def check_same_db(db_list):
    anchor_db = db_list[0]
    for i, db in enumerate(db_list[1:]):
        logging.info(f"Cheching the {i}-th db")
        for t in anchor_db:
            if t not in db:
                logging.warning(f"Missing table {t} of size {anchor_db[t]}")
            else:
                logging.info(f"Table {t} has a size diff of {db[t] - anchor_db[t]}/{anchor_db[t]}")
            

if __name__ == '__main__':
    # pg_imdb = DB_instance('postgres', 'imdbload')
    # pg_imdb.show_db_info()

    # # mssql_imdb = DB_instance('mssql', 'imdb')
    # # mssql_imdb.show_db_info()
    # sql = """ SELECT * FROM movie_companies mc,title t,movie_info_idx mi_idx WHERE t.id=mc.movie_id AND t.id=mi_idx.movie_id AND mi_idx.info_type_id=112 AND mc.company_type_id=2; """

    # # check_same_db([pg_imdb.table_sizes, mssql_imdb.table_sizes])
    # # print(mssql_imdb.explain_card(sql))
    # print(mssql_imdb.explain_card(sql))

    pg_lip_conn = PG_LIP_Connector()
    all_sql_25c = """
SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)');
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it2 WHERE it2.info = 'votes';
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM keyword AS k WHERE k.keyword IN ('murder',
--                     'violence',
--                     'blood',
--                     'gore',
--                     'death',
--                     'female-nudity',
--                     'hospital');
SELECT sum(pg_lip_bloom_add(4, movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Horror',
                  'Action',
                  'Sci-Fi',
                  'Thriller',
                  'Crime',
                  'War');
SELECT sum(pg_lip_bloom_add(5, id)) FROM name AS n WHERE n.gender = 'm';
SELECT sum(pg_lip_bloom_bit_and(6, 0, 4));


/*+
Leading(((((it1 ((it2 ((k mk) mi_idx)) mi)) ci) n) t))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
FROM (
        SELECT * FROM cast_info as ci
        WHERE pg_lip_bloom_probe(5, ci.person_id) 
     ) AS ci,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     (
        SELECT * FROM movie_info as mi
        WHERE 
        pg_lip_bloom_probe(6, movie_id) AND 
        pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     (
        SELECT * FROM movie_info_idx as mi_idx
        WHERE
        pg_lip_bloom_probe(6, movie_id) AND 
        pg_lip_bloom_probe(2, info_type_id)
     ) AS mi_idx,
     (
        SELECT * FROM movie_keyword as mk
        WHERE 
        pg_lip_bloom_probe(6, movie_id)
        -- AND pg_lip_bloom_probe(3, keyword_id)
     ) AS mk,
     name AS n,
     (
         SELECT * FROM title as t
         WHERE pg_lip_bloom_probe(6, id)
     ) AS t
WHERE 
 ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
  AND mi.info IN ('Horror',
                  'Action',
                  'Sci-Fi',
                  'Thriller',
                  'Crime',
                  'War')
  AND n.gender = 'm'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id;

"""
    ret = profile_lip_query(prepare_sqls = all_sql_25c.split(';')[0:-1] ,profile_sql=all_sql_25c.split(';')[-1])


    
