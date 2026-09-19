# Claude review · Codex's two commits stacked on the release candidate — 2026-09-19

Reviewed: `39c8d00` (calendar copies, atomic course cache) and `2908aa3` (live score marks, D370) on `codex/live-scoring-moments-2026-09-19`, both local and unpushed in `/Users/fischbeck3/cup-season-integrations`, both based on this branch's tip `144e3dc`. Nothing in that workspace was edited. Nothing was deployed.

## Verdict

**`20261111090000_course_cache_atomic` is safe to ride with the two pending migrations. One hardening is recommended before the `courses` function is deployed (finding 1). The web and native halves of `2908aa3` were not device-reviewed here.**

## What was run

| Check | Result |
|---|---|
| Full-chain sandbox (`tests/sim/sandbox/apply.sh`, port 5479) at `2908aa3` | **249 applied, 0 skipped** — `20261109`, `20261110` and `20261111` apply in order on top of production's 246 |
| Preflight at `2908aa3` | 0 failures, 0 warnings (check 50 sees 3 migrations since the rule) |
| `cache_course_card` grants, sandbox roles | `anon` no, `authenticated` no, `service_role` yes; ACL is exactly `postgres`, `service_role` |
| Client writes to the three cache tables as `authenticated` | DELETE and UPDATE touch 0 rows, INSERT refused by row security (SELECT-only policies). The table-level write grants are pre-existing and inert |
| Atomicity as `service_role` | A good card saves; three failing refreshes after it (fractional slope, empty-string latitude, null hole number) each roll back whole; the kept card is unchanged |
| Tee identity | `on conflict (course_id, gender, tee_name)` has its unique constraint (`20260714050000`), so a refresh keeps tee ids — an improvement on delete-and-reinsert |
| Codex's tests | `calendar-export`, `course-provider` pass; `course-cache-postgres.py` PASS |

## Findings

1. **A malformed number now fails the whole course, permanently (low likelihood, recommend fixing in the function, not the migration).** The SQL casts strictly: `"slope_rating": 113.5` raises `invalid input syntax for type integer`, and `"latitude": ""` raises on `double precision`. Before, one bad tee was skipped and the rest of the course cached. Now the golfer gets "Course card could not be saved; please retry", and a retry can never succeed because the provider's payload is the cause. Remedy in `flattenTees`/`fetchAndStore`: coerce before the RPC — integers through `Number.isFinite(n) ? Math.round(n) : null`, coordinates through the same finite check — and keep the SQL strict. First question: has the provider ever sent a non-integer slope or yardage? `api_courses.raw` in production can answer that read-only.
2. **The provider error log lost its body snippet.** The old line logged status plus 200 characters of body, and its comment said why: 429, 401 and 5xx need different responses from the founder. Status alone still separates those three, so this is acceptable; the deleted comment explaining the three cases was worth keeping.
3. **`tests/live-score-marks-browser.js` is not runnable under Node** (`csLiveScoreClass is not defined`) — it is a snippet for a page context and nothing in CI or preflight runs it. Either name it as a manual browser probe in its header or wire it into the existing browser harness; as it stands it reads as coverage and is not.
4. **Codex's note about three failing CSDesign tests is correct, and the miss was Claude's.** `noLookIsEmber`, `homebaseReachIsExactlyWhatItWas` and `bothThemesCarryEveryColourToken` pinned the pre-D359 contract (no look = ember, ember tick, 81 tokens). D359 (2026-09-14) made the fallback `act`, the homebase tick muted ink, and added `act` and `brand-ink` (83). The source was right and the tests were stale, unnoticed because the CSDesign scheme has no test action and the package is in no run list. Fixed on this branch; 120 tests in 32 suites pass. The command, since AGENTS.md does not carry it:

   ```bash
   cd apps/ios/Packages/CSDesign
   xcodebuild test -scheme CSDesign -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

   (`swift test` cannot build the package on macOS: it uses iOS-17-only API.)

## Not verified

- The native and web live-score marks and the carded moment, on a device or in a browser. Codex's record lists its own evidence; this review did not reproduce it.
- The calendar copy on a real phone calendar.
- Kit and app test suites at `2908aa3` (Codex reports 1,226 Kit passing; not rerun here).

## Deploy owed if these two commits join the candidate

Database: `20261111090000` with the other two. Edge: `courses` must deploy **after** the migration, or every detail fetch fails on a missing RPC.
