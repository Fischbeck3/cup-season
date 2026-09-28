# Selected repair release · September 28, 2026 UTC

Owner authorization: **“Ship it”**, after the completed S1a/S1b build handoff disclosed inherited checks and missing human/device proof.

Owned branch/worktree: `codex/ten-ship-2026-09-28`, `/Users/fischbeck3/cup-season-ten-ship`. The original dirty checkout and other workspaces remain untouched.

## Released source

Fresh baseline `5fabf861c4bee83e2492769f8e76ab3f9cda8281` fast-forwarded to **`cf6d0663dd14f0bc16e4fa8552fdadf79cbb334e`**, with an atomic, non-force push of main and the owned shipping branch. Approved Door `a4101f71` integrates as `111f8f3e`; Home `f884696b` integrates as `68e8716f`. Documentation `025d8f87` and its baseline/context ancestors are included.

Only `index.html` and `apps/ios/CupSeason/Door/DoorView.swift` change in production source. Web Email now has a persistent associated label; the native field has an explicit accessible name; web Home occasion text uses its readable ground and ordinary actions use `act`. No database, RPC, Edge, generated runtime token, icon, production mark, dependency or competition-mechanic change.

Delivery scope is main/Netlify web and internal Owner TestFlight. No App Store submission, Friends distribution or production-data mutation. This release-record follow-up changes documentation/evidence only; it does not require a second native archive.

## Web verification

- Local release preflight: **0 failures / 0 warnings**. CI test set: **105 passed / 0 failed**. Sunningdale: **27 assertions passed**. Actual `stamp-version.sh` build passed and kept `dist/` untracked.
- [GitHub CI](https://github.com/Fischbeck3/cup-season/actions/runs/36376341114): Client invariants and Migration hygiene both succeeded for `cf6d0663`.
- Production HTML and service worker both report **`cf6d066`**, read at 2026-09-28 04:07 UTC. The approved label and Home CSS substitutions are served.
- `/`, `/get`, `/support`, `/legal.html`, `/legal` and the Apple association file return 200. Security headers and the service worker's no-cache policy are present; the association file names the expected iOS app.
- `AGENTS.md`, this review's README and an actual tracked migration path return 404. The `dist` publishing boundary holds.
- Live HTML matches the locally stamped artifact except for the two equivalent Terms/Privacy anchors normalized by hosting from `/legal.html` to `/legal` and reserialized. Attribute comparison passes; all other HTML bytes match. An initial strict byte comparison flagged this known hosting transformation; no product edit was made.
- A fresh browser verification tab visibly reports `cf6d066`. Opening email entry exposes visible Email text and the accessible name EMAIL, with the scoped grid layout. No email was entered or submitted. No real authenticated session was reset. No browser errors were observed; the Supabase lock-option deprecation warning remains.

## Native artifact

**1.0.0 (1053)** is built from the clean `cf6d0663` source. The production Door file hash matches the previously tested S1a repair exactly. Archive and export succeeded using the existing distribution vault. The archive records 83 warning instances across 21 distinct messages; it is not a warning-free native build.

IPA: `apps/ios/build/archive/run-1053-cf6d0663.K3Qdj8/export/Cup Season.ipa` (local only), **22,050,486 bytes**.

SHA256: `f0dfcb7535f493710093b7e3f89c1bf8a6984c70afbef0cebd16904cb51bfb9c`.

App and widget signatures verify. Both have version/build 1.0.0/1053, distribution entitlements with `get-task-allow=false`, and the canonical `group.app.cupseason.shared`; the app has production APNs. Profiles expire September 14, 2027. An initial verification assertion assumed the wrong app-group name; the corrected check reads the canonical entitlement source and passes without changing the artifact.

Apple validation and upload both succeeded with no errors. Upload delivery UUID: `e0b4db37-3be1-4bc0-9710-49c40ac122fe`. Availability is recorded separately below; upload alone is not distribution.

## Limits retained

[BUILD.md](BUILD.md) retains the full capture matrices and test outcomes: the baseline/after 1600px Door terrain assertion failure; one unsigned-simulator keychain entitlement failure among 1,574 native non-UI tests; non-clean fixture consoles; complete authenticated UI, physical-device, VoiceOver, Reduce Motion and timed human tasks still unproven. The live auth deprecation warning and archive warnings remain recorded. No gate was changed to manufacture a pass, and this narrow delivery is not global launch clearance or a 10/10 claim.

The release dry-run could not query globally linked database/Edge state from this isolated worktree. This release changes neither layer, so neither requires deployment for these repairs. No database or Edge deployment was attempted.

## Owner TestFlight read-back

At **2026-09-28 04:16 UTC**, Apple reports build 1053 **VALID**, not expired, **IN_BETA_TESTING**, **Owner YES**, **Friends no**. Exact What to Test notes were read back and match. The App Store 1.0 draft remains **PREPARE_FOR_SUBMISSION**. Native delivery is complete; installation on a physical phone is not claimed.

The notes ask the owner to check the Email announcement before/after typing, larger text on a small iPhone, keyboard focus, and the 8-digit sign-in flow. Physical-device VoiceOver and full sign-in/recovery remain unverified.

[Sanitized release evidence](deployment-evidence.json) records source, artifact, HTTP, CI and Apple read-backs. Raw signing/archive/Apple logs stay local. The documentation-only follow-up republishes the same product sources with its own web stamp; native remains build 1053 from `cf6d0663`.

## Handoff

Branch: `codex/ten-ship-2026-09-28`, pushed with main
Goal: Ship the approved S1a/S1b repairs
What changed: persistent web Email label, native Email accessible name, readable web Home occasion pairing, approved context corrections and release records
Files changed: production `index.html`, `apps/ios/CupSeason/Door/DoorView.swift`; approved program documentation/evidence and planning status
Verification run: release preflight, complete Node CI set, scoring assertions, stamped build, GitHub CI, production HTTP/DOM read-back, signed native archive/export, Apple validation/upload and exact Owner availability/notes read-back
Database deploy owed: none for this release
Edge deploy owed: none for this release
Client deploy owed: none; web live and Owner TestFlight 1053 available
Open questions / risks: retained inherited test failures, console/compiler warnings and unperformed full authenticated UI/device/human checks; no global launch clearance
Recommended next step: install Owner TestFlight 1053 and complete the existing human task sheet before the separate App Store submission
