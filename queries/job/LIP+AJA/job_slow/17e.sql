SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM company_name AS cn WHERE cn.country_code ='[us]'; -- filter on mc.company_id

/*+
HashJoin(k mk t mc cn ci n)
NestLoop(k mk t mc cn ci)
NestLoop(k mk t mc cn)
NestLoop(k mk t mc)
NestLoop(k mk t)
NestLoop(k mk)
Leading(((((((k mk) t) mc) cn) ci) n))
*/
SELECT MIN(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci,
     company_name AS cn,
     keyword AS k,
     (
        SELECT * FROM movie_companies as mc
        -- WHERE pg_lip_bloom_probe(1, company_id)
     ) AS mc,
     (
        SELECT * FROM movie_keyword as mk
      --   WHERE pg_lip_bloom_probe(0, keyword_id)
     ) AS mk,
     name AS n,
     title AS t
WHERE cn.country_code ='[us]'
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