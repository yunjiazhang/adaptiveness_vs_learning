/*+ HashJoin(cn t k mk mc)
 NestLoop(t k mk mc)
 HashJoin(t k mk)
 NestLoop(k mk)
 IndexScan(cn)
 SeqScan(t)
 SeqScan(k)
 IndexScan(mk)
 IndexScan(mc)
 Leading((cn ((t (k mk)) mc))) */
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
