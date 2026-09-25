# Between-round widgets handoff · September 25, 2026

**Branch:** `codex/between-round-widgets-2026-09-25`, based on `origin/main`
at `70d68bcb`. Isolated checkout: `/private/tmp/cup-season-between-round-widgets`.
The preexisting, dirty visual-refresh workspace was left untouched.

**Goal:** Build the approved Race, Next Tee, Record, and Rivalry widgets using
Cup Season's current native design system and real, existing data contracts.

**What changed:** Four small/medium widgets, two Lock Screen accessories,
authenticated Next Tee replies, private deep links, independent freshness
clocks, account-switch protection, and native review fixtures. The existing
Live Activity is unchanged. The owner's requested Dynamic Island rethink is
a separate design exploration; no new score-entry behavior is shipped here.

**Files changed:**

- `CupSeason/Widgets/`: shared SwiftUI views, app-process RSVP intent, route
  handoff, and a DEBUG-only review gallery.
- `CupSeasonWidgets/CupSeasonWidgets.swift`, `Info.plist`, and `project.yml`:
  widget registration, shared sources, bundled fonts, generated configuration.
- `CupSeasonKit/Home/`: typed snapshot, app-authored feed, RSVP runner, and
  updates to DispatchSnapshot's sign-out cleanup.
- `CupSeasonApp.swift`, `HomeView.swift`, `MainTabView.swift`, `Presenter.swift`:
  refresh and signed-in destination routing.
- `CSDesign/WidgetControl.swift`: token-based 44-point reply button style.
- `BetweenRoundsWidgetTests.swift`, `BetweenRoundsWidgetUITests.swift`:
  data/ownership/action checks and native layout review.
- `docs/ios/DECISIONS.md` (IOS-082), implementation note, and this handoff.

**Verification run:**

- XcodeGen generation and iPhone 17 Pro Simulator build succeeded.
- 22 unit tests passed across `BetweenRoundsWidgetTests` and
  `WidgetSnapshotTests`.
- 2 UI tests passed, producing 17 capture states: four normal dark, four light,
  confirmed/error/stale/empty/nine-hole, and four long-text accessibility layouts.
  Visual review caught and fixed the initial large-text overflow before the
  final successful run. These are gallery checks of the production views,
  not system-hosted intent lifecycle tests.
- `npm run preflight`: **0 failures, 0 warnings**.
- `git diff --check`: clean.
- No dependency, migration, generated-token, or competition-rule changes.

Reproduce the focused tests from `apps/ios` after `xcodegen generate`:

```sh
xcodebuild -project CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:CupSeasonKitTests/BetweenRoundsWidgetTests \
  -only-testing:CupSeasonKitTests/WidgetSnapshotTests \
  -only-testing:CupSeasonUITests/BetweenRoundsWidgetUITests test
```

Local evidence: `/private/tmp/cup-season-widgets-accessible-tests.xcresult`,
`/private/tmp/cup-season-widgets-accessible-tests.log`, and
`/private/tmp/cup-season-widgets-preflight-final.log`. Review PNGs are preserved
in the task's visualization directory under `native-widget-review/`.

**Database deploy owed:** None.

**Edge deploy owed:** None.

**Client deploy owed:** A new native app + widget extension build. No web
deployment is needed. This branch has not been pushed or distributed.

**Open questions / risks:** Physical-device checks remain for system-hosted
RSVP with the app suspended/terminated, account authentication, and Lock Screen
privacy/redaction. Xcode emitted the existing Supabase SDK initial-session
warning and existing design-package concurrency warnings; neither failed the
build or tests. Widgets refresh from app-authored cached reads; they are not
push-updated standings. Large accessibility sizes intentionally omit secondary
details; long labels may truncate.

**Recommended next step:** Review the native captures and complete the device
interaction checks before native distribution. Choose a Dynamic Island design
direction before implementing its new live-round controls.
