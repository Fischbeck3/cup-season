# Today release sprint · 2026-09-13

Owner outcome: complete the release sprint and explore on a phone. Delivery order confirmed: **Safari first, then native TestFlight**. Production release is now authorized for the reviewed scope. This supersedes the older sprint packet's no-deploy limit; it does not resolve the Final scoring conflict or authorize unrelated migration activation.

## Ownership and baseline

- Codex integration: `codex/today-release-2026-09-13`, `~/cup-season-today-release`.
- Claude implementation lead: `claude/release-fixes-2026-09-13`, `~/cup-season-release-fixes`.
- Baseline `1ef0dc6` combines Claude's `b5b1bab` handoff with planning `2f51b45`; app predecessor `1c59a96`.
- Claude owns posting, league creation, invitation/terms routes, monthly fact contracts and their tests, including sole editing of `index.html`.
- Codex owns independent audit, widgets/Live Activity, integration QA, release tools and deployment evidence. Neither agent edits the other's active branch.
- Claude was started through the installed, authenticated local CLI with scoped tools. No deployment or push is assigned to Claude.

## Inspection findings

These are independently observed source defects; execution evidence is added when reproduced. The previous handoff's server replay tests do not establish client durability or UI correctness.

| Priority | Finding | Required outcome |
|---|---|---|
| P0 | Native replaces a pending ordinary post's payload on retry; persistence errors are swallowed. Web stores a global request ID without owner or frozen payload. | Persist the owner, identity and exact request before sending. Retry the same body across network loss, relaunch and account changes. Stop on failed durability. |
| P0 | Missing-RPC fallback uses non-idempotent posting while the native failure text promises same-round retry. | Fail closed, retain work, and deploy/verify the required backend before clients. No direct-insert escape. |
| P0 | Already-accepted recovery clears the request identity but leaves the card/form; another tap can create a duplicate. Ordinary pending drafts expire at 24 hours. | Complete accepted recovery exactly once and retain unresolved writes without ordinary draft expiry. |
| P1 | InvitesBanner is unrendered; See terms drops/misroutes IDs; a warm join link is only consumed on appear. | One reachable invitation/decline path with the correct terms before acceptance; warm and cold links work. |
| P1 | Missing covenant RPC falls back to acceptance without terms; handicap allowance and actual custom rules are absent. | Fail closed with retry; both entry doors use authoritative terms including actual supported rules. |
| P1 | Ambiguous create and relaunch can create a second league. | Durable request identity and replay, preserving the frozen setup agreement. |
| P1 | Month copy lacks authoritative join waiver and available-bye facts. | Expose existing rules' facts, or stay explicitly unavailable. No client inference or scoring changes. |
| P1 | Widget snapshots change without a WidgetKit reload request; expiry relies on the next OS refresh; cleanup can retain the current abandoned Activity. | Reload after publish/clear, pre-render the stale boundary, end orphan activities. |
| P1 | Supabase db push would include held D345, which still lacks compatibility protection for intermediate installed clients. | Explicit migration manifest; retain the hold until capability and client controls pass. A normal blanket push is not the release command. |

## Checkpoints

### R1 · A trustworthy first season (release blockers first)

Claude builds and commits:
- Frozen, durable ordinary posts and recoverable creation.
- Reachable invitations, honest decline, complete terms and warm links.
- Truthful monthly contribution, cap/Unlimited, minimum and existing waivers.
- Focused regression tests for failures, replay and access boundaries.

Codex independently verifies clients and RPCs with fictional/local fixtures, then integrates. Every scoring figure still traces to source rounds/adjustments.

### R2 · The complete week

Remaining approved vision work is captured here rather than lost behind release:
- D345 Add / Later / Didn't play, retaining approved per-plan semantics.
- Separate explicit capability signal; intermediate clients already send p_today.
- Known plan date/course-label prefill with consent before replacing an unfinished draft.
- Keep plan identity separate from scorecard and ordinary-post request IDs.
- Course catalogue/cache fix: no bare-course unfilter until missing-ID/FK and atomic tee-cache handling are proven.
- Explain golfer course stars distinctly from Course Rating.

This checkpoint requires an additive contract and actual old/new-client matrix. Do not deploy the held original migration simply to unlock the screen.

### R3 · Competition that accumulates

Audit and extend existing surfaces before adding a second implementation:
- Season chapter: current Record → season story → factual rounds and adjustments. Short recap with honest coverage; no invented historical lead changes.
- Existing Major/Ryder entry, eligibility, results and return paths for a newcomer and a club member.
- Run it back: preserve group history while obtaining consent to the new rules and money; never automatically mark members paid or enroll them.
- Final explanation: disclose current supported behavior. §14.3 versus D212 remains an owner mechanic decision; no scoring rewrite is bundled.

### R4 · Golf at a glance

Codex builds the bounded existing-snapshot slice:
- Rectangular Lock Screen season glance, freshness, privacy-sensitive presentation and a supported Home destination.
- Home widget publish/clear refresh and explicit expiry.
- Own-round Activity cleanup and signed-out/access-loss audit.

Friend booking/start/birdie pushes, followed-friend Live Activities, social delivery caps and public discovery remain decision/contract work. A plan is not a booking or proof of attendance; a birdie needs real hole scores and par. No new audience or fanout ships implicitly.

## Release checks

All changes in the candidate, including the older no-photo and setup work, must pass:
1. Preflight and relevant native suites/build.
2. Actual web journeys at 390/320px after clearing service workers/caches; no new console errors or horizontal overflow.
3. Native compact phone and standard phone, normal/AX3 text, light/dark for changed journeys.
4. Storage failure, offline, accepted-response loss, relaunch, duplicate tap, account switch and old-server behavior.
5. Local PostgreSQL migration/RPC tests with explicit grants, replay/conflict and stranger/resolved-invite cases.
6. Review complete diff against production main, generated sources and the exact migration/Edge manifest.
7. Database before dependent client; read back production contract availability.
8. Push reviewed main update, verify the deployed SHA and Safari journeys.
9. Archive the same reviewed candidate, validate main app and extension versions/identity, upload and read back TestFlight distribution state.

## Delivery evidence at inspection

- Production migration history: 231 applied, latest 20261023090000. Round idempotency and D343/D344 already present; D345 and the two activation migrations are absent.
- App Store Connect: build 815 is absent. This Mac has four valid development identities and no distribution identity. The earlier export reported No Accounts / no distribution certificate.
- No production mutation or release has occurred in this session yet.
- A missing distribution identity is a TestFlight blocker, independent of Safari. Do not revoke or replace account certificates by inference.

## Working status

R1 implemented by Claude through `99549ca`, independently reviewed and integrated. R4 implemented and covered by snapshot/account-boundary tests. Eight reviewed migrations are live (239 total; D345 absent). Safari candidate `25458ff` is live and verified. Native 835 archived but export is blocked by Apple cloud-signing access; see [release evidence](../reviews/2026-09-13-production-release.md). R2/R3 retain explicit scopes and release gates; they are not claimed complete by inclusion in this plan. Final release handoff must name what actually shipped, what remains, exact build/SHA and a phone URL.
