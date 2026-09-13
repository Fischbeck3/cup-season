# Every native test, and what its result means — 2026-09-13 closeout

F3 · the repair handoff said "eight failures". The whole-target result is not
eight, and the shape of it matters more than the number. This accounts for every
test in the run: **each failure and each skip, with its cause and a disposition.**

Run on the closeout commit, whole scheme, iPhone 17 Pro:

```sh
cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath /tmp/cs-closeout-native.xcresult
```

---

## 1 · The totals

The run reached its terminal marker (`** TEST FAILED **`, failing on the 14
account-dependent tests below), so these are complete counts and not a partial
run.

**Swift Testing** — three runs, every one green:

| Tests | Suites |
|---|---|
| **1,158** | 188 |
| **120** | 32 |
| **85** | 17 |

**XCTest** — per target:

| Target | Result |
|---|---|
| `CupSeasonKitTests` | **16 passed** |
| `CupSeasonTests` | **22 passed** |
| `CupSeasonUITests` | **41 executed · 21 passed · 14 failed · 6 skipped** |

XCTest cases in total: **79 — 59 passed, 14 failed, 6 skipped**.

*(Corrected after re-deriving from the completed log: an earlier draft of this
file attributed the 120-test Swift Testing run to `CupSeasonTests` and put its
XCTest count at 38. The app target's XCTest count is 22, and the three Swift
Testing runs are listed above without guessing which target hosts which.)*

The previous inspection counted 38 UI tests (18 passed). This run has 41 because
the closeout adds three. Both readings agree on the failures and the skips.

**Every failure and every skip is in the UI target, and every one of them is a
missing precondition rather than a defect.** That is established below from
source, not asserted.

---

## 2 · The 14 failures — all need a signed-in account

`-cs_dev_open <destination>` is the hatch these suites use, and it is gated:

```swift
// apps/ios/CupSeason/Main/MainTabView.swift:503
guard !devOpened, store.me != nil, let i = a.firstIndex(of: "-cs_dev_open"), …
```

`store.me != nil` is a signed-in session. **This simulator has no session**, so
the hatch never fires, the destination never opens, and the test fails looking
for an element that was never going to render. The failures read as missing
identifiers (`compete.row.`, `season.title`, `course.plan`,
`offline.courses.open`, `round.share.preview`) — the shape of an empty screen,
not a broken one. One of them says so in its own assertion message: *"Use the
signed-in review simulator."*

| Test | First failure | Disposition |
|---|---|---|
| `AcceptedRoundReviewTests.testReplayedAcceptedCompletionOpensReceipt` | no "View receipt" button | missing precondition — `-cs_dev_open receipt` needs a session and a real round |
| `AcceptedRoundReviewTests.testAcceptedReceiptToPreviewAndPhotoOptOut` | no `round.share.preview` | same |
| `CompeteBoldReviewTests.testAppearancesAndExistingDoors` | **"Use the signed-in review simulator"** | missing precondition, stated by the test itself |
| `CompeteBoldReviewTests.testNarrowAccessibilityLayout` | no `compete.row.` | same |
| `CompeteGameplayReviewTests.testRealCompeteSeasonAndCreationDoors` | no `compete.row.` | missing precondition |
| `CompeteGameplayReviewTests.testGameplayRoomsWithLabeledFixtures` | assertion on an absent room | missing precondition |
| `CompeteGameplayReviewTests.testLargeTextCompetitionHeaders` | no `season.title` | missing precondition |
| `CompeteGameplayReviewTests.testLargeTextRyderRosterReachesBothTeams` | no `event.side-roster` | missing precondition |
| `CompeteGameplayReviewTests.testSeasonSelectedLookInBothRooms` | absent season room | missing precondition |
| `CoursePrepReviewTests.testKeptCourseOpensPrefilledPlan` | no `course.plan` | missing precondition — `-cs_dev_open coursecard` |
| `CoursePrepReviewTests.testSaveBajamarThenUseItWithoutNetwork` | no `offline.courses.open` | missing precondition |
| `CoursePrepReviewTests.testSavedCoursePreparationAtAccessibilitySize` | same door | missing precondition |
| `OfflineTripReviewTests.testOfflineColdBootOffersScoringToRestoredAccount` | needs a **restored account** by name | missing precondition |
| `OfflineTripReviewTests.testBajamarLookupWithoutStartingRound` | needs the course catalogue behind a session | missing precondition |

`CompeteGameplayReviewTests.testRulesAndHeadToHeadDoors` and
`OfflineTripReviewTests.testScoreRelaunchAndKeepLocalRound` **pass** in the same
suites — they are the cases that do not need an account. That is the control:
the suites are not broken, the session is absent.

**This is not a verification of those journeys.** A missing precondition
explains a red; it does not turn it green. Saved course, offline resume and the
Compete rooms are unverified in this pass and are listed as owed below.

## 3 · The 6 skips — explicit, by design

Each throws `XCTSkip` with its own reason rather than failing, because a false
red on a machine with no session teaches nobody anything.

| Test | Reason in source |
|---|---|
| `SettingsReachableTests.testTheCornerSettingsLinkIsHittableAndOpensSettings` | "Not signed in on this simulator — copy the keychain in and re-run." |
| `SettingsReachableTests.testTheFootDoorIsHittableAndOpensSettings` | same |
| `SettingsReachableTests.testATertiaryLinkFiresOnAnotherScreen` | same |
| `SettingsReachableTests.testTheStartSomethingBandOpensTheIntentSheet` | "The ⊕ cover never opened — not signed in on this simulator" |
| `TabPersonalityTests.testGolferRowOpensPlayerCard` | "Requires the signed-in review account with buddies" |
| `TabPersonalityTests.testCompeteCreationStillOpensIntent` | same |

## 4 · The 21 UI passes — including every changed journey this pass touched

| Suite | Tests | Covers |
|---|---|---|
| `AfterGolfAnswerTests` | 5 | the lead placement: all three actions hittable and ≥44pt, at AX3, in light, a failed answer keeping the card, the door as primary |
| `AfterGolfWirePlacementTests` | 3 | **F1** · the displaced/empty-feed placement: all three actions, at AX3, failed answer keeps the card |
| `HomeNoPhotoTests` | 4 | Home photo fallback, reactions, person/receipt doors |
| `LeagueSetupReviewTests` | 2 | setup review and confirmation, incl. accessibility size |
| `ReturnFlowReviewTests` | 2 | sign-in terrain and controls |
| `OfflineTripReviewTests` | 1 | score, relaunch, keep the local round |
| `CompeteGameplayReviewTests` | 1 | rules and head-to-head doors |
| others | 3 | brand artifacts, round card, offline course model |

Plus, in `CupSeasonTests`, **`AfterGolfPlanRouteTests` (6, all passing)** — what
the after-golf tap actually carries: the handoff read once and cleared, a blank
composer taking the day played and the course as text with no catalogue id, a
typed course kept with the question saying so, the consent gate counting every
typed field including the gross, and the draft holding plan, request and kept
scorecard apart.

---

## 5 · What is still unverified, and why

No authorized review account is available in this workspace. Signing in would
need a real one-time code and would touch production data, which is outside a
closeout and is the owner's call. So these remain owed, and are **not** described
as passing anywhere:

- **Saved course / offline course preparation** — `CoursePrepReviewTests`, 3 tests.
- **Offline cold boot with a restored account** — `OfflineTripReviewTests`, 1 test.
- **Compete rooms, season page, Ryder roster, Major fixtures** — `CompeteBoldReviewTests` and `CompeteGameplayReviewTests`, 7 tests.
- **Accepted-round receipt and share preview** — `AcceptedRoundReviewTests`, 2 tests.
- **Settings reachability and tab personality** — the 6 skips.
- **Plan → composer as a real tap through the presenter.** The fixture renders
  Home outside the tab shell, so no presenter raises the composer. The seam is
  covered by `AfterGolfPlanRouteTests` and the browser suite; the tap itself
  belongs to a device or signed-in pass.

Codex's release workspace has the signed-in simulator these need.
