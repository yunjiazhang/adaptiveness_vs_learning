
# pg_lip_bloom: pg_lip_bloom.c
#      cc -fPIC -c pg_lip_bloom.c

# bloom: bloom.c
#      cc -fPIC -c bloom.c

# pg_lip_bloom:
# 	cc -shared -o pg_lip_bloom.so ./pg_lip_bloom.o ./bloom.o ./build/murmurhash2.o

EXTENSION = pg_lip_bloom
DATA = pg_lip_bloom--1.0.sql

# postgres build stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)