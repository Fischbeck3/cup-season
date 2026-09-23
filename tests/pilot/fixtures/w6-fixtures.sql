-- SYNTHETIC fixtures for the W6 report (tests/pilot/scorecard-db.test.mjs and the
-- labelled synthetic report). NEVER run against a linked project: every row is
-- invented, dated in the launch window (Oct–Nov 2026, America/Phoenix), and the
-- test loads it into a disposable copy of the sandbox chain.
--
-- Local weeks (Mon–Sun): W41 Oct 5–11 · W42 Oct 12–18 · W43 Oct 19–25 ·
-- W44 Oct 26–Nov 1 · W45 Nov 2–8. The main report date is Mon Nov 2, 2026, so
-- the cutoff is Nov 3 00:00 Phoenix (07:00 UTC) and W45 runs through Nov 2.
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
-- Fixture rows only: triggers off (the no-future-round guard, moments, achievements,
-- the signup trigger). Every row is written consistently by hand.
set session_replication_role = replica;
begin;

create function pg_temp.pid(n int) returns uuid language sql immutable as
  $$ select ('00000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
create function pg_temp.gid(n int) returns uuid language sql immutable as
  $$ select ('00000000-0000-4000-9000-' || lpad(n::text, 12, '0'))::uuid $$;
create function pg_temp.t(s text) returns timestamptz language sql immutable as
  $$ select (s || ' America/Phoenix')::timestamptz $$;

-- ── golfers ──────────────────────────────────────────────────────────────────
-- 1 founder · 2 App Review account · 3 test-seed bot · 4 deleted (tombstoned) —
-- all four are OUTSIDE the eligible population. 11–16 real golfers for
-- activation; 21–25 real golfers in the assistance cohorts.
create temp table g (n int, e text, c text);
insert into g values
  (1,  'founder@example.com',        '2026-07-01 09:00'),
  (2,  'reviewer@cupseason.app',     '2026-10-06 09:00'),
  (3,  'seed+bot1@cupseason.test',   '2026-10-06 09:00'),
  (4,  'deleted-4@cupseason.invalid','2026-10-06 09:00'),
  (11, 'g1@example.com', '2026-10-06 10:00'),   -- W41 account, rounds W41 and W43
  (12, 'g2@example.com', '2026-09-01 10:00'),   -- older account, first round W42 (a voided one in W41)
  (13, 'g3@example.com', '2026-10-27 10:00'),   -- W44 account, no round by the cutoff (one after it)
  (14, 'g4@example.com', '2026-11-02 23:30'),   -- 23:30 on the report date: INSIDE the cutoff
  (15, 'g5@example.com', '2026-11-03 00:10'),   -- ten minutes past midnight: AFTER the cutoff
  (16, 'g6@example.com', '2026-08-15 10:00'),   -- first round Sun Nov 1 23:50 local = Mon 06:50 UTC
  (21, 'a1@example.com', '2026-08-01 10:00'), (22, 'a2@example.com', '2026-08-01 10:00'),
  (23, 'a3@example.com', '2026-08-01 10:00'), (24, 'a4@example.com', '2026-08-01 10:00'),
  (25, 'a5@example.com', '2026-08-01 10:00');
insert into auth.users (id, email, created_at) select pg_temp.pid(n), e, pg_temp.t(c) from g;
insert into public.profiles (id, display_name, email, created_at, is_founder, deleted_at, came_via_kind, came_via_token)
select pg_temp.pid(n), 'Synthetic ' || n, e, pg_temp.t(c), n = 1,
       case when n = 4 then pg_temp.t('2026-10-20 09:00') end,
       case when n = 13 then 'claim' end, case when n = 13 then '00000000-0000-4000-a000-000000000001' end
  from g;

-- ── leagues: one real, one sandbox ───────────────────────────────────────────
insert into public.leagues (id, name, code, commissioner_id, created_at, sandbox) values
  ('00000000-0000-4000-b000-000000000001', 'Synthetic League', 'SYNTH1', pg_temp.pid(23), pg_temp.t('2026-09-01 09:00'), false),
  ('00000000-0000-4000-b000-000000000002', 'Synthetic Sandbox', 'SYNTHS', pg_temp.pid(3), pg_temp.t('2026-09-01 09:00'), true);
insert into public.league_members (league_id, profile_id, role, joined_at) values
  ('00000000-0000-4000-b000-000000000001', pg_temp.pid(23), 'commissioner', pg_temp.t('2026-09-01 09:00')),
  ('00000000-0000-4000-b000-000000000001', pg_temp.pid(24), 'player',       pg_temp.t('2026-09-02 09:00')),
  ('00000000-0000-4000-b000-000000000001', pg_temp.pid(13), 'player',       pg_temp.t('2026-10-27 10:10')),
  ('00000000-0000-4000-b000-000000000002', pg_temp.pid(3),  'commissioner', pg_temp.t('2026-09-01 09:00'));

-- ── rounds (quick posts unless a live round is named) ───────────────────────
create function pg_temp.rnd(p int, played date, created text, lr uuid default null, void boolean default false) returns void
language sql as $$
  insert into public.rounds (profile_id, course_label, played_on, holes_played, gross, rating, slope, index_at_post, source, voided, created_at, live_round_id)
  values (pg_temp.pid(p), 'Synthetic Links', played, 18, 85, 71.5, 125, 12.0,
          case when lr is null then 'quick' else 'live' end, void, pg_temp.t(created), lr) $$;
select pg_temp.rnd(11, '2026-10-07', '2026-10-07 19:00');          -- G1 first, W41, league-less
select pg_temp.rnd(11, '2026-10-20', '2026-10-20 19:00');          -- G1 second, W43
select pg_temp.rnd(12, '2026-10-08', '2026-10-08 19:00', null, true); -- G2 voided: never counts
select pg_temp.rnd(12, '2026-10-14', '2026-10-14 19:00');          -- G2 first, W42 (account from Sept)
select pg_temp.rnd(13, '2026-11-03', '2026-11-03 08:00');          -- G3, AFTER the cutoff
select pg_temp.rnd(16, '2026-11-01', '2026-11-01 23:50');          -- G6 first: local W44, UTC Monday
select pg_temp.rnd(1,  '2026-10-07', '2026-10-07 19:00');          -- founder: excluded
select pg_temp.rnd(3,  '2026-10-07', '2026-10-07 19:00');          -- bot: excluded
select pg_temp.rnd(4,  '2026-10-07', '2026-10-07 19:00');          -- deleted: excluded

-- ── live games: all final, league-less unless named, 2 hours long ───────────
-- Seated as start_live_round seats them (20260829090000): a league-less game
-- puts the starter and every app golfer on the guest_profile_id rail; a league
-- game seats members by member_id.
create function pg_temp.game(n int, starter int, other int, finished text, league uuid default null, st text default 'final') returns void
language plpgsql as $$
begin
  insert into public.live_rounds (id, league_id, course_label, course_snapshot, game, status, started_at, finished_at, starter_profile_id)
  values (pg_temp.gid(n), league, 'Synthetic Links', '{}'::jsonb, 'skins', st,
          pg_temp.t(finished) - interval '2 hours', case when st = 'final' then pg_temp.t(finished) end, pg_temp.pid(starter));
  if league is null then
    insert into public.live_round_players (live_round_id, guest_name, guest_profile_id, index_source, position)
    values (pg_temp.gid(n), 'Synthetic ' || starter, pg_temp.pid(starter), 'self', 0);
    if other is not null then
      insert into public.live_round_players (live_round_id, guest_name, guest_profile_id, index_source, position)
      values (pg_temp.gid(n), 'Synthetic ' || other, pg_temp.pid(other), 'self', 1);
    end if;
  else
    insert into public.live_round_players (live_round_id, member_id, index_source, position)
    select pg_temp.gid(n), m.id, 'member', (m.profile_id <> pg_temp.pid(starter))::int
      from public.league_members m
     where m.league_id = league and m.profile_id in (pg_temp.pid(starter), pg_temp.pid(coalesce(other, starter)));
  end if;
end $$;
-- friends (A1 21, A2 22): W41 three unassisted · W42 three, one covered by two sessions · W43 two, both covered
select pg_temp.game(1, 21, 22, '2026-10-06 18:00'); select pg_temp.game(2, 21, 22, '2026-10-08 18:00');
select pg_temp.game(3, 21, 22, '2026-10-10 18:00');
select pg_temp.game(6, 21, 22, '2026-10-13 18:00'); select pg_temp.game(7, 21, 22, '2026-10-15 18:00');
select pg_temp.game(8, 21, 22, '2026-10-17 18:00');
select pg_temp.game(4, 21, 22, '2026-10-20 18:00'); select pg_temp.game(5, 21, 22, '2026-10-22 18:00');
-- independent (A3 23, A4 24): W43 mixed · W44 two games whose session evidence is incomplete
select pg_temp.game(9, 23, 24, '2026-10-21 17:00'); select pg_temp.game(10, 23, 24, '2026-10-23 18:00');
select pg_temp.game(11, 23, 24, '2026-10-24 18:00');
select pg_temp.game(12, 23, 24, '2026-10-27 18:00', '00000000-0000-4000-b000-000000000001');
select pg_temp.game(13, 23, 24, '2026-10-29 18:00');
-- competition (A5 25): W44 two unassisted (a good prior week) · W45 one, assisted · one after the cutoff
select pg_temp.game(14, 25, null, '2026-10-28 18:00'); select pg_temp.game(15, 25, null, '2026-10-30 18:00');
select pg_temp.game(16, 25, null, '2026-11-02 12:00');
select pg_temp.game(17, 25, null, '2026-11-03 08:00');
-- owner (the founder alone): not gated, and not an eligible golfer's game
select pg_temp.game(18, 1, null, '2026-10-31 18:00');
-- a sandbox league's game with a bot: never counted
select pg_temp.game(19, 3, null, '2026-10-21 18:00', '00000000-0000-4000-b000-000000000002');
-- unfinished: one still live on the report date, one abandoned
select pg_temp.game(20, 25, null, '2026-11-02 10:00', null, 'live');
select pg_temp.game(21, 23, null, '2026-10-25 11:00', null, 'abandoned');
-- two cards posted from game 4: one completion, two cards
select pg_temp.rnd(21, '2026-10-20', '2026-10-20 18:05', pg_temp.gid(4));
select pg_temp.rnd(22, '2026-10-20', '2026-10-20 18:05', pg_temp.gid(4));
-- guest seats: minted on game 1 (unclaimed) and game 2 (claimed)
insert into public.live_round_players (live_round_id, guest_name, claim_token, position) values
  (pg_temp.gid(1), 'Synthetic guest', '00000000-0000-4000-a000-000000000002', 2);
insert into public.live_round_players (live_round_id, guest_name, claim_token, claimed_profile, position) values
  (pg_temp.gid(2), 'Synthetic guest', '00000000-0000-4000-a000-000000000003', pg_temp.pid(12), 2);

-- ── the pilot record ─────────────────────────────────────────────────────────
insert into public.pilot_cohort_members (profile_id, cohort, group_key, added_at, added_by) values
  (pg_temp.pid(21), 'friends',     'synthetic friends',     pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(22), 'friends',     'synthetic friends',     pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(23), 'independent', 'synthetic independents', pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(24), 'independent', 'synthetic independents', pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(25), 'competition', 'synthetic competitors', pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(1),  'owner',       'owner',                 pg_temp.t('2026-09-15 09:00'), pg_temp.pid(1)),
  (pg_temp.pid(14), 'founding',    'late',                  pg_temp.t('2026-11-03 09:00'), pg_temp.pid(1));  -- after the cutoff
insert into public.pilot_sessions (cohort, group_key, kind, started_at, ended_at, golfers, created_by, notes)
select c, g, k, pg_temp.t(s), case when e is null then null else pg_temp.t(e) end, gs, pg_temp.pid(1), 'synthetic ' || tag from (values
  -- W43 friends, ALL-ASSISTED: s1 by golfers, s2 by the game's own id
  ('friends', 'synthetic friends', 'assisted', '2026-10-20 15:00', '2026-10-20 18:00', array[pg_temp.pid(21), pg_temp.pid(22)], 's1'),
  ('friends', pg_temp.gid(5)::text, 'assisted', '2026-10-22 15:30', '2026-10-22 17:30', '{}'::uuid[], 's2'),
  -- W42 friends, OVERLAPPING: two sessions on the same game
  ('friends', 'synthetic friends', 'assisted', '2026-10-13 15:00', '2026-10-13 17:00', array[pg_temp.pid(21)], 's3'),
  ('friends', pg_temp.gid(6)::text, 'assisted', '2026-10-13 16:00', '2026-10-13 18:30', '{}'::uuid[], 's4'),
  -- W43 independent, MIXED: one of three games covered
  ('independent', 'synthetic independents', 'assisted', '2026-10-21 14:00', '2026-10-21 17:00', array[pg_temp.pid(23)], 's5'),
  -- W44 independent, INCOMPLETE: a linked session with no end; a free-text group with no golfers
  ('independent', '00000000-0000-4000-b000-000000000001', 'assisted', '2026-10-27 15:00', null, '{}'::uuid[], 's6'),
  ('independent', 'the tuesday group', 'assisted', '2026-10-29 15:00', '2026-10-29 17:00', '{}'::uuid[], 's7'),
  -- W45 competition, the CURRENT BAD WEEK after a good one
  ('competition', 'synthetic competitors', 'assisted', '2026-11-02 09:00', '2026-11-02 12:30', array[pg_temp.pid(25)], 's8'),
  ('competition', 'synthetic competitors', 'assisted', '2026-11-03 07:00', '2026-11-03 09:00', array[pg_temp.pid(25)], 's9 after the cutoff'),
  -- owner: not gated
  ('owner', 'owner', 'assisted', '2026-10-31 16:00', '2026-10-31 18:00', array[pg_temp.pid(1)], 's10'),
  -- a support contact, W43 friends
  ('friends', 'synthetic friends', 'support', '2026-10-21 10:00', '2026-10-21 10:20', array[pg_temp.pid(21)], 's11')
) v(c, g, k, s, e, gs, tag);

-- ── telemetry and growth ─────────────────────────────────────────────────────
insert into public.client_events (profile_id, event, props, created_at) values
  (pg_temp.pid(11), 'app_open', '{"platform":"web"}', pg_temp.t('2026-10-06 10:05')),   -- G1 first event: web
  (pg_temp.pid(11), 'app_open', '{"platform":"ios"}', pg_temp.t('2026-10-09 10:05')),   -- later from the phone
  (pg_temp.pid(13), 'app_open', '{"platform":"ios"}', pg_temp.t('2026-10-28 08:00')),   -- G3 first event a day after sign-up
  (pg_temp.pid(14), 'app_open', '{}',                 pg_temp.t('2026-11-03 00:30'));   -- G4's first event: no platform, and after the Nov 2 cutoff
insert into public.growth_events (at, node, kind, token, actor, props) values
  (pg_temp.t('2026-10-20 18:10'), 'artifact_shared', 'share', 'synthetic-token-1', pg_temp.pid(21), '{}'),
  (pg_temp.t('2026-10-21 09:00'), 'link_opened',     'share', 'synthetic-token-1', null, '{}'),
  (pg_temp.t('2026-10-26 12:00'), 'link_opened',     'join',  'SYNTH1', null, '{}'),
  (pg_temp.t('2026-10-27 10:05'), 'profile_created', 'claim', '00000000-0000-4000-a000-000000000001', pg_temp.pid(13), '{}'),
  (pg_temp.t('2026-11-01 23:50'), 'first_round_posted', null, null, pg_temp.pid(16), '{}'),
  (pg_temp.t('2026-11-03 09:00'), 'link_opened',     'share', 'synthetic-token-2', null, '{}');  -- after the cutoff
insert into public.member_invites (league_id, profile_id, invited_by, status, created_at) values
  ('00000000-0000-4000-b000-000000000001', pg_temp.pid(13), pg_temp.pid(23), 'accepted', pg_temp.t('2026-10-26 12:00'));

commit;
