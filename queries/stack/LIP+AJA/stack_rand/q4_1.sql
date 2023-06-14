SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(s1 t1 tq1 a1 q1 u1 account)
NestLoop(s1 t1 tq1 a1 q1 u1)
NestLoop(s1 t1 tq1 a1 q1)
NestLoop(s1 t1 tq1 a1)
NestLoop(s1 t1 tq1)
IndexScan(account)
NestLoop(s1 t1)
IndexScan(tq1)
IndexScan(a1)
IndexScan(q1)
IndexScan(u1)
SeqScan(s1)
SeqScan(t1)
Leading(((((((s1 t1) tq1) a1) q1) u1) account))
*/
  
 SELECT COUNT(distinct account.display_name) 
 
FROM 
tag t1,
site s1,
question q1,
answer a1,
tag_question tq1,
so_user u1,
account
WHERE 
 
 -- answerers posted at least 1 yr after the question was asked 
 s1.site_name='math' AND 
 t1.name = 'discrete-mathematics' AND 
 t1.site_id = s1.site_id AND 
 q1.site_id = s1.site_id AND 
 tq1.site_id = s1.site_id AND 
 tq1.question_id = q1.id AND 
 tq1.tag_id = t1.id AND 
 a1.site_id = q1.site_id AND 
 a1.question_id = q1.id AND 
 a1.owner_user_id = u1.id AND 
 a1.site_id = u1.site_id AND 
 a1.creation_date >= q1.creation_date + '1 year'::interval AND 
  
 -- to get the display name 
 account.id = u1.account_id; 
  
