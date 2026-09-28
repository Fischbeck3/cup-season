# S1a · persistent Email name

Approved by the owner’s “Build recommended.” Branch `codex/ten-door-label-2026-09-28` starts at release candidate `5fabf861`. This is a local review commit; no shipping action is authorized.

## Change

Web `index.html` gives `#obEmailIn` a real persistent Email label. A scoped two-column grid holds the label above the existing input and Go action; opaque `mut` follows current canon. Native `DoorView.swift` keeps its existing visible label and adds `.accessibilityLabel("Email")` after the same unnamed-field defect was reproduced with XCTest. Email metadata, code-only authentication and all handlers stay unchanged. No token, generated file, backend or copy-producer change.

Impeccable sequence: craft floor → harden → polish → independent A/B family critique. Both clients were examined. Native Home’s correct source pairing is also recorded with S1b.

## Evidence and verification

- [Before/after manifest](manifest.json): eight representative synthetic/empty images with SHA256 and exact source hashes. Native before/after screenshots look the same; the change is semantic and the runtime record is the proof.
- [Web results](web-verification.json): 375/402/1280/1600 × dark/light. Label appears on initial entry; clicking it focuses the field, and it survives typed synthetic text. 375/402 × both themes also pass the 380px-height action-reachability proxy. This does not replace an iPhone Safari keyboard test.
- Existing `brand-door-browser.js`: six matrix cells pass. Both 1600px cells fail the pre-existing “terrain is not at page scale” assertion. The same failure reproduces on 5fabf861 before the patch: the 900px terrain cap falls below the test’s 60% of 1600px threshold. No test was weakened.
- [Native accessibility](native-accessibility.json): baseline empty labels reproduced in five observed combinations; final exact Email label before/after typing passes all eight SE3/17 Pro × dark/light × default/AX3 combinations. Four actual XCTest executions, two themes each, all pass. Final empty-state screenshots have keyboard visible and status bar 9:41.
- [Executed native harness](ExecutedDoorVerification.swift) is retained for reproduction, outside the production test target. Existing DEBUG synthetic/offline hatches only; no address submitted or real account used.
- Build-for-testing passes. Affected Door/token suites pass. Final three non-UI targets: [1,574 tests, 1,573 passed, one failed, zero skipped](native-test-summary.json). The unchanged keychain migration test fails with -34018 (`errSecMissingEntitlement`) in the unsigned simulator host. Full authenticated UI suites require signed-in/keychain state and were not run under the synthetic-only constraint.
- [Final preflight](preflight.txt): **0 failures, 0 warnings**. Existing installed dependencies were read through a temporary symlink; no installation or dependency change.

## Limits and critique

The browser console is not clean: existing Supabase lock deprecation and harness service-worker blocking messages remain. No uncaught page exception was observed. The full native suite and physical-device/human gates are not cleared. This commit is ready to review, not declared release-ready.

[Web critique](web-door-critique.md): 21/28 observed points, residual P2 Back target/contrast and unclear Go action. [Native critique](native-door-critique.md): 24/28 observed, no verified priority issue in the entry sample. Different observed heuristic sets make these unsuitable for a direct percentage trend or a 36/40 claim. Web backlog stays open; native’s inspected empty backlog is closed by polish. Broader baseline debt remains in the program plan.

No P0/P1 was found in the fresh bounded review after the repairs. Other program families remain unverified or have deferred P1s. No authentication, recovery, VoiceOver journey or human task pass is implied.

Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none.
