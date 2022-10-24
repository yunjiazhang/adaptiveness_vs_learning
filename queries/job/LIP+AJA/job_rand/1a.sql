SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, id)) FROM company_type AS ct WHERE ct.kind = 'production companies';
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';

/*+
NestLoop(it mi_idx mc ct t) 
NestLoop(it mi_idx mc ct) 
NestLoop(it mi_idx mc) 
NestLoop(it mi_idx)
IndexScan(mi_idx)
Leading(((((it mi_idx) mc) ct) t))
*/
SELECT MIN(mc.note) AS production_note,
       MIN(t.title) AS movie_title,
       MIN(t.production_year) AS movie_year
FROM company_type AS ct,
     info_type AS it,
     (
        select * from movie_companies as mc
     --    where pg_lip_bloom_probe(0, company_type_id)
      ) AS mc,
     movie_info_idx AS mi_idx,
     title AS t
WHERE ct.kind = 'production companies'
  AND it.info = 'top 250 rank'
  AND mc.note NOT LIKE '%(as Metro-Goldwyn-Mayer Pictures)%'
  AND (mc.note LIKE '%(co-production)%'
       OR mc.note LIKE '%(presents)%')
  AND ct.id = mc.company_type_id
  AND t.id = mc.movie_id
  AND t.id = mi_idx.movie_id
  AND mc.movie_id = mi_idx.movie_id
  AND it.id = mi_idx.info_type_id;