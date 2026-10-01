# Home round boundaries · September 30, 2026

Owner feedback: “From my home, think we need some stylistic division between posted rounds, they all blend together.” Refinement within the existing almanac world, using Impeccable's layout playbook. No replacement design system or competition change.

The photograph's edge was treated as a separator, although the action row continued beneath it. That left the next golfer visually attached to the preceding record. The reading path remains golfer/result → course/story → optional photo → actions. A spaced page rule separates that complete group from the next record, with the same treatment for photo and text-only rounds.

Native uses the existing `CSRule`, page gutter, `s3` above the rule and `s2` below it. The next record retains its existing internal padding. Section headings remain their own boundaries, and unrelated non-round spacing stays unchanged. Web closes each Home round with the token hairline, `s3` padding and `s4` margin, suppressing the following round's redundant top rule. Its desktop column and phone layout remain distinct from native.

Governing sources: `packages/tokens/tokens.json`, `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md` §§3/10/12, `DESIGN_SYSTEM.md`, Home's native/web surface briefs, D234 and the existing Home layout decisions. The current repository's D358/D359 role amendments govern token meanings; the older roles in the pasted AGENTS instructions do not change them. This patch uses only the neutral page rule and spacing.

## Verification and limits

- Final `npm run preflight`: PASS, zero failures/warnings.
- Native simulator build-for-testing: PASS. The first test invocation failed because the XCTest runner did not receive the external synthetic photo path; it is not accepted photo evidence. Corrected runs supply the path through the generated `.xctestrun` configuration.
- Corrected native walkthroughs: two tests per device, zero failures, 16 original captures inspected. iPhone 17 Pro and SE 3, iOS 26.5; photo/no-photo/failure in dark/light and AX3 in dark. Photos and long labels stay inside the gutter; comments/course retain distinct 44pt controls; boundaries remain visible beneath the actions at AX3.
- Browser harness: four captures, 1280/375 CSS pixels, dark/light. Two photo rounds followed by two text-only rounds; computed boundaries verified, clean console and no horizontal overflow. Service workers/caches cleared and bypassed. Existing synthetic photography only.
- Layout detector: native zero findings; web nine findings identical to baseline, zero new. Existing reports concern unrelated segmented controls, posting footer and purse markup; no changed boundary selector appears in them.
- Source review: facts, ranking, photo loading/failure behavior, rounds, social actions, target sizes and accessibility order remain unchanged. The new native rule is hidden from VoiceOver.
- Simulator captures do not certify physical-device interaction or human VoiceOver use. No new fonts, colors, generated artifacts, dependencies, SQL or Edge changes.

Evidence: `.impeccable/review/home-round-boundaries/manifest.json` links 16 native and four web originals with dimensions and SHA-256. All were visually inspected; no further UI correction was needed.

## Handoff

Branch: `codex/home-round-boundaries-2026-09-30`, based on merged `b3f09975`.
Goal: make individual posted rounds visually distinct on Home.
What changed: neutral page rules and deliberate whitespace between complete round records.
Files changed: `apps/ios/CupSeason/Home/HomeView.swift`, `index.html`, this note and scoped review evidence.
Verification run: preflight, existing native walkthroughs, browser captures/computed styles, layout detector baseline comparison, diff review.
Database deploy owed: none.
Edge deploy owed: none.
Client deploy owed: this branch is local; web/native release remains pending.
Open questions / risks: visual treatment awaits owner feedback; source and simulator proof cover this narrow layout change.
Recommended next step: review the native preview, then ship the refinement when requested.
