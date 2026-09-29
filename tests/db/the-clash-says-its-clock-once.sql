-- AW2-05 · ASSERTIONS for home_dispatch's weekly clash item: the eyebrow names
-- the competition only, each branch says the clock once, and an IDLE clash
-- says its idle words on every day, the last included (never "both in" when
-- neither has posted). D216's yield is the band alone.
--
-- native_home() is stubbed INSIDE this transaction, so the real, patched
-- clash branch of home_dispatch runs on each of the six states: idle with five
-- days, idle tomorrow, idle today, theirs only, mine only, and both in. The
-- stub reads its clash from transaction-local settings. Run against an
-- ISOLATED cluster only, after the full migration chain. Every check RAISES on
-- a wrong answer, and the transaction rolls back (the real native_home with it).
\set ON_ERROR_STOP on
begin;

create or replace function pg_temp.want(p_label text, p_got text, p_expect text) returns void
language plpgsql as $$
begin
  if p_got is distinct from p_expect then
    raise exception 'FAIL % — got %, expected %', p_label, coalesce(p_got, '<null>'), coalesce(p_expect, '<null>');
  end if;
  raise notice 'ok   %', p_label;
end $$;

-- the caller: any signed-in id (the stub below answers for them)
insert into auth.users (id, email) values ('00000000-0000-4000-8000-00000000c1a5', 'clash@fixture.test');
select set_config('sim.uid', '00000000-0000-4000-8000-00000000c1a5', true);

create or replace function public.native_home() returns jsonb language sql stable as $$
  select jsonb_build_object(
    'profile', jsonb_build_object('rounds_count', 3),
    'memberships', jsonb_build_array(jsonb_build_object(
      'league_id', '00000000-0000-4000-8000-00000000c1b0',
      'name', 'Fixture Club',
      'clash', jsonb_build_object(
        'week_no', 8, 'ends_on', current_date + 5, 'rivalry', 'The Fixture Derby', 'them_name', 'Galen Ward',
        'days_left', current_setting('t.left')::int,
        'closes_today', current_setting('t.close')::boolean,
        'mine', nullif(current_setting('t.mine'), '')::jsonb,
        'theirs', nullif(current_setting('t.theirs'), '')::jsonb))))
$$;

-- one state of the clash in, its item out
create or replace function pg_temp.clash(p_left int, p_close boolean, p_mine text, p_theirs text) returns jsonb
language plpgsql as $$
declare v jsonb;
begin
  perform set_config('t.left', p_left::text, true);
  perform set_config('t.close', p_close::text, true);
  perform set_config('t.mine', coalesce(p_mine, ''), true);
  perform set_config('t.theirs', coalesce(p_theirs, ''), true);
  select i into v from jsonb_array_elements(public.home_dispatch(21, current_date, array['afterplan.v1'])->'items') i
   where i->>'key' like 'clash:%' limit 1;
  return v;
end $$;

-- ── idle, five days left: it yields (D216), and says its clock once ─────────
select pg_temp.want('idle, 5 days: the eyebrow names the competition only',
  pg_temp.clash(5, false, null, null)->>'eyebrow', 'THE FIXTURE DERBY · THE CLASH');
select pg_temp.want('idle, 5 days: the idle words, the clock in the standfirst',
  (select concat_ws(' / ', c->>'headline', c->>'standfirst') from pg_temp.clash(5, false, null, null) c),
  'Your clash with Galen is open. / Best round of the week takes it. The week closes in 5 days.');
select pg_temp.want('idle, 5 days: it yields, band 600, coming',
  (select concat_ws(' ', c->>'band', c->>'tier') from pg_temp.clash(5, false, null, null) c), '600 coming');

-- ── idle, its last day: the idle words, never "both in" ─────────────────────
select pg_temp.want('idle, tomorrow: the idle words, never "both in"',
  (select concat_ws(' / ', c->>'headline', c->>'standfirst') from pg_temp.clash(1, false, null, null) c),
  'Your clash with Galen is open. / Best round of the week takes it. The week closes tomorrow.');
select pg_temp.want('idle, tomorrow: the last-call day re-enters band 1000, closing',
  (select concat_ws(' ', c->>'band', c->>'tier') from pg_temp.clash(1, false, null, null) c), '1000 closing');
select pg_temp.want('idle, closing today: the idle words, never "both in"',
  (select concat_ws(' / ', c->>'headline', c->>'standfirst') from pg_temp.clash(0, true, null, null) c),
  'Your clash with Galen is open. / Best round of the week takes it. The week closes today.');
select pg_temp.want('idle, closing today: band 1000, closing',
  (select concat_ws(' ', c->>'band', c->>'tier') from pg_temp.clash(0, true, null, null) c), '1000 closing');

-- ── the posted branches keep their words, and the clock once ───────────────
select pg_temp.want('theirs in, mine not: the standfirst keeps the clock',
  pg_temp.clash(5, false, null, '{"gross": 84}')->>'standfirst', 'That is the number, and the week closes in 5 days.');
select pg_temp.want('mine in, theirs not: the headline keeps the clock',
  (select concat_ws(' / ', c->>'headline', c->>'standfirst') from pg_temp.clash(5, false, '{"gross": 89}', null) c),
  'Galen has 5 days to answer your 89. / Your round is the number to beat.');
select pg_temp.want('both in: "both in" is said only when both have posted',
  (select concat_ws(' / ', c->>'headline', c->>'standfirst') from pg_temp.clash(5, false, '{"gross": 89}', '{"gross": 84}') c),
  'You and Galen are both in. / The week closes in 5 days. Best round takes it.');
select pg_temp.want('no branch prints the clock in its eyebrow',
  (select string_agg(distinct c->>'eyebrow', ' | ') from (values
     (pg_temp.clash(5, false, null, null)), (pg_temp.clash(1, false, null, null)), (pg_temp.clash(0, true, null, null)),
     (pg_temp.clash(5, false, null, '{"gross": 84}')), (pg_temp.clash(5, false, '{"gross": 89}', null)),
     (pg_temp.clash(5, false, '{"gross": 89}', '{"gross": 84}'))) v(c)),
  'THE FIXTURE DERBY · THE CLASH');

-- ── the grants hold ─────────────────────────────────────────────────────────
select pg_temp.want('home_dispatch: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.home_dispatch(integer,date,text[])'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  'authenticated');
select pg_temp.want('home_dispatch: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.home_dispatch(integer,date,text[])'::regprocedure and a.grantee = 0))::text, '0');

rollback;
