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
 SELECT COUNT(*) 
 
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
 AND (s.site_name in ('chemistry')) 
 AND (t1.name in ('organic-chemistry','physical-chemistry')) 
 AND (q1.favorite_count >= 0) 
 AND (q1.favorite_count <= 10000) 
 AND (u1.reputation >= 10) 
 AND (u1.reputation <= 100000) 
 AND (b.name in ('Citizen Patrol','Curious','Nice Question','Revival')) 
  
;