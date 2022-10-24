SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(9);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code != '[us]';
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'countries';
SELECT sum(pg_lip_bloom_add(2, it2.id)) FROM info_type AS it2 WHERE it2.info = 'rating';
SELECT sum(pg_lip_bloom_add(3, k.id)) FROM keyword AS k WHERE k.keyword IN ('murder', 'murder-in-title', 'blood', 'violence');
SELECT sum(pg_lip_bloom_add(4, kt.id)) FROM kind_type AS kt WHERE kt.kind IN ('movie', 'episode');
SELECT sum(pg_lip_bloom_add(5, mc.movie_id)) FROM movie_companies AS mc WHERE mc.note NOT LIKE '%(USA)%' AND mc.note LIKE '%(200%)%';
SELECT sum(pg_lip_bloom_add(6, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Germany', 'German', 'USA', 'American');
SELECT sum(pg_lip_bloom_add(7, mi_idx.movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info < '7.0';
SELECT sum(pg_lip_bloom_add(8, t.id)) FROM title AS t WHERE t.production_year > 2009;

/*+
HashJoin(t kt mc mi mk mi_idx it1 it2 k ct cn)
HashJoin(t kt mc mi mk mi_idx it1 it2 k ct)
HashJoin(t kt mc mi mk mi_idx it1 it2 k)
HashJoin(t kt mc mi mk mi_idx it1 it2)
HashJoin(t kt mc mi mk mi_idx it1)
HashJoin(t kt mc mi mk mi_idx)
HashJoin(t kt mc mi mk)
HashJoin(t kt mc mi)
HashJoin(t kt mc)
HashJoin(t kt)
SeqScan(t)
SeqScan(kt)
SeqScan(mc)
SeqScan(mi)
SeqScan(mk)
SeqScan(mi_idx)
SeqScan(it1)
SeqScan(it2)
SeqScan(k)
SeqScan(ct)
SeqScan(cn)
Leading(((((((((((t kt) mc) mi) mk) mi_idx) it1) it2) k) ct) cn))*/
SELECT MIN(cn.name) AS movie_company,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS western_violent_movie
 FROM 
company_name AS cn ,
company_type AS ct ,
info_type AS it1 ,
info_type AS it2 ,
keyword AS k ,
kind_type AS kt ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
	AND pg_lip_bloom_probe(6, mc.movie_id)
	AND pg_lip_bloom_probe(7, mc.movie_id)
	AND pg_lip_bloom_probe(8, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(1, mi.info_type_id)
	AND pg_lip_bloom_probe(5, mi.movie_id)
	AND pg_lip_bloom_probe(7, mi.movie_id)
	AND pg_lip_bloom_probe(8, mi.movie_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(2, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(5, mi_idx.movie_id)
	AND pg_lip_bloom_probe(6, mi_idx.movie_id)
	AND pg_lip_bloom_probe(8, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(3, mk.keyword_id)
	AND pg_lip_bloom_probe(5, mk.movie_id)
	AND pg_lip_bloom_probe(6, mk.movie_id)
	AND pg_lip_bloom_probe(7, mk.movie_id)
	AND pg_lip_bloom_probe(8, mk.movie_id)
) AS mk ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(4, t.kind_id)
	AND pg_lip_bloom_probe(5, t.id)
	AND pg_lip_bloom_probe(6, t.id)
	AND pg_lip_bloom_probe(7, t.id)
) AS t
WHERE
 cn.country_code != '[us]'
  AND it1.info = 'countries'
  AND it2.info = 'rating'
  AND k.keyword IN ('murder',
                    'murder-in-title',
                    'blood',
                    'violence')
  AND kt.kind IN ('movie',
                  'episode')
  AND mc.note NOT LIKE '%(USA)%'
  AND mc.note LIKE '%(200%)%'
  AND mi.info IN ('Germany',
                  'German',
                  'USA',
                  'American')
  AND mi_idx.info < '7.0'
  AND t.production_year > 2009
  AND kt.id = t.kind_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND mk.movie_id = mc.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mc.movie_id
  AND mc.movie_id = mi_idx.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND ct.id = mc.company_type_id
  AND cn.id = mc.company_id;
