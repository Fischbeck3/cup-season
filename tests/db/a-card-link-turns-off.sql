-- X38 · D397 · "Turn off my card link" — ASSERTIONS for the server half that
-- ALREADY EXISTS, so both clients can build the control on it with no new RPC:
--   off  = revoke_share(<the golfer's live person token>), the token being what
--          create_share('person', me) returns (it answers the live token, and
--          mints only when there is none: shares_one_live allows one per golfer)
--   dead = share_info answers null (the landing says the link is dead, D57) and
--          redeem_share answers {kind: null} (no buddy request is minted)
--   on   = create_share('person', me) mints a NEW token; the old one never
--          answers again
-- Run against an ISOLATED cluster only (it inserts), after the full migration
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

-- ── the fixture: Blake shares a card link; Avery opens it; Casey is anybody
insert into auth.users (id, email) values
  ('00000000-0000-4000-8397-00000000c001', 'blake.card-off@fixture.test'),
  ('00000000-0000-4000-8397-00000000c002', 'avery.card-off@fixture.test'),
  ('00000000-0000-4000-8397-00000000c003', 'casey.card-off@fixture.test');
update profiles set display_name = 'Blake Sample',      marker = 'saguaro', handle = 'blakecardoff' where id = '00000000-0000-4000-8397-00000000c001';
update profiles set display_name = 'Avery Fixture',     marker = 'azalea',  handle = 'averycardoff' where id = '00000000-0000-4000-8397-00000000c002';
update profiles set display_name = 'Casey Placeholder', marker = 'saguaro', handle = 'caseycardoff' where id = '00000000-0000-4000-8397-00000000c003';

-- Blake, signed in, shares the card: one live token, and asking again returns it
select set_config('sim.uid', '00000000-0000-4000-8397-00000000c001', true);
select public.create_share('person', '00000000-0000-4000-8397-00000000c001') as tok1 \gset
select pg_temp.want('create_share returns the live card token again, never a second one',
  (public.create_share('person', '00000000-0000-4000-8397-00000000c001') = :'tok1'::uuid)::text, 'true');
select pg_temp.want('one live card link per golfer',
  (select count(*) from shares where kind = 'person' and created_by = '00000000-0000-4000-8397-00000000c001' and not revoked)::text, '1');
select pg_temp.want('the live link answers the stranger shape',
  (public.share_info(:'tok1')->>'kind'), 'person');

-- somebody else cannot turn Blake's link off
select set_config('sim.uid', '00000000-0000-4000-8397-00000000c003', true);
select pg_temp.want('revoke_share by anybody but the golfer changes nothing',
  (public.revoke_share(:'tok1'))::text, 'false');
select pg_temp.want('and the link still answers',
  (public.share_info(:'tok1') is not null)::text, 'true');

-- Blake turns it off
select set_config('sim.uid', '00000000-0000-4000-8397-00000000c001', true);
select pg_temp.want('turn off: revoke_share(the live token) answers true',
  (public.revoke_share(:'tok1'))::text, 'true');
select pg_temp.want('turn off twice: nothing left to turn off',
  (public.revoke_share(:'tok1'))::text, 'false');
select pg_temp.want('off: no live card link is left',
  (select count(*) from shares where kind = 'person' and created_by = '00000000-0000-4000-8397-00000000c001' and not revoked)::text, '0');

-- what the old link shows now, to a stranger and to a golfer who opens it
set local role anon;
select coalesce((public.share_info(:'tok1'))::text, '<null>') as anon_dead \gset
reset role;
select pg_temp.want('off: the landing (anon) answers null, the dead-link card (D57)', :'anon_dead', '<null>');
select set_config('sim.uid', '00000000-0000-4000-8397-00000000c002', true);
select pg_temp.want('off: a golfer who redeems the old link gets the dead answer',
  (public.redeem_share(:'tok1'))::text, '{"kind": null}');
select pg_temp.want('off: and no buddy request was minted',
  (select count(*) from friendships
    where (requester = '00000000-0000-4000-8397-00000000c002' and addressee = '00000000-0000-4000-8397-00000000c001')
       or (requester = '00000000-0000-4000-8397-00000000c001' and addressee = '00000000-0000-4000-8397-00000000c002'))::text, '0');

-- Blake turns it back on: a NEW link; the old one stays dead
select set_config('sim.uid', '00000000-0000-4000-8397-00000000c001', true);
select public.create_share('person', '00000000-0000-4000-8397-00000000c001') as tok2 \gset
select pg_temp.want('on again: a new token, not the old one',
  (:'tok2'::uuid <> :'tok1'::uuid)::text, 'true');
select pg_temp.want('on again: the new link answers',
  (public.share_info(:'tok2')->>'name'), 'Blake Sample');
select pg_temp.want('on again: the old link never answers again',
  (public.share_info(:'tok1') is null)::text, 'true');

-- ── the grants the control relies on (D37) ─────────────────────────────────
select pg_temp.want('create_share and revoke_share: authenticated only, never anon or PUBLIC',
  (select string_agg(p.proname || '=' || coalesce((select string_agg(a.grantee::regrole::text, '+' order by a.grantee::regrole::text)
                                             from aclexplode(p.proacl) a
                                            where a.privilege_type = 'EXECUTE'
                                              and (a.grantee = 0 or a.grantee::regrole::text in ('anon','authenticated'))), ''), ',' order by p.proname)
     from pg_proc p where p.oid in ('public.create_share(text,uuid)'::regprocedure, 'public.revoke_share(uuid)'::regprocedure)),
  'create_share=authenticated,revoke_share=authenticated');

rollback;
