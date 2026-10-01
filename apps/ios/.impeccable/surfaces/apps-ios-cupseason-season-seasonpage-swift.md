---
version: 1
slug: "apps-ios-cupseason-season-seasonpage-swift"
primary_target: "apps/ios/CupSeason/Season/SeasonPage.swift"
related_targets:
  - "apps/ios/CupSeason/League/LeagueIdentityViews.swift"
  - "apps/ios/CupSeason/Compete/CompeteScreen.swift"
---

# season · ios

Mode: **Operate**. This compiled existing-world brief includes the owner-approved D400 shared league-identity extension. It does not authorize a whole-season redesign.

## Scope and task

Season is narrative: where this competition stands, why, and the path from totals to rounds.

Surfaces: season, leaderboard, season-story, pot. Target: `apps/ios/CupSeason/Season/SeasonPage.swift`. Sibling: `index.html#view-season`.

## Character and constraints

Source: BRIEF §§29/31/33/35, UI_SYSTEM including amendments, PRODUCT.md and D234/D358–D396/D400. Inherit the token system; custom tab band and three-voice type are existing canon. Phone and desk keep their own shape. Preserve the five destinations, literal money sentence, traceable points, consent and factual rounds.

## Proof and states

Only existing, demonstrably synthetic fixtures or data-free states are evidence. Check both themes and the specified client matrix. Missing safe fixture: not captured, not scored. A screenshot cannot certify VoiceOver, hardware haptics, keyboard behavior or an unassisted task. No photos/faces/customer claims are invented to improve scores.

## Unresolved

Historical capture gaps, content ceilings and proposed changes remain in docs/design/ten-2026-09-27/PLAN.md, CONFLICTS.md and QUESTIONS.md. The approved Club Spread comp governs the shared identity extension only; no whole-season composition is newly approved. Root `.impeccable/review/club-spread-final-review.md` has disposition `fix`: corrected capture validity and the bounded native geometry/editor repairs are confirmed, while reproduction authority remains open. It reviews this shared heading as an extension, not the whole season-state set. The owner release-gate decision and separate production deployment confirmation remain owed. Screenshots do not establish a successful live upload, hardware interaction or full VoiceOver use.

## Built extension · 2026-09-30

`SeasonHead` now uses `LeagueIdentityHeading`: the same private photo/logo/initial fallback as Compete in a compact neutral badge, beside the existing `displayS` league title. `A11yStack` reflows that pairing for accessibility sizes. The optional saved description sits below it in `bodyS`/opaque `mut` and grows vertically. The heading is identity, not a new live or earned signal.

`SeasonBoardCopy`, the season story, dateline, closer sentence, table, receipts and Book retain their existing producers and routes. The extension does not change rankings, points, rounds or personal appearance. Image failure leaves the compact initial mark usable. Root `DESIGN.md`, `.impeccable/design.json` and token values remain incumbent.

Evidence: the Pro and SE `club-spread-season-header.png` originals in root `.impeccable/review/capture-manifest.json`, the source in `LeagueIdentityViews.swift`, and the final independent review. The final 40-file manifest matches hashes/dimensions and passes the review's evidence check. This is a header check, not a fresh audit of all SeasonPage states. The earlier finish/recapture records remain history. See root `.impeccable/review/club-spread-documentation.md` for exact review status and hardware limits.
