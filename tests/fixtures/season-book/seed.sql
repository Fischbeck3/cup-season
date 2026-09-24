-- Synthetic local database fixtures only. The caller must use the isolated
-- sandbox; these are not production users or a migration.
set session_replication_role=replica;
create or replace function pg_temp.bid(n int) returns uuid language sql immutable as $$
select ('C50B0000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid $$;
insert into auth.users(id,email) select pg_temp.bid(i),'book-fixture-'||i||'@example.invalid' from generate_series(1,18) i;
insert into profiles(id,email,display_name,marker,index_current)
select pg_temp.bid(i),'book-fixture-'||i||'@example.invalid',
  (array['Galen Marr','Jerecho','Jade Okafor','Dev Rana','Tash Bell','Mike Fenner','Priya Raghunathan','Sam Ridley','Nora Vance','Eli Brandt','Ruth Salas','Owen Pike','Alex Park','Cam Ellis','Robin West','Lee Santos','Outsider','Unconfirmed'])[i], 'saguaro',12
from generate_series(1,18) i;
insert into leagues(id,name,code,commissioner_id,phase,sandbox)
values(pg_temp.bid(100),'The Fellas','BKF01',pg_temp.bid(1),'season',true),
(pg_temp.bid(101),'The Saturday Cup','BKT01',pg_temp.bid(1),'season',true),
(pg_temp.bid(102),'The Autumn Cup','BKA01',pg_temp.bid(1),'season',true),
(pg_temp.bid(103),'The Summer Cup','BKS01',pg_temp.bid(1),'complete',true);
insert into league_settings(league_id,structure,counting_cap,participation_floor,handicap_allowance,finish)
select pg_temp.bid(i),case when i=100 then 'squads4' else 'solo' end,3,2,100,'points_table' from generate_series(100,103)i;
insert into seasons(id,league_id,number,starts_on,ends_on,status,champion_member_id)
select pg_temp.bid(i+100),pg_temp.bid(i),1,
 case when i=102 then '2026-10-05'::date else '2026-07-06'::date end,
 case when i=102 then '2027-01-17'::date else '2026-10-18'::date end,
 case when i=103 then 'complete' else 'active' end,
 case when i=103 then pg_temp.bid(1000+i*100+1) end
from generate_series(100,103)i;
insert into league_members(id,league_id,profile_id,role,agreed_seasons)
select pg_temp.bid(1000+lg*100+i),pg_temp.bid(lg),pg_temp.bid(i),
 case when i=1 then 'commissioner' else 'player' end,array[1]
from generate_series(100,103)lg cross join generate_series(1,16)i where lg<>101 or i<=2;
insert into league_members(id,league_id,profile_id,role,agreed_seasons)
values(pg_temp.bid(11800),pg_temp.bid(100),pg_temp.bid(18),'player','{}');
insert into squads(id,season_id,name,color)
select pg_temp.bid(300+i),pg_temp.bid(200),(array['Mudsharks','Roadrunners','Coyotes','Saguaros'])[i+1],i from generate_series(0,3)i;
insert into squad_members(squad_id,member_id)
select pg_temp.bid(300+(i-1)/4),pg_temp.bid(11000+i) from generate_series(1,16)i;
-- Multiple rounds per week and displaced rounds, scored by the REAL lens.
insert into rounds(id,profile_id,course_label,played_on,holes_played,gross,rating,slope,index_at_post,differential,created_at)
select pg_temp.bid(20000+i*100+w),pg_temp.bid(i),'Fixture Links',
 '2026-07-06'::date+(w-1)*7,18,80+(i+w)%7,72,113,12,8+(i+w)%7,
 ('2026-07-06'::date+(w-1)*7)::timestamp at time zone 'America/Phoenix'
from generate_series(1,16)i cross join generate_series(1,12)w;
insert into rounds(id,profile_id,course_label,played_on,holes_played,gross,rating,slope,index_at_post,differential,created_at)
values(pg_temp.bid(29999),pg_temp.bid(2),'Second round same week','2026-09-21',18,92,72,113,12,20,'2026-09-22 18:00-07');
insert into season_adjustments(id,season_id,squad_id,member_id,month,kind,points,reason,created_at)
values(pg_temp.bid(400),pg_temp.bid(200),pg_temp.bid(303),pg_temp.bid(11015),'2026-08-01','floor_penalty',-5,'August minimum: one round short','2026-09-01 00:30-07'),
(pg_temp.bid(401),pg_temp.bid(200),pg_temp.bid(303),pg_temp.bid(11016),'2026-08-01','bye',0,'August minimum waived: season bye','2026-09-01 00:30-07'),
(pg_temp.bid(402),pg_temp.bid(200),pg_temp.bid(300),pg_temp.bid(11002),'2026-09-01','override',-3,'The Pro corrected the competition record','2026-09-22 09:00-07'),
(pg_temp.bid(403),pg_temp.bid(200),pg_temp.bid(301),null,'2026-07-01','override',2,'Late recorded squad correction','2026-10-20 09:00-07');
-- A shared 41-point total, using the existing permitted individual override.
insert into season_adjustments(id,season_id,member_id,month,kind,points,reason,created_at)
select pg_temp.bid(410+(row_number() over())::integer),pg_temp.bid(201),iv.member_id,'2026-09-01','override',41-iv.points,
 'Synthetic tie adjustment','2026-09-22 09:00-07' from v_individual_standings iv where season_id=pg_temp.bid(201);
set session_replication_role=origin;
