-- using default substitutions

WITH R (supplier_no, total_revenue) AS
	(select
		l_suppkey,
		sum(l_extendedprice * (1 - l_discount))
	from
		lineitem
	where
		l_shipdate >= '1996-01-01'
		and l_shipdate < '1996-04-01'
	group by
		l_suppkey
)
select
count(*)
from
	supplier,
	R
where
	s_suppkey = supplier_no
	and total_revenue = (
		select
			max(total_revenue)
		from
			R
	)
group by 
	s_suppkey
order by
	s_suppkey;

