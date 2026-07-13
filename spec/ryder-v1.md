# The Ryder — v1 build spec

Promoted from `gameplay-modes-working.md` §4 with the 2026-07-13 decisions.
Source of truth for the build. Cite §R2/§R3 etc.

## §R1 — What it is
A **standalone event** (not a league — no seasons/floors/caps): two teams,
captains, N weekly sessions of **PvI duels**. The off-season / side product.
Runs on the existing `rounds` machinery + one new schema arc.

## §R2 — Locked decisions (2026-07-13)
1. **Standalone event entity**, schema option 1 (`events` + children). Shows on
   its own event surface, NOT in the league switcher's league list.
2. **Duration = weekly sessions.** 3wk→3, 6wk→6 sessions. Long option (3mo) uses
   `session_weeks=2` (bi-weekly) to keep it ~6 sessions, not 13. Sweet spot 3–6.
3. **Pairings v1 = auto-seed** (by roster seed order), organizer can override
   later. Blind-envelope drama is a fast-follow.
4. **Draw rule = `team_pvi` tiebreak** for one-offs (higher total team PvI wins);
   `defender` retains once an event has a prior holder; `shared` optional.
5. **v1 = singles only.** Fourball pairs / live-day finale are fast-follows.
6. **Event↔league linkage = B (2026-07-13).** An event may **attach to a league**
   (nullable `events.league_id`, borrow its crew + board) OR stand alone (null).
   It always scores as its own **parallel ledger** — never touches cup points.
   Attach requires the creator be a league member; `on delete set null` so
   scrapping a league detaches, never destroys, the event. Entry points fork in
   the clubhouse: **Start a League · Start an Event · Join** (peer containers),
   plus "Run a Ryder with this crew" from inside a league. League-member reads of
   attached events + board fan-out (`posts.event_id`) are fast-follows; v1 gates
   reads on event membership.

## §R3 — The duel (the async match)
`duel(session, A, B)`: each player's **best round in the session window**
`[opens_on, closes_on]`, compared by **PvI recomputed at 100% allowance**:
`pvi = index_at_post − differential` (higher wins). Ties → halve.
- A wins → A 1 / B 0; halve → ½ each.
- One player posts, other idle → poster wins 1–0.
- Both idle → halve (½ each). *(harsher 0–0 dial deferred.)*
- Multiple rounds in window → best PvI counts automatically.

## §R4 — Scaling (generalizes real Ryder's 28 / 14.5)
```
pairings/session P = min(rosterA, rosterB)   (larger team benches surplus, rotated)
points available M = Σ over sessions of P
clinch number      = M/2 + 0.5   ·   draw at exactly M/2
```
12v12 × (4+4+12 real) = 28 → 14.5. Ours (singles): 6v6 × 3 = 18 → 9.5.

## §R5 — Schema (`events` first-class; additive; spec §17 reserved this)
- `events(id, name, created_by, league_id (nullable, decision B), kind='ryder',
  status setup|live|complete, starts_on, session_count, session_weeks,
  draw_rule, defender_team_id, allowance=100)`
- `event_teams(id, event_id, slot 0|1, name, color, captain_player_id)`
- `event_players(id, event_id, profile_id, team_id, role, seed, benched_count)`
- `event_sessions(id, event_id, session_no, opens_on, closes_on, status, weight=1)`
- `event_duels(id, event_id, session_id, a_player, b_player, a_round, b_round,
  a_pvi, b_pvi, a_points, b_points, result pending|a|b|halve, resolved_at)`
- View `v_event_scoreboard(event_id, team_id, points)`.
- RLS: members read their event; writes via security-definer RPCs.

## §R6 — RPCs
- `create_event(name, starts_on, sessions, session_weeks, draw_rule, teamA, teamB)`
  → event + 2 teams + N dated sessions (Sun→Sat). Creator = organizer + Team A captain.
- `add_event_player(event, profile)` / `set_event_team(player, team)` — roster + assign.
- `generate_pairings(session)` — seed-order pairings up to P; bench surplus (++benched_count).
- `resolve_session(session)` — compute duels from rounds, set points, close session,
  flip event→complete when a team passes the clinch number.

## §R7 — UI (viewable MVP first)
Read-only **event scoreboard** is the home: big `A ½ – ½ B` with the "First to
X.5" line, per-session strips of duel chips (won/lost/halved/pending), team
rosters with each player's duel record, "who hasn't posted" nag. Entry from the
league-switcher sheet's new **Events** section. Create-event + captain-pick UX
and the event board are the next slice.

## §R8 — Not in v1
Blind-envelope pairings, fourball/live-day sessions, event board+push, pot
settlement UI (buy_ins pattern reused later), recurring/defense history.
