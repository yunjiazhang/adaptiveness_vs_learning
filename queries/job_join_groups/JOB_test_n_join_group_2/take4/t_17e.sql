/*+ MergeJoin(mc cn ci mk k t n)
 HashJoin(mc cn ci mk k t)
 HashJoin(ci mk k t)
 NestLoop(mk k t)
 HashJoin(mk k)
 HashJoin(mc cn)
 SeqScan(mc)
 SeqScan(cn)
 SeqScan(ci)
 IndexScan(mk)
 IndexScan(k)
 IndexScan(t)
 IndexScan(n)
 Leading((((mc cn) (ci ((mk k) t))) n)) */
SELECT MIN(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci,
     company_name AS cn,
     keyword AS k,
     movie_companies AS mc,
     movie_keyword AS mk,
     name AS n,
     title AS t
WHERE cn.country_code ='[us]'
  AND k.keyword ='character-name-in-title'
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;

