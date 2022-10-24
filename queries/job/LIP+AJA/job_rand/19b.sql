SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)',
--                   '(voice: Japanese version)',
--                   '(voice) (uncredited)',
--                   '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info = 'release dates';
SELECT sum(pg_lip_bloom_add(2, id)) FROM name AS n WHERE n.name LIKE '%Angel%';
-- SELECT sum(pg_lip_bloom_add(7, movie_id)) FROM movie_info AS mi WHERE mi.info IS NOT NULL
--                                                                       AND (mi.info LIKE 'Japan:%200%'
--                                                                       OR mi.info LIKE 'USA:%200%');
-- SELECT sum(pg_lip_bloom_add(4, id)) FROM name as n WHERE n.gender ='f'
--                                                          AND n.name LIKE '%An%';
SELECT sum(pg_lip_bloom_add(5, id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(6, id)) FROM title AS t WHERE t.production_year > 2000;
-- SELECT sum(pg_lip_bloom_bit_and(7, 0, 3));
-- SELECT sum(pg_lip_bloom_bit_and(7, 3, 3));

/*+
NestLoop(t mc ci an chn cn mi it n rt)
NestLoop(t mc ci an chn cn mi it n)
NestLoop(t mc ci an chn cn mi it)
NestLoop(t mc ci an chn cn mi)
NestLoop(t mc ci an chn cn)
NestLoop(t mc ci an chn)
NestLoop(t mc ci an)
NestLoop(t mc ci)
NestLoop(t mc)
Leading((((((((((t mc) ci) an) chn) cn) mi) it) n) rt))
*/
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS kung_fu_panda
FROM (
          select * from aka_name as an
          where pg_lip_bloom_probe(2, an.person_id) 
     ) AS an,
     char_name AS chn,
     (
          select * from cast_info as ci
          where pg_lip_bloom_probe(5, role_id)
     ) AS ci,
     company_name AS cn,
     info_type AS it,
     movie_companies AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     name AS n,
     role_type AS rt,
     title AS t
WHERE ci.note = '(voice)'
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND mc.note LIKE '%(200%)%'
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%')
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%2007%'
       OR mi.info LIKE 'USA:%2008%')
  AND n.gender ='f'
  AND n.name LIKE '%Angel%'
  AND rt.role ='actress'
  AND t.production_year BETWEEN 2007 AND 2008
  AND t.title LIKE '%Kung%Fu%Panda%'
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

