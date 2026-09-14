# Paired web / iOS release checkpoint · 2026-09-13

**Owner direction:** bring web and iOS to an equal state, as far as the platforms allow, in the next push so the owner can judge the product on a phone and move to TestFlight.

This makes the existing parallel-delivery requirement a release checklist. It does not redefine competition mechanics or turn all future vision proposals into this release. Governing: D234, the current product vision, existing tokens/brand application rules, and the owner-authorized welcome correction.

## Baseline and ownership

- Shared release baseline: `963d0e6`; live web service worker independently read back that SHA on 2026-09-13.
- Web candidate reviewed: `8f85dac`; combined PR #3 serves `b12c0ca` (handoff-only difference).
- Native application in the review tree matches the release app apart from the checkpoint's LINT-14 test correction. Build 857 was archived from `963d0e6`; an App Store Connect check on 2026-09-13 still returned no build 857.
- Codex: isolated `codex/welcome-review-2026-09-13`; independent native and web verification, parity inventory and final integration after explicit handoff.
- Claude: lead builder, sole web editor, existing `claude/mobile-safari-experience` / `claude/mobile-web-integration` workspaces. Fix review findings while finishing checkpoint B.
- The old `codex/testflight-visual-refresh-2026-09-11` workspace contains substantial uncommitted native/brand experiments. These are not the release baseline and must not be silently merged or counted as delivered.
- This packet is published on the review branch for coordination. A Git push is not an automatic message to a running Claude session; the builder must acknowledge the packet in its next handoff.

## Definition of equal enough for this release

Both clients must offer the same core golf/competition journeys, display the same server facts under the intended league, and visibly belong to the same brand. Layout may fit each platform. A native widget or system share sheet need not be recreated as a web imitation.

Every row below receives separate **built / verified / delivered** evidence for web and iOS. An implementation claim or test count alone cannot close it.

| Area | Native baseline / source evidence | Web closure required | Paired acceptance |
|---|---|---|---|
| Welcome and masthead | `DoorView` has the pennant signature and terrain; approved native composition remains the reference | Retain corrected fescue/topo welcome and narrow masthead; fix prior F3 enlarged-text clipping | Normal/large text, dark/light, email/code controls; text stays legible; no stale earlier identity preview |
| Home hierarchy | Existing Home ranks dispatch and shows recent golf | Complete A repairs, including F1 visible future-round ownership | One useful lead, recent photo/no-photo golf, future scheduled round visible once, loading/error/empty states honest |
| Home receipt and plan doors | `HomeView.take` sends receipt to `presenter.receipt`, plan to `presenter.scheduledRound`; `MainTabView` presents distinct sheets | WA1: posted-round shortcuts resolve cached and uncached posted IDs correctly | Correct posted receipt from lead/last score/feed; planned round still opens planning details |
| Compete and season navigation | `MainTabView.openCompetition` selects Compete and pushes the requested league/pane | WA2: current/other league reaches its season in one action | Same target league and room; failure does not show another league as success |
| Season / standings / rules | Existing season rooms, server standings and editable rules | MW-04 hierarchy and WA4 history → full receipt | Individual/squad, counting/bumped contribution, rules and ledger remain reachable and factual |
| Posting and after-golf | Existing server-attributed completion, draft/retry and played-date handoff | MW-05 hierarchy, solo/squad copy, existing date/draft/retry protections | Score → course/tee/date → post; optional media quiet; accepted facts and correct date; controlled-data retry checks |
| League setup | Existing suggestions/custom values and durable create/lock recovery | MW-06 clear progress and brief consequence copy | Same chosen rules survive review/back/retry; no new default or creation-timing rewrite as a layout fix |
| You / golfer record | `YouModel` is observable and replaces loaded career data; receipt seeds use real IDs | WA3: false zero count fixed; compare record/round doors | Loaded record and credential agree; unavailable is not a fabricated zero; profile/settings reachable |
| Golfers / plans / invitations / events | Existing capabilities, server eligibility and invitations | Verify existing equivalent entry paths; list concrete missing capabilities if found | Friends/plans and competition invitation terms reach intended records; event fixture smoke; no silent accept or invented facts |
| Round receipt explanation | Existing posted-round enrichment via `round_card` | WA6 grouped arithmetic and nonduplicated verdict | Same server facts and intended league lens; photo is optional; points have a path to rounds |
| Shared artwork | `CSArtifactFrame` used by native round/scorecard exports | D339 I-2: common web artifact signature/footer across existing generators | Compare round, scorecard, settlement and event artifacts with labeled fixtures; no private account imagery committed |
| Interior branding | Native Compete/season heads use restrained terrain | D339 I-3: finish applicable Compete/season/signature placements after structural markup settles | Same identity, restrained texture, readable facts; desktop remains coherent |
| Icons / install / link preview | Native beta pennant icon family exists; final mark/tile remains a recorded owner decision | D339 I-4: candidate PWA/apple-touch/favicon/OG family from the pennant source/generator | Review both platform icon families together; production replacement requires the existing explicit brand approval, not an inferred final mark |
| Platform integrations | Native widgets, Live Activities, system share and notification surfaces have their own delivery/testing requirements | Existing web equivalents where supported; do not invent imitation widgets | Explicit platform-difference list; no new notification audiences, privacy semantics or gameplay in this parity release |

Source comparison is not runtime proof. In particular, native's correct route types do not on their own prove every cross-league context or data-loading path.

## Builder packet: expand the current repair sprint, not another redesign

1. Finish WA1/WA2, WA3 and prior F1/F3 with meaningful controls-to-destination tests. The exact reproductions are in the [signed-in review](../reviews/2026-09-13-signed-in-account-walkthrough.md).
2. Complete MW-04/05/06; include WA4/WA6. Preserve shared scoring, draft ownership, backdated posting, create/lock recovery and fully editable league rules.
3. Complete the missing web D339 I-2/I-3 applications in separate design commits. Prepare I-4 for paired review, preserving the unresolved production-mark decision.
4. Check the native counterpart of every changed journey. Return exact native file/test evidence or a named native defect for Codex to repair in its owned workspace.
5. Reintegrate into **the same PR #3 preview**, and return one immutable candidate with HTML and service-worker SHA readbacks. Retire #1/#2 as review links.
6. Return this matrix with each row's actual status and residual differences. A row marked deferred must say what the owner will see and whether it blocks the paired release.

This is parity with the current approved product, not implementation of every future notification idea, gameplay mode or vision prototype.

## Codex verification and release sequence

1. While Claude builds, inspect native counterparts and run existing native UI journeys against the isolated baseline. Keep source-only, fixtures and real account observations distinct.
2. On Claude's immutable handoff, independently review the diff and integrate into an owned release workspace. No concurrent edits to Claude's branches.
3. Run relevant browser/domain checks and preflight, then the paired native checks on the actual final candidate. Baseline tests cannot certify a later merged candidate.
4. Repeat the signed-in web read paths. Use controlled fixtures/test data for create/post/retry/invite writes; do not silently use the owner's real account as a disposable test league.
5. Check mobile web at 390/320 and desktop at 1440, dark/light and enlarged text. Physical iPhone Safari safe areas, keyboard and navigation remain separately labeled until tested.
6. Publish the reviewed web candidate under the owner's next-push instruction, subject to any still-open production-mark approval. Independently read back the live HTML and service-worker versions.
7. Archive the same integrated application source with fresh app/widget versions. Export/upload only if distribution signing succeeds, then verify App Store Connect processing. Do not label an archive as TestFlight delivery.
8. Return live web URL/SHA, native source/build/processing state, remaining platform differences and verified/unverified journeys in one owner update.

No database or Edge deployment is expected for the known client repairs. Any new required migration/Edge change is an explicit scope change and requires its own authorized deployment. Signing remains independent of web publication.

## Native evidence for this checkpoint

A targeted native run was started from `634a98f` in the isolated review workspace, with generated Xcode project and the existing signed-in iPhone 17 Pro simulator. It selects:
- `CompeteGameplayReviewTests/testRealCompeteSeasonAndCreationDoors`;
- `AcceptedRoundReviewTests/testReplayedAcceptedCompletionOpensReceipt`;
- `AfterGolfComposerTapTests`.

**Result: 3 executed, 3 passed, 0 failures, 0 skips**, independently read from the completed xcresult summary. The run completed on 2026-09-13 using iPhone 17 Pro / iOS 26.5. The Compete test exercised season entry and setup entry in dark and light; the other tests reached the accepted receipt and the composer on the played date.

These controls open/read/cancel; they do not submit a round or create a season. The after-golf case uses a labeled plan fixture inside the authenticated shell; the accepted completion is replayed rather than a new post. This does not certify all native routes, photo-share opt-out, physical-device behavior or a later integrated candidate. Build output contains existing actor-isolation warnings and debugger-version diagnostics; the executed tests still passed.

Local evidence: `/tmp/cs-paired-release-native-634a98f.xcresult` and `/tmp/cs-paired-release-native-634a98f.log`. Private captures and result bundles are not committed. `git diff 963d0e6 634a98f -- apps/ios` confirms only the existing LINT-14 test change, with no native application change.

No native repair was needed for these three tested paths. The baseline is now available for comparison with Claude's repaired web checkpoint.

## Session handoff

Branch: codex/welcome-review-2026-09-13.
Goal: one paired web/iOS release checkpoint under the owner's next-push instruction.
What changed: parity scope and release gates; baseline native verification.
Files changed: this packet and ACTIVE_WORK.
Database deploy owed: none from this checkpoint.
Edge deploy owed: none from this checkpoint.
Client deploy owed: candidate fixes/integration and verified web publication; native signing/export/upload separately pending.
Open questions / risks: Claude's expanded scope needs acknowledgment; review findings, remaining brand applications, production-mark ruling and physical-device acceptance.
Recommended next step: Claude returns the paired matrix and integrated candidate; Codex audits and releases the validated layers.
