SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[de]';
SELECT sum(pg_lip_bloom_add(1, k.id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';

/*+
HashJoin(mk mc t k cn)
HashJoin(mk mc t k)
HashJoin(mk mc t)
HashJoin(mk mc)
SeqScan(mk)
SeqScan(mc)
SeqScan(t)
SeqScan(k)
SeqScan(cn)
Leading(((((mk mc) t) k) cn))*/
SELECT MIN(t.title) AS movie_title
 FROM 
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
title AS t
WHERE
 cn.country_code ='[de]'
  AND k.keyword ='character-name-in-title'
  AND cn.id = mc.company_id
  AND mc.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND mc.movie_id = mk.movie_id;

