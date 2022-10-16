

-- EXPLAIN ANALYZE 
-- SELECT SUM(lo_revenue), d_year, p_brand1
-- FROM lineorder,
--      ddate,
--      part,
--      supplier
-- WHERE lo_orderdate = d_datekey
--   AND lo_partkey = p_partkey
--   AND lo_suppkey = s_suppkey
--   AND p_category = 'MFGR#12'
--   AND s_region = 'AMERICA'
-- GROUP BY d_year, p_brand1
-- ORDER BY d_year, p_brand1;

DROP EXTENSION pg_lip_bloom; CREATE EXTENSION pg_lip_bloom;

SELECT pg_lip_bloom_init(2);

SELECT sum(pg_lip_bloom_add(0, part.p_partkey)) FROM part WHERE p_category = 'MFGR#12';
SELECT sum(pg_lip_bloom_add(1, supplier.s_suppkey)) FROM supplier WHERE s_region = 'AMERICA';
SELECT pg_lip_bloom_info();
SELECT pg_lip_bloom_make_shared();

EXPLAIN ANALYZE 
SELECT count(*)
FROM  
(
     SELECT *
     FROM lineorder 
     WHERE pg_lip_bloom_probe(1, lo_suppkey)
     AND pg_lip_bloom_probe(0, lo_partkey) 
) AS lineorder_bf,
     ddate,
     part,
     supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
-- GROUP BY d_year, p_brand1
-- ORDER BY d_year, p_brand1
;

EXPLAIN ANALYZE 
WITH lineorder_bf AS  (
     SELECT *
     FROM lineorder 
     WHERE pg_lip_bloom_probe(1, lo_suppkey)
     AND pg_lip_bloom_probe(0, lo_partkey) 
) 
SELECT count(*)
FROM  
    lineorder_bf,
     ddate,
     part,
     supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
-- GROUP BY d_year, p_brand1
-- ORDER BY d_year, p_brand1
;


EXPLAIN ANALYZE 
SELECT count(*)
FROM  
     lineorder,
     ddate,
     part,
     supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
  AND pg_lip_bloom_probe(0, lo_partkey)
  AND pg_lip_bloom_probe(1, lo_suppkey);
-- GROUP BY d_year, p_brand1
-- ORDER BY d_year, p_brand1


-- SELECT pg_lip_bloom_free();



EXPLAIN ANALYZE SELECT count(*)
FROM lineorder,
     ddate,
     part,
     supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
;
