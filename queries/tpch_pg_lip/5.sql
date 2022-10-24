-- using default substitutions
SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, c_custkey)) FROM customer WHERE c_mktsegment = 'BUILDING';
-- SELECT sum(pg_lip_bloom_add(1, l_orderkey)) FROM lineitem WHERE l_shipdate > '1995-03-15';

/*+
Leading((((((nation region) customer) orders) lineitem) supplier))
*/
select
	count(*)
from
	customer,
	orders,
	lineitem,
	supplier,
	nation,
	region
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and l_suppkey = s_suppkey
	and c_nationkey = s_nationkey
	and s_nationkey = n_nationkey
	and n_regionkey = r_regionkey
	and r_name = 'ASIA'
	and o_orderdate >= '1994-01-01'
	and o_orderdate < '1994-02-01';
