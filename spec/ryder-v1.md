# The Ryder — v1 requirement doc

Status: BUILD-READY DRAFT v2 · 2026-07-16 · supersedes the 2026-07-13 skeleton
(all §R2 locked decisions carried forward unchanged). Source of truth for the
events-schema arc. Cite §R-numbers. Open items for sign-off are ⚑-flagged in
§R12 — everything else is locked or requirement-level detail within already-
decided authority (gameplay-modes §4, §7b #9–11 #13, §7c #17–18).

Hierarchy: vision (off-season / distributed-crew product; persona 1's ONLY
product) → principles (low friction: posted rounds ARE the gameplay; feels
alive: every duel result is drama) → IA (events are peer containers to
leagues; Start a League · Start an Event · Join) → this doc → UI → schema.

## §R1 — What it is

A **standalone event**: two named teams, captains, N weekly sessions of
**async duels** — best posted round in the window, scored vs your own number,
head to head. No seasons, floors, caps, or cup points, ever (parallel ledger,
gameplay-modes §5). Runs on the existing `rounds` machinery + the events
schema arc. The pitch: *your Tuesday round in Tempe just beat his Saturday
round in Denver.*

## §R2 — Locked decisions (2026-07-13, unchanged)

1. **Standalone event entity**, schema option 1 (`events` + children). Own
   surface; never in the league switcher's league list.
2. **Duration = weekly sessions**, 1–6 (default 3); `session_weeks=2` for the
   long variant. Sessions run Sun→Sat (league-standard weeks, §14.0).
3. **Pairings v1 = auto-seed** by roster seed order; organizer override.
   Blind envelopes = fast-follow.
4. **Draw rule dial:** `team_pvi` (one-offs) · `defender` (holder retains) ·
   `shared` (optional).
5. **v1 = singles only.** Fourball / live-day finale = fast-follows.
6. **Event↔league linkage = B:** nullable `events.league_id` — attach
   (borrow crew + board) or stand alone. Attach requires league membership;
   `on delete set null`. v1 gates reads on event membership.

## §R3 — The duel (the atom)

`duel(session, A, B)`: each player's **best round posted in the session
window** `[opens_on, closes_on]` (played_on-based, league-default timezone
America/Phoenix), compared by **PvI at 100% allowance**:
`pvi = index_at_post − differential`. Higher wins; ties halve.

- Win 1 · halve ½ · loss 0.
- One posts, other idle → poster wins 1–0. Both idle → ½ each (locked §7b #11).
- Multiple rounds in window → best PvI counts automatically.
- Eligible rounds: any non-voided, non-sim posted round (9-hole rounds count —
  the differential already normalizes; ⚑ R12.1 to confirm sim exclusion).
- **The number to beat (batch-3 #17, binding):** the moment an opponent's
  round lands in an open session, the duel chip shows it unconditionally —
  "Marcus posted +1.2 · you have until Sunday." The PUSH for it is per-user
  **opt-in** (`event_players.notify_target`, default off). Timing meta
  (post early to set the pace vs hold your card) is a feature, not a leak.

## §R4 — Scaling & the clinch

```
pairings/session P = min(rosterA, rosterB)   (larger team benches surplus, rotated)
points available M = Σ over sessions of P
clinch             = floor(M/2) + ½ point    ·   draw at exactly M/2
```

- Real Ryder: 12v12, 28 pts → 14½. Ours, 6v6 × 3 singles = 18 → 9½.
- Clinch/"magic number" shows on the scoreboard as it develops; the event
  flips `complete` the moment a team passes it (remaining duels still resolve
  for the record — rounds are facts).
- **Draw** → `draw_rule`: `team_pvi` = higher summed winning-duel PvI margin
  takes it (logged like the §14.3 coin flip, receipts attached) · `defender`
  retains · `shared` = both names engrave.
- **Bench rotation:** surplus players sit per session; app nudges the captain
  toward whoever has sat most (`benched_count`), never forces. Benched
  players can still post rounds (they just don't score).

## §R5 — Schema (first-class events; additive; spec §17 reserved this)

```
events(id, name, created_by (profile), league_id nullable→leagues ON DELETE SET NULL,
       kind 'ryder', status setup|live|complete, starts_on date,
       session_count int 1..6, session_weeks int 1|2, draw_rule text,
       defender_team_id nullable, allowance int default 100,
       winner_team_id nullable, buy_in numeric default 0, created_at)
event_teams(id, event_id, slot 0|1, name, color, captain_player_id nullable)
event_players(id, event_id, profile_id, team_id nullable (pre-assign),
              role organizer|captain|player, seed int, benched_count int 0,
              notify_target bool default false,
              unique(event_id, profile_id))
event_sessions(id, event_id, session_no, opens_on, closes_on,
               status open|closed, weight int 1)
event_duels(id, event_id, session_id, a_player→event_players, b_player,
            a_round nullable→rounds, b_round nullable,   -- the receipts (§16)
            a_pvi numeric, b_pvi numeric,
            result pending|a|b|halve, resolved_at)
posts.event_id uuid nullable            -- board rail (events-engine #9)
v_event_scoreboard(event_id, team_id, points)   -- ½s as numeric
```

RLS: event members read their events + children; all writes via
security-definer RPCs (identity checked at the database, house rule).
`posts` reads extend to event members via event_id.

**Rivalry constraint (batch-3 #18, binding):** `event_duels` is a **facet
feed** of the one-rivalry-object-per-pair. `my_rivalries()` (shipped, weekly-
clash facet) gains a `duels` facet reading resolved event_duels. Never blend
into one number: "Jerecho vs Marcus — 12 meetings · weekly clashes 7–4 ·
Ryder duels 2–1." Ship the facet WITH v1, not after — retrofit is the
expensive path the decision log warns about.

## §R6 — RPCs (all security-definer)

- `create_event(p_name, p_starts_on, p_sessions, p_session_weeks, p_draw_rule,
  p_team_a, p_team_b, p_league default null)` → event (status `setup`) +
  2 teams + N dated Sun→Sat sessions. Creator = organizer + Team A captain
  by default. Validates: starts on a Sunday; league attach → creator must be
  a member.
- `add_event_player(p_event, p_profile)` — organizer/captains invite by
  handle/buddy/league roster (reuses the shipped invites machinery —
  `openInvitePicker` already speaks `container.event`). Accounts required;
  no guests (§5 cross-cutting — duels need posted rounds).
- `set_event_team(p_player, p_team)` + `set_event_seed(p_player, p_seed)` —
  roster assignment. v1 assignment = organizer/captains tap-assign
  (captains-pick theater is the league formation engine's; reuse later).
- `start_event(p_event)` — setup→live gate: both teams ≥1 player, rosters
  final warning. Posts the lineup card to the event board.
- `generate_pairings(p_session)` — seed-order pairing up to P; benches
  surplus (++benched_count, nudge order); writes pending event_duels; posts
  pairings to the board. Runs at session open (tick) or organizer tap.
- `resolve_session(p_session)` — for each duel: best eligible round per
  player in-window → pvi @100 → result + round receipts; closes the session;
  posts each result ("W2: JERECHO DEF. MARCUS, +2.1 VS −0.4") + a session
  summary; flips event complete (+ winner, trophies §R8) past the clinch.
  Idempotent (re-run = no-op on closed).
- **Timing:** `daily_season_tick` (cron) grows two duties: open sessions
  whose `opens_on` arrived (→ generate_pairings) and resolve sessions whose
  `closes_on` passed. Organizer also gets manual "resolve now".

## §R7 — UI (three slices, each shippable)

**Slice 1 — the scoreboard (read-only MVP).** Event home: big `USA 6½ – 4½ EUROPE`
with "first to 9½"; per-session strips of duel chips (won/lost/halved/pending
— pending chips carry the **number to beat** per §R3); rosters with duel
records; "who hasn't posted · N days left" nag list. Entry: the group
switcher's Events section (exists — `openEvent`/`loadMyEvents` shipped).

**Slice 2 — create + roster.** Start an Event fork in the switcher sheet
(IA: peer of Start a League) + "Run a Ryder with this crew" inside a league
(prefills league_id + roster picker from members). Wizard: name, two team
names/colors, start Sunday, sessions (default 3), buy-in note. Invites ride
the People Picker.

**Slice 3 — drama rails.** Event board (posts.event_id fan-in on the one
feed), duel-result pushes (existing webhook, event_id-aware), opt-in target
push, bench nudges, settlement card at completion.

**Pot (shape now, UI later — §R8/R12):** `buy_in` tracked per event; payout
default = winning team splits evenly (locked §7b: MVP cut exists as a dial,
OFF, no UI). Completion posts the settlement card (the v23.155–157 pattern:
tracked-never-held, minimized lines, shaped for the screenshot).

## §R8 — Completion & memory

- Winner team members get a **trophy** (`trophies` kind 'ryder' — the case
  already renders it) with event name + year; receipts = the event id.
- MVP (best duel record, tiebreak total PvI) computed and NAMED on the recap
  board post — no pot cut v1 (dial off).
- Rivalry facets update per duel (§R5). Board story on completion:
  "THE GRUDGE: TEAM STRIPES TAKE IT 10–8 · MVP: LOGAN 3–0".
- `defender` events: winner becomes `defender_team_id` for the next run —
  recurring events/defense history stays out of v1 (§R11) but the column
  seeds it.

## §R9 — Build checkpoints (each independently shippable)

1. **Schema + scoreboard read** — migration (events tables + posts.event_id
   + view + RLS) + create_event/add_player/set_team RPCs + slice-1 UI fed by
   a hand-created event. Proves the render before any automation.
2. **The duel engine** — generate_pairings + resolve_session + tick duties +
   result board posts. An event can run end-to-end.
3. **Create/roster UX + drama rails** — slice 2 + 3, target chip + opt-in
   push, completion trophies + settlement card + rivalry facet.

## §R10 — Edge cases (decided here, requirement-level)

- **Roster changes after live:** adds allowed until the FIRST session
  closes; never removals once a player has a resolved duel (their results
  are facts). Late adds seed last.
- **Odd rosters (e.g. 5v4):** P=4; bench rotation as §R4. 1v1 events are
  legal (P=1) — that's just a duel series.
- **A player in both teams' crews / duplicate invites:** unique(event,
  profile) + team reassignment allowed until start_event.
- **Voided round mid-session:** duels read non-voided rounds at resolve
  time; already-resolved duels do NOT retro-flip (resolved_at is a fact; the
  organizer's recourse is the log, mirroring season adjustments).
- **Timezone:** session windows evaluate in the event's tz — league's tz
  when attached, else America/Phoenix default (⚑ R12.2).
- **Organizer leaves/deletes account:** event survives (created_by is
  provenance, not a dependency); any captain can resolve/nudge.

## §R11 — Not in v1 (unchanged + additions)

Blind-envelope pairings · fourball/live-day sessions · session weighting UI
(dial exists, off — decision-log D8 keeps it out of UI) · MVP pot cut ·
pot/settlement UI beyond the completion card · recurring events/defense
history · captains-pick theater (reuse league formation later) · cross-event
analytics. Per decision-log D12: user-facing noun is **"the Ryder"** and
"your match this week" — "event" and "duel" stay schema words.

## §R12 — ⚑ Open for sign-off (small, don't block ckpt 1)

1. **Sim rounds in duels:** default EXCLUDE (matches handicap engine's
   basis) — confirm. A sim-heavy winter crew is exactly the off-season
   audience, so the OPPOSITE default is defensible; per-event toggle is the
   escape if real demand shows.
2. **Detached-event timezone:** America/Phoenix default vs creator-profile
   city. Leaning Phoenix (no-DST simplicity, house default).
3. **Session boundary time:** closes_on Saturday 23:59 event-tz (mirrors
   week snapshots) — confirm midnight vs "when resolved by tick ~00:10".
4. **Buy-in v1:** tracked number on the event card + settlement card at
   completion (no per-player buy_ins ledger rows until the pot arc) —
   confirm this thin version is enough for v1.
