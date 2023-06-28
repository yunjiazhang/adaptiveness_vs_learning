SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(t1 s tq1 a1 b u1 q1 acc)
NestLoop(t1 s tq1 a1 b u1 q1)
NestLoop(t1 s tq1 a1 b u1)
NestLoop(t1 s tq1 a1 b)
NestLoop(t1 s tq1 a1)
NestLoop(t1 s tq1)
HashJoin(t1 s)
IndexScan(tq1)
IndexScan(acc)
IndexScan(a1)
IndexScan(u1)
IndexScan(q1)
IndexScan(b)
SeqScan(t1)
SeqScan(s)
Leading((((((((t1 s) tq1) a1) b) u1) q1) acc))
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
 AND (t1.name in ('absolute-value','boolean-algebra','computer-science','contour-integration','diophantine-equations','epsilon-delta','gcd-and-lcm','generating-functions','graphing-functions','ideals','lp-spaces','polar-coordinates')) 
 AND (q1.view_count >= 0) 
 AND (q1.view_count <= 100) 
 AND (u1.reputation >= 10) 
 AND (u1.reputation <= 100000) 
 AND (b.name in ('Autobiographer','Citizen Patrol','Critic','Custodian','Good Answer','Popular Question','Promoter')) 
 GROUP BY acc.location 
 ORDER BY COUNT(*) 
 DESC 
 LIMIT 100 
  
;