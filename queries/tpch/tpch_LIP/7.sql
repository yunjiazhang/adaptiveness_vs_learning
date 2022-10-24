SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, n_nationkey)) FROM nation as n1 WHERE n1.n_name = 'GERMANY' or n1.n_name = 'FRANCE';
-- SELECT sum(pg_lip_bloom_add(1, l_orderkey)) FROM lineitem WHERE l_shipdate between '1995-01-01' and  '1996-12-31';


/*+
Leading(((lintitem ((n2 customer) orders)) (n1 supplier)))
*/
select
	supp_nation,
	cust_nation,
	l_year,
	sum(volume) as revenue
from
	(
		select
			n1.n_name as supp_nation,
			n2.n_name as cust_nation,
			extract(year from l_shipdate) as l_year,
			l_extendedprice * (1 - l_discount) as volume
		from
			(
				SELECT * FROM supplier
				where pg_lip_bloom_probe(0, s_nationkey)
			) AS supplier,
			lineitem,
			orders,
			(
				SELECT * FROM customer
				WHERE pg_lip_bloom_probe(0, c_nationkey)
			) AS customer,
			nation n1,
			nation n2
		where
			s_suppkey = l_suppkey
			and o_orderkey = l_orderkey
			and c_custkey = o_custkey
			and s_nationkey = n1.n_nationkey
			and c_nationkey = n2.n_nationkey
			and (
				(n1.n_name = 'FRANCE' and n2.n_name = 'GERMANY')
				or (n1.n_name = 'GERMANY' and n2.n_name = 'FRANCE')
			)
			and l_shipdate between '1995-01-01' and  '1996-12-31'
	) as shipping
group by
	supp_nation,
	cust_nation,
	l_year
order by
	supp_nation,
	cust_nation,
	l_year
LIMIT 1;