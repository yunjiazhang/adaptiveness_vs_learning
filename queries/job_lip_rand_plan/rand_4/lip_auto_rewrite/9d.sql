SELECT pg_lip_bloom_set_dynamic(2);
SELECT pg_lip_bloom_init(4);
SELECT sum(pg_lip_bloom_add(0, ci.movie_id)) FROM cast_info AS ci WHERE ci.note IN ('(voice)', '(voice: Japanese version)', '(voice) (uncredited)', '(voice: English version)');
SELECT sum(pg_lip_bloom_add(1, cn.id)) FROM company_name AS cn WHERE cn.country_code ='[us]';
SELECT sum(pg_lip_bloom_add(2, n.id)) FROM name AS n WHERE n.gender ='f';
SELECT sum(pg_lip_bloom_add(3, rt.id)) FROM role_type AS rt WHERE rt.role ='actress';

/*+
HashJoin(mc ci t n an cn chn rt)
HashJoin(mc ci t n an cn chn)
HashJoin(mc ci t n an cn)
HashJoin(mc ci t n an)
HashJoin(mc ci t n)
HashJoin(mc ci t)
HashJoin(mc ci)
SeqScan(mc)
SeqScan(ci)
SeqScan(t)
SeqScan(n)
SeqScan(an)
SeqScan(cn)
SeqScan(chn)
SeqScan(rt)
Leading((((((((mc ci) t) n) an) cn) chn) rt))*/
SELECT MIN(an.name) AS alternative_name,
       MIN(chn.name) AS voiced_char_name,
       MIN(n.name) AS voicing_actress,
       MIN(t.title) AS american_movie
 FROM 
(
	SELECT * FROM aka_name AS an 
	 WHERE pg_lip_bloom_probe(2, an.person_id)
) AS an ,
char_name AS chn ,
(
	SELECT * FROM cast_info AS ci 
	 WHERE pg_lip_bloom_probe(2, ci.person_id)
	AND pg_lip_bloom_probe(3, ci.role_id)
) AS ci ,
company_name AS cn ,
(
	SELECT * FROM movie_companies AS mc 
	 WHERE pg_lip_bloom_probe(0, mc.movie_id)
	AND pg_lip_bloom_probe(1, mc.company_id)
) AS mc ,
name AS n ,
role_type AS rt ,
(
	SELECT * FROM title AS t 
	 WHERE pg_lip_bloom_probe(0, t.id)
) AS t
WHERE
 ci.note IN ('(voice)',
                  '(voice: Japanese version)',
                  '(voice) (uncredited)',
                  '(voice: English version)')
  AND cn.country_code ='[us]'
  AND n.gender ='f'
  AND rt.role ='actress'
  AND ci.movie_id = t.id
  AND t.id = mc.movie_id
  AND ci.movie_id = mc.movie_id
  AND mc.company_id = cn.id
  AND ci.role_id = rt.id
  AND n.id = ci.person_id
  AND chn.id = ci.person_role_id
  AND an.person_id = n.id
  AND an.person_id = ci.person_id;

