SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
HashJoin(t s tq q)
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
 AND (t.name in ('algorithm','c#','c++11','date','function','html','math','node.js','svn','tsql','unicode','unit-testing')) 
 AND (q.score >= 10) 
 AND (q.score <= 1000) 
  
;