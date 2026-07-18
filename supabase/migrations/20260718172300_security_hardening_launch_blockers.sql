-- ============================================================================
-- Security hardening — launch blockers (principal-engineer audit 2026-07-18,
-- see spec/launch-audit-2026-07-18.md). Every fix here is surgical: DROP POLICY,
-- REVOKE, or widen a CHECK. No behavioral rewrites live in this file (those ride
-- in the companion medium-hardening migration). Ordered so the two functional
-- time bombs (REL-C1, REL-C2) are unbroken in the same push.
--
-- Verified against source before writing: the client never issues a direct
-- UPDATE on league_members or rounds (C1/C2 policies are dead weight it doesn't
-- use); it calls 60 RPCs, all as `authenticated` (so revoking `anon` can't
-- touch a signed-in user); the only anon-facing endpoints are the four re-granted
-- below; and no client profile read selects `email` (it reads email from the
-- auth session, never the table).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- C1 · Any member could self-promote to commissioner.
--   members_self was FOR UPDATE USING (profile_id = auth.uid()) with no
--   WITH CHECK and GRANT ALL — so a member could PATCH their own row's `role`
--   to 'commissioner' (is_commissioner reads exactly this column), or hop
--   `league_id`. There is no legitimate client-side UPDATE on this table:
--   index moves through set_member_index, byes through set_member_bye, the
--   Pro role through transfer_pro — all security-definer RPCs. Drop it.
-- ---------------------------------------------------------------------------
drop policy if exists "members_self" on public.league_members;

-- ---------------------------------------------------------------------------
-- C2 · Owners could directly rewrite their rounds (forges points; breaks the
--   §16 promise "rounds are never mutated"). rounds_owner_update let a member
--   PATCH differential/index_at_post/played_on/attested on a posted round, and
--   there is no UPDATE trigger to re-derive them. Deletion already flows through
--   delete_round(); there is no legitimate direct update. Drop it.
-- ---------------------------------------------------------------------------
drop policy if exists "rounds_owner_update" on public.rounds;

-- ---------------------------------------------------------------------------
-- C3 · Season-lifecycle RPCs were GRANTed to anon + authenticated but written
--   for pg_cron with no in-body caller check — any member could end a season,
--   force a cup final, or early-close a month. The client calls NONE of these
--   (verified against the 60-RPC surface); pg_cron runs as `postgres` and is
--   unaffected by role grants. Revoke from both API roles.
-- ---------------------------------------------------------------------------
revoke execute on function public.close_season(uuid)        from anon, authenticated;
revoke execute on function public.close_month(uuid, date)   from anon, authenticated;
revoke execute on function public.enter_cup_final(uuid)     from anon, authenticated;
revoke execute on function public.daily_season_tick()       from anon, authenticated;
revoke execute on function public.run_month_closes()        from anon, authenticated;
revoke execute on function public.run_week_snapshots()      from anon, authenticated;
revoke execute on function public.snapshot_week(uuid)       from anon, authenticated;
revoke execute on function public.run_event_sessions()      from anon, authenticated;

-- ---------------------------------------------------------------------------
-- C5 (+ C4) · Default privileges auto-granted EXECUTE on every function to anon
--   and authenticated, so "not granted" functions were in fact callable and
--   `revoke ... from public` didn't help. This is also what made the Ryder
--   engine's `if auth.uid() is not null and not organizer` guard bypassable by
--   anon (anon has auth.uid() = null, so it skipped the check).
--
--   Fix in three moves:
--     1. Stop the bleed forward: future functions are NOT auto-granted.
--     2. Revoke EXECUTE on everything from anon, then re-grant ONLY the four
--        genuine anon endpoints. This alone closes C4: once anon cannot reach
--        resolve_session/generate_pairings, the only caller with auth.uid()=null
--        is cron (postgres), so the existing guard becomes correct, and
--        authenticated organizers still pass it.
--     3. Revoke the named authenticated casualties that should never have been
--        callable (event_post forges 'system' event-board posts).
--   authenticated keeps its existing grants on the 60 real RPCs (ALTER DEFAULT
--   PRIVILEGES is forward-only), so signed-in users are unaffected.
-- ---------------------------------------------------------------------------
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated;

revoke execute on all functions in schema public from anon;
grant  execute on function public.claim_round_info(uuid) to anon;
grant  execute on function public.scan_claim_info(uuid)  to anon;
grant  execute on function public.league_by_code(text)   to anon;
grant  execute on function public.founder_id()           to anon;

revoke execute on function public.event_post(uuid, text) from anon, authenticated;

-- ---------------------------------------------------------------------------
-- H1 · Every authenticated user could read every profile's email + GHIN.
--   profiles_read USING(true) OR-combined over the scoped policies and won.
--   Drop it; keep self + league-mate reads; add an event-mate read so the one
--   cross-league embed (event rosters) still resolves. Then hard-revoke the
--   `email` column from the API roles entirely — the client reads its own email
--   from the auth session, never from this table (verified), and security-definer
--   RPCs query as owner so they're unaffected. Email is now unreadable via the
--   Data API by any user; GHIN is readable only to people you share a league or
--   event with (down from "everyone").
-- ---------------------------------------------------------------------------
drop policy if exists "profiles_read" on public.profiles;

create policy "profiles_event_read" on public.profiles
  for select to authenticated
  using (exists (
    select 1 from event_players a
    join event_players b on b.event_id = a.event_id
    where a.profile_id = auth.uid() and b.profile_id = profiles.id));

revoke select (email) on public.profiles from anon, authenticated;

-- ---------------------------------------------------------------------------
-- H1b · delete_account tombstone scrubbed name/handle/city but left GHIN
--   readable to a departed member's league-mates. Same signature, pure
--   create-or-replace; only the tombstone UPDATE changes (adds ghin_number =
--   null). Body is otherwise identical to 20260717205347.
-- ---------------------------------------------------------------------------
create or replace function public.delete_account() returns void
language plpgsql security definer set search_path = public as $$
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
    discoverable = 'nobody',
    deleted_at   = now()
  where id = v;

  delete from push_subscriptions where profile_id = v;

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;
revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;

-- ---------------------------------------------------------------------------
-- H3 · Legacy finish_live_round(uuid) (the 1-arg version) was never dropped
--   when the engine moved to the 4-arg (uuid, jsonb, boolean, jsonb) form.
--   It's unguarded, anon-granted, references dropped columns, and can flip a
--   scoreless live round to 'final' — bricking a group's active round. The
--   current 4-arg version (what the client calls) is untouched. Drop the legacy.
-- ---------------------------------------------------------------------------
drop function if exists public.finish_live_round(uuid);

-- ---------------------------------------------------------------------------
-- REL-C1 · TIME BOMB: close_month inserts kind = 'floor_forfeit' and the
--   'month_closed' sentinel, but season_adjustments_kind_check forbade both —
--   so every monthly close aborted and rolled back (first firing Aug 1, 2026).
--   Widen the constraint to the kinds the code actually writes.
-- ---------------------------------------------------------------------------
alter table public.season_adjustments drop constraint if exists season_adjustments_kind_check;
alter table public.season_adjustments add constraint season_adjustments_kind_check
  check (kind = any (array['floor_penalty','floor_forfeit','matchup_bonus','bye','override','month_closed']));

-- ---------------------------------------------------------------------------
-- REL-C2 · TIME BOMB: claim_scan_round inserts source = 'scan_claim' but
--   rounds_source_check allowed only 'quick'/'live' — so every scorecard-scan
--   foursome claim failed on first use. Widen it.
-- ---------------------------------------------------------------------------
alter table public.rounds drop constraint if exists rounds_source_check;
alter table public.rounds add constraint rounds_source_check
  check (source = any (array['quick','live','scan_claim']));
