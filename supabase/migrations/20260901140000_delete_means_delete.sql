-- ============================================================================
-- Cup Season — "Delete permanently" is currently the least accurate sentence
-- in the product
--
-- Read out of prod on 2026-09-01 rather than taken from the audit's summary,
-- because the summary got two details wrong (it said `ghin_number` survives —
-- it does not, H1b already nulls it).
--
-- What `delete_account()` actually does today, on the branch that essentially
-- everyone takes (any posted round is a "footprint", and prod has 211 rounds
-- across 30 onboarded profiles):
--
--   * nulls display_name/handle/city/home_course/marker/ghin_number, sets
--     discoverable='nobody' and stamps deleted_at            <- good
--   * deletes push_subscriptions (WEB push)                  <- good
--   * bans auth.users                                        <- good
--   * leaves `profiles.email`                                <- the address stays
--   * leaves `photo_path` AND every stored object            <- the FACE stays
--   * never touches `device_tokens` (APNs)                   <- THE PHONE KEEPS BUZZING
--
-- That last one is the one that matters. `device_tokens` has no cascade that
-- can fire, because the account is BANNED rather than deleted — so a golfer
-- who taps "Delete permanently" keeps receiving push notifications from a
-- product they just left. There is no way for them to make it stop.
--
-- `docs/ios/app-review-notes.md` tells Apple this path "removes the profile,
-- rounds and device tokens". Two of those three were untrue. Telling a
-- reviewer something the binary does not do is the cheapest possible way to
-- lose their benefit of the doubt on the paragraph that matters (5.3.4, the
-- pot) — so the fix is the behaviour, and the document follows it.
--
-- The email becomes a tombstone rather than NULL: `profiles.email` is NOT NULL,
-- and this schema already has a convention for "never mail this person" —
-- `%@cupseason.invalid`, which every send path already excludes (see
-- 20260725180000, 20260726100000, 20260727240000). `.invalid` is reserved by
-- RFC 2606 and can never route. HONEST LIMIT, stated so nobody claims more
-- later: the real address still exists in `auth.users`, which is the identity
-- system and cannot be deleted while the footprint holds. What this removes is
-- every product surface that reads an address.
-- ============================================================================

create or replace function public.delete_account()
returns void language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  has_footprint boolean;
  v_table text; v_constraint text;
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

  has_footprint :=
       exists (select 1 from rounds where profile_id = v)
    or exists (select 1 from season_adjustments sa join league_members m on m.id = sa.member_id
               where m.profile_id = v)
    or exists (select 1 from draft_picks dp join league_members m on m.id = dp.picked_by
               where m.profile_id = v)
    or exists (select 1 from live_round_players lp join league_members m on m.id = lp.member_id
               where m.profile_id = v
                 and exists (select 1 from live_round_players x
                             where x.live_round_id = lp.live_round_id and x.id <> lp.id));

  -- Every stored object this golfer owns lives under `media/<their id>/…`
  -- (avatars are `<id>/avatar.jpg`; round photos share the folder). One
  -- statement therefore reclaims the avatar AND every scorecard they ever
  -- uploaded — the leak the audit found, on both branches. It runs BEFORE the
  -- hard branch's `delete from auth.users` so that a failure there rolls the
  -- object rows back with everything else.
  delete from storage.objects where bucket_id = 'media' and name like v::text || '/%';

  if not has_footprint then
    begin
      delete from post_comments pc using league_members m
        where pc.member_id = m.id and m.profile_id = v;
      delete from posts p using league_members m
        where p.member_id = m.id and m.profile_id = v;
      delete from live_round_players lp using league_members m
        where lp.member_id = m.id and m.profile_id = v;
      delete from live_rounds lr using league_members m
        where lr.started_by = m.id and m.profile_id = v;
      update live_round_players set claimed_profile = null where claimed_profile = v;
      delete from feedback f using league_members m
        where f.member_id = m.id and m.profile_id = v;
      update squads s set captain_member_id = null
        from league_members m
        where s.captain_member_id = m.id and m.profile_id = v;
      delete from posts        where league_id in (select id from leagues where commissioner_id = v);
      delete from live_rounds  where league_id in (select id from leagues where commissioner_id = v);
      delete from leagues where commissioner_id = v;
      delete from events  where created_by = v;
      delete from member_invites where invited_by = v or profile_id = v;
      update courses set created_by = null where created_by = v;
      delete from device_tokens where profile_id = v;   -- no cascade reaches these
      delete from auth.users where id = v;
      return;
    exception when others then
      get stacked diagnostics v_table = table_name, v_constraint = constraint_name;
      raise exception 'Could not delete your account: something still references it (%.%). Nothing was changed — screenshot this and send it in via Feedback.',
        coalesce(nullif(v_table, ''), 'unknown table'), coalesce(nullif(v_constraint, ''), 'unknown constraint');
    end;
  end if;

  update profiles set
    display_name = 'Former member',
    handle       = null,
    city         = null,
    home_course  = null,
    marker       = null,
    ghin_number  = null,     -- H1b: don't leave a departed member's GHIN readable
    photo_path   = null,     -- the face comes off the roster with the name
    email        = 'deleted+' || v::text || '@cupseason.invalid',
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  delete from push_subscriptions where profile_id = v;   -- web push
  delete from device_tokens      where profile_id = v;   -- APNs: the phone stops

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;

-- ---- a deleted round takes its photograph with it -------------------------
-- `delete_round` was two statements and touched no storage, so a golfer who
-- deleted a round they had photographed left the photograph behind, signed-URL
-- reachable by anyone who had ever been handed a link. Prod already carries
-- orphans from this.
create or replace function public.delete_round(p_round uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_path text;
begin
  select photo_path into v_path from rounds
   where id = p_round and profile_id = auth.uid();

  delete from rounds where id = p_round and profile_id = auth.uid();
  if not found then raise exception 'not your round to delete'; end if;

  if v_path is not null and v_path <> '' then
    delete from storage.objects where bucket_id = 'media' and name = v_path;
  end if;
end $$;

revoke all on function public.delete_account() from public, anon;
revoke all on function public.delete_round(uuid) from public, anon;
grant execute on function public.delete_account() to authenticated;
grant execute on function public.delete_round(uuid) to authenticated;

-- ---- self-enforcing -------------------------------------------------------
do $$
declare src text;
begin
  select prosrc into src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'delete_account';
  if src not like '%device_tokens%' then
    raise exception '[delete] delete_account does not clear device_tokens — the phone would keep buzzing';
  end if;
  if src not like '%storage.objects%' then
    raise exception '[delete] delete_account does not reclaim stored objects';
  end if;
  if src not like '%cupseason.invalid%' then
    raise exception '[delete] delete_account leaves the email address in place';
  end if;
end $$;
