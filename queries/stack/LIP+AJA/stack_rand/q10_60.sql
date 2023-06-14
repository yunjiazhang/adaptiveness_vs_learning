SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(site pl1 pl2 q1 q3 q2 comment comment_1 comment_2)
NestLoop(site pl1 pl2 q1 q3 q2 comment comment_1)
NestLoop(site pl1 pl2 q1 q3 q2 comment)
NestLoop(site pl1 pl2 q1 q3 q2)
NestLoop(site pl1 pl2 q1 q3)
NestLoop(site pl1 pl2 q1)
HashJoin(site pl1 pl2)
IndexScan(comment_1)
IndexScan(comment_2)
NestLoop(site pl1)
IndexScan(comment)
SeqScan(site)
IndexScan(q1)
IndexScan(q3)
IndexScan(q2)
SeqScan(pl1)
SeqScan(pl2)
Leading(((((((((site pl1) pl2) q1) q3) q2) comment) comment_1) comment_2))
*/
  
 SELECT count(distinct q1.id) 
FROM 
site,
post_link pl1,
post_link pl2,
question q1,
question q2,
question q3
WHERE 
 
  
 site.site_name = 'ukrainian' AND 
 q1.site_id = site.site_id AND 
 q1.site_id = q2.site_id AND 
 q2.site_id = q3.site_id AND 
  
 pl1.site_id = q1.site_id AND 
 pl1.post_id_from = q1.id AND 
 pl1.post_id_to = q2.id AND 
  
 pl2.site_id = q1.site_id AND 
 pl2.post_id_from = q2.id AND 
 pl2.post_id_to = q3.id AND 
  
 exists ( SELECT * FROM comment  WHERE  comment.site_id = q3.site_id AND comment.post_id = q3.id ) AND 
 exists ( SELECT * FROM comment  WHERE  comment.site_id = q2.site_id AND comment.post_id = q2.id ) AND 
 exists ( SELECT * FROM comment  WHERE  comment.site_id = q1.site_id AND comment.post_id = q1.id ) AND 
  
 q1.score > q3.score; 
  
