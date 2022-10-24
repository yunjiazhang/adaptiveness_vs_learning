SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(2, it.id)) FROM info_type AS it WHERE it.info = 'release dates';
-- SELECT sum(pg_lip_bloom_add(3, n.id)) FROM name AS n WHERE n.gender ='f';
SELECT sum(pg_lip_bloom_add(4, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(5, t.id)) FROM title AS t WHERE t.production_year > 2000;

/*+
HashJoin(mi ci chn it an mc t n cn rt)
HashJoin(mi ci chn it an mc t n cn)
HashJoin(mi ci chn it an mc t n)
HashJoin(mi ci chn it an mc t)
HashJoin(mi ci chn it an mc)
HashJoin(mi ci chn it an)
HashJoin(mi ci chn it)
HashJoin(mi ci chn)
HashJoin(mi ci)
SeqScan(mi)
SeqScan(ci)
SeqScan(chn)
SeqScan(it)
SeqScan(an)
SeqScan(mc)
SeqScan(t)
SeqScan(n)
SeqScan(cn)
SeqScan(rt)
Leading((((((((((mi ci) chn) it) an) mc) t) n) cn) rt))*/
SELECT MIN(n.name) AS voicing_actress,
       MIN(t.title) AS jap_engl_voiced_movie
 FROM 
(
	SELECT * FROM aka_name AS an 
	--  WHERE pg_lip_bloom_probe(3, an.person_id)
) AS an ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	--  WHERE pg_lip_bloom_probe(3, ci.person_id)
	WHERE pg_lip_bloom_probe(4, ci.role_id)
	-- AND pg_lip_bloom_probe(5, ci.movie_id)
) AS ci ,
company_name AS cn ,
info_type AS it ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	AND pg_lip_bloom_probe(1, mc.company_id)
	-- AND pg_lip_bloom_probe(5, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(0, mi.movie_id)
	AND pg_lip_bloom_probe(2, mi.info_type_id)
	-- AND pg_lip_bloom_probe(5, mi.movie_id)
) AS mi ,
name AS n ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
) AS t
WHERE
 ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND it.info = 'release dates'
  AND n.gender ='f'
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

