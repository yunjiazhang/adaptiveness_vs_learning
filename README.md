# Adaptiveness vs Learning  #

This is the code repository for the submitted VLDB 2023 paper: *Simple Adaptive Query Processing vs. Learned Query Optimizers: Observations and Analysis*. In this repository, we include the postgres extension we used and provide links to the baseline methods.

<!-- ## Overview ##
* ```./pg_lip_bloom/``` contains the PostgreSQL extesnion of LIP.
* ```./queries/``` contains the queries for eavluation. 
* ```./runtime_eval/``` contains the external python code to obtain the workload run times.  -->

## Preperation ## 
For preperation details of Postgres,  you may refer to the [Balsa repo](https://github.com/balsa-project/balsa). The following instructions are adapted from [Balsa repo](https://github.com/balsa-project/balsa).  

### Installing Postgres

* Download Postgres source code: 
```bash
cd /tmp/ # change to any directory to compile and download pg
wget https://ftp.postgresql.org/pub/source/v12.5/postgresql-12.5.tar.gz
tar xzvf postgresql-12.5.tar.gz
```

* Compile and install Postgres

The default installation location is ```/mnt/postgresql-12.5```. Change it to any other locations if needed. 
```bash
sudo apt update
sudo apt install build-essential zlib1g-dev
cd postgresql-12.5
./configure --prefix=/mnt/postgresql-12.5 --without-readline
sudo make -j
sudo make install
echo 'export PATH=/mnt/postgresql-12.5/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Installing pg_hint_plan 
```bash
sudo apt install git
cd /tmp/
git clone https://github.com/ossc-db/pg_hint_plan.git -b REL12_1_3_7
# Modify Makefile: change line
#   PG_CONFIG = pg_config
# to
#   PG_CONFIG = /mnt/postgresql-12.5/bin/pg_config
sudo make
sudo make install
```

### Loading IMDB data to Postgres

```bash
cd /tmp/
wget -c http://homepages.cwi.nl/~boncz/job/imdb.tgz && tar -xvzf imdb.tgz
```

<!-- For other config details such as loading IMDB data to Postgres and setting up ```pg_hint_plan```,  you may refer to the [Balsa repo](https://github.com/balsa-project/balsa) -->

## Installing LIP Extension for Postgres ##
First, clone this repository by running ```git clone https://github.com/yunjiazhang/adaptiveness_vs_learning.git```

### Requirements ###
The following is the system enviornment example that verified this extension works correctly. Other versions may also work correctly but not verified.

* Hardware config: Intel(R) Xeon(R) Gold 5115 CPU with 256G RAM
* System: Ubuntu 20.04.6 LTS
* Software:
    - GNU Make 4.2.1
    - gcc g++ 9.4.0

Python 3.9.12 is used for runtime evaluation only, see ```./runtime_eval/README.md``` for more details.

### Compiling the extension ###
We use Makefile to make the installation procedure fluent. The default PostgreSQL installation directory ```/mnt/postgresql-12.5```. If you use other directories, change the ```PG_DIR``` in ```Makefile```. To compile, simply run ```make```.

### Installing the extension ###
Simply run ```make install``` to copy the compiled files to PostgreSQL directory. Run ```make clean``` to clean the compiled files if needed.

## Usage Example ##
To use ```pg_lip```, we need to first rewrite the query with the extension functions provided, then the query can be directly run with the PostgreSQL. For a new PostgreSQL session, run ```CREATE EXTENSION pg_lip_bloom;``` to create the extension.

![Alt text](docs/query_example.jpg?raw=true "Query rewriting example")

### Auto query rewriting
For simple JOB queries, we provide a auto query rewriting tool ```./pg_lip_bloom/lip_query_rewriter/rewriter.py```. The main function rewrites all the queries in ```all_files``` and output the rewriten queries to the subdir ```./pg_lip_bloom/lip_auto_rewrite/```. Note that this rewriter only rewrite for LIP extension. It needs PostgreSQL to be running and accept connection at port 5432.

## Query Plans ## 
We provide JOB rewritten queries in ```./queries/job/LIP+AJA/```. The plans include both LIP and AJA, and also applied the optimization rules of LIP manually (see our paper in detail). 

## Evaluating Runtimes ## 
We provide a toolkit to evaluate the query workload runtime with and without LIP+AJA in ```./runtime_eval/```. To run the evaluation tool, first install the required python packages 
```bash
cd ./runtime_eval/
pip install -r requirements.txt
```
Then, you may refer to the notebook ```./runtime_eval/runtime_quality.ipynb``` for usage examples.

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





