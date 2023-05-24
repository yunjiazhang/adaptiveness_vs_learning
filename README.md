# Simple Adaptive Query Processing vs. Learned Query Optimizers: Observations and Analysis #

This is the code repository for the submitted VLDB 2023 paper: *Simple Adaptive Query Processing vs. Learned Query Optimizers: Observations and Analysis*. In this repository, we include the postgres extension we used and provide links to the baseline methods.

## Overview ##
* ```./pg_lip_bloom/``` contains the PostgreSQL extesnion of LIP.
* ```./queries/``` contains the queries for eavluation. 
* ```./runtime_eval/``` contains the external python code to obtain the workload run times. 

## Preperation ## 

## Installing Postgres Extension ##

### Requirements ###


### Compiling the extension ###
We use Makefile to make the installation procedure fluent. The default PostgreSQL installation directory ```/data/postgresql-12.5```. If you use other directories, change the ```PG_DIR``` in ```Makefile```. To compile, simply run ```make```.

### Installing the extension ###
Simply run ```make install``` to copy the compiled files to PostgreSQL directory. Run ```make clean``` to clean the compiled files if needed.

## Usage Example ##
To use ```pg_lip```, we need to first rewrite the query with the extension functions provided, then the query can be directly run with the PostgreSQL. For a new PostgreSQL session, run ```CREATE EXTENSION pg_lip_bloom;``` to create the extension.

![Alt text](docs/query_example.jpg?raw=true "Query rewriting example")

## Evaluating Runtimes ## 

## Baseline RL-based Query Optimizers ## 
We used the original repo provided by the authors of [Bao](https://github.com/learnedsystems/BaoForPostgreSQL) and [Balsa](https://github.com/balsa-project/balsa) to conduct our comparative study. We are thankful to the authors of Balsa and Bao for transparency in their work and releasing their code. Our research would have been far more difficult and the results harder to understand without this gracious contribution by the Balsa and Bao team.

## Citation ##

TBD

## License and Acknowledgements

MIT License

Copyright (c) 2023 Yunjia Zhang

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.





