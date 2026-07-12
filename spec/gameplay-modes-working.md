# Cup Season — Gameplay Modes (working doc)

Status: WORKING DRAFT — feeds the requirement docs for the tee-sheet arc,
The Ryder, and wizard rebuild. Not user-facing. Where this conflicts with
spec-v1.0.md, the spec wins until a decision here is promoted into v1.1.
Decision-needed items are marked ⚑.

The unifying idea: **PvI (Performance vs Index) is the universal currency.**
Every mode below either consumes PvI directly (season, duels, Ryder) or
consumes hole-by-hole net scores captured by Live Rounds (match play, Wolf).
Nothing ever mutates a round; modes are lenses, same as leagues.

---

## 1. League / Season play (SHIPPED core — consolidated from spec §2–§4, §14)

The season is the flagship mode. Summary of the machinery as built/spec'd:

### 1.1 Round → points pipeline
```
Differential = (Adjusted Gross − Rating) × 113 ÷ Slope      (9-hole: vs nine_rating, ×2)
Playing Index = Index × allowance% (100/95/90, league dial)
PvI = Playing Index − Differential                           (+ = beat your number)
```

Points bands (anti-sandbagging by design — the 12 ceiling caps what a padded
index can buy; the 5 floor makes a posted 98 beat an unposted 82):

| PvI | Cup points |
|---|---|
| +3.0 or better | 12 |
| +1.0 … +2.9 | 9 |
| −0.9 … +0.9 | 7 |
| −3.0 … −1.0 | 6 |
| worse | 5 |

### 1.2 Monthly dials
- **Counting cap:** best N rounds/month feed the squad total (default 4);
  better rounds displace worse in real time; displaced rounds stay visible.
- **Participation floor:** default 2/month; penalty none / −5 per short
  round / forfeit month. 1 bye per player per season. Floors waived in
  partial edge months (Sunday-season rule, m006).
- Squad month = Σ members' counting points − penalties. Season = Σ months.

### 1.3 Season formats
A: Points Race (default) · B: Head-to-Head months (W-L table) ·
C: Hybrid (points race + 15/month to h2h winner).
**Cup Final:** final 4 weeks, seeds lock at `ends_on − 27`, scored fresh
under the league's own counting rules. Tiebreak ladder: h2h months won →
best single month → fewest rounds used → logged coin flip. (Migration 008 —
still to build.)
Individual layer always on: Points King ($ from pot), Most Improved, Iron Man.

### 1.4 Pot (season)
Buy-ins tracked in `buy_ins`, payout split bylaw exists (m006: default
60/25/15 champs/runner-up/points king, must sum 100). Pot is **tracked,
never held** — settlement is a card, money moves on Venmo.
⚑ Pot UI + wizard pot step = the wizard-rebuild checkpoint.

---

## 2. Match Play (live side game — tee sheet)

Spec §13.2 fixes v1: **net best ball off the low man, live status, never
touches cup points.** Expanding into buildable detail:

### 2.1 Formats
- **1v1 singles** and **2v2 best ball** (4-ball). v1 ships both; they share
  all machinery.
- Requires a Live Round (hole-by-hole entry, one phone or everyone's).

### 2.2 Strokes
- Course handicap per player = Index × Slope ÷ 113 (+ rating − par adj, ⚑
  keep simple: Index × Slope ÷ 113 rounded, v1).
- Strokes given = each player's CH − lowest CH in the match ("off the low
  man"). Allocated by the course card's hole stroke index (SI). No card SI →
  fallback allocation: hardest-first by par then hole number, flagged
  "estimated strokes."
- Guests participate with self-declared index (spec §13.3).

### 2.3 Hole + match state
Per hole: each side's net best ball → hole won/halved. Match state is the
classic ladder: n-up / all square, **dormie** flagged, match **closes out**
early when up > holes remaining; remaining holes still scorable for the
round itself (rounds are facts; the game just stops caring).
- Status line lives on the live round screen and (⚑ option) posts milestone
  updates to the league board if all players share a league ("Marcus & Trey
  3UP thru 12").

### 2.4 Stakes
- v1: flat dollar stake per side, declared at tee-off, recorded in the game
  config. Result → single ledger entry winner/loser. Push = no money.
- Roadmap (spec): nassau (front/back/overall), presses, skins.

### 2.5 The async cousin: the Duel
When players are NOT on the course together there is no hole data — the
async equivalent is the **duel**: best PvI in a window wins. This is not a
tee-sheet game; it's the atom of The Ryder (§4) and future h2h side pots.
One definition, reused: `duel(window, playerA, playerB) → A|B|halve` with
"best posted round's PvI in window" as the comparator, no-post rules per
container.

---

## 3. Wolf (live side game — tee sheet) — turn tracking + pot

Spec §13.2 fixes v1 scoring: **rotating wolf, partner ±1 / lone +3/−3,
dollar value at tee-off, netted ledger.** Full design:

### 3.1 Setup (at tee-off)
- Exactly 4 players (members and/or guests). ⚑ 3-player variant ("pig")
  deferred.
- Wolf order: random shuffle at game start (or manual arrange), locked.
- Dollar value per point set at tee-off (can be $0 = bragging points).
- ⚑ Toggles (v1 defaults in bold): **carries off** / carries on (pushed hole
  value rolls forward) · **blind wolf off** / on (declare lone before any
  tee shot, ±6) · handicaps **on** (net, strokes as §2.2) / gross.

### 3.2 Turn tracking (the state machine)
This is the piece the app must own — Wolf dies in real life because nobody
remembers whose turn it is by hole 7.

```
wolf(hole) = order[(hole − 1) mod 4]              holes 1–16
wolf(17), wolf(18) = current LAST PLACE in the ledger (comeback rule) ⚑
                     (alt: continue rotation — league of the game decides
                      at setup; default comeback)
```

Tee order each hole = rotation shifted so the wolf tees LAST (wolf watches
every drive). Phase machine per hole:

```
TEE_WATCH: opponents drive in order. After EACH drive the app prompts the
           wolf: [Take <name>] or [Pass]. A pass is irrevocable — you
           cannot come back to an earlier driver.
           - Take after drive i → PARTNERED (wolf+i vs other two)
           - Pass all three → LONE_WOLF (auto-declared)
           - (blind toggle: BLIND may be declared before any drive, ±6)
SCORE:     hole played out; net best ball per side entered via live scoring.
SETTLE:    hole result → ledger deltas:
           - Partnered win:  wolf +1, partner +1, losers −1 each
           - Partnered loss: wolf −1, partner −1, winners +1 each
           - Lone win:  wolf +3, others −1 each        (net-zero: +3/−3 total)
           - Lone loss: wolf −3, others +1 each
           - Halve: 0 (or carry if enabled ⚑)
```

⚑ Net-zero check: spec says "+3/−3"; the table above reads it as wolf ±3
against the field ∓1 each so every hole sums to zero and the ledger settles
cleanly. Confirm this reading before build.

The app's job at each moment: a banner that says **whose turn it is and
what they're deciding** — "You're the Wolf. Danny just striped one.
[Take Danny] [Pass]" — pushed to the wolf's phone at hole start.

### 3.3 Pot tracking
- Running ledger, always visible: per-player net points × $ value = live
  cash position ("Trey +$14 · Marcus −$6 …"). Sum is always $0.
- Hole-by-hole receipt behind every number (§16 house rule applies to side
  games too).
- Finish → **settlement card**: minimized transfer set ("Marcus pays Trey
  $6, pays Cole $4"), posted in the recap. Nothing held, Venmo moves.
- Guest recap text includes their line + claim link (spec §13.3 — the
  funnel).
- ⚑ Optional loss cap per player set at tee-off (family-friendly dial).

### 3.4 Data model sketch
Existing: `live_rounds`, `live_round_players` (nullable member + guest
fields), `round_holes`, `games`, `game_results` (spec §13.5).
Wolf needs: `games.config` jsonb (order, $/pt, toggles) ·
`games.state` jsonb (current hole, phase, decisions log) ·
`game_ledger` (game_id, player_id, hole, delta_points) — or fold ledger
into game_results rows per hole. ⚑ Decide flat table vs jsonb log; flat
table preferred for receipts.

---

## 4. The Ryder (standalone event, longer period)

Decided 2026-07-11 (memory: ryder-mode-design): **standalone** (any crew,
no league required — the off-season product), **two teams of any sizes**,
**captains pick**, **N weekly sessions of net-diff duels**. Extended design:

### 4.1 Container
- Event: name, 2 teams (names + colors), start Sunday, **1–6 weekly
  sessions** (default 3), organizer = "the Pro" of the event.
- Roster: invite by handle/buddies/invite link. Captains chosen at setup.
- **Captains pick** teams schoolyard-style, alternating, each pick posted
  to the event board. (Alt formation: organizer assign / blind draw — reuse
  the league machinery, but captains-pick is the Ryder default.)

### 4.2 The week = a session
Each session is a slate of **duels** (§2.5): you vs your assigned opponent,
best posted round's PvI inside the session window wins the point.

- Win 1 · halve ½ · loss 0. Team with most points when sessions end takes
  the cup. Clinch/magic number shown as it develops.
- **Pairings:** captains submit ordered lineups by the session deadline
  (blind, simultaneous — like real Ryder envelopes); list positions pair
  off. ⚑ Default deadline: Saturday midnight before the session week.
- **Uneven teams:** pairing count = smaller roster; captain of the larger
  team benches the surplus each session (rotation nudged by the app —
  "Cole has sat twice"). Everyone benched can still post rounds (they just
  don't score).
- **No round posted in the window:** opponent wins the duel 1–0; BOTH
  idle → halve–halve (½ each). ⚑ Alternative: both idle = 0–0 (deletes the
  point — harsher). Default: halve.
- Multiple rounds in the window: best PvI counts automatically.

### 4.3 Session type variants (schedule texture over the longer period)
| Type | Unit | Comparator | Needs |
|---|---|---|---|
| **Singles** (v1 default, every session) | 1v1 | best PvI in window | nothing new |
| **Fourball pairs** (v1.1 ⚑) | 2v2 | better of the pair's best PvIs | pairing UI only |
| **Live Day finale** (v1.1 ⚑) | on-course | real match play (§2) on a scheduled day | live rounds + scheduling |

Classic 3-week shape: W1 fourball, W2 singles, W3 singles at double value.
⚑ Session weighting (final week ×2) — off by default, dial exists.

### 4.4 Pot & awards
- Buy-in per player tracked (reuse buy_ins pattern, event-scoped). Default
  payout: winning team splits evenly. ⚑ Options: MVP cut (best duel
  record, tiebreak total PvI), captains' side wager line.
- Tracked, never held — settlement card at the end, same as everywhere.

### 4.5 Event board & drama
- Every duel result posts as it lands ("W2: Jerecho def. Marcus, +2.1 vs
  −0.4"), pairings post at session open, captains' picks post at draft.
  Push notifications ride the existing rails (posts webhook — event posts
  need an event_id home, see 4.6).
- Running scoreboard is the event home: team totals, session strips,
  per-duel chips (won/lost/halved/pending), who hasn't posted yet with
  days remaining — the nag surface.

### 4.6 Schema direction ⚑ (the big open decision)
Two candidate shapes:
1. **events as first-class**: `events`, `event_teams`, `event_players`,
   `event_sessions`, `event_duels` (+ result, round_id receipts); posts
   gain nullable `event_id` (board + push reuse). Clean, additive, matches
   spec §17's "cross-league event entity" prophecy.
2. **Overload leagues** with `kind='event'`: reuses membership/board/pot
   wholesale but pollutes league semantics (seasons, floors, caps all
   meaningless here).
Leaning **option 1** — spec §17 already reserved this ground. Needs its own
requirement doc before migration.

### 4.7 What The Ryder is NOT (v1)
No hole-by-hole team match play across cities, no live cross-course sync,
no GHIN requirement. It's posted-rounds PvI duels with team drama on top —
shippable on existing round machinery + one new schema arc.

---

## 5. Cross-cutting rules

- **Nothing touches cup points** except league season scoring itself. Side
  games and events are parallel ledgers.
- **Receipts everywhere** (§16): every duel/hole/ledger line traces to the
  round(s) or hole entries that produced it.
- **Guests** exist in live games only (name + index, claim-link recap);
  events require accounts (duels need posted rounds).
- **Money**: every mode's pot is tracked-never-held; every mode ends in a
  settlement card shaped for screenshots.

## 6. Build-order implication (matches the task board)

1. Wizard rebuild + pot step (league pot UI — §1.4)
2. Tee sheet organize flow → **Match Play** (§2) then **Wolf** (§3), both on
   live-rounds machinery (course cards land here too)
3. **The Ryder** (§4) — needs the events schema decision (⚑ 4.6) and its own
   requirement doc
4. Alternate season engines (Quota) unlock free once live rounds capture
   hole detail (spec §2.5)

---

## 7. Requirements-session decisions (2026-07-12) — promoted to canon

These supersede conflicting lines above and in spec-v1.0; fold into v1.1.

1. **Cadence:** monthly engine (caps/floors/H2H unchanged), **weekly
   moments** — the events engine crowns weekly winners and writes
   "won Week 4" headlines off the week snapshots. No competition-window
   migration.
2. **Squad formation scales with roster size** (supersedes §15's flat
   menu). Always available: Pro assign, blind draw. **Captains pick**
   unlocks when the Pro names N captains (the Ryder mechanic, generalized —
   right-sized for small leagues and two-team events). **Snake draft**
   surfaces only for rosters ~12+ (m004 schema ready; async picks, each
   posted to the board; no pick clock at launch). The wizard offers what
   fits the roster instead of a format menu.
3. **The endgame is a bylaw dial:** `finish = points_table | cup_final`.
   A season may crown the points champion outright, or build to the
   final-4-weeks Cup Final (§14.3) if the Pro configures it. Migration 008
   must implement the dial, not assume the Final. (Semifinal brackets:
   rejected for now.)
4. **Rounds post instantly** — no approval gate. "Round approved" in the
   vision doc maps to **attestation** (a buddy vouches → ping), not a Pro
   queue.
5. **Hole-by-hole is the default posting UI, not required** (stepper on
   par; gross-only escape hatch flagged "no hole detail"). Course cards
   arc pulled forward.
6. **Monetization: one general membership.** Verified tier dead; GHIN is
   an optional reference field on the card. Multi-season history is no
   longer a paid gate.
7. **Profile: photo optional** (marker fallback), GHIN optional.
8. **Events engine is the next major arc** — snapshots, deep stats, lead
   changes, milestones, weekly winners, lifetime rivalry records, curated
   notifications (replacing all-posts push).
