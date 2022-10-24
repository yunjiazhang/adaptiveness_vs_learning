/*+ HashJoin(t2 ml lt t1 mk k)
 HashJoin(ml lt t1 mk k)
 NestLoop(mk k)
 NestLoop(ml lt t1)
 NestLoop(ml lt)
 SeqScan(t2)
 IndexScan(ml)
 SeqScan(lt)
 IndexScan(t1)
 SeqScan(mk)
 IndexScan(k)
 Leading((t2 (((ml lt) t1) (mk k)))) */
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

