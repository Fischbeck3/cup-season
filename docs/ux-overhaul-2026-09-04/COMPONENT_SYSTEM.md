# Cup Season — the component system

*Phase 2. Written 2026-09-05 against `INFORMATION_ARCHITECTURE.md`, `UX_PRINCIPLES.md` and `DECISIONS_TO_LOG.md`, on top of `apps/ios/Packages/CSDesign`. Repo at tip `3bba87e`; read-only but for this folder.*

This document is the layer between the IA and the code. The IA says what each screen shows; this says what the screens are **made of**, so that fifteen surfaces do not each invent a card. Every pattern below names the existing CSDesign or app component it extends or replaces, with `file:line`, so the migration is a diff and not an archaeology project.

**The one rule this document exists to enforce.** The redesign's failure mode is not ugliness — it is the shipped build's actual failure mode: *the same idea drawn eleven ways*. A round's figure is a red float on the board, a green float on Home, a mint chip in the composer and a gold numeral in the table; an empty surface is a door in one place, a blank page in another, and the failure state in a third. Every one of those is a component decision that was never made, so it was made eleven times. **A pattern in this file is the only legal way to draw the thing it names.**

---

## Spine amendments proposed

Four. Everything else here is execution of the spine as written.

| # | The spine says | This proposes | Why |
|---|---|---|---|
| **CS-A1** | `INFORMATION_ARCHITECTURE.md` §4.3: the card dateline is "Plex Mono 11pt, tracked, mut" | The dateline is **`CSFont.eyebrow` (12 pt, `relativeTo: .caption`)**, not `CSFont.label` (11 pt) | 11 pt is the **floor** in `IOS-003 §2.1`, not a target, and the dateline is the first line of the most important card in the product. `CSFont.label` (`Typography.swift:26`) exists for stat labels inside a figure block, where a second line of type sits beside it. Nothing else changes; the tracking, case and `mut` are unchanged |
| **CS-A2** | `UX_PRINCIPLES.md` §4: "grep for gold tokens inside button and tab styles" | **`CSButtonStyle.gold` is deleted from CSDesign** (`Components.swift:41, 73, 88`), not merely audited | The check the spine asks for cannot pass while the API exists: three live call sites use it (`LeaguelessDoors.swift:88`, `StandingsPane.swift:140`, `SeasonCeremonyView.swift:67`), all three of them the same "Run it back — Season 2" button. L-25 is immutable and says gold on a button is a defect. A style whose only correct number of uses is zero is not a style |
| **CS-A3** | `UX_PRINCIPLES.md` §6: "`CSEmptyState`'s optional door is the pattern defect" | The door becomes a **required parameter**, so the lint is the Swift compiler and not a grep | The spine diagnoses it; this makes it unwritable. All five current call sites pass an action, but **three pass a `cta` that goes nil when a link is missing** — `IndividualRaceView.swift:43-44`, `ReceiptSheets.swift:98-99`, `RoomAlbumPane.swift:20-21` all read `cta: links.openRecord == nil ? nil : "Post a round"`, so the door silently vanishes on exactly the surfaces that need one. A fourth passes "Close" (`ScorecardSheet.swift:31`), which is a dismissal, not a move. And the two worst empties (`BoardScreen.swift:74-83`, `StandingsTableView.swift:27-33`) do not call it at all |
| **CS-A4** | *(not stated)* | **A budget: two accents and three eyebrow blocks per viewport**, checked by a preflight count | SV-05 found four accent hues in one viewport and SV-14 found eight 11-pt tracked-caps eyebrows in another. Both are named in the brief's do-not list ("tiny text", "admin aesthetics"). The spine forbids the *result*; nothing yet forbids the *quantity*, and quantity is what actually shipped |

---

## 1 · The identity contract, kept whole

`IOS-003 §1` rows that bind a component, verbatim from `docs/ios/IOS-003-design-direction.md:15-30`:

> **Charcoal ground** — `bg0` page · `bg1` surface · `bg2` raised. Dark is the default for a brand-new user (D76). Light is "same bones, dawn palette"; `auto` matches the device.
>
> **Two metals, never swapped** — `brand` ember #E8622C = **LIVE** (primary action, momentum, the ⊕). `gold` champagne #D8B25A = **EARNED only** (leads, pot, trophies, the leader's hairline, the `.earned` hero spine, points only when > 0). *"The single most important design rule to encode as a lint: no gold on anything unearned."*
>
> **One heat axis** — `warm` (building) → `hot` (burning) → `fire` (peak) · `cool` slate (falling). "Temperature is semantic, never decorative… never red-means-bad."
>
> **`pos` / `neg` are semantic only** — Performance up / money in · performance down / money owed. Never a progress bar, never a focus ring.
>
> **Squad colours** — `sq0` blue · `sq1` orange · `sq2` violet · `sq3` teal — identity in standings, the climb, the settlement.
>
> **Three type voices with jobs** — **Mono = the scorer's tent** (labels, eyebrows, stats, codes, inputs). **Serif = memory & honor** (hero numbers, standings sentence, trophies, wordmark). **Sans = now** (body, buttons).
>
> **The spine** — 3.5px left accent bar as the card grammar: ember = live, gold = earned, squad colour = squad, `pos` = live banner.
>
> **Radii** — `r` 16 cards · `rc` 10 controls · `rs` 24 sheets.
>
> **The roll** — `cubic-bezier(.16,.84,.36,1)` — "fast start, long soft settle, like a putt dying at the hole." Toasts roll out; "golf doesn't bounce."
>
> **Markers as identity** — 14 named glyphs. Avatar floor — **no silhouette state exists**.
>
> **Emoji stay emoji** — Reactions 🔥🦅⛳🧊🐍🚨 with named meanings; markers and achievements are their own systems.

All of it survives. Every pattern below is built from `CSTokens` (`Generated/Tokens.swift:46-96`) and adds no colour: preflight check 15 (palette purity) already fails an invented hex, and this document introduces none.

### 1.1 The spine is the state machine

The 3.5-pt bar is not decoration; it is how a card says what it is without a word, and it is the reason a screen can carry nine kinds of sentence without nine kinds of chrome.

| Spine | Means | Token | Fires on |
|---|---|---|---|
| **Ember** | live · a clock is running · I can still act | `cs.brand` (or `la.accent` under a look, `Look.swift:41`) | a live round, a clash inside its window, an invite waiting, a vote open, the first tee inside 72 h |
| **Champagne gold** | earned · it is already true and somebody took it | `cs.gold` | a lead held, a trophy, a champion's name, a personal best, a settled pot |
| **Squad colour** | this belongs to a squad, not to a person | `cs.squad(ci)` | squads standings, the climb, a squad-scoped item |
| **`mut` hairline** | quiet and true · no clock, nothing owed | `cs.line` | a chapter line, a record row, a finished thing |
| *(none)* | the card is a container, not a claim | — | sheets, pickers, settings |

`CSHero` (`Surfaces.swift:35-61`) already encodes the one rule a look may not break: a caller that passes gold keeps gold; a look only fills the seat ember would have taken (`Look.swift:47-48`). Every new pattern takes `spine: Color?` with the same contract.

**`pos` is not a spine tone in this system.** `IOS-003 §1` lists "`pos` = live banner" and the live banner keeps it; nothing else does. SV-06 found `pos` used as a selection ring, a title colour, a chip and a progress dot on nine surfaces, which is exactly what "semantic only" forbids.

### 1.2 The type voices, per slot

| Slot | Face | Role | Never |
|---|---|---|---|
| dateline / eyebrow / section head | `CSFont.eyebrow` — Plex Mono 12, tracking 1.6, caps (`Typography.swift:24, 58-68`) | the record's furniture | prose; a sentence about me |
| headline | `CSFont.sentenceBold` / `heroSmall` — Charter (`Typography.swift:42, 45`) | the story and the honor | a control label; a placeholder; a numeric input |
| standfirst / body / control | `CSFont.subhead` / `body` / `button` — SF | the workhorse | a hero figure |
| figure, table value, code, clock | `CSFont.stat` / `monoMediumBody` / `mono` + `.csTabular()` (`Typography.swift:28, 32, 30, 74`) | the record itself | a paragraph |
| the one figure a screen is about | `CSFont.figure` (64) / `hero` (40) — Charter Bold | a gross on the finish, a rank, a pot | a *focused numeric input* — that is a control and stays sans (L-29, `INFORMATION_ARCHITECTURE.md` §5.2) |

No fourth family. Nothing below 11 pt at the default size. Every layout tolerates AX3.

### 1.3 Light theme, deliberately

The light palette is not an inversion and two of its metals move (`Generated/Tokens.swift:72-96`): gold steps to `#846415` and ember to `#B3461C`, both *darker*, because on paper a metal has to be ink before it is a metal. Three component consequences, and they are the ones a dark-only pass gets wrong:

1. **Gold on light is text, not fill.** `#846415` on `bg2 #E5EAE4` is a text metal; a gold *fill* on the light theme reads as mustard. Gold fills only where the ground is dusk (`CSDusk`, `Theme.swift:78-81`) — ceremonies and share cards, which ignore the viewer's theme by design (L-28).
2. **Ink on a metal turns over with the theme.** `CSButton` already solves this once: `fg` is `cs.bg0`, which is near-black on the dark grounds and paper-white on the light one (`Components.swift:76-89`, and the D211 note explaining why a hard-coded near-black fell to 3.4:1). Every new pattern that puts ink on `brand` or `gold` uses `cs.bg0`, never a literal.
3. **`dim` is never text.** `Theme.swift:55-59` maps it to `mut`; the light theme's `dim #8C9992` fails AA on `bg0` exactly as the dark one does. New code calls `cs.dimText`, never `cs.dim`.

Every pattern in §4 must be screenshotted in **both** themes at the default size and at AX3 before it is called done. That is four frames per pattern, and it is the cheapest defect-finder in the set.

---

## 2 · The anti-patterns, and the component rule that makes each one unwritable

The audit named six. Each is a real, cited, shipping defect; each gets a rule with a lint, because a do-not with no enforcement is how all six shipped after being ruled against.

| # | The anti-pattern | Where it shipped | The rule | The check (§8) |
|---|---|---|---|---|
| **AP-1** | **Four accents in one viewport** — ember, gold, mint and dawn all competing, so the eye gets a legend instead of an answer | `02-clubhouse.png`; `LeagueRoomScreen.swift:188` (dawn), `BoardScreen.swift:46` (`pos` on a title), `HomeView.swift:463` (dawn), `ClimbView.swift:52, 61-63` (gold numerals + `pos`) — SV-05 | **Two accents per viewport: ember for the one thing to press, gold for the one thing that was earned.** Links are `ink` or `mut`; `dawn` is reserved for **one** trailing section-head link (`Surfaces.swift:171, 174`) and nothing else. State chips are `mut` on `line2`. Heat (`warm`/`hot`/`fire`/`cool`) is a *mechanic* — a closing clock, a carry — and is never a label colour | CL-1, CL-6 |
| **AP-2** | **Signed floats with red/green** — `-0.4 vs your index` in red, `+2.5` in green, `89 · -2.0 · FRI` in mint, `YOU +1.2 · GALEN -0.3` | six surfaces: `PostRoundScreen.swift:428`, `RoundStoryCard.swift:77-83`, `HomeLead.sideLine:209-216`, `Career.swift:134-160`, `Rivalries.swift:64`, `StandingsTableView.swift:105-108` — SV-04 | **A round's figure is a band word** (`CSBands.bandName`, `CSBands.swift:42-48`), never a chip. **A *signed* number appears in exactly one place — inside a receipt**, in `ink`, labelled "vs your playing number" (L-14, L-15, D209/D210). `CSBands.pviChip` (`CSBands.swift:92-94`) is deleted from every card surface. Red is never "worse" and green is never "better": `pos`/`neg` mean money in and money owed, and performance up and down, and nothing else. **The T-07 carve-out, ruled here once:** an **unsigned** figure inside an authored sentence, explicitly labelled against your number — *"Tash is 1.2 under her number this week"*, *"You beat your number by 3.1"* — **is legal on any surface**, because that is the exact sentence D209/D210 and T-07 sanction and it is the design's own lead copy. A **bare signed chip** (`+2.5`, `-0.4 vs your index`) is not, anywhere but the receipt. The distinction is *signed chip* versus *unsigned figure in a sentence with its label*, and CL-2 is written to it | CL-2 |
| **AP-3** | **KPI strips** — `SEASON W5/13 · THE POT · YOUR INDEX 10.6 ▼3.0 · COUNTING ROUNDS 1/4`, the league-less Home's three mini tiles, the web's seven tiles in one viewport | `StandingsPane.swift:173-244` (whose own comment claims "Not a grid of tiles"), the `A-8` and `E-obs-09` frames — SV-12, CH-17 | **One hero, one lane** (IOS-003 §4; IOS-019 rule 1, `DECISIONS.md:195`). A screen shows **one** figure block, and it is the ME strip (§4 P-15), which is a line of type on the page's ground — no boxes, no borders, no radius, no `CSStat`. `CSStat` (`Components.swift:123-145`) is legal only as a **single** tile, alone, on a receipt | CL-6, review |
| **AP-4** | **Forms as first screens** — live setup at 20 concepts and seven eyebrows with no fold; the wizard asking a name before there is anything to name; the golfer card as a 19-control form | `LiveSetupView.swift:24-184`, `WizardScreen.swift:70-86`, `WizardSteps.swift:11-42` — SV-19, P-4 | **A creation screen asks one question and folds the rest** (§4 P-9). A first screen is a question or a figure, never a field set. Everything inferable is inferred and shown as one editable line, not as N fields | review, P-9's concept count |
| **AP-5** | **Emoji trophies** — 🎯 Broke 100, 🎯 Broke 90, 📉 Personal best (a falling chart for a best), 💪 Iron Man, ⚔️/🥊 for events | `TrophyMeta.swift:42-56`, `EventPickerSheet.swift:26-27` — SV-08 | **Emoji are the six reaction glyphs and nothing else** (L-42, IOS-003 §1). Achievements, trophies and empty-state icons are **drawn strokes** in the marker family (`CSMarkerView`, `Marker.swift:15-40`; `SVGPath`, paths generated by `tools/build-markers.mjs`). Two achievements may never share a glyph | CL-4 |
| **AP-6** | **Eyebrow density** — eight 11-pt tracked-caps mono labels in one viewport; a whole standing sentence set in `CSFont.label`; `ACROSS 2 COUNTING ROUNDS` under every figure | `16-live-setup-nearby.png`, `HomeView.swift:1036`, `LeagueRoomScreen.swift:179-185` — SV-14 | **Three eyebrow blocks per viewport** (CS-A4). Anything that is a *sentence about me* is `CSFont.sentence` or `subhead`, never `label`. `CSGroupHead`'s own rule stands: "Two on a page is a spine; four is a table of contents" (`Surfaces.swift:186-188`) | CL-5 |

Two more the audit found that behave like anti-patterns and are folded into the rules above rather than given their own row: **gold used as decoration on the identity card** (five champagne elements on one object — SV-07; gold is the trophy and the lead, the index is `ink` serif, the founder mark is `mut` mono) and **raw ISO dates in a card** (`BoardLogic.swift:75-78` prints `2026-04-12` — L-07 and lint **CL-11**).

---

## 3 · The shared grammar every pattern is built from

### 3.1 The card grammar

One shape, nine kinds of sentence (`INFORMATION_ARCHITECTURE.md` §4.3):

```
▌ SAT · SEP 5 · WEEK 5 · FELLAS        dateline   mono 12, tracked, mut          (CS-A1)
▌ Galen is one round from the lead.    headline   Charter, natural case, ink
▌ He posted 79 at Papago on Thursday.  standfirst SF, mut → ink for the fact
▌ You have until Sunday.
▌ Post a round →                       action     one ember verb, function first
```

**The slots, and the law on each.**

| Slot | Type | Law |
|---|---|---|
| `spine: Color?` | §1.1 | ember/gold/squad/hairline. Gold never on a control |
| `dateline: [String]` | mono caps | **at most five segments**, joined by ` · `. It says *when* and *whose*; it is not a place for a rule or a figure. It is one of the viewport's three eyebrow blocks |
| `headline: String` | serif | **the veto** (`UX_PRINCIPLES.md` §5.2): a human subject or a first-person verb. A number, a rank or a stage word can never be a headline. Natural case, no terminal exclamation, no emoji |
| `standfirst: String?` | sans | one to three sentences of fact. Every clause is computable or it is not written (L-44) |
| `figure: (label, value)?` | mono tabular | at most one. A card with two figures is a KPI strip (AP-3) |
| `action: (label, route)?` | ember | function first — "Add my round", "See the terms", "Open the season". Never "Learn more", never "Continue" |
| `suppress: Set<Fact>` | — | what this card has spent, handed to everything below it. L-34 becomes a producer rule, not a per-screen judgement (`UX_PRINCIPLES.md` §5.4) |

**What is not a slot, deliberately:** a rules paragraph (SV-10 put a 40-word seeding rule in the smallest face on the largest card), a second action, a badge, a count, a progress bar.

### 3.2 The three states every data-bearing pattern declares

L-32 and L-44, as one contract. A pattern that cannot express all three is not finished.

| State | What it draws | What it must never do |
|---|---|---|
| **loading** | a **redacted shape of its own geometry** — the same rows, the same heights, real-length placeholder strings, `.redacted(reason: .placeholder)`. Precedent: `HomeView.swift:192-195`, `YouScreen.swift:167, 190`, `DraftNightScreen.swift:46` | a spinner inside content (`WizardScreen.swift:49`, `PotPane.swift:104` are the two live ones). A spinner inside a **control** is legal and stays — `CSButton`'s busy state (`Components.swift:58`) is the control saying it is working |
| **empty** | pattern P-11: a quiet stroke glyph · one line in voice · one true fact if one exists · **one door**. The first four words are about the world, never about the golfer's absence | double as the failure state (`HomeView.swift:283-288` is the live one, and D220 already ruled it); fabricate content or faces (L-23) |
| **error / stale** | **keeps what is on screen.** Cached content renders under a dateline reading `AS OF FRI 6:12 PM · OFFLINE`, dimmed, with **no action disabled**. Only with nothing cached does the surface say *"Cup Season can't reach the desk right now. Nothing here is missing — it just hasn't arrived."* with **Try again** | overwrite good rows with an empty read. `HomeView.swift:287` already implements exactly this for the feed (`if r.failed && !items.isEmpty { return }`) — it is the precedent to generalise, and it is the one place the app currently gets it right |

Every pattern's spec in §4 states all three. Two patterns legitimately have fewer: the intent door (P-8) has no data, and the share card (P-14) renders only from settled facts.

### 3.3 The accessibility contract, once

Stated here so fifteen pattern specs do not restate it; each pattern names only what is *particular* to it.

- **A11yStack everywhere a fixed-width trailing thing sits beside text** (`A11y.swift:26-51`). "The rule the helpers encode: a fixed-width trailing figure never squeezes a name; at AX1+ it takes its own line" (`docs/ios/accessibility.md`).
- **A headline never truncates.** `fixedSize(horizontal: false, vertical: true)`, never `lineLimit` on a serif sentence. Figures may shrink; sentences may not.
- **One element, one breath.** A card is `accessibilityElement(children: .combine)` or `.contain` with an explicit label reading dateline → headline → standfirst; secondary doors are **rotor actions**, not nested buttons (the precedent is `HomeView.swift:412-417`, where the face and six reactions became actions).
- **44 pt, always**, via `.a11yHitSlop()` inside the label so the drawn layout does not move (`A11y.swift:58-62`).
- **Reduced motion rests on the frame** (L-30). The split-flap renders flat (`StandingsTableView.swift:239-241`), the toast fades in place (`Toast.swift:59`), the dispatch does not animate its arrival.
- **A glyph is silent unless it stands alone** (`Marker.swift:5-10, 37-38`); a face speaks the person's name or nothing, never the marker's.
- **A bare em dash is spoken as words.** `YouStatRow` already does it (`YouRows.swift:17-20`) — "not yet", not a pause.
- **Nothing scrolls horizontally at AX** except a tab strip, which is allowed to run off to the right (`Surfaces.swift:256`).

### 3.4 Motion

One easing: `CSMotion.roll` (`Surfaces.swift:264-266`) / `CSTokens.Motion.roll` (`Generated/Tokens.swift:127`). Nothing bounces. New patterns animate exactly three things: a rank landing (the split-flap, `StandingsTableView.swift:185-244`), a row re-ordering (the climb), and a toast (`Toast.swift:64`). The dispatch **does not** animate its arrival — a list that reshuffles on every open is the "feels alive" failure mode, and L-21/L-22 forbid manufactured motion.

### 3.5 Haptics

The vocabulary is closed and already written (`Components.swift:213-276`). New patterns reuse it: `.posted` for a round landing, `.rankUp` for a rank moving on open, `.present` for the ⊕, `.armed` for a two-tap "Sure?", `.selection` for a pane or a chip. **No haptic on a dispatch refresh, on navigation, or on an error that already toasts.**

---

## 4 · The patterns

Sixteen. Each carries: **job · anatomy · copy rule · states · Dynamic Type and VoiceOver · extends or replaces (`file:line`) · where it is used · the reads its facts come from** (class A = shipping RPC, R1–R17 = `INFORMATION_ARCHITECTURE.md` §15.2, C-1–C-11 = §15.3). Where behaviour differs between **solo and squads** or between **the Pro and a member**, both are stated — the audit walked neither branch, and this is where that gap is closed.

---

### P-1 · The story card — `CSStoryCard`

**Job.** One thing that happened, or is about to, with a human subject and a single door. It is Home's lead, the head of a season page, the head of a moment, and the ceremony takeover. It is the pattern that makes the product read as a dispatch rather than a dashboard.

**Anatomy.**

```
CSStoryCard(
  spine:      Color?          // §1.1 — ember when a clock runs, gold when earned
  dateline:   [String]        // ≤ 5 segments · mono 12 caps
  headline:   String          // serif · the veto applies
  standfirst: String?         // sans · 1–3 sentences of fact
  aside:      Aside?          // .none | .sides(mine, theirs) | .figure(label, value)
  action:     Act?            // one ember verb + route
  secondary:  Act?            // at most one, and only where a decline must exist (an invite)
)
```

`aside: .sides` is the two-up clash block already built and correct (`HomeLeadCard.swift:50-70`): my side, a mono "V", their side with their marker, the one in front in `pos`. `aside: .figure` is the single figure a story may carry — a gross, a pot, a rank — and it is the only figure on the card (§3.1).

**Copy rule.** The **veto** governs the headline: a human subject or a first-person verb, in every one of the thirteen Home states (`UX_PRINCIPLES.md` §5.2). `2nd of 2 — held` is a fact and facts live in the ME strip. The standfirst carries the facts and the clock; the action is function-first. No exclamation, no emoji in prose, natural case (L-33). A card never says "you haven't" (`UX_PRINCIPLES.md` §5.3).

**States.**

- **loading** — the card's own geometry, redacted: one dateline bar, two serif lines, one action-width bar. Never a spinner; Home's first paint is a card-shaped grey, not a hole.
- **empty** — the lead never renders empty. When only Tiers 5 and 6 exist the lead *is* the quiet true sentence ("Week seven of twenty-six. Nothing has moved since Sunday."), which is honest under L-21 and is the rung-7 line the season page uses.
- **error** — keeps yesterday's card, dims it, and rewrites the dateline's first segment to `AS OF FRI 6:12 PM · OFFLINE`. The action stays enabled. With nothing cached it becomes the desk line and **Try again** (§3.2).

**Dynamic Type / AX.** The serif headline never truncates. `aside: .sides` becomes a column at AX1+ (`A11yStack`). The whole card is one element labelled "*dateline*. *headline*. *standfirst*", with the action as the default activation and `secondary` as a rotor action. At AX5 the card grows the page, never scrolls inside itself. Reduced motion: no arrival transition, ever.

**Extends / replaces.** Extends `HomeLeadCard` (`HomeLeadCard.swift:19-98`) — the `CSCard(spine:)` frame, the ember spine reasoning (`:27-30`) and the sides layout (`:50-70`) all survive; what changes is that its four hard-coded faces (`clash · floor · move · milestone`, `:72-97`) become the nine server-produced kinds, so the client stops owning the ladder. **Replaces** `PhaseHero` (`RoomBits.swift:125-146`) as a page head and the Home hero's footnote stack (`HomeHeroCopy.footEndgame/footRule/footMoney`, rendered `HomeView.swift:990-995`) — the four-line rulebook paragraph inside a hero (SV-10) is not a slot in this pattern and cannot be added back. Sits on `CSCard` (`Components.swift:15-37`) on Home, on `CSHero` (`Surfaces.swift:35-61`) where a page needs the wash, and on `CSDuskCard` (`Surfaces.swift:64-85`) for the ceremony.

**Used.** Home's lead (all thirteen states) · the season page's story block · the event page's head · the weekend page's head · the cancel-vote item · the ceremony takeover · the ME strip's neighbour, never its duplicate.

**Reads.** **R1** `home_dispatch().items[0]` (tier, kind, dateline, headline, standfirst, action_label, route, suppress) · **R6** `season_story` for a CHAPTER lead · **R3**'s inlined clash for a WEEK lead · A `native_home.live_round` + `live_state` for the live lead.

**Solo vs squads.** In a squads season the headline's subject may be a squad ("The Frost have taken six off the lead in a fortnight") and the spine wears `cs.squad(ci)`; the ember/gold rule is unchanged. In a solo season the subject is always a person — at n=2 the product's existing words are kept verbatim: *"It's the two of you — every week is the clash."* (D207, `HomeLead.swift:68, 85, 195-206`).

**Pro vs member.** Identical. A Pro's pending action is never the lead (D226; V-1's check is that the Pro's Home and a member's Home open on the same object).

---

### P-2 · The ranked action card — `CSDispatchRow`

**Job.** Dispatch items 2 through 5, the season page's THIS WEEK, and Compete's peer rows: one sentence, one clock, one door, at a weight that reads *below* the lead.

**Anatomy.**

```
CSDispatchRow(
  spine:    Color?        // a 2 pt hairline, not the lead's 3.5
  dateline: [String]      // ≤ 3 segments — for a peer row, the season's name leads
  sentence: String        // SANS semibold. Never serif
  detail:   String?       // one mono-small clause: a clock, a count, a gap
  action:   Act?          // inline ember verb, or a chevron when the row itself is the door
)
```

**The serif is the lead's alone.** That single restraint is what makes a ranked list read as ranked without a number beside each item.

**Copy rule.** One sentence, one fact set, one door. A row never restates a fact in the lead's `suppress` set, and never restates a fact the ME strip owns (my number, my last round, my next round, my money — D236). A row that would say "you haven't" does not render.

**States.** **loading** two redacted bars per row, three rows. **empty** the row does not render — a tier that did not fire draws nothing, and the dispatch simply gets shorter (the four foot doors are the floor, so the page is never empty). **error** inherits the page's stale dateline; rows keep their last values.

**Dynamic Type / AX.** `A11yStack`; the action drops under the sentence at AX1+. One element per row, the action as its default activation, the detail read after the sentence. The row is 44 pt minimum by construction.

**Extends / replaces.** **Replaces** three horizontal rails, all of which are KPI strips wearing capsules: `UpNextChips` (`UpNextChips.swift:9-79` — its warm-at-three-days rule survives in P-13), `EventChips` (`EventChips.swift:13-46` — a Ryder becomes a dispatch item and a Compete row, and finally reaches a golfer with no season), and `HomeLeagueRows` (`HomeView.swift:1015-1069` — retired as a switcher under O-09/D229; its content becomes items, each naming its own season in the dateline). Extends `CheckDoor` / `CheckRow` (`SliceComponents.swift:135-151, 89-131`) in spirit, but on the page's ground with a hairline rather than a bordered card — rows never nest cards (IOS-019 rule 2, `DECISIONS.md:196`).

**Used.** Home items 2–5 · Compete's YOUR SEASONS / YOUR MOMENTS / FINISHED rows · the season page's THIS WEEK · the event page's session line · the Pro's seven verbs at the foot of the season page.

**Reads.** **R1** `items[1…4]` · A `native_home.memberships[]`, `events[]`, `open_duels[]` (the last two are decoded at `Models.swift:233-234` and read by no view today) · A `my_schedule` · A `league_cancel_status` for the vote row.

**Pro vs member.** The Pro's seven verbs (invite, mark a payment, announce, close the roster, grant a bye, set the finish, end the season) are rows of this pattern at the **foot** of the season page, never a mode and never the identity of a screen (D226). A member sees no disabled Pro row — the row is absent, and the member's equivalents ("Post a forfeit", "Call someone out") are real acts in the same shape.

---

### P-3 · The feed row — `CSWireRow`, seven kinds

**Job.** The wire: what the people I know did, one row each, ranked by proximity, with the round as the one rich member of the family.

**The seven kinds and their sentence shapes.**

| Kind | The sentence | Figure | Door | Producer |
|---|---|---|---|---|
| **round** | "Galen posted 84 at Papago." | the **band word** ("Beat your number"), never a float | the receipt | **R2** over `rounds` |
| **milestone** | "Dev broke 90 for the first time." | none | the round behind it | **R2** over `achievements`; **C-1** gives it a home when there is no season |
| **plan** | "Saturday, 7:10 at Papago. Three in, one seat open." | seats | the plan | A `my_schedule` |
| **verdict** | "The clash is yours. Second week running." | the two grosses | the clash receipt | A `week_clashes` via **R2** |
| **lead change** | "The lead changed hands on Sunday. Jade has it for the first time." | the gap | the table | **R6** |
| **challenge** | "Galen posted — 82 to beat, three days left." | the number to beat | the callout | A `event_session_targets` |
| **invite** | "Galen put you on the Fellas." | the stake, if any | **the covenant** — never a bare Accept | A `my_invites` + **R9** |

**Anatomy.** face (`CSFace`, 22 in a row / 36 in a list) · who (sans semibold) · the sentence · when (`CSDate.short`, **never a raw ISO string**) · optional photo ground · optional reaction bar · the door.

**Copy rule.** Third person for someone else's round, always they/them, never a pronoun guessed from a name (`CSBands.theirs`, `CSBands.swift:70-75`). First names leave the app (`CSBands.fn1`, `:78-82`, D77). **One headline per round** — mark > barrier > personal best > streak (L-42): a round that broke 90 and 100 hangs one tile, not two (SV-09). And the rule this pattern exists to enforce: **the figure is the band word.** `CSBands.pviChip` is not called from any row.

**States.** **loading** three redacted rows at the real geometry. **empty** P-11 with a door — and this closes SV-03, where an empty board is 1,300 px of ground under a non-interactive note (`BoardScreen.swift:74-83`, `BoardRows.swift:78-115`). **error** keeps the rows: `HomeView.swift:287`'s rule, verbatim, generalised.

**Dynamic Type / AX.** The photo is the card's **background** and the text sets the height (already fixed at `HomeView.swift:353`); a gross drops under the name at AX (`:393`). One element per row — "Galen — 84 at Papago, beat your number by 2.4", hint "Opens the round" — with rotor actions for the face, the receipt and each of the six reactions (`HomeView.swift:412-417`). A system row with no door is a plain combined row, not a dimmed button (`:597`).

**Extends / replaces.** Extends `RoundStoryCard` (`RoundStoryCard.swift:12-127`): the photo ground (`:103-117`), the marker medallion (`:120-126`) and the squad spine (`:48`) survive unchanged. **Deleted from it:** the PvI chip (`:77-83`, AP-2) and the `COUNTING #N THIS MONTH` line (`:63-64`), which moves to the receipt where the machinery belongs (L-15). Replaces `SystemRow` (`BoardRows.swift:78-115`) — a system note either carries a door or does not render.

**Used.** Home's wire (the feed, whole — O-08) · the season board · the event board · the person page's recent rounds · the weekend's comments.

**Reads.** **R2** `home_stories(p_days, p_league)` — one read replaces two client-side merge algorithms and finally lets a leagueless buddy's milestone reach me · **C-1** `posts.profile_id` for a round with no season home · A `home_feed` as the declared fallback.

**Solo vs squads.** The spine's squad colour is meaningful only in a squads season; in solo it is the `mut` hairline. **Never** invent a squad colour for a solo golfer — `cs.squad(ci)` with a fabricated `ci` is how a two-person season grows fake teams.

---

### P-4 · The season chapter header — `CSChapterHead`

**Job.** The head of a season page and of the season's story page: where the story stands, in one sentence, over a dateline that says the stage.

**Anatomy.**

```
CSChapterHead(
  dateline: [String]   // "FELLAS · WEEK 7 OF 26 · SEASON LIVE" — the stage word from ONE producer
  line:     StoryLine  // serif, with squad/person name runs in their own colour
  door:     Act?       // "The season's story →"
)
```

**Copy rule.** The line is chosen by the **fixed ladder** (`INFORMATION_ARCHITECTURE.md` §7.2), whose bottom rung now **reaches into history** (R-H) under the same absolute fence, so the sentence is learnable rather than a mood, and **rung 7 is allowed to say nothing has moved** — that is the honest sentence for a quiet week and the thing that stops the editorial layer manufacturing drama. Every rung is a count over `standings_snapshots`. No probability, no projection dressed as a fact (D24). The stage word is one of six, from one producer per client, gated by preflight 20 (L-43, `LeagueCopy.swift:176-188`).

**States.** **loading** dateline redacted, two serif bars. **empty** week 1 has no snapshots, so rung 6 fires ("Thirteen weeks. Clean cards, fragile egos.") — never a blank. **error** the dateline stays (it is computed from the season row, which is cached); the story line drops silently, which is **R6**'s declared fallback.

**Dynamic Type / AX.** The serif line never truncates and never scales down; the dateline wraps rather than clipping (`LeagueRoomScreen.swift:229` already learned this the hard way — "Seaso n live" at AX5). The head is one element; the door is separate and 44 pt.

**Extends / replaces.** Extends `StoryLine` (`StandingsTableView.swift:141-159`) — its squad-coloured name runs (`name(_:)`, `:150`) are exactly right and survive; it gains the dateline, the rung ladder and the door. **Replaces** the room's record hero (`LeagueRoomScreen.swift:157-190` — the code chip, the span, the preset name and "Add golfers", SV-11) and the four-KPI season strip (`StandingsPane.swift:173-244`, SV-12/CH-17).

**Used.** The season page · the season's story page · the record's per-season rows (each opens a story page, not a dead table) · the event page, with the event's own clock in place of the week.

**Reads.** **R6** `season_story(p_season)` · **R3** `season.{week_no, weeks_total, final_opens_on}` — one week producer (C-8/D246; six formulas exist today) · A `LeagueCopy.Stage` for the stage word.

**Solo vs squads.** Squads: the subject is a squad and its name run wears `cs.squad(ci)`; the line is about squads ("The Mudsharks have led since the draw"). Solo: the subject is a person, in `ink`, and the word "squad" never appears (L-43).

---

### P-5 · The standings-as-story row — `CSTableRow`

**Job.** A table where every row carries the number **and one clause of why**, so the table is the story's second half rather than a spreadsheet (L-35).

**Anatomy.**

```
CSTableRow(
  rank:   Int          // mono, split-flap on a fresh load only
  chip:   Chip         // a squad swatch, or a marker for a solo table
  name:   String
  clause: Clause       // ONE of a closed set of six — mono small, mut
  points: Double       // mono tabular; gold ONLY at rank 1 with points > 0
)
```

**The closed set of clauses** — a table row may say exactly one of these, and nothing else:

`held four weeks` · `up one since Sunday` · `down one since Sunday` · `4 back` · `her best week was 3` · `2 of 3 counted`

**Copy rule.** **A movement label carries its own clock, or it does not render** (`UX_PRINCIPLES.md` §3, A-4). `prev_rank` is a Sunday snapshot (`20260902200000:312-342`, cron `'10 7 * * 0'`), so a Tuesday climb currently reads "held" and lies about time — a bare ▲/▼/held is now unwritable. **A gap is always attached to a name** (A-5): at rank ≥ 3 the row needs `next_up`/`next_down`, and without them the gap clause does not render. Every figure taps to its receipt (L-01).

**States.** **loading** five redacted rows. **empty** a season with no rounds replaces the row block with P-11 and the door "Add my round" — not the two mono lines with no door that ship today (`StandingsTableView.swift:27-33`). **error** keeps the table under the stale dateline.

**Dynamic Type / AX.** Three lines at AX with the column heads hidden, already built and correct (`StandingsTableView.swift:83-118`); "1st, Galen, 27 points, up one since Sunday" as one breath, with the hint naming what opens.

**Extends / replaces.** Extends `StandingsTableView.row` (`StandingsTableView.swift:71-127`). Kept: the gold leader hairline (`:120`, the one earned rule in the table, IOS-003 §2.10), the split-flap (`RankFlipText`, `:185-244`, a ceremony under L-31), the cut line (`:37-43`), the fresh-load haptic (`:52-56`). **Deleted:** the `Δ Wk` column (`:100-110`) — a signed float in `pos`/`neg`, AP-2 — and `moveChip` (`:130-138`), whose bare arrow is the unclocked label A-4 forbids. Both are replaced by the clause.

**Used.** The season page's table · the squad table · the individual table under it · the Cup Final race · the friends' board (P-7 supplies its rows, this supplies its shape).

**Reads.** A `native_home.standing` · **R3** `next_up{name, points}` / `next_down{name, points}` — the single most-cited missing fact in the audit, because the server names only the leader and rank 2 today · **R6** for run lengths (`held four weeks`) · A `pulse.credits` for `2 of 3 counted` · **R7** for the event-driven movement sentence at the moment it happens.

**Solo vs squads.** Squads: the squad table comes **first**, the individual table second, and each squad row expands to its members' contributions — which is the answer to "who am I competing with" in a squads season, a question no persona was ever asked. Solo: one table; the sub-line reads "N rounds"; the cut line does not render at a field of two (`:37-38` already guards this).

---

### P-6 · The rival line — `CSRivalLine`

**Job.** The state of a head-to-head in one line, wherever two people meet: Home, the person page, the head-to-head page, the epilogue, the record.

**Anatomy.**

```
CSRivalLine(
  left:   Side          // me, or a face + name
  right:  Side
  record: String        // "6–5" — mono tabular
  lead:   Lead          // .me | .them | .level — decides which name is in ink
  clause: String?       // "He has taken the last two."
  dots:   [Outcome]?    // last five, with a text alternative
  name:   String?       // the rivalry's name if it has one ("The Grudge")
  door:   Act?
)
```

**Copy rule.** The record is always attached to a name and a direction — "You lead 6–5", never a bare "6–5". Until a meeting is confirmed the facet is labelled **"played together"** and never "beat" without the qualifier (C-2/D239: the tag has a state, and a tag is never a vouch — L-19). The same-day/same-course heuristic is **labelled as a heuristic**, because the course is optional on a quick post — a round may carry no `course_id` at all, so a same-course match is an inference and never a record (L-44). The rivalry name leads when it exists (`my_rivalries.rivalry_name` is returned and dropped by the client today).

**States.** **loading** redacted record + one bar. **empty** fewer than two meetings and the line does not render — **never "0–0"**, which is a number that counts nothing (L-44). **error** the line drops; nothing else on the page changes.

**Dynamic Type / AX.** The dots carry a text alternative ("you, you, him, you, him"), never five unlabelled circles. `A11yStack` — the record drops under the names at AX1+.

**Extends / replaces.** **Replaces** the rivalry headline `YOU +1.2 · GALEN -0.3` (`Rivalries.swift:64`, rendered `RivalriesSection.swift:122`) — two signed floats where a record belongs, AP-2. **Replaces three implementations with one:** `my_rivalries`, `rivalry_weeks` and `tour_card.vs_you` all compute this differently today and none can count two buddies who share no season, because `my_rivalries`'s `shared` CTE joins `league_members × seasons` (`20260716210000:76-83`).

**Used.** Home's RIVALRY item · the person page ("YOU AND HIM 6–5 to him →") · the head-to-head page (as its head, with the facet table under it) · the post-round epilogue · You → Your record.

**Reads.** **R4** `head_to_head(p_opponent)` — `{facets, last_five[], record{w,l,t}, rivalry_name, lead}`, with A `my_rivalries` as the declared fallback (season-only, as today) · **C-2** `round_players` for the meetings.

---

### P-7 · The person row with shared history — `CSPersonRow`

**Job.** A golfer in a list, with the one true thing about them **and me**. This is the pattern that turns a directory into a competition surface.

**Anatomy.**

```
CSPersonRow(
  face:    CSFace              // photo, else the marker — no silhouette state (L-24)
  name:    String              // + the founder mark in `mut` mono, NOT gold
  history: String              // the strongest true fact, in a fixed order
  trailing: Trailing           // an action ("Add Ravi"), a figure, or a chevron
  spine:   Color?              // ember on a request; otherwise none
)
```

**The history line's fixed order** — the first of these that is true wins, and only one renders:

1. the head-to-head — "6–5 to him · last played Sat"
2. rounds together — "4 rounds together"
3. a shared season — "Fellas · 2nd of 8"
4. playing soon — "Sun 7:10a Whirlwind · 2 in"
5. the identity fallback — "@galen · Tempe"

**Copy rule.** Never a follower count, a reaction count, a streak rank or any other attention metric (L-22). The board's lens is **form**, not handicap, and it is a list, not a score (C-7/D245). A golfer I may not see says so plainly and offers the buddy request — the Tour Card gate is the one privacy rule and is unchanged (L-37, D150).

**States.** **loading** redacted rows with real-width name bars. **empty** P-11 — and for the "You play with (not buddies yet)" block the door is "Add Ravi", which is the row that turns a list into a door. **error** keeps the rows.

**Dynamic Type / AX.** The lead (face + name + history) is **one** button — the person — read as one element with a hint; the trailing action keeps its own control (`Links.swift:126-127, 136-146`). A glyph inside the face is silent because the name is beside it (`Marker.swift:85-88`). At AX the trailing action drops under the text.

**Extends / replaces.** Extends `RoomLineRow` (`Links.swift:122-180`) — the shape is right and its Y-23/Y-33 accessibility work is kept whole; it gains the history slot and the fixed order. Extends `PersonRow` (`PeopleScreen.swift:216-247`), with one correction: the founder mark moves from `cs.gold` (`:240`) to `mut` mono — a founder tag is a fact, not a thing taken off somebody (SV-07, L-25).

**Used.** Golfers → requests, the board, playing soon, buddies, people I play with, league mates · the covenant's roster row (**R9**) · the members sheet · the composer's "Who was out there?" · the invite picker · the event's field.

**Reads.** A `my_friends`, `search_golfers`, `recent_partners`, `last_round_with`, `my_schedule` · **R5** `friends_board()` for the board's figures · **R4** for the head-to-head clause · **C-4** for the person link's landing.

---

### P-8 · The intent door — `CSIntentDoor`

**Job.** Creation starts from what a golfer wants, not from what the engine has. Five sentences, no object nouns.

**Anatomy.**

```
CSIntentDoor(
  intent: String     // sans semibold — a verb phrase
  gloss:  String     // mut — what it gets you, in a golfer's words
  role:   .primary | .modifier   // the modifier renders as a footer line, not a peer
)
```

The five, as ruled (`INFORMATION_ARCHITECTURE.md` §6.2):

> **Play with my friends** — a round with whoever is around
> **Run a season** — weeks of golf that add up to a table
> **We're playing this weekend** — one day, and a name for it
> **I want to beat one guy** — you and him, whatever length you like
>
> *Put money on it* — add a pot to any of the above  ← the **modifier**, a footer line
> *I have a code →*

**Copy rule.** **Names an intent, never an object.** No "league", no "event", no "Ryder", no "bracket". **And it may not sell what the object does not mint:** the third line used to read *"one day, one trophy"* while C-3/D240's own text says a named weekend *"gets no board of its own and mints no trophy"* — the gloss is now **"one day, and a name for it"** (L-32/L-44, and `TERMINOLOGY.md` A-9). Money is a choice **on** a competition and never a competition, so it is a footer and not a fifth peer (L-11, D46 — and both organiser walks in the August audit met a $75 stake they never chose: a persona walk is a reasoning tool, not a cohort). No icon and no chevron on a primary door: an icon here would be a category badge, which is the object menu wearing a costume.

**States.** The one pattern with no data: no loading, no empty, no error. That is deliberate — creation must work when everything else is failing.

**Dynamic Type / AX.** Each door is a 44 pt+ row that becomes two lines at AX; the gloss never truncates and never scales. Each door is one element ("Run a season. Weeks of golf that add up to a table.").

**Extends / replaces.** **Replaces** `LeaguelessDoors`' three object-doors (`LeaguelessDoors.swift:14-46` — Join a league · Start a league · Start an event) and `EventPickerSheet`'s schema menu (`EventPickerSheet.swift:26-27` — "Ryder LIVE · Bracket SOON · Major", with ⚔️ and 🥊, which is AP-5 and P-4 in one screen). The `RunItBackCard` above them (`LeaguelessDoors.swift:20-22`) survives as a P-1 story card, because a wrapped season with a champion's name is a story, not a door.

**Used.** Compete's head ("Start something") · Home's OPPORTUNITY item and its foot doors · the post-round epilogue's next act · the person page's four doors (§9's table: make it a season · put a forfeit on it · play him for it · call him out).

**Reads.** None to render. Each door's **resolution** is existing RPCs — `create_league` → `lock_league` → `add_friend_to_league` (D205's two-golfer season) · `create_forfeit` (widened by **C-5**) · `start_live_round` · `declare_round` (+ **C-3**) · `create_event` at a field of two (**C-10**/D237, the callout). **No new object type is minted by any door.**

**Pro vs member.** "Run a season" always mints a **new** one; a member never sees the Pro's configuration tool for a season they are in (L-12, D40). A member's version of "start something" inside a season is a forfeit or a callout — real acts, never a disabled button.

---

### P-9 · The progressive-disclosure step — `CSStep`

**Job.** One question per screen, with everything inferable already filled and everything else folded, complete and unchanged, one tap deeper.

**Anatomy.**

```
CSStep(
  index:   (n, of)      // "1 OF 3" — mono
  question: String      // serif, natural case, ends in "?"
  answer:  Content      // the control — sans or mono, NEVER serif (L-29)
  note:    String?      // mut — the DERIVED consequence of the current answer
  more:    Disclosure?  // "More settings ⌄" — every dial, verbatim, with its ⓘ
  primary: Act          // ember, sticky at the foot, function-first
)
```

The three questions, in order, and nothing else before Start: **Who's playing? · How long, and when's the first tee? · What's on it?** (`INFORMATION_ARCHITECTURE.md` §6.3). The name is asked **last**, on the same screen as the primary, and the `leagues` row is minted at that tap in one transaction with `lock_league` — so an abandoned wizard leaves nothing behind (today the wizard mints the row on the name step, so an abandoned wizard strands a founder-alone `setup` league, `WizardScreen.swift:70-86` → `:252-268`).

**Copy rule.** The note is **derived, never a literal**: "Two is a season. Four opens squads." comes from `structMin`, so it cannot go stale. The primary names the press ("Start the season"), never "Continue". **A preset carries one sentence and never recites a dial** — `WizardState.swift:68-72` is a live L-16 violation, printing "95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor" on a card whose whole job is to spare a golfer those words. It becomes: *"Standard — the default. Light guardrails, honest scores."*

**States.** **loading** the step renders with its control disabled and the note redacted — never a full-screen spinner where a form belongs (`WizardScreen.swift:49` is the live one). **empty** n/a. **error** the step **keeps every answer the golfer gave** and shows the failure on the primary; a wiped form after a failed publish is the worst error state in any product.

**Dynamic Type / AX.** `More settings` is a real disclosure whose header reads as a button with an expanded/collapsed value. The derived note is `.updatesFrequently` so VoiceOver announces the consequence when an answer changes. The primary is sticky and clears the keyboard. The step index is spoken as "Step 1 of 3" (the card gate already does this, `CardGateView.swift:29`).

**Extends / replaces.** Replaces `WizardNameStep` / `WizardPresetStep` / `WizardReviewStep` (`WizardSteps.swift:11, 45, 187`) as a *sequence*; **keeps** `WizardSetRow` (`:219-272`), `WizardSeg` (`:273-301`) and `WizardInfoButton` (`:302-323`) **verbatim inside `More settings`** — all twelve dials survive with their ⓘ paragraphs, because complexity is hidden and not deleted (P-6). Applies unchanged to `LiveSetupView` (`LiveSetupView.swift:24-184`, the 20-concept specimen: **Who · Where · What are we playing** above the fold, strokes/stakes/guests/Bluetooth below it) and to the composer, which is this pattern with one box and nine folded things.

**Used.** The season wizard's three steps · live setup · the composer · the callout sheet · the weekend sheet (**C-3**'s name, game and stake) · the card gate.

**Reads.** A `create_league`, `lock_league`, `add_friend_to_league`, `declare_round`, `start_live_round`, `create_event` · **R11** `post_round(…)` for the composer, which turns the phone's one consequential direct write into an RPC (L-03; `PostService.swift:84, 93`).

**Pro vs member.** Only a Pro reaches the season steps. **Draft night is two different screens, not one screen with a swapped verb** (`DraftNightScreen.swift` shows the Pro's screen to a member today, CH-13): the Pro gets "The hat is ready. Six in, four to a squad." → **Draw the squads**; a member gets "Galen draws the squads before the first tee. It's random — nobody picks." → **See who's in**. No member ever sees a verb they cannot press.

---

### P-10 · The stake / pot line — `CSStakeLine`

**Job.** Say what is on it, once, in one place, with the ledger sentence — for a season pot, a moment's pot, a side-game stake, and a forfeit.

**Anatomy.**

```
CSStakeLine(
  headline: String?      // "$50 each" — mono tabular, INK
  books:    Money?       // "$150 on the books"  ┐ two numbers,
  collected: Money?      // "$50 collected"      ┘ NEVER blended (L-10)
  mine:     Owe?         // "$50 · YOU" — self-only, in `neg`
  terms:    String?      // "Ray Ortiz collects · Venmo @ray-o" — selectable text
  ledger:   Bool         // prints MoneyCopy.ledger verbatim
)
```

**Copy rule — the money rule, in component form.**

- **$0 renders nothing.** No "None", no "Bragging rights" tile, no pot pane, no surface anywhere (L-10, D70). A $0 season is not a season with an empty pot; it is a season with no pot.
- **The ledger line is one constant, printed verbatim**: `MoneyCopy.ledger` (`MoneyCopy.swift:28`) — *"Cup Season keeps the ledger; the money moves between friends."* Never "never held", never "takes no cut", never "between you". That file's own header explains why this drifted twenty-two ways: a verbatim law has no violating token, only near-misses, so nothing ever failed. The component is the fixed home the law needs.
- **The unpaid figure is self-only, in `neg`, never gold and never with a countdown.** Money is never urgency and never earned (L-10). It lives in exactly one always-present place — the ME strip's `STILL OWE` slot — where it fires from state on every open, and taps to the books. D129 relocated, not demoted.
- **A payout with zero rows renders nothing, never $0.** A golfer who has not been paid out has no `season_payouts` rows, and a "$0 earnings" stat over none of them is a number that counts nothing (L-44).
- **No odds, no action, no units, no parlay, no "wager".** The banned register is `brand-canon.md:91-95`, and this component is what App Review reads.

**States.** **loading** the two numbers redacted, labels visible. **empty** at $0 the component is **absent**, which is the only empty state in the system that draws literally nothing. **error** the numbers keep their last values under the stale dateline; a stale pot figure is honest, a guessed one is not.

**Dynamic Type / AX.** The two numbers are never one element ("$150 on the books" and "$50 collected" are two facts, and blending them is the exact defect L-10 names). The terms line is selectable — a Venmo handle a golfer cannot copy is not a payment note. `A11yStack` for the payout trio (already done, `PotPane.swift:40`).

**Extends / replaces.** Extends `PotPane` (`PotPane.swift:10-120`) and the forfeit ledger (`ForfeitLedgerView`, `:122-170`) — one component for both, which is what **C-5**/D242 needs when a forfeit can exist between two golfers with no league. Keeps `PotPane.swift:134`'s empty line as a model of voice ("No stakes on the books. The cookout isn't going to bet itself.") but gives it a door (P-11). Replaces the `THE POT · None / Bragging rights` column in the season strip (`StandingsPane.swift:173-244`) — at $0 there is no column.

**Used.** The season page's THE POT block · the covenant · the wizard's step 3 · the event page's "what's on it" · the live game's stake card · the head-to-head's forfeit · You → THE BOOKS · the ceremony's pay rows.

**Reads.** A `native_home.buy_in`, `mark_buy_in`, `set_buy_in_terms`, `forfeits`, `season_payouts`, `live_rounds.game_config` · D225's **required payment note at publish**, which is the fact two persona walks hit and could not get.

**Pro vs member.** The Pro gets a "Mark a payment" row (P-2) beside the line; a member sees the terms and has nothing to press. Neither ever sees the other's version.

---

### P-11 · The empty state with a door — `CSEmpty`

**Job.** An absence is an opportunity with one move. This is the pattern the brief calls out by name and the one the shipped app most often skips.

**Anatomy.**

```
CSEmpty(
  glyph: CSGlyph        // a drawn stroke, from the marker family — NOT an emoji
  line:  String         // one line in voice
  fact:  String?        // one true fact, if one exists
  door:  Act            // REQUIRED (CS-A3)
)
```

**Copy rule.** **The first four words are about the world, never about the golfer's absence.** *"Nothing posted this month"* opens on absence; *"Two rounds gets you back in the Fellas table before it closes"* opens on the move. The second is the only legal shape (`UX_PRINCIPLES.md` §6). Never fabricated content, never fabricated faces (L-23). The door is a real act, not "Learn more".

**States.** This *is* a state — and it is **never** the failure state. A failed read is §3.2's stale or unavailable, which is a different component and a different sentence. `HomeView.swift:283-288` currently uses one string for both, and D220 already ruled that wrong.

**Dynamic Type / AX.** The glyph is `accessibilityHidden`. The block is one element plus one action; the door is 44 pt (`a11yMinTarget`, already applied at `Components.swift:168`). The line and the door stack at AX and the door does not shrink (`HomeView.swift:62`'s fix, generalised).

**Extends / replaces.** Extends `CSEmptyState` (`Components.swift:151-176`) with two changes: **`cta` and `action` become non-optional** (CS-A3 — the optional door is the defect, and making it required moves the lint into the compiler), and `icon: String` becomes `glyph: CSGlyph` (AP-5 — the five live call sites pass 🗂 ⛳ 📷, which is emoji clip-art standing in for an icon set). The five call sites to migrate: `ScorecardSheet.swift:31` (its door is "Close", a dismissal rather than a move), `IndividualRaceView.swift:43-44`, `ReceiptSheets.swift:98-99` and `RoomAlbumPane.swift:20-21` (all three write `cta: links.openRecord == nil ? nil : "Post a round"`, so the door disappears whenever the link is not wired — the optional door failing in production, not in theory), and `YouScreen.swift:138`, which is the one that is already right. The surfaces with **no empty branch at all**, which are the ones that actually hurt: `BoardScreen.swift:74-83` (SV-03 — a blank page and a disabled Send), `StandingsTableView.swift:27-33` (two mono lines, no door), the display case, and the wire.

**Used.** Every list, every table, every pane, every tab, in every state — including the four Home foot doors, which are the floor that makes the page's empty state impossible.

**Reads.** Whatever the surface reads; the empty branch fires on `isEmpty && !failed`. **The `failed` half of that condition is the whole pattern.**

---

### P-12 · The section head — `CSSectionHead` (revised)

**Job.** Name a block of rows and offer at most one door.

**Anatomy.** eyebrow (mono 12, tracking 1.6, caps — `mut` on homebase, the look's accent under a look) · hairline · optional trailing link in `dawn`. Unchanged in shape from `Surfaces.swift:152-181`.

**Copy rule.** A noun phrase a golfer would say — "AROUND YOUR BUDDIES", "YOUR SEASONS", "THIS WEEK", "THE TABLE". Never a schema noun (`COUNTING CAP`, `PARTICIPATION FLOOR`, `STRUCTURE`, `PRESET`, `VERIFICATION`, `Clubhouse` as a label — all lint-checked under D249). **Never a count the rows already carry** (L-34): "REQUESTS · 2" is legal because the count is the reason the block exists and is not repeated below; "YOUR BUDDIES · 5" over five visible rows is not.

**The budget (CS-A4).** **Three eyebrow blocks per viewport.** A dateline is an eyebrow block. A section head is an eyebrow block. The ME strip's four labels are **one** block, because they are one row of one type role. `CSGroupHead` (`Surfaces.swift:189-201`) sits one level up and keeps its own rule verbatim: *"Use sparingly. Two on a page is a spine; four is a table of contents."*

**States.** A head never renders without its block. A head over an empty block renders **with P-11 under it**, never alone — an eyebrow over nothing is the shape of an unfinished screen.

**Dynamic Type / AX.** `.isHeader` rides the **title**, not the row, so the trailing link stays its own element (`Surfaces.swift:166` — this was Y-33's fix and it is correct). At AX the trailing link drops under the title. The link gets 44 pt via `a11yHitSlop` inside the label (`:171`).

**Extends / replaces.** `CSSectionHead` unchanged plus the budget lint, plus one merge: `HomeSectionHead` (`HomeView.swift:200-215`) exists only because the trailing slot is a closure and Home needs a `NavigationLink` there. It folds back in as a `Trailing: View` overload, exactly as `CSPageHeader` already does (`Surfaces.swift:93-130`).

**Used.** 34 call sites today, and every list in the new IA.

---

### P-13 · The countdown / clock chip — `CSClockChip`

**Job.** Say how long is left — once per surface, only when it is real, and only when the golfer can still act.

**Anatomy.** one capsule · mono · `mut` at rest · `warm` inside three days · ember only when the thing closing is a **live round**. No fill, no progress arc, no ticking seconds.

**Copy rule.**

- **The unit is always named.** "2 days left", never "2 left" — the App Store frame currently ships a unit-less clock that disagrees with the Clubhouse's "8 DAYS LEFT" for the same fixture (SV-16).
- **The noun comes before the clock.** "The clash closes Sunday", not "SUNDAY · CLASH".
- **Never on money** (L-10: no due-date countdown) and **never on a standing** (L-20: a standing is not an event, and pushing or counting down to one is the definition of manufactured urgency).
- **One clock per surface, from one producer.** `native_home.season.week_no` and its siblings are the week (C-8/D246); six formulas exist today and five of them stop.
- The warm-at-three rule is D176's and is kept verbatim: the chip appears from ten days out, and turns warm at three, "when the arithmetic stops being advisory" (`UpNextChips.swift:47-49`).

**States.** **loading** the chip does not render — a redacted clock is a lie about time. **empty** does not render. **error / offline** it renders `AS OF 6:12 PM` in `mut`, **never a stale countdown**; a countdown computed from a cached `generated_at` is exactly the class of defect L-44 exists for.

**Dynamic Type / AX.** Reads as a sentence — "the clash closes Sunday, two days left" — never "2 d". It never sets a fixed width; at AX it wraps to two lines rather than truncating.

**Extends / replaces.** Extends `UpNextChips.chip` (`UpNextChips.swift:50-62`), keeping the tone rule and losing the horizontal rail (which becomes P-2 items). Its producers consolidate onto `LeagueCopy.deadline` / `finalClock` and **R3**.

**Used.** The lead's dateline · a dispatch row's detail · the season page's THIS WEEK · the event's session line · the callout · the roster-closing notice · the first-tee countdown. **Not** on the pot, and **not** on a rank.

**Reads.** **R3** `season.{week_no, weeks_total, week_ends_on, days_to_first_tee, days_left, final_opens_on}` · A `home_clash` · A `event_sessions` via the event payload.

---

### P-14 · The recap / share card — `CSShareCard`

**Job.** The artifact that leaves the app. It is the product's only acquisition channel (`CLAUDE.md`: "Marketing = shareable artifacts… foursome-by-foursome, no paid acquisition"), so it is a product surface, not an export.

**Anatomy** — 1080 × 1350, **one face, ignoring the viewer's theme** (L-28: a look never touches a share card):

```
   marker medallion            gold stroke on the dusk ground — identity above everything
   NAME LINE                   mono tracked caps
   84                          Charter Bold, very large — the one figure
   BEAT YOUR NUMBER            mono, gold — the band, never a float
   by 2.4 vs your number       serif, mut — optional
   ★ PERSONAL BEST             at most ONE badge (L-42)
   ─────
   PAPAGO GC · 18 HOLES        mono
   SAT · SEP 5                 mono
   Cup Season                  serif
   cupseason.app               mono
```

**Copy rule.** Gross plus the named band phrase, third person. **No differential, no index, no league name** (D60a). At most one milestone badge. If money is named at all, `MoneyCopy.ledger` rides with it. Never a rank claimed as a seed (L-44).

**States.** It has none, and that is the rule: **a share card is rendered only from settled facts.** No pending verdict, no in-flight clash, no projected finish. A card that is wrong the day it is shared is worse than no card.

**Dynamic Type / AX.** The canvas is fixed, so Dynamic Type does not apply to the artifact — but the **export carries an accessibility description** generated from the same facts, and the share sheet around it obeys everything else. The share sheet gains the web's four controls — URL as text · Copy link · Copy message · Share… — where the phone offers a bare `ShareLink` today (`WizardLockShareSheet.swift:29-57`, D114's phone half).

**Extends / replaces.** Extends `RecapCardView` (`RecapCardView.swift:14-54`), generalised from one subject to four. Kept exactly: the fixed dark palette (`:20-25`), the marker above everything (`:38-40`), the baseline-positioned line renderer (`:56-60`).

**The four subjects and their reads.**

| Subject | Facts | Read |
|---|---|---|
| a round | gross, band, course, date, badge | as built (`PostRecap`) |
| a season | champion, margin, runner-up, points king, the pot from **collected** | `SeasonCeremonyView`'s facts + A `season_payouts` |
| a head-to-head | the record, the last five, the rivalry name | **R4** |
| a callout verdict | both grosses, the window, the result | A `event_duels.result` |

---

### P-15 · The ME strip — `CSFactStrip`

*Not in the task's minimum list; required by `INFORMATION_ARCHITECTURE.md` §4.2 and D236, and it is the pattern that stands closest to an anti-pattern, so its boundary is drawn here rather than left to a builder.*

**Job.** The four facts that belong to me and to nothing else on the screen: my number, my last round, my next round, my money. It is simultaneously the L-34 enforcement (the same fact rendered three times on one screen was persona F's finding) and the home for D129's owe line.

**Anatomy.**

```
12.4  ·  78 SAT  ·  SAT 7:10  ·  $50 YOU
YOUR NUMBER  LAST     NEXT      STILL OWE
FELLAS · 2ND OF 8 · 4 BACK OF GALEN · 2 CLEAR OF JADE · TOP 2 INTO THE FINAL
```

Four value/label pairs in one type row, plus one season context row in sans. Each slot is a **door to its receipt** (L-01).

**Why this is not a KPI strip, stated so it cannot drift (AP-3).** It is a **line of type on the page's own ground**: no `bg1`, no border, no radius, no tile, no grid, one row and not a 2×2. `CSStat` (`Components.swift:123-145`) is **explicitly forbidden inside it** — `CSStat` draws a bordered `bg1` box, which is the tile the do-not names. A tile has a box; this has a baseline. And it is *four* facts about **me**, not four facts about the league: `RoomSeasonStrip`'s four (season · the pot · your index · counting rounds, `StandingsPane.swift:173-244`) are three league facts and one of mine, which is why it reads as an admin readout.

**Copy rule.** Labels come from the terminology table, one word for one thing: `YOUR NUMBER` — or `STARTER` while the onboarding band stands, or `BUILDING` under three rounds. `LAST` · `NEXT` · `STILL OWE`. The owe slot is **absent** at $0. **No slot's fact ever appears anywhere else on the screen** — the lead hands the strip and everything below it a `suppress: Set<Fact>` (`UX_PRINCIPLES.md` §5.4).

**States.** **loading** labels visible, values redacted — the strip's shape is a promise the page keeps even before the read lands. **empty per slot**: `— · BUILDING` · `NO ROUNDS YET` · `PLAN ONE` (a door to the declare sheet) · *(owe absent)*. **error** keeps the last values under the page's stale dateline.

**Dynamic Type / AX.** **This is an acceptance test, not an afterthought.** At AX3 the four facts reflow to two rows of two and the season row wraps to three lines; nothing truncates and **nothing scrolls horizontally**. The owe slot keeps its VoiceOver action (`OweAction`, `HomeView.swift:1001-1008`). Each pair is one element ("your number, 12.4"); the season row is one element read whole.

**Extends / replaces.** **Replaces** `RoomSeasonStrip` (`StandingsPane.swift:173-244`) and the league-less Home's three mini tiles (the `A-8` frame; `RoomMini`, `RoomBits.swift:11-40`). Keeps `csTabular()` (`Typography.swift:74`) on every value so columns line up.

**Reads.** **R1** `home_dispatch().me{index_current, index_source, rounds_count, last{}, next{}, owe{}, season_row{}}` — one read, so the ME facts and the ranked list can never disagree · **R3** `profile.last_round_on`/`last_gross` (today the phone must find its own row in `home_feed.is_me`) and `standing.next_up`/`next_down`.

**Solo vs squads.** Squads reads the squad first, then me: `MUDSHARKS 1ST OF 4 · YOU 3RD OF 16 · 6 CLEAR OF THE FROST`. Solo reads me alone. **There is no tap-cycle across memberships** — that is the league switcher reintroduced in the tightest row on the screen; a second season's standing is its own dispatch item.

---

### P-16 · The receipt row — `CSMathRow` *(kept, named, and fenced)*

*Also not in the task's list, and included because it is where every figure this system refuses to print in a card must land.*

**Job.** Show the work. Every points figure, every band, every gap taps through to rows of arithmetic with their sources (L-01, spec §16).

**Anatomy.** label left, value right, a quieter `sub` tier for the arithmetic underneath. Already built and correct: `MathRow` (`SliceComponents.swift:153-176`), `RoomMathRow` (`RoomBits.swift:147-165`).

**Copy rule.** **This is the only place a signed float may appear** — in `ink`, labelled "vs your playing number", one lens, one name for it (L-14, D209). Rating, slope, allowance, the differential, the counting rank and the attestation all live here and nowhere else (L-15). No `pos`/`neg` tinting: a receipt is not a scoreboard.

**States.** **loading** redacted rows. **empty** a receipt with nothing to show does not open — the figure that would have opened it was not rendered either. **error** the sheet says what it could not fetch and keeps what it has.

**Dynamic Type / AX.** Stacks and combines at AX (already done, `SliceComponents.swift:163`, `RoomBits.swift:127`).

**Used.** The round receipt · the squad receipt · the member history · the pot's books · the head-to-head's facet table · the rules page's figures.

---

### P-17 · The safety block — `CSSafetyMenu`

*Not in the task's list, and included because **L-38 is in the immutable wall** and because this redesign is exactly the kind of change that loses it: `TourCardSheet` carries mute (`:134-137`, with its VoiceOver label) and the two-step report (`:151-169`) today, and §7 promotes that sheet into a page.*

**Job.** Put **report · block · hide · mute** within reach on every surface where a golfer meets content another golfer produced — and keep them there through any redesign, which is what L-38 and App Store Guideline 1.2 both require in those words.

**Anatomy.** A single trailing overflow control — `⋯`, 44×44, `mut` on the ground, never an accent — opening a menu:

```
  ⋯
  ├ Mute Galen          — hide their rounds from your feeds
  ├ Hide this           — this one item, this device
  ├ Block Galen         — you stop seeing each other
  └ Report              — two steps: pick a reason, then confirm
```

**Copy rule.** Function first, no euphemism, and **never a consequence the app cannot deliver**: "Mute" says *hide their rounds from your feeds*, not "you won't hear from them". The report keeps its **two steps** (a reason, then a confirmation) — one tap is an accident, and the existing two-step is the built pattern. Nothing here is a moderation claim; the app says what it does.

**Where it mounts, and this list is the acceptance test** (`INFORMATION_ARCHITECTURE.md` §18.1, test 4): **the person page** · **the head-to-head page** · **every wire row** (P-3) · **every moment page** — the Ryder, the Major, a weekend and the callout · **the board and a round's comments** (where it exists today and is unchanged) · **the peek sheet**, which keeps its own copy. The **delete-account** path stays where it is, in Card & settings, and is named here so the Guideline 1.2 walk has one list to follow.

**States.** **loading** the control renders immediately; it needs no data. **empty** n/a — it is never empty. **error** a failed report says so and keeps the sheet open; a failed mute reverts the row and says why.

**Dynamic Type / AX.** The `⋯` carries an accessibility label ("more actions for Galen"), the menu items are plain buttons, and at AX3 the menu is a sheet rather than a popover. Nothing about it is gated on a gesture.

**Used.** Everywhere in the coverage grid's new **P-17** column, which is the point: a surface with content and no P-17 has not shipped.

---

## 5 · The state contract, as one table

The compliance grid. A pattern ships when all three cells are built, not when the happy path renders.

| Pattern | Loading | Empty | Error / stale |
|---|---|---|---|
| **P-1** story card | redacted card geometry | never empty — the quiet true sentence is a lead | keeps yesterday's card, dims it, rewrites the dateline to `AS OF … · OFFLINE` |
| **P-2** dispatch row | 3 redacted rows | the row does not render | keeps values, page carries the stale dateline |
| **P-3** feed row | 3 redacted rows | **P-11** with a door | **keeps rows** — `HomeView.swift:287`'s rule, generalised |
| **P-4** chapter head | dateline + 2 serif bars | rung 6 fires at week 1 | dateline stays, story line drops (**R6** fallback) |
| **P-17** safety block | renders immediately; needs no data | never empty | a failed report keeps the sheet open and says so; a failed mute reverts the row |
| **P-5** table row | 5 redacted rows | **P-11** + "Add my round" | keeps the table |
| **P-6** rival line | redacted record | does not render — never "0–0" | drops |
| **P-7** person row | redacted rows | **P-11** | keeps |
| **P-8** intent door | *(none — no data)* | *(none)* | *(none — creation works when everything else fails)* |
| **P-9** step | control disabled, note redacted | *(n/a)* | **keeps every answer**, failure on the primary |
| **P-10** stake line | numbers redacted, labels shown | **absent entirely at $0** | keeps last values; a 0-row payout renders nothing |
| **P-11** empty | *(is a state)* | *(is the state)* | **never** — failure is its own component |
| **P-12** section head | renders with its block | never alone — P-11 under it | inherits |
| **P-13** clock chip | does not render | does not render | `AS OF <time>`, never a stale countdown |
| **P-14** share card | *(settled facts only)* | *(never built from a pending verdict)* | *(never built from a failed read)* |
| **P-15** ME strip | labels shown, values redacted | per-slot lines; owe absent at $0 | keeps last values |
| **P-16** receipt row | redacted rows | the sheet does not open | says what it could not fetch, keeps the rest |

### 5.1 Offline, said once

Offline is not a fourth state; it is the stale case with a name. The page keeps its content, dims it, and the **dateline** — not a banner, not a toast, not a modal — carries the truth: `AS OF FRI 6:12 PM · OFFLINE`. **No action is disabled.** A golfer standing on the 14th tee with no bars must still be able to open the composer, and a write that cannot land says so when it fails, not before it is attempted.

### 5.2 The surfaces that are not screens

Four surfaces render Cup Season where the app is not: the **home-screen widget** (IA §13.5), the **Live Activity** (`CSRoundActivity.swift`), a **push notification** arriving with the app closed, and the **share card** (P-14). All four obey the same laws with one addition: **they render only from a snapshot the app has already seen.** A widget never fetches a fresh ranking; it draws the last `home_dispatch` payload with its `generated_at`, and when that payload is older than the day it shows the date rather than pretending. A push landing on a closed app routes to a page that exists — every new route in IA §13.4 lands somewhere, which is the current failure mode for `.event` on a golfer with no season, and a payload whose `v` this build does not know decodes to nil and lands Home, never a blank (`PushPayload.swift:6-9, 84-101`).

---

## 6 · Dynamic Type and VoiceOver, per pattern

§3.3 is the contract; this is what is *particular* to each pattern, and it is the checklist for the AX3 screenshot pass.

| Pattern | At AX3 | VoiceOver |
|---|---|---|
| **P-1** story card | sides become a column; serif never truncates; card grows the page | one element: dateline → headline → standfirst; action is the activation; a decline is a rotor action |
| **P-2** dispatch row | action drops under the sentence | one element, action as activation |
| **P-3** feed row | photo is the background and text sets the height; gross drops under the name | one element + rotor actions for the face, the receipt and six reactions |
| **P-4** chapter head | dateline wraps, never clips ("Seaso n live" was the AX5 bug) | head is one element; the door is separate |
| **P-5** table row | three lines; column heads hidden | "1st, Galen, 27 points, up one since Sunday"; hint names what opens |
| **P-6** rival line | record drops under the names | the dots have a text alternative |
| **P-7** person row | trailing action drops under the text | the person is one button; the action keeps its own |
| **P-8** intent door | two lines; the gloss never scales | "Run a season. Weeks of golf that add up to a table." |
| **P-9** step | the disclosure header stays a button; primary stays sticky | "Step 1 of 3"; the derived note is `.updatesFrequently` |
| **P-10** stake line | the payout trio stacks | the two numbers are two elements, never blended |
| **P-11** empty | line and door stack; the door does not shrink | one element + one action; the glyph is hidden |
| **P-12** section head | trailing link drops under the title | `.isHeader` on the title only |
| **P-13** clock chip | wraps to two lines | "two days left", never "2 d" |
| **P-14** share card | *(fixed canvas)* | the export carries a description string |
| **P-15** ME strip | **two rows of two**; season row wraps to three lines; nothing scrolls sideways | each pair is one element; the owe slot keeps `OweAction` |
| **P-16** receipt row | stacks and combines | label + value in one breath |

**Reduced motion, everywhere:** the split-flap renders flat, the climb re-orders without animation, the toast fades in place, the ceremony rests on its frame, the dispatch does not animate arrival. Every one of these already has a rest frame in the code; the rule is that a new pattern may not introduce a motion without one.

---

## 7 · What changes in CSDesign — the migration table

Nothing in `Generated/Tokens.swift` changes (it is generated from `packages/tokens/tokens.json` and preflight 10 fails on drift). Everything below is `Components.swift`, `Surfaces.swift` and the app.

| # | Change | Where | Why |
|---|---|---|---|
| 1 | **Delete `CSButtonStyle.gold`** | `Components.swift:41, 73, 88`; call sites `LeaguelessDoors.swift:88`, `StandingsPane.swift:140`, `SeasonCeremonyView.swift:67` | L-25, CS-A2. All three sites are "Run it back — Season 2", which starts something **live** and is therefore ember. The champion's name in the same viewport keeps the gold |
| 2 | **`CSEmptyState` → `CSEmpty`, door required, `glyph` not emoji** | `Components.swift:151-176`; five call sites in §4 P-11 | CS-A3, AP-5 |
| 3 | **Delete `CSBands.pviChip` from every card surface** | `CSBands.swift:92-94`; call sites `RoundStoryCard.swift:77-83`, `PostRoundScreen.swift:428`, `Career.swift:134-160`, `Rivalries.swift:64`, `StandingsTableView.swift:105-108`, `IndividualRaceView.swift:80` | AP-2 / L-14. The signed float survives only in P-16 |
| 4 | **`CSStat` is fenced** — legal alone on a receipt, never in a row of two or more | `Components.swift:123-145` | AP-3. The component is fine; the *row of them* is the anti-pattern |
| 5 | **Add `CSStoryCard`, `CSDispatchRow`, `CSWireRow`, `CSChapterHead`, `CSTableRow`, `CSRivalLine`, `CSPersonRow`, `CSIntentDoor`, `CSStep`, `CSStakeLine`, `CSClockChip`, `CSFactStrip`** | new files in `CSDesign` (presentational) with their copy producers in `CupSeasonKit` | one pattern, one implementation, two clients able to share the producer |
| 6 | **Move `cs.squad(_:)` into CSDesign** | from `Board/BoardSupport.swift:20` to beside the palette | the spine's squad tone is a component law and currently lives in the Board's helpers, which is why `LiveCardView.swift:219` grew a second copy |
| 7 | **Fold `HomeSectionHead` into `CSSectionHead`** via a `Trailing: View` overload | `HomeView.swift:200-215` → `Surfaces.swift:152-181` | one section head, as `CSPageHeader` already models (`Surfaces.swift:93-130`) |
| 8 | **Retire the three horizontal rails** | `UpNextChips.swift:9-79`, `EventChips.swift:13-46`, `HomeLeagueRows` `HomeView.swift:1015-1069` | AP-3 and O-09/D229. Their content becomes P-2 items and P-13 chips |
| 9 | **Retire `RoomSeasonStrip` and `PhaseHero`** | `StandingsPane.swift:173-244`, `RoomBits.swift:125-146` | AP-3, SV-11/SV-12; replaced by P-15 and P-1/P-4 |
| 10 | **`pos` stops being chrome** | `CardAndSettingsScreen.swift:358-361`, `MembersSheet.swift:132-138`, `DeclareRoundSheet.swift:176-181`, `DraftBits.swift:70, 156, 159`, `BoardScreen.swift:46` | SV-06 / IOS-003 §1. Selection is an ember ring (the marker grid already does it right); titles are `mut`/`ink` |
| 11 | **Gold leaves what was not taken off somebody** | the index — `YouHero.swift:53` (the hero spine) and `:80` (the figure) · the founder mark — `FoundingTag.swift:16, 18` and `PeopleScreen.swift:239` · rank numerals and `IN` chips — `ClimbView.swift:52, 61` · a tee time, `YOU'RE IN`, `LEAGUE MATE` and `ON THE TEE SHEET` — `ScheduleScreen.swift:80, 97-99, 127, 140, 207-209` | SV-07. Five champagne elements sit on one identity card. An index is a measurement, a founder tag is a fact, and a tee time is a clock — none of them was taken off anybody. Gold is trophies (`YouTrophyChip`, `YouHero.swift:154-163`, which is correct and stays), the lead, the pot and a champion's name. The leader's table hairline stays gold |
| 12 | **Drawn achievement glyphs** | `TrophyMeta.swift:42-56`, `EventPickerSheet.swift:26-27` | AP-5. One stroke family, engraved in mono; and two achievements may not share a glyph (`sub_100` and `sub_90` both use 🎯 today) |
| 13 | **Two spinners in content become redacted shapes** | `WizardScreen.swift:49`, `PotPane.swift:104` | L-32. `CSButton`'s busy spinner (`Components.swift:58`), `RoomMini`'s (`RoomBits.swift:24`) and `RootView`'s boot (`RootView.swift:132`) are controls and the app frame — they stay |
| 14 | **`CSDate.short` on every date a card prints** | `BoardLogic.swift:75-78` prints a raw `2026-04-12` in the App Store frame | L-07, SV-15 |

**What does not change, and is worth saying so nobody "tidies" it:** `CSCard`'s spine geometry (`Components.swift:31-35`), `CSHero`'s look/gold contract (`Surfaces.swift:44-45`, `Look.swift:47-48`), `CSDuskCard` (`Surfaces.swift:64-85`), `CSPhotoScrim`'s two measured ramps and its arithmetic guarantee (`PhotoScrim.swift:46-85` — a component with a test under it, which is the standard the rest of this system should reach), `CSFace`'s no-silhouette floor (`Marker.swift:44-98`), `CSToastCenter` (`Toast.swift`), `A11yStack` and the two hit-target helpers (`A11y.swift`), `CSMotion.roll`, `CSHaptic`'s vocabulary, `CSTabStrip`, `CSPageHeader`, `CSGroupHead`, `CSRow`, `CSHairline`, `RankFlipText`'s split-flap.

---

## 8 · The component checks — CL-1 … CL-12

**They are numbered `CL-n`, not `L-n`, and the renumber is not cosmetic.** This document cites the wall's immutable laws as **L-02, L-07, L-19, L-25, L-40, L-42** and its own checks as **L-1 … L-12**, and both appeared **in the same table cell** (AP-2 read "… (L-14, L-15, D209/D210) | L-2"). A leading zero was the whole distinction, in the document whose thesis is *one name for one thing*. The collisions were real on sight: check L-2 against law L-02 (rounds are immutable), L-4 against L-04 (grants), L-5 against L-05 (migrations), L-11 against L-11 ($0 is the default), L-12 against L-12 (the covenant). **Every reference in this set now reads `CL-n` for a component check and `L-nn` for a law.**

The terminology checks (`TERMINOLOGY.md` §4, twenty-nine of them, D249/IOS-036) are separate and live with the vocabulary. These twelve guard the **components**, in the same shape as preflight check 20 (the `STAGE_LABEL` pattern, roughly 25 lines each) and check 15 (palette purity), and they run on **both clients**.

| # | Check | Fails when | Reads 0 today? |
|---|---|---|---|
| **CL-1** | gold on a control | `cs.gold` inside a `Button` label, a `CSButton`, a tab item or a nav; `style: .gold` anywhere | **no** — 3 sites |
| **CL-2** | **signed** float outside a receipt | `pviChip(`, `vsShort(`, or `"%+.1f"`-shaped formatting outside `Rounds/RoundReceiptSheet.swift` and `League/ReceiptSheets.swift`. **It does not fail on `"%.1f"`** — an unsigned figure inside an authored sentence labelled against your number is legal (AP-2's carve-out, T-07/D209-D210), and as first written this check would have failed the lead's own producer | **no** — 6 surfaces |
| **CL-3** | empty with no door | *(compiler-enforced once P-11's door is non-optional)* + a grep for a list whose empty branch is a bare `Text` | **no** — 2 surfaces have no branch at all |
| **CL-4** | emoji outside reactions | an emoji literal outside the six-reaction table and `RXLABEL` | **no** — 8 achievement glyphs, 3 event icons, 5 empty-state icons |
| **CL-5** | eyebrow budget | more than **three** eyebrow blocks in one view file's body (`.csEyebrow(`, `CSFont.eyebrow`, `CSFont.label` + `textCase(.uppercase)`) | **no** — 8 in one viewport |
| **CL-6** | accent budget | more than **two** accent tokens (`brand`, `gold`, `dawn`) referenced in one screen file, excluding `pos`/`neg` at their semantic homes and the heat ramp at its mechanic homes | **no** — 4 in one viewport |
| **CL-7** | serif on a control | `CSFont.sentence*`, `hero*`, `figure` or `wordmark` inside a `Button` label or a `TextField` | yes |
| **CL-8** | unclocked movement | `▲`, `▼` or the word `held` rendered without an adjacent "since" or a run length | **no** — `StandingsTableView.swift:130-138` |
| **CL-9** | spinner in content | `ProgressView()` outside `CSButton`, `RoomMini`, `RootView` and a named allowlist | **no** — 2 |
| **CL-10** | the ledger line | any string literal containing "keeps the ledger" other than `MoneyCopy.ledger` / `CS_LEDGER` | yes |
| **CL-11** | raw date in a card | a `playedOn`/`starts_on`-shaped value interpolated without `CSDate` / `localDate()` | **no** — `BoardLogic.swift:75-78` |
| **CL-12** | the 11 pt floor | `Font.custom(…, size: n)` with `n < 11` | yes |

Six of twelve read non-zero at tip. That is the honest state of the component layer and it is the work, stated as a number.

**The screenshot gate.** Every pattern, four frames: charcoal at default · charcoal at AX3 · light at default · light at AX3. A pattern with no four-frame set has not shipped. The harness exists (`-cs_dev_open`, `docs/ios/accessibility.md`) and the wave-8 method — launch, screenshot, read, fix, re-shoot — is the one to repeat.

---

## 9 · Where each pattern is used

Rows are the IA's surfaces; a ✓ means the surface is built from that pattern. Read it as a coverage check: a surface built from patterns nobody else uses is a surface that will drift.

| Surface | P-1 | P-2 | P-3 | P-4 | P-5 | P-6 | P-7 | P-8 | P-9 | P-10 | P-11 | P-12 | P-13 | P-14 | P-15 | P-16 | **P-17** |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Home — the dispatch** | ✓ | ✓ | ✓ | | | ✓ | | ✓ | | | ✓ | ✓ | ✓ | | ✓ | | ✓ |
| **Compete — the peer list** | | ✓ | | | | | | ✓ | | | ✓ | ✓ | ✓ | | | |  |
| **The intent sheet** | | | | | | | ✓ | ✓ | ✓ | ✓ | | | | | | |  |
| **⊕ Play — the cover** | | ✓ | | | | | | | | | | | | | | |  |
| **The composer** | | | | | | | ✓ | | ✓ | | | | | | | |  |
| **The epilogue** | ✓ | | | | | ✓ | | ✓ | | | | | | ✓ | | ✓ |  |
| **The season page** | ✓ | ✓ | ✓ | ✓ | ✓ | | ✓ | | | ✓ | ✓ | ✓ | ✓ | | | ✓ | ✓ |
| **The season's story page** | | | ✓ | ✓ | | | | | | | ✓ | ✓ | | ✓ | | | ✓ |
| **The rules page** | | | | | | | | | | ✓ | | ✓ | | | | ✓ |  |
| **A moment (Ryder / Major / weekend)** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | | | ✓ | ✓ | ✓ | ✓ | | | ✓ | ✓ |
| **The callout** | ✓ | ✓ | | | | ✓ | ✓ | ✓ | ✓ | ✓ | | | ✓ | ✓ | | | ✓ |
| **Golfers** | | ✓ | | | ✓ | ✓ | ✓ | ✓ | | | ✓ | ✓ | | | | | ✓ |
| **The person page** | | ✓ | ✓ | | | ✓ | ✓ | ✓ | | | ✓ | ✓ | | | | ✓ | ✓ |
| **The head-to-head page** | | | ✓ | | | ✓ | ✓ | ✓ | | ✓ | ✓ | ✓ | | ✓ | | ✓ | ✓ |
| **You / Your record** | | ✓ | ✓ | ✓ | | ✓ | ✓ | | | ✓ | ✓ | ✓ | | ✓ | ✓ | ✓ |  |
| **Onboarding** | ✓ | | | | | | ✓ | ✓ | ✓ | | | | | | | |  |
| **The covenant** | ✓ | | | | | | ✓ | | | ✓ | | ✓ | ✓ | | | |  |
| **Draft night** | ✓ | ✓ | | ✓ | | | ✓ | | ✓ | | ✓ | ✓ | ✓ | | | |  |
| **The ceremony** | ✓ | ✓ | | | ✓ | | ✓ | | | ✓ | | ✓ | | ✓ | | ✓ |  |
| **The cancel vote** | ✓ | ✓ | | | | | ✓ | | | ✓ | | | ✓ | | | |  |
| **The widget** | ✓ | ✓ | | | | | | | | | | | ✓ | | ✓ | |  |

Seventeen patterns cover twenty-one surfaces. **P-8** (the intent door) and **P-14** (the share card) are the two that appear least and matter most to the brief's funnel — they are the doors in and the artifact out.

**Read the P-17 column as a rejection risk, not a nice-to-have.** Nine surfaces carry other golfers' content, and **L-38 is in the immutable wall**: report, block and hide must exist on every one of them and must *survive any redesign* (App Store Guideline 1.2). Before this pass the column did not exist and neither did the pattern — the whole set's only mention of L-38 was a parenthetical about muting a tagger, asserted for a set of surfaces that did not exist when it was true. **A ✓ in this column is checked by using the control, not by finding it**, and the walk is `INFORMATION_ARCHITECTURE.md` §18.1's fourth acceptance test.

---

## 10 · What only the owner can rule

Four component-level questions. Each is a taste or a cost call, not a law, and none of them blocks the rest. **P-17 is not among them** — L-38 is immutable and a safety control is not a taste call.

1. **Does `dawn` retire from list links?** SV-05's recommendation is links in `ink` underlined or in `mut`, with `dawn` kept for one trailing section-head link. `dawn`'s token role is "links & live states" (`Generated/Tokens.swift:31`), so constraining it is a component rule and not an override — but it touches "Add golfers", "Show earlier", "THE CALENDAR ↗" and "YOUR BUDDIES ↗", and someone should look at a screen with them in `ink` before it is decided.
2. **Who draws the trophies?** AP-5 says the achievements stop being emoji. The marker paths come from the web's `MARKERS` table through `tools/build-markers.mjs`; an achievement family is a **new asset pipeline** and a real cost. The cheap interim — engraving the title in mono on the dusk ground with no glyph at all — is arguably better than either, and is one line.
3. **The dateline face: 11 pt or 12 pt?** CS-A1 recommends 12 (`CSFont.eyebrow`). The IA's §4.3 says 11. It is one token either way and it is the top line of the most-seen card in the product.
4. **Does the split-flap survive the new table?** It is a ceremony (L-31) and it is beautiful, but it fires on a fresh load of a table that now carries a clause per row, and two motions in one block may be one too many. Recommendation: keep it, and let the clause arrive without animation.

---

## 11 · The one-page summary a builder can hold

- **One card grammar:** mono dateline · serif headline · sans standfirst · one ember verb. The spine says the state.
- **Two metals, never swapped.** Ember acts. Gold is earned. Everything else is ink or `mut`. **Two accents per viewport, three eyebrow blocks.**
- **Three type voices, three jobs.** Serif never on a control. Mono never in prose. Nothing below 11 pt.
- **A figure is a band word.** The signed float lives in the receipt and nowhere else.
- **Every pattern declares three states.** Loading is a redacted shape. Empty has a door. **A failed read keeps what is on screen.**
- **One fact, one place** — enforced by `suppress`, not by judgement.
- **Every number taps to its work.**
- **Say both branches.** Solo and squads; the Pro and a member. If a pattern behaves the same in both, say that too.
- **Every surface with somebody else's content carries P-17** — report, block, hide, mute. L-38 is in the wall and Guideline 1.2 is the price of forgetting.
- **A signed number lives in the receipt. An unsigned figure in a sentence labelled against your number is legal anywhere.** That is the whole of AP-2, and CL-2 is written to it.
- **Component checks are `CL-n`. The wall's laws are `L-nn`.** Never the same register.
- **Four frames per pattern:** charcoal and light, default and AX3.

---

## 12 · Known gaps

| # | The gap | Why it is recorded rather than resolved | What reopens it |
|---|---|---|---|
| **1** | **Six of the twelve component checks read non-zero at tip** — CL-1 (3 sites), CL-2 (6 surfaces), CL-3 (2), CL-4 (16 glyphs), CL-5 (8 in one viewport), CL-6 (4 in one viewport), CL-8, CL-9, CL-11. | That is the honest state of the component layer and it is the work, stated as a number rather than as an intention. A check that is written but not passing is still a check that stops the *next* regression. | Each is fixed in the wave that owns the surface; CL-4's sixteen glyphs wait on §10 question 2 (who draws the trophies). |
| **2** | **P-14's share card and P-8's intent door are the least-covered patterns and the most load-bearing** (§9). Neither has a four-frame screenshot set yet. | They are new surfaces; the frames come with the build. | The first light-theme pass, which §9's own note calls the first thing to check. |
| **3** | **No pattern in this set has its four frames** (charcoal/light × default/AX3). The harness exists (`-cs_dev_open`) and the method is wave 8's — launch, screenshot, read, fix, re-shoot. | A screenshot gate on a pattern that has not been built is a plan, not a check. | Each pattern's own build; the gate is that a pattern with no four-frame set has not shipped. |
| **4** | **The two web halves of P-1 and P-15 are unspecified in this document.** R-C builds the web inline in a sidebar-and-wide-body shape, so a story card and a fact strip both need a desk rendering. | The producers are shared and the copy is identical; what differs is layout and density, which `INFORMATION_ARCHITECTURE.md` §16 owns rather than this document. | The web half of Wave 1a and 1b — the fact strip in the sidebar, the dispatch in the left column. |

---

*Companions: `INFORMATION_ARCHITECTURE.md` (§4.3 the card grammar, §17.1 the file-by-file migration, §18.1 the acceptance tests including the Guideline 1.2 walk), `UX_PRINCIPLES.md` (§4 the identity contract, §5 the ranking rule), `HOME_STATE_MATRIX.md` (what P-1, P-2 and P-15 render in every state), `TERMINOLOGY.md` §4 (the twenty-nine **terminology** checks — kept separate from the twelve **component** checks CL-1…CL-12 above), `DECISIONS_TO_LOG.md` (IOS-036 ships both suites).*
