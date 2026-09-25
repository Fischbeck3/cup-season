# Combined audit candidate · September 24, 2026

Branch: `codex/audit-integrated-2026-09-24`

Goal: integrate Claude's audit repairs with Codex's native repairs while preserving the shipped Scoreboard, continuous topo and Book design.

## What is combined

- Base: `origin/main` at `32fc9413` (remote fetched before integration).
- Native: `a1ae1be8`, `codex/native-audit-repairs-2026-09-24`.
- Database/web: `8cec0891`, `claude/audit-integration-2026-09-24`.
- Neither source workspace was edited. The original checkout's existing dirty design work remains untouched.
- The only merge conflicts were the shared RPC source and generated outputs. Claude's source is the superset; `node tools/build-db.mjs` regenerated both clients from it.

## Integration findings fixed

| Finding | Resolution |
|---|---|
| The new SQL Book returned version 2; both deployed readers accept only version 1. Every Book and native squad receipt would fail. | `20261205090000` keeps version 1 with the additive frozen/withdrawn fields and corrected eligibility. Real combined SQL payloads now pass both client validators. |
| The cleanup worker prepended the webhook's token, bypassing its due time. Its own error UPDATE could trigger another immediate retry. A webhook cannot wake itself at a future lease expiry. | Worker reads only the due queue; expiry errors return 500. An every-minute schedule is a required deployment step; `tools/share-cleanup-schedule.sql` configures the named job using private Vault values. |
| Native Storage removal did not confirm the server's cleanup row, so a successful response could leave pending status or conceal remaining bytes. | Each token requires server confirmation of `completed` and `remaining:0`; failure stays retryable. |
| The web hid its withdrawal control even on failure, and could not retry old tokens after the live token disappeared. | Withdrawal covers every prior token; receipt and epilogue retain failed controls and show “Retry image cleanup” while pending. |
| Already-revoked legacy tokens with no stored copies were omitted from the queue backfill but returned by withdrawal. Confirmation would fail forever. | `20261206090000` ensures every returned token has a confirmable queue row. Regression runs as the authenticated owner. |
| A withdrawn Book entry still offered a web button to its deleted round. | Keep the contribution and reason, omit the dead round door. |

The participation-floor policy remains unchanged. Per-season trophies and the season-number label are in the agreed build scope; D390's clarification records that the owner's subsequent build instruction covers them. No additional product decision is needed for this candidate.

## Files changed

Combined scope: `index.html`; native app, Kit, design component and tests under `apps/ios`; RPC source/output under `packages/db`; nineteen new SQL migrations; `supabase/functions/share-cleanup/index.ts`; database/web regression tests; planning/decision/inbox documentation.

Integration-only repairs: the two final migrations, Edge worker timing, native `ShareWithdrawal.swift`, web Book/withdrawal controls, their tests and fresh Book fixtures, portable probe path, schedule script and this handoff. No new third-party dependency, brand asset, token palette, version stamp or competition rule was added.

## Verification run

| Check | Result and evidence class |
|---|---|
| Fresh isolated PG17 database, complete migration chain | 274 migrations applied; all nineteen audit migrations reapplied without error. Synthetic local fixture evidence. |
| Launch repair scenarios | 51/51 passed, including legacy cleanup confirmation, frozen/withdrawn Book lines, late seats, final placement, renewal and share lifecycle. |
| Fresh SQL Book responses through actual web validator | 10 Book checks passed, including deployed-version compatibility and withdrawn receipt behavior. |
| Native XcodeGen + simulator build/test | Passed: 30 app XCTest + 100 app Swift Testing + 16 Kit XCTest + 1,264 Kit Swift Testing + 4 Book UI tests = 1,414 tests. Kit includes fresh integrated SQL fixtures. |
| Node test runner | 74/74 passed, including 7 actual Edge-handler tests with mocked Storage/RPCs and web cleanup control regressions. |
| `npm run preflight` | 0 failures, 0 warnings. The native branch's five missing-RPC failures are resolved. |
| Diff/source generation | `git diff --check` clean; contract source regenerated; no hand-edited generated files. |

Local logs: `/private/tmp/cs-audit-integrated-db-final.log`, `cs-audit-integrated-xcode.log`, `cs-audit-integrated-node-final.log`, `cs-audit-integrated-preflight-final.log`.
Native result: `/private/tmp/cs-audit-integrated-build/Logs/Test/Test-CupSeason-2026.09.24_21-53-13--0700.xcresult`.

Claude separately reported 20/20 real local Supabase Storage checks and browser checks on its original branch. Those are inherited evidence, not a rerun against this final worker. The changed worker's retry selection is covered by the seven handler tests; production schedule/Storage proof remains owed.

## Deploys owed and remaining risks

**Local candidate only. Nothing pushed, merged into main, deployed or distributed.**

- Database deploy owed: nineteen migrations after applied `20261118090000_the_book.sql`, through `20261206090000_withdrawal_can_finish.sql`. Verify the target ledger before deployment, then run `tests/db-checks.sql` against the deployed database.
- Edge deploy owed: `share-cleanup`, its `SHARE_CLEANUP_SECRET`, and the required every-minute schedule. Privately set Vault `share_cleanup_url` and `share_cleanup_secret` before running the operator-only schedule script. Optional webhook is an additional wakeup; verify its masked target if configured.
- Client deploy owed: coordinated web push through the existing Git → Netlify path; native archive/distribution separately. Neither is performed here.
- Deployment-security hold: this public repository's candidate repairs live authorization defects. Coordinate database and public code/client publication in one release window. Do not publish the local repair branch ahead of the server protections.
- Device proof owed: original live card after process death in airplane mode and reconnection; guest/claim and Pro seating flows; real OS share completion/cancel; photo removal with a failed connection and both clients closed.
- Scheduled cleanup proof owed: with no new events, an expired preparation and a backed-off failure must become completed, with neither public JPG nor PNG served. Verify the schedule is active and invocation/queue evidence agrees; job existence alone is insufficient.
- Broader launch gates remain in the release checklist (recipient journeys, human/device evidence and owner distribution checks).

Recommended next step: review this combined candidate on a phone, then authorize the coordinated database/Edge/schedule/web release. Keep native distribution as an explicit separate action.
