SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(1, k.id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';
SELECT sum(pg_lip_bloom_add(2, t.id)) FROM title AS t WHERE t.episode_nr >= 50 AND t.episode_nr < 100;

/*+
NestLoop(mk ci mc t an n cn k)
NestLoop(mk ci mc t an n cn)
NestLoop(mk ci mc t an n)
NestLoop(mk ci mc t an)
NestLoop(mk ci mc t)
NestLoop(mk ci mc)
NestLoop(mk ci)
SeqScan(mk)
IndexScan(ci)
IndexScan(mc)
IndexScan(t)
IndexScan(an)
IndexScan(n)
IndexScan(cn)
IndexScan(k)
Leading((((((((mk ci) mc) t) an) n) cn) k))*/
SELECT MIN(an.name) AS cool_actor_pseudonym,
       MIN(t.title) AS series_named_after_char
 FROM 
aka_name AS an ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.movie_id)
) AS ci ,
company_name AS cn ,
keyword AS k ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
	AND pg_lip_bloom_probe(2, mc.movie_id)
) AS mc ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(1, mk.keyword_id)
	AND pg_lip_bloom_probe(2, mk.movie_id)
) AS mk ,
name AS n ,
title AS t
WHERE
 cn.country_code ='[us]'
  AND k.keyword ='character-name-in-title'
  AND t.episode_nr >= 50
  AND t.episode_nr < 100
  AND an.person_id = n.id
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND an.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;

