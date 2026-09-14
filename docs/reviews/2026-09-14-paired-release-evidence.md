# Paired release review and delivery · 2026-09-14

## Delivery

- Application source: **1bc307f**, composed from Claude's completed **eaaa361** handoff plus Codex review fixes.
- Owned branch/workspace: `codex/paired-release-2026-09-14`, `/Users/fischbeck3/cup-season-paired-release`. Claude's workspaces were not edited.
- Web: pushed to main; **https://cupseason.app/** independently read back **v23 · 1bc307f** in the rendered production page and **1bc307f** in `sw.js`. Production welcome checks passed at 320 and 390 pixels. This supersedes preview #3 for owner review.
- Native: **build 890**, source **1bc307f**, archived successfully. Export failed with **Cloud signing permission error** and **No signing certificate "iOS Distribution" found**. No IPA exported or TestFlight upload performed.
- Database deploy owed: none from this release.
- Edge deploy owed: none from this release.
- Client deploy owed: web complete; native distribution signing, export, upload and processing remain.

## Changes and findings resolved

Claude's [paired candidate](2026-09-13-paired-release-candidate.md) provides the mobile Home/Compete/season/posting/setup work, welcome composition, receipt routes and interior identity.

Codex commits:
- `90baa6b`: native posting explains the selected league's actual solo/squad and cap rules; unknown settings do not invent rules. Preset explanations use actual defaults while preserving editing. Receipt arithmetic has explicit parentheses. Unknown career counts no longer become zero.
- `1884c5d`: failed web career reads preserve unknown/prior facts; strict season navigation propagates required read failures and retries failed loads. New season controls meet 44px. Browser verification now bypasses HTTP cache and controlling service workers after discovering stale source during review. Existing lint baselines were tightened only.
- `1bc307f`: removed an over-narrow welcome headline constraint that split ANYWHERE at normal phone size. Added a loaded-font two-line assertion while retaining enlarged-text wrapping.

No competition rules, database contracts, dependencies or production secrets changed. The terminology document explicitly records why approved factual preset copy supersedes its historical mood labels.

Files changed by Codex: `index.html`; native `PostRoundScreen.swift`, `YouScreen.swift`, `PostCard.swift`, `ReceiptSeed.swift`, `WizardState.swift`; corresponding Post/RoundsYou/Wizard tests; web brand-door/home-hierarchy/you-credential tests; `tests/preflight-baselines.json`; `tools/web-verify.mjs`; terminology amendment.

## Verification

- Committed application preflight: **0 failures, 0 warnings**; diff whitespace check passed.
- Native selected suite: **1,289 tests**, 1,286 passed and three new counting-copy tests failed because their fixture omitted required member_id. Corrected the fixture; all three passed on rerun. This is two runs, not a claim of one clean 1,289-test run. Included kit/app tests and selected setup, Compete, receipt and after-golf UI journeys.
- Eight initial candidate browser suites passed. Following review fixes: real career-loader failure/empty/preserved-value checks and season route checks passed at 320/390/1440; setup, after-golf repairs, release posting and app suites passed at 320/390; final welcome passed at 320/390/1440 including enlarged text.
- Actual-account, read-only walkthrough on preview eaaa361: Home last round and standings history open receipts, career count agrees with career data, and Home's other-league control arrives in the selected season. No business records submitted. Netlify preview report-only CSP messages were present; these runs are not clean-console passes.
- Published 1bc307f welcome: 320/390, dark/light and enlarged text checks passed, no horizontal overflow, zero console errors; existing SDK lock deprecation warnings remain. Production HTML and service-worker versions match.
- Production browser profile has no signed-in session. Actual-account checks above were on preview eaaa361, not a signed-in production walk on 1bc307f.

Local evidence: `/tmp/cs-paired-publish-preflight.log`, `/tmp/cs-paired-native-0914.xcresult`, `/tmp/cs-paired-native-counting-fixed.xcresult`, `/tmp/cs-paired-archive-0914.log`, `/tmp/cs-paired-live-0914/`. Private account captures remain local and are not committed.

## Remaining differences and next ownership

This is the reviewed paired checkpoint, not a claim of complete feature or visual parity.

- Web install/favicon/apple-touch/OG assets retain Tracer. Candidate pennant web icons are prepared but not installed; candidate OG composition remains owed. Keep this as an explicit separate brand application review.
- Physical iPhone Safari safe areas, keyboard, VoiceOver and Dynamic Type remain unverified. Chromium and native Simulator evidence do not replace them.
- With-photo receipt sharing/opt-out and a full production signed-in walk remain unverified in this pass.
- Harness freshness checks bypass the service worker; they do not prove offline/update behavior. Required season read failures are surfaced, but this is not transactional rollback of every context mutation or a rewrite of optional-read behavior.
- Native system widgets/Live Activities are platform-specific capabilities.

Next: owner/account operator resolves distribution signing; release operator exports and uploads the reviewed source, then verifies App Store Connect processing and beta availability. Claude remains lead builder for the next separately scoped packet, starting from main 1bc307f in an owned workspace. Codex reviews committed checkpoints and native/integration behavior. Every future packet must list its web half, native half, explicit differences and working HTTPS phone preview before it is called complete; signing must not block web delivery. This is recorded ownership, not automatic agent messaging.

Branch: codex/paired-release-2026-09-14
Goal: deliver the reviewed paired web/native checkpoint.
What changed: integrated Claude's finished work, repaired review findings, published web, archived native.
Files changed: listed above; this evidence and ACTIVE_WORK update are documentation only after application release.
Verification run: listed above.
Database deploy owed: none.
Edge deploy owed: none.
Client deploy owed: native export/upload after signing recovery.
Open questions / risks: explicitly listed above.
Recommended next step: phone review on live web and signing recovery for the reviewed native source.
