SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)');
SELECT sum(pg_lip_bloom_add(1, it1.id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(2, it2.id)) FROM info_type AS it2 WHERE it2.info = 'votes';
-- SELECT sum(pg_lip_bloom_add(3, k.id)) FROM keyword AS k WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital');
SELECT sum(pg_lip_bloom_add(4, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War');
-- SELECT sum(pg_lip_bloom_add(5, n.id)) FROM name AS n WHERE n.gender = 'm';

/*+
HashJoin(mk ci n mi t mi_idx it1 it2 k)
HashJoin(mk ci n mi t mi_idx it1 it2)
HashJoin(mk ci n mi t mi_idx it1)
HashJoin(mk ci n mi t mi_idx)
HashJoin(mk ci n mi t)
HashJoin(mk ci n mi)
HashJoin(mk ci n)
HashJoin(mk ci)
SeqScan(mk)
SeqScan(ci)
SeqScan(n)
SeqScan(mi)
SeqScan(t)
SeqScan(mi_idx)
SeqScan(it1)
SeqScan(it2)
SeqScan(k)
Leading(((((((((mk ci) n) mi) t) mi_idx) it1) it2) k))*/
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
	 WHERE pg_lip_bloom_probe(0, mi.movie_id)
	AND pg_lip_bloom_probe(1, mi.info_type_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(0, mi_idx.movie_id)
	AND pg_lip_bloom_probe(2, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(4, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(0, mk.movie_id)
	-- AND pg_lip_bloom_probe(3, mk.keyword_id)
	AND pg_lip_bloom_probe(4, mk.movie_id)
) AS mk ,
name AS n ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
	AND pg_lip_bloom_probe(4, t.id)
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

