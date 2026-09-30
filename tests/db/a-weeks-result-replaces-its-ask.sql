-- D398 (Q44 A, amends D296) · ASSERTIONS for 20261215090000: a week's result
-- replaces that week's "is up" post, the cup post says the cup without the
-- score the week's result already printed, event_post stamps
-- clock_timestamp(), and the stored asks of finished weeks are gone.
-- Run against an ISOLATED cluster only (it inserts). Every check RAISES on a
-- wrong answer.
--
-- Two phases, because the cleanup acts on rows that exist BEFORE the migration:
--   psql -v seed=1 -f this.sql   on the chain stopped before 20261215090000
--                                (commits the "stored" board rows prod holds)
--   then apply 20261215090000, then
--   psql -f this.sql             asserts: the stored rows, then the live
--                                producers (inside a rolled-back transaction)
--   psql -v skip_stored=1 -f …   runs the live half alone (for a control)
\set ON_ERROR_STOP on

\if :{?seed}
-- ── SEED · the board as prod holds it before the migration (committed) ──────
begin;
insert into auth.users (id, email) values
  ('00000000-0000-4000-8398-00000000a001', 'avery@fixture.test'),
  ('00000000-0000-4000-8398-00000000a002', 'blake@fixture.test'),
  ('00000000-0000-4000-8398-00000000a003', 'casey@fixture.test'),
  ('00000000-0000-4000-8398-00000000a004', 'drew@fixture.test');
update profiles set display_name = 'Avery Fixture', marker = 'saguaro', handle = 'averyfx', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a001';
update profiles set display_name = 'Blake Fixture', marker = 'azalea',  handle = 'blakefx', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a002';
update profiles set display_name = 'Casey Fixture', marker = 'saguaro', handle = 'caseyfx', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a003';
update profiles set display_name = 'Drew Fixture',  marker = 'azalea',  handle = 'drewfx',  index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a004';
insert into leagues (id, name, code, commissioner_id, phase) values
  ('00000000-0000-4000-8398-00000000b001', 'Fixture League', 'FXQ441', '00000000-0000-4000-8398-00000000a001', 'season');

-- a Ryder with two finished weeks and one open one (the stored board)
insert into events (id, name, created_by, kind, status, starts_on, session_count) values
  ('00000000-0000-4000-8398-00000000e001', 'Stored Cup', '00000000-0000-4000-8398-00000000a001', 'ryder', 'live', '2026-07-06', 3),
  ('00000000-0000-4000-8398-00000000e002', 'Open Cup',   '00000000-0000-4000-8398-00000000a001', 'ryder', 'live', '2026-07-06', 3);
insert into event_sessions (event_id, session_no, opens_on, closes_on, status) values
  ('00000000-0000-4000-8398-00000000e001', 1, '2026-07-06', '2026-07-12', 'closed'),
  ('00000000-0000-4000-8398-00000000e001', 2, '2026-07-13', '2026-07-19', 'closed'),
  ('00000000-0000-4000-8398-00000000e001', 3, '2026-07-20', '2026-07-26', 'open'),
  ('00000000-0000-4000-8398-00000000e002', 1, '2026-07-06', '2026-07-12', 'open');
insert into posts (event_id, league_id, kind, body, profile_id, created_at) values
  -- the two asks of finished weeks, in D296's spelling and the one before it: GO
  ('00000000-0000-4000-8398-00000000e001', null, 'system', 'Week 1 is up. 4 clashes — find yours.', null, '2026-07-06 07:20+00'),
  ('00000000-0000-4000-8398-00000000e001', null, 'system', 'Session 2 is up: Avery v Blake, Casey v Drew.', null, '2026-07-13 07:20+00'),
  -- everything else STAYS
  ('00000000-0000-4000-8398-00000000e001', null, 'system', 'Week 3 is up: Avery v Drew, Casey v Blake.', null, '2026-07-20 07:20+00'),
  ('00000000-0000-4000-8398-00000000e001', null, 'system', 'Fixture Aces lead 2–0 after week 1. Avery beat Blake · Casey beat Drew.', null, '2026-07-13 07:20+00'),
  ('00000000-0000-4000-8398-00000000e001', null, 'system', 'SESSION 1 PAIRINGS: AVERY VS BLAKE · CASEY VS DREW', null, '2026-07-06 07:19+00'),
  ('00000000-0000-4000-8398-00000000e001', null, 'chat',   'Week 1 is up: see you on the first tee.', '00000000-0000-4000-8398-00000000a002', '2026-07-06 08:00+00'),
  ('00000000-0000-4000-8398-00000000e002', null, 'system', 'Week 1 is up. 4 clashes — find yours.', null, '2026-07-06 07:20+00'),
  (null, '00000000-0000-4000-8398-00000000b001', 'system', 'Week 1 is up. The league''s own line.', null, '2026-07-06 07:20+00');
commit;
\echo 'seeded: the stored board (2 finished-week asks, 6 rows that must stay)'
\else

\if :{?skip_stored}
\echo 'skipping the stored-row half'
\else
-- ── STORED · the cleanup removed exactly the asks of finished weeks ─────────
do $$
declare n int;
begin
  if not exists (select 1 from events where id = '00000000-0000-4000-8398-00000000e001') then
    raise exception 'FAIL setup — the stored board was never seeded (run with -v seed=1 before the migration)';
  end if;
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and body = 'Week 1 is up. 4 clashes — find yours.';
  if n <> 0 then raise exception 'FAIL stored — a finished week''s ask (D296 spelling) is still on the board (% row)', n; end if;
  raise notice 'ok   stored — a finished week''s ask (D296 spelling) is gone';
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and body = 'Session 2 is up: Avery v Blake, Casey v Drew.';
  if n <> 0 then raise exception 'FAIL stored — a finished week''s ask (pre-D296 spelling) is still on the board'; end if;
  raise notice 'ok   stored — a finished week''s ask (pre-D296 spelling) is gone';
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and body = 'Week 3 is up: Avery v Drew, Casey v Blake.';
  if n <> 1 then raise exception 'FAIL stored — the open week''s ask was touched (% rows)', n; end if;
  raise notice 'ok   stored — the open week''s ask stays';
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and body like 'Fixture Aces lead 2–0 after week 1.%';
  if n <> 1 then raise exception 'FAIL stored — the week''s result was touched'; end if;
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and body like 'SESSION 1 PAIRINGS:%';
  if n <> 1 then raise exception 'FAIL stored — a post the cleanup does not name was touched'; end if;
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e001' and kind = 'chat';
  if n <> 1 then raise exception 'FAIL stored — a golfer''s chat post was touched'; end if;
  select count(*) into n from posts where event_id = '00000000-0000-4000-8398-00000000e002' and body = 'Week 1 is up. 4 clashes — find yours.';
  if n <> 1 then raise exception 'FAIL stored — another event''s open ask was touched'; end if;
  select count(*) into n from posts where league_id = '00000000-0000-4000-8398-00000000b001' and body like 'Week 1 is up.%';
  if n <> 1 then raise exception 'FAIL stored — a league post was touched'; end if;
  raise notice 'ok   stored — the result, the unnamed spelling, the chat, the other event and the league post all stay';
end $$;
\endif

-- ── LIVE · the producers, driven through the real functions ─────────────────
begin;

create or replace function pg_temp.want(p_label text, p_got text, p_expect text) returns void
language plpgsql as $$
begin
  if p_got is distinct from p_expect then
    raise exception 'FAIL % — got %, expected %', p_label, coalesce(p_got, '<null>'), coalesce(p_expect, '<null>');
  end if;
  raise notice 'ok   %', p_label;
end $$;

insert into auth.users (id, email) values
  ('00000000-0000-4000-8398-00000000a011', 'avery2@fixture.test'),
  ('00000000-0000-4000-8398-00000000a012', 'blake2@fixture.test'),
  ('00000000-0000-4000-8398-00000000a013', 'casey2@fixture.test'),
  ('00000000-0000-4000-8398-00000000a014', 'drew2@fixture.test');
update profiles set display_name = 'Avery Fixture', marker = 'saguaro', handle = 'averyfx2', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a011';
update profiles set display_name = 'Blake Fixture', marker = 'azalea',  handle = 'blakefx2', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a012';
update profiles set display_name = 'Casey Fixture', marker = 'saguaro', handle = 'caseyfx2', index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a013';
update profiles set display_name = 'Drew Fixture',  marker = 'azalea',  handle = 'drewfx2',  index_current = 12.0 where id = '00000000-0000-4000-8398-00000000a014';

-- three Ryders, 2 v 2 over three weeks: one clinched in week 2 by Fixture Aces,
-- one level at the end and decided on total PvI, one level and shared
insert into events (id, name, created_by, kind, status, starts_on, session_count, draw_rule) values
  ('00000000-0000-4000-8398-00000000e011', 'Fixture Cup', '00000000-0000-4000-8398-00000000a011', 'ryder', 'setup', '2026-08-03', 3, 'team_pvi'),
  ('00000000-0000-4000-8398-00000000e012', 'Tie Cup',     '00000000-0000-4000-8398-00000000a011', 'ryder', 'setup', '2026-08-03', 1, 'team_pvi'),
  ('00000000-0000-4000-8398-00000000e013', 'The Shared Cup', '00000000-0000-4000-8398-00000000a011', 'ryder', 'setup', '2026-08-03', 1, 'shared');
insert into event_teams (id, event_id, slot, name) values
  ('00000000-0000-4000-8398-0000000f0110', '00000000-0000-4000-8398-00000000e011', 0, 'Fixture Aces'),
  ('00000000-0000-4000-8398-0000000f0111', '00000000-0000-4000-8398-00000000e011', 1, 'Fixture Birdies'),
  ('00000000-0000-4000-8398-0000000f0120', '00000000-0000-4000-8398-00000000e012', 0, 'Fixture Aces'),
  ('00000000-0000-4000-8398-0000000f0121', '00000000-0000-4000-8398-00000000e012', 1, 'Fixture Birdies'),
  ('00000000-0000-4000-8398-0000000f0130', '00000000-0000-4000-8398-00000000e013', 0, 'Fixture Aces'),
  ('00000000-0000-4000-8398-0000000f0131', '00000000-0000-4000-8398-00000000e013', 1, 'Fixture Birdies');
insert into event_players (event_id, profile_id, team_id, seed, role)
select e.id, p.pid, (case when p.side = 0 then e.t0 else e.t1 end), p.seed, (case when p.seed = 1 then 'captain' else 'player' end)
  from (values ('00000000-0000-4000-8398-00000000e011'::uuid, '00000000-0000-4000-8398-0000000f0110'::uuid, '00000000-0000-4000-8398-0000000f0111'::uuid),
               ('00000000-0000-4000-8398-00000000e012'::uuid, '00000000-0000-4000-8398-0000000f0120'::uuid, '00000000-0000-4000-8398-0000000f0121'::uuid),
               ('00000000-0000-4000-8398-00000000e013'::uuid, '00000000-0000-4000-8398-0000000f0130'::uuid, '00000000-0000-4000-8398-0000000f0131'::uuid)) e(id, t0, t1),
       (values ('00000000-0000-4000-8398-00000000a011'::uuid, 0, 1), ('00000000-0000-4000-8398-00000000a013'::uuid, 0, 2),
               ('00000000-0000-4000-8398-00000000a012'::uuid, 1, 1), ('00000000-0000-4000-8398-00000000a014'::uuid, 1, 2)) p(pid, side, seed);
insert into event_sessions (id, event_id, session_no, opens_on, closes_on) values
  ('00000000-0000-4000-8398-0000000c0111', '00000000-0000-4000-8398-00000000e011', 1, '2026-08-03', '2026-08-09'),
  ('00000000-0000-4000-8398-0000000c0112', '00000000-0000-4000-8398-00000000e011', 2, '2026-08-10', '2026-08-16'),
  ('00000000-0000-4000-8398-0000000c0113', '00000000-0000-4000-8398-00000000e011', 3, '2026-08-17', '2026-08-23'),
  ('00000000-0000-4000-8398-0000000c0121', '00000000-0000-4000-8398-00000000e012', 1, '2026-08-03', '2026-08-09'),
  ('00000000-0000-4000-8398-0000000c0131', '00000000-0000-4000-8398-00000000e013', 1, '2026-08-03', '2026-08-09');

-- week 1: Avery and Casey post, Blake and Drew do not (Avery the better round)
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8398-0000000d0001', '00000000-0000-4000-8398-00000000a011', 78, 70.1, 120, '2026-08-05', 12.0, 18, 'Fixture Links'),
  ('00000000-0000-4000-8398-0000000d0002', '00000000-0000-4000-8398-00000000a013', 84, 70.1, 120, '2026-08-06', 12.0, 18, 'Fixture Links'),
  ('00000000-0000-4000-8398-0000000d0003', '00000000-0000-4000-8398-00000000a011', 79, 70.1, 120, '2026-08-12', 12.0, 18, 'Fixture Links'),
  ('00000000-0000-4000-8398-0000000d0004', '00000000-0000-4000-8398-00000000a013', 85, 70.1, 120, '2026-08-13', 12.0, 18, 'Fixture Links');

-- ── week 1 opens: the ask ──
select pg_temp.want('generate_pairings: week 1 pairs two clashes',
  public.generate_pairings('00000000-0000-4000-8398-0000000c0111')::text, '2');
select pg_temp.want('the week 1 ask is on the board',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Week 1 is up: ')::text, '1');

-- ── week 1 resolves: the result replaces the ask ──
select public.resolve_session('00000000-0000-4000-8398-0000000c0111');
select pg_temp.want('week 1 resolved: its ask is gone',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Week 1 is up')::text, '0');
select pg_temp.want('week 1 resolved: its result is on the board',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Fixture Aces lead 2–0 after week 1\. ')::text, '1');

-- ── week 2 opens, and resolves: the clinch writes the result AND the cup ──
select public.generate_pairings('00000000-0000-4000-8398-0000000c0112');
select pg_temp.want('the week 2 ask is on the board while the week is open',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Week 2 is up: ')::text, '1');
select public.resolve_session('00000000-0000-4000-8398-0000000c0112');
select pg_temp.want('week 2 resolved: its ask is gone',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Week 2 is up')::text, '0');
select pg_temp.want('the clinch completed the Ryder',
  (select status from events where id = '00000000-0000-4000-8398-00000000e011'), 'complete');
select pg_temp.want('the week 2 result says the score',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Fixture Aces lead 4–0 after week 2\. ')::text, '1');
select pg_temp.want('the cup post says the cup, not the score again',
  (select string_agg(body, ' | ') from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ ' take '),
  'Fixture Aces take the Fixture Cup. Avery is MVP at 2-0-0.');
select pg_temp.want('no line but the week results prints a score',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011'
      and body ~ '[0-9½]–[0-9½]' and body !~ ' after week [0-9]+\. ')::text, '0');
select pg_temp.want('one call, true order: the week 2 result is written before the cup post',
  ((select created_at from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Fixture Aces lead 4–0 after week 2')
   < (select created_at from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ ' take the Fixture Cup'))::text, 'true');

-- ── week 3: a dead rubber still opens; an open week keeps its ask ──
select public.generate_pairings('00000000-0000-4000-8398-0000000c0113');
select pg_temp.want('an open week keeps its ask, even after the cup is won',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e011' and body ~ '^Week 3 is up: ')::text, '1');

-- ── level at the end: the rung decides it, and the cup post names the rung ──
-- Tie Cup: Avery beats Blake, Drew beats Casey (1–1); Avery's is the best PvI
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8398-0000000d0011', '00000000-0000-4000-8398-00000000a014', 80, 70.1, 120, '2026-08-07', 12.0, 18, 'Fixture Links');
select public.generate_pairings('00000000-0000-4000-8398-0000000c0121');
select public.resolve_session('00000000-0000-4000-8398-0000000c0121');
select pg_temp.want('a level Ryder decided on the rung: the cup post drops "Level at"',
  (select string_agg(body, ' | ') from posts where event_id = '00000000-0000-4000-8398-00000000e012' and body ~ ' take '),
  'Fixture Aces take the Tie Cup on total PvI. Avery is MVP at 1-0-0.');
select pg_temp.want('the level week result still says it was level',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e012' and body ~ '^All square, 1–1 after week 1\. ')::text, '1');
select pg_temp.want('the rung case: the ask is gone',
  (select count(*) from posts where event_id = '00000000-0000-4000-8398-00000000e012' and body ~ '^Week 1 is up')::text, '0');

-- ── level and shared: the cup post drops the score ──
select public.generate_pairings('00000000-0000-4000-8398-0000000c0131');
select public.resolve_session('00000000-0000-4000-8398-0000000c0131');
select pg_temp.want('a shared cup: the cup post drops the score',
  (select string_agg(body, ' | ') from posts where event_id = '00000000-0000-4000-8398-00000000e013' and body ~ ' share '),
  'Fixture Aces and Fixture Birdies share The Shared Cup. Avery is MVP at 1-0-0.');

-- ── event_post: one call, three posts, three strictly increasing stamps ──
do $$
begin
  perform public.event_post('00000000-0000-4000-8398-00000000e011', 'order probe 1');
  perform public.event_post('00000000-0000-4000-8398-00000000e011', 'order probe 2');
  perform public.event_post('00000000-0000-4000-8398-00000000e011', 'order probe 3');
end $$;
select pg_temp.want('event_post stamps each post in the order it was written',
  (select (array_agg(body order by created_at, body desc))::text from posts
    where event_id = '00000000-0000-4000-8398-00000000e011' and body like 'order probe %'),
  '{"order probe 1","order probe 2","order probe 3"}');
select pg_temp.want('event_post: no two posts of one call share a stamp',
  (select count(distinct created_at) from posts
    where event_id = '00000000-0000-4000-8398-00000000e011' and body like 'order probe %')::text, '3');

-- ── the grants hold ──
select pg_temp.want('event_post: engine-only (no PUBLIC, anon or authenticated)',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.event_post(uuid, text)'::regprocedure and a.privilege_type = 'EXECUTE'
      and (a.grantee = 0 or a.grantee::regrole::text in ('anon','authenticated'))))::text, '0');
select pg_temp.want('resolve_session: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.resolve_session(uuid)'::regprocedure and a.privilege_type = 'EXECUTE'
      and (a.grantee = 0 or a.grantee::regrole::text in ('anon','authenticated'))))::text,
  'authenticated');

rollback;
\echo 'PASS a-weeks-result-replaces-its-ask'
\endif
