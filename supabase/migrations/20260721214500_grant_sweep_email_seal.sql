-- ============================================================================
-- Fixes for the two live FAILs from tests/db-checks.sql (2026-07-21):
--
-- CHECK 2 (anon surface) — functions created after the D37 default-privilege
--   flip picked up PUBLIC execute when their migration didn't revoke it
--   explicitly (the flip binds to the `postgres` role; not every runner path
--   is that role). PUBLIC includes anon. Re-run the sweep: strip PUBLIC and
--   anon from everything, re-grant the four genuine anon endpoints, then
--   grant the FULL client surface (73 RPCs) to authenticated explicitly and
--   by signature (a DO loop over pg_proc, so overloads are covered) — after
--   stripping PUBLIC, implicit access is gone and only explicit grants keep
--   the app alive.
--
-- CHECK 9 (email sealed) — the H1 fix revoked SELECT(email) column-wise, but
--   the baseline's table-level GRANT ALL still covered every column: column
--   revokes never subtract from table grants. Do it the only way that works:
--   revoke table-level SELECT outright, then grant SELECT on the full column
--   list MINUS email (built dynamically so future columns aren't silently
--   sealed too — new columns will need their own grant, which is the right
--   default). anon keeps no direct read at all (its endpoints are definers).
--   The one direct client read (loadProfile, own row, named columns, no
--   email) stays covered.
-- ============================================================================

-- ---- CHECK 2 · the anon/PUBLIC sweep, again and airtight -------------------
revoke execute on all functions in schema public from public, anon;

grant execute on function public.claim_round_info(uuid) to anon;
grant execute on function public.scan_claim_info(uuid)  to anon;
grant execute on function public.league_by_code(text)   to anon;
grant execute on function public.founder_id()           to anon;

-- the entire client-called surface, granted explicitly by resolved signature
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = any(array[
        'abandon_live_round','add_event_player','add_round_comment','announce','assign_player','claim_round','claim_round_info','claim_scan_round','create_event','create_league','create_major','create_scan_claim','declare_round','delete_account','delete_event','delete_league','delete_round','enter_major','event_session_targets','finish_live_round','form_squads','founder_desk','founder_id','founder_note','friend_request','friend_respond','generate_pairings','home_feed','invite_golfer','join_league','league_by_code','league_pulse','major_leaderboard','mark_buy_in','my_achievements','my_friends','my_invites','my_rivalries','my_schedule','my_trophies','open_major','randomize_squads','remove_member','report_content','resolve_session','respond_invite','retag_round','rivalry_weeks','round_detail','round_epilogue','scan_claim_info','scratch_round','search_golfers','season_scenarios','set_discoverable','set_event_notify','set_event_team','set_handle','set_index','set_league_finish','set_member_bye','set_member_index','set_notify_chat','set_notify_rounds','set_profile','set_rivalry_name','set_round_rsvp','settle_major','start_live_round','start_season','submit_feedback','tour_card','transfer_pro'
      ])
  loop
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

-- Helper predicates that RLS policies lean on stay callable: policies are
-- evaluated AS THE QUERYING ROLE, so authenticated must be able to execute
-- every is_*/can_*/my_* predicate or table reads fail app-wide. Pattern-wide
-- on purpose — a missed helper here breaks every SELECT behind its policy.
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (p.proname like 'is\_%' or p.proname like 'can\_%'
           or p.proname like 'my\_%' or p.proname in ('cup_points','founder_id'))
  loop
    execute format('grant execute on function %s to authenticated', r.sig);
  end loop;
end $$;

-- ---- CHECK 9 · seal profiles.email for real --------------------------------
revoke select on table public.profiles from anon, authenticated;

do $$
declare cols text;
begin
  select string_agg(quote_ident(column_name), ', ' order by ordinal_position)
    into cols
  from information_schema.columns
  where table_schema = 'public' and table_name = 'profiles'
    and column_name <> 'email';
  execute format('grant select (%s) on public.profiles to authenticated', cols);
end $$;
