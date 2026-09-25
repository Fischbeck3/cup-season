# Selected Compete build · verification

September 24, 2026. Branch `codex/compete-explorations-2026-09-24`, only in `/Users/fischbeck3/cup-season-compete-explore`. Normal native/web implementation was authorized by the owner and recorded in D381. Nothing was pushed, remotely applied, deployed or distributed.

## Source and result

- `49c219ea`: Scoreboard, the Book, shared points rank, local read migration, fixtures and tests.
- `bfe9a27b`: readable short week dates and full season identity/span.
- `f5f2a5db`: DEBUG capture shell inherits the same livery tint as MainTabView; native/web lead sentences aligned.
- Original exploration source `9959c620` and its 564 simulator captures remain unchanged. Selected-build evidence is separate.

**All required checks pass.** Across the final relevant runs, **1,520 distinct native tests pass**: CupSeasonKit 1,261; CSDesign 120; app 130; UI 9. This is a combined result, not a claim that the initial full run passed. The two initially failing UI assertions were corrected and rerun. One additional Kit regression was added and the entire Kit target rerun. Subsequent layout and fixture-shell changes were checked with the four Book UI tests.

| Check | Result | Evidence |
|---|---|---|
| CupSeasonKit | 1,261 passed, no failures/skips | [xcresult summary](evidence/selected-build/kit-final.json), [output](evidence/selected-build/kit-output.txt) |
| CSDesign + app + original exploration UI | 120 + 130 + 5 passed in full run; targets unchanged afterward | [first full summary](evidence/selected-build/first-full.json) |
| Selected Book UI | 4 passed, no failures/skips, on final fixture shell | [xcresult summary](evidence/selected-build/book-ui-final.json), [output](evidence/selected-build/book-ui-output.txt) |
| Debug simulator build | BUILD SUCCEEDED | [output](evidence/selected-build/debug-build.txt) |
| `node --test tests/*.test.mjs` | 58 passed, no failures/skips | [output](evidence/selected-build/node-tests.txt) |
| Book's focused Node checks | 8 passed | [output](evidence/selected-build/book-node-tests.txt) |
| `node tests/preflight.mjs` | 0 failures / 0 warnings | [output](evidence/selected-build/preflight.txt) |
| Fresh PostgreSQL 17 migration chain, synthetic seed, migration reapplication and contract verification | PASS | [output](evidence/selected-build/database.txt) |

The Node runner reports 58 tests; some preexisting files also report their own internal assertion totals. The Book's eight checks are included in that runner, not eight additional top-level tests.

## What was exercised

The local database verification uses a fresh, task-owned PostgreSQL cluster and the repository's full migration chain. It checks authenticated membership and season agreement, outsider/unknown/mismatched-season denial, explicit role grants, weekly and cumulative reconciliation against the real standings views, adjustment scope and assessed dates, multiple rounds in a week, included versus dropped rounds, byes, outside-week entries, equal points ranks, completed current-rule provenance, and parity with `native_home`. Migration reapplication also passes. No production connection or account was used.

Measured synthetic read sizes: 16 golfers × 15 weeks **85,350 bytes / 4,091 gzip**; squads plus individual/contribution scopes **257,117 bytes / 10,599 gzip**, including 193 scored rounds. Fresh local timings were 31 ms and 59 ms, including `psql` startup. These are local measurements, not production latency estimates.

Native tests cover real RPC JSON, authoritative totals, incomplete/wrong-identity reads, stale request protection, retry, squad adjustment scope, drops, ties, negative race domains and champion semantics. UI tests exercise fixed names with horizontal weeks, receipt navigation, the compact small-league read, the root Book door, AX3's week picker and switching into Race.

Browser checks use the real production rendering functions with a disconnected synthetic RPC. Verified: wide matrix with adjacent named receipts; Week 12's included/dropped rounds and adjustment; cumulative totals; squads/golfers/contribution filtering; Race; suppression of an incomplete weekly curve when points sit outside the axis; first-read failure and successful retry; narrow 375-point layout; both printings. The harness bundles the app's existing licensed typefaces and requires no sign-in or external service.

## Captures

[Selected capture manifest](evidence/selected-build-captures.json): **36 unedited simulator PNGs**, SHA-256 checked, all from `f5f2a5db`. Twenty-eight are iPhone 17 Pro, eight are iPhone SE. Both printings are represented; standard-phone AX3 captures cover the root, golfer Book and receipts. Subjects include the 41–41 tie, several seasons, season room, 16 golfers, four squads, weekly and cumulative points, Race, receipts, upcoming and completed states.

The actual production renderers are entered through the DEBUG-only `-cs_dev_compete_selected` hatch and synthetic payloads returned by the local SQL implementation. The hatch skips normal auth startup, push and telemetry. Its navigation shell now inherits the same tint as MainTabView; this fixed system-blue menu controls that appeared only in the first capture harness. The Book's short week dates no longer truncate; the full season date span is visible. Native captures and desktop browser captures are labeled separately.

Gallery: `/Users/fischbeck3/cup-season-compete-explorations-review/selected/index.html`. The original gallery links to it without replacing its 564 exploration captures. Reproduction scripts: `capture-selected.py`, `gallery-selected.py`, and `tests/fixtures/season-book/build-review.py`.

## Failures found and resolved

The first full native run had **1,519 tests: 1,517 passed, 2 failed**. Both failures were new UI assertions expecting title-case “Rounds & points”; the real type treatment uses uppercase. The tests now locate the stable `seasonBook.title` identifier and compare normalized copy. The screen and navigation already worked. [Exact retained failure output](evidence/selected-build/resolved-failures.txt) and the [original summary](evidence/selected-build/first-full.json) preserve the red run.

An earlier UI-test compile error called `.count` on an `XCUIElement`; corrected to a query assertion. A cold simulator test launch stalled before tests; restarting only the task-owned simulator recovered it. Early preflight findings were a zero-radius CSS declaration sharing a line with a background declaration and an unnecessary uppercase UUID operation in a test; both were corrected. Final checks are green.

After the capture-shell tint correction, another run completed all four UI tests but stalled in report finalization. Only that owned `xcodebuild` process was terminated. A `test-without-building` rerun with `-collect-test-diagnostics never` and an explicit result-bundle path completed with **TEST EXECUTE SUCCEEDED**, four passed, zero failures. [Retained report-stall output](evidence/selected-build/book-ui-report-stall.txt).

Existing tooling warnings remain: CSDesign actor-isolation diagnostics, skipped AppIntents metadata extraction, and the Supabase SDK's initial-local-session warning. No production session was established. They did not fail builds or tests. The complete local command logs remain under `/private/tmp/cs-season-book-work`; durable summaries and relevant failure output are committed here. Xcode purged the first full xcresult directory during later runs, so its previously extracted JSON summary is retained instead.

## Commands and limits

Native checks use Xcode's CupSeason scheme, Debug, `CODE_SIGNING_ALLOWED=NO`, `-jobs 2`, `-parallel-testing-enabled NO`, the task-owned standard simulator, and derived data at `/private/tmp/cs-compete-explore-build`. The full run is `xcodebuild test`; targeted reruns use `-only-testing:CupSeasonKitTests` and `-only-testing:CupSeasonUITests/SeasonBookUITests`. The standalone Debug check is `xcodebuild … build`. The final Book UI rerun uses `test-without-building -collect-test-diagnostics never -resultBundlePath /private/tmp/cs-season-book-work/BookFinal.xcresult` with the same target, device and built products.

The local database reproduction is `tests/fixtures/season-book/run.sh`; see its README for PostgreSQL requirements and safeguards. It creates and stops only its own fresh cluster. Node commands are listed in the table above. None of these commands deploys anything.

The Book reports points counting today. It does not claim immutable historical standings or locked historical rules. An outside-week contribution remains in the totals/receipts and prevents a misleading race curve. The RPC explicitly refuses reads beyond 104 weeks, 200 golfers, 10,000 rounds or 10,000 adjustments. A missing RPC produces a load error with retry. These are documented product limits, not open implementation failures.

The local migration `20261118090000_the_book.sql` remains unapplied remotely. Database review/application must precede client shipment. Web deployment and native distribution remain separately unauthorized; no Edge change is owed. D381 settles the design rulings. Historical snapshots and larger-field pagination would be separate work.
