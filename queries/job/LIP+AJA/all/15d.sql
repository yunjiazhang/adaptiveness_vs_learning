SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM movie_info AS mi WHERE  mi.note LIKE '%internet%';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info ='release dates'; -- filter on mc.company_id


/*+
NestLoop(it1 mi t mc cn ct mk k at)
NestLoop(it1 mi t mc cn ct mk k)
NestLoop(it1 mi t mc cn ct mk)
HashJoin(it1 mi t mc cn ct)
NestLoop(it1 mi t mc cn)
NestLoop(it1 mi t mc)
NestLoop(it1 mi t)
NestLoop(it1 mi)
Leading(((((((((it1 mi) t) mc) cn) ct) mk) k) at))
*/
SELECT MIN(at.title) AS aka_title,
       MIN(t.title) AS internet_movie_title
FROM aka_title AS at,
     company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     keyword AS k,
     movie_companies AS mc,
     movie_info AS mi,
     movie_keyword AS mk,
     title AS t
WHERE cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mi.note LIKE '%internet%'
  AND t.production_year > 1990
  AND t.id = at.movie_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mc.movie_id
  AND mk.movie_id = at.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi.movie_id = at.movie_id
  AND mc.movie_id = at.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;

