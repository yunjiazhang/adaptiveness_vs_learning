SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, o_orderkey)) FROM orders WHERE o_orderstatus = 'F';
SELECT sum(pg_lip_bloom_add(1, n_nationkey)) FROM nation WHERE n_name = 'SAUDI ARABIA';

select
	s_name,
	count(*) as numwait
from
	(
		select * from supplier
		where pg_lip_bloom_probe(1, s_nationkey)
	) as supplier,
	-- (
	-- 	select * from lineitem
	-- 	where pg_lip_bloom_probe(0, l_orderkey)
	-- )
	lineitem as l1,
	orders,
	nation
where
	s_suppkey = l1.l_suppkey
	and o_orderkey = l1.l_orderkey
	and o_orderstatus = 'F'
	and l1.l_receiptdate > l1.l_commitdate
	and exists (
		select
			*
		from
			lineitem l2
		where
			l2.l_orderkey = l1.l_orderkey
			and l2.l_suppkey <> l1.l_suppkey
	)
	and not exists (
		select
			*
		from
			lineitem l3
		where
			l3.l_orderkey = l1.l_orderkey
			and l3.l_suppkey <> l1.l_suppkey
			and l3.l_receiptdate > l3.l_commitdate
	)
	and s_nationkey = n_nationkey
	and n_name = 'SAUDI ARABIA'
group by
	s_name
order by
	numwait desc,
	s_name
LIMIT 100;