# Codex + Claude working agreement

2026-09-12. Coordination only; proposed after-golf behavior is not approved by this document.

## Workspaces and ownership

| Agent | Workspace | Branch | Owns |
|---|---|---|---|
| Codex | `/Users/fischbeck3/cup-season-home-no-photo` | `codex/home-no-photo-2026-09-12` | Client implementation, regression fixes, client tests, this brief, integration |
| Claude | `/Users/fischbeck3/cup-season-after-golf` | `claude/after-golf-audit` | Backend contract audit, independent client review, review reports on its own branch |

One agent edits each branch and workspace. Read the other workspace or its committed diff; never edit it. Do not switch branches in another agent's workspace. Both worktrees share Git objects, so local commit IDs are sufficient for review; no copying files or pushing is required to exchange a local checkpoint.

Claude's current assignment is audit/review. Backend implementation gets a separate, explicit file assignment after the contract and necessary product decisions are settled. Codex remains the integrator. Shared files such as `spec/decision-log.md`, `spec/inbox.md`, and `packages/db/contract.psv` require an identified owner before edits; generated files change through their source and generator only.

## Actual starting point

- Codex: `bee364a` (no-photo hierarchy and reactions), `de338d8` (Home failure handling and general function audit).
- Claude: `079a67f` (after-golf audit and independent regression review), clean workspace when inspected.
- Claude reports: `docs/reviews/2026-09-12-after-golf-audit.md` and `docs/reviews/2026-09-12-home-no-photo-regression-review.md`, on Claude's branch. Read with `git show 079a67f:<path>` from either workspace.
- Codex evidence: [Home function audit](2026-09-12-home-function-audit.md): 1,314 native tests and 461 web assertions passed, plus the Home browser flow at 390 and 320px and preflight. These are results for the prior implementation, not proof that the new review findings are resolved.
- Codex's branch has no upstream; the setup-time pull could not rebase. No upstream was assigned and no unrelated branch was merged.

## Next parallel checkpoint

**Codex: reproduce and resolve the Home review findings.** Inspect native image-loading layout changes, person/receipt destinations across clients, the lingering web reaction plus, missing-course accessibility copy, and photo/non-photo milestone consistency. Trace each claim independently before accepting it; reproduce speculative image-render re-entry before changing that path. Add targeted coverage for confirmed functional defects, inspect screenshots for visual changes, then hand over one small coherent commit at a time.

**Claude: review the proposed after-golf contract for unresolved compatibility and product choices.** Append a follow-up report on its own branch. In particular:

1. Verify PostgreSQL overload migration and PostgREST resolution: adding a defaulted argument does not by itself replace the existing one-argument function. Show old/new caller behavior and a safe migration strategy.
2. Use the same local-day rule for reading prompts and writing Later / Didn't play. The proposed write signature currently has no local-date argument; explain how its snooze date and past-day validation stay consistent with `p_today`.
3. Trace the existing plan destination on a shipped client. Prove a button labelled “Post this round” reaches a usable posting flow, or propose truthful compatible copy/capability behavior.
4. Separate owner decisions from technical conclusions: three-day window, inclusion of maybe/unanswered tags, one plan per day, and same-day suppression with missing course identity. Document the tradeoff for two genuine rounds on one day; do not treat an ambiguous match as an established link.
5. Give exact proposed payloads, authorization cases, old/new client-server combinations, and acceptance cases. Keep production read-only.

These are review questions raised during setup, not additional confirmed defects. The report's proposal is not yet a frozen contract.

## Build and review loop

1. Builder states scope and owned files, implements a small complete change, runs relevant checks, and commits on its own branch.
2. Builder supplies the handoff below. Reviewer reads that exact commit and may test in its own workspace without editing the builder's branch.
3. Reviewer returns findings with severity, trigger/reproduction, file reference, expected/actual behavior, and whether observed or inferred. Avoid stylistic rewrites without a concrete product or quality benefit.
4. Builder addresses findings and supplies the new commit and evidence. Review unresolved findings and changed paths again.
5. Codex integrates agreed commits into its owned workspace after an explicit completed handoff; run the relevant integration checks on the combined result. Reports can be read from their source branch without merging them first.

At every meaningful client change, check the actual entry and destination, success, empty/loading/failure, back/reopen/refresh, draft preservation, accessibility, and both clients where behavior is shared. Run narrow checks first; run broader preflight and native/web suites at the integration checkpoint. A passing count alone does not close an observed defect.

For the after-golf implementation, preserve unfinished post drafts and the existing live/offline recovery identity (`seededFrom`). The backend owns eligibility, suppression, and shared story production. Clients must not independently invent those rules. No scoring or historical-round rewrites.

## Handoff template

- Branch and commit:
- Goal / owned files:
- Built or reviewed:
- Verification (commands/results; observed versus inferred):
- Findings still open:
- Database deploy owed:
- Edge deploy owed:
- Client / TestFlight deploy owed:
- Next owner and bounded task:

## Release boundary

TestFlight remains held. Neither this agreement nor an audit authorizes a production migration, Edge deploy, production secret change, or a new gameplay/data-model decision. Record and obtain any required owner ruling before implementation; name each deployment layer separately. No background monitoring or automatic messages between Claude and Codex have been configured. Each agent reads the other's committed checkpoint when prompted or when continuing its assigned work.

## Setup handoff

Branch: `codex/home-no-photo-2026-09-12`.
Goal: make parallel building and independent review concrete.
What changed: recorded workspace/file ownership, current evidence, immediate parallel assignments, contract checkpoints, review loop, and release boundary.
Files changed: this document only.
Verification run: both workspace statuses and Claude's committed reports inspected; documentation diff checked. No application code changed and no application tests rerun.
Database deploy owed: none for this setup.
Edge deploy owed: none for this setup.
Client deploy owed: none for this document; prior client changes remain unreleased.
Open questions / risks: the after-golf contract is a proposal; Claude's regression findings still require Codex disposition; Codex branch has no upstream.
Recommended next step: Claude continues the bounded contract review above while Codex resolves the Home regression findings.


## Release checkpoint · 2026-09-12

The owner subsequently approved D343–D345 in Claude's session and handed off `040dcd2`. Codex integrated that completed branch at `05beb49`; the earlier proposal/assignment status above is historical. D343/D344 are applied, D345 is held. The owner then authorised full TestFlight preparation and function/quality inspection. Current scope, fixes, evidence and remaining release boundary: [TestFlight preparation](2026-09-12-testflight-preparation.md). The owned workspace and branch remain unchanged. Archive/export is authorised preparation; no upload or production migration is implied.
