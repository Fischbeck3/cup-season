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
| F03 | P1 | Web sheet keyboard ownership | source + keyboard trace | open Card & settings; Tab | `openSheet`/`closeSheet`, shared sheet host, document key handlers | web (native verify: `SheetFrame`, `Presenter`) | root | — | one modal lifecycle: name, initial focus, inert background, Tab containment, Escape, restore/fallback, cleanup on every close/replace | keyboard trace for settings, course card, receipt, composer, confirm; nested replace; removed invoker; async; 0/1/many focusables; regression test | fixed · verified (web); native verify → N2 | 72e4626e · tests/sheet-focus-browser.mjs 30/30 @375,1280 |
| F04 | P1 | Legal theme + link contrast | source + computed 3.564/4.023 | `/legal.html` light | `legal.html` `:root`, link roles, footer theme script | web; native entry links | root | — | canonical page/text/act roles, dark-first prepaint, dark/light/auto + denied storage; legal text byte-equal | contrast normal/hover/focus/visited both themes; text equality diff; keyboard order; native links open | fixed · verified | 2433217a · tests/legal-shell-browser.mjs 83/83; body text sha ac76bd84 unchanged |
| F05 | P1 | Autumn Light action 4.312:1 | source + computed | Autumn look, Light, primary button | `tokens.json` looks.autumn; `CSTheme` act resolution; `CSPrimaryStyle` | native (web `act` regression) | N1 | — | smallest role-preserving fix at token/role source; regenerate | every look × both appearances × normal/pressed/busy/disabled + increased contrast ≥4.5:1 | fixed · verified (native, N1) | 74c7c7b6, 92be7811 (merged c6acfc2e) · every look × appearance × rest/pressed/busy/disabled ≥4.5:1, panel label ≥4.51 · launch/n1/contrast-f05.json |
| F06 | P1 | Course card compact/AX3 | source arithmetic | course card 9/18, AX3, 375 | `CourseCardLeaf` rows `height:20`, grid; `CSLeaf` padding | native + web course card | N1 (web: root) | FX for route | intrinsic row height; fit/scroll from available width; pinned row labels | 9/18, no yards, long tee, first/last col, SE3/17Pro, themes, default/AX3, VO order | fixed · verified (both) | native 6d85bdca, 4ac4aea4 (N1: rows grow with type, fit or scroll with the key pinned; CourseCardLeafTests 9) · web 95531942: the card folds into OUT/IN nines, whole at 375/402/desk, key pinned at 320 · tests/course-leaf-browser.mjs 122/122 |
| F07 | P2 | AX3 live context displaces scoring | captures | SE3 AX3 live | `LivePlayView` header/legend | native (web live check) | N2 | — | current hole/golfer scoring first; disclose secondary | first controls reachable without scroll; sync truth kept | open | |
| F08 | P2 | Tee/Rating/Slope lose labels | captures | live setup filled, AX3 | `LiveSetupView` tee fields | native (web setup check) | N2 | — | persistent individual labels inline + stacked | each value identifiable visually + programmatically | fixed · verified (web); native → N2 | 9b4570a5 · tests/live-setup-labels-browser.mjs (320/375/402/1280 × themes) |
| F09 | P2 | First-round composer explains league math | capture | web composer, no league | composer points panel/bands | web (native `PostRoundScreen` check) | root | — | task + short consequence first; bands behind named help | no league prerequisite implied; help focus; populated league keeps context | fixed · verified (web); native check → N2 | cfbc81f0 · tests/composer-first-round-browser.mjs 48/48 |
| F10 | P2 | Empty profile repeats absence | capture | You with 0 rounds | web You/stats renderers; `YouScreen`, `ProfileBlocks` | both | root / N3 | FX | one identity + one next step; reveal sections as data arrives | empty/no-league/one-round/populated/error truthful | fixed · verified (web); native → N2 | 539d271b · tests/you-record-states-browser.mjs 44/44 |
| F11 | P2 | Book cells read "33D" | capture | Book squads | web Book cell renderer; `SeasonBookPage` | both | root / N3 | FX | separate status marker; key near control; unambiguous AX name | §16 drilldown exact; compact + desktop | fixed · verified (web); native → N2 | 9c7e135a · tests/book-cells-browser.mjs 28/28 (receipt 9 = 9) |
| F12 | P2 | Compete empty repeats invitation | capture | Compete empty | web Compete empty; `CompeteScreen` | both | root / N3 | FX | one primary Start something by the empty action | no route loss; one accessible action | fixed · verification pending (web capture); native → N2 | 8e0254d0 · compete-rows-browser.js passes 320/390/1440 |
| F13 | P2 | Share artifact repeats band | capture | round share output | web share renderer; `RecapCardView` | both | root / N2 | — | say band once; facts + pennant kept | exported artifacts photo/no-photo/long; consent/cancel/withdraw | fixed · verified (web artifact); native parity → N2 | 8e0254d0 · tests/share-artifact-browser.mjs 81/81 |
| F14 | P2 | Tiny composer labels; 18px wizard help | source + capture | composer; wizard `.ibtn` | `.calc .trio span`; `.ibtn` | web | root | — | readable ink/size; honest 44×44 hit regions | measured non-overlapping bounds every wizard step; names/focus/expanded | fixed · verified | 4b520f0b · tests/wizard-help-targets-browser.mjs 102/102 |
| F15 | P2 | Compact calendar days 41pt | source arithmetic | Schedule at 375 | `ScheduleScreen` grid | native (web calendar check) | N1 | FX | reclaim spacing or compact arrangement | actual 44×44 hit bounds, no shared hit space, AX3 | fixed · verified (both) | web 0208e254 · native 9444e967, a2f275c4, ca5a4945 (44.4pt days at 375, the 1st drawn, legend in band; ScheduleCalendarTests 6) · web legend act/ink/mut 09ead060 |
| F16 | P2 | Album read failure shown empty | source | Album read fails | `AlbumScreen` state enum/catch | native (web record photo check) | N2 | FX | failed state + retry; keep items on refresh failure | empty/loading/fail/offline/retry/refresh-fail distinct | fixed · verified (web); native → N2 | a7e4ae8a · tests/calendar-album-browser.mjs 66/66 |
| F17 | P2 | Spacing debt 1,176 | exact LINT-06 | preflight extractor | `tests/preflight.mjs` LINT-06 | both | N1 / root | — | shared-source role adoption only | fresh count + per-file deltas; ratchet lowered only after verification | paid down · ratchet pending | LINT-06 1193 → 1161 at c72d6a72+N1 (N1 −11 native; web systemic passes); ratchet lowered after the N2/FX merges |
| F18 | P3 | Colored blurred ordinary-action shadow | source | any `.btn` | `.btn:not(.dark):not(.gold):not(.apple)` | web | root | — | remove glow; keep zero-blur selection cues | all button states legible/interactive; no replacement glow | fixed · verified | 77fee9c6 · no coloured blur on .btn; carry pulse halo removed |

## 2 · Fresh residuals from the repair critiques (Wave D)

| ID | Finding | Evidence | Source symbol | Owner | Change | Acceptance | Status | Evidence / commit |
|---|---|---|---|---|---|---|---|---|
| R01 | Door Back 28.75×15px, dim 3.15/2.89 | [assessment B](../approved/assessment-b.md) | Door back control | root | real 44×44 target, opaque readable ink, visible focus, stable position initial/re-entry | measured bounds; contrast; order | fixed · verified | 77fee9c6 · tests/door-residuals-browser.mjs 120/120 |
| R02 | "Go" does not say a code is coming | [assessment A](../approved/assessment-a.md) | `#obEmailIn` submit | root (N3 native parity) | "Send code" **or** one nearby fact, not both | 375px + keyboard fit; 8-digit flow unchanged | fixed · verified (web); native parity → N2 | 77fee9c6 · "Send code" fits 375×380 |
| R03 | Home occasion Dismiss 24px, 2.77/2.61 | assessment B | `.ho-x` | root | 44×44 non-overlapping; ink ≥3:1 non-text | bounds; contrast; name; dismissal | fixed · verification pending (Home capture) | 77fee9c6 · 44px mut dismiss |
| R04 | Home helper prose uses dim | assessments A+B | `.fine` in Home helper contexts | root | opaque `mut` in those contexts only | ≥4.5:1 both themes; dim uses traced | fixed · verified (source + contrast) | bc52e497 · .fine and 151 other text sites dim→mut |
| R05 | Buddy link wears ember | assessment A | `data-gopeople` link | root | ordinary `act` text-link grammar | competition signals remain ember | fixed · verification pending (Home capture) | 77fee9c6 |
| R06 | 375px NEXT helper truncates | assessment A | Home deck NEXT caption | root | reproduce on complete fixtures; fix truncation | full text at 375 both themes | fixed · verified | 5fb4272b · tile lines whole at 320/375/402/1280 |
| R07 | Competing content-level next actions | assessment A | Home desktop setup row vs rival story | root | reproduce on complete fixtures; one primary next move | recorded state; no fixed-nav false positive | fixed · verified | 5fb4272b (no disabled board tile) · 58bc3462 (desk: lead before the doors) |

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
| I01 | `tests/brand-door-browser.js`: 1600px terrain ≥60% of width vs 900px CSS cap (both themes) | fixed · verified (stale test, cited) | fd38b3cc: the test copied only the 62vw arm of 8f85dac9's `min(62vw, 900px)`; passes 320/390/1440/1600/1920 × themes |
| I02 | `DeviceOnlyAuthStorageTests.existingSDKSessionMigratesWithoutLosingItsBytes()`: -34018 in an unsigned simulator host | fixed · verified (N1) | 379e6daf: simulator hosts sign ad hoc with the app's entitlements (`CODE_SIGN_IDENTITY[sdk=iphonesimulator*]: "-"`); A/B on 14b7f4e4; full non-UI suite 1601/0. Lane note: never build test hosts with `CODE_SIGNING_ALLOWED=NO` |
| I03 | Full authenticated UI never run (no safe state injection) | open | needs S2 |
| I04 | Console output: missing career/schedule fixture read models, worker blocking, Supabase lock-option deprecation (also live in production) | fixed · verified (web; clean-run count pending) | 09ead060: no `lock` option on the pinned lockless auth-js 2.112.4 (WX tests/ten-lock-probe.mjs: 0 navigator.locks requests; a second tab boots past a zombie tab holding the auth lock); the realtime client takes its own storage key (no "Multiple GoTrueClient"); preflight `auth lock matches the pin`. The fixture read models were WX's (fixed in the harness). What remains in `normal` is the `[boot]`/`[realtime]` breadcrumbs CLAUDE.md keeps |
| I05 | Release archive: 83 warning instances across 21 messages | open | |
| I06 | `compete-rows-browser.js` fails at baseline: Compete overflows 2px at 320–402 (page-head terrain `right:-18px` in a 16px gutter) | fixed · verified | 68f7e8cf; passes 320/390/1440 × themes |
| I08 | `season-setup-browser.js` flaked at 320 on baseline and HEAD: standings nowrap cells widen the table in the fallback face | fixed · verified | a7ab6588; 12/12 fonts blocked + loaded |
| I09 | `post-hierarchy-browser.js` fails at 320 with fonts blocked on baseline: composer photo/scan row overflow | fixed · verified | f1b4b351; 12/12 twice |
| I10 | `round-record-browser.js` height budget flakes 1/12 at 320 light, fonts blocked (course name wraps a third line mid font-swap); geometry identical to baseline (206px) | open · test flake, not a regression | recorded |
| I07 | `interior-brand-browser.js` fails at baseline: I-3 treated D381's Scoreboard band as a quiet head | fixed · verified (stale test, cited) | 95eb5049; D381 owner amendment 2026-09-24 |

## 4b · Web systemic passes

| Pass | Commit | Evidence |
|---|---|---|
| dim is never a word (UI_SYSTEM §16.1): 152 text sites dim→mut, faded words opaque | bc52e497 | preflight 0/0; every web suite green |
| Ember audit (D359): ordinary links, selections, heads, tags, the armed Save move to act/mut/ink; 25 remaining ember sites are live/competition/identity | f0297c27 | every web suite green |

| 11px floor (§16.2): 63 sub-11px rules raised; BELOW_11 ratchet held at 0 | e39c9b61, 6f5a3be2 | every page suite green in scope |
| Door code fields named like Email (F01 twins): Sign-in code, League code | 81c749c1 | door-residuals 120/120 |

## 4c · Found in the integrated captures (root review, WX, WX-C2), fixed before the panel

Each was reproduced on this branch before it changed; WX's line numbers were at `d2fb1b55`.

| ID | Surface | Defect | Status | Evidence |
|---|---|---|---|---|
| X01 | Golfers → a golfer | `openPerson` called `.catch` on a PostgREST builder; the throw sent neither read, so **every golfer page** read "A golfer · Couldn't pull that card" (production since 916f35d2) | fixed · verified | 09ead060 · harness golfers/person route ok |
| X02 | Ryder room | a B win read "A def. B" | fixed · verified | 09ead060 · competition-truth 86/86 |
| X03 | Ryder room | a finished edition's series line counted only other editions ("all square 0–0" beside 7–5) | fixed · verified | 09ead060 |
| X04 | Compete / Scoreboard | a season a week before its first tee read Live / "Week 1 of 12" (week_no===0 only; UTC date) | fixed · verified | 09ead060 · Phoenix-evening clock in the test |
| X05 | Compete | a live Ryder's row read "Forming" (starts_on never selected) | fixed · verified | 09ead060 |
| X06 | Season table | a two-squad season drew "Cut · top one plays the Cup Final"; both play, the leader carries +10 | fixed · verified | 09ead060 · the phone's "Top seed · +10" |
| X07 | Cup Final race | a per-golfer monthly cap beside a squad's pooled rounds ("4 ROUNDS OF 3") | fixed · verified | 09ead060 |
| X08 | Ryder room | two four-golfer sides overlapped at 375/402 | fixed · verified | 09ead060 |
| X09 | Season page | sections scrolled to "start" landed under the 60px sticky bar | fixed · verified | 09ead060 · root scroll-padding; settle after the glide; instant under Reduce Motion |
| X10 | Season page (desk) | the pot in the 340 aside ellipsised money to "$7…"; the Book's dialog pinned top-left | fixed · verified | 09ead060 |
| X11 | Home | Up Next's nowrap chip pushed member Home 154px sideways at 375; 36px target | fixed · verified | 09ead060 · wraps whole, 44px |
| X12 | Home, Coming up, round sheet | the hero, the round cards and the RSVP buttons printed page ink on the figure tile (`--panel`): unreadable in BOTH themes | fixed · verified | 09ead060 · hero 14.0:1, RSVP ≥5.3:1 |
| X13 | Home | the hero's one move was ember with a coloured glow on ordinary actions (D359, F18) | fixed · verified | 09ead060 |
| X14 | Share artifacts | a long club-and-course name ran off both canvas edges (recap, round card, settlement) | fixed · verified | 09ead060 · the phone's two-lines-down-to-65% rule |
| X15 | Play | an empty or failed roster read re-primed forever (~800 requests in 2.5s) | fixed · verified | 09ead060 |
| X16 | Home (league-less) | the desk never asked `home_dispatch` without a league, so S1/S2 missed the phone's lead (D234) | fixed · verified | c72d6a72 |
| X17 | Courses | the lead plate cut a four-line name; the card scrolled in one 514px row with its key; the sentence was a clipped one-line input named only by its placeholder; long names stood one word a line | fixed · verified | 95531942 · course-leaf 122/122 |
| X18 | Home (league-less) | the install nudge (D186: shown once, 3.4s after landing league-less) overlays the top 76px of Home until dismissed | **named barrier · owner** | its timing is D186's; moving it in-flow shifts the page under the reader. Options for the owner: keep; in-flow at the head of Home; or after the first round |
| X19 | Card & settings | the chosen ball marker and the chosen appearance were a green word (`.mini` has no border, so the border cue never drew); the appearance buttons had no pressed state | fixed · verified | the chosen pill (`.mini.sel`) + aria-pressed · tests/selection-rows-browser.mjs 42/42 |
| X20 | Wizard | the step rail was ember (a D76 sweep); D359 and the phone's WizardDots make it ink | fixed · verified | selection-rows |
| X21 | Wizard review | a long value squeezed its label to one word a line ("HOW / SCORES / COUNT") | fixed · verified | selection-rows (text line boxes) |
| X22 | Schedule | the crew's plans printed the rivalry record and "ON THE SCHEDULE" in gold, Home's round cards the tee time (gold means earned; the phone prints ink); the desk calendar's square days were ~170px | fixed · verified | selection-rows |
| X23 | Public settlement / dead link | the way in ("Play this with your crew") was ember while the public round's is the action green (D359) | fixed · verified (source) | the dark printing of `act` on the ceremony ground |
| X24 | Schedule at 320 CSS | seven days inside the card compute 37px at 320 | **named exception** | below every supported iPhone (375pt SE is the floor, where days are 44.4); WCAG 2.5.8 AA (24px) holds and days stay square |

## 5 · Coverage, detector, panel, critique, audit, human

Each of these is tracked in its own file as it fills: `COVERAGE.md`, `DETECTOR.md`, `PANEL.md`, `CRITIQUE.md`, `AUDIT.md`, `HUMAN.md`. Until a file exists and holds evidence, its gate is **open**. The starting points are:
- [BASELINE coverage](../BASELINE.md#full-requested-coverage)
- [detector-ledger.json](../detector-ledger.json), 214 candidates
- [HUMAN-TASK-SHEET](../HUMAN-TASK-SHEET.md), NOT RUN
