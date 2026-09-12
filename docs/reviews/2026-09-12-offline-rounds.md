# Offline trip scorekeeping — 2026-09-12

Owner authorized prioritizing three live-scored rounds with no internet and posting after reconnecting. Bajamar Oceanfront Golf Resort; White, Blue or Black tees; own-round scoring only.

## Contract

An explicit “Score on this phone” option uses the existing live scorecard in Just score mode. It does not start a server live round, sync group phones, vouch for other golfers, settle games or post automatically. Existing online mechanics are unchanged. Local UUIDs never enter server live-round endpoints. Each atomic account-owned file keeps the tee, pars, strokes, original calendar day, and completed state across restarts without a 24-hour expiry. The retained scorecards appear in Play for review and posting through the existing composer. No other golfer’s scores post from this path.

Previously authenticated identity and course books support the boot-failed offline door. Sign-out still requires signing back in through normal authentication. Actual pars must be downloaded or manually entered; unknown ratings/slopes must be resolved before posting.

Idempotent posting is a separate, undeployed server requirement. A new keyed request must never fall back to the unkeyed post function. No readiness claim until failure/relaunch tests and the deployment boundary are reported.

## Delivered for review

Scope confirmed: the owner will score only their own round at Bajamar, with White, Blue or Black tees. The existing live scorecard now has an explicit local mode, account-owned atomic storage, immediate persistence after score entry, restart recovery, multiple retained completed cards, and the existing review composer. Original dates and nine/eighteen-hole distinctions survive recovery. Nothing posts automatically.

The retained-card composer freezes its request and payload before sending. It reuses that identity after an interrupted response or restart and fails closed if the new server function is unavailable. Acceptance is recorded before deleting the local card. The migration wraps the existing authoritative posting function and hole inserts in one transaction; it does not change scoring or competition windows.

Actual simulator QA found and fixed two presentation/runtime defects: delayed scorecard rows could read emptied state after completion, and the confirmation toast could expand across the viewport. Completed state now remains safe during dismissal, and the toast sizes to its content.

## Bajamar preparation

Through the signed-in app's normal picker, the simulator downloaded all nine supplied tee variants with 18 holes each. Men's Black: rating 75.4, slope 137; Blue: 72.2/130; White: 69.8/124. These are the app's returned values, not newly invented course data. Confirm current resort tees before play. The phone has not yet been prepared.

Saved evidence and screenshots: `/Users/fischbeck3/cup-season-offline-review/index.html` and `bajamar-saved-course-book.json` in that directory.

## Verification

- Full native/app run: 1,303 passed, zero failed/skipped (`/tmp/cup-season-offline-full.xcresult`).
- After toast correction: 123 design/UI checks passed (`/tmp/cup-season-offline-final-ui.xcresult`).
- Store tests exercise three complete eighteen-hole rounds, restart at the turn, account isolation, storage errors, original dates, nine-hole cards, and frozen posting recovery.
- Actual UI checks cover a restored real account with requests failing, cached course preparation, and fixture score/relaunch/completion. Fixtures never post production rounds.
- Disposable local PostgreSQL tests cover concurrent duplicate requests, lost responses, changed payload rejection, rollback, account isolation, private grants, incomplete holes, and deletion tombstones. The existing scoring engine is stubbed for these wrapper tests; this is not deployed integration verification.
- XcodeGen succeeded; unsigned Release compilation succeeded. No archive was produced. Existing compiler warnings remain.
- Archive-script failure tests use fake build tools. They verify failures cannot reuse a stale archive/export.
- Preflight: zero failures/warnings; diff whitespace check clean. No baselines changed.

## Files and responsibility

- `LiveRoundStore`, `LiveSetupView`, `LivePlayView`, `LiveFinishViews`, `LiveRoundHost`, `RootView`: offline entry, own-round workflow, recovery and truthful state.
- `OfflineRounds`, `LiveModels`, `LiveCopy`, `KeptCard`: account-owned persistence and retained-card data.
- `CourseBookStore`, `LiveRepository`, `SessionStore`: complete tee preparation and restored golfer identity.
- `OfflinePost`, `PostCard`, `PostRoundModel`, `PostRoundScreen`, `PostCoverView`: frozen retry identity, accepted result handling and retained-card review.
- `SupabaseService`: DEBUG-only disconnected transport for simulator QA.
- `CSDesign/Toast`: bounded confirmation presentation.
- `RunItBackService`: require accepted season identifier before success.
- `tools/ios-archive.sh`: fresh output and failure handling.
- New native/app/UI test files and `tests/offline-post-database.py`, `tests/ios-archive-safety.py`: verification.
- `supabase/migrations/20261021090000_idempotent_phone_rounds.sql`: proposed, locally tested, **not deployed**.

Earlier run-it-back, invitation/date, sign-in, loading, Compete and generated icon changes remain in the working tree. The untracked visual implementation pack was left untouched.

## Release boundary and next steps

Branch: `codex/run-it-back-topo-2026-09-12`. Baseline commit: `246b77af61e1bedf7ebefd34e0ab9936104306d4`. Changes are uncommitted. No push, merge, production deployment, physical-phone install, archive or TestFlight upload.

Owner review is required before deploying the posting safeguard and installing this build on the phone. After installation, prepare Bajamar online and verify airplane-mode start, scores, force-close/reopen, completion, and a second local round on that physical device. Verify actual accepted posting after deployment using a permitted test account/environment before calling the trip flow ready.

## Remaining limits

- Ordinary manually composed posts still use the established unkeyed path. Extending retry protection there is a follow-up.
- An ambiguous keyed request remains frozen until confirmation; editing it must not create a second posting identity.
- Offline group sync, settlement, vouching, automatic posting and signed-out authentication are outside this slice.
- Current server competition deadlines still apply when the golfer reconnects.
- Physical-device airplane mode and deployed end-to-end acceptance remain unverified.
- Real invite acceptance and run-it-back concurrency integration remain follow-ups from the broader readiness audit.

Final complete eighteen-hole UI check passed, including process restart after nine holes and retained completion (`/tmp/cup-season-offline-complete18-verified.xcresult`). Screenshots in the review show one isolated, complete fixture card. Final preflight again returned zero failures/warnings.
