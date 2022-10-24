SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, c_custkey)) FROM customer WHERE c_mktsegment = 'BUILDING';
-- SELECT sum(pg_lip_bloom_add(1, l_orderkey)) FROM lineitem WHERE l_shipdate > '1995-03-15';

select
count(*)
from
	customer,
	(
		select * from orders
		-- where pg_lip_bloom_probe(1, o_orderkey)
	) as orders,
	lineitem
where
	c_mktsegment = 'BUILDING'
	and c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate < '1995-03-15'
	and l_shipdate > '1995-03-15';
