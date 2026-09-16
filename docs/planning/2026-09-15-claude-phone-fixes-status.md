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
| F1 | Course card opens on your tee; Change tees; yardage row; strict tee identity | built (tee picker, YDS row on the record) | authored (`CourseWholeCardScreen`, `CourseCardLeaf`, `CourseSheetRef.tee/rating`, `WholeCardRef`) | web: `course-card-browser` (picker, change, YDS, plan tee, longest-said-as-such) | web preview · build 919 |
| F2 | Saved course · planned round · unfinished round · posted round, four sentences | built (`Available offline · saved today`) | authored (`savedLine`, Play cover *Unfinished round(s)*, live setup *Unfinished rounds*) | Kit `CourseBookTests` updated; web suite | web preview · build 919 |
| F3 | Plan block as a composition; worth line: ceiling, rule, arithmetic; nine-hole; merge only when contexts agree | built (`csPlanCourseHtml`, `csRoundWorthLine` + `csRoundCeiling`, merge) | authored (`ScheduledRoundSheet.planCourse`, `RoundWorth.line/ceiling/merged`, composer re-derives on 9/18 flip) | web: `counting-explained-browser` (four sentences + the nine), `app-tests` D364 block; Kit `RoundWorthTests`, `ReceiptLensesTests`, `ComposerWorthUITests` updated | web preview · build 919 |
| F4 | Routine ember off; the live signal ember on every look; same clash marked on Home and in the season room | already on `--act`; no change needed | authored (bag, digest, plan dots, form, first door, focus rings, date pickers → mut/act/ink; `CSStoryCard`/`CSDoor` live → brand; compact lead + clash head dot) | preflight incl. LINT-18 budget | web unchanged · build 919 |
| F5 | One applause action, count opens people, applause vocabulary, no menu | built (`applauseHtml`, people sheet, digest grouping, first-use toast) | authored (`Applause` Kit, `CSApplauseGlyph`, `ApplauseControl`, Home/board/context menu/VoiceOver, digest grouping) | web: `home-function-browser` (give, count, take back, failed write reverts), `round-record-browser`; Kit `ApplauseTests`; no-photo UI tests rewritten | web preview · build 919 |
| F6 | Pride bet says what it is (purpose, who, where, what decides, confirm, where it shows, no points); record-only honesty | built (`CS_PRIDE`, both lines in the composer) | authored (`ForfeitCopy` + both composers) | `app-tests` D366; Kit `ForfeitHomeTests` sweeps `ForfeitCopy.all` | web preview · build 919 |
| F7 | Play with Alex → Play a round (now / schedule) · Go head to head (review first) · Start a season; the person rides into each | built (`csAskTheLength`, `csAskRoundWhen`, `csOpenCalloutReview`, live preselect, wizard invitee, `csCalloutDefaultClose`) | authored (`CalloutLength` words, `PlayRoute`, `LengthStep` fork, `CalloutSheet` review, `LiveRoundStore.preselect/seat`, `WizardTarget.invitee`, `DeclarePrefill.tagPids`) | web: `play-with-browser` (three ways, fork, review order, Sunday rule, seating); `app-tests` R-F/D363 block; Kit `CalloutTests`; app `LivePreselectTests` | web preview · build 919 |
| F8 | Course search answers above the keyboard, on transitions only, every entry point | built (`csRevealSearch` on the three inputs, visual-viewport measured) | authored (`CourseSearchReveal` in live setup, plan composer, post composer, offline sheet) | web: `play-with-browser` §3 (a hidden answer is revealed; one in view is left alone) | web preview · build 919 |

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
| **TestFlight** | **Build 919 (`5be5fa0`), internal Owner group only** — `IN_BETA_TESTING`, read back twice. Build 905 (`714609b`) stands beside it as the earlier checkpoint. Friends is external, untouched, and still holds its same nine builds. |

## Decisions still open (proposals, not built)

`2026-09-15-applause-and-pride-proposals.md`:
1. Applause folded to one per golfer per **round** on the server, and the historical-token conversion (recommended: one applause per golfer per round with the earliest timestamp; rows kept; the backfill never notifies).
2. Grouped opt-in applause push: window, daily cap, undo, audience and mute rules. Nothing activated.
3. Pride agreements with a lifecycle (proposed → accepted/declined/cancelled → settled/disputed) and competition-backed settlement. The record-only composer stands and says so.

## Deployment order, from here

Steps 1 and 2 of the original plan are DONE: the licence is accepted, the
native half compiles clean, and build 919 is in the Owner group.

1. **Codex reviews** the candidate — the preview, the source, and this file.
2. **Restore the review simulator**: sign the iPhone 17 Pro simulator back in
   (an emailed code), then run `ComposerWorthUITests` and take the AX3 and
   keyboard-up native captures. This is the one verification gap.
3. **Web**: merge to `main` → Netlify; read back `#obCaption` and `sw.js`.
   No database push, no Edge deploy — there is nothing to push.
4. **Native, only if the review changes code**: `tools/ios-archive.sh --upload`,
   then attach to the internal Owner group. Use the internal-only attach, NOT
   `asc.py ship`, which targets Friends and submits for beta review.

## Physical-device checks, outstanding

Keyboard-up search reveal in Safari and in the app on a real phone (the visual-viewport measurement and SwiftUI's scroll inset are proven on the desk and by construction only); VoiceOver on the applause control and the people sheet; Dynamic Type AX3 on the review sheet, the whole card and the plan block; the live group with a preselected golfer end to end against a real account (fixtures only here — no invitations, rounds, reactions or applause were created on the owner's account).

## F9 – F13 · 2026-09-15, second pass (Claude)

Branch `claude/phone-fixes-2026-09-15`, PR #5. Every item below is paired web + iOS unless stated. Delivery states are at the end and are SEPARATE.

### F9 · the applause mark — DONE
Redrawn as two overlapping hands (front hand filled, back hand stroked, two sparks) after rendering candidates at 22, 34 and 110pt and looking; the old glyph read as a downward arrow. Same geometry on both clients. Captures: `f9-applause` (in-feed + enlarged).

### F11 · Scoreboard, option 2 — DONE
Ember identifies a COMPETITION in any state. `CompetitionState` / `CS_COMPETITION` produce Upcoming · Live · Final from the statuses the database already stores. `CSCompetitionBand` / `.cband`: one broad flat ember surface, dark ink, no gradient; leads Compete with the season being PLAYED (live with a standing first) and the list beneath no longer repeats it. Home carries the same competition by its key FAMILY, so a plain `plan:` round stays neutral. **`brand-ink` flips with the printing** (measured: fescue on dark ember 5.27:1 / cream 2.99:1; on light ember 2.74:1 / 5.76:1) — the board's single "dark ink" is right for one theme only. LINT-18 restated, not relaxed (probe + rule table): a band is ONE mark. The Compete fixture now honours `-cs_dev_text_size` (it was an overlay that bypassed the tab shell, so that screen had never been photographable at an accessibility size). D367 records F12; `spec/brand-canon.md` amendment is in D368's wording. Captures: native dark / light / AX3; web three states + neutral booked round + light + enlarged.

### F12 · finish → your round → Home — DONE on the clients; server link WRITTEN, NOT PUSHED
**Read-only evidence first:** the owner's round WAS posted (Bajamar, 82, 18 holes, played+created 2026-09-15, source live, not voided, exactly one round that day, 4 board posts, no photo). Nothing lost, nothing reposted. Three separate causes:
1. the recap said "Round posted" unconditionally → now the VIEWER's outcome (`RoundReconcile.status`: Round posted · Saved on this phone · Not posted + reason);
2. `finish_live_round` returns `{name, gross, holes}` with NO round id → the recap could never open your receipt. Now: **Your round** with View round and Add a photo (arms the receipt's OWN picker; library asked for only after the golfer chooses); the round is found from my rounds + this COURSE ID + this day, never a label; two candidates ask *Which round was this?*;
3. `scheduled_rounds` has NO completion column → the booking kept prompting. Now reconciled PER GOLFER client-side (`RoundReconcile.booking` / `csBookingPlayed`): the Home `plan:` item and the live-setup plan bridge stop prompting the golfer who played it; a host finishing never marks their guests. Home is refreshed from the CONFIRMED post (`sessionStore.reload()` / `loadHome()`).
**Migration `20261105090000_the_round_remembers_its_plan.sql`** (written, validated, NOT pushed): `live_rounds.scheduled_round_id` + `rounds.scheduled_round_id`; partial unique index = one live round per (booking, starter) — server-authoritative duplicate prevention for F10's "Tee it up"; `start_live_round(+p_scheduled_round)` and `finish_live_round` patched from `pg_get_functiondef` with every anchor asserted, and the finish payload now carries `round_id` + `profile_id` per posted card. Validated on a disposable cluster seeded with the REAL production bodies (fetched read-only): every anchor hit, patched plpgsql compiles, self-check passes, index refuses a second live round for the same booking+starter and allows a different golfer. Not a full-chain staging run (no Docker on this Mac).
Tests: `RoundReconcileTests` (12), `PlayedPlanOnHomeTests` (5), `tests/round-reconcile-browser.js`.

### F13 · birdie and eagle — PROTOTYPED on both clients
`HoleMoment` / `HoleMomentLedger` and `csHoleMoment` / `csMomentLedger`: the same refusals twice — par must be KNOWN (an estimated par claims nothing), the score must be COMMITTED (the phone fires at `nextHole()`, the existing advance boundary; the stepper persists every tap so it is never the trigger), hydration / reconnect / another phone's echo arm the ledger silently, a correction revises rather than replaying, gross not net, per golfer. Inline: a 2pt ember stroke + the word + "on N" under the hole header, eagle larger by size only, haptic distinct (eagle success, birdie medium), gone after 3.2s, next-hole target never covered; Reduce Motion honoured via `CSMotion`. Continued line is a TALLY (`1 eagle · 2 birdies`) — **"Heating up" deliberately NOT built** (needs the owner's definition, D368). D368 written BEFORE implementation. Hatch `-cs_dev_live -cs_dev_moment birdie|eagle` drives the REAL advance path. Tests: `HoleMomentTests` (8), `tests/hole-moment-browser.js`. Captures: native birdie / eagle / AX3; web ordinary · birdie · eagle · estimated par.
Not yet: the tally in the final receipt; shared-scoring device test with two phones.

### F10 · "View round" / "Tee it up" — PARTIAL
Server side is in the F12 migration above (booking link + duplicate prevention). NOT done: the client "Tee it up" door from the booked-round sheet into prepared live setup, and retiring "Open the plan" (needs a `home_dispatch` patch; the decision-log:5029 rejection of the name must be read and superseded in writing first).

### Codex release review R1–R7 (docs/reviews/2026-09-15-finish-loop-release-review.md) — CLOSED
- **R1** web recap doors go through `csOpenPostedRound` (fetch-by-id, never a cache that may not hold the round); "Add a photo" opens the SAME receipt with its own `rcptPhotoBtn` scrolled into view and focused — no timed click, no picker outside the golfer's tap. Test: `tests/round-reconcile-browser.js`; capture `f12-recap-web`.
- **R2** `CS_MY_ROUNDS` keyed by account+day, invalidated on finish (`csInvalidateMyRounds`), late/other-account responses discarded, failed or signed-out read = UNKNOWN (never empty); `CS_PLAYED_PLANS` recomputed per load. Browser test asserts unknown never hides a booking.
- **R3** `RoundReconcile.status` / `csSaveStatus` decide by PROFILE ID; finish payload now carries `round_id`+`profile_id` (posted) and `profile_id` (skipped); an identity-less payload is **Not confirmed yet** until one authoritative match. Tests: duplicate name, someone else's post, missing identity, skipped viewer (Kit 6 + web).
- **R4** index is `(scheduled_round_id) where status='live'` — one live round per BOOKING; `start_live_round_from_plan` is a NEW fully specified function: validates booking + caller (host or tagged, not declined) BEFORE any write; JOIN returns the standing round (`joined:true`); the concurrent loser is handed the winner's round; `start_live_round` untouched. Every anchor COUNT asserted. Validator: 27 PASS including refusals-write-nothing and the race.
- **R5** competing bookings (one round, two plans, same course+day) are never dropped — Kit test + web prime logic.
- **R6** contract rows for `start_live_round_from_plan` and `round_tally` written to the snapshot query's exact shape and verified row-for-row against the disposable cluster; `start_live_round` row unchanged. Both "Tee it up" doors built (phone `ScheduledRoundSheet` → `LiveRoundStore.prepare(from:)` → `startFromPlan`; web `rtTeeUp` → `csTeeUpFromPlan` → `start_live_round_from_plan`, skew-safe). "View round" in `home_dispatch`, `HomeFallbackItems`, fixture. Receipt tally via `round_tally` on both clients. D367 addendum records the "Tee it up" distinction (roster closure ≠ booked round).
- **R7** the corrected candidate is archived at ITS commit with the number the helper computes (below). Build 928 is not shipped.

### Delivery states (separate)
- **Database:** `20261105090000_the_round_remembers_its_plan.sql` — rewritten per R3/R4/R6, validated (27 PASS) on a disposable cluster seeded with the real production bodies of `finish_live_round` and `home_dispatch` plus a signature-exact stub of `start_live_round`; `supabase db push --linked --dry-run` lists exactly this file. **NOT pushed** (the push is refused to this session by the permission classifier; the owner runs `supabase db push --linked`). Not a full-chain staging run — no Docker on this Mac.
- **Edge:** nothing.
- **Web:** branch / PR #5 preview; not promoted.
- **TestFlight:** the corrected candidate is **build 930 from commit d5ea192**, archived, signed and exported locally at `apps/ios/build/archive/run-930-d5ea192.exJH3i/export/Cup Season.ipa`. NOT uploaded (the upload is refused to this session by the permission classifier). The owner uploads THAT exact IPA with the altool line in `tools/ios-archive.sh` — or re-runs `tools/ios-archive.sh --upload` on commit d5ea192, which produces the same number — then attaches to the internal Owner group only. Build 928 is not shipped. Friends untouched.
- Kit 1217 tests / 197 suites; app target 100 / 19; preflight clean; 9 web suites incl. `round-reconcile` and `hole-moment`.
