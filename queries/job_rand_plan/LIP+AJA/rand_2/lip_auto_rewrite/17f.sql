SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, k.id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';
SELECT sum(pg_lip_bloom_add(1, n.id)) FROM name AS n WHERE n.name LIKE '%B%';

/*+
HashJoin(mk mc t ci n cn k)
HashJoin(mk mc t ci n cn)
HashJoin(mk mc t ci n)
NestLoop(mk mc t ci)
NestLoop(mk mc t)
NestLoop(mk mc)
SeqScan(mk)
IndexScan(mc)
IndexScan(t)
IndexScan(ci)
SeqScan(n)
SeqScan(cn)
SeqScan(k)
Leading(((((((mk mc) t) ci) n) cn) k))*/
SELECT MIN(n.name) AS member_in_charnamed_movie
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(1, ci.person_id)
) AS ci ,
company_name AS cn ,
keyword AS k ,
movie_companies AS mc ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(0, mk.keyword_id)
) AS mk ,
name AS n ,
title AS t
WHERE
 k.keyword ='character-name-in-title'
  AND n.name LIKE '%B%'
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;
