/*+ NestLoop(k mk mi_idx t it2 mi kt mc ct cn it1)
 HashJoin(k mk mi_idx t it2 mi kt mc ct cn)
 HashJoin(k mk mi_idx t it2 mi kt mc ct)
 HashJoin(k mk mi_idx t it2 mi kt mc)
 NestLoop(k mk mi_idx t it2 mi kt)
 NestLoop(k mk mi_idx t it2 mi)
 NestLoop(k mk mi_idx t it2)
 NestLoop(k mk mi_idx t)
 NestLoop(k mk mi_idx)
 NestLoop(k mk)
 SeqScan(k)
 IndexScan(mk)
 IndexScan(mi_idx)
 IndexScan(t)
 IndexScan(it2)
 IndexScan(mi)
 SeqScan(kt)
 SeqScan(mc)
 SeqScan(ct)
 SeqScan(cn)
 IndexScan(it1)
 Leading(((((((((((k mk) mi_idx) t) it2) mi) kt) mc) ct) cn) it1)) */
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
  AND mi.info IN ('Germany',
                  'German',
                  'USA',
                  'American')
  AND mi_idx.info < '7.0'
  AND t.production_year > 2008
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

