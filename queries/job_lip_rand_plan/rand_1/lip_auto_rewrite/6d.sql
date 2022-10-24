SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, k.id)) FROM keyword AS k WHERE k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence');
SELECT sum(pg_lip_bloom_add(1, n.id)) FROM name AS n WHERE n.name LIKE '%Downey%Robert%';
-- SELECT sum(pg_lip_bloom_add(2, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
NestLoop(ci t n mk k)
NestLoop(ci t n mk)
NestLoop(ci t n)
HashJoin(ci t)
SeqScan(ci)
SeqScan(t)
IndexScan(n)
IndexScan(mk)
IndexScan(k)
Leading(((((ci t) n) mk) k))*/
SELECT MIN(k.keyword) AS movie_keyword,
       MIN(n.name) AS actor_name,
       MIN(t.title) AS hero_movie
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(1, ci.person_id)
	-- AND pg_lip_bloom_probe(2, ci.movie_id)
) AS ci ,
keyword AS k ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(0, mk.keyword_id)
	-- AND pg_lip_bloom_probe(2, mk.movie_id)
) AS mk ,
name AS n ,
title AS t
WHERE
 k.keyword IN ('superhero',
                    'sequel',
                    'second-part',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence')
  AND n.name LIKE '%Downey%Robert%'
  AND t.production_year > 2000
  AND k.id = mk.keyword_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mk.movie_id
  AND n.id = ci.person_id;

