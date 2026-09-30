-- X39 · D399 · ASSERTIONS for home_dispatch's circle item (BAND 4): a buddy's
-- first round reads "Their first posted round." with the quiet spine, never
-- "Under 80 for the first time." in gold; a later round keeps its claims. Run
-- against an ISOLATED cluster only (it inserts), after the full migration
-- chain. Every check RAISES on a wrong answer, and the transaction rolls back.
-- Synthetic cast only (tests/fixtures/ten/cast.mjs).
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

-- the circle item Blake's Home carries, as "standfirst · spine · key"
create or replace function pg_temp.circle() returns text
language plpgsql as $$
declare v jsonb;
begin
  perform set_config('sim.uid', '00000000-0000-4000-8399-00000000c001', true);
  select i into v from jsonb_array_elements(public.home_dispatch(21, current_date, array['afterplan.v1'])->'items') i
   where i->>'tier' = 'circle' limit 1;
  return coalesce(v->>'standfirst', '<none>') || ' · ' || coalesce(v->>'spine', '<none>') || ' · ' || coalesce(v->>'key', '<none>');
end $$;

-- ── the fixture: Blake (the viewer) and his two buddies, Devon and Casey
insert into auth.users (id, email) values
  ('00000000-0000-4000-8399-00000000c001', 'blake.circle@fixture.test'),
  ('00000000-0000-4000-8399-00000000c002', 'devon.circle@fixture.test'),
  ('00000000-0000-4000-8399-00000000c003', 'casey.circle@fixture.test');
update profiles set display_name = 'Blake Sample',      marker = 'saguaro', handle = 'blakecircle', index_current = 14.0 where id = '00000000-0000-4000-8399-00000000c001';
update profiles set display_name = 'Devon Testwell',    marker = 'azalea',  handle = 'devoncircle', index_current = 10.0 where id = '00000000-0000-4000-8399-00000000c002';
update profiles set display_name = 'Casey Placeholder', marker = 'saguaro', handle = 'caseycircle', index_current = 12.0 where id = '00000000-0000-4000-8399-00000000c003';
insert into friendships (requester, addressee, status) values
  ('00000000-0000-4000-8399-00000000c001', '00000000-0000-4000-8399-00000000c002', 'accepted'),
  ('00000000-0000-4000-8399-00000000c003', '00000000-0000-4000-8399-00000000c001', 'accepted');

-- (1) Devon's FIRST posted round is a 78, eighteen holes: a debut
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label, created_at) values
  ('00000000-0000-4000-8399-0000000d0001', '00000000-0000-4000-8399-00000000c002', 78, 70.1, 120, current_date - 2, 10.0, 18, 'Papago (fixture)', now() - interval '2 hours');
select pg_temp.want('a buddy''s debut 78: a first round, in the quiet spine, never "Under 80 for the first time."',
  pg_temp.circle(), 'Their first posted round. · mut · story:00000000-0000-4000-8399-0000000d0001');

-- (2) Casey's second round breaks 80 for the first time, after an 85 that
--     scored better against its harder course (so it is not a personal best):
--     a later round keeps its barrier claim and its gold
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label, created_at) values
  ('00000000-0000-4000-8399-0000000d0002', '00000000-0000-4000-8399-00000000c003', 85, 76.0, 150, current_date - 10, 12.0, 18, 'Longbow (fixture)', now() - interval '9 days'),
  ('00000000-0000-4000-8399-0000000d0003', '00000000-0000-4000-8399-00000000c003', 79, 67.0, 110, current_date - 1, 12.0, 18, 'Encanto (fixture)', now() - interval '1 hour');
select pg_temp.want('a later round that breaks 80 keeps "Under 80 for the first time." in gold',
  pg_temp.circle(), 'Under 80 for the first time. · gold · story:00000000-0000-4000-8399-0000000d0003');

-- (3) Casey's next round beats both: a personal best is still a personal best
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label, created_at) values
  ('00000000-0000-4000-8399-0000000d0004', '00000000-0000-4000-8399-00000000c003', 77, 74.0, 140, current_date, 12.0, 18, 'Aguila (fixture)', now() - interval '10 minutes');
select pg_temp.want('a personal best keeps "A personal best." in gold',
  pg_temp.circle(), 'A personal best. · gold · story:00000000-0000-4000-8399-0000000d0004');

-- ── the body was patched, not retyped; the grants hold ─────────────────────
select pg_temp.want('the [AW2-05] clash patch survives',
  (position('[AW2-05]' in pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure)) > 0)::text, 'true');
select pg_temp.want('the terms sentence (20261211094500) survives',
  (pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure) ~ 'See the terms before you.re in')::text, 'true');
select pg_temp.want('home_dispatch: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.home_dispatch(integer,date,text[])'::regprocedure and a.privilege_type = 'EXECUTE'
      and (a.grantee = 0 or a.grantee::regrole::text in ('anon','authenticated'))))::text,
  'authenticated');

rollback;
