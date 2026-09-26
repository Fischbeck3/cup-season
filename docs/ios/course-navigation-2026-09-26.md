# Round receipt course navigation · 2026-09-26

Branch: `codex/course-navigation-2026-09-26`.

Goal: Open the course page from a played round, including the owner's reported
Galen → Papago receipt.

What changed: The receipt now preserves the stable course ID returned by
`posted_round_thread` when `round_card` supplies the scoring details. The live
scoring response omits `api_course_id`; previously its successful response hid
the course link. Home and the receipt label the link **View course**. This fixes
the existing D391 navigation and changes no competition mechanics.

Files changed: `RoundReceiptSheet.swift`, `HomeView.swift`, `SocialBlendReview.swift`,
`SocialBlendFixture.swift`, `RoundsRepository.swift`, `SocialBlendTests.swift`,
and this handoff. Synthetic receipt responses now enter at the repository
boundary, exercising the actual enrichment path instead of bypassing it.

Verification run:

- Simulator build and all ten `SocialBlendTests` passed on iPhone SE, zero
  failures. Four new cases cover a scoring response without the course ID,
  a friend's round without league scoring access, an unknown course, and an
  unavailable round. Existing comment moderation, retry, activity, course
  history, search at accessibility size, and nine-hole checks also passed.
- `npm run preflight`: zero failures, zero warnings. `git diff --check` passed.
- Installed the updated Debug app on Cup Season Native Audit without deleting
  its data. The owner's existing login was preserved. Opened the real Galen
  Papago receipt from Home, confirmed the visible course link, and tapped it
  to reach Papago with Blue/White, 18 holes, Galen's 86 and golfer history.
  Production inspection was read-only; no scores, comments or ratings changed.
- Local evidence: `/tmp/cs-course-navigation-se.xcresult`,
  `/tmp/cs-course-navigation-se.log`, `/tmp/cs-course-navigation-preflight.log`,
  `/tmp/cs-course-navigation-papago-receipt.png`.

Database deploy owed: None.

Edge deploy owed: None.

Client deploy owed: This correction is installed in the review simulator only.
Owner TestFlight remains build 1042 until a new native release is uploaded.

Open questions / risks: The earlier fixture bypassed the faulty receipt load,
so its passing tests did not establish that this route worked. The new tests
exercise that path, and the exact reported live round was verified separately.

Recommended next step: Continue feedback in the signed-in simulator, currently
open to Papago, then include this correction in the next native release.
