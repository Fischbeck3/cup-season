# Product board → paired implementation plan

**2026-09-14 · implementation plan requested by the owner.** Claude leads building across both clients; Codex independently reviews committed checkpoints. This document preserves the product board and sequences existing work. It does not certify the board's generated details as shipped behavior or deploy any code.

## References, scope and source

- [Owner brand reference](../brand/references/2026-09-14-owner-brand-board.jpg): the primary identity reference.
- [Product sections proposal](../brand/references/2026-09-14-product-sections-proposal.png): generated review board, eight section studies. SHA-256 `4a8a420a8e309512c0230429bcec8f3da0d224bd2a17cea9f65b077495b19676`.
- [Paired build brief](2026-09-14-brand-and-client-parity.md), including the owner's competition-only ember rule, governs acceptance. The D305/D313 amendment and brand canon record that rule.
- Product-board provenance: built-in image generation, using the owner's board and `Desingv1.png` as references. Prompt: eight readable section studies (Welcome, Home, Compete, illustrative active clash, Play, Golfers, You, illustrative receipt); cream/fescue/paper identity; green ordinary actions; ember only for active competition; native five-position labeled band; verified Fellas figures and explicitly illustrative other content. Refinement removed decorative ember outside the clash, restored dark bands, removed Fellas's invented photograph and changed distressed receipt paper to clean stock. This is a design reference, not a production asset or an acceptance screenshot.

**Observed checkpoint:** Claude branch `claude/brand-client-parity` has application checkpoint `bc22372`, ledger `9604661`, based on main `1bc307f`. Its reported HTTPS preview is https://deploy-preview-4--cupseason.netlify.app. Its ledger is `docs/reviews/2026-09-14-brand-client-parity-ledger.md` on that branch. These are builder-reported verification results; Codex has inspected the source summary/ledger but has not independently closed this checkpoint. Keep that existing ledger; do not create a competing one.

Already built in Claude's web checkpoint: five-position band, labeled outlined Play, cream/paper mark treatment, serif welcome, quieter terrain, selected ordinary green controls, receipt composition, focused tests. Native has the generated `act` token but **no matching UI consumer changes in that checkpoint**. Do not restart these changes or equate generated tokens with native parity.

## Translate the board without inheriting its mistakes

1. The board shows different theme examples; it does **not** authorize forcing Home to light or Compete to dark. Existing Fescue/Light/Match device and stored look choices remain. Every section supports the selected appearance; paper artifacts may remain paper as already designed.
2. Marketing panels are visual references, not new homepage priorities. Keep ranked live/action-required Home leads, actual competition context and one fact one place. Never hide actionable content behind a promotional scene.
3. The Play glyph stays in the band with a label, but native Play remains a presenting action, not a persistent selected destination. Preserve back/dismiss, live-round resume and existing long-press shortcuts. Do not copy the board's illustrative Play underline as a navigation decision.
4. Fellas figures were verified examples, not literals. No Alex match, 84 score, illustrative friends, artificial trophy, static handicap or generated photography goes into account UI. Use current domain facts and authorized media, or a purposeful empty/no-photo state.
5. The 84-versus-82 clash example illustrates color only. It does not define who wins: handicap/scoring and contest rules remain server-authoritative. Do not build gross-score comparison logic or urgency thresholds from the board.
6. Board/story typography have different jobs. Use native approved type roles, not an added font. The gross/rank remains tournament typography; avoid making every number a serif headline. Board glows, glossy buttons, decorative copy and rounded-box artifacts are not implementation instructions.
7. Use the existing mark source/generator; no raster tracing of the generated board. No fabricated licensed course image or automatic use of generated scenery in a real receipt.

## Work sequence and gates

Each implementation checkpoint carries BOTH web/native changes or a specific verified statement that one counterpart already meets the rule. Each gets an HTTPS preview, paired screenshots, tests and a ledger update. P0/P1 precede the remaining waves; independent review can overlap the next bounded wave.

| Wave | Work | Builder | Independent review / exit |
|---|---|---|---|
| P0 · Reconcile checkpoint A | Import this plan and color amendment into Claude's branch; inspect `bc22372` against native and the board. Classify existing changes as keep/correct/unfinished. Preserve good navigation and authentication work. | Claude resolves findings | Codex reviews exact source/screens and updates the existing ledger; no blanket rebuild |
| P1 · Shared identity and action roles | Consume `act` in native ordinary controls/Play, finish web classification, reserve competition ember, neutralize routine decorative ember, preserve looks/contrast/identity/gold. Align five-position band and welcome in both themes. | Claude, shared sources first then both clients | Paired welcome/band proof; ordinary actions green by default, no floating disc or hidden Play label, no blanket Compete orange |
| P2 · Home and competition | Apply editorial hierarchy to Home, native-style Compete rows/masthead, active-clash treatment and matching season/detail entry. Preserve real dispatch order and selected-league context. | Claude | Same state/facts on both clients; clash eligible→active→finished examples and the same item on Home; no invented urgency |
| P3 · Play, setup and receipt | Carry the system through Play options, post/editable league setup, completion, receipt, scorecard and share. Build the native counterpart of the web receipt and fix any board-related regression. | Claude | Both clients complete the core loop in an isolated test environment; draft retry and photo/no-photo/privacy paths verified; points trace to rounds |
| P4 · People, record and asset family | Apply Golfers/You/rivalry treatment and finish icon/boot/favicon/PWA/OG/export family from the accepted source. Preserve actual person/record data and appearances. | Claude | Correct identity at app, browser and shared-link sizes; no mixed old/new assets left unlisted; meaningful empty states |
| P5 · Paired release audit | Freeze one application candidate; inspect the full ledger and run required checks. Publish the reviewed web candidate separately from native signing/export/upload. | Claude builds/fixes; Codex verifies/integrates | Actual web version and native build/source/distribution state reported separately; physical-device gaps remain open until tested |

## P0 findings already established from source/ledger

- `bc22372` adds a decorative ember hairline on ordinary welcome/receipt. Claude's ledger says ember remains the identity hairline. The newer owner amendment restricts ember to active competition: neutralize these ordinary rules. Do not port them into native.
- Native `Tokens.swift` now declares `act`; the native UI still needs to consume the correct roles. Extend `Theme.swift`/shared component behavior so the change reaches buttons, Play, controls and applicable focus/selection states without local hex patches.
- Native look substitution currently treats `brand` as broadly replaceable. Audit every relevant consumer and preserve personal preference while separating ordinary action from the reserved competition signal. Do not add a second parallel token system or globally replace `cs.brand`/`--brand`.
- Claude's receipt puts gross in a large editorial serif. The product board and existing type-role rules use tournament figures for scores: resolve that in both clients before calling the composition final.
- Ledger row 2 says native AX labels wrap; current `CSTabBand` implementation contains a later single-line/minimum-scale treatment. Verify implementation and screenshots rather than repeating the stale comment. Both clients must keep all five readable labels at supported sizes.
- Full web icon/OG adoption and native receipt parity remain open. With-photo checks have fixture-only evidence; real account media and physical Safari are not yet verified.

## Surface-to-source map and acceptance

Web remains the single-file PWA; the named renderer/section is a scope boundary, not a request to introduce bundling. Re-check exact source names in Claude's latest tree before edits.

| Surface | Web / shared sources | Native sources | Required behavior and visual proof |
|---|---|---|---|
| Shared foundation | `packages/tokens/tokens.json`, generators, theme/style roles in `index.html` | `CSDesign/Theme.swift`, `Look.swift`, `Chrome.swift`, `Brand.swift`, shared controls | `act` vs active-competition role; correct foreground contrast; cream/green mark variants; protected semantic colors and gold unchanged |
| Welcome/auth | `#onboard`, `CS_BRAND`, email/join controls | `Door/DoorView.swift`, `DoorLayout.swift`, `CSBrandCopy` | Serif statement, confined topo, green ordinary entry; 8-digit code, resend, join, keyboard and errors remain functional |
| Navigation/Play | `.tabbar`, `[data-v="record"]`, existing `renderPlay`/routes | `Main/MainTabView.swift`, `CSTabBand`, `Post/PostCoverView.swift` | Five slots, outlined labeled Play, neutral selected tab, correct action presentation/dismiss and live resume |
| Home | `renderHomeDispatch`, `renderMeStrip`, wire and schedule producers | `HomeView.swift`, `HomeLead.swift`, `HomeWire.swift`, `AfterGolfAnswers.swift` | Ranked actual lead retained; photo/no-photo; one fact one place; truthful counts and league context; same competition color state as Compete |
| Compete/season | `renderCompete`, `csOpenSeason`, hub/standings | `CompeteScreen.swift`, `SeasonPage.swift`, standings views | Name/rank hierarchy, neutral routine standings, green creation; qualifying ember only; correct season/member/receipt destination |
| Post/setup | Composer/renderers and wizard in `index.html` | `PostRoundScreen.swift`, `PostRoundModel.swift`, wizard views and `WizardState` | Editable rules; truthful cap/solo/squad copy; no draft loss, duplicate post or fake success; unchanged money constant |
| Receipt/share | `openRoundReceipt`, receipt layout and artifact producers | `RoundReceiptSheet.swift`, `RoundCardArtifact.swift`, `BrandRecordCard.swift`, `CSArtifactFrame/Footer` | Paper/photograph composition from real data; gross/points not repeated; scorecard/attribution reachable; missing facts omitted; with-photo opt-out honored |
| Golfers/You | Golfers and You renderers, existing career loader | `GolfersScreen.swift`, `HeadToHeadPage.swift`, `YouScreen.swift` | Identity, handicap/unknown count, relationship and record facts preserved; usable empty/search/failure states; no invented records |
| Asset family | `brand/candidates/testflight-pennant/source.json`, mark generator, manifest/meta/install/OG | Generated mark and app icon sources, boot and export consumers | Matching silhouette and treatments across sizes; maskable crop, light/dark visibility, legible OG; generator ownership preserved |

## Required verification per wave

- Compare the same content/state on web and iOS, with source SHA and theme visible in the evidence manifest. Use current account reads or labeled fixtures; never compare a populated fake dashboard with a sparse real account and call the difference a bug.
- Web: 320 and 390, short viewport, 1440 smoke, light/dark, enlarged text, keyboard, scrolling and actual taps/routes. Verify changed cases, then preflight. Freshness bypass checks are distinct from service-worker update/offline checks.
- Native: focused unit/UI tests, simulator build, relevant small-phone/large-text captures, VoiceOver/reduced-motion checks when affected. A native generated token is not proof its UI changed.
- P2 color-state checks: ordinary season; existing active/closing clash; the same clash on Home; finished/earned result; casual live round; noncompetitive alert. Existing typed state controls color. No new event generation or notifications.
- P3 critical loop: sign in/join → open correct season → Play → restore/start draft → choose course/tee/date → post safely → receipt → scorecard/contribution → share/no-photo/with-photo opt-out. Test writes in an isolated environment; do not submit manufactured production rounds/invites/league changes for screenshots.
- Every wave includes success, loading, empty, failure and retry for touched flows. Protect auth boot, cross-script bridges, back navigation, unknown data, disabled/loading buttons and duplicate submit behavior.
- Keep private account screenshots local. Commit redacted or explicitly synthetic evidence only. Use screenshots as comparisons, not as production UI assets.

## Ownership, delivery and completion

Claude continues in `claude/brand-client-parity` and is sole implementation editor across the affected web/native/shared files for this sprint. Codex uses its own worktree to review exact committed checkpoints and return findings. Codex may execute local simulator/browser verification while Claude builds an independent next slice, but neither agent edits the other's active implementation workspace. Token and contract consumers wait for a committed source checkpoint.

Owner reviews one concrete paired checkpoint per wave, with directly viewable images and a working HTTPS link. Do not send only localhost, file paths or an HTML fragment the phone cannot open. A review should say what changed and what remains different in plain language. If native signing is still blocked, show simulator evidence and label it; web previews continue. Physical iPhone checks can complete when the owner returns to the Mac, without falsely closing them earlier.

Use the existing Claude parity ledger: **scoped → built → independently reviewed → preview verified → production verified** for each client. A row with an absent counterpart stays open. Platform-specific system integrations get explicit exceptions; they do not excuse shared UI/flow gaps. Record Home, Play and season state coverage, not just a welcome screenshot.

Release sequence: integrate only reviewed commits → required checks on one frozen source → verify hosted web candidate → owner reviews concrete production asset choices → promote authorized web layer and read back HTML/SW versions → archive/export/upload native when signing permits → verify App Store Connect processing and actual beta-group availability. Source, build, upload and installed state are separate facts. No database migration, Edge deploy, secret change or competition-mechanic change is planned; anything discovered to require one gets a separately scoped decision/deploy path.

No fixed completion date is promised from mockup count. P0/P1 produce the first reviewable correction; each subsequent wave produces a usable paired increment. Do not accumulate all native work behind a final catch-up phase.

## Planning handoff

Branch: `codex/brand-parity-brief-2026-09-14`.
Goal: translate the section board into a sequenced paired implementation.
What changed: preserved the generated review board; added wave/source/acceptance mapping and reconciled Claude's existing checkpoint with the latest color ruling.
Files changed: this plan, product-board reference, planning entry points.
Verification: reference hash, Markdown/link checks, source/ledger inspection and diff check. Documentation-only; no application tests required.
Database deploy owed: none. Edge deploy owed: none. Client deploy owed: none from this planning commit.
Open risks: builder-reported checkpoint A awaits independent review; native UI adoption and photo/device/asset gaps remain; generated board details must not override real product behavior.
Recommended next: Claude incorporate this plan and `9201c08`, resolve P0/P1 in the existing owned branch; Codex review that exact paired checkpoint.
