# Gameplay rules audit and season simulation

**2026-09-12 · Claude · branch `claude/gameplay-rules-simulation` · commit: see the handoff at the foot.**
Codex owns the interactive prototype and the comprehension review; this document owns the rules
inventory, the fairness analysis and the simulation evidence.

**Everything here was read from source, measured on production with SELECT only, or run against an
isolated local PostgreSQL 17 cluster carrying the real migration chain.** No competition mechanic was
changed, no migration or Edge Function was deployed, no dependency was added, and production was
never used as a sandbox. Synthetic results are not proof of real-world fairness; where a synthetic
finding could be checked against production data, it was, and the check is reported beside it.

---

## 0 · The one finding to read first

**Most Cup Season rounds score below "played to your number", and that is by construction.**

| Points band (spec §2.2) | Spec label | Production, 298 real 18-hole rounds | Simulation, 347 synthetic rounds |
|---|---|---|---|
| 12 | Torched it | **0.3 %** (one round, ever) | 3 % |
| 9 | Beat your number | 15 % | 8 % |
| 7 | Played to your index | 20 % | 13 % |
| 6 | A little loose | 29 % | 16 % |
| 5 | Rough day, posted anyway | **36 %** | 60 % |

Two thirds of real rounds are 5s and 6s. The cause is not the golfers; it is the index. The engine
derives the index WHS-style from the **best 8 of the last 20** differentials
(`handicap_index_asof`), which is a measure of potential, not of the average round. A golfer whose
rounds vary by a normal ~3.5 strokes plays to that index roughly one round in four. The 95 %
allowance then lowers the target further. So the band the spec calls "played to your index" is a
good day, "a little loose" is an ordinary day, and "rough day, posted anyway" is the median.

The 12-point ceiling is doing its anti-sandbagging job so well that it has paid out once in the
product's history. The synthetic model is harsher than production (its variance assumption is
likely a stroke high), but the direction and the order of the bands are the same in both.

This is a **comprehension** finding before it is a fairness one: the labels tell most golfers most
of the time that they underperformed, when they performed exactly as a best-8-of-20 index predicts.
The scoring is internally consistent; the words are calibrated to a different index than the one
the engine computes. It is also the single most valuable thing Codex's prototype can test with real
people (§6).

---

## 1 · Current-rules inventory

Four columns, deliberately: what is **approved** (spec plus decision log), what the **deployed
engine does** (read from production's own function bodies, saved in `tests/sim/engine-dump/`),
where they **conflict**, and what production **data** shows that no document records.

### 1.1 The scoring pipeline — round → points

| Rule | Approved | Deployed engine | Conflict / note |
|---|---|---|---|
| Differential | `(gross − rating) × 113 / slope`, 1 dp | `score_round()` trigger, exactly that; 9 holes with `nine_rating` doubled | **9 holes without `nine_rating` falls into the 18-hole branch** and subtracts the full rating — a wildly negative differential. Bug. |
| Playing index | `index × allowance %` | `v_rounds_ranked`: `pvi = round(index_at_post × allowance/100 − differential, 1)` | Matches. |
| Bands | 12 / 9 / 7 / 6 / 5 at +3, +1, −0.9, −3 (§2.2) | `cup_points`: `≥3, ≥1, >−1, ≥−3, else` — half-open edges per D123/D174 | Spec leaves −1.0<PvI<−0.9 undefined; engine says 7. A dead 7-argument `score_round` overload uses `≥−1` and is called by nothing. |
| Index at post | "every round snapshots how the handicap was known" (§16) | caller value → `profiles.index_current` → `handicap_index_asof` → the round's own differential | **A backdated round scores against today's `index_current`, not the index as of `played_on`.** |
| Index derivation | WHS-style best 8 of 20, revised monthly on the 1st (§5) | `handicap_index_asof`: m-table `≤5→1, ≤8→2, ≤11→3, ≤14→4, ≤16→5, 17→6, 18→7, else 8`; adjustments −2.0@3, −1.0@4, −1.0@6, **−1.0@9–11**; `round_refresh_index` rewrites `index_current` on **every** insert | Not the WHS 2020 table (18→6 and 9–11→0 in WHS). Continuous, never monthly. No max 30, no rise cap, no exceptional cut (spec §5 already notes these as unbuilt). |
| Provisional | D49: score normally, badge until 3 rounds. D124: bounded badged flat 7. | Below 3 differentials the index is null → falls back to the round's own differential → PvI 0 → 7 | D49 and D124 are a **named CONFLICT** in the log; the engine implements neither's intent explicitly and lands on 7 by arithmetic. |
| 9-hole points | `÷2 round up` (§2.4), half floor credit | `ceil(cup_points/2)` → 6/5/4/3/3; `floor_credit` 0.5 | Matches. D182's 10–17-hole rescue is proposed, not built. |
| No 7-day wall | struck as unenforced (D136) | `post_round` rejects only `played_on > current_date` | Matches. The "posted late" stamp is leaned to, not built. |

### 1.2 Counting and the month

| Rule | Approved | Deployed engine | Conflict / note |
|---|---|---|---|
| Counting cap | **Best 3** default (D142); Standard 3, Cutthroat 2, Casual unlimited; CHECK 1..31 (D206) | `month_rank ≤ coalesce(counting_cap, 999)` | **Production: `counting_cap` is NULL on 7 of 10 leagues and 4 on the other 3. No league runs 3.** NULL is unlimited. |
| Cap tie | unspecified | `month_rank` orders `points desc, pvi desc, played_on desc` — **the later round wins** | Undocumented. |
| Floor | 2/month, −5 per round short (Standard), forfeit (Cutthroat), none (Casual) | `close_month`: `−5 × ceil(short)`; forfeit strikes `counting_pts`; floors iterate `squad_members` only | **Solo leagues never get a floor** (D140, deliberate). 1.5 short → −10. |
| Bye | "1 bye month per player per season, commissioner-approved" (§3.2) | **auto-bye** on the first miss, 0 points, one per season (D14) | Spec §3.2 never amended. |
| Partial edge month | floors waived (§14.0) | `is_partial` = starts after the 1st OR ends before month-end → no floors at all | Blanket. **Every 13-week season with a mid-month start assesses the floor in at most two months.** |
| Late join | "before the 15th full floor, on/after waived" (§14.1) | member whose `joined_at` falls in the month is skipped (D161) | §14.1's 15th rule is **not** implemented; D161 supersedes it and the spec is unamended. |
| Squad total | Σ counting points − penalties (§3.3) | `v_squad_standings` = counting points + **all** `season_adjustments` with a `squad_id` | Matches. **Squads are not size-adjusted** (D243/244): a 4-golfer squad sums four incomes. |
| Individual total | — | `v_individual_standings` = counting points, **no ledger** | **A floor penalty never touches the golfer's own number**, only the squad's. Points King ignores floors. |
| Season attribution | round belongs to its league window (D122) | `v_rounds_ranked` **ignores `rounds.season_id`**: a round joins every league the profile is in whose season window contains `played_on` | By design (D123, "the league lens"). 11 real profiles are in more than one league. |
| Snapshot | monthly at close (§14.2) | weekly (`snapshot_week`), on **UTC** `current_date` | Same timezone class as D344. |

### 1.3 The Cup Final and the close

| Rule | Approved | Deployed engine | Conflict / note |
|---|---|---|---|
| Lock | `ends_on − 27` (§14.3, D24) | `enter_cup_final` when `current_date ≥ ends_on − 27` | Matches. Seeds use counting rounds with `played_on < ends_on − 27`. |
| Seeds | top-2 squads / individuals; §14.3 ladder (D105) | `score desc, months_won desc, best_month desc, rounds_used asc, random()`; `seed_rung` stored | **`months_won` = strictly beat the max of ALL other squads that month**, not head-to-head. Spec says "h2h months won". |
| Head start | leader +10 at 2-squad scale (§14.3) | `head_start = 10` for seed 1 **only under `squads2`** | squads3/4 and solo get 0. Undocumented narrowing. |
| Window scoring | "scored fresh, under the league's own counting rules" | `_cup_window_rounds`: window rounds count only if `month_rank ≤ cap` **in their whole calendar month** (D212) | **Not fresh for the cap.** Three strong rounds early in the lock month push a window round out. |
| Tiebreak | §14.3 ladder (h2h → best month → fewest rounds → coin) vs **§9 "total squad PvI → h2h → coin flip"** vs §4 "combined PvI → captains' playoff" | §14.3 ladder over the whole season; `random()` as the coin; rung name stored | **The spec carries three different tie rules.** D105 retired §4; §9 stands unamended and is not implemented. |
| Grace | 48 h (§14.4) | `close_season` when `now() > (ends_on+1) local midnight + grace_hours` | Matches. |
| Void / correction | "Commissioner can void/edit any round" (§9) | **No void writer exists.** `rounds.voided` has 0 rows and nothing sets it. `delete_round` is the only path, owner-only, hard delete. `season_adjustments.kind='override'` is allowed and never written. | **§9 is unimplemented.** A closed month's floor rows are not re-assessed after a delete (sentinel). |
| Deleted round's index | rounds are facts (§16) | `delete_round` recomputes `index_current`; every round already posted **keeps its `index_at_post` snapshot** | So a correction posted later scores against a different index than the original did. Proven in S6. |
| Settlement | 60/25/15, "paid from what was collected" (D106) | pot = buyin × **all** `league_members` incl. left/suspended; collected capped at pot; runner 25 %, king 15 %, champion remainder | **An uncollected pot writes no payout rows at all.** Proven in S8. |

### 1.4 The side competitions — must never move a squad total

| | Approved | Deployed | Evidence |
|---|---|---|---|
| Weekly clash | one pairing/week, best band, headline W, **never cup points** (D52/D108/D207) | `settle_week_clash`: best round in the week **ignoring the cap**, decided by band; equal = all square; writes `week_clashes` only | S7 asserts the squad table is unchanged by any clash result. |
| Major | best 18-hole card in a 2–4 day window, 100 % allowance, no band ceiling, parallel ledger (D42–46) | `settle_major`: 18-hole only, ladder pvi → second_pvi → best_posted_at → random; writes event tables only | Dump confirms no write into `season_adjustments`; the D42 "Major → Cup port" is named and unbuilt. |
| Ryder / callout | best PvI in window, 1 / ½ / 0, never season points (§R4, D237) | `resolve_session` writes event tables only; idempotent, no retro-flip on delete | Dump confirms. |

### 1.5 Retired and historical, explicitly

Formats B (head-to-head) and C (hybrid +15) — retired D48, engine branch deleted D206; **2 legacy
`matchup_bonus` rows still feed one production squad table.** The bonus layer §2.3 — retired D48. The
allowance dial — retired D48, presets fixed at 100/95/90; **production runs 95 only.** The flat-7
provisional — retired D49, then bounded D124 (conflict). Sunday-start seasons — dropped D213. The
"Best 4" default — replaced by Best 3 in D142 (and, per §1.2, by nothing in production). The
gameplay-modes working doc still states cap default 4 and is not current on it.

### 1.6 Unverified production behaviour (data no document records)

- **The participation floor has never fired.** Zero `floor_penalty`, `bye` or `floor_forfeit` rows in
  production, ever. Seasons are short, starts are mid-month, and the partial-month rule waives.
- **No real league runs the documented default cap.** NULL ×7 (unlimited), 4 ×3, 3 ×0.
- **The tie ladder has never been used.** `seed_rung`, `tiebreak_rung`, `king_rung` are null on
  every row.
- **61 of 213 rounds fall outside any season window.**
- **0 voided rounds**, and no way to make one.
- One 9-hole round in production; the `nine_rating`-missing bug in §1.1 has not been hit yet.

---

## 2 · Reproducible season simulations

### 2.1 What runs, and how to run it

Two engines, one set of generated rounds, and a comparison of every answer.

- **`tests/sim/engine_mirror.py`** — a Python reading of the rules, corrected against the deployed
  engine until they agreed. Every remaining approximation is listed by `assumptions()`.
- **`tests/sim/engine_real.py`** — replays the same rounds through the **real engine** in an isolated
  cluster, using the RPCs a phone calls (`create_league`, `lock_league`, `add_friend_to_league`,
  `assign_player`, `start_season`, `post_round`, `delete_round`) and the cron entry points called
  explicitly (`close_month`, `enter_cup_final`, `close_season`).
- **`tests/sim/sandbox/apply.sh`** — builds the cluster: `initdb` → stubs for the Supabase surface →
  **all 228 migrations on `origin/main`, in order, zero skipped** → the signup trigger. Stubs are
  inventoried in `sandbox/stubs.md`. Nothing runs on a timer; the simulator drives the clock.

```sh
# build the isolated engine (PostgreSQL 17 at /opt/homebrew; port 5470; ~2 min)
REPO=$PWD tests/sim/sandbox/apply.sh

# every family, mirror only, seed 7 (fast)
python3 tests/sim/run.py

# one family through BOTH engines, with a line-by-line comparison
python3 tests/sim/run.py S1_frequency --engine real

# fairness Monte Carlo over 300 seeds (mirror)
python3 tests/sim/run.py --mc 300

# stop the cluster
/opt/homebrew/opt/postgresql@17/bin/pg_ctl -D tests/sim/sandbox/pgdata stop
```

Results land in `tests/sim/results/<family>.json` (mirror) and `<family>.real.json` (engine).

### 2.2 Mirror versus engine — the reconciliation

Six families, thirty-seven golfer rows, three bylaws sets. After correction the two engines agree on
**every** golfer's counting points, **every** squad total, **every** seed, **every** champion and
**every** Cup score. The disagreements found along the way were each an engine fact the spec does
not state, and each is now in §1:

| What the comparison caught | Where the engine differs from a plain reading of the spec |
|---|---|
| Cap ties | the *later* round wins (`played_on desc`) |
| Index table | deployed m-table ≠ WHS 2020 at 18 and 9–11 |
| Cup seeds | ranked on every counting round before the lock day, not on closed months |
| Cup window | a window round must be within the cap of its whole calendar month |
| Head start | +10 only under `squads2` |
| `months_won` | beat the max of all squads, not head-to-head |
| Deleting a round | never rescores rounds already posted; their index snapshot stands |
| Founding members | `joined_at` is before the season; only a mid-season add gets D161's waiver |
| Minimum roster | `start_season` refuses fewer than four for squads (D205) — the mirror does not |

### 2.3 The families and what they showed

Seed 7 throughout; Monte Carlo over 300 seeds where stated. Allowance 95 %, cap 3, floor 2 with
−5 per round short, one auto-bye — the documented Standard defaults, which, per §1.6, no real league
runs.

**S1 · Infrequent versus frequent play.** Four identical golfers (ability 12, σ 3.5) at 1, 2, 4 and
7 rounds a month, 13 weeks.

| Rounds/month | Season points, mean (sd) | Floor events / season | Wins the table |
|---|---|---|---|
| 7 | 63.2 (4.8) | 0 | **300 of 300** |
| 4 | 55.5 (5.7) | 0 | 0 |
| 2 | 34.7 (9.8) | 0.52 | 0 |
| 1 | 18.2 (8.1) | 1.43 | 0 |

At identical ability, frequency is decisive: seven rounds a month beats four by ~14 % and two by
~80 %, because more draws produce a better best-three, and the floor adds a −5 on top for the
golfer at one. The 13-week default assesses the floor in only two months here; the third is partial
and waived.

**S2 · Mixed handicaps and variability.** A 5 (σ 2.5), a 15 (σ 3.5), a 25 (σ 5.0) and a steady 15
(σ 1.5), all at 4/month.

| Golfer | Season points, mean (sd) | P(wins) over 300 seeds |
|---|---|---|
| 5-index, σ 2.5 | 57.1 (4.7) | **0.36** |
| 15-index, σ 3.5 | 55.5 (5.4) | 0.26 |
| 25-index, σ 5.0 | 54.1 (6.1) | 0.19 |
| 15-index, σ 1.5 | 56.0 (3.4) | 0.19 |

PvI banding narrows a 20-stroke ability gap to about three season points. Two things survive it.
The lowest handicap keeps a modest edge, because a tighter golfer's index sits closer to their
mean and so their PvI is less negative on an ordinary day. And **high variance does not pay**: the
25 with σ 5 wins least, because a best-8-of-20 index is *more* optimistic the wider the golfer's
spread, so the same variance the 12-point ceiling was designed to stop rewarding is already
penalised at the index. The ceiling is a second lock on a door the index locked.

**S3 · Unequal squads, a late join, absences.** Squad A has four golfers, B three, C four with one
who joins on day 19 and one absent two months. 17 weeks.

- **A wins 300 of 300.** Every golfer averages ~74; a fourth income is decisive. Squads are not
  size-adjusted (D243/244), so this is by ruling, and the question is whether golfers understand
  it. *Prod runs `squads2`, `squads4` and `solo`; a 4-v-3 draw is what `_late_squad` produces.*
- The late joiner (65 points) got the join month waived (D161) and lost nothing to the floor.
- The two-month absentee (37 points) spent the bye on month one and took **−10** on month two,
  which is the whole of the floor's bite in a 17-week season.

**S4 · Counting-round replacement and the three penalty dials.** Same rounds, one chronic
under-floor golfer.

| Dial | Squad A | Effect on that golfer |
|---|---|---|
| none | 111 | nothing |
| deduct | 106 | −5, one month, after the bye |
| forfeit | 106 | the month's counting points struck (they were 5) |

Displacement works as documented: a better round replaces the worst counting one in real time on
both engines. Under Standard bylaws the deduct and forfeit dials cost the same here, because the
struck month held one 5-point round — forfeit only bites when a short month also held good rounds.

**S5 · Cup qualification, the Final, and the non-finalists.** Four squads, one bottom-squad golfer
playing nine rounds a month. 26 weeks.

- Seeds locked on 2 Aug at D 491, B 336, C 335, A 331 — **B and C one point apart at the lock**,
  and the engine seeded B, as §1.3 says it must (every round before the lock counts; the mirror had
  originally seeded on closed months and was wrong).
- The window scored fresh: D 70, B 53. Champion D. Both engines.
- The golfer on the bottom squad with 51 rounds took the most counting points (135) of anyone.
  Iron Man and Points King run to the last day regardless of the Cup, as the spec promises.

**S6 · A late post, a deletion, a correction.**

- A round played 1 Mar and posted 13 Mar scored in March. There is no 7-day wall; there is also no
  "posted late" mark anywhere in the data. Matches §1.1.
- A golfer's best round deleted after the season: it left the standings (45 → 44) **and stayed in
  the index history** of every round posted while it existed. The engine and the mirror agree
  once the mirror stopped rescoring. This is what "rounds are facts" means in practice.
- A correction (a 91 mistyped, re-posted as 81): the old round deleted, the new one posted — and
  scored against the index *at the time of the re-post*, not the index the original had. The
  golfer's average PvI moved from −2.51 to −2.03 across the two engines' different provenance.
  Nothing rewrites history; the correction is a new fact with new provenance.

**S7 · The clash stays separate.** Ten weekly clashes settled; the squad table was byte-identical
with and without them. Asserted programmatically, both engines.

**S8 · A forced tie and an uncollected pot.** Every round at differential 10.0 against a 10.0 index
(every round exactly 7 points), so months are won by round count. A wins March and April, B wins
May, the June window is identical.

- Window 28–28. **Champion A via `months won`**, and the engine stored `tiebreak_rung = 'months won'`
  — the first time that column has held a value anywhere, since production's are all null.
- $50 buy-in, six members, nobody paid: `pot_cents 30000, collected_cents 0`, and **zero
  `season_payouts` rows.** The champion's record shows no settlement at all.

---

## 3 · Findings, ranked

Each is marked **F** (fairness), **C** (comprehension) or **I** (implementation risk), and
**observed** (engine or production) or **synthetic** (mirror only).

1. **[C, F · production]** Two thirds of real rounds score the bottom two bands and the top band has
   paid once. The labels describe a good day as "played to your index" and the median day as
   "rough". (§0)
2. **[F · synthetic, direction confirmed in prod]** Frequency dominates ability. At identical
   skill, 7/month beats 4/month every time and beats 2/month by 80 %. Under Best-3 the marginal
   round past three is worth less each month, but the *first* three are worth everything, and a
   two-a-month golfer is one bad week from the floor. (S1)
3. **[F · by ruling]** Squads are summed, not averaged, so a 4-golfer squad beats a 3-golfer squad
   300 times in 300. This is D243/244's decision and the draw can produce it. It needs to be
   *said* on the standings. (S3)
4. **[I · engine]** The Cup Final is not scored fresh for the cap. A window round counts only if it
   is within the cap of its whole calendar month, so three strong rounds in the first days of the
   lock month can delete a Final round. Documented in D212, contradicted by the spec's "scored
   fresh", and invisible to the golfer. (§1.3)
5. **[I · engine]** A backdated round scores against *today's* index, not the index as of the day
   played; and a deleted round's influence persists in every snapshot taken while it existed. Both
   are consistent with "rounds are facts"; neither is explained anywhere a golfer reads. (§1.1, S6)
6. **[I · production]** No league runs the documented default cap; seven run unlimited via NULL.
   Every claim about "Best 3" in the spec, the wizard copy and D142 describes zero real seasons.
   (§1.6)
7. **[C · engine]** `months_won` is "beat every other squad", the spec says head-to-head; the spec
   carries three tie rules; the ladder has never fired in production and produced its first stored
   rung in this sandbox. (§1.3, S8)
8. **[I · engine]** No void or correction path exists. §9 promises the commissioner can void or
   edit; the only tool is the owner's hard delete, which does not re-open a closed month's floor.
   (§1.3)
9. **[F · engine]** A floor penalty never touches the golfer's own number. Points King is blind to
   participation; a golfer who misses every floor loses their squad −5s and keeps every individual
   point. (§1.2)
10. **[F · synthetic]** High variance does not pay. The index already punishes it harder than the
    12-point ceiling ever could, so the ceiling's stated purpose is served twice and its cost —
    that a career round is worth the same as a good one — is paid for nothing. (S2)
11. **[I · engine]** The floor has never assessed in production, and under the 13-week default it
    assesses at most twice. The mechanic every preset advertises has no observed behaviour. (§1.6)
12. **[I · engine]** An uncollected pot settles to nothing: no payout rows, no ledger line naming
    the champion's share. (S8)
13. **[I · engine]** A 9-hole round without `nine_rating` gets an 18-hole differential. Latent; one
    9-hole round exists in production. (§1.1)
14. **[I · engine]** Weekly snapshots and the daily tick read UTC, the same class of defect D344
    fixed on the plan path. (§1.2)
15. **[C · docs]** The spec's §3.2 bye, §9 tie rule, §9 void/edit, §14.1 15th rule and §14.2 hybrid
    +15 are all superseded and unamended; the working notes still say cap 4. (§1.5)

---

## 4 · A proposed shared gameplay contract

One statement per subject, written to be true of the engine today, so both clients and any
prototype can build on it without re-deriving. Where the engine's behaviour is a defect, the
contract states the *current* behaviour and flags it, rather than describing a wish.

**Eligibility.** A round scores in every league the golfer belongs to whose season window contains
`played_on`, at that league's allowance. Membership is by `league_members`; a round played before
joining still scores if it is inside the window. Suspended or departed members are cut by
`created_at`, not `played_on`. *(flag: `rounds.season_id` is stored and ignored.)*

**Counting.** Per golfer, per calendar month of `played_on`, the best `counting_cap` rounds by
points count; ties by higher PvI, then the later date. `counting_cap` NULL means unlimited. 9-hole
rounds count at `ceil(points/2)` and half a floor credit. Displacement is immediate.

**Score provenance.** A round carries `index_at_post`, taken at the moment of posting from the
golfer's current index (or the engine's as-of computation when none is stored), and never changed.
A deletion recomputes the golfer's index going forward and rescores nothing. A correction is a
deletion and a new post, scored at the new post's provenance. *(flag: a backdated post uses
today's index.)*

**Competition windows.** A month is the calendar month in the league's timezone; it is assessed
only if the season covers it entirely. The Cup lock is `ends_on − 27`; seeds rank on counting
rounds played before the lock; the window is `[ends_on − 27, ends_on]`; a window round counts only
if within the cap of its calendar month. The clash week is `floor((local_date − starts_on)/7)`.
*(flag: snapshots and the tick read UTC.)*

**Ties.** For seeds and the crown alike: points, then months won (strictly beating every other
squad that month, over the whole season), then best single month, then fewest counting rounds
used, then a stored random draw. The rung used is recorded. This is the only tie rule the engine
has; §9's PvI rule and §4's playoff do not exist.

**Corrections.** There is no void, edit or override. The owner may delete their own round. A closed
month is not re-assessed after a deletion.

**Settlement.** Pot = buy-in × every `league_members` row. Payouts are made from what was
collected, capped at the pot: 25 % runner-up, 15 % Points King, remainder champion, per seat in
`profile_id` order. If nothing was collected, nothing is recorded.

**Golfer-facing explanations owed by this contract.** (a) What band an ordinary round lands in and
why. (b) That the squad table sums incomes and squads may differ in size. (c) That the Final's cap
is monthly, not window-only. (d) That a correction is a new round with new provenance. (e) Which
cap the golfer's league actually runs.

---

## 5 · Three recommendations

**Improvements to existing mechanics — no new nouns.**

1. **Recalibrate the band language to the index the engine computes.** Keep the points. Rename the
   bands so the median round is not called "rough" — e.g. 7 as *"Your number's day"*, 6 as *"An
   ordinary one"*, 5 as *"Posted"* — and let the receipt say *"your index is your best eight of
   twenty, so most rounds land here"*. This is the highest-leverage change in the audit, it is copy
   only, and Codex's prototype can measure whether it lands (§6). *Owner ruling: the words.*
2. **Make the Final actually fresh, or say it is not.** Either rank window rounds among themselves
   (a one-clause change to `_cup_window_rounds`, logged as a D-entry), or amend §14.3 to say the
   monthly cap still applies and show it on the Final's receipt. The engine and the spec must stop
   disagreeing about the one contest the whole season leads to. *Mechanic change: needs a D-entry
   first.*

**New proposal.**

3. **A commissioner's override that writes to the ledger, not to the round.** §9 promises void and
   edit; the engine has neither, and a hard delete cannot re-open a closed month. Add one RPC that
   writes `season_adjustments(kind='override', member, month, points, reason)` — a kind the CHECK
   already permits and nothing uses — so a Pro can settle a dispute with a visible, reversible,
   reasoned line that leaves every round a fact. It fits §16 exactly and needs no schema change.
   *Mechanic addition: D-entry, then a migration, then both clients.*

Not recommended, and worth saying: do not average squads to fix F3. The sum is the season's
engine of belonging — a fourth golfer *is* worth more — and the honest fix is the sentence on the
table, not the arithmetic.

---

## 6 · Questions Codex's prototype should help answer

1. Shown their own last ten rounds banded, do golfers read "a little loose" as a bad day? Does
   renaming the 6 and 5 bands change what they say the season is telling them?
2. Shown a 4-v-3 squad table, do golfers assume it is averaged? What sentence on the table makes
   the sum feel fair rather than rigged?
3. Shown the Final's receipt with a window round displaced by a pre-window round of the same month,
   do golfers accept it, or does "scored fresh" have to mean fresh?
4. Does "your correction scored against this month's index, not last month's" read as fair or as a
   trick?
5. When a golfer is told their league's cap is unlimited (as seven real ones are), does the
   "best three" framing in the wizard still make sense to them?

---

## 7 · Limitations, stated

- **Synthetic golfers are independent Gaussians** with no form, weather, course variety or
  learning; every round is on one 71.2/128 course; 18 holes only; no sim rounds. The variance
  assumption (σ 3.5) is likely a stroke high, which is why the synthetic band table is harsher
  than production's. Every number in §2 is an artefact of these choices until checked against real
  play, and only the band distribution was so checked.
- **The sandbox is `origin/main`, 228 migrations.** Production is at 231; the three it lacks
  (Codex's idempotent post, D343, D344) do not touch scoring.
- **pg_cron does not run.** Month closes, the Cup lock and the season close were called directly,
  in order, after each month's rounds. The daily tick's own sequencing and idempotency were not
  exercised. Rounds carry today's `created_at`, so suspension cut-offs and "posted late" provenance
  are not modelled.
- **The caller is a superuser in the sandbox.** In-body guards run as production; RLS and GRANTs
  do not. Nothing here tests what a golfer can *see*.
- **Majors and the Ryder were not simulated**; their separation from season points is asserted
  from the deployed function bodies, not from a run.
- **The prototype is Codex's.** Nothing here claims to know what a golfer will understand.

---

## Handoff

- **Branch / commit:** `claude/gameplay-rules-simulation`, commit recorded in the git log for this
  file; pushed.
- **Goal / owned files:** rules inventory, fairness analysis, simulation evidence. New:
  `tests/sim/` (harness, sandbox scripts, engine dump, results), this report, three `.gitignore`
  lines. No application code, no migration, no generated file, no shared spec file edited.
- **Built or reviewed:** both — the harness was built; the engine was reviewed.
- **Verification:** the isolated cluster applied 228/228 migrations with zero skips; six families
  reconciled between the mirror and the real engine on every squad, golfer, seed and champion; the
  forced tie stored `tiebreak_rung`; the band distribution was checked against 298 production
  rounds by SELECT. `npm run preflight` passes on this branch.
- **Findings still open:** all fifteen in §3; the three recommendations in §5 need owner rulings
  before any mechanic changes.
- **Database / Edge / client deploy owed:** none. Nothing was deployed. Production was read-only.
- **Next owner and bounded task:** Codex, for the prototype and §6; the owner, for the rulings in
  §5. The sandbox rebuilds from `tests/sim/sandbox/apply.sh` in about two minutes on this machine.
