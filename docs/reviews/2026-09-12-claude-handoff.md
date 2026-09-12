# Claude → Codex handoff · 2026-09-12

Template from `2026-09-12-tandem-work.md`. Read from either workspace with
`git show <sha>:<path>`; no merge is needed to read a report.

- **Branch and commit:** `claude/after-golf-audit`, tip **`bea56eb`**, pushed.
  Three commits for you since you last read my branch at `079a67f`.
- **Goal / owned files:** backend implementation on the plan path, plus an
  independent inspection of your `b61024d`. I touched
  `supabase/migrations/` (two new files), `tests/db-checks.sql`,
  `spec/decision-log.md`, `spec/inbox.md` and `docs/reviews/`.
  **No client file, no generated file, no brand asset, nothing of yours.**
- **Built or reviewed:** both. Reviewed `b61024d`; built D343 and D344.

---

## What is here

| Commit | What |
|---|---|
| `c7236ea` | Inspection of your `b61024d`. Five of five fixed; one new finding; one merge problem. |
| `1a539f7` | **D343** — `declare_round` seats the host. Migration `20261022090000_the_host_has_a_seat.sql`. |
| `bea56eb` | **D344** — the four plan-day guards take one day of slack. Migration `20261023090000_a_plan_day_is_the_golfers.sql`. |

Reports: `docs/reviews/2026-09-12-home-fixes-inspection.md`,
`…-after-golf-audit.md` (read its correction banner first),
`…-after-golf-contract-review.md`.

---

## Verification, and how to repeat it

Everything below was run by me, not inferred. Production was read with SELECT
only and never written; no migration was pushed.

**Your `b61024d`, reproduced independently** in a detached worktree, not in
your workspace:

| Check | You reported | I measured |
|---|---|---|
| Native `CupSeasonKitTests` + `HomeNoPhotoTests` | 1,096 / 0 / 0 | **1,096 / 0 / 0**, and `HomeNoPhotoTests` confirmed present in the result bundle rather than filtered out |
| Home browser flow, 390px | passed | **`{"passed":true}`** |
| Home browser flow, 320px | passed | **`{"passed":true}`**, no overflow |
| `tests/app-tests.js`, 390px | 461 / 0 | **`{"total":461,"failures":[]}`** |

```
node tools/web-verify.mjs --url 'http://127.0.0.1:8793/?exit' --widths 390 \
     --wait 4000 --eval "$(cat tests/home-function-browser.js)"
```
(serve the checkout first; the flow needs `state` and `DEMO_FEED` on the page)

**My two migrations** were proven on a throwaway PostgreSQL 17 cluster built in
the session scratchpad with stub tables and deleted afterwards. Not on
production, and not on any cluster of the owner's. Both applied in order:

- a new plan seats its host `'in'`;
- the backfill seats the one future plan and **leaves the past plan alone**;
- a second run is a no-op, so it is idempotent;
- the self-check genuinely **raises** when a future host is unseated, so it is
  a guard and not decoration;
- a plan for `current_date - 1` (the golfer's tonight, seen from a UTC server
  at 6pm Phoenix) is **created**; `current_date - 2` is still refused;
- `current_date + 366` still hits the one-year ceiling, which D344 deliberately
  does not touch;
- D343's host seat still lands after D344 replaces `declare_round`.

`npm run preflight`: 0 failures on every commit. The single warning is the
pre-existing dev-only `acorn / eslint-scope not installed`.

---

## For you to inspect

**1 · D343, `20261022090000`.** One idempotent insert in `declare_round`. The
function body is **spliced from the migration file block after proving it
byte-identical to the deployed definition** (md5 `7016f9e5…`, 4,367 bytes), so
no guard, argument or sentence was retyped. Worth your eye on: the backfill is
`play_on >= current_date` only, and the reasoning for not backfilling the past
is in the entry.

**2 · D344, `20261023090000`.** Four functions, one guard each, swapped to
`plan_day_floor()`. Bodies were **fetched from the deployed definitions and
edited programmatically with an exact-count assertion per function**;
`declare_round` comes from D343 instead, because D343 is unpushed. Worth your
eye on: I took slack rather than a client-supplied date, and the reasoning
(the overload trap, proven) is in the entry. The cost is named there too.

**3 · `tests/db-checks.sql` gained check 33.** Future plans must have a seated
host. It will read FAIL until the push.

---

## Findings still open · yours

**A · The photo band's golfer action.** CONFIRMED, moderate, from
`c7236ea`. Your fix reached two of a photo row's three states. Loading gained
`.accessibilityAction(named: Text("Open golfer"), openPerson)` and the failure
record gained a 44pt labelled button, but the **loaded** band still has a bare
≈38pt `.onTapGesture` behind `.accessibilityElement(children: .ignore)`
(`HomeWire.swift:126-152`). So VoiceOver has no route to the golfer on the most
common state of the row, and **the loading placeholder is now more accessible
than the loaded photograph**. Pre-existing on the band, so not a regression
from your baseline; it is an incomplete fix, and your web story card already
does it properly (`index.html:15864`). Both fixes are additive.

**B · The course page cannot start a plan.** `CourseScreen.swift:361` — "Put
it on the plan" lives only inside `neverKept`, the branch for a course the
phone has never kept, so on a page that renders the door is absent. **I told
the owner this was "moving one door" and that was too glib.** The move is
mechanical, but `page(book)` already ends with a tertiary "The whole card" at
its foot, put there by D322, so a second door raises a real question about
which leads and at what weight. That is a design call with a screenshot
attached, which is yours. First question: does the plan door sit beside "The
whole card" as a second tertiary, or does it lead?

**C · Two residues on the reaction reveal**, both minor, from `c7236ea`. A
revealed row with no choice made cannot be collapsed until something
re-renders, which matches native and may be intended. And `renderHomeFeed()`
destroys the focus you carefully placed on the first chip the moment it is
used, so a keyboard user is thrown to the top. The second is pre-existing but
now asymmetric, since you handle focus on reveal and not on use.

---

## The merge · two files, one rule, already rehearsed

A real trial merge of `bea56eb` into `b61024d` conflicts in **exactly two
files**; the other 84 merge clean.

```
spec/decision-log.md      1 hunk
spec/inbox.md             1 hunk
```

Both are append-at-the-tail conflicts where **both sides are wanted and
neither supersedes the other**. I rehearsed the resolution: take yours first,
then mine. That yields D338 → D344 in order, with your `#### D340–D342`
amendment block sitting after D342 where it belongs, and
**`npm run preflight` passes on the merged tree**.

Note `f6e5ffd` (my D331–D339 catch-up) is **already contained in your branch**,
so it is not a third appender. My after-golf branch is based on `origin/main`,
which does not have it, which is why my tail jumps D330 → D343.

One small thing while you are in there: your amendment block is a `####`
sub-heading rather than `### D<n>`, so a reader grepping the file's own
convention will not find it.

---

## Deploys owed

- **Database: `supabase db push`** for `20261022090000` and `20261023090000`.
  **The owner's to run**, per CLAUDE.md. Neither has been pushed and neither is
  applied. `tests/db-checks.sql` check 33 reads FAIL until it is.
- **Edge:** none.
- **Client / TestFlight:** none from my branch. Neither migration needs a
  client release: the creation toast becomes true and Home's button flips on
  their own once the rows exist. TestFlight remains held.

## Waiting on the owner

1. **Four after-golf rulings** — `…-after-golf-contract-review.md` §4: the
   window, whether `maybe` and unanswered qualify, one plan per day, and the
   real one, same-day suppression when the plan has no course id. My advice
   there is to remove the ambiguity with item 28's nullable column rather than
   rule on which error to prefer.
2. **What a tee-less course should offer.** `ScheduleService.swift:148` and
   `:160` both end `.filter { !$0.tees.isEmpty }`; 12 of 115 cached courses are
   invisible and indistinguishable from "no such course", which is why Oak
   Quarry looked missing. A tee-less course cannot be planned against properly
   and D150 deliberately demoted the unlisted-course path, so this needs a
   ruling before code.
3. **Two brand rulings** from D339 / IOS-081: the pennant reservation against
   LINT-28, and the contour wallpaper on the icon tile.

## Next owner and bounded task

**Codex:** findings A, B and C above, and the merge when you integrate.
**Claude:** idle on the plan path until the owner rules on the tee-less course,
or the after-golf contract is unfrozen.
