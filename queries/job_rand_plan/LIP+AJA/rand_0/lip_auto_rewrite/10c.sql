SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note LIKE '%(producer)%';
-- SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code = '[us]';
-- SELECT sum(pg_lip_bloom_add(2, t.id)) FROM title AS t WHERE t.production_year > 1990;

/*+
HashJoin(t mc cn ci ct rt chn)
HashJoin(t mc cn ci ct rt)
HashJoin(t mc cn ci ct)
HashJoin(t mc cn ci)
HashJoin(t mc cn)
HashJoin(t mc)
SeqScan(t)
SeqScan(mc)
SeqScan(cn)
SeqScan(ci)
SeqScan(ct)
SeqScan(rt)
SeqScan(chn)
Leading(((((((t mc) cn) ci) ct) rt) chn))*/
SELECT MIN(chn.name) AS character,
       MIN(t.title) AS movie_with_american_producer
 FROM 
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	--  WHERE pg_lip_bloom_probe(2, ci.movie_id)
) AS ci ,
company_name AS cn ,
company_type AS ct ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	-- AND pg_lip_bloom_probe(1, mc.company_id)
	-- WHERE pg_lip_bloom_probe(2, mc.movie_id)
) AS mc ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
) AS t
WHERE
 ci.note LIKE '%(producer)%'
  AND cn.country_code = '[us]'
  AND t.production_year > 1990
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mc.movie_id
  AND chn.id = ci.person_role_id
  AND rt.id = ci.role_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;
