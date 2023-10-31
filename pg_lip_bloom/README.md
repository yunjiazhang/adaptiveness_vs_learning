## Compile and install 
We use Makefile to make the installation procedure fluent. The default PostgreSQL installation directory ```/data/postgresql-12.5```. If you use other directories, change the ```PG_DIR``` in ```Makefile```.

Specifically, 1) run ```make``` to compile; 2) run ```make install``` to copy the compiled files to PostgreSQL directory; 3) run ```make clean``` to clean the compiled files if needed.

