SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(6);
SELECT sum(pg_lip_bloom_add(0, id)) FROM comp_cast_type AS cct1 WHERE cct1.kind IN ('cast',
                    'crew');
SELECT sum(pg_lip_bloom_add(1, id)) FROM comp_cast_type AS cct2 WHERE cct2.kind = 'complete';
SELECT sum(pg_lip_bloom_add(2, id)) FROM company_name as cn WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%');
SELECT sum(pg_lip_bloom_add(3, id)) FROM company_type AS ct WHERE ct.kind ='production companies';
SELECT sum(pg_lip_bloom_add(4, id)) FROM keyword AS k WHERE k.keyword ='sequel';
-- SELECT sum(pg_lip_bloom_add(5, id)) FROM link_type AS lt WHERE lt.link LIKE '%follow%';

/*+
NestLoop(lt ml cc cct2 cct1 mc ct cn t mi mk k)
NestLoop(lt ml cc cct2 cct1 mc ct cn t mi mk)
NestLoop(lt ml cc cct2 cct1 mc ct cn t mi)
NestLoop(lt ml cc cct2 cct1 mc ct cn t)
NestLoop(lt ml cc cct2 cct1 mc ct cn)
NestLoop(lt ml cc cct2 cct1 mc ct)
NestLoop(lt ml cc cct2 cct1 mc)
HashJoin(lt ml cc cct2 cct1)
HashJoin(lt ml cc cct2)
NestLoop(lt ml cc)
NestLoop(lt ml)
IndexScan(ml)
IndexScan(cc)
Leading((((((((((cct2 ((lt ml) cc)) cct1) mc) ct) cn) t) mi) mk) k)) 
*/
SELECT MIN(cn.name) AS producing_company,
       MIN(lt.link) AS link_type,
       MIN(t.title) AS complete_western_sequel
FROM (
          select * from complete_cast as cc
          where pg_lip_bloom_probe(0, subject_id) AND pg_lip_bloom_probe(1, status_id)
     ) AS cc,
     comp_cast_type AS cct1,
     comp_cast_type AS cct2,
     company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     (
          select * from movie_companies as mc
          where pg_lip_bloom_probe(2, company_id) AND pg_lip_bloom_probe(3, company_type_id)
     ) AS mc,
     movie_info AS mi,
     (
          select  * from movie_keyword as mk
          where pg_lip_bloom_probe(4, keyword_id)
     ) AS mk,
     movie_link AS ml,
     title AS t
WHERE cct1.kind IN ('cast',
                    'crew')
  AND cct2.kind = 'complete'
  AND cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind ='production companies'
  AND k.keyword ='sequel'
  AND lt.link LIKE '%follow%'
  AND mc.note IS NULL
  AND mi.info IN ('Sweden',
                  'Germany',
                  'Swedish',
                  'German')
  AND t.production_year = 1998
  AND lt.id = ml.link_type_id
  AND ml.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_type_id = ct.id
  AND mc.company_id = cn.id
  AND mi.movie_id = t.id
  AND t.id = cc.movie_id
  AND cct1.id = cc.subject_id
  AND cct2.id = cc.status_id
  AND ml.movie_id = mk.movie_id
  AND ml.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id
  AND ml.movie_id = mi.movie_id
  AND mk.movie_id = mi.movie_id
  AND mc.movie_id = mi.movie_id
  AND ml.movie_id = cc.movie_id
  AND mk.movie_id = cc.movie_id
  AND mc.movie_id = cc.movie_id
  AND mi.movie_id = cc.movie_id;

