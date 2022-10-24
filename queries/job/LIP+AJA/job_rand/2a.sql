SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, id)) FROM company_name AS cn WHERE cn.country_code ='[de]';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';

/*+
NestLoop(k mk mc cn t)
NestLoop(k mk mc cn)
NestLoop(k mk mc)
NestLoop(k mk)
Leading( ((((k mk) mc) cn) t) )
*/
SELECT MIN(t.title) AS movie_title
FROM company_name AS cn,
     keyword AS k,
     (
        SELECT * FROM movie_companies AS mc
        WHERE pg_lip_bloom_probe(0, company_id) 
     ) AS mc,
     movie_keyword AS mk,
     title AS t
WHERE cn.country_code ='[de]'
  AND k.keyword ='character-name-in-title'
  AND cn.id = mc.company_id
  AND mc.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND mc.movie_id = mk.movie_id;

