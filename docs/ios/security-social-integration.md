# Security and social integration · 2026-09-26

Branch: `codex/security-social-integration-2026-09-26`.

## Composition

- Started exactly at Claude's rebased `92eb42c6`.
- Cherry-picked only native `b23ea8ee` as `fe58f24a`. The obsolete merge
  `17309313` and the three pre-rebase security commits are not ancestors.
- Merged current main `9d92c69d` to preserve the course-home correction that
  landed while the original rebase prompt was being prepared. The only textual
  conflict was the decision log; D391 and D392–D396 are all retained.
- Restored `Rpc.swift` from `92eb42c6`, then regenerated from the merged contract
  to include `course_home`. No generated file was merged by hand.

## Corrections

The applied course-home migration already owns `20261209090000`. The unapplied
security migration is now **`20261210090000_reach_needs_a_relationship.sql`**.
Do not deploy the stale `20261209090000_reach_needs_a_relationship.sql` from the
original security workspace: its version collides with the production ledger.
The migration body was preserved during the rename.

The round conversation already had `report_content` with `p_kind: comment` and
`p_comment`, plus `set_mute`. It now says **Block** consistently with the new
server behavior. A UI test reports the persisted comment identity and blocks
its author, then verifies the conversation and composer disappear. Plan
comments retain `id` and `profile_id`; reports use `round_comment`. Older
payloads without comment identity cannot submit an invented report id.

The course-home read was also missing from the native RPC dispatch list. It is
registered now. Synthetic responses run after real endpoint selection, so the
course-home UI test can no longer hide a missing production registration.
Build 1033 was archived from the earlier course-only commit but never uploaded;
this integrated candidate supersedes it.

## Deployment order and authorization

The owner's initial integration request held all publication. Their subsequent
instruction, “When you finish and all pen items are closed out please ship to me
in test flight,” authorizes the completed release. The dependency order remains:

1. Database, including security migration `20261210090000`; health checks.
2. Edge: push, season-email, share-cleanup, courses, scan. The first three keep
   JWT verification disabled because their authenticated webhook paths differ.
3. Main push and web deployment.
4. Signed native archive, Apple processing, Owner TestFlight, availability check.

Friends distribution and App Store submission are outside this shipment.
Independent account/provider operations from the wider audit (MFA, billing caps,
repository visibility, account cleanup and App Store privacy-label changes)
remain owner work; this integration does not silently change them.

## Verification and evidence

All UI fixtures are synthetic and Debug uses the local backend. The production
database is never used as a rollback sandbox.

- `npm run preflight`: 0 failures, 0 warnings.
- `node --test tests/*.test.mjs`: 107 passed, including the four Edge security suites.
- `node tests/social-course-database.mjs`: 128 assertions passed against the complete disposable migration chain.
- Security reach scenarios: 41 passed against that chain.
- Generated Swift/TypeScript contracts: generator check passed; diff whitespace check passed.
- Web smoke: desktop 1440 px and mobile 390 px passed, zero console errors or horizontal overflow. Intentional network-failure warnings confirm draft/retry handling; the existing Supabase lock deprecation is unchanged.
- Independent Claude review at `4a1ce60d`: no blocking findings; no code changes.

Unsuccessful native attempts identified two corrections: the new report test
queried an identifier SwiftUI replaces on child elements (it now selects the
accessible action label), and exact-comment scrolling could precede sheet
layout on the compact phone at AX3. The receipt now waits for presentation
layout and cancels pending scroll work on dismissal. Both targeted flows pass.
An additional simulator launch showed the signed-out root instead of the
requested Debug fixture; its unchanged rerun passed. One accidentally repeated
test action was cancelled; it is not counted as a successful full run.

The disposable all-database health harness has the same two limitations recorded
in the earlier native handback: the local cron stand-in omits a production job,
and security scenario fixtures intentionally create a future plan without its
host RSVP. These are not waived production invariants. Production health must
pass all 58 checks after deployment.

## Native verification

Both complete runs, iPhone 17 Pro and iPhone SE, passed **1,465 / 1,465 each**,
with zero failures or skips: 1,316 Kit tests (16 XCTest + 1,300 Swift Testing), 138 app tests, five
security UI tests and six social UI tests. The six include the original four
plus the real course-search route at accessibility size and comment Report/Block.
Screenshots confirm the course home, course best/history, and exact-comment
landing; light, dark and AX3 are covered.

## Release evidence

- Native source: `62d38103e9c5070669fc1713ec72b7c5a191821a`; marketing version
  **1.0.0**, build **1042**. Release archive and export succeeded.
- App/widget bundle identities and build versions match. `codesign --verify
  --deep --strict` passed; app uses production APNs and disables debug entitlement.
- IPA SHA-256: `d81a2a36c4e65904873d7fee3ad805b1cb9f14acad6a396a014f25c047a98ec7`.
- Database: security migration **20261210090000** applied, **278** total;
  **58/58 production health checks pass**, including cron and host-RSVP checks.
- Edge: **push 40**, **season-email 14**, **share-cleanup 3**, **courses 21**,
  **scan 9**, all ACTIVE. The first three read back `verify_jwt=false`;
  courses and scan retain JWT verification.
- Source pushed to the owned branch and main. [GitHub CI passed](https://github.com/Fischbeck3/cup-season/actions/runs/36215814144).
- Live web caption `v23 · 62d3810`, HTTP 200, boot complete, zero console errors
  and no horizontal overflow. Deployment status reports database, functions and
  client clean, with no owed or unknown layer.

Apple package validation and upload passed with no errors. Build UUID
`83eecc45-76c3-4cf9-8bf1-5b12fd67bc41` reached `VALID`. What to Test saved (HTTP
200), Owner assignment succeeded (204), and a fresh read confirmed **Owner YES,
IN_BETA_TESTING, Friends NO**. Build **1.0.0 (1042)** is available to the owner.
Both signed bundles also contain their privacy manifests, shared-preferences
reason, and the five declared purpose strings are present in the app.


## Device acceptance and owner operations

The remaining device acceptance checks require the owner's phone: account A
sign-out to B sign-in with actual APNs delivery, authenticated lock-screen
actions, and widget/StandBy redaction under the owner's privacy settings. They
are included in TestFlight's What to Test notes. Simulators and fixture tests do
not establish those behaviors, and no production accounts or real notifications
were created just to satisfy a test. An actual scan-provider upload was not made.

App Store privacy-label reconciliation and the separate audit's provider/account
operations remain owner work. This is an Owner beta, with no external beta
review or App Store submission.


## Handoff

Branch: `codex/security-social-integration-2026-09-26` (source also on main).

Goal: combine the rebased security changes with the social/course interface and
ship a verified Owner TestFlight build.

What changed: native consent/account protections, comment Report/Block,
production course-home RPC wiring, and notification focus after sheet layout.

Files changed: the native cherry-pick's 46 files, the preserved main course-home
changes, `RoundSocial.swift`, `SocialBlendFixture.swift`, `RoundConversation.swift`,
`RoundReceiptSheet.swift`, `SocialBlendTests.swift`, the generated RPC contract,
this handoff, and the unapplied security migration's filename.

Verification run: clean complete Pro and SE runs, 1,465 tests each; 107 Node
checks; 128 social database assertions; 41 security scenarios; preflight;
web smoke on desktop/mobile; 58 production database checks; signed archive,
Apple validation, and TestFlight availability readback. Earlier unsuccessful
attempts and the local fixture limits are described above.

Database deploy owed: none for this release.

Edge deploy owed: none for this release.

Client deploy owed: none; web live and Owner TestFlight 1042 available.

Open questions / risks: only the physical-device acceptance checks and separate
owner/provider audit operations described above; no unresolved implementation
or automated-test blocker remains for this beta.

Recommended next step: install build 1042, open **Home → Courses**, choose a
course, and try friend score history and the comment notification flow.

Private verification evidence is retained at
`~/cup-season-audit-private/security-2026-09-25/codex-social-integration-1042/`,
including both final `.xcresult` bundles, signatures, deployment responses,
production health, and Owner availability. The closing documentation commit
does not change the native binary built from `62d38103`.
