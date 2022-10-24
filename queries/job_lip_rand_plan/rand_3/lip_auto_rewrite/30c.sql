SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(8);
SELECT sum(pg_lip_bloom_add(0, cct1.id)) FROM comp_cast_type AS cct1 WHERE cct1.kind = 'cast';
SELECT sum(pg_lip_bloom_add(1, cct2.id)) FROM comp_cast_type AS cct2 WHERE cct2.kind ='complete+verified';
SELECT sum(pg_lip_bloom_add(2, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(writer)', '(head writer)', '(written by)', '(story)', '(story editor)');
SELECT sum(pg_lip_bloom_add(3, it1.id)) FROM info_type AS it1 WHERE it1.info = 'genres';
SELECT sum(pg_lip_bloom_add(4, it2.id)) FROM info_type AS it2 WHERE it2.info = 'votes';
SELECT sum(pg_lip_bloom_add(5, k.id)) FROM keyword AS k WHERE k.keyword IN ('murder', 'violence', 'blood', 'gore', 'death', 'female-nudity', 'hospital');
SELECT sum(pg_lip_bloom_add(6, mi.movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Horror', 'Action', 'Sci-Fi', 'Thriller', 'Crime', 'War');
SELECT sum(pg_lip_bloom_add(7, n.id)) FROM name AS n WHERE n.gender = 'm';

/*+
HashJoin(mi t mi_idx cc it2 ci mk it1 cct1 cct2 n k)
HashJoin(mi t mi_idx cc it2 ci mk it1 cct1 cct2 n)
HashJoin(mi t mi_idx cc it2 ci mk it1 cct1 cct2)
HashJoin(mi t mi_idx cc it2 ci mk it1 cct1)
HashJoin(mi t mi_idx cc it2 ci mk it1)
HashJoin(mi t mi_idx cc it2 ci mk)
HashJoin(mi t mi_idx cc it2 ci)
HashJoin(mi t mi_idx cc it2)
HashJoin(mi t mi_idx cc)
HashJoin(mi t mi_idx)
HashJoin(mi t)
SeqScan(mi)
SeqScan(t)
SeqScan(mi_idx)
SeqScan(cc)
SeqScan(it2)
SeqScan(ci)
SeqScan(mk)
SeqScan(it1)
SeqScan(cct1)
SeqScan(cct2)
SeqScan(n)
SeqScan(k)
Leading((((((((((((mi t) mi_idx) cc) it2) ci) mk) it1) cct1) cct2) n) k))*/
SELECT MIN(mi.info) AS movie_budget,
       MIN(mi_idx.info) AS movie_votes,
       MIN(n.name) AS writer,
       MIN(t.title) AS complete_violent_movie
 FROM 
(
	SELECT * FROM complete_cast AS cc 
	 WHERE pg_lip_bloom_probe(0, cc.subject_id)
	AND pg_lip_bloom_probe(1, cc.status_id)
	AND pg_lip_bloom_probe(2, cc.movie_id)
	AND pg_lip_bloom_probe(6, cc.movie_id)
) AS cc ,
comp_cast_type AS cct1 ,
comp_cast_type AS cct2 ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(6, ci.movie_id)
	AND pg_lip_bloom_probe(7, ci.person_id)
) AS ci ,
info_type AS it1 ,
info_type AS it2 ,
keyword AS k ,
(
	SELECT * FROM movie_info AS mi 
	 WHERE pg_lip_bloom_probe(2, mi.movie_id)
	AND pg_lip_bloom_probe(3, mi.info_type_id)
) AS mi ,
(
	SELECT * FROM movie_info_idx AS mi_idx 
	 WHERE pg_lip_bloom_probe(2, mi_idx.movie_id)
	AND pg_lip_bloom_probe(4, mi_idx.info_type_id)
	AND pg_lip_bloom_probe(6, mi_idx.movie_id)
) AS mi_idx ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(2, mk.movie_id)
	AND pg_lip_bloom_probe(5, mk.keyword_id)
	AND pg_lip_bloom_probe(6, mk.movie_id)
) AS mk ,
name AS n ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(2, t.id)
	AND pg_lip_bloom_probe(6, t.id)
) AS t
WHERE
 cct1.kind = 'cast'
  AND cct2.kind ='complete+verified'
  AND ci.note IN ('(writer)',
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
  AND t.id = cc.movie_id
  AND ci.movie_id = mi.movie_id
  AND ci.movie_id = mi_idx.movie_id
  AND ci.movie_id = mk.movie_id
  AND ci.movie_id = cc.movie_id
  AND mi.movie_id = mi_idx.movie_id
  AND mi.movie_id = mk.movie_id
  AND mi.movie_id = cc.movie_id
  AND mi_idx.movie_id = mk.movie_id
  AND mi_idx.movie_id = cc.movie_id
  AND mk.movie_id = cc.movie_id
  AND n.id = ci.person_id
  AND it1.id = mi.info_type_id
  AND it2.id = mi_idx.info_type_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id;

