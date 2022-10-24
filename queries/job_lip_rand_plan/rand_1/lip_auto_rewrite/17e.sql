SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(1, k.id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';

/*+
HashJoin(t ci mc mk n cn k)
HashJoin(t ci mc mk n cn)
HashJoin(t ci mc mk n)
HashJoin(t ci mc mk)
HashJoin(t ci mc)
HashJoin(t ci)
SeqScan(t)
SeqScan(ci)
SeqScan(mc)
SeqScan(mk)
SeqScan(n)
SeqScan(cn)
SeqScan(k)
Leading(((((((t ci) mc) mk) n) cn) k))*/
SELECT MIN(n.name) AS member_in_charnamed_movie
 FROM 
cast_info AS ci ,
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
  AND n.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.movie_id = mc.movie_id
  AND ci.movie_id = mk.movie_id
  AND mc.movie_id = mk.movie_id;



