SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM movie_info AS mi WHERE  mi.info IS NOT NULL
--   AND (mi.info LIKE 'USA:% 199%'
--        OR mi.info LIKE 'USA:% 200%');
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM comp_cast_type AS cct1 WHERE  cct2.kind = 'complete+verified';
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info ='release dates'; -- filter on mc.company_id
-- SELECT sum(pg_lip_bloom_add(4, id)) FROM info_type AS it2 WHERE it2.info ='rating'; -- filter on mc.company_id
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM kind_type AS kt WHERE kt.kind IN ('movie'); -- filter on mc.company_id

/*+
NestLoop(cc cct1 t kt mi it1 mk mc cn ct k)
NestLoop(cc cct1 t kt mi it1 mk mc cn ct)
NestLoop(cc cct1 t kt mi it1 mk mc cn)
NestLoop(cc cct1 t kt mi it1 mk mc)
NestLoop(cc cct1 t kt mi it1 mk)
NestLoop(cc cct1 t kt mi it1)
NestLoop(cc cct1 t kt mi)
HashJoin(cc cct1 t kt)
NestLoop(cc cct1 t)
NestLoop(cc cct1)
IndexScan(t)
IndexScan(cc)
Leading(((((((((((cct1 cc) t) kt) mi) it1) mk) mc) cn) ct) k))
*/
SELECT MIN(kt.kind) AS movie_kind,
       MIN(t.title) AS complete_us_internet_movie
FROM complete_cast AS cc,
     comp_cast_type AS cct1,
     company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     keyword AS k,
     kind_type AS kt,
     movie_companies AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     movie_keyword AS mk,
     (
          select * from title as t
          -- where 
          -- pg_lip_bloom_probe(2, kind_id)
          -- AND 
          -- pg_lip_bloom_probe(0, id)
     ) AS t
WHERE cct1.kind = 'complete+verified'
  AND cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND kt.kind IN ('movie')
  AND mi.note LIKE '%internet%'
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'USA:% 199%'
       OR mi.info LIKE 'USA:% 200%')
  AND t.production_year > 2000
  AND kt.id = t.kind_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND t.id = cc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mc.movie_id
  AND mk.movie_id = cc.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi.movie_id = cc.movie_id
  AND mc.movie_id = cc.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id
  AND cct1.id = cc.status_id;

