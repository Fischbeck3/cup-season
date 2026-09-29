# Panel · the §29 three-judge panel: the web in rounds 1 and 2, and the native half

| | |
|---|---|
| **Measured at** | web **`9d84c483`**. `play`, `receipt`, `record`, `you`, `golfers` and `book` were judged from their `9d84c483` captures; every other family from `02636007`, whose web client renders them byte-identically (COVERAGE.md §1.1). Native **`4112a3f0`**, Owner TestFlight 1.0.0 (1180), judged from `native-4112/` (COVERAGE.md §2). |
| **Status read at** | **`7b9c17e4`**, live on the web since 03:53 MST on 2026-09-29; Owner TestFlight 1335 comes from the same SHA. Round 2's judges read `fd27ace4`, and `ed8e6837` for home, compete, desk, courses and you. |
| **Date** | 2026-09-28; round 2 added 2026-09-29 |
| **Assessors** | the **category**, **craft** and **owner** judges: three fresh agents that wrote no code. Their calibration stays with root, which ran the same three on the native half and on round 2. Round 2's delta: session D's six checkers **G1–G6** re-read every round-1 defect and every round-1 cell below 9 at `ed8e6837`. |
| **Raw evidence (outside git)** | Web: `~/cup-season-claude-ten-gallery/evidence/panel/{category,craft,owner}.{json,md}`, citing captures in `~/cup-season-claude-ten-gallery/root/harness-9d84c483/`. Native: `…/evidence/panel/{category,craft,owner}-native.{json,md}`, citing captures in `~/cup-season-claude-ten-gallery/native-4112/`. Round 2: `…/evidence/r2-fd27ace4/panel/` and the delta, `…/r2-fd27ace4/delta/` (`DELTA.md`, `DELTA-panel-cells.md`, `DELTA.json`, and the checkers' `G1.md`–`G6.md`). |

Written by session C (docs). The scores and sentences below are the judges', copied from their JSON. Two strings are redacted with bracketed tokens: `[course]` stands for a fixture course that borrows a real course's name, and `~/` for the local home directory. The judges' proposed "change" for every cell is in the JSON; this file gives what stands between each cell and 10, and its kind.

**The gate** (SESSIONS §1): no cell below 9, and a mean of at least 9.5, on every row, from every judge.
**Round 1: not met anywhere.** On the web no row reaches 8 with any judge, and 649 of the 660 cells are below 9. On the phone no row reaches 9, and 483 of the 510 scored cells are below 9 (§5).

## Round 2 (web)
The judges re-scored the web at `fd27ace4`, with `ed8e6837` (the shipped client) for home, compete, desk, courses and you. Their files are `~/cup-season-claude-ten-gallery/evidence/r2-fd27ace4/panel/`. **All three have reported.**

**The gate is still not met.** One row reaches 9 with one judge: support at 9.1 with craft. No row has every cell at 9 from every judge, and no product mean reaches 9.5.

| Row | Category r1 | Category r2 | Craft r1 | Craft r2 | Owner r1 | Owner r2 |
|---|---:|---:|---:|---:|---:|---:|
| `web/door` | 6.5 | 6.9 | 7.8 | **8.4** | 7.5 | 7.8 |
| `web/home` | 6.3 | 7.5 | 6.2 | **8.1** | 7.1 | **8.0** |
| `web/post` | 6.3 | 7.2 | 5.9 | 7.9 | 6.2 | 7.8 |
| `web/share` | 7.4 | **8.0** | 7.5 | **8.7** | 7.1 | **8.1** |
| `web/public-round` | 6.6 | 7.6 | 7.2 | **8.6** | 7.0 | 7.9 |
| `web/claim-invite` | 6.0 | 7.2 | 6.8 | **8.2** | 6.9 | 7.9 |
| `web/identity` | 6.3 | 7.8 | 6.7 | **8.0** | 6.8 | 7.9 |
| `web/golfers` | 6.3 | 7.0 | 6.7 | 7.9 | 7.1 | 7.5 |
| `web/history` | 6.9 | 7.5 | 7.2 | **8.2** | 7.4 | **8.1** |
| `web/season` | 7.2 | 7.9 | 6.9 | **8.1** | 7.6 | **8.1** |
| `web/competition` | 6.4 | 7.5 | 7.0 | **8.3** | 7.2 | **8.1** |
| `web/events` | 6.4 | **8.0** | 7.0 | **8.8** | 7.6 | **8.2** |
| `web/schedule` | 5.0 | 7.3 | 6.1 | **8.1** | 6.4 | 7.7 |
| `web/wizard` | 5.4 | 7.2 | 6.1 | 7.9 | 6.3 | 7.9 |
| `web/courses` | 7.5 | 7.6 | 7.5 | 7.7 | 7.3 | 7.7 |
| `web/settings` | 6.1 | 7.2 | 6.5 | **8.1** | 7.2 | 7.9 |
| `web/play` | 6.1 | 7.4 | 6.2 | **8.2** | 7.0 | 7.8 |
| `web/rules` | 6.8 | 7.5 | 7.1 | **8.0** | 7.2 | 7.9 |
| `web/get` | 6.2 | 7.1 | 7.6 | **8.9** | 7.3 | **8.1** |
| `web/support` | 6.8 | 7.5 | 7.5 | **9.1** | 7.4 | **8.2** |
| `web/legal` | 6.5 | 7.2 | 7.0 | **8.8** | 7.3 | 7.9 |
| `web/desk` | 6.7 | 7.6 | 6.6 | **8.2** | 7.1 | **8.1** |
| **product mean** | 6.44 | **7.44** | 6.87 | **8.28** | 7.09 | **7.94** |

**Keep rows** (a mean of 8 or more), shown in bold:
- craft: **18 of 22**; only post (7.9), golfers (7.9), wizard (7.9) and courses (7.7) remain polish;
- owner: 9 (home, share, history, season, competition, events, get, support and desk);
- category: 2 (share and events).

**Cells at 10** (craft, 12): public-round T; get H, Sp, C and R; support H, Sp, R and D; legal Sp, R and D.

**Round 2's P0 and P1:**

| Judge | Pri | Defect | Status at `7b9c17e4` |
|---|---|---|---|
| category | **P0** | The public plan link says "Avery and Devon are in." while the plan's own sheet says Avery is ASKED: `the_plan_link.sql` counts an unanswered tag as in | **fixed on the client (09beefd3)**. The landing and the signed-in ask say "Avery and Devon are on the plan." (one producer, `csPlanWhoLine`), which is what the payload can support. The in-app half is fixed (f46086b4). **Open:** the database half, X42, a migration the owner must `db push`. |
| owner | P1 | The same plan-link defect: attendance inferred from an invitation | fixed on the client (09beefd3); X42 open |
| craft | P1 | The golfer page's course rows collide: "LAST PLAYED SEP 20" and "2 ROUNDS" read "SEP 202 ROUNDS" (owner P2 too) | **fixed (41cf8050)**: `.dtab`'s right column takes `--s4` |
| owner | P1 | The rivalry record still contradicts itself across surfaces, unchanged since round 1 | **decision X36** |
| category | P1 | At `fd27ace4` a course row on You could not be opened (a regression from W2's `<details>` door, found by session D) | **fixed (5df6d4cc)**, verified in `ed8e6837`'s recapture |

**Fixed from session D's round-2 deltas:**
- the dead league link at 375×380, a P1 regression: the notice is now the landing, and no email box opens (41cf8050);
- the covenant's "Custom rules, built on Standard" for a customised league (crit:A:wizard:1, 3d3b9e55);
- the live game picker's edge fade, a P2 regression that hid the fifth game (c1b70890);
- the Door's example wings stilled (crit:A:door:1, 7141516f).

**Round 2's P2s:**
- The person page's course rows collide into "SEP 202 ROUNDS" (owner). **Fixed (41cf8050).**
- The card gate at 375: the pinned "Save my card" bar covers the marker helper line (craft). A defect, open.
- The desk course book: the tee select clips its value, and the plate squeezes a four-line title (craft). A defect, open.
- The covenant sheet at 375 stops short of the screen, so the page's links show beneath its Join (craft). A defect, open.
- Home's clash lead never says who holds the week (owner). It is server copy: Q10.
- Home repeats "… have played here" under nearly every wire card (owner; L-34, D360). A defect, open.
- Two records for one pair (category): X36.
- The receipt with an unopenable photo stacks five buttons under a checkbox (category). A defect, open.
- The phone Door shows no product (category): Q6.
- The person page buries the credential about 960px down on the phone (category). A defect, open.

### The delta: round 1's defects and cells, re-read at `ed8e6837`
Session D's six checkers (G1–G6) re-read every round-1 P0/P1 defect and every round-1 cell below 9. They used the round-2 captures, pixels, source and git, with no browser (`r2-fd27ace4/delta/DELTA.md`; every cell is in `DELTA-panel-cells.md`).
- **The judges' 15 P0/P1 defects (§3):** 12 resolved, 2 open and 1 regressed.
  - Open: #6, the public plan's "in" (X42), and #15, the rivalry record (X36).
  - Regressed: #13, the dead league code at 375×380, fixed after the candidate (41cf8050).
- **The 649 cells below 9:** 315 resolved, 332 open and 2 regressed.
  - Regressed: identity M (category), where the card gate's sticky "Save my card" now covers the marker sentence at 375. It is open (also AW2-21).
  - Regressed: play Sp (craft), where the game picker hid the fifth game at 375. Fixed after the candidate (c1b70890).

The checker verifies the defect round 1 named; the round-2 judge re-scores the whole cell. So a cell can be resolved and still below 9 (the judge found another blocker), or open and at 9 (the judge passed it with the named defect still visible). D's cross-table:

| Judge | Cells below 9 in round 1 | Round 2 ≥ 9 | Round 2 < 9 | Round 2 lower than round 1 | Resolved and ≥ 9 | Resolved and < 9 | Open and ≥ 9 |
|---|---:|---:|---:|---:|---:|---:|---:|
| category | 218 | 6 | 212 | 0 | 6 | 75 | 0 |
| craft | 214 | 87 | 127 | 1 | 52 | 55 | 35 |
| owner | 217 | 19 | 198 | 0 | 15 | 112 | 4 |

§6 gives each cell's round-2 score and the checker's verdict.

## 1 · Summary

| Judge | Product mean (web) | Rows ≥ 9 | Rows ≥ 8 | Verdicts (keep · polish · redesign) | Cells < 9 of 220 | Lowest row | Highest row |
|---|---:|---:|---:|---|---:|---|---|
| category | **6.44** | 0 | 0 | 0 · 20 · 2 | 218 | `web/schedule` 5.0 | `web/courses` 7.5 |
| craft | **6.87** | 0 | 0 | 0 · 21 · 1 | 214 | `web/post` 5.9 | `web/door` 7.8 |
| owner | **7.09** | 0 | 0 | 0 · 22 · 0 | 217 | `web/post` 6.2 | `web/season` 7.6 |

**Across the three judges:** product mean **6.80** (6.44 · 6.87 · 7.09). Three rows are "redesign" to one judge each: `web/schedule` (5.0) and `web/wizard` (5.4) to the category judge, and `web/post` (5.9) to the craft judge.

### Dimension means
Each judge's mean of the 22 rows per dimension. The owner judge's JSON carries no dimension means, so all three are computed here from the rows.

| Judge | H (visual hierarchy) | T (typography) | Sp (spacing) | C (consistency) | B (brand identity) | P (premium feel) | R (readability) | E (emotional appeal) | D (information density) | M (mobile usability) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| category | 6.68 | 6.86 | 6.68 | 5.50 | 6.64 | 5.64 | 7.27 | 5.64 | 6.27 | 7.23 |
| craft | 7.27 | 6.73 | 7.05 | 6.05 | 7.05 | 6.50 | 7.68 | 6.05 | 6.95 | 7.36 |
| owner | 7.23 | 7.68 | 7.36 | 6.23 | 7.55 | 6.91 | 6.91 | 6.77 | 6.77 | 7.50 |

**Consistency (C) is the lowest column, or tied for it, with all three judges. Emotional appeal (E) is within the two lowest with all three.** Category ties E with premium feel (P) at 5.64; craft ties C with E at 6.05; owner ties E with information density (D) at 6.77. Category C at 5.50 is the lowest dimension mean on the panel.

## 2 · Rows

`Mean of three` is the plain mean of the three row means. `Cells < 9` counts that judge's ten cells. `Lowest cell` names every judge and dimension at the row's minimum. The lane column follows LEDGER §4f's lane list: W1 composer, play, receipts; W2 schedule, the Ryder/Major room, You, settings; W3 Home, Golfers; W4 share, public pages, links, get/support/legal; W5 Compete, the Book, the wizard. Root owns the rest; W6 (session B) owns shared producers and chrome.

| Row | Category | Craft | Owner | Mean of three | Verdicts (cat · craft · owner) | Cells < 9 (cat · craft · owner) | Lowest cell | Lane (LEDGER §4f) |
|---|---:|---:|---:|---:|---|---|---|---|
| `web/door` | 6.5 | 7.8 | 7.5 | 7.27 | polish · polish · polish | 10 · 9 · 10 | 5 (cat E, cat D) | root (no lane) |
| `web/home` | 6.3 | 6.2 | 7.1 | 6.53 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C, cat P, cat D, cra C, cra D) | W3 |
| `web/post` | 6.3 | **5.9** | 6.2 | 6.13 | polish · redesign · polish | 10 · 10 · 10 | 5 (cat P, cra C, cra P, cra E, own C, own P, own R) | W1 |
| `web/share` | 7.4 | 7.5 | 7.1 | 7.33 | polish · polish · polish | 10 · 10 · 9 | 6 (cat C, cat P, cra C, own C, own D) | W4 |
| `web/public-round` | 6.6 | 7.2 | 7.0 | 6.93 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C) | W4 |
| `web/claim-invite` | 6.0 | 6.8 | 6.9 | 6.57 | polish · polish · polish | 10 · 10 · 10 | 5 (cat H, cat C, cat P, cat E) | W4 |
| `web/identity` | 6.3 | 6.7 | 6.8 | 6.60 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C, cat D, cra C, cra D, own C, own D) | W2 |
| `web/golfers` | 6.3 | 6.7 | 7.1 | 6.70 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C, own C) | W3 |
| `web/history` | 6.9 | 7.2 | 7.4 | 7.17 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C) | W1 (receipts), W2 (the record on You) |
| `web/season` | 7.2 | 6.9 | 7.6 | 7.23 | polish · polish · polish | 9 · 10 · 9 | 5 (cat C, cra C) | root (no lane) |
| `web/competition` | 6.4 | 7.0 | 7.2 | 6.87 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C) | W5 |
| `web/events` | 6.4 | 7.0 | 7.6 | 7.00 | polish · polish · polish | 10 · 10 · 9 | 5 (cat C) | W2 |
| `web/schedule` | **5.0** | 6.1 | 6.4 | 5.83 | redesign · polish · polish | 10 · 10 · 10 | 4 (cat C) | W2 |
| `web/wizard` | **5.4** | 6.1 | 6.3 | 5.93 | redesign · polish · polish | 10 · 10 · 10 | 4 (cat C) | W5 |
| `web/courses` | 7.5 | 7.5 | 7.3 | 7.43 | polish · polish · polish | 10 · 10 · 10 | 6 (cat E, cra E, own D) | root (no lane) |
| `web/settings` | 6.1 | 6.5 | 7.2 | 6.60 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C, cat B, cat P, cat E, cra E) | W2 |
| `web/play` | 6.1 | 6.2 | 7.0 | 6.43 | polish · polish · polish | 10 · 10 · 10 | 5 (cat C, cat P, cat E, cat M, cra C, cra M) | W1 |
| `web/rules` | 6.8 | 7.1 | 7.2 | 7.03 | polish · polish · polish | 9 · 9 · 10 | 5 (cat E, cra E) | root (no lane) |
| `web/get` | 6.2 | 7.6 | 7.3 | 7.03 | polish · polish · polish | 10 · 8 · 10 | 4 (cat B, cat P, cat E) | W4 |
| `web/support` | 6.8 | 7.5 | 7.4 | 7.23 | polish · polish · polish | 10 · 9 · 10 | 5 (cat B, cat P) | W4 |
| `web/legal` | 6.5 | 7.0 | 7.3 | 6.93 | polish · polish · polish | 10 · 9 · 10 | 4 (cat E) | W4 |
| `web/desk` | 6.7 | 6.6 | 7.1 | 6.80 | polish · polish · polish | 10 · 10 · 10 | 6 (cat Sp, cat C, cat P, cat E, cat D, cra Sp, cra C, cra P, cra E, cra D, own C, own D) | each lane for its own surfaces; shared chrome W6 (session B) |

## 3 · The judges' P0 and P1 defects, with status

*fixed (sha)* means the commit message or diff shows the fix; for a lane, the lane's own commit names it, and the sha is its merge. Each row ends with session D's round-2 verdict at `ed8e6837` (the delta's `pdef` items).

| # | Judge | Pri | Row | Defect (the judge's words, shortened) | Captures | Status at `7b9c17e4` |
|---|---|---|---|---|---|---|
| 1 | category | **P0** | home | A nine-hole 43 is announced "Broke 80 for the first time." on Home, the golfer's own feed and every buddy's. `home_feed.is_sub80` has no `holes_played = 18` guard (`20261020090000_one_round_one_number.sql`). | `home--league-less-rounds_no_buddies--375--dark.png` | **fixed in part (e8108e59).** The web claims sub-80 only for a round known to be 18 holes, and a known nine reads "9 HOLES" (2dce66e6). **Open:** the server half, X41 (owner's `db push`). The phone's guard is fixed too (146401bb: 5404441a). **Round 2: resolved**. |
| 2 | category | P1 | home | The Home photo round card is broken at every width and theme: the reactions foot is an opaque band across the photograph, the icons stack, and the course door is clipped (`.hsfoot`). | `home--member--375--dark.png`, `home--member--1280--dark.png` | **fixed (e8108e59)**: a plate on a bottom-anchored scrim, with one foot row under it (2dce66e6) **Round 2: resolved**. |
| 3 | category | P1 | wizard | Desk wizard step 3 "Review the rules" shows no rules (`#bylawsReview` hidden at ≥1100px). | `wizard--step-3-review--1280--light.png` | **fixed (38471687)**: the review shows on the desk **Round 2: resolved**. |
| 4 | category | P1 | identity/history | EVERY SEASON prints live seasons under FINISH as "1ST"/"2ND" with the podium rule, a standing presented as a finish (`csRecordLeaf`). | `you--populated--375--dark.png`, `record--populated--375--dark.png` | **fixed (f46086b4)**: a live season has no finish; it reads "In play" with its standing in its own line, and the podium mark is a finished season's (35b4f475) **Round 2: resolved**. |
| 5 | category | P1 | identity | FORM marks a nine-hole 43 as the best of the last five, in gold (`formRowHtml`). | `you--populated--375--dark.png` | **fixed (38471687)**: a nine never takes the gold and reads "NINE"; the phone twin is 74997409 (N2). W2 adds gold only among two or more comparable rounds (f46086b4). **Round 2: resolved**. |
| 6 | category | P1 | schedule | The public plan link says "Avery and Devon are in." while the plan sheet shows Avery NO REPLY; `the_plan_link.sql` counts a missing RSVP as in. | `schedule--plan-landing--375--dark.png`, `schedule--plan-sheet--375--dark.png` | **fixed in part (f46086b4, 09beefd3).** In the app, "in" is an explicit yes and an unanswered tag reads Asked (57325028). The public card now says "on the plan", which the payload supports (09beefd3). **Open:** X42, so that the card can say "in" again truthfully (owner's `db push`); the phone's `ScheduleScreen` is N4's. **Round 2: open** (the client half came after, 09beefd3; X42 is owed). |
| 7 | craft | P1 | wizard | The review's "Start the season" is disabled with no reason on screen. | `wizard--step-3-review--375--dark.png` | **fixed (38471687)**: `#lockWhy` says why, with a door to the pay note **Round 2: resolved**. |
| 8 | craft | P1 | settings | "Delete permanently" is white on `#FF6A5E`, 2.81:1 in the default dark theme. | `settings--delete-confirm--375--dark.png` | **fixed (38471687)** **Round 2: resolved**. |
| 9 | craft | P1 | play | Light desk live scoring: the selected HOLE segment is 2.37:1. | `play--scoring--1280--light.png` | **fixed (38471687)** **Round 2: resolved**. |
| 10 | craft | P1 | identity | The Form row gilds the nine-hole 43 against 18-hole grosses. | `you--populated--375--dark.png` | **fixed (38471687)** (as #5) **Round 2: resolved**. |
| 11 | owner | P1 | post | The composer prints "+1.4" over "YOUR PLAYING HCP", so a 14.2 golfer reads a plus handicap on every post. A second top-level `vsShort` shadowed the words form. | `composer--filled--375--dark.png` | **fixed (38471687, 1e9eb856)**: the figure reads "beat by 1.4" again, and the signed form is `vsSigned`, used only on the clash and the receipt row. The label now reads "vs your playing HCP" (R-M; 1e9eb856: 84983c4c). **Open:** no preflight check catches a duplicate top-level function. **Round 2: resolved**. |
| 12 | owner | P1 | share | The finish ceremony offers "Include round photo" on rounds with no photograph (`.finish-photoopt{display:flex}` beats `hidden`). | `share--recap-no-photo--375--dark.png` | **fixed (38471687)**: `[hidden]` always hides **Round 2: resolved**. |
| 13 | owner | P1 | claim-invite | A join code that resolves to no league tells a stranger "You're invited. Sign in to review the league before you join." | `links--join-unavailable--375--dark.png` | **fixed (38471687)**: "No league with that code. Check with your Pro.", from one producer **Round 2: regressed** (fixed after, 41cf8050). |
| 14 | owner | P1 | wizard | On the desk, "Review the rules" shows no rules, and the aside reads "FORMING — THE RULES AREN'T SET YET". | `wizard--step-3-review--1280--light.png` | **fixed (38471687)** (as #3). The aside's "forming" line is open, verification pending: W5's merge (`4a703402`) reworked the portrait without naming it. **Round 2: resolved**. |
| 15 | owner | P1 | golfers/identity/schedule | The rivalry verdict contradicts itself: "3–4 · THEY LEAD" on You and "leads 4–3" on the plan, but "All square, 5–5" on the person page. | `you--populated--375--dark.png`, `golfers--person--375--dark.png` | **decision X36** (OWNER-QUESTIONS). W3 changed the person page's words ("All square between you, 5–5.", 3324ae89), but which facet each surface shows is still the question. **Round 2: open** (X36). |

**Tally at `7b9c17e4`:** 15 defects. Round 2's checkers found 12 resolved at `ed8e6837`, 2 open (#6, #15) and 1 regressed (#13, fixed after the candidate).
- **fixed: 12.** #2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14. #11 keeps the preflight check as a residual; #14 keeps the aside's "forming" line.
- **fixed in part: 2.** #1 waits on X41 alone, since its phone half is fixed (5404441a). #6 waits on X42 and N4.
- **decision: 1.** #15 (X36).

The judges' P2 and P3 defects (category 22 + 16, craft 23 + 10, owner 23 + 22) are listed in their `.md` files. Lanes W1–W5 were briefed on them. Round 2 re-read them only through the cells that cite them.

## 4 · The 649 cells below 9, by kind

| Kind | Category | Craft | Owner | All |
|---|---:|---:|---:|---:|
| defect | 173 | 172 | 164 | 509 |
| content | 14 | 25 | 41 | 80 |
| decision | 18 | 7 | 7 | 32 |
| device-or-human | 13 | 10 | 5 | 28 |
| **all** | **218** | **214** | **217** | **649** |

- **defect (509):** a visible defect with a capture. These are the lanes' work (LANE-BRIEF).
- **content (80):** the words or data on the surface. These are the lanes' work too, but a change to a ruled sentence needs the ruling that owns it.
- **decision (32):** the judge named a ruling the owner has not made, or called the genre itself the ceiling ("It is a rules page"). They are grouped as questions in OWNER-QUESTIONS.md §C. The largest group is the genre ceiling on settings, rules, support and legal (Q9).
- **device-or-human (28):** motion, haptics, real photographs, real keyboards and the OTP round trip. No capture can raise these; HUMAN.md does.

## 5 · Native half (measured at `4112a3f0`, TestFlight 1180)

The same three judges scored the phone with the calibration they used on the web. Root forwarded it on 2026-09-28.
- **Not scored:** `native/door` is not captured (the signed-out Door is not in the synthetic plan), and `native/public-round` has no native surface (web only). Neither counts toward the means.
- **The web fixes are not in this build:** 1180 is `cf401dee`'s native tree. N2's fixes merged at `de3eaf35`, after it.

### Summary

| Judge | Product mean (native, 17 scored rows) | Web mean | Rows ≥ 9 | Rows ≥ 8 (keep) | Verdicts (keep · polish · redesign · not captured) | Cells < 9 of 170 | Lowest row | Highest row |
|---|---:|---:|---:|---:|---|---:|---|---|
| category | **7.04** | 6.44 | 0 | 0 | 0 · 17 · 0 · 2 | 167 | `native/schedule` 6.2 | `native/share` 7.8 |
| craft | **7.42** | 6.87 | 0 | 2 | 2 · 15 · 0 · 2 | 155 | `native/post` 6.4 | `native/season` 8.3 |
| owner | **7.77** | 7.09 | 0 | 3 | 3 · 14 · 0 · 2 | 161 | `native/claim-invite` 7.3 | `native/events` 8.2 |

The phone scores higher than the web with every judge (by 0.60, 0.55 and 0.68), and craft and owner each keep rows the web never reached. No row reaches 9, so the gate is not met on the phone either.

### Dimension means (17 scored rows)

| Judge | H | T | Sp | C | B | P | R | E | D | M |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| category | 7.41 | 7.47 | 7.12 | 6.29 | 7.29 | 6.71 | 7.41 | 6.41 | 7.24 | 7.06 |
| craft | 7.94 | 7.71 | 7.24 | 7.29 | 8.18 | 7.59 | 7.41 | 6.47 | 7.82 | 6.59 |
| owner | 7.94 | 8.12 | 7.88 | 7.24 | 8.06 | 7.82 | 7.53 | 7.88 | 7.88 | 7.35 |

Category's two lowest columns are consistency (6.29) and emotional appeal (6.41), as on the web. Craft's are emotional appeal (6.47) and mobile usability (6.59); owner's are consistency (7.24) and mobile usability (7.35).

### Rows

**Bold** marks a mean of 8 or more, a keep verdict.

| Row | Category | Craft | Owner | Mean of three | Verdicts (cat · craft · owner) | Cells < 9 (cat · craft · owner) | Lowest cell |
|---|---:|---:|---:|---:|---|---|---|
| `native/door` | — | — | — | — | not captured · not captured · not captured | — | not scored |
| `native/home` | 7.4 | **8.1** | 7.9 | 7.80 | polish · keep · polish | 10 · 7 · 10 | 7 (cat H, cat Sp, cat C, cat P, cat E, cat M, cra E, cra M, own C) |
| `native/post` | 6.6 | 6.4 | 7.4 | 6.80 | polish · polish · polish | 10 · 10 · 10 | 5 (cra M) |
| `native/share` | 7.8 | 6.9 | 7.9 | 7.53 | polish · polish · polish | 10 · 10 · 9 | 6 (cra Sp, cra C, cra E) |
| `native/public-round` | — | — | — | — | not captured · not captured · not captured | — | not scored |
| `native/claim-invite` | 6.5 | 6.8 | 7.3 | 6.87 | polish · polish · polish | 10 · 10 · 10 | 6 (cat Sp, cat C, cat B, cat P, cat E, cra T, cra C, own C) |
| `native/identity` | 7.5 | 7.4 | 7.8 | 7.57 | polish · polish · polish | 9 · 9 · 9 | 6 (cat C, cra C, cra M) |
| `native/golfers` | 6.6 | 7.2 | 7.8 | 7.20 | polish · polish · polish | 10 · 10 · 9 | 5 (cat C) |
| `native/history` | 7.2 | 7.3 | **8.0** | 7.50 | polish · polish · keep | 10 · 9 · 8 | 5 (cat C) |
| `native/season` | 7.5 | **8.3** | **8.0** | 7.93 | polish · keep · keep | 9 · 6 · 8 | 6 (cat C) |
| `native/competition` | 6.3 | 7.4 | 7.7 | 7.13 | polish · polish · polish | 10 · 9 · 10 | 5 (cat C) |
| `native/events` | 7.2 | 7.9 | **8.2** | 7.77 | polish · polish · keep | 10 · 8 · 8 | 6 (cat C) |
| `native/schedule` | 6.2 | 7.2 | 7.7 | 7.03 | polish · polish · polish | 10 · 10 · 10 | 6 (cat H, cat T, cat C, cat B, cat P, cat R, cat E, cat D, cra M) |
| `native/wizard` | 6.5 | 7.2 | 7.6 | 7.10 | polish · polish · polish | 10 · 10 · 10 | 6 (cat Sp, cat B, cat P, cat E, cat M, cra E, cra M, own M) |
| `native/courses` | 7.8 | 7.6 | 7.8 | 7.73 | polish · polish · polish | 10 · 9 · 10 | 6 (cra R, cra E) |
| `native/settings` | 6.9 | 7.6 | 7.8 | 7.43 | polish · polish · polish | 10 · 10 · 10 | 5 (cat E) |
| `native/play` | 6.7 | 7.5 | 7.5 | 7.23 | polish · polish · polish | 10 · 10 · 10 | 6 (cat B, cat P, cat E, cra E) |
| `native/rules` | 7.3 | 7.8 | 7.8 | 7.63 | polish · polish · polish | 9 · 9 · 10 | 5 (cat E) |
| `native/widgets` | 7.7 | 7.6 | 7.9 | 7.73 | polish · polish · polish | 10 · 9 · 10 | 6 (cat C, cra M) |

### The native P0 and P1 defects, with status

No judge raised a P0. The six P1 entries are four distinct defects.

| # | Judge | Row | Defect (the judge's words, shortened) | Captures | Status at `7b9c17e4` |
|---|---|---|---|---|---|
| N-1 | category, craft | identity | FORM gilds a nine-hole 43 as the best of the last five beside 18-hole grosses, and VoiceOver calls it "their best" (craft); the web's twin defect | `17pro/tourcard-dark-large.png`, `17pro/person-me-dark-large.png` | **fixed (de3eaf35)**: N2's 74997409: a nine never takes the gold, and a nine says so; tests ab3d1cac. Not in 1180; verification pending. |
| N-2 | category | history | The record prints two LIVE seasons (week 6 of 13, week 4 of 10) under FINISH as "2ND" with the podium rule; the web's twin defect | `17pro/record-dark-large.png`, `se3/record-light-large.png` | open · in lane N4 (not in E's phase 1, `6716b0ed`). The web twin is fixed (f46086b4: "In play"). |
| N-3 | craft | post | A refused or failed post shows no message: the composer's toast is drawn by the app-root host beneath the Play full-screen cover, for every composer failure (`PostRoundModel.swift:541`, `CupSeasonApp.swift:76`, `MainTabView.swift:1043`) | `flows/flow__post-failed.png` | **fixed (146401bb: 678b1868)**: said inline above Add my round, and every cover has its own toast host; in TestFlight 1335. The web twin, CQ-09, is fixed at 1e9eb856. |
| N-4 | craft, owner | post | At AX3 the composer scrolls the focused gross field off screen with the keypad up, and content slides under the status bar: the golfer types a score they cannot see | `17pro/composer-light-AX3.png`, `se3/composer-dark-AX3.png` | **fixed (146401bb: bf67db31)**: at the accessibility sizes the gross field anchors at the top of the scroll; in TestFlight 1335 |

The judges' P2 and P3 counts: category 19 + 12, craft 24 + 5, owner 7 + 17. They are listed in the `-native.md` files.

### The 48 flagged `failed.json` rows

All three judges read every flagged row as rendering correctly. The owner judge gives a verdict per route:

| Route | Flag | The owner judge's verdict |
|---|---|---|
| `story` | FAIL (root), 8 | Renders correctly on every pass: the page draws "THE STORY" in display caps, and the runner looked for "The story" (a case-sensitive check). |
| `course-wholecard` | unanswered requests, 8 | Renders correctly: both nines, the offline note and the tee line. |
| `whenfork` | unanswered requests, 8 | Renders correctly: the sheet over Home with its two options ("RIGHT NOW" pre-tinted ember, a P3). |
| `invite-signedin` | unanswered requests, 8 | Renders correctly: the full covenant, wrapping whole at AX3. |
| `rules` | unanswered requests, 8 | Six render whole. The two 17 Pro large frames (dark and light) were caught mid-push. Capture timing, not rendering. |
| `season-ceremony` | unanswered requests, 8 | Renders correctly. Its money mismatch is fixture composition. |

The craft judge adds two coverage notes, which match COVERAGE.md §2.4:
- `home-long` is pixel-identical to `home-populated`, so the long-name stress is not evidenced;
- `album-failed` on the SE 3 at the default size shows the populated album.

### Fixture artifacts (not scored)
- The ceremony's payouts exceed what was collected (D106).
- The season story files a headline under week 2.
- Blake's round counts disagree between places.

These are the synthetic world's composition, not product defects. FX's fixture owner should correct them before round 2, or they will be read again.

### Cells below 9, by kind (native)

| Kind | Category | Craft | Owner | All |
|---|---:|---:|---:|---:|
| defect | 113 | 107 | 111 | 331 |
| content | 29 | 16 | 35 | 80 |
| decision | 8 | 4 | 3 | 15 |
| device-or-human | 17 | 28 | 12 | 57 |
| **all** | **167** | **155** | **161** | **483** |

- **device-or-human (57):** more than twice the web's share. Motion, haptics, Dynamic Type on a device, VoiceOver speech and outdoor light cannot be judged from rest frames. HUMAN.md's D1–D13 are their evidence.
- **decision (15):** they join OWNER-QUESTIONS §C where they repeat a web question (the genre ceiling, Q9).

Every native cell below 9 is in §7.

## 6 · Every web cell below 9, by row

Cells appear in dimension order (H T Sp C B P R E D M), each dimension's judges together. A cell at 9 or 10 is omitted. **R1** is the round-1 score and **R2** the round-2 judge's for the same cell; **Checker** is session D's verdict at `ed8e6837` on the defect round 1 named (resolved, open or regressed). The checkers' notes are in `DELTA-panel-cells.md`. Each row opens with the judges' own scope notes, which say what the captures prove and what they do not.

### `web/door`

Means: category 6.5 · craft 7.8 · owner 7.5. Lane: root (no lane).

*Category scope:* All seven Door states at 375/402/1280/1600 both themes plus the 375x380 keyboard proxy (captured at 02636007; the Door renders identically at 9d84c483 per the brief). Proves layout, copy and short-height reach. Does not prove motion, focus order, pressed/loading feel or the real OTP round trip. The 'v23 · __CS_VERSION__' line is the unstamped local build and is not counted.

*Craft scope:* All seven door states at 375/402/1280/1600 and the 375x380 keyboard proxy, both themes (captured at 02636007, web client byte-identical to 9d84c483). Live DOM measurement on 127.0.0.1:8807 (supabase aborted): no text under 11px, no text/ground pair under AA, every door control >=44px except the inline Terms link. Not proved: a real keyboard, real OTP delivery, focus order by hand.

*Owner scope:* All seven Door states at 375×380, 375, 402, 1280 and 1600 in both themes (captured at 02636007; identical web client). Proves copy, layout, keyboard-proxy reachability and the desk composition. Does not prove real iOS keyboard behaviour, email delivery or focus order (not driven).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 7 | open | defect | On the phone the eye lands on 'Any time. Anywhere.', a tagline that does not say what Cup Season is; the reason to sign up (a season with your crew, points, a cup) appears only on the desk boards (door--initial--375--dark.png vs door--initial--1280--dark.png). In door--code-entry--375--dark.png 'Send code' and 'Verify' are two equal act-green primaries. |
| owner | H | 7 | 8 | resolved | defect | Code entry keeps two filled primaries, 'Send code' beside 'Verify', plus a 'Resend code (30s)' link: two controls for one resend and no single next move (door--code-entry--375--dark.png, door--code-entry--1600--light.png, door--code-error--375--light.png). |
| category | T | 7 | 8 | open | defect | Three wordmark treatments: serif caps 'CUP SEASON' on the Door (door--initial--375--dark.png), bold sans 'Cup Season' in every signed-in header (home--member--375--dark--first.png), condensed caps on the public round (public-round--public--375--dark.png). Status/error prose is 12px mono (door--code-error--375--dark.png, door--send-failed--375--dark.png). |
| craft | T | 7 | 8 | resolved | defect | Serif numerals in the desk rails (82/91/78, door--initial--1280--dark.png); sentences with verbs and field labels set in Plex Mono - the error 'Code didn't take. Codes expire when a new one is sent - use the newest email.' and EMAIL / SIGN-IN CODE (door--code-error--375--dark.png) - which UI_SYSTEM 1.4 forbids |
| owner | T | 8 | 8 | resolved | defect | Serif display, mono labels and sans buttons hold, but the status lines that decide the golfer's next step (sent-to, code-error, send-failed) are small coloured mono (door--code-error--375--light.png, door--send-failed--375x380--dark.png). |
| category | Sp | 7 | 7 | open | defect | At 375x380 the status/error sentence is cut by the bottom edge (door--code-entry--375x380--dark.png, door--code-error--375x380--dark.png); at 375x667 ~190px of empty ground sits between the tagline and the actions with nothing composed into it (door--initial--375--dark.png). |
| craft | Sp | 8 | 9 | open | defect | At 375x380 the status/error line drops below the fold under Verify (door--code-error--375x380--dark.png, door--code-entry--375x380--light.png); the email row squeezes the typed address to 'avery.fixture@example.ir' beside Send code (door--code-error--375--dark.png) |
| owner | Sp | 8 | 8 | open | defect | The phone door leaves a ~200px dead band between the subline and the doors (door--initial--375--dark.png, door--initial--402--light.png). |
| category | C | 6 | 8 | open | defect | The league-code state keeps 'I have a league code' as a button above its own field (door--league-code--375--dark.png, door--league-code--402--dark.png) where the email path replaces the buttons with the field; two primaries in code-entry; three wordmarks across Door/app/public. |
| craft | C | 7 | 9 | open | defect | The wordmark is set four ways: serif caps on the door (door--initial--375--dark.png), sans title case 'Cup Season' in the phone header (home--member--375--dark--first.png), condensed caps in the desk sidebar (desk--home--1280--dark.png), sans or mono caps on public pages (public-round--public--375--dark.png, public-round--settlement--375--light.png) |
| owner | C | 8 | 8 | open | decision | The door's sample board prints round points in ember ('+9 PTS') while the share ceremony prints them in gold; the caption carries a build stamp ('v23 · __CS_VERSION__', a SHA in prod) (door--initial--1280--dark.png, share--recap-photo--375--dark.png). |
| category | B | 6 | 6 | open | defect | Remove the pennant and the phone Door is serif text, faint contours and a green button: nothing of golf, competition or friends is visible at 375/402 (door--initial--375--dark.png, door--initial--402--dark.png). The desk shows the product can show itself (door--initial--1280--dark.png). |
| craft | B | 8 | 8 | open | decision | The phone door carries only the mark and the contour; the live proof rails that make the desk door Cup Season are absent at 375/402 (door--initial--375--dark.png vs door--initial--1280--dark.png) |
| owner | B | 8 | 8 | open | content | The phone door proves nothing about the product: pennant, slogan, two buttons. Only the desk shows what Cup Season does (door--initial--375--dark.png vs door--initial--1280--dark.png). |
| category | P | 6 | 6 | open | defect | The phone Door is a well-made template: serif headline, short rule, two stacked buttons on flat charcoal (door--initial--375--dark.png, door--initial--375--light.png); category first screens lead with the product or a photograph. |
| craft | P | 8 | 8 | open | content | No image of golf on the first screen - the premium ceiling is one serif line and a contour (door--initial--375--light.png) |
| owner | P | 7 | 7 | open | decision | The welcome reads as a centred sign-in template on the phone, with a developer build caption at the foot (door--initial--375--light.png). |
| category | R | 8 | 8 | resolved | defect | Error and status copy is 12px mono (door--code-error--375--dark.png) and reads slower than the rest; otherwise large, high-contrast type. |
| craft | R | 8 | 9 | open | defect | The error sentence is the smallest text on the screen at the moment it matters (small mono in neg under the code field, door--code-error--375--dark.png); the door's DOM has six 11px lines (measured) |
| owner | R | 8 | 9 | resolved | defect | Readable throughout; the error/status sentences are 12px mono in red or green (door--code-error--375--light.png). |
| category | E | 5 | 5 | open | defect | Nothing on the phone Door makes a golfer want in: no score, no rival, no stake (door--initial--375--dark.png); the desk's 'ROUNDS HITTING THE BOARD' and 'THE SEASON, LIVE' do (door--initial--1280--dark.png). |
| craft | E | 7 | 7 | open | content | 'Any time. Anywhere.' carries the phone door alone - no image, no live moment (door--initial--375--dark.png) |
| owner | E | 6 | 6 | open | decision | 'Any time. Anywhere.' answers when and where, not why. The vision says 'Where amateur golf counts' is why the product exists; the phone door has no people, no golf and no stake (door--initial--375--dark.png). |
| category | D | 5 | 5 | open | defect | Starved on the phone: the tagline and sub-line never say seasons, points or friends (door--initial--375--dark.png). |
| craft | D | 8 | 8 | open | decision | Phone door is deliberately sparse; the desk shows three rounds and a four-row table the phone never sees (door--initial--375--dark.png vs door--initial--1280--dark.png) |
| owner | D | 7 | 7 | open | content | The phone door is mostly empty; the desk's sample data is headed 'THE SEASON, LIVE' though it is an illustration (door--initial--1280--dark.png). |
| category | M | 8 | 9 | resolved | defect | Fields and primaries reach inside 375x380 in every state and targets are 44px; only the status sentence is cut at short height (door--code-entry--375x380--dark.png). |
| craft | M | 8 | 9 | open | defect | Primary action stays visible at 375x380 but the status/error line does not (door--code-error--375x380--dark.png); the 380px proxy is not a real keyboard. Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 9 | resolved | defect | At 375×380 (keyboard up) the code-error sentence falls to the bottom edge, half out of view (door--code-error--375x380--light.png). |

### `web/home`

Means: category 6.3 · craft 6.2 · owner 7.1. Lane: W3.

*Category scope:* All 32 Home states at 375/402/1280/1600 both themes (02636007). Proves layout, copy, colour roles and the photo-card fault at every width. The hatch/dispatch lead SENTENCES are fixture-authored (tests/fixtures/ten/home-states.synthetic.json, including its he/her pronouns) and forced over the live world, so their wording and lead-vs-standing mismatches are not scored as product defects; the layout they sit in is. The 'Broke 80' line comes from the home_feed producer (mirrored in the fixture from the production SQL) and is scored. Motion, pull-to-refresh and live updates are not captured; photographs are a synthetic gradient.

*Craft scope:* Member, pro, invited, inbox, league-less and all hatch-/dispatch- lead states at 375/402/1280/1600, both themes (02636007, byte-identical web client). Fixed chrome judged from --first crops. The DOM measures (search 33px, board link 87x14) were taken from the live header on 8807. Not proved: loading skeletons (not captured), real photographs, motion.

*Owner scope:* 32 Home states in both themes and four widths (02636007). Dispatch/hatch states substitute only the lead and deck; their headlines are fixture copy, so lead-vs-season-line contradictions there (e.g. 'starts in six days' over a week-8 season line) are harness composition and are not scored. The Pro's Home is byte-identical to the member's at desk and differs at 375 only in the wire's list: no Pro-only content is shown (a decision, noted under E). Photo cards use the synthetic 'FIXTURE PHOTO' image.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | The serif lead and its one door are right, but on every member state a bordered BUDDY REQUEST card sits above the lead (home--member--375--dark--first.png, home--dispatch-*--375--dark--first.png), and below the lead every round gets the same weight: ~12 compact scorecards, each followed by the identical 'X, Y and Z have played here / SEE THEIR ROUNDS AND YOUR CIRCLE'S BEST' row (home--member--375--dark.png, home--pro--375--dark.png). |
| craft | H | 7 | 8 | open | defect | The lead (ember clash eyebrow + serif line) reads first, but below it 20+ rounds sit at identical weight, each with the same 'X, Y and Z have played here / SEE THEIR ROUNDS AND YOUR CIRCLE'S BEST' door (home--member--375--dark.png y~700-4700), and the page ends in a grab-bag foot (home--member--375--light.png y~4750-5300) |
| owner | H | 7 | 8 | open | defect | Every member Home opens on a bordered buddy-request card above the season lead (home--member--375--dark--first.png, all dispatch-* first screens). The clash lead 'You and Devon are both in.' withholds who holds the week, and its only door opens my own receipt (home--member--375--dark--first.png; index.html:18987). |
| category | T | 7 | 8 | open | defect | Long course names in condensed caps become 5-line blocks ('THE CHAMPIONSHIP COURSE AT WHISPERING FIXTURE PINES COUNTRY CLUB · TOURNAMENT TIPS (CHAMPIONSHIP BLACK)', home--member--375--dark.png) with the tee in the title. |
| craft | T | 6 | 8 | resolved | defect | The photo round card and the foot tiles set 82 / 2nd / 1 in the serif while every other round sets its gross in the board face (home--member--375--dark.png y~1200-1560 and y~5560-5640); the monthly-minimum rule is a long mono paragraph (home--member--375--light.png y~5250); course names wrap to five lines of condensed caps |
| owner | T | 8 | 8 | open | defect | Course names in condensed caps wrap to five lines on wire cards and outweigh the round's story line (home--member--375--dark.png, the Championship Course cards). |
| category | Sp | 6 | 7 | open | defect | 5,860px at 375 with one rhythm repeated; the tail crams LEAGUE/BOARD tiles, a promo card, chips and a policy paragraph together (home--member--375--dark.png, bottom; home--member--1280--dark.png left column); the photo card's reaction band cuts the photograph in half (see P). |
| craft | Sp | 6 | 8 | resolved | defect | The photo round card is cut by an opaque ~110px band holding applause and comment stacked vertically, the photo resuming below it (home--member--375--dark.png and --light.png y1200-1560; home--member--1280--dark.png right column); the foot's chips wrap as a ragged cluster (home--member--375--light.png y~4760-4900) |
| owner | Sp | 7 | 8 | resolved | defect | Each wire card carries an extra ~90px course row, and the photo card's reaction foot swells into a ~150px block (home--member--375--dark.png y≈1210–1580). |
| category | C | 5 | 7 | open | defect | P0: a nine-hole 43 reads 'Broke 80 for the first time.' (home--league-less-rounds_no_buddies--375--dark.png, home--league-less-rounds_no_buddies--1280--dark--first.png) while the trophy case requires 18 holes. 'THE BOARD ↗' is gold (index.html:2553-2556) and the LEAGUE tile wears a gold rule though gold means earned (D359) (home--member--375--dark.png); the Ryder invite prints 'first tee 2026-10-10' (home--member-invited--375--dark--first.png); 'AROUND YOUR BUDDIES' heads a list of only your own rounds (home--league-less-rounds_no_buddies--375--dark.png). |
| craft | C | 5 | 8 | resolved | defect | Dark (the default theme) phone header and tab band paint the retired D76 charcoal rgba(12,13,15,.86/.9) - sampled #0C0F10 / #0D0F10 - around the fescue #0F1A15 page, so every signed-in phone page shows two grounds (home--member--375--dark--first.png, compete--empty--375--dark.png, golfers--list--375--dark--first.png); light already mixes --bg0 (index.html:320-321); 'THE BOARD' section link is painted --gold (.eyebrow.withgo a, index.html:2553) and is an 87x14px target - gold on a control (UI_SYSTEM 2.4, D359) (home--member--375--dark.png y~770, links--claim-signed-in-ask--375--light.png); reaction row horizontal on text rounds but vertical on photo rounds; four container grammars in the foot (bg2 chips, bordered promo card, side-ruled tiles, bare mono paragraph) |
| owner | C | 6 | 8 | resolved | defect | Gold on ordinary furniture: 'THE BOARD ↗' is #D8B25A/#795912 and the 'LEAGUE 2nd' tile carries a gold rule, against D359 'gold means earned' (home--member--375--dark.png, home--member--1280--dark.png). The desk sidebar prints 14.2 twice, as 'YOUR NUMBER' and '14.2 INDEX' (home--member--1280--dark.png). Retired nouns survive: 'is on your sheet' (home--hatch-event_ahead--375--dark--first.png), 'Two of you on the sheet' (home--dispatch-round_morning--375--dark--first.png), 'LEAGUE · None yet · JOIN OR START' (home--league-less-brand_new--1280--light.png), and 'He runs it.' is a third rendering of the Pro sentence (home--dispatch-invited--375--light--first.png). |
| category | B | 8 | 8 | open | content | Unmistakably ours (serif leads in the golf voice, condensed titles, the tournament gross, topo, markers); what is missing is a proprietary object in the feed on quiet days, and the one departure (the photo card) is broken. |
| craft | B | 7 | 8 | open | defect | Pennant, markers and the clash eyebrow are Cup Season, but a round on the wire is text + marker disc - no drawn scorecard strip or course bars on any row (home--member--375--dark.png) |
| owner | B | 8 | 8 | open | content | Pennant masthead, topo and the tournament voice hold; wire rows are still text records, with faces only as markers. |
| category | P | 5 | 7 | resolved | defect | P1: the photo round card draws its reactions as an opaque band across the middle of the photograph, applause and comment icons stacked vertically, the course door clipped under it (home--member--375--dark.png y≈1250-1560, home--member--1280--dark.png right column, home--member--402--light.png y≈1100-1400; .hsfoot has no flex, index.html:1532). The tail tiles and promo card look assembled. |
| craft | P | 6 | 8 | resolved | defect | Reads assembled: the repeated door furniture, the split photo card, the foot grab-bag and (dark) the charcoal chrome bands (home--member--375--dark--first.png) |
| owner | P | 6 | 8 | resolved | defect | The flagship photo round is broken in both shapes and themes: an opaque band crosses the middle of the photograph holding only a stacked applause and comment glyph, and the card has no Receipt door (home--member--375--dark.png y≈1210–1580, home--member--1280--dark.png right column, home--dispatch-event_live--1280--light.png). The same course sentence under most cards reads auto-generated. |
| category | R | 7 | 8 | open | defect | Readable, but the repeated 11px mono caps 'SEE THEIR ROUNDS AND YOUR CIRCLE'S BEST' and the 5-line caps course blocks slow the scan (home--member--375--dark.png). |
| craft | R | 7 | 9 | resolved | defect | Five-line condensed-caps course names slow the scan; the foot paragraph is 11px mono (home--member--375--light.png) |
| owner | R | 8 | 8 | resolved | defect | 'LEAGUE 2nd' does not say 2nd of what; in a squads season it is the squad (home--member--1280--dark.png). |
| category | E | 6 | 7 | open | content | The dispatch/hatch leads are the best writing in the product ('Your 89 took six off Blake's lead.', home--dispatch-round_evening--375--dark--first.png; 'Finley took it by twelve.', home--dispatch-ceremony_night--375--dark--first.png), but the feed beneath is records without faces or pictures, and one of them states a false milestone. |
| craft | E | 6 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png); the ceremony-night lead is one sentence over two equal buttons with no trophy object (home--hatch-ceremony_night--1600--light.png) |
| owner | E | 7 | 8 | open | decision | The week's rivalry result is withheld (both in, no leader); the crowning lead is text only ('Finley took it by twelve.', home--dispatch-ceremony_night--375--dark--first.png); an upcoming Ryder has no Home item at all (the fixture's own note, home--hatch-event_ahead--375--dark--first.png). |
| category | D | 5 | 7 | open | defect | The standing is said three times (lead line '2ND OF 2 · 34 BACK', LEAGUE '2nd' tile, the wire) and the next round twice (wire 'You have a round on Wednesday' + NEXT ROUND chip) (home--member--375--dark.png, home--member--1280--dark.png); the monthly-minimum policy paragraph prints on Home (16A.1); league-less brand-new offers seven doors on an empty page (home--league-less-brand_new--375--dark.png). |
| craft | D | 5 | 8 | open | defect | Six layers per round (name/day, course, gross, story, played-here door, applause/comment/receipt) and repeated facts - the standing sits in the lead's standing sentence, the foot 'LEAGUE 2nd' tile and the desk sidebar (home--member--375--dark.png y~410 and y~5560; home--member--1280--dark.png) |
| owner | D | 6 | 7 | open | defect | Member Home runs 5,860px at 375, largely because 'Casey, Blake and Jules have played here · SEE THEIR ROUNDS AND YOUR CIRCLE'S BEST' repeats under nearly every card (home--member--375--dark.png y≈1100–4700), against L-34. The brand-new Home asks for a first round four times in one viewport (home--league-less-brand_new--1280--light.png). |
| category | M | 7 | 8 | open | defect | No overflow at 375/402; the buddy-request row squeezes its mono line into two lines beside two buttons (home--member--375--dark--first.png); the photo card is broken at every width. |
| craft | M | 7 | 9 | open | defect | Header search button measures 33x33 (inline padding 6px + 21px glyph, index.html:4759) beside a 44x44 bell - measured in the DOM at 375; the 'THE BOARD' link is 14px tall and 'Start something else...' is a small text link (home--member--375--light.png). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 9 | open | defect | No overflow and 44px targets, but on the brand-new Home the primary 'ADD MY ROUND' is a text link beneath two filled secondary buttons (home--league-less-brand_new--375--dark--first.png). |

### `web/post`

Means: category 6.3 · craft 5.9 · owner 6.2. Lane: W1.

*Category scope:* Four composer states (first round, member, filled, post refused) at every width and theme plus 375x380 (02636007). Proves the form, the points preview, the worth line and the failure path. Does not prove the scan flow, a real photo attached, the typing interaction (the band updating), or the keyboard itself (375x380 is a proxy).

*Craft scope:* First-round, member, filled and post-failed at 375/402/1280/1600 (+375x380), both themes (02636007). Not captured: posting in progress, success, scan flow, photo attach.

*Owner scope:* Four composer states, both themes, all widths incl. the 375×380 proxy (02636007). The filled state was driven through front/back nines; the hero-vs-summary disagreement is what that path shows. A successful post is covered under web/share (the finish ceremony).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 8 | resolved | defect | The largest slot on the screen, 'YOUR GROSS', stays an empty dash when the card is filled (composer--filled--375--dark.png, composer--post-failed--375--light--first.png, composer--filled--1280--dark.png) while a button far below reads 'Gross 83 · 18 holes'. |
| craft | H | 6 | 9 | resolved | defect | In the filled state the 'YOUR GROSS' hero at the top stays a dash while the 83 exists only as a bg2 summary 'Gross 83 - 18 holes' near the foot (composer--filled--375--dark.png, composer--filled--1280--light.png) - the most important number is not where the label says it is |
| owner | H | 6 | 8 | resolved | defect | After front and back are entered, the 'YOUR GROSS' hero still reads '—' while 'Gross 83 · 18 holes' sits at the foot (composer--filled--375--dark.png, composer--filled--1280--light.png). The course, the other required fact, is a quiet mono line with a small 'edit' (composer--first-round--375--dark.png). |
| category | T | 7 | 8 | resolved | defect | The inherit line 'Add the course · — / — · TODAY' is set in mono like code (composer--first-round--375--dark.png); the points panel sets '+1.4' over the label 'YOUR PLAYING HCP' (composer--filled--375--dark.png). |
| craft | T | 6 | 8 | resolved | defect | Mono sets the course line and the sentence 'No match - type the course, rating and slope by hand.'; league points '9' is a serif numeral (composer--filled--375--dark.png) |
| owner | T | 7 | 8 | resolved | defect | Mono caps carry the labels, the course line and the golfer chips; the scoring panel's serif '9' is the only display moment. |
| category | Sp | 7 | 7 | open | defect | Card inside card: a bordered composer holding a bordered photo plate and a filled scan button, above a second bordered card (composer--member--375--dark.png, composer--first-round--375--light.png). |
| craft | Sp | 7 | 8 | resolved | defect | The post-failed toast floats over the tag chips and course fields (composer--post-failed--375--light--first.png) |
| owner | Sp | 7 | 8 | resolved | defect | The no-match course state stacks an input, a message boxed like an input, a hint and three chips (composer--filled--1280--light.png). |
| category | C | 6 | 8 | resolved | defect | '+1.4 · YOUR PLAYING HCP' labels the comparison as if it were the handicap; the ruled label is 'vs your playing HCP' (R-M/D260; index.html:5359; composer--filled--375--dark.png). The post-failed toast renders as a round blob of seven centred lines joining two messages (composer--post-failed--375--dark--first.png, composer--post-failed--402--dark--first.png), unlike every other toast. |
| craft | C | 5 | 8 | open | defect | Dark .card/.stat still paint the D76 charcoal gradient #191C20->#141619 with a #2A2F36 border and a drop shadow (index.html:3658); charcoal covers 35-50% of composer--filled--375--dark--first.png, play--setup-empty--375--dark.png, wizard--step-3-review--375--dark.png; the native date input shows the browser's blue selection on '09' (composer--filled--375--dark.png, composer--filled--1280--light.png); four button grammars on one form (outlined ADD A PHOTO, bg2 Scan chip, bg2 'Gross 83' block, act primary) |
| owner | C | 5 | 8 | resolved | defect | Two gross fields disagree on one card; the failure says 'press Post again' though the button is 'Add my round' (A-5) (composer--post-failed--375--dark--first.png); the unlisted-course hint contradicts its own first clause. |
| category | B | 6 | 7 | open | defect | A good form that is ours only in the points preview and the band table (composer--filled--375--dark.png); the rest is fields in boxes. |
| craft | B | 6 | 7 | open | defect | A tidy form: the fescue palette and the named-band table are the only Cup Season signals; no drawn object (composer--first-round--375--light.png) |
| owner | B | 7 | 7 | open | content | The voice is Cup Season (bands, 'It says nothing about the score'); the surface is a boxed form. |
| category | P | 5 | 6 | open | defect | Native date input with its blue segment selection (composer--filled--375--dark.png), boxed fields, and the error blob read assembled. |
| craft | P | 5 | 8 | open | defect | Boxes in boxes on the primary write path, and the post-failed toast is a pill stretched into a five-line oval (composer--post-failed--402--dark--first.png) |
| owner | P | 5 | 7 | resolved | defect | A refused post renders as a large circular toast over the tags and over the points figure (composer--post-failed--375--dark--first.png, composer--post-failed--375--light.png), with no inline error by the button. |
| category | R | 7 | 8 | open | decision | Readable; the worth paragraph under the 9 carries four numbers in one block ('up to 12 … lowest is a 6, so a 12 would add 6 … up to 12 in South Wash') (composer--filled--375--dark.png). |
| craft | R | 7 | 8 | resolved | defect | 11px mono labels; a five-line worth paragraph under the points (composer--filled--375--dark.png) |
| owner | R | 5 | 8 | resolved | defect | The margin '+1.4' is labelled 'YOUR PLAYING HCP' (index.html:5359 `calcVs` · 'your playing HCP'), so a 14.2 golfer reads a plus handicap (composer--filled--375--dark.png, composer--filled--1280--light.png). The unlisted-course hint says the round 'won't show in your rounds' (index.html:12308) while the round counts in full. |
| category | E | 6 | 6 | open | defect | The points preview ('9 · You beat your playing HCP by 1.4. Nice round.') is the only reward; nothing anticipates the ceremony. |
| craft | E | 5 | 6 | open | defect | Posting has no moment - the '9 ... Nice round.' panel is the only reward (composer--filled--375--dark.png) |
| owner | E | 6 | 8 | resolved | defect | 'You beat your playing HCP by 1.4. Nice round.' is the one warm line; the worth line keeps quoting a hypothetical 12 after the card scores 9 (composer--filled--1280--light.png). |
| category | D | 6 | 7 | resolved | defect | The filled composer is 2,344px at 375: course search + three suggestion chips + rating/slope + 18/9 + nines + date + summary + worth paragraph + the open five-band table (composer--filled--375--dark.png). |
| craft | D | 6 | 8 | resolved | defect | Worth paragraph + full band table + chip rows run the filled page to 2344px at 375 (composer--filled--375--dark.png) |
| owner | D | 7 | 8 | open | defect | The phone composer runs 2,344px for a two-number task once the course list opens (composer--filled--375--dark.png). |
| category | M | 7 | 7 | open | defect | At 375x380 'Add my round' is below the fold with the keyboard up (composer--first-round--375x380--dark.png, composer--member--375x380--light.png); the failure blob covers the tag chips (composer--post-failed--375--dark--first.png). |
| craft | M | 6 | 9 | open | defect | Tag chips measure 25-28px tall (composer--filled--375--dark--first.png, pixel runs y455-548; UI_SYSTEM 16.2 names them) and the failure toast covers live fields (composer--post-failed--375--light--first.png). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | open | device-or-human | At 375×380 the gross field is reachable but the tab bar takes 70px of the short viewport (composer--member--375x380--light.png); real keyboard behaviour is not captured. |

### `web/share`

Means: category 7.4 · craft 7.5 · owner 7.1. Lane: W4.

*Category scope:* The finish ceremony (dark ground in both themes by design; no-photo and photo states are byte-identical as pages) and the three exported 1080x1350 artifacts (one per state; byte-identical across widths/themes). Proves the artifact composition and the photo-option fault. Does not prove the reveal animation, the native share sheet, or the withdraw/cancel flows.

*Craft scope:* Three share states at four widths, both themes (02636007), plus the 24 exported artifacts - which are byte-identical across widths and themes, so three unique 1080x1350 images. Not captured: the OS share sheet, cancel/withdraw after share.

*Owner scope:* The finish ceremony page (fixed ceremony ground, byte-identical in both themes, as §16.1 intends) at four widths, and the three exported 1080×1350 artifacts (one per state, identical across viewports). The page capture does not distinguish photo from no-photo; the artifacts do. Consent withdrawal and cancel paths are not captured.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 8 | 9 | resolved | defect | Clear stack, but on a round with no photograph an outlined 'Include round photo' button competes with the primary (share--recap-no-photo--375--dark.png, share--recap-long-course--375--dark.png). |
| craft | H | 8 | 9 | resolved | defect | Three centred actions of similar weight ('Include round photo', 'Share the card', 'Back to the board') under the figure (share--recap-photo--375--light.png) |
| owner | H | 7 | 8 | resolved | defect | A photo-less round still offers 'Include round photo', in its pressed style, above the share action (share--recap-no-photo--375--dark.png; the page is byte-identical to share--recap-photo at every width). `.finish-photoopt{display:flex}` (index.html:3841) overrides the `hidden` attribute set at index.html:11008. |
| category | T | 7 | 8 | resolved | defect | The ceremony sets the gross in the serif (share--recap-no-photo--375--dark.png) while the artifact sets it in the condensed display face (artifacts/share--recap-no-photo--375x667--dark.png); the ceremony band is a lowercase fragment ('beat your playing HCP by 1.5'). |
| craft | T | 7 | 9 | resolved | defect | The share screen sets 83/89 in the serif while the exported card sets the same figure in the board face (share--recap-no-photo--375--dark.png vs artifacts/share--recap-no-photo--375x667--dark.png); the points line is gold mono |
| owner | T | 8 | 8 | open | defect | The facts line under the serif figure is 12px mono caps; on the card the band line competes with the course (artifacts/share--recap-no-photo--375x667--dark.png). |
| category | Sp | 8 | 8 | open | defect | Balanced; the artifact's lower third packs course, date/points and the lockup into ~120px (artifacts/share--recap-long-course--375x667--dark.png). |
| craft | Sp | 8 | 9 | resolved | defect | On desk the share screen is a narrow centred column floating in a black 1280/1600 field (share--recap-photo--1280--dark.png, share--recap-long-course--1600--light.png) |
| owner | Sp | 7 | 8 | resolved | defect | The desk ceremony is a ~300px column in a black 1280×1000 field (share--recap-no-photo--1280--dark.png). |
| category | C | 6 | 9 | resolved | defect | 'Include round photo' shows on rounds without a photograph because .finish-photoopt{display:flex} overrides the [hidden] attribute the code sets (index.html:3841, 11008; share--recap-no-photo--375--dark.png); 'Share the card' is ember though sharing is an ordinary action (D359; index.html:3833); the artifact paints every band gold, 'PLAYED TO IT' included (artifacts/share--recap-long-course--375x667--dark.png), though gold means earned. |
| craft | C | 6 | 9 | resolved | defect | Ember 'Share the card' on an ordinary action (D359 gives ordinary actions act); 'Include round photo' is a third button grammar (1px white outline); gold on the points line and on the card's band phrase ('PLAYED TO IT' is not an earning) (share--recap-no-photo--375--dark.png, artifacts/share--recap-long-course--375x667--dark.png) |
| owner | C | 6 | 8 | resolved | defect | 'Share the card' is ember (#F6682F, `--ceremony-brand`), but D359 gives ordinary actions to act; the page says 'beat your playing HCP by 1.5' while the card says 'BEAT THEIR NUMBER'; points are gold here and ember on the door's sample (share--recap-photo--375--dark.png, door--initial--1280--dark.png). |
| category | B | 8 | 8 | open | defect | The artifact is clearly ours (medallion, pennant lockup, tagline); the ceremony page itself carries no mark (share--recap-no-photo--375--dark.png). |
| craft | B | 8 | 9 | resolved | defect | The card is proprietary (medallion, marker, pennant, frame) but the share screen previews it as plain type on black (share--recap-no-photo--375--dark.png) |
| category | P | 6 | 7 | resolved | defect | The photo artifact buries the photograph under a near-opaque scrim, so it reads as the no-photo card with a watermark (artifacts/share--recap-photo--375x667--dark.png); category share cards lead with the picture. |
| craft | P | 7 | 8 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) - the photo variant shows the placeholder at ~10% (artifacts/share--recap-photo--375x667--dark.png) |
| owner | P | 7 | 8 | open | content | The photo artifact darkens the photograph almost to black (artifacts/share--recap-photo--375x667--dark.png). The fixture photo is a dark synthetic, so this is partly a content limit. |
| category | R | 8 | 8 | open | defect | The ceremony eyebrow runs to three lines of 11px tracked mono on a long course (share--recap-long-course--375--dark.png). |
| craft | R | 8 | 9 | resolved | defect | 11px mono course/date line above an 83 of ~90px (share--recap-long-course--402--dark.png) |
| owner | R | 7 | 8 | resolved | content | 'BEAT THEIR NUMBER' and 'PLAYED TO IT' are insider words for the friend who receives the card (artifacts/share--recap-long-course--375x667--light.png). |
| category | E | 7 | 7 | open | device-or-human | The putt-into-the-cup reveal exists in code (index.html:3790-3827) but stills cannot show it; the stills are a big number and a gold points line. |
| craft | E | 7 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | E | 7 | 8 | resolved | defect | The golfer is asked to 'Share the card' without ever seeing it (share--recap-no-photo--375--dark.png). |
| category | D | 8 | 8 | open | content | Right amount of information on both the ceremony and the artifact. |
| craft | D | 8 | 9 | resolved | defect | The screen restates the card's facts instead of showing the card (share--recap-photo--375--light.png) |
| owner | D | 6 | 8 | resolved | defect | The desk ceremony is five lines on a 1280-wide black field (share--recap-no-photo--1280--dark.png). |
| category | M | 8 | 8 | open | device-or-human | Fits every width; 'Back to the board' is a text button whose hit height cannot be read from a still. |
| craft | M | 8 | 9 | open | defect | Desk composition not designed (phone column in a black field, share--recap-photo--1280--dark.png). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | resolved | defect | Every photo-less post, which is most posts, shows the false photo toggle. |

### `web/public-round`

Means: category 6.6 · craft 7.2 · owner 7.0. Lane: W4.

*Category scope:* All nine public states (round record in both themes; settlement/recap/dead link are fixed-dark and byte-identical across themes) at every width (02636007). The recap's figures and dates come from a separate fixture envelope and differ from the in-app North Grove; not scored as a defect. Link unfurl (og:image) is not captured.

*Craft scope:* All nine public-round states at four widths, both themes (02636007). The long name wraps whole and the escaped name renders inert. Settlement/recap/dead-link are pinned dark in the light printing (ceremony ground) - noted, scored as consistency not readability.

*Owner scope:* All nine public states, four widths, both themes (02636007). Settlement, recap and dead-link are identical across themes. The escaped-name state proves hostile names render as text. Link previews (og cards) are not captured.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 7 | open | defect | The course title leads and the golfer's name sits fourth, under the gross (public-round--public--375--dark.png, public-round--photo--1280--dark.png); for a link a friend sent, who played is the first question. |
| craft | H | 8 | 9 | resolved | defect | The CTA bar is as heavy as the round itself (public-round--public--375--dark.png) |
| owner | H | 8 | 8 | resolved | content | The gross leads, but a stranger's first question (what is this, why should I care) gets 'ANY TIME. ANYWHERE.' in 11px mono (public-round--public--375--dark.png). |
| category | T | 6 | 8 | resolved | defect | Two public typographies: the round record (serif title, condensed name, serif-caps band 'PLAYED TO IT') and the share-view family set in typewriter mono (public-round--settlement--375--dark.png, public-round--dead-link--375--dark.png, public-round--recap--375--dark.png). |
| craft | T | 6 | 10 | resolved | defect | The band phrase is set in the serif in ALL CAPS ('PLAYED TO IT', 'BEAT THEIR NUMBER', 'POSTED ANYWAY') (public-round--public--375--dark.png, public-round--photo--375--light.png); settlement names and sentences are mono (public-round--settlement--375--light.png) |
| owner | T | 8 | 8 | resolved | defect | Dead link, settlement and recap switch to all-mono type (public-round--dead-link--375--dark.png, public-round--settlement--375--dark.png). |
| category | Sp | 8 | 8 | open | decision | Good rhythm; the desk centres a 560px column on a wide field (public-round--photo--1280--dark.png). |
| craft | Sp | 8 | 9 | open | defect | Settlement's CTA falls below the fold at 667 under a tall card (public-round--settlement--375--light.png) |
| owner | Sp | 7 | 8 | resolved | defect | The desk shape is a ~350px column on a 1280/1600 ground (public-round--photo--1280--light.png, public-round--settlement--1600--dark.png). |
| category | C | 5 | 8 | resolved | defect | Two public shells: the round record has the pennant lockup and 'PLAY WITH YOUR PEOPLE'; the share-view pages a text 'CUP SEASON' header and 'Play this with your crew' in mono (public-round--settlement--375--dark.png vs public-round--public--375--dark.png); the settlement says 'CLOSED ON 16' and then a chip 'CLOSED OUT ON 16'. |
| craft | C | 6 | 9 | open | defect | The wordmark is set four ways: serif caps on the door (door--initial--375--dark.png), sans title case 'Cup Season' in the phone header (home--member--375--dark--first.png), condensed caps in the desk sidebar (desk--home--1280--dark.png), sans or mono caps on public pages (public-round--public--375--dark.png, public-round--settlement--375--light.png); CTA grammar splits between 'PLAY WITH YOUR PEOPLE' (sans caps) and 'Play this with your crew' (mono) across sibling pages |
| owner | C | 6 | 8 | resolved | defect | Two public families: the round record has the pennant lockup and follows the theme; settlement, recap, dead link and the person and plan landings print 'CUP SEASON' as text and are fixed dark (byte-identical across themes). |
| category | B | 7 | 8 | resolved | defect | The round record's lockup and the settlement's 18-square hole strip are ours; the recap is two rows in a box (public-round--recap--375--dark.png). |
| craft | B | 8 | 8 | open | content | No image of the course (content); otherwise the pennant, marker and hole strip carry it |
| owner | B | 7 | 8 | resolved | defect | Settlement, recap and dead-link pages lack the pennant that D358 puts on shared artifacts (public-round--recap--402--dark.png). |
| category | P | 6 | 7 | resolved | defect | The round record is spare and correct; the settlement reads like a till receipt; the recap is a stub. |
| craft | P | 7 | 8 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) (public-round--photo--375--light.png); mono footers read utilitarian |
| owner | P | 7 | 8 | resolved | content | Record pages are clean but plain; the season recap is a two-row table (public-round--recap--402--dark.png). |
| category | R | 7 | 8 | resolved | defect | Mono body text in the settlement and recap reads slower than the round record (public-round--settlement--375--dark.png). |
| craft | R | 8 | 9 | resolved | defect | 11px mono footer 'ANY TIME. ANYWHERE. cupseason.app' (public-round--public--375--dark.png) |
| owner | R | 7 | 8 | resolved | content | Band names ('PLAYED TO IT', 'BEAT THEIR NUMBER') are insider words for a recipient (public-round--public--375--light.png, public-round--long-name-nine--375--dark.png). |
| category | E | 6 | 7 | resolved | defect | A stranger sees a number and a band word; the recap gives them nothing to want ('1 · Fixture Javelinas 171 pts / 2 · Fixture Wrens 87 pts / IN PLAY'). |
| craft | E | 6 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | E | 6 | 7 | open | content | A text record; the recap shows two rows and 'IN PLAY'. |
| category | D | 6 | 7 | resolved | defect | The recap is starved (public-round--recap--375--dark.png); the round record is right for a share. |
| craft | D | 7 | 8 | open | decision | The round page says nothing of the course or the season it counted in (public-round--public--375--dark.png) |
| owner | D | 6 | 8 | resolved | defect | The recap is starved and the desk is void. |
| category | M | 8 | 8 | open | device-or-human | Fits every width; CTAs 44px+; escaping holds (public-round--escaped-name--375--dark.png). |
| craft | M | 8 | 9 | open | device-or-human | Desk centres the phone column (public-round--photo--1600--dark.png). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | open | defect | Long names wrap whole and hostile names are escaped; the settlement hole strip is 9px squares at 375 (public-round--settlement--375--dark.png). |

### `web/claim-invite`

Means: category 6.0 · craft 6.8 · owner 6.9. Lane: W4.

*Category scope:* All 17 link states (02636007) at every width, both themes, and 375x380 for the door-borne ones. links--claim-used is byte-identical to the plain Door by design (the used card says nothing). Does not prove the OTP-to-claim completion or the covenant's Join write.

*Craft scope:* All 17 link states (02636007). claim-used and join-unavailable deliberately say nothing / do not reveal the league (harness expectations in tests/ten-states.d/40-links-setup.mjs) - treated as decisions, not defects.

*Owner scope:* All 17 link states, four widths (and 375×380 for signed-out doors), both themes (02636007). The person landing shows index and three recent rounds to any link holder under D241; whether D394 (strangers see name, handle and marker) should narrow it is an open decision, recorded not scored.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 5 | 7 | resolved | defect | The thing the visitor came for ('Kit — 91 at Mesquite Wash Golf Club … Enter your email to keep it.'; 'You're invited to North Grove (fixture).') is the smallest text on the screen, 12px mono under the email field, beneath the generic 'Any time. Anywhere.' hero (links--claim-valid--375--dark.png, links--claim-scan-partner--375--dark.png, links--join-valid--375--dark.png). |
| craft | H | 6 | 9 | resolved | defect | The fact that brought the golfer here (whose card, which league) is the smallest text on the door - a small mono line under the email field (links--claim-valid--375--dark.png, links--join-valid--375--light.png) |
| owner | H | 6 | 8 | resolved | defect | Claim and join doors keep the slogan as the headline; the reason the visitor came ('Kit — 91 at Mesquite Wash… Enter your email to keep it.', 'You're invited to North Grove (fixture)') is 12px mono under the email field (links--claim-valid--375--dark.png, links--join-valid--375--light.png). An invite banner and the lead repeat one invitation, with two 'See the terms' (links--invite-banner--375--light--first.png). |
| category | T | 6 | 8 | resolved | defect | Key sentences are mono (links--claim-unfinished--375--light.png, links--claim-dead--375--dark.png); the person landing mixes a serif headline with a mono body (links--person-landing--375--dark.png). |
| craft | T | 6 | 8 | resolved | defect | Mono sentences for the claim and join lines and the person-landing bodies; ember mono 'Get the app' (links--person-landing--375--light.png) |
| owner | T | 7 | 8 | resolved | defect | The link's context is set in small mono (links--claim-scan-partner--375--light.png). |
| category | Sp | 7 | 7 | resolved | defect | The invite banner stacks an ember card and a lead that say the same thing on one screen (links--invite-banner--375--dark.png). |
| craft | Sp | 7 | 8 | resolved | defect | The invite banner squeezes 'League invite - North Grove (fixture)' onto three lines beside two buttons (links--invite-banner--375--dark--first.png) |
| owner | Sp | 8 | 8 | open | defect | The fields sit low under a large empty band (links--join-valid--375--light.png). |
| category | C | 5 | 7 | open | defect | The person landing's 'Get the app' is ember and mono (links--person-landing--375--dark.png) while the dead link's CTA is act green (public-round--dead-link--375--dark.png, X23); the covenant calls best-four 'Standard' (links--join-covenant--375--dark.png) while the wizard's Standard card says best three (wizard--step-2-rules--375--dark.png); the unknown code QQFX00 still says 'You're invited.' (links--join-unavailable--375--dark.png). |
| craft | C | 6 | 8 | resolved | defect | Person landing 'Get the app' is ember on an ordinary action (D359; its settlement twin already moved to act, ledger X23) (links--person-landing--375--light.png, links--person-landing-new--375--dark.png); '$75 each.' is gold on the covenant though a buy-in is not an earning (links--join-covenant--375--dark.png, links--invite-terms--402--light.png) |
| owner | C | 6 | 7 | open | defect | The person landing's 'Get the app' is ember (links--person-landing--375--dark.png) though X23 moved the other public CTAs to act; 'League invite' and 'review the league' use league as a thing you join (TERMINOLOGY §2.3); the free covenant drops the Pro line the staked one carries (links--join-covenant-free--375--light.png). |
| category | B | 6 | 7 | resolved | defect | Branded only by the reused Door and the marker medallion on the person landing. |
| craft | B | 7 | 8 | resolved | defect | Claim and join states reuse the door unchanged - nothing on screen is the round or league being claimed (links--claim-valid--375--dark.png) |
| owner | B | 8 | 8 | resolved | defect | Door brand and covenant voice are strong; the person and plan landings use a text-only 'CUP SEASON' shell. |
| category | P | 5 | 7 | open | defect | Four different arrivals share one generic Door; the sheets (covenant, signed-in asks) are tidy but plain. |
| craft | P | 7 | 8 | resolved | defect | Same: the door with a mono footnote (links--claim-scan-partner--375--light.png) |
| owner | P | 7 | 8 | open | defect | Two landing families (the door vs the mono card). |
| category | R | 7 | 8 | resolved | defect | The key sentence is 12px mono; the covenant's nine paragraphs read well (links--join-covenant--375--dark.png). |
| craft | R | 7 | 8 | resolved | defect | Context lines in small mono under the field (links--claim-valid--375--dark.png, links--join-valid--375--light.png) |
| owner | R | 6 | 8 | resolved | defect | A code that resolves to no league tells the stranger 'You're invited. Sign in to review the league before you join.' (links--join-unavailable--375--dark.png; index.html:33737; fixture `dead: 'QQFX00' /* resolves to no league */`). An already-claimed link shows the bare door with no sentence (links--claim-used--375--dark.png is byte-identical to door--initial--375--dark.png) while an unknown token gets 'expired or was already claimed'. |
| category | E | 5 | 6 | resolved | defect | The claim link is the guest funnel's hook (a round you already played is waiting for you) and it is shown as fine print. |
| craft | E | 7 | 8 | resolved | defect | 'Blake Sample wants you in their golf.' lands; the claim door has no figure of the round (links--claim-valid--375--dark.png) |
| owner | E | 7 | 8 | resolved | defect | 'Blake Sample wants you in their golf.' is warm and the covenant is proud, but it never tells a week-8 joiner that the season is eight of thirteen weeks in and that earlier rounds won't count for the squad (D386) before 'Join — I'm in for $75' (links--join-covenant--375--dark.png). |
| category | D | 6 | 7 | resolved | defect | Door states are starved of the context the link carries; the covenant is complete. |
| craft | D | 7 | 8 | open | decision | The covenant sheet is nine stacked paragraphs (links--join-covenant--375--dark.png) |
| owner | D | 7 | 8 | resolved | defect | The person landing clips course names with ellipses ('[course] Fixture L…') (links--person-landing--375--dark.png). |
| category | M | 8 | 8 | resolved | defect | Targets are 44px and nothing overflows; at the 375x380 proxy the reason sentence for unfinished/not-started/dead claims sits below the fold (links--claim-unfinished--375x380--dark.png, links--claim-dead--375x380--light.png), though those states have no field focused, so the keyboard would not be up. |
| craft | M | 8 | 9 | open | device-or-human | Actions >=44px and visible at 375x380 (links--claim-valid--375x380--dark.png). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | open | defect | The dead-code and claimed-link paths send the visitor through a full email-code sign-in to learn nothing. |

### `web/identity`

Means: category 6.3 · craft 6.7 · owner 6.8. Lane: W2.

*Category scope:* You (empty, one round, populated, partial error) captured at 9d84c483; the card gate and the card sheet at 02636007; every width, both themes. Proves the credential, the stats and the record sections. Does not prove photo upload, handle availability checks against a real server, or AX sizes.

*Craft scope:* you--* at 9d84c483 (empty, one-round, populated, error), onboarding card gate and the card sheet at 02636007; both themes, four widths. The second highlighted marker tile in settings--card is the .mini:hover state under the harness pointer, not a defect.

*Owner scope:* You at 9d84c483 (empty, one-round, populated, error), the card gate and Card & settings at 02636007, all widths and themes. The error state is exemplary ('Nothing is lost — the read failed, not the record'). No state carries a profile photograph.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 8 | open | defect | The credential leads, then eleven sections stack at one weight to 6,410px at 375 (form, buttons, buddies, trophies, two tile grids, recent rounds, rivalries, every season, bag, courses) (you--populated--375--dark.png); on the desk the 360px credential sits top-left with the right half empty (you--populated--1280--dark.png). |
| craft | H | 7 | 8 | open | defect | The credential leads, then 6410px of equal-weight sections - trophies, all-time, recent rounds, seasons, ten rivalries, every season, the bag and the whole course book (you--populated--375--dark.png) |
| owner | H | 7 | 8 | resolved | defect | After the tour card come 'Card and settings', 'Tell us how it's going' and the buddies row, all before any golf (you--populated--375--dark.png, you--empty--375--dark.png). |
| category | T | 7 | 8 | resolved | defect | Credential type is strong; below it tiles mix figure sizes and trophy lines clip ('The Championship Course at Whisp…') (you--populated--375--dark.png). |
| craft | T | 6 | 8 | resolved | defect | All-time tiles set 8 / +5.4 / -1.0 in the serif under mono labels (you--populated--375--dark.png y~1100-1300) |
| owner | T | 8 | 8 | resolved | defect | Label stacks such as 'BEST VS YOUR PLAYING HCP +5.4 across 8 rounds that count' sit in small mono (you--populated--375--dark.png). |
| category | Sp | 6 | 8 | resolved | defect | Tile grids crowd; the credential sub-line clips '@AVERY · MESA, AZ · SAGUARO FLATS MUNICIPAL (FI…' at 375 and on the desk (you--populated--375--dark.png, you--populated--1280--dark.png). |
| craft | Sp | 7 | 7 | resolved | defect | Boxed tiles and boxed rivalry rows sit under hairline lists - two spacing systems on one page (you--populated--375--dark.png, you--populated--1280--light.png) |
| owner | Sp | 7 | 8 | resolved | defect | A 6,410px phone page; the course book repeats full scorecards inline (you--populated--375--dark.png y≈3900–6400). |
| category | C | 5 | 7 | open | defect | P1: FORM marks the nine-hole 43 as the best of the last five in gold beside 18-hole grosses (formRowHtml takes the lowest gross, index.html:21646; you--populated--375--dark.png, you--populated--1280--dark.png). 'Your buddies · 1 request waiting' wears an ember border (not competition, D359); ALL TIME tiles repeat THIS SEASON's (8 · +5.4 · -1.0); the rivalry reads 'Devon 3-4 THEY LEAD · 7 weeks head-to-head' while the person page and head-to-head say 'All square, 5-5' (golfers--person--375--dark.png, golfers--h2h--375--dark.png). |
| craft | C | 5 | 9 | resolved | defect | Dark .card/.stat still paint the D76 charcoal gradient #191C20->#141619 with a #2A2F36 border and a drop shadow (index.html:3658); charcoal covers 35-50% of composer--filled--375--dark--first.png, play--setup-empty--375--dark.png, wizard--step-3-review--375--dark.png; the Form row golds the 9-hole 43 as best of five against 18-hole grosses (you--populated--375--dark.png, you--populated--1280--light.png; formRowHtml, index.html:21646) |
| owner | C | 5 | 7 | resolved | defect | 14.2 appears as 'YOUR NUMBER', '14.2 INDEX' and 'HANDICAP INDEX' in one desk viewport (desk--you--1280--dark--first.png). ALL TIME and THIS SEASON print the same three figures. Gold decorates a card chip and single form figures ('43', '84') (you--one-round--375--dark.png). The buddies row wears ember. 'Post your first round' against A-5's 'Add my round' (you--empty--375--dark.png). |
| category | B | 8 | 9 | resolved | defect | The credential (topo, medallion, gold tab, huge name, figures on a rule) is proprietary; the sections below are tile grids. |
| craft | B | 8 | 9 | open | defect | The credential is proprietary; everything below it is lists (you--populated--375--dark.png) |
| owner | B | 8 | 8 | open | content | The tour card is a proprietary object (topo, medallion, condensed name). No profile photo appears in any capture. |
| category | P | 6 | 7 | open | defect | Tile grids and bordered rows under a premium credential (you--populated--375--dark.png); the card gate is a form (onboarding--card-gate--375--dark.png); the card sheet is a form (settings--card--375--dark.png). |
| craft | P | 7 | 8 | resolved | defect | Credential premium, the rest assembled from boxes (you--populated--1280--light.png) |
| owner | P | 7 | 8 | resolved | defect | The card's gold chip and stacked stat boxes read assembled (you--populated--1280--dark.png). |
| category | R | 7 | 8 | resolved | defect | Recent rounds ellipsize course names ('MESQUITE WASH GOLF CL…') and trophy lines clip (you--populated--375--dark.png). |
| craft | R | 8 | 9 | open | defect | Recent-round course names truncate at 375 ('MESQUITE WASH GOLF CL...', you--populated--375--dark.png y~1450); 11px mono labels |
| owner | R | 7 | 7 | open | defect | 'EVERY SEASON · FINISH' prints two live seasons as '1ST'/'2ND' with podium marks (you--populated--375--dark.png; index.html:31909 passes the live place as `finish`, :17043 adds the podium mark). The personal best reads '7.9 vs course', a differential that L-14 keeps to the receipt. FINDABLE BY shows no current value (settings--card--1280--dark.png). |
| category | E | 6 | 7 | open | defect | The credential and the trophies pull; the one-round state awards PERSONAL BEST + BROKE 100 + BROKE 90 at once (you--one-round--375--dark.png), which cheapens all three (BRIEF §33); the empty state is deliberately thin (F10). |
| craft | E | 7 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) (you--empty--375--dark.png credential shows the marker, not a face) |
| owner | E | 7 | 8 | open | decision | Rivalries, milestones and the bag story are memory, but a golfer's first round earns 'PERSONAL BEST', 'BROKE 100' and 'BROKE 90' at once (you--one-round--375--dark.png). |
| category | D | 5 | 8 | open | defect | Overloaded populated page: duplicate tiles, bag, courses and every season on one scroll (you--populated--375--dark.png). |
| craft | D | 5 | 8 | resolved | defect | One page carries profile, trophies, stats, rounds, seasons, rivalries, bag and the full course book (6410px at 375), repeating the courses page (you--populated--375--dark.png) |
| owner | D | 5 | 8 | resolved | defect | The phone page is 6,410px and the desk You is the phone column stretched to 5,041px (you--populated--1280--dark.png). |
| category | M | 7 | 8 | **regressed** | defect | The card gate's 'Save my card' sits below the fold at 375 (onboarding--card-gate--375--dark.png) and the handle defaults from the email with its domain ('@averyfixtureexamplei', onboarding--card-gate--402--light.png). |
| craft | M | 7 | 7 | open | defect | Header search button measures 33x33 (inline padding 6px + 21px glyph, index.html:4759) beside a 44x44 bell - measured in the DOM at 375. Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 9 | resolved | defect | Ellipses clip the home course and the recent-round course names at 375 ('SAGUARO FLATS MUNICIPAL (FI…', 'MESQUITE WASH GOLF CL…') (you--populated--375--dark.png). The card gate suggests a handle built from the email, domain included ('@averyfixtureexamplei') (onboarding--card-gate--402--light.png). |

### `web/golfers`

Means: category 6.3 · craft 6.7 · owner 7.1. Lane: W3.

*Category scope:* All five golfers states captured at 9d84c483 (desk--golfers at 02636007) at every width and theme. Proves the list, the person page, the head-to-head and the board. Does not prove search results, a real profile photo or the add-buddy write.

*Craft scope:* All five golfers states at 9d84c483, four widths, both themes. Not captured: search results, a stranger's (non-buddy) card.

*Owner scope:* Golfers at 9d84c483 in both themes and four widths. The person page renders (ledger X01's `.catch` fix holds; the harness title's 'door is broken' note is stale). The rivalry comparison uses You (9d84c483) and Schedule (02636007) captures of the same fixture world.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 7 | open | defect | On the phone the person page buries the credential ~960px down under a course list (golfers--person--375--dark.png) though the desk places it top-right (golfers--person--1280--light.png); the head-to-head prints its title twice ('YOU AND DEVON TESTWELL', then 'YOU AND DEVON') (golfers--h2h--375--dark.png); the list draws the buddy request twice (top card and 'REQUESTS · 1') (golfers--list--375--dark.png). |
| craft | H | 7 | 9 | resolved | defect | The head-to-head says the pairing twice: 'YOU AND DEVON TESTWELL', then 'THE FIXTURE DERBY', then 'YOU AND DEVON' (golfers--h2h--375--light.png, golfers--h2h--375--dark--first.png) |
| owner | H | 7 | 8 | resolved | defect | The same buddy request appears at the top and again under 'REQUESTS · 1' (golfers--list--375--dark.png; both inside one desk viewport, golfers--list--1280--dark--first.png). Two near-identical doors: 'Text someone a link' and 'Send an invite link'. |
| category | T | 7 | 8 | resolved | defect | Good ranked-table type; the double h2h title in two sizes. |
| craft | T | 7 | 8 | open | defect | Mono sub-lines and handles under condensed names; board sheet cards mix five sizes (golfers--board--402--light.png) |
| owner | T | 8 | 8 | open | defect | Mono-heavy rows and chips; the ranking's gloss is 11px mono ('VS PLAYING HCP · PLUS IS BETTER'). |
| category | Sp | 6 | 6 | resolved | defect | 'Text someone a link' is a dark button with ~1-2px padding, so its text touches the border (golfers--list--375--dark.png, golfers--list-empty--375--light.png, desk--golfers--1280--dark.png; index.html:20826). |
| craft | Sp | 6 | 8 | resolved | defect | 'Text someone a link' button has zero inner padding - the label sits flush on its border (golfers--list-empty--375--light.png, golfers--list--375--dark.png) |
| owner | Sp | 7 | 7 | resolved | defect | The 'Text someone a link' box sets its text against the border (golfers--list--375--dark.png y≈790). |
| category | C | 5 | 6 | open | defect | The EVERY MEETING tape draws one merged white bar and one hollow square for ten meetings, so 'One square is one win' cannot be counted (golfers--h2h--375--dark.png, golfers--h2h--1600--light.png); the board paints Wrens golfers orange and Javelinas golfers blue while the standings swatch the squads the other way (memCi uses the array index, standings use q.color; index.html:28552 vs 28493; golfers--board--375--dark.png, desk--season--1280--dark.png); rivalry 3-4 on You vs 5-5 here. |
| craft | C | 6 | 8 | resolved | defect | Squad marks come from a hard-coded SQHEX ['#57A8FF','#FB8B4B','#A78BFA','#2FD3BE'] (index.html:6175, ~20 render sites) instead of the D270 --sq0..3; the #FB8B4B orange reads as ember beside the live band (season--leaderboard--375--dark.png and --light.png sampled #FB8B4B / #57A8FF) - board post bars (golfers--board--375--dark.png); buddy rows are boxed cards under a hairline slat board; the 'Buddies' status is act green and reads as a button (golfers--list--375--dark.png) |
| owner | C | 5 | 6 | open | defect | The rivalry verdict differs by surface. Devon is '3–4 · THEY LEAD · 7 weeks head-to-head' on You (you--populated--375--dark.png) and 'Devon leads 4–3' on the plan (schedule--populated--375--dark.png), but 'All square, 5–5' and 'Devon Testwell has beaten you five times out of ten' on his page (golfers--person--375--dark.png) and 'MET 10 · 5–5' on the head-to-head (golfers--h2h--375--dark.png): `my_rivalries()` counts clash weeks, the page counts weeks both posted. The friends ranking is headed 'THE BOARD' (A-3 renamed it) while the league board is also 'THE BOARD' (golfers--board--375--light.png). |
| category | B | 7 | 8 | open | content | The ranked board with markers, bands and figures reads like a real leaderboard; faces are markers only. |
| craft | B | 7 | 8 | open | content | Slat rail, markers, the every-meeting tape and the credential are proprietary; faces are marker glyphs (content) |
| owner | B | 8 | 8 | open | content | Christened rivalries ('THE FIXTURE DERBY'), markers and the tour card carry the brand. |
| category | P | 6 | 7 | resolved | defect | The broken tape and the unpadded button undercut a well-made list. |
| craft | P | 6 | 8 | resolved | defect | Boxed list rows under a premium slat board (golfers--list--1280--light.png) |
| owner | P | 7 | 8 | resolved | defect | The every-meeting tape renders as one fused white bar and one square, not a tape of meetings (golfers--h2h--375--dark.png). |
| category | R | 7 | 7 | resolved | defect | Board course names clip ('Mesquite Wash G…', golfers--board--375--dark.png). |
| craft | R | 8 | 7 | resolved | defect | Board cards truncate course names ('Mesquite Wash G...' at 375, 'Mesquite Wash Golf ...' at 402) (golfers--board--375--dark.png, golfers--board--402--light.png) |
| owner | R | 6 | 6 | open | defect | A golfer cannot tell which record is true; the ranking never states its window; the board's '+2.4' chips carry no label (golfers--board--375--light.png). |
| category | E | 6 | 7 | resolved | defect | 'Devon Testwell has beaten you five times out of ten.' is real rivalry pull; the tape meant to dramatise it is broken. |
| craft | E | 6 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | E | 8 | 8 | resolved | defect | Naming a rivalry and 'You have taken the last four' carry real pull, but the person headline frames a 5–5 tie as a loss ('has beaten you five times out of ten'). |
| category | D | 6 | 7 | open | defect | list-empty repeats its two doors as links and then as sections (golfers--list-empty--375--light.png); the person page is long on the phone. |
| craft | D | 7 | 8 | open | defect | The list page stacks requests, finder, invite, buddies, requested and playing-soon in one column (golfers--list--375--dark.png) |
| owner | D | 7 | 8 | resolved | defect | Buddy rows each repeat 'Buddies' under a 'BUDDIES · 5' head; indexes read '9.8 number'. |
| category | M | 7 | 7 | resolved | defect | Fits at 375/402 with no overflow; clipped course names on the board. |
| craft | M | 7 | 8 | open | defect | Header search button measures 33x33 (inline padding 6px + 21px glyph, index.html:4759) beside a 44x44 bell - measured in the DOM at 375. Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | open | device-or-human | No clipping; targets fine. The head-to-head was reached through window.openHeadToHead in the harness; the person page's 'See the whole record' door is drawn but its tap is not captured. |

### `web/history`

Means: category 6.9 · craft 7.2 · owner 7.4. Lane: W1 (receipts), W2 (the record on You).

*Category scope:* record and receipt captured at 9d84c483. record--populated/photos-none/photo-broken are the You page (byte-identical), photo-credited is the golfer card, photo-withdrawn is the public dead link (identical to public-round--dead-link). The receipts are fully evidenced; the record's photo states are not.

*Craft scope:* record--* and receipt--* at 9d84c483. record--populated, --photos-none and --photo-broken are identical to you--populated (checked by pixel diff), so the photo-none/broken states are not distinctly captured; scored on credited, withdrawn and the two receipts.

*Owner scope:* Record and receipt at 9d84c483. record--populated/photos-none/photo-broken are the You page and are byte-identical: the photo states are not captured. record--photo-withdrawn equals public-round--dead-link, which is right under D385. receipt--round captures stop at the grid and consent row, so the points lens is not captured. receipt--points proves §16 end to end (171 = 53 + 48 + 36 + 34).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | The round receipt says '84 gross' as its title and again as the panel's hero (receipt--round--375--dark.png); the points receipt says 171 twice ('Rounds that count 171', 'Total 171') (receipt--points--375--dark.png). |
| craft | H | 8 | 9 | resolved | defect | The receipt sheet's title '84 gross' is plain sans above the photo card that repeats 84 at display size (receipt--round--375--dark.png) |
| owner | H | 8 | 9 | resolved | defect | The round receipt leads with the photo card, then photo controls, then the hole grid; the league verdict and counting (D362/D387) sit below all of it, outside every captured viewport (receipt--round--375--dark.png, receipt--round--1280--dark.png). |
| category | T | 8 | 8 | open | defect | The receipt's serif band and the cream scorecard leaf are well set; the points receipt is a plain list of rows. |
| craft | T | 7 | 8 | open | defect | The photo card's serif sentence sits beside a board 84 and mono meta, three voices in one card (receipt--round--375--dark.png) |
| owner | T | 8 | 8 | resolved | defect | Agate labels on the receipt card ('MESQUITE WASH GOLF CLUB (FIXTURE) · BLACK · SEP 27, 2026') and the points-receipt rows are small mono caps under very large figures (receipt--round--375--dark.png, receipt--points--375--dark.png). |
| category | Sp | 7 | 7 | resolved | defect | Replace/Remove photo sit between the hero and the card (receipt--round--375--dark.png). |
| craft | Sp | 7 | 8 | resolved | defect | 'Replace photo' / 'Remove photo' float under the card with an uneven gap to 'THE CARD' (receipt--round--375--dark.png) |
| owner | Sp | 8 | 8 | resolved | defect | The phone receipt spends its first screen on the card and the Replace/Remove photo buttons (receipt--round--402--light.png). |
| category | C | 5 | 7 | open | defect | P1: EVERY SEASON prints two LIVE seasons under a FINISH head as '1ST' and '2ND' with the podium rule (csRecordLeaf, index.html:17035-17055; you--populated--375--dark.png = record--populated--375--dark.png) though North Grove is in week 8 of 13; the points receipt reads 'AVG vs your playing HCP' on other golfers' rows (receipt--points--375--dark.png) where the house rule is 'their' (index.html:9764); the photo-credited card's 'YOU'VE BOTH PLAYED' is gold (record--photo-credited--375--dark.png). |
| craft | C | 6 | 8 | open | defect | The points receipt prints members' points in pos green (receipt--points--375--light.png) - pos is movement, points are ink; 'YOU'VE BOTH PLAYED' carries a gold rule for a shared-course fact (record--photo-credited--375--dark.png) |
| owner | C | 6 | 8 | open | defect | A birdie in the receipt grid is gold (hole 16, receipt--round--402--light.png, receipt--round--1280--dark.png), against D267's neutral grid and D368's 'not earned gold'. The points receipt says 'AVG vs your playing HCP' on other golfers' rows (receipt--points--375--dark.png). 'YOU'VE BOTH PLAYED' sits in a gold box (record--photo-credited--375--dark.png). |
| category | B | 8 | 8 | open | content | The receipt panel (contour, pennant, 'ANY TIME. ANYWHERE.') and the cream leaf are ours. |
| craft | B | 8 | 9 | open | content | Leaf scorecard and photo card are proprietary; no course image (content) |
| owner | B | 8 | 8 | open | content | The receipt card on the photo with the pennant is on-brand; every photo in evidence is the synthetic 'FIXTURE PHOTO'. |
| category | P | 7 | 7 | open | defect | The receipt is made; the points receipt is a list; every recent-round row carries a × beside the score (you--populated--375--dark.png). |
| craft | P | 7 | 8 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | P | 8 | 8 | open | content | The ledger feel holds; the card's scrim almost hides the synthetic photo (receipt--round--375--dark.png). |
| category | R | 7 | 8 | resolved | defect | Recent rounds ellipsize course names ('MESQUITE WASH GOLF CL…', you--populated--375--dark.png). |
| craft | R | 8 | 8 | resolved | defect | Leaf hole rows at 11-12px mono (receipt--round--1280--light.png) |
| owner | R | 6 | 8 | resolved | defect | The record's 'EVERY SEASON · FINISH' table shows live seasons as finishes with podium marks (you--populated--375--dark.png; index.html:31909, :17043). The round receipt's points lens is not visible in any capture. |
| category | E | 6 | 7 | open | content | The receipt's band over the photograph works; the archive is a table without a single trophy moment (no won season in the fixture). |
| craft | E | 6 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | E | 7 | 8 | resolved | content | The record's photo states prove nothing: record--photos-none and record--photo-broken are byte-identical to record--populated at every width and theme, and no photograph appears in any of them. |
| category | D | 7 | 7 | open | content | Right; only two seasons exist to test the leaf. |
| craft | D | 7 | 8 | open | device-or-human | record--photos-none and record--photo-broken are pixel-identical to you--populated, so no distinct no-photo or broken-photo state of the record is evidenced |
| owner | D | 8 | 8 | resolved | defect | The points receipt is right ('Tap any golfer for the rounds behind their points'); the round receipt makes the golfer scroll past photo controls to reach the reason they opened it. |
| category | M | 7 | 8 | open | device-or-human | record--photos-none and record--photo-broken are byte-identical to the populated You page at every width (the record lives inside You), so those two states are not evidenced. |
| craft | M | 8 | 9 | open | device-or-human | Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | resolved | defect | A bare '×' (Delete round) sits beside every recent round's gross on the record (you--populated--375--dark.png). |

### `web/season`

Means: category 7.2 · craft 6.9 · owner 7.6. Lane: root (no lane).

*Category scope:* The season page's five windows (phone captures are viewport windows of one 5,992px page; desk--season is the full page) at every width and theme (02636007). Rules are scored as web/rules. Does not prove the reveal/motion, the Pro's money edits, or print output.

*Craft scope:* Season captures are viewport shots scrolled to each section (narrative, leaderboard, story, pot, pot-pro, rules) plus the full-page desk--season (02636007). Not captured: a complete season's ceremony.

*Owner scope:* Six season sections as viewport captures, four widths, both themes (02636007). The pay note's presence differs by state (a harness variant, not a contradiction).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 8 | 8 | open | defect | Band → story sentence → clash → standings is right; the 'THE SEASON'S STORY →' door and the four section pills compete right under the band (season--narrative--375--dark.png). |
| craft | H | 7 | 8 | open | defect | The 'POS' column head is set larger than the names it heads, and the clash block sits between the month band and the table (season--leaderboard--375--light.png); 5992px page |
| owner | H | 8 | 8 | resolved | defect | 'LEAVE THE SEASON' sits between the rules link and the story (season--story--375--light.png). |
| category | T | 7 | 8 | resolved | defect | 'POS' is set at display size (~26px bold) beside 11px mono column heads (season--leaderboard--375--dark.png, season--leaderboard--402--light.png, desk--season--1280--dark.png); 'GOLFER' heads a column of squads. |
| craft | T | 7 | 8 | open | defect | 'POS' set as display text; 11px mono meta ('SUN AUG 9 -> SAT NOV 7 - 13 WKS - THE PRO - BLAKE SAMPLE', season--narrative--375--dark.png) |
| owner | T | 8 | 8 | open | defect | Buy-ins are small sans names in bordered boxes with checkboxes (season--pot--375--dark.png). |
| category | Sp | 7 | 8 | resolved | defect | The GAP column prints '+34–' (the gap glued to the held-movement dash) (season--leaderboard--375--dark.png); the season switcher's second pill is cut at the edge (season--narrative--375--dark.png). |
| craft | Sp | 7 | 8 | open | defect | A heavy 2px black rule under 'TOP SEED - +10' cuts the table (season--leaderboard--375--light.png); the seasons chip row cuts a chip mid-word at the edge (season--narrative--375--dark.png) |
| owner | Sp | 7 | 8 | resolved | defect | At 402 the LEAGUE admin block (roster, share, squads) fills most of the rules viewport (season--rules--402--dark.png). |
| category | C | 5 | 7 | resolved | defect | The EVERY GOLFER table paints Javelinas golfers blue and Wrens golfers orange directly under standings that swatch the squads the other way (desk--season--1280--dark.png; memCi vs q.color, index.html:28552/28493); 'LEAVE THE SEASON' sits above 'THE SEASON'S STORY' (season--story--375--dark.png); '1 still owe' (season--pot--375--dark.png). |
| craft | C | 5 | 8 | resolved | defect | Squad marks come from a hard-coded SQHEX ['#57A8FF','#FB8B4B','#A78BFA','#2FD3BE'] (index.html:6175, ~20 render sites) instead of the D270 --sq0..3; the #FB8B4B orange reads as ember beside the live band (season--leaderboard--375--dark.png and --light.png sampled #FB8B4B / #57A8FF); desk 'AVG VS YOUR PLAYING HCP' paints 7 of 8 rows in neg red (desk--season--1280--dark.png) though UI_SYSTEM 2.5 keeps neg for errors and down for cool; 'Print this season' shows on the phone (season--story--375--dark.png) |
| owner | C | 6 | 8 | resolved | defect | Two producers for one rule: the rules say 'Two rounds a month. Miss a month and your first one is forgiven automatically.' (index.html:7340) while Home's minimum adds the −5-a-round penalty (index.html:9755) (season--rules--1280--light.png vs home--member--375--dark.png). 'How it ends' says the weeks 'decide who is in' in a two-squad season whose climb says 'BOTH SQUADS PLAY THE CUP FINAL' (season--rules--402--dark.png vs season--narrative--1280--dark.png). The viewer's 2nd-place squad is outlined and named in gold in the race. The ledger sentence prints twice in one desk viewport (season--rules--1280--light.png). The roster rows use 🔒/🚪 emoji. |
| craft | B | 8 | 9 | open | defect | Ember band with topo, month band, gold rail and pot panel are proprietary; the board section reuses generic post cards (desk--season--1600--light.png) |
| category | P | 7 | 8 | open | defect | The desk season is FPL-grade; on the phone the lower half (admin cards, checkbox buy-ins) looks assembled (season--pot-pro--375--light.png, season--rules--375--dark.png). |
| craft | P | 7 | 8 | open | defect | Pot tiles and buy-in rows are boxed; board cards with neon bars (season--pot--375--light.png, desk--season--1600--light.png) |
| owner | P | 8 | 8 | resolved | defect | Made, but the buy-in list is a checkbox form, identical for members and the Pro (season--pot--375--dark.png vs season--pot-pro--375--light.png). |
| category | R | 8 | 8 | open | defect | Readable; the 11px mono date line under the band is the smallest text carrying a fact. |
| craft | R | 8 | 9 | open | defect | 11px mono meta lines (season--narrative--375--dark.png) |
| owner | R | 7 | 8 | open | defect | Members read 'The link has closed. Add anyone yourself until the halfway turn.' (season--rules--375--dark.png; index.html:24200 writes it before the isPro gate). The GAP column prints '+34' for the squad 34 back, fused with the held bar (season--narrative--1280--dark.png; index.html:8060). '1 still owe' (season--pot--375--dark.png); 'ask them in the board' (season--narrative--1280--dark.png). |
| category | E | 7 | 7 | open | content | For a week-8 season the story is two one-line entries and a Print button (season--story--375--dark.png). |
| craft | E | 7 | 7 | open | content | A synthetic field; the pot and hero sentence carry it (season--narrative--375--dark.png) |
| owner | E | 8 | 8 | open | content | The season's story is two lines for eight weeks (season--story--375--light.png). |
| category | D | 7 | 8 | open | defect | The phone page is 5,992px; the desk is dense but organised. |
| craft | D | 6 | 7 | open | defect | One page repeats the clash (Home), the story (own page) and the rules (row 18); on desk the 340 aside ends near y1440 of 3931 leaving the right column empty (desk--season--1280--dark.png) |
| owner | D | 7 | 8 | open | defect | The phone page is 5,992px; the desk is balanced. |
| category | M | 7 | 8 | resolved | defect | The switcher pill is cut; tables fit at 375. |
| craft | M | 7 | 9 | resolved | defect | Seasons chip scroller cuts a chip mid-word (season--narrative--375--dark.png); Header search button measures 33x33 (inline padding 6px + 21px glyph, index.html:4759) beside a 44x44 bell - measured in the DOM at 375 |
| owner | M | 8 | 8 | resolved | defect | No overflow at any width; the season switcher's second chip is cut at the edge at 375 (season--narrative--375--dark.png). |

### `web/competition`

Means: category 6.4 · craft 7.0 · owner 7.2. Lane: W5.

*Category scope:* Compete (02636007) and the Book (9d84c483) in all states at every width and theme. The harness flagged book--upcoming and book--squads 'FAIL' only because its head check still expects ISO dates after 9d84c483's date formatting; routes are ok and the captures are valid. Does not prove the live Scoreboard updating.

*Craft scope:* compete--* at 02636007, book--* at 9d84c483. The harness logged 16 'route failures' for book--upcoming/--squads because its expected head string predates 9d84c483's date formatting ('Oct 5 - Jan 17, 2027'); the captures render correctly and were used. Book markers measured 11px (index.html:623), at the floor.

*Owner scope:* Compete (02636007) and the Book (9d84c483), four widths, both themes. The harness logged FAIL for book--upcoming and book--squads because it expects the old ISO head; the captures show the new human dates and the manifest rows are ok. Cell receipts, adjustments with reasons, tie ranks and the provenance note all show their work (§16).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | The Scoreboard band leads well (compete--populated--375--dark.png); the Book opens on four native selects above its table (book--squads--375--dark.png, book--race--375--dark.png); Compete empty offers three 11px mono text links and no primary (compete--empty--375--dark.png). |
| craft | H | 7 | 9 | open | defect | Compete empty offers three equal mono text links (START SOMETHING - FIND GOLFERS - I HAVE A CODE) and no button (compete--empty--375--dark.png); on desk it is a small block top-left in a void (compete--empty--1600--light.png) |
| owner | H | 8 | 8 | resolved | defect | The Scoreboard leads well; empty Compete's three doors are quiet mono links over a mostly blank screen (compete--empty--375--dark.png). |
| category | T | 7 | 8 | resolved | defect | Native <select> text in the system face inside a serif/mono Book (book--race--375--dark.png). |
| craft | T | 7 | 8 | resolved | defect | The Book's title 'the Book' is lowercase serif and its controls are native selects in the system face (book--squads--375--dark.png) |
| owner | T | 8 | 8 | resolved | defect | The Book's controls are four native selects in the page's sans (book--race--375--dark.png). |
| category | Sp | 6 | 7 | open | defect | Compete empty leaves ~45% void (compete--empty--375--dark.png); the desk rail 'FINISHED · Nothing finished yet.' sits over a large dead area (desk--compete--1280--dark.png); at 1280 the Book is a 740px dialog showing W1-W11 of 15 and scrolling inside (book--squads--1280--dark.png). |
| craft | Sp | 7 | 8 | open | defect | At 375 the Book's grid scrolls sideways and cuts W3 mid-glyph at the edge (book--squads--375--dark.png, book--finished--375--light.png) |
| owner | Sp | 7 | 8 | resolved | defect | The desk right column holds one row or 'Nothing finished yet.' (compete--populated--1280--dark.png, desk--compete--1600--light.png). |
| category | C | 5 | 8 | resolved | defect | ISO date in the cell receipt 'Blake Sample · 2026-09-21' where every other surface says 'Sep 21' (book--cell-receipt--375--dark.png); '-3 points' with a hyphen; the error state still says 'Select a cell' under 'The Book did not load' (book--error--375--dark.png). |
| craft | C | 6 | 8 | resolved | defect | Native <select> controls and a bordered 'Close' text box in the Book while every other sheet uses an x (book--squads--375--dark.png, book--race--1280--dark.png) |
| owner | C | 6 | 8 | open | defect | 'YOUR MOMENTS' survives though A-4 retired it, and it lists plans; 'The North Grove Ryder (fixture)' appears as Live and as Final with no edition date (compete--populated--1280--dark.png); Book cell receipts print '2026-09-21' beside the reformatted head (book--cell-receipt--375--dark.png). |
| category | B | 8 | 8 | open | defect | The ember band with contours is ours (D381); the Book's table is a spreadsheet. |
| craft | B | 8 | 9 | open | defect | D381 band and the Book's topo head are proprietary; the Book body is a plain table (book--race--375--dark.png) |
| owner | B | 8 | 8 | open | content | The Book and empty Compete carry no Cup Season object beyond the head (book--squads--375--dark.png, compete--empty--375--dark.png). |
| category | P | 6 | 7 | open | defect | The band is a flat slab; the Book's native selects read as an admin tool. |
| craft | P | 6 | 8 | open | defect | Native selects and plain tables inside the Book (book--race--375--dark.png, book--race--402--light.png) |
| owner | P | 7 | 8 | open | defect | The Book reads as a data tool (four selects, a dense grid). |
| category | R | 7 | 8 | open | defect | At 375 the Book cuts its third column and needs horizontal scroll (book--squads--375--dark.png). |
| craft | R | 8 | 9 | resolved | defect | Race chart legend uses two dotted line styles that are hard to tell apart (book--race--402--light.png) |
| owner | R | 7 | 9 | resolved | defect | '137 points · 2nd · You are 34 back from Fixture Javelinas' never says the 137 is Fixture Wrens' (compete--populated--375--dark--first.png). The upcoming Scoreboard omits the first-tee date (book--scoreboard-upcoming--375--light.png). A finished Book shows two '1st · Tied' with no champion named (book--finished--375--dark.png). |
| category | E | 6 | 7 | open | defect | '2nd · You are 34 back from Fixture Javelinas.' pulls; the Book has no moment in it. |
| craft | E | 7 | 8 | resolved | defect | The scoreboard band carries the stakes; the Book is utilitarian (book--squads--402--light.png) |
| owner | E | 7 | 8 | open | content | Empty Compete is about 70% blank (compete--empty--375--dark.png). |
| category | D | 6 | 7 | open | defect | Populated Compete is right; empty is starved; the Book is crammed at 375. |
| craft | D | 7 | 8 | resolved | defect | Desk Compete's FINISHED column holds one row or 'Nothing finished yet.' (desk--compete--1280--light.png, compete--empty--1600--light.png) |
| owner | D | 7 | 8 | resolved | defect | 'Behind the points · Select a cell…' shows in the upcoming and error states, where there are no cells (book--upcoming--375--dark.png, book--error--375--dark.png). |
| category | M | 6 | 7 | open | defect | The Book table overflows its container at 375 and at 1280; empty-state doors are small text links. |
| craft | M | 7 | 8 | open | defect | The Book's grid scrolls sideways at 375 with no pinned name column or edge cue (book--squads--375--dark.png, book--finished--375--light.png); selects measure ~44px. Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | open | defect | The Book grid scrolls horizontally at 375 with a cut column and no affordance (book--squads--375--dark.png). |

### `web/events`

Means: category 6.4 · craft 7.0 · owner 7.6. Lane: W2.

*Category scope:* Ryder live, finished, unavailable and failed-read at every width and theme (02636007). A Major room and a callout room are not in the gallery (not captured).

*Craft scope:* Ryder live/finished/unavailable/failed-read at four widths, both themes (02636007). Not captured: a Major, a callout room, an event before it starts.

*Owner scope:* Live and finished Ryder rooms plus unavailable and failed-read, four widths, both themes (02636007). A Major and a callout room are not captured.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 9 | resolved | defect | The live Ryder's score (5½-2½) is below the fold at 375x667; the first screen is title, sides and dates (events--live--375--dark--first.png). |
| craft | H | 8 | 9 | resolved | defect | Title card and score lead; the weekly clash list then runs long before the rosters (events--live--375--dark.png) |
| owner | H | 8 | 9 | open | defect | At 375 the first screen is the head graphic; the score (5½–2½) and 'need 1 / need 4' begin below the fold (events--live--375--dark--first.png). |
| category | T | 8 | 8 | resolved | defect | Display, serif and mono are well used; only the clipped clash names hurt (see R). |
| craft | T | 7 | 9 | resolved | defect | Roster legend '1-0-1 - wins - losses - halved' in mono after the figures reads as noise (events--live--375--dark.png y~2120) |
| owner | T | 8 | 8 | open | defect | Pairing names are condensed caps that clip at 375 (events--live--375--dark.png). |
| category | Sp | 6 | 8 | open | defect | Each of the eight roster cards repeats the legend '1-0-1 · wins · losses · halved' (events--live--375--dark.png); clash rows are cramped. |
| craft | Sp | 7 | 9 | resolved | defect | Boxed roster cards under hairline clash rows (events--live--375--dark.png) |
| owner | Sp | 7 | 8 | resolved | defect | The desk is the phone column widened: pairing figures sit ~700px apart with no second column (events--live--1280--dark.png, events--finished--1280--light.png). |
| category | C | 5 | 8 | resolved | defect | 'Fixture Hawks hold the Ryder 1-0 · Fixture Hawks hold it' says it twice; CAPTAIN is gold though gold is earned (D359); 'Tell me when he posts' is product copy (index.html:24615) breaking the product's own they/them rule (index.html:9767); the plates carry both '← HOME' and 'Back to Compete' (events--unavailable--375--dark.png). |
| craft | C | 6 | 9 | resolved | defect | In light the pinned-dark title card draws its discs from the light pigments, so the marker glyphs vanish (events--live--402--light--first.png, events--finished--375--light--first.png) - UI_SYSTEM 16.1 resolves a ceremony object to dark tokens |
| owner | C | 7 | 8 | resolved | defect | 'CAPTAIN' is gold and board posts carry gold rules (events--live--375--dark.png), against D359; 'Fixture Hawks hold the Ryder 1–0 · Fixture Hawks hold it' says it twice. |
| category | B | 8 | 8 | open | content | A tournament graphic (black hero, labelled squad disc groups, LIVE). |
| craft | B | 8 | 9 | open | content | Tournament title card, pigment discs and halves figures are proprietary; the rest is lists (events--live--375--dark.png) |
| category | P | 6 | 7 | open | defect | Hero is premium; roster cards and clash rows look assembled (events--live--375--dark.png). |
| craft | P | 7 | 9 | resolved | defect | Roster and board as boxed cards (events--live--375--dark.png) |
| owner | P | 8 | 8 | resolved | defect | Rosters are bordered boxes with mono W-L-H lines (events--live--375--dark.png). |
| category | R | 6 | 8 | resolved | defect | At 375 nearly every clash name is ellipsized ('HARPER EXAMPL…', 'FINLEY STUB…', 'CASEY PLACEHO…') so you cannot read who played whom (events--live--375--dark.png, events--finished--375--light.png). |
| craft | R | 6 | 9 | resolved | defect | Light-theme disc glyphs unreadable (events--live--402--light--first.png); clash rows truncate both names at 375 ('EMERY MOCKR... vs CASEY PLACEHO...', events--live--375--dark.png y~1060) |
| owner | R | 7 | 8 | resolved | defect | Pairing names clip ('HARPER EXAMPL…', 'CASEY PLACEHO…') and the pairing margins carry no label (events--live--375--dark.png), against §16A.3. |
| category | E | 7 | 8 | open | device-or-human | The hero and 'Run it back' pull; the score's arrival is not visible in stills. |
| craft | E | 7 | 7 | open | content | A synthetic Ryder (fixture names); the 5 1/2 - 2 1/2 figures carry it |
| owner | E | 8 | 8 | open | content | The finished room's win is one sentence ('Final. Fixture Hawks took it 7–5.'); MVP and trophies are not in the captured screens (events--finished--375--light.png). |
| category | D | 6 | 8 | resolved | defect | Roster legend x8; the desk puts names and scores ~550px apart in one wide column (events--live--1280--dark.png). |
| craft | D | 7 | 9 | resolved | defect | Desk renders one long column where rosters and board could sit beside the clashes (events--live--1280--dark.png) |
| owner | D | 7 | 8 | resolved | defect | The desk's right half is empty (events--live--1280--dark.png). |
| category | M | 6 | 8 | resolved | defect | Clipped names and the below-fold score at 375. |
| craft | M | 7 | 9 | open | defect | Name truncation at 375; Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | resolved | defect | Name clipping at 375 (events--live--375--dark.png). |

### `web/schedule`

Means: category 5.0 · craft 6.1 · owner 6.4. Lane: W2.

*Category scope:* Populated, empty, plan sheet and the public plan landing (fixed dark in both themes) at every width (02636007). Does not prove RSVP writes or plan editing.

*Craft scope:* Populated, empty, plan sheet and signed-out plan landing at four widths, both themes (02636007).

*Owner scope:* Four schedule states, four widths, both themes (02636007). The plan sheet itself is strong (the tee named and why, the October worth line reset, RSVP); the score reflects the page and landing around it.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 5 | 8 | resolved | defect | Nothing leads: the calendar grid and the plan cards share one weight, and your next round is one card among many (schedule--populated--375--dark.png). |
| craft | H | 6 | 9 | resolved | defect | Two eyebrows stack at the top ('YOURS, YOUR BUDDIES', YOUR SEASONS'' over 'IN YOUR CREW'S PLANS') and each plan card's 6-7 line caps meta outweighs the golfer's name (schedule--populated--375--dark.png) |
| owner | H | 6 | 8 | resolved | defect | The page has no title, only two stacked mono eyebrows ('YOURS, YOUR BUDDIES', YOUR SEASONS'', 'IN YOUR CREW'S PLANS'), and the calendar outweighs the plans (schedule--populated--375--dark.png). |
| category | T | 5 | 8 | resolved | defect | Each plan card is six or seven lines of 11px mono caps (course + tee + time + rivalry + note) (schedule--populated--375--dark.png). |
| craft | T | 5 | 8 | resolved | defect | Plan meta is mono caps sentences running 6-7 lines ('TODAY - THE CHAMPIONSHIP COURSE AT WHISPERING FIXTURE PINES COUNTRY CLUB - CHAMPIONSHIP - TOURNAMENT TIPS ...') and names mix case with caps suffixes ('Casey Placeholder IN YOUR SEASONS') (schedule--populated--375--dark.png) |
| owner | T | 6 | 8 | resolved | defect | Plan cards set six facts in 11px mono caps (schedule--populated--375--dark.png). |
| category | Sp | 5 | 7 | open | defect | The 'You · 7:40a' row squeezes its text to ~120px beside '2 DAYS [+] [×]', breaking into ~14 one-word lines (schedule--populated--375--dark.png); every calendar day is a filled tile. |
| craft | Sp | 7 | 8 | resolved | defect | The plan card's right slot changes width between a button and a text state (schedule--populated--375--dark.png) |
| owner | Sp | 7 | 8 | resolved | defect | Plan cards pack six facts into ~110px while each calendar day gets a 55px square (schedule--populated--375--light.png). |
| category | C | 4 | 6 | open | defect | P1: the public plan link says 'Avery and Devon are in.' while the plan sheet shows Avery 'NO REPLY' (schedule--plan-landing--375--dark.png vs schedule--plan-sheet--375--dark.png; 20260921100000_the_plan_link.sql counts a missing RSVP as in). The plan sheet prints '8:10A TEE' twice and sets the rivalry box and HOST in gold; the landing's date and border are ember for a casual plan (D359); its CTA is mono. |
| craft | C | 6 | 9 | resolved | defect | The right slot is a button ('I'm in') on one card and plain text ('ON THE SCHEDULE') on the next (schedule--populated--375--dark.png); Dark .card/.stat still paint the D76 charcoal gradient #191C20->#141619 with a #2A2F36 border and a drop shadow (index.html:3658); charcoal covers 35-50% of composer--filled--375--dark--first.png, play--setup-empty--375--dark.png, wizard--step-3-review--375--dark.png |
| owner | C | 6 | 7 | resolved | defect | The tag reads 'IN YOUR SEASONS' where A-7 names the crew; 'HOST' is gold; the plan landing's date is ember with '08:10' against '8:10a' elsewhere (schedule--plan-landing--375--dark.png); the plan sheet prints the tee time and rating/slope twice (schedule--plan-sheet--375--dark.png). |
| category | B | 5 | 7 | open | defect | A utility calendar; the landing's marker medallion is the only proprietary object. |
| craft | B | 6 | 7 | open | defect | A calendar grid and cards; no drawn object - the round ahead has no course plate (schedule--populated--1280--light.png) |
| owner | B | 7 | 8 | open | content | A functional calendar and cards; little that is Cup Season beyond the voice. |
| category | P | 5 | 7 | open | defect | Reads like a list app (schedule--populated--375--dark.png, schedule--populated--1280--dark.png). |
| craft | P | 6 | 8 | resolved | defect | Cards of caps text (schedule--populated--375--dark.png) |
| owner | P | 6 | 8 | resolved | defect | Reads assembled (bordered cards, mono caps). |
| category | R | 5 | 8 | resolved | defect | Walls of caps mono are slow to scan. |
| craft | R | 6 | 8 | resolved | defect | 11px mono caps multi-line meta is the hardest read in the product (schedule--populated--375--dark.png) |
| owner | R | 6 | 6 | resolved | defect | Six-fact mono-caps cards are hard to scan outdoors. |
| category | E | 5 | 7 | resolved | defect | The notes ('Loser buys the breakfast burritos') are the fun and are set as metadata. |
| craft | E | 5 | 7 | resolved | defect | Nothing says 'a round is coming' - no tee time as a figure, no course (schedule--empty--375--light.png) |
| owner | E | 7 | 8 | open | content | Rivalry records on plans ('Casey leads 3–1') and the note ('Bring the good balls.') are strong; the page frame is not. |
| category | D | 5 | 7 | open | defect | Crammed cards; the calendar and the list say the same plans twice. |
| craft | D | 6 | 8 | resolved | defect | Each card packs course, tee, time, rivalry record and a quote into one caps block (schedule--populated--375--dark.png) |
| owner | D | 6 | 8 | open | defect | The desk is one wide stacked column with ~100px calendar cells and a week-by-week standings list that belongs to the season (schedule--populated--1280--light.png). |
| category | M | 6 | 8 | resolved | defect | The squeezed row at 375; day targets are 44px (F15). |
| craft | M | 8 | 9 | open | device-or-human | Calendar days measured 44px at 375 (ledger F15). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | resolved | defect | Unlabelled '+' and '×' on my own plan row (schedule--populated--1280--light.png). |

### `web/wizard`

Means: category 5.4 · craft 6.1 · owner 6.3. Lane: W5.

*Category scope:* Five wizard states for a Pro whose league is in setup (02636007) at every width and theme. The fixture league stores preset 'standard' with counting_cap 4, the state a Pro reaches by picking Standard and changing the cap. Does not prove the lock write, invites or the draw.

*Craft scope:* Five wizard states at four widths, both themes (02636007). Not captured: a successful lock, the draw reveal.

*Owner scope:* Five wizard states, four widths, both themes (02636007). Whether 'Best 4' came from a harness draft or the product's defaults is not proven; the contradiction on screen is. The desk shape is the weaker and is scored.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 8 | resolved | defect | P1: on the desk (≥1100px) step 3 'Review the rules, then start the season' shows no rules: #bylawsReview is display:none and the aside shows only squads, endgame, pot and season (index.html:2182; wizard--step-3-review--1280--light.png, wizard--step-3-review--1600--dark.png). On the phone the washed-out 'Start the season' is disabled with no reason on the step (the missing pay note lives in step 2's Customize fold; index.html:25150; wizard--step-3-review--375--dark.png, --light). |
| craft | H | 6 | 9 | resolved | defect | On the review step the one action, 'Start the season', is disabled with no reason on screen; the reason ('They'll need somewhere to send it.') lives on step 2 and #lockErr stays hidden (wizard--step-3-review--375--dark.png, --375--light.png, --1280--dark.png; wizard--step-2-dials--1280--dark.png; index.html:5541-5542) |
| owner | H | 6 | 8 | resolved | defect | 'Start the season' is disabled on the review step with no reason on that step; the reason ('They'll need somewhere to send it.') lives on step 2 (wizard--step-3-review--375--dark.png, wizard--step-2-dials--1280--dark.png). |
| category | T | 5 | 8 | resolved | defect | Review values are right-aligned mono paragraphs up to six lines (wizard--step-3-review--375--dark.png). |
| craft | T | 6 | 8 | resolved | defect | Help paragraphs and review values are mono (wizard--step-2-help-open--375--dark.png, wizard--step-3-review--375--dark.png) |
| owner | T | 7 | 8 | resolved | defect | The review table is all mono caps (wizard--step-3-review--375--light.png). |
| category | Sp | 6 | 7 | open | defect | Step 1 is a form card with ~50% void below (wizard--step-1-league--375--dark.png); 'HOW OFTEN WILL MOST OF YOU PLAY?' is jammed under the fine print (wizard--step-2-rules--375--dark.png). |
| craft | Sp | 6 | 8 | resolved | defect | 'HOW OFTEN WILL MOST OF YOU PLAY?' abuts the sentence above with no gap (wizard--step-2-rules--375--light.png, wizard--step-2-help-open--375--dark.png) |
| owner | Sp | 7 | 8 | open | defect | Step 2 runs 2,355px at 375 with the dials open. |
| category | C | 4 | 8 | open | defect | The selected Standard card says 'Your best three each month count' while the dial below says 'Best 4' and the review says 'HOUSE RULES Standard · EACH MONTH Best 4 a month count' (wizard--step-2-rules--375--dark.png, wizard--step-3-review--375--dark.png); members' covenant calls best-four 'Standard' (links--join-covenant--375--dark.png). |
| craft | C | 6 | 8 | resolved | defect | Native 'Choose a pace' select; two segmented-control looks; Dark .card/.stat still paint the D76 charcoal gradient #191C20->#141619 with a #2A2F36 border and a drop shadow (index.html:3658); charcoal covers 35-50% of composer--filled--375--dark--first.png, play--setup-empty--375--dark.png, wizard--step-3-review--375--dark.png |
| owner | C | 5 | 9 | resolved | defect | The checked Standard card says 'Your best three each month count' above a 'Best 4' dial, and the review prints 'HOUSE RULES Standard · EACH MONTH Best 4' (wizard--step-2-rules--375--light.png, wizard--step-2-dials--1280--dark.png, wizard--step-3-review--375--dark.png). Step 1 says 'you run this league' against the ruled 'runs the season' (wizard--step-1-league--375--dark.png). |
| category | B | 5 | 6 | resolved | defect | A generic form wizard on the phone; the desk aside's drawn league portrait is the only proprietary object (wizard--step-2-dials--1280--light.png). |
| craft | B | 6 | 7 | resolved | defect | The desk's 'Your league so far' preview is the only proprietary object; the phone has none (wizard--step-1-league--375--dark.png) |
| owner | B | 7 | 7 | open | content | The desk aside 'Your league so far' is a good object; the phone has no equivalent. |
| category | P | 5 | 6 | open | defect | Native date input, stacked boxed fields, a washed-out disabled primary. |
| craft | P | 6 | 7 | open | defect | A stack of form cards (wizard--step-2-rules--375--light.png) |
| owner | P | 6 | 7 | open | defect | Form-first: preset cards are checkbox tiles, dials are ± steppers. |
| category | R | 6 | 8 | resolved | defect | Right-aligned mono paragraphs are slow to read. |
| craft | R | 7 | 8 | resolved | defect | Review values right-aligned in multi-line mono (wizard--step-3-review--375--dark.png) |
| owner | R | 5 | 9 | resolved | defect | On the desk the review step shows no rules: `#view-wizard #bylawsReview{display:none}` ('the sticky aside IS the review', index.html:2182), and the aside omits the counting cap, the minimum, the penalty and the allowance while reading 'FORMING — THE RULES AREN'T SET YET' at the lock (wizard--step-3-review--1280--light.png, wizard--step-3-review--1280--dark.png, wizard--step-3-review--1600--dark.png). |
| category | E | 5 | 6 | open | defect | Presets named Casual / Standard / Cutthroat have character; the rest is settings. |
| craft | E | 5 | 6 | resolved | defect | Starting a season has no moment on review (wizard--step-3-review--375--light.png) |
| owner | E | 6 | 7 | open | content | 'Set once, so there is nothing to argue about in October' is the right promise; the surface is a form. |
| category | D | 5 | 7 | open | defect | The dials page is 2,355px at 375; step 1 is starved. |
| craft | D | 7 | 9 | open | defect | The dials step runs 2355px at 375 (wizard--step-2-dials--375--dark.png) |
| owner | D | 7 | 8 | open | defect | Step 2 mixes presets, pace, dials, money and calendar in one scroll (wizard--step-2-dials--1280--dark.png). |
| category | M | 7 | 8 | open | device-or-human | 44px help targets (F14) and no overflow; keyboard and AX not captured. |
| craft | M | 6 | 9 | open | defect | Disabled primary with its reason off-screen (see H). Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | resolved | defect | The league-name placeholder clips at 375 (wizard--step-1-league--375--dark.png). |

### `web/courses`

Means: category 7.5 · craft 7.5 · owner 7.3. Lane: root (no lane).

*Category scope:* Course books (inside You) and the course card for 18, 9 without yardage and a long tee at every width and theme (02636007). Rating a course and editing a note are not captured.

*Craft scope:* Course book and three card variants at four widths, both themes (02636007).

*Owner scope:* The course book and three card states (02636007). courses--books is byte-identical to you--populated. The D391 course page (circle best, faces) is not captured on this surface.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 8 | 8 | resolved | defect | Plate → figures → rating → card is clear; a very long name wraps to seven lines on the plate and pushes the figures below the first screen (courses--card-long-tee--375--dark.png). |
| craft | H | 8 | 8 | open | defect | The '4.0' community figure and the plate title compete for the first read (courses--card-18--375--dark.png) |
| owner | H | 8 | 8 | resolved | defect | A long course name takes the whole first screen (courses--card-long-tee--402--light.png). |
| category | T | 8 | 8 | resolved | defect | Strong; the plate's caps name at seven lines is the only strain. |
| craft | T | 8 | 8 | resolved | defect | Plate titles wrap to four lines of caps at 375 (courses--card-long-tee--375--light.png) - whole, but heavy |
| owner | T | 8 | 8 | open | defect | The facts line ('72 PAR · 6,790 YDS · 71.8 RTG · 129 SLOPE') runs figures and labels inline in small mono (courses--card-18--375--dark.png). |
| category | Sp | 7 | 8 | open | decision | Long-name plates crowd the yardage bars; 'AVAILABLE OFFLINE · SAVED TODAY' repeats under every course (courses--books--375--dark--first.png, you--populated--375--dark.png). |
| craft | Sp | 7 | 7 | resolved | defect | The 9-hole leaf without yardage spaces its columns unevenly (hole row reads 1 2 _3 _4 5 6 _7 8 _9) (courses--card-9-no-yardage--375--dark.png) |
| owner | Sp | 7 | 7 | open | defect | Rating, notes and the whole scorecard stack in one long sheet (courses--card-18--375--dark.png). |
| category | C | 7 | 7 | open | defect | The tee picker on the plate is a native <select> ('Blue — 70.1 / 121 · 6,412 yds') (you--populated--375--dark.png, courses--books--375--dark--first.png). |
| craft | C | 7 | 7 | resolved | defect | Same 9-hole leaf misalignment |
| owner | C | 7 | 8 | open | defect | The course sheet carries only your own history ('You have played here 2 times · best 84'); Home's wire promises 'YOUR CIRCLE'S BEST' (home--member--375--dark.png) and that circle is not on this surface. |
| category | B | 8 | 8 | open | content | The drawn 18-bar yardage card is proprietary; there is no photograph of a course anywhere. |
| craft | B | 8 | 9 | open | content | Bar plate and leaf are proprietary; no course photograph (content) |
| owner | B | 8 | 8 | open | content | The drawn yardage card is proprietary; no course photograph. |
| category | P | 7 | 7 | open | content | A made object, but no picture of the place (BRIEF §11/§20). |
| craft | P | 7 | 8 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | P | 7 | 7 | open | content | No course imagery anywhere (brief §11, §20). |
| category | R | 8 | 8 | open | defect | Readable; the cream leaf's figures are small but clear. |
| craft | R | 8 | 8 | open | defect | Leaf numerals at 11-12px (courses--card-18--375--dark.png) |
| owner | R | 8 | 8 | resolved | defect | 'best 84' has no visible path to its round (D391: the best carries its source round). |
| category | E | 6 | 6 | open | content | The rating and buddies' one-line notes carry some pull; no picture. |
| craft | E | 6 | 6 | open | content | No photograph of any course (courses--card-18--375--dark.png) |
| owner | E | 7 | 7 | open | content | Buddies' notes and ratings are warm; nothing visual. |
| category | D | 8 | 8 | open | content | Right. |
| craft | D | 8 | 8 | open | defect | Balanced; the 'also kept' rows repeat bar strips with no figure |
| owner | D | 6 | 8 | resolved | defect | On You, every course renders its full scorecard inline (you--populated--375--dark.png y≈4000–6400). |
| category | M | 8 | 8 | open | device-or-human | The leaf folds into OUT/IN at 375 (F06); AX sizes not captured. |
| craft | M | 8 | 8 | open | device-or-human | Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | open | device-or-human | The captures are element crops that include the page beneath the sheet (courses--card-9-no-yardage--375--dark.png). |

### `web/settings`

Means: category 6.1 · craft 6.5 · owner 7.2. Lane: W2.

*Category scope:* Card, settings and delete-confirm at every width and theme (02636007). Push permission, sign-out and delete are not driven.

*Craft scope:* Card, settings and delete-confirm at four widths, both themes (02636007). Contrast of the delete label measured from pixels in the captures.

*Owner scope:* Three Card & settings states, four widths, both themes (02636007). The scan disclosure and the membership line are honest.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 7 | resolved | defect | Title and segmented control, then a flat run of equal-weight chip buttons (settings--settings--375--dark.png). |
| craft | H | 7 | 9 | resolved | defect | Routine switches and account actions share one list; nothing groups what a golfer changes often (settings--settings--375--light.png) |
| owner | H | 7 | 8 | resolved | defect | At 375 two markers are tinted (The Saguaro selected, The Pews highlighted) with no legend (settings--card--375--dark.png). |
| category | T | 6 | 7 | resolved | defect | Mono caps heads over sans chips; flat. |
| craft | T | 7 | 8 | resolved | defect | Mono eyebrows; state words inside button labels ('Round posts: ON') (settings--settings--402--dark.png) |
| owner | T | 7 | 8 | resolved | defect | Toggle state is carried by text in pills ('Round posts: ON') (settings--settings--375--dark.png). |
| category | Sp | 7 | 8 | resolved | defect | Tidy; chip labels wrap ('Scorecard scanning with Claude: OFF'). |
| craft | Sp | 7 | 8 | resolved | defect | Chips wrap in ragged rows of different widths (settings--settings--375--light.png) |
| owner | Sp | 8 | 8 | open | defect | Sections share one weight; identity (the card) and app settings differ only by the tab. |
| category | C | 5 | 8 | resolved | defect | Notification and scanning toggles are buttons reading 'Round posts: ON' / 'Chat: ON' / '…: OFF' while the copy calls them switches (settings--settings--375--dark.png); in the marker grid a focused tile (bg1) looks like a second selection beside the chosen ink tile (settings--card--375--dark.png, settings--card--402--light.png; index.html:1019/1668). |
| craft | C | 6 | 9 | resolved | defect | Toggles are text buttons that carry their state in the label ('Round posts: ON', 'Scorecard scanning with Claude: OFF') rather than a checked control (settings--settings--375--light.png, settings--settings--402--dark.png) |
| owner | C | 7 | 9 | resolved | defect | Notification switches are split between Settings and the inbox sheet (home--inbox--375--dark.png); the delete confirm omits that posts and comments become '[removed]' and shares are withdrawn (D396) (settings--delete-confirm--375--light.png). |
| category | B | 5 | 6 | open | decision | Settings; the marker grid is the only proprietary element. |
| craft | B | 7 | 7 | open | decision | The marker grid is proprietary; the rest is a settings form (settings--card--375--dark.png) |
| owner | B | 7 | 7 | open | content | The marker grid has personality; the rest is a generic settings sheet. |
| category | P | 5 | 7 | resolved | defect | ON/OFF chip buttons look assembled. |
| craft | P | 6 | 7 | resolved | defect | A form in a sheet (settings--settings--1600--light.png) |
| owner | P | 7 | 8 | open | decision | A clean sheet with the build stamp in its foot (settings--delete-confirm--375--light.png). |
| category | R | 7 | 8 | resolved | defect | Readable. |
| craft | R | 6 | 9 | resolved | defect | 'Delete permanently' is white on #FF6A5E = 2.81:1 in dark (settings--delete-confirm--375--dark.png, settings--delete-confirm--1280--dark.png); light is 6.57:1 |
| owner | R | 7 | 8 | resolved | defect | FINDABLE BY shows no current value in either theme (settings--card--1280--dark.png, settings--card--1280--light.png): index.html:27649–27652 paints a border that `.mini` does not draw, the cue X19 retired for markers. |
| category | E | 5 | 5 | open | decision | Low by nature; the marker picker is the fun. |
| craft | E | 5 | 6 | open | decision | Utility surface: nothing to feel on a settings sheet beyond the marker grid (settings--settings--375--light.png) |
| owner | E | 6 | 7 | open | content | A settings surface. |
| category | D | 7 | 8 | open | decision | Right. |
| craft | D | 7 | 9 | resolved | defect | Fine; the account block repeats 'how it works' links |
| owner | D | 8 | 8 | open | defect | Notifications, scanning, appearance and membership sit in one scroll at equal weight (settings--settings--375--dark.png). |
| category | M | 8 | 8 | open | device-or-human | Fits; 44px targets. |
| craft | M | 7 | 9 | open | device-or-human | Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | resolved | defect | Pill toggles wrap unevenly at 375 (settings--settings--375--dark.png). |

### `web/play`

Means: category 6.1 · craft 6.2 · owner 7.0. Lane: W1.

*Category scope:* Eight live-scoring states captured at 9d84c483 at every width and theme. Proves setup, scoring, sync-pending, match, skins, confirm and finish. Does not prove group phones, realtime sync, offline replay, or outdoor legibility.

*Craft scope:* All play states at 9d84c483, four widths, both themes. Scoring captures are scrolled viewport frames (docH 1052). Touch sizes are pixel measurements from the captures. Not captured: Wolf, offline, a finish with a failed post.

*Owner scope:* Eight live states at 9d84c483, four widths, both themes. Finish confirm and 'Round posted' are clear (D367). Wolf and the landscape card are not captured.


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | At 375 once scrolled to the golfers the hole header ('HOLE 6 · PAR 4') is hidden under the stuck scoreboard (play--scoring--375--dark.png, --light); the finish is a quiet list with no round figure as its hero (play--finish--375--dark.png). |
| craft | H | 7 | 9 | resolved | defect | At 375 the sticky leader box sits over the hole navigator, so the ← HOLE → control is hidden once the golfer scrolls to the steppers (play--scoring--375--light.png, play--scoring--375--dark.png top 150px) |
| owner | H | 7 | 8 | resolved | defect | At 375 the hole navigator scrolls away under the sticky scoreboard while the golfer enters scores (play--scoring--375--dark.png; visible at 402, play--scoring--402--dark.png). |
| category | T | 7 | 8 | resolved | defect | Fine; the mono metadata ('14.2 NUMBER · 8 STROKES') is dense. |
| craft | T | 6 | 8 | resolved | defect | Mono carries the leader box, the round meta caps ('LIVE ROUND - SAGUARO FLATS MUNICIPAL (FIXTURE) - SAGUARO FLATS - BLUE - 70.1/121') and the side-game panels (play--sync-pending--375--light.png) |
| owner | T | 7 | 8 | resolved | defect | Mono rows ('14.2 NUMBER · 8 STROKES') carry the working data. |
| category | Sp | 7 | 7 | open | defect | Setup is three stacked bordered cards (play--setup-empty--375--dark.png). |
| craft | Sp | 6 | 8 | **regressed** | defect | The sticky leader box and the site header both stick at top:0 - the header's rule pokes out on both sides of the box (play--scoring--375--light.png, play--scoring--402--dark.png); the game picker wraps 'Sunningdale Rules' onto its own row (play--setup-empty--375--dark.png) |
| owner | Sp | 7 | 7 | open | defect | Setup is 1,678px at 375 for 'just score' (play--setup-empty--375--dark.png). |
| category | C | 5 | 7 | open | defect | The finish sheet uses the ⛳ emoji as row icons (play--finish--375--dark.png, --light) against BRIEF §19; every golfer row carries the same orange squad bar (live rows hard-code ci:1, index.html:13418/13555) so the swatch means nothing (play--scoring--402--dark.png); the match card and the leader card both say 'AVERY FIXTURE 1 UP'. |
| craft | C | 5 | 8 | resolved | defect | A colour ⛳ emoji marks each posted card on the finish sheet (play--finish--375--light.png; index.html:15704); Dark .card/.stat still paint the D76 charcoal gradient #191C20->#141619 with a #2A2F36 border and a drop shadow (index.html:3658); charcoal covers 35-50% of composer--filled--375--dark--first.png, play--setup-empty--375--dark.png, wizard--step-3-review--375--dark.png (setup); SQHEX orange roster dots; skins counts in pos green (play--skins-scoring--375--light.png) |
| owner | C | 7 | 8 | resolved | defect | Finish rows print a generic ⛳ emoji instead of each golfer's marker (play--finish--375--dark.png; index.html:15704); roster chips wear ember dots (play--setup-filled--375--dark.png). |
| category | B | 6 | 7 | open | defect | The ring/box notation strip is ours; the rest is a generic stepper list. |
| craft | B | 7 | 8 | open | defect | The circle/square hole strip and live ember bars are proprietary; setup is generic boxes (play--setup-filled--375--light.png) |
| owner | B | 7 | 7 | open | content | The live chrome is functional more than branded. |
| category | P | 5 | 7 | open | defect | Functional scoring UI; emoji; small steppers. |
| craft | P | 6 | 8 | open | defect | Boxed setup, emoji on the finish (play--finish--375--light.png) |
| owner | P | 7 | 8 | resolved | defect | Bordered rows with small steppers; made, not crafted. |
| category | R | 7 | 8 | open | device-or-human | Readable in both themes. |
| craft | R | 7 | 9 | resolved | defect | On desk light the selected 'HOLE' segment is #0D1511 on #1F5D3A = 2.37:1 (play--scoring--1280--light.png, play--skins-scoring--1600--light.png); dark is 6.08:1 |
| owner | R | 7 | 8 | resolved | defect | '1 SCORING · 8 QUEUED' is terse (play--sync-pending--375--dark.png). |
| category | E | 5 | 6 | open | defect | The leader line has drama; the finish is flat. |
| craft | E | 6 | 7 | open | content | A synthetic round; the leader line carries the tension (play--match-scoring--375--dark.png) |
| owner | E | 7 | 8 | open | defect | The finish says 'It's on the books and scoring.' but not what the cards earned (play--finish--375--dark.png). |
| category | D | 7 | 8 | open | decision | Right. |
| craft | D | 7 | 9 | resolved | defect | Desk scoring is one ~760px column with the right half empty unless a side game runs (play--scoring--1280--light.png) |
| owner | D | 7 | 8 | open | defect | Rows are dense mono and the strip legend adds a row (play--scoring--402--dark.png). |
| category | M | 5 | 8 | resolved | defect | The stepper buttons are 36x36 (.step button, index.html:1894) on the most-tapped control of a round played one-handed outdoors, below §16.2's 44 (play--scoring--375--dark.png). |
| craft | M | 5 | 8 | open | defect | Stepper -/value/+ measure ~35x37px each (play--scoring--402--dark.png x281-385, y298-335) and setup roster chips 28px tall (play--setup-filled--375--dark.png y735-763), under the 44px floor on the on-course control; the leader box hides the hole navigator at 375 (see H); desk HOLE/CARD toggle ~23px. Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 7 | 8 | open | device-or-human | The desk live round is a 600px phone column (play--scoring--1280--dark.png); on-course use (sun, one hand) needs device evidence. |

### `web/rules`

Means: category 6.8 · craft 7.1 · owner 7.2. Lane: root (no lane).

*Category scope:* The season page's rules window at every width and theme (02636007).

*Craft scope:* The rules section of the season page (season--rules at four widths, both themes, 02636007).

*Owner scope:* The rules section of the season page, four widths, both themes (02636007).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 6 | 8 | resolved | defect | At 375 the rules view opens on four LEAGUE admin cards (roster, roster closed, share, squads) before 'THE RULES' (season--rules--375--dark.png). |
| craft | H | 8 | 9 | resolved | defect | Q/A pairs are clear; the head 'THE RULES - HOW THIS SEASON SCORES, AND HOW IT ENDS' wraps to two lines of mono caps (season--rules--402--light.png) |
| owner | H | 7 | 8 | resolved | defect | The rules start below the LEAGUE admin rows in the rules viewport (season--rules--402--dark.png). |
| category | T | 8 | 8 | resolved | defect | Question heads + sentences are right; the heads are 11px tracked mono. |
| craft | T | 7 | 9 | resolved | defect | Mono caps labels over sans answers; long mono eyebrow (season--rules--1280--dark.png) |
| owner | T | 8 | 8 | open | defect | Rule sentences run long under 11px mono heads; the endgame and money sentences are paragraphs (season--rules--1280--light.png). |
| category | Sp | 7 | 8 | resolved | defect | Fine. |
| craft | Sp | 7 | 8 | open | defect | Pairs sit tight under the long head; the league doors above are boxed (season--rules--402--light.png) |
| owner | Sp | 8 | 8 | open | defect | Rules share one scroll with admin rows and the pot, with no break (season--rules--402--light.png). |
| category | C | 6 | 8 | resolved | defect | The desk rules view prints the ledger line twice in one viewport ('What's on it' and under the buy-ins) (season--rules--1280--light.png) against 16A.1; '1 still owe'. |
| craft | C | 7 | 9 | open | defect | Boxed league doors directly above an unboxed rules list (season--rules--402--light.png) |
| owner | C | 6 | 9 | resolved | defect | 'What you owe the season' omits the penalty Home states (index.html:7340 vs :9755); 'How it ends' says the regular season 'decide[s] who is in' for two squads who both play the Final (season--rules--402--dark.png vs season--narrative--1280--dark.png); the ledger sentence twice on desk (season--rules--1280--light.png); 🔒/🚪 emoji above. |
| category | B | 6 | 6 | open | defect | Rules in the product's voice; no object. |
| craft | B | 6 | 7 | open | defect | A plain text section - nothing Cup Season beyond the palette (season--rules--402--light.png) |
| owner | B | 7 | 7 | open | content | Rules in the product's voice; no object. |
| category | P | 6 | 7 | open | decision | A well-set text page. |
| craft | P | 6 | 8 | open | defect | Plain text with mono labels; nothing expensive in the typesetting (season--rules--402--light.png) |
| owner | P | 7 | 8 | open | content | Plain, well set. |
| owner | R | 7 | 8 | resolved | defect | A member reads 'Add anyone yourself until the halfway turn' directly above the rules (season--rules--375--dark.png; index.html:24200). |
| category | E | 5 | 5 | open | decision | It is a rules page. |
| craft | E | 5 | 5 | open | decision | Rules text (season--rules--402--light.png) |
| owner | E | 6 | 7 | open | content | A rules page. |
| category | D | 7 | 8 | open | decision | Right. |
| craft | D | 8 | 8 | open | defect | The rules restate the pot split and the Cup Final that the season page states above them (season--rules--1280--dark.png) |
| owner | D | 8 | 8 | resolved | defect | The sentences are the right density; the missing penalty and the misleading endgame line (see C) are the gap. |
| category | M | 8 | 8 | open | device-or-human | Fits. |
| craft | M | 8 | 9 | open | device-or-human | Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | resolved | defect | At 402 the rules begin ~480px down the section viewport (season--rules--402--dark.png). |

### `web/get`

Means: category 6.2 · craft 7.6 · owner 7.3. Lane: W4.

*Category scope:* get.html at every width and theme (02636007).

*Craft scope:* get.html at four widths, both themes (02636007) + a live DOM measure on 8807 (sizes 12-28px, no failing pairs, only inline links under 44px).

*Owner scope:* static--get at four widths, both themes (02636007).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | Headline and one act 'Open Cup Season' are clear (static--get--375--dark.png). |
| craft | H | 8 | 10 | resolved | defect | Three equal boxed cards; the iPhone card is as prominent as the web app it points away from (static--get--375--dark.png) |
| owner | H | 8 | 8 | open | content | 'Where amateur golf counts. Get it on your phone.' leads and the iPhone beta is stated honestly, but there is no TestFlight public link yet (D371) (static--get--375--dark.png). |
| category | T | 7 | 8 | open | defect | Serif headline, condensed card heads, long sans paragraphs. |
| craft | T | 8 | 9 | resolved | defect | Serif lede, condensed titles, sans body - fine; bold phrases mid-paragraph compete with the titles (static--get--375--light.png) |
| owner | T | 8 | 8 | resolved | defect | The mono nav and eyebrows are 11px caps (static--get--375--dark.png). |
| category | Sp | 7 | 8 | open | decision | Tidy cards; the desk is a narrow column on a wide field (static--get--1280--dark.png). |
| craft | Sp | 8 | 10 | open | defect | Three same-weight boxes stacked at equal 16px gaps give the page no rhythm; the footer sits tight under the last box (static--get--375--dark.png) |
| owner | Sp | 8 | 8 | resolved | defect | At 375 each section is a boxed card, the pattern brief §6 says not to default to (static--get--375--dark.png). |
| category | C | 7 | 8 | resolved | defect | The back link reads '← CUP SEASON' here and '← BACK TO CUP SEASON' on legal (static--legal--375--dark--first.png). |
| craft | C | 7 | 10 | resolved | defect | Header is a '<- CUP SEASON' text link with no pennant, unlike every other page; cards are boxed (static--get--375--dark.png) |
| owner | C | 7 | 9 | resolved | defect | A text-only 'CUP SEASON' header where every app surface signs with the pennant (static--get--375--dark.png). |
| category | B | 4 | 6 | open | defect | No mark, no screenshot, no product image on the page that asks you to install the app (static--get--375--dark.png, static--get--1280--dark.png). |
| craft | B | 6 | 8 | open | defect | No mark, no contour - remove the name and it is a generic install page (static--get--375--light.png) |
| owner | B | 6 | 8 | open | defect | No pennant (D358) and no product object on the page. |
| category | P | 4 | 5 | open | defect | Three text cards. |
| craft | P | 7 | 8 | open | defect | Tidy template (static--get--1280--light.png) |
| owner | P | 7 | 7 | open | content | A plain document page. |
| category | R | 8 | 8 | open | defect | Readable. |
| owner | R | 8 | 9 | resolved | defect | Bold body blocks in 'Somebody sent you a link?' read heavy (static--get--375--dark.png). |
| category | E | 4 | 5 | open | defect | Nothing makes you want it. |
| craft | E | 6 | 6 | open | content | Install copy with no picture of the product (static--get--375--dark.png) |
| owner | E | 6 | 7 | open | content | No product is visible to a stranger arriving from a link (static--get--375--light.png). |
| category | D | 6 | 7 | open | defect | Paragraph-heavy for a download page. |
| craft | D | 8 | 9 | resolved | defect | 'Same account' is said twice across the cards ('Same account, same seasons' / 'the same product on the same account') (static--get--375--dark.png) |
| owner | D | 7 | 8 | resolved | defect | A single column of boxed text with no summary line at the top. |
| category | M | 8 | 8 | open | device-or-human | Fits. |
| owner | M | 8 | 9 | open | defect | Fine at every width; no in-page navigation on phone. |

### `web/support`

Means: category 6.8 · craft 7.5 · owner 7.4. Lane: W4.

*Category scope:* support.html at every width and theme (02636007).

*Craft scope:* support.html at four widths, both themes (02636007) + live DOM measure (no failing pairs, inline links only under 44px).

*Owner scope:* static--support at four widths, both themes (02636007).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 8 | 9 | resolved | defect | The headline says exactly what to do (static--support--375--dark--first.png); the jump links are small caps. |
| craft | H | 8 | 10 | resolved | defect | Anchor row of five condensed-caps links reads as tags (static--support--375--dark--first.png) |
| owner | H | 8 | 9 | resolved | content | Human and honest ('One golfer answers this address'), but the way to write is a link inside a paragraph (static--support--375--dark.png). |
| category | T | 7 | 8 | open | defect | 11px tracked caps jump links and condensed card heads beside the serif headline. |
| craft | T | 8 | 9 | open | defect | Bold lead-ins on every bullet plus a condensed head per section flatten the hierarchy (static--support--375--light.png) |
| owner | T | 8 | 8 | resolved | defect | The mono nav and eyebrows are 11px caps (static--support--375--dark.png). |
| category | Sp | 7 | 8 | open | defect | Tidy. |
| craft | Sp | 8 | 10 | resolved | defect | Long boxed sections run 20+ lines with no break (static--support--375--light.png, y~1833) |
| owner | Sp | 8 | 8 | resolved | defect | At 375 each section is a boxed card, the pattern brief §6 says not to default to (static--support--375--dark.png). |
| category | C | 7 | 8 | resolved | defect | Back link wording differs from legal ('← CUP SEASON' vs '← BACK TO CUP SEASON'). |
| craft | C | 7 | 9 | resolved | defect | No pennant; boxed sections (static--support--1600--dark--first.png) |
| owner | C | 7 | 9 | resolved | defect | A text-only 'CUP SEASON' header where every app surface signs with the pennant (static--support--375--dark.png). |
| category | B | 5 | 6 | resolved | defect | No mark; the voice carries it ('One golfer answers this address'). |
| craft | B | 6 | 8 | open | defect | Generic help page (static--support--375--light.png) |
| owner | B | 6 | 8 | open | defect | No pennant (D358) and no product object on the page. |
| category | P | 5 | 6 | open | decision | Text cards. |
| craft | P | 7 | 9 | open | defect | Tidy template: boxed sections on a flat ground (static--support--375--light.png) |
| owner | P | 7 | 7 | open | content | A plain document page. |
| category | R | 8 | 8 | open | defect | Readable. |
| owner | R | 8 | 9 | resolved | defect | A long single column at 375 (2,819px) without anchors. |
| category | E | 6 | 6 | open | decision | The human voice is warm; no more is expected here. |
| craft | E | 6 | 7 | open | content | 'One golfer answers this address' is warm; nothing else on the page is golf (static--support--375--dark--first.png) |
| owner | E | 7 | 8 | open | content | The humane voice carries it; the page is still a document. |
| category | D | 7 | 8 | open | decision | Right. |
| craft | D | 8 | 10 | resolved | defect | Install guidance repeats what get.html already says (static--support--375--dark--first.png) |
| owner | D | 7 | 8 | resolved | defect | A single column of boxed text with no summary line at the top. |
| category | M | 8 | 8 | open | device-or-human | Fits. |
| craft | M | 8 | 9 | open | device-or-human | Anchor links 38x44; Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | resolved | defect | Fine at every width; no in-page navigation on phone. |

### `web/legal`

Means: category 6.5 · craft 7.0 · owner 7.3. Lane: W4.

*Category scope:* legal.html at every width and theme (02636007). Legal text itself is not judged.

*Craft scope:* legal.html at four widths, both themes (02636007) + live DOM measure (no failing pairs, no text under 12px).

*Owner scope:* static--legal at four widths, both themes (02636007).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | decision | Tabs then a card per document (static--legal--375--dark--first.png); fine for legal. |
| craft | H | 7 | 9 | open | defect | Three equal doc links and a long single document (static--legal--375--light--first.png) |
| owner | H | 8 | 8 | resolved | content | Plain-language v2 (operator named, what is collected, contacts as hashes), but three documents share one long page (static--legal--375--light.png). |
| category | T | 7 | 8 | open | defect | Card heads in condensed, body sans; long bullets. |
| craft | T | 7 | 9 | resolved | defect | No serif; sans at 17px and condensed heads - fine but flat (static--legal--1280--dark--first.png) |
| owner | T | 8 | 8 | resolved | defect | The mono nav and eyebrows are 11px caps (static--legal--375--dark.png). |
| category | Sp | 7 | 8 | open | defect | Tidy. |
| craft | Sp | 8 | 10 | resolved | defect | One box holds the whole policy and headings sit tight to the paragraph above (static--legal--375--light--first.png) |
| owner | Sp | 8 | 8 | resolved | defect | At 375 each section is a boxed card, the pattern brief §6 says not to default to (static--legal--375--dark.png). |
| category | C | 7 | 8 | resolved | defect | Back link wording differs from support/get. |
| craft | C | 7 | 9 | resolved | defect | No pennant; boxed document (static--legal--375--light--first.png) |
| owner | C | 7 | 9 | resolved | defect | A text-only 'CUP SEASON' header where every app surface signs with the pennant; the nav says 'PRIZE POOL DISCLAIMER' where the product says 'the pot' (static--legal--375--dark.png). |
| category | B | 5 | 6 | resolved | defect | No mark on the page. |
| craft | B | 5 | 8 | resolved | defect | Nothing Cup Season beyond the palette |
| owner | B | 6 | 8 | open | defect | No pennant (D358) and no product object on the page. |
| category | P | 5 | 6 | open | decision | Themed and carded; plain by nature. |
| craft | P | 6 | 9 | resolved | defect | Plain boxed document (static--legal--375--light--first.png) |
| owner | P | 7 | 7 | open | content | A plain document page. |
| category | R | 8 | 8 | open | defect | Readable in both themes (F04 fixed). |
| owner | R | 8 | 8 | resolved | defect | 5,767px at 375 without in-page navigation. |
| category | E | 4 | 4 | open | decision | A legal page. |
| craft | E | 5 | 5 | open | content | A legal document (static--legal--375--light--first.png) |
| owner | E | 6 | 7 | resolved | content | A legal document; the opening sentence is humane. |
| category | D | 7 | 8 | open | decision | Right. |
| craft | D | 8 | 10 | resolved | defect | Three documents on one long page with no table of contents (static--legal--375--light--first.png) |
| owner | D | 7 | 8 | resolved | defect | A single column of boxed text with no summary line at the top. |
| category | M | 8 | 8 | open | device-or-human | Fits. |
| craft | M | 8 | 9 | open | device-or-human | Rest frames only: no tap, scroll, keyboard or thumb pass on a real 375pt/402pt device |
| owner | M | 8 | 8 | resolved | defect | Fine at every width; no in-page navigation on phone. |

### `web/desk`

Means: category 6.7 · craft 6.6 · owner 7.1. Lane: each lane for its own surfaces; shared chrome W6 (session B).

*Category scope:* Every 1280/1600 capture viewed as the desk shape (D234), both themes. Hover, keyboard traversal and window resizing between breakpoints are not captured.

*Craft scope:* Every 1280/1600 capture plus desk--* (desk--golfers and desk--you are pixel-identical to golfers--list and you--populated at 1280). Judged as the desk shape (D234).

*Owner scope:* Every 1280/1600 capture was reviewed at contact-sheet scale, the desk--* states at full size; judged as the desk shape (D234).


| Judge | Dim | R1 | R2 | Checker | Kind | What stands between it and 10 (round 1) |
|---|---|---:|---:|---|---|---|
| category | H | 7 | 8 | open | defect | Home, season, composer and the Door use the desk shape well (home--member--1280--dark.png, desk--season--1280--dark.png, composer--filled--1280--dark.png, door--initial--1280--dark.png); You is one column with the right half empty (you--populated--1280--dark.png), Compete has a thin rail over dead space (desk--compete--1280--dark.png), the live Ryder is one wide column (events--live--1280--dark.png), and the wizard's review hides its rules (wizard--step-3-review--1280--light.png). |
| craft | H | 7 | 9 | resolved | defect | Sidebar + lead column read well on two-column pages; on one-column pages (You, Events, Schedule, Play) the page is the phone stack stretched to ~960px (you--populated--1280--light.png, events--live--1280--dark.png, schedule--populated--1280--light.png) |
| owner | H | 7 | 8 | resolved | defect | Home, season, golfers, the person page, the composer, the Book and the door are real desk compositions; the wizard's desk review has no rules to review at the lock (wizard--step-3-review--1280--light.png). |
| category | T | 7 | 8 | resolved | defect | Consistent; the sidebar's stats block is 11px mono. |
| craft | T | 7 | 8 | resolved | defect | The sidebar's standing sentence is a long mono caps block ('NORTH GROVE (FIXTURE) - FIXTURE WRENS 2ND OF 2 - 34 BACK ...') (desk--home--1280--dark.png) |
| owner | T | 8 | 8 | open | defect | The sidebar ME block and identity sit in 11px mono caps at 1280/1600 (home--member--1280--dark.png). |
| category | Sp | 6 | 7 | open | defect | Dead areas on You, Compete and the static pages; the Book is a 740px dialog that scrolls weeks at 1280 (book--squads--1280--dark.png). |
| craft | Sp | 6 | 8 | open | defect | Voids: the share screen is a small column in a black field (share--recap-photo--1280--dark.png), Compete empty is a block in the top-left (compete--empty--1600--light.png), the season aside ends at a third of the page (desk--season--1280--dark.png) |
| owner | Sp | 7 | 8 | resolved | defect | Six surfaces are the phone column widened or centred in a void: You (you--populated--1280--dark.png, 5,041px), the Ryder room (events--live--1280--dark.png), Schedule (schedule--populated--1280--light.png), live scoring (play--scoring--1280--dark.png), public pages (public-round--photo--1280--light.png), the share ceremony (share--recap-no-photo--1280--dark.png). |
| category | C | 6 | 8 | open | defect | Sheets open as centred modals and the notifications popover floats far from its bell (home--inbox--1280--dark.png); the phone shape leaks into You/Compete/Events. |
| craft | C | 6 | 8 | resolved | defect | Two-column on Home, Season, Golfers, Person, Compete, Composer, Wizard, Courses, Book; one stretched column on You, Events, Schedule, Play; a centred phone column on Share - three shapes for one desk |
| owner | C | 6 | 8 | open | defect | The sidebar prints the index twice ('14.2 YOUR NUMBER', '14.2 INDEX'), three times with You's card (desk--you--1280--dark--first.png); its season line repeats Home's 'LEAGUE 2nd' tile (home--member--1280--dark.png); the rail sets day words beside figures ('84 SUN', 'WED 7:40') against §16A.4; the Pro's desk Home is byte-identical to a member's (home--pro--1280--dark.png = home--member--1280--dark.png). |
| category | B | 8 | 8 | open | content | The sidebar lockup, the Door's live boards and the season desk are ours. |
| craft | B | 7 | 8 | open | defect | The sidebar carries the mark, but the desk adds no object of its own - no faces above the table (UI_SYSTEM 14.3) (desk--season--1280--dark.png, desk--compete--1600--dark.png) |
| owner | B | 8 | 8 | open | decision | Pennant and wordmark head every desk page; the build stamp sits in every sidebar foot (home--member--1280--dark.png). |
| category | P | 6 | 7 | open | defect | The season and Door desks feel made; You and Compete read as phone pages on a desk. |
| craft | P | 6 | 8 | open | defect | Two-column pages feel made; stretched and void pages feel reflowed (as Sp) |
| owner | P | 7 | 8 | resolved | defect | Void-heavy stretched pages read unfinished beside the composed ones. |
| category | R | 8 | 8 | open | defect | Readable; long lines in the event room. |
| craft | R | 8 | 8 | resolved | defect | Desk 'AVG VS YOUR PLAYING HCP' in neg red on 7 of 8 rows (desk--season--1280--dark.png) |
| owner | R | 7 | 8 | resolved | defect | The desk drops facts the phone shows in one place (the wizard review); elsewhere readable. |
| category | E | 6 | 7 | resolved | defect | Season and Home desks pull; You's desk is a card on a void. |
| craft | E | 6 | 7 | open | content | The synthetic world has no real photograph: every photo slot renders the fixture placeholder ('FIXTURE PHOTO'), and faces are marker glyphs (receipt--round--375--dark.png, home--member--375--dark.png) |
| owner | E | 7 | 8 | resolved | defect | Composed pages carry pull; stretched ones don't. |
| category | D | 6 | 7 | open | defect | Season is dense and organised; You and Compete are starved at 1280/1600. |
| craft | D | 6 | 9 | open | defect | Width under-used on the stretched/void pages (as Sp) |
| owner | D | 6 | 8 | resolved | defect | Right-hand voids on Compete ('Nothing finished yet.'), the Ryder room and live scoring (desk--compete--1600--light.png, events--live--1280--dark.png). |
| category | M | 7 | 8 | open | defect | No page overflow at 1280/1600; the Book's table scrolls inside its dialog. |
| craft | M | 7 | 9 | resolved | defect | Sidebar nav items are 38px and sub-items 29px tall; the live HOLE/CARD toggle ~23px (DOM at 1280; play--scoring--1280--light.png) - fine for a pointer, short for a touch laptop/iPad |
| owner | M | 8 | 9 | open | device-or-human | No overflow at 1280/1600; keyboard focus and tab order on the desk dialogs are not captured (F03 is verified by test, not by capture). |

## 7 · Every native cell below 9, by row

The same layout as §6, from the `-native.json` files. The two unscored rows show only their scope notes.

### `native/door`

Means: category — · craft — · owner —.

*Category scope:* Not captured: the signed-out Door is not in the synthetic plan (NATIVE-BRIEF). The nearest evidence, the invite and claim arrivals (17pro/invite-signedout-dark-large.png, 17pro/claim-signedout-dark-large.png), is scored under native/claim-invite, not here.

*Craft scope:* Not captured: the signed-out Door is not in the synthetic plan (NATIVE-BRIEF). The only signed-out native frames are the invite door (17pro/invite-signedout-*.png, scored under native/claim-invite) and the boot screens (scored under native/home). Scores null, never guessed.

*Owner scope:* Not captured: the signed-out Door is not in the synthetic plan (NATIVE-BRIEF). The signed-out invite door (17pro/invite-signedout-*.png) and claim pencil are scored under native/claim-invite; the sign-in and code-entry states are unproven on the phone.


### `native/home`

Means: category 7.4 · craft 8.1 · owner 7.9.

*Category scope:* All eight Home states on 17 Pro and SE3, large and AX3, both themes (4112a3f0). Captures are first screens only (no full-page scroll), so the feed below THIS WEEK is not evidenced. Motion, pull-to-refresh and live updates are not captured.

*Craft scope:* All eight home states x 17 Pro/SE3 x large/AX3 x dark/light (64 frames) plus the offline/reconnect flows, at 4112a3f0. First-screen frames: the wire below the lead is not evidenced. Scored on the rest frame; motion and haptics are device evidence.

*Owner scope:* Eight Home states (populated, empty, loading, offline, failed-read, forced-update, long-names, no-season) on 17 Pro and SE3, large and AX3, both themes, plus the offline/reconnect flow. First screens only. The failed-read Home serves cached content under a masthead that says so ("AS OF MON 7:30 AM · OFFLINE") and the offline boot still lets you score: both are exemplary owner behaviour.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | At default size the lead is right (serif sentence, one door, the rank chip owning the standing). At AX3 the masthead (wordmark, index, YOUR NUMBER, the Courses/Activity row) takes the top third, and the first screen reaches only three lines of the headline (17pro/home-populated-dark-AX3.png) or one (se3/home-populated-light-AX3.png). |
| owner | H | 8 | decision | The lead is right ("Blake has led since week two, and you are the one closing." + 2ND ▲1 OF EIGHT + "ten back with seven weeks left"), but its one door is OPEN THE SEASON, not the round that would close the gap (17pro/home-populated-dark-large.png). |
| category | T | 8 | defect | The type voices are well kept. At AX3 the wordmark grows to about 40pt, larger than the lead's serif (17pro/home-populated-dark-AX3.png). |
| owner | T | 8 | defect | The context the lead depends on ("WEEK 6 OF 13 · FIXTURE CUP LEAGUE", "LAST · SAT") is 11pt tracked agate (17pro/home-populated-light-large.png). |
| category | Sp | 7 | defect | AX3 spends the first screen on chrome. At default size the wire's only line between '84 LAST · SAT' and THIS WEEK is a promo, 'The big team match. Two teams. One cup.' (17pro/home-populated-dark-large.png). |
| craft | Sp | 8 | defect | On SE3 at default size the offline dateline stays on the masthead line and squeezes the wordmark to two lines, 'CUP / SEASON' (se3/home-failed-dark-large.png, se3/home-failed-light-large.png); UI_SYSTEM 16.3 says the dateline leaves the line first |
| owner | Sp | 8 | defect | The empty Home opens with a drawn grid glyph above the title, which reads as a missing image (§16A.7) (17pro/home-empty-dark-large.png). |
| category | C | 7 | defect | The offline door's 'Courses on your phone ›' is ember, but it is ordinary navigation (D359: act) (17pro/boot-offline-dark-large.png). The forced-update wall has no door at all: 'Grab the newest one from TestFlight or the App Store' is prose only (17pro/boot-mustupdate-dark-large.png; LINT-21). |
| craft | C | 8 | defect | 'Courses on your phone ›' is ember on an ordinary navigation (D359: ordinary actions are act; ember is competition) (flow__offline.png, 17pro/boot-offline-dark-large.png) |
| owner | C | 7 | defect | Ember on things that are not competition (D359): the Activity count is #E8622C (17pro/home-populated-dark-large.png) and the offline door's "Courses on your phone" link is #A13F0E (17pro/boot-offline-light-large.png). The empty Home heads "Post a round you already played." against A-5's one verb (17pro/home-empty-dark-large.png). |
| category | B | 8 | content | The pennant masthead, the serif lead and the rank chip carry the identity. No face or photograph is above the fold (synthetic world). |
| owner | B | 8 | content | Pennant masthead and the tournament voice carry it; no photograph or face on any captured first screen. |
| category | P | 7 | defect | The empty state's drawn grid glyph reads as a generic table icon (17pro/home-empty-dark-large.png), and on the populated screen the wire is a promo. |
| craft | P | 8 | defect | The must-update screen is three centred lines and nothing else - no mark, no door (17pro/boot-mustupdate-dark-large.png) |
| owner | P | 8 | defect | The forced-update gate is a dead end: a headline, a sentence and "needs build 999,999", with no action (17pro/boot-mustupdate-dark-large.png). |
| category | R | 8 | defect | Readable at every size. The loading state's standing line is a run of small mono caps ('FIXTURE CUP LEAGUE · 2ND OF 8 · 10 BACK OF BLAKE · 1 CLEAR OF DEVON · TOP 2 INTO THE FINAL, OPENS OCT 23') (17pro/home-loading-dark-large.png). |
| craft | R | 8 | defect | At AX3 on SE3 the must-update instruction truncates ('...TestFlight or the...') on a blocking screen with no scroll (se3/boot-mustupdate-light-AX3.png; MustUpdateView has no ScrollView, RootView.swift:481-492) |
| owner | R | 8 | defect | The occasion row "The big team match. Two teams. One cup." names no Ryder, no date and no stake (17pro/home-populated-dark-large.png; §4.36). |
| category | E | 7 | content | The lead sentences pull ('Blake has led since week two, and you are the one closing.'), but no faces or pictures appear above the fold. |
| craft | E | 7 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png); the populated Home's round row is a figure on a rule, not a picture (17pro/home-populated-dark-large.png) |
| owner | E | 8 | content | The after-golf prompt ("Blake had you on the plan for Fri. Nothing posted yet. · ADD MY ROUND · LATER · DIDN'T PLAY", 17pro/home-solo-light-large.png) and the chasing lead carry pull; nothing visual on the first screen. |
| category | D | 8 | content | One fact per place: the chip owns the standing and the lead says it in prose. Nothing is repeated on the first screen; below the fold is not captured. |
| craft | D | 8 | device-or-human | home-long is pixel-identical to home-populated on the first screen (checked by diff), so the long-name stress is not evidenced; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | device-or-human | Captures are first screens; the wire below, where the web's density problems lived, is not captured on the phone. |
| category | M | 7 | defect | Targets are 44pt and nothing clips at 375 or 402. The AX3 first screen is spent on chrome, as noted under H. |
| craft | M | 7 | defect | Must-update truncation at AX3 (se3/boot-mustupdate-light-AX3.png) and the SE3 masthead wrap (se3/home-failed-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | defect | AX3 wraps whole, but on the 17 Pro at AX3 only "Blake has led" fits above the tab bar; the standing sentence is off the first screen (17pro/home-populated-light-AX3.png). |

### `native/post`

Means: category 6.6 · craft 6.4 · owner 7.4.

*Category scope:* Cover, composer (first round, member, keyboard) on both phones, both sizes and both themes, plus the keyboard and refused-post flows (17 Pro, large, dark). A filled composer and the photo and scan flows are not in the matrix. The refused-post still does not show the toast.

*Craft scope:* Composer, first-round, keyboard and the Play cover across all eight variants, plus the post-failed and composer-keyboard flows (17 Pro large dark), at 4112a3f0. The 'AutoFill' bubble in composer-keyboard is the system edit menu from the test's tap, not a layout defect.

*Owner scope:* Cover, composer (member and first round) and keyboard states in the matrix, plus the post-failure flow (17 Pro large dark). The verdict after entry is correctly labelled ("Played to your playing HCP · 7 PTS"), unlike the web's '+1.4 YOUR PLAYING HCP'.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | The composer opens with the keypad up on an empty gross slot, which is right for the task. The title is said twice, as the navigation title 'Add my round' and as the eyebrow 'ADD MY ROUND · YOUR INDEX 12.4' (17pro/composer-dark-large.png). |
| craft | H | 7 | defect | With the keyboard up at AX3 the focused YOUR GROSS field is scrolled out of view; the screen shows the worth paragraph, ADD MY ROUND and the keypad but not the field being typed into (17pro/composer-light-AX3.png, se3/composer-dark-AX3.png) |
| owner | H | 8 | defect | The worth sentence (three lines) sits between the gross and the course, pushing the course and tags down (17pro/composer-dark-large.png). |
| category | T | 7 | defect | The inherit line is set in mono ('Add the course · – / – · MON · SEP 28   DONE'), and the gross slot's caret is system blue, not act (17pro/composer-first-dark-large.png). |
| craft | T | 7 | defect | The worth line is a four-line sans paragraph under the gross ('This round can score up to 12 in both Fixture Cup League and Placeholder Squads League. Your best 4 count...') (17pro/composer-dark-large.png) |
| owner | T | 8 | defect | The course, a required fact, is a small mono line: "Add the course · — / — · MON · SEP 28 · DONE" (17pro/composer-dark-large.png). |
| category | Sp | 7 | defect | The system AutoFill bubble sits over the 'YOUR GROSS' label (17pro/composer-keyboard-dark-large.png). |
| craft | Sp | 6 | defect | Content scrolls under the translucent navigation bar with no opaque cap - the 84 gross sits under 'Add my round' at default size (flows/flow__post-failed.png), and at AX3 text runs over the clock ('see the points.', 17pro/composer-light-AX3.png; ghost 'ADD MY ROUND · YOUR INDEX', 17pro/composer-dark-AX3.png) |
| owner | Sp | 7 | defect | The transparent header lets scrolled content run under it: the entered "84" and the eyebrow sit under the back button and title (flows/flow__post-failed.png). |
| category | C | 6 | defect | Two clients disagree on the date (L-34): the composer prints 'MON · SEP 28' for today where the shared day producer says 'TODAY' (the web composer at the same clock). The PLAY cover gives 'Score it live' the ember '● LIVE' eyebrow and rule though nothing is live (D359) (17pro/post-cover-dark-large.png). The caret is system blue. |
| craft | C | 6 | defect | The text caret is iOS system blue #0284E5, the one non-token colour on the screen (17pro/composer-first-dark-large.png, sampled) |
| owner | C | 7 | defect | The refusal sentence says "press Post again" (OrdinaryPost.swift:90) for a button labelled "Add my round" (A-5); the Play cover's "LIVE" row wears ember with nothing live (D359) (17pro/post-cover-dark-large.png). |
| category | B | 7 | defect | The PLAY cover is ours (topo, pennant, 'ANY TIME. ANYWHERE.'). The composer itself is a form over the system keypad. |
| craft | B | 7 | defect | The Play cover is proprietary (contour band, pennant foot, ember LIVE rule on Score it live) but the composer below it is a plain form with no drawn object (17pro/post-cover-dark-large.png vs 17pro/composer-dark-large.png) |
| owner | B | 8 | content | A well-set form in the product's voice; no object of its own. |
| category | P | 6 | defect | The composer's first screen is a boxed photo plate, a blank slot and the system keypad (17pro/composer-dark-large.png, se3/composer-dark-large.png). The category's post flows open on the moment. |
| craft | P | 6 | defect | A refused post is never seen: the composer raises the reason as a toast (PostRoundModel.swift:541), but the composer lives in a fullScreenCover (MainTabView.swift:1043) and the only toast host is the app root's overlay (CupSeasonApp.swift:76; no .csToasts under CupSeason/Post), so the pill draws beneath the cover. The route test found 'Fix the card...' in the element tree at t=19.36s and the screenshot at t=19.82s shows no message (flows/flow__post-failed.png; logs/routes.log) |
| owner | P | 7 | defect | A refused post shows no reason in the captured frame: the only channel is a 2.6-second bottom toast (PostRoundModel.swift:540–542; Toast.swift `seconds: 2.6`), and nothing persists by the button (flows/flow__post-failed.png). |
| category | R | 7 | decision | The worth paragraph puts four numbers in one block ('up to 12 in both … your lowest is a 6, so a 12 would add 6') above the keypad (17pro/composer-dark-large.png). |
| craft | R | 7 | defect | Worth paragraph in mut at bodyS; at AX3 the long sentence pushes the field off screen (se3/composer-dark-AX3.png) |
| owner | R | 8 | defect | With 84 entered the preview reads "7 PTS · PLACEHOLDER SQUADS LEAGUE" while the worth line says the round counts in both leagues; the other league's number is absent (flows/flow__post-failed.png; D387). |
| category | E | 6 | defect | Nothing rewards the golfer until a number is typed ('Enter your gross to see the points.'). The cover is warmer than the composer. |
| craft | E | 6 | content | The Play cover is strong, but the composer itself has no moment before posting (17pro/composer-dark-large.png) |
| owner | E | 7 | device-or-human | The worth line ("so a 12 would add 6") motivates; the finish ceremony is evidenced only as an animation frame (flows/flow__finish-ceremony.png). |
| category | D | 7 | defect | On SE3 the worth paragraph and the keypad fill the screen (se3/composer-dark-large.png). |
| craft | D | 7 | defect | The worth paragraph restates both leagues' caps before the golfer has typed a gross (17pro/composer-dark-large.png) |
| owner | D | 8 | defect | Five full-name tag chips take a third of the screen (flows/flow__post-failed.png). |
| category | M | 6 | defect | At AX3 the navigation title draws over the eyebrow text (17pro/composer-dark-AX3.png). After a refused post, the flow still shows the card, but the refusal toast is not visible in the capture (flows/flow__post-failed.png; the test asserts the text exists). |
| craft | M | 5 | defect | Focused field hidden at AX3 and content under the status bar (17pro/composer-light-AX3.png, se3/composer-dark-AX3.png); the post-failure message is drawn beneath the cover (flows/flow__post-failed.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 6 | defect | At AX3 the member composer scrolls the gross field off-screen above the keypad: the golfer types a score they cannot see (se3/composer-dark-AX3.png, se3/composer-light-AX3.png, 17pro/composer-light-AX3.png; the field shows only in 17pro/composer-dark-AX3.png). |

### `native/share`

Means: category 7.8 · craft 6.9 · owner 7.9.

*Category scope:* Two route-test stills (17 Pro, large, dark, 4112a3f0): the finish ceremony at rest and the share preview. The exported image, the native share sheet, and the no-photo and withdraw paths are not captured.

*Craft scope:* Two flow frames only (17 Pro, large, dark): the finish ceremony caught mid-animation and the share preview. No SE3, light or AX3 evidence. The ceremony's Share colour is read from source (FinishCeremonyView.swift) because the button had not faded in.

*Owner scope:* Two flow screenshots, 17 Pro large dark only. D380's consent is exemplary: the toggle appears because the round has a photo and says what leaves the app; the share action is act, not ember.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | device-or-human | The share preview is clear: a toggle, one explanation, the card, one Share (flows/flow__share-preview.png). The finish-ceremony still shows only the eyebrow, the cup and '84' (flows/flow__finish-ceremony.png), so its full hierarchy (band, points, Share) is not evidenced. |
| craft | H | 7 | defect | The share card's facts crowd the top two-thirds and the bottom third is an empty band above the sign-off (flows/flow__share-preview.png) |
| owner | H | 8 | defect | The consent toggle and its three lines lead; the card preview under them is smaller than the text above it (flows/flow__share-preview.png). |
| category | T | 8 | defect | The preview card reuses the public page's type well. The toggle's explanation runs three lines of body text above the card. |
| craft | T | 7 | defect | The band phrase is set in serif ALL CAPS ('PLAYED TO IT') on the card (flows/flow__share-preview.png) - the serif is a sentence voice and never caps (UI_SYSTEM 1.3/1.4) |
| owner | T | 8 | defect | The preview's facts ("SAT · SEP 26", "ROUND RECORD") render at 9–10pt (flows/flow__share-preview.png). |
| category | Sp | 8 | defect | The preview card sits small in a tall sheet, with about 40% of the sheet spent on the toggle copy. |
| craft | Sp | 6 | defect | Same dead band in the card's lower third (flows/flow__share-preview.png) |
| owner | Sp | 8 | defect | The preview sits in a narrow column with dead space beside "84 GROSS" (flows/flow__share-preview.png). |
| category | C | 8 | device-or-human | It matches the public round record and uses the shared RoundCopy sentence. The ceremony's actions cannot be compared with the web's from the still. |
| craft | C | 6 | defect | The ceremony's Share button is ember (FinishCeremonyView.swift:41-42, 85-88: shareBg = ceremonyBrand) though sharing is an ordinary action (D359); the share-preview sheet's own SHARE is act - two colours for one verb (flows/flow__share-preview.png) |
| owner | C | 7 | defect | The action is "Share round" / "SHARE" here and "Share the card" on the web (L-34) (flows/flow__share-preview.png vs share--recap-photo--375--dark.png). |
| category | B | 8 | defect | Lockup, pennant and 'ANY TIME. ANYWHERE.' are all on the card. The ceremony still carries no mark. |
| craft | B | 8 | content | Pennant, marker and dusk ceremony are proprietary; no course image (content) |
| category | P | 7 | defect | The preview is a shrunken public page rather than the designed share artifact (compare the web's 1080x1350 recap card). |
| craft | P | 7 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| owner | P | 8 | content | The preview's photo is the synthetic gradient; the scrim on real photography is unproven. |
| category | R | 8 | defect | The type on the scaled card is small. |
| craft | R | 8 | defect | The card's sign-off 'ANY TIME. ANYWHERE. cupseason.app' is the smallest text on the artifact (flows/flow__share-preview.png) |
| owner | R | 7 | content | "PLAYED TO IT" is an insider band name for the friend who receives the card (flows/flow__share-preview.png). |
| category | E | 7 | device-or-human | The moment (the cup, the drop, the reveal) is animation; the still is almost empty. |
| craft | E | 6 | device-or-human | The finish ceremony frame was caught at stage 2 of 5 (eyebrow, cup, 84 only; band, points and buttons at opacity 0) (flows/flow__finish-ceremony.png) - the rest frame is not evidenced |
| owner | E | 8 | device-or-human | The golfer sees the card before sharing (the web does not); the ceremony before it is evidenced only mid-animation (flows/flow__finish-ceremony.png). |
| category | D | 8 | content | Right amount. |
| craft | D | 7 | device-or-human | Only 17 Pro large dark is captured for both share surfaces |
| owner | D | 8 | content | The consent copy is complete but three lines for one toggle (flows/flow__share-preview.png). |
| category | M | 8 | device-or-human | Only 17 Pro, large text and dark theme are captured for share. SE3, AX3 and light are not evidenced. |
| craft | M | 7 | device-or-human | Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | device-or-human | Only 17 Pro, large text, dark is evidenced (flows); light, AX3 and SE3 are unproven. |

### `native/public-round`

Means: category — · craft — · owner —.

*Category scope:* Web-only by design (NATIVE-BRIEF): the public round record is a web page with no phone surface. It is not scored. The phone's view of it is the share preview, scored under native/share.

*Craft scope:* Web-only by design (a public link opens in the browser); there is no native surface to score. Recorded null per the brief.

*Owner scope:* Web-only by design (NATIVE-BRIEF): the phone has no public round page. Nothing to score; recorded as null under the output's 'not captured' vocabulary.


### `native/claim-invite`

Means: category 6.5 · craft 6.8 · owner 7.3.

*Category scope:* Claim signed out and signed in, and invite signed out and signed in, on both phones, both sizes and both themes. invite-signedin has an unanswered read in the synthetic backend but renders completely. The OTP completion and the Join write are not driven.

*Craft scope:* Claim confirm (signed in), claim pencil (signed out), invite covenant (signed in) and invite door (signed out), all eight variants, at 4112a3f0. The 8 invite-signedin rows flagged 'unanswered requests' render complete. L-34 comparison read from the two producers (JoinLeague.swift, index.html csCovenantFacts).

*Owner scope:* Four states (claim confirm, claim pencil, invite covenant, invite door), all passes. The covenant is complete (who, length, structure, rules with the allowance, ending, stake, ledger line, split, pay). Its first-name Pro and doubled "Harper" come from the synthetic payload (JoinLeague.swift:198–201 prints proName verbatim) and are not scored. The web's P1 (a dead code reads as an invitation) cannot be checked on the phone: not captured.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | The signed-out claim makes the round the headline, which is better than the web. But the content starts 45% of the way down a blank screen (17pro/claim-signedout-dark-large.png). The signed-out invite leads with the tagline, not the league (17pro/invite-signedout-dark-large.png). |
| craft | H | 7 | defect | The signed-out claim screen floats a small block mid-screen under an empty top half, with no mark (17pro/claim-signedout-light-large.png) |
| owner | H | 7 | defect | The signed-out invite door headlines the slogan "ANY TIME. ANYWHERE." with the invitation as body text (17pro/invite-signedout-light-large.png). The claim doors lead with the round, which is right. |
| category | T | 7 | defect | An ember caps eyebrow sits over a serif sentence. At AX3 the claim sheet clips its 'Scored as…' line under the title (se3/claim-signedin-dark-AX3.png). |
| craft | T | 6 | defect | The invite covenant sets every paragraph in the serif (17pro/invite-signedin-dark-large.png) - UI_SYSTEM 1.4 allows one serif sentence per viewport |
| owner | T | 8 | defect | The signed-out claim sets the whole message in one serif paragraph; the 88, the course and the date are unemphasised (17pro/claim-signedout-light-large.png). |
| category | Sp | 6 | defect | The signed-out claim leaves the top 45% empty (17pro/claim-signedout-dark-large.png, 17pro/claim-signedout-light-large.png). |
| craft | Sp | 7 | defect | At AX3 the claim sheet's pinned footer shears its detail line mid-glyph ('It posts to your rounds...' cut) (se3/claim-signedin-dark-AX3.png, se3/claim-signedin-light-AX3.png, 17pro/claim-signedin-dark-AX3.png) - UI_SYSTEM 13.2a |
| owner | Sp | 7 | defect | The signed-out claim floats one sentence and one button in the lower half of an otherwise blank page (17pro/claim-signedout-light-large.png). |
| category | C | 6 | defect | Sentences differ between the clients (L-34). The native invite says 'You're joining Fixture Friday League. Sign in to review and join.' where the web says 'You're invited to … Sign in to review the league before you join.' The native covenant lists the Pro twice ('Harper runs the season (the Pro). Harper, Blake, …') where the web leaves the Pro out. The 'YOUR SCORECARD' eyebrow is ember, but nothing here is competition (D359). |
| craft | C | 6 | defect | 'YOUR SCORECARD' eyebrow is ember (LiveRoundHost.swift:215 csEyebrow(cs.brand)) on a claim that is not a competition (17pro/claim-signedout-light-large.png); '$25 each.' is gold on the covenant though a buy-in is not an earning (17pro/invite-signedin-dark-large.png) |
| owner | C | 6 | defect | Two sentences for one state across clients: "You're joining Fixture Friday League. Sign in to review and join." (PendingLink.swift:73) vs the web's "You're invited to <league>. Sign in to review the league before you join." (index.html:33733) (L-34). The signed-out claim's "YOUR SCORECARD" eyebrow is ember (#A13F0E) on a non-competition door (D359). |
| category | B | 6 | defect | The signed-out claim carries no mark at all (17pro/claim-signedout-dark-large.png). |
| craft | B | 7 | defect | The claim screens carry no mark; only the invite door does (17pro/invite-signedout-dark-large.png) |
| owner | B | 7 | defect | The signed-out claim carries no pennant or product object (17pro/claim-signedout-light-large.png). |
| category | P | 6 | defect | The signed-out claim looks unfinished; the sheets are tidy but plain. |
| craft | P | 7 | defect | A serif wall on the covenant (17pro/invite-signedin-dark-large.png) |
| owner | P | 7 | defect | The signed-out claim looks unfinished (a blank top half). |
| category | R | 7 | defect | The serif sentences read well, including the nine-paragraph covenant (17pro/invite-signedin-dark-large.png). The AX3 claim sheet clips one line. |
| craft | R | 7 | defect | L-34: the covenant's split and ending sentences differ from the web's. Phone: 'The split: 60 percent to the champion; 25 percent to the runner-up; 15 percent to the Points King, the individual season-points leader.' (JoinLeague.swift:282) vs web 'If you take it: 60 percent to the champion, 25 to the runner-up, 15 to the points king...' (index.html:29627); phone 'The top two golfers qualify for a four-week Cup Final, scored fresh.' vs web 'Everyone plays for themselves. The top two on points meet in a four-week Cup Final.' (17pro/invite-signedin-dark-large.png) |
| owner | R | 8 | defect | "GET STARTED" and "SIGN IN" don't say which one a returning golfer needs (17pro/invite-signedout-light-large.png). |
| category | E | 6 | defect | 'KEEP THIS ROUND' is warm, but there is no picture of the round being kept. |
| craft | E | 7 | defect | The claim has no figure of the round being claimed (17pro/claim-signedin-dark-large.png) |
| owner | E | 8 | defect | "Add this 88 at North Grove (fixture) · White to your record?" is warm; the signed-out claim is flat beside it. |
| category | D | 7 | content | The claim is lean; the covenant is complete. |
| craft | D | 7 | decision | The covenant is a column of paragraphs (17pro/invite-signedin-dark-large.png) |
| owner | D | 7 | defect | The signed-out claim is starved: one sentence (17pro/claim-signedout-light-large.png). |
| category | M | 7 | defect | Buttons are 44pt+. The AX3 clip is noted under T. |
| craft | M | 7 | defect | AX3 footer shear (se3/claim-signedin-dark-AX3.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | device-or-human | AX3 wraps whole (se3/claim-signedout-dark-AX3.png, se3/invite-signedin-light-AX3.png); used, dead, unfinished and not-started claim links and unknown join codes are not captured on the phone. |

### `native/identity`

Means: category 7.5 · craft 7.4 · owner 7.8.

*Category scope:* You (populated, empty, failed), the tour card (own and another golfer), the person page (own and another), the bag, the card gate and the crew step, on both phones, both sizes and both themes. Blake's credential reads '1 round' while the board and the head-to-head show five rounds and eleven meetings. These are separate synthetic envelopes (tourCard is built from the synthetic rounds list), so this is not scored as a product defect.

*Craft scope:* You (populated/empty/failed), tour card (own/other), person (own/other), bag, and onboarding card-gate + crew step, all eight variants, at 4112a3f0. The card-gate chips draw at 28pt with a 44pt hit area (CardGateView.swift:157-159), so no target defect.

*Owner scope:* Card gate, crew step, You (populated, empty, failed), tour card (own and another golfer's), person (me) and the bag, all passes. The failed You is exemplary ("Nothing is lost — the read failed, not the record.").


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | The credential leads every identity surface, and You's first screen is the credential, the last round and the season row. The tour-card sheet's header truncates Share to 'SHA…' on every theme, phone and size (17pro/tourcard-dark-large.png, 17pro/tourcard-other-dark-large.png, se3/tourcard-other-light-large.png, 17pro/tourcard-dark-AX3.png). |
| craft | H | 8 | defect | The bag is a two-column grid of equal filled wells with no hierarchy between driver and wedge (17pro/bag-dark-large.png) |
| owner | H | 8 | defect | The empty You pairs its door with a drawn grid glyph that reads as a missing image (17pro/you-empty-light-large.png). |
| category | T | 8 | defect | Another golfer's credential truncates its figure labels ('HANDICAP IN…', 'ROU…', 'BEST · NORTH GROVE (FIX…') (17pro/tourcard-other-dark-large.png, 17pro/person-dark-large.png). |
| craft | T | 8 | defect | Credential figure labels truncate at default size - on SE3 for every card and on the 17 Pro for another golfer's: 'HANDICAP I...', 'ROU...', 'BEST · NORTH GROVE (F...' (se3/tourcard-other-dark-large.png, se3/tourcard-light-large.png, 17pro/person-dark-large.png) |
| owner | T | 8 | defect | The tour card's stat labels are 9–10pt tracked caps (17pro/tourcard-dark-large.png). |
| category | Sp | 7 | defect | 'SHA…' as noted under H. The bag truncates values inside boxed cells ('Fixture 460 driver,…', 'Sample 3-wood, 1…') (17pro/bag-dark-large.png, se3/bag-dark-large.png). |
| craft | Sp | 7 | defect | The bag's wells truncate their values ('Fixture 460 dri...', 'Sample 3-woo...' on SE3; 'Driv...' at AX3) (se3/bag-dark-large.png, 17pro/bag-dark-AX3.png) |
| owner | Sp | 8 | defect | The crew step stacks four boxed options tightly (17pro/crew-light-large.png). |
| category | C | 6 | defect | P1: FORM marks a nine-hole 43 as the best of the last five, in gold (ProfileFormRow takes the lowest gross regardless of holes; the synthetic 43 is holes: 9) (17pro/tourcard-dark-large.png, 17pro/person-me-dark-large.png). The rivalry name 'THE GROVE GRUDGE (FIXTURE)' is gold, though gold means earned (17pro/you-populated-dark-large.png). The crew step's 'FIND YOUR FRIENDS' carries an ember rule, but it is an ordinary action (17pro/crew-dark-large.png). |
| craft | C | 6 | defect | The Form row golds the 9-hole 43 as the best of the last five against 18-hole grosses (ProfileBlocks.swift:131 takes the minimum gross; the synthetic round is holes: 9, SyntheticWorld.swift:188), and VoiceOver says 'their best' (17pro/person-me-dark-large.png, 17pro/tourcard-dark-large.png) - the same false best as the web |
| owner | C | 7 | defect | Your standing twice in one viewport (the card's "2ND · FIXTURE CUP LEAGUE" and THE SEASON's "02 … 48") (17pro/you-populated-dark-large.png); "POST YOUR FIRST ROUND" against A-5 (17pro/you-empty-light-large.png); an ember rule marks "FIND YOUR FRIENDS" as recommended without the word (D359, §16A.6) (17pro/crew-light-large.png); a single form figure in gold ("43") (17pro/tourcard-dark-large.png). |
| category | P | 7 | defect | The bag and the card gate are forms in boxes (17pro/bag-dark-large.png, 17pro/cardgate-dark-large.png). |
| craft | P | 8 | defect | The bag reads as a form of boxes (17pro/bag-dark-large.png) |
| owner | P | 8 | defect | The bag's club names truncate in fixed boxes ("Fixture 460 dri…", "Sample 3-woo…") (17pro/bag-light-large.png). |
| category | R | 8 | defect | The truncations noted under T and Sp. |
| craft | R | 7 | defect | The tour card's toolbar truncates its Share control to 'SHA...' in every variant (17pro/tourcard-dark-large.png, 17pro/tourcard-light-large.png) |
| owner | R | 7 | defect | Another golfer's card truncates its own labels ("HANDICAP IN…", "ROU…", "BEST · NORTH GROVE (FIX…") and its Share action ("SHA…") at the default size (17pro/tourcard-other-light-large.png, 17pro/person-dark-large.png, 17pro/tourcard-dark-large.png). |
| category | E | 7 | content | The credential pulls; 'Posted 84 at North Grove (fixture) on September 26.' is plain. |
| craft | E | 7 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| owner | E | 8 | content | The crew step ("Bring one now and your first round already counts for something.") and "This is how your buddies see you." carry pull; nothing photographic. |
| category | D | 8 | defect | The credential's '2ND FIXTURE CUP LEAGUE' repeats the season row just below ('02 FIXTURE CUP LEAGUE … 48') (17pro/you-populated-dark-large.png). |
| craft | D | 8 | device-or-human | One credential, one form row and one line per section - right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | device-or-human | You's first screen is balanced; rivals, record and courses sit below the capture. |
| category | M | 7 | defect | Truncations at 402. The AX3 credential grows the page correctly (17pro/tourcard-dark-AX3.png, se3/you-populated-dark-AX3.png). |
| craft | M | 6 | defect | SE3 label truncation and 'SHA...' (se3/tourcard-light-large.png, 17pro/tourcard-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | Truncation on the flagship object at the default size (as R); at AX3 the card's name and stats push the season off the first screen (se3/you-populated-dark-AX3.png). |

### `native/golfers`

Means: category 6.6 · craft 7.2 · owner 7.8.

*Category scope:* Golfers (populated, empty, search), the head-to-head and the league board on both phones, both sizes and both themes. Adding a buddy and posting to the board are not driven.

*Craft scope:* Golfers list, empty, search (keyboard), head-to-head and the season board sheet, all eight variants, at 4112a3f0.

*Owner scope:* List (populated, empty, search keyboard), head-to-head, season board and a person page, all passes. The request block appears once (the web shows it twice) and FINDABLE BY shows its selected value. Blake's '1' round on his card vs '5 rounds' on the board vs eleven meetings are hand-authored synthetic producers (SyntheticWorld+You.swift:194–205, +Golfers.swift:62–110), not scored.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | The head-to-head's record '4–5–1' breaks across two lines ('4–' over '5–1') at default size, so the figure the page exists for reads as two numbers (17pro/headtohead-dark-large.png, se3/headtohead-light-large.png). The title prints once, which is better than the web. |
| craft | H | 8 | defect | The head-to-head record '4-5-1' breaks after its first dash onto two lines at default size, so the object the page exists for reads '4- / 5-1' (17pro/headtohead-dark-large.png, se3/headtohead-light-large.png) |
| owner | H | 8 | defect | The head-to-head's plain verdict ("…has taken the last two.") sits under a record figure that wraps (17pro/headtohead-dark-large.png). |
| category | T | 7 | defect | The record breaks as noted under H. At AX3 the request row breaks a name mid-word, 'TESTC/ASE' (se3/golfers-dark-AX3.png). |
| craft | T | 8 | defect | At AX3 the request row breaks the golfer's name mid-word ('DEVON TESTCA / SE', 'TESTC / ASE') and the handle '@fixture_ / devon' (17pro/golfers-dark-AX3.png, se3/golfers-light-AX3.png) |
| owner | T | 8 | defect | The board's gloss ("VS PLAYING HCP · PLUS IS BETTER") and row labels are 11pt mono (17pro/golfers-dark-large.png). |
| category | Sp | 7 | defect | The empty state repeats 'TEXT SOMEONE A LINK' as a link and then as a card (17pro/golfers-empty-dark-large.png). |
| craft | Sp | 7 | defect | Same mid-word breaks at AX3 (17pro/golfers-dark-AX3.png) |
| owner | Sp | 8 | defect | The empty state stacks a definition, links, search, a link card and the findable control (17pro/golfers-empty-light-large.png). |
| category | C | 5 | defect | The EVERY MEETING tape draws four marks under 'ELEVEN MEETINGS' and a 'LAST FIVE' head (17pro/headtohead-dark-large.png). The board's reaction chips render as empty grey boxes marked '…' (17pro/board-dark-large.png). The request row wears an ember rule and board posts wear gold rules, though neither is competition or earned (D359). |
| craft | C | 7 | defect | Board system notes ('Avery Fixture posted 84...', 'Week 6 opened...') carry a gold spine (BoardRows.swift:129, sampled #806F3C / #AF9C71) - gold is for an earning (17pro/board-dark-large.png) |
| owner | C | 7 | defect | "THE BOARD" names both the friends ranking (17pro/golfers-dark-large.png) and the league chat (17pro/board-light-large.png), the collision A-3 ruled out; the empty state defines a buddy twice and offers "Text someone a link" twice (17pro/golfers-empty-light-large.png); "Message the league…". |
| category | B | 7 | content | The ranked board and the tape are ours. Faces are markers. |
| craft | B | 8 | content | Slat board, faces and the meeting tape carry it; faces are markers (content) |
| owner | B | 8 | content | The christened rivalry and the every-meeting tape are proprietary; the list is plain rows. |
| category | P | 6 | defect | The board looks unfinished because of its placeholder-looking chips. |
| craft | P | 7 | defect | The board's reaction row sets a bare '···' and a comment glyph in small bg2 boxes beside the applause (17pro/board-dark-large.png) |
| owner | P | 8 | defect | The chat board's reaction and comment chips are small unlabelled pills (17pro/board-light-large.png). |
| category | R | 7 | defect | The record split slows the one read that matters. |
| craft | R | 7 | defect | '12.4 index · Fixture...' truncates on SE3 beside the record (se3/headtohead-light-large.png); board composer placeholder truncates at AX3 (17pro/board-dark-AX3.png) |
| owner | R | 7 | defect | The rivalry's headline record breaks across lines ("4–" / "5–1") at the default size on both phones (17pro/headtohead-light-large.png, se3/headtohead-dark-large.png). |
| category | E | 7 | defect | 'Eleven meetings where you both played, going back to May. Blake Sample has taken the last two.' pulls; the broken tape undercuts it. |
| craft | E | 6 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| category | D | 7 | defect | Right, apart from the duplicated door in the empty state. |
| craft | D | 8 | device-or-human | Right for the first screen; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | defect | Right; the empty state is over-worded (see C). |
| category | M | 6 | defect | The AX3 name break is noted under T. The board's chips are unclear as targets. |
| craft | M | 6 | defect | The broken record figure at default size and the AX3 mid-word breaks (17pro/headtohead-dark-large.png, 17pro/golfers-dark-AX3.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | The record wrap (as R). |

### `native/history`

Means: category 7.2 · craft 7.3 · owner 8.0.

*Category scope:* The record (populated, empty), the album (populated, failed) and four receipt photo states (photo, none, broken, withdrawn), on both phones, both sizes and both themes. flows/flow__album-failed.png is not a failed album (README); the matrix's album-failed capture is.

*Craft scope:* Record (populated/empty), album (populated/failed) and four receipt states, all eight variants, at 4112a3f0. flow__album-failed.png is not a failed album (brief) and was not used.

*Owner scope:* Record (populated, empty), album (populated, failed) and four receipt photo states, all passes. The photo states are genuinely distinct here (the web's were byte-identical): broken says "This round's photo couldn't be opened."; withdrawn offers Add a photo. The matrix's album-failed capture shows the failed state; flows/flow__album-failed.png does not (README).


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | The record's sentence, figures and leaf lead well. The receipt says its band twice (see C). |
| craft | H | 8 | defect | On SE3 the record's seasons table truncates every competition name to 'Placeholder...' / 'Fixture Cup L...' while the season qualifier stays, so the rows cannot be told apart (se3/record-light-large.png) |
| owner | H | 8 | defect | The receipt puts photo controls, View course and Share before the league verdict lens, which starts at the foot ("THE RECEIPT · WHAT THIS ROUND WAS WORTH", flows/flow__book-round-receipt.png). |
| category | T | 8 | defect | At AX3 the figure label 'SEASONS' breaks as 'SEASON/S' (17pro/record-dark-AX3.png). |
| craft | T | 8 | defect | At AX3 the record's figure labels break mid-word, 'SEASON / S' (17pro/record-light-AX3.png) |
| category | Sp | 7 | defect | The record leaf truncates competition names ('Placeholder Squ…', 'Fixture Cup Leag…') (17pro/record-dark-large.png, se3/record-light-large.png). The receipt's marker badge sits over the eyebrow's date (17pro/receipt-photo-dark-large.png). |
| craft | Sp | 7 | defect | The receipt photo card's marker stamp sits on its dateline, covering 'SEP 26' (17pro/receipt-photo-dark-large.png) and '(FIXTURE)' at AX3 (17pro/receipt-photo-light-AX3.png) |
| owner | Sp | 8 | defect | REPLACE PHOTO / REMOVE PHOTO sit directly under the card, before the round's facts (17pro/receipt-photo-dark-large.png). |
| category | C | 5 | defect | P1: the record prints two LIVE seasons (week 6 of 13 and week 4 of 10) under FINISH as '2ND', with the podium rule (17pro/record-dark-large.png, se3/record-light-large.png). The receipt's line stutters, 'Played to your playing HCP — played to it.' (17pro/receipt-photo-dark-large.png), where the web receipt states the comparison alone (L-34). |
| craft | C | 7 | device-or-human | album-failed on SE3 at default size renders the populated album (identical to album in light; the brief notes the synthetic failure world rendered photos, LEDGER X35), so the failed state is only partly evidenced (se3/album-failed-light-large.png) |
| owner | C | 7 | decision | Every receipt card signs "ANY TIME. ANYWHERE."; "SHARE ROUND" vs the web's "Share the card" (L-34) (17pro/receipt-nophoto-light-large.png). |
| category | B | 8 | content | The receipt panel with its pennant, the cream leaf and the record figures are ours. |
| category | P | 7 | defect | The album is a plain grid with a blank sixth tile (17pro/album-dark-large.png). |
| craft | P | 8 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| owner | P | 8 | defect | The photo receipt's marker medallion covers the date in the card's eyebrow (17pro/receipt-photo-dark-large.png). |
| category | R | 7 | defect | Truncated competition names. |
| craft | R | 6 | defect | The receipt photo card's dateline is scrim-ink #E1E4E0 on the grey plate #858786 = 2.82:1 (17pro/receipt-photo-dark-large.png) - the scrim covers only the bottom of the plate |
| owner | R | 7 | defect | THE RECORD's SEASONS table lists two live seasons under FINISH as "2ND", and truncates their names ("Placeholder Squ…", "Fixture Cup Leag…") (17pro/record-dark-large.png) — the web's P2, on the phone too. |
| category | E | 7 | content | '23 rounds since May. The best of them a 79, at Sample Links (fixture).' and the receipts pull. |
| craft | E | 6 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| owner | E | 8 | content | The verdict sentences are memory ("Beat your playing HCP by 3.4 — torched it.") and the receipt holds the conversation (D391); photographs are synthetic. |
| category | D | 8 | content | Right. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | defect | "23 rounds since May. The best of them a 79…" and then 23 / 4 / 79 as figures state the same facts twice (17pro/record-dark-large.png). |
| category | M | 7 | defect | The AX3 label break and the SE3 truncation. |
| craft | M | 6 | defect | SE3 table truncation, AX3 label break and the stamp collision (se3/record-light-large.png, 17pro/record-light-AX3.png, 17pro/receipt-photo-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | defect | AX3 wraps whole (se3/receipt-nophoto-dark-AX3.png); the SEASONS table truncates at the default size (as R). |

### `native/season`

Means: category 7.5 · craft 8.3 · owner 8.0.

*Category scope:* All eight season states and the three looks, on both phones, both sizes and both themes. The 'story' FAIL rows render correctly: the heading is set in caps ('THE STORY'), so the runner's case-sensitive text check missed it. season-ceremony has an unanswered read. Its payout rows ($240 + $80) exceed the $240 collected because the synthetic season_payouts are cut from the full pot (SyntheticWorld+Season.swift) while production pays from collected (D106). That is a fixture artifact and is not scored.

*Craft scope:* Season live solo/squads, Cup Final, loading, failed, ceremony, pot and story, plus the three looks on Home/Compete/Season/You, all eight variants, at 4112a3f0. The 8 story frames the runner FAILED render correctly: the runner searched for 'The story' and the heading is 'THE STORY' (hierarchy dump in export-17pro-large). The looks keep panel text >=4.79:1 (measured); cupfinal's ember is D359's named phase exemption.

*Owner scope:* Eight season states and the looks, all passes, plus failure → retry. Not scored as defects, because the synthetic world composes them: the ceremony's payouts ($240 + $80) exceed "what was collected — $240" because the fixture splits the full pot (SyntheticWorld+Season.swift:53–55) while D106's server pays from collected; and the story files the current headline under WEEK 2 because the fixture arc is oldest-first while season_story orders it newest-first (`order by (x->>'on') desc`). The story's runner FAIL is a root-text mismatch; the page renders.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | In the Cup Final the 'THE CUP FINAL' head prints twice in a row, once with 'TOP TWO' and once with '17 DAYS LEFT' (17pro/season-final-dark-large.png). |
| owner | H | 8 | defect | The minimum paragraph sits between the tick row and the clash, pushing the week's competition below the first screen (17pro/season-dark-large.png). |
| category | T | 8 | defect | Strong. The minimum paragraph is a long run of body text under the tick row. |
| craft | T | 8 | defect | The rule sentence under the month band is a three-line bodyS paragraph in mut ('September's minimum is met - 5.5 of 2. A nine counts half...') (17pro/season-dark-large.png) |
| category | Sp | 7 | defect | The Final's double head. At SE3 the pot truncates names ('Casey Placeh…', 'Maximilian Pl…', 'Emerson Mock…') (se3/pot-light-large.png). |
| craft | Sp | 8 | defect | The failed-read state is top-aligned with the rest of the screen empty (17pro/season-failed-dark-large.png) |
| owner | Sp | 8 | defect | The pot stacks the figure, a split row, a split line and a boxed table (17pro/pot-light-large.png). |
| category | C | 6 | defect | In the Final the band says 'Blake Sample has led for nine straight weeks.' over a Final table you lead 19–14 (17pro/season-final-dark-large.png). The story's WEEK 2 entry leads with 'Blake Sample has led for four straight weeks.' (17pro/story-dark-large.png). The minimum line says 'best 4' where the web says 'best four' (L-34). The teams look paints the rank chip and the clash leader's tile red (17pro/look-teams-home-dark-large.png, 17pro/look-teams-season-dark-large.png). |
| craft | C | 8 | defect | The pot's 'WHO IS IN' sits on a white leaf that re-forms a bordered panel in light (17pro/pot-light-large.png) |
| owner | C | 7 | defect | Two consecutive heads both read "THE CUP FINAL" (17pro/season-final-dark-large.png); the pot prints the split twice ("192 / 80 / 48" and "$192 CHAMPION · $80 RUNNER-UP · $48 POINTS KING") (17pro/pot-light-large.png). |
| category | P | 8 | defect | The ceremony and the pot are premium. The ceremony's 'SHARE SEASON RESULT' is a secondary dark button for the moment's one action (17pro/season-ceremony-dark-large.png). |
| owner | P | 8 | defect | The pot's paid/owes list is a boxed grid (17pro/pot-light-large.png). |
| category | R | 8 | defect | '5.5 of 2' reads oddly (17pro/season-dark-large.png). |
| owner | R | 7 | defect | The Cup Final race prints "+5" in GAP for the golfer five back and truncates "top seed…" (17pro/season-final-dark-large.png); the pot heads its paid/owes list "WHO IS IN · SIX OF EIGHT", which reads as two golfers not being in the season (17pro/pot-light-large.png); "5.5 of 2" (17pro/season-dark-large.png). |
| category | E | 7 | content | The ceremony is a real moment, but the season story is two entries (17pro/story-dark-large.png). |
| craft | E | 7 | content | The ceremony renders only on a fixture (no season has completed), and statically (17pro/season-ceremony-dark-large.png) |
| owner | E | 8 | content | The ceremony (champion, margin, runner-up, Points King, what you're owed) and the band carry the season; the story has two items across six played weeks (17pro/story-dark-large.png). |
| category | D | 7 | defect | The minimum paragraph is dense on every season screen. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | content | Balanced; the season's own photographs would say more than the tick row. |
| category | M | 7 | defect | The SE3 truncations noted under Sp; AX3 reflows correctly (17pro/season-dark-AX3.png). |
| craft | M | 8 | device-or-human | Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | defect | AX3 wraps whole (se3/season-light-AX3.png); "top seed…" truncates at the default size. |

### `native/competition`

Means: category 6.3 · craft 7.4 · owner 7.7.

*Category scope:* All eight competition states on both phones, both sizes and both themes, plus the Book flows (17 Pro, large, dark). whenfork has an unanswered read but renders completely. The Race and Totals views of the Book are not captured.

*Craft scope:* Compete (scoreboard/empty/Cup Final), the Book (populated/squads/failed), the intent and when-fork sheets, all eight variants, plus the three Book receipt flows, at 4112a3f0. The 8 whenfork rows flagged 'unanswered requests' render complete.

*Owner scope:* Scoreboard, empty, Cup Final, intent sheet, when-fork, the Book (solo, squads, failed) and the Book receipt flows. §16 at its best: every cell opens its rounds, a dropped round says why ("Outside the best 4 for this calendar month; the round stays in the record"), and the Pro's correction carries its reason ("Posted from the wrong tee on Aug 29; corrected by the Pro").


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | The Scoreboard leads Compete (D381). But during a Cup Final it still leads with another league's regular week while the Final is a list row, 'Cup Final · 3 weeks left' (17pro/compete-final-dark-large.png). |
| craft | H | 8 | defect | Compete empty offers two eyebrow-sized text doors (START SOMETHING in act, I HAVE A CODE in mut) and no button, over a mostly empty screen (17pro/compete-empty-dark-large.png; CompeteScreen.swift:376 csEyebrow) |
| owner | H | 8 | defect | In the Cup Final scenario Compete still leads with the other league's regular-season band (WEEK 4 OF 10) and demotes the Cup Final to a row (17pro/compete-final-dark-large.png). |
| category | T | 7 | defect | At AX3 the Scoreboard breaks the league name mid-word, 'PLACEHOLDE/R SQUADS LEAGUE' (17pro/compete-dark-AX3.png). |
| craft | T | 7 | defect | The Book prints raw ISO dates, 'Season 2 · 2026-08-21 - 2026-11-19' (SeasonBookPage.swift:86) (17pro/book-dark-large.png, 17pro/book-squads-light-large.png), and an adjustment reads 'Applies to 2026-09' (flows/flow__book-adjustment.png) |
| owner | T | 8 | defect | The Book grid's totals ("87 pts") are 11pt mono under condensed team names (17pro/book-squads-light-large.png). |
| category | Sp | 6 | defect | Compete empty is a headline, one sentence and two 11px mono text links over a 65% void (17pro/compete-empty-dark-large.png). The solo Book places each figure right after its name, so the figures sit at different x positions, with 'POINTS' repeated under every one (17pro/book-dark-large.png). |
| craft | Sp | 7 | defect | At AX3 the scoreboard band breaks the league name mid-word, 'PLACEHOLDE / R SQUADS' (se3/compete-dark-AX3.png, 17pro/compete-light-AX3.png) |
| owner | Sp | 8 | defect | Empty Compete is a title, a sentence and two quiet mono links over mostly blank ground (17pro/compete-empty-light-large.png). |
| category | C | 5 | defect | ISO dates in golfer copy: 'Season 2 · 2026-08-21 – 2026-11-19' (17pro/book-dark-large.png, 17pro/book-squads-dark-large.png) and 'Applies to 2026-09' (flows/flow__book-adjustment.png), where the web Book now prints human dates (L-34). 'RIGHT NOW' in the when-fork is ember, but it is an ordinary action (17pro/whenfork-dark-large.png). Compete's title carries the tagline 'ANY TIME. ANYWHERE.' (17pro/compete-dark-large.png). Compete empty offers two doors where the web offers three (L-34). |
| craft | C | 7 | defect | L-34: the Book's season line differs from the web's formatted dates (17pro/book-dark-large.png) |
| owner | C | 7 | defect | The Book head prints ISO dates ("Season 2 · 2026-08-21 – 2026-11-19") where the web at 9d84c483 prints human dates (L-34) (17pro/book-dark-large.png); the Cup Final row prints "CUP FINAL · Cup Final · 3 weeks left" (17pro/compete-final-dark-large.png); the when-fork pre-tints its first option "RIGHT NOW" in ember (§16A.6, D359) (17pro/whenfork-light-large.png). |
| category | B | 8 | defect | The ember Scoreboard with contours and the Book's head are ours. The Book body is a table. |
| owner | B | 8 | content | The Scoreboard band is proprietary; the Book is a data grid. |
| category | P | 6 | defect | The solo Book reads unfinished (misaligned figures) and the empty state is a void. |
| craft | P | 8 | defect | The intent sheet on SE3 clips its last row ('I have a code' is below the sheet edge with no fade) (se3/intent-dark-large.png) |
| owner | P | 8 | defect | The Book reads as a tool: two segmented controls and a key line before the grid (17pro/book-squads-light-large.png). |
| category | R | 6 | defect | The solo Book cannot be scanned as a leaderboard (BRIEF §15) (17pro/book-dark-large.png). |
| craft | R | 7 | defect | ISO dates and the AX3 mid-word break (17pro/book-dark-large.png, se3/compete-dark-AX3.png) |
| owner | R | 7 | defect | "83 POINTS · 2nd POINTS STANDING · You are 4 back from Team Placeholder" never says the 83 is Team Stub's (17pro/compete-dark-large.png) — the same producer gap as the web. |
| category | E | 6 | defect | 'You are 4 back from Team Placeholder.' pulls. The Book has no moment in it. |
| craft | E | 7 | content | Synthetic leagues; the band carries the stakes |
| owner | E | 8 | content | Empty Compete is blank (17pro/compete-empty-light-large.png); the intent sheet ("What do you want to do?") is warm. |
| category | D | 6 | defect | The empty state is starved, and the solo Book repeats 'POINTS' four times. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | defect | Right; the adjustment reads its date as "Applies to 2026-09" (flows/flow__book-adjustment.png). |
| category | M | 6 | defect | The AX3 mid-word break. At SE3 the squads table scrolls its W4 column off the edge (se3/book-squads-dark-large.png). |
| craft | M | 6 | defect | AX3 mid-word break and the clipped intent row (se3/compete-dark-AX3.png, se3/intent-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | At AX3 on the SE3 the Scoreboard breaks the league name mid-word ("PLACEHOLDE / R SQUADS LEAGUE") (se3/compete-light-AX3.png). |

### `native/events`

Means: category 7.2 · craft 7.9 · owner 8.2.

*Category scope:* Ryder live and complete, the Major, the picker, the missing-event and failed-read states, on both phones, both sizes and both themes. A callout room is not captured.

*Craft scope:* Ryder live/complete, Major live, failed, not-open and the picker, all eight variants, at 4112a3f0. The native title card keeps dark pigments in the light printing, so its glyphs stay legible (the web's does not).

*Owner scope:* Ryder live and complete, a live Major, the picker, not-open and failed rooms, all passes. The picker names things as §4.36 rules ("The Ryder", "A Major"); failure and not-open states each have a way back.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | Title, the two labelled sides, the score and the clinch line all fit the first screen, even on SE3, which is better than the web (se3/event-live-light-large.png). On the Major, the Casey row has no position and its reason is clipped ('doesn't c…') (17pro/event-major-dark-large.png). |
| owner | H | 8 | defect | At the default size the Ryder's score (4½–3½) sits under the rosters, past the middle of the first screen (17pro/event-live-dark-large.png). |
| category | T | 8 | defect | Well set. Clash names are clipped ('BLAKE SA…', 'HARPER FA…') (17pro/event-complete-dark-large.png). |
| craft | T | 8 | defect | Clash and leaderboard sub-lines are 11pt mono caps ('79 gross · 2 cards') (17pro/event-major-dark-large.png) |
| owner | T | 8 | defect | Roster names are 10–11pt mono under the markers (17pro/event-live-dark-large.png). |
| category | Sp | 7 | defect | The clipped clash names and the clipped Major reason. |
| craft | Sp | 7 | defect | At AX3 the rosters row does not wrap: the second side's label and discs are clipped at the right edge ('TE', 'EM') (17pro/event-live-dark-AX3.png, se3/event-complete-dark-AX3.png) - §16.3 says the field rail wraps to two groups |
| owner | Sp | 8 | defect | Two rosters take the first half of the screen (17pro/event-live-dark-large.png). |
| category | C | 6 | defect | '1 DAYS LEFT' (17pro/event-major-dark-large.png). 'The 2nd Ryder · Team Placeholder hold the Ryder 1–0 · Team Placeholder hold it' says the holder twice; this is a producer shared with the web (17pro/event-live-dark-large.png). |
| craft | C | 8 | defect | Roster names truncate on SE3 AX3 ('BLA... AVE... CAS...') (se3/event-major-dark-AX3.png) |
| owner | C | 8 | defect | "Team Placeholder hold the Ryder 1–0 · Team Placeholder hold it" repeats (17pro/event-live-dark-large.png) — as on the web. |
| category | B | 8 | content | A tournament graphic: squads, discs, the ember live eyebrow, the score rail. |
| category | P | 7 | defect | The hero is premium. The clash rows are plain text rows. |
| craft | P | 8 | defect | Premium title card; the week list below is a plain list (17pro/event-complete-dark-large.png) |
| owner | P | 8 | content | The picker is plain text rows (17pro/event-picker-light-large.png). |
| category | R | 7 | defect | Clipped names mean you cannot read who played whom. |
| craft | R | 8 | defect | At AX3 the second side is clipped (17pro/event-live-dark-AX3.png) and SE3 AX3 roster names truncate to 'BLA... AVE... CAS...' (se3/event-major-dark-AX3.png) |
| owner | R | 8 | defect | The Major reads "1 DAYS LEFT" and clips a reason ("88 gross · 1 card · doesn't c…") (17pro/event-major-dark-large.png). |
| category | E | 7 | device-or-human | 'First to 8½. Team Placeholder need 4, Team Stub need 5.' pulls. The score changing is not evidenced in stills. |
| craft | E | 7 | content | A synthetic Ryder and Major with fixture names and no photograph of the event's course (17pro/event-live-dark-large.png) |
| category | D | 7 | content | Right. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | defect | The Major's leaderboard heads a figure column "LIVE NET" without saying what it is measured against (§16A.3) (17pro/event-major-dark-large.png). |
| category | M | 7 | decision | At AX3 the side roster scrolls sideways by design (CSSideRoster, §7.5), so the second side is cut at the screen edge (17pro/event-live-dark-AX3.png). UI_SYSTEM §16.3 asks for the groups to stack. |
| craft | M | 7 | defect | AX3 clipping. Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | defect | AX3 wraps whole (se3/event-live-dark-AX3.png); the Major's reason clips (as R). |

### `native/schedule`

Means: category 6.2 · craft 7.2 · owner 7.7.

*Category scope:* Schedule (populated, empty), the plan sheet and the declare sheet, on both phones, both sizes and both themes. RSVP writes and editing a plan are not driven.

*Craft scope:* Schedule (populated/empty), the declare sheet and the plan sheet, all eight variants, at 4112a3f0.

*Owner scope:* Schedule (populated, empty), a planned round and the declare sheet, all passes. Unlike the web, the page has a title and the plan sheet carries weather, the D364 worth line and the course's history.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 6 | defect | The schedule opens on 'IN YOUR CREW'S PLANS' rows and a calendar at one weight. Your own next round is not a hero (17pro/schedule-dark-large.png). The plan sheet is strong (17pro/plan-dark-large.png). |
| craft | H | 7 | defect | Two eyebrows stack at the head ('YOURS, YOUR BUDDIES', YOUR SEASONS'' over 'IN YOUR CREW'S PLANS') before the first plan (17pro/schedule-dark-large.png) - same as the web |
| owner | H | 8 | defect | The subtitle "YOURS, YOUR BUDDIES', YOUR SEASONS'" is a possessive pile-up over the plans (17pro/schedule-dark-large.png). |
| category | T | 6 | defect | Each crew row is five or six lines of mono caps metadata ('WED OCT 7 · SAMPLE LINKS (FIXTURE) · 3:40p · YOU'RE IN'). |
| craft | T | 7 | defect | At AX3 the plan's name breaks mid-word ('TESTCAS / E') and the declare sheet's label breaks 'OPTIONA / L' (17pro/schedule-dark-AX3.png, 17pro/declare-dark-AX3.png) |
| owner | T | 8 | defect | Plan rows set the course, time and status in 11pt mono caps (17pro/schedule-dark-large.png). |
| category | Sp | 7 | defect | At SE3 the rows run five or six lines each (se3/schedule-dark-large.png). |
| craft | Sp | 7 | defect | At AX3 the declare sheet's 'SET A TEE TIME' link is clipped at the right edge (17pro/declare-dark-AX3.png, 17pro/declare-light-AX3.png) |
| owner | Sp | 8 | defect | "ON THE SCHEDULE" takes a right-hand column on every row and squeezes the names (17pro/schedule-dark-large.png). |
| category | C | 6 | defect | 'ON THE SCHEDULE' repeats on every row under a section that already says so. The plan sheet prints '78°' twice (the figure and the weather line) (17pro/plan-dark-large.png). The declare sheet's day is the system date pill (17pro/declare-dark-large.png). |
| craft | C | 7 | defect | Plan rows' right slot is a state phrase ('ON THE SCHEDULE') in the same place other rows put an action (17pro/schedule-dark-large.png) |
| owner | C | 7 | defect | The calendar legend says "IN YOUR SEASONS" where A-7 names the crew (17pro/schedule-empty-light-large.png); every row repeats "ON THE SCHEDULE" on the schedule. |
| category | B | 6 | defect | The calendar and list are utilities. The plan sheet (caps title, figures, weather, the course block) is ours. |
| craft | B | 8 | defect | The plan sheet's figures-on-a-rule and course leaf are proprietary; the list is plain (17pro/schedule-dark-large.png) |
| owner | B | 8 | content | A calendar and rows; the plan sheet is where the character is. |
| category | P | 6 | defect | The list reads like a list app; the plan sheet is premium. |
| craft | P | 8 | defect | The plan sheet is premium; the crew list is caps meta (17pro/schedule-dark-large.png) |
| owner | P | 8 | defect | The declare sheet's example values ("Pebble Beach", "buddies trip, looking for a 4th") read like entries (17pro/declare-light-large.png). |
| category | R | 6 | defect | Walls of caps mono. |
| craft | R | 7 | defect | At AX3 names break mid-word ('TESTCAS / E') and the tee-time label breaks 'OPTIONA / L' (17pro/schedule-dark-AX3.png, 17pro/declare-dark-AX3.png) |
| owner | R | 8 | defect | As P: example text reads as chosen values. |
| category | E | 6 | defect | The plan sheet's '“Walking if the weather holds.”' and the weather pull; the list is flat. |
| craft | E | 7 | defect | The plan sheet's 5 DAYS OUT / 7:10a / 78° lands; the schedule list does not |
| owner | E | 8 | content | Weather, the worth line, the note and "You have played here 13 times · best 81" make a plan feel like a round (17pro/plan-dark-large.png). |
| category | D | 6 | defect | Crew rows are crammed, and the calendar and the list state the same plans. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 7 | defect | The plan sheet repeats facts: "72 / 130" in the dateline and the course block; "78° HIGH" and "78° Mostly sunny" (17pro/plan-dark-large.png). |
| category | M | 7 | device-or-human | Fits at both widths; day targets were raised to 44pt (F15). |
| craft | M | 6 | defect | AX3 clipping and breaks (17pro/declare-dark-AX3.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | At AX3 on the SE3 a plan row breaks a name mid-word ("DEVON / TESTCA / SE") beside the status column (se3/schedule-dark-AX3.png). |

### `native/wizard`

Means: category 6.5 · craft 7.2 · owner 7.6.

*Category scope:* Only the wizard's first step ('Who's playing?') is captured, on both phones, both sizes and both themes. The later steps are not captured (NATIVE-BRIEF), so the review and lock are not evidenced on the phone.

*Craft scope:* Step 1 (who's playing) only, all eight variants, at 4112a3f0. Steps 2-3 and the lock are NOT captured (brief); the row is scored on step 1 alone and says so in H/D.

*Owner scope:* First step only (all passes). The later steps are not captured (NATIVE-BRIEF), so the web's P1/P2 wizard findings (hidden desk review, preset/dial contradiction) cannot be checked on the phone.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | device-or-human | 'WHO'S PLAYING?' with one act NEXT is clear (17pro/wizard-dark-large.png). The later steps are not captured. |
| craft | H | 8 | device-or-human | Step 1 reads cleanly: head, step dashes, buddies, the text-a-link door, count, NEXT (17pro/wizard-dark-large.png); only step 1 exists |
| owner | H | 8 | defect | The progress dots under the title are unlabelled (17pro/wizard-dark-large.png); the web names the step (MW-06). |
| category | T | 7 | defect | Caps title and chips. The count row ('HOW MANY OF YOU?') is small mono. |
| craft | T | 8 | defect | Count chips (2...12+) are small tiles at agate size (17pro/wizard-dark-large.png) |
| owner | T | 8 | defect | The count choices (2 3 4 5 6 8 10 12+) are small mono squares (17pro/wizard-dark-large.png). |
| category | Sp | 6 | defect | The count chips are tight and small. A long buddy name's chip ('MAXIMILIAN PLACEHOLDER-WORTHINGTON') runs off the right edge at SE3 and at AX3 (se3/wizard-dark-large.png, 17pro/wizard-light-AX3.png, se3/wizard-light-AX3.png). |
| craft | Sp | 7 | defect | The long buddy chip 'MAXIMILIAN PLACEHOLDER-WORTHINGTON' runs to the right edge with no margin on SE3 and is clipped at AX3 ('MAXIMILIAN PLACEHO') (se3/wizard-dark-large.png, 17pro/wizard-light-AX3.png) |
| owner | Sp | 8 | defect | Buddy chips stack one per line even when short (17pro/wizard-dark-large.png). |
| category | C | 7 | defect | No count chip is selected while the copy says 'Counting you.' |
| craft | C | 8 | defect | Two chip sizes on one step: wide name chips for buddies and small square count tiles (2...12+) (17pro/wizard-dark-large.png) |
| owner | C | 8 | defect | The phone's step rail is unnamed where the web's is named (L-34). |
| category | B | 6 | defect | A generic setup step. No object shows what season is being made. |
| craft | B | 7 | defect | No proprietary object on step 1 (17pro/wizard-light-large.png) |
| owner | B | 7 | content | A form; no object. |
| category | P | 6 | defect | Form chips. |
| craft | P | 7 | defect | Step 1 is a tidy stack of bg2 chips with no drawn object (17pro/wizard-light-large.png) |
| owner | P | 7 | defect | Chips and squares, form-first. |
| category | R | 7 | defect | Readable. |
| craft | R | 7 | defect | AX3 clipping of the long name (17pro/wizard-light-AX3.png) |
| owner | R | 8 | decision | The count omits 7 and 9 without saying why (17pro/wizard-dark-large.png). |
| category | E | 6 | defect | 'Two is a season. Four opens squads.' is a good line; the step is otherwise settings. |
| craft | E | 6 | defect | Starting a season has no moment on step 1 (17pro/wizard-dark-large.png) |
| owner | E | 8 | content | People first is right ("Two is a season. Four opens squads."). |
| category | D | 7 | content | Right for a first step. |
| craft | D | 8 | device-or-human | Density is right for step 1; steps 2-3 and the lock are not captured (brief) |
| owner | D | 8 | device-or-human | Rules, money, review and lock (steps 2–3) are not captured on the phone, so the rules a Pro agrees to are unproven here. |
| category | M | 6 | defect | The 'HOW MANY OF YOU?' chips measure about 30x28pt, below §16.2's 44pt (17pro/wizard-dark-large.png, se3/wizard-dark-large.png). The long-name chip is cut at the screen edge at SE3 and AX3. |
| craft | M | 6 | defect | AX3 clipping. Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 6 | defect | Buddy chips run off the right edge at SE3 default size ("MAXIMILIAN PLACEHOLDER-WORTHINGTON") and at AX3 on both phones ("CASEY PLACEHOLDEF", "MAXIMILIAN PLACEH…") (se3/wizard-dark-large.png, 17pro/wizard-light-AX3.png, se3/wizard-light-AX3.png). |

### `native/courses`

Means: category 7.8 · craft 7.6 · owner 7.8.

*Category scope:* The courses list, the course page, the whole card, the course card and the never-kept card, on both phones, both sizes and both themes. course-wholecard has an unanswered read but renders completely. The never-kept card's title, 'A course you have not played', is the dev hatch's label, and identical quotes on different courses are fixture reuse; neither is scored. Rating a course is not driven.

*Craft scope:* Course home, whole card, course card (kept/never) and the course list, all eight variants, at 4112a3f0. The 8 course-wholecard rows flagged 'unanswered requests' render complete.

*Owner scope:* Course home, course page, kept and never-kept cards and the whole card, all passes. The whole card says "AVAILABLE OFFLINE · SAVED TODAY" and "The longest rated 18 — change tees for yours." (D364).


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | The course page leads with a photograph band, the name and the rating figure (17pro/course-dark-large.png). On the course card the drawn yardage bars take the top of the screen above the name (17pro/coursecard-dark-large.png). |
| craft | H | 8 | content | The course page opens on the grey fixture plate with the round credit and the schedule eyebrow over it (17pro/course-dark-large.png) |
| owner | H | 8 | defect | The course page leads with a round photograph and the name; the circle's best (D391) is not on the first screen (17pro/course-light-large.png). |
| category | T | 8 | defect | Strong. Long club names set in caps grow tall at AX3 (se3/coursecard-dark-AX3.png). |
| craft | T | 8 | defect | Eyebrow over the plate is a two-line caps sentence ('ON YOUR SCHEDULE · SAT OCT 3 · FOUR OF YOURS HAVE PLAYED IT') (17pro/course-dark-large.png) |
| owner | T | 8 | defect | The whole card's facts line ("72 PAR · 6,640 YDS · 72 RTG · 130 SLOPE") is small inline mono (17pro/course-wholecard-dark-large.png). |
| category | Sp | 8 | decision | 'AVAILABLE OFFLINE · SAVED TODAY' sits under every card's title (17pro/course-wholecard-dark-large.png). |
| craft | Sp | 8 | defect | Right; the light printing starts the plate below a cream strip (17pro/course-light-large.png) |
| owner | Sp | 8 | defect | List rows pack faces, a count line and a chevron tightly (17pro/courses-dark-large.png). |
| category | C | 7 | defect | The course list shows four faces over '1 friend has played here' (friends_total counts buddies only), while the course page says 'FOUR OF YOURS HAVE PLAYED IT' (17pro/courses-dark-large.png vs 17pro/course-dark-large.png). |
| craft | C | 8 | defect | Two counts for one fact on adjacent screens: the course list says '1 friend has played here' (17pro/courses-dark-large.png; CourseHomeScreen.swift:172, friends_total) and the course page says 'FOUR OF YOURS HAVE PLAYED IT' (17pro/course-dark-large.png; CourseScreen.swift:549-560, the circle's others) - two populations, two words (may also reflect fixture incoherence) |
| owner | C | 7 | defect | A course card header draws a yardage bar graphic with no key (17pro/coursecard-dark-large.png) — the encoding D364 removed from plans for that reason; the list says "1 friend has played here" beside four faces (17pro/courses-dark-large.png). |
| category | B | 8 | content | The photograph band, the drawn yardage bars and the leaves are ours. |
| owner | B | 8 | content | A round photograph as the course image is right; most courses have none. |
| category | P | 8 | content | The one photograph is a golfer's round photo, which is right, but this world has no course imagery. |
| craft | P | 8 | content | The synthetic world has no real photograph: every photo slot renders the grey fixture plate and faces are marker glyphs (17pro/receipt-photo-dark-large.png, 17pro/course-dark-large.png) |
| owner | P | 8 | content | Plain list rows. |
| category | R | 8 | content | Readable. |
| craft | R | 6 | defect | The schedule eyebrow over the photo plate is scrim-mut #CBD2C8 on the plate's #949494 = 1.96:1 (17pro/course-dark-large.png) |
| owner | R | 7 | defect | As C (the friend count vs the faces); "best 81" on the plan has no path to its round (17pro/plan-dark-large.png). |
| category | E | 7 | content | The quotes and the buddies' rating pull. |
| craft | E | 6 | content | No photograph of a course (17pro/coursecard-dark-large.png) |
| owner | E | 8 | content | Buddies' notes ("The best par fives in Fixtureville.") are warm. |
| category | D | 8 | content | Right. |
| craft | D | 8 | device-or-human | Right; Captures are first-screen frames only; nothing below the fold of any scrolling page is evidenced |
| owner | D | 8 | content | Right; "No rounds from your circle here yet." on a course you have not played is honest (17pro/coursecard-never-light-large.png). |
| category | M | 8 | device-or-human | The leaves fit at both widths and AX3 grows the page. |
| craft | M | 7 | defect | The eyebrow contrast (17pro/course-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | defect | AX3 wraps whole (se3/course-light-AX3.png). |

### `native/settings`

Means: category 6.9 · craft 7.6 · owner 7.8.

*Category scope:* Card & settings, the 'Your card' tab only, on both phones, both sizes and both themes. The Settings tab, notifications and account deletion are not captured.

*Craft scope:* Card & settings, the Your card tab only, all eight variants, at 4112a3f0. The Settings tab (notifications, appearance, delete) is not captured.

*Owner scope:* Card & settings, Your card tab only, all passes.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | defect | Tabs, fields and the marker grid at even weight. The Save/Done action is not on the first screen (17pro/settings-dark-large.png). |
| craft | H | 8 | device-or-human | Only the Your card tab is captured (17pro/settings-dark-large.png) |
| owner | H | 8 | defect | "WHAT YOUR BUDDIES SEE" leads the Your card tab, but the card itself is not previewed (17pro/settings-light-large.png). |
| category | T | 7 | defect | Mono caps labels over sans fields; plain. |
| craft | T | 8 | defect | Two title voices on one sheet: the sans nav title 'Card & settings' and the caps head 'WHAT YOUR BUDDIES SEE' (17pro/settings-dark-large.png) |
| owner | T | 8 | defect | Field labels are 11pt tracked caps (17pro/settings-light-large.png). |
| category | Sp | 8 | defect | Tidy. The home-course field truncates 'North Grove (fixtu…'. |
| craft | Sp | 8 | device-or-human | Only the Your card tab is captured; the Settings tab's rows, switches and delete confirm are not evidenced (17pro/settings-dark-large.png) |
| owner | Sp | 8 | defect | Even stacking; nothing separates identity from app settings but the tab. |
| category | C | 7 | defect | The marker grid has one clear selection (an inverse tile), which is better than the web. The field truncation noted under Sp. |
| craft | C | 8 | device-or-human | Consistent within the card tab; parity with the web's text-button toggles cannot be judged because the Settings tab is not captured |
| owner | C | 8 | defect | The marker is defined in a second wording here ("Your icon on the board and in the standings — add a photo and it rides in the corner of your card.") beside the card gate's canon sentence (TERMINOLOGY #10) (17pro/settings-light-large.png vs 17pro/cardgate-dark-large.png). |
| category | B | 6 | decision | Settings. The marker grid is the only proprietary element. |
| craft | B | 8 | decision | The marker grid is proprietary; the rest is a form |
| owner | B | 8 | content | The marker grid is the brand's; the rest is a form. |
| category | P | 6 | decision | Boxed fields. |
| craft | P | 7 | defect | A form in a sheet (17pro/settings-light-large.png) |
| owner | P | 8 | content | Clean. |
| category | R | 8 | content | Readable. |
| craft | R | 8 | defect | At AX3 'North Grove (fixt...' truncates in its field (17pro/settings-dark-AX3.png) |
| owner | R | 8 | device-or-human | The Settings tab (notifications, findable, sign out, delete) is not captured on the phone. |
| category | E | 5 | decision | Low by nature; the marker picker is the fun part. |
| craft | E | 6 | decision | Utility surface: nothing to feel beyond the marker grid (17pro/settings-dark-large.png) |
| owner | E | 7 | content | A settings surface. |
| category | D | 7 | content | Right. |
| craft | D | 8 | device-or-human | Only one of two tabs is captured (17pro/settings-dark-large.png) |
| owner | D | 8 | content | Right. |
| category | M | 8 | device-or-human | Fits, with 44pt targets. The Settings tab (notifications, appearance, sign out) is not captured. |
| craft | M | 7 | device-or-human | The destructive and notification controls are not captured. Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | The home course field truncates ("North Grove (fixtu…") at the default size and at AX3 (17pro/settings-light-large.png, se3/settings-dark-AX3.png). |

### `native/play`

Means: category 6.7 · craft 7.5 · owner 7.5.

*Category scope:* Live setup on both phones, both sizes and both themes, plus the finish-sheet flow (17 Pro, large, dark). The live scoring rows are not captured in the matrix (NATIVE-BRIEF). The recap flow is from 72e76e3a and is cited only as context, not scored.

*Craft scope:* Live setup (all eight variants) and the live-finish sheet flow at 4112a3f0. Live scoring states are NOT captured in the matrix; flow__live-recap--at-72e76e3a.png is from an earlier SHA and caught mid-transition, so it was not scored. Noted, not scored (no capture): LiveRoundHost is presented as a fullScreenCover with no toast host of its own under CupSeason/Live, the same structure that hides the composer's failure toast (native/post P1) - verify live-scoring toasts on a device.

*Owner scope:* Setup (all passes) and the finish sheet flow. The scoring rows are not captured (NATIVE-BRIEF); the recap flow is from 72e76e3a and not attributed to 4112a3f0.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 7 | device-or-human | Setup is a clear form ending in one act TEE OFF (17pro/live-setup-dark-large.png). The finish sheet says exactly what happens ('Every complete card posts to its golfer, vouched by the group…') (flows/flow__live-finish-sheet.png). The scoring screen itself is not captured. |
| craft | H | 8 | device-or-human | Setup reads in order and TEE OFF is the one primary; only setup is captured (17pro/live-setup-dark-large.png) |
| owner | H | 8 | defect | Setup leads with "Score on this phone" (a toggle) above the course (17pro/live-setup-light-large.png). |
| category | T | 7 | defect | Fine. The tee/rating/slope labels are small mono. |
| craft | T | 8 | defect | Section heads are mono caps ('TEE & RATING — OFF THE SCORECARD') (17pro/live-setup-dark-large.png) |
| owner | T | 8 | defect | Tee, rating and slope labels are small caps. |
| category | Sp | 7 | defect | Setup is a run of boxed fields. |
| craft | Sp | 8 | defect | On SE3 at default size the pinned TEE OFF footer puts THE GROUP (who is playing) below the fold of the first screen (se3/live-setup-dark-large.png) |
| owner | Sp | 8 | defect | The finish sheet sits over half-visible scoring rows (flows/flow__live-finish-sheet.png). |
| category | C | 7 | defect | It is not clear what the 'Score on this phone' toggle (off by default) changes (17pro/live-setup-dark-large.png). |
| craft | C | 8 | defect | The 18/9 HOLES control is an underline tab while the schedule's game picker is filled chips (17pro/live-setup-dark-large.png vs 17pro/declare-dark-AX3.png) |
| owner | C | 7 | defect | Setup labels the golfer's index "12.4 PLAYING HCP" where the web's setup prints "14.2 NUMBER" (L-34) (17pro/live-setup-light-large.png vs play--setup-filled--375--dark.png). |
| category | B | 6 | defect | The setup form is generic. The finish sheet's match line ('MATCH PLAY · NET BEST BALL · ALL SQUARE · THRU 14') is ours. |
| craft | B | 7 | defect | Setup carries no drawn object (17pro/live-setup-light-large.png) |
| owner | B | 7 | content | Functional live chrome. |
| category | P | 6 | defect | A settings-like setup. |
| craft | P | 7 | defect | Setup is a stack of form fields with no drawn object (17pro/live-setup-light-large.png) |
| owner | P | 8 | defect | The finish sheet is crafted; setup is a form. |
| category | R | 7 | device-or-human | Readable. Outdoor legibility is device evidence. |
| craft | R | 8 | defect | The par-72 explanation is a two-line bodyS paragraph in mut between the hole toggle and 'Enter the pars' (17pro/live-setup-dark-large.png) |
| owner | R | 7 | defect | "Score on this phone" has no explanation at first contact (17pro/live-setup-light-large.png); finish-sheet rows truncate ("62 THRU…") (flows/flow__live-finish-sheet.png). |
| category | E | 6 | device-or-human | The live moment is not in the matrix. The recap takeover exists only at an earlier SHA (flows/flow__live-recap--at-72e76e3a.png, where the text is clipped at the left edge), so it is not scored. |
| craft | E | 6 | device-or-human | Scoring, the moment itself, is not captured; the live-finish sheet is (flows/flow__live-finish-sheet.png) |
| owner | E | 7 | device-or-human | The finish sheet states consequences well; the recap is evidenced only at an earlier SHA (flows/flow__live-recap--at-72e76e3a.png). |
| category | D | 7 | content | Right. |
| craft | D | 8 | device-or-human | Setup density is right; scoring density is not captured |
| owner | D | 8 | content | Right. |
| category | M | 7 | device-or-human | The steppers behind the finish sheet are about 44pt. The setup fits SE3 at AX3 (se3/live-setup-dark-AX3.png). |
| craft | M | 7 | device-or-human | Live scoring - the on-course touch surface - is not in the matrix; the finish flow shows steppers only behind a sheet (flows/flow__live-finish-sheet.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | device-or-human | Live scoring (holes, steppers, sync, match, skins) is not captured in the matrix. |

### `native/rules`

Means: category 7.3 · craft 7.8 · owner 7.8.

*Category scope:* Rules on both phones, both sizes and both themes. The two 17 Pro large-text captures are mid-push frames: the season page is still sliding out and the rules text is cut at the right edge (17pro/rules-dark-large.png, 17pro/rules-light-large.png). That is a capture-timing artifact of a route with an unanswered read. Every AX3 and SE3 capture renders cleanly, so no defect is counted.

*Craft scope:* The rules page, all eight variants, at 4112a3f0. The 8 rows flagged 'unanswered requests' render the page; the two 17 Pro large frames are mid-transition, so SE3 and AX3 frames carry the score.

*Owner scope:* The rules page, all passes (flagged for unanswered requests; all eight render). The sentences match the web's rules producers.


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | content | Rules come first: a serif title, the span, then question heads with answers (se3/rules-light-large.png). This is better than the web, which opens on admin cards. |
| craft | H | 8 | defect | Two serif blocks at the head - the bold title and a mut serif standfirst at nearly the same size (se3/rules-light-large.png, 17pro/rules-dark-AX3.png); UI_SYSTEM 1.4 allows one |
| owner | H | 8 | defect | A title and a serif summary lead; each rule is a mono head and a paragraph (se3/rules-light-large.png). |
| category | T | 8 | defect | The question heads are 11px tracked mono. |
| craft | T | 8 | defect | Mono caps labels (HOW IT SCORES) over sans answers (se3/rules-light-large.png) |
| owner | T | 8 | defect | Rule heads are 11pt tracked mono. |
| category | Sp | 8 | content | Tidy. |
| craft | Sp | 8 | defect | Q/A pairs sit close with no rule between them, so the answers run together as one column (se3/rules-light-large.png) |
| owner | Sp | 8 | defect | Paragraphs run long without breaks. |
| category | C | 7 | defect | The sentences come from the shared producers, but the minimum line differs from the web ('best 4' vs 'best four') (L-34). |
| craft | C | 8 | defect | Rule labels are mono caps ('HOW IT SCORES') where Home's and Compete's section heads are board caps ('THIS WEEK') (se3/rules-light-large.png vs 17pro/home-populated-dark-large.png) |
| owner | C | 8 | defect | "The top 2 golfers" here, "The top two golfers" in the covenant (se3/rules-light-large.png vs 17pro/invite-signedin-dark-large.png). |
| category | B | 6 | defect | Rules in the product's voice; no object. |
| craft | B | 7 | defect | A text page with no drawn object or mark beyond the serif title (se3/rules-light-large.png) |
| owner | B | 7 | content | Rules in the voice; no object. |
| category | P | 7 | decision | A well-set text page. |
| craft | P | 8 | defect | Money and splits sit as plain words inside sentences ('$40 each, $320 in the pot. Sixty percent...') rather than as figure runs (17pro/rules-dark-large.png) |
| owner | P | 8 | content | Plain, well set. |
| owner | R | 8 | defect | The endgame paragraph folds three rules into one ("scored fresh, so the weeks before it decide who is in, not who wins. Level on points? Months won breaks it."). |
| category | E | 5 | decision | It is a rules page. |
| craft | E | 6 | decision | A rules page; the genre caps the feeling (se3/rules-light-large.png) |
| owner | E | 7 | content | A rules page. |
| category | D | 7 | content | Right. |
| craft | D | 8 | defect | The rules restate the season dates and the pot the season page already shows (17pro/rules-dark-AX3.png) |
| owner | D | 8 | content | Right. |
| category | M | 8 | device-or-human | Fits, and grows cleanly at AX3 (17pro/rules-dark-AX3.png). |
| craft | M | 8 | device-or-human | The two 17 Pro large frames caught the push transition mid-slide (17pro/rules-dark-large.png, 17pro/rules-light-large.png) - a capture-timing artifact. Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 8 | device-or-human | AX3 wraps whole; the two 17 Pro large captures were taken mid-push (17pro/rules-dark-large.png, 17pro/rules-light-large.png). |

### `native/widgets`

Means: category 7.7 · craft 7.6 · owner 7.9.

*Category scope:* The in-app widget and Live Activity review pages (synthetic records from the app's own producers), on both phones, both sizes and both themes. The real Home Screen, Lock Screen and Dynamic Island are not captured.

*Craft scope:* The four home widgets, the empty widget and three Live Activity states, all eight variants, at 4112a3f0 - rendered by the in-app review harness, not by WidgetKit on the system surfaces.

*Owner scope:* Four widgets (populated, empty) and the Live Activity (long, missed, closed), as in-app review renders. Staleness is stated ("AS OF 5:59 PM"); the missed hole says "Hole 2 · not entered".


| Judge | Dim | Score | Kind | What stands between it and 10 |
|---|---|---:|---|---|
| category | H | 8 | defect | The Race, Next Tee, Record and Rivalry widgets each lead with their figure. The small Race widget clips '10 back of Blake Samp…' and Next Tee clips 'NORTH GROVE (FI…' (17pro/widget-CSSeasonWidget-dark-large.png, 17pro/widget-CSNextTeeWidget-dark-large.png). |
| craft | H | 8 | defect | Each widget leads with its figure, but the Season widget's serif line '10 back of Blake Sample.' competes with the rail (17pro/widget-CSSeasonWidget-dark-large.png) |
| owner | H | 8 | defect | The Race widget's large size puts "10 back of Blake Sample." after the table (17pro/widget-CSSeasonWidget-dark-large.png). |
| category | T | 8 | defect | Well set: figures, the leaf, the serif lines. |
| craft | T | 8 | defect | Small widgets set sub-lines at agate with 'AS OF 5:59 PM' stamps that dominate the foot (17pro/widget-CSRecordWidget-light-large.png) |
| owner | T | 8 | defect | Serif, sans and mono mix inside small widgets. |
| category | Sp | 8 | content | Tidy. |
| craft | Sp | 7 | defect | At AX3 every widget collapses to truncated text: '81 · 18 h...', 'North Grove...', 'AS OF 6:3...', 'Open to refre...' (17pro/widget-CSRecordWidget-dark-AX3.png, 17pro/widget-CSSeasonWidget-dark-AX3.png, 17pro/widget-empty-dark-AX3.png) |
| owner | Sp | 8 | defect | The small widgets are dense. |
| category | C | 6 | defect | The Record widget says 'Personal best · 81' (the best round against the course) while the record page says 'The best of them a 79' and prints '79 BEST' (17pro/widget-CSRecordWidget-dark-large.png vs 17pro/record-dark-large.png). One noun names two different figures. |
| craft | C | 8 | device-or-human | Shown only in an in-app review harness, so consistency with the system surfaces (margins, corner radius, tinted and clear modes) is not evidenced (17pro/widget-CSRecordWidget-light-large.png) |
| owner | C | 8 | defect | The Next Tee widget prints "7:10 AM" where the app prints "7:10a" (17pro/widget-CSNextTeeWidget-dark-large.png vs 17pro/plan-dark-large.png). |
| category | B | 8 | content | Ours: the leaf, the figures, the ember Next in the Live Activity. |
| owner | B | 8 | content | Type and ground carry it; no mark. |
| category | P | 8 | device-or-human | Made. They are shown on a review page, not the Home Screen. |
| craft | P | 8 | defect | Premium at default size; at AX3 every widget degrades to truncated text (17pro/widget-CSRecordWidget-dark-AX3.png) |
| owner | P | 8 | device-or-human | These are in-app review renders; system chrome, Lock Screen and StandBy rendering are unproven. |
| category | R | 8 | device-or-human | Readable at the review size. |
| craft | R | 7 | defect | At AX3 lines truncate mid-word ('81 · 18 h...', 'AS OF 6:3...') (17pro/widget-CSRecordWidget-dark-AX3.png) |
| owner | R | 8 | defect | The empty Race widget tells a brand-new golfer to "Open Cup Season to catch up." (17pro/widget-empty-dark-large.png). |
| category | E | 7 | content | The Live Activity's hole-by-hole '1 up' with steppers pulls. The widgets are informational. |
| craft | E | 7 | content | Synthetic records and no round photograph in any widget (17pro/widget-CSRecordWidget-dark-large.png) |
| owner | E | 8 | content | "A round to keep · Personal best" and "Casey took the last one." are memory. |
| category | D | 8 | content | Right. |
| craft | D | 8 | defect | An 'AS OF' stamp sits on every widget at every size, fresh or not (17pro/widget-CSRivalryWidget-dark-large.png) |
| owner | D | 8 | content | Right; the Rivalry widget names its basis ("Weekly clashes · All time"), which the web's rivalry rows do not. |
| category | M | 8 | device-or-human | AX3 captured on the review pages. |
| craft | M | 6 | device-or-human | These are an in-app review harness ('Native widget review · synthetic records from the app's own producer'), not the Home Screen, Lock Screen or Dynamic Island; the Live Activity controls are drawn in-app (17pro/island-closed-dark-large.png). Rest frames only: no tap, scroll, keyboard, VoiceOver or thumb pass on a device (HUMAN.md D1-D13) |
| owner | M | 7 | defect | Small sizes truncate names ("10 back of Blake Samp…", "NORTH GROVE (FI…") (17pro/widget-CSSeasonWidget-dark-large.png, 17pro/widget-CSNextTeeWidget-dark-large.png); real Home Screen rendering is not captured. |
