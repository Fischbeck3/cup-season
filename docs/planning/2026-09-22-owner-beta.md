# September 22 · Owner phone beta

## Target and scope

Prepare the recent launch and visual work for Jerecho's phone tonight. Codex owns integration, visual corrections, local verification and the signed candidate. This is an internal **Owner** beta to collect real-device evidence. The Friends gate in D372 and the public launch checklist remain open.

Candidate branch: `codex/october-visual-ui`, isolated worktree `/private/tmp/cup-season-visual-ui`. The older dirty visual checkout remains intact. Claude's W6 corrections (`8f632ed`) are integrated by `9d9ef46`; the native launch fixes, D380 sharing flow and V1 entrance fixes are all included. Archived source: **`37f959e`**, **1.0.0 (986)**. Later documentation-only commits do not change that package.

## Tonight's visual corrections

1. **Readable entry fields:** shared `CSField` placeholder prompts use opaque `mut`, matching the existing secondary-text rule in both rooms.
2. **Honest Home emphasis:** the full Home lead uses competition/live styling only for competition items, matching F11 and the compact row. An ordinary after-golf plan no longer receives a live dot or live VoiceOver label.
3. **A clean exported card header:** keep the pennant and Cup Season name together, with a guaranteed gap and a full-width header before the record label. The exported canvas, mark and typography stay canonical.
4. **Competition reachability:** exercise the existing populated competition fixture in dark/light and default/AX3 text. Check row bounds and the Start something action after scrolling.

Existing launch improvements in this candidate include unfinished/claim/ruling/re-up UI, one Share action with card/link and photo consent, atomic course-cache client support, and the invitation context at the native welcome. This packet does not claim the entire visual sprint is complete.

## Verified baseline, September 22

- App Store Connect readback: latest uploaded build **934**; internal Owner carries 934, 932, 919, 905 and 898. External Friends' latest is **795**. No recent native work has reached either group yet.
- Production migration ledger ends at **20261115090000**. The course-cache and shared-card migrations are absent. Supabase `courses` is version **18**, updated August 29.
- Fresh local PostgreSQL **17** chain: **254 applied, zero skipped**. The 17 W6 database tests passed. Course-cache validation, reapplication on the same populated sandbox and shared-card storage policy probes passed.
- Integrated top-level Node tests: **57 passed**, zero failed; with the separate database suite, **74 passed**. Preflight passed with zero failures/warnings before the final visual corrections.
- Baseline visual walkthroughs: **27 passed**, zero failed/skipped. Coverage includes Home with/without photos, after-golf states, ruling/re-up sheets, setup, offline score/relaunch/keep, share photo choices and native share cancellation.
- The initial field/competition verification passed **1,497 native tests**, zero failed/skipped, on the iPhone 17 Pro simulator. The final-pass results, including the observed test failures, are recorded below.

Machine-local evidence: `/private/tmp/cup-season-beta-db/`, `/private/tmp/cup-season-beta-baseline.xcresult`, `/private/tmp/cup-season-beta-verified.xcresult`, and their exported screenshot directories. Fixture renders establish layout, not authenticated production behavior or an unassisted real round.

## Release dependencies and boundaries

The reviewed [deployment packet](2026-09-22-course-cache-deploy.md) contains exactly `20261116090000_course_cache_atomic.sql`, `20261117090000_shared_card_consent.sql`, then the `courses` Edge deployment. An explicit owner approval is pending. Re-read the ledger and dry-run the exact pending set before any production write. Never execute the local mutation probes on production.

The signed archive can be prepared while that approval is pending. Upload and internal Owner distribution must identify the exact build and source commit. Do not use `tools/asc.py ship`: it targets Friends and external review. Do not merge to main, submit for App Review, open the Friends gate or publish a public installation link as part of this Owner beta.

## What to test on the phone

Record the installed version/build, device/iOS, room/look and text size. Use real existing golf records or clearly designated test data; do not fabricate a real round to improve a metric.

1. **Get in and move around.** Sign in, then visit Home, Golfers, Play, Compete and You. Open settings and return. Check text, tabs, back buttons, sheet dismissal and the keyboard in dark and light.
2. **Prepare and score.** Find a course and its tees; check a long course name. Exercise the approved round/score workflow, background/reopen and the documented offline recovery path. Confirm the saved state is understandable.
3. **Finish and understand.** Open a posted receipt, the season and the points/adjustment explanation. Check the no-round adjustment state and Run it back covenant where available.
4. **Share deliberately.** Preview a real photo round and a no-photo round. With the photo off, confirm the image, public page and link preview omit it; with it on, confirm the intended image. Cancel the share sheet and return safely. The production Storage API proof in recipient-journeys.md remains required.
5. **Receive it.** On the second phone, run the actual claim and invitation scripts through sign-in. Record expired/already-used behavior and install-then-reopen. Local fixtures are not a substitute for this check.

Use the full [owner checks](../pilot/owner-checks.md) and [recipient journeys](../pilot/recipient-journeys.md) for the formal release gate. Record failures with a screenshot, the last action, expected result and build number; a screenshot alone cannot establish the behavior.

## UI work after tonight's beta

- Golfers, relationships, You, record and settings: capture populated/empty/error/private states and verify the real signed-in routes.
- Complete the 13-family inventory: course search failures, code errors, setup/admin variants, public recipients, widgets/live activity and permission-denied states.
- Complete accessibility evidence: long names, largest useful text sizes, VoiceOver/focus order, reduced motion and safe-area/keyboard reachability across those routes.
- Run the timed comprehension tasks with real golfers, then fix the observed failures.
- Capture App Store imagery from the accepted build with approved content; replace `/get`'s hidden installation target only when the real invitation/store URL is authorized and available.

These remain in the [visual sprint](2026-09-22-visual-ui-sprint.md). They do not all have to be complete to obtain tonight's internal phone feedback; they do have to be accounted for before the public launch claim.

## Candidate evidence and disposition

### Final local checks

- Preflight: **PASS, zero failures/warnings** after replacing the added literal card spacing with `CSTokens.Space.s4`.
- Full final native pass: **1,508 passed, one failed**, zero skipped. All **1,493 Kit/design/app tests passed**. The failure was the standard-phone native share-cancellation UI check: the activity sheet remained visible five seconds after the recorded close tap. Its recording and accessibility hierarchy were inspected; do not relabel that run as green.
- Small phone (iPhone SE 3, 375pt): **129 passed**, zero failed/skipped, including all design tests, artifact exports, invitation/field, competition, after-golf AX3 and all five round-share walkthroughs. This rebuild includes the final token-based card spacing. Long-value export, large-text share, email and competition screenshots were visually inspected.
- Standard-phone cancellation diagnostic: three repetitions; the first failed to open the DEBUG share fixture at all, and the next **two passed**, including native dismissal. The baseline cancellation check and the small-phone cancellation check also passed. These results leave an intermittent simulator/UI-harness observation; real-phone cancellation still needs checking. No production cancellation code was changed in this visual pass.
- One initial final-suite attempt stalled before test execution and was cancelled. The isolated simulator was restarted before the recorded full final pass. Preserve this as infrastructure evidence, not a product pass.
- TestFlight push precheck: the production secret-name listing has **no `APNS_SANDBOX`**. No secret value was printed or changed.
- The competition test now checks full vertical visibility, not just `isHittable`; the final run **passed on both 375pt and 402pt phones**, in dark/light and default/AX3 variants. The full-label screenshots were inspected.

Result bundles: `/private/tmp/cup-season-beta-final-rerun.xcresult`, `/private/tmp/cup-season-beta-small.xcresult`, `/private/tmp/cup-season-beta-cancel-repeat.xcresult`, `/private/tmp/cup-season-beta-action-bounds.xcresult`. The known Supabase initial-session runtime warning remains unchanged.

### Candidate

**Prepared, signed and exported; not Apple-validated, uploaded or distributed.**

- Source commit: `37f959e`; build **1.0.0 (986)**, generated from commit count.
- Archive: `/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/CupSeason.xcarchive`.
- Exact IPA: `/private/tmp/cup-season-visual-ui/apps/ios/build/archive/run-986-37f959e.QoXfzc/export/Cup Season.ipa` (**19,965,012 bytes**).
- SHA-256: `a9de87cfd14590b7cd1d838e7baf63c7b9e5bbe6fb9e160f0edbbfbdafcaf87d`.
- App and widget signatures: `codesign --verify --deep --strict` **PASS**. Both are 1.0.0 (986), iOS 17 minimum, non-debuggable, and use the same app group. Distribution profiles expire September 14, 2027. App APNs entitlement is `production`.
- Archive/export completed successfully using the existing local signing vault. Existing compiler warnings in unchanged sources were retained; this is not a warning-free archive claim.
- Release-string inspection found the existing `-cs_dev_no_worth` argument check in `PostRoundModel` remains compiled outside its neighboring DEBUG block. It only suppresses the worth read when explicitly supplied; the normal phone launch does not supply it. Move that diagnostic guard wholly under DEBUG in a later code slice. The inspected visual fixture launch switches are absent from this executable. Do not claim a blanket zero-debug-string check passed.
- Local package inspection: `/private/tmp/cup-season-beta-986-package-check.json`. Archive/export logs remain beside the archive.
- Visual review: `/Users/fischbeck3/.codex/visualizations/2026/09/22/01a0c938-cfd8-7640-a89d-da9d1edade7e/cup-season-owner-beta-review.html` (four embedded native captures, rendered and checked in the browser).

**Approval state:** automatic approval review rejected `altool --validate-app` before execution because transmitting the signed IPA to Apple needs explicit approval for this build. No package was sent. The owner has been asked to approve validation, upload and internal Owner distribution of this exact IPA. The earlier two-migration/`courses` production approval is also pending. Do not rerun the denied validation or perform dependent Apple/production writes without the corresponding answer.

Owner group: `c4a784fe-22c5-4a75-bd4b-ca864b63574a`. Friends group: `9f8db84a-166c-4900-b196-ea2c5459e369` (closed to this candidate). After approval, validate this exact package, upload it without rebuilding, await VALID processing, update its What to Test, add only to Owner and read that group's build relationship back. An upload alone is not distribution, and distribution is not proof that the phone installed it.

No database, Edge, Netlify production, Apple upload, group assignment, review submission or main merge was performed by this beta-preparation pass.
