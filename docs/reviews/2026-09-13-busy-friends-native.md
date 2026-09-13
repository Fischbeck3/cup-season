# Busy-friends setup · implementation and review handoff

2026-09-13 · Codex · D346 · base `e0643c1` on audited candidate `ca682da`.

The group can choose how often they expect to play, explicitly accept **Best 2 / no minimum**, change any existing offered rule, and read the agreement before starting. Merely changing pace never changes the rules. This is a client implementation for review, not a TestFlight release.

## What changed

- Native setup gives the two main round rules a visible home. Other supported choices remain in More settings; three/four squads and carried squad choices survive review. An unchosen structure defaults to individual competition.
- The agreement is an immutable copy of the outgoing settings. It pins the start date and uses those same dates and settings for publishing. It includes the selected minimum’s actual consequence and existing cross-client score expectations. Short seasons describe the points-table finish.
- After a confirmed create, a failed lock retains the league ID in the current wizard. Retry skips creation, keeps the same agreement and waits for lock before sending invitations. Tests exercise a failed lock followed by `already_locked`, and partial invite failures.
- Confirmation cannot run twice concurrently; dismissal cannot discard a league while publishing or after an ambiguous publish attempt. The share uses a membership read, not `1 + sent invitations`.
- Squad receipts add known ledger rows plus only the unexplained remainder. A partial ledger no longer displays the full adjustment a second time. Existing golfer → rounds → receipt navigation remains in place. A replaced monthly round is labelled “Outside monthly best.” No ranking is recomputed here.
- Web setup exposes the same explicit suggestion and consequences, preserves the payment note independently of the pot-split description, shows one Review action, and displays the selected dates even if another season’s dates remain in memory.
- Native large-text inspection found an overlapping system menu picker. The corrected menu lays out its full text; the compact-phone check exercises the menu and both review/return paths.

## Files

- `apps/ios/CupSeason/Wizard/WizardAgreementView.swift` — rules editor and agreement.
- `apps/ios/CupSeason/Wizard/WizardScreen.swift` — review snapshot, publish retry checkpoint, share membership, safe DEBUG fixture.
- `apps/ios/CupSeason/Wizard/WizardSteps.swift` — plain setup copy, main controls, review action.
- `apps/ios/CupSeason/RootView.swift` — DEBUG-only setup fixture route.
- `apps/ios/CupSeason/League/ReceiptSheets.swift` — receipt reconciliation and monthly-best label.
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/LeagueSetup.swift` — agreement and receipt presentation data.
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/WizardService.swift` — resumable publish orchestration.
- `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/WizardState.swift` — clear rule explanations.
- `index.html` — web setup and agreement.
- `LeagueSetupTests.swift`, `WizardAgreementTests.swift`, `LeagueSetupReviewTests.swift`, `tests/league-setup-browser.js` — regression evidence.
- `spec/decision-log.md`, `docs/planning/ACTIVE_WORK.md`, this handoff — decision and ownership.

No migration, RPC contract, dependency, generated source, token, brand mark or deployed version edit.

## Verification

- Simulator build passed.
- Initial native run: **1,204 tests passed**, zero failures, on iPhone 17 Pro (Kit, app and two setup UI tests).
- Compact iPhone SE (3rd generation): **2 UI tests passed**, light and dark AX3. Screenshots inspected; original picker overlap fixed.
- Final focused native run after refinements: **13 tests passed**, zero failures, on SE3. Includes actual pace-menu selection, immutable agreement/date mapping, score-contract consistency, retry ordering, partial invite failure, payment/name blocking, fixture write blocking and partial-ledger reconciliation.
- Local browser journey: 390/320px, fresh service workers/caches, editable suggestion, pace changes, selected consequences, payment validation, custom squads, chosen dates, review/back and no horizontal document overflow. No publish action tapped. **20 assertions passed at each width**, zero browser errors and zero horizontal overflow. Final agreement screenshots inspected.
- `npm run preflight`: **PASS, zero failures/warnings**. `git diff --check`: clean before commit. Existing compiler warnings and Supabase JS deprecated-lock warnings are not claimed resolved.

Local evidence (not committed): `work/setup-tests.xcresult`, `work/setup-small-tests.xcresult`, `work/setup-final-tests.xcresult`, screenshot exports under `work/setup-small-visual`, browser screenshots/logs under `work/setup-web*`. Repeat the native visual fixture with `-cs_dev_wizard_fixture`; its model blocks publication and skips setup/pricing reads. The browser audit file can be evaluated through `tools/web-verify.mjs` against the local checkout.

## Limits and next review

1. **Final conflict remains open.** The spec’s “scored fresh” promise conflicts with D212/current monthly-ranked Final eligibility. The new setup agreement discloses the current effect. Other season/Final copy still contains “scored fresh”; this slice does not resolve that product decision or all downstream wording. Do not treat it as permission to change scoring.
2. **Durable creation recovery remains a backend question.** This fixes retry after a confirmed create inside the same wizard. It does not solve an ambiguous `create_league` response, process termination or another device. Propose an idempotent create/lock contract and recovery path before promising those cases safe. Keep acceptance consent and payment-note guarantees.
3. **Existing stored settings need a separate contract audit.** `lock_league` uses `coalesce` for a null cap; resetting a non-null stored cap to Unlimited is not equivalent to creating a new unlimited league. The existing UI also maps off-ladder cap values to offered choices. Neither server behavior is changed here. Membership-count read retains its existing fallback if the read fails.
4. **No real league was created for this QA.** Failure tests use in-memory transport and UI fixtures; browser checks exercise real client state/renderers without publication. Shared Postgres scoring was reviewed, not rerun or deployed in this slice. PostgreSQL numeric remains authoritative at band boundaries.

Claude review request: review the committed branch from `e0643c1`, on your own workspace/branch, without changing Codex-owned client files. Check agreement-to-lock mapping, minimum/bye/Final facts, explicit squad preservation, create/lock ambiguity, invite consent and receipt residuals. Return findings against exact file/line and commit. Propose backend recovery separately; do not deploy or implement fresh-scored Final without its decision.

## Handoff

Branch: `codex/busy-friends-native-2026-09-13`.
Goal: build the approved busy-friends setup and audit its functional seams.
What changed: editable suggestion, exact agreement, known-create retry, honest invites, reconciled receipts, web disclosure.
Files changed: listed above.
Verification run: build, native suites/UI, mobile browser audit, preflight and diff checks.
Database deploy owed: none for this slice; prior D345 remains separate.
Edge deploy owed: none.
Client deploy owed: reviewed branch must be integrated and released; nothing sent to production or TestFlight.
Open questions / risks: Final decision; durable/ambiguous creation recovery; legacy stored cap behavior.
Recommended next step: Claude independent review, Codex fixes/integration, then a new release checkpoint when signing is available.
