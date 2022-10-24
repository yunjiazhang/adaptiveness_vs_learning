SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, p_partkey)) FROM part WHERE p_type like '%BRASS' and p_size = 15;
SELECT sum(pg_lip_bloom_add(1, r_regionkey)) FROM region WHERE r_name = 'EUROPE';

select
	s_acctbal,
	s_name,
	n_name,
	p_partkey,
	p_mfgr,
	s_address,
	s_phone,
	s_comment
from
	part,
	supplier,
	(
		SELECT * FROM partsupp
		WHERE pg_lip_bloom_probe(0, ps_partkey)
	) AS partsupp
	,
	(
		SELECT * FROM nation
		WHERE 
		pg_lip_bloom_probe(1, n_regionkey)
	) AS nation,
	region
where
	p_partkey = ps_partkey
	and s_suppkey = ps_suppkey
	and p_size = 15
	and p_type like '%BRASS'
	and s_nationkey = n_nationkey
	and n_regionkey = r_regionkey
	and r_name = 'EUROPE'
	and ps_supplycost = (
		select
			min(ps_supplycost)
		from
			partsupp,
			supplier,
			(
				SELECT * FROM nation
				WHERE 
				pg_lip_bloom_probe(1, n_regionkey)
			) AS nation,
			region
		where
			p_partkey = ps_partkey
			and s_suppkey = ps_suppkey
			and s_nationkey = n_nationkey
			and n_regionkey = r_regionkey
			and r_name = 'EUROPE'
	)
order by
	s_acctbal desc,
	n_name,
	s_name,
	p_partkey
LIMIT 100
;