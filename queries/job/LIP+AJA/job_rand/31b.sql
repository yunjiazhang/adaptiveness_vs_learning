SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(0, id)) FROM keyword AS k WHERE k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital');
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type as it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type as it2 WHERE it2.info = 'votes';
SELECT sum(pg_lip_bloom_add(4, id)) FROM title as t where (t.title LIKE '%Freddy%'
       OR t.title LIKE '%Jason%'
       OR t.title LIKE 'Saw%');


/*+
NestLoop(cn mc mi_idx it2 t mk ci mi it1 k n)
NestLoop(cn mc mi_idx it2 t mk ci mi it1 k)
NestLoop(cn mc mi_idx it2 t mk ci mi it1)
NestLoop(cn mc mi_idx it2 t mk ci mi)
NestLoop(cn mc mi_idx it2 t mk ci)
NestLoop(cn mc mi_idx it2 t mk)
NestLoop(cn mc mi_idx it2 t)
NestLoop(cn mc mi_idx it2)
NestLoop(cn mc mi_idx)
NestLoop(cn mc)
Leading(((((((((((cn mc) mi_idx) it2) t) mk) ci) mi) it1) k) n))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS violent_liongate_movie
FROM cast_info AS ci,
     company_name AS cn,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     (
          select * from movie_companies as mc
          where pg_lip_bloom_probe(4, movie_id)
     ) AS mc,
     (
          select * from  movie_info as mi
          where pg_lip_bloom_probe(2, info_type_id)
     ) AS mi,
     (
          select * from movie_info_idx as mi_idx
          where pg_lip_bloom_probe(3, info_type_id)  AND pg_lip_bloom_probe(4, movie_id)
     ) AS mi_idx,
     (
          select * from movie_keyword as mk
          where pg_lip_bloom_probe(0, keyword_id)
     ) AS mk,
     name AS n,
     title AS t
WHERE ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND cn.name LIKE 'Lionsgate%'
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
  AND mc.note LIKE '%(Blu-ray)%'
  AND mi.info IN ('Horror',
                  'Thriller')
  AND n.gender = 'm'
  AND t.production_year > 2000
  AND (t.title LIKE '%Freddy%'
       OR t.title LIKE '%Jason%'
       OR t.title LIKE 'Saw%')
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND t.id = mc.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND ci.movie_id = mc.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi.movie_id = mc.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND mi_idx.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id
  AND cn.id = mc.company_id;

