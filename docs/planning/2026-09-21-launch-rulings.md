# Owner rulings on the launch decision points — 2026-09-21

The fourteen decision points in `spec/launch-readiness-2026-10-01.md` §4C were
presented with options on 2026-09-21 and ruled the same day. This packet is the
record until the entries below are appended to `spec/decision-log.md`: PR #6
carries D363–D369 and is not yet merged, and D370 is Codex's, on the Mac, so
**D371–D379 are reserved here** and go into the log at integration, after the
merge, in this order. Format is the hierarchy-of-truth one (rule 5); a CONFLICT
line is named wherever a ruling collides with a higher level.

| # | Decision point | Ruling |
|---|---|---|
| 0 | Launch shape | **B — public.** App Store submission on Oct 1, open outreach the same day |
| 1 | Push and merge | **B** — push the revokes now, merge by Mon 21 17:00 Phoenix with or without Codex |
| 2 | Friends gate | **A** — every row of `owner-checks.md` PASS, no known-issues shortcut |
| 3 | Allowance gloss | **A** — yes |
| 4 | Unclaimable link | **A** — say the true thing, both doors, client-only |
| 5 | Season two | **A** — the covenant again, a recorded yes |
| 6 | Adjustment pen | **A, built before Oct 1** |
| 7 | Email invitations | **B** — link and code only |
| 8 | Presidents Cup week | **B** — let it go |
| 9 | Legal set | founder v2 before submission; counsel engaged now |
| 10 | Stage C install path | **A** — TestFlight public link |
| 11 | Competition lifecycle at D→E | **A** — a Ryder or Major counts; moot while free |
| 12 | Gates file | ratify, amended to the ruling on 0 |
| 14 | Store date | **Oct 1 is the submission date** |
| D | Stage D mechanics cluster | **address every item** |

---

## D371 · October 1 is the public launch: submitted to App Review that day, outreach open, a public TestFlight link in the meantime

**OWNER-RULED 2026-09-21** · launch-shape level (vision / IA) · CONFLICT named

- **Current mechanic.** The pilot's *proposed* gates (`docs/pilot/gates-and-stop-conditions.md`, headed "for the owner to ratify") open a capped public cohort only after Stage D: one full competition lifecycle by a group the founder is not in, and the paid offer put to five organizers. The readiness audit's §0 recommended the staged launch and called a cold public launch "not to be attempted".
- **Problem.** The owner's date is a public one. Waiting on a Stage D lifecycle puts the public door in late October or winter. Nothing is sold (D183), so the submission risks a review cycle, not a customer.
- **Recommendation (ruled).** Submit to App Review on **2026-10-01** (ruling 14). Begin open outreach the same day; until Apple approves, the phone door for strangers is a **TestFlight public link** (ruling 10) and the web door is what it is today. The r/golf founder post waits for the store link — it is the one shot at that audience. Stages A–D stay as the *measurement* frame; the **stop conditions stay in force** and pause outreach if one fires. The gates file is ratified amended (ruling 12): E is opened by this ruling, its stale A→B line corrected (`20261106`/`20261107` are applied), and the paid-offer clause of D→E becomes the gate for the *paid* stage only. A Ryder or a Major counts as a lifecycle (ruling 11).
- **Principle served.** A date the founder can say to people; the five-question filter's "does this encourage golfers to return" — a real audience before the season-ending months.
- **Benefit.** Strangers on the real product while Phoenix's golf year is turning; the timed comprehension gates finally get run on people who do not know the founder.
- **Tradeoffs.** Strangers meet a build whose two-phone checks are being run this same week; the legal set must be v2 before submission (D379); rate limiting on the anon surface is now required before outreach (D378) and `rate_limit_otp` must be read and set (D186); one Apple rejection cycle should be assumed (5.3.4 on the pot, 2.1 on an empty reviewer state), so the store goes live when Apple says, not on the 1st.
- **CONFLICT.** With the proposed D→E gate and with the readiness audit's verdict. Resolved by the owner at the vision level: the date is set, the gates measure, the stop conditions decide.
- **Forcing dates.** Submission Oct 1. Live when approved. The Stage E App Store date is hereby logged (ruling 14) so it cannot slip silently a third time (D186 and D194 each reasoned from a September date that passed unrecorded).

## D372 · The merge and the Friends gate

**OWNER-RULED 2026-09-21** (rulings 1-B, 2-A) · process level · no mechanic

- Push `20261109090000` and `20261110090000` **now**, from the PR #6 checkout (a push from `main` fails: 243 files against production's 246). Both are zero-client-dependency and self-checking.
- Merge PR #6 by **Mon 2026-09-21 17:00 America/Phoenix**, with or without Codex's review, after the owner walks the PR #6 Netlify preview on an iPhone in Safari: sign in · the Play-with fork · course search with the keyboard up · post a round and read the recap's outcome line. This overrides the 09-13 "Codex integrates" ownership row for this one merge; Codex's late findings become a narrow follow-up on `main`; any change to `20261110`'s scope is a NEW narrowing migration (rule 2). PR #5 closes as subsumed. Rollback is a Netlify redeploy of `c6acc53`.
- Friends receive a build only after **every** row of `docs/pilot/owner-checks.md` (A1–A11, R1–R7, G1–G2) is PASS on that build. A FAIL is fixed and the failed rows re-run; there is no known-issues shortcut. Beta App Review is submitted on the same version string — `MARKETING_VERSION` stays 1.0.0, which is what lets it auto-approve (`tools/asc.py`).

## D373 · The allowance is explained where a golfer first meets it

**OWNER-RULED 2026-09-21** (ruling 3-A) · UI/copy level · no dial (D8/D48), no term (preflight lint 3)

- **Current mechanic.** The covenant clause, the wizard agreement row and the wizard info show "95 percent of your index" and nothing about what that does; the founder did not retain it; comprehension graded C.
- **Recommendation (ruled).** One clause per client in R-M's sanctioned shape — *scored against your playing HCP, your index at ninety-five percent* — used by the wizard info bubble (with the worked example: *Your index is 10.6. This league plays 95%, so your playing HCP here is 10.1*), the wizard agreement row (the phone's "of your handicap" becomes "of your index"), the covenant clause and the bylaw row. A web pin beside `tests/app-tests.js:1355`, the Swift pins updated, lints 3/42/43 run. Its own small commit on `main` after the merge; the phone half before the next archive. The personal figure is held as a conditional second sentence only when an established index exists (L-44, D124).
- **Principle served.** L-32 (say what the door does); §16; R-M (the two handicap nouns distinguished once, at first contact).
- **Files.** `index.html:5002, :21238, :26698`; `WizardState.swift:563`; `LeagueSetup.swift:57`; `JoinLeague.swift:230`; `LeagueCopy.swift:136`.

## D374 · A link from a round nobody finished says so, on both doors; the pencil stays

**OWNER-RULED 2026-09-21** (ruling 4-A) · UI level · D85/D87/D107 upheld · no change to the anon surface

- **Current mechanic.** 55 of 70 guest seats ever minted sit in live rounds that never finished. Their links land on the signed-out door as "expired or already claimed". A guest who then made an account is told "they're still out there", forever — `claim_round` raises *Round is still live* for any non-final status.
- **Problem.** The first sentence a stranger reads from the product is false, and the B→C gate's "told how" clause cannot pass.
- **Recommendation (ruled).** Both clients read the round's status from `guest_live_state` — already returned, no new endpoint — before falling through. `abandoned` → *This round was never finished, so there's no card to keep. Whoever ran it can tee off again and send your link from the new round.* and the token is dropped. `setup` → *hasn't started yet*, token kept. `live` keeps D86's early claim. The signed-in claim path (`claimPendingRound`, `ClaimFlow.consume`) makes the same read before `claim_round`. One producer per client (D297). No migration. "Stop minting" is rejected: the link is minted at seat time because it is the guest's pencil.
- **Principle served.** L-44 (unknown stays unknown); the door tells the truth.
- **Follow-ups filed.** A D296-style migration so `claim_round`'s raise stops saying "still live" for an abandoned round; who may finish a league-less round (`owner-checks.md:56`).
- **Files.** `index.html:30187–30190, :30050`; `LiveRoundHost.swift:190–220`; `LiveClaim.swift:41–125`.

## D375 · Season two is a re-up: the covenant again, and a recorded yes

**OWNER-RULED 2026-09-21** (ruling 5-A) · MECHANIC level · AMENDS D243 · restores spec §14.5 · built in October, before the first staked run-back

- **Current mechanic.** `run_it_back` (`20260928093000`, live body re-emitted in `20261012090000:126–287`, **applied**) re-seats every living member as a count, carries the terms locked and draws squads at once; the covenant re-fires only on a changed stake or length and is unreachable because neither client sends them; the copy says "N of you are on it"; no `agreed_at` exists.
- **Problem.** A second season re-attaches stake × roster to the ledger with no yes on record. L-12 says every join passes the covenant. Spec §14.5 says *bylaws carry forward unlocked, fresh draw — the re-up moment is the renewal moment*; D243 departed from it without a CONFLICT line.
- **Recommendation (ruled).** `run_it_back` returns the league to `setup` with the terms carried; the existing lock door does the rest — D346's agreement, D111's `lock_league`, invitations, the covenant on accept carrying last season's finish, `form_squads` at lock. `league_members.agreed_at` + `agreed_season` are written per member per season; `v_rounds_ranked`, `close_month`'s floors and the pot's owed number gain the agreed predicate for seasons > 1; the Pro's screen counts yeses. **Now,** before the next build: the copy stops claiming an opt-in on both clients ("carried over", not "on it"; the step-out door named), `already_running`'s unfiltered seated count is fixed, and the three stale "unpushed" claims are corrected.
- **Principle served.** §14.5; L-12; D351 (nobody owes a stake they did not see).
- **Benefit.** Season two is a join with a memory, not a schema fact.
- **Tradeoffs.** One more tap per member; about a week of work with a phone half, so it is scheduled for October after launch week. Forcing date: the first *staked* run-back — Fellas wraps 2027-01-18 by the documented dates; the owner confirms nothing staked wraps earlier with the read-only query.
- **CONFLICT.** With D243 as built (locked carry, immediate draw). Resolved upward by §14.5.

## D376 · The Pro's pen: `adjust_points`, the ledger read everywhere, the Final refuses

**OWNER-RULED 2026-09-21** (ruling 6-A, *built before Oct 1*) · MECHANIC level · amends spec §9's wording · builds the mechanism D50 assumed

- **Current mechanic.** Nothing but the engine writes `season_adjustments` (`close_month`, `set_member_bye`, the wizard defaults, `start_season`); `rounds.voided` has no writer; `commissioner_log` is written by eight RPCs and read by no client; `v_individual_standings` reads no adjustments; `cup_final_race` reads none; `delete_round` is owner-only. §9 says "void/edit any round, every override logged"; §16 says adjustments live in a ledger with reasons; CLAUDE.md says rounds are immutable.
- **Problem.** A disputed score in a real-money league has a ledger with reasons and nobody who can write one. A bare RPC would move nothing in a solo league (the only kind real leagues are, D205) and nothing in a Final.
- **Recommendation (ruled).** ONE migration, three parts. **(1)** `adjust_points(p_season uuid, p_member uuid, p_delta int, p_reason text)`: SECURITY DEFINER; `is_commissioner`; the member seated in the season resolved through `league_members`/`seasons`, never through `squads`; `squad_id` set when one exists, else null; reason required and length-capped; |delta| capped; `kind = 'override'`; `created_by = my_member_id()`; one natural-case `system` board post (D165; model `20260831120000:1797–1836`); a `commissioner_log` row; `revoke … from public, anon` + `grant execute … to authenticated`; refuses while `seasons.status in ('cup_final','complete')`. **(2)** `v_individual_standings` redefined with a member-keyed adjustments CTE so a solo ruling reaches the total, the King and `league_pulse`; columns unchanged; a `tests/db-checks.sql` row asserting both standings views sum the ledger. **(3)** The Cup Final: refuse and say so, with the covenant sentence *a ruling in the Final is settled by the crew*. Round-level void stays with D125 stage 2; `delete_round` stays owner-only (D125, D284). Web: a Pro sheet beside the Bye button (`index.html:29211`); phone: `MembersSheet` / `LeagueRoomModel`, on the Mac. Spec §9 amended from "void/edit any round" to "adjust the points, in the ledger, with a reason, league-scoped". D50's covenant paragraph ships as the copy half.
- **Principle served.** §16; rule 4 ("everything shows its work"); D50 ("every ruling is a logged entry with a reason, visible to the whole league").
- **Benefit.** The standings and the crew agree, on the record; a wrong ruling is corrected by another row (D43).
- **Tradeoffs.** Three to four working days inside launch week; the phone half is Mac time; "done" means both halves (D234) — if the phone half misses the Oct 1 build, the desk carries the pen and the phone follows in the next build, and the release record says so.

## D377 · The invitation is the link and the code; email is not a player channel

**OWNER-RULED 2026-09-21** (ruling 7-B) · IA level · retires the email fallback D97 kept

- **Current mechanic.** `lockBylaws`' pre-D111 direct-write fallback (`index.html:26287–26402`) inserts `invites` rows that no function mails; two "Invites out" readers print nothing; the table has held zero rows, ever.
- **Recommendation (ruled).** The league invitation is the `?join=CODE` link and the code, carried by D114's Copy message. Built **after the Friends gate**, in one commit that does nothing else: delete the whole fallback, the `state.emails` plumbing and both readers (web `:29190–29196, :29219–29222`; iOS `LeagueRoomModel.swift:519–524`, `MembersSheet.swift:31–34, 48`) — the iOS half on the first build after the Beta App Review build, never on it. `drop table public.invites` in a Q1 migration (both readers swallow errors; order is free). A Pro-facing email sequence (gtm §9) is its own future decision.
- **Principle served.** D97's false-map rule; "low friction wins".

## D378 · The Stage D cluster, brought forward — every item dispositioned, one bundle before Oct 1

**OWNER-RULED 2026-09-21** ("address all items") · MECHANIC level · bodies copied from their latest definitions with a D144-style self-check · plus the rate limits D371 requires

- **(i) Attendance over skill.** The bands **stay** for season one — a decision, recorded: §2.2's bands and the cap-3 default (D142) are unchanged; the counting cap is the Pro's lever; revisit at the first month close of a non-founder competition league, on real data.
- **(ii) Verification dial.** **Closed** as a stated norm. M-15 is verbatim on both clients (*Verification is a norm the league holds, not a filter Cup Season applies*); the server covenant carries no attested/GHIN text; `attested` never flips from a partner's confirm (D125a, D239/L-19). Nothing built.
- **(iii) Leavers keep write access.** `is_active_member(p_league)` — member AND `left_at IS NULL` AND `suspended_at IS NULL` — swapped into the consequential **write** paths only: `create_major`, event creation and entry, callouts, plan RPCs. Never inside `is_league_member` or `my_member_id` (D197 ruling 1 keeps READ; D244 keeps the name and the rounds).
- **(iv) Solo lock at one.** **Struck** — D205's ruling; not a defect.
- **(v) Snake and live drafts.** `lock_league` refuses `p_draft_type in ('snake','live')` with one sentence; the engine and `DraftNightScreen` stay dormant for D54.
- **(vi) UTC in the Final.** `(now() at time zone se.timezone)::date` replaces `current_date` in `daily_season_tick`, `enter_cup_final` and `cup_final_race.days_left` (D344 is the precedent; `seasons.timezone` exists, default America/Phoenix).
- **(vii) Sunday snapshots.** `snapshot_week` takes a league-local week number and rides the tick's existing rollover branch; `cron.unschedule('cs-week-snapshot')`; `home_dispatch`'s hard-coded "since Sunday" made honest.
- **Required by D371's public door.** Rate limiting on the anon surface: an attempt ledger on `league_by_code` (deferred by `20260714040000`), caps on `log_growth_event` and the `guest_live_*` trio; and `rate_limit_otp` read and set before the first stranger (D186).
- **Principle served.** §14.0, §16, D197 ruling 1.
- **Tradeoffs.** Two to three days of migration work in launch week, validated on the Mac sandbox (`tests/sim/sandbox/apply.sh`), never "dry-run" against the linked project (first landmine).

## D379 · The legal set, v2 before submission; counsel engaged now

**OWNER-RULED 2026-09-21** (ruling 9) · legal/ops level · D197 ruling 3 kept as ruled

- **Recommendation (ruled).** A founder-written v2 of `legal/privacy-policy.md`, `terms-of-service.md`, `pot-disclaimer.md` and `legal.html` before Oct 1, carrying: a minimum-age sentence (13+, matching the rating; 18+ for a season with a buy-in flagged as a counsel question); the operator named as **Fischbeck3 LLC** if the owner confirms (it already signs the app); the five vendors and their roles (Supabase, Brevo, Netlify, GolfCourseAPI, Anthropic for the scan); a contacts paragraph copied from D251's consent sentence; deletion described as in-app plus one retention sentence; *Apple is not a sponsor of any league or pot*; one money posture in D39's ledger language — `legal.html:82` "takes no fee or cut" kept as present-tense fact or dropped, owner's call, recorded; a new Last Updated. Same commit: the Contacts label reconciled one way across `app-store-listing.md` §7, D251(4) and `PrivacyInfo.xcprivacy`; `app-review-notes.md` brought to D183 with a real password and a walkthrough league whose season is running; `appstore-runbook.md:131` and `appstore-launch-kit.md:40–41` from 4+ to 13+.
- **Counsel.** Engaged **now**, asynchronously, with a briefing packet (D39, D183, D184, D192, D201, the v2 drafts, the LLC question) and a fixed-fee scope requested; reviews the v2, not the July stub. Off the critical path.
- **D197 ruling 3.** The age gate and the terms record (attestation/DOB, `terms_version`/`accepted_at`, one migration, both sign-in doors) are built first thing after submission, as ruled.

## Socials (ruling 8-B) — not a decision entry

Let the Presidents Cup week go: no brand posts, no PIGL Ryder this week (the Ryder is Sunday-anchored and resolves weekly; "daily duel results" never existed). Re-key `spec/socials-operating-plan.md` to the pilot stages and D371's date; claim the @cupseason handles in one quiet half hour (claiming is not posting); PIGL's own moments go out in the founder's own voice only; the brand's first post is keyed to the store link. D46: marketing is never a mechanic dependency.

---

## How these land

1. This packet is the record today. After PR #6 merges, D371–D379 are appended to `spec/decision-log.md` verbatim, after D370.
2. Spec amendments owed with them: §9 (the pen's wording), §14.5 cited by D375, §3.2 and §14.1 prose (already stale, noted in the audit).
3. `docs/pilot/gates-and-stop-conditions.md` amended per D371 and ratified at the Sep 29 review. `docs/planning/ACTIVE_WORK.md` corrected (`20261024` applied; the `index.html` ownership row; the Codex-late override).
4. The build order and dates are in `spec/launch-readiness-2026-10-01.md` §4A, re-sequenced to these rulings.
5. **Built 2026-09-21, remote:** `20261112090000_the_stage_d_cluster_before_the_door_opens.sql` (D378), `20261113090000_the_pros_pen.sql` (D376), `20261114090000_the_door_keeps_count.sql` (D371's throttle). Every function change is an in-place patch of the live definition (`pg_get_functiondef` → asserted replace → execute; the 20261102090000 pattern), idempotent on a second run. Validated on a Postgres 16 sandbox running PR #6's full 251-file chain (the harness's PG17 `MAINTAIN` privilege filtered from the stream; production is 17) with 18 functional probes. `tests/db-checks.sql` gains 35 (the pen reaches the table) and 36 (the bundle and the counter hold); check 1 now expects three cron jobs. Contract rows for `adjust_points`, `is_active_member`, `_door_gate`; `rpc.ts` and `Rpc.swift` regenerated. **Not pushed; Codex review first.**
6. **Web halves built 2026-09-21** (index.html, on top of PR #6's tree): D373 — the wizard info bubble, the agreement row and the covenant clause say *scored against your playing HCP — your index at N percent* (R-M's shape; lints 3/42/43 pass); D374 — `CS_CLAIM_UNFINISHED` / `CS_CLAIM_NOT_STARTED`, one producer, read on the signed-out door (the D85 `guest_live_state` result is kept and branched on: abandoned drops the token and says so, setup keeps the pencil and says when) and before `claim_round` on the signed-in path; D375-now — the run-it-back result and sub-line say *carried over* and name the step-out door, never an opt-in, and the stale "unpushed" comment is corrected; D376 — a **Ruling** button beside Bye on the roster sheet opens `openRulingSheet` (member, delta 1–50 up or down, reason 3–240 chars) → `adjust_points`, toasts `csRulingDone`, reloads the league; the member receipt lists an override row with its reason from the ledger the desk already reads (D355); D378 (vii) — the web season-story line already derives its weekday from the snapshot date, so it is right by construction once the snapshot rides the tick. Pins added to `tests/app-tests.js` (covenant clause with allowance, run-it-back copy ×4, ruling toast, claim sentences). Browser check here: producers evaluate to the pinned strings; the module block cannot load in this sandbox (CDN blocked), so the full suite runs on the Mac.
7. **Phone halves owed on the Mac (D234 — not done until both ship):**
   - D373: `WizardState.swift:563` (preset help), `LeagueSetup.swift:57` ("of your handicap" → the R-M clause), `JoinLeague.swift:230` (covenant clause), `LeagueCopy.swift:136` (bylaw row); `GuideCopy.swift:143` keeps the worked example; pins `ReleaseFixesTests.swift:10`, `LeagueRoomTests.swift:411`. The clause, verbatim: *scored against your playing HCP — your index at 95 percent*.
   - D374: `LiveRoundHost.swift:190–220` and `LiveClaim.swift:41–125` — a `ClaimDoor.Face` for unfinished (token dropped) and not-started (token kept) beside `.dead`; `ClaimFlow.consume` calls `guest_live_state` before `claim_round`; one Kit test beside `LiveEngineTests.swift:746`. Sentences verbatim from `CS_CLAIM_UNFINISHED` / `CS_CLAIM_NOT_STARTED`.
   - D375-now: `LeagueCopy.swift:551–566` / `RunItBackResult.line` — *carried over*, the step-out door named; the file comment that says `run_it_back` is unpushed is stale.
   - D376: a Ruling row in `MembersSheet` / `LeagueRoomModel` calling the generated `Rpc.adjustPoints` (already in `Rpc.swift`); `CS_RULING_WHAT` and `csRulingDone` twins; `SquadReceiptBreakdown` and the member history list override rows with their reason.
   - D378 (vii): `HomeFallbackItems` — *since Sunday* → *this week*; `HomeFallbackItemsTests.swift:142–145`. `SeasonStoryCopy` should already derive the day from the snapshot date — verify, do not change.
