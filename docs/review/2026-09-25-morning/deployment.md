# September 25 approved design release

Branch: `codex/play-share-store-review-2026-09-25`

Goal: Deploy the owner-approved Play, sharing and App Store presentation work.

Authorization: The owner reviewed the local gallery and said “Looks good deploy it.”

## Release identity

- Latest remote main before this release: `afd21ce2`, the combined audit integration.
- Approved implementation: `46aad31e`; review artifact commit: `5ecc9377d120e925a51d12628bd904981a02bc93`.
- Fast-forwarded remote main and published the owned branch with an atomic, non-force Git push. No merge conflicts, additional product changes or edits to another agent's workspace.
- Web and native source are the exact reviewed tree. The deployment-record follow-up is documentation only.

## Deployment evidence

Structured checksums and read-backs: [deployment-evidence.json](deployment-evidence.json).

| Layer | Observed state |
|---|---|
| Web | Netlify published `5ecc937`, verified in both HTML and service worker. Root, `/get`, `/support` and Apple association file return 200. Security headers and service-worker cache policy pass. Repo instructions, SQL and the private review gallery return 404. The documentation-only follow-up automatically advances the stamp without changing product source. |
| iOS | **1.0.0 (1022)** from `5ecc9377` is **available in Owner TestFlight**. Apple validation passed at **12:24:01 UTC**, upload succeeded once at **12:25:49 UTC**, delivery `7504a78c-4a53-409e-8cc2-9e90d3176a4d`. Read-back: **VALID**, **Owner YES**, **IN_BETA_TESTING**, **Friends no**. What to Test saved (200), Owner add succeeded (204). |
| App Store presentation | All **eight** approved PNGs uploaded and ordered in the existing **1.0 / en-US** draft, screenshot set `APP_IPHONE_67`. Apple reports **COMPLETE** for every image; MD5 read-backs match the exact approved files, dimensions **1320 × 2868**, and order 01–08. Version remains **PREPARE_FOR_SUBMISSION**. |
| Database | Read-only production ledger comparison: **274/274 applied**, through `20261206090000`, none pending or remote-only. This release adds and applies no migration. |
| Edge | Read-only deployed list confirms `share-cleanup` version **2**, updated September 25 at **05:17:07 UTC**. No Edge change or deploy in this release. |

## Verification

- Release `npm run preflight`: **0 failures, 0 warnings**.
- GitHub CI for `5ecc9377`: **Client invariants** and **Migration hygiene** passed ([run](https://github.com/Fischbeck3/cup-season/actions/runs/36134241643)).
- Live web: all **8** public-round variants passed against deployed code in a fresh browser, with no JavaScript errors, overflow or private-points leakage. These are synthetic renderer checks with production Supabase requests blocked; they are not evidence of real production round creation or sharing.
- Live source comparison passes after the version stamp and Netlify's observed pretty-URL rewrite of the two legal anchors. Initial raw byte comparison exposed only that rewrite; `/legal` returns 200. The service worker matches the stamped source exactly.
- Review-time native evidence retained: 7 UI checks on standard phone, 7 on small phone and 1 final message-disclosure check, all passed. Simulator builds passed. No app source changed after that review.
- Archive and export succeeded using the existing local signing vault. Exported app and widget signatures verified; both are distribution-provisioned (`get-task-allow=false`), with production APNs on the app. No new signing identity, production secret, dependency, design token or version-string edit.

IPA: `apps/ios/build/archive/run-1022-5ecc9377.mjJW6t/export/Cup Season.ipa` (local, ignored), **20,422,704 bytes**.

SHA-256: `7a9f7231e546b1e462bf2e65bf7be0ae2b02ba44cbf7444c29f624c3735f9bcd`.

Local logs: `/private/tmp/cs-morning-release-preflight.log`, `cs-morning-release-archive.log`, `cs-morning-live-web.log`, `cs-morning-live-http.json`, `cs-morning-release-ledger.json`, `cs-morning-store-upload.json`, `cs-morning-apple-validation.log`, `cs-morning-apple-upload.log`, `cs-morning-owner-distribution.log`.

## Handoff

What changed: approved Play setup hierarchy and keyboard controls, share consent/message and cancellation, public round presentation, intact leaderboard totals, and eight store images. See [review handoff](handoff.md) for the source inventory.

Files changed: the approved source/review commits above; this follow-up updates deployment documentation only.

Database deploy owed: **None.**

Edge deploy owed: **None.**

Client deploy owed: **None within this release. Web is live; build 1022 is available in Owner TestFlight; all eight App Store draft images are COMPLETE.**

Open questions / risks: Real-phone installation and human/device launch gates are not established by simulator tests or an upload. App Store screenshots are in the draft; public App Store review/submission and external Friends distribution are separate from this Owner release.

Recommended next step: Install build 1022 from Owner TestFlight and review Play and sharing on the phone. Availability is confirmed; installation on the owner's device is not.
