/*+ NestLoop(k ml lt t1 mk t2)
 MergeJoin(k ml lt t1 mk)
 NestLoop(ml lt t1 mk)
 NestLoop(ml lt t1)
 NestLoop(ml lt)
 SeqScan(k)
 SeqScan(ml)
 IndexScan(lt)
 IndexScan(t1)
 IndexScan(mk)
 IndexScan(t2)
 Leading(((k (((ml lt) t1) mk)) t2)) */
SELECT MIN(lt.link) AS link_type,
       MIN(t1.title) AS first_movie,
       MIN(t2.title) AS second_movie
FROM keyword AS k,
     link_type AS lt,
     movie_keyword AS mk,
     movie_link AS ml,
     title AS t1,
     title AS t2
WHERE k.keyword ='character-name-in-title'
  AND mk.keyword_id = k.id
  AND t1.id = mk.movie_id
  AND ml.movie_id = t1.id
  AND ml.linked_movie_id = t2.id
  AND lt.id = ml.link_type_id
  AND mk.movie_id = t1.id;

