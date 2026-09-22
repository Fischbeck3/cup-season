# SYNTHETIC — fixture data, not a measurement · Pilot scorecard and weekly growth report · 2026-11-02 · SANDBOX (cs_w6_examples, local, disposable)

> **SYNTHETIC.** Every number below comes from fixture rows and fixture files written to exercise the report. None of it was observed. Do not read it as progress, and do not copy it into a real report.

_Reporting cutoff: everything before the end of **2026-11-02** in **America/Phoenix**; weeks are America/Phoenix Monday weeks, and the report date's own week is partial (its `through` column says to which day). Run on 2026-09-22._

_Cohorts come from `pilot_cohort_members` (added before the cutoff); assisted activity from `pilot_sessions`._

## eligible

| cohort | golfers | groups |
|---|---|---|
| competition | 1 | 1 |
| friends | 2 | 1 |
| independent | 2 | 1 |
| owner | 1 | 1 |

## golfer_funnel

| cohort | golfers | invited_or_opened_link | joined | first_round_posted | posted_again | one_round_quiet_3w | joined_never_posted |
|---|---|---|---|---|---|---|---|
| competition | 1 | 0 | 1 | 0 | 0 | 0 | 1 |
| friends | 2 | 0 | 2 | 2 | 0 | 0 | 0 |
| independent | 2 | 0 | 2 | 0 | 0 | 0 | 2 |
| owner | 1 | 0 | 1 | 1 | 0 | 1 | 0 |

## organizer_funnel

_Columns ending `_now` are the state when this report ran (2026-09-22), not at the cutoff — the schema keeps no history for them._

| cohort | organizers | opened_a_competition | had_first_participant_round | completed_a_competition_now | started_another |
|---|---|---|---|---|---|
| independent | 1 | 0 | 0 | 0 | 0 |

## live_games

_Real games only, by the local week they started. `unfinished_at_cutoff` had not finished by the cutoff; `abandoned_now` is today's status._

_Columns ending `_now` are the state when this report ran (2026-09-22), not at the cutoff — the schema keeps no history for them._

| week | through | started | finished_by_cutoff | unfinished_at_cutoff | abandoned_now | from_a_booking | league_less | start_failures_reported |
|---|---|---|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | 2 | 1 | 1 | 0 | 0 | 2 | 0 |
| 2026-10-26 | 2026-11-01 | 4 | 4 | 0 | 0 | 0 | 3 | 0 |
| 2026-10-19 | 2026-10-25 | 6 | 5 | 0 | 1 | 0 | 6 | 0 |
| 2026-10-12 | 2026-10-18 | 3 | 3 | 0 | 0 | 0 | 3 | 0 |
| 2026-10-05 | 2026-10-11 | 3 | 3 | 0 | 0 | 0 | 3 | 0 |
| 2026-09-28 | 2026-10-04 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-21 | 2026-09-27 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-14 | 2026-09-20 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

## posting

_Real games finished in the twelve weeks to the cutoff. A card counts if it was posted before the cutoff._

_Columns ending `_now` are the state when this report ran (2026-09-22), not at the cutoff — the schema keeps no history for them._

| finished_rounds | every_seat_posted | nothing_posted | had_account_less_guests | all_guests_claimed_now |
|---|---|---|---|---|
| 16 | 1 | 15 | 2 | 1 |

## repeat_groups

| groups_with_a_finished_game | groups_with_a_second_game | one_game_quiet_3w |
|---|---|---|
| 5 | 3 | 1 |

## integrity

_Every live round, the founder's and sandbox leagues' included — an operational check, not a population count._

_Columns ending `_now` are the state when this report ran (2026-09-22), not at the cutoff — the schema keeps no history for them._

| live_over_24h_now | bookings_with_two_live_rounds_now | double_posted_live_cards | start_failures_4w | finish_failures_4w | client_errors_4w |
|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 |

## assistance

_Four-week context only. The stop condition is judged week by week in `assistance_weekly`, never on this aggregate._

| assisted_sessions_4w | support_sessions_4w | feedback_rows_4w | bug_or_confusing_4w |
|---|---|---|---|
| 9 | 1 | 0 | 0 |

## clash

| golfers_shown_a_clash_4w | golfers_opened_a_receipt_4w | seasons_running_on_report_date |
|---|---|---|
| 0 | 0 | 0 |

## sharing

| week | through | kind | shared | opened | claim_started | profiles_created | first_rounds |
|---|---|---|---|---|---|---|---|
| 2026-10-26 | 2026-11-01 | claim | 0 | 0 | 0 | 1 | 0 |
| 2026-10-26 | 2026-11-01 | join | 0 | 1 | 0 | 0 | 0 |
| 2026-10-26 | 2026-11-01 | none | 0 | 0 | 0 | 0 | 1 |
| 2026-10-19 | 2026-10-25 | share | 1 | 1 | 0 | 0 | 0 |

## sharing_outcomes

_Guest seats (no membership, no account at play) in real games; claimed and answered are today's status._

_Columns ending `_now` are the state when this report ran (2026-09-22), not at the cutoff — the schema keeps no history for them._

| week | through | guest_seats | guest_seats_claimed_now | invitations_sent | invitations_accepted_now | invitations_declined_now |
|---|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | 0 | 0 | 0 | 0 | 0 |
| 2026-10-26 | 2026-11-01 | 0 | 0 | 1 | 1 | 0 |
| 2026-10-19 | 2026-10-25 | 0 | 0 | 0 | 0 | 0 |
| 2026-10-12 | 2026-10-18 | 0 | 0 | 0 | 0 | 0 |
| 2026-10-05 | 2026-10-11 | 2 | 1 | 0 | 0 | 0 |
| 2026-09-28 | 2026-10-04 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-21 | 2026-09-27 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-14 | 2026-09-20 | 0 | 0 | 0 | 0 | 0 |

## activation_weekly

_EVENTS in each week among eligible golfers — not a funnel. A first round this week can belong to an account from months ago; the signup funnel is `activation_cohort`._

| week | through | accounts_created | first_rounds | second_rounds | live_games_finished |
|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | 1 | 0 | 0 | 1 |
| 2026-10-26 | 2026-11-01 | 1 | 1 | 0 | 4 |
| 2026-10-19 | 2026-10-25 | 0 | 2 | 1 | 5 |
| 2026-10-12 | 2026-10-18 | 0 | 1 | 0 | 3 |
| 2026-10-05 | 2026-10-11 | 1 | 1 | 0 | 3 |
| 2026-09-28 | 2026-10-04 | 0 | 0 | 0 | 0 |
| 2026-09-21 | 2026-09-27 | 0 | 0 | 0 | 0 |
| 2026-09-14 | 2026-09-20 | 0 | 0 | 0 | 0 |

## activation_cohort

_The FUNNEL: of the eligible accounts created in each week, how many had posted, posted again and played a finished real game by the cutoff._

| signup_week | through | accounts | posted_a_round_by_cutoff | posted_a_second_by_cutoff | played_a_finished_game_by_cutoff |
|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | 1 | 0 | 0 | 0 |
| 2026-10-26 | 2026-11-01 | 1 | 0 | 0 | 0 |
| 2026-10-19 | 2026-10-25 | 0 | 0 | 0 | 0 |
| 2026-10-12 | 2026-10-18 | 0 | 0 | 0 | 0 |
| 2026-10-05 | 2026-10-11 | 1 | 1 | 1 | 0 |
| 2026-09-28 | 2026-10-04 | 0 | 0 | 0 | 0 |
| 2026-09-21 | 2026-09-27 | 0 | 0 | 0 | 0 |
| 2026-09-14 | 2026-09-20 | 0 | 0 | 0 | 0 |

## signups_first_event_platform

_A PROXY. The platform of each account's first client event, which can come days after sign-up and from the other client. An account is not an install and never a first-time App Store download._

| week | through | accounts | first_event_web | first_event_ios | first_event_unlabelled | first_event_other | no_event_yet | attributed_to_a_link | link_kinds |
|---|---|---|---|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | — |
| 2026-10-26 | 2026-11-01 | 1 | 0 | 1 | 0 | 0 | 0 | 1 | claim |
| 2026-10-19 | 2026-10-25 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| 2026-10-12 | 2026-10-18 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| 2026-10-05 | 2026-10-11 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | — |
| 2026-09-28 | 2026-10-04 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| 2026-09-21 | 2026-09-27 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |
| 2026-09-14 | 2026-09-20 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | — |

## assistance_weekly

_The stop condition, per local week and cohort: STOP when assisted sessions exceed unassisted completions; UNKNOWN when only incomplete session evidence stands between the week and a STOP — complete the session log and re-run. A completion is one finished real game, however many cards it posted._

| week | through | cohort | assisted_sessions | completions | assisted_completions | unassisted_completions | unknown_completions | cards_posted | support_contacts | stop_condition |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-11-02 | 2026-11-02 | competition | 1 | 1 | 1 | 0 | 0 | 0 | 0 | STOP: assisted sessions exceed unassisted completions |
| 2026-11-02 | 2026-11-02 | friends | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-11-02 | 2026-11-02 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-11-02 | 2026-11-02 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-10-26 | 2026-11-01 | competition | 0 | 2 | 0 | 2 | 0 | 0 | 0 | ok |
| 2026-10-26 | 2026-11-01 | friends | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-26 | 2026-11-01 | independent | 2 | 2 | 0 | 0 | 2 | 0 | 0 | UNKNOWN: 2 completion(s) lack session evidence |
| 2026-10-26 | 2026-11-01 | owner | 1 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-10-19 | 2026-10-25 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-19 | 2026-10-25 | friends | 2 | 2 | 2 | 0 | 0 | 2 | 1 | STOP: assisted sessions exceed unassisted completions |
| 2026-10-19 | 2026-10-25 | independent | 1 | 3 | 1 | 2 | 0 | 0 | 0 | ok |
| 2026-10-19 | 2026-10-25 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-10-12 | 2026-10-18 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-12 | 2026-10-18 | friends | 2 | 3 | 1 | 2 | 0 | 0 | 0 | ok |
| 2026-10-12 | 2026-10-18 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-12 | 2026-10-18 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-10-05 | 2026-10-11 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-05 | 2026-10-11 | friends | 0 | 3 | 0 | 3 | 0 | 0 | 0 | ok |
| 2026-10-05 | 2026-10-11 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-10-05 | 2026-10-11 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-09-28 | 2026-10-04 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-28 | 2026-10-04 | friends | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-28 | 2026-10-04 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-28 | 2026-10-04 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-09-21 | 2026-09-27 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-21 | 2026-09-27 | friends | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-21 | 2026-09-27 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-21 | 2026-09-27 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |
| 2026-09-14 | 2026-09-20 | competition | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-14 | 2026-09-20 | friends | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-14 | 2026-09-20 | independent | 0 | 0 | 0 | 0 | 0 | 0 | 0 | no activity |
| 2026-09-14 | 2026-09-20 | owner | 0 | 0 | 0 | 0 | 0 | 0 | 0 | not gated |

## acquisition

_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._

**Input problems (the rows named were left out; nothing here was guessed):**
- log: line 8: week_ending 2026-10-26 is not a Sunday — a week is logged on the Sunday it ends; the row was left out
- log: lines 9, 10 are all week 2026-11-01 / channel by_hand — one row per key; merge them into one row. The report left every one of them out.

_Left out as after the report date 2026-11-02: 1 log row(s), 1 reading(s)._

### checkpoints — cumulative first-time App Store downloads

_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._

| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |
|---|---:|---|---|---|
| 2026-10-31 | 500 | met | 512 through 2026-10-31 | 330 (3 of 4 weeks logged) |
| 2026-11-30 | 2,000 | open | 512 through 2026-10-31 | 330 (3 of 5 weeks logged) |
| 2026-12-31 | 5,000 | open | 512 through 2026-10-31 | 330 (3 of 5 weeks logged) |

_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._

### the weekly log — logged subtotals

_Weeks logged: 4 of 5 from 2026-10-04 to 2026-11-01; not logged: 2026-10-25._

| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |
|---|---:|---:|---:|---:|---:|---:|---|
| 2026-11-01 | — | — | — | — | — | 0 | public_link |
| 2026-10-18 | 8 | 1 | — | 120 | 3 | 0 | by_hand, unattributed |
| 2026-10-11 | 10 | 2 | 2 | 145 | 4 | 1 | by_hand, r/golf |
| 2026-10-04 | 12 | 3 | 1 | 65 | 23 | 0 | by_hand, public_link |

### by channel — logged subtotals, not verified totals

| channel | first-time App Store downloads logged | weeks with a number |
|---|---:|---:|
| by_hand | 125 | 2 |
| unattributed | 120 | 1 |
| r/golf | 60 | 1 |
| public_link | 25 | 1 |

### App Analytics readings used

| through | cumulative first-time downloads | source |
|---|---:|---|
| 2026-10-18 | 330 | App Analytics (SYNTHETIC) |
| 2026-10-31 | 512 | App Analytics (SYNTHETIC) |

## Known measurement gaps

- Founder assistance is what `pilot_sessions` says and nothing else; an unlogged phone call is invisible. A session with no end time, or with no golfers and no resolvable group, makes the games it overlaps UNKNOWN — never unassisted.
- `clash_seen` is exposure. It says a clash was on screen, not that anyone valued it. `receipt_viewed` is the nearest interaction fact.
- "One round, quiet 3 weeks" is not churn. Golf is intermittent; read it against the season calendar and the weather.
- Client events are attempts and failures only; every success is read from the product tables. A device that never reached the network reports nothing.
- Counts under about 10 are printed as counts. No percentage here is statistically conclusive at pilot size.
- The eligible population excludes the founder, deleted accounts, the App Review account and test-seed bots — defined once, applied to every account and round count. A real game is one outside sandbox leagues with at least one eligible golfer, the same rule in every game count; only the integrity checks watch every live round.
- A guest seat is a seat with no membership and no account at play. Every seat carries a claim token by default, so a token alone never makes a guest.
- The first-event platform is a proxy: the first event can follow sign-up by days and come from the other client. An account is not an install, and none is a first-time App Store download.
- `attributed_to_a_link` is written by `log_growth_event` on `profile_created`; a blank means no attribution was observed (a direct arrival, a seeded account, or a signup before the writer shipped on 2026-08-29), not a broken writer.
- The store count is what the owner recorded from App Store Connect and nothing else; a checkpoint is judged only on a dated App Analytics reading.
