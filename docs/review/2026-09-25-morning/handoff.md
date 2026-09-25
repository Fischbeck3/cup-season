# Morning review handoff

Owner approved this review on September 25 with “Looks good deploy it.” The
build-time record below is retained; current release evidence is in
[deployment.md](deployment.md).

Branch: `codex/play-share-store-review-2026-09-25`

Implementation commit: `46aad31e`. The review artifacts are in the following separate commit.

Goal: Build the Play journey, sharing experience and App Store presentation for owner review.

What changed:

- Play setup keeps Tee off below the scroll, prioritizes course entry, adds a Close keyboard control and gives names enough width in the group and team layouts. Scoring, posting, consent and competition mechanics are unchanged.
- The share preview puts photo consent before the image and makes the exact accompanying message expandable. Completion/cancellation now clears the presentation binding, fixing a share sheet that could remain open.
- The public round page uses the existing tokens and generated pennant, follows the native record’s information order, shows a clear photo plate only with consent, and keeps private points out of the page. A missing photo copy leaves the round readable.
- A three-digit leaderboard total can take its required width without breaking into two lines. An explicit gap separates it from the gap column.
- Eight App Store candidates use actual native renders with invented records. The sequence ends on the completed-season page. The chart caption describes current counting contributions rather than historical standings.
- DEBUG-only fixtures skip auth/startup work and isolate the review. The receipt fixture is capture-only. Fixture setup/finish never creates or posts a real round.

Files changed:

- `apps/ios/CupSeason/Live/LiveSetupView.swift` — setup hierarchy, action, keyboard and roster width.
- `apps/ios/CupSeason/Post/RoundSharePreview.swift` — photo choice, message disclosure, cancellation state and fixture exports.
- `apps/ios/Packages/CSDesign/Sources/CSDesign/Board.swift` — intact trailing numbers and column spacing.
- `index.html` — public round renderer and scoped styles.
- `CupSeasonApp.swift`, `MorningReviewFixture.swift`, `LiveRoundStore.swift`, `LivePlayView.swift`, `RoundReceiptSheet.swift` — isolated fixture routing and evidence hooks; production receipt/scoring behavior retained.
- `apps/ios/CupSeasonUITests/MorningReviewTests.swift` — focused interaction checks.
- `tests/preflight-baselines.json` — tighten the existing case-lint baseline to its current count.
- This review directory — gallery, image exports, eight store candidates, captions, manifests and capture/build scripts.

Verification run:

- Focused setup/share UI suite: **7/7 passed** on the standard iPhone and **7/7 passed** on the 375-point iPhone SE. Includes AX3, rating keyboard, disconnected status, photo opt-out/in, no-photo state and native share cancellation.
- Final message-disclosure check: **1/1 passed**. Verifies the 44-point target, exact caption visibility and reachable Share action.
- Public page: **8 variants passed**, no JavaScript errors. Mobile dark/light, desktop, 320-pixel long names/nine holes, included photo, missing photo, no band, escaped untrusted copy; no horizontal overflow or private point leakage. Supabase requests blocked; the photo response is a local fixture.
- Simulator builds succeeded. `npm run preflight`: **0 failures, 0 warnings**. `git diff --check` clean.
- Visual inspection: standard and small native views, AX3, fixed-size card exports including long course/golfer with photo, leaderboard totals and store compositions. No generated source files hand-edited.

Database deploy owed: **None added by this work.** The earlier audit release remains a separate deployment.

Edge deploy owed: **None.**

Client deploy owed: **Web and iOS changes are local review candidates.** Nothing pushed, merged, deployed, uploaded to App Store Connect or sent to TestFlight.

Open questions / risks: Owner review of layout, store ordering and captions remains. The public record layout changes only the round branch; other share types retain their existing presentation. Actual link creation/revocation was not exercised against production in this design pass. The verified audit integration `afd21ce2` is the base; coordinate these commits with Claude’s release branch after review.

Recommended next step: Open `index.html`, review all three tabs, then bring the approved changes into the latest release branch. Keep database/Edge/client release checks separate.
