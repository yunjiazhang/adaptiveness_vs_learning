SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(2);
-- SELECT sum(pg_lip_bloom_add(0, movie_id)) FROM movie_info AS mi WHERE mi.info IN ('Sweden',
--                   'Norway',
--                   'Germany',
--                   'Denmark',
--                   'Swedish',
--                   'Denish',
--                   'Norwegian',
--                   'German');
-- SELECT sum(pg_lip_bloom_add(1, id)) FROM keyword AS k WHERE k.keyword ='character-name-in-title';

/*+
NestLoop(mc ct t mi it)
NestLoop(mc ct t mi)
NestLoop(mc ct t)
NestLoop(mc ct)
IndexScan(mc)
Leading(((((ct mc) t) mi) it))
*/
SELECT MIN(t.title) AS typical_european_movie
FROM company_type AS ct,
     info_type AS it,
     (
        SELECT * FROM movie_companies AS mc
        -- where pg_lip_bloom_probe(0, movie_id)
      ) AS mc,
     movie_info AS mi,
     title AS t
WHERE ct.kind = 'production companies'
  AND mc.note LIKE '%(theatrical)%'
  AND mc.note LIKE '%(France)%'
  AND mi.info IN ('Sweden',
                  'Norway',
                  'Germany',
                  'Denmark',
                  'Swedish',
                  'Denish',
                  'Norwegian',
                  'German')
  AND t.production_year > 2005
  AND t.id = mi.movie_id
  AND t.id = mc.movie_id
  AND mc.movie_id = mi.movie_id
  AND ct.id = mc.company_type_id
  AND it.id = mi.info_type_id;

