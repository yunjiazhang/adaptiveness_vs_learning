SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
-- SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(2, it.id)) FROM info_type AS it WHERE it.info = 'release dates';
-- SELECT sum(pg_lip_bloom_add(3, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IS NOT NULL AND (mi.info LIKE 'Japan:%200%' OR mi.info LIKE 'USA:%200%');
SELECT sum(pg_lip_bloom_add(4, n.id)) FROM name AS n WHERE n.gender ='f' AND n.name LIKE '%An%';
SELECT sum(pg_lip_bloom_add(5, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(6, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
NestLoop(ci mi mc chn rt cn t it n an)
NestLoop(ci mi mc chn rt cn t it n)
NestLoop(ci mi mc chn rt cn t it)
NestLoop(ci mi mc chn rt cn t)
NestLoop(ci mi mc chn rt cn)
NestLoop(ci mi mc chn rt)
NestLoop(ci mi mc chn)
NestLoop(ci mi mc)
NestLoop(ci mi)
SeqScan(ci)
IndexScan(mi)
IndexScan(mc)
IndexScan(chn)
IndexScan(rt)
IndexScan(cn)
IndexScan(t)
IndexScan(it)
IndexScan(n)
IndexScan(an)
Leading((((((((((ci mi) mc) chn) rt) cn) t) it) n) an))*/
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
 FROM 
(
	SELECT * FROM aka_name AS an 
	 WHERE pg_lip_bloom_probe(4, an.person_id)
) AS an ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	--  WHERE pg_lip_bloom_probe(3, ci.movie_id)
	WHERE pg_lip_bloom_probe(4, ci.person_id)
	AND pg_lip_bloom_probe(5, ci.role_id)
	-- AND pg_lip_bloom_probe(6, ci.movie_id)
) AS ci ,
company_name AS cn ,
info_type AS it ,
(
	SELECT * FROM movie_companies AS mc 
	--  WHERE pg_lip_bloom_probe(0, mc.movie_id)
	WHERE pg_lip_bloom_probe(1, mc.company_id)
	-- AND pg_lip_bloom_probe(3, mc.movie_id)
	-- AND pg_lip_bloom_probe(6, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	--  WHERE pg_lip_bloom_probe(0, mi.movie_id)
	WHERE pg_lip_bloom_probe(2, mi.info_type_id)
	-- AND pg_lip_bloom_probe(6, mi.movie_id)
) AS mi ,
name AS n ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	--  WHERE pg_lip_bloom_probe(0, t.id)
	-- AND pg_lip_bloom_probe(3, t.id)
) AS t
WHERE
 ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND mi.info IS NOT NULL
  AND (mi.info LIKE 'Japan:%200%'
       OR mi.info LIKE 'USA:%200%')
  AND n.gender ='f'
  AND n.name LIKE '%An%'
  AND rt.role ='actress'
  AND t.production_year > 2000
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND mc.movie_id = ci.movie_id
  AND mc.movie_id = mi.movie_id
  AND mi.movie_id = ci.movie_id
  AND cn.id = mc.company_id
  AND it.id = mi.info_type_id
  AND n.id = ci.person_id
  AND rt.id = ci.role_id
  AND n.id = an.person_id
  AND ci.person_id = an.person_id
  AND chn.id = ci.person_role_id;

