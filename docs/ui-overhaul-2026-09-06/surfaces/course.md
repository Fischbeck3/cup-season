# SURFACE SPEC — COURSE

**The course card and the course page.** *Editorial · discovery. Character: a spread in an almanac.*

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 of 3 (design; nothing is built)
**Standard** `BRIEF.md` §11, §12, §20, §31 · **System** `UI_SYSTEM.md` (obeyed; departures in §12 below)
**Audit** `UI_AUDIT.md` §2.24 — *mean 4.4, redesign; brand 3 and emotion 2 are the two lowest numbers on the board*
**Mockups** `mockups/course.html` → `mockups/renders/course/` — `course-page` · `course-page-noimage` ·
`course-card` · `course-rating` · `course-light`

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 1 · What this surface is for, in one paragraph

A course is the only object in Cup Season that is **a place**. Everything else — a season, an event, a
golfer, a round — is a record of what people did; a course is where they did it, and it exists whether
or not anybody opens the app. That is why it gets the product's only image-led surface and its only
pull quote. The page answers four questions in this order: **what is this place** (the plate, the name,
where it is), **is it any good and how hard** (the rating, the facts line), **what do my people say
about it** (the quote, the faces, who has played it), and **what will I face** (the card, printed on a
leaf). The rounds posted here run underneath. Nothing on it is a database record and nothing on it is a
box: the shipped screen's 2×2 KPI grid — the audit's named "canonical SaaS dashboard pattern" — becomes
**one line of type**.

---

## 2 · Anatomy, top to bottom

Every spacing value is a `space` token (§4). Every type role is one of the nine (§1.2). The page is a
**pushed screen** inside the tab band, not a sheet: it is an object, and §7.3 says objects are pushed.
`navigationTitle("")`; the system bar carries the back chevron only (§12.2).

### 2.1 The plate — `CSPlate`, full-bleed, 252pt, radius 0

The surface's opening object, and **the only place in the product where the name is reversed out of an
image**. Its content is the §10.1 ladder — a golfer's round photo, else the drawn card, else the
contour — and *the object does not change when the content does*, which is what makes the no-image
state a state rather than a fallback.

| Element | Role · token | Position |
|---|---|---|
| the image | `CSPlate`, radius 0, full-bleed | 0 → 252 |
| the scrim | `CSPhotoScrim` (settle/plate split, §10.3) — the product's only scrim | over the whole plate |
| back | system `chevron.left`, drawn at 1.7pt, `#F1F4EF` on the scrim | `gutter` 20, top 56 |
| the credit | `agateS` 11 in **`scrimMut` `#CBD2C8`** (a named token — §2.1) on **`CSPhotoScrim.top`**, the 96pt band a full-bleed plate takes under the status bar (§10.3, a11y-9) — *"Galen's round · Aug 24"* | flush right, top 58 |
| the eyebrow | `agate` 12, `#CBD2C8` — *"Kept · four of yours have played it"* | `gutter` 20, above the name |
| the name | `display` 34, `ink` reversed | `s2` 8 under the eyebrow |
| the place | `agate` 12, `#CBD2C8` — *"Phoenix, Arizona · Municipal"* | `s2` 8 under the name |
| **the panel** | `CSPanel` 64×64, **bone in both themes** (§3.2), `figM` 27 + `agateS` in `panelMut` — *your best here* | flush right, bottom-aligned with the name block, gap `s3` 12 |

**Type on the scrim is never a palette token.** `ink` on a photograph is a coincidence, not a contrast
ratio; the plate's four text elements use the two scrim-safe constants `#F1F4EF` and `#CBD2C8`, which
`PhotoScrimTests` already holds at 4.5:1 over a paper-bright and a dusk-dark subject.

**A second title line** (`title` 24 in `mut`, `s1` 4 under the name) carries the course when the club
and the course differ — *GOLD CANYON / DINOSAUR MOUNTAIN*. This is the long-name answer at title scale:
a course headline **wraps**, it does not truncate; the tail-ellipsis policy (§9.1) applies to rows.

### 2.2 The facts — one line of type · `s4` 20 below the plate, `s3` 15 in the mockup's tighter setting

```
72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE
PAPAGO BLUE · THE 4TH PLAYS HARDEST · SAVED TODAY
```

Figures in `figS` 20 tabular; unit labels in `agateS` 11 at `mut`; the separators in `agateS` at `mut`
at 50% opacity (a glyph, not a word). **Never a grid, never four hairline-divided cells** (§15.3), and
never four `CSStat` tiles — the component is retired.

The second line is the **facts object's own label**, not a stand-alone metadata block: it carries the
tee it is describing, the difficulty fact the cached card can prove (`si == 1`), and **L-32's
provenance verbatim from `CourseBook.savedLine`**. See §12 deviation D-1: this moves the provenance
line *below* the figures it qualifies.

### 2.3 The rating — `CSRating` (`CSFigure` in `.ink` + `CSStarRail`) · `s4` 20 below

Brief §12, which does not exist in the product at all today. Two columns, `s4` 18 apart.

| Left (the community's number) | Right (yours and your golfers') |
|---|---|
| `figure` 40 in **`ink`** | the **drawn** five-star rail, **filled `ink` / unfilled `rule`**, 122×20; half by clipping the fifth star, never a second glyph |
| a **2pt `ink` rule**, 66pt wide | `body` 15 at `mut` with a **figure run**: *"Your golfers give it **4.9**. You haven't rated it."* |
| `agateS` 11 at `mut` — *"Cup Season golfers · 24 ratings"* | a tertiary link, `nameS` 15 `ink` + a **2px `mut` rule** (in content, and not this screen's live action — §7.1) — **`Rate it`** |

**There is no gold on this surface, and that is the fix, not an omission.** The first draft set the
rating figure, its rule and the whole star rail in champagne and defended it as "the earned one" —
but *nobody earns a course's rating*: it is an average of opinions, and §2.4's list is closed to
things that were **won**. Spending the product's scarcest mark on its most repeated object (every
course row, every discovery item, every course page, twice on Home) is how gold stopped meaning
anything the first time. The rating's weight comes from **size and the rule**, which is what the
display tier and the 2pt rule exist for. A viewport with no gold object is legal (§2.4).

The star glyph is drawn at the icon family's weight; there is no `★` character anywhere (§5.2 bans the
dingbat, LINT-13 bans a typed glyph in a produced string). **There is no arrow on the link** — the
underline is the affordance, product-wide (§5.2).

**Unrated** is not a smaller control. It is the **full-size star rail, unfilled**, stroked 1.4pt in
`mut`, plus `NOT RATED · THE FIRST RATING SETS THE NUMBER` in `agateS` and the same `Rate it` link
(§9.11). *A rating is a rating; "card" is reserved for the person and for the scorecard (T-01).* The
drawn card's #1-stroke bar is **`ink`**, not gold — the hardest hole is not won either.

### 2.4 The pull quote — the one serif on this surface · `s4` 20 below

`story` 20 New York Regular, sentence case, with the opening quote **hung 9pt into the margin**; the
attribution beneath in `body` 15 at `mut` with the gross as a figure run: *"Jade, after an **82** here
on Aug 30."* The text is a `posts.body` attached to a round played here (§11, new producer). **The
block does not render at all when no such post exists** — it is never a placeholder, never a stock
line, and never a caption about the course written by us.

§15.3's rule that COURSE's serif is a *pull quote rather than a headline* is what keeps this surface
from reading like Home. It also means the surface's serif **changes role with state**: on the no-image
page there is no quote, and the one serif is the empty state's headline (§2.7).

### 2.5 Who of yours has played it · `s3` 17 below

An **overlapping** row of `CSFace` discs (34pt, −12 overlap, each ringed in `bg0`), then one `body` 15
sentence that **names them** and carries the best gross as a figure run: *"Galen, Tash, Jade and Dev.
Galen's **79** is the best of them."* Overlap at small size reads as a group (§6.3); a spaced row with
names reads as a roster and is the event's device, not this one. **This is the line that makes a course
page social rather than a database record** — it is the single biggest change from the shipped screen,
where the only social fact is a footnote at the bottom.

**No section head above it.** The sentence labels itself, which buys the surface a slot inside §1.5's
four-agate budget.

### 2.6 The front nine — `CSLeaf` · `s3` 18 below, inset `gutter` 20

A sheet of scorecard paper set into the page: `leaf` fill, radius `p` 3, `leaf-shade`, and in Light a
1px `rule` frame. Three rows — **HOLE** (`colS` 12, `leafMut`) · **PAR** (`col` 14, `leafInk`) · **SI**
(`colS` 12, `leafMut`) — with a tenth **Out** column, split by one 1px rule at 20% `leafInk`. The row
labels sit in a fixed 26pt leading column in `agateS` at `leafMut`.

The leaf passes §3.3's test — *it contains a grid* — and it is the cheapest unmistakably-golf object in
the system. It is also the airplane-mode payoff: **this block draws entirely from `CourseDisk` and
needs no network**, which is the whole reason `CourseBook` exists (D261 / R-N).

Below it, off the first viewport: a tertiary link **`The whole card`** (the back nine and every rated
tee, pushed as a screen, not a sheet).

### 2.7 Rounds here — `CSSectionHead` + slats · `s4` 20 below the leaf

`agate` 12 at `mut` + a 1px `rule` running to the margin. Then 50pt slats, each with a `rule` on its
top edge, full-bleed:

`CSFace` 30 · `social` 17 title case (a person in a course row is title case, §1.3) with an `agateS`
sub-line *"Aug 30 · blue tees"* · the gross in `figM` 27, tabular, right-flush at `gutter` 20.

**No rank rail** — these rounds are not ranked against each other, and painting a rail would assert an
order the data does not have. The list runs on under the 28pt fade (§12.1), which is the correct "there
is more" cue and the reason the surface ends in a row rather than in a slab.

### 2.8 The compact card — `course-card`

The same object at two smaller scales, and they are different objects.

**In a list** (the Courses screen, and any course row anywhere): a 62pt slat carrying a **44pt
thumbnail** (a photo plate or the drawn card — **never the contour**, §10.2), `social` 17 with tail
ellipsis, an `agateS` sub-line carrying a drawn 11pt star, the rating, the place and one social or
temporal fact, and a trailing `figM` 27 = **your best gross here**. A course with neither a photo nor a
cached card **shows no thumbnail at all**: the left column collapses and the name sets flush to the
margin. A course you have not played shows **nothing** in the trailing column, or a two-line `agateS`
date when it is on the plan — never a dash, never a zero (L-44).

**In the wire** (Home's course-discovery item, brief §7's "more editorial"): a 64pt drawn-card
thumbnail, the name in `name` 17 caps (in the feed the course is a headline), the full drawn star rail
+ the rating in `figS` **`ink`** + `agateS` credit, then one `body` 15 line of the golfer's own words in
quotation marks. **No serif here** — Home spends its one serif on its lead (§15.1).

The screen these rows live on opens with `display` 34 **COURSES**, one `agate` line, and **one chip
row** — `All · Planned · Played`, 28pt, radius `p` 3, the selected one inverting to the panel (§7.2).

---

## 3 · The rating, in full — `course-rating`

§12 of the brief is the largest genuinely new thing on this surface. **The rating is content, not a
form field**, and the act of rating is a fitted sheet, not an alert.

**The sheet** (`CSFittedSheet`, `rs` 24 top corners, `bg0`, drag pill in `rule`, `Close` as the one
dismiss verb at `topBarTrailing`, §7.3):

1. `agate` eyebrow — *YOUR RATING* *(never "your card on this course": T-01 collapsed that noun to the person and `TERMINOLOGY` §4 check 7 was widened to catch exactly this phrasing, aimed at a third object)*
2. `display` 34 — the course
3. **the control**: `CSStarRail` — a **continuous 362 × 56 drag target**
   (`DragGesture(minimumDistance: 0)` mapping *x* to the nearest half) with a **−½ / +½ stepper pair
   at 44pt** beside it for the tap case. **Half-star granularity.** Filled stars are **`ink`**; the
   unfilled remainder is stroked 1.6pt in `mut`. *(Gold may never touch a control — LINT-11.)*
   **The first draft asserted "44pt minimum target per half", which the geometry cannot deliver:**
   five stars × two halves is ten discrete targets and 10 × 44 = 440pt against a 362pt measure (335 on
   an SE). The half-star hit region is **28pt** — above WCAG 2.5.8's 24 × 24, below this system's own
   44 — and the stepper pair is what makes that legal (`UI_SYSTEM` §16.2 carries the carve-out by
   name). `.accessibilityAdjustable` with 0.5 increments, plus
   `.accessibilityValue("four and a half stars")`.
4. **the figure**: `figXL` 56, tabular, on a **2pt `ink` rule** 88pt wide with `YOURS` in `agateS`
   beneath — the rule-and-figure, at the size §16 of the brief asks for
5. `body` 15 at `mut` — *"Half stars count. Change it any time — the number moves with you."*
6. a 1px `rule`
7. **two numbers on one shared 2pt `ink` rule** (§9.6's standing-line device): `4.6` and `4.9` in
   `figure` 40 with `CUP SEASON` · `YOUR GOLFERS` in `agateS` beneath. **The `YOURS` cell is gone** —
   the 56pt figure at item 4 *is* yours, and printing 4.5 twice 90pt apart is the same fact rendered
   twice in one viewport (brief §28 Q7). **No gold**: an average is not earned (§2.4). Then one
   `body` 15 line: *"Twenty-four ratings, four of them from your golfers."*
8. **one primary**: `Rate it`, 50pt, `rc` 10, `brand` fill, `bg0` label
9. one tertiary beneath, centred, `nameS` in `mut` with a `rule` underline: `Take my rating off`

**Yours, your golfers' and the community's** — the three numbers §12 names — are on one rule so the
comparison is a glance rather than a paragraph. A golfer who has not rated it sees the third figure
slot **empty with `NOT YOURS YET` as the label**; the value slot never renders a dash (§1.6).

---

## 4 · Every state

| State | What it is |
|---|---|
| **Loading** | **the destination's own geometry, redacted** (§13.2). The plate renders immediately from the local `CourseBook` as the drawn card; the facts line, the rating block, the quote and the leaf render at their real heights with type replaced by `bg2` blocks at radius `p` 3 with real-length placeholder widths. The leaf keeps its paper and its rules and redacts only its numerals. **No spinner anywhere in content** — the shipped `CSFine("Looking for this course on your phone…")` is deleted. |
| **Empty · nobody has played it** | the four-part `CSEmpty` (§13.1): a **drawn scorecard object** 52pt at 1.7pt in `rule` · `agate` eyebrow *THE FIRST CARD* · `lead` 28 serif **"Nobody here has played it."** — a fact about the world, never the golfer's omission · one true fact in `body` 15 at `mut` · **one required door**, the primary `Add my round` (`TERMINOLOGY` A-5: one verb opens the composer, product-wide, and Home and Event already use it). The rating block above it is the unrated star rail; the leaf still prints. The page is never blank and never says "Nothing here yet." |
| **Empty · never kept** (the course is not on this phone and there is no signal) | `CourseBookCopy.neverKept` verbatim in `body` 15 at `mut`, the course's name in `display` 34 above it, and the door is `Put it on the plan` — the one thing that both works offline and makes the book arrive next time. |
| **Error · stale** | **keep what is on screen** (§13.3). The cached page renders under the facts line's own provenance label with `· OFFLINE` appended, at `mut`, and **no action is disabled**. `Rate it` queues. |
| **Error · nothing cached** | one `lead` line in the product's voice, one `body` line, and **Try again** as the primary. Never a raw code; server text renders verbatim when it was written for humans. |
| **No photo** | `course-page-noimage` — the drawn card fills the plate, name reversed out of it exactly as over a photograph. The credit line **disappears** (a drawn plate has no photographer, and §10.2 forbids a caption that teaches the reader how to read the graphic). |
| **No photo and no cached card** | the contour plate (§10.1 rung 3), hero scale only. At thumbnail the row shows **no image at all**. |
| **No rating yet** | §2.3's unrated rail, full size. |
| **No quote** | the block does not render; the faces row moves up by `s4`. |
| **You have not played here** | the plate's panel is **absent** (not a dash); the list row's trailing figure is empty or the plan date. |
| **Long course name** | on the page the title **wraps** (two lines: club in `display` 34, course in `title` 24 at `mut`). In every row it is **one line with a tail ellipsis** — the product-wide policy (§9.1), demonstrated in `course-card` row 5. Both flex containers carry `min-width: 0`; without it the name silently overflows the frame, which is exactly what the first render of this mockup did. |
| **Disabled** | `Rate it` is never disabled — an unrated course is a state, not an error. The only disabled control on the surface is the primary while a write is in flight, which shows **three mono dots that tally**, never a spinner (§7.1). |

### 4.1 AX3, stated as a layout

| Region | Default | AX3 |
|---|---|---|
| the plate | name reversed out of the image, panel flush right | **the foot block leaves the image**: the plate becomes a 200pt image band carrying only the credit; the eyebrow, name, place and panel set below it on the page's own ground. Reversing 34pt-grown type out of a photograph is not a contrast claim anyone can make |
| the facts line | one line of type | a **stacked list**, each fact a row: `agate` label leading, `figS` figure trailing (§16.3's form for figures on a rule) |
| the rating | two columns | stacked: the `ink` rule-and-figure, then the star rail, then the friends' line, then the link |
| the quote | serif + attribution | unchanged; `story` does not cap |
| the faces row | discs left, sentence right | the disc row moves **above** the sentence, full width |
| the leaf | 10 columns | **scrolls horizontally inside its own container with the row labels pinned** — the shipped `CourseCardSheet` behaviour, which the audit calls the one region of that screen that already works. See deviation D-5 |
| a round slat | face · name/sub · gross | the gross moves **under** the sub-line as its own `figS` line; `minHeight` becomes intrinsic; one VoiceOver element throughout |
| the tab band | glyph + label | labels drop, glyphs grow to 28 |

`ViewThatFits` and the measured-advance reflow of `MeStripLayout` are the model — **not a device
breakpoint**. Growth caps: `display` ×1.6, `figure` ×1.5/×1.7. `agate`, `body`, `column` and `social`
never cap. Nothing renders below 11pt at the default size.

### 4.2 VoiceOver

- The plate is one element: *"Papago. Phoenix, Arizona, municipal. Kept on your phone; four of your golfers have played it. Your best here is 81. Photograph by Galen, August 24."*
- The facts line is one element: *"Par 72, 7,068 yards, rating 72.5, slope 130, from the Papago blue tees. The 4th plays hardest. Saved on your phone today."*
- The rating block is one element: *"Rated 4.6 out of 5 by 24 Cup Season golfers. Your golfers give it 4.9. You have not rated it."* The `Rate it` link is a separate element with the `.isLink` trait.
- The leaf is **one element per row**, not one per cell — the shipped card's single label for eighteen columns is the hole the audit names, and three sentences ("Hole one through nine." / "Pars: four, five, three…" / "Stroke indexes: …") is what a golfer can actually follow.
- The star rail in the sheet is an **adjustable** element: `.adjustable`, increments of 0.5, value spoken as *"four and a half stars"*.

---

## 5 · What it replaces

| File | Lines | Fate |
|---|--:|---|
| `apps/ios/CupSeason/Courses/CourseCardSheet.swift` | 207 | **replaced entirely.** Becomes `CourseScreen.swift` — a pushed screen, not a sheet (§7.3: objects are pushed). Its `ratings(_:)` `LazyVGrid` of four `CSStat` tiles is deleted (that is 4 of the 12 remaining `CSStat` sites; the type is retired in §18). Its `card(_:)` stacked-nines block **survives in substance** as the leaf. Its `CSSheetHeader` + `Done`-in-ember toolbar is deleted (§7.3: one dismiss verb, and a pushed screen has none) |
| `apps/ios/CupSeason/Courses/KeptCoursesList.swift` | 84 | **replaced entirely** (both `KeptCoursesList` and `KeptCoursesSheet`). Becomes `CoursesScreen.swift` + `CourseRow.swift`. The ember `SEE` label on every row — a link-label on a row that is already the door (BF-16) — is deleted; the row's trailing column becomes your best gross |
| `apps/ios/CupSeason/Main/MainTabView.swift` | :484, :548 | the `.sheet(item: $presenter.courseCard)` presentation becomes a `NavigationLink` push; `MainTabView.swift:484`'s `CourseSheetRef(id: "never-kept", …)` sentinel keeps working — it is the never-kept state |
| `apps/ios/CupSeason/Main/Presenter.swift` | :22 | `var courseCard: CourseSheetRef?` becomes a path element rather than a sheet item |
| `apps/ios/CupSeason/Schedule/ScheduledRoundSheet.swift` | :42 | its `.sheet(item: $card)` becomes a push from inside the sheet's own `NavigationStack` |
| `apps/ios/CupSeason/RootView.swift` | :226 | `KeptCoursesSheet()` → `CoursesScreen()`. This is the boot-failed path and **must keep working with no session** |
| `apps/ios/CupSeason/Settings/CardAndSettingsScreen.swift` | :536 | the embedded `KeptCoursesList()` becomes a single row that pushes `CoursesScreen` — the courses list stops being a settings pane |
| `index.html` — `renderCourseBooks()` | 12275–12313 | **replaced.** The `<details>/<summary>` accordion of `.cbook` / `.cbtee` / `.cbtable` becomes the desk's two-column course page (§8). Call sites at :12543, :20422, :24081 are unchanged |

New Swift types, using §18's names: `CoursePlate` (a `CSPlate` variant with the scrim, the credit and
the foot block), `CourseFactsLine`, `CourseRating` (`CSFigure` `.earned` + `StarRail`), `StarRail`
(drawn, display and control modes), `CourseQuote`, `CourseFriends`, `CourseCardLeaf`, `CourseRow`,
`RateCourseSheet`.

---

## 6 · What it consumes unchanged

Nothing here invents a fact the server does not produce.

| Producer | Used for |
|---|---|
| `my_course_books(p_limit)` → `CourseBook` / `CourseBookStore` / `CourseDisk` | the name, the place, the tees, the ratings, the slopes, the par totals, the yardages, the hole card, `planned`, `played`, `next_play_on`, `last_played_on` |
| `CourseBook.label` / `.place` / `.defaultTee` / `.tee(named:holes:rating:)` / `.firstHole` | the title, the place line, which tee the facts line describes |
| `CourseBookTee.pars(want:)` / `.card(want:)` | the leaf. `nil` is a real answer and draws `CourseBookCopy.noCard`, never eighteen par 4s (L-44) |
| `CourseBook.savedLine(now:)` / `CourseBookCopy.offlineBanner` | the provenance in the facts line's label (L-32) |
| `CourseBookCopy.neverKept` / `.readFailed` / `.noCard` / `.searchOffline` / `.what` | the four honest states, **verbatim** |
| `CourseHit.label(club:course:)` | the row's name, so the book and the search row can never disagree |
| `LeagueDates.dowMonDay` / `CourseBookCopy.when` | every date on the surface. Never `toISOString().slice()` |
| `CSCopy.points` | the rating and the tee rating, so a missing figure prints an em dash rather than a zero |
| `rounds.photo_path` + the existing signed-URL cache | the plate's photograph |
| `MARKERS` / `Markers.swift` + the six pigments | every `CSFace` |

---

## 7 · New data the design needs

Listed in build order. Items 1–2 are the feature; 3–6 are producers over facts the database already
holds; 7 is a link that does not exist.

1. **Course ratings — the whole of brief §12, which has no representation in the product today.**
   A `course_ratings` table (`api_course_id text`, `profile_id uuid`, `stars numeric(2,1)` constrained
   to 0.5-steps in [0.5, 5.0], `created_at`, `updated_at`, unique on the pair), a
   `rate_course(p_course_id text, p_stars numeric)` security-definer RPC that upserts, an
   `unrate_course(p_course_id text)`, and RLS + an explicit `grant execute … to authenticated` (D37 —
   a new RPC that "silently 403s in prod" is almost always a missing grant).
2. **The rating aggregate**: the community mean and card count, the mean and count **among golfers the
   viewer can see**, and the viewer's own value. Three numbers and two counts, returned together, so
   the three-figures-on-one-rule block is one read.
3. **`course_page(p_course_id text)`** — one producer for the rest of the page: the rounds posted at
   this course that the viewer may see (`profile_id`, `display_name`, `marker`, `photo_path`, `gross`,
   `played_on`, `tee_name`), the viewer's own best gross here, the set of the viewer's golfers who have
   played it and the best score among them. Every underlying fact already exists on `rounds`; none of
   it is currently reachable for a course other than the viewer's own.
4. **The hero photograph's selection**: the most recent (or most-reacted) `rounds.photo_path` at this
   course from someone the viewer can see, **with the photographer's display name and the round's
   date**, for the credit line. The column, the bucket and the signed-URL cache are all live; choosing
   one and crediting it is not.
5. **The pull quote**: the `posts.body` attached to a round played here, with its author and date.
   Existing rows, new selection. Must be nullable — the block disappears rather than degrading.
6. **Per-hole yardage on the phone**: `api_course_holes.yardage` **already exists server-side** and
   `my_course_books` simply does not select it, so `CourseHole` has no field for it. Carrying it makes
   the drawn card's bar heights real. *Carried, not collected.* Without it the drawn card falls back to
   height-by-par, which makes 11 of 18 bars identical — see deviation D-2.
7. **"Who keeps this course"** is **not buildable today and the design does not claim it.**
   `profiles.home_course` is free text with no `api_courses.id` behind it, so a sentence like *"Galen
   keeps it"* would be a string match dressed as a fact. The empty state uses the schedule instead
   (*"It is on your schedule for Saturday"*), which is real. If the copy is wanted, the new data is a
   `home_course_id` on `profiles` or a `kept_courses` relation.

---

## 8 · The web desk, in one paragraph

Sidebar 236pt as everywhere (§14.1); the body is `1fr + 340`, `gutterDesk` 40. **The plate runs the
full width of the left column at 2.6:1** with the name reversed out of it and the credit flush right —
the desk is where the photograph finally has room to be a photograph. Under it, the facts line (one
line even at desk width) and the pull quote at `story` 21. The **right 340 column** carries the rating
block as the three figures on one rule, the friends as a **spaced** face row with names beneath (the
desk has room for the roster form, §6.3), and the leaf carrying **all eighteen holes** rather than the
front nine — the extra column the phone cannot afford. "Rounds here" becomes a real table with two more
columns (`TEE · DATE · GROSS · VS YOUR BEST`) plus the five-dot form column inside the row (§14.3).
Hover steps a row's ground to `bg1`; **every hover state has a focus twin**, a 2px `brand` outline,
never suppressed; `↑`/`↓` move between rows, `→` opens the round's receipt, `/` focuses course search,
`Esc` closes the rating sheet, and `1`–`5` with `Shift` for halves sets a rating from the keyboard. A
print stylesheet prints the leaf as the scorecard and drops the chrome — the archive test, made
functional.

---

## 9 · Motion — the moments, and only these

| Moment | What happens |
|---|---|
| **Arriving** | the screen pushes on `roll` 320. Nothing on the page fades in |
| **The plate resolving** | the drawn card renders **immediately** from the local book; when the photograph resolves it **wipes over it from the leading edge on `snap` 180**. Never a crossfade, never a fade-in — §11.1: a board graphic arrives, it does not fade in. This also means the page never flashes empty on a cold open |
| **Rating a star** | the rail fills left-to-right on `snap` 180 with `.selection` on each half-step; the `figXL` **tallies** to the new value over 340ms on `snap`; the commit seals with `.impact(.light)`. When the write returns, the community figure re-tallies on `snap`. **No confetti** — the number is the ceremony (§11.3) |
| **Opening the rating** | the fitted sheet rises on `roll` 320 |
| **Scrolling** | nothing moves but the 28pt fade over the tab band. The plate does not parallax, the leaf does not lift, and no shimmer skeleton exists (§11.4) |
| **Reduce motion** | both curves resolve to `nil`, never "faster"; the wipe becomes an immediate swap; the tally becomes the final value. Every rest frame is already the finished state |

---

## 10 · The audit's ten problems, as this surface answers them

| # | Answered here |
|---|---|
| 1 | **No card and no border anywhere on the surface.** The only containers are the plate (an image field), the leaf (a printed grid) and one 64pt panel (one figure). The 2×2 KPI grid is one line of type |
| 2 | Six figures are visual objects: the rating (40 + a 2pt `ink` rule), your best (a panel), each round's gross (27), the four facts (20), the sheet's `4.5` (56) |
| 3 | Four faces on the page above the fold, three more in the rounds list, and a real photograph as the opening object |
| 4 | One primary (`Add my round`, and only in the empty state), one tertiary (`Rate it`), one chip row on the list screen |
| 5 | **No gold object on this surface at all**, which §2.4 permits and which is the honest answer for a page whose headline number is an average. Ember appears only on the primary fill and the Play glyph; the `Rate it` link takes the **2px `mut`** rule, because it is not the screen's live action |
| 6 | Every glyph on the surface is drawn at 1.7pt on a 24×24 box: the star, the back chevron, the empty state's scorecard, every marker. No emoji, no dingbat star, no typed arrow |
| 7 | One `display` (the course), nine tracked-caps agate lines of the ten §1.5 allows, one serif appearance |
| 8 | Loading, empty (two kinds), error (two kinds), stale, no-photo, no-rating, no-quote, never-played — each specified, each with a door |
| 9 | n/a to this surface (no ceremony) — but the rating's tally is sized to what it is: small |
| 10 | The AX3 form is stated per region; the tab band is a band on the page's own ground, so the rounds list runs under a fade rather than being guillotined |

---

## 11 · Screenshot test (brief §28, question 10)

`course-page` is the answer to *"would I be proud to post this?"*. It is a photograph of a golf course
at dusk, a name in a condensed grotesk reversed out of it, a bone tile with your score in it, one line
of golf facts, a 4.6 at `figure` 40 over a 2pt rule with five stars beside it, a sentence in a serif that a friend actually said, four
faces, and a scorecard printed on paper. **Remove the logo and it is still Cup Season.**

---

## 12 · Deviations from `UI_SYSTEM.md` — for the refuters

Each is a rule I obeyed the letter of where I could, and where I could not, the exact line and why.

- **D-1 · L-32's position.** The provenance line moves from *above* the first figure it qualifies to
  directly *beneath* the facts line, as that object's own agate label. It is **never omitted** and it is
  adjacent to the figures — but `CourseCardSheet.swift`'s header states there is no path that renders a
  saved rating without the line *above* it. I moved it because the audit (BF-15) names the
  disclaimer-as-first-paragraph a defect on this exact screen: *"the disclaimer as the first paragraph
  a golfer reads about a golf course."* If the refuters keep the letter, the line returns above the
  facts and costs one agate block.
- **D-2 · The drawn card's bar heights.** §10.1 specifies "eighteen bars, height by yardage, weight by
  par". `my_course_books` does not carry per-hole yardage, so the spec depends on new_data item 6. The
  mockup draws height-by-yardage. **If that field is not carried, the fallback is height-by-par, which
  makes 11 of 18 bars identical** and the plate reads as three tones rather than a course.
- **D-3 · The drawn card's hole numbers.** §10.1 says "hole numbers in agate"; the hero omits them.
  Eighteen 11pt numerals under 18 bars is a chart axis, which §9.10 bans on the product's charts and
  §10.2 bans as a caption teaching the reader how to read the plate. The numbers appear on the leaf.
- **D-4 · The agate count is four only if the plate's credit is part of the plate.** I count
  *"Galen's round · Aug 24"* as part of the plate object — the credit §10.2 *requires* — the way a unit
  label is part of a rule-and-figure. Counted as a stand-alone metadata line it is a fifth block and
  the surface is over §1.5's budget; the fix would be to fold the credit into the facts sub-line.
- **D-5 · The leaf at AX3.** §16.3 says "any table: column heads hide". The leaf's HOLE row is not a
  column head, it is the key the PAR and SI rows are read against; hiding it makes the card unreadable.
  At AX3 the leaf scrolls horizontally with its row labels pinned — the shipped behaviour the audit
  praised.
- **D-6 · RESOLVED, and in the other direction.** This spec raised a colour split — gold when
  displayed, `ink` when interactive — to reconcile §9.11 with LINT-11. The system resolved it by
  removing the metal from **both**: §2.4 now says in as many words that *an average is not earned*, and
  §9.11 sets the rating in `ink` on an `ink` rule with the rail filled `ink` / unfilled `rule`. One
  colour, one object, in and out of a control. The second effect the deviation named — "the
  community's number is the earned metal and your own is not" — was itself the tell.
- **D-7 · The pull quote is `story` 20, not `lead` 28.** §15.3 licenses a pull quote; §1.2 offers two
  serif sizes. At 28 the quote outweighed the course name. Consequence: on the no-image page the one
  serif is the empty headline at `lead` 28 — **the surface's serif changes role with state**, which is
  intentional but is not a rule the system states.
- **D-8 · The plate is 252pt, 29% of the frame.** §15.3 says the image owns "the top third edge to
  edge"; a true third at 402×874 is 291pt and it pushed the rating below the fold. Recorded rather than
  fudged. The desk's plate is proportionally larger.
- **D-9 · The plate spends one of the two panels.** §3.2 licenses a bone panel over a photograph and
  budgets two per viewport; the course page uses one for YOUR BEST, and it is **absent** — not dashed —
  when you have not played there.
- **D-10 · ADOPTED PRODUCT-WIDE.** The system's own `cs-course` mockup set `Rate it →`. LINT-13 fails a typed arrow inside a
  produced string. This surface's link has no arrow — and **`UI_SYSTEM` §5.2 now makes that the
  product-wide form**: there is no drawn link arrow either, because the 2px rule is the affordance and
  the arrow says nothing it has not. `home`, `season`, `event` and `leaderboard` follow this file.

---

## 13 · Known imperfections in the renders, stated rather than iterated a fourth time

(a) On `course-page` and `course-light` the first round slat sits under the scroll fade — this is the
correct "the list continues" cue and not an overflow, but a reviewer measuring the artboard should know
it is deliberate. (b) On `course-page-noimage` the tallest drawn-card bars end ~7pt above the eyebrow's
cap-line; on a device with the real yardage profile the tallest bar varies by course and the build
should clamp the tallest bar to the plate height minus 96pt. (c) The photographs in `course-page`,
`course-light`, `course-rating` and the `course-card` thumbnail are **drawn stand-ins** for a golfer's
own round photo (§10.4). No face is fabricated anywhere in the set. (d) `course-card` combines two real
product regions — the Courses list and Home's wire — on one artboard so the compact card can be judged
at both scales; they are not one screen.


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it, and it is the only surface the review failed.** Instantly 2/3 · looks
like Cup Season 2/3 · **premium 0/3** · template 1/3 · **proud to post 0/3** · **belongs in the
category 0/3**. Median **6.9** — the lowest of the seven. Two of the three named the same single cause,
and the third named it twice.

**1 · The hero is a photograph (§10.1).** There was no photograph in five course renders: the page
drew the contour and the `-noimage` variant drew eighteen unlabelled bars as its hero. blind-1: *"Course
discovery is a photographic category."* blind-2: *"The hero is a near-black topo field where every
competitor puts a photograph. This is the surface that most needs one — courses are the app's
scenery."* blind-3: *"Random bar heights representing nothing, as the hero of a page about a real
place … fake data as ornament is less premium than a plain color."*

The page (dark **and** light) now opens on a round photo at its true 402 × 268, credited
`GALEN'S ROUND · AUG 24`, with the plate scrim lightened at the horizon so the photograph is visible
rather than merely present. **The `-noimage` variant keeps the drawn card, and the drawn card became
real**: eighteen bars, height by yardage, width by par, **gold on the #1 stroke hole**, numbered 1–18
in `colS` beneath — and the sentence twenty points below it, which the page was already printing,
says *"the 6th plays hardest"*. Nothing teaches the reader how to read the graphic; the page's own
facts do it.

**2 · The rating is one number, one comparison, one action (§16A.3, brief §12).** All three filed the
same band: `4.6` + a star row + `24 RATINGS` + *"Your golfers give it 4.9"* + *"You haven't rated it"*
+ `RATE IT` — **five expressions of rating in one 120pt band**, and blind-3 called it "the most
cluttered 120px in the product". It is now `4.6 / CUP SEASON · 24 RATINGS` beside the star rail, one
line — *Your golfers give it 4.9.* — and `RATE IT`. The sheet's three exits became two.

**3 · Every row carries the same left object.** Gold Canyon's missing thumbnail broke the rail
mid-list and all three read it as a load failure rather than as "unplayed". Its card **is** cached —
its own page prints the pars — so it draws one. Every thumbnail is now the front-nine drawn card at
nine bars and three heights by par, per §10.2, rather than a twelve-to-fourteen-bar comb that three
reviewers read as an audio waveform.

**4 · A course name wraps to two lines.** *"The Raven Golf Club at Verrado · Founde…"* truncated the
tee, and in golf the tee is often the whole distinction. Two lines, clamped, tail ellipsis only past
that.

**5 · One casing rule, and the number column is headed.** Five rows used three casings; they now use
one (small-caps labels, sentence-case place names). `YOUR BEST` sits over the `81 / 86 / 88` column,
and the unplayed row shows an em dash there rather than borrowing the column for a date — the date
moved into its own meta line.

**6 · On cream stock the leaf has an edge and the markers have ink.** The scorecard inset lost its
boundary against the light page (blind-1) and the overlapping marker discs were near-invisible in one
theme or the other (blind-3). The leaf carries a 1px inset rule; `.paper .disc svg` takes `ink`.
