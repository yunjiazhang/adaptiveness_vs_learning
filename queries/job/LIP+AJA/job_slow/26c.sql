SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(7);
SELECT sum(pg_lip_bloom_add(0, id)) FROM comp_cast_type AS cct1 WHERE cct1.kind = 'cast';
SELECT sum(pg_lip_bloom_add(1, id)) FROM comp_cast_type AS cct2 WHERE cct2.kind LIKE '%complete%';
SELECT sum(pg_lip_bloom_add(2, id)) FROM char_name AS chn WHERE chn.name IS NOT NULL
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%');
SELECT sum(pg_lip_bloom_add(3, id)) FROM info_type AS it2 WHERE it2.info = 'rating';
SELECT sum(pg_lip_bloom_add(4, id)) FROM keyword AS k WHERE k.keyword IN ('superhero',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence',
                    'magnet',
                    'web',
                    'claw',
                    'laser');
SELECT sum(pg_lip_bloom_add(5, id)) FROM kind_type AS kt WHERE kt.kind = 'movie';
-- SELECT sum(pg_lip_bloom_add(6, id)) FROM title AS t WHERE t.production_year > 2000;

/*+
NestLoop(cct1 cc cct2 mi_idx it2 t kt ci chn mk k n)
NestLoop(cct1 cc cct2 mi_idx it2 t kt ci chn mk k)
NestLoop(cct1 cc cct2 mi_idx it2 t kt ci chn mk)
NestLoop(cct1 cc cct2 mi_idx it2 t kt ci chn)
NestLoop(cct1 cc cct2 mi_idx it2 t kt ci)
NestLoop(cct1 cc cct2 mi_idx it2 t kt)
NestLoop(cct1 cc cct2 mi_idx it2 t)
NestLoop(cct1 cc cct2 mi_idx it2)
NestLoop(cct1 cc cct2 mi_idx)
NestLoop(cct1 cc cct2)
NestLoop(cct1 cc)
Leading(((((((kt ((it2 (((cct1 cc) cct2) mi_idx)) t)) ci) chn) mk) k) n))
*/
SELECT MIN(chn.name) AS character_name,
       MIN(mi_idx.info) AS rating,
       MIN(t.title) AS complete_hero_movie
FROM (
        SELECT * FROM complete_cast as cc
        WHERE 
      --   pg_lip_bloom_probe(6, movie_id) AND 
        pg_lip_bloom_probe(0, subject_id)
        AND pg_lip_bloom_probe(1, status_id)
     ) AS cc,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2,
     char_name AS chn,
     (
        SELECT * FROM cast_info as ci
        WHERE 
      --   pg_lip_bloom_probe(6, movie_id) AND 
        pg_lip_bloom_probe(2, person_role_id)
     ) AS ci,
     info_type AS it2,
     keyword AS k,
     kind_type AS kt,
     (
        SELECT * FROM movie_info_idx as mi_idx
        WHERE 
      --   pg_lip_bloom_probe(6, movie_id) AND 
        pg_lip_bloom_probe(3, info_type_id)
     ) AS mi_idx,
     (
        SELECT * FROM movie_keyword as mk
        WHERE 
        -- pg_lip_bloom_probe(6, movie_id)
        -- AND 
        pg_lip_bloom_probe(4, keyword_id)
     ) AS mk,
     name AS n,
     (
         SELECT * FROM title as t
         WHERE pg_lip_bloom_probe(5, kind_id)
     ) AS t
WHERE cct1.kind = 'cast'
  AND cct2.kind LIKE '%complete%'
  AND chn.name IS NOT NULL
  AND (chn.name LIKE '%man%'
       OR chn.name LIKE '%Man%')
  AND it2.info = 'rating'
  AND k.keyword IN ('superhero',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence',
                    'magnet',
                    'web',
                    'claw',
                    'laser')
  AND kt.kind = 'movie'
  AND t.production_year > 2000
  AND kt.id = t.kind_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND t.id = cc.movie_id
  AND t.id = mi_idx.movie_id
  AND mk.movie_id = ci.movie_id
  AND mk.movie_id = cc.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND ci.movie_id = cc.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND cc.movie_id = mi_idx.movie_id
  AND chn.id = ci.person_role_id
  AND n.id = ci.person_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id
  AND it2.id = mi_idx.info_type_id;

-- 1108 ms / 3458 ms

