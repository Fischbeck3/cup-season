-- D351 · the terms reach the golfer on every door into a league.
--
-- Joining by CODE passes the covenant on both clients, at every stake including
-- $0. Accepting an INVITATION does not, because `join_covenant_info` keys on the
-- league CODE and an invitation does not carry one: `my_invites` returns
-- `container_id`, and `leagues_read` restricts SELECT on `leagues` to members and
-- the commissioner, with no invitee arm. So an invited golfer cannot look the
-- code up, and a $50 season can be accepted with the stake never shown.
--
-- This is a NEW NAME, deliberately, not a new argument on `join_covenant_info`.
-- A defaulted argument beside an existing one-argument function makes every
-- current caller fail `is not unique` — positional, named and no-arg alike,
-- proven on PostgreSQL 17 (docs/reviews/2026-09-12-after-golf-contract-review.md
-- §1). Nothing existing is dropped, so no ACL is discarded.
--
-- It returns the SAME object `join_covenant_info` returns, and resolves the
-- league only through an invitation that is the caller's own and still pending.
-- It does NOT return the league code: the covenant is the golfer's to read, the
-- code is the Pro's to share.
--
-- Not deployed by this change.

create or replace function public.join_covenant_for_invite(p_invite uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure,
    'has_pay_note', (ls.buy_in_note is not null),
    'buy_in_due_on', ls.buy_in_due_on,
    'phase',       l.phase)
  from member_invites mi
  join leagues l          on l.id = mi.league_id
  join league_settings ls on ls.league_id = l.id
  where mi.id = p_invite
    and mi.profile_id = auth.uid()   -- somebody else's invitation is not a door
    and mi.status = 'pending'
  limit 1;
$function$;

-- D37 · every new function declares its own grants. `anon` never: an invitation
-- is addressed to a signed-in golfer, and this reads league settings.
revoke all on function public.join_covenant_for_invite(uuid) from public, anon;
grant execute on function public.join_covenant_for_invite(uuid) to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare n int;
begin
  select count(*) into n from pg_proc
   where proname = 'join_covenant_for_invite' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'join_covenant_for_invite must resolve to exactly one function, found %', n; end if;

  select count(*) into n from pg_proc
   where proname = 'join_covenant_info' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'join_covenant_info must still resolve to exactly one function, found %', n; end if;

  if has_function_privilege('anon', 'public.join_covenant_for_invite(uuid)', 'execute') then
    raise exception 'anon must not execute join_covenant_for_invite';
  end if;
  if not has_function_privilege('authenticated', 'public.join_covenant_for_invite(uuid)', 'execute') then
    raise exception 'authenticated must execute join_covenant_for_invite';
  end if;
end $check$;
