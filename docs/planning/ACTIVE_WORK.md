# Cup Season · active work and ownership

## Approved Play, sharing and App Store release · 2026-09-25 (Codex)

Owner approved the morning gallery with “Looks good deploy it.” The two
reviewed commits were fast-forwarded onto main from `afd21ce2` through
`5ecc9377`, preserving the complete audit integration. **Web live; Owner
TestFlight 1.0.0 (1022) available; eight approved App Store screenshots COMPLETE
in the existing 1.0 / en-US draft.** Apple validation and upload passed; read-back
confirms VALID, Owner YES, IN_BETA_TESTING and Friends no. The app remains
PREPARE_FOR_SUBMISSION. The documentation follow-up changes no product source.

Release preflight 0 failures / 0 warnings, both GitHub CI jobs green, all eight
public-round variants passed against live web code with synthetic records.
Production ledger read confirms 274/274 migrations, none pending; no database,
Edge or secret changes by this release. Real-phone installation remains for the
owner. [Deployment evidence and handoff](../review/2026-09-25-morning/deployment.md).
Owned branch/workspace: `codex/play-share-store-review-2026-09-25` in
`/private/tmp/cup-season-morning-review`; other workspaces remain untouched.

## Selected Compete release · 2026-09-24 (Codex) — database and web live; TestFlight held

Owner requested “Push and deploy,” held TestFlight, then directed the Git deployment path. Remote `main` was fast-forwarded from `1e792793` to release `300266e4`; Netlify published it, verified at **2026-09-25 02:06 UTC** (September 24 in Phoenix). HTML and service worker both read `300266e`; signed-out startup, public routes, headers and the publish boundary pass. GitHub Client invariants/Migration hygiene and Supabase Preview pass. Production migration `20261118090000_the_book.sql` is applied: **255 total, none pending**, **37/37 production checks pass**. TestFlight is held; no ASC, archive, upload or Supabase Edge deployment. No merge commit or rebase; all repository work stays on the owned branch in `/Users/fischbeck3/cup-season-compete-explore`. This release-record follow-up changes documentation/evidence only. [Deployment evidence](../design/compete-2026-09-24/DEPLOYMENT.md). Earlier entries below are historical checkpoints.

## Compete topo correction · 2026-09-24 (Codex) — local review

Owner requested text over continuous topo after spotting the clipped ember strip. `d837a8c0` replaces the strip with a full background in the native/web Scoreboard and Book heading; D381 amended. Contrast: **4.62:1 dark / 4.97:1 light** over the strongest ember stroke. Debug build, four Book UI tests, 58 Node tests and preflight pass. The selected gallery's 36 simulator captures are refreshed; the preceding version is preserved in `selected-before-topo/`. [Evidence](../design/compete-2026-09-24/SELECTED-VERIFICATION.md#owner-topo-correction--september-24). Same isolated branch/worktree; local commits only. No database, Edge or client deployment performed, and no additional deployment requirement introduced.

## Selected Compete build · 2026-09-24 (Codex) — built and verified locally

Owner approved **Scoreboard + the Book's Weeks view, with Race inside the Book**, including normal native/web app code and one local, unapplied read-contract migration (D381). Work remains only in `/Users/fischbeck3/cup-season-compete-explore` on `codex/compete-explorations-2026-09-24`. The Book has authoritative weekly/cumulative totals, golfers/squads/contributions, named receipts and reasoned adjustment rows. Small leagues keep Rounds & points. The shared 41–41 points rank and ember-label contrast are fixed. No scoring mechanic changed.

[Selected build and deployment dependency](../design/compete-2026-09-24/SELECTED-BUILD.md) · [original proposal](../design/compete-2026-09-24/PROPOSAL.md). Gallery: `/Users/fischbeck3/cup-season-compete-explorations-review/index.html`; original 564 captures remain historical, with a separate Selected build section. The selected section adds **36 new simulator captures**, both printings, SE/standard and standard AX3. **1,520 distinct native tests pass** across the final relevant runs; Node **58 passed**, preflight **0 failures / 0 warnings**, Debug build green, and fresh local PostgreSQL contract checks pass. [Verification and retained failure output](../design/compete-2026-09-24/SELECTED-VERIFICATION.md). Implementation commits `49c219ea`, `bfe9a27b`, `f5f2a5db`. Everything remains unpushed. Migration `20261118090000_the_book.sql` is verified only in isolated local PostgreSQL. **Database and client deployment/distribution remain owed after separate approval; Edge: none.** The design rulings are settled; historical snapshots and very-large-field pagination remain separate future work.

## Compete explorations and the Book · 2026-09-24 (Codex) — local owner review

On `codex/compete-explorations-2026-09-24` in `/Users/fischbeck3/cup-season-compete-explore` only. Three working DEBUG directions behind `-cs_dev_compete_exploration`: **Scoreboard** (ember points board), **Race** (points across the season on livery terrain), and **Broadsheet** (dense season/field comparison). The **Book** adds weekly and cumulative points, squads/golfers, squad contributions, a race and receipts, including dropped rounds and reasoned adjustment rows. No money. Small solo seasons get “Rounds & points.” Release keeps the shipped root and startup behavior.

[Proposal, ranked recommendation and owner rulings](../design/compete-2026-09-24/PROPOSAL.md) · [verification and failure history](../design/compete-2026-09-24/VERIFICATION.md). New local gallery: `/Users/fischbeck3/cup-season-compete-explorations-review/index.html`; **564 fixture-only simulator captures**, audited with all **324 required combinations**, cover light/dark, standard/SE and standard AX3. Native checks **1,505 passed**, preflight **0 failures / 0 warnings**, Debug build green. Brief committed first as `788dd5b`, prototypes as `9959c620`; everything is **local and unpushed**.

Owner to choose the direction, live-only ember versus F11’s broader scope, Scoreboard’s proposed monochrome topo exception inside its ember band, the proposed **10 golfers or squads** Book threshold and small-league fallback, “counting today” versus historical snapshots, and shared points-rank / qualification-seed / final-tiebreak semantics. Recommend Scoreboard with the Book’s Weeks view, then Race, then Broadsheet. Naming is settled: **the Book**.

Found and documented without changing shipped code: the home rank window splits equal points by name while the season table ties them; `LeagueRecord.finish` also uses row position. Shared `CSFigure` labels over ember fail small-text contrast. No migrations, generated assets, production data or other worktrees changed. **Database / Edge / client deploy owed by this exploration: none.** Production implementation awaits the owner’s choice and an approved read contract.


## Owner beta release · EXECUTED 2026-09-23 03:13–03:23 UTC (Claude, on the Mac) — `claude/owner-beta-release`

Both approvals executed exactly as recorded, from a clean worktree of this
branch (`/Users/fischbeck3/cup-season-owner-beta`), after steps 0 and 1
matched the packet on every line. The command-by-command record with
timestamps and read-backs is in the [Owner beta packet](2026-09-22-owner-beta.md#executed-on-the-mac--2026-09-23-0313-0323-utc).

| Layer | State | Evidence |
|---|---|---|
| **Database** | **254 applied, none pending**, latest `20261117090000`. `20261116090000` and `20261117090000` pushed 03:16:01Z by `supabase db push` (ledger records both). | Probe read `2 · t · f · f · t · f · 1`; `tests/db-checks.sql` **37/37 PASS** against production 03:17Z |
| **Edge** | `courses` **version 19** (03:16:40Z), deployed after the cache RPC existed. Nothing else touched. | `supabase functions list` |
| **Owner (TestFlight, internal)** | **1.0.0 (986)** from `37f959e`, the exact validated IPA (sha256 `a9de87cf…af87d`, 19,965,012 bytes): VERIFY SUCCEEDED 03:19:02Z, uploaded **once** 03:20:31Z (delivery `80f0393a-dc5e-427d-916b-ba7c671c543a`), VALID, What to Test set, added to Owner (204). Read-back: **in Owner YES · internalBuildState IN_BETA_TESTING · in Friends no**; Owner holds 7 builds, newest 986. **Available to install; the phone is not confirmed updated until the owner reads 986 on the device.** | `tools/asc.py owner 986`, then `status 986` |
| **Friends** | unchanged: newest **795**, 9 builds. 986's external state is READY_FOR_BETA_SUBMISSION, i.e. not submitted. | `tools/asc.py groups` |
| **Live web** | unchanged: `v23 · 1e79279` = `origin/main`. This branch's 38 commits are **not** on main. No merge, no Netlify, no public link. | `curl` + `deploy-status` |

Not done, by scope: main merge, Netlify, Friends, Beta App Review, App Store submission. Next: the phone checklist in the packet (rows 1–5), recorded PASS/FAIL by the owner.

### As approved (2026-09-23 03:09 UTC, remote) — history

Approved, not yet executed. The owner approved **A** (`20261116090000` +
`20261117090000` by `supabase db push`, then `courses` only) and **B**
(validate, upload once and distribute to internal **Owner** only the exact
**1.0.0 (986)** IPA from `37f959e`, sha256 `a9de87cf…af87d`) at 2026-09-23
03:09 UTC, after one batched question. This session ran in a remote Linux
sandbox with no IPA, `altool`, App Store Connect key or `supabase` CLI, so
**nothing was applied, deployed, validated, uploaded or distributed**; a local
Mac session runs the recorded runbook under those approvals.

| | State |
|---|---|
| **Verified here (read-only)** | Candidate unchanged: the three commits after `37f959e` are docs-only. Production ledger 252, latest `20261115090000`; pending set is exactly the two files; neither applied out of band (no `cache_course_card`, share helpers JPEG-only, no `shared_copy_read`). |
| **Found** | Build 986 refuses to make a round link until `20261117090000` is live ("Round sharing needs the latest update") — safe, but the phone's share/photo-consent checks need A first. The live web stamp, `courses` version, secret names and App Store Connect state were not readable from the sandbox. |
| **Added** | `tools/asc.py builds`, `groups` (read-only) and `owner <build> "notes"` (Owner-only add with VALID polling and availability read-back; refuses if Friends is unreadable or already holds the build; never submits for review), exercised against a mocked API in seven scenarios. The runbook, approvals and phone checklist are in the [Owner beta packet](2026-09-22-owner-beta.md). |
| **Deployed / uploaded** | **Nothing.** Database, Edge, Apple and the web client are unchanged by this session. Friends and public release remain closed. |
| **Preserved failures** | 1,508 / 1 native: the standard-phone share-cancellation check failed once (sheet visible after the close tap); small-phone and two later standard runs passed; one retry failed to open the DEBUG fixture. Not relabelled green; checklist row 1 on the phone. |

## Tonight's Owner beta · 2026-09-22 (Codex)

The owner requested a beta on their phone tonight with the recent work.
`codex/october-visual-ui` now integrates Claude's W6 correction tip `8f632ed`
through merge `9d9ef46`. Codex prepared and signed **1.0.0 (986)** from `37f959e` with the shared
field contrast, full Home lead color role and exported card header fixes.
Archive/export and signature inspection passed; Apple validation was blocked
by automatic approval review before transmission and awaits explicit approval
for validation, upload and internal Owner distribution. The [Owner beta packet](2026-09-22-owner-beta.md) records scope,
evidence, remaining UI work and phone checks. Production migration/Edge
approval is pending; the candidate is for internal Owner feedback. The
Friends gate and public launch gates remain unchanged. The older dirty
visual checkout has not been changed.


## Visual UI sprint · 2026-09-22 (Codex)

The owner assigned Codex the visual UI sprint and execution. Owned branch
`codex/october-visual-ui`, isolated from the older dirty visual checkout, starts
from `82cb92f` and preserves the Mac verification and W6 work. Codex owns web
and native visual presentation; Claude's independent next lane remains W6
reporting corrections. Avoid concurrent edits to the visual branch or its UI
files. The [visual sprint](2026-09-22-visual-ui-sprint.md) inventories every
screen family, dates six slices through September 28 and leaves September
29–30 for human evidence and release corrections. V1 fixes entrance contrast,
public-page theme defaults, support touch targets and native invitation
context. Local evidence and outstanding checks are recorded in that plan.
D358/D359/F11 govern the mark and color roles where older summary guides
conflict. No database, Edge, production or Apple action is part of this pass.

## W6 correction pass · 2026-09-22 (Claude, remote) — on `claude/october-w6-fixes` from `82cb92f`

The six corrections in [the W6 review](2026-09-22-w6-review-and-claude-prompt.md),
in order, each reproduced on the `82cb92f` code first. Old answer beside new
answer, per finding: [`docs/pilot/examples/w6-reproduction.md`](../pilot/examples/w6-reproduction.md).

| | State |
|---|---|
| **Implemented** | (1) `assistance_weekly`: per local week and cohort, assisted / unassisted / UNKNOWN completions, a completion = one finished real game (cards shown beside), STOP · UNKNOWN · ok · no activity · not gated. (2) Checkpoints judged only on dated App Analytics readings (`docs/pilot/appstore-readings.csv`, new, header only); weekly log rows are labelled subtotals with coverage; duplicate keys rejected. (3) One `--as-of` + `--tz` → one `:CUTOFF` in every SQL section and the CSVs; local Monday weeks; `_now` columns labelled; a future date refused unless `--synthetic`. (4) One `ELIGIBLE` population and one `REAL_GAMES` rule for every account, round and game count; events (`activation_weekly`) apart from the signup funnel (`activation_cohort`); a guest seat is account-less at play, never "has a token". (5) Real calendar dates, Sunday weeks, digits-only counts, strict flags, an RFC-4180 parser with line-numbered diagnostics, the `--store-live false` contradiction; nothing throws. (6) The attribution writer traced and left alone; the inbox entry closed as wrong; the first-event platform labelled a proxy with `first_event_unlabelled`. Also: `apply.sh` runs the chain on PG16 (env overrides; Mac defaults unchanged). |
| **Tested — locally, this sandbox** | `tests/growth-report.test.mjs` 21/21 · `tests/pilot-scorecard-cli.test.mjs` 9/9 · `tests/attribution-trace.test.mjs` 7/7 · `tests/pilot/scorecard-db.test.mjs` 17/17 on synthetic fixtures in a disposable copy of the full 254-migration chain (PG16; skips without a sandbox, so CI runs the first three). Preflight **0 failures, 0 warnings**; the full Node suite **74 of 74** (every `tests/*.test.mjs` and `tests/pilot/*.test.mjs`, the sandbox half included) and `sunningdale.test.mjs` 27 assertions. Not run here: the native suites (no Swift change) and the in-browser suite (no client change). |
| **Read on production (SELECT only)** | Every corrected section executed on the linked project, report date 2026-09-20; nothing saved as a report. It showed two earlier W6 figures were artefacts: the Aug 24 week's "8 accounts, 9 first, 9 second rounds" are 8 test-seed accounts and the App Review account (eligible: 0); "35 guest seats minted, 0 claimed" were member and visitor seats carrying the default token (account-less guest seats in real games: 1, claimed). |
| **Deployed** | **Nothing.** The report is a tool, not a client surface; no migration, function or client changed. Owed as before: `20261116090000`, `20261117090000`, then `courses`, then the reviewed clients. |
| **Synthetic examples** | [`docs/pilot/examples/`](../pilot/examples/README.md): the full report on the fixtures (STOP / UNKNOWN / ok rows; the October checkpoint met on a reading; a missing week and rejected rows) and five acquisition scenarios (complete · partial · failing · missing · contradictory). Labelled SYNTHETIC in every title; no number in them is real. |

**Owner inputs still missing (not invented here):** cohorts in `pilot_cohort_members`; sessions in `pilot_sessions` with end times and golfers or ids; the weekly acquisition rows; App Analytics readings once the listing is live (none can exist before approval); a real claim on a release build read back from `profiles`; the two-phone gates; the deployments above. The first saved real report is generated on Tue Sep 29, dated **Sun Sep 27**, from what production holds then — never written ahead.

## W6 review · 2026-09-22 (Codex)

Reviewed Claude's `5404978`, which preserves the Mac's `f49756d`. Preflight 0/0
and all 29 Node checks pass, but W6 still needs reporting corrections before
acceptance: the weekly assistance gate counts all completions, incomplete or
duplicated log rows can generate false checkpoint statuses, reporting dates
are inconsistent, activation populations differ, and malformed dates can
crash. The attribution writer claimed absent in the inbox already exists in
the RPC with callers on both clients; null values require diagnosis, not a
second writer. Findings, reproductions and the next Claude prompt are in
[the W6 review](2026-09-22-w6-review-and-claude-prompt.md). This is a
documentation review; no product code, production data or deployment changed.
Continue the correction pass now while owner inputs and device gates remain
pending.

## THE RELEASE RECORD · verified 2026-09-15 night (this section is the one record; the sections below are history)

Verified from the systems themselves on 2026-09-15, not from prior reports. "Implemented", "tested", "deployed" and "available to testers" are kept apart.

| Layer | State | Evidence |
|---|---|---|
| **Owner candidate (TestFlight, internal group "Owner")** | build **934** from commit **`1aac23a`** (branch `claude/pilot-readiness-2026-09-15`), uploaded 2026-09-16 from the validated IPA (sha256 prefix `579b0cbc4306410f`, no rebuild), processing VALID, internal state IN_BETA_TESTING, attached to Owner (HTTP 204; Owner holds 6 builds: …905, 919, 932, 934). **Available to the owner to install; the phone is NOT confirmed updated until the owner installs 934 and reads the build number on the device.** | App Store Connect API, read back 2026-09-16 |
| **Friends (TestFlight, external group)** | latest build **795** (DesignV1 identity, 2026-09-12); 9 builds in the group. **932 is NOT in Friends.** External state of 932: READY_FOR_BETA_SUBMISSION, i.e. not submitted for external review. | App Store Connect API |
| **Live web (cupseason.app)** | stamp `v23 · c6acc53` = `origin/main` tip. The 21+ commits on `claude/phone-fixes-2026-09-15` and this branch are **not** on main and not live. | `curl` of the live page + `git log origin/main` |
| **Database (linked project)** | **246 migrations applied**, latest `20261107090000` (both pilot-readiness migrations applied 2026-09-15 night under the owner's "push remaining items"; verified read-only: owner-read policy on `round_holes` present, `round_tally` requires readable holes, `pilot_cohort_members` and `pilot_sessions` exist with RLS on, `client_events_one_attempt` present). **Nothing pending.** | `supabase db push --linked` + read-back |
| **Edge functions** | 6 deployed, none stale, nothing pending. | `tools/deploy-status.mjs` |
| **Newest build in Friends** | still **795**; 934's external state is READY_FOR_BETA_SUBMISSION, i.e. not submitted. Friends unchanged. | App Store Connect API |

### Addendum · 2026-09-21 (Claude, remote)

- The owner ruled all fourteen launch decision points — **public launch: App Store submission on 2026-10-01, open outreach the same day** (D371–D379, `docs/planning/2026-09-21-launch-rulings.md`; appended to the decision log on branch `claude/elegant-curie-x15hps`, which is based on PR #6's tip `6c9712d`). The ten-day plan is `spec/launch-readiness-2026-10-01.md` §4A.
- On that branch, **pushed to production 2026-09-22 and not yet merged**: `20261112090000` (D378 bundle), `20261113090000` (D376, the Pro's pen), `20261114090000` (D371's door counter) and `20261115090000` (D375, season two is a re-up) — validated on a Postgres 16 sandbox running the full chain (18 + 32 functional probes), pushed by the owner with PR #6's `20261109090000` and `20261110090000`, and read back from production's ledger. Still branch-only until the merge: the web halves of D373, D374, D375 and D376; the legal v2 draft (D379), operator name confirmed; this file's corrections.
- **Owed today (D372):** the two revokes pushed from the PR #6 checkout; PR #6 merged by 17:00 Phoenix after the iPhone Safari walk; a build to the Owner group; Codex pointed at the branch above.
- Corrections to the history below: `20261024090000` is **applied** (the "held" line was a coordinator note that did not hold — `20261102090000`'s header, D353b); `index.html` has been edited by Claude since the 2026-09-13 override, and D372 records the merge override.

### Addendum · 2026-09-22 (Claude, remote)

- PR #6 and PR #7 (`claude/elegant-curie-x15hps`) are **merged** to `main` (05:55–05:56 Phoenix); PR #5 closed as subsumed. `main` = `1e79279`: the pilot-readiness work, the rulings, the four migrations, the web halves of D373–D376, the legal v2 set. CI now runs every unit file and the real stamp build; preflight and the five unit files pass on the tip. The 09-21 line "not yet merged" is history.
- Production: the six migrations are recorded (252, latest `20261115090000`), read back 2026-09-22. Codex's `20261111090000` and the `courses` change remain Mac-only — the one owed database/edge item, migration first, function second.
- Owed on the Mac, verified from the tree by grep: the Swift halves of D373 / D374 / D375 / D376 / D378 (vii) (no caller of `Rpc.adjustPoints`, no unfinished-link face, no re-up copy — `Rpc.swift` is regenerated and carries the names); a build from the merged tip (934 is `1aac23a`, pre-merge); the two-phone checklist. Live web stamp not reachable from the sandbox — confirm `v23 · 1e79279` on the Mac.
- The execution view from today and the local session's prompt: `2026-09-22-october-launch-execution.md`, `2026-09-22-claude-october-launch-prompt.md`.
- **Revised the same day** on the owner's instruction: the objective restored in full — the Oct 1 public launch and submission, and **5,000 first-time App Store downloads by 2026-12-31** (500 by Oct 31 · 2,000 by Nov 30 · 5,000 by Dec 31, cumulative; TestFlight installs and web sign-ups never count; every acquisition assumption labelled unverified), supported by unassisted real rounds and repeat groups. Six workstreams with owners and acceptance criteria (timed comprehension tests · one round-sharing action · the claim and invitation recipient journeys · install-then-reopen, no deferred linking · `/get` and `/support` pages · five-section weekly reporting). Protocol corrected: a dedicated `claude/october-launch` branch in its own worktree from `main`; baseline reported, then the work without an extra "go"; production and Apple approvals unchanged; D376's web-only exception confined to the adjustment tool; the latest Apple builds and groups read, not the record; missing evidence told apart from confirmed absence; Codex's `20261111` validated in the applied order (rename to sort after `20261115` before the push). The two-phone gate and the scope cuts stand. Nothing deployed.
- **Refined the same evening:** production's migration ledger is read before `20261111` is renamed (`deploy-status` cannot see an applied version with no local file), and an applied migration is preserved as applied; photo consent governs the exported image, the public share page and the link preview, including on a reused token (`PostService.shareLink` uploads the copy on its own today; `share_info.photo` is `exists(copy)`); two claims corrected to missing evidence — a post-merge build may exist, and hardware results are unlocated rather than "never run"; the owner's weekly acquisition pipeline (prospects contacted · organizers activated · groups playing · first-time downloads by channel) with a review by 2026-10-15; implementation keeps moving while owner actions or approvals are pending.

### Addendum · 2026-09-22 evening (Claude, remote) — the launch sprint's first session, on `claude/october-launch`

- **Branch, not production.** `claude/october-launch` (worktree from `main` at `1e79279`, the three planning commits brought in) carries: the Swift halves of D373, D378 (vii), D374, D376 and D375 — one commit each, built against the current server contract and the web's pinned producers; the course-cache packet (`2026-09-22-course-cache-deploy.md`) with the `flattenTees` coercion; `/get` and `/support` with their routes and allowlist; the timed-tests protocol and the W2 share-action proposal. **Nothing deployed; nothing uploaded; no PR opened.**
- **Ladder, honestly.** Every Swift slice is *implemented*, not *locally verified*: this sandbox has no Swift toolchain (swift.org is blocked here), so preflight's Swift lints are the only check that ran; the Kit suite, the app suite and a build to a phone are the first thing the Mac session runs. `/get` and `/support` are *locally verified* (the real `stamp-version.sh` build, links resolved, served 200); the Netlify rewrites are verified on the preview after the push. The coercion in `courses/index.ts` is *implemented*, not run (no Deno).
- **Read from production, read-only, 2026-09-22:** the ledger carries `20261109`–`20261115` and **not** `20261111`; no atomic course-cache RPC exists. The file lives only in Codex's local workspace; the packet says how to recover it under `20261116090000`.
- **Missing evidence, still:** the live stamp (egress blocked from here); the latest TestFlight builds and both groups; any hardware run of `owner-checks.md`.

### Addendum · 2026-09-22 night (Claude, remote) — the correction pass on `claude/october-launch`

- Codex's build-for-testing stopped at `LiveClaim.swift:93` (an await inside `??`'s autoclosure). Fixed with an explicit conditional load; the model's no-season error is its own `LocalizedError`; the receipt's ruling rows render whether or not there is round history. **Still not natively verified** — this is the remote sandbox; the Mac runs the build and the suites next.
- `courses/index.ts` normalization moved to `normalize.ts` and tested (6 of 6, `node --experimental-strip-types --test`, in CI): null stays null, booleans never become numbers, the hole count falls back to the holes listed, else null — no invented zeroes.
- `/get` no longer points at Apple's generic TestFlight page; the iPhone button exists only when a real invitation or store link is pasted into its `data-href`. Both pages on the design tokens; reviewed at 390px, both themes, in headless Chromium.
- **W2 built on both clients under the owner's ruling (Option A, D380):** one Share from a posted round, the card and the link together, the photo only on a yes, the copies following the answer on a reused token (re-mint), the preview preferring the card. Desk: preflight passes, the eight new pins pass in headless Chromium; the full in-browser suite cannot finish here (the module block's CDN is blocked). Phone: implemented, not built.
- **Not done here, by nature:** the course-cache migration and probes from Codex's local `39c8d00`, the PG17 chain and the reapply-on-populated-sandbox test; every native build and suite; the device runs.

### Addendum · 2026-09-22 (Codex, Mac) — verified from Claude's `4a171f7`

- Own worktree and branch: `/private/tmp/cup-season-october-mac`, `codex/october-launch-mac-verification`. Claude's stopped branch and the owner's existing worktree were left untouched. Full evidence and next-session instructions: [Mac verification handoff](2026-09-22-october-mac-verification.md).
- **Native is locally verified:** 1,235 Kit tests, 120 design tests, 122 app tests and six focused UI tests passed. Fixed the actual share-sheet cancellation failure and the re-up test's missing fixture facts. Inspected simulator evidence for share opt-out/accessibility, the ruling sheet and the re-up covenant. Physical checks and Apple actions remain owed.
- **Recovered and locally proved:** `39c8d00`'s migration, unchanged apart from its filename `20261116090000_course_cache_atomic.sql`, integrated with provider normalization. PG17 applied all 254 migrations, zero skipped; cache probes, the reapply on that same populated database, and the standalone regression passed.
- **Additional W2 release dependency found and fixed:** JPEG-only storage helpers rejected PNG cards and no shared SELECT policy exposed existing copies. `20261117090000_shared_card_consent.sql` adds owner-only PNG/JPEG support and reads; authenticated-role probes pass. Clients guard rollout, stop on consent read/delete/revoke failures, and replace potentially photo-bearing PNGs on opt-out. D380's amendment records the correction. Preflight and all 20 Node checks pass.
- The complete in-browser function suite also passed here: **489 checks, zero failures**, after cache/SW reset. Fixed the build script's GNU-only `sed -i` invocation; the real allowlisted build now passes on macOS.
- **Nothing deployed, merged, archived, uploaded or submitted.** Two database migrations are now owed, then `courses`, then the reviewed web/native clients; see [deployment packet](2026-09-22-course-cache-deploy.md). Real Storage API consent proof, the two-phone gate, current live/Apple state, the actual installation URL and W6 reporting remain open.

### Addendum · 2026-09-22 late (Claude, remote) — W6 and the gate documents, on `claude/october-launch-w6` from Codex's `f49756d`

- **W6 built.** `tests/pilot/scorecard.sql` gains five sections — `sharing` (the growth funnel's first reader), `sharing_outcomes` (guest seats minted and claimed, invitations sent and answered), `activation_weekly` (accounts → first posted round → second → finished games, by week), `signups_by_door` (the first client event's platform: web, the iOS app, or `unknown` — an account, never an install), `assistance_by_cohort` (the stop condition's own numbers, `@pilot`). The runner reads the owner's `docs/pilot/acquisition-log.csv` (counts only) and prints first-time App Store downloads, TestFlight installs and web sign-ups in three columns that are never summed, a — for a week not logged and 0 only for a logged 0, the 500 / 2,000 / 5,000 checkpoints as met, missed, open or missing, downloads by channel, and no forecast. `--no-db` renders the log alone; `CS_PG_BIN` points the sandbox at another psql.
- **Evidence.** Every new section executed read-only against production on 2026-09-22 through the Supabase connection (no writes): the funnel shows 2 shares and 6 link opens in eight weeks, 35 guest seats minted and 0 claimed, 0 invitations, 8 accounts in the week of Aug 24 with 9 first and 9 second posted rounds, every account's door `unknown` (no first event carried a platform), both pilot tables empty. **Corrected by the W6 correction pass above:** the 35 seats and the 8 accounts / 9 rounds were measurement artefacts (default claim tokens on member seats; test-seed and App Review accounts outside a shared eligible population). `tests/growth-report.test.mjs` 9 of 9; the no-database run renders. The first saved report is Tuesday's, on the Mac.
- **The gate documents.** `docs/planning/2026-09-22-release-checklist.md` lists every gate with the evidence it needs and who supplies it; none is passed. `docs/pilot/recipient-journeys.md` scripts the claim link, the season invitation and the re-up as the recipient, and the share consent proof as Storage API and `share_info` reads on the release build against production — never a mock or a simulator. `weekly-review.md` and `timed-tests.md` point at both.
- **Nothing deployed, merged, uploaded or submitted.** The two migrations, `courses`, the device runs and every Apple action remain the owner's.

### Known issues (as of 2026-09-15)
- A seated non-starter cannot finish a league-less round; the host (or a league member seat) must. By design (D107), told to testers. `tests/pilot/authz-flow.py` NOT VERIFIED line.
- Historical rounds carry no par provenance and therefore show no birdie/eagle tally — including the owner's own 2026-09-15 round. Honest by design (Codex S3).
- Production `client_events` holds 9 `client_error` rows in the last four weeks: 8 native crash reports (SIGTRAP/SIGABRT) on 2026-09-03 from the pre-905 era, and 1 native SIGABRT on 2026-09-11. The 09-11 row and half of the 09-03 rows carry build `1` — an unarchived local Xcode run, not a tester's build; the rest carry 669 (pre-905). No crash on 932 is on record.
- Production posting baseline: of 8 live games finished in 12 weeks, 2 posted nothing and none of the account-less guests claimed. The pilot task sheet asks for the claim path explicitly.
- The web has no plan-suppression cache reset on sign-out beyond account keying (Codex R2 closed by keying per account + invalidation on finish).

### Outstanding device checks
- The two-phone lifecycle and recovery checks in `docs/pilot/owner-checks.md` (A1–A11, R1–R7, G1–G2) are **NOT RUN** on physical phones. The simulator is signed out (erased earlier for a stale DerivedData fix), so the signed-in native walkthroughs (+ chooser, invitation states) were verified from code and on the web only.
- `ComposerWorthUITests` (3) remain blocked on the simulator sign-in OTP.
- Scorecard baseline refreshed 2026-09-16 with the pilot tables present: `docs/pilot/scorecard-2026-09-16.md` — the cohort table is EMPTY, so the cohort sections print no rows until the founder names cohorts (`docs/pilot/session-log.md`).


Updated 2026-09-13. One queue for the next expansion. This records assignments and gates; it does not configure automatic agent-to-agent messages or monitoring.

## Brand and parity sprint, and the next gameplay sprint · 2026-09-14

- Claude's owned branch: `claude/brand-client-parity` (PR #4, preview on every push). Web preview and TestFlight state in [the release handoff](../reviews/2026-09-14-release-handoff.md); the per-surface ledger in [the parity ledger](../reviews/2026-09-14-brand-client-parity-ledger.md).
- The owner's seven ratified decisions are D358/D359; the compact no-photo scorecard and Home's one-fact-one-place audit are D360; Home photograph stability is D361 (`spec/decision-log.md`).
- **Evening checkpoint 2026-09-14:** [frozen at `714609b`, build 905 internal](../reviews/2026-09-14-release-checkpoint-evening.md). The first gameplay increment (D362) is built on the desk after it and prepared for the phone behind `20261104090000` (validated in isolation, **not applied**).
- **Next gameplay sprint, proposed and not dispatched:** [four candidates, one recommendation](2026-09-14-gameplay-sprint-candidates.md) — run B ("why the next round matters") with A's first increment, then C behind the season-two consent decision. Nothing from it is in the current release; its migrations are named, none applied.

## Parallel delivery and phone review · owner direction 2026-09-13

The owner is away from the Mac and uses mobile web to track progress. This is a standing delivery requirement for future milestones: pair web/native scope, and provide a verified working HTTPS phone preview at each review checkpoint. Native signing must not block web review. A local artifact or source commit alone is not delivery.

Claude builds the next bounded slice while Codex reviews the previous committed checkpoint in an isolated workspace. Claude remains the sole web implementation editor and fixes review findings. This records the collaboration process; no automatic messaging or monitoring is configured.

Current handoff: Claude's D339 inventory `ef4f1b7` is reviewed and incorporated on the Codex audit branch. [Review corrections and delivery acceptance](../reviews/2026-09-13-d339-web-half-review.md) govern the next build. Status: **ready for implementation; no new app preview produced**. Fixes and identity changes remain separate commits; the first identity preview must include the narrow phone masthead. Next output should be a working build/link, not another inventory-only packet.

## Current mobile-web catch-up override · 2026-09-13

This section supersedes the historical release status and ownership assignments below for the current packet.

- Live web audited: `963d0e6`; release evidence checkpoint `eca1b3c`. Release evidence records 242 production migrations, latest `20261103090000`, and native archive 857; TestFlight export/upload remains blocked separately by distribution signing. See [release evidence](../reviews/2026-09-13-release-evidence.md).
- Owner requested an audit after finding mobile web visually behind, with Claude continuing as lead builder.
- Codex audit: `codex/mobile-web-audit-2026-09-13`, `/Users/fischbeck3/cup-season-mobile-web-audit`. [Findings](../reviews/2026-09-13-mobile-web-experience-audit.md): the actual Compete creation link is dead; Home, Compete, season, posting and setup need focused responsive refinement.
- Next packet: [mobile Safari experience sprint](2026-09-13-mobile-safari-experience-sprint.md). **Ready for Claude; not dispatched.** Claude owns `index.html`, related web tests and implementation fixes on a new owned branch. Codex owns independent review and integration/device verification. This explicitly supersedes the default web-editor row for this packet.
- No application source or production deployment changed in the audit. Actual iPhone Safari acceptance remains owed; mobile-width Chromium checks are labeled as such.
- Identity half, kept separate (Claude, 2026-09-13): D339's beta identity shipped natively only; [D339 · the web half](2026-09-13-d339-web-half.md) inventories every surface, reconciles with the Safari sprint, and asks for one ruling (does the web show the beta identity?) before its first checkpoint I-1 (door + sidebar brand, copy + mark). Branch `claude/d339-web-half`; nothing built; frozen release unchanged.

## Current release override · 2026-09-13

Owner requested both phone surfaces, Safari first. The historical baselines below are retained as history, not the current release candidate.

- Integration: `codex/today-release-2026-09-13`, `/Users/fischbeck3/cup-season-today-release`.
- Claude implementation lead completed `99549ca` on `claude/release-fixes-2026-09-13`; integrated and independently audited. Codex now owns final edits, QA and release. Claude is idle.
- R1 posting/setup/invitations/month facts and R4 snapshot/widget work are implemented. R2 complete-week and R3 competition chapters/event renewal remain explicitly scoped in [today's sprint](2026-09-13-today-release.md).
- Eight reviewed migrations applied to production; readback 239 total, latest `20261101090000`, D345 absent. No Edge or Vault changes.
- Safari `25458ff` is live and verified. Native build 835 archived; export is blocked by Apple cloud-signing permission and absence of a distribution identity. Build 815 is superseded and must not be uploaded. See [release evidence](../reviews/2026-09-13-production-release.md) for final delivery state.
- Do not run a blanket database push: `20261024090000_the_loop_has_a_closing_act.sql` remains held pending capability protection. **[Corrected 2026-09-21: it is applied — the hold did not hold; `20261102090000` gates the band on a client capability instead. History, not instruction.]**

## Baselines and current state

- Audited candidate: `ca682da`, build 815. Keep it unchanged while Apple distribution signing is unavailable. Latest Claude handoff reviewed: `b2dac7e`; no signing issue is a reason to deploy D345.
- Current planning workspace: `/Users/fischbeck3/cup-season-vision-next`, branch `codex/vision-next-2026-09-12`, based on `ca682da`.
- Codex's release workspace and Claude's existing workspace retain their owners. Do not switch or edit another agent's branch. A new implementation branch starts from the explicitly agreed integration checkpoint.
- First execution checkpoint completed: interactive prototype/brand proof and an independent Claude C0 review. Production implementation had not started at that checkpoint. The 2026-09-13 busy-friends client slice below is now implemented on a separate review branch. See `docs/reviews/2026-09-12-next-checkpoint.md` for evidence and findings disposition.
- Claude C0 ran to completion in `/Users/fischbeck3/cup-season-next-loop-contract`, branch `claude/next-loop-contract`, base `205a0ef`. Its report is imported unchanged with attribution; that bounded process has finished.

## Ownership defaults

| Responsibility | Builder / final editor | Independent review |
|---|---|---|
| Product journey, prototypes, native UI, accessibility | Codex | Claude checks factual/contract consistency; owner judges experience |
| Web client `index.html` | Claude, under the 2026-09-13 override and D372 (corrected 2026-09-21 — the row said Codex while every September commit was Claude's) | Codex reviews the committed diff; do not split the single file between active builders |
| SQL migrations, grants/RLS, shared ranking and copy producers | Claude | Codex exercises actual RPCs and client compatibility |
| Course Edge Function / selected-course contract | Claude | Codex verifies selection and failure paths |
| RPC contract source `packages/db/contract.psv` | Claude supplies the agreed contract checkpoint | Codex reviews and runs the source generator during integration; never hand-edit generated Swift |
| Tokens, CSDesign, mark source/generator, brand application rules | Codex | Claude checks meanings/consistency and guards; owner approves material brand choices |
| Canonical vision, decision log, inbox, this queue | Codex as integrator | Claude drafts proposed entries in its own task packet; owner settles product decisions |
| Release integration / native artifact | Codex | Claude independently verifies exact candidate and may export/upload when expressly assigned |
| Production DB / Edge / account-level changes | Named release operator with explicit owner authorisation | Other agent checks exact planned changes and verifies the deployed layer |

This is a file-ownership rule, not a claim that one agent is intrinsically better at a domain. Change ownership explicitly when a task warrants it. Reviewers return findings; the builder fixes its own code. Both agents own quality in their assigned work.

## Queue

| ID | Deliverable | Owner | Status | Dependency / completion proof |
|---|---|---|---|---|
| V0 | Expanded vision, evidence-based roadmap, ownership brief | Codex | Direction accepted; expansion language remains draft | Planning commit `205a0ef`; owner approved first execution checkpoint |
| C0 | Independent critique + exact week-loop contract packet | Claude | Review delivered; contract proposals not yet agreed | `docs/reviews/next-loop-contract.md`, base `205a0ef`; static review only |
| B0 | Pennant application and symbol-role proof sheet | Codex | Prototype ready for visual selection | `docs/prototypes/next-week.html`; final D339 decision still open |
| B1 | D339 web half — door, masthead, brand copy, shared artifacts | Claude plan / owner ruling | Proposed; plan committed | [plan](2026-09-13-d339-web-half.md); needs decision 0 (beta identity on web); I-1 after Safari checkpoint A review |
| P0 | Complete-week interaction prototype | Codex | Review delivered | 21 checks at each of three widths; see checkpoint review |
| Q0 | Reproduce/repair native draft restore and seed protection | Codex | Recommended next; not started | C0 F2; model-level test before fix; isolated implementation branch |
| C0a | Minimal D345 context, typed answer and capability proposal | Claude | Recommended next; not started | C0 + Codex disposition; preserve approved per-plan semantics; no deploy |
| C1 | Course search/detail and bare-course behavior | Claude backend / Codex clients | Proposed | C0, accepted scope, named Edge deployment gate |
| C2 | After-golf answers and safe draft continuity | Claude backend / Codex clients | Proposed | C0; decision before new linkage semantics |
| Q1 | Integrated complete-week audit | Codex + Claude independent review | Proposed | C1/C2; same commit, both clients, real RPC and UI evidence |
| R1 | Existing Record extended into a season chapter | Codex prototype / Claude facts | Later proposal | Q1; sparse-data and privacy proof |
| G1 | Existing invite/guest/renewal continuity | Codex clients / Claude contracts | Later proposal | Core loop and chapter evidence |
| N0 | Widget, Live Activity and notification structure | Codex surfaces / Claude events | Design proposal; no activation | `docs/planning/2026-09-12-notifications-next.md`; D104/D248 gates and sharing contract |
| S0 | Signing recovery for build 815 | Owner/account operator; Claude retains prior release handoff | Blocked separately | Valid authorised distribution signing; no app-source edits required |

At most one active build packet per agent. Review can overlap the other builder's independent work, but a contract consumer waits for the agreed payload. A proposed row is not a running assignment.

## The handoff that removes repeated coordination

Every packet includes: ID; outcome in golfer language; base commit; owned branch/workspace/files; governing decisions; exact request/response examples; compatibility/visibility rules; success/empty/loading/failure/retry behavior; tests; changed files; candidate commit; database/Edge/web/native deployment status; open findings; next owner.

Use states **Proposed → Contract agreed → Building → Review → Integrated → Deployed**. “Tests passed” and “merged” do not mean “deployed.” Name each deployment layer separately. When one agent changes a contract, tell the consumer in the next handoff and update the packet before either client continues.

Integration order: reviewer reads the exact commit → builder resolves findings → Codex integrates into an owned branch → generate derived files from agreed sources → run targeted and required checks → self-review the combined diff → record an immutable release checkpoint. Deploy only the explicitly authorised layers. Never cherry-pick the same correction twice just because two review reports mention it.

## Completed C0 brief (historical; do not reassign)

```text
We are planning Cup Season's next expansion while TestFlight signing is held.
Read ca682da and the completed Codex vision-next planning checkpoint. Use a
new claude/next-loop-contract branch/workspace; leave both existing release
workspaces untouched. Read AGENTS.md/CLAUDE.md and the linked canonical docs.

Your bounded task C0 is independent review and a contract proposal, not a
production deploy or client implementation. Read:
- spec/product-vision-v1.0.md (new expansion draft)
- docs/planning/2026-09-12-next-chapter.md
- docs/planning/ACTIVE_WORK.md

Return one docs/reviews/next-loop-contract.md packet covering:
1. Vision/brand conflicts or existing features the plan accidentally duplicates.
2. D345 Add/Later/Didn't play request/response/error examples, local dates,
   terminal-answer races, visibility and old/new client-server combinations.
3. Safe plan context versus live-round identity; preservation of unfinished
   drafts; durable linkage options with tradeoffs and any decision draft needed.
4. Bare-course selection on phone AND web; what Edge detail fetching changes,
   failure/readiness states, and exactly which deployment is owed.
5. Acceptance tests that execute the actual RPC and consequential transitions,
   plus findings ordered by severity and a recommended smallest first slice.

You own this packet. Codex owns canonical planning docs, client files, tokens
and integration. Do not edit those files or generate a migration in C0.
Do not reopen D345's already approved eligibility/window rulings. Commit the
packet and return its exact hash, findings and next steps. No production writes.
```

## Next packet constraints

Before C1/C2, read Codex’s disposition in `docs/reviews/2026-09-12-next-checkpoint.md`. Client-first shipping alone does not protect installed `p_today`-capable builds without prefill. C0a must address this explicitly. Do not expand answers to the whole day, discard unowned legacy drafts, add linkage, or remove the community rating aggregate as incidental fixes. Q0 and C0a are the next bounded assignments, not running tasks.

## Session-end handoff

Branch: `codex/vision-next-2026-09-12`.
Goal: complete the first review/prototype checkpoint.
What changed: prototype, brand proof, imported C0 review and integrated findings/build order.
Files changed: see `docs/reviews/2026-09-12-next-checkpoint.md`.
Verification run: 21 browser assertions at three widths; brand/text-stress captures; visual, generation, hash, link and diff checks.
Database deploy owed: none; D345 remains held separately.
Edge deploy owed: none.
Client deploy owed: none; build 815 signing recovery remains separate.
Open questions / risks: C0 contract proposals and F2 reproduction; D339 selection; production code not repaired in this checkpoint.
Recommended next step: Q0 draft recovery and C0a contract packet, each on its own branch from this committed checkpoint.


## Busy-friends client slice · 2026-09-13

Status: **Review**. Owner approved editable setup and brief language, then “Do it.”

- Codex branch: `codex/busy-friends-native-2026-09-13`; workspace `/Users/fischbeck3/cup-season-busy-friends`; base `e0643c1` (planning checkpoint on audited `ca682da`).
- Built: explicit best-2/no-minimum suggestion, editable choices, native agreement, retained creation checkpoint for retry, exact review dates, truthful invite/member distinction, receipt reconciliation, and corresponding web setup disclosure. D346 records scope and tradeoffs.
- Evidence and exact review request: [busy-friends native handoff](../reviews/2026-09-13-busy-friends-native.md).
- Claude’s gameplay audit at `8dcd403` informed this work; its branch and workspace remain untouched. No automated Claude task was started or message sent.
- Recommended next owner: Claude independently reviews this committed client diff and proposes durable create/lock recovery. Codex resolves findings and integrates a new release candidate. Fresh-scored Final needs an owner decision before backend implementation.
- No production DB, Edge, web or TestFlight release performed. Build 815 remains separate.


## Claude-led season activation sprint · 2026-09-13

Owner requested that Claude take the build lead. This is the current sprint-specific ownership assignment and supersedes the default editor table only for this packet.

- Packet: [From invitation to a first round that counts](2026-09-13-claude-led-season-activation.md).
- Status: **Ready to start; not dispatched by Codex.** App base `1c59a96`; start from the documentation checkpoint containing the packet on a new `claude/season-activation` branch/workspace.
- Claude: lead builder and fixes; affected invite, draft/post, setup and season/receipt implementation; sole `index.html` editor; scoped backend/contract work and tests. Review fixes are a separate first commit.
- Codex: independent review and integration/local device verification after handoff. No concurrent edits to Claude-owned implementation files. Native execution requires a local Mac session.
- Q0 draft protection moves into Claude’s sprint. C0a/D345 plan capability remains the next separate contract; do not fold unapproved plan semantics into activation. Existing G1 invitation paths are audited here; broader renewal remains later.
- S1 review closeout → S2 reliable invitation/draft/post → S3 understandable monthly contribution. Exact acceptance and deferred opportunities are in the packet.
- No production deploy, scoring rewrite, new notification audience or brand decision is authorized by this ownership change.
