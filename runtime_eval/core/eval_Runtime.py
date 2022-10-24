from core.DB_connector import *
import os
import time
import re
from tqdm import tqdm

class Runtime_Evaluator(object):

    def __init__(self, db_instance=None, sql_dir=None):
        self.db_instance = db_instance
        self.sql_dir = sql_dir
        if sql_dir is not None:
            self.sql_files = os.listdir(sql_dir)
        else:
            self.sql_files = []

    def _reset_db(self, db_instance):
        self.db_instance = db_instance

    def _prepare_sql_files(self, sql_dir=None, eval_sql_re_pattern=None):
        assert self.sql_dir is not None or sql_dir is not None, "No sql files provided."
        if sql_dir is not None:
            sql_files = os.listdir(sql_dir)
        else:
            sql_dir = self.sql_dir
            sql_files = self.sql_files
        
        sql_files = sorted(sql_files)
        if eval_sql_re_pattern is not None:
            pattern = re.compile(eval_sql_re_pattern)
            sql_files = [f for f in sql_files if '.sql' in f and pattern.match(f)]
        else:
            sql_files = [f for f in sql_files if '.sql' in f]
        return sql_dir, sql_files

    def evaluate_queries(self, sql_dir=None, max_sql_num=None, sql_files=None, save_json_file=None,\
                         multiple_runs=5, rerun_finished=False, skip_queries=[], timeout=600,
                         disable_lip=False, disable_parallel=False, save_plan=False, disable_op=None, save_plan_subdir='plan'):
        
        if sql_files is not None:
            pass
        else:
            sql_dir, sql_files = self._prepare_sql_files(sql_dir)

        if rerun_finished is False and save_json_file is not None and os.path.exists(save_json_file):
             self.runtime_quality = json.load(open(save_json_file))
        else:
             self.runtime_quality = {}

        for idx, sql_file in enumerate(sql_files):
            
            if sql_file in skip_queries or sql_file in self.runtime_quality:
                continue

            with open(os.path.join(sql_dir, sql_file), 'r') as f:
                sql = f.read() # .replace("COUNT(*)", "*")
            self.runtime_quality[sql_file] = []
            logging.info(f"Evaluating {sql_file}.")
            for i in range(multiple_runs):
                start_timestamp = time.time()
                # if i == 0:
                #     show_plan = True
                # else:
                #     show_plan = False
                q = self.db_instance.execute(sql, timeout=timeout, disable_lip=disable_lip, show_plan=save_plan, disable_parallel=disable_parallel, disable_op=disable_op)
                end_timestamp = time.time() 
                if q['execution_cost'] < 0:
                    self.runtime_quality[sql_file] = [-1]
                    break
                else:
                    exeuction_cost = q['execution_cost'] # end_timestamp - start_timestamp
                    logging.info(f"\tFinished the {i+1}-th trial with {exeuction_cost:.2f} secs")
                    # self.runtime_quality[sql_file].append(end_timestamp - start_timestamp)
                    self.runtime_quality[sql_file].append(exeuction_cost)
            
                if save_plan:
                    plan_str = '\n'.join([a[0] for a in q['plan']])
                    if disable_nestloop:
                        with open(os.path.join(sql_dir, f'{save_plan_subdir}_disable_nl' , sql_file.replace('.sql', '_plan.txt')), 'w') as f:
                            f.write(plan_str)
                    else:
                        with open(os.path.join(sql_dir, f'{save_plan_subdir}' , sql_file.replace('.sql', '_plan.txt')), 'w') as f:
                            f.write(plan_str)
            
            logging.info(f"\tAvg runtime = {np.average(self.runtime_quality[sql_file]):.2f} secs")

            # exit(1)
            
            if save_json_file is not None:
                self.dump_estimation_qualities(save_json_file)

        return self.runtime_quality
    
    def evaluate_queries_as_workload(self, sql_dir=None, max_sql_num=None, sql_files=None, save_json_file=None,\
                         multiple_runs=5, rerun_finished=False, skip_queries=[], timeout=600,
                         disable_lip=False, disable_parallel=False, save_plan=False, disable_op=None, save_plan_subdir='plan'):
        
        if sql_files is not None:
            pass
        else:
            sql_dir, sql_files = self._prepare_sql_files(sql_dir)

        self.runtime_quality = []

        for i in range(multiple_runs):
            
            self.runtime_quality.append({})
            import random
            random.shuffle(sql_files)
            logging.info(f"Shuffled: {sql_files}")

            total_time = 0

            for idx, sql_file in enumerate(tqdm(sql_files)):
                
                if sql_file in skip_queries or sql_file in self.runtime_quality:
                    continue

                with open(os.path.join(sql_dir, sql_file), 'r') as f:
                    sql = f.read() # .replace("COUNT(*)", "*")
                
                # self.runtime_quality[sql_file] = []
                # logging.info(f"Evaluating {sql_file}.")
                
                start_timestamp = time.time()
                q = self.db_instance.execute(sql, timeout=timeout, disable_lip=disable_lip, show_plan=save_plan, disable_parallel=disable_parallel, disable_op=disable_op)
                end_timestamp = time.time() 
                if q['execution_cost'] < 0:
                    self.runtime_quality[sql_file] = [-1]
                    break
                else:
                    exeuction_cost = q['execution_cost'] # end_timestamp - start_timestamp
                    # logging.info(f"\tFinished the {i+1}-th trial with {exeuction_cost:.2f} secs")
                    # self.runtime_quality[sql_file].append(end_timestamp - start_timestamp)
                    self.runtime_quality[i][sql_file]= exeuction_cost
                    total_time += exeuction_cost
            
            logging.info(f'{i}-th trial with {total_time}')
            
            if save_json_file is not None:
                self.dump_estimation_qualities(save_json_file)

        return self.runtime_quality

    def dump_estimation_qualities(self, dump_json_file):
        with open(dump_json_file, "w") as outfile:
            json.dump(self.runtime_quality, outfile, indent=4)

class PG_LIP_Runtime_Evaluator(Runtime_Evaluator):
    
    def __init__(self, db_instance=None, sql_dir=None, init_sql_file=None):
        super(PG_LIP_Runtime_Evaluator, self).__init__(db_instance, sql_dir)
        self.init_functions(init_sql_file)

    def init_functions(self, init_sql_file):
        self.db_instance.connector.load_functions(init_sql_file)
    
    def evaluate_queries(self, eval_lip=True, sql_dir=None, sql_files=None, save_json_file=None,\
                         multiple_runs=5, rerun_finished=False, skip_queries=[], timeout=None, 
                         disable_parallel=False, save_plan=False, disable_op=None):

        if sql_files is not None:
            pass
        else:
            sql_dir, sql_files = self._prepare_sql_files(sql_dir)

        if rerun_finished is False and save_json_file is not None and os.path.exists(save_json_file):
             self.runtime_quality = json.load(open(save_json_file))
        else:
             self.runtime_quality = {}

        print("Executing sql: ", sql_files)

        for idx, sql_file in enumerate(sql_files):
            
            if sql_file in skip_queries or sql_file in self.runtime_quality:
                continue

            with open(os.path.join(sql_dir, sql_file), 'r') as f:
                sql = f.read() # .replace("COUNT(*)", "*")
            
            prepare_sqls = [s+';'  for s in sql.split(';')[0:-2]] 
            profile_sql = sql.split(';')[-2] + ';'

            self.runtime_quality[sql_file] = []
            logging.info(f"Evaluating {sql_file}.")
            
            for i in range(multiple_runs):
                start_timestamp = time.time()
                q = self.db_instance.connector.profile_lip_query(prepare_sqls, profile_sql, save_plan, disable_op=disable_op)
                end_timestamp = time.time() 
                if q['lip_execution_cost'] < 0:
                    self.runtime_quality[sql_file] = [[-1, -1, -1]]
                    break
                else:
                    logging.info(f"\tFinished the {i+1}-th trial with total: {end_timestamp - start_timestamp:.2f} secs, (prep: {q['lip_build_overhead']:.2f}, exec: {q['lip_execution_cost']:.2f})")
                    self.runtime_quality[sql_file].append([end_timestamp - start_timestamp, q['lip_build_overhead'], q['lip_execution_cost']])
            
                if save_plan:
                    plan_str = '\n'.join([a[0] for a in q['plan']])
                    if disable_op:
                        with open(os.path.join(sql_dir, f'{disable_op}_plan' , sql_file.replace('.sql', '_plan.txt')), 'w') as f:
                            f.write(plan_str)
                    else:
                        with open(os.path.join(sql_dir, 'plan' , sql_file.replace('.sql', '_plan.txt')), 'w') as f:
                            f.write(plan_str)
            
            # logging.info(f"\tAvg runtime = {np.average(self.runtime_quality[sql_file], axis=0):.2f} secs")
            # exit(1)
            if save_json_file is not None:
                self.dump_estimation_qualities(save_json_file)
        return self.runtime_quality


    def evaluate_queries_as_workload(self, eval_lip=True, sql_dir=None, sql_files=None, save_json_file=None,\
                         multiple_runs=5, rerun_finished=False, skip_queries=[], timeout=None, 
                         disable_parallel=False, save_plan=False, disable_op=None):

        if sql_files is not None:
            pass
        else:
            sql_dir, sql_files = self._prepare_sql_files(sql_dir)

        if rerun_finished is False and save_json_file is not None and os.path.exists(save_json_file):
             self.runtime_quality = json.load(open(save_json_file))
        else:
             self.runtime_quality = {}

        logging.info(f"Executing sql: {sql_files}")
        self.runtime_quality = []
        
        for i in range(multiple_runs):

            self.runtime_quality.append({})
        
            import random
            random.shuffle(sql_files)
            logging.info(f"Shuffled: {sql_files}")
            
            total_time = [0, 0, 0]

            for idx, sql_file in enumerate(tqdm(sql_files)):
                
                if sql_file in skip_queries or sql_file in self.runtime_quality:
                    continue

                with open(os.path.join(sql_dir, sql_file), 'r') as f:
                    sql = f.read() # .replace("COUNT(*)", "*")
                
                prepare_sqls = [s+';'  for s in sql.split(';')[0:-2]] 
                profile_sql = sql.split(';')[-2] + ';'

                
                # logging.info(f"Evaluating {sql_file}.")

                start_timestamp = time.time()
                q = self.db_instance.connector.profile_lip_query(prepare_sqls, profile_sql, save_plan, disable_op=disable_op)
                end_timestamp = time.time() 

                total_time[1] += q['lip_build_overhead']
                total_time[2] += q['lip_execution_cost']
                self.runtime_quality[i][sql_file] = [q['lip_execution_cost'] + q['lip_build_overhead'], q['lip_build_overhead'], q['lip_execution_cost']]
                
                # logging.info(f"\tAvg runtime = {np.average(self.runtime_quality[sql_file], axis=0):.2f} secs")
                # exit(1)
                if save_json_file is not None:
                    self.dump_estimation_qualities(save_json_file)
            
            logging.info(f"{i}-th trial: {total_time}")

        return self.runtime_quality

# if __name__ == '__main__':
    # pg_imdb = DB_instance('postgres', 'imdb')
    # pg_imdb.show_db_info()
    # pg_ev = Evaluator(pg_imdb, '/mnt/ml4qo/dataset/imdb/job-light/')
    # pg_ev.evaluate_queries(max_sql_num=None, save_json_file='/mnt/ml4qo/core/postgres_card_est_eval.json')
    # pg_ev.dump_estimation_qualities('/mnt/ml4qo/core/postgres_card_est_eval.json')

    # mssql_imdb = DB_instance('mssql', 'imdb')
    # # mssql_imdb.show_db_info()
    # mssql_ev = Evaluator(mssql_imdb, '/mnt/ml4qo/dataset/imdb/job-light/')
    # mssql_ev.evaluate_queries(max_sql_num=None, save_json_file='/mnt/ml4qo/core/mssql_card_est_eval.json')
    # # mssql_ev.dump_estimation_qualities('/mnt/ml4qo/core/mssql_card_est_eval.json')





