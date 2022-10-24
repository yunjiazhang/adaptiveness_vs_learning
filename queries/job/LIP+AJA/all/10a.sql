SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note LIKE '%(voice)%' AND ci.note LIKE '%(uncredited)%';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM title AS t WHERE t.production_year > 2005;
-- SELECT pg_lip_bloom_bit_and(2, 0, 1);
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM company_name AS cn WHERE cn.country_code = '[ru]'; -- filter on mc.company_id
SELECT sum(pg_lip_bloom_add(4, id)) FROM role_type AS rt WHERE rt.role = 'actor'; -- on ci.role_id

/*+
NestLoop(mc cn t ci rt chn ct)
NestLoop(mc cn t ci rt chn)
NestLoop(mc cn t ci rt)
NestLoop(mc cn t ci)
NestLoop(mc cn t)
HashJoin(mc cn)
Leading((((rt (((mc cn) t) ci)) chn) ct))
*/
SELECT MIN(chn.name) AS uncredited_voiced_character,
       MIN(t.title) AS russian_movie
FROM char_name AS chn,
     (
    SELECT * FROM cast_info AS ci
    WHERE pg_lip_bloom_probe(4, ci.role_id) AND ci.note LIKE '%(voice)%' AND ci.note LIKE '%(uncredited)%'
) AS ci,
     company_name AS cn,
     company_type AS ct,
     (
    SELECT * FROM movie_companies AS mc
    -- WHERE pg_lip_bloom_probe(1, mc.movie_id)
) AS mc,
     role_type AS rt,
     (
    SELECT * FROM title AS t
    WHERE t.production_year > 2005
) AS t
WHERE cn.country_code = '[ru]'
  AND rt.role = 'actor'
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mc.movie_id
  AND chn.id = ci.person_role_id
  AND rt.id = ci.role_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;

