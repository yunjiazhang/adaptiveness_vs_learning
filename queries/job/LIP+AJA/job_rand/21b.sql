SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, id)) FROM company_name AS cn WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%');
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM company_type AS ct WHERE ct.kind ='production companies';
SELECT sum(pg_lip_bloom_add(2, id)) FROM link_type AS lt WHERE lt.link LIKE '%follow%';

/*+
NestLoop(k mk ml lt mi mc cn ct t)
NestLoop(k mk ml lt mi mc cn ct)
NestLoop(k mk ml lt mi mc cn)
NestLoop(k mk ml lt mi mc)
NestLoop(k mk ml lt mi)
NestLoop(k mk ml lt)
NestLoop(k mk ml)
NestLoop(k mk)
Leading(((((((lt ((k mk) ml)) mi) mc) cn) ct) t))
*/
SELECT MIN(cn.name) AS company_name,
       MIN(lt.link) AS link_type,
       MIN(t.title) AS german_follow_up
FROM company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     (
          select  * from movie_companies as mc
          where pg_lip_bloom_probe(0, company_id) --  AND pg_lip_bloom_probe(1, company_type_id)
     ) AS mc,
     movie_info AS mi,
     movie_keyword AS mk,
     (
          select * from movie_link as ml
          where pg_lip_bloom_probe(2, link_type_id)
     ) AS ml,
     title AS t
WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind ='production companies'
  AND k.keyword ='sequel'
  AND lt.link LIKE '%follow%'
  AND mc.note IS NULL
  AND mi.info IN ('Germany',
                  'German')
  AND t.production_year BETWEEN 2000 AND 2010
  AND lt.id = ml.link_type_id
  AND ml.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_type_id = ct.id
  AND mc.company_id = cn.id
  AND mi.movie_id = t.id
  AND ml.movie_id = mk.movie_id
  AND ml.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id
  AND ml.movie_id = mi.movie_id
  AND mk.movie_id = mi.movie_id
  AND mc.movie_id = mi.movie_id;

