SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM role_type AS rt WHERE rt.role ='writer';


/*+
HashJoin(mc cn t rt ci n1 a1)
HashJoin(mc cn t rt ci n1)
HashJoin(mc cn t rt ci)
HashJoin(mc cn t)
NestLoop(rt ci)
NestLoop(mc cn)
Leading((a1 (((t (cn mc)) (rt ci)) n1)))
*/
SELECT MIN(a1.name) AS writer_pseudo_name,
       MIN(t.title) AS movie_title
FROM aka_name AS a1,
     (
       SELECT * FROM cast_info AS ci
      --  WHERE pg_lip_bloom_probe(1, role_id)
     ) AS ci,
     company_name AS cn,
     (
       SELECT * FROM movie_companies as mc  
      -- WHERE pg_lip_bloom_probe(0, company_id)
     ) AS mc,
     name AS n1,
     role_type AS rt,
     title AS t
WHERE cn.country_code ='[us]'
  AND rt.role ='writer'
  AND a1.person_id = n1.id
  AND n1.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND a1.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id;

