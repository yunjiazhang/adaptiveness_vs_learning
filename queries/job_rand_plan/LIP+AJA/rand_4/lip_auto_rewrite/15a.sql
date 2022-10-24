SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code = '[us]';
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'release dates';
SELECT sum(pg_lip_bloom_add(2, mc.movie_id)) FROM movie_companies AS mc WHERE mc.note LIKE '%(200%)%' AND mc.note LIKE '%(worldwide)%';
SELECT sum(pg_lip_bloom_add(3, mi.movie_id)) FROM movie_info AS mi WHERE mi.note LIKE '%internet%' AND mi.info LIKE 'USA:% 200%';
SELECT sum(pg_lip_bloom_add(4, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
HashJoin(mc ct t cn mk k mi aka_t it1)
HashJoin(mc ct t cn mk k mi aka_t)
HashJoin(mc ct t cn mk k mi)
HashJoin(mc ct t cn mk k)
HashJoin(mc ct t cn mk)
HashJoin(mc ct t cn)
HashJoin(mc ct t)
HashJoin(mc ct)
SeqScan(mc)
SeqScan(ct)
SeqScan(t)
SeqScan(cn)
SeqScan(mk)
SeqScan(k)
SeqScan(mi)
SeqScan(aka_t)
SeqScan(it1)
Leading(((((((((mc ct) t) cn) mk) k) mi) aka_t) it1))*/
SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS internet_movie
 FROM 
(
	SELECT * FROM aka_title AS aka_t 
	 WHERE pg_lip_bloom_probe(2, aka_t.movie_id)
	AND pg_lip_bloom_probe(3, aka_t.movie_id)
	AND pg_lip_bloom_probe(4, aka_t.movie_id)
) AS aka_t ,
company_name AS cn ,
company_type AS ct ,
info_type AS it1 ,
keyword AS k ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
	AND pg_lip_bloom_probe(3, mc.movie_id)
	AND pg_lip_bloom_probe(4, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(1, mi.info_type_id)
	AND pg_lip_bloom_probe(2, mi.movie_id)
	AND pg_lip_bloom_probe(4, mi.movie_id)
) AS mi ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(2, mk.movie_id)
	AND pg_lip_bloom_probe(3, mk.movie_id)
	AND pg_lip_bloom_probe(4, mk.movie_id)
) AS mk ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(2, t.id)
	AND pg_lip_bloom_probe(3, t.id)
) AS t
WHERE
 cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mc.note LIKE '%(200%)%'
  AND mc.note LIKE '%(worldwide)%'
  AND mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%'
  AND t.production_year > 2000
  AND t.id = aka_t.movie_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mc.movie_id
  AND mk.movie_id = aka_t.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi.movie_id = aka_t.movie_id
  AND mc.movie_id = aka_t.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;
