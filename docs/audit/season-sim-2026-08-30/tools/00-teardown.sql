-- ============================================================================
-- Season simulator — TEARDOWN.
--
-- Removes the entire simulation footprint from production:
--   · every league a sim run created (all flagged sandbox=true)
--   · every cast member (auth.users on the unroutable @sim.cupseason.test)
--   · any observer seat (jerecho+simN@fischbeck3.com)
--   · the sim schema itself
--
-- WHY THIS IS NOT JUST "delete from leagues":
-- Fourteen tables reference public.league_members with ON DELETE NO ACTION —
-- season_adjustments, posts, post_comments, buy_ins, commissioner_log,
-- draft_picks, feedback, live_rounds, live_scores — and seasons itself carries
-- champion/runnerup/points_king member and squad references. Deleting a league
-- cascades to league_members, which then trips those FKs. So every child is
-- cleared first, in dependency order, and the seasons row's own pointers are
-- nulled before its squads and members go.
--
-- This is the same shape of bug the shipped sandbox_scrap (D65) has: it deletes
-- the league first and comments that the cascade "clears every no-action
-- member_id reference before the users go", which does not hold for any league
-- whose months closed with floor penalties.
--
-- Runs as a transaction ending in ROLLBACK so it can be rehearsed safely.
-- Change the last line to `commit;` to actually scrap.
-- ============================================================================
begin;

create temp table _doomed on commit drop as
select l.id
  from public.leagues l
 where l.sandbox is true
   and (
     -- tracked by the harness
     (to_regclass('sim.runs') is not null
      and l.id in (select league_id from sim.runs where league_id is not null))
     -- or identifiable by the cast it holds (a run that died before recording)
     or exists (select 1 from public.league_members lm
                  join public.profiles p on p.id = lm.profile_id
                 where lm.league_id = l.id
                   and (p.email like '%@sim.cupseason.test'
                        or p.email like 'jerecho+sim%@fischbeck3.com')));

create temp table _seasons on commit drop as
select s.id from public.seasons s where s.league_id in (select id from _doomed);

-- 1. the seasons' own pointers at members and squads
update public.seasons
   set champion_member_id = null, runnerup_member_id = null,
       points_king_member_id = null, champion_squad_id = null,
       runnerup_squad_id = null
 where id in (select id from _seasons);

-- 2. everything that references league_members / seasons / squads
delete from public.season_adjustments where season_id in (select id from _seasons);
delete from public.season_payouts     where season_id in (select id from _seasons);
delete from public.standings_snapshots where season_id in (select id from _seasons);
delete from public.week_clashes       where season_id in (select id from _seasons);
delete from public.cup_finalists      where season_id in (select id from _seasons);
delete from public.buy_ins            where season_id in (select id from _seasons);
delete from public.season_lead        where season_id in (select id from _seasons);

delete from public.post_comments where post_id in
       (select id from public.posts where league_id in (select id from _doomed));
delete from public.posts          where league_id in (select id from _doomed);
delete from public.commissioner_log where league_id in (select id from _doomed);
delete from public.trophies         where league_id in (select id from _doomed);
delete from public.scheduled_rounds where league_id in (select id from _doomed);
delete from public.events           where league_id in (select id from _doomed);
delete from public.member_invites   where league_id in (select id from _doomed);
delete from public.feedback where member_id in
       (select id from public.league_members where league_id in (select id from _doomed));

-- 3. the league graph (seasons, league_members, squads, squad_members cascade)
delete from public.leagues where id in (select id from _doomed);

-- 4. the cast and any observer seats (profiles + their rounds cascade)
delete from auth.users where email like '%@sim.cupseason.test'
                          or email like 'jerecho+sim%@fischbeck3.com';

-- 5. the harness
drop schema if exists sim cascade;

-- What is left of the footprint?  Every column must read 0.
select
  (select count(*) from public.leagues l
    where l.sandbox is true
      and exists (select 1 from public.league_members lm
                    join public.profiles p on p.id = lm.profile_id
                   where lm.league_id = l.id
                     and (p.email like '%@sim.cupseason.test'
                          or p.email like 'jerecho+sim%@fischbeck3.com')))     as sim_leagues_left,
  (select count(*) from auth.users where email like '%@sim.cupseason.test'
      or email like 'jerecho+sim%@fischbeck3.com')                             as cast_left,
  (select count(*) from public.profiles where email like '%@sim.cupseason.test'
      or email like 'jerecho+sim%@fischbeck3.com')                             as profiles_left,
  (select count(*) from public.rounds r join public.profiles p on p.id = r.profile_id
    where p.email like '%@sim.cupseason.test'
       or p.email like 'jerecho+sim%@fischbeck3.com')                          as sim_rounds_left,
  (select count(*) from information_schema.schemata where schema_name = 'sim') as schema_left;

rollback;  -- <<< change to `commit;` to actually scrap
