# Selected Compete build · September 24, 2026

The owner asked to build to the recommendations after reviewing the three-direction proposal. The selected combination is **Scoreboard for Compete, the Book opening to Weeks, and Race as an additional Book view**. Broadsheet remains an exploration reference.

The recommended implementation keeps live-only ember, full `brandInk` text and monochrome terrain inside the ember band, and league-livery terrain on neutral grounds. The prominent Book door appears for at least ten golfers or any squad season. Small solo seasons keep Rounds & points. The race means **points counting today**, grouped by contribution week; it does not claim historical standings. Points ties, qualification seeds and final tiebreak results remain separate facts. No scoring mechanic changes.

## Scope to resolve before normal app integration

The earlier user instruction and the brief explicitly require unchanged Release behavior and DEBUG-only prototypes. A scope question is pending: lift that limit for normal app implementation, or keep this selected build a DEBUG-only preview. The request to build selects the recommendation; this record does not silently remove that earlier hard limit.

Local commits only, this worktree only, no migration files, no remote SQL, no deployment and no production sign-in remain in force either way.

## Integration findings

- `CompeteScreen` can reuse its existing ordering, invites, destinations and empty/loading states while replacing the lead band's rank-first composition with Scoreboard.
- `SeasonPage` owns the real room model and receipt routing; the Book should enter there rather than duplicating its lifecycle.
- Current reads do not supply the complete authoritative Book contract in the proposal. The adjustment row omits its assessment timestamp, the root rank can disagree with the points table, and the generic room query does not establish full-season coverage. A live Book cannot substitute authored fixture flags or inferred assessment weeks.
- The approved no-migration boundary leaves that server contract as prose. Normal app integration must explicitly account for its absence before claiming a complete live Book.

## Preparation within the existing DEBUG scope

The Book race now includes negative totals and earlier cumulative peaks in its plot range. Previously, a floor or other deduction could leave an earlier peak outside a scale derived only from final totals. A regression test covers the peak, a deduction below zero, a dropped round and a future contribution.

Book week columns and the race axis use the season's week count. The accessibility week selector starts at the current week, clamped to that season, rather than always week twelve.

The original gallery remains the reviewed exploration evidence from prototype commit `9959c620`; it has not been relabeled as captures of a normal app implementation.

## Preparation verification

- Native packages, app tests and the five Book UI checks: **1,506 passed, zero failed or skipped**. [Result summary](evidence/selected-native-tests.json), [console summary](evidence/selected-native-output.txt).
- `node tests/preflight.mjs`: **zero failures, zero warnings**. [Output](evidence/selected-preflight.txt).
- Standalone Debug simulator build: **BUILD SUCCEEDED**. [Result](evidence/selected-debug-build.txt).
- The first runner stalled before tests and was interrupted; restarting only the owned simulator recovered it. [Interrupted output](evidence/selected-interrupted-output.txt). The full original log remains `/private/tmp/cs-compete-selected-preparation.log`.
- A new fixture-only light/AX3 simulator capture confirms that the finished season starts on **Week 15**, with full names and exact contributions. [Capture record](evidence/selected-capture.json); PNG at `/Users/fischbeck3/cup-season-compete-explorations-review/selected-preparation/finished-book-ax3-light.png`.
- All Swift changes remain inside DEBUG. No normal app integration, migration, generated source or production action was made. The original package/runtime warning remains recorded in the native result.
