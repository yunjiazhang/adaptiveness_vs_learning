import wandb
import json
import pandas as pd
import numpy as np

# run_path = 'yunjiazhang/balsa/1bs7oby0'
# run_path = 'yunjiazhang/balsa/16ly1j6d'
run_path = 'yunjiazhang/balsa/2po9ps6z'

valuable_runs = {
    'Balsa_JOB_test_n_join_group_1': 'yunjiazhang/balsa/2czc66cv',
    'Balsa_JOB_test_n_join_group_2': 'yunjiazhang/balsa/3ejs5u28',
    'Balsa_JOB_test_n_join_group_3': 'yunjiazhang/balsa/1urqe5cq',
    'Balsa_JOB_test_n_join_group_4': 'yunjiazhang/balsa/1mt9sv2c',
    'Balsa_JOB_test_n_join_group_5': 'yunjiazhang/balsa/11056q9j',
    'Balsa_JOB_test_n_join_group_6': 'yunjiazhang/balsa/3lmtdidf',
    'Balsa_JOBRandSplit': 'yunjiazhang/balsa/1bs7oby0',
    'Balsa_JOB_all_train_try1': 'yunjiazhang/balsa/tmeng9pw',
    # 'Balsa_JOB_all_train_try4': 'yunjiazhang/balsa/2itwd34e',
    'Balsa_JOB_all_train_try2': 'yunjiazhang/balsa/2ofuhy6p',
    'Balsa_JOB_all_train_try3': 'yunjiazhang/balsa/2wmdc6m8',
}

all_JOB_queries = [
    '30a.sql', '1d.sql', '25a.sql', '6b.sql', '19c.sql', '28b.sql', 
    '9b.sql', '33b.sql', '32a.sql', '27a.sql', '20b.sql', '17d.sql', 
    '16b.sql', '10b.sql', '6a.sql', '17b.sql', '25b.sql', '8b.sql', 
    '31b.sql', '33c.sql', '23a.sql', '15a.sql', '21b.sql', '11d.sql', 
    '9a.sql', '6d.sql', '24a.sql', '17e.sql', '19a.sql', '1c.sql', 
    '25c.sql', '31a.sql', '23c.sql', '17f.sql', '19b.sql', '9d.sql', 
    '27b.sql', '11b.sql', '7b.sql', '19d.sql', '1a.sql', '11c.sql', 
    '31c.sql', '28a.sql', '3c.sql', '6c.sql', '26b.sql', '16a.sql', 
    '7a.sql', '29b.sql', '29a.sql', '1b.sql', '6e.sql', '13d.sql', 
    '10c.sql', '26a.sql', '4b.sql', '10a.sql', '15b.sql', '15d.sql', 
    '26c.sql', '14b.sql', '15c.sql', '14c.sql', '13b.sql', '3a.sql', 
    '24b.sql', '5a.sql', '8c.sql', '6f.sql', '8a.sql', '27c.sql', 
    '12a.sql', '22a.sql', '17a.sql', '13a.sql', '21a.sql', '12b.sql', 
    '13c.sql', '8d.sql', '21c.sql', '7c.sql', '2a.sql', '3b.sql', 
    '16c.sql', '9c.sql', '32b.sql', '28c.sql', '33a.sql', '11a.sql', 
    '18a.sql', '5c.sql', '22d.sql', '18c.sql', '5b.sql', '2c.sql', 
    '16d.sql', '4a.sql', '22c.sql', '12c.sql', '29c.sql', '30b.sql', 
    '2d.sql', '14a.sql', '17c.sql', '22b.sql', '30c.sql', '20a.sql', 
    '20c.sql', '2b.sql', '4c.sql', '18b.sql', '23b.sql'
]


def save_balsa_train_best():
    # with open('best_balsa_train_all_try_runtimes.json') as f:
    #     q_runtimes = json.load(f)
    
    api = wandb.Api()
    q_runtimes = {}
    for run_path in [valuable_runs[f'Balsa_JOB_all_train_try{i+1}'] for i in range(3)]:
        run = api.run(run_path)
        for q in all_JOB_queries:
            if q not in q_runtimes:
                q_runtimes[q] = []
            # if q!= '19d.sql': # q not in q_runtimes or q_runtimes[q] == -1:
            runtimes = run.history(keys=[f'latency/q{q.split(".")[0]}'])
            lowest_runtime = np.inf
            for i in range(runtimes.shape[0]):
                if runtimes[f'latency/q{q.split(".")[0]}'].iloc[i] < lowest_runtime:
                    lowest_runtime = runtimes[f'latency/q{q.split(".")[0]}'].iloc[i]
            q_runtimes[q].append(lowest_runtime)

    with open('best_balsa_train_all_try_runtimes.json', 'w') as f:
        json.dump(q_runtimes, f, indent=4)

        
def save_pg_baseline_best():
    with open('postgres_parallel=1_imdb_runtimes.json') as f:
        q_runtimes = json.load(f)
    
    api = wandb.Api()
    run = api.run(run_path)
    
    for q in all_JOB_queries:
        if q!= '19d.sql' and (q not in q_runtimes or q_runtimes[q] == -1):
            runtimes = run.history(keys=[f'latency_expert/q{q.split(".")[0]}'])
            lowest_runtime = np.inf
            for i in range(runtimes.shape[0]):
                if runtimes[f'latency_expert/q{q.split(".")[0]}'].iloc[i] < lowest_runtime:
                    lowest_runtime = runtimes[f'latency_expert/q{q.split(".")[0]}'].iloc[i]
            
            if q in q_runtimes:
                if lowest_runtime < min(q_runtimes[q]) :
                    print(f"q{q}: lower runtime {lowest_runtime} {q_runtimes[q]};")
            
            q_runtimes[q] = [lowest_runtime]    
    
    with open('best_pg_baseline_job_runtimes.json', 'w') as f:
        json.dump(q_runtimes, f, indent=4)
        
def record_valuable_runs():
    for r in valuable_runs:
        df_all = pd.DataFrame()
        api = wandb.Api()
        run = api.run(valuable_runs[r])
        runtimes = run.scan_history()
        rows = 0
        for row in runtimes:
            df = pd.json_normalize(row)
            
            if df_all.empty:
                df_all = df
            else:
                df_all = pd.concat([df_all, df])
            rows += 1
            print(rows)
                    
            
        df_all.to_csv(f'balsa_wandb_logs/{r}_full.csv')
        
        
        
if __name__ == '__main__':
    # record_valuable_runs()
    save_balsa_train_best()