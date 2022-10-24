SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(1, ct.id)) FROM company_type AS ct WHERE ct.kind IS NOT NULL AND (ct.kind ='production companies' OR ct.kind = 'distributors');
SELECT sum(pg_lip_bloom_add(2, it1.id)) FROM info_type AS it1 WHERE it1.info ='budget';
SELECT sum(pg_lip_bloom_add(3, it2.id)) FROM info_type AS it2 WHERE it2.info ='bottom 10 rank';
SELECT sum(pg_lip_bloom_add(4, t.id)) FROM title AS t WHERE t.production_year >2000 AND (t.title LIKE 'Birdemic%' OR t.title LIKE '%Movie%');

/*+
HashJoin(mi_idx t it2 mc cn mi ct it1)
HashJoin(mi_idx t it2 mc cn mi ct)
HashJoin(mi_idx t it2 mc cn mi)
HashJoin(mi_idx t it2 mc cn)
HashJoin(mi_idx t it2 mc)
HashJoin(mi_idx t it2)
HashJoin(mi_idx t)
SeqScan(mi_idx)
SeqScan(t)
SeqScan(it2)
SeqScan(mc)
SeqScan(cn)
SeqScan(mi)
SeqScan(ct)
SeqScan(it1)
Leading((((((((mi_idx t) it2) mc) cn) mi) ct) it1))*/
SELECT MIN(mi.info) AS budget,
       MIN(t.title) AS unsuccsessful_movie
 FROM 
company_name AS cn ,
company_type AS ct ,
info_type AS it1 ,
info_type AS it2 ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
	AND pg_lip_bloom_probe(1, mc.company_type_id)
	AND pg_lip_bloom_probe(4, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(2, mi.info_type_id)
	AND pg_lip_bloom_probe(4, mi.movie_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(3, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(4, mi_idx.movie_id)
) AS mi_idx ,
title AS t
WHERE
 cn.country_code ='[us]'
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

