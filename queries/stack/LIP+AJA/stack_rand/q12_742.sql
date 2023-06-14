SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(3);
SELECT sum(pg_lip_bloom_add(0, u1.site_id)), sum(pg_lip_bloom_add(1, u1.id)), sum(pg_lip_bloom_add(2, u1.site_id)) FROM so_user AS u1 
        WHERE ((u1.downvotes >= 10) AND (u1.downvotes <= 100000)) AND ((u1.downvotes >= 10) AND (u1.downvotes <= 100000)) AND ((u1.downvotes >= 10) AND (u1.downvotes <= 100000));


/*+
NestLoop(t1 s tq1 a1 q1 u1)
NestLoop(t1 s tq1 a1 q1)
NestLoop(t1 s tq1 a1)
NestLoop(t1 s tq1)
HashJoin(t1 s)
IndexScan(tq1)
IndexScan(a1)
IndexScan(q1)
IndexScan(u1)
SeqScan(t1)
SeqScan(s)
Leading((((((t1 s) tq1) a1) q1) u1))
*/
 SELECT t1.name, count(*) 
 
FROM 
(
    SELECT * FROM site as s
    WHERE 
pg_lip_bloom_probe(0, s.site_id) 
) AS s,
so_user as u1,
(
    SELECT * FROM question as q1
    WHERE 
pg_lip_bloom_probe(1, q1.owner_user_id)  AND pg_lip_bloom_probe(2, q1.site_id) 
) AS q1,
answer as a1,
tag as t1,
tag_question as tq1
WHERE 
 
 q1.owner_user_id = u1.id 
 AND a1.question_id = q1.id 
 AND a1.owner_user_id = u1.id 
 AND s.site_id = q1.site_id 
 AND s.site_id = a1.site_id 
 AND s.site_id = u1.site_id 
 AND s.site_id = tq1.site_id 
 AND s.site_id = t1.site_id 
 AND q1.id = tq1.question_id 
 AND t1.id = tq1.tag_id 
 AND (s.site_name in ('stackoverflow','superuser')) 
 AND (t1.name in ('coded-ui-tests','esp8266','exit','google-spreadsheet-api','jspdf','jython','keyboard-layout','orders','point','strongloop')) 
 AND (q1.view_count >= 100) 
 AND (q1.view_count <= 100000) 
 AND (u1.downvotes >= 10) 
 AND (u1.downvotes <= 100000) 
 GROUP BY t1.name 
;