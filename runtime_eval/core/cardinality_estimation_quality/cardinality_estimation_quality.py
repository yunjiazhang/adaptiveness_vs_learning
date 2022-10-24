#!/usr/bin/env python3

'''
Connect to a postgresql database, run the provided queries on it, and
generate several plots for visualizing the quality of selectivity estimations of
predicates.
'''

from matplotlib.backends.backend_pdf import PdfPages
import sys
import seaborn
import psycopg2.extras
import psycopg2
import pickle
import pandas as pd
import os
import matplotlib.pyplot as plt
from math import ceil, log
import errno
import glob
import json
from collections import deque
import matplotlib
matplotlib.use('Agg')


QUERY_RESULTS_FILE = os.path.join(os.path.dirname(
    __file__), 'output', 'query_results.pkl')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'output')
GRAPHS_FILE = os.path.join(OUTPUT_DIR, 'output.pdf')


class Postgres():
    _connection = None
    _cursor = None

    def __init__(self, pg_url):
        self._connection = psycopg2.connect(pg_url)
        self.execute

    def execute(self, query, set_env=False):
        '''
        Execute the query and return all the results at once
        '''
        cursor = self._connection.cursor(
            cursor_factory=psycopg2.extras.DictCursor)
        cursor.execute(query)
        if not set_env:
            return cursor.fetchall()

    def explain(self, query, timeout=0, execute=True):
        '''
        Execute an 'EXPLAIN ANALYZE' of the query
        '''
        if 'explain' not in query.lower():
            if execute:
                # if not query.lower().startswith('explain'):
                query = 'EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) ' + query
            else:
                query = 'EXPLAIN (COSTS, VERBOSE, FORMAT JSON) ' + query

        if timeout > 0:
            self.execute(f'SET statement_timeout = {timeout};', set_env=True)
        
        try:
            cursor = self._connection.cursor(
                cursor_factory=psycopg2.extras.DictCursor)
            cursor.execute(query)
            q = cursor.fetchall()
        except Exception as e:
            print(f"Timeout in {timeout}!")
            print("Err msg: ", e)
            return None
        
        # if timeout > 0:
        #     self.execute(f'SET statement_timeout = 0;', set_env=True)

        return q


class QueryResult():
    filename = None
    query = None  # sql
    query_plan = None  # json representing the plan
    planning_time = None  # in milliseconds
    execution_time = None  # in milliseconds
    total_cost = None
    max_join_level = None
    # dataframe containing the node type, join level, estimated and actual
    # cardinalities
    cardinalities = None

    def __init__(self, filename):
        if filename is not None:
            self.filename = filename
            with open(filename) as f:
                self.query = f.read()

    def explain(self, db, execute=True, timeout=0):
        '''
        EXPLAIN the query in the given database to populate the execution stats fields
        '''
        # print(self.query)
        q = db.explain(self.query, timeout=timeout)
        if q is None:
            return
        result = q[0][0][0]
        self.result = result
        self.query_plan = result['Plan']

        if not execute:
            self.planning_time = None
            self.execution_time = None
            self.cardinalities = pd.DataFrame(
                self._parse_cardinalities_no_execute())
        else:
            self.planning_time = result['Planning Time']
            self.execution_time = result['Execution Time']
            self.cardinalities = pd.DataFrame(self._parse_cardinalities())

        return result

    def _parse_cardinalities(self, query_plan=None):
        '''
        Read the query plan and return the list of cardinalities
        If query_plan is None, use self.query_plan. The argument is used for recursion
        '''

        top_level_node = False
        if query_plan is None:
            query_plan = self.query_plan
            top_level_node = True

        cardinalities = {
            'node_type': [],
            'join_level': [],
            'estimated': [],
            'actual': []
        }

        # parent nodes
        try:
            for subplan in query_plan['Plans']:
                subplan_cardinalities = {}
                subplan_cardinalities = self._parse_cardinalities(subplan)

                cardinalities['node_type'] += subplan_cardinalities['node_type']
                cardinalities['join_level'] += subplan_cardinalities['join_level']
                cardinalities['estimated'] += subplan_cardinalities['estimated']
                cardinalities['actual'] += subplan_cardinalities['actual']

                if subplan_cardinalities['actual'] == 1:
                    print(subplan_cardinalities['node_type'])

            max_join_level = max(cardinalities['join_level'])
            if top_level_node:
                self.max_join_level = max_join_level

            # ignore aggregate nodes, because their selectivity is not
            # interesting
            if query_plan['Node Type'] != 'Aggregate':
                cardinalities['node_type'].append(query_plan['Node Type'])
                cardinalities['estimated'].append(query_plan['Plan Rows'])
                cardinalities['actual'].append(query_plan['Actual Rows'])

                if query_plan['Node Type'] in ['Hash Join', 'Nested Loop', 'Merge Join']:
                    cardinalities['join_level'].append(max_join_level + 1)
                else:
                    cardinalities['join_level'].append(max_join_level)

        # leaf nodes
        except KeyError as e:
            # ignore aggregate nodes, because their selectivity is not
            # interesting
            if query_plan['Node Type'] != 'Aggregate':
                cardinalities['node_type'].append(query_plan['Node Type'])
                cardinalities['join_level'].append(0)
                cardinalities['estimated'].append(query_plan['Plan Rows'])
                cardinalities['actual'].append(query_plan['Actual Rows'])

        return cardinalities

    def _parse_cardinalities_no_execute(self, query_plan=None):
        '''
        Read the query plan and return the list of cardinalities
        If query_plan is None, use self.query_plan. The argument is used for recursion
        '''

        top_level_node = False
        if query_plan is None:
            query_plan = self.query_plan
            top_level_node = True

        cardinalities = {
            'node_type': [],
            'join_level': [],
            'estimated': []
        }

        # parent nodes
        try:
            for subplan in query_plan['Plans']:
                subplan_cardinalities = {}
                subplan_cardinalities = self._parse_cardinalities(subplan)

                cardinalities['node_type'] += subplan_cardinalities['node_type']
                cardinalities['join_level'] += subplan_cardinalities['join_level']
                cardinalities['estimated'] += subplan_cardinalities['estimated']

                if subplan_cardinalities['actual'] == 1:
                    print(subplan_cardinalities['node_type'])

            max_join_level = max(cardinalities['join_level'])
            if top_level_node:
                self.max_join_level = max_join_level

            # ignore aggregate nodes, because their selectivity is not
            # interesting
            if query_plan['Node Type'] != 'Aggregate':
                cardinalities['node_type'].append(query_plan['Node Type'])
                cardinalities['estimated'].append(query_plan['Plan Rows'])

                if query_plan['Node Type'] in ['Hash Join', 'Nested Loop', 'Merge Join']:
                    cardinalities['join_level'].append(max_join_level + 1)
                else:
                    cardinalities['join_level'].append(max_join_level)

        # leaf nodes
        except KeyError as e:
            # ignore aggregate nodes, because their selectivity is not
            # interesting
            if query_plan['Node Type'] != 'Aggregate':
                cardinalities['node_type'].append(query_plan['Node Type'])
                cardinalities['join_level'].append(0)
                cardinalities['estimated'].append(query_plan['Plan Rows'])

        return cardinalities

    def q_error(self):
        '''
        Compute the q-error of the top-most join node in the query
        '''
        top_plan_node = self.cardinalities.iloc[self.cardinalities.join_level.idxmax(
        )]
        return q_error(top_plan_node.estimated, top_plan_node.actual)


def usage():
    help_text = '''Usage:
    {0} CONNECTION_STRING QUERIES
    {0} QUERY_RESULTS_FILE

    CONNECTION_STRING must be a libpq-valid connection string, between
    quotes.
    See https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING

    QUERIES must be a list of files or directories. Files must contain one and
    only one query; directories must contain .sql files containing one and only
    one query.

    If the queries have been executed before, their result has been stored in
    the file {1}. It is possible to re-use the results instead of re-executing
    all the queries by supplying the filename as argument.

    The resulting graphs are saved in {2}.

    Example:
    {0} 'host=localhost port=5432 user=postgres dbname=postgres' q1.sql q2.sql queries/
    {0} {1}
    '''.format(sys.argv[0], QUERY_RESULTS_FILE, GRAPHS_FILE)
    return help_text


def parse_query_args(query_args):
    '''
    Get the queries in the files and directories specified in query_args
    '''
    queries = []

    for query_arg in query_args:
        # if the argument is a directory, get sql files in it
        if os.path.isdir(query_arg):
            query_args += glob.glob(os.path.join(query_arg, '*.sql'))
        # if the argument is a file, read its content and add it to the
        # queries
        elif os.path.isfile(query_arg):
            queries.append(QueryResult(query_arg))
        # if the argument is neither a file nor a directory, raise an
        # exception
        else:
            raise FileNotFoundError(
                errno.ENOENT, os.strerror(errno.ENOENT), query_arg)

    return queries


def execute_queries(pg_url, queries):
    '''
    Execute an EXPLAIN ANALYZE of each query and parse the output to get the
    relevant execution information
    '''
    print("Execute query!")
    return
    db = Postgres(pg_url)
    for i, query in enumerate(queries):
        print('Executing query ' + query.filename +
              '... (' + str(i+1) + '/' + str(len(queries)) + ')')
        query.explain(db)

    # save the results to re-use them later
    pickle.dump(queries, open(QUERY_RESULTS_FILE, 'wb'))


def visualize(queries):
    '''
    Generate all interesting graphs from the set of queries
    '''
    plot_functions = [
        plot_plan_node_q_error_vs_join_level,
        plot_q_error_vs_query,
        plot_query_q_error_vs_join_tree_depth,
        plot_execution_time_vs_total_cost,
        plot_actual_vs_estimated,
        plot_q_error_distribution_vs_join_level,
    ]

    with PdfPages(GRAPHS_FILE) as pdf:
        for plot_function in plot_functions:
            # style parameters that will be applied to all plots
            seaborn.set_context('paper')
            seaborn.set_style('white')
            plt.rc("axes.spines", top=False, right=False)

            plt.figure()
            plot = plot_function(queries)
            try:
                pdf.savefig(plot.figure)
            except(AttributeError):
                pdf.savefig(plot.fig)

            # also save the figure as png
            file_name = os.path.join(
                OUTPUT_DIR, plot_function.__name__ + '.png')
            try:
                plot.get_figure().savefig(file_name)
            except(AttributeError):
                plot.savefig(file_name)

            plt.cla()
            plt.clf()
            seaborn.set()


def q_error(estimated, actual):
    '''
    Compute the q-error for the given selectivities
    Return the negative q-error if it's an underestimation, positive for
    overestimation
    '''
    # overestimation
    if estimated > actual:
        actual = max(actual, 1)  # prevent division by zero
        return estimated / actual
    # underestimation
    else:
        estimated = max(estimated, 1)  # prevent division by zero
        return actual / estimated * -1


def ceil_power_of_ten(n):
    '''
    Compute the closest power of 10 greater than n
    '''
    return 10**(ceil(log(n, 10)))


def plot_plan_node_q_error_vs_join_level(queries):
    # concatenate single queries cardinalities stats
    cardinalities = pd.concat(
        [query.cardinalities for query in queries], ignore_index=True)

    # filter out non-join nodes
    cardinalities = cardinalities.loc[
        (cardinalities['node_type'].isin(['Nested Loop', 'Hash Join', 'Merge Join'])) |
        (cardinalities['join_level'] == 0)
    ]

    # compute the q-errors and store them in the dataframe
    cardinalities['q_error'] = cardinalities.apply(
        lambda row: q_error(row.estimated, row.actual), axis=1)

    plot = seaborn.boxplot('join_level', 'q_error',
                           data=cardinalities, palette='muted', linewidth=1)
    plot.set(yscale='symlog')
    plot.set_title('Plan node q-error vs its join level')
    return plot


def plot_q_error_vs_query(queries):
    # concatenate single queries cardinalities stats
    cardinalities = pd.concat([query.cardinalities.assign(
        filename=query.filename) for query in queries], ignore_index=True)
    # compute the q-errors and store them in the dataframe
    cardinalities['q_error'] = cardinalities.apply(
        lambda row: q_error(row.estimated, row.actual), axis=1)

    plt.figure(figsize=(8, len(queries) * 0.2))
    plot = seaborn.stripplot(
        y='filename',
        x='q_error',
        data=cardinalities.sort_values(by='filename'),
        palette='muted',
    )
    plot.set(xscale='symlog')
    plot.set_title('Q-error of each node plan, grouped by query')
    return plot


def plot_query_q_error_vs_join_tree_depth(queries):
    data = {
        'q_error': [query.q_error() for query in queries],
        'join_level': [query.max_join_level for query in queries]
    }
    data = pd.DataFrame(data)
    plot = seaborn.boxplot('join_level', 'q_error',
                           data=data, palette='muted', linewidth=1)
    plot.set(yscale='symlog')
    plot.set_title('Query q-error vs its join tree depth')
    return plot


def plot_execution_time_vs_total_cost(queries):
    data = {
        'execution_time': [query.execution_time for query in queries],
        'total_cost': [query.total_cost for query in queries]
    }
    data = pd.DataFrame(data)

    plot = seaborn.regplot('total_cost', 'execution_time', data, fit_reg=False)
    plot.set(
        xscale='log',
        yscale='log',
        xlim=(1, ceil_power_of_ten(data['total_cost'].max())),
        ylim=(1, ceil_power_of_ten(data['execution_time'].max()))
    )
    plot.set_title('Execution time of a query vs its planned cost')
    plot.set(xlabel='Planned cost', ylabel='Execution time (ms)')
    return plot


def plot_actual_vs_estimated(queries):
    # concatenate single queries cardinalities stats
    cardinalities = pd.concat(
        [query.cardinalities for query in queries], ignore_index=True)
    max_join_level = max([query.max_join_level for query in queries])

    plot = seaborn.lmplot(
        'estimated',
        'actual',
        data=cardinalities,
        hue='join_level',
        palette=seaborn.cubehelix_palette(
            n_colors=max_join_level+1,
            start=2.6,
            rot=.1,
            light=.70
        ),
        fit_reg=False,
        x_jitter=1
    )
    plot.set(
        xscale='log',
        yscale='log',
        xlim=(0, cardinalities['estimated'].max()),
        ylim=(1, cardinalities['actual'].max())
    )
    plot.fig.suptitle('Actual cardinalities vs estimated cardinalities')
    plot.set(xlabel='Estimated cost', ylabel='Actual cost')

    # show a red line representing the ideal case (where the estimation is perfectly accurate)
    plt.plot([0, 10000000], [0, 10000000], linewidth=1, color='red')
    plt.show()
    return plot


def plot_q_error_distribution_vs_join_level(queries):
    # concatenate single queries cardinalities stats
    cardinalities = pd.concat(
        [query.cardinalities for query in queries], ignore_index=True)

    # compute the q-errors and store them in the dataframe
    cardinalities['q_error'] = cardinalities.apply(
        lambda row: q_error(row.estimated, row.actual), axis=1)

    plt.figure(figsize=(10, 6))
    plot = seaborn.stripplot(
        'join_level', 'q_error', data=cardinalities, palette='muted', size=3, jitter=0.4)
    plot.set(yscale='symlog')
    plot.set_title('Q-error distribution vs node join level')
    plot.set(xlabel='Join level', ylabel='Q-error')
    return plot


def postgres_triplet_cost_parse(q, anchor='CTE Scan', start_up_cost_name='Startup Cost', total_cost_name='Total Cost'):
    total_cost = q.query_plan[total_cost_name]
    sub_plan = q.query_plan['Plans']
    # print(q.query_plan)
    # assert len(sub_plan) == 3
    CTE_cost = sub_plan[0][total_cost_name]

    if is_CTE_scan(sub_plan[1], anchor, start_up_cost_name=start_up_cost_name, total_cost_name=total_cost_name):
        CTE_scan_cost = is_CTE_scan(sub_plan[1], anchor, start_up_cost_name=start_up_cost_name, total_cost_name=total_cost_name)
    else:
        CTE_scan_cost = is_CTE_scan(sub_plan[2], anchor, start_up_cost_name=start_up_cost_name, total_cost_name=total_cost_name)
    
    # if not CTE_scan_cost:
    #     print(sub_plan)
    #     exit(1)

    # total_useful_cost = total_cost - CTE_scan_cost - CTE_cost

    # print("Total cost ", total_cost)
    # print("CTE_cost ", CTE_cost)
    # print("CTE_scan_cost ", CTE_scan_cost)
    # return total_cost, CTE_scan_cost
    return total_cost, -1 # (CTE_scan_cost + CTE_cost)


def is_CTE_scan(plan_json, anchor, start_up_cost_name='Startup Cost', total_cost_name='Total Cost'):
    # print("str(plan)", str(plan_json).lower())
    # exit(1)

    if anchor.lower() in str(plan_json).lower():
        q = deque()
        q.append(plan_json)
        while q:
            c = q.popleft()
            if 'cte scan' not in c['Node Type'].lower():
                for p in c['Plans']:
                    q.append(p)
            else:
                break
        return c[total_cost_name] - c[start_up_cost_name]
    else:
        return None


if __name__ == '__main__':
    # if args are a connection string and a list of queries
    if len(sys.argv) >= 3:
        try:
            # first argument is postgresql's connection string
            pg_url = sys.argv[1]

            # all other arguments are files containing single queries or directories
            # containing those files
            queries = parse_query_args(sys.argv[2:])

        # if we don't have the correct amount of arguments, print the help text
        except(IndexError) as e:
            print(usage())
            exit(1)

        # execute the queries and collect the execution stats
        execute_queries(pg_url, queries)
    # if args is a file containing the result of queries
    else:
        try:
            # argument must be a pickle file containing the result of queries previously executed
            queries = pickle.load(open(sys.argv[1], 'rb'))
        except(IndexError):
            print(usage())
            exit(1)

    # generate all the relevant graphs
    visualize(queries)
