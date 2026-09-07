# THE VISUAL PASS — the owner's second round, answered

> Received 2026-09-07, on **cupseason.app in mobile Safari at 390px**, not the app.
>
> *"Better but these are bland. What do we need maybe in league creation to make these tabs
> visually more appealing. Trophies and recent rounds also not engaging. Maybe that is waiting photo
> dynamic but it should be more of a visual. Think Strava. Future rounds should highlight holes if we
> have that info, what we thought of the course etc. a record of the courses we like"*

What he photographed: six consecutive rounded rectangles, each a grey circle-with-a-flag and two
lines of text, with **the same fact printed once per league** — *"You took the week"* twice, *"The
clash: X v you"* twice, *"The clash closes today"* twice.

This document answers the six things in his order. Every data claim below was **read out of the
migrations, the client and `supabase migration list` on 2026-09-07**, not assumed. Where a design
needs a fact nothing produces, it says so and degrades.

---

## 0 · What was verified, before anything was designed

| Claim | Verdict | Evidence |
|---|---|---|
| `course_ratings` is live in prod | **TRUE** | `20261007090000` appears in both the Local and Remote columns of `supabase migration list`; `deploy-status` reads 215 applied / none pending. The migration's own header ("THIS FILE HAS NOT BEEN RUN") is now **stale** — rule 2 leaves it uncorrected in the file; this line is the correct version. |
| `course_rating` / `rate_course` / `unrate_course` granted to `authenticated` | **TRUE** | each carries its own `grant execute … to authenticated` and a `revoke … from public, anon`; the migration's own self-check raises unless all three are executable by `authenticated` and none by `anon`. |
| Anything on either client calls them | **NO** | grep of `index.html` and `CupSeasonKit` finds only the `api_course_tees.course_rating` **column**. Zero RPC callers. `index.html:13591` hardcodes `csStarsSvg(0, true)` under a comment that says the function is unpushed. |
| `api_course_holes` carries par, stroke index **and yardage** | **TRUE** | `20260714050000:49–52` — `hole_number, par, yardage, handicap`. |
| Any authenticated golfer may read it for any cached course | **TRUE** | policy `api_course_holes_read … for select to authenticated using (true)`; both clients already select it directly (`index.html:10501`, `LiveRepository.swift:316`). |
| `my_course_books` omits per-hole yardage | **TRUE** | it selects `'hole', 'par', 'si'` only. One column short of drawing height-by-yardage offline. |
| `my_schedule` returns the course id | **TRUE** | `20260924093000:184` returns `course_id text`. |
| `my_achievements` returns `round_id` | **TRUE**, and applied | `20260902173000:200`. The desk already reads it with a guard (`a.round_id||null`) and wires `data-achr` → `openRoundReceipt`. |
| `home_stories` (the feed producer) carries a course id or a live-round id | **NO** | `20260908090000:104–109` returns `course text` — the **label** — and nothing else about the course. This is the one real data gap in this document. |
| `posts.round_id` exists and is readable | **TRUE** | baseline `posts_round_id_fkey → rounds(id) ON DELETE CASCADE`; the only grant migration on `posts` (`20260902210000`) touches INSERT only and states SELECT is "deliberately unchanged". |
| The desk selects it | **NO** | `HCOLS` (`index.html:25277`) and `PCOLS` (`:25299`) omit `round_id`. So `p.round_id` at `:15365` **is always `undefined`** and the `spent` filter has never once fired on a post. |
| `rounds` carries column-level grants | **NO** | no `grant select (…) on public.rounds` exists in any migration; the freeze is on `profiles`. Adding `api_course_id` to a client select needs no migration. |
| `rounds` has a note / caption column | **NO** | baseline `:1244–1269`. Neither does `course_ratings`. **"What we thought of the course" has no text home today.** |
| `leagues.look` exists and is granted | **TRUE** | `20260827200000`; `league_looks()` + `set_league_look()` both granted to `authenticated`. |
| The **phone** reads it | **TRUE** | `CupSeasonKit/Looks/LookStore.swift`. |
| The **desk** reads it | **NO** | zero hits for `league_looks` or `set_league_look` in `index.html`. |

---

## 1 · THE DESK FEED — the screen he photographed

### The diagnosis, in three lines of code

1. **`postRow` emits one card per post** (`index.html:15015`). `round_to_board()` fans one round into
   every league the profile belongs to. Two leagues → two identical cards. That is the repeat.
2. **The dedupe was written and has never run.** `renderHomeFeed:15365` filters posts on
   `p.round_id`, and `round_id` is in neither posts select. The filter reads `undefined` forever.
3. **The heads are quieter than the rows they head.** `.feedsec` (`:1701`) is mono **10.5px** in
   `dim`; the rows under it are 15px/650 in `ink`. The desk *has* Today / This week / Earlier — they
   are simply outranked by everything beneath them. That is why "sections aren't differentiated" is
   still true here after the phone fixed it.

### What it becomes

**a. The heads outrank the rows.** `.feedsec` becomes `display` — Plex Cond Bold, UPPER, `ink`, no
rule and no box (§32) — and the wire runs under the phone's own four datelines
(`HomeWirePeriod`): **COMING UP · TODAY · THIS WEEK · EARLIER**.

| | desk (340 aside) | 390 (full width) |
|---|---|---|
| dateline | `display` **24 / 0.98**, `ink`, `margin:26px 0 10px` | `display` **22**, `margin:22px 0 9px` |
| step over the row beneath | 24 → 15 = **1.6×**, plus `ink` → `mut` | 22 → 15 = **1.47×**, plus `ink` → `mut` |

`COMING UP` has a producer today with **zero new reads**: `window.mySchedule` / `window.watchAll`
are already in memory on Home (`:14127`, `:16065`). Merging them in is one `.concat`.

**b. The fold, three rules in order.**

1. **One round, one row.** Group posts by `round_id`; the first survives, the rest are dropped, and
   the survivor's league line becomes `Fellas & Who's the bitch?` rather than one league.
2. **A round the deck already told is not told again.** `window.__spentRounds` exists and works for
   `homeFeedRows`; with `round_id` selected it starts working for posts too. Same fix, no new code.
3. **The residue is ONE line, at the foot.** Every surviving league note collapses into the desk's
   twin of `HomeWireNotes.line`: `Fellas & Who's the bitch? · 14 league notes`, and past two leagues
   `3 leagues · 14 league notes`. `bodyS` 15 in `mut`, no avatar, no card. It opens the board.
   The string is produced once and shared (D234) — the phone already owns it.

**c. The weights — five, and what each one is at both widths.**

| # | What | desk 340 | 390 |
|---|---|---|---|
| **1** lead | `#homeLead`, left column — never in the wire | — | sits **above** the wire when the columns stack, which is correct |
| **2a** round **with** a photograph | `.hfstory` unchanged, full-bleed | 340 × 200 | 390 × 240, bleeds both edges |
| **2b** round **without** one | **the card becomes a slat.** No border, no radius, no `bg1`. A 1px `rule` top edge; 44pt face; name `social` 17 `ink`; phrase `bodyS` 15 `mut`; gross a **bare tabular `figure` 27, right-flush, no rule** (§9.2 — a column takes no rule-and-figure) | 76pt row | 84pt row |
| **3** competition item | lives in `#homeDeck`, left column | — | above the wire when stacked |
| **4** season moment | `#homeOccasion`, left column | — | above the wire when stacked |
| **5** quiet | a surviving league note: one `bodyS` 15 `mut` line + a trailing `agateS` stamp. **No avatar, no dashed card.** | 44pt | 44pt |

**d. `.hfcard.quiet` is deleted.** `bg2` + `border-style:dashed` (`:1177`) is the exact object he
photographed six of. A quiet thing is quiet by being small and grey — not by being a card with a
dashed edge (§27, §32).

**e. The date stamp takes D285's rule.** A row under `TODAY` prints no date; inside a group, a stamp
equal to the row above it is dropped. Today `.hfmeta` prints `course · date` on every single row.

**Component / producer:** `feedBuckets`, `feedRow`, `postRow`, `.feedsec`, `HomeWireNotes` (phone).
**Data:** all present. The only change is adding `round_id` to `HCOLS`/`PCOLS`, guarded by the
existing skew retry. **No migration.**
**Degrades to:** if the `round_id` select errors, the retry drops the column and the feed renders
with heads and weights intact and no dedupe — i.e. strictly better than today, never worse.

---

## 2 · THE ROUND AS A VISUAL OBJECT — "think Strava"

Strava's feed item is a map because **the route is the activity**. Golf's route is the hole sequence,
and there are exactly two things drawable from real data: the **course's shape**, and the **round's
shape on it**.

### The primitive already exists

`csDrawnCardSvg` (`index.html:13480`) draws eighteen bars, **width by par** (3 → 0.78, 4 → 1.0,
5 → 1.30), **height by yardage** where the book has one and by par where it does not, numbered
beneath — and **returns `''` when there is no real card**, because *fake data as ornament is less
premium than a plain colour*. It ships today on the course books. The round item is that drawing with
the round on it.

### THE SHAPE OF THE ROUND

A **340 × 96** (desk) / **390 × 110** (390px) drawing, sitting above the slat from §1:

- eighteen columns, **width by par**, so the drawing is recognisably *that course* — Papago's
  back-to-back par 5s are two wide columns, Troon North's four par 3s are four narrow ones;
- a **baseline at par**, 1px `rule`, running the full width;
- each hole drawn as a bar **from** the baseline: **under par UP, over par DOWN**, level = no bar.
  In `ink` at full and `mut` at 56%. **No colour at all** — §9.4's rule, drawn the way a paper card
  is drawn, so it is never colour-only and needs no legend;
- the hardest hole (SI 1) marked by a hairline tick **below** the baseline, its numeral in `agateS`;
- beneath, in `col` 14 tabular: `OUT 41 · IN 38`.

**One ruling this pass takes:** **no gold in the drawing, in any state.** Gold means a thing that was
won (§2.4), and neither the hardest hole nor a hole's par is won. `csDrawnCardSvg` currently fills
the SI-1 hole `gold` — that is the same category error §9.11 spent a paragraph removing from the
rating, and it should move to `mut` at full opacity. *(Filed; it is a two-token change.)*

### Where the strokes come from, and what it degrades to

| State | Drawn | Frequency |
|---|---|---|
| a **photograph** exists | the photograph wins — §10.1 rung 1 is unchanged | rare on this account (**zero** round photos on the owner's) |
| **strokes** exist (`rounds.live_round_id` set — a round scored in the app) | the full shape above, under-and-over par per hole | the minority |
| **course known, no strokes** (`rounds.api_course_id` set — every round posted through the picker) | the **course's** card alone, `rule` at 56%, the gross as a `figure` 27 sitting on it, eyebrow `THE COURSE, NOT THE ROUND · PAPAGO · PAR 72`. Still drawn from real data; does not pretend to be a scorecard. | **the majority** |
| **hand-typed course** (a label, a rating and a slope) | **nothing.** The row is the §1 slat — face, name, phrase, gross. | the rest |

### The data gap, stated plainly

`home_stories` returns `course text` — a **label** — and no `api_course_id` and no `live_round_id`.
**A feed round cannot draw anything today.** The fix is two columns on one function; because adding a
column to a `returns table` function is a 42P13, it is `drop function` + recreate in one new
migration, plus its grant. That is the whole cost.

Then: the feed draws the **course** shape inline (one extra read of `api_course_tees` +
`api_course_holes` for the courses on screen, cached), and the **stroke** shape only inside the
receipt sheet the row already opens — `live_round_card` is already wired there (`openScorecard`,
`:15040`). One read per feed, not one per row.

**Component:** `csDrawnCardSvg` (extended with a strokes argument), `feedRow`, `openRoundReceipt`.
**Data:** par/SI/yardage EXIST and are readable. The **link from a feed row to its course does not.**
**Degrades to:** the plain slat, always, with no error and no empty box.

---

## 3 · TROPHIES AND THE RECORD

### What exists — read first, per the brief

`renderTrophyCase` (`:17052`) is already **slats, not tiles**: a 28pt **drawn** mark, the name in
`name` caps, a dated `agateS` sub-line, one `rule` on the top edge, plus the engraver (a trophy that
lands *during* a session takes its name behind a sliding gold cover). `ACH_META` gives ten distinct
glyph keys, and `threshold` / `streak` / `lowRound` carry a **numeral** so no two share a mark
(§5.2). `csTrophyMark` draws every one of them; there is no colour emoji.

**So the canon is already kept.** What is missing is not compliance — it is **scale and consequence**.
Every slat is the same height, every mark is 28pt, and a Cup sits at exactly the weight of *"Posted"*.

### What it becomes

**a. The record is a rule-and-figure, not a grid of counts.** `renderCareerRecord`'s `.recgrid`
becomes one line: the largest count as **`figure` 40 over a 2pt `ink` rule** with `CUPS` beneath
(§9.2), the rest as bare `figure` 20 on the same baseline — `2 CUPS · 1 POINTS CROWN · 1 EVENT ·
1 RUNNER-UP` — and the settled money as its own `figure` 27 under `SETTLED ACROSS 3 SEASONS`.
One object, one scale.

**b. The case gets three sizes and three heads.**

| Group | Head | Mark | Line | Door |
|---|---|---|---|---|
| **Hardware** — Cup, points crown, major, event, runner-up | `HARDWARE` | **44pt** | name `name` 17, year `col` 14 trailing | the season |
| **Bests** — broke 80/90/100, personal best, low round | `BESTS` | 28pt | **the round it was won on**: `79 at Papago · Aug 24 ›` | **opens the receipt** |
| **Along the way** — first round, streaks, Iron Man | `ALONG THE WAY` | 28pt, `mut` sub-line | quiet | none |

**The door is the change that makes it engaging.** A badge is inert; a milestone that opens the
afternoon it happened is not. And **the wiring already exists** — `my_achievements` returns
`round_id` (applied 2026-09-02), and `renderTrophyCase` already emits `data-achr` →
`openRoundReceipt`. Today that door is buried under an undifferentiated run of equal slats, so
nobody finds it.

**c. The empty gets a shape** (§17). Not `.card` + one grey line. Four **uncut** marks — `cup`,
`threshold 80`, `personalBest`, `streak` — drawn in a row at 12% opacity, under `THE CASE IS EMPTY`
and one line: *"Break 80, post a first round, or win a Cup Final."* No button; the ⊕ is a tab an inch
below (D177's own ruling).

**d. Recent rounds — the other half of his sentence.** `#youRecent` (`:17246`) is `.fine` rows: a
13.5px bold, two greys and a delete ×. It becomes **`formRowHtml`'s big brother** — that object
(`:17160`: five grosses on one rule, best in gold, the date beneath) is already right, and the recent
list should be the same object at row scale: the gross as `figure` 27 **right-flush on a shared right
edge**, the course in `nameS` 15, the date in `agateS`, and a **60 × 18 sparkline of the round's
shape** where §2's card exists. Not a paragraph with a number in it.

**Component:** `renderTrophyCase`, `csTrophyMark`, `renderCareerRecord`, `formRowHtml`.
**Data:** `trophies`, `achievements` (with `round_id`), `careerRec` — **all in memory today. Nothing
new, no migration.**
**Degrades to:** no `round_id` → the Bests slat is a slat with no door, exactly as today.

---

## 4 · A PLANNED ROUND

*"Future rounds should highlight holes if we have that info"* — we do, for any course whose tee has
been cached, and the plan already carries the key.

Above the tee time, on the plan's own row:

- **The card, drawn** — `csDrawnCardSvg` unchanged, 340 × 84, the whole eighteen, width by par,
  height by yardage.
- **THE THREE THAT DECIDE IT** — the three lowest stroke indexes as three **`figure` 27** hole
  numbers on one rule, `PAR 4 · 458 · SI 1` in `agateS` beneath each. This is the fact a golfer
  actually wants the night before, and it is the literal answer to his sentence.
- **The turn**, in `col` 14: `OUT 36 · IN 36 · 7,068 YDS · 73.3 / 137`.
- **Your history here**: *"You have played Papago 4 times · best 78 · last 82."*
- **The rating** from §5, so the night before you play you see what your golfers thought of it.

**Component:** the schedule row, `csDrawnCardSvg`, `CS_COURSE_COPY`.
**Data:**
- `my_schedule.course_id` — **EXISTS** (`20260924093000:184`).
- par / SI / **yardage** per hole — **EXIST** and are readable by any authenticated golfer
  (`api_course_holes_read`); both clients already select the table directly.
- `par_total`, `total_yards`, `course_rating`, `slope_rating` — **EXIST** on `api_course_tees`.
- "played here 4 times, best 78" — the desk already pulls 400 of the golfer's rounds into
  `window.career` (`:25116`). It needs **`api_course_id` added to that one select**; `rounds`
  carries no column grants, so that is one word and **no migration**.
- **Worth taking with it:** `my_course_books` omits per-hole `yardage`, so the phone's offline card
  draws height-by-par while the desk draws height-by-yardage — the same course, two shapes. One
  column in one new migration fixes it.

**Degrades to:** no `course_id` (a hand-typed course) → no card and no three-hardest; the row keeps
its tee time, field and game. Tee never cached → `csDrawnCardSvg` returns `''` and the block prints
`CS_COURSE_COPY.noCard`, which already exists and already says the right thing.

---

## 5 · WHAT WE THOUGHT OF A COURSE, AND A RECORD OF THE ONES WE LIKE

**This is the piece with the most new value and the least existing UI, and it is unblocked as of
today.** Three RPCs are live, granted, and called by nothing.

### 5.1 The act — half stars, one tap, reversible

`csStarsSvg` (`:13513`) already draws five stars, filled `ink` / unfilled `rule`, halves by
**clipping** the fifth star rather than by a second glyph. It is a picture. Make it a control:

- **32pt** on the course page. The target is each star's **two halves** (16 × 32). One tap sets
  0.5 – 5.0. **No confirm, no sheet, no submit.**
- On tap the rail fills **immediately**; `rate_course` runs; the returned aggregate re-tallies the
  three figures from the server's own arithmetic — the RPC returns `course_rating()` for exactly this
  reason, so the client never adds one to a number it was holding. On error it reverts and toasts.
- **Reversible in one tap**: tapping the value you already set calls `unrate_course`.
- The label beneath says which state you are in — `YOUR RATING · 4.5` or `NOT YOURS YET`.
  **Null, never zero, never a dash** (L-44; the RPC returns null by construction).
- §22: the newly filled stars sweep left-to-right over 180ms. Nothing else on the page moves.

### 5.2 The aggregate — one read, one rule

```
4.5            ★★★★★            ← figure 40, drawn rail beside it
──────────────────────           ← 2pt ink rule (§9.2)
CUP SEASON GOLFERS · 24 RATINGS  ← agate

Your golfers 4.5 (6)  ·  Yours 5.0   ← body 15
```

**No gold in any state.** An average of opinions is not earned (§2.4) — and the migration's own
header says the same thing. The rating's weight comes from **size and the rule**.
**Unrated** = the full-size **unfilled** rail plus `NOT RATED · THE FIRST RATING SETS THE NUMBER` —
never a hidden or shrunken control.

All three figures and both counts come from **one** `course_rating(text)` call.
**`index.html:13581–13592` currently hardcodes `csStarsSvg(0, true)` under a comment stating the
function is unpushed. That comment is now false. It is a two-line change.**

### 5.3 "What we thought of the course" — the one honest gap

`course_ratings` has `stars` and nothing else. `rounds` has no note or caption column. **A sentence
about a course has no home in this database today.**

**Recommendation:** `course_ratings` gains one nullable `note text` column, capped at 140 characters,
written by the **same call** — `rate_course(p_course_id, p_stars, p_note text default null)`, so a
client that predates it still works and neither deploy order breaks a live user. `course_rating()`
returns your own note plus up to three of your golfers'. **Cost: one migration, one 140-character
field under the rail on each client.** It is the smallest possible version of his sentence, and
without it the KEPT COURSES record below is numeric rather than readable.

### 5.4 KEPT COURSES — the record of the courses you like

The surface already exists: `renderCourseBooks` (`:13526`) on `#youCourses`, fed by
`my_course_books`. Today it renders every kept course at equal weight in schedule-then-recency order
with a hardcoded unrated rail. The record he asked for is **that list sorted by your own rating**,
with the unrated below a rule.

```
COURSES YOU LIKE · 7 RATED
─────────────────────────────────────────────
PAPAGO GOLF COURSE                  ★★★★★ 4.5
Phoenix, AZ · 4 rounds · best 78 · Aug 24
▁▃▂▅▁▄▃▂▆▁▃▂▄▁▅▃▂▄          ← the drawn card, 40pt, rule at 56%
"Best muni in the state and it isn't close."   ← story 20, when a note exists
─────────────────────────────────────────────
ALSO KEPT · 11
TROON NORTH · MONUMENT              ☆☆☆☆☆ RATE IT
```

Name `display` 24 · place and history `agateS` · the rail 20pt trailing · the card as the row's own
plate · the note in `story` 20 serif. **No card is a card-inside-a-card** (§32) — the row is a rule,
a plate and three lines.

**Component:** `renderCourseBooks`, `csStarsSvg`, `csDrawnCardSvg`, `csContourSvg`.
**Data:** the rating — **LIVE TODAY**. The list — **LIVE TODAY**. `best 78` — one word
(`api_course_id`) on the career select, no migration. The note — **one migration**.
**Degrades to:** no rating → the row falls below the rule with an unfilled rail and `RATE IT` as a
tertiary link. No card cached → the plate is `csContourSvg`, which is live. No note → three lines
instead of four. RPC missing → the unrated rail, no error — exactly what ships today.

---

## 6 · THE LEAGUE-CREATION QUESTION, ANSWERED

> *"What do we need maybe in league creation to make these tabs visually more appealing?"*

**Nothing new. The hook already exists and the desk never reads it.**

- `leagues.look` is live (`20260827200000`), constrained to a token key, with `league_looks()` and
  `set_league_look()` both granted to `authenticated`.
- The **phone** reads both (`CupSeasonKit/Looks/LookStore.swift`).
- **`index.html` calls neither.** Zero hits. On the surface he was actually looking at, a league's
  look does not exist.
- `packages/tokens/tokens.json` already ships **eleven** looks with light and dark accents —
  Azaleas, Silver, The Test, Stars, Claret, Two Teams, Fall, Evergreen, Fresh, Cup Final, The Wrap.
- UI_SYSTEM §2.7 already gives the look its one job: **it tints the rail and the eyebrow, and nothing
  else.** Never a ground, never ink, never `pos`/`neg`, never gold.

### Recommendation, in three parts with costs

**1 · Wire `look` on the desk. (~40 lines, no migration, no wizard change.)**
One `league_looks()` read at boot into `window.CS.looks`; one `--look` custom property set per
league surface; §2.7's job — the 4px rail on a feed row, the league eyebrow, the season eyebrow.
**This is the whole of "make these tabs visually more appealing", for free.** The two leagues
repeating down his feed stop being interchangeable the moment one has a green rail and the other a
claret one. *Do this first; it may be the entire answer.*

**2 · Add ONE step to the wizard, and make it the look. (One step on both clients + one
`set_league_look` call. No migration.)**
Not a colour picker — six named looks as six 64pt swatches with their names, defaulting to the
season's calendar look, **skippable**, four seconds. The wizard is three steps today (`data-step`
0–2); this is step 3 and it is the only one that is optional.

**3 · DECLINE the crest and the photograph.**
A crest is an upload path, moderation, a private bucket, a signed URL on every league surface and a
fallback for the majority who skip it — all for a mark rendered at 24pt. A **home course** is more
tempting, because it would earn a league a real plate through §10.1's ladder; but `leagues` has no
course column, a league's home course is a fact the product uses nowhere else, and the plate it would
buy is already available from the members' own round photos at the courses they actually play. Both
cost more than the look and buy less identity.

### The honest note

**His league tabs are not bland because the wizard captured too little. They are bland because the
desk never read what the wizard already captures.**

---

## 7 · The verdicts

| # | Item | Verdict | Reason |
|---|---|---|---|
| 1 | The desk feed — fold, datelines, weights | **BUILD NOW** | every fact is in memory; `round_id` on two selects is client-only and skew-guarded. This is D285's layout half arriving on the desk (D234). |
| 2 | The round drawn — "think Strava" | **NEEDS DATA** | par/SI/yardage exist and are readable, but `home_stories` returns a course **label** and no `api_course_id` / `live_round_id`. One `drop`+recreate migration unblocks it; until then the row is the §1 slat. |
| 3 | Trophies and the record | **BUILD NOW** | marks, glyph uniqueness, the engraver and `round_id` all ship today. This is scale, three heads and a door, not new data. |
| 4 | A planned round | **BUILD NOW** | `my_schedule.course_id` and the hole cards are live. (`my_course_books` gains `yardage` alongside, so both clients draw one shape.) |
| 5 | Ratings + kept courses | **BUILD NOW** (the note: **NEEDS DATA**) | the three RPCs are applied and granted and nothing calls them; `index.html:13591` hardcodes the unrated rail under a comment that is no longer true. The 140-character note is the one migration. |
| 6 | League creation | **DECLINE the feature — BUILD the wiring** | `look` exists, the phone reads it, the desk does not. Wire the desk first; the wizard step is a four-second nicety after that. Crest and photograph both declined on cost. |

---

## 8 · The artboards

Drawn at the two widths that matter — **402 × 874** (his 390px measure plus the frame) and
**1440 × 900** (the desk's own arithmetic: 236 + 40 + 744 + 40 + 340 + 40). Cast: Sam Ridley, Galen
Marr, Jade, Tash Bell. Courses: Papago, Troon North · Monument, Gold Canyon · Dinosaur Mountain, with
real par, stroke-index and yardage sets. Every drawing on every board is generated from those arrays
by the same two functions the product already ships.

| Board | What it shows |
|---|---|
| `p1-wire` | §1 — the wire at 390: four datelines outranking their rows, a round DRAWN, a round degraded to the course, a round degraded to a slat, fourteen league notes folded to one line |
| `p2-course` | §5 — the drawn card as the plate, the rating act and aggregate on one rule, the note, and COURSES YOU LIKE |
| `p3-case` | §3 — the record as one rule-and-figure, the case in three sizes under three heads, a best that opens its round, recent rounds with the round's shape, and the empty given a shape |
| `p4-plan` | §4 — the card drawn, THE THREE THAT DECIDE IT as figures, your history here, and the honest degradation stated |
| `d1-desk` | §1 + §2 at desk width — the lead, the deck, what you are about to play, and the 340 wire under its datelines |
| `d2-look` | §6 — the same two feed rows unwired and wired, the six-swatch wizard step, the eleven looks that already ship, and the cost in full |

**Two things the boards deliberately do not draw:** a photograph (the owner's account has none, and
§10.1 rung 1 has to degrade to rung 2 to be worth anything), and gold anywhere on a rating or a hole
(§2.4 — neither is won).
