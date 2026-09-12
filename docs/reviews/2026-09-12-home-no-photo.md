# Home without a photograph — 2026-09-12

Branch: `codex/home-no-photo-2026-09-12`, based on `f6e5ffd` (build 795 plus Claude's review).

The owner requested design ideas in an artifact while fixing the no-photo issue. D340 records the authorized presentation change. No-photo Home rounds now carry a golfer header, the course, a prominent gross rule-and-figure, and the existing milestone/band sentence. Course and gross appear once. Missing gross produces no fabricated number or milestone. Native golfer and receipt buttons are separate accessible controls. D341 adds an explicit “React” invitation on untouched rounds. Web Home now mirrors native’s given-reactions-first reveal, using the existing drawn tokens. Selection closes the reveal; removing the last reaction restores the invitation. Web receipt keyboard handling now preserves Enter/Space for its inner controls.

A single fresh round uses the existing story producer and keeps its receipt id; the native page yields that digest when the same round is already in the wire/lead. The web also yields the single-round count to its own record. Multi-update summaries remain unchanged.

This is the factual typography fallback. No new photograph, course-card geometry, hole score, par, course identity, database contract or scoring calculation is introduced. The course-card feed ladder remains follow-up work.

## Interactive study

`work/home-design-ideas.html` is the inline source. Host design controls compare Score-led, Editorial and Current compact treatments; Home, Reactions and After golf; and the reaction-door label. The compact option is a schematic comparison, not an exact screenshot. All rounds are illustrative, icons are sketches, and every interaction is local. The React label is now applied on untouched rounds; the after-golf flow and alternative icon sketches remain proposals.

## Files

- Native layout: `apps/ios/CupSeason/Home/HomeWire.swift`.
- Copy and deduplication: Kit `HomeWireCopy.swift`, `HomeDigest.swift`, `HomePage.swift`.
- Web: `index.html`.
- Native QA: `RootView.swift`, `Dev/HomeNoPhotoFixture.swift`, `HomeNoPhotoTests.swift`; Home digest/page unit cases.
- Record: D340/D341, inbox follow-through, this review.
- Verification limits: `tests/preflight-baselines.json` and the small-type floor in `tests/preflight.mjs` tightened to measured counts, including inherited build-795 reductions; no limit rose.

## Verification

- Xcode simulator build and 34 focused tests passed, no skipped tests: HomeDigestTests, HomePageTests and HomeNoPhotoTests. Result: `work/home-verified.xcresult`.
- Native fixture visually inspected in dark and light on iPhone 17 Pro, and at AX3 on iPhone SE. Three illustrative rows include a long golfer/course name and three-digit gross.
- Reaction reveal/select/multiple/remove/close checked against the real web renderer in local demo mode at 320 and 390 pixels, with keyboard-event handling, 44px targets, actual icon sprite and Board behavior retained. Native reaction selection/removal and distinct golfer/receipt destinations pass UI tests.
- No-photo web renderer captured at 1440 and 390 pixels; no horizontal overflow or console errors. Existing Supabase lock deprecation warnings remain. Sample data never writes to the server.
- Interactive study checked at 390 and 736 pixels, including Tweak alternatives, picker open/select/close, round detail/back, prefilled after-golf screen, dismissal and aligned figures. No overflow, errors or warnings.
- `npm run preflight`: 0 failures, 0 warnings after installing the repository's locked development dependencies. `git diff --check` clean.
- Xcode reports existing concurrency/deprecation warnings elsewhere in the app. No claim of a production-account feed walkthrough or photo/no-photo image-loading fallback change.

## Remaining action plan

| Order | Claude finding / opportunity | Concrete next work | Acceptance evidence |
| --- | --- | --- | --- |
| 1 | Item 16: a past plan disappears without asking how golf went | Specify one Home prompt from the existing plan, then implement the server producer and both clients together. Proposed copy: “How did Oak Quarry go?” Primary: “Add your round”. | A past plan opens the composer with the real course/date; an existing accepted round suppresses the prompt; no duplicate prompts or required photo. |
| 2 | Items 22–24: real scorecard art cannot reach the feed | Trace stable course/tee identity into the feed contract, then reuse the existing card renderer only when real hole data exists. | Photograph → real drawn card → approved available texture → factual no-image record; missing data never invents par or holes. |
| 3 | D339: pennant reservation and contour tile conflict | Compare the current icon at home-screen size with a solid-field treatment. Record the owner’s mark-placement ruling and make LINT-28 check `CSBrandMark` accordingly. | Owner-selected tile and a lint that covers the actual production mark; sketches do not replace assets automatically. |
| 4 | D337: plan headline has two producers | Move calendar-relative wording into `home_dispatch`, then remove the phone’s local rewrite with skew-safe client rollout. | Same plan/date yields the same factual headline on both clients. |

The after-golf flow is a new persisted interaction, so its contract remains to be decided before implementation. Recommendation: start on Home without a push, never infer that golf actually happened, and keep the photo optional after posting. “Later” and “Didn’t play” in the study demonstrate intent only. Define durable snooze/dismissal, eligibility for host versus RSVP participants, the local-day boundary, and course/date matching when identity is missing or two rounds occur in one day. Dismissal should hide the prompt without rewriting the historical plan or round. The existing historical migration shows the future-only window and a course-id field; it is not evidence that a deployed closing-loop contract exists. Item 16 remains open.

## Handoff

Branch: codex/home-no-photo-2026-09-12
Goal: interactive design ideas plus a meaningful no-photo Home round.
What changed: factual round presentation, redundant single-round count removal, and a clearer Home reaction invitation on both clients.
Files changed: listed above; `work/` ignores build products and QA output while retaining the inline study.
Verification run: build, 34 native tests, browser/interaction checks, visual inspection, preflight.
Database deploy owed: none from this change.
Edge deploy owed: none from this change.
Client deploy owed: web and iOS; prepared on this branch, not deployed or uploaded.
Open questions / risks: taller no-photo rows; after-golf matching/dismissal and the brand ruling remain open; course-card feed data remains separate.
Recommended next step: review this branch on a phone, then use the normal client release gates; develop the after-golf contract as the next Home opportunity.
