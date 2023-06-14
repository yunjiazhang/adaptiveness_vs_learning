SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, b.site_id)), sum(pg_lip_bloom_add(1, b.user_id)), sum(pg_lip_bloom_add(2, b.site_id)), sum(pg_lip_bloom_add(3, b.user_id)) FROM badge AS b 
        WHERE ((b.name)::text = ANY ('{Deputy,Disciplined,"Favorite Question",Generalist,"Tag Editor",Tenacious}'::text[])) AND ((b.name)::text = ANY ('{Deputy,Disciplined,"Favorite Question",Generalist,"Tag Editor",Tenacious}'::text[])) AND ((b.name)::text = ANY ('{Deputy,Disciplined,"Favorite Question",Generalist,"Tag Editor",Tenacious}'::text[])) AND ((b.name)::text = ANY ('{Deputy,Disciplined,"Favorite Question",Generalist,"Tag Editor",Tenacious}'::text[]));


/*+
NestLoop(t1 s tq1 a1 u1 q1 b acc)
NestLoop(t1 s tq1 a1 u1 q1 b)
NestLoop(t1 s tq1 a1 u1 q1)
NestLoop(t1 s tq1 a1 u1)
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
Leading((((((((t1 s) tq1) a1) u1) q1) b) acc))
*/
 SELECT acc.location, count(*) 
 
FROM 
(
    SELECT * FROM site as s
    WHERE 
pg_lip_bloom_probe(0, s.site_id) 
) AS s,
(
    SELECT * FROM so_user as u1
    WHERE 
pg_lip_bloom_probe(2, u1.site_id)  AND pg_lip_bloom_probe(3, u1.id) 
) AS u1,
question as q1,
(
    SELECT * FROM answer as a1
    WHERE 
pg_lip_bloom_probe(1, a1.owner_user_id) 
) AS a1,
tag as t1,
tag_question as tq1,
badge as b,
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
 AND (s.site_name in ('askubuntu','math')) 
 AND (t1.name in ('16.04','algebraic-topology','commutative-algebra','complex-numbers','continuity','definite-integrals','diophantine-equations','elementary-set-theory','indefinite-integrals','nvidia','pde','vector-spaces')) 
 AND (q1.favorite_count >= 1) 
 AND (q1.favorite_count <= 10) 
 AND (u1.reputation >= 10) 
 AND (u1.reputation <= 100000) 
 AND (b.name in ('Deputy','Disciplined','Favorite Question','Generalist','Tag Editor','Tenacious')) 
 GROUP BY acc.location 
 ORDER BY COUNT(*) 
 DESC 
 LIMIT 100 
  
;