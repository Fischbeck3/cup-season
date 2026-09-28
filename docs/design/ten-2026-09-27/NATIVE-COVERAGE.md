# Native capture scope at 5fabf861

This is capture metadata, not a critique or a score. App product sources are an untouched `git archive` of `5fabf861c4bee83e2492769f8e76ab3f9cda8281`. The isolated local UI test harness only opens existing DEBUG fixture paths and never signs in or submits a form.

## Coverage available

- Door welcome. Invitation/email/keyboard is a separately tracked UI-test supplement, not part of the direct manifest.
- Morning review: Play setup, live match, live score, on-phone score, offline queued status, share preview (with/without the drawn fixture image and long invented name/course), receipt.
- Social review: activity, receipt, comments, unavailable round, scoring-card unavailable, missing course identity. Course navigation and comment keyboard remain uncaptured existing-path gaps in this bounded pass.
- League setup fixture at its existing structure step; covenant and ruling sheets with QA identifiers.
- Security/link/consent fixture paths were inventoried but not captured in this bounded direct pass.
- Four widgets in their empty state, rendered by the production widget view inside the existing review host.
- Live Activity long-name compact and expanded controls, rendered by the production view inside the existing review host.
- Private credential state, which contains no personal identity.

The matrix for each directly reachable safe scene is dark/light × SE3 (375pt)/17 Pro (402pt) × large(default)/AX3, appearance and Dynamic Type set using the existing DEBUG hatches, status bar pinned at 9:41. Existing fixture record dates remain unchanged. All launches also use `-cs_dev_offline_network`, whose tuned Supabase URL session fails requests locally. Top-level Morning/Social, Widget and Island roots additionally bypass SessionStore startup, links, push and launch telemetry in CupSeasonApp.

## Not captured, not scored

- Signed-in first round / Post composer / acceptance / first Home transition: `-cs_dev_open post`, `postround`, etc. require `store.me != nil` in MainTabView.swift:520. No synthetic SessionStore fixture exists. Morning `setup` is the Play setup renderer and is not a posted-round composer or proof of the post transaction.
- CardGate and CrewStep require a signed-in `Me`; no clean signed-out fixture for these exists.
- Home state fixtures, selected Scoreboard/Book/Season fixtures, legacy Compete and normal credential fixtures embed owner/pilot identities. They were excluded rather than renamed, redacted or captured from an account. This is a fixture provenance gap, not proof of UI quality.
- Profile/You, Golfer/Head-to-head, history/record, settings, pot, season story/rules, event, schedule, planned round, offline course/book and course rating routes use the signed-in MainTabView path. Fixture objects below these paths do not bypass their authentication root.
- Populated widgets embed pilot-overlap identifiers, so only empty states were captured. Live Activity is the long invented-name fixture only; no genuine lock-screen/Dynamic Island host capture was generated. Review-host evidence cannot establish system-host geometry or interaction.
- Post failure/empty/long states, scan output, share-link minting failures, auth error/code states, push request, and other absent fixture states remain gaps. No network or auth was exercised to fabricate them.
- There is no full tab-shell fixture among the safe captured roots. Native five-destination navigation, edge-swipe back, background/restore, VoiceOver order and Reduce Motion need separate accessible synthetic routes or human evidence. Screenshots alone do not prove those behaviors.
- A long-name variant is only captured where an existing clean hatch declares one. No product source or fixture data was changed to invent missing states.

## Identity evidence

`MorningReviewFixture.swift` describes invented records; `LiveRoundStore.swift` 298–304 explicitly identifies its seeded golfers as invented. `SocialBlendFixture.swift` identifies its in-memory responses as synthetic and does no I/O. `SecurityReviewFixture.swift` uses synthetic actions and names. `LaunchSheetFixture.swift` names QA season/host. Empty widgets and the private credential contain no person data. The long LiveActivity fixture uses its existing invented stress name. No account is used.

## Build and harness

- Source: `git archive 5fabf861 apps/ios` into local gallery `native/build-source`.
- Project: `xcodegen generate` inside that archive.
- Dependencies: copied existing `SourcePackages` cache, `-disableAutomaticPackageResolution`; no dependency added.
- Build: `xcodebuild -project CupSeason.xcodeproj -scheme CupSeason -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .../native/DerivedData -clonedSourcePackagesDirPath .../native/SourcePackages -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO build`.
- Build succeeded. Full log: `native/build.log`.
- The local `capture-ten-native.py` adapts `docs/review/2026-09-25-morning/capture-native.py` and `docs/design/compete-2026-09-24/capture-selected.py`.
- New task-owned SE3 simulator: `C49F562F-1ACB-4664-897C-99D2B7649E12`.
- New task-owned 17 Pro simulator: `BD7B199C-7C75-4958-B0D1-038A488FDD33`.
- Existing user simulators were not operated.
- Direct screen manifests are `native/manifest-se3.json` and `native/manifest-17pro.json`; each row gives arguments, source SHA, identity provenance and PNG SHA-256. The authoritative validated output is `manifest-safe.json`; `manifest-excluded.json` records failed validation. `coverage.json` and refreshed contact sheets are generated exclusively from validated frames. The raw per-device manifests preserve the capture run.
- The local UI test source is `native/build-source/apps/ios/CupSeasonUITests/TenCaptureTests.swift`; it is not in the worktree. Its build log is `native/test-build.log`.

## Final direct capture notes

The direct run completed 104 files per device (208 total). One bounded startup-frame recapture was needed. OCR/image validation checks the intended scene; a wrong frame is excluded, never scored. `morning-kept` is the hatch name only: it sets scoreOnPhone=true and still shows active LivePlayView at hole 15, so its state is **live score on phone**, not a kept/completed/resume screen.

Original root-level captures used the DEBUG size hatch only; their size change was verified visually. Later captures set simulator system `content_size` to `large` / `accessibility-extra-large` as well as the app hatch; the manifest identifies this provenance per file. This matters for the covenant/ruling native sheets. The UI supplement also pins system text size before each batch.

Xcode is 27.0 (27A266a); simulator runtime is iOS 26.5 (23F77). The two device logical dimensions are 375×667 and 402×874. The archive was verified against every tracked `apps/ios` blob at 5fabf861: zero changed or missing source files. The added local UI capture test is outside the repository and is the only extra source in the isolated archive.

## Keyboard supplement

The bounded local UI tests ran Door invitation → email field → keyboard, and Play setup → rating keyboard, without submitting or changing any account data. Both tests passed on both devices at large and AX3 (8 executions, 0 test failures). Capture runner logs are `ui-{phone}-{size}.log`; exported screenshot manifests are `ui-export-{phone}-{size}/manifest.json`. `manifest-supplemental.json` maps 32 screenshots to source, exact arguments, device, text-size provenance and SHA-256. All roots use the app hatch plus system size. The email stage focuses its field automatically, so email-stage captures can already include the keyboard.

The first default-size 17 Pro Door capture showed the iOS first-use keyboard tutorial. A bounded confirmation run (`UI-17pro-large-confirm.xcresult`) passed and its six Door captures replaced the affected supplemental files. Their manifest hashes now refer to the confirmation export. No other supplement needs recapture.

Tests logged an existing SwiftUI runtime warning, “Invalid frame dimension (negative or non-finite),” while still passing. Optional simulator diagnostic collectors stalled after two completed runs; only those task-owned collectors were terminated to finalize results. No other device/job was operated. The confirmation disables verbose test diagnostics.
