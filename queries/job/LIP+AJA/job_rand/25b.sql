SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, id)) FROM title as t where t.title LIKE 'Vampire%';
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, id)) FROM info_type AS it2 WHERE it2.info = 'votes';

/*+
NestLoop(k mk it2 mi ci it1 n t)
NestLoop(k mk it2 mi ci it1 n)
NestLoop(k mk it2 mi ci it1)
NestLoop(k mk it2 mi ci)
NestLoop(k mk it2 mi)
NestLoop(k mk it2)
NestLoop(k mk)
Leading(((((((it2 ((k mk) mi_idx)) mi) ci) it1) n) t))
*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
FROM (
        select * from cast_info as ci 
        where pg_lip_bloom_probe(0, movie_id)
    ) AS ci,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     (
        select * from movie_info as mi
        where pg_lip_bloom_probe(1, info_type_id) AND pg_lip_bloom_probe(0, movie_id)
    ) AS mi,
     (
        select * from movie_info_idx as mi_idx
        where pg_lip_bloom_probe(2, info_type_id) AND pg_lip_bloom_probe(0, movie_id)
    ) AS mi_idx,
     (
        select * from movie_keyword as mk
        where  pg_lip_bloom_probe(0, movie_id)
    ) AS mk,
     name AS n,
     title AS t
WHERE ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity')
  AND mi.info = 'Horror'
  AND n.gender = 'm'
  AND t.production_year > 2010
  AND t.title LIKE 'Vampire%'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND t.id = mk.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id;

