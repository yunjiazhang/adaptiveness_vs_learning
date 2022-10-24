/*+ HashJoin(mk k t kt cc cct2 cct1 ci n chn)
 MergeJoin(mk k t kt cc cct2 cct1 ci n)
 HashJoin(mk k t kt cc cct2 cct1 ci)
 HashJoin(mk k t kt cc cct2 cct1)
 HashJoin(mk k t kt cc cct2)
 HashJoin(mk k t kt cc)
 HashJoin(mk k t kt)
 NestLoop(mk k t)
 HashJoin(mk k)
 SeqScan(mk)
 IndexScan(k)
 IndexScan(t)
 SeqScan(kt)
 IndexScan(cc)
 IndexScan(cct2)
 SeqScan(cct1)
 SeqScan(ci)
 IndexScan(n)
 SeqScan(chn)
 Leading((((((((((mk k) t) kt) cc) cct2) cct1) ci) n) chn)) */
SELECT MIN(t.title) AS complete_downey_ironman_movie
FROM complete_cast AS cc,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2,
     char_name AS chn,
     cast_info AS ci,
     keyword AS k,
     kind_type AS kt,
     movie_keyword AS mk,
     name AS n,
     title AS t
WHERE cct1.kind = 'cast'
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

