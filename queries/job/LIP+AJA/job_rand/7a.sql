SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, person_id)) FROM person_info AS pi WHERE pi.note ='Volker Boehm';
SELECT sum(pg_lip_bloom_add(1, id)) FROM info_type AS it WHERE it.info ='mini biography';

/*+
NestLoop(lt ml t ci n pi an it)
NestLoop(lt ml t ci n pi an)
NestLoop(lt ml t ci n pi)
NestLoop(lt ml t ci n)
NestLoop(lt ml t ci)
NestLoop(lt ml t)
NestLoop(lt ml)
IndexScan(ml)
Leading((((((((lt ml) t) ci) n) pi) an) it))
*/
SELECT MIN(n.name) AS of_person,
       MIN(t.title) AS biography_movie
FROM aka_name AS an,
     (
        select * from cast_info as ci
        where pg_lip_bloom_probe(0, person_id) 
      ) AS ci,
     info_type AS it,
     link_type AS lt,
     movie_link AS ml,
     name AS n,
     (
        select  * from person_info as pi
        where pg_lip_bloom_probe(1, info_type_id)
      ) AS pi,
     title AS t
WHERE an.name LIKE '%a%'
  AND it.info ='mini biography'
  AND lt.link ='features'
  AND n.name_pcode_cf BETWEEN 'A' AND 'F'
  AND (n.gender='m'
       OR (n.gender = 'f'
           AND n.name LIKE 'B%'))
  AND pi.note ='Volker Boehm'
  AND t.production_year BETWEEN 1980 AND 1995
  AND n.id = an.person_id
  AND n.id = pi.person_id
  AND ci.person_id = n.id
  AND t.id = ci.movie_id
  AND ml.linked_movie_id = t.id
  AND lt.id = ml.link_type_id
  AND it.id = pi.info_type_id
  AND pi.person_id = an.person_id
  AND pi.person_id = ci.person_id
  AND an.person_id = ci.person_id
  AND ci.movie_id = ml.linked_movie_id;