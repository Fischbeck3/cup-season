# SURFACE — EVENT · *the title card*

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 (design; nothing is built)
**Obeys** `UI_SYSTEM.md` in full — every role, token and budget below is named from it
**Character** `UI_SYSTEM` §15.5 — *the graphic that comes up before the coverage starts*
**Mockups** `mockups/event.html` → `mockups/renders/event/` — `event-ryder-live` · `event-callout` ·
`event-plan` · `event-setup` · `event-light`
**Evidence** `UI_AUDIT.md` (the Ryder/Major/callout rooms were audited from code — the shipped
`dark-ryder` capture fell through to Home, `SHOTS.md` caveat 1), `apps/ios/CupSeason/Events/*`,
`Packages/CupSeasonKit/Sources/CupSeasonKit/Events/*`, `…/Compete/Callout.swift`, `…/Schedule/*`

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · The one-paragraph brief this answers

Brief §14: *"Events should feel like moments. Strong visual treatment for event title · course · date ·
participants · stakes · countdown · leaderboard. Think TOURNAMENT GRAPHIC, not DATABASE RECORD."*
Shipped, an event is a `CSCard` holding a bordered `A 6½ – 4½ B` with an 11pt tracked-mono clinch line
under it, then a stack of 9pt-radius bordered duel rows — box inside box inside box, the audit's
problem 1 at its purest, and the one screen in the product where the score of a live competition is
smaller than the section label above it. **This surface replaces all of that with one object: a
full-bleed ceremony plate carrying the title, the dates and the whole field, and beneath it a single
rule-and-figure that holds the score *and* the clock.** The seven facts §14 lists are on the first
screen without a card anywhere, and the primary thing — *who is winning, and how long you have* — is
identifiable in under a second because it is the only thing set at 40pt.

**The surface's three shapes, all one design.** A Ryder is a title card, a score, a field and a week
of clashes. A callout is the same title card with two faces instead of six, the same rule-and-figure with
*his number · your number · the clock*, and a printed record on a leaf instead of a week's clashes. A planned
round is the same head inside a sheet, with the countdown, the tee time, the field and the weather on
one rule. **Nothing about the layout changes between them; only how many people are in it.**

---

## 1 · What this replaces (`apps/ios/CupSeason`, grepped at HEAD 57b993f)

| File | Today | After |
|---|---|---|
| `Events/EventRoomScreen.swift` | routes on `events.kind`; sets `navigationTitle(event.name)` **and** the room draws the name again (§12.2's double-naming defect); the error state is a `CSCard(spine: cs.neg)` | **rewritten.** `navigationTitle("")`; routes on `kind` **and on `CalloutShape.isCallout`** (§3); the error state is §13.3's stale/error grammar |
| `Events/RyderRoomView.swift` | the scoreboard `CSCard(padding:16)`, `CSMini` taunt, `CSCheckRow` rosters, duel rows in a 9pt `RoundedRectangle().stroke(cs.line)`, `cs.warm` on the risen chip, the board's `SystemRow`s | **rewritten** as §2's anatomy. `CSCard`, `CSCheckRow`, `CSMini`, `cs.warm` and every `.stroke(` are gone |
| `Events/MajorRoomView.swift` · `Events/MajorJugCard.swift` | the Major's own head, jug card and leaderboard | **rewritten** to §6.1 — same title card, the board becomes `CSSlat`s with the rank rail |
| `Events/EventBits.swift` | `EventHeaderRow` (the name as an **eyebrow**, the status chip in **gold** — gold on a status is not "earned"), `EventFineCard` (a bordered `bg2` card), `EventSeg` (a fifth segmented control), `EventTeamSwatch` | **`EventHeaderRow`, `EventFineCard`, `EventSeg` deleted.** The head is `CSBand` + `CSPageHeader`'s parts; fine print is `body` 15 at `mut` on the ground; segments are `CSChip`. `EventTeamSwatch` survives as the 3pt squad rule (§2 B, §2 D) |
| `Events/EventChips.swift` · `Events/EventStagePicker.swift` | Clubhouse chips, staged invitees | re-clothed to `CSChip` / `CSFace` + `CSSlat`; no logic change |
| `Events/RyderSetupSheet.swift` · `Events/MajorSetupSheet.swift` | two setup sheets with `EventSeg` pills, `EventFieldLabel`, `EventLeaguePicker` | re-clothed to §7.2's one field family and one chip; `Close` at `topBarTrailing`, the confirm in the body (§5) |
| `Events/EventPickerSheet.swift` | the "which event?" sheet | re-clothed to `CSSlat` rows with `CSFace`; `Close` |
| `Compete/IntentSheet.swift` (+ `WhenForkSheet`) | five sentences in `CSFont.sentenceBold`, `CSSheetHeader`, hairlines | **re-clothed, not re-argued** — §5. The five sentences, their glosses, their order and the ember on the first are `StartIntent`'s and are untouched |
| `Schedule/ScheduledRoundSheet.swift` | the plan sheet: `CSSheetHeader`, a **gold-tinted weather chip**, `CSCheckRow` seats, a three-button RSVP row whose middle button is **gold** (`LINT-11`: gold may never touch a control) | **rewritten** as §4 |
| `Schedule/DeclareRoundSheet.swift` · `UpcomingRoundsSection.swift` · `UpNextChips.swift` · `ScheduleScreen.swift` | the declare sheet and the schedule's rows/chips | re-clothed to the same field family, chip and slat; out of this surface's scope except that they must not re-invent the plan's head |
| `Events/EventRoomModel.swift` | the room's loader | **untouched.** No data path changes |

**New file:** `Events/CalloutRoomView.swift`. A callout currently lands in `RyderRoomView` and is told
it is in "WEEK 1 OF 1" of a series it is not in — the exact failure `Callout.swift`'s own header names
("the Ryder room's grammar was written for a four-week series between two SIDES … so a callout does not
land there"). `CalloutShape.isCallout(sessionCount:leagueId:field:)` already exists in the Kit and is
called nowhere on the phone. The branch is one line; the room is §3.

---

## 2 · Anatomy — `event-ryder-live` (the live team event)

Top to bottom. Every gap is a `space` token; every colour a `tokens.json` name; every type role from
§1.2. The page ground is `bg0`; the side margin is `gutter` (20) throughout; the measure is 362.

### A · The title card — `CSBand(.ceremony)`, full-bleed, radius 0
Runs edge to edge and under the status bar, so it can never read as a box (§3.4). Ground `ceremony`
(`#0A0E0C`) **in both themes** — a title card is a physical object, and `event-light` proves it is the
same object in the morning room. Ink is `ceremonyInk` throughout (17.51:1).

1. **The contour** — `CSPlate(.contour)` behind everything at 1.2pt in `rule` at `a56`, six nested
   closed curves each rotated off the last so it reads as topography rather than a bullseye, cropped
   hard off its own centre, with the routing line entering from the right edge and **one `brand` dot on
   the hardest hole by stroke index**. Deterministic from the course id: same course, same plot,
   forever. **Absent when the event has no course** (§10) — the plate degrades to the bare ceremony
   ground, which is what `event-callout` shows, and it still looks like a title card.
2. **The status bar and the system back chevron** sit on the plate; nothing else is in the toolbar
   (`topBarTrailing` carries at most one tertiary link — §12.2).
3. **The live eyebrow** — a **7pt `ceremonyBrand` dot** + `agate` 12 in `ceremonyBrand` (5.75:1 in both themes — §2.8's ceremony ramp): `LIVE · WEEK 2 OF 3`. *(Never `SESSION`: `TERMINOLOGY` §4 pattern 10 retires it; the golfer's form is `Week 2 of 3`, or the date range when a window runs longer than a week.)*
   *(On the ceremony ground `brand` is the dark-room ember in both themes — §13 D-1.)* This is
   `RyderMath.statusChip(_:)` re-cased; it is the surface's whole LIVE signal. **No ember band** — §2.4
   forbids a saturated field wider than a chip carrying a label, which is the rejection the winning
   direction earned.
   Gap above: `s4`.
4. **The title** — `display` 34, `ceremonyInk`, `events.name`, wrapping to two lines, `s3` under the
   eyebrow. **One `display` per viewport** (LINT-16); this is it.
5. **The dateline** — `agate` 12 in `ceremonyMut`, two lines, `s3` under the title:
   `GOLD CANYON — DINOSAUR MOUNTAIN` / `SUN SEP 6 – SAT SEP 26 · SIX IN THE FIELD`. **En dash, never `→`** (§5.2, `LINT-13`).
   One block by §1.5's counting rule (a dateline that wraps is still one dateline).
6. **The field rail — TWO NAMED GROUPS, not one row of six.** `s4` above the plate's bottom edge,
   `s4` inset each side. **`SAGUAROS` in `agate` at `ceremonyMut` over its three 38pt `CSFace` discs;
   `COYOTES` in `agate` over its three** — two labelled groups side by side, each group's discs over a
   **3pt `ceremonySq` rule**, each disc with an `agateS` 11 name in `ceremonyMut` (`ceremonyInk` for
   your own) beneath it.
   **Why the groups.** §16.4 requires a squad to be carried by *a swatch plus the squad's name*, and a
   `space-between` row of six discs over two rule colours carries it by hue alone: `sq0` and `sq3` are
   **1.58:1** apart at best (§2.2a), so on a bright screen, through a greyscale filter, or with
   achromatopsia the two teams become one team — and the same pair keys the score cells above, so
   face → team → figure would be hue the whole way. Two labels cost one line, use copy the surface
   already has, and satisfy §16.4 literally. This is still §6.3's "spaced row with names = a roster".
   **Seven or more in the field:** each group keeps three discs and the third becomes a `+N` disc in
   `bg2` with `agate` `+2`, which pushes to the field list.
   **Below 390pt** the two groups stack (§16.3's SE clause).

### B · The score and the clock — `CSFigure` (the rule-and-figure), three cells on one rule
`s4` below the plate. **The signature object, and the surface's primary.**

- Three equal cells across the measure. Each cell: a **26 × 3pt squad rule** (cells 1–2 only, `s2`
  above the numeral), then `figure` 40 tabular in `ink`.
- **One shared 2pt rule in `brand`** beneath all three — the metal variant that means *live* (§0.2,
  §8). It goes to `ink` the moment the event completes and `gold` never (the pot is the gold object).
- Labels beneath in `agateS` 11: `SAGUAROS` and `COYOTES` in `mut`, `DAYS LEFT` in `brand`.
- Values: `RyderMath.evHalf(points)` for cells 1–2 (`3½`), `EventDates.daysUntil(session.closes_on)`
  for cell 3. **The half is a rider** — the vulgar-fraction glyph is set at 0.56em and raised 0.16em so
  a mixed number reads as one figure, exactly as the ordinal rider does on a rank hero (§1.6).
- **This one object carries the score and the countdown**, which is why the surface needs neither a
  four-cell hairline-divided facts rail (§0.5's rejection) nor a separate countdown block.

### C · The clinch sentence — `body` 15 at `mut`, `s3` below the labels
`RyderMath.clinchLine(_:)`, re-cased to a sentence: *"First to 5. The Saguaros need 1½, the Coyotes
need 2½."* The sentence is the story; the figures above are the record (§9.9). At `complete` it becomes
*"Final. The Saguaros took it 5–4."*

### D · The stakes line — one line of type, `s3` below
`figure` 20 in **`gold`** for the pot (`$480`) followed by `agate` 12 in `mut`:
`THE POT · 60/25/15 · BEST CARD EACH WEEK`. **The pot is the surface's one gold object** (LINT-17), it is
gold *ink on a numeral* — never a fill, never a chip (the shipped gold "$480 POT" chip is a gold
control by any reading), and at 20pt it needs no rule of its own (§9.2's rule-and-figure threshold is
27). The **ledger line** (`MoneyCopy.ledger`, verbatim, `body` 15, `mut`) renders under the pot **on
the event's money pane**, not here — this surface shows a pot, and §9.5's rule attaches the ledger line
to the surface that shows the money figure, which on the phone is one scroll down beside the split.
*(See §13 D-3.)*

### E · The one primary — `CSButtonStyle.primary`, `s4` above, 50pt, `rc` 10, full measure
`brand` fill, `bg0` label in `name` 17 (5.27:1 / 5.39:1). **Add my round** — the live thing you can do
now, which is what makes it legal to be ember (§2.4). One per screen: the taunt toggle, "Invite
players", "Generate pairings" and "Score this week" are all **secondary or behind the organiser's
`ellipsis`** (§13.4), not four `CSMini`s in a `FlowRow`.
- `setup`/forming: the primary is **Invite players**.
- `complete`: the primary is **Run it back** (existing `RyderPrefill` path) and **nothing on the screen
  is ember** — a completed event is not live (§2.4's mechanism).
- Your clash already posted: the primary drops to secondary **See the receipt** and the ember goes with
  it; the live dot in the eyebrow stays, because the *week* is still live.

### F · The week — `CSSectionHead`, `s4` above
`agate` 12 in `mut`: `WEEK 2 · SEP 6 – SEP 12` (`RyderMath.sessionHeader`, re-cased and re-worded), a 1px
`rule` running to the margin, and the count flush right in `agateS` at `mut`: `OPEN`. One agate line.
**An en dash, never `→`** (§5.2, `LINT-13`): an arrow inside a dateline is not a link affordance.

### G · The clash — a 56pt two-line row, one `rule` on its top edge, full-bleed
Not a `CSSlat`: **a clash has no rank, so it does not take the rail** (§13 D-4). *`duel` is a schema word
(`event_duels`); the golfer's word is **the clash**, and it already ships — D12, T-09, `TERMINOLOGY` §4
pattern 9.* Anatomy:

```
│ ◍26  GALEN MARR            def.        MIKE FENNER  ◍26 │   nameS 15 · agateS mut · nameS 15
│      +2.1                                     −0.4      │   figure 20, tabular
```

- Line 1: `CSFace` 26 · `name` 15 caps (`min-width:0`, **tail ellipsis**, the one long-name policy) ·
  the middle word in `agateS` at `mut`, **sentence case** (`RyderMath.mid(result)`: `vs` · `def.` · `halved`) · the
  opponent's name right-flush · `CSFace` 26. The **losing** side's name is `mut`; a halve leaves both
  `ink`.
- Line 2: the two figures under their own names, `figure` 20 tabular, inset 35 each side so each sits
  under its face+name column. `RyderMath.chip(...)` produces them: a resolved clash shows the two
  signed figures, an open clash shows the two numbers to beat with **`—` in `mut` for "not posted"**.
- Vertical padding `s3` top / `s2` bottom, side `gutter`.
- **Your clash is the first row of the week**, regardless of pairing order — it is the only row on
  the surface the reader is *in*, and it was the row the scroll fade cut when it sat third.
- Tap target 56 ≥ `rail` 44. One VoiceOver element: *"Galen Marr beat Mike Fenner. Galen plus two point
  one, Mike minus nought point four."*

### H · The nag line — `body` 15 at `mut`, `s3` below the last clash
`RyderMath.nagLine(waiting:closesOn:)` re-cased to a sentence: *"Still to post: you, Dev · closes
Saturday."* It is prose, not agate, because it is a sentence a person reads (§1.3) — which is also what
keeps the surface inside its four-block agate budget.

### I · The foot
The scroll ends in a **28pt fade to `bg0`** over the tab band (§12.1); the band is a full-width
`CSTabBand` on `bg0` with a 1px `rule` on top and the ⊕ as an ember glyph. Below the fold, unchanged in
IA: the two rosters with each golfer's `W-L-H`, the series line (`RyderMath.seriesLine`), the taunt
toggle, the organiser's hands, and the event board's engine posts as quiet wire rows.

**Tracked-caps agate lines on this viewport: 9 of the 10 §1.5 allows** — the live eyebrow, the dateline, the stakes line, the week
head. **`display`: 1. `gold` objects: 1. `brand` fills: 1** (the primary; the dot, the rule and the
eyebrow are a dot, a rule and a glyph-tint, not fills). All four budgets hold.

---

## 3 · Anatomy — `event-callout` (one round each, closing Sunday)

`CalloutShape.isCallout(sessionCount:leagueId:field:)` routes here. **Same objects, two people.**

- **A · The title card**, `ceremony`, 306pt, **no contour** — a callout has no course, and §10.1's
  ladder has no fourth state, so the plate is simply the ceremony ground. This is the surface that
  proves the head does not need an image.
- The live eyebrow: dot + `agate` in `brand` — `LIVE · CLOSES SUNDAY`.
- **The two golfers are the title**: a **56pt `CSFace`** + `display` 34 for you, a **2pt `brand` rule
  across the full measure**, then the same pair for him. The rule between the two names is the whole
  graphic: two names, one live rule. (`s3` above and below the rule.)
- The dateline, `agate` at `ceremonyMut`, at the plate's foot: `ONE ROUND EACH · ANY COURSE · BEST BY SUN
  SEP 13` — `CalloutCopy.openLine`'s date through `LeagueDates.dowMonDay`, the same producer the
  covenant clock uses.
- **B · Three figures on one `brand` rule**, `s4` below: `+2.1` / `GALEN, FRI` · `—` / `YOU` · `3` /
  `DAYS LEFT`. `RoundCopy.signed(pvi)` produces the two figures; the empty side renders `—` in `mut`
  and **never a zero and never a guess**. The `DAYS LEFT` label is `brand`.
- **C · The stake**: `agate` `ON IT`, then the forfeit terms as the surface's **one serif sentence** —
  `story` 20 New York Regular, in quotation marks: *"Loser buys the beers."* A bet is exactly the
  sentence §1.4 reserves the serif for. Then `CalloutCopy.noPoints` verbatim in `body` 15 at `mut`:
  *"It's for the record — nothing scores toward a season."* Money never appears: a forfeit is words,
  and `forfeits` has no money column by rule (T-02 / D242).
- **D · The primary**: **Add my round**, ember, 50pt. When you have posted and he has not, it becomes
  secondary **See the receipt** and the ember leaves the button but not the dot.
- **E · The record**: a 1px `rule`, then the standing as a sentence in `body` 15 at `mut` — *"Galen
  leads it 4–3–1 since May."* — then the meetings printed on a **`CSLeaf`**: `DATE · WHERE · GALEN ·
  YOU`, dates in `columnS` at `leafMut`, courses in `name` 15 at `leafInk`, the figures in `figure` 20,
  and **the winning cell marked by a 2pt `gold` rule beneath it** (§9.8 — gold ink on bone is 1.68:1
  and is forbidden; the rule is how an earned figure is marked). A halve is marked on neither.
  The leaf is licensed because it holds a printed grid and it is the Record's table (§3.3).
  Source: the existing `head_to_head` read (`HeadToHead.Record`, `.Meeting`, `.Streak`) — no new fact.
- **F**: a tertiary link, **Every meeting** (no arrow at all: the 2px rule is the affordance, §5.2 —
  LINT-13), to `HeadToHeadPage`.

**Agate blocks: 4** — eyebrow, dateline, `ON IT`, the leaf's column-head row. **`gold`: the leaf's win
rules, counted as the table's one object** (§13 D-5). **`brand` fills: 1.**

**The three closing states** all keep this layout and swap B, C and D:
`CalloutCopy.youTookIt` / `.theyTookIt` / `.allSquare` become the **`lead` 28 serif** line where the
stake sat, the rule under B goes from `brand` to `ink`, the eyebrow drops its dot and reads
`FINAL · SUN SEP 13` in `mut`, and the primary becomes **Call him out again**. Nobody is ever named as
having refused (`CalloutCopy.declined` — a decline leaves no mark and this surface has no shape for it).

---

## 4 · Anatomy — `event-plan` (the plan sheet)

Presented, not pushed (the IA is unchanged): `rs` 24 top corners, `bg0` ground, a `rule` drag pill,
**`Close` as a tertiary link at `topBarTrailing` — the one dismiss verb** (§7.3; the shipped sheet says
"Done" in ember). The sheet opens at `.large`; the page behind it dims.

1. **`agate` eyebrow** `ON THE SCHEDULE`, `s4` below the Close row.
2. **`display` 34** — the plan's **name** (`scheduled_rounds.name`, D240): *SATURDAY AT PAPAGO*. With
   no name the head falls back to `ScheduleDates.long(play_on)` + the course, and the eyebrow carries
   the weekday — the surface never renders an empty title.
3. **`agate` dateline**, two lines: `SAT SEP 12 · PAPAGO, PHOENIX` / `MATCH PLAY · BLUE TEES`
   (`game` and the tee from the plan; the second line is omitted when both are absent).
4. **Four figures on one 2pt `ink` rule** — the countdown, the tee time, the field and the weather, all
   as one object: `6` / `DAYS OUT` · `7:40` / `TEE, A.M.` · `3` / `IN` · `71°` / `HIGH`.
   `figure` 27, tabular, `agateS` labels at `mut`. **The rule is `ink`, not `brand`** — a plan six days
   out is not live; it goes `brand` on the day (`ScheduleDates.when` == today).
   - **No weather:** the fourth cell is **removed and the rule shortens to three cells.** It never
     renders a dash, and the sheet never shows a blank panel (`ScheduleService.weather` returns nil on
     any miss, by design).
   - **No tee time:** the second cell is removed the same way; `TeeTime.format` returning "" is the
     test, and the plan reads three cells wide.
5. **The weather sentence** — a **17pt drawn sun glyph** at the icon family's 1.7pt stroke + `body` 15
   at `mut`: *"Mostly sunny · 9 mph after noon."* The shipped `Weather.line` producer embeds a literal
   `☀` and must drop it (§10): the glyph is drawn, and `icon` maps to a name in the drawn family.
6. **The worth line** — `RoundWorth.lines(worth)` verbatim, `body` 15 at `mut`. Renders nothing when
   the server sends no `worth` key (L-44).
7. **`CSSectionHead`** `WHO'S IN` + rule + `3 OF 4` at `mut`.
8. **The seats** — 50pt rows, one `rule` each, `CSFace` 38 · the name in **`social` 17 (title case — a
   person in a social row is not the board, §1.3)** · the host's `HOST` in `agateS` at `mut` · the
   answer right-flush in `agate` 12: `IN` in `ink`, `ASKED` in `mut`, `OUT` in `mut`.
   **`asked` is the state of the invitation, never a verdict on the man** (`PlanIdentity` rule 2) — and
   there is no chase control on this surface, by rule.
9. **The stake** — `agate` `ON IT` + `body` 17 in `ink`. Body, not serif: the plan is the quieter of
   the two forfeit surfaces, and the serif is spent on the callout.
10. **The actions — two marks, not five.** §7.1 is *one primary, one secondary, the rest behind a
    door*, and brief §18 names five equally prominent buttons as the anti-pattern. So: one primary
    **I'm in** (ember, flex 1.35), one secondary **Maybe** (`bg2`, flex 1), and **"Can't make it"** as
    a `mut` **text link with no rule** beneath them — a decline is not a control the sheet should
    advertise. **`Send the link` moves to the sheet's one trailing toolbar action** (§12.2), and
    **dismissal is the drag pill plus a `mut` `Close`** in the toolbar, with a 1px rule and **no
    ember** (§7.1's toolbar tier). The first draft put five actions at one foot, three of them wearing
    a rule and two of them ember. The shipped middle button is a **gold** fill, which LINT-11 fails
    outright.
    Not the host and not tagged: the three RSVP controls are replaced by a single secondary
    **Ask for a seat**, which writes nothing to the tee sheet (IOS-032 / D69 stand unchanged).

**Agate blocks: 4** — the eyebrow, the dateline, `WHO'S IN`, `ON IT`. **`gold`: 0** — nothing on a plan
has been earned, and a surface with no gold is a correct surface, not an unfinished one.

---

## 5 · Anatomy — `event-setup` (the intent sheet, re-clothed)

`csFittedSheet(540, large: true)` is kept exactly. Nothing about the five sentences, their glosses,
their order, the ember on the first, the modifier below a rule, or the footer door is re-argued — all
of it is `StartIntent`, a producer both clients share.

1. Drag pill, then **`Close`** at the trailing edge (the shipped sheet has no dismiss verb at all here
   — it is gesture-only).
2. **The question in `lead` 28, New York Bold** — `StartIntent.title`, *"What do you want to do?"*
   This is the surface's one serif appearance, and it is the right one: a question the reader is meant
   to slow down for. It replaces `CSFont.sentenceBold` (SF 17), which is the audit's finding 7 in one
   line — the product's most consequential fork was set in the system's voice.
3. **`agate` 12 at `mut`** — `PICK THE ONE THAT SOUNDS LIKE YOU`. One agate block, the only one.
4. **Four peer rows**, each `s3`+`s3` vertical padding over a 1px `rule`, ≥56pt: the line in `social`
   17 (title case) and the gloss in `body` 15 at `mut`. **The first line is `brand`** — "Play with my
   friends" is the live door — and no other line takes a colour.
5. **A 2pt `ink` heavy rule**, then the modifier row (`Put money on it`). The heavy rule is what says
   *this one is different*; the shipped sheet uses a second hairline a few points from the first, which
   its own comment records as having read as a mistake.
6. **The footer door** — `I have a code` as a tertiary link in `nameS` at `mut` with a **drawn** arrow.

`WhenForkSheet` takes the same anatomy at `csFittedSheet(260)`: the question in `lead` 28, two rows,
`Right now` in `brand`.

---

## 6 · The other event kinds this surface must clothe

**6.1 The Major** (`MajorRoomView`). Same title card; the eyebrow is `MajorMath.statusChip` (`OPENS
SATURDAY` · `LIVE · 2D LEFT` · `THE FINAL DAY` · `WAITING TO SETTLE` · `NAME TAKES THE JUG`), which is
already plain English after D252 and needs no rewording. Section B becomes **two cells** — the leading
gross and the days left — and the board below is a real leaderboard, so it **does** take `CSSlat` and
the 44pt rank rail: `POS · face · name/sub · THRU · NET`, `THRU` in place of `GAP` (§15.5), the net in
`figure` 27 right-flush. `MajorJugCard` is deleted; a won jug is the **`CSSlot`** (a 24pt `gold` field
with `panelInk` agate) on the champion's row, and that is the surface's one gold object once the pot is
paid. An exhibition card renders with an unpainted rail and `EXHIBITION` in its agate sub-line.

**6.2 The complete event.** The eyebrow loses its dot and reads `FINAL · SAT SEP 26` in `mut`; the
shared rule under section B goes `ink`; **the winner's rail (Major) or the winning team's cell (Ryder)
paints `gold`, and the pot figure goes to `ink`** — because the pot has been paid and the *result* is
now the earned thing. That keeps exactly one gold object per viewport in both states and makes "gold
means earned" true across time, not just across space.

**6.3 Forming / setup.** No score to show, so section B is replaced by the **empty state** (§7.2) and
the primary is **Invite players**. The title card is unchanged — a forming event still gets its
graphic, which is most of the reason anyone joins one.

---

## 7 · Every state

**7.1 Loading** — the destination's own geometry, redacted (§13.2). The ceremony plate paints
immediately (it needs only `events.name`, which the chip that opened the room already had); the title
sets; the field rail draws six discs in `bg2` at `p` 3; section B draws its three cells with `bg2`
blocks at real-length placeholder widths and **the rule already drawn**; the clash rows draw their
rules and their faces. `.redacted(reason: .placeholder)`. **No spinner anywhere in content** — the
shipped `CSFine("No event loaded.")` is deleted (LINT-22).

**7.2 Empty** — three of them, each with §13.1's five parts and a **required** door:
| Where | Object · eyebrow · headline (`lead`) · fact (`body` 15) · door |
|---|---|
| No pairings yet | a drawn empty rail, 64pt · `WEEK 1` · *"The week hasn't been paired."* · *"Both teams need golfers before pairings can be drawn."* · **Invite players** (organiser) / **See the field** (everyone else) |
| No field | a drawn `schedule-sheet`, 76pt · `THE FIELD` · *"Nobody is in it yet."* · *"An event needs two sides."* · **Invite players** |
| No clash for you this week | a drawn empty rail, 56pt · `YOUR WEEK` · *"Three pairings are running and none of them is yours."* · *"You are back in week 3."* · **See the board** |
Every headline is **a fact about the world, never the golfer's omission** — *"The week hasn't been
paired"*, not *"You haven't set pairings yet."* A number is present in each (a week number, a count).

**7.3 Error and stale** — keep what is on screen (§13.3). A failed refresh over a room the phone
already has renders the room under an `agate` dateline `AS OF FRI 6:12 PM · OFFLINE` at `mut`, **with
nothing disabled**. Only a room with nothing cached speaks: one `lead` line — *"The room didn't
load."* — one `body` line, and **Try again** as the primary. `EventRoomScreen`'s
`CSCard(spine: cs.neg)` goes with the card. Server text renders verbatim when it is written for
humans; never a raw code.

**7.4 Disabled and busy** — a disabled primary is `bg1` + `mut` and **never ember** (§7.1). Busy
replaces the label with **three mono dots that tally**, never a spinner. `model.isBusy("resolve-…")`
already keys per-action and is kept.

**7.5 AX3** (§16.3, and this is stated as a layout, not a principle):
| Block | AX1 | AX3 |
|---|---|---|
| The title card | as default; the display grows to its ×1.6 cap | the **field rail scrolls horizontally** inside the plate rather than shrinking the discs; the dateline stacks to three lines; the plate grows the page |
| Section B (three cells on a rule) | **2 + 1**: the two team cells share the rule, the clock drops to its own rule beneath | a **stacked list** — each cell a row with the `agate` label leading and the `figure` trailing, each on its own 2pt rule. The rule's metal is preserved per row |
| The clash row | as default | the two names stack (yours first), the middle word becomes a leading `agate` line, and the two figures sit under their own names as two rows. `minHeight` becomes intrinsic. **One VoiceOver element throughout** |
| The plan's four figures | 2 × 2, each pair on its own rule | a stacked list, label leading, figure trailing |
| The intent sheet | fitted 540 | **the whole page** (`csFittedSheet(_:large:)` already does this — it is a "what works" and is kept verbatim) |
| The section head | as default | the count wraps under the label; the rule stays |
Reflow is driven by the **measured advance** of the cells' own characters (the `MeStripLayout` model),
never by a device breakpoint. `ViewThatFits` for the three-cell → stacked transition.

**7.6 Long names.** One policy, product-wide: **tail ellipsis at the column edge**, `min-width: 0`,
`lineLimit(1)` — the clash row's two name columns, the field rail's `agateS` names (which truncate to
the first name, as `CSBands.fn1` already produces), the seat rows and the board's slats. A team name
longer than its third of the measure truncates in section B's label and is read in full by VoiceOver.
The title itself is the one thing that **wraps** (to three lines, then truncates) — it is a display
headline, not a column.

**7.7 No photo, no course, no image at all.** There is **no photograph on this surface, ever** — an
event is not a place and the product has no picture of one. The head's image ladder is: a contour
seeded from the event's course if it has one; **otherwise nothing** (§10.2's "a course with neither
shows no thumbnail at all", applied to a plate). `event-callout` is the rendered proof that the bare
ceremony ground is not a degraded state. **No fabricated faces anywhere**; `CSFace` is the only path,
and a golfer who chose nothing draws initials on their pigment.

---

## 8 · Motion (§11)

| Moment | What happens |
|---|---|
| **Opening the room** | the title card **wipes** from the left edge over 220ms on `snap`; the title's two lines arrive at a 60ms stagger; the field's six discs wipe in left to right at 40ms. The score's three figures **tally** from 0 over 340ms on `snap` and the `brand` rule draws left to right underneath them as they land. This is §11.1's "a board graphic arrives; it does not fade in", at the size of the moment |
| **A clash resolves** (realtime) | the row's middle word crossfades `vs` → `def.`, the losing name steps to `mut`, and the two figures **tally**. The team cell that gained the point tallies its half-point rider. `.impact(.light)` **only if it was your clash** |
| **The taunt lands** (C10) | the opponent's figure arcs in, squashes at touch and settles — the existing `EventRiseModifier`, kept, but its tint moves from the deleted `cs.warm` to `ink` (the arrival is the signal; a fourth orange was never one) |
| **A callout closes** | the eyebrow's dot fades out, the `brand` rule under section B crossfades to `ink`, and the result sentence wipes in as `lead`. No confetti |
| **The event completes** | **the takeover band** — the ceremony plate expands to full-bleed, the `display` lines arrive at a 60ms stagger, the final figure tallies, the winner's `CSSlot` seals gold and the medallion stamps. `.success`. This is the biggest motion in the product and it belongs here (§11.3) |
| **RSVP** | the seat's answer word crossfades and the `IN` count in the section head tallies. `.selection`. Nothing else on the row moves |
`accessibilityReduceMotion` resolves both curves to `nil` and every rest frame is the finished state.

---

## 9 · Producers and copy consumed unchanged

Every string on these five artboards is an existing producer, re-cased by a **role** (never
`.uppercased()` — LINT-14):

`RyderMath.statusChip` · `.clinchLine` · `.ruleSentence` · `.sessionHeader` · `.mid` · `.chip` ·
`.nagLine` · `.record` · `.evHalf` · `.seriesLine` · `.tauntLabel` · `.tauntToast` · `.pairingsToast` ·
`.scrapQuestion` · `RyderMath.target` (P · M · clinch) ·
`MajorMath.facts` · `.statusChip` · `.cardsLine` · `.noCardsLine` · `.stillToPost` · `.finePrint` ·
`.lineageLine` · `.whenLine` ·
`EventDates.window` · `.daysUntil` · `.weekdayMonthDay` ·
`CalloutCopy.openLine` · `.openLineWithStake` · `.theyPosted` · `.youTookIt` · `.theyTookIt` ·
`.allSquare` · `.noPoints` · `.received` · `.receivedSub` · `.accept` · `.decline` · `.declined` ·
`CalloutShape.isCallout` · `CalloutLength` (title, gloss, order) ·
`StartIntent` (five lines, five glosses, order, `modifierLine`, `codeDoor`, the banned-noun list) ·
`StartIntent.WhenFork` ·
`SchedulePlan` / `PlanSeat` (`name`, `game`, `tee_time`, `rsvp[]`, `rsvp_in`, `my_rsvp`, `tagged_names`,
`withLine`, `hostFirstName`, `courseShort`) · `TeeTime.format` / `.chip` · `ScheduleDates.long` /
`.when` · `RoundWorth.lines` · `Weather` (`hi`, `wind`, `summary`) ·
`HeadToHead.Record` / `.Meeting` / `.Streak` / `RivalryLead` ·
`RoundCopy.signed` · `CSBands.fn1` · `MoneyCopy.ledger` · `BoardText.easeCaps` · `BoardText.humanError`.

**Three producer edits, none of them a new fact:**
1. `Weather.line` and `Weather.glance` must **drop the literal `☀`** (§5.3's emoji ban, LINT-12). The glyph
   is drawn from `Weather.icon`; the producer returns `"71° Mostly sunny · 9mph"`.
2. `RyderMath.statusChip` returns `"Live · wk 2/3"` and `"NAME TAKES THE CUP"` — one is sentence case
   with an abbreviation, the other is `.uppercased()` inside the producer. **Case belongs to the role**
   (§1.3): the producer should return `"Live · week 2 of 3"` and `"Saguaros take the cup"`, and the
   `agate` role uppercases. Same for `clinchLine`, `sessionHeader` and `seriesLine`, all of which
   currently ship pre-uppercased strings.
3. `EventHeaderRow`'s status chip is drawn in **`cs.gold`** for every status including `Forming`. Gold
   is earned-only; the chip's colour moves to the role (`brand` when live, `mut` otherwise).

---

## 10 · New data

**One column, and it is the only thing on this surface the server cannot answer today.**

`events` carries `id, name, created_by, league_id, kind, status, starts_on, session_count,
session_weeks, draw_rule, winner_team_id, buy_in, pot_split, lineage_id, tz` — **and no course.**
Brief §14 asks an event graphic for its *course*. Two honest options, and the design works either way:

- **Ship without it.** The dateline reads `SUN SEP 6 – SAT SEP 26 · SIX IN THE FIELD`, the contour is
  absent, and the head is the callout's bare ceremony plate. Nothing else changes. **This is the
  default if the column is refused**, and it is what the `event-callout` artboard already renders.
- **Add `events.course_id text null` + `events.course_label text null`** (FK-by-convention to
  `api_courses`, exactly as `scheduled_rounds` carries them), set at setup from the same course search
  the declare sheet uses. It buys the dateline's first line **and** the contour's seed — the only image
  this surface has.

Nothing else is new: the field, the weeks, the clashes, the numbers to beat, the scoreboard, the pot,
the split, the seats, the tee time, the weather and the head-to-head record are all produced today.
`head_to_head` is an **additional read** in the callout room, not a new fact.

---

## 11 · The web desk (§14, ruling R-C)

On the desk the title card runs the full width of the body column at 300pt with the contour cropped
harder and the field rail spaced across it at 44pt discs with full first names; `display` goes to 42
and the score's figures to 56. The body splits `1fr + 340`: **left** is the week — the clash rows at
64pt with a sixth column added (`THRU`), each row hover-lifting its ground to `bg1` and its faces
ringed, with a focus twin as a 2px `brand` outline on the whole row; **right** is the rail — the two
rosters with `W-L-H` as a printed table, the series line, the pot with its ledger line, and the event
board's engine posts as a dated column. `↑`/`↓` move between clashes, `→` opens a clash's receipt, `Esc`
closes, and the board and the settlement card both carry print stylesheets — the archive test made
functional. The plan sheet becomes a right-hand panel rather than a modal, and the intent sheet becomes
a five-row list in the sidebar's `New` popover; neither is redesigned, only re-columned.

---

## 12 · Accessibility floor

Contrast, from §2.8 and computed for this surface's pairs: `ceremonyInk` on `ceremony` **17.51**,
`brand`(dark) on `ceremony` **5.63**, `mut` on `ceremony` **6.9**, `ink` on `bg0` **16.05 / 15.49**,
`mut` on `bg0` **7.07 / 5.85**, `gold` on `bg0` **8.85 / 5.64**, `bg0` on `brand` **5.27 / 5.39**,
`leafInk` on `leaf` **14.44 / 16.61**, `leafMut` on `leaf` **5.42 / 6.04**. `dim` and `rule` carry no
words anywhere on this surface. Nothing renders below 11pt. Every tap target is ≥44 (`rail` = 44 by
construction; the clash row is 56, the seat row 50, the primary 50, the tertiary links carry a 44pt hit
slop). Colour is never the only channel: a clash's result is carried by the word (`def.` / `halved`) and
by the loser's tone, not by hue; a squad is a rule **plus** the team name in agate; a win in the record
leaf is a **rule**, not a colour; `IN` / `ASKED` / `OUT` are words. Every drawn mark carries an
accessibility label in the product's voice, and every duel row and every seat row is one VoiceOver
element.

---

## 13 · Deviations from `UI_SYSTEM`, recorded for the refuters

**D-1 · RESOLVED in the system.** This spec raised it as a deviation: the ceremony ground needs its own
metals and the palette had none, so the artboards were painting dark-room ember and gold on
`ceremony` — values no token could produce, at 3.19:1 and 3.05:1 in light. `UI_SYSTEM` §2.1 and §2.8
now carry a full **ceremony ramp** (`ceremonyMut` 7.71 · `ceremonyBrand` 5.75 · `ceremonyGold` 9.65 ·
`ceremonyPos` 8.92 · `ceremonyCool` 5.63 · `ceremonySq0–3`), pinned to the dark values **in both
themes**, under the rule *"the light theme does not reach inside a physical object."* This surface
uses those names throughout; **`cerMut` is struck** — its name is `ceremonyMut`.

**D-2 · RESOLVED in the system.** §1.5 now budgets **ten tracked-caps agate lines** per viewport and
counts every one of them, rather than four "blocks" with the dense positions exempted. This surface's
head folds its three metadata blocks into **one two-line dateline** anyway, because that is better
typography; the budget is no longer the reason.

**D-3 · The ledger line is not on this viewport.** §9.5 says it renders "beneath every surface that
shows a money figure". The event's pot appears on the first screen; the ledger line at `body` 15 is two
lines and would push the primary and the first duel below the fold. It renders under the pot on the
event's money pane, one scroll down. Either the rule wants a "once per scroll view" clause or this
surface is in breach.

**D-4 · A duel row refuses the rank rail.** §0.2 says "every ranked list in the product starts with
it", and §18 maps `CSSlat` to every table row. A duel is a pairing, not a rank — there is no position
to put in the slot, and a rail painted with a half-point would make the rail mean two things. So the
duel is a 56pt two-line row with a top rule and **no rail**. The Major's leaderboard and the event's
own board do take the rail; only the duel does not.

**D-5 · The callout's record leaf carries two gold rules, and the gold budget is one object per
viewport.** §9.8 explicitly marks *each* won finish with a gold rule; §2.4 counts hue, not tokens. This
surface reads the record table as **one gold object** the way §15.4 whitelists the season's
leader-plus-pot pair. It needs the same explicit whitelist, or §9.8 needs a "one row" clause.

**D-6 · A live event's leader takes no gold.** §9.1 paints the rail `gold` "when the position was
earned (1st)". On a live event nothing is earned yet, so the design leaves every rail unpainted (bone
for yours) while play is open and paints gold only at `complete` (§6.2). This is stricter than §9.1 and
I believe it is what "earned only" actually means; a refuter may read it as a contradiction.

**D-7 · The Ryder's session pairings are a printed grid, and the leaf's licence does not cover them.**
§3.3's licence list is explicit and closed. A week's pairings are exactly the kind of grid a scorer
would print, but they are not on the list, so they are rendered as rows on the page's own ground. If
the licence is meant to be extensible, this is the first case.

**D-8 · The plan sheet stays a sheet.** §7.3 says objects are pushed and actions are presented; a plan
with a roster, a stake and comments is closer to an object than to an action. Changing it is an IA
decision the UX phase did not make, so the design obeys the shipped IA and puts the title card *inside*
the sheet. Flagged rather than taken.

**D-9 · Off-token gaps in the mockup.** The artboards use a handful of optical values (16, 18, 11, 9)
that are not in the `space` group; every one is stated in tokens in §2–§5 and the build takes the token
(`s2`/`s3`/`s4`), which will shift some blocks by 1–4pt from the render. LINT-06 is the enforcement.

### Known imperfections in the renders, stated rather than iterated a fourth time

(a) **The half-point.** `3½` is drawn from IBM Plex Sans Condensed's pre-composed vulgar fraction and
still reads as a small diagonal at 40pt even with the rider. On iOS the build should compose it — the
whole number in `figure` 40 and a separate `½` at 0.56em on a raised baseline — rather than passing
`RyderMath.evHalf`'s single string to one `Text`. It is the weakest typographic moment in the set.
(b) On `event-callout` the **Every meeting** link sits under the 28pt scroll fade at the default
size; on a device the surface scrolls and it clears.
(c) On `event-ryder-live` and `event-light` the third duel is cut by the fade and its figures are below
the fold. That is the intended behaviour of a scrolling board — the fade is the signal — but it means
the artboard does not show all three sets of numbers.
(d) `event-plan` and `event-setup` render the page behind them as a dimmed stand-in; the real surfaces
behind those sheets are Home and Compete.
(e) The two 56pt discs on `event-callout` had to be pushed onto non-adjacent pigments to be told apart.
`pig[hash(id) % 6]` can seat two golfers on neighbouring warm pigments, and at credential scale the
pigment stops doing identity work — **the marker must carry it**, which is an argument for finishing
§6.2's optical normalisation before the pigments are trusted.


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it, and it is the second-weakest row.** Instantly 1/3 · looks like Cup
Season 3/3 · premium 2/3 · template 0/3 · proud to post 3/3 · belongs 2/3. Median **7.3**, with
**spacing 6** and **consistency 6**. Two reviewers marked it "not instantly legible" and all three
gave the same reason.

**1 · The side is carried by the roster (§15.5a).** blind-2: *"a Ryder screen where you cannot tell
teams apart has failed at its one job."* Sides were two 14 × 4pt colour ticks — which also **collided
with the date line**, filed separately by two reviewers — while the six roster discs beneath were
coloured by personal marker. The roster is now **two named groups**, each under a full-width 3pt rule
in its squad colour with the squad name beneath, and **every disc carries a 2.5pt ring in its squad
colour** while keeping its own pigment and glyph. blind-3 called this "one change, three problems",
and it is: the key goes, the collision goes, and the screen's one job is done at a glance. The hero
grew 26pt to give the roster its own row.

**2 · The marker is frozen (§6.2a).** Galen was brown in `event-ryder-live` and maroon in
`event-light` — the light hero had been authored with literal hexes rather than tokens, and two
golfers' pigments were transposed between themes. Two reviewers filed it as an identity failure
("marker colour is identity and must not vary with theme"). The whole cast is now resolved from one
table across all 135 disc sites in the deck.

**3 · A countdown is not a score (§15.5a).** `3½`, `2½` and `2 DAYS LEFT` sat under one ember rule "as
if they were one class of number". The rail is the two side scores; the deadline is in the live
eyebrow — `LIVE · WEEK 2 OF 3 · 2 DAYS LEFT` — with the other time facts.

**4 · One date line, and no sheared row (§13.2a).** The strap stated the range and the field size on
one line under the title, colliding with the team keys; it now states the course and the range, and
the field size belongs to the roster. The pairing list's third row is a clean half-scroll under the
fade rather than a row cut at `+2.1 / −0.4`.

**5 · `event-setup` was the least designed screen in the deck, and it was the front door.** Two
reviewers filed the same three things and the copy survived all of them intact. The first option was
tinted `brand` while nothing was selected — read as "already selected" — and is now set at the same
weight as its peers (§16A.6). Every option is a two-line row with a chevron at 44pt+, which gives the
options the weight blind-1 asked for. *"Put money on it"* was a fifth peer option that is not a peer
at all; it is now a modifier line — *Any of the four can carry a pot. You add it on the next screen.*
And **`I HAVE A CODE` was the smallest thing on the sheet while being the highest-frequency act an
invited golfer performs** (blind-3); it is now a full row at option weight, below a hairline, with its
own sub-line.

**6 · The ledger sentence is gone from this surface (§16A.1).**
