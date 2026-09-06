# SURFACE — THE PROFILE (PersonPage · You · the Record · head-to-head)

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 (design; nothing is built)
**Standard** `BRIEF.md` §10, §1, §5, §6, §8, §9, §16, §17, §31, §32, §33, §35
**System** `UI_SYSTEM.md` — every rule here is that document's; §-numbers below are its
**Evidence** `UI_AUDIT.md` §2.11 (person page, **5.3**), §2.12 (head-to-head, **4.6**), §2.14 (You, **5.8**),
§2.15 (the Record, **5.0**); findings GP-09…GP-30, YRS-01…YRS-31, DD-17, ICO-16, ICO-19, ICO-23
**Mockups** `mockups/profile.html` → `mockups/renders/profile/` — `profile-top`, `profile-scrolled`,
`profile-history`, `profile-h2h`, `profile-light`

---

> **Two `L-nn` namespaces are live in this repo and this spec cites both.** `LINT-nn` is
> `UI_SYSTEM.md` §17 (the visual preflight, 29 checks). Bare `L-nn` is
> `docs/ux-overhaul-2026-09-04/UX_PRINCIPLES.md` (45 principles). They collide across 26 ids, so
> nothing here abbreviates a `LINT-` id.


## 0 · THE CHARACTER, AND THE ONE SENTENCE

§15.2: **PROFILE is identity — one object, then a printed record.** The surface is built around an
*object* rather than a layout: the credential, on the ceremony ground, with a real lift shadow. It is
the only object on the screen with depth. Everything under it is deliberately flat — bands, rules, the
rank rail, a leaf — so the card is unmistakably the thing the page is about.

> **The credential is the page's header.** There is no page title, no serif "You", no nav-bar name.
> The object says whose page this is, once. *(Answers GP-17: the name is currently said three times in
> the first 750pt, and GP-09: the identity page's name is set at SF ~20pt while the handicap is 40.)*

The brief's four tiers, and where each lives:

| §10 tier | Where |
|---|---|
| **HERO** — photo, name, handicap, location | the credential (§2) |
| **COMPETITION** — wins/losses, current season, rivalries | **the season** (§3) and **rivals** (§4) |
| **GOLF** — recent rounds, top courses, courses played | **form** (§5) and **courses kept** (§6) |
| **HISTORY** — past seasons, career record | **the record** leaf (§7) → **the Record page** (§9) |

**Aspirational, and testable:** the screenshot a golfer would post is `profile-top` — one object with a
crest, a serial and three tabular figures, and under it a rank rail, a rival's name and a score. No
emoji, no chips, no legend, no settings list.

---

## 1 · THE PAGE FRAME

| | |
|---|---|
| Ground | `bg0`, painted once, on the root. No `CSLookSky` wash (§2.2 · audit F-04) |
| Gutter | `gutter` **20** both sides; the measure is **362** |
| Scroll | reserves the tab band's measured height (`CSTabBarProbe`), ends in the **28pt fade** (§12.1) |
| Chrome | **34pt row**, `gutter` inset. `topBarLeading` = the system back (pushed pages only). `topBarTrailing` = **one** tertiary link: `Settings` on You, the P-17 safety menu (`ellipsis`, 17pt, `mut`) on somebody else's page (§12.2) |
| `navigationTitle` | **`""`** on every one of these screens. `CSPageHeader` is used only on the Record and the head-to-head. *(Closes the doubled title on three pushed pages — audit §3, YRS-12.)* |
| Budgets, per viewport | one `display` · one `gold` object · **≤10 tracked-caps agate lines** (§1.5, counted the way a golfer sees them) · **≤2 ember marks, counting every fill, rule, glyph, dot and word except the tab band** (§2.4, `LINT-18`) |

---

## 2 · THE CREDENTIAL (`CSCredential`, the object) — HERO

**The anatomy is `UI_SYSTEM` §6.5's table, and this spec does not restate it.** Both this file and
`player-card.md` rebuild `CredentialCard.swift`, `CredentialFace.swift`, `YouHero.swift`,
`PersonPage.swift` and `FoundingTag.swift`, and both cite GP-16 ("one object, two chromes, two aspect
ratios") as the defect they close — so two disagreeing anatomy tables would reopen GP-16 inside the
design that closes it. **§6.5 is the single table.** What it rules, and what changed here as a result:

- **Geometry `362 × 312`**, `r` 16, `shadow-lift`, `overflow: clip` — this spec's number, adopted
  product-wide. **Measure-relative**: 335 × 289 on an SE (§16.3). The 3:4 portrait survives only as the
  **share PNG**, which has no fold under it.
- **The medallion is present only when the plate is a photograph** — player-card's D-3, adopted: on a
  crest card *the crest or the corner, never both*. This deletes Known Imperfection 1 below (the Lone
  Tree's canopy behind the gold ring) rather than mitigating it.
- **The identity line is one string**, `CredentialCopy.identity`: `@handle · city · home course`. No
  `EST. JUL 2026` (YRS-21) — the founding fact is already the gold slot and the folio's serial.
- **Every colour on the object comes from the ceremony ramp** (§2.1, §2.8), pinned to its dark value in
  both themes: `ceremonyInk` · `ceremonyMut` · `ceremonyGold` · `ceremonyBrand` · `crest` `#33463B` ·
  `folioRule` `#8B8F8B`. The three off-palette hexes this spec had written into Swift — `#2A3A32`,
  `#2C3B33`, `#5E6A62` — are gone: two were never in `index.html` (preflight 15 fails a Swift hex that
  is not), and `#5E6A62` is `dim`, which may never carry a word (§16.1).
- **The three figures share a 2pt `ceremonyInk` rule, never `ink`** — `ink`'s light value on `ceremony`
  is **1.11:1**, so in the light theme the one structural rule binding the card's three figures would
  disappear entirely. `player-card.md` had this right; this file did not.

Positions, which are this surface's own: slot left 20 / top 20 · name left 20 / top 114, right margin
**20** when there is no medallion and **82** when there is · identity line left 20 / top 157 · the three
figures left/right 20 / top 196 · the folio bottom 15.

**What is deleted from the shipped hero and why:** the ember radial wash (GP-10 — ember is *live*, a
crest is not) · the inner seam (GP-30) · the gold **spine** (YRS-06 — the largest gold object in the
product, keyed to any achievement) · the second marker rendering under the photo (YRS-05) · the two
emoji achievement capsules (YRS-03, §5.3) · the LAST FIVE dots and their eleven-word legend inside the
object (YRS-04, GP-13 — form is §5, once) · the GHIN line and `EST. JUL 2026` (YRS-21, GP-17 — the
account, not the golf) · all four borders (GP-30 — the system has no border token, §3.4).

**The photograph.** When `profileExtras.avatarURL` resolves, the photo *is* the plate: full-bleed
across the top 180, subject-anchored crop, `CSPhotoScrim`'s settle split, the name and identity line
set on the measured scrim, the medallion notched at the plate's lower-right. **No fabricated face ever
stands in** — with no photo the crest is the design, not a fallback (this is why the mockups show the
crest state: it is the state most golfers are in, and it must be beautiful on its own).

**Long names.** `display` 34 → shrink one step to 24 → tail ellipsis. One policy, product-wide (§9.1).
The name column is `min-width: 0`.

---

## 3 · THE SEASON — COMPETITION, part one

```
THE SEASON ─────────────────────────────── WEEK 9 OF 14
│ 02 │ THE FELLAS                     ▲2      19
│bone│ SEASON II · 8 GOLFERS
4 BACK OF GALEN · 3 CLEAR OF TASH
```

| Element | Role · token | Spacing |
|---|---|---|
| section head — `CSSectionHead` | `agate` 12 `mut` + 1px `rule` + `agateS` 11 count | `s5` **32** above |
| **the rail** — `CSRankRail`, 44pt, full-bleed left, two digits with a leading zero | `figM` **27**, field `panel` (yours) / `gold` (first) / unpainted | slat 56pt, top `rule` |
| the league | `name` 17 caps, tail ellipsis; sub `agateS` 11 `mut` | body starts at `rail` + `s3` = **56** |
| movement | `CSMovement` — drawn triangle in `pos` + tabular numeral in `ink`, or the 9×2 `rule` bar for held. **No field, no chip** (§9.3) | `s4` from points |
| points | `figM` **27**, tabular, right-flush | |
| **the standing line** | `agate` 12 `mut`, one line, names the rival (§9.6) | `s3` **12** below the slat |

This is the single largest hierarchy repair on the surface: **the golfer's position in the season is
not on You at all today** (audit §2.14), and where it does exist it is a settings row. The rail makes
it the same object it is on the season board, so a position reads identically wherever a golfer meets
it — and the whole slat is one door to the season table.

---

## 4 · RIVALS — COMPETITION, part two

Three slats, 50pt, top `rule` each. `CSFace` 38 (pigment keyed to the golfer's id, 1px `rule` inset
ring, marker at 55% in `mut`) · `name` 17 caps with a tail ellipsis · `agateS` sub (`11 MEETINGS ·
SINCE JUNE`) · then the record and the verdict, right-flush:

| Fact | Role |
|---|---|
| the record `6–5` | **`figS` 20**, tabular, `ink` — **always `ink`, winning or losing** |
| the verdict | `agateS` 11 `mut`: `YOU LEAD` · `ALL SQUARE` · `THEY LEAD` |

> **A losing record is set in the same ink as a winning one.** The shipped app renders a trailing
> record in the **dim tier** and a leading one in mint (DD-17) — it greys out your losses. The verdict
> is a **word**, which is a second channel (§16.4) and survives colour blindness.

Each slat pushes the head-to-head (§10). On somebody else's page this whole section is replaced by a
single **YOU AND \<NAME\>** slat carrying an **overlapping pair** of 38pt discs (−12pt, each ringed in
`bg0`, §6.3), the record and the verdict — see `profile-light`.

---

## 5 · FORM — GOLF, part one

§9.7, verbatim: **five grosses with their dates on one rule, the best in `gold`.** Figures `figS`
**20** above a 2pt `ink` rule; dates `agateS` 11 `mut` beneath; the best gross **and** its date in
`gold`. Section head `FORM` / `LAST FIVE`.

It says "recent form" with no legend, which is what the five dots and their sentence
("*a lit dot beat your playing HCP*") were for. It is also the only place the last five appear —
against the shipped **two** renderings in two label faces on one screen (GP-13, YRS-04).

*Colour is not the only channel: the best is marked by **position** (it is the newest, right-most) and
by the gold on both the figure and its date.*

---

## 6 · COURSES KEPT — GOLF, part two

Section head with the count spelled (`ELEVEN`), then 44pt slats:

`Papago` **`social` 17 (title case — a course is read aloud)** · `Phoenix` `agateS` `mut` ·
rounds `column` 14 `mut` right-flush in a 34pt column · best `figS` 20 right-flush in a 44pt column.

Three rows, then a tertiary link `All eleven`. **No thumbnail** — §10.2: a course with neither a photo
nor a cached drawn card shows no thumbnail at all, and the name sets flush to the margin. On a golfer's
own page this is "courses played"; on somebody else's it becomes **COURSES YOU BOTH KEEP**
(`sharedCourses`), which is the social fact and the better one.

---

## 7 · THE RECORD — HISTORY, the door

Section head `THE RECORD` / `SINCE 2026`, then **the leaf** (`CSLeaf`, `leaf` fill, `p` 3,
`leaf-shade`, +1px `rule` frame in light) carrying a **printed table** — §3.3's licence, because it is a
grid:

| Column | Role | Width |
|---|---|---|
| year | `colS` 12 at `leafMut` | 42 |
| competition | `social` 16 at `leafInk`, qualifier in `agateS` at `leafMut` | flex |
| finish | `figS` 20 (`2ND`, ordinal rider at 40%) or `nameS` (`WON`) | 52, right |
| money | `column` 14, `leafInk`, `−$20` with a **minus in ink** | 56, right |

**The earned mark, tightened.** §9.8 marks a won *or podium* finish with a 2pt gold rule under the
finish cell. Here: **a win takes the gold rule; a podium takes a 2pt `ink` rule.** Gold is "only on
something that was won" (§2.4), 2nd of 8 is not silverware, and the tightening keeps the viewport's
gold budget honest without losing the podium's mark.

**Gold on paper** (`CSLeaf.earnedRule`, §3.3). On a leaf the gold rule is drawn in the **light theme's** gold `#7A5A12` in *both*
themes, because the leaf does not invert — dark gold `#D8B25A` on `leaf #EFEADD` is a pale smear at 2pt.
This is a system clarification Phase 3 should carry into `CSLeaf`. Gold **ink** on a leaf stays
forbidden (1.68:1).

The **ledger line** — `MoneyCopy.ledger`, `body` 15 `mut` — renders beneath the leaf, verbatim, on any
viewport that shows a money figure (§9.5).

---

## 8 · THE PERSON PAGE — what differs when it is not you

Same surface, four differences. All of them answer audit findings by name:

1. **Chrome**: system back + the P-17 safety menu (`ellipsis`) — nothing else.
2. **One primary, directly under the credential**: `Play Galen`, `brand` fill, 50pt, `rc` 10, `name`
   17 label at `bg0` (5.27 / 5.39:1). It is the live thing you can do now, so it is the screen's one
   ember object. **The three lengths become a step inside that flow** — a `.medium` sheet asking
   *"How long do you want it to run?"* with the three answers as full-width secondary blocks — not
   three door rows with `SAT` / `WK` / `SSN` glyph cells (GP-18, ICO-23, and the "SSN reads as a
   government number" note). The row whose object does not exist yet keeps `TourCard.weekNotYet` as
   the answer's own caption inside the sheet, so nothing is hidden and nothing is guessed.
   *(This also fixes audit F-8: the page's ranked action can never need a scroll.)*
3. **Rivals → one YOU AND \<NAME\> slat** (§4).
4. **Courses kept → courses you both keep** (§6).

`profile-light` renders the whole not-me variant, in the light theme, with no slot on the credential
(nothing earned) and the **gold rail** on his first place — which is the only surface in the set that
shows the rail's `earned` field.

---

## 9 · THE RECORD PAGE — `profile-history`, character: **archive / achievement** (§15.6)

The densest surface in the product and the quietest: **no ember at all**, gold only under a season that
was won, `column` for every figure, a leaf carrying the table.

| Band | Anatomy |
|---|---|
| **the header** | `CSPageHeader`: `display` **34** `THE RECORD` with **`SINCE MARCH 2026`** in `agateS` flush right. **Not today's date** — a today-dateline on a page about the past is YRS-12 |
| **the one serif sentence** | `lead` **28** New York Bold, sentence case: *"Eighteen rounds since March. The best of them an 80, at Papago."* One appearance per viewport (§1.4). This is the audit's own "what works" — the memory-voice subline — promoted from grey body copy to the page's voice (YRS-11) |
| **the career** | four figures on one shared 2pt `ink` rule: `18 ROUNDS · 3 SEASONS · 74 BEST · $80 MONEY`, labels in `agateS` `mut`. Money in **ink** (§9.5) |
| **SEASONS** | the **leaf**, full table (§7's grammar), every season, newest first; the ledger line beneath |
| **TROPHIES** | 44pt slats, top `rule`, **a drawn glyph at 28pt in `ink`** + `name` 17 + `agateS` sub. **Two achievements may never share a glyph** (§5.2 — the shipped case has two dartboards with the same subtitle), **and none of them is the pennant** (§5.1, `LINT-28`: the Tracer's flag is `CSTabBand` and the app icon, nothing else — the first draft put it on `LOW ROUND OF THE SEASON` with the Compete tab's identical flag 400pt below it in the same viewport, which is audit ICO-12 reopened on the product's core symbol). The glyphs: **a rule under a numeral** for a low round (it ladders to the rule-and-figure signature), a **stepped bar** for most improved (checked against the drawn card, which it is one stroke from), a **filled disc on a rail** for a season won. No tiles, no card-in-a-card (YRS-07), no emoji (YRS-03), no trophy for having posted a round (YRS-09) |
| **HEAD TO HEAD** | the rivals list, as §4, below the trophies — reachable, not clipped (audit: it is cut by the tab bar today) |

**Most Improved takes a drawn mark of ascending rules, never an arrow** — ▼/▲ has exactly one meaning
in this product and it is "you fell" (§9.3, DD-02).

---

## 10 · HEAD-TO-HEAD — `profile-h2h`, the rivalry as a graphic

The audit's biggest personality opportunity in the social slice: *"a head-to-head between two golfers
with neither golfer on the page"* (GP-20, P0). Anatomy:

| Band | Anatomy |
|---|---|
| **the eyebrow** | the christened rivalry name in **`gold`** `agate` 12 — earned, and the surface's one gold object. Absent when unnamed |
| **the title** | `display` 34 `YOU AND GALEN` (`HeadToHeadCopy.title` + the opponent's first name) |
| **the graphic** | two **`CSFace` 64** discs, one at each end of the measure, names in `nameS` 15 beneath (`YOU` / their first name); between them the record as **`figXL` 56 tabular `6–5`** on a **2pt `ink` rule** with `ELEVEN MEETINGS` in `agateS` beneath — a rule-and-figure, at the largest tier the product has |
| **the sentence** | `HeadToHeadCopy.standfirst` in **`story` 20** New York, sentence case. The serif carries what the numeral cannot: *"He has won the last two."* |
| **THE MEETING TAPE** (`CSTape` — **chart 5**, §9.10) | the surface's signature. One **2pt `ink` rule** across the measure; **every meeting is a 17 × 16 tick — above the rule if you won it, below if they did**, in chronological order, **yours filled `ink` and theirs outlined 1.7pt `mut`**, a halved meeting a 17 × 2 `mut` bar centred on the rule. **No `YOURS` / `THEIRS` legend** — the section head carries it (`THE MEETINGS ——— YOURS ABOVE`) and §9.10 bans a legend on a chart in the same breath as it bans an axis. The first and last dates in `agateS` beneath. Countable, colour-independent (position and fill are the channels), and it is a *tally*, not a chart |
| **WHERE IT WAS DECIDED** | **behind a door.** `Where it was decided` as a tertiary link, pushing the six facets as a printed grid on a leaf: facet in `social` 16, `MET` in `column` 14 `leafMut`, the record in `figS` 20. **A facet with no data does not render** (P-6, L-44 — never "0–0"). *The viewport cannot hold the hero (`6–5`), the tape (eleven ticks) and a leaf whose three rows sum to 6–5 — that is the same fact three ways in one screen, brief §28 Q7. The hero and the tape stay, because one is the claim and the other is the shape of it; the leaf is the evidence and evidence belongs one tap away.* |
| **the door** | one primary, `Play <name>` |

**Empty** (`h2h.record.total == 0`) — `CSEmpty`, §13.1's anatomy, and it is *this* page's biggest win
over the shipped void: the **two faces are still drawn**, side by side over the rule with **no numerals
at all** (never "0–0"); the eyebrow reads `NOTHING COUNTED YET`; the headline is
`HeadToHeadCopy.emptyHead` in `lead` 28; the fact is `HeadToHeadCopy.emptySub` in `body` 15 `mut`; and
the door is the **real primary** `Play Galen`, never a text link that toasts *"Add it from the ⊕"*
(GP-21). The dateline is removed from this page entirely (a today-dateline on a rivalry).

---

## 11 · EVERY STATE

| State | What renders |
|---|---|
| **Loading** | **the destination's own geometry, redacted** (§13.2): the credential's object at full size with `bg2` blocks at `p` 3 in place of the name, the identity line and the three figures — its rule, its folio rule and its slot geometry all present; the season slat with its **rail drawn and empty**; three rival slats redacted at real row heights. `.redacted(reason: .placeholder)`. **Never a spinner** (LINT-22). This also repairs GP-08 — today's skeleton does not match the real card |
| **Empty · no rounds** | the credential still renders (a golfer is a golfer with no rounds): the **value slot never renders a dash or a guess** (§9.9) — the index cell's *label* reads `BUILDING` or `STARTER`, the rounds cell reads `0`. Under it, one `CSEmpty`: a drawn empty rail at 64pt in `rule`, `THE FIRST CARD` in agate, `lead` *"Nobody has counted a round for them yet."* (a fact about the world, never the golfer's omission — §13.1), one true fact if one exists, and the door. **`TourCard.noRoundsYet` is the producer** |
| **Empty · no season** | the season block does not render at all; the rivals block leads. A block whose fact did not arrive **is not drawn as a dash — it is not drawn** (L-44, `PersonPage.swift`'s own rule, kept) |
| **Empty · no rivals** | one `CSEmpty` at 56pt with the door `Find golfers` |
| **Empty · no record** | the leaf is not drawn; the section is absent. An empty leaf is a card |
| **Error / stale** | **keep what is on screen** (§13.3). Cached content renders under `AS OF FRI 6:12 PM · OFFLINE` in `agateS` `mut`, **no action disabled**. Only with nothing cached: one `lead` line in voice, one `body` line, **Try again** as the primary. `YouData.isPartial` already knows which block failed — the failed block, and only it, shows the retry |
| **Private** (`visible == false`) | the credential renders as the **crest state with the name and nothing else** — no figures, no folio serial — then `TourCard.privateLine` in `body` 15 `mut` and the one door that can change it (the buddy action). No empty tiers, no dashes |
| **No photo** | the crest. It is a design, not a fallback (§2). **No silhouette, ever** |
| **Long names** | `display` 34 → 24 → tail ellipsis on the credential; `name` 17 tail ellipsis in every slat; a course name truncates before its city agate does. One policy (§9.1) |
| **Long course / league names** | the season slat's league name truncates; `WEEK 9 OF 14` never wraps (it is the section head's count, `fixedSize`) |
| **Disabled** | a secondary at `bg1` with a `mut` label. **A disabled primary is never ember** (§7.1) |
| **AX3** | §16.3, applied: the **credential's three figures stack to three rows and the object grows the page** — it never scrolls inside itself, and the crest re-anchors to the object's new height. The season slat: the **rail keeps its 44pt width and grows its numeral**; movement and points move under the league name as one agate line. Rival slats: the record and verdict move under the sub-line. The form row becomes five rows, each `date · gross` on its own rule. Any table hides its column heads and each row speaks its own facts. The tab band drops labels and grows glyphs to 28. Reflow is on the **measured advance** (`MeStripLayout`'s model), never a device breakpoint |
| **VoiceOver** | one element per slat: *"2nd. The Fellas, season two, eight golfers. Up two. Nineteen points."* · *"Galen Marr. Eleven meetings since June. You lead six to five."* The tape is **one** element: *"Eleven meetings. You won six, Galen won five. Galen has won the last two."* Every drawn indicator carries a label written in the product's voice (§16.4) |
| **Dynamic Type** | every role is `relativeTo:` a text style; growth caps only on `figure` and `display` (§1.2). Nothing under 11pt at default |

---

## 12 · WHAT IT REPLACES — the files, named

Grepped at HEAD 57b993f under `apps/ios/`.

| File | Fate |
|---|---|
| `CupSeason/You/YouScreen.swift` (328) | **rebuilt** — the tab root becomes credential → season → rivals → form → courses → record. Its `.sheet`/link plumbing survives |
| `CupSeason/You/YouHero.swift` (195) | **replaced** by `CSCredential`. `YouTrophyChip` (the two gold emoji capsules) is **deleted** (YRS-03, §5.3) |
| `CupSeason/You/CredentialCard.swift` (292) · `CredentialFace.swift` (192) | **merged into `CSCredential`** — one object, one chrome, one ratio, one meta string (GP-16, YRS-26). The forced dark palette becomes the **`ceremony` ground by design** (GP-27 resolved, not inherited) |
| `CupSeason/You/YouSections.swift` (274) | **deleted wholesale**: `LifetimeTiles` (the grid of tiles inside a card — YRS-07), `SeasonStatsStrip` and `LeagueRecordView` (label-left/value-right settings rows carrying golf numbers — YRS-01, YRS-02), `RecentRoundsList` **with its per-row delete ×** (YRS-22 — an identity page is not an admin tool; deletion moves to the round's own receipt). `CareerRecordView` becomes the Record page's career rule-and-figure. `LastRoundWithCard` (D63) survives as a wire item on Home, not on the profile |
| `CupSeason/You/YouRows.swift` (94) | **deleted** — `YouStatRow` and `YouDoorRow` are the settings-list grammar the audit names. Doors become slats and tertiary links |
| `CupSeason/You/RecordPage.swift` (271) | **rebuilt** as §9 |
| `CupSeason/You/TrophyCaseView.swift` (132) | **replaced** by the trophy slats. The engraver ceremony (a "what works") is **kept** and moves onto the slat |
| `CupSeason/You/RivalriesSection.swift` (199) | `RivalriesSection` **rebuilt** as §4's slats; `RivalrySheet` / `NameRivalrySheet` keep their behaviour, gain §7.3's sheet grammar |
| `CupSeason/Golfers/PersonPage.swift` (393) | **rebuilt** as §2–§8. Its `MathRow`/`CSRow`/`CheckRow` stacks, the three `lengths()` door rows and the `careerEyebrow` table all go |
| `CupSeason/Golfers/HeadToHeadPage.swift` (272) | **rebuilt** as §10 |
| `CupSeason/You/TourCardSheet.swift` (207) | **becomes a presentation of `CSCredential`** at 0.82 with the leaf on its reverse (§6.5). Its mute + two-step report move to P-17 in the toolbar, one control type (GP-29) |
| `CupSeason/You/FoundingTag.swift` (32) | folds into `CSSlot` |
| `CupSeason/You/GuideSheets.swift` (68) · `CredentialDev.swift` (84) | unchanged |
| `CupSeason/You/BagSheet.swift` (215) | **out of scope here** (YRS-13 is its own surface); the profile's bag block becomes a leaf grid of `slot · club` and keeps `BagCopy` |
| `CSDesign` | **adds** `CSCredential`, `CSSlot`, `CSMedallion`, `CSRankRail`, `CSSlat`, `CSLeaf`, `CSFigure`, `CSMovement`, `CSFace`, `CSSectionHead`, `CSEmpty`. **Retires** `CSCard`, `CSHero`, `CSStat`, `CSMini`, `CSButtonStyle.gold`, `CSEmptyState` |

---

## 13 · PRODUCERS AND COPY IT CONSUMES UNCHANGED

Nothing on this surface invents a fact.

| Fact | Producer |
|---|---|
| name · handle · city · home course · index · member-since · `isMe` | `TourCard.Profile` |
| the photograph | `YouRepository.profileExtras` → `rounds.signedURL(photo_path)`; `TourCardLoad.avatarURL` |
| the founder slot | `SessionStore.founding.badge(for:)` · the registry number behind `FoundingTag` |
| rounds · best · average · the lens | `TourCard.CareerBlock` (`playingLens`, `bestText`, `avgText`) |
| the five grosses and their dates | `TourCard.recent` (`gross`, `playedOn`, `beat`) via `FormRow.from(beats:)` |
| courses kept · shared courses | `TourCard.courses` / `TourCard.sharedCourses` — **returned by `tour_card` since D150 and discarded by the phone ever since** (`TourCard.swift:93-126`). This design finally renders them |
| the best round | `TourCard.bestRound` (`gross`, `courseLabel`, `playedOn`) |
| trophies | `TourCard.cabinet` (`kind`, `title`, `subtitle`, `placement`, `seasonYear`) · `Rpc.my_achievements` · `TrophyMeta` |
| the current season line | `LeagueRecordRow` (`name`, `number`, `line`, `sub`, `spoken`) · `SeasonStats` |
| rivals | `YouData.rivalries` → `RivalryLine` (`name`, `marker`, `facets`, `record`, `lead`, `rivalryName`) |
| the head-to-head | `HeadToHead` (`record`, `lead`, `since`, `streak`, `lastFive`, `facets`, `rivalryName`) |
| every rivalry sentence | `HeadToHeadCopy.headline` · `.standfirst` · `.emptyHead` · `.emptySub` · `.heuristicNote` · `.unconfirmedNote` · `.notAVouch` · `.personNarrative` · `RivalryCopy.record` |
| the ledger line | **`MoneyCopy.ledger`** (web: `CS_LEDGER`) — verbatim, one constant (LINT-23) |
| the private state | `TourCard.privateLine` |
| no rounds | `TourCard.noRoundsYet` |
| the lengths | `TourCard.Length` · `.lengthsSub` · `.weekNotYet` |
| the bag | `BagCopy.head` · `.sinceLine` · `.sideline` |
| the marker paths | `MARKERS` in `index.html` → `Markers.swift` (generated) |

---

## 14 · NEW DATA THE DESIGN NEEDS

Five, each small, each with a stated degrade so Phase 3 can ship the surface before the server catches
up. **None of them is invented behaviour** — each is a fact the product already computes somewhere and
does not expose here.

1. **`finish` and `won` as fields, not prose.** `LeagueRecordRow` carries one pre-formatted string
   (`"2ND OF 12 · 41 PTS"`). The leaf needs `finish: Int?`, `of: Int?` and `won: Bool` so the finish can
   be set as a `figure` with an ordinal rider and the earned rule can attach. *Degrade:* render `line`
   in `column` 14 in the finish column, no rule.
2. **Per-season money on the record row.** `CareerRecord.earningsCents` is a career total;
   `season_payouts` holds zero rows in prod, so `seasonsDone` reads 0 for everyone. The leaf's MONEY
   column needs a per-season net. *Degrade:* the column is dropped and the leaf runs three columns —
   the table is still a table.
3. **The golfer's own movement in the current season.** `▲2` exists for the season table; the You /
   tour-card payload does not carry the viewer's own rank delta. *Degrade:* the movement column is
   omitted (never a `—` and never a guess).
4. **The standing line's second clause.** `4 back of <leader>` is produced for Home; `3 clear of
   <the golfer behind you>` is not. *Degrade:* the sentence renders its first clause only.
5. **The full ordered meeting list for the tape.** `HeadToHead.lastFive` returns five; the tape draws
   every meeting. Extend `last_five` to `meetings: [{on, won, facet}]` (cap ~24, oldest first).
   *Degrade:* the tape draws five ticks and its dateline reads `LAST FIVE`, which is honest and still a
   graphic.

Also required, and not server data: **a drawn glyph per achievement kind** (§5.2 — two achievements may
never share a glyph), and `courses` must be read on the **You** root from the same `tour_card` producer
the person page already calls (a re-use, not an endpoint).

---

## 15 · MOTION

Two curves only (§11.2): `roll` for travel, `snap` (180ms) for arrivals and tallies. Nothing bounces.
`accessibilityReduceMotion` resolves both to `nil`, never "faster". Every rest frame is the finished
state.

| Moment | What happens |
|---|---|
| **the credential arrives** | the object **wipes** from its left edge over 220ms on `snap`; the three figures **tally** from 0 to value over 340ms; the medallion **seals** on the last frame. Once per appearance, gated by a replay-on-open flag |
| **your rank changed since last open** | the season slat's numeral **slots** (`RankFlipText`, kept), then the movement mark wipes in from the rail after the row settles. `.impact(.light)` — and only because it is *your* row (§11.3) |
| **the tape draws** | the ticks wipe left to right at **26ms** per meeting, oldest first, so the run reads as a run. `6–5` tallies alongside |
| **the form row** | the five figures wipe from the rail edge at a 40ms stagger; the gold rule under the best arrives last |
| **Share the card** | the credential lifts to the export geometry and renders at 2× — **the object the audit calls the most beautiful in the product is seen in-app, at the geometry it exports at** (§11.3) |
| **a trophy is engraved** | the shipped engraver — a 2pt gold needle sliding a cover off a fresh trophy's name over 1.1s — **survives verbatim** onto the trophy slat. It is the one real ceremony on this surface and the audit calls it out as a "what works" |
| **never** | a bare opacity fade, a shimmer skeleton, an animated disclosure, a spinner in content (§11.4) |

---

## 16 · THE WEB DESK, IN ONE PARAGRAPH

Ruling R-C: the same visual system, a different shape. On the desk the profile is a **two-column body
under the 236pt sidebar** (`1fr + 340pt`, `gutterDesk` 40): the credential sits at the **top of the
right rail at its natural 362pt width — it does not stretch**, because it is a fixed object and a
stretched credential is a banner; under it, in the same rail, the season slat and the rivals. The left
column takes the record at length — the leaf runs the **full** season table with two extra columns
(`RDS · BEST · GAP · PTS · MONEY`) and a five-dot form column inside each row (§14.3) — with the
courses-kept table beneath it and the trophies as a printed list. `display` grows to 42, the slat to 56.
**Hover** steps a slat's ground to `bg1` and paints its rail slot `bg2`; a link's 2px `brand` rule
thickens to 3px; **every hover state has a focus twin** — a 2px `brand` outline on the whole slat,
never suppressed. Keyboard: `↑`/`↓` between slats, `→` opens the head-to-head, `Esc` closes. The record
leaf and the credential both carry **print stylesheets** — the archive test, made functional.

---

## 17 · DEVIATIONS FROM `UI_SYSTEM.md` — for the refuters

| # | The rule | What I did, and why |
|---|---|---|
| **D-1** | ADOPTED | §6.5 now rules **362 × 312, measure-relative**, product-wide, with the 3:4 portrait kept only for the share PNG. This is no longer a deviation; it is the system. |
| **D-2** | §15.2's stated order: card → form row → record leaf → courses kept | Reordered to card → **season → rivals** → form → courses → record. §15.2 does not include COMPETITION at all, and **`BRIEF` §10 names it explicitly** as the profile's second tier. The materials are unchanged; only the order is. |
| **D-3** | RESOLVED in the system | §1.5 now budgets **ten tracked-caps agate lines** per viewport and counts every one, with a **sentence-case sibling** for anything that is a phrase rather than a label. `profile-top` carries ten once the identity line, the courses-kept glosses and the rival sub-lines set in sentence case. No special pleading for the credential. |
| **D-4** | §2.4: at most one gold object per viewport | `profile-scrolled` carries the form row's gold best **and** the record leaf's earned rules. §9.8 is narrowed (a **win** takes gold; a **podium** takes an ink rule) so the leaf's visible rows are ink there. **Confirmed reading:** a table's earned marks count as **one** gold object, the way the season's leader-rail-plus-pot pair is whitelisted; `LINT-17` carries `CSLeaf.earnedRule` on its whitelist by name. |
| **D-5** | §9.8: "a won **or podium** finish is marked by a 2pt gold rule" | Narrowed: gold for a win, ink for a podium (§7). More faithful to §2.4's "only on something that was won". |
| **D-6** | ADOPTED into §3.3, with the mechanism named | **On a leaf, gold is always the light-theme gold `#7A5A12`, in both themes**, because the leaf does not invert and dark gold at 2pt on `leaf` is invisible. §3.3 now names how: **`CSLeaf.earnedRule`** reads `CSTokens.light.gold` explicitly, rather than leaving Phase 3 to reach for a literal that preflight 15 would fail. |
| **D-7** | §12.2: every pushed screen names itself with `CSPageHeader` | The **You root and the person page carry no page header at all** — the credential is the header. GP-17 and GP-09 are both "the name is said too often and set too small"; a header above the object would restate it a third time. The Record and the head-to-head **do** use `CSPageHeader`. |
| **D-8** | ADOPTED into §5.1 as the product-wide idiom | **A row whose whole surface is the target carries no chevron**; a chevron appears only where the row contains a second, smaller target. That settles the two idioms the first draft shipped side by side (`season-money`'s three chevrons against this page's none). The affordance a full-row door does carry is stated rather than assumed: the row's **verb sets in `name` caps at `ink`** against `mut` glosses and `mut` sub-lines everywhere else on the page, and the door rows sit in their own rule-bounded block at the page foot — so a golfer with low vision has a weight step and a position, not only a hairline. |

## 18 · KNOWN IMPERFECTIONS IN THE RENDERS (stated, not iterated a fourth time)

1. **`profile-light`'s crest.** The Lone Tree's closed canopy sits behind the gold medallion and the two
   together read as an eye. This is a real finding, not a mockup accident: **a single fixed crest
   transform cannot serve fourteen different marker silhouettes.** Phase 3 must anchor the crest by the
   marker's own bounding box — the same optical normalisation §6.2 already applies to the disc — and
   push the medallion to the object's lower-right whenever the crest's ink falls inside the medallion's
   46pt circle. The Saguaro on `profile-top` shows what the treatment looks like when the two do not
   collide.
2. **No photographed credential is rendered anywhere in this set.** The product has no photograph this
   session may use and fabricating a face is forbidden (§10.4). The crest state is drawn instead — which
   is the state most golfers are in, and the photo path is specified in §2.
3. `profile-scrolled`'s record leaf and `profile-top`'s FORM head are deliberately cut by the 28pt fade
   — that is the scroll continuing, not clipping.
4. `profile-light` shows the *person page* in light rather than the You root, so one artboard carries
   both the second printing and the not-me variant. The two differ only in the chrome row, the primary
   button and two section titles (§8).

## 19 · §28, ANSWERED

| | |
|---|---|
| 1 · The most important thing | Who this golfer is — and, one scroll down, what they have done |
| 2 · Identified instantly | Yes: one object with depth on a flat page, name at `display` 34, three tabular figures on a rule |
| 3 · Hierarchy supports the UX | Yes — the page's ranked action (play them) is the only ember object and sits above the fold |
| 4 · Looks like Cup Season | The rail, the rule-and-figure, the folio, the medallion and the leaf could be nothing else |
| 5 · Premium | The card is a physical object; the record is printed; nothing is a rounded rectangle by default |
| 6 · Generic template | No settings rows, no stat table, no tiles, no chips, no segmented control |
| 7 · Unnecessary UI | Removed: 2 emoji capsules, 5 door rows, 8 stat rows, a legend sentence, a GHIN line, a registry line, a delete ×, a second marker, 4 borders, a wash and a seam |
| 8 · 20% simpler | ~40% fewer elements above the fold than the shipped You |
| 9 · Personality | The crest, the folio serial, the meeting tape, the standing sentence that names the rival |
| 10 · Proud to post | `profile-top` and `profile-h2h` — yes |


---

# THE BLIND REVIEW, AND WHAT IT CHANGED HERE

*2026-09-06. Three reviewers who had never read `UI_SYSTEM.md`, `UI_AUDIT.md` or this spec judged the
artboards against the shipped screens and against the consumer-sports category. Their scores are in
`UI_SCORECARD.md` §TARGET. Everything below is a change made to this surface as a result; the system
rules the changes propagate into are named. Declined findings are in `UI_SYSTEM.md` §20.1.*

**How the three scored it.** Instantly 3/3 · looks like Cup Season 3/3 · premium 3/3 · template 0/3
· proud to post 3/3 · belongs 3/3. Median **7.8**, with the lowest cell in the row being **consistency
6** — and every one of the consistency findings was a page contradicting itself.

**1 · The headline reads the field the rail reads.** *"The best of them an 80, at Papago"* sat 200pt
above `74 BEST` and a trophy reading `74 at Troon North`. Two reviewers filed it and blind-1 named the
cost exactly: *"On the page whose promise is that every number shows its work, this costs more
credibility than any spacing error in the deck."* The headline is now *"Eighteen rounds since March.
The best of them a 74, at Troon North."*

**2 · One join date, and the right-of-rule slot carries a count (§16A.2).** `SINCE MARCH 2026`,
`SINCE 2026` and `EST. JUL 2026` disagreed three ways (the third is a different golfer's card, and is
correct). `THE RECORD`'s slot now reads `THREE SEASONS` — a count, which is the slot's one job — and
the join date is printed once, on the archive page that is about it. blind-3's finding that the slot
was carrying counts, a range, a filter and a date on one screen is what became §16A.2.

**3 · The meeting ladder is labelled.** blind-1: *"it is an original scoreboard graphic and it is one
caption away from being unambiguous."* Under the axis, in `agateS`: **One square is one win.** Four
words, and the graphic survives (blind-3 asked for eleven W/L pills instead; declined in §20.1).

**4 · Column heads on `COURSES KEPT` (§16A.3).** `Papago PHOENIX 11 77` gave the reader no way to know
which number was which. `RDS` and `BEST` now sit over the columns they name.

**5 · One ordinal (§1.7).** `2ND` small-cap, `2nd` raised superscript and `5th` were three forms on
one surface. There is now one: uppercase, 0.46 em, **on the baseline**.

**6 · Fewer row grammars, and the door stops repeating the count.** `RIVALS` was three rows of
avatar + record + meeting count + league — "a table pretending to be a list" (blind-2). It is two rows
and a door reading `EVERY RIVAL`, and `ALL ELEVEN` under a slot already reading `ELEVEN` became
`THE OTHER EIGHT` (§16A.2). The ledger sentence is gone from this surface entirely (§16A.1), and the
utility slot says `SHARE` — one word for one job across the whole card family.
