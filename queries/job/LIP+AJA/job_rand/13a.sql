SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, id)) FROM company_type AS ct WHERE ct.kind ='production companies';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it WHERE it.info ='rating';
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it2 WHERE it2.info ='release dates';
SELECT sum(pg_lip_bloom_add(3, id)) FROM kind_type AS kt WHERE kt.kind ='movie';


/*+
HashJoin(it mi_idx t kt mc ct cn mi it2)
NestLoop(it mi_idx t kt mc ct cn mi)
NestLoop(it mi_idx t kt mc ct cn)
HashJoin(it mi_idx t kt mc ct)
NestLoop(it mi_idx t kt mc)
HashJoin(it mi_idx t kt)
NestLoop(it mi_idx t)
HashJoin(it mi_idx)
Leading(((((((((mi_idx it) t) kt) mc) ct) cn) mi) it2))
*/
SELECT MIN(mi.info) AS release_date,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS german_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it,
     info_type AS it2,
     kind_type AS kt,
     (
        select * from movie_companies as mc
        -- where pg_lip_bloom_probe(0, mc.company_type_id)
      ) AS mc,
     (
        select * from movie_info as mi 
        where pg_lip_bloom_probe(2, mi.info_type_id) 
      ) AS mi,
     movie_info_idx AS mi_idx,
     (
        select * from title as t
        where pg_lip_bloom_probe(3, t.kind_id)
      ) AS t
WHERE cn.country_code ='[de]'
  AND ct.kind ='production companies'
  AND it.info ='rating'
  AND it2.info ='release dates'
  AND kt.kind ='movie'
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

