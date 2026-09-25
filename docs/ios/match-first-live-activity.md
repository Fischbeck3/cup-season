# Match first · native Live Activity

**Branch:** `codex/between-round-widgets-2026-09-25`, isolated checkout
`/private/tmp/cup-season-between-round-widgets`. Follows the between-round widget
commit `cbcc55db`; the original dirty workspace remains untouched.

**Goal:** Build the owner's selected Match first direction, with quick own-score
entry from the expanded Dynamic Island and Lock Screen Live Activity.

**What changed:**

- Compact: hole and the golfer's match position. Expanded: opponent, result,
  match holes completed, own score, Previous and Next. Uses the existing match
  and Sunningdale engines, including all square and closeouts. Other games keep
  their existing summaries; just-score rounds show gross.
- A golfer on hole 3 can go back to 2, use + / −, then return to 3. Moving holes
  never records a score. First + starts at that hole's par; minus at 1 clears
  the entry. The existing server range, 1–15, bounds input.
- Last hole opens Review round in the app. It never posts or finishes from the
  background. The exact owned card can also open through the offline boot door.
- `LiveActivityIntent` executes in the app process. The extension has no session
  credentials or network client. Actions validate account, round, and displayed
  hole; old activities and guest pencils offer an app link. An account epoch
  change invalidates in-flight actions, including switching away and back.
- A single atomic journal records the card and its pending existing RPC write
  before the activity acknowledges a change. Interrupted queue transfer recovers
  on the next read. Actor-owned queue updates preserve edits arriving during an
  RPC. Per-cell clocks prevent a delayed app snapshot from undoing a score.
- Local-only cards use the existing offline vault. Pending scores say “Saved on
  phone.” Network sync follows the durable edit; it does not serialize the next
  score tap behind an earlier request. Successful queue drains reconcile the
  server's latest round through the existing merge path.
- Branded type, dark ground, ember action, and 44-point controls use CSDesign.
  Bounded text scaling keeps the small surface within its height budget;
  accessibility sizes omit secondary match copy. Full labels remain available
  to VoiceOver, and the app remains the full-size scorecard.

**Files changed:**

- App `Live/`: activity content/identity, lifecycle, durable scoring runner,
  recovery/routing, score clocks, and scorecard-review handoff.
- App `Widgets/`: shared live presentation, authenticated score intent, and
  a DEBUG review fixture using the production controls and store.
- `CupSeasonWidgets.swift`, `project.yml`, `CupSeasonApp.swift`, `MainTabView.swift`,
  `RootView.swift`: extension registration and online/offline route handling.
- Kit `LiveIsland.swift`, `LiveActivityJournal.swift`, `LiveDisk.swift`,
  `LiveRoundSession.swift`: facts/actions, atomic recovery, safe queue mutation.
- CSDesign `WidgetControl.swift`: live action variant and review-only framing.
- `LiveIslandTests`, `LiveActivityScoringTests`, `LiveIslandUITests`, IOS-083,
  D155's UI amendment, and this handoff.

**Verification run:**

- XcodeGen generation and iPhone 17 Pro Simulator builds succeeded.
- All 1,283 CupSeasonKit tests passed, including eight new LiveIsland tests.
- Nine app tests passed: seven scoring/recovery tests and two existing
  offline-round flow tests.
- Two UI tests passed, with 12 native captures: seven standard states, four
  accessibility-size states, and the missed-hole walkthrough. The walkthrough
  goes hole 3 → 2 → score 5 → 3. Every reviewed surface fits the 160-point
  height budget. An initial accessibility overflow was corrected and retested.
- `npm run preflight`: zero failures and zero warnings. `git diff --check`: clean.
- Both compiled targets contain `LiveScoreIntent` metadata with authentication
  required and `openAppWhenRun: false`. No new dependency or generated-token edit.

Evidence: `/private/tmp/cup-season-match-first-verified.xcresult` (full Kit),
`/private/tmp/cup-season-match-first-layout.xcresult` (final app tests; its initial
UI height failures were corrected), and
`/private/tmp/cup-season-match-first-ui-verified.xcresult` (passing final UI).
PNG captures are preserved in the task visualization directory under
`native-match-first-review/`. Native gallery checks do not establish
system-hosted intent lifecycle behavior on a physical phone. Xcode also emitted
the existing Supabase initial-session warning; it did not fail the app tests.

Reproduce after `xcodegen generate` from `apps/ios`:

```sh
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CupSeasonKitTests \
  -only-testing:CupSeasonTests/LiveActivityScoringTests \
  -only-testing:CupSeasonTests/OfflineRoundFlowTests \
  -only-testing:CupSeasonUITests/LiveIslandUITests test
```

**Database deploy owed:** None. **Edge deploy owed:** None.

**Client deploy owed:** None within the approved Owner release. The branch is
merged into main and **1.0.0 (1025)** is available in Owner TestFlight.
[Deployment evidence](widgets-match-first-deployment.md).

**Open questions / risks:** A physical-device check remains for actual expanded
Island/Lock Screen placement, intent execution while suspended or terminated,
rapid repeated taps, Face ID/passcode, and privacy redaction. Apple requires
authentication/unlocking for Lock Screen interactions; this does not bypass the
lock. The compact Island opens the app; hold it to expand. Match facts update
from the app and interaction-time reconcile, without a server-push ActivityKit
service. They can lag when the app is suspended. The existing 45-minute stale
date offers “Open to refresh.”

**Recommended next step:** Install build 1025 from Owner TestFlight and complete
those system-hosted checks on an iPhone before wider distribution.

Platform references: [LiveActivityIntent](https://developer.apple.com/documentation/appintents/liveactivityintent),
[widget and Live Activity interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities),
[Live Activity layout guidance](https://developer.apple.com/design/human-interface-guidelines/live-activities).
