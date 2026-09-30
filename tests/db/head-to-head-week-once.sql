-- W7-002 · ASSERTIONS for head_to_head's season_weeks facet: a week both
-- golfers posted is ONE meeting, however many seasons they share. Run against
-- an ISOLATED cluster only (it inserts), after the full migration chain.
-- Every check RAISES on a wrong answer.
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

-- ── the fixture: Sam and Jade share TWO solo leagues, each with a season ──
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000a001', 'sam@fixture.test'),
  ('00000000-0000-4000-8000-00000000a002', 'jade@fixture.test');
update profiles set display_name = 'Sam Fixture', marker = 'saguaro', handle = 'samfx', index_current = 12.0 where id = '00000000-0000-4000-8000-00000000a001';
update profiles set display_name = 'Jade Fixture', marker = 'azalea', handle = 'jadefx', index_current = 12.0 where id = '00000000-0000-4000-8000-00000000a002';
insert into leagues (id, name, code, commissioner_id, phase) values
  ('00000000-0000-4000-8000-00000000b001', 'Fellas', 'FELLA1', '00000000-0000-4000-8000-00000000a001', 'season'),
  ('00000000-0000-4000-8000-00000000b002', 'Sunday Cup', 'SUNDA1', '00000000-0000-4000-8000-00000000a001', 'season');
insert into league_settings (league_id) values ('00000000-0000-4000-8000-00000000b001'), ('00000000-0000-4000-8000-00000000b002') on conflict do nothing;
update league_settings set structure = 'solo' where league_id in ('00000000-0000-4000-8000-00000000b001', '00000000-0000-4000-8000-00000000b002');
insert into seasons (id, league_id, number, starts_on, ends_on, status) values
  ('00000000-0000-4000-8000-00000000c001', '00000000-0000-4000-8000-00000000b001', 1, '2026-01-01', '2026-12-31', 'active'),
  ('00000000-0000-4000-8000-00000000c002', '00000000-0000-4000-8000-00000000b002', 1, '2026-01-01', '2026-12-31', 'active');
insert into league_members (id, league_id, profile_id, role) values
  ('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000b001', '00000000-0000-4000-8000-00000000a001', 'commissioner'),
  ('00000000-0000-4000-8000-00000000d002', '00000000-0000-4000-8000-00000000b001', '00000000-0000-4000-8000-00000000a002', 'player'),
  ('00000000-0000-4000-8000-00000000d003', '00000000-0000-4000-8000-00000000b002', '00000000-0000-4000-8000-00000000a001', 'commissioner'),
  ('00000000-0000-4000-8000-00000000d004', '00000000-0000-4000-8000-00000000b002', '00000000-0000-4000-8000-00000000a002', 'player');

-- two weeks both posted, on different days and courses (so no other facet
-- counts them): Sam takes the first week, Jade the second
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000a001', 80, 70.1, 120, '2026-09-01', 12.0, 18, 'Papago'),
  ('00000000-0000-4000-8000-00000000e002', '00000000-0000-4000-8000-00000000a002', 90, 70.1, 120, '2026-09-02', 12.0, 18, 'Aguila'),
  ('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000a001', 92, 70.1, 120, '2026-09-08', 12.0, 18, 'Encanto'),
  ('00000000-0000-4000-8000-00000000e004', '00000000-0000-4000-8000-00000000a002', 81, 70.1, 120, '2026-09-10', 12.0, 18, 'Longbow');

-- the precondition the defect needs: every round is ranked in BOTH seasons
select pg_temp.want('each round is ranked in both shared seasons',
  (select count(*) from v_rounds_ranked where profile_id in ('00000000-0000-4000-8000-00000000a001','00000000-0000-4000-8000-00000000a002'))::text,
  '8');

-- ── as Sam ──────────────────────────────────────────────────────────────────
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a001', true);

select pg_temp.want('season_weeks: two weeks both posted are two meetings, not four',
  (public.head_to_head('00000000-0000-4000-8000-00000000a002')->'facets'->'season_weeks'->>'meetings'), '2');
select pg_temp.want('season_weeks: Sam took one',
  (public.head_to_head('00000000-0000-4000-8000-00000000a002')->'facets'->'season_weeks'->>'wins'), '1');
select pg_temp.want('season_weeks: Jade took one',
  (public.head_to_head('00000000-0000-4000-8000-00000000a002')->'facets'->'season_weeks'->>'losses'), '1');
select pg_temp.want('the record sums the same rows: 1–1 in two',
  (public.head_to_head('00000000-0000-4000-8000-00000000a002')->'record')::text,
  '{"ties": 0, "wins": 1, "total": 2, "losses": 1}');
select pg_temp.want('the last five hold two meetings',
  (jsonb_array_length(public.head_to_head('00000000-0000-4000-8000-00000000a002')->'last_five'))::text, '2');

-- ── the grants hold ─────────────────────────────────────────────────────────
select pg_temp.want('head_to_head: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.head_to_head(uuid)'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  'authenticated');
select pg_temp.want('head_to_head: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.head_to_head(uuid)'::regprocedure and a.grantee = 0))::text, '0');

rollback;
