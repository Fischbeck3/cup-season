-- X38 · D397 · ASSERTIONS for share_info's person and settlement branches: a
-- stranger holding a person link reads the stranger shape of D394 (a name, a
-- marker, rounds played), and a settlement link keeps the game public but not
-- who pays whom. Run against an ISOLATED cluster only (it inserts), after the
-- full migration chain. Every check RAISES on a wrong answer, and the
-- transaction rolls back.
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

-- ── the fixture: Blake has three rounds and a typed index; Avery has none;
--    Harper deleted the account. Blake started a settled match against two
--    guests, with a transfer on the result.
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000c001', 'blake@fixture.test'),
  ('00000000-0000-4000-8000-00000000c002', 'avery@fixture.test'),
  ('00000000-0000-4000-8000-00000000c006', 'harper@fixture.test');
update profiles set display_name = 'Blake Sample',    marker = 'saguaro', handle = 'blakefx', index_current = 14.2
 where id = '00000000-0000-4000-8000-00000000c001';
update profiles set display_name = 'Avery Fixture',   marker = 'azalea',  handle = 'averyfx', index_current = 22.0
 where id = '00000000-0000-4000-8000-00000000c002';
update profiles set display_name = 'Harper Examplar', marker = 'azalea',  handle = 'harperfx', deleted_at = now()
 where id = '00000000-0000-4000-8000-00000000c006';

insert into rounds (id, profile_id, gross, rating, slope, played_on, index_at_post, holes_played, course_label) values
  ('00000000-0000-4000-8000-0000000cd001', '00000000-0000-4000-8000-00000000c001', 88, 70.1, 120, current_date - 20, 14.2, 18, 'Papago (fixture)'),
  ('00000000-0000-4000-8000-0000000cd002', '00000000-0000-4000-8000-00000000c001', 84, 70.1, 120, current_date - 10, 14.2, 18, 'Encanto (fixture)'),
  ('00000000-0000-4000-8000-0000000cd003', '00000000-0000-4000-8000-00000000c001', 43, 34.9, 118, current_date - 3,  14.2,  9, 'Aguila (fixture)');

insert into live_rounds (id, course_label, course_snapshot, game, status, started_at, finished_at, game_result, starter_profile_id) values
  ('00000000-0000-4000-8000-0000000ce001', 'Longbow (fixture)', '{}'::jsonb, 'match', 'final',
   now() - interval '5 hours', now() - interval '1 hour',
   jsonb_build_object('side_a', 'Blake', 'side_b', 'Kit', 'status', '2&1', 'winner', 'a', 'stake', '5',
                      'story', 'Blake closed it on 17.',
                      'transfers', jsonb_build_array(jsonb_build_object('from', 'Kit', 'to', 'Blake', 'amt', 5)),
                      'holes', jsonb_build_object('1', 'a', '2', 'h')),
   '00000000-0000-4000-8000-00000000c001');
insert into live_round_players (live_round_id, guest_name, guest_gross, position) values
  ('00000000-0000-4000-8000-0000000ce001', 'Kit Fixture', 91, 0),
  ('00000000-0000-4000-8000-0000000ce001', 'Devon Testwell', 86, 1);

insert into shares (token, kind, ref_id, created_by) values
  ('00000000-0000-4000-8000-0000000cf001', 'person',     '00000000-0000-4000-8000-00000000c001', '00000000-0000-4000-8000-00000000c001'),
  ('00000000-0000-4000-8000-0000000cf002', 'person',     '00000000-0000-4000-8000-00000000c002', '00000000-0000-4000-8000-00000000c002'),
  ('00000000-0000-4000-8000-0000000cf006', 'person',     '00000000-0000-4000-8000-00000000c006', '00000000-0000-4000-8000-00000000c001'),
  ('00000000-0000-4000-8000-0000000cf101', 'settlement', '00000000-0000-4000-8000-0000000ce001', '00000000-0000-4000-8000-00000000c001');

-- ── the public landing is anon. share_info is SECURITY DEFINER, so its answer
--    does not depend on the caller; the anon call proves the door is open and
--    reads the same, and every other assertion reads it as the owner.
set local role anon;
select coalesce((select string_agg(k, ',' order by k)
                   from jsonb_object_keys(public.share_info('00000000-0000-4000-8000-0000000cf001')) k), '<null>') as anon_person_keys \gset
select coalesce((public.share_info('00000000-0000-4000-8000-0000000cf101')->'result' ? 'transfers')::text, '<null>') as anon_has_transfers \gset
reset role;
select pg_temp.want('as anon (the public landing), the person card is the stranger shape',
  :'anon_person_keys', 'kind,marker,name,rounds_n');
select pg_temp.want('as anon (the public landing), a settlement sends no transfers',
  :'anon_has_transfers', 'false');

-- the person branch: a name, a marker and rounds played, nothing else
select pg_temp.want('person: the name and the marker',
  (public.share_info('00000000-0000-4000-8000-0000000cf001')->>'name') || ' · ' ||
  (public.share_info('00000000-0000-4000-8000-0000000cf001')->>'marker'), 'Blake Sample · saguaro');
select pg_temp.want('person: rounds played counts every live round, the nine included',
  (public.share_info('00000000-0000-4000-8000-0000000cf001')->>'rounds_n'), '3');
select pg_temp.want('person: no index (D57, D394)',
  (public.share_info('00000000-0000-4000-8000-0000000cf001') ? 'index')::text, 'false');
select pg_temp.want('person: no best',
  (public.share_info('00000000-0000-4000-8000-0000000cf001') ? 'best')::text, 'false');
select pg_temp.want('person: no dated course rounds',
  (public.share_info('00000000-0000-4000-8000-0000000cf001') ? 'rounds')::text, 'false');
select pg_temp.want('person: no course name anywhere in the card',
  (public.share_info('00000000-0000-4000-8000-0000000cf001')::text like '%fixture)%')::text, 'false');
select pg_temp.want('person with no rounds: the stranger shape, rounds_n 0, no starter shown as an index',
  (select string_agg(k || '=' || (public.share_info('00000000-0000-4000-8000-0000000cf002')->>k), ',' order by k)
     from jsonb_object_keys(public.share_info('00000000-0000-4000-8000-0000000cf002')) k),
  'kind=person,marker=azalea,name=Avery Fixture,rounds_n=0');
select pg_temp.want('person: a deleted account still answers null',
  (public.share_info('00000000-0000-4000-8000-0000000cf006') is null)::text, 'true');

-- the settlement branch: the game is public, the money line is not
select pg_temp.want('settlement: the result keeps the game (sides, status, winner, stake, story, strip)',
  (select string_agg(k, ',' order by k) from jsonb_object_keys(public.share_info('00000000-0000-4000-8000-0000000cf101')->'result') k),
  'holes,side_a,side_b,stake,status,story,winner');
select pg_temp.want('settlement: the card keeps its game, course, date and players',
  (select string_agg(k, ',' order by k) from jsonb_object_keys(public.share_info('00000000-0000-4000-8000-0000000cf101')) k),
  'course,game,kind,played_on,players,result');
select pg_temp.want('settlement: the players and their grosses are unchanged',
  (public.share_info('00000000-0000-4000-8000-0000000cf101')->'players')::text,
  '[{"name": "Kit Fixture", "gross": 91}, {"name": "Devon Testwell", "gross": 86}]');
select pg_temp.want('settlement: no pays line anywhere in the payload',
  (public.share_info('00000000-0000-4000-8000-0000000cf101')::text like '%"amt"%')::text, 'false');
select pg_temp.want('a dead token still answers null (D57)',
  (public.share_info('00000000-0000-4000-8000-0000000cffff') is null)::text, 'true');

-- ── the body was patched, not retyped; the grants hold ─────────────────────
select pg_temp.want('the [D385] photo patch survives',
  (position('[D385]' in pg_get_functiondef('public.share_info(uuid)'::regprocedure)) > 0)::text, 'true');
select pg_temp.want('the [X42] plan patch survives',
  (position('[X42]' in pg_get_functiondef('public.share_info(uuid)'::regprocedure)) > 0)::text, 'true');
select pg_temp.want('share_info: anon and authenticated execute it',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.share_info(uuid)'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  'anon,authenticated');
select pg_temp.want('share_info: PUBLIC holds nothing',
  ((select count(*) from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.share_info(uuid)'::regprocedure and a.grantee = 0))::text, '0');

rollback;
