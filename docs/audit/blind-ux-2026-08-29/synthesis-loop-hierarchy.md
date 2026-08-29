# Blind UX audit 2026-08-29 — Synthesis: gameplay loop, information hierarchy, competition visibility

**Scope.** Eight blind persona passes (organizer, league novice, retention observer, new joiner, casual, competitive, skeptic, iOS screen survey) against the local web client at `http://127.0.0.1:8791/` and the native iPhone app. This document synthesizes them along three axes: (1) the loop as testers actually experienced it, (2) the information hierarchy of every major screen, (3) whether competition is visible.

**Evidence conventions.**
- `raw/agent5-organizer.md` = **ORG**, `raw/agent3-league-novice.md` = **NOV**, `raw/agent7-retention-observer.md` = **OBS**, `raw/agent6-new-joiner.md` = **JOIN**, `raw/agent1-casual.md` = **CAS**, `raw/agent2-competitive.md` = **COMP**, `raw/agent4-skeptic.md` = **SKEP**, `raw/ios-screen-survey.md` = **IOS**.
- Screenshots are cited as `shots/<session>/<file>.png`. **Base path:** `screenshots/`. Note: the frames were later copied into `docs/audit/blind-ux-2026-08-29/screenshots/<session>/` as `.jpg` (downsampled); paths in this file were rewritten accordingly.
- **OBSERVATION** = what a tester saw on screen (quoted copy). **INTERPRETATION** = what it means for the loop. **INTENT** = what the product's own sources say was meant (`spec/spec-v1.0.md` cited as §n, `spec/decision-log.md` cited as Dn, `spec/product-vision-v1.0.md`, `Cup-Season-Guide.md`, and `index.html` line numbers for the shipped behaviour). These three are kept separate throughout. Where the spec explains something the UI did not, that is recorded as a finding, not an excuse.
- Scores are 1–10, my judgement across all eight reports, with the evidence that drove them.

**Caveats on evidence quality (carried from the raw reports).** Three accounts (CAS, COMP, SKEP) opened already signed-in from an earlier interrupted run; their sign-up screens are cited from the earlier run's screenshots. The headless browser could not show native share sheets or read the clipboard, so every "Share…" finding is about the *visible fallback*, not the phone. The harness auto-accepted native `confirm()` dialogs. Two testers disagree on "Scrap this round": NOV saw a two-tap red confirm (`screenshots/nov/93-scrap-confirm.jpg`), CAS found the button dead three ways (`screenshots/cas/93-L03-scrap-test.jpg`) — treat as unresolved. Both mid-season leagues on the OBS account have exactly two players, which makes every "who is my biggest threat" question trivial and "EVERYONE ADVANCES" literally true.

---

## 0. The verdict in one paragraph

The loop has one genuinely strong beat — **enter result** (course search → tee → rating/slope autofill → live points preview → a receipt with the differential arithmetic) — and one strong side-loop (live skins/match play with strokes off the low man and a netted settlement). Everything downstream of the posted round leaks energy: the form promises points, the ceremony withholds them, the table shows zero, and nothing says why (7 of 7 posting testers hit this). The sign on "vs your index" is read backwards by golfers on three surfaces (6 of 7). Upstream, the member's Home leads with the organizer's lock button and a guilt bar. The endgame — the thing the product is named after — exists as one bylaws row four taps deep; no tester could explain how the Cup Final is won (8 of 8). Competition is legible on exactly one surface (a mid-season Home hero with a name and a gap) and nowhere pre-season. The product knows all of this: D4 (2026-07), D24, D26, D51, D52, D81, D105 each name the missing beat. Several are built server-side (season_scenarios, week_clashes) or in the client (the clash chip, `renderClash`, `index.html:4613`) and were not visible in any league any tester touched.

Persona scores, for orientation: rulesClear 3–5 across all eight; stakesMeaningful 3–6; wouldInvite 3–6; wouldPay 2–5. The highest single scores in the whole audit are sideGamesCompelling 8 (ORG, COMP).

---

## 1. The micro loop as experienced

The loop the brief asks about — *Before round → choose/see competition → play golf → enter result → see outcome → see season impact → compare against friends → anticipate next round* — was walked by every persona with a posting account (ORG, NOV, JOIN, CAS, COMP, SKEP) and read-only by OBS. Each transition below gets: what testers saw, what it means, what was intended, five scores, and the evidence.

Scoring key: **Clarity** (does the golfer know what is happening), **Motivation** (does it make them want the next step), **Friction** (10 = frictionless), **Emotional payoff** (does it land), **Information quality** (is what is shown true, complete, and consistent).

### T1 · Before the round → choose / see the competition

**OBSERVATION.**
- Pre-season member Home (JOIN, CAS, COMP, SKEP — `screenshots/join/21-P-home-member-full.jpg`, `screenshots/skep/09-home-full.jpg`): hero "THE PAPAGO GRIND · FORMING · 7 days to first tee. 5 golfers in. The bylaws lock at the tee." with the only button **"Lock it in and invite your crew"**; below, "NEXT · Open · PLAN A ROUND", "MONTH CLOSES in 2 days", "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points…". Four of four players read the lock button as an instruction to them (JOIN §5, CAS §4, COMP timeline 15:32, SKEP "Three deliberate probes" #1); it opens "CREATE YOUR LEAGUE · REVIEW THE BYLAWS" with a live **"Lock the bylaws & form the squads"** (`screenshots/join/39-U-lock-it-in.jpg`, `screenshots/skep/50-lock-page.jpg`). CAS and COMP also found the **You tab rendering the wizard** from Home (3/3 repro; `screenshots/cas/02-R01-you-tab.jpg`, `screenshots/comp/49-you-after.jpg`).
- "What round am I supposed to play?" — every poster answered "I don't know; there is no round" (ORG J-D Q1, NOV Q1, JOIN Q1, CAS Q1, COMP Q1, SKEP Q1). NOV read "NEXT · Open" for twenty minutes as "the next league round is open" (NOV N-20); it is the tee-sheet calendar.
- Mid-season Home (OBS `screenshots/obs/05-home-full.jpg`): "FELLAS · WEEK 6 OF 26 · **1st** · — HELD · You lead by 22 points over Jade. · AUG FLOOR 1/2 ▬▬ 1 MORE · 2D", tiles "NEXT · FRI · QUINTERO GOLF…". This is the only surface in the audit where a golfer sees a named opponent and a gap before playing. The second league (where he is losing) is invisible on Home until he opens it in the Clubhouse (OBS issue 4).
- No screen anywhere told a golfer what their next round is *worth* ("post X to take 2nd", "your 4th counter is a 6 — beat it"). The only forward-looking copy is the floor bar ("1 MORE · 2D") and the month-close pill, which CAS called "the opposite of a reason to open it; it's a reason to feel guilty" (CAS §7).
- No tester saw a weekly clash chip.

**INTERPRETATION.** Before a round, the app answers "what is the state of the league" (for the Pro) or "what are you late on" (for a member), never "what is at stake for you today". Pre-season the member's dominant call-to-action is someone else's job; the season copy leaks admin state ("The bylaws lock at the tee") into a player's first read.

**INTENT.** D81 (Home as a state machine, 2026-07-27) explicitly resolved this: "the hero always renders the MOVE and its cause… and on quiet days points forward ('beat your number by 3 Saturday and you take 2nd')". The shipped `heroMyRung()` (`index.html:10190-10198`) renders only "You lead by N over X" / "N back of X" / "Level with X. Your next round breaks the tie." — the forward line exists only for the tie case. D96 made the forming hero's CTA the lock step "because inviting has no pre-lock step" and `renderHomeHero` (`index.html:10101-10110`) does not gate the button on `is_commissioner` — hence a player sees it. D51 (the stake line, DECIDED 2026-07-21) is the exact missing beat; `grep` finds no stake-line surface in `index.html`. D52/D108 (weekly clash) is built (`renderClash`, `index.html:4613`) but rides `week_clashes`, which no audited league had a row in.

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 3 | 3 | 5 | 2 | 3 |

Evidence: JOIN J-02 (P0), CAS A1/A2, COMP C-03/C-04, SKEP SK-07/SK-08, OBS issues 4/5/6, NOV N-20, `screenshots/join/21-P-home-member-full.jpg`, `screenshots/obs/05-home-full.jpg`.

### T2 · Play golf → enter the result

**OBSERVATION.**
- Reaching the ⊕: the "Get the full-screen app" banner sat exactly on the FAB; two taps did nothing until "Not now" (ORG ORG-09, `document.elementFromPoint` verified; `screenshots/org/84-live-door2.jpg`). NOV hit the banner's "Add" instead of the guest "Add" (NOV N-27). The FAB overlaps body copy on Home, the wizard, the Clubhouse and the board on every full-page screenshot (NOV N-34, OBS issue 8).
- The ⊕ door (`screenshots/org/61-post-sheet.jpg`): three cards — "● LIVE Play now — score the group live", "Post a round — after you play · Gross + tee, 20 seconds", "Plan a tee time — before". All testers found it and called the before/during/after model the first thing that "clicked" (ORG J-D, NOV, SKEP). Side games were discovered here without instruction by all seven web testers.
- The composer (`screenshots/org/62-post-round-form.jpg`, `screenshots/nov/65-post-form.jpg`): course search → tee list with rating/slope → autofill. Praised by NOV ("excellent — the scary rating/slope boxes disappear"), SKEP ("better than 18Birdies' course picker"), COMP. Failure modes: Rating/Slope placeholders "72.1 / 128" read as filled values (CAS A5, IOS 1.8); typing the nines before picking a tee closed the tee list and produced "**-79.0 vs your index**" in red with Post still enabled (CAS `screenshots/cas/48-F06-scores-entered.jpg`; COMP saw "-77.6"); "Papago Golf Course · Phoenix, AZ · 13 tees" listed twice in every session that searched it (ORG, NOV, JOIN, CAS, COMP); a 502 on the first tee pick (JOIN J-22) and 502s during Post (CAS A28, SKEP SK-31, COMP).
- Live scoring (`screenshots/org/88-live-scoring.jpg`, `screenshots/nov/91-live-h1.jpg`, `screenshots/comp/56-live-hole18.jpg`): setup blurb writes the first-tee argument for you ("Strokes off the low man (Priya): Casey gets 9 — the 9 hardest holes · Marcus gets 6: holes 3, 6, 9, 16, 17, 18") — the most-praised copy in the audit (ORG, COMP, CAS). Friction: the stepper's first tap lands on par, unannounced — NOV tapped + six times on a par 5 and got 10 (NOV N-22; ORG ORG-38); "Scrap this round" dead for CAS (A6) and a two-tap confirm for NOV; the promised "Continue your round banner… on Home" never appears and every boot logs `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` (CAS A8, ORG, NOV, SKEP, JOIN — five sessions).

**INTERPRETATION.** This is the strongest transition in the product. The 20-second promise is kept once a course is picked; the live scorer is the part testers would actually use on Saturday. The failures are all mechanical (occluded FAB, placeholder-as-value, unguarded blank rating, duplicate course rows, silent par-on-first-tap) rather than conceptual.

**INTENT.** D34 (two boxes), D82 (three tenses at the door), D110 (live leads, ember) all landed as designed. Vision principle 2 ("posting a round in under 60 seconds") is met when the course picker cooperates.

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 7 | 6 | 5 | 6 | 6 |

Evidence: ORG ORG-09/33/38, NOV N-22/27/34/35, CAS A5/A6/A8/A25/A28, JOIN J-22, COMP timeline 15:42–15:55, SKEP SK-31, `screenshots/cas/48-F06-scores-entered.jpg`, `screenshots/org/84-live-door2.jpg`.

### T3 · Enter the result → see the outcome

**OBSERVATION.** One round, three verdicts, ten seconds apart, in every posting session:
1. Live preview on the form: "LEAGUE POINTS THIS ROUND **6** · A little loose, still cash in the bank. · 87 GROSS · **-1.7** VS YOUR INDEX" (ORG `screenshots/org/68-round-filled.jpg`; NOV "5 · -3.7"; JOIN "5 · -3.9"; CAS "5 · -9.8"; SKEP "5 · -6.7"; COMP "12 · +5.0 · You torched your number by 5.0. Sandbagger alert.").
2. The ceremony: "87 · **1.7 over your number** · COUNTS ON YOUR CARD · [Share the card]" (`screenshots/org/69-after-post.jpg`, `screenshots/nov/72-posted.jpg`). No points figure. Behind it, a stacked "Welcome to the season ⛳" sheet with "🏆 You broke 90 for the first time · 🏆 You broke 100 for the first time" for a first-ever posted 87, "Your first round is on the board" listed twice, and "[Turn off this link] — The page stops working for everyone who has it" for a link nobody made, plus the install banner — three stacked dialogs after one tap (NOV N-25, JOIN J-25, ORG ORG-21).
3. The receipt: "87 − 70.1 × 113 ⁄ 120 → 15.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 14.2 · Against your number **-1.7 — A LITTLE LOOSE**" (`screenshots/org/71-round-detail.jpg`). ISO date. No points row. No edit/delete control.
- CAS, with no index, got a fourth verdict: receipt "27.8 DIFFERENTIAL · YOUR NUMBER THAT DAY 27.8 · +0.0 — PLAYED TO IT" for a round the form had called -9.8 (CAS A4/A19).
- Six of seven web testers independently flagged the sign: "a golfer reads minus as under = good; the app means worse" (ORG ORG-06, NOV N-04, JOIN J-04, CAS A4, SKEP SK-10, OBS issue 11, COMP UA/APB list). OBS: "Avg vs index -4.0 (red)" while his rounds "beat his number".
- "Share the card" → hidden status "Card downloaded", nothing visible (SKEP SK-16, JOIN, CAS, COMP "no visible feedback").
- In-season receipts DO carry points: Galen's 79 shows "Points 9 · This month COUNTING #1" (`screenshots/obs/37-round-card.jpg`). Pre-season receipts do not.

**INTERPRETATION.** The moment of maximum attention — the golfer has just typed a score — is spent on a number whose sign reads backwards, a promise (points) that vanishes on the next screen, and three stacked celebrations for milestones that do not exist yet. The receipt is the one place the product keeps its §16 promise, and it is the screen with the least emotional design.

**INTENT.** §2.1 defines PvI as "Playing Index − Differential… positive = you beat your number" — the app is faithful to the spec's sign, and golfers read it as golf's. D1 chose "beat your number by 1.4" as the display precisely to avoid a bare signed number; `vsPhrase()` (`index.html:5709-5714`) does that on the ceremony, but `calcVs` (`index.html:6339`) and the receipt print the raw signed PvI. D2 said two numbers survive on the card: *gross and points* — the ceremony shows gross and a phrase, no points; `finishCeremony` (`index.html:6187-6192`) deliberately falls to "COUNTS ON YOUR CARD" when `counts` is false (round outside the season window, `index.html:6584-6596`) and the comment says this "matches the app's own 'practice rounds hit your card' promise" — but the ceremony never *says* that. D3 promised "a 4-slot fill meter… displaced rounds shown grayed with 'bumped by your 81 ✓'" — the in-season board card does say "COUNTING #2 THIS MONTH" (`screenshots/obs/45-the-board-link.jpg`), which is the closest shipped surface. D95 gave the receipt its working; it did not give it a points row for pre-season rounds or a correction path.

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 3 | 5 | 4 | 4 | 5 |

Evidence: ORG ORG-05/06/21/35/37, NOV N-04/12/25/26, JOIN J-03/J-04/J-21/J-25, CAS A3/A4/A17/A18/A19/A26, SKEP SK-09/SK-10/SK-16, COMP C-05/C-07, `screenshots/org/68`, `69`, `71`, `screenshots/nov/72-posted.jpg`, `screenshots/obs/37-round-card.jpg`.

### T4 · See the outcome → see the season impact

**OBSERVATION.**
- Pre-season (six posting testers, one league): the form said 5–12 points; Standings showed "0 R · — · 0 Pts" for every member, including three whose rounds were in the feed that day (`screenshots/join/23-Q-clubhouse-full.jpg`, `screenshots/comp/40-standings-after74.jpg`, `screenshots/skep/37-standings-after.jpg`). Tapping one's own row: "No rounds this season yet — post one and you're on the board." (JOIN `screenshots/join/52-AE-marcus-row.jpg`, COMP) — an instruction the tester had just followed. You tab: "LIFETIME · Rounds posted 1 … THIS SEASON · ROUNDS POSTED 0". Not one of the six screens involved (form, ceremony, receipt, standings row, You, Home) said "the season starts Sat Sep 5".
- The only pre-season explanation exists on the Pro's Clubhouse kickoff card: "BEFORE FIRST TEE · KICKS OFF IN 7 DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (NOV `screenshots/nov/36-clubhouse-full.jpg`) — while NOV's Home simultaneously said "DESERT DOGS · SEASON LIVE — The season's on. **Rounds count from today.**" (NOV N-03). Members of the Papago Grind never saw the kickoff card at all (their Standings opened on "SQUADS ARE FORMING · The Pro has the list.").
- Same-day counters: "COUNTING ROUNDS 0/4 · August · your best 4 count" and "MONTH CLOSES in 2 days" for a season starting in September (NOV N-16, CAS A9, COMP UA).
- Mid-season (OBS): the board card is the best surface — "85 GROSS · A LITTLE LOOSE · COUNTING #2 THIS MONTH · -1.2 · 6 PTS" (`screenshots/obs/45-the-board-link.jpg`). But: the board showed two Aug 27 rounds while Standings said "you've posted 1" this month and Home said "AUG FLOOR 1/2 · 1 MORE" (OBS issue 2 — data contradiction, unresolved); the Home story said "Beat your number by 3.3" for a round whose receipt says "+2.6 vs index · 9 PTS" — by the band table 3.3 would be 12 (OBS issue 3); "Δ WK +10" with no round in two weeks (OBS issue 21); the index moved "▼ 1.1", "▲ 1.2" and "12.2 → 12.6" on three surfaces (OBS issue 20).
- The player receipt from a standings row (`screenshots/obs/10-my-row.jpg`) lists dates + vs-index + PTS only — no course, no gross, no total line; OBS added 9+5+5+6+7 by hand.

**INTERPRETATION.** This is the transition where the loop dies. The app breaks its first promise to a new member (points) without a sentence, and the only sentence that would fix it exists on a card only the Pro sees, contradicted by the Pro's own Home. Mid-season, the impact is shown well on one card and contradicted by three counters.

**INTENT.** `v_rounds_ranked` scores pre-season rounds at 0 by design (§14.1 "dates are structural"). The client knows the window (`counts` in `index.html:6590`) and uses it only to *withhold* the points line — the same boolean could produce "Season starts Sep 5 — this one builds your number." §16: "no points figure without a path to the rounds that produced it" — the standings row's "0 · post one and you're on the board" fails this in reverse: a figure with a false path. D53 (month-close podium) and D24 (scenarios) are about later in the month; nothing in the decision log addresses the pre-season posting experience for a member.

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 2 | 3 | 6 | 2 | 3 |

Evidence: ORG ORG-05/22, NOV N-03/N-16/N-26, JOIN J-03/J-11/J-18, CAS A3/A9/A24, COMP C-05, SKEP SK-09/SK-12/SK-27, OBS issues 2/3/12/20/21, `screenshots/nov/34-reload-home.jpg` vs `screenshots/nov/36-clubhouse-full.jpg`.

### T5 · Season impact → compare against friends

**OBSERVATION.**
- Mid-season Home hero: "1st · You lead by 22 points over Jade" — answered in 0 taps, ~3 s (OBS Journey E). The Clubhouse Climb: "01 Jerecho F… LOCKED 32 / 02 Jade LOCKED 10 · Jade 22 behind you · EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (`screenshots/obs/07-league-full.jpg`). Below it a second table (PLAYER · TREND · Δ WK · PTS), a caption "JERECHO FISCHBECK HAS LOCKED A CUP SEED", four stat tiles, and a third table (THE INDIVIDUAL RACE) — three tables for two people (OBS issue 25). The race sits below chips + season card + segmented control + a progress bar, i.e. below the fold on a phone (OBS "3 s: the race itself is below the fold"; IOS 1.2 same).
- Pre-season with five members: Standings all zeros; the feed shows **gross only** ("Sam 91 · Jordan 97 · Priya 84 · Priya 74") — "the app scores against each person's number, so gross tells me nothing about points" (JOIN §8); "Priya's 74 is in the feed as a number, not as 'Priya just torched it for 12'" (SKEP §Social objects). The only index comparison is Members & invites (Priya 6.4 · Sam 15.2 · Casey 14.2 · Marcus 12.0). Tapping a rival's row opens "0 ROUNDS · 0 PTS · [Post a round]" (JOIN J-20 — "reads as posting for them").
- Empty-league Standings (NOV `screenshots/nov/36-clubhouse-full.jpg`): "TOP SEED · +10", "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING", "CAPT. —", "WK 1" for two empty squads (NOV N-13).
- Squads: "SQUADS ARE FORMING · The Pro has the list." (Standings) vs "Squads · LIVE NOW — CAPTAINS READY" (League tab) vs "Squad 1 · 0 PLAYERS · Empty" (See the squads) — all seven web testers logged the contradiction; no player ever learned their squad (JOIN J-09, CAS A12, SKEP SK-15, ORG ORG-10, NOV N-10, COMP).
- Rivalry surfaces: You › "RIVALRIES · YOUR RECORD · Jade 2 weeks head-to-head 2–0 · Galen 1 week head-to-head 1–0" (`screenshots/obs/29-you-full.jpg`) — records from live match play, not the season; "weeks" unexplained. Find golfers shows "Casey @casey · Requested" and nothing else — "a result row is not tappable — no profile, no head-to-head" (COMP timeline 15:58).
- iOS: gap line "10 back of Galen" rendered under Galen's row, above the divider that starts the viewer's row (`screenshots/ios/03-clubhouse.jpg`, IOS 2.4); Home "2nd" with no "of 2" and no leader named (IOS 1.1).

**INTERPRETATION.** Comparison works for a two-player league in week 6 and fails for a five-player league in week −1. The product's own vocabulary of the race (seed, locked, advances, contenders, seats, generous ceiling, +10) is projected onto a table with no data, which reads as noise, and the moment a real field exists (five members, four rounds today) the feed speaks only in gross.

**INTENT.** D26 (The Climb) designed "your row, the rung above, the rung below, the leader, and the cup line… points-back labels" — shipped (`index.html:4430-4480`), and it works with two rows. D24's "honesty rule" is why the caption says "PROJECTED UNDER A GENEROUS CEILING"; the rule was for the engine's math, not for a caption on an empty table. D19 (christened rivalries) and D21 (callouts) are logged; the shipped rivalry facet is the live-match record only. D2's "84 · beat your number by 0.6 → 7 pts" is what a feed card should say; the pre-season feed card says "91 GROSS · First round on the card".

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 4 (7 mid-season / 2 pre-season) | 5 | 5 | 5 | 4 |

Evidence: OBS Journey E + issues 13/25, JOIN §8 + J-09/J-20, SKEP SK-15/SK-26, NOV N-13, CAS A12/A13, COMP "RIVALRY", IOS 2.4/2.9, `screenshots/obs/07-league-full.jpg`, `screenshots/join/23-Q-clubhouse-full.jpg`, `screenshots/nov/36-clubhouse-full.jpg`, `screenshots/join/33-S-see-squads.jpg`.

### T6 · Compare → anticipate the next round

**OBSERVATION.**
- "If I win my next round?" — "Not projected… no 'if you post X you…' line anywhere" (OBS Journey E). "What do I need to do to win?" — "Not answered anywhere" (OBS). "Next round matters because…: none" (COMP "RIVALRY"). "Nothing says 'post one more to lock your 4th counter' or 'Casey is 3 points ahead'" (COMP).
- What does exist: the floor bar "AUG FLOOR 1/2 · 1 MORE · 2D", the "NEXT UP · AUGUST · Post 1 more round this month — best 4 count, you've posted 1. [Live round]" card (`screenshots/obs/07-league-full.jpg`), "MONTH CLOSES in 2 days", and the NEXT tile pointing at a tee-sheet round ("FRI · QUINTERO GOLF…"; on the calendar "Galen BUDDY · FRI SEP 4 · you lead 1–0 · YOU'RE IN · 'Major'" — four undefined tokens, OBS issue 23, IOS 1.4).
- The Cup Final: "the ONLY place the app told me the season ends with a 'Cup Final · final 4 weeks · scored fresh'" is League › ▶ LEAGUE RULES & PRO SHOP › bylaws (OBS; `screenshots/obs/21-bylaws-open.jpg`). Same for JOIN, CAS, COMP, SKEP, ORG, NOV. "Scored fresh" was defined by nobody; COMP: "Do the first 13 weeks matter at all if the final 4 are 'scored fresh'?" Confidence 2/10 (COMP rules table), 4/10 (NOV).
- The only reasons testers gave for wanting to play next: a $5 skins game (ORG, NOV, CAS, COMP — "skins at $5 mattered more to me than the season points did today"), a tee time with a buddy (CAS), and one specific person (OBS: "To beat Galen — he's the only name the app made me care about").
- Nothing in the season UI points at the side games: "the Pot tab says 'Post a stake · The cookout isn't going to bet itself' and never links to Live games; nothing in the wizard or league room says your buddies can run match play / Wolf / skins inside the season" (ORG side-game verdict; NOV "one tap deeper than it should be"; CAS "nothing on Home, the welcome sheet or the how-scoring sheet ever says side games exist").

**INTERPRETATION.** Anticipation is manufactured by fear (floor, month close) and by things the user typed (a pride stake, a tee time), never by the season's own arithmetic or its ending. The strongest retention lever the testers found — the live side game — is disconnected from the league room that is supposed to be the retention surface.

**INTENT.** D24 (magic number / clinch / cut line — "'your Sunday round matters because…' becomes literal") and D51 (stake line — "the one-more-round rule as a mechanic", "highest value-to-effort item in the backlog") are the two named fixes; D24's engine ships (`season_scenarios`, used by `climbCut`), D51 is unbuilt. D4 ("season-long foreshadow… 'Season crowns 4 Cup seeds · Cup starts fresh Aug 30'") was the fix for the finale's invisibility in July; the shipped foreshadow is the bylaws row and a "LOCKED" pill. D105 (2026-08-28, PROPOSED) admits "the flagship moment of the product is invisible". D52/D108: the clash is the intended weekly appointment; the chip is coded, no tester's league had a clash.

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 3 | 4 | — | 3 | 3 |

Evidence: OBS Journey E/F/G + emotional-loop table, COMP "RIVALRY"/"STRATEGIC VERDICT"/C-11/C-12/C-33, ORG side-game verdict, NOV empty-league section, CAS §7, SKEP SK-35, `screenshots/obs/21-bylaws-open.jpg`, `screenshots/obs/13-sub-Schedule.jpg`.

### T7 (implicit) · The social return — the board, reactions, sharing

Not in the brief's list but every persona treated it as part of the loop, so it is scored.

**OBSERVATION.** The Clubhouse board is oldest-first with the compose box under the newest post (OBS issue 15; `screenshots/obs/19-sub-Board.jpg`); the ⚑ beside 🔥 is "Report this post" with no label (SKEP SK-19); the match-play scorecard with gold holes (`screenshots/obs/42-matchplay.jpg`) and the skins scorecard (`screenshots/cas/87-K04-scorecard.jpg`) are "the best-looking objects in the app — and they have no share/export control" (OBS issue 18); the settlement sheet has three share buttons and a revoke, none producing visible output in the harness (ORG `screenshots/org/92-settlement.jpg`); side-game cash "lives only as a board card" — the Pot tab's "other stakes" are "never money" (COMP C-28, NOV N-24, ORG ORG-24). Zero product emails or pushes reached the OBS account in 60 days beyond sign-in codes (OBS issue 19). iOS Board: "◆ Your league is live — post the first round" under TODAY while Home shows 18 items (`screenshots/ios/04-board.jpg`, IOS 2.3).

| Clarity | Motivation | Friction | Emotional payoff | Info quality |
|---|---|---|---|---|
| 5 | 5 | 4 | 6 | 4 |

### Where does the loop lose energy?

Ranked by how many personas hit it and how much of the loop it strands:

1. **T3→T4, "did that count?"** Every posting persona (6/6) left the first round unable to say whether it earned anything; four of six wrote a verbatim "I think it's because the season doesn't start till the 5th, but nothing on the screen said that." The form promises, the ceremony withholds, the table zeroes, the row lies ("post one and you're on the board"). This is the single most-cited break in the audit.
2. **T5→T6, "what do I do about it?"** No projection, no stake line, no named rival from the app, an endgame that exists as one bylaws row. OBS's lifecycle scores fall from 6 mid-season to 3 at season+1 day to 2 at +30 days for this reason.
3. **T1, the member's Home.** The biggest button is the Pro's; "what should I do this week" is answered with a guilt bar. Four players tapped it; two of them ended up inside the creation wizard from the You tab.
4. **T3, the sign.** Not a break in flow but a break in trust: the same round is "-1.7", "1.7 over", and "-1.7 — A LITTLE LOOSE". A golfer who reads minus as good either mis-celebrates or distrusts the engine.
5. **T2 mechanics** (FAB occlusion, placeholder-as-value, dead scrap, duplicate course, 502s) are real but recoverable; they cost taps, not belief.

---

## 2. The macro loop — where exactly it breaks

*Join → Understand → Play → Result → Standings → Rivalry → Next round → Season finale → Next season*

| Stage | Status | Where it breaks (observation) | Intent it collides with |
|---|---|---|---|
| **Join** | **Breaks at consent** | Link landing: "You're invited to The Papago Grind. Enter your email and you're in." (`screenshots/join/02-B-join-link-landing.jpg`). Actual flow: email → code → golfer card → orientation → "Before you join… BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks · [Join — I'm in for $50]" (`screenshots/join/11-J-after-take-me-in.jpg`). No roster, no organizer name, no dates, no scoring, no payment path before the $50 button (JOIN J-01 P0, 3/10). "Not now" drops the invite; code must be retyped (J-06). No invitation email exists for any invitee (JOIN, COMP, CAS, SKEP all searched Gmail). The Pro never sees what invitees see (ORG ORG-28). Only an 8-char code is ever shown; the `?join=` URL is never displayed (ORG ORG-03, NOV N-05, CAS A22, SKEP SK-17, JOIN J-27). Wizard default buy-in **$75** hidden behind "Customize" (ORG ORG-04 P1, NOV N-02 P0). | Vision success metric "join a league in under 30 seconds"; §7 default $75 is per spec — the spec is the source of the hidden default. D40 gated invites on lock; D97 removed the pre-lock invite path; the Guide (§Start a league) still says "add golfers (find them by name or @handle, **or invite by email**)" — the email path does not exist in the client (ORG ORG-02, NOV N-05). |
| **Understand** | **Breaks** | The rules live at Clubhouse › League › ▶ LEAGUE RULES & PRO SHOP › [How scoring & handicaps work →] (four taps, collapsed) or at the bottom of You. The welcome sheet's "How scoring works →" (`screenshots/org/95-join-link-view.jpg`) is the one good pointer, and that sheet never mentions squads, the Cup Final or the pot split. "THREE THINGS TO KNOW" lists four (5 testers). rulesClear: ORG 5, NOV 5, OBS 3, JOIN 5, CAS 3, COMP 4, SKEP 4, IOS 3. Vocabulary debt: each persona logged 15–20 undefined terms; the union is ~60 (Pro, Pro Shop, bylaws, lock, squad, staged, pool, seats, seed, scored fresh, attested, allowance, Points King, floor, bye, short month, tee sheet, snapshot, HELD, LOCKED, the climb, contenders, Sunningdale, bank a unit, riding, SI, net best ball, card ×5 meanings…). The verification value reads "GHIN rounds" on the preset and "Attested" on the review; "attested" is defined only on the live scoring screen after tee-off (ORG ORG-07, NOV N-11). | D82 put orientation on one screen and "depth at the doors"; the doors do explain themselves, the league room does not. D1/D2/D47 (noun sweeps) reduced jargon on the round card and left it in the room. Vision: "never need a tutorial" — the product ships five tutorials at the bottom of You. |
| **Play** | Holds | See T2. The composer and the live scorer are the two things every persona would keep. | D34, D82, D107, D110 landed. |
| **Result** | **Breaks** | Sign inversion (6/7); points promised and withheld (6/6); three stacked dialogs; milestone badges for first-ever rounds; badges survive round deletion (COMP); no correction path on the card or receipt (ORG ORG-35, NOV N-12, CAS A26). A 103 landed on CAS's card from someone else's live game with no notification or "that wasn't me" (CAS A7 — the attestation model as experienced by a stranger to it). | D1 (phrase, not sign), D2 (gross + points), D95 (receipt shows work), §9 (rounds immutable; delete only). |
| **Standings** | Half-breaks | Mid-season two-player: works in 3 s on Home. Pre-season five-player: zeros, gross-only feed, squads undrawn and contradictorily labelled, tapping a rival = "Post a round". Three tables for two people; the race below the fold; captions from D24's engine ("GENEROUS CEILING", "LOCKED", "2 CONTENDERS, 2 SEATS") shown on empty data. | D26 shipped; D24's honesty rule leaked into captions; §16 receipts partial (player receipt has no course/gross/sum). |
| **Rivalry** | **Breaks** | "The only rivalry in my league today is the pride stake I typed myself" (COMP). App never names a nemesis for the season; rivalries facet shows live-match W–L only; buddies list carries no competitive data (IOS 1.7); Find golfers rows not tappable (COMP). The clash (D52/D108) is coded (`index.html:4613`) and was not visible in any audited league. | D19 (christened rivalries), D21 (callout), D52/D108 (clash), D29 (digest) — logged; shipped surface is the head-to-head record from live games. |
| **Next round** | Breaks softly | No stake line (D51 unbuilt). NEXT tile is the calendar. Floor/month-close copy fires before the season starts and on the league-less Home ("Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points" to a user with no league — ORG ORG-23, NOV N-15, CAS A9, `screenshots/org/14-home-empty-full.jpg`). Live games — the actual reason to play again — are unreferenced from the season screens. | D51, D23 (nudges name their emotion), D81 ("points forward on quiet days"). |
| **Season finale** | **Breaks hard** | One bylaws row ("CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh"), a "LOCKED" pill, "HAS LOCKED A CUP SEED", "EVERYONE ADVANCES". No countdown, no bracket, no tiebreak text, no "what winning pays you", no preview of the settlement card. OBS Journey F verdict: "the database reached its final row." COMP: cannot plan December. 8/8 personas could not explain how the Cup is won. | D4 (July: "the reset lands as a playoff, not a theft"), D66 (ceremony), D105 (Aug 28: "the flagship moment of the product is invisible" — PROPOSED, unbuilt), §14.3/§14.4 (Trophy Room "screenshot-shaped by design"). |
| **Next season** | **Breaks** | No finished league exists to test. What the live app says about after: "THE RECORD · No silverware yet — every season starts level.", "SEASON I" everywhere, no notifications in 60 days, "Cups & events · 1 · Played in" for nothing played. OBS: "the only thing that would make me start another is a specific friend — Galen." The complete-state hero ("Run it back — Season 2", `index.html:10033`) exists in code; no tester could reach it. | D41 (run it back), D66/D67/D68 (ceremony, career record, season-end email) — all logged; unobservable in this audit. |

**The break points, in order of severity for a real league:** consent (a friend commits $50 without seeing who or when) → first result (points promised, withheld, unexplained) → finale (the name of the product is a bylaws row) → rivalry (never named by the app) → understand (rules four taps deep) → next round (no stake, no projection).

---

## 3. Information hierarchy, screen by screen (web)

Format per screen: **3 s / 10 s / 30 s / after exploration** · **Primary question** → answered? · **Should dominate** · **Unnecessarily prominent** · **Buried**. Reads are consolidated across the personas who saw the screen; disagreements are noted.

### 3.1 Sign-in door — `screenshots/org/01-door.jpg`
- **3 s:** orange flag, "CUP SEASON", "Rally your crew. Post real rounds. Take the cup." **10 s:** I post scores, there is a prize, groups are private (invite code). **30 s:** two buttons, nothing else to do; raw `v23 · __CS_VERSION__` visible (8/8 noticed). **After:** still cannot define season, league, cup, cost, length (8/8 cold answers).
- **Primary question:** "What is this and why would I sign up?" → **No.** SKEP: "The door is a wall with two handles." The Prize Pool Disclaimer on `/legal.html` explains the product better than the door (ORG ORG-40, NOV).
- **Should dominate:** one sentence of mechanism — the Guide's own "You post the rounds you actually play, from any course, and they count toward a season that ends in a Cup Final." (Cup-Season-Guide.md line 3) is not on the door.
- **Unnecessarily prominent:** the version placeholder.
- **Buried:** everything.

### 3.2 Join landing (`?join=`) — `screenshots/join/02-B-join-link-landing.jpg`
- **3 s:** the same door plus an email box. **10 s:** "You're invited to The Papago Grind. Enter your email and you're in." **30 s:** the two big buttons still sit above the auto-opened email box; the URL has already dropped `?join=` (JOIN J-29). **After:** the promise is false — four screens and a $50 consent follow (JOIN J-05, CAS A23, SKEP SK-03).
- **Primary question:** "What am I being invited to?" → **No.** Roster, Pro, dates, stakes, format: none.
- **Should dominate:** the league card (name, Pro, N golfers, dates, buy-in) and a Join.
- **Unnecessarily prominent:** "Continue with email" / "I have an invite code" (both redundant once the link is open).
- **Buried:** the $50 (disclosed after account creation).

### 3.3 Golfer card — `screenshots/org/09-golfer-card-2.jpg`
- **3 s:** a form: name, handle, index, a grid of 14 icons. **10 s:** the index is "optional… a starting point — otherwise your first three rounds set it" — praised as "the single best sentence in onboarding" (CAS). **30 s:** handle silently follows the name (ORG, NOV); "+ Add your GHIN number… that's identity, not your number" read three times and still cryptic (NOV, CAS, ORG); "Ball marker" never says it is an avatar (6/7). City/home course deferred to a tab not yet seen.
- **Primary question:** "What does the app need from me to start?" → Mostly yes.
- **Should dominate:** name + index. **Unnecessarily prominent:** the 14-tile marker grid (largest element; IOS 1.6 same). **Buried:** what the marker is for; that the typed index is provisional (Home then shows "INDEX 0 OF 3" while Clubhouse shows 14.2 — ORG ORG-16, NOV N-17).

### 3.4 Orientation "Four places. Two ways to play." — `screenshots/org/12-after-card.jpg`
- **3 s:** four tiles + two cards. **10 s:** Home/Clubhouse/⊕/You; league = months, event = weekend. **30 s:** "table", "board", "pot", "event" introduced undefined; "The ⊕" vs the tab bar's "Post" (NOV). **After:** the words "season" and "cup" — the product's name — are not defined here (ORG).
- **Primary question:** "How is this app organised?" → Yes. "What is the game?" → No.
- **Should dominate:** what a round becomes (points) and what a season ends in. **Buried:** scoring entirely (lives in You › How it works).

### 3.5 Home, league-less — `screenshots/org/14-home-empty-full.jpg`
- **3 s:** three pills, "YOUR CARD · Three rounds and your index goes live. Nothing else needed. · INDEX 0 OF 3 · [Post your first round]". **10 s:** three tiles (LEAGUE None yet · NEXT Open · BOARD —). **30 s:** "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points…" for a user with no league (ORG, NOV, CAS all flagged); FAB covers "AROUND YOUR BUDDIES".
- **Primary question:** "What do I do now?" → Yes ("Post your first round") — the best league-less rung. 
- **Should dominate:** the index ladder — it does. **Unnecessarily prominent:** the floor rule. **Buried:** nothing important.

### 3.6 Home, forming / pre-season member — `screenshots/join/21-P-home-member-full.jpg`, `screenshots/skep/09-home-full.jpg`
- **3 s:** "7 days · to first tee. 5 golfers in. The bylaws lock at the tee." and a huge orange **"Lock it in and invite your crew"**. **10 s:** ROSTER bar 5 IN (of what? — SKEP), LEAGUE/NEXT/BOARD tiles, "MONTH CLOSES in 2 days", the floor paragraph. **30 s:** feed of joins, two three-hole match plays "$5 on the line", gross scores. **After:** the button is the Pro's; "Join a league" pill highlighted for a member (CAS A34); the answer to "what do I do" is "wait 7 days", which the screen never says (CAS §4).
- **Primary question (member):** "What is my situation and what should I do?" → **No.** 
- **Should dominate:** "First tee Sat Sep 5 · squads drawn by Casey · practice rounds build your number until then" + the ⊕.
- **Unnecessarily prominent:** the lock CTA (P0 for JOIN), Start/Start/Join pills, month-close pill, floor paragraph.
- **Buried:** the season's start date as a *player* fact; the roster; the ⊕ (unlabelled circle).

### 3.7 Home, mid-season — `screenshots/obs/05-home-full.jpg`, `screenshots/obs/36-home-earlier.jpg`
- **3 s:** gold "1st", "You lead by 22 points over Jade." **10 s:** WEEK 6 OF 26, "— HELD", "AUG FLOOR 1/2 ▬▬ 1 MORE · 2D", NEXT FRI QUINTERO, Galen's 79. **30 s:** tiles, feed, reactions. **After:** HELD, floor, "month closes" unexplained; second league absent; feed is cross-league and duplicates one story twice (OBS issue 24); stories are signed with a league name that runs into the sentence ("That one goes on the wall. Who's the bitch? · Aug 24").
- **Primary question:** "Where do I stand and what's next?" → Yes, for one league.
- **Should dominate:** the standing MOVE (it does) plus the one thing to do this week (it does not — the floor bar is a penalty, not a move). **Unnecessarily prominent:** Start/Start/Join pills for a week-6 member (D94 chose this deliberately — "the thing to watch in use"; OBS is the use, issue 6). **Buried:** the other league, money owed ($0 collected, six weeks in), the Cup Final.

### 3.8 Clubhouse header / league card — `screenshots/org/37-league-room-forming.jpg`, `screenshots/obs/07-league-full.jpg`
- **3 s:** YOUR GROUPS chips, league name (twice), a code pill, dates, "THE PRO · CASEY", "Add golfers", and for the Pro a red "Cancel & delete this league". **10 s:** six-segment control. **30 s:** the race begins below the fold.
- **Primary question:** "Who's winning?" → Not on the first screen.
- **Should dominate:** the race. **Unnecessarily prominent:** the code pill, "Add golfers", the delete link (NOV N-29: "the invite code is the last thing on the page; Cancel & delete is the third line"). **Buried:** standings.

### 3.9 Standings — pre-season Pro (`screenshots/nov/36-clubhouse-full.jpg`), pre-season member (`screenshots/join/23-Q-clubhouse-full.jpg`), mid-season (`screenshots/obs/07-league-full.jpg`)
- **3 s:** Pro: an orange "BEFORE FIRST TEE" card; member: "SQUADS ARE FORMING · The Pro has the list. · 5 PLAYERS IN THE POOL · [See the squads]"; mid-season: chips + card + segments, then the Climb. **10 s:** two empty squads with "TOP SEED · +10", "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING", "CAPT. —"; or a five-row table of zeros; or two names 32/10 "LOCKED". **30 s:** four tiles (SEASON, POT, YOUR INDEX, COUNTING ROUNDS), NEXT UP card, ON THE LINE, three individual titles, a second table, the footnote "bylaws §4", the code. **After:** nobody could say what LOCKED, seed, advance, +10, ceiling, Δ WK, R, or §4 mean (8/8 glossaries).
- **Primary question:** "Who is beating whom and what changes it?" → mid-season yes (first half), pre-season no; "what changes it" never.
- **Should dominate:** the Climb with the viewer's rung and one forward line. **Unnecessarily prominent:** two redundant tables (D26 replaced a chart, not the table), the stat tiles above the race (iOS), the code/Add golfers at the bottom. **Buried:** the race (below the fold), what the season ends in, the rival's floor status (OBS issue 16).

### 3.10 The board — tab (`screenshots/obs/19-sub-Board.jpg`) and sheet (`screenshots/obs/45-the-board-link.jpg`)
- **3 s:** "THE BOARD · ROUNDS LAND HERE AUTOMATICALLY", Jul 20 join post at the top. **10 s:** a chronological log, oldest first, compose box at the bottom under the newest post. **30 s:** 🔥 / + / ⚑ / 💬 per round; two post formats ("posted 35 gross · 9 holes · Palo Verde Gc · Back · Diff 17.8" vs "posted 90 at Raven… · Silver."). The Home-opened sheet is richer: "85 GROSS · A LITTLE LOOSE · COUNTING #2 THIS MONTH · -1.2 · 6 PTS" — the best per-round card in the product. Pre-season the tab's header is false: members' rounds appear on Home's feed, not on the league board (CAS A16).
- **Primary question:** "What just happened?" → newest is at the bottom. 
- **Should dominate:** newest first, the points band on every round. **Unnecessarily prominent:** joins and handle changes as full cards. **Buried:** the newest post; "Diff 17.8" (D2 says differential is never shown outside a receipt — it is shown on the board).

### 3.11 The ⊕ door — `screenshots/org/61-post-sheet.jpg`
- **3 s:** three cards, LIVE first with an ember tick. **10 s:** during / after / before. **30 s:** side games named (match play, Wolf, settle-up), guests welcome. 
- **Primary question:** "Which kind of round?" → Yes. The cleanest screen in the app. **Buried:** that a live round also posts to the season is in the LIVE card's sub-copy ("every complete card posts at the finish") and understood by ORG/COMP, missed by CAS (A36).

### 3.12 Post-a-round composer — `screenshots/org/62-post-round-form.jpg`, `screenshots/org/68-round-filled.jpg`
- **3 s:** course search, RATING 72.1 / SLOPE 128 (placeholders that read as values), 18/9, FRONT 41 / BACK 43 (placeholders), DATE. **10 s:** [Post round] enabled with an empty card; below, "HOW THIS ROUND SCORES · LEAGUE POINTS THIS ROUND — · No league yet? The round still counts on your card…" (shown to members — 6/7 flagged) and POINT BANDS. **30 s:** with a course + nines: "6 · A little loose, still cash in the bank. · 87 GROSS · -1.7 VS YOUR INDEX". **After:** the 95% allowance in the bylaws appears nowhere on the form (ORG, NOV, JOIN, COMP, SKEP); which index (14.2 or 13.5) the number is against is unknowable from the screen.
- **Primary question:** "How do I get my score in and what is it worth?" → in: yes; worth: yes-then-no (see T3/T4).
- **Should dominate:** course/tee then the nines, then a single true line about what this round does *today* (D51). **Unnecessarily prominent:** rating/slope as editable boxes before a tee is chosen; the "No league yet?" line. **Buried:** the season window (pre-season rounds count for nothing — unsaid); the point bands are well placed (all testers).

### 3.13 Posted-round ceremony — `screenshots/org/69-after-post.jpg`, `screenshots/nov/72-posted.jpg`
- **3 s:** "87 · 1.7 over your number". **10 s:** "COUNTS ON YOUR CARD", green "Share the card". **30 s:** behind it, "Welcome to the season ⛳" with two trophies, a duplicated line, "Share a link — no account needed", "Turn off this link". 
- **Primary question:** "What did I earn?" → **No** (no points; "counts on your card" read as "counted" by NOV, JOIN, CAS).
- **Should dominate:** gross · band · points · "counts for Squad 2 this month" or "practice · season starts Sep 5". **Unnecessarily prominent:** share (two buttons across two sheets), threshold badges, the link-revoke control. **Buried:** the league consequence.

### 3.14 Round receipt — `screenshots/org/71-round-detail.jpg` (pre-season, own), `screenshots/obs/37-round-card.jpg` (in-season, other's)
- **3 s:** "87 gross". **10 s:** "The course 70.1 / 120 · 87 − 70.1 × 113 ⁄ 120 → 15.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 14.2 · Against your number -1.7 — A LITTLE LOOSE". **30 s:** in-season adds "Points 9 · This month COUNTING #1" and (live rounds) "Attested · Played with Casey, Marcus, Priya · [See the scorecard]". **After:** ISO date; no edit/delete/report; the sign again; no allowance line even though §16 says the receipt "shows the rating/slope/allowance snapshot".
- **Primary question:** "Why is this number what it is?" → Yes — the one screen that fully shows its work (7/7 praised). "Did it count?" → in-season yes, pre-season silent.
- **Should dominate:** the verdict + points + counting slot. **Buried:** the correction path (the only delete is an unlabelled ✕ on You › Recent rounds with a native confirm and no undo — ORG, NOV, CAS, COMP).

### 3.15 Live setup — `screenshots/org/85-live-door3.jpg`
- **3 s:** a form: course, tee/rating/slope, 18/9, "Enter the pars". **10 s:** THE FOURSOME 1/4, league mates as chips, search the app, add a guest. **30 s:** GAME FOR THIS ROUND · PICK ONE (Just score / Match play / Wolf / Skins / Sunningdale Rules) — each explains itself only after selection; Wolf and Sunningdale never explained (NOV N-23, ORG ORG-39, CAS). Strokes line ("Marco gets 4: holes 3, 6, 16, 18") is the best copy in the flow. Guest "Add" with empty name is a silent no-op (ORG). No exit before tee-off on web (D110 addendum added Close on iOS).
- **Primary question:** "Who am I playing and what game?" → Yes once a game is picked.
- **Should dominate:** the game picker (it is last). **Unnecessarily prominent:** "Enter the pars" paragraph. **Buried:** the game.

### 3.16 Live scoring — `screenshots/org/88-live-scoring.jpg`, `screenshots/nov/91-live-h1.jpg`, `screenshots/comp/56-live-hole18.jpg`
- **3 s:** "ALL SQUARE" / "MIKE 1", hole header "HOLE 1 · PAR 5 · SI 15", steppers. **10 s:** per-player "14.2 IDX · 0 STK", running "+5 net · 10 thru 1". **30 s:** "Group phones — everyone can score", "Finish round & post to season", the attestation paragraph, "Scrap this round", SIDE GAMES panel with the live ledger ("JORDAN → PRIYA $60"). **After:** first tap = par unannounced; "0 STK" for two 18s puzzled NOV; "attested" is finally defined here — after tee-off; "Finish round & post to season" pre-season posts to the season that hasn't started (NOV).
- **Primary question:** "Who's winning right now?" → Yes, instantly. "the best-feeling part of the app" (NOV).
- **Should dominate:** the match state (it does). **Buried:** the par-on-first-tap rule.

### 3.17 Finish / settlement — `screenshots/org/92-settlement.jpg`, `screenshots/comp/58-live-posted.jpg`
- **3 s:** "Round posted · 0 CARDS TO THE SEASON" (contradiction — ORG ORG-27) or "4 CARDS TO THE SEASON · 💰 Priya took 7 skins and $60 · JORDAN PAYS PRIYA $60 · …". **10 s:** per-player POSTED/NOT POSTED · ✓ ATTESTED. **30 s:** three share buttons + revoke. The "Finish the round" pre-sheet with "Finish — no complete member card to post" vs "This one was casual — post nothing" is indistinguishable (CAS A20).
- **Primary question:** "Who owes whom?" → Yes — "the artifact I'd actually screenshot into the group chat" (ORG). 
- **Should dominate:** the settlement (it does). **Unnecessarily prominent:** three share controls. **Buried:** the per-skin math (COMP had to derive $60), and that this money never reaches the Pot tab.

### 3.18 Schedule / calendar — `screenshots/obs/13-sub-Schedule.jpg`, `screenshots/nov/54-tab-Schedule.jpg`
- **3 s:** "← HOME · YOUR GOLF CALENDAR", a month grid. **10 s:** IN YOUR CREW'S PLANS ("Galen BUDDY · FRI SEP 4 · you lead 1–0 · YOU'RE IN · 'Major'"), legend with three near-identical dots. **30 s:** "Put a round on the tee sheet"; "ON THE TEE SHEET — Nothing on the tee sheet for Aug" directly under a card labelled ON THE TEE SHEET (OBS issue 22); WEEK BY WEEK lists WK 4…WK 1 with nothing beside them. **After:** the tab leaves the Clubhouse and the only way back is the bottom nav (7/7 flagged); Sunday "season date" dots unexplained; NOV worked out week 1 is one day long (Sat start, Sun close) and nothing explains it (N-21).
- **Primary question:** "When do I play next, with whom?" → partly.
- **Should dominate:** the next round. **Unnecessarily prominent:** the grid; the CTA repeated as a hint line. **Buried:** the season's own dates (first tee not visible on the August grid — SKEP).

### 3.19 You / profile — `screenshots/org/73-you-tab.jpg`, `screenshots/obs/29-you-full.jpg`
- **3 s:** avatar, name, big index, "FORM ●". **10 s:** "Tell us how it's going", Founder's desk (on the owner's account), DISPLAY CASE ("No hardware yet" right after "🏆 Pinned to your card" — ORG, NOV, JOIN), THE RECORD, LIFETIME ("Best vs index -3.7 · Career best" for the worst band — NOV; "Cups & events 1 · Played in" for nothing played — 5 testers). **30 s:** RECENT ROUNDS with an unlabelled "91 · 19.7" and an ✕ (delete), YOUR BUDDIES, RIVALRIES (OBS only), THIS SEASON, LEAGUE RECORD, HOW IT WORKS (five cards, last thing on the page — SKEP SK-24, JOIN J-31).
- **Primary question:** "Who am I here and how am I doing?" → index yes; standing only at the very bottom (LEAGUE RECORD · 1ST OF 2).
- **Should dominate:** index + league record + rivalries. **Unnecessarily prominent:** feedback prompt, founder tools, the display case of unearned badges. **Buried:** league record, rivalries, the manual.

### 3.20 Trophies
No trophy screen exists. "YOUR DISPLAY CASE" holds milestone badges (Broke 100 / Broke 90 both "88 gross" on one round — IOS 1.5; ORG got both on an 87); "THE RECORD · No silverware yet". Badges survived deletion of the round that earned them (COMP). §14.4's Trophy Room is unobservable (no complete season).

### 3.21 Pot — `screenshots/org/54-tab-Pot.jpg`
- **3 s:** "THE POT $50" gold. **10 s:** "1 × $50 · $0 collected · 1 still owe · $30 CUP CHAMPS · $13 RUNNER-UP · $8 POINTS KING" ($51 on $50 — 4 testers), "Cup Season keeps the books…". **30 s:** BUY-INS with checkbox rows any member can tap (refusal is a hidden status — SKEP), "THE OTHER STAKES · PRIDE, ON THE BOOKS · [Post a stake]".
- **Primary question:** "How much, to whom, by when, and what do I win?" → how much yes; to whom/by when never (JOIN J-10, CAS A15); "Cup champs $150" for a squad — split unstated (ORG, SKEP, COMP).
- **Should dominate:** what you owe / to whom, and what winning pays *you*. **Unnecessarily prominent:** the checkbox rows for non-Pros. **Buried:** payment path; that side-game cash never lands here.

### 3.22 Card & settings — `screenshots/org/77-card-settings.jpg`, `screenshots/org/80-settings-segment2.jpg`
- **3 s:** a form with the marker grid. **10 s:** handle "moves once / 60 days" (first disclosure), Findable by All (default; strangers appeared in ORG's Add-golfers search — ORG-15), GHIN copy here is clear where the card's was not. **30 s:** Settings: notification toggles read ON while "Enable on this device" is unpressed (SKEP SK-32); "Membership & billing · PLAN FREE · PILOT · Cup Season membership lands at launch" — no price, no scope (ORG ORG-17, CAS A32, SKEP SK-22); `v23 · __CS_VERSION__` again.
- **Primary question:** "How do I change things / what will this cost?" → change yes; cost no.

### 3.23 Wizard step 0 (name) — `screenshots/org/15-wizard-1.jpg`, iOS `screenshots/ios/12-wizard.jpg`
- **3 s:** one field, "Start the league". **10 s:** "You can rename it any time before the bylaws lock." **After:** empty-name tap does nothing (ORG, NOV); "Start" creates the league immediately ("…is on the books — set the bylaws" toast) — the button means Next (NOV N-32); no step count.
- **Primary question:** "What am I committing to?" → No.

### 3.24 Wizard step 2 (competitiveness) — `screenshots/org/18-wizard-step2.jpg`, `screenshots/org/21-customize-open.jpg`
- **3 s:** three preset cards, Standard checked. **10 s:** "95% hcp · GHIN rounds · best 4 / mo count · 2-round floor" — seven jargon tokens in three lines (ORG ORG-13); FAB covers the summary sentence. **30 s:** big orange "Use these defaults →" and a small "Customize". **After:** Customize reveals nine dials including **Buy-in $75** (default, hidden), Season length 6 mo, Teams with a caption that contradicts the highlight ("2 Squads" selected, caption "4 squads · the full cup experience", orange "1 golfer staged — solo fits" — NOV N-07, ORG), "How it ends" ((i): "top seeds only, whoever's hottest takes the cup" — the only in-app definition of the Cup Final, behind an (i) behind Customize), the pot split (i) with the money model sentence that belongs beside the buy-in.
- **Primary question:** "What rules am I choosing for my friends?" → only if Customize is opened and every (i) tapped (7 minutes for ORG).
- **Should dominate:** buy-in, length, first tee, teams. **Unnecessarily prominent:** "Use these defaults →" (which also does not reset customisations — ORG ORG-36). **Buried:** $75; the Cup Final's definition; "Minimum four to tee off" (appears only on step 3 — NOV N-06).

### 3.25 Wizard step 3 (review & lock) — `screenshots/org/30-wizard-step3.jpg`
- **3 s:** a bylaws table. **10 s:** "VERIFICATION Attested" (never chosen; preset said "GHIN rounds"), "CUP FINAL · Final 4 weeks · from Sun Dec 6 · scored fresh". **30 s:** "Lock opens the invite link — one link fills the league… Minimum four to tee off." + **"Lock the bylaws & form the squads"**. **After:** three lock moments on one screen (header "LOCKS AT FIRST TEE", button "lock now", footer "invite opens on lock") (ORG ORG-08); the code already exists before lock (ORG found THEPTCQ5 in the room after the failed lock); the lock itself threw `staged is not defined` for both Pros — ORG six failures and never proceeded; NOV six "Lock failed" toasts while the lock had succeeded on tap 1 with the first attempt's 2-squad structure, a later Solo choice silently discarded (NOV N-01 P0).
- **Primary question:** "What happens when I press this?" → No, and then the press fails.

### 3.26 Form squads — `screenshots/org/51-squads-view.jpg`, `screenshots/join/33-S-see-squads.jpg`
- **3 s:** "5 in the pool · THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW", two Empty squads, five chips. **After:** no back/close (7/7); chips tappable and inert for members (JOIN J-19); "Draw squads" for the Pro shows "Draw failed. Something went wrong — please try again." while the console carried the server's usable sentence "Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first." (ORG ORG-12, NOV N-09).
- **Primary question (member):** "Which squad am I on?" → No. **(Pro):** "Can I draw yet?" → the answer exists and is hidden.

### 3.27 League tab / bylaws — `screenshots/org/45-league-tab.jpg`, `screenshots/obs/21-bylaws-open.jpg`
- **3 s:** Members & invites · Share the season · Squads rows. **10 s:** it is admin. **30 s:** "▶ LEAGUE RULES & PRO SHOP" collapsed; expanded: the spec-sheet bylaws (no sentences — SKEP SK-20), "[How scoring & handicaps work →]", then a Pro Shop upsell ("THE PILOT RIDES FREE · SOON Custom rules…"). Squad vocabulary printed for an "Individual — no squads" league (OBS issue 10).
- **Primary question:** "What are the rules that decide the winner?" → they are here, collapsed, on the sixth tab, phrased as parameters.
- **Should dominate:** exactly those rules, as prose. **Unnecessarily prominent:** the upsell. **Buried:** the rules.

### 3.28 Join covenant / welcome — `screenshots/join/11-J-after-take-me-in.jpg`, `screenshots/org/95-join-link-view.jpg`
- Consent sheet: four parameter rows + "Joining puts you on the pot sheet for $50" + "Join — I'm in for $50". Welcome: "THREE THINGS TO KNOW" (four bold items), "How scoring works →", "Share the invite link". The welcome is good copy (ORG: "a good join covenant"); the consent is "the right idea with the wrong contents" (JOIN).
- **Primary question:** "What am I agreeing to?" → money yes; people, dates, rules no.

---

## 4. Information hierarchy — iOS screens (`screenshots/ios/`)

The native survey could not tap or scroll; reads are first-screen only.

| Screen | 3 s / 10 s / 30 s | Primary question → answered? | Should dominate / is prominent instead / buried |
|---|---|---|---|
| **Home** `01-door.jpg` | "2nd — held · 10 points back of the lead. · Partial month · floors waived" / week 4 of 14, QUIET SINCE YOUR LAST VISIT followed by an item, Galen 79 / THE BOARD, 🔥, +, tabs | "How am I doing, what next?" → rank + gap yes; leader unnamed, field size unstated, no next action | Rank card (is). / `SAT · AUG 29`, the wordmark band. / the leader's name, that there are only two golfers, any definition of a point. **Week count contradicts Clubhouse (14 vs 13)** — IOS 2.2. |
| **Clubhouse** `03-clubhouse.jpg` | league name ×3, code pill, "WK 4 / 13 · POINTS RACE · STANDARD RULES", "Add golfers" / four tiles, "3 days left in August", NEXT UP card / the Climb: "01 Galen LOCKED 19 · **10 back of Galen** (drawn under Galen's row) · 02 You LOCKED 9 · EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" | "Where do I stand, who do I catch?" → **yes — the only iOS screen that names the leader and the gap**, one tab and a full scroll from Home | The standings. / the header card (duplicates the nav title), code pill, tiles, Add golfers. / the standings (below the fold); the gap line on the wrong row (IOS 2.4). |
| **Board** `04-board.jpg` | "◆ Your league is live — post the first round" under TODAY; 85% empty | "What's going on?" → **contradicts Home** (18 items there) | The feed. / nothing. / everything. No league name on the pushed screen. |
| **Schedule** `05-schedule.jpg` | calendar; "Galen BUDDY · FRI SEP 4 · you lead 1–0 · YOU'RE IN · 'Major'"; grid missing Aug 1–5 | "When next, with whom?" → yes, wrapped in undefined tokens | Next round (roughly is). / caps subtitle repeating the title; CTA repeated as hint. / ON THE TEE SHEET section. |
| **You** `06-you.jpg` | "NO. 2" (the marker's name — reads as rank for a golfer actually in 2nd), FOUNDER pill, GHIN number public, 11.3, badge chips, FORM dots | "Who am I, how good?" → index yes; standing absent | Index + standing. / GHIN, FOUNDER, badges ("Broke 100" and "Broke 90" both "88 gross"). / competitive context. |
| **Card & settings** `07-settings.jpg` | marker grid is the largest element; "THE MARKER ALWAYS BACKS IT UP" | "How do I change myself?" → mostly | Name/photo/handicap source. / the 14-tile grid. / handicap (not on this segment). |
| **Buddies** `08-people.jpg` | Find a golfer button + a search field doing the same job; six rows each tagged BUDDIES under a BUDDIES header; REQUESTED (direction unknown, no accept) | "Who are my people?" → names only, no handicap, no record vs me | Pending requests needing action. / redundant pills and controls. / requests. |
| **Post a round** `09-post.jpg` | "A preview at 100% of your number — your league's own math scores it on the books." (undefined), recent courses with unlabelled "72.1 / 142", 41/43 placeholders that read as values, Post round fully orange with an empty card, "Play now" competing in the nav | "How do I get my score in?" → mostly | Score entry. / the empty preview box. / date; the inputs. |
| **Live setup** `11-live.jpg` | no title bar, no exit, no game named; "the stepper", "Enter the pars", LEAGUE header twice | "What am I starting?" → with whom yes; what no | The game and a start. / the pars paragraph. / the exit (D110 addendum added Close after the survey), the game. |
| **Wizard** `12-wizard.jpg` | one field, "Start the league", "bylaws lock", 80% empty, no step count | "What am I committing to?" → no | A one-line description of a league. / "Start the league". / everything after the name. |
| **Events** `13-events.jpg` | "The Ryder · Two teams · weekly vs-index duels · first to the clinch · LIVE" / "Bracket · SOON" / "More styles land after the pilot" | "What else can I play?" → jargon | Plain words for the Ryder. / trophy framing. / who can start, who's invited, how long. |

Cross-cutting on iOS (IOS §2): five different "do a round" entry points (Post tab, + on Home, Play now, Live round, Put a round on the tee sheet); three type families and two toggle styles; content ghosting through the tab bar on five screens; nothing on any of 11 screens says what a point is.

---

## 5. Competition visibility

Question per surface: **can I immediately see who I'm beating, who's beating me, and what I need to do to change that?** Flag = the screen foregrounds statistics / schedules / admin / scorekeeping over competition.

| Surface | Who I'm beating | Who's beating me | What changes it | What it foregrounds instead | Flag |
|---|---|---|---|---|---|
| Home, league-less | — | — | "Post your first round" (index ladder) | the index ladder — appropriate | — |
| Home, forming member | No (all zeros; feed gross-only) | No | No ("Lock it in" is the Pro's; "wait 7 days" unsaid) | **admin** (Start/Start/Join, lock CTA, roster bar), **scorekeeping** (month closes, floor) | **FLAG** |
| Home, mid-season | Yes, one league, named, with gap (3 s) | Yes when 2nd ("10 points back of Galen") | No forward line except tie case; floor bar = penalty avoidance | Start/Start/Join pills above the hero; the other league hidden | partial FLAG |
| Clubhouse header | No | No | No | **admin** (code, Add golfers, Cancel & delete) | **FLAG** |
| Standings, pre-season | No (zeros; squads undrawn) | No | No | **scorekeeping vocabulary on no data** (TOP SEED +10, GENEROUS CEILING, Δ WK, CAPT. —), stat tiles, the code | **FLAG** |
| Standings, mid-season | Yes (Climb + table, two names) | Yes | "Post 1 more round this month" (floor, not race); "HAS LOCKED A CUP SEED" without saying what a seed buys | four stat tiles, three tables, bylaws §4 footnote | partial FLAG (race below the fold) |
| The board | Indirectly (in-season cards carry band + points + counting slot) | Indirectly | No | join/handle-change system cards; Diff on round rows; oldest-first | partial |
| Home feed (pre-season) | No — gross only | No | No | **scorekeeping** (gross, "First round on the card") | **FLAG** |
| Composer | — | — | Points bands (generic), no stake line | rating/slope boxes, "No league yet?" | **FLAG** (scorekeeping over stakes) |
| Ceremony | — | — | No ("COUNTS ON YOUR CARD") | share, badges, link revoke | **FLAG** |
| Receipt | — | — | In-season: points + counting slot (good). Pre-season: silent | the arithmetic (correct here) | — |
| Live scoring / settlement | Yes, hole by hole, named, with money | Yes | Yes (the next hole) | — | **the model for the rest of the app** |
| Schedule | "you lead 1–0" (undefined) | — | — | **schedule/planning** by design; empty WEEK BY WEEK | FLAG (it exits the league room) |
| Pot | — | — | — | **admin/ledger** ($0 collected; checkbox rows) | FLAG (by design, but no "what you win") |
| League tab | — | — | The rules — collapsed | **admin + upsell** | **FLAG** |
| You | LEAGUE RECORD "1ST OF 2" at the bottom; RIVALRIES (live-match W–L) | same | — | founder tools, feedback prompt, badges, lifetime stats, five guides | **FLAG** (statistics over competition) |
| Members & invites | Indexes only (the sole index comparison pre-season) | — | — | admin | partial |
| Form squads | No (Empty) | No | No | admin tooling shown to players | **FLAG** |
| iOS Home | "2nd", unnamed leader | unnamed | No | date, wordmark | partial FLAG |
| iOS Clubhouse | Yes, named, gap on wrong row | Yes | No | header card, tiles, code | partial FLAG |
| iOS You / Buddies / Board | No | No | No | badges / contacts / empty | **FLAG** |

**Summary.** Competition is immediately visible on two surfaces: a mid-season Home hero (for the last-opened league) and the live scorer. It is visible-with-scrolling on mid-season Standings. It is invisible pre-season everywhere, invisible on You, the board (pre-season), the Pot, the League tab, the schedule, and on 9 of 11 iOS screens. "What I need to do to change it" is answered nowhere in the season layer; it is answered on every hole of a live side game.

---

## 6. Intent vs. shipped — the product already named these

Kept separate on purpose: this is not to soften findings but to show that the audit's findings are re-discoveries, which raises their priority.

| Decision / spec | What it promised | What testers saw | Gap |
|---|---|---|---|
| D1 (PvI display) | "beat your number by 1.4", bands by name | Ceremony: yes. Form, receipt, You, standings, board chips: raw signed PvI ("-1.7", "-4.0" red) | Sign convention leaks on five surfaces; 6/7 read it backwards |
| D2 (two numbers on a card) | gross + points + one phrase | Ceremony: gross + phrase, **no points**; board: "Diff 17.8" | Points missing at the peak; differential shown outside receipts |
| D3 (cap/floor as prose, slot meter, "bumped by your 81 ✓") | visible displacement, "can't hurt your squad" at the door | "COUNTING #2 THIS MONTH" on in-season cards; "BUMPED" on the player receipt; welcome sheet carries the sentence | Partially shipped; pre-season nothing |
| D4 (foreshadow the Cup Final reset) | season-long banner "Season crowns 4 Cup seeds · Cup starts fresh…" | one bylaws row + "LOCKED" / "HAS LOCKED A CUP SEED" | The name of the product is undefined in the product (8/8) |
| D24 (magic number / clinch / cut line) | "your Sunday round matters because…" | captions on empty tables; no magic number line anywhere | Engine shipped, story not |
| D26 (The Climb) | you-centred ladder with points-back | shipped and legible for 2 rows; below the fold; duplicated by two tables | Works; buried |
| D51 (stake line) | "what your next round is worth" on the post screen | nothing | Unbuilt |
| D52 / D108 (weekly clash) | one spotlighted pairing per week, chip on Standings | `renderClash` exists (`index.html:4613`); no audited league had a clash | Unobserved; needs a running league on the tick |
| D81 (Home state machine) | hero = the MOVE and its cause; "on quiet days points forward" | hero = position + gap; forward line only for ties; forming hero = Pro's CTA for everyone | Half-shipped; the forming state is wrong for members |
| D82 (orientation) | one screen; depth at the doors | shipped; season/cup undefined on it | Fine for IA, silent on the game |
| D94 (doors above hero) | "the thing to watch in use" | OBS issue 6, CAS A34, SKEP SK-07 | Watched: members read them as "you haven't joined" |
| D95 (receipt shows work) | course, rating/slope, arithmetic, points, counting rank, attestation | all present in-season; pre-season lacks points and window; ISO dates | Nearly complete |
| D96 (forming hero CTA) | "Lock it in and invite your crew" for an abandoned setup | shown to every member of a forming league | Missing `is_commissioner` gate |
| D105 (Cup Final you can see) | window race leads Standings during cup_final; seeds carry a ladder | PROPOSED 2026-08-28; nothing visible | Unbuilt; unobservable this audit |
| D106 (pot: owed vs collected) | "$600 pot · $450 collected · 2 still owe" | "$150 · $0 collected · 2 still owe" ✓; payouts still computed on the roster ($90/$38/$23 on $0 collected) | Half; the ceremony math is the unbuilt half |
| §7 default buy-in $75 | spec default | hidden default behind Customize | Spec-faithful and a P0/P1 for both Pros — the spec is the bug |
| §16 receipts | no figure without a path | pot tiles, bylaw rows, standings zeros ("post one and you're on the board"), "Cups & events 1" — not tappable / false path | Partial |
| Guide "invite by email" | exists | does not exist in the client (ORG, NOV) | Doc ahead of product |
| Guide "Live rounds start from your league's Clubhouse" | — | "Live round" button on Standings' NEXT UP card; the ⊕ is the real door | Two doors, neither referenced from the season screens |

---

## 7. Recommendations, ranked by loop impact

Ordered by (personas affected × severity × how much of the loop it unblocks). Each names the transition it repairs.

1. **Say when a round counts, everywhere it is shown (T3→T4).** One computed string from `seasonStart/seasonEnd` — "Season starts Sat Sep 5 · this one builds your number" / "+6 pts · counts for Squad 2 · #3 this month" — on the composer preview (replacing the points panel pre-season), the ceremony (replacing COUNTS ON YOUR CARD), the receipt, the standings row sheet (replace "post one and you're on the board"), and the You THIS SEASON tile. Delete "No league yet?" for members. 6/6 posting personas; P0 in JOIN, P1 in five others.
2. **One sign convention, in words (T3).** Never print a bare signed PvI. "+1.7 under" / "1.7 over", colour secondary. Applies to `calcVs` (`index.html:6339`), the receipt "Against your number", You "Best vs index", standings "AVG VS INDEX", board chips. 6/7 personas.
3. **Gate the forming hero by role (T1).** Members get "First tee Sat Sep 5 · N golfers in · squads drawn at the tee · practice rounds build your number" + the ⊕; the Pro keeps the lock CTA. Fix the Home→You route that opens the wizard. Fix `staged is not defined` in the lock and surface server errors verbatim ("Draw failed: 1 in, 2 squads"). JOIN P0, CAS/COMP/SKEP P1, ORG/NOV P0.
4. **Put the endgame on the hero and the standings (T6 / finale).** A persistent line under the Climb — "Cup Final starts Sun Dec 6 · both squads play · leader starts +10 · four weeks scored fresh" — and a "How the Cup is won" sheet linked from it. This is D4 as written. 8/8.
5. **Build D51 on the composer (T1/T6).** The honest marginal value line. It is the only surface that could turn "Month closes in 2 days" from guilt into a reason.
6. **Fix consent (Join).** The `?join=` landing shows the league card (Pro, N in, dates, buy-in, endgame) before email; the consent sheet shows roster + dates + "How scoring works"; "Not now" keeps the code; show the Pro a preview of what invitees see; show the URL as text with copy. Add the email/SMS path the Guide already claims, or delete the claim. JOIN P0, ORG P0/P1, NOV P1.
7. **Rules as a first-class sub-tab, in sentences (Understand).** Move "How scoring works" and the bylaws out of the collapsed accordion on tab six; link it from the wizard's preset step, the welcome sheet (already), the Standings caption, and the composer's point bands. Retire "bylaws §4" as a citation. Define attested where verification is chosen.
8. **Standings hierarchy (T5).** Race above the tiles; one table for ≤4 competitors; hide D24 captions until `season_scenarios` has data; render "10 back of X" on the viewer's row (iOS); name the leader on iOS Home.
9. **Feed cards speak in bands, not gross (T5).** "Priya · torched it · 74 · 12 pts" pre-season becomes "Priya · torched it · 74 · builds her number". This is D2 applied to the feed.
10. **Point the season at the side games (T6).** A "Play Saturday live — match play, Wolf, skins" row on Standings/NEXT UP and on the Pot tab; settle side-game money into a ledger view or say plainly that it never lands anywhere.
11. **Mechanical (T2):** never overlay the FAB; hide rating/slope until a tee is picked and block Post when blank; dedupe course rows; announce "first tap = par"; make Scrap reliable; fix the `live_rounds`/`live_round_players` embed so the resume banner works; stamp the version.
12. **Default buy-in to $0** in the wizard and surface money above the fold (spec §7 should change).

---

## 8. Evidence index (fast lookup)

- **Lock bug:** ORG §13:32 (`screenshots/org/31-after-lock.jpg`…`36-lock-from-home.jpg`), NOV C6 (`screenshots/nov/30`–`34`), console `Lock failed. staged is not defined`.
- **Points promised/withheld:** `screenshots/org/68-round-filled.jpg` → `69-after-post.jpg` → `72-standings-after-round.jpg`; `screenshots/join/46-Z-preview.jpg` → `47-AA-posted.jpg` → `51-AD-standings-after.jpg`; `screenshots/cas/51-F08-tee-white-picked.jpg` → `53-G01-after-post.jpg` → `57-H01-standings-after.jpg`; `screenshots/comp/35-preview-74.jpg` → `38-posted-74.jpg` → `40-standings-after74.jpg`; `screenshots/skep/32-pre-post.jpg` → `33-posted.jpg` → `37-standings-after.jpg`. Code: `index.html:6187-6192`, `6584-6596`.
- **Sign inversion:** `screenshots/org/71-round-detail.jpg`, `screenshots/nov/77-round-detail.jpg`, `screenshots/obs/10-my-row.jpg`, `screenshots/cas/56-G04-round-receipt.jpg`. Code: `index.html:6339-6340`, `5709-5714`; spec §2.1.
- **Member sees the Pro's lock:** `screenshots/join/39-U-lock-it-in.jpg`, `screenshots/skep/50-lock-page.jpg`, `screenshots/comp/19-lock-tap.jpg`, `screenshots/cas/02-R01-you-tab.jpg`. Code: `index.html:10101-10110`; D96.
- **Cup Final only in bylaws:** `screenshots/obs/21-bylaws-open.jpg`, `screenshots/org/48-rules-expanded.jpg`, `screenshots/skep/13-tab-League.jpg`. D4, D105.
- **Squad status contradictions:** `screenshots/org/37-league-room-forming.jpg` vs `45-league-tab.jpg` vs `51-squads-view.jpg`; code `index.html:12229-12233`.
- **Consent sheet:** `screenshots/join/11-J-after-take-me-in.jpg`; landing `screenshots/join/02-B-join-link-landing.jpg`; welcome `screenshots/org/95-join-link-view.jpg`.
- **Mid-season competition read:** `screenshots/obs/05-home-full.jpg`, `07-league-full.jpg`, `28-wtb-standings2.jpg`, `36-home-earlier.jpg`; board sheet `45-the-board-link.jpg`; in-season receipt `37-round-card.jpg`.
- **Live/side games:** `screenshots/org/85`–`92`, `screenshots/nov/91-live-h1.jpg`, `screenshots/comp/52`–`58`, `screenshots/cas/87-K04-scorecard.jpg`, `screenshots/obs/42-matchplay.jpg`.
- **iOS:** `screenshots/ios/01`, `03`–`09`, `11`–`13`.
- **Boot/resume errors (all sessions):** `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'`; 502s on post (CAS, SKEP, COMP, JOIN).
