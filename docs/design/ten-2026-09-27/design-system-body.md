
# Design System: Cup Season

## Overview

**Creative North Star: “The tournament board, printed.”** [UI_SYSTEM §0.1](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md).

The tournament board and its almanac: bands, rules, rank rails and a few meaningful objects. The brand is proud, warm, quietly ceremonial and competitive without hype. Dark is the trophy room at dusk; light is the morning tee sheet. [Brand canon §§1–3](spec/brand-canon.md), UI_SYSTEM §§0,2,15. This compiled scan is not a new design authority; approval is pending. The token-native frontmatter is an exact copy of tokens.json, including its source notes and historical amendments; later D-entries govern meaning. No invented ramps or new primitive values are generated.

## Colors

Use the project's roles without renaming them: `act` for ordinary actions; ember (`brand`) for competition and the approved identity hairline (D359/F11); `gold` earned only; opaque `mut` for secondary text; `pos`, `neg`, `cool` for their semantic jobs; `bg0`/`bg1`/`bg2` grounds, identity pigments and pinned ceremony inks for their own surfaces. D381 limits the full Scoreboard competition band to live state. D368's short earned-play-moment stroke is a named exception; it does not recolor the score grid. No opacity on secondary words. [Token notes](packages/tokens/tokens.json), [D358–D368/D381](spec/decision-log.md), UI_SYSTEM §16.

A personal look styles `act` under D359; it never broadly substitutes for `brand`, grounds, ink, earned gold or semantic colors. The `cupfinal` and `wrap` phase exceptions are explicitly named in tokens. Light is a designed paper printing, and ceremony objects retain their own ink ramp in both themes.

## Typography

Board: IBM Plex Sans Condensed for names, figures and agate. Story: system serif for a deliberate sentence. Record: IBM Plex Mono for codes, times and columns. Functional prose/inputs: system sans. The fonts and their roles are incumbent decisions, not a license to add a face. Source growth policy: `apps/ios/Packages/CSDesign/Sources/CSDesign/Type.swift`; qualitative roles: UI_SYSTEM §1. No numeric type values absent from tokens.json are added to frontmatter. An agate label remains only if it carries an independent fact; repeating its heading violates D360.

## Layout

Native preserves its five destinations and phone hierarchy; web uses the desktop sidebar and wide two-column body (D234, UI_SYSTEM §14). Use the `space` scale and structural constants from the frontmatter. Reflow meaning at AX3 rather than shrinking the same row. Home is social, Profile identity, Course editorial, Season narrative, Event a moment, History an archive (BRIEF §31; UI_SYSTEM §15). Surface strategy is in family briefs.

## Elevation & Depth

Most structure is type, rules, rails, bands and whitespace. A panel holds one figure/word, a leaf holds a printed grid, and an object is an artifact worth keeping. Shadow values are only the source `shadow` group. No generic card stack, glow, glass, wash or decorative gradient. [UI_SYSTEM §§3,10–11](docs/ui-overhaul-2026-09-06/UI_SYSTEM.md).

## Shapes

Use the exact `radius` and `space` tokens. Drawn score marks are rings/boxes, not a semantic heat map. Pigment and marker identity stay consistent across surfaces. The CS pennant is the production mark (D358), sparingly signing identity; do not change it or its generated assets. Canonical component implementations resolve historical geometry conflicts, which the checkpoint records rather than silently normalizing.

## Components

Ordinary primary actions use `act`; secondary actions use the existing shared styles; gold never paints control chrome (D359, UI_SYSTEM §7 as amended). Fields pair labels, values and adjacent validation. Keep safe focus/keyboard paths. Native tab band is D269's ratified structure; desktop sidebar is D234's. Every points figure retains its receipt path (§16). State components preserve cached content on read failure and identify missing data honestly. Exported round artifacts honor D380/D385's consent and cancellation boundaries.

## Do's and Don'ts

- **Do** keep one fact in its closest useful place (D360).
- **Do** preserve the literal ledger sentence and UI_SYSTEM §16A.1 placement.
- **Do** use real, consented photographs when present and the existing drawn/marker fallback when absent; never fabricate faces or lift scores with invented content.
- **Do** preserve 44pt targets, readable text in both themes, Dynamic Type, VoiceOver and Reduce Motion.
- **Don't** treat old “ember = primary action” or “mark open” summaries as current authority.
- **Don't** let a skill default silently reverse ratified type, navigation, color, dark-first or copy laws.
- **Don't** introduce bounce, glow, glass, sports gradients or gamification (BRIEF §33; UI_SYSTEM §11).

This record contains no unsourced new aesthetic choice. Any future unsourced direction must be labeled **PROPOSED** and sent to the checkpoint.
