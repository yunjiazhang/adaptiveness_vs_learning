SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(tag site tq1 pl c1 q1 tq2 c2 q2)
NestLoop(tag site tq1 pl c1 q1 tq2 c2)
NestLoop(tag site tq1 pl c1 q1 tq2)
NestLoop(tag site tq1 pl c1 q1)
NestLoop(tag site tq1 pl c1)
NestLoop(tag site tq1 pl)
NestLoop(tag site tq1)
HashJoin(tag site)
IndexScan(tq1)
IndexScan(tq2)
SeqScan(site)
IndexScan(c1)
IndexScan(q1)
IndexScan(c2)
IndexScan(q2)
SeqScan(tag)
SeqScan(pl)
Leading(((((((((tag site) tq1) pl) c1) q1) tq2) c2) q2))
*/
  
 SELECT count(distinct q1.id) 
FROM 
site,
post_link pl,
question q1,
question q2,
comment c1,
comment c2,
tag,
tag_question tq1,
tag_question tq2
WHERE 
 
 site.site_name = 'german' AND 
 pl.site_id = site.site_id AND 
  
 pl.site_id = q1.site_id AND 
 pl.post_id_from = q1.id AND 
 pl.site_id = q2.site_id AND 
 pl.post_id_to = q2.id AND 
  
 c1.site_id = q1.site_id AND 
 c1.post_id = q1.id AND 
  
 c2.site_id = q2.site_id AND 
 c2.post_id = q2.id AND 
  
 c1.date < c2.date AND 
  
 tag.name in ('sql-server', 'php', 'html', 'css', 'angularjs') AND 
 tag.id = tq1.tag_id AND 
 tag.site_id = tq1.site_id AND 
 tag.id = tq2.tag_id AND 
 tag.site_id = tq1.site_id AND 
  
 tag.site_id = pl.site_id AND 
  
 tq1.site_id = q1.site_id AND 
 tq1.question_id = q1.id AND 
 tq2.site_id = q2.site_id AND 
 tq2.question_id = q2.id; 
  
  
