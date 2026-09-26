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

Final complete native counts and release evidence are recorded below when done.
