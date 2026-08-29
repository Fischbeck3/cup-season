# Rules & Mental Model Audit — blind UX audit, 2026-08-29

**Scope.** Eight blind persona passes (seven on the web client at `http://127.0.0.1:8791/`, one screenshot-only survey of the native iPhone app). This synthesis extracts every competition rule the testers met or needed, scores whether they could discover / understand / predict / explain it, and then reconstructs the mental model they left with against the one the product intends.

**Evidence discipline.** Every claim is tagged:
- **OBSERVATION** — what a tester saw, cited as `report · screenshot · "exact UI copy"`.
- **INTERPRETATION** — this synthesis's reading of why.
- **INTENT** — what the product means, from `spec/spec-v1.0.md`, `spec/product-vision-v1.0.md`, `spec/decision-log.md`, `spec/gameplay-modes-working.md`, `Cup-Season-Guide.md`, and the code in `index.html` / `supabase/migrations`.
- **GAP** — the finding. Where the spec explains something and the UI did not, the gap *is* the finding; nothing below is softened because a document elsewhere is correct.

**Confidence (1–10)** is a tester-evidence score: roughly, how many of the eight could discover the rule unaided, how many understood it, how many could predict its consequence, and how many said it correctly in their 30-second explanation. Anything below 8 is flagged.

Report shorthand: **ORG** = agent5-organizer (Casey) · **NOV** = agent3-league-novice (Dana) · **OBS** = agent7-retention-observer (mid-season, read-only) · **JOIN** = agent6-new-joiner (Marcus) · **CAS** = agent1-casual (Jordan) · **COMP** = agent2-competitive (Priya) · **SKEP** = agent4-skeptic (Sam) · **IOS** = ios-screen-survey. Screenshot roots are under `scratchpad/harness/shots/{org,nov,obs,join,cas,comp,skep,ios}/`.

---

## 1. Headline findings — the six rules that broke the model

These are the rules whose failure shaped every tester's understanding. Each is expanded in §3.

| # | Finding | Who hit it | Conf. |
|---|---|---|---|
| H1 | **Rounds before the first tee earn nothing for the league, and every surface but one says otherwise.** The post form promised "LEAGUE POINTS THIS ROUND 5 / 6 / 12"; the result card said "COUNTS ON YOUR CARD"; standings stayed at 0; the Home hero said "The season's on. Rounds count from today." while the Clubhouse said "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON". Six of six testers who posted a round hit this and had to *infer* the rule from zeros. | ORG, NOV, JOIN, CAS, COMP, SKEP | 1 |
| H2 | **The 95% handicap allowance is real, applied server-side, and invisible.** It appears once, as a bylaw row. The web preview scores at 100%; the league scores at 95%; the one place the two collide ("Beat your number by 3.3" on Home vs "+2.6 vs index · 9 PTS" on the receipt for the same round) reads as a bug. The iPhone app confesses ("A preview at 100% of your number — your league's own math scores it on the books"); the web says nothing. | OBS (collision), ORG, NOV, JOIN, COMP, SKEP (could not say what 95% does) | 2 |
| H3 | **The endgame is one bylaw row.** "CUP FINAL · Final 4 weeks · scored fresh" is the entire explanation of how the season is won, four taps deep behind a collapsed disclosure. Seven of eight said some version of "I honestly can't tell you how the winner is decided." The tiebreak ladder exists in spec §14.3 and in `close_season`; it exists nowhere a user can see. | all but IOS mention it; none can explain it | 2 |
| H4 | **The sign of "vs your index" inverts golf intuition, by design.** Spec §2.1 defines PvI as positive = beat your number; the client renders `−3.7` in red for a bad round. Every golfer tester read minus as "under = good" at least once. Decision D1 said the display should be *words* ("beat your number by 1.4"); the posted card obeys, the form, receipt, standings and You tab still show bare signed numbers. One round was described three ways in four minutes. | ORG, NOV, JOIN, CAS, COMP, SKEP, OBS | 3 |
| H5 | **The rules exist, in excellent prose, four taps deep and in three vocabularies.** "How scoring works" (the best 250 words in the product) is reachable only via League tab → collapsed "LEAGUE RULES & PRO SHOP" → link, or the bottom of the You tab. Verification is "GHIN rounds" on the preset card, "Attested" on the review, "auto-attested" on the live screen — and decision D13 said the only user-facing word would be "Vouch" (0 occurrences in `index.html`; "attested" ×15). | all 8 | 4 |
| H6 | **The money model was understood by everyone; the payment path by no one.** 8/8 explained "the app keeps the ledger, money moves between friends." 0/8 could say how, when, or to whom they pay the buy-in. The organizer path defaults to a hidden $75/player behind "Customize". "Membership lands at launch" appears twice with no price. | all 8 | 5 |

**INTERPRETATION of the pattern.** The testers reconstructed spec §1's pipeline stages 1–3 (**POST → SCORE → COUNT**) almost verbatim, unaided. Stages 4–5 (**RANK → CROWN**) are a blank in every explanation. The mental model is not wrong; it is *truncated*: a season with a head and no tail, and no sentence anywhere that says why today's round matters (D51's stake line is decided and unbuilt).

---

## 2. The rules table

Legend — **D** discover unaided · **U** understand · **P** predict the consequence · **E** explain to a friend · **M** UI reinforces it at the right moment. Values: **Y** yes · **P** partial · **N** no. **Conf.** below 8 is flagged (⚑).

### 2.1 Scoring & points

| # | Rule (as the product means it) | Where the UI states it | D | U | P | E | M | Conf. | Tester evidence |
|---|---|---|---|---|---|---|---|---|---|
| R1 | Every posted round scores 5/6/7/9/12 in five bands vs your own number (spec §2.2). | Post form "POINT BANDS"; "How scoring works"; welcome sheet | Y | Y | Y | Y | P | ⚑ 7 | 7/8 gave the numbers in their explanation (IOS: "somehow that turns into points"). Points appear on the form but never on the posted card or the web receipt (ORG `71-round-detail.jpg`, NOV `77-round-detail.jpg`, CAS `56-G04`). Three label sets for one band (NOV N-37). Band edges overlap in copy ("by 3+" / "by 1–3"; SKEP SK-05). |
| R2 | "Beat it by X" is measured in **differential vs index** (slope-adjusted), not strokes. | Receipt arithmetic only | P | P | N | P | N | ⚑ 4 | COMP reverse-engineered it from the receipt ("74 at 72.4/133 → 1.4 differential → +5.0"); SKEP assumed "net three under handicap-adjusted expectation"; CAS: "some course-adjusted score. Formula shown, meaning not." |
| R3 | **Sign convention: + = beat your number, − = worse** (spec §2.1, D1). | Form `calcVs` (`index.html:6339`), receipt (`:11519`), standings "Avg vs index", You "Best vs index" | Y | N | N | N | N | ⚑ 3 | NOV: "USER ASSUMPTION on first read: 'I beat my index by 3.7 — why only 5 points?'" (`71-pre-post2.jpg`). ORG `68-round-filled.jpg` "-1.7 VS YOUR INDEX" under "A little loose". CAS: same round as "-9.8 vs your index" → "9.8 over your number" → "+0.0 — PLAYED TO IT". SKEP: "Best vs index -4.5 · Career best". OBS: "'Avg vs index' is negative and red for both of us while my rounds 'beat my number'". |
| R4 | Points are visible on every round after the fact (§16 receipts). | In-season receipt list shows "+2.6 vs index · 9 PTS" (OBS `10-my-row.jpg`); pre-season receipts show no points row | P | P | — | — | N | ⚑ 5 | The receipt code has a `Points` row (`index.html:11522`) that renders only when the round is in a season — so exactly the testers who most needed "did this count?" saw no points line. |

### 2.2 Handicap application

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R5 | Your index builds from scores (WHS-lite), establishes at 3 rounds; a typed index is a **starter** the engine overtakes. | Golfer card help; "How scoring works"; Card & settings | Y | P | P | P | P | ⚑ 6 | Understood by ORG/NOV/COMP/SKEP but with alarm: COMP "having [a real GHIN 6.4] replaced by a 3-round WHS-lite number is alarming… which number does the league use?" Two truths on adjacent screens: Home "INDEX 0 OF 3 · building" vs Members "INDEX 14.2" (ORG `14`, `50`; NOV N-17). GHIN copy "that's identity, not your number" read three times by NOV and still cryptic. |
| R6 | **Playing index = index × allowance (Standard 95%)** — applied by `v_rounds_ranked` (`baseline.sql:1360`). | Bylaws row "HANDICAP ALLOWANCE 95%"; preset card "95% hcp" | P | N | N | N | N | ⚑ 2 | ORG: "the panel gives no hint whether -1.7 is against 14.2 or 13.5. I cannot reproduce the number by hand." COMP: "The 95% allowance never shows up in any calculation I saw (preview, receipt, live strokes)." NOV: "Does an 18.2 play as 17.3?" **OBS found the collision without knowing it:** Home card "Beat your number by 3.3" vs receipt "+2.6 vs index · 9 PTS" for the Aug 16 round — "by this table 3.3 would be 12 pts." See §3.2 for the arithmetic. |
| R7 | With no index yet, what are you scored against? (D49: score normally off the starter, badge "provisional".) | Nothing | N | N | N | N | N | ⚑ 2 | CAS (no index, 2 rounds): receipt "27.8 DIFFERENTIAL · YOUR NUMBER THAT DAY 27.8 · Against your number +0.0 — PLAYED TO IT" (`56-G04-round-receipt.jpg`) — "circular for a new golfer; 'played to it' is guaranteed." No "provisional" badge exists in `index.html` (grep: 0 hits). The 103 posted to his card by someone else's live game repeated the pattern: "28.0 / 28.0 / +0.0". |
| R8 | Live games estimate a missing index at 18. | Live setup: "Leave index blank for an estimated 18." | Y | Y | P | P | N | ⚑ 5 | Stated for guests; CAS was silently shown as "Jordan · EST 18.0 IDX" and "$5 match decided by a silent default" (A21). |

### 2.3 What counts

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R9 | **Best 4 rounds a month count for your squad; a better round bumps your worst counter, in real time** (spec §3.1). | Post form footer; scoring sheet; bylaws "COUNTING CAP"; standings tile "COUNTING ROUNDS 1/4"; receipt "BUMPED" | Y | Y | Y | Y | Y | 8 | The best-taught rule in the product: 7/8 said it verbatim. OBS: "Bumped rounds still happened — a better round took their monthly slot" — "explained inline, fine." Minor: COMP could not tell whether the individual Pts column is capped too. |
| R10 | **Rounds played before `starts_on` are not in the season** (`v_rounds_ranked` joins `seasons` on `played_on between starts_on and ends_on`, `baseline.sql:1372`). They build your index only. | Clubhouse kickoff card only: "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`index.html:12225`) | N | N | N | N | N | ⚑ 1 | Contradicted by: the post form's live preview (`recalc`, `index.html:6341` — no date check); the Home hero "The season's on. *Rounds count from today.*" (`:10105`, shown whenever `state.phase==='season'`, i.e. from lock, before the first tee — `:10076`); the ⊕ door "counts on your card and in every league"; the live finish "Finish round & post to season". NOV `78-standings-after.jpg`, JOIN `51-AD`, CAS `57-H01`, COMP `40`, SKEP `37`, ORG `72`: all zeros after posting. CAS: "the first thing the app promised me (5 points) didn't happen and I had to infer why." |
| R11 | Rounds belong to your profile ("your card") and are read by every league you're in (data model: leagues are lenses). | ⊕ door: "counts on your card and in every league"; How it works | P | N | N | N | N | ⚑ 4 | The lens model was never grasped. NOV: "'COUNTS ON YOUR CARD' — as a novice I read that as 'counted'." SKEP: "'Card' means five different things (your card, on the card, scorecard, settlement card, Post card)." |
| R12 | Nine-hole rounds post at half value, half a round (D72). | Post form help; receipt "HALF VALUE · HALF A ROUND" | Y | Y | Y | — | Y | ⚑ 7 | Stated where met; only OBS saw one ("2026-07-24 · 9 HOLES · BUMPED · 3 PTS"). Not tested by anyone else. |
| R13 | Round eligibility under the preset (Standard: rated courses, sim ok; Cutthroat: rated tees, no 9-hole — spec §8). | Preset cards: "any course" / "GHIN rounds" / "rated tees" | P | N | N | N | N | ⚑ 2 | ORG: "'GHIN rounds' — does Standard mean my buddies without a GHIN can't post?" NOV: "does this mean players must ALSO post to GHIN? Does the app check?" SKEP: "Nothing about… which tees are allowed, or whether a round with non-members counts." Nothing on the post form enforces or mentions it. |

### 2.4 Floors, byes, months, weeks

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R14 | **Participation floor 2/month; −5 squad points per round short** (spec §3.2). | Home fine print; wizard (i); bylaws; scoring sheet; welcome sheet | Y | Y | P | Y | P | ⚑ 7 | 7/8 explained it. Flagged for three inconsistent phrasings (JOIN J-08 quotes all three) and for firing where it cannot apply: shown on a league-less Home (ORG `14`, NOV `10`), on a solo league ("−5 sqd pts" for "Individual — no squads", OBS `21-bylaws-open.jpg`), and a week before the season ("MONTH CLOSES in 2 days" + floor warning, CAS A9, SKEP SK-12). |
| R15 | **The season bye auto-covers the first floor miss** (D14); the Pro can also grant one. | Scoring sheet: "Miss it once and your season bye covers you automatically… the floor bites from the second miss." | P | P | P | P | N | ⚑ 4 | Only in the scoring sheet. The wizard (i) still says the pre-D14 rule: "One **Pro-approved** bye month per season" (`index.html:3318`). NOV noticed: "'Pro-approved' vs 'automatic'." ORG: "'bye' is a new mechanic that appears only here." |
| R16 | **Floors are waived in partial edge months** (§14.0). | Home: "Short months are waived."; iOS Home: "Partial month · floors waived"; iOS Clubhouse: "August is a short month — no floor to clear." | P | N | N | N | P | ⚑ 4 | SKEP: "'short month' is undefined (a month with fewer days? a partial month?)". ORG glossary: "Short months — ? partial calendar months where the floor is waived — yes [confusing]". IOS: "what floors are and why they're waived." |
| R17 | The month closes on the 1st: floor penalties assessed into the ledger, standings snapshot, board post (§14.2). | Home pill "MONTH CLOSES in 2 days"; board "July closed — Ledger posted · Partial month, floors waived" | Y | N | N | N | N | ⚑ 3 | OBS: "'month closes' (what closes? what happens?)". CAS: "USER ASSUMPTION: 'Month closes in 2 days' means I need 2 rounds in the next 2 days." SKEP: "Do I owe 2 rounds in the 2 remaining days of August, before the season even starts?" |
| R18 | There is no weekly obligation. Weeks are Sunday-night snapshots, the Cup Final window unit, and (as of migration `20260829091000`, built the day of the audit) the weekly clash (D52/D108). | Calendar dots "Week closes — snapshot recorded"; standings "Δ WK" | N | N | N | N | N | ⚑ 2 | NOV's rules table: "Miss a week — Nowhere — 'week' only exists as a Sunday snapshot — 2/10." NOV: "week/month/season are three clocks, never explained together." IOS: Home "WEEK 4 OF 14" vs Clubhouse "WK 4 / 13". OBS: "'Δ WK +10' though my last round was two weeks earlier." No tester saw a clash. |

### 2.5 Season shape, lock, squads

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R19 | A season is N whole weeks from a first-tee weekday; ends the same weekday. | Wizard "Season length"; Clubhouse header "Sat Sep 5 → Sat Jan 2 · 17 wks" | Y | Y | Y | Y | Y | ⚑ 7 | Clear once inside a league (ORG, NOV 9/10). Flagged because a joiner cannot see it before committing (JOIN: "No start date, no end date, no length before commit"), and IOS shows two different week counts. You-tab says "FIRST TEE SUN SEP 5" for a Saturday (NOV, `index.html:16863` hardcodes "SUN"). |
| R20 | **Lock** = the Pro freezes the bylaws, the draw runs, invites open (D40); the season starts at first tee; the endgame dial stays switchable. | "LOCKS AT FIRST TEE" (header) · "Lock the bylaws & form the squads" (button) · "You can rename it any time before the bylaws lock" · "The bylaws · locked at first tee" | Y | N | N | N | N | ⚑ 3 | ORG: "Three different lock moments in one screen." NOV: "Catch-22 for a novice: you must commit before you can rally anyone." The "locked" bylaws still offer "Finish: Cup Final — switch to points table" (NOV). Members (JOIN, CAS, COMP, SKEP) were shown the Pro's lock button on their own Home. |
| R21 | Minimum four golfers to tee off (D58 gate). | Wizard step 3 footer only | N | Y | N | P | N | ⚑ 4 | NOV: "revealed on the LAST step. I have three people total." ORG: "'3 SEATS OPEN' reads as a capacity of 4 for a league meant for 7." NOV then saw "SEASON LIVE" with one golfer — the hero copy, not the gate, is what misled (see R10). |
| R22 | **Squads** are teams (2 by default) drawn blind at lock; squad month = Σ members' counting points − penalties (§3.3). | Wizard Customize (i) — the *only* definition; Home floor line; standings | N | P | N | P | N | ⚑ 4 | NOV: "THIS is the first definition of 'squad' (= team), and it is behind an (i) on an optional Customize panel." SKEP: "Team structure never introduced until the collapsed bylaws on tab six." CAS: "USER ASSUMPTION: 'squad' = the whole league." Nobody learned their own squad. Uneven squads (3 v 4): "Nothing says how uneven squads are scored" (ORG). |
| R23 | Captains are an optional label (§15). | Standings "CAPT. —"; League tab "LIVE NOW — CAPTAINS READY" | N | N | N | N | N | ⚑ 2 | NOV: "squads have captains? Who picks them?" ORG: "There are no captains anywhere on this screen." Squad status told four ways for one unlocked league (ORG ORG-10). |

### 2.6 The endgame

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R24 | **Cup Final = the final four weeks, scored fresh under the league's counting rules; seeds lock at `ends_on − 27`; 2-squad: both in, leader +10; solo: top 2** (§14.0/§14.3). | Bylaws row "CUP FINAL · Final 4 weeks · from Sun Dec 6 · scored fresh"; wizard (i) "top seeds race fresh"; teams copy "+10 head start"; covenant "FINISH · Cup Final · final 4 weeks" | P | N | N | N | N | ⚑ 2 | COMP: "'Scored fresh' is never defined. Who plays the Cup Final? Both squads? Do the first 13 weeks matter at all?" OBS: "Home says 'You lead by 22 points.' Nowhere… does it say that lead is (apparently) a seed." NOV: "What is a seed? Top how many? What happens to non-seeds?" ORG: "'+10 head start' — 10 of what?" CAS: "'scored fresh' whatever that means." The tester who read the most — OBS, 29 min — rated rulesClear 3 on this alone. |
| R25 | The alternative endgame: the points table crowns the leader (dial 008). | Wizard (i); "Leagues vs events" explainer | P | Y | Y | P | — | ⚑ 5 | Only the two organizers saw the dial; ORG understood it. Members never learn which endgame their league runs except via the bylaws row. |
| R26 | **Tiebreak ladder**: h2h months won → best single month → fewest rounds used → logged coin flip (§14.3; stored as `tiebreak_rung`). | Nowhere | N | N | N | N | N | ⚑ 1 | COMP: "Ties — Nothing. Not in bylaws, scoring sheet, standings footnote, or the welcome sheet — 1." OBS: "how a tie breaks: nowhere." No occurrence of the ladder in `index.html` outside the ceremony's stored rung. |
| R27 | Clinch vocabulary: **LOCKED / cup seed / TOP SEED · +10 / EVERYONE ADVANCES — n CONTENDERS, K SEATS / PROJECTED UNDER A GENEROUS CEILING** (D24 honesty rule, D26 the Climb). | Standings "THE CLIMB" | Y | N | N | N | N | ⚑ 2 | NOV `36-clubhouse-full.jpg`: "TOP SEED · +10 … TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING" over two empty squads — "I do not know what any of these mean. Why does Squad 1 have +10 with zero rounds?" IOS `03-clubhouse.jpg`: "LOCKED… both rows carry it, so it cannot distinguish us"; "advance to what? seats where?" OBS: "what 'LOCKED' locks (a 'cup seed' — what is a cup seed?)". |
| R28 | The individual layer runs in parallel: Points King (15% of pot), Most Improved, Iron Man (§4). | Standings footnote: "…All three run in parallel with the squad race — bylaws §4." | Y | P | P | P | P | ⚑ 6 | Understood by most from the footnote; "bylaws §4" cites a document nobody is shown (ORG, NOV, JOIN, SKEP). JOIN: "only Points King's 15% is stated." OBS: "'squad race' in an Individual — no squads league." |
| R29 | A season ends in a ceremony: champion, margin, deciding rung, per-person payout, trophies (D66). | "Leagues vs events": "the endgame settles it"; You: "No silverware yet — every season starts level." | N | N | N | N | N | ⚑ 3 | OBS Journey F: "'the database reached its final row.' There is no countdown to Dec 22, no 'final starts in N weeks', no bracket/seed graphic, no tiebreak text, no preview of the settlement card." (No finished season existed to observe; judged on what a live season says about its ending.) |

### 2.7 Money & pot

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R30 | **Buy-in per player; pot = stake × roster; the app keeps the ledger; money moves friend-to-friend; the Pro marks who paid** (§7, D39, D106). | Covenant; welcome sheet; Pot tab; scoring sheet; legal page | Y | Y | P | Y | P | ⚑ 6 | 8/8 explained the ledger. 0/8 could say how to pay: JOIN "who do I pay, how, by when — none of it"; CAS "pay Casey cash/Venmo and hope he ticks the box." Organizer defaults: "$75 (DEFAULT). (!!!) hidden behind 'Customize'" (NOV N-02, ORG ORG-04). First disclosed to invitees *after* account creation (SKEP SK-03: "a skeptic reads this as a bait-and-switch"). |
| R31 | Pot split 60/25/15 champ / runner-up / Points King; squad shares resolve to people at the ceremony (D66). | Wizard (i); bylaws; Pot tab "$150 Cup champs · $63 Runner-up · $38 Points king" | Y | P | N | P | N | ⚑ 5 | ORG: "$30 + $13 + $8 = $51 on a $50 pot… the app never says how a squad payout is divided among its members." COMP: "USER ASSUMPTION: 'Cup champs $150' is what I win. ACTUAL: unknown." SKEP: "'Cup champs' (plural) first hint of a team prize." |
| R32 | The pot has two numbers: owed (stake × roster) and collected (D106). | Pot tab "$250 · 5 × $50 · $0 collected · 5 still owe" | Y | P | N | — | N | ⚑ 5 | OBS: "'0/2 in' and '2 still owe' sit directly above two names with ✓ marks. I read the ✓ as 'paid'." Six weeks in, $0 collected, no reminder path (OBS #32). |
| R33 | Pricing: a league pass paid to Cup Season, pilot free (D56/D101). | "Pro Shop · CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE"; Settings "PLAN FREE · PILOT" | Y | N | N | N | N | ⚑ 3 | ORG: "I cannot tell whether we will be charged mid-season, who pays (me? each player?), or how much." CAS A32: "I don't know if I'll be asked to pay the app on top of the pot." SKEP: "no price, no scope." |
| R34 | **Side-game money settles between players and never reaches the pot ledger; "stakes" on the Pot tab are pride, never money** (§13.2, D64). | Live: "SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN YOU"; Pot: "Pride, on the books — never money" | P | N | N | N | N | ⚑ 3 | NOV: "USER ASSUMPTION (before): side-game dollars go on the Pot ledger. ACTUAL: … the app that 'keeps the books' doesn't keep these." COMP: "the $60 lives only as a board card." ORG: "four money nouns (buy-in, pot, stake per side, stake) with different rules each." |

### 2.8 Side games and their effect on the season

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R35 | **A live round posts every complete member card to the season (attested); the game result itself never touches cup points** (§13.2, modes §5). | Live scoring paragraph: "Only league members' rounds post to the season."; finish sheet "ONE FINISH — EVERY MEMBER'S CARD POSTS" | Y | P | P | P | N | ⚑ 6 | ORG and COMP got it (sideGames 8/10 each). CAS A36: "Nothing in one place states that side games don't affect season points while the gross score does." NOV: "the ROUND still feeds the league… the GAME result is separate — integrated at the ledger level, not at the points level." (Also wrong pre-season, per R10.) |
| R36 | **Verification.** Standard = Attested: a group scoring together vouches by construction; unattested rounds still score (§6). D13: the user-facing word is "Vouch". | Preset card "GHIN rounds"; review "VERIFICATION Attested"; live "auto-attested"; receipt "Attested · PLAYED WITH THE GROUP" | P | N | N | N | N | ⚑ 3 | ORG ORG-07: "Verification shown as 'Attested' though Standard preset said 'GHIN rounds'; 'attested' is only explained on the live scoring screen." SKEP: "attested by whom? the form asks nobody… nobody attested my 91." COMP: "one phone can post + attest four cards (I did)." `index.html`: "vouch" ×0, "attested" ×15. |
| R37 | Anyone who seats you in a live round can post an attested score to your card. | Nothing, to the person it happens to | N | N | N | N | N | ⚑ 2 | CAS A7: "'You · Played to your number · 103 gross' appeared on my card from another member's skins game… no notification, no confirmation; my index count moved. Someone else can put a 103 on my record." |
| R38 | Game rules: Match play (net best ball off the low man), Wolf, Skins (carry), Sunningdale. | One-line blurbs after selecting each | Y | P | P | P | P | ⚑ 4 | Skins and match play understood; "Wolf is never explained" (NOV — though a fuller Wolf blurb exists at `index.html:8846` once four are seated, which COMP saw); Sunningdale "no idea" (ORG); "net best ball", "SI", "strokes off the low man", "riding", "bank a unit" undefined (CAS, NOV). Nassau absent. |

### 2.9 Joining, roles, leaving

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R39 | Joining by code/link puts you on the pot sheet; the covenant shows buy-in, preset, floor, finish. | Covenant `11-J-after-take-me-in.jpg`: "BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks" | Y | P | N | P | P | ⚑ 4 | JOIN (3/10): "I did not know who was in it (not even that Casey ran it), when it started or ended, how a round scored, or how money moved." Landing copy "Enter your email and you're in" contradicts the four-step flow (J-05). "Not now" drops the invite (J-06). |
| R40 | Mid-season joins until halfway (floor prorates; late joiners → thinnest squad); dropouts → squad plays short; league cancellation with consent (§9, §15, D71). | Nothing a member sees | N | N | N | N | N | ⚑ 1 | No tester found any copy on leaving, dropping out, or joining late. "Cancel & delete this league (only possible before the first tee)" is the only lifecycle control, and it is "more prominent than the invite" (NOV). |
| R41 | Roles: only the Pro locks, draws, marks buy-ins, grants byes, rules on disputes. | "PRO — THAT'S YOU"; Settings "Your leagues · PLAYER" | N | N | N | N | N | ⚑ 3 | Every member tester was handed the Pro's tools: "Lock it in and invite your crew" hero (JOIN J-02, CAS A2, COMP, SKEP); "See the squads" opens the Pro's blind-draw tool with tappable chips (COMP, SKEP SK-18); Pot rows look tickable (CAS A15). NOV: "'Pro-approved' means I'll be adjudicating my friends' vacations. Nobody told me that would be my job." |

### 2.10 Correcting mistakes & disputes

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R42 | **Rounds are immutable** (§16); a wrong round is deleted and re-posted (`delete_round()`); there is no edit. | Unlabeled ✕ on You › Recent rounds; native `confirm()` "Delete this round? It leaves your card and any league standings it counted toward." | N | P | P | N | N | ⚑ 3 | NOV N-12: "no edit/delete path visible from the round receipt or posted card." ORG: "a wrong score means delete and re-post; a wrong date or course, same. Nothing tells you that." CAS: "hard to find when you need it, easy to hit by accident once found." |
| R43 | Disputes: the Pro rules; every ruling is a logged, visible ledger entry; settled events never change (D50 — "copy-only build… in a future UX pass"). | Nowhere | N | N | N | N | N | ⚑ 1 | No tester found a dispute path. CAS on the 103: "no obvious way to dispute except the ✕ on the You tab." |
| R44 | Deleting a round removes what it earned. | The confirm text | — | P | N | — | N | ⚑ 4 | COMP: "Display-case badges 'Broke 100 / Broke 90 / Broke 80 · 74 gross' SURVIVED the deletion with Lifetime 'Rounds posted 0'." ORG: "'Cups & events 1 · Played in' persists." |

### 2.11 Draft / squad formation

| # | Rule | Where stated | D | U | P | E | M | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| R45 | Blind draw (server-side, balanced, at lock) or Pro assign; live draft is Pro Shop roadmap (§15, D54, D58). | Wizard "How teams fill"; Form-squads screen "THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW" | Y | Y | P | P | N | ⚑ 5 | Organizers understood the dial. Members saw the tool, not the result: "SQUADS ARE FORMING · The Pro has the list" / "Squads · LIVE NOW — CAPTAINS READY" / both squads "Empty" (JOIN J-09, CAS A12, SKEP SK-15). "Draw failed. Something went wrong" hid the server's "Not enough golfers… Share the invite link first." (ORG, NOV). |

**Tally:** 45 rules. **1 at 8** (R9, best-4 counting). **44 flagged below 8**, of which 12 sit at 1–2: R10, R26, R40, R43 at 1; R6, R7, R13, R18, R23, R24, R27, R37 at 2.

---

## 3. The flagged rules — observation, intent, gap

### 3.1 Pre-season rounds (R10) — the one rule every poster hit

**OBSERVATION.** Six testers posted a round on Aug 29 into a league whose first tee is Sep 5. In every case the post form's live panel promised league points — ORG `68-round-filled.jpg` "LEAGUE POINTS THIS ROUND **6**"; COMP `35-preview-74.jpg` "**12** · You torched your number by 5.0. Sandbagger alert."; NOV/JOIN/CAS/SKEP "5". The result sheet said "COUNTS ON YOUR CARD" and nothing about points. Standings stayed "0 R · 0 Pts" (NOV `78-standings-after.jpg`, JOIN `51-AD-standings-after.jpg`, CAS `57-H01`, COMP `40`, SKEP `37`). The You tab said "THIS SEASON · Rounds posted 0" beside "LIFETIME · Rounds posted 1". The only sentence stating the rule is the Clubhouse kickoff card: "KICKS OFF IN 7 DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (NOV `36-clubhouse-full.jpg`). NOV's Home simultaneously read "DESERT DOGS · SEASON LIVE — The season's on. Rounds count from today."

**INTENT.** `v_rounds_ranked` joins a round into a season only when `played_on between starts_on and ends_on` (`supabase/migrations/00000000000000_initial_baseline.sql:1372`) — rounds before the first tee are, correctly, index-building practice. The Clubhouse copy is right.

**GAP (code-confirmed).** (a) The form's `recalc()` (`index.html:6341`) computes `pts` from `pointsFor(vs)` with no season-date check, so it advertises league points for any date. (b) The Home hero's branch `const starter = state.phase==='season'` (`:10076`) renders "The season's on. Rounds count from today." (`:10105`) as soon as the bylaws lock — i.e. in precisely the pre-first-tee state where `atStarter()` (`:11981`) makes the Clubhouse say the opposite. (c) The result sheet and receipt never say "season starts Sep 5". Every tester's verbatim explanation carries the scar: CAS "I'm not sure my rounds this week even count"; JOIN "I think it's because the season doesn't start till the 5th, but nothing on the screen said that"; NOV "one screen says the season started today and another says nothing counts till next Saturday."

### 3.2 The invisible allowance (R6) — a correct rule that reads as a bug

**OBSERVATION.** OBS, in a live season, saw the same Aug 16 round described as "You · **Beat your number by 3.3** · 85 · Troon North" on Home and as "2026-08-16 · **+2.6 vs index · 9 PTS**" in the standings receipt (`10-my-row.jpg`). He flagged it as P1: "Two numbers, two bands, one round… by this table 3.3 would be 12 pts."

**INTERPRETATION (arithmetic, inferred — `index_at_post` not visible to the tester).** The You tab lists that round as "Troon North 85 · **10.3**" (differential). Home's card is computed at 100% (`pvi = index_at_post − differential`, the client comment at `index.html:16641`): 13.6 − 10.3 = **3.3**. The league view applies the Standard preset's 95% (`round(index_at_post × handicap_allowance/100 − differential, 1)`, `baseline.sql:1360`): 12.9 − 10.3 = **2.6**. Both are right. The 95% allowance is the entire difference, and it demoted the round from the 12-band the Home card implies to the 9 the league paid.

**INTENT.** Spec §2.1 `Playing Index = Index × Handicap Allowance %`; D8/D48 retired the *dial* but kept the preset's fixed value as an internal constant; D2 made allowance a "never-shown term, visible only inside receipts."

**GAP.** The web receipt (`showRoundReceipt`, `:11500–11524`) has no allowance row — only the *demo* receipt (`showRound`, `:11912`, "Index × allowance · 14.2 × 95%") ever shows it. The iOS post screen at least says "A preview at 100% of your number — your league's own math scores it on the books" (`apps/ios/CupSeason/Post/PostRoundScreen.swift:406`); the web form says nothing. Result: ORG "I cannot reproduce the number by hand from what is on screen"; COMP "as a 6.4 I also have no reason to believe the flat 12/9/7/6/5 bands aren't tilted toward high-variance 20-handicaps" — a fairness doubt the visible math cannot answer. D2's "never shown" became "never explained," which is a different thing when the number changes between two screens.

### 3.3 The sign convention (R3) — designed, and still wrong for golfers

**OBSERVATION.** ORG `68-round-filled.jpg`: "**-1.7** VS YOUR INDEX" in red beneath "A little loose, still cash in the bank"; result sheet "1.7 over your number"; receipt `71-round-detail.jpg` "Against your number **-1.7 — A LITTLE LOOSE**". NOV: "USER ASSUMPTION on first read: 'I beat my index by 3.7 — why only 5 points?'" CAS, three surfaces in four minutes: "-9.8 vs your index" (form) → "9.8 over your number" (card) → "+0.0 — PLAYED TO IT" (receipt). SKEP: "'Best vs index -4.5 · Career best' … how is that 4.5 UNDER my index?" COMP was the only tester who read + as good, and only after seeing green.

**INTENT.** Spec §2.1: "PvI is the universal currency: positive = you beat your number." D1: PvI stays the engine currency; the *display* becomes words ("beat your number by 1.4"). `vsPhrase()` (`index.html:5710`) does exactly that for the posted card.

**GAP.** The bare signed number survives on the form (`:6339`), the receipt's verdict line (`:11519`), the standings "Avg vs index" column (`:11412`), the player receipt list (`:11481`), and You's "Best vs index / Avg vs index" (`:2884`). Golf's only signed convention is score-to-par, where minus is good; the product's convention is the reverse, and it is never stated. D1 was applied to one surface of five.

### 3.4 The endgame (R24–R27, R29) — a season with no visible ending

**OBSERVATION.** The bylaws row is the whole story: OBS `21-bylaws-open.jpg` "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" behind "▸ LEAGUE RULES & PRO SHOP". Above it, Home says "1st · You lead by 22 points over Jade." The Climb's captions — "LOCKED", "JERECHO FISCHBECK HAS LOCKED A CUP SEED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (OBS `08-club-top.jpg`; IOS `03-clubhouse.jpg`) — and the empty-league version "TOP SEED · +10 · TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING" (NOV `36-clubhouse-full.jpg`) are the only foreshadowing. The wizard (i) adds "top seeds race fresh" and the teams copy "the regular-season leader carries a +10 head start" (`index.html:12001`) — organizer-only surfaces.

**INTENT.** §14.3: seeds lock at `ends_on − 27`; 2-squad leagues both advance with the leader +10; solo top-2; finalists race on window points; ladder h2h months won → best month → fewest rounds → coin flip; non-finalists keep the individual races. D4 (2026-07-15) named the exact failure — "the points leader discovers at reset time that the lead 'vanished' — reads as a rug-pull" — and prescribed a season-long foreshadow. D105 (2026-08-28, PROPOSED) admits the race itself never shipped: "the flagship moment of the product is invisible."

**GAP.** D4's foreshadow shipped as *vocabulary* (LOCKED, seed, seats, ceiling) without *definitions*, and the vocabulary is what testers tripped on. "Scored fresh" is used seven times in copy and defined zero times. The +10 head start appears only in an organizer (i). The ladder appears nowhere. Nobody in a 2-player league is told that "EVERYONE ADVANCES" makes the final structurally hollow (OBS). Seven of eight explanations end the season with a shrug: OBS "I honestly can't tell you how the winner is decided"; COMP "I honestly don't know what that means yet"; SKEP "a final few weeks that decides who takes the pot."

### 3.5 Where the rules live and what they are called (R1, R14–R16, R36 — the H5 cluster)

**OBSERVATION.** The path to "How scoring works": Clubhouse → league room → League sub-tab → expand "▶ LEAGUE RULES & PRO SHOP" → "[How scoring & handicaps work →]" (ORG `49-scoring-help2.jpg`, found "18 minutes after starting the wizard, and only because the lock failed"). Also the bottom of the You tab. Not linked from Home, Standings, the wizard's preset step, or the post form's bands. The welcome sheet links it — for joiners only.

Three vocabularies for one rule: preset card "95% hcp · **GHIN rounds** · best 4 / mo count · 2-round floor" (`index.html:3250`) → review "VERIFICATION **Attested**" (ORG `30-wizard-step3.jpg`) → live "Scores entered together are **auto-attested**". Three phrasings of the floor (JOIN J-08). Three label sets for the bottom band: "Rough day, posted anyway" / "Posted anyway · rough day" / "POSTED ANYWAY". Two names for the bye's grantor (wizard "Pro-approved", sheet "automatically").

**INTENT.** D3 wanted cap/floor as prose at the door; D13 wanted "Vouch" as the only user-facing word; D14 made the bye automatic; D82 put depth "at the doors"; the vision's success metric is "never need a tutorial."

**GAP.** The prose exists and is good; it is unreachable from the moments of confusion (a zero in standings, a preset card, a "-3.7"). The preset card's "GHIN rounds" is the spec §8 *index-source* row surfacing where the *verification* row was expected; both are true and neither is explained. D13 was never applied. D14's wizard copy was never updated. Every persona's verdict includes some form of "the organizer will have to explain it" — the exact tutorial the vision forbids.

### 3.6 Money (R30–R34)

**OBSERVATION.** Understood: 8/8 said "the app keeps the tab / ledger, money moves between friends." Not understood: the payment path — JOIN "the buy-in rows look like checkboxes but tapping only toasts 'The Pro marks buy-ins as money moves between you'"; CAS "pay Casey cash/Venmo and hope he ticks the box." Organizer trap: buy-in "$75 (DEFAULT)… hidden behind 'Customize'" with "Use these defaults →" as the primary button (NOV `19-wizard-customize-full.jpg`, ORG `21`–`22`). Squad share: "$30 CUP CHAMPS … the app never says how a squad payout is divided" (ORG); "$51 on a $50 pot" (ORG), "$251 on $250" (COMP). Side-game cash: "the $60 lives only as a board card" (COMP `60-pot-after-skins.jpg`). Membership: "Pro Shop … COMING AT LAUNCH · THE PILOT RIDES FREE" and Settings "PLAN FREE · PILOT" — no price (ORG, CAS, SKEP).

**INTENT.** §7 default $75; D39 ledger language; D66 per-person payout at the ceremony with explicit rounding; D106 owed vs collected; D70 no pot for $0 leagues; §13.2 side games "app tracks, Venmo moves, nothing held"; D101 league pass priced at iOS launch.

**GAP.** The ledger *concept* landed (the best-communicated business rule in the product). The ledger *mechanics* did not: who pays whom, by when, how a squad's 60% becomes a person's number before the ceremony, and why the skins settlement the app just computed is not "on the books." The legal page's Prize Pool Disclaimer "tells me more about what the product is than the door does" (ORG). The spec's $75 default is the spec's choice; surfacing it only behind Customize is the UI's.

### 3.7 Consent, roles and correction (R37, R41, R42–R44)

**OBSERVATION.** CAS: "Someone else can put a 103 on my record" — a live game seated him, finished, and posted an attested 103 to his card with no notification. JOIN, CAS, COMP, SKEP: a plain member's Home hero is "Lock it in and invite your crew" → the Pro's "CREATE YOUR LEAGUE · Review the bylaws, then lock it in" wizard with a live lock button (`39-U-lock-it-in.jpg`, `50-lock-page.jpg`). Correction: the only control is an unlabeled ✕ on You › Recent rounds with a browser `confirm()`; the receipt and posted card have no fix path (NOV N-12, CAS A26, ORG ORG-35).

**INTENT.** §16 rounds immutable, `delete_round()` only; §6 attestation by construction; D40 "a member must never see the Pro's configuration tool"; D50 the dispute paragraph "stated at join (covenant) and in league fine print" — logged as copy-only, not built; D96's forming-hero CTA (2026-08-04) is what routes members into the wizard.

**GAP.** D40's rule was undone by D96's CTA: the forming hero wires "Lock it in and invite your crew" to the wizard for any member of an unlocked league with no role check (`index.html:10098–10112`, `wire('[data-hform]', nextStep.go)` gated only on `!starter`) — a regression the decision log does not record. D50's paragraph is absent from the covenant that testers read (`11-J-after-take-me-in.jpg` shows four rows and a money sentence). Attestation-by-construction is a fairness feature for the group and a consent problem for the individual, and the product tells the individual nothing.

---

## 4. Prioritization — what a user must understand, and when

Rules are placed by *when the consequence first bites*. A rule can be well-taught later and still be a MUST here if the user commits before meeting it.

### 4.1 MUST understand before joining (the consent surface)

| Rule | What the user must be able to say | Currently on the covenant? | Conf. |
|---|---|---|---|
| R30 | "It's $50, I pay [Casey] by [Venmo/cash] before [date]; the app only keeps score of who paid." | Amount yes; path no | 6 |
| R39 | "It's [Casey]'s league, [5] people, [Sep 5 → Jan 2]." | No roster, no Pro, no dates | 4 |
| R22 | "We'll be split into two random teams; my points go to my team." | No — "squad" first defined in an organizer (i) | 4 |
| R14 | "I owe two rounds a month or my team loses 5 per round short; the first miss is forgiven." | Floor yes; penalty and bye no | 7 |
| R1 + R3 | "Every round scores 5–12 against my own handicap; a bad day is still 5." | No (post-join welcome sheet has it) | 7 / 3 |
| R24 | "The last four weeks are a fresh playoff; the regular season decides seeds." | "FINISH · Cup Final · final 4 weeks" only | 2 |
| R41 | "The Pro runs it; I post rounds. Nothing on my screen is his job." | No | 3 |

### 4.2 MUST understand before the first round

| Rule | What the user must be able to say | Currently at the post form? | Conf. |
|---|---|---|---|
| R10 | "The season starts Sep 5 — this round builds my number, no league points yet." | **Contradicted** by the form's own points panel | 1 |
| R1 | "12 if I beat my number by 3, 5 if I just post." | Yes (the best-placed rule in the app) | 7 |
| R3 | "+ means I beat it, − means I didn't." / better: words, not signs | No; the red "-3.7" is the moment of confusion | 3 |
| R2 / R6 | "'Beat by 3' is on the differential, at 95% of my index." | No; iOS says "100% preview", web says nothing | 4 / 2 |
| R9 | "Only my best four this month count; a better round bumps my worst." | Yes | 8 |
| R11 | "The round lives on my card; every league I'm in reads it." | Half — "counts on your card" reads as "counted" | 4 |
| R13 | "Any course counts under Standard; here's what my tees need to be." | No | 2 |
| R42 | "If I typed it wrong, I delete it here and post again." | No — only on You tab, unlabeled | 3 |
| R36 / R37 | "Scoring together vouches for the round; anyone who seats me live can post to my card." | Live screen only, after tee-off | 3 / 2 |
| R7 | "Until I have 3 rounds I'm scored against a starter (or a provisional number)." | No; receipt reads "27.8 vs 27.8 · +0.0" | 2 |

### 4.3 Can learn during play (if the UI defines the term where it appears)

R15 bye · R16 short months · R17 month close · R12 nine holes · R5 index building · R28 individual titles · R27 clinch vocabulary (LOCKED / seed / seats — each needs a tap-definition) · R35 live rounds post, games don't score · R34 side money is off the ledger · R38 game rules · R8 estimated 18 · R32 owed vs collected · R45 how the draw works · R21 minimum four (organizer, step 1 not step 3) · R20 what "lock" freezes (organizer).

### 4.4 Nice to know — until the moment it isn't

R26 tiebreak ladder (becomes MUST at `ends_on − 27` and for any tie at the cut) · R25 the points-table alternative · R29 the ceremony (becomes MUST in the final week — OBS: "the Cup Final arrives unannounced") · R33 membership pricing (becomes MUST before a Pro asks six friends for $50 — ORG) · R40 late joins / dropouts / cancellation · R43 the dispute procedure (becomes MUST at the first contested 79) · R44 what deletion removes · R23 captains (delete the word until it means something).

---

## 5. Mental model

### 5.1 What a first-time user currently thinks Cup Season is

**At the door (0 taps), all eight, near-identically:** "a golf thing for a group; I type in scores; someone wins a cup." Every cold answer to "what is a season / league / cup / what am I competing for / against whom / how do rounds work" was *unknown* or a guess. Two testers flagged the visible `v23 · __CS_VERSION__` as "unfinished software" before a single tap (SKEP, ORG). SKEP: "The door is a wall with two handles."

**After 30–50 minutes, the model every tester rebuilt** (synthesized from the eight verbatim explanations; frequency in brackets):

> Cup Season runs a months-long golf league for a friend group [8/8]. Everyone posts real rounds from anywhere [8/8]. Each round is scored against your own handicap into 5–12 points, so a high handicap and a low one compete evenly [7/8]. Your best four rounds a month count for your squad [7/8]; you owe two a month or your squad loses points [7/8]. The league is split into two random squads [5/8]. There's a buy-in the app keeps a tab on but doesn't collect; you pay each other [7/8]. The last four weeks are a "Cup Final" that's "scored fresh" [7/8] — and I can't tell you what that means [7/7 who mentioned it]. On the course you can run skins, match play or Wolf in the app and it settles who owes who [6/8].

**What that model contains that the product intends:** spec §1's stages 1–3 (POST → SCORE → COUNT), the anti-sandbag ceiling and the 5-point floor ("you can't hurt your team by playing badly, only by not playing" — quoted back by four testers), the ledger posture (D39), the live-game/settlement layer (§13).

**What it lacks:** stages 4–5 (RANK → CROWN): how squads are compared, what a seed is, what the final does to accumulated points, how a tie breaks, what winning pays *me*. The lens model (rounds belong to the card, leagues read them). Any reason a *particular* round matters ("no rival, no gap to the leader, no 'this round matters because' line" — COMP; D51's stake line is unbuilt). The end of the story: OBS's retention curve falls from 6 at mid-season to 2 at season+30 days because "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it."

**How they hold it:** as a *fantasy league* analogy (ORG, NOV, SKEP use the phrase unprompted) — which is the spec's own category ("fantasy sports where your foursome are the athletes", §12). The analogy is doing the work the UI should: it supplies "squads," "points," "a final" as slots, and the testers fill each slot with a guess.

### 5.2 What it is supposed to be

From `product-vision-v1.0.md`: "Cup Season exists to make every round of golf matter because it belongs to a season." Golfers "build rivalries, win championships, create traditions." Principles: golf first; low friction; real golf; memory > statistics; the app should feel alive. Success metrics: "understand standings in under 10 seconds · **never need a tutorial**."

From `spec-v1.0.md`: one pipeline, five stages — **POST a round → SCORE it (bands vs your number) → COUNT it (best-N, floor, bye, partial months) → RANK squads (points race, the Climb, seeds) → CROWN a champion (Cup Final scored fresh or the points table; ladder; ceremony; per-person pot)**. Design principles: every posted round scores; steady bogey golf can win; volume can't buy the cup; set it once, argue never. Side games and events are *parallel ledgers* that never touch cup points (modes §5). The pot is a ledger with two numbers.

From the decision log, the product already *knows* which parts of this the UI fails: D1 (currency in words), D2 (two numbers per round), D3 (floor as prose at the door), D4 (foreshadow the reset), D5 (receipts), D13 (vouch), D24/D26 (honest clinch math with a face), D50 (the ruling), D51 (the stake line), D66 (an ending), D105 (a visible final). The mental-model gap is largely the gap between these decisions and what shipped.

### 5.3 Where the model breaks — noun by noun

| Noun | What the product means | What testers thought / said | Break |
|---|---|---|---|
| **League** | The competition container: crew + bylaws + pot + board + squads; can run many seasons ("SEASON I"). | Fine after the orientation card (8/8). But the door says "crew," the field says "LEAGUE CODE," the button says "invite code," the toast says "Invite code:" — "three names for one thing" (JOIN J-15). NOV: "I assumed crew = league; the app says buddies are a separate, points-free thing." | Naming, not concept. D11 assigned crew = people, league = competition; the door still leads with "crew." |
| **Season** | A dated window, N whole weeks from a first-tee weekday, with monthly machinery and a four-week final; phases forming → locked/starter → live → cup_final → complete. | Understood as dates once inside (ORG 9/10). Phases are the break: one unlocked, one-member league is "FORMING," "Squad formation," "LIVE NOW — CAPTAINS READY," and "is live" on four screens (ORG ORG-10); locked-before-first-tee is "SEASON LIVE — Rounds count from today" on Home and "BEFORE FIRST TEE · practice rounds" in the Clubhouse (NOV). | Four status strings for one state machine (D81 built the machine; the copy didn't follow). |
| **Round** | A profile fact (gross, rating, slope, date, index snapshot, differential) that every league *reads*; immutable; never mutated by a league. | "A round = any 18 or 9 you post, any day, any course" (NOV — correct). But "counts on your card" ≠ counted (NOV, SKEP); "card" = golfer card / scorecard / settlement card / Post card / "on the card" (SKEP SK-34: five meanings). | The lens model is invisible; the word "card" is overloaded five ways. |
| **Cup** | The season championship (the trophy), decided by the Cup Final or the points table. | "Still fuzzy" (ORG, COMP); "still not defined anywhere" (JOIN); "unclear whether it's the squad prize or the whole season" (CAS); ORG also read "Cups & events · 1 · Played in" as the app counting leagues as cups. | The product's *name* is the least-defined noun in it. |
| **Cup Final** | The final four weeks, scored fresh under the counting rules; seeds carry (+10 for the 2-squad leader); ladder on ties. | "the top squads start fresh" (NOV); "regular season only for seeding (guess)" (COMP); "some kind of Cup Final" (CAS); "the 22-point lead may mean nothing" (OBS). | One bylaw row; "scored fresh" undefined; seeds/+10/ladder unstated. |
| **Match / side game** | A live game (match play, Wolf, skins, Sunningdale) on a parallel ledger; the *round* posts, the *result* never touches cup points; money settles between players. | Mostly right when read at the live screen (ORG, COMP). Wrong assumption everywhere else: "side-game dollars go on the Pot ledger" (NOV, COMP); "does winning the match matter for the Cup?" (CAS). | Correct at the live door, absent from every season surface. |
| **Event** | The short game (Ryder, Major, Bracket-soon); its own trophy; stands alone or attaches to a league. | Nobody opened one. "Two teams · weekly vs-index duels · first to the clinch" read as "jargon; no relation to my league explained" (CAS A33, IOS). | Untested; blurbs are spec-speak. |
| **Standings** | Squad table + individual race + the Climb (a you-centered ladder with honest clinch math, D24/D26). | "Three redundant tables for two people" (OBS). LOCKED / seed / seats / +10 / ceiling undefined (OBS, NOV, IOS). Standings answer "who's ahead" but never "what do I need to do to win" (OBS: "Not answered anywhere"). Gap line drawn under the wrong row on iOS. | The Climb's *vocabulary* shipped without its *explanations*; the projection D24 promised is not a sentence anyone can read. |
| **Points** | Cup points per round (5–12) → counting points → squad month → season total; the individual layer runs beside it. | Per-round: understood (7/8). Aggregation: "I still don't totally get how the squad points and the individual points fit together" (CAS); "nothing says whether the individual Pts column is capped too" (COMP); "10 points back" with no leader named (IOS). | Round→points is taught; points→table is not. |
| **Pot** | Stake × roster (owed) and collected (cash); split 60/25/15 by role; resolved to people at the ceremony; a $0 league shows no pot. | The ledger: 8/8. The path: 0/8. "$0 collected · 5 still owe would just start an argument about who pays whom, which is exactly what the page claims to prevent" (JOIN). "Four money nouns" (ORG). | Concept landed; mechanics (pay whom, when; squad share per person; side cash) did not. |
| **Squad** | A team drawn at lock; squad points = Σ members' counting points − penalties. | "Squad = the whole league" (CAS); "three things at once — a team, a formation state, a points target" (SKEP); "I never learn mine" (JOIN). Used on Home before defined; defined only in an organizer (i). | Introduced by its penalty before its definition. |
| **The Pro** | The commissioner (locks, draws, marks buy-ins, grants byes, rules). | "For a beat I thought the app was assigning me a pro" (NOV); "a golf pro at a course" (CAS). Members were handed the Pro's tools (H-lock, draw, pot rows). | D15 chose the collision knowingly; the role boundary is the real break. |
| **Bylaws / lock** | The rule set, frozen at lock; the season starts at first tee; the endgame stays switchable. | "Legal word for settings" (NOV); "three lock moments" (ORG); "'locked at first tee' apparently means 'locked in a week'" (NOV, seeing the switchable finish). | One word for two moments and one non-freeze. |
| **Buddies / crew** | A mutual follow graph, "nothing to do with leagues or points." | "I already have a league of buddies; a second friends list is a second thing to maintain" (SKEP); door's "crew" ≠ buddies ≠ league (NOV). | D80's one noun landed; the door still says "crew." |
| **The board** | The league feed + chat where rounds land automatically. | Fine once seen (7/8). iOS: "the screen literally called 'the board' says the league is empty" while Home shows 18 items. Web: "'THE BOARD · ROUNDS LAND HERE AUTOMATICALLY' but neither of my posted rounds… appear" (CAS A16). | Concept fine; the promise "rounds land here" was false for pre-season rounds. |

### 5.4 "Explain it to a friend" — the comparison

**What everyone understood (8/8 or 7/8):**
- Post the real rounds you already play, from any course. (8/8)
- Each round is scored against *your own* handicap, so different handicaps compete evenly. (8/8; IOS: "You post your rounds with your handicap, and somehow that turns into points.")
- Five bands, 5 to 12 points; a bad day still scores; "the only way to hurt your team is not to play." (7/8)
- Best four a month; two a month or the squad loses points. (7/8)
- The app keeps the money on a tab; you pay each other. (7/8 — COMP said "a $50 buy-in that pays the winning squad"; IOS: "There's a pot, but ours is 'bragging rights'.")
- Live scorecard for skins / match play / Wolf, settled hole by hole. (6/8)

**What nobody understood (0/8 confident):**
- How the Cup Final decides the winner and what "scored fresh" does to the points already on the table.
- How ties break — anywhere (standings, seeds, Points King, skins).
- What the 95% handicap allowance does to a round, or that it is why two screens show different numbers.
- What "Attested" asks of a player at post time (and that it is what D13 calls "vouch").
- How, when, and to whom the buy-in is paid; how a squad's 60% becomes a person's payout.
- Whether a round posted this week counts (until inferred from zeros).
- What "the cup" is, in one sentence. (ORG: "'cup' = the season championship; the app also uses it as a count of leagues I'm in.")

**What testers interpreted differently (the same copy, opposite readings):**

| Copy | Reading A | Reading B |
|---|---|---|
| "-3.7 VS YOUR INDEX" | NOV: "I beat my index by 3.7 — why only 5 points?" | COMP: "+ means better (green); −4.5 means worse (red)." |
| "MONTH CLOSES in 2 days" | CAS: "I need 2 rounds in the next 2 days." SKEP: "Do I owe 2 rounds… before the season even starts?" | OBS: "what closes? what happens?" — no consequence imagined at all. |
| "LOCKED" | OBS: "my place in the standings can't change." | IOS: "both rows carry it, so it cannot distinguish us." (Intent: a guaranteed Cup Final seat.) |
| "— HELD" | OBS: "I held 1st place from last week." (Correct — `moved===0`, `index.html:10185`.) | IOS: "held what — position? a hold on me?" |
| "Lock the bylaws & form the squads" / "LOCKS AT FIRST TEE" | ORG: "settings freeze on the season's first day (Sep 5)." | JOIN/CAS/SKEP: "this button reads as somebody else's job… 'lock' sounds irreversible." |
| "GHIN rounds" (Standard preset) | ORG: "does Standard mean my buddies without a GHIN can't post?" | NOV: "does this mean players must ALSO post to GHIN? Does the app check?" (Intent: spec §8 index-source row; the app never checks.) |
| "Cup Final · scored fresh" | NOV: "the top squads start fresh and whoever's hottest wins the pot." | COMP: "the regular season is only for seeding (guess)." OBS: "the lead I've watched… may mean nothing." |
| "$150 Cup champs" | COMP: "'Cup champs $150' is what I win." | ORG: "champs get $210 for a squad of 3 or 4 — the app never says how a squad payout is divided." |
| "Post a stake" (Pot tab) | NOV (before): "side-game dollars go on the Pot ledger." | NOV (after): "'stakes' are NON-money bragging bets… skins/match/Wolf cash is shown once… and then gone." |
| "NEXT · Open · PLAN A ROUND" | NOV: "the next league round is open" (for twenty minutes). | NOV (after tapping): "'Next' means 'your next planned tee time', 'Open' means 'you haven't planned one'." |
| "One Pro-approved bye month" (wizard) vs "your season bye covers you automatically" (sheet) | NOV: "'Pro-approved' means I'll be adjudicating my friends' vacations." | ORG: "one forgiven floor miss per season — partly [understood]." |
| "COUNTS ON YOUR CARD" | NOV: "as a novice I read that as 'counted'." | SKEP: "I logged a round, got a badge for 'breaking 100', and nothing happened to the competition." |
| "The Pro" | NOV: "for a beat I thought the app was assigning me a pro." CAS: "a golf pro at a course." | ORG: "the organizer/commissioner (me) — partly [confusing]." |
| "beat it by 3" | SKEP: "net score three under my handicap-adjusted expectation." | COMP: "it is index minus differential (1.4 vs 6.4 = 5.0), a slope-adjusted number." |
| "Squads · LIVE NOW — CAPTAINS READY" | CAS (assumption): "squads are set." | ORG/JOIN/SKEP: both squads "Empty"; "there are no captains anywhere on this screen." |

**The one sentence every persona wrote in some form:** "The organizer will have to explain the rules to you, because the app doesn't." (IOS, verbatim; CAS "I'd need Casey to explain half of it in the parking lot"; NOV "I would still have to explain them verbally"; SKEP "the app just doesn't tell you any of that until you dig"; ORG "I would still have to explain them verbally, mostly to reconcile the contradictions.") Against the vision's own metric — "never need a tutorial" — that is the audit's verdict on rules comprehension.

---

## 6. Evidence index

| Finding | Reports | Screenshots (root `…/harness/shots/`) | Source |
|---|---|---|---|
| H1 pre-season rounds | ORG, NOV, JOIN, CAS, COMP, SKEP | `org/68,69,72` · `nov/36,71,72,78` · `join/46,47,51,52` · `cas/51,53,57` · `comp/35,38,40` · `skep/32,33,37` | `index.html:6341,10076,10105,11981,12225`; `baseline.sql:1372` |
| H2 allowance | OBS (collision), ORG, NOV, JOIN, COMP, SKEP | `obs/04,10,22` · `org/30,68,71` | `baseline.sql:1360`; `index.html:11500–11524,11912,16641`; `PostRoundScreen.swift:406`; spec §2.1, D2, D8, D48 |
| H3 endgame | all but IOS | `obs/08,21` · `nov/36` · `ios/03` · `org/23,28` | spec §14.3; `index.html:3293,3298,4478,12001,14799`; D4, D24, D26, D105 |
| H4 sign | ORG, NOV, JOIN, CAS, COMP, SKEP, OBS | `org/68,69,71` · `nov/71,77,79` · `join/46,48,53` · `cas/51,53,56` · `skep/21,36` · `obs/10,44` | spec §2.1; D1; `index.html:5710,6339,11519,11481,2884` |
| H5 rules depth / vocabulary | all 8 | `org/45,49` · `nov/38,40,42,43` · `skep/13,06,07` · `obs/21,22` · `join/30` | `index.html:3250,3318,17274`; D3, D13, D14, D82 |
| H6 money | all 8 | `join/11,29,55` · `org/22,54` · `nov/19,61` · `comp/25,60` · `cas/25,37` · `skep/12,49` · `obs/12` | spec §7; D39, D66, D70, D106; `index.html:15428` |
| Consent / roles | CAS, JOIN, COMP, SKEP | `cas/86,87` · `join/39,54,56` · `comp/19,22` · `skep/50,19` | D40, D96, D50, §6 |

*Every screenshot cited above was read for this synthesis; the rows marked in §3 as "code-confirmed" were verified against the files and line numbers given, not taken from the reports.*
