# Verify · SP-9 · lens "is-it-structural" — tip 3bba87e, 2026-09-04

**Verdict: HOLDS, narrowed.** The core survives every copy / single-screen / default fix I could construct; roughly half of the statement's evidence is NOT structural and should be moved to an attached "non-structural" list, and two evidence lines are wrong at tip (server-side anticipation producers do exist; the clash result IS pushed). No immutable law blocks the fix; D23's push fence is a level-2 ruling with an extension path (CC-22), and the vision itself lists the missing kinds.

All line numbers as of tip 3bba87e. SAW = read in code or returned by `supabase db query --linked` today; INFER marked.

## 1. Refutation attempts (what I tried, and why each fails on the core)

| Attempt | Would dissolve | Fails because |
|---|---|---|
| Copy: reason-keyed ask lines, one verb per invitation kind, settings sentence | EN-05, EN-12, the ask's "duel" line (FR-05) | Nothing reaches a leagueless lock screen or a between-seasons league. |
| Single screen: sync the duel reminder from Home load; a Home door while `.notDetermined` | EN-06, EN-01/EN-16 | Still client-scheduled; still no producer for anything personal. |
| Single file: `collapseId: record.round_id ?? record.id` in `push/index.ts:520` | EN-03 (N-times) | Dedupes, does not add a recipient. |
| Default: fan `round` posts to the author's friends inside the posts webhook | EN-02 | A round produces NO post unless a league of the author has an ACTIVE season covering `played_on` (`round_to_board`, `20260727160000_board_voice.sql:61-73`) — for the 14 leagueless (SAW: 14 today) and for a completed league there is no row to fan. The producer has to move to the `rounds` INSERT path (a new trigger or a `push_nudges` writer) — a mechanic, not a default. |
| Default: enrol every golfer in an implicit league | EN-02, DL-12 | That is SP-1's mental-model change (posts homed in leagues), not a default. |

Five-questions test: with every non-structural fix above applied, Persona A (leagueless) still has no producer that can tell them "what is happening / who I am competing with" between opens, and Persona B (member of a completed league) still gets nothing because the league graph is silent by construction (§2b). holds = true.

## 2. The structural core, verified at tip (SAW)

a. **Two circles, one rail.** Home's "what happened" read is `home_feed(p_days)`: circle = accepted `friendships` ∪ league-mates ∪ event-mates, over `rounds` (`20260723090000_home_feed_photo.sql:24-46`; the phone's cross-league lane "Around your buddies", `HomeView.swift:104-108`, D218 `decision-log.md:5660`). The push rail's recipients for round/moment/system are `league_members` of the post's league minus author, prefs, mutes (`supabase/functions/push/index.ts:501-521`). So the product already carries the brief's mental model of "my people" as a READ and the database's as the only thing that reaches a lock screen.

b. **The league graph is silent by construction between seasons.** `round_to_board()` inserts one post per league_membership whose season is `active`/`cup_final` and whose dates cover `played_on` (`board_voice.sql:61-73`; the moment writer has the same guard, `20260831130000_the_moments.sql:611-617`). A completed league (Persona B's Dew Sweepers) therefore produces zero round posts, hence zero pushes, token or no token.

c. **Every per-person producer is another person's act on you.** `push_nudges` inserters: invite (`push_wave7.sql:82`), request (`:119`), rsvp (`:157`, `:223`; re-created `20260831170000:118`, `20260902203000:133`), live-round nudge (`board_voice_natural_case.sql:2351`), Ryder duel/taunt (`ryder_slice3.sql:413`, `nudge_payloads.sql:82,145`), takedown (`the_takedown_path.sql:332`). Kinds allowed: `push_nudges_kind_check` (`push_wave7.sql:36-37`); route kinds `push/index.ts:100-102`. No producer reads a standing, a gap, a seat count, a countdown or the friendship graph. Prod today: push_nudges = nudge 11 · request 6 · rsvp 1 · invite 0.

d. **The only forward-looking per-person reminder is client-scheduled.** `PushDuelReminder.sync` is called from exactly one place, `EventRoomModel.swift:44`; `EpilogueSheet.swift:55` cancels. The plan is `PushDuelPlan.make` (today, 18:00, pending duel, `PushDuelPlan.swift:28-50`).

e. **The rail is unproven.** device_tokens = 1 (`ios-sandbox`), push_prompt_shown 1 / accepted 0 (SAW today). Cause is a trigger-set defect, not structure — see C4.

## 3. Canon check — no immutable law blocks the fix

- Vision (`spec/product-vision-v1.0.md:123-125`): "Friend posted. League lead changed. Championship clinched. Milestone reached. Invitation received. Round approved. No spam." — the vision ENDORSES the missing kinds.
- D23 (`decision-log.md:393-412`): eight emotions, once per condition, no shame, no badge counts; "V1 nudges are HOME-SURFACED chips only, never push … Push escalation is a Year-2 decision with its own entry." Level 2, overridable by an entry that keeps the three fences (CC-22, canon report `:278`). D104 (`:3799-3818`) already crossed the "never push" line for real events, so an anticipation kind is a D104 extension under D23's guardrails.
- Guardrails that STAY (`memory-layer-v1.md:261-276`; L-20/L-22): no engagement bait, no manufactured FOMO, streak-shame ≤ one dignified reminder, badge = actionable only (D179, CC-41). Consequence for the fix: "filling up" and "starts in three days" must be facts once per condition, never a countdown drumbeat; "points from 2nd" is D130's stake line whose entry says "Push: none" (`:4337-4341`) — pushing it needs D130 amended, not merely a new kind.
- Nothing at vision or mechanic level (spec-v1.0) is touched: recipients and producers are notification-level (D104's own level).

## 4. Corrections to the statement and evidence

C1 · **N-times is implementation, one file.** `apns-collapse-id` is `record.id` (`push/index.ts:520`, applied `:272`); `record.round_id ?? record.id` folds the second league's push on the device; month-close needs a league-independent key. Scale: **32** round_ids have >1 post today (SAW), not two examples.

C2 · **Three invitations, one title** — copy in three SQL functions (`push_wave7.sql:83`, `board_voice_natural_case.sql:2352`, `20260831170000:118` + `20260902203000:133`). Not structural.

C3 · **Duel reminder call site** — a one-site change (`EventRoomModel.swift:44`). Bonus copy conflict: `PushDuelPlan.swift:53` says "Your duel closes **tonight**" while D176 beat 3 rules "today, never tonight" and its migration RAISES on "tonight" in the SQL function — the client's local reminder escaped that check.

C4 · **"Fires before the first Home" is imprecise.** The request is queued in `CardGateView.save()` (`:238`) while the boot state is `.cardGate` (`RootView.swift:34-35`); presentation is `MainTabView.drainAsk` (`:330`, `:333` with a 500 ms "let the curtain close first", `:444-447`) — half a second INTO the first Home (persona A: "a sheet rises over Home a beat later"). The copy is reason-independent (`PushAsk.swift:86-90`) — a copy fix. The real defect is the trigger set: `PushAskReason` has three FIRST-TIME moments (`PushAskPolicy.swift:11-16`); anyone who onboarded before D104 (2026-08-27) never hits one again — which is WHY push_prompt_shown = 1 ever and 0 `ios` tokens exist while build 669 is out. A Home door while `.notDetermined` (EN-01/EN-16) is a single-screen fix. Not structural; keep as the precondition for observing anything in SP-9.

C5 · **Settings pills** (`CardAndSettingsScreen.swift:488-496`) — single-screen copy.

C6 · **"One phone can hear them"** conflates the token count with the rail's health. `PushService.swift:27-31` registers `ios-sandbox` under DEBUG and `ios` otherwise; `hostFor` (`push/index.ts:256`, `:283-289`) routes each token to its host and retries a misroute. The rail is unproven, not broken. Say "unproven in production; precondition".

C7 · **Two evidence lines are wrong at tip.** Server-scheduled, once-per-condition anticipation producers DO exist, all as league `system` posts, and every `system` post IS pushed to league members unless the Pro curated it off (`push/index.ts:504-508`, `:511-521`):
  - `clash_last_call` — "The clash closes today …" from the daily tick (`20260902170000:222-317`; called `20260904180000:102`; D176 beat 3) — a forward-looking SERVER producer, so "the only forward-looking … reminder schedules only if you opened the event room" is false;
  - `settle_week_clash` — "<First> took the week — …" (`the_moments.sql:726-729`) — the clash's RESULT is pushed; HM-34's "folded" is Home's display choice, not the rail's;
  - `lock_league` — "Bylaws locked. First tee Wed Sep 30 · …" (`20260902163000_the_first_tee_horn.sql:216-219`);
  - the first-tee horn — "The season is live. Week 1 — counting rounds start now." (`:49-58`).
  What is genuinely absent: a COUNTDOWN ("in three days"), any PERSONAL kind (passed you / N from 2nd / YOU won — the lines above are league-wide, second-person-free, and land on the loser and the bystanders alike), seat count, challenge (no challenge object exists — another SP's territory), friendship fan-out. Prod today: 0 last-call posts, 0 first-tee posts have fired yet (Fellas' horn is due 09-30) — these producers are as unobserved as the rail.

C8 · **DL-06/DL-11** belong to the data layer; SP-9 needs only: `prev_rank` is a Sunday snapshot (`20260902200000:312-342`), so "passed you" must be produced on the round INSERT path, not read.

C9 · **Persona B's diagnosis changes** from "no notifications came" to "silent by construction" (§2b). The only line that could reach B is `lock_league`'s "Bylaws locked. First tee …" when Marcus runs it back — and only if the run-back keeps B on the roster (D41 makes a new league; persona B asked "Would there be two leagues?"). B remains a structural victim, via the active-season guard, not via missing kinds.

C10 · **Persona E is a weak witness.** E's question ("what time Saturday and where?") is answered by the RSVP nudge that exists (`20260831170000:114-122`); the gap is that Casey never declared the round in the app (a create/schedule SP), not a notification kind. Keep E only for the ask's vocabulary ("duel", "the board", "the table", persona-E:165).

C11 · **D23's own V1 fallback was never built.** The Home chips D23 named ("You and Jake haven't played together in 47 days"; the streak reminder) have 0 hits in `apps/ios`, `index.html`, `supabase/migrations` (SAW). The statement should say the fence was honoured on the push side and left unbuilt on the chip side — the between-opens loop has NEITHER.

C12 · **Hierarchy line**: "mechanics (notification level, D104's own), fenced by D23 (level 2, extension path CC-22); depends on SP-1 for the leagueless half (posts homed in leagues); independent of SP-1 for the between-seasons half (active-season guard) and the personal-kinds half."

## 5. Proposed narrowed statement

"Between opens the product can only say what a league-mate did inside a league with a live season. The push rail's recipient set is `league_members` of the post's league (`push/index.ts:501-521`), and a round becomes a post only for a league whose season is active on that date (`round_to_board`, `board_voice.sql:61-73`), while Home's own circle is friendships ∪ league-mates ∪ event-mates over `rounds` (`home_feed_photo.sql:24-46`). So the 14 leagueless golfers and every member of a between-seasons league are silent by construction, and every per-person kind that exists (invite / request / rsvp / nudge) is another person's act on you. The anticipation producers that exist (bylaws-locked, first-tee horn, clash last call, took-the-week) are league-wide `system` lines; no personal kind (passed you, N from 2nd, you won), no countdown, no seat count, no challenge and no friendship fan-out exists, and the one per-person forward-looking reminder is client-scheduled (`EventRoomModel.swift:44`). The rail is unproven in production (1 sandbox token) because the ask's three first-time triggers (`PushAskPolicy.swift:11-16`) never fire for anyone who onboarded before 2026-08-27."

Attached non-structural list (fix regardless, cite as such): C1 collapse key · C2 invitation titles · C3 reminder call site + "tonight" · C4 ask trigger set + Home door + reason-keyed copy · C5 settings pills.

## 6. Root cause, amended

Principles: D23 fenced push (chips only) and the chips were never built. Mechanics: D104 built push as a webhook on `posts` INSERT, inheriting posts' league home (SP-1) AND `round_to_board`'s active-season guard; the friend circle exists as a read (`home_feed`) but never as a recipient set; the personal rail (`push_nudges`) exists but every inserter is act-on-you; D130's stake line was ruled "Push: none". UI: the ask is keyed to three first-time profile events. Implementation: collapse id per league post; the local reminder's trigger site and copy. Rollout: no production token has ever registered.

## 7. Costs (unchanged, sharpened)

WAU/MAU and D7/D30: silent for everyone until a token exists; silent by construction for the leagueless (SP-1) and for every between-seasons league (the active-season guard). Season repeat: "Bylaws locked. First tee …" exists but only reaches the NEW league's roster after the Pro acts; nothing nudges the Pro or tells the crew a run-back is possible. Competition repeat: no "Jake posted — +2.3 to beat" outside a shared active league. The brief's notification principle cannot be tested until C4 is fixed on one TestFlight phone.
