/*+ NestLoop(t mi_idx it2 mi mc it1 cn ct)
 NestLoop(t mi_idx it2 mi mc it1 cn)
 NestLoop(t mi_idx it2 mi mc it1)
 NestLoop(t mi_idx it2 mi mc)
 NestLoop(t mi_idx it2 mi)
 NestLoop(t mi_idx it2)
 NestLoop(t mi_idx)
 SeqScan(t)
 IndexScan(mi_idx)
 IndexScan(it2)
 IndexScan(mi)
 IndexScan(mc)
 IndexScan(it1)
 IndexScan(cn)
 SeqScan(ct)
 Leading((((((((t mi_idx) it2) mi) mc) it1) cn) ct)) */
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS mainstream_movie
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
                  'Horror',
                  'Western',
                  'Family')
  AND mi_idx.info > '7.0'
  AND t.production_year BETWEEN 2000 AND 2010
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

