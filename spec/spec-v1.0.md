# Cup Season — Competition Model & Monetization Spec v1.0

Season-long fantasy golf for real friend groups. Captains draft squads, everyone posts real rounds wherever they play, points accumulate all season, a cup settles it. This document defines every rule and parameter in the competition system, what the commissioner can select, and how the three presets map onto the dials.

**Design principles the whole model serves:**

1. **Every posted round scores.** The floor exists so nobody ghosts in July.
2. **Steady bogey golf can win.** Handicapped scoring means the 22-index matters as much as the 6.
3. **Volume can't buy the cup.** Counting caps keep the guy who plays daily from ending the race in April.
4. **Set it once, argue never.** All rules lock at first tee. Mid-season disputes go to the commissioner override log, not the group chat.

*(NOTE: this file is the working copy checked into the repo. The full v1.0 text
was authored in the design chats; sections below are complete as pasted at repo
creation. §14.0 amendment supersedes §14.1/§14.3 where they conflict — spec
v1.1 should reconcile the prose; the hybrid +15 question closed with D206,
which retired hybrid from the engine. Amendments since are inline italic
parentheticals citing their D-number; the decided line is never rewritten.)*

---

## 1. The pipeline

Every league, regardless of settings, runs the same five-stage pipeline:

```
POST a round → SCORE it (points) → COUNT it (monthly caps/floors)
      → RANK squads (season format) → CROWN a champion (the Cup)
```

Each stage has parameters. The presets (Casual / Standard / Cutthroat) are bundles of parameter values; **Custom** exposes every dial individually.

---

## 2. Scoring engine — round → points

### 2.1 Core formulas

```
Differential        = (Adjusted Gross − Course Rating) × 113 ÷ Slope
Playing Index       = Index × Handicap Allowance %
Performance vs Index (PvI) = Playing Index − Differential
```

PvI is the universal currency: positive = you beat your number, negative = you didn't. A +2.0 PvI means the same thing for a 6-index and a 24-index.

### 2.2 Points bands (default engine)

| Performance vs Index | Cup points | Read |
|---|---|---|
| +3.0 or better | **12** | Torched it |
| +1.0 to +2.9 | **9** | Beat your number |
| −0.9 to +0.9 | **7** | Played to your index |
| −3.0 to −1.0 | **6** | A little loose |
| Worse than −3.0 | **5** | Rough day, posted anyway |

Why bands instead of continuous points: the **12-point ceiling is the anti-sandbagging feature.** A padded index can only ever buy you the top band — a career round is worth 12 whether you beat your number by 4 or by 14. Continuous scoring would make index manipulation pay linearly; bands cap the payoff.

Why a 5-point floor: a posted 98 beats an unposted 82. The floor converts "I played terribly" from a reason to hide into 5 team points, which is what keeps feeds alive in the dog days.

### 2.3 Bonus layer (optional, off by default)

| Bonus | Points | Verification note |
|---|---|---|
| Birdie or better (per hole, max 3/round) | +1 | Honor or attested |
| Net eagle on any hole | +2 | Attested |
| Personal-best differential of season | +2 | Automatic |

Bonuses add texture for casual leagues but widen the sandbag surface; Cutthroat leagues should leave them off.

*(D48, 2026-07-21: retired — see decision log. v1.1 removes this section.)*

### 2.4 Round eligibility toggles

| Toggle | Options | Notes |
|---|---|---|
| 9-hole rounds | Off / Half-value | Half-value: points ÷ 2 (round up), counts 0.5 toward floors |
| Simulator rounds | Off / On | On is recommended for leagues with winter or sim access; sim rounds are flagged in the feed |
| Course requirement | Any / Rated courses only | "Any" allows unrated munis and executive courses at honor-system rating |
| Tee requirement | Any / Rated tees only | Cutthroat locks to rated tees |

### 2.5 Alternate engines (roadmap, v2+)

- **Quota (Stableford vs personal quota):** quota = 36 − course handicap; points = Stableford total − quota. Requires hole-by-hole entry — which Live Rounds (§13) capture natively, so this engine unlocks with no new data plumbing. Most golf-native.
- **Net Medal months:** lowest net rounds of the month score placement points (10/8/6/4/2). Simple, but only the top of the table earns — violates principle #1, so it's a side-pot format, not a core engine.

---

## 3. Counting rules — the two monthly dials

The window is the **calendar month**. Two independent parameters:

### 3.1 Counting cap — "best N rounds per month count"

| Setting | Effect | Suits |
|---|---|---|
| Unlimited | Every round's points count | Casual play-more-win-more |
| Best 6 | High cap, mild equalizer | Active groups, retiree-heavy |
| Best 4 | Roughly weekly cadence | Active groups *(was the default until D142)* |
| **Best 3** *(default, D142)* | A good round matters; a missed week is survivable | Most leagues |
| Best 2 | Strong equalizer | Busy-season leagues |

All posted rounds are always visible and count toward floors/stats; only the best N by points feed the squad total. A newly posted better round **displaces** the worst counting round in real time.

*(D142/D149, 2026-08-30: the ladder is Best 2 / Best 3 / Best 4 / Best 6 / Unlimited and the default is **Best 3** — the cap is the quality dial, and at 4 the marginal round was already worthless to a regular. Standard = 3, Cutthroat = 2, Casual = Unlimited. Built: migration `20260830180000`; `lock_league` defaults `p_counting_cap` to 3. D206 (2026-09-01) adds a CHECK `counting_cap between 1 and 31` — a 0 zeroes every standings row silently.)*

### 3.2 Participation floor — "minimum rounds per month"

0 / 1 / **2 (default)** / 3–4. Penalty options: **None** (Casual) · **Squad deduction** −5/round short (Standard) · **Forfeit month** — counting rounds zero out (Cutthroat). **Grace:** 1 bye month per player per season, commissioner-approved (Pro: 0–2).

### 3.3 Squad month score

```
Squad month = Σ (each member's counting-round points) − penalties
Season total = Σ (all months to date)
```

Scale check (Standard, 4-man squads): ~118 pts/squad/month, ~1,065 over 9 months. Gaps of 20–40 points are one good weekend — the race stays live.

---

## 4. Season formats — how squads compete

**Format A — Points Race** *(default)*: cumulative table, cup line under 2nd; top 2 advance to the Cup Final.
**Format B — Head-to-Head:** monthly matchups, standings by W–L (points tiebreak); top 2 records advance.
**Format C — Hybrid:** Points Race **plus** +15 squad points to each month's head-to-head winner.

**The Cup Final (all formats):** the two qualified squads go head-to-head under the league's own counting rules; higher total lifts the cup. Tiebreak: combined squad PvI for the window; then a real-world playoff round between captains.

**The individual layer (always on):** **Points King** (most individual points — pays from the pot) · **Most Improved** (largest index drop) · **Iron Man** (most posted rounds).

*(D48, 2026-07-21: Formats B and C retired — see decision log. v1.1 collapses
this section to Points Race + the endgame dial.)*

---

## 5. Handicap & fairness system

| Parameter | Options / value |
|---|---|
| Index source | App-computed (WHS-style best 8 of last 20, revised monthly on the 1st) / GHIN (required Standard+) |
| Handicap allowance | 100% / 95% / 90% |
| Max index | 30.0 |
| In-season index rise cap | +1.0 max above season-start |
| Exceptional score rule | Two rounds of PvI ≥ +7 in one month → index cut 1.0 immediately |
| New member provisional | First 3 rounds score at fixed 7 points |

*(D49, 2026-07-21: flat-7 retired — provisional rounds score normally,
badged until established. See decision log.)*

*(Unbuilt as of 2026-09-01 — leaned to in the 2026-09-01 You-and-mechanics
review behind D204–D212, which took no D-entry on it:
the **max index 30.0**, the **+1.0 in-season rise cap** and the
**exceptional-score cut** exist in this table and not in the engine.
`handicap_index_asof()` (`20260716100000`, still the only definition) takes
the best m of the last 20 differentials through the WHS adjustment table and
nothing else — no ceiling, no rise cap, no cut. D49 leans on the cut without
it existing. Strike or build is a spec-amendment decision after launch; this
note records the gap so the table stops reading as shipped.)*

---

## 6. Verification tiers

**Honor** (posts, done) · **Attested** (a playing partner taps confirm; unattested rounds score but are flagged) · **GHIN-verified** (round must exist in GHIN; launches as commissioner spot-checks, becomes the Verified League tier §11 via licensed API).

**Live Rounds make attestation automatic (§13):** a group scoring together in one live session is peer-verified by construction.

---

## 7. Stakes structure

Buy-in **$0 by default (bragging rights); $25–$200 when money's in play** *(D113, 2026-08-29. The column default moves to 0 in migration `20260901220000` (D196), whose backfill matched zero rows as written — it joins `seasons.status = 'setup'`, a value that CHECK forbids. `20260901220000` is APPLIED, so rule 2 binds it: the corrected backfill (keyed on `leagues.phase = 'setup'`) is a NEW migration, `20260902160000` §1, per D206; D206 also has `create_league` write the wizard's defaults explicitly, so a row and a wizard can never disagree again.)* · Payout split 60/25/15 (Champs/Runner-up/Points King) · optional side pots. **Track, never hold.** Money moves friend-to-friend; the ledger is the product. The pot is what the roster owes; payouts are made from what was collected (D106).

---

## 8. Preset matrix

| Parameter | Casual | Standard | Cutthroat | Custom |
|---|---|---|---|---|
| Handicap allowance | 100% | 95% | 90% | Any |
| Index source | App | GHIN | GHIN | Any |
| Verification | Honor | Attested | GHIN + attested | Any |
| Eligible rounds | Any, sim ok, 9-hole half | Rated, sim ok | Rated tees, no 9-hole | Any |
| Counting cap /mo | Unlimited | **Best 3** *(D142)* | Best 2 *(D149)* | 2/3/4/6/Unl |
| Floor /mo | 0 | **2** | 3 | 0–4 |
| Floor penalty | None | −5/short | Forfeit | Any |
| Bye months | 1 | 1 | 1 | 0–2 |
| Bonus layer | Birdie +1 | Off | Off | Any |
| Format | Points | Points | H2H | Any |
| Length | 6 mo | 9 mo | 9–12 mo | 1–12 mo *(D143/D149)* |

**Monetization mapping:** presets free; **Custom = Commissioner Pro** (§11).

**League size (graduated):** min **4 for squads · 2 for solo (D205)**. 4–5: **Individual** (top 2 duel the Final) or **2×2** (both reach the Final; leader +10). 6–7: 2×3 / 3×2. **8+: full 4-squad draft.** 10+ clears the USGA club threshold → Make It Official (§11).

*(D48, 2026-07-21: the allowance dial, bonus-layer row, and format rows of the
preset matrix are retired — presets keep their fixed values internally. See
decision log; v1.1 updates the matrix.)* *(D206, 2026-09-01: hybrid retired
from the engine as well — `season_format` defaults to `points`, unlocked rows
are updated, the `close_month` +15 branch is deleted; the CHECK keeps the
legacy value only so the two seed rows survive.)*

*(Counting cap row — D142/D149, 2026-08-30: Standard **Best 3**, Cutthroat
**Best 2**, Casual Unlimited, Custom 2/3/4/6/Unlimited; see §3.1.)*

*(Length row — D206, 2026-09-01: the default on both clients is **13 weeks /
3 months** for every preset — under ~10 weeks the calendar-month floor never
assesses (D143's own tradeoff). The CHECK is 1–12 months (widened from 3–12 in
`20260830180000`) and the dates are the truth, `season_months` only describes
them (D143/D149). The per-preset
lengths above are v1.0's suggestions, not defaults.)*

---

## 9. Edge cases & rulings

Ties: total squad PvI → h2h record → streamed coin flip. Mid-season joins until halfway (provisional scoring; floor prorates — see §14.1 15th rule). Dropouts: squad plays short or Pro waiver wire. A round belongs to the local date **played**; posts accepted 7 days after play, later needs override *(the seven-day wall is NOT enforced anywhere and never was — D122 named it an open item, D136 (Q-28) struck it as unenforced: backdated entry is legitimate (scorecard scan, guest claims, a round posted the following week) and the date field's own prominence is the control. The ruled direction (leaned to in the 2026-09-01 You-and-mechanics review behind D204–D212, under the owner's "build out your suggestions"; no D-entry of its own) is a "posted late" stamp on the card and the board story when `created_at − played_on > 7d`, with the Pro ruling (D50) — not yet built, no D-entry yet.)*. Commissioner can void/edit any round — every override logged and visible. Index revision day: the 1st, before counting.

---

## 10. Recommended beta configuration (PIGL)

Standard + **sim rounds ON** + format **Hybrid**. Best 4 / floor 2 (−5) / 9 months / Attested / $75 · 60/25/15. *(Historical — the v1.0 beta configuration as written. Hybrid is retired (D48, and D206 from the engine), the Standard cap is Best 3 (D142) and the buy-in defaults to $0 (D113/D196); a league minted today is points · Best 3 · $0 unless the Pro dials it.)*

---

## 11. Product tiers & pricing

**Players never pay to play.**

| Tier | Price | Unlocks |
|---|---|---|
| **Free** | $0 | Full season on any preset: draft, scoring, standings, feed, pot ledger |
| **Commissioner Pro** | $40/season/league | Custom dials, live draft night + clock, trades/waivers, multi-season history, custom cup branding |
| **Verified League** | $12/player/season (requires Pro) | GHIN integrity layer: index auto-sync, round verification, score push, Verified badge, full analytics |
| **Make It Official** | Included w/ Verified | Concierge league-as-real-club registration with state AGA (10+ members, commissioner as Handicap Chair) |

**Never charge for the Handicap Index itself** — the line the USGA enforced against TheGrint. Unit economics (16 players): Pro $40; Pro+Verified **$232**/league/season. GHIN-dependence is **additive by design** — app-computed index is the permanent fallback spine.

---

## 12. Competitive positioning

**vs. TheGrint:** golfer's utility (individual, per-player subs) vs league's competition engine (per-commissioner). Complementary — a Grint user's GHIN rounds can flow into a Verified league. Defensible assets: the league graph (12–16 users/acquisition), season history, commissioner lock-in, system of record for the pot.
**Squabbit** — excellent event scoring, not season-fantasy-shaped; closest feature threat. **CupTracker** — weekend product. **League software** — co-located weekly leagues, different century of UX.
The category: **fantasy sports where your foursome are the athletes.**

---

## 13. Live Rounds & Side Games

**13.1 Flow:** start live round, pull in 1–3 others (members or guests). Score hole by hole (one phone or everyone). Finish → every round posts at once, **✓ attested** by construction; hole detail powers Quota + stats. Quick-post stays the default. **Course cards:** mScorecard/golfapi.io (~43k courses; CSV into own Postgres preferred). Fallbacks: card found → stepper on par; thin → two 9-char strings (`453453543`), saved as community template forever; unknown → all par 4, corrected walking. Manual entry is the seed, not the fallback.

**13.2 Side games (v1, one per round):** **Match play** (net best ball off the low man, live status) · **Wolf** (rotating, partner ±1 / lone +3/−3, dollar value at tee-off, netted ledger). Never touch cup points; app tracks, Venmo moves, nothing held. Roadmap: nassau, skins, presses.

**13.3 Guests:** join with name + index, no account. Full side-game participants; **zero contact with the season.** Cutthroat requires a league-member witness. Finish → recap text with scorecard, winnings, claim link. **The recap is the funnel** — the highest-intent demo that exists.

**13.4 Tier placement:** Live Rounds + both v1 games ship **free** (the acquisition surface). **13.5 Schema:** live_rounds, live_round_players (nullable member, guest fields + claim_token), round_holes, games, game_results.

---

## 14. The Season Clock

### 14.0 Amendment (v1.0, DECIDED): Sunday seasons & the four-week Final
Superseding 14.1/14.3 where they conflict: **seasons start on a Sunday, end on a Saturday**, N months snapped to whole weeks *(v1.1, D213: the Sunday snap is dropped; the first tee is any weekday — the season runs N whole weeks from the weekday of `starts_on`, clash weeks roll on that weekday, and first-tee labels derive the real weekday, never a hardcoded Sun/Sat. Built 2026-07-15, v23.122; the one label still keyed to Sunday — the Season tile's week-close line — was fixed on both clients in the same 2026-09-01/02 pass.)*. Caps/floors stay calendar-month machinery; **floors waived in partial edge months** *(implemented: blanket rule, migration 006)*. **The Cup Final is the final four weeks, scored fresh.** `close_month()` gains the waiver; weekly snapshots feed the Week Review browser. *(Open for v1.1: hybrid +15 in partial edge months — closed by D206, 2026-09-01: hybrid is retired from the engine and the `close_month` +15 branch is deleted.)*

### 14.1 Dates are structural
League timezone default `America/Phoenix`. Late joiners: before the 15th → full floor; on/after → waived that month. *(Original 1st-of-month start superseded by 14.0.)*

### 14.2 The turn of the month (automated close)
At 00:00 local on the 1st: floor penalties (honoring byes) → `season_adjustments` ledger; hybrid +15; **system post to the board** ("JULY CLOSED"); standings snapshot. Standings = rounds + adjustments; every adjustment carries a reason, reversible via the log.

### 14.3 The Cup Final, scored fresh
Seeds lock when the window opens (top-2 squads; both at 2-squad scale, leader +10; top-2 individuals Solo). Finalists race on final-window points only. **Tie-break ladder:** h2h months won → best single month → fewest rounds used → logged coin flip. Non-finalists keep playing: Points King, Iron Man, Most Improved run to the final day.

### 14.4 The day after — Trophy Room
48-hour grace for rounds played on/before the final day, then the close crowns and flips to `complete`. Home becomes the Trophy Room: champion banner, final table, awards, superlatives, pot settlement card. **Screenshot-shaped by design.** The board stays open.

### 14.5 Offseason → Season II
**Run it back:** bylaws carry forward unlocked, fresh draw, archive to multi-season history (Pro) — the re-up moment is the renewal moment.

---

## 15. Squad formation *(amended from "The Draft" — decided this cycle)*

**Blind draw** *(default, Free)*: server-side shuffle of all joined members, round-robin, revealed as a board post — rigging-proof. *(D54, 2026-07-21: the Pro may schedule the draw for a paced card-by-card reveal; instant remains default. See decision log.)* **Commissioner assign** *(Free)*: teams from the group chat, placed by hand. **Snake draft** and **Live draft + pick clock** retire to the **Pro roadmap** (schema from m004 remains ready). Captains are an optional label until the Final captain-playoff needs them. Season can't start with unassigned members; late joiners assigned to the thinnest squad, logged.

---

## 16. Receipts — every number shows its work

No points figure without a path to the rounds that produced it. Squad totals decompose into counting rounds + bonuses − penalties with ledger reasons. Player views show counting rounds AND displaced rounds (making the cap visible machinery). Round receipts show the rating/slope/allowance snapshot, differential arithmetic, attestation, and hole detail where it exists. Every round snapshots **how the handicap was known** (`self`/`app`/`ghin`) — the foundation of any future inter-club match.

---

## 17. Deferred architecture — clubs later, everyday golfer first

Schema is unusually club-ready (global profiles, cross-league rounds, course commons, uncapped squads). Missing pieces are additive: `organizations`, a cross-league event entity, event boards. **The reason to wait is trust, not architecture** — between clubs, attestation turns adversarial and GHIN verification becomes a prerequisite. **Trigger to build:** a head pro asks, or two real leagues ask to play each other. The club channel is the other 48 weeks (ringer boards, ladders), not event-day software.

---

*v1.0 — pilot and cheap to change. Pressure-test first: the points bands (§2.2), floor penalty severity (§3.2), the $12 Verified price (§11), whether groups score live rounds in-app (§13), and whether guest recaps convert (§13.3).*
