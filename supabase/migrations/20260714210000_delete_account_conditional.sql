-- Conditional account deletion (supersedes the always-tombstone delete_account
-- from 20260714200000). Structure: delete frees your email UNLESS your scores
-- are load-bearing.
--
--   • No competition footprint (no posted rounds) -> HARD delete. The auth row
--     and profile are removed, cascades clean up memberships/friendships/subs,
--     and the email is immediately reusable for a fresh account. Owned solo
--     leagues/events (the guards above guarantee no other members), sent
--     invites, and course provenance are cleared first so the auth delete
--     isn't blocked by a non-cascade FK.
--   • Has posted rounds -> TOMBSTONE (scrub PII, revoke login, keep the row and
--     all competition/ledger data as "Former member"). Email is retired, so a
--     season's record is never disturbed.
--
-- The hard-delete path is wrapped: if any FK still blocks it, it rolls back to
-- the savepoint and falls through to the tombstone — deletion never fails.

create or replace function public.delete_account() returns void
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); has_footprint boolean;
begin
  if v is null then raise exception 'not signed in'; end if;

  if exists (
    select 1 from leagues l
    where l.commissioner_id = v
      and exists (select 1 from league_members m
                  where m.league_id = l.id and m.profile_id <> v)
  ) then
    raise exception 'You run a league with other players in it. Hand it off or delete that league first, then delete your account.';
  end if;

  if exists (
    select 1 from events e
    where e.created_by = v
      and exists (select 1 from event_players ep
                  where ep.event_id = e.id and ep.profile_id <> v)
  ) then
    raise exception 'You created an event with other players in it. Delete that event first, then delete your account.';
  end if;

  has_footprint := exists (select 1 from rounds where profile_id = v);

  if not has_footprint then
    -- No load-bearing data: try a clean hard delete so the email frees up.
    begin
      delete from leagues where commissioner_id = v;   -- solo (guard passed); cascades
      delete from events  where created_by = v;         -- solo; cascades
      delete from member_invites where invited_by = v;
      update courses set created_by = null where created_by = v;
      delete from auth.users where id = v;              -- cascades profile + the rest
      return;                                           -- done; email is reusable
    exception when others then
      null;   -- something still referenced the profile; fall through to tombstone
    end;
  end if;

  -- Tombstone: scrub PII, keep the row (and every competition/ledger row it
  -- anchors) so a departure never disturbs anyone else's season or pot.
  update profiles set
    display_name = 'Former member',
    handle       = null,
    city         = null,
    home_course  = null,
    marker       = null,
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  delete from push_subscriptions where profile_id = v;

  -- Revoke login without deleting the auth row (that would cascade the profile
  -- and its competition rows away).
  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
