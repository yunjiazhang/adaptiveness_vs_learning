SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note LIKE '%(voice)%' AND ci.note LIKE '%(uncredited)%';
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code = '[ru]';
SELECT sum(pg_lip_bloom_add(2, rt.id)) FROM role_type AS rt WHERE rt.role = 'actor';
SELECT sum(pg_lip_bloom_add(3, t.id)) FROM title AS t WHERE t.production_year > 2005;

/*+
HashJoin(mc ct cn ci t rt chn)
HashJoin(mc ct cn ci t rt)
HashJoin(mc ct cn ci t)
HashJoin(mc ct cn ci)
HashJoin(mc ct cn)
HashJoin(mc ct)
SeqScan(mc)
SeqScan(ct)
SeqScan(cn)
SeqScan(ci)
SeqScan(t)
SeqScan(rt)
SeqScan(chn)
Leading(((((((mc ct) cn) ci) t) rt) chn))*/
SELECT MIN(chn.name) AS uncredited_voiced_character,
       MIN(t.title) AS russian_movie
 FROM 
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.role_id)
	AND pg_lip_bloom_probe(3, ci.movie_id)
) AS ci ,
company_name AS cn ,
company_type AS ct ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	AND pg_lip_bloom_probe(1, mc.company_id)
	AND pg_lip_bloom_probe(3, mc.movie_id)
) AS mc ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
) AS t
WHERE
 ci.note LIKE '%(voice)%'
  AND ci.note LIKE '%(uncredited)%'
  AND cn.country_code = '[ru]'
  AND rt.role = 'actor'
  AND t.production_year > 2005
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mc.movie_id
  AND chn.id = ci.person_role_id
  AND rt.id = ci.role_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;

