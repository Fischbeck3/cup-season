# Return flows — owner review, 2026-09-12

Branch: `codex/run-it-back-topo-2026-09-12`. Baseline: `246b77a` (phone build 793).
No production deployment, push, archive or TestFlight upload is part of this review.

## Implemented client changes

- Run it back: the Pro confirms before the existing same-league RPC runs. Closing the review writes nothing. Concurrent taps are guarded. Failed member board requests no longer disable Ask; only a recorded successful ask does. No new competition rules or roster behavior.
- Invitations: native and web retain intent until server acceptance; late completion cannot erase a newer code. Native opens the joined league's board after refreshing membership. Closing an unfinished invitation preserves it for a later launch.
- Home plans: headline dates derive from the same local calendar date as the accompanying stamp, rather than the database's UTC-relative prose. Other stories retain server copy.
- Draft recovery: flush existing draft storage before submission, when leaving the composer and when backgrounding. This preserves the existing draft contents; it does not add offline posting, photo retention or server idempotency.
- Icon: contour opacity 0.12 → 0.132, exactly 10% relative. Foreground geometry, palette and placement unchanged. Generated through `tools/build-beta-mark.sh`.
- Shared topo: use existing alpha-24 token instead of alpha-16. Sign-in removes its second opacity reduction and gives contours a stable region beside the crest. No animation was found in the contour primitive; extreme faintness and the small clipped region explain visibility, but runtime review is still required to rule out transient rendering.

## Safe round retry — proposed server contract, not implemented or deployed

The existing `post_round` has no caller request ID. A timeout can occur after commit; repeating it can insert a second factual round. Draft retention and button guards cannot resolve that ambiguity.

Proposed bounded addition:

1. Add `post_round_once` accepting an account-scoped UUID request ID plus the existing post payload. Preserve `post_round` for older clients. No scoring changes.
2. In one transaction, serialize `(auth.uid(), request_id)` and store the exact canonical request and accepted response in a private receipt table. A duplicate with identical payload returns that response; a changed payload under the same key fails. Rollback leaves neither a request receipt nor a round.
3. Call the existing authoritative posting function inside that transaction. Revoke public/anon access; authenticated callers only, with the user ID derived from auth. No client table access. A deleted round must remain tombstoned against this request ID, never be recreated by retry.
4. Before the first request, the client atomically persists the frozen payload, request ID and account ID. All retries/relaunch recovery use that same envelope. Do not expire unresolved submissions with the ordinary 24-hour draft TTL. Retain uploaded photo path and pending hole details without duplicating uploads.
5. Gate the new client path on confirmed server capability. Once a keyed request may have reached the server, never fall back to the unkeyed RPC or direct insert. Preserve the existing path for older deployed servers until rollout is approved.
6. Verify against a local database: simultaneous same-key requests; changed payload; timeout after commit; process restart; account switch; transaction rollback; deleted round; missing RPC; replayed acceptance. Prove one round and one authoritative consequence, not merely one button action.

Owner decision required: approve this new RPC/private receipt table and staged rollout. No schema, grants or production data were changed here. Until then, lost-response retries remain unsafe; check round history before repeating an ambiguous submission. A release must not claim this capability is complete.

## Verification and runtime limits

- XcodeGen and simulator build succeeded. Shared/native/app suite plus signed-out UI review: 1,291 passed, 0 failed, 0 skipped. After the additional retry test and final copy refinements, ReturnFlowTests: 5 passed; final sign-in/home-screen capture test: 1 passed.
- `npm run preflight`: 0 failures, 0 warnings. `git diff --check`: clean.
- Existing browser verifier ran the app function suite at 1440 and 390 widths, with no unexpected console errors or horizontal overflow. It did not perform a live invitation join.
- Actual signed-in SE3 Compete captured in light/dark. Signed-out iPhone 17 Pro Welcome, email sign-in (initial and four-second settled frames), and settled iOS home-screen icon captured. Mark bright-pixel geometry is unchanged between icon variants.
- No real league/season was created and no round was submitted during verification. The real Pro mint and authenticated invitation completion remain end-to-end release checks; unit/source verification is not represented as proof of those production writes.
- Existing Xcode warnings include three unassigned legacy icon asset children and concurrency warnings in older tests. Preflight baselines were not changed.
- Existing draft scope and 24-hour retention remain unchanged. No new claim of offline posting or photo recovery is made.

Review artifacts: `/Users/fischbeck3/cup-season-runback-topo-review/index.html`.

## Changed sources

- `apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/app-icon-dark.png`
- `apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/app-icon-tinted.png`
- `apps/ios/CupSeason/Assets.xcassets/AppIcon.appiconset/app-icon.png`
- `apps/ios/CupSeason/Door/DoorView.swift`
- `apps/ios/CupSeason/Home/HomeLead.swift`
- `apps/ios/CupSeason/Home/HomeView.swift`
- `apps/ios/CupSeason/Home/HomeWire.swift`
- `apps/ios/CupSeason/People/JoinLeagueFlow.swift`
- `apps/ios/CupSeason/Post/PostRoundModel.swift`
- `apps/ios/CupSeason/Post/PostRoundScreen.swift`
- `apps/ios/CupSeason/RootView.swift`
- `apps/ios/CupSeason/Wizard/LeaguelessDoors.swift`
- `apps/ios/Packages/CSDesign/Sources/CSDesign/Brand.swift`
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Home/HomeDispatch.swift`
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/League/RunItBackService.swift`
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/People/JoinLeague.swift`
- `index.html`
- `tools/build-beta-mark.swift`
- `apps/ios/Packages/CupSeasonKit/Tests/CupSeasonKitTests/ReturnFlowTests.swift`
- `apps/ios/CupSeasonUITests/ReturnFlowReviewTests.swift`
- `docs/reviews/2026-09-12-return-flows.md`

## Owner refinement — golf-terrain page theme, 2026-09-12

Supersedes the earlier small sign-in crest region above. `CSTopoField` now draws intentional vector geometry suggesting green surrounds, bunker pockets and approaches. It is abstract brand artwork, not a factual course map. Welcome and every sign-in stage use the page composition behind their existing controls; the background ignores keyboard resizing. Compete uses the same geometry across its masthead rather than inside a small trailing rectangle. Existing share/footer consumers inherit the shared contour geometry; the icon master and its 10% contrast change remain untouched.

Sources touched in this refinement: `Brand.swift`, `DoorView.swift`, `CompeteScreen.swift`, and `ReturnFlowReviewTests.swift`. No auth, scoring, navigation, backend, palette or foreground mark changes.

Visual review removed overlapping lower terrain and extended abrupt approach endpoints. Actual captures cover Welcome/sign-in dark and light, sign-in AX3, and real-account Compete on SE3. The first light UI test used a redundant forced-door overlay; corrected to use the normal signed-out path. Final verification: XcodeGen, simulator build, 122 design/UI tests passed (0 failed/skipped), preflight 0 failures/warnings, diff check clean. This does not claim all possible rendering transitions are flicker-free.

Latest review: `/Users/fischbeck3/cup-season-runback-topo-review/golf-terrain.html`. Changes remain local and uncommitted. No TestFlight, archive, deployment or push.

## Owner refinement — centered sign-in and stronger Compete, 2026-09-12

Supersedes the previous lockup alignment and Compete hierarchy. The email sign-in mark/name now center together, with a stacked fallback for constrained widths. Shared golf terrain uses fewer surrounding paths, retaining green/bunker shapes and open space at the existing contrast. Compete retains its list, ordering and routes while adding a full-width green masthead, stronger season names and rank figures, quiet section labels and the existing primary action style for Start something. No data, mechanics, authentication, navigation or app-icon master changes in this refinement.

Sources: `apps/ios/CupSeason/Door/DoorView.swift`, `apps/ios/CupSeason/Compete/CompeteScreen.swift`, `apps/ios/Packages/CSDesign/Sources/CSDesign/Brand.swift`, `apps/ios/CupSeasonUITests/ReturnFlowReviewTests.swift`, and this review note.

Final verification: 122 CSDesign/sign-in UI tests plus 10 standing/Compete UI tests passed, 0 failures/skips. Simulator build succeeded; preflight 0 failures/warnings; diff check clean. The initial Compete test queried a container identifier as a button; corrected the test to tap the actual child button, without changing product behavior. Actual signed-in SE3 screenshots cover dark/light and AX3. Existing season navigation and creation chooser were opened without creating data. Sign-in dark/light and AX3 screenshots confirm centered identity and preserved controls.

Visual compromise: stronger season names occupy more vertical space; on SE3 the moments section begins below the initial viewport. Accessibility sizes intentionally stack rows and scroll. Shared topo consumers inherit the simplified artwork; no claim is made that every possible transition is flicker-free. Existing legacy icon asset warnings remain.

Latest before/after review: `/Users/fischbeck3/cup-season-compete-review/index.html`. All changes remain local and uncommitted. Phone build 793 is unchanged. No archive, TestFlight, deployment or push.

## Loading and Play footer — owner refinement, 2026-09-12

`RootView.swift` / `BootingView` now uses the same `CSTopoField(.page)` background as sign-in, full-frame with matching ground, scale and contrast, rather than a 100×60 patch behind the lockup. The lockup centers; the named loading step and state transition remain unchanged. `CSBrandSignature` gains a default-preserving `showsTopo` option; only Play (`PostCoverView.swift`) opts out. Its larger Start something terrain band remains unchanged.

Verification: simulator build and 120 CSDesign tests passed, 0 failed/skipped; preflight 0 failures/warnings; diff check clean. Actual session-restoration video confirms the loading view and successful arrival; Play screenshot confirms the bare footer mark. No new auth behavior, backend change, icon generation or release. Review images: `/Users/fischbeck3/cup-season-compete-review/loading-page-topo.png` and `/Users/fischbeck3/cup-season-compete-review/play-clean-footer.png`.
