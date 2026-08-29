-- Blind-audit test footprint — wipe (plan item Q-03)
--
-- DEADLINE: run before 2026-09-05 07:20 UTC. `daily_season_tick` starts both
-- audit seasons that morning (first tee Sat Sep 5), which posts board stories
-- and week snapshots into leagues that should not exist.
--
-- DRY RUN (default): the script ends in ROLLBACK and prints what it would
-- remove.   supabase db query --linked "$(cat docs/audit/blind-ux-2026-08-29/tools/wipe.sql)"
-- TO COMMIT: change the last line to `commit;` and run it again.
--
-- Removes: the seven audit auth users (their profiles, rounds, memberships,
-- posts and device tokens cascade), the three audit leagues, and the live-round
-- rows that reference those profiles WITHOUT a cascade (claimed_profile and
-- guest_profile_id are plain FKs and would otherwise RESTRICT the delete).
-- Touches nothing owned by a real account.

begin;

create temporary table _audit_emails(email text primary key);
insert into _audit_emails values
  ('jerecho+blind1@fischbeck3.com'),  -- organizer "Casey Ortega"
  ('jerecho+blind2@fischbeck3.com'),  -- joiner "Marcus Bell"
  ('jerecho+blind2x@fischbeck3.com'), -- joiner retry alias
  ('jerecho+blind3@fischbeck3.com'),  -- casual "Jordan Reyes"
  ('jerecho+blind4@fischbeck3.com'),  -- competitive "Priya Nair"
  ('jerecho+blind5@fischbeck3.com'),  -- novice "Dana Whitfield"
  ('jerecho+blind6@fischbeck3.com'),  -- skeptic "Sam Kowalski"
  ('jerecho+q01a@fischbeck3.com');    -- Q-01 lock verification, 2026-08-29

create temporary table _audit_profiles as
  select id from profiles where email in (select email from _audit_emails);

create temporary table _audit_leagues as
  select id, code, name from leagues where code in ('THEPTCQ5','DESEUU0K','QLOCS15V');

-- Guard: refuse to run if any league we are about to delete is run by someone
-- who is NOT an audit account, or if a real golfer ever joined one.
do $$
declare n int;
begin
  select count(*) into n
    from league_members m
    where m.league_id in (select id from _audit_leagues)
      and m.profile_id not in (select id from _audit_profiles);
  if n > 0 then
    raise exception 'ABORT: % real member(s) in an audit league — inspect before wiping', n;
  end if;

  select count(*) into n
    from leagues l
    join league_members m on m.league_id = l.id and m.role = 'commissioner'
    where m.profile_id in (select id from _audit_profiles)
      and l.id not in (select id from _audit_leagues);
  if n > 0 then
    raise exception 'ABORT: an audit account runs % league(s) not on the wipe list', n;
  end if;
end $$;

-- Nineteen FKs to leagues/league_members/profiles are ON DELETE NO ACTION, so
-- the leagues cascade alone hits a RESTRICT (found by the first dry run:
-- live_scores.updated_by -> league_members). Clear the children explicitly,
-- deepest first, then the leagues.

-- 1 · live rounds belonging to an audit league (cascades live_scores,
--     live_round_players and game_results with them).
delete from live_rounds where league_id in (select id from _audit_leagues);

-- 2 · references to an audit PROFILE from live rounds that survive (a guest
--     claim inside somebody else's round) — plain FKs, so null them.
update live_round_players set claimed_profile  = null where claimed_profile  in (select id from _audit_profiles);
update live_round_players set guest_profile_id = null where guest_profile_id in (select id from _audit_profiles);
update live_rounds set starter_profile_id = null where starter_profile_id in (select id from _audit_profiles);

-- 3 · league-scoped rows that hold a league_members FK with NO ACTION.
delete from post_comments where post_id in (select id from posts where league_id in (select id from _audit_leagues));
delete from posts               where league_id in (select id from _audit_leagues);
delete from buy_ins             where season_id in (select id from seasons where league_id in (select id from _audit_leagues));
delete from commissioner_log    where league_id in (select id from _audit_leagues);
delete from draft_picks         where draft_id  in (select id from drafts  where season_id in (select id from seasons where league_id in (select id from _audit_leagues)));
delete from season_adjustments  where season_id in (select id from seasons where league_id in (select id from _audit_leagues));
delete from feedback            where member_id in (select id from league_members where league_id in (select id from _audit_leagues));
update seasons set champion_member_id = null, runnerup_member_id = null, points_king_member_id = null
  where league_id in (select id from _audit_leagues);
delete from seasons             where league_id in (select id from _audit_leagues);
delete from league_members      where league_id in (select id from _audit_leagues);

-- 4 · profile-level references outside any league.
update member_invites set invited_by = null where invited_by in (select id from _audit_profiles);
delete from member_invites where profile_id in (select id from _audit_profiles)
                              or league_id in (select id from _audit_leagues);

-- growth_events keeps no FK to leagues; clear the audit league's rows by id.
delete from growth_events where league_id in (select id from _audit_leagues);

delete from leagues where id in (select id from _audit_leagues);
delete from auth.users where email in (select email from _audit_emails);

-- What is left (all four must be 0 before you commit).
select 'leagues'  as what, count(*) from leagues  where code in ('THEPTCQ5','DESEUU0K','QLOCS15V')
union all select 'auth users', count(*) from auth.users where email in (select email from _audit_emails)
union all select 'profiles',   count(*) from profiles   where email in (select email from _audit_emails)
union all select 'rounds',     count(*) from rounds     where profile_id in (select id from _audit_profiles);

rollback;   -- <<< change to `commit;` to actually wipe
