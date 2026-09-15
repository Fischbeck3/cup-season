-- D362 · the receipt's lens, the counting rounds, the composer's counters —
-- run against the ISOLATED cluster only (tests/sim/sandbox on the simulation
-- branch, port 5471 in this session). Never against production: it inserts.
\set ON_ERROR_STOP on
begin;
-- three golfers: Sam in two leagues, Jade in one of them, Rex in the other
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000a001', 'sam@fixture.test'),
  ('00000000-0000-4000-8000-00000000a002', 'jade@fixture.test'),
  ('00000000-0000-4000-8000-00000000a003', 'rex@fixture.test');
update profiles set display_name = 'Sam Fixture', marker = 'saguaro', handle = 'samfx' where id = '00000000-0000-4000-8000-00000000a001';
update profiles set display_name = 'Jade Fixture', marker = 'azalea', handle = 'jadefx' where id = '00000000-0000-4000-8000-00000000a002';
update profiles set display_name = 'Rex Fixture', marker = 'flag', handle = 'rexfx' where id = '00000000-0000-4000-8000-00000000a003';

insert into leagues (id, name, code, commissioner_id, phase) values
  ('00000000-0000-4000-8000-00000000b001', 'Fellas', 'FELLA1', '00000000-0000-4000-8000-00000000a001', 'season'),
  ('00000000-0000-4000-8000-00000000b002', 'Sunday Cup', 'SUNDA1', '00000000-0000-4000-8000-00000000a001', 'season');
-- Fellas caps at 2 this month; the Sunday Cup is uncapped
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
update profiles set index_current = 12.0 where id = '00000000-0000-4000-8000-00000000a001';

-- Sam's rounds in September: three, so the third is bumped in the Fellas (cap 2) and counts in the Sunday Cup
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000a001', 84, 70.1, 120, '2026-09-01', 12.0, 18, 'Papago'),
  ('00000000-0000-4000-8000-00000000e002', '00000000-0000-4000-8000-00000000a001', 80, 70.1, 120, '2026-09-05', 12.0, 18, 'Aguila'),
  ('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000a001', 92, 70.1, 120, '2026-09-12', 12.0, 18, 'Encanto');
-- a backdated round posted later, into August
insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-00000000e004', '00000000-0000-4000-8000-00000000a001', 86, 70.1, 120, '2026-08-20', 12.0, 18, 'Encanto');

-- the receipt, as Sam (both leagues)
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a001', true), set_config('sim.role', 'authenticated', true);
\echo --- owner: contributions and the ambiguous scalars
select jsonb_array_length(round_card('00000000-0000-4000-8000-00000000e003')->'contributions') as lenses,
       round_card('00000000-0000-4000-8000-00000000e003')->>'points' as points_without_context,
       (select string_agg(c->>'league_name' || ':' || coalesce(c->>'month_rank','-') || '/' || coalesce(c->>'counting_cap','∞'), ' ')
          from jsonb_array_elements(round_card('00000000-0000-4000-8000-00000000e003')->'contributions') c) as per_lens;
\echo --- owner: explicit lens
select round_card('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000b001')->>'league_id' as chosen,
       round_card('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000b001')->>'month_rank' as rank_in_fellas,
       round_card('00000000-0000-4000-8000-00000000e003', '00000000-0000-4000-8000-00000000b002')->>'month_rank' as rank_in_sunday;
\echo --- the counting rounds, September, in the Fellas: e002 and e001 count, e003 bumped
select c->>'round_id' as round, c->>'counting' as counting, c->>'month_rank' as rank
  from jsonb_array_elements(counting_rounds('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000c001', '2026-09')->'rounds') c;
\echo --- the whole season includes the backdated August round
select jsonb_array_length(counting_rounds('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000c001')->'rounds') as season_rounds;
\echo --- the composer, on a date in September: Fellas cap 2 used 2 worst?, Sunday uncapped used 3
select c->>'league_name' as league, c->'counters'->>'cap' as cap, c->'counters'->>'used' as used, c->'counters'->>'worst' as worst
  from jsonb_array_elements(my_month_counters('2026-09-13')) c;

-- the receipt, as Jade (shares only the Fellas)
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a002', true), set_config('sim.role', 'authenticated', true);
\echo --- a viewer who shares one league sees one lens, and the scalars are that lens
select jsonb_array_length(round_card('00000000-0000-4000-8000-00000000e003')->'contributions') as lenses,
       round_card('00000000-0000-4000-8000-00000000e003')->>'league_id' as league,
       round_card('00000000-0000-4000-8000-00000000e003')->>'month_rank' as rank;
\echo --- Jade may read Sam's Fellas rounds but not Sam's Sunday Cup rounds
select jsonb_array_length(counting_rounds('00000000-0000-4000-8000-00000000d001', '00000000-0000-4000-8000-00000000c001', '2026-09')->'rounds') as fellas_ok;
do $$ begin
  perform counting_rounds('00000000-0000-4000-8000-00000000d003', '00000000-0000-4000-8000-00000000c002', '2026-09');
  raise exception 'Jade read the Sunday Cup';
exception when others then
  if sqlerrm like 'Jade read%' then raise; end if;
  raise notice 'refused as expected: %', sqlerrm;
end $$;
\echo --- a viewer with no shared league is refused the receipt
select set_config('sim.uid', '00000000-0000-4000-8000-00000000a003', true), set_config('sim.role', 'authenticated', true);
do $$ begin
  perform round_card('00000000-0000-4000-8000-00000000e001', '00000000-0000-4000-8000-00000000b001');
  raise notice 'Rex shares the Sunday Cup, so the receipt opens; its Fellas lens is withheld: %',
    (select count(*) from jsonb_array_elements(round_card('00000000-0000-4000-8000-00000000e001')->'contributions') c where c->>'league_name' = 'Fellas');
end $$;
rollback;
