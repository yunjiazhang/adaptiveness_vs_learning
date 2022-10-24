SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM cast_info AS ci WHERE ci.note LIKE '%(producer)%';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM title AS t WHERE t.production_year > 2010;
-- SELECT sum(pg_lip_bloom_add(2, id)) FROM role_type AS rt WHERE rt.role = 'actor';
-- SELECT sum(pg_lip_bloom_add(3, id)) FROM company_name AS cn WHERE cn.country_code = '[ru]'; -- filter on mc.company_id


/*+
NestLoop(cn mc t ci rt chn ct)
NestLoop(cn mc t ci rt chn)
HashJoin(cn mc t ci rt)
NestLoop(cn mc t ci)
NestLoop(cn mc t)
NestLoop(cn mc)
Leading(((((((cn mc) t) ci) rt) chn) ct))
*/
SELECT MIN(chn.name) AS character,
       MIN(t.title) AS russian_mov_with_actor_producer
FROM char_name AS chn,
     cast_info AS ci,
     company_name AS cn,
     company_type AS ct,
     movie_companies AS mc,
     role_type AS rt,
     title AS t
WHERE ci.note LIKE '%(producer)%'
  AND cn.country_code = '[ru]'
  AND rt.role = 'actor'
  AND t.production_year > 2010
  AND t.id = mc.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mc.movie_id
  AND chn.id = ci.person_role_id
  AND rt.id = ci.role_id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id;

