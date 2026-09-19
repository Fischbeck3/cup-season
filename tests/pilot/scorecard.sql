-- Cup Season · the pilot scorecard — READ-ONLY queries, one result set per
-- section. Run with `node tools/pilot-scorecard.mjs` (linked project, read-only)
-- or against the sandbox. Every query degrades honestly: if the pilot tables
-- from 20261106090000 are absent, `cohort` reads 'all' and assisted is null.
--
-- Golf is intermittent. Nothing here treats daily activity as retention, and
-- "has not played again" is reported with the days since the last round rather
-- than as churn. Small samples are printed as counts, never as percentages
-- with a decimal point.

-- :COHORT_ROWS is substituted by the runner: the pilot cohort table when it exists,
-- otherwise every profile as one cohort named 'all'. :ASSISTED_SESSIONS and
-- :SUPPORT_SESSIONS become 0 when pilot_sessions is absent.

-- ── 1 · eligible: who is in the pilot, by cohort ─────────────────────────────
-- name: eligible
with c as (
  :COHORT_ROWS
)
select cohort,
       count(distinct profile_id) as golfers,
       count(distinct group_key)  as groups
  from c
 group by cohort order by cohort;

-- ── 2 · activation: where the golfer funnel stalls ───────────────────────────
-- name: golfer_funnel
with c as (
  :COHORT_ROWS
),
f as (
  select c.cohort, c.profile_id,
         exists (select 1 from public.member_invites i where i.profile_id = c.profile_id)
           or exists (select 1 from public.growth_events g where g.actor = c.profile_id and g.node = 'link_opened') as invited_or_link,
         exists (select 1 from public.league_members m where m.profile_id = c.profile_id)
           or exists (select 1 from public.round_rsvp r where r.profile_id = c.profile_id and r.status = 'in')
           or exists (select 1 from public.live_round_players p where p.guest_profile_id = c.profile_id or p.claimed_profile = c.profile_id) as joined,
         (select min(played_on) from public.rounds r where r.profile_id = c.profile_id and not coalesce(r.voided,false)) as first_round,
         (select count(*) from public.rounds r where r.profile_id = c.profile_id and not coalesce(r.voided,false)) as rounds,
         (select max(played_on) from public.rounds r where r.profile_id = c.profile_id and not coalesce(r.voided,false)) as last_round
    from c
)
select cohort,
       count(*)                                  as golfers,
       count(*) filter (where invited_or_link)   as invited_or_opened_link,
       count(*) filter (where joined)            as joined,
       count(*) filter (where first_round is not null) as first_round_posted,
       count(*) filter (where rounds >= 2)       as posted_again,
       count(*) filter (where rounds = 1 and last_round < current_date - 21) as one_round_quiet_3w,
       count(*) filter (where joined and first_round is null) as joined_never_posted
  from f group by cohort order by cohort;

-- ── 3 · organizer funnel ─────────────────────────────────────────────────────
-- name: organizer_funnel
with org as (
  select distinct owner as profile_id from (
    select l.commissioner_id as owner from public.leagues l where not coalesce(l.sandbox, false)
    union all select sr.profile_id from public.scheduled_rounds sr
    union all select e.created_by from public.events e
  ) o where owner is not null
),
c as (
  :COHORT_ROWS
),
f as (
  select c.cohort, org.profile_id,
         (select count(*) from public.seasons s join public.leagues l on l.id = s.league_id where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false) and s.status in ('active','cup_final','complete')) as competitions_opened,
         (select count(*) from public.seasons s join public.leagues l on l.id = s.league_id where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false) and s.status = 'complete') as competitions_completed,
         (select count(*) from public.events e where e.created_by = org.profile_id and e.status in ('live','complete')) as events_run,
         exists (select 1 from public.seasons s join public.leagues l on l.id = s.league_id join public.league_members m on m.league_id = l.id
                  join public.rounds r on r.profile_id = m.profile_id and r.played_on >= s.starts_on
                 where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false)) as first_participant_round
    from org join c on c.profile_id = org.profile_id
)
select cohort,
       count(*) as organizers,
       count(*) filter (where competitions_opened > 0 or events_run > 0) as opened_a_competition,
       count(*) filter (where first_participant_round) as had_first_participant_round,
       count(*) filter (where competitions_completed > 0) as completed_a_competition,
       count(*) filter (where competitions_opened + events_run >= 2) as started_another
  from f group by cohort order by cohort;

-- ── 4 · live games: attempted, started, finished, abandoned, still live ──────
-- name: live_games
with w as (
  select date_trunc('week', lr.started_at)::date as week,
         count(*)                                        as started,
         count(*) filter (where lr.status = 'final')     as finished,
         count(*) filter (where lr.status = 'abandoned') as abandoned,
         count(*) filter (where lr.status = 'live')      as still_live,
         count(*) filter (where lr.scheduled_round_id is not null) as from_a_booking,
         count(*) filter (where lr.league_id is null)    as league_less
    from public.live_rounds lr
    left join public.leagues l on l.id = lr.league_id
   where lr.started_at >= now() - interval '12 weeks' and not coalesce(l.sandbox, false)
   group by 1),
f as (
  select date_trunc('week', ce.created_at)::date as week, count(*) as start_failures_reported
    from public.client_events ce where ce.event = 'live_start_failed' group by 1)
select w.*, coalesce(f.start_failures_reported, 0) as start_failures_reported
  from w left join f on f.week = w.week order by w.week desc;

-- ── 5 · posting outcome per finished live round ──────────────────────────────
-- name: posting
select count(*) as finished_rounds,
       count(*) filter (where posted = seats) as every_seat_posted,
       count(*) filter (where posted = 0)     as nothing_posted,
       count(*) filter (where guests > 0)     as had_account_less_guests,
       count(*) filter (where guests > 0 and claimed = guests) as all_guests_claimed
  from (
    select lr.id,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id) as seats,
           (select count(*) from public.rounds r where r.live_round_id = lr.id) as posted,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id and p.claim_token is not null) as guests,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id and p.claimed_profile is not null) as claimed
      from public.live_rounds lr where lr.status = 'final' and lr.started_at >= now() - interval '12 weeks'
  ) x;

-- ── 6 · repeat group activity ────────────────────────────────────────────────
-- name: repeat_groups
with g as (
  select coalesce(lr.league_id::text,
                  (select string_agg(coalesce(p.guest_profile_id, p.claimed_profile)::text, '+' order by 1)
                     from public.live_round_players p where p.live_round_id = lr.id)) as group_key,
         lr.id, lr.started_at
    from public.live_rounds lr where lr.status = 'final'
)
select count(distinct group_key) as groups_with_a_finished_game,
       count(distinct group_key) filter (where n >= 2) as groups_with_a_second_game,
       count(distinct group_key) filter (where n = 1 and last_at < now() - interval '21 days') as one_game_quiet_3w
  from (select group_key, count(*) as n, max(started_at) as last_at from g group by group_key) s;

-- ── 7 · failures and integrity ───────────────────────────────────────────────
-- name: integrity
select
  (select count(*) from public.live_rounds where status = 'live' and started_at < now() - interval '24 hours') as live_over_24h_not_abandoned,
  (select count(*) from (select scheduled_round_id from public.live_rounds where status = 'live' and scheduled_round_id is not null group by 1 having count(*) > 1) d) as bookings_with_two_live_rounds,
  (select count(*) from (select live_round_id, profile_id from public.rounds where live_round_id is not null group by 1,2 having count(*) > 1) d) as double_posted_live_cards,
  (select count(*) from public.client_events where event = 'live_start_failed' and created_at >= now() - interval '4 weeks') as start_failures_4w,
  (select count(*) from public.client_events where event = 'live_finish_failed' and created_at >= now() - interval '4 weeks') as finish_failures_4w,
  (select count(*) from public.client_events where event = 'client_error' and created_at >= now() - interval '4 weeks') as client_errors_4w;

-- ── 8 · founder assistance and support ───────────────────────────────────────
-- name: assistance
select
  :ASSISTED_SESSIONS as assisted_sessions,
  :SUPPORT_SESSIONS as support_sessions,
  (select count(*) from public.pilot_feedback where created_at >= now() - interval '4 weeks') as feedback_rows_4w,
  (select count(*) from public.pilot_feedback where created_at >= now() - interval '4 weeks' and category in ('bug','confusing')) as bug_or_confusing_4w;

-- ── 9 · weekly clash: exposure and receipt interaction, kept apart ───────────
-- name: clash
select
  (select count(distinct profile_id) from public.client_events where event = 'clash_seen' and created_at >= now() - interval '4 weeks') as golfers_shown_a_clash_4w,
  (select count(distinct profile_id) from public.client_events where event = 'receipt_viewed' and created_at >= now() - interval '4 weeks') as golfers_opened_a_receipt_4w,
  (select count(*) from public.seasons where status in ('active','cup_final')) as seasons_running;
