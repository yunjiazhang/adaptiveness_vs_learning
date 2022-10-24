SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)',
--                   '(voice: Japanese version)',
--                   '(voice) (uncredited)',
--                   '(voice: English version)');
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM role_type AS rt WHERE rt.role ='actress';
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM name AS n WHERE n.gender ='f';
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM company_name AS cn WHERE cn.country_code ='[us]';

/*+
HashJoin(mc cn rt ci n chn t an)
HashJoin(mc cn rt ci n chn t)
HashJoin(mc cn rt ci n chn)
HashJoin(mc cn rt ci n)
HashJoin(mc cn rt ci)
NestLoop(mc cn)
NestLoop(rt ci)
Leading((an (t (chn (n ((cn mc) (rt ci)))))))
*/
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
FROM aka_name AS an,
     char_name AS chn,
     (
        SELECT * FROM cast_info as ci
      --   WHERE 
      --   pg_lip_bloom_probe(1, role_id) 
      --   AND 
      --   pg_lip_bloom_probe(2, person_id)
     ) AS ci,
     company_name AS cn,
     (
        SELECT * FROM movie_companies as mc
      --   WHERE 
      --   pg_lip_bloom_probe(0, movie_id) -- AND 
      --   pg_lip_bloom_probe(3, company_id)
     ) AS mc,
     name AS n,
     role_type AS rt,
     (
        SELECT * FROM title as t
      --   WHERE pg_lip_bloom_probe(0, id)
     ) AS t
WHERE ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND n.gender ='f'
  AND rt.role ='actress'
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND ci.movie_id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND n.id = ci.person_id
  AND chn.id = ci.person_role_id
  AND an.person_id = n.id
  AND an.person_id = ci.person_id;
