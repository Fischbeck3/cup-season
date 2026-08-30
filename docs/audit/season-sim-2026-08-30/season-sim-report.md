# Season simulation study — 64 seasons, 2026-08-30

**The ask:** *"I can't do a season start to finish without wasting a ton of time. I want to
be sure the play is sound for our biggest feature and that the finish is exciting and
engaging."* Pilot: Arizona, individual/solo, 8–12 golfers, starting 2026-09-06.

**What ran:** 64 complete seasons against the real engine — real `create_league` /
`lock_league` / `randomize_squads` / `start_season`, real round inserts through the
`score_round` trigger, real `close_month` / `enter_cup_final` / `close_season`. 26 configs
covering 2v2 up to 6v6, 3- and 4-squad, and solo at 8/10/12 golfers; both endgames; 9- to
39-week lengths; casual / standard / cutthroat / hybrid rulesets. Every measured config ran
**three replicates**, because one blowout is a draw and three is the format. 8,624 counting
rounds.

Method, fidelity rules and the teardown: `README.md`. Harness: `tools/`. Raw results:
`data/`.

---

## The two answers

**Is the play sound?** For your shape — solo, 10–12 golfers — **yes, and it is the best of
everything tested.** Solo leagues at 10–12 finished with an average margin of 4–5%, about
five lead changes a season, and **zero wire-to-wire runaways in 19 runs**. By contrast
two-squad leagues finished wire-to-wire **70% of the time** with a 23% margin. If you had
picked two squads, the pilot would likely have been decided in week one.

**Is the finish exciting?** The Cup Final genuinely decides things — it crowned someone
other than the regular-season leader in **5 of 13** solo cup seasons. But it does that for
**two people**. In a 10-player solo league, the moment seeds lock, **eight golfers can no
longer win the title**, with four weeks still to play. And the app does not tell them.

There is also one outright bug at the most important moment in the product: **the
season-wrapped card on Home names the wrong champion.**

---

## What is genuinely good

These are worth protecting.

**1. Solo at 10–12 is the most competitive format you have.**

| contenders in the table | n | wire-to-wire | mean margin | lead changes |
|---|---|---|---|---|
| 2 (squads2) | 27 | **70%** | 23% | 1.1 |
| 3 (squads3) | 3 | 67% | 12% | 0.3 |
| 4 (squads4) | 3 | 0% | 5% | 3.3 |
| 8 (solo) | 6 | 33% | 10% | 1.5 |
| **10 (solo)** | **13** | **0%** | **4%** | **5.1** |
| 12 (solo) | 6 | 0% | 5% | 4.7 |

More contenders means closer racing. Ten is materially better than eight.

**2. The mid-season experience for a losing player is well designed.** The drifter in last
place is shown *"3 points back of Moe Duffer"* — the golfer **one place ahead**, not the
leader — plus a concrete floor nudge (`AUG FLOOR 0/2 · 2 MORE · 1D`). That is the right
target to give someone in 10th.

**3. The Cup Final ceremony is excellent** and it is correct: champion, score, runner-up,
Points King, and the pot split down to the dollar.

**4. The clubhouse race view is honest.** IN/OUT badges, a cut line, the viewer's own row
highlighted, and "The regular season — final" once seeds lock.

**5. The solo floor copy is right.** *"In a solo league that is a habit, not a penalty —
there's no squad to dock."* That is true, and it is the kind of honesty §16 asks for.

---

## What is broken

### P0 — Home names the wrong champion

**`index.html:10425`.** The season-wrapped card picks the winner as `teams[0]` — the top of
the **points table** — while the real champion is `seasons.champion_member_id`, decided by
`close_season` from the Cup Final (28-day window + head start + §14.3 tiebreak).

In the simulated league `Encanto Ten` the database says **Vic Slice** won the Cup Final
28–26. The Home card says **"Ray Fairway took it."** One layer above it, the ceremony sheet
correctly says Vic Slice. Two producers of "who won", and the one on Home is wrong.

Two things make it worse:

* The same block renders `i===0 → "Your name goes on the cup."` So the points-table leader
  who did **not** win the Cup Final is told they did.
* The points table was **tied at 99** (Vic Slice and Ray Fairway), so the client's sort
  broke a tie that the engine breaks with a documented ladder.

This is the exact disease the 2026-08-30 code audit named: *a rule with more than one
producer*. The champion now has two.

**Fix:** read the champion from `seasons.champion_member_id` / `champion_squad_id`. Never
infer it from the standings table.

### P1 — Eight of ten players are shown a race they cannot win

Once `enter_cup_final` runs, `cup_finalists` holds exactly two rows and `close_season`
crowns only from those two. Everyone else is mathematically eliminated from the title.

The Home card does not say so. The player in 3rd sees:

> **PAPAGO TEN · CUP FINAL** — **3 seed** — HELD — **"5 points back of Cal Bunker."** —
> 2 WEEKS LEFT

He is 5 points back on the *points table*, which is still live and still worth the Points
King share. But the card is headed **CUP FINAL** and shows a **"3 seed"** that does not
exist — there are only two seeds. It reads as "keep grinding, you're close," when the thing
it names is sealed.

The clubhouse gets this right (`OUT`, cut line, "The regular season — final"). Home does
not.

**Fix:** for a non-finalist during `cup_final`, say what is actually live — the Points King
race and the final table — and stop calling it a seed.

### P1 — Points measure attendance, not golf

Across all 64 seasons, within each league:

* correlation of season points with **rounds counted**: **r = +0.96**
* correlation of season points with **points-per-round**: **r = +0.04**
* rounds-counted was the stronger driver in **61 of 61** leagues — unanimous

The mechanism is the band distribution. Of 8,624 counting rounds:

| band | share |
|---|---|
| 12 Torched it | 9.2% |
| 9 Beat your number | 10.6% |
| 7 Played to your index | 16.2% |
| 6 A little loose | 21.2% |
| **5 Rough day, posted anyway** | **42.8%** |

64% of all rounds land on 5 or 6. So **the best golfer in a league out-scores the worst by
1.83 points per round, while one extra posted round is worth 6.6 points.** Showing up once
more is worth about 3.6× being the best player in the league for a round.

The driver is the handicap engine doing its job: across 576 golfers the WHS-lite index
settled **4.7 strokes below** their true playing ability (it is the average of their best
few differentials, minus an adjustment). Volatile golfers are hit hardest — improvers and
streaky players lost 6.6–6.8 strokes, steady players 3.5. Since points come from
`playing_index − differential`, a lower index makes every band harder to reach. **A golfer
gets worse at this game by playing it well.**

*This is not a simulator artifact and the result is conservative:* the sim reaches "played
to your index or better" in 35.5% of rounds, where real golf is 20–25%. The real
distribution would be more bottom-heavy, not less.

Whether this is a bug depends on intent. If Cup Season is "post your rounds and stay in it
with your friends," it works exactly as designed. If it is "the best golfer over a season
wins," it does not currently do that.

### P2 — The app promised a +10 head start that solo leagues never get *(fixed)*

`endgameLine()` branched on structure for "golfers vs squads" but stated **"The leader
carries +10 in."** unconditionally. The engine grants that only for `squads2`
(`head_start = case when structure='squads2' then 10 else 0 end`) — solo, squads3 and
squads4 leaders carry nothing. Your solo pilot would have read a rule the engine does not
have, in the explainer meant to teach the endgame.

I introduced that line yesterday in D126/D127. **Fixed and verified** in a live solo league
(`index.html:5936`); preflight passes.

### P2 — A completed season still renders as a live race

Opening a finished league shows **"SEASON RACE · THE CLIMB"** with IN/OUT badges, a
**"CUT LINE · 15 BACK"**, and a recent-form column — on a season that is settled. The actual
champion sits at #2 with nothing marking him as the winner. Only the ceremony modal knows
the season is over.

### P2 — The product cannot express a season shorter than three months

`league_settings_season_months_check` is `>= 3 AND <= 12`. A four- or six-week trial season
cannot be created. Worth knowing a week out from a pilot — and note `lock_league` takes
explicit dates, so the stored `season_months` bylaw and the real window **can disagree**,
which is its own trap.

### P3 — The participation floor is structurally inert in solo leagues

`close_month` walks `squad_members`. Solo leagues have no squads, so **no floor penalty,
forfeit or auto-bye can ever fire** — confirmed across all 25 completed solo seasons. The
copy is honest about it, but the Home card still renders a floor progress bar with
`2 MORE · 1D` urgency for something with no consequence.

Separately: in any season without a **whole** calendar month, the floor is never assessed at
all (partial edge months are waived). A short pilot beginning Sep 6 and ending inside
October would assess it zero times.

### P3 — `sandbox_scrap` (D65) cannot scrap a league that closed a month

Fourteen tables reference `league_members` with `ON DELETE NO ACTION`. `sandbox_scrap`
deletes the league first, commenting that the cascade "clears every no-action member_id
reference" — it does not, once `season_adjustments` holds a floor penalty. My teardown hit
this and now clears children in dependency order (`tools/00-teardown.sql`).

### Note — CLAUDE.md is stale on the onboarding gate

CLAUDE.md and the code comment both say onboarding gates on `marker`. It is
`!marker || !handle` (`index.html:18189`). No real profile is affected (0 of 44), so this is
documentation drift, not a live bug.

---

## What I would change before September 6

**1. Fix the champion bug.** It fires on the single most important screen in the product.

**2. Run the pilot on the points table, not the Cup Final.** For a 10-person solo league:

| | points table | Cup Final |
|---|---|---|
| still alive at the end | **all 10** | 2 |
| wire-to-wire runaways | 0 of 12 | 2 of 13 |
| lead changes | 3.6 | 4.6 |
| final margin | 6% | 5% |
| last-day drama | every golfer | two golfers |

The Cup Final is the better *story* — it reversed the regular season 38% of the time. But it
buys that story by benching eight of your ten friends for the last month of a first
pilot, which is exactly when you need them still posting. Run season 1 on the points
table; introduce the Cup Final in season 2 once the habit is there.

If you do want the Cup Final, fix the non-finalist Home card first.

**3. Aim for 10–12, not 8.** Eight-player solo leagues went wire-to-wire in 1 of 3 with a
10% margin; ten-player leagues never did, at 4%.

**4. Decide what a point should mean.** Right now the table ranks attendance. If that is
what you want, say so in the copy and stop implying skill. If you want golf to matter, the
lever is the **counting cap** — at cap=2 the bottom bands fell from 64% to 47% because only
your best rounds count. A tighter cap (2 or 3 a month) makes quality matter and shortens the
grind; it is a one-field change in the wizard.

**5. Decide whether the solo floor should have teeth.** Today it is a suggestion. Either
give it a consequence in solo leagues or stop rendering a progress bar and a countdown for
it.

---

## The test footprint

Four simulated leagues are committed in production so the screenshots could be taken
(`Encanto Ten`, `Papago Ten`, `Tempe Solo League`, `Dobson Two-Squad`), plus their cast on
the unroutable `@sim.cupseason.test` domain and five `jerecho+simN@fischbeck3.com` observer
seats. Every league is flagged `sandbox = true`. The other 60 seasons ran inside
transactions that were rolled back and left nothing behind.

Remove all of it with `tools/00-teardown.sql` (change the final `rollback;` to `commit;`).
It rehearses clean and reports zero on every counter.

Still outstanding from yesterday, unrelated to this study: `git push` (now 3 commits) and
`supabase db push` for `20260830040000_buy_in_terms.sql`, plus the blind-audit test wipe
before **2026-09-05 07:20 UTC**.
