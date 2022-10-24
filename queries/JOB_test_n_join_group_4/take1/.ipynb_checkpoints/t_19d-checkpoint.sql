/*+ HashJoin(t n mi it ci rt chn mc an cn)
 HashJoin(t n mi it ci rt chn mc an)
 NestLoop(t n mi it ci rt chn mc)
 HashJoin(t n mi it ci rt chn)
 HashJoin(t n mi it ci rt)
 HashJoin(n mi it ci rt)
 HashJoin(mi it ci rt)
 HashJoin(ci rt)
 HashJoin(mi it)
 SeqScan(t)
 SeqScan(n)
 SeqScan(mi)
 IndexScan(it)
 SeqScan(ci)
 IndexScan(rt)
 SeqScan(chn)
 IndexScan(mc)
 IndexScan(an)
 SeqScan(cn)
 Leading((((((t (n ((mi it) (ci rt)))) chn) mc) an) cn)) */
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
FROM aka_name AS an,
     char_name AS chn,
     cast_info AS ci,
     company_name AS cn,
     info_type AS it,
     movie_companies AS mc,
     movie_info AS mi,
     name AS n,
     role_type AS rt,
     title AS t
WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND n.gender ='f'
  AND rt.role ='actress'
  AND t.production_year > 2000
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND mc.movie_id = ci.movie_id
  AND mc.movie_id = mi.movie_id
  AND mi.movie_id = ci.movie_id
  AND cn.id = mc.company_id
  AND it.id = mi.info_type_id
  AND n.id = ci.person_id
  AND rt.id = ci.role_id
  AND n.id = an.person_id
  AND ci.person_id = an.person_id
  AND chn.id = ci.person_role_id;

