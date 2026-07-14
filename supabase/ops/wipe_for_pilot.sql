-- ============================================================================
-- WIPE FOR PILOT  —  DESTRUCTIVE, IRREVERSIBLE.
-- Clears ALL users + ALL game/league data. KEEPS the course catalog only.
-- Run in the Supabase SQL editor (runs as service role / postgres).
--
-- NOT a migration on purpose — lives in supabase/ops/ so `supabase db push`
-- never replays it. Copy-paste it, or run once from the editor.
--
-- >>> BACK UP FIRST (from your machine, before running this): <<<
--     supabase db dump -f pre_pilot_backup.sql
--
-- KEEPS (never named below): courses, course_tees, course_holes,
--                            api_courses, api_course_tees, api_course_holes
-- ============================================================================

begin;

-- Truncate every user/game table that actually exists (skips any whose
-- migration hasn't run yet, so the script is safe to run in any state).
do $$
declare
  t text;
  tables text[] := array[
    'profiles','friendships','rounds','round_holes','leagues','league_members',
    'league_settings','seasons','season_adjustments','squads','squad_members',
    'drafts','draft_picks','posts','post_comments','post_kudos','attestations',
    'buy_ins','commissioner_log','cup_finalists','game_results','invites',
    'member_invites','live_rounds','live_round_players','live_scores',
    'standings_snapshots','scheduled_rounds','events','event_teams',
    'event_players','event_sessions','event_duels','trophies',
    'push_subscriptions','feedback','pilot_feedback'
  ];
begin
  foreach t in array tables loop
    if to_regclass('public.'||t) is not null then
      execute format('truncate table public.%I restart identity cascade', t);
    end if;
  end loop;
end $$;

-- The login accounts themselves (cascades within the auth schema).
delete from auth.users;

commit;

-- Sanity check: course catalog intact, everything else at zero.
select 'courses'     as tbl, count(*) from public.courses
union all select 'api_courses',  count(*) from public.api_courses
union all select 'profiles',     count(*) from public.profiles
union all select 'rounds',       count(*) from public.rounds
union all select 'leagues',      count(*) from public.leagues
union all select 'auth.users',   count(*) from auth.users;
