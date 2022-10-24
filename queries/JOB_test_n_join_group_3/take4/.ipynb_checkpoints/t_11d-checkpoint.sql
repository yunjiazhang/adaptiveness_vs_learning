/*+ NestLoop(t k ml lt mk mc cn ct)
 NestLoop(t k ml lt mk mc cn)
 HashJoin(t k ml lt mk mc)
 NestLoop(k ml lt mk mc)
 HashJoin(k ml lt mk)
 NestLoop(ml lt mk)
 HashJoin(ml lt)
 IndexScan(t)
 IndexScan(k)
 IndexScan(ml)
 SeqScan(lt)
 IndexScan(mk)
 IndexScan(mc)
 IndexScan(cn)
 IndexScan(ct)
 Leading((((t ((k ((ml lt) mk)) mc)) cn) ct)) */
SELECT MIN(cn.name) AS from_company,
       MIN(mc.note) AS production_note,
       MIN(t.title) AS movie_based_on_book
FROM company_name AS cn,
     company_type AS ct,
     keyword AS k,
     link_type AS lt,
     movie_companies AS mc,
     movie_keyword AS mk,
     movie_link AS ml,
     title AS t
WHERE cn.country_code !='[pl]'
  AND ct.kind != 'production companies'
  AND ct.kind IS NOT NULL
  AND k.keyword IN ('sequel',
                    'revenge',
                    'based-on-novel')
  AND mc.note IS NOT NULL
  AND t.production_year > 1950
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

