# SURFACE SPEC — THE SEASON

**Surface** SEASON · *competition, narrative* · **the board** (`UI_SYSTEM` §15.4)
**Character** **story on top, board underneath.** No card appears anywhere on it.
**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 of 3 (design; nothing is built)
**Standard** `BRIEF.md` §13, §15, §16, §31, §33 · **System** `UI_SYSTEM.md`, obeyed; every departure is in §12
**Evidence** `UI_AUDIT.md` §2.5 (mean 4.7), §2.6 (4.8), §2.7 (pot, code-only), `UI_SCORECARD.md`
**Mockups** `mockups/season.html` → `mockups/renders/season/` — `season-top`, `season-table`, `season-squads`,
`season-story`, `season-money`, `season-light`, all 402 × 874 at 2× · the desk board is `mockups/web-desk.html` → `mockups/renders/desk/desk-season.png`, 1440 × 900

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · The one-line brief for the builder

> **The season is one scrolling page: a sentence, a clock, a matchup, a board, a pot.** The board is the
> hero and it begins inside the first viewport. Gold appears exactly twice — the leader's rail field and
> the pot — and they are the same fact. Ember appears twice — the live eyebrow's dot and the current
> week's tick. There is no card, no border, no capsule, no segmented control, no progress bar, no squad
> swatch, no column-head row and no second standings table.

---

## 1 · ANATOMY, top to bottom

Every measurement is a `space` token (`UI_SYSTEM` §4). Every type role is from §1.2. The page is one
`ScrollView`; the "viewports" below are what the five artboards show.

### 1.1 The head — `CSPageHeader` (season variant) · artboard `season-top`

| # | Element | Role · token | Spacing | Notes |
|---|---|---|---|---|
| 1 | back chevron | SF Symbol `chevron.left`, 17, `mut` | `gutter` left, 28pt row | the system back button; `navigationTitle("")` (LINT-24) |
| 2 | **the live eyebrow** | `agate` 12 in **`brand`**, preceded by a 7pt `brand` dot | `s1` between dot and text; `s2` under the chevron row | `"SEASON LIVE · WEEK 5 OF 13"`. The dot **is** the ember; the season's `look` may re-tint both (§2.7) |
| 3 | **the season's name** | `display` 34, UPPER | `s2` above | the surface's **one** `display` (LINT-16). The league's name, because that is what the crew calls it |
| 4 | the dateline | `agate` 12 in `mut` | `s2` above | `"SEASON ONE · MON AUG 3 – MON NOV 2 · THE PRO, GALEN"`. An **en dash**, never `→` (LINT-13) |
| 5 | **the chapter line** | `lead` — New York **Bold 28**, sentence case | `s3`+2 above | The surface's **one serif appearance** (§1.4). The audit's "best line on the phone", finally at lead size instead of body size (CS-08) |

### 1.2 The month clock — `CSSeasonCalendar` (new; the tick row, given months)

The tick row of §8, grouped by the calendar month that does the counting — so one object answers
"how far into the season", "which month am I in" and "how long have I got".

| Element | Role · token | Geometry |
|---|---|---|
| the ticks | one 20 × 8pt bar per season week | `s1` (4) between ticks, `s3`−2 (14) between month groups; `align-items: flex-end` |
| played | `mut` fill | |
| **now** | **`brand`** fill, **12pt tall** — the one live cell | grows upward from the shared baseline |
| ahead | `rule` fill | |
| the month label | `agateS` 11 in `mut`; the live month's label in **`brand`** with its days-left: `"SEP · 25 DAYS"` | `s2` under its group. **Part of the object — it does not count against the agate budget** |
| the counting sentence | `body` 15 in `mut`, sentence case | `s3`−1 above | `"Best four a month count — you have posted one."` |
| the door | tertiary link: `nameS` 15 in `ink` + a **2px `mut` rule** — in content, and it is not this screen's live action (§7.1). **No arrow glyph**: the rule is the affordance (§5.2) | `s2`+1 above; 44pt tap target | `"Add my round"` |

This replaces **`PressMeter`** — a 6pt three-stop `warm→hot→fire` capsule with no head, which the audit
read as a warning bar and §4 of the brief names as a generic sports gradient (CS-12). It is countable,
it is unmistakably a scorecard rather than a health bar, and it costs one token colour.

### 1.3 The clash — `CSClash` · the week's matchup

`CSSectionHead` (`agate` `"THIS WEEK · THE CLASH"` + 1px `rule` to the margin + `agateS` `"THROUGH SUN"`
flush right), then two rows on the page's own ground — **no card, no spine, no border**:

| Column | Role | Width |
|---|---|---|
| face | `CSFace` 38pt, pigment disc, 1px `rule` ring | 38 |
| name | `name` 17 caps | flex, tail-ellipsis |
| sub | `agateS` 11 in `mut` — the band and the day: `"A LITTLE LOOSE · FRI"` / `"NO ROUND YET"` | one line, ellipsis |
| the figure | **the side that is ahead takes a `panel`** 62 × 44 (`figure` 27 + `PTS` in `panelMut`); the other is a bare `figure` 27 in `mut`, or an em dash when idle | 62 |

The panel is the emphasis §13 asks for ("important matchups visually emphasised") and it costs one
object. Row spacing `s2`; the block sits at `gutter`. Each row taps to its round receipt when
`best.round_id` exists, and is inert (not greyed) when it does not.

### 1.4 The board — `CSSlat` × N · artboards `season-top`, `season-table`

`CSSectionHead` `"THE TABLE"` + rule + `agateS` `"SIX IN THE FIELD"` flush right. **No column-head
row** — the audit found the shipped heads sitting 140–200px left of the columns they name (CS-18), and
five self-evident columns do not need labels (§27 of the brief).

The slat, exactly as `UI_SYSTEM` §9.1, with this surface's widths at 402pt:

```
│ 01 │ ◍ GALEN MARR          │ ▬  │  —  │  19 │
│gold│   HELD FOUR WEEKS     │    │ gap │ pts │
  44  12  38/30    flex 160    30    34    48    20
```

| Column | Role | Token / width | Rule |
|---|---|---|---|
| **the rail** | `figure` 27, tabular, two digits, leading zero, centred | `rail` 44, full slat height | field `gold` when the position was **earned** (1st), `panel` when the row is **yours**, unpainted otherwise. Numerals `panelInk` on both painted states (9.43:1 / 15.87:1) |
| the face | `CSFace` — **30pt**, **38pt on the leader's row** | pigment keyed to the golfer's id | every row carries one. **The squad swatch is conditioned, not deleted** — CS-11 recorded *a squad swatch in a two-golfer SOLO season*, so the defect is a swatch where there are no squads. In a squads season it renders as a **4 × 14 `sq` bar and the squad's name in agate** at the head of the clause line (§9.1, §16.4). Never as a disc tint |
| the name | `name` 17 caps, **tail ellipsis**, `min-width: 0` | flex ≈ 160 | the one long-name policy product-wide. **The viewer's row reads `"YOU"` alone** (§9.1, `leaderboard.md` D-7): at the 375pt measure the fixed columns leave 141pt and `YOU · SAM RIDLEY` measures 143pt, so the SE would ellipsise the viewer's own row at the default text size |
| the clause | `agateS` 11 in `mut`, **sentence case** (§1.3), **one line, ellipsis**. In a squads season it is preceded by the **4 × 14 `sq` swatch and the squad's name in agate** (§9.1, §16.4) | same column | `SeasonStoryCopy.rowClause` / `StandingsStory` — `"Held four weeks"`, `"1 of 4 counting"`, `"4 rounds · cooled"`, `"1 of 4 counting · one short"`. **Never the word *floor*** (`TERMINOLOGY` §4 pattern 2; the schema's `participation_floor` never surfaces) |
| **movement** | `CSMovement` — a drawn triangle (9 × 7) in `pos` up / `cool` down + the numeral in `ink` at `figure` 20; a 9 × 2 `rule` bar for held | 30, right-flush | **on the page's own ground.** No chip, no fill, no tint. `▼` means *you fell* and nothing else |
| **the gap** | `column` 14 mono, tabular, right-flush: `+4` `+9` | 34 | **the leader's cell is EMPTY** — not `0`, and not an em dash either: an em dash reads as a value, which is the thing "empty" was protecting against. One cell, one answer, matching §9.1 and `leaderboard.md`. This column does not exist in the shipped product at all |
| **the points** | `figure` 27, tabular, right-flush; **`figure` 40 on the leader's row**; **`gold` ink only for the leader** | 48 | §16 of the brief: the number is the object |

**The leader's slat is the board's hero**: `minHeight` **74** against 52, a 38pt face, the clause
`"HELD FOUR WEEKS"`, and its total at `figure` 40. Rank, face, run and total, one beat taller and one
metal apart. That is §13's "the current leader should visually matter", answered without a card.

**The cut** (`cup_final` seasons with a field > 2, after row 2) — `CSCut`: `agateS` `"CUT · TOP TWO PLAY
THE CUP FINAL"` flush left, then a **2pt `ink` heavy rule** running to the margin, 26pt tall, `s2` above
and `s2`−2 below. **Never gold**: nothing here is won yet. This replaces the shipped gold "Cut line ·
top 2 advance" band, which spent the surface's metal on a thing nobody has earned.

**One standings object, not three.** `ClimbView` and `IndividualRaceView` are deleted from this page
(CS-21, P0: three tables for a field of two). The climb's *window* survives only as a behaviour — when
the field exceeds ten, the table renders the leader, the cut neighbours and you ±1 with `ClimbMath`'s
ellipsis rung between, and a tertiary link `"Every golfer"` opens the full board as a pushed screen.
The climb's own good ideas (the padded ellipsis, `RankFlipText`, the QB-12 "one great Saturday closes
it" clause) move into the table and the chapter line.

### 1.4a A SQUADS SEASON — the squad table first, then the individuals · artboard `season-squads`

`COMPONENT_SYSTEM` P-5's "Solo vs squads" note requires it and the first draft had no squads layer at
all — so in a season with four or more golfers the table could not say which side anyone was on. When
`league_settings.structure != 'solo'`:

| Block | Anatomy |
|---|---|
| **the squad table** | `CSSectionHead` `"THE SQUADS"` + rule + `agateS` `"TWO SIDES"` flush right. Then **N squad slats**, 56pt: the **rail** (`figure` 27, painted `gold` for the leading squad, `panel` for yours) · a **6 × 30 `sq` bar** · the squad's name in `name` 17 caps · an `agateS` sub-line in sentence case (*"4 golfers · 3 counting"*) · the movement mark · the gap column · the squad's points in `figure` 27 right-flush |
| **expansion** | tapping a squad slat expands it in place to its members as **indented individual slats** (rail unpainted, face 30, name, clause, points), on `roll` at 260ms. Collapsed by default except the viewer's own squad, which is expanded on first appearance |
| **the individual table** | unchanged, beneath, under its own `CSSectionHead` `"EVERY GOLFER"`. Each row's clause line leads with its **4 × 14 `sq` swatch and the squad's name in agate** (§9.1, §16.4) |
| **the solo case** | in a solo season **neither the squad table nor the swatch renders at all**, and the individual head stays `"THE TABLE"` — which is what CS-11 actually asked for. `TERMINOLOGY` L-43: a solo league never says *squad* |

**Colour never carries the squad alone.** The four squad marks are only **1.58:1** apart at best
(`UI_SYSTEM` §2.2a), so every swatch in this layer is followed by the squad's **name in agate**, and the
squad table's rows are ordered and ranked — the rail, not the hue, says who is winning.

### 1.5 What the board is running toward — `CSFigure` + two sentences · artboard `season-table`

Closing 1px `rule` under the last slat, then at `s4`:

| Element | Role | Notes |
|---|---|---|
| **the countdown** | `CSFigure.live` — `figure` 40 `"04"` over a **2pt `brand` rule** with `agateS` `"WEEKS TO THE CUP FINAL"` beneath | from `facts.final.in_weeks`. A clock that is running is ember (§2.6). Rule, not a fill |
| the endgame | `body` 15 in `mut`, one line: `"Top two after 13 weeks play a four-week Cup Final."` | `LeagueCopy.endgame`, verbatim — the audit calls its permanence "right" |
| the scenario | `agateS` 11 in `mut`: `"GALEN IS IN A CUP SEAT · SIX STILL LIVE"` | `ScenarioLine.parts` + `facts.final.still_live`. One agate line, not a 13–14pt mono console message (CS-20) |

A points-table season (`finish == "points"`) renders the same block with the season's own end date and
no cut rule: `"13 weeks. The points table crowns it."` — the countdown figure is `weeks_left`.

### 1.6 The pot — `CSFigure.earned` + `CSStakeLine` · artboards `season-table` (head), `season-money`

| Element | Role · token | Notes |
|---|---|---|
| section head | `agate` `"THE POT"` + rule + `agateS` `"SIX IN AT $60"` | |
| **the pot** | `CSFigure.earned` — `figure` **56** in **`gold`** over a **2pt `gold` rule**, `agateS` `"THE POT · SIX IN AT $60"` beneath | the surface's second and last gold object. `.contentTransition(.numericText())` on the roll is kept — the audit calls it one of the two best-typeset figures in the product |
| **the split** | three `figure` 27 in **`ink`** on one shared **2pt `ink` heavy rule**, three `agateS` labels beneath: `CUP CHAMP · RUNNER-UP · POINTS KING` | `PotMath.trioCents`. The shipped gold serif trio is re-inked: gold is the pot, once |
| **the ledger line** | `body` 15 in `mut`, verbatim from `MoneyCopy.ledger` / `CS_LEDGER` | LINT-23. It sits under every money figure on this surface |
| section head | `agate` `"WHO IS IN"` + rule + `agateS` `"FOUR OF SIX"` | |
| **the ledger, printed** | **`CSLeaf`** — `leaf` fill, radius `p` 3, `leaf-shade`; a grid and only a grid | see below |
| the collector | `body` 15 in `ink`: `"Galen collects for the season — pay him however you two already do."` | `SeasonFacts.owe`, which the audit found built and called from a test only (QB-04) |

**The leaf's grid** — column heads `agateS` in `leafMut` (`GOLFER · IN · AMOUNT`, the whole row = one
agate block), a hairline, then one 29pt row per member: a **24pt `CSFace`** with the marker in
`leafMut`, the name in `social` 15 (title case — a person in a row is not the board), **the sign as a
word** in `agateS` (`PAID` in `leafMut`, `YOU OWE` / `OWES` in `leafInk`), and the amount in `column` 14
right-flush. A closing hairline and a `COLLECTED · $240` total row. **No colour anywhere on the leaf**:
no `pos`, no `neg`, and no gold (gold ink on bone is 1.68:1, §2.4). This deletes the text `✓` at 50%
opacity, the handshake emoji in a stroked circle, the `✕` used as a button label and the paid/unpaid
state expressed as opacity — the whole of the audit's §2.7 "what feels cheap".

### 1.7 The foot — `CSDoor` × 3–4 · artboard `season-money`

`CSSectionHead` `"THE REST OF THE SEASON"`, then door rows: `social` 17 title, `agateS` sub in `mut`, a
drawn `chevron.right` at 13pt in `mut`, 52pt min height, separated by 1px `rule`. **The board · the
schedule · the album (only when the shell has one) · the rules.** No capsules, no icon circles, no
system disclosure indicator. The Pro's verb row (up to **seven** equally weighted capsules, one of them
red, under a gold eyebrow — CS-38) becomes **one secondary door, `"Season settings"`**, which pushes the
rules page where the Pro's controls already live.

### 1.8 The story — `SeasonStoryPane`, rebuilt · artboard `season-story`

A pushed screen. Opens with a **different object from the season page** (§15): the eyebrow, `display`
`"THE STORY"`, then **three figures on one 2pt `ink` rule** — `05` WEEKS PLAYED · `13` WEEKS IN ALL ·
`06` IN THE FIELD (`facts.week_no`, `weeks_total`, `field`).

Then the arc, **weighted in three tiers** — the audit's finding is that eight entries at one weight make
a milestone, a notice and a database row typographically identical (CS-29, P0):

| Tier | What it is | Setting |
|---|---|---|
| **the chapter** | one week | `agate` `"WEEK 5"` in `ink` + 1px `rule` + `agateS` date range in `mut`, flush right |
| **the lead** | the newest chapter's ladder sentence | `story` — New York Regular 20. **One per viewport**, and only in the newest chapter |
| **a moment** | a round, a first, a personal best | `body` 17 in `ink` + an `agateS` dateline in `mut`, with a **`panel`** 64 × 56 carrying the gross (`figure` 27 + `GROSS` in `panelMut`) |
| **a result** | a clash, a lead change | `body` 17 in `ink` + either an **overlapping face pair** (−10pt, each ringed in `bg0`) for a two-person result, or a `CSMovement` mark for a lead change; the figure or em dash right-flush |
| **a notice** | a month close, a first tee | `body` 15 in `mut`, sentence case, no mark. Quiet by construction |

**Numerals inside an arc sentence are figure runs** (§1.6) — but **the producer names the run**. A
regex over produced prose is not a rendering rule, it is a parser over copy the producers are free to
change: applied over `SeasonStoryCopy.arc`'s strings it would also restyle dates (*"Sep 6"*), money
(*"$60"*), ordinals (*"2nd"*), the *"82 → 74"* pair and any digit inside a course name, and it would
rewrite the `AttributedString` runs VoiceOver reads. **`CSFigureRun` takes a marked string** —
`"Galen shot {74} at Papago"` — **or an `[NSRange]` beside it.** The producers already build these
sentences; naming the number costs them one array. *(This is `UI_SYSTEM` §1.6's form, and it is the
one place this spec asked for a new field and should have.)*

**Panel budget: two per viewport** — the two grosses. **Agate budget: see §12, deviation D-2.**

---

## 2 · THE LIGHT PRINTING · artboard `season-light`

Not an inversion — a second printing (§2.3). Warm almanac stock `#F4F1E9`; the leader's rail field is
**bronze** `#7A5A12` with `panelInk` numerals at 5.64:1; the eyebrow and the live tick are **stamp red**
`#A8420F`; the clash panel and the viewer's rail **invert to ink** `#141A16`, which is the light theme's
whole idea; `pos` `#0B7340` and `cool` `#5D6862` carry the movement triangles; the leaf **does not
invert** — paper is paper in both rooms. Nothing else about the layout changes.

---

## 3 · EVERY STATE

| State | What renders |
|---|---|
| **Loading** | the destination's own geometry, redacted (§13.2): the head's three lines, the calendar's ticks, the section heads, and **six slats with their rails and rules present** and the type replaced by `bg2` blocks at radius `p` with real-length placeholder widths. **No spinner** — `ProgressView` is banned in content (LINT-22). The shipped `SeasonDateline(loading: true)`'s `"LOADING THE SEASON…"` string is deleted |
| **Empty — no rounds yet** | the head, the calendar and the clash render as usual; the table renders `CSEmpty`: a **drawn empty rail** at 64pt in `rule`, `agate` `"THE FIRST CARD"`, `lead` **"The season starts with the first posted round."** (a fact about the world, never the golfer's omission), `body` 15 in `mut` `"Six are in. Nobody has posted."`, and one **required** door — the primary `"Add my round"` (`TERMINOLOGY` A-5: one verb opens the composer). The pot renders whole (the money exists before the golf does) |
| **Empty — no clash** | pre-season, deploy skew, a field too small to pair, or a settled week where both sides were idle: the clash section **renders nothing at all**, head included. A door with nothing behind it is worse than no door |
| **Empty — free league** (`stake == 0`) | the pot section is **absent entirely** (L-10), not a `$0`. The foot's doors move up |
| **Error, with cache** | everything on screen **stays**, under an `agateS` dateline reading `"AS OF FRI 6:12 PM · OFFLINE"` in `mut`, with **no action disabled** (§13.3, generalising `HomeView.swift:181-184` and `:516-519`) |
| **Error, nothing cached** | one `lead` line in the product's voice, one `body` line, and **Try again** as the surface's primary. Server text verbatim when it is written for humans; never a raw code. The shipped `CSCard(spine: cs.neg)` wrapper is deleted — the error is type on the ground |
| **Long names** | one policy, product-wide: the name **truncates with a tail ellipsis** at the name column's edge (`min-width: 0`, `lineLimit(1)`). The clause line does the same. This replaces the shipped wrap / wrap / clip split across three standings surfaces |
| **No photo** | there is no photograph on this surface by design. Identity is the pigment disc and the drawn marker; a golfer who uploaded a photo shows it in the disc, subject-anchored; a golfer who chose nothing shows **initials** on the pigment. **No silhouette, ever** |
| **Complete season** | the eyebrow goes `gold` `"SEASON COMPLETE"`, the chapter line becomes the champion's sentence, the calendar's ticks are all `mut` (no ember — nothing is live), the leader's rail keeps its gold, and the primary is `"See how it ended"` → the ceremony. The countdown block is replaced by the archive's own row |
| **Setup / draft phase** | the head and the calendar render; `THIS WEEK` carries the checklist or the draft hero; the table renders its empty state; the Pro's one primary (`"The rules freeze at the first tee"` while the rules are still open, then `"Start the season"`) is the surface's one ember button — the only live season state in which this page owns a primary |
| **A cancellation vote is open** | one `body` 17 sentence and two tertiary links directly under the dateline, above the chapter line, on the ground. No `CSCard`, no `neg` spine |
| **Disabled** | `bg1` fill, `mut` label. A disabled primary is never ember |

### 3.1 AX3 reflow — stated as layouts (§16.3)

| Block | Default | AX1 | AX3 |
|---|---|---|---|
| the head | eyebrow · display · dateline · chapter line, stacked | as default | as default; `display` and `lead` take their growth caps (×1.6 / ×1.5) |
| **the month clock** | 3 month groups on one row | 2 rows of groups | **one group per row**, each a slat: month label leading, ticks trailing; the counting sentence follows |
| **the clash** | face · name/sub · figure | as default | the panel drops **below** the two rows and goes full width, its figure and `PTS` side by side |
| **the slat** | rail · face · name/clause · move · gap · pts | as default | the **rail keeps its 44pt width and grows its numeral**; move, gap and pts move under the clause as one `agate` line; `minHeight` becomes intrinsic. **One VoiceOver element throughout**: *"2nd. You, Sam Ridley. Up two. Four back. Fifteen points."* |
| the three-figures rule (story) | 3 cells on one rule | 2 + 1 | a stacked list, label leading, figure trailing |
| **the leaf** | 3 columns | 3 columns | **column heads hide**; each row speaks its own facts: *"Mike Fenner. Owes sixty dollars."* |
| the doors | title over sub | as default | as default; `minHeight` intrinsic |

Reflow is driven by the **measured advance** of the row's own characters at the size the golfer is
reading (the `MeStripLayout` model), not by a device breakpoint. `ViewThatFits` is 0 in the product
today and that is the gap.

---

## 4 · MOTION (§11)

| Moment | What happens |
|---|---|
| **the board arrives** | the table **wipes in top-down at a 40ms stagger** on `snap`, each slat's clip rect opening from the rail's edge, so the rank slot is on screen before the name and the name before the figure. 220ms per row |
| **a rank changed since last open** | that row's numeral **slots** (`RankFlipText`, kept verbatim — the audit calls it "a real ceremony") and its movement mark wipes in from the rail *after* the row settles. `.impact(.light)` **once, and only if your row moved** — the existing `iClimbed` guard, kept |
| **replay gate** | the flip plays on a **fresh data load only** (`freshStandings`, consumed on first render), so a re-render stays static. The climb never had this gate; the table does, and the table is now the only standings object |
| **the pot** | tallies on `snap` over 340ms when it changes (the existing `.numericText()` odometer on `roll`, retimed) |
| **the week tick** | the live cell grows 8 → 12pt on `snap` when the page first appears. Nothing else about the calendar moves |
| **the clash settles** | the winning side's figure wipes into the panel from the rail; `.impact(.medium)` once |
| **reduce motion** | `accessibilityReduceMotion` resolves both curves to `nil` — never "faster". Every rest frame is the finished state |
| **deleted** | every bare opacity transition on this surface; `CSMotion.settle` on the whole `ForEach` (replaced by the staggered wipe); the shimmer skeleton; the `csLookGround` accent wash |

---

## 5 · WHAT IT REPLACES — the SwiftUI files, named

*(paths relative to `apps/ios/`)*

| File | Fate |
|---|---|
| `CupSeason/Season/SeasonPage.swift` | **rebuilt.** `SeasonPage` keeps its `SeasonPane` routing, its `RoomRouter`, its `.task` loads and its `navigationDestination`s verbatim. `SeasonDateline` → `CSPageHeader` (season variant). `SeasonStoryLead` → the chapter line at `lead` 28 with a tertiary link (its `cs.dawn` link colour is deleted with the token). `SeasonEndgameFoot` moves into §1.5's block. `SeasonDoors` → `CSDoor` rows. `SeasonVoteBanner` loses its `CSCard(spine: cs.neg)`. The `.padding(.horizontal, 20)` on the whole `VStack` is removed — slats and bands are **full-bleed**; only `.wrap` content takes `gutter` |
| `CupSeason/Season/SeasonPhases.swift` | **`PressMeter` deleted** (§1.2 replaces it). `ClashCard` → `CSClash` (loses `CSCard`, the spine and the `w` gold letter). `NextCard` → the counting sentence + the tertiary link in §1.2 (loses `CSCard`, the spine and `RoomMini`). `PhaseHero`, `SeasonSetupChecklist`, `SeasonDraftHero`, `SeasonWrappedHero` re-clothed to bands and rules |
| `CupSeason/League/StandingsTableView.swift` | **rebuilt as `CSSlat` + `CSRankRail` + `CSMovement`.** `header(solo:)` **deleted** (CS-18). `moveChip` → `CSMovement`, no field. The squad `RoundedRectangle` swatch **deleted** (CS-11). `RankFlipText` kept verbatim. `StoryLine` folds into the chapter line. `ScenarioLineView` → one `agateS` line (§1.5) |
| `CupSeason/League/ClimbView.swift` | **deleted from this page.** `ClimbMath`'s window, ellipsis rung and QB-12 `closer` clause move into `CSSlat`'s data path and the chapter line |
| `CupSeason/League/IndividualRaceView.swift` | **deleted from this page** (CS-21). Its signed red/green float column dies with it (AP-2, DD-05) |
| `CupSeason/League/CupFinalRaceView.swift` | **kept, re-clothed** as slats with the same rail; it *replaces* the season table while its window is open, and the season table then prints beneath it under `"THE WEEKS BEFORE THE FINAL"`. Its 21pt finalist total becomes `figure` 40 |
| `CupSeason/League/PotPane.swift` | **rebuilt** as §1.6. The gold-spined `CSCard`, the serif trio, the `✓`/`✕` glyphs, the opacity-as-state and the handshake-emoji forfeit rows all go. `PotMath`, `SeasonFacts.owe`, `PotPassCard` and `PricingPotFinePrint` are consumed unchanged (the pass card and fine print move **below** the doors) |
| `CupSeason/Season/SeasonStoryPane.swift` | **rebuilt** as §1.8 |
| `CupSeason/Season/ProVerbRow.swift` | **deleted** (CS-38). One secondary door to the rules page |
| `CupSeason/League/RoomBits.swift` | `RoomMini` and `RoomFine` retired product-wide (`CSButtonStyle.secondary` and `body` 15 in `mut`); `PhaseHero` re-clothed |
| `CupSeason/Season/SeasonRulesPage.swift` | **out of this spec's scope** (audit: 6.3, "polish") — but its Charter-Bold-28-over-a-deck head is the thing this page was missing, and §1.1 promotes it |
| `CupSeason/League/SeasonCeremonyView.swift` | **out of scope**, and it is the P0 the audit scores 4.9. Flagged here so Phase 3 does not think this spec covered it |
| `CupSeason/Season/SeasonPreviews.swift` | **extended**: previews must cover loading, empty, error-cached, complete, free-league, AX3 and light. Two of those axes are currently unrenderable — see §11 |

---

## 6 · WHAT IT CONSUMES, UNCHANGED

Every fact on this surface is already produced. Nothing is invented, and nothing is computed that the
client cannot compute from rows it already holds.

| Fact on screen | Producer |
|---|---|
| the eyebrow, the week | `SeasonStoryCopy.dateline` + `LeagueCopy.stage` (`season_story.facts.week_no`, `weeks_total`) |
| the season's name, span, the Pro | `LeagueRoomModel.league`, `.clock.spanText`, `.proName` |
| **the chapter line** | `SeasonStoryCopy` — the seven-rung ladder, verbatim. `model.storyLine` |
| the week ticks, the month grouping | `clock.startsOn` + `weeks_total`, grouped by calendar month client-side |
| `"25 days left"`, the counting sentence | `LeagueCopy.pressMeter(today:)`'s facts + `bylaws.capN` + `myMonth.credits` (the *meter* dies; its numbers live) |
| the clash | `LeagueRoom.WeekClash` + `ClashMath.window` / `.bestSoFar`; the band words from `CSBands` |
| every table row | `model.teams` (`StandingsMath`) — name, points, rounds, id; `priorRank` + `priorSince` for movement; `SeasonStory.Row.counted` + `bylaws.capN` for the counting clause |
| **the gap column** | `leader.pts − row.pts`, the same subtraction `SeasonStoryCopy.rowClause` already makes for its sentence |
| the cut | `bylaws.finish == "cup_final"` + `teams.count > 2` |
| the countdown | `season_story.facts.final.in_weeks`, `.opens_on`, `.seats`, `.still_live` |
| the endgame sentence | `LeagueCopy.endgame(finish:structure:startsOn:endsOn:)` |
| the scenario line | `ScenarioLine.parts(model.scenarios)` |
| the pot, the split, the ledger rows | `model.potTotal`, `potPlayers`, `bylaws.stake`, `PotMath.trioCents`, `buyIns[member].paid` + `.amount_cents`, `collectedDollars`, `paidCount`, `stillOweCount` |
| the collector sentence | `SeasonFacts.owe(membership)` — built, tested, and called from nowhere in the shipped UI |
| the ledger line | `MoneyCopy.ledger` / `CS_LEDGER`, verbatim |
| faces | `members[].profile.marker` + `model.avatarURL[profileId]`; the pigment is `pig[hash(profile_id) % 6]` |
| the arc | `SeasonStory.Arc` + `SeasonStoryCopy.arc` / `.arcWeek`; the tier is chosen from `kind` (`post` / `lead_change` / `clash`) and `post_kind` |

**NEW DATA — one item, and it is optional.** See §13.

---

## 7 · THE AUDIT, ANSWERED BY NAME

| Finding | Answer |
|---|---|
| **CS-06 (P0)** standings 74% down the viewport, one row visible | the table's section head lands at **~530 of 874 (61%)** with the leader, you and two more above the fold — `season-top`. The card stack, the meter and the second serif sentence that pushed it down are gone |
| **CS-07** the season's name printed three times in 50pt | once, in `display` 34. `navigationTitle("")` (LINT-24) |
| **CS-08** the biggest number in the first viewport is a 14pt clash figure | the biggest numbers are the leader's `19` at `figure` 40 and the rank rail's `01` at 27 |
| **CS-10** six oranges with six meanings in one viewport | **two ember objects** (the eyebrow's dot, the live tick) and **one gold** (the leader's rail). `warm`/`hot`/`fire`/`focus`/`dawn` are deleted tokens |
| **CS-11** an orange square as identity in the table, a marker 40pt below | `CSFace` in every row, one drawing, six pigments. The swatch is deleted |
| **CS-12** a headless gradient progress bar | the month clock: countable ticks, grouped by month, one live cell |
| **CS-13** two serif sentences ~1,100 units apart saying one thing | **one serif appearance per viewport** — the chapter line. The story page's copy of it is the newest chapter's dated entry in an archive, which is where a repeated sentence belongs |
| **CS-15** three link idioms on one page | one: `name` 15 in `ink` with a 2px `brand` rule and a drawn arrow |
| **CS-16 / DD-08** rank and points in the same face at the same size | rank `figure` 27 in a 44pt rail; points `figure` 27 (40 for the leader) right-flush. §15's order is legible at a glance |
| **CS-17** row 1 and row 2 identical but for colour | the leader's slat is 74pt with a 38pt face and a 40pt total |
| **CS-18** column heads sitting 140–200px off their columns | **no column heads** |
| **CS-20** the scenario line as a console message | one `agateS` line under the endgame sentence |
| **CS-21 (P0)** three standings tables for a field of two | **one** |
| **CS-24** a signed red/green float column | deleted with `IndividualRaceView`; money never takes `pos`/`neg` |
| **CS-29 (P0)** the story at one weight | three tiers plus a serif lead, §1.8 |
| **CS-32** the story page's lead is the season page's sentence verbatim | it is the same sentence in a **dated chapter at `story` 20**, not a duplicated standfirst at `lead` 28 |
| **CS-38** seven equal capsules, one of them red, under a gold eyebrow | one secondary door |
| **§2.7** the pot's tick list, the `✓`, the emoji-in-a-circle, opacity-as-state | the leaf: a printed ledger with faces, the sign as a word, and a collected total |
| **§13 of the brief** — title · identity · participants · standings · progress · upcoming · narrative · history | display + look-tinted eyebrow · six faces · the board · the month clock · the Cup Final countdown · the chapter line and the arc · the story page's archive |

---

## 8 · BUDGETS, COUNTED

| Budget | `season-top` | `season-table` | `season-story` | `season-money` | `season-light` |
|---|--:|--:|--:|--:|--:|
| `display` (max 1) | 1 | 0 | 1 | 0 | 1 |
| serif appearance (max 1) | 1 | 0 | 1 | 0 | 1 |
| **gold objects** (max 1; leader+pot whitelisted) | 1 | 2 ✔ | 0 | 1 | 1 |
| **`brand` fills** (max 1) | 2 ⚠ | 0 | 0 | 0 | 2 ⚠ |
| `panel` (max 2) | 1 | 0 | 2 | 0 | 1 |
| **agate blocks** (max 4) | 4 | 4 | 6 ⚠ | 3 | 4 |
| containers | 1 panel | 0 | 2 panels | 1 leaf | 1 panel |
| cards / borders / capsules | 0 | 0 | 0 | 0 | 0 |

⚠ = a stated deviation. See §12.

---

## 9 · ACCESSIBILITY

- Every text pair on this surface is from §2.8's legal set. `dim` and `rule` **carry no words anywhere**
  on it — the month labels, the section-head counts and the clash's clock all sit at `mut` (7.07:1 dark,
  5.85:1 light), which is the correction to the first draft of these mockups.
- Nothing renders below **11pt** at the default size. The smallest type on the surface is `agateS` 11
  and `colS` 12; the leaf's initials disc sets `agateS` 11, not 10.
- **44pt minimum target**: the rail is 44 by construction; slats are ≥52; doors ≥52; the tertiary link
  carries a 44pt `contentShape`.
- **One VoiceOver element per slat**, in the product's voice; the movement mark and the tick row carry
  written labels (*"Week five of thirteen, the live week"*); the cut rule is a heading.
- **Colour is never the only channel**: movement is a *shape* (triangle up / triangle down / bar),
  the leader is a *field* (the gold rail) as well as a hue, the pot is a *rule* as well as a metal, the
  paid state is a *word*, and the link is a *rule* under the text.
- The gold rail's numerals are `panelInk` at **9.43:1** (dark) and **5.64:1** (light).

---

## 10 · THE WEB DESK, in one paragraph

Owner ruling R-C: the desk is a sidebar and a wide two-column body, not the phone's page reflowed. The
season lives in the body at `1fr + 340pt` with `gutterDesk` 40: **left** — the chapter line at `lead`,
the month clock across the full column width (thirteen ticks, no group wrapping), the board at `slat`
height **56** carrying two columns the phone cannot afford (`RDS` and `MONEY`, money in ink with the
sign as a word in the header, never red and green) plus a **five-dot form column** inside the row
(`pos` filled = beat your number, `rule` = did not); **right** — the clash as a fixed panel at the top,
then the season's story as a scrolling list of week chapters (the arc at length, which is the desk's
real advantage), then the pot with its split, its leaf ledger and the ledger line beneath. `display`
runs at 42 and `story` at 21. Hover steps a slat's ground to `bg1` and paints its rail slot `bg2`;
**every hover state has a focus twin** — a 2px `brand` outline on the whole slat, never suppressed;
`↑`/`↓` move between slats, `→` opens the receipt, `g` then `t` jumps to the table, `Esc` closes. The
board and the leaf both take a print stylesheet, because a season table and a pot ledger are the two
things a Pro actually prints.

---

## 11 · TWO THINGS PHASE 3 MUST CLEAR BEFORE SIGNING THIS OFF

Both are capture blockers from `UI_SYSTEM` §16.5, and both apply to this surface directly: **(1)** the
light theme has never been rendered on a device (`CupSeasonApp.swift:15,27` applies
`preferredColorScheme` from `UserDefaults`, so `xcrun simctl ui … appearance light` never reaches the
UI) — every statement about `season-light` is computed, not seen; **(2)** AX3 has never been rendered
(`-UIPreferredContentSizeCategoryName` does not take). Add a launch-argument hatch for `CSAppearance`
and for the content-size category, or the review of this surface is blind on two of its axes.

---

## 12 · DEVIATIONS FROM `UI_SYSTEM` — recorded, not resolved

*The refuters decide these. Each names the rule, what this surface did, and why.*

**D-1 · RESOLVED in the system.** LINT-18 is restated: it counts **every** ember mark on a viewport —
fill, rule, glyph, dot and word — **capped at two**, with the tab band exempt and *a live dot plus its
own eyebrow counted as one*. The live week tick and the live eyebrow's dot are therefore one mark
between them (both are the same clock, and the eyebrow names it), and the surface has one mark to
spend elsewhere. The looser fill-only version could not see the real failure, which was four screens
whose only content-area ember was the word `CLOSE`.

**D-2 · RESOLVED in the system, and in the other direction.** §1.5 now budgets **ten tracked-caps agate
lines** and exempts nothing except the tab band and sentence-case `agate`. `season-story` carries the
eyebrow, five chapter rules and three datelines — nine — and the moment sub-lines set in **sentence
case**, where they belong: *"Galen · Papago · Sep 1"* is a phrase, not a label. No carve-out was needed;
the budget was simply counting the wrong thing.

**D-2a · The serif on `season-story`, declared rather than left to a refuter.** §1.4 allows New York
**one appearance per viewport**. The first draft rendered four serif blocks on this page (the chapter
line, the moment sentence, the personal-best sentence and the Week 1 sentence), and the consequence is
not a lint failure but that the serif stops meaning *slow down here* and becomes the story page's body
face — the almanac voice spent as wallpaper. **The rule for this page: the chapter headline is the
serif, one per chapter, and only the top chapter's is `lead` 28; every other chapter's is `story` 20 at
most.** A moment sentence (*"Galen put a round on the books…"*) is `body` 17 in `ink` — it is a report,
not a headline.

**D-3 · §18 of the brief (one obvious primary) — the live season page has no primary button.** §15.4
describes this surface as a board, and its live action (adding a round) belongs to the ⊕ and to D82's
four places. This surface renders that action as a **tertiary link under the counting sentence**, where
the sentence has just told the golfer he owes the month three more rounds. A primary appears only in
the states where the page genuinely owns one: setup and the draw (the Pro's
`"The rules freeze at the first tee"` / `"Start the season"` — never *lock the roster* or *start the
draft*, `TERMINOLOGY` §4 patterns 5 and 14), the empty table (`"Add my round"`), the
error-with-nothing-cached
(`"Try again"`), and complete (`"See how it ended"`).

**D-4 · §3.3 (the leaf's licensed uses) — the buy-in ledger is printed on a leaf.** §3.3 licenses the
leaf for "the front nine, the scorecard, **a receipt**, the settlement card, the season book page, the
Record's table. Nothing else." A pot ledger is a receipt of who has paid, it is a grid, and it passes
the leaf's own test. If the refuters read the licence narrowly, the ledger renders as slats with
hairlines on `bg0` and the surface loses its one printed object — and with it the audit's answer to
"the money surface of a product about money between friends has no ledger character".

**D-5 · §9.1 (the slat is 50pt at the default size) — the leader's slat is 74pt and its total is
`figure` 40, not 27.** §9.1 gives every row one geometry. §13 of the brief says the leader must visually
matter, and the audit's §2.6 remedy asks in as many words for "the leader's row a beat taller". This is
a *deliberate* second slat geometry, used once per table and only on rank 1. It is not a card: no
radius, no border, no fill, same rail, same columns.

**D-6 · §15.4 ("gold appears exactly twice") — `season-table` shows both at once.** The leader's rail
field and the pot figure are in the same viewport. §15.4 explicitly whitelists this pair as the
budget's one sanctioned exception, so this is compliance rather than deviation — recorded because LINT-17
will flag it and needs the season's whitelist entry by name (`SeasonPage.leaderRail`,
`SeasonPage.potFigure`).

**D-7 · The mockups are not the whole page.** The five artboards are five viewports of one scroll. The
setup/draft phases, the Cup Final race view, the cancellation banner, the pass card and the fine print
are specified in prose above and are not drawn. Known imperfection, stated rather than iterated: on
`season-story` the Week 1 notice sits under the scroll fade — it is drawn in the file and it is the
correct behaviour of a scrolling archive, but it means the artboard shows four complete chapters and a
fifth beginning, not five.

---

## 13 · NEW DATA

**One item, optional, and the surface degrades cleanly without it.**

`SeasonStory.Arc` carries `kind`, `week`, `on`, `subject`, `other`, `text`, `post_kind` and `mine` — but
**no numeric field**. §1.8's *moment* tier puts the round's gross in a `panel` beside the sentence.
Without a numeric field the panel cannot be filled from the arc, and the tier degrades to the *result*
tier (the sentence with its dateline, no panel) — which is what ships if nothing is added. **Proposal:
`Arc.figure: Double?` and `Arc.figure_label: String?`** ("GROSS", "PTS"), emitted by `season_story` for
the arc rows it already builds from `posts` and `rounds`, where the number is already in the row it
counted over. No new table, no new read, no new count — one column on a payload that is already
assembled.

Everything else on this surface — including the gap column, the month grouping, the counting clause and
the collector sentence — is a producer this build already ships or an arithmetic over rows the client
already holds.


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it.** Instantly 3/3 · looks like Cup Season 3/3 · premium 3/3 · template 0/3
· proud to post 3/3 · belongs 3/3. Median **7.8**, with **consistency 6** — and every consistency
finding was arithmetic, not taste.

**1 · One printing of the ledger line (§16A.1).** It appeared **twice on `season-money`, 250pt apart,
verbatim**, and again on `season-table`. All three filed it; blind-3's sentence is the one §16A.1
quotes: *"It is a legal line being used as a layout element."* It is now printed once in the whole
product — `agateS`, pinned above the tab bar on the money surface, under a hairline.

**2 · The pot names itself once.** `THE POT · SIX IN AT $60` was both the section head and the caption
of the same `$360`. The head carries the count (`EIGHT IN`) and the figure carries the rule.

**3 · One fixture, and it is arithmetic.** `SIX IN THE FIELD / $360 / $216 · $90 · $54` here versus
`ALL EIGHT / $480 / 288 · 120 · 72` on the leaderboard, for the same league in the same week. **The
Fellas are eight in at $60 → $480 → $288 / $120 / $72**, on every surface. The twelve-strong board is
a different league.

**4 · The narrative agrees with itself.** *"Galen has led for four straight weeks"* headed a story
whose week-3 entry is *"Galen took the lead from Jade"* — three weeks. The headline is now *"Galen has
led since week three."* and the table's sub-line reads `HELD SINCE WEEK THREE`. `04 WEEKS TO THE CUP
FINAL` in week 5 of 13 is `08`. A week-5 story item dated `Mon Sep 7` on a device reading `Sun Sep 6`
is dated `Sat Sep 5`; **story items are clamped to today.**

**5 · The table carries its header at every field size (§9.1).** blind-2 called the unlabelled
`+4 / +9 / +12` column "the single most confusing element in the set". `POS · GOLFER · GAP · PTS` now
heads the season table exactly as it heads the leaderboard, and **the delta folded into the gap cell**
so the two surfaces are one component with one geometry.

**6 · The month clock is one component (§9.10).** It carried month labels here and none on the
leaderboard's week bar. The leaderboard's bar is now the same object: ticks grouped by the month that
counts them, each month named, the live month in `brand`.

**7 · Two deletions.** The `$360` figure was `figXL` gold — "the loudest object in the entire product,
louder than the leader's points and louder than the primary CTA" (blind-3). It is `fig`. And
`THE REST OF THE SEASON`, a two-item nav menu bolted to the end of a content page, is gone.

**8 · A sub-line is authored to a character budget.** `1 OF 4 COUNTING · ONE S…` sheared; the clause
is now `1 OF 4 COUNTING` and the qualifier lives in the receipt.
