SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(s t1 tq1 a1 u1 q1 b acc)
NestLoop(s t1 tq1 a1 u1 q1 b)
NestLoop(s t1 tq1 a1 u1 q1)
NestLoop(s t1 tq1 a1 u1)
NestLoop(s t1 tq1 a1)
NestLoop(s t1 tq1)
NestLoop(s t1)
IndexScan(tq1)
IndexScan(acc)
IndexScan(a1)
IndexScan(u1)
IndexScan(q1)
IndexScan(b)
SeqScan(t1)
SeqScan(s)
Leading((((((((s t1) tq1) a1) u1) q1) b) acc))
*/
 SELECT acc.location, count(*) 
 
FROM 
site as s,
so_user as u1,
question as q1,
answer as a1,
tag as t1,
tag_question as tq1,
badge as b,
account as acc
WHERE 
 
 s.site_id = q1.site_id 
 AND s.site_id = u1.site_id 
 AND s.site_id = a1.site_id 
 AND s.site_id = t1.site_id 
 AND s.site_id = tq1.site_id 
 AND s.site_id = b.site_id 
 AND q1.id = tq1.question_id 
 AND q1.id = a1.question_id 
 AND a1.owner_user_id = u1.id 
 AND t1.id = tq1.tag_id 
 AND b.user_id = u1.id 
 AND acc.id = u1.account_id 
 AND (s.site_name in ('math')) 
 AND (t1.name in ('linear-algebra','reference-request')) 
 AND (q1.favorite_count >= 5) 
 AND (q1.favorite_count <= 5000) 
 AND (u1.downvotes >= 0) 
 AND (u1.downvotes <= 10) 
 AND (b.name in ('Analytical','Benefactor','Excavator','Explainer','Favorite Question','Investor','Necromancer','Vox Populi')) 
 GROUP BY acc.location 
 ORDER BY COUNT(*) 
 DESC 
 LIMIT 100 
  
;