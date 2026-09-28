# S1b · readable Home occasion

Approved by the owner’s “Build recommended.” Branch `codex/ten-home-contrast-2026-09-28` starts independently at release candidate `5fabf861`. This is a local review commit; no shipping action is authorized.

## Change

In `index.html`, `.hocc` uses existing `bg1` instead of inverse `panel`, so its existing `ink` and `mut` have their correct ground. Normal and earned `.ho-act` use `act`. Competition/earned fact cues, copy, rankings, visibility and handlers remain unchanged. No token, generated file, backend or native production edit.

Native counterpart inspection: `HomeView.swift:543–550` passes `cs.ink` into `HomeWireLine`, which draws on page `cs.bg0` without an inverse panel. Ink/bg0 is 16.055:1 dark and 15.491:1 light; muted/bg0 is 7.070:1 and 5.851:1. [Source calculation](native-source-contrast.json). Existing Home/dispatch/occasion unit suites pass. Rendered native occasion remains **not captured, not scored**: safe Home hatch clears the occasion, and other fixtures contain excluded pilot identities. No unnecessary native visual change was made.

Impeccable sequence: craft floor → colorize → polish → independent A/B family critique. The existing fescue/paper world and semantic color hierarchy are preserved.

## Measured change

| Text | Dark before → after | Light before → after |
|---|---|---|
| Heading | 1.077 → 14.103 | 1.010 → 14.021 |
| Body | 2.108 → 6.211 | 2.674 → 5.296 |
| Ordinary action | 2.828 → 5.136 | 2.719 → 6.272 |

[Contrast data](contrast.json) covers all four widths and both normal/earned CSS variants. Each repaired text role exceeds 4.5:1. Earned styling was toggled solely to inspect the color pairing, not presented as a fabricated earned event.

## Evidence and verification

- [Manifest](manifest.json): six representative before/after images, exact hashes and source identity. The compact component crop includes fixed navigation; use the desktop crop for the complete card. The crop alone does not demonstrate action reachability.
- 375/402/1280/1600 × dark/light captures for event_live; additional same-width/theme [brand_new, between_seasons, preseason and ceremony_night](additional-states.json). All contrast/zero-horizontal-overflow checks pass; no page exceptions. Missing account read models remain empty and explicitly unscored.
- A compact screenshot initially put the fixed nav over the action. [Scroll confirmation](scroll-confirmation.json) compares source baseline and after: normal document scrolling exposes the action in all six affected 375px state/theme combinations on both versions. No geometry regression was found and no layout mutation was used.
- [Existing Home hierarchy/repetition browser suites](browser-tests.json): all 16 suite/matrix executions pass, preserving desktop two-column layout and one-fact ownership.
- [Homefold test](homefold.txt): one passed. [Final preflight](preflight.txt): **0 failures, 0 warnings**. No dependency installed; temporary symlink to already-installed packages only.
- Native full non-UI verification during S1a: 1,573/1,574 pass with the same unsigned-simulator keychain entitlement failure; Home-related suites pass. Full authenticated UI and owner/human checks remain unrun.

## Limits and critique

The fixture console is not clean: Supabase lock deprecation, blocked worker, missing career/schedule read models, and expected failure-path test logs. These were recorded, not suppressed or claimed clean. No production runtime exception was observed.

[Fresh family critique](web-home-critique.md): 16/24 observed points. Three residual P2s remain: faint helper text, the small/faint Dismiss control, and competition ember on ordinary buddy navigation. The family snapshot remains open. The selected P1 ink/panel mismatch is fixed; the program’s full craft floor, 36/40 target, 10/10 panel and human gates are not claimed complete.

Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none.
