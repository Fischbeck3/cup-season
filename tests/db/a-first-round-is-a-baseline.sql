-- X39 · D399 · ASSERTIONS for "a first round is a baseline": the board's
-- debut headline claims no barrier, every threshold is still minted, a later
-- round still gets its barrier headline, and a personal best needs a prior
-- round on the re-derive path too. Run against an ISOLATED cluster only (it
-- inserts), after the full migration chain. Every check RAISES on a wrong
-- answer. Synthetic cast only (tests/fixtures/ten/cast.mjs).
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

-- the trophy case of one golfer, as one comparable string: kind@round
create or replace function pg_temp.case_of(p uuid) returns text
language sql as $$
  select coalesce(string_agg(a.kind || '@' || coalesce(right(a.round_id::text, 3), 'none'), ',' order by a.kind), '')
    from achievements a where a.profile_id = p;
$$;

-- ── the fixture: three golfers in one solo league with a live season ───────
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000a391', 'devon.testwell@example.invalid'),
  ('00000000-0000-4000-8000-00000000a392', 'casey.placeholder@example.invalid'),
  ('00000000-0000-4000-8000-00000000a393', 'emery.mockridge@example.invalid');
update profiles set display_name = 'Devon Testwell',    marker = 'island',   handle = 'devonx39', index_current = 14.0 where id = '00000000-0000-4000-8000-00000000a391';
update profiles set display_name = 'Casey Placeholder', marker = 'lonetree', handle = 'caseyx39', index_current = 18.0 where id = '00000000-0000-4000-8000-00000000a392';
update profiles set display_name = 'Emery Mockridge',   marker = 'dunes',    handle = 'emeryx39', index_current = 10.0 where id = '00000000-0000-4000-8000-00000000a393';
insert into leagues (id, name, code, commissioner_id, phase) values
  ('00000000-0000-4000-8000-00000000b391', 'Baseline League (fixture)', 'BASEX9', '00000000-0000-4000-8000-00000000a391', 'season');
insert into league_settings (league_id) values ('00000000-0000-4000-8000-00000000b391') on conflict do nothing;
update league_settings set structure = 'solo' where league_id = '00000000-0000-4000-8000-00000000b391';
insert into seasons (id, league_id, number, starts_on, ends_on, status) values
  ('00000000-0000-4000-8000-00000000c391', '00000000-0000-4000-8000-00000000b391', 1, '2026-01-01', '2026-12-31', 'active');
insert into league_members (id, league_id, profile_id, role) values
  ('00000000-0000-4000-8000-00000000d391', '00000000-0000-4000-8000-00000000b391', '00000000-0000-4000-8000-00000000a391', 'commissioner'),
  ('00000000-0000-4000-8000-00000000d392', '00000000-0000-4000-8000-00000000b391', '00000000-0000-4000-8000-00000000a392', 'player'),
  ('00000000-0000-4000-8000-00000000d393', '00000000-0000-4000-8000-00000000b391', '00000000-0000-4000-8000-00000000a393', 'player');

-- ── 1 · Devon's debut: an 18-hole 85, through the insert the trigger hangs on
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e391', '00000000-0000-4000-8000-00000000a391', 85, 72.0, 113, '2026-09-01', 14.0, 18, 'Papago (fixture)');

select pg_temp.want('debut: the round posts its own story to the board',
  (select string_agg(body, ' | ') from posts
    where round_id = '00000000-0000-4000-8000-00000000e391' and kind = 'round'),
  'Devon posted 85 at Papago (fixture).');
select pg_temp.want('debut: no moment claims a barrier on a first round',
  (select count(*) from posts
    where round_id = '00000000-0000-4000-8000-00000000e391' and kind = 'moment')::text, '0');
select pg_temp.want('debut: nothing on the board says "for the first time" or "broke"',
  (select count(*) from posts
    where round_id = '00000000-0000-4000-8000-00000000e391'
      and (body ilike '%for the first time%' or body ilike '%broke%'))::text, '0');
select pg_temp.want('debut: every threshold is still minted, with no personal best',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a391'),
  'first_round@391,sub_100@391,sub_90@391');

-- ── 2 · Devon's second round breaks 80: the barrier headline is earned ─────
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e392', '00000000-0000-4000-8000-00000000a391', 78, 72.0, 113, '2026-09-08', 14.0, 18, 'Papago (fixture)');

select pg_temp.want('second round: the board keeps the barrier headline',
  (select string_agg(body, ' | ') from posts
    where round_id = '00000000-0000-4000-8000-00000000e392' and kind = 'moment'),
  'Devon broke 80 for the first time — a 78. That one goes on the wall.');
select pg_temp.want('second round: Broke 80 and the personal best land on it',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a391'),
  'first_round@391,personal_best@392,sub_100@391,sub_80@392,sub_90@391');

-- ── 3 · delete it: the re-derive leaves a lone round, and no personal best ─
delete from rounds where id = '00000000-0000-4000-8000-00000000e392';
select pg_temp.want('lone round after a delete: no personal best',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a391'),
  'first_round@391,sub_100@391,sub_90@391');

-- (one statement per round: an AFTER ROW trigger in a multi-row insert sees
--  every row of the statement, so a batch has no "first" round)
-- ── 4 · Casey: three rounds, the best one deleted — the PB comes back on the
--        round that beat the one before it
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e393', '00000000-0000-4000-8000-00000000a392', 95, 72.0, 113, '2026-09-01', 18.0, 18, 'Aguila (fixture)');
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e394', '00000000-0000-4000-8000-00000000a392', 90, 72.0, 113, '2026-09-08', 18.0, 18, 'Aguila (fixture)');
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e395', '00000000-0000-4000-8000-00000000a392', 85, 72.0, 113, '2026-09-15', 18.0, 18, 'Aguila (fixture)');
select pg_temp.want('Casey forward: the personal best is the latest record',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a392'),
  'first_round@393,personal_best@395,sub_100@393,sub_90@395');
delete from rounds where id = '00000000-0000-4000-8000-00000000e395';
select pg_temp.want('two rounds after a delete: the personal best is re-derived',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a392'),
  'first_round@393,personal_best@394,sub_100@393');

-- ── 5 · Emery: the first round is the best, and a later one only ties it ───
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e396', '00000000-0000-4000-8000-00000000a393', 80, 72.0, 113, '2026-09-01', 10.0, 18, 'Encanto (fixture)');
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e397', '00000000-0000-4000-8000-00000000a393', 88, 72.0, 113, '2026-09-08', 10.0, 18, 'Encanto (fixture)');
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e398', '00000000-0000-4000-8000-00000000a393', 80, 72.0, 113, '2026-09-15', 10.0, 18, 'Encanto (fixture)');
select pg_temp.want('Emery debut 80: no barrier headline either',
  (select count(*) from posts
    where round_id = '00000000-0000-4000-8000-00000000e396' and kind = 'moment')::text, '0');
select pg_temp.want('Emery forward: nothing beat the first round, so no personal best',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a393'),
  'first_round@396,sub_100@396,sub_90@396');
select public.rederive_achievements('00000000-0000-4000-8000-00000000a393');
select pg_temp.want('Emery re-derived: the first round is not a PB, and a tie is not one',
  pg_temp.case_of('00000000-0000-4000-8000-00000000a393'),
  'first_round@396,sub_100@396,sub_90@396');

-- ── 6 · the grants and the trigger hold ─────────────────────────────────────
select pg_temp.want('round_moments: anon cannot execute',
  has_function_privilege('anon', 'public.round_moments()', 'EXECUTE')::text, 'false');
select pg_temp.want('round_moments: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
     where p.oid = 'public.round_moments()'::regprocedure and a.grantee = 0)
   + (select count(*) from pg_proc p
       where p.oid = 'public.round_moments()'::regprocedure and p.proacl is null))::text, '0');
select pg_temp.want('rederive_achievements: no client role can execute',
  (has_function_privilege('anon', 'public.rederive_achievements(uuid)', 'EXECUTE')
   or has_function_privilege('authenticated', 'public.rederive_achievements(uuid)', 'EXECUTE'))::text, 'false');
select pg_temp.want('rederive_achievements: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
     where p.oid = 'public.rederive_achievements(uuid)'::regprocedure and a.grantee = 0)
   + (select count(*) from pg_proc p
       where p.oid = 'public.rederive_achievements(uuid)'::regprocedure and p.proacl is null))::text, '0');
select pg_temp.want('trg_round_moments still fires on rounds',
  (select count(*) from pg_trigger
    where tgname = 'trg_round_moments' and tgrelid = 'public.rounds'::regclass and not tgisinternal)::text, '1');

rollback;
