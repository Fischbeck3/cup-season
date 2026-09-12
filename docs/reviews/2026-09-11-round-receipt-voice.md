# Next build: accepted round, receipt, share

Owner direction 2026-09-11: preserve proven UX; one bounded product slice,
voice system, icon contour visibility. No release authorization.

Baseline: isolated `codex/round-receipt-voice-2026-09-11`, HEAD `a4714cfa` plus
an exact snapshot of the owner's uncommitted visual-refresh work. Original
workspace untouched. `CupSeason2030Vision.md` is absent; the historical HTML
prospectus is not treated as approved mechanics. Reference: `Desingv1.png`,
1448×1086, SHA-256 `5e6c73d5c3d0bd537ba3999af6056b31b6a3fe120de627185f1bdbaf3e141797`.

## Build map

Statuses separate implementation evidence from runtime proof. All paths below
are relative to `apps/ios/` unless prefixed `supabase/`.

| Capability | Status / evidence | Friction and smallest release | Dependencies / verification |
|---|---|---|---|
| A Submission/recovery | PARTIAL. `CupSeason/Post/PostRoundModel.swift`, Kit `Post/PostService.swift`, `Post/PostCard.swift`: busy guard, delayed 24-hour draft snapshot, server acceptance before ceremony. SQL `20260910090000_a_round_is_posted_by_the_server.sql` inserts a new ID on every call. | Lost accepted response + retry has no request-key guarantee. Draft is not an offline queue. | Server idempotency approval required; interrupted request/relaunch tests need a dev-safe server. No production test writes. |
| B Invitation | UNVERIFIED end to end. Kit `Nav/PendingLink.swift`, `People/JoinLeague.swift`; app `People/JoinLeagueFlow.swift`, `RootView.swift` retain intent and show covenant. | Sign-in copy promises membership/friendship too early. Correct copy now. | No backend dependency for copy. Full signed-out/member/expired/interrupted/web matrix remains required. |
| C First round, no league | PARTIAL. SQL accepts no matching season; `PostRoundModel` and `PostEpilogue` support no-season result. | Appreciation should not depend on joining. Existing receipt now offers round export without hole-by-hole data. | Client-only; no-season fixture and real accepted no-season account needed for full proof. |
| D Receipt | PARTIAL. `Rounds/RoundReceiptSheet.swift`, Kit `Rounds/Receipt*` retain calculation, rules, adjustments. | Completion lacks a clear receipt door; local preview consequences can differ from server result. Use accepted ID and returned figures. | Existing RPC only. Verify ceremony→receipt and enrichment failure, preserve explainability. |
| E Round share | PARTIAL. `Post/RecapCardView.swift`, `Post/PostPhoto.swift` already export native images. | Immediate share lacks preview; receipt only exposes full-scorecard export. Add one preview to existing round template. | Existing renderer/native sheet. Verify exact PNG, no-photo, privacy, cancellation, large text. |
| F Existing group renewal | UNVERIFIED runtime. `Wizard/WizardScreen.swift` has `WizardRunBack`; `Main/MainTabView.swift` routes role-gated renewal. | Discoverability/review of carried rules, not an absent feature. | Existing wizard/backend. Verify completed season→carried rules→new season with test group later. |
| G Personal history | UNVERIFIED runtime. `You/YouScreen.swift` reads career, recent rounds, courses from tour card. | Quiet presentation is not missing capability. | Existing data only; review long/empty history later. |
| H Measurement | PARTIAL. Kit `Telemetry.swift`, `Growth.swift` already write existing infrastructure; growth first-round classification is server-side. | Share opening is not delivery; debug polluted metrics. Add generated/completed/cancelled/failed and receipt-view events; exclude DEBUG writes. | No vendor/schema. Counts and baselines remain unmeasured. |

Selected slice: accepted round → existing receipt → preview of one public round
artifact → native share sheet. No new destination, template gallery or editor.

## Save-truth boundary

The current RPC has no client request ID and inserts a fresh round for each call.
The fallback direct insert also has no request key. The busy guard prevents
concurrent taps within this model instance; it cannot prove retry idempotency.
A transport timeout is not proof that the server rejected the round.

**Proposed, not executed:** an authenticated, transactionally unique request key
scoped to golfer; retry returns the same accepted round and result. Persist that
key with the local draft until acceptance is reconciled. Define retention, grant,
fallback/deploy-skew and photo/hole follow-up behavior before implementing. No
heuristic deduplication by course/date/score: two legitimate rounds may match.

Not certified in this pass: interrupted production requests, accepted response
loss, cross-relaunch retry, or zero duplicate production rows. Existing draft
snapshot is 24 hours, debounced 350ms, and does not include the in-memory image.
No copy claims an offline queue or automatic sync.

## Copy audit

| State / source key | Before | After / disposition | Truth condition / protected |
|---|---|---|---|
| Welcome `DoorView.welcome` | Rounds count. | Golf with your people, all season. | One explanation beneath primary brand line; no auth change. |
| Join `PendingLink.doorLine` | Sign in and you're on the roster. | Sign in to review and join. | Pending invitation, membership still unaccepted. |
| Claim same producer | Sign in and it attaches. | A round is waiting. Sign in to review it. | Pending claim, no acceptance promise. |
| Person same producer | Sign in and you're buddies. | Someone shared their golfer card. Sign in to view it. | Viewing is not friendship. |
| Plan same producer | There's a round on. Sign in and take the seat. | You’ve been invited to a round. Sign in to view the plan. | No availability promise. |
| Photo upload `PostRoundModel.submit` | Photo didn’t stick — posting the round without it | Couldn’t upload the photo. Posting the round without it. | Upload failed; round request still follows. |
| Receipt loading literal | Pulling the round… | Loading round… | Read pending. |
| Completion / receipt | No direct receipt / recap door | View receipt / Share round | Accepted ID / enriched owned round. |
| Home plan | “today” can conflict with “Tomorrow” | Flagged, not disguised | `home_dispatch` uses database `current_date`; native `HomePage` uses `CSDate.today()`. Needs common date contract. |
| Compete / Golfers / empty states | Existing factual and protected terms | Preserved this pass | No blind replacement or scoring-band rename. |
| Save errors | Post failed. | Flagged unknown-outcome distinction for idempotency slice | Cannot imply safe retry or rejection after transport timeout. |

Canonical voice guide: `spec/voice-and-tone.md`. Current owner direction is at
the top; earlier persona is explicitly superseded historical rationale. The Pro,
Run it back, Your Number, scoring bands and ledger sentence/§16A.1 stay protected.

## Measurement contract

Existing `client_events`, no new vendor. New native events:
`receipt_viewed`, `round_share_generated` (`has_photo` only),
`round_share_completed`, `round_share_cancelled`, `round_share_failed`.
Completion means iOS reports activity completion, not delivery/read by a friend.
Generation is not a share. No names, scores, courses, private titles, photos or
tokens in these payloads. Removed gross from native post-submit breadcrumb.
DEBUG calls to both telemetry writers return without sending.

Existing accepted `round_posted` and server-classified `first_round_posted`
remain. Second accepted round and returning participants should be derived from
authoritative distinct round IDs/profile participation, not multi-competition
client notifications. Invitation opens/acceptance and renewed-crew activation
need a cross-client event audit before conversion claims. No baseline measured.

## Next three builds

1. **Safe retry / recovery.** Source proves missing request-key guarantee. Smallest
   release is the approved idempotency contract plus interrupted/relaunch matrix.
   Improves accepted rounds without duplicates; backend/security dependency. Comes
   first because uncertain saving undermines every return/share loop.
2. **Invitation completion and local calendar consistency.** Retained intent
   exists, but the full member/expired/auth/web matrix is unverified and Home has
   two clocks. Smallest release fixes verified breaks and establishes one calendar
   contract. Improves joining and showing up; may need RPC date context. Before
   renewal because the crew must reliably arrive first.
3. **Run it back with participating people.** Existing wizard carries rules;
   verify organizer review and returning-member activation on a test group.
   Improve proven friction only; existing APIs first. Measure actual returning
   participants, not league creation. Before more share templates or profile depth
   because it directly tests whether a crew chooses another season.

## Verification and review checkpoint

- XcodeGen generation and simulator builds passed.
- Final `/tmp/cup-season-next-verified.xcresult`: **1,290 passed, zero failed,
  zero skipped** (CSDesign, CupSeasonKit, app tests, four selected UI tests).
- Welcome's two existing entry actions passed on the signed-out iPhone 17 Pro
  in the preceding expanded run. That run's new share test initially failed on
  an incorrect button query; the observed native actions are cells. The final
  test uses `ActivityListView` and the native Close control and passes.
- Read-only real-account UI: existing accepted receipt → preview → attached
  photo opt-out → native share sheet → Close. Completion replay → receipt also
  passed. The replay is not a newly submitted round and is labeled accordingly.
- No-photo fixture and large Dynamic Type dark preview passed. Privacy test
  confirms public export strips points/achievement claims without mutating input.
- Preflight passed (zero failures, zero warnings) after installing locked dev dependencies; no baseline changes.
- `git diff --check` passed. No test round/competition writes, deployments, pushes or commits.

Icon source remains `brand/candidates/testflight-pennant/source.json`; the only
visual change is icon contour alpha in `tools/build-beta-mark.swift`: 0.09 → 0.12.
`--review <directory>` emits A/B/C; `--icon-alpha` produces comparison builds
through the normal source pipeline. Default is B. Mark, contour paths, stroke,
placement, size, palette and in-app topo remain unchanged. Compiled A/B/C were
installed and captured on the iPhone 17 Pro home screen. Current A matches the
inherited icon exactly in RGB. An initial alpha-only comparison incorrectly
suggested caching; corrected RGB comparisons verify differences. No packaging
workaround was introduced.

Review artifacts are local (contain the owner's real round), outside this public
repository: `/Users/fischbeck3/cup-season-next-build-review/index.html`.
The manifest `files-this-pass.txt` separates these changes from inherited work.

Known limits: no new server submission was made on the real account; interrupted
request, duplicate retry and recovery semantics are not certified. Invitation
matrix and renewal were source-audited, not comprehensively exercised. No product
conversion baseline or real outbound sharing was measured. Existing native
compiler warnings include unused legacy icon assets; they were not deleted in
this pass. No-photo layout and existing date/board typography were retained.

Owner decisions: review screenshots and modest versus stronger icon. Separately
approve the request-key RPC/schema contract before the safe-retry build. No
release action is authorized by this checkpoint.
