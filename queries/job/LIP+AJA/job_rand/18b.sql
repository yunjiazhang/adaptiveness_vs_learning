SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, id)) FROM info_type AS it1 WHERE it1.info = 'genres'; 
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it2 WHERE it2.info = 'rating';

/*+
NestLoop(it2 mi_idx mi it1 t ci n)
NestLoop(it2 mi_idx mi it1 t ci)
NestLoop(it2 mi_idx mi it1 t)
NestLoop(it2 mi_idx mi it1)
NestLoop(it2 mi_idx mi)
NestLoop(it2 mi_idx)
Leading(((((((it2 mi_idx) mi) it1) t) ci) n))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(t.title) AS movie_title
FROM (
        SELECT * FROM cast_info as ci
      --   WHERE pg_lip_bloom_probe(5, movie_id)  -- AND pg_lip_bloom_probe(4, person_id)
     ) AS ci,
     info_type AS it1,
     info_type AS it2,
     (
        SELECT * FROM movie_info as mi
        WHERE 
      --   pg_lip_bloom_probe(5, movie_id) AND
        pg_lip_bloom_probe(0, info_type_id)
     ) AS mi,
     ( 
        SELECT * FROM movie_info_idx as mi_idx
        -- WHERE 
        --   pg_lip_bloom_probe(5, movie_id) AND 
        -- pg_lip_bloom_probe(1, info_type_id)
     ) AS mi_idx,
     name AS n,
     (
        SELECT * FROM title as t
      --   WHERE pg_lip_bloom_probe(5, id) 
     ) AS t
WHERE ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'rating'
  AND mi.info IN ('Horror',
                  'Thriller')
  AND mi.note IS NULL
  AND mi_idx.info > '8.0'
  AND n.gender IS NOT NULL
  AND n.gender = 'f'
  AND t.production_year BETWEEN 2008 AND 2014
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id;

