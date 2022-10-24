SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, r_regionkey)) FROM region WHERE r_name = 'AMERICA';
SELECT sum(pg_lip_bloom_add(1, p_partkey)) FROM part WHERE p_type = 'ECONOMY ANODIZED STEEL';

/*+
Leading((((((((customer n1) region) orders) lineitem) part) supplier) n2))
*/
select
	o_year,
	sum(case
		when nation = ':1' then volume
		else 0
	end) / sum(volume) as mkt_share
from
	(
		select
			extract(year from o_orderdate) as o_year,
			l_extendedprice * (1 - l_discount) as volume,
			n2.n_name as nation
		from
			part,
			supplier,
			(
				SELECT * FROM lineitem
				WHERE pg_lip_bloom_probe(1, l_partkey) 
			) as lineitem,
			orders,
			customer,
			(
				SELECT * FROM nation as n1
				WHERE pg_lip_bloom_probe(0, n_regionkey)
			) as n1,
			nation n2,
			region
		where
			p_partkey = l_partkey
			and s_suppkey = l_suppkey
			and l_orderkey = o_orderkey
			and o_custkey = c_custkey
			and c_nationkey = n1.n_nationkey
			and n1.n_regionkey = r_regionkey
			and r_name = 'AMERICA'
			and s_nationkey = n2.n_nationkey
			and o_orderdate between  '1995-01-01' and  '1996-12-31'
			and p_type = 'ECONOMY ANODIZED STEEL'
	) as all_nations
group by
	o_year
order by
	o_year
LIMIT 1;