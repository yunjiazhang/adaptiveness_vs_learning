-- using default substitutions


select
	count(*)
from
	orders,
	lineitem
where
	o_orderkey = l_orderkey
	and l_shipmode in ('MAIL', 'SHIP')
	and l_commitdate < l_receiptdate
	and l_shipdate < l_commitdate
	and l_receiptdate >= '1994-01-01'
	and l_receiptdate < '1995-01-01'
;
