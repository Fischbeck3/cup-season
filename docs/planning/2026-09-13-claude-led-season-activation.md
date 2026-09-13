# Claude-led sprint · from invitation to a first round that counts

2026-09-13. Owner: “another sprint on top of the Claude review” with Claude taking the lead. This packet assigns build ownership and a bounded sequence; it does not claim Claude has started or that a newer review has arrived.

## Starting point and ownership

- Application baseline: `1c59a96`, `codex/busy-friends-native-2026-09-13`. Read its [handoff](../reviews/2026-09-13-busy-friends-native.md). The subsequent planning commit changes documentation only.
- Latest synced Claude gameplay report observed: `8dcd403` on `claude/gameplay-rules-simulation`, file `docs/reviews/2026-09-12-gameplay-rules-simulation.md`. No newer review of `1c59a96` was present when this packet was prepared. If one arrives, read and disposition it before implementation; do not invent or duplicate its findings.
- Claude leads scoping, fixes, implementation, targeted tests and handoff for this sprint. Use a new `claude/season-activation` branch and separate workspace from the documentation checkpoint containing this packet. Do not edit the Codex review branch.
- This is an explicit sprint-specific override of the default ownership table: Claude may edit affected native setup/posting/season/invite files, the web `index.html`, and shared backend/contract sources on its owned branch. One editor owns `index.html` for the entire sprint. Codex does not implement in those files concurrently.
- Codex owns independent review, cross-client integration, local simulator/device verification and the release checkpoint after Claude hands off. Claude may run native builds in a local Mac session. A remote session hands local-native work/checks to Codex and does not claim simulator verification.
- Keep the existing token system, supported editable rules and consent model. A new rule, membership meaning, scoring formula or notification audience requires its own decision before implementation. No production database/Edge deployment, main merge or TestFlight upload is included.

## Product outcome

A friend opens an invitation, understands the competition, joins deliberately, plays on their own schedule, posts once, and can see which rounds contribute to the season. A busy golfer can tell whether another round is required or simply another chance to improve.

This advances Cup (understandable competition), Crew (successful invitation), and the complete-week horizon in the [vision](../../spec/product-vision-v1.0.md#expansion-draft--2026-09-12). It does not create a new league format, a new top-level tab, or a separate league administration product.

## Build in three checkpoints

### S1 · close the review before adding behavior

Read the exact review of `1c59a96` if available; otherwise perform it first. Resolve reproducible defects in the agreed behavior and record every disposition. Recheck agreement → outgoing fields → stored settings, selected squad count, minimum/bye facts, membership versus invitations, and receipt residuals.

Carry forward the explicitly open issues, not a claim that the previous slice solved them:

- Ambiguous create responses and reopening after process termination; in-session confirmed-create retry already exists.
- Existing stored non-null counting cap changed to Unlimited (`lock_league` coalesce semantics); off-ladder stored cap values must not silently become different rules.
- The existing Final spec/D212 conflict. Preserve current scoring. Do not solve a copy contradiction by secretly changing qualification or ranking.

Deliver a review-fix commit first. Keep the new behavior in subsequent commits so the review fixes can be integrated independently.

### S2 · make the invite-to-post journey reliable

Inspect the existing `JoinLeagueFlow`, invitation/covenant routes, wizard, `PostRoundModel`, `PostDraft`/`PostService`, web draft and post paths before introducing a replacement. Reproduce old audit findings against this exact branch; do not assume inbox entries remain open.

Acceptance targets:

1. Invitation context survives sign-in, and the recipient sees this season’s rules before accepting. Expired/closed/late-entry states use current policy and offer an honest return path. No invitation is treated as a joined member, paid seat or attended round.
2. An unfinished ordinary draft can be resumed without losing its date, course or scores. A kept live-scorecard draft cannot be overwritten by an ordinary entry. Recovery remains scoped to the correct golfer. Reproduce the date-before-`isBlank` issue from C0 F2 before fixing it.
3. An ambiguous post response has a safe retry/recovery path with one accepted factual round. Preserve the existing phone/live idempotency guarantees; audit ordinary posting separately. Define and test any additive request identity/contract before wiring consumers. Do not use a direct insert fallback that bypasses deduplication.
4. Accepted results retain the no-photo path and a working receipt. Reopening the app must agree with the accepted server result.

If reliable create/lock or ordinary-post recovery requires an additive backend contract, specify request identity, ownership, replay/conflicting-body behavior, old-client behavior and grants. Record the decision and tests before implementation. Do not couple safe independent fixes to an unresolved new product mechanic. Test against an isolated local database; leave deployment instructions in the handoff.

### S3 · make this month understandable

Extend the existing season facts, standings and member-round receipts. `SeasonFacts.monthRow`, `footRule`, `LeagueCopy`, `MemberHistorySheet` and `SquadReceiptSheet` already cover parts of this job; reconcile them rather than adding a second dashboard.

Acceptance targets:

- Display the league’s actual counting rule, including Unlimited, and distinguish how many rounds count from minimum credit (a 9-hole round can supply half a minimum credit).
- Explain no minimum, minimum met, remaining requirement, automatic bye and partial/joining-month exemptions only when the server facts support them. No inactivity shame or mandatory-play implication in a no-minimum league.
- A golfer can open the rounds behind their contribution and see why a round is outside the monthly best. Squad totals disclose their sum and known adjustments without inventing missing data.
- An additional eligible round is described as another chance to improve; do not promise it adds points, overtakes a friend, or guarantees qualification. Only Postgres decides a band or scoring consequence.
- Reuse known server facts. Where the payload cannot establish a consequence or history, show an honest unavailable state or propose the smallest contract. Do not calculate hypothetical golf scores on the client.

Do not add new alert fanout, achievements, points bonuses or fairness algorithms in this checkpoint.

## Quality throughout the sprint

Each checkpoint: reproduce → implement → targeted regression → inspect the changed journey → commit. At handoff, run relevant full preflight/native checks and record the actual environment; do not count unexecuted test cases as evidence.

Minimum scenario matrix:

| Scenario | Must prove |
|---|---|
| Busy friends, Best 2/no minimum, one round this month | The round has its actual contribution; another round is optional; no minimum warning. |
| Former D1 group, custom squad count and tougher rules | Chosen rules survive setup/join; actual handicap-based points and counting rounds are traceable. |
| New golfer accepting an invitation | No membership before consent; rules and handicap requirements are clear; season contribution and any separate Major exhibition gate are not conflated. |
| Club professional gathering an existing member group | Invite lifecycle and roster counts are truthful; existing league/event objects suffice for this slice. No new club organization model. |
| Failure and time boundaries | Offline/relaunch, duplicate tap, ambiguous response, account switch, 9/18 holes, monthly boundary, partial month, empty/missing data and an older server. |

Use isolated fixture accounts and local database tests. Public evidence contains fictional people; no private member data or money in shares. Native: compact phone, normal/AX3 text, dark/light, actual taps through changed paths. Web: clear service workers/caches, 390/320px, no horizontal document overflow or new browser errors.

Exit: S1 fixes and the agreed S2/S3 behaviors pass, exact commits and remaining blockers are named, and Codex can independently rerun the evidence. A blocked contract is reported honestly with its dependent work still pending; a partial sprint is not labelled complete.

## What can follow from the vision

| Opportunity | Recommended timing | First useful scope |
|---|---|---|
| Complete planning → posting | Next after this sprint’s draft/retry foundations | C0a capability contract, then D345 Add/Later/Didn’t play and safe plan context. Preserve approved per-plan semantics and installed-client compatibility. |
| Competition recap / season chapter | Next product increment once contributions are trustworthy | Extend existing Record/season story with one supported monthly or season recap, every claim linked to its rounds. No invented historical lead changes. |
| Event participation and Run it back | Following bounded sprint | Existing Major/Ryder/callout entry, eligibility and results; then returning-group consent and new-season rules. Do not invent new formats or copy paid memberships automatically. |
| Home/Lock Screen glance | Small independent follow-up after snapshot/privacy audit | Extend the existing season widget with actual current standings/next plan, stale/access-loss handling and a useful deep link. Reuse snapshots; no friend fanout. |
| Friend-start/birdie alerts; public golfer/league discovery | Decision/contract work first | Consent, audience, moderation where needed, freshness and deduplication. D248 feed-only plan declarations are not authorization for booking alerts. |
| Final seeding explanation | Contract investigation can run after S1 | Determine whether an authoritative lock-time table exists before promising a historical table. Fresh-scored Final remains an owner decision. |

Prefer one completed competition journey over starting all of these in parallel. The certificate hold remains separate from which sprint is ready for review.

## Prompt for Claude

```text
Take the build lead for the next Cup Season sprint. Start from the latest
codex/busy-friends-native-2026-09-13 documentation checkpoint (app base
1c59a96) in your own claude/season-activation branch/workspace.

Read AGENTS.md, CLAUDE.md, docs/planning/ACTIVE_WORK.md and
 docs/planning/2026-09-13-claude-led-season-activation.md.
Read your latest review of 1c59a96 first if it exists; otherwise review it.

The sprint is: from invitation to a first round that counts.
1. Fix validated review findings in a separate commit.
2. Make invitation acceptance, draft recovery and posting/retry reliable.
3. Extend the existing season/receipt surfaces so this month's counting
   rounds, minimum and contribution are understandable.

You own the affected implementation and tests for this sprint, including
index.html as its sole editor. Codex will independently review and perform
local integration/device QA after your handoff. Work to the packet's
checkpoints and acceptance matrix. Inspect existing work before rebuilding.

Preserve editable rules, consent and server-owned scoring. Record any new
contract before implementation; flag unresolved product decisions. Do not
change Final scoring, invent competition rewards, activate friend alerts,
or deploy production layers. Return exact commits, test evidence, findings,
deploys owed and the next review request. Do not stop at another broad audit
when the validated fixes and agreed implementation can be completed.
```

## Handoff

Branch: `codex/busy-friends-native-2026-09-13` (planning update only).
Goal: give Claude the lead on one competition-focused sprint.
What changed: bounded sprint, explicit ownership override, checkpoints and acceptance matrix.
Files changed: this packet and `ACTIVE_WORK.md`.
Verification run: branch sync, source/doc inspection, link and diff checks; no app tests rerun for documentation-only changes.
Database deploy owed: none from this packet.
Edge deploy owed: none from this packet.
Client deploy owed: none from this packet; prior implementation remains a review candidate.
Open questions / risks: latest review not yet observed; durable retry contracts and Final semantics remain explicit gates.
Recommended next step: send the prompt to Claude; Claude builds on its own branch, then Codex independently reviews.
