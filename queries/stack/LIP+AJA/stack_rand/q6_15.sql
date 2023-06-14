SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(t1 s1 tq1 q1 u1 c1 account)
NestLoop(t1 s1 tq1 q1 u1 c1)
NestLoop(t1 s1 tq1 q1 u1)
NestLoop(t1 s1 tq1 q1)
NestLoop(t1 s1 tq1)
IndexScan(account)
HashJoin(t1 s1)
IndexScan(tq1)
IndexScan(q1)
IndexScan(u1)
IndexScan(c1)
SeqScan(t1)
SeqScan(s1)
Leading(((((((t1 s1) tq1) q1) u1) c1) account))
*/
  
 SELECT COUNT(distinct account.display_name) 
 
FROM 
tag t1,
site s1,
question q1,
tag_question tq1,
so_user u1,
comment c1,
account
WHERE 
 
 -- underappreciated (high votes, low views) questions with at least one comment 
 s1.site_name='avp' AND 
 t1.name in ('adjustment-layers', 'video-capture', 'hevc', 'video') AND 
 t1.site_id = s1.site_id AND 
 q1.site_id = s1.site_id AND 
 tq1.site_id = s1.site_id AND 
 tq1.question_id = q1.id AND 
 tq1.tag_id = t1.id AND 
 q1.owner_user_id = u1.id AND 
 q1.site_id = u1.site_id AND 
 c1.site_id = q1.site_id AND 
 c1.post_id = q1.id AND 
 c1.score > q1.score AND 
  
 -- to get the display name 
 account.id = u1.account_id; 
  
  
