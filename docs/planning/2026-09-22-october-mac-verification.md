# October launch — Mac verification handoff

2026-09-22 · Codex · `codex/october-launch-mac-verification`, based on
Claude's stopped and pushed `4a171f7`. Worktree:
`/private/tmp/cup-season-october-mac`.

The native implementation is now locally verified. This pass also recovered
the atomic course cache and fixed defects found in share consent and storage
permissions. Nothing was merged, deployed, archived, uploaded or submitted.
The owner's existing worktree and Claude's branch were left untouched.

## What changed

- Recovered `39c8d00`'s atomic cache migration byte-for-byte as
  `20261116090000_course_cache_atomic.sql`, after the four applied November
  migrations. Integrated its single RPC into the normalized provider path.
  Malformed, mismatched and empty provider cards fail without replacing the
  cache; sparse refreshes preserve tee IDs and existing holes.
- Fixed the native share sheet staying presented after cancellation. The
  existing cancellation UI test now passes. Corrected a re-up test fixture
  that expected host/roster facts without supplying them.
- Fixed photo withdrawal when a PNG contains the photo but the separate JPEG
  upload failed. Unknown card consent now causes a new token on opt-out.
  Listing, deletion or revocation failures stop sharing the link. Explicit
  revoke removes both formats. The web clears stale decoded image data, and
  native freezes the consent answer with the image while minting.
- Added `20261117090000_shared_card_consent.sql`. Existing helpers admitted
  JPEG only, and there was no shared-copy SELECT policy: PNG uploads failed
  and listing could falsely look empty. Both formats now use the same owner
  boundary; writes require a live token, while owners can read/remove revoked
  copies. Other owners and anonymous callers gain no access. Both clients
  refuse this share path until the PNG predicate is available.
- Added local storage-policy and share failure regressions, and DEBUG-only
  simulator fixtures for the actual ruling and re-up sheets. The fixture
  ruling model has no season and cannot make a server write.
- Fixed `stamp-version.sh`'s GNU-only `sed -i` invocation with a portable
  temporary-file replacement. The same allowlisted build now runs on the Mac;
  source version placeholders remain untouched.

## Verification actually run

| Check | Result |
|---|---|
| Native build-for-testing at Claude's `4a171f7` | Passed; the reported `LiveClaim` compile error is fixed |
| Final CupSeasonKit suite | 1,235 passed |
| Final CSDesign suite | 120 passed |
| Final app suite | 122 passed (22 XCTest + 100 Swift Testing) |
| Focused simulator UI suite | 6 passed: four round-share tests and two launch-sheet tests |
| Preflight | 0 failures, 0 warnings |
| Node regression command | 20 passed, including eight share-flow failure/consent checks |
| Complete in-browser function suite | 489 passed, zero failures, in the local in-app browser after clearing service workers/caches |
| Real `stamp-version.sh` build | Passed on macOS, including `/get` and `/support` in `dist/` |
| PostgreSQL 17 full migration chain | 254 applied, zero skipped |
| Course-cache probes | Atomic rollback, malformed input, sparse refresh, stable IDs and grants passed |
| Reapply on that populated full-chain database | Passed; the migration reran without losing IDs, holes or grants |
| Storage-policy probes under authenticated roles | Own JPEG/PNG upload/list/delete passed; other-owner access and revoked writes denied |
| Standalone course-cache PG17 regression | Passed |

The first native test run exposed the fixture and cancellation failures above.
An intermediate rerun stalled before test execution; the owned runner was
stopped and the disposable simulator restarted. The final run completed with
`TEST SUCCEEDED`. No tests were disabled to obtain that result.

Native evidence is in
`/private/tmp/cup-season-october-mac-verified.xcresult` and its `.log` sibling.
Attachments were exported to
`/private/tmp/cup-season-october-mac-verified-attachments`. Inspected screenshots
show the ruling sheet, re-up covenant, photo opt-out and accessibility-size
share preview without obstructing their primary action. These are signed-out
fixtures, not proof of a signed-in round or a real-device recipient journey.
The ruling fixture has no loaded member name.

Reproduce the native selection after `xcodegen generate` in `apps/ios`, using
an available iOS simulator destination:

```bash
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO \
  -only-testing:CupSeasonKitTests -only-testing:CSDesignTests \
  -only-testing:CupSeasonTests \
  -only-testing:CupSeasonUITests/RoundShareReviewTests \
  -only-testing:CupSeasonUITests/LaunchSheetTests test
```

The database commands and deployment sequence are in
[the deployment packet](2026-09-22-course-cache-deploy.md). Local logs use the
`/private/tmp/cup-season-october-mac-` prefix (`pg-chain`, `cache-checks`,
`cache-reapply`, `shared-storage`, `cache-isolated`, `preflight`, `node-tests`).
Those temporary files are evidence for this Mac session, not repo artifacts.
The browser suite completed here with the module loaded; the remote sandbox's
CDN limitation did not reproduce. Console warnings were the existing auth
lock deprecation and the suite's deliberate error-formatting inputs, with no
error-level entries. No production share or round was written by those tests.

## Next session: execute the remaining sprint

Start from this branch's committed work in a separate owned worktree. Do not
restart from `4a171f7` and lose the fixes. Report the actual source state, then
continue authorized engineering without an extra approval checkpoint.

1. Finish W6's five-section weekly report and acquisition pipeline from the
   execution plan. Keep first-time App Store downloads separate from web and
   TestFlight; missing data stays missing. Preserve the 500 / 2,000 / 5,000
   cumulative checkpoints and flag their acquisition assumptions.
2. Prepare and carry out the W1 timed comprehension and W3 recipient journeys
   with the owner and real golfers. Run the physical two-phone checklist,
   including claim, invitation, recovery, re-up and a real round. Record
   observed results; simulator fixtures do not satisfy these gates.
3. Finish W5's installation destination when the real TestFlight invitation
   is supplied; replace it with the approved App Store URL at availability.
   `/get` must not pretend a generic TestFlight page is an installation link.
4. Prepare the release candidate and remaining gate evidence. Read current
   App Store Connect groups/builds and the live stamp; neither was verified
   in this Mac pass. Keep the owner's outreach separate from engineering.

## Deployments and approvals still owed

- **Database:** both `20261116090000` and `20261117090000`, after a fresh
  production ledger read and owner authorization. The earlier production
  evidence came from Claude's September 22 read, not a new read here.
- **Supabase Edge:** `courses`, after its atomic RPC is deployed.
- **Web:** reviewed merge/deployment of this work plus Claude's branch,
  including Netlify's `share-preview.ts`. Check the resulting live stamp.
- **Native:** physical build/checks, archive and owner-authorized Apple
  upload/distribution. No signed device build or archive ran in this pass.
- **Consent proof:** use the real Storage API and release build to verify
  photo on → off, PNG-only partial upload, revoked URL, both public image
  objects removed, and failure handling. Local RLS and mocks do not prove
  Storage API/CDN behavior. Recipient-cached previews cannot be recalled.

The wider sprint remains open. Green local suites close the Mac verification
gap; they do not establish launch readiness or progress toward 5,000 downloads.
