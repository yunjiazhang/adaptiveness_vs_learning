SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)',
--                   '(voice: Japanese version)',
--                   '(voice) (uncredited)',
--                   '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM name AS n WHERE n.gender ='f'
--   AND n.name LIKE '%Ang%';
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM company_name AS cn WHERE cn.country_code ='[us]';

/*+
NestLoop(n an ci rt mc cn t chn)
NestLoop(n an ci rt mc cn t)
NestLoop(n an ci rt mc cn)
NestLoop(n an ci rt mc)
NestLoop(n an ci rt)
NestLoop(n an ci)
NestLoop(n an)
IndexScan(rt)
Leading((((((((n an) ci) rt) mc) cn) t) chn))
*/
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS character_name,
       MIN(t.title) AS movie
FROM aka_name AS an,
     char_name AS chn,
     (
          select * from cast_info as ci 
          where pg_lip_bloom_probe(1, role_id)
     ) AS ci,
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
  AND mc.note IS NOT NULL
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND n.gender ='f'
  AND n.name LIKE '%Ang%'
  AND rt.role ='actress'
  AND t.production_year BETWEEN 2005 AND 2015
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND ci.movie_id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND n.id = ci.person_id
  AND chn.id = ci.person_role_id
  AND an.person_id = n.id
  AND an.person_id = ci.person_id;

