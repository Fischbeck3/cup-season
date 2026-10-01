# Recipient follow-up · September 30, 2026

Owner asked “Start on other items” after the selected 1/2/4 sprint at `e700abc8`. This follow-up implements item 3 and prepares the physical release checks for item 5. Impeccable harden, clarify and craft-floor guidance applied within Cup Season canon; no new visual system or mechanic.

Branch: `codex/launch-sprint-2026-09-30`.

Workspace: `~/.codex/worktrees/launch-sprint-2026-09-30/cup-season`.

Verified source candidate: **`6a35c3d6`** (following evidence commit is documentation only). Recipient production fix: `50b0483c`, on the unified Build 2 + D400 + Q2 + Book candidate. Fetched main remains `5d70caeb`. The dirty Match Programme checkout and Claude's active work were not edited.

## What changes for the recipient

Public buddy and plan pages have a direct sign-in door. Their original token remains in the URL and local storage across email entry and reload. Get the app remains a secondary, accessible link. Neither the buddy request nor the seat is spent by that door: the existing authenticated, named confirmation still owns the golfer's yes.

For an invitation already agreed to, web reads current memberships and uses the existing season navigation. Successful arrival consumes only the matching pending code/name. Failure preserves the invitation, and a late response cannot consume a newer code. Signed-in door, welcome, join sheet and boot/profile continuations stop there without another join RPC or false welcome. A failed terms read also releases the join sheet's disabled button, making retry possible.

Native's agreed sheet names the season and offers Open the season instead of a closing dead end. JoinModel resolves only that code's current membership and consumes only that invitation; missing membership retains it with a recoverable error. The existing RootView callback owns preferred-season reload and board routing. Other covenant presenters without an opening callback retain Close; ordinary join/terms behavior is unchanged.

The DEBUG gallery exercises the real sheet and tap callback using explicitly synthetic North Grove records, without a server write. Visual review caught the gallery's raw `.sheet` ignoring the existing text-size hatch: it now uses `.csSheet`, and the UI test requires actual heading growth at AX3. The hosted unit test waits for the app scene and accessibility tree before measuring. Button/header words are checked independently of the existing type roles' capitalization. No Release styling was changed by the fixture repair.

## Boundaries of the proof

Browser tests intercept Supabase and use invented payloads. They click the real public link, email door and existing confirmation, then explicitly simulate authentication; they do not deliver or verify an actual eight-digit email code. They assert zero redeem before yes, exactly one after yes and consumption, and all three signed-in code handlers. Membership reads exercise the real client read; the season navigation is a spy proving the intended league ID and success/failure wiring, not live server arrival.

Native model tests prove matching membership, no new welcome and matching-only code consumption. The system-hosted sheet's UI test proves accessible words, finger target, actual enlarged text, reachability and its opening callback. The DEBUG “opened” marker does not claim live auth or server navigation. No real account posts, invitations, locks, reactions or RSVP writes were performed.

The full parent browser control uses `e700abc8` HTML in the same synthetic matrix and reproduces 60 failed assertions (42 unaffected checks pass). The repaired matrix passes 150/150 at 375/402/1280 × dark/light with zero page exceptions. Existing browser app tests pass 570/570 in every cell, including the saved-draw pin. All 12 public-page captures were inspected; six are saved in captures/.

## Physical release gates

[DEVICE-CHECKS.md](DEVICE-CHECKS.md) is the exact-candidate sheet for recipient journeys, owner two-phone recovery, real system widgets, sign-out/account-switch privacy and background-handler/cadence observation. Every physical row is NOT RUN. One phone was available on this Mac and the second unavailable; no physical-phone interaction was performed. Simulator passes do not close these gates. Natural iOS background cadence remains NOT OBSERVED.

The release owner must install the same combined source/build on both test phones, record native identity, live web stamp and Q2 read-back, then fill the sheet with private evidence. Friends/public distribution is not advanced by this work.

## Final verification

| Check | Result |
| --- | --- |
| Native app/design/Kit/XCTest | **1,811 passed**, zero failed/skipped; signed build, Xcode exit 0 |
| Recipient browser matrix | **150/150**; 375/402/1280 × dark/light; zero page exceptions |
| Unchanged parent control | 60 expected failures, 42 unaffected passes |
| Existing browser app suite | **570/570 in each of six cells**, zero page exceptions |
| Pro recipient UI | 1 test, four actual theme/size cases; zero failed/skipped, exit 0 |
| Compact SE recipient UI | 1 test, four actual theme/size cases; zero failed/skipped, exit 0 |
| Preflight and diff check | **Zero failures/warnings**; clean diff |

The native 1,811 comprises 153 app Swift Testing, 141 design, 1,453 Kit and 64 XCTest. All eight final native captures were visually inspected; whole season/action words remain readable and tappable at AX3. See the summaries, capture manifest and logs beside this file. No generated sources, dependency, version, backend or gameplay changes were made.

Final result bundles: `/private/tmp/codex-recipient-native-verified.xcresult`, `/private/tmp/codex-recipient-ui-pro-verified.xcresult`, `/private/tmp/codex-recipient-ui-se-verified.xcresult`. The initial case-sensitive label/header assertions were test assumptions, not changed typography. Initial raw-sheet captures did not exercise AX3 and are superseded. Focused hosted measurement now waits for the app scene/tree; the final full run confirms it. Existing first-launch argument loss has a bounded, recorded single relaunch, as in SyntheticRouteTests; neither final UI run needed it.

Earlier runs stalled in Xcode's bulk simulator diagnostic collection after test bodies completed. Only task-owned processes/devices were recovered. Final runs use `-collect-test-diagnostics never`; ordinary result bundles, failures, screenshots and runtime warnings remain available. All final commands exited 0. Existing FocusState test-harness and Supabase fixture initial-session warnings remain in result summaries; these do not establish live authentication. No failed/interrupted run is counted as final proof.

## Files and release handoff

Implementation: `index.html`; native `People/JoinLeagueFlow.swift`; DEBUG `League/LaunchSheetFixture.swift`. Tests: `RecipientJourneyTests.swift`, `RecipientJourneyUITests.swift`, `tests/recipient-link-browser.mjs`. Ownership: `docs/planning/ACTIVE_WORK.md`. This folder holds the evidence and physical check sheet.

Database deploy owed: **none additional**; the unified branch still carries the prior Q2 migration `20261220090000_two_squads_play_the_final.sql`, awaiting the approved release path.

Edge deploy owed: **none**.

Client deploy owed: **root integration, web push and unified TestFlight upload**. No push, production deployment or upload performed here.

Open questions/risks: physical recipient auth, two-phone recovery, system widget privacy/lifecycle and natural background cadence remain unrun. They require the exact combined release and both test phones; use DEVICE-CHECKS.md. No Friends/public distribution change.

Recommended next step: integrate the owned sprint branch, inspect any merge resolutions, take the unified candidate through the approved release path, then execute and record the device sheet. The original dirty checkout remains untouched. Task HTTP server is stopped; task-created simulators are shut down at handoff.
