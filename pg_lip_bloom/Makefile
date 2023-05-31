CC=gcc
PG_DIR=/mnt/postgresql-12.5

pg_lip_bloom: 
	$(CC) -pthread -fPIC -I $(PG_DIR)/include/server/ -c pg_lip_bloom.c
	$(CC) -pthread -fPIC -I $(PG_DIR)/include/server/ -c bloom.c
	$(CC) -pthread -shared -I $(PG_DIR)/include/server/ -o pg_lip_bloom.so ./pg_lip_bloom.o ./bloom.o ./build/murmurhash2.o

install:
	sudo cp pg_lip_bloom.control $(PG_DIR)/share/extension/
	sudo cp pg_lip_bloom--1.0.sql $(PG_DIR)/share/extension/
	sudo cp pg_lip_bloom.so $(PG_DIR)/lib/

clean:
	rm pg_lip_bloom.so pg_lip_bloom.o bloom.o
