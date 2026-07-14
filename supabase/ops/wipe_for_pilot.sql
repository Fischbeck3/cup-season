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

-- GOTCHA (learned the hard way): TRUNCATE ... CASCADE force-truncates EVERY
-- table with an FK to a truncated one, regardless of its ON DELETE rule. The
-- legacy `courses` table has courses.created_by -> profiles, so cascading the
-- profiles truncate nuked courses -> course_tees -> course_holes. The live
-- API cache (api_courses) has no such link and was never at risk, but protect
-- the legacy tables too: drop that FK before the wipe, recreate it (as ON
-- DELETE SET NULL, so a future profile delete just orphans provenance) after.
alter table public.courses drop constraint if exists courses_created_by_fkey;

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

-- Recreate the courses provenance FK as ON DELETE SET NULL. Null any surviving
-- created_by first (the profiles they pointed to are now gone) so the new
-- constraint validates.
update public.courses set created_by = null where created_by is not null;
alter table public.courses
  add constraint courses_created_by_fkey
  foreign key (created_by) references public.profiles(id) on delete set null;

commit;

-- Sanity check: course catalog intact, everything else at zero.
select 'courses'     as tbl, count(*) from public.courses
union all select 'api_courses',  count(*) from public.api_courses
union all select 'profiles',     count(*) from public.profiles
union all select 'rounds',       count(*) from public.rounds
union all select 'leagues',      count(*) from public.leagues
union all select 'auth.users',   count(*) from auth.users;
