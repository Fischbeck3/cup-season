-- HOW TO RUN IT: `supabase db query --linked --output-format text -f tests/db-checks.sql`.
-- Do NOT pass it as an argument — `"$(cat tests/db-checks.sql)"` fails with
-- "Unrecognized flag: --" because this file's first line starts with a comment
-- dash and the CLI reads it as a flag. (A leading space inside the quotes also
-- works.) The CLI answers in JSON whatever --output-format says. Read-only.
-- ============================================================================
-- Cup Season DB invariant suite — READ-ONLY. Paste whole file into the
-- Supabase SQL editor; every row returned is a check with PASS/FAIL.
-- The live half of tests/preflight.mjs (regenerate the RPC list there when
-- the client grows: node tests/preflight.mjs prints the count; the extractor
-- one-liner lives in the repo history).
-- Generated 2026-07-21 against the v23 client; refreshed 2026-07-22 (D57
-- public shares: anon list 4 → 5, authenticated list gains the share trio);
-- refreshed 2026-07-24 (anon table seal 20260724150000: check 10; scoreboard
-- security_invoker 20260725210000: check 11); refreshed 2026-07-28 (D85 live
-- sync: anon list 7 → 10, authenticated 93 → 96, live_scores in check 6 —
-- AND the suite's FIRST clean run: check 8 referenced meta->>'month', a
-- column that never existed, so every prior paste errored whole. Fixed, plus
-- check 10's default-acl branch scoped to postgres, see comment there);
-- refreshed 2026-08-27 (IOS-009 batch 1: authenticated list 99 → 102 with
-- handle_available / round_holes_of / native_home; check 12 pins the engine
-- functions close_month / award_*_trophies OFF the API surface — the
-- close_month grant had crept back via 20260727160000:341); refreshed
-- 2026-08-28 (launch review: check 8 scoped by season_id — the NULL-member
-- sentinel false-failed across two seasons; check 13 pins profiles as
-- server-owned (20260828150000, the founder self-promote hole); check 14 pins
-- the four live tables read-only + claim_token sealed (20260828150100)).
-- Refreshed 2026-08-29 (blind UX audit): checks 15-17 added — 15 lock health
-- (the ratio nobody was watching while `staged is not defined` told every Pro
-- "Lock failed" for 25 days), 16 the §15 formation invariant (the audit's own
-- second league sat in prod as phase=season with two empty squads), 17 the
-- band boundaries the web and the engine disagreed on at exactly -1.0.
-- NOTE: 15 and 16 FAIL until the audit's test footprint is wiped
-- (docs/audit/blind-ux-2026-08-29/tools/wipe.sql) — they are failing on the
-- evidence they were written from, which is the point.
-- Refreshed 2026-09-02 (D204-D212 batch): checks 19 and 20 added — 19 seals
-- the rounds INSERT to the payload's own columns (the column-revoke landmine
-- again: a table grant a column revoke cannot subtract from, which let any
-- client name index_at_post / attested / posted_by on the way in), 20 pins
-- what a deleted round leaves behind (the board keeps the sentence, the
-- trophy case keeps no medal it can no longer show).
-- ============================================================================

with checks as (

-- 1 · pg_cron: the four season engines are scheduled and active
select '1 · pg_cron jobs' as check_name,
  case when (select count(*) from cron.job where active) >= 4
    then 'PASS' else 'FAIL — expected >=4 active jobs, got ' ||
      (select count(*) from cron.job where active)::text end as status,
  (select string_agg(jobname, ' · ' order by jobname) from cron.job where active) as detail

-- 2 · anon can execute EXACTLY the twelve public endpoints (D57 share_info;
--     setup-QA join_covenant_info; D68 email_unsubscribe; D85 the guest live
--     pencil trio — token-keyed, fail-closed; 20260828160000 log_growth_event —
--     signed-out may log only a real link being opened, void either way)
union all
select '2 · anon function surface',
  case when missing = '' and extra = '' then 'PASS'
    else 'FAIL — missing: [' || missing || '] unexpected: [' || extra || ']' end,
  'expected claim_round_info, scan_claim_info, league_by_code, founder_id, share_info, join_covenant_info, email_unsubscribe, guest_live_state, guest_live_set_score, guest_live_set_wolf, door_flags, log_growth_event'
from (
  select
    (select coalesce(string_agg(f, ', '), '') from unnest(array['claim_round_info','scan_claim_info','league_by_code','founder_id','share_info','join_covenant_info','email_unsubscribe','guest_live_state','guest_live_set_score','guest_live_set_wolf','door_flags','log_growth_event']) f
      where not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname = f
          and has_function_privilege('anon', p.oid, 'execute'))) as missing,
    (select coalesce(string_agg(distinct p.proname, ', '), '') from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and has_function_privilege('anon', p.oid, 'execute')
        and p.proname not in ('claim_round_info','scan_claim_info','league_by_code','founder_id','share_info','join_covenant_info','email_unsubscribe','guest_live_state','guest_live_set_score','guest_live_set_wolf','door_flags','log_growth_event')) as extra
) t

-- 3 · every client-called RPC is executable by authenticated (the 105:
--     99 from the web client + the IOS-009 batch-1 trio the phone calls)
union all
select '3 · authenticated RPC grants',
  case when missing = '' then 'PASS — all 105 granted'
    else 'FAIL — not granted: ' || missing end,
  '99 names extracted from the web client + handle_available, round_holes_of, native_home (IOS-009) + founding_ids, door_flags + my_actionable_count (D104)'
from (
  select coalesce(string_agg(f, ', '), '') as missing
  from unnest(array[
    'abandon_live_round','add_event_player','add_round_comment','announce','assign_player','claim_round','claim_round_info','claim_scan_round','create_event','create_league','create_major','create_scan_claim','create_share','declare_round','delete_account','delete_event','delete_league','delete_round','enter_major','event_session_targets','finish_live_round','form_squads','founder_desk','founder_id','founder_note','friend_request','friend_respond','generate_pairings','home_feed','invite_golfer','join_league','league_by_code','league_pulse','major_leaderboard','mark_buy_in','my_achievements','my_friends','my_invites','my_rivalries','my_schedule','my_trophies','open_major','randomize_squads','remove_member','report_content','resolve_session','respond_invite','retag_round','revoke_share','rivalry_weeks','round_detail','round_epilogue','scan_claim_info','scratch_round','search_golfers','season_scenarios','set_discoverable','set_event_notify','set_event_team','set_handle','set_index','set_league_finish','set_member_bye','set_member_index','set_notify_chat','set_notify_rounds','set_profile','set_rivalry_name','set_round_rsvp','settle_major','share_info','start_live_round','start_season','submit_feedback','tour_card','transfer_pro','set_mute','my_mutes','register_device_token','join_covenant_info','set_league_marker','event_lineage','last_round_with','create_forfeit','settle_forfeit','scrap_forfeit','career_record','set_email_recap','email_unsubscribe','request_league_cancel','vote_league_cancel','withdraw_league_cancel','league_cancel_status','live_set_score','live_set_wolf','live_state','my_visitor_rounds','live_round_card','round_card','handle_available','round_holes_of','native_home','founding_ids','door_flags','my_actionable_count','league_looks','set_league_look','set_league_notify_system'
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
  'profiles, rounds, league_members, posts, post_comments, trophies, events, pilot_feedback, content_reports, scheduled_rounds, live_scores'
from (
  select coalesce(string_agg(t, ', '), '') as off
  from unnest(array['profiles','rounds','league_members','posts','post_comments','trophies','events','pilot_feedback','content_reports','scheduled_rounds','live_scores']) t
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
      -- month is a real date column (fixed 2026-07-28: the suite said
      -- meta->>'month', a column that never existed — the check 42703'd the
      -- WHOLE query, so no check in this file had ever actually run)
      -- scoped by season (2026-08-28): sentinels carry a NULL member_id, so
      -- two seasons closing the same month collided as a "duplicate"
      select season_id, member_id, month, count(*)
      from season_adjustments where kind = 'month_closed'
      group by 1, 2, 3 having count(*) > 1) d) as dupes
) t

-- 9 · the email column stays sealed — AND every other profiles column stays
--     readable. The seal froze the column-grant list (20260721214500); a new
--     column without its own grant fails boot as 42501 (photo_path, 2026-07-23).
union all
select '9 · profiles column grants',
  case when has_column_privilege('anon', 'public.profiles', 'email', 'select')
         or has_column_privilege('authenticated', 'public.profiles', 'email', 'select')
    then 'FAIL — an API role can select profiles.email'
       when exists (select 1 from information_schema.columns c
         where c.table_schema='public' and c.table_name='profiles' and c.column_name <> 'email'
           and not has_column_privilege('authenticated', 'public.profiles', c.column_name, 'select'))
    then 'FAIL — ungranted non-email column: ' ||
      (select string_agg(c.column_name, ', ') from information_schema.columns c
        where c.table_schema='public' and c.table_name='profiles' and c.column_name <> 'email'
          and not has_column_privilege('authenticated', 'public.profiles', c.column_name, 'select'))
    else 'PASS' end,
  'email sealed (20260718172300) · every later profiles column needs its own grant'

-- 10 · anon holds ZERO relation privileges in public (seal 20260724150000):
--      no table/view/sequence grants, no column grants, and no default-privilege
--      auto-grant for future tables/sequences. PUBLIC counts too — anon inherits
--      anything granted to PUBLIC. anon reaches the DB only through the seven
--      SECURITY DEFINER endpoints of check 2.
union all
select '10 · anon table seal',
  case when count(*) = 0 then 'PASS'
    else 'FAIL — ' || count(*)::text || ' leftover grant(s): ' || string_agg(o, ' · ') end,
  'relations + columns + default acls all clean of anon/PUBLIC'
from (
  select c.relname || ' (' || a.privilege_type || ')' as o
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  cross join lateral aclexplode(c.relacl) a
  where n.nspname = 'public' and c.relkind in ('r','p','v','m','f','S')
    and (a.grantee = 0 or a.grantee = 'anon'::regrole)
  union all
  select c.relname || '.' || att.attname || ' (column)'
  from pg_attribute att
  join pg_class c on c.oid = att.attrelid
  join pg_namespace n on n.oid = c.relnamespace
  cross join lateral aclexplode(att.attacl) a
  where n.nspname = 'public' and att.attnum > 0 and not att.attisdropped
    and (a.grantee = 0 or a.grantee = 'anon'::regrole)
  union all
  -- scoped to postgres (2026-07-28, the suite's first real run): Supabase's
  -- PLATFORM defaults ("for role supabase_admin in schema public grant all to
  -- anon", same pattern in graphql/graphql_public/supabase_functions) also
  -- live here. They fire only for objects supabase_admin creates — platform
  -- objects, never app tables (migrations + SQL editor run as postgres) — and
  -- postgres cannot alter another role's default acls, so they are both
  -- unreachable and benign. Unscoped, they made this check a permanent FAIL.
  select 'default-acl (' || d.defaclobjtype::text || ') for role ' || d.defaclrole::regrole::text
  from pg_default_acl d
  left join pg_namespace n on n.oid = d.defaclnamespace
  cross join lateral aclexplode(d.defaclacl) a
  where d.defaclobjtype in ('r','S')
    and d.defaclrole = 'postgres'::regrole
    and (n.nspname = 'public' or d.defaclnamespace = 0)
    and (a.grantee = 0 or a.grantee = 'anon'::regrole)
) t

-- 11 · every view an API role can read runs as its READER (20260725210000).
--      A view in public without security_invoker executes as its owner
--      (postgres), who owns the base tables and therefore skips their RLS —
--      so a grant to anon/authenticated becomes an unpoliced read of everything
--      the view selects. v_event_scoreboard was the last one (it leaked every
--      event's team totals cross-league). v_pilot_gates / v_post_timings are
--      owner-mode but revoked from both API roles, so they stay out of scope.
union all
select '11 · views run as reader',
  case when count(*) = 0 then 'PASS'
    else 'FAIL — owner-mode view(s) on the API surface: ' || string_agg(relname, ' · ') end,
  'security_invoker required on any public view granted to anon/authenticated'
from (
  select c.relname
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  left join lateral (
    select lower(split_part(o, '=', 2)) as v
    from unnest(coalesce(c.reloptions, '{}'::text[])) o
    where split_part(o, '=', 1) = 'security_invoker'
  ) so on true
  where n.nspname = 'public' and c.relkind = 'v'
    and coalesce(so.v, 'false') not in ('true', 'on', '1', 'yes')
    and (has_table_privilege('anon', c.oid, 'select')
      or has_table_privilege('authenticated', c.oid, 'select'))
) t

-- 12 · the season/trophy engines stay OFF the API surface (IOS-009 batch 1,
--      20260827130000). close_month's only guard is the month_closed
--      sentinel, so a member who could call it would close last month early
--      and block the cron's real close; its grant crept back in
--      20260727160000:341 after the C3 revoke. Cron runs as postgres and the
--      trophy minters are reached through definer functions/triggers, so
--      neither API role needs any of these.
union all
select '12 · engine functions unreachable',
  case when leaked = '' then 'PASS'
    else 'FAIL — executable by an API role: ' || leaked end,
  'close_month · award_event_trophies · award_season_trophies — no execute for anon/authenticated'
from (
  select coalesce(string_agg(p.proname || ' (' || r.role_name || ')', ', ' order by p.proname, r.role_name), '') as leaked
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join (values ('anon'), ('authenticated')) r(role_name)
  where n.nspname = 'public'
    and p.proname in ('close_month', 'award_event_trophies', 'award_season_trophies')
    and has_function_privilege(r.role_name, p.oid, 'execute')
) t

-- 13 · profiles is SERVER-OWNED (20260828150000). authenticated held a
--      table-level UPDATE and the policies scoped only by row, so any golfer
--      could PATCH their own is_founder / index_current. No API role may hold
--      any write privilege (table or column) and no write policy may exist;
--      every change goes through a SECURITY DEFINER RPC.
union all
select '13 · profiles server-owned',
  case when leaks = '' then 'PASS' else 'FAIL — ' || leaks end,
  'no insert/update/delete grant (table or column) to anon/authenticated · no write policy on profiles'
from (
  select coalesce(string_agg(o, ' · '), '') as leaks from (
    select r.role_name || ' table ' || pv.p as o
    from (values ('anon'), ('authenticated')) r(role_name)
    cross join (values ('insert'), ('update'), ('delete')) pv(p)
    where has_table_privilege(r.role_name, 'public.profiles', pv.p)
    union all
    select a.grantee::regrole::text || ' column ' || att.attname || ' ' || a.privilege_type
    from pg_attribute att
    cross join lateral aclexplode(att.attacl) a
    where att.attrelid = 'public.profiles'::regclass and att.attnum > 0 and not att.attisdropped
      and a.grantee in ('anon'::regrole, 'authenticated'::regrole)
      and a.privilege_type <> 'SELECT'
    union all
    select 'policy ' || polname
    from pg_policy where polrelid = 'public.profiles'::regclass and polcmd in ('w','a','d','*')
  ) x
) t

-- 14 · live-round tables are READ-ONLY to the API (20260828150100): no write
--      grant, no write policy on live_rounds / live_round_players /
--      game_results / live_scores, and live_round_players.claim_token is
--      sealed (its column list is frozen like profiles' — a new column needs
--      its own grant or the phone's open-rounds select fails 42501).
union all
select '14 · live tables read-only',
  case when leaks = '' then 'PASS' else 'FAIL — ' || leaks end,
  'no write grant/policy for authenticated on the four live tables · claim_token unreadable'
from (
  select coalesce(string_agg(o, ' · '), '') as leaks from (
    select t || ' ' || pv.p as o
    from unnest(array['live_rounds','live_round_players','game_results','live_scores']) t
    cross join (values ('insert'), ('update'), ('delete')) pv(p)
    where has_table_privilege('authenticated', 'public.' || t, pv.p)
    union all
    select c.relname || ' policy ' || p.polname
    from pg_policy p join pg_class c on c.oid = p.polrelid
    where c.relname in ('live_rounds','live_round_players','game_results','live_scores')
      and p.polcmd in ('w','a','d','*')
    union all
    select 'claim_token readable'
    where has_column_privilege('authenticated', 'public.live_round_players', 'claim_token', 'select')
  ) x
) t

-- 15 · lock health: the client's bylaws lock is succeeding
--     The `staged` remnant (D97, 2026-08-04) made lockBylaws throw AFTER the
--     server had committed, so every Pro was told "Lock failed" about a league
--     that was live. It ran 25 days because nobody was watching this ratio:
--     prod held ONE lock_ok all-time against eleven lock_fail. A lock_fail
--     naming a JS reference error is never a user problem — it is a bug that
--     is live right now.
union all
select '15 · lock health',
  case
    when js_errs > 0 then 'FAIL — ' || js_errs::text ||
      ' lock_fail(s) carrying a JavaScript reference error in 7d — a shipped bug: ' || coalesce(sample, '?')
    when attempts >= 3 and fails > oks then 'FAIL — ' || fails::text || ' lock_fail vs ' ||
      oks::text || ' lock_ok in 7d'
    else 'PASS' end,
  'lock_ok ' || oks::text || ' · lock_fail ' || fails::text || ' · 7 days'
from (
  select
    count(*) filter (where event = 'lock_ok')   as oks,
    count(*) filter (where event = 'lock_fail') as fails,
    count(*) filter (where event in ('lock_ok','lock_fail')) as attempts,
    count(*) filter (where event = 'lock_fail'
      and props->>'msg' ~* '(is not defined|is not a function|undefined is not|cannot read propert)') as js_errs,
    (select props->>'msg' from client_events where event = 'lock_fail'
       and created_at > now() - interval '7 days'
       and props->>'msg' ~* '(is not defined|is not a function|undefined is not|cannot read propert)'
     order by created_at desc limit 1) as sample
  from client_events where created_at > now() - interval '7 days'
) t

-- 16 · §15 formation invariant: no league is in season with empty squads
--     Desert Dogs (the blind audit's second league) sat in prod as
--     structure=squads2 · phase=season · two EMPTY squads · one member — a
--     state spec §15 forbids and nothing detected.
union all
select '16 · formation invariant',
  case when bad = 0 then 'PASS'
    else 'FAIL — ' || bad::text || ' league(s) in season with an empty squad or an unseated member' end,
  'leagues in phase=season whose squads do not cover the roster'
-- Widened 2026-08-30 (code audit TT-01). The first version JOINed squads, so a
-- non-solo league with NO squads formed was structurally invisible, and it never
-- tested the unseated member its own failure message advertises.
-- NOTE, honestly: the review claimed this hid 4 live violations and it does not.
-- Three of those four are SOLO leagues, which correctly have no squads
-- (form_squads returns early for solo), and the fourth is the same league already
-- caught. Prod has exactly one violation before and after this change. The widening
-- is still worth it — the two uncovered cases are real and would have been missed —
-- but the check was not under-reporting. Verified by counting each case separately.
from (
  select count(*) as bad from leagues l
  where l.phase = 'season'
    and exists (select 1 from seasons s where s.league_id = l.id)
    and (
      -- structure says squads, but none were ever formed
      (coalesce((select ls.structure from league_settings ls where ls.league_id = l.id), 'squads2') <> 'solo'
       and not exists (select 1 from squads q join seasons s on s.id = q.season_id where s.league_id = l.id))
      -- a squad exists with nobody in it
      or exists (select 1 from squads q join seasons s on s.id = q.season_id
                  where s.league_id = l.id
                    and not exists (select 1 from squad_members sm where sm.squad_id = q.id))
      -- a member of a squads league is seated in no squad
      or (coalesce((select ls.structure from league_settings ls where ls.league_id = l.id), 'squads2') <> 'solo'
          and exists (select 1 from league_members m where m.league_id = l.id
                       and not exists (select 1 from squad_members sm where sm.member_id = m.id)))
    )
) t

-- 17 · the point bands agree between the web and the engine
--     The client's pointsFor() and the server's cup_points() are two
--     implementations of one rule (§2.2). They disagreed at exactly -1.0 (the
--     web said 7, the engine 6) — a boundary a golfer lands on constantly.
union all
select '17 · band boundaries',
  case when cup_points(-1.0) = 6 and cup_points(-0.9) = 7
        and cup_points(3.0) = 12 and cup_points(0) = 7
    then 'PASS'
    else 'FAIL — cup_points(-1.0)=' || cup_points(-1.0)::text ||
         ' (want 6) · (-0.9)=' || cup_points(-0.9)::text ||
         ' (want 7) · (3.0)=' || cup_points(3.0)::text || ' (want 12)' end,
  'cup_points half-open bands, §2.2'

-- 18 · one relationship per embedded table
--     D199, learned the expensive way. Adding an audit column with a foreign
--     key gives a table a SECOND path to the same target, and PostgREST then
--     refuses every unqualified embed against it with 300 / PGRST201. D197's
--     `league_members.suspended_by -> profiles` broke the roster, the board's
--     social fetch, the schedule, the live roster and the rounds picker on
--     BOTH clients the moment it was pushed — and preflight's check 21, which
--     exists for exactly this failure, watched it happen and said PASS,
--     because it names `live_round_players` and nothing else.
--     A schema fact cannot be checked from source; it is checked here.
--     SCOPED to tables a client embeds, and four pairs are ACCEPTED by name:
--     rounds (posted_by, D125a), live_round_players (guest paths),
--     content_reports (read only via moderation_queue) and round_comments
--     (queried by neither client) all carry two paths and none is a fault,
--     because nothing embeds them. Schema-wide the invariant is FALSE BY
--     DESIGN — fourteen more healthy pairs exist. A guard that fires on things
--     that are fine teaches people to push past guards.
union all
select '18 · one relationship per embed',
  case when not exists (
    select 1 from pg_constraint c
     where c.contype = 'f' and c.connamespace = 'public'::regnamespace
       and c.conrelid::regclass::text in
           ('league_members','posts','post_comments','round_comments','rounds',
            'squads','squad_members','live_rounds','live_round_players',
            'event_players','event_teams','content_reports')
       and (c.conrelid::regclass::text, c.confrelid::regclass::text) not in (
             ('rounds','profiles'), ('live_round_players','profiles'),
             ('content_reports','profiles'), ('round_comments','profiles'))
     group by c.conrelid, c.confrelid having count(*) > 1)
    then 'PASS'
    else 'FAIL — ' || coalesce((
      select string_agg(t || ' -> ' || tgt || ' x' || n::text, ', ')
        from (select c.conrelid::regclass::text t, c.confrelid::regclass::text tgt, count(*) n
                from pg_constraint c
               where c.contype='f' and c.connamespace='public'::regnamespace
                 and c.conrelid::regclass::text in
                     ('league_members','posts','post_comments','round_comments','rounds',
                      'squads','squad_members','live_rounds','live_round_players',
                      'event_players','event_teams','content_reports')
                 and (c.conrelid::regclass::text, c.confrelid::regclass::text) not in (
                       ('rounds','profiles'), ('live_round_players','profiles'),
                       ('content_reports','profiles'), ('round_comments','profiles'))
               group by 1,2 having count(*) > 1) x), '?') end,
  'a client-embedded table with two paths to one target = PGRST201 on every unqualified embed'

-- 19 · the rounds INSERT is sealed to the payload (M-14, 20260902173000).
--     The same landmine as checks 2 and 9: a column revoke subtracts nothing
--     from a table-level grant, so `authenticated` could name index_at_post,
--     attested or posted_by on the way in and the BEFORE trigger — which only
--     fills what is MISSING — would leave the lie in place. The seal is:
--     revoke the table INSERT, re-grant the eleven columns both clients
--     actually send (index.html:7184 · PostCard.swift:278-289 PostPayload). A twelfth
--     column added to either payload lands here as a FAIL, not as a 42501 in
--     a golfer's face.
union all
select '19 · rounds INSERT is column-scoped',
  case when has_table_privilege('authenticated', 'public.rounds', 'INSERT')
         then 'FAIL — authenticated holds table-level INSERT on rounds'
       when missing <> '' then 'FAIL — payload column not grantable: ' || missing
       when leaked  <> '' then 'FAIL — engine column still writable: ' || leaked
       else 'PASS — 11 payload columns, engine columns sealed' end,
  'gross rating nine_rating slope holes_played source played_on course_label api_course_id season_id photo_path'
from (
  select
    coalesce((select string_agg(c, ', ') from unnest(array[
       'gross','rating','nine_rating','slope','holes_played','source',
       'played_on','course_label','api_course_id','season_id','photo_path']) c
      where not has_column_privilege('authenticated', 'public.rounds', c, 'INSERT')), '') as missing,
    coalesce((select string_agg(c, ', ') from unnest(array[
       'id','profile_id','index_at_post','index_source_at_post','attested',
       'posted_by','voided','differential','index_provisional']) c
      where has_column_privilege('authenticated', 'public.rounds', c, 'INSERT')), '') as leaked
) t

-- 20 · what a deleted round leaves behind (Y-19 / M-16, 20260902173000).
--     delete_round() is the only way a round leaves, and three things used to
--     go wrong at once: the refresh trigger fired on INSERT only, so the
--     index the deleted round earned survived it; every post that pointed at
--     the round CASCADEd out, taking the clash result and the moment; and the
--     award kept its row with a null receipt — a medal nobody can show.
union all
select '20 · a deleted round leaves the ledger true',
  case when trg is null or trg not like '%AFTER INSERT OR DELETE%'
         then 'FAIL — round_refresh_index_trg is not AFTER INSERT OR DELETE'
       when fk is distinct from 'n'
         then 'FAIL — posts_round_id_fkey is not ON DELETE SET NULL'
       when orphans > 0
         then 'FAIL — ' || orphans::text || ' achievement(s) carry no receipt'
       else 'PASS' end,
  'the number follows the ledger both ways ONCE THE ENGINE HAS ONE (round_refresh_index returns early while handicap_index() is null — under three live rounds the index the deleted round earned stands until the next post) · the board keeps the sentence · every medal has its round'
from (
  select
    (select pg_get_triggerdef(t.oid) from pg_trigger t
      where t.tgrelid = 'public.rounds'::regclass and t.tgname = 'round_refresh_index_trg') as trg,
    (select c.confdeltype::text from pg_constraint c
      where c.conrelid = 'public.posts'::regclass and c.conname = 'posts_round_id_fkey') as fk,
    (select count(*) from achievements where round_id is null) as orphans
) t

)
select * from checks order by check_name;
