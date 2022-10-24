SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
SELECT sum(pg_lip_bloom_add(0, cct1.id)) FROM comp_cast_type AS cct1 WHERE cct1.kind = 'cast';
SELECT sum(pg_lip_bloom_add(1, cct2.id)) FROM comp_cast_type AS cct2 WHERE cct2.kind LIKE '%complete%';
SELECT sum(pg_lip_bloom_add(2, chn.id)) FROM char_name AS chn WHERE chn.name NOT LIKE '%Sherlock%' AND (chn.name LIKE '%Tony%Stark%' OR chn.name LIKE '%Iron%Man%');
SELECT sum(pg_lip_bloom_add(3, k.id)) FROM keyword AS k WHERE k.keyword IN ('superhero', 'sequel', 'second-part', 'marvel-comics', 'based-on-comic', 'tv-special', 'fight', 'violence');
SELECT sum(pg_lip_bloom_add(4, kt.id)) FROM kind_type AS kt WHERE kt.kind = 'movie';
SELECT sum(pg_lip_bloom_add(5, t.id)) FROM title AS t WHERE t.production_year > 1950;

/*+
HashJoin(ci t kt n mk chn k cc cct2 cct1)
HashJoin(ci t kt n mk chn k cc cct2)
HashJoin(ci t kt n mk chn k cc)
HashJoin(ci t kt n mk chn k)
HashJoin(ci t kt n mk chn)
HashJoin(ci t kt n mk)
HashJoin(ci t kt n)
HashJoin(ci t kt)
HashJoin(ci t)
SeqScan(ci)
SeqScan(t)
SeqScan(kt)
SeqScan(n)
SeqScan(mk)
SeqScan(chn)
SeqScan(k)
SeqScan(cc)
SeqScan(cct2)
SeqScan(cct1)
Leading((((((((((ci t) kt) n) mk) chn) k) cc) cct2) cct1))*/
SELECT MIN(t.title) AS complete_downey_ironman_movie
 FROM 
(
	SELECT * FROM complete_cast AS cc 
	 WHERE pg_lip_bloom_probe(0, cc.subject_id)
	AND pg_lip_bloom_probe(1, cc.status_id)
	AND pg_lip_bloom_probe(5, cc.movie_id)
) AS cc ,
comp_cast_type AS cct1 ,
comp_cast_type AS cct2 ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.person_role_id)
	AND pg_lip_bloom_probe(5, ci.movie_id)
) AS ci ,
keyword AS k ,
kind_type AS kt ,
(
	SELECT * FROM movie_keyword AS mk 
	 WHERE pg_lip_bloom_probe(3, mk.keyword_id)
	AND pg_lip_bloom_probe(5, mk.movie_id)
) AS mk ,
name AS n ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(4, t.kind_id)
) AS t
WHERE
 cct1.kind = 'cast'
  AND cct2.kind LIKE '%complete%'
  AND chn.name NOT LIKE '%Sherlock%'
  AND (chn.name LIKE '%Tony%Stark%'
       OR chn.name LIKE '%Iron%Man%')
  AND k.keyword IN ('superhero',
                    'sequel',
                    'second-part',
                    'marvel-comics',
                    'based-on-comic',
                    'tv-special',
                    'fight',
                    'violence')
  AND kt.kind = 'movie'
  AND t.production_year > 1950
  AND kt.id = t.kind_id
  AND t.id = mk.movie_id
  AND t.id = ci.movie_id
  AND t.id = cc.movie_id
  AND mk.movie_id = ci.movie_id
  AND mk.movie_id = cc.movie_id
  AND ci.movie_id = cc.movie_id
  AND chn.id = ci.person_role_id
  AND n.id = ci.person_id
  AND k.id = mk.keyword_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id;

