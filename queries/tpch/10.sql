-- using default substitutions


select
count(*)

from
	customer,
	orders,
	lineitem,
	nation
where
	c_custkey = o_custkey
	and l_orderkey = o_orderkey
	and o_orderdate >= '1993-10-01'
	and o_orderdate < '1994-01-01'
	and l_returnflag = 'R'
	and c_nationkey = n_nationkey
;