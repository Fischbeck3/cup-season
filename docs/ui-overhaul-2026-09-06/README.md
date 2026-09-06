# Cup Season — the hard UI overhaul, 2026-09-06

*A UI **system** overhaul, not a polish pass. The UX architecture was rebuilt in
`docs/ux-overhaul-2026-09-04/` and shipped; this folder is the separate question the owner asked
next — **does the product look like something people want to open?** Repo
the repo root at HEAD `57b993f`. Read-only on the repo but for this folder; nothing
here is code.*

**The brief in one line:** *"Damn, this looks good."* — `BRIEF.md` §1.

**The verdict in two numbers:** product mean **5.10** across 25 surfaces. Readability **6.36**;
emotional appeal **4.00**; premium feel **4.12**. The product is *readable and unloved*, and that gap
is the whole brief.

---

## STATUS

> ### DESIGNED, NOT BUILT.
> **Phases 1 and 2 of `BRIEF.md` §30 are complete: the audit, the scorecard, the visual system, seven
> surface specs and thirty-four rendered artboards. Phases 3–7 — the build — are specified in
> `BUILD_BRIEF.md` and have not started.**
>
> **Paused by the owner on 2026-09-06**, whose instruction was: *"Design on scheme on Fable, pause so
> we can build on Opus."* The design session ran on one model; the build runs on another, on a later
> day, with no memory of this one. That is why `BUILD_BRIEF.md` exists and why it is as long as it is:
> it is written to be executed without asking a question.
>
> **Not one line of app code has changed.** `apps/ios`, `index.html`, `packages/tokens/tokens.json`
> and `tests/preflight.mjs` are all at HEAD. Every count, every line number and every file path cited
> in these documents was grepped at `57b993f` and will drift the moment the build starts.

---

## READING ORDER

Read them in this order. Each answers a different question and none repeats another — a rule stated
once is cited, not restated, so it cannot drift.

| # | File | The question it answers | Lines |
|---|---|---|--:|
| 1 | **[`BRIEF.md`](BRIEF.md)** | *What did the owner ask for?* The brief, verbatim, in 35 sections. §30 is the phase order; §29 is the bar (8 out of 10, and below 6 is a redesign); §31–§33 are the three ways this kind of work usually goes wrong. | 197 |
| 2 | **[`UI_AUDIT.md`](UI_AUDIT.md)** | *What is actually wrong?* The one-page verdict, **the ten problems ranked by reach × distance from the standard**, **the four things that are genuinely good and must survive**, then 25 screens one at a time, then the system slices — typography, colour, cards, buttons, icons, motion, a11y, data display, the web, navigation. | 4,258 |
| 3 | **[`UI_SCORECARD.md`](UI_SCORECARD.md)** | *How bad, on one scale?* 25 screens × 10 dimensions, one calibration judge, the mechanical verdict rule, the five systemic caps, a second table of 12 sub-surfaces and pseudo-screens — **and a TARGET section**: the median of three blind reviewers scoring the Phase-2 artboards beside the shipped screens. | 367 |
| 4 | **[`UI_SYSTEM.md`](UI_SYSTEM.md)** | *What is the visual language?* **This replaces `docs/ios/IOS-003-design-direction.md` §1 as the identity contract**, and §0.3 lists every kept and every changed row with the reason. Type, colour, containers, spacing, icons, faces, buttons, data display, imagery, motion, navigation, states, the web desk, the six surface characters, the accessibility floor, the copy laws, **the lint**, the glossary of names the build uses in code, and the refutations already declined. | 2,312 |
| 5 | **[`surfaces/`](surfaces/)** | *What does each of the seven Phase-3 surfaces look like, exactly?* [`home.md`](surfaces/home.md) · [`player-card.md`](surfaces/player-card.md) · [`profile.md`](surfaces/profile.md) · [`course.md`](surfaces/course.md) · [`season.md`](surfaces/season.md) · [`event.md`](surfaces/event.md) · [`leaderboard.md`](surfaces/leaderboard.md). Each carries anatomy top to bottom, every state, AX3 as a **layout**, VoiceOver, the SwiftUI files it replaces (grepped, with line numbers), what it consumes unchanged, what new data it would need and what it degrades to without it, motion, the web paragraph, and its own deviations from `UI_SYSTEM.md`. | 3,661 |
| 6 | **[`mockups/`](mockups/)** and **[`system-mockups/`](system-mockups/)** | *What does it look like?* 33 phone artboards at 402 × 874 (the iPhone 17 Pro logical size), one desk artboard at 1440 × 900, and 8 system specimens. Renders are in `*/renders/`. `UI_SYSTEM.md` §19 says what each artboard proves **and lists its known imperfections** rather than pretending there are none. | — |
| 7 | **[`BUILD_BRIEF.md`](BUILD_BRIEF.md)** | *How is it built?* The read-first list · the ten non-negotiables · the exact `tokens.json` diff and the emitter change that must ride with it · the component work in `CSDesign` with Swift signatures · **twelve waves**, each with scope, files, acceptance test, hatch, gates and a files-touched estimate · the web half of every wave · the decision-log entries to write **before** building (D265+ / IOS-044+) · what is out of scope · the re-score protocol · and the ship commands, which the build session never runs. | 1,497 |

**Outside this folder, and binding:** `CLAUDE.md` (working protocol rules 1–6, the deploy discipline,
the phone section, the tokens pipeline) · `docs/ux-overhaul-2026-09-04/` (the UX overhaul this clothes —
`COMPONENT_SYSTEM.md`'s 17 patterns, `OWNER_RULINGS.md` **R-C** on the web's shape, `TERMINOLOGY.md`
§4's 34 retired-word patterns, `EVIDENCE_POLICY.md`, and `README.md` §5 + `OVERHAUL_REPORT.md` §5 for
the wave format this follows) · `spec/brand-canon.md` and `brand/README.md` (the promise, the voice,
the one rule: gold means earned, never chrome) · `packages/tokens/tokens.json` (the token source; the
Swift is **generated** from it, never hand-edited).

---

## THE DESIGN IN ONE PARAGRAPH

**Cup Season is the tournament board, printed.** Golf's own graphic language is not the fantasy app and
not the stadium: it is a hand-set scoreboard on a wall and the almanac that records what the board
said. So the product is built out of **bands, rules and a rank rail** instead of cards; its names,
ranks and every numeral are set in a **condensed grotesk** — the scorer's hand, not the system's; its
metadata is **agate**, the condensed caps of a newspaper's sports page; its one serif sentence per
surface is the almanac's voice; and the only two containers it allows itself are **the panel** (a small
opaque bone tile holding one number) and **the leaf** (a sheet of scorecard paper, licensed only for a
printed grid). Colour is spent on state and nothing else: ember means *live*, champagne means *earned*,
and a golf score's quality is never coloured at all — a birdie is a ring and a bogey is a box, drawn in
ink, the way it is on paper. Money is ink, the sign is a word, and the pot is gold. **Remove the logo
and the rail, the rule-and-figure and the agate still say Cup Season.**

The signature is two devices. **The rank rail** — a 44pt left column carrying a two-digit tabular
numeral, its field painted only when the position is *earned* (gold) or is *yours* (bone); every ranked
list in the product starts with it, and it is the origin of every arrival in motion. **The
rule-and-figure** — a number that matters, set on a 2pt rule the width of its column with its label
hanging beneath in agate, the rule `ink` by default, `brand` when live, `gold` when earned. In six
words: *numbers never wear a box; boxes wear numbers.*

---

## HOW THE MOCKUPS ARE RENDERED

Every mockup is a self-contained HTML file containing one or more `<div class="artboard" id="…">`
elements, each exactly **402 × 874** CSS px (the iPhone 17 Pro logical size) — or **1440 × 900** for
the web desk. Fonts load from Google Fonts; Apple's New York, Charter and SF resolve natively on a Mac.

```bash
node <scratchpad>/web/render.mjs <file.html> <outdir>
```

It screenshots every `.artboard` into `<outdir>/<id>.png` at **2×** and prints any console errors. The
render script lived in the design session's scratchpad and is **not in the repo**; any equivalent
headless-Chromium screenshotter that honours the artboard ids reproduces the set. The command as run:

```bash
node .../scratchpad/web/render.mjs docs/ui-overhaul-2026-09-06/mockups/season.html \
                                   docs/ui-overhaul-2026-09-06/mockups/renders/season
```

**The rule that went with it, and it is worth keeping:** *a mockup you did not look at is not a
mockup.* Every render in this folder was viewed and fixed before it was committed. The contrast ratios
printed throughout `UI_SYSTEM.md` §2 and §16 were computed by
[`system-mockups/contrast.mjs`](system-mockups/contrast.mjs) from the hexes in §2.1, not estimated.

### What the artboards contain, and what they stand in for

| Set | Artboards |
|---|---|
| `system-mockups/renders/` | `cs-system-a` (the nine type roles at size, the rule-and-figure, the panel, the scorecard ink law, the six pigments, the medallion) · `cs-system-b` (the three button tiers and their states, the chip, the field, the movement marks, the empty state) · `cs-system-c` (loading as redacted geometry, the toast, **an AX3 artboard**) · `cs-home-dark` · `cs-home-paper` · `cs-season` · `cs-profile` · `cs-course` |
| `mockups/renders/` | home ×5 · player-card ×5 · profile ×5 · course ×5 · season ×6 · event ×5 · leaderboard ×7 · desk ×1 |

**The photographs are stand-ins, and the deck says so rather than pretending otherwise.** They are
procedurally drawn dusk plates — a noise-modulated sky, a blurred treeline, mown turf bands, a horizon
feather, film grain — at each object's true pixel size. They are **not** a gradient wash (`UI_SYSTEM`
§10.1 bans one outright, and all three Phase-2 directions were rejected for using one), **not** a
cartoon golf hole, and **no face is fabricated anywhere in the set**. In the build the frame is a real
golfer's own round photo; what the mockup specifies is the crop, the scrim geometry, the credit line
and the panel.

**Known imperfections are stated, not iterated away.** `UI_SYSTEM.md` §19 lists eleven of them by
artboard — a ledger line that wants 14 more points on `cs-season`, a clipped pigment row on
`cs-system-a`, two artboards running past the fold. Each says what a real device does differently and
why the mockup's version is acceptable.

---

## A CAVEAT ABOUT THE SHIPPED SCREENSHOTS

**The screenshots of the shipped app that this audit was made from are not in the repo, and were never
meant to be.** They were session scratch — 100+ PNGs across three device sizes, both themes, and every
DEBUG launch hatch, captured on 2026-09-06 at HEAD `57b993f` on iOS 26.5 simulators, **signed in as the
owner's real account**. They carry a real person's name, city, home course, handicap, leagues, buddies
and rounds; **this repo is public**, and `stamp-version.sh`'s build-time allowlist would not have
served them but committing them would still have published them.

**So `UI_AUDIT.md` describes them instead of storing them**, in enough detail that every finding is
checkable: which screen, which hatch launched it, which device, which theme, what was on it, and where
in the code the defect lives. Where the audit measures a pixel it names the hex and the ratio; where it
counts something it prints the command. **`UI_AUDIT.md` §0 also names what the capture could not
reach** — the season ceremony (no complete season on the account), the finish screen, the trophy room,
the Major room, draft night, the error toasts, the loading placeholders, the offline banner and the
widgets, all of which were audited from code and are marked as such.

**Two capture blockers stand and Phase 3 inherits them** (`UI_SYSTEM.md` §16.6). Every `light-*.png`
rendered the dark theme, because `CupSeasonApp.swift:15,27` applies `preferredColorScheme` from
`UserDefaults` and `xcrun simctl ui … appearance light` never reaches the UI. Every `dark-ax3-*.png`
rendered the reading size, because `-UIPreferredContentSizeCategoryName` does not take. **Every
light-theme and every AX3 statement in every document in this folder is therefore computed, not
seen** — which is filed as a finding (F-16), not scored as a defect, and which
[`BUILD_BRIEF.md`](BUILD_BRIEF.md) §4 fixes in Wave 0 with two DEBUG launch arguments, before any wave
is signed off.

---

*Phase 1 audit and Phase 2 design, 2026-09-06. Four verifier passes and three blind reviewers attacked
the design; every blocker and every major finding is fixed in place and marked, and every declined
finding is recorded with its reason in `UI_SYSTEM.md` §20 so nobody raises it twice. The build is
`BUILD_BRIEF.md`, and it starts at Wave 0.*
