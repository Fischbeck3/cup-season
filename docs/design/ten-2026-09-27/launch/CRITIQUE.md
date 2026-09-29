# Critique · Impeccable critiques A and B, web (round 1)

| | |
|---|---|
| **Measured at** | web **`9d84c483`**. `play`, `receipt`, `record`, `you`, `golfers` and `book` were critiqued from `9d84c483` captures; every other family from `02636007`, which renders them byte-identically (COVERAGE.md §1.1). |
| **Status read at** | **`b8a61266`**: `git log cf401dee..b8a61266`, plus `9d84c483..cf401dee`. That covers root's fix commits, N2's merge at `de3eaf35`, and the merges of lanes W3 (`e8108e59`), W2 (`f46086b4`) and W4 (`b8a61266`), which root forwarded on 2026-09-28. W1, W5 and W6 had not merged. |
| **Date** | 2026-09-28 |
| **Assessors** | critique **A** and critique **B**. Each ran Impeccable 4.3.1's `critique` independently and never saw the other's work. |
| **Raw evidence (outside git)** | `~/cup-season-claude-ten-gallery/evidence/critique-A/` and `…/critique-B/` (one `.md` per target, plus `summary.json`) · the brief `~/cup-season-claude-ten-gallery/evidence/CRITIQUE-PROMPT.md` · captures in `~/cup-season-claude-ten-gallery/root/harness-9d84c483/` |

Written by session C (docs). Scores, titles and captures are the assessors'; the status column is this file's, read from commits.

**The gate** (SESSIONS §1): at least 36/40 per target (90%; on a renormalised maximum that is 32.4/36 or 28.8/32), no heuristic below 3, and no P0 or P1.
**Round 1: not met on any target.**
- The best raw scores are 30/40 for A (events, settings, play) and 29/40 for B (competition, events, support).
- The best percentages are A's support at 26/32 (81%) and B's legal at 25/32 (78%).
- Only four targets have no heuristic below 3: A's get, support and legal, and B's legal. All four are below 90%.

**Status words:**
- *fixed (sha)*: the commit message or diff shows the fix; for a lane, the sha is the lane's merge and the lane's own commit names the item. **Every fix is verification pending** until round 2 (session D) re-measures it on the final SHA.
- *fixed in part (sha)*: the rest is named.
- *in lane Wn*: the surface belongs to that lane (LEDGER §4f), and no commit at `b8a61266` shows the fix. At `b8a61266`, W1, W5 and W6 have not merged.
- *decision Xnn*: the question is in OWNER-QUESTIONS.md.
- *open*: no lane owns the surface and no commit fixes it.
- *open, verification pending*: when unsure.

## 1 · Per target

`score` is the total over the heuristics scored; a maximum below 40 means heuristics were marked n/a under critique.md's mode rule, with the reason in `summary.json`. `lowest` is the minimum heuristic and every heuristic at it: H1 status, H2 real world, H3 control, H4 consistency, H5 error prevention, H6 recognition, H7 flexibility, H8 minimalism, H9 error recovery, H10 help. Lanes as in PANEL.md §2.

| Target | Mode | A score | A lowest | A P0·P1·P2·P3 | B score | B lowest | B P0·P1·P2·P3 | Lane |
|---|---|---|---|---|---|---|---|---|
| door | Persuade | 26/36 (72%) | 2 · H10 | 0·1·4·1 | 27/40 (68%) | 2 · H1, H4, H5 | 0·1·5·7 | root |
| home | Operate | 25/40 (62%) | 2 · H2, H4, H8, H9, H10 | 1·1·7·3 | 24/40 (60%) | 2 · H2, H4, H7, H8, H9, H10 | 1·2·11·15 | W3 |
| post | Operate | 26/40 (65%) | 2 · H1, H4, H8, H9 | 0·1·6·1 | 25/40 (62%) | 2 · H1, H2, H4, H8, H9 | 0·3·5·6 | W1 |
| share | Persuade | 21/36 (58%) | 2 · H1, H4, H5, H6, H9, H10 | 0·0·4·2 | 22/36 (61%) | 2 · H1, H4, H5, H9, H10 | 0·1·4·3 | W4 |
| public-round | Persuade | 26/36 (72%) | 2 · H4, H10 | 0·0·2·2 | 23/32 (72%) | 2 · H4 | 0·1·2·6 | W4 |
| claim-invite | Persuade | 23/36 (64%) | 2 · H1, H4, H8, H9 | 0·0·6·3 | 23/36 (64%) | 2 · H1, H4, H8, H9 | 0·1·9·4 | W4 |
| identity | Operate | 27/40 (68%) | 2 · H2, H4, H7, H8 | 0·1·5·4 | 27/40 (68%) | 2 · H4, H7, H8 | 0·2·8·7 | W2 |
| golfers | Operate | 27/40 (68%) | 2 · H4, H8, H9 | 0·0·5·3 | 27/40 (68%) | 2 · H4, H8, H9 | 0·1·8·6 | W3 |
| history | Operate | 28/40 (70%) | 2 · H4, H8 | 0·1·4·3 | 26/40 (65%) | 2 · H2, H4, H7, H8 | 0·3·6·5 | W1/W2 |
| season | Operate | 27/40 (68%) | 2 · H4, H8, H9 | 0·1·3·2 | 27/40 (68%) | 2 · H1, H4, H8 | 2·1·11·8 | root |
| competition | Operate | 29/40 (72%) | 2 · H2 | 0·0·2·4 | 29/40 (72%) | 2 · H2 | 0·0·6·10 | W5 |
| events | Operate | 30/40 (75%) | 2 · H6 | 0·0·2·3 | 29/40 (72%) | 2 · H4 | 0·0·9·6 | W2 |
| schedule | Operate | 25/40 (62%) | 2 · H4, H5, H6, H8, H9 | 0·0·5·3 | 26/40 (65%) | 2 · H1, H4, H8, H9 | 1·0·8·5 | W2 |
| wizard | Operate | 29/40 (72%) | 2 · H4, H5, H9 | 0·1·1·3 | 26/40 (65%) | 2 · H1, H4, H6, H9 | 0·4·2·6 | W5 |
| courses | Operate | 26/40 (65%) | 2 · H4, H8, H9, H10 | 0·0·2·3 | 27/40 (68%) | 2 · H4, H7, H9 | 0·0·6·4 | root |
| settings | Operate | 30/40 (75%) | 2 · H9 | 0·1·1·2 | 28/40 (70%) | 2 · H4, H9 | 0·1·3·3 | W2 |
| rules | Read | 28/40 (70%) | 2 · H5, H9 | 0·0·2·3 | 26/40 (65%) | 2 · H1, H4, H6, H9 | 0·0·6·5 | root |
| get | Persuade | 28/36 (78%) | 3 · H1, H3, H4, H5, H6, H8, H9, H10 | 0·0·0·3 | 28/40 (70%) | 2 · H7, H8 | 0·0·2·5 | W4 |
| support | Read | 26/32 (81%) | 3 · H1, H3, H4, H6, H7, H8 | 0·0·0·3 | 29/40 (72%) | 2 · H9 | 0·0·1·4 | W4 |
| legal | Read | 24/32 (75%) | 3 · H1, H2, H3, H4, H6, H7, H8, H10 | 0·0·0·3 | 25/32 (78%) | 3 · H1, H3, H4, H6, H7, H8, H10 | 0·0·0·4 | W4 |
| desk | Operate | 28/40 (70%) | 2 · H4, H8 | 0·1·3·1 | 26/40 (65%) | 2 · H1, H4, H7, H8 | 4·19·13·11 | all + W6 |
| play | Operate | 30/40 (75%) | 2 · H9 | 0·0·2·5 | 28/40 (70%) | 2 · H4, H8 | 0·1·7·6 | W1 |
| **all** | | | | **1·9·66·60** | | | **8·41·132·136** | |

**Reading the counts.**
- B's `desk` target carries 4 P0 and 19 P1 that are cross-references: each says "Owned by `<target>`, where the full analysis and verification live". B's distinct defects are **4 P0 and 20 P1**, as LEDGER §4f records.
- A's are **1 P0 and 7 P1**: `desk` re-lists Home's photo card, and `history` re-lists identity's Form row.
- Together they are **25 distinct P0/P1 defects** (§3).

## 2 · Where the heuristics fail

Targets with each heuristic below 3:

| Heuristic | A (of 22) | B (of 22) |
|---|---:|---:|
| H4 Consistency and standards | **13** | **18** |
| H8 Aesthetic and minimalist design | 10 | 11 |
| H9 Error recovery | 12 | 11 |
| H1 Visibility of system status | 3 | 9 |
| H7 Flexibility and efficiency | 1 | 6 |
| H10 Help and documentation | 5 | 2 |
| H5 Error prevention | 4 | 2 |
| H2 Match with the real world | 3 | 4 |
| H6 Recognition rather than recall | 3 | 2 |
| H3 User control and freedom | 0 | 0 |

**Consistency (H4) is the common failure.** Both critiques mostly cite one fact said differently on two surfaces (L-34), shared components drawn differently (the wordmark, CTA grammar, the retired spine), and the phone and the desk telling one sentence two ways (D234). The panel's lowest dimension is also consistency (PANEL.md §1). Many H4 items are shared producers and chrome, which LANE-BRIEF kept out of lanes W1–W5; they are session B's (W6).

## 3 · Every P0 and P1, with status

Entries are merged where A and B, or a target and B's desk cross-reference, describe one defect. "Where" names the targets that raised it.

| # | Pri | Defect | Where (A · B) | Captures (first cited) | Element | Status at `de3eaf35` |
|---|---|---|---|---|---|---|
| CQ-01 | **P0** | A nine-hole 43 is announced "Broke 80 for the first time." | A home · B home, desk | `home--league-less-rounds_no_buddies--375--dark.png` | `homeRoundDetail` ← `home_feed.is_sub80` (no 18-hole guard, `20261020090000_one_round_one_number.sql`) | **fixed in part (e8108e59).** The web makes a sub-80 claim only when the round is known to be 18 holes, and a known nine reads "9 HOLES" (2dce66e6). **Open:** the server half is X41 (owner's `db push`); the phone's `HomeWireCopy` guard goes to N4. |
| CQ-02 | **P0** | Golfer rows and board stripes wear the other squad's colour. | B season, desk | `desk--season--1280--dark.png` | `#indTable .sw` and board stripes, fed by list position rather than `squads.color` | **fixed (69f40d1f)**: `squads.color`, resolved as the squad rows are; the tag is the squad's name |
| CQ-03 | **P0** | A 53–53 tie is ranked 01/02, and one Points King is picked by average vs playing HCP. | B season, desk | `desk--season--1280--dark.png` | `#indTable` rank, `#awKing = rows[0]` | **fixed (69f40d1f)**: tied golfers share a rank (T01), and no Points King is crowned by average (D136) |
| CQ-04 | **P0** | "YOU'RE IN" / "Avery and Devon are in." for a golfer who hasn't answered. | B schedule, desk | `schedule--populated--1280--dark.png`, `schedule--plan-landing--375--dark.png` | `renderWatchList` on `tagged_me`; `the_plan_link.sql` `coalesce(rsvp,'in')` | **fixed in part (f46086b4).** There is one producer for "in" (`csPlanMe`, 57325028): an unanswered tag reads ASKED and offers I'm in. **Open:** the public card is `share_info`'s plan `who` (X42, `20260921100000_the_plan_link.sql:222`, owner's `db push`); the phone's `ScheduleScreen` still keys YOU'RE IN on `tagged_me` (N4). |
| CQ-05 | P1 | Keyboard focus walks into the hidden app behind the Door. | B door, desk | `door--initial--375--dark.png` | `#onboard` over a focusable shell | **fixed (38471687)**: covers make the app inert; Tab presses landing on the app behind the Door went from 16 of 30 at 375 to 0 |
| CQ-06 | P1 | The desk Door's "live" season is invented activity. | A door | `door--initial--1280--dark.png` | `aside.ob-wing` (`#obFeed` "Rounds hitting the board", `#obLb` "The season, live") | **fixed (b8a61266)**: the wings read "How a round reads" and "How a season reads", the foot says it is an example season, "every point has a receipt" is gone, and the wings stand down on a link landing (2bc71749). Whether the phone Door shows a specimen too is Q6. |
| CQ-07 | P1 | The photo round card renders broken on Home, phone and desk. | A home, desk · B home, desk | `home--member--375--dark.png`, `desk--home--1600--dark.png` | `feedRow()` photo branch: `.hsfoot` band across the photo; `.hfr-course` under the image | **fixed (e8108e59)**: the photograph is a plate with the golfer, course and gross on a bottom-anchored scrim; everything else sits under it with one foot row, applause · comment · Receipt (2dce66e6) |
| CQ-08 | P1 | "MONTH CLOSES" is ember on bg2 at 3.77:1 in the dark printing. | B home, desk | `home--member--1280--dark.png` | `.upchip.hot .k` | **fixed (38471687)** (AW P1-4, DX OB-02) |
| CQ-09 | P1 | A refused post is a 2.4-second toast that contradicts itself and names a button that isn't there. | A post · B post, desk | `composer--post-failed--402--dark--first.png` | `#toast`: the specific prefix plus `humanError`'s generic line; "press Post again" beside "Add my round" | open · in lane W1 (not merged at `b8a61266`) |
| CQ-10 | P1 | "+1.4 · YOUR PLAYING HCP": a signed margin under the playing HCP's own name. | B post, desk | `composer--filled--375--dark.png` | `#calcVs`; a second top-level `vsShort` shadowed the words form | **fixed (38471687)**: "beat by 1.4" again, with `vsSigned` for the clash and the receipt row. **Open:** the label is still "your playing HCP", not R-M's "vs your playing HCP" (`index.html:5503` at `de3eaf35`), in lane W1; and no preflight check catches duplicate top-level functions. |
| CQ-11 | P1 | The unlisted-course hint says the round "won't show in your rounds". | B post, desk | `composer--filled--375--dark.png` | `#inCourseHint` (`paintCourseHint`); D150 affects only course history | open · in lane W1 (not merged) |
| CQ-12 | P1 | "Include round photo" is offered on rounds with no photo. | B share, desk | `share--recap-no-photo--375--dark.png` | `#finPhoto`: `.finish-photoopt{display:flex}` beats `hidden` | **fixed (38471687)**: `[hidden]` always hides. W4's df111545 then made the photo a switch that states itself. |
| CQ-13 | P1 | The settlement hole strip separates the two sides by hue alone (1.05:1 luminance) and keys only one side. | B public-round, desk | `public-round--settlement--1280--dark.png` | `renderHoleStrip` (`STRIP_HOT`/`STRIP_COOL`) and the legend | **fixed (b8a61266)**: a second channel (the subject's holes full height, the other side's half, halved hollow, unplayed dashed), a spoken summary and a key in words (df8e958f). The in-app settlement sheet calls the same renderer (lane W1). |
| CQ-14 | P1 | A dead league code is told it is invited. | B claim-invite, desk | `links--join-unavailable--375--dark.png` | `#obStatus` after `league_by_code` returns null | **fixed (38471687)**: "No league with that code. Check with your Pro.", from one producer, and the code is dropped |
| CQ-15 | P1 | The Form row crowns a nine-hole 43 as the best of the last five, in gold. | A identity, history · B identity, history, desk | `you--populated--375--dark.png` | `formRowHtml` | **fixed (38471687, f46086b4)**: a nine never takes the gold and reads "NINE"; a best is gilded only among two or more comparable rounds (35b4f475). The phone's nine is 74997409; its two-round rule is for N4 to check. |
| CQ-16 | P1 | Deleting a round is an 8px × nested inside the row that opens the receipt, confirmed by a native `confirm()`. | B identity, history, desk | `you--populated--375--dark.png` | `.yrow .ydel` | **fixed in part (38471687)**: a 44px hit area. **Open, verification pending:** W2's merge (`f46086b4`) does not name this control. At `de3eaf35` it still sat inside the receipt row and used `confirm()`, where B asks for a labelled "Delete round" on the receipt with UI_SYSTEM §7.1's armed pattern. |
| CQ-17 | P1 | The board sheet's header is unreadable in the light printing (2.42:1). | B golfers, desk | `golfers--board--375--light.png` | `#boardFull .bf-hdr` literal charcoal glass | **fixed (38471687)**: the header takes the page's own ground, and the title is ink (DX TP-06) |
| CQ-18 | P1 | A profile photo is credited as a round photo ("BLAKE'S ROUND · SAT" over Blake's avatar). | B history, desk | `record--photo-credited--375--dark.png` | `csCredentialHtml`: avatar plus a credit from `card.recent[0]` | **fixed (f46086b4)**: a profile photo is no longer credited as a round (35b4f475) |
| CQ-19 | P1 | The season's title fails contrast in the light printing (2.69:1). | A season · B season, desk | `season--narrative--375--light.png` | `#seasonTitle.seasontitle{color:var(--ink)}` on the ember band | **fixed (38471687)** (AW P1-3, DX TP-01) |
| CQ-20 | P1 | Step 2 says "Standard = best three" beside a dial reading "Best 4", and carries the contradiction into the review and the covenant. | A wizard · B wizard, desk | `wizard--step-2-rules--375--dark.png`, `links--join-covenant--375--dark.png` | `.preset.sel` lead from the preset's own cap (`csPresetLead`); `#structNote`'s markup default | open · in lane W5 (not merged) |
| CQ-21 | P1 | At the desk, "Review the rules" shows no rules. | B wizard, desk | `wizard--step-3-review--1280--dark.png` | `#view-wizard #bylawsReview{display:none}` at ≥1100px | **fixed (38471687)** |
| CQ-22 | P1 | "Start the season" is disabled, and nothing says why. | B wizard, desk | `wizard--step-3-review--375--dark.png` | `#lockBtn` disabled by `csRenderPayNote()`, with the reason only on step 2 | **fixed (38471687)**: `#lockWhy`, with a door to the pay note |
| CQ-23 | P1 | The squad options are faded to 40%, including the chosen one. | B wizard, desk | `wizard--step-2-dials--1280--dark.png` | `renderStructFit()` sets `opacity:.4` (DX OB-03) | open · in lane W5 (not merged) |
| CQ-24 | P1 | "Delete permanently" fails contrast in the default dark theme (2.81:1). | A settings · B settings, desk | `settings--delete-confirm--375--dark.png` | `#phDelYes` inline `background:var(--neg); color:#fff` | **fixed (38471687)** (DX TP-07). W2's 35b4f475 also makes the confirm say what D396 does, word for word with the phone. |
| CQ-25 | P1 | The score steppers are 36px: the round's most-touched control is below the 44px floor. | B play | `play--scoring--402--dark.png` | `.step button{width:36px;height:36px}` | **fixed (38471687)**: steppers among the 44px targets; the gap between − and + is open, verification pending |

**Tally at `b8a61266`:** 25 distinct defects (4 P0, 21 P1). Every fixed item is verification pending until round 2.
- **fixed: 18.** CQ-02, 03, 05, 06, 07, 08, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 24 and 25. CQ-10 keeps a named residual in W1.
- **fixed in part: 3.**
  - CQ-01: the web half; X41 and N4 remain.
  - CQ-04: in-app; X42 and N4 remain.
  - CQ-16: the 44px target.
- **open: 4.** CQ-09 and CQ-11 (W1), CQ-20 and CQ-23 (W5). None of those lanes had merged at `b8a61266`.

## 4 · P2 and P3

A raised 66 P2 and 60 P3; B raised 132 P2 and 136 P3, including its desk cross-references. They are listed with captures, elements and fixes in each target's `.md` and in `summary.json`, and LANE-BRIEF points every lane at them. Their status is taken in round 2 (session D's delta table), which re-reads every round-1 P0 and P1 against new captures.

## 5 · Native

**Pending (session A).** Session A runs critiques A and B on every native row at `4112a3f0` (COVERAGE.md §2), writing to `~/cup-season-claude-ten-gallery/evidence/native/critique-{A,B}/`. Rows that are not captured (the Door, wizard steps 2–3, live scoring) are scored "not captured".
