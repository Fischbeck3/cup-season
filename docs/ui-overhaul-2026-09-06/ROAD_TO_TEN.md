# ROAD TO TEN — what the remaining distance is made of

**Date** 2026-09-07 · **HEAD** `ee321bf` · **Build on the phone** 733 · **Prod** 217 migrations
**Standard** `BRIEF.md` §29, read literally: **10** = would sit beside the best consumer sports apps
with no apology · **8** = finished · **6–7** = polish inside the current structure · **below 6** =
redesign. **Companions** `UI_SCORECARD.md` (Phase-1 baseline + the design target),
`BUILD_REPORT.md` §3–§4 (the pre-visual-pass build and what was left undone), `VISUAL_PASS.md`.

**You asked one question: *on your scoring criteria, what is needed to get it to a 10 for UI?***
This document answers it and does nothing else. No work was done to the product to write it.

**How the numbers were made.** Three scorers went over 42 fresh captures of the shipped build — 24
dark, 8 light, 8 at AX3, plus the sign-in door at 375pt and at 430pt — and scored the same 23
surfaces on the same ten dimensions. Every cell below is the **median of the three**, so no single
reading carries a row. `EVIDENCE_POLICY` holds: nothing here counts what anybody did in production.
Every count in this document was re-derived at `ee321bf` rather than inherited; where a scorer's
count did not reproduce, the verified one is printed and the discrepancy is named.

**What is new about this re-score, and it matters more than the numbers.** Wave 0a's two hatches —
`-cs_dev_appearance` and `-cs_dev_text_size` — work. This is the **first score in the product's
history with observed light-theme and accessibility evidence.** Every light and AX3 number in the
Phase-1 baseline and in the design target was computed from tokens and never seen. Nine of the
defects below could not have been found before today.

---

# 1 · WHERE IT ACTUALLY STANDS

| screen | H | T | Sp | C | B | P | R | E | D | M | mean | verdict |
|---|--|--|--|--|--|--|--|--|--|--|--|---|
| **tour-card** | 9 | 8 | 7 | 6 | 9 | 9 | 8 | 8 | 8 | 7 | **7.9** | polish |
| **you** | 8 | 8 | 7 | 7 | 9 | 8 | 8 | 7 | 7 | 6 | **7.5** | polish |
| **season** | 8 | 8 | 6 | 7 | 9 | 8 | 8 | 7 | 7 | 5 | **7.3** | polish |
| **play-cover** | 8 | 8 | 7 | 7 | 7 | 7 | 9 | 6 | 6 | 8 | **7.3** | polish |
| **intent** | 8 | 8 | 7 | 8 | 6 | 7 | 9 | 6 | 7 | 7 | **7.3** | polish |
| **leaderboard** | 8 | 8 | 7 | 6 | 8 | 7 | 8 | 6 | 7 | 6 | **7.1** | polish |
| **person** | 7 | 8 | 7 | 6 | 8 | 7 | 8 | 6 | 6 | 7 | **7.0** | polish |
| **home** | 7 | 8 | 6 | 6 | 8 | 7 | 8 | 6 | 6 | 6 | **6.8** | polish |
| **record** | 7 | 8 | 5 | 6 | 8 | 7 | 8 | 6 | 7 | 6 | **6.8** | polish |
| **live** | 8 | 7 | 6 | 6 | 7 | 6 | 7 | 6 | 8 | 6 | **6.7** | polish |
| **course** | 7 | 8 | 6 | 6 | 7 | 6 | 8 | 4 | 7 | 6 | **6.5** | polish |
| **compete** | 7 | 7 | 6 | 7 | 7 | 6 | 8 | 5 | 5 | 6 | **6.4** | polish |
| **settings** | 6 | 6 | 6 | 6 | 8 | 6 | 7 | 6 | 7 | 5 | **6.3** | polish |
| **season-story** | 6 | 7 | 7 | 7 | 6 | 6 | 7 | 4 | 5 | 7 | **6.2** | polish |
| **door** | 7 | 7 | 6 | 5 | 7 | 6 | 8 | 6 | 6 | 4 | **6.2** | polish |
| **golfers** | 6 | 6 | 6 | 5 | 7 | 6 | 7 | 5 | 6 | 5 | **5.9** | redesign |
| **h2h** | 6 | 7 | 5 | 6 | 6 | 5 | 8 | 4 | 4 | 7 | **5.8** | redesign |
| **plan** | 6 | 6 | 6 | 5 | 5 | 5 | 7 | 4 | 7 | 6 | **5.7** | redesign |
| **wizard** | 6 | 6 | 4 | 5 | 5 | 5 | 7 | 4 | 6 | 6 | **5.4** | redesign |
| **schedule** | 5 | 4 | 5 | 4 | 4 | 4 | 6 | 4 | 6 | 4 | **4.6** | redesign |
| **board** | 4 | 5 | 5 | 3 | 4 | 3 | 6 | 4 | 6 | 5 | **4.5** | redesign |
| **composer** | 5 | 4 | 5 | 4 | 4 | 4 | 6 | 3 | 5 | 4 | **4.4** | redesign |
| **bag** | 4 | 5 | 4 | 4 | 3 | 3 | 5 | 3 | 4 | 5 | **4.0** | redesign |

**Product mean 6.24 across 23 surfaces. Fifteen of twenty-three now clear 6; eight do not. None
reaches 8.** The three scorers' own product means were 6.18, 6.13 and 6.42 — they agree on the level.

## Per dimension, against both prior columns

| | R | T | H | B | D | P | Sp | M | C | E |
|---|---|---|---|---|---|---|---|---|---|---|
| **Phase 1**, 25 surfaces | 6.36 | 5.24 | 4.92 | 5.28 | 4.92 | 4.12 | 5.48 | 5.84 | 4.80 | **4.00** |
| **now**, 23 surfaces | **7.43** | **6.83** | **6.65** | **6.61** | **6.22** | **6.00** | **5.91** | **5.83** | **5.74** | **5.22** |
| move | +1.07 | +1.59 | +1.73 | +1.33 | +1.30 | +1.88 | +0.43 | −0.01 | +0.94 | +1.22 |

*The two screen sets are not identical — Phase 1 carried `events`, `pot`, `sheets`, `onboarding` and
`web`, which nobody could photograph this time, and this set adds `intent`, `plan`, `h2h` and
`season-story` — so read the move as the shape of the change, not to two decimals.*

**On the seven surfaces `BRIEF` §30 put in Phase 3's order, six of which are in this set** (the
event room has no real data and was not shot):

| | H | T | Sp | C | B | P | R | E | D | M | mean |
|---|--|--|--|--|--|--|--|--|--|--|--|
| Phase-1 baseline (six) | 5.17 | 5.33 | 5.50 | 4.83 | 5.50 | 4.33 | 6.33 | 4.33 | 5.00 | 5.67 | **5.20** |
| built at `35b2dd2`, pre-visual-pass (seven) | 7.00 | 8.14 | 5.86 | 5.71 | 8.14 | 7.14 | 7.57 | 6.57 | 6.29 | 6.00 | **6.84** |
| **now** (six) | 7.83 | 8.00 | 6.50 | 6.33 | 8.33 | 7.50 | 8.00 | 6.33 | 7.00 | 6.00 | **7.18** |

## Said plainly

**It moved, and it moved most where the brief asked.** Premium feel +1.88, visual hierarchy +1.73,
typography +1.59, brand identity +1.33, emotion +1.22. The Phase-1 diagnosis was *readable and
unloved*: readability was the only dimension above 6, two full points clear of everything the brief
cares about. That gap has closed to 1.4. Eleven surfaces now carry a drawn object; four score 8 or 9
on brand and premium; the flagship credential is at 7.9, within a tenth of the brief's bar.

**Two things did not move, and one of them went backwards.**

- **Mobile usability, 5.84 → 5.83.** Not one point, across the whole overhaul, on the dimension that
  decides whether the product works on a phone. The *original* cause was genuinely removed — D269
  deleted the system tab bar for `CSTabBand` and `csStatusCap` stops content sliding under the clock
  — and four new guillotines took its place, three of which nobody could see until the hatches
  shipped. The worst is not a polish item: **on a 375pt phone with the keyboard up, `CONTINUE WITH
  EMAIL` — the only action on the first screen of the product — is entirely behind the keyboard, and
  the app mark is cut in half by the status bar.** That is observed, in `se-door.png`.
- **Spacing, 5.48 → 5.91.** +0.43 over thirteen waves. There is still no spacing token in the
  product: LINT-06 holds at 1,206 literals. The specific fault is not broken rhythm, it is that
  nobody has ruled where a rule stops — on Home's ME strip the rule runs the full measure past `$75`
  with nothing over its right half, and `1 round.` sits alone in the gap below it with roughly 130pt
  of void either side.

**And nothing anywhere is a 10.** Of the 230 median cells: **zero tens, seven nines, 39 eights.**
Sixty-one cells are still below 6. Reaching a product mean of 8 is **+404 cell-points**; reaching 10
is **+864**. That is the honest scale of the question you asked.

## Where the three scorers disagreed by more than a point

Only three rows, and I will say which reading I hold.

| row | category | craft | owner | median | **my reading** |
|---|--:|--:|--:|--:|---|
| **course** | 6.3 | 5.5 | 6.9 | 6.5 | **6.4 — category.** Craft's B 5 / P 4 undersells the drawn 18-bar card: it is a real proprietary object, drawn by yardage with the hardest hole lit, and it is the best thing on the page. Owner's B 8 / P 7 oversells a page whose entire emotional argument is five generic hollow outline stars and which contains no photograph of a golf course. Both true at once. |
| **door** | 6.1 | 5.9 | 7.1 | 6.2 | **6.1 — category.** Craft's T 5 punishes the serif wordmark in the typography column when it is a *consistency* fault (two wordmarks for one brand); the type on that screen is well set. Owner's pairing of B 9 with M 4 is incoherent — a first screen whose primary action is unreachable on the smallest supported phone is not a 9 on anything. |
| **person** | 6.8 | 6.3 | 7.4 | 7.0 | **6.6 — craft.** I checked the capture. The credential here sits inside a 1px-bordered rounded rectangle whose fill is barely above the ground — the exact grammar D266 deleted, surviving on a flagship object — and the page is one card, one full-width ember slab that outranks the person's name, one paragraph, and a large grey grid glyph that reads as a missing image. Owner has attached the tour card's score to the person page. |

Three cells were fought over by three points: `course.B` (7/5/8), `course.P` (6/4/7) and `door.T`
(7/5/8). All three are the same argument — *does a drawn object you have seen eleven times still
count as proprietary* — and the answer is yes, but it does not substitute for a photograph.

---

# 2 · WHICH CAPS LIFTED AND WHICH DID NOT

`UI_SCORECARD.md` named five systemic caps that held every Phase-1 row down. Each was re-tested
against the build rather than inherited.

## LIFTED

**Cap 1 — premium ≤ 6 while the card is a border.** **Lifted.** `Capsule(` returns **0** across the
phone target. `RoundedRectangle(` is **107**, down from the audit's 264. `tests/preflight-baselines.json`
records **LINT-30 at 0, from 157**: `CSCard`, `CSStat`, `CSEmptyState`, `CSButton`, `CSHairline`,
`CSGroupHead`, `CSTabStrip`, `CSHero`, `CSWash`, `CSDuskCard` and `CSLookSky` are deleted from the
codebase, and every `.stroke(cs.rule)` round a container went with them because there is no border
token. Premium now reads 9 on the tour card and 8 on You, the season page and the record.
**What replaced the cap is a distribution, not a ceiling** — bag 3, board 3, composer 4, schedule 4
are low because those four surfaces *still carry the old grammar*, not because it is the only
grammar available. `dark-bag.png` is twenty-eight filled rounded rectangles in a column.
**One residue, newly visible: the cap re-forms in light theme.** `light-record.png` renders the bone
SEASONS panel as a white panel with a 1px border on a cream ground — the object D266 deleted,
returning in an appearance nobody had ever looked at.

**Cap 2 — brand ≤ 6 unless the screen carries a proprietary object.** **Lifted**, and it is now the
product's most useful diagnostic. The shipped app icon is a real drawn flag (`icon.png`,
`icon-dark.png`, `icon-tinted.png`), not Xcode's placeholder. `Image(systemName:)` is down to **11
call sites in the phone target**, none of them on a flagship — the residue is draft night, the
wizard's chevron, two admin bells, a look-row checkmark, live's share, a link, an ellipsis and the
rules page's three — against **54 `csGlyph(` sites**. Proprietary objects rendering on real data and
observed in these captures: the credential's contour plus gold look medallion plus folio; the twelve
drawn ball markers; the drawn 18-bar course card; the bone ledger panel; the month band with its
ember current week; the circle/square/dot hole strip; the struck-through 100 for BROKE 100.
**The cap is replaced by a rule the table obeys without exception: a surface scores B ≥ 7 if and only
if it carries a drawn object, and the six surfaces at B ≤ 5 — composer 4, plan 5, wizard 5, board 4,
schedule 4, bag 3 — are precisely the six that carry none.**

**The capture-harness blocker (F-16).** **Closed.** Both hatches work. `-cs_dev_appearance light`
renders a genuine bone ground with inverted plates and a darkened ember; `-cs_dev_text_size AX3`
renders genuinely enlarged type with reflowed layout. All eight AX3 shots are pushed screens rather
than sheets, so §4.6's residual (`csSheet`/`csCover` missing some `.sheet(` presentations) does not
contaminate this set.

## STILL STANDING

**Cap 3 — emotion ≤ 7 everywhere.** **Intact, and it is now the binding constraint on the whole
product.** E is the lowest dimension at 5.22 and exactly one surface breaks 7 — the tour card at 8 —
**because it is the one screen in the product carrying a photograph.** That is the mechanism, stated
by the data itself.
- Its *no faces* clause has **partly** lifted: `home_stories` carries `photo_path`, so the season
  table and the clash rows carry your real photograph. But `friends_board()`'s return table is
  `profile_id · display_name · handle · marker · index_current · rounds_30d · beats_30d ·
  avg_vs_number_30d · best_vs_number_30d · last_round_on · rank_by_form · rank_by_index · is_me` —
  **no `photo_path`** — so the Golfers board draws a mark for the same golfer the table one tab away
  photographs.
- Its *no course imagery* clause is **wholly intact**. Five course renders across two design passes,
  and not one photograph of a golf course.
- Its *ceremony* clause is intact and worse than filed. At HEAD, `SeasonCeremonyView.swift` contains
  exactly **one** match for animation-or-haptics and **it is a comment stating the file has zero**.
  `LiveFinishViews.swift` — 408 lines, the screen where a round ends and money changes hands — has
  **zero**. Six of `UI_SYSTEM` §11.3's seven moments are unbuilt.

**Cap 4 — consistency ≤ 7 wherever glyph families or button grammars mix.** **Standing, but the
cause has moved.** The glyph half is largely closed (11 system symbols against 54 drawn). The button
half is genuinely repaired: **191 tappables now carry a shared definition** — `csPrimary` 56,
`csSecondary` 37, `csTertiary` 25, `csDestructive` 6, plus 67 `CSDoor` — against **221 raw `Button(`**
across `apps/ios` (205 in the phone target). That is ~46% of the raw-button population addressed,
against the audit's 28%.
*(Correction to the scorers, who printed 286 and 59 respectively: the verified pair at HEAD is
191 / 221. The direction all three describe is right; the figures were not.)*
What holds C to 5.74 is three **visible** mixtures, each of which a golfer meets inside four seconds:
1. **Two section-head weights ship simultaneously.** `CSSectionHead` has **83 call sites** and
   exactly **four in production spend `weight: .display`** — `HomeView.swift:290` and
   `CompeteScreen.swift:117` and `:200`. D286 left `.label` as the default, so the fix you asked for
   reached the two screens you photographed and stopped. Golfers, the schedule, the record, settings,
   the course page, live, the person page, the season sub-panes and the plan sheet all still carry
   agate-plus-rule, one tab from Compete's display 24.
2. **59 colour-emoji sites survive** (LINT-12), four of them rendering on one Board screen inside a
   product with a drawn glyph family — and `ReactionBar.swift:4` records the 🔥 as a *decision*,
   which makes it a ruling to reverse rather than a bug to fix.
3. **Two door-row grammars doing one job two taps apart** — Home's caps-name-plus-right-gloss and the
   leaderboard's sentence-name-plus-sub-plus-chevron. Plus one minus glyph on the Board and a
   different one on Golfers, an iOS system-blue caret in the composer and the sign-in field, two
   wordmarks, and four top-right chrome grammars.
Only the intent sheet reaches 8. Twenty-two of twenty-three rows are still capped.

**Cap 5 — mobile ≤ 6 where floating chrome cuts live content.** **Partly lifted, and it now fails for
a different reason than it was written for.** The original cause is gone: `CSTabBand` sits on the
page's own ground with a 1px rule, so there is nothing to float over. But `csStatusCap` is applied on
**six** pages — Home, Compete, Golfers, the season page, You and the Record — against roughly
twenty-five pushed screens, and four new guillotines are observed, three of them visible only because
the hatches now work:
- `se-door.png` — the primary action of the first screen entirely behind the keyboard at 375pt, and
  the app mark cut in half by the status bar.
- `dark-schedule.png` — the page's own pinned ember primary cut by the tab band, only its top curve
  rendering.
- `ax3-composer.png` — a pinned footer taking roughly a third of the viewport and overlapping live
  scroll content with no inset.
- `light-home.png` — a gradient scrim above the band fades `THIS WEEK` to a ghost, so a section head
  reads as *disabled* in light and not in dark.
The cap should be rewritten as **mobile ≤ 6 where the chrome cuts content at the bottom, at 375pt, or
at AX3**, not retired.

## One correction the scorers between them got wrong, which is worth your attention

Two of the three filed *"the tab bar is five stock SF Symbols on every screen."* **It is not.**
`MainTabView.swift:812–817` builds `CSTabBand` from the product's own drawn family — `.home`,
`.pennant`, `.play`, `.people`, `.card` — and there is no `systemName` anywhere in that file.
**But an experienced reviewer looked straight at it and called it stock, twice.** The drawn chrome
glyphs are drawn *in SF Symbols' idiom* — same optical weight, same metaphors, same rounded terminals
— so the one proprietary object that appears on 21 of 23 screens does not read as proprietary. That
is a real brand finding and it is cheaper to fix than anything else on this list.

---

# 3 · THE ROAD TO 10, GROUPED BY KIND

Two pieces of arithmetic have to be separated before this list makes sense, because they answer
different questions.

- **The mean** is an average over 23 screens. Almost every fix touches a handful of cells, so almost
  every fix moves the mean by a few hundredths. The mean is dominated by *how many surfaces are still
  unopened*, not by how good the good ones are.
- **A 10** is a ceiling question. §29's 10 is *"would sit beside the best consumer sports apps with no
  apology"* — which is a claim about every surface, not about an average. A dimension reaches 10 when
  **no screen in the product embarrasses it.**

So: the four unopened surfaces are the only thing that moves the mean much, and they are not what
gets you to 10. What gets you to 10 is further down and costs more.

Ordered by **points per unit of work**, cheapest first. Costs are engineering days for one person who
knows this codebase; mean deltas are modelled by re-scoring the affected cells and are estimates.

### Rank 1 · Paint the league look — **product decision, then ~2 days**
*Unlocks: B on 6 surfaces, E on Compete. Mean +0.03. Answers a question you asked out loud.*

`leagues.look` is live and constrained to a token key. `league_looks()` and `set_league_look()` are
granted. Eleven looks ship in `tokens.json` with light and dark accents. The **phone reads it in
seven files** — `SeasonPage`, `HomeView`, `CompeteScreen`, `MainTabView`, `SeasonStoryPane`,
`SeasonRulesPage`, `CrewStep` — `CompeteScreen.swift:122` already sets
`.environment(\.csLook, look(row))` **per row**. And **nothing draws with any of it**, because no
league in the product has a look set, because no wizard step asks. `index.html` has zero hits for
either RPC.

That is why `dark-compete.png` renders two leagues identically on the exact surface you called bland.
**The decision is yours and it is one line: is a league a colour?** If yes, it is ~40 lines on the
desk, ~2 days including one optional six-swatch wizard step, no migration. This is the cheapest point
on the board and it is ninety per cent built.

### Rank 2 · Flip the section-head default — **engineering, ~1.5 days**
*Unlocks: C on 9 surfaces, H on 4. Mean +0.06.*

83 call sites, 4 spend the display weight. Finish the sweep D286 started and flip `.label` out of the
default position so the next new surface cannot get it wrong. This is the single largest consistency
move available and it is mechanical.

### Rank 3 · The chrome singletons — **engineering, ~2 days**
*Unlocks: C across the product, P on 4 flagships. Mean +0.08.*

One caret (`.tint(cs.ember)` at the app root kills the iOS system blue in the composer's gross field
and the sign-in field — the only non-token colour in the product). One minus glyph. One wordmark
(the door's serif title-case *Cup Season* against every signed-in screen's condensed caps
**CUP SEASON** — two wordmarks for one brand, on the first screen anyone sees). One top-right chrome
instead of four. Zero emoji: LINT-12 from 59 to 0, which is a ruling to reverse, not a bug to fix.
Then put each of them in preflight the way the palette already is, so the count cannot climb back.

### Rank 4 · Redraw the five tab glyphs in the ball-marker hand — **design, ~2 days**
*Unlocks: B on 21 of 23 screens. Mean +0.05, and it is the highest-leverage single drawing in the
product.*

The glyphs are already the product's own. They are drawn to look like Apple's. Redraw them at the
twelve ball markers' stroke weight and the one object on every screen starts reading as yours.
§4's test — *remove the logo, is it still Cup Season* — is currently answered by the content, and
this makes the chrome answer it too.

### Rank 5 · The type growth policy — **engineering, ~3 days including a re-shoot**
*Unlocks: T on 8 surfaces, H on 4. Mean +0.07. And it closes a test that lies.*

`Type.swift:130–139` at HEAD: `figureXL/figureL` 1.5 · `figureM` 1.45 · `display` 1.6 · `displayS`
1.8 · `agate` 2.2 · **`default: nil`** — which is `name`, `nameS` and `body`, uncapped. So at AX3
the section head grows to 1.8× and the row title beneath it grows without limit. `ax3-compete.png`
is the proof: **`YOUR SEASONS` and `WHO'S THE BITCH?` render at the same size, and the row title is
arguably the larger of the two.** The 1.6× step this entire owner-feedback wave was built on does not
merely collapse at accessibility sizes — **it inverts, at exactly the size where a reader most needs
it.** `SystemTests` asserts the step at the default size only: a test that passes while the thing it
guards fails. Cap `name`/`nameS`, and move the assertion to AX1/AX3/AX5.

### Rank 6 · The 375pt and AX3 geometry pass — **engineering, ~4 days**
*Unlocks: M, which has not moved in thirteen waves. Mean +0.06. Contains one shipping blocker.*

Keyboard avoidance with a scroll-to-focus that guarantees the primary action clears the keyboard —
the sign-in door on an SE is not a polish item, it is a screen a new golfer cannot complete. A scroll
bottom-inset that reserves the band's height on every pinned footer. A growth budget for the tab
band's five labels so they stop shearing at AX3 (`HOME`'s H is clipped at x=0 on all eight AX3 shots,
and the band renders two different type sizes). And `UI_SYSTEM` §16.3's credential-at-AX3 instruction
either implemented or reversed — at AX3 the object carrying the most brand in the product dissolves
into an unbounded page and stops being an object.

### Rank 7 · Open the four unopened surfaces — **design + engineering, ~3 weeks**
*Unlocks: everything, on four screens. **Mean +0.32 — five times the next largest single move.***

**The bag, the composer, the board and the schedule.** They score 4.0, 4.4, 4.5 and 4.6 and they are
the only four screens still below the Phase-1 *product* mean. They fail for one shared reason: each
takes something a golfer cares about and renders it as a record in a box. Fourteen clubs chosen over
years are twenty-eight identical filled wells with half the values truncated and a floating `…` with
no affordance — §32 rendered in the negative, on the surface that should be pure personality. The
composer is the product's primary write path and the least designed screen in it.

Add the plan sheet (5.7) and the wizard (5.4) and the mean move is +0.45. **This is the whole
difference between a product mean of 6.2 and one of 6.8, and it buys no ceiling at all** — it lifts a
floor. Which is exactly why it is ranked seventh on points-per-unit and first on mean.

### Rank 8 · Three payload changes — **server data, ~5 days including the client halves**
*Unlocks: D on 5 surfaces, E on 3, C on 1, B on Home. Mean +0.06. Unblocks the one screen you actually
photograph.*

No new design is needed for any of these — the drawing already exists, is unit-tested, refuses to
draw when there is no real card, and renders today on the course page and on a planned round.

1. **`home_stories` gains `api_course_id` and `live_round_id`.** Verified at HEAD: the function
   returns `course text` — a *label* — so no round in the feed can draw anything, and five slats are
   five identical rows of face-name-phrase-number. It is a `drop function` + recreate plus its grant,
   because adding a column to a `returns table` function is a 42P13. **This is the single biggest
   unblock left, and it is the difference between "think Strava" being answered everywhere and being
   answered everywhere except where you were looking.** Strava's feed item is a map *because the route
   is the activity*; Cup Season's exact equivalent is `csDrawnCardSvg` and it cannot reach the feed
   because the feed does not know which course it is looking at.
2. **`photo_path` on `friends_board()` and on the standings row.** One golfer, one face, everywhere.
3. **`standing` on `tour_card`.** Today a buddy's card loses its entire league block.

### Rank 9 · The light theme designed rather than inverted — **design, ~5 days**
*Unlocks: R and P. Mean +0.05. None of it was visible before today.*

Three objects lose their job in light because the theme is a token inversion rather than a second
design: the drawn card's bars are dark green on a near-black plate and its star rail is pale grey on
cream (`light-course.png`, both below reading contrast at the size shipped); the bone ledger becomes a
white panel on a cream page separated only by a hairline (`light-record.png`); the band's scrim fades
a section head to disabled (`light-home.png`). **Every object specified twice, not every token
inverted once.** The Athletic and Apple Sports both ship a light theme in which no object is a weaker
version of itself; this ships three that are.

### Rank 10 · Motion and haptics — **engineering, ~8 days**
*Unlocks: E, which is the lowest dimension. Mean +0.03 on this table — and see §4, because most of
what it unlocks is on surfaces this table cannot photograph.*

Six of seven moments. The vocabulary is already proved: `CSTally` is in `CSDesign`, `RankFlipText`'s
split-flap survives, the ceremony's takeover is built, and every rest frame is already the finished
state, which is the accessibility floor. What is missing: the score submission's tally-and-seal, the
rank-flip slots, the leaderboard's staggered wipe, the challenge-accepted band, the tape's
per-meeting wipe, the reaction scale, the dateline crossfade — one haptic each.

### Rank 11 · Home's floor — **a ruling only you can take, then ~1 day**
*Unlocks: H on Home. Mean +0.01, and it is the thing you complained about, moved 400pt down the page.*

`ADD MY ROUND` · `START SOMETHING` · `JOIN WITH A CODE` · `FIND GOLFERS` — one size, one weight, one
colour, four rules, **no primary among them**, sitting under a 15pt grey wire. So the loudest block
on the bottom half of the front page is a navigation menu. `BRIEF` §18 names this by hand (*avoid
five equally prominent buttons*) and §8 wants a tier.

**It is a ruling and not a defect**, which is why nobody has fixed it: L-25 puts all four doors on
every Home, and the collapse to one `SOMETHING ELSE` row fires only when the page carries its own
ember primary — which a live lead does not set. **The decision: does a page whose lead is already lit
show one door and a `Something else`, or four?** Answer it and the design is a tier — one primary,
one secondary, the rest one line — applied to Home's floor, the composer's footer, the board's row
and the bag. Strava's feed simply ends; the actions live in the chrome, never at the bottom of the
content.

### Rank 12 · Content — **§4 said this cannot be bought. §6 shows four sources of it already in the repo.**

---

# 4 · WHAT A 10 REQUIRES THAT NO AMOUNT OF DESIGN WORK CAN BUY

This is the part of the answer you should read twice.

**Three dimensions have a hard ceiling that is not a design problem, an engineering problem or a
server problem. It is that no real golfer has put anything into the product yet.**

### Emotional appeal — ceiling ~6.5 without content, 5.22 today

E's observed ceiling in this build is **8, reached exactly once**, on the tour card, **because a
photograph owns it.** That is not an interpretation; it is the only variable that separates that row
from every other row.

- **No photograph of a golf course exists anywhere in the product**, across five course renders and
  two design passes. The code path is real, unit-tested, and refuses an uncredited image. The
  signed-in account has no round photo at any of its seven kept courses, so every capture of the
  course page renders rung 2 of the imagery ladder. Three blind reviewers failed that page in Phase 2
  and all three gave the same reason in different words. It scores E 4 today. **It cannot pass 6
  until a golfer takes a picture at a golf course.**
- **No season on any device is `complete`**, so the ceremony — the product's single biggest emotional
  moment, and a P0 in the Phase-1 audit — has never been rendered on real data by anyone. It is
  proved by `CeremonyFixture` and by nothing else.
- **`native_home` returns an empty `events` array** for the only account anybody can photograph, so
  the event room is not in this table at all. Every event shot in this overhaul is a fixture.
- **The account's buddies have no record**, so head-to-head is scored on its empty state.
- **The flagship season board is a fixture.** The signed-in account plays a two-golfer free league in
  which the cut, the pot, the split and the squad table are all correctly absent. Every eight-row
  shot in this overhaul is `-cs_dev_season_fixture`: invented golfers on invented ids.

Motion closes part of this gap and photography closes the rest, and **neither substitutes for the
other**. Build all six missing moments and E on this table reaches perhaps 6.0. Add a real course
photograph and a real round photograph and it reaches perhaps 7.5. **E reaches 8+ only when the feed
is full of other people's golf** — which is a product-adoption fact, not a design fact.

### Premium feel — ceiling ~7.5 without photography, 6.00 today

Same mechanism, one step removed. The one surface in the product that reads as expensive reads that
way because it has a photograph on it. Everything else premium asks for — flat ground, no cards, one
accent, figures set as objects, two scarce metals — **is already done**, and it produces 8s, not 9s,
on surfaces with nothing photographic on them. The four unopened surfaces are worth about a point of
premium mean; a real course photograph is worth the rest.

### Information density — ceiling ~7 without real leagues, 6.22 today

Compete answers four facts on a whole screen because the payload carries four facts, and the payload
carries four facts because there is nothing else true about a two-man league in its sixth week.
`tour_card` has no `standing` for anyone but you. A league row has no course or best columns.
`SeasonStory.Arc` carries no numeric field, so the story's figure panels have never rendered.
`head_to_head` returns `last_five` as `{on, won, facet}` — no course, no figures — so the callout's
four-column leaf is not built, because three of its four columns would have to be fabricated.
**Every one of these degrades honestly today rather than inventing a fact, which is right.** Three of
them are payload fixes (§3, rank 8). The rest need golfers to have played each other.

### And one more, which is not about content at all

**Mobile usability cannot honestly pass 6 until somebody puts a finger on it.** There is no tap or
gesture tooling on this Mac. **Every shot in every wave of this overhaul — all 42 in this set
included — is a rest frame.** Nobody has pressed a chip, scored a hole, armed a destructive, swiped
a sheet closed, or tested the edge-swipe back on the two pages that hide their navigation bar. No
consumer sports app ships without that. An M score above 6 is not fully earned until it happens, and
it needs a person and an afternoon, not a build.

## So: what is the honest ceiling without content?

| dimension | today | ceiling with **all** the design + engineering + server work in §3 | what the last stretch needs |
|---|--:|--:|---|
| R readability | 7.43 | **9** | nothing outside §3 |
| T typography | 6.83 | **9** | nothing outside §3 |
| H hierarchy | 6.65 | **8.5** | your ruling on Home's floor |
| C consistency | 5.74 | **8.5** | nothing outside §3; it is the cheapest number on the board |
| B brand | 6.61 | **8.5** | a look on a league; one wordmark; the tab glyphs redrawn |
| M mobile | 5.83 | **8** | a thumb on a device |
| Sp spacing | 5.91 | **8** | a spacing token, and one ruling on where a rule stops |
| P premium | 6.00 | **7.5** | **a photograph** |
| D density | 6.22 | **7** | **real leagues with real fields** |
| E emotion | 5.22 | **6.5** | **course photographs, round photographs, a finished season** |

**A product mean of roughly 8.0 is reachable by work alone. A 10 is not.** Four of the ten dimensions
are capped by what is in the database, and the two the brief cares about most in §1 — emotion and
premium — are two of the four. That is not a failure of the overhaul; it is the overhaul finishing
and the product not having been used yet.

---

# 5 · THE HONEST FLOOR

## What I would fix first tomorrow, in this order

**1 · The sign-in door on a 375pt phone.** Not because it scores badly — because a golfer with an SE
or a phone in the large-text setting cannot get into the product. It is one keyboard-avoidance
modifier and a scroll inset. Half a day. This is the only item on this entire list that is a bug
rather than a score.

**2 · The type growth cap.** The section step you asked for inverts at AX3. Everything else in §3
rank 2–4 is cosmetic next to a hierarchy that reverses itself for a reader who needs it most.

**3 · The section-head default, the chrome singletons and the tab glyphs, as one sweep.** Four days
together, and they touch every screen. Do them as one commit family so the re-shoot is one re-shoot.

**4 · Your two rulings**, which cost you five minutes each and block work worth more than they cost:
- *Is a league a colour?* — unblocks rank 1.
- *Does a Home whose lead is already lit show one door, or four?* — unblocks rank 11.

## The realistic mean after each of the next three moves

Modelled by re-scoring the affected cells, not by assertion.

| after | product mean | screens below 6 | screens at 8+ |
|---|--:|--:|--:|
| **today** | **6.24** | 8 | 0 |
| **move 1** — the whole engineering sweep: type cap, section head, chrome singletons, tab glyphs, truncation, the 375pt/AX3/keyboard pass | **6.43** | 7 | 0 |
| **move 2** — the four unopened surfaces opened (bag, composer, board, schedule) | **6.75** | 3 | 0 |
| **move 3** — the payload's three changes, and the look painted | **6.82** | 3 | 1 |

**Read that table honestly.** Three moves, something on the order of six to eight weeks of work, and
the product mean goes from 6.2 to 6.8. Not one screen except the tour card reaches the brief's bar of
8, and three screens are still below 6. **That is what §29's scale being read literally costs.**

The reason is arithmetic, not pessimism: with 23 screens and 10 dimensions, a fix that adds a point
to five cells moves the mean by two hundredths. **The mean is a floor measurement.** What those three
moves actually buy is that the product stops contradicting itself — one section head, one caret, one
wordmark, one minus, one door grammar, one tab family, a type scale that survives its own
accessibility sizes, and no screen a golfer cannot complete on the phone he owns.

**And after all three, the ceiling is exactly where §4 says it is.** Emotion 5.22 will be about 5.7.
Premium 6.00 will be about 6.6. Those two numbers move when somebody photographs a golf course and
somebody finishes a season — and the design that will render both of those is already built, tested,
and refusing to draw until the data arrives.

## The one-paragraph answer to your question

**A 10 needs four things, and only two of them are work.** It needs the engineering sweep — the type
cap, the section head, the singletons, the 375pt geometry — which is about two weeks and moves five
dimensions. It needs the four surfaces nobody has opened yet redesigned, which is about three weeks
and is the only thing that moves the mean. It needs two rulings from you that cost five minutes and
unblock a week of work each. **And then it needs golfers** — a photograph of a course, a photograph
of a round, a season that finishes, a league with a field bigger than two. Without those last four,
the honest ceiling is a product mean around **8.0** with emotion at **6.5** and premium at **7.5**,
which under §29 reads: *finished, and still not a 10.* With them, and with the motion work,
**10 is reachable, and nothing in the design stands in its way.** The product is no longer waiting on
its design. It is waiting on being used.

---

# 6 · THE PLAN TO 9.5 — attack the ceiling, not the score

*Added 2026-09-07 on the owner's instruction: "Action plan to get to 9.5. Let's think outside the
box." §4 above says four dimensions are capped by content that "cannot be bought." Three independent
readings of the repo — the category playbook, the iOS platform, the product loop — found that claim
wrong in four specific places. Real content already exists and is being thrown away. Every item below
was verified against HEAD `a679ae7`; a move that assumed data the product does not have was cut.*

## The premise, corrected

Strava never asked users to fill the feed: it drew a sensor they already carried. Letterboxd pulled the
image from a public database. Whoop drew the user's own numbers back at him. Cup Season has all three
available today and uses none of them:

| the source | what exists at HEAD | what throws it away |
|---|---|---|
| **the round's own holes** | `round_holes` for every live and scanned round; `round_holes_of()` in the generated client; `CSDrawnCard` built and unit-tested | the renderer is used on the course page and nowhere else — a round is never drawn |
| **the course's real geometry** | OpenStreetMap carries surveyed `golf=hole / green / fairway / bunker` for most courses, free and keyless | the plate behind every course title is **seeded noise** — FNV-1a over the course id (`Contour.swift:27–56`); `BUILD_REPORT.md:179` already convicts it |
| **a finished moment, weekly** | `settle_week_clash` runs on every rollover and writes `winner_member`, `a_best`, `b_best` | the client decodes them and never reads them; `winner_member` is used in one test. `clash_verdict` is a declared push kind with a payload contract and **no producer** |
| **the weather it actually was** | `supabase/functions/weather` built, deployed, Open-Meteo, free | dead: 0 of 93 courses have coordinates, so it returns `no_location` every time |

And one **live defect** found on the way: `PostRoundModel.swift:207` makes the scanned card the round's
photograph, and `CoursePage.hero` picks the latest round photograph as a course's hero. **Every scanned
round currently makes a photo of a piece of paper the hero image of a golf course.** Raising scan
volume without fixing this makes the course pages worse.

## The plan, in six phases

Each phase ships on its own. Costs are working days. Lifts are per-dimension estimates from the three
readings, reconciled; they are the *ceiling* moving, which §4 said could not happen.

### A · Supply content from what already exists — ~3 weeks. This is the outside-the-box part.

| # | move | days | what it lifts | why it is honest |
|---|---|--:|---|---|
| A1 | **Draw the round.** Point `CSDrawnCard` at `round_holes`: the golfer's strokes over the course's bars, gaps left as gaps. **Retroactive** — every round already posted gets a picture the day it ships, on the receipt, the row, the recap. Ship the scan-is-not-a-course-photo fix with it | 3 | D +1.0 · E +0.6 · P +0.4 | every stroke is one the golfer entered; the renderer already refuses to invent a par |
| A2 | **Geocode the 93 courses server-side**, once, from the address already in `api_courses.raw`. The write path exists (`functions/courses/index.ts:102`); the upstream just returns null | 1 | unlocks A3, A5 | it is the course's address |
| A3 | **The course from the map database.** Pull OSM golf geometry once per course, store it, draw it as the plate. Attribute it in the agate credit slot rung 1 already reserves. Replaces the noise field on **all 93 courses and every future one with zero user behaviour** | 6 | E +1.2 · P +1.0 · D +0.7 · B +0.5 — the biggest absolute lift on the board | surveyed by humans; it is the real place |
| A4 | **The week's verdict as a ceremony.** Render `winner_member` and the two bests with the ceremony chassis that already exists, seen-once, with a door onto the winning round. Write the `clash_verdict` push producer. Fires 13–26 times a season instead of once at the end, never | 2.5 | E +0.8 · D +0.4 | a row the server wrote from posted rounds; a loss drawn with the same dignity as a win; both-idle stays silent |
| A5 | **The weather it was.** With A2 done, add Open-Meteo's archive endpoint so every round already posted gets its conditions | 2 | D +0.5 · E +0.4 | a fact about a date and a place |

### B · Put faces and photographs where the loop is warm — ~1.5 weeks

| # | move | days | lifts | note |
|---|---|--:|---|---|
| B1 | **The finish frame.** The 18th green is the one moment 2–4 golfers stand together, finished, phones out; live scoring already puts a sheet there. One frame: *"one for the card."* Camera picker, compression, upload, bucket and RLS are all built | 3 | E +0.8 · P +0.5 | **the only move that produces faces at scale**; consumes the attach-later RPC being built now |
| B2 | **The face at the card gate, with the camera.** Onboarding asks for a name, a handle, a marker and a band — and never a face. That is why one golfer in the product has one | 1 | B, E on every list row | marker stays the floor; no silhouette state |
| B3 | **Scan as the default way to post.** It is live, capped, confirmed cell by cell, and yields hole data and a photograph in one act — and it is a small pill under `Details`. Invert it: the composer opens on the card, typed entry is the second door | 1.5 | D, and it feeds A1 | genuinely faster than typing eighteen numbers; needs no bribe |
| B4 | **The epilogue asks the one thing only today's golfer can answer** — a photograph, at the warmest moment in the funnel | 1.5 | E, P | one ask, once, never a nag (L-22) |
| B5 | **The camera roll already played this round.** PhotoKit: every photo has a date; a golfer who played Papago on Aug 24 has pictures from that afternoon. Offer them, retroactively, on any round | 4 | E, P | his own photos, his own choice, one permission |

### C · The engineering sweep — ~2 weeks. Already costed in §3; the floor.
Type growth cap · section-head default · chrome singletons · tab glyphs in the marker hand · 375pt and
AX3 geometry · truncation policy · a spacing token. Lifts consistency, spacing, mobile, hierarchy and
typography to their §4 ceilings of 8–9.

### D · The premium signals the category has — ~1.5 weeks
D1 the widget draws A1's round or A3's course instead of eight strings (2 days, on A1) · D2 the finish
and the ceremony get a body: `CSMotion` and the haptic vocabulary exist and neither screen calls them
(3 days) · D3 the live round reaches the lock screen by push (6 days — the Live Activity exists; the
push side does not; defer if the budget is tight).

### E · Two rulings only you can take — five minutes each
Is a league a colour? (spend the `look` nothing uses.) Does a lit Home show one door or four?

### F · Open the four unopened surfaces — ~3 weeks
Bag, composer, board, schedule. §3 says this is the only phase that moves the *mean*, because the
mean is a floor measurement over 23 screens.

## The honest projection

| after | product mean | E | P | D | note |
|---|--:|--:|--:|--:|---|
| today | 6.24 | 5.2 | 6.0 | 6.2 | |
| A | ~7.0 | 7.4 | 7.5 | 7.8 | the ceiling moves; nothing here waits on adoption |
| A + B | ~7.4 | 8.2 | 8.0 | 8.0 | faces and photographs arrive at the rate rounds are played |
| A + B + C + E | ~8.2 | | | | the §4 ceiling, reached |
| + D + F | **~8.8** | | | | every screen at or above 8 |

**9.5 is the last stretch above that, and it is a different kind of work**: not more features but the
9→10 on each dimension — the light theme designed rather than inverted, motion on every moment that
changes state, a spacing rhythm a designer would not touch, and the product used by a real field so
that the ceremonies, the faces and the courses render on data rather than fixtures. Phases A–F are
roughly eleven weeks of engineering. They get the product to a place where a 9.5 is a matter of
finish rather than of missing content — which today it is not.

## What to do first

**A1 and the scan fix, this week.** Three days, retroactive over every round in the database, and it
turns the feed row the owner photographed from text into a picture without a single server change to
`home_stories`. Then A2 + A4 together (the geocode is a day and the verdict is the product's biggest
emotional moment finally firing). Then A3.
