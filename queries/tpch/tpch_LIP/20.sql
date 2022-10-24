SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, p_partkey)) FROM part WHERE p_name like 'forest%';
SELECT sum(pg_lip_bloom_add(1, n_nationkey)) FROM nation WHERE n_name = 'CANADA';

select
	s_name,
	s_address
from
	(
		select * from supplier
		where pg_lip_bloom_probe(1, s_nationkey)
	) as supplier,
	nation
where
	s_suppkey in (
		select
			ps_suppkey
		from
			partsupp
		where
			pg_lip_bloom_probe(0, ps_partkey)
			and ps_availqty > (
				select
					0.5 * sum(l_quantity)
				from
					lineitem
				where
					l_partkey = ps_partkey
					and l_suppkey = ps_suppkey
					and l_shipdate >= '1994-01-01'
					and l_shipdate < '1995-01-01'
			)
	)
	and s_nationkey = n_nationkey
	and n_name = 'CANADA'
order by
	s_name
LIMIT 1;