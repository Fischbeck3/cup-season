# Mobile Safari catch-up · checkpoint A — Claude handoff for Codex review

Date 2026-09-13. Branch `claude/mobile-safari-experience`, worktree
`~/cup-season-mobile-safari`, base `ee03ce2` (Codex's review checkpoint on
top of `main` = `963d0e6`; the intervening commits are documentation only —
`git diff --stat origin/main ee03ce2` is 8 docs files).

**Candidate for review: `bf61e05`.** Four commits, each with its own
regression; the earlier three are immutable now and Codex can review them
while checkpoint B proceeds on top.

| Commit | What | Regression |
|---|---|---|
| `86fecba` | LINT-14 · the tap test matches its header by role, not by uppercasing (CI on `963d0e6` was red on this) | preflight, baseline 141 → 140 |
| `6d174e0` | **MW-01** · Compete's START SOMETHING opens the intent sheet; the empty root's door too; empty-root doors are 44 tall | `tests/compete-start-browser.js` |
| `73879c6` | **MW-02** · Home on the phone: one lead, a compact strip, a wire that names its league; the season door enters its own league | `tests/home-hierarchy-browser.js` |
| `bf61e05` | **MW-03** · Compete rows say my standing from the dispatch; one status; the empty archive stands down on the phone | `tests/compete-rows-browser.js` |

---

## The working phone preview

| | |
|---|---|
| **Web preview** | **https://deploy-preview-1--cupseason.netlify.app** — Netlify's deploy preview for [PR #1](https://github.com/Fischbeck3/cup-season/pull/1) (draft; not for merging). Opened and read back at 17:35: `#obCaption` `v23 · bf61e05`, `sw.js` `VERSION = 'bf61e05'`. |
| Live web | `https://cupseason.app` — **unchanged at `963d0e6`**. Nothing here is promoted; the preview does not update production. |
| Native source | `963d0e6` + this branch's Swift test fix only (`86fecba`); no native app change in this checkpoint. |
| TestFlight | build 857 archived from `963d0e6`; export still blocked on distribution signing (owner). |

**How the preview path was found.** No Netlify CLI, no site state file and no
documented preview path exist in the repo; branch deploys are not enabled
(`claude-mobile-safari-experience--cupseason.netlify.app` → 404). Deploy
previews for pull requests *are* enabled (Netlify's default), so a draft PR
against `main` produces the URL above and rebuilds on every push to the
branch. That is the existing configured path, verified by reading the stamp,
not assumed.

**Backend target.** The preview is the same single-file client pointed at the
**production** Supabase project (`zddbfcokmvneltrgukzf`) — there is no other
backend in the build. A real sign-in on the preview origin therefore reads and
writes real data, exactly as cupseason.app does. Nothing was written from the
preview in this checkpoint.

**Auth on the preview origin.** Not exercised signed-in: the review profile's
session is bound to the `cupseason.app` origin and does not transfer, and a
fresh code is the owner's to issue. The signed-out door renders on the preview
(captured). Every capture and assertion below on the preview ran against
**labelled fixtures** (`FIXTURE ·` in the names), not the review account.

**Preview-only console noise.** The preview origin logs three report-only CSP
"errors": Netlify's collaboration drawer frames `app.netlify.com`, which our
`Content-Security-Policy-Report-Only` names. It is the drawer, not the app;
production has no drawer and a clean console. The drawer is also the white bar
at the foot of every preview capture.

---

## Findings disposition

| ID | Status | What changed | Evidence |
|---|---|---|---|
| **MW-01** | **fixed** | `#cmpStart` bound to `openIntentSheet` (Home's own door), `preventDefault`, tap recorded as `compete:start`; the empty root's *Start something* goes to the sheet too, not straight to the wizard (which bounced non-Pro members off the D40 gate); `.emptyroot .doors button` min-height 44 (they measured under it at every width). | `compete-start-browser.js`: enters through the rendered tab, clicks the actual link, asserts the sheet and its season row; Escape, the close control and the backdrop each close it with **zero** RPCs; three taps recorded; the season path reaches `#wCreate` exactly once and writes nothing; the empty-root door opens the sheet and never `switchView('wizard')`. Fails on `ee03ce2` at *"START SOMETHING did not open the intent sheet"*; passes at 390/320/1440. |
| **MW-02** | **fixed** (hierarchy + duplicates + wrong-league door) | Below 960 `#homeHub` is a flex column and `.deskmain` is `display:contents`, ordered: lead → compact strip → wire → hero → recent golf (`.deskwire`) → doors → up next → occasion → tiles → pulse. The desk grid ≥960 is untouched. `#homeMe` renders the compact strip (number, last round, season row); `#sideMe` keeps the full strip; suppression unchanged. `csWireArrange`: exact duplicates (headline + `league_id`) collapse to one; a headline shared across leagues gets its league name (`.lc`, agate) from `homeDispatch.me.memberships`, then boot memberships, then the eyebrow's first segment. `csItemDoor('season')` enters the item's league by id (the Compete row's rule) instead of `switchView('hub')`. | `home-hierarchy-browser.js`: fixture dispatch with the duplicate and the shared sentence → 3 rows, two names, none on the story; both season doors land on the right league; narrow strip has no `my_money`/`my_next_round`, sidebar still has money; box order at 390/320 and two columns at 1440. Fails on `ee03ce2` at *"the wire has 4 rows, not 3"*. The duplicate was independently observed on the review account's real Home (two `chapter:` items, both "You are the one to catch."). |
| **MW-03** | **fixed** (rows + archive chrome) | `csCompeteFacts()` joins `homeDispatch.me.memberships[]` by `league_id`; `csSeasonRowFacts` renders `2nd of 2 · 14 pts · 3 behind Jade` under `In season · Week 8 of 26`, plus one status (`The clash closes today` / `3 days left`); a leader reads `leading`; the Pro's row adds `you run it`. No standing → the plain sentence; no rank is ever rendered as first; a forming league borrows nothing; no point is computed. The empty Finished shelf gets `data-empty` and hides below 960; it returns with a finished season; the desk column stays. | `compete-rows-browser.js`: four memberships against a fixture dispatch, every line and status asserted verbatim, the shelf hidden at 390/320 and present at 1440, back with a finished season, every row ≥ 44. Fails on `ee03ce2` at *"the standing line is wrong: You're in it."* |
| **MW-07** | **partial** | Compete's rows now carry the standing in the mono column role, the status in the ember clock colour (a word, never a control), the archive chrome gone at phone widths, tap targets at 44. The header mark, tile radii and the rest of the consistency pass are **not** done here — the narrow header is also the identity plan's surface (D339 web half, I-1), so it moves once, not twice. | — |
| MW-04, MW-05, MW-06 | **not started** — checkpoint B | | |

---

## Evidence

Commands, all from the worktree at `bf61e05`:

```sh
npm run preflight                                        # PASS — 0 failures, 0 warnings
python3 -m http.server 8794 &
for t in compete-start-browser home-hierarchy-browser compete-rows-browser \
         home-function-browser after-golf-repairs-browser app-tests league-setup-browser; do
  node tools/web-verify.mjs --url 'http://127.0.0.1:8794/?exit' --widths <390|320|1440> \
    --wait 1500 --eval "$(cat tests/$t.js)"; done
```

| Suite | 390 | 320 | 1440 |
|---|---|---|---|
| `compete-start-browser.js` (new) | passed | passed | passed |
| `home-hierarchy-browser.js` (new) | passed | passed | passed |
| `compete-rows-browser.js` (new) | passed | passed | passed |
| `home-function-browser.js` | passed | — | — |
| `after-golf-repairs-browser.js` | passed | — | — |
| `app-tests.js` | 461, zero failures | — | — |
| `league-setup-browser.js` | 20 checks | — | — |

Console clean but for the known lines; nothing scrolls horizontally at any
width. Each new suite was also run against a served copy of `ee03ce2`'s
`index.html` and fails there at the message named above — the regressions
are regressions, not descriptions of the new screen.

**Before/after captures at 390** (fixtures, labelled; local, not committed —
public repo): `…/scratchpad/caps/{before,after}-{home,compete,compete-sheet}/page-390.png`.
What the after-captures show on the preview origin: Home leads with *"Jade has
today to answer your 84."* and its receipt door, then `11.4 YOUR NUMBER · 84
SAT`, then the wire with *Who's the bitch?* and *Fellas* named above their
shared sentence, then *Around your buddies*, then *Start something else…*;
Compete shows three rows with standings and statuses and no Finished shelf;
the sheet capture shows *What do you want to do?* open over Compete after the
real control was tapped.

**Actual iPhone Safari: not done.** Everything above is Chromium at mobile
viewports. Safe areas, the keyboard, VoiceOver, large text and light mode on
a real phone are outstanding, and the owner can now open the preview URL on
one.

---

## Next

- **Codex** reviews `bf61e05` (or any of its three predecessors) in an
  isolated worktree; findings return here and I fix them on this branch.
- **Claude** continues to checkpoint B on top of `bf61e05`: MW-04 (season
  page), MW-05 (posting hierarchy and the solo/squad copy), MW-06 (setup copy
  and progress).
- **Identity** (D339 web half) is prepared separately on `claude/d339-web-half`
  per Codex's review corrections — door **and** narrow masthead together, as
  a labelled preview, without replacing the production mark until approved.
- **Signed-in preview check**: when the owner is ready to issue a code, the
  same walk runs on the preview origin against the review account.
