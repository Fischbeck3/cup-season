# Compete consistency follow-through — 2026-09-12

**Release authorization — 2026-09-12:** after this review, the owner requested “Port to phone, push and move to test flight.” The review-time holds/status below are historical. The release will use this branch's committed source; actual phone and App Store Connect outcomes must be verified separately.

Owner authorized the recommendations from the offline/Compete review. Scope: native presentation and the misleading time frame in a historical sentence. Previous offline-course work remains in this branch. No gameplay, ranking, navigation, backend, icon or global palette changes.

## Changes

- `SeasonPage.swift`: compact existing board type for the season name, quieter metadata, story-sized serif instead of lead-sized serif. The existing golf terrain component replaces the polygonal contour at the heading. The story, roster and table remain on clear ground. Loading uses the updated heading scale. Selected-look accent behavior stays native and retains its existing precedence.
- `EventTitleCard.swift`: the same smooth golf-terrain family replaces angular course-seeded lines and the decorative dot. Terrain is restricted to the header, above the roster. Event titles and callout golfer names use the existing smaller board type. Faces, team colors, score figures, ceremony grounds and actions are preserved. No-course callouts retain their intentional plain ceremony ground.
- `SeasonStory.swift`: a weekly rank run is past tense and dated with `facts.last_snapshot_on`. If that date is absent, wording explicitly calls it the weekly record. No change to which story candidate wins, the historical rank, or the current table.

## Why the two positions differed

The latest checked-in `season_story` implementation reads today's standings into `v_now`. Its `my_run` history candidate counts the latest consecutive weekly `standings_snapshots`, which may end before today. `facts.last_snapshot_on` is the `captured_at` timestamp from that same final snapshot. The existing formatter used “You have held …” without this time boundary.

The correction uses existing server facts; it does not infer a date from today, a week count or `generated_at`. Following the existing L-07 convention, it prints the timestamp's calendar-date prefix. A missing/invalid date produces a clearly historical sentence without an invented cutoff. No schema, RPC or deployment is required. Source: `supabase/migrations/20261012090000_the_server_says_the_sentence_the_golfer_reads.sql`, the `v_now`, `v_snaps`, `last_snapshot_on` and `my_run` blocks.

## Voice example

Before: “You have held 2nd for four straight weeks.”

After, with the fixture's actual date: “Through Aug 30, you held 2nd for four straight weeks.”

No date: “Your weekly record includes four straight weeks in 2nd.”

The live position can be different without the historical sentence contradicting it. The season's story/receipt routes remain available.

- `CSDesign/Event.swift`: keep the existing horizontal accessibility roster and enable its native scroll indicator; verify both named teams can be reached. No normal-size roster change.
- `SeasonStoryTests.swift` and `CoursePrepCompeteReviewTests.swift`: regression coverage for historical/live rank differences, absent/invalid dates, calendar boundaries, narrow large-text headings and selected looks.

## Review boundaries

Real Compete/season screens are read-only account captures. Ryder/callout/Major screenshots use the existing DEBUG fixtures and do not claim real game results or enabled Major rollout. Nothing was sent, joined, posted or advanced for this review. All artifacts remain local. Archive/TestFlight remains on hold.

## Verification

- XcodeGen generation and CupSeason simulator build passed.
- First run: 37 passed, 0 failed (story/history/arc and three actual UI walkthroughs).
- Second run: 36 passed, 0 failed (history/date cases, look resolver/accent protections and three UI checks, including AX3 and selected looks).
- Three existing roster identity checks passed. Final AX3 roster interaction: 1 passed, 0 failed, with the entire second team brought into view. An earlier test scrolled the page past the roster before trying to swipe it; corrected the test sequence, preserving the existing roster behavior.
- Preflight passed with 0 failures, 0 warnings; final whitespace check clean. No baseline changes.
- Actual screenshots reviewed in light/dark, on the narrow SE, at AX3, and with the existing Claret selected look. The native look's secondary panel/tick colors and protected ceremony colors remain as configured.
- No new token/asset source, so no brand generator was required. XcodeGen generated the project from the existing source pipeline.

## Handoff

Branch: `codex/run-it-back-topo-2026-09-12`. Baseline commit: `0430f9d`; new edits uncommitted for owner review.

Gallery: `/Users/fischbeck3/cup-season-compete-consistency-review/index.html`.

Result bundles: `/tmp/cup-season-compete-consistency-first.xcresult`, `/tmp/cup-season-compete-consistency-final.xcresult`, and `/tmp/cup-season-compete-roster-check.xcresult` (three identity checks; initial offscreen-gesture failure), and `/tmp/cup-season-compete-roster-final.xcresult` (successful final interaction).

No database or edge deployment is owed for these changes. Phone remains on build 794. No push, archive, TestFlight or main merge.

Known presentation limits: large accessibility type intentionally makes the page taller; Ryder's roster retains its horizontal scroll; the Major preview still uses the existing abbreviated first-name roster and full player identities remain in the table. No-course callouts keep their plain ceremony header. These are not invitations or live scoring acceptance tests: no competition was created or advanced.
