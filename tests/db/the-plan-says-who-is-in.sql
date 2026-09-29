-- W7-001 [X42] · ASSERTIONS for share_info's plan branch: the public card
-- counts only an explicit yes as in. `who_in` names the tagged golfers whose
-- round_rsvp.status is 'in'; `who` (every tag not out) is unchanged. Run
-- against an ISOLATED cluster only (it inserts), after the full migration
-- chain. Every check RAISES on a wrong answer, and the transaction rolls back.
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

-- ── the fixture: Blake hosts; Avery never answered, Casey said maybe, Devon
--    said yes, Jules said no, and Harper said yes and then deleted the account
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-00000000f001', 'blake@fixture.test'),
  ('00000000-0000-4000-8000-00000000f002', 'avery@fixture.test'),
  ('00000000-0000-4000-8000-00000000f003', 'casey@fixture.test'),
  ('00000000-0000-4000-8000-00000000f004', 'devon@fixture.test'),
  ('00000000-0000-4000-8000-00000000f005', 'jules@fixture.test'),
  ('00000000-0000-4000-8000-00000000f006', 'harper@fixture.test');
update profiles set display_name = 'Blake Sample',      marker = 'saguaro', handle = 'blakefx'  where id = '00000000-0000-4000-8000-00000000f001';
update profiles set display_name = 'Avery Fixture',     marker = 'azalea',  handle = 'averyfx'  where id = '00000000-0000-4000-8000-00000000f002';
update profiles set display_name = 'Casey Placeholder', marker = 'saguaro', handle = 'caseyfx'  where id = '00000000-0000-4000-8000-00000000f003';
update profiles set display_name = 'Devon Testwell',    marker = 'azalea',  handle = 'devonfx'  where id = '00000000-0000-4000-8000-00000000f004';
update profiles set display_name = 'Jules Mockup',      marker = 'saguaro', handle = 'julesfx'  where id = '00000000-0000-4000-8000-00000000f005';
update profiles set display_name = 'Harper Examplar',   marker = 'azalea',  handle = 'harperfx', deleted_at = now()
 where id = '00000000-0000-4000-8000-00000000f006';

insert into scheduled_rounds (id, profile_id, play_on, course_label, tagged) values
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f001', current_date + 5, 'Mesquite Wash (fixture)',
   array['00000000-0000-4000-8000-00000000f002', '00000000-0000-4000-8000-00000000f003', '00000000-0000-4000-8000-00000000f004',
         '00000000-0000-4000-8000-00000000f005', '00000000-0000-4000-8000-00000000f006']::uuid[]),
  -- a second plan: two tags, and nobody has answered yet
  ('00000000-0000-4000-8000-0000000fa002', '00000000-0000-4000-8000-00000000f001', current_date + 9, 'Papago (fixture)',
   array['00000000-0000-4000-8000-00000000f002', '00000000-0000-4000-8000-00000000f004']::uuid[]);
insert into round_rsvp (round_id, profile_id, status) values
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f001', 'in'),
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f003', 'maybe'),
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f004', 'in'),
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f005', 'out'),
  ('00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f006', 'in');
insert into shares (token, kind, ref_id, created_by) values
  ('00000000-0000-4000-8000-0000000fb001', 'plan', '00000000-0000-4000-8000-0000000fa001', '00000000-0000-4000-8000-00000000f001'),
  ('00000000-0000-4000-8000-0000000fb002', 'plan', '00000000-0000-4000-8000-0000000fa002', '00000000-0000-4000-8000-00000000f001');

-- ── the public landing: a stranger holding the link is anon. share_info is
--    SECURITY DEFINER, so its answer does not depend on the caller; the anon
--    call proves the door is open and reads the same, and every other
--    assertion reads it as the owner (pg_temp.want is not anon's to run).
set local role anon;
select coalesce((public.share_info('00000000-0000-4000-8000-0000000fb001')->'who_in')::text, '<missing>') as anon_who_in \gset
reset role;
select pg_temp.want('as anon (the public landing), who_in is an explicit yes', :'anon_who_in', '["Devon"]');

select pg_temp.want('who is unchanged: every live tag that has not said no',
  (public.share_info('00000000-0000-4000-8000-0000000fb001')->'who')::text,
  '["Avery", "Casey", "Devon"]');
select pg_temp.want('who_in is an explicit yes, and nothing else',
  (public.share_info('00000000-0000-4000-8000-0000000fb001')->'who_in')::text,
  '["Devon"]');
select pg_temp.want('an unanswered tag is on the plan, not in',
  ((public.share_info('00000000-0000-4000-8000-0000000fb001')->'who') ? 'Avery'
   and not (public.share_info('00000000-0000-4000-8000-0000000fb001')->'who_in') ? 'Avery')::text,
  'true');
select pg_temp.want('a maybe is on the plan, not in',
  ((public.share_info('00000000-0000-4000-8000-0000000fb001')->'who') ? 'Casey'
   and not (public.share_info('00000000-0000-4000-8000-0000000fb001')->'who_in') ? 'Casey')::text,
  'true');
select pg_temp.want('a deleted account that said yes is in neither',
  ((public.share_info('00000000-0000-4000-8000-0000000fb001')->'who_in') ? 'Harper'
   or (public.share_info('00000000-0000-4000-8000-0000000fb001')->'who') ? 'Harper')::text,
  'false');
select pg_temp.want('nobody answered: who_in is present and empty, never missing',
  (public.share_info('00000000-0000-4000-8000-0000000fb002')->'who_in')::text,
  '[]');
select pg_temp.want('nobody answered: both tags are still on the plan',
  (public.share_info('00000000-0000-4000-8000-0000000fb002')->'who')::text,
  '["Avery", "Devon"]');
select pg_temp.want('the rest of the card is unchanged',
  (select string_agg(k, ',' order by k) from jsonb_object_keys(public.share_info('00000000-0000-4000-8000-0000000fb001')) k),
  'course,host,kind,marker,play_on,who,who_in');
select pg_temp.want('a dead token still answers null (D57)',
  (public.share_info('00000000-0000-4000-8000-0000000fbfff') is null)::text, 'true');

-- ── the body was patched, not retyped; the grants hold ─────────────────────
select pg_temp.want('the [D385] photo patch survives',
  (position('[D385]' in pg_get_functiondef('public.share_info(uuid)'::regprocedure)) > 0)::text, 'true');
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
