SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
-- SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)');
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, it2.id)) FROM info_type AS it2 WHERE it2.info = 'votes';
SELECT sum(pg_lip_bloom_add(3, k.id)) FROM keyword AS k WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital');
SELECT sum(pg_lip_bloom_add(4, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War');
-- SELECT sum(pg_lip_bloom_add(5, n.id)) FROM name AS n WHERE n.gender = 'm';

/*+
NestLoop(ci mi_idx mk it2 mi it1 n t k)
NestLoop(ci mi_idx mk it2 mi it1 n t)
NestLoop(ci mi_idx mk it2 mi it1 n)
NestLoop(ci mi_idx mk it2 mi it1)
NestLoop(ci mi_idx mk it2 mi)
NestLoop(ci mi_idx mk it2)
NestLoop(ci mi_idx mk)
NestLoop(ci mi_idx)
SeqScan(ci)
IndexScan(mi_idx)
IndexScan(mk)
IndexScan(it2)
IndexScan(mi)
IndexScan(it1)
IndexScan(n)
IndexScan(t)
IndexScan(k)
Leading(((((((((ci mi_idx) mk) it2) mi) it1) n) t) k))*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS male_writer,
       MIN(t.title) AS violent_movie_title
 FROM 
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(4, ci.movie_id)
	-- AND pg_lip_bloom_probe(5, ci.person_id)
) AS ci ,
info_type AS it1 ,
info_type AS it2 ,
keyword AS k ,
(
	SELECT * FROM movie_info AS mi 
	--  WHERE pg_lip_bloom_probe(0, mi.movie_id)
	WHERE pg_lip_bloom_probe(1, mi.info_type_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	--  WHERE pg_lip_bloom_probe(0, mi_idx.movie_id)
	WHERE pg_lip_bloom_probe(2, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(4, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	--  WHERE pg_lip_bloom_probe(0, mk.movie_id)
	WHERE pg_lip_bloom_probe(3, mk.keyword_id)
	AND pg_lip_bloom_probe(4, mk.movie_id)
) AS mk ,
name AS n ,
(
	SELECT * FROM title AS t 
	--  WHERE pg_lip_bloom_probe(0, t.id)
	WHERE pg_lip_bloom_probe(4, t.id)
) AS t
WHERE
 ci.note IN ('(writer)',
                  '(head writer)',
                  '(written by)',
                  '(story)',
                  '(story editor)')
  AND it1.info = 'genres'
  AND it2.info = 'votes'
  AND k.keyword IN ('murder',
                    'violence',
                    'blood',
                    'gore',
                    'death',
                    'female-nudity',
                    'hospital')
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

