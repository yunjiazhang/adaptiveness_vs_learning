SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(t s tq q)
NestLoop(t s tq)
HashJoin(t s)
IndexScan(tq)
IndexScan(q)
SeqScan(t)
SeqScan(s)
Leading((((t s) tq) q))
*/
 SELECT COUNT(*) 
 
FROM 
tag as t,
site as s,
question as q,
tag_question as tq
WHERE 
 
 t.site_id = s.site_id 
 AND q.site_id = s.site_id 
 AND tq.site_id = s.site_id 
 AND tq.question_id = q.id 
 AND tq.tag_id = t.id 
 AND (s.site_name in ('stackoverflow')) 
 AND (t.name in ('arraylist','canvas','ggplot2','inno-setup','knockout.js','layout','linked-list','mobile','nlp','pandas','post','process','tsql')) 
 AND (q.favorite_count >= 0) 
 AND (q.favorite_count <= 1) 
  
;