-- 20261224120000 · D412 · ASSERTIONS for a Major's buy-in ceiling, through the real
-- create_major as a signed-in golfer (never as postgres):
--   · 201, 200.01 and a negative are refused with the unchanged words 'buy-in out of range';
--   · 200, 0 and an omitted buy-in are accepted and stored exactly as sent;
--   · the gates the anchor patch had to keep still answer: the [D393] reach gate (a sixth
--     new event in a day) and the stage-D write gate (a golfer who left the league);
--   · anon still cannot call it.
-- Run against an ISOLATED cluster only, after the full migration chain:
--   node tests/major-buy-in-database.mjs
-- or tests/sim/sandbox/apply.sh, then psql … -f tests/db/a-majors-buy-in-has-the-same-ceiling.sql.
-- Every check RAISES on a wrong answer, and the transaction rolls back.
\set ON_ERROR_STOP on
begin;

create function pg_temp.want(p_label text, p_got text, p_expect text) returns void
language plpgsql as $$
begin
  if p_got is distinct from p_expect then
    raise exception 'FAIL % — got %, expected %', p_label, coalesce(p_got, '<null>'), coalesce(p_expect, '<null>');
  end if;
  raise notice 'ok   %', p_label;
end $$;
create function pg_temp.refused(p_label text, p_sql text, p_msg text) returns void
language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    if position(p_msg in sqlerrm) > 0 then raise notice 'ok   %', p_label; return; end if;
    raise exception 'FAIL % — expected "%" but got "%"', p_label, p_msg, sqlerrm;
  end;
  raise exception 'FAIL % — expected a refusal ("%"), and it was accepted', p_label, p_msg;
end $$;
grant execute on function pg_temp.want(text, text, text) to authenticated, anon;
grant execute on function pg_temp.refused(text, text, text) to authenticated, anon;

-- ---- the cast (fictional fixture golfers, never production data) -------------
insert into auth.users (id, email) values
 ('00000000-0000-4000-8000-0000000d4120', 'major.host@fixture.test'),
 ('00000000-0000-4000-8000-0000000d4121', 'major.leaver@fixture.test');
update profiles set display_name = 'Fixture Host', handle = 'fixture_host', marker = 'saguaro', is_founder = false
 where id = '00000000-0000-4000-8000-0000000d4120';
update profiles set display_name = 'Fixture Leaver', handle = 'fixture_leaver', marker = 'dunes', is_founder = false
 where id = '00000000-0000-4000-8000-0000000d4121';
insert into leagues (id, name, code, commissioner_id, phase) values
 ('00000000-0000-4000-8000-0000000d412a', 'Fixture Majors Club', 'D412FX', '00000000-0000-4000-8000-0000000d4120', 'season');
insert into league_members (league_id, profile_id, role) values
 ('00000000-0000-4000-8000-0000000d412a', '00000000-0000-4000-8000-0000000d4120', 'commissioner'),
 ('00000000-0000-4000-8000-0000000d412a', '00000000-0000-4000-8000-0000000d4121', 'player')
 on conflict (league_id, profile_id) do nothing;

create temp table t_made (label text, event_id uuid);
grant select, insert on t_made to authenticated;

-- ---- 1 · the ceiling, as the host ---------------------------------------------
set local role authenticated;
select set_config('sim.uid', '00000000-0000-4000-8000-0000000d4120', true);

select pg_temp.refused('a $201 buy-in is refused',
  $q$select create_major('Fixture Jug', current_date + 7, 4, 201)$q$, 'buy-in out of range');
select pg_temp.refused('a $200.01 buy-in is refused (the ceiling is $200, not $200 and change)',
  $q$select create_major('Fixture Jug', current_date + 7, 4, 200.01)$q$, 'buy-in out of range');
select pg_temp.refused('the old top of the range, $100,000, is refused',
  $q$select create_major('Fixture Jug', current_date + 7, 4, 100000)$q$, 'buy-in out of range');
select pg_temp.refused('a negative buy-in is still refused',
  $q$select create_major('Fixture Jug', current_date + 7, 4, -1)$q$, 'buy-in out of range');

insert into t_made select 'at 200', create_major('Fixture Jug at the ceiling', current_date + 7, 4, 200);
insert into t_made select 'at 0', create_major('Fixture Jug for bragging rights', current_date + 7, 4, 0);
insert into t_made select 'omitted', create_major('Fixture Jug with no buy-in', current_date + 7);
reset role;

select pg_temp.want('a $200 buy-in is accepted and stored as 200',
  (select e.buy_in::text from t_made m join events e on e.id = m.event_id where m.label = 'at 200' and e.kind = 'major'), '200');
select pg_temp.want('a $0 buy-in is accepted and stored as 0',
  (select e.buy_in::text from t_made m join events e on e.id = m.event_id where m.label = 'at 0' and e.kind = 'major'), '0');
select pg_temp.want('an omitted buy-in is accepted and stored as 0',
  (select e.buy_in::text from t_made m join events e on e.id = m.event_id where m.label = 'omitted' and e.kind = 'major'), '0');
select pg_temp.want('the $200 Major announces its buy-in on the board',
  (select count(*)::text from t_made m join posts p on p.event_id = m.event_id
    where m.label = 'at 200' and p.body like '%Buy-in%'), '1');
select pg_temp.want('a refused buy-in left no event behind',
  (select count(*)::text from events where created_by = '00000000-0000-4000-8000-0000000d4120'), '3');

-- ---- 2 · the [D393] reach gate survived the patch ------------------------------
-- three accepted above; two more fill the day's five; the sixth is the gate's
set local role authenticated;
select set_config('sim.uid', '00000000-0000-4000-8000-0000000d4120', true);
select create_major('Fixture Jug four', current_date + 7, 4, 50);
select create_major('Fixture Jug five', current_date + 7, 4, 50);
select pg_temp.refused('[D393] a sixth new event in a day meets the reach gate',
  $q$select create_major('Fixture Jug six', current_date + 7, 4, 50)$q$, 'That''s a lot for one day');

-- ---- 3 · the stage-D write gate survived the patch -----------------------------
select set_config('sim.uid', '00000000-0000-4000-8000-0000000d4121', true);
insert into t_made select 'league at 200',
  create_major('Fixture Club Jug', current_date + 7, 4, 200, 'places', '00000000-0000-4000-8000-0000000d412a');
select pg_temp.refused('a league member is held to the same $200 ceiling',
  $q$select create_major('Fixture Club Jug', current_date + 7, 4, 201, 'places', '00000000-0000-4000-8000-0000000d412a')$q$,
  'buy-in out of range');
reset role;
update league_members set left_at = now()
 where league_id = '00000000-0000-4000-8000-0000000d412a' and profile_id = '00000000-0000-4000-8000-0000000d4121';
set local role authenticated;
select set_config('sim.uid', '00000000-0000-4000-8000-0000000d4121', true);
select pg_temp.refused('[D378] a golfer who left the league cannot run a Major with it',
  $q$select create_major('Fixture Club Jug', current_date + 7, 4, 100, 'places', '00000000-0000-4000-8000-0000000d412a')$q$,
  'you must be in the league to run a Major with it');

-- ---- 4 · anon is never a caller -----------------------------------------------
set local role anon;
select set_config('sim.uid', '', true);
select pg_temp.refused('anon cannot create a Major',
  $q$select create_major('Fixture Jug', current_date + 7, 4, 0)$q$, 'permission denied');
reset role;

select pg_temp.want('a league Major at $200 was stored as 200',
  (select e.buy_in::text from t_made m join events e on e.id = m.event_id where m.label = 'league at 200'), '200');
select pg_temp.want('create_major is one function (no overload beside it)',
  (select count(*)::text from pg_proc where pronamespace = 'public'::regnamespace and proname = 'create_major'), '1');
select pg_temp.want('that one function carries the [D412] patch',
  (select count(*)::text from pg_proc where pronamespace = 'public'::regnamespace and proname = 'create_major'
      and prosrc like '%[D412]%'), '1');

select 'a-majors-buy-in-has-the-same-ceiling: all assertions passed' as result;
rollback;
