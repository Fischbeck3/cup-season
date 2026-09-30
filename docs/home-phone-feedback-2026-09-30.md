# Home — owner phone feedback

Branch: `codex/almanac-home-compete-2026-09-30` in `/private/tmp/cup-season-match-programme-release`, based on the shipped Match Programme source `e8e9f84b`.

Goal: correct the Home round's clunky composition exposed by the owner's real phone screenshot. The Almanac pivot remains paused. Profile and Compete are outside this correction.

What changed: the golfer leads a full-width identity row beside a compact trailing gross figure. Course, tee and supported story each have the full measure. An available photograph appears in a 16:9 landscape insert beneath the record. D361 retains a last-good image through transient failure; if no image is available, the complete record reserves no photo space. Supporting applause, comments and Course share one line at reading sizes and reflow at accessibility sizes. Home period headings use the existing quieter label treatment and token spacing; headless single-item periods keep their existing behavior.

Files changed: native Home `HomeWire.swift` and `HomeView.swift`; DEBUG `MatchProgrammeFixture.swift`; `MatchProgrammeTests.swift`; the direction amendment and this handoff. No shared type/token/Profile changes.

Verification run: final `npm run preflight` passes with zero failures and warnings, the corrected test build succeeds, and `git diff --check` passes. All seven focused `MatchProgrammeTests` pass on both iPhone 17 Pro and iPhone SE (3rd generation), zero failures: 14 test executions across the two devices. The final photo-loaded, absent, failed and missing-data receipt checks pass on both phones; the long-course/support matrix covers both themes and AX3. Parent and independent reviewer opened all 22 required final Home captures. The review marks all five scored corrections resolved. Diagnostic runs exposed missing test-runner photo input, floating-point target assertions and an oversized photo hit region; all are corrected in the final passing source. Production targets remain 44pt; assertions allow only a 0.000001pt transform epsilon. These passes establish local fixture layout/navigation, not hardware or live-account acceptance.

Database deploy owed: none.

Edge deploy owed: none.

Client deploy owed: approved Owner TestFlight release pending archive/upload/readback. The owner reviewed the simulator and authorized shipment with “ship it.” Build 2020 is planned from the next source commit. Existing TestFlight 2019 remains the prior layout until the new build is confirmed available. No main merge, web, database or Edge deployment is part of this native release.

Open questions / risks: owner approved shipment after the simulator review; simulator fixtures cannot certify real-account writes, hardware behavior or live photo consent. Complete course/tee/story data stays visible and spoken; no line limits or smaller factual-text roles hide the content.

Recommended next step: archive the committed revision, upload build 2020, add it to internal Owner TestFlight and verify availability. D372 keeps Friends behind the complete owner checklist on that build.

## Acceptance and evidence

Primary evidence is the owner's actual phone screenshot `12CDED23-8FEC-41FE-A96F-ED8DB4DD1C79.png`, supplied September 30. It exposes the narrow course column and extra supporting rows that short synthetic Papago records missed. A fresh independent review returned **fix** with five material items: compact identity/result, full-width separated facts, landscape photography, grouped support, quieter Home periods. The prior Match Programme board is critique-reference only; no new concept is asserted approved.

The new DEBUG `phone`, `phone_no_photo`, and `phone_failed` cases include a marked QA golfer, gross 79, a long Kaanapali-like course/tee, a supported handicap story, comments and a course link. Data is synthetic and not written. Fixtures suppress reaction writes even if launched over a signed-in session. Loaded photo uses the existing local QA picture; no new image ships. Actual-user photography is not copied into app assets.

The production path retains D361's per-attachment last-good image cache, existing person/receipt/comment/course destinations, exact copy producers and supplied points/counting story. Ordinary action and competition colors follow D359 and the live Home cue follows Q36. No native detector applies to SwiftUI.

## Source documentation check

The correction reuses incumbent roles: `social` for the golfer, `CSFigure.l` instead of the earlier `.xl` gross, `agateS` for the existing day and hole-aware gross unit, and `bodyS` for the club, tee and supported story. `courseTitle` splits the existing course label at its last tee separator; `roundStory` selects the supplied counting consequence or existing factual round detail. It adds no new read or factual copy. Text expands vertically without line limits. The identity/result and support use existing accessibility reflow. The round control speaks the full producer-derived record once; the adjacent visible facts and photograph retain the same receipt action and are hidden from VoiceOver to avoid duplicate stops. The separate golfer-card target remains available.

The photo control owns a bounded 16:9 rectangular hit region. Its scale-to-fill image is a clipped overlay with hit testing disabled, so the image's uncropped extent cannot cover the identity or other controls above it. This is a touch-region correction within the documented landscape composition.

Evidence checked: current `HomeWire.swift`, `HomeView.swift`, `MatchProgrammeFixture.swift`, `MatchProgrammeTests.swift` and shared `HomeWireCopy.swift`; root and native `PRODUCT.md`; generated root `DESIGN.md`, `.impeccable/design.json` and canonical tokens. This source check is complemented by the final capture verdict below. Root product/design artifacts, generated outputs, the shared visual system, Profile and Compete are preserved. Impeccable context reports inherited orphaned surface-brief paths; resolving those paths is outside this correction.


## Final evidence — September 30

- Pro: `/private/tmp/cup-season-home-feedback-pro-crop.xcresult`, seven tests passed, zero failures.
- SE: `/private/tmp/cup-season-home-feedback-se-crop.xcresult`, seven tests passed, zero failures.
- Test build: `/private/tmp/cup-season-home-feedback-build-crop-final.log`.
- Preflight: `/private/tmp/cup-season-home-feedback-preflight-final.log`, zero failures/warnings.
- Unaltered native captures: `/private/tmp/cup-season-home-feedback-review/phone-pro/` and `/private/tmp/cup-season-home-feedback-review/phone-se/`.
- Eleven required Home captures per phone: loaded/absent/failed long-course examples in both themes, AX3 record/support, dark/light first viewport and long-name AX3 record.

The independent `phone_feedback_review` verdict is **ship within the five scored fixes**, with all resolved: compact identity/result; full-width separated facts; bounded landscape photography with collapsed unavailable states; grouped support with accessibility reflow; quiet Home periods. It opened all 22 required captures and found no material regression within that pass. This is not whole-app certification or owner acceptance. Profile, Compete and shared tokens are outside its scope.

The task-owned Pro simulator is open on the corrected DEBUG `phone` example at normal reading size, dark appearance. The owner subsequently authorized shipment. This handoff records the approved source and simulator evidence; the archive and final distribution readback will be recorded in a separate post-release handoff so the uploaded build remains traceable to its exact source commit.
