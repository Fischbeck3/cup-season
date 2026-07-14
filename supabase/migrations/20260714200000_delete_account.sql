-- Self-service account deletion — the fantasy-app-correct way: SOFT delete.
--
-- A hard delete (cascade off the profile) would vaporize a departing player's
-- counting rounds and pot/ledger entries, silently shifting everyone else's
-- standings and breaking the money math. So instead we TOMBSTONE: strip the
-- PII and revoke login, but KEEP the profile row and all competition data.
--
-- Because the profile row survives, every FK that points at it stays valid
-- (leagues.commissioner_id, events.created_by, member_invites.invited_by,
-- courses.created_by, friendships, rounds) — nothing to tear down, nothing
-- orphaned. Views render the scrubbed display_name "Former member" for free.
--
-- Policy (pilot): blocked while you run a league or event that OTHER people
-- are in — hand it off or delete it first. Solo leagues you own just persist
-- harmlessly under the tombstone.

alter table public.profiles add column if not exists deleted_at timestamptz;

create or replace function public.delete_account() returns void
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid();
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

  -- Revoke login without deleting the auth row — deleting it would cascade the
  -- profile (and all its competition rows) away, defeating the whole point.
  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
