-- Creating the functions used in the pg_lip extension 

CREATE OR REPLACE  FUNCTION pg_lip_bloom_init(integer) RETURNS integer
     AS 'pg_lip_bloom', 'pg_lip_bloom_init'
     LANGUAGE C STRICT PARALLEL UNSAFE;

CREATE OR REPLACE  FUNCTION pg_lip_bloom_set_dynamic(integer) RETURNS integer
     AS 'pg_lip_bloom', 'pg_lip_bloom_set_dynamic'
     LANGUAGE C STRICT PARALLEL UNSAFE;

CREATE OR REPLACE FUNCTION pg_lip_bloom_add(integer, integer) RETURNS integer
     AS 'pg_lip_bloom', 'pg_lip_bloom_add'
     LANGUAGE C STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION pg_lip_bloom_probe(integer, integer) RETURNS boolean
     AS 'pg_lip_bloom', 'pg_lip_bloom_probe'
     LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE 
     COST 1000; -- push the probe to the last of the predicates

CREATE OR REPLACE FUNCTION pg_lip_bloom_info() RETURNS integer
     AS 'pg_lip_bloom', 'pg_lip_bloom_info'
     LANGUAGE C STRICT PARALLEL UNSAFE;
     
------------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION pg_lip_bloom_probe_order_test_2(integer, integer, integer, integer, integer) RETURNS boolean
--      AS 'pg_lip_bloom', 'pg_lip_bloom_probe_order_test_2'
--      LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE 
--      COST 1000;

-- CREATE OR REPLACE FUNCTION pg_lip_bloom_probe_dynamic_2(integer, integer, integer, integer) RETURNS boolean
--      AS 'pg_lip_bloom', 'pg_lip_bloom_probe_dynamic_2'
--      LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE 
--      COST 1000;

-- CREATE OR REPLACE FUNCTION pg_lip_bloom_probe_order_test_3(integer, integer, integer, integer, integer, integer, integer) RETURNS boolean
--      AS 'pg_lip_bloom', 'pg_lip_bloom_probe_order_test_3'
--      LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE 
--      COST 1000;

-- CREATE OR REPLACE FUNCTION pg_lip_bloom_probe_dynamic_3(integer, integer, integer, integer, integer, integer) RETURNS boolean
--      AS 'pg_lip_bloom', 'pg_lip_bloom_probe_dynamic_3'
--      LANGUAGE C STRICT PARALLEL SAFE IMMUTABLE 
--      COST 1000;
------------------------------------------------------------------------------