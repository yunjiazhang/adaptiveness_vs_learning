SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM movie_info AS mi WHERE  mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%';
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info ='release dates'; -- filter on mc.company_id

/*+
NestLoop(mc cn aka_t t mi ct it1 mk k)
NestLoop(mc cn aka_t t mi ct it1 mk)
NestLoop(mc cn aka_t t mi ct it1)
NestLoop(mc cn aka_t t mi ct)
NestLoop(mc cn aka_t t mi)
NestLoop(mc cn aka_t t)
NestLoop(mc cn aka_t)
NestLoop(mc cn)
Leading(((((((((mc cn) aka_t) t) mi) ct) it1) mk) k))
*/
SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS internet_movie
FROM aka_title AS aka_t,
     company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     keyword AS k,
     (
        select * from movie_companies as mc
        where pg_lip_bloom_probe(0, movie_id) 
     ) AS mc,
     (
        SELECT * from movie_info as mi
        where pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     movie_keyword AS mk,
     title AS t
WHERE cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mc.note LIKE '%(200%)%'
  AND mc.note LIKE '%(worldwide)%'
  AND mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%'
  AND t.production_year > 2000
  AND t.id = aka_t.movie_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mc.movie_id
  AND mk.movie_id = aka_t.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi.movie_id = aka_t.movie_id
  AND mc.movie_id = aka_t.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;


-- 288 ms