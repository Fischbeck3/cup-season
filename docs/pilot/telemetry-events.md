# Pilot telemetry — every event, its denominator, and where the truth lives

Written 2026-09-15 for the staged pilot. The rule throughout: **an attempt is
what a client says it tried; a success is what the server's own tables say
happened.** The scorecard reads successes from the tables and uses client
events only for attempts, failures and exposure. Missing analytics never
blocks gameplay: every client write is fire-and-forget, and a refused insert
is silent by design.

## What already existed (reused, not duplicated)

| Surface | What it is | Reused for |
|---|---|---|
| `client_events` (event, props, profile_id) | the one client-side event table, web `qaEvent`, phone `CSTelemetry.event` (DEBUG builds write nothing) | attempts, failures, exposure |
| `growth_events` (`artifact_shared` · `link_opened` · `claim_started` · `profile_created` · `first_round_posted`) | fail-closed server-side funnel via `log_growth_event`; anon may log only a real link opening | golfer funnel: invited/link → joined → first round |
| `pilot_feedback` (category, body, context) | in-app feedback, founder-readable | support requests and friction reports |
| `rounds`, `live_rounds`, `live_round_players`, `scheduled_rounds`, `round_rsvp`, `leagues`, `seasons`, `events`, `league_members`, `invitations` | the product's own facts | every success and every completion |

## What is new (written, validated on the sandbox, NOT applied)

`20261106090000_the_pilot_keeps_its_own_record.sql`:

- `pilot_cohort_members (profile_id, cohort, group_key, added_at, added_by, note)` — the founder names who is in which cohort (`owner · friends · independent · competition · founding`). **This is the denominator.** Founder-only read and write.
- `pilot_sessions (cohort, group_key, kind assisted|observed|support, started_at, ended_at, golfers[], notes)` — when the founder was in the room. **Telemetry cannot infer assistance; this records it.** Founder-only.
- `client_events_one_attempt` — a partial unique index on `(profile_id, event, props->>'attempt_id')`. A retried event with the same attempt id is stored once; the second insert is refused and the client never notices.

## Event definitions

Every client event below carries `attempt_id` and `platform` (`web` / `ios`). An attempt id is minted once per user action (a tee-off tap, a finish tap) and re-sent verbatim on retry; exposure events use a deterministic id (`<key>:<day>`) so a day counts once.

| Event | Fired when | Denominator it serves | Success comes from |
|---|---|---|---|
| `live_start_attempted` | the tee-off button is tapped and validation passed (`game`, `via_plan`, `players`) | golfers who tried to start a live game | `live_rounds` row exists (server) |
| `live_start_succeeded` | the start RPC returned a round id (`via_plan`, `live_round_id`) | cross-check only — `live_rounds` is the truth | — |
| `live_start_failed` | the start RPC refused or errored (`reason`: `refused` / `error` / server text ≤80 chars) | failure rate per attempt | — |
| `live_join_result` | a plan-aware start found a standing round (`outcome`: `joined` / `no_seat`) | join outcomes per booking | `live_round_players` + `live_join` presence |
| `live_finish_attempted` | finish tapped (`live_round_id`, `casual`) | rounds where a finish was tried | `live_rounds.status = 'final'`, `rounds` rows |
| `live_finish_result` | the finish RPC answered (`posted`, `skipped`, `already_final`) | posting outcome per finish | `rounds.live_round_id` |
| `live_finish_failed` | the finish RPC errored | finish failure rate | — |
| `post_open` / `post_submit` (existing, web) · `round_posted` (existing, phone product metric) | the ordinary composer | golfers who tried to post | `rounds` (source `app`), `post_round_once` replay table |
| `receipt_viewed` (existing on the phone; added on the web) | a receipt opened; id `receipt:<round>:<day>` | receipt interaction per posted round | — |
| `clash_seen` (new, both) | a `clash:` item was rendered on Home; id `<key>:<day>` | weekly clash EXPOSURE — a view is not proof of value | — |
| `home_state_seen`, `cta_tapped`, `home_occasion_tap` (existing) | Home surfaces | context only | — |

Recovery is a server fact, not an event: a round that was live for more than 24 hours without a finish is abandoned by the server; a snapshot on a phone that later finishes is a finish like any other. The scorecard counts **finished / abandoned / still live** per started round.

## Organizer funnel (server-derived)

| Step | Definition |
|---|---|
| setup started | first of: a `leagues` row created by the profile; a `scheduled_rounds` row declared; an `events` row created |
| competition opened | a `seasons` row for their league reached `active` (the lock), or an event reached `live` |
| first participant round | first `rounds` row by ANY member of that league with `played_on ≥ season.starts_on`, or any posted card from a live round on that booking |
| second competition | a second league locked, or a second event created, by the same organizer |

## Golfer funnel (server-derived where possible)

| Step | Definition |
|---|---|
| invited / link opened | `invitations` row addressed to the profile, or `growth_events.link_opened` resolved to a real token (fail-closed) |
| joined | `league_members` row, or `round_rsvp` = `in`, or a seat in `live_round_players` |
| first completed round | first non-voided `rounds` row for the profile (any source) |
| next posted round | the second non-voided `rounds` row, and the days between |

## Repeat use and completion

| Measure | Definition |
|---|---|
| group's second completed game | a group key (league id, or the set of seated profiles for league-less play) with ≥ 2 `live_rounds` in `final` |
| competition completion | `seasons.status = 'complete'` or `events.status = 'complete'` |
| organizer started another | see "second competition" |

## Excluding what is not the pilot

- `state.demo` on the web writes no client events; DEBUG phone builds write none; the sandbox is a different database.
- The founder's own profile (`founder_id()`) and any profile in `pilot_cohort_members.cohort = 'owner'` are reported separately, never inside the Friends or Independent cohorts.
- Activity inside a `pilot_sessions` window with `kind = 'assisted'` is reported as **assisted** for the golfers listed in that session. Nothing infers it.
- `props` never carries a raw claim token, an email, or a name. `live_round_id` and `round_id` are opaque ids the founder can already read.

## Deployment compatibility

Events are inserted by the same writers that exist today; a database without the attempt index simply keeps duplicates (the phone already de-duplicates in memory). The cohort and session tables are founder-only; no client reads them. A client that never sends an `attempt_id` is unaffected by the index. Nothing here is required for a round to be played, scored or posted.
