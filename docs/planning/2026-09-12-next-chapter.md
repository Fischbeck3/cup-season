# Cup Season · the next chapter

2026-09-12 · proposal and build plan, not a new release commitment.

**Recommendation:** complete the week of golf, then deepen the Record, then make the group easier to bring back. Develop the brand system alongside the first wave. Preserve build 815 as an independent recovery candidate while signing is blocked.

## First execution checkpoint · 2026-09-12

Owner approved proceeding with the parallel prototype/review checkpoint. The [journey and brand proof](../prototypes/next-week.html) and [Claude C0 report](../reviews/next-loop-contract.md) are delivered. Read [Codex’s disposition](../reviews/2026-09-12-next-checkpoint.md) before assigning implementation: draft restoration and correct plan-date entry precede bare-course exposure; ordinary-post retry safety remains a Wave 1 gate. C0’s proposed mechanics are not automatically accepted, and its client-first deploy recommendation needs a capability gate for installed intermediate builds.

## What this review actually inspected

Baseline `ca682da`, the audited native/web candidate, in isolated branch `codex/vision-next-2026-09-12`. Read the founding vision, competition spec, brand canon/bible, design guide and relevant UI rules, native roadmap/amendment, inbox, D309/D324/D326/D329/D331–D345, and the current Home, course search, posting and Record implementations. Read Claude's subsequent `b2dac7e` signing handoff without modifying its workspace.

Fresh local DEBUG captures: Home in dark and You in light on iPhone SE. These are observations of rendered app states, not fresh production-data or performance measurements. Prior candidate inspection covers course planning and season screens, photo failure, accessibility text, signed-in navigation and offline recovery. Real account captures stay ignored under `work/vision-audit/`; do not publish them to this public repository. No new product code or deployment is included in this planning pass.

## What is already strong

- Home has an editorial rhythm, not equal-weight cards. The course photograph is a photograph and the no-photo record is usable. The next action and the recent round already have distinct visual weights.
- The identity card, season board and Record have recognisable physical metaphors. `RecordPage.swift` already contains career, seasons, trophies and rivals; “build a career page” would duplicate existing work.
- Offline recovery, accepted-result ceremonies and idempotent phone posting already exist (D331–D335). The next plan bridge must preserve those guarantees.
- The course page already has social opinions and a “Rate it” control. The question is its language and role beside numerical course rating, not whether to invent a ratings feature.
- D345 has approved eligibility and a locally corrected server implementation. The remaining client controls, explicit draft context and deployment review are concrete work.

## The gaps worth building around

| Gap | Evidence | Product opportunity |
|---|---|---|
| The plan ends before the post starts | D345 opens a plain composer; `PostRoundModel.seededFrom` represents a live-round source, not a plan | Carry known course/date through an explicit plan draft without overwriting existing work; later establish durable linkage with defined ownership and retry semantics. |
| A known course can look missing | Both `ScheduleService.searchCacheResult` and `searchRemote` filter out empty tee lists | Show catalogue identity independently of scorecard readiness; fetch selected-course detail deliberately. |
| Strong history is separated into rooms | You opens the Record; Record has seasons/trophies/rivals; Home mostly reports the immediate week | Connect an accepted round to the relevant rivalry, course visit or season chapter using available facts. |
| Brand meaning is less settled than its rendering | D339's beta pennant is implemented on signature surfaces; canonical restrictions still disagree | Decide one permitted signature family, test it at real sizes, then update the generator and lint together. |
| Symbol policy has accumulated contradictory prose | UI_SYSTEM §5.3 says six emoji reactions; D309/current `CSReactionToken` have four drawn tokens; D329 unifies earned marks | Publish one current role matrix, preserving familiar reaction and trophy meanings instead of redoing every icon. |
| Some visible facts compete with themselves | Captured photo row prints gross in its sentence and again in its figure panel | Review photo/non-photo rows together against “one fact, one place”; retain the figure and put unique context in the sentence. This is an observed design follow-up, not changed here. |

Do not conflate Home's “Your number” with the credential's formal handicap label: D324 explicitly explains their different audiences. Do not treat the presence of a golfer marker such as a cactus as approval for a desert brand identity.

## Reconcile the documents before calling v1.1 canonical

| Document claim | Later evidence / conflict | Proposed editorial resolution |
|---|---|---|
| Vision: profile photo and GHIN required | D59 has optional photo with marker fallback; CLAUDE identifies GHIN as optional reference | Name the minimum usable identity and make optional enrichment explicit. |
| Vision: hole-by-hole score required | D34's ordinary quick post is front/back; live and scan may supply holes | Separate a factual posted round from optional detailed scorecard evidence. |
| Vision: operating system for leagues | Brand canon extends the scope to amateur competition; league-less planning and personal history exist | Keep seasons central while recognising value before a formal league. |
| Brand bible: PWA, future wrapper, old palette version | D99 and current source are native SwiftUI; tokens/UI system have changed | Update status/application references, retaining the founding positioning as history. |
| Brand canon/master mark vs beta signature | Tracer is the master described in canon; D339 records the beta pennant and two unresolved rules | State master/beta/final separately. Owner chooses the final family; no silent production asset replacement. |
| UI emoji rule vs later rulings | Four drawn reactions and shared earned trophy marks now exist | D309/D324/D329 are the reconciliation basis; do not copy the old “six emoji” sentence into the new brief. |
| Native roadmap still contains initial implementation waves | Its own status note says those estimates are historical | Link this evidence-based plan; do not revive Expo, a desktop rewrite, or old session estimates. |
| Inbox asks whether to add course opinions | `CourseScreen` already has `CSRating` and `RateCourseSheet` | Audit the delivered experience and resolve ambiguous vocabulary before expanding its scope. |

These conflicts are surfaced for owner review. Drafting an expanded vision does not retroactively change their governing decisions.

## Build sequence

The scope below is recommended. A task starts only after its brief is accepted; “next” is not a claim that another agent is already running it.

### Wave 0 · agree the experience and freeze the contracts

**Outcome:** a reader can trace one ordinary week and understand each agent's next bounded task.

Codex: prototype the Home after-golf state, interrupted-draft choice and accepted-round destination using current components. Prepare the brand proof sheet described below. Own the consolidated plan and vision draft.

Claude: independently review this expansion against the decisions and implementation. Produce an exact D345 client/RPC contract packet, list durable-linkage options and draft protections, and verify bare-course search behavior across both clients and the Edge Function. Draft any proposed mechanic decisions in its own review document.

Gate: shared agreement on payloads, old/new client behavior, visibility, date handling, data ownership and acceptance cases. No new database table merely to make a mockup easier.

### Wave 1 · complete the week

**Outcome:** a golfer can find a known course, plan, recover work, post once, and understand what happened.

1. **Course discovery:** preserve known bare courses with an honest readiness label. A plan can carry the catalogue identity without a tee; live setup still requires real pars. Verify the web independently rather than assuming its filter matches Swift. Selected-course detail fetching is a separate Edge change with its own deployment.
2. **After-golf actions:** Add my round / Later / Didn't play on both clients; use D345's existing server eligibility. Wait for the accepted write before hiding a prompt; give failure/retry a working path.
3. **Draft continuity:** pass known plan context only when safe. An unfinished draft presents an explicit resume/replace choice. Keep `sourceLive` separate from a proposed `sourcePlan`; no overloaded identity or automatic attendance claim. Durable plan-to-round linkage is a contract/decision subtask, not a hidden column in UI work.
4. **Accepted round:** preserve the factual no-photo treatment and accepted-result ceremony; connect the result to its receipt and relevant existing course/season destinations when identity is present.

Gate: an end-to-end pair of client checks covering local midnight, no course tees, empty/error/slow states, old-server retry, unanswered/maybe/out participation, Later across midnight, terminal answer races, post retry, existing draft, deleted/edited plan and offline relaunch. No duplicate scored round or rewritten RSVP. Existing checks plus UI taps and a real-device smoke are required.

### Wave 2 · make the Record accumulate

**Outcome:** the same round is meaningful a month later.

Extend existing Record/season-story/course-history/head-to-head surfaces. First prototype a concise season chapter assembled from accepted rounds and existing achievements, with a door back to every stated fact. Then test one contextually relevant revisit: a prior round at this identified course, or an established result against this person. Never label a coincidental same-day post as a match.

Codex owns the reading experience and share preview on both clients. Claude owns fact selection, stable identities, visibility, tie/absence semantics and contract tests. Any new aggregation remains server-owned.

Gate: correct sparse/empty histories, deleted/private records, ties and multiple seasons; public shares cannot expose private money or unsupported points/badges (D336). A golfer can explain why the chapter selected a moment. A record must not turn into a compulsory journaling workflow.

### Wave 3 · make traditions easier to continue

**Outcome:** existing guest, invite and Run it back paths preserve context and help a real group finish another season.

Audit the current paths before adding a Crew object or another wizard. Preserve invitations through auth, explain the new season's rules before acceptance, and bring identity/history forward without silently copying memberships, stakes or old results. A portable season book is an exploration after the chapter proves useful. A per-golfer record for a genuinely absent course remains a separate D150 ruling; no unverified shared tee catalogue.

Gate: a person other than the owner joins through a real invitation, understands the competition, and returns for another genuine round. Certificate readiness and release scope are reassessed at each completed wave; later waves do not automatically delay a releasable earlier one.

## Brand work inside the sequence

**Keep:** two rooms, printed board/record language, the existing four type jobs, real people and optional photos, earned gold, one primary action, familiar drawn reactions and stable trophy meaning.

**Explore two executions of the current pennant direction:** (A) a clean solid-field icon and spare signature; (B) the same mark with restrained contour support on large editorial surfaces. Use the current beta icon as the control. These are application tests, not permission to replace the mark or invent a new palette.

One proof sheet must show: 16/32px recognition; normal/dark/tinted home-screen icons; one-color mark; round mask/crop; a two-inch embroidery approximation; Home masthead; golfer card; receipt; season chapter; public share. A digital embroidery approximation is not a physical sew-out. Test narrow and large-text screens in both rooms. Give the chosen mark a source/generator and make lint enforce the same permitted placements.

The proposed message hierarchy is: **Where amateur golf counts** for the promise; a concrete season/round proof for the visitor's reason to care; **Any time. Anywhere.** only where flexible play is the point. Do not stack all three slogans on a screen. First explain the product with its artifacts; then decide whether the wording needs changing.

## Evidence and measures

Use the original friction targets as test tasks, not performance claims. Establish a clean release-only baseline: first post success, viewed eligible prompt → completed post, recoveries without duplicate writes, invitations that survive auth, and repeat weeks with multiple participating golfers. Answered “Didn't play” resolves a task; it does not count as played golf. DEBUG events are excluded under D338. Event payloads should avoid names, emails, free text and photos; retention/consent semantics need review before any new collection.

Qualitative gate: can an unfamiliar golfer recognise the next action, explain what changed, and find the round behind a statement without a tutorial? Product demand and brand preference still need owner/tester evidence; screenshots and 1,000+ tests do not establish them.

## Decisions to make from this proposal

Recommended first choice: **Wave 1 leads; brand proof work runs alongside it.** Then review the season-chapter prototype before committing Wave 2. Outstanding specific rulings: D339 signature placement/icon tile; draft replacement and durable plan linkage; how to consolidate stale vision requirements; later, D150 personal course identity. None requires reopening D345's already approved participation/window rules.

No dates or staffing multipliers are promised. Re-estimate each wave after its contract and measured unknowns are clear. Work ownership and the exact next prompts live in [ACTIVE_WORK.md](ACTIVE_WORK.md).
