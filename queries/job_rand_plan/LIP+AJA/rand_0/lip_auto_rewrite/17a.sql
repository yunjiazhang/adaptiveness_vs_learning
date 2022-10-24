SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(1, k.id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';
SELECT sum(pg_lip_bloom_add(2, n.id)) FROM name AS n WHERE n.name LIKE 'B%';

/*+
HashJoin(mc mk t ci cn n k)
HashJoin(mc mk t ci cn n)
HashJoin(mc mk t ci cn)
HashJoin(mc mk t ci)
HashJoin(mc mk t)
HashJoin(mc mk)
SeqScan(mc)
SeqScan(mk)
SeqScan(t)
SeqScan(ci)
SeqScan(cn)
SeqScan(n)
SeqScan(k)
Leading(((((((mc mk) t) ci) cn) n) k))*/
SELECT MIN(n.name) AS member_in_charnamed_american_movie,
       MIN(n.name) AS a1
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.person_id)
) AS ci ,
company_name AS cn ,
keyword AS k ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.company_id)
) AS mc ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(1, mk.keyword_id)
) AS mk ,
name AS n ,
title AS t
WHERE
 cn.country_code ='[us]'
  AND k.keyword ='character-name-in-title'
  AND n.name LIKE 'B%'
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;

