# SURFACE SPEC — LEADERBOARDS AND SCORE DISPLAYS

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 of 3 (design; nothing is built)
**Obeys** `UI_SYSTEM.md` in full · **Standard** `BRIEF.md` §15, §16, §8, §13, §31, §33
**Evidence** `UI_AUDIT.md` §2.6, §2.10, §2.20, §3.8; the ten problems
**Mockups** `mockups/leaderboard.html` → `mockups/renders/leaderboard/` (7 artboards, 402×874, 2×)

> **The one-second test.** Open any board in this document, look for one second, look away.
> You should be able to say **who leads, where you are, and which way you are moving.**
> Every decision below is subordinate to that.

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · THE THESIS FOR THIS SURFACE

A leaderboard is the product's **board**, and the board is printed. So it is made of the four devices
the system already owns and **nothing else**: the **rank rail** (44pt, painted only when the position
is earned or is yours), the **slat** (a full-bleed row with a rule on its top edge), the **rule-and-
figure** (a number over a 2pt rule with an agate label), and the **scorecard ink law** (ring / box, no
colour). There is no card, no border, no pill, no tinted chip, no header rule that does not match the
rows', no swatch, and no column of unsigned zeros.

Everything this surface adds to the system is one idea: **the movement clock is named once, for the
whole table, in the section head** — `THE TABLE · MOVED SINCE SUN` — instead of eleven times at 11pt
beside eleven two-digit ranks. That single move deletes the audit's two-line `HELD SINCE SUN` fragment
(§2.6, DD-08), keeps `StandingsMath`'s absolute rule that a movement label must name the day it is
measured from, and frees the movement column to be what §15 of the brief asks for: **a mark you read,
not a sentence you parse.**

---

## 1 · THE OBJECTS, DEFINED ONCE

| Object | Swift name (§18) | Geometry | Rule |
|---|---|---|---|
| **The rank rail** | `CSRankRail` | 44 × row height, radius 0, no border | `figure` 27 tabular, two digits, leading zero, centred. Field: `gold` + `panelInk` when the position was **earned**; `panel` + `panelInk` when the row is **yours**; unpainted with the numeral in `mut` for everyone else |
| **The slat** | `CSSlat` | full-bleed, `min-height` **50** (default size), one 1px `rule` on the top edge, body inset `rail` + `s3` = 56 left, `gutter` 20 right | rail · face · name + sub · movement · gap · points |
| **The face** | `CSFace` | **30** in a table row, **38** on the friends board and the live sheet | pigment disc keyed to the golfer's id, 1px `rule` inset ring, marker at 55%, `ink` when it is the viewer. "Chose nothing" draws initials in `name` 15 |
| **The movement mark** | `CSMovement` | 34pt column, one line, never wraps | drawn triangle 9 × 7 in `pos` (up) / inverted in `cool` (down) + the count in `figure` 20 **`ink`**; a 9 × 2 `rule` bar for held. **No field, no tint, no pill.** ▼ means one thing: you fell |
| **The gap column** | — | 42pt, right-flush, `column` 14 in `mut` | `+4` · `+9` · `—`. **The leader's cell is empty, never "0"** |
| **The points figure** | `CSFigure` | 50pt column, right-flush, `figure` 27 tabular | **`gold` only for the leader**, `ink` for everybody else. Reserves three digits |
| **The rule-and-figure** | `CSFigure` | figure · 2pt rule the width of its column · agate label beneath | `.ink` default · `.live` (`brand` rule) · `.earned` (`gold` rule). The pot, the gross, the points, the form figure |
| **The score mark** | `CSScoreMark` | 1.7pt stroke, `currentColor`, no fill | ring = birdie · double ring = eagle+ · nothing = par · box = bogey · double box = worse. **No colour, in any theme** |
| **The hole strip** | `CSHoleStrip` (new) | 18 cells across the 362pt measure, 30pt tall, one `rule` beneath | each cell draws that hole's **score mark** (a 4pt `ink` dot for par); unplayed is a 9 × 1 `rule` dash; the hole you are on carries a **2pt `brand` rule** under its cell |
| **The receipt** | `CSLeaf` | a leaf, radius `p` 3, `leaf-shade`, 1px `rule` frame in light | label/value rows on hairlines, a **2pt `leafInk` rule** above the total, the total's value in `figure` 20 |

**Nothing else is allowed on this surface.** No `CSCard`, no `Capsule()`, no `RoundedRectangle` outside
`CSDesign`, no swatch, no header row whose rule differs from the rows'.

---

## 2 · ANATOMY — THE SEASON BOARD (`lb-season-6`, `lb-season-2`, `lb-light`)

Top to bottom, with the token name for every gap.

| # | Element | Type role | Token / colour | Space above |
|---|---|---|---|---|
| 1 | back chevron (system) | SF Symbol 22 | `mut` | — |
| 2 | the live eyebrow — a **7pt `brand` dot** + `SEASON LIVE · WEEK 5 OF 13` | `agate` 12 | `brand` | `s2` |
| 3 | the season's name | `display` 34 UPPER | `ink` | `s2` |
| 4 | **the chapter line** — the one serif sentence the surface allows | `story` 20, sentence case | `ink` | `s3` |
| 5 | the week ticks — N cells, 8pt tall, `s1` gutters | — | `mut` played · `brand` now · `rule` ahead | `s3`+2 |
| 6 | the counting note | `agateS` 11 | `mut` | `s3` |
| 7 | **the section head** — `THE TABLE · MOVED SINCE SUN` + a 1px rule to the margin | `agate` 12 | `mut` | `s4` |
| 8 | the column heads — `POS · GOLFER · (blank) · GAP · PTS` | `agateS` 11 | `mut` | `s2` |
| 9 | **the slats**, N × 50pt | §1 | — | 0 |
| 10 | one closing 1px `rule` | — | `rule` | 0 |
| 11 | **the pot** — a `.earned` rule-and-figure: `$480` in `gold` over a 2pt `gold` rule, `THE POT · 8 IN AT $60 · 288 / 120 / 72` beneath; `All eight` as a tertiary link, right — no arrow (§5.2) | `figure` 40 / `agateS` | `gold` / `mut` | `s4` |
| 12 | **the ledger line**, verbatim from `MoneyCopy.ledger` | `body` 15 (13.5 on the phone) | `mut` | `s2` |
| 13 | the 28pt fade, then `CSTabBand` | — | — | — |

**Column geometry, left to right** (402pt wide, `gutter` 20):
`rail` 44 · `s3` 12 · face 30 · `s2`+2 10 · **name (flex, min-width 0)** · 10 · movement 34 · 10 · gap 42 ·
10 · points 50 · `gutter` 20.

**The two-golfer board (`lb-season-2`)** is the same table. Nothing shrinks and nothing is replaced by a
duel widget: the surface's extra room goes to **the clash** above the table (two 38pt faces, names, the
band sub-line, and the posted gross in a **panel** 64 × 52), and the pot beneath reads
`THE POT · 2 IN AT $60 · WINNER TAKES IT`. A table of two still looks like a table, because a season of
two is still a season. *(This answers the audit's CS-21 — three standings objects for a field of two —
by shipping **one** standings object at every field size; the climb window appears only when the field
exceeds it, and the individual race only in a squads season.)*

**The light printing (`lb-light`)** is not a paler dark. The paper is `#F4F1E9`, gold is the bronze
`#7A5A12` (5.64:1), ember is the stamp red `#A8420F`, and **the rail inverts**: the leader's field is
bronze with `panelInk` numerals, and *your* field is a near-black slab with light numerals. The panel's
inversion is the light theme's whole idea and it is at its most useful here, because the rail is the one
place on the board where depth has a job.

---

## 3 · ANATOMY — THE FULL BOARD (`lb-season-12`)

The pushed "all golfers" screen. `navigationTitle("")`; `CSPageHeader` names it.

1. back chevron · 2. `agate` eyebrow `THE FELLAS · MOVED SINCE SUN` · 3. a baseline-aligned row:
`display` 24 `ALL TWELVE` left, **the payout ladder** `1ST $288 · 2ND $120 · 3RD $72` in `agateS` at
`mut`, right · 4. the column heads · 5. twelve slats · 6. a closing rule.

**This is where the fifth of `BRIEF` §15's ordered facts — STAKE — lands on the phone.** `UI_SYSTEM`
§9.1 puts money in a sixth column **on the desk only**, and this document obeys that: the phone's board
carries no money column. The stake instead reads once, in the header, as the ladder every position is
playing for, and again at the foot of the season page as the pot. It is on the surface, it is scannable,
and it costs no column. *(Recorded as a deviation — see §10, D-1.)*

**The four hard cases, all rendered:**

| Case | The answer |
|---|---|
| **Long names** | one policy product-wide: `name` truncates with a **tail ellipsis**, `min-width: 0`, never wraps, never clips mid-glyph. The sub-line takes the same policy. *(Replaces the shipped wrap / wrap / clip split across three standings surfaces — and the one that clipped was the live round.)* |
| **A tie** | both rows carry the **same rail numeral** (`04`, `04`) and the next row is `06`; both gap cells read the same figure; the sub-line says `TIED`. Competition rank, not array index — see §8, new data |
| **A three-digit total** | the points column reserves **three tabular digits** at `figure` 27 (50pt). Nothing re-flows when the leader passes 99 |
| **No movement clock** | when `StandingsMath.priorSince` returns nil, **the whole movement column and the section head's `· MOVED SINCE SUN` clause do not render.** No bare arrow, no empty column, no "held" claimed without a clock |

---

## 4 · ANATOMY — THE GOLFERS BOARD (`lb-friends-form`)

The Golfers tab root. Same slat, one narrowing and one substitution.

1. `display` 34 `GOLFERS` with the dateline in `agate` right, on one baseline · 2. the search field
(50pt, `rc` 10, `bg2`, no border) · 3. section head `THE BOARD · LAST 30 DAYS` · 4. one chip row, two
chips (`Form` / `Handicap`), the selected chip **inverting to the panel** · 5. slats at **60pt** with
38pt faces · 6. the note line, verbatim from `FriendsBoard.note`.

**The substitution, and it is quieter than the first draft.** This board has no season, no gap and no
points, so the trailing column carries the golfer's `avg_vs_number_30d` as a **bare tabular `figure` 20,
right-flush, with no rule** (§9.2: a figure repeating down a column takes no rule — column position is
the hierarchy, and six rule-and-figures down one list is six 2pt rules and eleven lines of ragged caps
against one right edge).

**The frame is named once, at the section head, not on every row.** The head reads
`THE BOARD · VS PLAYING HCP · LAST 30 DAYS`; the rows carry the figure alone. *(The first draft captioned
each figure with a band word, which is three faults at once: it invents a sixth band —
`BEAT THEIR NUMBER` is not one of spec §2.2's five and preflight 42 fails any comparison frame that says
`number` unless the string **is** one of the five verbatim; a bare ±N.N under a band word is the
`pviChip`, a name `UI_SYSTEM` §18 itself lists as retired and the PvI-on-a-surface `brand-canon` §3 bans
by name; and it says the same fact three times per row — `3 ROUNDS · BEAT IT ONCE`, `−1.8`,
`A LITTLE LOOSE` — against D201's one-fact-one-place.)*

**Where a band word does appear it is one of the five, verbatim** — *Torched it · Beat your number ·
Played to it · A little loose · Posted anyway* — first person on the viewer's own row, and on anybody
else's row the sub-line's existing clause does the job with no possessive at all. It sets on **one
line** in a slot wide enough for the longest band at the default size, and it truncates under the one
long-name policy rather than wrapping. **The sub-line then carries the count only** — `3 ROUNDS` — and
drops the verdict clause it was repeating.

**The narrowing, and it is deliberate: the rail is never painted gold here.** `UI_SYSTEM` §9.1 paints
the rail gold "when the position was earned". Leading a rolling 30-day form window is not a thing that
was *won*, and `D245` clause 5 / `L-22` forbid this board reading as a score. So the rail has **two**
states on this surface — `panel` when it is yours, unpainted for everyone else — and the surface spends
**zero** gold objects. *(Deviation D-7.)*

Also fixed here, from the audit: **faces at last** (`FriendsBoard.swift:70` draws a bare marker and never
reaches `CSFace` — deleted, not patched); the rank as a `figure` in the rail rather than a 13pt mono line
number; **one** sub-line instead of two; the three-identical-greys problem gone, because the row now has
exactly two tones (`ink` for the name and the figure, `mut` for everything else).

---

## 5 · ANATOMY — THE LIVE SHEET (`lb-live`)

The most-looked-at surface in the product, and the one the audit scored 4.8 in portrait against 6.8 for
its own landscape card. This is the portrait sheet rebuilt to the landscape card's standard.

| # | Element | Detail |
|---|---|---|
| 1 | **Close** | the one dismiss verb, a **toolbar** tertiary link at `topBarTrailing` — `ink` label, **1px `mut` rule, no ember** (§7.1). A dismiss verb is neither live nor primary, and the loudest control on the live sheet is never the one that closes it |
| 2 | the live eyebrow | 7pt `brand` dot + `LIVE · PAPAGO · BLUE · 71.2 / 128`, `agate` 12 in `brand`. One line, never wrapped — the tail is dropped before it orphans |
| 3 | **the hole** | two 44pt `bg2` targets carrying drawn chevrons, `display` 34 `HOLE 15` between them, `PAR 4 · SI 14 · 402 YDS` in `agateS` beneath. This is the screen's one `display` |
| 4 | **the hole strip** (`CSHoleStrip`, chart 4 — §9.10) | 18 cells across the measure at a **≥20pt** pitch. Each played cell draws **your** result in the scorecard ink law, **single ring / dot / single box only** — at 20pt an eagle and a birdie both read as one ring, and the *double* variants live on the card and the receipt where §9.4 has room. The hole you are on carries a 2pt `brand` rule under its cell and is `.isSelected`; unplayed holes are 9 × 1 **`mut`** dashes (`rule` at 2.30:1 in light states nothing — §16.1). **One VoiceOver element for the whole strip**, in the product's voice: *"Through fourteen. Two birdies, nine pars, three bogeys. You are on fifteen."* A 1px `rule` runs beneath the whole strip, then one agate line: `OUT 36 · THRU 14` left, `YOUR CARD · 55` right. **This replaces the 18 ember dots** — same countability, and it now says *how* the round is going, not only *how far* |
| 5 | **the golfer rows**, 70pt | 38pt face · name in `name` 17 (a guest tag in `agateS` beside it) · one agate sub-line `2 STROKES · 55 THRU 14` · then the score object |
| 6 | **the score object** | a 44pt `bg2` decrement target, **the hole's score as `figure` 27 over a 2pt rule**, a 44pt increment target. **The numeral is bare — no ring, no box** (§7.2, §9.4: a circled numeral between a − and a + reads as *this field is selected*, and the paper convention and the selection convention must not be one shape; the marks live in the strip above, where nothing is tappable). Scored: the numeral in `ink` on an `ink` rule. **Unscored: the value slot is EMPTY** — the rule stays `rule`-coloured and the hole's par hangs **below** it in `agateS` at `mut` (`PAR 4`), where a scored cell carries nothing |
| 6a | **why not par in the slot** | rendering par *is* the guess §9.9 forbids. It puts an app-supplied number in the same slot, face, size and position as a real score, told apart only by `ink` 16.05 vs `mut` 7.07 and an underline at 2.66:1 — tone-only communication on the most-looked-at screen in the product, mid-round, held in sunlight, where the consequence is a wrong card posted. §16.4 now carries the row. **And any running total computed over an empty seat says so**: `55 THRU 14 · TWO NOT IN`, on the row and on the strip's agate line |
| 7 | the match state | `agateS` `MATCH PLAY · NET BEST BALL` over `name` 17 `ALL SQUARE · THRU 14`; **`The scorecard`** as a tertiary link, right — **no arrow** (the 2px rule is the affordance, §5.2) and *scorecard*, because "the card" is the person (T-01). No card, no capsule, no restatement |
| 8 | the foot | **one full-width PRIMARY, `Finish the round`** — ember, because on the screen a golfer is holding *while standing on the course* the live thing they can do is finish the round. The first draft made it a `bg2` secondary and left `Close` as the only ember-underlined control, so the loudest mark on the screen closed it and the screen had no primary at all (brief §8, §18). It stays primary at every stage; when cards are still out it carries the count in its own label (`Finish the round · 2 not in`) and arms a confirmation rather than going quiet |

**What this kills, by name:** the `− − +` stepper whose unscored placeholder is an en dash 34pt from the
decrement glyph (PPL-19, P0); the running total at 11pt grey wrapped into a column that breaks `THRU`
into `THR / U` on an SE (PPL-20, DD-06, P0); "thru 14" appearing seven times in one viewport (PPL-21);
the 4pt colour bar standing in for a person on a screen with four people on it; the birdie that is gold
here and green on the landscape card (PPL-22); and the score frame given **less** width than either
button beside it.

**The index leaves the live row.** It is a setup fact and a receipt fact; mid-round the facts are strokes
received and the running total. *(Deviation D-4.)*

---

## 6 · ANATOMY — THE SCORE AS AN OBJECT, AND THE RECEIPT (`lb-score-object`)

`BRIEF` §16 in one screen: **a 74 should look like a meaningful piece of information**, and §16's second
half — the receipt — is why it is worth what it is.

1. **Close** (tertiary link) · 2. `agate` dateline `PAPAGO · BLUE · SUN SEP 6` · 3. `display` 24
`YOUR ROUND`.
4. **Two rule-and-figures on one baseline**: `74` in `figure` 56 over a 2pt `ink` rule with
`GROSS · 18 HOLES` in `agateS`; `12` in `figure` 40 over its own rule with `POINTS`. No panel, no card,
no gradient plate — the numeral and its rule are the object.
5. **The sentence, with a figure run**: *"You beat your playing HCP by **7.6** — your best of the
season."* set in `body` 17 (SF) with the numeral in the **board face at the sentence's own size**, so a
number in a sentence is still in the number's voice. This is the fix for `CSFont.sentence`'s 38 sites,
where the 89, the 79 and the "leads by 4" are typographically indistinguishable from the words around
them (DD-01, P0).
6. Section head `THE RECEIPT`.
7. **The receipt, on a leaf** — the one licensed use here, because a receipt is a printed grid:

```
WHAT THIS ROUND WAS WORTH                       SUN · SEP 6
────────────────────────────────────────────────────────────
The course                                       71.2 / 128
Your index that day                                    10.6
Playing HCP · 95%                                      10.1
74 − 71.2 × 113 ⁄ 128                        2.5 vs the course
Against your playing HCP                               −7.6
                                          BEAT YOUR NUMBER
════════════════════════════════════════════════════════════
POINTS                                                   12
THIS MONTH                                  COUNTING #2 OF 4
```

Rows are `body` 15 labels at `leafInk` (the arithmetic and the two handicap nouns at `leafMut`, because
they are the working, not the answer), values in `column` 14 tabular at `leafInk`, hairlines at 12%
`leafInk`. The verdict's band word hangs in `agateS` under its figure. **The total sits under a 2pt
`leafInk` rule and its value is `figure` 20** — the receipt ends in a figure, which is the whole point
of a receipt. A won or earned figure would take a **2pt gold rule beneath**, never gold ink (gold on
bone is 1.68:1).
8. `See the scorecard` as a tertiary link (no arrow — §5.2), `PLAYED WITH GALEN, TASH` in `agateS` right.

**Every row above is `ReceiptRows.build` verbatim.** Nothing is invented, nothing is reordered, and the
`.note` case (a round posted with no number) replaces the number rows with its one sentence exactly as
the producer already decides.

---

## 7 · EVERY STATE

| State | What the surface does |
|---|---|
| **Loading** | **the destination's own geometry, redacted.** Every rule, every rail slot and every disc circle draws; the name, sub-line, gap and points become `bg2` blocks at radius `p` 3 at real-length widths (`.redacted(reason: .placeholder)`). The rail numerals do **not** redact — the positions are the skeleton. **Never a spinner inside content**; the full-screen "Loading…" is deleted |
| **Empty — no rounds yet** | a **drawn empty rail** at 64pt in `rule` · `agate` eyebrow `THE TABLE` · `lead` 28: *"Nobody has posted a round yet."* — a fact about the world, never the golfer's omission · one true fact in `body` 15 at `mut`: *"Best four a month count. The season runs to Nov 2."* · **one door, required**: `Add my round` as the primary · and **a number**: the rail draws `01`–`08` unpainted with blank bodies, so the shape of the board is visible before it has data |
| **Empty — no season** | the same anatomy, door = `Start something` |
| **Error / stale** | **keep what is on screen.** Cached rows render under an `agate` dateline `AS OF FRI 6:12 PM · OFFLINE` at `mut`, with **no action disabled** (`HomeView.swift:181-184` and `:516-519` are the precedent; `:287` is a route switch). Only with nothing cached does the surface speak: one `lead` line in the product's voice, one `body` line, `Try again` as the primary |
| **Failed, but the tab still works** | the friends board's own case: one line, `FriendsBoard.didNotLoad` verbatim, in `body` 15 at `mut`, under the section head. The rest of the tab is untouched |
| **Long names** | tail ellipsis on `name` and on the sub-line; `min-width: 0`; never wraps; never clips a glyph. One policy, three surfaces |
| **No photo** | the pigment disc + the golfer's marker, at `mut` (`ink` when it is the viewer). **"Chose nothing"** draws initials in `name` 15 on the pigment — not a silhouette, not a fabricated face, and visibly different from "chose the Saguaro" |
| **A tie** | shared rail numeral, shared gap, `TIED` in the sub-line, the next rank skipped |
| **Disabled** | a board row is never disabled; a golfer with no qualifying round still has a row, a rail and a `—` |
| **AX3** | the **rail keeps its 44pt width and grows its numeral**; movement, gap and points leave their columns and set as **one agate line under the name** — `UP TWO SINCE SUNDAY · FOUR BACK · FIFTEEN POINTS` (`Movement.long` verbatim, which is why the clock survives the reflow); `minHeight` becomes intrinsic; **column heads hide**; the section head keeps its rule. One VoiceOver element per row throughout: *"2nd. You. Up two since Sunday. Four back. Fifteen points."* |
| **AX3, the live sheet** | the score object goes **full width above the name** — figure, rule and the two 44pt targets on one row, the name and sub beneath — matching §16.3's lead-block rule; the hole strip halves into two rows of nine |
| **Small phone (SE)** | nothing re-ranks by breakpoint. The name column is the only flexible one and it is already `min-width: 0`, so the SE loses characters from the name and nothing else. The movement mark never wraps because it is a drawn component, not a string |

---

## 8 · WHAT IT CONSUMES, WHAT MUST CHANGE AT THE PRODUCER, AND WHAT IS NEW

### Consumed unchanged — no producer touched

`StandingsMath.Team` · `StandingsMath.IndRow` · `MyMonth` · `StandingsMath.movement(delta:since:)`
(its `dir`, `long` and `tone`) · `StandingsMath.priorSince(snapshots:)` · `ClimbMath.items` (the
proportional ellipsis rung, a "what works") · `SeasonStoryCopy.word` · `CSBands.bandName` / `.theirs` /
`.vsShort` · `FriendsBoard.Row.band` / `.indexText` / `.ordered(_:)` / `.head` / `.note` / `.empty()` /
`.didNotLoad` · `ReceiptRows.build(_:capN:viewerId:)` and every `ReceiptRow` case · `ReceiptSeed` ·
`ReceiptCache` · `RoundCopy.f1` · `CSCopy.points` / `CSCopy.index` · `PotMath.trio` / `.dollars` /
`.splitCents` (the payout ladder is arithmetic over produced facts, not a new fact) ·
`MoneyCopy.ledger` / `CS_LEDGER` **verbatim** · `LiveCopy` · `LiveEngines` (the match state and `thru`) ·
`KeptCard` · `LeagueDates.dow` · `CSDate.local` · `RankFlipText` · `csTabular()`.

### Producer changes — the same facts, emitted without a glyph

These are not new data; they are `LINT-13` compliance and one valence bug, and all three are named in the
audit.

1. **`StandingsMath.Movement.text` emits `"▲1 SINCE SUN"`** — a typed arrow inside a produced string,
   which `LINT-13` fails. The producer must emit the **parts** (`dir`, the magnitude, the short day) and
   let `CSMovement` draw the triangle. `long` stays exactly as it is and becomes the VoiceOver string
   and the AX3 line. Nothing about the arithmetic or the two refusals changes.
2. **`Movement.Tone` has four cases** (`held` / `up` / `up2` / `down`) inherited from the deleted heat
   axis (§2.6). `up2` keeps its magnitude and loses its colour: there is one `pos` and one `cool`.
3. **▼ is emitted by three producers for "Most Improved"** — the opposite valence of "you fell"
   (DD-02, P0). Fixed **at the producer**: Most Improved becomes a `CSSlot` (a 24pt gold field with
   `panelInk` agate), and no producer emits an arrow character for it.

### NEW DATA — the design needs these and the server does not produce them today

| # | What | Why | Degrades to |
|---|---|---|---|
| **N-1** | **`photo_path` on `friends_board()` rows** and on the league standings row payload (nullable text, the same private-bucket path `rounds.photo_path` uses) | `UI_SYSTEM` §6.3 requires a face in **every** table row, and `CSFace` is the only legal way to draw a person. Neither `FriendsBoard.ServerRow` nor `StandingsMath.Team` carries a photo field, so a golfer with a photograph **structurally cannot** show it on a board — the audit's problem 3, at the payload | the pigment disc with the golfer's marker, or initials. **The design is complete without it**; N-1 only closes the structural hole |
| **N-2** | **a server-computed competition `rank`** on the standings row (dense rank with ties shared: 04, 04, 06) | the current renderers index the sorted array, so two golfers on 86 points read `04` and `05`. A tie is a real state of a points table and the rail must show it | the array index — which is wrong, visibly, the first time two golfers tie |
| **N-3** | **a per-hole `par` guarantee on the live round payload** (it is cached in `api_course_holes` on tee pick, but `LiveCardView` already refuses to draw off an *estimated* stroke index, so the guarantee is not universal) | the hole strip draws the scorecard ink law, which is par-relative | the strip degrades to **played / unplayed** ticks with no marks — countable, honest, and still better than the shipped dots. The refusal-to-assert discipline is preserved: no par, no mark |

**Nothing else is new.** The gap is `leader.pts − row.pts`. The payout ladder is `PotMath`. The
movement clock is `priorSince`. The band words are `CSBands`. The receipt is `ReceiptRows`.

---

## 9 · MOTION (`UI_SYSTEM` §11)

Two curves only: `roll` `cubic-bezier(.16,.84,.36,1)` for travel, `snap` `cubic-bezier(.2,0,0,1)` 180ms
for arrivals and tallies. Nothing bounces. `accessibilityReduceMotion` resolves both to `nil` — never
"faster" — and every rest frame is the finished state.

| Moment | What happens |
|---|---|
| **The board arrives** | the table **wipes** in top-down at a **40ms stagger** — a clip rect opening from the rail's edge across each slat, so the rank slot is on screen before the name and the name before the figure. `snap`. This is why the rail earns its keep twice: it is the origin of every arrival, so motion and layout are one idea |
| **A rank changed since the last open** | that row's numeral **slots** (`RankFlipText`, the split-flap, kept verbatim with its deterministic decoys) and its **movement mark wipes in from the rail after the row settles**. `.impact(.light)` **once**, and only if **your** row moved. This is the audit's stubbed climb (§22 of the brief, "moving up a leaderboard") finally playing — it needs the **replay-on-open gate** the standings table already has and the climb does not |
| **A score lands on the live sheet** | the hole-strip cell's **mark draws** (a 160ms stroke draw on `snap`), the running total in the sub-line **tallies**, and the score's own rule goes from `rule` to `ink`. `.selection` per step; `.impact(.light)` on hole complete — the shipped haptic that currently has no visual twin |
| **A round posts** | the gross **tallies** 0 → 74 over 340ms on `snap` while its 2pt rule wipes in from the left; the `POSTED` mark seals on the last frame with `.success`. The number is the ceremony; there is no confetti |
| **The receipt opens** | rows wipe in from the left at a 30ms stagger; **the total's 2pt rule draws last**, left to right, and the total tallies on it. A receipt should feel like it is being totted up |

**Deleted here:** every bare opacity transition on a standings row; the shimmer skeleton (replaced by
redacted geometry); any spinner inside content; any animation whose only variable is duration.

---

## 10 · THE FILES THIS REPLACES

Grepped at HEAD 57b993f.

| File | Lines | What happens |
|---|--:|---|
| `apps/ios/CupSeason/League/StandingsTableView.swift` | 284 | **Replaced.** Becomes `CSSlat` × N inside a `CSSectionHead`. The header `HStack`'s swallowed `.frame(maxWidth: .infinity, alignment: .leading)` at `:63` (which collapses the column heads ~150px left of the columns they name — CS-18) dies with the header. The 10pt `cs.squad(t.ci)` swatch at `:98` dies with the swatch. `RankFlipText` and the rank-up haptic at `:224-284` **survive verbatim** |
| `apps/ios/CupSeason/League/ClimbView.swift` | 144 | **Merged.** One standings object, not three: the climb becomes the table's **window** when the field exceeds it. `ClimbMath.items`' proportional ellipsis rung survives and becomes the window's rule |
| `apps/ios/CupSeason/League/IndividualRaceView.swift` | 132 | **Replaced and conditioned** — renders only in a squads season. Its signed red/green float column at `:89-90` (which `COMPONENT_SYSTEM` AP-2 bans outside a receipt) is deleted |
| `apps/ios/CupSeason/League/CupFinalRaceView.swift` | 125 | **Replaced** by the same slat. Its `CSFont.stat` 21pt finalist total at `:57` — the only points figure in the shipped set above 14pt — is the thing being generalised, at `figure` 27 |
| `apps/ios/CupSeason/Season/SeasonPage.swift` | — | `:231-248` stops rendering three standings unconditionally; `:236` and `:241` become one `CSStandingsBoard` |
| `apps/ios/CupSeason/Golfers/FriendsBoard.swift` | 290 | **Replaced.** `:70`'s bare `CSMarkerView` path is **deleted, not patched** — `CSFace` becomes the only way a person is drawn |
| `apps/ios/CupSeason/Golfers/GolfersScreen.swift` | 150 | **Reordered**: the board leads, the search field folds under the header, the `FIND GOLFERS` eyebrow and the dateline go (three agate blocks in the first viewport become one) |
| `apps/ios/CupSeason/Live/LivePlayView.swift` | 506 | **Replaced** from the status band down: the two capsule chips, the 18 ember dots, the four `4×40` colour bars, the stacked `55 / THRU / 14 / -1` column, the `− – +` tray and the bordered side-game card. The 44pt circular hole arrows and the stepper-opens-on-par behaviour survive; `:260`'s clip long-name policy becomes the product's tail ellipsis |
| `apps/ios/CupSeason/Live/LiveCardView.swift` | 232 | **Kept — this is the ceiling and it is not being redesigned.** Three fixes only: its 11 `cs.dim` text sites move to `mut`, its single `accessibilityLabel` becomes per-column labels, and its birdie stops being gold (the ink law applies: a ring). Its refusal to draw stroke pips off an estimated stroke index is a "what works" and is preserved |
| `apps/ios/CupSeason/Rounds/RoundReceiptSheet.swift` | — | **Re-clothed onto a leaf.** `ReceiptRows` untouched; `MathRow` becomes the leaf's grid row; the `cs.line2` stroke at the photo dies with the token |
| `apps/ios/CupSeason/League/ReceiptSheets.swift` | 147 | Same treatment; the season receipt is the same leaf |
| `apps/ios/CupSeason/League/RoomBits.swift` | 264 | `RoomMathRow` (`:147-163`) is the receipt shape the audit calls right — it survives as the **leaf's row**, with `CSFont.stat` → `figure` 20 and `cs.line2` → the 2pt `leafInk` rule |
| `apps/ios/CupSeason/Post/PostRoundScreen.swift` | — | `:530` and `:536`'s `CSFont.figure` gross — the best-typeset object in the product — becomes the canonical **rule-and-figure** and is the model the rest of this surface is derived from |
| `apps/ios/CupSeason/Events/RyderRoomView.swift`, `EventRoomScreen.swift` | — | the event scoreboard becomes the same slat with **`THRU` in place of `GAP`** (`UI_SYSTEM` §15.5) |
| `index.html` — `renderStandings()` at `:6011` | — | the web half, §11 below. Two clients, one producer set, two shapes |

**Retired names** used by these files: `CSCard`, `CSStat`, `CSMini`, `MiniPill`, `pviChip`, `RoomSpark`,
`cs.line2`, `cs.dawn`, `cs.warm/hot/fire`, `CSFont.sentence` for numbers.

---

## 11 · THE WEB DESK, IN ONE PARAGRAPH

Owner ruling **R-C**: the desk is its own desktop-first shape, not the phone's tabs reflowed. The board
is the left column of the `1fr + 340pt` body at `gutterDesk` 40, and it is **the same slat at 56pt**
with the same 44pt rail — nothing is re-designed, only the column count changes. It gains the two
columns the phone cannot afford: `RDS · BEST · GAP · PTS · MONEY`, plus a **five-dot form column inside
the row** (`pos` filled = beat your number, `rule` = did not), which is what makes LAST FIVE scannable
without a separate block. **Money in the desk table is `ink` with the word in the column head**, never
green and red, and the ledger line sits under the table. Faces sit **above** the table as well as in it.
Hover (guarded `@media (hover: hover)`) steps the slat's ground to `bg1` and paints its rail slot `bg2`;
**every hover state has a focus twin** — a 2px `brand` outline on the whole slat, always visible, never
suppressed — against the shipped web's 40 hover rules and one `[disabled]` rule. Keyboard: `↑`/`↓`
between slats, `→` opens the receipt, `g` then `t` jumps to the table, `Esc` closes. The board and the
settlement card both get **print stylesheets**, because the archive test should be functional and a
league that prints its table on the last Sunday of the season is the product working as designed.

---

## 12 · THE AUDIT'S TEN PROBLEMS, ANSWERED WHERE THIS SURFACE OWNS THEM

| # | Answered here by |
|---|---|
| **1 · the card is the only container** | there is **no container on this surface at all** except the receipt's leaf (a printed grid) and one panel on the two-golfer clash. Structure is rail, rule, slat, whitespace. The header row whose rule did not match the rows' is gone with the header |
| **2 · golf numbers are not objects** | one `figure` scale at 56 / 40 / 27 / 20, tabular, in the board face; the points figure is the row's anchor at 27; the gross is 56 over a rule; the hole score is 27 wearing its mark; ten renderings of the gross become three, and `CSFont.sentence`'s 38 numeric sites become the **figure run** |
| **3 · no face anywhere** | `CSFace` in **every** row of every board and every live golfer row; the bare-glyph path is deleted; N-1 closes the payload hole |
| **5 · ember has no seat, gold is not earned-only** | on the season board gold appears **exactly twice** — the leader's rail field and the pot — which §15.4 names as the budget's one sanctioned exception because the two are the same fact. On the Golfers board gold appears **zero** times. Ember appears as the live dot and the current-hole rule, and nowhere else |
| **7 · no display tier; the eyebrow is the default voice** | one `display` per board; the agate blocks are counted (four on the season board: eyebrow, counting note, section head, column heads) and the movement clock rides the section head rather than eleven row fragments |
| **8 · empty / loading / disabled unbuilt** | §7 above: redacted geometry with the rail slots intact, an empty state with a drawn object, a fact about the world, a required door **and a number** |
| **9 · ceremony hierarchy inverted** | the biggest motion on this surface belongs to the biggest event on it: the climb finally plays, the rank slots, and the haptic fires only when **your** row moved |
| **10 · nothing re-ranks; chrome guillotines content** | one flexible column and one long-name policy; the tab band is a full-width band on the page's own ground with a rule, so there is nothing to float over; every scroll reserves its height and ends in a 28pt fade |

---

## 13 · DEVIATIONS — for the refuters

| # | The rule | What this surface did, and why |
|---|---|---|
| **D-1** | `UI_SYSTEM` §9.1: "Stake / money is the sixth column, **on the desk only**" — against `BRIEF` §15, which lists STAKE as one of the five ordered facts of a leaderboard | **Obeyed the system.** The phone's row has no money column. The stake reads as the payout ladder in the full board's header (`1ST $288 · 2ND $120 · 3RD $72`) and as the pot rule-and-figure at the season page's foot. The fact is on the surface; it is not in the row. If the refuters want §15 satisfied literally, the phone needs a sixth column and the name column drops to ~100pt |
| **D-2** | `UI_SYSTEM` §9.1 puts the movement clock nowhere, while `StandingsMath` refuses to render a movement label that does not name its day | **New placement, not named in the system**: the clock rides the **section head** (`THE TABLE · MOVED SINCE SUN`) for the whole table, and the row's mark is drawn. It also means the producer stops emitting `"▲1 SINCE SUN"` as a string. The producer's rule is honoured; its *rendering* changed. Refuters should confirm the rule is about the claim, not about the string |
| **D-3** | RESOLVED in the system | §1.5 now budgets **ten tracked-caps agate lines** and counts every one of them, including the positions the first draft exempted. At full dress this board carries nine. The mockups no longer drop the dateline or the counting note to make a number work |
| **D-4** | audit §2.20 praises the live row for carrying the golfer's number | The index **leaves the live row** (`8.4 ·` is dropped) so the sub-line fits on one line at 402pt without ellipsis. Strokes received and the running total stay. The index lives on setup and on the receipt |
| **D-5** | PROMOTED into the system | The 18-cell hole strip is now **chart 4** in §9.10 with its floor (≥20pt), its mark set (single ring / dot / single box) and its single VoiceOver element written there rather than here — it is used on two surfaces, and a rule that lives in one surface spec drifts on the second. The head-to-head's meeting tape is **chart 5** for the same reason |
| **D-6** | `UI_SYSTEM` §9.1: the rail is `gold` "when the position was earned" | **Narrowed on the Golfers board to two states** (yours / nobody's). Leading a rolling 30-day form window is not a thing won, and `D245` clause 5 / `L-22` forbid that board reading as a score. §2.4's closed gold list now says the same thing in general: an average is not earned |
| **D-7** | `UI_SYSTEM` §9.1's row reads `YOU · SAM RIDLEY` | The viewer's row reads **`YOU`** alone, product-wide. One form of address — the audit found the same component addressing the viewer two ways twelve points apart in one scroll — and it stops the viewer's own row being the one that ellipsises |
| **D-8** | `LINT-17` "one gold object per viewport" | The season board carries **two** (the leader's rail field and the pot). §15.4 whitelists exactly this pair by name; recorded so the preflight's whitelist is written, not assumed |
| **D-9** | — | **Known imperfection, stated rather than iterated a fourth time**: on `lb-season-12` the twelfth slat's bottom edge sits ~20pt above the fade, so the list ends with a visible gap rather than a cut. On a device the board scrolls and the gap does not exist. Nothing else in the set is unresolved |

---

## 14 · THE §28 REVIEW, FOR THIS SURFACE

| # | Question | Answer |
|--:|---|---|
| 1 | Most important thing | Who leads, and where you are |
| 2 | Identified instantly | **Yes.** The gold rail finds the leader and the bone rail finds you, from the far side of a table, in one glance — and neither requires reading a word |
| 3 | Hierarchy supports UX | Yes: position (rail) → player (face + name) → points (the row's largest ink figure) → movement → gap |
| 4 | Looks like Cup Season | Remove the logo and the rail, the rule-and-figure, the agate and the ink scorecard still say it |
| 5 | Premium | The board is the strongest argument the product has: a printed table with real typography and one metal spent on one earned thing |
| 6 | Generic template | No. Rank · swatch · name · two numeric columns with an all-caps header — the fantasy-league table the brief names in its do-not list — is gone entirely |
| 7 | Unnecessary UI | Removed: the header row, the Δ WK column of unsigned zeros, the swatch, two of the three standings objects, the 18 ember dots, the side-game card |
| 8 | 20% simpler | It is: two columns and a header went, and three standings objects became one |
| 9 | Personality | The rail, the ink law on the hole strip, the band words in a fixed slot, the receipt that ends in a figure |
| 10 | Proud to screenshot | **Yes** — and the two the owner would actually post are the twelve-row board and the receipt |


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it.** Instantly 2/3 · looks like Cup Season 3/3 · premium 3/3 · template
0/3 · proud to post 3/3 · belongs 3/3. Median **7.5**, with **density 6** and **readability 7** — and
one finding was filed, in the same words, by all three.

**1 · Four surnames were being cut so that two half-empty change columns could both exist (§9.1).**
`PRIYA RAGHU…`, `BARTHOLOME…`, `MARCUS OYEL…`, `ANA QUINTAN…`. blind-3 called merging the columns
"the highest-value fix in the entire set"; blind-1 said "drop GAP before you drop a surname"; blind-2
said "abbreviate to 'P. Raghunathan' before you ever ellipsize". **Both remedies are taken.** Delta
and gap are one 58pt cell — the gap figure, then the movement mark — and at a field of ten or more
**every** given name abbreviates to an initial, so the column keeps one grammar. Nothing truncates on
the twelve-row board, and **row 12 now clears the tab bar**, because the ledger sentence left the
header (§16A.1) and gave back the 44pt it needed.

**2 · A held row prints one mark.** `— —` — an em dash for the gap and a held bar for the delta —
read as a rendering error. A leader with no gap and no movement prints the held bar alone.

**3 · The header row ships at every field size.** It was on the six- and twelve-row boards and absent
on the two-row board and the season table. It is now on all four, in one geometry, and the `Δ` column
is gone from the head because it is gone from the row.

**4 · The live board, which is the one screen used with wet hands in sunlight.** Three fixes, each
filed twice or more. **The hole strip has a key** — `○ under · • level · □ over` in `agateS`, once,
beside the strip — because squares, circles and dots had no legend anywhere. **An empty value slot is
an em dash**, not a ghosted `PAR 4`, which "reads as if they scored par". And the half-screen of dead
space above `FINISH THE ROUND` now carries **the number to beat, hole by hole** — three rows naming
what each golfer needs on 15 — which is what a foursome is actually asking at that moment. The
ambiguous `Out 36 · thru 14` (read as "36 through 14 holes") is gone; the strip's right-hand line
carries `YOUR CARD · 55 THRU 14` alone.

**5 · The one place a negative number is good says so, over the column (§16A.3).**
`VS YOUR NUMBER · LOWER IS BETTER`, right-aligned above the signed differentials, instead of an
explanation 800pt away in the eyebrow.

**6 · The pot line stopped contradicting the season page**, the `ALL EIGHT` link beside `8 IN AT $60`
became `THE SPLIT` (§16A.2), and the week bar became the season page's **month clock** — same
component, one information model.

**7 · Initials are gone.** Tash Bell drew as `TB` and Bo Trittipoe as `BT` in every table while
carrying real markers elsewhere. §6.2a: there is no initials rung.
