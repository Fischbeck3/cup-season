# Local verification · Compete and the Book

September 24, 2026. Prototype commit **9959c620**; the brief was committed first as **788dd5b**. Assigned worktree only: `/Users/fischbeck3/cup-season-compete-explore`, branch `codex/compete-explorations-2026-09-24`. Nothing pushed, merged, rebased, deployed or signed for distribution. No migrations or production account were used.

## Checks

| Check | Result | Evidence |
|---|---|---|
| Native app, both native packages, prototype UI | **1,505 passed, zero failures, zero skips** | [Result summary](evidence/native-tests.json), [console summary](evidence/native-output.txt) |
| `node tests/preflight.mjs` | PASS, zero failures, zero warnings | [Complete output](evidence/preflight.txt) |
| Debug simulator build | **BUILD SUCCEEDED** | [Build result](evidence/debug-build.txt) |
| Release source isolation | PASS: new types disappear; startup is the original `RootView()` expression after inlining the computed property; existing fixture changes disappear | [Source audit](evidence/release-scope.txt) |
| Gallery coverage and originals | **PASS: 564 files, all 324 required combinations, no errors** | [Capture audit](evidence/capture-audit.json) |
| Gallery controls | PASS: side-by-side filters, expanded direction groups, original PNG links, SE AX3 disabled; no browser console errors; JavaScript syntax valid | [Visual review](evidence/visual-review.md) |
| Contrast | Full primary and secondary ink on every text-bearing ground pass; bold topo is confined to empty strips | [Ratios](evidence/contrast.txt), [design reasoning](PROPOSAL.md#contrast-and-terrain) |

The native total includes **CupSeasonKit 1,251**, **CSDesign 120**, **app 129** and **prototype UI 5**. The seven new app tests reconcile every fixture against the real room model, verify ties, count flags, byes, dropped rounds and empty/future cells. UI checks exercise horizontal scrolling with frozen names, a cell with two receipts, the dropped round's receipt, AX3 week navigation, squads/golfers and all three small-league entry paths. The fifth UI check verifies that the squad contribution filter also scopes adjustment rows.

The required package suites run on the simulator through the app's Xcode scheme. The unrelated full app UI suite was not run; the five exploration UI tests are the selected UI scope. This is a local design prototype, not a production acceptance run. A source audit is not a Release archive or a binary equivalence claim.

## Reproduce

From the assigned worktree, generate the ignored Xcode project with `xcodegen generate` in `apps/ios`, then:

```sh
node tests/preflight.mjs
xcodebuild -project apps/ios/CupSeason.xcodeproj -scheme CupSeason \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=DC418592-2D15-43AA-9E83-B47D918D2956' \
  -derivedDataPath /private/tmp/cs-compete-explore-build \
  -parallel-testing-enabled NO -jobs 2 \
  -only-testing:CupSeasonKitTests -only-testing:CSDesignTests \
  -only-testing:CupSeasonTests \
  -only-testing:CupSeasonUITests/CompeteExplorationUITests \
  CODE_SIGNING_ALLOWED=NO test
```

The same project, scheme, configuration and destination with `build` gives the standalone Debug build. No signing identity, archive, upload or remote database is involved.

Launch with `-cs_dev_compete_exploration scoreboard` (or `race`, `broadsheet`). Add `-cs_explore_fixture tie|field|squads|upcoming|finished|multi` and `-cs_explore_screen root|season|entry|book|race|receipt|round|adjustments|root-bottom`. The capture manifest records the exact arguments for every image, including the existing appearance, type-size and look overrides.

## Simulator photographs

Gallery: `/Users/fischbeck3/cup-season-compete-explorations-review/index.html`.

Capture complete: **564 original PNGs**: 376 on iPhone 17 Pro and 188 on iPhone SE (3rd generation), both on iOS 26.5. The mandatory core covers 3 directions × 6 fixtures × 3 screens × light/dark × (standard, SE, standard AX3) = **324**. The remaining **240** show Book modes, late weeks, receipts, adjustments, squad contributions and the moment below three seasons. AX3 is the additional accessibility size on the standard phone; SE uses the default Large size in both printings.

The original PNGs stay in the new gallery, outside Git. The three direction totals are Scoreboard 216, Race 216 and Broadsheet 132; each device/type/printing configuration has 94 captures. Capture manifests include device ids, launch arguments, sizes and SHA-256 hashes. The scripts do not crop, composite or recolour the captures. A render check rejects blank app-launch frames and requires two identical frames, half a second apart, before retaining the original PNG. **The complete capture audit passed:** 324/324 mandatory combinations, 564/564 files with matching hashes and sizes, expected dimensions, and no blank frames or missing captures. See [capture-audit.json](evidence/capture-audit.json) and the [representative visual review](evidence/visual-review.md). Visual inspection is representative, not a claim that every pixel of all 564 screens was manually inspected.

```sh
python3 docs/design/compete-2026-09-24/capture.py \
  --device DC418592-2D15-43AA-9E83-B47D918D2956 --phone standard
python3 docs/design/compete-2026-09-24/capture.py \
  --device D1B26067-F4EC-4A20-93BD-3D348CFA7802 --phone small
python3 docs/design/compete-2026-09-24/gallery.py
```

The capture script resumes a manifest. Use `--surface contributions --refresh` to retake just that surface. It requires an already booted simulator with the Debug app installed. The Python environment needs Pillow for the blank-frame check only; no app dependency was added.

The new isolated simulator originally could not boot because macOS had nearly exhausted its process capacity. The owner explicitly approved shutting down the default iPhone 17 Pro. Only that existing simulator was shut down. The two new capture devices ran sequentially and are shut down after capture completion; other audit and QA devices were left alone.

## Failures encountered and corrected

[Actual failed output is retained here](evidence/corrected-failures.txt), including:

- The earlier fixture initializer read `self.upcoming` before `entries` was initialized. It now tests the initializer's `kind` argument.
- Initial UI tests queried title-case labels rendered as capitals, and a container accessibility identifier masked its child identifiers. Those test/query and identifier issues were corrected.
- A receipt row's blank area was not tappable. Full-row content shapes fixed the actual interaction defect; the receipt drill-down now passes.
- An attempted conditional root expression triggered Swift's “failed to produce diagnostic for expression.” A computed view with `RootView()` as its sole Release expression fixed compilation without adding a Release container.
- AX3 split the contextual tab names and points heading mid-word; the selected-tab context is now one line and column headings keep their natural width. Scroll content is clipped to its safe area. The final standard-phone set is retaken in full after this correction.
- A local runner stalled before the tests started and was interrupted after 179 seconds; restarting only the isolated capture simulator recovered it. Its original `TEST INTERRUPTED` output remains in the evidence.
- A squad contribution filter originally left unrelated adjustments below the table. The adjustment list now follows the visible rows; the final focused UI check verifies the empty adjustment state for Mudsharks.

Earlier failed runs remain failed evidence; they are not renamed as successful. The final green result is a separate run. Initial blank simulator frames were discarded and recaptured, not published as prototype screens.

## Existing defects and limits left for a separate change

- Home's checked-in rank window includes display name, splitting a 41–41 tie; the season table uses points-only competition rank. `LeagueRecord.finish` also uses a sorted index. The proposal records the source paths and required shared-standing decision. No production ranking or migration was changed.
- Shared `CSFigure` small labels over ember measure 2.72:1 dark / 2.86:1 light. The prototype uses full `brandInk`; the shipped component remains untouched.
- The test runner reports the existing Supabase Swift initial-session behavior warning (preserved in the result JSON). No exploration sign-in or production room read occurs.
- Receipts contain authored scored fixture facts. Gross score, course rating, slope and holes are explicitly marked unavailable. There is no claim of live RPC completeness or historical snapshot coverage.
- Navigation is intentionally limited to the exploration's season, Book and receipt screens. The pictured root tab strip is context, not five rebuilt tabs; at AX3 it states “Compete selected.” The read contract, desktop layouts, loading/error states and production receipt integration are proposals only.
