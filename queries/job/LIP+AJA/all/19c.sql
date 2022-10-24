SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)',
--                   '(voice: Japanese version)',
--                   '(voice) (uncredited)',
--                   '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info = 'release dates';
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(7, movie_id)) FROM movie_info AS mi WHERE mi.info IS NOT NULL
                                                                      AND (mi.info LIKE 'Japan:%200%'
                                                                      OR mi.info LIKE 'USA:%200%');
-- SELECT sum(pg_lip_bloom_add(4, id)) FROM name as n WHERE n.gender ='f'
--                                                          AND n.name LIKE '%An%';
SELECT sum(pg_lip_bloom_add(5, id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(6, id)) FROM title AS t WHERE t.production_year > 2000;
-- SELECT sum(pg_lip_bloom_bit_and(7, 0, 3));
-- SELECT sum(pg_lip_bloom_bit_and(7, 3, 3));

/*+
NestLoop(n an ci rt t mi it chn mc cn)
NestLoop(n an ci rt t mi it chn mc)
NestLoop(n an ci rt t mi it chn)
NestLoop(n an ci rt t mi it)
NestLoop(n an ci rt t mi)
NestLoop(n an ci rt t)
NestLoop(n an ci rt)
NestLoop(n an ci)
NestLoop(n an)
Leading((((((((((n an) ci) rt) t) mi) it) chn) mc) cn ))
*/
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
FROM ( 
          SELECT * FROM aka_name as an
          -- WHERE pg_lip_bloom_probe(4, person_id)
     ) AS an,
     char_name AS chn,
     (
          SELECT * FROM cast_info as ci
          WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)') AND pg_lip_bloom_probe(7, movie_id)
     ) AS ci,
     company_name AS cn,
     info_type AS it,
     (
          SELECT * FROM movie_companies as mc
          WHERE pg_lip_bloom_probe(7, movie_id) -- AND pg_lip_bloom_probe(2, company_id)    
     ) AS mc,
     (
          SELECT * FROM movie_info as mi
          WHERE mi.info IS NOT NULL
          AND (mi.info LIKE 'Japan:%200%'
               OR mi.info LIKE 'USA:%200%') AND pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     name AS n,
     role_type AS rt,
     (
          SELECT * FROM title as t
          WHERE pg_lip_bloom_probe(7, id)
     ) AS t
WHERE 
  cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND n.gender ='f'
  AND n.name LIKE '%An%'
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

