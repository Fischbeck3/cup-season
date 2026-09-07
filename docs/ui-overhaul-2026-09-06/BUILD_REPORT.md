# The UI overhaul — the build report

**Date** 2026-09-07 · **Design commit** `b3abedc` · **Build tip** `865bd58` · **Nineteen commits**
(thirteen waves, six repair) · **249 files, +29,834 / −9,844** · this report is a twentieth commit
and changes no code

**Nothing in this build was pushed and nothing was deployed.** `git rev-list --count
origin/main..HEAD` = **21** — the design commit, all nineteen build commits and this report sit on
this machine.
The two migrations this overhaul wrote are **written and unrun**; the latest applied migration in
production is still `20261006093000`. No edge function was touched. The owner stays at both wheels.

This is the one document to read instead of the session. It is written against
`docs/ux-overhaul-2026-09-04/OVERHAUL_REPORT.md`, which it follows section for section.

**Evidence policy** (`docs/ux-overhaul-2026-09-04/EVIDENCE_POLICY.md`) still outranks everything.
Cup Season has not launched; no production count of behaviour appears anywhere below. Every claim
rests on a screenshot, a line of code, a preflight check or an arithmetic measurement — and where a
claim rests on a **fixture** rather than on a golfer, this report says so in the same sentence.

---

## 1 · WHAT THE PRODUCT LOOKED LIKE

*From `UI_AUDIT.md` §1, condensed.*

Cup Season was a tidy, legible, well-engineered application that looked like a well-made dark
template: a stack of near-identical rounded rectangles held together by a hairline you could barely
see, with the card fill sitting **1.084:1** above the page and the border doing the actual work at
**1.443:1** — the full visual cost of over-carding for almost no depth in return. Golf numbers, the
one thing the product exists to show, were set as captions almost everywhere: **38 sites typed a
score into a sentence**, the live running total rendered at 11pt grey and broke mid-word on a small
phone, and a golfer's finishing position for an entire season was 11pt tracked caps under a generic
flag glyph. There was **no photograph and no human face anywhere in the product except one
credential** — the people tab rendered six golfers with zero faces, the live tee sheet identified
four golfers with a 4pt colour bar, and the course sheet was a 2×2 grid of bordered KPI tiles under
a cache disclaimer. Five glyph vocabularies ran at once (SF Symbols, ~35 colour emoji, Unicode
dingbats in Plex Mono, typed text arrows and the fourteen drawn markers), the shipped app icon was
Xcode's blue placeholder, and **310 sites of 11–12pt tracked mono caps** stood in for a display tier
that existed for exactly one thing. And the emotional hierarchy was inverted: a once-per-device door
animation was the most crafted motion in the app while winning a season was a settings-shaped sheet
with a drag pill and a circled X, and on Home **ceremony night and a brand-new empty account rendered
as the same card with a different eyebrow word**.

**Product mean 5.10 across 25 surfaces. Two reached 6. None reached 8. Twenty-three of twenty-five
carried the verdict "redesign".** Readability averaged 6.36 and was the only dimension above 6;
emotional appeal averaged 4.00 and premium feel 4.12.

---

## 2 · WHAT IT LOOKS LIKE NOW

Thirteen wave commits, then six repair commits. Every one ships its decision entries in the same
commit as the code it governs, each carrying the dated `**Authorised by the owner's "build it"**,
2026-09-06` line. **Twenty product entries (D265–D284)** are in `spec/decision-log.md` and
**nineteen phone entries (IOS-044 … IOS-060**, with `IOS-047a/b` and `IOS-049a/b`) in
`docs/ios/DECISIONS.md`.

| | wave | commit | files | what is now true |
|---|---|---|--:|---|
| **0a** | the ground | `325bb1b` | 94 | 80 tokens in 14 groups; the emitter gains Space/Alpha/Track (a group added to `tokens.json` used to reach the web for free and the phone never); IBM Plex Sans Condensed bundled as the board face; the app icon ships in three appearances; `-cs_dev_appearance` and `-cs_dev_text_size`, which are what make a light and an AX3 screenshot possible for the first time in this product's life; the lint baseline ratchet. |
| **0b** | the vocabulary | `1bd7eb1` | 36 | `CSDesign` rewritten: nine type roles, three containers, the rank rail, the rule-and-figure, the drawn glyph family, `CSFace`, the credential, the leaf, the board, the four button tiers, the five states with a **non-optional** empty-state door. |
| **1** | HOME / FEED | `bf434ae` | 21 | The masthead is a wordmark over a 2pt rule; the lead is one serif sentence with one door; the deck is **deleted** — ranked items 2–5 enter the wire at their earned weight; the ME strip is figures on one shared rule and a slot with no figure is **absent**; the floor is four 44pt verb rows; the tab bar is a band on the page's own ground. |
| **2** | the player card | `3905347` | 23 | One credential object at 362 × 312, measure-relative, used by the peek, the person page and the You tab — four files deleted. The marker floor is a **marching-squares contour** seeded identically in Swift and in the browser, checked against each other by preflight 46. |
| **3** | the profile | `b67a160` | 37 | The You root is an identity page (the object is the header); the record is a printed almanac on a bone leaf; eight emoji trophies become eight **drawn** marks; the head-to-head is a graphic with the every-meeting tape. |
| **4** | the course | `19b5f67` | 21 | Full-bleed plate under the status bar, the imagery ladder (photo → drawn card → contour), the facts as one line of type, the rating as **content** in ink, the front nine on a leaf. Writes `20261007090000` and does not run it. |
| **5** | the season | `61f0bd2` | 20 | The board on `CSSlat` + the 44pt rank rail with three field states; **the cut rule**; the month clock; the pot as a printed ledger with the sign as a **word**; the story in three tiers. |
| **6** | the event | `3fa64d8` | 32 | The title card on the pinned ceremony ground; **the two-group side roster** — the best thing in the build; the score rail whose metal is the state; the callout gets its own room. Writes `20261008090000` and does not run it. |
| **7** | leaderboards | `fe5b074` | 35 | The movement clock named once per table and the triangle drawn by the renderer, never by a producer (D276); competition rank with shared ties; the live sheet rebuilt from the status band down; the receipt on a leaf. |
| **8** | propagate | `f139e48` | 93 | The ceremony **takeover** with its wipe, stagger, tally and seal; twelve chip families → one; ten drawn glyphs replace the SF Symbols beside them; one dismiss verb; every toast carries a kind; every face keyed to a golfer (LINT-31 → 0). |
| **9** | the lint | `8a291e4` | 59 | All twenty-nine §17 checks run, and **preflight 49 fails the push if the table and the codebase disagree about which**. The retired vocabulary is deleted (`CSCard`/`CSStat`/`CSButton`/`CSEmptyState` → 0). The atmosphere washes are gone. |
| **10** | responsive + a11y | `0d2d155` | 30 | `csPage` measures, clamps and logs the shear; the slat's columns derive from the measure; the credential is measure-relative for the first time; Reduce Transparency resolves composited; the desk gets a keyboard model. |
| **11** | the desk | `35b2dd2` | 5 | 236px sidebar on `bg0` with the mark, the wordmark and the viewer's face; the body fills 1440 exactly (236 + 40 + 744 + 40 + 340 + 40); the clash and the pot move to the second column; the board gains `RDS` and a five-dot `LAST FIVE`. |

### The repair pass

Three adversarial reviewers — **design fidelity** (the shots beside the artboards), **correctness**
(the code) and **the laws** (`CLAUDE.md`, the canon, the terminology, the owner's rulings) — filed
**51 findings** against the tip of Wave 11. Six commits answered them.

| | commit | what is now true |
|---|---|---|
| **P0** | `bd20e23` | **The Golfers board ranked on the server's beats-order while printing the average**, so the 44pt rail read `01 −2.6 · 02 +1.0 · 03 +2.8 · 04 −3.8` — a ranked list sorted on neither direction of the one number it shows. Each lens now sorts on the figure it prints and the rail carries the **position**, not a server column. Both clients. Also: the cut counts `ClimbMath.cut(meta).K` rather than a hard two, and says it in words. |
| **P0** | `060598a` | **The gold `FOUNDER` slot printed through `JER` of `JERECHO`** at the default reading size on the default device, on the tab a golfer opens to look at themselves. `CSCredential` reserves the head band, measures the copy band in the real face, and drops the name to `displayS` when it wraps. A card with **no** photograph now draws its own edge, so it is an object in dark. |
| **P0** | `8924359` | **Four lints reported "zero, and held there" over things that ship.** `LINT-04` grepped `Color(red:` in a codebase that writes `Color(hex:` — eight literals shipped, five of them the palette D270 deleted, painting the **finish ceremony**. `LINT-11` watched button bodies while gold sat on a warning, a legend key, a tee time and an SF Symbol trophy. `LINT-23` checked the words and not the form, so the ledger line shipped in three type roles and the ceremony printed it twice. And `spec/brand-canon.md` §4 still named Fairway and Charter eight commits after D268 and D270 replaced them, with no CONFLICT line in either entry. |
| **P1** | `36fcef9` | **The product shipped two back buttons** — iOS 26 wraps a toolbar item in a glass capsule and no artboard draws one; the page draws its own chevron now. **In light theme the status-bar clock was invisible on two flagship pages**; every page paints its own ground under it. The drawn card takes `ground.rule`'s sage instead of reading as a bar chart. The tab band keeps its five words at the accessibility sizes. |
| **P1** | `38e74a6` | **The phone could not delete a round at all** — Wave 3 removed the × and the receipt never got the replacement, so for four waves the desk had a capability the phone did not. Two steps, owner-gated, with the consequence spelled out. The receipt ends in a figure. **The Forge stopped catching fire**: three of its four heat stops mapped to one ember when the heat tokens were deleted, so a named must-survive asset drew three identical tracers. |
| **P1** | `865bd58` | The live sheet's match block is the artboard's **two lines** rather than four, which is ~120pt back on the one screen a golfer reads standing on a tee with one thumb; `SI` became `HCP` on the live hole head. |

---

## 3 · THE BEFORE AND AFTER, SURFACE BY SURFACE

Scored on the ten dimensions of `UI_SCORECARD.md` — H · T · Sp · C · B · P · R · E · D · M — with the
same mechanical verdict rule (`mean ≥ 8 keep · 6.0–7.9 polish · < 6.0 redesign`).

**Read the built column carefully.** It is the design-fidelity review's own scoring, taken from the
dark, light and AX3 captures **at `35b2dd2` — before the repair pass**. The six repair commits closed
a number of the things it penalised, and the repair pass photographed the results (`r1`–`r6` in the
shot set), but **nobody re-scored the ten dimensions afterwards**. So the built column is a floor,
not a claim, and the "what the repair closed" column says which cells have moved without saying how
far.

| surface | Phase-1 | design target | **built** | verdict | what the repair pass closed since |
|---|--:|--:|--:|---|---|
| **home** | 5.1 | 7.9 | **6.8** | polish | the wire's duplicated moment; the floor's asymmetric rules |
| **player-card** | 6.4 | 8.2 | **7.1** | polish | the slot printing through the name; the truncated figure rule; the crest card's figure-ground; the stray ember dot on a name |
| **profile** | 5.8 | 7.8 | **7.1** | polish | content scrolling under the clock; the establishing clause on your own card |
| **course** | 4.4 | 6.9 | **5.7** | **redesign** | the drawn card's colour; the light-theme clock; the back chevron |
| **season** | 4.7 | 7.8 | **7.3** | polish | the cut's K and its rule at AX3; ~28pt of fold; the back chevron; the AX3 gutter (re-shot clean) |
| **event** | 4.2 | 7.3 | **7.0** | polish | the dateline restored above the roster; the face's colourway on a pinned plate |
| **leaderboard** | 4.8 | 7.5 | **6.9** | polish | the board's sort (P0); the receipt's total; the live sheet's fold; the tab band's AX3 labels |
| **the seven** | **5.06** | **7.63** | **6.84** | | |

**+1.78 delivered of the +2.57 designed — 69%.** Six surfaces move from *redesign* to *polish*.
**No surface reaches 8**, which is `BRIEF` §29's bar. One — `course` — is still below 6.

### Per dimension

| | E | P | B | H | T | D | C | Sp | M | R |
|---|---|---|---|---|---|---|---|---|---|---|
| baseline | 4.14 | 4.14 | 5.29 | 4.86 | 5.14 | 5.00 | 4.71 | 5.43 | 5.57 | 6.29 |
| target | 8.14 | 8.00 | 8.43 | 7.71 | 8.71 | 6.86 | 6.43 | 7.14 | 7.43 | 7.43 |
| **built** | **6.57** | **7.14** | **8.14** | **7.00** | **8.14** | **6.29** | **5.71** | **5.86** | **6.00** | **7.57** |
| built − target | **−1.57** | −0.86 | −0.29 | −0.71 | −0.57 | −0.57 | −0.72 | **−1.28** | **−1.43** | **+0.14** |

**Brand identity (8.14) and typography (8.14) arrived essentially intact.** The rank rail, the
rule-and-figure, the board face, the bone leaf and the drawn marks do what the design promised;
nothing in the whole review asks for a system change. The three shortfalls have three different
causes and only one of them is design work.

### Where the build did not reach the target, and why

**HOME · 5.1 → 6.8, target 7.9.** The structure landed: the masthead is a byte-for-byte match, the
deck is gone, the ME strip drops empty slots rather than printing a dash. **The five weights are one
weight on every photograph anybody can take.** Weight 3 has *no producer at all* — `home_dispatch`
emits no `course` kind — and weights 2 and 4 need a round photograph and a completed season, neither
of which exists on the signed-in account. So `w1-bottom.png` is eleven quiet lines where
`home-feed-weights.png` is five different objects, and Home's emotional argument (`E` 5 against a
target of 8) is a data gap rather than a design one. The `-cs_dev_home_state` hatch cannot help: it
clears the wire by design, because a fixture that invented a feed would be inventing golfers.

**PLAYER CARD · 6.4 → 7.1, target 8.2.** The only surface whose target was `keep`, and it lost the
whole gap on two dimensions: `Sp` 5 (the gold slot printing through the name, the figure rule
stopping 55pt short of the card edge) and `M` 6 (at AX3 the object dissolves into a page — plate,
then name, then one figure per row, no bounded card, no folio). **Both `Sp` drivers were repaired**;
the AX3 dissolve is `UI_SYSTEM` §16.3's own instruction and was not.

**PROFILE · 5.8 → 7.1, target 7.8.** The closest of the seven on hierarchy (`H` 8 = target) and it
loses on `Sp` and `M`: content scrolled under the status bar with nothing behind it and landed on
the form row's grosses (repaired), a doubled divider under `COURSES KEPT`, and two of the eight drawn
trophy marks — `PERSONAL BEST` and `4-WEEK STREAK` — that are distinct from every other mark but are
not yet good drawings.

**COURSE · 4.4 → 5.7, target 6.9. The one surface that did not clear 6, and it fails for the same
reason it failed in Phase 1.** `course-page.png`'s entire argument is a photograph of a golf course.
The code path is real, unit-tested and refuses an uncredited image — and the signed-in account has no
round photo at any of its seven kept courses, so **every capture of this surface renders rung 2 of the
imagery ladder**. `page.others` is empty for the same reason, so the friends row, the sentence that
names them and the rating figure all render nothing, and **the design's own signature — the
rule-and-figure — appears zero times on this page**. `E` scored **3** against a target of 7. The
repair pass fixed the two things that were actually build defects (the drawn card read as a grey bar
chart, the light-theme clock was invisible); it could not fix the absence of a photograph, and
fabricating one was not on the table.

**SEASON · 4.7 → 7.3, target 7.8. The smallest gap and the best-executed object in the build.** Put
`w5-fixture-table-dark.png` beside `season-top.png` and the difference is data, not design — the gold
earned rail, a face in every row, the merged gap-and-movement cell, competition ranks, the cut rule.
What it lost was the fold: one table row survived above it where the artboard shows four, behind a
navigation bar the artboards do not have and two clash rows occupying ~300pt. The repair pass bought
back ~28pt of that and no more. **And the flagship board is a fixture**: the signed-in account plays
a two-golfer free league, in which the cut, the pot, the split and the squad table are all correctly
absent, so every eight-row shot in this overhaul is `-cs_dev_season_fixture` — invented golfers on
invented ids, DEBUG-only, never written to the server.

**EVENT · 4.2 → 7.3, target 7.3 on hierarchy and the only `+1` cell in the whole review.** §15.5a's
two-group side roster **beats its own artboard**: the blind review's "can you tell who is on which
team?" failed 2/3 on the render and answers yes in under a second on the build. The gap is elsewhere
— the contour behind the title reads as noise rather than as a place, the clash rows are ~40% taller
than the design, and `BEST CARD EACH WEEK` now collides with the credential's new name. **Nothing in
this surface was photographed on real data**: `native_home` returns an empty `events` array for the
signed-in account, so every event shot is `-cs_dev_event_fixture`.

**LEADERBOARD · 4.8 → 6.9, target 7.5.** Held down by `H` 6 and `C` 5, both driven by the **P0 the
repair pass fixed**: a ranked board sorted in an order that contradicted the column beside it. The
rest is consistency — two back chromes on one product, the rank rail bleeding to x=0 on one board and
inset 20pt on another, an ASCII hyphen in one producer and a true minus in another on the same screen.

### What the review named as must-not-lose, and which all survive

The cut rule · the month clock · shared competition ranks · the every-meeting tape · the copy (not one
string in the whole review needs a tone rewrite) — and a sixth the build earned on its own, **the
two-group side roster**.

---

## 4 · WHAT WAS DELIBERATELY NOT BUILT

### 4.1 The two migrations — written, and not run

Both are client-adjacent and both are yours to push. `node tools/deploy-status.mjs` reports them.

- **`20261007090000_what_your_golfers_think_of_a_course.sql`** (Wave 4) — `course_ratings` with a
  unique pair and a half-star arithmetic constraint, RLS on with **no** policies and **no** table
  grant, plus `course_rating(text)`, `rate_course(text, numeric)` and `unrate_course(text)`, each
  security-definer with its own explicit `grant execute … to authenticated` and never to `anon`
  (D37), and a read-only self-check that RAISES if any of the three is ungranted or if the table is
  readable off the API. Until it runs, the course page's rating block renders the unrated rail and
  the sheet says so **before** the golfer commits: *"Ratings are not switched on yet, so this one
  cannot be saved. Everything else on the page is real."*
- **`20261008090000_an_event_knows_its_course.sql`** (Wave 6) — `events.course_id` and
  `events.course_label` with select grants, so an event's title card can draw the contour of the
  course it is played at. **This one is groundwork with no writer, and Wave 6's report said
  otherwise.** `create_event` is not changed by the file and carries no course argument, so after
  `supabase db push` the column will be null for every event that will ever exist and the title card
  will still degrade to the bare ceremony ground. The read side is safe under deploy skew — the
  repository selects `*` and the model decodes `String?`. Closing it needs `create_event` to gain
  `p_course_id` and the setup control to pass it; that is a second migration nobody wrote.

### 4.2 Server data the design needs and the payload does not carry

Every one of these is a place where a surface **degrades exactly as its spec's DEGRADE clause says**
rather than inventing a fact. None was resolved on the client.

| what the design draws | what the payload carries | where it shows |
|---|---|---|
| the position figure on **somebody else's** card | `tour_card` has no `standing`; `me.memberships[].standing` is the viewer's own | the third figure and the **whole league block** are absent on a buddy's card; `profile-light.png`'s gold `01` rail cannot render |
| Home's weight-3 **course** row | `home_dispatch` emits no `course` kind, and there are no ratings tables | the row type is built and never renders; Home runs on four weights |
| the course page's **pull quote** | needs the `posts.body` attached to a round played here, with author and date — a selection nobody wrote | the surface's one serif never renders on a real course |
| **per-hole yardage** on the drawn card | `api_course_holes.yardage` exists; `my_course_books` does not select it | every drawn card in the product draws height **by par** — 11 of 18 bars identical |
| a course row's **city** and **best** | `tour_card.courses[]` is `{name, rounds, last_played}` | two of the mockup's four columns have no producer |
| the story moment's **figure panel** | `SeasonStory.Arc` carries no numeric field | `season-story.png`'s two `79 GROSS` panels are unphotographed |
| the tape at **every meeting** | `head_to_head` returns `last_five` as `{on, won, facet}` — no course, no figures | the callout's four-column leaf is not built; three of its four columns would be fabricated |
| the desk board's **BEST** column | `v_rounds_ranked` carries a differential and no gross | the column is absent rather than filled with a figure the head does not name |
| `photo_path` on `friends_board()` and on a standings row | neither payload carries a photo field | a golfer with a photograph still cannot show it on a board |
| the folio's **serial** | the product owns no card number | the folio's right slot is empty; a serial derived from a UUID is fake data as ornament |

**And the standing RPC push-debt is unchanged and untouched by this overhaul** —
`post_round`, `my_course_books`, `bag_of`, `save_bag`, `home_dispatch`, `match_contacts`,
`friends_board`, `head_to_head`, `run_it_back`, `season_story`, `leave_season`, `call_out`,
`redeem_share`. Wave 4 added three more hand-declared around `Generated/Rpc.swift`
(`course_rating`, `rate_course`, `unrate_course`, disclosed in the file), taking the list to
**sixteen**. `friends_board` being on it is why the Golfers board reads a hand-declared row shape;
`head_to_head` being on it is why the profile still runs on `my_rivalries` as its declared fallback.

### 4.3 The web half that remains

D234 / owner ruling R-C says every change has a phone half and a web half. **Waves 0a, 0b, 2, 3, 7
and 11 shipped a complete web half for their scope.** What remains:

- **The desk's composition on five surfaces.** Wave 11 built the frame (the 236px sidebar, the
  1440-exact body, the season head, the re-columned clash and pot, the board's `RDS` and five-dot
  form column). It did **not** re-column the profile, the composer, the wizard, the onboarding or the
  door. Waves 1, 3, 5 and 7 each named the two-column body as owed and each ran out before it.
- **Home's weights 2, 3 and 4 on the desk**, and the ME strip turned vertical in the right column.
  Home's web half shipped the lead block and the wire line and deleted the deck; it did not build the
  photograph at 2.1:1, the course row or the takeover band.
- **The desk has no callout room.** It renders a two-golfer event through the Ryder branch, which is
  the exact defect Wave 6 closed on the phone.
- **The four icon systems are not collapsed on the desk.** `index.html` still carries ~126 typed `→`,
  33 `✓`, 27 `⛳` and ~35 UI emoji inside template strings, and the drawn family has no `csGlyph()`
  producer on the web. Wave 8 did the chips, the four canvas artifacts and the two clients'
  agreement; Wave 9's brief put the glyph sweep after this overhaul's own targets.
- **The print stylesheets** — the board, the pot ledger, the settlement card and the credential's 3:4
  front-and-back — named as owed by Waves 2, 3, 5, 7 and 11. `@media print` collapses the two columns
  and nothing more.
- **Two retired-vocabulary residues survive in `index.html`,** named by the laws review and not fixed:
  `.ob-ember` at `:2658` paints a fixed 42vh radial gradient behind the signed-out door in a raw hue
  that is not a token (R-C §C-4 exempts the door from this overhaul's scope; the literal is not
  exempt), and `.leadcard` at `:2946–2958` is dead CSS still carrying the exact card grammar D265/D266
  deleted, left in the file by the commit titled *"the old vocabulary is gone"*.
- **Nobody drove the desk in a browser in most waves.** Wave 11 did — served on 8791, service worker
  unregistered, zero console errors across four viewport/theme passes — but it could only see the
  signed-out door and the demo diorama, because **there is no OTP in this session**. Waves 2, 3, 4, 5,
  6, 7, 8 and 9 all verified their web halves by parsing every script block, by producer assertions
  run headlessly in Node, and by the token single-source checks — and every one of them recorded that
  nobody had looked at it. **Somebody should open `?exit`, clear the service worker, sign in, and
  drive the season page, the credential, the course page and the event room before this ships.**

### 4.4 Motion

`UI_SYSTEM` §11.3 names seven moments. **One is built**: the ceremony's takeover — the plate wiping
from the leading edge, the display lines at a 60ms stagger, the figure tallying over 340ms, the
medallion sealing last with one haptic — plus `CSTally`, which is in `CSDesign` for the rest of them.
`RankFlipText`'s split-flap and its replay gate survive from before the overhaul, and the Forge's
heat ramp is repaired. **Everything else is unbuilt**: the 220ms arrival wipes, the rank-flip slots,
the leaderboard's staggered wipe, the score submission's tally-and-seal, the challenge-accepted band,
the tape's per-meeting wipe, the reaction scale, the dateline crossfade. Every rest frame is the
finished state, which is the accessibility floor — so nothing is broken, and nothing arrives.

### 4.5 The five render-time budget probes, in CI

Wave 9 found that **the probe mechanism had been broken for nine waves and nothing could say so**:
`CSBudgetTick` used `View.preference(key:value:)`, which sets the value for the modified view and
**discards the subtree's**, so every container that counted itself erased the budget of everything it
held. It is `transformPreference` now, and `BudgetProbeTests` asserts each of the five budgets in both
directions on objects a test can construct. **Home, the season page and the event room still only
print under DEBUG**, because asserting a real root needs a fixture-driven preview harness nobody
built. And the counting rule itself is unsettled — see §5.

### 4.6 The review findings that were not repaired

Twelve of the fifty-one were left, all P2, each named here rather than closed quietly.

- **`MajorMath.cardsLine` was replaced by view code the spec said not to touch.** The producer is now
  referenced only by its own tests.
- **`reportPhoto` lost its only call site.** The function is live in `TourCard.swift:465`; nothing on
  either client calls it. P-17's report path for a photograph is gone from the phone.
- **Home's collapsed floor names three routes and opens one.**
- **The AX3 capture hatch still misses sheet presentations.** `csSheet`/`csCover` are referenced 34 times across
  `apps/ios` against **60** `.sheet(` call sites in the app target alone — so some earlier waves' AX3 shots of sheet-based surfaces
  are at the reading size and nothing in the shot says so. Wave 8 said this was closed; it is not.
- **One page, two meanings for the section head's count slot.** `w5-fixture-table-dark.png` reads
  `EIGHT IN THE FIELD` and `w9-season-dark.png` reads `MOVED SINCE SUN`; the slot holds one, so the
  field size is now said nowhere on the season page.
- **The metal budgets are breached on three flagship viewports** and nothing in CI can say so — see
  §5, question 1.
- **The three hand-declared course RPCs** — disclosed in the file, honest at the point of failure, and
  still a hand-declaration around the compiler-enforced grant list.
- **The two `index.html` residues** in §4.3.
- **Two trophy marks are weak drawings** (`PERSONAL BEST` reads as a stray glyph, `4-WEEK STREAK` as
  a progress bar), and **the `rack` and `bag` empty-state glyphs** are weaker than the scorecard and
  the schedule sheet.
- **`PostHoleGrid`'s 2px and 1px dashed ember cell rings** — the one place in the product where ember
  outlines a control. Migrated in chrome only, because sweeping it means redesigning the grid's
  selection language.
- **`LINT-06` (363 phone spacing literals) and `LINT-14` (146 pre-uppercased producer strings)** hold
  at their baselines. Forty of the tracking sites are a mono-to-condensed **face** change on surfaces
  no wave of this overhaul designed — draft night, the composer's hole grid, the widgets — and
  restyling screens nobody can photograph, in a sweep wave, is how a regression ships unattributed.

### 4.7 Surfaces this overhaul never designed

**Draft night** (`DraftBits`, 17 shapes) and **the round slices** (`SliceComponents`, 9) took the
mechanical sweep — the roles, the chip shape, no borders — and not a layout pass. The **widgets** are
a separate target with their own canvas and were not touched. The **landscape scorecard**, which is
the highest-scoring surface in the whole Phase-1 audit at **6.8** and the product's actual ceiling, is
in neither `BRIEF` §30's Phase-3 order nor the 25-row table, and was not re-scored.

### 4.8 What could not be photographed at all

Named plainly, because six of the seven flagship artboards are unmatchable for want of data rather
than for want of code.

- **The ceremony.** No season on any device is `complete`. The takeover, the two finishers, the
  trophy engraving and the settlement card are proved by `CeremonyFixture` and by nothing else.
- **The live recap and its in-app settlement card at export geometry.** Reaching them needs a live
  round *finished* on the device and there is no finish hatch. **A finish hatch is the cheapest thing
  the next session could add.**
- **A course photograph** (rung 1 of the imagery ladder) — the state three blind reviewers failed the
  course page over.
- **Home's weight 2 and weight 4.**
- **The event room on real data** — `native_home` returns an empty `events` array.
- **A real head-to-head** — the account's buddies have no record, so the tape and the clash are shot
  on `-cs_dev_h2h_fixture` and `-cs_dev_cred clash`.
- **The signed-in web desk** — no OTP in this session.
- **Anything under a finger.** There is no tap or gesture tooling on this Mac. Every shot in every
  wave is a rest frame: nobody has pressed a chip, scored a hole, armed a destructive, swiped a sheet
  closed, or tested the edge-swipe back on the two pages that hide their navigation bar.

---

## 5 · THE OPEN QUESTIONS ONLY YOU CAN ANSWER

Ten. Each is a place where two normative statements in your own documents disagree, or where the
answer is a brand or a money decision that is not a builder's to take. Each says what the build
currently does, so nothing is blocked on you — but each will be re-argued by the next reviewer if you
do not settle it.

1. **How is a metal counted?** `UI_SYSTEM` §1.5 counts "every fill, rule, glyph, dot and word";
   §2's own tally on the event room counts **fills**. Both are in the same document, and by the first
   reading three flagship viewports breach the two-mark budget: the live Home (the dot, the ember
   eyebrow, the ember underline, the ⊕ glyph, the `PLAY` label), the ceremony (three gold objects) and
   your own person page (the `FOUNDER` slot, the medallion, and the form row's gold best gross). The
   probe counts honestly and prints the breach under DEBUG. **One line in §1.5 settles it**, and it
   should be settled before the Phase-7 blind review scores those screens.
2. **Does a card with nothing earned wear a gold ring?** `UI_SYSTEM` §6.5 row 3 and the build brief's
   own acceptance line say *the crest **or** the corner medallion, never both*. §6.2a's revision and
   §19(i) put both on, and `player-card-marker.png` draws both. The build follows the later ruling, so
   a golfer who has earned nothing still carries one gold ring — `player-card-marker`'s "no gold
   anywhere on the card" is, in the build, "no gold **field** anywhere on the card". **It is one
   boolean in `CSCredential.head`**, and `theCredentialHoldsItsOwnBudget` flips with it.
3. **What is the identity line's third clause?** All five artboards render
   `@GALENM · MESA, AZ · EST. JUL 2026`. §6.5 row 5 — which the build brief names as the object's
   single anatomy of record — and `player-card.md` §1 both say handle, city, **home course**, and that
   `EST.` is out (YRS-21), because the founding fact is already the gold slot. The build says
   `@JERECHO · PHOENIX, AZ · LOOKOUT MOUNTAIN GOL…`. A reviewer comparing pixel to pixel will see a
   different third clause.
4. **Is the wordmark re-cut?** `brand/README.md` generates the two lockups and the og-image, and
   Wave 0b's `CSMasthead` cut it in Plex Mono 600 at 0.32em to match. `home.md` §1.1 and all five
   artboards set it in the **board face**, and the build follows the artboards at `display` 34. **The
   generated lockups are untouched**, so Home and every email and link preview now set the wordmark
   differently. Re-cutting a wordmark is a brand decision the canon reserves to you.
5. **Where does the ledger sentence print?** `spec/brand-canon.md` §3 says verbatim **everywhere**
   money appears, from one constant per client. D273 narrowed that to **once per client** with no
   CONFLICT line — and then asserted two deletions that had never happened. The repair pass ruled that
   **the canon governs**, corrected D273 in place, deleted the false sentence, collapsed the
   ceremony's two printings to one at the foot, normalised all four standalone printings to `agateS`,
   and rewrote `LINT-23` to check the **form** rather than a literal. So the sentence
   prints at **seven** render sites on the phone — four standalone in `agateS` (the pot, the ceremony's
   foot, the record and the wizard's fine print) and three inside longer prose (the join flow and the
   two pricing cards) — and at nine constant reads on the desk, all from one constant per client. **If
   you want D273's rule instead of the canon's, that is six deletions on the phone, six on the desk and
   a canon amendment.** (`PotPane.swift:18`'s own comment still says "ONCE per client" and is now
   stale.)
6. **Two serif blocks on one Home viewport.** §1.4 says one serif object per viewport; `home-quiet`
   and `home-light` both ship a `lead` headline in the lead block **and** a second in the wire's empty.
   `home.md` §10 names it as an unresolved system conflict and says the refuters should rule. The
   build matched the artboards and shipped two. Options: drop the empty's headline to `story` 20, or
   restate §1.4's budget as one serif **object** per viewport.
7. **Is the head-to-head facet leaf on the page or behind a door?** `profile-h2h.png` draws it inline
   under the tape. `profile.md` §10 says the opposite in its own words — *the hero, the tape and a leaf
   whose three rows sum to 6–5 is the same fact three ways in one screen* — and the build followed the
   spec. It is one `showFacets` boolean. This is the single place where the shot and the artboard
   differ by a whole band.
8. **Should `tour_card` carry `standing`?** It is a one-key additive migration, and it is what makes
   the position figure and the whole league block render on **somebody else's** card rather than only
   on your own. Until then, `THIS SEASON` — declared, read and never once assigned since before this
   overhaul — is absent on every card but yours, and `profile-light.png`'s gold `01` rail cannot be
   photographed at all.
9. **Does `20261008090000` ship as groundwork or with its writer?** As written it adds two columns
   nothing will ever fill (§4.1). Push it as groundwork and say so, or hold it until `create_event`
   gains `p_course_id` and the setup control passes it. **The event title card's contour is the thing
   that hangs on the answer.**
10. **Is a circle a boxed surface?** `LINT-10` counts `border-radius:50%` beside a `background` as a
    boxed container, which means it counts the system's own **discs** — the face, the live dot, the
    tape's meeting mark — against a check written to kill the card. Wave 11 folded two new marks into
    existing rules partly to keep the number from rising, and said so. The check needs a ruling, not
    a workaround.

**And one that is not a design question.** `spec/brand-canon.md` §4 was materially false for eight
commits — still headed LIVE, still naming Fairway as the brand, Charter as the serif, three radii and
one easing — after D268 and D270 replaced all of it with no CONFLICT line in either entry. The repair
pass amended the canon to what ships and gave both entries the line they owed it. **Read that hunk**:
a level-5 entry silently narrowing a level-5 document is the failure mode this overhaul produced
twice, and it produced it in the two places nobody greps.

---

## 6 · THE COMMANDS TO SHIP IT, IN ORDER

Run from `/Users/fischbeck3/cup-season`. Three layers, three separate deploys.

**Nothing below has been run. This build pushed nothing and deployed nothing** — not `git push`, not
`supabase db push`, not `supabase functions deploy`. `node tools/deploy-status.mjs` at this tip
reports `X OWED DATABASE` (two migrations), `clean EDGE FUNCTIONS` (6 deployed, none stale) and
`X OWED CLIENT` (21 commits not pushed to `origin/main` — the design commit, all nineteen build
commits and this report).

```bash
# 0 · where prod actually is (read-only, no Docker needed)
supabase db query --linked \
  "select version from supabase_migrations.schema_migrations order by version desc limit 1"
#    expect 20261006093000 — 2 migrations pending

# 1 · the gate, before anything ships
node tools/build-tokens.mjs      # expect: four "same" lines and a clean tree
node tests/preflight.mjs         # expect: PASS — 0 failure(s), 0 warning(s)
node tests/sunningdale.test.mjs  # expect: PASS — 27 assertions

# 2 · THE DATABASE. You type the word `push`; a human stays at this wheel.
supabase db push                 # 2 migrations: 20261007090000, 20261008090000
#    20261007090000 switches course ratings on.
#    20261008090000 adds two columns NOTHING WRITES YET — see §4.1 before you run it.

# 3 · prove the grants and the seal held
supabase db query --linked --file tests/db-checks.sql
#    20261007090000 also carries its own self-check, which RAISES if any of its three
#    functions is ungranted or if course_ratings is readable off the API.

# 4 · the contract, regenerated FROM the pushed database
node tools/build-db.mjs          # Rpc.swift — only granted functions get a Swift name
node tests/preflight.mjs         # checks 10/11 fail the push if this is stale
#    After this, delete the three hand-declared course RPCs in
#    CupSeasonKit/Courses/CoursePage.swift:341-365 — they exist only because the
#    migration was unpushed, and build-db will now generate them properly.

# 5 · the edge function behind the notification kinds
#    NOTHING IS OWED HERE. This overhaul touched no edge function; deploy-status
#    reports 6 deployed, none stale. Skip this step.

# 6 · the client
git push                         # Netlify auto-builds index.html
```

**Then, and only then:**

1. **Open the desk in a browser and drive it signed in.** `?exit`, clear the service worker, sign in,
   and look at the season page, the credential, the course page and the event room. No wave of this
   overhaul saw the signed-in desk (§4.3).
2. **Put a thumb on the phone.** Score a hole on the live sheet, press a chip, arm a destructive,
   swipe a sheet closed, and test the edge-swipe back on the course page and the event room — the two
   pages that hide their navigation bar and draw their own chevron. Every shot in this overhaul is a
   rest frame (§4.8).
3. **Add a finish hatch and photograph the recap.** The live recap and its in-app settlement card at
   export geometry are built, palette-checked by preflight 47, and have never been seen.
4. **Walk the ceremony.** No season on any device is `complete`. It is the largest hole in this
   build's evidence and it is the same hole the 2026-09-04 overhaul reported.
5. **Answer the ten questions in §5** before the Phase-7 blind re-score, or it will re-argue them.
6. **Re-score.** `BUILD_BRIEF` §8 asks for all 25 rows plus the second table's twelve sub-surfaces,
   shot in both themes at default and AX3 — which Wave 0a's two hatches now make possible for the
   first time. The seven surfaces above have a built score; the other eighteen do not.

**One diagnostic, for "is it live":** the desk's sidebar foot and `#obCaption` both read
`v23 · <sha>` — compare that SHA straight to `git log`.

---

## 7 · THE GATE, AS IT STANDS

Run at `865bd58` on a clean tree.

```
node tools/build-tokens.mjs      same × 4  (tokens.css · tokens.ts · Tokens.swift · Looks.swift)
node tests/preflight.mjs         PASS — 0 failure(s), 0 warning(s)
node tests/sunningdale.test.mjs  PASS — 27 assertions
xcodebuild test                  ** TEST SUCCEEDED **
                                   CupSeasonTests      50 tests /  11 suites
                                   CSDesignTests      116 tests /  30 suites
                                   CupSeasonKitTests  982 tests / 162 suites
                                   ────────────────────────────────────────
                                   1,148 tests / 203 suites
```

**The count did not fall.** The measured baseline at the design commit `b3abedc` was **929 tests in
156 suites** — not the 788 / 133 the task brief carried, which every wave from 0a onward reported as
stale and which is still stale. **No coverage was deleted anywhere in this overhaul.** Where a
component was retired its test was migrated (Wave 9 retired `CSCard`, `CSStat`, `CSEmptyState`,
`CSButton`, `CSHairline`, `CSGroupHead`, `CSTabStrip`, `CSHero`, `CSWash` and `CSDuskCard` and the
count rose); where an expectation changed the test was rewritten in place with the arithmetic or the
reason written into the file.

`node tests/preflight.mjs` now runs **all twenty-nine §17 checks** — 25 grepped, 6 carried by a test
— and **check 49 reads §17's own markdown rows and fails the push if any declared id has nothing
behind it, or if preflight runs an id §17 never declared**. **Fifteen of the twenty-four lint
baselines stand at zero and are zero-tolerance from here** — LINT-01 (no Charter), -04 (no colour
invented in Swift, after the repair pass widened it to `Color(hex:` and migrated the eight literals it
could not see), -11 (no gold on a control), -13 (no typed arrow in a produced string), -19, -20, -21,
-22, -23, -24, -25, -26, -29, -30 and -31. The remaining nine are debt written down:
LINT-03 41 · -05 102 · -06 1,219 · -07 208 · -09 29 · -10 264 · -12 61 · -14 146 · -27 2, each of
which the ratchet allows to fall and not to rise. **Two of them currently report a lower floor than
the file records** — `LINT-03` reads 40 of 41 and `LINT-12` reads 59 of 61, because the repair pass
lowered the counts and did not lower the baselines. Neither fails the gate; both should be written
down in the next commit that touches them, which is what the ratchet asks.

Two preflight checks were **edited in the commits they guard** and a reviewer should read both hunks:
check 25's mounts table (Wave 2 deleted the file it required, and it now asserts that
`presenter.tourCard` presents `PersonPage` — one P-17 mount instead of two that could drift), and the
version-placeholder count 3 → 4 (Wave 11's sidebar is a fourth `__CS_VERSION__` render site;
`stamp-version.sh` substitutes globally and nothing was hand-edited).

---

## 8 · THE OVERHAUL IN ONE PARAGRAPH

The old product was readable and unloved: a stack of near-identical boxes held together by a hairline
at 1.44:1, a golfer's whole season set as an 11pt caption under a generic flag, no face and no
photograph anywhere but one credential, five glyph vocabularies running at once, and Xcode's blue
placeholder on the home screen. The new one has a system it can be held to — a 44pt rank rail, a
figure on a rule in a face bought for the purpose, a bone leaf that prints like a ledger, six frozen
pigments so a person is drawn one way, two metals that are scarce by construction, and twenty-nine
lint checks with a preflight check on **top** of them that fails the push if the table and the
codebase ever disagree about which are running. Thirteen waves built it and three adversarial
reviewers took it apart: they found a ranked board sorted in an order that contradicted the column
beside it, a gold slot printing through the owner's own name at the default reading size, four lints
reporting "zero, and held there" over things that shipped, a brand canon that had been materially
false for eight commits, a phone that could no longer delete a round the desk could, and a door that
had stopped catching fire. **Six repair commits fixed all of it.** What is left is honest and it is
mostly not code: six of the seven flagship artboards cannot be matched on the only account anybody can
photograph, because the product has no round photographs, no completed season, no events and no
rivalries in it yet — the course page still scores 5.7 for exactly the reason it scored 4.4 in
Phase 1. **Mean 5.06 → 6.84 against a design target of 7.63. Six surfaces move from redesign to
polish; none reaches the brief's 8.** And what remains is one `supabase db push` you have to think
about before you type it, one `git push`, one browser session, and one thumb.
