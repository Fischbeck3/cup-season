# Rules, Mental Model & Terminology — blind UX audit, Cup Season, 2026-08-29

**What this is.** The rules-comprehension, mental-model and vocabulary deliverable of the 2026-08-29 blind audit. Seven personas drove the real product cold (headless iPhone-viewport browser, real prod accounts, prod build `34d20b6` — byte-identical to this branch's `index.html`, so every client defect here is live at cupseason.app), plus one screenshot-only survey of the native iPhone app. Synthesis agents then read everything with the spec open; the five top findings were adversarially validated by fifteen independent agents (15/15 "Confirmed UX problem", 0 refuted — `raw/synthesis-and-validation-results.json`).

**Evidence discipline.** Every claim carries one of four tags, kept separate: **OBSERVATION** (what a tester saw — report · screenshot · "exact UI copy" · `index.html` line where known) · **INTERPRETATION** (this audit's reading of why) · **IMPACT** (what it costs the product) · **RECOMMENDATION**. Product intent is cited to `spec/spec-v1.0.md` (§), `spec/product-vision-v1.0.md`, `spec/decision-log.md` (D-numbers) and code. Where the spec explains a rule and the UI did not, the gap *is* the finding — nothing is softened because a document elsewhere is right.

**Confidence /10** is a tester-evidence score: how many of the eight could discover the rule unaided, understand it, predict its consequence, and say it correctly in their 30-second explanation. Anything below 8 is flagged (⚑). Column values: **Y** yes · **P** partial · **N** no · **—** not exercised.

**Report shorthand.** ORG = `raw/agent5-organizer.md` (Casey, organizer) · NOV = `raw/agent3-league-novice.md` (Dana, first-time organizer) · JOIN = `raw/agent6-new-joiner.md` (Marcus, invitee) · CAS = `raw/agent1-casual.md` (Jordan, no handicap) · COMP = `raw/agent2-competitive.md` (Priya, 6.4) · SKEP = `raw/agent4-skeptic.md` (Sam) · OBS = `raw/agent7-retention-observer.md` (mid-season, read-only on the owner's real account — 0 rounds, 0 posts written, DB-verified) · IOS = `raw/ios-screen-survey.md` (static screens, no taps). Screenshots are cited as `<session>/<file>.png` as the testers named them; the frames live in this folder as `screenshots/{org,nov,join,cas,comp,skep,obs,ios}/<file>.jpg` (validator frames `screenshots/v-TOP-*/` stay `.png`; git-ignored). Structured results (12 runs, 424 raw issues) in `raw/persona-results.json`; the deduped master set (135 issues from 425 raw items) in `issues.json`.

**Method limits, stated honestly.** No in-season play could be observed (both audit leagues defaulted their first tee to Sat Sep 5, a week out); no finished season existed (Journeys F/G are judged on what a live season says about its ending); the owner's two real leagues have two players each; the headless browser has no share sheet or clipboard (share outcomes judged on visible feedback only); the iOS survey saw static landing screens only; the first joiner attempt's "code never arrived" was a test-harness mail artifact (Supabase recorded the send) and only that run's door/Terms observations are used here. Rules-comprehension scores are therefore a *floor* for the pre-season and a best-available read for mid-season; nothing about the endgame was observable except its absence from every pre-window surface.

**Orchestrator-verified facts this document relies on** (confirmed, not persona claims): (1) prod = `34d20b6`; (2) both organizers' leagues defaulted the first tee to Sat Sep 5, every joiner's pre-season round showed "LEAGUE POINTS THIS ROUND N" on the form and 0 in standings, and nothing states pre-season rounds don't count while Home shows "MONTH CLOSES in 2 days"; (3) `lockBylaws()` throws on `staged.length` (`index.html:15218`) *after* the seasons insert, `form_squads` and the phase update commit, so the Pro sees "Lock failed" while the league is live — relevant here because it is why both organizers met the rules in the "locked-but-failed" state.

**Headline numbers.** rulesClear mean **4.0/10** across the 8 personas, each family's latest run (ORG 5 · NOV 5 · JOIN 5 · CAS 3 · COMP 4 · SKEP 4 · OBS 3 · IOS 3; median 4 — the same median `blind-ux-audit.md` §1 reports across all 12 result rows); conceptClear mean **5.1**; 46 rules scored, **1 at ≥ 8** (best-four counting), **45 flagged**, 12 of them at 1–2; ~120 product-specific terms met, most undefined at first contact; six of eight 30-second explanations end on "I can't tell you how the winner is decided" or "I'm not sure my round counted".

---

# Part 1 — Rules

## 1.0 The six rules that broke the model

| # | Finding | Who hit it | Conf. |
|---|---|---|---|
| H1 | **Rounds before the first tee earn nothing for the league, and every surface but one says otherwise.** Form: "LEAGUE POINTS THIS ROUND 5 / 6 / 12". Result card: "COUNTS ON YOUR CARD". Standings: 0. Home hero: "The season's on. Rounds count from today." Clubhouse: "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON". Six of six posters inferred the rule from zeros. | ORG NOV JOIN CAS COMP SKEP | ⚑ 1 |
| H2 | **The 95% allowance is real, applied server-side, and invisible.** It appears once, as a bylaw row. The web preview scores at 100%; the league at 95%; where they collide ("Beat your number by 3.3" on Home vs "+2.6 vs index · 9 PTS" on the receipt, same round) it reads as a bug. iOS confesses ("A preview at 100% of your number"); the web says nothing. | OBS (collision) ORG NOV JOIN COMP SKEP | ⚑ 2 |
| H3 | **The endgame is one bylaw row.** "CUP FINAL · Final 4 weeks · scored fresh" — four taps deep behind a collapsed disclosure — is the whole explanation of how the season is won. Seven of eight: "I honestly can't tell you how the winner is decided." The §14.3 ladder is in `close_season` and nowhere a user can see. | all but IOS | ⚑ 2 |
| H4 | **The sign of "vs your index" inverts golf intuition, by design.** §2.1: positive = beat your number; the client prints `-3.7` in red for a bad round. Every golfer tester read minus as good at least once. D1 said *words*; the posted card obeys, the form, receipt, standings and You tab still print bare signed numbers. One round was described three ways in four minutes. | ORG NOV JOIN CAS COMP SKEP OBS | ⚑ 3 |
| H5 | **The rules exist, in excellent prose, four taps deep and in three vocabularies.** "How scoring works" is reachable via League tab → collapsed "LEAGUE RULES & PRO SHOP" → link, or the bottom of You. Verification is "GHIN rounds" / "Attested" / "auto-attested" on three screens; D13 said the only user-facing word would be "Vouch" (0 hits in `index.html`; "attested" ×15). | all 8 | ⚑ 4 |
| H6 | **The money model was understood by everyone; the payment path by no one.** 8/8: "the app keeps the ledger, money moves between friends." 0/8 could say how, when or to whom they pay. The organizer path defaults a hidden $75/player behind "Customize". "Membership lands at launch" appears twice with no price. | all 8 | ⚑ 5 |

**INTERPRETATION of the pattern.** Testers reconstructed spec §1's pipeline stages 1–3 (**POST → SCORE → COUNT**) almost verbatim, unaided. Stages 4–5 (**RANK → CROWN**) are blank in every explanation. The model is not wrong; it is *truncated* — a season with a head and no tail, and no sentence anywhere saying why today's round matters (D51's stake line is decided and unbuilt).

## 1.1 The rules table

Columns: **Rule** (as the product means it, with where the UI states it) · **Disc.** can the user discover it unaided · **Und.** can they understand it · **Pred.** can they predict its outcome · **Expl.** can they explain it to a friend · **Reinf.** does the UI reinforce it at the right moment · **Conf. /10** · **Evidence**.

### A. Scoring bands, index, allowance, differential

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R1 | **Five bands vs your own number: 12 / 9 / 7 / 6 / 5** (§2.2). Stated on the post form "POINT BANDS", "How scoring works", the welcome sheet. | Y | Y | Y | Y | P | ⚑ 7 | 7/8 gave the numbers verbatim (IOS: "somehow that turns into points"). Points appear on the form but never on the posted card or the pre-season web receipt (ORG `org/71-round-detail.jpg`, NOV `nov/77-round-detail.jpg`, CAS `cas/56-G04-round-receipt.jpg`). Three label sets for one band (NOV N-37: "Rough day, posted anyway" / "Posted anyway · rough day" / "POSTED ANYWAY"). Band edges overlap in copy ("by 3+" and "by 1–3" both contain 3 — SKEP SK-05); the spec's own edges are half-open (§2.2). |
| R2 | **"Beat it by X" is measured in differential vs index (slope-adjusted), not strokes.** Stated only in the receipt arithmetic. | P | P | N | P | N | ⚑ 4 | COMP reverse-engineered it: "74 at 72.4/133 → 1.4 differential → +5.0 … a normal golfer would assume strokes." SKEP assumed "net score three under my handicap-adjusted expectation." CAS: "some course-adjusted score with 113 in it. Formula shown, meaning not." |
| R3 | **Sign convention: + = beat your number, − = worse** (§2.1; D1 says display as words). Bare signed numbers at `index.html:6339` (form), `:11519` (receipt), standings "Avg vs index", You "Best vs index". | Y | N | N | N | N | ⚑ 3 | NOV `nov/71-pre-post2.jpg` "-3.7 VS YOUR INDEX": "USER ASSUMPTION on first read: 'I beat my index by 3.7 — why only 5 points?'" ORG `org/68-round-filled.jpg` "-1.7 VS YOUR INDEX" under "A little loose". CAS, one round, three verdicts: "-9.8 vs your index" → "9.8 over your number" → "+0.0 — PLAYED TO IT". SKEP: "'Best vs index -4.5 · Career best' … how is that 4.5 UNDER my index?" OBS: "the opposite of golf's minus-is-good." Only COMP read + as good, and only after seeing green. |
| R4 | **Every round's points are visible after the fact** (§16 receipts). The receipt's `Points` row (`index.html:11522`, keyed on `month_rank`) renders only for in-season rounds. | P | P | — | — | N | ⚑ 5 | In-season: OBS `obs/10-my-row.jpg` "+2.6 vs index · 9 PTS". Pre-season: no points line anywhere — exactly the testers who most needed "did this count?" saw nothing (ORG, COMP: "no points number on the receipt and no 'counts for The Papago Grind: no'"). |
| R5 | **Your index builds from scores (WHS-lite), establishes at 3 rounds; a typed index is a starter the engine overtakes.** Golfer card help; scoring sheet; Card & settings. | Y | P | P | P | P | ⚑ 6 | Understood by ORG/NOV/COMP/SKEP, with alarm — COMP: "having [a real GHIN 6.4] replaced by a 3-round WHS-lite number is alarming… which number does the league use?" Two truths one screen apart: Home "INDEX 0 OF 3 · building" vs Members "INDEX 14.2" (ORG ORG-16, `org/14`, `org/50`; NOV N-17). GHIN copy "that's identity, not your number" — NOV "read it three times", still cryptic. |
| R6 | **Playing index = index × allowance (Standard 95%)**, applied by `v_rounds_ranked` (baseline `:1360`). Stated only as the bylaw row "HANDICAP ALLOWANCE 95%" (`index.html:12090`) and the preset card "95% hcp" (`:3250`). | P | N | N | N | N | ⚑ 2 | ORG: "the panel gives no hint whether -1.7 is against 14.2 or 13.5. I cannot reproduce the number by hand." COMP: "The 95% allowance never shows up in any calculation I saw (preview, receipt, live strokes)." NOV: "Does an 18.2 play as 17.3?" OBS found the collision without knowing it: Home "Beat your number by 3.3" vs receipt "+2.6 vs index · 9 PTS" for the Aug 16 round — "by this table 3.3 would be 12 pts" (`obs/10-my-row.jpg`). D2/D8/D48 said never show the allowance; it is shown *and* unexplained. |
| R7 | **With no index yet you are scored off the starter, badged provisional** (D49). Stated nowhere. `grep -i provisional index.html` = 0 hits. | N | N | N | N | N | ⚑ 2 | CAS (no index, 2 rounds), receipt: "27.8 DIFFERENTIAL · YOUR NUMBER THAT DAY 27.8 · Against your number +0.0 — PLAYED TO IT" — "circular for a new golfer; 'played to it' is guaranteed" (`cas/56-G04-round-receipt.jpg`). The 103 posted to his card by someone else's live game repeated it: "28.0 / 28.0 / +0.0". |
| R8 | **Live games estimate a missing index at 18.** Live setup: "Leave index blank for an estimated 18." | Y | Y | P | P | N | ⚑ 5 | Stated for guests; CAS was silently shown as "Jordan · EST 18.0 IDX" — "a $5 match decided by a silent default" (CAS A21). |

### B. What counts: cap, pre-season, lens model, eligibility

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R9 | **Best 4 rounds a month count for your squad; a better round bumps your worst counter in real time** (§3.1). Form footer; scoring sheet; bylaws "COUNTING CAP"; standings "COUNTING ROUNDS 1/4"; receipt "BUMPED". | Y | Y | Y | Y | Y | **8** | The best-taught rule in the product: 7/8 said it verbatim. OBS: "Bumped — explained inline, fine." Residual: COMP "nothing says whether the individual Pts column is capped too"; the bylaws label "COUNTING CAP" (`:12092`) is the phrase D51 said never to print. |
| R10 | **Rounds played before `starts_on` are not in the season; they build your index only** (`v_rounds_ranked` joins `seasons` on `played_on between starts_on and ends_on`, baseline `:1372`). Stated once: Clubhouse kickoff card "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:12225`). | N | N | N | N | N | ⚑ 1 | Contradicted by the form's live preview (`recalc`, `:6341`, no date check — "LEAGUE POINTS THIS ROUND 6" ORG `org/68`; "12 · You torched your number by 5.0. Sandbagger alert." COMP `comp/35-preview-74.jpg`), the Home hero "The season's on. *Rounds count from today.*" (`:10105`, rendered whenever `state.phase==='season'`, `:10076` — i.e. from lock, before first tee), the form's own "No league yet? The round still counts on your card — points apply in any league you join." (`:3198`, unconditional), the live finish "Finish round & post to season". Standings 0 for all six: `nov/78`, `join/51-AD`, `cas/57-H01`, `comp/40`, `skep/37`, `org/72`. CAS: "the first thing the app promised me (5 points) didn't happen and I had to infer why." The ceremony code knows (`:6588` "COUNTS THIS SEASON" vs "COUNTS ON YOUR CARD") and never says so. **Orchestrator-verified: both leagues, all joiners.** |
| R11 | **Rounds belong to your profile ("your card"); every league you're in reads them** (leagues are lenses). ⊕ door: "counts on your card and in every league". | P | N | N | N | N | ⚑ 4 | Never grasped. NOV: "'COUNTS ON YOUR CARD' — as a novice I read that as 'counted'." SKEP SK-34: "'Card' means five different things." CAS: "'counts on your card' = profile/record — but also the scorecard ('Scan the card')." |
| R12 | **Nine-hole rounds post at half value, half a round** (D72). Form help; receipt "HALF VALUE · HALF A ROUND". | Y | Y | Y | — | Y | ⚑ 7 | Stated where met; only OBS saw one ("2026-07-24 · 9 HOLES · BUMPED · 3 PTS"). Untested by anyone else — flagged for coverage, not for copy. |
| R13 | **Round eligibility under the preset** (Standard: any rated course, sim ok; Cutthroat: rated tees, no 9-hole — §2.4/§8). Preset cards: "any course" / "GHIN rounds" / "rated tees". | P | N | N | N | N | ⚑ 2 | ORG: "'GHIN rounds' — does Standard mean my buddies without a GHIN can't post?" NOV: "does this mean players must ALSO post to GHIN? Does the app check?" (It does not — GHIN is an optional reference field.) SKEP: "Nothing about… which tees are allowed, or whether a round with non-members counts." The post form enforces and mentions nothing. |

### C. Floors, byes, months, weeks

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R14 | **Participation floor 2/month; −5 squad points per round short** (§3.2). Home fine print; wizard (i) `:3318`; bylaws; scoring sheet; welcome sheet. | Y | Y | P | Y | P | ⚑ 7 | 7/8 explained it. Flagged for three phrasings (JOIN J-08 quotes all three) and for firing where it cannot apply: a league-less Home (ORG `org/14`, NOV `nov/10`), a solo league ("−5 sqd pts" under "Individual — no squads", OBS `obs/21-bylaws-open.jpg`), and a week before the season ("MONTH CLOSES in 2 days" + floor warning — CAS A9, SKEP SK-12). |
| R15 | **The season bye auto-covers the first floor miss** (D14). Scoring sheet only: "Miss it once and your season bye covers you automatically… the floor bites from the second miss." | P | P | P | P | N | ⚑ 4 | The wizard (i) still prints the pre-D14 rule: "One **Pro-approved** bye month per season" (`:3318`). NOV: "'Pro-approved' means I'll be adjudicating my friends' vacations." ORG: "'bye' is a new mechanic that appears only here." |
| R16 | **Floors are waived in partial edge months** (§14.0). Home "Short months are waived."; iOS "Partial month · floors waived". | P | N | N | N | P | ⚑ 4 | SKEP: "'short month' is undefined (a month with fewer days? a partial month?)". ORG glossary: "Short months — ? partial calendar months where the floor is waived — yes [confusing]". IOS: "what floors are and why they're waived." |
| R17 | **The month closes on the 1st: penalties assessed into the ledger, snapshot, board post** (§14.2). Home pill "MONTH CLOSES in 2 days"; board "July closed — Ledger posted". | Y | N | N | N | N | ⚑ 3 | OBS: "'month closes' (what closes? what happens?)". CAS: "USER ASSUMPTION: 'Month closes in 2 days' means I need 2 rounds in the next 2 days." SKEP: "Do I owe 2 rounds in the 2 remaining days of August, before the season even starts?" COMP: "the August 'month' is apparently irrelevant." |
| R18 | **There is no weekly obligation**: weeks are Sunday snapshots, the Cup Final unit, and (migration `20260829091000`, built the day of the audit) the weekly clash (D52/D108). Calendar dots "Week closes — snapshot recorded"; standings "Δ WK". | N | N | N | N | N | ⚑ 2 | NOV's own rules table: "Miss a week — Nowhere — 'week' only exists as a Sunday snapshot — 2/10"; "week/month/season are three clocks, never explained together"; "the season starts Saturday, weeks close Sunday — so week 1 is one day long?" IOS: Home "WEEK 4 OF 14" vs Clubhouse "WK 4 / 13". OBS: "'Δ WK +10' though my last round was two weeks earlier." No tester saw a clash. |

### D. Season shape, lock, squads, draw, captains

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R19 | **A season is N whole weeks from a first-tee weekday** (§14.0 v1.1). Wizard "Season length"; Clubhouse "Sat Sep 5 → Sat Jan 2 · 17 wks". | Y | Y | Y | Y | Y | ⚑ 7 | Clear once inside (NOV 9/10). Flagged because a joiner cannot see it before committing (JOIN: "No start date, no end date, no length before commit"), iOS shows two week counts, and the You tab hardcodes "FIRST TEE SUN" for a Saturday start (`:16863` — NOV). |
| R20 | **Lock = the Pro freezes the bylaws, the draw runs, invites open (D40); the season starts at first tee; the endgame dial stays switchable.** "LOCKS AT FIRST TEE" · "Lock the bylaws & form the squads" · "locked at first tee". | Y | N | N | N | N | ⚑ 3 | ORG ORG-08: "Three different lock moments in one screen." NOV: "'locked at first tee' apparently means 'locked in a week'" (the "locked" bylaws still offer "Finish: Cup Final — switch to points table"). "Lock opens the invite link" is false — the code chip exists pre-lock (`org/37-league-room-forming.jpg`). Members (JOIN, CAS, COMP, SKEP) were handed the Pro's lock button on their own Home. |
| R21 | **Minimum four golfers to tee off** (D58). Wizard step-3 footer only. | N | Y | N | P | N | ⚑ 4 | NOV N-06: "revealed on the LAST step. I have three people total" — then "SEASON LIVE" with one golfer. ORG ORG-20: "'3 SEATS OPEN' reads as a capacity of 4 for a league meant for 7." |
| R22 | **Squads are teams (2 by default) drawn blind at lock; squad month = Σ members' counting points − penalties** (§3.3). Defined only in the wizard's Customize (i). | N | P | N | P | N | ⚑ 4 | NOV: "THIS is the first definition of 'squad' (= team), and it is behind an (i) on an optional Customize panel." SKEP: "Team structure never introduced until the collapsed bylaws on tab six." CAS: "USER ASSUMPTION: 'squad' = the whole league." JOIN: "I don't know my team or my opponents." ORG: "Nothing says how uneven squads (3 v 4) are scored." |
| R23 | **Captains are an optional label** (§15; the captain playoff is gone, D105). Standings "CAPT. —"; League tab "LIVE NOW — CAPTAINS READY" (`:12231`, phase `draft`). | N | N | N | N | N | ⚑ 2 | NOV: "squads have captains? Who picks them?" ORG: "There are no captains anywhere on this screen." A role that does not exist in the product, printed on two surfaces. |
| R45 | **Blind draw (server-side, balanced, at lock) or Pro assign** (§15, D54, D58). Wizard "How teams fill"; form-squads "THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW". | Y | Y | P | P | N | ⚑ 5 | Organizers understood the dial. Members saw the *tool*, not the result — "SQUADS ARE FORMING · The Pro has the list" / "LIVE NOW — CAPTAINS READY" / both squads "Empty" (JOIN J-09, CAS A12, SKEP SK-15); "See the squads" opens the Pro's draw tool with tappable chips and no back control (COMP, SKEP SK-18). "Draw failed. Something went wrong" hid the server's "Not enough golfers… Share the invite link first." (ORG, NOV). |

### E. The endgame

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R24 | **Cup Final = the final four weeks, scored fresh under the counting rules; seeds lock at `ends_on − 27`; 2-squad: both in, leader +10; solo: top 2** (§14.0/§14.3). Bylaws row "CUP FINAL · Final 4 weeks · from Sun Dec 6 · scored fresh"; wizard (i) "top seeds race fresh"; teams copy "+10 head start" (`:12001`); covenant "FINISH · Cup Final · final 4 weeks". | P | N | N | N | N | ⚑ 2 | COMP: "'Scored fresh' is never defined. Who plays the Cup Final? Both squads? Do the first 13 weeks matter at all?" OBS: "Home says 'You lead by 22 points.' Nowhere does it say that lead is (apparently) a seed." NOV: "What is a seed? Top how many? What happens to non-seeds?" ORG: "'+10 head start' — 10 of what?" CAS: "'scored fresh' whatever that means." "scored fresh" appears on six lines of `index.html` and is defined on none. The +10 exists only in organizer copy. OBS rated rulesClear 3 on this alone. |
| R25 | **The alternative endgame: the points table crowns the leader** (dial 008). Wizard (i); "Leagues vs events" explainer. | P | Y | Y | P | — | ⚑ 5 | Only organizers saw the dial; ORG understood it. Members never learn which endgame their league runs except via the bylaws row. |
| R26 | **Tiebreak ladder: h2h months won → best single month → fewest rounds used → logged coin flip** (§14.3; stored as `tiebreak_rung`). Stated nowhere. | N | N | N | N | N | ⚑ 1 | COMP: "Ties — Nothing. Not in bylaws, scoring sheet, standings footnote, or the welcome sheet — 1." OBS: "how a tie breaks: nowhere." The only tie sentence in the client is the Major's countback (`:12706`, `:16296`); the season ladder appears only as the stored rung (`:11706`). |
| R27 | **Clinch vocabulary: LOCKED / cup seed / TOP SEED · +10 / EVERYONE ADVANCES — n CONTENDERS, K SEATS / PROJECTED UNDER A GENEROUS CEILING** (D24 honesty rule, D26 the Climb; `:4478–4480`). | Y | N | N | N | N | ⚑ 2 | NOV `nov/36-clubhouse-full.jpg` "TOP SEED · +10 … TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING" over two empty squads: "I do not know what any of these mean. Why does Squad 1 have +10 with zero rounds?" IOS `ios/03-clubhouse.jpg`: "LOCKED… both rows carry it, so it cannot distinguish us"; "advance to what? seats where?" OBS: "what 'LOCKED' locks (a 'cup seed' — what is a cup seed?)". |
| R28 | **The individual layer runs in parallel: Points King (15% of pot), Most Improved, Iron Man** (§4). Standings footnote "…All three run in parallel with the squad race — bylaws §4." | Y | P | P | P | P | ⚑ 6 | Understood from the footnote; "bylaws §4" cites a document nobody is served (ORG, NOV, JOIN, SKEP). JOIN: "only Points King's 15% is stated." OBS: "'squad race' in an Individual — no squads league." |
| R29 | **A season ends in a ceremony: champion, margin, deciding rung, per-person payout, trophies** (D66, §14.4). "the endgame settles it"; You: "No silverware yet". | N | N | N | N | N | ⚑ 3 | OBS Journey F: "'the database reached its final row.' There is no countdown to Dec 22, no 'final starts in N weeks', no bracket/seed graphic, no tiebreak text, no preview of the settlement card." (No finished season existed; judged on what a live season says about its ending.) |

### F. Money and pot

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R30 | **Buy-in per player; pot = stake × roster; the app keeps the ledger; money moves friend-to-friend; the Pro marks who paid** (§7, D39, D106). Covenant; welcome sheet; Pot tab; scoring sheet; legal page. | Y | Y | P | Y | P | ⚑ 6 | 8/8 explained the ledger. 0/8 could say how to pay — JOIN: "who do I pay, how, by when — none of it"; CAS: "pay Casey cash/Venmo and hope he ticks the box." Organizer default "$75 (DEFAULT) … hidden behind 'Customize'" (NOV N-02 `nov/19-wizard-customize-full.jpg`, ORG ORG-04). Disclosed to invitees only *after* account creation (SKEP SK-03: "a skeptic reads this as a bait-and-switch"). ORG found the clearest statement of the money posture in the legal page's Prize Pool Disclaimer, "which tells me more about what the product is than the door does." |
| R31 | **Pot split 60/25/15 champ / runner-up / Points King; squad shares resolve to people at the ceremony** (D66). Wizard (i); bylaws; Pot "$150 Cup champs · $63 Runner-up · $38 Points king". | Y | P | N | P | N | ⚑ 5 | ORG: "$30 + $13 + $8 = $51 on a $50 pot… the app never says how a squad payout is divided among its members." COMP: "USER ASSUMPTION: 'Cup champs $150' is what I win. ACTUAL: unknown"; "$251 on $250". SKEP: "'Cup champs' (plural) first hint of a team prize." |
| R32 | **The pot has two numbers: owed and collected** (D106). Pot "$250 · 5 × $50 · $0 collected · 5 still owe". | Y | P | N | — | N | ⚑ 5 | OBS: "'0/2 in' and '2 still owe' sit directly above two names with ✓ marks. I read the ✓ as 'paid'." Six weeks in, $0 collected, no reminder path (OBS #32). |
| R33 | **Pricing: a league pass paid to Cup Season; the pilot free** (D56/D101). "Pro Shop · CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE"; Settings "PLAN FREE · PILOT". | Y | N | N | N | N | ⚑ 3 | ORG: "I cannot tell whether we will be charged mid-season, who pays (me? each player?), or how much." CAS A32: "I don't know if I'll be asked to pay the app on top of the pot." SKEP: "no price, no scope." |
| R34 | **Side-game money settles between players and never reaches the pot ledger; "stakes" on the Pot tab are pride, never money** (§13.2, D64). Live: "SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN YOU"; Pot: "Pride, on the books — never money". | P | N | N | N | N | ⚑ 3 | NOV: "USER ASSUMPTION (before): side-game dollars go on the Pot ledger. ACTUAL: … the app that 'keeps the books' doesn't keep these." COMP: "the $60 lives only as a board card" (`comp/60-pot-after-skins.jpg`). ORG ORG-24: "four money nouns (buy-in, pot, stake per side, stake) with different rules each." |

### G. Side games, verification, consent

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R35 | **A live round posts every complete member card to the season (attested); the game result never touches cup points** (§13.2). Live paragraph "Only league members' rounds post to the season."; finish "ONE FINISH — EVERY MEMBER'S CARD POSTS". | Y | P | P | P | N | ⚑ 6 | ORG and COMP got it (sideGames 8/10 each). CAS A36: "Nothing in one place states that side games don't affect season points while the gross score does." NOV: "the ROUND still feeds the league… the GAME result is separate." (Also wrong pre-season, per R10.) |
| R36 | **Verification: Standard = Attested; a group scoring together vouches by construction; unattested rounds still score** (§6). D13: the only user-facing word is "Vouch". Preset "GHIN rounds"; review "VERIFICATION Attested"; live "auto-attested"; receipt "Attested · PLAYED WITH THE GROUP". | P | N | N | N | N | ⚑ 3 | ORG ORG-07: "Verification shown as 'Attested' though Standard preset said 'GHIN rounds'; 'attested' is only explained on the live scoring screen." SKEP: "attested by whom? the form asks nobody… nobody attested my 91." COMP: "one phone can post + attest four cards (I did)." `index.html`: "vouch" ×0, "attested" ×15. |
| R37 | **Anyone who seats you in a live round can post an attested score to your card.** Stated nowhere, to the person it happens to. | N | N | N | N | N | ⚑ 2 | CAS A7: "'You · Played to your number · 103 gross' appeared on my card from another member's skins game… no notification, no confirmation; my index count moved. Someone else can put a 103 on my record." |
| R38 | **Game rules: match play (net best ball off the low man), Wolf, Skins (carry), Sunningdale.** One-line blurbs after selecting each. | Y | P | P | P | P | ⚑ 4 | Skins and match play understood; "Wolf is never explained" (NOV — a fuller blurb exists at `:8846` once four are seated, which COMP saw); Sunningdale "no idea, no (i)" (ORG); "net best ball", "SI", "strokes off the low man", "riding", "bank a unit" undefined (CAS, NOV, OBS). COMP praised the strokes sentence: "the sentence golfers argue about on the first tee, written for you." |
| R46 | **Events (The Ryder, a Major) are short competitions with their own trophy, standalone or attached to a league; the Ryder = two teams, weekly one-on-one vs-index matchups, first to a majority** (gameplay-modes §4; D42–D46). Home "Start an event"; tiles "Two teams · weekly vs-index duels · first to the clinch". | P | N | N | N | N | ⚑ 3 | Nobody opened one. CAS A33: "jargon; no relation to my league explained." IOS: "team event judged vs handicap; first to win enough — 'vs-index', 'clinch' undefined." OBS saw a "Major" as a quoted note on a Sep 4 plan beside "you lead 1–0" — "head-to-head vs Galen in what?" The long-game/short-game split on the orientation card *did* land (NOV, ORG). |

### H. Joining, roles, leaving, correcting

| # | Rule | Disc. | Und. | Pred. | Expl. | Reinf. | Conf. | Evidence |
|---|---|---|---|---|---|---|---|---|
| R39 | **Joining by code/link puts you on the pot sheet; the covenant shows buy-in, preset, floor, finish** (`covenantGate`, `:15422–15440`). `join/11-J-after-take-me-in.jpg`: "BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks". | Y | P | N | P | P | ⚑ 4 | JOIN (3/10): "I did not know who was in it (not even that Casey ran it), when it started or ended, how a round scored, or how money moved… The consent sheet is the right idea with the wrong contents." Landing copy "Enter your email and you're in" contradicts the four-step flow (J-05). "Not now" drops the invite (J-06). |
| R40 | **Mid-season joins until halfway (floor prorates; late joiners → thinnest squad); dropouts → squad plays short; cancellation with consent** (§9, §15, D71). Nothing a member sees. | N | N | N | N | N | ⚑ 1 | No tester found any copy on leaving, dropping out, or joining late. "Cancel & delete this league (only possible before the first tee)" is the only lifecycle control — "more prominent than the invite" (NOV). |
| R41 | **Roles: only the Pro locks, draws, marks buy-ins, grants byes, rules on disputes.** "PRO — THAT'S YOU"; Settings "Your leagues · PLAYER". | N | N | N | N | N | ⚑ 3 | Every member tester was handed the Pro's tools: "Lock it in and invite your crew" hero → the wizard with a live lock button (JOIN J-02 `join/39-U-lock-it-in.jpg`, CAS A2, COMP, SKEP `skep/50-lock-page.jpg`); the Cancel offered to delete the friend's league (server refused: "Could not discard. commissioner only"); Pot rows look tickable (CAS A15). NOV: "Nobody told me that would be my job." Root cause validated: `renderHomeHero`'s forming branch (`:10072–10116`, CTA at `:10102`) has no role check; D40's backstop guards `enterLeague` only. |
| R42 | **Rounds are immutable (§16); a wrong round is deleted (`delete_round()`) and re-posted; there is no edit.** Unlabeled ✕ on You › Recent rounds; native `confirm()`. | N | P | P | N | N | ⚑ 3 | NOV N-12: "no edit/delete path visible from the round receipt or posted card." ORG: "a wrong score means delete and re-post; a wrong date or course, same. Nothing tells you that." CAS: "hard to find when you need it, easy to hit by accident once found." |
| R43 | **Disputes: the Pro rules; every ruling is a logged, visible ledger entry; settled events never change** (D50 — logged as copy-only, not built). Nowhere. | N | N | N | N | N | ⚑ 1 | No tester found a dispute path. CAS on the 103: "no obvious way to dispute except the ✕ on the You tab." |
| R44 | **Deleting a round removes what it earned.** The confirm text only. | — | P | N | — | N | ⚑ 4 | COMP: "Display-case badges 'Broke 100 / Broke 90 / Broke 80 · 74 gross' SURVIVED the deletion with Lifetime 'Rounds posted 0'." ORG: "'Cups & events 1 · Played in' persists" (for a league that hasn't started). |

**Tally.** 46 rules. **1 at 8** (R9). **45 flagged below 8**, of which 12 sit at 1–2: R10, R26, R40, R43 at **1**; R6, R7, R13, R18, R23, R24, R27, R37 at **2** (R46 events at 3 is untested rather than misread).

## 1.2 Every flagged rule, in one line each

| Conf. | Rules | Why flagged |
|---|---|---|
| 1 | R10 pre-season · R26 ties · R40 late join/dropout · R43 disputes | Stated nowhere a member looks (R10: stated once and contradicted four times) |
| 2 | R6 allowance · R7 provisional · R13 eligibility · R18 weeks · R23 captains · R24 Cup Final · R27 clinch words · R37 consent | Engine vocabulary printed without definitions, or the rule acts invisibly |
| 3 | R3 sign · R17 month close · R20 lock · R29 ceremony · R33 pricing · R34 side money · R36 verification · R41 roles · R42 correction · R46 events | Defined in one register, met in another; or the consequence is never named |
| 4 | R2 differential · R11 lens · R15 bye · R16 short months · R21 minimum four · R22 squads · R38 game rules · R39 covenant · R44 deletion | Defined behind an (i), a disclosure, or on the last step |
| 5 | R4 points visibility · R8 est. 18 · R25 points table · R31 split · R32 owed/collected · R45 draw | Concept lands; the number or the outcome does not |
| 6 | R5 index building · R28 individual layer · R30 ledger · R35 live posts | Understood by most; one hole each (which index / "bylaws §4" / how to pay / pre-season) |
| 7 | R1 bands · R12 nine holes · R14 floor · R19 season shape | Well taught; wobbling labels, misplaced timing, or joiner can't see it before commit |

## 1.3 The major rule findings — OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION

### F1. Pre-season rounds (R10) — the one rule every poster hit

**OBSERVATION.** Six testers posted a round on Aug 29 into a league whose first tee is Sep 5. In every case the post form's live panel promised league points — ORG `org/68-round-filled.jpg` "LEAGUE POINTS THIS ROUND **6**"; COMP `comp/35-preview-74.jpg` "**12** · You torched your number by 5.0. Sandbagger alert."; NOV/JOIN/CAS/SKEP "5". The result sheet said "COUNTS ON YOUR CARD" and nothing about points. Standings stayed "0 R · 0 Pts" (`nov/78-standings-after.jpg`, `join/51-AD-standings-after.jpg`, `cas/57-H01`, `comp/40`, `skep/37`); JOIN's own row read "No rounds this season yet — post one and you're on the board" *right after posting* (`join/52-AE-marcus-row.jpg`). The You tab said "THIS SEASON · Rounds posted 0" beside "LIFETIME · Rounds posted 1". The only sentence stating the rule is the Clubhouse kickoff card "KICKS OFF IN 7 DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:12225`, `nov/36-clubhouse-full.jpg`). NOV's Home simultaneously read "DESERT DOGS · SEASON LIVE — The season's on. Rounds count from today." (`nov/34-reload-home.jpg` vs `nov/35-clubhouse-1.jpg`). SKEP's verbatim: "I logged a round, got a badge for 'breaking 100', and nothing happened to the competition."

**INTERPRETATION.** `v_rounds_ranked` joins a round into a season only when `played_on between starts_on and ends_on` (baseline `:1372`) — correct, and the Clubhouse copy is right. But (a) `recalc()` (`:6306–6341`) computes `pts = pointsFor(vs)` with no season-window check; (b) the hero's `starter = state.phase==='season'` (`:10076`) fires from lock, before first tee — precisely where `atStarter()` (`:11981`) makes the Clubhouse say the opposite; (c) the form's "No league yet? The round still counts on your card" (`:3198`) is unconditional; (d) the ceremony knows the answer (`:6588`, "COUNTS THIS SEASON" vs "COUNTS ON YOUR CARD") and phrases it so that "counts on your card" reads as "counted". Validation added that the mechanic "a round scores for a league only inside its window, at its allowance" has **no spec §14 sentence and no decision-log entry** (rule 5) — so no canonical phrase exists for Home, Clubhouse, form, card and receipt to share.

**IMPACT.** The first promise the product makes is broken silently, on the core loop, for 100% of pre-season posters. Two testers believed the post had failed; every 30-second explanation carries the scar (CAS "I'm not sure my rounds this week even count"; JOIN "nothing on the screen said that"; NOV "one screen says the season started today and another says nothing counts till next Saturday"). rulesClear 3–5 across all personas traces here first. It also poisons trust in every later number: "I know more and trust it less" (SKEP).

**RECOMMENDATION.** Log the mechanic (one sentence in spec §14 + a decision entry). One season-state producer feeding Home, Clubhouse, the form and the receipt. Season-aware preview: "Season starts Sat Sep 5 — this round builds your number; no league points yet", echoed on the posted card and receipt ("On your record · season starts Sep 5" vs "6 pts to Squad 1"). Delete the "No league yet?" line. Gate "Rounds count from today" on `atStarter()`, not `phase`.

### F2. The invisible allowance (R6) — a correct rule that reads as a bug

**OBSERVATION.** OBS, mid-season, saw one Aug 16 round as "You · **Beat your number by 3.3** · 85 · Troon North" on Home and "2026-08-16 · **+2.6 vs index · 9 PTS**" in the standings receipt (`obs/10-my-row.jpg`), and flagged it P1: "Two numbers, two bands, one round… by this table 3.3 would be 12 pts."

**INTERPRETATION (arithmetic inferred; `index_at_post` not visible to the tester).** The You tab lists the round at differential **10.3**. Home's card computes at 100% (`pvi = index_at_post − differential`, comment at `:16641`): 13.6 − 10.3 = **3.3**. The league view applies Standard's 95% (`round(index_at_post × handicap_allowance/100 − differential, 1)`, baseline `:1360`): 12.9 − 10.3 = **2.6**. Both are right; the allowance is the entire difference and demoted the round from the 12-band Home implies to the 9 the league paid. Validation confirmed PvI is produced in four places under three rules (client `recalc` at 100%; `home_feed` at 100%; `v_rounds_ranked`/`round_card` at allowance + window — the only spec path; and `score_round`'s fallback that sets `index_at_post` to the round's own differential when no index exists, which is R7's "+0.0 — PLAYED TO IT").

**IMPACT.** The organizer cannot reproduce a number by hand (ORG); the competitive golfer forms a fairness doubt the visible math cannot answer (COMP: "I have no reason to believe the flat 12/9/7/6/5 bands aren't tilted toward high-variance 20-handicaps"); the one screen that shows its work (the receipt) prints the raw index beside an allowance-applied verdict, so its arithmetic does not close. D2's "never shown" became "never explained", which is a different thing once the number changes between screens.

**RECOMMENDATION.** Per D2/D48, delete "95%" from the preset card and bylaws. In the receipt, show it working: "Your number 14.2 · plays as 13.5 (95%) · differential 15.9 · 2.4 over". Make every client preview use the league's allowance and window (one shared function), or label it the way iOS already does.

### F3. The sign convention (R3) — designed, and still wrong for golfers

**OBSERVATION.** ORG `org/68-round-filled.jpg`: "**-1.7** VS YOUR INDEX" in red beneath "A little loose, still cash in the bank"; result sheet "1.7 over your number"; receipt `org/71-round-detail.jpg` "Against your number **-1.7 — A LITTLE LOOSE**". NOV: "USER ASSUMPTION on first read: 'I beat my index by 3.7 — why only 5 points?'" CAS, three surfaces in four minutes: "-9.8 vs your index" → "9.8 over your number" → "+0.0 — PLAYED TO IT". SKEP: "'Best vs index -4.5 · Career best'". OBS: "'Avg vs index' is negative and red for both of us while my rounds 'beat my number'."

**INTERPRETATION.** §2.1: "PvI is the universal currency: positive = you beat your number." D1 (2026-07-15) ruled the *display* becomes words — "beat your number by 1.4" — and `vsPhrase()` (`:5710`) does exactly that for the posted card. The bare signed number survives at `:6339` (form), `:11519` (receipt verdict), `:11412` (standings), `:11481` (player receipts), `:2884` (You). Golf's only signed convention is score-to-par, where minus is good; the product's is the reverse and is never stated. D1 was applied to one surface of five.

**IMPACT.** The verdict on every posted round is read backwards by golfers, and the same round gets three phrasings. This is the moment (per the vision, "Memory > Statistics") the product is supposed to turn a score into a story; instead it produces a red number that the golfer argues with.

**RECOMMENDATION.** `vsPhrase()` everywhere; retire signed numbers from every surface. If a compact form is unavoidable in a table: "−1.7 worse" / "+5.0 better", never "vs index" with a bare sign. Label the band unit once ("measured on your differential, not strokes").

### F4. The endgame (R24–R27, R29) — a season with no visible ending

**OBSERVATION.** The bylaws row is the whole story: OBS `obs/21-bylaws-open.jpg` "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" behind "▸ LEAGUE RULES & PRO SHOP". Above it Home says "1st · — HELD · You lead by 22 points over Jade". The Climb's captions — "LOCKED", "HAS LOCKED A CUP SEED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (`obs/08-club-top.jpg`; `ios/03-clubhouse.jpg`) — and the empty-league version "TOP SEED · +10 · TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING" (`nov/36-clubhouse-full.jpg`) are the only foreshadowing. "top seeds race fresh" and "the regular-season leader carries a +10 head start" (`:12001`) are organizer-only surfaces. OBS Journey E: "What do I need to do to win? — **Not answered anywhere.**"

**INTERPRETATION.** §14.3: seeds lock at `ends_on − 27`; 2-squad leagues both advance, leader +10; finalists race on window points; ladder h2h months → best month → fewest rounds → coin; non-finalists keep the individual races. D4 (2026-07-15) named the exact failure — "the points leader discovers at reset time that the lead 'vanished' — reads as a rug-pull" — and prescribed a season-long foreshadow. Validation found the foreshadow *is* implemented, as one line in `#statFinal` (`:9614–9634`) under a "nearest deadline wins" sort, so the always-nearer Sunday week-close suppresses "Cup Final · <date> · Nd" for all but the final week. D105 (2026-08-28) admits the race surface itself never shipped: "the flagship moment of the product is invisible."

**IMPACT.** Seven of eight explanations end the season with a shrug. OBS's retention curve falls from 6 mid-season to 2 at season+30 because "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it." Nobody in a 2-player league is told that "EVERYONE ADVANCES" makes the final structurally hollow. The product's *name* is its least-defined noun.

**RECOMMENDATION.** One endgame sentence, everywhere the term appears and on the hero with a countdown: "The Cup Final is the last four weeks, from Dec 22. Points reset to zero (the season leader starts +10) and the squad with the most points in those four weeks takes the cup." Give the Final its own slot, not a shared deadline slot. Add "How it ends" and "Ties" sections to the scoring sheet. Tappable bylaw rows. Hide "LOCKED/ADVANCES" when K ≥ n. Warn a two-player Pro at setup.

### F5. Where the rules live and what they are called (R1, R14–R16, R36 — the H5 cluster)

**OBSERVATION.** Path to "How scoring works": Clubhouse → league room → League sub-tab → expand "▶ LEAGUE RULES & PRO SHOP" → "[How scoring & handicaps work →]" (ORG `org/49-scoring-help2.jpg`, found "18 minutes after starting the wizard, and only because the lock failed"), or the bottom of the You tab. Not linked from Home, Standings, the wizard's preset step, or the form's bands. Three vocabularies for one rule: preset "95% hcp · **GHIN rounds** · best 4 / mo count · 2-round floor" (`:3250`) → review "VERIFICATION **Attested**" (`org/30-wizard-step3.jpg`) → live "**auto-attested**". Three phrasings of the floor (JOIN J-08). Three label sets for the bottom band. Two grantors for the bye (wizard "Pro-approved" `:3318` vs sheet "automatically").

**INTERPRETATION.** D3 wanted cap/floor as prose at the door; D13 wanted "Vouch" as the only word; D14 made the bye automatic; D82 put depth "at the doors"; the vision's metric is "never need a tutorial." The prose is good and unreachable from the moments of confusion (a zero in standings, a preset card, a red "-3.7"). "GHIN rounds" is the §8 *index-source* row surfacing where the *verification* row was expected — both true, neither explained, and GHIN is never checked.

**IMPACT.** Every persona wrote some form of "the organizer will have to explain the rules to you, because the app doesn't" (IOS verbatim; CAS "I'd need Casey to explain half of it in the parking lot"; ORG "I would still have to explain them verbally, mostly to reconcile the contradictions"). Against the vision's own success metric, that is the audit's verdict on rules comprehension.

**RECOMMENDATION.** "Rules" as a first-class sub-tab; link the scoring sheet from the wizard's step 2, the form's band table and the standings header. One copy source per rule (floor, bye, band names). Apply D13 (vouch) and D14 (auto bye) as string replacements — the debate is over.

### F6. Money (R30–R34)

**OBSERVATION.** Understood by 8/8: "the app keeps the tab; you pay each other." Not understood by 0/8: the payment path — JOIN "the buy-in rows look like checkboxes but tapping only toasts 'The Pro marks buy-ins as money moves between you'"; CAS "pay Casey cash/Venmo and hope he ticks the box." Organizer trap: "$75 (DEFAULT)… hidden behind 'Customize'" with "Use these defaults →" as the primary button (`nov/19-wizard-customize-full.jpg`, `org/21`–`22`). Squad share: "$51 on a $50 pot" (ORG), "$251 on $250" (COMP); "the app never says how a squad payout is divided" (ORG). Side cash: "the $60 lives only as a board card" (COMP `comp/60-pot-after-skins.jpg`). Membership: no price anywhere (ORG, CAS, SKEP).

**INTERPRETATION.** §7 default $75 is the spec's choice; surfacing it only behind Customize is the UI's (validation: `$75` in `#stakeVal` is static markup never re-rendered after `resetWizard()` sets stake to 0, and `league_settings.buyin_cents` defaults to 7500 in the DB). D66's per-person payout with explicit rounding exists for the ceremony, not the Pot tab. D101's league pass is behind a flag; the web still says "COMING AT LAUNCH".

**IMPACT.** The ledger *concept* is the best-communicated business rule in the product; the ledger *mechanics* are absent at the point of highest bail risk. SKEP: "a real Sam replies 'wait, fifty bucks for what?' — and the app cannot answer." JOIN: "$0 collected · 5 still owe would just start an argument about who pays whom, which is exactly what the page claims to prevent."

**RECOMMENDATION.** Buy-in above the fold, default $0 (or the spec's $75 shown, never hidden). Covenant: "It's $50; you pay Casey by Venmo/cash before Sep 5; the app only keeps score of who paid." Pot tab: "$150 to the winning squad (split evenly) · Side-game cash settles between you and isn't tracked here." One membership sentence with a number.

### F7. Consent, roles and correction (R37, R41–R44)

**OBSERVATION.** CAS: "Someone else can put a 103 on my record" — a live game seated him, finished, and posted an attested 103 with no notification. JOIN/CAS/COMP/SKEP: a member's Home hero is "Lock it in and invite your crew" → the Pro's "CREATE YOUR LEAGUE · Review the bylaws, then lock it in" with a live lock button (`join/39-U-lock-it-in.jpg`, `skep/50-lock-page.jpg`); JOIN's Cancel offered "Cancel this league? … discards it completely" and only the server refused. Correction: an unlabeled ✕ on You › Recent rounds with a browser `confirm()`; no fix path on the receipt or posted card (NOV N-12, CAS A26, ORG ORG-35). Deleted rounds leave their badges behind (COMP).

**INTERPRETATION.** D40 ("a member must never see the Pro's configuration tool") was undone by D96's forming-hero CTA (`:10098–10112`, `wire('[data-hform]', nextStep.go)` gated only on `!starter`) — a regression the decision log does not record. D50's dispute paragraph was logged copy-only and is absent from the covenant testers read. Attestation-by-construction (§6) is a fairness feature for the group and a consent problem for the individual; the product tells the individual nothing.

**IMPACT.** The biggest button on every member's Home is one they are afraid to touch and it nearly deleted the friend's league. "What do I do now?" is answered with an admin tool. A wrong score has no labelled remedy; a disputed one has no path at all.

**RECOMMENDATION.** Role-gate the hero CTA and the wizard view (server-verify lock). Read-only forming card for players: "Casey locks the bylaws at first tee · squads drawn then · post from Sep 5." A labelled "Fix this round" on the receipt (delete + re-post, explained). A notification when a live round posts to your card. D50's paragraph on the covenant and in fine print.

### F8. The three clocks and the squad noun (R14–R18, R22–R23)

**OBSERVATION.** "MONTH CLOSES in 2 days" + "AUG FLOOR 0/2" a week before first tee (CAS A9, SKEP SK-12, COMP); "−5 sqd pts" in a solo league (OBS `obs/21`); the floor sentence on a Home with no league (ORG `org/14`, NOV `nov/10`); "WEEK 4 OF 14" vs "WK 4 / 13" (IOS); "Δ WK +10" two weeks after the last round (OBS); "squad" met on Home before it is defined in an organizer (i); "CAPT. —" always empty.

**INTERPRETATION.** Floor copy is authored separately on Home, the wizard (i), the explainer and the bylaws table; the month pill and floor bar key on the calendar, not the season window; snapshots are Sunday-only (D81) while §14.0 v1.1 weeks run from the first-tee weekday (D108) — two definitions of a week. "Squad" is introduced by its penalty before its definition.

**IMPACT.** NOV: "week/month/season are three clocks, never explained together." The team structure — the thing that makes it a league and not a leaderboard — is discovered on "tab six" (SKEP).

**RECOMMENDATION.** Suppress month/floor machinery before first tee and in solo leagues; one "how the calendar works" line on Schedule; reconcile the two weeks; define squad on the orientation card and the covenant ("You'll be drawn into one of two squads; your points go to your squad"); delete "CAPT." until captains do something.

## 1.4 The four priority tiers — what a user must understand, and when

Rules are placed by *when the consequence first bites*. A rule can be well taught later and still be a MUST here if the user commits before meeting it.

### Tier 1 — MUST understand before joining (the consent surface)

| Rule | What the user must be able to say | On the covenant today? | Conf. |
|---|---|---|---|
| R30 | "It's $50, I pay Casey by Venmo/cash before Sep 5; the app only keeps score of who paid." | Amount yes; path no | 6 |
| R39 | "It's Casey's league, 5 people, Sep 5 → Jan 2." | No roster, no Pro, no dates | 4 |
| R22 | "We'll be split into two random squads; my points go to my squad." | No — "squad" first defined in an organizer (i) | 4 |
| R14 + R15 | "I owe two rounds a month or my squad loses 5 per round short; the first miss is forgiven." | Floor yes; penalty and bye no | 7 / 4 |
| R1 + R3 | "Every round scores 5–12 against my own handicap; a bad day is still 5." | No (post-join welcome sheet has it) | 7 / 3 |
| R24 | "The last four weeks are a fresh playoff; the regular season decides seeds." | "FINISH · Cup Final · final 4 weeks" only | 2 |
| R41 | "The Pro runs it; I post rounds. Nothing on my screen is his job." | No | 3 |

### Tier 2 — MUST understand before the first round

| Rule | What the user must be able to say | At the post form today? | Conf. |
|---|---|---|---|
| R10 | "The season starts Sep 5 — this round builds my number, no league points yet." | **Contradicted** by the form's own points panel | 1 |
| R1 | "12 if I beat my number by 3, 5 if I just post." | Yes — the best-placed rule in the app | 7 |
| R3 | "+ means I beat it, − means I didn't" — better: words, not signs | No; the red "-3.7" is the moment of confusion | 3 |
| R2 / R6 | "'Beat by 3' is on the differential, at 95% of my index." | No; iOS says "100% preview", web says nothing | 4 / 2 |
| R9 | "Only my best four this month count; a better round bumps my worst." | Yes | 8 |
| R11 | "The round lives on my card; every league I'm in reads it." | Half — "counts on your card" reads as "counted" | 4 |
| R13 | "Any course counts under Standard; here's what my tees need to be." | No | 2 |
| R42 | "If I typed it wrong, I delete it here and post again." | No — only on You, unlabeled | 3 |
| R36 / R37 | "Scoring together vouches for the round; anyone who seats me live can post to my card." | Live screen only, after tee-off | 3 / 2 |
| R7 | "Until I have 3 rounds I'm scored against a starter (a provisional number)." | No; receipt reads "27.8 vs 27.8 · +0.0" | 2 |

### Tier 3 — Can learn during play (if the UI defines the term where it appears)

R15 bye · R16 short months · R17 month close · R12 nine holes · R5 index building · R28 individual titles · R27 clinch vocabulary (LOCKED / seed / seats — each needs a tap-definition) · R35 live rounds post, games don't score · R34 side money is off the ledger · R38 game rules · R8 estimated 18 · R32 owed vs collected · R45 how the draw works · R21 minimum four (organizer: step 1, not step 3) · R20 what "lock" freezes (organizer) · R46 what an event is.

### Tier 4 — Nice to know, until the moment it isn't

R26 tiebreak ladder (becomes MUST at `ends_on − 27` and for any tie at the cut) · R25 the points-table alternative · R29 the ceremony (becomes MUST in the final week — OBS: "the Cup Final arrives unannounced") · R33 membership pricing (becomes MUST before a Pro asks six friends for $50 — ORG) · R40 late joins / dropouts / cancellation · R43 the dispute procedure (becomes MUST at the first contested 79) · R44 what deletion removes · R23 captains (delete the word until it means something).

---

# Part 2 — Mental model

## 2.1 The model users currently hold

### 2.1.1 At the door (0 taps) — the cold Journey A answers, verbatim

Every persona saw the same door: "CUP SEASON · Rally your crew. Post real rounds. **Take the cup.** · [Continue with email] · [I have an invite code] · By continuing you agree to the Terms & Privacy Policy. · v23 · __CS_VERSION__" (`skep/02-cold-door.jpg`, `org/01-door.jpg`, `nov/01-door.jpg`, `join/01-A-cold-door.jpg`, `cas/09-R05-after-signout.jpg`, `comp/10-cold-door.jpg`). Nothing below the fold on a phone (the desktop "wing" is `display:none` under 1100px — validation TOP-2). Two testers flagged `__CS_VERSION__` as "unfinished software" before a single tap (SKEP, ORG); JOIN and NOV noticed it too.

| Question | Consensus cold answer | Verbatim |
|---|---|---|
| What does the app do? | "a golf thing for a group; you type in scores; someone wins a cup" — all 8 | SKEP: "That is inferred from three words; the screen never says it." JOIN: "Nothing tells me whether it is fantasy golf, a handicap tracker, a betting app or a league manager." |
| What is a season? | unknown / "a few months during which rounds count" — 7 guesses, 0 answers | NOV: "Not stated anywhere." SKEP: "Casey's text said 'for the fall', so I'm leaning on Casey, not the app." |
| What is a league? | the word is not on the door; "my group of friends" | NOV: "'Crew' is used instead. I assume a league = my group of friends." ORG: "the invite-code field calls it 'LEAGUE CODE' so a league is the thing you join with a code." |
| What is a cup? | a trophy — real, cash or bragging rights unknown | SKEP: "No idea. A trophy? A pot of money? A final tournament? The screen says 'take the cup' like it's obvious." COMP: "Could be a match-play playoff. Zero information." |
| Competing for? | "the cup"; money never mentioned | ORG (only one who opened Terms): "the legal page says prize pools exist but are handled by us." |
| Against whom? | "your crew"; individual vs teams unknown — 8/8 | NOV: "USER ASSUMPTION: … we're all in one group competing head to head." |
| How do rounds work? | "I type in a score after I play"; gross/net/handicap unknown | COMP: "'Post real rounds' hints at verification, but nothing says how." |
| After a round? | unknown; "presumably a leaderboard moves" — 8/8 | — |
| Different from playing with friends? | "it keeps score over time and there is a cup" | SKEP: "'Rally / post / take' is a slogan, not a mechanism… why not a spreadsheet." CAS: "That is all the door says." |

SKEP's summary of the door: "a wall with two handles." The invite landing added one line — "You're invited to The Papago Grind. Enter your email and you're in." — and stripped the code from the URL (`join/02-B-join-link-landing.jpg`); COMP: "A real invitee would have to ask Casey 'so what is this?'"

### 2.1.2 After 30–50 minutes — the eight 30-second explanations, verbatim

**ORG (Casey, organizer), 3/10:**
> "It's a fantasy-league-style golf season for our group. We're split into two squads by a blind draw. Every real round you play — anywhere, any course — you post your score and the app scores it against your own handicap: crush your number and it's 12 points, play to it and it's 7, even a bad day is 5 as long as you post. Your best four rounds a month count for your squad, and you have to post at least two a month or the squad loses points. It runs four months, then the last four weeks are a fresh 'Cup Final' and the hot squad takes the cup. Fifty bucks in, the app keeps the tab, winners split it 60/25/15 and we pay each other. And when we actually play together you can run match play or Wolf in it and it tells you who owes who at the end."

**NOV (Dana, first-time organizer), 4/10:**
> "Cup Season is a fantasy-league thing for our actual golf. I set up a league, we each throw in twenty-five bucks, and the app splits us into two squads. Then you just go play golf wherever, whenever, and post your score — it works out how you did against your own handicap and gives you five to twelve points, so a bad day still gets you five. Your best four rounds a month count for your squad, and if you don't post at least two a month your squad gets docked. It runs thirteen weeks; the last four weeks are a 'Cup Final' where the top squads start fresh and whoever's hottest wins the pot. There's also a live mode for skins or match play when we're actually out together, and you can drag guys in as guests without them having an account. Honestly, the setup asked me a bunch of stuff I didn't understand and it told me it failed when it hadn't, but once it's running the round-posting part is slick."

**JOIN (Marcus, invitee), 3/10:**
> "Cup Season is an app where a group of golf buddies runs a season — ours is 17 weeks, September 5th to January 2nd. Everyone puts $50 in a pot, you get split into two squads by a blind draw, and every round you play anywhere counts: you post your gross score and tees, and the app scores it against your own handicap, so a 15 beating his number gets the same points as a 6 beating hers. Your best four rounds a month count for your squad, you owe at least two rounds a month, and the last four weeks are a 'Cup Final' that's scored fresh. The winning squad takes 60% of the pot, second 25%, and the top individual 15%. The catch is the app doesn't move money — Casey keeps a tab, and I still don't know how I'm supposed to pay him."

**CAS (Jordan, no handicap), 4/10:**
> "It's an app for our golf group. Casey set up a 'league' for the fall — four months. Everybody chips in fifty bucks into a pot the app keeps track of, but you still pay Casey directly. It splits us into two squads by random draw. Every time you play, you type in your front and back nine and the app turns it into points — five to twelve — based on how you did against your own handicap, which it works out for you after three rounds, so a 97 from me can beat an 84 from Priya. Your best four rounds a month count for your squad, and if you don't post at least two a month your squad loses points. There's also a live scorecard thing where you can play match play or skins for five bucks while you're out there, and it posts the scores for you. At the end there's some kind of Cup Final and the pot gets split. I still don't totally get how the squad points and the individual points fit together, and I'm not sure my rounds this week even count."

**COMP (Priya, 6.4), 5/10:**
> "Cup Season is a season-long golf league app for your friend group. Everyone posts their real rounds from wherever they play, and each round scores 5 to 12 points based on how you did against your own handicap — beat your number by three and you get 12, a bad day still gets 5, so the only way to hurt your team is not to play. Your best four rounds a month count for your squad, you owe at least two a month, and there's a $50 buy-in that pays the winning squad, the runner-up and the top individual points scorer. The last four weeks are a 'Cup Final' that's scored fresh — I honestly don't know what that means yet. On the course you can run skins, match play, Wolf or Sunningdale live in the app and it settles the money hole by hole."

**SKEP (Sam), 3/10:**
> "It's an app that turns our regular rounds into a season. You join Casey's league, and every time you play — anywhere — you type in your front and back nine and it scores you against your own handicap: 5 points for just posting, up to 12 if you beat your number by three. Your best four rounds a month count for your team — it splits us into two random squads — and if you don't post at least two rounds a month your team loses points. There's a fifty-dollar buy-in it keeps a tab on but doesn't actually collect, and after four months there's a final few weeks that decides who takes the pot. It also has a chat and a scorecard for side bets. Honestly the scoring idea is good; the app just doesn't tell you any of that until you dig."

**OBS (mid-season, real account), 4/10:**
> "Cup Season is an app for a season-long golf league with your friends. Everyone posts their real rounds from wherever they play, and each round scores points against your own handicap — beat your number and you get more points, have a rough day and you still get five just for posting. Your best four rounds a month count and you owe at least two a month or you lose points. Points stack up over a 26-week season; there's a pot, a leaderboard, and side titles like Points King and Iron Man. Apparently the last four weeks are a 'Cup Final' that's scored fresh, but I only found that in the fine print — I honestly can't tell you how the winner is decided."

**IOS (static screens only), 4/10:**
> "It's a golf app where your friend group runs a season — ours is 13 or 14 weeks, the app can't decide. You post your rounds with your handicap, and somehow that turns into points; I'm in 2nd with 9, Galen has 19, and I honestly can't tell you how he got there or how I get more. There's a calendar for planning rounds together — it calls them a 'tee sheet' — and a live-scoring thing where you set up a foursome, but it never says what game you're playing. You collect badges like 'Broke 90' on your profile and pick a little icon named after a famous golf hole. There's a pot, but ours is 'bragging rights'. The organizer will have to explain the rules to you, because the app doesn't."

### 2.1.3 The composite model (frequency across the eight)

> Cup Season runs a months-long golf league for a friend group **[8/8]**. Everyone posts real rounds from anywhere **[8/8]**. Each round is scored against your own handicap into 5–12 points, so a high handicap and a low one compete evenly **[7/8]**. Your best four rounds a month count for your squad **[7/8]**; you owe two a month or your squad loses points **[7/8]**. The league is split into two random squads **[5/8]**. There's a buy-in the app keeps a tab on but doesn't collect; you pay each other **[7/8]**. The last four weeks are a "Cup Final" that's "scored fresh" **[7/8]** — and I can't tell you what that means **[7/7 who mentioned it]**. On the course you can run skins, match play or Wolf in the app and it settles who owes who **[6/8]**.

Three testers reached for the phrase **"fantasy league"** unprompted (ORG, NOV, SKEP) — the spec's own category (§12, "fantasy sports where your foursome are the athletes"). The analogy is doing the work the UI should: it supplies "squads," "points," "a final" as slots, and each tester fills each slot with a guess.

### 2.1.4 Journey A re-answered — what moved and what did not

| Question | Cold (0 taps) | End (30–50 min) | Still unresolved at the end |
|---|---|---|---|
| What does the app do? | "a golf thing, someone wins a cup" | Season-long points league vs your own handicap, squads, pot, live side games — 8/8 | — |
| Primary action | "sign up" | "Post a round (the ⊕)" — 8/8; but JOIN: "The Home screen still says 'Lock it in and invite your crew'" | For an organizer, "get 3 more people in" (NOV) — the app "doesn't treat it that way" |
| Season | "a stretch of time" | exact dates + week count — 7/8 | Which of three clocks matters; two week counts on iOS |
| League | "my friends" | group + bylaws + pot + squads + board + a Pro — 8/8 | "also called 'your groups' and 'the room'" (ORG); crew ≠ buddies ≠ league (NOV) |
| Cup | "a trophy" | **still fuzzy — 6/8 say so explicitly** | ORG: "the app also uses it as a count of leagues I'm in"; COMP: "this is the app's name and I still can't define it"; CAS: "Is the cup the squad prize or the season?" |
| Competing for | "the cup" | the pot 60/25/15 + trophies + titles — 8/8 | How a squad's 60% becomes my number; whether "Cup champs $150" is mine |
| Against whom | "my crew" | my squad vs the other squad; individuals for Points King — 7/8 | "I don't know my team or my opponents" (JOIN); "I did not know it was a team game until tab six" (SKEP) |
| How rounds work | "type a score" | gross + tee → differential → band vs index — 8/8 | Strokes vs differential; 95%; which index |
| After a round | unknown | card, receipt, board post; "points… once the season starts" — 8/8 | "Points/standings did not move for me… still don't know when they will" (CAS) |
| Different from playing with friends | "a running tally" | handicap-fair race + ledger + a final — 8/8, and SKEP: "That IS different — and the door says 'Rally your crew. Post real rounds. Take the cup.'" | "learned from a help sheet four taps deep, not from the product surface" (NOV) |

## 2.2 The model the product intends

**Vision** (`spec/product-vision-v1.0.md`, "Vision"): "Cup Season exists to make every round of golf matter because it belongs to a season. Golfers don't just post scores. They build rivalries. Win championships. Create traditions." Principles: Golf First · Low Friction Wins · Real Golf · **Memory > Statistics** ("Golfers don't remember 'I averaged 31.8 putts.' They remember 'I birdied 18 to beat Jake.'") · The App Should Feel Alive. Success metrics: "join a league in under 30 seconds · post a round in under 60 seconds · understand standings in under 10 seconds · **never need a tutorial**."

**The pipeline** (`spec/spec-v1.0.md` §1): "Every league, regardless of settings, runs the same five-stage pipeline: **POST a round → SCORE it (points) → COUNT it (monthly caps/floors) → RANK squads (season format) → CROWN a champion (the Cup)**." Design principles the whole model serves: every posted round scores (§1 #1); steady bogey golf can win (#2); volume can't buy the cup (#3); **set it once, argue never** (#4 — "All rules lock at first tee. Mid-season disputes go to the commissioner override log, not the group chat").

**The mechanics behind it:** §2.1 PvI = playing index − differential, "positive = you beat your number"; §2.2 the five bands, "the 12-point ceiling is the anti-sandbagging feature", "a posted 98 beats an unposted 82"; §3 best-N cap + floor + bye; §3.3 squad month = Σ counting points − penalties; §4 the individual layer always on; §5 app-computed WHS-style index, provisional rounds score normally badged (D49); §6 attestation by construction (D13: the word is "vouch"); §7 track never hold, owed vs collected (D106); §13 side games "never touch cup points; app tracks, Venmo moves, nothing held"; §14.0/§14.3 the Cup Final "scored fresh", seeds, +10, the ladder; §14.4 the Trophy Room "screenshot-shaped by design"; §15 the blind draw; §16 "no points figure without a path to the rounds that produced it… round receipts show the rating/slope/**allowance** snapshot."

**What the decision log already knows about the gap.** D1 (currency in words) · D2 (the number soup on a round) · D3 (floor as prose at the door) · D4 (Cup Final reset, unforeshadowed — 2026-07-15) · D5 (receipts) · D13 (vouch) · D14 (auto bye) · D24/D26 (honest clinch math with a face) · D47 (noun sweep: "card never unqualified", one code noun) · D50 (the ruling, copy-only) · D51 (the stake line — "never say counting cap") · D66 (an ending) · D105 (the Cup Final you can see — 2026-08-28, "the flagship moment of the product is invisible"). **The mental-model gap is largely the gap between these decisions and what shipped.**

## 2.3 The gaps — where the intended model and the held model part

**What landed (8/8 or 7/8):** stages 1–3 of the pipeline, near-verbatim. The anti-sandbag ceiling and the 5-point floor ("you can't hurt your team by playing badly, only by not playing" — quoted back by four testers). The ledger posture (D39). The live-game/settlement layer (§13) — rated the highest of anything in the product (COMP 8/10, ORG 8/10).

**What did not land (0/8 confident):**
- How the Cup Final decides the winner and what "scored fresh" does to the points already on the table (stage 5).
- How squads are compared and what a seed is (stage 4).
- How ties break — anywhere (standings, seeds, Points King, skins).
- What the 95% allowance does, or that it is why two screens show different numbers.
- What "Attested" asks of a player at post time.
- How, when and to whom the buy-in is paid; how a squad's 60% becomes a person's payout.
- Whether a round posted this week counts (until inferred from zeros).
- What "the cup" is, in one sentence.
- Any reason a *particular* round matters — COMP: "no rival, no gap to the leader, no 'this round matters because' line"; D51's stake line is decided and unbuilt.

**The shape of the gap.** The held model is the intended model *with the last two stages cut off*, plus the lens model (rounds belong to the card; leagues read them) missing entirely, plus no ending. OBS's retention curve makes the cost concrete: understanding 6 mid-season → 4 late → 3 finale → 2 at season+30, because "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it." The vision promises rivalries, championships and traditions; testers found rivalries only by accident (two-player leagues), championships as a bylaw row, and traditions as "SEASON I everywhere".

**The same copy, opposite readings** — the strongest evidence that the gap is the UI's, not the testers':

| Copy | Reading A | Reading B | Intent |
|---|---|---|---|
| "-3.7 VS YOUR INDEX" | NOV: "I beat my index by 3.7 — why only 5 points?" | COMP: "+ means better (green); −4.5 means worse (red)." | §2.1: negative = worse |
| "MONTH CLOSES in 2 days" | CAS: "I need 2 rounds in the next 2 days." SKEP: "Do I owe 2 rounds… before the season even starts?" | OBS: "what closes? what happens?" — no consequence imagined | §14.2 close; irrelevant pre-season |
| "LOCKED" | OBS: "my place in the standings can't change." | IOS: "both rows carry it, so it cannot distinguish us." | D24: a clinched Cup Final seat |
| "— HELD" | OBS: "I held 1st place from last week." (correct, `:10185`) | IOS: "held what — position? a hold on me?" | rank unchanged vs Sunday snapshot |
| "Lock the bylaws & form the squads" / "LOCKS AT FIRST TEE" | ORG: "settings freeze on the season's first day (Sep 5)." | JOIN/CAS/SKEP: "this button reads as somebody else's job… 'lock' sounds irreversible." | D40: the Pro's tap; first tee is a date |
| "GHIN rounds" (Standard preset) | ORG: "does Standard mean my buddies without a GHIN can't post?" | NOV: "does this mean players must ALSO post to GHIN? Does the app check?" | §8 index-source row; never checked |
| "Cup Final · scored fresh" | NOV: "the top squads start fresh and whoever's hottest wins the pot." | COMP: "the regular season is only for seeding (guess)." OBS: "the lead I've watched… may mean nothing." | §14.3: both squads at 2-squad scale, leader +10 |
| "$150 Cup champs" | COMP: "'Cup champs $150' is what I win." | ORG: "the app never says how a squad payout is divided." | D66: split at the ceremony |
| "Post a stake" (Pot tab) | NOV (before): "side-game dollars go on the Pot ledger." | NOV (after): "'stakes' are NON-money bragging bets." | D64 forfeits; side cash off-ledger |
| "NEXT · Open · PLAN A ROUND" | NOV: "the next league round is open" (for twenty minutes). | NOV (after tapping): "'Next' = your next planned tee time, 'Open' = you haven't planned one." | the tee sheet |
| "One Pro-approved bye month" (wizard) vs "your season bye covers you automatically" (sheet) | NOV: "'Pro-approved' means I'll be adjudicating my friends' vacations." | ORG: "one forgiven floor miss per season — partly." | D14: automatic |
| "COUNTS ON YOUR CARD" | NOV: "as a novice I read that as 'counted'." | SKEP: "nothing happened to the competition." | `:6588`: the out-of-season branch |
| "The Pro" | NOV: "for a beat I thought the app was assigning me a pro." CAS: "a golf pro at a course." | ORG: "the organizer/commissioner (me) — partly." | the commissioner (D15 kept the collision) |
| "beat it by 3" | SKEP: "net score three under my handicap-adjusted expectation." | COMP: "index minus differential (1.4 vs 6.4 = 5.0), a slope-adjusted number." | §2.1 PvI on the differential |
| "Squads · LIVE NOW — CAPTAINS READY" | CAS: "squads are set." | ORG/JOIN/SKEP: both squads "Empty"; "there are no captains anywhere." | phase `draft` label (`:12231`) |

**The one sentence every persona wrote in some form:** "The organizer will have to explain the rules to you, because the app doesn't." (IOS verbatim; CAS "I'd need Casey to explain half of it in the parking lot"; NOV "I would still have to explain them verbally"; SKEP "the app just doesn't tell you any of that until you dig"; ORG "mostly to reconcile the contradictions".) That is the tutorial the vision forbids.

## 2.4 Where the model breaks — noun by noun

| Noun | What the product means | What testers thought / said | Where it breaks |
|---|---|---|---|
| **League** | The competition container: crew + bylaws + pot + board + squads; can run many seasons ("SEASON I"). D11: crew = people, league = competition. | Fine after the orientation card (8/8). But the door says "crew," the field says "LEAGUE CODE," the button says "invite code," the toast says "Invite code:" — "three names for one thing" (JOIN J-15). NOV: "I assumed crew = league; the app says buddies are a separate, points-free thing." ORG: also "your groups" and "the room". | Naming, not concept. The door leads with the one noun (crew) that maps to the relationship (buddies) the app then says has "nothing to do with leagues or points." |
| **Season** | A dated window, N whole weeks from a first-tee weekday, with monthly machinery and a four-week final; phases setup → forming/draft → live → cup_final → complete. | Understood as dates once inside (ORG 9/10, NOV 9/10). Phases are the break: one unlocked, one-member league is "FORMING," "Squad formation," "LIVE NOW — CAPTAINS READY," and "is live" on four screens (ORG ORG-10); locked-before-first-tee is "SEASON LIVE — Rounds count from today" on Home and "BEFORE FIRST TEE · practice rounds" in the Clubhouse (NOV N-03). Three clocks (week/month/season) never explained together. iOS: 13 or 14 weeks. | Four status strings for one state machine (D81 built the machine; the copy didn't follow — validation: labels hard-coded at `:3553`, `:12231–12232`, `:3428` and five other sites). |
| **Round** | A profile fact (gross, rating, slope, date, index snapshot, differential) that every league *reads*; immutable; scored by each league through its own bylaws. | "A round = any 18 or 9 you post, any day, any course" (NOV — correct). But "counts on your card" ≠ counted (NOV, SKEP); "card" = golfer card / scorecard / settlement card / Post card / "on the card" (SKEP SK-34: five meanings). Nobody knows how to fix one (R42). | The lens model is invisible; "card" is overloaded five ways; the pre-season state is narrated as success. |
| **Cup** | The season championship — the trophy — decided by the Cup Final or the points table. | "Still fuzzy" (ORG, COMP); "still not defined anywhere" (JOIN); "unclear whether it's the squad prize or the whole season" (CAS); ORG also read "Cups & events · 1 · Played in" as the app counting leagues as cups; SKEP: "Best guess: the 'Cup Final'… whose winners are 'Cup champs'." | The product's *name* is the least-defined noun in it — used for the title, the per-round points ("cup points"), the final, the winning squad ("Cup champs"), a seed ("cup seed") and a count ("Cups & events"). |
| **Cup Final** | The final four weeks, scored fresh under the counting rules; seeds carry (+10 for the 2-squad leader); ladder on ties. | "the top squads start fresh" (NOV); "regular season only for seeding (guess)" (COMP); "some kind of Cup Final" (CAS); "a final few weeks that decides who takes the pot" (SKEP); "the 22-point lead may mean nothing" (OBS). | One bylaw row; "scored fresh" undefined on six lines; seeds/+10/ladder unstated; foreshadow line starved by a nearest-deadline sort. |
| **Match / side game** | A live game (match play, Wolf, skins, Sunningdale) on a parallel ledger; the *round* posts, the *result* never touches cup points; money settles between players. | Mostly right when read at the live screen (ORG, COMP). Wrong assumption everywhere else: "side-game dollars go on the Pot ledger" (NOV, COMP); "does winning the match matter for the Cup?" (CAS); "$5 match decided by a silent default" of index 18 (CAS). | Correct at the live door, absent from every season surface; "stake" means money here and never-money on the Pot tab. |
| **Standings** | Squad table + individual race + the Climb (a you-centered ladder with honest clinch math, D24/D26). | "Three redundant tables for two people" (OBS). LOCKED / seed / seats / +10 / ceiling undefined (OBS, NOV, IOS). Standings answer "who's ahead" but never "what do I need to do to win" (OBS: "Not answered anywhere"). Gap line under the wrong row on iOS. | The Climb's *vocabulary* shipped without its *explanations*; the projection D24 promised is not a sentence anyone can read. |
| **Points** | Cup points per round (5–12) → counting points → squad month → season total; the individual layer beside it. | Per-round: understood (7/8). Aggregation: "I still don't totally get how the squad points and the individual points fit together" (CAS); "nothing says whether the individual Pts column is capped too" (COMP); "10 points back" with no leader named (IOS); "what a 'point' is and how a round becomes points" (IOS confusion debt #1). | Round → points is taught; points → table is not; the number previewed is not the number scored (allowance, window). |
| **Pot** | Stake × roster (owed) and collected (cash); split 60/25/15 by role; resolved to people at the ceremony; a $0 league shows no pot. | The ledger: 8/8. The path: 0/8. "$0 collected · 5 still owe would just start an argument about who pays whom, which is exactly what the page claims to prevent" (JOIN). "Four money nouns" (ORG). "$251 on $250" (COMP). | Concept landed; mechanics (pay whom, when; squad share per person; side cash; membership price) did not. |
| **Squad** | A team drawn at lock; squad points = Σ members' counting points − penalties. | "Squad = the whole league" (CAS); "three things at once — a team, a formation state, a points target" (SKEP); "I never learn mine" (JOIN); "captains? who picks them?" (NOV). | Introduced by its penalty ("−5 sqd pts") before its definition; defined only in an organizer (i); printed in solo leagues. |
| **The Pro** | The commissioner: locks, draws, marks buy-ins, grants byes, rules. | "For a beat I thought the app was assigning me a pro" (NOV); "a golf pro at a course" (CAS); "sounds like a course professional" (SKEP, OBS). Members were handed the Pro's tools. | D15 chose the collision knowingly; the *role boundary* is the real break — the product does not enforce who is the Pro on the member's Home. |
| **Bylaws / lock** | The rule set, frozen at lock; the season starts at first tee; the endgame stays switchable. | "Legal word for settings" (NOV); "three lock moments" (ORG); "'locked at first tee' apparently means 'locked in a week'" (NOV); "'lock' unexplained, sounds irreversible" (JOIN). | One word for two moments and one non-freeze; "bylaws §4" cites a document never served. |
| **Buddies / crew** | A mutual follow graph, "nothing to do with leagues or points" (D80). | "I already have a league of buddies; a second friends list is a second thing to maintain" (SKEP); door's "crew" ≠ buddies ≠ league (NOV). | D80's noun landed; the door still says "crew." |
| **The board** | The league feed + chat where rounds land automatically. | Fine once seen (7/8). iOS: "the screen literally called 'the board' says the league is empty" while Home shows 18 items. Web: "'THE BOARD · ROUNDS LAND HERE AUTOMATICALLY' but neither of my posted rounds… appear" (CAS A16). | Concept fine; the promise "rounds land here" was false for pre-season rounds. |
| **Event** | The short game (Ryder, Major, Bracket-soon); its own trophy; standalone or attached. | Nobody opened one. "Two teams · weekly vs-index duels · first to the clinch" = "jargon; no relation to my league explained" (CAS A33, IOS). | Untested; the tiles are spec-speak (D12 said "duel" and "event" are schema words only). |

---

# Part 3 — Terminology glossary

## 3.0 The headline

The vocabulary problem is not that the words are bad — most are charming. It is that the app introduces roughly 120 product-specific terms and defines almost none of them where they are first met; uses several in two or three senses; prints a handful its own decision log already retired; and in three places puts internal engineering language on screen. Seven systemic pathologies, each documented in the table:

1. **Undefined at point of use.** The definitions exist (the scoring sheet, the five How-it-works cards, the wizard (i)s) but sit behind a collapsed disclosure, an optional Customize panel, or the bottom of the You tab. Cup, Cup Final, seed, floor, squad, the Pro, attested, allowance, tee sheet, bylaws — all met before defined.
2. **Overloaded nouns.** "Card" (five senses), "cup" (four), "stake" (two, opposite: money vs never-money), "tee sheet" (calendar vs live scorer), "lock" (three moments), "squad" (team / phase / penalty unit), "the books" (money / pride bets).
3. **Three label sets for one concept.** The point bands wear different names on the scoring sheet, the post form, the preview message and the receipt; the verification tier is "GHIN rounds" on one screen and "Attested" on the next; the invite code has four labels.
4. **Golf words used against their golf meaning.** "The Pro" (a club professional), a negative "vs index" (minus is good in golf), "short game", "receipts required", "tee sheet", "No. 2".
5. **Spec-retired or spec-forbidden terms still on screen.** The allowance % (D2/D8/D48), "attested" (D13), "Pro-approved bye" (D14), "event" as a label (D12), "counting cap" (D51), "invite code / league code" both (D47), unqualified "card" (D47).
6. **Internal language leaking.** "PROJECTED UNDER A GENEROUS CEILING" (D24's honesty-rule phrasing printed verbatim at `:4479`); "the stepper"; "the pilot"; "mints a trophy"; "bylaws §4" (a repo document never served); "staged" (`:12024`, survived D97); "THE HAT SHUFFLES SERVER-SIDE".
7. **The number shown is not the number that scores.** Preview and any pre-season/league-less receipt compute "vs your index" at 100%; league scoring applies the preset allowance; the bylaws advertise "95%" and no surface shows it acting.

**Classification key.** *invented* (a Cup Season coinage) · *golf-different* (a real golf word used in a non-golf sense) · *fantasy* (fantasy-sports vocabulary) · *leagues* (generic league/commissioner vocabulary) · *ambiguous* (one word, meaning not recoverable from context) · *overloaded* (one word, several product senses) · *internal* (engineering / decision-log language on screen). **Confusing?** is the audit's judgement: would a normal golfer (CAS's Jordan, 10–20 rounds a year, no handicap) ask "what does that mean?" at first sight — with the reason.

## 3.1 The complete table

### 3.1.A The competition container

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Cup / the cup / "Take the cup"** | invented · **overloaded** | ORG: "the season championship; also used as a count of leagues ('Cups & events · 1')". NOV: "two meanings — the trophy and the 4-week playoff". CAS: "unclear whether it's the squad race or the whole season". COMP: "this is the app's name and I still can't define it". All 8 marked it confusing. | §1: the pipeline ends "CROWN a champion (the Cup)" — the season title. Reused as "cup points" (§2.2), "Cup Final" (§14.3), "Cup champs" (Pot tab), "Cups & events · Played in" (`:2886`, a count of leagues + events joined), "cup seed", "the full cup experience". | **Yes** — four senses; the door says "Take the cup" and nothing says what the cup is. | Reserve "the Cup" for the season title. "Cup points" → "points". "Cups & events" → "Leagues & events". "Cup champs" → "Winning squad". Define once on the door or orientation: "The cup is the season championship." |
| **Season** | leagues | Mostly clear once dates are seen; ORG/SKEP "partly" — NOV: "three clocks (week / month / season), none explained in one place". IOS: "13 or 14 weeks, the app can't decide" (`ios/01-door.jpg` WEEK 4 OF 14 vs `ios/03-clubhouse.jpg` WK 4 / 13). | §14.0: N whole weeks from a first-tee weekday; calendar months are the cap/floor unit; the last four weeks are the Cup Final. | Partly — the word is fine; the clocks are not explained together and the phone disagrees with itself. | Keep. One "how the calendar works" line on Schedule; fix the week count. |
| **League** | leagues | Clear to all. ORG: also called "your groups" (Clubhouse header) and "the room" ("OPEN THE ROOM" tile). | The competition container (D11); the Clubhouse is its room. | Slightly — three nouns for the container. | Keep "league"; "YOUR GROUPS" → "Your leagues"; "Open the room" → "Open the league". |
| **Event / Start an event / the short game** | overloaded (D12 said schema-only) | ORG/NOV/JOIN: "a short competition with its own trophy — never opened"; CAS: "unclear relative to my league"; NOV: "the long game / short game distinction lands". | A standalone short competition — the Ryder, a Major, Bracket (SOON) — that can attach to a league. D12 ruled "event" a schema/doc word; the UI uses it as a Home button, a You stat and a guide title. | Mildly — understood as a category, never as a thing. "Short game" is a golf term (chipping/putting) reused. | Un-retire "event" formally, or say what it is: "Start a Ryder or a Major". |
| **Crew / buddies / league mate / BUDDY tag** | overloaded | NOV: "I assumed crew = league" — then the explainer said buddies have "nothing to do with leagues or points". SKEP: "a second friends list to maintain". IOS: "friend tiers". | D80: **buddy** = mutual golfer bond; **league mate** = co-member; **crew** = colloquial register only. | Yes at the door: "Rally your crew" points at the one relationship that explicitly has nothing to do with leagues. | On the door say "your league" or "your group"; or keep "crew" and stop telling users buddies are unrelated to leagues. |
| **Clubhouse** | golf-borrowed (fine) | Clear ("one league's room" — CAS, COMP, SKEP). | The per-league room: Standings / Board / Schedule / Pot / Album / League. | No. | Keep. |
| **The board / THE BOARD ↗ / BOARD · 6 NEW TODAY** | leagues | NOV: "undefined until seen — a leaderboard? a message board?"; IOS: "the screen literally called the board says the league is empty" while Home shows 18 items; SKEP/CAS: "ROUNDS LAND HERE AUTOMATICALLY" but the round did not. | The league's `posts` feed + chat ("the social spine"); the Home tile counts unread. | Partly — the first meeting (orientation: "table, board, pot") is a list of undefined nouns. | Keep; first mention "the Board — the league's feed and chat". |
| **Table / "counts toward a table"** | fantasy | NOV/ORG/JOIN: "standings, I guess". | Standings. | Slightly. | Say "standings". |
| **The room / YOUR GROUPS / HERE / IN SEASON** | ambiguous | ORG: "the room"; OBS: "HERE" chip = the league you're looking at. | Switcher chips; HERE = selected. | Minor. | "Your leagues"; "viewing" instead of HERE. |

### 3.1.B Roles and the business layer

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **The Pro / PRO — THAT'S YOU / THE PRO · CASEY** | **golf-different** | NOV: "the golf word already means the club professional; for a beat I thought the app was assigning me a pro." CAS/SKEP/OBS: "sounds like a course professional." IOS: "the organizer? a golf pro?" ORG: "I got it from context; a friend would not." | The commissioner (`league_members.role='commissioner'`): sets indexes, grants byes, marks buy-ins, draws, locks, switches the endgame, cancels. D15 logged the collision with "Pro Shop" and kept it. | **Yes**, on every tester's list — a real person your buddies know is called the pro; the app redefines it silently. | "Commissioner" (the spec's own word) or "the Commish". If "the Pro" stays, define at first contact: "the Pro — the one who runs the league". |
| **Pro Shop / Cup Season membership / Membership & billing / PLAN FREE · PILOT** | golf-different · overloaded with "the Pro" | NOV: "used three times before defined — sounds like a paid tier." ORG/SKEP: "a coming subscription; no price; who pays?" CAS: "paid features coming at launch." | The paid tier — D56/D101: a per-league **league pass** (~$89/league-year, first year free, Founding Leagues free forever); checkout unbuilt. Four names on screen. | Yes — a pro shop sells gloves; the tier's own decided noun never appears. | "League pass". One sentence where money is discussed: "The app is $89 a year per league, paid from the pot — free this year." |
| **The pilot / THE PILOT RIDES FREE / after the pilot** | **internal** | NOV/ORG: "am I 'the pilot'?" SKEP: "currently free." IOS: "internal language." | The beta period; Founding Leagues free forever (D56). | Yes — a project-management word on a customer surface. | "Free during the beta" / "Founding leagues play free forever." |
| **✦ FOUNDER / Founding Member / Founder's desk** | invented | IOS: "early user? league creator?" OBS: admin tools. | D102 profile tags; Founder's desk = owner-only admin. | Mild; persona-specific. | Tooltip "first on Cup Season". |
| **Captain / CAPT. — / LIVE NOW — CAPTAINS READY** | fantasy · **vestigial** | NOV: "squads have captains? never explained." ORG: "there are no captains anywhere on this screen." JOIN/COMP/SKEP: "captains ready" contradicts "squads are forming". | §15: an optional label until the captain playoff — which D105 replaced with the ladder. `:12231` prints "LIVE NOW — CAPTAINS READY" for phase `draft`; the "CAPT. —" column is always empty (`nov/36-clubhouse-full.jpg`). | Yes — a role that does not exist in the product. | Remove "CAPT." and "CAPTAINS READY" until captains do something. |

### 3.1.C Setting up a league

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Bylaws / the bylaws lock / "bylaws §4"** | leagues (legal register) | NOV: "legal word for settings." **ORG, JOIN, OBS: "bylaws §4 — a document I cannot find."** | The league's rule set (`league_settings`). "§4" cites spec-v1.0 §4 — a repo file never served (`:3506`). | Yes — the citation points nowhere a user can go. | "League rules". Delete "— bylaws §4" or link it to the rules sheet. |
| **Lock / Lock it in / LOCKS AT FIRST TEE / locked at first tee / Lock the bylaws & form the squads / Lock opens the invite link** | overloaded (three moments) | ORG ORG-08: "three different lock moments in one screen." NOV: "'locked at first tee' apparently means 'locked in a week'." SKEP: "organizer action: freeze bylaws and draw squads." JOIN: "'lock' unexplained, sounds irreversible" — and members saw the button. | Lock = the Pro's tap that moves setup → forming, opens the share sheet (D40) and freezes the bylaws; first tee = `starts_on`. "Locks at first tee" is stale (the endgame switch survives lock). "Lock opens the invite link" is false — the code exists pre-lock (`org/37`). | **Yes** — the single most-cited organizer confusion. | Two verbs: "Publish the league & open invites" (the tap) and "Rules freeze at first tee" (the date). Never "lock" for both. Hide the button from non-Pros. |
| **First tee / Before first tee / KICKS OFF IN 7 DAYS** | golf (fine) | Clear. NOV: "as a label for a date it took a second." | `seasons.starts_on`; D47 chose "Before first tee". | No. | Keep. |
| **"SEASON LIVE — Rounds count from today" vs "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"** | contradiction | NOV N-03: "Home says the season's on… the Clubhouse, ten seconds later, says practice rounds hit your card, not the season." | `:10105` prints the first for the pre-first-tee state; `:12225` prints the second. Only the second is true before `starts_on`. | Yes — opposite statements on adjacent screens. | One state string: "First tee Sat Sep 5 — rounds before then build your index, not the season." |
| **Forming / Squad formation / Squads are forming / The Pro has the list / Complete · rosters locked / LIVE NOW — CAPTAINS READY / is live** | overloaded | ORG ORG-10: "four statuses for one unlocked, one-member league." SKEP: "'The Pro has the list' reads like a phrase from a game I wasn't taught. Which list?" NOV N-10: "Complete · rosters locked" over two empty squads. | League phases setup → forming → draft → live; each surface derives its own label. "The Pro has the list" (`:3416`) = the Pro controls the draw. | Yes. | One phase label computed once. "Casey draws the squads at first tee." |
| **Staged / "1 golfer staged"** | **internal** (survived D97) | ORG: "joined but not locked? Never defined." | Members joined before the draw. D97 deleted the staged machinery; the word survived at `:12024` (and the `staged` variable's ghost at `:15218` is the lock bug). | Yes. | "1 golfer in." |
| **The pool / in the pool / seats open / 3 SEATS OPEN** | ambiguous | ORG ORG-20: "reads as a capacity of 4 for a league meant for 7." SKEP: "the pool = undrafted players." | Pool = undrawn members; "seats open" = shortfall to the four-player minimum (D58). | Yes — "seats" implies a cap. | "1 in · need 3 more to tee off (4 minimum)". |
| **The hat / THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW** | internal | CAS: "dead end with developer language." COMP: "confusing when shown to a player as an editable screen." | §15 blind draw. | Mild; "server-side" is engineering. | "Squads are drawn at random — nobody picks." |
| **Blind draw / Assign / Pro assign** | leagues | Clear (NOV, ORG, SKEP, CAS). | §15. | No. | Keep. |
| **Minimum four to tee off** | leagues | NOV N-06: revealed on the last step, then not enforced. | §8 min 4 players. | Placement, not wording. | State it on step 1. |
| **Competitiveness — pick once, argue never / Preset · Casual / Standard / Cutthroat / PRESET Standard** | leagues | JOIN J-07: "PRESET Standard appears on the consent sheet, bylaws and wizard and is defined nowhere." SKEP: "a rules template." IOS: "STANDARD RULES — a default ruleset I can't read." | §8 preset bundles; `PRESET_SUMMARY` (`:7208`) has one-line definitions, shown only inside the wizard. | Yes outside the wizard. | Show the summary sentence wherever "Standard" appears; make it tappable to the rules. |
| **95% hcp / Handicap allowance 95%** | golf · **spec-retired** | Every tester: "undefined" / "never applied visibly" / NOV "does an 18.2 play as 17.3?" / ORG "I cannot reproduce the number by hand" / COMP "the live strokes looked like 100% and the season preview used the raw 6.4". | §2.1 Playing Index = Index × allowance; D2 never-shown; D8/D48 retired the dial. Shown twice (`:3250`, `:12090`); applied at 95% by `v_rounds_ranked`; preview (`:6315`) and unranked receipts at 100%. iOS admits it (`PostRoundScreen.swift:406`). | **Yes** — a retired dial is advertised, and the number shown is not the number that scores. | Per D2/D48 remove "95%" from card and bylaws. In the receipt show it working: "Your number 14.2 · plays as 13.5 (95%)". Make the preview use the league's allowance. |
| **GHIN rounds / honor scores / verified + attested / VERIFICATION Attested / rated tees / receipts required** | leagues · **spec-retired** (D13 → Vouch) | NOV N-11: "Standard = 'GHIN rounds' on the card, 'Attested' in the review; attested is defined only on the live-round screen." ORG: "as the Pro I cannot tell my friends what verification rule we're under." SKEP: "never asked of me." OBS: "someone vouches for your scores?" | §6 tiers Honor / Attested / GHIN-verified; **D13: "Vouch" is the only user-facing word.** Never said (`:3076`, `:3255`, `:9316`: attested / auto-attested / ✓ ATTESTED). "GHIN rounds" is enforced nowhere. "Receipts required" collides with §16's receipts. | **Yes** — five words, one concept, one of them false. | One word (vouched), one sentence on the preset card: "Standard — honor scores; rounds scored together are vouched automatically." Delete "GHIN rounds". |
| **Use these defaults → / Customize** | ambiguous | ORG ORG-36: "'Use these defaults' means 'Next'." NOV N-02: a $75 buy-in hides behind Customize. | Button advances; defaults are the preset's. | Label wrong in the safe direction; the hidden money is the real cost. | "Next →"; buy-in above the fold. |
| **Teams / Solo / 2 Squads / +10 head start / Cut line after 2nd** | fantasy | ORG: "+10 of what? I still don't know how a round becomes points." NOV: "can't picture 'top seeds only' for a 3-person league." | §8/§14.3: at 2 squads both reach the Final, leader +10; 3+ squads cut after 2nd. | Yes — "head start" without a points model yet. | Move the scoring sheet before the Teams dial, or say "+10 points". |

### 3.1.D Scoring a round

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Index / handicap index / your number / your own number / number that day / YOUR INDEX 14.2 / 0 OF 3 · building** | golf · overloaded | JOIN: "three words used interchangeably." ORG ORG-16: "14.2 on Members/You/post form; '0 OF 3 — building' on Home. Two truths one screen apart." COMP: "which number does the league use — my real 6.4 or the app's 3-round number? Alarming." CAS: "'your own number' = my score?" | App-computed WHS-lite index (§5; establishes at 3 rounds). A typed value is a **starter**. `index_at_post` = the snapshot the round was scored against ("your number that day", `:11516`). D1 chose "your number" as the display word. | Yes — three names, two states, and the state chip disagrees with the value. | One label, one state: "Index 14.2 (starter · 0 of 3 rounds)". "Number that day" → "your index when you posted". |
| **Starter / building / EST 18.0 IDX / estimated 18** | invented | COMP/SKEP/JOIN: "a manual index used until 3 rounds." CAS A21: "a $5 match decided by a silent default of 18." | Starter = seeded manual index; live guests/indexless players default to 18. | Mild; the estimate is silent. | "No index yet — using 18, tap to change." |
| **Differential / DIFFERENTIAL / Diff 17.8 / "91 · 19.7" (unlabeled)** | golf (WHS) | ORG/COMP/NOV/JOIN: clear from the formula. CAS: "some course-adjusted score with 113 in it." SKEP SK-11: "91 · 19.7 unlabeled on Recent rounds." OBS: "Diff 17.8 on the board — undefined." | §2.1 WHS differential. D2: never-shown outside receipts — yet board rows print "Diff 17.8" and You prints it unlabeled. | Yes for casuals; a D2 violation. | Keep in receipts with the formula (it works); drop from board rows; label it on You. |
| **vs your index / VS YOUR INDEX / Against your number / -1.7 / +5.0 / Avg vs index / Best vs index -3.7 · Career best** | **golf-different (sign)** | All seven web testers flagged the sign (see R3). OBS also: Home "Beat your number by 3.3" vs receipt "+2.6 · 9 PTS" for one round. | §2.1 PvI; positive = beat your number. **D1: display as "beat your number by 1.4" / "1.7 over your number"** — the form (`:6339`), receipt (`:11519`), member receipts, You and standings print bare signed numbers; only the posted card uses `vsPhrase` (`:5710`). | **Yes** — the core loop's verdict is read backwards, and one round gets three phrasings. | D1 everywhere: "1.7 over your number" / "beat your number by 5.0". Compact fallback: "−1.7 worse" / "+5.0 better". Never "vs index" with a bare sign. |
| **Point bands** — "Torched it · Beat your number · Played to it · A little loose · Posted anyway" (sheet) vs "Beat your index by 3+ · Beat it by 1–3 · Within a stroke either way · Over by 1–3 · Rough day, posted anyway" (form) vs "A little loose, still cash in the bank" / "Sandbagger alert" (preview) vs "A LITTLE LOOSE / POSTED ANYWAY" (receipt) | invented · three label sets | NOV N-37: "three label sets for one band." SKEP SK-05: "band edges overlap — 'by 3+' and 'by 1–3' both contain 3." Otherwise the best-understood mechanic. | §2.2 — one name set in the spec (`pointsFor`, `:5693`). | Mildly — the concept lands; the labels wobble. | One label set (the spec's), non-overlapping edges ("3.0 or better", "1.0 to 2.9"). |
| **Cup points / League points / LEAGUE POINTS THIS ROUND / pts** | invented | Clear — and the preview promised 5–12 that landed as 0 pre-season for every tester who posted. | §2.2 cup points; the form previews them regardless of season state. | The noun is fine; the promise is false before first tee. | "Season points"; before first tee replace the preview with "Season starts Sep 5 — this round builds your index." |
| **Counting cap / Best 4 / mo / counting rounds / counter / bumped** | fantasy · **D51 forbade "counting cap"** | Clear after the (i). JOIN: "counter — a round that counts toward the cap?" (yes). OBS: "Bumped — explained inline, fine." | §3.1. D51: "never say 'counting cap' — say 'your best four'." The bylaws row still reads "COUNTING CAP" (`:12092`). | Mild — the (i) is good; the bylaws label breaks D51. | "Best 4 a month count" everywhere; "counter" → "counting round". Keep "bumped". |
| **Participation floor / floor / AUG FLOOR 1/2 · 1 MORE · 2D / −5 sqd pts / round short / no floor to clear** | fantasy (a "floor" is a ceiling word) | JOIN J-08: "penalty explained three different ways." OBS: "what a floor is and what missing it costs — assumed." IOS: "a monthly minimum that isn't applied in August." ORG: shown to a user with no league (ORG-23). | §3.2 minimum rounds per month; −5 squad points per round short. "sqd" (`:12038`) appears in solo leagues too (OBS). | Yes — "floor" is not a golf word and is never defined on Home where it is met. | "Monthly minimum · 2 rounds" with the penalty in a sentence; spell out "squad"; hide in solo leagues. |
| **Short months are waived / Partial month · floors waived** | invented | NOV/SKEP/ORG: "'short month' undefined — a month with fewer days? a partial month?" | §14.0: floors waived in partial edge months. | Yes — "short" is the wrong adjective. | "A partial first or last month has no minimum." |
| **Month closes / MONTH CLOSES in 2 days / July closed — Ledger posted** | leagues | OBS: "what closes? what happens?" SKEP/COMP: "end-of-month tally moment — wrong month shown (pre-season)." CAS: "I need 2 rounds in the next 2 days." | §14.2: on the 1st, floors assessed into the ledger, a board post, a snapshot. | Yes — "closes" without "and then what"; shown before the season exists. | "August's rounds lock on Sep 1 — post 1 more to hit your minimum." Suppress before first tee. |
| **Bye / season bye / One Pro-approved bye month** | fantasy · **contradicts D14** | NOV: "'Pro-approved' in one place, 'automatic' in another." ORG: "a new mechanic that appears only here." CAS/SKEP/JOIN: "first missed floor is forgiven, apparently." | §3.2 grace; D14 made the bye auto-apply. The wizard (i) still says "Pro-approved" (`:3318`). | Yes — two grant mechanisms on screen; only one is real. | Fix the (i): "Your first missed month is forgiven automatically." |
| **R (column) / Avg vs index / Δ WK / WK 1 / TREND / snapshot / Week closes Sun · 1d / SEASON DATE** | leagues · abbreviations | COMP/SKEP: "R — rounds, probably." OBS: "Δ Wk +10 though my last round was two weeks earlier." NOV N-21: "the season starts Saturday, weeks close Sunday — so week 1 is one day long?" IOS: "why are Sundays 'season dates'?" | R = rounds. Δ WK = points since the last Sunday snapshot. Two "weeks": §14.0 v1.1 weeks from the first-tee weekday (D108) vs Sunday-only snapshots (D81). | Yes — unlabeled column, two definitions of a week. | "Rounds"; "Since Sunday"; legend "standings snapshot (Sundays)". Reconcile the two weeks. |
| **Receipt** | internal (§16 word) | Testers used it on their own; the UI never titles the sheet. ORG/COMP: "the show-its-work moment mostly works." | §16; D5 promoted to UI. | No — the sheet is good; it lacks the points figure and a season-status line. | Title it "How this round scored"; add points and "counts in The Papago Grind: no (starts Sep 5)". |

### 3.1.E The endgame and standings vocabulary

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Cup Final · Final 4 weeks · scored fresh / FINISH · Cup Final / How it ends** | invented · fantasy (playoff) | **8 of 8 confused.** COMP: "'scored fresh' unknown. Do the first 13 weeks matter at all?" OBS: "I can't tell you how the winner is decided." SKEP: "re-scored from zero(?)". ORG: "what is a seed?" NOV: "how many seeds? what do non-seeds do?" | §14.0/§14.3: last four weeks from `ends_on − 27`; seeds lock; finalists' points restart at 0 (+head start); ladder tiebreak; non-finalists keep the individual races. D4 named it "unforeshadowed"; D105 says the race surface still doesn't exist. | **Yes** — the flagship mechanic is one bylaw row and a wizard (i) nobody opens. | One sentence, everywhere the term appears: "The Cup Final is the last four weeks. Points reset to zero (the season leader starts +10) and the squad with the most points in those four weeks takes the cup." |
| **Points table (endgame)** | fantasy | Clear (NOV, ORG, COMP). | The alternative: the season leader wins, no reset. | No. | "Season standings decide it". |
| **Seed / top seeds / TOP SEED · +10 / cup seed / has locked a cup seed** | fantasy (playoff) | ORG: "ranking entering the Final (never defined)." NOV: "meaningless with no data." OBS: "LOCKED — a guaranteed place in a later 'cup'?" | §14.3 finalists; D24's magic-number engine. | Yes — playoff jargon on a beer-league standings page. | "In the Final ✓" / "Season leader starts the Final +10". |
| **LOCKED** | ambiguous | OBS: "my place in the standings can't change?" IOS: "both rows carry it, so it cannot distinguish us." | D24 clinched seat. In every 2-player league always true → vacuous. | Yes — "locked" already means bylaws and rosters elsewhere. | "Final ✓"; hide when K ≥ n. |
| **EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS / TOP 1 ADVANCE / cut line** | fantasy | NOV: "I do not know what any of these mean." IOS: "advance to what? seats where?" OBS: "vacuous with two players." | D24/D26 cutline caption (`:4478–4480`). | Yes. | "Both squads reach the Cup Final." |
| **PROJECTED UNDER A GENEROUS CEILING** | **internal** | NOV: "What ceiling?" (nobody could parse it). | D24's honesty rule printed verbatim (`:4479`). | Yes — a design-doc sentence on screen. | Delete, or "projection is conservative". |
| **SEASON RACE · THE CLIMB** | invented (D26) | OBS: "the ranked race list." IOS: "the standings table — confusing." | D26/D31 the you-centered ladder. | Mild — a brand flourish costing a beat. | "The race" or "Standings". |
| **— HELD / ▲ UP 2 / ▼ DOWN 1** | ambiguous | OBS: "position unchanged since last week? or a hold on me?" IOS: "my position didn't move." | Rank unchanged vs last Sunday's snapshot (`:10185`). | Yes — "held" alone; not tappable. | "— same as last week". |
| **Points King / Most Improved / Iron Man / champ / 2nd / king** | fantasy (fun) | Clear after the footnote. JOIN: "only Points King's 15% is stated." COMP: "'king' — confusing abbreviation." | §4; Points King pays 15%. | Slight. | Keep the names; expand "king" in the split. |
| **Display case / hardware / silverware / The record / Lifetime / Cups & events · 1 · Played in / FORM ●●●●● / Diff 9.3** | invented (register) | NOV/JOIN/SKEP: trophies. IOS: "three trophy sections, overlap unclear." ORG/NOV/SKEP: "Cups & events 1 — I have played in zero." All: "FORM dots — a lone grey dot, no label." | Display case = milestone badges; the record = trophies (D46); Lifetime = career totals; Cups & events = leagues + events **joined** (`:2886`); FORM = last 5 rounds by band (`:11326`). | Yes — three overlapping shelves and a stat that counts a league that hasn't started. | "Milestones / Trophies / Career"; "Leagues & events joined"; label FORM "last 5 rounds" with a legend. |

### 3.1.F Money

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Pot / pot sheet / the tab / the books / on the books / ledger / Season stakes / ON THE LINE** | overloaded | JOIN: "four names." CAS: "the $250 the app tracks but does not hold." JOIN J-10: "how to pay, to whom, by when — never stated." | §7 track never hold; D39 ledger language; D47 "books = money"; D106 owed vs collected. | Partly — the model is clear, the nouns multiply. | "The pot" only. "You owe Casey $50 — he ticks you off here." |
| **Buy-in** | leagues | Clear. The hidden $75 default is placement, not wording. | §7. | No. | Keep; surface it. |
| **Cup champs $150 / Runner-up / Points king tiles** | ambiguous | CAS: "is $150 what I win?" SKEP/ORG: "champs plural — a team; how a squad splits it is never stated; tiles sum to $251." | 60/25/15 to the winning squad / runner-up / Points King; per-member split unstated. | Yes. | "$150 to the winning squad (split evenly)". |
| **Stake / Post a stake / "pride, on the books — never money"** vs **Stake per side · $0 = bragging rights / DOLLARS PER SKIN / BANK UNIT** | **overloaded — opposite senses** | NOV: "'stake' usually means money — mine was wrong: stakes are non-money bragging bets." ORG ORG-24: "the Pot tab's stake explicitly cannot be money while the side game's stake explicitly is." COMP/NOV: "the $60 skins settlement is not on the books anywhere." | D64 forfeits = named non-money stakes ("must be unmistakably NOT money"). Live games: §13.2 dollar stakes settled between players. "On the books" for pride bets breaks D47's "books = money". | **Yes** — the same word means money on one screen and never-money on the next. | Pride bets → "Bets for pride" / "Forfeits". Side games → "$ per side / per skin". Say once on the Pot tab: "Side-game cash settles between you and isn't tracked here." |
| **Settle up / settlement / round settlement · live** | golf (fine) | Clear. | Netted who-pays-whom after a live game (D77/D78). | No. | Keep. |

### 3.1.G Playing: posting, live, planning

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **The ⊕ / Post (tab) / + / Play now / LIVE / Live round / Put a round on the tee sheet** | ambiguous (five doors) | NOV: "the orientation calls it 'The ⊕', the tab bar says 'Post' — two names." IOS 2.6: "five 'do a round' entry points, none explained." CAS: "posting is easy once you find the ⊕." | D110: the ⊕ opens three doors (Play now · Post a round · Plan a tee time). | Yes — one concept, three tenses, five labels. | One verb per tense: "Post a score · Play live · Plan a round"; call the ⊕ "Post" in the orientation. |
| **Card** — golfer card · your card · counts on your card · YOUR CARD (18/9) · Scan the card · every complete card posts · Share the card · settlement card · Post card · Tour Card | **overloaded (five senses)** — D47 said never unqualified | CAS: "'counts on your card' = profile/record — but also the scorecard ('Scan the card')." SKEP SK-34: "five different things." NOV N-26: "'COUNTS ON YOUR CARD' reads as 'counted' — it meant NOT the season." IOS: "scorecard on Post/Live, profile on Settings." | Golfer card = profile; "your card" = your record; YOUR CARD 18/9 = the scorecard being entered; recap/settlement/Tour cards = artifacts. `:6588` shows the confirmation has two states — the app knows a round is out of season and still never says so. | **Yes** — and the worst instance is the post-round verdict. | Profile → "your card" only on You; record → "your record"; scorecard → "scorecard". Confirmation: "On your record · season starts Sep 5" / "6 pts to Squad 1". |
| **Tee sheet / on the sheet / 1 ON THE SHEET · SYNCED / NEXT · Open / PLAN A ROUND** | **golf-different · overloaded** | NOV: "I know this phrase from the starter's desk; here it seems to mean rounds I've announced — and live rounds also count." NOV N-20: "'NEXT · Open' read for twenty minutes as 'the next league round is open'." IOS: "used five times on one screen, never defined." | Two senses: (1) the shared calendar of declared rounds (D47); (2) the live scorer (D86 invites, D107 "the tee sheet is the free door"). | Yes — a real-golf noun covering both a calendar and a live scorecard. | Calendar → "Schedule / Planned rounds"; live → "live round". "NEXT · Open" → "Next round · none planned". |
| **Live round / Play now / shared pencil / Group phones / Finish round & post to season / Scrap this round** | invented (register) | Clear (COMP, NOV, ORG, OBS). CAS: "'Finish — no complete member card to post' vs 'This one was casual — post nothing' — I cannot tell the difference." | §13; D85 sync; D87 the pencil. | Mostly no; the finish buttons are. | Keep; one primary finish button. |
| **The stepper / Standard par-72 card / Enter the pars / OFF THE SCORECARD** | **internal** | IOS: "a UI widget name leaking into copy; why would I enter the pars?" NOV/ORG: "first tap lands on par — unannounced." | §13.1: stepper opens on par; manual pars are the fallback. | Yes — "stepper" is a widget. | "Tap + to start at par"; "Set the pars (if the course isn't found)". |
| **SI / SI 15 / stroke index** | golf (UK) | CAS: "SI — stroke index? Undefined." ORG: "jargon for most weekend golfers." | Hole handicap ranking. | Yes for US casuals. | "HCP 15 (hole handicap)". |
| **Strokes off the low man / 0 STK / Casey gets 9 — the 9 hardest holes** | golf idiom | CAS: guessed right. NOV: "0 STK for two 18-indexes — took me a minute." COMP: praised. | §13.2 net strokes. | Mild; the sentence is good, the abbreviation is not. | "0 strokes"; keep the sentence. |
| **Just score / Match play / Wolf / Skins / Sunningdale Rules / net best ball / 2 UP THRU 3 / riding / 2 SKINS DIED CARRIED / bank a unit** | golf (money games) | NOV/CAS: "Wolf is never explained." ORG: "Sunningdale — no idea, no (i)." COMP: "'2 SKINS DIED CARRIED' is confusing wording." OBS: "Sunningdale / bank / 6 units — all undefined on the board." | §13.2 + D74. Wolf's full blurb exists (`:8846`) once four are seated. | Yes for the two least-common games and the tally words. | An (i) with a three-line how-to per game; "riding" → "carried over"; "bank a unit" → "bank a point". |
| **Attested / auto-attested / ✓ ATTESTED / PLAYED WITH THE GROUP** | see 3.1.C | (see verification row) | D13 → Vouch. | Yes. | "Vouched by the group". |
| **Guest / claim / claim link / recap link** | invented | Clear after the explainer (ORG, NOV, OBS, SKEP). JOIN: "claims — unknown, three kinds of links." | §13.3 guests; a claim link hands them their round. | Mild — "claim" is legal-sounding. | Keep "guest"; "claim link" → "their round link". |
| **Invite code / I have an invite code / LEAGUE CODE / Invite code: THEPTCQ5 / Code · / invite link / league code** | overloaded — D47 said one noun | JOIN J-15: "the same code is 'invite code' (button), 'LEAGUE CODE' (field), 'Invite code:' (toast), 'Code ·' (chip)." ORG: "the button says link; it gives a code." | One 8-char `leagues.code`; the link is `/?join=CODE`. D47: "one code noun: league code." | Yes — four labels, and "link" buttons that emit a code. | "League code" everywhere; show the URL as text. |

### 3.1.H Identity and social

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **Golfer card / NAME ON THE CARD** | invented | Clear (JOIN, ORG). | The profile. | No (until "card" multiplies). | Keep on the profile only. |
| **Handle · moves once / 60 days** | social-app | Clear; IOS: "odd phrasing." ORG/NOV: it "silently changed itself" during onboarding. | `@handle`, changeable once per 60 days. | Phrasing only. | "can change once every 60 days". |
| **Ball marker / marker / Marker here / NO. 2 / THE SAGUARO … THE THISTLE** | golf-different | ORG: "a cute name for avatar but nothing says that." JOIN J-17: "all five members display the same cactus; 'Marker here' unexplained." IOS: "'NO. 2' next to a person literally in 2nd place reads as rank." | D36/D59: the avatar glyph (famous holes); per-league override via "Marker here" (`:17167`). | Yes — an avatar called a marker, named after holes casuals don't know, one of which is a number. | "Your marker — the icon that stands in for your photo"; "Marker here" → "Use a different marker in this league"; rename "No. 2". |
| **GHIN / add your GHIN / "that's identity, not your number"** | golf (US) | NOV: "I read it three times." CAS: "I don't know what GHIN is." | Optional reference field, never verified. | Yes on the card. | Reuse the settings sentence on the card. |
| **Findable by · All / crew-policed** | invented | CAS: "the league sees manual index changes." ORG ORG-15: "Findable by All is the default; strangers appeared in my search." | Discoverability setting; manual index changes post to the board. | Mild. | "Your league sees the change." |
| **🔥 heater / + More reactions / ⚑** | invented (D25) | OBS: "heater — a reaction." SKEP SK-19: "the ⚑ next to 🔥 is 'Report this post' — one slip and I've reported my buddy's trash talk." | D25 six-reaction vocabulary; ⚑ = report. | The flag. | Label the flag or move it into a menu. |
| **"Moments, reveals, and month closes always come through"** | **internal** | SKEP/ORG: "unknown notification categories." | Server post kinds: moments = milestone posts; reveals = the squad-draw reveal; month closes = §14.2 (D104). | Yes — schema kinds as user copy. | "Milestones, squad draws and month closes always come through." |
| **Founder's desk / Field note** | internal (owner-only) | OBS: admin tools. | D102 owner tooling. | Persona-specific. | Fine. |

### 3.1.I Events

| Term | Class | What users thought | Actual meaning | Confusing? | Better alternative |
|---|---|---|---|---|---|
| **The Ryder / Two teams · weekly vs-index duels · first to the clinch** | golf (Ryder Cup) · "duel" is D12 schema-only | IOS: "'vs-index', 'clinch' undefined." CAS A33: "jargon; no relation to my league explained." | gameplay-modes §4: two teams; weekly one-on-one matchups, best round vs index wins the point; first to a majority. | Yes — three undefined tokens in nine words. | "Two teams. Each week everyone gets a one-on-one matchup scored against their own handicap. First team to a majority wins." |
| **A Major / best card takes the jug / Bracket · seeded / LIVE / SOON** | golf | CAS: "one line each." IOS: "LIVE — available, or currently running? ambiguous with live round." | D42–D46 the Major; Bracket D109-parked. "LIVE" = available. | "LIVE" collides with live scoring. | "Available now" / "Coming". |
| **"Major" (quoted, on the schedule row) / you lead 1–0 · YOU'RE IN** | ambiguous | OBS/IOS: "a nickname for the round? head-to-head vs Galen in what?" | The plan's free-text note; the faceted rivalry record; YOU'RE IN = accepted (D17/D19). | Yes — an unlabeled note in quotes beside an unlabeled record. | Render the note in prose; "Head-to-head: you lead 1–0". |
| **"Every event mints a trophy for your display case"** | internal | IOS: "'mints' is odd." | Awards a trophy. | Mild. | "Every event awards a trophy." |

## 3.2 Where the UI contradicts its own decision log

Not judgement calls — each is a shipped string a logged decision already forbade. They belong at the top of any copy sweep because the debate is over.

| Decision | What it ruled | What ships | Evidence |
|---|---|---|---|
| **D1 / D2** (2026-07-15) | Display PvI as "beat your number by 1.4"; differential / playing index / allowance never shown outside receipts | Bare signed "-1.7 VS YOUR INDEX" on form, receipt, member receipts, You, standings; "Diff 17.8" on board rows; "HANDICAP ALLOWANCE 95%" bylaw row | `org/68-round-filled.jpg`, `obs/10-my-row.jpg`, `obs/19-sub-Board.jpg`; `:6339`, `:11519`, `:12090` |
| **D8 / D48** | Allowance dial retired; presets never mention it | "95% hcp" on every preset card; "HANDICAP ALLOWANCE 95%" bylaw row | `org/18-wizard-step2.jpg`, `org/30-wizard-step3.jpg`; `:3250`, `:12090` |
| **D12** | "Duel" and "event" are schema/doc words only | "Start an event", "Cups & events", "Leagues vs events", "vs-index duels" | Home, You tab, `EventPickerSheet.swift:26` |
| **D13** | "Vouch" is the only user-facing word for attestation | "VERIFICATION Attested", "auto-attested", "✓ ATTESTED", "verified + attested" | `:3076`, `:3255`, `:9316`; `comp/58-live-posted.jpg`; "vouch" ×0 |
| **D14** | The bye auto-applies; the Pro no longer adjudicates | Wizard (i): "One Pro-approved bye month per season" | `:3318` |
| **D40** | Invites open at lock; a member never sees the Pro's configuration tool | "Lock opens the invite link" while the code chip exists pre-lock; every member's hero routes to the wizard (D96 regression) | `org/37-league-room-forming.jpg`; `:10098–10112`; `join/39-U-lock-it-in.jpg` |
| **D47** | "card" never unqualified; one code noun ("league code"); books = money | "counts on your card" / "Scan the card" / "Post card"; invite code / LEAGUE CODE / Invite code: / Code ·; "pride, on the books — never money" | `join/11-J-after-take-me-in.jpg`, `org/94-post-stake.jpg` |
| **D49** | Provisional rounds score normally, **badged** until established | No "provisional" badge exists ("provisional" ×0 in `index.html`); the receipt reads "27.8 vs 27.8 · +0.0" | `cas/56-G04-round-receipt.jpg` |
| **D51** | Never say "counting cap" — say "your best four"; a stake line on the post screen | "COUNTING CAP · Best 4 / mo" bylaw row; wizard label; no stake line anywhere | `:12092` |
| **D97** | Staged-invitee machinery deleted | "1 golfer staged —" (`:12024`); `staged.length` in `lockBylaws()` (`:15218`) — the lock bug | ORG, NOV lock failures |
| **§15 / D105** | Captains are an optional label; the captain playoff is gone | "CAPT. —" column; "LIVE NOW — CAPTAINS READY" phase label | `nov/36-clubhouse-full.jpg`, `org/45-league-tab.jpg`; `:12231` |
| **D24** (design intent) | The honesty rule is an engine property | "PROJECTED UNDER A GENEROUS CEILING" printed on the standings | `:4479` |
| **Guide** (`Cup-Season-Guide.md:106`) | "add golfers … or invite by email" | No email invite path exists — "No golfers found. Invite links still work for everyone else." | `org/42-add-golfers-email.jpg`; ORG ORG-02, NOV N-05 |

## 3.3 Terms testers met that the product never defines anywhere (not even four taps deep)

seed · scored fresh (as a mechanic) · short month · HELD · LOCKED · contenders / seats · generous ceiling · the climb · sqd · CAPT. · R · Δ WK · SEASON DATE · staged · the pool · seats open · "The Pro has the list" · Pro Shop (until tab six) · the pilot · attested (until the live screen) · GHIN rounds (never true) · net best ball · Wolf (short card) · Sunningdale Rules (no (i)) · riding · bank a unit · SI · EST 18.0 IDX · the stepper · Moments / reveals · FORM dots · Cups & events · Marker here · No. 2 · bylaws §4 · Preset Standard (outside the wizard) · counter · vs-index duels · the clinch · mints · "Major" (the note) · you lead 1–0 · provisional (the state exists; the word does not).

## 3.4 The ten terms that most damage comprehension — ranked

Ranked by (a) how many testers hit it, (b) whether it sits on the core loop (post → points → standings → win), (c) whether the misreading is *confident* — a wrong model is worse than a blank.

1. **The endgame cluster — Cup / Cup Final / "scored fresh" / seed / LOCKED / advance / seats.** 8 of 8 could not say how a season is won; the product's name is undefined; the flagship mechanic is one bylaw row behind a collapsed disclosure and a wizard (i). D4 named this on 2026-07-15; D105 (2026-08-28) says the race surface still doesn't exist. Every "why would I start another season" answer (OBS: 4/10) traces here.
2. **"vs your index" as a bare signed number.** 7 of 7 web testers read the sign backwards or watched one round get three verdicts (−9.8 / 9.8 over / +0.0). D1 already ruled the phrase form; the form, receipt and tables ignore it. This is the verdict on every posted round.
3. **"Card" — and specifically "COUNTS ON YOUR CARD."** Five senses; the one that matters is the post-round confirmation every tester read as "counted" when it meant "not in the season" (`:6588` proves the app knew). D47 forbade the unqualified word.
4. **"The Pro" (and "Pro Shop").** Every persona paused on it; three said "a club professional." D15 chose the collision; the testers paid for it. "Commissioner" costs nothing.
5. **"Handicap allowance 95%."** Advertised on two screens, applied on none the user can see, and the preview/receipt math runs at 100% while the league scores at 95%. D2/D8/D48 said hide it; it is shown *and* unexplained — the worst of both.
6. **Squad / "sqd pts" / captain / four formation states.** A team noun met before it is defined (Home's floor sentence shows it to users with no league), stretched to a phase and a penalty unit, printed in solo leagues, with a captain column that references nothing.
7. **The verification set: GHIN rounds / honor / attested / verified / rated tees / receipts required.** One concept, five labels across three screens, D13's "Vouch" on none of them, and "GHIN rounds" describing a requirement that does not exist. The organizer cannot state the rule to friends (ORG).
8. **The monthly machinery: floor / short months / month closes / bye (Pro-approved vs automatic) / counting cap / counter.** The best-explained mechanic in the (i)s and the worst on Home, where "floor", "squad" and "month closes" appear to users with no league and no season, and the bye's grant mechanism contradicts D14.
9. **The money nouns: pot / pot sheet / the books / the tab / on the line / stake (pride) vs stake per side / Cup champs.** "Stake" means never-money on the Pot tab and money in a live game; "keeps the books" is true of the pot and false of the $60 skins settlement; nobody learns how a squad splits its 60%.
10. **Lock / locks at first tee / lock it in / forming / Squad formation / LIVE NOW — CAPTAINS READY.** Three lock moments, four phase labels, a false "lock opens the invite link", and a member Home whose biggest button is the Pro's lock. This is the vocabulary an organizer needs to relay to six friends, and ORG could not.

Runners-up, in order: **tee sheet** (calendar vs live scorer; "NEXT · Open") · **Δ WK / week / snapshot / SEASON DATE** (two definitions of a week) · **invite code ×4** (D47) · **ball marker / No. 2 / Marker here** · **bylaws §4** · **HELD** · **Moments / reveals** · **the pilot** · **Wolf / Sunningdale / riding / bank a unit** · **display case / record / Cups & events**.

---

# Part 4 — Confusion debt

Everything the product assumes the user already knows, consolidated from the eight reports' "confusion debt" sections (CAS 20 items, COMP 15, NOV 20, SKEP 16, ORG 20, JOIN 15, OBS 20, IOS 16 — 142 raw, 58 consolidated), grouped by the journey in which the debt is first called. **Raised by** lists the personas who wrote it down unprompted. **Where the product says it** is the nearest in-app definition, or "nowhere".

## 4.A Journey A — the door and the invite landing

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| A1 | That "league", "season", "cup" and "event" are four different nouns with different lifetimes. | ORG, NOV, JOIN, SKEP, IOS | Orientation card (after sign-in); "Leagues vs events" at the bottom of You |
| A2 | What "the cup" is — a trophy, a pot, a final, or a count of leagues. | all 8 | Nowhere, in a sentence |
| A3 | That this is a TEAM game with two randomly drawn squads. | SKEP, CAS, NOV, JOIN, ORG | Wizard Customize (i) (organizer only); collapsed bylaws (member) |
| A4 | That there is a $50 (default $75) buy-in — before you sign up. | SKEP, JOIN, NOV, ORG | Covenant sheet, after email + card + orientation |
| A5 | What a point is, and that rounds become points against your own handicap rather than par. | CAS, IOS, SKEP | Welcome sheet (joiners) / "How scoring works" (4 taps) |
| A6 | That "Rally your crew" means a league, while "buddies" is a separate, points-free relationship. | NOV, SKEP, JOIN | "Buddies, invites and claims" explainer on You |
| A7 | What "real rounds" implies about verification (GHIN? attested? photos?). | COMP, SKEP | Live screen only |
| A8 | That `v23 · __CS_VERSION__` is a build placeholder, not broken software. | SKEP, ORG, JOIN, NOV | Nowhere (locally unstamped; prod is stamped — the audit ran a local serve of the prod build) |
| A9 | That the invite link and "I have an invite code" are the same code, and that "Enter your email and you're in" is followed by four more steps. | JOIN, ORG, CAS, COMP | Nowhere |

## 4.B Journey B — sign-up and onboarding

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| B1 | What a handicap index is, that it can be "built", and that a typed one is a starter the app will overwrite after 3 rounds. | CAS, ORG, COMP, JOIN | Golfer card help (partly); Card & settings |
| B2 | What GHIN is, and that "that's identity, not your number" means it is never verified. | CAS, NOV, SKEP | Settings copy (clearer than the card) |
| B3 | That a "ball marker" is an avatar, that the famous-hole names are decorative, and that "No. 2" is not a rank. | ORG, JOIN, CAS, IOS | Nowhere |
| B4 | That "THREE THINGS TO KNOW" is four, and that the orientation's "table, board, pot, the ⊕" are nouns you will need. | CAS, NOV, ORG | The orientation itself, undefined |
| B5 | That the handle can silently change itself during onboarding and moves once per 60 days. | ORG, NOV | Settings |
| B6 | That "Findable by: All" is on by default and lets strangers add you. | ORG, CAS | Settings |

## 4.C Journey C — creating a league (the organizer)

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| C1 | What a round is worth (points) — needed before the wizard's Teams dial, shown after it. | ORG, NOV | "How scoring works", found post-lock |
| C2 | What "lock" freezes and when (three answers), and that "locks at first tee" does not freeze the endgame. | ORG, NOV, JOIN, SKEP, CAS | Nowhere consistent |
| C3 | Why 95% / 90% / 100% allowances exist and what they do to a round. | NOV, ORG, COMP, SKEP, JOIN, OBS | Nowhere (the row is a number) |
| C4 | What "GHIN rounds", "attested", "rated tees", "receipts required" require of friends at post time — and that "GHIN rounds" requires nothing. | NOV, ORG, SKEP, COMP | Live screen (attested only) |
| C5 | That "Minimum four to tee off" is a rule — revealed on the last step, then not enforced. | NOV, ORG | Step-3 footer |
| C6 | That the $75 default is behind "Customize", and that "Use these defaults" means "Next". | NOV, ORG | Nowhere |
| C7 | What "seeds", "+10 head start", "cut line after 2nd", "top seeds race fresh" mean for the Final. | ORG, NOV | Wizard (i), undefined terms |
| C8 | How uneven squads (3 v 4) are scored. | ORG | Nowhere |
| C9 | That the invite is a code, that friends must download the app and tap "I have an invite code", and what they will be told when they do. | ORG, NOV, JOIN, CAS | Nowhere (ORG found the join covenant by typing the URL) |
| C10 | That there is no email/SMS invite; friends must already be on the app. | NOV, ORG | Nowhere (the Guide says otherwise) |
| C11 | That you must lock before the share sheet opens — and that the code already exists before lock. | NOV, ORG | Contradictory copy |
| C12 | Who pays for "membership", when, and how much. | ORG, CAS, SKEP | Nowhere ("COMING AT LAUNCH") |
| C13 | That "Pro Shop" is a paid tier — three mentions before one definition. | NOV, ORG | Tab six |
| C14 | That the Pro's job includes approving byes (false since D14), collecting money, assigning squads, switching the endgame, ruling on disputes. | NOV, JOIN, COMP | Nowhere as a list |

## 4.C′ Joining (the invitee)

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| J1 | Who is in the league, who runs it, when it starts and ends — before the $50 button. | JOIN, COMP, CAS, SKEP | Clubhouse, after joining |
| J2 | What "PRESET Standard" means and what the other presets would have changed. | JOIN, SKEP, IOS | Wizard (organizer only) |
| J3 | That a league has a "Pro" and that you are not one — so "Lock it in", "Add golfers", "Share the invite link", "Turn off this link" and the buy-in checkboxes are not yours to press. | JOIN, CAS, COMP, SKEP | Nowhere; the member's Home says the opposite |
| J4 | What "squad" is, that there are two, and that you will be assigned by a draw someone else triggers. | JOIN, CAS, SKEP, COMP | Collapsed bylaws |
| J5 | Which of the three floor-penalty explanations is true, and that the first miss is forgiven. | JOIN, COMP, CAS | Scoring sheet (bye), Home (penalty), bylaws (abbreviation) |
| J6 | What "Cup Final · scored fresh" does to accumulated points. | all 8 | Nowhere |
| J7 | How and to whom to pay the $50, and that the "pot sheet" is a ledger the Pro edits. | JOIN, CAS, COMP, SKEP, ORG, OBS | Nowhere |
| J8 | That "Not now" on the covenant drops the invite and you must retype the code. | JOIN | Nowhere on screen |
| J9 | What to do next after joining ("wait for Sep 5, then post two a month"). | JOIN, CAS, COMP, SKEP | Nowhere — best guess from "7 days to first tee" |
| J10 | That "bylaws §4" is a document you cannot open. | JOIN, ORG, OBS | — |

## 4.D Journey D — the first round

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| D1 | That rounds posted before the season's first tee give 0 league points despite the form saying 5 / 6 / 12. | all 6 posters | Clubhouse kickoff card only; contradicted by Home and the form |
| D2 | That negative "vs index" is bad — the opposite of golf's minus-is-good. | ORG, NOV, JOIN, CAS, SKEP, OBS | Nowhere |
| D3 | That "beat by X" is measured on the differential, not strokes, and what a differential is (why 113 appears). | COMP, CAS, SKEP, ORG | Receipt formula (the what, not the why) |
| D4 | What course Rating and Slope are, that the tee choice supplies them, and that the placeholders "72.1 / 128" are not values. | CAS | Nowhere ("-79.0 vs your index" with them blank) |
| D5 | Whether the league scores against your real index or the app's 3-round number, and what happens on the switch. | COMP, ORG | Nowhere |
| D6 | That "card" means your record in "counts on your card" and the scorecard in "Scan the card". | CAS, SKEP, NOV, IOS | Nowhere |
| D7 | That the band names change between the sheet, the form, the preview and the receipt, and that "by 3+" and "by 1–3" do not overlap. | NOV, SKEP | — |
| D8 | That "Month closes in 2 days" and the floor bar refer to a calendar month that does not matter yet. | CAS, SKEP, COMP, OBS | Nowhere |
| D9 | That "THE BOARD · ROUNDS LAND HERE AUTOMATICALLY" excludes pre-season rounds. | CAS, SKEP, IOS | Nowhere |
| D10 | Why the second round is labelled "First round on the card" and the first became "Personal best"; that "Cups & events · 1 · Played in" counts a league that hasn't started. | CAS, ORG, NOV, SKEP | Nowhere |
| D11 | That the receipt has no points line pre-season, and no "counts for this league: no (starts Sep 5)". | ORG, COMP, JOIN | — |
| D12 | That "Share the card" needs a device share sheet, and "Share" means "download a PNG". | COMP, SKEP | Nowhere |
| D13 | That the install banner must be dismissed before the ⊕ works. | ORG | — |

## 4.L Live rounds and side games

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| L1 | How Wolf, Sunningdale Rules, net best ball, skins carry-over and "strokes off the low man" are played. | CAS, NOV, ORG, OBS, COMP | One-line blurbs; Wolf's full blurb once four are seated; Sunningdale nothing |
| L2 | That "SI" is a stroke index, which holes you get strokes on, and why. | CAS, ORG | Nowhere |
| L3 | That the app estimates a missing index as 18.0 — silently, for a $5 match. | CAS | Setup copy for guests only |
| L4 | That any league member can seat you in a live round and post an attested score to your card, with no notification. | CAS, COMP | Nowhere |
| L5 | That side games don't affect season points while the gross score does — and that it, too, is 0 pre-season. | CAS, NOV, ORG, COMP | Live paragraph (partly) |
| L6 | That side-game money is "settled between you" and never reaches the pot ledger; that "stakes" on the Pot tab are never money. | NOV, COMP, ORG | Live door / Pot tab, in opposite senses |
| L7 | That the first tap on the live stepper sets par, and what "the stepper" is. | NOV, ORG, IOS | Copy uses the widget name |
| L8 | What "attested" verification requires (a second phone? a tap? nothing?). | COMP, SKEP, JOIN, OBS | Live screen |
| L9 | That "Finish — no complete member card to post" and "This one was casual — post nothing" differ; that "Scrap this round" does nothing; that ⊕ → Play now resumes a round (the "Continue your round" banner does not appear — the live-resume query fails on every Home load). | CAS | Nowhere |
| L10 | That "riding", "bank a unit", "units", "2 SKINS DIED CARRIED" are tally words. | NOV, OBS, COMP | Nowhere |

## 4.E Journey E — mid-season: standings, clocks, board

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| E1 | What a "floor" is and what missing it costs; what "short months are waived" means. | OBS, IOS, NOV, SKEP, ORG | Home fine print (penalty); "short" undefined |
| E2 | What "HELD", "LOCKED", "cup seed", "contenders / seats", "advances", "generous ceiling", "the climb" mean. | OBS, IOS, NOV | Nowhere |
| E3 | What "R", "Δ WK", "FORM dots", "SEASON DATE", "TREND" encode. | COMP, SKEP, OBS, IOS | Nowhere |
| E4 | What a "week" is (a Sunday snapshot), that weeks, months and seasons are three different clocks, and why the season starts Saturday but weeks close Sunday. | NOV, OBS, IOS | Nowhere |
| E5 | What a "month close" does, and whether a rival's missing rounds will cost them. | OBS, CAS, SKEP | Board post after the fact |
| E6 | That Home shows one league only and how to switch; which league a pushed Board/Schedule screen belongs to. | OBS, IOS | — |
| E7 | That board dates are posting dates, not play dates; that the board runs oldest-first. | OBS | — |
| E8 | Squad vocabulary ("sqd pts", "squad race") in a league with no squads. | OBS | — |
| E9 | That "Schedule" leaves the Clubhouse for a separate calendar page. | OBS, CAS, COMP | — |
| E10 | What "the pilot", "Moments / reveals", "mints" mean in notifications and guides. | SKEP, ORG, IOS, NOV | Nowhere |

## 4.F Journey F — the finale

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| F1 | That the season ends in a fresh 4-week Cup Final, when it starts, and what a seed is. | all 8 | One bylaw row |
| F2 | Who plays the Final (both squads at 2-squad scale; top 2 otherwise) and what non-finalists do. | COMP, NOV, ORG, OBS | Organizer (i) only |
| F3 | That the leader carries +10, and 10 of what. | ORG, NOV, COMP | Organizer (i) only |
| F4 | How ties break — anywhere (standings, seeds, Points King, skins, match play). | COMP, OBS | Nowhere |
| F5 | That "EVERYONE ADVANCES" makes a two-player final structurally hollow. | OBS, IOS | Nowhere |
| F6 | What winning pays *me* — how a squad's 60% becomes a person's number; why the tiles sum to $51 on $50. | ORG, COMP, SKEP, CAS, JOIN | Nowhere |
| F7 | What the ceremony / settlement card / Trophy Room looks like, and that there will be one. | OBS | "the endgame settles it" |

## 4.G Journey G — next season, money and membership

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| G1 | How the pot gets collected, who chases it, and by when. | OBS, JOIN, CAS | Nowhere ($0 collected six weeks in) |
| G2 | Whether you will be asked to pay the app on top of the pot, and who pays. | CAS, ORG, SKEP | "COMING AT LAUNCH · THE PILOT RIDES FREE" |
| G3 | That "SEASON I" implies a Season II, and what "run it back" carries forward. | OBS | Nowhere |
| G4 | What an "event", "The Ryder", "A Major" are relative to your league; what "vs-index", "duels", "the clinch" mean. | CAS, OBS, IOS, ORG | Tile blurbs, undefined |

## 4.M Correcting mistakes, consent and disputes

| # | The product assumes you already know… | Raised by | Where the product says it |
|---|---|---|---|
| M1 | That a wrong score means delete and re-post — there is no edit — and that the ✕ on You › Recent rounds is the only way. | NOV, ORG, CAS, JOIN | The `confirm()` text |
| M2 | That deleting a round leaves its badges and "Played in" counts behind. | COMP, ORG | Nowhere |
| M3 | How to dispute a round someone else posted to your card. | CAS | Nowhere (D50 unbuilt) |
| M4 | That the ⚑ next to 🔥 is "report", not "flag as good". | SKEP | Nowhere |
| M5 | What happens if you join late, drop out, or the league is cancelled. | (none found it; all needed it) | "Cancel & delete this league" only |

## 4.X Cross-cutting: the golf and WHS vocabulary the product leans on without teaching

index · differential · rating · slope · 113 · playing index · allowance · stroke index (SI) · course handicap · net · attested · rated tees · GHIN · match-play margins (4&3) · skins carry · Wolf · Sunningdale · Nassau (absent) · net best ball · "strokes off the low man". Understood by COMP and ORG; partly by NOV, SKEP, JOIN, OBS; largely not by CAS ("What a 'differential' is and why 113 appears in a formula"; "What GHIN is"; "What Wolf, Sunningdale Rules, net best ball, skins carry-over and 'strokes off the low man' are"). The product's own stated audience is the everyday golfer (§17 "everyday golfer first"); the vocabulary assumes a club golfer.

---

# Appendix

## A. What to do with this — three moves, in cost order

1. **Copy sweep against §3.2** (a day): every row is a string replacement with a decision already behind it. Start with D1 (the sign), D47 (card, code), D13 (vouch), D14 (bye), D51 (best four), D48 (delete the 95%), D97 (staged — also the lock bug), §15 (captains).
2. **Define at first contact** (a design pass): the orientation screen and the join covenant are the two places every user passes; they currently introduce cup, table, board, pot, squad, the Pro, first tee and Cup Final without a sentence each. The scoring sheet is excellent and unreachable — link it from the wizard's step 2, the post form's band table, and the standings header; add "How it ends" and "Ties".
3. **Log the unlogged mechanics and resolve the four overloaded nouns as decisions** (talk first, rule 1): the pre-season window rule (no spec sentence, no D-entry); one season-state producer; cup (title vs points vs final vs count), stake (money vs pride), tee sheet (calendar vs live), lock (publish vs freeze). Each needs a log entry naming the winner, because each currently has two.

## B. Evidence index

| Finding | Reports | Screenshots (`screenshots/<session>/…`, `.jpg`) | Source |
|---|---|---|---|
| H1 pre-season rounds | ORG, NOV, JOIN, CAS, COMP, SKEP | `org/68,69,72` · `nov/34,35,36,71,72,78` · `join/46,47,51,52` · `cas/51,53,57` · `comp/35,38,40` · `skep/32,33,37` | `index.html:3198,6306–6341,6588,10076,10105,11981,12225`; baseline `:1372` |
| H2 allowance | OBS (collision), ORG, NOV, JOIN, COMP, SKEP | `obs/04,10,22` · `org/30,68,71` | baseline `:1360`; `index.html:3250,11500–11524,11912,12090,16641`; `PostRoundScreen.swift:406`; §2.1, D2, D8, D48 |
| H3 endgame | all but IOS | `obs/08,21` · `nov/36` · `ios/03` · `org/23,28` | §14.3; `index.html:3293,3298,4478–4480,9614–9634,12001,14799`; D4, D24, D26, D105 |
| H4 sign | ORG, NOV, JOIN, CAS, COMP, SKEP, OBS | `org/68,69,71` · `nov/71,77,79` · `join/46,48,53` · `cas/51,53,56` · `skep/21,36` · `obs/10,44` | §2.1; D1; `index.html:2884,5710,6339,11481,11519` |
| H5 rules depth / vocabulary | all 8 | `org/45,49` · `nov/38,40,42,43` · `skep/06,07,13` · `obs/21,22` · `join/30` | `index.html:3250,3318,17274`; D3, D13, D14, D82 |
| H6 money | all 8 | `join/11,29,55` · `org/22,54` · `nov/19,61` · `comp/25,60` · `cas/25,37` · `skep/12,49` · `obs/12` | §7; D39, D66, D70, D106; `index.html:15428` |
| Consent / roles | CAS, JOIN, COMP, SKEP | `cas/86,87` · `join/39,54,56` · `comp/19,22` · `skep/19,50` | D40, D96, D50, §6; `index.html:10072–10116,14497–14501` |
| Lock bug (context) | ORG, NOV | `org/31` · `nov/30,31,33,34` | `index.html:15218`; commit `1fd47e1` (D97); 15/15 validators confirmed |

Every screenshot cited was read during synthesis; rows marked "code-confirmed" in Part 1 were verified against the files and line numbers given, not taken from the reports. Validation verdicts: `raw/synthesis-and-validation-results.json` — TOP-1 through TOP-5, three lenses each, 15/15 "Confirmed UX problem", 0 refuted.

## C. Test footprint

Accounts `jerecho+blind1..6@fischbeck3.com` and `+blind2x`. Leagues **The Papago Grind** (`THEPTCQ5`; organizer +blind1; members +blind2/3/4/6) and **Desert Dogs** (`DESEUU0K`; +blind5). Inside those leagues only: posted rounds, one $5 match-play story, guest "Marco", one skins round, board messages. The read-only observer used the owner's real account and made no writes (DB check: 0 rounds, 0 posts). Re-runs (`_run 2` in `persona-results.json`) of casual / competitive / skeptic / iOS on already-used accounts signed out, redid the cold paths and flagged contamination in their blockers; only their fresh observations are used here.

## D. Companion deliverables

`synthesis-rules-mental-model.md` and `synthesis-terminology.md` (the base syntheses this document consolidates) · `synthesis-loop-hierarchy.md` · `synthesis-retention-monetization.md` · `synthesis-sidegames-setup.md` · `synthesis-triage.md` · `issues.json` / `issues.csv` / `issues-counts.json` (135 deduped issues: 7 P0 · 44 P1 · 65 P2 · 19 P3; comprehension 28, terminology 17, rules 14) · `raw/` (the eight persona reports, the harness-artifact run, `persona-results.json`, `synthesis-and-validation-results.json`).

---

*Companion documents in this folder: `README.md` (start here) · `blind-ux-audit.md` (master report) · `critical-findings.md` · `user-journey-map.md` · `gameplay-loop.md` · `retention-audit.md` · `issues.json` / `issues.csv` / `issues-counts.json` (`issues-README.md`) · the six `synthesis-*.md` files · `raw/` · `screenshots/`.*
