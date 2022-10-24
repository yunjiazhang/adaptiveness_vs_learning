SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note LIKE '%(producer)%';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM title AS t WHERE t.production_year > 1990;
-- SELECT pg_lip_bloom_bit_and(2, 0, 1); -- global filter on movie_id
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM company_name AS cn WHERE cn.country_code = '[us]'; -- filter on mc.company_id

/*+
NestLoop(cn mc t ct ci chn rt)
HashJoin(cn mc t ct ci chn)
HashJoin(cn mc t ct ci)
HashJoin(cn mc t ct)
HashJoin(cn mc t)
NestLoop(cn mc)
Leading((rt (chn (ci (ct (t (cn mc)))))))
*/
SELECT MIN(chn.name) AS character,
       MIN(t.title) AS movie_with_american_producer
FROM char_name AS chn,
     (
        SELECT * FROM cast_info as ci
        -- WHERE pg_lip_bloom_probe(0, movie_id)
     ) AS ci,
     company_name AS cn,
     company_type AS ct,
     (
        SELECT * FROM movie_companies as mc
        -- WHERE 
        -- pg_lip_bloom_probe(0, movie_id) -- AND 
        -- pg_lip_bloom_probe(3, company_id)
     ) AS mc,
     role_type AS rt,
     (
        SELECT * FROM title as t
        -- WHERE pg_lip_bloom_probe(0, id)
     ) AS t
WHERE cn.country_code = '[us]'
  AND ci.note LIKE '%(producer)%'
  AND t.id = mc.movie_id
  AND t.production_year > 1990
  AND t.id = ci.movie_id
  AND ci.movie_id = mc.movie_id
  AND chn.id = ci.person_role_id
  AND rt.id = ci.role_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;


