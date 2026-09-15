-- D362 · ASSERTIONS for the receipt's lenses, the counting rounds, the
-- composer's counters and the grants. Run against the ISOLATED cluster only
-- (it inserts). Every check RAISES on a wrong answer; an unrelated error is
-- re-raised rather than swallowed as an expected denial.
\set ON_ERROR_STOP on
begin;

-- ONE helper, comparing TEXT, so an int/bigint/jsonb mix can never silently
-- pick a different overload or fail to resolve one.
create or replace function pg_temp.want(p_label text, p_got text, p_expect text) returns void
language plpgsql as $$
begin
  if p_got is distinct from p_expect then
    raise exception 'FAIL % — got %, expected %', p_label, coalesce(p_got, '<null>'), coalesce(p_expect, '<null>');
  end if;
  raise notice 'ok   %', p_label;
end $$;

-- the same check for the types the assertions actually compare, each handing
-- the text version its own rendering. Explicit overloads rather than
-- `anyelement`, because an int/bigint or jsonb/text mix silently fails to
-- resolve one polymorphic signature — which is how a "passing" probe file can
-- stop running half way down and still exit 0.
create or replace function pg_temp.want(p_label text, p_got jsonb, p_expect jsonb) returns void
language sql as $$ select pg_temp.want(p_label, p_got::text, p_expect::text) $$;
create or replace function pg_temp.want(p_label text, p_got boolean, p_expect boolean) returns void
language sql as $$ select pg_temp.want(p_label, p_got::text, p_expect::text) $$;
create or replace function pg_temp.want(p_label text, p_got integer, p_expect integer) returns void
language sql as $$ select pg_temp.want(p_label, p_got::text, p_expect::text) $$;
create or replace function pg_temp.want(p_label text, p_got bigint, p_expect bigint) returns void
language sql as $$ select pg_temp.want(p_label, p_got::text, p_expect::text) $$;
create or replace function pg_temp.want(p_label text, p_got numeric, p_expect numeric) returns void
language sql as $$ select pg_temp.want(p_label, p_got::text, p_expect::text) $$;

-- an EXPECTED refusal is one whose message is the one the function raises.
-- Anything else — a missing column, a type error, a permission slip — is a
-- failure of the test, not a pass, and is re-raised with its own text.
create or replace function pg_temp.want_refused(p_label text, p_sql text, p_message text) returns void
language plpgsql as $$
begin
  execute p_sql;
  raise exception 'FAIL % — the call was ALLOWED', p_label;
exception
  when others then
    if sqlerrm = format('FAIL %s — the call was ALLOWED', p_label) then raise; end if;
    if sqlerrm <> p_message then
      raise exception 'FAIL % — refused for the WRONG reason: % (expected %)', p_label, sqlerrm, p_message;
    end if;
    raise notice 'ok   % (refused: %)', p_label, sqlerrm;
end $$;

-- ── the fixture ────────────────────────────────────────────────────────────
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000a001', 'sam@fixture.test'),
  ('00000000-0000-4000-8000-00000000a002', 'jade@fixture.test'),
  ('00000000-0000-4000-8000-00000000a003', 'rex@fixture.test');
update profiles set display_name = 'Sam Fixture', marker = 'saguaro', handle = 'samfx', index_current = 12.0 where id = '00000000-0000-4000-8000-00000000a001';
update profiles set display_name = 'Jade Fixture', marker = 'azalea', handle = 'jadefx' where id = '00000000-0000-4000-8000-00000000a002';
update profiles set display_name = 'Rex Fixture', marker = 'flag', handle = 'rexfx' where id = '00000000-0000-4000-8000-00000000a003';

insert into leagues (id, name, code, commissioner_id, phase) values
  ('00000000-0000-4000-8000-00000000b001', 'Fellas', 'FELLA1', '00000000-0000-4000-8000-00000000a001', 'season'),
  ('00000000-0000-4000-8000-00000000b002', 'Sunday Cup', 'SUNDA1', '00000000-0000-4000-8000-00000000a001', 'season');
insert into league_settings (league_id) values ('00000000-0000-4000-8000-00000000b001'), ('00000000-0000-4000-8000-00000000b002') on conflict do nothing;
update league_settings set counting_cap = 2, structure = 'solo' where league_id = '00000000-0000-4000-8000-00000000b001';
update league_settings set counting_cap = null, structure = 'solo' where league_id = '00000000-0000-4000-8000-00000000b002';
insert into seasons (id, league_id, number, starts_on, ends_on, status) values
  ('00000000-0000-4000-8000-00000000c001', '00000000-0000-4000-8000-00000000b001', 1, '2026-01-01', '2026-12-31', 'active'),
  ('00000000-0000-4000-8000-00000000c002', '00000000-0000-4000-8000-00000000b002', 1, '2026-01-01', '2026-12-31', 'active');
insert into league_members (id, league_id, profile_id, role) values
  ('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000b001', '00000000-0000-4000-8000-00000000a001', 'commissioner'),
  ('00000000-0000-4000-8000-00000000d002', '00000000-0000-4000-8000-00000000b001', '00000000-0000-4000-8000-00000000a002', 'player'),
  ('00000000-0000-4000-8000-00000000d003', '00000000-0000-4000-8000-00000000b002', '00000000-0000-4000-8000-00000000a001', 'commissioner'),
  ('00000000-0000-4000-8000-00000000d004', '00000000-0000-4000-8000-00000000b002', '00000000-0000-4000-8000-00000000a003', 'player');

-- Sam: three September rounds (cap 2 in the Fellas → the worst is bumped there,
-- uncapped in the Sunday Cup) and one BACKDATED August round.
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000a001', 84, 70.1, 120, '2026-09-01', 12.0, 18, 'Papago'),
  ('00000000-0000-4000-8000-00000000e002', '00000000-0000-4000-8000-00000000a001', 80, 70.1, 120, '2026-09-05', 12.0, 18, 'Aguila'),
  ('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000a001', 92, 70.1, 120, '2026-09-12', 12.0, 18, 'Encanto'),
  ('00000000-0000-4000-8000-00000000e004', '00000000-0000-4000-8000-00000000a001', 86, 70.1, 120, '2026-08-20', 12.0, 18, 'Encanto');

-- ── the grants, read from the catalogue ────────────────────────────────────
select pg_temp.want('my_month_counters: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.my_month_counters(date)'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  ('authenticated')::text);
select pg_temp.want('counting_rounds: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.counting_rounds(uuid,uuid,text)'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  ('authenticated')::text);
select pg_temp.want('round_card: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.round_card(uuid,uuid)'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  ('authenticated')::text);
select pg_temp.want('round_card: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.round_card(uuid,uuid)'::regprocedure and a.grantee = 0))::text,
  (0::bigint)::text);
select pg_temp.want('the one-argument round_card is gone',
  ((select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'round_card' and p.pronargs = 1))::text,
  (0::bigint)::text);
select pg_temp.want('all three are SECURITY DEFINER',
  ((select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname in ('round_card','counting_rounds','my_month_counters') and p.prosecdef))::text,
  (3::bigint)::text);

-- signed out: no caller, no answer
select pg_temp.want_refused('round_card signed out',
  $$ select public.round_card('00000000-0000-4000-8000-00000000e001') $$, 'Sign in first');
select pg_temp.want_refused('counting_rounds signed out',
  $$ select public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001') $$, 'Sign in first');
select pg_temp.want('my_month_counters signed out is empty, not an error',
  (public.my_month_counters('2026-09-13'))::text, ('[]'::jsonb)::text);


-- ── as Sam, who is in both leagues ─────────────────────────────────────────
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a001', true);

select pg_temp.want('owner sees two lenses',
  (jsonb_array_length(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions'))::text,
  (2)::text);
select pg_temp.want('no context → points is null',
  (public.round_card('00000000-0000-4000-8000-00000000e003')->'points')::text,
  ('null'::jsonb)::text);
select pg_temp.want('no context → month_rank is null',
  (public.round_card('00000000-0000-4000-8000-00000000e003')->'month_rank')::text,
  ('null'::jsonb)::text);
select pg_temp.want('no context → league_id is null',
  (public.round_card('00000000-0000-4000-8000-00000000e003')->'league_id')::text,
  ('null'::jsonb)::text);
select pg_temp.want('no context → pvi falls back to the 100% figure',
  (round((public.round_card('00000000-0000-4000-8000-00000000e003')->>'pvi')::numeric, 1))::text,
  (round((select r.index_at_post - r.differential from rounds r where r.id='00000000-0000-4000-8000-00000000e003'), 1))::text);
select pg_temp.want('the lenses are ordered by league name',
  (select string_agg(c->>'league_name', ',' ) from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') with ordinality t(c, i)),
  'Fellas,Sunday Cup');

select pg_temp.want('the Fellas lens is bumped past the cap of 2',
  ((select (c->>'month_rank')::int > (c->>'counting_cap')::int
     from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c
    where c->>'league_name' = 'Fellas'))::text,
  (true)::text);
select pg_temp.want('the Sunday Cup lens is uncapped',
  ((select c->'counting_cap' from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c
    where c->>'league_name' = 'Sunday Cup'))::text,
  ('null'::jsonb)::text);
select pg_temp.want('every lens names its month',
  ((select bool_and(c->>'month' = '2026-09') from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c))::text,
  (true)::text);

-- the explicit lens selects, and it selects the RIGHT one
select pg_temp.want('p_league selects the Fellas',
  (public.round_card('00000000-0000-4000-8000-00000000e003','00000000-0000-4000-8000-00000000b001')->>'league_id')::text,
  ('00000000-0000-4000-8000-00000000b001')::text);
select pg_temp.want('the Fellas lens carries its own cap',
  ((public.round_card('00000000-0000-4000-8000-00000000e003','00000000-0000-4000-8000-00000000b001')->>'counting_cap')::int)::text,
  (2)::text);
select pg_temp.want('p_league selects the Sunday Cup',
  (public.round_card('00000000-0000-4000-8000-00000000e003','00000000-0000-4000-8000-00000000b002')->>'league_id')::text,
  ('00000000-0000-4000-8000-00000000b002')::text);
select pg_temp.want('the Sunday Cup lens has no cap',
  (public.round_card('00000000-0000-4000-8000-00000000e003','00000000-0000-4000-8000-00000000b002')->'counting_cap')::text,
  ('null'::jsonb)::text);
select pg_temp.want('a league the round does not count in selects nothing',
  (public.round_card('00000000-0000-4000-8000-00000000e003', gen_random_uuid())->'month_rank')::text,
  ('null'::jsonb)::text);

-- the one-argument call an older client makes still resolves
select pg_temp.want('the one-argument call resolves and carries every key build 905 reads',
  ((select bool_and(public.round_card('00000000-0000-4000-8000-00000000e001') ? k)
     from unnest(array['id','gross','holes_played','played_on','course_label','rating','slope','differential',
                       'index_at_post','index_provisional','provisional_round','playing_index','pvi','band',
                       'points','month_rank','counting_cap','source','attested','photo_path','live_round_id',
                       'profile_id','golfer','is_mine','played_with']) k))::text,
  (true)::text);
select pg_temp.want('a single-lens round fills the scalars for an older client',
  ((public.round_card('00000000-0000-4000-8000-00000000e001','00000000-0000-4000-8000-00000000b001')->>'month_rank')::int)::text,
  ((select month_rank from v_rounds_ranked where round_id='00000000-0000-4000-8000-00000000e001' and member_id='00000000-0000-4000-8000-00000000d001'))::text);

-- ── counting_rounds: the month, the season, the counting status ────────────
select pg_temp.want('September in the Fellas lists three rounds',
  (jsonb_array_length(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds'))::text,
  (3)::text);
select pg_temp.want('the month filter excludes the backdated August round',
  ((select bool_and(c->>'month' = '2026-09')
     from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds') c))::text,
  (true)::text);
select pg_temp.want('the whole season includes it',
  (jsonb_array_length(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001')->'rounds'))::text,
  (4)::text);
select pg_temp.want('cap 2 → exactly two of September counts',
  ((select count(*) from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds') c
    where (c->>'counting')::boolean))::text,
  (2::bigint)::text);
select pg_temp.want('the worst September round is the bumped one',
  ((select c->>'round_id' from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds') c
    where not (c->>'counting')::boolean))::text,
  ('00000000-0000-4000-8000-00000000e003')::text);
select pg_temp.want('counting matches month_rank against the cap, row by row',
  (select bool_and((c->>'counting')::boolean = ((c->>'month_rank')::int <= 2))
     from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds') c), true);

select pg_temp.want('every row carries a counting status',
  ((select bool_and(c ? 'counting' and jsonb_typeof(c->'counting') = 'boolean')
     from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001')->'rounds') c))::text,
  (true)::text);
select pg_temp.want('the uncapped season counts every round',
  ((select bool_and((c->>'counting')::boolean)
     from jsonb_array_elements(public.counting_rounds('00000000-0000-4000-8000-00000000d003','00000000-0000-4000-8000-00000000c002','2026-09')->'rounds') c))::text,
  (true)::text);
select pg_temp.want('the uncapped season reports its cap as null, and the key is present',
  public.counting_rounds('00000000-0000-4000-8000-00000000d003','00000000-0000-4000-8000-00000000c002')->'cap', 'null'::jsonb);

select pg_temp.want('the payload names the season it answered for',
  (public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->>'season_id')::text,
  ('00000000-0000-4000-8000-00000000c001')::text);
select pg_temp.want('a month with no rounds is an empty list, not an error',
  jsonb_array_length(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-01')->'rounds'), 0);

select pg_temp.want_refused('a member and a season from different leagues',
  $$ select public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c002') $$,
  'No such season for that member');

-- ── the composer's counters ────────────────────────────────────────────────
select pg_temp.want('two seasons answer for a September date',
  (jsonb_array_length(public.my_month_counters('2026-09-13')))::text,
  (2)::text);
select pg_temp.want('the Fellas counters: cap 2, two used',
  (select (c->'counters'->>'used')::int from jsonb_array_elements(public.my_month_counters('2026-09-13')) c where c->>'league_name' = 'Fellas'), 2);

select pg_temp.want('the Sunday Cup is uncapped and all three count',
  ((select (c->'counters'->>'used')::int from jsonb_array_elements(public.my_month_counters('2026-09-13')) c where c->>'league_name' = 'Sunday Cup'))::text,
  (3)::text);
select pg_temp.want('August answers for the backdated round''s month',
  ((select (c->'counters'->>'used')::int from jsonb_array_elements(public.my_month_counters('2026-08-25')) c where c->>'league_name' = 'Fellas'))::text,
  (1)::text);
select pg_temp.want('a date outside every season window answers with nothing',
  (public.my_month_counters('2025-06-01'))::text,
  ('[]'::jsonb)::text);

-- ── as Jade, who shares only the Fellas ────────────────────────────────────
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a002', true);
select pg_temp.want('a mate sharing one league sees exactly one lens',
  (jsonb_array_length(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions'))::text,
  (1)::text);
select pg_temp.want('and it is the shared one',
  (public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions'->0->>'league_name')::text,
  ('Fellas')::text);
select pg_temp.want('with one lens the scalars ARE that lens',
  ((public.round_card('00000000-0000-4000-8000-00000000e003')->>'counting_cap')::int)::text,
  (2)::text);
select pg_temp.want('the unshared league cannot be selected by naming it',
  (public.round_card('00000000-0000-4000-8000-00000000e003','00000000-0000-4000-8000-00000000b002')->'league_id')::text,
  ('null'::jsonb)::text);
select pg_temp.want('a mate may read the shared league''s rounds',
  (jsonb_array_length(public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001','2026-09')->'rounds'))::text,
  (3)::text);
select pg_temp.want_refused('a mate may NOT read the unshared league''s rounds',
  $$ select public.counting_rounds('00000000-0000-4000-8000-00000000d003','00000000-0000-4000-8000-00000000c002') $$,
  'Those rounds are not yours to read');
-- Jade IS in the Fellas and has posted nothing: her counters are her OWN, one
-- season, nothing used. (The first version of this assertion expected `[]` and
-- was wrong about the fixture — which is the assertion doing its job.)
select pg_temp.want('a mate''s counters are the mate''s own, not the round owner''s',
  (select c->'counters'->>'used' from jsonb_array_elements(public.my_month_counters('2026-09-13')) c
    where c->>'league_name' = 'Fellas'), '0');
select pg_temp.want('a season she has no rounds in reports no worst',
  (select c->'counters'->'worst' from jsonb_array_elements(public.my_month_counters('2026-09-13')) c
    where c->>'league_name' = 'Fellas'), 'null'::jsonb);
select pg_temp.want('she is in one season, not the owner''s two',
  jsonb_array_length(public.my_month_counters('2026-09-13')), 1);

-- ── as Rex, who shares only the Sunday Cup ─────────────────────────────────
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a003', true);
select pg_temp.want('Rex sees only the Sunday Cup lens',
  ((select string_agg(c->>'league_name', ',') from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c))::text,
  ('Sunday Cup')::text);
select pg_temp.want('the Fellas lens is withheld from him',
  ((select count(*) from jsonb_array_elements(public.round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c
    where c->>'league_name' = 'Fellas'))::text,
  (0::bigint)::text);

-- ── a stranger ─────────────────────────────────────────────────────────────
insert into auth.users (id, email) values ('00000000-0000-4000-8000-00000000a004', 'stranger@fixture.test');
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a004', true);
select pg_temp.want_refused('a stranger cannot read the round at all',
  $$ select public.round_card('00000000-0000-4000-8000-00000000e003') $$, 'That round is not yours to read');
select pg_temp.want_refused('a stranger cannot read the rounds that count',
  $$ select public.counting_rounds('00000000-0000-4000-8000-00000000d001','00000000-0000-4000-8000-00000000c001') $$,
  'Those rounds are not yours to read');

\echo ALL ASSERTIONS PASSED
rollback;
