/*+ HashJoin(t2 t1 k mk ml lt)
 HashJoin(t1 k mk ml lt)
 NestLoop(t1 k mk ml)
 HashJoin(t1 k mk)
 NestLoop(k mk)
 SeqScan(t2)
 IndexScan(t1)
 IndexScan(k)
 IndexScan(mk)
 IndexScan(ml)
 SeqScan(lt)
 Leading((t2 (((t1 (k mk)) ml) lt))) */
SELECT MIN(lt.link) AS link_type,
       MIN(t1.title) AS first_movie,
       MIN(t2.title) AS second_movie
FROM keyword AS k,
     link_type AS lt,
     movie_keyword AS mk,
     movie_link AS ml,
     title AS t1,
     title AS t2
WHERE k.keyword ='10,000-mile-club'
  AND mk.keyword_id = k.id
  AND t1.id = mk.movie_id
  AND ml.movie_id = t1.id
  AND ml.linked_movie_id = t2.id
  AND lt.id = ml.link_type_id
  AND mk.movie_id = t1.id;

