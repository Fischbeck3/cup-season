# Home review follow-through · 2026-09-12

Source: Claude commit `079a67f`, `docs/reviews/2026-09-12-home-no-photo-regression-review.md`. Codex independently traced the five reported defects below before changing its own branch.

| Finding | Disposition | Evidence / limit |
|---|---|---|
| 1. Loading uses the no-photo slat | Fixed: reserve 168pt while loading; failure alone becomes a slat; distinct loading accessibility identifier | App builds; actual invalid-image UI test now waits for failure, not loading. The empty-to-success phase geometry is source-reviewed; slow-network/recycling behavior was not separately measured. No claim about AsyncImage's universal caching behavior is needed. |
| 2. Name opens different destinations | Fixed native: 44pt face opens golfer, name opens receipt, matching web | Native UI test activates name and face separately; browser test activates name and face separately. Failed-image test retains receipt-body coverage. |
| 3. Extra web plus during reveal | Fixed: invitation hides, four choices replace it, focus moves to first | Browser asserts four visible choices, no visible plus, correct keyboard focus, select/remove counts and no receipt activation. |
| 4. Missing-course spoken copy | Fixed null, empty and whitespace course cases in both clients | Native test checks full sentences with and without gross; browser checks photo and record accessibility labels. Existing client copy functions retained pending the broader server-copy work. |
| 5. Milestone without gross on photo | Fixed web photo milestone and performance-band guards | Browser checks photo and record variants with no gross and milestone/performance payload flags. |
| 6. Possible synchronous photo-render re-entry | Open; no production change in this batch | The synchronous branch exists, but the claimed split-flap symptom has not been reproduced. Existing actual bad-image and refreshed-image flows pass. Needs an isolated cached-failure/arrival reproduction. |
| 7. Gross minimum width | No change in this batch | Native's documented right-flush figure remains right-aligned for 79/84/108 in the inspected screenshot. Differing figure-block widths are visible; a shared fixed left edge was not established as a requirement. |

The review also noted a collapsed-feed/digest discoverability edge and obsolete form-row caption plumbing. These remain follow-ups, not resolved by this patch.

## Verification

- `xcodebuild test` on iPhone 17 Pro, parallel testing disabled, selecting `CupSeasonKitTests` and `CupSeasonUITests/HomeNoPhotoTests`: **1,096 passed, zero failed or skipped**. Result: `work/home-review-fixes.xcresult`.
- `tools/web-verify.mjs` evaluating `tests/home-function-browser.js` at **390 and 320px**: passed; no unexpected console errors or horizontal overflow. Result: `work/web-home-review.log`.
- Same browser runner evaluating `tests/app-tests.js` at 390px: **461 assertions, zero failures**. Result: `work/web-home-review-general.log`.
- `npm run preflight`: **zero failures, zero warnings**. Result: `work/preflight-home-review.log`.
- Inspected native normal-size reaction screenshot, native failed-photo AX3 screenshot, and web 320px screenshot. Record hierarchy remains readable; AX3 stacks the gross; revealed reactions have no extra plus.
- `git diff --check`: clean. No generated files, migration, scoring, or deployment changes.

These are local fixtures and domain tests, not a new claim of live posting/authentication/push verification. The earlier broader native run remains recorded separately; this batch did not rerun every native suite.

## Handoff

Branch: `codex/home-no-photo-2026-09-12`.
Goal: resolve confirmed Home regressions before the next feature.
What changed: photo-loading state, destination consistency, reaction reveal, missing-course copy, and no-score claim guards.
Files changed: `HomeWire.swift`, `HomeWireCopy.swift`, `HomeTests.swift`, `HomeNoPhotoTests.swift`, `index.html`, `tests/home-function-browser.js`, `spec/decision-log.md`, `spec/inbox.md`, this report.
Verification run: native 1,096; web 461 plus two-width Home flow; preflight; screenshot and diff review.
Database deploy owed: none.
Edge deploy owed: none.
Client deploy owed: native/web changes remain local; TestFlight held.
Open questions / risks: finding 6 unproved, finding 7 unchanged, after-golf contract pending; current branch has no upstream and its pull could not rebase.
Recommended next step: Claude independently reviews this commit; Codex reviews Claude's contract follow-up before any after-golf persistence implementation. Continue with draft-preserving composer prefill once scope is agreed.
