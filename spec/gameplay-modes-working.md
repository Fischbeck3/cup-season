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
Points Race only (D48 retired B/H2H and C/Hybrid). Endgame stays the bylaw
dial: points_table | cup_final.
**Cup Final:** final 4 weeks, seeds lock at `ends_on − 27`, scored fresh
under the league's own counting rules. Tiebreak ladder: h2h months won →
best single month → fewest rounds used → logged coin flip. (Migration 008 —
still to build.)
Individual layer always on: Points King ($ from pot), Most Improved, Iron Man.

### 1.4 Pot (season)
Buy-ins tracked in `buy_ins`, payout split bylaw exists (m006: default
60/25/15 champs/runner-up/points king, must sum 100). Pot is **a
ledger (D39)** — settlement is a card, money moves on Venmo.
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
- Exactly 4 players (members and/or guests). **3-player variant ("pig") is
  HARD-CUT from v1** (decision-log D16): no greyed option, no mention — the
  tee-off validation requires exactly 4, and a 3-ball takes Skins or Just
  score. Revive only when a real 3-ball asks; until then the deferral is
  invisible, not a broken button.
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
- On the books (D39 ledger canon) — settlement card at the end, same as
  everywhere.

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

### 7b. Flag resolutions, batch 2 (2026-07-12)

9. **Events are first-class schema** (not overloaded leagues): `events`,
   `event_teams`, `event_players`, `event_sessions`, `event_duels`, plus
   nullable `posts.event_id` so the board and push rails serve events
   natively. The Ryder requirement doc builds on this.
10. **Wolf kit confirmed as v1 defaults:** net-zero ledger (lone ±3 vs
    field ∓1 each; partnered ±1 each), holes 17–18 wolf = current last
    place (comeback rule), carries OFF, blind wolf OFF. All later toggles.
11. **Ryder session defaults confirmed:** both idle = halve (½ each);
    lineups blind + simultaneous, due Saturday midnight before the session
    week; session weighting off by default (dial exists).
12. **Hybrid +15 does NOT pay in partial edge months** — consistent with
    the floor waiver; weekly moments still celebrate stub weeks. (Closes
    spec §14.0's open question for v1.1.)
13. **Event↔league linkage = B (2026-07-13):** events carry a nullable
    `league_id` — attach to a league (borrow crew + board) or stand alone.
    Always a parallel ledger (never cup points); attach needs league
    membership; `on delete set null`. Entry IA: clubhouse forks **Start a
    League · Start an Event · Join**, peer containers; plus "Run a Ryder with
    this crew" inside a league. See `ryder-v1.md` §R2.6.

Implementer defaults (engineering-level, changeable cheaply):
- Course handicap v1 = round(Index × Slope ÷ 113); rating−par adjustment
  deferred.
- Side-game ledger = flat `game_ledger` table (receipts-friendly), not a
  jsonb log.
- Match-play milestone posts to the league board: ON when all players share
  the league ("feels alive" principle), OFF otherwise.
- Wolf per-player loss cap: deferred to a later toggle, not v1.
- Ryder MVP pot cut: exists as a dial, OFF by default (winning team splits
  evenly).

---

## 7c. Flag resolutions, batch 3 (2026-07-15) — recording dynamics

Batches 1–2 settled the *rules* of each mode. This batch settles the
*recording* — the act of capturing a game and what a capture feeds. Every
item below was argued against its own steelman before landing; the
"landed on" line is the decision, the "argued past" line is why the obvious
version was wrong, kept so nobody reopens it cold. Items 14–15 are **canon**
(promote to spec v1.1). Items 16–18 are **requirement-doc constraints** —
binding on the tee-sheet (§2–§3), Ryder (§4), and events-engine arcs, not
schema-ready yet. Item 19 is a stepper-build acceptance test.

14. **A finished live round IS the posted round — one entry, many
    consumers.** Completing a live game (Match Play, Wolf) writes hole
    detail to `round_holes`, and that same round feeds the season, the
    match/game ledger, the rivalry record, and the handicap. There is never
    a second entry. *Gated, not automatic:* finish → one confirm
    ("Post this round? [Post / Casual — don't post]"), default Post. Casual
    is the escape hatch for closed-out/picked-up/mulligan games that
    shouldn't touch the season or index. *Per-player, not per-game:* your
    round posts only if **your** card is complete and **you** confirm — a
    partner whose ball stopped mattering mid-hole (team formats) has gaps
    and isn't force-posted; guests never post (no account, §13.3).
    - *Argued past:* "auto-post everything" pollutes the season with casual
      games — true, which is why the confirm gate and per-player
      completeness rule exist rather than dropping the principle. The double
      entry itself is the Principle-2 violation to kill; the gate is the one
      tap that survives.

15. **Co-play generates "played with" automatically; attestation stays a
    deliberate tap.** Two tiers, not one. Sharing a live round auto-writes a
    **played-with** fact (free — feeds rivalry records §18, feed copy
    "with Danny O & Cole W", the with-line already on declared rounds). It
    does NOT auto-attest. **Attestation remains an explicit vouch**, but
    co-players are **prompted** for it ("You played with Jerecho — vouch for
    the 84?"), killing the cold-start without diluting the act. This
    supersedes decision #4's implication that co-play and attestation are
    unrelated systems.
    - *Argued past:* "attested by existing" (presence = vouching) — too
      strong; it makes the padding foursome self-verify and empties the word
      "attested." Anti-sandbagging was never attestation's job (the 12-point
      ceiling, §1.1, is). Attestation is a *social* signal, so it keeps its
      deliberate tap; only the played-with *fact* is automatic.

16. **Every live-game state must be enterable after the fact — the phase
    machine is a prompt engine, not a lock.** (Constraint on §2–§3.) The
    Wolf/Match state machines (§2.3, §3.2) are the happy path for a phone
    that's out every tee; real groups fall behind. So the flow that decides
    whether the mode survives is **catch-up**: reconstruct a missed hole in
    a few taps ("hole 8: Danny wolf, went lone, lost"), undo included. No
    live-game state may be reachable ONLY through the real-time prompt.
    Corollary: irrevocable-pass (§3.2) is enforceable live, advisory on
    backfill. Corollary: **one designated scorekeeper phone is the v1
    primary model**; everyone's-phone live sync is v2. Write this as a
    design constraint in the tee-sheet requirement doc before the state
    machine is built rigid — retrofit is expensive.
    - *Argued past:* "backfill corrodes the whole pitch (the app forgets
      too)" — real, but a happy-path-only design doesn't force compliance,
      it forces mid-game abandonment, which teaches "doesn't work on a real
      course." Recovery is the feature surviving contact, not failing.

17. **The async duel surfaces a target, and the target push is opt-in.**
    (Constraint on §4.) The moment an opponent posts inside the session
    window, the duel has a number to beat — show it on the duel chip
    unconditionally ("Marcus posted +1.2 · you have until Sunday"), the
    prospectus' one-more-round rule as a game mechanic. The *notification*
    of it is **per-user opt-in** (Principle: "only meaningful ones, no
    spam" — a standing taunt must be chosen). Timing becomes strategy (set
    the pace vs. hold your card, echoing the blind-lineup logic §4.2); that
    tension is a feature of the weekly cadence, not a bug to design out.
    - *Argued past:* "posting first hands your opponent a target, so
      everyone sandbags timing to Saturday night" — the timing meta is good
      drama, not a leak; and the pressure/tone risk is a copy + opt-in
      problem, not a reason to hide the scoreboard.

18. **One rivalry object per pair, faceted — never a single blended
    W-L number.** (Constraint on events-engine, task #5 — schema decision,
    urgent.) Match Play, Wolf, and Ryder duels are parallel *points*
    ledgers (§5 unchanged) but must all write to **one rivalry record per
    pair** so history converges: header "Jerecho vs Marcus — 12 meetings,"
    faceted "match play 2–1 · duels 3–2 · 7 Wolf nights." Every mode feeds
    the same object; **no single number** pretends a 1v3 Wolf hole equals a
    singles match. The events engine must land rivalries on this shape now —
    if it ships duels-only, folding side games in later is a painful
    retrofit. This makes decision-#8's "lifetime rivalry records" concrete.
    - *Argued past:* "blend it all into 7–4 lifetime" — the records aren't
      commensurable and golfers know it; a blended number starts a bar
      argument it can't settle (Principle 4: the memory must be *true*). The
      faceted object keeps every meeting without the fake aggregate.

19. **The declared round is the tee sheet's parent — prefill flows forward,
    one direction only.** (Constraint on task #11.) On a declared day, the
    round on the books offers "Tee off — start a live round," carrying
    course, tee time, and tagged group as **editable defaults** (all four
    now captured, v23.135). The continuum is one object's lifecycle:
    plan (calendar) → tee off (+ pick a game: Wolf, Match Play) → post →
    points. The tee sheet is ALSO spawnable from nothing (four on the first
    tee, nobody declared) — so the declared round is *a* parent, never the
    *required* one, and plan data never constrains the game (facts flow
    plan→game, never back). Do not build a second scheduling front door;
    that recreates the "two home tabs" redundancy one layer down.
    - *Argued past:* "planned and played are different objects, welding them
      risks stale foursome-of-record" — only if prefill were bidirectional
      or mandatory; one-directional editable defaults have no such downside.

Two copy/craft notes (not decisions — build guidance):
- **Don't badge the gross-only escape hatch punitively.** "No hole detail"
  reads as a scarlet letter. Make the hole-by-hole stepper fast enough
  (par-prefilled, adjust only deviations — decision #5) that the hatch is
  rarely wanted, rather than flagging the golfers who take it.
- **The 60-second post is an acceptance test, not an aspiration.** The
  success metric (post a round in under 60 seconds) is a stated pass/fail
  gate on the stepper build, measured, not a hope.

---

## 8. The personal stake line (PARKED — designed, not decided, not built)

Designed in the Gameplay lane 2026-07-17; parked when the lane closed. Nothing
built, no decision-log entry drafted — three ⚑ questions below must be answered
before this becomes a D-entry. Captured here so the reasoning is not lost.

**The idea:** one line telling a golfer what their next round is actually worth.

**The trap that makes this a mechanic, not a copy line:** the obvious version —
"a great round today is worth up to 12!" — is a *lie* for much of the league most
months. The counting cap (best 4/month, default) means once you are at cap your
next round only counts if it displaces your worst counting round.

| Your state this month | What the next round is actually worth |
|---|---|
| Short of the floor | its points (5–12) **plus** killing the penalty (−5/round short, Standard) — up to a **17-point swing** |
| Below cap, floor met | **5–12**, never less than 5 |
| At cap, worst counting = 6 | **0–6** — only the part above the 6 |
| At cap, worst counting = 12 | **exactly 0** to the table |

Two spec facts make it sharp: a posted round **never scores zero** (worst band is
5 — "a posted 98 beats an unposted 82"), and displacement is **real-time** (§3.1).
So the honest marginal value is `max(0, 12 − your worst counting round)` —
computable client-side today from `window.myMonth` + `indRows[].hist`. No engine,
no migration.

**Inherited honesty rule (from D24):** never claim a resulting position — other
people post too.
- ✅ "8 back of the cup line — one top-band round closes it."
- ❌ "A 10 today puts you 2nd." (assumes nobody else plays; false by dinner)

**Priority ladder (one line wins):**
1. **Floor at risk** — short, month closing. Highest stakes, time-boxed.
2. **Index not established** (<3 rounds) — "two more and your number is real."
3. **At cap** — the honest marginal: "your best four are banked."
4. **Cup-line / rival stake** — only when closable in one round (gap ≤ 12).
5. **Below cap, nothing urgent** — "even a rough day banks 5."
6. Otherwise **quiet** — hides rather than babbles, same discipline as D24's
   scenario line.

**Settled while designing:**
- **Role-blind.** The Pro is also a player; their round has identical math.
  A Pro-shaped *league-health* line ("3 players are short with 5 days left") is
  real but is its **own deferred entry** — and it brushes D23 (nudge policy,
  Social's fence), so it needs coordination, not assumption.
- **Explain by receipt, not tooltip.** The line taps through to the month's slot
  meter (D3's best-four fill) — §16, and already built.
- **Never say "counting cap."** Say "your best four" (D2, no jargon).
- **The new-user fear self-solves:** you cannot be at cap and be new — four
  counting rounds means the floor is met twice over. A new golfer gets line #2,
  which is welcoming. *Caveat:* a **Best 2** league can put a two-rounds-in
  player at cap, so the at-cap tone must reframe, never deflate.

**⚑ Open — answer these before drafting the D-entry:**
1. **⚑ Show the at-cap-zero line at all?** It honestly tells a golfer their round
   does not count — fighting "every round counts" and the one-more-round rule.
   This is the one place the feature could actively suppress play. *Proposed
   resolution (Memory > Statistics):* the round still counts for the **index**,
   the **Iron Man** count, the **board**, and a possible **moment** — so the line
   reframes rather than deflates: "your four slots are full — today's round is
   for your number and the Iron Man, not the table." Values call, not a math one.
2. **⚑ Where does it live** — Home, the post-a-round screen, or both? Trigger
   logic + math are Gameplay's; **placement is UX's**.
   **✓ ANSWERED (UX lane, 2026-07-17): the post-a-round screen.** Home is the
   reveal surface (#5) — a "what your next round is worth" line there speaks on
   days the golfer isn't playing and is wallpaper by week three (the exact ⚑3
   failure). On the post screen the golfer is present *because they played*; the
   line lands where it's actionable. **Carve-out, deliberately NOT taken:** the
   priority-1 case (floor at risk) is a "go play" message, and a floor-short
   golfer is by definition not visiting the post screen — the one golfer who
   most needs the line never sees it there. Surfacing that case on Home is the
   honest fix, but a time-boxed "short with 5 days left" on Home is a nudge →
   D23 (Social's fence) + a Jerecho call, not a UX placement decision. So: ⚑2
   is settled for priorities 2–5; the floor-at-risk Home surface rides with ⚑1
   to Jerecho and coordinates with Social if approved.
3. **⚑ Should it ever be silent?** Lean yes — a line that speaks daily becomes
   wallpaper and stops meaning anything.

**Implementation note:** `floor_penalty` is **not** hydrated client-side (only
`state.preset`, which the client *couples* to it on write). Read `b.floor_penalty`
directly — inferring from the preset misstates the stake for any league whose
penalty diverged from it.

---

## 9. Parked idea: earned markers (from the Social lane, 2026-07-17)

One line, captured at lane close: ball markers could be *earned*, not just
picked — break 80 → unlock The Jug, first Ryder win → The Thistle. The Social
lane flagged it as a real retention hook and correctly stopped at the boundary:
unlockables are a mechanic (achievement rules, visibility, whether picked-vs-
earned markers read differently), so it gets a decision-log entry before any
build. Not designed, not committed to — just not lost.

---

## 10. The Major (standalone championship — days, the field, one jug)

Decided 2026-07-20 with the owner (decision-log **D42–D46**; this section pays
the IA's Major IOU). A **standalone championship event** on the events spine
(`kind='major'`), league-attachable like the Ryder, always a parallel ledger
(§5 — never cup points). The product line spreads by time-grain: the Season is
months (squads) · the Ryder is weeks (teams) · **the Major is a weekend (the
field)**. The pitch: one weekend, every card on one board, one name on the jug.

### 10.1 Container & window

- Event: a name worth engraving (the crew names the jug — "The PIGL
  Championship"), organizer = the Pro of the event, optional league attach
  (borrow crew + board). Teams: none — `event_teams` sits empty for majors.
- **Window:** organizer picks the **final day** (any weekday; wizard defaults
  the next Sunday) and **length 2–4 days** (default 4 = Thu→Sun, real-major
  grammar). ONE `event_sessions` row IS the window (`opens_on = final_on −
  days + 1`, `closes_on = final_on`); the daily tick opens and settles it
  (§R12.3 rails; tz per §R12.2: league season > creator device > Phoenix).
- **Field:** invite via the existing picker; **late entry until the horn** (a
  Saturday joiner with a Sunday card is legal; entries post to the board).
  Auto-open needs ≥2 entered (the Ryder's both-benches rule, translated).
  The organizer plays like anyone.

### 10.2 Scoring — your best card, vs your number (D43)

- **Best eligible card in the window is your score.** Unlimited attempts; every
  attempt also lives its normal season/index life (rounds are facts).
- Eligible: **18-hole cards only** (a 9 still feeds season + index; the Major
  is the full test — dial later if a twilight crew asks), never voided, never
  sim. PvI at 100% allowance off `index_at_post` — a frozen-at-entry index was
  rejected (forks the one currency, muddies receipts).
- **No band ceiling.** The round of your life pays in full; the ringer vector
  closes at the field line (10.4), not by muting the heater. Revisit trigger:
  the first suspicious win.
- Leaderboard grammar: **"JERECHO 82 · −4.2"** — gross is the story,
  vs-your-number is the ranking; named bands stay the per-card voice (D1/D2).
  Every figure taps to its card (§16). Build note: the live board REQUIRES a
  security-definer read — rounds RLS is owner-only (`event_session_targets`
  precedent).
- **NO CARD** = an honest unranked row at the foot; no synthetic penalty
  number. A no-card buy-in settles as a donation, visible on the card.

### 10.3 The window tells its story (server posts, existing rails)

Open post at the tick ("THE PIGL CHAMPIONSHIP IS LIVE — CARDS IN BY SUNDAY
NIGHT") · every card / clubhouse-lead change posts to the event board
("JERECHO CARDS 82 — CLUBHOUSE LEADER AT −4.2") · **a round booked during the
window posts the chase** ("MARCUS BOOKED SATURDAY — CHASING −4.2" — the
owner's hype beat, riding `scheduled_rounds`) · a final-day-morning stakes
post via the daily tick · settle on the tick after the horn (organizer manual
settle stays as override). Push: stories ride the existing curated webhook;
**no new opt-in nudge class** in v1 (`notify_target` is duel-shaped; a Major
has no assigned opponent — deferred until a real ask).

### 10.4 The field line — two tiers, one leaderboard (D44)

- **Established (engine-derived) index at entry → contends** for title + pot.
  The un-established join anyway, appear on the board **flagged exhibition** —
  name in lights, can't win title or money, official by the next Major. The
  claimed guest plays THIS Major; the conversion hook is the flag itself.
- Checked ONCE at add-time against the handicap engine's own established
  definition (never a parallel count). Establishing mid-window still finishes
  exhibition — a card that rode a starter number must not contend for money.

### 10.5 Ties — the countback ladder, best-card edition (D45)

Tied best card → **better second-best card** (the deeper weekend wins; any
second card beats none — playing more is the covenant's value) →
**earliest-posted best card** (they set the number) → **logged coin flip**
(§14.3 precedent, receipts attached). Applies to every paying place. Stated in
the fine print at create — chosen, not discovered. Playoff window = the
fast-follow when a real tie earns it; shared titles rejected.

### 10.6 Ceremony & pot (D46)

- **Champion-only hardware:** one `trophies` row (kind 'major', title = the
  event's name); the case stays scarce — the jug engraves one name. Runner-up
  lives in the recap + settlement post, never the case.
- Champion story posts to the event board and — when attached — the league
  board. **Share-ready recap card** at settle (D30 canvas pattern: champion +
  marker, event name, final top-3, gross + vs-number, date, wordmark) carrying
  the join path (GTM §3 rule).
- Pot: D39 ledger posture. Buy-in at create, **$0 bragging rights first-class
  and default**; paying places default **60/25/15** (the season's own split)
  with a winner-take-all preset; no custom-% editor (D8). Exhibition never
  pays.
- **Earned champion's marker:** §9's perfect candidate — flagged, own decision
  entry when unparked, nothing built silently.

### 10.7 Schema direction (additive; the Ryder rails, not a fork)

```
events            kind='major' (no CHECK to alter); window rides the one
                  session row; + buy_in numeric default 0,
                  + pot_split text 'places'|'wta'
event_players     + exhibition boolean not null default false (set at add)
event_major_cards (event_id, player_id→event_players, round_id→rounds (the
                  §16 receipt), gross, pvi, rank, prize, resolved_at) —
                  frozen at settle; the live board is a definer fn
tick              run_event_sessions branches on kind: majors skip
                  generate_pairings → open_major (board post) / settle_major
                  (ladder, prizes, stories, complete → trophies trigger,
                  kind-aware: award branches 'ryder'/'major')
RPCs              create_major(name, final_on, days, buy_in, split, league?,
                  tz?) · add_event_player gains the exhibition check for
                  majors · major_leaderboard(event) definer read ·
                  settle_major — engine paths cron-drivable (auth.uid() null),
                  human callers organizer-gated, same as resolve_session
posts             existing event_id rail; an attached Major's completion post
                  carries BOTH league_id + event_id (posts_home_check allows)
```

D37 law: every new client-called RPC ships its explicit
`grant execute … to authenticated`; engine-only fns stay revoked from API
roles (`run_event_sessions` precedent). Edge cases decided here: settled cards
never retro-flip on a later void (§R10 mirror; the organizer's recourse is the
log) · a zero-card Major completes with a no-champion story and the pot
returned on the settlement card · organizer deletion → provenance rule (§R10)
· deploy-skew: the client try/catches the new RPCs so old client + new DB and
the reverse both live.

### 10.8 Not in v1

Playoff windows · runner-up hardware (a placement dial later) · the
order-of-merit circuit · a 9-hole dial · attempt caps · custom pot % · new
push classes · earned markers (parked, §9) · season adoption — the D42 port
stays a named door (`season_adjustments` at settle, never `cup_points()`).

**⚑ none open** — all flags resolved with the owner 2026-07-20. The window
shape was the owner's redirect (days, not weeks; the compressed-window hype
loop) — recorded in D43.

### 10.9 Parked: the annual Major (owner insight, 2026-07-20, day of the build)

Majors anchor to the **crew's own calendar**, not the pro tour's — "the annual
Thanksgiving Major," "the New Year's tee-off," the trip week. Stronger than
Masters-week tie-ins because the date already belongs to the crew. **V1 already
serves it by convention:** create by the same jug name each year (any final
day, 2–4 days), `trophies.season_year` stamps the lineage, the case reads
"The Thanksgiving Major · 2026 / 2027 / …" with zero build. **The lineage
build is its own decision entry before anything ships:** defending champion
named in the announce, an "Nth annual" counter, a champions roll on the event
page, one-tap rematch with bylaws carried (the event analog of D41's
run-it-back — D41 explicitly deferred "the event rematch row"), and any
anticipation nudge rides D23's fence. Not designed, not committed — captured.
