/*+ MergeJoin(lt ml t mc cn ct mk k)
 NestLoop(lt ml t mc cn ct mk)
 NestLoop(lt ml t mc cn ct)
 NestLoop(lt ml t mc cn)
 NestLoop(lt ml t mc)
 NestLoop(lt ml t)
 NestLoop(lt ml)
 IndexScan(lt)
 IndexScan(ml)
 IndexScan(t)
 IndexScan(mc)
 IndexScan(cn)
 IndexScan(ct)
 IndexScan(mk)
 SeqScan(k)
 Leading((((((((lt ml) t) mc) cn) ct) mk) k)) */
SELECT MIN(cn.name) AS from_company,
       MIN(lt.link) AS movie_link_type,
       MIN(t.title) AS sequel_movie
FROM company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     movie_companies AS mc,
     movie_keyword AS mk,
     movie_link AS ml,
     title AS t
WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind ='production companies'
  AND k.keyword ='sequel'
  AND lt.link LIKE '%follows%'
  AND mc.note IS NULL
  AND t.production_year = 1998
  AND t.title LIKE '%Money%'
  AND lt.id = ml.link_type_id
  AND ml.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_type_id = ct.id
  AND mc.company_id = cn.id
  AND ml.movie_id = mk.movie_id
  AND ml.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id;

