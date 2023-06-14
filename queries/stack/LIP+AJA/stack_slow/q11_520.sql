SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
HashJoin(s t tq q)
NestLoop(s t tq)
NestLoop(s t)
IndexScan(tq)
IndexScan(q)
SeqScan(s)
SeqScan(t)
Leading((((s t) tq) q))
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
 AND (t.name in ('android','single-page-application')) 
 AND (q.view_count >= 100) 
 AND (q.view_count <= 100000) 
  
;