/*+ NestLoop(cn mc t ci n1 an1 rt)
 NestLoop(cn mc t ci n1 an1)
 NestLoop(cn mc t ci n1)
 NestLoop(cn mc t ci)
 NestLoop(cn mc t)
 NestLoop(cn mc)
 IndexScan(cn)
 IndexScan(mc)
 IndexScan(t)
 IndexScan(ci)
 IndexScan(n1)
 IndexScan(an1)
 SeqScan(rt)
 Leading(((((((cn mc) t) ci) n1) an1) rt)) */
SELECT MIN(an1.name) AS actress_pseudonym,
       MIN(t.title) AS japanese_movie_dubbed
FROM aka_name AS an1,
     cast_info AS ci,
     company_name AS cn,
     movie_companies AS mc,
     name AS n1,
     role_type AS rt,
     title AS t
WHERE ci.note ='(voice: English version)'
  AND cn.country_code ='[jp]'
  AND mc.note LIKE '%(Japan)%'
  AND mc.note NOT LIKE '%(USA)%'
  AND n1.name LIKE '%Yo%'
  AND n1.name NOT LIKE '%Yu%'
  AND rt.role ='actress'
  AND an1.person_id = n1.id
  AND n1.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND an1.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id;

