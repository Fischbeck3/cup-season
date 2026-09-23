-- Cup Season · the pilot scorecard and the weekly growth report — READ-ONLY.
-- One result set per section. Run with `node tools/pilot-scorecard.mjs`
-- (linked project, read-only) or against the sandbox (`--sandbox`).
--
-- ONE REPORTING CUTOFF (W6 correction 3). The runner validates one report date
-- and one time zone and substitutes, before any query runs:
--   :AS_OF    the report date, DATE 'YYYY-MM-DD'
--   :TZ       the reporting time zone, e.g. 'America/Phoenix' (no DST)
--   :CUTOFF   the first instant AFTER the report date in that zone. Every
--             temporal filter below is `< :CUTOFF`, so nothing that happened
--             after the report date is counted, whenever the report is run.
--   :WEEKS    the eight local Monday-start weeks ending with the report date's
--             week, each with `through` = the last day it covers (the report
--             date's own week is partial and says so)
--   :ELIGIBLE, :PARTICIPANTS, :REAL_GAMES   the fragments below, defined once
--   :COHORT_ROWS   the named pilot cohorts as of the cutoff (or, without the
--             pilot record, every eligible golfer as one cohort named 'all')
-- Weeks are local: `date_trunc('week', ts at time zone :TZ)`, never UTC.
--
-- CURRENT STATE IS LABELLED. A column ending `_now` is the database's state when
-- the report RAN: the schema keeps no history for it (an invitation's status, a
-- claimed seat, an abandoned round), so a backdated report shows it as it is
-- today, and says so.
--
-- A section line `-- empty: …` is what the report prints when the section has
-- no rows — missing is said, never shown as a blank table or a zero.
--
-- Golf is intermittent. Nothing here treats daily activity as retention, and
-- "has not played again" is reported with the days since the last round rather
-- than as churn. Small samples are printed as counts, never as percentages.

-- fragment: ELIGIBLE
-- The real-golfer population, defined ONCE (W6 correction 4) and applied to
-- every account, round and game count that claims to be about real golfers:
-- not deleted, not the founder, not the App Review account (@cupseason.app),
-- not a test-seed bot (@cupseason.test), not a deleted-account tombstone
-- (@cupseason.invalid), and created before the cutoff.
select p.id as profile_id, p.created_at
  from public.profiles p
 where p.deleted_at is null
   and not coalesce(p.is_founder, false)
   and coalesce(p.email, '') not like '%@cupseason.app'
   and coalesce(p.email, '') not like '%@cupseason.test'
   and coalesce(p.email, '') not like '%@cupseason.invalid'
   and p.created_at < :CUTOFF
-- end fragment

-- fragment: PARTICIPANTS
-- Who played a live round: its starter, every member seat (through the league
-- membership), every signed-in visitor seat and every claimed guest seat.
select lr.id as live_round_id, lr.starter_profile_id as profile_id
  from public.live_rounds lr where lr.starter_profile_id is not null
union
select p.live_round_id, coalesce(m.profile_id, p.guest_profile_id, p.claimed_profile)
  from public.live_round_players p left join public.league_members m on m.id = p.member_id
 where coalesce(m.profile_id, p.guest_profile_id, p.claimed_profile) is not null
-- end fragment

-- fragment: REAL_GAMES
-- A real game, defined ONCE and used by every game count below except the
-- integrity checks (which watch every live round, the founder's included): a
-- live round outside sandbox leagues with at least one ELIGIBLE golfer among
-- its PARTICIPANTS. The founder's solo test round is not a real game; a real
-- golfer's league-less round is.
select lr.*
  from public.live_rounds lr left join public.leagues l on l.id = lr.league_id
 where not coalesce(l.sandbox, false)
   and exists (select 1 from (:PARTICIPANTS) pt join (:ELIGIBLE) el on el.profile_id = pt.profile_id
                where pt.live_round_id = lr.id)
-- end fragment

-- A GUEST SEAT is a seat with no league membership and no account at play
-- (`member_id is null and guest_profile_id is null`) — the seat a claim link
-- exists for. Never `claim_token is not null`: the baseline defaults a token
-- onto EVERY seat, members included (20260728180000's header).

-- ── 1 · eligible: who is in the pilot, by cohort ─────────────────────────────
-- name: eligible
-- empty: no golfer is in a named cohort by the cutoff — the founder names cohorts in pilot_cohort_members
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
-- empty: no golfer is in a named cohort by the cutoff
with c as (
  :COHORT_ROWS
),
f as (
  select c.cohort, c.profile_id,
         exists (select 1 from public.member_invites i where i.profile_id = c.profile_id and i.created_at < :CUTOFF)
           or exists (select 1 from public.growth_events g where g.actor = c.profile_id and g.node = 'link_opened' and g.at < :CUTOFF) as invited_or_link,
         exists (select 1 from public.league_members m where m.profile_id = c.profile_id and m.joined_at < :CUTOFF)
           or exists (select 1 from public.round_rsvp r where r.profile_id = c.profile_id and r.status = 'in' and r.updated_at < :CUTOFF)
           or exists (select 1 from public.live_round_players p join public.live_rounds lr on lr.id = p.live_round_id
                       where (p.guest_profile_id = c.profile_id or p.claimed_profile = c.profile_id) and lr.started_at < :CUTOFF) as joined,
         r.first_round, r.rounds, r.last_round
    from c
    left join lateral (
      select min(x.played_on) as first_round, count(*) as rounds, max(x.played_on) as last_round
        from public.rounds x
       where x.profile_id = c.profile_id and not coalesce(x.voided, false) and x.created_at < :CUTOFF) r on true
)
select cohort,
       count(*)                                  as golfers,
       count(*) filter (where invited_or_link)   as invited_or_opened_link,
       count(*) filter (where joined)            as joined,
       count(*) filter (where rounds >= 1)       as first_round_posted,
       count(*) filter (where rounds >= 2)       as posted_again,
       count(*) filter (where rounds = 1 and last_round < :AS_OF - 21) as one_round_quiet_3w,
       count(*) filter (where joined and coalesce(rounds, 0) = 0) as joined_never_posted
  from f group by cohort order by cohort;

-- ── 3 · organizer funnel ─────────────────────────────────────────────────────
-- name: organizer_funnel
-- empty: no organizer is in a named cohort by the cutoff
with org as (
  select distinct owner as profile_id from (
    select l.commissioner_id as owner from public.leagues l where not coalesce(l.sandbox, false) and l.created_at < :CUTOFF
    union all select sr.profile_id from public.scheduled_rounds sr where sr.created_at < :CUTOFF
    union all select e.created_by from public.events e where e.created_at < :CUTOFF
  ) o where owner is not null
),
c as (
  :COHORT_ROWS
),
f as (
  select c.cohort, org.profile_id,
         (select count(*) from public.seasons s join public.leagues l on l.id = s.league_id
           where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false) and s.starts_on <= :AS_OF) as competitions_opened,
         (select count(*) from public.seasons s join public.leagues l on l.id = s.league_id
           where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false) and s.ends_on <= :AS_OF and s.status = 'complete') as competitions_completed_now,
         (select count(*) from public.events e where e.created_by = org.profile_id and e.created_at < :CUTOFF and e.starts_on <= :AS_OF) as events_started,
         exists (select 1 from public.seasons s join public.leagues l on l.id = s.league_id join public.league_members m on m.league_id = l.id
                  join public.rounds r on r.profile_id = m.profile_id and r.played_on >= s.starts_on and r.created_at < :CUTOFF
                 where l.commissioner_id = org.profile_id and not coalesce(l.sandbox, false)) as first_participant_round
    from org join c on c.profile_id = org.profile_id
)
select cohort,
       count(*) as organizers,
       count(*) filter (where competitions_opened > 0 or events_started > 0) as opened_a_competition,
       count(*) filter (where first_participant_round) as had_first_participant_round,
       count(*) filter (where competitions_completed_now > 0) as completed_a_competition_now,
       count(*) filter (where competitions_opened + events_started >= 2) as started_another
  from f group by cohort order by cohort;

-- ── 4 · live games: started, finished, unfinished, by local week ─────────────
-- Real games only (:REAL_GAMES). `abandoned_now` is the status today: the schema
-- keeps no abandonment time, so a backdated report cannot place it.
-- name: live_games
-- note: Real games only, by the local week they started. `unfinished_at_cutoff` had not finished by the cutoff; `abandoned_now` is today's status.
with wk as (
  :WEEKS
),
g as (
  select date_trunc('week', lr.started_at at time zone :TZ)::date as week,
         lr.status, lr.finished_at, lr.scheduled_round_id, lr.league_id
    from (:REAL_GAMES) lr
   where lr.started_at < :CUTOFF
),
w as (
  select week,
         count(*) as started,
         count(*) filter (where status = 'final' and finished_at < :CUTOFF) as finished_by_cutoff,
         count(*) filter (where not (status = 'final' and finished_at < :CUTOFF) and status <> 'abandoned') as unfinished_at_cutoff,
         count(*) filter (where status = 'abandoned') as abandoned_now,
         count(*) filter (where scheduled_round_id is not null) as from_a_booking,
         count(*) filter (where league_id is null) as league_less
    from g group by week
),
f as (
  select date_trunc('week', ce.created_at at time zone :TZ)::date as week, count(*) as start_failures_reported
    from public.client_events ce where ce.event = 'live_start_failed' and ce.created_at < :CUTOFF group by 1
)
select wk.week, wk.through,
       coalesce(w.started, 0) as started, coalesce(w.finished_by_cutoff, 0) as finished_by_cutoff,
       coalesce(w.unfinished_at_cutoff, 0) as unfinished_at_cutoff, coalesce(w.abandoned_now, 0) as abandoned_now,
       coalesce(w.from_a_booking, 0) as from_a_booking, coalesce(w.league_less, 0) as league_less,
       coalesce(f.start_failures_reported, 0) as start_failures_reported
  from wk left join w on w.week = wk.week left join f on f.week = wk.week
 order by wk.week desc;

-- ── 5 · posting outcome per finished live round (12 weeks to the cutoff) ─────
-- Real games only. A guest seat is account-less at play (see GUEST SEAT above).
-- name: posting
-- note: Real games finished in the twelve weeks to the cutoff. A card counts if it was posted before the cutoff.
select count(*) as finished_rounds,
       count(*) filter (where posted = seats) as every_seat_posted,
       count(*) filter (where posted = 0)     as nothing_posted,
       count(*) filter (where guests > 0)     as had_account_less_guests,
       count(*) filter (where guests > 0 and claimed = guests) as all_guests_claimed_now
  from (
    select lr.id,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id) as seats,
           (select count(*) from public.rounds r where r.live_round_id = lr.id and r.created_at < :CUTOFF) as posted,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id and p.member_id is null and p.guest_profile_id is null) as guests,
           (select count(*) from public.live_round_players p where p.live_round_id = lr.id and p.member_id is null and p.guest_profile_id is null and p.claimed_profile is not null) as claimed
      from (:REAL_GAMES) lr
     where lr.status = 'final' and lr.finished_at < :CUTOFF and lr.finished_at >= :CUTOFF - interval '12 weeks'
  ) x;

-- ── 6 · repeat group activity ────────────────────────────────────────────────
-- Real games only. A group is the game's league, else the exact set of its
-- participants (the starter included).
-- name: repeat_groups
with pt as (
  :PARTICIPANTS
),
g as (
  select coalesce(lr.league_id::text,
                  (select string_agg(distinct pt.profile_id::text, '+' order by pt.profile_id::text)
                     from pt where pt.live_round_id = lr.id)) as group_key,
         lr.id, lr.finished_at
    from (:REAL_GAMES) lr
   where lr.status = 'final' and lr.finished_at < :CUTOFF
)
select count(distinct group_key) as groups_with_a_finished_game,
       count(distinct group_key) filter (where n >= 2) as groups_with_a_second_game,
       count(distinct group_key) filter (where n = 1 and last_at < :CUTOFF - interval '21 days') as one_game_quiet_3w
  from (select group_key, count(*) as n, max(finished_at) as last_at from g group by group_key) s;

-- ── 7 · failures and integrity ───────────────────────────────────────────────
-- EVERY live round, the founder's and sandbox leagues' included: a stuck round
-- is an operational fault whoever started it. Not a population metric.
-- name: integrity
-- note: Every live round, the founder's and sandbox leagues' included — an operational check, not a population count.
select
  (select count(*) from public.live_rounds where status = 'live' and started_at < :CUTOFF - interval '24 hours') as live_over_24h_now,
  (select count(*) from (select scheduled_round_id from public.live_rounds where status = 'live' and scheduled_round_id is not null and started_at < :CUTOFF group by 1 having count(*) > 1) d) as bookings_with_two_live_rounds_now,
  (select count(*) from (select live_round_id, profile_id from public.rounds where live_round_id is not null and created_at < :CUTOFF group by 1,2 having count(*) > 1) d) as double_posted_live_cards,
  (select count(*) from public.client_events where event = 'live_start_failed'  and created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as start_failures_4w,
  (select count(*) from public.client_events where event = 'live_finish_failed' and created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as finish_failures_4w,
  (select count(*) from public.client_events where event = 'client_error'       and created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as client_errors_4w;

-- ── 8 · founder assistance and support, four weeks to the cutoff ─────────────
-- name: assistance @pilot
-- note: Four-week context only. The stop condition is judged week by week in `assistance_weekly`, never on this aggregate.
select
  (select count(*) from public.pilot_sessions where kind = 'assisted' and started_at >= :CUTOFF - interval '4 weeks' and started_at < :CUTOFF) as assisted_sessions_4w,
  (select count(*) from public.pilot_sessions where kind = 'support'  and started_at >= :CUTOFF - interval '4 weeks' and started_at < :CUTOFF) as support_sessions_4w,
  (select count(*) from public.pilot_feedback where created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as feedback_rows_4w,
  (select count(*) from public.pilot_feedback where created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF and category in ('bug','confusing')) as bug_or_confusing_4w;

-- ── 9 · weekly clash: exposure and receipt interaction, kept apart ───────────
-- name: clash
select
  (select count(distinct profile_id) from public.client_events where event = 'clash_seen'     and created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as golfers_shown_a_clash_4w,
  (select count(distinct profile_id) from public.client_events where event = 'receipt_viewed' and created_at >= :CUTOFF - interval '4 weeks' and created_at < :CUTOFF) as golfers_opened_a_receipt_4w,
  (select count(*) from public.seasons s join public.leagues l on l.id = s.league_id
    where not coalesce(l.sandbox, false) and s.starts_on <= :AS_OF and s.ends_on >= :AS_OF) as seasons_running_on_report_date;

-- ═══ W6 · the weekly growth report (launch plan §3; D183, D371) ══════════════
-- First-time App Store downloads, TestFlight installs and web sign-ups are
-- THREE different numbers and are never summed. The store count is not in this
-- database: the runner reads the owner's dated App Analytics readings and the
-- weekly acquisition log and prints them beside these, missing when missing.

-- ── 10 · sharing: the growth funnel, by local week and link kind ─────────────
-- name: sharing
-- empty: no growth event in the eight weeks to the cutoff
with wk as (
  :WEEKS
),
e as (
  select date_trunc('week', g.at at time zone :TZ)::date as week, coalesce(g.kind, 'none') as kind,
         count(*) filter (where g.node = 'artifact_shared')    as shared,
         count(*) filter (where g.node = 'link_opened')        as opened,
         count(*) filter (where g.node = 'claim_started')      as claim_started,
         count(*) filter (where g.node = 'profile_created')    as profiles_created,
         count(*) filter (where g.node = 'first_round_posted') as first_rounds
    from public.growth_events g where g.at < :CUTOFF
   group by 1, 2
)
select wk.week, wk.through, e.kind, e.shared, e.opened, e.claim_started, e.profiles_created, e.first_rounds
  from wk join e on e.week = wk.week
 order by wk.week desc, e.kind;

-- ── 11 · sharing outcomes: guest seats and claims, invitations sent and answered
-- Guest seats in real games, by the week the game started; claimed and
-- answered are the status today (`_now`) — the schema keeps no claim history.
-- name: sharing_outcomes
-- note: Guest seats (no membership, no account at play) in real games; claimed and answered are today's status.
with wk as (
  :WEEKS
),
seats as (
  select date_trunc('week', lr.started_at at time zone :TZ)::date as week,
         count(*)                                              as guest_seats,
         count(*) filter (where p.claimed_profile is not null) as guest_seats_claimed_now
    from public.live_round_players p join (:REAL_GAMES) lr on lr.id = p.live_round_id
   where lr.started_at < :CUTOFF and p.member_id is null and p.guest_profile_id is null
   group by 1),
inv as (
  select date_trunc('week', i.created_at at time zone :TZ)::date as week,
         count(*)                                      as invitations_sent,
         count(*) filter (where i.status = 'accepted') as invitations_accepted_now,
         count(*) filter (where i.status = 'declined') as invitations_declined_now
    from public.member_invites i
   where i.created_at < :CUTOFF
   group by 1)
select wk.week, wk.through,
       coalesce(seats.guest_seats, 0)               as guest_seats,
       coalesce(seats.guest_seats_claimed_now, 0)   as guest_seats_claimed_now,
       coalesce(inv.invitations_sent, 0)            as invitations_sent,
       coalesce(inv.invitations_accepted_now, 0)    as invitations_accepted_now,
       coalesce(inv.invitations_declined_now, 0)    as invitations_declined_now
  from wk left join seats on seats.week = wk.week left join inv on inv.week = wk.week
 order by wk.week desc;

-- ── 12 · activation EVENTS, by local week — not a funnel ─────────────────────
-- Each column counts what happened in that week among ELIGIBLE golfers: accounts
-- created, first and second rounds POSTED (created_at — the week the golfer
-- acted, whatever day they played; voided rounds never count; league-less
-- rounds count like any other), and finished live games with at least one
-- eligible golfer outside sandbox leagues. A first round this week can belong to
-- an account created weeks earlier; the signup-cohort funnel is section 13.
-- name: activation_weekly
-- note: EVENTS in each week among eligible golfers — not a funnel. A first round this week can belong to an account from months ago; the signup funnel is `activation_cohort`.
with wk as (
  :WEEKS
),
el as (
  :ELIGIBLE
),
posted as (
  select r.profile_id, r.created_at,
         row_number() over (partition by r.profile_id order by r.created_at, r.id) as nth
    from public.rounds r join el on el.profile_id = r.profile_id
   where not coalesce(r.voided, false) and r.created_at < :CUTOFF
),
games as (
  select lr.id, lr.finished_at
    from (:REAL_GAMES) lr
   where lr.status = 'final' and lr.finished_at < :CUTOFF
)
select wk.week, wk.through,
       (select count(*) from el     where date_trunc('week', el.created_at at time zone :TZ)::date = wk.week)                  as accounts_created,
       (select count(*) from posted where nth = 1 and date_trunc('week', posted.created_at at time zone :TZ)::date = wk.week) as first_rounds,
       (select count(*) from posted where nth = 2 and date_trunc('week', posted.created_at at time zone :TZ)::date = wk.week) as second_rounds,
       (select count(*) from games  where date_trunc('week', games.finished_at at time zone :TZ)::date = wk.week)             as live_games_finished
  from wk order by wk.week desc;

-- ── 13 · activation by SIGNUP WEEK: the conversion funnel ────────────────────
-- Of the eligible accounts created in each week, how many had posted a round,
-- posted a second, and played a finished live game — all by the cutoff.
-- name: activation_cohort
-- note: The FUNNEL: of the eligible accounts created in each week, how many had posted, posted again and played a finished real game by the cutoff.
with wk as (
  :WEEKS
),
el as (
  :ELIGIBLE
),
n as (
  select r.profile_id, count(*) as rounds
    from public.rounds r join el on el.profile_id = r.profile_id
   where not coalesce(r.voided, false) and r.created_at < :CUTOFF
   group by 1
),
played as (
  select distinct pt.profile_id
    from (
      :PARTICIPANTS
    ) pt join (:REAL_GAMES) lr on lr.id = pt.live_round_id
   where lr.status = 'final' and lr.finished_at < :CUTOFF
)
select wk.week as signup_week, wk.through,
       count(el.profile_id)                                              as accounts,
       count(el.profile_id) filter (where coalesce(n.rounds, 0) >= 1)    as posted_a_round_by_cutoff,
       count(el.profile_id) filter (where coalesce(n.rounds, 0) >= 2)    as posted_a_second_by_cutoff,
       count(el.profile_id) filter (where played.profile_id is not null) as played_a_finished_game_by_cutoff
  from wk
  left join el on date_trunc('week', el.created_at at time zone :TZ)::date = wk.week
  left join n on n.profile_id = el.profile_id
  left join played on played.profile_id = el.profile_id
 group by wk.week, wk.through
 order by wk.week desc;

-- ── 14 · eligible accounts by week, with the FIRST-EVENT PLATFORM — a PROXY ──
-- The platform is the one on the account's first client event before the
-- cutoff. It is NOT the sign-up door: that event can come days later and from
-- the other client (sign up on the web, first event from the phone). An account
-- with no event is `no_event_yet`, and a first event that carried no platform is
-- `first_event_unlabelled` — neither is guessed. An account is not an install,
-- and none of these is a first-time App Store download. `attributed_to_a_link`
-- is `profiles.came_via_kind`, written by log_growth_event on profile_created
-- when the golfer arrived with a pending claim or join; a blank there means no
-- attribution was observed (a direct arrival, a seeded account, or a signup
-- before 2026-08-29 when the writer shipped), not a broken writer.
-- name: signups_first_event_platform
-- note: A PROXY. The platform of each account's first client event, which can come days after sign-up and from the other client. An account is not an install and never a first-time App Store download.
with wk as (
  :WEEKS
),
el as (
  :ELIGIBLE
),
fe as (
  select el.profile_id, el.created_at, p.came_via_kind,
         (select coalesce(ce.props->>'platform', 'unlabelled') from public.client_events ce
           where ce.profile_id = el.profile_id and ce.created_at < :CUTOFF
           order by ce.created_at limit 1) as platform
    from el join public.profiles p on p.id = el.profile_id
)
select wk.week, wk.through,
       count(fe.profile_id)                                                            as accounts,
       count(fe.profile_id) filter (where fe.platform = 'web')                          as first_event_web,
       count(fe.profile_id) filter (where fe.platform = 'ios')                          as first_event_ios,
       count(fe.profile_id) filter (where fe.platform = 'unlabelled')                   as first_event_unlabelled,
       count(fe.profile_id) filter (where fe.platform not in ('web','ios','unlabelled')) as first_event_other,
       count(fe.profile_id) filter (where fe.platform is null)                          as no_event_yet,
       count(fe.profile_id) filter (where fe.came_via_kind is not null)                 as attributed_to_a_link,
       string_agg(distinct fe.came_via_kind, ',' order by fe.came_via_kind)            as link_kinds
  from wk left join fe on date_trunc('week', fe.created_at at time zone :TZ)::date = wk.week
 group by wk.week, wk.through
 order by wk.week desc;

-- ── 15 · the ASSISTANCE GATE, by local week and cohort (W6 correction 1) ─────
-- The stop condition (docs/pilot/gates-and-stop-conditions.md): "a week where
-- assisted sessions exceed unassisted completions in a cohort that is meant to
-- be unassisted". A COMPLETION is one finished live game, however many cards it
-- posted (cards are shown beside it). A game counts for every named cohort one
-- of its golfers is in. It is ASSISTED for a cohort when an assisted session of
-- that cohort is linked to it — by group key (the game's league, booking or
-- round id) or by a golfer in common — and the two time windows overlap with
-- both ends known. It is UNKNOWN when the evidence cannot settle it: a linked
-- session with no end time, or a session that names no golfers and no
-- resolvable group and overlaps the game in time. Otherwise it is UNASSISTED.
-- Nothing unknown is ever counted as unassisted. The owner cohort is not gated.
-- name: assistance_weekly @pilot
-- note: The stop condition, per local week and cohort: STOP when assisted sessions exceed unassisted completions; UNKNOWN when only incomplete session evidence stands between the week and a STOP — complete the session log and re-run. A completion is one finished real game, however many cards it posted.
-- empty: no cohort is named and no assisted session is logged by the cutoff, so no week can be judged
with wk as (
  :WEEKS
),
c as (
  :COHORT_ROWS
),
pt as (
  :PARTICIPANTS
),
games as (
  select lr.id, lr.league_id, lr.scheduled_round_id, lr.started_at, lr.finished_at,
         date_trunc('week', lr.finished_at at time zone :TZ)::date as week,
         array_agg(distinct pt.profile_id) as golfers
    from (:REAL_GAMES) lr join pt on pt.live_round_id = lr.id
   where lr.status = 'final' and lr.finished_at < :CUTOFF
     and date_trunc('week', lr.finished_at at time zone :TZ)::date >= (select min(week) from wk)
   group by lr.id, lr.league_id, lr.scheduled_round_id, lr.started_at, lr.finished_at
),
gc as (
  select distinct g.id, g.league_id, g.scheduled_round_id, g.started_at, g.finished_at, g.week, g.golfers, c.cohort
    from games g join c on c.profile_id = any(g.golfers)
),
s as (
  select ps.id, ps.cohort, ps.group_key, ps.started_at, ps.ended_at, ps.golfers,
         (ps.golfers <> '{}'
          or exists (select 1 from public.leagues l          where l.id::text  = ps.group_key)
          or exists (select 1 from public.scheduled_rounds x where x.id::text  = ps.group_key)
          or exists (select 1 from public.live_rounds lr     where lr.id::text = ps.group_key)) as resolvable
    from public.pilot_sessions ps
   where ps.kind = 'assisted' and ps.started_at < :CUTOFF
),
judged as (
  select gc.id, gc.cohort, gc.week,
         case
           when exists (select 1 from s
                         where s.cohort = gc.cohort
                           and (s.group_key in (gc.league_id::text, gc.scheduled_round_id::text, gc.id::text) or s.golfers && gc.golfers)
                           and s.ended_at is not null
                           and s.started_at <= gc.finished_at and s.ended_at >= gc.started_at)
             then 'assisted'
           when exists (select 1 from s
                         where s.cohort = gc.cohort
                           and s.started_at <= gc.finished_at
                           and (((s.group_key in (gc.league_id::text, gc.scheduled_round_id::text, gc.id::text) or s.golfers && gc.golfers)
                                 and s.ended_at is null)
                                or (not s.resolvable and coalesce(s.ended_at, 'infinity'::timestamptz) >= gc.started_at)))
             then 'unknown'
           else 'unassisted'
         end as assistance,
         (select count(*) from public.rounds r where r.live_round_id = gc.id and r.created_at < :CUTOFF) as cards
    from gc
),
sess as (
  select s.cohort, date_trunc('week', s.started_at at time zone :TZ)::date as week, count(*) as assisted_sessions
    from s group by 1, 2
),
sup as (
  select ps.cohort, date_trunc('week', ps.started_at at time zone :TZ)::date as week, count(*) as support_contacts
    from public.pilot_sessions ps where ps.kind = 'support' and ps.started_at < :CUTOFF group by 1, 2
),
cohorts as (
  select cohort from c union select cohort from s
),
grid as (
  select wk.week, wk.through, cohorts.cohort from wk cross join cohorts
),
agg as (
  select grid.week, grid.through, grid.cohort,
         coalesce(max(sess.assisted_sessions), 0) as assisted_sessions,
         count(j.id)                                                   as completions,
         count(j.id) filter (where j.assistance = 'assisted')          as assisted_completions,
         count(j.id) filter (where j.assistance = 'unassisted')        as unassisted_completions,
         count(j.id) filter (where j.assistance = 'unknown')           as unknown_completions,
         coalesce(sum(j.cards), 0)                                     as cards_posted,
         coalesce(max(sup.support_contacts), 0)                        as support_contacts
    from grid
    left join judged j on j.cohort = grid.cohort and j.week = grid.week
    left join sess on sess.cohort = grid.cohort and sess.week = grid.week
    left join sup  on sup.cohort  = grid.cohort and sup.week  = grid.week
   group by grid.week, grid.through, grid.cohort
)
select week, through, cohort, assisted_sessions, completions, assisted_completions, unassisted_completions,
       unknown_completions, cards_posted, support_contacts,
       case
         when cohort not in ('friends','independent','competition','founding') then 'not gated'
         when assisted_sessions = 0 and completions = 0 then 'no activity'
         when assisted_sessions = 0 then 'ok'
         when assisted_sessions > unassisted_completions + unknown_completions
           then 'STOP: assisted sessions exceed unassisted completions'
         when assisted_sessions > unassisted_completions
           then 'UNKNOWN: ' || unknown_completions || ' completion(s) lack session evidence'
         else 'ok'
       end as stop_condition
  from agg
 order by week desc, cohort;
