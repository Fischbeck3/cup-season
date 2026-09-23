# October launch · visual UI sprint

**Owner: Codex. Started September 22, 2026. Target: visual candidate September 28; launch corrections through September 30.**

The owner asked Codex to own the visual UI sprint and begin execution. This authorizes the audit and implementation inside the existing product and design decisions. The outcome is a bold, readable Cup Season in which a golfer can understand the next action, finish a round and share it without coaching. This supports the October 1 submission/public launch and 5,000 first-time App Store downloads by December 31; visual polish alone does not establish an acquisition forecast.

## Ownership and baseline

- Owned branch: `codex/october-visual-ui`, isolated worktree `/private/tmp/cup-season-visual-ui`, cut from `82cb92f` (`codex/october-w6-review`). It includes the Mac fixes in `f49756d` and Claude's W6 work in `5404978`.
- Codex owns the visual audit, web/native presentation fixes, local builds, screenshot review, accessibility checks and the review packet. Each slice gets a narrow commit and evidence before it is called verified.
- Claude's [W6 reporting correction](2026-09-22-w6-review-and-claude-prompt.md) at `8f632ed` is now integrated by `9d9ef46` for the Owner beta. Avoid overlapping edits to `index.html`, shared design code and the native views during this sprint. A later cross-lane change must be integrated on an owned branch and rechecked.
- The older, dirty `codex/testflight-visual-refresh-2026-09-11` checkout and its visual implementation pack were left intact. They are design input to reconcile, not the launch baseline or proof that a screen shipped.
- This pass adds no database or Edge work. Existing `20261116090000`, `20261117090000`, `courses`, real consent proof, two-phone checks and release actions stay in the [release checklist](2026-09-22-release-checklist.md). No production, Apple or main-branch mutation is part of this visual implementation approval.

## Design truth, including the stale summaries

Use `packages/tokens/tokens.json`, the current decisions and `docs/ui-overhaul-2026-09-06/UI_SYSTEM.md`. D358 ratified the CS pennant as the production mark. D359 and its F11 amendment reserve ember for competition (upcoming, live or finished) and the approved identity hairline; an ordinary action uses `act`. Gold remains earned. The token notes carry F11 explicitly.

`AGENTS.md` and `DESIGN_SYSTEM.md` still contain earlier summaries calling the mark open and ember the ordinary action color. Those conflict with the later owner-ratified rulings above. This sprint follows the later explicit rulings; it does not reopen the mark or introduce a palette. Older UI-system passages also need to be read through those amendments.

Keep the green-black and warm paper grounds; serif story, condensed board and mono records; rules, rails and purposeful space. Secondary text uses opaque `mut`, not `dim` or faded text. Preserve one fact in one place, the five destinations, existing gameplay and photo-consent semantics. A material new design or product decision gets a concrete proposal before implementation.

## Sprint sequence and acceptance

Dates are the execution order and target completion dates, not a claim that unattended work has been scheduled. If a release defect consumes the buffer, cut decoration before cutting clarity, accessibility or recipient proof.

| Slice | Target | Codex owns | Acceptance |
|---|---|---|---|
| **V1 · First impression and entry** | **Sep 22** | Welcome and sign-in, pending invitation context, `/get`, `/support`; fix measured contrast, theme and target defects | Readable welcome/legal text in both themes; visible recipient context before sign-in; actions reachable with large text; no overflow; no false install button. First implementation and local evidence below. |
| **V2 · The places golfers return to** | **Sep 23–24** | Home, navigation, Golfers, You, record, settings and shared chrome | Home answers what happened and what to do next without repeating a fact. Empty/no-photo states look intentional. Primary/secondary actions are distinguishable. Every tab, back path and sheet dismissal works; long names do not collide with figures. |
| **V3 · Get onto the course and finish** | **Sep 25** | Play chooser, course search/preparation, schedule, roster, score entry, live card, recovery, post-round composer | Course/tee selection and score entry remain reachable above the keyboard. Validation is adjacent to its input. Saving, offline, unfinished and failed states are explicit. A golfer can reach a posted result without a visual dead end. |
| **V4 · Understand the competition** | **Sep 26** | Compete, season, standings, event rooms, draft, setup, adjustments, re-up, members and ledger | Competition hierarchy and phase are clear; numbers align and have their existing drill-down. Ruling reasons and “Run it back” consent remain readable. Member and Pro controls are distinguishable. No new scoring or money rules. |
| **V5 · A round worth sharing** | **Sep 27** | Receipt/epilogue, share preview and card, album, public round/claim/invitation pages, golfer card and installation continuation | One clear Share action; card reads at message-preview size; long names, no-photo and failed-photo states work. Preview/export honor the existing consent answer. Recipient sees what arrived and the next step; cancelled sharing returns safely. Device/link proof stays a separate gate. |
| **V6 · Whole-product finish and release imagery** | **Sep 28** | Accessibility sweep, light/dark/looks consistency, errors/empty/loading states, legal/support, widgets/live activity, app icon and store screenshot staging | All inventory rows below have evidence or a named open blocker. No critical clipping, unreadable essential copy or unreachable action. Capture launch screenshots from the verified build with approved/fixture content and accurate captions. |
| **Human proof and correction buffer** | **Sep 29** | Observe the existing timed tasks; correct the UI failures they expose | Record actual times, assistance and failures using the pilot protocol. Do not invent a usability pass from an automated test. |
| **Visual freeze** | **Sep 30** | Integrate the accepted slices, rebuild, repeat affected checks and prepare release handoff | Freeze a named commit/build. Only release-blocking corrections afterward; no speculative visual expansion. October 1 submission/distribution remains an owner release action. |

## Coverage inventory

This is the scope inventory, not a claim that every screen has been visually verified. **V1 has rendered evidence. The September 22 Owner-beta pass adds selected V2–V5 native fixture evidence; the remaining states still need capture.** Native fixtures give repeatable local evidence, but cannot prove a real invitation, push, production consent or two-device lifecycle.

| Family | Native source / web surface | Required states | Slice / present evidence |
|---|---|---|---|
| Welcome, email/code, profile and crew entry | `Door/`, `Onboarding/`; `#obDoor`, `#obProfile`, `#obCrew`, `#obWelcome` | New/returning, invited, invalid/expired code, waiting/error, keyboard | V1 welcome/email rendered; profile, crew and code error states still to capture in V6 |
| Public entrance and recovery | `get.html`, `support.html`, `legal.html`; universal-link handlers | No saved theme, explicit dark/light/auto; no install URL; install then reopen; invalid link | V1 get/support layout verified; real URL, legal and invalid-link proof open |
| Home and navigation | `Home/`, `Main/`; `#view-home`, web tabs/sidebar | Empty, one/many seasons, before/after golf, live round, photo/no-photo, digest | V2; HomeNoPhoto, HomePhotoStability and AfterGolfAnswer rendered/passed Sep 22; authenticated navigation remains open |
| Golfers and relationships | `Golfers/`, `People/`; `#view-golfers`, `#view-person`, `#view-h2h` | Search/no results, buddy request, invite, safety/report/block, long names, empty history | V2; visual capture queued |
| You, record and settings | `You/`, `Settings/`, `Looks/`, `Pricing/`; `#view-record`, settings/card surfaces | New/established golfer, private/public, empty/full record, theme/look, account/help/error | V2; capture queued, do not redesign pricing or permissions |
| Courses and schedule | `Courses/`, `Schedule/`; course sheets, `#view-schedule` | Search/loading/no result/failure, tees, saved/offline course, booking/date, long course names | V3; OfflineTripReview score/relaunch/keep flow passed Sep 22; real course search states remain open |
| Play and live round | `Compete/IntentSheet`, `Live/`; `#view-play` | Chooser, roster/guest, 9/18 holes, scorecard, keyboard, offline/reconnect, resume/finish | V3; physical two-phone lifecycle remains open |
| Posting and receipt | `Post/`, `Rounds/`; `#view-post`, ceremony/receipt | Score-only/photo, edit, loading/failure, cancelled share, no season, adjustment without rounds | V3/V5; RoundShareReview and LaunchSheet fixtures available |
| Competition and season | `Compete/`, `Season/`, `League/`; `#view-compete`, `#view-hub`, standings | Empty/forming/live/finished, one/many competitions, Cup race, points path | V4; competition fixture captured dark/light, default/AX3 Sep 22; signed-in routes remain open |
| Events, draft and setup | `Events/`, `Draft/`, `Wizard/`; `#view-event`, `#view-draft`, `#view-wizard` | Major/Ryder/callout, forming/live/finished, member/Pro, validation, review/confirm | V4; LeagueSetupReview passed Sep 22; remaining event fixtures and real paths are open |
| Administration and money | `League/SeasonAdminSheets`, `ReceiptSheets`, `PotPane`; web ruling/re-up/ledger sheets | Empty/history, positive/negative adjustment, no-round total, pending re-up, error | V4; preserve fixed money sentence and every points drill-down |
| Share and recipient | `Post/RoundSharePreview`, `Rounds/RoundCardArtifact`, `People/JoinLeagueFlow`; public share and claim pages, `share-preview.ts` | Photo on/off, long text, fresh/reused link, signed in/out, claimed/expired, back/cancel | V5; local fixture evidence + real Storage/link/device gate required |
| System and release | `Push/`, `CupSeasonWidgets/`, app icons, install assets, store screenshots | Lock screen, live activity, permission denied, missing data, dynamic type, reduced motion | V6; inventory/source located, renders and device evidence pending |

## The next execution step: V2

1. Capture Home, the four destination tabs and the Play chooser before editing. Use empty, populated, live, after-golf and no-photo fixtures; show each fixture name and build in the evidence record. Start with HomeNoPhoto, HomePhotoStability and AfterGolfAnswer tests. Use a test account only for surfaces that need one.
2. Inspect the rendered hierarchy: where the eye lands, the one next action, repeated facts, figure alignment, excessively tall empty blocks, and controls hidden behind tabs or sheets. Source grep identifies candidates; a visible state determines whether they are defects.
3. Fix shared presentation at its source when the defect is shared. Keep content selection, navigation ownership and competition rules intact. Do not copy the older dirty visual branch wholesale.
4. Verify dark/light, 375pt and standard phone sizes, AX3, web phone/desktop, photo/no-photo and long-name variants. Run affected local tests and preflight. Capture the final version, self-review the diff and commit the slice.
5. Update this record with changed files, before/after evidence, actual results and the next open item. Mark unresolved signed-in/device states as missing evidence, not passed or absent. Continue independent work while owner-only release gates remain pending.

## V1 implementation and evidence · September 22

| Finding | Before | Implemented correction | Evidence |
|---|---|---|---|
| Web welcome legal/caption text | `dim` plus 0.7/0.5 opacity; nominal contrast on ground only 2.18/1.70 dark and 2.01/1.62 light | Opaque `mut` on legal copy, links and build caption | Computed style confirms full opacity; nominal contrast now **7.07 dark / 5.85 light**. Actual welcome inspected in both themes. Version placeholder preserved. |
| Public pages change rooms unexpectedly | `/get` and `/support` default to the OS while the app defaults dark | Match the app's dark default; respect explicit light/dark/auto; blocked storage falls back dark | Browser checks include no saved preference and explicit light/dark. An explicit `auto` also follows the test machine's light OS preference on both pages. |
| Support navigation targets too short | 13px × 1.2 line-height plus 24px padding = 39.6px | Minimum height 44px with vertically centered link text | DOM measured all five links at **44px** at 375, 402 and 1280 widths. |
| Invitation context missing at native welcome | Generic welcome until the golfer entered the sign-in form; visible door did not observe pending-link notifications | Use the existing `PendingLink.doorLine()` before the entry choices and refresh when pending links/name arrive; reduce decorative space for invitations/AX sizes | New visual fixture/test traverses welcome → email in dark/default text and light/AX3. Late name replies cannot restore a spent or replaced invitation. Real recipient/device proof still open. |

Implementation commits: `faee731` (web entrance) and `e555f61` (native invitation) on `codex/october-visual-ui`.

Changed production source: `index.html`, `get.html`, `support.html`, `apps/ios/CupSeason/Door/DoorView.swift`, `DoorDev.swift` (DEBUG fixture only), and `CupSeasonApp.swift`. Added `apps/ios/CupSeasonUITests/VisualEntranceTests.swift`. No token, generated asset, scoring, consent or database change.

### Verification record

- Preflight: **PASS, 0 failures / 0 warnings**.
- Node unit suite: **29 passed**, zero failed.
- Existing browser function suite: **489 passed**, zero failed, in the locally served app after service-worker/cache reset.
- Browser entrance matrix: **18 cases** (welcome/get/support × dark/light × 375/402/1280 widths), no horizontal overflow. Support links remain 44px; the iPhone install button remains hidden without its real URL. Welcome's email action opens the field.
- Real allowlisted web build (`bash stamp-version.sh`): **PASS**; source version placeholders unchanged.
- Native: **PASS, 1,496 tests**, zero failed/skipped on iPhone 17 Pro (iOS 26.5): 1,235 Kit Swift Testing + 16 Kit XCTest + 120 design + 122 app + 3 UI tests. XcodeGen generation and the simulator build succeeded. The same 3 entrance UI tests also **passed on iPhone SE (3rd generation), 375pt**. Both result bundles closed successfully; dark/light, default/AX3 invitation and email screenshots were exported and visually reviewed. The existing Supabase initial-session runtime warning remains; this pass does not change authentication configuration.
- Local evidence paths: `/private/tmp/cup-season-visual-before.xcresult`, `/private/tmp/cup-season-visual-verified.xcresult`, `/private/tmp/cup-season-visual-small.xcresult`, `/private/tmp/cup-season-visual-preflight.log`, `/private/tmp/cup-season-visual-node.log`. These are machine-local verification artifacts, not public repository assets or release builds.

### Completion bar for every slice

Use before/after renders, not lints alone. At minimum: dark and light; standard and 375pt phone; AX3 on native or enlarged browser text; meaningful long-name/missing-photo/empty/error states; keyboard, safe-area and bottom-bar reachability; contrast at least 4.5:1 for ordinary text and 3:1 for large text/control boundaries; controls at least 44pt unless an existing documented exception applies. Check focus/VoiceOver order and reduced motion where the slice changes them. The web signed-out AX tree currently also exposes the underlying tab labels: reproduce keyboard/assistive-technology reachability in V6 and isolate the covered app shell if it is reachable; visual occlusion alone is not evidence of accessible modal behavior. Use the established timed-test gates for comprehension; an attractive screenshot is not an unassisted-round result.

**Current disposition:** V1's four corrections are implemented and locally verified. The owner has advanced selected daily-use V2–V5 checks for tonight's [Owner beta](2026-09-22-owner-beta.md); that packet is the current execution step and carries the final results. The remaining V2–V6 states stay queued. Full visual readiness, acquisition outcomes, real recipient proof and release approval have not been claimed.
