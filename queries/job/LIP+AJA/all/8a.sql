SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);

-- SELECT sum(pg_lip_bloom_add(4, movie_id)) FROM cast_info AS ci WHERE ci.note ='(voice: English version)';
-- SELECT sum(pg_lip_bloom_add(4, movie_id)) FROM movie_companies AS mc WHERE mc.note LIKE '%(Japan)%'
--   AND mc.note NOT LIKE '%(USA)%';
SELECT sum(pg_lip_bloom_add(2, id)) FROM name AS n1 WHERE n1.name LIKE '%Yo%'
  AND n1.name NOT LIKE '%Yu%';
SELECT sum(pg_lip_bloom_add(3, id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_bit_and(4, 1, 0));


-- enforce workers = 3
/*+
NestLoop(cn mc t ci rt an1 n1) 
NestLoop(cn mc t ci rt an1) 
HashJoin(cn mc t ci rt) 
NestLoop(cn mc t ci) 
NestLoop(cn mc t) 
NestLoop(cn mc)
Leading(((((((cn mc) t) ci) rt) an1) n1))
*/
SELECT MIN(an1.name) AS actress_pseudonym,
       MIN(t.title) AS japanese_movie_dubbed
FROM aka_name AS an1,
     (
      SELECT * FROM cast_info AS ci
      WHERE 
      -- pg_lip_bloom_probe(4, movie_id) AND 
      pg_lip_bloom_probe(2, person_id) 
      -- AND pg_lip_bloom_probe(3, role_id)
     ) AS ci,
     company_name AS cn,
     (
      select * from movie_companies as mc
      -- where pg_lip_bloom_probe(4, movie_id)
     ) AS mc,
     name AS n1,
     role_type AS rt,
     (
      select * from title as t
      -- where pg_lip_bloom_probe(4, id)
    ) AS t
WHERE ci.note ='(voice: English version)'
  AND cn.country_code ='[jp]'
  AND mc.note LIKE '%(Japan)%'
  AND mc.note NOT LIKE '%(USA)%'
  AND n1.name LIKE '%Yo%'
  AND n1.name NOT LIKE '%Yu%'
  AND rt.role ='actress'
  AND an1.person_id = n1.id
  AND n1.id = ci.person_id
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND an1.person_id = ci.person_id
  AND ci.movie_id = mc.movie_id;

