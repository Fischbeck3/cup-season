# Production release inspection · 2026-09-13

## Outcome and ownership

Owner requested a larger audited sprint and production access on a phone: **Safari first, then TestFlight**. Codex integration branch `codex/today-release-2026-09-13` incorporates Claude's season activation and second release-fix pass `99549ca`. Claude led implementation on its separate workspace; Codex independently reviewed, integrated, repaired the remaining web scope defect, tested, and operated release.

**Safari is live at https://cupseason.app**, release candidate `25458ff`; verified by live HTML and cache-cleared browser checks at 390/320. Native **build 835 (1.0.0)** archived successfully from that exact candidate, but distribution export is blocked by Apple cloud-signing permissions. No IPA was produced or uploaded; App Store Connect confirms no build 835. A later documentation-only commit records these results without changing the tested app sources.

## Findings resolved

- Ordinary posting retains one durable, owner-scoped request identity through retries and edits. Missing RPC/unreadable storage fails closed. Accepted recovery clears the composer; server serialization prevents concurrent bodies creating two rounds.
- League creation has durable replay. The agreement preserves real stored/custom rules including Unlimited. Invitation/code doors disclose authoritative handicap allowance, limits, minimum and dates. Event invitations disclose actual type and stake. Warm join links and decline have reachable routes.
- Month/Home use the same server facts for joining-month waiver and available bye. No competition scoring changes.
- Home no-photo receipts, person doors and reactions retain their separate actions. Independent preflight found `scanCtx` declared inside a narration try block but used outside; moved the declaration into the handler scope before release.
- Widget snapshots request reload on publish/clear, schedule expiry explicitly, sanitize legacy data and clear across account changes. Delayed old-owner publication is refused. Lock Screen rectangular season glance is private and dated. Orphan own-round Live Activities are ended on recovery/account change.
- Archive helper now authenticates both provisioning phases using the existing App Store Connect API key. Fake-tool regression checks cover archive/export failure and prevent old artifacts being uploaded. The actual archive succeeded; distribution export returned Cloud signing permission error and no iOS Distribution certificate.

## Executed verification

- Full local PostgreSQL history: **239 migrations passed**, D345 excluded. Isolated UTF-8 cluster with local Supabase stubs; no production rollback sandbox.
- Real local RPC concurrency/permissions tests: **9 groups passed**, including both amended-request arrival orders, same-body replay, corrected refusal, owner-only status, league creation replay, invitation/code covenant, event invitations and monthly/Home facts.
- Final preflight with installed locked lint dependencies: **0 failures, 0 warnings** after contract generation.
- Compact iPhone native run: 1,262 passed; two UI selectors were ambiguous because the debug fixture overlays another screen. Scoped the golfer selector to the fixture and tapped the receipt's identifier; all four Home UI journeys then passed. Domain/app tests and both league-setup UI tests passed in the full run.
- Snapshot lifecycle suite: 11 passed, including account changes, delayed publisher, clearing, expiry, future timestamps and persisted-content sanitization.
- Browser at 390/320, service workers/caches cleared: setup 20 checks each; actual Post-button fault injection 11 checks each (network disabled) covering offline, edited retry, accepted recovery, narration failure and unreadable receipt. Existing Home browser audit also passed photo/fallback, person/receipt/reaction and keyboard/target checks. No console errors or horizontal overflow. Existing Supabase lock-option deprecation and deliberately injected failure warnings remain documented.
- Compact native Home screenshots inspected at normal and AX3 text; no-photo fallback/reactions are readable. These fixtures prove the UI paths, not live account end-to-end transactions or actual iPhone WidgetKit scheduling.
- Standard iPhone 17 Pro native run against the regenerated bindings: **1,264 passed, zero failures/skips**. Light setup/agreement and dark AX3 setup screenshots inspected. Result bundle `/tmp/cup-season-today-standard.xcresult`.
- Live Safari smoke: `v23 · 25458ff` at both 390/320; expected boot controls/recovery code present, zero console errors/overflow. Existing SDK deprecation warnings only.
- Archive main app and widget extension both verified as version 1.0.0 / build 835, IDs `app.cupseason.ios` and `app.cupseason.ios.widgets`. Export failed before IPA creation; this is not a distributed TestFlight build.

## Exact database deployment

Applied from a hash-recorded staging manifest containing canonical migrations except held D345, using `supabase db push --skip-vault`. Dry run showed only these eight; actual deployment and read-only production readback confirmed **239 applied**, latest `20261101090000`, held D345 false.

1. `20261025090000_unlimited_means_unlimited.sql`
2. `20261026090000_the_terms_reach_every_door.sql`
3. `20261027090000_a_post_can_be_asked_about.sql`
4. `20261028090000_one_league_however_many_times_start_is_pressed.sql`
5. `20261029090000_the_covenant_says_the_allowance.sql`
6. `20261030090000_the_pulse_says_who_joined_and_who_has_a_bye.sql`
7. `20261031090000_an_invitation_says_what_it_is.sql`
8. `20261101090000_home_carries_the_month_facts.sql`

Read-only live pg_proc refresh produced 262 function signatures; generated bindings contain 244 functions / 193 client-callable Swift RPCs. The prior snapshot lagged other already-live migrations, so generation includes that existing contract drift too. Generated outputs were not hand-edited.

No Edge Functions, production secrets, Final scoring, historical rounds, or friend alert fanout were changed by this release operation.

## TestFlight signing hold and exact resume

Archive preserved locally: `apps/ios/build/archive/run-835-25458ff.C9u4wL/CupSeason.xcarchive` in `/Users/fischbeck3/cup-season-today-release`. Archive log and export log are beside it. Source commit `25458ff` is clean and published; do not use the old build 815 artifact.

Apple export returned `Cloud signing permission error` and `No signing certificate "iOS Distribution" found`. Its detailed recovery message says the authenticated operator has not been given access to cloud-managed distribution certificates and must contact the Account Holder/Admin. Read-only `/v1/certificates` returned only one DEVELOPMENT certificate, no distribution certificate. No certificates were revoked and no production secrets were replaced.

Apple documents cloud-signing access in [Cloud-managed certificates](https://developer.apple.com/help/account/certificates/cloud-managed-certificates) and [Distribute apps in Xcode with cloud signing](https://developer.apple.com/videos/play/wwdc2021/10204/). Existing upload/API access alone did not provide signing permission in this run. An Account Holder/Admin must authorize a signing-capable identity/key, or provision a valid local Apple Distribution identity with its private key. Do not paste credentials into chat or commit them. Merely downloading a public certificate without the matching private key cannot establish a local signing identity.

**Claude resume prompt:** Read this report and the active queue. Take a separate owned branch/workspace; Safari is already released. Resolve the documented Apple signing access with the Account Holder; do not revoke certificates, replace secrets or change account roles by inference. Once valid signing access exists, re-export the preserved build 835 archive into a fresh export directory with the existing authenticated xcodebuild flags. Verify the IPA main app and widget bundle IDs, version 1.0.0/build 835, and signing entitlements. Upload only that verified fresh IPA. Run `python3 tools/asc.py ship 835` with release notes for Home receipts, editable league agreements, safe posting recovery and season widgets. Read back VALID processing, Friends group membership and actual beta-review/distribution state. Group attachment alone is not delivery. If instead rebuilding newer source, use its own commit-count build number and rerun relevant checks. D345 stays held; no Edge deployment is owed.

## Remaining sprint and limits

R2: capability-protected Add / Later / Didn't play, safe plan-to-draft prefill and selected-course cache integrity. R3: extend factual season Record/chapters and audit existing event/Run it back consent paths. These are the next Claude-led implementation checkpoints, not delivered features merely because listed in a plan. Friend booking/start/birdie pushes and public discovery still need audience/evidence/delivery contracts. Final §14.3 vs D212 remains an owner decision.

## Handoff

Branch: `codex/today-release-2026-09-13`
Goal: audited Safari release first, current native TestFlight release second.
What changed: posting/creation integrity, real invitation/setup/month facts, Home no-photo behavior, widget lifecycle and signing-helper authentication.
Files changed: web client; iOS feature/domain/widget code and tests; eight migrations; generated contract from its source; release tools and planning/review evidence. Detailed history includes Claude `99549ca` and Codex integration.
Verification run: 1,264 standard native tests; compact Home recheck; local RPC/full-chain tests; final preflight; local and live browser walks; successful archive plus failed distribution export.
Database deploy owed: none for this release; D345 deliberately held.
Edge deploy owed: none for this release.
Client deploy owed: Safari delivered; native export/upload/beta distribution blocked by Apple signing access.
Open questions / risks: Apple cloud-signing permission and absent distribution identity; native widget behavior still needs a real-device pass after distribution; retained R2/R3 gates above.
Recommended next step: explore Safari now; Account Holder/Admin resolves signing access, then Claude resumes the preserved native artifact as specified above.
