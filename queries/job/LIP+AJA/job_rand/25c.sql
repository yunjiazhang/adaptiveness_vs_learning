SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)',
--                   '(head writer)',
--                   '(written by)',
--                   '(story)',
--                   '(story editor)');
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it2 WHERE it2.info = 'votes';
SELECT sum(pg_lip_bloom_add(3, id)) FROM keyword AS k WHERE k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital');
/*+
NestLoop(k mk mi_idx it2 mi it1 ci n t)
NestLoop(k mk mi_idx it2 mi it1 ci n)
NestLoop(k mk mi_idx it2 mi it1 ci)
NestLoop(k mk mi_idx it2 mi it1)
NestLoop(k mk mi_idx it2 mi)
NestLoop(k mk mi_idx it2)
NestLoop(k mk mi_idx)
NestLoop(k mk)
Leading(((((it1 ((it2 ((k mk) mi_idx)) mi)) ci) n) t))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
FROM 
     (
        SELECT * FROM cast_info as ci
      --   WHERE pg_lip_bloom_probe(5, ci.person_id) 
     ) 
   --   cast_info_bf 
     AS ci,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     (
        SELECT * FROM movie_info as mi
        WHERE 
      --   pg_lip_bloom_probe(0, movie_id) 
         --   AND 
           pg_lip_bloom_probe(1, info_type_id)
     ) 
   --   movie_info_bf 
     AS mi,
     (
        SELECT * FROM movie_info_idx as mi_idx
        WHERE
      --   pg_lip_bloom_probe(0, movie_id) AND 
        pg_lip_bloom_probe(2, info_type_id)
     ) AS mi_idx,
     (
        SELECT * FROM movie_keyword as mk
        WHERE 
      --   pg_lip_bloom_probe(0, movie_id)
      --   AND 
        pg_lip_bloom_probe(3, keyword_id)
     ) AS mk,
     name AS n,
     (
         SELECT * FROM title as t
         -- WHERE pg_lip_bloom_probe(0, id)
     ) AS t
WHERE 
 ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND 
  it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
  AND mi.info IN ('Horror',
                  'Action',
                  'Sci-Fi',
                  'Thriller',
                  'Crime',
                  'War')
  AND n.gender = 'm'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id;

