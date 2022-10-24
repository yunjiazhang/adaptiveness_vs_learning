SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(5);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)');
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, it2.id)) FROM info_type AS it2 WHERE it2.info = 'votes';
SELECT sum(pg_lip_bloom_add(3, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War');
SELECT sum(pg_lip_bloom_add(4, n.id)) FROM name AS n WHERE n.gender = 'm';

/*+
HashJoin(mi ci it1 t mi_idx n it2)
HashJoin(mi ci it1 t mi_idx n)
HashJoin(mi ci it1 t mi_idx)
HashJoin(mi ci it1 t)
HashJoin(mi ci it1)
HashJoin(mi ci)
SeqScan(mi)
SeqScan(ci)
SeqScan(it1)
SeqScan(t)
SeqScan(mi_idx)
SeqScan(n)
SeqScan(it2)
Leading(((((((mi ci) it1) t) mi_idx) n) it2))*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(t.title) AS movie_title
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(3, ci.movie_id)
	AND pg_lip_bloom_probe(4, ci.person_id)
) AS ci ,
info_type AS it1 ,
info_type AS it2 ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(0, mi.movie_id)
	AND pg_lip_bloom_probe(1, mi.info_type_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(0, mi_idx.movie_id)
	AND pg_lip_bloom_probe(2, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(3, mi_idx.movie_id)
) AS mi_idx ,
name AS n ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
	AND pg_lip_bloom_probe(3, t.id)
) AS t
WHERE
 ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND mi.info IN ('Horror',
                  'Action',
                  'Sci-Fi',
                  'Thriller',
                  'Crime',
                  'War')
  AND n.gender = 'm'
  AND t.id = mi.movie_id
  AND t.id = mi_idx.movie_id
  AND t.id = ci.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id;

