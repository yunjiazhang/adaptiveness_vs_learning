-- using default substitutions


select
count(*)

from
	lineitem,
	part
where
	l_partkey = p_partkey
	and l_shipdate >= '1995-09-01'
	and l_shipdate < '1995-10-01';
