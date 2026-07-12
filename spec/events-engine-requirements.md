# Cup Season — Events Engine: Requirement Doc

Status: DRAFT for sign-off · 2026-07-12 · the "app feels alive" arc (task #5)
Feeds from: product-vision-v1.0 (principle 5, memory > statistics),
personas-dashboards-v1.0 (role homes, storytelling standings, watch list),
gameplay-modes-working §7 (monthly engine, weekly moments).
Decision-needed items marked ⚑.

## 0. Purpose

Opening Cup Season should reveal something new: someone posted, standings
changed, a rivalry shifted, a streak continued. The engine is (a) a data
layer that DETECTS moments from data we already collect — zero new golfer
effort — and (b) the surfaces that tell them: board posts, curated pushes,
storytelling standings, the trophy case, and the role-aware Home.

## 1. Foundation — snapshots & the cron spine

**standings_snapshots** (new table): one row per squad per week per season
(`season_id, week_no, taken_on, squad_id, points, rank`) plus individual
rows (`member_id, points, rank`) — ⚑ same table with nullable squad/member
vs two tables; leaning one table, `scope` column.

Written by `run_week_snapshots` every Sunday 23:59 league-local. This arc
FINALLY enables **pg_cron** (m006's commented block: `run_month_closes`,
`run_week_snapshots`, `daily_season_tick`).

**⚠ Pre-flight audit (workstream 0):** m006's close/tick functions predate
the 007 profile-first restructure. `rounds_compute` and `round_to_board`
were both stale in prod; assume `close_month`, `run_month_closes`,
`daily_season_tick`, and `cup_points` call-chains may be too. Audit every
function the cron block invokes against the live schema BEFORE scheduling.

Snapshots immediately make real: the season race chart (task #5's original
golf-data half), week-over-week deltas, and lead-change detection.

## 2. Moment detection (the events)

**Round-triggered** (fires in the round fan-out path; all derivable):
- Personal best differential (vs the profile's full history)
- Barrier broken: first career sub-100 / sub-90 / sub-80 gross ⚑ (career vs
  per-season firsts — leaning career, they're rarer and bigger)
- Streak extended/started: consecutive weeks with ≥1 posted round
- Lead change: league's #1 squad differs after this round scores
  (one v_squad_standings comparison per round insert)

**Weekly** (cron, with the snapshot): week winner per league (squad points
gained), best individual PvI of the week, watch-list data refresh.

**Monthly** (extends existing close_month): month winner detail joins the
"JULY CLOSED" post; hybrid +15 announcement (full months only, per §7.12).

Moments post to the board as kind **'moment'** (new posts kind, icon-styled
like announcements but green) — compact one-liners on Home, styled cards in
the full board.

## 3. Rivalries & head-to-head

Lifetime record vs friends, zero-effort. ⚑ v1 definition (pick one):
- **Weekly clash (leaning):** in any shared-league week where BOTH posted,
  better best-PvI takes the week; lifetime W-L-T per pair.
- Monthly clash: same but month windows (fewer, chunkier).
- Same-day clash: only when both posted the same day (rarer, most "real").

Computed as a view (`v_rivalries`) over rounds + shared memberships — no
new writes. Surfaces: player profile card ("vs Jake: 14-9"), moment posts
on lead swaps ("Jerecho takes the season series lead over Marcus"), watch
list ("Steve plays Sunday — the Jake series is tied").

## 4. Achievements & the trophy case

`achievements` table (`profile_id, kind, label, earned_on, meta jsonb`),
written by the detectors, rendered in the You tab's trophy case (shipped as
placeholder in v23.55). ⚑ v1 catalog: barriers (sub-100/90/80), personal
best, iron-man streaks (4/8/12 weeks), first round posted, first league
won, Points King, month winner, season champion. Career-level, immutable,
receipts attached (round_id / season_id in meta).

## 5. Storytelling standings & scenario math

Standings rows gain a narrative line. v1 (cheap, from snapshots + points):
"leads by 12" · "7 back — one good weekend" · "up 3 spots this week".
v2 (needs migration 008's endgame dial): clinched / eliminated / controls
own destiny / must win. The scenario primitive — "if X posts +3 PvI, they
move to Nth" — also powers the calendar's tap-a-round projections later.

## 6. Role-aware Home (the engine's UI layer)

- **The Pro:** command central — rounds missing vs floor this month
  ("18/24 in · waiting on Jake, Steve, Mike"), league health cards
  (players who haven't played, playoff/final lock date, month close
  countdown), announce shortcut.
- **Golfer:** standing strip (position, record, points behind, finals
  status) + **"your next round matters because…"** (from the scenario
  primitive: "a 9-pointer moves Mudsharks to 1st").
- Both render from engine data; the shell already adapts by state, this
  adds role. Captain variant deferred to the wizard-rebuild arc.

## 7. Curated notifications (the push switch)

Replace all-posts push with kind-based curation:
- always: announce, moment (lead change, clinch, barrier), invited/added
- rounds: ⚑ default ON or OFF? (personas doc says "friend posted" is
  meaningful; leaning ON with the existing per-user mute pattern extended
  to a notify_rounds flag)
- chat: existing notify_chat flag (unchanged)
Friend requests/accepts already ride their own branch.

## 8. Build order (each step independently shippable)

0. Audit m006 cron-chain functions against post-007 schema; fix stale ones
1. standings_snapshots + enable pg_cron (snapshots, month closes, tick)
2. Real season race chart + week-over-week standings deltas (kills the
   last big demo edge)
3. Round-triggered detectors + 'moment' posts kind
4. Weekly winner posts + storytelling standings v1
5. achievements + trophy case UI
6. v_rivalries + profile h2h display
7. Role-aware Home (Pro command central, golfer next-steps)
8. Curated push switch
Then: League Calendar / declared rounds (task #16) rides the scenario
primitive from §5.

## 9. Explicitly out of scope

Photos (own arc), kudos/comments on real posts (social pass with photos),
matchup view hole detail (course cards), captain dashboards (wizard arc),
Golf Wrapped / AI summaries (later, on top of this data).
