# HOME — the surface spec

**Surface** Home · the dispatch, the ME strip, the five feed weights, the wire, the doors
**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 (design; nothing is built)
**Obeys** `UI_SYSTEM.md` in full — every token, role, radius, spacing step and lint below is its.
**Answers** `BRIEF.md` §7 (the five weights), §8, §16, §17, §31, §35 · `UI_AUDIT.md` §2.3 (H-01…H-23,
score 5.1) and problems 1, 2, 3, 5, 7, 8, 10
**Clothes** `COMPONENT_SYSTEM.md` P-1 (story card), P-2 (dispatch row), P-3 (wire row), P-8 (intent
door), P-11 (empty), P-12 (section head), P-15 (ME strip)
**Mockups** `mockups/home.html` → `mockups/renders/home/` — `home-live`, `home-quiet`, `home-new`,
`home-light`, `home-feed-weights`

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · What Home is now, in one paragraph

**Home is the front page of an edition, not a stack of cards.** It opens with a masthead and a
dateline, states one thing in the serif, prints the four facts that are mine on a single rule, and
then runs a wire whose items are deliberately unequal — a block, a photograph, an editorial row, a
takeover band, a quiet line. There is no card and no border anywhere on it. Its character is
**rhythm**: rule, type, photograph, rule, quiet line, so scrolling reads as a rundown rather than a
scroll of tiles. The audit's finding that "the content of a premium feed is already here; the
packaging is not" is the whole design brief for this surface: **every sentence on Home is kept
verbatim from the producers that already write it, and only the packaging changes.**

The five things a golfer must get in one second, in this order: **what is closing · where I stand ·
what I owe · what my people did · what I can start.**

---

## 1 · ANATOMY, top to bottom

Spacing is named from `UI_SYSTEM` §4 (`s1` 4 · `s2` 8 · `s3` 12 · `s4` 20 · `s5` 32 · `s6` 52 ·
`gutter` 20 · `rail` 44 · `hair` 1). **No other number may appear in a padding or `spacing:`
position** (lint LINT-06). The measure is 362pt at 402pt wide; everything hangs off the same left edge.

### 1.1 The masthead — `CSMasthead` (§12.3)

| Element | Role | Token | Geometry |
|---|---|---|---|
| the wordmark | `display` at **30** (§12.3's stated size, not 34) | `ink` | flush left at `gutter` |
| the dateline | `agate` 12 | `mut` | flush right, baseline-aligned to the wordmark |
| the rule | the **2pt heavy rule** in `ink` | `ink` | full measure, `s2` below the wordmark |

No ember tick, **no sky wash, no second ground** — `CSLookSky`'s accent wash over the top 260pt is
deleted (§2.2, audit F-04): the band the system clock sits in is now the same colour as the page
under it. The masthead is Home's opening object and appears on no other surface. Its dateline is part
of the object and is **not** counted against the four-agate-block budget (§1.5), the same exemption
the tab bar's five labels have.

**Stale/offline** rewrites the dateline in place — `AS OF FRI 6:12 PM · OFFLINE`, `agate` at `mut`
(§13.3). Nothing else on the page changes and no action is disabled.

### 1.2 The lead — weight 1, the competition moment (P-1, `CSStoryCard`)

`s4` below the masthead rule. Two columns, `s4` apart: the sentence left, the figure right.

```
● LIVE · THE CLASH CLOSES TODAY              THE FELLAS     agate/brand + agate/mut
You moved to 2nd.                            ┌──────────┐   lead · New York Bold 28
Galen is four ahead. One counting round      │   2ND    │   body 17 · mut
in the top band closes it.                   │ OF EIGHT │   panel 84×84, radius p 3
PUT A ROUND ON THE SCHEDULE →                └──────────┘   name 15 + 2pt brand rule
                                               ▲ 2
                                             ──────────      2pt ink rule
                                               SPOTS         agateS · mut
```

| Element | Role | Token | Rule |
|---|---|---|---|
| the live dot | 7pt disc | `brand` | present **only** while a clock is running |
| the eyebrow | `agate` 12 | `brand` when live, `mut` otherwise | one line, never wraps; the producer's `eyebrow`, truncated at the tail |
| the league tag | `agate` 12 | `mut` | flush right on the eyebrow's baseline |
| the headline | **`lead`** — New York Bold 28, sentence case | `ink` | the producer's `headline`, verbatim. Never truncates. **The one serif appearance on the viewport** (§1.4) |
| the standfirst | `body` 17 | `mut` | the producer's `standfirst`, verbatim. ≤3 lines |
| the door | tertiary link — `name` 15 caps, **2px `brand` rule** beneath, 44pt target, a **drawn** arrow glyph | `ink` + `brand` | the producer's `action` + `route`. Sits in the **left column, under the standfirst** — the door belongs to the sentence, not to the figure |
| the panel | **84 × 84**, radius `p` 3, no border, no shadow | `panel` fill / `panelInk` ink | one `figure` 40 with the ordinal rider at `max(11, numeral × 0.4)` (§1.6), one `agateS` unit label in `panelMut`. **Never a sentence** (LINT-19) |
| the movement | a **rule-and-figure**: drawn triangle 9×7 in `pos` (up) / inverted in `cool` (down) / a 9×2 `rule` bar (held), the numeral in `figure` 20 `ink`, on a **2pt `ink` rule** the width of the column, `SPOTS` in `agateS` `mut` beneath | — | §9.3. No field, no pill, no tint. `▼` means one thing only: you fell |

**Where the panel's number comes from** — the dispatch item carries no figure. The client joins
`item.leagueId` → `me.memberships[].standing` and reads `rank` / `of` / `prev_rank`. That is a
client-side join of two facts the payload already ships; it is not new data.

**When there is no figure** (an invite, a friend request, a first-round opportunity) the right column
is absent, the sentence takes the full measure, and the block is type alone. **A panel is never
invented to fill the column.**

**This answers audit H-01 directly**: the lead and a deck row are no longer the same object at two
padding values, because the deck of cards is deleted (§1.4 below) and the lead is the only serif and
the only panel above the wire.

### 1.3 The ME strip — `CSFactStrip` (P-15, §9.6)

`s5` below the lead. **Four figures on one 2pt `ink` rule**, the labels hanging beneath, the standing
line in agate under the block, the ledger line under that. No `bg1`, no border, no radius, no tile,
no grid — it is a line of type on the page's own ground.

| Element | Role | Token | Rule |
|---|---|---|---|
| the values | `figure` 27, **tabular** | `ink` | 2–4 cells, equal columns, `s1` above the rule |
| the rule | 2pt heavy rule | `ink` | full measure |
| the labels | `agateS` 11 | `mut` | `s1` below the rule; from the terminology table, one word for one thing |
| the standing line | `agate` 12 | `mut` | `s3` below, **and it yields to the lead block.** The full `LEAGUE · RANK · GAP` form — `THE FELLAS · 2ND OF 8 · 4 BACK OF GALEN` — renders only in the states with **no lead block** (the quiet day, between seasons), where it is the screen's only competitive statement and it **names the rival**, which is §13's "important matchups emphasised" done with type. When a lead block is present, the lead owns the rank, the gap and the movement (it is closest to the action), and the standing line drops to the league plus one fact the lead does not carry: `THE FELLAS · 26 WEEKS · 4 TO PLAY`. *D201's one-fact-one-place: if two elements can both say it, the one further from the action goes silent — and the first draft said the rank three times, the gap twice, the field size twice and the league twice in one viewport.* |
| the ledger line | `body` 15 | `mut` | `s2` below, **verbatim from `MoneyCopy.ledger` / `CS_LEDGER`**, rendered only when a money figure is present (§9.5) |

**Two rules that kill audit findings at the source:**

1. **A slot with no figure is absent.** The strip renders 2, 3 or 4 cells. It never prints a dash, a
   guess, or a verb in a value seat — `PLAN ONE` in the value column is H-09 and is gone. The act to
   set a tee time lives in the floor. `STARTER` and `BUILDING` are the **label**, never the value
   (§9.9).
2. **No slot's fact appears anywhere else on the viewport.** The lead and the wire are ranked first
   and publish `suppress`; the strip yields to them, exactly as `HomeView.swift` already sequences it
   (lead → deck → strip, one way, no negotiation).

`STILL OWE` is absent at $0. Each cell is a door to its receipt (L-01) at a 44pt target.

### 1.4 The wire — `THE WIRE`, and the five weights

`s5` below the ledger line. Section head: `agate` 12 `mut` + a 1px `rule` running to the margin
(`CSSectionHead`). **The deck of dispatch cards is deleted as a visual object**: items 2–5 no longer
render as four smaller copies of the lead. Ranked items that are not the lead enter the wire in date
order at the weight their kind earns, so Home has **one ranked object and one feed**, not two stacks.

> **The grammar, in one line: five weights, one page ground, no boxes.** What differs between weights
> is *how much of the page an item is allowed to take* and *what kind of object leads it* — a serif
> sentence, a photograph, a drawing, a band, or a day marker. Nothing differs in colour language,
> radius, or container, because there are no containers.

| # | Weight | Height | The object that leads | Type | Figure | Ground |
|---|---|---|---|---|---|---|
| **1** | **competition moment** — big | ~150–190pt | the **serif sentence** with a bone panel | `agate` eyebrow · `lead` 28 · `body` 17 · link | panel 84 + movement rule-and-figure | the page |
| **2** | **friend round** — social | **full-bleed 2.1:1 photo band**, 154–190pt | the **face** (38pt disc) over the photograph | `social` 17 (title case) · `bodyS` 15 | bone panel 60–64 with `GROSS` | the photograph + the one measured scrim |
| **3** | **course discovery** — editorial | 68–84pt slat | the **drawn card** thumbnail, 58 | `name` 17 caps · `agateS` sub-line | `figure` 20 in `gold` + a drawn star rail | the page, 1px `rule` on top |
| **4** | **season moment** — dramatic | 126–142pt **full-bleed band** | the **ceremony ground** with the course contour at `a24` | `agate`/`brand` eyebrow · `display` 31–34 · `agateS` metadata | none — the words are the object | `ceremony` `#0A0E0C` in **both** themes |
| **5** | **minor activity** — quiet | 44pt row | a **day marker** in `agateS` **`mut`** — never `dim`, which is 3.15 / 2.89 and may not carry a word (§16.1); the marker takes its quietness from size, column position and the row's rule | `bodyS` 15 `mut`, one line | none | the page, 1px `rule` on top |

Rendered as a key in `home-feed-weights`; weights 1, 2, 3 and 5 appear in place in `home-live`.

**Weight 2, in full.** Face 38 disc (`CSFace`, pigment keyed to the golfer's id, 1px inset ring) at
the band's lower left; the golfer's name in `social` (title case — *a person in a wire row is never
caps*, §1.3); the round sentence in `bodyS` 15; the gross in a bone panel at the trailing edge.
`CSPhotoScrim`'s settle/plate split is the **only** scrim; the panel over a photograph is the **bone**
panel in both themes (§3.2). Beneath the band, a 34pt reaction line: the used reactions at `column`
12 with their counts and the relative day flush right. **Emoji appear here and nowhere else on Home**
(§5.3).

**Weight 2 with no photograph** — the majority case today, and it must be beautiful. The band becomes
a **68pt slat** on the page's ground with a 1px `rule` on top: face 38, `social` name, `bodyS`
sentence, and the gross as a **right-flush rule-and-figure** (`figure` 27, 2pt `ink` rule, `GROSS` in
`agateS`). No placeholder image, no gradient wash, no tinted block. A wash standing in for a
photograph is forbidden outright (§10.1).

**Weight 3, in full.** The thumbnail is the **drawn card** generated from `api_course_holes` (eighteen
bars, height by yardage, weight by par) — never the contour, which is illegible at ≤64pt (§10.2). At
thumbnail scale the drawn card renders **entirely in `rule`**: the gold `#1`-stroke bar is a
plate-scale feature only, so that the rating stays the viewport's **one** gold object (LINT-17). A course
with neither a card nor a photo shows **no thumbnail at all** — the left column collapses and the name
sets flush to the margin.

**Weight 4, in full.** The takeover band is the biggest static object on Home and belongs to the
biggest moment (a Cup Final opening, a season wrapping). It is a full-bleed band on the `ceremony`
ground with `ceremonyInk` type in **both** themes — a ceremony is a physical object and does not
change colour when the room does. The contour plot sits behind at `a24`, cropped hard off its own
centre, with one `brand` dot on the hardest hole. Never more than one per viewport.

**Buckets.** `HomeBuckets`' Today / This week / Earlier survive as **day markers on the rows
themselves** (weight 5's leading `agateS`), not as three more section heads. This is the fix for the
audit's "four 44pt *N league notes* rows with chevrons — a database's GROUP BY rendered as a feed":
league notes are weight 5, one line each, folded to at most two per league per day.

### 1.5 The floor — the four doors (P-8, `CSIntentDoor`)

The floor is on **every** Home, in every state, including brand-new, offline and failed (L-25, D94).
It is a 1px `rule` and then four rule-separated **44pt rows**:

| Element | Role | Token |
|---|---|---|
| the verb | `nameS` 15 caps | `ink` |
| the gloss | `agateS` 11, flush right | `mut` |
| row | 44pt, `gutter` padding, 1px `rule` between (inset to the measure) | — |

`ADD MY ROUND` · *One you already played* — `START SOMETHING` · *A season, a weekend, a clash* —
`JOIN WITH A CODE` · *Someone sent you one* — `FIND GOLFERS` · *The people you play with*.

**This replaces the shipped four tracked-caps text links in four ragged two-line columns** (H-07,
§18's "buttons that look like links"), and it also honours `UI_SYSTEM` §0.5's rejection of "four
tracked-caps actions in a row as Home's foot": these are rows with glosses, not four peers competing
for one baseline, and at most one of them is ever lit.

> **The floor never repeats the viewport's primary.** If the lead or an empty block already offers
> `ADD MY ROUND` as the screen's primary, the floor **suppresses that door** and collapses to a single
> row — `SOMETHING ELSE` · *A season, a weekend, a clash* — which pushes the four. On a Home with no
> primary of its own (`home-quiet`, between seasons) all four rows stay. L-25 / D94's "all four doors
> on every Home" survives as **four routes**, not four drawn rows: the routes are always reachable and
> the drawn rows are not the routes. The first draft put `ADD MY ROUND` on the brand-new golfer's
> screen twice, 380pt apart, at two weights — brief §27's "competing CTAs", verbatim, on the first
> screen a new golfer sees.

> **The one-ember rule for Home.** *Exactly one ember object on the screen, and it is the single act
> the golfer should take now.* If the lead or an empty block carries it, the floor is entirely quiet.
> If nothing above carries it, the floor's highest-ranked **unoffered** door takes the 2px `brand`
> rule under its verb — the shipped `emberKey` logic in `MeStrip.swift:353-361`, generalised across
> the whole page. Ember's other job (a live dot, a live eyebrow, the Play glyph) is unaffected; that
> is state, not an action. This closes H-06 (two, and on the emptiest states three, ember CTAs
> pointing at different places in one viewport) by construction rather than by review.

### 1.6 The tab band (§12.1)

A **full-width band on the page's own ground with a 1px `rule` on top**: 74pt + safe area, a 22pt
drawn glyph over an `agateS` label, `mut` at rest, `ink` plus a 26×2pt `ink` underline when selected,
`PLAY` as a drawn ⊕ **glyph** in `brand` with no fill and no disc. Home reserves the band's measured
height and ends in a **28pt fade to `bg0`**, so nothing is guillotined (problem 10).

---

## 2 · STATES

| State | What Home does |
|---|---|
| **loading** | The destination's own geometry, **redacted**: the masthead and its rule paint immediately (they need no read); the lead's two-column block, the strip's rule and four labels, the wire's row heights and rules all render at full size with the type replaced by `bg2` blocks at radius `p` 3 at real-length widths. **Labels are visible and values are redacted** — the strip's shape is a promise the page keeps before the read lands. No spinner anywhere in content; the three-grey-rectangles skeleton (H-21) is deleted. |
| **error / stale** | **Keep what is on screen.** The masthead's dateline becomes `AS OF FRI 6:12 PM · OFFLINE` in `agate` `mut`; every row keeps its last values; **no action is disabled**. `HomeView.swift:181-184` (`EmptyRoot.failedRead()`) and `:516-519` (`feedFailed = r.failed`) already implement exactly this for the feed and is the precedent being generalised. With nothing cached: one `lead` line in the product's voice, one `body` line, and **Try again** as the one primary. A failed read is never rendered as an empty one. |
| **empty — brand new** (`home-new`) | The empty *is* the page. A drawn **blank scorecard** at **78pt** in **`mut`** at the icon family's 1.7pt weight; `THE FIRST CARD` in `agate` `mut` — legal, because the object drawn beside it **is** a scorecard; the headline in `lead` 28, a fact about the world: *"Every number you have starts with one round."*; **the ruled first-contact line** in `body` 17 `mut`: *"Post three and your number builds itself — until then, 12.0 is a starter."*; **one primary button**, `Add my round`; the ME strip at one cell (`12.0` / `STARTER · UNTIL THREE ROUNDS LAND`); then the floor, **collapsed to one row** because the page already offers the primary. **The first sentence a new golfer reads is about golf, not about the product's internals** — the earlier draft said *"Three of them and the engine stops guessing — it has a number of its own"*: "the engine" is a builders' word for the auto-handicap engine, the referent of "it" is ambiguous, and the friend who has run the Saturday game for fifteen years would never mention one. `TERMINOLOGY` already carries the ruled line for this exact moment. |
| **empty — between seasons** (`home-quiet`) | The lead is the season that ended (spine `gold` → **a gold slot**, `CHAMPION`, the viewport's one gold object) with the finish in a panel and a **`rule`-coloured** tertiary link, because nothing here is live. The strip carries two cells. The wire's empty carries a drawn **empty rail** at 44pt in `mut`, `NOTHING RUNNING`, and a `lead` headline that is again a fact about the world: *"Four of the eight have played since it ended."* Its door is `Door.elsewhere("The four doors are at the foot of this page.")` — a reference line, not a control (§13.1) — so the screen carries one act, not two, and `CSEmpty`'s door parameter stays non-optional. **Two absences never share a drawn object**: the brand-new empty draws a blank scorecard (*you have no rounds*), this one draws an empty rail (*a board with nobody on it*). |
| **empty — the wire, with a roster** | Never *"add some buddies"* to a golfer who has one (QB-05, kept). The headline is the world's fact; the door is the season's own roster when there is a season, the buddies tab when there genuinely is nobody. |
| **AX3** (§16.3) | **The lead block**: the panel goes **full width above the headline**, its numeral and unit side by side with the movement mark; the headline follows; the door stays 44pt and does not shrink. **The ME strip**: a stacked list, each cell a slat with the label leading and the figure trailing; nothing scrolls sideways. **Weight 2**: the photograph becomes the row's background and the text sets the height; the gross drops under the name. **The floor**: the gloss drops under the verb, rows become intrinsic-height. **The tab band**: labels drop, glyphs grow to 28. Reflow is driven by the **measured advance** of the golfer's own characters (`MeStripLayout`'s model, generalised), never by a device breakpoint. |
| **long names** | One policy, product-wide: the name column is `min-width: 0` and **truncates with a tail ellipsis**. The serif headline **never** truncates and never clips — it wraps and the block grows the page. |
| **long course names** | The course row's name truncates at the tail; the `agateS` sub-line drops its least-load segment first (locality before the friends count). |
| **no photo** | §1.4 above — the round becomes a 68pt slat with a right-flush rule-and-figure. |
| **no rating** | The rating block becomes `NOT RATED · THE FIRST RATING SETS THE NUMBER` in `agateS` `mut` beside a **full-size unfilled** star rail (§9.11). *Home carries no gold on a course rating in any state* — a community average is not earned (§2.4), so the rating is `ink` here as everywhere. |
| **success** | A toast, 46pt, radius `rc` 10, `bg2`, `body` 15, with a **3pt leading kind rail** (`pos` / `neg` / `rule`) and a drawn glyph. A toast confirms *the golfer's own act*; anything that happened elsewhere arrives as a **wire row and a badge**, never as a toast. |

---

## 3 · THE SWIFTUI FILES THIS REPLACES

Grepped at HEAD 57b993f under `apps/ios/CupSeason`.

| File | Disposition |
|---|---|
| `CupSeason/Home/HomeView.swift` (1,060 lines) | **Rewritten.** The load model (`HomeModel`, `LoadKey`, `ranked()`, `feed(upcoming:spent:)`, `toggle(round:emoji:)`), the lead→deck→strip precedence, the `suppress` union, the failed-vs-empty branch at `:287`, the widget-snapshot write and the refresh/task keys all **survive unchanged**. The view body, `HomeSectionHead` (`:298`), `OccasionCard` (`:582`), `HomeDigestRow` (`:620`), `FeedBucketView` (`:653`), `FeedRoundCard` (`:700`), `FeedPostRow` (`:869`), `FeedNotesRow` (`:951`) and `HomeReactionStrip` (`:1021`) are replaced by `CSMasthead`, `CSStoryCard`, `CSFactStrip`, `CSSectionHead` and the five wire weights. |
| `CupSeason/Home/HomeLeadCard.swift` | **Replaced.** `HomeLeadCard` (`:25`) becomes `CSStoryCard` — the ember-spine reasoning and the two-up clash `aside` survive as data, the `CSCard(spine:)` frame does not. **`HomeDeckCard` (`:72`) is deleted**: ranked items 2–5 become wire items at their earned weight. |
| `CupSeason/Home/MeStrip.swift` (396 lines) | **Replaced by `CSFactStrip`.** `HomeFootDoors` (`:334`) becomes the floor's four rows; its `emberKey` rule (`:353-361`) is kept and widened to the whole page (§1.5). |
| `CupSeason/Schedule/UpNextChips.swift` | **Deleted from Home.** A horizontal rail of capsules is a KPI strip wearing chips; the next tee is a ME-strip cell and a plan is a wire item. The warm-at-three-days rule survives in `CSClockChip` on the schedule. |
| `CupSeason/Schedule/UpcomingRoundsSection.swift` | **Deleted from Home.** The same plan rendered as a deck card *and* a Coming-up card (H-14) is one item at one weight. The section stays on the schedule screen. |
| `CupSeason/People/InvitesBanner.swift` · `CupSeason/People/BuddyRequests.swift` | **Replaced in place** by the weight-1 block with a secondary (the one place a decline may exist, P-1). The r10 box with a 60%-ember border is deleted. |
| `CupSeason/Board/RoundStoryCard.swift` | **Extended into weight 2.** The photo ground, the marker medallion and the scrim survive; the PvI chip and the `COUNTING #N THIS MONTH` line are deleted (they belong in the receipt). |
| `Packages/CSDesign` — `CSCard`, `CSHero`, `CSStat`, `CSMini`, `RoomMini`, `MiniPill`, `RoomSpark`, `CSLookSky`, `CSButtonStyle.gold`, `CSEmptyState` | **Retired** (§18). Home is the surface that removes the last call sites of most of them. |
| `Packages/CSDesign/Sources/CSDesign/Surfaces.swift` — `CSPageHeader` (`:96`), `CSSectionHead`, `CSHairline`, `CSRow` | **Kept.** `CSPageHeader` gains a `Trailing:` overload so `HomeSectionHead` folds back into it; the divider system is a "what works" and survives verbatim. |
| `Packages/CSDesign/Sources/CSDesign/Marker.swift` — `CSFace` (`:44`) | **Kept and made mandatory.** `CSFace` is the only legal way to draw a person on Home; a face now appears in every wire item that has one, which is the first face Home has ever carried (problem 3). |

**New components Home introduces** (all named in `UI_SYSTEM` §18): `CSMasthead`, `CSStoryCard`,
`CSFactStrip`, `CSFigure` (the rule-and-figure), `CSMovement`, `CSPanel`, `CSPlate`, `CSBand`,
`CSDoor`, `CSEmpty`, `CSTabBand`.

---

## 4 · WHAT IT CONSUMES, UNCHANGED

Every sentence on Home is already written by a producer. **The design invents no copy.**

| Producer | What Home takes |
|---|---|
| `home_dispatch()` → `HomeDispatch.Payload` (`Home/HomeDispatch.swift`; SQL `20260908090000_home_is_one_read.sql`) | `items[]`: `key`, `tier` (closing/changed/coming/circle/chapter/opportunity), `rank`, `score`, `rank_reason`, `subject`, `human_subject`, `eyebrow`, `headline`, `standfirst`, `action`, `route`, `league_id`, `suppress`, `spine`, `at`; plus `me`, `lead_suppress`, `generated_at`. *(`band` is **not** a payload field — it is `Tier.band`, a client-side computed weight at `HomeDispatch.swift:39`; and `mods` does not exist anywhere in the file.)* The **item keys are the weight map**: `clash:` `floor:` `move:` `firsttee:` `live:` → weight 1 · `chapter:` `lastseason:` → weight 1 or 4 · `plan:` `story:` `friend:` `invite:` → weights 2/5 · `runitback:` `first_round` `find_golfers` → the floor and the empty states. |
| `HomeRank.ranked()` | `lead`, `deck`, `overflow`, `cut`, `suppress`, `columnFacts`, `spentRounds`, `saysStanding` — the ranking survives untouched; only what the ranks *look like* changes. |
| `MeStripCopy.make(me:starter:suppress:standingSaid:)` | the four `Fact`s (`my_number` · `my_last_round` · `my_next_round` · `my_money`) and the season row, verbatim. |
| `native_home()` → `Me.Membership` | `standing{rank, of, prev_rank, points, gap_to_leader, leader_name, runner_up_name, seed, finalists}` (the lead's panel and movement), `clash{…}`, `last_season{champion_name, champion_is_me, my_rank, of, ended_on}`. |
| `home_feed(p_days)` → `HomeFeedRow` | `golfer`, `marker`, `handle`, `gross`, `pvi`, `course`, `played_on`, `created_at`, `is_pr`, `is_first`, `is_sub80`, `is_me`, `photo_path` — weight 2 whole. |
| `HomeStreamRepository` / `HomePost` / `HomeBuckets` | league notes and system posts → weight 5, with `failed` distinguishing a dead read from a quiet week. |
| `HomeSocial` + `post_kudos` | the reaction counts under weight 2 — already produced and folded (`HomeSocial.swift:141-218`). |
| `CSBands.bandName` / `.theirs` / `.fn1` · `CSDate.short` · `CSHeaderDate.today()` · `EmptyRoot.wireEmpty(me:)` / `.failedRead()` · `MoneyCopy.ledger` · `Occasion` · `HomeDigest` · `StarterIndex.current(engineIndex:)` | copy, dates, empties, the ledger line and the starter index, all verbatim. |
| Routes (`HomeDispatch.Route`) | `composer` `people` `declare` `live` `receipt` `plan` `season(pane:)` `pot` `invite(kind:)` — unchanged. |

---

## 5 · NEW DATA THIS DESIGN NEEDS

Listed because §7 of the brief asks for a weight the product cannot currently produce.

1. **A course-discovery wire item.** No producer emits one. Needs `home_stories`/`home_feed` to
   return a `course` kind carrying `course_id`, `name`, the tee/nine name, locality, and
   `friends_played` (a count derivable from `rounds` joined to `api_courses`), plus the cached
   `api_course_holes` par + stroke index and tee yardages the **drawn card** is generated from (those
   rows already exist; the *item* does not). **Degrade:** with no such item, weight 3 does not render
   and Home runs on four weights.
2. **Course ratings** (`BRIEF` §12, `UI_SYSTEM` §9.11) — the community mean and card count, the
   viewer's friends' mean, and the viewer's own rating. **These do not exist in the product at all
   today**: new tables, a write RPC and a read. **Degrade:** `NOT RATED · THE FIRST CARD SETS THE
   NUMBER` beside an unfilled star rail, and Home carries no gold.
3. *(optional)* **`home_dispatch().items[].figure {value, unit, kind}`** — for items whose figure is
   not a standing (a gross, a pot, a countdown). Without it the client joins `leagueId` → `standing`,
   which covers every ranked item; the optional field would remove the join and let the server say
   which number the block is about.
4. *(optional)* **`home_dispatch().items[].display`** — an explicit `block | band | row | line` hint,
   so the season-moment takeover is the server's call rather than a client-side read of the `key`
   prefix plus `seasons.status = 'cup_final'`. Derivable today; a hint is cleaner.
5. *(optional)* **`home_feed.prev_best`** — the golfer's previous best at that course, so weight 2 can
   print the brief's own `82 → 74` improvement pairing. Without it the row prints the band sentence
   and `is_pr`, which is what it does in the mockup.

Nothing else on Home is new. **No fact on this surface is invented by the client.**

---

## 6 · MOTION (§11)

Four moments, and nothing else moves.

| Moment | What plays |
|---|---|
| **Arrival** | The primitive is the **wipe**: a clip rect opening from the left margin across each block over **220ms on `snap`**, staggered 40ms — masthead, lead, strip, then the wire's rows. A board graphic arrives; it does not fade in. Every bare opacity transition on Home is deleted. |
| **Your rank changed since the last open** | The lead's panel numeral **slots** (`RankFlipText`, kept), then the movement mark wipes in from the panel's edge after the block settles. `.impact(.light)` **once**, and only when the row that moved is yours. Gated on a replay-on-open flag, so it plays on the change and not on every scroll. |
| **A reaction** | The emoji scales 1.0 → 1.12 → 1.0 on `roll` over 160ms and the count tallies. `.selection`. Nothing else on the row moves. |
| **Pull to refresh** | The masthead's dateline crossfades to the new date on `roll` 180ms; rows that are unchanged do not re-animate. A refresh that fails changes the dateline to the offline form and moves nothing. |

`accessibilityReduceMotion` resolves both curves to `nil` — never "faster". Every rest frame is the
finished state. **No haptic on scroll, on navigation, or on an error that already toasts.**

---

## 7 · ACCESSIBILITY — the flagship's own statement

Six surface specs state this and the one that matters most did not. Home is the only surface mixing
five item weights, and every object on it is a **compound** that has to be one VoiceOver element or a
mess: authored naïvely, VoiceOver walks 40+ stops down this page and reads `10.6` and `YOUR NUMBER` as
two of them.

**One element per object, in the product's voice.**

| Object | The element |
|---|---|
| **the masthead** | one element: *"Cup Season. Sunday, September 6."* The rule is decorative and is hidden |
| **the lead block** | one element combining eyebrow, headline, standfirst, panel and movement mark, with `.isButton`: *"Live. You moved to second of eight, up two spots. Galen is four ahead. Opens the table."* |
| **each ME cell** | one element combining label and figure, with `.isButton`: *"Your number, ten point six. Opens your index."* — never `10.6` and `YOUR NUMBER` as two stops |
| **the standing line** | one element, read as a sentence: *"The Fellas. Twenty-six weeks, four to play."* |
| **each wire item** | one element per row, whatever its weight: *"Galen Marr. Seventy-nine at Papago, a personal best."* · *"Tash Bell rated Troon North four and a half."* · *"Two notes in The Dew Sweepers. Tuesday."* |
| **the reaction line** | one element per reaction with its count and `.isToggle`; the row does not repeat the item's headline |
| **each floor door** | one button, the gloss folded into the label: *"Add my round. One you already played."* |
| **the tab band** | five buttons, `.isSelected` on the current one |

**Written labels on every drawn indicator** (§16.4): the live dot is *"Live"*, the movement mark is
*"Up two spots"* / *"Down one"* / *"Held"*, the week ticks are *"Week seven of twenty-six"*, the score
mark is *"Birdie"* / *"Bogey"*, the drawn empty object is named for what it is (`schedule-sheet`,
*"an empty schedule"*).

**The pairs worth stating**, computed from §2.8: the live eyebrow is `brand` `agate` on `bg0` at
**5.27 dark / 5.39 light**; the day marker is `mut` at `agateS` — **7.07 / 5.85**, and it is `mut`
rather than `dim` for exactly this reason; copy over a wire photograph takes `scrimInk` or `scrimMut`
through `CSPhotoScrim.band`, measured, never a raw value.

**Targets**: every wire row is ≥44pt at its own weight (weight 5's 44pt row is the floor and it *is*
44); each ME cell is a 44pt target inside the strip; each floor row is 44; the reaction chips are 44
with hit slop. **Dynamic Type**: §16.3's masthead, `agate`, lead-block, ME-strip and floor rows, all of
which this surface owns. **Bold Text, Increase Contrast and Reduce Transparency**: §16.5, product-wide.

---

## 8 · THE WEB DESK VARIANT, in one paragraph

*(The rendered desk artboard is the season board — `mockups/web-desk.html` → `renders/desk/desk-season.png`, 1440 × 900 — and `UI_SYSTEM` §14.5 carries the nine type roles as CSS classes and the order `index.html` migrates in.)*

On the desk (`index.html`, owner ruling R-C) Home is the same edition set in two columns inside the
236pt sidebar frame: the masthead becomes the page's own dateline row at the top of the body (the
wordmark already lives in the sidebar, so it is not printed twice), `display` grows to 42 and `story`
to 21, and the gutter to `gutterDesk` 40. The **left column (1fr)** carries the lead block — sentence
left, panel and movement right at the same proportions — then the wire at its five weights, with
weight 2's photograph running the column's full width at 2.1:1 and weight 3 gaining a second line of
course facts because there is room for it. The **right column (340pt)** carries the ME strip turned
vertical (four rule-and-figures stacked, the standing line beneath, the ledger line under that), the
clash, and the four doors as a persistent block that never scrolls out of reach — which is the desk's
answer to the floor. Hover is guarded by `@media (hover: hover)`: a wire row's ground steps to `bg1`,
a link's 2px `brand` rule thickens to 3px; **every hover state has a focus twin**, a 2px `brand`
outline on the whole row, always visible. Keyboard: `↑`/`↓` between wire rows, `→` opens the row's
door, `/` focuses search, `Esc` closes. Density and column count change; **nothing is re-designed.**

---

## 9 · HOW THIS ANSWERS THE AUDIT, BY NUMBER

| Audit finding | Answer |
|---|---|
| **P1** the card is the only container | Home has **zero** containers. Four objects exist on it — the panel, the plate (a photograph), the band, and the rail-free rows — and every one of them has a job in `UI_SYSTEM` §3.1. No border token exists. |
| **P2** golf numbers are not visual objects | The rank is a `figure` 40 in a bone panel at 14.91:1; the gross is a `figure` 27 in a panel or a rule-and-figure; the four ME facts are `figure` 27 on a 2pt rule. Home's largest type is no longer its own name (H-22). |
| **P3** no face, no photograph | A 38pt `CSFace` leads weight 2; a photograph is above the fold **by design** on the live Home; weight 2 without a photo still carries the face (problem 3, H-04). |
| **P5** ember has no seat | **One ember object per Home** (§1.5), plus ember's state job (the live dot, the live eyebrow, the Play glyph). H-06 and H-12's five accent hues become two. |
| **P7** no display tier; the eyebrow is the default voice | One `display` (the wordmark), one serif `lead`, and **ten tracked-caps agate lines** as §1.5's budget — counted the way a golfer sees them, including unit labels, row sub-lines and door glosses. `home-live` carries nine once the wire's sub-lines and the door glosses set in **sentence case** (§1.3). The shipped Home carries seventeen. |
| **P8** empty/loading unbuilt | Three empty Homes are drawn, each with a shape, an eyebrow, a headline about the world, a door and a number. Loading is redacted geometry. |
| **P10** nothing re-ranks; chrome guillotines | Every layout has a stated AX3 form (§2); the tab band sits on the page's ground with a rule and a 28pt fade, so there is nothing to float over. |
| **H-01** rank 1 and rank 4 are the same weight | The deck is deleted; the lead is the only serif, the only panel and the only two-column block above the wire. |
| **H-03** ceremony night and brand-new are the same object | `home-live`, `home-quiet` and `home-new` share a masthead and share nothing else: a photograph and a live dot; a gold slot and a finish panel; a drawn card, a serif invitation and one primary button. |
| **H-05** half the premium-feed slot is a count of notes | League notes are weight 5 — one quiet line each, folded, with a day marker. |
| **H-07** four doors as wrapped caps links | Four 44pt rows with glosses, at most one lit. |
| **H-09** `PLAN ONE` in a value seat | A slot with no figure is absent. |
| **H-10 / H-13 / H-18** mono links, control radii on cards, an invisible spine | Mono is gone from Home entirely (it survives only in the reaction counts); there are no radii on Home except the panel's `p` 3 and the primary's `rc` 10; the three-state spine is replaced by a two-state signal (painted means something). |
| **H-14** the same plan rendered twice | One item, one weight; `UpcomingRoundsSection` leaves Home. |
| **H-21** the three-grey-rectangles skeleton | Redacted destination geometry. |

---

## 10 · KNOWN IMPERFECTIONS OF THE MOCKUPS

Stated rather than iterated a fourth time.

- **The artboards compress three inter-section gaps.** `home.html` uses ~18–22pt where this spec
  says `s5` 32 (masthead→lead, lead→strip, strip→wire), and the ledger line renders at 14pt where
  §9.5 says `body` 15. The artboard is a fixed 874pt frame with no scroll; the device scrolls. **The
  spec's token values are what Phase 3 builds**, not the artboards' compressed ones.
- **The photographs are drawn stand-ins** for a golfer's own round photo (§10.4). The product has no
  photograph this session may use and fabricating a face is forbidden. The crop, the scrim, the panel
  and the face are what the mockup specifies.
- **`home-live`'s last wire line sits under the 28pt fade.** That is deliberate — it is the signal
  that the wire continues — but it means the second minor line is only half-legible in the render.
- **`home-new` prints `ADD MY ROUND` twice**: once as the empty's ember primary and once as a quiet
  floor row. That is correct under L-25 (all four doors, always) and under the one-ember rule (the
  metal does not repeat), and it is the shipped `emberKey` behaviour — but a reviewer should confirm
  they are comfortable with the words repeating on the emptiest screen in the product.
- **`home-quiet` and `home-light` carry two serif `lead` lines** — the season-complete headline and
  the wire-empty's headline. `UI_SYSTEM` §1.4 allows New York **one appearance per viewport**;
  §13.1 requires an empty state's headline to be in `lead`. On any viewport that has both a lead
  block and an empty block those two rules collide, and there is no third option that keeps the
  empty state's weight. **This is a system conflict, not a drafting slip** — the refuters should
  rule: either the empty's headline drops to `story` 20 (weaker, but one serif voice per viewport),
  or §1.4's budget is stated as "one serif *object* per viewport, and an empty state is one".
- **The rating and the course-discovery item are drawn against data that does not exist yet** (§5).
  The unrated degrade is specified but not drawn.


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it.** Instantly legible 3/3 · looks like Cup Season 3/3 · premium 3/3 ·
template 0/3 · proud to post 3/3 · belongs in the category 3/3. Median **7.9**. Every one of them
opened with the same three findings, which is why they are the three changes.

**1 · Rank is one object, not three (§16A.4).** The headline said it, the chip said it, and a
`▲2 SPOTS` rule-and-figure said it a third time — inside 400pt, and sharing a baseline with the
schedule link so the two read as one broken object. All three filed it; blind-3 measured the cost
("it narrows the left column enough to force a 3-line wrap"). **The chip now carries the figure, the
ordinal and the movement in one block** — `2ND / ▲2 / OF EIGHT`, 84 × 90 — and the lead's copy and CTA
run the full column width. The `SPOTS` block is deleted.

**2 · The stat rail is three numerals, and a weekday is not one (§16A.4).** `10.6 · 84 · Mon · $75`
became `10.6 · 84 · $75`. All three reviewers filed `Mon`; blind-1's line is the one to keep — *"a
weekday in identical type to three numbers reads as a rendering error"*. **The next tee returned as a
dated wire row with a chevron** (`Mon · Papago, 7:10 with Galen and Jade. ›`), which is where dates
live on this surface and which also gives the wire a fourth weight it was short of.

**3 · The wire leads with a photograph (§10.1).** The friend-round band drew the contour under the
scrim; blind-2: *"it is the one place a photo exists and it currently renders as a marker disc on a
dark topo band. Photo first, topo only as the empty state."* The band is now a round photo with the
credit `GALEN'S ROUND · SUN` top-right and the `.band` scrim leading-anchored. **The course-discovery
thumbnail is a photograph too**: all three read the fourteen-bar comb as an equalizer that "encodes
nothing", and blind-1's alternative — *"a real course photograph or nothing"* — is what it now is.

**4 · The ledger sentence and the league strap are gone (§16A.1).** Two rows of boilerplate sat
between the four figures and the feed, "neither of which changes anything" (blind-2), and the strap
also contradicted the season page's own week count. Deleting both lifts the first wire item ~90pt.

**5 · Both empty states are written.** `home-quiet` drew a table glyph under `THE WIRE` and nothing
else — read as "an unfinished empty state on the flagship screen" and "a failed image load". It is now
three lines and no glyph: `NOTHING RUNNING SINCE AUG 31` / *Four of the twelve have played since it
ended.* / *Their rounds are still counting somewhere. Yours are not.* — a fact about the world, never
the golfer's omission (§13.1). `home-new`'s ~350pt void is filled with what the first round turns on,
as three rule-separated rows: **your number moves · the course keeps it · your friends see it**.

**6 · Reaction counts are set in the system's own type.** The emoji stay (canon, and declined in
§20.1); the count beside each is now `agateS` rather than mono, so the emoji is the only foreign
object on the screen and the number beside it is ours.

**Fixture.** The Dew Sweepers are a field of **twelve** on every surface that names them; The Fellas
are **eight**. Home's chip reads `OF EIGHT` in the live state and `OF TWELVE` in the quiet one, and
both agree with their own headlines.
