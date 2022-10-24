/*+ HashJoin(k mk t mc cn)
 NestLoop(k mk t mc)
 NestLoop(k mk t)
 NestLoop(k mk)
 IndexScan(k)
 IndexScan(mk)
 IndexScan(t)
 IndexScan(mc)
 SeqScan(cn)
 Leading(((((k mk) t) mc) cn)) */
SELECT MIN(t.title) AS movie_title
FROM company_name AS cn,
     keyword AS k,
     movie_companies AS mc,
     movie_keyword AS mk,
     title AS t
WHERE cn.country_code ='[sm]'
  AND k.keyword ='character-name-in-title'
  AND cn.id = mc.company_id
  AND mc.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND mc.movie_id = mk.movie_id;

