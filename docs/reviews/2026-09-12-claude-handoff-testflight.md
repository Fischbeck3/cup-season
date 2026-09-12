# Claude → Codex · the one-hour TestFlight window

**2026-09-12.** Written for a release window, so it leads with the decisions
rather than the reasoning. Branch `claude/after-golf-audit`, tip **`482f256`**,
pushed. Read any of it with `git show <sha>:<path>`.

---

## The three decisions, up front

**1 · Do not push another migration in this window.** `D345` is committed and
**deliberately unpushed**. It puts a **new card on Home** for every tester the
moment it is applied, and Home is reviewed by screenshot. One hour is not that
review. It costs nothing to wait: it is server-only, so it does not block the
build, and shipping the client without it changes nothing.

**2 · The database is already where it needs to be.** `D343` and `D344` were
applied and verified earlier today. Production is at **231 migrations**, newest
`20261023090000`. **Neither needs a client release** — that is why they were
safe to push and D345 is not.

**3 · No client test breaks because of them.** I checked before writing this.
The only tests that mention the past-plan path assert **copy strings** through
`csShareLine` / `ShareIntent` (`ShareKindTests.swift:165`,
`app-tests.js:1250`), not server behaviour, and `redeem_share`'s `seat:'past'`
branch still exists — it simply triggers a day later. `rsvp_in` appears in
`MeStripTests` and `PeopleScheduleTests` only as fixture values. **Nothing to
fix before you run the suites.**

---

## What changed in production today, and what to look at

Both are live now. Worth one screenshot each, because they change what a real
account sees.

| Change | What a tester sees | Where |
|---|---|---|
| **D343** · the host is seated on their own plan | Home's plan card action flips from **"Say you're in"** to **"Open the plan"** for a plan you created. The plan sheet shows "I'm in" as selected. | Home, plan card · plan sheet |
| **D343** · `rsvp_in` counts the host | **"2 of you on the sheet"** can now appear where nothing did. It was undercounting, and the Home fixtures already assumed the corrected number. | Home, plan card standfirst |
| **D344** · one day of slack on four plan guards | After 17:00 Phoenix a plan for **tonight** can be created, re-tagged, joined and redeemed. It could not before. | Declare sheet · plan sheet · a share link |

**The quickest confidence check** is to create a plan and look at the card. If
it says "Open the plan" rather than asking you to join your own round, D343 is
working end to end.

---

## The merge · rehearsed, two files, one rule

A real trial merge of `482f256` into `b61024d` conflicts in **exactly two
files**; everything else merges clean.

```
spec/decision-log.md      1 hunk
spec/inbox.md             1 hunk
```

Both are append-at-the-tail where **both sides are wanted**. Resolution: **take
yours first, then mine.** That yields D338 → D345 in order with your
`#### D340–D342` amendment block after D342, and I confirmed
`npm run preflight` passes on the merged tree.

`f6e5ffd` is already contained in your branch, so it is not a third appender.
My branch is based on `origin/main`, which is why my tail jumps D330 → D343.

**Migrations merge clean** and sort correctly: `20261021090000` (yours),
`20261022` and `20261023` (applied), `20261024` (D345, unpushed).

Build number after the merge is about **804** (`git rev-list --count HEAD`).

---

## My three open findings · none of them blocks this build

Detail in `git show c7236ea:docs/reviews/2026-09-12-home-fixes-inspection.md`.

1. ~~**The photo band has no VoiceOver route to the golfer**~~ **WRONG, corrected — the action is at `HomeWire.swift:154` and always was.** What survived is only the 44pt target, which Codex has fixed.
   <!-- original: -->
   **The photo band has no VoiceOver route to the golfer** and its face is
   under 44pt (`HomeWire.swift:126-152`). Your fix reached the loading and
   failure states and not the loaded photograph, so the placeholder is now more
   accessible than the photo. **Pre-existing on the band, additive to fix.**
   Not a beta blocker.
2. **The course page cannot start a plan** (`CourseScreen.swift:361`). Not a
   regression, and the landing is a design call because that page already ends
   with a tertiary door. Yours, after the window.
3. **Focus is lost when a reaction is chosen**, because the re-render replaces
   the DOM. Pre-existing, small.

---

## If there is time left after the build

In this order, and only if the build is already archiving:

- Delete `HomeDispatch.localHeadline`. Its only reason to exist was the server
  writing *"You have a round on today."*, which **D345 fixes at the source** —
  so do this **only if D345 is pushed**, and otherwise leave it alone.
- The photo band's `.accessibilityAction(named: Text("Open golfer"),
  openPerson)` and a 44pt `contentShape` on the face. Two additive lines.

---

## Not done, and not mine to do

- **The tee-less course** (`docs/reviews/2026-09-12-tee-less-course-tree.md`,
  and the page the owner has). Q2 to Q5 are one small client change plus an
  edge-function change; **Q6 needs an owner ruling** and I recommended holding
  it until bare courses are visible and the real absence rate is known.
- **The two brand rulings** (D339 / IOS-081): the pennant reservation against
  LINT-28, and the contour wallpaper on the icon tile. Amending an identity
  rule is the owner's call, not mine and not a release-window decision.
- **`rounds.scheduled_round_id`** (inbox 28). D345's suppression is a
  documented heuristic until this exists, and it belongs with the composer's
  plan bridge, because a column nothing writes is not a fix.

---

## Handoff

- **Branch / commit:** `claude/after-golf-audit`, `482f256`, pushed.
- **Built:** D343, D344 (both applied and verified in production), D345
  (committed, unpushed, server-only).
- **Reviewed:** `b61024d`, reproduced independently — 1,096 native and 461 web,
  both matching your numbers.
- **Verification:** preflight 0 failures on every commit; `tests/db-checks.sql`
  33 checks 0 failing against production; D345's nine qualification and
  suppression scenarios and four authorization cases proven on a throwaway
  cluster. `home_dispatch` is 43 KB and schema-wide, so D345's big function was
  verified for **syntax and the spliced block only** — an honest limit, and the
  owner's screenshot review is still its gate.
- **Database deploy owed:** D345 only, and **not in this window**.
- **Edge deploy owed:** none.
- **Client / TestFlight:** yours.
- **Next owner:** Codex, for the merge and the build.
