from core.DB_connector import *
import json

class op_test:

    def __init__(self, ):
        self.query_template = """
        /*+
        {}(t1 t2)
        */
        WITH t1 AS (
            SELECT * FROM title LIMIT {}
        )
        SELECT COUNT(*) FROM t1, cast_info as t2 WHERE t1.id = t2.movie_id;
        """
        self.db = Postgres_Connector(server='localhost', username='postgres', password='postgres', db_name='imdbload')

    def gen_test_query(self, s1, join_op):
        return self.query_template.format(join_op, s1)
    
    def gen_and_test(self, size_max=100, join_ops = ['HashJoin', 'NestLoop']):
        latencies = {}
        for s1 in range(1, size_max, int(size_max/2)):
            # for s2 in range(1, size_max, int(size_max/20)):
            latencies[f'{s1}'] = {}
            for j in join_ops:
                query = self.gen_test_query(s1, j) 
                if j == 'HashJoin':
                    query = query.replace('*/', '\n Leading(t2 t1)*/')
                else:
                    query = query.replace('*/', 'SeqScan(t2)\n Leading(t1 t2)*/')
                for _ in range(2):
                    latency = self.get_query_latency(query)
                latencies[f'{s1}'][j] = latency
                # print(query)
                print(f'{j}: {s1}: ', latency)
            json.dump(latencies, open('/mnt/pg_lip_bloom/runtime_eval/runtime_quality/eval_pg_op_robustness/latencies.json', 'w'), indent=4)
        return latencies

    def get_query_latency(self, query):
        res = self.db.execute(query)
        return res['execution_cost']


if __name__ == '__main__':
    t = op_test()
    print(t.gen_and_test())


    """
        /*+
        HashJoin(t1 t2)
        Leading(t2 t1)
        */
        WITH t1 AS (
            SELECT * FROM title LIMIT 800000
        )
        SELECT COUNT(*) FROM t1, cast_info as t2 WHERE t1.id = t2.movie_id;
    """