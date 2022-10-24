-- using default substitutions


select
	count(*)

from
	orders
where
	o_orderdate >= '1993-07-01'
	and o_orderdate < '1993-10-01'
	and exists (
		select
			*
		from
			lineitem
		where
			l_orderkey = o_orderkey
			and l_commitdate < l_receiptdate
	)
;