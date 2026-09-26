# Connected rounds and courses · September 26, 2026

Owner authorization: “Ship it deploy and push. Prompt Claude for any work needed.”

Codex owns `codex/social-course-blend-2026-09-26` in an isolated temporary
worktree. Claude owns `claude/social-course-backend-2026-09-26` in a separate
worktree. The existing dirty visual workspace is outside this release.

The approved example connects the photo-led round feed to comments, comment
activity, and a course's golfers and posted scores. North Grove and the people
in the example are fictional fixtures. Production reads existing course IDs,
posted rounds and relationships; it never seeds the example into live data.

## Acceptance

- A round's comment door opens its conversation. Replies retain their parent,
  failed sends retain the draft, and retries do not duplicate a comment.
- Comments on owned rounds, replies, and followed conversations produce
  persistent activity according to the golfer's preferences. No self alerts.
  A notification opens and highlights its comment; reading one does not clear
  unrelated unread activity. A thread can be followed or muted.
- A course shows accepted friends and other golfers whose rounds the viewer
  may already see, including friends outside a league. Each golfer opens a
  dated course history, each score its round.
- Best gross is authoritative over the eligible cohort, with a stated scope,
  known tee provenance and hole count. Shared bests retain their source rounds.
  Unknown tees do not become comparable by guessing. Private rounds never
  acquire a public audience through a course page or notification.
- Light/dark, small phone, large type, offline failure, empty data and
  deployment skew remain usable. Existing posting, scorecards, moderation,
  round sharing and competition calculations continue to use their current paths.

## Release record

Claude implemented and reviewed the web/backend contract on his isolated branch;
Codex integrated commits `882b1956` and `3de8d4c0` and built the native surfaces.
The shared contract is [D391 v1.4](../planning/2026-09-25-d391-social-course-contract.md).

Released September 26, 2026 UTC (September 25 in Arizona):

- Web implementation `26696a808ace8b837f0f905331ce833406f8a502` is on `main`
  and the owned release branch. Netlify serves `26696a8` in HTML and the service
  worker, HTTP 200 with no version placeholders. The signed-out browser door
  renders that stamp. A subsequent documentation-only closeout advances the
  stamp without changing product code.
- Database migrations `20261207090000` and `20261208090000` applied. Production
  has 276 migrations, no pending migrations, 11 authenticated-only social RPCs,
  and sealed notification/preferences/thread-state tables.
- The `push` Edge function is deployed and ACTIVE, version **39**.
- Native **1.0.0 (1029)** is available in **Owner TestFlight**. Exact source:
  `4754eb77c621ad6a7c26c66b254b61bff86a0c6f`. Archive/export and Apple validation
  succeeded; the app and widget both carry build 1029, signatures verify,
  APNs is production and debugging entitlement is off. One upload succeeded,
  delivery `8234169f-a980-4d42-b4de-6a11e5b33686`. Read-back: **VALID**,
  **Owner YES**, **IN_BETA_TESTING**, **Friends no**. What to Test saved (200);
  Owner group add succeeded (204). No external review or App Store submission.
- [Structured deployment evidence](social-course-blend-evidence.json).

Verification: preflight **0 failures / 0 warnings**; **102** social database
assertions against the full disposable migration chain; **53/53** production
invariants; web integration at **1440/390 px** with no console errors or horizontal
overflow; **1,289** domain and **120** design tests; **four** social UI tests on
iPhone SE, including **AX3** notification → exact comment. Small-phone light and
dark captures were visually inspected. The UI tests also cover course history
→ source round, nine-hole filtering, and failed-send draft retention.
[GitHub CI passed](https://github.com/Fischbeck3/cup-season/actions/runs/36211519085).

Release review caught a false positive in database check 18: the new author and
reply foreign keys intentionally give `post_comments` two paths to profiles and
to itself. Claude audited both clients and function sources; all reads use
scalar columns or the definer RPC, with no ambiguous embed. The check now accepts
only those two exact pairs, and preflight 21b scans **510** sources to reject a
future unqualified embed. No applied migration was changed to resolve it.

Comment activity is persistent in-app. The optional lock-screen producer remains
disabled by `app_flags.social_comment_push.enabled=false` until actual-device
delivery is verified. Nine-hole rounds remain in history but do not set bests:
the existing round record does not identify which nine was played. Tee keys are
opaque and comparisons require a unique known layout, including gender and holes.

## Handoff

Branch: `codex/social-course-blend-2026-09-26`, pushed and integrated into `main`.

Goal: Ship the approved social/round-posting and course-history blend.

What changed: Posted-round conversations and replies; persistent comment activity,
read state and notification preferences; course doors from rounds; friends and
circle histories; scoped best scores with source rounds; privacy and moderation.

Files changed: `index.html`; the two new migrations; `supabase/functions/push/index.ts`;
DB contract plus generated clients; native Home, receipt, course, Activity and push
surfaces; domain/design components and tests; D391 and shared contract documentation.
The existing dirty visual workspace was not changed.

Verification run: The database, web, native and release checks above.

Database deploy owed: None.

Edge deploy owed: None.

Client deploy owed: None for web or the internal Owner release.

Open questions / risks: Real-device comment-push delivery is unverified and its
producer stays off. In-app comment activity is live. North Grove examples remain
debug-only fixtures, never production records. TestFlight availability does not
establish installation on the owner's phone.

Recommended next step: Install **1029** through Owner TestFlight; open a course,
choose a friend's score, add a comment/reply and follow the resulting Activity
item back to the conversation. Verify lock-screen delivery before enabling the
comment-push producer.


## Course-home correction · 2026-09-26

The owner found the Courses interface missing in TestFlight 1029. The Home door
opened `CoursesScreen`, the offline inventory, and the social review fixture
rendered `CourseCircleSection` directly. That verification never exercised the
real course-home or full course-page navigation.

`CourseHomeScreen` now lists the actual places played by the viewer's circle,
with friends, round counts and catalogue search. Home and the signed-in Courses
routes open it; Saved for offline and the boot-recovery path retain the existing
inventory. A course page renders its real header and circle history without a
local course book. The circle best and golfer histories precede scorecard facts;
rating remains the first action per D322. No public record, scoring change or
fictional production data was introduced.

The review fixture now enters through the same `CourseHomeLink` as Home, then
uses the production CourseHomeScreen and CourseScreen. UI regression coverage
includes list → course → golfer → round, search → unsaved course at AX3, and
nine-hole best exclusion, alongside the existing conversation checks.

Release evidence is recorded after Apple processing below.
