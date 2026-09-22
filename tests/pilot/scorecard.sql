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

-- ═══ W6 · the weekly growth report (launch plan §3; D183, D371) ══════════════
-- Five more sections, read the same way. Every count below is by ISO week
-- (Monday-start, `date_trunc('week')`), the last eight weeks, newest first.
-- Web sign-ups, TestFlight installs and first-time App Store downloads are
-- THREE different numbers and are never summed: the store count lives in
-- App Store Connect's App Analytics, not here — the runner reads it from the
-- owner's acquisition log (docs/pilot/acquisition-log.csv) and prints it
-- beside these, missing when it is missing. Sections marked `@pilot` need
-- the pilot record (20261106090000) and are skipped with a note without it.

-- ── 10 · sharing: the growth funnel, by week and link kind ───────────────────
-- name: sharing
select week, kind,
       sum(shared)        as shared,
       sum(opened)        as opened,
       sum(claim_started) as claim_started,
       sum(profiles)      as profiles_created,
       sum(first_rounds)  as first_rounds
  from public.v_growth_funnel
 where week >= (date_trunc('week', now()) - interval '7 weeks')::date
 group by week, kind
 order by week desc, kind;

-- ── 11 · sharing outcomes: seats minted and claimed, invitations sent and answered
-- name: sharing_outcomes
with wk as (
  select (date_trunc('week', now()) - (n || ' weeks')::interval)::date as week from generate_series(0, 7) n
),
seats as (
  select date_trunc('week', lr.started_at)::date as week,
         count(*) filter (where p.claim_token is not null)     as guest_seats_minted,
         count(*) filter (where p.claimed_profile is not null) as guest_seats_claimed
    from public.live_round_players p join public.live_rounds lr on lr.id = p.live_round_id
   where lr.started_at >= now() - interval '8 weeks'
   group by 1),
inv as (
  select date_trunc('week', i.created_at)::date as week,
         count(*)                                         as invitations_sent,
         count(*) filter (where i.status = 'accepted')    as invitations_accepted,
         count(*) filter (where i.status = 'declined')    as invitations_declined
    from public.member_invites i
   where i.created_at >= now() - interval '8 weeks'
   group by 1)
select wk.week,
       coalesce(seats.guest_seats_minted, 0)  as guest_seats_minted,
       coalesce(seats.guest_seats_claimed, 0) as guest_seats_claimed,
       coalesce(inv.invitations_sent, 0)      as invitations_sent,
       coalesce(inv.invitations_accepted, 0)  as invitations_accepted,
       coalesce(inv.invitations_declined, 0)  as invitations_declined
  from wk left join seats on seats.week = wk.week left join inv on inv.week = wk.week
 order by wk.week desc;

-- ── 12 · activation, by week: accounts → first round → second round → games ──
-- name: activation_weekly
with wk as (
  select (date_trunc('week', now()) - (n || ' weeks')::interval)::date as week from generate_series(0, 7) n
),
acct as (
  select date_trunc('week', p.created_at)::date as week, count(*) as accounts_created
    from public.profiles p
   where p.deleted_at is null and not coalesce(p.is_founder, false)
     and p.email not like '%@cupseason.app' and p.email not like '%@cupseason.invalid'
   group by 1),
-- first and second rounds are keyed on when they were POSTED (created_at), the
-- same clock as growth_events' first_round_posted — a backdated card counts in
-- the week the golfer acted, not the week they played
firsts as (
  select date_trunc('week', f.first_at)::date as week, count(*) as first_rounds
    from (select r.profile_id, min(r.created_at) as first_at
            from public.rounds r where not coalesce(r.voided, false) group by r.profile_id) f
   group by 1),
seconds as (
  select date_trunc('week', s.second_at)::date as week, count(*) as second_rounds
    from (select r.profile_id, (array_agg(r.created_at order by r.created_at))[2] as second_at
            from public.rounds r where not coalesce(r.voided, false) group by r.profile_id having count(*) >= 2) s
   group by 1),
games as (
  select date_trunc('week', lr.finished_at)::date as week, count(*) as live_games_finished
    from public.live_rounds lr left join public.leagues l on l.id = lr.league_id
   where lr.status = 'final' and not coalesce(l.sandbox, false)
   group by 1)
select wk.week,
       coalesce(acct.accounts_created, 0)     as accounts_created,
       coalesce(firsts.first_rounds, 0)       as first_rounds,
       coalesce(seconds.second_rounds, 0)     as second_rounds,
       coalesce(games.live_games_finished, 0) as live_games_finished
  from wk left join acct on acct.week = wk.week left join firsts on firsts.week = wk.week
          left join seconds on seconds.week = wk.week left join games on games.week = wk.week
 order by wk.week desc;

-- ── 13 · sign-ups by the door they came through — NOT App Store downloads ────
-- The platform is the client that sent the account's first event (`client_events`
-- props.platform); an account with no event is `unknown`, never guessed. A
-- phone sign-up here is an account, not an install; the store's own first-time
-- download count is a different number and is read from App Store Connect.
-- name: signups_by_door
with wk as (
  select (date_trunc('week', now()) - (n || ' weeks')::interval)::date as week from generate_series(0, 7) n
),
first_seen as (
  select p.id, p.created_at, p.came_via_kind,
         coalesce((select coalesce(ce.props->>'platform', 'unknown') from public.client_events ce
                    where ce.profile_id = p.id order by ce.created_at limit 1), 'unknown') as platform
    from public.profiles p
   where p.deleted_at is null and not coalesce(p.is_founder, false)
     and p.email not like '%@cupseason.app' and p.email not like '%@cupseason.invalid'),
d as (
  select date_trunc('week', created_at)::date as week,
         count(*)                                                       as accounts,
         count(*) filter (where platform = 'web')                       as web_signups,
         count(*) filter (where platform = 'ios')                       as ios_app_signups,
         count(*) filter (where platform not in ('web','ios'))          as unknown_door,
         count(*) filter (where came_via_kind is not null)              as arrived_by_a_link,
         string_agg(distinct came_via_kind, ',' order by came_via_kind) as link_kinds
    from first_seen
   group by 1)
select wk.week,
       coalesce(d.accounts, 0)          as accounts,
       coalesce(d.web_signups, 0)       as web_signups,
       coalesce(d.ios_app_signups, 0)   as ios_app_signups,
       coalesce(d.unknown_door, 0)      as unknown_door,
       coalesce(d.arrived_by_a_link, 0) as arrived_by_a_link,
       d.link_kinds
  from wk left join d on d.week = wk.week
 order by wk.week desc;

-- ── 14 · assistance by cohort: the stop condition's own numbers ──────────────
-- A week where assisted sessions exceed unassisted completions in a cohort that
-- is meant to be unassisted pauses outreach (gates file). Completions are the
-- cohort's finished live games and posted rounds; assistance is what the
-- founder logged and nothing else.
-- name: assistance_by_cohort @pilot
with c as (
  :COHORT_ROWS
),
by_cohort as (
  select c.cohort,
         count(distinct c.profile_id) as golfers,
         (select count(*) from public.pilot_sessions s where s.cohort = c.cohort and s.kind = 'assisted' and s.started_at >= now() - interval '4 weeks') as assisted_sessions_4w,
         (select count(*) from public.pilot_sessions s where s.cohort = c.cohort and s.kind = 'support'  and s.started_at >= now() - interval '4 weeks') as support_contacts_4w,
         (select count(distinct r.id) from public.rounds r where r.profile_id = any(array_agg(c.profile_id)) and r.created_at >= now() - interval '4 weeks' and not coalesce(r.voided, false)) as rounds_posted_4w,
         (select count(distinct lr.id) from public.live_rounds lr join public.live_round_players p on p.live_round_id = lr.id
           where lr.status = 'final' and lr.finished_at >= now() - interval '4 weeks'
             and coalesce(p.guest_profile_id, p.claimed_profile) = any(array_agg(c.profile_id))) as live_games_finished_4w
    from c group by c.cohort)
select cohort, golfers, assisted_sessions_4w, support_contacts_4w, rounds_posted_4w, live_games_finished_4w,
       case when assisted_sessions_4w > live_games_finished_4w and cohort in ('friends','independent','competition','founding')
            then 'STOP: assisted exceeds unassisted completions' else 'ok' end as stop_condition
  from by_cohort order by cohort;
