/*+ HashJoin(it1 cn mi t it2 ct mc mi_idx)
 HashJoin(cn mi t it2 ct mc mi_idx)
 MergeJoin(mi t it2 ct mc mi_idx)
 HashJoin(t it2 ct mc mi_idx)
 NestLoop(it2 ct mc mi_idx)
 NestLoop(ct mc mi_idx)
 NestLoop(mc mi_idx)
 IndexScan(it1)
 IndexScan(cn)
 IndexScan(mi)
 SeqScan(t)
 SeqScan(it2)
 SeqScan(ct)
 SeqScan(mc)
 IndexScan(mi_idx)
 Leading((it1 (cn (mi (t (it2 (ct (mc mi_idx)))))))) */
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS drama_horror_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     info_type AS it2,
     movie_companies AS mc,
     movie_info AS mi,
     movie_info_idx AS mi_idx,
     title AS t
WHERE cn.country_code = '[us]'
  AND ct.kind = 'production companies'
  AND it1.info = 'genres'
  AND it2.info = 'rating'
  AND mi.info IN ('Drama',
                  'Horror')
  AND mi_idx.info > '8.0'
  AND t.production_year BETWEEN 2005 AND 2008
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND mi.info_type_id = it1.id
  AND mi_idx.info_type_id = it2.id
  AND t.id = mc.movie_id
  AND ct.id = mc.company_type_id
  AND cn.id = mc.company_id
  AND mc.movie_id = mi.movie_id
  AND mc.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id;

