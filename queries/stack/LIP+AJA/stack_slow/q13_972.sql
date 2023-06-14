SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, u1.site_id)), sum(pg_lip_bloom_add(1, u1.id)), sum(pg_lip_bloom_add(2, u1.id)), sum(pg_lip_bloom_add(3, u1.site_id)) FROM so_user AS u1 
        WHERE ((u1.downvotes >= 10) AND (u1.downvotes <= 100000)) AND ((u1.downvotes >= 10) AND (u1.downvotes <= 100000)) AND ((u1.downvotes >= 10) AND (u1.downvotes <= 100000)) AND ((u1.downvotes >= 10) AND (u1.downvotes <= 100000));


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
(
    SELECT * FROM site as s
    WHERE 
pg_lip_bloom_probe(0, s.site_id) 
) AS s,
so_user as u1,
question as q1,
(
    SELECT * FROM answer as a1
    WHERE 
pg_lip_bloom_probe(1, a1.owner_user_id) 
) AS a1,
tag as t1,
tag_question as tq1,
(
    SELECT * FROM badge as b
    WHERE 
pg_lip_bloom_probe(2, b.user_id)  AND pg_lip_bloom_probe(3, b.site_id) 
) AS b,
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
 AND (s.site_name in ('askubuntu')) 
 AND (t1.name in ('12.04','dpkg','drivers','firefox','keyboard','nvidia','software-installation','system-installation','wine')) 
 AND (q1.view_count >= 10) 
 AND (q1.view_count <= 1000) 
 AND (u1.downvotes >= 10) 
 AND (u1.downvotes <= 100000) 
 AND (b.name in ('Announcer','Caucus','Critic','Editor','Good Answer','Guru','Necromancer','Nice Answer','Nice Question','Notable Question','Revival','Teacher','Yearling')) 
 GROUP BY acc.location 
 ORDER BY COUNT(*) 
 DESC 
 LIMIT 100 
  
;