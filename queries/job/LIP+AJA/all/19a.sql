SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)');
SELECT sum(pg_lip_bloom_add(7, id)) FROM title AS t WHERE t.production_year BETWEEN 2005 AND 2009;
SELECT sum(pg_lip_bloom_add(3, movie_id)) FROM movie_companies AS mc WHERE mc.note IS NOT NULL
  AND (mc.note LIKE '%(USA)%'
       OR mc.note LIKE '%(worldwide)%');
SELECT sum(pg_lip_bloom_add(4, movie_id)) FROM movie_info AS mi WHERE mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%200%'
       OR mi.info LIKE 'USA:%200%');
SELECT pg_lip_bloom_bit_and(0, 0, 7); -- global filter on movie_id
SELECT pg_lip_bloom_bit_and(0, 0, 3); -- global filter on movie_id
SELECT pg_lip_bloom_bit_and(0, 0, 4); -- global filter on movie_id

SELECT sum(pg_lip_bloom_add(1, id)) FROM company_name AS cn WHERE cn.country_code ='[us]'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it WHERE it.info = 'release dates'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(5, id)) FROM name AS n WHERE n.gender ='f'
  AND n.name LIKE '%Ang%'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(6, id)) FROM role_type AS rt WHERE rt.role ='actress'; -- filter on mc.company_id
SELECT pg_lip_bloom_make_shared();



SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS voiced_movie
FROM aka_name AS an,
     char_name AS chn,
     (
    SELECT * FROM cast_info AS ci
    WHERE pg_lip_bloom_probe(0, ci.movie_id) AND pg_lip_bloom_probe(5, ci.person_id) AND pg_lip_bloom_probe(6, ci.role_id)
) AS ci,
     company_name AS cn,
     info_type AS it,
     (
    SELECT * FROM movie_companies AS mc
    WHERE pg_lip_bloom_probe(0, mc.movie_id) AND pg_lip_bloom_probe(1, mc.company_id)
) AS mc,
     (
    SELECT * FROM movie_info AS mi
    WHERE pg_lip_bloom_probe(0, mi.movie_id) AND pg_lip_bloom_probe(2, mi.info_type_id)
) AS mi,
     name AS n,
     role_type AS rt,
     (
    SELECT * FROM title AS t
    WHERE pg_lip_bloom_probe(0, t.id) 
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

