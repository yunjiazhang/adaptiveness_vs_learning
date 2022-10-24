SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(5, movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Drama',
--                   'Horror');
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM title AS t WHERE t.production_year >2000
--                                                   AND (t.title LIKE 'Birdemic%'
--                                                        OR t.title LIKE '%Movie%');
-- SELECT sum(pg_lip_bloom_add(6, movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info > '8.0';
-- SELECT pg_lip_bloom_bit_and(5, 5, 7);
-- SELECT pg_lip_bloom_bit_and(5, 5, 6);

-- SELECT sum(pg_lip_bloom_add(1, id)) FROM company_name AS cn WHERE cn.country_code ='[us]'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(0, id)) FROM company_type AS ct WHERE ct.kind IS NOT NULL AND 
                                                            (ct.kind ='production companies'
                                                                 OR ct.kind = 'distributors');
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info ='budget'; -- filter on mc.company_id
-- SELECT sum(pg_lip_bloom_add(4, id)) FROM info_type AS it2 WHERE it2.info ='bottom 10 rank'; -- filter on mc.company_id


/*+
NestLoop(it2 mi_idx t mi it1 mc cn ct)
NestLoop(it2 mi_idx t mi it1 mc cn)
NestLoop(it2 mi_idx t mi it1 mc)
NestLoop(it2 mi_idx t mi it1)
NestLoop(it2 mi_idx t mi)
NestLoop(it2 mi_idx t)
NestLoop(it2 mi_idx)
IndexScan(mi_idx)
Leading((((((((it2 mi_idx) t) mi) it1) mc) cn) ct))
*/
SELECT MIN(mi.info) AS budget,
       MIN(t.title) AS unsuccsessful_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it1,
     info_type AS it2,
     (
          select * from movie_companies as mc
          where pg_lip_bloom_probe(0, company_type_id) -- AND pg_lip_bloom_probe(0, movie_id)
     ) AS mc,
     (
          select * from movie_info as mi
          where pg_lip_bloom_probe(1, info_type_id)
     ) AS mi,
     (
          select * from movie_info_idx as mi_idx
          -- where pg_lip_bloom_probe(0, movie_id)
          -- where 
     ) AS mi_idx,
     title AS t
WHERE cn.country_code ='[us]'
  AND ct.kind IS NOT NULL
  AND (ct.kind ='production companies'
       OR ct.kind = 'distributors')
  AND it1.info ='budget'
  AND it2.info ='bottom 10 rank'
  AND t.production_year >2000
  AND (t.title LIKE 'Birdemic%'
       OR t.title LIKE '%Movie%')
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

  -- 8 ms