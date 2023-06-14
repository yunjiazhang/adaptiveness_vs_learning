SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(s1 t1 tq1 q1 u1 c1 account)
NestLoop(s1 t1 tq1 q1 u1 c1)
NestLoop(s1 t1 tq1 q1 u1)
NestLoop(s1 t1 tq1 q1)
NestLoop(s1 t1 tq1)
IndexScan(account)
NestLoop(s1 t1)
IndexScan(tq1)
IndexScan(s1)
IndexScan(q1)
IndexScan(u1)
IndexScan(c1)
SeqScan(t1)
Leading(((((((s1 t1) tq1) q1) u1) c1) account))
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
 s1.site_name='rpg' AND 
 t1.name in ('minds-eye-theatre', 'fudging', 'unknown-armies', 'pokemon-tabletop-united') AND 
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
  
  
