/*+ MergeJoin(ct mi miidx it t kt it2 cn mc)
 HashJoin(mi miidx it t kt it2 cn mc)
 NestLoop(cn mc)
 HashJoin(mi miidx it t kt it2)
 HashJoin(mi miidx it t kt)
 HashJoin(mi miidx it t)
 HashJoin(mi miidx it)
 NestLoop(miidx it)
 IndexScan(ct)
 SeqScan(mi)
 IndexScan(miidx)
 IndexScan(it)
 SeqScan(t)
 SeqScan(kt)
 IndexScan(it2)
 SeqScan(cn)
 IndexScan(mc)
 Leading((ct (((((mi (miidx it)) t) kt) it2) (cn mc)))) */
SELECT MIN(mi.info) AS release_date,
       MIN(miidx.info) AS rating,
       MIN(t.title) AS german_movie
FROM company_name AS cn,
     company_type AS ct,
     info_type AS it,
     info_type AS it2,
     kind_type AS kt,
     movie_companies AS mc,
     movie_info AS mi,
     movie_info_idx AS miidx,
     title AS t
WHERE cn.country_code ='[de]'
  AND ct.kind ='production companies'
  AND it.info ='rating'
  AND it2.info ='release dates'
  AND kt.kind ='movie'
  AND mi.movie_id = t.id
  AND it2.id = mi.info_type_id
  AND kt.id = t.kind_id
  AND mc.movie_id = t.id
  AND cn.id = mc.company_id
  AND ct.id = mc.company_type_id
  AND miidx.movie_id = t.id
  AND it.id = miidx.info_type_id
  AND mi.movie_id = miidx.movie_id
  AND mi.movie_id = mc.movie_id
  AND miidx.movie_id = mc.movie_id;

