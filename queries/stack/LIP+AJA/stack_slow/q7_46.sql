SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(0);


/*+
NestLoop(so_user account b2 b1)
HashJoin(so_user account b2)
HashJoin(so_user account)
SeqScan(so_user)
SeqScan(account)
IndexScan(b2)
IndexScan(b1)
Leading((((so_user account) b2) b1))
*/
  
 SELECT count(distinct account.display_name) 
FROM 
account,
so_user,
badge b1,
badge b2
WHERE 
 
 account.website_url != '' AND 
 account.id = so_user.account_id AND 
  
 b1.site_id = so_user.site_id AND 
 b1.user_id = so_user.id AND 
 b1.name = 'Commentator' AND 
  
 b2.site_id = so_user.site_id AND 
 b2.user_id = so_user.id AND 
 b2.name = 'Commentator' AND 
 b2.date > b1.date + '11 months'::interval 
  
;