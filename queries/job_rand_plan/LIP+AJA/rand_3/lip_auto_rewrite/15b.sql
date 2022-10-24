SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code = '[us]' AND cn.name = 'YouTube';
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'release dates';
SELECT sum(pg_lip_bloom_add(2, mc.movie_id)) FROM movie_companies AS mc WHERE mc.note LIKE '%(200%)%' AND mc.note LIKE '%(worldwide)%';
SELECT sum(pg_lip_bloom_add(3, mi.movie_id)) FROM movie_info AS mi WHERE mi.note LIKE '%internet%' AND mi.info LIKE 'USA:% 200%';
SELECT sum(pg_lip_bloom_add(4, t.id)) FROM title AS t WHERE t.production_year between 2005 and 2010;

/*+
HashJoin(mc t mi mk at k cn ct it1)
HashJoin(mc t mi mk at k cn ct)
HashJoin(mc t mi mk at k cn)
HashJoin(mc t mi mk at k)
HashJoin(mc t mi mk at)
HashJoin(mc t mi mk)
HashJoin(mc t mi)
HashJoin(mc t)
SeqScan(mc)
SeqScan(t)
SeqScan(mi)
SeqScan(mk)
SeqScan(at)
SeqScan(k)
SeqScan(cn)
SeqScan(ct)
SeqScan(it1)
Leading(((((((((mc t) mi) mk) at) k) cn) ct) it1))*/
SELECT MIN(mi.info) AS release_date,
       MIN(t.title) AS youtube_movie
 FROM 
(
	SELECT * FROM aka_title AS at 
	 WHERE pg_lip_bloom_probe(2, at.movie_id)
	AND pg_lip_bloom_probe(3, at.movie_id)
	AND pg_lip_bloom_probe(4, at.movie_id)
) AS at ,
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
  AND cn.name = 'YouTube'
  AND it1.info = 'release dates'
  AND mc.note LIKE '%(200%)%'
  AND mc.note LIKE '%(worldwide)%'
  AND mi.note LIKE '%internet%'
  AND mi.info LIKE 'USA:% 200%'
  AND t.production_year BETWEEN 2005 AND 2010
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

