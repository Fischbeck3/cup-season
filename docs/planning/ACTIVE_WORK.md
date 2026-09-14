# Cup Season · active work and ownership

Updated 2026-09-13. One queue for the next expansion. This records assignments and gates; it does not configure automatic agent-to-agent messages or monitoring.

## Signed-in review · 2026-09-13

Codex completed an authorized account walkthrough of PR #3, app candidate `8f85dac` / served `b12c0ca`. [Consolidated findings](../reviews/2026-09-13-signed-in-account-walkthrough.md): P1 posted-receipt shortcuts fail; P1 cross-league links fail to reach the season (prior F2 now reproduced); P2 credential count stays at a false zero; standings-to-receipt and copy repairs also recorded. Prior F1 remains source-confirmed, with a future-round fixture owed because this account had no qualifying future rounds. F3 remains open. Normal posted receipts, root tabs and posting/planning/name-gate entry worked. No business records submitted; physical iPhone Safari and write-path acceptance remain pending. Claude repairs and continues checkpoint B, then updates the same PR #3 preview. This section supersedes earlier signed-in-review status below.

## Integrated candidate review · 2026-09-13

Codex independently reviewed `8f85dac` in `codex/welcome-review-2026-09-13`. The combined PR #3 preview currently reads `b12c0ca` (documentation-only difference). [Review findings](../reviews/2026-09-13-integrated-welcome-review.md): two P1 Home issues (hidden next round; cross-league season navigation) and P2 text-enlargement clipping require fixes before promotion. Welcome composition is directionally ready for owner review, with quieter terrain near text recommended. Claude retains implementation ownership and checkpoint B; Codex reviews committed checkpoints in parallel. No production promotion performed.

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
- Do not run a blanket database push: `20261024090000_the_loop_has_a_closing_act.sql` remains held pending capability protection.

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
| Web client `index.html` | Codex, as sole editor of the file per wave | Claude reviews the committed diff; do not split the single file between active builders |
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
