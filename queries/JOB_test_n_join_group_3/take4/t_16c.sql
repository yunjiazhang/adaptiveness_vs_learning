/*+ NestLoop(mc k mk cn ci n t an)
 HashJoin(mc k mk cn ci n t)
 HashJoin(mc k mk cn ci n)
 NestLoop(mc k mk cn ci)
 MergeJoin(mc k mk cn)
 HashJoin(mc k mk)
 NestLoop(k mk)
 IndexScan(mc)
 IndexScan(k)
 IndexScan(mk)
 SeqScan(cn)
 IndexScan(ci)
 IndexScan(n)
 SeqScan(t)
 IndexScan(an)
 Leading(((((((mc (k mk)) cn) ci) n) t) an)) */
SELECT MIN(an.name) AS cool_actor_pseudonym,
       MIN(t.title) AS series_named_after_char
FROM aka_name AS an,
     cast_info AS ci,
     company_name AS cn,
     keyword AS k,
     movie_companies AS mc,
     movie_keyword AS mk,
     name AS n,
     title AS t
WHERE cn.country_code ='[us]'
  AND k.keyword ='character-name-in-title'
  AND t.episode_nr < 100
  AND an.person_id = n.id
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND an.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;

