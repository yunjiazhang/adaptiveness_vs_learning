SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
-- SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note ='(voice: English version)';
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[jp]';
SELECT sum(pg_lip_bloom_add(2, mc.movie_id)) FROM movie_companies AS mc WHERE mc.note LIKE '%(Japan)%' AND mc.note NOT LIKE '%(USA)%';
SELECT sum(pg_lip_bloom_add(3, n1.id)) FROM name AS n1 WHERE n1.name LIKE '%Yo%' AND n1.name NOT LIKE '%Yu%';
-- SELECT sum(pg_lip_bloom_add(4, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';

/*+
NestLoop(ci rt mc cn t n1 an1)
NestLoop(ci rt mc cn t n1)
NestLoop(ci rt mc cn t)
NestLoop(ci rt mc cn)
NestLoop(ci rt mc)
NestLoop(ci rt)
SeqScan(ci)
IndexScan(rt)
IndexScan(mc)
IndexScan(cn)
IndexScan(t)
IndexScan(n1)
IndexScan(an1)
Leading(((((((ci rt) mc) cn) t) n1) an1))*/
SELECT MIN(an1.name) AS actress_pseudonym,
       MIN(t.title) AS japanese_movie_dubbed
 FROM 
(
	SELECT * FROM aka_name AS an1 
	 WHERE pg_lip_bloom_probe(3, an1.person_id)
) AS an1 ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.movie_id)
	AND pg_lip_bloom_probe(3, ci.person_id)
	-- AND pg_lip_bloom_probe(4, ci.role_id)
) AS ci ,
company_name AS cn ,
(
	SELECT * FROM movie_companies AS mc 
	--  WHERE pg_lip_bloom_probe(0, mc.movie_id)
	WHERE pg_lip_bloom_probe(1, mc.company_id)
) AS mc ,
name AS n1 ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	--  WHERE pg_lip_bloom_probe(0, t.id)
	WHERE pg_lip_bloom_probe(2, t.id)
) AS t
WHERE
 ci.note ='(voice: English version)'
  AND cn.country_code ='[jp]'
  AND mc.note LIKE '%(Japan)%'
  AND mc.note NOT LIKE '%(USA)%'
  AND n1.name LIKE '%Yo%'
  AND n1.name NOT LIKE '%Yu%'
  AND rt.role ='actress'
  AND an1.person_id = n1.id
  AND n1.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND an1.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id;

