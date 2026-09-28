# Cup Season — technical audit

**Source baseline:** `5fabf861`; checkout `d8671e77` has only the planning document above it. **Planning-only, no tracked changes.**

**Native conformance: pass with defects. Web integrity: partial.** Both clients express a specific golf/season system. D269’s custom tab band, the ratified type voices, factual labels and D76 dark-first choice are accepted constraints. None is a defect merely because the skill prefers stock UI.

This is an Impeccable technical audit, separate from the independent Nielsen /40 critique. All findings below are source-verified unless labeled arithmetic/inference. No full VoiceOver, device-haptic, frame-rate, keyboard or motion certification is claimed. iPad is out of scope. This agent did not run the web detector. Root delegated that scan to the Assessment B agent after independent Assessment A begins.

## Health scores

| Client | A11y | Performance | Theming | Conformance / responsive | Adaptivity / integrity | Total |
|---|---:|---:|---:|---:|---:|---:|
| Native iPhone | 2 | 3 | 3 | 4 conformance | 2 adaptivity | **14/20** |
| Web | 2 | 3 | 2 | 3 responsive | 2 integrity | **12/20** |

Native is Good; web is Acceptable on the technical rubric. These are bounded source-health estimates; lack of runtime evidence prevents an Excellent claim. Performance3 is provisional: lazy native lists, downsampled Home photos, lazy web feed images and limited third-party imports are positive source evidence, but no Instruments/Lighthouse or real-device trace was run.

## Prioritized findings

### N-01 · [P1] Autumn light primary text misses AA contrast

**Client/category:** native · Accessibility / Theming.

**Location:** `packages/tokens/tokens.json:555`, `apps/ios/Packages/CSDesign/Sources/CSDesign/Theme.swift:138`, `apps/ios/Packages/CSDesign/Sources/CSDesign/Controls.swift:39`.

Source-verified: Autumn light accent #A6601F becomes cs.act; CSPrimaryStyle uses cs.bg0 #F4F1E9 as text. Relative-luminance contrast is 4.312:1. Default name role is 17pt semibold, below the large-bold exemption. Other 21 normal-state look/theme combinations clear 4.5:1; this is a specific combination, not a global palette failure.

**Impact:** The main action becomes harder to read for low-vision golfers selecting Autumn in Light.

**Standard:** WCAG 1.4.3 normal text contrast; iOS accessibility contrast guidance.

**Recommendation:** Resolve action ink/paint in the token system for this pair; verify every look in both appearances, including pressed and busy states. Suggested command: `$impeccable colorize`.

**Evidence level:** source + computed contrast; not a device observation.

### N-02 · [P2] Album read failure is presented as an empty album

**Client/category:** native · State completeness.

**Location:** `apps/ios/CupSeason/Rounds/AlbumScreen.swift:18`, `apps/ios/CupSeason/Rounds/AlbumScreen.swift:31`, `apps/ios/CupSeason/Rounds/AlbumScreen.swift:107`.

Source-verified: the state enum only has opening/empty/ready. Both league-mate and album read failures enter catch and set .empty. The resulting sentence directs the golfer to add photographs; there is no failure state or retry action in this screen.

**Impact:** A temporary read failure incorrectly says existing memories are absent, and sends the golfer toward adding photos instead of recovering the read.

**Standard:** Repository failed-read-is-not-empty rule; actionable error recovery.

**Recommendation:** Add a truthful failed state with retry and preserve already loaded items during a refresh failure. Suggested command: `$impeccable harden`.

**Evidence level:** source; no network failure injected.

### N-03 · [P1] Whole-card geometry is fixed even when its type grows

**Client/category:** native · Adaptivity / Accessibility.

**Location:** `apps/ios/CupSeason/Courses/CourseCardLeaf.swift:60`, `apps/ios/CupSeason/Courses/CourseCardLeaf.swift:85`, `apps/ios/CupSeason/Courses/CourseCardLeaf.swift:111`, `apps/ios/Packages/CSDesign/Sources/CSDesign/Structure.swift:271`.

Source-verified geometry: the AX branch adds a horizontal scroller, but all text cells and row labels remain height:20. The column roles are uncapped Dynamic Type. With yards at ordinary sizes the contents need 30 + 9×32 + 40 =358pt; CSLeaf adds 24pt horizontal padding (382pt before the parent page gutter). Ordinary-size branch has no horizontal scroller. This cannot fit a 375pt phone even before outer padding. Actual clipping/overlap shape still needs a capture.

**Impact:** A golfer reading the offline course card on a narrow phone or at accessibility size can lose the alignment and legibility of yards, par and hole numbers.

**Standard:** iOS Dynamic Type/adaptive layout; repository AX3 and compact-phone acceptance.

**Recommendation:** Let row height follow measured text; choose a horizontal grid or fit strategy from available width at all type sizes, with pinned row labels. Suggested command: `$impeccable adapt`.

**Evidence level:** source arithmetic; rendering confirmation pending.

### N-04 · [P2] Calendar day targets fall below 44pt on compact iPhones

**Client/category:** native · Adaptivity / Accessibility.

**Location:** `apps/ios/CupSeason/Schedule/ScheduleScreen.swift:45`, `apps/ios/CupSeason/Schedule/ScheduleScreen.swift:119`, `apps/ios/CupSeason/Schedule/ScheduleScreen.swift:168`, `apps/ios/CupSeason/Schedule/ScheduleScreen.swift:395`.

Source-verified: outer padding is 20 each side, calendar padding 12 each side, seven flexible columns with six 4pt gaps. At 375pt width: (375-40-24-24)/7 =41pt per day; at 402pt it is44.86pt. A minHeight:44 does not give the narrow columns a 44pt width.

**Impact:** Picking a nearby calendar day is less reliable on compact phones, especially outdoors or with reduced motor precision.

**Standard:** iOS 44×44pt target guidance; compact width is in shipped iPhone scope.

**Recommendation:** Reclaim horizontal spacing or provide a compact date-selection arrangement whose actual hit bounds meet 44pt. Suggested command: `$impeccable adapt`.

**Evidence level:** source layout arithmetic; not a touch trace.

### W-01 · [P1] Generic sheets declare modality without owning keyboard focus

**Client/category:** web · Accessibility.

**Location:** `index.html:5959`, `index.html:23024`, `index.html:8951`.

Source-verified: openSheet fills and opens a div with aria-modal=true, freezes body scrolling, and wires rows. It never moves focus into the sheet, makes the background inert, traps Tab, or restores the invoking focus when closeSheet runs. Document key handlers include Escape and shortcuts but no modal focus management. This is distinct from the Book, which correctly uses dialog.showModal() at19609.

**Impact:** Keyboard and screen-reader users can remain on or reach controls behind a visually blocking receipt/form instead of entering the active task.

**Standard:** WCAG 2.4.3 focus order and 4.1.2 semantic/state consistency; modal dialog keyboard pattern.

**Recommendation:** Give the shared sheet host an explicit focus lifecycle and background isolation, preserving its existing sheet geometry and nested-sheet behavior. Suggested command: `$impeccable harden`.

**Evidence level:** source; keyboard corroboration requested.

### W-02 · [P1] Legal-page links fail contrast in Light

**Client/category:** web · Accessibility / Theming.

**Location:** `legal.html:13`, `legal.html:25`, `legal.html:28`.

Source-verified: links and the13px heading use #9A7B18. Contrast is4.023:1 on white section panels and3.564:1 on #EFF2EE page ground, below4.5:1. Links are ordinary reading size, not large text.

**Impact:** The privacy, terms and account-support links are harder to read on the page where people need to inspect the product’s promises.

**Standard:** WCAG1.4.3 normal text contrast.

**Recommendation:** Use the current action/text tokens and verify link, hover and visited states in both appearances; retain the legal copy. Suggested command: `$impeccable colorize`.

**Evidence level:** source + computed contrast.

### W-03 · [P2] Wizard explanation controls are 18px and use low-contrast dim ink

**Client/category:** web · Accessibility / Responsive.

**Location:** `index.html:2598`, `index.html:5240`, `index.html:5276`.

Source-verified: .ibtn is18×18px with padding:0; the actual wizard buttons use it for presets, counting rounds and minimums. Its dim glyph on bg2 is2.277:1 dark and2.289:1 light. No later size/color override exists except hover/expanded state. Score step buttons are also36×36px at1841, a44px-guidance gap, though above WCAG2.2’s24px minimum.

**Impact:** The controls that explain competition setup are difficult to hit and visually weak at the moment the golfer needs clarification.

**Standard:** WCAG1.4.11 non-text control contrast3:1; WCAG2.5.8 target size minimum depends on spacing; product44px touch guidance.

**Recommendation:** Keep the small visual glyph if desired but give it an honest44px hit region and readable token ink without colliding with its label. Suggested command: `$impeccable adapt`.

**Evidence level:** source; not a measured browser target audit.

### W-04 · [P2] Legal is a separate palette and theme-default system

**Client/category:** web · Theming / Implementation Integrity.

**Location:** `legal.html:12`, `legal.html:15`, `legal.html:111`, `support.html:14`, `get.html:14`.

Source-verified: legal uses old gray-black/cool-light literals and OS fallback, while get/support read cs_theme before paint and default new visitors to dark using the canonical green-black/almanac palette. Legal applies a saved explicit theme only in a footer script. Its card borders and gold/orange link role are also outside the current token roles.

**Impact:** Opening legal from acquisition/support changes the product’s visual identity, and a first-time visitor gets different appearance defaults by route.

**Standard:** D76 dark-first default; canonical tokens/brand application consistency.

**Recommendation:** Bring legal’s shell onto the current static-page tokens and the same prepaint theme resolver as get/support; preserve all legal wording. Suggested command: `$impeccable colorize`.

**Evidence level:** source.

### S-01 · [P2] Spacing-token adoption is still a large ratcheted debt

**Client/category:** shared · Implementation Integrity.

**Location:** `tests/preflight.mjs:2905`, `tests/preflight-baselines.json:11`.

Fresh exact LINT-06 extraction:332 native +844 index.html =1,176 off-scale spacing values. The current baseline is1,193; ROAD_TO_TEN reported1,206. This rule counts disallowed numeric values per source line, not all literal spacing, and excludes generated/test directories according to the repository extractor. Report data is in cup-ten-spacing.json.

**Impact:** Repeated local spacing decisions keep repairs from propagating consistently and make each responsive adjustment expensive; counts alone do not prove1,176 visible defects.

**Standard:** UI_SYSTEM spacing scale and ratchet.

**Recommendation:** Pay down literals by touched shared components and measured surface repairs; do not replace every number mechanically or conflate drawing geometry with spacing. Suggested command: `$impeccable layout`.

**Evidence level:** exact source scan, not Impeccable detector.

## Exact historical cap disposition

### 1 premium / borders

**original systemic cap stays lifted; current exceptions require visual judgment**. Phone Capsule sites0, RoundedRectangle sites98 vs107 historical. Shared retired component grammar remains removed. CSLeaf still intentionally outlines paper in Light (Structure.swift282); not automatically a defect, and not enough to revive a product-wide cap.

### 2 proprietary objects

**lifted in source; distribution still for critique**. CSGlyph sites71; proper golfer faces and scorecard/credential/competition objects exist. No penalty for D269 tab band, approved Plex/serif/mono roles, or fact-carrying labels.

### 3 emotion / faces / courses / ceremony

**historical technical cause substantially lifted; quality not certified**. FriendsBoard.swift144,158 resolves avatar URLs; CourseScreen.swift215 supports credited golfer course photography; both season and live finish call CSTakeover (146/234), whose Ceremony.swift156-169 stages and seals, uses csFeedback, and rests under Reduce Motion. No claim all seven named moments or device haptics passed.

### 4 consistency

**still standing locally, with a different concrete basis**. Spacing1,176; mixed legacy Typography and current role use; legal route palette drift; current section-head count79 and2 same-line display-weight calls are usage counts, not an instruction to make every header display. Shared controls have full states; blanket old button finding is stale.

### 5 mobile geometry

**partly lifted; narrower residual geometry defects remain**. DoorLayout working register + action reveal and DoorView csStatusCap; schedule primary is inside scroll; PostRoundScreen275 uses safeAreaInset. The old four screenshots must not be inherited. Whole course card fixed dimensions and calendar day widths are current source failures; actual current keyboard/tab-band coverage belongs to captures.

### type scaling

**partial adaptation; no blanket no-Dynamic-Type claim**. CSType UIFontMetrics reads environment; A11yStack reflows. Role caps: figure XL/L1.5, M1.45, display1.6, displayS1.8, agate2.2. Meaningful body/story/name roles scale. Fixed20pt course grid is the verified geometry conflict. Fixed export canvases are legitimate and not counted as app text failures.

### light

**implemented but not closed**. Semantic light palette and contrast/transparency support exist; normal Autumn action4.312:1 fails; legal light links4.023/3.564 fail. Need full-state appearance matrix for closure.

### state completeness

**partial; explicit counterexample remains**. Home and FriendsBoard distinguish failure from empty; AlbumScreen107 collapses them. Shared states/control implementations exist; screen reach must be checked rather than inferred.

### motion / haptics

**implementation exists; no experiential score claim**. CSMotion reads Reduce Motion, CSTakeover has whole rest frame; haptic vocabulary is centralized. Web has many purposeful per-surface alternatives plus a .001ms universal backstop at4149. Backstop is a technical flag to evaluate for lost feedback, not proof all motion is broken.

## Positive findings to retain

- Native shared ButtonStyles read pressed/enabled/busy states. The tertiary target applies contentShape after its44pt frame; it is not the earlier small-hitbox implementation.
- Native uses Dynamic Type-aware roles, a dedicated A11yStack, semantic palette substitution for increased contrast, opaque composition for Reduce Transparency, and named haptic events.
- The record/course/ceremony system has product-specific objects; photography now has real fallbacks and a credited course-photo path.
- The Home photo store downscales at decode and keeps imagery through transient refresh failures; Board uses LazyVStack and Album uses LazyVGrid.
- Web has persistent focus-visible rules, keyboard activation on data rows, preserved feed focus, per-surface reduced-motion treatments, lazy feed images, explicit eight-digit-code semantics, and a proper native dialog for the Book.
- Get and Support share current tokens and dark-first prepaint theme choice. Both offer readable line lengths, wrapping navigation and large primary targets.

## Evidence limits and remaining verification

No P0 task blocker was proven in this source pass. Findings count:4 P1,5 P2,0 P3 (shared spacing counted once). The2MB single-file source is1,998,806 bytes /649,866 gzip bytes in a local measurement; this is a profiling lead, not a measured slow-start defect and not a proposal to add a bundler.

Current captures should confirm CourseCardLeaf overflow, generic sheet focus, light states, compact/AX3 geometry, and failed/loading/empty states. The separately assigned Assessment B agent owns a single bounded browser-detector scan after independent Assessment A; detector findings must be checked against tokens and actual selectors. Do not conflate native source evidence with detector coverage.

Native motion/haptic implementation is present, but simulator stills do not establish timing, physical haptic quality, gesture reliability or full screen-reader behavior. Those remain named device/human gates rather than silently passing.

## Recommended command order

1. `$impeccable harden`: modal focus lifecycle and truthful album failure.
2. `$impeccable adapt`: course-card rows/widths, calendar hit area and wizard help targets.
3. `$impeccable colorize`: failed contrast pairs and legal token/theme parity.
4. `$impeccable layout`: pay down spacing by shared component during the above repairs.
5. `$impeccable audit`: bounded confirmation of the corrected source and captured states.
6. `$impeccable polish`: final pass after the substantive defects are fixed.

No implementation was authorized in this subtask and none was made. Reports: `/private/tmp/cup-ten-audit.md`, `/private/tmp/cup-ten-audit.json`; measurements: `/private/tmp/cup-ten-spacing.json`, `/private/tmp/cup-ten-contrast.json`.
