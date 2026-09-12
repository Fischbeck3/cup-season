# TestFlight preparation · 2026-09-12

The integrated client has passed the release-window function and quality checks below. Archive/export follows this source checkpoint; the exact candidate path, build and signature verification are recorded separately in ignored `work/testflight-candidate.md` so the archived Git tree remains clean. Nothing has been uploaded by this preparation task.

## Scope and governing decisions

Branch `codex/home-no-photo-2026-09-12`, workspace `cup-season-home-no-photo`. Claude completed the `040dcd2` handoff; merge `05beb49` preserves both decision/inbox histories. Claude's workspace was not edited. Product vision, brand/token rules, D234 and D340–D345 govern this pass. No new competition rules, production mark, dependency or historical-round rewrite.

The owner authorised preparation and a top-down inspection. D343/D344 were independently confirmed applied by read-only production metadata: 231 migrations, latest `20261023090000`. D345 was absent. Its activation remains separate from the client release.

## Corrections in this checkpoint

- **Home / function:** both clients send their calendar day to dispatch and retry the existing signature when the server lacks it. The native retry preserves the requested feed window. Keep the existing local headline correction while supporting older servers.
- **Unapplied D345:** fix the JSON loop variable that crashed the entire actual Home RPC when a plan qualified. Require the local-day capability for the new prompt, refresh the existing upcoming-plan payload when local and UTC dates differ, and describe an invitation without claiming it was played. Reject a null answer; prevent stale Later from overwriting terminal Didn't play. RSVP/history remain untouched.
- **Home / interaction:** preserve keyboard focus after selecting, removing or failing to save a web reaction. The native loaded-photo face has a 44pt target and retains the existing VoiceOver custom action; face and photo open distinct destinations.
- **Course / navigation:** a course with a loaded card now also offers “Put it on the plan,” before its existing whole-card reference link. It uses the existing tertiary style and composer, prefilled with the course identity. No new visual hierarchy or planning mechanic.
- **Audit integrity:** add a disposable PostgreSQL suite that invokes the actual migrated function; extend browser failure/retry/focus coverage and native photo/course tap tests. The loaded-photo fixture is explicitly a render fixture, not proof of network image loading.

## Top-down inspection

| Layer | Evidence and outcome |
|---|---|
| Product / facts | Approved eligibility preserved; uncertain attendance described as a plan; no invented score, photo or plan-to-round link. |
| Server / compatibility | Actual D345 RPC and role-isolation tests pass in an isolated PostgreSQL 17 cluster. Old caller/new server and local-evening schedule cases covered. Production unchanged. |
| Native foundations | Integrated CupSeasonKit, CSDesign and app test targets passed. Coverage includes existing domain, draft, scoring/recovery, navigation and rendering contracts. |
| Real navigation | Signed-in iPhone SE: course-to-prefilled-plan in light/dark, Compete-to-season and creation intent, golfer card, both settings doors, restored-account offline boot. Eight tests passed, none skipped. Tests stop before submitting real plans, scores or competitions. |
| Home / failure | Missing and invalid photos retain record, person and reaction doors; reaction select/remove and native loaded-photo face/round taps pass. Web also tests failed write rollback/focus and refreshed photo data. |
| Offline | Eighteen-hole illustrative local round survives process death and is kept on the phone; real restored account reaches offline setup. No real score posted. |
| Visual / accessibility | Reviewed AX3 no-photo and sign-in-with-keyboard captures, local kept-round state, 375pt course footer/composer and season, plus loaded-photo fixture. Existing room, token and type language retained. |
| Packaging | App identity, version source, privacy manifest, permission text and export configuration inspected. Archive must be generated from the clean committed source using `tools/ios-archive.sh`, without `--upload`. |

## Verification record

- `npm run preflight`: PASS, zero failures, zero warnings. Log `work/testflight-prep-preflight.log`.
- General web suite: **461 assertions**, zero failures, no horizontal overflow at 390px. `work/testflight-prep-web-general.log`.
- Expanded Home browser suite: PASS at **390px and 320px**, including old-server retry, invalid/refreshed photo, record/golfer routes, keyboard, reactions and deliberate failed-write rollback. `work/testflight-prep-home-web.log`.
- `python3 tests/after-golf-postgres.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`: PASS. `work/testflight-prep-db.log`. A private Unix socket and disposable schema are used, with TCP disabled. The real function executes, but other Home ranking branches have minimal stubs; this is not full staging or PostgREST certification.
- Initial integrated native run: **1,318 passed**, one newly added photo-test lookup failed. `work/testflight-prep-native.xcresult`.
- Home/offline run: three Home checks and local score recovery passed. The restored-account check was run on a signed-out device; the photo fixture was not present in that run's accessibility snapshot. These failures were retained, investigated and not counted as app passes.
- Final signed-in run: **8 passed, 0 failed, 0 skipped**. `work/testflight-prep-signed-in.xcresult`. Photo lookup now matches the actual SwiftUI container and explicitly terminates before launch. Both coordinate taps remain asserted.
- Final photo rerun on the original iPhone 17 Pro: PASS (exit 0), `work/testflight-prep-photo-final.xcresult`. This closes the earlier photo failure on both tested device sizes.
- `git diff --check`: clean.

Screenshots are local/ignored under `work/testflight-prep-screens`, `work/testflight-prep-home-offline-screens`, and `work/testflight-prep-signed-in-screens`. They include real account data and are not committed to this public repository.

## Known limits and follow-ups

- D345 needs a production-like staging run and owner visual review before its separately authorised deployment. Later / Didn't play UI and a plan-prefilled round composer are still future client work. Its current action opens the existing plain composer; there is no durable plan-to-round association.
- Tee-less catalogue visibility and genuinely unlisted courses remain the next course-search workstream, with the documented D150 boundary. This candidate does not claim to repair those search omissions.
- Cached-image arrival re-entry and hidden-feed digest suppression remain unconfirmed review leads, not proven fixed defects.
- Xcode reports three legacy unassigned icon assets and its existing debugger-version diagnostic. The assigned normal/dark/tinted app icons remain intact. Inspect the exported candidate separately; this pass does not finalise the brand mark.
- Camera capture, APNs delivery, receipt of a new auth email, and posting a real production round were not exercised in this pass. A real-device beta smoke should cover those operational paths without fabricating competition data.
- No upstream is configured for this Codex branch. No arbitrary upstream was assigned, and no client push was performed.

## Handoff

Branch: `codex/home-no-photo-2026-09-12`.
Goal: integrate the completed handoff, correct reproduced issues, audit general function/quality, and prepare a signed TestFlight candidate.
What changed: date/API compatibility, D345 runtime and answer corrections, web reaction focus, native photo target, loaded-course planning door, durable regressions and this report.
Files changed: `index.html`; `HomeStream.swift`; `HomeWire.swift`; `CourseScreen.swift`; `HomeNoPhotoFixture.swift`; native HomeDispatch/HomeNoPhoto/CoursePrep tests; `tests/home-function-browser.js`; `tests/after-golf-postgres.py`; `tests/fixtures/after-golf-db.sql`; unapplied D345 migration; this report; inbox and tandem status.
Verification run: checks and evidence above; archive/export evidence belongs to the candidate record generated from this checkpoint.
Database deploy owed: D345 held separately; D343/D344 already applied. Do not batch-push migrations as a side effect of shipping this client.
Edge deploy owed: none from this change.
Client deploy owed: archive/export, then explicit upload/distribution step; web push remains separate.
Open questions / risks: staging and physical-device limits above; no release claim beyond observed evidence.
Recommended next step: create/verify the clean signed archive, then upload and distribute that exact candidate when the owner requests the TestFlight push.
