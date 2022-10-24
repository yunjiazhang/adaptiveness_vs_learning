SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM company_type AS ct WHERE ct.kind ='production companies';
SELECT sum(pg_lip_bloom_add(1, id)) FROM title AS t WHERE t.title != ''
                                                            AND (t.title LIKE '%Champion%'
                                                                 OR t.title LIKE '%Loser%');
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it2 WHERE it2.info ='release dates';
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM kind_type AS kt WHERE kt.kind ='movie';

/*+
NestLoop(mi_idx it t kt mc cn ct mi it2)
NestLoop(mi_idx it t kt mc cn ct mi)
NestLoop(mi_idx it t kt mc cn ct)
NestLoop(mi_idx it t kt mc cn)
NestLoop(mi_idx it t kt mc)
NestLoop(mi_idx it t kt)
NestLoop(mi_idx it t)
HashJoin(mi_idx it)
Leading(((((((((mi_idx it) t) kt) mc) cn) ct) mi) it2))
*/
SELECT MIN(cn.name) AS producing_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS movie_about_winning
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it,
     info_type AS it2,
     kind_type AS kt,
     (
          select * from movie_companies as mc
          -- where pg_lip_bloom_probe(0, company_type_id)
     ) AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(2, info_type_id)
     ) AS mi,
     (
          select * from movie_info_idx as mi_idx 
          where pg_lip_bloom_probe(1, movie_id)
     ) AS mi_idx,
     (
          select * from title as t
          -- where pg_lip_bloom_probe(3, kind_id)
     ) AS t
WHERE cn.country_code ='[us]'
  AND ct.kind ='production companies'
  AND it.info ='rating'
  AND it2.info ='release dates'
  AND kt.kind ='movie'
  AND t.title != ''
  AND (t.title LIKE '%Champion%'
       OR t.title LIKE '%Loser%')
  AND mi.movie_id = t.id
  AND it2.id = mi.info_type_id
  AND kt.id = t.kind_id
  AND mc.movie_id = t.id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id
  AND mi_idx.movie_id = t.id
  AND it.id = mi_idx.info_type_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi_idx.movie_id = mc.movie_id;

