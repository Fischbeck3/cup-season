-- delete_account, made LOUD (task #33). The 20260714210000 version wrapped its
-- hard-delete in `exception when others then null` — any FK blocker silently
-- fell through to the tombstone, permanently retiring the email with zero
-- signal. That is how jerechofischbeck@gmail.com became a banned "Former
-- member" on 2026-07-14: the likeliest blockers are the twelve FKs into
-- league_members with no delete rule (posts.member_id, post_comments.member_id,
-- live_rounds.started_by, …) — chat once on a board with zero posted rounds and
-- your hard delete silently downgraded itself. Three changes:
--
--   1. "Load-bearing" is broader than posted rounds. Shared live-game records
--      (a Match/Wolf/Skins with anyone else in it), ledger rows
--      (season_adjustments), and draft picks are other people's history too —
--      those tombstone, never hard-delete.
--   2. The hard-delete path clears every KNOWN innocent anchor explicitly,
--      child-first (the wipe taught us cascade ordering is never guaranteed):
--      board voice, solo live rounds, feedback, captaincy, guest-claim
--      pointers, solo leagues' content, then the auth row.
--   3. If an UNKNOWN FK still blocks, the function RAISES with the table and
--      constraint name — the whole delete rolls back, the account stays whole
--      and usable, and the error names the next fix. Never a silent tombstone.
--
-- Same signature → pure `create or replace`, deploy-skew-safe both ways.

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

  -- Load-bearing = anything another golfer's season, game, or ledger stands on.
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
      -- my board voice, league-wide (posts/post_comments.member_id: no delete rule)
      delete from post_comments pc using league_members m
        where pc.member_id = m.id and m.profile_id = v;
      delete from posts p using league_members m
        where p.member_id = m.id and m.profile_id = v;
      -- live rounds only I was in (started_by / member_id: no delete rule);
      -- shared ones already forced the tombstone path above
      delete from live_round_players lp using league_members m
        where lp.member_id = m.id and m.profile_id = v;
      delete from live_rounds lr using league_members m
        where lr.started_by = m.id and m.profile_id = v;
      update live_round_players set claimed_profile = null where claimed_profile = v;
      -- misc member anchors
      delete from feedback f using league_members m
        where f.member_id = m.id and m.profile_id = v;
      update squads s set captain_member_id = null
        from league_members m
        where s.captain_member_id = m.id and m.profile_id = v;
      -- solo-owned containers: empty them child-first, then drop them
      delete from posts        where league_id in (select id from leagues where commissioner_id = v);
      delete from live_rounds  where league_id in (select id from leagues where commissioner_id = v);
      delete from leagues where commissioner_id = v;
      delete from events  where created_by = v;
      delete from member_invites where invited_by = v or profile_id = v;
      update courses set created_by = null where created_by = v;
      delete from auth.users where id = v;   -- cascades profile + the rest
      return;                                -- email is free for reuse
    exception when others then
      get stacked diagnostics v_table = table_name, v_constraint = constraint_name;
      -- LOUD, and whole: raising rolls back every delete above — the account
      -- is untouched, still signed in, and the message names the blocker.
      raise exception 'Could not delete your account: something still references it (%.%). Nothing was changed — screenshot this and send it in via Feedback.',
        coalesce(nullif(v_table, ''), 'unknown table'), coalesce(nullif(v_constraint, ''), 'unknown constraint');
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

  update auth.users set banned_until = 'infinity'::timestamptz where id = v;
end $$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
