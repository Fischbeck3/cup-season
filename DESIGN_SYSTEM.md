# DESIGN_SYSTEM.md — Cup Season implementation guide for Codex

This is a fast orientation for visual work. It intentionally does **not** replace the canonical design sources.

Canonical order:

1. `packages/tokens/tokens.json` — values
2. `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md` — current visual language and exact rules
3. `spec/brand-canon.md` — identity, voice, visual laws
4. `spec/brand-bible.md` — applications / messaging

If this file conflicts with those sources, the canonical source wins.

---

## 1. The design thesis

Cup Season should feel like:

> **the tournament board, printed**

The product is not trying to look like:
- a fantasy-sports dashboard
- a sportsbook
- a fintech product
- a generic SaaS card grid
- a glossy golf GPS app

Its reference grammar is:
- tournament board
- scorecard
- sports-page agate
- almanac
- season book
- trophy plate
- ball marker
- clubhouse record

The app should still look like Cup Season with the logo removed.

---

## 2. Two rooms, one club

### Dark — trophy room at dusk

Core shipped identity:
- ground: `#0F1A15`
- primary light ink: `#F1F4EF`
- ember / brand: `#E8622C`
- champagne / gold: `#D8B25A`
- positive semantic: `#4EC584`
- cool / down semantic: `#7F8C95`
- ceremony object ground: `#0A0E0C`

Dark should read green-black, not neutral charcoal.

### Light — morning tee sheet

Core identity:
- paper ground: `#F4F1E9`
- dark ink: `#151B17`
- ember deepens on paper: `#A8420F`
- champagne becomes darker / bronzed for legibility: `#7A5A12`
- positive: `#0B7340`
- negative: `#B02A20`

Light mode is warm printed stock, not a white version of the dark theme.

Do not invent visual hexes from this summary if a token already exists. Use the token source.

---

## 3. The two-metal law

This is one of the strongest brand rules.

### Ember means:
- LIVE
- the one primary action

It is active energy.

### Champagne gold means:
- earned
- lead
- trophy
- pot
- founder / honor
- a legitimately earned upward state

Gold is scarce on purpose.

**Gold on an ordinary button, tab, or nav item is a defect.**

Gold is not "premium chrome."

If a screen feels visually weak, do not fix it by spending more gold.

---

## 4. Typography has four jobs

### Board — IBM Plex Sans Condensed

Job:
- names
- ranks
- figures
- display numerals
- column heads
- tournament-board information

This is the brand-carrying numeric / competitive face.

### Story — system serif / New York

Job:
- the one story sentence
- lead
- season prose
- editorial / almanac moments

Serif speaks in sentences.

Do not put serif on controls.

### Record — IBM Plex Mono

Job:
- codes
- handles
- times
- scorecard columns
- true record-like entries

Mono should not become the default UI voice.

### Workhorse — SF Pro / system sans

Job:
- body
- forms
- functional prose
- standard interface reading

Do not introduce a fifth type family without a design-system decision.

---

## 5. The signature grammar

### Rank rail

Ranked lists begin from a left rail rather than a generic card.

The rail carries position.

An earned rank can be painted with earned color. "You" can have its own defined treatment.

The rank rail is a structural identity element, not decoration.

### Rule-and-figure

Important numbers should feel printed / scored.

A figure:
- uses the board face
- uses tabular figures where appropriate
- sits with a 2pt rule
- carries its label in metadata / agate below
- keeps the number itself legible and disciplined

The rule can carry state:
- ink = normal
- ember = live
- gold = earned

Do not solve every figure by putting it in a rounded card.

Canonical maxim:

> **Numbers never wear a box; boxes wear numbers.**

---

## 6. Containers

The September UI system deliberately rejects generic card proliferation.

Structure should primarily come from:
- bands
- rules
- rank rails
- spacing
- alignment
- typographic hierarchy

Allowed object metaphors are constrained.

### Panel
A small opaque tile for one number / one word.

Not prose.

### Leaf
Paper / scorecard object.

Use when the content genuinely behaves like a printed grid or record.

### Object
A physical / ceremonial artifact.

Do not nest containers reflexively.

Avoid:
- card inside card
- panel inside panel
- tinted boxes around every KPI
- hairline-bordered rectangles whose only job is to separate content

---

## 7. Score grammar

Golf score quality should not become a rainbow heatmap.

Traditional scorecard marks are stronger:
- ring
- double ring
- box
- double box

The score can remain ink.

Semantic color has specific jobs and should not be used as generic emphasis.

---

## 8. People / golfer identity

The product should feel populated by real golfers.

Use the existing `CSFace` / marker system rather than random avatar grammar.

Rules from the current visual direction:
- people should have a consistent rendered identity
- faces / markers belong in competitive and social rows
- a round photograph is not an avatar
- round photography renders as photography, typically as a plate

Do not invent a second avatar system casually.

---

## 9. Photography

The brand favors real golf:
- real crews
- real courses
- morning / dusk
- munis and lived-in golf, not only polished private-club fantasy
- photography that feels like someone's season, not stock advertising

A photo is a photo.

Do not add color washes / gradient overlays as a default brand effect.

Use typography / ground contrast intentionally.

---

## 10. Topographic / contour accents

Topo / contour is a supporting Cup Season device.

Use it:
- at plate scale
- in deliberate brand moments
- as a quiet secondary layer
- where it can imply course / place / terrain / movement

Do not:
- wallpaper every screen
- run it behind dense text
- use it as a replacement for layout
- make it compete with a course photo
- make it the primary logo idea by default

The contour should feel printed / engraved rather than digital neon.

---

## 11. Motion

There are two basic behavioral families.

### Roll-out

```css
cubic-bezier(.16,.84,.36,1)
```

For:
- arrivals
- settling
- things that travel
- transitions that should feel like a putt dying at the hole

### Snap

```css
cubic-bezier(.2,0,0,1)
```

Approximately 180ms for controls answering a finger.

The law:

> Nothing bounces. Things roll out and settle.

Do not add springy consumer-app motion because it is fashionable.

---

## 12. Radii

The current token system deliberately constrains radius vocabulary.

Do not invent local literals because a component "looks better" at 14 or 18.

Use the existing radius tokens.

A capsule / pill is a capsule, not a new radius token.

---

## 13. Navigation

Current product destinations:
- Home
- Compete
- Play
- Golfers
- You

The current UI direction avoids floating chrome that covers content.

Play can carry the live/primary treatment; that does not mean every nav state gets a colored filled disc.

Navigation should feel integral to the printed board / band system.

---

## 14. Actions

Action hierarchy must be obvious without three loud colors.

Use:
- one primary action
- restrained secondary action
- quiet text / link actions
- hidden / progressive doors for low-priority actions

Do not turn every possible next action into an equal button.

Gold is never the solution for an action.

Ember is budgeted. Spend it intentionally.

---

## 15. Copy as interface

Cup Season copy is one of the strongest identity assets.

### Preferred register

- direct
- warm
- proud
- lightly ceremonial
- specific
- quiet confidence
- crew language

### Avoid

- "Don't miss out"
- "You won't believe"
- fake urgency
- streak shame
- sportsbook language
- generic motivational sports language
- corporate golf language

### Product terms

Use:
- The Pro
- Run it back
- every round counts
- named competition bands
- receipt / record language where appropriate

Avoid exposing internal jargon just because the schema uses it.

---

## 16. One fact, one place

This is a hard UX law.

If a fact appears in a row next to the action, do not repeat it:
- in the page intro
- in a summary
- in a badge
- in a button
- again below the button

The interface should feel confident enough to say something once.

This also makes the app feel less AI-written.

---

## 17. Empty / loading / disabled

Do not treat states as afterthoughts.

The current UI system defines them as first-class.

An empty state should:
- have a visual shape / object
- orient the user
- provide the next door
- avoid blaming the golfer for not having done something

Loading should resemble the destination's geometry, not a generic spinner sitting in a card.

Disabled should be legible but quiet.

---

## 18. Brand artifacts

Strong Cup Season brand moments should feel worth keeping.

Examples:
- settlement card
- round recap
- season recap
- standings artifact
- trophy / record
- share card

Use the **archive test**:

> Would this still look right printed in the crew's season book in 2046?

Prefer:
- stamped
- printed
- engraved
- scorecard-like
- trophy-plate-like

Avoid:
- glassmorphism
- glow
- generic AI gradients
- trendy chrome treatments with a two-year shelf life

---

## 19. Logo / mark — current state

The mark remains open in the canonical brand docs.

Production currently has an older mark family; do not assume it is the final answer.

Current owner exploration:
- no cactus
- no desert theme
- keep the symbol close to the actual UI identity
- explore pennant / season-marker / CS geometry
- topo / ridge can support the mark without becoming a generic "flag in a hole"
- must pass:
  - hat test
  - archive test
  - embroidery
  - one-color
  - favicon / 16px
  - circle crop
  - dark + paper

Do not merge a concept into the live product until it is explicitly approved.

---

## 20. UI review checklist

Before calling a visual task done, ask:

### Hierarchy
- Is there one obvious thing to look at first?
- Is the story sentence actually a story?
- Are important figures treated like figures rather than card copy?

### Color
- Is ember reserved?
- Is gold actually earned?
- Did a new arbitrary color sneak in?

### Type
- Is Board used for competitive figures / names?
- Is serif telling a story, not labeling a button?
- Is mono actually record-like?

### Structure
- Could a border / card be removed without losing meaning?
- Is a rank list using the rank grammar?
- Are boxes holding numbers, rather than numbers living in boxes?

### Copy
- Is the same fact repeated?
- Is internal jargon leaking out?
- Does the language sound like a golfer / Pro rather than a growth team?

### Brand
- Would it still look right in a season book years from now?
- Does it feel like Cup Season with the logo removed?

### Accessibility
- Verify contrast.
- Verify Dynamic Type / scalable text behavior where relevant.
- Verify touch targets.
- Verify the screen at realistic narrow phone widths.
- Verify light and dark when the component exists in both.

---

## 21. When doing a design task in Codex

Use this sequence:

1. Read the relevant existing screen.
2. Read the canonical UI section for that component / surface.
3. Inspect current tokens / shared components.
4. State the visual problem in one sentence.
5. Propose the smallest design-system-consistent change.
6. Implement.
7. Compare light + dark.
8. Compare narrow + standard phone width.
9. Check typography and gold/ember budgets.
10. Run preflight and platform tests.

Do not start by creating a new component library.

The goal is to make the existing Cup Season system more coherent, not to design a second one.
