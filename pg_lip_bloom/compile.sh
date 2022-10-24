# # For the global installation of postgres (pg14)
# cc -fPIC -I /usr/include/postgresql/14/server/ -c pg_lip_bloom.c
# cc -fPIC -I /usr/include/postgresql/14/server/ -c bloom.c
# cc -shared -I /usr/include/postgresql/14/server/ -o pg_lip_bloom.so ./pg_lip_bloom.o ./bloom.o ./build/murmurhash2.o
# make install

# For any installation of postgres (pg12) 
# replace /data/postgresql-12.5 with your postgres installation directory
cc -pthread -fPIC -I /data/postgresql-12.5/include/server/ -c pg_lip_bloom.c
cc -pthread -fPIC -I /data/postgresql-12.5/include/server/ -c bloom.c
cc -pthread -shared -I /data/postgresql-12.5/include/server/ -o pg_lip_bloom.so ./pg_lip_bloom.o ./bloom.o ./build/murmurhash2.o
sudo cp pg_lip_bloom.control /data/postgresql-12.5/share/extension/
sudo cp pg_lip_bloom--1.0.sql /data/postgresql-12.5/share/extension/
