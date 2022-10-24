SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it WHERE it.info ='countries';
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type AS it2 WHERE it2.info ='rating';
-- SELECT sum(pg_lip_bloom_add(4, id)) FROM kind_type AS kt WHERE kt.kind ='movie';

/*+
NestLoop(k mk t kt mi it1 mi_idx it2)
NestLoop(k mk t kt mi it1 mi_idx)
NestLoop(k mk t kt mi it1)
NestLoop(k mk t kt mi)
NestLoop(k mk t kt)
NestLoop(k mk t)
NestLoop(k mk)
Leading((((((((k mk) t) kt) mi) it1) mi_idx) it2))
*/
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_dark_production
FROM info_type AS it1,
     info_type AS it2,
     keyword AS k,
     kind_type AS kt,
     (
        select * from movie_info as mi
        where pg_lip_bloom_probe(2, info_type_id)
     ) AS mi,
     (
        select * from movie_info_idx as mi_idx
        where pg_lip_bloom_probe(3, info_type_id)
      ) AS mi_idx,
     movie_keyword AS mk,
     (
        select * from title as t
        -- where pg_lip_bloom_probe(4, kind_id)
      ) AS t
WHERE it1.info = 'countries'
  AND it2.info = 'rating'
  AND k.keyword IN ('murder',
                    'murder-in-title')
  AND kt.kind = 'movie'
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
  AND mi_idx.info > '6.0'
  AND t.production_year > 2010
  AND (t.title LIKE '%murder%'
       OR t.title LIKE '%Murder%'
       OR t.title LIKE '%Mord%')
  AND kt.id = t.kind_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mi_idx.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id;

