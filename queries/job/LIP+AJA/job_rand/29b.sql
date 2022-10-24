SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
SELECT sum(pg_lip_bloom_add(0, id)) FROM comp_cast_type AS cct1 WHERE cct1.kind = 'cast';
SELECT sum(pg_lip_bloom_add(1, id)) FROM comp_cast_type AS cct2 WHERE cct2.kind = 'complete+verified';
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type as it WHERE it.info = 'release dates';
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type as it3 WHERE it3.info = 'height';
SELECT sum(pg_lip_bloom_add(4, id)) FROM title AS t WHERE t.title = 'Shrek 2';
SELECT sum(pg_lip_bloom_add(5, id)) FROM char_name AS chn WHERE chn.name = 'Queen';
SELECT sum(pg_lip_bloom_add(6, id)) FROM role_type AS rt WHERE rt.role ='actress';

/*+
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn mi it n it3 rt)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn mi it n it3)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn mi it n)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn mi it)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn mi)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc cn)
NestLoop(k mk t ci pi an cc cct1 cct2 chn mc)
NestLoop(k mk t ci pi an cc cct1 cct2 chn)
NestLoop(k mk t ci pi an cc cct1 cct2)
NestLoop(k mk t ci pi an cc cct1)
NestLoop(k mk t ci pi an cc)
NestLoop(k mk t ci pi an)
NestLoop(k mk t ci pi)
NestLoop(k mk t ci)
NestLoop(k mk t)
NestLoop(k mk)
Leading(((((((((((((((((k mk) t) ci) pi) an) cc) cct1) cct2) chn) mc) cn) mi) it) n) it3) rt))
*/
SELECT MIN(chn.name) AS voiced_char,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_animation
FROM aka_name AS an,
     (
          select * from complete_cast as cc
          where pg_lip_bloom_probe(0, subject_id) AND pg_lip_bloom_probe(1, status_id)
     ) AS cc,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2,
     char_name AS chn,
     (
          select  * from cast_info as ci 
          where pg_lip_bloom_probe(5, person_role_id) AND pg_lip_bloom_probe(6, role_id)
     ) AS ci,
     company_name AS cn,
     info_type AS it,
     info_type AS it3,
     keyword AS k,
     movie_companies AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(2, info_type_id)
     ) AS mi,
     (
          select  * from movie_keyword as mk
          where pg_lip_bloom_probe(4, movie_id)
     ) AS mk,
     name AS n,
     (
          select * from person_info as pi
          where pg_lip_bloom_probe(3, info_type_id)
     ) AS pi,
     role_type AS rt,
     title AS t
WHERE cct1.kind ='cast'
  AND cct2.kind ='complete+verified'
  AND chn.name = 'Queen'
  AND ci.note IN ('(voice)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND it3.info = 'height'
  AND k.keyword = 'computer-animation'
  AND mi.info LIKE 'USA:%200%'
  AND n.gender ='f'
  AND n.name LIKE '%An%'
  AND rt.role ='actress'
  AND t.title = 'Shrek 2'
  AND t.production_year BETWEEN 2000 AND 2005
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND t.id = cc.movie_id
  AND mc.movie_id = ci.movie_id
  AND mc.movie_id = mi.movie_id
  AND mc.movie_id = mk.movie_id
  AND mc.movie_id = cc.movie_id
  AND mi.movie_id = ci.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi.movie_id = cc.movie_id
  AND ci.movie_id = mk.movie_id
  AND ci.movie_id = cc.movie_id
  AND mk.movie_id = cc.movie_id
  AND cn.id = mc.company_id
  AND it.id = mi.info_type_id
  AND n.id = ci.person_id
  AND rt.id = ci.role_id
  AND n.id = an.person_id
  AND ci.person_id = an.person_id
  AND chn.id = ci.person_role_id
  AND n.id = pi.person_id
  AND ci.person_id = pi.person_id
  AND it3.id = pi.info_type_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id;

