# Pilot scorecard · 2026-09-16 · linked project (read-only)

_**The pilot record (20261106090000) is not on this database.** Every golfer is reported as one cohort named `all`; founder assistance cannot be subtracted. Apply the migration and name the cohorts before reading these numbers as pilot evidence._

## eligible

| cohort | golfers | groups |
|---|---|---|
| all | 33 | 0 |

## golfer_funnel

| cohort | first_round_posted | golfers | invited_or_opened_link | joined | joined_never_posted | one_round_quiet_3w | posted_again |
|---|---|---|---|---|---|---|---|
| all | 21 | 33 | 1 | 23 | 3 | 0 | 21 |

## organizer_funnel

| cohort | completed_a_competition | had_first_participant_round | opened_a_competition | organizers | started_another |
|---|---|---|---|---|---|
| all | 1 | 5 | 5 | 9 | 1 |

## live_games

| abandoned | finished | from_a_booking | league_less | start_failures_reported | started | still_live | week |
|---|---|---|---|---|---|---|---|
| 0 | 1 | 0 | 0 | 0 | 1 | 0 | 2026-09-14 |
| 0 | 2 | 0 | 0 | 0 | 2 | 0 | 2026-09-07 |
| 9 | 1 | 0 | 6 | 0 | 10 | 0 | 2026-08-31 |
| 1 | 1 | 0 | 0 | 0 | 2 | 0 | 2026-08-24 |
| 2 | 1 | 0 | 0 | 0 | 3 | 0 | 2026-07-27 |
| 8 | 2 | 0 | 0 | 0 | 10 | 0 | 2026-07-20 |

## posting

| all_guests_claimed | every_seat_posted | finished_rounds | had_account_less_guests | nothing_posted |
|---|---|---|---|---|
| 0 | 5 | 8 | 8 | 2 |

## repeat_groups

| groups_with_a_finished_game | groups_with_a_second_game | one_game_quiet_3w |
|---|---|---|
| 3 | 2 | 0 |

## integrity

| bookings_with_two_live_rounds | client_errors_4w | double_posted_live_cards | finish_failures_4w | live_over_24h_not_abandoned | start_failures_4w |
|---|---|---|---|---|---|
| 0 | 9 | 0 | 0 | 0 | 0 |

## assistance

| assisted_sessions | bug_or_confusing_4w | feedback_rows_4w | support_sessions |
|---|---|---|---|
| 0 | 0 | 0 | 0 |

## clash

| golfers_opened_a_receipt_4w | golfers_shown_a_clash_4w | seasons_running |
|---|---|---|
| 2 | 0 | 5 |

## Known measurement gaps

- Founder assistance is what `pilot_sessions` says and nothing else; an unlogged phone call is invisible.
- `clash_seen` is exposure. It says a clash was on screen, not that anyone valued it. `receipt_viewed` is the nearest interaction fact.
- "One round, quiet 3 weeks" is not churn. Golf is intermittent; read it against the season calendar and the weather.
- Client events are attempts and failures only; every success is read from the product tables. A device that never reached the network reports nothing.
- Counts under about 10 are printed as counts. No percentage here is statistically conclusive at pilot size.
- Leagues flagged `sandbox` and the founder's own profile are excluded from every cohort but `owner`.
