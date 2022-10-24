/*+ NestLoop(n ci mk k t)
 NestLoop(n ci mk k)
 NestLoop(n ci mk)
 NestLoop(n ci)
 SeqScan(n)
 IndexScan(ci)
 IndexScan(mk)
 IndexScan(k)
 IndexScan(t)
 Leading(((((n ci) mk) k) t)) */
 SELECT MIN(k.keyword) AS movie_keyword,
       MIN(n.name) AS actor_name,
       MIN(t.title) AS marvel_movie
FROM cast_info AS ci,
     keyword AS k,
     movie_keyword AS mk,
     name AS n,
     title AS t
WHERE k.keyword = 'marvel-cinematic-universe'
  AND n.name LIKE '%Downey%Robert%'
  AND t.production_year > 2000
  AND k.id = mk.keyword_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mk.movie_id
  AND n.id = ci.person_id;

