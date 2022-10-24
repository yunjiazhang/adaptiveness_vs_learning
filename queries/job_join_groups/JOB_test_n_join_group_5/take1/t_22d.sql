/*+ HashJoin(k mk t mi_idx it2 kt mc mi it1 cn ct)
 NestLoop(k mk t mi_idx it2 kt mc mi it1 cn)
 NestLoop(k mk t mi_idx it2 kt mc mi it1)
 NestLoop(k mk t mi_idx it2 kt mc mi)
 NestLoop(k mk t mi_idx it2 kt mc)
 MergeJoin(k mk t mi_idx it2 kt)
 NestLoop(k mk t mi_idx it2)
 NestLoop(k mk t mi_idx)
 NestLoop(k mk t)
 NestLoop(k mk)
 IndexScan(k)
 IndexScan(mk)
 IndexScan(t)
 IndexScan(mi_idx)
 SeqScan(it2)
 SeqScan(kt)
 IndexScan(mc)
 IndexScan(mi)
 IndexScan(it1)
 IndexScan(cn)
 IndexScan(ct)
 Leading(((((((((((k mk) t) mi_idx) it2) kt) mc) mi) it1) cn) ct)) */
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_violent_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     kind_type AS kt,
     movie_companies AS mc,
     movie_info AS mi,
     movie_info_idx AS mi_idx,
     movie_keyword AS mk,
     title AS t
WHERE cn.country_code != '[us]'
  AND it1.info = 'countries'
  AND it2.info = 'rating'
  AND k.keyword IN ('murder',
                    'murder-in-title',
                    'blood',
                    'violence')
  AND kt.kind IN ('movie',
                  'episode')
  AND mi.info IN ('Sweden',
                  'Norway',
                  'Germany',
                  'Denmark',
                  'Swedish',
                  'Danish',
                  'Norwegian',
                  'German',
                  'USA',
                  'American')
  AND mi_idx.info < '8.5'
  AND t.production_year > 2005
  AND kt.id = t.kind_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND mk.movie_id = mc.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mc.movie_id
  AND mc.movie_id = mi_idx.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND ct.id = mc.company_type_id
  AND cn.id = mc.company_id;

