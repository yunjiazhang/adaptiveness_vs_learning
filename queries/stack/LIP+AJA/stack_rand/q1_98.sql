SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(site tag tag_question question)
NestLoop(site tag tag_question)
IndexScan(tag_question)
IndexScan(question)
NestLoop(site tag)
SeqScan(site)
SeqScan(tag)
Leading((((site tag) tag_question) question))
*/
  
 SELECT count(*) 
FROM 
tag,
site,
question,
tag_question
WHERE 
 
 site.site_name='pm' AND 
 tag.name='delays' AND 
 tag.site_id = site.site_id AND 
 question.site_id = site.site_id AND 
 tag_question.site_id = site.site_id AND 
 tag_question.question_id = question.id AND 
 tag_question.tag_id = tag.id 
  
;