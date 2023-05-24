from core.cardinality_estimation_quality.cardinality_estimation_quality import *
from treelib import Node, Tree
from tqdm import tqdm

JOIN_NODE_TYPES = {'Nested Loop': 'NestLoop', 'Hash Join': 'HashJoin', 'Merge Join': 'MergeJoin'}
SCAN_NODE_TYPES = {'Index Scan': 'IndexScan', 'Seq Scan': 'SeqScan', 'Index Only Scan': 'IndexScan'}

MOVIE_ID_FACT_TABLES = ['at', 'ci', 'cc', 'mc', 'mi', 'mi_idx', 'mk', 'ml', ]


SLOW_TEST_QUERIES = [
    '16b.sql', '17a.sql', '17e.sql', '17f.sql', '17b.sql', '19d.sql', '17d.sql',
    '17c.sql', '10c.sql', '26c.sql', '25c.sql', '6d.sql', '6f.sql', '8c.sql',
    '18c.sql', '9d.sql', '30a.sql', '19c.sql', '20a.sql'
]

RAND_TEST_QUERIES = [
    [
        '8a.sql', '16a.sql', '2a.sql', '30c.sql', '17e.sql', '20a.sql', '26b.sql',
        '12b.sql', '15b.sql', '15d.sql', '10b.sql', '15a.sql', '4c.sql', '4b.sql',
        '22b.sql', '17c.sql', '24b.sql', '10a.sql', '22c.sql'
    ],
    [
        '14b.sql', '17f.sql', '13a.sql', '6d.sql', '7a.sql', '29a.sql', '13d.sql', 
        '27b.sql', '20c.sql', '15b.sql', '9a.sql', '27a.sql', '23c.sql', '13c.sql', 
        '18c.sql', '1a.sql', '21a.sql', '14b.sql', '19a.sql'
    ],
    [
        '13a.sql', '23c.sql', '25b.sql', '13a.sql', '30a.sql', '15d.sql', '25c.sql', 
        '30c.sql', '25a.sql', '17a.sql', '21b.sql', '33b.sql', '19b.sql', '8a.sql', 
        '13d.sql', '1a.sql', '20a.sql', '13b.sql', '4a.sql'
    ],
    [
        '16c.sql', '18b.sql', '22c.sql', '5a.sql', '12a.sql', '20b.sql', '26c.sql', 
        '24a.sql', '27a.sql', '29b.sql', '19d.sql', '5a.sql', '17c.sql', '22c.sql', 
        '13c.sql', '29b.sql', '15a.sql', '23a.sql', '6b.sql'
    ],
    [
        '31b.sql', '11a.sql', '20c.sql', '26c.sql', '26a.sql', '12b.sql', '22a.sql', 
        '25c.sql', '8d.sql', '4c.sql', '21a.sql', '12b.sql', '22d.sql', '6e.sql', 
        '25c.sql', '11a.sql', '32a.sql', '14a.sql', '20a.sql'
    ]
]

class PostgreConnector:

    def __init__(self,):
        server='localhost' 
        username='postgres'
        password='postgres'
        db_name='imdbload'
        self.db_url = f"host={server} port=5432 user={username} dbname={db_name} password={password} options='-c statement_timeout={6000000}' "
        db = self.db_url.format(db_name)
        self.PG = Postgres(db)

    def get_plan(self, sql_str):
        assert 'explain' not in sql_str.lower()
        # print(self.PG.explain(sql_str, execute=False))
        # exit(1)
        return self.PG.explain(sql_str, execute=False)[0][0][0]["Plan"]


# class TreeNode:
#     def __init__(self, id):
#         self.id = id
#         self.left, self.right = None, None

class QueryPlan:
    
    # class PlanNode:
    #     def __init__(self, left=None, right=None, op=None, table=None):
    #         self.left, self.right, self.op, self.table = left, right, op, table

    def __init__(self, pg_plan_json):
        # self.tree = Tree()
        self.nodes_cnt = 0
        self.root_node = None
        self.tree = {}

        def parse_json(pg_plan_json, parent_id):
            # if 'Aggregate' in pg_plan_json['Node Type'] or 'Gather' in pg_plan_json['Node Type'] or ('Hash' in pg_plan_json['Node Type'] and 'Join' not in pg_plan_json['Node Type']) :
            #     parse_json(pg_plan_json['Plans'][0], parent_id)
            # else:
            if self.nodes_cnt == 0:
                self.nodes_cnt += 1
                node_id = f'{self.nodes_cnt}:' + pg_plan_json['Node Type']
                self.root_node = node_id
                parent_id = node_id
                # self.tree[node_id] = [node_id]
            if 'Plans' in pg_plan_json:
                node_ids = []
                for sub_plan in pg_plan_json['Plans']:
                    self.nodes_cnt += 1
                    node_id = f'{self.nodes_cnt}:' + sub_plan['Node Type']
                    if 'Alias' in sub_plan:
                        node_id += ':' + sub_plan['Alias']
                    
                    # self.tree.create_node(node_id, node_id, parent_id)
                    if parent_id in self.tree:
                        self.tree[parent_id].append(node_id)
                    else:
                        self.tree[parent_id] = [node_id]
                    node_ids.append(node_id)

                for sub_plan, node_id in zip(pg_plan_json['Plans'], node_ids):    
                    parse_json(sub_plan, node_id)

        parse_json(pg_plan_json, 0)

    def get_pg_hint_plan(self, physcial=False):
        scan_hints = []
        join_op_hints = []

        def gen_jo_hint(root_node):
            if root_node in self.tree:
                children = self.tree[root_node]
                sub_hints = []
                for c in children:
                    sub_hints.append(gen_jo_hint(c))
                
                if len(sub_hints) > 1:
                    hint = '(' + ' '.join(sub_hints) + ')' 
                else:
                    hint = ' '.join(sub_hints)
                return hint
            
            elif 'scan' in root_node.lower():
                scan_hints.append( SCAN_NODE_TYPES[root_node.split(':')[1]] + '(' + root_node.split(':')[-1] + ')')
                return root_node.split(':')[-1]
            else:
                return ''

        def get_lower_level_tabs(root_node, all_tabs):
            if 'scan' in root_node.lower():
                return all_tabs + [root_node.split(':')[-1]]
            elif root_node in self.tree:
                for c in self.tree[root_node]:
                    all_tabs = get_lower_level_tabs(c, all_tabs)
                return all_tabs
            else:
                return all_tabs

        
        def gen_join_op_hint(root_node):
            if root_node in self.tree and root_node.split(':')[1] in JOIN_NODE_TYPES:
                join_op_hints.append( JOIN_NODE_TYPES[root_node.split(':')[1]] +  '(' + ' '.join(get_lower_level_tabs(root_node, [])) +  ')' )
                for c in self.tree[root_node]:
                   gen_join_op_hint(c)
            elif 'scan' in root_node.lower():
                pass
            else:
                if root_node in self.tree:
                    for c in self.tree[root_node]:
                        gen_join_op_hint(c)
        
        jo_hint = '(' + gen_jo_hint( self.root_node) + ')'
        # print(jo_hint)
        first_cnt = 0
        for c in jo_hint:
            if c != '(':
                break
            else:
                first_cnt += 1
        last_cnt = 0
        l = list(jo_hint)
        l.reverse()
        for c in l:
            if c != ')':
                break
            else:
                last_cnt += 1
        rm_cnt = min(first_cnt, last_cnt) - 2
        if rm_cnt > 0:
            jo_hint = jo_hint[rm_cnt:-rm_cnt]

        jo_hint = 'Leading' +  jo_hint
        gen_join_op_hint(self.root_node)
        join_op_hint = '\n'.join(join_op_hints)
        scan_hint = '\n'.join(scan_hints)

        print(join_op_hint)

        if physcial:
            return '/*+\n' + join_op_hint + '\n' + scan_hint + '\n' + jo_hint + '*/'
        else:
            return '/*+\n' + jo_hint + '*/'


    def show_tree(self,):
        # self.tree.show()
        print(self.tree)
        # print(self.get_pg_hint_plan())


class LipRewriter:

    def __init__(self):
        self.conn = PostgreConnector()
        self.build_sqls = []
        self.probe_rewriten_sql = None
        self.sql_str = None

    def _get_PG_plan_tree(self, sql_str):
        plan_dict = self.conn.get_plan(sql_str)
        self.plan_tree = QueryPlan(plan_dict)
        self.plan_tree.show_tree()
        return self.plan_tree
    
    def _get_predicates(self, sql_str):
        self.predicates = {}
        all_pred = sql_str.split('WHERE')[-1].split(';')[0].replace('\n', ' ').strip(' ').split('AND')
        for idx, p in enumerate(all_pred):
            if 'id' in p and '=' in p:
                break
            current_tab = p.strip(' ').strip('(').split('.')[0]
            if current_tab in self.predicates:
                self.predicates[current_tab].append(p)
            else:
                self.predicates[current_tab] = [p]
        
        self.join_graph = {}
        for join_pred in all_pred[idx:]:
            left = join_pred.split('=')[0]
            left = " ".join(left.split())
            right = join_pred.split('=')[1]
            right = " ".join(right.split())
            if left in self.join_graph:
                self.join_graph[left].append(right)
            else:
                self.join_graph[left] = [right]

            if right in self.join_graph:
                self.join_graph[right].append(left)
            else:
                self.join_graph[right] = [left]
        return self.predicates

    def _get_tab_mappings(self, sql_str):
        all_mappings = sql_str.split('FROM')[-1].split('WHERE')[0].replace('\n', ' ').strip(' ').split(',')
        self.tab_mappings = {}
        for m in all_mappings:
            original = m.split('AS')[0].replace(' ', '')
            short = m.split('AS')[1].replace(' ', '')
            self.tab_mappings[short] = original
        return self.tab_mappings

    def gen_build_sql(self, ):
        self.build_sqls = [
            'SELECT pg_lip_bloom_set_dynamic(2);',
            f'SELECT pg_lip_bloom_init({len(self.predicates.keys())});'
        ]
        self.BF_built_attrs = []
        for i, tab in enumerate(self.predicates):
            full_pred = ' AND '.join(self.predicates[tab])
            pk_attr = "movie_id" if tab in MOVIE_ID_FACT_TABLES else 'id'
            self.BF_built_attrs.append(f'{tab}.{pk_attr}')
            self.build_sqls.append(
                f'SELECT sum(pg_lip_bloom_add({i}, {tab}.{pk_attr})) FROM {self.tab_mappings[tab]} AS {tab} WHERE {" ".join(full_pred.split())};'
            )

    def gen_probe_sql(self, keep_jo=True):
        self.target_tabs = {}

        for idx, built_attr in enumerate(self.BF_built_attrs):
            if built_attr in self.join_graph:
                for target_attr in self.join_graph[built_attr]:
                    target_tab_name = target_attr.split('.')[0]
                    target_attr_name = target_attr.split('.')[1]
                    if target_tab_name not in self.target_tabs:
                        # self.target_tabs[target_tab_name] = {target_attr_name: f'pg_lip_bloom_probe({idx}, {target_attr})'}
                        self.target_tabs[target_tab_name] = [f'pg_lip_bloom_probe({idx}, {target_attr})']
                    else:
                        # self.target_tabs[target_tab_name][target_attr_name] = f'pg_lip_bloom_probe({idx}, {target_attr})'
                        self.target_tabs[target_tab_name].append(f'pg_lip_bloom_probe({idx}, {target_attr})')
        
        all_mappings = sql_str.split('FROM')[-1].split('WHERE')[0].replace('\n', ' ').strip(' ').split(',')
        

        all_sub_queries = []
        for m in all_mappings:
            original = m.split('AS')[0].replace(' ', '')
            short = m.split('AS')[1].replace(' ', '')
            if short in self.target_tabs:
                sub_q = f'(\n\tSELECT * FROM {original} AS {short} \n\t WHERE ' + '\n\tAND '.join(self.target_tabs[short]) + f'\n) AS {short}'
                all_sub_queries.append(sub_q)
            else:
                all_sub_queries.append(f'{original} AS {short}')
        
        self.probe_rewriten_sql = self.plan_tree.get_pg_hint_plan(physcial=True) + '\n' + sql_str.split('FROM')[0] + ' FROM \n' + ' ,\n'.join(all_sub_queries) + '\nWHERE\n' + sql_str.split('WHERE')[-1]

        return self.probe_rewriten_sql


    def tune_expression(self, s):
        if 'BETWEEN' in s:
            words = s.split(' ')
            replace = False
            for i, w in enumerate(words):
                if w == 'AND' and replace:
                    replace = False
                    words[i] = 'and'
                elif w == 'BETWEEN':
                    words[i] = 'between'
                    replace = True
            s = ' '.join(words)
        return s

    def rewrite(self, sql_str):
        self.sql_str = self.tune_expression(sql_str)
        self._get_PG_plan_tree(self.sql_str)
        self._get_predicates(self.sql_str)
        self._get_tab_mappings(self.sql_str)
        self.gen_build_sql()
        self.gen_probe_sql()
        # print(self.probe_rewriten_sql)
        return '\n'.join(self.build_sqls) + '\n\n'  + self.probe_rewriten_sql
        

if __name__ == '__main__':
    import os
    all_files = os.listdir(queries_dir)
    all_files = [s for s in all_files if '.sql' in s]
    os.system(f"mkdir {os.path.join(queries_dir, 'lip_auto_rewrite/')}")
    for sql_file in tqdm(all_files):
        print(sql_file)
        with open(os.path.join(queries_dir, sql_file)) as f, open(os.path.join(queries_dir, 'lip_auto_rewrite', sql_file), 'w') as g:
            sql_str = f.read()
            m_writer = LipRewriter()
            rewriten = m_writer.rewrite(sql_str)
            print(rewriten)
            g.write(rewriten)
