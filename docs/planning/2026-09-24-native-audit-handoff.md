# Native audit repairs — local build handoff

Branch: `codex/native-audit-repairs-2026-09-24`

Workspace: `/private/tmp/cup-season-native-audit`, based on fetched `origin/main` at `32fc9413`. The original dirty design checkout and Claude's repair worktree were preserved.

Goal: implement Codex's native portion of the launch-audit recommendations while preserving the approved Scoreboard and Book design. The owner authorized implementation with “Prompt claude to build what they own and build what you own.”

## What changed

- Imported Claude's native claim-link handoff, boot foreground retry, short-season/solo-floor agreement fixes, figure-run receipt text, and crown-aware per-season record parser. Preserved main's explicit `tied` field and separated a record row's season identity from the league it opens. Future first tees have no invented placement.
- Completed tables put the stored champion/runner-up first, preserve ties among the remaining points ranks, remove live cuts, movement, gaps, counting clauses and chase language, and keep the Book door. Cup Final rails show race position; qualification seed is explicitly labelled in the clause. The existing board component can omit its empty Gap header.
- Squad receipts read the validated Book's squad/contribution entries. They no longer add individual totals, which would include pre-seat rounds, or count a ruling twice. Withdrawn Book entries keep their contribution/explanation and remove the private round door.
- Season-two membership accepts the additive `in_season` and `renewal_status` fields. Pending opens the covenant directly; accepted opens the season; expired/declined are excluded from live rows. Season pages refresh with a new Home payload and when reopened.
- Added unseated-player actions to the Pro's roster, excluding departed/suspended/non-accepted members, plus a conditional season-page door.
- Added saved live-round recovery at a failed boot, filtered by the authenticated account, snapshot age and pending abandonment. It opens the original round and durable queue, preserves strokes/clocks and cached identity, and labels unsynced state. It does not create an offline replacement round. Reconnect uses the existing sync/reconcile path.
- Handle derivation now stops only after a user edit. Added guest orientation, a YOU row, named score values and a sign-in alternative. Kept join-with-code available without existing buddies and added it to Play. Suppressed LAST when the first wire round (after any digest) is that same round. Home's Cup Final fallback no longer calls the regular-season leader the one to catch.
- Covenant copy reads the actual structure, excludes solo floor language, explains the two-squad head start, separates a points-table ending, defines Points King and omits zero-percent awards. The fixed money sentence remains unchanged.
- Native sharing now prepares an owned attempt with explicit consent and acknowledges actual OS completion/cancellation. Reused completed links survive cancellation. New attempts are cleaned by the backend contract; completed acknowledgements persist per owner for retry. Public-copy cleanup errors propagate and remain actionable. The receipt has a labelled off/retry control; it never mints merely to revoke. Missing preparation RPCs fall back to sharing the card alone with an explicit link error.

## Claude's implementation prompt

Use [the Claude prompt](2026-09-24-claude-audit-integration-prompt.md), which assigns the database, web, backend tests, migration collisions and decision-ID reconciliation. The precise additive native contract is [here](2026-09-24-native-audit-contract.md). These are prepared instructions for the owner to paste into Claude; this task did not dispatch a Claude session.

Claude's existing D383/D384 decisions govern short-season agreement and withdrawal; the native branch imports their client halves. Claude must carry those decisions and the owner's acceptance of per-season trophies into the integrated decision log, preserving the already-applied Book decision and resolving duplicate D381 IDs. No new competition scoring algorithm was introduced in native.

## Files changed

Native app surfaces: `CompeteScreen`, `CupSeasonApp`, `RootView`, `HomeView`, `MembersSheet`, `ReceiptSheets`, `StandingsTableView`, `CupFinalRaceView`, live host/store/play/activity, `MainTabView`, `CardGateView`, Play/share preview, round receipt/moment, season/Book pages and You/Record routing.

Native packages: board header option in CSDesign; Kit competition/season/member models, `FinalTable`, record parser/repository, wizard agreement, covenant, Home copy, Book entry decoding, live rehydration/session, round/photo withdrawal, share service/attempt acknowledgements and SessionStore retry.

Contract: `packages/db/contract.psv`; regenerated `packages/db/rpc.ts` and native `Generated/Rpc.swift` with `node tools/build-db.mjs`. Generated output was not hand-edited. No SQL, web client, production asset, dependency or deployed version was changed.

Tests: existing covenant/empty-root expectations updated for authorized behavior; imported league setup/photo/record tests; new `NativeAuditRepairTests` and future-first-tee record regression.

## Verification run

- XcodeGen generation succeeded.
- Simulator build and full selected test run succeeded on task-owned iPhone 17 Pro, iOS 26.5: 30 app XCTest tests + 100 app Swift Testing tests, 16 Kit XCTest tests + 1,260 Kit Swift Testing tests, and four existing Book UI tests. That is 1,410 passing tests at the full-suite checkpoint. Log: `/private/tmp/cs-native-audit-final-tests.log`; result bundle: `/private/tmp/cs-native-audit-build/Logs/Test/Test-CupSeason-2026.09.24_20-25-58--0700.xcresult`.
- After adding the final cleanup-failure and pre-season-placement regressions: 13 focused tests in the two repair suites passed (`/private/tmp/cs-native-audit-regression-tests.log`). They verify revocation failure stops cleanup, Storage failure is not reported as success, both public copies are retried, cross-account/stale/abandoned cards cannot resume, the original queue survives, changed-consent responses are rejected, renewal routing and final crown/tie behavior.
- The full Xcode run initially lingered collecting optional simulator diagnostics after all tests passed. Only its task-owned diagnostic child was stopped; Xcode then exited 0 with `TEST SUCCEEDED`. The focused run used `-collect-test-diagnostics never` and exited normally. The earlier superseded run's two failures were obsolete copy/door expectations, corrected before the passing full run.
- Book UI tests passed real matrix horizontal scrolling/name freezing, receipt opening, equal points ties/compact presentation, root-to-Book navigation, accessibility week picker and Race selection.
- Final app build after the closed-table header correction succeeded (`/private/tmp/cs-native-audit-final-build.log`).
- Final completed-season fixture checked visually; screenshot in `/private/tmp/cs-native-audit-evidence/completed-season.png`. This is synthetic local data, not production verification. The check caught and removed an empty Gap header and the word “playing” on the closed table.
- `npm ci --offline` installed the existing development lockfile; no dependency changes. `npm run preflight` has **one expected integration failure and zero warnings**: native RPC grants for `prepare_round_share`, `finish_round_share`, `round_share_status`, `withdraw_round_shares`, `my_league_record` are absent from this native-only migration tree. Every other check passes. The unchanged `origin/main` design worktree passed preflight for comparison.
- `git diff --check` passes.

## Deployments owed and remaining gates

Database deploy owed: Claude's reviewed/integrated migrations and server share lifecycle/cleanup, after the full combined local migration and failure tests. **Not authorized or performed here.**

Edge deploy owed: whatever Claude's durable Storage cleanup implementation requires; not assumed deployed and not performed here.

Client deploy owed: integrated web deployment and a separately approved native distribution. This native branch is local only; no push, merge, TestFlight or App Store submission.

Open questions / risks: do not release this branch alone. Backend share leases, cleanup execution/status, old-client mutation coverage and cross-device concurrency need integration proof. `renewal_status`, withdrawn Book provenance and season-number trophy subtitles need Claude's producer changes. Finalized-season immutability and squad eligibility remain server responsibilities. A physical two-phone/offline-interruption run and an actual share-sheet delivery/cancel/Storage-failure run remain release gates; local model/queue tests are not that evidence.

Recommended next step: give Claude the prompt and contract; integrate the two local branches in a separate worktree, regenerate the union contract, apply/test the complete migration sequence locally, and require green preflight before any deployment request.
