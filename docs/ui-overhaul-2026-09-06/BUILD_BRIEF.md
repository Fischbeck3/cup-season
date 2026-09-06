# BUILD_BRIEF — Cup Season, the hard UI overhaul, Phases 3–7

**Written** 2026-09-06 · **From** HEAD `57b993f` · **For** the build session (Opus, a later day, no
memory of the design session) · **Standard** `BRIEF.md` §30, Phases 3–7 · **Bar** `BRIEF.md` §29: 8 on
every dimension of every screen; below 6 is a redesign.

> **You are implementing a design that is finished.** `UI_SYSTEM.md` and the seven files in
> `surfaces/` are exact. Where they and this file disagree, **this file wins** — §2 and §3 record the
> handful of arithmetic conflicts the design left open and resolve each one, so you never have to ask.
> Where this file is silent, `UI_SYSTEM.md` is the answer.
>
> **You never `git push` and you never `supabase db push`.** §9. Preflight, build, test, screenshot,
> commit locally, hand the commands to the owner.
>
> **Nothing in this overhaul changes a competition mechanic.** Not one rule of `spec/spec-v1.0.md`
> moves. If a change you are about to make alters what a number *means* rather than how it is *set*,
> stop: you have left the UI layer.

---

# 0 · READ FIRST, IN THIS ORDER

Read all fourteen before you write a line. The first six are the design; the rest are the rails.

| # | File | Why, in one line |
|---|---|---|
| 1 | `docs/ui-overhaul-2026-09-06/BRIEF.md` | The owner's brief, verbatim. §30 is the phase order you execute; §29 is the bar; §31–§33 are the three things that most often go wrong. |
| 2 | `docs/ui-overhaul-2026-09-06/UI_AUDIT.md` §1 | The one-page verdict, the **ten problems** (every wave below names the ones it closes) and **the four things that must survive**. |
| 3 | `docs/ui-overhaul-2026-09-06/UI_SCORECARD.md` | The 25-row Phase-1 baseline, the systemic caps, and the **TARGET** section — three blind reviewers' scores of the design. §8 of this file is how you re-score against it. |
| 4 | `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md` | **The visual language, and it replaces `IOS-003` §1 as the identity contract.** Read §0 (the idea, the signature, what changed and why), §1 type, §2 colour + §2.9 the tokens diff, §3 containers, §4 spacing, §5–§13 the components, §14 the desk, §15 surface characters, §16 accessibility, §16A the copy laws, §17 the lint, §18 the glossary. §19 lists the mockups' known imperfections; §20 lists the refutations already declined — do not re-file them. |
| 5 | `docs/ui-overhaul-2026-09-06/surfaces/*.md` | Seven surface specs — home · player-card · profile · course · season · event · leaderboard. Each carries anatomy, every state, AX3 as a layout, VoiceOver, the files it replaces, what it consumes unchanged, new data, motion, the web paragraph, and its deviations. **One spec per Phase-3 wave.** |
| 6 | `docs/ui-overhaul-2026-09-06/mockups/renders/` and `system-mockups/renders/` | 33 phone artboards (402 × 874 @2×), one 1440 × 900 desk artboard, and 8 system specimens. Look at them before each wave. `UI_SYSTEM.md` §19 says exactly what each proves and where each is imperfect. |
| 7 | `CLAUDE.md` | Working protocol rules **1–6** (talk first · never hand-edit the version · design and structure ride separately · everything shows its work · **log every mechanic change before it is built** · one branch one machine), the deploy discipline, **the phone section** (native work runs locally; `packages/` is the shared source and the Swift artifacts are GENERATED), and the landmines. |
| 8 | `docs/ux-overhaul-2026-09-04/COMPONENT_SYSTEM.md` | The 17 UX patterns (P-1…P-17) this visual system **clothes**. The IA of the components is settled. Do not re-argue what a surface carries; change only how it looks. |
| 9 | `docs/ux-overhaul-2026-09-04/OWNER_RULINGS.md` | **R-C** — the web is its own desktop-first shape, a sidebar and a wide two-column body, and every wave has a phone half and a web half. **R-A** — the five destinations. Rulings outrank artifacts. |
| 10 | `docs/ux-overhaul-2026-09-04/TERMINOLOGY.md` §4 | The 34 retired-word patterns, whose scope explicitly includes `.accessibilityLabel`. `LINT-27` is the check. "the Tour Card" → **the card** · "duel" → **the clash** · "session" → **Week n of N** · "floor" → **the monthly minimum** · "tee sheet" → **the schedule**. |
| 11 | `docs/ux-overhaul-2026-09-04/README.md` §5 and `OVERHAUL_REPORT.md` §5 | **The wave format this file follows** — a table of waves, three sequencing rules, a phone half and a web half per wave, an acceptance test per wave. §8 of the report is the ship command list, which is unchanged. |
| 12 | `docs/ux-overhaul-2026-09-04/EVIDENCE_POLICY.md` | **No production count of behaviour is evidence.** The product has not launched. Reason from the brief, the audit and the canon. |
| 13 | `spec/brand-canon.md` and `brand/README.md` | The promise ("where amateur golf counts"), the voice, the one rule (gold means earned, never chrome), and the **wordmark setting** — IBM Plex Mono 600, 0.32em, caps, which this overhaul does **not** re-cut (`UI_SYSTEM` §12.3). |
| 14 | `docs/ios/IOS-003-design-direction.md` §1 | The **superseded** contract. Read it only so you recognise what changed; `UI_SYSTEM.md` §0.3 is the diff, row by row, with a reason on every line. |

**Also on the shelf, cited but not read cover to cover:** `apps/ios/README.md` (build and run),
`tests/preflight.mjs` (the gate), `packages/tokens/tokens.json` (the token source),
`tools/build-tokens.mjs` (the emitter you are about to change), `spec/decision-log.md` and
`docs/ios/DECISIONS.md` (where §6's entries go).

---

# 1 · THE NON-NEGOTIABLES

**Ten rules. If one of them is broken, this is not the design — it is a different design that shares a
palette.** Each names the check that catches it, so none of them depends on anyone remembering.

### 1 · A container needs a job, and there are only three jobs.
The **panel** (one opaque tile, ≤96 × 96, one figure or one word, radius 3, never a sentence), the
**leaf** (a sheet of scorecard paper, and it must contain a grid), the **object** (a physical artefact
a golfer would keep — the credential, the settlement card). Everything else is **band, rule, rail and
whitespace**. `CSCard` is deleted, **there is no border token**, and **no container may contain
another container**. *Answers audit problem 1 and `BRIEF` §6/§32.* — `LINT-08`, `-10`, `-19`, `-20`.

### 2 · The rank rail and the rule-and-figure are the signature.
Every ranked list in the product starts with the **44pt rail** carrying a two-digit tabular numeral,
painted `gold` when the position was earned, `panel` when the row is yours, unpainted otherwise. Every
figure at 27pt or above sits on a **2pt rule the width of its column** with an agate label beneath —
`ink` by default, `brand` live, `gold` earned. *Numbers never wear a box; boxes wear numbers.* Remove
the logo and these two devices still say Cup Season. — visual review, §8.

### 3 · A golf number is a visual object.
**One `figure` role at 56 / 40 / 27 / 20**, tabular, in the board face. A number inside a sentence is a
**figure run** — the same board face at the sentence's size, produced from a marked string, **never
found by a regex over prose**. Ten renderings of the gross become three. No score is ever set in
`mut` at 13pt. *Answers audit problem 2 and `BRIEF` §16.* — `LINT-02` (the tabular assertion), §8.

### 4 · Two metals, and they are scarce by construction.
**Ember = live, and the one primary action. Champagne = earned, and nothing else.** One gold object per
viewport, **counted by hue, not by token name**; at most **two ember marks** per viewport, counting
every fill, rule, glyph, dot and word outside the tab band. **Gold may never touch a control** — no
gold button, no gold tab, no gold status, no gold on a course's rating (an average of opinions is not
earned). *Answers audit problem 5 and `BRIEF` §27.* — `LINT-11`, `-17`, `-18`.

### 5 · Typography carries the brand, and the budget is counted on the screen.
Nine roles, fourteen symbols, three families (IBM Plex Sans Condensed bundled, IBM Plex Mono already
bundled, SF Pro, New York — **Charter is retired**). **One `display` per viewport. At most ten
tracked-caps agate lines per viewport**, counting chips, buttons, sub-lines and column heads. **One
serif appearance per viewport.** Every role declares a leading and a text style; nothing renders below
11pt at the default size; uppercase is produced by `.textCase(.uppercase)` and never by
`.uppercased()`. *Answers audit problem 7 and `BRIEF` §5.* — `LINT-01`, `-03`, `-07`, `-14`, `-15`,
`-16`.

### 6 · A person is drawn exactly one way, and their mark never moves.
**`CSFace` is the only legal path.** The bare-glyph path (`FriendsBoard.swift:70` and five siblings) is
**deleted, not patched**. A profile's marker is a frozen pair — `(pigment, glyph)` — resolved once from
the profile row and never re-derived per surface, per theme, per size or per component. **There is no
initials rung below the marker**; initials draw only when a golfer chose nothing. No silhouette. **No
fabricated face, ever, including in the demo diorama.** A face appears in every table row, every wire
item with a person in it, the clash, the field, and the desk. *Answers audit problem 3.* — `LINT-26`,
visual review.

### 7 · An image is one of three things, or the space collapses.
**(1)** a golfer's own round photo at that course, credited in agate; **(2)** the drawn card, generated
from real par, stroke index and yardage, numbered 1–18; **(3)** the contour plate, a seeded
value-noise field. **Never** stock, a licensed image the product does not have, a generated aerial
presented as real, a fabricated face, or **a gradient wash**. A course with none of the three shows
**no thumbnail at all**. A surface's flagship state renders the **top** legal rung; the fallbacks are
proved on their own named variants. *Answers `BRIEF` §11/§20.* — visual review.

### 8 · Ink laws: the scorecard has no colour, and money is never a P&L.
Birdie is a ring, eagle a double ring, bogey a box, worse a double box — drawn in ink at 1.7pt, in both
themes, on every scorecard in the product. **Money is `ink`; the pot and anything won are `gold`; the
sign is a word in agate (`YOU OWE` / `YOU'RE OWED` / `THE POT`); `pos` and `neg` never touch money.**
The ledger line renders verbatim from **one constant**, printed **once per client**, at the foot of the
money surface. *Answers `BRIEF` §16 and the audit's DD-05.* — `LINT-23`, visual review.

### 9 · Every component declares five states, and the empty state's door is a compiler error.
Default · pressed · disabled · loading · empty, for every control. `configuration.isPressed` and
`isEnabled` are read 0 times in the product today; that is the finding. **A disabled primary is never
ember.** Loading is **the destination's own geometry, redacted** — never a spinner inside content. An
empty state is **a drawn object, an eyebrow, a headline that is a fact about the world, one true fact,
a door, and a number** — all of it, or none of it. `CSEmpty(door:)` takes a **non-optional `Door`
enum** with `.primary` / `.link` / `.elsewhere`. *Answers audit problems 4 and 8, `BRIEF` §17/§18/§23.*
— `LINT-21`, `LINT-22`, the Swift compiler.

### 10 · Two clients, one system, two shapes — and every value comes from `tokens.json`.
Owner ruling **R-C** / **D234**: **every wave has a phone half and a web half and is not done until
both ship.** The desk is a 236pt sidebar and a `1fr + 340pt` body, never the phone's tabs reflowed.
Colours, radii, spacing, alphas, tracking and type stacks all flow from `packages/tokens/tokens.json`
through `tools/build-tokens.mjs`; **no literal survives in Swift or in `index.html`**. — preflight
check 10 (design tokens single-source), check 15 (swift palette purity), `LINT-04`, `-05`, `-06`.

---

# 2 · THE TOKENS DIFF

`packages/tokens/tokens.json` is the source. `tools/build-tokens.mjs` emits four artefacts:
`packages/tokens/tokens.css`, `packages/tokens/tokens.ts`,
`apps/ios/Packages/CSDesign/Sources/CSDesign/Generated/Tokens.swift`, and
`.../Generated/Looks.swift`. **Preflight check 10 compares `tokens.json`'s stored string to
`index.html`'s CSS declaration byte for byte and fails on a stale generated file**, so all of it moves
in one commit or nothing does.

## 2.1 The emitter changes FIRST, and it is not optional

**As the repo stands, the first command of Phase 3 throws.**
`tools/build-tokens.mjs:117` does an unguarded `entries.find(([, n]) => n === 'glow')[2].dark` and
`:118` does the same for `grad` — both of which this diff deletes. `TypeError: Cannot read properties
of undefined` means nothing is regenerated and check 10 then fails permanently with "generated tokens
are stale", and nothing else in the overhaul can start.

Three edits to `tools/build-tokens.mjs`, in the same commit as the token edits:

1. **Delete the `glow` / `gradStops` block** (`:117-122`) and its two `CSTokens.glow` /
   `CSTokens.gradStops` call sites. (Guarding the two `find`s is acceptable; deleting is cleaner,
   because both tokens are gone.)
2. **Add three emitter groups beside `Radius`** (`:124`): `public enum Space`, `public enum Alpha`,
   `public enum Track`. The emitter walks `colorTokens` (anything whose value is a `#rrggbb`) and then
   **four groups by name** — `radius`, `type`, `motion`, `shadow`. Any other non-colour group reaches
   `tokens.css` and `tokens.ts` and is **silently dropped from `Tokens.swift`**. Without this there is
   no `CSTokens.Space.s4`, no `Alpha.a56`, no `Track.agate` on the phone, and `LINT-06`/`-07` have no
   set to compare against.
3. **The stored shape**, because check 10 is a byte comparison: `space` values are stored as
   **`"20px"`**, `alpha` as a **bare number** (`0.56`), `track` as a **bare number** (`0.09` — a ratio
   of the rendered point size, not a length).

## 2.2 `packages/tokens/tokens.json` — changed

| Group · token | Dark: from → to | Light: from → to |
|---|---|---|
| `ground.bg0` | `#0B1410` → **`#0F1A15`** | `#EFF2EE` → **`#F4F1E9`** |
| `ground.bg1` | `#131D17` → **`#1A2620`** | `#FBFCFA` → **`#EAE6DB`** |
| `ground.bg2` | `#1A2820` → **`#26352E`** | `#E5EAE4` → **`#DED8C8`** |
| `ground.line` → **rename `ground.rule`** | `#24352B` → **`#4A6155`** | `#D9DFD7` → **`#A9A08A`** |
| `text.ink` | `#F0F2F3` → **`#F1F4EF`** | `#1A2620` → **`#151B17`** |
| `text.mut` | `#8E979E` → **`#9BA69D`** | `#52625A` → **`#575F57`** |
| `text.dim` | `#5C646B` → **`#5E6A62`** | `#8C9992` → **`#8B9089`** |
| `semantic.pos` | unchanged `#4EC584` | `#0B793F` → **`#0B7340`** |
| `semantic.neg` | `#FF5F56` → **`#FF6A5E`** | `#BE3831` → **`#B02A20`** |
| `metal.gold` | unchanged `#D8B25A` | `#846415` → **`#7A5A12`** |
| `metal.brand` | unchanged `#E8622C` | `#B3461C` → **`#A8420F`** |
| `heat.cool` → **move to `semantic.cool`** | `#66707A` → **`#7F8C95`** | `#6E7A84` → **`#5D6862`** |
| `squad.sq0–sq3` | `#57A8FF` `#FB8B4B` `#A78BFA` `#2FD3BE` → **`#366F87` `#B27E7C` `#97B999` `#EDD4FA`** | `#2C7CD3` `#DE6A22` `#7A58DE` `#0D9E8F` → **`#002B40` `#603E35` `#4C705D` `#8B88A8`** |
| `type.serif` | `'Charter','Iowan Old Style',…` → **`ui-serif, 'New York', 'Iowan Old Style', Georgia, serif`** | same |

## 2.3 `packages/tokens/tokens.json` — added

| Group | Tokens (dark / light) |
|---|---|
| **`object`** *(new group)* | `panel` `#E9ECE3`/`#141A16` · `panelInk` `#0B120E`/`#F4F1E9` · `panelMut` `#4C574F`/`#A6AEA5` · `leaf` `#EFEADD`/**`#FFFDF7`** · `leafInk` `#1A1B14` both · `leafMut` `#57605A`/`#5A625A` |
| **`object`** *(the ceremony ramp — pinned in BOTH themes, because a physical object does not re-print)* | `ceremony` `#0A0E0C` · `ceremonyInk` `#F1F4EF` · `ceremonyMut` `#9BA69D` · `ceremonyBrand` `#E8622C` · `ceremonyGold` `#D8B25A` · `ceremonyPos` `#4EC584` · `ceremonyCool` `#7F8C95` · `ceremonySq0–3` = the **dark** `sq0–sq3` values |
| **`object`** *(named so nothing is invented in Swift — these are the five off-palette literals the specs had written inline, consolidated to four)* | `crest` `#33463B` both · `folioRule` `#8B8F8B` both · `scrimInk` `#F1F4EF` both · `scrimMut` `#CBD2C8` both |
| **`pigment`** *(new group)* | `pig0–pig5` dark `#492D2C` `#473C28` `#293B2B` `#1F4648` `#293B4E` `#4E3C4F` · light `#FDDAD8` `#E6D8C2` `#D6EBD7` `#BEE4E7` `#D9EAFF` `#EED9EE` |
| **`space`** *(new group, stored as `"NNpx"`)* | `s1` 4 · `s2` 8 · `s3` 12 · `s4` 20 · `s5` 32 · `s6` 52 · `gutter` 20 · `gutterDesk` 40 · `rail` 44 · `hair` 1 |
| **`radius`** | add `p` `3px` · `rx` `28px` (joining `r` 16, `rc` 10, `rs` 24) |
| **`alpha`** *(new group, bare numbers)* | `a08` .08 · `a16` .16 · `a24` .24 · `a56` .56 · `a88` .88 |
| **`track`** *(new group, bare numbers — see §2.5 for the resolved set)* | `flat` 0 · `tight` −0.01 · `d1` 0.005 · `d2` 0.01 · `caps` 0.035 · `caps2` 0.04 · `agateS` 0.08 · `agate` 0.09 · `ord` 0.05 |
| **`type`** | `board` — `'IBM Plex Sans Condensed', system-ui, sans-serif` |
| **`motion`** | `snap` — `cubic-bezier(.2,0,0,1)` |
| **`shadow`** | `leaf-shade` — `0 1px 0 rgba(0,0,0,.22)` |

## 2.4 `packages/tokens/tokens.json` — removed

`ground.line2` (86 Swift sites) · `metal.dawn` (27 sites) · `metal.pine` (0 sites) ·
`heat.warm` · `heat.hot` · `heat.fire` (40 sites between them) · `heat.focus` (the focus ring becomes
`brand`) · `effect.glow` · `effect.grad` (`BRIEF` §4's named do-not, verbatim) ·
`shadow.shadow-rest` (0 references).

Also: every `looks[].motif` emoji becomes a **drawn-glyph name** (`LINT-12` fails the codepoints);
`looks[].accent` / `accent2` keep their values and gain the fence in `UI_SYSTEM` §2.7 — a look tints
**the rail and the eyebrow only, never a ground**.

## 2.5 Four arithmetic conflicts the design left open, resolved here

**Resolve them this way and do not re-open them.** Each is a place where two parts of `UI_SYSTEM.md`
or a surface spec disagree on a number.

1. **`track` needs nine values, not four.** §1.2's table asks for display +0.5%, displayS +1%, name
   +3.5%, nameS +4%, agate +9%, agateS +8%, columnM −1%, and §1.7's ordinal +5% — which the stated
   four-token group cannot express, and `LINT-07` needs a set to compare against. **The nine values in
   §2.3 above are the resolved group.** Record it in the decision entry (§6, D268).
2. **`leaf` light is `#FFFDF7`.** §2.1 prints `#FCFAF3`; §2.9 and §3.3 both print the correction.
   **`#FFFDF7` is the value.**
3. **The slat's columns are §9.1's REVISED set.** `leaderboard.md` §1's table (movement 34pt, gap 42pt,
   points 50pt) predates the blind-review revision. The shipped row is: **rail 44 · face 30 · `s3` 12 ·
   name (flexible, `min-width: 0`, tail ellipsis) · a merged gap+movement cell 58pt right-aligned ·
   points 50pt · `gutter` 20.** The header row `POS · GOLFER · GAP · PTS` ships **at every field size**,
   including the season page's. A held row prints **one** mark. At a field of ten or more, **every** row
   abbreviates the given name to an initial before any name is truncated.
4. **The 375pt (SE) arithmetic is recomputed for the merged cell.** §16.3's `234pt` of fixed columns
   was the pre-revision set. The fixed columns now total **214pt**, leaving **188pt** for the name at
   402 and **161pt** at 375. Build to those numbers; derive every fixed column from the measure rather
   than hard-coding it.

Also settled, so nobody looks it up twice: **`LINT-nn` is this document's namespace and `L-nn` is
`UX_PRINCIPLES.md`'s.** Twenty-six ids collide and the surface specs cite both in the same paragraphs.
When a spec says `L-25`, it means `UX_PRINCIPLES.md`.

## 2.6 The other four files that move in the same commit

| File | Edit |
|---|---|
| `index.html:36` | the Google Fonts href becomes `…css2?family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans+Condensed:wght@600;700&display=swap`. **`type.board` is a CSS stack and a stack does not load a face** — without this the desk silently renders 46% of its type in `system-ui`, which is D258's exact failure mode on the client D234 calls half the product. `netlify.toml:30`'s CSP already allows `font-src https://fonts.gstatic.com`. |
| `index.html`'s two `:root` blocks | merge into one and take the new `space`, `alpha`, `track`, `radius` and `type` groups. They currently sit 2,287 lines apart. |
| `apps/ios/project.yml:92` **and** `apps/ios/CupSeason/Info.plist:53` | **both** carry the `UIAppFonts` array and **both** need `IBMPlexSansCondensed-SemiBold.ttf` and `IBMPlexSansCondensed-Bold.ttf`. One without the other is D258 again. |
| `apps/ios/CupSeason/Resources/Fonts/` | drop the two TTFs beside the three Plex Mono files. **OFL 1.1** (Bold Monday for IBM), ~124 KB each ≈ **248 KB**. PostScript names `IBMPlexSansCondensed-SemiBold`, `IBMPlexSansCondensed-Bold` — **read them from the files' own name table (id 6), do not remember them**; that is precisely how D258 happened. |

**If the bundle is refused**, the fallback is `Font.system(…, design: .default).width(.condensed)` at
the same point sizes: every layout in the design holds, the voice is weaker, and nothing else changes.
The identity is the rail, the rule-and-figure and the ink scorecard, not the face.

## 2.7 The preflight checks that will fire, and the order to run them

```bash
node tools/build-tokens.mjs      # must not throw — §2.1 first, or it does
node tests/preflight.mjs         # expect PASS — 0 failure(s), 0 warning(s)
```

- **check 10 · design tokens single-source** — fires on any disagreement between `tokens.json` and
  `index.html`, and on a stale `Tokens.swift` / `Looks.swift`. This is the one that blocks everything.
- **check 15 · swift palette purity** — fires on an invented hex or `Color(red:` outside
  `Generated/Tokens.swift`. Four surface specs had written five off-palette literals into Swift
  (`#33463B`, `#2A3A32`, `#2C3B33`, `#CBD2C8`, `#D2D8CE`); §2.3's four `object` names are why they now
  pass.
- **check 34 · the 11px floor** and **check 39 · the phone holds the 11pt floor** — `agateS` 11 and
  `columnS` 12 are the floor; nothing may go under.
- **check 38 · the bundled faces resolve** — becomes `LINT-02` and gains the tabular assertion (§3).
- **checks 12–14 / 15–17** are the web/native palette, OTP and RPC-grant pairs; unchanged.

**The twenty-nine new `LINT-nn` checks land with a baseline, or they land nothing.** They fall on
roughly 2,300 existing sites (`LINT-06` 1,387 · `LINT-10` 354 · `LINT-14` 194 · `LINT-07` 177 ·
`LINT-09` 151 · `LINT-05` 264 · `LINT-03` 80), and `ship.sh` refuses to ship anything if preflight
fails — so the commit that adds them would block every push for the rest of a multi-session build.
**Each check gets an entry in `tests/preflight-baselines.json` holding today's count and fails only
when the count RISES**, hardening to zero-tolerance the moment its baseline reaches 0. The hardening
order is the order the code changes: `01/02/04` (already zero) → `11/12/13/23/25/26` → `03/05/10` →
`06/07/14` → `08/15/16/17/18` (the probes, once `CSBudgetProbe` exists) →
`09/19/20/21/22/24/27/28/29`.

---

# 3 · THE COMPONENT WORK IN `CSDesign`

`apps/ios/Packages/CSDesign/Sources/CSDesign/` — thirteen files today (`A11y`, `Components`,
`Look`, `LookSky`, `Marker`, `PhotoScrim`, `Surfaces`, `SVGPath`, `Theme`, `Toast`, `Typography`, plus
`Generated/{Tokens,Looks,Markers}.swift`). Tests are
`apps/ios/Packages/CSDesign/Tests/CSDesignTests/{CSDesignTests,LookAccentTests}.swift`.

**The single highest-leverage change the audit names**: primary/secondary/tertiary become
**`ButtonStyle`s, not a `View`**. That one move removes the reason four sites hand-copy the ember fill,
gives every button a pressed state for free, and lets `ShareLink`, `NavigationLink` and `Menu` wear the
brand. 90 of ~317 tappables carry a shared definition today; the target is all of them.

## 3.1 DELETE — with the call-site count each one has to migrate

| Symbol | File | Sites at HEAD | Replaced by |
|---|---|---|---|
| `CSCard` | `Components.swift:15` | **20** | band · rule · rail · panel · leaf |
| `CSStat` | `Components.swift:123` | **12** | `CSFigure` (the rule-and-figure) |
| `CSEmptyState` | `Components.swift:151` | **6** | `CSEmpty` (door is non-optional) |
| `CSButton` (a `View`) | `Components.swift:43` | **90** | `CSButtonStyle.primary/.secondary/.tertiary` as `ButtonStyle`s |
| `CSButtonStyle.gold` (the enum case) | `Components.swift:41` | 0 direct | **the tier does not exist** |
| `CSHero`, `CSWash`, `CSDuskCard` | `Surfaces.swift:38,18,67` | 2 + 2 | `CSBand`, `CSObject` |
| `CSHairline` | `Surfaces.swift:169` | **34** | `CSRule` (1px) / `CSRule.heavy` (2pt ink) |
| `CSLookSky` | `LookSky.swift:27` | **5** | nothing — one ground, painted once (audit F-04/F-05) |
| `RoomSpark` | app-side | **3** | nothing — its own doc comment calls it "Decoration" |
| `CSMini`, `RoomMini`, `MiniPill`, `MiniButton`, `ArmedMini` | app-side | **55 + 29 + …** | `CSChip` · `CSButtonStyle.secondary` · `CSDoor` |
| `PostSeg`, `WizardSeg`, `EventSeg`, `FlowSeg`, `LiveSeg` | app-side | 5 families | one `CSSegment` (44pt row, no pill, ink underline) |
| `FoundingTag` | `You/FoundingTag.swift` (32) | 1 | `CSSlot` — it draws a `Capsule().stroke()` and carries a `✦` |
| `pviChip`, `CSTickRow`, `PressMeter` | app-side | — | nothing · `CSSeasonCalendar` · nothing |
| `CSFont` (18 roles) | `Typography.swift` | **850** | `CSType` (14 symbols) |

## 3.2 CHANGE — the file and what happens to it

| File | Change |
|---|---|
| `Typography.swift` → **`Type.swift`** | `CSFont` becomes **`CSType`**, §3.3's API. The two Plex Mono PostScript names stay; the two Plex Sans Condensed names join them; `serifRegular`/`serifBold` (Charter) are **deleted** and the serif becomes `Font.system(size:weight:design:.serif)`. **These four strings are the only `.custom(` face names in the product** (`LINT-01`). `csEyebrow()` and `CSEyebrowStyle` are deleted — the eyebrow is a role, not a modifier. `csTabular()` **survives** at all 69 sites. |
| `Marker.swift` | `CSFace` gains the six-pigment ground keyed to the golfer's id, the 1px inset ring, five tokenised sizes, the optical cap-height re-fit of the fourteen markers, and the frozen `(pigment, glyph)` pair. `CSMarkerView` becomes **internal** — no call site outside `CSFace`. |
| `PhotoScrim.swift` | `CSPhotoScrim` gains **three named geometries** — `.title` (bottom-anchored, for a name reversed out of a plate), `.band` (leading-anchored, for a wire photo band), `.top` (`0% ceremony a72 → 96pt clear`, for any plate running under the status bar). The stops are in `UI_SYSTEM` §10.3. **`PhotoScrimTests` is extended before any of this ships** — it holds `mut` body copy today and the system now puts `display` 34, `social` 17, `agateS` and a chevron stroke on the same scrim, against a **high-frequency** subject. This is a gate, not a follow-up. |
| `Surfaces.swift` | `CSSectionHead` gains the **right-of-rule count slot** (a count or a period, **never** a proper name, a date, a range, a filter or a link — §16A.2). `CSPageHeader` keeps its AX3 stacking branch (a "what works") and its `Trailing:` overload. `CSMotion` gains **`snap`** = `timingCurve(0.2, 0, 0, 1, duration: 0.18)`; `roll` is unchanged and `reduced` still resolves to `nil`, never "faster". `CSRow` survives. `CSGroupHead` and `CSTabStrip` fold into `CSSectionHead` and `CSSegment`. |
| `Theme.swift` | `CSAppearance` gains a **launch-argument override** (§4, Wave 0) and the **Increase Contrast** substitutions: `mut` → `ink` at `a88` · `rule` → `mut` · `a56` → `a88` · `a24` → `a56`, resolved here rather than per site. Add the **ceremony resolution rule**: on the `ceremony` ground every token resolves to its dark value in both themes. |
| `A11y.swift` | `A11yStack` generalises `MeStripLayout`'s model — reflow on the **measured advance of the actual characters at the size the golfer is reading**, never on a device breakpoint. `ViewThatFits` is 0 in the product and `horizontalSizeClass` appears twice; this is the replacement for both. |
| `Toast.swift` | `CSToast.Item` gains `kind` (`.confirmed` / `.failed` / `.neutral`) and an optional single action. 46pt, `rc` 10, `bg2`, a 3pt leading kind rail plus a drawn glyph — shape **and** colour. 134 `toast.show(` sites currently pass `id` and `text` only. |
| `Look.swift` / `Generated/Looks.swift` | `CSLookAccent.spine(earned:)` is deleted with the spine. A look tints **the rail field and the eyebrow only**. Every `motif` becomes a drawn-glyph name. |
| `Components.swift` | reduced to `CSHaptic` (kept verbatim — `IOS-003` §2.8's vocabulary), `CSField` (rebuilt, §3.3), `CSNote`, `CSTone`, the environment plumbing, and `CSTabBarChrome` (which becomes `CSTabBand`'s measurement, `CSTabBarProbe.dressAndMeasure()` kept). |

## 3.3 ADD — the new API, in Swift, file by file

**All names are `UI_SYSTEM.md` §18's, and the build uses them verbatim.** Signatures below are the
contract; bodies are yours.

### `Type.swift`
```swift
public enum CSType {
  // The ONLY face strings in the product (LINT-01). Read from each file's name table, id 6.
  static let boardSemi   = "IBMPlexSansCondensed-SemiBold"
  static let boardBold   = "IBMPlexSansCondensed-Bold"
  static let monoRegular = "IBMPlexMono-Regular"
  static let monoMedium  = "IBMPlexMono-Medium"

  // figure — board bold, tabular. 56 / 40 / 27 / 20. Leading .92 / .94 / .96 / 1.00.
  // Caps ×1.5 / ×1.5 / ×1.45 / none. relativeTo .largeTitle / .largeTitle / .title / .title3.
  public static func figureXL(_ d: DynamicTypeSize) -> Font
  public static func figureL (_ d: DynamicTypeSize) -> Font
  public static func figureM (_ d: DynamicTypeSize) -> Font   // the rail's 27; ×1.45 is load-bearing
  public static func figureS (_ d: DynamicTypeSize) -> Font

  // display — board bold, UPPER. 34 / 24. Track d1 / d2. Cap ×1.6 / ×1.8.
  public static func display (_ d: DynamicTypeSize) -> Font
  public static func displayS(_ d: DynamicTypeSize) -> Font

  public static var name:   Font { get }   // board semi 17, UPPER, track caps,  lh 1.16
  public static var nameS:  Font { get }   // board semi 15, UPPER, track caps2, lh 1.16
  public static var social: Font { get }   // board semi 17, Title Case, flat,   lh 1.16
  public static var lead:   Font { get }   // New York bold 28, tight, lh 1.14, cap ×1.5
  public static var story:  Font { get }   // New York reg 20, flat,   lh 1.34, cap ×1.6
  public static var body:   Font { get }   // SF Pro Text 17, lh 1.45
  public static var bodyS:  Font { get }   // SF Pro Text 15, lh 1.45

  // agate — board semi 12 / 11, track agate / agateS, lh 1.20, floored at 11pt, cap ×2.2.
  public static func agate (_ d: DynamicTypeSize) -> Font
  public static func agateS(_ d: DynamicTypeSize) -> Font

  public static var column:  Font { get }  // Plex Mono 500, 17,        lh 1.30
  public static var columnM: Font { get }  // Plex Mono 500, 14, tab,   lh 1.25, track tight
  public static var columnS: Font { get }  // Plex Mono 400, 12, tab,   lh 1.20
}
```
**Fourteen symbols. No surface may name a size that is not one of them.** The three capped roles
(`figure`, `display`, `agate`) are the reason six of them take a `DynamicTypeSize`:
`Font.custom(_:size:relativeTo:)` offers no ceiling, so a capped role computes
`min(UIFontMetrics(forTextStyle: style).scaledValue(for: base), base * cap)` and passes it to
`Font.custom(_:fixedSize:)`, re-reading on every size change. Every other role uses `relativeTo:` and
never caps. **Tracking is a ratio of the *scaled* size**, so exactly one call site multiplies —
`CSType`'s own — and `LINT-07` exempts only that one.

Case is the role's job: a role applies `.textCase(.uppercase)`. `agate` has **one case switch** — caps
for a *label*, sentence case for a *phrase a person could read aloud* — and only the caps form counts
against §1.5's budget of ten. Bold Text (`@Environment(\.legibilityWeight)`) moves `agate`, `name` and
`social` from SemiBold 600 to **Bold 700**; both cuts are bundled, so it costs nothing.

### `Structure.swift`
```swift
public struct CSBand<Content: View>: View {              // full-bleed tone or ceremony field, radius 0
  public enum Kind { case tone, ceremony }
  public init(_ kind: Kind = .tone, @ViewBuilder content: () -> Content)
}
public struct CSRule: View {                             // the ONLY divider. replaces CSHairline + Divider()
  public enum Weight { case hair, heavy }                // 1px `rule` · 2pt `ink`
  public enum Metal  { case ink, live, earned }          // heavy only: ink / brand / gold
  public init(_ weight: Weight = .hair, metal: Metal = .ink, inset: CGFloat = 0)
}
public struct CSPanel<Content: View>: View {             // ≤96×96, one figure OR one word, radius p 3
  public enum Ground { case page, overPhoto }            // .overPhoto reads CSTokens.dark.panel explicitly
  public init(_ ground: Ground = .page, unit: String? = nil, @ViewBuilder content: () -> Content)
}
public struct CSLeaf<Content: View>: View {              // scorecard paper; MUST contain a grid
  public init(@ViewBuilder content: () -> Content)
  public static func earnedRule() -> some View           // reads CSTokens.light.gold in BOTH themes
}
public struct CSPlate<Content: View>: View {             // an image field: photo / drawn card / contour
  public enum Fit { case bleed, inset32, thumb }         // radius 0 · p 3 · p 3
  public init(_ fit: Fit, credit: String? = nil, @ViewBuilder content: () -> Content)
}
public struct CSObject<Content: View>: View {            // radius r 16 + shadow-lift. The credential, the settlement card
  public init(@ViewBuilder content: () -> Content)
}
```
**No container may contain another container** (`LINT-08`, a render-time probe). The panel's tripwire:
*if it ever holds a sentence, it has become a card* (`LINT-19` — >12 characters or a space fails). The
leaf's test: *it must contain a grid* (`LINT-20`).

### `Figures.swift`
```swift
public struct CSFigure: View {                           // THE RULE-AND-FIGURE — the signature
  public enum Size  { case xl, l, m, s }                 // 56 / 40 / 27 / 20
  public enum Metal { case ink, live, earned }           // the 2pt rule's colour
  public init(_ value: String, size: Size, metal: Metal = .ink, label: String?, ordinal: String? = nil)
  // A figure ≥27 ALWAYS carries the rule and the agate label.
  // A figure INSIDE a panel carries neither — the panel's edge is the rule.
  // A figure repeating down a table's trailing column carries neither — position is the hierarchy.
  // The ordinal rider: board 700, UPPERCASE, 0.44–0.46 em, tracked .05em, ON THE BASELINE. Never raised.
}
public struct CSFigureRun: View {                        // a numeral in the board face inside a sentence
  public init(_ marked: String, font: Font)              // "Galen shot {74} at Papago" — the producer marks it
  public init(_ text: String, runs: [NSRange], font: Font)
  // NEVER a regex over prose: a regex also restyles dates, money, ordinals and digits inside course
  // names, and rewrites the AttributedString runs VoiceOver reads.
}
public struct CSMovement: View {                         // drawn triangle + tabular numeral, on the page's ground
  public enum State { case up(Int), down(Int), held }    // pos ▲ / cool ▼ / a 9×2 `mut` bar
  public init(_ state: State)                            // NO field, NO pill, NO tint. ▼ means one thing: you fell.
}
public struct CSScoreMark: View {                        // ring · double ring · nothing · box · double box
  public init(_ strokesOverPar: Int)                     // 1.7pt, currentColor, NO COLOUR in any theme
}
```

### `Board.swift`
```swift
public struct CSRankRail: View {                         // 44 × row height, radius 0
  public enum Field { case earned, mine, none }          // gold + panelInk · panel + panelInk · unpainted + mut
  public init(_ rank: Int, field: Field)                 // figure 27, tabular, two digits, leading zero, centred
}
public struct CSSlat<Trailing: View>: View {             // full-bleed, min-height 50, one `rule` on the top edge
  public init(rank: Int, field: CSRankRail.Field, face: CSFace.Model,
              name: String, sub: AttributedString,       // sub-line is agate in SENTENCE CASE
              squad: (Color, String)? = nil,             // swatch + NAME — only when structure != solo
              movement: CSMovement.State?, gap: String?, // ONE 58pt right-aligned cell
              @ViewBuilder trailing: () -> Trailing)     // the points figure, 50pt, right-flush
  // Body inset = rail 44 + s3 12 = 56 left, gutter 20 right. Name column min-width 0, tail ellipsis.
  // The viewer's own row reads `YOU` alone, product-wide. One VoiceOver element per row.
}
public struct CSStandingsBoard: View {                   // column heads + N slats + an optional CSCut
  public init(rows: [Row], cut: Cut?, abbreviateNames: Bool)   // abbreviate at a field of 10+, per BOARD not per row
}
public struct CSCut: View { public init(_ label: String) }      // `CUT · TOP TWO PLAY THE CUP FINAL`
public struct CSHoleStrip: View { public init(holes: [Hole], current: Int?) }  // 18 cells ≥20pt, single ring/box only
public struct CSTape: View { public init(meetings: [Meeting], key: String) }   // viewer filled, rival outlined, one key line
public struct CSSeasonCalendar: View { public init(weeks: Int, played: Int, now: Int, months: [Month]) }
public struct CSClash: View { public init(left: CSFace.Model, right: CSFace.Model, figure: CSFigure) } // NO boxes
```

### `Person.swift`
```swift
public struct CSFace: View {                             // THE ONLY LEGAL WAY TO DRAW A PERSON
  public struct Model: Hashable {                        // resolved ONCE from the profile row
    public let id: UUID                                  // pigment = pig[hash(id) % 6] — deterministic, frozen
    public let marker: String?                           // the glyph key — frozen; never re-derived per surface
    public let photoURL: URL?
    public let initials: String                          // drawn ONLY when marker == nil. There is no initials rung.
    public let isViewer: Bool                            // marker takes `ink` rather than `mut`
  }
  public enum Size: CGFloat { case inline = 24, slat = 30, list = 38, block = 56, crest = 120 }
  public init(_ model: Model, size: Size, sideRing: Color? = nil)   // sideRing = 2.5pt, team events ONLY
}
public struct CSFaceRow: View {                          // overlapping (a GROUP) or spaced with names (a ROSTER)
  public enum Style { case overlapped, roster }
  public init(_ faces: [CSFace.Model], style: Style, groups: [(String, Color)] = [])
}
public struct CSMedallion: View { public init(_ marker: String) }   // gold marker on ceremony ground, 1px gold ring
public struct CSCredential: View {                       // 362 × 312 (≈7:6), radius r 16, shadow-lift, ceremony ground
  public enum Presentation { case hero, held, sharePNG } // full measure · 0.82 · the ONE 3:4 crop
  public init(_ golfer: Golfer, presentation: Presentation = .hero)
  // Anatomy is UI_SYSTEM §6.5's table and NOTHING may restate it: plate · slot · medallion · name ·
  // identity line · three figures on ONE ceremonyInk rule · folio. Crest OR corner medallion, never both.
}
public struct CSSlot: View { public init(_ label: String) }   // 24pt gold field, panelInk agateS. One per surface.
public struct CSFolio: View { public init(club: String, serial: String) }  // a16 rule + folioRule agateS
```

### `Controls.swift`
```swift
public struct CSPrimaryStyle: ButtonStyle {}             // 50pt, rc 10, brand fill, bg0 label
public struct CSSecondaryStyle: ButtonStyle {}           // 50pt, rc 10, bg2 fill, ink label
public struct CSTertiaryStyle: ButtonStyle {              // intrinsic, 44pt target, name 15 + a rule beneath
  public enum Placement { case live, content, toolbar }  // 2px brand · 2px mut · 1px mut. NEVER ember off `.live`.
  public init(_ placement: Placement)
}
public extension ButtonStyle where Self == CSPrimaryStyle { static var csPrimary: Self { … } }
// … csSecondary, csTertiary(_:), csDestructive
public struct CSChip: View {                             // 28pt, radius p 3, agate. SELECTED INVERTS TO THE PANEL.
  public init(_ label: String, selected: Bool, enabled: Bool = true)
}
public struct CSSegment<T: Hashable>: View { }           // 44pt row, NO pill, 2px INK underline (a tab is not live)
public struct CSField: View {                            // 50pt, rc 10, bg2, NO border. Focus = 2px `brand` ring.
  public init(label: String, text: Binding<String>, caption: String?, error: String?,
              limit: Int?, kind: Kind)                   // .prose (SF) | .code (Plex Mono: code/handle/time/score)
  // The full family: label · value · caption · error · character counter at 80% of a limit · disabled · loading.
}
public struct CSStepper: View { }                        // 44pt, bg2, figure 20, BARE — no ring, no box (§9.4)
public struct CSDoor: View {                             // a primary, a secondary or a tertiary link — P-8
  public enum Kind { case primary(String, () -> Void), secondary(String, () -> Void), link(String, () -> Void) }
}
```
**One primary per screen**, and it is ember. **There is no gold button.** Dismiss is one thing:
`Close`, a **toolbar** tertiary (`mut`, 1px rule, never ember) at `topBarTrailing`, in every sheet and
every cover — no xmark circle, no coloured "Done" (`LINT-25`). The confirming action lives in the body,
at the foot, as the sheet's one primary. **Objects are pushed; actions are presented.**

### `States.swift`
```swift
public struct CSEmpty: View {
  public enum Door {                                     // NON-OPTIONAL. The Swift compiler is LINT-21.
    case primary(String, () -> Void)
    case link(String, () -> Void)
    case elsewhere(String)                               // a reference line, not a control
  }
  public init(glyph: CSGlyph, eyebrow: String, headline: String, fact: String?, number: Number?, door: Door)
  // headline is a FACT ABOUT THE WORLD, never the golfer's omission. Test: could the golfer have
  // prevented this sentence by doing something? If yes, rewrite it.
  // Two absences never share a glyph. The glyph's name IS its accessibility label.
}
public extension View { func csRedacted(_ loading: Bool) -> some View }  // the destination's own geometry, redacted
public struct CSStale: View { public init(asOf: Date) }  // `AS OF FRI 6:12 PM · OFFLINE`, no action disabled
```

### `Chrome.swift`
```swift
public struct CSMasthead: View { public init(date: Date) }   // pennant 22 · s2 · wordmark · dateline flush right · 2pt ink rule
public struct CSTabBand: View { }                        // full-width band on bg0, 1px rule on top, 74pt + safe area
                                                         // 22pt DRAWN glyph + agateS label; selected = ink + 26×2pt ink underline
                                                         // Play = the drawn ⊕ in `brand`. NO fill, NO disc, NO square.
public struct CSGlyph: View {                            // ONE drawn family: 1.7pt on a 24×24 box, round caps, no fill
  public enum Size: CGFloat { case inline = 13, row = 17, tab = 22, block = 28 }
  public init(_ name: Name, size: Size = .row)           // `pennant` is RESERVED to CSTabBand + the app icon (LINT-28)
}
public struct CSStakeLine: View { }                      // money in ink, the sign as a word, the pot in gold
public struct CSFactStrip: View { }                      // the ME strip — P-15. 2–4 figures on ONE rule + the standing line
public struct CSStoryCard: View { }                      // Home's lead — P-1. NOT a card: a block on the ground
public struct CSRating: View { }                         // rule-and-figure 40 in INK + CSStarRail + one sentence + a link
public struct CSStarRail: View {                         // five drawn stars, filled ink / unfilled rule, halves by CLIPPING
  public init(_ value: Double, editable: Bool)           // 362 × 56 continuous drag target + a 44pt −½/+½ stepper pair
}
public struct CSCoursePlate: View { }                    // plate + CSPhotoScrim.title + the reversed name + the credit
public struct CSFactsLine: View { }                      // `72 PAR · 7,068 YDS · 72.5 RTG · 130 SLOPE` — ONE LINE OF TYPE
public struct CSQuote: View { }                          // the course page's one serif appearance
```

### `Probe.swift`
```swift
public struct CSBudgetProbe: PreferenceKey {             // LINT-08/15/16/17/18 are RENDER-TIME, not greps
  public struct Counts { var agateCapsLines, display, goldObjects, emberMarks, nestedContainers: Int }
}
// CSType.display, .agate, .agateS, every gold-taking component and CSButtonStyle.primary increment it
// as they render. Every root asserts under #if DEBUG; the preview snapshot tests assert in CI.
// A per-file grep counts the wrong thing in both directions: Home's agate lines come from four
// components at one apiece, and the gold rail lives in CSRankRail while the pot lives in CSFigure —
// so a grep sees ZERO gold in SeasonPage.swift, the surface that carries two.
```

## 3.4 Tests that ship with the components

- **`CSDesignTests`** gains: the tabular assertion (render `0000000000` against `1111111111` in each
  bundled face, assert equal advance — `csTabular()` is `.monospacedDigit()`, documented for *system*
  fonts, and on `Font.custom` it resolves through the descriptor's `kNumberSpacingType`); the
  `figureM` ×1.45 cap (two digits ≤ 42.3pt inside the 44pt rail at AX3); the `agate` ×2.2 cap; the
  frozen `(pigment, glyph)` pair for a fixed id across both themes and all five sizes; the ordinal's
  baseline geometry; the slat's fixed columns summing to 214pt.
- **`PhotoScrimTests`** is **extended before Wave 1** — four roles on the same scrim, against a
  high-frequency subject, not a two-stop wash. **This is a gate.** Until it exists, the design's
  signature move — a name reversed out of an image — is unproven everywhere it appears.
- **Preview snapshot tests** per component, asserting `CSBudgetProbe` under CI. This is how
  `LINT-08/15/16/17/18` run at all.

---

# 4 · THE WAVES

Twelve waves. **Wave 0 is not in `BRIEF.md` §30 and it comes first anyway**, because §30's Phase 3 says
"redesign the highest-visibility surfaces" and every one of those surfaces is assembled from components
that do not exist yet. Waves 1–7 are §30's Phase 3, in §30's order. Wave 8 is Phase 4, Wave 9 Phase 5,
Wave 10 Phase 6, Wave 11 Phase 7.

**Three sequencing rules that are not preferences** (the last overhaul's, and they held):

1. **Wave 0 gates everything.** It carries no surface change. It carries the tokens, the emitter, the
   fonts, the app icon, the whole component vocabulary, the lint with its baselines, and **the two
   capture hatches** — without which no wave after it can be signed off in light or at AX3.
2. **Every wave has a phone half and a web half and is not done until both ship** (R-C / D234). §5
   carries the web half of each.
3. **A wave's decision-log entry is committed in the same commit as the code it governs, never after**
   (`CLAUDE.md` rule 5). §6 has the entries drafted.

**The screenshot recipe**, used for every acceptance test below:

```bash
xcodebuild -project apps/ios/CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath apps/ios/build/dd-ui build
xcrun simctl install booted apps/ios/build/dd-ui/Build/Products/Debug-iphonesimulator/CupSeason.app
xcrun simctl launch booted app.cupseason.ios <hatch args>
sleep 6 && xcrun simctl io booted screenshot <out>.png
```

**Shoot every acceptance test three ways: dark, light, and AX3.** That is what Wave 0's two hatches
buy, and it is the difference between this review and the last one.

---

## WAVE 0 · THE GATE — tokens, faces, the component vocabulary, the lint, the two hatches

**Scope.** No surface changes. Everything §2 and §3 describe, plus the app icon and the two capture
hatches. Nothing after this wave can be reviewed without it.

**Files.**
`packages/tokens/tokens.json` · `tools/build-tokens.mjs` · `packages/tokens/tokens.{css,ts}` ·
`apps/ios/Packages/CSDesign/Sources/CSDesign/Generated/{Tokens,Looks}.swift` (regenerated, never
hand-edited) · `index.html` (the two `:root` blocks, the font href at `:36`) · `apps/ios/project.yml:92`
· `apps/ios/CupSeason/Info.plist:53` · `apps/ios/CupSeason/Resources/Fonts/` (+2 TTFs) ·
`apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/` (`brand/appstore-1024.png` ships, with the
iOS 18 **dark** and **tinted** variants filled in `Contents.json` — the shipped icon is Xcode's blue
placeholder and **nothing in this overhaul costs less to fix or costs more to leave**) ·
`apps/ios/Packages/CSDesign/Sources/CSDesign/*` (13 rewritten + ~10 new files per §3.3) ·
`apps/ios/Packages/CSDesign/Tests/CSDesignTests/*` · `apps/ios/CupSeason/CupSeasonApp.swift` (the two
hatches) · `tests/preflight.mjs` · `tests/preflight-baselines.json` (new).

**The two capture hatches — build them here, not in Wave 10.** `UI_SYSTEM` §16.6:
`CupSeasonApp.swift:15,27` applies `preferredColorScheme` from `UserDefaults`, so
`xcrun simctl ui … appearance light` **never reaches the UI**, and
`-UIPreferredContentSizeCategoryName` **does not take**. Every light-theme and AX3 statement in the
design is computed, never seen. Add **`-cs_dev_appearance <light|dark|auto>`** overriding
`CSAppearance` at launch, and **`-cs_dev_text_size <category>`** injecting a `dynamicTypeSize` at the
root, both `#if DEBUG` and both in the hatch list.

**Implements.** `UI_SYSTEM.md` §1–§13, §17, §18; the system specimens
`system-mockups/renders/cs-system-{a,b,c}.png`.

**Acceptance test.** A `CredentialDev`-style harness screen (`-cs_dev_developer`) rendering every
component in every declared state, shot **dark / light / AX3**, and compared to `cs-system-a`
(the nine roles at size · the rule-and-figure in three variants · the panel at three sizes · the
scorecard ink law · the six pigments · the medallion), `cs-system-b` (the three button tiers and their
states · the chip and its inversion · the field with label, caption and error · the movement marks ·
the empty state) and `cs-system-c` (loading as redacted geometry · the toast in both kinds · the AX3
layout). **Must be visible:** the condensed board face actually rendering (not SF Pro — that is
D258's whole lesson); tabular digits lining up; the panel inverting between themes while the leaf does
not; a pressed state on every tier; a disabled primary that is not ember.

**Gates.** `node tools/build-tokens.mjs` (must not throw) · `node tests/preflight.mjs` **PASS, 0
failures, 0 warnings** · `node tests/sunningdale.test.mjs` · `xcodebuild test -scheme CupSeason`
(788 tests, 133 suites at HEAD — the number must not fall) · the new `CSDesignTests` and the extended
`PhotoScrimTests`.

**Files touched: ≈60.**

---

## WAVE 1 · HOME / FEED — *the front page* (`BRIEF` §30 Phase 3.1, §7)

**Scope.** The masthead and dateline · the lead at weight 1 · the ME strip as four figures on one rule
with the standing line and the ledger line · the wire at **five distinct weights** (competition moment ·
friend's round · course discovery · season moment · minor activity) · the floor's four doors · the tab
band. **Do not make every feed item visually equal** — that sentence is `BRIEF` §7 and it is the wave.

**Files.** `CupSeason/Home/HomeView.swift` (1,060 — **rewritten**; `HomeModel`, `LoadKey`, `ranked()`,
`feed(upcoming:spent:)`, `toggle(round:emoji:)`, the lead→deck→strip precedence, the `suppress` union,
the failed-vs-empty branch at `:181-184` and `:516-519`, the widget-snapshot write and the refresh keys
**all survive unchanged**; the view body and its seven private row types are replaced) ·
`Home/HomeLeadCard.swift` (**replaced**; `HomeDeckCard` **deleted** — ranked items 2–5 become wire
items at their earned weight) · `Home/MeStrip.swift` (396 — **replaced by `CSFactStrip`**; the
`emberKey` rule at `:353-361` is **kept and widened to the whole page**) ·
`Schedule/UpNextChips.swift` and `Schedule/UpcomingRoundsSection.swift` (**deleted from Home**, kept on
the schedule) · `People/InvitesBanner.swift` · `People/BuddyRequests.swift` (replaced in place by the
weight-1 block) · `Board/RoundStoryCard.swift` (**extended into weight 2**; the photo ground, the
medallion and the scrim survive; the PvI chip and the `COUNTING #N THIS MONTH` line are deleted) ·
`Home/HomeSocial.swift` (the reaction strip: the count beside each emoji becomes `agateS` in the
system's own face, baseline-aligned) · `Home/HomeDispatch.swift` (no data change; the **item key is the
weight map**) · new `CSStoryCard`, `CSFactStrip`, `CSMasthead` in CSDesign · `Home/HomePreviews.swift`.

**Implements.** `surfaces/home.md` in full; `UI_SYSTEM` §15.1, §12.1, §12.3, §16A.4.

**Acceptance test.** Thirteen shots from `-cs_dev_home_state <state>` — `brand_new`,
`rounds_no_buddies`, `buddies_no_competition`, `event_ahead`, `event_live`, `between_seasons`,
`ceremony_night`, `inactive`, `invited`, `callout_pending`, `preseason`, `round_morning`,
`round_evening` — plus a plain launch, `-cs_dev_bottom` (the four doors) and `-cs_dev_bar` (the live
bar). Compare to `mockups/renders/home/{home-live,home-quiet,home-new,home-light,home-feed-weights}.png`.
**Must be visible:** the wordmark over a 2pt rule with the dateline flush right; LIVE as a **7pt ember
dot plus an ember agate eyebrow**, never a band; **at most two ember marks** on the viewport; the ME
strip with **no box**; a **face** in every wire item that has a person in it (Home has never carried
one); **three of the five wire weights below the fold**, because HOME's character is rhythm and rhythm
is only visible where a golfer scrolls; the tab band on the page's own ground with a rule on top and
the ⊕ as an **ember glyph with no disc**; **ceremony night and a brand-new account rendering as
visibly different surfaces** (they are the same card with a different eyebrow word today).

**Closes audit problems** 1, 2, 3, 5, 7, 10.

**Gates.** preflight · `xcodebuild test` · `LINT-15/16/17/18` probes asserting on the Home root.

**Files touched: ≈18.**

---

## WAVE 2 · THE PLAYER CARD — *the credential* (Phase 3.2, §9)

**Scope.** One object, one chrome, one ratio, one meta string. `CSCredential` at **362 × 312**,
measure-relative (335 × 289 on an SE), on the `ceremony` ground **in every theme**, pushed rather than
presented. The clash. The Golfers board row.

**Files.** `You/CredentialCard.swift` (292 — **replaced**) · `You/CredentialFace.swift` (192 — **folded
into `CSCredential.plate`**; the `riding` behaviour at accessibility sizes survives verbatim; the
1:1-vs-16:10 `aspect` parameter is deleted) · `You/YouHero.swift` (195 — **replaced**) ·
`You/TourCardSheet.swift` (207 — **becomes `TourCardPage`, pushed**; its loading / failed / private
branches survive as copy) · `Golfers/PersonPage.swift` (393 — **merges into the same object**;
`PersonModel.load`'s card → bag → head-to-head cascade survives unchanged) ·
`You/FoundingTag.swift` (32 — **deleted**, `CSSlot` replaces it) · `Golfers/FriendsBoard.swift` (290 —
`:70`'s bare `CSMarkerView(key:size:22)` is **deleted, not patched**) ·
`Golfers/HeadToHeadPage.swift` (272 — gains the clash as its head) · `You/CredentialDev.swift`
(retargeted; it is the harness that renders all seven states) ·
`CSDesign/Marker.swift`, `CSDesign/PhotoScrim.swift` · `index.html` (`.cred`, `refreshWhoChip()`,
`openTourCard()`).

**Implements.** `surfaces/player-card.md`; `UI_SYSTEM` §6.5 (**the object's single anatomy of record —
neither `player-card.md` nor `profile.md` restates it, and neither may**), §6.2a, §15.2.

**Acceptance test.** `-cs_dev_open tourcard`, `-cs_dev_cred`, `-cs_dev_open person`,
`-cs_dev_open person me`, `-cs_dev_open golfers`, `-cs_dev_open h2h`. Compare to
`mockups/renders/player-card/{player-card-photo,player-card-marker,player-card-light,player-card-in-list,player-card-record}.png`.
**Must be visible:** the photograph owning the plate edge to edge with the name riding
`CSPhotoScrim.title`; the medallion **clear of every seam**; **the crest OR the corner medallion,
never both**; three figures on **one shared `ceremonyInk` rule** (never `ink`, which is 1.11:1 on
`ceremony` in light); the folio in `folioRule`; the gold slot present when something is earned and
**absent — with no gold anywhere on the card — when nothing is**; the same marker glyph and pigment for
the same golfer across **every** artboard and **both** themes; **no initials on a golfer who has a
marker**; the record on a **leaf** on the card's reverse.

**Closes audit problems** 1, 3, 5, 7.

**Gates.** preflight · `xcodebuild test` · `PhotoScrimTests` (extended) · the frozen-marker test.

**Files touched: ≈16.**

---

## WAVE 3 · THE PROFILE — *identity* (Phase 3.3, §10)

**Scope.** The tab root becomes credential → season → rivals → form → courses → record. **No segmented
control** — a golfer's record is not a fantasy player page. The record prints on a leaf. The
head-to-head becomes a graphic.

**Files.** `You/YouScreen.swift` (328 — rebuilt; the `.sheet` / link plumbing survives) ·
`You/YouSections.swift` (274 — **deleted wholesale**: `LifetimeTiles`, `SeasonStatsStrip`,
`LeagueRecordView`, `RecentRoundsList` **with its per-row delete ×** — an identity page is not an admin
tool, and deletion moves to the round's own receipt) · `You/YouRows.swift` (94 — **deleted**;
`YouStatRow` and `YouDoorRow` are the settings-list grammar the audit names) · `You/RecordPage.swift`
(271 — rebuilt as the almanac) · `You/TrophyCaseView.swift` (132 — replaced by trophy slats; **the
engraver ceremony is kept**) · `You/RivalriesSection.swift` (199) · `Golfers/PersonPage.swift` ·
`Golfers/HeadToHeadPage.swift` · `You/BagSheet.swift` (the profile's bag block becomes a leaf grid of
`slot · club`; the sheet itself is Wave 8) · `index.html`.

**Implements.** `surfaces/profile.md`; `UI_SYSTEM` §9.6, §9.7, §9.8, §15.2, §15.6.

**Acceptance test.** `-cs_dev_open you`, `-cs_dev_open record`, `-cs_dev_open person`,
`-cs_dev_open h2h`, `-cs_dev_open settings`. Compare to
`mockups/renders/profile/{profile-top,profile-scrolled,profile-history,profile-h2h,profile-light}.png`.
**Must be visible:** the credential as the **only thing on the screen with depth**; the form row as
five grosses with dates on one rule with the best in gold; the record as a **printed table on a leaf**
(`year · competition · finish · money`) with a **2pt gold rule beneath a won finish** (gold ink on bone
is 1.68:1 and is forbidden); the money column under a `MONEY` head with the sign as a word; **no ember
at all** on the Record page; the meeting tape with its one key line (`One square is one win.`) and
**no legend**.

**Closes audit problems** 1, 2, 3, 7, 9.

**Files touched: ≈14.**

---

## WAVE 4 · THE COURSE — *editorial* (Phase 3.4, §11, §12)

**Scope.** The course card sheet becomes a **pushed screen**. The plate owns the top third edge to
edge. The facts are **one line of type**. The rating becomes content. The front nine prints on a leaf.
The courses list stops being a settings pane.

**Files.** `Courses/CourseCardSheet.swift` (207 → **`CourseScreen.swift`**; its `ratings(_:)`
`LazyVGrid` of four `CSStat` tiles is deleted — that is 4 of the 12 remaining `CSStat` sites; its
`card(_:)` stacked-nines block **survives in substance** as the leaf) · `Courses/KeptCoursesList.swift`
(84 → **`CoursesScreen.swift` + `CourseRow.swift`**; the ember `SEE` label on a row that is already the
door is deleted) · `Main/MainTabView.swift:484,548` (the sheet presentation becomes a push; the
`CourseSheetRef(id: "never-kept", …)` sentinel keeps working) · `Main/Presenter.swift:22` ·
`Schedule/ScheduledRoundSheet.swift:42` · `RootView.swift:226` (**the boot-failed path — it must keep
working with no session**) · `Settings/CardAndSettingsScreen.swift:536` ·
`index.html` `renderCourseBooks()` (12275–12313) · new `CSCoursePlate`, `CSFactsLine`, `CSRating`,
`CSStarRail`, `CSQuote`, `CourseCardLeaf`, `RateCourseSheet`.

**Implements.** `surfaces/course.md`; `UI_SYSTEM` §9.11, §10, §15.3.

**Acceptance test.** `-cs_dev_open coursecard` (the first kept book, and the never-kept state).
Compare to
`mockups/renders/course/{course-page,course-page-noimage,course-card,course-rating,course-light}.png`.
**Must be visible:** a **photograph** on the flagship state — the top rung of the ladder, credited in
agate (`GALEN'S ROUND · AUG 24`) — with the drawn card and the contour proved only on
`course-page-noimage`; the facts as **one line**, never a 2×2 grid of bordered KPI tiles (the shipped
answer, and the lowest brand/emotion cells in the whole scorecard); the rating in **`ink`, not gold**;
the drawn card carrying **real** par, yardage and hole numbers 1–18 with gold on the #1 stroke hole
(*fake data as ornament is less premium than a plain colour* — all three blind reviewers, in three
different sentences); the overlapping disc row followed by a sentence that **names the friends**; the
front nine on a leaf.

> **This is the surface the blind reviewers failed.** Nobody would post it, nobody thought it belonged
> in the category, nobody called it premium — and all three gave the same reason: *there is no
> photograph of a golf course anywhere in five course renders.* Rung 1 on the front door is the fix.

**Closes audit problems** 1, 2, 3, 5.

**New data this surface needs and does not have** (`course.md` §7): **course ratings do not exist in
the product at all** — new tables, a write RPC and a read. **Degrade, and ship the degrade in this
wave:** a full-size **unfilled** star rail plus `NOT RATED · THE FIRST RATING SETS THE NUMBER`, never a
hidden or shrunken control. The server work is **not in this overhaul's scope** (§7).

**Files touched: ≈18.**

---

## WAVE 5 · THE SEASON — *the board* (Phase 3.5, §13)

**Scope.** An ember eyebrow, the season's name in `display`, **the chapter line in the serif**, the
week ticks, the clash, the squad table above the individual table in a squads season, both as slats,
then the pot as a rule-and-figure in gold with the ledger line beneath. **No card appears anywhere on
it.** Gold appears exactly twice — the leader's rail field and the pot — and that pair is the budget's
one sanctioned exception, whitelisted by name in `LINT-17`.

**Files.** `Season/SeasonPage.swift` (rebuilt; `SeasonPane` routing, `RoomRouter`, `.task` loads and
`navigationDestination`s survive verbatim; the `.padding(.horizontal, 20)` on the whole `VStack` is
**removed** — slats and bands are full-bleed) · `Season/SeasonPhases.swift` (**`PressMeter` deleted**;
`ClashCard` → `CSClash`; `NextCard` → a sentence and a link) · `League/StandingsTableView.swift` (284 —
rebuilt as `CSSlat` + `CSRankRail` + `CSMovement`; `header(solo:)` **deleted**, its swallowed
`.frame(maxWidth:.infinity, alignment:.leading)` at `:63` collapses the column heads ~150px left of the
columns they name; **`RankFlipText` and the rank-up haptic at `:224-284` survive verbatim**) ·
`League/ClimbView.swift` (144 — **merged**: the climb becomes the table's *window*) ·
`League/IndividualRaceView.swift` (132 — conditioned to squads seasons; its signed red/green float
column at `:89-90` is deleted) · `League/CupFinalRaceView.swift` (125 — re-clothed; its 21pt finalist
total becomes `figure` 40) · `League/PotPane.swift` (rebuilt; `PotMath`, `SeasonFacts.owe`,
`PotPassCard` and `PricingPotFinePrint` consumed unchanged) · `Season/SeasonStoryPane.swift` ·
`Season/ProVerbRow.swift` (**deleted**) · `League/RoomBits.swift` · `Season/SeasonPreviews.swift`
(extended to loading, empty, error-cached, complete, free-league, AX3 and light) ·
new `CSSeasonCalendar`, `CSClash`, `CSStakeLine` · `index.html`.

**Implements.** `surfaces/season.md`; `UI_SYSTEM` §9.1, §9.5, §15.4.

**Acceptance test.** `-cs_dev_open season`, `-cs_dev_open story`, `-cs_dev_open rules`,
`-cs_dev_open pot`, `-cs_dev_scroll`. Compare to
`mockups/renders/season/{season-top,season-table,season-squads,season-money,season-story,season-light}.png`.
**Must be visible:** the rank rail in **all three field states**; a **face in every table row** with
six pigments; the **header row** `POS · GOLFER · GAP · PTS` at every field size; the merged 58pt
gap+movement cell with movement on **the page's own ground** (no tinted field, no pill); the leader's
gap cell **empty**, never `0` and never an em dash; the week ticks with played `ink` / now `brand` /
ahead `mut`; the **cut rule** (`CUT · TOP TWO PLAY THE CUP FINAL`) — a reviewer named it and the month
band "the two devices that make this surface FPL-grade"; correct **tie handling** (`04 / 04 / 06`);
the same table reading correctly at **2, 6 and 12 golfers**; in a squads season, a **swatch plus the
squad's name** in every sub-line and never colour alone; the ledger line **once**, at the foot; and
**no card**.

**Closes audit problems** 1, 2, 3, 5, 7, 10.

**Out of this wave's scope, and say so in the commit**: `Season/SeasonRulesPage.swift` (already 6.3,
"polish") and `League/SeasonCeremonyView.swift` (a P0 at 4.9 — Wave 8).

**Files touched: ≈17.**

---

## WAVE 6 · THE EVENT — *the title card* (Phase 3.6, §14)

**Scope.** A full-bleed ceremony plate with the title at `display` 34, three agate metadata blocks, the
score and the clock as figures on one rule, the field as a **rail of faces with names**, the board
carrying `THRU` in place of `GAP`. **Think tournament graphic, not database record.**

**Files.** `Events/EventRoomScreen.swift` (rewritten; `navigationTitle("")`; routes on `kind` **and on
`CalloutShape.isCallout`**) · `Events/RyderRoomView.swift` (rewritten) · `Events/MajorRoomView.swift` ·
`Events/MajorJugCard.swift` · `Events/EventBits.swift` (`EventHeaderRow`, `EventFineCard`, `EventSeg`
**deleted**; `EventTeamSwatch` survives as the 3pt squad rule) · `Events/EventChips.swift` ·
`Events/EventStagePicker.swift` · `Events/RyderSetupSheet.swift` · `Events/MajorSetupSheet.swift` ·
`Events/EventPickerSheet.swift` · `Compete/IntentSheet.swift` + `WhenForkSheet` (**re-clothed, not
re-argued** — the five sentences, their glosses, their order and the ember on the first are
`StartIntent`'s and are untouched) · `Schedule/ScheduledRoundSheet.swift` (its **gold-tinted weather
chip** and its **gold middle RSVP button** both violate "gold may never touch a control") ·
`Events/EventRoomModel.swift` (**untouched — no data path changes**) · **new**
`Events/CalloutRoomView.swift` (a callout currently lands in `RyderRoomView` and is told it is in
"WEEK 1 OF 1" of a series it is not in; `CalloutShape.isCallout(sessionCount:leagueId:field:)` already
exists in the Kit and is called nowhere on the phone — the branch is one line) · `index.html`.

**Implements.** `surfaces/event.md`; `UI_SYSTEM` §15.5, **§15.5a** (sides).

**Acceptance test.** `-cs_dev_open ryder`, `-cs_dev_open ryder <uuid>` (a COMPLETE room — `native_home`
carries only `setup` and `live`, so half of D237's gate is unreachable without the id),
`-cs_dev_open callout`, `-cs_dev_open events`, `-cs_dev_open intent`, `-cs_dev_open declare`,
`-cs_dev_open whenfork`, `-cs_dev_open lengths`, `-cs_dev_open forfeit`,
`-cs_dev_open forfeit league`. Compare to
`mockups/renders/event/{event-ryder-live,event-callout,event-plan,event-setup,event-light}.png`.
**Must be visible:** **who is on which team, instantly** — two named groups, each under a full-width
3pt rule in its squad colour with the squad's name in `agateS` beneath, every disc carrying a 2.5pt
outer ring in its side's colour **while keeping its own pigment and glyph**. That was the one thing two
of three blind reviewers could not read on this surface, and it was a failure at the surface's one job.
Also: the countdown **out of the score rail** and into the live eyebrow (a countdown is not a score);
an un-chosen option **never pre-tinted** (`event-setup` drew its first option in `brand` while nothing
was selected and two reviewers read it as already selected); **one** ember rule per sheet, not three.

**Closes audit problems** 1, 2, 3, 4, 5, 9.

**Files touched: ≈17.**

---

## WAVE 7 · LEADERBOARDS AND SCORE DISPLAYS (Phase 3.7, §15, §16)

**Scope.** One standings object, not three. The live sheet from the status band down. The receipt on a
leaf. The gross as the canonical rule-and-figure. **The user should be able to scan a leaderboard
instantly, and `▲3` should communicate more than a paragraph.**

**Files.** `League/StandingsTableView.swift` (final form) · `League/ClimbView.swift` (merged;
`ClimbMath.items`' proportional ellipsis rung becomes the window's rule) ·
`League/IndividualRaceView.swift` · `League/CupFinalRaceView.swift` · `Season/SeasonPage.swift:231-248`
(stops rendering three standings unconditionally; `:236` and `:241` become one `CSStandingsBoard`) ·
`Golfers/FriendsBoard.swift` (290 — replaced) · `Golfers/GolfersScreen.swift` (150 — reordered: the
board leads, the search field folds under the header, three agate blocks in the first viewport become
one) · `Live/LivePlayView.swift` (506 — replaced from the status band down: the two capsule chips, the
18 ember dots, the four 4×40 colour bars, the stacked `55 / THRU / 14 / -1` column, the `− – +` tray
and the bordered side-game card; **the 44pt circular hole arrows and the stepper-opens-on-par behaviour
survive**; `:260`'s clip long-name policy becomes the product's tail ellipsis) ·
`Live/LiveCardView.swift` (232 — **kept. This is the product's ceiling at 6.8 and it is not being
redesigned.** Three fixes only: its 11 `cs.dim` text sites move to `mut`, its single
`accessibilityLabel` becomes per-column labels, and **its birdie stops being gold** — the ink law
applies) · `Rounds/RoundReceiptSheet.swift` and `League/ReceiptSheets.swift` (re-clothed onto a leaf;
`ReceiptRows` untouched) · `League/RoomBits.swift` (`RoomMathRow` at `:147-163` is the receipt shape
the audit calls right — it **survives as the leaf's row**) · `Post/PostRoundScreen.swift:530,536`
(`CSFont.figure`'s 64pt gross — the best-typeset object in the product — becomes the canonical
`CSFigure` the rest is derived from) · `Events/RyderRoomView.swift`, `Events/EventRoomScreen.swift`
(the event board becomes the same slat with `THRU`) · `index.html` `renderStandings()` at `:6011`.

**Implements.** `surfaces/leaderboard.md`; `UI_SYSTEM` §9.1–§9.10.

**Acceptance test.** `-cs_dev_open season` (2-, 6- and 12-golfer boards), `-cs_dev_open golfers`,
`-cs_dev_open live`, `-cs_dev_landscape`, `-cs_dev_open postround`, `-cs_dev_hole`. Compare to
`mockups/renders/leaderboard/*.png` (7 artboards). **Must be visible:** the header row at **every**
field size; `P. Raghunathan` rather than `Priya Raghu…` at a field of ten or more, **per board, not per
row**; **no truncated surname anywhere** — all three blind reviewers filed the same four as the single
most damaging defect in the set; the hole strip with a legend; the receipt on a leaf with a 2pt
`leafInk` rule above the total; the last visible row of every list **either fully clear of the chrome
or at least half visible under a 28pt fade** — never sheared (§13.2a).

**Closes audit problems** 1, 2, 3, 5, 10.

**Files touched: ≈18.**

---

## WAVE 8 · PROPAGATE (`BRIEF` §30 Phase 4)

**Scope.** Every surface Phase 3 did not name, brought onto the same system. Nothing here is a redesign
argument; it is the same components applied.

**The list, in descending audit priority:** the **season ceremony** (`League/SeasonCeremonyView.swift`
— 150 lines, **zero animation calls and zero haptics**, a P0 at 4.9, and `UI_SYSTEM` §11.3's takeover
band is its answer) · the **live finish / recap** (`Live/LiveFinishViews.swift` — 323 lines, also zero;
**the settlement card is rendered in-app at the geometry it exports at**, because the golfer who won
should see the most beautiful object in the product) · the **live setup** (a P0 at 4.3) · the
**composer** (`Post/PostRoundScreen.swift` — its 64pt gross is already right; the golfer chips at ~36pt
and "Start over" at ~20pt are the two known 44pt misses) · the **wizard** · **onboarding** (the card
gate, the crew step, the push prompt) · the **door** and the **Forge** (keep the bones; fix the timing
— the mark's arrival is the shortest beat; **ship the app icon**, done in Wave 0) · **Card &
settings** · the **bag** (`You/BagSheet.swift`) · the **Board** · the **schedule** · the **pot** ·
the **Play cover** · the **trophy case** · the **widgets** · every remaining **sheet** (84 `.sheet(`
sites and 11 covers, onto one grammar) · every remaining **toast** (134 sites, onto one shape).

**Implements.** `UI_SYSTEM` §7.3, §11.3, §13, §15.6; `COMPONENT_SYSTEM.md`'s remaining patterns.

**Acceptance test.** Every hatch in the list at §4's head, shot dark / light / AX3, and every screen in
`UI_SCORECARD.md`'s 25 rows re-shot. **`-cs_dev_forge`, `-cs_dev_door`, `-cs_dev_bag`,
`-cs_dev_open wizard`, `-cs_dev_open card`, `-cs_dev_open crew`, `-cs_dev_push_prompt`,
`-cs_dev_open settings`, `-cs_dev_settings_pane`, `-cs_dev_open board`, `-cs_dev_open schedule`,
`-cs_dev_open_play`, `-cs_dev_open post`, `-cs_dev_open live`, `-cs_dev_dress`, `-cs_dev_look`.**
**Must be visible:** zero `CSCard`, zero `Capsule()`, zero `RoundedRectangle(` outside `CSDesign`; one
dismiss verb everywhere; a disabled state that exists.

**The ceremony's data blocker, stated here so nobody signs off around it:** no season on any device is
`complete`, so the takeover, the trophy engraving and the settlement card **cannot be photographed**.
Build them, ship them, and record in the wave's commit that they are **unjudged**. §7 and §8.

**Files touched: ≈120.**

---

## WAVE 9 · THE CONSISTENCY SWEEP (Phase 5, `BRIEF` §26, §27)

**Scope.** Harden every `LINT-nn` baseline to zero, in the order §2.7 gives. Delete the last call
sites of every retired name and every retired *word*. Then run the sweep `BRIEF` §26 asks for:
duplicate button styles, duplicate card styles, inconsistent spacing, typography, radii, colours, icon
sizes, modal behaviour, navigation — and consolidate each into the component that already exists.

**The targets, with today's counts** (each must reach 0): `RoundedRectangle(` **264** ·
`Capsule(` **74** · `cornerRadius:` **264** · `.tracking(` **177** (→ 1) · `.uppercased()` **194** →
0 · `.stroke(` **151** → 4 whitelisted · `ProgressView(` **9** → inside a `ButtonStyle` only ·
`navigationTitle(` **29** → `""` on every pushed screen · `cs.dim` **226** → non-text only ·
`cs.line2` **86** → 0 · `cs.dawn` **27** → 0 · `cs.warm|hot|fire` **40** → 0 · ~35 UI emoji → 0 ·
9 flags → 1 · 22 chip types → 1 · 5 segmented controls → 1.

**Also:** `LINT-27` runs `TERMINOLOGY.md` §4's **34 patterns** over `UI_SYSTEM.md`, the seven surface
specs and the seven mockups as well as the code — five of the six hits found in this design's own copy
were written into specs the build was going to build from without asking.

**Acceptance test.** `node tests/preflight.mjs` with **every baseline at 0** and the checks hardened to
zero-tolerance. No screenshot; the gate is the gate.

**Files touched: ≈40.**

---

## WAVE 10 · RESPONSIVE AND ACCESSIBILITY (Phase 6, `BRIEF` §24, §25)

**Scope.** Every layout gets its stated AX3 form. Every one of the five iOS switches gets an answer.
Every drawn indicator gets a label.

**The nine layouts, from `UI_SYSTEM` §16.3, each with a stated default / AX1 / AX3 form:** the masthead
· any `agate` line · the lead block · the ME strip and any figures-on-a-rule · the slat · the
credential · the tab bar · a section head · any table. **Generalise `MeStripLayout`'s model** — reflow
on the measured advance of the actual characters at the size being read — not a breakpoint table.
`ViewThatFits` is 0 and `horizontalSizeClass` appears twice, both meaning "is the phone sideways".

**The other four switches** (`UI_SYSTEM` §16.5): **Bold Text** — a `.custom()`-registered face does not
respond to `legibilityWeight` at all, so `agate`, `name` and `social` move 600 → 700 (both cuts
bundled, costs nothing); **Increase Contrast** — four substitutions resolved in `Theme.swift`;
**Reduce Transparency** — the folio, the crest, the contour and the scrim each resolve to their
composited opaque value; **Reduce Motion** — already right, both curves to `nil`, never "faster".

**Targets.** 44pt minimum, and the three known misses are named: the composer's "Start over"
(~20pt — its frame modifier is inside a comment), the live round's CARD/HOLE strip (~22pt), the
composer's golfer chips (~36pt where the sibling sheet's are 44). The star rail is the one carve-out
and it is stated, not asserted: a continuous 362 × 56 drag target plus a **44pt −½/+½ stepper pair**,
`.accessibilityAdjustable` with 0.5 increments.

**Acceptance test.** Every surface at **SE (375pt) · 17 Pro (402) · Max**, in **both themes**, at
**default and AX3** — using Wave 0's two hatches, which is the first time any of it has been *seen*
rather than computed. The landscape scorecard's single label for 18 columns becomes per-column labels.

**Files touched: ≈30.**

---

## WAVE 11 · THE BLIND VISUAL REVIEW (Phase 7, `BRIEF` §28, §34)

**Scope.** No code. Re-shoot the whole product, re-score it (§8), and run `BRIEF` §28's ten questions
and §34's side-by-side test against the leading consumer sports apps.

**The ten questions, asked of every screen:** what is the most important thing here · can I identify it
instantly · does the hierarchy support the UX · does this look like Cup Season · does it look premium ·
does anything feel like a generic template · is there unnecessary UI · could it be 20% simpler · is
there an opportunity for personality · **would I be proud to screenshot this and post it.**

**Use readers who have not read `UI_SYSTEM.md`.** The Phase-2 target column was produced by three
blind reviewers and it caught eight defects the designers could not see, including the one that failed
the course page outright. Do the same, or the review is a self-assessment.

**Files touched: 0 code, 2 docs** (`UI_SCORECARD.md` gains a Phase-3 column; this file gains a closing
section).

---

# 5 · THE WEB HALF OF EVERY WAVE

**R-C / D234: two clients, one product, one set of producers, two shapes — the phone at the turn, the
web at the desk. A wave is not done until both ship.** The desk is **built into `index.html`**, in its
own desktop-first shape: a **236pt sidebar** and a **`1fr + 340pt` body at `gutterDesk` 40**. Never the
phone's tabs reflowed. The rendered proof is `mockups/web-desk.html` →
`mockups/renders/desk/desk-season.png`, 1440 × 900.

**The desk's own numbers to retire** (audit §2.25): **492 `font-size` declarations across 36 values
with zero type tokens · 114 boxed surfaces · 25 radii · zero spacing tokens · 90 hex and 84 rgba
literals against 24 colour tokens · 20 chip families · four icon systems · two `:root` blocks 2,287
lines apart.**

**The migration order, from `UI_SYSTEM` §14.5** — each step is one commit and each is greppable, so the
lint can be turned on for `index.html` one check at a time:

1. the two `:root` blocks **merge into one** and take `space`, `alpha`, `track`, `radius`, `type` from
   `tokens.json` — **Wave 0**;
2. the **nine roles as CSS classes** (`.cs-fig-xl/l/m/s`, `.cs-display`, `.cs-display-s`, `.cs-name`,
   `.cs-name-s`, `.cs-social`, `.cs-lead`, `.cs-story`, `.cs-body`, `.cs-body-s`, `.cs-agate`,
   `.cs-agate-s`, `.cs-col`, `.cs-col-m`, `.cs-col-s`) replace the 492 `font-size` declarations,
   **largest first** — Waves 0–1;
3. the **114 boxed surfaces** resolve to band / rule / rail / panel / leaf, which is where the 25 radii
   collapse to five — Waves 1–7, per surface;
4. the **20 chip families** become one shape — Wave 8;
5. the **four icon systems** become the drawn family — Wave 8;
6. **hover and focus twins** — Wave 10.

**Desk density** (`UI_SYSTEM` §14.2): gutter **40** · slat **56** · `display` **42** · `story` **21** ·
everything else unchanged.

| Wave | The web half |
|---|---|
| **0** | the merged `:root`; the nine CSS classes; the Google Fonts href at `:36` (**a stack is not a loader** — without it 46% of the desk renders in `system-ui`); the sidebar frame with the mark, the wordmark, `agate` nav items, a **3px `brand` tick on the selected item's left edge**, `THE DESK ▸` under a rule, and the viewer's face, index and `v23 · <sha>` at the foot |
| **1 · Home** | the edition in two columns. **Left (1fr)**: the lead block, then the wire at its five weights, weight 2's photograph running the column's full width at 2.1:1, weight 3 gaining a second line of course facts. **Right (340)**: the ME strip **turned vertical** (four rule-and-figures stacked, the standing line, the ledger line), the clash, and the four doors as a block that **never scrolls out of reach** — the desk's answer to the floor. The masthead becomes the body's dateline row; the wordmark already lives in the sidebar and is not printed twice |
| **2 · The card** | the credential at its **native 362 × 312 in the right column — it does not stretch**, because a stretched credential is a banner. Left column: the record at length. The card takes the focus outline when it is the keyboard's target, because the card is a door (Enter opens Share). **Print stylesheet** = the share PNG's 3:4 geometry, front and leaf back, on one page |
| **3 · The profile** | credential top-right at natural width; under it the season slat and the rivals. Left: the record leaf at **full** season width with `RDS · BEST · GAP · PTS · MONEY` and the five-dot form column, the courses-kept table, the trophies as a printed list. Print stylesheets on the leaf and the credential |
| **4 · The course** | **the plate at the full width of the left column at 2.6:1** with the name reversed out and the credit flush right — the desk is where the photograph finally has room to be a photograph. Facts line stays **one line** even at desk width; the pull quote at `story` 21. Right 340: the rating block, the friends as a **spaced** roster row with names, and the leaf carrying **all eighteen** holes. "Rounds here" becomes a real table (`TEE · DATE · GROSS · VS YOUR BEST`). `1`–`5` with `Shift` for halves sets a rating from the keyboard |
| **5 · The season** | **the desk's best surface.** Left: the chapter line at `lead`, the month clock across the full column (thirteen ticks, no wrapping), the board at slat 56 with **`RDS` and `MONEY`** — money in ink with the sign in the header, never red and green — plus the five-dot form column. Right: the clash as a fixed panel, the season's story as a scrolling list of week chapters (the arc at length, the desk's real advantage), the pot with its split, its leaf ledger and the ledger line. **Print stylesheets on the board and the pot ledger**, because those are the two things a Pro actually prints |
| **6 · The event** | the title card at the full body width at 300pt, the field rail spaced across it at 44pt discs with full first names, `display` 42, the score's figures 56. Left: the week's clashes at 64pt with a `THRU` column. Right: the two rosters with `W-L-H` as a printed table, the series line, the pot with its ledger line, the board's engine posts as a dated column. **The plan sheet becomes a right-hand panel rather than a modal; the intent sheet becomes a five-row list in the sidebar's `New` popover.** Neither is redesigned, only re-columned |
| **7 · Leaderboards** | `renderStandings()` at `index.html:6011` becomes **the same slat at 56pt with the same 44pt rail**. It gains the two columns the phone cannot afford, plus the five-dot form column inside the row. Money in ink with the word in the head. **Faces above the table as well as in it.** Print stylesheets on the board and the settlement card |
| **8 · Propagate** | the 20 chip families → one; the four icon systems → the drawn family; the remaining boxed surfaces; the web's own composer, wizard, onboarding, door |
| **9 · The sweep** | `LINT-05`, `-06`, `-07`, `-10` turned on for `index.html`; the web string extractor for `LINT-27` |
| **10 · Hover, focus, keyboard** | **every hover state gets a focus twin** — the shipped web has **40 hover rules and one `[disabled]` rule**. Hover (guarded `@media (hover: hover)`): a slat's ground steps to `bg1`, its rail slot paints `bg2`, a link's 2px `brand` rule thickens to 3px. Focus: a **2px `brand` outline on the whole slat, always visible, never suppressed**. Keyboard: `↑`/`↓` between slats · `→` opens the receipt · `/` focuses search · `g` then `t` jumps to the table · `Esc` closes |
| **11 · Review** | the desk re-shot at 1440 × 900 and at 390 × 844, and its scorecard row (`web`, baseline **4.5**) re-scored |

---

# 6 · DECISION-LOG ENTRIES — WRITE THESE BEFORE YOU BUILD

`CLAUDE.md` rule 5: **any change to a mechanic gets an entry BEFORE it is built**, in the
hierarchy-of-truth format, and lower levels never silently contradict higher ones. The hierarchy is
vision → principles → IA → mechanics → **UI (level 5)** → implementation (level 6). This overhaul is
entirely level 5 and 6: **nothing here changes a competition mechanic**, and if an entry you are about
to write would, stop.

**The tails, verified at HEAD `57b993f`:** `spec/decision-log.md` ends at **D264** ("The phone is not
dead without a signal", 2026-09-06). `docs/ios/DECISIONS.md` ends at **IOS-043** ("The morning
repair"). So this overhaul opens at **D265** and **IOS-044**. Verify both again before writing — a
parallel session may have moved them:

```bash
grep -oE '^#+ *D[0-9]+' spec/decision-log.md | tail -3
grep -oE '^#+ *IOS-[0-9]+' docs/ios/DECISIONS.md | tail -3
```

**Each entry is appended in the same commit as the code it governs**, with `PROPOSED` replaced by a
dated authorisation line. The wave column says which.

## Product entries — `spec/decision-log.md`, level 5

| # | Title | Wave |
|---|---|---|
| **D265** | The visual system replaces the identity contract | 0 |
| **D266** | The card is deleted — three containers, three jobs, and no border token | 0 |
| **D267** | A golf number is a visual object — the rank rail and the rule-and-figure | 0 |
| **D268** | Typography carries the brand — nine roles, a bundled condensed cut, Charter retired | 0 |
| **D269** | The two metals, made enforceable — budgets counted by hue, and no gold on a control | 0 |
| **D270** | The palette is re-printed — a nameable ground, a paper light theme, eight tokens deleted | 0 |
| **D271** | A person is drawn one way — `CSFace`, six pigments, and a frozen marker pair | 0 |
| **D272** | The imagery ladder — a golfer's photo, the drawn card, the contour, and nothing else | 4 |
| **D273** | Money is ink and the ledger line is printed once per client | 5 |
| **D274** | The lint — twenty-nine checks, five of them render-time probes, all of them with baselines | 0 / 9 |

**D265 · The visual system replaces the identity contract.** *Current:* `IOS-003` §1 is the identity
contract — the 3.5pt spine as the card grammar, Charter as the serif, mono as the metadata voice, a
four-tone heat axis, `dawn` as a third metal. *Problem:* `UI_AUDIT.md` measures every one of those as a
defect at the surface: the spine rides paragraphs and menus, so it means "a box"; the card fill sits
1.084:1 above the page and its border 1.443:1; 310 sites of 11–12pt tracked mono caps are the product's
*default* voice; the heat axis renders as a legend at 11pt; `dawn` splits evenly between links and
statuses so neither reading wins. Product mean **5.10 across 25 surfaces, twenty-three verdicts of
"redesign"**. *Recommendation:* `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md` **supersedes `IOS-003` §1**
as the identity contract; §0.3 of that file lists every kept and every changed row with the reason it
survived or fell, and nothing was inherited silently. *Principle served:* `BRIEF` §4 — *do not default
to whatever styling already exists*. *Benefit:* one contract, re-decided element by element, with a
preflight behind the parts that can be checked. *Tradeoffs:* every surface in the product changes, and
`IOS-003` §1 becomes a historical document rather than a live one. **CONFLICT (level 5 over level 5):
this supersedes `IOS-003` §1 in whole.** It does not touch `IOS-003` §2 (motion, haptics, push
semantics), which survives verbatim.

**D266 · The card is deleted — three containers, three jobs, and no border token.** *Current:* the card
is the only container the product owns; 13 of 20 `CSCard` sites draw a border and a spine 2px apart,
and the codebase carries **338 hand-rolled containers against 34 component uses** across **91
off-token radii in 11 values**. *Problem:* on eight of fifteen screens in the audit's card census,
deleting every border costs **zero information** — the product pays the full visual cost of
over-carding and gets almost no depth back, and `BRIEF` §6 and §32 forbid it in as many words.
*Recommendation:* a container is legal only when it holds a single figure (**the panel**, ≤96 × 96,
never a sentence), holds a printed grid (**the leaf**), or is a physical artefact a golfer would keep
(**the object**). Everything else is band, rule, rail and whitespace. **No container may contain
another container.** The system has **no border token**. *Principle served:* `BRIEF` §6, §27, §32.
*Benefit:* the rule goes from 1.443:1 to **2.66:1** and the panel to **14.91:1** — real depth, spent on
the two objects a screen is about instead of on every paragraph. *Tradeoffs:* 338 sites migrate, and
`LINT-08/10/19/20` need a render-time probe rather than a grep.

**D267 · A golf number is a visual object — the rank rail and the rule-and-figure.** *Current:* 38
sites type a score into a sentence in the sentence's own face; the board's gross is 13pt grey mono
while its points figure gets 21pt and a red pill outranks both; a golfer's finishing position for a
whole season is 11pt tracked caps under a generic flag. *Problem:* `BRIEF` §16 — *a score of 74 should
look like a meaningful piece of information* — and it does so on exactly two screens in the product.
*Recommendation:* **one `figure` role at 56 / 40 / 27 / 20**, tabular, in the board face; any figure at
27 or above carries a **2pt rule the width of its column with an agate label beneath**; every ranked
list in the product opens with the **44pt rank rail**, painted gold when earned and bone when it is
yours; a number inside a sentence is a **figure run** produced from a marked string, never found by a
regex. *Principle served:* `BRIEF` §5, §15, §16. *Benefit:* the two devices are the product's
signature — remove the logo and they still say Cup Season — and the rail is also the origin of every
arrival in motion, so layout and motion become one idea. *Tradeoffs:* the rail costs 44pt of a 375pt
measure, which is why the name column is the only flexible one and why a field of ten or more
abbreviates given names.

**D268 · Typography carries the brand — nine roles, a bundled condensed cut, Charter retired.**
*Current:* eighteen type roles, none declaring a line height; "display" exists for exactly one thing (a
number, 21 of ~1,000 type sites ≈ 2%); a golfer's name is a 20pt SF heading; season and event titles
are Apple's nav bar at 29 sites; against that, **310 sites of 11–12pt tracked mono caps** doing six
jobs in nine colours. *Problem:* `BRIEF` §5 asks typography to carry a significant portion of the
brand, and one tap below a tab root the product is typographically a stock iOS app on a green ground.
Two system faces cannot fix that. *Recommendation:* nine roles / fourteen symbols, each with a text
style, a leading and a case law; **IBM Plex Sans Condensed SemiBold + Bold bundled** (~248 KB, OFL 1.1,
a cut of the family already bundled, so the family count stays at three); **Charter retired** — it has
no display cut, no optical sizes, one weight step and must be addressed by PostScript string, which is
D258's exact defect class; **New York** becomes the serif; metadata moves from tracked mono to
**agate**, and mono falls from ≈55% of type sites to ≈12%, keeping what print gave it — columns of
figures, codes, handles and times. *Principle served:* `BRIEF` §5, §7. *Benefit:* target distribution
board ≈46% · sans ≈38% · mono ≈12% · serif ≈4%, and a voice that is not Apple's. *Tradeoffs:* two
bundled faces are a D258 risk, mitigated by one constant, a launch assertion and a tabular assertion
(`LINT-01`, `LINT-02`); the `track` group needs **nine** values, not the four `UI_SYSTEM` §1.2 names,
and this entry records the resolved set (§2.5 of `BUILD_BRIEF.md`). **If bundling is refused**, the
fallback is `Font.system(design:.default).width(.condensed)` at the same sizes: every layout holds and
only the voice weakens.

**D269 · The two metals, made enforceable.** *Current:* **141 ember sites doing nine jobs**; roughly 30
of 123 gold sites are chrome, state or taxonomy; one Home viewport carries five accent hues; and on
every signed-in screen the loudest object in the frame is the tab bar's ember ⊕. *Problem:* the
two-metal rule is the most ownable thing in the product and the only one that reads as *scarcity* —
which is what "premium" means here — and it is currently unenforced. *Recommendation:* ember has
exactly two jobs (**live**, and **the one primary action**); gold has exactly one (**earned**), with a
hard budget of **one gold object per viewport counted by hue, not by token name**, and **an average is
not earned** — a course's rating is `ink`. **Gold may never touch a control**, and
`CSButtonStyle.gold` is deleted. The ⊕ loses its fill and becomes a glyph. The tertiary link splits
into `.live` / `.content` / `.toolbar`, so a dismiss verb, a Settings link and a Share link cannot wear
the live metal. `LINT-18` counts **every** ember mark on a viewport, not fills alone. *Principle
served:* `spec/brand-canon.md`'s one rule — gold means earned, never chrome. *Benefit:* scarcity
restored, and it is now countable. *Tradeoffs:* emphasis has to come from somewhere else, which is what
the display tier and the 2pt rule are for.

**D270 · The palette is re-printed.** *Current:* `bg0` `#0B1410` is **ΔE 6.88 from pure black at chroma
4.14** — less separation from black than Home's lead card has from its deck card, so the fescue cast is
not nameable; the light theme puts `pos`, `neg`, `gold` and `brand` inside a **0.03** contrast spread,
at a ground chroma of 1.07. *Problem:* there is no dawn in the dawn palette and no green in the
green-black. *Recommendation:* `bg0` becomes `#0F1A15` (**ΔE 10.28 at chroma 6.35 — 49% more
separation**); the light theme is rebuilt as **warm almanac stock**, not a paler dark, with gold
re-hued to bronze and ember to a stamp red; `line2`, `dawn`, `pine`, `warm`, `hot`, `fire`, `focus`,
`glow`, `grad` and `shadow-rest` are **deleted**; `object`, `pigment`, `space`, `alpha` and `track`
are added; `CSLookSky`'s accent wash over the top 260pt is deleted so the band the system clock sits in
is no longer a different product colour from the screen under it. *Principle served:* `BRIEF` §4 — a
recognisable visual language — and §27, remove visual debt. *Benefit:* the ground is nameable, the two
printings are genuinely two printings, and every value is a token. *Tradeoffs:* ~180 Swift sites change
colour token; `tools/build-tokens.mjs` must change **in the same commit** or the emitter throws and
preflight 10 fails permanently.

**D271 · A person is drawn one way.** *Current:* `FriendsBoard.swift:70` uses a bare marker glyph and
never reaches `CSFace`, so **a golfer with a photograph structurally cannot show it on the people
tab**; there is no face and no photograph anywhere in the product except one credential; markers drift
between surfaces and themes. *Problem:* `BRIEF` §4, §7, §9, §11 and §20 all ask for faces, and a marker
that changes with the theme is decoration that happens to be circular, not an identity system.
*Recommendation:* **`CSFace` is the only legal way to draw a person**; the disc takes one of six
**pigments** chosen deterministically from the golfer's id; the marker is a **frozen pair
`(pigment, glyph)`** resolved once from the profile row and never re-derived per surface, theme, size
or component; **there is no initials rung below the marker**; on cream stock the glyph takes `ink`; a
face appears in every table row, every wire item with a person in it, the clash, the field and the
desk. **No silhouette and no fabricated face, ever, including in the demo diorama.** *Principle
served:* the markers-as-avatar-floor canon, kept and finally made a system. *Benefit:* two golfers with
the same marker become two different coins with no data required and no colour meaning implied.
*Tradeoffs:* the fourteen markers must be optically re-fitted to a common cap-height box, and any two
must differ in **outline** at 26pt, not only in detail.

**D272 · The imagery ladder.** *Current:* the product has no course imagery at all, and the course
sheet — the object `BRIEF` §20 calls one of the strongest visual elements available — is a 2×2 grid of
bordered KPI tiles under a cache disclaimer, scoring **brand 3 / emotion 2**, the lowest two cells in
the scorecard. *Problem:* `BRIEF` §20 asks for authentic, beautiful, editorial imagery and forbids
stock; the product cannot license photographs and must not fabricate them. *Recommendation:* three
legal states, in order — **(1)** a golfer's own round photo at that course (`rounds.photo_path` is
live, the bucket is private, the signed URLs are already cached), credited in agate; **(2)** the drawn
card, generated from `api_course_holes`' real par and stroke index and the cached tee yardages, gold on
the #1 stroke hole, numbered 1–18; **(3)** the contour plate, a seeded value-noise field. A course with
none of the three shows **no thumbnail at all**. **A gradient wash is not one of the three and may not
ship.** A surface's flagship state renders the **top** legal rung. *Principle served:* `BRIEF` §11,
§20; the brand's own line, "one great photo of Saturday morning". *Benefit:* it is true, it is free, it
makes the course page social without adding a feature, and it is unique per course by construction.
*Tradeoffs:* rung 1 depends on a golfer having posted a photo there; the degrade must be beautiful, and
**fake data as ornament is less premium than a plain colour** — the drawn card's bars must be real.

**D273 · Money is ink and the ledger line is printed once per client.** *Current:* money takes `pos`
green and `neg` red — a red/green P&L axis, which is the grammar of a brokerage and `BRIEF` §1's named
"overly minimalist fintech app"; and the ledger sentence appeared on **eight of thirty-four** design
renders, twice on one screen 250pt apart. *Problem:* a legal line used as a layout element makes a page
look auto-generated rather than composed, and a colour axis borrowed from finance is the opposite of
what this product is. *Recommendation:* **the figure is `ink`; the pot and anything won are `gold`;
`pos` and `neg` never touch money; the sign is a word in agate** (`YOU OWE` · `YOU'RE OWED` ·
`SETTLED` · `THE POT`); a negative figure takes a **minus sign in ink**, never a red fill. The ledger
line renders verbatim from **one constant**, **once per client**, in `agateS`, at the foot of the money
surface, under a hairline. If two lines is the cost, the constant is shortened **once, with the
owner** — never on an individual surface. *Principle served:* D39 and D201 (the ledger is a promise,
not a feature), and `BRIEF` §27. *Benefit:* the anti-"betting app" vaccine keeps working without
becoming wallpaper. *Tradeoffs:* `LINT-23` must fail any string containing "keeps the ledger" outside
`MoneyCopy.ledger` / `CS_LEDGER`.

**D274 · The lint — twenty-nine checks, five of them probes, all with baselines.** *Current:* the
components that exist are good and are ignored — **34 component uses against 338 hand-rolled shapes**,
**90 `CSButton` sites against 227 raw `Button` and 181 `.buttonStyle(.plain)`** (≈28% of tappables with
a shared definition). *Problem:* **a rule a preflight cannot fail is a wish**, and this system has
thirty rules. *Recommendation:* `LINT-01…29` extend `tests/preflight.mjs` over both clients.
`LINT-01…07`, `09…14` and `20…29` are greps; **`LINT-08`, `15`, `16`, `17`, `18` are render-time
probes** through `CSBudgetProbe`, because in a component codebase a *viewport* is assembled from a
dozen files and a per-file grep counts the wrong thing in both directions. **Each check lands with an
entry in `tests/preflight-baselines.json` holding today's count and fails only when the count rises**,
hardening to zero the moment its baseline reaches 0 — otherwise the commit that adds them blocks every
push for the rest of a multi-session build. *Principle served:* `BRIEF` §26. *Benefit:* the system that
already works displaces the one that does not, and stays displaced. *Tradeoffs:* the probes need
preview snapshot tests in CI to run at all; the check ids are `LINT-nn` and not `L-nn`, because
`UX_PRINCIPLES.md` already owns a live `L-01…L-45` namespace and **26 of the ids collide**.

## Phone entries — `docs/ios/DECISIONS.md`

| # | Title | Wave |
|---|---|---|
| **IOS-044** | The tokens, the emitter, the two bundled cuts, and the app icon that finally ships | 0 |
| **IOS-045** | `CSDesign` becomes the product's only container and control vocabulary | 0 |
| **IOS-046** | Home is an edition — a masthead, five wire weights, and a face in every row | 1 |
| **IOS-047** | The card is one object, pushed, at 362 × 312 in every theme | 2–3 |
| **IOS-048** | The course is an editorial object and a pushed screen, and the rating is content | 4 |
| **IOS-049** | The season is a board and the event is a title card | 5–6 |
| **IOS-050** | One standings object, and the ceremony hierarchy is put the right way up | 7–8 |
| **IOS-051** | The two capture hatches — appearance and content size, at launch | 0 |

**IOS-051 is the one to write first even though it is the smallest.** Every light-theme and AX3
statement in `UI_SYSTEM.md`, in all seven surface specs and in both scorecard columns is **computed,
never seen**, because `CupSeasonApp.swift:15,27` applies `preferredColorScheme` from `UserDefaults`
(so `xcrun simctl ui … appearance light` never reaches the UI) and `-UIPreferredContentSizeCategoryName`
does not take. Two DEBUG launch arguments — `-cs_dev_appearance <light|dark|auto>` and
`-cs_dev_text_size <category>` — turn two thirds of this design's accessibility claims from arithmetic
into evidence. Without them **the Phase-7 review is blind on two of its ten axes**, exactly as Phase 1's
was.

---

# 7 · WHAT IS NOT IN SCOPE

**Say so in the commit when you touch the edge of one of these, rather than quietly doing it.**

1. **The UX overhaul's unbuilt items.** `OVERHAUL_REPORT.md` §6 lists what the last overhaul
   deliberately did not build — the organiser's invite state (which needs a column on `leagues`, a
   thread through both `native_home` and `home_dispatch`, and a tenth notification kind behind a gate
   that has never delivered once), and QB-14. Not this overhaul's job.
2. **Server work of any kind.** No migration is required by this design. The three surfaces that want
   new data say so in their own specs and each names a degrade that ships instead: Home's
   **course-discovery wire item** (no producer emits one; without it Home runs on four weights),
   **course ratings** (they do not exist in the product at all — new tables, a write RPC and a read;
   the degrade is `NOT RATED · THE FIRST RATING SETS THE NUMBER` beside an unfilled star rail), and
   three optional `home_dispatch` hints. **Build the degrades. Do not write the migrations.**
3. **The 23 unapplied migrations from the UX overhaul.** Check `node tools/deploy-status.mjs` at the
   start of the session so you know what is owed, and then leave them alone. They are the owner's push.
4. **The ceremony's data.** No season on any device is `complete`, so the takeover band, the trophy
   engraving and the settlement card **cannot be photographed or judged**. Build them to the spec, ship
   them, and record in the wave commit and in the re-score that they are **unjudged**. This is the
   largest hole in the review and it was the largest hole in the last one.
5. **Re-cutting the wordmark.** `brand/README.md` states the setting as a rule and `lockup-dark.png`,
   `lockup-light.png` and `og-image.png` are all **generated from it** by `tools/make-icons.py`. The
   masthead keeps IBM Plex Mono 600, 0.32em, caps, 30pt. A re-cut is a **brand wave** the owner opens,
   not a UI change — and it would mean re-running `make-icons.py` and `make-og-image.py`, re-issuing
   both lockups and the og-image, and amending `brand/README.md`.
6. **Any competition mechanic.** Nothing in `spec/spec-v1.0.md` moves. No band, no allowance, no
   counting cap, no tiebreak, no pot split. If a change alters what a number *means*, you have left the
   UI layer.
7. **The IA.** `COMPONENT_SYSTEM.md`'s seventeen patterns and `INFORMATION_ARCHITECTURE.md`'s five
   destinations are settled by owner ruling. This overhaul clothes them. A blind reviewer's request to
   "split the season page in two" was declined on exactly this ground (`UI_SYSTEM` §20.1) and so is
   every sibling of it.
8. **The refutations already declined.** `UI_SYSTEM.md` §20 and §20.1 carry 96 findings from four
   reviewers plus three blind reviewers, each declined with its reason. Do not re-file them. The two
   the reviewers were right about that Phase 2 could not fix are named in §20.1's closing, and both are
   Wave 0 / Wave 10 work in this file.
9. **`Charter` as a fallback.** It is retired. If the condensed bundle is refused, the fallback is a
   *system condensed sans*, not a return to Charter.
10. **The web's own behaviour.** The desk changes shape, density and type; it does not change what it
    can do. `renderStandings()`, `renderCourseBooks()` and their siblings keep their data paths.

---

# 8 · THE RE-SCORE PROTOCOL

`UI_SCORECARD.md` is the baseline **and** the target. Re-score against both.

## 8.1 The rules, unchanged from Phase 1

- **Same 25 rows, same ten dimensions** (H · T · Sp · C · B · P · R · E · D · M), same questions.
- **The verdict is a function of the mean, not a separate opinion:** `mean ≥ 8 → keep` ·
  `6.0–7.9 → polish` · `< 6.0 → redesign`. Applied without exception, including a tenth either side of
  the line.
- **`EVIDENCE_POLICY.md` still holds.** No production count of behaviour is evidence.
- **The bar is not "good for an indie golf app."** `BRIEF` §1 names the comparison set.
- **The five systemic caps that held every Phase-1 row down are the things to check first**, because
  each one should now be *gone*: premium ≤6 while the card is a border (the card is deleted) · brand ≤6
  without a proprietary object (the rail, the rule-and-figure, the ink scorecard, the markers and the
  shipped app icon) · emotion ≤7 with no faces and no imagery (`CSFace` in every row, the imagery
  ladder) · consistency ≤7 where glyph families mix (one drawn family) · mobile ≤6 where floating
  chrome cuts content (the tab band sits on the page's own ground with a rule).

## 8.2 When

- **After every wave**, re-score only the surfaces that wave touched. A wave that does not move its
  surfaces' scores has not landed.
- **At Wave 11**, re-score all 25 rows plus the **second table** — the twelve sub-surfaces and system
  pseudo-screens. Two of them are P0 (the season ceremony 4.9, the live setup 4.3), one is the highest
  score in the audit (the landscape scorecard **6.8**, which is the product's actual ceiling and is in
  **neither** `BRIEF` §30's Phase-3 order nor the 25-row table) and one is the lowest number in it
  (icons/imagery/avatars **3.9**).
- **Complete or drop the two incomplete rows.** `colour & surfaces` carries six dimensions and `the
  Forge` carries three; a six-dimension mean cannot be compared with a ten-dimension one, and
  `UI_SCORECARD.md` says so itself. Either finish them or delete them.

## 8.3 How to shoot it

**In both themes, at default and AX3, from the real app** — which neither the Phase-1 baseline nor the
Phase-2 target has ever been. Wave 0's two hatches are what makes this possible; **until they exist,
every light and AX number in both columns is computed rather than seen, and a re-score without them
repeats Phase 1's blind spot.** Shoot SE 375 · 17 Pro 402 · Max as well, per Wave 10.

## 8.4 The target

| surface | Phase-1 baseline | Phase-2 target (blind, median of 3) | gap |
|---|--:|--:|--:|
| home | 5.1 | **7.9** | +2.8 |
| player-card | 6.4 | **8.2** | +1.8 |
| profile | 5.8 | **7.8** | +2.0 |
| course | 4.4 | **6.9** | +2.5 |
| season | 4.7 | **7.8** | +3.1 |
| event † | 4.2 | **7.3** | +3.1 |
| leaderboard † | 4.8 | **7.5** | +2.7 |
| **the seven** | **5.06** | **7.63** | **+2.57** |

**Read the target as the design's ceiling, not the build's floor.** It was scored **before** the fix
pass, so where the fix landed it is conservative by construction — and two of its largest fixes
(a photograph on the course page's front door, and the Ryder's two named side groups) have **never been
re-scored at all**. `BRIEF` §29's bar is **8**. The realistic Phase-3 target is that all seven clear
8 and **no surface anywhere is left below 6**.

**And protect these five**, each named unprompted by a blind reviewer as a thing the design gets right
that the category usually gets wrong — a refactor is exactly where they die: **the cut rule and the
month band** ("the two devices that make this surface FPL-grade") · **correct tie handling**
(`04 / 04 / 06`) · **the scale grammar** (the same table reading correctly at 2, 6 and 12 golfers) ·
**the every-meeting tape** ("an original scoreboard graphic") · **the copy** — not one reviewer asked
for a word to be rewritten for tone.

**The two dimensions the target itself warns about**: consistency **6.43** and information density
**6.86** are the two lowest in the target column. Those are what Phase 3 must not lose.

---

# 9 · THE OWNER'S SHIP COMMANDS ARE UNCHANGED — AND YOU NEVER RUN THEM

**`docs/ux-overhaul-2026-09-04/OVERHAUL_REPORT.md` §8 is the ship list and it has not changed.** Three
layers, three separate deploys — the database (`supabase db push`), the edge functions
(`supabase functions deploy`), and the client (`git push` → Netlify). Conflating them cost fourteen
undeployed client versions early on.

**This overhaul touches exactly one of the three: the client.** No migration, no edge function. The
handoff is therefore short — but state it in full anyway, because the repo may owe the owner a database
push from the *previous* overhaul and the two must not be confused.

**What the build session may run:**

```bash
node tools/build-tokens.mjs        # regenerate; must not throw
node tests/preflight.mjs           # the gate: PASS — 0 failure(s), 0 warning(s)
node tests/sunningdale.test.mjs    # 27 assertions
node tools/deploy-status.mjs       # what is owed, across all three layers
xcodebuild test -project apps/ios/CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
supabase db query --linked "<read-only sql>"     # READ ONLY, and only if you need to check prod state
git commit                                        # locally, on a branch, one wave per commit
```

**What the build session never runs:** `git push` · `supabase db push` · `supabase functions deploy` ·
`supabase secrets` · `./tools/ship.sh`. Those mutate production or need privileged credentials and **a
human stays at that wheel** (`CLAUDE.md`, Deploy & verify discipline). `db push` in particular is
confirmed by typing the word `push`, by a person.

**Three more rules from `CLAUDE.md` that this overhaul is unusually likely to break:**

- **Rule 2 — never hand-edit the version.** The sign-in caption and `sw.js`'s `VERSION` both carry the
  `__CS_VERSION__` placeholder and Netlify replaces it at deploy. This overhaul edits `index.html`
  heavily; leave both lines alone. They were the single biggest source of merge friction in this
  repo's history.
- **Rule 6 — one branch, one machine.** Native work runs **locally**. A remote session cannot run a
  simulator, so it cannot shoot a single acceptance test in this file.
- **`index.html` has MIXED middot encodings** — some template strings carry the literal escape
  `·`, others the real UTF-8 `·`. An `Edit` that fails "string not found" on a middot-containing
  line usually means the wrong form; anchor on adjacent ASCII-only lines rather than fighting it
  (`cat -A` reveals which).

**The handoff sentence, at the end of every wave:** *"Wave N is committed at `<sha>` — client only, no
migration. Preflight PASS, `xcodebuild test` TEST SUCCEEDED (N tests). `git push` when you're ready;
nothing is owed on the database by this wave."* Then check `node tools/deploy-status.mjs` and say
separately whether anything **else** is owed.
