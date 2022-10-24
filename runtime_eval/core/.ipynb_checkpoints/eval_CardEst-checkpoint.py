from core.DB_connector import *
import os

class Evaluator(object):

    def __init__(self, db_instance=None, sql_dir=None):
        self.db_instance = db_instance
        self.sql_dir = sql_dir
        if sql_dir is not None:
            self.sql_files = os.listdir(sql_dir)
        else:
            self.sql_files = []

    def _reset_db(self, db_instance):
        self.db_instance = db_instance

    def evaluate_queries(self, sql_dir=None, max_sql_num=None, save_json_file=None):
        assert self.sql_dir is not None or sql_dir is not None, "No sql files provided."
        if sql_dir is not None:
            sql_files = os.listdir(sql_dir)
        else:
            sql_dir = self.sql_dir
            sql_files = self.sql_files
        
        sql_files = sorted(sql_files)
        sql_files = [f for f in sql_files if '.sql' in f]

        self.est_quality = {}
        for idx, sql_file in enumerate(sql_files):
            with open(os.path.join(sql_dir, sql_file), 'r') as f:
                sql = f.read().replace("COUNT(*)", "*")
            logging.info(f"Evaluating {sql_file}.")
            actual_rows, est_rows = self.db_instance.explain_card(sql)
            q_error = max(actual_rows / est_rows, est_rows / actual_rows)
            self.est_quality[sql_file] = {
                'actual': actual_rows, 
                'estimated': est_rows,
                'estimation diff': '{0:+}'.format(est_rows - actual_rows),
                'q-error': q_error
                }
            logging.info(f"Evaluated {sql_file}. Actual = {actual_rows}, Estimation = {est_rows}, Q-error = {q_error}")
            if save_json_file is not None:
                self.dump_estimation_qualities(save_json_file)
        return self.est_quality
        
    def dump_estimation_qualities(self, dump_json_file):
        with open(dump_json_file, "w") as outfile:
            json.dump(self.est_quality, outfile, indent=4)



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





