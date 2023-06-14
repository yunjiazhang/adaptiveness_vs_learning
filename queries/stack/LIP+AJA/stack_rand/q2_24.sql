SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(t1 s1 tq1 q1 u1 t2 s2 tq2 q2 u2 account)
HashJoin(t1 s1 tq1 q1 u1 t2 s2 tq2 q2 u2)
NestLoop(t1 s1 tq1 q1 u1)
NestLoop(t2 s2 tq2 q2 u2)
NestLoop(t1 s1 tq1 q1)
NestLoop(t2 s2 tq2 q2)
NestLoop(t1 s1 tq1)
NestLoop(t2 s2 tq2)
IndexScan(account)
HashJoin(t1 s1)
HashJoin(t2 s2)
IndexScan(tq1)
IndexScan(tq2)
IndexScan(q1)
IndexScan(u1)
IndexScan(q2)
IndexScan(u2)
SeqScan(t1)
SeqScan(s1)
SeqScan(t2)
SeqScan(s2)
Leading(((((((t1 s1) tq1) q1) u1) ((((t2 s2) tq2) q2) u2)) account))
*/
  
 SELECT distinct account.display_name 
 
FROM 
tag t1,
site s1,
question q1,
tag_question tq1,
so_user u1,
tag t2,
site s2,
question q2,
tag_question tq2,
so_user u2,
account
WHERE 
 
 -- group theory askers 
 s1.site_name='stackoverflow' AND 
 t1.name  = 'xamarin.android' AND 
 t1.site_id = s1.site_id AND 
 q1.site_id = s1.site_id AND 
 tq1.site_id = s1.site_id AND 
 tq1.question_id = q1.id AND 
 tq1.tag_id = t1.id AND 
 q1.owner_user_id = u1.id AND 
 q1.site_id = u1.site_id AND 
  
 -- D&D askers 
 s2.site_name='math' AND 
 t2.name  = 'stochastic-processes' AND 
 t2.site_id = s2.site_id AND 
 q2.site_id = s2.site_id AND 
 tq2.site_id = s2.site_id AND 
 tq2.question_id = q2.id AND 
 tq2.tag_id = t2.id AND 
 q2.owner_user_id = u2.id AND 
 q2.site_id = u2.site_id AND 
  
 -- intersect 
 u1.account_id = u2.account_id AND 
 account.id = u1.account_id; 
  
  
