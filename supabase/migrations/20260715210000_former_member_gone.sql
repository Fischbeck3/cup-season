-- "Folks that leave the app are gone gone" (pilot decision, 2026-07-15).
--
-- The tombstone (Former member) is REQUIRED for anyone with a competition
-- footprint: hard-deleting their rounds would shift everyone else's standings
-- and break the pot math. So the record stays. But a departed member should
-- vanish from every SOCIAL/SELECTION surface — the buddies list and the
-- add-to-league / add-to-event picker — not linger as a dead "Former member"
-- row you can't act on.
--
-- Three moves:
--   1. delete_account() tombstone path also DROPS the person's friendships, so
--      they immediately disappear from everyone's buddies (friendships carry no
--      competition consequence — safe to delete; the hard-delete path already
--      cascaded them away).
--   2. my_friends() + search_golfers() exclude tombstoned profiles (deleted_at
--      not null) — belt-and-suspenders, and covers accounts tombstoned before
--      this migration.
--   3. One-time backfill: clear friendships tied to already-deleted accounts.

-- 1. delete_account: tombstone path now clears the departing member's friendships
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
    -- No load-bearing data: clean hard delete so the email frees up.
    begin
      delete from leagues where commissioner_id = v;
      delete from events  where created_by = v;
      delete from member_invites where invited_by = v;
      update courses set created_by = null where created_by = v;
      delete from auth.users where id = v;              -- cascades profile + friendships + the rest
      return;
    exception when others then
      null;   -- something still referenced the profile; fall through to tombstone
    end;
  end if;

  -- Tombstone: scrub PII, keep the row + all competition/ledger data.
  update profiles set
    display_name = 'Former member',
    handle       = null,
    city         = null,
    home_course  = null,
    marker       = null,
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  -- gone gone from everyone's social graph (friendships carry no competition
  -- weight; their rounds/pot/standings stay under the tombstone).
  delete from friendships where requester = v or addressee = v;
  delete from push_subscriptions where profile_id = v;

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;

-- 2a. my_friends: never surface a tombstoned profile
create or replace function public.my_friends()
returns table (friendship_id uuid, profile_id uuid, handle text, display_name text,
               city text, marker text, index_current numeric, status text, incoming boolean)
language sql stable security definer set search_path = public as $$
  select f.id, p.id, p.handle, p.display_name, p.city, p.marker, p.index_current,
         f.status, (f.addressee = auth.uid())
  from friendships f
  join profiles p
    on p.id = case when f.requester = auth.uid() then f.addressee else f.requester end
  where (f.requester = auth.uid() or f.addressee = auth.uid())
    and p.deleted_at is null
  order by (f.status = 'pending') desc, p.display_name;
$$;

-- 2b. search_golfers: explicit tombstone exclusion (discoverable='nobody' already
--     hides them, but make it unmissable for future edits)
create or replace function public.search_golfers(p_q text)
returns table (profile_id uuid, handle text, display_name text, city text,
               home_course text, marker text, index_current numeric, rel text)
language sql stable security definer set search_path = public as $$
  select p.id, p.handle, p.display_name, p.city, p.home_course, p.marker,
         p.index_current,
    case
      when f.status = 'accepted' then 'friend'
      when f.status = 'pending' and f.requester = auth.uid() then 'requested'
      when f.status = 'pending' then 'incoming'
      else 'none' end
  from profiles p
  left join friendships f
    on least(f.requester, f.addressee)    = least(p.id, auth.uid())
   and greatest(f.requester, f.addressee) = greatest(p.id, auth.uid())
  where p.id <> auth.uid()
    and p.deleted_at is null
    and length(trim(p_q)) >= 2
    and (p.handle ilike replace(trim(p_q), '@', '') || '%'
         or p.display_name ilike '%' || trim(p_q) || '%')
    and (p.discoverable = 'everyone'
         or (p.discoverable = 'friends' and f.status = 'accepted'))
  order by (p.handle ilike replace(trim(p_q), '@', '') || '%') desc, p.display_name
  limit 10;
$$;

-- 3. one-time: clear links for anyone already tombstoned before this migration
delete from friendships f
  using profiles p
  where (f.requester = p.id or f.addressee = p.id)
    and p.deleted_at is not null;
