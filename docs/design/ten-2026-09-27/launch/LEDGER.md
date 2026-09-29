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

## 5 · Coverage, detector, panel, critique, audit, human

Each of these is tracked in its own file as it fills: `COVERAGE.md`, `DETECTOR.md`, `PANEL.md`, `CRITIQUE.md`, `AUDIT.md`, `HUMAN.md`. Until a file exists and holds evidence, its gate is **open**. The starting points are:
- [BASELINE coverage](../BASELINE.md#full-requested-coverage)
- [detector-ledger.json](../detector-ledger.json), 214 candidates
- [HUMAN-TASK-SHEET](../HUMAN-TASK-SHEET.md), NOT RUN
