SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM movie_companies AS mc WHERE  mc.note NOT LIKE '%(USA)%'
--               AND mc.note LIKE '%(200%)%';
-- SELECT sum(pg_lip_bloom_add(1, movie_id)) FROM movie_info AS mi WHERE  mi.info IN ('Germany',
--                   'German',
--                   'USA',
--                   'American');            
-- SELECT pg_lip_bloom_bit_and(1, 0, 1);
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it1 WHERE it1.info ='countries'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(4, id)) FROM info_type AS it2 WHERE it2.info ='rating'; -- filter on mc.company_id
-- SELECT sum(pg_lip_bloom_add(5, id)) FROM kind_type AS kt WHERE kt.kind IN ('movie', 'episode'); -- filter on mc.company_id



/*+
NestLoop(k mk t kt mi_idx it2 mi it1 mc cn ct)
NestLoop(k mk t kt mi_idx it2 mi it1 mc cn)
NestLoop(k mk t kt mi_idx it2 mi it1 mc)
NestLoop(k mk t kt mi_idx it2 mi it1)
NestLoop(k mk t kt mi_idx it2 mi)
NestLoop(k mk t kt mi_idx it2)
NestLoop(k mk t kt mi_idx)
NestLoop(k mk t kt)
NestLoop(k mk t)
NestLoop(k mk)
Leading(((((((it2 ((((k mk) t) kt) mi_idx)) mi) it1) mc) cn) ct))
*/
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
     (
       select * from movie_info as mi
       where pg_lip_bloom_probe(2, info_type_id)
     ) AS mi,
     (
        select * from movie_info_idx as mi_idx
        where pg_lip_bloom_probe(4, info_type_id) -- AND pg_lip_bloom_probe(1, movie_id)
      ) AS mi_idx,
     movie_keyword AS mk,
     (
         select * from title as t 
        --  where pg_lip_bloom_probe(5, kind_id) -- and pg_lip_bloom_probe(1, id)
     ) AS t 
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

