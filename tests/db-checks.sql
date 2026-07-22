-- ============================================================================
-- Cup Season DB invariant suite — READ-ONLY. Paste whole file into the
-- Supabase SQL editor; every row returned is a check with PASS/FAIL.
-- The live half of tests/preflight.mjs (regenerate the RPC list there when
-- the client grows: node tests/preflight.mjs prints the count; the extractor
-- one-liner lives in the repo history).
-- Generated 2026-07-21 against the v23 client (73 RPCs).
-- ============================================================================

with checks as (

-- 1 · pg_cron: the four season engines are scheduled and active
select '1 · pg_cron jobs' as check_name,
  case when (select count(*) from cron.job where active) >= 4
    then 'PASS' else 'FAIL — expected >=4 active jobs, got ' ||
      (select count(*) from cron.job where active)::text end as status,
  (select string_agg(jobname, ' · ' order by jobname) from cron.job where active) as detail

-- 2 · anon can execute EXACTLY the four public endpoints
union all
select '2 · anon function surface',
  case when missing = '' and extra = '' then 'PASS'
    else 'FAIL — missing: [' || missing || '] unexpected: [' || extra || ']' end,
  'expected claim_round_info, scan_claim_info, league_by_code, founder_id'
from (
  select
    (select coalesce(string_agg(f, ', '), '') from unnest(array['claim_round_info','scan_claim_info','league_by_code','founder_id']) f
      where not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname = f
          and has_function_privilege('anon', p.oid, 'execute'))) as missing,
    (select coalesce(string_agg(distinct p.proname, ', '), '') from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and has_function_privilege('anon', p.oid, 'execute')
        and p.proname not in ('claim_round_info','scan_claim_info','league_by_code','founder_id')) as extra
) t

-- 3 · every client-called RPC is executable by authenticated (the 73)
union all
select '3 · authenticated RPC grants',
  case when missing = '' then 'PASS — all 73 granted'
    else 'FAIL — not granted: ' || missing end,
  '73 names extracted from the client'
from (
  select coalesce(string_agg(f, ', '), '') as missing
  from unnest(array[
    'abandon_live_round','add_event_player','add_round_comment','announce','assign_player','claim_round','claim_round_info','claim_scan_round','create_event','create_league','create_major','create_scan_claim','declare_round','delete_account','delete_event','delete_league','delete_round','enter_major','event_session_targets','finish_live_round','form_squads','founder_desk','founder_id','founder_note','friend_request','friend_respond','generate_pairings','home_feed','invite_golfer','join_league','league_by_code','league_pulse','major_leaderboard','mark_buy_in','my_achievements','my_friends','my_invites','my_rivalries','my_schedule','my_trophies','open_major','randomize_squads','remove_member','report_content','resolve_session','respond_invite','retag_round','rivalry_weeks','round_detail','round_epilogue','scan_claim_info','scratch_round','search_golfers','season_scenarios','set_discoverable','set_event_notify','set_event_team','set_handle','set_index','set_league_finish','set_member_bye','set_member_index','set_notify_chat','set_notify_rounds','set_profile','set_rivalry_name','set_round_rsvp','settle_major','start_live_round','start_season','submit_feedback','tour_card','transfer_pro'
  ]) f
  where not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = f
      and has_function_privilege('authenticated', p.oid, 'execute'))
) t

-- 4 · the two dead policies stay dead (D37: self-promote + round rewrite)
union all
select '4 · dead policies stay dead',
  case when count(*) = 0 then 'PASS'
    else 'FAIL — resurrected: ' || string_agg(policyname, ', ') end,
  'members_self on league_members · rounds_owner_update on rounds'
from pg_policies
where (tablename = 'league_members' and policyname = 'members_self')
   or (tablename = 'rounds' and policyname = 'rounds_owner_update')

-- 5 · constraint widenings hold (the two defused time bombs + founder notes)
union all
select '5 · check constraints current',
  case when ok = 3 then 'PASS'
    else 'FAIL — ' || (3 - ok)::text || ' constraint(s) missing expected values' end,
  'season_adjustments kinds · rounds sources · feedback categories'
from (
  select count(*) as ok from (
    select 1 from pg_constraint where conname = 'season_adjustments_kind_check'
      and pg_get_constraintdef(oid) like '%month_closed%'
    union all
    select 1 from pg_constraint where conname = 'rounds_source_check'
      and pg_get_constraintdef(oid) like '%scan_claim%'
    union all
    select 1 from pg_constraint where conname = 'pilot_feedback_category_check'
      and pg_get_constraintdef(oid) like '%founder%'
  ) x
) t

-- 6 · RLS is on for every table the client touches directly
union all
select '6 · RLS enabled',
  case when off = '' then 'PASS' else 'FAIL — RLS off: ' || off end,
  'profiles, rounds, league_members, posts, post_comments, trophies, events, pilot_feedback, content_reports, scheduled_rounds'
from (
  select coalesce(string_agg(t, ', '), '') as off
  from unnest(array['profiles','rounds','league_members','posts','post_comments','trophies','events','pilot_feedback','content_reports','scheduled_rounds']) t
  where not exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = t and c.relrowsecurity)
) t

-- 7 · media bucket limits (8 MB + image-only) survived
union all
select '7 · media bucket limits',
  case when exists (select 1 from storage.buckets where id = 'media'
      and file_size_limit = 8388608 and allowed_mime_types is not null)
    then 'PASS' else 'FAIL — size/mime limits missing on media bucket' end,
  (select 'limit ' || coalesce(file_size_limit::text, 'none') || ' · mimes ' ||
    coalesce(array_length(allowed_mime_types, 1)::text, '0') from storage.buckets where id = 'media')

-- 8 · data sanity: no orphaned rounds, no double month sentinels
union all
select '8 · data sanity',
  case when orphans = 0 and dupes = 0 then 'PASS'
    else 'FAIL — orphan rounds: ' || orphans::text || ' · duplicate month sentinels: ' || dupes::text end,
  'rounds without profiles · month_closed uniqueness'
from (
  select
    (select count(*) from rounds r where r.profile_id is null) as orphans,
    (select count(*) from (
      select member_id, meta->>'month' as m, count(*)
      from season_adjustments where kind = 'month_closed'
      group by 1, 2 having count(*) > 1) d) as dupes
) t

-- 9 · the email column stays sealed (H1: no API role can read it)
union all
select '9 · profiles.email sealed',
  case when has_column_privilege('anon', 'public.profiles', 'email', 'select')
         or has_column_privilege('authenticated', 'public.profiles', 'email', 'select')
    then 'FAIL — an API role can select profiles.email' else 'PASS' end,
  'revoked in 20260718172300'
)
select * from checks order by check_name;
