# Home Scorebook · full matte

The owner selected C / Scorebook, suggested gold, silver and bronze performance panels, then authorized “GO on full matte.” This implements that direction on native and web Home. It is locally built and committed; no push, merge, TestFlight upload or production deployment belongs to this refinement yet.

## Behavior and governing decision

D404 in `spec/decision-log.md` records the scope and the narrow exception to D269's two-metal rule and the one-gold-object viewport budget. The brand canon and UI system carry that amendment. The source token file owns four fixed score-object paints; generated outputs come from `node tools/build-tokens.mjs`.

Each round reads golfer/date, course and tee with its existing story beside a compact gross panel, optional photo, then the existing supporting actions. The previous spaced page rules close the round. Recorded finite performance picks gold at >= +1, silver between -1 and +1 exclusively, bronze at <= -1. Missing/nonfinite performance stays neutral. Existing five scoring bands and points are unchanged. The actual performance phrase remains in the accessible round name when a milestone or counting story takes the visible story line.

The fixed paints work in both themes and remain fixed across personal looks and Increase Contrast. They are result content inside the receipt target. Neutral results use the ordinary second ground. Native large text stacks the details and panel and lets the panel grow naturally. Photo, profile, receipt, applause, comment and course targets keep their existing actions; the profile target now includes the golfer's name. Profile's layout and photo-first avatar behavior remain unchanged.

## Verification and bounded visual review

All final evidence is in `.impeccable/review/home-scorebook/`. `manifest.json` retains original dimensions, SHA-256, device IDs and capture provenance. Screens are synthetic DEBUG/QA records rendered by the production components, not production writes or claims about real golf.

| Check | Outcome |
| --- | --- |
| `npm run preflight` | PASS, 0 failures / 0 warnings |
| `git diff --check` | PASS |
| XcodeGen and final `xcodebuild build-for-testing` | PASS; `scorebook-build-recovered.log` |
| iPhone 17 Pro, iOS 26.5 | 6 tests passed: 3 UI methods, 2 band-edge/unknown-data tests, 1 all-palette contrast/fixed-paint test |
| iPhone SE 3, iOS 26.5 | 2 UI methods passed; confirmed result summary and 8 screenshots |
| Browser, 1280px and 375px, both themes | PASS; 12 band-edge cases, actual paints, neutral data, 9-hole unit, long course, photo decode; zero console errors or horizontal overflow |
| Layout detector | 9 inherited web findings, zero new findings against the prior baseline; no native findings |

Viewed all 12 Pro, 8 SE and 4 final web screenshots. The native paths cover photo, no photo, failed image, missing gross, long course names, supporting actions, receipt opening, independent profile targets and accessibility-size reflow. Contrast is calculated across every palette rather than inferred from screenshots. This is simulator and browser verification, not a physical-phone or human VoiceOver certification.

The initial web capture raced image painting. The confirmation waited for image decode and two animation frames, then showed the photo correctly without a production edit. Native source produced one failed build while disk space was very low; after removing only unused generated caches from this task's previous builds, the final build passed. The first SE run logged two passing tests but produced an empty result summary and no exportable screenshots. It was not accepted as capture evidence. A serial confirmation on the same source passed both tests and retained all eight frames. Existing Supabase session runtime warnings are recorded in the result summaries; this refinement does not change authentication.

Visual work stopped after the batched native review and the web confirmation. No further design edits followed the final build. `DESIGN.md` is an older compiled record; the amended canonical UI system, brand canon and D404 govern this change. It was not regenerated as an unrelated context repair.

## Files and handoff

- Native: `HomeWire.swift`, shared `CSScorePanel`, `Theme.swift`, `CSBands.swift`, DEBUG fixture and two focused test suites.
- Web: `index.html` Home feed renderer and scoped CSS.
- Tokens: source JSON and its generated CSS, TypeScript and Swift outputs.
- Canon: D404, brand canon and UI system amendment.
- Guard: LINT-10 recognizes only the named token-based Home figure panel, with its dimensions and no border. No broad lint suppression or baseline increase.
- Evidence: original captures, provenance manifest, final build/preflight/browser/test logs and summaries.

Branch: `codex/home-round-boundaries-2026-09-30`

Goal: Distinct Home round records with the approved full matte Scorebook treatment.

What changed: Compact performance score panels, unified photo/text record structure and existing spaced rules.

Files changed: Home, CSDesign, band presentation, tokens, canonical records, focused verification and evidence listed above.

Verification run: Preflight, build, 6 Pro tests, 2 SE tests, browser matrix, contrast, visual review and diff check passed.

Database deploy owed: None.

Edge deploy owed: None.

Client deploy owed: Web push/merge and native archive/TestFlight release remain outstanding.

Open questions / risks: No known blocker in the approved scope; runtime warning and simulator-only limits above. Existing unrelated detector findings remain.

Recommended next step: Review the captured Home screens, then release the owned branch when shipping is requested.
