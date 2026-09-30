# Match Programme — Home and Compete

Approved by the owner on September 30, 2026: “Build Match Programme.”

The original direction and Build 2019 release record are preserved below. The [owner phone feedback amendment](#owner-phone-feedback--september-30) supersedes the original Home round/photo and period-heading composition; Compete retains its shipped composition. The Almanac pivot remains paused and Profile remains outside the correction.

## Direction contract — original approval

- **Mode:** Operate. Preserve Home's dispatch ranking and social wire, and Compete's peer list and nearest-clock ordering.
- **First viewport:** the Home masthead and number; a full-measure narrative lead and its existing action; strong rule-and-type section boundaries; a round's score and person beside an optional upright photograph. Compete opens with its title and season names, then supporting stage, context, and placing.
- **Signature:** programme section bands and prominent names. A round without an image becomes a numeric rail and open record; an image must not leave a placeholder when absent or unavailable.
- **Interaction:** existing actions, round receipts, person cards, reactions, competition pushes, and creation remain wired to their existing destinations. Whole-row targets are at least 44pt; accessibility sizes stack the photo and record or the stage and placing.
- **Scope:** Home and Compete views plus an opt-in section-heading weight. Existing themes, selected looks, native navigation, and protected tokens remain. No backend or gameplay changes.
- **Reference interpretation:** the three-screen approved concept tests optional imagery and hierarchy. Its fictional names, scores, dates, avatar photographs, and sample copy are not live content. Current producer wording and native token metrics win where the generated concept cannot represent actual data or reading sizes.
- **States:** photo, no photo, failed photo, long names, missing standing, setup, empty, stale/offline, loading, invitations, live lead, and earned ceremony. Finished competitions stay accessible. No extra data reads to decorate a row.

## Governing decisions

Product vision and the shared mechanics remain unchanged. D318/D319 keep the number at the masthead and debt with its season; D321 keeps a lone wire item from acquiring a redundant bucket title. The approved local section-band treatment supersedes the earlier no-rule display-head composition only on these two surfaces. D305/D313 still govern accent substitution.

## Current-main release integration — original Build 2019 source

This subsection describes the narrow port onto `origin/main` at `e2b62f00`, in the isolated `codex/match-programme-testflight-2026-09-30` release workspace. The release verification below concerns this integrated source; the earlier local implementation and its captures remain in the original workspace as historical evidence.

This is an ordinary native extension of the incumbent system. Existing root `PRODUCT.md`, `apps/ios/PRODUCT.md`, generated root `DESIGN.md`, `.impeccable/design.json`, token sources, and production brand assets are preserved. The old task adapters and illustrative browser specimens are not copied over current main. The scoped extraction lives here; no primitive values or synthesized ramps are added.

### Source adaptations

- **Color and identity authority:** D358 ratifies the current production pennant. D359 and its later amendments distinguish ordinary `act` controls from `brand` competition identity, with the narrow D368 earned-play exception and D381's selected Scoreboard application. Current `CSPalette.wearing` styles `act`, preserves competition `brand`/`brandInk`, and resolves panel ink centrally. Programme composition adds no new color role. The earlier D305/D313 wording above must be read through these later decisions.
- **Home lead:** the full-measure narrative uses the existing `lead` role and `localHeadlineMarked()` producer, with `localHeadline()` for spoken copy. The final live-cue correction applies D359/F4 and the latest UI_SYSTEM moment rule (Q36, September 29): only a genuinely live competition (`HomePage.isCompetition(item)` with an ember spine) shows the existing `CSGlyph(.dot, points: 23)` in `brand` beside its `brand` agate eyebrow. `leadEyebrow` uses the existing producer-derived state word, falls back to Live only for that live item, and adds no second state word when the eyebrow already contains it. Non-live cues remain quiet. The spoken lead uses the same `leadEyebrow`, keeping visible and spoken state aligned. Existing standing construction, routes, and clash exposure telemetry remain; DEBUG programme fixtures suppress that exposure event. The primary door still resolves through current ordinary `act` paint, independently of the reserved competition cue. The historical source comment calling it an ember door does not establish its actual color. This records the source correction; its recapture and final reviewer verdict are separate verification evidence.
- **Round record and photography:** `HomeWireBand` retains D361's `HomePhotoStore`, keyed by attachment path, and its credential states. A cached last good image survives transient signing or loading failures; a missing image produces the complete programme record. `HomeView` selects this branch for an attachment even when its current signed URL is unavailable. The record preserves the existing hole-aware gross label, factual round-detail producer, and optional supplied points/counting-story arguments. Unknown hole counts do not authorize a milestone claim. No extra read or replacement image is introduced.
- **Layout and type:** `social` and `agate` remain condensed board roles, `bodyS` remains system prose, and `lead` remains the platform serif. Reading-size photographs occupy an upright insert. Accessibility sizes keep the full-height photo-free record above an insert bounded to its actual available width. Round and golfer retain separate existing actions. Only an explicitly headed Today group suppresses its repeated visible day; broader and headless groups retain it, and the spoken record retains an available day.
- **Programme headings:** `CSSectionHead.Weight.programme` is opt-in for Home and Compete. It combines the existing heavy rule, `displayS`, existing spacing, and lower hairline. A selected look supplies two solid lower-rule segments. Other heading weights and canonical tokens are unchanged.
- **Compete integration:** invitations, shared `CompeteRoot` ordering, tied-rank wording, empty/failure distinctions, native routes, and the lead season's existing Book door remain available. Programme season records retain supplied points, `pointsStanding` when available, and `competitionLine`/factual gap; an unavailable points standing uses the existing rank fallback rather than an invented one. Visible and spoken records carry the same supplied scoreboard facts. The creation door uses current ordinary-action paint. Finished records move behind a native disclosure. Prominent season names and supporting stage/placing use existing roles.

### Source review findings and limits

The owner-approved Match Programme adapts D381's visual composition: supplied scoreboard facts now sit in the prominent programme season records instead of main's separate leading `leadBand`. The current implementation prints `row.points` with its points unit, prefers `row.pointsStanding` to the existing rank fallback, and uses `row.competitionLine` as support when points are supplied, otherwise the existing `row.sub`. The lead season retains its Book door and existing Book destination. This preserves D381's points, points-standing, and factual-gap content within the approved composition; it does not claim that a leading band was restored or change the shared competition/read semantics. Ordinary `act` paint and protected competition `brand` roles remain governed by current main.

Pre-existing drift is reported without repair: `Type.swift` shares a smaller metadata base between `agateS` and `columnS` while the UI table distinguishes them, and current serif growth differs from the old table caps. Historical `brand`-substitution and ember-door comments also survive beside current `act` resolution. Those comments and source/document differences are not promoted into new visual rules.

Evidence checked: current `HomeLead.swift`, `HomeView.swift`, `HomeWire.swift`, `CompeteScreen.swift`, `HomeWireCopy.swift`, CSDesign `Surfaces.swift`, `Type.swift`, `Theme.swift`, and `Controls.swift`; current token source and generated root design record; existing sidecar and product records; D358/D359/D360/D361/D368/D381; and the pre-port main Compete implementation. This is source documentation, not a screenshot review, passing-test claim, or distribution confirmation. No SwiftUI browser detector is applicable.

## Verification

### Owner phone feedback — September 30

The owner rejected the shipped Home round composition as “big clunky not engaging,” supplying an actual phone screenshot with a long Kaanapali course/tee name, handicap story, narrow photograph and separate supporting action rows. That real-content evidence supersedes this document's upright-photo and strong-Home-period signature. The subsequent Almanac pivot was explicitly scratched/paused. Profile is excluded from this correction.

The scoped correction uses the existing smaller `CSFigure.l` gross beside the full-width identity, `HomeWireCopy.courseTitle` for full-measure club/tee lines, and the existing `roundStory` producer for a separate supported story. A photograph occupies a 16:9 insert below the record. D361 retains a last-good image through transient failure; when no image is available, the complete record reserves no photo space. Applause, comments and Course share one supporting line at reading sizes and reflow at accessibility sizes, retaining separate 44pt controls. Home periods use the incumbent label-heading treatment. Compete retains its shipped composition. Existing copy producers, cache, routes, reaction semantics, counts, colors and the live Home cue remain authoritative. Verification and the fresh independent verdict for this correction are recorded in [the scoped handoff](home-phone-feedback-2026-09-30.md).

### Original Build 2019 verification — historical

The results below apply to the original Match Programme source distributed as TestFlight 2019. They do not validate the later Home correction.

Current-main domain and design verification passed 1,590 tests: 1,433 CupSeasonKit Swift Testing cases across 243 suites, 141 CSDesign cases across 36 suites, and 16 classic round-scorecard XCTest cases. This includes the three programme copy contracts. Release preflight passes with zero failures and warnings; `git diff --check` is clean. The spacing-literal baseline decreases from 1,048 to 1,047.

All five focused UI checks pass on both iPhone 17 Pro and iPhone SE (3rd generation). After the review's live-signal correction, the SE complete suite passed in `cup-season-match-programme-release-se-live.xcresult`, plus the added AX3 lead capture in `cup-season-match-programme-release-se-live-ax.xcresult`. The Pro passed four checks in `cup-season-match-programme-release-pro-live.xcresult`; its stale installed test-only predicate was cleared, and receipt navigation plus AX3 passed with freshly installed QA apps in `cup-season-match-programme-release-pro-live-final.xcresult`. These are local `/private/tmp/` bundles. Earlier failing bundles are diagnostic evidence only.

The fresh independent full review of all 32 native captures requested one material correction: preserve Home's current live competition signal/state. The existing brand dot and state eyebrow are restored in the full-measure lead while ordinary-action paint remains unchanged. Both themes and both phones were recaptured, with an additional AX3 first viewport on each phone. The same reviewer supplies the scoped final verdict in `design-match-programme-release-review.md`; the source documenter has rechecked the final integration.

### Original Build 2019 evidence and limits

The native XCTest/Simulator matrix is local and unaltered under `/private/tmp/cup-season-match-programme-release-review/phone-pro/` and `phone-se/`. It covers both printings, optional imagery and failed-image fallback, unavailable score, first-run Home, long names, AX3 records/inserts, Compete creation and Finished. The DEBUG programme hatch supplies named QA records, with a local illustrative golf photo; that image and hatch are absent from Release. These checks prove fixture layout and navigation, not live-account scoring or two-phone operation.

The approved three-phone decision board remains in the original workspace at `.impeccable/mocks/match-programme.png`; its fictional content is illustrative. Native acceptance follows the direction contract and current token/producer truth, with no whole-board pixel-match claim. No web detector ran on SwiftUI.

## Original Build 2019 release handoff — historical

Branch: `codex/match-programme-testflight-2026-09-30`, based on current main `e2b62f00`. The original dirty branch and unrelated work remain intact.

Goal: push the approved native Match Programme Home/Compete changes and distribute a verified Owner TestFlight build.

What changed: full-measure narrative lead; open round records with optional upright photos and bounded accessibility inserts; programme section rules; prominent season names with supplied points, standing and factual gap; retained Book destination, creation and Finished disclosure. Existing producers, photo cache, themes, ordering, social actions and routes remain.

Files changed: native Home (`HomeLead`, `HomeView`, `HomeWire`); native Compete (`CompeteScreen`, `CompeteFixture`); opt-in CSDesign section heading; shared `HomeWireCopy` and copy tests; DEBUG fixture/root shell and focused UI tests; lowered preflight baseline; this contract and release review.

Verification run: see the verified results above.

Database deploy owed: none. Edge deploy owed: none. Client deploy owed: native archive, upload and Owner availability readback; no web change.

Open questions / risks: real-device launch review remains. D372 keeps Friends distribution behind the complete two-phone owner checklist; that checklist is not established by simulator layout checks.

Recommended next step: install this release from Owner TestFlight and walk Home/Compete with real rounds and photographs.
