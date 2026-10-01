---
version: 1
slug: "apps-ios-cupseason-season-seasonrulespage-swift"
primary_target: "apps/ios/CupSeason/Season/SeasonRulesPage.swift"
related_targets:
  - "apps/ios/CupSeason/League/LeagueIdentityViews.swift"
  - "apps/ios/CupSeason/League/LeagueIdentityEditor.swift"
---

# rules · ios

Mode: **Read**, with the optional Pro identity task in **Operate**. This existing-world brief includes the owner-approved D400 extension; competition rules remain unchanged.

## Scope and task

Answer how the competition works and how figures arise; one reading path with clear wayfinding.

Surfaces: rules. Target: `apps/ios/CupSeason/Season/SeasonRulesPage.swift`. Sibling: `index.html#rules`.

## Character and constraints

Source: BRIEF §§29/31/33/35, UI_SYSTEM including amendments, PRODUCT.md and D234/D358–D396/D400. Inherit the token system; custom tab band and three-voice type are existing canon. Phone and desk keep their own shape. Preserve the five destinations, literal money sentence, traceable points, consent and factual rounds.

## Proof and states

Only existing, demonstrably synthetic fixtures or data-free states are evidence. Check both themes and the specified client matrix. Missing safe fixture: not captured, not scored. A screenshot cannot certify VoiceOver, hardware haptics, keyboard behavior or an unassisted task. No photos/faces/customer claims are invented to improve scores.

## Unresolved

Historical capture gaps, content ceilings and proposed changes remain in docs/design/ten-2026-09-27/PLAN.md, CONFLICTS.md and QUESTIONS.md. The approved Club Spread brief includes optional Pro identity editing, not a redesign of competition rules. Root `.impeccable/review/club-spread-final-review.md` has disposition `fix`: original editor fix 3 is resolved and all 40 corrected captures pass evidence validity, while reproduction authority remains open. The owner release-gate decision and separately confirmed production DB/Edge deployment remain owed. A successful production media upload and real Photos permission flow are not established by fixtures.

## Built extension · 2026-09-30

The rules header uses the same compact `LeagueIdentityMark` beside its existing `SeasonRules` title. The rules sentences, member controls, share/leave doors and their producers remain incumbent. Only The Pro receives the League identity door. When identity metadata is unavailable, that door becomes Try league identity again; the existing season still loads. The current `LookRoomSection` continues to carry the optional curated color choice.

`LeagueIdentityEditor` is a native navigation sheet with a Form, segmented Photo/Logo choice, Photos and Files pickers, image removal and an optional description bounded at 160 Unicode scalars. Photos fill; logos fit and retain transparency; media reads are downsampled before upload. No image leaves the stable initial mark in place.

The editor uses the shared `CSField` and its opaque `mut` edge/focus behavior. A quiet trailing Close invokes discard protection when edits exist. The sole confirming Save uses the shared primary style at the body foot, with the error above it and safe-area/keyboard handling. Busy, reading, invalid-length and unchanged states disable Save. Save dismisses the keyboard; failure keeps the draft, error and retry action. These are source observations and passing fixture-flow evidence, not proof of a production save.

Evidence: the named Pro/SE editor and failed-save originals in root `.impeccable/review/capture-manifest.json`, `club-spread-fix1.json`, UI result bundles named there and the final independent review. That review confirms Close/Save hierarchy, opaque field edge and retained failed-save work in the captured scope; it does not certify a live save or the entire Rules page. Existing Rules literal spacing and any historical chrome/type drift are not made into new system tokens by this extension. Root `DESIGN.md`, `.impeccable/design.json`, token source and Profile remain unchanged. See root `.impeccable/review/club-spread-documentation.md` for exact release limits.
