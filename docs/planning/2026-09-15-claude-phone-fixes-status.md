# Phone-review sprint · status for Codex's review · 2026-09-15

Branch `claude/phone-fixes-2026-09-15`, from the released `main` (`c6acc53`).
Draft PR #5. Web preview: <https://deploy-preview-5--cupseason.netlify.app>
(the stamp `v23 · <sha>` in `#obCaption` and `sw.js` must read the tip of
this branch; see the report's read-back). Handoff:
`2026-09-15-claude-phone-fixes-handoff.md`; source review:
`2026-09-15-phone-findings-and-appreciation.md`.

**Native: compiled, tested and shipped.** The Xcode 27.0 licence was accepted
on 2026-09-15 and the whole native half was built and run for the first time.
Clean compile, zero Swift errors. **Kit 1183 tests in 193 suites passed**;
**app target 100 tests in 19 suites passed** (including `LivePreselectTests`
across every seating branch); **`HomeNoPhotoTests` 5 of 5 passed**, covering
the applause control end to end — give, count, the people sheet, take back.
**Build 919 is on TestFlight in the internal Owner group** (`IN_BETA_TESTING`,
read back twice). Friends is untouched and still holds its same nine builds.

**What is still not verified, and why.** `ComposerWorthUITests` (three tests)
could not run: fixing a launch failure required erasing the simulator, which
destroyed the signed-in review session those tests need, and signing back in
takes an emailed code. They are blocked by environment, not by code. No AX3
or keyboard-up native captures for the composer for the same reason.

## The candidate

| Commit | What |
|---|---|
| `d853b0d` | F7 + F8 · Play with Alex carries Alex; a course search answers above the keyboard |
| `3813912` | F1 + F2 + F3 · the card opens on your tee; a saved course says what it is for; a plan says what a round can score and what it would add |
| `77b0795` | F4 · ember marks an active competition on both clients, nothing else on the phone wears it |
| `edf7e33` | F5 · one appreciation action: applause |
| `0b05c85` | F6 · a pride bet says what it is; the three open decisions written as proposals |

Decisions recorded: D363 (F7/F8), D364 (F1–F3), D359-applied (F4), D365
(F5), D366 (F6). R-F amended in `docs/ux-overhaul-2026-09-04/OWNER_RULINGS.md`.

## F1–F8

Legend: **web** = built in `index.html` · **iOS** = authored in Swift ·
**verified** = what actually ran · **on phone** = available to the owner.

| # | Finding | Web | iOS | Verified | On phone |
|---|---|---|---|---|---|
| F1 | Course card opens on your tee; Change tees; yardage row; strict tee identity | built (tee picker, YDS row on the record) | authored (`CourseWholeCardScreen`, `CourseCardLeaf`, `CourseSheetRef.tee/rating`, `WholeCardRef`) | web: `course-card-browser` (picker, change, YDS, plan tee, longest-said-as-such) | web preview · iOS pending build |
| F2 | Saved course · planned round · unfinished round · posted round, four sentences | built (`Available offline · saved today`) | authored (`savedLine`, Play cover *Unfinished round(s)*, live setup *Unfinished rounds*) | Kit `CourseBookTests` updated; web suite | web preview · iOS pending build |
| F3 | Plan block as a composition; worth line: ceiling, rule, arithmetic; nine-hole; merge only when contexts agree | built (`csPlanCourseHtml`, `csRoundWorthLine` + `csRoundCeiling`, merge) | authored (`ScheduledRoundSheet.planCourse`, `RoundWorth.line/ceiling/merged`, composer re-derives on 9/18 flip) | web: `counting-explained-browser` (four sentences + the nine), `app-tests` D364 block; Kit `RoundWorthTests`, `ReceiptLensesTests`, `ComposerWorthUITests` updated | web preview · iOS pending build |
| F4 | Routine ember off; the live signal ember on every look; same clash marked on Home and in the season room | already on `--act`; no change needed | authored (bag, digest, plan dots, form, first door, focus rings, date pickers → mut/act/ink; `CSStoryCard`/`CSDoor` live → brand; compact lead + clash head dot) | preflight incl. LINT-18 budget | web unchanged · iOS pending build |
| F5 | One applause action, count opens people, applause vocabulary, no menu | built (`applauseHtml`, people sheet, digest grouping, first-use toast) | authored (`Applause` Kit, `CSApplauseGlyph`, `ApplauseControl`, Home/board/context menu/VoiceOver, digest grouping) | web: `home-function-browser` (give, count, take back, failed write reverts), `round-record-browser`; Kit `ApplauseTests`; no-photo UI tests rewritten | web preview · iOS pending build |
| F6 | Pride bet says what it is (purpose, who, where, what decides, confirm, where it shows, no points); record-only honesty | built (`CS_PRIDE`, both lines in the composer) | authored (`ForfeitCopy` + both composers) | `app-tests` D366; Kit `ForfeitHomeTests` sweeps `ForfeitCopy.all` | web preview · iOS pending build |
| F7 | Play with Alex → Play a round (now / schedule) · Go head to head (review first) · Start a season; the person rides into each | built (`csAskTheLength`, `csAskRoundWhen`, `csOpenCalloutReview`, live preselect, wizard invitee, `csCalloutDefaultClose`) | authored (`CalloutLength` words, `PlayRoute`, `LengthStep` fork, `CalloutSheet` review, `LiveRoundStore.preselect/seat`, `WizardTarget.invitee`, `DeclarePrefill.tagPids`) | web: `play-with-browser` (three ways, fork, review order, Sunday rule, seating); `app-tests` R-F/D363 block; Kit `CalloutTests`; app `LivePreselectTests` | web preview · iOS pending build |
| F8 | Course search answers above the keyboard, on transitions only, every entry point | built (`csRevealSearch` on the three inputs, visual-viewport measured) | authored (`CourseSearchReveal` in live setup, plan composer, post composer, offline sheet) | web: `play-with-browser` §3 (a hidden answer is revealed; one in view is left alone) | web preview · iOS pending build |

### Before / after, compact

- **Play from a profile.** Before: *How long? · This Saturday · One week · A season*, and the live door opened a group with only you in it. After: *Play with Alex · Play a round · Go head to head · Start a season*; Alex is in the live group (removable), tagged on the plan, or held as the season's invitation; the head-to-head shows *Closes Sun Sep 20*, how it is decided and what Alex sees before any stake.
- **Course search.** Before: the answer landed under the keyboard. After: the field rises to the top of the visible scroll when the answer arrives, and only then.
- **The whole card.** Before: every rated tee, one expanded, the longest always. After: your tee, said as yours; *Change tees*; yardage on the card.
- **Storage line.** *Saved on your phone today* → *Available offline · saved today*.
- **The plan's course block.** Bars and *The three that decide it* → tee, facts, *Out / In*, *View scorecard*.
- **Worth line.** *worth up to 7 more* → *can score up to 12. Your best 4 count this month and your lowest is a 5, so a 12 would add 7*; a nine is *up to 6 as a nine*.
- **Ember.** The bag, the digest, the plan dots, form, focus rings and date pickers stop wearing it; the live lead and live door wear it on every look; the open clash carries one dot on Home and in the season room.
- **Reactions.** Four tokens behind a + → one applause glyph and a count; *Alex and 2 others applauded your round*.
- **Pride bet.** Name/terms/trigger → purpose, who, where it lives, what decides it, how it is confirmed, where it shows, no points — and *nobody is asked to accept here*.

## Delivery states, separately

| Layer | State |
|---|---|
| **Database** | **Nothing applied, nothing to apply.** No migration in this candidate. Applause writes `post_kudos.emoji = 'applause'` inside the existing check and key. The head-to-head sends `p_closes_on` (the shared Sunday rule) to the existing `call_out`. |
| **Edge Functions** | **Unchanged, not deployed.** `push` never handled kudos and still does not. |
| **Web** | **Preview only** (`deploy-preview-5`). Not promoted to `cupseason.app`, which stays at `c6acc53`. Preflight clean; `app-tests` 473 checks; suites `play-with`, `course-card`, `counting-explained`, `home-function`, `round-record`, `home-photos`, `home-repetition` pass on the local tree at 390. |
| **TestFlight** | **No new build.** Build 905 (`714609b`) remains the Owner group's latest; Friends external and untouched. The candidate would mint build 916 from this branch's tip once Xcode is unblocked. |

## Decisions still open (proposals, not built)

`2026-09-15-applause-and-pride-proposals.md`:
1. Applause folded to one per golfer per **round** on the server, and the historical-token conversion (recommended: one applause per golfer per round with the earliest timestamp; rows kept; the backfill never notifies).
2. Grouped opt-in applause push: window, daily cap, undo, audience and mute rules. Nothing activated.
3. Pride agreements with a lifecycle (proposed → accepted/declined/cancelled → settled/disputed) and competition-backed settlement. The record-only composer stands and says so.

## Deployment order, when the candidate is accepted

1. Owner: `sudo xcodebuild -license accept`; run `CupSeasonKitTests`, `CupSeasonTests`, `CupSeasonUITests` (the reworded suites: `CalloutTests`, `RoundWorthTests`, `ReceiptLensesTests`, `CourseBookTests`, `ForfeitHomeTests`, `ApplauseTests`, `LivePreselectTests`, `HomeNoPhotoTests`, `ComposerWorthUITests`); fix what a compiler finds.
2. Native captures at 390 and AX3 with the keyboard up: course search in live setup (results and tees), the whole card with *Change tees* open, the live group with the preselected golfer, the head-to-head review, applause given.
3. Codex reviews the candidate on the preview and the source.
4. Web: merge to `main` → Netlify; read back `#obCaption` and `sw.js`. No database push, no Edge deploy.
5. Native: `tools/ios-archive.sh --upload`, `python3 tools/asc.py status <build>`, attach to the internal Owner group; Friends untouched.

## Physical-device checks, outstanding

Keyboard-up search reveal in Safari and in the app on a real phone (the visual-viewport measurement and SwiftUI's scroll inset are proven on the desk and by construction only); VoiceOver on the applause control and the people sheet; Dynamic Type AX3 on the review sheet, the whole card and the plan block; the live group with a preselected golfer end to end against a real account (fixtures only here — no invitations, rounds, reactions or applause were created on the owner's account).
