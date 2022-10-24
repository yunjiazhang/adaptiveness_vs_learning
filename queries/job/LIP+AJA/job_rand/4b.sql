SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
SELECT sum(pg_lip_bloom_add(0, id)) FROM info_type AS it WHERE it.info ='rating';
SELECT sum(pg_lip_bloom_add(1, movie_id)) FROM movie_info_idx AS mi_idx WHERE mi_idx.info > '9.0';


-- enforce workers = 2
/*+
NestLoop(mi_idx it t mk k)
NestLoop(mi_idx it t mk)
NestLoop(mi_idx it t)
NestLoop(mi_idx it)
IndexScan(mi_idx)
Leading(((((it mi_idx) t) mk) k))
*/
SELECT MIN(mi_idx.info) AS rating,
       MIN(t.title) AS movie_title
FROM info_type AS it,
     keyword AS k,
    (
      SELECT * FROM movie_info_idx AS mi_idx
      WHERE pg_lip_bloom_probe(0, info_type_id)
    )
    AS mi_idx,
      (
        select * from movie_keyword as mk
        where pg_lip_bloom_probe(1, movie_id)
      ) AS mk,
     (
        select * from title as t
        where pg_lip_bloom_probe(1, id)
      ) AS t
WHERE it.info ='rating'
  AND k.keyword LIKE '%sequel%'
  AND mi_idx.info > '9.0'
  AND t.production_year > 2010
  AND t.id = mi_idx.movie_id
  AND t.id = mk.movie_id
  AND mk.movie_id = mi_idx.movie_id
  AND k.id = mk.keyword_id
  AND it.id = mi_idx.info_type_id;
