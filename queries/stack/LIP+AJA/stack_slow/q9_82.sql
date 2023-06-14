SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(site tag tq q so_user account pl a)
HashJoin(site tag tq q so_user account pl)
NestLoop(site tag tq q so_user account)
NestLoop(site tag tq q so_user)
NestLoop(site tag tq q)
NestLoop(site tag tq)
NestLoop(site tag)
IndexScan(so_user)
IndexScan(account)
SeqScan(site)
IndexScan(tq)
SeqScan(tag)
IndexScan(q)
IndexScan(a)
SeqScan(pl)
Leading((((((((site tag) tq) q) so_user) account) pl) a))
*/
  
 SELECT count(distinct account.id) 
FROM 
account,
site,
so_user,
question q,
post_link pl,
tag,
tag_question tq
WHERE 
 
 not exists (select * FROM answer a  WHERE  a.site_id = q.site_id AND a.question_id = q.id) AND 
 site.site_name = 'stackoverflow' AND 
 site.site_id = q.site_id AND 
 pl.site_id = q.site_id AND 
 pl.post_id_to = q.id AND 
  
 tag.name = 'underscore.js' AND 
 tag.site_id = q.site_id AND 
  
 q.creation_date > '2011-01-01'::date AND 
  
 tq.site_id = tag.site_id AND 
 tq.tag_id = tag.id AND 
 tq.question_id = q.id AND 
  
 q.owner_user_id = so_user.id AND 
 q.site_id = so_user.site_id AND 
 so_user.reputation > 81 AND 
  
 account.id = so_user.account_id AND 
 account.website_url != ''; 
  
