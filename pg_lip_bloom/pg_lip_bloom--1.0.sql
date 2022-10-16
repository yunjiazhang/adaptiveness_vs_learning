<<<<<<< HEAD
-- DROP EXTENSION pg_lip_bloom; 
-- CREATE EXTENSION pg_lip_bloom;
=======
>>>>>>> 0211cac98151baf7e9e0f53e9528f27474158666

CREATE OR REPLACE  FUNCTION pg_lip_bloom_init(integer) RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_init'
     LANGUAGE C STRICT PARALLEL UNSAFE;

<<<<<<< HEAD
CREATE OR REPLACE  FUNCTION pg_lip_bloom_set_dynamic(integer) RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_set_dynamic'
     LANGUAGE C STRICT PARALLEL UNSAFE;

=======
>>>>>>> 0211cac98151baf7e9e0f53e9528f27474158666
CREATE OR REPLACE FUNCTION pg_lip_bloom_add(integer, integer) RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_add'
     LANGUAGE C STRICT PARALLEL SAFE;

-- CREATE OR REPLACE FUNCTION pg_lip_bloom_add(integer, integer) RETURNS integer
--      AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_add'
--      LANGUAGE C STRICT PARALLEL UNSAFE;

CREATE OR REPLACE FUNCTION pg_lip_bloom_probe(integer, integer) RETURNS boolean
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_probe'
     LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_lip_bloom_info() RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_info'
     LANGUAGE C STRICT PARALLEL UNSAFE;

<<<<<<< HEAD
=======
CREATE OR REPLACE FUNCTION pg_lip_bloom_make_shared() RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_make_shared'
     LANGUAGE C STRICT PARALLEL UNSAFE;

>>>>>>> 0211cac98151baf7e9e0f53e9528f27474158666
CREATE OR REPLACE FUNCTION pg_lip_bloom_free() RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_free'
     LANGUAGE C STRICT PARALLEL UNSAFE;

CREATE OR REPLACE FUNCTION pg_lip_bloom_bit_and(integer, integer, integer) RETURNS integer
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_bit_and'
     LANGUAGE C STRICT PARALLEL UNSAFE;
<<<<<<< HEAD


CREATE OR REPLACE FUNCTION pg_lip_bloom_func_call_overhead_test() RETURNS boolean
     AS '/mnt/pg_lip_bloom/pg_lip_bloom/pg_lip_bloom', 'pg_lip_bloom_func_call_overhead_test'
     LANGUAGE C STRICT PARALLEL SAFE;
=======
>>>>>>> 0211cac98151baf7e9e0f53e9528f27474158666
