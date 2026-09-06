# SURFACE SPEC — the player card (**the card**)

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 of 3 (design; nothing is built)
**The standard** `BRIEF.md` §9 (player cards), §5, §6, §8, §16, §31, §33, §35
**The system** `UI_SYSTEM.md` — every rule below is that document's unless a §"Deviation" number says otherwise
**The evidence** `UI_AUDIT.md` §2.11 (the person page), §2.13 (the card), §2.10 (the Golfers board), D8, GP-09/13/14/15/16/27/29/30, CH-01/02/03/04/06/07, YRS-03/04/26/27
**Mockups** `mockups/player-card.html` → `mockups/renders/player-card/` — five artboards at 402 × 874, rendered 2×

| Artboard | What it proves |
|---|---|
| `player-card-photo` | the credential as an **object** on the ceremony ground with a photograph: the gold slot, the display name on the measured scrim, the medallion, three figures on one rule with the movement mark, the folio · the status sentence · the one ember primary |
| `player-card-marker` | the **marker floor**, designed rather than degraded: the crest at emblem scale over the home course's contour, **no gold anywhere on the card**, a two-figure strip because no index has been established, the form row **rendering two columns and no blank slots**, and the two-tier action for a golfer who is not yet a buddy |
| `player-card-record` | the second screenful: the form row at full height, the golfer's own **slat** off the season board (movement · gap · points), the head-to-head row with the overlapping pair, the courses with drawn-card thumbnails, and the doors out |
| `player-card-in-list` | **a person in a list is a slat, never a card** — the Golfers board with the rank rail in two field states and faces in every row — and the one place a small card is legal: **the clash**, two compact cards facing, with the record on a rule beneath |
| `player-card-light` | your own card on the morning tee sheet: the object **keeps its own ground and its own gold in both themes**, and everything around it is paper (audit D8, answered) |

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · What this surface is, in one paragraph

**The card is the one object in the product a golfer would keep.** It is not a layout, not a
profile header and not a stat block: it is a fixed-ratio card with a bleed, a slot, a seal and a
serial, sitting on the page with a real lift shadow, printed on the ceremony ground in **both**
themes because a physical card does not change colour when the room does. Everything under it is
deliberately flat — a sentence, an action, then a printed record — so the card is the only thing on
the screen with depth. §9 of the brief lists seven facts; all seven are here and **none of them are
crammed**, because the card itself carries only the four that are permanent (face, name, number,
position) and the three that move (status, form, course activity) live in the rows beneath it, in
the order a golfer asks for them.

**It answers the audit by name.** Problem 1 (the card is the only container): this is the one surface
where the container is *earned* — it is the "object" of `UI_SYSTEM` §3.4, and nothing else on the
screen is boxed. Problem 2 (numbers are not objects): four `figure` renderings replace ten. Problem 3
(no face anywhere): `CSFace` appears in every board row, every slat and both clash cards. Problem 5
(gold is not "earned only"): the slot is the only gold field on the card and it is absent when
nothing was earned — `player-card-marker` carries no gold at all. Problem 6 (five glyph vocabularies):
every mark here is drawn at 1.7pt; the `✦` and the emoji milestone lines are gone. Problem 7 (no
display tier): the name is `display` 34, which is where §5 of the brief puts a player's name and where
GP-09 (P0) says the shipped SF-title3 name is not.

---

## 1 · ANATOMY — the credential, top to bottom

**`UI_SYSTEM` §6.5 is the object's single anatomy of record, and this spec does not restate it.** This
file and `profile.md` both rebuild `CredentialCard.swift`, `CredentialFace.swift`, `YouHero.swift`,
`PersonPage.swift` and `FoundingTag.swift`, and both cite GP-16 ("one object, two chromes, two aspect
ratios, two meta strings") as the defect they close — so two disagreeing anatomy tables would reopen
GP-16 inside the design that closes it. One table, in the system, where a shared object belongs.

What §6.5 rules, and what changed in this file as a result:

- **`362 × 312`** (≈ 7:6 landscape), `r` 16, `shadow-lift`, ground `ceremony` in every theme,
  **measure-relative** (335 × 289 on an SE). This file had specified 362 × 440 (3:4) and `profile.md`
  362 × 312; the landscape wins, because a 3:4 object is 483pt tall at the 362pt measure and puts the
  page's ranked action below the tab bar on every device (F-8 / GP-19 / YRS-25). **The 3:4 portrait
  survives only as the share PNG**, which has no fold and no chrome under it — §7's third size.
- **The medallion appears only over a photograph.** This file's D-3 (*the crest or the corner, never
  both*) is adopted product-wide, which also deletes `profile.md`'s known collision between the gold
  ring and the crest's canopy.
- **The identity line is one string**, `CredentialCopy.identity`: `@GALENM · MESA, AZ · PAPAGO` —
  handle, city, home course. **`EST. JUL 2026` is out** (YRS-21): the founding fact is already the gold
  slot and the folio's serial, and a third telling is the duplication GP-17 names.
- **Secondary ink is `ceremonyMut` `#9BA69D` — 7.71:1 in both themes** — not `ceremonyInk` at `a56`.
  The `a56` composite is `#8B8F8B` at 5.92:1 and it is now a named token, `folioRule`, used for the
  folio alone. *(This file's 5.85 and its 2.99 for `dim` were both slightly off; the conclusion — `dim`
  is forbidden as text — was right, and §16.1 now states it as a product-wide deletion.)*
- **Every metal on the object comes from the ceremony ramp** (§2.1, §2.8), pinned to its dark value in
  both themes: `ceremonyGold` 9.65 for the slot and the medallion, `ceremonyBrand` 5.75 for the live
  tag, `ceremonyMut` 7.71 for the identity line and the figure labels. Without the ramp the light
  theme rendered the `FOUNDER` slot at **3.05:1** and the live tag at **3.19:1**, and the artboards
  were painting values no token could produce.
- **The three figures share a 2pt `ceremonyInk` rule** (17.51:1). Never `ink`, which is 1.11:1 on
  `ceremony` in light.
- **The ordinal rider is `max(11, numeral × 0.4)`, uppercase** (§1.6) — a floor, not a ratio: 40% of
  `figure` 20 is 8pt, and §16.2's floor is 11.
- **No border, no inner seam. Four borders on one object (GP-30) become zero.**

**Why the folio.** A serial line is what separates a collectible from a dashboard, and it is the
archive test made literal — it is the only element on this surface that exists for no functional
reason and it is the one that makes the object feel kept. It is also honest: the marker's **name**
("The Lone Tree") is a fact the product owns, and the serial degrades (§7).

### 1.1 Under the card — the page, in order

| Block | Type · spacing |
|---|---|
| **The status sentence** | `s4` 20 under the card. `body` 15 in `mut`, **sentence case**, with the gross as a **figure run** (§1.6): *"Posted **74** at Papago on Sunday."* Live: `ink` with a 7pt `brand` dot leading — *"Playing Papago right now — thru 12."* No round: **the line is not drawn** (L-44) |
| **The action** | `s3` 12 under the sentence. **One primary, 50pt, `rc` 10, `brand` fill, `bg0` label in `name` 17** — and it is ember because it is the live thing you can do now (§2.4). The tier is chosen by the relationship, not by the screen: **a buddy → `Play Galen`** (primary, alone); **not a buddy → `Add buddy`** (primary) + **`Play Tash`** (secondary, `bg2`, intrinsic width, `s2` 8 gutter); **a pending ask → the primary becomes a `tag`** (28pt, `bg2`, `agate` in `mut`: `ASKED`) — *there is nothing to tap that cannot do anything*. Your own card: **no body action at all**, and the screen carries no ember |
| **FORM** | `s5` 32. Section head: `agate` 12 `FORM` + 1px rule to the margin + `agate` 12 count flush right (`LAST FIVE`, or **`2 OF 5 ROUNDS`** — a posted round is a *round*; "card" is reserved for the person and for the scorecard, T-01) |
| **The form row** | `s3` 12. Five equal columns: the gross in `figure` 20 above a **2pt `ink` rule**, the date in `agateS` 11 `mut` `s2` 8 beneath. **The best gross and its date are `gold`, and the rule under that column is `gold`** (§9.7 — shape *and* hue, §16.4). **Fewer than five rounds → the row renders only the rounds that exist**, left-flush, on a rule spanning only them. **No blank slots and no em dash** — §9.9's "the value slot never renders a dash or a guess", four times over across these specs; and three empty slots make a two-round golfer's row read as a five-round row with failures in it. The section head's count (`2 OF 5 ROUNDS`) is the honest statement of the gap. Zero rounds → §6.2 |
| **THE \<LEAGUE\>** | `s5` 32. Section head: the league's name in `agate` + rule + `WEEK 5 OF 13` flush right |
| **The board slat** | `CSSlat` full-bleed (negative `gutter`), 52pt: `rail` 44 (rank in `figure` 27, two digits, leading zero; field **unpainted** — see Deviation 7) · `CSFace` 30 on its pigment, `s3` 12 either side · name `name` 17 caps with a tail ellipsis + `agateS` sub-line (`3 COUNTING · HELD`) · the movement mark 38 · the gap in `column` 14 `mut` right-flush 40 · the points in `figure` 27 right-flush 46 · `gutter` 20 |
| **The head-to-head slat** | 52pt, **no rail**: the empty 44 column, then an **overlapping pair** of 30pt faces (−12, each ringed in `bg0`), yours first · `YOU AND GALEN` in `name` 17 + `agateS` sub (`10 MATCHES · SINCE JUL 2026`) · trailing column 74: the record in `figure` 20 (`4–6`) over `agateS` `HE LEADS` |
| **The door** | `s3` 12. A tertiary link: `name` 15 `ink` + 2px `brand` rule, 44pt target — `The Fellas table` |
| **COURSES** | `s5` 32. Section head + `11 KEPT` flush right |
| **The course slats** | 52pt each: the **drawn card** thumbnail (44 × 26, eighteen bars from `api_course_holes`, in `rule`, the #1 stroke hole in `mut`) in a 56 column · the course in `social` 17 (**title case — a course is not a board row**) + `agateS` sub (`PHOENIX · HIS HOME COURSE` / `SCOTTSDALE · LAST PLAYED SEP 9`) · `agateS` 11 `mut` right-flush (`14 CARDS`). Three shown, then a tertiary link `All 11 courses` |
| **The overlap sentence** | `s4` 16–20. `body` 15 `mut`: *"You've both played Papago and Troon North."* — the reason two golfers start talking, fetched by `tour_card` since D150 and thrown away ever since |
| **The foot** | `s6` 52 of ground. No footer, no repeated folio |

**The agate count is exactly four** (§1.5): the credential (one block — see Deviation 8), `FORM`,
the league, `COURSES`. The status sentence spends none, because it is a sentence.
**One `display` per viewport**: the name. **One `brand` fill**: the primary.

---

## 2 · THE MARKER FLOOR — the crest

A golfer with no photograph gets a **designed card, not a degraded one**. This is canon (`IOS-003`
§1, `UI_SYSTEM` §6.1: no silhouette state, no fabricated face, ever) and it is the state most
golfers are actually in.

- **The contour** — the deterministic topographic plot of the golfer's **home course**, seeded from
  the course id (§10.1 state 3): 5–7 nested closed curves at 1.2pt in `rule`, cropped hard off its
  own centre, with one `brand` dot on the hardest hole by stroke index. It is the plate's field, at
  plate scale, which is the only scale §10.2 allows it. No home course → the curves are seeded from
  the **golfer's** id instead, and the `brand` dot is omitted (there is no hole to point at).
- **The crest** — the golfer's marker, drawn at **1.5pt on a ~190pt box** in `#33463B`
  (`pig`-adjacent, non-text, 2.4:1 — an emboss, not a picture), **bleeding off the plate's right
  edge**, so the object reads as printed stock rather than as an icon centred in a box. This kills
  GP-10 (the shipped 28% ember radial wash: "a muddy ochre-brown cloud, and ember is the *live*
  metal, which a crest is not") at the token level — there is no wash.
- **No medallion** (Deviation 3), **no slot** unless something was earned. On
  `player-card-marker` the card carries **zero gold**, which is what "earned only" is supposed to
  look like on a golfer who has not earned anything yet.
- The scrim shortens to 44% because there is no photograph to hold the name off.

---

## 3 · THE CLASH, AND THE RULE ABOUT LISTS

> **A person in a list is a slat. There is no fourth container, and the clash does not need one.**

That is the anti-card rule (brief §6, §32) applied to the surface most likely to break it. The
Golfers board, the season table, the event field, the wire and search results all render
`CSSlat`/`CSFace`; none of them gets a card — **and neither does the clash.**

**What the first draft proposed, and why it is withdrawn.** `CSCredential.compact` was a 170 × 190
rounded rectangle at radius 16 with a `0 6px 18px` shadow, holding a plate, a medallion, a name, an
identity line, a 2pt rule, a figure and an agate label — **two of them side by side with an image and
stats underneath**, which is the shape brief §6 and §32 ban in as many words, and which `LINT-08` and
`LINT-10` would both fail as written. `UI_SYSTEM` §3.1 closes the container list at three jobs (panel,
leaf, object) and adds *"an object may hold a plate and a rule and nothing else"*; a fourth class
called "compact" is the card grammar coming back through the one door left open. It also stated the
rivalry record **three times in one viewport** — `4 WINS`, `6 WINS`, `4–6 · HE LEADS`.

**`CSClash`, built from objects the system already owns.** Two **56pt `CSFace` rows facing across the
record**, on the page's own ground, no box and no shadow:

```
        ◍ 56                                            ◍ 56
     SAM RIDLEY                                      GALEN MARR
     10.6 · MESA                                    10.2 · MESA
              ───────────  4–6  ───────────
              GALEN LEADS · SINCE JUL 2026
```

- Two 56pt faces, one flush left and one flush right, each with `name` 17 caps beneath and an
  `agateS` identity clause in sentence case under that. Yours first.
- Between them, the record as a **rule-and-figure**: `4–6` in `figure` 40 over an 86pt 2pt `ink` rule
  with **`GALEN LEADS · SINCE JUL 2026`** in `agate` `mut` beneath. **Never `HE LEADS`** — the
  gendered form is the one sentence on the surface not addressed to every golfer in a mixed league,
  which is R-J's own stated reason for rewriting the fourth intent's gloss, and `TERMINOLOGY`'s ruled
  form names a subject (*"You lead 6–5"*). One form on both surfaces: `profile-top` reads
  `YOU LEAD` / `GALEN LEADS` / `ALL SQUARE`, and so does this.
- **No per-side `WINS` figures.** The `4–6` says it once. (`event-callout`'s head does exactly this
  and reads better than two boxes did.)
- The section head is `THE CLASH ——— THE FELLAS · WEEK 5`: **§8's head is an agate label, a rule and a
  COUNT flush right — never a proper name.** The first draft put a real production league name in the
  count slot (`WHO'S THE BITCH?`, recorded at `index.html:7445` as the exact string the shipped recap
  card **deliberately refuses to draw**, because "league names are in-joke space… on a PNG headed for
  strangers"). The in-joke stays where the product already keeps it: in the golfer's own typed
  content, never in the product's own chrome. It is also outside this session's fixture leagues.

That is `HeadToHeadPage`'s head, and it is the answer to the audit's "a rivalry surface that shows no
rivalry" — with three fewer objects than the version that failed the anti-card rule.

### 3.1 The Golfers board row

Full-bleed `CSSlat`, 52pt, one 1px `rule` on its top edge. `rail` 44 with the rank in `figure` 27
(**`panel` field when the row is yours, unpainted otherwise — never gold**, because D245 clause 5
says the board is a list and not a score, so no position on it was *earned*) · `CSFace` 30 on its
pigment · the name in `name` 17 caps with a tail ellipsis · the **band** as the `agateS` sub-line
(`A LITTLE LOOSE` · `BEAT YOUR NUMBER` · `NO ROUNDS IN THE WINDOW` — `FriendsBoard.Row.band`,
unchanged) · the **beats column** in `column` 14 right-flush (`3/4`, `—`), with `BEATS` named once in
the section head's count so the column needs no unit. Under the handicap lens the column becomes the
index (`10.6`, `FriendsBoard.Row.indexText`) and the sub-line becomes `LAST ROUND SEP 2`.

**The denominator is part of the fact** (L-01) — it is the column, not a clause in the sub-line, which
is what lets the sub-line stay one line at the default size. `FriendsBoard.note` renders verbatim
beneath the list in `body` 15 `mut`, because L-22 is a promise a golfer should be able to read.

**No movement, no badge, no arrow anywhere on this list** — D245 clause 5 and L-22, obeyed. The rank
rail is the *only* borrowed board device, and it carries a rank the server already computes.

---

## 4 · TYPE, TOKENS AND SPACING — the complete list this surface uses

**Type** `display` 34 · `figure` 27 / 20 · `name` 17 / 15 · `social` 17 · `body` 15 · `agate` 12 ·
`agateS` 11 · `column` 14. **No `lead`, no `story`** — the credential is the one surface with no
serif sentence, because the object is the sentence (§15.2's "one object, then a printed record").
Nothing on this surface renders below 11pt.

**Colour** `ceremony` · `ceremonyInk` (+ `a56`, `a16`) · `bg0` · `bg2` · `rule` · `ink` · `mut` ·
`gold` · `brand` · `pos` · `cool` · `panelInk` · `pig0–pig5`. **Not used:** `neg` (nothing here is
destructive), `dim` (non-text only), `panel` except as the rail's "yours" field, `bg1`, `leaf`, the
squad colours.

**Space** `s1` 4 (figure→rule) · `s2` 8 (rule→label, face gutters) · `s3` 12 (inside a slat, card→action) ·
`s4` 20 (the page gutter, the card's own padding, card→sentence) · `s5` 32 (between sections) ·
`s6` 52 (the page foot) · `rail` 44 · `hair` 1. **Radii** `r` 16 (the object), `rc` 10 (the buttons),
`p` 3 (the slot). No other number appears in a padding or radius position (LINT-05, LINT-06).

---

## 5 · MOTION

| Moment | What happens |
|---|---|
| **Arrival** | the card **wipes** from its leading edge over 220ms on `snap`; the plate first, the name at +60ms, the identity line at +90ms, the three figures at +120ms as one block. The primitive is §11.1's wipe, with the card's own left edge standing in for the rail |
| **The seal** | the medallion scales 0.92 → 1.0 over 180ms on `snap` as the last frame of the arrival, once per open. `.impact(.light)` **only on your own card**, and never on a re-render |
| **The position tallies** | the third figure's numeral **slots** (`RankFlipText`, kept) and its movement mark wipes in after the row settles — **only when the rank changed since this viewer last opened this card**. An unchanged rank does not animate; a number that moves every time you look at it stops meaning that something moved |
| **A new round lands** (your own card, returning from the composer) | the form row's rightmost column **tallies** from blank to the gross over 340ms on `snap` while its date fades in, and the whole row shifts left by one column on `roll` 260ms. The gold moves to the new best only if it *is* the new best |
| **Share** | the object lifts (`shadow-lift` → 1.6×) over 160ms on `roll` and the share sheet rolls up. The exported PNG is the same object at 2× (§7) |
| **Press** | the card as a whole is not a button and never scales. The slats press by their ground stepping to `bg1`; the primary darkens by `a16` |
| **Reduce motion** | every one of these resolves to `nil` — never "faster" (§11.2). The rest frame is the finished state |

**No confetti, no shimmer, no spinner** (§11.4). The only haptic on this surface is the seal's, and
the `.selection` on the lens segment of the board.

---

## 6 · EVERY STATE

### 6.1 Loading
**The destination's own geometry, redacted** (§13.2). The card renders at full size, on its real
ground, with its real plate rectangle, its real rule and its real folio rule; the photograph, the
name, the identity line, the three numerals and their labels are replaced by blocks at
`ceremonyInk` `a08`, radius `p` 3, at real-length placeholder widths. Below the card, two section
heads and three slat skeletons in `bg2`. **No spinner anywhere in content** (LINT-22). The card's shape
appearing instantly is the point: the object is what the golfer came for.

### 6.2 Empty — a golfer with no rounds
The card still renders (name, identity, folio, and a **one-figure strip**: `0` / `ROUNDS`). The form
block is replaced by `CSEmpty`:
1. a **drawn blank card** at 64pt, 1.7pt stroke in `rule`
2. eyebrow `THE FIRST CARD` in `agate`
3. the headline in `lead` 28 — **a fact about the world, never the golfer's omission**:
   *"Tash joined in August. The board starts with a first round."* (Not *"No rounds yet."* — §13.1's
   test: could the golfer have prevented this sentence by doing something? If yes, rewrite it.)
4. one true fact in `body` 15 `mut` when one exists: *"Papago is on the board because Galen keeps it."*
5. **the door, required, never nil** — `Play Tash` (primary) on someone else's card, **`Add my round`**
   (primary) on your own. *One verb opens the composer, product-wide (`TERMINOLOGY` A-5, §4 pattern
   26); Home and Event already use it and this file was the odd one out.*
The season block and the courses block **do not render at all** (L-44): a fact with no read renders
nothing, not a dash and not a zero.

### 6.3 Empty — no shared season, no rivalry, no courses
Each block is independently absent. The minimum honest card is: the object, the status sentence (if
there is a round), the action, and FORM. That is `player-card-marker`, and it is still a designed
screen.

### 6.4 Private — `visible: false`
Not an error and never dressed as one. The card renders as its **object outline**: the ceremony
ground, the folio rule, and the crest at `a16`, with the name absent. Under it, `lead` 28:
*"This card is private."* and `body` 15 `mut` rendering **`TourCard.privateLine` verbatim**
("This golfer keeps their card private, or you don't share a league yet."). The door is
`Add buddy` when the relation allows it; otherwise there is no door and the back chevron is the exit.

### 6.5 Error — the read failed
**Keep what is on screen** (§13.3). Cached card → it renders under an `agate` dateline
`AS OF FRI 6:12 PM · OFFLINE` in `mut` with **no action disabled**. Nothing cached → `lead` 28
*"Could not pull the card."*, `body` 15 rendering the existing sentence ("Could not pull the card —
check your signal and try again."), and **Try again** as the primary. A failed read is never
rendered as privacy — the existing L-32 comment in `PersonPage` is the precedent and it survives.

### 6.6 No photograph
§2 above. This is a first-class state, not a fallback, and the shipped rule survives verbatim:
**the crest, or the corner — never neither, never both.**

### 6.7 Long names
- **On the card**: `display` 34, `lineLimit(2)`, no tightening, no `minimumScaleFactor`. Two lines
  push the identity line down and **the plate's copy band grows**; the object grows with it. A single
  word wider than the measure drops to `display` 24 (one step, never a scale factor).
- **Everywhere else**: the one long-name policy, product-wide — `name`/`social` on one line with a
  **tail ellipsis** (§9.1), replacing the shipped wrap/wrap/clip split.
- **A long course name** (`Gold Canyon · Dinosaur Mountain`) sets in `social` 17 on one line and
  ellipsises; the city moves entirely into the sub-line.

### 6.8 AX3 (and the whole Dynamic Type ladder)
Every role is `relativeTo:` a text style. Growth caps exist only on `figure` and `display`.

| Element | Default | AX1 | AX3 |
|---|---|---|---|
| **The credential** | **362 × 312**, measure-relative (335 × 289 on an SE) | as default, plate ~180 | **the ratio is released and the object grows the page** — it never scrolls inside itself (§16.3). The plate holds ~180; the figure half grows |
| **The name** | `display` 34 | 44 | ~60, two lines, still on the scrim; if the copy band would exceed 45% of the plate the identity block **drops off the photograph** onto the card's own ground beneath it (the shipped `CredentialFace.riding` behaviour, kept — legibility beats composition) |
| **The three figures** | one row, one shared rule | one row | **three rows**, each its own cell: label leading in `agate`, figure trailing in `figure` 27, each on its own 2pt rule |
| **The form row** | 5 columns | 5 columns | **5 rows**: date leading, gross trailing, one rule between; the gold best keeps its rule |
| **The slat** | rail · face · name/sub · move · gap · pts | as default | the **rail keeps its 44 and grows its numeral**; move, gap and points move under the name as one `agate` line; `minHeight` becomes intrinsic. One VoiceOver element throughout |
| **The buttons** | side by side | side by side | **stacked full width** |
| **The clash pair** | two 170 cards | two cards | **stacked**, full measure, plate 3:2 |

The reflow is measured, not breakpointed: generalise `MeStripLayout`'s measured-advance model, not a
device table (`ViewThatFits` is 0 in the product today).

### 6.9 Accessibility
- **One VoiceOver element for the card**: *"Galen Marr's card. Founder. Handicap index 10.2.
  31 rounds. Second in The Fellas, up two."* The folio is `accessibilityHidden` (a serial is not
  spoken); the medallion carries the label *"His marker, the Lone Tree"*.
- **One element per slat**: *"Second. Galen Marr. Three counting rounds, held. Up two. Four back.
  Nineteen points."*
- **Every drawn mark carries a label** — the movement triangle, the blank form slot ("no round"), the
  crest.
- **Colour is never the only channel**: movement is a shape *and* a hue; the best gross is a *rule*
  and a hue; the "yours" rail is a *field* and not a tint.
- **44pt minimum** everywhere: the rail is 44 by construction, the slats are 52, the links carry a
  44pt target behind a 24pt label, the buttons are 50.
- Contrast, computed: `ceremonyInk` on `ceremony` **17.51** · `ceremonyInk a56` on `ceremony`
  **5.85** · `gold` on `ceremony` **9.65** · `panelInk` on `gold` **9.43** · `ink` on `bg0` **16.05**
  · `mut` on `bg0` **7.07** · `bg0` on `brand` **5.27** (dark) / **5.39** (light) · `ink` on a pigment
  **11.08–12.29**.

---

## 7 · THE THREE SIZES OF ONE OBJECT

| Size | Where | What changes |
|---|---|---|
| **Hero** | the You tab, the person page, the card screen | **362 × 312** at the measure |
| **Compact** | the clash only (§3) | 170 × 190; no display, no slot, no folio |
| **The share PNG** | `ShareLink`, the claim link's preview, the group chat | exported at **1080 × 1440 (true 3:4)** at 2×, because a shared image has no fold. Front is the person; **the back is the leaf** — the printed grid of the last five with dates, the courses kept and the record, in `column`, with the folio repeated. The two faces are one export |

---

## 8 · WHAT IT REPLACES — the SwiftUI files, named

*(grepped at HEAD 57b993f; line counts are the current files)*

| File | Disposition |
|---|---|
| `apps/ios/CupSeason/You/CredentialCard.swift` (292) | **replaced** by `CSCredential`. Its fixed-dark palette survives as the *rule* (the ceremony ground in every theme, D8 answered); its generic `<Anchor, Extra>` shape, its `@ScaledMetric` gear box, its `CSLookAccent` wash and its trophy-line column do not |
| `apps/ios/CupSeason/You/CredentialFace.swift` (192) | **folded into** `CSCredential.plate`. The `riding` behaviour at the accessibility sizes survives verbatim (§6.8); the 1:1-vs-16:10 `aspect` parameter is deleted — one object, one ratio |
| `apps/ios/CupSeason/You/YouHero.swift` (195) | **replaced**. The You hero becomes `CSCredential` at hero size. `CSHero`'s wash and the gold spine go with it (the spine is retired product-wide, `UI_SYSTEM` §0.3); the milestone chip row and its trailing fade are deleted — milestones move to the record, without emoji (YRS-03, CH-01) |
| `apps/ios/CupSeason/You/TourCardSheet.swift` (207) | **becomes `TourCardPage`, pushed, not presented** (§7.3: objects are pushed, actions are sheets). Its loading/failed/private branches and their copy survive as §6.1/6.4/6.5; `SliceSheet`'s SF-bold header, the three control types for three safety acts (GP-29) and the emoji-led mute label do not |
| `apps/ios/CupSeason/Golfers/PersonPage.swift` (393) | **merges with the above into one surface.** The person page and the card screen are the same object with the same facts and must stop being two chromes, two ratios and two meta strings (GP-16). Its `PersonModel.load` (card → bag → head-to-head, each riding in after the card) survives unchanged; its `YouDoorRow` settings-list rows, its `MathRow` career table and its dead `sharedSeason` do not |
| `apps/ios/CupSeason/You/FoundingTag.swift` (32) | **deleted** — `CSSlot` replaces it. It draws a `Capsule().stroke(…)`, which LINT-09 and LINT-10 both fail, and its label carries a `✦` dingbat, which LINT-12 fails |
| `apps/ios/CupSeason/Golfers/FriendsBoard.swift` (290) | `FriendsBoardSection.row(_:)` (≈:67–90) **replaced** by `CSSlat` + `CSFace`. Line ~70's bare `CSMarkerView(key:size:22)` is the construction site `UI_SYSTEM` §6.2 deletes by name ("a golfer with a photograph cannot show it on the people tab"). `CSMini` lens chips become `CSChip`. The section's logic, its two lenses and all of its copy are untouched |
| `apps/ios/CupSeason/Golfers/HeadToHeadPage.swift` (272) | **gains the clash** (§3) as its head; the rest of the page is another surface's spec |
| `apps/ios/CupSeason/You/CredentialDev.swift` (84) | **retargeted** at `CSCredential` — it is the harness that should render all seven states of §6 |
| `apps/ios/CupSeason/You/YouScreen.swift` (328) · `YouSections.swift` (274) · `YouRows.swift` (94) | **touched only where they draw the hero and the form row**; their other sections are out of scope |
| `apps/ios/Packages/CSDesign/Sources/CSDesign/Marker.swift` (`CSMarkerView`:15) | **survives**, and gains `CSFace` around it — the disc, the six pigments, the ring, the optical re-fit. `CSFace` becomes the only legal way to draw a person |
| `apps/ios/Packages/CSDesign/Sources/CSDesign/PhotoScrim.swift` | **survives as the product's only scrim**, with one change: `groundUnderCopy` is re-measured for `display` 34 (its test covers `mut` body copy) |
| `index.html` — `.cred` (the audit's 585–613), `refreshWhoChip()` (:18366), `openTourCard()` (:18683) | the web half. Same object, desk shape (§10) |

**New component names** (`UI_SYSTEM` §18): `CSCredential`, `CSSlot`, `CSMedallion`, `CSFace`,
`CSSlat`, `CSRankRail`, `CSFigure`, `CSFigureRun`, `CSMovement`, `CSObject`, `CSSectionHead`,
`CSEmpty`, `CSDoor`. **Retired here**: `CredentialCard`, `CredentialFace`, `YouHero`, `FoundingTag`,
`CSHero`, `CSStat`, `CSMini`, `MathRow` on this surface.

---

## 9 · WHAT IT CONSUMES, UNCHANGED

Every fact below is already produced. **Nothing on this surface invents a fact.**

**Payload** — `Rpc.tour_card(p_profile:)` via `TourCardRepository.load` (card + `my_friends` +
`my_mutes` + the signed avatar, in parallel; visibility enforced server-side):
`profile.{display_name, handle, marker, city, home_course, index_current, member_since, is_me}` ·
`career.{rounds, best, avg_pvi, best_pvi, avg_vs_index}` and its `playingLens` switch (D209 —
the phone never prints the You tab's words over a figure that is not the You tab's number) ·
`career.best_round.{gross, course_label, played_on}` (R21) · `recent[]` ·
`courses[].{name, rounds, last_played}` (D150 — returned since D150 and discarded by the phone ever
since) · `shared_courses[]` (D150) · `vs_you.{wins, losses, ties}` · `case[]` · `trophies[]` ·
`visible`.
**Board** — `Rpc.friends_board` via `FriendsBoard`: `rankByForm` / `rankByIndex` (**the server ranks
both, so two clients cannot order one board differently**), `rounds`, `beats`, `avgVsNumber`,
`indexCurrent`, `lastRoundOn`, `isMe`.
**Rivalry** — `PeopleService.headToHead` / `headToHeadFallback` (R4), `TourCard.VsYou`.

**Copy producers, verbatim**: `TourCard.established(_:)` ("est. Jul 2026" — the one form, Y-26) ·
`CSCopy.index(_:)` · `TourCard.privateLine` · `TourCard.noRoundsYet(_:)` · `TourCard.BestRound.line` ·
`EmptyRoot.failedRead()` · `FriendsBoard.Row.band` / `.formLine` / `.indexText` / `.name` ·
`FriendsBoard.note` / `.head` / `Lens.caption(days:)` / `Lens.label` · `RivalryCopy.record` /
`.leadLabel` / `.monthDaySpoken` · `HeadToHeadCopy.personNarrative` · `RoundCopy.course` ·
`CSBands` (the band table, with only the possessive turned) · `CSMarkers.marker(_:)` ·
`FoundingBadge` (its *cases*; see Deviation 10 for its label).

**Two new copy producers — consolidations, not new facts:**
1. `CredentialCopy.identity(profile:)` → `"@galenm · Mesa, AZ · est. Jul 2026"`. Today the same line
   is built twice, differently, and a golfer's identity line changes with the door they came through
   (GP-16). One string, one place, uppercased by the *role*, never by `.uppercased()` (LINT-14).
2. `FriendsBoard.Row.beatsColumn` → `"3/4"` / `"—"` from the existing `beats` and `rounds`.

---

## 10 · THE WEB DESK, IN ONE PARAGRAPH

Owner ruling R-C: the desk is its own desktop-first shape, and the card is the one object that does
not change shape — it renders at its native 362 × 312 in the **right column** (340pt, so it sits at
the column's own width with the gutter absorbing the 22), pinned under the sidebar's rule, while the
**left column carries the record at length**: the form row as five columns, the season slat at 56pt
with the desk's two extra columns (`RDS · BEST · GAP · PTS`) and the five-dot form column inside the
row, the head-to-head, and the full course table rather than three rows and a door. Density follows
§14.2 — `gutterDesk` 40, slat 56, `display` 42 on the card's name — and nothing is redesigned; only
the column count changes. Hover (guarded by `@media (hover: hover)`) steps a slat's ground to `bg1`
and paints its rail slot `bg2`, and thickens a link's rule from 2px to 3px; **every hover state has a
focus twin** — a 2px `brand` outline on the whole slat, always visible, never suppressed — and the
card itself takes the same outline when it is the keyboard's target, because the card is a door
(Enter opens the share sheet). `↑`/`↓` move between slats, `→` opens the receipt behind a form
figure, `Esc` closes. The card's **print stylesheet** is the share PNG's geometry at 3:4 on one page,
front and leaf back, which is the archive test made functional.

---

## 11 · DEVIATIONS FROM `UI_SYSTEM` — for the refuters

Each is a place where a rule in the system did not survive contact with this surface. I have obeyed
the system everywhere else; these twelve are recorded rather than silently resolved.

1. **RESOLVED, and the other way.** This file argued 4:5 (362 × 440) against §6.5's "3:4-ish";
   `profile.md` argued 362 × 312. **§6.5 now rules 362 × 312, measure-relative**, and the reason is
   this deviation's own reason taken one step further: if 483pt puts the ranked action under the tab
   band, 440 leaves it 41pt clear on a 402 × 874 frame and *nothing* clear on an SE. The portrait
   crop survives where it costs nothing — **the share PNG exports at true 3:4**, because an image has
   no fold.
2. **RESOLVED.** The budget counts **gold fields**, and `LINT-17`'s whitelist carries two named pairs:
   the season's leader-plus-pot (already sanctioned) and **the credential's slot-plus-seal**, because
   the medallion is a 1px ring and a 24pt glyph, not a field. The form row's gold is §9.7 verbatim and
   is a *rule*. And the count drops by one in the common case anyway: **deviation 3 is now the system's
   rule**, so a crest card has no medallion at all.
3. **ADOPTED into §6.5.** The medallion is present **only when the plate is a photograph**. The
   shipped rule is "the crest, or the corner — never neither, never both" (`CredentialFace`'s own
   header) and the audit's CH-03 is "the marker appears twice on one card". This also deletes
   `profile.md`'s own known imperfection, where the gold ring landed on the Lone Tree's canopy.
4. **ADOPTED, and the value is now a token.** §6.5's "in `agateS` at `dim`" is struck. The folio takes
   **`folioRule` `#8B8F8B` at 5.92:1** — the opaque value `ceremonyInk` at `a56` composites to, named
   so Phase 3 does not invent a hex and so Reduce Transparency has something to resolve to. (`dim` on
   `ceremony` measures 3.44:1, not 2.99; the conclusion held either way, and §16.1 now deletes `dim`
   from every text position product-wide.)
5. **No `CSPageHeader` on this surface**, against §12.2's "every pushed screen sets
   `navigationTitle("")` and `CSPageHeader` names the screen". The card's `display` 34 name *is* the
   page's naming object; a page header would print the name twice (the audit's "the name is said
   three times in the first 750pt") and would put two `display` roles in one viewport, failing LINT-16.
   The first half of §12.2 is obeyed: empty `navigationTitle`, system back, one trailing action.
6. **ADOPTED into §7.1, and generalised into three tiers.** A `brand` rule beside an ember primary
   puts two ember actions on one screen, which §2.4's mechanism forbids. §7.1 now rules: **2px
   `brand`** only when the link *is* the screen's one live action · **2px `mut`** for every other link
   in content · **1px `mut`** in a toolbar. The underline is `mut` (7.07 / 5.85) and never `rule`
   (2.66 / 2.30) in the quiet cases, because when the underline *is* the affordance, taking it below
   3:1 stops it being a control. `profile-top`'s `SETTINGS` and `lb-live`'s `CLOSE` are repainted.
7. **The rank is stated twice in one viewport** — as the card's third figure (`2ND`, the identity
   claim) and as the slat's rail (`02`, the board's record). §9.1's own note licenses the gap being
   *said* above a table and *recorded* in it; this is the same move, and the two are in different
   registers. It is still a repetition and the refuters should rule. **Related:** the rail's three
   field states (gold / `panel` / unpainted) cannot mark "this row belongs to the golfer whose page
   this is". Ruled here: **the rail stays unpainted and the section head names the league** — a
   fourth state would break the two-state law that §0.3 established.
8. **RESOLVED in the system, without the carve-out.** §1.5 now budgets **ten tracked-caps agate lines**
   and counts every one — including the credential's identity line, its three figure labels and its
   folio. No object gets an exemption; the budget simply counts what a golfer sees. What absorbs the
   difference is §1.3's **sentence-case `agate`**: the status sentence, the course sub-lines and the
   overlap sentence are phrases, not labels, and they set in sentence case and do not count.
9. **ADOPTED, and widened.** §2.4's gold list is now closed to things that were **won**, so the
   hardest hole's bar is `ink`/`mut` at *every* scale — nobody wins a stroke index. And §10.2 now makes
   the thumbnail degrade rather than shrink: **at ≤64pt the drawn card renders the front nine only,
   nine bars at three heights by par**, because eighteen 3pt bars in a 44 × 26 box are three
   near-identical grey combs — the same failure that bans the contour at that size.
10. **`FoundingBadge.label` must lose its `✦`.** The producer ships `"✦ Founder"`; LINT-12 fails an
    emoji/dingbat codepoint outside the six reactions, and §5.2 deletes "every Unicode dingbat".
    The slot's label becomes `FOUNDER` / `FOUNDING MEMBER`, uppercased by the role.
11. **The board row's name is `name` (caps)** because §1.3 puts caps on "a ranked row"; D245 clause 5
    insists the friends board is a list and not a score. If the refuters read the board as social
    rather than ranked, the row takes `social` (title case) and nothing else changes.
12. **ADOPTED into §10.3, and widened from one role to four.** `PhotoScrimTests` holds `mut` **body**
    copy; the system puts `display` 34 (this card, and the course hero), `social` 17 (Home's wire
    band), `agateS` (the credit line) and the back chevron's stroke on the same scrim. **All four are
    a gate, not a follow-up**, and all four are composited against a **high-frequency** subject — a
    real photograph, not a two-stop wash — because the mockups' washes exercise none of them. §10.3
    also names the three geometries (`.title`, `.band`, `.top`); the first draft's "one scrim" was
    three different gradients in the mockups illustrating the claim.

---

## 12 · KNOWN IMPERFECTIONS OF THE RENDERS — stated rather than iterated a fourth time

(a) **The photographs are drawn stand-ins, and they are now state 2 or state 3 of the ladder, not a
wash** (§10.4). The product has no photograph this session may use and fabricating a face is
forbidden, so the plate carries the **contour** — a thing the product can generate today — under the
scrim. The earlier stand-in was a four-stop sky with an ochre sun disc and a flag filled in `brand`:
that is the one image state §10.1 bans (a gradient wash), the cartoon golf graphic §4 bans, and the
live metal spent on decoration. In the build the plate is the golfer's own photograph,
subject-anchored; the crop, the scrim, the medallion's clearance and the copy band are what the
mockup specifies.
(b) On `player-card-photo` and `player-card-marker` the form row's **date line sits inside the 28pt
scroll fade**. That is the real fold on a 402 × 874 phone and it is drawn deliberately; the row is
shown at full height on `player-card-record`.
(c) The rendered card is **432pt tall with a 12pt gap above the folio**; the spec's 440 with `s4` 20
is the buildable number, and the 8pt is the mockup's, not the design's.
(d) The **Lone Tree marker at 24pt inside the 44pt medallion** reads a little like a tee. It is the
shipped glyph, unretouched; §6.2's optical re-fit of the fourteen markers to a common cap-height box
is what fixes it, and that work is not this surface's to do.
(e) `player-card-in-list` shows **four board rows, not five**, so the clash clears the fade. The
fifth state (`POSTED ANYWAY`) is drawn on row 04.


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it.** Instantly 3/3 · looks like Cup Season 3/3 · premium 3/3 · template 0/3
· proud to post 3/3 · belongs 3/3. Median **8.2** — the highest of the seven, and the only surface
that clears the brief's bar on the reviewers' own numbers.

**1 · The credential's default ground is a photograph (§10.1).** `player-card-photo` contained no
photograph — it drew the contour, identically to the fallback variant. All three filed it; blind-1's
reason is the one the system adopted: *"the shipped tour card leads with a real picture of a man on a
green and it is the warmest thing in the shipped app … a face is the most premium asset a social
sports product has."* The plate is now a round photo at the card's true 362 × 300, with a top scrim
under the status bar, the credit `GALEN'S ROUND · AUG 24` and the name reversed out at the foot. The
marker plate is proved on `-marker`, where it belongs.

**2 · The marker has one slot and one treatment (§6.2a).** blind-2: *"On Galen it is a small
gold-ringed medallion in the corner; on Tash it is a giant flat glyph filling a third of the card."*
Every card now carries **the 44pt gold-ringed medallion in the same slot**, and the marker card
*additionally* carries the same glyph as a crest at 9.2× — lifted from a low-contrast `#41604F` to
`#7E9184`, which was blind-1's finding ("a low-contrast smudge at that scale"). One slot, one size,
one treatment, plus a crest that is the same mark magnified.

**3 · One primary (§16A.5).** `ADD BUDDY` + `PLAY TASH` were two orange-weight decisions; the second
is now a tier-3 text link on a rule, centred, at the same place on every card. The `…` overflow is
`SHARE`, spelled, in **both** themes — blind-2: *"a '…' on the most shareable screen in the app hides
the only verb that matters."*

**4 · One denominator, one standing.** `2 ROUNDS OF 3` in the rail and `2 OF 5 ROUNDS` on the form
strip were two establishing rules on one screen. The rail is `2 · ROUNDS`, the form slot is
`TWO OF FIVE`, and the establishment moved into the sentence where it reads as English: *"Posted 79 at
Papago on Aug 30. One more round sets her number."* Galen's position now reads **1ST**, which is what
the season table and the leaderboard say.

**5 · The rail rule fits its own cells.** Tash's two-cell rail drew a full-width rule with an empty
right third that "reads as a missing value" (blind-3). The rule is 66% and the grid is two columns.

**6 · `player-card-in-list`.** `BEATS` is a column head over the `3/4` and `1/2` figures; the clash
block rose **above** the grey explainer, because it is the emotional payload and it was buried; and
the record reads `6–5 · YOU LEAD · eleven meetings since June 2026`, which is what the profile and the
h2h page say. Three surfaces, one record.
