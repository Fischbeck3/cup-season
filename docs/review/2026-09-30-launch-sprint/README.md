# Launch sprint · September 30, 2026

Owner selected sprint items **1, 2, and 4**: unify the release candidate, finish Q2's SQL announcement, preserve Book selections across refresh.

Branch: `codex/launch-sprint-2026-09-30`

Workspace: `~/.codex/worktrees/launch-sprint-2026-09-30/cup-season`

Base: fetched `origin/main` at `5d70caeb`.

Verified source candidate: `362ccffa` (the following evidence commit changes documentation only).

## Candidate integration

- Build 2 `4ebce2f2` merged at `8c4eb8bb`.
- D400 widgets `1e43b1a6` merged at `0a64f496`.
- Approved Home feedback `1664d7cd` is an ancestor. Home's layout is retained: its diff from main adds the What's On publisher and changes a fixture comment. CompeteScreen has no diff from main.
- The one merge conflict was WidgetReviewFixture: keep What's On cases and Build 2's synthetic cast together. App/extension routing, background-task registration, manifest entries, and exhaustive widget-kind switches compile.
- Q2 committed at `2b8bcff6`; Book defaults at `a9aa6e9b`. Book refresh cancellation repair: `362ccffa`.

## Q2 · both squads play the Final

New migration: `supabase/migrations/20261220090000_two_squads_play_the_final.sql`.

Spec §14.3, D126 and OWNER-QUESTIONS Q2 row 5 already govern this behavior; this is copy repair, no scoring/mechanic change. The new migration patches one asserted sentence in the deployed function definition, preserving later D384 guards. Two squads hear that both play and the leading squad carries a 10-point head start. Solo and larger squad structures hear their own top-two unit. Points-table wording stays exact; historical posts are not rewritten. RPC grants explicitly revoke public/anon and grant authenticated.

Proof: `python3 tests/finish-announcement-database.py` uses a unique disposable PostgreSQL 17 cluster, Unix socket, no network listener, no production URL. It reproduces the false cut before the patch, applies all 288 migrations with zero skipped, reapplies the patch idempotently, exercises all four structures, verifies one saved announcement per RPC, preserves old posts, rejects invalid/non-Pro calls, checks short-season/open-window/entered-Final guards, and verifies execution grants. 58/59 database checks pass; the runtime pg_cron registration check is unavailable in the local stand-in. This does not verify production cron health. Cluster stopped and removed.

## Book · defaults once per season, complete refreshes

SeasonBookSelection remembers the league/season identity. The first successful read sets squad/golfer scope, current week and Every golfer; another read of the same season preserves deliberate selections. A different season gets its own defaults. Display and Follow already survived refresh and retain that behavior.

Actual pull-to-refresh uncovered another defect: clearing the snapshot before an async read shrank the scroll content, cancelled SwiftUI's refresh task and left a loading page. SeasonBookStore now retains the same season while a refresh is pending or cancelled. A different season clears immediately. A real read error still clears the snapshot and exposes the existing Try again state; selections survive the retry.

Regression coverage includes delayed success, failure/retry, new-season defaults, in-flight cancellation, late old-season responses and actual pull-to-refresh. The DEBUG UI counter counts only successful uncancelled reads, so a test cannot pass solely on retained old data. No test instrumentation ships in Release.

## Verification

| Check | Result |
| --- | --- |
| Native app, design, Kit and XCTest | 1,808 passed, zero failed/skipped |
| Browser app-tests, 375/402/1280 × dark/light | 570 passed per cell; zero page exceptions |
| Saved-draw versus changed live leader | Pass in all six browser cells; supplied integration parent fails the pin |
| Disposable SQL | All Q2 behavior/grant/guard pins pass; 288 migrations, zero skipped, idempotent reapply |
| Repository preflight | Zero failures, zero warnings |
| Pro UI | All 15 focused cases pass across the Pro runs; final Book 5/5 after cancellation repair |
| Compact iPhone SE (3rd generation) UI | 15/15 passed, zero failed/skipped |

The 1,808 native tests comprise 150 app Swift Testing, 141 design, 1,453 Kit, and 64 XCTest. Existing FocusState test-harness warnings in OwnerQ46FieldTests and Supabase initial-session configuration warnings in the fixture launches are unchanged; these runs do not establish live auth recovery. Signed ad-hoc simulator builds preserve Keychain entitlements. No unsigned-test workaround.

Photo cases use the same supplied course-photo fixture as build 2020, `/private/tmp/cup-season-match-programme-qa-photo.png`, injected into the temporary xctestrun's CupSeasonUITests EnvironmentVariables as `CS_PROGRAMME_QA_PHOTO`. The QA photo is not a new production asset. Captures show explicitly synthetic review records.

All 46 compact-device captures and all successful Pro captures were inspected as contact sheets; selected Home, Book and What's On captures are preserved in `captures/`. Approved Home keeps the compact gross figure, whole course/story, 16:9 photo, and gap-free failed/missing photo state; AX3 content wraps and actions remain reachable. Book's matrix intentionally scrolls horizontally with names pinned.

Compact result bundle: `/private/tmp/codex-sprint-ui-se-final.xcresult`. Pro final Book: `/private/tmp/codex-sprint-book-pro-confirm.xcresult`; the other ten unique Pro cases passed in `/private/tmp/codex-sprint-ui-pro-confirm.xcresult`.

Native result bundle: `/private/tmp/codex-sprint-native-refresh-final.xcresult`. Browser/SQL/preflight summaries are saved beside this file. Initial UI runs surfaced fixture-launch setup errors and the Book cancellation defect; final Book and compact-device proof supersede those runs.

## Release handoff

Database deploy owed: the one new Q2 migration, after release-owner approval.

Edge deploy owed: none.

Client deploy owed: unified web/phone candidate; no push or upload performed here.

Open risks: this is simulator/disposable evidence, not physical two-phone recovery or system widget/background cadence proof. D372 owner/device gates remain outstanding; do not advance Friends/public distribution from this report.

Recommended next step: merge the verified owned sprint branch, apply the Q2 migration through the normal approved deployment path, publish web and upload the unified phone candidate containing both Build 2 and D400, then perform the physical release gates on that exact build.
