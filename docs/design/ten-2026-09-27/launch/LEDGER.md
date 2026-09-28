# Before-launch completion ledger · opened 2026-09-28 (Claude)

**Scope.** This ledger covers the owner's September 28 direction: *"Prompt claude to address other findings. Be extremely specific to meet our 10/10 expectation. We ship all before launch."* Under it, every remaining finding, fresh residual, missing family/state, detector candidate and per-cell barrier in this program is pre-launch work. The earlier "POST-LAUNCH", "proposal only" and "stop until build it" labels in [PLAN.md](../PLAN.md) describe the September 27 checkpoint. The history they record is kept, but they no longer defer anything.

**Source.** Integration branch `claude/ten-before-launch-2026-09-28` at `/Users/fischbeck3/cup-season-claude-ten`, cut from origin/main **`1b5916b251c00c4c0c02afd7b1540201dbe6e09d`**. Web and service worker read `1b5916b`. Owner TestFlight **1.0.0 (1053)** was built from `cf6d0663`.

**Rules held.**
- Original IDs are preserved.
- A failed result is recorded, never overwritten.
- Source-only findings are revalidated at HEAD before any repair.
- "Not captured / not scored" is never n/a.
- Human gates are never marked from automation.

Status vocabulary:
- `open`
- `in progress`
- `fixed · verified`
- `verified · no change needed` (the correct counterpart was checked)
- `fixed · verification pending`
- `blocked · owner/human`
- `failed` (kept with evidence)

Owners:
- **root**: integrator; sole writer of `index.html` and `legal.html`
- **N1**: CSDesign/tokens, course geometry, schedule
- **N2**: live, post, record and share views
- **N3**: identity, competition, events and door parity
- **FX**: native fixture seam and capture harness
- **WX**: web fixture harness, tests only
- Judges and assessors are independent agents that wrote no code.

## 1 · Program findings F01–F18

| ID | Pri | Finding | Current evidence | Reproducer | Source symbol (revalidate at HEAD) | Clients | Owner | Depends on | Change | Acceptance check | Status | Evidence / commit |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| F01 | P1 | Email entry label | shipped `111f8f3e`; live `1b5916b` | Door → Continue with email | `#obEmailIn` label; `DoorView` `.accessibilityLabel("Email")` | both | — | — | **preserve**, do not count | label + AX name remain after every Door change | shipped earlier · preserve | [DEPLOYMENT](../DEPLOYMENT.md) |
| F02 | P1 | Home occasion ink on inverse panel | shipped `68e8716f` | Home occasion fixtures | `.hocc` bg1 + `.ho-act` act | web | — | — | **preserve** | pairs stay ≥4.5:1 both themes | shipped earlier · preserve | [DEPLOYMENT](../DEPLOYMENT.md) |
| F03 | P1 | Web sheet keyboard ownership | source + keyboard trace | open Card & settings; Tab | `openSheet`/`closeSheet`, shared sheet host, document key handlers | web (native verify: `SheetFrame`, `Presenter`) | root | — | one modal lifecycle: name, initial focus, inert background, Tab containment, Escape, restore/fallback, cleanup on every close/replace | keyboard trace for settings, course card, receipt, composer, confirm; nested replace; removed invoker; async; 0/1/many focusables; regression test | open | |
| F04 | P1 | Legal theme + link contrast | source + computed 3.564/4.023 | `/legal.html` light | `legal.html` `:root`, link roles, footer theme script | web; native entry links | root | — | canonical page/text/act roles, dark-first prepaint, dark/light/auto + denied storage; legal text byte-equal | contrast normal/hover/focus/visited both themes; text equality diff; keyboard order; native links open | open | |
| F05 | P1 | Autumn Light action 4.312:1 | source + computed | Autumn look, Light, primary button | `tokens.json` looks.autumn; `CSTheme` act resolution; `CSPrimaryStyle` | native (web `act` regression) | N1 | — | smallest role-preserving fix at token/role source; regenerate | every look × both appearances × normal/pressed/busy/disabled + increased contrast ≥4.5:1 | open | |
| F06 | P1 | Course card compact/AX3 | source arithmetic | course card 9/18, AX3, 375 | `CourseCardLeaf` rows `height:20`, grid; `CSLeaf` padding | native + web course card | N1 (web: root) | FX for route | intrinsic row height; fit/scroll from available width; pinned row labels | 9/18, no yards, long tee, first/last col, SE3/17Pro, themes, default/AX3, VO order | open | |
| F07 | P2 | AX3 live context displaces scoring | captures | SE3 AX3 live | `LivePlayView` header/legend | native (web live check) | N2 | — | current hole/golfer scoring first; disclose secondary | first controls reachable without scroll; sync truth kept | open | |
| F08 | P2 | Tee/Rating/Slope lose labels | captures | live setup filled, AX3 | `LiveSetupView` tee fields | native (web setup check) | N2 | — | persistent individual labels inline + stacked | each value identifiable visually + programmatically | open | |
| F09 | P2 | First-round composer explains league math | capture | web composer, no league | composer points panel/bands | web (native `PostRoundScreen` check) | root | — | task + short consequence first; bands behind named help | no league prerequisite implied; help focus; populated league keeps context | open | |
| F10 | P2 | Empty profile repeats absence | capture | You with 0 rounds | web You/stats renderers; `YouScreen`, `ProfileBlocks` | both | root / N3 | FX | one identity + one next step; reveal sections as data arrives | empty/no-league/one-round/populated/error truthful | open | |
| F11 | P2 | Book cells read "33D" | capture | Book squads | web Book cell renderer; `SeasonBookPage` | both | root / N3 | FX | separate status marker; key near control; unambiguous AX name | §16 drilldown exact; compact + desktop | open | |
| F12 | P2 | Compete empty repeats invitation | capture | Compete empty | web Compete empty; `CompeteScreen` | both | root / N3 | FX | one primary Start something by the empty action | no route loss; one accessible action | open | |
| F13 | P2 | Share artifact repeats band | capture | round share output | web share renderer; `RecapCardView` | both | root / N2 | — | say band once; facts + pennant kept | exported artifacts photo/no-photo/long; consent/cancel/withdraw | open | |
| F14 | P2 | Tiny composer labels; 18px wizard help | source + capture | composer; wizard `.ibtn` | `.calc .trio span`; `.ibtn` | web | root | — | readable ink/size; honest 44×44 hit regions | measured non-overlapping bounds every wizard step; names/focus/expanded | open | |
| F15 | P2 | Compact calendar days 41pt | source arithmetic | Schedule at 375 | `ScheduleScreen` grid | native (web calendar check) | N1 | FX | reclaim spacing or compact arrangement | actual 44×44 hit bounds, no shared hit space, AX3 | open | |
| F16 | P2 | Album read failure shown empty | source | Album read fails | `AlbumScreen` state enum/catch | native (web record photo check) | N2 | FX | failed state + retry; keep items on refresh failure | empty/loading/fail/offline/retry/refresh-fail distinct | open | |
| F17 | P2 | Spacing debt 1,176 | exact LINT-06 | preflight extractor | `tests/preflight.mjs` LINT-06 | both | N1 / root | — | shared-source role adoption only | fresh count + per-file deltas; ratchet lowered only after verification | open | |
| F18 | P3 | Colored blurred ordinary-action shadow | source | any `.btn` | `.btn:not(.dark):not(.gold):not(.apple)` | web | root | — | remove glow; keep zero-blur selection cues | all button states legible/interactive; no replacement glow | open | |

## 2 · Fresh residuals from the repair critiques (Wave D)

| ID | Finding | Evidence | Source symbol | Owner | Change | Acceptance | Status | Evidence / commit |
|---|---|---|---|---|---|---|---|---|
| R01 | Door Back 28.75×15px, dim 3.15/2.89 | [assessment B](../approved/assessment-b.md) | Door back control | root | real 44×44 target, opaque readable ink, visible focus, stable position initial/re-entry | measured bounds; contrast; order | open | |
| R02 | "Go" does not say a code is coming | [assessment A](../approved/assessment-a.md) | `#obEmailIn` submit | root (N3 native parity) | "Send code" **or** one nearby fact, not both | 375px + keyboard fit; 8-digit flow unchanged | open | |
| R03 | Home occasion Dismiss 24px, 2.77/2.61 | assessment B | `.ho-x` | root | 44×44 non-overlapping; ink ≥3:1 non-text | bounds; contrast; name; dismissal | open | |
| R04 | Home helper prose uses dim | assessments A+B | `.fine` in Home helper contexts | root | opaque `mut` in those contexts only | ≥4.5:1 both themes; dim uses traced | open | |
| R05 | Buddy link wears ember | assessment A | `data-gopeople` link | root | ordinary `act` text-link grammar | competition signals remain ember | open | |
| R06 | 375px NEXT helper truncates | assessment A | Home deck NEXT caption | root | reproduce on complete fixtures; fix truncation | full text at 375 both themes | open | |
| R07 | Competing content-level next actions | assessment A | Home desktop setup row vs rival story | root | reproduce on complete fixtures; one primary next move | recorded state; no fixed-nav false positive | open | |

## 3 · Structural and program slices

| ID | Slice | Owner | Status | Notes |
|---|---|---|---|---|
| S2/C3 | Fixture seam: synthetic identities + deterministic read models, DEBUG/test only | FX (native), WX (web) | open | no prod auth bypass, no fake prod writes, out of release runtime and `dist` |
| S8 | Event unavailable-route recovery redesign (web/events 5.70) | root (web), N3 (native) | open | capture real event-room states before judging them |
| S9 | Photo/record states: none, credited, broken, withdrawn, long credit | N2 / root | open | no acquisition, no invented activity |
| E | Remaining H/T/Sp/C/B/P/R/E/D/M barriers ([CELL-BARRIERS](../CELL-BARRIERS.md)) | all | open | surface character per BRIEF §31 |

## 4 · Inherited failures (work, not waivers)

| ID | Failure | Status | Evidence / disposition |
|---|---|---|---|
| I01 | `tests/brand-door-browser.js`: 1600px terrain ≥60% of width vs 900px CSS cap (both themes) | open | |
| I02 | `DeviceOnlyAuthStorageTests.existingSDKSessionMigratesWithoutLosingItsBytes()`: -34018 in an unsigned simulator host | open | |
| I03 | Full authenticated UI never run (no safe state injection) | open | needs S2 |
| I04 | Console output: missing career/schedule fixture read models, worker blocking, Supabase lock-option deprecation (also live in production) | open | |
| I05 | Release archive: 83 warning instances across 21 messages | open | |

## 5 · Coverage, detector, panel, critique, audit, human

Each of these is tracked in its own file as it fills: `COVERAGE.md`, `DETECTOR.md`, `PANEL.md`, `CRITIQUE.md`, `AUDIT.md`, `HUMAN.md`. Until a file exists and holds evidence, its gate is **open**. The starting points are:
- [BASELINE coverage](../BASELINE.md#full-requested-coverage)
- [detector-ledger.json](../detector-ledger.json), 214 candidates
- [HUMAN-TASK-SHEET](../HUMAN-TASK-SHEET.md), NOT RUN
