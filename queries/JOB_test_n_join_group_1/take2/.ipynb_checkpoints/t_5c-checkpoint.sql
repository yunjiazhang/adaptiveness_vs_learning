/*+ HashJoin(ct mc t mi it)
 MergeJoin(mc t mi it)
 HashJoin(t mi it)
 HashJoin(mi it)
 SeqScan(ct)
 SeqScan(mc)
 SeqScan(t)
 SeqScan(mi)
 SeqScan(it)
 Leading((ct (mc (t (mi it))))) */
 SELECT MIN(t.title) AS american_movie
FROM company_type AS ct,
     info_type AS it,
     movie_companies AS mc,
     movie_info AS mi,
     title AS t
WHERE ct.kind = 'production companies'
  AND mc.note NOT LIKE '%(TV)%'
  AND mc.note LIKE '%(USA)%'
  AND mi.info IN ('Sweden',
                  'Norway',
                  'Germany',
                  'Denmark',
                  'Swedish',
                  'Denish',
                  'Norwegian',
                  'German',
                  'USA',
                  'American')
  AND t.production_year > 1990
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND mc.movie_id = mi.movie_id
  AND ct.id = mc.company_type_id
  AND it.id = mi.info_type_id;

