/*+ MergeJoin(k mk t mi_idx kt it2 mi it1 mc ct cn)
 MergeJoin(k mk t mi_idx kt it2 mi it1 mc ct)
 HashJoin(k mk t mi_idx kt it2 mi it1 mc)
 HashJoin(k mk t mi_idx kt it2 mi it1)
 NestLoop(k mk t mi_idx kt it2 mi)
 NestLoop(k mk t mi_idx kt it2)
 NestLoop(k mk t mi_idx kt)
 NestLoop(k mk t mi_idx)
 NestLoop(k mk t)
 NestLoop(k mk)
 SeqScan(k)
 IndexScan(mk)
 IndexScan(t)
 IndexScan(mi_idx)
 SeqScan(kt)
 IndexScan(it2)
 IndexScan(mi)
 SeqScan(it1)
 SeqScan(mc)
 SeqScan(ct)
 SeqScan(cn)
 Leading(((((((((((k mk) t) mi_idx) kt) it2) mi) it1) mc) ct) cn)) */
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
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
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

