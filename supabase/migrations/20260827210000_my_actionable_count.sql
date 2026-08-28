-- ============================================================================
-- D104 / IOS-026 — push-contract §4: the badge counts ACTIONABLE items only.
--
--   pending buddy requests addressed to me
-- + open league / event invites addressed to me
-- + live rounds I am seated on (or started) that are still open
--
-- Never chat, never rounds. The phone calls this on foreground and after the
-- Requests screen, the invites banner, a live round or a lock-screen action,
-- and sets the app badge to the answer; the push function computes the same
-- three counts per recipient at send time. `auth.uid()`-scoped; a signed-out
-- caller reads 0. Phone side: `PushBadgeCountCall` in CupSeasonKit/Push —
-- Rpc.swift picks it up at the next snapshot refresh.
-- ============================================================================

create or replace function public.my_actionable_count()
returns integer
language sql stable security definer set search_path = public as $$
  select (
    (select count(*) from friendships f
      where f.addressee = auth.uid() and f.status = 'pending')
  + (select count(*) from member_invites mi
      where mi.profile_id = auth.uid() and mi.status = 'pending')
  + (select count(*) from live_rounds lr
      where lr.status in ('setup', 'live')
        and (exists (select 1 from live_round_players lp
                       join league_members mm on mm.id = lp.member_id
                      where lp.live_round_id = lr.id and mm.profile_id = auth.uid())
          or exists (select 1 from league_members sm
                      where sm.id = lr.started_by and sm.profile_id = auth.uid())
          or exists (select 1 from live_round_players gp
                      where gp.live_round_id = lr.id and gp.guest_profile_id = auth.uid())))
  )::integer;
$$;

revoke all on function public.my_actionable_count() from public, anon;
grant execute on function public.my_actionable_count() to authenticated;
