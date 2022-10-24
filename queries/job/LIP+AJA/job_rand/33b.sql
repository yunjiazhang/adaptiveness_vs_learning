SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, id)) FROM info_type AS it1 WHERE it1.info = 'rating';
SELECT sum(pg_lip_bloom_add(1, id)) FROM kind_type AS kt WHERE kt.kind = 'tv series';
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM link_type AS lt WHERE lt.link LIKE '%follow%';

/*+
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1 cn1 mc2 cn2 t2 kt2)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1 cn1 mc2 cn2 t2)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1 cn1 mc2 cn2)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1 cn1 mc2)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1 cn1)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2 mc1)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2 it2)
NestLoop(lt ml mi_idx it1 t1 kt1 mi_idx2)
NestLoop(lt ml mi_idx it1 t1 kt1)
NestLoop(lt ml mi_idx it1 t1)
NestLoop(lt ml mi_idx it1)
NestLoop(lt ml mi_idx)
NestLoop(lt ml)
Leading((((((((((((((lt ml) mi_idx) it1) t1) kt1) mi_idx2) it2) mc1) cn1) mc2) cn2) t2) kt2))
*/
SELECT MIN(cn1.name) AS first_company,
       MIN(cn2.name) AS second_company,
       MIN(mi_idx1.info) AS first_rating,
       MIN(mi_idx2.info) AS second_rating,
       MIN(t1.title) AS first_movie,
       MIN(t2.title) AS second_movie
FROM company_name AS cn1,
     company_name AS cn2,
     info_type AS it1,
     info_type AS it2,
     kind_type AS kt1,
     kind_type AS kt2,
     link_type AS lt,
     movie_companies AS mc1,
     movie_companies AS mc2,
     (
        select * from movie_info_idx as mi_idx1 
        where pg_lip_bloom_probe(0, info_type_id)
      ) AS mi_idx1,
     (
        select * from movie_info_idx as mi_idx2
        where pg_lip_bloom_probe(0, info_type_id)   
     ) AS mi_idx2,
     movie_link AS ml,
     (
        select * from title as t1
        where pg_lip_bloom_probe(1, kind_id)
      ) AS t1,
     (
        select * from title as t2
        where pg_lip_bloom_probe(1, kind_id)
      ) AS t2
WHERE cn1.country_code = '[nl]'
  AND it1.info = 'rating'
  AND it2.info = 'rating'
  AND kt1.kind IN ('tv series')
  AND kt2.kind IN ('tv series')
  AND lt.link LIKE '%follow%'
  AND mi_idx2.info < '3.0'
  AND t2.production_year = 2007
  AND lt.id = ml.link_type_id
  AND t1.id = ml.movie_id
  AND t2.id = ml.linked_movie_id
  AND it1.id = mi_idx1.info_type_id
  AND t1.id = mi_idx1.movie_id
  AND kt1.id = t1.kind_id
  AND cn1.id = mc1.company_id
  AND t1.id = mc1.movie_id
  AND ml.movie_id = mi_idx1.movie_id
  AND ml.movie_id = mc1.movie_id
  AND mi_idx1.movie_id = mc1.movie_id
  AND it2.id = mi_idx2.info_type_id
  AND t2.id = mi_idx2.movie_id
  AND kt2.id = t2.kind_id
  AND cn2.id = mc2.company_id
  AND t2.id = mc2.movie_id
  AND ml.linked_movie_id = mi_idx2.movie_id
  AND ml.linked_movie_id = mc2.movie_id
  AND mi_idx2.movie_id = mc2.movie_id;

