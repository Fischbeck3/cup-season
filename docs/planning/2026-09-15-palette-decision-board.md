# Palette decision board — 2026-09-15

Status: exploration requested by the owner, not a selected palette or production change. The existing CS pennant/logo remains unchanged. Built-in image generation creates visual proposals; these are not captures of implemented UI. Names, scores and matchups are illustrative.

## The decision

The owner wants an entire palette refresh and a visibly more colorful, energetic Compete experience. Earlier rules restricted ember to active competition. This exploration proposes a broader competition identity for Compete, seasons, events and matchups, with the same identity following those items onto Home. Selecting a palette would require a recorded amendment to the current color rules before implementation.

Keep the distinction between **competition identity** and **live status**: a colorful season surface does not claim an event is currently live. Actual live/closed/pending states still need explicit wording and accessible indicators. A general Home booking remains ordinary, even on the day of play.

## Alternatives

Boards: [A — Field & Volt](../brand/references/2026-09-15-palette-a-field-volt.png), [B — Ink & Coral](../brand/references/2026-09-15-palette-b-ink-coral.png), [C — Paper & Cobalt](../brand/references/2026-09-15-palette-c-paper-cobalt.png). [Generation prompts](../brand/references/2026-09-15-palette-prompts.md).

Visual QA: all three show the intended everyday/competition palette difference and readable sample screens. Generation introduced small variations in layout, glyphs, mark rendering and surface shading. These are not proposed logo/icon changes or authorization for gradients; the existing vector logo remains the production source. A's tiny masthead red tick and B's Home coral rule are reference carryovers, not intended ordinary-decoration roles. A's teal Golfers tile and C's blue You tile should not establish additional section themes. Refine those details in deterministic UI after palette selection.

| Option | Everyday app | Compete | Tradeoff |
|---|---|---|---|
| A — Field & Volt | Forest, chalk and fern | Teal grounds and electric lime score panels | Closest to the golf identity; sharper sporting energy. Large lime areas need discipline. |
| B — Ink & Coral | Midnight ink, porcelain and sea glass | Plum and coral | Warmer and more social; could still feel too close to ember if coral drifts orange. |
| C — Paper & Cobalt | Oat paper and deep golf green | Cobalt, sky and white | Strongest separation; light-first presentation is a more substantial change. |

Candidate colors are exploratory, not additions to production tokens:
- A: forest #10281F, pine #1D3C2E, chalk #F4F1E8, fern #77B98B, lime #D5F45B, teal #087F78.
- B: ink #142530, slate #263E4A, porcelain #F3F0E9, sea glass #93C9BF, coral #FF876D, plum #512C50.
- C: paper #F3EFE5, warm panel #E8E0D1, deep green #17392B, action green #28764D, cobalt #274BCE, sky #C2DDFF.

## Shared structure

Home, Play, Golfers and You share the everyday palette. Compete has a richer ground, larger colored bands, contrasting score panels and restrained topo. Competition content retains its colors when surfaced elsewhere. Navigation remains one coherent five-tab system. Photos, editorial typography, the actual pennant and factual golf data carry identity across every option.

Positive/negative results, errors, disabled controls and earned awards remain distinct semantic roles. The competition accent must not masquerade as a favorable result or earned gold. No logo redesign, new mechanic, notification change or live deployment is part of this board.

## Before implementation

Pick a direction, then refine Home, Compete, a season room, a live scorecard, a booked round and a receipt in both themes. Verify actual text/control contrast, color-vision accessibility, enlarged text and active/finished states; generated artwork is not an accessibility test. Preserve logo source geometry exactly in production. Define semantic token pairs and generate native tokens from source, then implement web and iOS together.

The board intentionally holds content/layout stable across options. Judge the palette and distribution of color, not incidental image-generated UI details.
