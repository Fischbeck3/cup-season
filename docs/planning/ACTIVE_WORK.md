# Cup Season · active work and ownership

Updated 2026-09-12. One queue for the next expansion. This records assignments and gates; it does not configure automatic agent-to-agent messages or monitoring.

## Baselines and current state

- Audited candidate: `ca682da`, build 815. Keep it unchanged while Apple distribution signing is unavailable. Latest Claude handoff reviewed: `b2dac7e`; no signing issue is a reason to deploy D345.
- Current planning workspace: `/Users/fischbeck3/cup-season-vision-next`, branch `codex/vision-next-2026-09-12`, based on `ca682da`.
- Codex's release workspace and Claude's existing workspace retain their owners. Do not switch or edit another agent's branch. A new implementation branch starts from the explicitly agreed integration checkpoint.
- This turn produces documents and a proposed build sequence. No new product implementation has started under this plan. Actual start/completion is recorded by the assigned agent with a commit hash.

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
| V0 | Expanded vision, evidence-based roadmap, ownership brief | Codex | Drafted for owner review | This checkpoint; no new mechanics approved |
| C0 | Independent critique + exact week-loop contract packet | Claude | Ready to assign; not started | Read V0 and `ca682da`; own docs-only branch |
| B0 | Pennant application and symbol-role proof sheet | Codex | Proposed next | Existing tokens; explicit D339 choices shown |
| C1 | Course search/detail and bare-course behavior | Claude backend / Codex clients | Proposed | C0, accepted scope, named Edge deployment gate |
| C2 | After-golf answers and safe draft continuity | Claude backend / Codex clients | Proposed | C0; decision before new linkage semantics |
| Q1 | Integrated complete-week audit | Codex + Claude independent review | Proposed | C1/C2; same commit, both clients, real RPC and UI evidence |
| R1 | Existing Record extended into a season chapter | Codex prototype / Claude facts | Later proposal | Q1; sparse-data and privacy proof |
| G1 | Existing invite/guest/renewal continuity | Codex clients / Claude contracts | Later proposal | Core loop and chapter evidence |
| S0 | Signing recovery for build 815 | Owner/account operator; Claude retains prior release handoff | Blocked separately | Valid authorised distribution signing; no app-source edits required |

At most one active build packet per agent. Review can overlap the other builder's independent work, but a contract consumer waits for the agreed payload. A proposed row is not a running assignment.

## The handoff that removes repeated coordination

Every packet includes: ID; outcome in golfer language; base commit; owned branch/workspace/files; governing decisions; exact request/response examples; compatibility/visibility rules; success/empty/loading/failure/retry behavior; tests; changed files; candidate commit; database/Edge/web/native deployment status; open findings; next owner.

Use states **Proposed → Contract agreed → Building → Review → Integrated → Deployed**. “Tests passed” and “merged” do not mean “deployed.” Name each deployment layer separately. When one agent changes a contract, tell the consumer in the next handoff and update the packet before either client continues.

Integration order: reviewer reads the exact commit → builder resolves findings → Codex integrates into an owned branch → generate derived files from agreed sources → run targeted and required checks → self-review the combined diff → record an immutable release checkpoint. Deploy only the explicitly authorised layers. Never cherry-pick the same correction twice just because two review reports mention it.

## Copyable next task for Claude

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

## Session-end handoff

Branch: `codex/vision-next-2026-09-12`.
Goal: expand the product vision into a reviewable sequence with one owner per file.
What changed: proposed vision extension, implementation/brand assessment, build gates and collaboration queue.
Files changed: vision, doc map, inbox, prior tandem pointer, and these two planning documents.
Verification run: source/decision inspection, fresh app captures, local document-link and diff checks. Documentation only; no application test suite rerun.
Database deploy owed: none from planning; D345 remains separately held.
Edge deploy owed: none from planning.
Client deploy owed: none from planning; build 815 signing issue remains separate.
Open questions / risks: owner direction/brand choices; draft/linkage semantics; no new implementation or automatic Claude task started.
Recommended next step: owner reviews the proposed order; hand C0 to Claude while Codex develops B0 and the week-loop prototype once the first slice is selected.
