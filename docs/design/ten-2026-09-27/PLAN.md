# Ranked plan · proposals only

No source fix is authorized. The owner must name launch items and say **“build it”**. PRE-FREEZE SAFE means small/reversible launch work or an evidence gate; it does not place the item in October 1. Selected code items get separate branches from the release owner’s candidate, finished by September29 for review. Visual freeze is September30. All other work waits until after launch. No source edits, push, merge, deploy, Apple action, dependency or decision ratification is included here.

Rank prioritizes proven user impact and verifiability. Evidence work comes before changes to uncaptured states. S1a/S1b are the recommended launch selection; S1 is optional because it expands the reviewed surface. Shared source causes are addressed before broad per-screen polish. Each slice retains §16, the money sentence, five destinations, terminology, mechanics and photo consent. Both client halves are reviewed; a correct counterpart receives verification rather than a gratuitous edit.

## 1. S0 · Complete safe evidence and owner launch gates — PRE-FREEZE SAFE

**Defect:** The native authenticated door→card→composer→post→Home path, claim/invite recipients and actual system-host/human behavior lack safe complete evidence. No absence is a passing result.

**Evidence:** Capture manifests and coverage notes; HUMAN-TASK-SHEET.md

**Cells / outcome:** M/R confidence across launch; E/P/D need real-content evidence. This is a proof gate, not a promised numerical lift.

**Impeccable command:** $impeccable audit; $impeccable critique after evidence exists

**Phone half:** Existing DEBUG harnesses and docs/pilot/owner-checks.md; no production files in this slice.

**Web half:** Existing browser suites and docs/pilot/timed-tests.md; no production files in this slice.

**Token and source changes:** No token/RPC/source changes. Owner runs candidate on actual phones; any new fixture seam belongs to S2.

**Verification:** Three new testers, G1–G4 timed per protocol; owner two-phone integrity and iPhone Safari/VoiceOver/keyboard/Reduce Motion checks. Record build and misses; never mark screenshot as pass.

## 2. S1a · Name the email field on the launch door — PRE-FREEZE SAFE

**Defect:** The email field has no persistent visible label or programmatic accessible name.

**Evidence:** Assessment A01: fresh browser AX/DOM and door-email captures; index.html4395.

**Cells / outcome:** door R/M/C; first action for screen-reader users. P1, not a proven complete launch blocker.

**Impeccable command:** $impeccable harden → $impeccable polish

**Phone half:** Door/DoorView.swift/DoorLayout.swift: verify corresponding email accessible name and visible context; no native change unless parity defect is reproduced.

**Web half:** index.html: add an Email label associated with #obEmailIn via for/id using existing form-label tokens; retain type/email/autocomplete/inputmode, code-only auth and all handlers.

**Token and source changes:** No new values, producers, backend, grants or auth behavior. Narrow accessible-label markup/CSS only.

**Verification:** Inspect AX name and visible label before/after typing; keyboard entry;375/402/1280/1600 both themes and reduced-height proxy; browser entrance suite and preflight; actual iPhone keyboard remains owner check. Separate branch from launch candidate, done by September 29 if selected.

## 3. S1b · Restore readable Home occasion text in both themes — PRE-FREEZE SAFE

**Defect:** Occasion heading uses page ink on inverse panel:1.077:1 dark,1.010:1 light. Body is2.108:1/2.674:1.

**Evidence:** A02 and B-W1 independently agree; index.html2318–2331 and home-brand-new/home-event_live captures.

**Cells / outcome:** Home H/R/C/P and first-round return legibility; P1, no proven blocked post/share.

**Impeccable command:** $impeccable colorize → $impeccable polish

**Phone half:** Home/HomeLead.swift/HomeView.swift inspect corresponding occasion/dispatch presentation; retain current native surface unless the same mismatch is demonstrated.

**Web half:** index.html .hocc: use existing non-inverted ground bg1 in place of panel so current ink/mut remain correctly paired. Use act for ordinary .ho-act in normal and earned variants; preserve competition/earned signals on the relevant fact. No copy/ranking/visibility changes.

**Token and source changes:** Existing tokens only; no new value or global panel redefinition. This narrows a misused inverse figure tile, not a new color system.

**Verification:** Same existing safe Home brand-new/event/preseason/ceremony variants, eight webmatrix cells,4.5:1 text/3:1 controls; visual regression on neighboring lead; browser Home state tests+preflight. Native counterpart inspection and source baseline comparison. Release owner must select this small item.

## 4. S1 · Bring the legal shell onto current readable tokens — PRE-FREEZE SAFE

**Defect:** The legal route still uses a separate palette/default and its ordinary light links measure 4.02:1 on white /3.56:1 on the page.

**Evidence:** AUDIT W-02/W-04; local legal dark/light captures (not committed because they expose a real contact address).

**Cells / outcome:** legal C/B/R/P; entrance continuity. No change to legal substance.

**Impeccable command:** $impeccable colorize → $impeccable polish

**Phone half:** Door/DoorView.swift and Settings/CardAndSettingsScreen.swift only verify existing legal links; no native edit expected because the destination is the same web page.

**Web half:** legal.html: replace its stale :root/light roles with current tokens; use get.html/support.html prepaint cs_theme resolver; move ordinary links to act/readable ink, not earned gold. Preserve every legal word and destination.

**Token and source changes:** Reuse existing token values; no new colors, token changes, generators, dependency or CSP edit.

**Verification:** 375/402/1280/1600×both themes; no preference + explicit dark/light/auto + denied storage; contrast normal/hover/visited, keyboard links and native external-page opening. Existing static-page/browser tests and preflight must pass on a separately cut launch branch by September 29. Owner must explicitly select this item; it is not a proven P0 fix.

## 5. S2 · Make every target safely reachable for review — POST-LAUNCH

**Defect:** Authentication gates and pilot-overlap fixtures prevent a complete repeatable matrix. Wrong-route or blank startup frames cannot stand in for requested screens.

**Evidence:** Native CAPTURE-NOTES; web coverage; C3 proposal.

**Cells / outcome:** All presently unscored cells; enables proof, does not itself improve visual quality.

**Impeccable command:** $impeccable harden → $impeccable critique

**Phone half:** Dev/DeveloperHarness.swift, Main/MainTabView.swift DEBUG boundary, safe fixture definitions and CupSeasonUITests; proposal only.

**Web half:** tests/fixtures/home-states.json and existing test fixture readers/browser harnesses; safe complete read models, not production demo rewrites.

**Token and source changes:** Explicit synthetic identities, deterministic empty/error/loading/long/no-photo/offline states. No production auth bypass, write simulation, server contract or scoring change.

**Verification:** Confirm routes show intended visible roots and sourceSHA; matrix8native/8web; fixture provenance scan; no network writes; source release behavior unchanged. Structural commit separate from design passes.

## 6. S3 · Give web sheets a complete keyboard focus lifecycle — POST-LAUNCH

**Defect:** Generic sheets visually block the task while focus remains behind them and subsequent Tab stops visit background controls.

**Evidence:** AUDIT W-01; web interaction-evidence.json (Card & settings opened with focus still on header search).

**Cells / outcome:** sheets/settings/composer-related M/R/C; not inferred to be a launch P0 without the actual blocked flow.

**Impeccable command:** $impeccable harden → $impeccable polish

**Phone half:** League/SheetFrame.swift and Main/Presenter.swift verify accessible title, initial focus, dismissal and return; change only if a matching native defect is reproduced.

**Web half:** index.html openSheet/closeSheet shared host: focus first appropriate control, isolate background, contain Tab, restore invoker after close, preserve nested-sheet behavior and Escape.

**Token and source changes:** No tokens, payload or gameplay changes. A structural behavior fix, separated from visual composition.

**Verification:** Keyboard forward/back Tab, Escape/backdrop/explicit close, nested replacements, restored invoker, screen-reader order; receipt, settings, composer and confirmation representatives at both themes/widths. Browser suites and preflight; corresponding native focus verification.

## 7. S4 · Let course grids and date controls fit actual available space — POST-LAUNCH

**Defect:** Course-card rows remain20pt while type grows; ordinary yardage grid needs382pt before outer gutters. Compact native calendar days compute41pt wide.

**Evidence:** AUDIT N-03/N-04 source arithmetic; uncaptured grid layout must be rendered first.

**Cells / outcome:** course/schedule Sp/R/M; no inherited old chrome penalty.

**Impeccable command:** $impeccable adapt → $impeccable typeset → $impeccable polish

**Phone half:** Courses/CourseCardLeaf.swift, Schedule/ScheduleScreen.swift; shared CSDesign/Structure.swift only if root component owns the failure.

**Web half:** index.html course-card/tee data and schedule/calendar renderer: inspect corresponding compact grid and controls, repair only demonstrated counterpart failures.

**Token and source changes:** Use space/type tokens, intrinsic row heights and width-dependent scrolling/fitting. Preserve hole/yard/par semantics; no new payload or fabricated course detail.

**Verification:** 375/402default+AX3×themes, no-yards/long-tee/offline course states, label/column alignment, actual44pt hit bounds; full-width desktop table remains useful. Relevant native/course/browser suites then preflight.

## 8. S5 · Resolve the Autumn light action contrast at its source — POST-LAUNCH

**Defect:** Autumn Light action/background pair measures4.312:1 for normal-size primary text.

**Evidence:** AUDIT N-01; contrast.json with22 normal-state combinations.

**Cells / outcome:** native action R/C/P; appearance-specific, not a global palette failure.

**Impeccable command:** $impeccable colorize → $impeccable polish

**Phone half:** CSDesign/Theme.swift action ink resolution and Controls.swift; generated Tokens.swift only through generator if source token changes are approved.

**Web half:** index.html ordinary act controls regression check; web has no equivalent native look picker to invent.

**Token and source changes:** Prefer an existing readable ink role if it preserves the role contract; otherwise propose a specific token-source change in packages/tokens/tokens.json and run tools/build-tokens.mjs. Do not invent a hex in the view or hand-edit generated output.

**Verification:** All looks dark/light at normal/busy/pressed states;4.5:1 normal text,3:1 controls; Swift token/theme/control suites, web default act regression and preflight. No live/earned color semantics change.

## 9. S6 · Distinguish missing memories from failed reads — POST-LAUNCH

**Defect:** Album catch paths set empty, telling a golfer to add photos when a read failed.

**Evidence:** AUDIT N-02 AlbumScreen.swift107–108; failure render not yet safely captured.

**Cells / outcome:** history/album E/R/M/C; user trust and recovery.

**Impeccable command:** $impeccable harden → $impeccable clarify → $impeccable polish

**Phone half:** Rounds/AlbumScreen.swift state enum/load/render; preserve loaded content on refresh failure and add retry.

**Web half:** index.html album/record photo reader: inspect error/empty counterpart and use the same produced copy meaning.

**Token and source changes:** Client state/copy only, no query visibility, consent or payload change. A shared copy producer if supported; no independently invented wording on each client.

**Verification:** Empty success, denied/unavailable read, retry success, refresh failure with existing content, offline; fixtures first, native state tests + browser state tests, preflight.

## 10. S7 · Pay down spacing and type drift by shared component — POST-LAUNCH

**Defect:** 1,176 current off-scale spacing values remain; raw counts are debt, not 1,176 visible bugs. Legacy web control/label grammar still differs across families.

**Evidence:** AUDIT S-01 exactLINT-06 extractor; fresh capture critique decides priority.

**Cells / outcome:** C/Sp/T/R on each touched family.

**Impeccable command:** $impeccable layout → $impeccable typeset → $impeccable extract → $impeccable polish

**Phone half:** CSDesign/Structure.swift, Controls.swift, Type.swift then only affected view call sites.

**Web half:** index.html shared spacing/type/control selectors then affected renderers; do not bundle a production JS rewrite.

**Token and source changes:** Reuse space and typography roles. Separate drawing geometry from layout spacing; no blind replace-all. If a missing semantic token is justified, propose it first and regenerate.

**Verification:** Same captured matrix before/after, token parity, lower—not weakened—ratchet, targets/contrast/no clipping; affected native/browser suites and preflight. Keep fact-bearing labels; remove only repeated facts.

## 11. S10 · Keep the next round action near its essential context — POST-LAUNCH

**Defect:** At AX3 the native live header delays scoring; populated tee fields lose individual visible labels. The web first composer starts with a large league-points explanation before a new golfer needs it.

**Evidence:** F07/F08/F09; LivePlayView119/145, LiveSetupView148, index.html5064; native default/AX3 and keyboard captures.

**Cells / outcome:** ios/play-cover H/T/Sp/R/M, ios/live H/Sp/D/M, web/composer H/D/M.

**Impeccable command:** $impeccable layout → clarify → adapt → polish

**Phone half:** apps/ios/CupSeason/Live/LivePlayView.swift and LiveSetupView.swift: keep current hole/score action first, put course/tee and secondary legend in a concise subordinate region, retain honest offline status; persistent field labels in stacked and row layouts.

**Web half:** index.html composer/setup/live renderers: disclose the existing league-points explanation at the relevant context; retain scoring and all input semantics. Use the existing shared copy source or propose a narrow source boundary before duplicating text.

**Token and source changes:** Existing spacing/type/state roles only. No formula, payload, during-play tracking or sync changes. Design pass separate from any structural state work.

**Verification:** Recapture both phones/default/AX3/themes including actual simulator keyboard; verify semantic names/order and field identity; owner checks real keyboard and score control reach. Browser375/402/1280/1600; targeted suites, full native end-of-slice suite and preflight.

## 12. S11 · Give empty states and record labels one clear job — POST-LAUNCH

**Defect:** Repeated empty Profile sections, duplicate Compete start text, adjacent Book numbers/status marks and repeated share-band meaning increase work without adding facts.

**Evidence:** F10/F11/F12/F13, captures for You/Compete/Book/share output.

**Cells / outcome:** web/you D/E, web/compete H/D, web/book C/D/M, web/share-card C/D; native counterparts require equivalent fixtures first.

**Impeccable command:** $impeccable distill → clarify → polish

**Phone half:** apps/ios/CupSeason/You/YouScreen.swift and ProfileBlocks.swift; Compete/CompeteScreen.swift; Season/SeasonBookPage.swift; Post/RecapCardView.swift. Preserve native shape and only repair a reproduced counterpart.

**Web half:** index.html: show one first-use action near the empty record, remove the duplicate empty Compete phrase, visually separate the existing D/* status/key from points and avoid repeating a named band in the share sentence.

**Token and source changes:** Existing tokens and common copy meaning. No invented accomplishments, numeric/ranking changes, removal of §16 drilldown or share-consent changes.

**Verification:** Empty/populated/long-name/error fixtures; inspect Book status and every points drilldown; output share card comparison; both client suites, theme/AX3 matrix and preflight.

## 13. S8 · Redesign the unavailable Event route recovery — POST-LAUNCH

**Defect:** The only complete primary row below 6 is web/events at5.70: an unavailable-route state with weak message/recovery hierarchy. This does not authorize redesigning the unseen event room.

**Evidence:** Three independent panel medians; web app-event-empty captures. See all 15 disagreements before choosing a comp.

**Cells / outcome:** web/events H/B/P/R/E; native counterpart unscored until safe error fixture exists.

**Impeccable command:** $impeccable layout → clarify → adapt → polish; agreed comp only for this redesign

**Phone half:** apps/ios/CupSeason/Events/EventRoomScreen.swift and EventRoomModel.swift: first capture the unavailable/failed route states; preserve event mechanics and meaningful native back behavior.

**Web half:** index.html#view-event and its load/error renderer: concise familiar destination title, readable explanation, adjacent return action and retry only where the existing read supports it. Desktop uses the established wide shell; phone puts recovery in reach.

**Token and source changes:** Existing bg/ink/mut/act and typography. Retain known safe destination; no fabricated event details or new backend. A re-fetch/state change, if needed, is a separate structural commit from the design pass.

**Verification:** Actual unavailable/error/retry/known-route fixtures, long title, both themes and all widths; keyboard focus and accessible order; native counterpart matrix once available; existing event/route suites plus full end-of-slice checks.

## 14. S9 · Fill the record with consented real places and people — POST-LAUNCH

**Defect:** Fixture-only E/P/D cells cannot prove a lived season; no fabricated face, league activity or testimonial can close them.

**Evidence:** Per-cell content ceilings in BASELINE/panel reasons; ROAD_TO_TEN§6-A; C4.

**Cells / outcome:** Content-capped E/P/D cells listed individually, without carrying over old caps automatically.

**Impeccable command:** $impeccable critique after truthful content exists; $impeccable adapt for validated image states

**Phone half:** Existing Home/HomePhotos.swift, Courses/CourseScreen.swift, Post/RecapCardView.swift, You/profile photo consumers; preserve consent.

**Web half:** index.html existing corresponding photo/record consumers and public round; preserve shared-copy cancellation/withdrawal.

**Token and source changes:** Optional actual-play photo collection, consented profile photos, rights/credit-checked course material. No UI/backend changes merely to fabricate density; new geometry/payload needs a separate proposal.

**Verification:** No-photo/allowed/withdrawn/broken-image/long-credit states, actual crop legibility both themes, private owner review of real records, synthetic public substitutes, repeated group human evidence.

## Complete issue mapping

| Issue | Slice |
|---|---|
| F01 · Email entry has no persistent or programmatic label | S1a |
| F02 · Home occasion panel uses page ink on an inverted panel | S1b |
| F03 · Generic sheet leaves keyboard focus behind the visible task | S3 |
| F04 · Legal leaves the shared paper and action palette | S1 |
| F05 · Autumn Light action text is below AA | S5 |
| F06 · Whole course-card row geometry conflicts with AX3 and compact width | S4 |
| F07 · AX3 live-round context displaces the scoring controls | S10 |
| F08 · Filled tee details lose their visible individual labels | S10 |
| F09 · First-round composer spends most of its length explaining league math | S10 |
| F10 · Empty profile repeats the absence of a record | S11 |
| F11 · Book status letters merge visually into point totals | S11 |
| F12 · Compete empty state repeats its primary invitation | S11 |
| F13 · The web round-share artifact repeats its performance band | S11 |
| F14 · Small functional labels and help controls need local accessibility repair | S7 |
| F15 · Compact calendar columns are narrower than44pt | S4 |
| F16 · Album read failure is shown as empty | S6 |
| F17 · Spacing-token adoption is still a large ratcheted debt | S7 |
| F18 · Ordinary actions retain a colored blurred shadow | S7 |

S7 includes the small help target/record label readability (F14), existing space-role adoption (F17) and removal of ordinary-action glow (F18); it must be split into narrow component commits, not a bulk literal rewrite. No new token values are currently proposed. If an approved contrast solution requires a new source value, edit tokens.json and regenerate; never hand-edit Tokens.swift, Markers.swift, Rpc.swift, BetaMark.swift or a deployed version string.

## Rechecked systemic caps

| Cap | Current status | Evidence and response |
|---|---|---|
| 1 premium / borders | original systemic cap stays lifted; current exceptions require visual judgment | Phone Capsule sites0, RoundedRectangle sites98 vs107 historical. Shared retired component grammar remains removed. CSLeaf still intentionally outlines paper in Light (Structure.swift282); not automatically a defect, and not enough to revive a product-wide cap. |
| 2 proprietary objects | lifted in source; distribution still for critique | CSGlyph sites71; proper golfer faces and scorecard/credential/competition objects exist. No penalty for D269 tab band, approved Plex/serif/mono roles, or fact-carrying labels. |
| 3 emotion / faces / courses / ceremony | historical technical cause substantially lifted; quality not certified | FriendsBoard.swift144,158 resolves avatar URLs; CourseScreen.swift215 supports credited golfer course photography; both season and live finish call CSTakeover (146/234), whose Ceremony.swift156-169 stages and seals, uses csFeedback, and rests under Reduce Motion. No claim all seven named moments or device haptics passed. |
| 4 consistency | still standing locally, with a different concrete basis | Spacing1,176; mixed legacy Typography and current role use; legal route palette drift; current section-head count79 and2 same-line display-weight calls are usage counts, not an instruction to make every header display. Shared controls have full states; blanket old button finding is stale. |
| 5 mobile geometry | partly lifted; narrower residual geometry defects remain | DoorLayout working register + action reveal and DoorView csStatusCap; schedule primary is inside scroll; PostRoundScreen275 uses safeAreaInset. The old four screenshots must not be inherited. Whole course card fixed dimensions and calendar day widths are current source failures; actual current keyboard/tab-band coverage belongs to captures. |
| type scaling | partial adaptation; no blanket no-Dynamic-Type claim | CSType UIFontMetrics reads environment; A11yStack reflows. Role caps: figure XL/L1.5, M1.45, display1.6, displayS1.8, agate2.2. Meaningful body/story/name roles scale. Fixed20pt course grid is the verified geometry conflict. Fixed export canvases are legitimate and not counted as app text failures. |
| light | implemented but not closed | Semantic light palette and contrast/transparency support exist; normal Autumn action4.312:1 fails; legal light links4.023/3.564 fail. Need full-state appearance matrix for closure. |
| state completeness | partial; explicit counterexample remains | Home and FriendsBoard distinguish failure from empty; AlbumScreen107 collapses them. Shared states/control implementations exist; screen reach must be checked rather than inferred. |
| motion / haptics | implementation exists; no experiential score claim | CSMotion reads Reduce Motion, CSTakeover has whole rest frame; haptic vocabulary is centralized. Web has many purposeful per-surface alternatives plus a .001ms universal backstop at4149. Backstop is a technical flag to evaluate for lost feedback, not proof all motion is broken. |

The current LINT-06 count is 1,176 (332 native,844 web), not the old 1,206; the current ratchet is 1,193. Counts describe debt, not 1,176 visible bugs. Existing figure caps and export canvases have intentional jobs; repair actual fixed-height/width collisions. The old “no motion/haptics” claim is obsolete: CSTakeover and central feedback exist. Device/human experience remains unproved.

## Fixture gaps before wider design claims

[BASELINE full coverage](BASELINE.md#full-requested-coverage) lists every requested surface/client. Highest priority: authenticated Door/code/card and first-post-to-Home journey; native Home/Profile/Season/Compete/Book/Scoreboard/course/record/settings/events; claim/invite recipients; complete populated web read models; native Album error; all native looks; real widget/Live Activity hosts; current store outputs. A current source file or a failed hatch showing Door is not an observed screen. Existing unsafe pilot-identity fixtures stay out of public evidence. S2 proposes safe source-declared synthetic identities and injected read models; no production auth bypass or mock write success.

## Content and remaining barriers

[CELL-BARRIERS](CELL-BARRIERS.md) specifies every sub-10 median and the removal proposal. [CONTENT-CEILINGS](CONTENT-CEILINGS.md) maps E/P/D ceilings to actual rounds/history, optional consented profile/round/course photos, and rights-cleared course photography where approved. No new during-play tracking, invented faces, activity, testimonial or customer claim. Content acquisition and structural payload requests are separate approval scopes.

## Execution and exit gates after approval

Load Impeccable’s craft floor and the mapped command for the selected slice. Design passes and structural builds ride separately. First capture its missing counterpart/states; then implement narrowly, recapture the same matrix, fix the identified batch, and confirm once. Run affected native suites then the full native suite at the end of a slice, affected browser suites and preflight (0 failures / 0 warnings). Preserve tests encoding ratified rules. Finish-review disposition is required for an agreed new-work rebuild; critique trend/polish closes a refinement. Current baseline warnings are open context, not silently waived future checks.

A 10 claim requires every cell≥9, product mean≥9.5 on a complete comparable matrix, critiques≥36/40 with no heuristic<3, audits≥18/20, no P0/P1, all detector candidates resolved or individually verified false positives, craft-floor proof and owner-run human gates. None is certified here.

## Ownership before source work

ACTIVE_WORK still assigns the Sep22 visual lane over index.html, CSDesign and native views. Potential overlap also exists in `claude/course-home-correction-2026-09-26`, `codex/social-course-blend-2026-09-26`, `codex/native-audit-repairs-2026-09-24`, `codex/course-navigation-2026-09-26` and the release worktree. Their existence is not proof of a live agent, and this lane claims no source ownership. Resolve the release owner and actual candidate before cutting any implementation branch. Port8791 belongs to the complete-week lane and remains untouched.

Branch: codex/impeccable-ten-2026-09-27
Goal: Phases 0–3 baseline and approval checkpoint
What changed: documentation, Impeccable context, reports and synthetic evidence only
Files changed: PRODUCT.md, DESIGN.md, apps/ios/PRODUCT.md, shared Impeccable metadata/surfaces/critiques, docs/design/ten-2026-09-27, planning prompt/ACTIVE_WORK
Verification run: source equality, native build/capture suites, evidence hashes and metadata, independent assessments/panel, token parity, local gallery checks
Database deploy owed: none
Edge deploy owed: none
Client deploy owed: none
Open questions / risks: QUESTIONS.md; incomplete coverage and human proof; source-lane ownership
Recommended next step: owner chooses scope and says “build it”; otherwise stop
