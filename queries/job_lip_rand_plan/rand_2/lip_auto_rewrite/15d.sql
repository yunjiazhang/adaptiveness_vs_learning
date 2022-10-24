SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code = '[us]';
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'release dates';
SELECT sum(pg_lip_bloom_add(2, mi.movie_id)) FROM movie_info AS mi WHERE mi.note LIKE '%internet%';
-- SELECT sum(pg_lip_bloom_add(3, t.id)) FROM title AS t WHERE t.production_year > 1990;

/*+
NestLoop(mc ct t mk mi k at cn it1)
NestLoop(mc ct t mk mi k at cn)
NestLoop(mc ct t mk mi k at)
NestLoop(mc ct t mk mi k)
NestLoop(mc ct t mk mi)
NestLoop(mc ct t mk)
NestLoop(mc ct t)
NestLoop(mc ct)
SeqScan(mc)
IndexScan(ct)
IndexScan(t)
IndexScan(mk)
IndexScan(mi)
IndexScan(k)
IndexScan(at)
IndexScan(cn)
IndexScan(it1)
Leading(((((((((mc ct) t) mk) mi) k) at) cn) it1))*/
SELECT MIN(at.title) AS aka_title,
       MIN(t.title) AS internet_movie_title
 FROM 
(
	SELECT * FROM aka_title AS at 
	 WHERE pg_lip_bloom_probe(2, at.movie_id)
	-- AND pg_lip_bloom_probe(3, at.movie_id)
) AS at ,
company_name AS cn ,
company_type AS ct ,
info_type AS it1 ,
keyword AS k ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
	AND pg_lip_bloom_probe(2, mc.movie_id)
	-- AND pg_lip_bloom_probe(3, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(1, mi.info_type_id)
	-- AND pg_lip_bloom_probe(3, mi.movie_id)
) AS mi ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(2, mk.movie_id)
	-- AND pg_lip_bloom_probe(3, mk.movie_id)
) AS mk ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(2, t.id)
) AS t
WHERE
 cn.country_code = '[us]'
  AND it1.info = 'release dates'
  AND mi.note LIKE '%internet%'
  AND t.production_year > 1990
  AND t.id = at.movie_id
  AND t.id = mi.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND mk.movie_id = mi.movie_id
  AND mk.movie_id = mc.movie_id
  AND mk.movie_id = at.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi.movie_id = at.movie_id
  AND mc.movie_id = at.movie_id
  AND k.id = mk.keyword_id
  AND it1.id = mi.info_type_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;

