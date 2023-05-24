# pg_lip_bloom
We implement the key bloom filter function of [LIP](https://www.vldb.org/pvldb/vol10/p889-zhu.pdf) in PostgreSQL as an extension pg_lip_bloom. LIP utilizes the semijoin techinique to optimize the equijoin execution pipeline. 

## Prepare PostgreSQL
Clone the code base of the PostgreSQL
```bash
wget https://ftp.postgresql.org/pub/source/v12.5/postgresql-12.5.tar.gz
tar xzvf postgresql-12.5.tar.gz
```
Compile and install 
```
cd postgresql-12.5
./configure --prefix=/data/postgresql-12.5 --without-readline
sudo make -j
sudo make install
echo 'export PATH=/data/postgresql-12.5/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Compile and install 
We use Makefile to make the installation procedure fluent. The default PostgreSQL installation directory ```/data/postgresql-12.5```. If you use other directories, change the ```PG_DIR``` in ```Makefile```.

Specifically, 1) run ```make``` to compile; 2) run ```make install``` to copy the compiled files to PostgreSQL directory; 3) run ```make clean``` to clean the compiled files.

## Usage example
To use ```pg_lip```, we need to first rewrite the query with the extension functions provided, then the query can be directly run with the PostgreSQL. For a new PostgreSQL session, run ```CREATE EXTENSION pg_lip_bloom;``` to create the extension.

![Alt text](docs/query_example.jpg?raw=true "Query rewriting example")

### Auto query rewriting
For JOB queries, we provide a auto query rewriting tool ```./lip_query_rewriter/rewriter.py```. The main function rewrites all the queries in ```all_files``` and output the rewriten queries to the subdir ```lip_auto_rewrite/```. Note that this rewriter needs to interact with PostgreSQL and only works on JOB queries. 

## License and Acknowledgements
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this repo except in compliance with the License.
You may obtain a copy of the License at:

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

This work was supported by Amazon under an ARA Award, by NSF under grant IIS-1755676, and by DARPA under grant ASKE HR00111990013.
