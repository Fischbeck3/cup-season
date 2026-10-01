---
version: 1
slug: "apps-ios-cupseason-compete-competescreen-swift"
primary_target: "apps/ios/CupSeason/Compete/CompeteScreen.swift"
related_targets:
  - "apps/ios/CupSeason/League/LeagueIdentityViews.swift"
  - "apps/ios/CupSeason/League/LeagueIdentityEditor.swift"
  - "apps/ios/CupSeason/Season/SeasonPage.swift"
  - "apps/ios/CupSeason/Season/SeasonRulesPage.swift"
---

# competition · ios

Mode: **Operate**. Existing-world scope, expanded by the owner's confirmed Club Spread brief and September 30 instruction to build and ship it.

## Scope and task

The Scoreboard supplies the live moment; the Book holds the season. Follow D381 state colors and Book eligibility.

Surfaces: compete, intent, scoreboard, book. Target: `apps/ios/CupSeason/Compete/CompeteScreen.swift`. Sibling: `index.html#view-compete`.

## Character and constraints

Source: BRIEF §§29/31/33/35, UI_SYSTEM including amendments, PRODUCT.md and D234/D358–D396. Inherit the token system; custom tab band and three-voice type are existing canon. Phone and desk keep their own shape. Preserve the five destinations, literal money sentence, traceable points, consent and factual rounds.

## Proof and states

Only existing, demonstrably synthetic fixtures or data-free states are evidence. Check both themes and the specified client matrix. Missing safe fixture: not captured, not scored. A screenshot cannot certify VoiceOver, hardware haptics, keyboard behavior or an unassisted task. No photos/faces/customer claims are invented to improve scores.

## Unresolved

Historical program gaps remain in docs/design/ten-2026-09-27/PLAN.md, CONFLICTS.md and QUESTIONS.md. This build owns Compete league identity, league-page identity and optional Pro customization. Profile is untouched. The confirmed owner-photo/logo brief already makes the sample image replaceable. Final review at root `.impeccable/review/club-spread-final-review.md` has disposition `fix`: all 40 corrected captures pass evidence validity, and the original geometry/editor fixes are resolved within the captured identity-extension scope. Reproduction authority remains open: photo 30.68% failed/open, hero comparison 72.98% `drift`, hero/later state pending. No forced gate, numeric fidelity pass or owner-approved change to authority is recorded. The owner native-release-gate decision and separately confirmed production deployment remain owed. See root `docs/club-spread-build-2026-09-30.md` and `.impeccable/review/club-spread-documentation.md` for exact review limits.

## Direction contract

THESIS: Each league is recognizable by its own image, words and real friends; one compact season record follows that identity.

OWN-WORLD: Existing fescue/paper grounds, IBM Plex Sans Condensed board type, SF prose, token rules and curated two-color looks. League marks use identity color without repainting golfer markers or semantic competition colors.

STORY: Recognize the group, see who's in, read where its season stands, then enter it. The Pro can optionally choose a photo or logo and a short description; the identity survives Run it back.

FIRST VIEWPORT: Modest Compete masthead; open league spreads with square imagery at left and league names at right. Short description and member preview sit close to that pairing; long content and accessibility sizes reflow full width. Compact phase/standing footer. Existing tab band and quiet create/join doors remain usable.

FORM: Club Spread, grounded candidate 6, selected by the owner from the three visual concepts; seed f97d9e31. Approved composition: root .impeccable/mocks/decision/club-spread.png. Existing native fonts and factual member identities are pinned by the confirmed brief; catalog font rankings do not authorize new fonts. No fabricated descriptions or people enter production.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Built extension · 2026-09-30

This is a local expression of the incumbent world under D400. Root `DESIGN.md`, `DESIGN_SYSTEM.md`, `.impeccable/design.json`, the token source and Profile remain unchanged. These observations describe the implementation; they do not close the release gate or establish new global tokens.

- `CompeteScreen` keeps `CompeteRoot` ordering, state and routes. A heavy full-measure masthead rule precedes the separate quiet Your seasons label and neutral rule. Season rows use `LeagueIdentitySpread`; moments retain their existing row shape, and the eligible Book door stays beside its lead season.
- The spread's image is a clipped square at 35% of the native horizontal container. The open row uses existing `gutter`, `s1`–`s4`, `rail` and `CSRule`; it adds no card fill, border, shadow or radius. Names use `display`, description/people/support use `bodyS`, phase uses `agate`, and the compact standing uses `name`.
- A short name and description share the image/name pairing. A title over 30 characters forces the pairing into a column. A description over 48 characters, a long title or accessibility type puts description and people full width. Text grows vertically without truncating league names or suppressing supported season facts.
- Photo fills; logo fits with `s3` inset and a neutral backing chosen for its visible ink. Loading, missing and failed images retain the same stable initial mark. Large marks use the existing curated two-color pair and a flat diagonal; compact headings use a neutral badge with a paired-color foot. Phase and personal appearance do not select the league identity.
- `LeagueIdentityPeople` draws up to three actual member identities through `CSFace`, then the model's name/count line. League livery does not repaint golfer markers. The season footer reads phase, rank, points and supporting copy from existing producers; the whole spread opens its season.

## Finish record

Initial independent review: root `.impeccable/review/club-spread-finish-review.md`, disposition `fix`. Correction packet: root `.impeccable/review/club-spread-fix1.json`. `club-spread-fix1-verdict.md` preserves the historical `recapture` disposition, which stopped before material-fix scoring. Four standing captures were replaced on unchanged application source, and the final manifest matches all 40 originals. The full five-section `club-spread-final-review.md` confirms evidence validity, resolves original fix 2 (rules/35% geometry/footer/reflow) and fix 3 (Close/Save/field/recovery), and finds no additional material UI regression in its bounded correction scope. It remains `fix` for reproduction authority and requested documentation closeout. This pass supplies that closeout without closing the release gate. Hardware haptics, full VoiceOver use, actual Photos permission behavior and successful production upload remain unverified. Existing AX tab labels differ from UI_SYSTEM's glyph-only branch; this incumbent chrome gap is not canonized or repaired here.
