/*+ MergeJoin(t mi cn ct ml lt k mk mc)
 MergeJoin(mi cn ct ml lt k mk mc)
 MergeJoin(cn ct ml lt k mk mc)
 NestLoop(ct ml lt k mk mc)
 NestLoop(ml lt k mk mc)
 HashJoin(ml lt k mk)
 NestLoop(k mk)
 NestLoop(ml lt)
 SeqScan(t)
 SeqScan(mi)
 SeqScan(cn)
 SeqScan(ct)
 SeqScan(ml)
 IndexScan(lt)
 IndexScan(k)
 IndexScan(mk)
 IndexScan(mc)
 Leading((t (mi (cn (ct (((ml lt) (k mk)) mc)))))) */
SELECT MIN(cn.name) AS company_name,
       MIN(lt.link) AS link_type,
       MIN(t.title) AS western_follow_up
FROM company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     movie_companies AS mc,
     movie_info AS mi,
     movie_keyword AS mk,
     movie_link AS ml,
     title AS t
WHERE cn.country_code !='[pl]'
  AND (cn.name LIKE '%Film%'
       OR cn.name LIKE '%Warner%')
  AND ct.kind ='production companies'
  AND k.keyword ='sequel'
  AND lt.link LIKE '%follow%'
  AND mc.note IS NULL
  AND mi.info IN ('Sweden',
                  'Norway',
                  'Germany',
                  'Denmark',
                  'Swedish',
                  'Denish',
                  'Norwegian',
                  'German')
  AND t.production_year BETWEEN 1950 AND 2000
  AND lt.id = ml.link_type_id
  AND ml.movie_id = t.id
  AND t.id = mk.movie_id
  AND mk.keyword_id = k.id
  AND t.id = mc.movie_id
  AND mc.company_type_id = ct.id
  AND mc.company_id = cn.id
  AND mi.movie_id = t.id
  AND ml.movie_id = mk.movie_id
  AND ml.movie_id = mc.movie_id
  AND mk.movie_id = mc.movie_id
  AND ml.movie_id = mi.movie_id
  AND mk.movie_id = mi.movie_id
  AND mc.movie_id = mi.movie_id;
