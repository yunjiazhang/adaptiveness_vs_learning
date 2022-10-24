SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, k.id)) FROM keyword AS k WHERE k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence');
SELECT sum(pg_lip_bloom_add(1, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
HashJoin(t ci mk n k)
HashJoin(t ci mk n)
HashJoin(t ci mk)
HashJoin(t ci)
SeqScan(t)
SeqScan(ci)
SeqScan(mk)
SeqScan(n)
SeqScan(k)
Leading(((((t ci) mk) n) k))*/
SELECT MIN(k.keyword) AS movie_keyword,
       MIN(n.name) AS actor_name,
       MIN(t.title) AS hero_movie
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(1, ci.movie_id)
) AS ci ,
keyword AS k ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(0, mk.keyword_id)
	AND pg_lip_bloom_probe(1, mk.movie_id)
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
  AND t.production_year > 2000
  AND k.id = mk.keyword_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mk.movie_id
  AND n.id = ci.person_id;

