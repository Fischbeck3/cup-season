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
The shared contract is [D391 v1.3](../planning/2026-09-25-d391-social-course-contract.md).

The release candidate passes preflight (0 failures, 0 warnings), all 102 social
database assertions against the full disposable migration chain, and the web
integration walk at 1440/390 px (no console errors or horizontal overflow).
Before deployment, production's 53 read-only invariant checks pass and the dry
run names exactly migrations `20261207090000` and `20261208090000`.

Native UI verification covers course history → source round, nine-hole filtering,
failed-send draft retention, and activity → exact comment. Final small-phone and
accessibility captures and deployment identities are recorded at release closeout.
External distribution and App Store submission are outside this release.

Comment activity is persistent in-app. The optional lock-screen producer remains
disabled by `app_flags.social_comment_push.enabled=false` until actual-device
delivery is verified. Nine-hole rounds remain in history but do not set bests:
the existing round record does not identify which nine was played. Tee keys are
opaque and comparisons require a unique known layout, including gender and holes.
