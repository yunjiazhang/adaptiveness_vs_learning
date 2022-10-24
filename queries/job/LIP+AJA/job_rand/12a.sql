SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(10);
SELECT sum(pg_lip_bloom_add(5, movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Drama',
                  'Horror');
-- SELECT sum(pg_lip_bloom_add(7, id)) FROM title AS t WHERE t.production_year BETWEEN 2005 AND 2008;
-- SELECT sum(pg_lip_bloom_add(6, movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info > '8.0';
-- SELECT pg_lip_bloom_bit_and(5, 5, 7); -- global filter on movie_id
-- SELECT pg_lip_bloom_bit_and(5, 5, 6); -- global filter on movie_id
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM company_name AS cn WHERE cn.country_code ='[us]';  
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM company_type AS ct WHERE ct.kind = 'production companies'; 
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type AS it1 WHERE it1.info = 'genres'; 
SELECT sum(pg_lip_bloom_add(4, id)) FROM info_type AS it2 WHERE it2.info = 'rating';


/*+
NestLoop(it2 mi_idx mc ct t cn mi it1)
NestLoop(it2 mi_idx mc ct t cn mi)
NestLoop(it2 mi_idx mc ct t cn)
NestLoop(it2 mi_idx mc ct t)
NestLoop(it2 mi_idx mc ct)
NestLoop(it2 mi_idx mc)
NestLoop(it2 mi_idx)
IndexScan(mi_idx)
Leading((((((((it2 mi_idx) mc) ct) t) cn) mi) it1))
*/
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS drama_horror_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     info_type AS it2,
     (
    SELECT * FROM movie_companies AS mc
    WHERE  
    -- pg_lip_bloom_probe(1, mc.company_id) AND 
    -- pg_lip_bloom_probe(2, mc.company_type_id)
    pg_lip_bloom_probe(5, movie_id)
) AS mc,
     (
    SELECT * FROM movie_info AS mi
    WHERE mi.info IN ('Drama', 'Horror') 
    AND pg_lip_bloom_probe(3, info_type_id) 
    AND pg_lip_bloom_probe(5, movie_id)
) AS mi,
     (
    SELECT * FROM movie_info_idx as mi_idx
    WHERE info > '8.0' AND pg_lip_bloom_probe(4, info_type_id) AND pg_lip_bloom_probe(5, movie_id)
) AS mi_idx,
     (
    SELECT * FROM title as t WHERE pg_lip_bloom_probe(5, id) AND (t.production_year BETWEEN 2005 AND 2008)
) AS t
WHERE cn.country_code = '[us]'
  AND ct.kind = 'production companies'
  AND it1.info = 'genres'
  AND it2.info = 'rating'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND mi.info_type_id = it1.id
  AND mi_idx.info_type_id = it2.id
  AND t.id = mc.movie_id
  AND ct.id = mc.company_type_id
  AND cn.id = mc.company_id
  AND mc.movie_id = mi.movie_id
  AND mc.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id;