SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it WHERE it.info = 'release dates';
SELECT sum(pg_lip_bloom_add(6, id)) FROM role_type AS rt WHERE rt.role ='actress';

/*+
NestLoop(n an ci rt t mc cn mi it)
NestLoop(n an ci rt t mc cn mi)
NestLoop(n an ci rt t mc cn)
NestLoop(n an ci rt t mc)
NestLoop(n an ci rt t)
NestLoop(n an ci rt)
NestLoop(n an ci)
NestLoop(n an)
Leading(((((((((n an) ci) rt) t) mc) cn) mi) it))
*/
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_movie
FROM aka_name AS an,
     char_name AS chn,
     (
    SELECT * FROM cast_info AS ci
    WHERE 
    -- pg_lip_bloom_probe(0, ci.movie_id) AND 
    -- pg_lip_bloom_probe(5, ci.person_id) AND 
    pg_lip_bloom_probe(6, ci.role_id)
) AS ci,
     company_name AS cn,
     info_type AS it,
     (
    SELECT * FROM movie_companies AS mc
    -- WHERE 
    -- pg_lip_bloom_probe(0, mc.movie_id) AND 
    -- pg_lip_bloom_probe(1, mc.company_id)
) AS mc,
     (
    SELECT * FROM movie_info AS mi
    WHERE 
    -- pg_lip_bloom_probe(0, mi.movie_id) AND 
    pg_lip_bloom_probe(2, mi.info_type_id)
) AS mi,
     name AS n,
     role_type AS rt,
     (
    SELECT * FROM title AS t
    -- WHERE pg_lip_bloom_probe(0, t.id) 
) AS t
WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND mc.note IS NOT NULL
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%200%'
       OR mi.info LIKE 'USA:%200%')
  AND n.gender ='f'
  AND n.name LIKE '%Ang%'
  AND rt.role ='actress'
  AND t.production_year BETWEEN 2005 AND 2009
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

