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

Client deploy owed: None. The correction is available in Owner TestFlight
**1.0.0 (1044)** and installed in the review simulator.

Release record:

- Source `0aaa7f1e5a78e4c0d1dadf07fbb72d3501f98ea2` was pushed to the owned
  branch and `main`. [CI passed](https://github.com/Fischbeck3/cup-season/actions/runs/36253607053).
- Archive/export, app and widget version checks, signature verification and
  Apple validation passed. Production APNs is set and debugging is disabled.
- IPA SHA-256: `2ef85b46a78a852dabf58b01343a0952f85ae70181a2436416d6826614ff83ff`.
- Apple upload succeeded, delivery/build ID
  `8de33944-5266-474c-81ac-30c2248ebb80`. Read-back confirmed **VALID**,
  **Owner YES**, **IN_BETA_TESTING**, **Friends no**. What to Test saved (200),
  Owner add succeeded (204). No external beta or App Store submission.
- The automatic web deployment serves the release source stamp, HTTP 200;
  this native-only fix adds no web, database or Edge behavior.
- Signed IPA, UI test results, screenshot, logs and structured release evidence
  are preserved privately at
  `~/cup-season-audit-private/course-navigation-2026-09-26/build-1044/`.

Open questions / risks: The earlier fixture bypassed the faulty receipt load,
so its passing tests did not establish that this route worked. The new tests
exercise that path, and the exact reported live round was verified separately.

Recommended next step: Update to TestFlight 1044. Open Galen's Papago round from
Home, then tap **View course** below the points. The simulator remains signed in
and open to Papago for continued feedback.

## Follow-up: receipt touch area

The owner reported the route still failed after updating. A read-only check of
their paired iPhone confirmed build 1044 was installed. A new UI regression
reproduced a second defect: an ordinary tap at 65% of the course row's width
did not navigate. The earlier element-based tap activated the text instead and
passed. The failed run's hierarchy exposed only an 18-point-tall element even
though the label layout reserved 44 points.

The receipt link now defines its entire rectangular label as its touch area,
matching the existing Home course link. This changes no layout, course identity,
data access or scoring. The regression retains the previously failing tap.

Files changed: `RoundReceiptSheet.swift`, `SocialBlendTests.swift`, this handoff.

Verification: The new coordinate-tap test failed before the correction. All
11 social UI tests pass after it, including the same coordinate tap, with zero
failures. Preflight passes with zero failures and zero warnings. Evidence:
`/tmp/cs-course-tap-area.xcresult` (before), `/tmp/cs-course-tap-fixed.xcresult`
(after), `/tmp/cs-course-tap-preflight.log`.

Database / Edge deploy owed: None.

Client deploy owed: Follow-up native build pending verification and upload.
