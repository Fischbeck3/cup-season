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
| I03 | Full authenticated UI never run (no safe state injection) | in progress · **blocked · owner** for the integrated run | FX's seam, flows and route tests are merged (31e99c7d); at FX's SHA the non-UI suite and SyntheticRouteTests are green. The full native capture matrix at the integrated SHA (4112a3f0) was **denied by the permission classifier** ("Modify Shared Resources") at `xcodebuild build-for-testing` in a fresh worktree; not worked around. The owner runs, or allows, FX's five commands (in its report) |
| I04 | Console output: missing career/schedule fixture read models, worker blocking, Supabase lock-option deprecation (also live in production) | fixed · verified (web; clean-run count pending) | 09ead060: no `lock` option on the pinned lockless auth-js 2.112.4 (WX tests/ten-lock-probe.mjs: 0 navigator.locks requests; a second tab boots past a zombie tab holding the auth lock); the realtime client takes its own storage key (no "Multiple GoTrueClient"); preflight `auth lock matches the pin`. The fixture read models were WX's (fixed in the harness). What remains in `normal` is the `[boot]`/`[realtime]` breadcrumbs CLAUDE.md keeps |
| I05 | Release archive: 83 warning instances across 21 messages | open | |
| I06 | `compete-rows-browser.js` fails at baseline: Compete overflows 2px at 320–402 (page-head terrain `right:-18px` in a 16px gutter) | fixed · verified | 68f7e8cf; passes 320/390/1440 × themes |
| I08 | `season-setup-browser.js` flaked at 320 on baseline and HEAD: standings nowrap cells widen the table in the fallback face | fixed · verified | a7ab6588; 12/12 fonts blocked + loaded |
| I09 | `post-hierarchy-browser.js` fails at 320 with fonts blocked on baseline: composer photo/scan row overflow | fixed · verified | f1b4b351; 12/12 twice |
| I10 | `round-record-browser.js` height budget flakes 1/12 at 320 light, fonts blocked (course name wraps a third line mid font-swap); geometry identical to baseline (206px) | fixed · verified (test recalibrated, cited) | 45d599f5: the height caps were read in whatever face had loaded (the page suites fetch Google Fonts live). The test now loads every declared face before measuring; in real faces the record is 206 (390) / 226 (320) on the pre-program baseline 1b5916b2 and on HEAD alike; the caps are those +4px; 3/3 green at 320/390/1440 |
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
| X01 | Golfers → a golfer | `openPerson` called `.catch` on a PostgREST builder; the throw sent neither read, so **every golfer page** read "A golfer · Couldn't pull that card" (production since 916f35d2) | **fixed · shipped to production** | 09ead060 on this branch · shipped alone on the owner's yes (2026-09-28) as d7a5a07d on main; cupseason.app serves `v23 · d7a5a07` and `VERSION = 'd7a5a07'`, with the fixed line; before/after: golfers/person failed at every width on 1b5916b2, 40/40 golfer captures pass on d7a5a07d |
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
| X25 | Golfer credential | fixed thirds truncated "BEST · MESQUITE WASH…" a word early | fixed · verified | f23431f6 · measured columns, the phone's Person.columnWidths |
| X26 | Season climb (two squads) | the seat line said "TOP 1 ADVANCE TO THE CUP FINAL"; both squads play, the leader carries +10 | fixed · verified (web); native → N2 | 49ee7d42 · StandingsMath.note has the same bug |
| X27 | Standings story | squad names in the squad palette as text, ~2.3:1 on the light theme's paper | fixed · verified | 49ee7d42 · ink name, colour on a swatch |
| X28 | Plan share page | "Take the seat" was ember | fixed · verified (source) | 49ee7d42 · the dark printing of `act` |
| X29 | Receipts, record, Cup Final rounds, board cards, album | round dates printed raw (2026-09-27) and read digit by digit | fixed · verified | 45d599f5 · csRoundDay "Sun Sep 27" |
| X30 | The Book | head and week columns printed ISO dates | fixed · verified (web); native head → N2 | 45d599f5 · "Jul 6 – Oct 18, 2026", columns named for screen readers |
| X31 | Live scoring | setup scrolled sideways 35px at 375 (the game control, after d2fb1b55's nowrap); the stuck board hid "N queued"; a just-score round announced side games over nothing (and an empty desk column); the hole read "SI"; the hole strip overflowed 1px | fixed · verified | 9d84c483 · WX play family 48/48, 0 overflow rows |
| X32 | Native · forced-update gate | the must-update screen shows "needs build N" and no way to update (FX) | open · native lane | a door that does not open is not offered (L-32) |
| X33 | Native · dev strings | the DEBUG `-cs_dev_bar_waiting` option embeds the owner's real name; `-cs_dev_no_worth` ships in Release | → N2 | FX release-proof otherwise clean: 0 seam strings, 0 synthetic symbols |

## 4d · CI set at d15b5f18 (a `git archive` snapshot, so `dist/` never touched the checkout)

| Step (ci.yml) | Result |
|---|---|
| preflight | PASS · 0 failures · 0 warnings |
| sunningdale | PASS · 27 assertions |
| unit (homefold, post-request, rating, trophycase) | 4/4 |
| courses + share consent | 24/24 |
| edge security (push, courses/scan, share cleanup, season email) | 40/40 |
| growth report, pilot scorecard, attribution | 37/37 |
| build (`stamp-version.sh`, COMMIT_REF=d15b5f18) | ok · `v23 · d15b5f1` and `VERSION = 'd15b5f1'`, 0 placeholders left in dist |
| dist stays untracked · migration names | ok · ok (no migration touched on this branch) |

## 4e · Released for the owner's testing (2026-09-28, on the owner's yes)

The owner said *"I give permission to push all remaining and ship to test."* No database or Edge Function change rides with this release.

| Layer | Identity | Proof |
|---|---|---|
| Web | main **`cf401dee`** (fast-forward from `d7a5a07d`) | 2026-09-29 00:47 UTC: cupseason.app reads `v23 · cf401de`, `sw.js` reads `VERSION = 'cf401de'`, and origin/main is `cf401dee`; the CI run on main succeeded |
| iPhone | Owner TestFlight **1.0.0 (1180)** from **`cf401dee`** | `tools/ios-archive.sh --upload` ran from a clean detached worktree: archive, export and altool succeeded, with an IPA of 22,184,643 bytes. A fresh altool log reads "UPLOAD SUCCEEDED with no errors". Then `tools/asc.py owner 1180`: VALID, What to Test set (200), added to Owner (204). A separate `asc.py status 1180` at 2026-09-29 00:46 UTC reads: VALID, not expired, internal **IN_BETA_TESTING**, **Owner YES**, **Friends no**, no beta review submission. `asc.py ship` was not run. |

- The native tree at `cf401dee` is identical to `4112a3f0`, where the phone run below ran. The archive, dSYMs and signing logs stay local: `cup-season-claude-ten-gallery/testflight-1180/`.
- **Phone run at `4112a3f0`, recorded as found:**
  - Build: succeeded.
  - Non-UI suite: TEST SUCCEEDED (1304 tests in 209 suites, plus XCTest 16).
  - `SyntheticRouteTests`: 13 executed, 2 skipped, and two results that are not proof.
- **X34 · the live finish route is not proven.** `testLiveFinishToRecap` failed. After the finish sheet's primary was tapped, the app showed Home with "Live round in progress · Hole 15" and no recap takeover. The same test failed in 2 of FX's 4 earlier runs (`fx/flows/`), and it taps a host that reports "not hittable". So it is a flaky route until shown otherwise, not a proven product defect. Finishing a live round on a device is owed. What to Test asks only for a hole to be scored; [HUMAN.md](HUMAN.md) D12 asks for the finish.
- **X35 · the album retry route is not exercised.** `testAlbumFailureThenRetry` passed only as an expected failure. The synthetic "failures" world rendered the album **with photographs** (`flow__album-failed`), so the failed read was never injected into F16's `AlbumModel`. The product half is code-read: the `.failed` state has "The album didn't load" and a Try again door. The unit tests of a54d2fb7 pass. The route proof is open until the fixture fails the read; [HUMAN.md](HUMAN.md) D13 is the device check.

## 4f · The assessment of `9d84c483`, and the fix waves after it (2026-09-28, night)

**The gates, as first measured on the candidate `9d84c483`.** No gate is met.

| Gate | Target | Measured on `9d84c483` | Evidence |
|---|---|---|---|
| §29 panel | no cell < 9, mean ≥ 9.5 | category **6.44**, craft **6.87**, owner **7.09** (web half); 0 of 22 rows ≥ 8 anywhere; schedule and wizard are "redesign" to the category judge; post is "redesign" to the craft judge | `evidence/panel/{category,craft,owner}.{json,md}` |
| Impeccable critique | ≥ 36/40 per target, no heuristic < 3, no P0/P1 | critique B: best **29/40** (competition, events, support); 4 P0, 20 P1. Critique A is still running | `evidence/critique-B/` |
| Web audit | ≥ 18/20 | **12/20** (A11y 2, Perf 2, Responsive 3, Theming 3, Integrity 2); 0 P0, 6 P1, 11 P2, 8 P3 | `evidence/audit-web/AUDIT-web.md` |
| Detector | every candidate resolved | **37,919 resolved, 0 open**; 22 true positives (7 P2, 15 P3) with proposals | `evidence/detector/DETECTOR.md` |
| Native half | same gates | the phone matrix at `4112a3f0` is still capturing, and native critique/audit have not run | `native-4112/` |
| Human | three testers G1–G4; owner D1–D13 | **NOT RUN** | [HUMAN.md](HUMAN.md) |

**Fixed at the root, integration commits.**
- **`38471687`: every P1 in the audit.**
  - Covers make the app inert (the Door, the share view, unsubscribe).
  - Six AA contrast failures.
  - The shadowed `vsShort` ("+1.4 over your playing HCP").
  - A dead join code said "You're invited".
  - `[hidden]` lost to component display, so the finish offered a photo on photo-less rounds.
  - The desk wizard review showed no rules, and a disabled Start said nothing.
  - The Form row golded a nine.
  - The retired D76 charcoal.
  - 44px targets.
  - Clipped names.
  - Keyboard access to golfer rows.
- **`735a63ec`: the season.**
  - The two-squad endgame line; `tests/fixtures/endgame.json` regenerated, 3 of 24 cases.
  - One minimum producer.
  - The ledger line once.
  - Rules first, and Leave at the foot.
  - Member voice on the roster, and drawn icons.
  - A buy-in ledger.
  - The POS head, and the gap cell.
  - No gold on your rung or the cut.
  - An ink average column.
  - Wrapping chips.
- **`69f40d1f`: structure.**
  - Critique B's season P0s: squad colour by `squads.color`; ties are ties, with no Points King crowned by average.
  - One h1 per view, the main landmark and a skip link.
  - One focus ring.
  - No Door flash for a returning session.
  - A 60px bar, and tab-bar scroll padding.
  - Theme-color and the manifest, with no portrait lock.
  - Door errors tied to their fields.
  - The desk inbox under the bell.

**In flight: five fix lanes, each merged by root.**
- **W1:** composer, play, receipts.
- **W2:** schedule, the Ryder/Major room, You, settings.
- **W3:** Home, Golfers.
- **W4:** share, public pages, links, get/support/legal.
- **W5:** Compete, the Book, the wizard.

Brief: `evidence/LANE-BRIEF.md`. Native twins go to N2. So far: LeagueCopy.endgame, SeasonStory's minimum, and the Form row.

**Settled by canon, not changed.**
- The cut is a 2pt ink rule on both clients (`CSCut`: "the rule carries the meaning"). The craft judge asked for 1px mut.
- The standings GAP column prints "+34" on both clients (`SeasonBoardCopy.gap`; its spoken form "34 back" is used for VoiceOver). The web's row label was fixed to match.

**Owner questions (decisions, not defects).**
- **X36 · the rivalry record.** You counts weekly clashes ("3–4, they lead"); the person page counts every week both played ("All square, 5–5"). Both are faceted records, and canon says never one blended number. Which record is "the" record on You, on the plan and on the person page, or should both surfaces name their facet?
- **X37 · the owner's own identity in the product.** The demo diorama's "you" is the owner's real first name, handle, city and course, and the golfer card's handle placeholder was the owner's own handle (W2 made it "@yourname"). Keep, or use a fictional one?
- **X38 · public privacy.**
  - The public settlement page shows non-sharing golfers' scores and debts.
  - The person landing shows an index and dated course visits to anyone holding the link (D241 vs D394).
- **X39 · trophies on a first round.** One round can earn Personal best, Broke 100 and Broke 90 at once.
- **X40 · "7.9 vs course".** On a personal best's subtitle (D291), against R-M's "vs your playing HCP". TERMINOLOGY row 92 confines "vs the course" to the receipt.

**Database owed (outside this brief: owner's `db push`).**
- **X41:** `home_feed.is_sub80` has no 18-hole guard (`20261020090000`), so a nine-hole 43 is "Broke 80". The client guard is lane W3's.
- **X42:** `the_plan_link.sql` counts an unanswered tag as "in" on the public plan landing. The in-app producer is lane W2's.

## 4g · N2 merged, and the work split into sessions (2026-09-28, night)

**N2 merged: `de3eaf35`.** The merge was clean, and preflight passes with 0 failures and 0 warnings.
- **Closed:** F03, F07, F08, F09 (check only), F10, F11, F12, F13, F16, R02, S8 and S9.
- **X34 (live finish → recap).** The finish sheet now carries identifiers, and the flow passed 6 of 6, three on each phone. The earlier failures were a widget crash after the recap and a dev round that never came up. Finishing itself works.
- **X35 (the album's retry).** The seam now counts only reads that fail after the route's `cs.screen` mark. The test asserts the failure, Try again, and the retry landing, both on time and when the album is opened late. It passed 3 of 3 on each phone.
- **The Form row.** A nine never takes the gold, and a nine says so.
- **The live recap.** The settlement card was drawn off screen on the SE3 and clipped on the 17 Pro. It is fixed, and each part is now one VoiceOver element.
- **Copy twins:** the two-squad endgame line, the rules page's minimum (`LeagueCopy.floorSentence`), and the ME strip's two-squad clause.
- **Other parity:** the two-squad climb, "A lost to B", the Ryder series count, the Book's dates, the owner's real name replaced by a cast golfer, and `-cs_dev_no_worth` moved into DEBUG.
- **N2's evidence:** 31 synthetic images plus `MANIFEST.json`, under `launch/n2/`.
- **Tests on N2's own tree.**
  - Non-UI: 1609 of 1609 passed.
  - UI: 27 passed, 1 failed as expected (the N1 items), and 3 skipped behind an environment gate. One share-sheet test timed out, then passed 2 of 2 on a re-run.
- **Not yet verified: the merged native tree.** N2's tree lacked integration's N1, N3 and FX native changes. Lane N4's phase 0 builds and tests the merged tree before any archive.

**Open from N2.**
- **Decision (D360).** Now that the recap's card shows, the recap draws the hole strip twice. N2 suggests keeping the card's strip and moving "Hole strip, thru N" into its spoken label. This goes to the owner memo.
- **Routed to N4:**
  - DeclareRoundSheet prints "You're in —" in gold.
  - Home says "1 comments", truncates a long name in its photo band, and sets "From the Pro" in gold.
  - The live rows sit at an 8pt inset.
  - The join covenant says "between the top two" for two squads.
  - GuideCopy states the minimum in its own words.
  - N1's items: CSCredential's heading, a 42pt Close, IntentSheet's inaccessible text, and the plan sheet's hit areas.
- **Web twin owed:** the web has no twin of S9's photo-unavailable line.
- **FX gaps (coverage, open):**
  - There is no synthetic live round. F07's test still asserts a real course name from the morning-review fixture, so its evidence is not committed.
  - There is no single-round You scenario.
  - The album's refresh-failure and offline routes are unit-tested only.
- **Gallery hygiene, outside git.** Some older result bundles in the gallery contain xcodebuild's automatic diagnostics, which include host-wide simulator logs:
  - `results/t5`–`t9`, `ui1`–`ui4` and `unit1`;
  - the `UI-se3-*.xcresult` bundles under `before/` and `after/`.

  Every run since `t10` uses `-collect-test-diagnostics never`. Deleting the old bundles is the owner's call.

**Split sessions** (on the owner's word, "keep going on the reviews and fixes - split into new sessions"). Every session is bound by the same rules and reports to root; root still integrates. Their shared brief, with one section each, is `evidence/SESSIONS.md` in the gallery.

| Session | Job | Starts |
|---|---|---|
| A | Native review: coverage, `failed.json`, critiques A and B, the native audit, a detector sweep, parity, and the N4 work list | now |
| B | W6 web lane: shared producers and chrome ([WM], the CTA grammar, the desk ME strip, the lanes' "needs root" items, ratchets) | on GO, after W1–W5 merge |
| C | The launch write-up (COVERAGE, PANEL, CRITIQUE, AUDIT, DETECTOR) and the owner-questions memo | now |
| D | Web re-assessment, round 2: a fresh gallery, critiques A2 and B2, audit AW2, detector DX2, and a delta table | on GO |
| E | N4 native lane: phase 0 verifies the merged tree, phase 1 the known items, phase 2 the native findings | phase 0 when the phone matrix finishes |

The judges stay with root, so their calibration holds across the native half and round 2.

## 4h · The web lanes merged, root's fixes, and the ship on the owner's word (2026-09-28/29, night)

**Merged into integration.** Each lane is merged with `--no-ff`, and its report is its lane's record.

| Lane | Merge | What it carries |
|---|---|---|
| N2 | `de3eaf35` | the native views (§4g) |
| W3 | `e8108e59` | Home and Golfers |
| W2 | `f46086b4` | schedule, the Ryder/Major room, You, settings, the card gate |
| W4 | `b8a61266` | share, one public shell, links, get/support/legal, the Door's wings |
| W5 | `4a703402` | Compete, the Book, the wizard |
| W1 | `1e9eb856` | composer, live scoring, history, S9's web twin |
| C | `ab7f7c34` | docs: COVERAGE, PANEL (both halves), CRITIQUE, AUDIT, DETECTOR, OWNER-QUESTIONS |
| B (W6) | `f6cb4760` | shared producers and chrome: one lockup (the Door keeps its serif), the ME strip, one CTA grammar, the lanes' needs-root, ratchets lowered |

**Conflicts, and how they were settled.**
- **Trial merges before the lanes finished** found three overlaps: the finish ceremony (W1 and W4), the public plan landing (W2 and W4), and the invitation banner (W3 and W4). Root assigned an owner to each, and every lane obeyed before reporting.
  - The finish ceremony went to W4. Round points are ink, not gold (UI_SYSTEM §2.4).
  - The public plan landing went to W4, with W2's `fmtTee`.
  - The invitation banner's logic went to W3, and its look to W4.
- **One textual conflict:** `csSideWho`. W3's rule was kept.

**Root's own fixes after the merges.**
- `65a1a11a`: a course row gives a long name the line when the row is under 600px (a container query). W2's two-column You had squeezed it. course-leaf opens You's courses door; it had failed 10 of 122 at `b8a61266`.
- `8aaab412`: harness state `record--photo-credited` now proves W2's fix: a golfer's own photo carries no credit.
- `45d40eb3`: **`?cs_home_state` lifts the Door only when its fixture was served.**
  - This was a live exposure. On `cf401dee`, a prod-like host lifted the Door onto the demo diorama for a signed-out visitor.
  - Found by session C's code read, and probed before and after.
- `53129f8f`: the events states tap the Ryder in W5's `#cmpMoments`.
- `6c5f251b`: the install nudge stays dismissed and never sits over the composer (code-audit B25).
- `ba6935a5`: the ledger's X37 line names the owner's handle by role.
- `b82eabd9`: the last retired 3.5px spines leave the Season page: `.purse`, `.pro`, `.phasehero`, `.nextcard` and `.ontheline` (AW P2-13, DX TP-09).

**Held off main (owner's call).** `d30f1ecb` on `claude/ten-w6-shared-2026-09-28` is a migration.
- It patches `home_dispatch` to say "See the terms before you're in".
- It is copy only, idempotent, and proven on the disposable cluster.
- B reverted it on its branch (`d355b115`). Take it, then `db push`, when wanted.

**Counsel.** W4 renamed "Prize Pool Disclaimer" to "The pot" in `legal.html` and `legal/*.md`, following TERMINOLOGY row 144. The disclaimer's text is unchanged. Counsel should read it; a revert is one line.

**The panel's native half** (`4112a3f0` = TestFlight 1180): category **7.04**, craft **7.42**, owner **7.77**; no P0.
- P1s:
  - the composer's toast drawn under its cover;
  - the AX3 gross field;
  - live seasons shown as FINISH;
  - the Form row's nine, fixed by N2.
- All but the Form row are routed to N4. The details are in `PANEL.md` §5.

## 4i · Released for the owner's testing, again (2026-09-29, night, on "ship me the latest")

**The owner, before sleeping:** "Run through remaining items, tidy up and ship me the latest please." That yes covers tonight's candidate. Every commit after `7b9c17e4` needs a new one.

| Layer | Identity | Verified |
|---|---|---|
| Web | main `272c2da1` at 00:09 MST, then `7b9c17e4` at 03:53 (fast-forwards from `cf401dee`) | The live stamp read `v23 · 272c2da`, then `v23 · 7b9c17e`, and the service worker `VERSION` matched each time. CI green. A production smoke with Supabase aborted: `?cs_home_state` keeps the Door up and the shell inert; the console is clean |
| iPhone | Owner TestFlight 1.0.0 (**1328**) from `41cf8050` at 03:28, then (**1335**) from `7b9c17e4` at 04:04 | Each is VALID and IN_BETA_TESTING in the Owner group, **not** in Friends, and never `asc.py ship`. The archives, IPAs and dSYMs are kept under `cup-season-claude-ten-gallery/testflight-13{28,35}/` |
| Database | nothing | No migration after `cf401dee` is on main; B's `d30f1ecb` is held on its branch |

**Verification behind 1335 and `7b9c17e4`:**
- Web: 43 of 43 browser suites at `dcafca7f`. `7b9c17e4` adds only an `aria-labelledby` to it.
- Web captures:
  - D's full capture of `fd27ace4`: 1,126 captures, 0 page errors. Its only errors were the course-card timeouts, fixed at `5df6d4cc`.
  - Recaptures of every family changed since then: 0 failures.
- Native, at `146401bb` (the same native tree as `7b9c17e4`), on root's fresh simulator:
  - build green;
  - 1321 package tests plus the app-hosted suites, at `7b9c17e4`;
  - 31 UI tests with 2 env-gated skips and 0 failures. These are the route suite, the N2 suites and N4's refusal and AX3 tests.
- **FX's simulator falsely failed the recap tests at `9e3a49b3`.** It was left dirty by the capture matrix. Both tests passed on a fresh simulator.

**What tonight's two releases carry beyond `cf401dee`:**
- all five web lanes, B's shared chrome, and E's native phases 1 and 2 (set 1);
- root's fixes:
  - the `?cs_home_state` exposure;
  - the course tap;
  - the halfway-turn roster line;
  - the unsent-score count;
  - the public plan's "on the plan";
  - the dead-link landing;
  - the covenant's Custom head;
  - the picker's edge fade;
  - the still Door wings;
  - the golfer page's columns;
  - the album render;
  - the install nudge;
  - the index field's name;
  - the palette's pigments;
  - the course row container.

**Round 2 (panel web half):**

| Judge | Round 2 | Round 1 |
|---|---|---|
| Craft | 8.28 | 6.87 |
| Owner | 7.94 | 7.09 |
| Category | 7.44 | 6.44 |

- Critique B2 at `ed8e6837`: best 33/40.
- AW2: 13/20.
- **No gate is met.** The human gates G1–G4 and D1–D13 have not run.

**Open, and the owner's:**
- the Oct 1 default look (Q31, top of the memo; 1335 still turns Fall on Oct 1);
- X36 to X40 and Q1 to Q37;
- database owed: X41, X42, the head-to-head week count, and `d30f1ecb`;
- counsel on "The pot" in `legal.html`.

## 4j · The morning after the ship: C, B and E merged, root's audit fixes (2026-09-29, 05:00–07:00, nothing pushed)

Nothing here is on main or in a TestFlight build. Main is still `7b9c17e4`, the same tree as Owner TestFlight 1335. Each push or upload needs the owner's new yes.

**Merged into integration:**

| Merge | What | The session's own proof |
|---|---|---|
| `fe811bb6` ← C `bb871c73` | Round 2 folded into the six launch docs; Q39 (the record's "+2.4") | preflight 0/0 |
| `295e837b` ← B `e8cc1b12` | W6 checkpoint: D380's Share (card and link), AW2-09's course row, the tee select, the card gate's Save, the covenant at 375, the rail's foot, the wizard's Pro row, PAR-33's bridge, and three twins (the buy-in in ink, the sync window, the receipt's 3:2 plate) | all 44 suites, app-tests 502/0, preflight 0/0 |
| `5b352210` ← E `97f9204e` | N4 phase 2 part 1: the six P1s as far as unblocked, the sub-80 twin, the W1–W5 and B copy twins, root's four rulings, Q29, A's first P2s | build; non-UI 1703/1703; UI 43/45 (0 failed, 2 gated); SE3 5/5; preflight 0/0 |
| `a27fbaf5` | The ratchets lowered to the merged head: LINT-06 1066, LINT-07 102, LINT-14 123 | preflight 0/0 |
| `c11199d7` ← B `41a71fc6` | D's four round-2 items: a first round's "Add my round" opens the fold and names the field there; "Change setup" holds the round; Delete account takes and returns focus; OB2-01's ground under the board photo. Plus the empty slope, per root's ruling | preflight 0/0; all 44 suites (app-tests 502/0); a full harness run with 0 route failures |

One conflict, in the settings "Ball marker" block: root's group name and B's "Your photo" gloss were both kept.

**Root's fixes from round 2's audit (AW2) and detector (DX2):**
- `29dfb7b0` AW2-10: the card gate's two questions name their groups, and a marker pick returns focus to its row. It had fallen to `<body>`.
- `4c2ac97f` AW2-11: a focus ring on the leaf is drawn in the leaf's ink. Dark went from 2.54 to 14.44:1.
- `70af0c09` AW2-18 part 1:
  - decorative SVGs carry aria-hidden (home--member went from 28 unnamed to 0);
  - a failed "Send code" leaves focus on the address, not `<body>`.
- `7e1d5949` AW2-18 part 2 / TP-17: no page skips a heading level.
  - 31 of 154 renders skipped a level at `a27fbaf5`; 0 now.
  - Pixel-identical, except for #msSame below.
- `f61b96c9` TP2-01: `#msSame` is a sentence in the body role.

**Rulings sent to the lanes:**
- The empty slope follows the phone's IOS-030 guard. score_round stores no differential without a slope, so the web's `||113` preview goes (B).
- N4-113's "RIGHT NOW" is not ember. No round is live on the when-fork (D359, L-40).
- E's credit below the panel stands, for measured contrast.
- Toolbar Close at ~42.6pt in partial-detent sheets is the platform's scaled detent. It becomes a device check, with no code change.
- B's receipt plate stays after the verdict, keeping D362/D387's first screen.
- The board's round story card takes §10.3's `.band` geometry on both clients: a feed story is the wire's case, and §10.3 names the board's three-stop wash as replaced.
- A2's course-first block is approved on both clients.
  - The order is noCard, then **noCourse** ("Add the course you played — its tee sets the rating and slope."), then noRating.
  - B writes the web half and E adds `PostCalc.Blocked.noCourse`.
  - E also twins B's held round ("Change setup" keeps the same round and its scores).
- AW2-05 (Home's lead says the clock twice) moves to B. It needs a copy-only home_dispatch patch, held for the owner's `db push` like `d30f1ecb`, plus both fallbacks.

**Verification at the merged head** (root's own simulator, CS-Claude-Root-17Pro `3CA82A3B`, never the owner's):
- **Native at `a27fbaf5`:**
  - build green;
  - package tests: 1374 Swift Testing and 16 XCTest;
  - app-hosted: 47 XCTest and 131 Swift Testing. The first attempt hit the known "runner hung before establishing connection", and a rerun passed.
  - **UI 57: 54 passed, 2 env-gated skips, 1 failure.** The failure is `N4ShellUITests` line 41, the test's own cleanup: a keyboard "search" key this simulator does not have. It failed 2 of 2, including on a warmed simulator. Every product assertion passes. E is hardening the cleanup.
- **Web at `c11199d7`:**
  - app-tests 503/0.
  - 42 of 43 browser suites green on the first pass. A run at `f61b96c9`, stopped when B's head landed, had finished 27 suites, all green.
  - **`round-record-browser.js` flaked under load.** It failed once at 1440 light, with the record 270 tall against its 210 cap. Of three reruns, two passed and one failed at 390 light (272).
  - A probe then rendered the card 16 times at `c11199d7` and 16 at `41a71fc6`. It measured 180–181 every time, with every font face loaded and identical child heights (id 32, title 43, story 22, foot 52). It did not reproduce.
  - Nothing root changed renders inside the feed card. It is recorded as a load-dependent flake to watch: both failures came while two other lanes' simulators and suites loaded the machine.
- **Heading sweep:** 31 of 154 renders skipped a level at `a27fbaf5`; 0 at `f61b96c9`. The same sweep found 0 unnamed decorative SVGs.
- preflight 0/0 at every commit.

**The native P3 cut (the owner, 2026-09-29 ~07:30: "go with your cut on the P3 tail").**

A's `N4-WORKLIST.md` (134 items: P1 6, P2 70, P3 58).
- **All six P1s are done.** E finishes every open P2 before the freeze, except N4-105, which is the owner's Q31.
- **P3s are kept when they touch accessibility, a sentence that misleads, a difference from the web (L-34), or an action with no undo:** 41 items, listed in root's message to E.
- **Cut, as known debt after launch (11):**
  - N4-004 (the Door headline's serif caps; also Q24);
  - N4-026 (the system-blue caret);
  - N4-031 (the share band's serif caps);
  - N4-032 (the ceremony dateline eyebrow);
  - N4-044 (the covenant's paragraph weights; its Charter half is done);
  - N4-066 (the request count in its label);
  - N4-074 (the album tile placeholder and full-size decodes: performance debt);
  - N4-117 (the Book's segmented pills);
  - N4-118 (the ordinals and figure column);
  - N4-180 (the rules head's two serif blocks);
  - N4-182 (the ledger sentence on several surfaces).
- **The web's queue is not cut.** B's AW2/DX2 list fits before the freeze.
- **TestFlight waits until the remaining items are done** (the owner, the same morning).

**Still the owner's:**
- Q31, the Oct 1 look (1335 turns Fall on Oct 1);
- X36–X40, Q1–Q39;
- database owed: X41, X42, the head-to-head week count, `d30f1ecb`, and AW2-05's patch once B writes it;
- counsel on "The pot".

## 4k · Pushing as batches land: the first web push, a red CI, root's AW2 batch, N4 checkpoint 1 (2026-09-29, morning)

On the owner's standing "push items as needed" (git push of verified heads to main; db push and functions stay the owner's; TestFlight waits).

**Web push 1: `60ad364e`, 07:40 MST.**
- 94 commits, a fast-forward from `7b9c17e4`, with `index.html` the only served file; no migrations, no generated Swift, no version lines.
- Verified first: the harness at `31299f43`, 1174 captures with 0 route failures, 0 errors, 0 fixture gaps and 0 page errors (served from a `git archive` snapshot); 43 browser suites at `c11199d7` (the round-record flake rerun 3 of 3 green on an idle machine); preflight 0/0.
- Live: `sw.js` VERSION `60ad364`, caption `v23 · 60ad364`.
- **CI went red:** Client invariants · unit files, `tests/rating.test.mjs`. Its hidden-control check searched the whole control string for `aria-hidden="true"`, and AW2-18 part 1 (`70af0c09`) had rightly hidden the drawn stars inside it. Root's verification had not run CI's `node --test` unit steps.
  - **`1131a4b0`** asks the question the test meant (the wrapper and its ten targets are exposed; every drawn star is a picture), mutation-checked. CI green, live `v23 · 1131a4b`.
  - **The gap is closed:** `tools/ci-local.py` in the gallery parses `ci.yml` and runs every step in a snapshot of the committed tree. It reproduced the red at `60ad364e` exactly, and every push since has run it first.

**Root's AW2 batch (web).**
- **AW2-16 (a) `5307dc20`:** the live match's "AVERY FIXTURE 1 UP" was said twice. The match card shows only when the scoreboard hero already carries its status line, so `#matchStatus` is `hidden` and the card keeps who and the terms. The phone already says it once (its match block, no hero): no twin.
- **AW2-16 (b), the desk You's five grosses twice, is Q40.** D291 (owner-authorised) keeps both the Form row and Recent rounds on the desk, so root does not remove either. Recommendation (b): drop the desk's Form row and move the best-of-five gold onto its Recent rounds row.
- **AW2-19 `b935f929` and `baf2358e`:** every remaining under-44 target keeps its drawn size inside a 44px hit box (the report flag, "The season's story", "Open", the rail's league switch, a course row's name, "best 90", the card leaf, the course note, and the golfer rows, whose face disc was a mouse-only second target). Measured with the round-2 probe's own `targets()`, then proven with `elementFromPoint` 2px inside every edge at 375 and 1280: nothing clipped, nothing over it.
  - The star rail: §16.2 makes its 24px halves legal only beside a −½/+½ pair at 44. The course lead's rail now has RateCourseSheet's pair, its glyphs and its bounds, with the rail at the sheet's 40. At a bound the button is `aria-disabled`, so a keyboard golfer keeps focus; a redraw returns focus to the same control. Driven end to end at 375 and 1280.
  - The phone's page rail has the same gap; its twin is a P3 for N4.
- **AW2-22 `98077497`:** the credential's third cell is "Best", with the course on its own agate line that wraps; no label is cut to an ellipsis. It is the phone's N4-050 shape, which N4 builds in checkpoint 2.
- **The Book's leader total is ink `5d9ba670`,** matching N4's build: §9.1 draws the leader's gold on the rank rail, and §2.4 gives gold only to what was won.
- **Verified at `5d9ba670`:** harness families play 72, golfers 40, desk 20, season 48, you 32, courses 32, book 64, all 0 failures; every pixel difference against `31299f43` is one of the changes above or ≤2-level text compositing; `ci-local` 11 of 11; preflight 0/0.

**N4 checkpoint 1 merged at `7afd9aeb`** (E at `a891eb8a`, 32 commits, all under `apps/ios/`): A's system sweeps, the N4-013/014/112/063 parts, N4-023/052/113, the W5 and W2 twins, "Change setup" holds the round, `noCourse`, and the N4Shell cleanup. E's proof: build; preflight 0/0; non-UI 1721/1721; UI 17 Pro 63/65 (2 environment skips), SE3 62/65 (one flake that passed alone). Ratchets lowered at `a8a39c2e`: LINT-03 11, 05 89, 06 1064, 07 100, 10 227, 12 33, 14 122.

**Root's rulings for N4 (none is a mechanic):**
- noRating moves like noCourse: its words under rating and slope, focus to the first empty field (finishes N4-020).
- The empty scoreboard keeps the phone's two-row drawing; the words match the web's (D234).
- N4-080 keeps "the in-app card is the export"; the shrink floors were the scope.
- N4-205 accepted: the phone's seat tap picks for a swap, so "(tap to change)" would lie there.
- N4-101 stays parked with DEC-01; X37's fixture names are the owner's.
- **Compete's empty head is Q41.** IA §6.1 says "Nothing running."; QB-21 moved the counted sentence into the head on the phone without amending IA. Root sends it to the owner (recommendation: amend IA to QB-21). The "Find golfers" door with no buddies is IA itself, so N4 adds it now.

**Tooling still open (root's), each waiting on its sites first:**
- Widening LINT-04 and check 15 to literal alphas and materials (N4-087): ten literal alphas remain in Swift, so a zero-tolerance check would fail today.
- N4-093's header grep: 21 `csType(.display)` sites without a header trait, most of them dev fixtures and the rest needing triage one by one.
- N4-091's LINT-18 probe widening.

**B's queue, three items handed to root (B: "take them", ~08:40).**
- **AW2-21 `7d9aa5c8`:** tee off sits at the foot of a long setup and the stage changes inside one view, so the round opened where the setup had been scrolled. From 845px down, the round rested at 313, with its context line and "Change setup" above the sticky header. Now tee off and "Back to the round" both rest at the round's top (`csLiveRest`). The board is never stuck at scrollY 0: `csLiveSticky`'s hysteresis could not release there, which also held the compact face for any golfer who scrolled back up. Measured at 375 and 402: the context line, "Change setup", the hole header and the hero are all clear; the board is unstuck with its chips. The card gate's Save band and the rail's fade were already in (B, wave 3).
- **AW2-23 `ba16d19d`:**
  - the star sweep animates a clip (`--fill`, same geometry), not a width;
  - no `will-change` held at rest on the Door's feed and leaderboard rows;
  - the full board's bar is on the flat ground (the header and tab bar are B's, in AW2-13);
  - the toast's dead `transition: all` is gone.
- **AW2-20 `8c9a9567`:** TP-20's 60ch reading measure holds from 640px, and the rules prose reads at the body-s size, 56ch, from 640px. The column itself is not capped, because 640–959 carries designed layouts (Play at ≥740, D152/D153; stats; events; the Door). Measured: ≤71 characters a line at 640, 768 and 1280, and the phone unchanged.
- **The 320 fit `acc22e54`:** the star stepper (`baf2358e`) made the You page scroll sideways by 24px at 320 (course-leaf-browser.mjs caught it at `5d9ba670`, 152/154). The rate control's star is now `min(40px, (100vw − 160px) / 5)`: 40 at 375 and on the desk, 32 at 320. **So `5d9ba670` was never pushed;** the batch goes out with the fix.

**Native verification of N4 checkpoint 1 on root's own simulator could not start:** "Unable to boot device due to insufficient system resources", with E's two phones running their UI sets. It runs when E reports its phones idle, and before any TestFlight regardless. Until then checkpoint 1 stands on E's proof.

**Root's answers to E for checkpoint 2 (none is a mechanic):**
- N4-208: `renderBylaws` is the one producer of the Pro's agreement; the phone levels `LeagueCopy.bylawsRows` to it and WizardAgreement's separate rows retire. The web doesn't move.
- N4-040: the phone's claim screen takes the Door's serif name, because the web's claim is a card on the Door, not a fifth lockup place. "Not now" goes to the plain Door; the claim stays pending and shows again on the next launch.
- The star-rail twin goes to N4 as a P3 with RateCourseSheet's pair.

## 5 · Coverage, detector, panel, critique, audit, human

Each of these is tracked in its own file as it fills: `COVERAGE.md`, `DETECTOR.md`, `PANEL.md`, `CRITIQUE.md`, `AUDIT.md`, `HUMAN.md`. Until a file exists and holds evidence, its gate is **open**. The starting points are:
- [BASELINE coverage](../BASELINE.md#full-requested-coverage)
- [detector-ledger.json](../detector-ledger.json), 214 candidates
- [HUMAN-TASK-SHEET](../HUMAN-TASK-SHEET.md), NOT RUN
