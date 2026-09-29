-- 20261211094500 · ASSERTIONS for home_dispatch's invitation item: it says
-- "See the terms before you’re in." (the product's contraction, the curly
-- apostrophe), and its verb and route are unchanged.
--
-- native_home() is stubbed INSIDE this transaction with one invitation, so the
-- real invitation branch of home_dispatch runs. Run against an ISOLATED
-- cluster only, after the full migration chain. Every check RAISES on a wrong
-- answer, and the transaction rolls back (the real native_home with it).
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

insert into auth.users (id, email) values ('00000000-0000-4000-8000-0000000017e5', 'invitee@fixture.test');
select set_config('sim.uid', '00000000-0000-4000-8000-0000000017e5', true);

create or replace function public.native_home() returns jsonb language sql stable as $$
  select jsonb_build_object(
    'profile', jsonb_build_object('rounds_count', 0),
    'memberships', '[]'::jsonb,
    'invites', jsonb_build_array(jsonb_build_object(
      'id', '00000000-0000-4000-8000-0000000017a1', 'inviter', 'Blake Sample',
      'container_name', 'The Fixture Derby', 'container_id', '00000000-0000-4000-8000-0000000017b1',
      'kind', 'league', 'created_at', '2026-09-28T12:00:00Z')))
$$;

create temp table t_item as
  select i from jsonb_array_elements(public.home_dispatch(21, current_date, array['afterplan.v1'])->'items') i
   where i->>'key' like 'invite:%';

select pg_temp.want('the invitation is on Home, once',
  (select count(*) from t_item)::text, '1');
select pg_temp.want('it says "you’re", as the product speaks',
  (select i->>'standfirst' from t_item), 'See the terms before you’re in.');
select pg_temp.want('the rest of the item is unchanged',
  (select concat_ws(' / ', i->>'eyebrow', i->>'headline', i->>'action', i->'route'->>'kind', i->>'tier') from t_item),
  'AN INVITATION / Blake put you on The Fixture Derby. / See the terms / invite / closing');
select pg_temp.want('no sentence on Home still says "before you are in"',
  (position('before you are in' in pg_get_functiondef('public.home_dispatch(integer,date,text[])'::regprocedure)) = 0)::text, 'true');

select pg_temp.want('home_dispatch: authenticated only',
  ((select coalesce(string_agg(a.grantee::regrole::text, ',' order by a.grantee::regrole::text), '')
     from pg_proc p, aclexplode(p.proacl) a
    where p.oid = 'public.home_dispatch(integer,date,text[])'::regprocedure and a.privilege_type = 'EXECUTE'
      and a.grantee::regrole::text in ('anon','authenticated')))::text,
  'authenticated');

rollback;
