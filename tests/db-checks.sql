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

-- 1 · pg_cron: the season engines are scheduled and active. Three since
--     20261112090000 (D378): cs-month-close, cs-daily-tick, run_event_sessions —
--     the weekly snapshot rides the daily tick now and cs-week-snapshot is gone.
select '1 · pg_cron jobs' as check_name,
  case when (select count(*) from cron.job where active) >= 3
          and not exists (select 1 from cron.job where jobname = 'cs-week-snapshot')
          and exists (select 1 from cron.job where jobname = 'cs-daily-tick' and active)
    then 'PASS' else 'FAIL — expected >=3 active jobs with the tick and without cs-week-snapshot, got ' ||
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
    'abandon_live_round','add_event_player','add_round_comment','announce','assign_player','claim_round','claim_round_info','claim_scan_round','create_event','create_league','create_major','create_scan_claim','create_share','declare_round','delete_account','delete_event','delete_league','delete_round','enter_major','event_session_targets','finish_live_round','form_squads','founder_desk','founder_id','founder_note','friend_request','friend_respond','generate_pairings','home_feed','invite_golfer','join_league','league_by_code','league_pulse','major_leaderboard','mark_buy_in','my_achievements','my_friends','my_invites','my_rivalries','my_schedule','my_trophies','open_major','randomize_squads','remove_member','report_content','resolve_session','respond_invite','retag_round','revoke_share','rivalry_weeks','round_detail','round_epilogue','scan_claim_info','scratch_round','search_golfers','season_scenarios','set_discoverable','set_event_notify','set_event_team','set_handle','set_index','set_league_finish','set_member_bye','adjust_points','set_member_index','set_notify_chat','set_notify_rounds','set_profile','set_rivalry_name','set_round_rsvp','settle_major','share_info','start_live_round','start_season','submit_feedback','tour_card','transfer_pro','set_mute','my_mutes','register_device_token','join_covenant_info','set_league_marker','event_lineage','last_round_with','create_forfeit','settle_forfeit','scrap_forfeit','career_record','set_email_recap','email_unsubscribe','request_league_cancel','vote_league_cancel','withdraw_league_cancel','league_cancel_status','live_set_score','live_set_wolf','live_state','my_visitor_rounds','live_round_card','round_card','handle_available','round_holes_of','native_home','founding_ids','door_flags','my_actionable_count','league_looks','set_league_look','set_league_notify_system'
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

-- 9 · the SEALED columns stay sealed — AND every other profiles column stays
--     readable. The seal froze the column-grant list (20260721214500); a new
--     column without its own grant fails boot as 42501 (photo_path, 2026-07-23).
--     TWO COLUMNS ARE SEALED, NOT ONE (2026-09-09). This check knew only about
--     `email` and so reported the second seal as a hole: C-11's `contact_hash`
--     (20260928100000) is DELIBERATELY ungranted, and that migration's own
--     self-check raises if it ever becomes selectable — granting it would hand
--     every signed-in golfer the peppered digest of everyone's email, which is
--     precisely the offline matching the RPC's gate exists to prevent. So the
--     check returned FAIL against a correct production, and a guard that is
--     permanently red is a guard nobody reads. The seal list is now the subject
--     of the check rather than a single name: each sealed column is asserted
--     UNREADABLE, and every column that is not sealed must carry its grant.
--     ADDING A COLUMN HERE IS A DELIBERATE ACT — it means "no client selects
--     this, and handing it to one would be a disclosure."
union all
select '9 · profiles column grants',
  case when exists (select 1 from unnest(array['email','contact_hash']) sealed(col)
         where has_column_privilege('anon', 'public.profiles', sealed.col, 'select')
            or has_column_privilege('authenticated', 'public.profiles', sealed.col, 'select'))
    then 'FAIL — an API role can select a sealed column: ' ||
      (select string_agg(sealed.col, ', ') from unnest(array['email','contact_hash']) sealed(col)
        where has_column_privilege('anon', 'public.profiles', sealed.col, 'select')
           or has_column_privilege('authenticated', 'public.profiles', sealed.col, 'select'))
       when exists (select 1 from information_schema.columns c
         where c.table_schema='public' and c.table_name='profiles'
           and c.column_name <> all (array['email','contact_hash'])
           and not has_column_privilege('authenticated', 'public.profiles', c.column_name, 'select'))
    then 'FAIL — ungranted non-sealed column: ' ||
      (select string_agg(c.column_name, ', ') from information_schema.columns c
        where c.table_schema='public' and c.table_name='profiles'
          and c.column_name <> all (array['email','contact_hash'])
          and not has_column_privilege('authenticated', 'public.profiles', c.column_name, 'select'))
    else 'PASS' end,
  'email (20260718172300) + contact_hash (C-11) sealed · every other column needs its own grant'

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
--     SCOPED to tables a client embeds, and seven pairs are ACCEPTED by name
--     (the two post_comments pairs are explained below):
--     rounds (posted_by, D125a), live_round_players (guest paths),
--     content_reports (read only via moderation_queue), round_comments
--     (queried by neither client) and posts (see below) all carry two paths
--     and none is a fault, because nothing embeds them. Schema-wide the
--     invariant is FALSE BY DESIGN — fourteen more healthy pairs exist. A
--     guard that fires on things that are fine teaches people to push past
--     guards.
--
--     POSTS BECAME A SECOND PAIR ON 2026-09-21 AND NOBODY NOTICED UNTIL NOW
--     (accepted 2026-09-09). `posts.hidden_by -> profiles` landed with the
--     takedown path (20260901120000); D199 saw it the next day and wrote
--     "posts keeps its audit FK: nothing embeds it, and integrity is free
--     where it costs nothing" — TRUE AT THE TIME, because `posts.profile_id`
--     did not exist yet, so the pair was x1 and D199's own guard passed.
--     `20260921090000_a_post_can_be_homed_on_a_person` then added
--     `profile_id uuid references profiles(id)` and made it x2. D199's guard
--     only ever ran once, at its own push; this check is the standing one and
--     it had not been run since. Verified 2026-09-09 by grep across BOTH
--     clients, the netlify functions and the edge functions: nothing embeds
--     profiles on posts anywhere — the board resolves an author through a
--     separate `league_members` read (HomeSocial.swift:205), not an embed.
--     So it is accepted, on exactly the ground `rounds -> profiles` is
--     accepted, which is the same shape (a semantic profile_id beside an
--     audit column).
--
--     THE HAZARD THIS ACCEPTANCE CARRIES, STATED SO IT IS NOT A SURPRISE:
--     `profile_id` exists precisely so a post can be homed on a person, so
--     embedding the author from `posts` is the obvious next thing somebody
--     writes, and it will fail with PGRST201 on both clients. It must NAME
--     the relationship — `profile:profiles!posts_profile_id_fkey(...)` — or
--     `posts_hidden_by_fkey` must be dropped first, which is what D199 did to
--     `league_members_suspended_by_fkey`: when a pair is reduced, the AUDIT
--     foreign key goes and the semantic one stays.
--
--     POST_COMMENTS BECAME TWO PAIRS WITH D391 (20261207090000, 2026-09-25) AND
--     BOTH ARE ACCEPTED BY NAME. `post_comments.profile_id -> profiles` (the
--     author of a round-thread comment) sits beside the takedown audit column
--     `hidden_by -> profiles` — the posts/rounds shape again; and `parent_id` /
--     `root_id -> post_comments` are the reply graph, a self-reference twice.
--     Verified 2026-09-25 across index.html, every Swift source, the netlify
--     functions and the edge functions: every client read of post_comments
--     selects SCALAR columns (index.html feed social + Home digest,
--     BoardRepository.swift:193, HomeSocial.swift:205); the inserts return
--     nothing; nothing embeds post_comments from posts, rounds or profiles; and
--     the round thread is read only through posted_round_thread (a definer RPC,
--     no PostgREST embed at all). Nothing embeds, so nothing is ambiguous.
--     THE HAZARD, STATED: an author embed written the obvious way —
--     `post_comments.select('..., profiles(...)')` — or a reply embed
--     `post_comments(...)` from its parent fails with PGRST201 on both clients.
--     It must NAME the relationship (`profiles!post_comments_profile_id_fkey`,
--     `post_comments!post_comments_parent_id_fkey`). Preflight's check 21b
--     ("post_comments embeds name their FK") fails the push on any unqualified
--     embed in a post_comments read, or of post_comments from anywhere, in every
--     client and function source — so this acceptance cannot rot silently.
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
             ('content_reports','profiles'), ('round_comments','profiles'),
             ('posts','profiles'),
             ('post_comments','profiles'), ('post_comments','post_comments'))
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
                       ('content_reports','profiles'), ('round_comments','profiles'),
                       ('posts','profiles'),
                       ('post_comments','profiles'), ('post_comments','post_comments'))
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

-- 21 · the posts INSERT is sealed to the chat payload (20260902210000).
--     `posts.scheduled_round_id` is stamped by declare_round and by nothing
--     else, but the column comment said so while the database did not: an
--     INSERT policy constrains ROWS, never COLUMNS, and authenticated held
--     table-level INSERT. Same landmine as checks 2, 9 and 19. The seal is:
--     revoke the table INSERT, re-grant the five columns both clients send
--     (index.html:6008 · BoardRepository.swift:205). A sixth column added to
--     either payload lands here as a FAIL, not as a 42501 in a golfer's face —
--     and a boilerplate migration that hands table INSERT back lands here too,
--     which is the failure this check exists for.
union all
select '21 · posts INSERT is column-scoped',
  case when has_table_privilege('authenticated', 'public.posts', 'INSERT')
         then 'FAIL — authenticated holds table-level INSERT on posts'
       when missing <> '' then 'FAIL — chat column not grantable: ' || missing
       when leaked  <> '' then 'FAIL — server-owned column still writable: ' || leaked
       else 'PASS — 5 chat columns, server columns sealed' end,
  'league_id season_id kind member_id body'
from (
  select
    coalesce((select string_agg(c, ', ') from unnest(array[
       'league_id','season_id','kind','member_id','body']) c
      where not has_column_privilege('authenticated', 'public.posts', c, 'INSERT')), '') as missing,
    coalesce((select string_agg(c, ', ') from unnest(array[
       'id','round_id','live_round_id','scheduled_round_id','event_id',
       'push_title','hidden_at','hidden_by','hidden_reason']) c
      where has_column_privilege('authenticated', 'public.posts', c, 'INSERT')), '') as leaked
) t

-- 22 · a null uid may not pass a guard (20260904173000).
--     `auth.uid() <> owner` is NULL when either side is NULL, so the `if`
--     never fires and the guard is skipped — it fails OPEN. Nine functions
--     carried it; two compared against a column (`f.created_by`, `v_owner`)
--     that can itself be null, which needs no missing JWT to open. The idiom
--     is `is distinct from`, and this check is how it stays that way.
union all
select '22 · founder/owner guards fail closed',
  case when bad is null then 'PASS — no `auth.uid() <>` anywhere in public'
       else 'FAIL — a null uid still passes a guard in: ' || bad end,
  'is distinct from, never <>'
from (
  select (select string_agg(p.proname, ', ' order by p.proname)
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.prosrc ~ 'auth\.uid\(\)\s*(<>|!=)') as bad
) t

-- 23 · no client-useless table grants (20260904183000).
--     TRUNCATE bypasses RLS, so it is not covered by the layer this schema
--     leans on; REFERENCES, TRIGGER and MAINTAIN are not client verbs either.
--     Note pg_default_acl still hands `arwdDxtm` to authenticated on NEW
--     tables, so this check is also the tripwire for the next table added.
union all
select '23 · TRUNCATE is not a client verb',
  case when n = 0 then 'PASS — no TRUNCATE/REFERENCES/TRIGGER/MAINTAIN for authenticated or anon'
       else 'FAIL — ' || n || ' such grant(s), e.g. ' || left(coalesce(names, ''), 120) end,
  'RLS does not cover TRUNCATE'
from (
  select count(*) as n, string_agg(distinct c.relname, ', ' order by c.relname) as names
    from pg_class c, lateral aclexplode(c.relacl) a
   where c.relnamespace = 'public'::regnamespace and c.relkind in ('r','p')
     and a.privilege_type in ('TRUNCATE','REFERENCES','TRIGGER','MAINTAIN')
     and a.grantee::regrole::text in ('authenticated','anon')
) t

-- 24 · round_players is read-only to every client (D239, 20260910093000).
--     The programme's ONE new table holds who-played-with-whom, and CC-52's
--     lesson is that a new table is born wide: `pg_default_acl` hands
--     `arwdDxtm` to authenticated, so the migration revokes from authenticated
--     as well as from public and anon before granting SELECT back. Writes go
--     through `post_round` and `confirm_round_partner` and nowhere else — a
--     direct insert would let anyone write a claim about anybody.
union all
select '24 · round_players is read-only to clients',
  case when to_regclass('public.round_players') is null then 'PASS — table not deployed yet'
       when bad <> '' then 'FAIL — ' || bad
       else 'PASS — authenticated may SELECT and nothing else; anon holds nothing; RLS on' end,
  'writes go through post_round only'
from (
  select coalesce(nullif(concat_ws('; ',
      (select case when to_regclass('public.round_players') is not null
                    and (has_any_column_privilege('authenticated','public.round_players','INSERT')
                      or has_any_column_privilege('authenticated','public.round_players','UPDATE')
                      or has_table_privilege('authenticated','public.round_players','DELETE'))
                   then 'authenticated can write it' end),
      (select case when to_regclass('public.round_players') is not null
                    and (has_table_privilege('anon','public.round_players','SELECT')
                      or has_any_column_privilege('anon','public.round_players','INSERT'))
                   then 'anon holds a grant' end),
      (select case when to_regclass('public.round_players') is not null
                    and not coalesce((select c.relrowsecurity from pg_class c where c.oid = to_regclass('public.round_players')), false)
                   then 'RLS is off' end),
      (select case when to_regclass('public.round_players') is not null
                    and not has_table_privilege('authenticated','public.round_players','SELECT')
                   then 'authenticated cannot read it' end)
    ), ''), '') as bad
) t

-- 25 · D244 · leaving a season is FORWARD-ONLY, and the only thing that can
--     enforce that is the scoring lens. `leave_season` writes `left_at` and
--     touches no round; if the view ever stops honouring the column, every
--     leaver's past rounds vanish from everyone else's standings — the exact
--     thing §16 forbids, and it would happen silently.
union all
select '25 · a leaver stops scoring forward-only',
  case when to_regclass('public.v_rounds_ranked') is null then 'FAIL — the scoring lens is gone'
       when not exists (select 1 from information_schema.columns
                         where table_schema = 'public' and table_name = 'league_members'
                           and column_name = 'left_at') then 'PASS — leave_season not deployed yet'
       when pg_get_viewdef('public.v_rounds_ranked'::regclass, true) not like '%left_at%'
         then 'FAIL — v_rounds_ranked does not honour left_at; a leaver''s past rounds are at risk'
       else 'PASS — the forward-only cut is in the lens, beside the suspension''s' end,
  'r.created_at < lm.left_at'


-- 26 · D238 · a post may be homed on a PERSON, and the reaction is keyed on one.
--     `posts` RLS is the most-read policy in the product and `post_kudos` is
--     the wall a leagueless golfer hit; both are asserted here because a
--     silently-reverted CHECK or a restored FK puts 14 of 39 profiles back
--     outside the board with nothing on screen to say so.
union all
select '26 · a post can be homed on a person',
  case when (select pg_get_constraintdef(oid) from pg_constraint where conname = 'posts_home_check') is null
         then 'FAIL — posts_home_check is gone'
       when (select pg_get_constraintdef(oid) from pg_constraint where conname = 'posts_home_check') not like '%profile_id%'
         then 'PASS — D238 not deployed yet'
       when not exists (select 1 from pg_policies where tablename = 'posts' and policyname = 'posts_profile_read')
         then 'FAIL — a person-homed post has no reader policy'
       when (select pg_get_constraintdef(oid) from pg_constraint where conname = 'post_kudos_pkey') not like '%profile_id%'
         then 'FAIL — posts widened but post_kudos is still keyed on a membership'
       when exists (select 1 from pg_constraint where conname = 'post_kudos_member_id_fkey')
         then 'FAIL — a reaction still requires a shared league'
       else 'PASS — homed, readable, and reactable without a league' end,
  'posts.profile_id + posts_profile_read + post_kudos(post_id, profile_id, emoji)'

-- 27 · D241 · the person link is a VALUE on an existing CHECK and a BRANCH in
--     an endpoint that is already one of L-45's twelve. The thing that must
--     never be true is a thirteenth anon endpoint, so the redemption — the
--     half that writes — is asserted signed-in only.
union all
select '27 · the person link keeps the anon surface at twelve',
  case when (select pg_get_constraintdef(oid) from pg_constraint where conname = 'shares_kind_check') not like '%person%'
         then 'PASS — D241 not deployed yet'
       when to_regprocedure('public.redeem_share(uuid)') is null
         then 'FAIL — shares.kind admits a person but nothing can redeem one'
       when has_function_privilege('anon', 'public.redeem_share(uuid)', 'execute')
         then 'FAIL — redeem_share is executable by anon: that is a thirteenth endpoint'
       when not has_function_privilege('authenticated', 'public.redeem_share(uuid)', 'execute')
         then 'FAIL — redeem_share is callable by nobody'
       else 'PASS — the card is anon, the buddy request is not' end,
  'shares.kind = person · share_info branch · redeem_share to authenticated only'

-- 28 · D253 · the plan link rides the SAME CHECK and the SAME two functions.
--     It also may not widen `set_round_rsvp`: the seat is taken inside
--     `redeem_share`, and D69's guard on the RSVP write stays exactly as it is.
--     THE SENTENCE MOVED, THE GUARD DID NOT (2026-09-09). D296's voice pass
--     (20261012090000) rewrote the raise as "Only the host and tagged GOLFERS
--     can RSVP to this round" — L-42, the vocabulary is the crew's — and that
--     migration carries its own self-check asserting the new wording is present
--     and the old absent. This check still grepped "tagged players", so it read
--     an intact guard as a widened one and returned FAIL against a correct
--     production. A proxy that names a sentence has to move when the sentence
--     does; the thing being guarded is the host/tagged test, not the wording.
union all
select '28 · the plan link keeps the anon surface at twelve',
  case when (select pg_get_constraintdef(oid) from pg_constraint where conname = 'shares_kind_check') not like '%plan%'
         then 'PASS — D253 not deployed yet'
       when has_function_privilege('anon', 'public.redeem_share(uuid)', 'execute')
         then 'FAIL — redeem_share is executable by anon: that is a thirteenth endpoint'
       when (select prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'set_round_rsvp')
              not like '%Only the host and tagged golfers%'
         then 'FAIL — D69 guard was widened; the link was supposed to seat, not the function'
       else 'PASS — one plan, one seat, and D69 untouched' end,
  'shares.kind = plan · share_info branch · the seat is taken inside redeem_share'

-- 29 · D242 · a forfeit carries its terms in WORDS, never an amount in a
--     column. The rule is load-bearing for store review (20260724120000:10-13)
--     and a WIDENING is exactly when a rule gets quietly dropped, so it is a
--     tripwire rather than a comment. Exactly one home is a CHECK, and the
--     read moved with the write or the widened writer inserts rows nobody can
--     ever see.
union all
select '29 · a forfeit has no money column, and exactly one home',
  case when (select count(*) from information_schema.columns
              where table_schema = 'public' and table_name = 'forfeits'
                and column_name ~* '(cents|amount|dollars|stake|price|money)') > 0
         then 'FAIL — forfeits grew a money column; terms are prose (D64/D242)'
       when (select count(*) from information_schema.columns
              where table_schema = 'public' and table_name = 'forfeits'
                and column_name = 'event_id') = 0
         then 'PASS — D242 not deployed yet'
       when not exists (select 1 from pg_constraint
                         where conname in ('forfeits_one_home', 'forfeits_has_home')
                           and conrelid = 'public.forfeits'::regclass)
         then 'FAIL — the one-home CHECK is gone'
       when (select qual::text from pg_policies
              where schemaname = 'public' and tablename = 'forfeits' and policyname = 'forfeits_read')
              not like '%party_b%'
         then 'FAIL — forfeits_read cannot see a forfeit between two buddies with no season'
       else 'PASS — four homes, one at a time, and no amount anywhere' end,
  'forfeits.league_id nullable · event_id · scheduled_round_id · party_b'

-- 30 · D237 · `callout_mutes` is the WRITER's memory, not a surface. CC-52:
--     pg_default_acl still grants everything on every new table, so a new
--     table is born wide and this is the standing proof it was sealed.
union all
select '30 · callout_mutes is sealed, and a callout scores nothing',
  case when to_regclass('public.callout_mutes') is null then 'PASS — D237 not deployed yet'
       when has_table_privilege('anon', 'public.callout_mutes', 'select')
         or has_table_privilege('authenticated', 'public.callout_mutes', 'select')
         then 'FAIL — callout_mutes is readable; nothing may render "he muted you" (L-22)'
       when has_function_privilege('anon', 'public.call_out(uuid,date,text)', 'execute')
         or has_function_privilege('anon', 'public.respond_callout(uuid,boolean)', 'execute')
         then 'FAIL — a callout RPC is reachable by anon'
       when (select prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'call_out') not like '%league_id%'
         then 'FAIL — call_out must mint league_id null; a callout scores zero, always'
       else 'PASS — sealed, authenticated-only, and league_id null' end,
  'callout_mutes revoked from all · call_out / respond_callout to authenticated'

-- 31 · R-K / D256 · `round_worth` is the AUTHORITY for what a round is worth,
--     and the two client ports (`RoundWorth.gain`, `csRoundWorth`) are pinned
--     to it by their own tests. This is the pin on the server's half: the same
--     table the migration's header states, evaluated by the live function.
--     Check 17 does this for cup_points and is the shape being copied.
union all
select '31 · what a round is worth, and it is a ceiling',
  case when to_regclass('public.v_rounds_ranked') is null then 'PASS — schema not deployed yet'
       when not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                         where n.nspname = 'public' and p.proname = 'round_worth')
         then 'PASS — R-K not deployed yet'
       when round_worth(4, 2, 6)    is distinct from 12 then 'FAIL — a slot is open: the round ADDS its points'
       when round_worth(4, 4, 6)    is distinct from  6 then 'FAIL — full: the round BUMPS the worst counter'
       when round_worth(4, 4, 12)   is distinct from  0 then 'FAIL — a month of top-band rounds gains nothing'
       when round_worth(4, 4, null) is not null          then 'FAIL — full with an unknown counter has no honest answer'
       when round_worth(null, 9, null) is distinct from 12 then 'FAIL — uncapped: every round counts'
       when has_function_privilege('anon', 'public.round_worth(integer,integer,numeric)', 'execute')
         then 'FAIL — round_worth is reachable by anon'
       else 'PASS — 12 / 6 / 0 / null / 12, and no anon execute' end,
  'round_worth(cap,used,worst) · the table in 20261001090000''s header'

-- 32 · D300 · A STORAGE POLICY NEVER READS A TABLE THE GOLFER CANNOT.
--     Postgres evaluates EVERY permissive policy for a command, so one policy
--     that reads a revoked table kills every write to `storage.objects` — for
--     every bucket, by everybody. That is not hypothetical: `shares` was
--     revoked from `authenticated` on 2026-07-22 and two policies that read it
--     landed on 2026-07-23, and no golfer could upload a photograph of any
--     kind for the 47 days that followed. Nothing caught it, because the two
--     halves are each correct and the client's own error sentence says
--     "check your signal" (L-32: a golfer never reads a code).
--     The rule is general on purpose. A check that only knew about `shares`
--     would be a check that let the next one through.
union all
select '32 · a storage policy reads nothing the golfer cannot',
  case when (select count(*) from pg_policies p
              cross join (select c.relname
                            from pg_class c join pg_namespace n on n.oid = c.relnamespace
                           where n.nspname = 'public' and c.relkind in ('r','p','v','m')
                             and not has_table_privilege('authenticated', c.oid, 'SELECT')) t(table_name)
             where p.schemaname = 'storage' and p.tablename = 'objects'
               and (coalesce(p.qual,'') || ' ' || coalesce(p.with_check,'')) ~ ('\m' || t.table_name || '\M')) > 0
       then 'FAIL — ' || (select string_agg(p.policyname || ' reads ' || t.table_name, ', ')
                            from pg_policies p
                            cross join (select c.relname
                                          from pg_class c join pg_namespace n on n.oid = c.relnamespace
                                         where n.nspname = 'public' and c.relkind in ('r','p','v','m')
                                           and not has_table_privilege('authenticated', c.oid, 'SELECT')) t(table_name)
                           where p.schemaname = 'storage' and p.tablename = 'objects'
                             and (coalesce(p.qual,'') || ' ' || coalesce(p.with_check,'')) ~ ('\m' || t.table_name || '\M'))
            || ' — every upload dies with that table''s name in the message'
       else 'PASS — every storage policy reads only what the caller may' end,
  'pg_policies(storage.objects) × public relations authenticated cannot select'

-- 33 · D343 · a plan seats the host who declared it.
--     `declare_round` wrote no `round_rsvp` row for its own caller, so three
--     surfaces disagreed about the same plan: the roster array synthesises the
--     host as 'in', `my_rsvp` read the real table and came back null, and Home
--     therefore offered the host "Say you're in" about their own round while
--     both clients had already toasted "You're in" at creation. The check is
--     scoped to plans that have not happened yet, which is exactly what the
--     migration backfilled — a past plan's host is left as the record found
--     them, because seating one would move an `rsvp_in` somebody has read.
union all
select '33 · a plan seats the host who declared it',
  case when (select count(*) from scheduled_rounds sr
              where sr.play_on >= current_date
                and not exists (select 1 from round_rsvp r
                                 where r.round_id = sr.id and r.profile_id = sr.profile_id)) > 0
       then 'FAIL — ' || (select count(*)::text from scheduled_rounds sr
                           where sr.play_on >= current_date
                             and not exists (select 1 from round_rsvp r
                                              where r.round_id = sr.id and r.profile_id = sr.profile_id))
            || ' future plan(s) whose host was never seated — Home will ask them to say they are in'
       else 'PASS — every future plan has its host on the sheet' end,
  'scheduled_rounds(play_on >= today) × round_rsvp'

-- 34 · D353 · a band nobody can answer is never served.
--     D345 reached production without `schema_migrations` knowing, and its one
--     gate was `p_today is not null` — which every shipped build already sent.
--     So the after-golf card went live on clients with no Later, no Didn't play
--     and no date prefill: a card a golfer could neither answer nor dismiss,
--     whose only door opened a blank composer dated today. This check is the
--     claim made self-enforcing. It reads the DEPLOYED function, not the file.
union all
select '34 · the after-golf band waits for a client that can answer it',
  case
    when (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'home_dispatch') <> 1
      then 'FAIL — home_dispatch does not resolve to exactly one function; the overload trap has fired'
    when (select position('afterplan:' in pg_get_functiondef(p.oid)) = 0
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'home_dispatch')
      then 'PASS — this database has no after-golf band to gate'
    when (select position('afterplan.v1' in pg_get_functiondef(p.oid)) = 0
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'home_dispatch')
      then 'FAIL — the after-golf band is live with NO capability gate; every shipped client that sends p_today gets a card it cannot answer'
    when (select pg_get_function_result(p.oid) <> 'jsonb'
            from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'answer_plan_followup')
      then 'FAIL — answer_plan_followup returns void; a client cannot tell a recorded answer from an already-terminal one'
    else 'PASS — the band requires a declared capability, and an answer says what it did' end,
  'pg_get_functiondef(home_dispatch) × answer_plan_followup result type'

-- 35 · D376 · the Pro's pen reaches the table. A ruling is a season_adjustments
--     row of kind override with a member; v_individual_standings must sum it,
--     or the board says +3 and the table does not move — work shown that is
--     not the work. Recomputes every ruled member's total from rounds + ledger.
union all
select '35 · the standings views sum the ledger (D376)',
  case when to_regprocedure('public.adjust_points(uuid,uuid,integer,text,date)') is null
         then 'PASS — the pen is not deployed yet'
       when bad = 0 then 'PASS — ' || ruled || ' ruled total(s), every one equal to rounds + ledger'
       else 'FAIL — ' || bad || ' member total(s) ignore a ruling' end,
  'v_individual_standings vs. a recomputation from v_rounds_ranked and season_adjustments'
from (
  select count(*) as ruled,
         count(*) filter (where v.points <> r.pts + x.adj) as bad
    from (select a.season_id, a.member_id, sum(a.points) as adj
            from season_adjustments a
           where a.kind = 'override' and a.member_id is not null
           group by 1, 2) x
    join v_individual_standings v on v.season_id = x.season_id and v.member_id = x.member_id
    join league_members lm on lm.id = v.member_id
    join league_settings ls on ls.league_id = lm.league_id
    left join lateral (
      select coalesce(sum(rr.points) filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0) as pts
        from v_rounds_ranked rr
       where rr.member_id = v.member_id and rr.season_id = v.season_id) r on true
) t

-- 36 · D378 / D371 · the Stage D bundle and the counted door hold in production:
--     the three write doors read is_active_member (never is_league_member,
--     which keeps READ for leavers); lock_league refuses snake/live; the Final
--     and the snapshot key on the league's date; door_attempts is unreachable
--     by any client role.
union all
select '36 · D378 bundle and D371 door counter',
  case when to_regprocedure('public.is_active_member(uuid)') is null
         then 'PASS — the bundle is not deployed yet'
       when problems = '' then 'PASS — leavers gated on writes, snake refused, league-local Final, private door counter'
       else 'FAIL — ' || problems end,
  'prosrc of create_major / enter_major / create_event / lock_league / daily_season_tick / enter_cup_final / cup_final_race / snapshot_week; door_attempts privileges'
from (
  select concat_ws('; ',
    case when exists (select 1 from pg_proc where pronamespace = 'public'::regnamespace
                        and proname in ('create_major','enter_major','create_event')
                        and prosrc like '%is_league_member(%') then 'a write door still reads is_league_member' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'is_league_member')
              like '%left_at%' then 'is_league_member gates READ on left_at' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'lock_league')
              not like '%Squads are drawn or placed by the Pro this season.%' then 'lock_league accepts snake/live' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'daily_season_tick')
              not like '%perform snapshot_week(se.id);%' then 'the tick does not cut the week' end,
    case when exists (select 1 from pg_proc where pronamespace = 'public'::regnamespace
                        and proname in ('enter_cup_final','cup_final_race','snapshot_week')
                        and prosrc like '%current_date%') then 'the Final or the snapshot still reads current_date' end,
    case when to_regclass('cupseason_private.door_attempts') is not null
          and (has_any_column_privilege('anon', 'cupseason_private.door_attempts', 'SELECT')
            or has_any_column_privilege('authenticated', 'cupseason_private.door_attempts', 'SELECT')
            or has_table_privilege('authenticated', 'cupseason_private.door_attempts', 'INSERT'))
         then 'a client role can reach door_attempts' end
  ) as problems
) t

-- 37 · D375 · season two is a re-up. Every member carries a season on record,
--     the lens and the individual table read it, the re-up doors record and
--     say the yes, the hat and the start read the season's roster, the pot
--     counts the yeses, and the two helpers are the engine's alone.
union all
select '37 · season two is a re-up (D375)',
  case when (select count(*) from information_schema.columns
              where table_schema = 'public' and table_name = 'league_members' and column_name = 'agreed_seasons') = 0
         then 'PASS — the re-up is not deployed yet'
       when problems = '' then 'PASS — every member on record; the lens, the doors, the hat, the start and the pot read it'
       else 'FAIL — ' || problems end,
  'league_members.agreed_seasons × v_rounds_ranked / v_individual_standings × prosrc of respond_invite, join_league, run_it_back, randomize_squads, start_season, recompute_season_payouts, invite_golfer, my_invites × helper grants'
from (
  select concat_ws('; ',
    case when exists (select 1 from league_members where agreed_seasons is null or agreed_seasons = '{}')
         then 'a member carries no season on record' end,
    case when pg_get_viewdef('public.v_rounds_ranked'::regclass) not like '%agreed_seasons%'
           or pg_get_viewdef('public.v_rounds_ranked'::regclass) not like '%prior_left_at%'
         then 'v_rounds_ranked does not read the record' end,
    case when pg_get_viewdef('public.v_individual_standings'::regclass) not like '%agreed_seasons%'
         then 'v_individual_standings lists members who did not say yes' end,
    case when exists (select 1 from pg_proc where pronamespace = 'public'::regnamespace
                        and proname in ('respond_invite', 'join_league')
                        and prosrc not like '%_agree_to_season(%') then 'a join door does not record the yes' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'run_it_back')
              not like '%The invitations are out%' then 'run_it_back seats instead of asking' end,
    case when exists (select 1 from pg_proc where pronamespace = 'public'::regnamespace
                        and proname in ('randomize_squads', 'start_season')
                        and prosrc not like '%_season_roster(p_season)%') then 'the hat or the start reads the whole league' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'recompute_season_payouts')
              not like '%agreed_seasons%' then 'the pot counts members who did not say yes' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'invite_golfer')
              not like '%same rules, fresh table%' then 'the Pro cannot ask again' end,
    case when position('season_number integer, reup boolean' in
                 (select pg_get_function_result(oid) from pg_proc where pronamespace = 'public'::regnamespace and proname = 'my_invites')) = 0
         then 'my_invites does not say which season' end,
    case when has_function_privilege('authenticated', 'public._season_roster(uuid)', 'execute')
           or has_function_privilege('authenticated', 'public._agree_to_season(uuid, uuid)', 'execute')
           or has_function_privilege('anon', 'public._agree_to_season(uuid, uuid)', 'execute')
         then 'a client role can reach a re-up helper' end,
    case when not exists (select 1 from pg_trigger where tgname = 'league_members_agree_on_join'
                             and tgrelid = 'public.league_members'::regclass and not tgisinternal)
         then 'a fresh seat records no season' end
  ) as problems
) t

-- 38 · D382 · the record book has one door. No client role writes seasons,
--     the ledger, squads, seats, buy-ins or the Pro's log, nor edits or deletes
--     a league (INSERT on leagues stays: leagues_create binds the creator); no
--     write policy survives on those tables; assign_player refuses in the Final
--     and after the close, and never moves a seated golfer once under way.
union all
select '38 · the record book has one door (D382)',
  case when problems = '' then 'PASS — the Pro writes through the pen, and a Final''s squads hold'
       else 'FAIL — ' || problems end,
  'relacl × pg_policies on seasons, season_adjustments, squads, squad_members, buy_ins, commissioner_log, leagues × prosrc of assign_player'
from (
  select concat_ws('; ',
    (select 'a client role writes: ' || string_agg(format('%s %s %s', c.relname, a.grantee::regrole, a.privilege_type), ', ')
       from pg_class c, lateral aclexplode(c.relacl) a
      where c.oid in ('public.seasons'::regclass, 'public.season_adjustments'::regclass,
                      'public.squads'::regclass, 'public.squad_members'::regclass,
                      'public.buy_ins'::regclass, 'public.commissioner_log'::regclass,
                      'public.leagues'::regclass)
        and a.grantee <> 0
        and a.grantee::regrole::text in ('authenticated', 'anon')
        and a.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
        and not (c.relname = 'leagues' and a.privilege_type = 'INSERT')
     having count(*) > 0),
    (select 'a write policy survives: ' || string_agg(tablename || '.' || policyname, ', ')
       from pg_policies
      where schemaname = 'public'
        and tablename in ('seasons', 'season_adjustments', 'squads', 'squad_members',
                          'buy_ins', 'commissioner_log', 'leagues')
        and cmd <> 'SELECT'
        and not (tablename = 'leagues' and cmd = 'INSERT')
     having count(*) > 0),
    case when coalesce((select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'assign_player'), '')
              not like '%se.status in (''cup_final'', ''complete'')%'
           or coalesce((select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'assign_player'), '')
              not like '%v_started and v_seated%'
         then 'assign_player has no phase rule' end
  ) as problems
) t

-- 39 · D383 · a finished season keeps its book. Every complete season has a
--     book; the lens reads a booked season from it and never from live rounds;
--     the close writes it on every path (the trigger); no client role writes
--     it or reaches the trigger function; post_round never stamps a complete
--     season; run_it_back refuses a first tee inside the previous season.
union all
select '39 · a finished season keeps its book (D383)',
  case when to_regclass('public.season_books') is null then 'PASS — the book is not deployed yet'
       when problems = '' then 'PASS — every finished season reads from its book, and the close writes it'
       else 'FAIL — ' || problems end,
  'seasons(complete) × season_books × pg_get_viewdef(v_rounds_ranked) × pg_trigger × prosrc of post_round, run_it_back'
from (
  select case when to_regclass('public.season_books') is null then '' else concat_ws('; ',
    (select count(*) || ' complete season(s) with no book' from seasons s
      where s.status = 'complete' and not exists (select 1 from season_books b where b.season_id = s.id)
     having count(*) > 0),
    case when pg_get_viewdef('public.v_rounds_ranked'::regclass) not like '%season_book_rows%'
           or pg_get_viewdef('public.v_rounds_ranked'::regclass) not like '%season_books bk%'
         then 'the lens scores finished seasons live' end,
    case when not exists (select 1 from pg_trigger where tgname = 'seasons_book_on_close'
                             and tgrelid = 'public.seasons'::regclass and not tgisinternal)
         then 'the close does not write the book' end,
    case when has_any_column_privilege('authenticated', 'public.season_book_rows', 'INSERT')
           or has_any_column_privilege('authenticated', 'public.season_books', 'INSERT')
           or has_table_privilege('anon', 'public.season_book_rows', 'SELECT')
           or has_function_privilege('authenticated', 'public._book_season()', 'EXECUTE')
         then 'a client role can reach the book' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'post_round')
              like '%''active'', ''cup_final'', ''complete''%' then 'post_round stamps a complete season' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'run_it_back')
              not like '%[D383]%' then 'run_it_back accepts an overlapping first tee' end
  ) end as problems
) t

-- 40 · D384 · a season shorter than six weeks is a points-table season. The
--     tick and enter_cup_final never take one into a Final, lock_league stores
--     the table for one, set_league_finish refuses a Final for one, and no live
--     short season still promises a Final or sits in one.
union all
select '40 · a short season is a table season (D384)',
  case when problems = '' then 'PASS — under six weeks, the points table decides everywhere'
       else 'FAIL — ' || problems end,
  'prosrc of enter_cup_final, daily_season_tick, lock_league, set_league_finish × live seasons under 42 days'
from (
  select concat_ws('; ',
    (select string_agg(p.proname, ', ') || ' has no length guard' from pg_proc p
      where p.pronamespace = 'public'::regnamespace
        and p.proname in ('enter_cup_final', 'daily_season_tick', 'lock_league', 'set_league_finish')
        and p.prosrc not like '%[D384]%'
     having count(*) > 0),
    (select count(*) || ' live short season(s) promise or play a Final'
       from seasons s join league_settings ls on ls.league_id = s.league_id
      where s.status in ('active', 'cup_final') and s.ends_on - s.starts_on + 1 < 42
        and (s.status = 'cup_final' or (coalesce(ls.finish, 'cup_final') = 'cup_final'
             and s.number = (select max(s2.number) from seasons s2 where s2.league_id = s.league_id)))
     having count(*) > 0)
  ) as problems
) t

-- 41 · D385 · a withdrawn photo is withdrawn. Remove, replace and delete
--     revoke the round's links on the server; withdraw_round_shares hands the
--     caller's tokens back for the client to remove the copies (authenticated
--     only); share_info reads a photo only while the round carries one.
union all
select '41 · a withdrawn photo is withdrawn (D385)',
  case when problems = '' then 'PASS — remove, replace and delete revoke; the client can find every copy'
       else 'FAIL — ' || problems end,
  'prosrc of clear_round_photo, set_round_photo, delete_round, share_info × withdraw_round_shares grants'
from (
  select concat_ws('; ',
    (select string_agg(p.proname, ', ') || ' does not revoke' from pg_proc p
      where p.pronamespace = 'public'::regnamespace
        and p.proname in ('clear_round_photo', 'set_round_photo', 'delete_round', 'share_info')
        and p.prosrc not like '%[D385]%'
     having count(*) > 0),
    case when to_regprocedure('public.withdraw_round_shares(uuid)') is null
         then 'withdraw_round_shares is missing'
         when not has_function_privilege('authenticated', 'public.withdraw_round_shares(uuid)', 'EXECUTE')
           or has_function_privilege('anon', 'public.withdraw_round_shares(uuid)', 'EXECUTE')
         then 'withdraw_round_shares is wrongly granted' end
  ) as problems
) t

-- 42 · launch audit S6 · one card, one claim. claim_round and claim_scan_round
--     lock the seat they read (L-09), and signed-out guest_live_state returns
--     only the status of a finished or claimed seat (L-27), still anon.
union all
select '42 · one card, one claim; a finished link shows its status only (S6)',
  case when problems = '' then 'PASS — claims lock their seat, and a spent link tells nothing'
       else 'FAIL — ' || problems end,
  'prosrc of claim_round, claim_scan_round, guest_live_state'
from (
  select concat_ws('; ',
    (select string_agg(p.proname, ', ') || ' reads its seat without a lock' from pg_proc p
      where p.pronamespace = 'public'::regnamespace and p.proname in ('claim_round', 'claim_scan_round')
        and p.prosrc not like '%for update%'
     having count(*) > 0),
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'guest_live_state')
              not like '%[S6]%' then 'guest_live_state returns a finished round' end,
    case when not has_function_privilege('anon', 'public.guest_live_state(uuid)', 'EXECUTE')
         then 'guest_live_state lost its anon grant' end
  ) as problems
) t

-- 43 · launch audit S3 · the record names the champion. `_final_place` is the
--     one answer (crown-aware when complete, tie-aware while live), engine-only;
--     native_home's standing reads it and never breaks a points tie by name;
--     my_league_record is the record both clients print.
union all
select '43 · the record names the champion (S3)',
  case when problems = '' then 'PASS — one place producer, crown-aware and tie-aware, on both clients'
       else 'FAIL — ' || problems end,
  'to_regprocedure(_final_place, my_league_record) × prosrc of native_home × grants'
from (
  select concat_ws('; ',
    case when to_regprocedure('public._final_place(uuid, uuid)') is null then '_final_place is missing'
         when has_function_privilege('authenticated', 'public._final_place(uuid, uuid)', 'EXECUTE')
         then '_final_place is reachable by a client' end,
    case when to_regprocedure('public.my_league_record()') is null then 'my_league_record is missing'
         when not has_function_privilege('authenticated', 'public.my_league_record()', 'EXECUTE')
         then 'my_league_record is not granted' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              not like '%_final_place%' then 'native_home ranks a finished season by the table' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              like '%over w as rk%' then 'native_home breaks a points tie by name' end
  ) as problems
) t

-- 44 · D390 · a trophy per season. The year key is gone, league trophies are
--     unique per season, and the award writes the season.
union all
select '44 · a trophy per season (D390)',
  case when problems = '' then 'PASS — two seasons in one year are two trophies'
       else 'FAIL — ' || problems end,
  'pg_indexes(trophies) × prosrc of award_season_trophies'
from (
  select concat_ws('; ',
    case when to_regclass('public.trophies_league_uq') is not null then 'league trophies are still keyed by year' end,
    case when to_regclass('public.trophies_league_season_uq') is null then 'league trophies have no season key' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'award_season_trophies')
              not like '%se.league_id, yr, se.id%' then 'the award does not write the season' end
  ) as problems
) t

-- 45 · D388 · §14.3's ladder everywhere. The crown, the King and the seeds
--     count months won head to head among the tied, on §3.3's month score, and
--     one coin per contender serves the crown and the King.
union all
select '45 · the ladder is head to head (D388)',
  case when problems = '' then 'PASS — h2h months won on the §3.3 month, one coin per tie'
       else 'FAIL — ' || problems end,
  'prosrc of close_season, enter_cup_final'
from (
  select concat_ws('; ',
    (select string_agg(p.proname, ', ') || ' counts months against the whole field' from pg_proc p
      where p.pronamespace = 'public'::regnamespace and p.proname in ('close_season', 'enter_cup_final')
        and p.prosrc not like '%[D388]%'
     having count(*) > 0),
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'close_season')
              not like '%update _king k set coin = c.coin from _coin c%' then 'the crown and the King flip separate coins' end
  ) as problems
) t

-- 46 · D386 · a late joiner gets a seat. join_league and respond_invite seat a
--     joiner once the league is in season; _late_squad stays out of the draft
--     and the Final; a seat taken under way counts forward only.
union all
select '46 · a late joiner gets a seat (D386)',
  case when problems = '' then 'PASS — seated on the thinnest squad, counted from the seat'
       else 'FAIL — ' || problems end,
  'prosrc of join_league, _late_squad, assign_player × pg_get_viewdef(v_squad_standings)'
from (
  select concat_ws('; ',
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'join_league')
              not like '%_late_squad(%' then 'a code join is never seated' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = '_late_squad')
              not like '%[D386]%' then '_late_squad seats before the draw' end,
    case when pg_get_viewdef('public.v_squad_standings'::regclass) not like '%seated_at%'
         then 'a late seat counts backwards' end
  ) as problems
) t

-- 47 · D387 · the result explains itself. round_card's scalars are a league's
--     own number (never an allowance nobody scored), native_home's last season
--     includes the one that just finished and reads the seat, and the
--     settlement post prints the ledger's money.
union all
select '47 · the receipt uses the league''s number (D387)',
  case when problems = '' then 'PASS — one number per lens, the champion named, the money exact'
       else 'FAIL — ' || problems end,
  'prosrc of round_card, native_home, close_season'
from (
  select concat_ws('; ',
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'round_card')
              not like '%[D387]%' then 'round_card explains with an allowance nobody scored' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              like '%lm9.squad_id%' then 'native_home joins a column that does not exist' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'close_season')
              like '%/ 100.0)%' then 'the settlement post rounds the money' end
  ) as problems
) t

-- 48 · D389 · season two is only for yeses. Re-up invitations can lapse and
--     the first tee lapses them; the clash and the owed list read the season's
--     roster; native_home says whether the golfer is in the current season.
union all
select '48 · season two is only for yeses (D389)',
  case when problems = '' then 'PASS — invitations lapse at the first tee; nobody outside the season is paired or owes'
       else 'FAIL — ' || problems end,
  'member_invites status check × prosrc of daily_season_tick, open_week_clash, close_season, native_home'
from (
  select concat_ws('; ',
    case when not exists (select 1 from pg_constraint where conrelid = 'public.member_invites'::regclass
                            and pg_get_constraintdef(oid) like '%lapsed%') then 'an invitation cannot lapse' end,
    (select string_agg(p.proname, ', ') || ' reads the whole league' from pg_proc p
      where p.pronamespace = 'public'::regnamespace
        and p.proname in ('daily_season_tick', 'open_week_clash', 'close_season', 'native_home')
        and p.prosrc not like '%[D389]%'
     having count(*) > 0)
  ) as problems
) t

-- 49 · launch audit S12 · the first screens say what is so. "Under 80" means
--     eighteen holes; a solo season stores no floor to promise.
union all
select '49 · the first screens say what they mean (S12)',
  case when problems = '' then 'PASS — no nine-hole "Under 80", no solo minimum'
       else 'FAIL — ' || problems end,
  'prosrc of home_stories, lock_league'
from (
  select concat_ws('; ',
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'home_stories')
              not like '%rk.holes_played = 18%' then 'a nine-hole round can read as Under 80' end,
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'lock_league')
              not like '%[S12]%' then 'a solo season can promise a minimum' end
  ) as problems
) t

-- 50 · I4 · the Book counts what the squad counts. One seat rule answers for the squad
--     table, the Book's squad receipts and the ladder's month scores; a finished season's
--     book keeps each line's post time; the Book says frozen and withdrawn.
union all
select '50 · the Book counts what the squad counts (I4)',
  case when problems = '' then 'PASS — one seat rule for the table, the Book, the Race and a tie-break'
       else 'FAIL — ' || problems end,
  'pg_get_viewdef(v_squad_standings) × prosrc of season_book, close_season, enter_cup_final × season_book_rows'
from (
  select concat_ws('; ',
    case when to_regprocedure('public._counts_for_seat(uuid, timestamptz)') is null then 'the seat helper is missing' end,
    case when pg_get_viewdef('public.v_squad_standings'::regclass) not like '%_counts_for_seat%' then 'the squad table has its own seat rule' end,
    (select string_agg(p.proname, ', ') || ' counts a round the squad does not' from pg_proc p
      where p.pronamespace = 'public'::regnamespace and p.proname in ('season_book', 'close_season', 'enter_cup_final')
        and p.prosrc not like '%[I4]%'
     having count(*) > 0),
    case when not exists (select 1 from information_schema.columns where table_schema = 'public'
                            and table_name = 'season_book_rows' and column_name = 'round_created_at')
         then 'a finished season forgets when its rounds were posted' end
  ) as problems
) t

-- 51 · I5 · a withdrawn photo is gone. Every revocation queues a cleanup obligation that
--     only a storage check can complete; the owner reads and retries it; the service
--     side is service-role only; nothing new is open signed out.
union all
select '51 · a withdrawn photo is gone, not just unlinked (I5)',
  case when problems = '' then 'PASS — every revocation is an obligation until storage says it is gone'
       else 'FAIL — ' || problems end,
  'pg_trigger(shares) × share_cleanup grants × cleanup RPC grants'
from (
  select concat_ws('; ',
    case when to_regclass('public.share_cleanup') is null then 'there is no cleanup obligation' end,
    case when not exists (select 1 from pg_trigger where tgname = 'shares_queue_cleanup'
                             and tgrelid = 'public.shares'::regclass and not tgisinternal)
         then 'a revocation does not queue its cleanup' end,
    case when to_regclass('public.share_cleanup') is not null
          and (has_table_privilege('authenticated', 'public.share_cleanup', 'UPDATE')
               or has_table_privilege('anon', 'public.share_cleanup', 'SELECT'))
         then 'a client can write or anon can read the obligation' end,
    case when to_regprocedure('public._share_cleanup_report(uuid, text)') is not null
          and (has_function_privilege('authenticated', 'public._share_cleanup_report(uuid, text)', 'EXECUTE')
               or has_function_privilege('anon', 'public.confirm_share_cleanup(uuid)', 'EXECUTE'))
         then 'a service or owner door is open to the wrong role' end
  ) as problems
) t

-- 52 · I5b · one share, one attempt (Codex's native contract). The three lifecycle RPCs
--     are authenticated-only, the attempt ledger and shares stay unreadable to clients,
--     and the reclaimer is service-role only.
union all
select '52 · one share, one attempt (I5b)',
  case when problems = '' then 'PASS — prepare / finish / status, owner-only, never reactivating'
       else 'FAIL — ' || problems end,
  'grants of prepare_round_share, finish_round_share, round_share_status, _expire_share_attempts × share_attempts, shares'
from (
  select concat_ws('; ',
    case when to_regprocedure('public.prepare_round_share(uuid, boolean, uuid)') is null
           or to_regprocedure('public.finish_round_share(uuid, boolean)') is null
           or to_regprocedure('public.round_share_status(uuid)') is null then 'a lifecycle RPC is missing'
         when not has_function_privilege('authenticated', 'public.prepare_round_share(uuid, boolean, uuid)', 'EXECUTE')
           or has_function_privilege('anon', 'public.prepare_round_share(uuid, boolean, uuid)', 'EXECUTE')
           or has_function_privilege('authenticated', 'public._expire_share_attempts(uuid)', 'EXECUTE')
         then 'a lifecycle grant is wrong' end,
    case when to_regclass('public.share_attempts') is not null
          and (has_table_privilege('authenticated', 'public.share_attempts', 'SELECT')
               or has_table_privilege('authenticated', 'public.shares', 'SELECT'))
         then 'a client can read shares or the attempt ledger directly' end
  ) as problems
) t

-- 53 · the phone's payload and the Final (Codex's contract, I6). native_home carries
--     renewal_status and in_season beside the Book's points standing and S3's final
--     placement; the Final's surfaces read cup_finalists for their seeds.
union all
select '53 · the phone reads the season it is in, and the Final its own seeds (contract, I6)',
  case when problems = '' then 'PASS — renewal_status, in_season, final_place; seeds from cup_finalists'
       else 'FAIL — ' || problems end,
  'prosrc of native_home, season_scenarios, season_story, join_covenant_info'
from (
  select concat_ws('; ',
    case when (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              not like '%''renewal_status''%'
           or (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              not like '%''points_tied''%'
           or (select prosrc from pg_proc where pronamespace = 'public'::regnamespace and proname = 'native_home')
              not like '%''final_place''%' then 'native_home lost a contract field' end,
    (select string_agg(p.proname, ', ') || ' reads the live table for the Final''s seeds' from pg_proc p
      where p.pronamespace = 'public'::regnamespace and p.proname in ('season_scenarios', 'season_story')
        and p.prosrc not like '%[I6]%'
     having count(*) > 0)
  ) as problems
) t

)
select * from checks order by check_name;