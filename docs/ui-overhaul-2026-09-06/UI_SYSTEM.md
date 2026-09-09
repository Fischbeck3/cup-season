# UI_SYSTEM — the Cup Season visual language

**Date** 2026-09-06 · **HEAD** 57b993f · **Phase** 2 of 3 (design; nothing is built)
**Standard** `BRIEF.md` §3 and §1–§35 · **Evidence** `UI_AUDIT.md`, `UI_SCORECARD.md`
**Priors** `docs/ios/IOS-003-design-direction.md` §1 (the identity contract), `spec/brand-canon.md`,
`packages/tokens/tokens.json`, `docs/ux-overhaul-2026-09-04/COMPONENT_SYSTEM.md` (the 17 patterns),
`docs/ux-overhaul-2026-09-04/OWNER_RULINGS.md` R-C (the web's shape)
**Mockups** `system-mockups/system-mockups.html` → `system-mockups/renders/` (8 artboards)
**Contrast** every ratio in §2 and §16 was computed by `system-mockups/contrast.mjs` from the hexes printed here

> **This document replaces `IOS-003` §1 as the identity contract.** Where the two disagree, this one
> wins, and §0.3 lists every line that changed and why. Nothing here was inherited silently: every
> element of the old contract was re-decided, and the ones that survive say why they survived.
>
> **Phase 3 builds from this file without asking questions.** Every number is exact. Every rule has a
> one-line reason. Where a rule cannot be enforced by a preflight grep, §17 says so.

---

# 0 · THE IDEA

## 0.1 The thesis, in one paragraph

**Cup Season is the tournament board, printed.** Golf's own graphic language is not the fantasy app
and not the stadium: it is a hand-set scoreboard on a wall and the almanac that records what the
board said. So the product is built out of **bands, rules and a rank rail** instead of cards; its
names, ranks and every numeral are set in a **condensed grotesk** — the scorer's hand, not the
system's; its metadata is **agate**, the condensed caps of a newspaper's sports page, not a terminal's
mono; its one serif sentence per surface is the almanac's voice; and the two objects it allows itself
are **the panel** (a small opaque bone tile holding one number) and **the leaf** (a sheet of
scorecard paper, allowed only when it carries a printed grid). Colour is spent on state and nothing
else: ember means *live*, champagne means *earned*, and a golf score's quality is never coloured at
all — a birdie is a ring and a bogey is a box, drawn in ink, the way it is on paper. Money is ink, the
sign is a word, and the pot is gold. Every ranked thing in the product begins with the same 44pt rail,
painted gold when the position was earned and bone when the position is yours. Remove the logo and
the rail, the rule-and-figure and the agate still say Cup Season.

## 0.2 The signature

> **THE RANK RAIL and THE RULE-AND-FIGURE.**
>
> **The rail** — a 44pt left column carrying a two-digit tabular numeral in condensed bold, its top
> edge a full-bleed hairline, its field painted only when the position is *earned* (gold) or is
> *yours* (bone). Every ranked list in the product starts with it; it is the origin of every arrival
> in §11; and it is why the layout survives every phone width unchanged.
>
> **The rule-and-figure** — a number that matters, set in the board face with tabular figures, sitting
> on a **2pt rule the width of its column**, with its label hanging beneath in agate. The rule is
> `ink` by default, `brand` when the figure is live, `gold` when it was earned — so the two-metal law
> is a *graphic device* rather than a colour you have to remember, and the numeral itself stays
> uncoloured.

Both pass the two standing filters in `brand-canon` §5–§6: they embroider (a rule, a numeral, a bar),
and they would look right printed in the crew's season book in 2046, because that is how a season book
prints a number.

Corollary, and it is the whole anti-card rule in six words: **numbers never wear a box; boxes wear
numbers.**

## 0.3 What this keeps from the identity contract, and what it changes

### Kept — each with the reason it survived a deliberate re-decision

| `IOS-003` §1 row | Kept as | Why it survives |
|---|---|---|
| **Two metals, never swapped** (ember = LIVE, gold = EARNED) | Kept, and finally enforceable | It is the most ownable rule in the product and the only one that reads as *scarcity*, which is what "premium" means here. It failed before because emphasis had nowhere else to go; a display tier and a 2pt rule now absorb everything gold was doing for emphasis. §2.4 |
| **`bg0` is a green-black, not a grey-black** | Kept, deepened *and* greened: `#0F1A15` | The fescue idea is right. The failure was measurable: the shipped `#0B1410` is ΔE 6.88 from pure black, so the cast was not nameable. The new ground is ΔE 10.28 — 49% more separation — at chroma 6.35. §2.2 |
| **Markers as the avatar floor · no silhouette state** | Kept verbatim, and made a system | A proprietary drawing set nobody can copy without it looking copied, and the only humane answer to a product with almost no photographs. What changes is that a bare glyph is deleted: `CSFace` becomes the only legal way to draw a person. §6 |
| **Emoji stay emoji — the six reactions** | Kept verbatim | Reactions are emoji in every social product. The failure was leakage into ~35 UI sites, not the rule. §5 |
| **`pos` / `neg` semantic only · the four squad colours** | Kept, with `neg` re-jobbed | Semantic colour is the cheapest legibility there is. §2.5 |
| **The roll easing · nothing bounces** | Kept verbatim (`cubic-bezier(.16,.84,.36,1)`) | "Golf doesn't bounce" is why the product never feels gimmicky. `snap` is added *beside* it, not instead of it. §11 |
| **Radii 16 / 10 / 24** | Kept; 3 and 28 join them | They are correct. 28 is promoted from the de-facto ceremony literal the audit found doing deliberate expressive work; 3 is new, for printed objects. §3.4 |
| **The Forge, the ceremonies, the Tracer mark** | Kept | The strongest sequence and the strongest asset in the product. The Forge's heat ramp survives as three private constants inside the door, not as palette tokens (§2.6). |
| **The voice · band words · the ledger line · "the Pro"** | Kept verbatim | The audit calls the copy the strongest asset in the product; it was only ever wrong in its *size*, which the display tier fixes. |
| **The five destinations** — Home · Compete · ⊕ Play · Golfers · You | Kept | `OWNER_RULINGS` **R-A / D222** is a flow ruling, not a visual one, and it overrides D82, D93, D94 and IOS-011. What changes is the chrome around it. §12 |
| **A visible build identity** | Kept | `v23 · <sha>` in Settings and at the foot of the desk's sidebar. |

### Changed — each naming the row it overrides

| Change | The row it overrides | Why |
|---|---|---|
| **The 3.5pt spine leaves the card edge and becomes the 44pt rank rail** | §1 "The spine — 3.5px left accent bar as the card grammar" | 13 of 20 `CSCard` sites draw a border and a spine 2px apart, and the spine rides paragraphs, menus and option lists — so it means "a box", not "live" or "earned". As a rail it means *position*, which is a thing the product actually has. (Audit D1.) The **three-state spine is replaced by a two-state rail**: painted means something, unpainted means nothing — audit D2's finding that `line2` at 1.80:1 is a third state below the threshold of sight. |
| **The card and its border are deleted outright** | §1 "the card grammar" | The fill is 1.084:1 and the border 1.443:1; on eight of fifteen screens in the card census, deleting every border costs zero information. The system has **no border token**. §3 |
| **The serif is New York; Charter is retired** | §1 "Serif: Charter ships on iOS as a system face" | Charter has no display cut, no optical sizes and one weight step, and it must be addressed by PostScript string — the exact defect class of D258, which rendered 296 mono sites in SF Pro for weeks. New York is free, has four optical masters, needs no string, and is unusual enough in 2026 to read as a choice. Ruled by the owner-eye judge; two of three directions arrived at it independently. §1.1 |
| **A condensed grotesk is bundled and becomes the voice of the board** | §1 "Three type voices with jobs" | §5 of the brief says typography must carry a significant portion of the brand; that cannot be done with system faces alone, and the shipped display tier is 2% of type sites. IBM Plex Sans Condensed is a **cut of the family already bundled**, so the family count stays at three (§1.1 answers the "no fourth family" fence head-on). |
| **Mono falls from ≈55% of type sites to ≈12%, and loses the eyebrow** | §1 "Mono = the scorer's tent (labels, eyebrows, stats, codes, inputs)" | 310 sites of 11–12pt tracked mono caps is the product's *default* voice, not its metadata voice, and the door's email reads as a terminal prompt. Metadata moves to **agate**; mono keeps what print gave it — **columns of figures, codes, handles and times**. (Audit D3, D4.) §1.4 |
| **The heat axis collapses to ember** | §1 "One heat axis: warm → hot → fire · cool" | Every carrier the axis had is gone: the ramp is a gradient (§4's named do-not, audit D7), the pressure meter is deleted, the month becomes countable week ticks, the carry becomes a figure. A four-tone axis rendered at 11pt is a legend, not a signal. **A clock that is running is ember; one that is not is ink.** `cool` survives for falling. §2.6 |
| **`dawn` is deleted** | §1's palette, by implication; the token's own note | A third metal on the first screen reads as iOS link blue — the single most template-like signal in the product — and its 25 sites split evenly between *links* and *statuses*, so neither reading wins. Links become underlined ink; statuses become `mut`. (Audit D5.) |
| **`grad`, `glow`, `pine`, `line2`, `focus`, `shadow-rest` are deleted** | §1's palette | A three-stop amber→red capsule is §4's "generic sports gradients" verbatim; `pine` has 0 call sites, `shadow-rest` 0 references, `glow` 1; `focus` #FF8A4C is a *fourth* warm hue and the brightest object on a form. The focus ring becomes `brand`. |
| **Money leaves `pos`/`neg` entirely** | §1 "`pos`/`neg` — money in / money owed" | A red/green P&L axis on golf is the grammar of a brokerage and §1's named "overly minimalist fintech app". **Money is ink, the sign is a word in agate (YOU OWE / YOU'RE OWED), the pot is gold**, and the ledger line sits under every money surface. (Audit DD-05; all three judges.) §9.5 |
| **The light theme is rebuilt as warm almanac stock, not a paler dark** | §1 "Light is 'same bones, dawn palette'" | The shipped light palette put `pos`, `neg`, `gold` and `brand` inside a **0.03** contrast spread, so nothing outranked anything, and its ground chroma of 1.07 is below the threshold at which a cast is nameable. There was no dawn in the dawn palette. (Audit F-03.) §2.3 |
| **The credential is a physical object: the ceremony ground in every theme** | §2.6, extended | One golfer should not have two different objects in Light. And the composer — which is an *input* — comes **off** the ceremony ground, because a form is not a ceremony. (Audit D8.) §6.5 |
| **Empty states get a shape and a number, and never name the golfer's omission** | §3 "Empty: quiet icon · one line · one next move" | Not one canonical empty state in the product contains an image, a shape or a number, and §17 of the brief forbids the exact sentence the product ships ("Nothing in the bag yet."). The four-part shape survives; the *icon* becomes a drawn object at 56–76pt and the door becomes a required parameter. (Audit D9; `COMPONENT_SYSTEM` CS-A3.) §13.1 |
| **A second easing, `snap`** | §1 "The roll — the one timing curve for every transition" | Duration alone does not read as importance, so a lead change currently moves like a disclosure opening. `snap` is for *arrivals and tallies*; `roll` keeps everything that travels. Nothing bounces either way. (Audit D10.) §11 |
| **Gold may never touch a control, and `CSButtonStyle.gold` is deleted** | `UX_PRINCIPLES` §4, made absolute | Gold on a button, a tab or a nav is "a defect, not a taste call". Scarcity is the entire mechanism by which the metal means anything. Ruled by the owner-eye judge over almanac's gold slab. (`COMPONENT_SYSTEM` CS-A2.) §7.1 |
| **The looks system is narrowed to the rail and the eyebrow, and loses its emoji motifs** | `looks` in `tokens.json` | This is the first defined *job* the looks have had: the Cup Final's ember rail and the Wrap's gold rail become a real seasonal signal at zero palette risk. Their `motif` field currently holds emoji (✿ 🏆 ⛳ ★ 🌬 ⚔️ 🍂 ✦ ◌ 🔥), which §5's emoji ban forbids; each becomes a drawn glyph name. §2.7 |

## 0.4 The audit's ten problems, answered by name

| # | The problem | Where this document answers it |
|---|---|---|
| 1 | The card is the only container, and it is a border on a flat ground | §3 — the card and the border token are **deleted**; structure is band, rule, rail, whitespace; the only containers are the panel (≤96×96, one figure, never a sentence), the leaf (a printed grid, never prose) and the object (a physical artefact). The rule goes from 1.443:1 to **2.66:1**; the panel to **14.91:1**. |
| 2 | Golf numbers are not visual objects except on two screens | §0.2, §1.6, §9 — one `figure` role at four sizes, tabular, in the board face; every figure ≥27pt is a **rule-and-figure**; ten renderings of the gross become three. |
| 3 | No face and no photograph anywhere except one credential | §6 — `CSFace` is the only legal way to draw a person, the disc takes a **six-pigment tint keyed to the golfer's id**, faces appear in every table row, every field, every wire item and the desk; §10 gives photography two real sources the product already has. |
| 4 | The action layer has no system and no state | §7 — three tiers, five declared states each, `ButtonStyle`s rather than a `View`, one chip, one field with six states, one sheet grammar, one dismiss verb. |
| 5 | Ember has no reserved seat and gold is not "earned only" | §2.4 — ember has exactly two jobs (live, and the one primary action) and gold exactly one, with a **hard budget of one gold object per viewport counted by hue, not by token name**, and **an average is not earned** (a course's rating is `ink`). The tab bar's ⊕ loses its fill and becomes a glyph. §7.1 splits the tertiary link into three so a dismiss verb, a Settings link and a Share link cannot wear the live metal, and `LINT-18` counts **every** ember mark on a viewport rather than fills alone. |
| 6 | Five glyph vocabularies, and the app icon is Xcode's placeholder | §5 — one drawn family at the markers' 1.7pt weight, four sizes, three tints; SF Symbols survive for eight OS affordances; **every UI emoji is deleted**; nine flags become one; `brand/appstore-1024.png` ships with the iOS 18 dark and tinted variants. |
| 7 | No display tier, and the eyebrow is the product's default voice | §1 — nine roles replace eighteen, three of them display-scale; the eyebrow becomes **agate** with a per-viewport budget of **ten tracked-caps lines** that counts everything on the screen (§1.5), a **sentence-case sibling** so a phrase is not shouted (§1.3), and a **render-time probe** rather than a per-file grep (§17). |
| 8 | Empty, loading and disabled are unbuilt; the empty contract is the anti-pattern | §13 — each of the four states has an anatomy, a required door, a shape and a number; disabled exists and is quiet; loading is the destination's own geometry, redacted. |
| 9 | The ceremony hierarchy is inverted | §11 — five named moments sized to the moment; the takeover band is the biggest motion in the product and belongs to the biggest event; the settlement card is rendered **in-app** at the geometry it exports at. |
| 10 | Nothing re-ranks for the phone; floating chrome guillotines content | §12.1 — the tab bar becomes a **full-width band on the page's own ground with a rule on top**, so there is nothing to float over; every scroll reserves its height and ends in a 28pt fade; §16.3 gives every layout a stated AX3 form; one long-name policy product-wide. |

## 0.5 What this takes from the three directions, and what it refuses

The three Phase-2 directions were `broadcast` (the winner, 148), `almanac` (146) and `clubhouse`
(126). Three judges filed grafts and rejections. **Every graft is implemented and every rejection is
honoured**; the table says where.

| Graft | From | Implemented in |
|---|---|---|
| The rule-and-figure — a display numeral on a 2pt rule with an agate label beneath, ember for live, gold for earned | almanac | §0.2, §9.2 — the signature |
| Condensed-caps agate as the metadata voice, replacing the tracked-mono eyebrow; mono freed for columns of figures | almanac | §1.2, §1.4 |
| The folio ruled off at the foot of the credential | almanac | §6.5 |
| The form row — five grosses with dates on one rule, best in gold | almanac | §9.7 |
| The record as a printed table (year · competition · finish · money) | almanac | §9.8, §15.6 |
| The paper light theme — warm stock, gold re-hued to bronze, ember to a stamp red | almanac | §2.3 |
| The money grammar: ink for the ledger, the sign as a word in agate, gold for the pot, the ledger line beneath | almanac | §2.5, §9.5 |
| The masthead and dateline — the wordmark over a 2pt rule, the date flush right | almanac | §12.3 |
| The standing line — four figures on one rule, the league sentence in agate beneath | almanac | §9.6 |
| The tab bar as a full-width band with a rule on top, only Play in ember, no floating pill | almanac | §12.1 |
| The bone panel — one opaque tile, one number or one word, ≤96×96, radius 3, never a sentence; inverted in light | broadcast | §3.2 |
| The 44pt rank rail, and "numbers never wear a box; boxes wear numbers" | broadcast | §0.2, §9.1 |
| The scorecard ink law — ring / double ring / box / double box, no colour | broadcast | §9.4 |
| Faces in every table row; the event's field rail | broadcast | §6.3, §15.5 |
| The per-layout Dynamic Type spec | broadcast | §16.3 |
| The movement mark — a drawn triangle plus a tabular numeral, a 9×2 bar for held, ▼ with exactly one meaning | broadcast (field removed, see below) | §9.3 |
| The paper leaf — a bone scorecard sheet inside the dark page, licensed only for printed grids | clubhouse | §3.3 |
| The six-pigment marker disc keyed deterministically to the golfer's id | clubhouse | §6.2 |
| The overlapping face row for "who of yours has played it"; the spaced row with names at field size | clubhouse | §6.3 |
| "A round photo is never an avatar" — it renders as a 3:2 plate | clubhouse | §6.4, §10.3 |
| The season `look` tints the rail and the eyebrow only, never a ground | clubhouse | §2.7 |
| The outright ban on a gold button | clubhouse | §7.1 |
| The course facts as one line of type | clubhouse | §15.3 |
| The form column as five dots inside a desk table row | clubhouse | §14.3 |
| The topographic contour — clubhouse's idea, broadcast's execution, at plate scale only | clubhouse + broadcast | §10.2 |

| Rejection | From | The rule that forbids it here |
|---|---|---|
| The full-bleed ember LIVE band across Home | broadcast | §2.4 — **no saturated field wider than a chip may carry a label.** LIVE is a 7pt ember dot plus an ember agate eyebrow on the lead itself. |
| The filled/tinted movement chip | broadcast | §9.3 — movement is a **drawn triangle and a tabular numeral on the page's own ground**. No tinted field. (Two of three judges; craft's version of the graft is taken minus its field.) |
| The four-cell hairline-divided facts rail on the course page | broadcast | §15.3 — the facts are **one line of type**. Vertical hairlines between four boxed figures are the audit's 2×2 KPI grid with different borders. |
| `neg` red on money | broadcast | §2.5, §9.5 — money never takes `pos` or `neg`. |
| Bundling a condensed face *while keeping Charter by PostScript string* | broadcast | §1.1 — Charter is retired, so the only string-addressed faces are the two bundled Plex cuts, pinned in one constant and asserted by preflight; the family count stays at three. |
| Near-universal uppercase | broadcast | §1.3 — the case law plus a **per-viewport budget** (one `display`, ten tracked-caps agate lines), a **sentence-case `agate`** for anything that is a phrase rather than a label, and the rule that a person in a social row is title case. |
| Condensed ALL CAPS for every person's name on every surface | broadcast | §1.3 — `name` (caps) is the board, the title and the credential; `social` (title case) is a person in a wire row, a course row or a comment. |
| The profile's LABEL/sub-line/figure segment (the fantasy player page) | broadcast | §15.2 — the profile is a credential and then a **record**, printed on a leaf. |
| The claim of faces that the render did not show | broadcast | §6.3 — faces are a *rule* (`CSFace` is the only path), not an intention, and `cs-home-dark` carries one. |
| The words-only tab bar | almanac | §12.1 — the band survives, the drawn glyph above the word survives. |
| No faces in the season table; a squad bar **instead of** a disc | almanac | §6.3, §9.1 — every table row carries a disc, **and in a squads season the sub-line also carries the squad's swatch and name**. The rejection was of the swap, not of the squad channel. |
| An event page with no field | almanac | §15.5 — the field is a rail of faces with names. |
| Captions that explain the graphic | almanac + broadcast | §10.2 — a plate never carries a caption teaching the reader how to read it; it carries a *credit* (the photographer) or nothing. |
| The agate budget stated but not counted | almanac | §1.5 — a **counting rule** that a preflight can run. |
| `rise` in amber while gold is budgeted "once per screen" | almanac | §2.4 — the gold budget **counts hue, not token name**, and there is no amber in the palette: movement up is `pos`. |
| Every surface opening with the same serif-over-rule device | almanac | §15 — six surfaces, six different opening objects, named. |
| Four tracked-caps actions in a row as Home's foot | almanac | §7.1 — one primary, one secondary, the rest behind a door. |
| The felt panel as Home's lead container; a plate inside a panel | clubhouse | §3.1 — box-in-box is unwritable: a panel may not contain a panel, a leaf or a plate, and preflight greps for the nesting. |
| The white (or ember) ⊕ disc in the tab bar | clubhouse + broadcast | §12.1 — the ⊕ is a **drawn glyph in ember**, no fill, no disc, no square. |
| `brassbg` as a fill behind a figure | clubhouse | §2.4 — gold is a rule, a rail field, a slot or ink on a numeral. It is never a large fill behind a figure. |
| The contour at thumbnail scale | clubhouse | §10.2 — the drawn card is the thumbnail; the contour is plate scale and above, and a course with neither shows **no thumbnail at all**. |
| Five radii including a 20 for the felt panel | clubhouse | §3.4 — four jobs, four values, plus 28 for ceremony. |
| A tone-step depth model that dies in light | clubhouse | §3.5 — depth is never a tone step. The panel *inverts*. |
| The contour as wallpaper behind running text | clubhouse | §10.2 |
| Two competing display voices | clubhouse | §1.2 — one display voice; the serif is a supporting role at one appearance per viewport. |
| Typed ASCII arrows (`^2`, `v1`) | clubhouse | §9.3, §17 `LINT-13` — preflight fails an arrow character inside a produced string. |
| A CSS gradient wash used as course or round imagery | all three | §10.1 — the imagery ladder has exactly three legal states and a wash is not one of them. |

---

# 1 · TYPOGRAPHY

## 1.1 The faces, where each comes from, and the bundling plan

| Voice | Family | Weights | On iOS | Cost / licence |
|---|---|---|---|---|
| **The board** — display, names, ranks, every numeral, agate | **IBM Plex Sans Condensed** | SemiBold 600, Bold 700 | **BUNDLED** — 2 static TTFs | ~124 KB each ≈ **248 KB**. OFL 1.1 (Bold Monday for IBM). PostScript names `IBMPlexSansCondensed-SemiBold`, `IBMPlexSansCondensed-Bold` |
| **The record** — columns of figures, codes, handles, times | **IBM Plex Mono** | Regular 400, Medium 500 | already bundled | already paid. OFL 1.1 |
| **Now** — prose, standfirsts, controls, inputs | **SF Pro Text / Display** | 400, 600 | system (`Font.system`) | — |
| **Memory** — one sentence a surface | **New York** (Apple's system serif) | Regular 400, Bold 700 | system (`Font.system(design: .serif)`) — four optical masters, chosen automatically by point size | — |

**Three families, and the fence is answered rather than dodged.** `brand-canon` §4 says "no fourth
family, ever". The families here are **IBM Plex** (two cuts of one superfamily, by the same designers
on the same skeleton), **SF Pro** and **New York**. That is three, and it is three only because
**Charter is retired** — which also removes the last face addressed by PostScript string that is not
bundled by us. The craft judge's rejection was of bundling a condensed face *while keeping Charter by
string*; retiring Charter answers both halves.

**Why a condensed grotesk at all.** §5 of the brief says typography must carry a significant portion
of the brand, and the audit's finding 7 is that one tap below a tab root the product is
typographically a stock iOS app on a green ground. Two system faces cannot fix that. Plex Sans
Condensed at Bold in caps is authoritative and engineered — a scoreboard, not a shout — it fits two
digits into a 44pt rail at 27pt without tracking games, and its SemiBold sets agate that is denser and
warmer than SF Condensed.

**Alternatives considered and rejected**: SF Pro `.width(.condensed)` (free, but it is Apple's voice
and the fix cannot be another system face); Oswald / Bebas Neue (one weight, poster-generic);
Archivo Narrow (not narrow enough for a scoreboard numeral); Big Shoulders (reads civic-poster).

**The bundling risk, and the fallback.** D258 is exactly this bug: `"IBMPlexMono"` is a name none of
the three bundled files carries, so 296 sites rendered in SF Pro for weeks. Therefore: the two
PostScript names live in **one constant**, a preflight check asserts each resolves to a non-system
face at launch, and no other file may name a face by string (§17, `LINT-01` and `LINT-02`). **If
bundling is refused**, the fallback is `Font.system(…, design: .default).width(.condensed)` at the
same point sizes: every layout in this document holds, the voice is weaker, and nothing else changes.
The identity does not depend on the bundle, because the signature is the rail, the rule-and-figure and
the ink scorecard, not the face.

## 1.2 The roles — nine, against the shipped eighteen

Sizes are the **default** Dynamic Type size in points. Every role names a text style, so Dynamic Type
works end to end; growth caps are `@ScaledMetric` ceilings and exist only where a 190pt headline would
break the measure. Leading is a multiplier of point size and **every role declares one** — none of the
shipped eighteen does.

| Role | **Swift symbol** | Face | pt | Weight | Tracking | Case | Leading | `relativeTo:` | Cap |
|---|---|---|---|---|---|---|---|---|---|
| **`figure`** | `CSType.figureXL` / `.figureL` / `.figureM` / `.figureS` | Plex Cond Bold, **tabular** | **56 · 40 · 27 · 20** | 700 | `flat` 0 | — | 0.92 / 0.94 / 0.96 / 1.00 | `.largeTitle` / `.largeTitle` / `.title` / `.title3` | ×1.5 · ×1.5 · **×1.45** · none |
| **`display`** | `CSType.display` / `.displayS` | Plex Cond Bold | **34 · 24** | 700 | `caps` +0.5% at 34, +1% at 24 | UPPER | 0.98 / 1.05 | `.largeTitle` / `.title2` | ×1.6 / ×1.8 |
| **`name`** | `CSType.name` / `.nameS` | Plex Cond SemiBold | **17 · 15** | 600 | `caps` +3.5% / +4% | UPPER | 1.16 | `.headline` / `.subheadline` | none |
| **`social`** | `CSType.social` | Plex Cond SemiBold | **17** | 600 | `flat` 0 | Title Case | 1.16 | `.headline` | none |
| **`lead`** | `CSType.lead` | New York Bold | **28** | 700 | `tight` −1% | Sentence | 1.14 | `.title1` | ×1.5 |
| **`story`** | `CSType.story` | New York Regular | **20** | 400 | `flat` 0 | Sentence | 1.34 | `.title3` | ×1.6 |
| **`body`** | `CSType.body` / `.bodyS` | SF Pro Text | **17 · 15** | 400 (600 for buttons) | `flat` 0 | Sentence | 1.45 | `.body` / `.subheadline` | none |
| **`agate`** | `CSType.agate` / `.agateS` | Plex Cond SemiBold | **12 · 11** | 600 | `agate` +9% / +8% | UPPER *(or Sentence — §1.3)* | 1.20 | `.caption1` / `.caption2`, **both floored at 11pt** | **×2.2** |
| **`column`** | `CSType.column` / `.columnM` / `.columnS` | Plex Mono | **17 · 14 · 12**, tabular at 14 and 12 | 500 (400 at 12) | −1% at 14, 0 elsewhere | — | 1.30 / 1.25 / 1.20 | `.body` / `.subheadline` / `.caption1` floored at 11 | none |

**These fourteen symbols are the whole public API of `CSType`, and no surface spec may name a size
that is not one of them.** (`title` 24 is `displayS`; the surface specs' shorthand `figS`/`figM`/
`figXL`/`colS`/`col`/`nameS`/`agateS`/`bodyS` map onto this column one-for-one.) A role that is not in
this table does not exist, which is what lets `LINT-16` carve `displayS` out by name rather than by
point size.

**Three caps, and the mechanism, because `Font.custom(_:size:relativeTo:)` offers no ceiling.**
`figure`, `display` and `agate` are the only capped roles. A capped role is built as: read
`@Environment(\.dynamicTypeSize)`, compute `min(UIFontMetrics(forTextStyle: style).scaledValue(for: base), base * cap)`,
and pass that to `Font.custom(_:fixedSize:)`, re-reading on every `dynamicTypeSize` change. Every other
role uses `relativeTo:` and never caps. Without this stated, Phase 3 either drops the caps or loses
Dynamic Type on the two roles that carry the identity.

**`figure` 27's cap is ×1.45 and the arithmetic is why.** Two tabular digits of Plex Sans Condensed
Bold measure **1.080 em**. At ×1.7 the numeral reaches 45.9pt and two digits are 49.6pt — 5.6pt wider
than the 44pt rail, so §9.1's centred rank overflows between AX1 and AX2. At ×1.45 the numeral reaches
39.1pt and two digits are **42.3pt**, which fits with 0.85pt each side. The rail keeps its width; the
row keeps its height by growing intrinsically. (§9.1, §16.3.)

**`agate`'s cap is ×2.2 — 11pt → 24.2pt — and it is the only cap on a role that is not display-scale.**
`agate` is a *label*, not a sentence: it names a column, a unit, a date or a section. At AX3 an uncapped
`agate` reaches 33pt, and §1.5's licensed lines then spend ~260pt of an 874pt frame on labels before a
word of content. Capping the label costs a golfer nothing they read for meaning, and it is what makes
§16.3's masthead and slat rows hold. *(This is the one Dynamic Type exception the system takes, and it
is stated rather than discovered.)*

**Tracking values are RATIOS of the rendered point size, not lengths.** `.tracking()` takes absolute
points and does not scale, so a role computes
`UIFontMetrics(forTextStyle: style).scaledValue(for: basePt) * ratio` and passes the product. Stored in
`tokens.json` the four `track` values are bare numbers (0, −0.01, 0.035, 0.09); on the web they are `em`.
`LINT-07` permits exactly one `.tracking(` call site — `CSType`'s own computed one.

**Nine roles, four tracking values, one floor.** Tracking is a token (`flat` 0 · `tight` −0.01em ·
`caps` +0.035em · `agate` +0.09em) against the shipped **17 values across 175 hand-set sites**;
preflight fails a numeric literal in a `.tracking()` position. Nothing renders below **11pt** at the
default size.

**Target distribution**, against the shipped mono 55% / sans 38% / serif 8%:
**board ≈ 46% · sans ≈ 38% · mono ≈ 12% · serif ≈ 4%.**

## 1.3 Case, and the fences

- **Caps are legal in exactly five places**: `display`, `name`, `agate`, a chip label, a button label.
- **Anything a person could read aloud as a sentence is sentence case** — `lead`, `story`, `body`,
  standfirsts, empty-state lines, errors, captions, inputs, toasts, feed sentences, VoiceOver strings.
  This is what keeps a condensed direction readable at AX3 and keeps the voice conversational.
- **A person's name is caps only on the board** — a ranked row, a title, the credential, the field
  rail. Everywhere else it is `social`, title case. *Case is a hierarchy signal on a social product
  and is spent, not defaulted.*
- **Uppercase is produced one way only**: the role applies `.textCase(.uppercase)`.
  `.uppercased()` on a string is a lint failure — it breaks VoiceOver and localisation. (The shipped
  product produces the same label three ways.)
- **Never mixed case inside a tracked line.**
- **`agate` has one case switch, and it is the same test.** `agate` sets caps for a *label* — an
  eyebrow, a dateline, a section head, a column head, the unit beneath a figure, a chip, a tab. It sets
  **sentence case** for anything that is a *phrase a person could read aloud*: a slat's sub-line
  (*"3 rounds · held"*, *"1 of 4 counting · one short"*), a door's gloss (*"One you already played"*), a
  credit line, a state clause. Same face, same size, same tracking, same colour — the case is the only
  difference, and it is what keeps the caps voice meaningful once §1.5's budget counts lines rather than
  blocks. A capped phrase also loses word shape, which costs most in glare and with age; a label has no
  word shape to lose.

## 1.4 Where each face may not go

| Face | Forbidden |
|---|---|
| **Plex Sans Condensed** | any prose block over two lines · any body copy · any paragraph · any input value that is a sentence. It sets things that are *named*, never things that are *said*. |
| **Plex Mono** | any sentence with a verb · any string over six words · any eyebrow · any section label · any button label · any input except a code, a handle, a time or a score. *(This settles audit D3: mono keeps the scorer's tent; sans takes email, name and search.)* |
| **SF Pro** | any number that matters · any rank · any title · any section label. SF is the workhorse and never the voice. |
| **New York** | any control · any label · any number · any list row · anything that repeats on a screen. **One appearance per viewport, maximum** — the one sentence the screen wants a reader to slow down for. |

## 1.5 The agate budget, with a counting rule

**At most TEN tracked-caps agate LINES per viewport, and the count includes everything.**

The first draft of this rule budgeted four *blocks* and exempted unit labels, slat sub-lines, chip
labels, button labels and column-head rows — which is exactly where the density lives, so the artboards
carried 15 to 29 agate spans against a stated budget of four and four surface specs filed a deviation
saying the budget could not be held. **A budget that does not count what is on screen is not a budget.**

| Counts as one line | Does not count |
|---|---|
| every rendered line set in `agate` or `agateS` **in caps** — eyebrow, dateline, section head, column head, unit label beneath a figure, chip label, button label, slat sub-line, door gloss, folio, credit | an `agate` line set in **sentence case** (§1.3) — it is a phrase, not a label, and it does not read as the metadata voice |
| a wrapped label counts once per rendered line | the **tab band's five labels** — chrome, counted once product-wide |
| | text inside a photograph the golfer supplied |

Ten is the number because the two densest artboards that read well (`home-live`, `season-top`) sit at
nine and ten once the sentence-case sibling absorbs the phrases; every artboard above fourteen reads as
a spreadsheet. `LINT-15` cannot count this with a grep (a viewport is assembled from a dozen files), so
it is a **render-time probe** — see §17.

**And one `display` per viewport.** The screen's name is set once. `displayS` is not `display` and does
not count against it (a page header may set a club in `display` 34 and a course in `displayS` 24).

**And one `display` per viewport.** The screen's name is set once.

## 1.6 How a 74, a rank and an HCP are set

| Object | Setting | Never |
|---|---|---|
| **A gross (74)** | `figure` at 56 (the composer, the ceremony), 40 (a hero, a block), 27 (a row's figure, a panel), 20 (a column value). A figure at 27 or above **carries a rule-and-figure**: 2pt rule, agate label beneath. | inside a sentence in the sentence's own face; in `body`; in `mut` at 13pt |
| **A gross inside a sentence** | a **figure run** — the same board face at the sentence's own size and weight, so the number is always in the number's voice: "Best: **84**, Tash." **The producer names the run**; `CSFigureRun` takes a marked string (`"Galen shot {74} at Papago"`) or an `[NSRange]` beside it, never a regex over prose — a regex would also restyle dates, money, ordinals and any digit inside a course name, and would rewrite the `AttributedString` runs VoiceOver reads | set in New York or SF like the words around it; **discovered by scanning the sentence for digits** |
| **A rank (2nd)** | in a list: `figure` 27, tabular, centred in the 44pt rail, ordinal suffix omitted (`01`, `02` — two digits, leading zero). As a hero: `figure` 40–56 with the ordinal rider at **`max(11, numeral × 0.4)`, uppercase** — a floor, not a ratio, because 40% of `figure` 20 is 8pt and §16.2's floor is 11 — in a **panel**, with `OF EIGHT` in agate beneath. **In a column the rider is dropped entirely** (the column head already says `FINISH`), exactly as the rail drops it for `01` / `02`. | as an 11pt tracked-caps label under a flag glyph (the shipped answer) |
| **An HCP (10.6)** | always a rule-and-figure at 40 (a hero) or 27 (a strip cell), with `HANDICAP INDEX` or `YOUR NUMBER` in agate. The `STARTER` and `BUILDING` states are the **label**, never the value; the value slot never renders a dash or a guess. | inside a sentence; as a caption; beside a signed delta |
| **A points total (19)** | `figure` 27, tabular, right-flush in its column; **gold only for the leader**. | any colour for anyone else |
| **A money figure ($480)** | `figure` at its tier in **ink**; gold only when it is the pot or a thing won; the sign is a **word** in agate. | `pos` green or `neg` red, anywhere, ever |

---

## 1.7 The ordinal, frozen — one form, product-wide

**REVISED after the blind review.** Two reviewers found the ordinal suffix set three ways on one
surface — `2ND` as an agate small cap, `2nd` as a raised lowercase superscript, and `5th` — and one
called the raised form "three glyph systems in the cell with the smallest label".

**There is one ordinal.** The suffix is `board` 700, **uppercase**, at **0.44–0.46 em** of the figure
it follows, letter-spaced `.05em`, **sitting on the baseline** with a 0.05 em left sidebearing. It is
never raised, never lowercase, never italic, and never a `<sup>`. It applies wherever an ordinal is
set: the rank chip, the credential's third rail cell, the record table's FINISH column, and the
leaderboard's rail (which prints `01`, not `1ST`, and so never uses it).

The raised form was chosen for typographic correctness in print and it is wrong here: at the sizes
this product sets ordinals — 38pt in the chip, 27pt in the rail, 20pt in a cream table — a raised
suffix collides with the row above and reads as a footnote marker beside a number that is not a
footnote. On the baseline it reads as part of the figure, which is what it is.

---

# 2 · COLOUR

Two printings of one page: **the room at dusk** (dark, the default) and **the morning tee sheet**
(light, warm almanac stock). Every value is a token in `packages/tokens/tokens.json`; nothing is
invented in Swift (preflight check 15 already fails an invented hex). Every ratio below is WCAG,
computed by `system-mockups/contrast.mjs` from these hexes.

## 2.1 The full palette

| Token | Dark | Light | Job |
|---|---|---|---|
| `bg0` | `#0F1A15` | `#F4F1E9` | **the page.** Fescue green-black / warm almanac stock |
| `bg1` | `#1A2620` | `#EAE6DB` | **the band** — a full-bleed tone field. Never a card |
| `bg2` | `#26352E` | `#DED8C8` | **the block** — chips, fields, quiet buttons, the face disc, redacted type |
| `rule` | `#4A6155` | `#A9A08A` | **the only hairline**, 1px, and the section rule |
| `ink` | `#F1F4EF` | `#151B17` | primary text; the 2pt heavy rule |
| `mut` | `#9BA69D` | `#575F57` | secondary text — **the only secondary tier** |
| `dim` | `#5E6A62` | `#8B9089` | **non-text only**: unfilled ticks, disabled glyphs, watermarks. **Never a word** (§16.1) |
| `panel` | `#E9ECE3` | `#141A16` | the panel's fill — **always the opposite of the page** |
| `panelInk` | `#0B120E` | `#F4F1E9` | ink on the panel |
| `panelMut` | `#4C574F` | `#A6AEA5` | the panel's unit label |
| `leaf` | `#EFEADD` | `#FCFAF3` | scorecard paper — warm, and it does **not** invert |
| `leafInk` | `#1A1B14` | `#1A1B14` | wood ink on paper |
| `leafMut` | `#57605A` | `#5A625A` | the leaf's column heads and hole numbers |
| `ceremony` | `#0A0E0C` | `#0A0E0C` | the ceremony ground — a physical object, the same in every theme |
| `ceremonyInk` | `#F1F4EF` | `#F1F4EF` | ink on the ceremony ground, in every theme (17.51:1) |
| `ceremonyMut` | `#9BA69D` | `#9BA69D` | the ceremony object's secondary tier — **7.71:1 in both themes** |
| `ceremonyBrand` | `#E8622C` | `#E8622C` | ember **on a physical object** — 5.75:1 in both themes |
| `ceremonyGold` | `#D8B25A` | `#D8B25A` | champagne **on a physical object** — 9.65:1 in both themes |
| `ceremonyPos` | `#4EC584` | `#4EC584` | 8.92:1 both · `ceremonyCool` `#7F8C95` 5.63:1 both |
| `ceremonySq0–3` | the dark `sq0–sq3` | same | squad marks on a physical object |
| `crest` | `#33463B` | `#33463B` | the credential's embossed marker (§6.5), on the ceremony ground only |
| `folioRule` | `#8B8F8B` | `#8B8F8B` | the folio's ink — the opaque value `ceremonyInk` at `a56` composites to; **5.92:1** |
| `scrimInk` / `scrimMut` | `#F1F4EF` / `#CBD2C8` | same | the two constants copy takes **over a photograph**, in both themes (`PhotoScrimTests` holds them) |
| `brand` (ember) | `#E8622C` | `#A8420F` | **LIVE**, and the one primary action |
| `gold` (champagne) | `#D8B25A` | `#7A5A12` | **EARNED**, once per viewport |
| `pos` | `#4EC584` | `#0B7340` | movement up · performance up |
| `neg` | `#FF6A5E` | `#B02A20` | a genuinely negative state: an error, a destructive arm, a signed over-par figure inside a receipt |
| `cool` | `#7F8C95` | `#5D6862` | movement down · cooled. Slate, never alarm |
| `sq0–sq3` | `#366F87` `#B27E7C` `#97B999` `#EDD4FA` | `#002B40` `#603E35` `#4C705D` `#8B88A8` | squads — slate · clay · moss · lilac. A rule or a swatch, **never text, never a disc tint**, and **never without the squad's name** (§16.4) |
| `pig0–pig5` | `#492D2C` `#473C28` `#293B2B` `#1F4648` `#293B4E` `#4E3C4F` | `#FDDAD8` `#E6D8C2` `#D6EBD7` `#BEE4E7` `#D9EAFF` `#EED9EE` | the six disc pigments — clay · ochre · moss · slate · indigo · plum. **Six hues 60° apart at fixed chroma** (C\* 14 dark / 13 light) across a 6-point L\* band (§2.2a) |

**Alphas — five, replacing 35 literals across 125 sites:** `a08` `a16` `a24` `a56` `a88`. Anything
else is a lint failure.

## 2.2 The ground, decided once

`bg0` dark `#0F1A15` is **ΔE 10.28 from pure black** at chroma 6.35 — against the shipped `#0B1410`'s
ΔE 6.88 at chroma 4.14, which the audit measured as less separation from black than Home's lead card
had from its deck card. The cast is nameable now: it is a green-black, and it is the same colour
behind the status bar as behind the content, because **`CSLookSky`'s accent wash over the top 260pt is
deleted** (audit F-04: the product ships two grounds with a soft seam, and the band the system clock
sits in is a different product colour from the screen under it). One ground, painted once, on every
root — which also kills the visible colour jump when tabbing between roots (F-05).

## 2.2a The pigments and the squad marks, derived rather than picked

The first draft of both sets was hand-picked and did not survive measurement: the light pigments had a
minimum pairwise **ΔE76 of 2.66** with ten of fifteen pairs under 10.28 — below the very number §2.2
uses to reject the shipped ground as "not nameable" — so `event-light`'s four discs read as one disc.
Both sets are now **derived, and the derivation is the token note**, so a future re-hue is testable.

| Set | Rule | Measured |
|---|---|---|
| **`pig0–pig5`** | six hues **60° apart** (25° · 85° · 145° · 205° · 265° · 325°) at a fixed chroma — C\* 14 dark, C\* 13 light — across a 6-point L\* band (22–28 dark, 87–92 light) | **minimum pairwise ΔE76 13.86 dark / 12.72 light**, zero pairs under 10. `ink` on any pigment **9.09–11.17 / 12.46–14.29**; `mut` on any pigment **4.00–4.92 / 4.71–5.40** |
| **`sq0–sq3`** | a **lightness ladder**: four hues (250° · 35° · 155° · 300°) placed at L\* 44/58/72/88 dark and 16/30/44/58 light, so the four are separable **in greyscale** | **minimum pairwise 1.58:1 in both themes**; each mark **3.01–13.11:1 against its own ground** |

**The squad ladder stops at 1.58:1 and the arithmetic says why.** Four marks that each keep 3:1 against
the ground leave a luminance window in which a pairwise 2.0:1 ladder does not fit: 3:1 on `bg0` dark
sets the darkest mark's relative luminance at 0.11 and 2.0:1 three times over would demand 0.92, which
admits no chroma at all. **1.58:1 is the achievable ceiling and it is a visible greyscale step** — but
it is *not* enough on its own, which is why §16.4 makes the squad's **name in agate** mandatory beside
every swatch and why the event's field rail is drawn as two named groups rather than one row of six
discs. Colour ranks the squads; the word names them.

## 2.3 The light theme is a second printing, not an inversion

The shipped light palette put `pos` 4.87, `neg` 4.90, `gold` 4.88 and `brand` 4.88 on `bg0` — a spread
of **0.03**, because a test optimised all four to a 4.5:1 floor, so nothing outranked anything (F-03).
Here the paper is warm (`#F4F1E9`), gold is a **bronze** that reads engraved rather than muddy, ember
is a **stamp red-orange**, and the panel **inverts to ink** — which is the light theme's whole idea and
a real design rather than a translation. The contrast spread is 5.14–5.85 and, more to the point, the
four hues are 40°+ apart, which is what the eye actually sorts on.

## 2.4 The two metals, restated and now enforceable

> **Ember means LIVE. Champagne gold means EARNED. They are never swapped, and neither is ever chrome.**

**Ember has exactly two jobs**: (a) *live* — the live dot, the live eyebrow, the current week's tick,
the focus ring, the Play glyph; and (b) *the one primary action on the screen*, which is the live thing
you can do now. A screen whose primary is not live (a settings save, a share) uses **secondary**, and
nothing on that screen is ember. That is the mechanism: it is not a rule about colour, it is a rule
about how many live actions a screen may have, which is one.

**Ember is removed from** toolbar buttons, chevrons, status text, selected chips, DatePicker and
ProgressView tints, step dots, hole dots, the tab-bar fill and the ⊕ disc — 141 sites doing nine jobs
become two.

**Gold has one job and a hard budget**: **at most one gold object per viewport**, and only on
something that was won — the leader's rail field, the pot figure, a trophy, the FOUNDER slot, the best
of the last five, the rule under an earned figure. **The budget counts hue, not token name**: there is
no amber in the palette, so a second warm-yellow object cannot enter under another name.

**Gold marks a thing that was WON, and an average is not won.** A course's community star rating, a
mean, a count, a "notable" number and any figure the design merely wants to emphasise are `ink`. This
is the clause the first draft was missing, and without it gold walked straight back onto the most
repeated object in the product (every course row, every discovery item, every course page). Emphasis
has somewhere else to go now — the display tier and the 2pt rule — which is the whole reason the
two-metal rule became enforceable in the first place (§0.3). **The gold list is closed**: the pot · a
prize · a won or podium finish · the leader's rail field · an earned slot (`FOUNDER`, `CHAMPION`,
`THE PRO`) · the best of the last five · the 2pt rule under an earned figure. Nothing else.

**Two shapes gold may take, and two it may not.** It may be **ink on a numeral**, a **2pt rule**, a
**rail field** (with `panelInk` numerals, 9.43:1) or a **slot** (a 24pt gold field with `panelInk`
agate). It may **never** be a large fill behind a figure (at rendered scale that is a mud-brown button
that makes an earned result look tappable), and it may **never touch a control** — no gold button, no
gold tab, no gold nav. `CSButtonStyle.gold` is deleted from `CSDesign`, not merely audited: a style
whose only correct number of uses is zero is not a style.

**Gold never sets type on bone.** `gold` on `panel` is **1.68:1** in dark. On a panel or a leaf, an
earned figure is marked by the **2pt gold rule beneath it**, never by gold ink — which is the
rule-and-figure doing the work it was designed for. (Visible on `cs-profile`: the leaf's record table
marks `2ND` and `WON` with a gold rule.)

**And no saturated field wider than a chip may carry a label.** That is the rule that forbids the
ember LIVE band: the largest ember object in the product is a 50pt primary button, and the largest
gold object is a 44×50 rail field.

## 2.5 Semantics, links, money

- **`pos` / `neg` are performance and state, never money.** `pos` is movement up and a genuinely
  better figure; `neg` is an error, a destructive arm, and a signed over-par figure *inside a receipt*
  (`COMPONENT_SYSTEM` AP-2's one carve-out). `cool` is movement down and cooling — slate, never red.
- **Money is ink.** The figure is `ink` (or `gold` when it is the pot or a thing won); **the sign is a
  word in agate** — `YOU OWE` · `YOU'RE OWED` · `SETTLED`; and **the ledger line renders verbatim from
  one constant** (`CS_LEDGER` / `MoneyCopy.ledger`) in `body` 15 at `mut` under every surface that
  shows a money figure. A red/green P&L axis is the grammar of a brokerage; a word and one metal is
  the anti-fintech answer, and it makes the ledger line's promise visually true.
- **Links are underlined ink, and the rule's colour says what kind of link it is.** `name` 15 in `ink`,
  44pt target, always with a rule beneath — underlined ink at 16.05:1 is more visible than 7.31:1 blue
  text and the signal is a *shape* rather than a hue, so it survives colour blindness. `dawn` is
  deleted. **Three rules, one shape** (the full table is §7.1):
  **2px `brand`** only when the link *is* the screen's one live action · **2px `mut`** for every other
  link in content · **1px `mut`** for a link in a toolbar. A dismiss verb, a Settings link and a Share
  link are neither live nor primary and **never take a metal** — otherwise "gold is never chrome" is
  half a law, and the four screens whose only ember was the word `CLOSE` prove the other half matters.
  No underline ever drops below 3:1 against its ground (`mut` is 7.07 / 5.85), because when the
  underline *is* the affordance, taking it below 3:1 does not make the control quiet — it makes it stop
  being a control.
- **Squad colour is a rule or a swatch, never text and never a disc tint.** Three of four squad hues
  fail AA as text in light; and the disc's identity job belongs to the pigments (§6.2).

## 2.6 The heat axis, collapsed

`warm`, `hot`, `fire` and `focus` are **deleted**. A clock that is running is `brand`; one that is not
is `ink` or `mut`. `cool` survives for falling. The Forge's heat ramp (warm → hot → fire → ink) is an
*illustration*, not a state, and survives as three private constants inside `ForgeView`, so the door
is unchanged and the palette loses three tokens. The focus ring becomes `brand` at 2px — removing the
fourth warm hue the audit found (three oranges within ΔE of each other, and the brightest one meant
"your cursor is here").

## 2.7 The looks, given a job and a fence

A season's `look` (Azaleas, Cup Final, The Wrap…) tints **the rail and the eyebrow, and nothing else**
— never a ground, never ink, never `pos`/`neg`, never a squad, never gold. That is the first defined
job the looks have had, and it makes the Cup Final's ember rail and the Wrap's gold rail a real
seasonal signal at zero palette risk. Their `motif` field currently holds emoji; each becomes the name
of a drawn glyph in the icon family (§5).

## 2.8 The contrast table

Every text/ground pair this system defines. **Bold** = the pairs that carry running text.

| Foreground | on `bg0` dark | `bg1` | `bg2` | on `bg0` light | `bg1` | `bg2` |
|---|--:|--:|--:|--:|--:|--:|
| **`ink`** | **16.05** | 14.10 | 11.60 | **15.49** | 14.02 | 12.29 |
| **`mut`** | **7.07** | 6.21 | 5.11 | **5.85** | 5.30 | 4.64 |
| `dim` *(non-text)* | 3.15 | 2.77 | 2.28 | 2.89 | 2.61 | 2.29 |
| `rule` *(non-text)* | 2.66 | 2.33 | 1.92 | 2.30 | 2.08 | 1.83 |
| **`brand`** | **5.27** | 4.63 | 3.81 ✗ | **5.39** | 4.88 | 4.28 ✗ |
| **`gold`** | **8.85** | 7.78 | 6.40 | **5.64** | 5.11 | 4.48 ✗ |
| **`pos`** | **8.18** | 7.19 | 5.91 | **5.25** | 4.76 | 4.17 ✗ |
| **`neg`** | **6.34** | 5.57 | 4.58 | **5.82** | 5.27 | 4.62 |
| **`cool`** | **5.16** | 4.54 | 3.73 ✗ | **5.14** | 4.65 | 4.08 ✗ |
| `sq0 / sq1 / sq2 / sq3` *(non-text)* | 3.21 / 5.23 / 8.24 / 13.06 | | | 13.11 / 8.31 / 4.92 / 3.01 | | |
| `panel` | 14.91 | 13.09 | 10.77 | 15.65 | 14.16 | 12.41 |

✗ = **not legal as text on that ground.** `brand`, `cool`, `gold` and `pos` may sit on `bg2` only as a
fill, a rule or a glyph with an accessibility label — never as a word. This is a rule the preflight
cannot see, so it is a review item and it is written into §16.1.

| Pair | Dark | Light |
|---|--:|--:|
| `panelInk` on `panel` | 15.87 | 15.65 |
| `panelMut` on `panel` | 6.31 | 7.75 |
| `leafInk` on `leaf` | 14.44 | 16.61 |
| `leafMut` on `leaf` | 5.42 | 6.04 |
| `bg0` on `brand` *(the primary button's label)* | 5.27 | 5.39 |
| `panelInk` on `gold` *(the leader's rail, the slot)* | 9.43 | 5.64 |
| `ceremonyInk` on `ceremony` | 17.51 | 17.51 |
| `mut` on any pigment | 4.00 – 4.92 | 4.71 – 5.40 |
| `ink` on any pigment | 9.09 – 11.17 | 12.46 – 14.29 |
| `mut` on `leaf` | 5.50 | 6.49 |
| `leafInk` on `leaf` light `#FFFDF7` | — | 17.05 |

**The ceremony ground has its own ramp, and it does not switch with the room.** The first draft pinned
only `ceremony` and `ceremonyInk` across themes and let every other token switch, which put the
credential's `FOUNDER` slot at **3.05:1**, the event's LIVE eyebrow at **3.19:1** and the event's
dateline — the surface's whole identity block — at **2.94:1** in the light theme, while the mockups
quietly painted the dark-room values a token could not produce. §2.8's first draft also printed 9.65 in
both columns for `gold` on `ceremony`, which was simply false.

> **On the `ceremony` ground every token resolves to its dark value. The light theme does not reach
> inside a physical object.** A card in your hand is the same card in either room; that was already the
> argument for `ceremony` and `ceremonyInk`, and it is the same argument for the six that were missed.

| On `ceremony`, both themes | Ratio |
|---|--:|
| `ceremonyInk` `#F1F4EF` | **17.51** |
| `ceremonyGold` `#D8B25A` | **9.65** |
| `ceremonyPos` `#4EC584` | **8.92** |
| `ceremonyMut` `#9BA69D` | **7.71** |
| `folioRule` `#8B8F8B` *(the opaque `a56` value)* | **5.92** |
| `ceremonyBrand` `#E8622C` | **5.75** |
| `ceremonyCool` `#7F8C95` | **5.63** |
| `ceremonySq0–3` | 3.21 / 5.23 / 8.24 / 13.06 |
| `crest` `#33463B` *(non-text, an emboss)* | 1.92 |

*(For the record, and so nobody re-derives them: the theme-switching tokens on `ceremony` in **light**
measure `gold` 3.05 · `brand` 3.19 · `mut` 2.94 · `pos` 3.28 · `cool` 3.35 · `sq0–3` 3.06–3.47. Every
one of them is why the ramp exists. `event.md`'s `cerMut` is this table's `ceremonyMut`; the name
`cerMut` is struck.)*

## 2.9 The `tokens.json` diff the build must make

Swift is generated from this file by `tools/build-tokens.mjs`; the web reads the same values. Preflight
10 fails if `index.html` and `tokens.json` disagree, so **both clients change together**.

> **The diff touches four files, not one, and the emitter is one of them.** The first command of Phase 3
> — edit `tokens.json`, run `node tools/build-tokens.mjs` — **throws** as this document stands, because
> the Swift emitter does an unguarded `entries.find(([, n]) => n === 'glow')[2].dark`
> (`tools/build-tokens.mjs:118-119`) and the same for `grad`, both of which §2.9 deletes. `TypeError:
> Cannot read properties of undefined` means `tokens.css`, `tokens.ts`, `Tokens.swift` and `Looks.swift`
> are never regenerated and preflight 10 then fails permanently with "generated tokens are stale" — and
> nothing else in Phase 3 can start. **In the same change:**
>
> 1. **`tools/build-tokens.mjs`** — delete the `glow` / `gradStops` emitter block and the two
>    `CSTokens.glow` / `CSTokens.gradStops` call sites (or guard both `find`s).
> 2. **`tools/build-tokens.mjs`** — add three emitter blocks beside `Radius`: `public enum Space`,
>    `public enum Alpha`, `public enum Track`. The emitter today walks `colorTokens` (anything whose
>    value is a `#rrggbb`) and then four groups **by name** — `radius`, `type`, `motion`, `shadow` — so
>    `space`, `alpha` and `track` reach `tokens.css` and `tokens.ts` and are **silently dropped from
>    `Tokens.swift`**. Without them there is no `CSTokens.Space.s4`, no `Alpha.a56` and no
>    `Track.agate` on the phone, and `LINT-06` and `LINT-07` have no set to compare against.
> 3. **The stored shape**, because preflight 10 compares the stored string to `index.html`'s CSS
>    declaration byte for byte: `space` values are stored as **`"20px"`**, `alpha` as a **bare number**
>    (`0.56`), `track` as a **bare number** (`0.09`) — a ratio, not a length (§1.2).
> 4. **`index.html:36`** — the web loads its bundled face from one Google Fonts link
>    (`family=IBM+Plex+Mono:wght@400;500;600`). `type.board` is a **CSS stack**, and a stack does not
>    load a face, so the desk would silently render 46% of its type in `system-ui` — D258's exact
>    failure mode, on the client D234 calls half the product. The href becomes
>    `family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans+Condensed:wght@600;700`
>    (`netlify.toml:30`'s CSP already allows `font-src https://fonts.gstatic.com`).
> 5. **`apps/ios/project.yml:92` and `apps/ios/CupSeason/Info.plist:53`** — both carry the `UIAppFonts`
>    list and **both** need the two new TTFs. One without the other is D258 again.

**Changed**

| Token | Dark: from → to | Light: from → to |
|---|---|---|
| `ground.bg0` | `#0B1410` → `#0F1A15` | `#EFF2EE` → `#F4F1E9` |
| `ground.bg1` | `#131D17` → `#1A2620` | `#FBFCFA` → `#EAE6DB` |
| `ground.bg2` | `#1A2820` → `#26352E` | `#E5EAE4` → `#DED8C8` |
| `ground.line` → **renamed `ground.rule`** | `#24352B` → `#4A6155` | `#D9DFD7` → `#A9A08A` |
| `text.ink` | `#F0F2F3` → `#F1F4EF` | `#1A2620` → `#151B17` |
| `text.mut` | `#8E979E` → `#9BA69D` | `#52625A` → `#575F57` |
| `text.dim` | `#5C646B` → `#5E6A62` | `#8C9992` → `#8B9089` |
| `semantic.pos` | unchanged `#4EC584` | `#0B793F` → `#0B7340` |
| `semantic.neg` | `#FF5F56` → `#FF6A5E` | `#BE3831` → `#B02A20` |
| `metal.gold` | unchanged `#D8B25A` | `#846415` → `#7A5A12` |
| `metal.brand` | unchanged `#E8622C` | `#B3461C` → `#A8420F` |
| `heat.cool` → **moved to `semantic.cool`** | `#66707A` → `#7F8C95` | `#6E7A84` → `#5D6862` |
| `squad.sq0–sq3` | `#57A8FF` `#FB8B4B` `#A78BFA` `#2FD3BE` → `#366F87` `#B27E7C` `#97B999` `#EDD4FA` | `#2C7CD3` `#DE6A22` `#7A58DE` `#0D9E8F` → `#002B40` `#603E35` `#4C705D` `#8B88A8` |
| `pigment.pig0–pig5` | → `#492D2C` `#473C28` `#293B2B` `#1F4648` `#293B4E` `#4E3C4F` | → `#FDDAD8` `#E6D8C2` `#D6EBD7` `#BEE4E7` `#D9EAFF` `#EED9EE` |
| `type.serif` | `'Charter','Iowan Old Style',…` → `ui-serif, 'New York', 'Iowan Old Style', Georgia, serif` (iOS: `Font.system(design: .serif)`) | same |

**Added**

| Group | Tokens |
|---|---|
| `object` | `panel` `#E9ECE3`/`#141A16` · `panelInk` `#0B120E`/`#F4F1E9` · `panelMut` `#4C574F`/`#A6AEA5` · `leaf` `#EFEADD`/**`#FFFDF7`** · `leafInk` `#1A1B14`/`#1A1B14` · `leafMut` `#57605A`/`#5A625A` · `ceremony` `#0A0E0C` both · `ceremonyInk` `#F1F4EF` both |
| `object` *(the ceremony ramp — §2.8)* | `ceremonyMut` `#9BA69D` · `ceremonyBrand` `#E8622C` · `ceremonyGold` `#D8B25A` · `ceremonyPos` `#4EC584` · `ceremonyCool` `#7F8C95` · `ceremonySq0–3` = the dark `sq0–sq3`. **All pinned in both themes** |
| `object` *(named, so nothing is invented in Swift)* | `crest` `#33463B` both · `folioRule` `#8B8F8B` both · `scrimInk` `#F1F4EF` both · `scrimMut` `#CBD2C8` both. These are the five off-palette literals the surface specs had written into Swift (`#33463B`, `#2A3A32`, `#2C3B33`, `#CBD2C8`, `#D2D8CE`); they are **consolidated to four names**, so preflight 15 (a Swift hex must also appear in `index.html`) passes instead of failing on four surfaces |
| `pigment` | `pig0`–`pig5`, both themes, values in §2.1 |
| `space` | `s1` 4 · `s2` 8 · `s3` 12 · `s4` 20 · `s5` 32 · `s6` 52 · `gutter` 20 · `gutterDesk` 40 · `rail` 44 · `hair` 1 |
| `radius` | `p` 3 · `rx` 28 *(joining `r` 16, `rc` 10, `rs` 24)* |
| `alpha` | `a08` .08 · `a16` .16 · `a24` .24 · `a56` .56 · `a88` .88 |
| `track` | `flat` 0 · `tight` −0.01em · `caps` +0.035em · `agate` +0.09em |
| `type` | `board` — `'IBM Plex Sans Condensed', system-ui, sans-serif` *(and the Google Fonts href above — a stack is not a loader)* |
| `motion` | `snap` — `cubic-bezier(.2,0,0,1)` |
| `shadow` | `leaf-shade` — `0 1px 0 rgba(0,0,0,.22)` |

**Removed**

`ground.line2` (one hairline only) · `metal.dawn` (audit D5) · `metal.pine` (0 call sites) ·
`heat.warm` `heat.hot` `heat.fire` (§2.6) · `heat.focus` (the ring becomes `brand`) ·
`effect.glow` (1 site, decorative) · `effect.grad` (§4's named do-not, verbatim) ·
`shadow.shadow-rest` (0 references).

**Also**: every `looks[].motif` emoji becomes a drawn-glyph name; `looks[].accent`/`accent2` keep their
values and gain the fence in §2.7. `Surfaces.swift`'s ten hard-coded hexes on the finish ceremony and
the recap (including a green share button belonging to no palette and a second gold at ΔE 5.4) and the
trophy case's private colour family are **deleted**: those surfaces are `ceremony` + `ceremonyInk` +
`gold`, like everything else.

---

# 3 · SURFACES, ELEVATION AND CONTAINERS

## 3.1 The rule that replaces "card by default"

> **A container is allowed only when it has one of three jobs: it holds a single figure (the panel),
> it holds a printed grid (the leaf), or it is a physical artefact a golfer would keep (the object).
> Everything else is made of bands, rules, the rail and whitespace.**

That is the whole list. A paragraph never gets a container. A row never gets a container. A section
never gets a container — it gets a rule with its label sitting in the break. **338 hand-rolled
containers become four shapes**, and three of them have a test you can apply in one glance.

**No container may contain another container.** A panel may not hold a panel, a leaf or a plate; a
leaf may not hold a panel; an object may hold a plate and a rule and nothing else. Box-in-box is the
audit's problem 1 and §6 of the brief's explicit ban, and it is now unwritable (§17, `LINT-08`).

## 3.2 The panel

| | |
|---|---|
| **What it is** | a small opaque tile that holds **exactly one number or one word** |
| **Fill** | `panel` — bone on dark, ink on light. **Always the opposite of the page** (14.91:1 dark, 15.65:1 light) |
| **Size** | at most **96 × 96**; the common sizes are 96×96 (a hero), 64×64 (a row's figure), 64×38 (a word) |
| **Radius** | `p` 3 · **Border** never · **Shadow** never |
| **Contents** | one `figure`, with an optional agate unit label in `panelMut`; or one `name` word |
| **Budget** | **two per viewport** |
| **The tripwire** | *if it ever holds a sentence, it has become a card.* |

The panel is the depth the card never had, spent on the two objects a screen is actually about instead
of on every paragraph. Over a photograph the panel is **always the bone panel in both themes**, because
a photograph carries its own dusk and the light theme's ink panel would vanish into it. **The mechanism
is named, so Phase 3 does not reach for a literal**: `CSPanel(.overPhoto)` reads `CSTokens.dark.panel`
explicitly rather than the `\.cs` environment's palette. (Same for `CSLeaf.earnedRule`, §3.3.)

## 3.3 The leaf

| | |
|---|---|
| **What it is** | a sheet of scorecard paper set into the page |
| **Fill** | `leaf` — warm bone `#EFEADD` on dark, bright stock **`#FCFAF3` → `#FFFDF7`** on light. **It does not invert**: paper is paper in both rooms |
| **Ink** | `leafInk` (14.44 dark / **17.05** light), heads and hole numbers in `leafMut` (5.42 / 6.20). An **earned** figure on a leaf takes `CSLeaf.earnedRule` — the 2pt gold rule beneath it, reading `CSTokens.light.gold` explicitly in both themes, because gold ink on bone is 1.68:1 and forbidden (§2.4) |
| **Radius** | `p` 3 · **Shadow** `leaf-shade`, in **both** themes (one 1px bottom shade, because paper sits *on* something) · in **light** it also takes a **1px `mut` frame** (6.49:1 on the leaf), because a bright sheet on paper needs an edge and the first draft's 1px `rule` was **2.55:1 over a 1.11:1 tone step** — where a component's shape *is* its meaning ("this is a scorecard, set into the page"), WCAG 1.4.11 wants 3:1 on the boundary and a hairline at 2.55 delivers neither the shape nor the meaning |
| **Licensed for** | the front nine, the scorecard, a receipt, the settlement card, the season book page, the Record's table. **Nothing else.** |
| **The test** | *it must contain a grid.* A leaf that holds prose is a card. |

The leaf is the one material that is neither the ground nor a container-for-its-own-sake, and it is
what makes the archive surfaces feel printed rather than merely dim. It is also the cheapest
unmistakably-golf object in the system: one fill and one radius, and it says *scorecard* without a
golf-ball icon.

## 3.4 The object, the band, the rail, the rule, the plate

| Device | What it is | Radius | Border | Shadow |
|---|---|---|---|---|
| **The band** | a full-bleed tone field (`bg1`) or ceremony field. Runs edge to edge, so it can never read as a box | 0 | never | never |
| **The rule** | one hairline, `rule`, **1px**, full-bleed or inset to the measure; and the **2pt heavy rule** in `ink` under a figure or a masthead | — | — | — |
| **The rail** | the 44pt left column carrying rank; painted `gold` (earned), `panel` (yours), unpainted (everyone else) | 0 | never | never |
| **The panel** | §3.2 | `p` 3 | never | never |
| **The leaf** | §3.3 | `p` 3 | light only, 1px `rule` | `leaf-shade` |
| **The plate** | an image field: a photograph, a drawn card, a contour. Full-bleed (radius 0) or inset 3:2 (radius `p` 3) | 0 / 3 | never | never |
| **The object** | a thing: the credential, the settlement card, the trophy plate | `r` 16 | never | `shadow-lift` |
| **The sheet** | a presented modal | `rs` 24 (top corners) | never | `shadow-lift` |
| **Ceremony** | the takeover, the finish, the Forge | `rx` 28 | never | — |

**Radii: five values, five jobs** — `p` 3 · `rc` 10 (controls) · `r` 16 (objects) · `rs` 24 (sheets) ·
`rx` 28 (ceremony). 28 is promoted from the de-facto literal the audit identified as "the one off-token
radius doing deliberate expressive work". Preflight fails any `cornerRadius:` numeric literal, which is
what turns 91 off-token radii across 11 values into zero.

**Borders: none.** The system has **no border token**. The only outlines in the product are the focus
ring (`brand`, 2px, keyboard and Switch Control), the face disc's 1px inset ring (a ring on a circle,
not a box), the leaf's light-theme edge, and the drawn scorecard marks. `.stroke(` outside those four
is a lint failure.

**Shadows: two, and only one is elevation.** `shadow-lift` under an **object** or a presented sheet;
`leaf-shade` under a leaf. The shipped restraint here — nine shadow sites, none decorative — is a
"what works" and survives verbatim.

## 3.5 The ladder of tone, and why depth is not made of it

There is **no elevation ladder**, because tone cannot carry structure on a near-black ground and the
audit proved it: every structural device in the shipped app measures between 1.08:1 and 1.94:1, which
is not weak but absent. `bg1` sits 1.14:1 above the page here and is asked to do **no structural work
at all** — it is a band's tone, a redaction's fill, a disabled control's fill. Structure is carried by
the **rule at 2.66:1** (84% more separation than the shipped hairline) and the **panel at 14.91:1**.

And the depth model holds in both rooms, which is the test clubhouse's tone-step thesis failed: the
panel is 14.91:1 in dark and **15.65:1 in light**, because it inverts. A design whose depth is a tone
step is a design with no depth in light.

---

# 4 · SPACING

**Six steps on a ~1.6 ratio, plus three structural constants.** The audit's cleanest finding was 34
distinct values across 1,519 sites with no token at all — a de-facto 2pt grid, which is no grid.

| Token | pt | Used for |
|---|--:|---|
| `s1` | **4** | inside a chip · between a figure and its rule |
| `s2` | **8** | between a name and its sub-line · chip gutters · between a rule and its label |
| `s3` | **12** | inside a slat · between a rule and its first child · between the rail and the body |
| `s4` | **20** | between blocks inside a band · a band's own vertical padding · **the page gutter** |
| `s5` | **32** | between sections |
| `s6` | **52** | before a ceremony or a page foot |
| `gutter` | **20** | the page's side margin on the phone (`gutterDesk` 40) |
| `rail` | **44** | the rank rail; also the minimum touch target |
| `hair` | **1** | every rule |

**Three rules, all lintable.**

1. **No other number may appear in a `padding` or `spacing:` position.** Preflight fails a literal, the
   way check 15 fails an invented hex.
2. **The gap between two blocks is always ≥ the padding inside them** (`s4` outside, `s3` inside).
   Home currently ships the inversion — a 14pt inter-card gap against 16/18pt intra-card padding — which
   is why its deck reads as one grey mass.
3. **The measure is 362pt** at 402pt wide (`gutter` 20 each side). Everything hangs off the same left
   edge; nothing on a phone is ever indented from it except a table cell and the rail's body column,
   which starts at `rail` + `s3` = 56.

**Row heights.** A slat is **50pt** minimum at the default size; a compact row 44; a field 50; a
button 50; the tab band 74 + safe area.

---

# 5 · ICONOGRAPHY

## 5.1 The family

**One drawn family, at the markers' own stroke weight.** Every glyph the product draws — the fourteen
markers, the five tab glyphs, the movement triangles, the live dot, the star, the pennant, the
achievement marks, the empty-state objects, the scorecard rings and boxes — is drawn at **1.7pt on a
24×24 box**, `linecap`/`linejoin` round, `fill: none`, `currentColor`. Put a marker beside a tab glyph
and they are one hand; that is the test, and the shipped product fails it by 40pt (a filled SF mass
beside a 1.8pt hairline).

- **Sizes: four, from a token** — 13 (inline), 17 (row), 22 (tab, section), 28 (block). Empty-state
  objects are 56–76 and are the one exception, stated. *(The shipped product has 12+ size/weight pairs
  and no icon scale.)*
- **Tints: three** — `mut` at rest, `ink` when selected or primary, `panelInk`/`leafInk` inside a panel
  or a leaf. **Never a metal**, with exactly two exceptions, both of which mean something: the **⊕ Play
  glyph** (ember, because it *is* the live action) and the **medallion's marker** (gold, because it
  means "this is theirs").
**The tab bar set — five drawn glyphs, named**: `home` (a roofline), `pennant` (the Tracer's flag —
the product's one flag), `plus.circle` (the ⊕, drawn, in ember), `people` (two figures at different
depths), `card` (a credential with a face and two rules). All at 22pt, 1.7pt stroke, `currentColor`.
Remove the labels and the product is still nameable, which is the test the shipped five stock filled
SF Symbols fail.

**One idiom for "this row pushes", and it is countable.** A row **whose whole surface is the target
carries no chevron** — the row is the affordance, and a glyph that says what the row already says is
§27's redundant icon. A `chevron.right` appears **only** where the row contains a second, smaller
target and the chevron marks which part pushes. The first draft shipped both idioms across six surfaces
of one document whose §26 mandate is to consolidate exactly this.

**The pennant is a reserved glyph.** `pennant` may appear in `CSTabBand` and in the app-icon asset and
**nowhere else** — not on a trophy row, not on an achievement, not on a season award (§5.2, and
`LINT-28`). Every achievement draws its own mark in the family: a **rule under a numeral** for a low
round (it ladders to the rule-and-figure signature), a **stepped bar** for most improved, a **filled
disc on a rail** for a season won.

- **SF Symbols survive as system furniture only** — eight of them: `chevron.left`, `chevron.right`,
  `xmark`, `plus`, `checkmark`, `square.and.arrow.up`, `ellipsis`, `magnifyingglass` — at one weight
  (`.regular`), one tint (`mut`), three sizes (13/17/22).

## 5.2 What is deleted

- **All ~35 UI emoji.** Reactions keep the six canon glyphs (🔥🦅⛳🧊🐍🚨) and nothing else.
  Achievements, trophies, category marks, the Pro's announce control, the founder's desk and five empty
  states become **drawn strokes**. Two achievements may never share a glyph.
- **Every Unicode dingbat set in Plex Mono** (⚑ ✦ ◆ ◇ ✕ ✓ ★ ⇄ ⊕ ✉ ☀).
- **Typed text arrows, and the drawn one too.** `→` inside a produced string is a lint failure
  (`LINT-13`), *and* the link's arrow is **absorbed into the underline, product-wide** — there is no
  drawn link arrow. The first draft allowed "a drawn glyph **or** the underline" and the set promptly
  shipped both, so one system carried two link idioms; the 2px rule is the affordance and the 13pt
  arrow after it says nothing the rule has not (§27, redundant icons). An arrow inside a **dateline** is
  not a link affordance at all: a date range is `SUN SEP 6 – SAT SEP 26`, en dash.
- **Eight of the nine flags.** The Tracer's pennant is the flag: it is the Compete tab, the app icon,
  and nothing else. Every other flag becomes a word. *(Nine flags carrying at least seven meanings, on
  the product's core symbol, is the audit's ICO-12.)*
- **The filled SF tab set** and its grey-glass selected capsule (§12.1).
- **The Xcode placeholder app icon.** `brand/appstore-1024.png` is finished and good and ships on day
  one, with the iOS 18 **dark** and **tinted** variants filled in `Contents.json`. Nothing else in this
  document costs less to fix or costs more to leave.

## 5.3 Emoji policy, in one line

**Emoji appear in exactly one place: the six reactions, and the golfer's own typed text.** Everywhere
else they are a lint failure (§17, `LINT-12`).

---

# 6 · AVATARS AND THE PLAYER CARD

## 6.1 The floor, kept

The marker-as-avatar-floor is canon and survives untouched: fourteen named hand-drawn glyphs, **no
silhouette state, no fabricated face, ever**. What changes is that it is finally a system.

## 6.2 The disc

| | |
|---|---|
| **Shape** | a circle. **`CSFace` is the only legal way to draw a person** — the bare-glyph path (`FriendsBoard.swift:70`) and the six marker-only construction sites are deleted, not patched. That structurally closes "a golfer with a photograph cannot show it on the people tab" |
| **Ground** | one of six **pigments**, chosen deterministically from the golfer's id (`pig[hash(id) % 6]`). Two Saguaros in one list become two different coins, with no data required and **no colour meaning implied** |
| **Ring** | 1px `rule`, inset |
| **Marker** | drawn at 55% of the diameter, in `mut` (4.00–4.92 / 4.71–5.40 — a glyph, over the 3:1 graphic floor; `ink` when the face is the viewer's own), **optically normalised** — the fourteen markers are re-fitted to a common cap-height box rather than aligned by bounding box, so a column of them stops reading ragged |
| **Sizes: five, tokenised** | **24** (inline) · **30** (slat) · **38** (list, field, clash) · **56** (block) · **120** (crest) |
| **"Chose nothing"** | draws the golfer's **initials** in `name` 15 in **`ink`** on the pigment (9.09–11.17 dark / 12.46–14.29 light) — which is not a silhouette and not a fabricated face, and is visibly different from "chose the Saguaro" |
| **With a photo** | the photograph fills the disc, **subject-anchored crop** (not centre crop), same inset ring |

**Squad colour does not touch the disc.** Squad identity is a rule or a swatch beside the row; the
disc's job is *which person*, and pigments answer it without spending a semantic colour.

### 6.2a The marker is FROZEN per profile — one pigment, one glyph, every surface, both themes

**NEW after the blind review.** All three reviewers caught the same class of defect and two named it
as a brand failure rather than a bug: *"Galen's marker is brown in `event-ryder-live` and maroon in
`event-light` — marker colour is identity and must not vary with theme"*; *"Sam Ridley carries a tee
here and a cactus on his own card"*; *"Galen's marker changes from a tee to a flag between the season
and leaderboard surfaces"*. A marker that drifts is not an identity system; it is decoration that
happens to be circular.

**The law.** A profile's marker is a **pair** — `(pigment, glyph)` — resolved once from the profile
row and never re-derived per surface, per theme, per size or per component. Consequences the build
must enforce:

- **The pigment is the same token in both themes.** In light the token resolves to the pale tint and
  in dark to the deep one; that is a *printing* of one identity, not a second identity. What may never
  happen is a golfer being seated on `pig1` in one artboard and `pig0` in another, which is exactly
  what happened when a light-theme ceremony band was authored with literal hexes instead of tokens.
  **On a ceremony band inside a light surface, the marker takes the dark pigment's literal value** —
  the band is dark in both themes, so the mark must be too — and the mapping is a lookup, never a
  re-pick.
- **On cream stock the glyph takes `ink`, never `mut`.** The pale tints are ~0.90 relative luminance;
  a `mut` stroke on them measured near-invisible in the light renders, and one reviewer filed it
  ("lift the marker-cluster avatars in dark; the light render proves the design" — the same failure,
  the opposite theme). `.paper .disc svg { stroke: ink }` is now a rule, not a per-site override.
- **Initials are never rendered when a marker exists**, at any size, in any component. This was
  already canon (§6.1's "guaranteed floor") and was violated on five artboards — Tash Bell drew as
  `TB` in every table while carrying a real marker on her own card, and two reviewers filed it. The
  floor means *the marker is what appears when there is no photograph*; it does not mean initials are
  a legal rung below it. **There is no initials rung.**
- **One glyph per golfer, and glyphs must be discriminable in pairs.** Two of the shipped fixture's
  markers were near-identical line drawings at 30pt; the pair now differs in silhouette, not only in
  detail. When a new marker is added to the table, the test is: at 26pt, against every existing
  marker, does the pair differ in *outline*?

## 6.3 Faces are a rule, not an intention

A face appears in: every table row, every wire item with a person in it, the clash, the event's field,
the course's rounds list, the person page, the desk's sidebar and every desk table row. **The event's
field** is a spaced row of 38pt discs with names beneath; **"who of yours has played it"** and any
small group summary is an **overlapping row** (−12pt overlap, each disc ringed in `bg0` so the stack
reads) followed by a sentence naming the friends and the best score. Overlap at small sizes reads as a
*group*; a spaced row with names reads as a *roster*, and each is used where it is true.

## 6.4 Photography of people

- **One treatment, replacing five.** `CSPhotoScrim`'s settle/plate split with its measured
  `groundUnderCopy` arithmetic and its existing test is the product's **only** scrim.
- **A round photo is never an avatar.** It renders as a **3:2 plate** (inset) or a full-bleed 2.1:1
  crop band (in the wire). This kills the centre-cropped-landscape defect (ICO-17) at the rule level
  rather than with a smarter crop, and it is one line a preflight can enforce.
- **The medallion**: a disc of the `ceremony` ground carrying the marker in `gold` on a 1px gold ring,
  notched into the lower-right of any photograph, plate or object the golfer owns. It is the one place
  a marker takes a metal, and it means *this is theirs*.

## 6.5 The player card — the credential

A collectible object, not a layout — and **this table is the object's single anatomy of record**.
`profile.md` and `player-card.md` both rebuild `CredentialCard.swift`, `CredentialFace.swift`,
`YouHero.swift`, `PersonPage.swift` and `FoundingTag.swift`, and both cite GP-16 ("one object, two
chromes, two aspect ratios") as the defect they close — so a second, disagreeing anatomy table in
either spec would reopen GP-16 in the design that closes it. **Neither spec restates the geometry; both
point here**, and each says only what its own page does *around* the object.

**Geometry, ruled once: `362 × 312` (≈ 7:6, landscape), radius `r` 16, `shadow-lift`, ground
`ceremony` in every theme.** A 3:4 object at the 362pt measure is **483pt tall**; with the chrome above
it the page's ranked action lands below the tab bar on every device — the audit's F-8 / GP-19 / YRS-25.
**The 3:4 portrait survives in exactly one place: the share PNG**, which has no fold and no chrome
under it. That is the whole disagreement between the two specs, settled.

Anatomy, top to bottom (`profile-top`, `player-card-photo`):

| # | Element | Spec |
|---|---|---|
| 1 | **The plate** — 362 × ~180, the object's top corners. The golfer's photograph through `CSPhotoScrim.title` (§10.3); else **the crest**: the marker at 1.4–1.5pt in `crest` `#33463B`, bleeding off the right edge, with their home course's contour behind it at `a24`. An emboss, not a picture | `CSPlate` |
| 2 | **The slot** — an earned label in a 24pt `ceremonyGold` field with `panelInk` `agateS` (9.43:1): `FOUNDER` · `CHAMPION` · `THE PRO`. **Absent when nothing is earned**, and then the card carries no gold at all. This is the surface's one gold object | `CSSlot` |
| 2a | **The live tag** *(replaces the slot while a round is live)* — a 7pt `ceremonyBrand` dot + `agateS` in `ceremonyBrand`. The only ember on the card | — |
| 3 | **The medallion** — a 44pt `ceremony` disc, 1px `ceremonyGold` ring, the marker drawn in `ceremonyGold` (9.65:1), notched at the plate's lower right. **Present only when the plate is a photograph.** On a crest card the crest *is* the mark: **the crest or the corner, never both**, which also removes the collision `profile.md` filed as a known imperfection | `CSMedallion` |
| 4 | **The name** — `display` 34 in `ceremonyInk`, riding the scrim | `CSType.display` |
| 5 | **The identity line** — `agateS` at `ceremonyMut` (**7.71:1**), **one string product-wide**, `CredentialCopy.identity`: `@GALENM · MESA, AZ · PAPAGO`. Handle, city, home course. **`EST. JUL 2026` is not in it** — the founding fact is already the gold slot and the folio's serial, and saying it a third time is YRS-21 | `CredentialCopy.identity` |
| 6 | **Three figures on one rule** — index · rounds · position. Each numeral `figure` 27 tabular; a shared **2pt `ceremonyInk` rule** (17.51:1) beneath all three; `agateS` labels at `ceremonyMut` under the rule. `ink` is **1.11:1 on `ceremony` in light** and is forbidden here (§16.1) — the rule that binds the card's three figures is the last thing that may vanish in one theme | `CSFigure` ×3 |
| 6a | **The ordinal rider** — `max(11, numeral × 0.4)`, uppercase (§1.6) | — |
| 7 | **The folio** — a 1px `ceremonyInk` `a16` rule across the measure, then `agateS` in **`folioRule` `#8B8F8B`** (5.92:1 — the opaque value `ceremonyInk` at `a56` composites to, named so nothing is invented in Swift): `CUP SEASON · THE LONE TREE` flush left, `No. 12` flush right | `CSFolio` |

**The back** (the card sheet's reverse, and the share PNG's second face): the leaf. A printed grid —
last five with dates, courses kept, the record — in `column`, with the folio repeated. Front is the
person; back is the record.

**Three sizes, one object**: the profile hero (full measure, 362 × 312), the card sheet (a held card at
0.82), and the share PNG (exported at 2×, and **the one 3:4 crop**). §9 of the brief's list — face,
name, handicap, status, form, position, course — is complete, with nothing crammed, because form and
position live in the two rows *under* the card rather than inside it.

**Its name is "the card".** Not "the Tour Card" — `TERMINOLOGY` §4 pattern 30 retires that name with no
exempt call site, and §4's scope explicitly covers `.accessibilityLabel`. In prose it is *your card* /
*‹Name›'s card*; in code it is `CSCredential`, which already carries the right name.

---

# 7 · BUTTONS AND CONTROLS

The single highest-leverage change the audit names: **primary/secondary/tertiary become `ButtonStyle`s,
not a `View`.** That one move removes the reason four sites hand-copy the ember fill, gives every
button a pressed state for free, and lets `ShareLink`, `NavigationLink` and `Menu` wear the brand.
90 of ~317 tappables carry a shared definition today; the target is all of them.

## 7.1 The three tiers, and every state

| Control | Geometry | Rest | Pressed | Disabled | Busy |
|---|---|---|---|---|---|
| **Primary** | 50pt, `rc` 10, full-width or intrinsic, label `name` 17 | `brand` fill, `bg0` label (5.27:1 / 5.39:1) | fill darkens by `a16`, label to 92% | `bg1` fill, `mut` label — **a disabled primary is never ember** | label replaced by **three mono dots that tally** — never a spinner |
| **Secondary** | 50pt, `rc` 10 | `bg2` fill, `ink` label | fill → `rule`, label 92% | `bg1`, `mut` | as above |
| **Tertiary — the link, LIVE** | intrinsic, 44pt target | `name` 15 in `ink`, **2px `brand` rule** beneath | rule darkens, label 92% | `mut` label, `mut` underline | — |
| **Tertiary — the link, in content** | intrinsic, 44pt target | `name` 15 in `ink`, **2px `mut` rule** beneath (7.07 / 5.85) | rule → `ink`, label 92% | `mut` label, `mut` underline | — |
| **Tertiary — the link, in a TOOLBAR** | intrinsic, 44pt target | `name` 15 in `ink`, **1px `mut` rule** beneath | rule → `ink` | `mut` label | — |
| **Destructive, armed** | 50pt | `bg2` fill, `neg` label, copy **"Sure?"** (never an `alert()`) | fill → `neg` at `a16` | — | — |

**One primary per screen**, and it is ember because ember means *the live thing you can do now*
(§2.4). **There is no gold button** — the tier does not exist, and `CSButtonStyle.gold` is deleted.

**The tertiary's rule is where ember kept leaking back, so the tier is split into three and the split
is a ruling, not a preference.** §2.4 gives ember exactly two jobs; a *dismiss* verb is neither, a
*Settings* link is neither, and a *Share* link is neither. The first draft gave every tertiary a 2px
`brand` rule, and the consequence was countable: four screens whose only content-area ember was the
word `CLOSE` or `SETTINGS`, and one sheet (`event-plan`) carrying three ember rules and a fill.

> **In content the link keeps its shape and its metal only when it IS the screen's one live action.
> Otherwise the metal goes and the shape stays. In a toolbar the metal never appears and the rule
> thins to 1px — the toolbar's position is already an affordance.**

`mut` at 7.07 / 5.85 is the underline colour in both quiet cases, never `rule` (2.66 / 2.30): when the
underline *is* the affordance, taking it below 3:1 stops it being a control. `CSDoor` /
`CSButtonStyle.tertiary` therefore takes a `Placement` — `.live`, `.content`, `.toolbar` — and
`LINT-18` counts every ember mark on a viewport, not only fills.

## 7.2 Chips, segments, fields, steppers, sheets

| Control | Geometry | Rest | Selected | Disabled |
|---|---|---|---|---|
| **Chip** | 28pt tall, `p` 3, `agate` label, `s3` horizontal padding | `bg2` fill, `mut` label | **inverts to the panel** — `panel` fill, `panelInk` label | `bg1`, `dim` |
| **Segment** | 44pt row, **no pill** | `agate` in `mut`, 2px transparent underline | `ink` label, 2px **`ink`** underline — never ember, because a tab is not live | — |
| **Field** | 50pt, `rc` 10, `bg2` fill, **no border** | value in `body` 17 (SF) — `column` 17 only for a code, handle, time or score | focus: **2px `brand`** ring | `bg1` fill, `mut` value |
| **Stepper** | 44pt, `bg2`, value in `figure` 20, **bare — no ring and no box** (§9.4: the score mark and the input are not the same object; a circled numeral between a − and a + reads as *selected*, not as a birdie). The field is the numeral's own underline | `.selection` haptic per step | — | — |
| **Sheet** | `rs` 24 top corners, `bg0` ground, drag pill in `rule`, a `rule` under the header | — | — | — |

**The field family, in full** (the audit's "inputs" item, which the product answers with two states and
a cliff between them): **label** in agate above · **value** · **caption** in `body` 15 at `mut` beneath,
which doubles as the **error** line in `neg` · **character counter** in agate appearing at 80% of a
limit (four fields currently clamp silently inside `.onChange` and tell the golfer nothing) ·
**disabled** · **loading**. The caret is tinted `brand` **at the presentation roots**, not per field —
the shipped iOS-blue caret on all 54 fields is a root-level omission, not 54 missing modifiers.

**Chip budget: one chip row per screen, at most six chips.** Twenty-two declared chip types at five
heights, five paddings, two shapes and three "selected" languages become one shape and one selected
language — and the inversion also fixes the finding that the *selected* pill was visually quieter than
the unselected one.

## 7.3 The sheet grammar, said once

84 `.sheet(` sites and 11 full-screen covers currently offer three dismiss verbs in three colours at
two positions plus an xmark circle plus nothing at all. One grammar:

- **Dismiss is one thing: `Close`**, a **toolbar** tertiary link at `topBarTrailing` (§7.1 — `mut`,
  1px rule, **never ember**), in every sheet and every cover. No xmark circle, no coloured "Done", no
  bare gesture-only sheet. A sheet's loudest control is never the one that closes it.
- **The confirming action lives in the body**, at the foot, as the sheet's one primary. A toolbar never
  carries a consequential verb.
- **Detents**: `.medium` for a question, `.large` for a list, `CSFittedSheet` for anything measured.
  A bare detent outside `CSFittedSheet` already fails preflight; that check stays.
- **Objects are pushed, not presented** (`IOS-003` §2.4, kept): the card, a round receipt, a
  scorecard and the member list are screens; actions are sheets.

---

# 8 · BADGES, PILLS, DIVIDERS, RULES

| Object | What it is for | Budget |
|---|---|---|
| **The rule** (1px `rule`) | the *only* divider. Between slats, under a section label, above a foot action. Full-bleed or inset to the measure — never a short decorative dash | unlimited, but a rule always separates two things that are genuinely different |
| **The heavy rule** (2pt `ink`) | under a masthead; under a figure in a rule-and-figure. Its metal variants (`brand` live, `gold` earned) are the two-metal law made graphic | one per masthead; one per figure block |
| **The section head** | agate label + a 1px rule running to the margin, with an optional agate **count** flush right. The right slot takes a count or a period (`LAST FIVE`, `11 KEPT`, `WEEK 5`) — **never a proper name**, and never a league's name, which belongs in the label or in the row's own sub-line. Replaces `CSSectionHead`'s current pairing with a bordered card beneath it | ≤3 per viewport |
| **The slot** | a 24pt `gold` field with `panelInk` agate, for a thing that was won (`FOUNDER`) | one per surface; it *is* the surface's gold object |
| **The chip** | a filter or a selectable, §7.2 | one row, ≤6 |
| **The badge** | a count on a tab or a row: a 16pt `bg2` disc with `agate` 11 in `ink`; ember **only** when the count is a live thing you can act on now | one per tab item. `.badge(` currently appears **zero** times while `PushBadge` sets an app-icon count — a golfer who opens the app from the badge has no trail back to what summoned them |
| **The tick row** | N week ticks, 8pt tall — **played `ink`, now `brand`, ahead `mut`**. Countable, and unmistakably a scorecard rather than a health bar. *(The first draft used `mut` played / `rule` ahead, which is 2.66:1 dark and 2.30:1 light against each other in two bars of identical size: the row's whole meaning rode one tone step below the threshold of sight. `rule` separates; it never states — §16.1.)* | one per season surface |

**There is no pill.** Capsules (74 raw `Capsule()` sites) are deleted: a chip is a 3pt-radius
rectangle, a toast is a 10pt-radius block, a badge is a circle because it holds a count.

---

# 9 · DATA DISPLAY

## 9.1 The leaderboard row — the slat

Full-bleed, one `rule` on its top edge, **50pt** at the default size. Five ordered facts, all present,
each in its own column (`BRIEF` §15: POSITION · PLAYER · SCORE/POINTS · MOVEMENT · STAKE):

```
│ 01 │ ◍  GALEN MARR                │ ▲2 │  —   │  19 │
│gold│    3 ROUNDS · HELD           │    │ gap  │ pts │
  44    30    name + agate sub-line   34    46     52
```

**The rail keeps its 44pt width, and `figure` 27's ×1.45 cap is what makes that true** (§1.2): two
tabular digits are 1.080 em, so at AX3 the numeral is 39.1pt and the pair is 42.3pt inside 44. The
row's height goes intrinsic; the width does not move. Stated once here and in §16.3 rather than
repeated as "keeps its width" in four surface specs that had no arithmetic behind it.

**REVISED after the blind review (2026-09-06). Movement and gap share ONE cell, and a surname is
never cut.** All three blind reviewers, independently, filed the twelve-row board's four truncated
surnames (`PRIYA RAGHU…`, `BARTHOLOME…`, `MARCUS OYEL…`, `ANA QUINTAN…`) as the single most damaging
defect in the set, and two of them proposed the same remedy. The row is therefore:

```
│ 01 │ ◍  G. MARR                       │  —      │ 104 │
│gold│    11 ROUNDS · BEST 74           │ +9  ▲2  │ pts │
  44    30    name + agate sub-line        58       50
```

1. **Delta and gap are one cell, 58pt, right-aligned: the gap figure, then the movement mark.** They
   are both change metrics, both half-empty at any field size, and separately they ate ~130pt that the
   name column needs. Merging them returns ~28pt directly, and the header row loses its `Δ` column.
2. **A held row prints ONE mark.** `— —` (an em dash for the gap and a held bar for the delta) reads as
   a rendering error; a leader with no gap and no movement prints the held bar alone.
3. **At a field of ten or more, the given name abbreviates to an initial before any name is ever
   truncated** — `P. Raghunathan`, not `Priya Raghu…`. The rule is per-board, not per-row, so the
   column keeps one grammar: at ten or more, *every* row abbreviates, including `G. Marr`. Below ten,
   full names, because they fit. Tail ellipsis remains the last resort and now fires on a surname of
   14+ characters rather than on a first name plus a space.
4. **The header row ships at every field size.** It was present on the six- and twelve-row boards and
   absent on `season-top` and the two-row board; two reviewers filed the inconsistency and one called
   the unlabelled `+4 / +9 / +12` column "the single most confusing element in the set". `POS ·
   GOLFER · GAP · PTS` is now drawn on every table in the product, including the season page's.

- **Position** — the rail. `figure` 27, tabular, two digits with a leading zero, centred. Field: `gold`
  when the position was earned (1st), `panel` when the row is yours, unpainted otherwise.
- **Player** — a 30pt disc, then `name` 17 caps, then an agate sub-line **in sentence case** and in the
  product's voice ("3 rounds · held", "1 of 4 counting · one short" — never *floor*, which is the
  schema's word, `TERMINOLOGY` §4 pattern 2). The name column is `min-width: 0` and **truncates with a
  tail ellipsis** — the one long-name policy, product-wide, replacing the shipped wrap/wrap/clip split.
  **The viewer's own row reads `YOU` alone**, product-wide: at the 375pt measure the fixed columns
  leave 141pt and `YOU · SAM RIDLEY` at `name` 17 with caps tracking measures 143pt, so the first row a
  golfer sees on an SE would ellipsise their own name at the default text size.
- **The squad channel** — **restored, and it costs no column.** When `structure != solo`, the sub-line
  carries a **4 × 14 `sq` swatch** followed by the squad's **name in agate**, before the state clause:
  `▌ MUDSHARKS · 3 rounds · held`. Rendered only in a squads season, which is what CS-11 actually
  found (a swatch in a two-golfer SOLO season) — the defect is a swatch where there are no squads, so
  the fix conditions it rather than deleting it. Squad colour is a row of the identity contract and
  `COMPONENT_SYSTEM` P-5's anatomy requires the slot; with the channel gone, a squads table could not
  say which side anyone is on. It also satisfies §16.4's two-channel rule literally: **a swatch plus
  the squad's name, never colour alone** (the four squad marks are only 1.58:1 apart — §2.2a).
- **Movement** — §9.3, on the page's own ground.
- **The gap** — its own column at last, `column` 14 right-flush: `+4`, `+9`. **The leader's cell is
  empty** — never `0`, and never an em dash either, because an em dash reads as a value, which is the
  thing "empty" was protecting against. One cell, one answer. It is never a sentence and never inside one; the chapter line above may still
  *say* the gap, because the sentence is the story and the column is the record.
- **Points** — `figure` 27, tabular, right-flush; **gold only for the leader**.
- **Stake / money** is the sixth column, on the desk only, where there is room (§14.3).

One VoiceOver element per row: *"2nd. You, Sam Ridley. Up two. Four back. Fifteen points."*

## 9.2 The score as an object

One face, one rule: **`figure`, tabular, at 56 / 40 / 27 / 20**, and any figure at 27 or above carries a
**rule-and-figure** — a 2pt rule the width of its column and an agate label hanging beneath. Ten
renderings of the gross across six roles from 11pt to 64pt become three. A figure inside a sentence is a
**figure run** (§1.6). A figure in a column is right-flush and tabular; `csTabular()`'s 69 sites are a
"what works" and survive.

**A panel does not take a rule-and-figure** — the panel's own edge is the rule, so its label sits
directly under the numeral in `panelMut`.

**Neither does a column.** A figure repeating down a table's trailing column is a **bare tabular
`figure` 20, right-flush, no rule** — column position is the hierarchy, and §9.1's own slat gives the
points column no rule for the same reason. Six rule-and-figures down one list is six 2pt rules and
eleven lines of ragged caps against one right edge; the rule-and-figure is reserved for **a number that
matters**, which cannot be every row.

## 9.3 Movement

**A drawn triangle and a tabular numeral, on the page's own ground.** No field, no pill, no tint behind
it.

| State | Mark |
|---|---|
| up | a drawn triangle (9 × 7, apex up) in **`pos`** + the numeral in **`ink`**, `figure` 20 |
| down | the same triangle inverted in **`cool`** + the numeral in `ink` |
| held | a **9 × 2 bar** in `mut` (7.07 / 5.85). *Never `rule`: at 2pt and 2.30:1 in light it is neither a shape nor visible, and "held" becomes indistinguishable from "no data" — §16.1.* |

Shape *and* colour, so it is never colour-only; one line, never two, never wrapping. The mark is a
**drawn component with an accessibility label** — an arrow character inside a produced string is a lint
failure (the shipped indicator is a Unicode glyph inside a string at 11pt with `lineLimit(2)`, so
"HELD SINCE SUN" wraps beside a two-digit rank).

**▼ has exactly one meaning — you fell.** "Most Improved" is a gold slot, not an arrow; the producer
that emits ▼ for it is changed at the producer. That closes the audit's opposite-valence finding
(DD-02) at the source.

At hero size on Home, movement is a **rule-and-figure**: `▲2` over a rule with `SPOTS` beneath — which
is §15's *"↑ 3 should immediately communicate more than a paragraph"* answered with a picture instead of
a paragraph.

## 9.4 The scorecard, and the colour rule that costs nothing

**Under and over par are drawn the way they are on paper**, in `ink` (or `leafInk`), at the icon
family's 1.7pt stroke, with **no colour at all**:

| Score | Mark |
|---|---|
| eagle or better | a **double ring** around the numeral |
| birdie | a **ring** |
| par | nothing |
| bogey | a **box** |
| double or worse | a **double box** |

This is a paper convention no app uses; it reads identically in both themes; it is archival; it is not
colour-only; and it settles the audit's "three scorecards, three colour languages" (birdie is `pos`
green on one card and **gold** on another) without spending a single token. Stroke pips for handicap
strokes stay as they are — `LiveCardView`'s refusal to draw them off an estimated stroke index is a
"what works".

**The marks are drawn where nothing is tappable.** The hole strip, the scorecard and the receipt carry
rings and boxes; **the stepper's numeral is bare** (§7.2). A circled numeral flanked by a − and a +
reads as *this field is selected*, so the paper convention and the selection convention would be one
shape — and the strip above the rows then has a job the rows do not duplicate.

## 9.5 Money

- The figure is **`ink`**; the pot and anything won are **`gold`**; `pos` and `neg` never touch money.
- **The sign is a word**, in agate: `YOU OWE` · `YOU'RE OWED` · `SETTLED` · `THE POT`.
- **The ledger line renders verbatim from one constant** in `body` 15 at `mut` — **once per scrolling
  surface, under the first money figure that surface shows.** It is the anti-"betting app" vaccine and
  it is a copy law, not a suggestion (D39, D201). *A viewport is not a surface*, and the first draft's
  "beneath every surface" left the scrolling case unresolved, so four artboards printed money with no
  ledger line and only one declared it — which is how Phase 3 would have resolved it by omission on the
  season board, the twelve-row leaderboard and the profile's record. Under the pot on the season page,
  under the payout ladder on a full board, under the record leaf on the profile, under the pot on the
  event's **first** viewport. If two lines is the cost, the constant is shortened **once, with the
  owner** — never on an individual surface.
- A negative money figure takes a **minus sign in ink** (`−$20`), never a red fill or a red numeral.

## 9.6 The standing line

Four figures on one shared 2pt rule with their agate labels beneath, and **the league sentence in agate
under the whole block**: `THE FELLAS · 2ND OF 8 · 4 BACK OF GALEN`. One agate sentence does more
competitive work than any chip, and it names the rival — which is §13's "important matchups visually
emphasised" done with type instead of furniture. This is the ME strip (`CSFactStrip`, P-15): my number ·
my last round · my next round · my money. It is type on the page's ground and it has **no box**, no
border, no radius and no `CSStat`.

## 9.7 The form row

**Five grosses with their dates on one rule, the best in `gold`** — the figures in `figure` 20 above a
2pt `ink` rule, the dates in agate beneath, and the best gross and its date both gold. It says "recent
form" without a legend, which five squares and five dots both need ("lit = beat it"). On the desk it
compresses to a five-dot column inside the table row (§14.3), where a column is worth more than a block.

## 9.8 The record

A **printed table on a leaf**: `year · competition · finish · money`, one row per season, the year in
`columnS` at `leafMut`, the competition in `social` with its qualifier in agate, the finish in
`figure` 20, the money in `column` 14 right-flush. A won or podium finish is marked by a **2pt gold rule
beneath the finish cell** (gold ink on bone is 1.68:1 and is forbidden — §2.4). §31 asks HISTORY to be
archive and achievement; the archive is the one surface that should be a book page.

## 9.9 The HCP, and the gap — the two facts that keep escaping into prose

**The handicap index** is always a rule-and-figure — `figure` 40 as a hero, 27 in a strip cell — with
`HANDICAP INDEX` or `YOUR NUMBER` in agate beneath the rule. It is the first cell of the ME strip and
the first of the credential's three figures. It is **never inside a sentence, never a caption, and never
beside a signed delta**. `STARTER` and `BUILDING` are the *label*; the value slot never renders a dash
or a guess.

**"Never a guess" includes par.** An unscored cell on the live sheet does **not** render the hole's par
in the value slot: rendering par *is* the guess, in the same slot, face, size and position as a real
score, told apart only by 16.05 versus 7.07 and an underline at 2.66:1 — tone-only communication on the
most-looked-at screen in the product, mid-round, held in sunlight, where the consequence is a wrong card
posted. **The numeral seat stays empty until a golfer puts something in it**, the rule stays
`rule`-coloured, and the hole's par hangs **below** the rule in `agateS` at `mut` (`PAR 4`) where a
scored cell carries nothing — a second channel that is position, not tone (§16.4). Any running total
computed over an empty seat says so: `55 THRU 14 · TWO NOT IN`.

**The gap** is a column (§9.1), `column` 14, right-flush, `+4` / `+9` / `—`, and the leader's cell is
empty. It may be *said* in the chapter line above the table — the sentence is the story and the column
is the record — but it never lives only inside prose, which is where all three of its shipped
renderings are.

## 9.10 Charts — three, and no library chrome

Swift Charts with token colours, **no gridlines, no legends, no axes, no area fills**, and every chart
is a printed diagram.

1. **The climb** — the slat list re-ordering with matched geometry. Not a chart at all.
2. **The month** — a row of N week ticks (§8). This replaces the heat gradient (audit D7).
3. **The index trajectory** — a hairline step plot in `ink` with the counting differentials marked as
   filled slots, on `bg1`.

4. **The hole strip** — 18 cells on one rule, marks only, in the ink law (§9.4), no numerals, no axis,
   no legend. Cells are **≥20pt** and the strip drops the *double* variants: at 20pt an eagle and a
   birdie both draw a single ring, and the doubles live on the card and the receipt where §9.4 has room.
   One VoiceOver element in the product's voice — *"Through fourteen. Two birdies, nine pars, three
   bogeys. You are on fifteen."* — with the current hole `.isSelected`.
5. **The meeting tape** — the head-to-head's ticks above and below one rule: **the viewer's filled, the
   rival's outlined**, the row labels folded into the section head. **No legend** — a legend on a chart
   is what §9.10 exists to forbid.

`RoomSpark`, whose own doc comment calls it "Decoration", is deleted. The pressure meter is deleted with
the heat axis. **A sixth chart requires a decision-log entry.** *(Charts 4 and 5 arrived from the
surface specs while this section still said "three, and a fourth needs a ruling"; they are ruled here
rather than left to ship unmentioned.)*

## 9.11 Ratings

§12 of the brief, which does not exist in the product at all today. **The rating is content, not a form
field**: a rule-and-figure at 40 in **`ink` on a 2pt `ink` rule** with `CUP SEASON GOLFERS · 24 RATINGS`
in agate, a **drawn** five-star rail beside it — **filled `ink`, unfilled `rule`**, half stars by
clipping the fifth star, not by a different glyph — then one `body` 15 line for the other numbers, and a
tertiary link, `Rate it`. Unrated is a full-size **unfilled** star rail plus
`NOT RATED · THE FIRST RATING SETS THE NUMBER`, never a hidden or shrunken control.

**Two words this section had to give back.**
**Gold**, because *nobody earns a course's rating*: it is an average of opinions, and gold means a thing
that was won (§2.4). Gold on the rating put the product's scarcest mark on its most repeated object —
every course row, every discovery item, every course page, twice on Home. The rating's weight comes from
**size and the rule**, which is what the display tier and the 2pt rule were built for.
**"Card"**, because T-01 spent an entire ruling collapsing that noun to one object — the person. A
rating is a **rating**; a posted round is a **round**; the paper thing with eighteen boxes is a
**scorecard**. `24 RATINGS`, *"Twenty-four ratings, four of them from your golfers"*, and the rating
sheet's eyebrow is `YOUR RATING` — never `YOUR CARD ON THIS COURSE`, which is the phrase pattern 7 was
widened to catch, aimed at a third object.

---

# 10 · IMAGERY

## 10.1 The ladder — three legal states, and nothing else

**A course's image is, in this order:**

1. **A golfer's own round photo taken at that course.** `rounds.photo_path` is live, the bucket is
   private, the signed URLs are already cached. The most recent (or most-reacted) round photo at a
   course, from someone the viewer can see, is that course's plate — **credited in agate with the
   photographer's name and date**: `GALEN'S ROUND · AUG 24`. It is true, it is free, it is the brand's
   own line ("one great photo of Saturday morning"), and it makes the course page social without adding
   a feature.
2. **The drawn card.** Generated from `api_course_holes` (par + stroke index) and the cached tee
   yardages: eighteen bars, height by yardage, weight by par, **gold on the #1 stroke hole**, hole
   numbers in agate. It reads as golf faster than anything else the product can generate, and it is
   unique per course by construction.
3. **The contour plate.** A deterministic topographic plot seeded from the course id — a **seeded
   value-noise field sampled at 5–7 isolevels** (marching squares over a 32 × 32 grid; cheap in a
   SwiftUI `Canvas`/`Path`), at 1.2pt in `mut`, **cropped hard off its own centre**, carrying a routing
   line and one `brand` dot on the hardest hole by stroke index. Same course, same plot, forever.
   **Not nested ellipses**: six near-concentric circles with a radial line is a radar sweep, and it is
   the same "three near-identical concentric ovals" failure §10.2 uses to ban the contour at thumbnail
   scale, arriving at plate and hero scale instead. A noise field is what makes two courses look like
   two places.

**Never**: stock photography · a licensed image the product does not have · a generated aerial presented
as real · a fabricated face · a silhouette · **a gradient wash standing in for a photograph**. All three
Phase-2 directions used a wash as a mockup stand-in and all three said so; a wash is not one of the
three states and may not ship.

**REVISED after the blind review — the review rule that goes with the ladder.** All three blind
reviewers looked at thirty-four renders and reported, independently, that there is **no photograph
anywhere in the product**; two of them scored COURSE "not premium" and "does not belong in the
category" on that basis alone, and one wrote that the shipped tour card's real picture of a man on a
green "is the warmest thing in the shipped app". The ladder above was right and the *deck* was
wrong: every artboard drew rung 2 or rung 3, so a reviewer who never read this document could only
conclude the system had no rung 1.

**The rule that follows, and it binds every future design review as hard as it binds this one:**

> **A surface's flagship artboard renders the ladder's TOP legal rung. The fallback is proved on its
> own named variant, never on the surface's front door.** The course page, the credential and Home's
> wire band each carry a photograph in the artboard that carries the surface's name; `-noimage`,
> `-marker` and `-quiet` are where rungs 2 and 3 are proved. A deck that shows only the degrade has
> not shown the design, and reviewers will score the degrade.

This is also why the drawn card (rung 2) must be drawn from **real** par and yardage with hole numbers
under it. All three reviewers read the eighteen unlabelled bars as decoration — "a fake chart", "an
equalizer", "random bar heights representing nothing, as the hero of a page about a real place" — and
one wrote the line this system now adopts verbatim: **fake data as ornament is less premium than a
plain colour.** The bars are heights by yardage, widths by par, gold on the #1 stroke hole, numbered
1–18 in `colS` beneath. The sentence that explains the gold bar is the page's own facts line ("the 6th
plays hardest"), twenty points below it — a fact the page was already printing, not a caption teaching
the reader how to read a graphic (which §10.2 still forbids).

## 10.2 Where each plate is allowed

| Scale | Photo | Drawn card | Contour |
|---|---|---|---|
| **hero** (full-bleed, 260–300pt) | yes | yes | yes |
| **plate** (inset 3:2) | yes | yes | yes |
| **thumbnail** (≤64pt) | yes | **yes — this is the thumbnail** | **never** |
| **watermark** (behind a credential's crest, `a24`) | never | never | yes |
| **behind running text** | never | never | **never** |

The contour is banned at thumbnail because three different courses draw as three near-identical
concentric ovals at that size — the exact failure clubhouse's own renders showed. **A course with
neither a photo nor a cached card shows no thumbnail at all**: the row's left column collapses and the
name sets flush to the margin. That is honest, and it is better looking than a placeholder.

**And the drawn card degrades at thumbnail rather than shrinking**, for the same reason and by the same
test: eighteen 3pt bars in a 44 × 26 box are three near-identical grey combs — the identical failure,
with the identical justification, on the object this table declares to *be* the thumbnail. **At ≤64pt
the drawn card renders the front nine only: nine bars at three heights by par (3 / 4 / 5), one tone.**
Countable at 26pt, and genuinely different per course.

**A plate never carries a caption that teaches the reader how to read it** ("THE PLATE IS DRAWN FROM
THE CARD"). It carries a credit, or nothing. A caption explaining the graphic is a tell that the
graphic is not carrying.

## 10.3 Round photos, and the scrim

- **A round photo is never an avatar.** It is a **3:2 plate** when inset (the album, the receipt, the
  course page) or a **full-bleed 2.1:1 crop band** in the wire, where the text sets on the scrim and the
  panel carries the gross.
- **One scrim component, TWO named geometries, and a third for the status bar.** "One scrim" was three
  in the first draft — a left-to-right 3-stop on the wire band, a top-to-bottom 4-stop on the course
  hero, and a third with different offsets on the credential — three geometries, two directions, in the
  mockups illustrating the claim. `CSPhotoScrim` now takes exactly:
  **`.title`** — bottom-anchored, for a name reversed out of a plate (the course hero, the credential,
  the event's title card): top → bottom, stops `0% clear · 44% ceremony a24 · 72% ceremony a72 ·
  100% ceremony a88`;
  **`.band`** — leading-anchored, for a wire photo band where the copy sets at the left: leading →
  trailing, stops `0% ceremony a88 · 46% ceremony a56 · 100% clear`; and
  **`.top`** — for any plate that runs full-bleed **under the status bar**: `0% ceremony a72 → 96pt
  clear`. Without it the credit line, the system back chevron and the status clock sit on raw image,
  and over a real sunrise photo — rung 1 of the ladder, and the whole point of it — the credit computes
  at **1.48:1** on the bright band.
  Copy over any of the three takes `scrimInk` (a name, a headline) or `scrimMut` (a credit, a caption)
  — the two named constants of §2.1, so the extra hexes the specs had invented (`#D2D8CE`) are gone.
- **`PhotoScrimTests` is extended before any of this ships.** It holds `mut` **body** copy today, and
  the system now puts four roles on the same scrim: `display` 34 (the credential, the course hero),
  `social` 17 (Home's wire band), `agateS` (the credit) and the chevron's stroke. All four are
  composited against a **high-frequency** subject — a real photograph, not a two-stop wash — and the
  test is a gate, not a follow-up. Until it exists, the surface's signature move, a name reversed out
  of an image, is unproven everywhere it appears. The board's separate three-stop dusk gradient, the
  album's raw square, the recap's gold ring and the credential's blurred watermark are all replaced by
  `CSPhotoScrim`.
- **The panel over a photograph is always the bone panel in both themes.**
- **No filters, no duotone, no gradient beyond the measured scrim.** A photograph is printed, not
  styled.
- The album keeps its square grid and loses its hairline ring.

## 10.4 What the mockups stand in for, stated plainly

Where a golfer's round photo goes, the mockups draw **the drawn card (state 2) or the contour (state
3)** — both are things the product can generate today, so the ladder is *proved* rather than flattered
— or a flat `bg2` plate carrying the credit line. **No mockup uses a gradient wash**, because §10.1's
closing line forbids exactly that and all three Phase-2 directions were rejected for it; a reviewer
looking at the set should not be shown the one image state the system bans. The earlier stand-in — a
four-stop sky, an ochre sun disc, two hill ellipses and a flag filled in `brand` — was also a cartoon
golf hole (§4's named do-not) with the *live* metal spent on decoration. **Decorative art is never
filled with a metal.** In the build the frame is a real golfer's photograph; the crop, the scrim, the
credit line and the panel are what the mockup specifies.

---

# 11 · MOTION

## 11.1 The principle and the primitive

**A board graphic arrives; it does not fade in.** The primitive is the **wipe** — a clip rect opening
from the rail's edge across the object over 220ms, so the rank slot is on screen before the name, and
the name before the figure. That is why the rail earns its keep twice: it is the origin of every
arrival, so motion and layout are one idea.

## 11.2 Two curves

| Curve | Value | For |
|---|---|---|
| **`roll`** | `cubic-bezier(.16,.84,.36,1)` — kept verbatim | travel: pushes, sheets, scroll-linked chrome, disclosures. Durations 180 / 260 / 320 / 550ms as shipped |
| **`snap`** | `cubic-bezier(.2,0,0,1)`, 180ms | arrivals and tallies: wipes, rank flips, counters, the medallion's seal |

**Nothing bounces**, either way — the canon line survives, and `snap` has no overshoot.
`accessibilityReduceMotion` resolves both to `nil` (never "faster"), and **every ceremony's rest frame
is its finished state** — the Forge's rule, generalised.

## 11.3 The five moments, sized to the moment

| Moment | What happens |
|---|---|
| **Leaderboard movement** (§21, §22) | the table wipes in top-down at a 40ms stagger; any row whose rank changed since the last open **slots** its numeral (the split-flap `RankFlipText`, kept) and its movement mark wipes in from the rail after the row settles. `.impact(.light)` once, and only if **your** row moved. This is the stubbed climb, finally playing — it needs a replay-on-open gate, which the standings table already has and the climb does not |
| **Score submission** | the gross **tallies** from 0 to its value over 340ms on `snap` while the panel wipes bone from the rail; the POSTED mark seals on the last frame with the thock (`.success`). The number is the ceremony; there is no confetti |
| **Challenge accepted** | the two faces slide to the two ends of a new full-bleed band; the countdown tallies once. `.impact(.medium)` |
| **Season progression / a season ending** | **the takeover band** — the ceremony plate wipes from the rail, `display` lines arrive at a 60ms stagger, the final figure tallies, the medallion seals and it holds. This is the biggest motion in the product and it belongs to the biggest moment. **The settlement card is rendered in-app** at the same geometry it exports at: the object the audit calls the most beautiful in the product should be seen by the golfer who won, not only by the group chat |
| **Feed interaction** (a reaction) | the emoji scales 1.0 → 1.12 → 1.0 on `roll` over 160ms and the count tallies. `.selection`. Nothing else on the row moves |

**Haptics** keep `IOS-003` §2.8's vocabulary verbatim. No haptic on scroll, on navigation, or on an
error that already toasts.

## 11.4 Deleted

Every bare opacity transition (14 sites, eight of them bare). The shimmer skeleton (replaced by
redacted geometry, §13.2). The settings-disclosure animation — *the app currently animates its
accordions and not its trophies*. Any spinner inside content. The month seal's case-insensitive regex
for the word "closed" in a post body, which tilts a feed row when a course closes for aeration. Any
animation whose only variable is duration.

---

# 12 · NAVIGATION

## 12.1 The tab bar

**A full-width band on the page's own ground with a 1px `rule` on top.** No floating pill, no glass, no
capsule, no fill.

| | |
|---|---|
| Height | **74pt** + the safe area |
| Item | a **22pt drawn glyph** above an `agateS` label |
| Rest | `mut` glyph and label |
| Selected | `ink` glyph and label, plus a **26 × 2pt `ink` underline** beneath the label — never ember, because a tab is not live |
| **Play** | the drawn **⊕ glyph in `brand`** with `PLAY` in `brand`. **No fill, no disc, no square.** It is the only coloured thing in the chrome, and it is a glyph, so it can no longer be the loudest object on every signed-in screen |
| Content inset | every scrolling surface reserves the band's measured height (`CSTabBarProbe.dressAndMeasure()`, kept — it reads the live bar and applies the remainder once, on the `TabView`, which is better than most apps manage) |
| The edge | a **28pt fade to `bg0`** over the band. `scrollEdgeEffectStyle(.hard, …)` is replaced: `.hard` draws a delineated edge, which is why a card mid-scroll is currently sliced through its own glyphs at full ink with no signal that anything continues |

Because the band sits on the page's ground with a rule, there is nothing to float over and nothing to
guillotine: the audit's problem 10 stops being a mitigation and becomes a non-event.

## 12.2 Headers — one system, not two

**The product's own header wins; the system bar carries the back chevron and at most one action.**
Every pushed screen sets `navigationTitle("")`, exactly as the four tab roots already do, and
`CSPageHeader` names the screen. That ends the three cases where a title is drawn twice (the person
page, head-to-head, the Record) and gives the nineteen pushed screens currently naming themselves in
SF 17pt semibold the product's own voice for the first time. It is one modifier per screen and the
cheapest brand win in the audit after shipping the app icon.

**The page header's anatomy**: an `agate` eyebrow (optional, and it counts against the budget) ·
the name in `display` 34 or 24 · an `agate` dateline · one trailing action as a tertiary link.
Its AX3 branch stacks the three elements rather than letting them fight for one row (the shipped
`CSPageHeader` already does this and it is a "what works").

**Back** is the system back button everywhere — one affordance, verified identical on four pushed
screens, and there is no `chevron.left` in the codebase. Keep it that way.

**Toolbar grammar**: `topBarLeading` is back and nothing else; `topBarTrailing` is **one** action, as a
tertiary link in `name` 15; `principal` is never used. Three dismiss verbs in three colours at two
positions is the single most visible inconsistency a golfer meets, because they meet it on 84 sheets
and 11 covers.

## 12.3 The masthead

Home only, and it is the reason Home reads as an edition of something rather than a screen:
**the wordmark · the dateline in agate flush right · a 2pt `ink` rule beneath, full measure.** No ember
tick (the masthead is not live), no sky wash, no second ground.

**The wordmark keeps the canon setting: IBM Plex Mono 600, tracked 0.32em, always CAPS, at 30pt.**
`brand/README.md` states that setting as a rule, and `lockup-dark.png`, `lockup-light.png` (the
email/marketing default) and `og-image.png` are all **generated from it** by `tools/make-icons.py`. The
first draft set the masthead in the board face in one sentence and then claimed "the mark itself is
untouched by this document" — both halves of which were false: the product would have shipped two
different wordmarks, one on Home and one in every email, link preview and lockup, and **re-cutting a
wordmark is a brand decision** that `brand-canon` §6 explicitly reserves to the owner as an open
exploration brief. A design document does not get to close it in a sentence.

Keeping it also **gives mono the one job its demotion to ≈12% leaves it**, and it is the one place in
the product where tracked mono caps are unarguably right: the wordmark is a name, not a label, and it
is set once per surface on one surface. *(If the owner later re-cuts the mark in the board face, the
same pass must re-run `tools/make-icons.py` and `tools/make-og-image.py`, re-issue both lockups and the
og-image, and amend `brand/README.md`. That is a brand wave, not a UI change.)*

**The Tracer stays in the in-app header** — `brand/README.md` puts the mark on "every icon, the
favicon, the apple-touch icon, the maskable tile, the App Store square and the in-app header", and the
first draft's masthead carried no mark at all while §14.1 kept it in the desk's sidebar, so the flag
the Forge exists to manufacture appeared nowhere on the phone but the Compete tab. The masthead is
**the 22pt pennant, `s2` 8, then the wordmark**, on one baseline, with the dateline flush right.

**Its AX branch, which §16.3 also carries.** At the default size `CUP SEASON` at 30pt measures 169pt
and `SUN · SEP 6` at `agate` 11 measures 65pt — 234 of the 362pt measure, comfortable. At AX3 the
wordmark is capped at ×1.6 (48pt → 271pt) and even a capped `agate` dateline is 141pt: 412 into 362, so
the single row fails at AX2. **At AX1 and above the dateline leaves the wordmark's line and sets flush
left beneath it**, with the 2pt rule following both; the wordmark **wraps to two lines rather than
truncating**, because it is the product's name and §9.1's tail-ellipsis policy must never reach it.

---

# 13 · EMPTY, LOADING, ERROR, SUCCESS

## 13.1 Empty

**Anatomy, in order** — and the door is a **required parameter**, so the lint is the Swift compiler:

1. **A drawn object**, 56–76pt, at the icon family's stroke weight in **`mut`** — a blank scorecard, a
   rack, an empty rail, a `schedule-sheet`. Not an emoji, not an SF Symbol, not a shrug. It is the
   loudest thing on an empty screen and it should read like it; `rule` at 2.66 / 2.30 is a ghost, and
   `rule` separates but never states (§16.1). **Two absences never share an object** — the sibling of
   §5.2's "two achievements may never share a glyph": a blank scorecard means *you have no rounds*, an
   empty rail means *a board with nobody on it*, and `schedule-sheet` means *nothing is scheduled*. The
   glyph's name is also its accessibility label, which is why it is `schedule-sheet` and not "tee
   sheet" — a retired noun (`TERMINOLOGY` §4 pattern 13, T-03 as amended by A-8), and §4's scope
   covers `.accessibilityLabel`. *"The morning tee sheet" survives only as the light theme's canon
   name, never as a string.*
2. **An agate eyebrow** naming what this place is (`THE FIRST CARD`).
3. **A headline in `lead`** that is a **fact about the world**, never the golfer's omission:
   *"Nobody here has played it."* — not *"Nothing in the bag yet."* The test, from `UX_PRINCIPLES` §6 as
   amended: *could the golfer have prevented this sentence by doing something?* If yes, rewrite it.
4. **One true fact** in `body` 15 at `mut`, if one exists: *"Dinosaur Mountain is on the board because
   Galen keeps it."*
5. **One door**, and its type is `Door`, not `View?`:
   `CSEmpty(door: Door)` where `Door` is `.primary(String, () -> Void)` · `.link(String, () -> Void)` ·
   **`.elsewhere(String)`**, the last rendering a *reference line* rather than a control
   (*"The four doors are at the foot of this page."*). Never optional, never "Close", never nil-able —
   three current call sites pass a `cta` that goes nil when a link is missing, so the door silently
   vanishes on exactly the surfaces that need one. `.elsewhere` is what makes the parameter survivable:
   Home's quiet wire-empty genuinely has no door of its own (its door *is* the floor's lit door), and
   without a third case Phase 3 would either pass a dummy control or make the parameter optional and
   delete the lint.
6. **A number where one exists** — an unfilled star rail at full size, a `0` in a panel, a blank rail.
   Not one canonical empty state in the product today contains an image, a shape or a number.

## 13.2 Loading

**The destination's own geometry, redacted.** The real rows, the real heights, the rail slots and the
rules all present; the type replaced by `bg2` blocks at `p` 3 with real-length placeholder widths
(`.redacted(reason: .placeholder)`). **Never a spinner inside content** — the full-screen spinner beside
the word "Loading…" is deleted. A spinner inside a *control* is legal and stays: it is the control
saying it is working, and it is three mono dots that tally (§7.1).

### 13.2a The fold — a row is whole, or clearly half-scrolled, never sheared

**NEW after the blind review.** Filed on four surfaces by three reviewers: pairing rows "sheared
mid-row by the tab bar (+2.1 / −0.4 clipped)", a twelfth leaderboard row clipped under the chrome, a
course list's last row cut at 18pt of a 60pt row. A row showing a third of itself reads as a rendering
fault; a row showing two thirds under a fade reads as a list that continues.

**The rule.** The floating chrome is 74pt plus the home indicator; content is laid out so that at the
default size **the last visible row of any list is either fully clear of the chrome or at least half
visible under the scroll fade**. In practice that means every scrolling surface carries a bottom
padding equal to the chrome, and a surface whose content lands in the shear band loses a row rather
than showing a sliver of one. The `.fade` is what makes half-visible legible; without it, half a row
is still a fault.

## 13.3 Error and stale

**Keep what is on screen.** Cached content renders under an agate dateline reading
`AS OF FRI 6:12 PM · OFFLINE`, at `mut`, with **no action disabled**. `HomeView.swift:181-184` (the `C-10 · a failed read is never an empty one` comment and
`EmptyRoot.failedRead()`) and `:516-519` (`feedFailed = r.failed; if !(r.failed && !items.isEmpty)`)
already implement exactly this for the feed and are the precedent to generalise. *(`:287` is a route
switch; four documents cited it.)* Only with nothing cached does
the surface speak: one `lead` line in the product's voice, one `body` line, and **Try again** as the
primary. Server text renders verbatim when it is written for humans; never a raw code. The one designed
error surface the product has is thoughtful and its headline is "Boot stalled" — that headline is the
last thing to fix, and it should be fixed.

## 13.4 Success, and the toast

The toast is one shape at last — 133 `toast.show(...)` sites currently carry `id` and `text` and nothing
else, so "Round posted: +9 pts" and "Reaction did not save." are the same grey pill.

| | |
|---|---|
| Geometry | 46pt tall, `rc` 10, `bg2` fill, `body` 15 in `ink`, rolls out on `roll`, 2.4s |
| Kind | **a 3pt leading rail** — `pos` (confirmed) · `neg` (failed) · `rule` (neutral) — plus a **drawn glyph** at 17pt in the same colour. Shape and colour together |
| Action | at most one, as a `name` 15 link at the trailing edge (`Retry`) |
| What it is not | an arrival. A notification and a confirmation are different objects: the toast confirms **the golfer's own action**; something that happened elsewhere arrives as a row in the wire and as a badge (§8) |

---

# 14 · THE WEB DESK

Owner ruling **R-C**: the web is its own desktop-first shape — a sidebar and a wide two-column body —
built into `index.html`, never the phone's tabs reflowed. The visual system is the same; the density and
the column count are not.

## 14.1 The frame

- **Sidebar 236pt**, `bg0` with a 1px `rule` on its right edge: the mark and the wordmark at the top;
  nav items in `agate` 12 with a **3px `brand` tick on the left edge of the selected one** — the tab
  bar's underline, rotated; `THE DESK ▸` (the Pro's section) below a rule; the viewer's own face and
  index at the foot with the build identity (`v23 · <sha>`) under them.
- **Body: `1fr + 340pt`, gutter 40.** Left: the chapter line, the week ticks, the board. Right: the
  clash, the story as a list of weeks, the pot with its ledger line.
- **The visual language is the same; the shape is not.** The desk is a sidebar and a two-column body,
  and the second column carries facts the phone has no room for. R-C C-2 rejects "the phone IA
  reflowed" in as many words, and a 1440px screen with one column down the middle wastes the only thing
  the desk has.

## 14.2 Density

| | Phone | Desk |
|---|--:|--:|
| gutter | 20 | **40** |
| slat height | 50 | **56** |
| `display` | 34 | **42** |
| `story` | 20 | **21** |
| everything else | — | unchanged |

## 14.3 What the desk gains

- **The board carries two more columns**: `RDS · BEST · GAP · PTS · MONEY`, plus a **five-dot form
  column** inside the row (`pos` filled = beat your number, `rule` = did not) — LAST FIVE made scannable
  inside a row rather than as a separate block. That is the extra column the phone cannot afford.
  **Money in the desk table is ink with a word in the header**, never green and red.
- **The archive at length**, the season's story as a full column, the Pro's dials, and **print
  stylesheets** for the board and the settlement card — the archive test, made functional.
- **Faces above the table**, not only in it: the desk's own version of §6.3.

## 14.4 Hover, focus, keyboard

- **Hover** (guarded for touch with `@media (hover: hover)`): the slat's ground steps to `bg1` and its
  rail slot paints `bg2`. A link's 2px `brand` rule thickens to 3px.
- **Focus**: a **2px `brand` outline** on the whole slat, always visible, never suppressed. **Every
  hover state has a focus twin** — the shipped web has 40 hover rules and one `[disabled]` rule.
- **Keyboard**: `↑`/`↓` between slats, `→` opens the receipt, `/` focuses search, `g` then `t` jumps to
  the table, `Esc` closes.
- **The web's own system numbers to retire**: 492 `font-size` declarations across 36 values with zero
  type tokens; 114 boxed surfaces; 25 radii; zero spacing tokens; 90 hex and 84 rgba literals against
  24 colour tokens; 20 chip families; four icon systems; two `:root` blocks 2,287 lines apart. §26 of
  the brief is a **two-client instruction**: the tokens, the type roles, the spacing scale and the
  radii in this document are the web's too.

## 14.5 The nine roles as CSS, and the order the 25,000 lines change

R-C C-1 makes the web half of every wave non-optional (D234). Seven one-paragraph sections are not a
specification for a 25,000-line single-file client, so this is the table Phase 3 migrates against and
`web-desk.html` → `mockups/renders/desk/desk-season.png` is the 1440 × 900 artboard that proves it.

| Role | CSS class | `font` | `letter-spacing` | `line-height` |
|---|---|---|---|---|
| `figure` XL/L/M/S | `.cs-fig-xl` `.cs-fig-l` `.cs-fig-m` `.cs-fig-s` | `700 56/40/27/20px var(--type-board)`, `font-variant-numeric: tabular-nums` | 0 | .92 / .94 / .96 / 1.0 |
| `display` / `displayS` | `.cs-display` `.cs-display-s` | `700 42/24px var(--type-board)` *(the desk's 34 → 42)* | `.005em` / `.01em` | .98 / 1.05 |
| `name` / `nameS` | `.cs-name` `.cs-name-s` | `600 17/15px var(--type-board)` | `.035em` / `.04em` | 1.16 |
| `social` | `.cs-social` | `600 17px var(--type-board)` | 0 | 1.16 |
| `lead` / `story` | `.cs-lead` `.cs-story` | `700 28px` / `400 21px var(--type-serif)` | `−.01em` / 0 | 1.14 / 1.34 |
| `body` / `bodyS` | `.cs-body` `.cs-body-s` | `400 17/15px var(--type-sans)` | 0 | 1.45 |
| `agate` / `agateS` | `.cs-agate` `.cs-agate-s` | `600 12/11px var(--type-board)`, `text-transform: uppercase` | `.09em` / `.08em` | 1.20 |
| `column` M/S | `.cs-col` `.cs-col-m` `.cs-col-s` | `500 17/14/12px var(--type-mono)`, tabular | 0 / `−.01em` / 0 | 1.30 / 1.25 / 1.20 |

**The order.** (1) the two `:root` blocks merge into one and take the `space`, `alpha`, `track`,
`radius` and `type` groups from `tokens.json`; (2) the nine classes above replace the 492 `font-size`
declarations, largest first; (3) the 114 boxed surfaces resolve to band / rule / rail / panel / leaf,
which is where the 25 radii collapse to five; (4) the 20 chip families become `CSChip`'s one shape;
(5) the four icon systems become the drawn family; (6) hover and focus twins (§14.4). Each step is one
commit and each is greppable, so `LINT-05`, `-06`, `-07` and `-10` can be turned on for `index.html`
one at a time — see §17's adoption clause.

---

# 15 · SURFACE CHARACTERS

§31 of the brief is a rule, not a caveat: a design system does not mean every screen looks identical.
**Every surface opens with a different object.** These six paragraphs say what may differ.

## 15.1 HOME — social, dynamic. *The front page.*
The only surface with a **masthead and a dateline**, and the only one that mixes five item weights
deliberately. Its opening object is the wordmark over a heavy rule; its lead is the **one serif
headline** the product allows per viewport; and the ME strip is four figures on one rule with the
standing line in agate beneath. Below that, the wire runs at five weights — a competition moment (a
block with a panel and a movement mark), a friend's round (a photograph, a face, a gross panel), a
course discovery (a drawn-card thumbnail and a rating), a season moment (a takeover band), and minor
activity (one quiet line with a day marker). Its character is **rhythm**: band, rule, photograph, rule,
quiet line — so scrolling it feels like a rundown rather than a stack. It is the only surface where a
photograph appears above the fold by design. `cs-home-dark`, `cs-home-paper`.

## 15.2 PROFILE — identity, personal. *The credential.*
The one surface built around an **object** rather than a layout: a fixed-ratio card with a bleed, a
crest, a slot, a medallion, three figures on a rule and a folio, sitting on the page with a real lift
shadow. Everything under it is deliberately flat and quiet — the form row, then the record on a leaf,
then courses kept as slats — so the card is the only thing with depth on the screen. **No segmented
control**, because a golfer's record is not a fantasy player page. Character: **one object, then a
printed record.** `cs-profile`.

## 15.3 COURSE — editorial, discovery. *The plate.*
The only surface where an image or a drawing owns the top third edge to edge, the only one where the
name is reversed out of an image, and the only one where the serif is a **pull quote** rather than a
headline. The facts are **one line of type** — `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE` — never a
grid and never four hairline-divided cells. The rating is content (§9.11) and it is **`ink`, not gold**
— nobody earns an average of opinions. "Who of yours has played it"
is an overlapping disc row and a sentence that **names the friends** — which is what makes a course page
social rather than a database record. The front nine prints on a leaf. Character: **a spread in an
almanac.** `cs-course`.

## 15.4 SEASON — competition, narrative. *The board.*
Opens with an ember eyebrow and the season's name in `display`, then **the chapter line in the serif** —
the season's one sentence — then the week ticks, then the clash, then **the squad table (in a squads
season) above the individual table**, both as slats, then the pot
as a rule-and-figure in gold with the ledger line. **No card appears anywhere on it.** It is the surface
where the rank rail does the most work and where gold appears exactly twice (the leader's rail field and
the pot) — which is the budget's one sanctioned exception, because the two are the same fact. Character:
**story on top, board underneath.** `cs-season`.

## 15.5 EVENT — tournament, moment. *The title card.*
The only surface whose head is a **full-bleed ceremony plate** with the title at `display` 34–42 over
three agate metadata blocks, and the only one with a **countdown as figures on a rule** and a **field
rail of faces with names**. Its board carries `THRU` instead of `GAP`. Stakes are agate words with ink
figures; the pot is the gold object. Ember here is a live dot and a week number, never decoration.
Character: **the graphic that comes up before the coverage starts.**

### 15.5a Sides — the team is carried by the roster, never by a key

**NEW after the blind review.** All three reviewers filed the same failure on the Ryder surface, and
one called it a failure at the surface's one job: *"This is a team event and you cannot tell who is on
which team."* Sides were carried by two 14 × 4pt colour ticks that also collided with the date line;
the six roster discs beneath were coloured by **personal marker**, which is identity, not side.

**The law, and it resolves three findings with one change.** A team event's roster is drawn as **two
named groups**, each under a **full-width 3pt rule in its squad colour**, with the squad's name in
`agateS` beneath the rule (leading-aligned on the left group, trailing-aligned on the right). **Every
disc in a group carries a 2.5pt outer ring in its squad colour** while keeping its own pigment and
glyph inside. The colour ticks are deleted; the collision goes with them, and §16.4 is satisfied
because the squad is named in type as well as coloured.

**Identity and side are different channels and must stay so.** The disc's fill and glyph are the
golfer, forever, on every surface (§6.2a). The ring is the side, and it exists only inside a team
competition. Re-tinting a marker by side would trade one legibility failure for a worse one.

**And a countdown is not a score.** The three-up rail put `3½`, `2½` and `2 DAYS LEFT` under one rule
"as if they were one class of number". The rail carries the two side scores; the deadline moves into
the live eyebrow, where the other time facts already are.

## 15.6 HISTORY / THE RECORD — archive, achievement. *The almanac.*
The densest surface in the product and the quietest: 44pt slats, a year rule between sections, the
**leaf** carrying every table, `column` for every figure, **no ember at all**, and gold only under a
season that was won. The drawn card appears at thumbnail size beside each course (nine bars, §10.2).
**Every achievement draws its own glyph and none of them is the pennant** (§5.1, `LINT-28`). Character:
**printed, and meant to be read in 2046.** The archive test, made into a screen.

## 15.7 The rule that keeps §31 true below the fold

Each of the six paragraphs above describes a surface's **top 300pt**, and the first draft of this
system abandoned §31 beneath it: scroll `home-quiet`, `season-money`, `event-setup` and `profile-top`
past their heads and they converge on one unit — a 44–60pt hairline-separated row with a bold label
left and a small tracked-caps gloss right. That swaps "card everywhere" for "rule-separated row
everywhere": a better default, still a default.

**So the two surfaces whose character is most distinct spend a material below the fold, not only above
it.** **COURSE** runs *courses kept* and the front nine on the **leaf**, as a ruled table, rather than
as slats on the ground; **HISTORY** runs the record as a **book page** for the same reason. And
**HOME** shows at least three of its five wire weights *below* the fold on a real artboard, because its
character is **rhythm** and rhythm is only visible where a golfer actually scrolls.

---

# 16 · THE ACCESSIBILITY FLOOR

## 16.1 Contrast

- **Every text/ground pair in §2.8 meets AA (4.5:1) at the sizes it is used.** `ink` 16.05/15.49,
  `mut` 7.07/5.85 — and `mut` is the **only** secondary tier, because `dim` fails AA and `dimText`
  already resolves to `mut` at 206 of 224 sites.
- **`dim` and `rule` are declared non-text** and may never carry a word. The tertiary tier the brief
  asks for is expressed by **size, case, position and reveal**, never by a dimmer grey. Every remedy in
  the audit that says "demote to a dimmer grey" is fenced by this. `dim` measures **3.15:1 dark and
  2.89:1 light** on `bg0` — below AA at any size, and below 3:1 even as large text.
- **`dim` is deleted from every text position product-wide, and the three sites that had one are named**:
  Home's wire **day marker** (`TUE`, `MON`) → `agateS` at **`mut`**, taking its quietness from size,
  column position and the row's rule, which is what this section already promises; the credential's
  **folio** → `folioRule` `#8B8F8B`, the opaque value `ceremonyInk` at `a56` composites to (5.92:1); a
  **disabled chip's label** → `mut` on `bg1` (6.21 / 5.30). `dim`'s job line in §2.1 loses "a day
  marker". `LINT-29` fails the `dim` token inside a `Text(` or a `.foregroundStyle(` applied to a string.
- **`rule` may separate. It may never state.** `rule` is 2.66:1 dark / 2.30:1 light and the first draft
  gave it four jobs that are *state*, not separation: the season clock's not-yet-played ticks (the
  majority of the row, and only 2.66 / 2.54 against the played ticks — one tone step carrying the whole
  meaning); the **held** movement bar (a 9 × 2pt mark that is neither a shape nor visible, so "held"
  and "no data" look identical); the **empty state's drawn object** at 56–78pt, the single device
  answering brief §17; and the unplayed cells of the live sheet's hole strip. WCAG 1.4.11 asks 3:1 of a
  graphic needed to understand content and none of the four reached it in either theme. **All four take
  `mut`** (7.07 / 5.85). §8, §9.3, §13.1 and §9.4 are amended to match.
- **The `bg2` column is a review item**: `brand`, `cool`, `gold` (light) and `pos` (light) do not reach
  4.5:1 on `bg2` and may sit there only as a fill, a rule or a glyph with a label.
- **On the `ceremony` ground every token resolves to its DARK value, in both themes** — the ceremony
  ramp of §2.1 and §2.8. The light theme does not reach inside a physical object. `ink`'s light value on
  `ceremony` is 1.11:1; before the ramp existed, the credential's `FOUNDER` slot was 3.05:1, the event's
  live eyebrow 3.19:1 and the event's dateline 2.94:1 in light, while the mockups painted the dark-room
  values a token could not produce. **The review checks four objects by name**: the credential's shared
  three-figure rule (`ceremonyInk`, never `ink` — 17.51:1), the medallion's ring (`ceremonyGold`), the
  event's dateline (`ceremonyMut`), and the folio (`folioRule`).
- The one legitimate exception, kept: the landscape scorecard's HOLE and SI rows, where par and stroke
  index are the reference the score is read against, may use `dim` — 11 sites in one file, already
  isolated.

## 16.2 Sizes and targets

- **Nothing renders below 11pt at the default size.** `agateS` and `columnS` are the floor and they are
  11 and 12.
- **44pt minimum touch target**, `rail` = 44 by construction. The three known misses are named and
  fixed: the composer's "Start over" (a ~20pt line box, because its frame modifier is inside a comment),
  the live round's CARD/HOLE strip (~22pt), and the composer's golfer chips (~36pt, where the sibling
  sheet's are 44).
- **Every role is `relativeTo:` a text style.** Growth caps exist on **`figure`, `display` and
  `agate`** (§1.2 gives the mechanism and the arithmetic for each); `body`, `column`, `social`, `lead`
  and `story` **never cap**, because those are the roles a golfer reads for meaning.
- **The star rail is the one target carve-out, and it is stated rather than asserted.** Five stars ×
  two halves is ten discrete targets; ten × 44pt is 440pt against a 362pt measure (335 on an SE), so
  "44pt minimum per half" is a sentence the geometry cannot deliver and Phase 3 would build the
  geometry. **The rail is a continuous 362 × 56 drag target** (`DragGesture(minimumDistance: 0)`
  mapping *x* to the nearest half) with a **−½ / +½ stepper pair at 44pt beside it** for the tap case;
  the half-star hit region is 28pt, above WCAG 2.5.8's 24 × 24 and below this document's own 44, and
  the stepper is what makes that legal. `.accessibilityAdjustable` with 0.5 increments, plus
  `.accessibilityValue("four and a half stars")`.

## 16.3 AX3, per layout — stated as layouts, not as principles

No Phase-2 direction rendered an AX3 artboard; `cs-system-c` does, and this is what Phase 3 builds to.

| Layout | Default | AX1 | AX3 |
|---|---|---|---|
| **The masthead** | pennant + wordmark + dateline flush right, on one baseline over the 2pt rule | **the dateline leaves the line** and sets flush left beneath the wordmark; the rule follows both | as AX1, and the wordmark **wraps to two lines rather than truncating** — it is the product's name, and §9.1's tail-ellipsis policy never reaches it |
| **Any `agate` line** | one line, `·`-separated clauses | capped at ×2.2 (11 → 24.2pt) | capped; a multi-clause line that still does not fit **breaks on its `·` separators into stacked lines** and the block grows the page |
| **The lead block** | headline + standfirst left, panel right | panel drops below the standfirst | **the panel goes full width, above the headline**, its numeral and label side by side with the movement mark; the headline follows |
| **The ME strip / any figures-on-a-rule** | 4 cells on one rule | 2 × 2, each pair on its own rule | a stacked list, each cell a slat with the label leading and the figure trailing |
| **The slat** | rail · face · name/sub · move · gap · pts | as default | the **rail keeps its 44pt width** — `figure` 27's ×1.45 cap puts two digits at 42.3pt inside it (§1.2, §9.1) — and the row grows its *height*, not its columns; move, gap and pts move under the name as one agate line; `minHeight` becomes intrinsic. One VoiceOver element throughout |
| **The credential** | **362 × 312, measure-relative** | as default | the three figures stack to three rows and **the object grows the page** — it never scrolls inside itself |
| **The tab bar** | glyph + label | glyph + label | **labels drop, glyphs grow to 28**; the band keeps its rule and its inset |
| **A section head** | label + rule + count | as default | the count wraps under the label; the rule stays |
| **Any table** | column heads shown | shown | **column heads hide**; each row speaks its own facts |

`ViewThatFits` is 0 in the product today and `horizontalSizeClass` appears twice, both meaning "is the
phone sideways" — SE, 17 Pro and Max render the identical view tree. The model to copy already exists:
`MeStripLayout` reflows on the **measured advance** of its own characters at the size the golfer is
reading, not on a device breakpoint. Generalise that, not a breakpoint table.

**The 375pt measure (SE), stated once here so six surface specs stop guessing.** The slat's fixed
columns — rail 44 + face 30 + `s3` 12 + movement 30 + gap 46 + points 52 + gutter 20 = **234pt** — leave
168pt at 402 and **141pt at 375**, which is 62% of an SE's width spent before a character of a name.
Therefore, product-wide:

- **Every fixed column in the slat is derived from the measure, not hard-coded**; the name is the only
  flexible column, and the viewer's row reads `YOU` alone (§9.1).
- **The credential and the leaf are measure-relative** — the *ratio* is fixed, the width is not.
  362 × 312 becomes 335 × 289 on an SE.
- **The course leaf's ten-column front nine** goes from 36.2 to 33.5pt per column and keeps its grid;
  below 335 the back nine wraps to its own leaf.
- **The event's six-disc field rail wraps to two rows of three below 390pt** — and it is already drawn
  as two named squad groups (§16.4), so the wrap is the groups stacking.

## 16.4 Colour is never the only channel

Four repeating marks in the product currently carry meaning in hue and fill alone. Each gains a second
channel here:

| Mark | Second channel |
|---|---|
| movement | **shape** — a triangle up, a triangle down, a bar for held (§9.3) |
| the last five | **position and the gold rule** — the figures are the data; the best is marked by a rule, not only by hue (§9.7) |
| a score's quality | **the drawn ring or box** (§9.4) — the only scorecard language, and it has no colour at all |
| a squad | **a swatch plus the squad's name in agate**, never colour alone — mandatory, because the four squad marks are only **1.58:1** apart (§2.2a). Where faces are grouped by side (the event's field rail) the surface draws **two labelled groups**, `SAGUAROS` in agate over three discs and `COYOTES` over three, not one space-between row of six |
| a link | **the rule beneath it**, never hue alone — and the rule must reach **3:1** against its ground, which is why the quiet variants are `mut` and never `rule` (§7.1) |
| **an unscored cell** | **position** — the numeral seat stays empty and the hole's par hangs *below* the rule in `agateS` `mut`, where a scored cell carries nothing (§9.9). This is the highest-stakes mark in the product and it was the one missing from this table |

**Every drawn indicator carries an accessibility label** written in the product's voice — 242 labels,
72 hints, 103 elements and 62 traits already are, and that is better work than most shipping consumer
apps do. The landscape scorecard's single label for 18 columns is the one hole to fill.

## 16.5 The other four iOS switches

Brief §25 asks for an accessibility audit; the first draft answered contrast, size, targets and
colour-only well and then stopped at `accessibilityReduceMotion` — one of iOS's five settings. This
design is unusually exposed to three of the other four.

| Switch | Why this design is exposed | The answer |
|---|---|---|
| **Bold Text** | a `.custom()`-registered face **does not respond to `legibilityWeight` at all**, so a golfer who turns Bold Text on gets a heavier SF body against an unchanged Plex Condensed board — the hierarchy inverts on exactly the voice the identity depends on | `@Environment(\.legibilityWeight)` moves `agate`, `name` and `social` from SemiBold 600 to **Bold 700**. `figure` and `display` are already 700 and **both cuts are already bundled**, so it costs nothing new |
| **Increase Contrast** (`accessibilityDarkerSystemColors`) | a palette with `mut` at 5.85 in light and a dozen marks between 2.3 and 3.4 has no darker variant | `mut` → `ink` at `a88` · `rule` → `mut` · `a56` → `a88` · `a24` → `a56`. Four substitutions, resolved in `Theme.swift` |
| **Reduce Transparency** | the folio at `a56`, the crest at `a24`, the contour at `a56` and the photo scrim are the **entire texture** of the credential and the title card | each resolves to its **composited opaque value** (`folioRule` `#8B8F8B` is already computed and named); the scrim becomes a solid band at the darkest stop |
| **Reduce Motion** | already handled | both curves resolve to `nil`, never "faster" (§11.2) |

## 16.6 Two capture blockers Phase 3 must clear before it signs anything off

Neither is fixed by design and both invalidate a claim until they are: **(1)** the light theme has
never been rendered on a device — `CupSeasonApp.swift:15,27` applies `preferredColorScheme` from
`UserDefaults`, so `xcrun simctl ui … appearance light` never reaches the UI and every light-theme
statement in this document is computed, not seen; **(2)** AX3 has never been rendered — the
`-UIPreferredContentSizeCategoryName` launch argument does not take. **Add a launch-argument hatch for
`CSAppearance` and for the content-size category before the Phase 3 review**, or the review is blind on
two of its axes.

---

# 16A · THE COPY LAWS THE VISUAL SYSTEM ENFORCES

*Added after the blind review. These are not writing guidelines; each one is a rule about how many
times a thing may be **drawn**, and each was filed by two or three independent reviewers who had never
read this document.*

## 16A.1 A sentence that is a policy is printed ONCE, on the surface the policy governs

`Cup Season keeps the ledger; the money moves between friends.` appeared on **eight of thirty-four
renders**, twice on one screen 250pt apart, and on three leaderboards, a profile, an event and Home.
Every reviewer filed it; one wrote that it "is a legal line being used as a layout element", another
that repetition "makes the page look auto-generated rather than composed".

**The law.** The ledger line is drawn **once per client**: in `agateS`, at the **foot** of the money
surface — above the tab bar on the phone, under the pot in the desk's right column — under a hairline.
Two clients, two shapes, one printing each; that is D234's rule applied to a sentence rather than to a
layout. In the artboards it now appears exactly twice in thirty-four renders, against eight before. It is not a caption, not a subtitle, not filler
under a stat rail, and it never appears on a surface whose subject is not money. The same law governs
any future sentence of the same kind (a rules footnote, a disclosure, an eligibility clause): **one
surface, one printing, at the foot.**

## 16A.2 A section names its count ONCE, in the right-of-rule slot

Two reviewers found `COURSES KEPT — ELEVEN` followed three lines later by `ALL ELEVEN`, and
`THE POT · 8 IN AT $60` beside a link reading `ALL EIGHT`. The count is data; the door is a verb.

**The law.** The **right-of-rule slot on a section head carries a count and nothing else** — not a
date, not a range, not a filter, not a link. Two reviewers separately found that slot carrying counts
(`THREE`, `ELEVEN`), a range (`WEEK 5 OF 13`), a filter (`LAST FIVE`) and a date (`SINCE 2026`) on one
screen; one wrote "reserve it for one job". The **door beneath a section never repeats the count**:
`THE REST`, `THE OTHER EIGHT`, `EVERY RIVAL`, `THE SPLIT` — never `ALL ELEVEN` under a slot that
already said `ELEVEN`.

## 16A.3 An unlabelled number column is a defect, not a minimalism

Filed on four surfaces by three reviewers: `11` and `77` beside a course name; `3/4` and `1/2` on a
board; `81 / 86 / 88` down a course list; signed differentials where lower is better with the
explanation 800pt away. **Every column of bare figures carries a head in `agateS`, right-aligned over
the column it names**, and where the sign convention is counter-intuitive the head says so
(`VS YOUR NUMBER · LOWER IS BETTER`). A column head is four words; a support ticket is not.

## 16A.4 One fact, one encoding, per viewport

Home stated the reader's rank **three times in 400pt** — in the headline, in the chip, and in a
`▲2 SPOTS` rule-and-figure that shared a baseline with an unrelated link. All three reviewers filed
it; two named it the surface's largest single waste and one measured it as forcing a three-line wrap
in the column beside it.

**The law.** A fact is drawn once per viewport, in the object that owns it. Rank is owned by the
**chip**, which now carries the figure, the ordinal and the movement in one block
(`2ND / ▲2 / OF EIGHT`); the headline may *say* it in prose because prose is a different channel, but
a third, graphic encoding of the same number is deleted. The corollary the same reviewers asked for:
**a numeral rail holds numerals.** `Mon` in a rail beside `10.6`, `84` and `$75` "reads as a rendering
error"; a next-tee time is a **dated row in the wire with a chevron**, where dates live.

## 16A.5 One primary per surface, and the alternative is a link

Two reviewers filed a credential carrying an orange `ADD BUDDY` beside a filled `PLAY TASH` — "two
orange-weight decisions where one belongs". §7.1's three tiers already say this; what was missing is
the **count**: one tier-1 object per surface, and the second action is tier-3 (a text link on a rule),
never tier-2, on any surface small enough to see both at once.

## 16A.6 An un-chosen option is never pre-tinted

`event-setup` drew its first option in `brand` while nothing was selected; two reviewers read it as
"already selected". **Accent on an option means chosen or recommended, and a recommendation carries
the word.** Otherwise every option in a list is set at the same weight, and the list's *order* does
the arguing.

## 16A.7 An empty state is written, never an orphan glyph

`THE WIRE` followed by a drawn table icon and nothing else was read by two reviewers as "an unfinished
empty state on the flagship screen" and "a failed image load". §13.1's empty state is *a drawn object,
a fact about the world, and a door* — **all three, or none**. A glyph alone is a broken image; a glyph
plus a headline plus a door is a composition. Where a page already carries a drawn object of its own
(the course page's drawn card), the empty state drops the glyph and keeps the sentence.

---

# 17 · THE LINT

The audit's real finding is that the components that exist are good and are ignored — 34 component uses
against 338 hand-rolled shapes. **A rule a preflight cannot fail is a wish.** These extend
`tests/preflight.mjs` (checks 15–17 are already the Swift siblings of the web's palette, OTP and RPC
checks) and run over both clients.

**The checks are named `LINT-nn`, not `L-nn`.** `UX_PRINCIPLES.md` already owns a live `L-01…L-45`
namespace and 26 of the ids collided — the surface specs cite both in the same paragraphs, so a Phase 3
engineer reading *"correct under L-25 (all four doors, always)"* would look up this table's L-25 (one
dismiss verb) and be wrong. One prefix, one sweep of the seven specs.

**Two mechanisms, because five of these are not greps.** `LINT-01…07`, `09…14` and `20…29` are greps
over source. **`LINT-08`, `15`, `16`, `17` and `18` are render-time probes**, because in a component
codebase a *viewport* is assembled from a dozen files and a grep scoped to "one view file's body" counts
the wrong thing in both directions: Home's agate lines come from `CSMasthead`, `CSStoryCard`,
`CSFactStrip` and `CSSectionHead` — one apiece, so a per-file grep counts 1 four times and passes while
the screen carries fourteen; `CSSlat`'s exempt sub-line is counted against its own file; the gold rail
lives in `CSRankRail.swift` and the pot in `CSFigure`, so a grep sees **zero** gold in `SeasonPage.swift`,
the surface that carries two; and a grep cannot see a `CSPanel` inside a `CSStoryCard` placed inside a
`CSPlate` at the Home level. **`CSBudgetProbe`** is a `PreferenceKey` that `CSType.display`,
`CSType.agate`, `CSType.agateS`, the gold-taking components and `CSButtonStyle.primary` increment as
they render; every root asserts it under `#if DEBUG`, and the preview snapshot tests assert it in CI.
The budgets that carry the identity are then counted on the thing they are about — a screen.

**And they land with a baseline, or they land nothing.** The twenty-nine checks fall on roughly **2,300
existing sites** (`LINT-06` 1,387 · `LINT-10` 354 · `LINT-14` 189 · `LINT-07` 182 · `LINT-09` 162 ·
`LINT-05` 113 · `LINT-03` 80), and `CLAUDE.md` states that `ship.sh` "refuses to ship anything if
preflight fails" — so the commit that adds them blocks every push, including Phase 3's own migration
commits, and Phase 3 is a multi-session build. **Each check gets an entry in
`tests/preflight-baselines.json` holding today's count and fails only when the count RISES**, hardening
to zero-tolerance the moment its baseline reaches 0. `preflight.mjs` already has the pass/fail shape to
carry it. **The hardening order** is the order the migration touches the code:
`LINT-01/02/04` (already zero) → `11/12/13/23/25/26` (small, high-value) → `03/05/10` (with the
component rewrites) → `06/07/14` (with the type and spacing sweep) → `08/15/16/17/18` (the probes, once
`CSBudgetProbe` exists) → `09/19/20/21/22/24/27/28/29`.

| # | Check | Fails on |
|---|---|---|
| **LINT-01** | grep · no face by PostScript string | `.custom("` outside `CSFont.swift`'s single face constant |
| **LINT-02** | assert · the bundled faces resolve | a launch assertion that each PostScript name returns a non-system face (D258's regression test), **plus a tabular assertion**: render `0000000000` and `1111111111` in the bundled face and assert equal advance. `csTabular()` is `.monospacedDigit()`, which is documented for *system* fonts; on `Font.custom` it resolves through the descriptor's `kNumberSpacingType` feature and works only if the face carries it — and every column in this system (the rail, points, the gap, the form row, the receipt) depends on it, while all 69 existing sites sit on Charter. If the assertion fails, `csTabular()` applies the feature explicitly via `UIFontDescriptor.featureSettings` instead of relying on `.monospacedDigit()` |
| **LINT-03** | grep · no bare system font | `.font(.system(size:` anywhere outside `CSFont` |
| **LINT-04** | grep · no colour literal | an invented hex or `Color(red:` outside `Generated/Tokens.swift` *(check 15, exists)* |
| **LINT-05** | grep · no radius literal | `cornerRadius: <number>` — every radius comes from `p/rc/r/rs/rx` |
| **LINT-06** | grep · no spacing literal | a number in a `padding(` or `spacing:` position that is not in the `space` group |
| **LINT-07** | grep · no tracking literal | a number in a `.tracking(` position. **`CSType`'s own computed call is the one exemption** — tracking is a ratio of the *scaled* size (§1.2), so exactly one call site multiplies |
| **LINT-08** | **probe** · no container in a container | a `CSPanel` / `CSLeaf` / `CSPlate` rendering inside another of the three, counted through `CSBudgetProbe` at the root, not by a per-file grep |
| **LINT-09** | grep · no border | `.stroke(` outside `CSFocusRing`, `CSFace`, `CSLeaf` (light) and the scorecard marks |
| **LINT-10** | grep · no rounded rectangle | `RoundedRectangle(` / `Capsule(` outside `CSDesign` |
| **LINT-11** | grep · **no gold on a control's own chrome** | the `gold` token inside a **`ButtonStyle` body**, or inside a `.tint(` / `.background(` / `.foregroundStyle(` applied to a `Button`'s label **root** — **not** any gold reachable from a `Button`. Every slat is a `Button` (`FriendsBoard.swift:65` is literally `Button { … } label: { … }`, and `profile.md` D-8 makes the whole row the target), so the naïve form failed the leader's gold rail, the course row's gold star rail and the record leaf's earned rules — the three objects §2.4 exists to protect. `CSRankRail` and `CSLeaf` are whitelisted by name; `CSButtonStyle.gold` must not exist |
| **LINT-12** | grep · **no emoji on a shared surface** | AP-5 as amended by D326 — a mark others see is drawn; the post-round epilogue and a golfer's own typed content may carry a glyph. No file is exempt: the `Reactions.swift` skip came out on 2026-09-09 once D309's four drawn tokens left it with nothing to exempt |
| **LINT-13** | grep · no typed arrow | the arrow set **`→ ← ▲ ▼ ↑ ↓ ⇧ ⇩`**, plus `\^\d` and `\bv\d` for the ASCII caret forms, inside a produced string; **explicitly exempt: `−` (minus), `–` (en dash), `—` (em dash)**. *(A bare `v` matched `RyderMath.mid`'s "vs", `CSBands.vsShort` and every literal containing the letter, and a bare `^` matched every regex literal in the codebase: the check as first written failed thousands of innocent strings and would have been disabled on its first run.)* **It touches five producers, not three**: `StandingsMath.swift:94` (`Movement.text`) and `:117` (`RankMove.label`, `"▲2"`), `LeagueCopy.indexSub` (`"▼ 0.3 this season"`) and the You stats' `deltaText` (`"▼ 0.3"`) — the last two put the "you fell" glyph on a **falling handicap index**, which is good news — and all five are asserted by tests (`LeagueRoomTests.swift:446`, `RoundsYouTests.swift:372`) that must change with them |
| **LINT-14** | grep · no uppercasing in a string | `.uppercased()` on a display string — case is a role's job |
| **LINT-15** | **probe** · the agate line budget | more than **ten** tracked-caps `agate`/`agateS` **lines** rendered in one viewport, by §1.5's counting rule. Sentence-case `agate` and the tab band do not increment |
| **LINT-16** | **probe** · one display per viewport | more than one `CSType.display` rendered in one viewport. `displayS` is a different symbol and does not increment |
| **LINT-17** | **probe** · one gold object per viewport | more than one gold-taking component rendered in one viewport, with the season's leader-rail-plus-pot pair whitelisted by name |
| **LINT-18** | **probe** · ember discipline | more than **two** ember marks in one viewport, counting **every** `brand` fill, rule, glyph, dot and word **except the tab band** (a live dot plus its own eyebrow counts as one). The fill-only version could not see the four screens whose only ember was the word `CLOSE` |
| **LINT-19** | grep+probe · a panel never holds a sentence | a `CSPanel` whose content string exceeds 12 characters or contains a space. *(The first draft said "a string with a space and a verb", which is not a grep.)* |
| **LINT-20** | grep · a leaf always holds a grid | a `CSLeaf` with no `Grid`/`HStack`-of-columns child |
| **LINT-21** | compiler · the door is required | `CSEmpty(door:)` takes a **non-optional `Door` enum** with `.primary` / `.link` / `.elsewhere` (§13.1). The Swift compiler is the check |
| **LINT-22** | grep · no spinner in content | `ProgressView(` outside a `ButtonStyle` |
| **LINT-23** | grep · the ledger line is one constant | any string literal containing "keeps the ledger" outside `MoneyCopy.ledger` / `CS_LEDGER` |
| **LINT-24** | grep · pushed screens do not name themselves twice | a file containing both `CSPageHeader` and a non-empty `navigationTitle` |
| **LINT-25** | grep · one dismiss verb | a toolbar item whose label is "Done", "Cancel" or an `xmark` inside a sheet |
| **LINT-26** | grep · photos are not avatars | a `rounds.photo_path` URL passed to `CSFace` |
| **LINT-27** | grep · **no retired term in a produced string** | any of `TERMINOLOGY.md` §4's **34 patterns** in any string this document or its surface specs produce — including `.accessibilityLabel`, which §4's scope explicitly covers. The 34 are run over `UI_SYSTEM.md`, the seven surface specs and the seven mockups **before Phase 3 opens**, not after: five of the six hits found in this design's own copy were written into specs Phase 3 builds from without asking questions |
| **LINT-28** | grep · the pennant is reserved | the `pennant` glyph outside `CSTabBand` and the app-icon asset (§5.1) |
| **LINT-29** | grep · `dim` is never a word | the `dim` token inside a `Text(` or a `.foregroundStyle(` applied to a string (§16.1) |

---

# 18 · GLOSSARY — the names the build must use

The visual objects, and the `COMPONENT_SYSTEM` pattern each one clothes. **Phase 3 uses these names in
code.**

| Name | Swift type | What it is | Clothes |
|---|---|---|---|
| **the band** | `CSBand` | a full-bleed tone or ceremony field, radius 0 | the takeover, the masthead area, a ceremony |
| **the rule** | `CSRule` | the 1px hairline; `.heavy` is the 2pt ink rule | replaces `CSHairline`, `Divider()` |
| **the rail** | `CSRankRail` | the 44pt rank column with its three field states | P-5 `CSTableRow`'s first column |
| **the slat** | `CSSlat` | the leaderboard row: rail · face · name · move · gap · pts | **P-5** `CSTableRow` |
| **the panel** | `CSPanel` | the bone tile, one figure or one word, ≤96×96 | the hero figure on P-1, P-2, P-13 |
| **the leaf** | `CSLeaf` | the paper sheet, printed grids only | the scorecard, **P-16** `CSMathRow`, the record, **P-14** `CSShareCard` |
| **the plate** | `CSPlate` | an image field: photo, drawn card, contour | **P-1** `CSStoryCard`'s image, the course hero |
| **the object** | `CSObject` | radius 16 + `shadow-lift`; the credential, the settlement card | the card |
| **the rule-and-figure** | `CSFigure` | figure + 2pt rule + agate label; `.ink` / `.live` / `.earned` | every number in P-10, P-13, P-15 |
| **the figure run** | `CSFigureRun` | a numeral set in the board face inside a sentence | P-1, P-3 |
| **the face** | `CSFace` | the pigment disc, the only legal way to draw a person | **P-7** `CSPersonRow`, P-3, P-5, the field |
| **the medallion** | `CSMedallion` | the gold marker disc on an owned object | the credential, a round photo |
| **the credential** | `CSCredential` | the player card, front and back, **362 × 312** (§6.5) | the You hero, the card sheet |
| **the movement mark** | `CSMovement` | drawn triangle + tabular numeral, or the held bar | P-5's movement column |
| **the score mark** | `CSScoreMark` | ring / double ring / box / double box, in ink | the scorecard, the receipt |
| **the season calendar** | `CSSeasonCalendar` | the season's month/week clock — N week ticks with their month labels; **supersedes `CSTickRow`**, which is retired into it | **P-4** `CSChapterHead`'s month |
| **the clash** | `CSClash` | two faces facing across one rule-and-figure; **no boxes** (§3.1) | **P-6** the week's clash, the Ryder callout |
| **the cut** | `CSCut` | the field's cut line inside a board | the event's board |
| **the hole strip** | `CSHoleStrip` | 18 cells on one rule, marks only, ≥20pt, single ring/box (chart 4, §9.10) | the live round |
| **the standings board** | `CSStandingsBoard` | a column head row + N `CSSlat`s + an optional `CSCut` | **P-5** at surface scale |
| **the meeting tape** | `CSTape` | ticks above and below one rule, viewer filled / rival outlined, no legend (chart 5, §9.10) | head-to-head |
| **the course plate** | `CSCoursePlate` | the course hero: plate + `CSPhotoScrim.title` + the reversed name + the credit | the course page |
| **the course facts line** | `CSFactsLine` | `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE`, one line of type | the course page |
| **the rating** | `CSRating` | the rule-and-figure at 40 in `ink` + `CSStarRail` + the sentence + the link (§9.11) | the course page, the rating sheet |
| **the star rail** | `CSStarRail` | five drawn stars, filled `ink` / unfilled `rule`, half by clipping; the 362 × 56 drag target + a 44pt stepper pair (§16.2) | ratings |
| **the pull quote** | `CSQuote` | the course page's one serif appearance | the course page |
| **the folio** | `CSFolio` | the credential's rule + serial line, `folioRule` | the credential, the share PNG |
| **the tick row** | *retired* | see `CSSeasonCalendar` | — |
| **the section head** | `CSSectionHead` | agate label + rule + optional count | **P-12** (revised) |
| **the masthead** | `CSMasthead` | wordmark + dateline + 2pt rule | Home only |
| **the page header** | `CSPageHeader` | eyebrow + display name + dateline + one action | every pushed screen |
| **the me strip** | `CSFactStrip` | four figures on one rule + the standing line | **P-15** |
| **the stake line** | `CSStakeLine` | money in ink, the sign as a word, the pot in gold, the ledger line | **P-10** |
| **the chip** | `CSChip` | 28pt, radius 3, agate; selected inverts to the panel | filters |
| **the slot** | `CSSlot` | a 24pt gold field with panelInk agate | an earned label |
| **the door** | `CSDoor` | a primary, a secondary or a tertiary link | **P-8** `CSIntentDoor`, P-11's required action |
| **the empty** | `CSEmpty` | drawn object + eyebrow + lead + fact + door | **P-11** |
| **the toast** | `CSToast` | 46pt, leading kind rail, drawn glyph, one action | success and failure |
| **the tab band** | `CSTabBand` | the full-width band with a rule and a drawn glyph set | the chrome |
| **agate** | `CSType.agate` | the metadata voice | every eyebrow, dateline, label, column head |

**Retired names**: `CSCard`, `CSHero`, `CSStat`, `CSMini`, `RoomMini`, `MiniButton`, `MiniPill`,
`PostSeg`, `WizardSeg`, `EventSeg`, `FlowSeg`, `LiveSeg`, `ArmedMini`, `CSButtonStyle.gold`,
`CSEmptyState`, `RoomSpark`, `CSLookSky`, `shadowRest`, `pviChip`, `CSTickRow`.

**Retired *words*, and they are as binding as the type names.** "the Tour Card" → **the card** /
`CSCredential` · "duel" → **the clash** · "session" → **Week n of N**, or the date range · "floor" →
**the monthly minimum**, or the consequence · "Post a round" as a control label → **Add my round** ·
"tee sheet" → **the schedule** (`schedule-sheet` as a glyph name). Every one of these is a
`TERMINOLOGY` §4 pattern with a preflight behind it (`LINT-27`), and every one of them had drifted back
into this design's own copy.

---

# 19 · THE MOCKUPS, AND THEIR KNOWN IMPERFECTIONS

`system-mockups/system-mockups.html` → `system-mockups/renders/` (the system specimens), and
`mockups/*.html` → `mockups/renders/` (the seven surfaces, 32 artboards). Phone artboards are
402 × 874 (the iPhone 17 Pro logical size); `mockups/web-desk.html` → `mockups/renders/desk/` is
**1440 × 900**, rendered at 2×. The fixture cast is Sam Ridley, Galen Marr, Jade, Dev Rana,
Tash Bell and Mike Fenner; the leagues are The Fellas and The Dew Sweepers; the courses are Papago, Gold
Canyon (Dinosaur Mountain), Troon North and Desert Mountain.

| Artboard | What it proves |
|---|---|
| `cs-home-dark` | the masthead and dateline · LIVE as a dot and an eyebrow, **not** a band · the serif lead · the panel and the drawn movement mark · the ME strip as four figures on one rule with the standing line and the ledger line · the wire at three weights with a photograph, a face and a drawn-card thumbnail · the tab **band** with the ⊕ as an ember glyph |
| `cs-home-paper` | the light theme as a **second printing**: warm stock, bronze gold, stamp-red ember, and the panel inverted to ink while the photograph keeps its own dusk |
| `cs-season` | the rank rail in all three field states · faces in every table row with six pigments · the gap column · the movement marks with no tinted field · the week ticks · the pot as a gold rule-and-figure with the ledger line · no card anywhere |
| `cs-profile` | the credential as an object on the ceremony ground: crest, gold slot, medallion clear of every seam, three figures on one rule, **the folio** · the form row with the best in gold · **the record printed on a leaf**, with the gold rule marking what was won |
| `cs-course` | the photograph as the opening object · the facts as **one line of type** · the rating as content with a drawn star rail · the overlapping disc row and the sentence that names the friends · the front nine on a leaf |
| `cs-system-a` | the nine type roles at size · the rule-and-figure in its three variants · the panel at three sizes with its tripwire · **the scorecard ink law** · the six pigments and the medallion |
| `cs-system-b` | the three button tiers and their states · the chip and its inversion · the field with label, caption and error in sentence case · the movement marks · the empty state with a drawn object, a fact about the world and a door |
| `cs-system-c` | loading as redacted geometry · the toast in both kinds · **an AX3 artboard** — the first one anybody has drawn in this exercise: the panel goes full width above the headline and the type grows |

**The seven surface files and their 33 artboards** (`mockups/*.html` →
`mockups/renders/`): home ×5 · season ×6 (**`season-squads` is new** — the squad table above the
individual table, every swatch beside its squad's name) · leaderboard ×7 · course ×5 · event ×5 ·
profile ×5 · player-card ×5 · **`web-desk.html` → `renders/desk/desk-season.png`, 1440 × 900** — the
desk's season board, where the second column beside the table is the whole argument for a two-column
body (§14.5). Every photograph in the set is now **the contour (state 3) under the scrim**, drawn from
a seeded value-noise field, because §10.1 bans a gradient wash and §10.4 would rather prove the ladder
than flatter it.

**REVISED after the blind review (2026-09-06).** Thirty-four artboards were re-rendered. The
material changes to the set, each traceable to two or three independent findings:

| What changed in the deck | Filed by |
|---|---|
| **A photograph is the default ground** on the course hero (dark + light), the credential (dark + light) and Home's wire band and course thumbnails — drawn at each object's true size, under `CSPhotoScrim`, credited in agate (`GALEN'S ROUND · AUG 24`). The contour and the drawn card are now proved on `-noimage` / `-marker` only. | 3 of 3 |
| **The drawn card became real data** — 18 bars by yardage, width by par, gold on the #1 stroke hole, numbered 1–18 | 3 of 3 |
| **The marker cast was frozen** (§6.2a) across 135 disc sites in 8 files; five `TB` / `BT` initials discs became markers | 3 of 3 |
| **Delta folded into the gap cell**; four truncated surnames survive; the header row ships at every field size | 3 of 3 |
| **The ledger sentence went from 8 printings to 1** | 3 of 3 |
| **Home's rank went from three encodings to one**; the stat rail from four cells to three, and `Mon` left the numerals | 3 of 3 |
| **The Ryder roster is two named, ringed groups**; the colour ticks and the header collision are gone | 3 of 3 |
| **The rating band went from five statements to two lines and one action** | 3 of 3 |
| **Two empty states were written** (`home-quiet`, `course-page-noimage`); one void was filled (`home-new`) | 2–3 of 3 |
| **One primary per card**; `…` became `SHARE`, spelled, in both themes | 2 of 3 |
| **Column heads added** — `BEATS`, `ROUNDS / BEST`, `YOUR BEST`, `VS YOUR NUMBER · LOWER IS BETTER`; a legend added to the hole strip and a key to the meeting ladder | 2–3 of 3 |
| **The ordinal was frozen** to one baseline small-cap form | 2 of 3 |
| **The fixture was made single-valued** — The Fellas are eight in at $60 → $480 → $288 / $120 / $72 on every surface; the twelve-strong board is a different league; the profile headline now reads the field its rail reads; the season headline agrees with its own story; the Cup Final countdown agrees with the week that counts it | 2–3 of 3 |

**Known imperfections, stated rather than iterated a fourth time.**
(a) On `cs-season` the ledger line's second line sits under the scroll fade at the default size — the
band is correct but wants ~14pt more room, or the ledger line wants to be one line on the phone.
(b) On `cs-season` row 02 the points column touches the right gutter because the mockup's name is at
full width; on a device the tail-ellipsis policy in §9.1 takes effect first, and the column keeps its
20pt margin.
(c) On `cs-system-a` the pigment row is clipped by the artboard's foot; all six discs and the medallion
are in the HTML and render at full height in a taller frame.
(d) On `cs-home-dark` the minor-activity line sits below the fold; it is drawn in the file.
(e) The photographs in `cs-home-*` and `cs-course` are **drawn stand-ins** for a golfer's own round
photo (§10.4) — the contour, at plate scale, under the measured scrim. No face is fabricated anywhere
in the set.
(f) On `season-squads` Tash Bell's clause line (`Roadrunners · 3 rounds · held`) clips at the mockup's
fixed column width; on a device §9.1's tail-ellipsis policy takes effect first and the clause truncates
cleanly. The channel it is proving — swatch plus squad name — renders correctly on all six rows.
(g) On `player-card-in-list` the lower third is deliberately empty: it is a clash with nothing under
it, and it looks sparse in a 402 × 874 frame that cannot scroll. `home-new`'s void was filled after the
review with three rows naming what the first round turns on.
(h) **The photographs are still stand-ins**, and the deck says so here rather than pretending
otherwise. They are procedurally drawn dusk plates — a noise-modulated sky, a blurred treeline, mown
turf bands, a horizon feather, film grain — at each object's true pixel size. They are **not** a
gradient wash (§10.1's named ban: every band is high-frequency and noise-modulated, which is why they
read as photographic at a glance), **not** a cartoon golf hole (no sun disc, no flag, no ellipse
hills, no metal spent on decoration), and **no face is fabricated anywhere in the set**. In the build
the frame is a golfer's own round photo; what the mockup specifies is the crop, the scrim geometry,
the credit line and the panel. A reviewer looking at these should read them as *"a photograph goes
here and this is how the type sits on it"*, which is the claim §10.4 makes and the claim the previous
deck failed to make at all.
(i) `player-card-marker`'s crest and its medallion now draw the **same** glyph at two scales, which is
the point of §6.2a and also means the crest is legible as a bell only once the medallion has taught it.
That is accepted: the marker is a mark, not an illustration.
(j) `season-squads` shows The Dew Sweepers **mid-season, at week 7 of 26**, while `home-quiet` shows
the same league **after that season ended**. Two moments of one season, deliberately: the deck has to
prove the squad table and the between-seasons Home, and only one league in the fixture runs squads.
The field is twelve in both.
(k) `course-page`, `course-light` and both Ryder artboards run ~15–40pt past the fold. That is now a
**half-scrolled row under the fade** (§13.2a) rather than a sheared one, verified by measuring every
artboard's flow height in the browser rather than by eye.

---

# 20 · REFUTATIONS DECLINED

Four reviewers filed 96 findings against this document, the seven surface specs and the 32 artboards.
Every blocker and every major is fixed in place, and the fixes are marked in the sections above. **The
findings below are declined, with the reason, so nobody raises them a second time.** A declined finding
is not a disagreement about taste; each of these is either arithmetically wrong, or asks for something
the document already does, or would cost more than it buys.

| Id | The finding | Why it is declined |
|---|---|---|
| **a11y-6** *(second half)* | "Re-derive `sq0–sq3` so any two differ by ≥2.0:1 in both themes." | **Arithmetically impossible with the other constraint.** Four marks that each keep 3:1 against the ground leave no room for a 2.0:1 ladder three steps deep: 3:1 on `bg0` dark puts the darkest mark at relative luminance 0.11, and 2.0 × 2.0 × 2.0 demands 0.92, which admits no chroma at all. **1.58:1 is the measured ceiling** and it is what §2.2a ships, with the arithmetic printed beside it. The finding's *first* half — name the team where the faces are — is implemented in full (§16.4), and it is the half that actually fixes the failure. |
| **a11y-11** *(the credential at 335)* | "the credential is specified as fixed 362 × 440 with no statement of what it does at a 335pt measure" | **Superseded rather than declined**: the object is now 362 × 312 and **measure-relative** (§6.5, §16.3), so the 440 the finding measures no longer exists. Recorded here because the id will not appear elsewhere. |
| **a11y-19** *(the 18-cell strip's VoiceOver)* | "neither the strip nor its eighteen marks appears in `leaderboard.md`'s VoiceOver line" | Implemented, but not where the finding asked: the strip's single element and its `.isSelected` current hole are written into **§9.10's chart 4**, because the strip is now a named chart used on two surfaces and a rule that lives in one surface spec would drift on the second. |
| **buildable-12** *(prefer the fallback face)* | "the fallback `Font.system(design:.default).width(.condensed)` IS guaranteed tabular, so the fallback is safer than the bundle on the one axis the layout depends on" | The **assertion** is adopted (`LINT-02` now renders `0000000000` against `1111111111`), and the explicit `UIFontDescriptor.featureSettings` path is written in as the remedy. **Switching to the fallback is declined**: §1.1's whole argument is that two system faces cannot carry the brand, and IBM Plex Sans Condensed ships `tnum` — the risk is a *bug*, which a launch assertion catches, not an *unknown*, which would justify abandoning the face. |
| **buildable-26** *(`CSFace`'s size scale)* | "snap the specs to 24/30/38/56/120, or add 34" | Half-taken: **34 is not added**. The four drifted sizes are snapped instead — the event's 26 → 24, the course's 34 → 38, the course's 44 thumbnail is a *plate*, not a face, and the medallion is 44 everywhere (its 28 was a typo for the marker inside it, which is 24). Five sizes, five jobs; a sixth exists to accommodate one drifted spec. |
| **buildable-28** *(`HomeView.swift:287`)* | four citations point at a route switch | Fixed, and recorded here because it is the only finding in the set that is purely a citation: the four sites now read `HomeView.swift:181-184` and `:516-519`. |
| **overdesign-19** *(everything converges below the fold)* | "COURSE and HISTORY run their lists on the leaf; HOME shows three wire weights below the fold" | Adopted as **§15.7**, a rule, rather than as three artboard edits — the finding is right about the disease and the artboards are only its symptom. `home-feed-weights` already draws all five weights; what it lacked was §15.7 saying why. |
| **overdesign-21** *(Home is busier above the fold than the shipped Home)* | "make the ME strip two cells whenever the lead already carries a panel" | **Declined as a rule, taken as a state.** `home.md` already lets the strip render 2, 3 or 4 cells, and the count is driven by *what the golfer has* (a golfer with no money owed has no money cell), never by what else is on the screen — a strip whose column count changes with the lead above it is a strip a golfer cannot learn. What is taken from the finding: `home-live` loses the duplicated league tag and the duplicated standing facts (identity-8), which lifts the first wire item ~60pt for the same reason and without making the ME strip conditional. |

## 20.1 Declined from the blind review of the artboards (2026-09-06)

*Three blind reviewers — none of whom read this document, the audit or the surface specs — judged the
thirty-four artboards against the shipped screens and against the consumer-sports category. Everything
two or more of them agreed on, and everything one of them was plainly right about, is fixed above and
in the artboards. These are the findings **declined**, each with its reason.*

| Filed by | The finding | Why it is declined |
|---|---|---|
| blind-1 | "Drop the emoji reaction row (fire/club counts) and render reactions as small-caps counts in the system's own type — it is the only place in 34 renders where another app's language got pasted in." | **Emoji reactions are canon** (`spec/`, the owner's brief's own constraint, and §5.3 which already fences them to exactly this one site). The reviewer is right that it is the only place another product's language appears; that is deliberate, because a reaction is the one thing in this product a golfer *sends* rather than reads, and inventing a proprietary glyph for it would be the over-design §33 bans. **The craft half is taken**: the count beside each emoji is now `agateS` in the system's own face, baseline-aligned, instead of `colS` mono — so the emoji is the only foreign object, and the number beside it is ours. |
| blind-2 | "Give the friend-round row a real face. Photo first, topo only as the empty state." | **Half-taken, half-declined, and the half declined is canon.** The row now leads with a *photograph* (the round photo, rung 1) rather than the contour — that is the reviewer's substance and it is done. **A face is not drawn**, in this deck or in the product's demo diorama, because the no-fabricated-faces rule is canon and §6.3/§6.4 make the marker the guaranteed floor. A real golfer's avatar renders there when one exists; a mockup that invented one would be flattering the design with an asset the product cannot produce. |
| blind-3 | "Replace the every-meeting bar chart with eleven W/L pills in a row, tappable to the round." | **Declined in favour of the cheaper fix the other two reviewers asked for.** blind-1 called the same graphic "an original scoreboard graphic … one caption away from being unambiguous" and blind-2 asked only for a key. It now carries one: `One square is one win.` under the axis. Eleven pills is a different, more conventional object; the tape is the surface's one proprietary chart and the review says it works once labelled. |
| blind-3 | "Drop the steppers from the rating sheet — tap-and-drag the stars." | **Declined on the accessibility floor.** Ten half-star targets do not fit a 362pt measure (10 × 44 = 440), so the drag rail's half-star hit region is 28pt — below §16.2's 44pt floor. The stepper pair *is* the accessible path and is why the drag rail is legal at all. **The other half of the finding is taken**: the sheet's three exits became two (`TAKE MY RATING OFF` is gone from a sheet where no rating exists yet). |
| blind-2 | "The 'THE WIRE' hairline label over what is self-evidently a feed." | **Declined.** It is not self-evident: on Home the wire sits directly under a four-figure stat rail and a lead block, and without the head the first wire item reads as a fifth element of the lead. The head also carries the surface's one named object, which §15.1 uses to keep HOME's character distinct from COMPETE's. It costs 14pt. |
| blind-3 | "Label the money column: '−$20' alone on a personal profile with no adjacent word is a support ticket." | **Declined as already done.** The column sits under a `MONEY` head in the record table, which is exactly what §16A.3 requires. The reviewer read the figure in isolation; in the artboard it is the fourth column of a headed table. |
| blind-1 | "Say the ledger line on money surfaces only" *and* blind-3 "print it once, small, at the bottom of money surfaces only" — **plural**. | **Taken further than filed.** It is printed **once in the product**, not once per money surface (§16A.1). Three money-adjacent surfaces would have meant three printings, which is the disease at a smaller dose. |
| blind-2 | "Abbreviate to 'P. Raghunathan' before you ever ellipsize, tighten rows from ~100px to ~76px so eleven fit cleanly." | **First half taken, second declined.** The abbreviation is now §9.1's rule. **The row does not shrink**: 50pt is the slat's height at the default size and it is what makes the rail's 44pt figure and the two-line name/sub-line legal at AX3 (§16.3). Fitting one more row by shrinking every row is the trade §25 forbids. The twelfth row fits because the ledger sentence left the header, which cost the design nothing. |
| blind-2 | "ADD MY ROUND as the orange pill on a team-match screen where the natural next action is reading the matches." | **Declined.** Posting the round is what moves the event; reading the matches is what the page already is. The reviewer's underlying complaint — that the same orange pill carries five different meanings across five screens — is answered instead by §16A.5's count rule and by the pill's label always naming its own verb. One primary per surface is the system; one primary per *product* is not. |
| blind-3 | "Split season-top in two. It runs ten modules before the table fills." | **Declined as an IA change, not a visual one.** `COMPONENT_SYSTEM.md` fixes what the season page carries and in what order; §31 asks each surface to keep its own character, and SEASON's is narrative-then-table. What is taken from the finding is everything visual inside it: the duplicated pot caption is gone, the clash is one object, the table now carries a header, and the trailing nav menu is deleted — which removes three of the ten modules the reviewer counted. |

**Two things the reviewers were right about that this document cannot fix, and Phase 3 inherits them.**
(1) The light theme and AX3 have still never been *rendered on a device* — §16.6's two capture blockers
stand, and until the launch-argument hatches land, every light and AX statement here is computed rather
than seen. (2) `PhotoScrimTests` still holds only `mut` body copy at tip; §10.3 makes extending it a
gate on three of this system's signature moves, and that gate is a Phase 3 commit, not a Phase 2 claim.
