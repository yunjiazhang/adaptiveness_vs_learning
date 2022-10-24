/*+ NestLoop(ci chn n mc cn t an rt)
 NestLoop(ci chn n mc cn t an)
 NestLoop(ci chn n mc cn t)
 NestLoop(ci chn n mc cn)
 NestLoop(ci chn n mc)
 NestLoop(ci chn n)
 HashJoin(ci chn)
 SeqScan(ci)
 SeqScan(chn)
 IndexScan(n)
 IndexScan(mc)
 IndexScan(cn)
 IndexScan(t)
 IndexScan(an)
 SeqScan(rt)
 Leading((((((((ci chn) n) mc) cn) t) an) rt)) */
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
FROM aka_name AS an,
     char_name AS chn,
     cast_info AS ci,
     company_name AS cn,
     movie_companies AS mc,
     name AS n,
     role_type AS rt,
     title AS t
WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND n.gender ='f'
  AND rt.role ='actress'
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND ci.movie_id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND n.id = ci.person_id
  AND chn.id = ci.person_role_id
  AND an.person_id = n.id
  AND an.person_id = ci.person_id;

