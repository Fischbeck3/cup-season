# Offline preparation and Compete experience review — 2026-09-12

**Release authorization — 2026-09-12:** the subsequent Compete follow-through was reviewed and the owner requested phone installation, branch push and TestFlight. Review-time holds/status below are historical; actual release outcomes must be verified separately.

Owner request: build a clear course preparation flow, then explore Compete gameplay and provide actual visuals against the current brand direction. Preserve established UX, mechanics, selected looks and protected colors. TestFlight remains on hold.

## Course preparation

Entry points: Play → Score it live → Save courses for offline; and the existing Courses page → Save courses for offline.

Search while online, pick a course/tee, then Save for offline. The existing course book service downloads the available tee cards. The preparation write must succeed and decode from disk before the UI reports success. Each tee is checked separately: actual rating/slope, 9 or 18 holes, consecutive unique hole numbers, and real pars. Missing data is not filled with defaults. Tees with missing data remain Not ready.

The saved-course list works from local storage, including the boot-failed offline entry. A ready tee can be loaded straight into live setup without another network call. No round starts during preparation. Selecting Score on this phone still controls scoring mode; changing the solo default is a separate, not-yet-implemented proposal.

Downloads are guarded against duplicate taps. A failed download retains the old saved course and reports the failure. Partial cards remain visibly incomplete. The existing cache is limited to forty recently used courses and clears at sign-out; the UI makes this explicit instead of promising permanent downloads.

## Compete functions under review

| Door | Existing experience | Review boundary |
|---|---|---|
| Your Seasons | Season table, counting rounds, rules, activity and context | Open existing season; no score or settings changes |
| Start something → Run a season | Crew, length/dates, stake, final review/name | Inspect setup without starting a season |
| Play with my friends | Now/live scorecard or a planned round | Existing action fork; no new game |
| Go head to head | Pick golfer, then live match / one-week callout / season | Inspect length and invitation composition; do not send |
| Weekend / event | Ryder; Major where the feature flag allows | Existing setup; no event creation |
| Ryder | Two sides, weekly pairings, scores and event result | Labeled existing DEBUG fixture for populated room |
| Callout | Two golfers, deadline, round result and receipt | Labeled existing DEBUG fixture |
| Major | Championship window, individual standings and trophy | Labeled existing DEBUG fixture; does not prove rollout enabled |
| Run it back | The Pro confirms the next season; a member requests it | Existing guards/tests; no season advanced during review |

## Files changed

- CourseBook: per-tee offline readiness and truthful status.
- CourseDisk: explicit verified save with surfaced storage errors.
- CourseBookStore: preparation uses verified disk write.
- OfflineCoursesSheet: search/save/retry/readiness/list and saved-tee selection, using the existing store and picker.
- LiveSetupView / LiveRoundStore: preparation entry and network-free use of a saved tee.
- CoursesScreen: preparation entry in the existing course directory.
- LengthStep: wrap the head-to-head record-only choice on narrow screens.
- Native/app/UI tests: missing data, duplicate holes, storage failure, retry, duplicate tap, actual Bajamar download and offline reopen, plus Compete review captures.
- This review and `spec/inbox.md`: capture findings and follow-up boundaries.

No new backend work, navigation destination, scoring logic, token, font or logo change.

## Findings from actual screenshots

1. **Topo family mismatch.** Compete's root uses smooth `CSTopoField` terrain. `SeasonPage` and `EventTitleCard` still use polygonal `CSContour`, with much heavier presence behind dense title/roster text. Recommendation: a focused contour consistency pass using the existing golf contour family, preserving course/league identity where useful and keeping the field away from dense content. No whole-screen redesign.
2. **An apparent current-rank/history contradiction.** The real Compete row reads 1st, while the season headline says “You have held 2nd for four straight weeks.” The `my_run` producer counts weekly `standings_snapshots`; the Swift history formatter uses present-tense wording without the snapshot date. Historical snapshots can lag today's table. This needs a dated-history/current-rank check, not a typography workaround. Neither rank nor scoring changed here.
3. **Setup choice clipped.** The head-to-head “Nothing, just the record” option truncated at default text on the SE. Fixed only the wrapping/minimum height. Its meaning, selection and send behavior are unchanged.
4. **Hierarchy still varies.** The event header and season editorial sentence occupy much more of the first viewport than the root. The useful standings/rounds sit farther down. Recommend tightening header spacing/type scale selectively, not copying DesignV1 phone layouts.
5. **Keep the useful parts.** Paper/fescue grounds, quiet rules, people markers/photos, printed score figures and clear existing entry paths already work together. Existing light-mode action contrast variants, team pigments, earned treatments and ceremony colors are intentional protected roles, not arbitrary new colors.

No competition or invitation was created/sent. Fixture rooms show current rendering only, not proof of production scoring outcomes. Major screenshots do not claim that its creation flag is enabled for every golfer. Real screenshots remain local owner-review artifacts.

## Visual iteration

The first actual large-text capture exposed that the new sheet had not inherited the developer Dynamic Type override. Applied the existing `csSheet`/`csDevTextSize` presentation pattern, then checked the genuinely enlarged UI. That exposed a scroll-position defect when opening a saved course, so selection now opens a separate course-detail state with a Saved courses return link and a fresh scroll position. The new sheet uses a quiet in-content Close control rather than the system glass toolbar treatment.

Initial test-harness selectors incorrectly waited for Close in event rooms that use Back and selected an obscured underlying course field. Corrected selectors to the actual controls; no product behavior was changed to satisfy those assertions. An initial timing-based duplicate-tap test wait was replaced by a deterministic continuation.

The genuine accessibility-size run also exposed over-wide mini links. The new preparation actions now use the existing wrapping tertiary-link style; long tee names no longer stretch the sheet horizontally. Normal-size and AX3 checks pass after the correction.

## Verification and handoff

- XcodeGen generation and the actual CupSeason simulator build: passed.
- Sixteen app/domain checks passed: two preparation-model tests, two readiness/storage tests, and twelve existing course-book tests.
- Five distinct UI checks passed across the review runs: real Bajamar save/offline reopen and tee load; genuine AX3 readiness/action reachability; real Compete/season/creation navigation in both rooms; Ryder/callout/Major fixture rooms in both rooms; rules/head-to-head setup. The final preparation-only rerun passed both checks with no failures.
- `npm run preflight`: zero failures, zero warnings. `git diff --check`: clean. No baseline or generated source edits.
- Final course UI result: `/tmp/cup-season-prep-wrapping-final.xcresult`. Earlier unit/domain result: `/tmp/cup-season-prep-accepted.xcresult` (its old AX3 failure is superseded by the final rerun, not ignored). Compete fixtures/rules: `/tmp/cup-season-prep-review-final.xcresult`; real Compete navigation: `/tmp/cup-season-prep-review.xcresult`.
- Gallery: `/Users/fischbeck3/cup-season-course-compete-review/index.html`. Screenshots are actual iPhone SE simulator captures, with DEBUG fixture rooms labeled.

Branch: `codex/run-it-back-topo-2026-09-12`. Baseline commit: `0430f9d`. Changes remain uncommitted for owner review. No new backend/edge deployment needed. Phone remains on build 794; this preparation UI is only in the local simulator build. No push, archive, TestFlight upload or main merge in this pass.

Remaining limits: catalogue search/download still needs service; the cache is capped at forty courses and clears on sign-out; this task did not repeat the prior three-round posting/recovery test or advance a real competition. The final large-text check establishes readiness/action reachability, while the normal-size check follows the selected tee through to the loaded live card. Review the contour mismatch and dated history sentence before a focused Compete follow-up.
