SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, id)) FROM link_type AS lt WHERE lt.link LIKE '%follow%';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM company_type AS ct WHERE ct.kind ='production companies';

/*+
NestLoop(k mk ml lt t mc cn cn ct)
NestLoop(k mk ml lt t mc cn cn)
NestLoop(k mk ml lt t mc cn)
NestLoop(k mk ml lt t mc)
NestLoop(k mk ml lt t)
NestLoop(k mk ml lt)
NestLoop(k mk ml)
NestLoop(k mk)
Leading((((((lt ((k mk) ml)) t) mc) cn) ct))
*/
SELECT MIN(cn.name) AS from_company,
       MIN(lt.link) AS movie_link_type,
       MIN(t.title) AS non_polish_sequel_movie
FROM company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     (
          select * from movie_companies as mc
          -- where pg_lip_bloom_probe(1, company_type_id)
     ) AS mc,
     movie_keyword AS mk,
     (
          select * from movie_link as ml
          where pg_lip_bloom_probe(0, link_type_id)
     ) AS ml,
     title AS t
WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind ='production companies'
  AND k.keyword ='sequel'
  AND lt.link LIKE '%follow%'
  AND mc.note IS NULL
  AND t.production_year BETWEEN 1950 AND 2000
  AND lt.id = ml.link_type_id
  AND ml.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_type_id = ct.id
  AND mc.company_id = cn.id
  AND ml.movie_id = mk.movie_id
  AND ml.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id;

