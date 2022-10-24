SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM title AS t WHERE t.production_year > 2000;
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM keyword AS k WHERE k.keyword IN ('superhero',
--                     'sequel',
--                     'second-part',
--                     'marvel-comics',
--                     'based-on-comic',
--                     'tv-special',
--                     'fight',
--                     'violence');

/*+
HashJoin(k mk t ci n)
NestLoop(k mk t ci)
NestLoop(k mk t)
NestLoop(k mk)
Leading((n (((k mk) t) ci)))
*/
SELECT MIN(k.keyword) AS movie_keyword,
       MIN(n.name) AS actor_name,
       MIN(t.title) AS hero_movie
FROM 
(
    SELECT * FROM cast_info AS ci
    -- WHERE pg_lip_bloom_probe(0, movie_id) 
) AS ci,
     keyword AS k,
(
    SELECT * FROM movie_keyword as mk
    -- WHERE pg_lip_bloom_probe(0, movie_id) 
    -- AND 
    -- pg_lip_bloom_probe(1, keyword_id)
) AS mk,
     name AS n,
     title AS t
WHERE k.keyword IN ('superhero',
                    'sequel',
                    'second-part',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence')
  AND t.production_year > 2000
  AND k.id = mk.keyword_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mk.movie_id
  AND n.id = ci.person_id;
-- 3.4 s

