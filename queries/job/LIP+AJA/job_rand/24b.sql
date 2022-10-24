
SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, id)) FROM title AS t WHERE t.production_year > 2010
                                             AND t.title LIKE 'Kung Fu Panda%';
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info ='release dates'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(2, id)) FROM role_type AS rt WHERE rt.role ='actress'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(3, id)) FROM name AS n WHERE n.gender ='f' AND n.name LIKE '%An%'; -- filter on ci.personid


/*+
NestLoop(cn mc t mk ci an chn mi it k n rt)
NestLoop(cn mc t mk ci an chn mi it k n)
NestLoop(cn mc t mk ci an chn mi it k)
NestLoop(cn mc t mk ci an chn mi it)
NestLoop(cn mc t mk ci an chn mi)
NestLoop(cn mc t mk ci an chn)
NestLoop(cn mc t mk ci an)
NestLoop(cn mc t mk ci)
NestLoop(cn mc t mk)
NestLoop(cn mc t)
NestLoop(cn mc)
Leading((((((((((((cn mc) t) mk) ci) an) chn) mi) it) k) n) rt))
*/
SELECT MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress_name,
       MIN(t.title) AS kung_fu_panda
FROM aka_name AS an,
     char_name AS chn,
     (
          select * from cast_info as ci
          where pg_lip_bloom_probe(3, person_id) and pg_lip_bloom_probe(2, role_id)
     ) AS ci,
     company_name AS cn,
     info_type AS it,
     keyword AS k,
     (
          select * from movie_companies as mc
          where pg_lip_bloom_probe(0, movie_id)
     ) AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     movie_keyword AS mk,
     name AS n,
     role_type AS rt,
     title AS t
WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND cn.name = 'DreamWorks Animation'
  AND it.info = 'release dates'
  AND k.keyword IN ('hero',
                    'martial-arts',
                    'hand-to-hand-combat',
                    'computer-animated-movie')
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%201%'
       OR mi.info LIKE 'USA:%201%')
  AND n.gender ='f'
  AND n.name LIKE '%An%'
  AND rt.role ='actress'
  AND t.production_year > 2010
  AND t.title LIKE 'Kung Fu Panda%'
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND mc.movie_id = ci.movie_id
  AND mc.movie_id = mi.movie_id
  AND mc.movie_id = mk.movie_id
  AND mi.movie_id = ci.movie_id
  AND mi.movie_id = mk.movie_id
  AND ci.movie_id = mk.movie_id
  AND cn.id = mc.company_id
  AND it.id = mi.info_type_id
  AND n.id = ci.person_id
  AND rt.id = ci.role_id
  AND n.id = an.person_id
  AND ci.person_id = an.person_id
  AND chn.id = ci.person_role_id
  AND k.id = mk.keyword_id;

