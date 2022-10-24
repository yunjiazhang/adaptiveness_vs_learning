/*+ HashJoin(ci mi it1 n t it2 mi_idx)
 HashJoin(it2 mi_idx)
 NestLoop(ci mi it1 n t)
 HashJoin(ci mi it1 n)
 HashJoin(ci mi it1)
 HashJoin(mi it1)
 SeqScan(ci)
 SeqScan(mi)
 SeqScan(it1)
 SeqScan(n)
 IndexScan(t)
 IndexScan(it2)
 IndexScan(mi_idx)
 Leading(((((ci (mi it1)) n) t) (it2 mi_idx))) */
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(t.title) AS movie_title
FROM cast_info AS ci,
     info_type AS it1,
     info_type AS it2,
     movie_info AS mi,
     movie_info_idx AS mi_idx,
     name AS n,
     title AS t
WHERE ci.note IN ('(producer)',
                  '(executive producer)')
  AND it1.info = 'budget'
  AND it2.info = 'votes'
  AND n.gender = 'm'
  AND n.name LIKE '%Tim%'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id;
