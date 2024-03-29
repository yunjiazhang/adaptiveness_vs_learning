SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(t1 s tq1 a1 u1 q1)
NestLoop(t1 s tq1 a1 u1)
NestLoop(t1 s tq1 a1)
NestLoop(t1 s tq1)
HashJoin(t1 s)
IndexScan(tq1)
IndexScan(a1)
IndexScan(u1)
IndexScan(q1)
SeqScan(t1)
SeqScan(s)
Leading((((((t1 s) tq1) a1) u1) q1))
*/
 SELECT t1.name, count(*) 
 
FROM 
site as s,
so_user as u1,
question as q1,
answer as a1,
tag as t1,
tag_question as tq1
WHERE 
 
 q1.owner_user_id = u1.id 
 AND a1.question_id = q1.id 
 AND a1.owner_user_id = u1.id 
 AND s.site_id = q1.site_id 
 AND s.site_id = a1.site_id 
 AND s.site_id = u1.site_id 
 AND s.site_id = tq1.site_id 
 AND s.site_id = t1.site_id 
 AND q1.id = tq1.question_id 
 AND t1.id = tq1.tag_id 
 AND (s.site_name in ('es','magento','salesforce','serverfault')) 
 AND (t1.name in ('apache-2.2','email','magento-2.1','networking','unit-test','windows')) 
 AND (q1.view_count >= 0) 
 AND (q1.view_count <= 100) 
 AND (u1.reputation >= 10) 
 AND (u1.reputation <= 100000) 
 GROUP BY t1.name 
;