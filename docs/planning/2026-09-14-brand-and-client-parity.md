# Brand and client parity · Claude implementation brief

Status: **Ready for Claude; not dispatched automatically.** Owner requested this brief after reviewing the current/future comparisons. Implementation proceeds in Claude's owned workspace; this document does not itself deploy application changes.

## Outcome

Make mobile web a dependable view of the product the owner sees on iPhone. Preserve working native interactions and bring BOTH clients toward the owner's complete brand reference. A matching logo alone is not parity. Signing must not block HTTPS phone review.

## Reference and authority

The owner's September 14 board is preserved unchanged at:

[Owner brand board](../brand/references/2026-09-14-owner-brand-board.jpg)

SHA-256: `17ea615b30871073d82468cda9d41e15a21afedfbfc38e4e61685fccb83ec48d`.

This is the visual reference for this pass. It does not make the pictured 2030 targets current metrics, authorize new competition mechanics, supply licensed course photography, or turn every marketing composition into an application wireframe.

Read AGENTS.md, CLAUDE.md, docs/doc-map.md, product vision, brand canon/bible, tokens, UI_SYSTEM, D222/D234/D305/D313/D339 and docs/design-designv1-implementation.md. Resolve stale instructions explicitly under the repository's hierarchy. The older return to a proven utility UI did not require abandoning the brand composition.

Owner corrections governing this pass:
- Cream pennant/lockup on deep fescue; dark-green mark on warm paper. The board is not a request for a bright-green logo on green everywhere.
- Fescue and warm paper dominate. Orange must cease to dominate ordinary welcome, actions and navigation. Use the existing look/token mechanism for a coherent green action treatment; keep identity, semantic colors and earned gold separate. Do not globally replace every orange/positive/gold value.
- Editorial serif for brand/story moments, board typography for competition and figures, restrained metadata. Preserve the real native UI hierarchy instead of rebuilding it from a marketing board.
- Sparse fine contours supporting the composition; no busy terrain behind reading. Real course/round photography where legitimately available, with a designed truthful no-photo state.
- Native's five-position band: Home, Compete, Play, Golfers, You. Play stays labeled in the center, uses the native outlined glyph, and has no floating filled disc. Selected ordinary tabs use neutral ink/underline as native does. Preserve actual Play entry behavior and existing shortcuts.

Codex's September 14 recoloring/oversized-score mockups are review history, not the new design authority. Document the bounded appearance amendment before implementation wherever current canon still mandates orange on ordinary actions. Gameplay mechanics remain unchanged. Exact production logo geometry remains subject to the owner reviewing the concrete result; use the established vector generator, not a raster trace.

## Source and ownership

Application baseline: main **1bc307f** at brief creation. Native build **890** archived from that source; the last release attempt failed distribution export. Do not equate that archive with the owner's installed TestFlight build. Verify current branches/deployment versions and record what is actually installed/available before claiming parity.

Previous release evidence is on `origin/codex/paired-release-2026-09-14` at **dfc232c**, file `docs/reviews/2026-09-14-paired-release-evidence.md`. Signing recovery is separately owned by Claude on `claude/testflight-890`; inspect its latest handoff before changing release tooling. Do not overwrite that branch or assume an earlier signing diagnosis is still current.

- Claude: lead implementation editor for web, native counterparts, shared token/mark sources and their generated outputs, focused tests and the parity ledger. Use a new `claude/brand-client-parity` branch/workspace; no edits in Codex's workspace or concurrent editors of index.html.
- Codex: independent committed-checkpoint review, native/local verification and integration checks. Return findings to Claude; no simultaneous implementation edits to Claude-owned files.
- Owner: judges the concrete paired visual checkpoint and handles any Apple account interaction that remains necessary.

No automatic task dispatch or agent messaging is configured. Work can overlap: Claude builds the next independent slice while Codex reviews a committed checkpoint. Shared contracts/tokens must be committed before another agent consumes them.

## Start by exposing the full gap

Create one living `docs/reviews/2026-09-14-brand-client-parity-ledger.md` covering each row below. Columns: surface, native behavior/version, web behavior/version, difference, governing reference, named builder/reviewer, implementation SHA, native evidence, web evidence/HTTPS link, remaining limitation, status. Seed from code plus real captures, not from older claims that a packet was complete.

Required rows:
1. Boot, welcome, email/code entry, join entry and branding.
2. Header, five-position navigation, Play entry and back/dismiss behavior.
3. Home: actual dispatch priority, season context, recent round, activity and upcoming plans.
4. Compete and season detail: creation door, selected-league routing, standings and receipt drill-down.
5. Play/post: live/post/planning choices, draft continuity, solo/squad counting copy and completion.
6. League setup: editable rules, factual preset explanation, review and creation retry.
7. Golfers, You, career/handicap facts and existing rivalry surfaces.
8. Round receipt, no-photo and with-photo states, privacy-aware sharing and share artifacts.
9. App/PWA icons, favicon, Apple touch icon, link preview/OG, boot and lockup asset family.
10. Appearance/selected-look coverage, light/dark, accessibility, keyboard/safe areas and cache/update behavior.

Platform-only widgets, Live Activities and system integrations get explicit platform-specific rows with applicable web behavior; do not claim browser equivalents that do not exist. Do not defer shared feature/flow differences by calling them platform-specific.

## Build order and review checkpoints

### A · Brand and shell proof, using working app screens

Implement a bounded paired checkpoint: welcome plus native-style navigation, Home/Compete mastheads and one real round/receipt brand moment. Share a working HTTPS deploy preview and directly viewable phone images early. Include reference/current/proposed comparisons, plus real native captures where available. Show the board's cream-on-fescue and green-on-paper treatments; green actions should not require orange identity marks.

Preserve ranked Home priorities and truthful facts. In signed-in imagery do not substitute stock scenery for an actual round photo. Do not invent a score, opponent, handicap, photo, milestone or statistic to fill the board. Marketing photography needs documented rights and must never masquerade as account data.

### B · Shared function and remaining surface gaps

Close the ledger's remaining shared behavior gaps on BOTH clients. Prioritize blockers in sign-in/join, league entry, Play/post, setup, receipt navigation and photo handling. Retain current competition rules, custom setup options, backend attribution and every points-to-round explanation. Failed reads stay unknown or preserve prior facts; never become invented zeroes or success.

### C · Asset family and release readiness

Generate the accepted asset family from its single source. Verify native icon, favicon, PWA/maskable/Apple touch icons, lockups and OG/share composition together. No old/new identity mixture can silently survive under a 'done' status. Keep unapproved production asset promotion separate from the preview.

Produce a final paired candidate and explicit remaining differences. Do not let certification/signing hold the web preview. Production promotion follows review of the concrete checkpoint; no DB, Edge, secret or certificate-revocation actions are part of this design brief.

## Evidence required before a row closes

- A source commit or green unit test alone is not visible delivery. Capture both implementations and name the exact versions.
- Mobile web: 320/390 widths, short viewport, light/dark and enlarged text; Play label visible with five slots and no floating action. Check scrolling, keyboard entry, back/dismiss and reachable controls. Include desktop smoke coverage because the PWA is shared.
- Native: relevant simulator builds/tests and actual captures, including small phone and accessibility text where applicable. Label simulated versus physical-device evidence.
- Exercise real navigation controls, loading/empty/error/retry states, draft preservation, league context, accurate counts, receipt routes and photo permission/share paths. Do not create production rounds, invitations or league changes merely to produce screenshots; use isolated fixtures/test environments for consequential writes.
- Read-only real account examples are allowed under existing owner authorization; keep private captures and account identifiers out of the public repository. Use clearly labeled fixtures/redacted evidence for committed reports. Never commit auth codes or credentials.
- Run affected browser/native tests, preflight and diff review. Verify generated output at source. Browser freshness bypass does not prove SW update/offline behavior: test those separately and state limits.
- Completion states: scoped, built, independently reviewed, preview verified, production verified. A missing native counterpart, inaccessible preview or untested behavior remains visibly open with owner/next step.

Final handoff: exact branch/SHA; files changed; reference mapping; screenshots; HTTPS preview/version readback; tests; web/native parity ledger; platform-only differences; database/Edge/client/native deploy status; signing status; next owner. The first useful output must be a working paired visual checkpoint, not another inventory-only handoff.
