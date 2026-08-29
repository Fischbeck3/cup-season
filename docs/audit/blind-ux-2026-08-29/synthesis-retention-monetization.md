# Blind UX audit 2026-08-29 — Synthesis: retention, social, monetization, competitors

**Scope.** Eight blind persona passes on the web client at `http://127.0.0.1:8791/` (seven interactive, one read-only) plus a screenshot-only survey of the native iPhone app. This document synthesizes the raw reports on the questions of *whether people come back, whether they bring others, whether they would pay, and what the product is competing against*. The onboarding/comprehension defects are covered elsewhere; they appear here only where they drive retention or monetization.

**Sources.** Raw reports in `docs/audit/blind-ux-2026-08-29/raw/` (cited below by file); screenshots under `screenshots/<session>/` (cited by session + file). Product intent established from `spec/spec-v1.0.md`, `spec/product-vision-v1.0.md`, `spec/decision-log.md`, `Cup-Season-Guide.md`, `index.html`, and the `push` / `season-email` Edge Functions.

**Three labels are kept apart throughout.**
- **SEEN** — what a tester observed, verbatim copy, screenshot.
- **READ** — the tester's or synthesizer's interpretation.
- **MEANT** — what the spec / decision log says the product intends. When MEANT explains something SEEN did not, that is the finding, not an excuse.

**Caveats that bound every score below.**
| Caveat | Effect on this synthesis |
|---|---|
| No tester had a **completed** season. The observer's two leagues were both `SEASON I`, live, week 4/13 and week 6/26. | Finale, season+1, season+30 are judged from what the live app *says about* endings plus what the code and decision log say is built for endings. Scores there are projections, flagged as such. |
| The Papago Grind (5 of 7 testers) was **pre-season** (first tee Sep 5; audit Aug 29). Desert Dogs (novice) had **one member**. | "Week 1" is judged from a forming league, which is the real Week 1 for every new league. |
| Both observer leagues had **exactly two players**. | "Who is my rival" and "everyone advances" are trivially answered by roster size; scored accordingly. |
| Headless browser: `navigator.share` undefined, clipboard denied, no push permission. | Every share/notification path was observed only as its fallback. Where the fallback itself is the defect (invisible feedback, wrong error copy), it is counted; where the native path may work on a phone, it is flagged. |
| Three accounts (casual, competitive, skeptic) were **contaminated** by earlier runs; the iOS simulator held a session. | Day-0 is anchored on the clean runs (organizer, novice, joiner) and the earlier-run screenshots those reports cite. |
| The weekly clash (D108) and the Cup Final race view (D105) were pushed **2026-08-28/29** — the day before / day of the audit. | No tester saw either. Treated as "built, unobserved," not as "missing." |

---

## 1. Retention lifecycle

Scores are 1–10 on six dimensions — understanding · motivation · competition · social engagement · emotional investment · likelihood of return — synthesized across personas. The observer (agent7) gave explicit lifecycle numbers; they anchor the mid-season rows and are shown alongside. Where a row is a projection (no tester lived it), the basis is stated.

### 1.1 The table

| Stage | Understand | Motivation | Competition | Social | Emotional | **Return** | Basis (who lived it) |
|---|---|---|---|---|---|---|---|
| **Day 0** (door → card → first league screen) | 3 | 5 | 2 | 3 | 3 | **5** | organizer, novice, joiner (clean); casual, skeptic, competitive (re-enacted) |
| **Week 1** (forming / pre-season league) | 4 | 4 | 2 | 4 | 3 | **4** | The Papago Grind ×5, Desert Dogs ×1 |
| **Week 4** (first month close approaching) | 5 | 6 | 5 | 4 | 5 | **6** | observer (WTB wk 4/13, iOS + web); observer's Fellas at wk 6 |
| **Mid-season** | 6 | 6 | 6 | 4 | 5 | **6** | observer (Fellas wk 6/26) — anchor: 6/6/6/4/5/6 |
| **Late season** (seeds locking, Cup Final approaching) | 4 | 5 | 5 | 4 | 5 | **5** | projection from live copy + code; observer 4/5/5/4/5/5 |
| **Finale** (Cup Final → close → ceremony) | 3 | 5 | 5 | 4 | 5 | **5** | projection; observer 3/5/5/4/5/4 |
| **Season + 1 day** | 4 | 3 | 3 | 3 | 4 | **4** | projection from D66/D68/D41 (built) vs. what the live app shows about endings; observer 3/3/3/3/3/3 |
| **Season + 30 days** | 3 | 2 | 2 | 2 | 2 | **2** | projection; observer 2/2/2/2/2/2 |

The shape is the finding: **the curve peaks in the middle and collapses at both ends.** The product is at its best when a season is running and a tester is losing to someone by a number; it is at its worst on the first day (nobody can say what the game is) and after the last day (the app has nothing built that a lapsed member will *see* without opening it, except one email).

### 1.2 Stage-by-stage evidence

**Day 0.**
- SEEN: the door is nine words — "Rally your crew. Post real rounds. **Take the cup.**" — two buttons, and a raw `v23 · __CS_VERSION__` (`skep/02-cold-door.jpg`, `org/01-door.jpg`, `join/01-A-cold-door.jpg`, `ios/01-door.jpg`). Every persona's cold answer to "what is a cup / a season / what do I win" was "unknown" (agent4-skeptic.md §Journey A: "The door is a wall with two handles"; agent5-organizer.md: "no 'how it works', no screenshot, no sample").
- SEEN: the first thing a joiner is told after committing is money — "**You're on the pot sheet: $50 buy-in.**" (`skep/05-after-verify.jpg`), and the consent sheet before that shows "PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks" with no roster, no dates, no organizer name (`join/11-J-after-take-me-in.jpg`; agent6-new-joiner.md §3).
- SEEN: the one screen that *does* explain the game — "How scoring works" — is reached by a link on the welcome sheet, or four taps deep behind "▸ LEAGUE RULES & PRO SHOP" (agent3-league-novice.md §"How scoring works" sheet; agent5-organizer.md 13:41 entry: "the single most important text in the app and it is four taps deep").
- READ: Day-0 return likelihood is carried entirely by the friend who sent the code, not by the product. The skeptic: "If Casey hadn't texted me, I'd close the tab. The only reason I continue is social obligation."
- MEANT: product-vision success metric — "join a league in under 30 seconds · understand standings in under 10 seconds · **never need a tutorial**." The Guide's own first paragraph ("Season-long fantasy golf for your regular group…ends in a Cup Final") is the sentence the door does not say.

**Week 1 (forming league).**
- SEEN: a member's Home leads with the organizer's job: "THE PAPAGO GRIND · FORMING · **7 days** to first tee · 5 golfers in · **[Lock it in and invite your crew]**" (`skep/09-home-full.jpg`; agent1-casual.md A2; agent6 J-02). Under it, "MONTH CLOSES **in 2 days**" and "Miss it and your squad loses 5 points" — a threat about a season that has not started (agent1 A9: "the opposite of a reason to open it; it's a reason to feel guilty").
- SEEN: the first posted round promises "LEAGUE POINTS THIS ROUND 5" then lands as `0 R · 0 Pts` with "No rounds this season yet — post one and you're on the board." (agent2 C-05, agent4 SK-09, agent6 J-03, agent1 A3, agent3 N-03, agent5 ORG-05 — **six of seven testers hit this**). The casual golfer's verbatim: "I logged a round, got a badge for 'breaking 100', and nothing happened to the competition."
- SEEN: the novice's one-member league — "Dead, with one bright spot" (agent3 §Empty-league state): two empty squads named "Squad 1 / Squad 2", "TOP SEED · +10" for a squad with no players, "PROJECTED UNDER A GENEROUS CEILING" over two zeros (`nov/36-clubhouse-full.jpg`).
- READ: Week 1 is the week the app most needs to say "nothing counts yet, here is what to do," and instead it shows a lock button, a month-close countdown, and a points preview that will not pay. The first competitive feedback every new member gets is a broken promise.
- MEANT: D24's "honesty rule" produces "PROJECTED UNDER A GENEROUS CEILING" — accurate, but rendered as an unexplained caption on a screen with no data. Pre-season rounds "hit your card, not the season" is stated exactly once (Clubhouse "BEFORE FIRST TEE" card, `nov/35-clubhouse-1.jpg`) and contradicted by Home ("SEASON LIVE — Rounds count from today") and by the post form.

**Week 4 / mid-season (the product's best stretch).**
- SEEN: Home answers "how am I doing" in three seconds — "FELLAS · WEEK 6 OF 26 · **1st** · — HELD · You lead by **22 points** over **Jade**." (`obs/04-home-first.jpg`); iOS "2nd — held · 10 points back of the lead." (`ios/01-door.jpg`). The observer: "big gold '1st'…I'm winning, Jade is second" in 3 s.
- SEEN: the month machinery gives a reason to open the app — "AUG FLOOR 1/2 ▬▬ 1 MORE · 2D", "MONTH CLOSES in 2 days", "3 days left in August" gradient bar (`obs/08-club-top.jpg`), "Post 1 more round this month — best 4 count, you've posted 1." The observer scored Week 4 motivation 6: "floor bar + month-close pill give a reason to open it."
- SEEN: the board carries real stories — "Galen broke 80 for the first time — a 79. That one goes on the wall." — and the observer named Galen as the one person the app made him care about (agent7 Journey G).
- SEEN, the ceiling on this stretch: "Still don't understand after exploration: HELD…floor 1/2…month closes (what closes? what happens?)" (agent7 Home read). "What do I need to do to win? **Not answered anywhere.**" (agent7 Journey E). The iOS survey: "I honestly can't tell you how he got there or how I get more."
- READ: mid-season retention is carried by *loss aversion on the floor* and *a rival's name*, not by understanding. That works for the two-player observer; it is fragile at 8+ where the rival is not automatic.
- MEANT: the vision's promise #2 ("Every round counts") is legible here; the spec's "understand standings in under 10 seconds" is met for *rank and gap* and missed for *what changes it*.

**Late season.**
- SEEN: the Cup Final is mentioned on exactly one live surface — the collapsed bylaws row "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" (`obs/21-bylaws-open.jpg`; agent7: "This is the ONLY place the app told me the season ends with a Cup Final"). Standings captions read "LOCKED", "HAS LOCKED A CUP SEED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" with no explanation (`obs/08-club-top.jpg`; `ios/03-clubhouse.jpg`).
- SEEN: the stat-strip line that should foreshadow the Final read "Week closes Sun · 1d" (`obs/09-club-mid.jpg`, `ios/03-clubhouse.jpg`).
- READ: a member who has watched a 22-point lead for 22 weeks will learn what it is worth from a bylaws row, or not at all. Every persona who reached the endgame question rated it the least understood rule (agent2 rules table: Cup Final confidence **2/10**, ties **1/10**; agent7 rulesClear 3).
- MEANT: D4 (2026-07-15) diagnosed exactly this — "the points leader discovers at reset time that the lead 'vanished' — reads as a rug-pull" — and prescribed a *season-long* foreshadow. What shipped is a stat-strip line chosen by "nearest deadline wins" (`index.html` ≈9630: `opts.sort((a,b)=>a.n-b.n || b.pri-a.pri)`), so the "Cup Final · <date> · Nd" line can only appear in the week before the Final, when it is nearer than Sunday and the 1st. **The foreshadow exists in code and is suppressed by its own sort for ~95% of the season.** D105 (Cup Final race view, `20260828170100_cup_final_race.sql`) shipped the day before the audit; it only renders once `status = cup_final`.

**Finale.**
- SEEN (what the live app says about endings): "Season live · Mon Jul 20 → Mon Jan 18 · 26 wks" — the end is a date in a range; "THE RECORD · No silverware yet — every season starts level"; the pot "$150 · 2 × $75 · **$0 collected** · 2 still owe" above "[Jade ✓] [Jerecho Fischbeck ✓]" (`obs/12-on-the-line.jpg`; agent7 §Journey F: "the database reached its final row").
- READ: with two players and "everyone advances," the Final is structurally hollow and nothing warns the Pro. With $0 collected six weeks in, the ceremony's "you're owed $90" line would be fiction.
- MEANT: spec §14.4 — "Home becomes the Trophy Room: champion banner, final table, awards, superlatives, pot settlement card. **Screenshot-shaped by design.**" D66 built a first-open takeover (`csSettlement`, `index.html` ≈11641–11714) with the margin, the tiebreak rung, and the viewer's own payout. None of it is visible before `complete`, and nothing on a live season previews it. D106 (pot = roster vs. collected = cash; ceremony pays from cash) is **PROPOSED, not built** — the "0/2 in" beside two ✓ marks the observer could not parse is precisely the confusion D106 names.

**Season + 1 day.**
- SEEN: nothing — no tester had one. What the app promises for it: the hero "Season wrapped · <league> · *Your name goes on the cup.* · Season recap → · [Run it back — Season 2]" (`index.html` ≈10026–10033).
- MEANT: D68 sends one email — subject `The Cup goes to <champ> by <gap> — <league>` (`supabase/functions/season-email/index.ts:251`) with the recipient's own payout line. D41 "Run it back" opens the wizard prefilled with a `· S2` name — a **new league id**, "continuity by convention"; "defending champs" and the margin line were explicitly deferred. D67 career record aggregates titles + exact payouts.
- READ: the ending is the best-designed beat in the decision log and the least-evidenced in the product a member can see today. The +1-day return is a 4 not a 3 only because the email exists and is well-aimed.

**Season + 30 days.**
- SEEN: "No app emails/notifications were received in 60 days" other than sign-in codes (agent7 §Blockers, Gmail search 13:46). Push exists but requires "Enable on this device" (`skep/47-settings-6.jpg`); the toggles read "ON" while the master button is unpressed (SK-32).
- MEANT: D23 — "V1 nudges are HOME-SURFACED chips only, never push"; D27 — "natural cadence is 2–4×/week, not daily; chasing daily opens would violate the guardrails." Email inventory in code: sign-in codes, buddy request ("Priya wants in your crew"), season-end ceremony, cancellation. **No month-close email, no floor-warning email, no weekly-clash email, no "your rival just posted" email.**
- READ: this is a deliberate policy, and its cost is the +30-day row. A member who has not opened the app has, by design, no reason the product gives them to open it — the only off-app touch between the buddy-request email and the season-end email is whatever the group text does on its own.

---

## 2. The emotional loop

| Element | Present? | SEEN (evidence) | MEANT (intent) | Gap |
|---|---|---|---|---|
| **Anticipation** | Partial | "MONTH CLOSES in 2 days", "3 days left in August", "NEXT · FRI · QUINTERO", "Week closes Sun · 1d" (`obs/04`, `obs/08`). Novice: "**The app never tells me when to play.**" iOS: `SEASON DATE` dots on every Sunday, unexplained. | D52: "fantasy football's engine is the week-as-episode…Cup Season's unit is the month — too long." D108 built the weekly clash 2026-08-28 (`THE CLASH · A v B · THROUGH SAT` chip, `index.html:4613`). | Countdowns exist; **what happens at zero is never said** ("month closes — what closes?"). The one weekly appointment the product has designed was not on any tester's screen. |
| **Rivalry** | Present (structurally) | "You lead by 22 points over Jade", "10 back of Galen", "RIVALRIES · YOUR RECORD Jade 2–0 · Galen 1–0" (`obs/29-you-full.jpg`), "you lead 1–0" on the tee-sheet row. Competitive: "**the app itself never picks a rival for me**"; "the only rivalry in my league today is the pride stake I typed myself." | D19 named rivalries (built); D52/D108 clash pairing "named rivalry > closest gap > least-recently-featured"; D24 magic number. | Rivalry is a *record* on the You tab, two taps away; on Home it is one name in the gap line. The app has the machinery to *choose and announce* a rival and did not, for anyone, in this audit. |
| **Identity** | Present | @handle, 14 ball markers, photo, "Points King / Iron Man" titles, display case, "✦ FOUNDER" pill. iOS: "NO. 2" marker name collides with being 2nd (`ios/06-you.jpg`). | Vision "Identity" stories; D59 marker floor; D102 Founder tags. | Strong. Undermined by badges that read as unearned ("Broke 100 · 91 gross" on a first round — five testers; "Broke 90 / Broke 100 both 88 gross"). |
| **Progression** | Present | Index 11.3 "▼ 1.1 this season", sparklines, "Personal best. New number to chase.", "number now comes from their scores 12.2 → 12.6". Three contradictory index stories on one account (agent7 issue 20). | Auto-handicap engine; D55 sunlight chip. | Present and trusted less than it should be because the numbers disagree. |
| **Stakes** | Weak | "$150 · $0 COLLECTED · 2 still owe" at week 6; WTB "None · Bragging rights"; Papago "$250 · $0 collected · 5 still owe"; joiner: "I still don't know how I'm supposed to pay him." Side-game cash ($60 skins) never reaches any ledger (agent2 C-28, agent3 N-24). | §7 "the ledger is the product"; D39; D106 (proposed) two numbers. | The pot is a number nobody has paid into, shown with no payment path, and the money that *did* change hands (skins) is not kept. Stakes are stated, not felt. |
| **Bragging rights** | Partial | Board stories ("That one goes on the wall"), settlement "MARCO PAYS CASEY $5", "Priya took 7 skins and $60". No share control on the scorecard sheet (`obs/42-matchplay.jpg`) or on stories; "Share the card" → invisible "Card downloaded". | D30 recap PNG; D57 public pages; D89 settlement card travel; §13.3 "the recap is the funnel". | The objects are screenshot-worthy; the product does not hand them to you at the moment you would brag, and the ones it does hand you gave no visible feedback in this environment. |
| **Unfinished business** | Partial | "1 MORE · 2D" floor bar; "a good weekend back"; casual: tee sheet "WITH CASEY · 7 DAYS" is the one thing that made him want to play. | D51 personal stake line ("what your next round is worth") — decided, build pending. | The only "unfinished" thing the app names is a *penalty to avoid*, never a *gain to chase* ("post a 9 and you pass Galen"). |
| **Social pressure** | Weak | 🔥 reactions, "Message the league…", a ⚑ that is *Report* beside 🔥 (SK-19). Rival's floor status invisible; no nudge; zero replies on any chat in any league. | D23 forbids shame/nag; D25 reactions; D20 trash-talk thread. | Pressure has to come from the group text; the app gives it nothing to point at ("Jade owes 2 rounds and $75" is computable and never shown). |
| **Redemption** | Absent | Nothing frames 2nd as a comeback path; "Level with X. Your next round breaks the tie." exists in code (`index.html` ≈10190) but no tester was level. | D24 magic number ("needs N"); D105 race view. | The engine exists; the sentence does not reach Home. |
| **Title defense** | Absent | "No silverware yet — every season starts level"; "SEASON I" everywhere; "Cups & events 2 · Played in" (which two? not linked). | D41 (new id per season — "defending champs" deferred); D67 career record. | There is nothing to defend because the product cannot yet say "you won last time." Deferred by decision, not by accident. |
| **A specific nemesis** | Present by accident | Two-player leagues make it automatic; Papago (5 players, pre-season) had none — "no 'you passed Marcus', no 'Priya is 3 points clear', no head-to-head" (agent4). | D52 clash pairing; D19 naming. | The moment roster > 2, the nemesis disappears unless the clash chip is on screen. It was not. |
| **Desire to improve** | Present | "Beat your number" framing; index trend; "beat it by 3+ · 12 pts". Competitive: "as a 6.4 with low variance I will 'torch' less often than a 15…the game structurally favours higher, more volatile handicaps." | §2.2 bands; §5 fairness ("a 22-index beating their number is worth exactly what a 6-index…"). | Present, with a fairness doubt the product never addresses for the low-handicap persona. |

**Net:** identity, progression and improvement are real; rivalry and nemesis are real only at n=2; anticipation is a deadline without a consequence; stakes, redemption and title defense are absent on every screen a tester could reach. The decision log has a designed answer for almost every absent row (D24, D51, D52/D108, D66, D67, D68, D105, D106) — five built-but-unobservable, two proposed, one pending.

---

## 3. Social pressure test

### 3.1 Which screens would a tester send to the group?

| Would send | Who said so | Would NOT send | Why not |
|---|---|---|---|
| Match-play scorecard with gold holes (`obs/42-matchplay.jpg`, `skep/45-matchplay2.jpg`) | observer, skeptic ("if it were a real 18-hole match") | — | — |
| Live settlement "MARCO PAYS CASEY $5 · SETTLE UP" (`org/92-settlement.jpg`); "JORDAN PAYS PRIYA $60" (`comp/58-live-posted.jpg`) | organizer ("the artifact I'd actually screenshot"), competitive | — | — |
| "Galen broke 80 … That one goes on the wall." story | observer, iOS survey ("the kind of thing I'd forward, but there is no share affordance") | — | — |
| Pride stake "Loser buys the beers · Jordan vs Casey" | skeptic ("the one object in the app that reads like our group text"), casual | — | — |
| — | — | Own round card "91 · 6.7 over your number" | skeptic: "a screenshot of my shame with the math attached"; casual: "it makes me look bad"; joiner: "mildly embarrassing but shareable" |
| — | — | Standings | all zeros pre-season; "three tables for two people" mid-season |
| — | — | Pot page | joiner: "'$0 collected · 5 still owe' would just start an argument about who pays whom, which is exactly what the page claims to prevent" |
| — | — | Round posted sheet | "a download, not a share" |

READ: the shareable objects are **the ones where somebody else loses** (a settlement, a match result, a stake) or **a milestone**. A losing round card is anti-shareable by design of the copy ("6.7 over your number" on the card itself). The product's own D2/D30 law says the card carries the band phrase; for the bottom band that phrase is a public confession.

### 3.2 Social objects that exist outside the app — and whether testers found them

| Object | MEANT (built?) | SEEN in this audit |
|---|---|---|
| Round recap card (PNG) | D30 — "Share the card" on the epilogue; PNG via share sheet / download | Every poster saw the button. Result: a hidden `role=status` "Card downloaded" (SK-16, J-AB, A-G02); competitive: "produced no visible feedback." Nobody saw the image. |
| Public round page | D57 — `/?share=TOKEN`, "Share a link — no account needed" | Seen on the first-round welcome sheet, stacked under "Turn off this link — the page stops working for everyone who has it" for a link the user never made (N-25, J-25). Not opened by anyone. |
| Settlement card + public settlement page | D89/D92, "Share the settlement — no account needed" | Seen (`comp/58-live-posted.jpg`, `org/92-settlement.jpg`). Clipboard denied; link text never displayed. |
| Public season page | "Share the season · A public page — the standings so far, no account needed [Link]" | Organizer tapped Link → "**Could not make the link. Please sign in again.**" while signed in; console showed a clipboard-permission error (ORG-26). Wrong diagnosis shown to the user. |
| Guest recap text + claim link | §13.3 "the recap is the funnel" | Copy seen ("get a recap text with their scorecard and an invite"); organizer's "Copy link" → "Copy failed — try again". Never received (no real guest phone). |
| Invite link | D40, "Share the invite link" on welcome / Standings / Members | **All seven interactive testers** got a 1.5-s toast "Invite code: THEPTCQ5" — no URL, no share sheet, no copied confirmation (ORG-03, N-05, SK-17, J-27, A22, C-…). The button says *link*; it gives a *code*. |
| Board stories / scorecards (in-app) | D25 reactions, D92 scorecard sheet | Seen and liked. **No share control on the scorecard sheet or any story** (agent7 issue 18; `openScorecard` at `index.html:10512` has no share button). |
| Push notifications | `push` function: round / chat / system / event / nudges, curated, mute-aware (D104) | Not observable headless. Settings showed "Round pings: ON · Chat pings: ON · Season email: ON" beneath an unpressed "Enable on this device" (SK-32). |
| Emails | sign-in code; buddy request; season-end ceremony (D68); cancellation | Sign-in codes and one buddy-request email ("Priya wants in your crew") observed. No league-invite email exists — three joiners searched for one (agent4, agent6, agent1). |
| Month-close post | §14.2 + D53 podium (`20260727160000_board_voice.sql`) | Observer saw "July closed — Ledger posted · Partial month, floors waived" — the administrative line, because July was a partial edge month. The first month-end every new league sees is the one without a podium. |

READ: **the product creates screenshot-worthy objects and no social object that a tester verified leaving the app.** Some of that is the harness; but the invite (the one object every organizer needs) fails identically for everyone, the recap card's only feedback is invisible, the scorecard sheet (the best-looking object) has no share at all, and the public-season link blamed the user for a permission error. The vision's growth motion — "shareable artifacts, foursome-by-foursome, no paid acquisition" — rests on exactly these paths.

---

## 4. Why would I come back?

Each answer is given as the testers gave it, graded (strong / weak / none), with the product change that would turn a weak answer into a strong one.

### 4.1 …tomorrow?
**Answer:** weak. "Yes, a little, for the feed" (casual); "the 'MONTH CLOSES in 2 days / lose 5 points' banner is the opposite of a reason to open it." iOS Home on a quiet day: "QUIET SINCE YOUR LAST VISIT · Sun, Aug 23 — Galen set a personal best" (D27 working as designed). Nobody named a *tomorrow* reason other than fear of the floor.
**Change required:** one line on the hero that names a *gain*, not a *penalty*: "Post a 9 by Sunday and you pass Galen" (D24's magic number already computes `needs`; D51's stake line is decided). And the weekly clash chip (D108) has to actually be on Home/Standings for every live league — the audit found zero instances.

### 4.2 …to play another round?
**Answer:** medium, and it comes from the wrong layer. The reasons testers gave: "a $5 skins game is a reason to care on hole 14 in December" (casual); "skins at $5 mattered more to me than the season points did today" (competitive); the tee sheet "You SAT SEP 5 · PAPAGO · WITH CASEY · 7 DAYS" (casual). The *season* gave nobody a reason: "the points table doesn't, because I don't understand it yet and it's all zeros."
**Change required:** the season must speak at the moment of a round the way the live game does. Post-round epilogue and receipt should carry points **and** table movement ("6 pts · Squad 1 now leads by 3"), and pre-season rounds must say "practice · season starts Sep 5" instead of promising 5 points (six testers).

### 4.3 …to finish the season?
**Answer:** weak-to-medium. The floor will keep people posting (loss aversion works); nothing keeps them *caring* — "the season layer is a participation contest whose rules I can't fully find" (competitive, 5/10); "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it" (observer, late-season return 5).
**Change required:** put the endgame on the hero and the standings from week 1 — "Season crowns 2 Cup seeds · Cup starts fresh Dec 22" (D4's own prescription) — and fix the stat-strip sort so the Final line is not hidden behind "Week closes Sun." Explain "LOCKED", "seed", "scored fresh" inline where they appear. State the tiebreak ladder somewhere a member can read it (spec §14.3 has it; the app does not).

### 4.4 …to start another season?
**Answer:** weak. The observer's honest answer: "**To beat Galen** — he's the only name the app made me care about — and only if more of the group is actually in it. The cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant." wouldPlayAgain across personas: 7, 6, 5, 6, 5, 7, 4, 6 (mean 5.75).
**Change required (three, in order):** (1) the ceremony has to be *previewed* during the season, not only shown after — a member should see what winning looks like before it is decided; (2) D106 so the "you're owed" line is cash, not roster arithmetic; (3) true multi-season continuity — same league, "defending champs", the margin line — which D41 explicitly deferred. Without (3), "Run it back" mints a fresh `SEASON I` and the title-defense row stays absent.

### 4.5 …to pay again next year?
**Answer:** none today, and the testers said why without prompting. wouldPay: 5, 4, 3, 5, 3, 5, 2, 3 (mean 3.75). Skeptic: "I'd pay $79 split six ways for THAT, if it were visibly true on day one. Today I've seen the ledger and the formula; I haven't seen the race." Organizer (5): "would pay ~$5/player if the Pro Shop is the price; unknown." Every tester met "CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE" and "PLAN FREE · PILOT · membership lands at launch" with no price, no scope, and no statement of who pays (ORG-17, SK-22, A32, N-14).
**Change required:** show the model (D56/D101 already decided it: league-year pass, $59/$89/$109 by roster band, first year free, paid by the Pro from the pot — "seven bucks a man"). The web copy has not caught up to D101; the iOS flag is off. But the price is the smaller problem: **nobody in this audit saw the thing they would be paying for run.** The race, the clash, the ceremony, the email, the career record — all built, none visible in a forming or two-player league. Monetization readiness is gated on those surfaces, not on Stripe.

---

## 5. Annual subscription test and monetization readiness

### 5.1 The five numbers

| Dimension | /10 | Reasoning (SEEN → READ) |
|---|---|---|
| **Perceived value today** | 4 | What is visible on day one is "a chat, a calendar, a pot ledger, gross scores, a $50 ask, a Pro's lock button" (skeptic) — things the group already has. The differentiators (vs-your-number bands, best-4 cap, floor, receipts, live settle-up) were rated 7–8 by the people who found them, and they are found by digging. |
| **Recurring value** | 5 | Mid-season the product earns its opens (floor, rival, board). Between seasons and pre-season it earns none. Live games are the strongest recurring hook and are league-independent (D107 made them the free door). |
| **Social lock-in** | 3 | The league graph is real (a league is 5–16 people who all have to be here) but the audit shows it is not yet *captured*: no invite email exists, the invite link never displayed, buddies are a second graph "with nothing to do with leagues" (agent4, agent3), and the group text is where the banter still lives (zero replies on any board). |
| **Switching cost** | 3 | Pre-season: zero ("my 91 lives in 18Birdies too"). Mid-season: the counting/floor arithmetic ("a formula I'd hate to maintain by hand" — skeptic) and the round history. There is no multi-season record yet to leave behind (D67 built; nothing to aggregate until a season closes). |
| **Annual renewal motivation** | 3 | The renewal moment is designed (D41, D66, D68, D101's "run it back goes back to being a celebration") and unproven: no completed season anywhere in the audit, no title to defend, the pot never collected, and the observer's 30-day projection is 2/10. |

### 5.2 What must happen before pushing monetization

1. **A season has to be seen ending well.** The ceremony (D66), the email (D68), the career record (D67) and the run-it-back card exist; nobody outside the sandbox has watched them fire. The first PIGL close is the real test. Until then every "would pay" number is a guess about a product the tester has not seen.
2. **The race has to be visible for the whole season, not the last week.** Fix the foreshadow sort; show seeds/magic number on Home; ship the clash chip on every live league (D108 is in prod as of 2026-08-29 — verify a row opens on the next tick and the chip renders).
3. **Pre-season honesty.** Six of seven testers were promised league points that did not exist. A product asking for money cannot open with a broken promise.
4. **The pot has to be true.** D106 (owed vs. collected) before any league is asked to pay a pass "out of the pot" — the pass is paid from money the Pro has, and today the app cannot say how much that is.
5. **The invite has to work.** An organizer who cannot send a link cannot form the league that would pay. ORG-02/ORG-03/N-05: no email/SMS invite, no visible URL, a global stranger search instead.
6. **State the price where the wizard sets the buy-in** (D56 surfaces: wizard pot step, You membership card, League Room Pro view) with D101's numbers. Testers explicitly could not tell whether "membership" would be charged to them, to the Pro, or mid-season (ORG-17: "the one money question the app does not answer anywhere").
7. **Then** the focus-group instrument (D56's deck) has real surfaces to test against.

### 5.3 "Why wouldn't I just use the group text / a spreadsheet / 18Birdies?"

The skeptic's value hunt (agent4-skeptic.md §VALUE HUNT) is the honest answer and is reproduced in condensed form:

| What the group does now | Cup Season today | Verdict |
|---|---|---|
| Group text banter | The Board: chat + auto-posted rounds + 🔥 | **Worse** for banter (three taps deep, no threads, report flag beside the reaction, zero replies anywhere), **better** for record ("nobody has to type 'shot 91'") |
| Spreadsheet standings | Standings tab | **Same** pre-season ("my row says 0 after I posted; the spreadsheet would at least show the 91"), **better** in-season ("best 4 a month vs your own index is a formula I'd hate to maintain by hand — that is the real spreadsheet-killer, and the app never sells it") |
| 18Birdies score / handicap | Post a round; auto index after 3 rounds; differential receipt | **Same-ish**: 20-second post beats hole-by-hole; two handicaps now; no GPS/stats; receipt explains itself better |
| Venmo | Pot ledger | **Replaceable**: "the pot ledger (Venmo + a text)" is on his free-tool list |
| Calendar / tee time in the text | Tee sheet | **Replaceable** |

His own sentence for what would justify $79/year: "It runs the whole season so nobody has to be the spreadsheet guy — it scores every round against your own number so the 8 and the 20 are in the same race, it tells you when you're about to miss your two rounds and cost the team five points, it shows who owes the pot and who gets paid at the end, and it's the place the trash talk lives because the scores are already there." **Every clause of that sentence is a built mechanic. None of it was visible to him on the day he joined.**

MEANT: spec §12 — "vs. TheGrint: golfer's utility vs league's competition engine…Defensible assets: the league graph, season history, commissioner lock-in, system of record for the pot." The audit finds the graph uncaptured (no invite), the history empty (SEASON I), the commissioner blocked (lock bug), and the system of record disputed by its own screens (owed vs. collected).

---

## 6. Competitor mental model

Where the loop is genuinely better, and where it feels like administrative software — from what the testers actually compared it to.

| Versus | Where Cup Season's loop is genuinely better (SEEN) | Where it feels like administrative software (SEEN) |
|---|---|---|
| **Group text** | Rounds auto-post with a band phrase; milestone stories ("broke 80 … goes on the wall"); the settlement card names who pays whom; pride stakes archive. | Chat is on tab 2 of a room 3 taps from Home; oldest-first with the compose box under the newest post; ⚑ = Report beside 🔥; no replies; nothing to forward except a code. "I'd stay in the group text and let Casey run it." |
| **Spreadsheet** | The counting cap, the floor, the bye, "a better round always bumps your worst" — computed live; receipts with the differential formula ("the one screen that shows its work, and it is good"). | Bylaws rendered as a spec sheet ("PRESET Standard · VERIFICATION Attested · COUNTING CAP · §4"); three tables for two players; "R" column unlabeled; standings that show 0 after a post with no reason. |
| **18Birdies / TheGrint** | 20-second post with course/tee autofill ("better than 18Birdies' course picker, honestly"); the round means something beyond itself. | A second handicap the golfer did not ask for ("having [my GHIN 6.4] replaced by a 3-round WHS-lite number is alarming"); no GPS, no stats; an inverted sign convention every golfer misreads. |
| **Traditional (Tuesday-night) league** | "Play anywhere, any day, any course" — the real differentiator, "stated once, in a guide card at the bottom of the You tab." No fixed tee times, no course. | "The app never tells me when to play"; a Pro who "approves byes", "marks buy-ins", "draws squads", "switches the endgame" — a job description nobody told the novice she was taking. |
| **Fantasy sports** | The framing testers reached on their own: "It's a fantasy-league-style golf season" (organizer, novice). Best-4 cap = a lineup you do not have to set; the floor = a roster you cannot ghost. | "Worse — no draft, no lineup decisions, no weekly matchups I can see" (skeptic); "Live draft night · Trades & waiver wire · SOON"; the weekly episode (D52's own diagnosis) not on screen. |
| **Ryder-Cup-style event** | Live match play with real strokes ("exactly the sentence golfers argue about on the first tee, and the app writes it for you"); guests without accounts; group phones. | The Ryder itself was seen only as a card: "⚔ Two teams · weekly vs-index duels · first to the clinch" — "terse to the point of jargon." |
| **Season-long friend competitions (the thing they'd invent themselves)** | Handicap-normalized bands so "a 97 from me can beat an 84 from Priya"; the floor "so nobody coasts"; a Cup Final. | "Everyone advances — 2 contenders, 2 seats"; "PROJECTED UNDER A GENEROUS CEILING"; "$0 collected"; a finale that is a bylaws row. |

READ: the loop is better *inside a round* (post, receipt, live settle-up) and *inside a month* (floor, cap, month close). It is administrative software *at the edges* — forming a league, reading the rules, understanding the ending, paying the pot — which is exactly where the organizer, the joiner and the skeptic spent their sessions. The category the spec names ("fantasy sports where your foursome are the athletes") was reached by two testers unaided and contradicted by a third who compared it to fantasy and found no weekly episode.

---

## 7. "If Cup Season disappeared tomorrow"

Answered by the skeptic verbatim and corroborated by the others.

| Question | Answer (SEEN / READ) |
|---|---|
| **Miss immediately** | Pre-season: "nothing — the season hasn't started, and my 91 lives in 18Birdies too." Mid-season (observer): the number ("1st · 22 over Jade"), the floor bar, and Galen's 79 on the wall. Live-round users: the settlement card and the strokes line. |
| **A group text / spreadsheet replaces** | The Board, the pot sheet, the stake card, the tee sheet, "joined the league" notices, buddies/find golfers ("we know each other"), the album ("Photos"). |
| **Another golf app replaces** | Posting rounds, the handicap index ("18Birdies/GHIN do it with more history"), course/tee lookup, the scorecard. |
| **Cannot be replaced** | "The rule set — best-4-a-month vs your own index, the floor, the squad race, the Cup Final 'scored fresh' — automatically applied across any course, and the receipt that shows the math for every point. **That is the product. It is also the part the app hides.**" |
| **Should become indispensable for** | (synthesized) The thing only a season-long system of record can be: *the group's competitive memory* — who beat whom, by how much, the margin the cup was won by, the rivalry record, what the pot paid, "defending champs." The vision names this ("Golfers…build rivalries. Win championships. Create traditions. Relive memories."); D67 and D19 build toward it; no tester could see any of it because every league is `SEASON I` with "No silverware yet." |

---

## 8. What Cup Season is actually selling vs. what it looks like it is selling

**Actually selling (from the sources):** *season-long competition* as the frame, *rivalry with friends* as the emotion, *a recurring golf tradition* as the renewal. Product-vision: "Cup Season exists to make every round of golf matter because it belongs to a season"; "Not another score tracking app. Not another handicap app."; personas' promises "I'll run the league so you can enjoy it" and "Every round counts." Spec §12: "fantasy sports where your foursome are the athletes." D101's Pro sentence: "The app's $89 for the year out of the pot — call it seven bucks a man — and it covers every season we run."

**What it looks like it is selling, screen by screen (SEEN):**

| Surface | What it presents | Category it reads as |
|---|---|---|
| Door | "Rally your crew. Post real rounds. Take the cup." + email + invite code | *scorekeeping with a prize* — "not specific enough to make a skeptic sign up" |
| Home (member, forming) | Start a league · Start an event · Join a league · **Lock it in and invite your crew** · MONTH CLOSES · floor penalty | *league administration* |
| Welcome sheet | "You're on the pot sheet: $50 buy-in." first | *betting / a money ask* — "the single most likely bail point" |
| Clubhouse header | Code · Add golfers · THE PRO · Cancel & delete this league (red, third line) | *league administration* |
| League tab | Members & invites · Share the season · Squads · ▸ LEAGUE RULES & PRO SHOP · membership "COMING AT LAUNCH" | *admin + an upsell* |
| Pot tab | $250 · $0 collected · 5 still owe · buy-in checkboxes · "Post a stake" | *a ledger* |
| Board | joins, match results, one chat line, 🔥 ⚑ | *social golf*, thinly |
| ⊕ → LIVE | strokes off the low man, skins riding, "JORDAN PAYS PRIYA $60" | *betting / side games* — rated 8/10 by two personas |
| Standings (mid-season) | 1st · 22 over Jade · LOCKED · EVERYONE ADVANCES · Points King / Iron Man | *season-long competition* — the only surface that reads as the category |
| You | index, badges, "No silverware yet", rivalries 2–0 / 1–0, SEASON I | *identity + a record with nothing in it yet* |

**The gap, stated plainly.** The product's own sentence for itself ("Season-long fantasy golf for your regular group…ends in a Cup Final. The app keeps score and keeps the pot's books.") appears in `Cup-Season-Guide.md` and nowhere a tester can see before or during joining. What a new member sees first is *administration* (a lock button, a code, a Pro) and *money* (a $50 line, a $0-collected pot); what a mid-season member sees is *competition without an ending* (a lead, a floor, a Cup Final in a collapsed row); what an ex-member sees is *nothing* (no email until a season ends, no title to defend). The strongest thing testers praised — the live settle-up — is the layer the spec calls "the acquisition surface" and treats as a side product, and it is the only layer that showed a tester who won, who lost, and what it cost, in the same session. Two testers independently wrote the same diagnosis: the scoring model is "smart and fair" / "genuinely good," and "the app just doesn't tell you any of that until you dig."

**What closing the gap looks like (one sentence per level of the hierarchy):**
- *Vision → IA:* the season's ending is a first-class object on every live-season screen, not a bylaws row.
- *IA → mechanics:* the engines that already exist (magic number, seeds, clash, ceremony, career record) render *before* they resolve, so the season is watched, not discovered.
- *Mechanics → UI:* the hero says one gain ("post a 9 by Sunday and you pass Galen") and one rival, every week, for every league of any size.
- *UI → copy:* the door says what the Guide says; the welcome sheet says the game before the money; the standings say "seed" and "scored fresh" in a sentence.
- *Implementation:* the invite link renders as a link; the share buttons say what they did; the foreshadow strip stops sorting the Cup Final out of view.

---

## Appendix A — Persona score sheet (as reported)

| Persona | concept | setup | rules | pickUp | gameplay | sideGames | stakes | invite | again | **pay** | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Organizer (Casey) | 5 | 4 | 5 | 4 | 7 | 8 | 6 | 4 | 7 | 5 | 3/10 |
| Novice (Dana) | 5 | 4 | 5 | 5 | 7 | 7 | 6 | 4 | 6 | 4 | 4/10 |
| Observer (mid-season) | 7 | — | 3 | 6 | 5 | 5 | 3 | 5 | 5 | 3 | 4/10 |
| Joiner (Marcus) | 5 | 4 | 5 | 4 | 6 | 4 | 6 | 4 | 6 | 5 | 3/10 |
| Casual (Jordan) | 5 | 5 | 3 | 4 | 5 | 6 | 6 | 4 | 5 | 3 | 4/10 |
| Competitive (Priya) | 6 | 5 | 4 | 7 | 5 | 8 | 5 | 6 | 7 | 5 | 5/10 |
| Skeptic (Sam) | 4 | 4 | 4 | 6 | 4 | 4 | 5 | 3 | 4 | 2 | 3/10 |
| iOS survey | 4 | 3 | 3 | 5 | 6 | 4 | 4 | 5 | 6 | 3 | 4/10 |
| **Mean** | 5.1 | 4.1 | 4.0 | 5.1 | 5.6 | 5.8 | 5.1 | 4.4 | 5.75 | **3.75** | 3.75 |

Pattern: *sideGames* and *gameplay* are the highest columns; *rules*, *setup* and *pay* the lowest. The mechanic is liked; its legibility, its setup and its price are not trusted.

## Appendix B — Built-but-unobserved retention machinery (for the owner's triage)

| Mechanism | Decision | Status per code | Why no tester saw it |
|---|---|---|---|
| Weekly clash chip + posts | D52 / D108 | `week_clashes` engine pushed 2026-08-28; chip at `index.html:4583–4640` | Renders only when a row exists; the daily tick had not opened one for the audit leagues. |
| Cup Final race view | D105 | `20260828170100_cup_final_race.sql`; client reads `cup_final_race` at `index.html:14605` | Only during `status = cup_final`. |
| Season-long foreshadow | D4 | Stat-strip option at `index.html` ≈9627 | Suppressed by "nearest deadline wins" sort until the last week. |
| Seed / magic-number line | D24 | `renderScenarioLine`, `index.html:14803+` | Rendered ("HAS LOCKED A CUP SEED", "EVERYONE ADVANCES") without any explanation of the words. |
| Season-end takeover + per-person payout | D66 | `csSettlement`, `index.html:11657` | No completed season. |
| Season-end email | D68 | `season-email/index.ts` ("The Cup goes to … by …") | No completed season. |
| Career record / titles | D67 | `career_record()` | Nothing to aggregate. |
| Run it back | D41 | `runItBack`, `index.html:14383` | No completed season; new league id, no "defending champs." |
| Month-close podium | D53 | `20260727160000_board_voice.sql` | Both observer leagues' first close was a partial month → administrative line only. |
| Named rivalries | D19 | `openNameRivalry`, `index.html:13471` | Records shown; naming affordance two taps deep; no rival chosen by the app. |
| Pot owed vs. collected | D106 | **PROPOSED** | The "0/2 in" beside two ✓ marks is the un-built decision. |
| Personal stake line | D51 | decided, build pending | — |
| Pricing surfaces | D56 / D101 | iOS behind `pricing.visible=false`; web copy still "COMING AT LAUNCH" | No price seen by anyone. |
