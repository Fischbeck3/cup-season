# Blind UX audit 2026-08-29 — Synthesis: triage + master dataset

**Scope.** Eight blind persona passes on the web client at `http://127.0.0.1:8791/` (seven interactive: organizer, league novice, mid-season observer, new joiner, casual, competitive, skeptic) plus a look-only survey of the native iPhone app. 284 raw issue rows, 8 confusion-debt lists, 8 verdicts. This document is the synthesis; nothing here was softened because the spec explains it — where the spec explains it and the UI didn't, that *is* the finding.

**Method discipline.** OBSERVATION = what testers saw (quoted copy, screenshot). INTERPRETATION = my reading of why. INTENT = what `spec/spec-v1.0.md`, `spec/decision-log.md`, `Cup-Season-Guide.md` and `index.html` say the product means to do. The three are kept apart in every finding below.

**Artifacts.**
- Master dataset: `docs/audit/blind-ux-2026-08-29/issues.json` (127 rows) and `issues.csv` (same columns; quoted; one header row). Every one of the 284 original IDs appears in exactly one `dedupedFrom` list — nothing was dropped. `issues-counts.json` carries the tallies.
- Raw reports: `raw/*.md`; screenshots under the harness `shots/<session>/` directories referenced in each row.

**Counts.** 127 master issues from 284 raw rows. By severity: **P0 6 · P1 43 · P2 62 · P3 16.** By category: comprehension 27, terminology 16, visual-hierarchy 15, gameplay 14, rules 14, navigation 11, onboarding 10, social 8, monetization 6, retention 6. By stage: activation 38, engagement 53, retention 30, monetization 6.

**Persona verdicts (1–10):** organizer 3 · novice 4 · mid-season observer 4 · joiner 3 · casual 4 · competitive 5 · skeptic 3 · iOS survey 4. `rulesClear` averaged **3.9**; `wouldInvite` **4.4**; `wouldPay` **3.75**. The two things every tester praised — the post-a-round form with its live bands, and the live side-game scorer with its stroke line and settlement — are the same two things the season layer then contradicts.

---

## 1. The five biggest problems

Ranked by damage along activation → engagement → retention → monetization. Each has evidence (report · screenshot · exact copy), the product's own intent, the root cause found in source, the fix, and the expected impact.

### 1. The organizer cannot finish: lock reports failure, and the invite is a dead end
**Stage: activation.** Master issues M-001, M-002, M-003, M-017, M-004 (supporting: M-006, M-007, M-008, M-011, M-018, M-022).

**Observation.** Both organizers tapped "Lock the bylaws & form the squads" six times. Each tap produced a 1.5-second toast "Lock failed. Something went wrong — please try again." (`screenshots/nov/33-lock-fail-toast.jpg`) or nothing visible at all (`screenshots/org/31-after-lock.jpg`); console: `[cs] error: Lock failed. staged is not defined` ×12. The novice reloaded and found Home reading "DESERT DOGS · SEASON LIVE — Rounds count from today" (`screenshots/nov/34-reload-home.jpg`): the first tap had succeeded and her later switch to Solo was silently discarded. Then the invite: "Add golfers" only searches existing accounts ("No golfers found. Invite links still work for everyone else.", `screenshots/org/42-add-golfers-email.jpg`); every "Share the invite link" control produced the toast "Invite code: THEPTCQ5" and never a link (`screenshots/org/38-share-invite.jpg`, `screenshots/nov/45-share-link.jpg`); no invitation email was ever sent to any of the four invitee accounts (three independent Gmail searches). "Draw squads" said "Draw failed. Something went wrong" while the server said "Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first." (`screenshots/nov/53-after-draw.jpg`). Buy-in defaulted to a hidden $75 behind "Customize" (`screenshots/nov/19-wizard-customize-full.jpg`).

**Intent.** D40: "openLockShare fires the instant you lock, so 'one link fills the league' is preserved." The Guide: "add golfers (find them by name or @handle, **or invite by email**)". D46: buy-in "surfaces the choice so it's seen, not buried."

**Root cause (verified in source).** `lockBylaws()` still ends with `return { emails: emails.length, invited: staged.length, nextPhase }` (`index.html:15218`); D97 deleted the `staged` array and its loop but left this line. The RPCs (`form_squads`, the `leagues.update`) have already run, so the ReferenceError fires *after* commit, `humanError()` maps it to the generic sentence (`index.html:4117`), and `openLockShare` — the **only** invite moment the product has after D40 — never opens. Invite-by-email does not exist in the client at all (the Guide is wrong). The share fallback is `catch(e){ toast('Invite code: ' + code) }` (`index.html:14127`). `state.stake` is seeded `75` (`index.html:3793`).

**Why it matters.** This is the single tap that turns an account into a league, and it is where seven pilot Pros stopped before (the hero comment at `index.html:10080` says so). Every downstream funnel — joiners, rounds, pot — waits behind it. Organizer verdict: "Fix the lock bug and add a real invite and this is a 7."

**Fix.** Remove the dangling `staged.length`; on any post-commit exception re-read league state and render success; pass user-facing RPC messages through `humanError`; render the join URL as text with Copy on every share surface; ship invite-by-email/SMS with a prewritten message (league, Pro, dates, buy-in, link, "three things"); default buy-in $0 and surface it above the fold; add a preflight/e2e test for lock → share.

**Expected impact.** Unblocks league creation outright (today: 0 of 2 organizers saw a success state). Organizer `setupClear` 4 → 7+, `wouldInvite` 4 → 6–7 by the tester's own estimate.

### 2. Nobody can tell what they are joining until after they have committed
**Stage: activation (with a monetization trust cost).** M-023, M-143, M-024, M-025, M-026, M-133, M-144.

**Observation.** The cold door is "Rally your crew. Post real rounds. Take the cup." plus two buttons and `v23 · __CS_VERSION__` (`screenshots/skep/02-cold-door.jpg`). The invite landing adds one line: "You're invited to The Papago Grind. Enter your email and you're in." The consent sheet — after sign-in, golfer card and orientation — shows four rows: `BUY-IN $50 / player · on the pot sheet`, `PRESET Standard`, `PARTICIPATION FLOOR 2 rounds / mo`, `FINISH Cup Final · final 4 weeks`, then "Join — I'm in for $50" (`screenshots/join/11-J-after-take-me-in.jpg`). No roster, no organizer, no dates, no scoring, no payment path. "Not now" drops the invite and the code must be retyped. The skeptic: "the single most likely bail point — 'wait, fifty bucks for what?'" On the phone, across 11 screens, nothing says what a point is or how a season is won (`screenshots/ios/01-door.jpg`). The differentiator — a season race against your own number, from any course, with a fresh-scored final — is stated once, in the fifth "How it works" card at the bottom of the You tab.

**Intent.** Vision principle 2 ("Low Friction Wins"); D47's "the door explains itself"; the join covenant was designed for money disclosure (`index.html:15418` comment).

**Root cause.** `covenantGate()` renders only `buyin / preset / floor / finish` from `join_covenant_info` (`index.html:15422–15440`); the door is auth-only by design; `?join=` is consumed into `localStorage.cs_code` and stripped from the URL; the Leagues-vs-events sentence lives in the You › How it works list only.

**Why it matters.** Three of four joiner personas scored `conceptClear` ≤ 5 and `wouldPay` ≤ 5. A $50 ask disclosed after account creation reads as bait-and-switch to the person the growth model depends on (foursome-by-foursome, no paid acquisition).

**Fix.** Consent sheet: roster with "Casey invited you · THE PRO", date range, point bands, pot split, payment note; league card on the invite door before email; the Guide sentence + a three-card "how it works" on the cold door; persist the pending invite as a Home card; on iOS a tappable "How points work" under the rank card.

**Expected impact.** Converts the invite from a code relayed by text into a self-explaining offer; directly raises `conceptClear`/`stakesMeaningful` for joiners; removes the money surprise that the skeptic identified as the bail point.

### 3. Members are handed the organizer's controls and no next step
**Stage: engagement.** M-030, M-031, M-032, M-033, M-041, M-110 (buy-in rows).

**Observation.** For four PLAYER personas the Home hero's only CTA was a full-width orange "Lock it in and invite your crew" (`screenshots/cas/19-C02b-home-full.jpg`). Tapping it opened "CREATE YOUR LEAGUE · Review the bylaws, then lock it in" with a live "Lock the bylaws & form the squads" button pre-filled with the friend's bylaws (`screenshots/join/39-U-lock-it-in.jpg`); "← Back" walked deeper into the wizard ("League name · Pro — that's you · Marcus"); "Cancel" prompted "Cancel this league? … discards it completely." and failed only because the server said `commissioner only`. The You tab from Home rendered the wizard instead of the profile 7 times across three testers. "See the squads" opened the Pro's blind-draw tool with tappable chips and no back. The league's status read "FORMING", "Squad formation", "SQUADS ARE FORMING · The Pro has the list", "Squads · LIVE NOW — CAPTAINS READY" and "is live — post the first round" at once. Nowhere did a member see "wait for Sep 5, then post two rounds a month."

**Intent.** D40, verbatim: "a member must never see the Pro's configuration tool … enterLeague routes only the Pro to the wizard; members land on Home's forming state — the backstop."

**Root cause.** The backstop covers `enterLeague` only (`index.html:14500`: `switchView(state.phase === 'setup' && isPro ? 'wizard' : 'home')`). The forming hero at `index.html:10102` builds `nextStep = { label:'Lock it in and invite your crew', go:toWiz(2, null) }` with no role check, so every member of a forming league gets the Pro's CTA and a working route into the wizard; the wizard view then persists and captures the You tab. Status labels are hard-coded per component (`index.html:3553, 12231–12232, 3428`) rather than derived from one state.

**Why it matters.** The biggest button on every member's Home is one they are afraid to touch, and it nearly deleted the friend's league. "What do I do now?" — the question the vision's "App Should Feel Alive" principle exists to answer — is answered by an admin tool.

**Fix.** Role-gate the hero CTA and the wizard view; render a read-only forming card for players ("Casey locks the bylaws at first tee · squads drawn then · post from Sep 5"); the You tab always renders the profile; one league-state machine feeding every status string; read-only squads view; demote the Start/Start/Join row for members.

**Expected impact.** Removes a near-destructive path; gives every member a next action; ends the four-way status contradiction that every persona logged.

### 4. The first round contradicts itself: points promised, zero delivered, sign inverted, receipt stops short
**Stage: engagement.** M-040, M-045, M-044, M-046, M-049, M-048, M-076, M-080.

**Observation.** Six of six web testers posted a round seven days before first tee. The form said "LEAGUE POINTS THIS ROUND 5" (or 6, or "12 — You torched your number by 5.0. Sandbagger alert.", `screenshots/comp/35-preview-74.jpg`). The posted sheet said only "COUNTS ON YOUR CARD". Standings: "R 0 · Pts 0" (`screenshots/comp/40-standings-after74.jpg`); the player's own row sheet: "No rounds this season yet — post one and you're on the board."; You: "THIS SEASON · Rounds posted 0" beside "LIFETIME · Rounds posted 1". Home meanwhile said "SEASON LIVE — Rounds count from today" while the Clubhouse said "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON." The same round was described as "-3.7 VS YOUR INDEX" (red), "3.7 over your number", and "Against your number -3.7 — POSTED ANYWAY" (`screenshots/nov/77-round-detail.jpg`); the casual golfer's was "-9.8", "9.8 over", then "+0.0 — PLAYED TO IT". "Beat it by 3" never says 3 of what; the 95% allowance in the bylaws appears in no calculation; the receipt has no points line and no edit/delete.

**Intent.** Spec §16: "No points figure without a path to the rounds that produced it … Round receipts show the rating/slope/allowance snapshot"; spec §14.0: pre-season rounds are "practice"; D1: the screen says "your number", PvI is engine currency only.

**Root cause.** The preview computes `vs = state.myIndex − diff; pts = pointsFor(vs)` with no season window (`index.html:6327–6341`); the sign leaks from `sgn()` helpers and `(vs>=0?'+':'')` at 4566/6339/11519/11830–11890 while `vsPhrase()` (5710) already has the right words; the allowance is never applied client-side; the copy at 3198 ("No league yet?") is unconditional.

**Why it matters.** This is the loop. Every tester's first promise from the product did not happen and nothing said why; two believed the post had failed. `rulesClear` 3–5 across the board traces here.

**Fix.** Season-aware preview ("Season starts Sat Sep 5 — this round builds your number; no league points yet"), echoed on the posted card and receipt; `vsPhrase()` everywhere and retire signed numbers; receipt lines "League points: 6" and "index used: 14.2 × 95% = 13.5"; guard the preview on rating+slope; a labelled "Fix this round" on the receipt.

**Expected impact.** Turns the strongest screen in the app (the form) into a trustworthy one; the "shows its work" promise becomes true end to end; removes the top comprehension complaint of all seven interactive personas.

### 5. "How do I win?" is answered nowhere — and the money that rides on it is never explained or collected
**Stage: retention (→ monetization).** M-055, M-056, M-057, M-058, M-054, M-059, M-072, M-123, M-124, M-110, M-111, M-012, M-120.

**Observation.** The mid-season observer's Home said "You lead by 22 points over Jade." The only statement that the title is decided by a fresh-scored four-week Cup Final is one bylaw row — `CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh` — behind a collapsed "▸ LEAGUE RULES & PRO SHOP" disclosure (`screenshots/obs/21-bylaws-open.jpg`; 4 taps + a disclosure, ~5 min). No tester found who plays the Final, what "scored fresh" does to accumulated points, what a seed / LOCKED / "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" / "TOP 1 ADVANCE" means, how ties break, or whether "Cup champs $150" is a person or a squad. The floor penalty is explained three inconsistent ways. The rules themselves are four taps deep. Home shows one league only (the one where the observer was losing was invisible). No rival, gap or "this round matters because" line exists. On money: "$0 collected · 2 still owe" six weeks into a $75 season; "The Pro marks buy-ins as money moves between you" is the only answer to "how do I pay?"; membership "lands at launch" with no price in two places.

**Intent.** Spec §14.3 has the entire answer (seeds lock at the window, leader +10, the tie-break ladder, non-finalists keep racing); D39 makes the pot a ledger by design; the vision's "Every round counts" and "The App Should Feel Alive" principles.

**Root cause.** The endgame exists in the engine (`cup_final_race`, `isCupFinal()`) and in the bylaws table, but no surface narrates it before the window opens; bylaw rows are static text; `How scoring works` has no endgame or ties section; the hero renders one league; the pot ledger has no payment note/deadline fields.

**Why it matters.** Retention verdict: "the cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant" (4/10). A member could coast on a lead that decides nothing. The pot — the product's chosen stakes mechanism and its future season-pass pricing anchor — reads as fiction when nobody knows how to pay it.

**Fix.** One endgame sentence with a countdown on the hero and standings; tappable bylaw rows; ties + seeds + final in the explainer; "Rules" as a sub-tab; a per-league row on Home; gap/head-to-head/what-if lines; Pro-set payment note + deadline, member rows as status, unpaid buy-ins on Home; one sentence on membership.

**Expected impact.** Gives the season a visible end to play toward and a reason to open the app between rounds; makes the pot real; the observer's `stakesMeaningful` 3 and the competitor's `gameplayCompelling` 5 are the metrics this moves.

---

## 2. Zero-instruction test

> If the developer disappeared and a new user downloaded Cup Season tomorrow, could that user successfully run a season with five friends without asking another human how it works?

**Answer: NO.**

Why, from evidence only:
1. **The organizer cannot complete setup and know it.** Both organizers saw "Lock failed" on every attempt; one only learned the league was live by reloading (M-001). The share sheet that is supposed to hand over the invite never opens.
2. **The five friends cannot be invited from the app.** No email/SMS invite exists; "Add golfers" finds only existing accounts; the invite link is never displayed, only a code in a vanishing toast (M-002, M-003). The organizer would have to text "download Cup Season, tap 'I have an invite code', type THEPTCQ5" — which is asking another human.
3. **A friend who does open the link cannot tell what they're joining** before agreeing to $50 (M-023) — so they will text the organizer to ask.
4. **Once in, every friend's Home hands them the organizer's lock button** and no next step (M-030); the You tab opens the wizard (M-031).
5. **Their first round promises points and delivers zero with no explanation**, described with three different signs (M-040, M-045); two testers assumed the post failed.
6. **Nobody can answer "how do we win"**: the Cup Final, seeds, ties and the floor are undefined or contradictory in-product (M-055–M-058); the rules are four taps deep (M-054). The organizer would explain it in the parking lot — every persona said so in those words.
7. **Money** is a ledger nobody knows how to settle (M-110), with a hidden $75 default (M-004).

What *would* pass: an already-formed, already-running league where members only post rounds and play live side games. The post form, tee picker, receipt math, live stroke line, live ledger and settlement card were praised by every persona. The season *around* them is what fails the test.

---

## 3. Friction tax

Every point where a tester had to think, read, interpret, remember, calculate, navigate back, ask, guess, confirm, repeat or leave the screen. Severity is the master-issue severity; journey letters follow the brief (A discovery · B sign-up · C create · D first round · E mid-season · F finale · G side games · Join · Money · iOS).

| # | Friction point | Type | Sev | Journey |
|---|---|---|---|---|
| F1 | Lock tapped 6× over ~3 min, then a full reload to learn it had worked | repeat / leave-screen | P0 | C |
| F2 | Type friends' emails into Add golfers (3 attempts) — cannot | repeat / ask | P0 | C |
| F3 | Decide "Join — I'm in for $50" with no roster, dates or rules | guess / ask | P0 | Join |
| F4 | Read "Lock it in and invite your crew" as my job; enter the wizard; escape via Back ×2 + Cancel + a failed discard | navigate-back / confirm | P0 | Post-join |
| F5 | Check Standings, You and my row sheet (~2 min) to discover the promised points never landed, then guess why | navigate / guess | P0 | D |
| F6 | Open Customize and read every (i) (~7 min) to find the $75 buy-in and the dials "Use these defaults" would have set | read / navigate | P0 | C |
| F7 | Choose a Teams structure for 7 from a control whose highlight, caption and note disagree | guess | P1 | C |
| F8 | Reconcile "GHIN rounds" (card) with "Attested" (review) | interpret | P1 | C |
| F9 | Hesitate at the lock: three lock moments, "form the squads" with 1 player | think / confirm | P1 | C |
| F10 | Find the league room via a Home tile after the Clubhouse tab showed no league | navigate | P1 | C |
| F11 | Tap Share ×4 → a code toast; try to verify anything was copied | repeat / guess | P1 | C |
| F12 | Retry "Draw squads" against a generic error the server had explained | repeat | P1 | C |
| F13 | Find the rules: Clubhouse → room → League → expand a collapsed panel → link (18 min in, by accident) | navigate | P1 | C/Rules |
| F14 | Dismiss the install banner before the ⊕ responds (2 dead taps) | repeat | P1 | D |
| F15 | Retype the league code after "Not now" (3 taps) | repeat / remember | P1 | Join |
| F16 | Reconcile "Enter your email and you're in" with four more screens | interpret | P1 | Join |
| F17 | Decode "PRESET Standard" on the consent sheet | guess | P1 | Join |
| F18 | Ask the Pro how, to whom and by when to pay the $50 | ask | P1 | Money |
| F19 | Tap You from Home → wizard; tap again | repeat | P1 | Nav |
| F20 | Reconcile "SEASON LIVE — Rounds count from today" with "PRACTICE ROUNDS HIT YOUR CARD" with "LEAGUE POINTS THIS ROUND 5" | interpret | P1 | D |
| F21 | Reconcile "Squads are forming" / "LIVE NOW — CAPTAINS READY" / "Complete · rosters locked" / two Empty squads | interpret | P1 | Clubhouse |
| F22 | Recover from the Schedule tab leaving the room (1–3 failed taps) | navigate-back | P1 | Clubhouse |
| F23 | Pick a tee before typing scores (4 attempts); interpret "-79.0 vs your index" | repeat / interpret | P1 | D |
| F24 | Interpret "-3.7 vs your index" vs "3.7 over your number" vs "+0.0 — played to it" | interpret | P1 | D |
| F25 | Find delete: a tiny ✕ on You, a native confirm, no undo, no edit | navigate / confirm | P1 | D |
| F26 | Reverse-engineer from the receipt that "beat by 3" means differential, not strokes | calculate | P1 | Rules |
| F27 | Reconcile two vs-index numbers for one round (3.3 vs 2.6 → 12 or 9 pts) | calculate | P1 | E |
| F28 | Find the Cup Final rule: 4 taps + a disclosure, ~5 min — and still not know how the winner is decided | navigate / ask | P1 | E/F |
| F29 | Discover the second league (where I'm losing) by accident after 10 min | navigate | P1 | E |
| F30 | Cross-check board dates against standings and receipts (~4 min) to find the count of August rounds | calculate / interpret | P1 | E |
| F31 | Decode HELD / AUG FLOOR 1/2 / MONTH CLOSES on the hero | guess | P1 | E |
| F32 | Scrap this round: 3 attempts, nothing happens | repeat | P1 | G |
| F33 | Resume a live round via ⊕ → Play now because the promised Home banner never appears | navigate | P1 | G |
| F34 | Discover a 103 posted to my card by someone else; no way to confirm or dispute except delete | ask | P1 | G |
| F35 | Reconcile "WEEK 4 OF 14" with "WK 4 / 13" | interpret | P1 | iOS |
| F36 | Read "10 back of Galen" under Galen's row | interpret | P1 | iOS |
| F37 | Read 41/43 placeholders as entered scores | interpret | P1 | iOS |
| F38 | Reconcile an empty Board with 18 items on Home | interpret | P1 | iOS |
| F39 | Scroll to learn a code was sent; hunt a Gmail thread of 20 identical subjects (~3.5 min, one Resend) | read / leave-screen | P2 | B |
| F40 | Interpret "Month closes in 2 days" a week before the season | interpret | P2 | Home |
| F41 | Exit Form squads via the bottom nav (no back) | navigate-back | P2 | Clubhouse |
| F42 | Find the invite code at the bottom of a long Standings page, under a red delete | navigate | P2 | C |
| F43 | Choose between two identical "Papago Golf Course" rows; second tap after a 502 | guess / repeat | P2 | D |
| F44 | Dismiss three stacked post-round sheets; interpret "Turn off this link" | read / confirm | P2 | D |
| F45 | Compute the 95% allowance by hand and fail to reproduce the number | calculate | P2 | Rules |
| F46 | Sum 9+5+5+6+7 on the receipt to confirm 32 | calculate | P2 | E |
| F47 | First stepper tap = par: 6 taps → 10 on a par 5 | repeat / relearn | P2 | G |
| F48 | Choose between "Finish — no complete member card to post" and "This one was casual — post nothing" | guess | P2 | G |
| F49 | Select each game chip to read its rule and player count | repeat | P2 | G |
| F50 | Net the skins settlement by hand (7 × $15 − 9 × $5) | calculate | P2 | G |
| F51 | Hit the banner's "Add" instead of the guest "Add" | repeat | P2 | G |
| F52 | Tap a buy-in row; invisible refusal | confirm | P2 | Money |
| F53 | Scroll to the bottom of the board for the newest post | navigate | P2 | E |
| F54 | Decode "you lead 1–0 · YOU'RE IN · "Major" · BUDDY" | interpret | P2 | E |
| F55 | Wait 6–8 s on the sign-in door at every cold open | wait / think | P2 | Retention |
| F56 | Distinguish five round entry points (Post, +, Play now, Live round, tee sheet) | think | P2 | iOS |
| F57 | Scroll past header card, four tiles, a bar and a next-up card to reach standings | navigate | P2 | iOS |
| F58 | Open the join URL manually to see what friends will be told | leave-screen | P2 | C |
| F59 | Re-enter the wizard via Home → review → Back → Back to edit the name | navigate-back | P2 | C |
| F60 | Count "THREE THINGS TO KNOW" that are four | read | P3 | Join |
| F61 | Tap "Start the league" with an empty name; nothing happens | repeat | P3 | C |
| F62 | Add weeks remaining by hand (26 − 6) | calculate | P3 | E |
| F63 | "Copy link" for the guest → "Copy failed — try again" | repeat | P3 | G |

---

## 4. Confusion debt (consolidated)

Everything the product assumed the user already knew, merged across the eight lists. Agents in brackets.

1. That **league, season, cup, event** and **crew/buddies** are five different nouns with different lifetimes — never defined together. [A5, A3, A7, A1, iOS]
2. **What a point is** and how a round becomes 5–12 points — needed on the first screen and before the wizard's dials; shown only on the post form and a hidden explainer. [A5, A1, iOS]
3. That this is a **team game**: squads exist, the league is split by a blind draw someone else triggers, squad points ≠ my points, and which squad is mine. [A5, A3, A6, A1, A4]
4. What **"the Pro"** is (organizer, not a club professional), what the job entails (byes, money, squads, endgame), what only the Pro can do — and therefore that "Lock it in", "Add golfers", "Share the invite link", "Turn off this link" and the buy-in checkboxes on *my* Home are not mine. [A3, A7, A6, A1, A2, A4]
5. What **bylaws** are, what **lock** freezes and when (three answers), and that the league code exists before any lock. [A5, A3, A1, A4, iOS]
6. That rounds posted **before first tee earn 0 league points** even though the form shows 5/6/12 (and Home says "Rounds count from today"). [A5, A3, A6, A1, A2, A4]
7. That the index I typed is a **"starter"** the app overwrites after 3 rounds; whose number the league scores against (my GHIN or the app's); what happens on the switch. [A5, A3, A2, A4]
8. That the **95% allowance** changes my number invisibly, and where it applies. [A5, A3, A2]
9. **Handicap vocabulary**: differential, rating, slope, 113, stroke index/SI, rated tees, attested, honor scores, WHS-style. [A5, A3, A1, A4]
10. That **"vs index" negative means worse** and positive better — the reverse of golf. [all seven web personas]
11. That "beat it by 3" is **differential vs index, not strokes**; why a 6 and a 22 get the same 12. [A2]
12. What **"GHIN rounds" / "Attested" / "verified"** require at post time (nobody attested my 91); that Standard does not actually require GHIN. [A5, A3, A7, A6, A2, A4]
13. How the **Cup Final** works: who plays, what "scored fresh" does to accumulated points, seeds, +10, "cut line after 2nd", LOCKED, "advances / seats", and how a squad wins 60%. [A5, A3, A7, A6, A1, A2, A4, iOS]
14. How **ties** break anywhere. [A2]
15. What **floor, month closes, bye** (automatic vs Pro-approved), **short months waived**, and **counting cap / best 4** mean and when they apply; which of three floor explanations is true. [A3, A7, A6, A1, A4, iOS]
16. What a **week** is (Sunday snapshot), why Sundays are "season dates", that season/weeks/months are three clocks, what Δ WK measures. [A3, A7, iOS]
17. That the **invite is a code**; friends must download the app and tap "I have an invite code"; there is no email/SMS invite; and what friends will be told (the covenant). [A5, A3]
18. That "Share the invite link" shows a code toast and "Share the card" silently downloads a PNG. [A6, A4, A2]
19. That there is a **$50/$75 buy-in** — before signing up; how, to whom and by when to pay it; that the pot sheet is a ledger only the Pro edits. [A5, A6, A1, A7, A4]
20. Who pays for **membership / Pro Shop**, how much, when it "lands"; what "the pilot" is. [A5, A3, A6, A4]
21. That **side games** live under the ⊕ LIVE door, post to the board, and touch neither the season table nor the pot; that Pot-tab "stakes" are never money and side-game cash is kept nowhere. [A5, A3, A2, A1]
22. How **Wolf, Sunningdale Rules, net best ball, skins carry-over, "strokes off the low man", "bank/units"** work. [A5, A3, A1, A7]
23. That the app estimates my index as **18.0** in live games, and that **any league member can add me to a live round and post a score to my card**. [A1]
24. That the **first tap on the live stepper sets par**. [A3]
25. **Where the rules live** (Clubhouse › League › collapsed panel; You › How it works) — Home and Clubhouse never point there; what "bylaws §4" is. [A5, A3, A7, A6, A4]
26. Which of five meanings of **"card"** a sentence intends (record / scorecard / profile / settlement / Post card). [A1, A4, iOS]
27. That **"Findable by: All"** is the default and anyone in the app can add me — or a stranger — to a league. [A5]
28. That the **✕** on a round deletes it (browser confirm, no undo, no edit). [A5, A6]
29. That the **install banner** must be dismissed before the ⊕ works. [A5]
30. That **"Use these defaults →"** just means Next. [A5]
31. What **"HELD"** means. [A7, iOS]
32. That **Home shows one league** (the last opened) and how to switch. [A7]
33. That **board dates are posting dates**, not play dates. [A7]
34. "Your number" vs "index" vs "number that day". [A7, A6]
35. What an **event / Major / The Ryder / Bracket** is relative to my league; "vs-index duels", "the clinch". [A7, A1, iOS]
36. That **"Schedule" leaves the Clubhouse**. [A7]
37. Whether a **rival's missing rounds** will cost them points. [A7]
38. What the **FORM dots, 📉 Personal best, "Diff 9.3", FOUNDER, moments/reveals** mean. [A7, A4, iOS]
39. That **"ball marker"** is an avatar, the famous-hole names are decorative, and what "Marker here" does; that "NO. 2" on the card is a marker, not a rank. [A6, A1, iOS]
40. That **"the board"** is both chat and feed; "Board 6 NEW TODAY" counts feed items; why it can be empty while Home shows 18 items; which league a pushed Board/Schedule belongs to. [A6, iOS]
41. What **Iron Man / Most Improved** pay (only Points King's 15% is stated). [A6]
42. That a **"Continue your round" banner** exists (it doesn't appear) and ⊕ → Play now resumes a round. [A1]
43. That **"Minimum four to tee off"** is a rule — revealed last, then not enforced. [A3]
44. That **"tee sheet"** = scheduled rounds and "NEXT · Open" is the calendar. [A3, iOS]
45. That **"Share the season"** is a public standings page. [A5]
46. That the **buddies graph** is separate from the league. [A4]
47. That the **⚑** beside 🔥 is "report", not a reaction. [A4]
48. That the **handle** follows the name and then locks for 60 days. [A5]

---

## 5. Severity re-check notes

Re-scored from the raw rows, honestly:
- **Upgraded to P0:** hidden $75 buy-in default (ORG-04 was P1; N-02 P0) — a money commitment made unseen, contradicting D46, landing in every invitee's covenant. Pre-season points contradiction (several P1 rows) — six of six testers hit it and two believed the post failed; it blocks "what did I earn" and "what do I do next".
- **Upgraded to P1:** the correction path (ORG-35 P3 / A26 P2 / N-12 P1 → P1): no discoverable answer to "wrong score?" at the point of need. Empty-standings projections (N-13) folded into the endgame issue at P1 because "TOP 1 ADVANCE" actively misstates the Final. Board-contradicts-Home (A16 P2 + IOS-03 P1 → P1): the social spine looks dead on two platforms.
- **Downgraded / merged:** the version placeholder (seven rows, some at P2) → one P3. Cosmetic date-format, odometer, signature-run-on and typography rows → P3. Live-stepper drop (A35) kept at P3 with confidence 4 (automation timing).
- **Kept as the tester scored it** where the evidence was solid and singular (e.g. Scrap-this-round dead, P1; one phone attests four cards, P1).

---

## 6. Prioritized backlog

Ordered by impact on understanding → activation → gameplay → retention → monetization, **not** by ease. Master IDs reference `issues.json`.

### P0 — fix before any meaningful launch
1. **M-001** Lock throws after commit (`staged.length`, index.html:15218); false "Lock failed"; share sheet never opens; later choices discarded.
2. **M-002** No invite-by-email/SMS; no invitation email exists; the Guide claims one.
3. **M-030** Members get the Pro's "Lock it in and invite your crew" → live lock button → "discard this league" (hero CTA at index.html:10102 has no role check).
4. **M-040** Pre-season rounds promise league points, deliver zero, and no surface says why; Home/Clubhouse/form disagree on whether rounds count.
5. **M-023** Consent sheet withholds roster, Pro, dates, scoring and payment path before a $50 commitment; the door and invite landing explain nothing.
6. **M-004** Buy-in defaults to a hidden $75 behind "Customize".

Ride with the P0s (same code paths): **M-017** generic error mapping hides actionable messages; **M-003** invite link never displayed; **M-031** You tab renders the wizard; **M-041** one league-state string.

### P1 — before scaling past the founding leagues
*Understanding / rules:* M-055 endgame invisible (Cup Final, seeds, LOCKED, advances) · M-056 ties · M-057 floor explained three ways · M-058 team structure never introduced · M-054 rules four taps deep / How-it-works buried · M-046 band unit and overlapping edges · M-047 one round, two numbers · M-045 sign convention · M-044 posted card/receipt without points or status · M-051 starter vs GHIN precedence · M-059 hero pills undefined · M-026 "Standard" undefined · M-011 verification vocabulary · M-010 preset jargon · M-009 squad/seed/+10 worked examples · M-006 three lock moments · M-007 minimum four revealed last · M-008 Teams control contradicts itself · M-102 iOS live screen untitled · M-144 iOS never defines the game · M-145 iOS 14 vs 13 weeks.
*Navigation / next step:* M-033 member Home leads with creation · M-070 Schedule exits the room · M-072 one league on Home · M-018 install banner covers the ⊕ · M-076 rating/slope placeholders and −79.0 · M-080 no correction path · M-024 landing copy lies · M-025 "Not now" drops the invite · M-129 race below the fold / gap line on wrong row · M-084 Board contradicts Home.
*Trust / consent:* M-093 one phone attests four cards; a 103 lands on a card unasked · M-019 global directory, Findable-by-All default · M-085 live-resume query fails on every boot; banner never appears · M-090 Scrap this round dead · M-120 board dates vs standings counts.
*Retention / money:* M-123 no rival, gap or "this round matters" · M-110 how to pay the pot; $0 collected; fake checkboxes · M-143 cold door explains nothing.

### P2 — after PM signal
M-042 pre-season floor pressure · M-043 "No league yet?" boilerplate · M-032 draw tool exposed to members · M-012 Pro Shop / membership undefined · M-062 money nouns collide · M-063 game rules absent until selected · M-064 side games vs season unstated · M-049 95% never applied visibly · M-048 circular receipt for <3 rounds · M-050 starter index shown two ways · M-052 bands vs variance (design decision to log) · M-060 jargon cluster / §4 / R column · M-061 "card" ×5 · M-071 FAB overlaps · M-073 board oldest-first · M-074 round entry points / NEXT tile / tee sheet · M-075 boot shows the door · M-077 duplicate courses + 502 on tees · M-078 stacked post-round sheets · M-079 trivial/duplicate/stale trophies · M-082 feed badge logic + odometer a11y · M-086 502s on core writes · M-087 unlabeled 19.7 · M-091 stepper opens on par · M-092 ambiguous finish buttons · M-094 estimated 18.0 decides strokes · M-095 side-game money off the books · M-096/M-097 settlement headline and math · M-099 pride-stake settle · M-100 Share the card silent · M-111 pot tiles don't sum; squad split · M-121 index delta three ways · M-122 three clocks / Δ WK / dead calendar rows · M-124 no finale rail · M-125 no share on shareable objects · M-126 no emails · M-127 rivalry tokens · M-128 cross-league leakage · M-130 squad copy in solo league · M-131 changelog board posts · M-132 player receipt lacks course/gross/sum · M-133 value loop invisible pre-season · M-136 notification toggles · M-137 report flag beside reaction · M-138 member row sheet · M-139 ball marker unexplained / "NO. 2" · M-146 iOS calendar drops days 1–5 · M-147 iOS THIS WEEK / QUIET · M-148 iOS buddies list · M-149 event blurbs · M-150 iOS post form · M-153 iOS clubhouse header · M-005 buy-in steps · M-014 "Start the league" · M-016 dead-end screens · M-020 Pro can't preview the covenant · M-021 "3 seats open" · M-022 delete outranks invite · M-027 four names for the code · M-028 stacked sign-in rows · M-029 sign-in email subject/threading.

### P3 — polish
M-013 · M-015 · M-053 · M-081 · M-083 · M-098 · M-101 · M-134 · M-135 · M-140 · M-141 · M-142 (version placeholder) · M-151 · M-152 · M-154 · M-155.

---

## 7. What held up (for calibration)

Every persona independently praised: the course search → tee pick → rating/slope autofill; the live point-bands panel on the post form; the receipt's differential arithmetic; the live scorer's stroke line ("Marco gets 4: holes 3, 6, 16, 18"), running skins ledger and settlement card; guest play without an account; the "Finish the round" dialog's honesty about partial cards; the "How scoring works" copy itself. The side-game verdicts (7–8/10 from the two organizers and the competitor) are the product's best retention lever. The audit's core message is that the season wrapper — setup, invite, consent, status, endgame, money — undoes the trust those screens earn.
