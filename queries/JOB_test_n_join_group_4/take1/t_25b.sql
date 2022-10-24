/*+ HashJoin(mi it1 mk k t ci n mi_idx it2)
 HashJoin(mk k t ci n mi_idx it2)
 HashJoin(mi_idx it2)
 NestLoop(mk k t ci n)
 NestLoop(mk k t ci)
 HashJoin(mk k t)
 HashJoin(mk k)
 HashJoin(mi it1)
 SeqScan(mi)
 IndexScan(it1)
 SeqScan(mk)
 SeqScan(k)
 SeqScan(t)
 IndexScan(ci)
 IndexScan(n)
 SeqScan(mi_idx)
 SeqScan(it2)
 Leading(((mi it1) (((((mk k) t) ci) n) (mi_idx it2)))) */
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
FROM cast_info AS ci,
     info_type AS it1,
     info_type AS it2,
     keyword AS k,
     movie_info AS mi,
     movie_info_idx AS mi_idx,
     movie_keyword AS mk,
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

