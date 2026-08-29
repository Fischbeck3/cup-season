# Blind UX audit 2026-08-29 — Retention, social, monetization, competitors

**Product:** Cup Season, web PWA at cupseason.app, prod build `34d20b6` (byte-identical to the `index.html` driven in this audit — every client defect named here is live), plus the native iPhone app in `apps/ios/`.
**Method:** seven blind personas drove the real product on real prod accounts through a headless iPhone-viewport browser; an eighth surveyed the iOS app's static landing screens; synthesis agents then read everything with the spec open; the five headline findings were adversarially validated by fifteen independent agents (all fifteen returned "confirmed UX problem", several with sub-claims struck — see Appendix E).
**This document** answers four questions: will people come back, will they bring others, will they pay, and what is the product actually competing with. Onboarding and rules defects appear only where they drive one of those four.

**Evidence conventions.** Raw reports live in `docs/audit/blind-ux-2026-08-29/raw/` and are cited by file name. Screenshots are cited as `<session>/<file>.png` as the testers named them; the frames live in this folder as `screenshots/<session>/<file>.jpg` (sessions: `org` organizer, `nov` novice, `join` joiner, `cas` casual, `comp` competitive, `skep` skeptic, `obs` observer, `ios` iPhone; validator frames `screenshots/v-TOP-*/` stay `.png`; copied out of the session scratchpad by `tools/collect_screenshots.py`; git-ignored). UI copy is quoted exactly. `index.html:NNNN` is a line in the tested build. Decisions are cited as `D<n>` from `spec/decision-log.md`.

Every major finding keeps four labels apart: **OBSERVATION** (what a tester saw, verbatim), **INTERPRETATION** (what it means), **IMPACT** (what it costs), **RECOMMENDATION** (what to change). Where the spec or decision log already prescribes the answer, that is named, because "designed and not shipped" is a different failure from "never thought of".

---

## The verdict in one paragraph

Cup Season's retention curve peaks in the middle of a season and collapses at both ends. When a season is running and a member is losing to someone by a number, Home answers "how am I doing" in three seconds and the month machinery gives a reason to open the app. On the first day nobody can say what the game is, the first thing a joiner is told after committing is that they owe $50, and the first promise the product makes ("LEAGUE POINTS THIS ROUND 5") is broken for six of seven testers. After the last day the product has, by policy, nothing that reaches a lapsed member except one email. Mean "would play again" across the eight passes (each family's latest run) is **5.75/10**; mean "would pay" is **3.75/10**; no persona verdict exceeded 5/10 (the executive-verdict *medians* across all 12 result rows — play again 6, pay 3.5 — are in `blind-ux-audit.md` §1, where the method is stated once). The uncomfortable part for the owner is that almost every missing emotional beat already has a designed and mostly built answer in the decision log (D24, D51, D52/D108, D66, D67, D68, D105, D106) that **no tester could see**, because no league in the audit had a clash row, a completed season, a second season, or more than two players in a live season. The product's strongest layer by tester score — live side games and the settle-up (8/10 twice) — is the one the spec treats as a side product; the season wrapper around it is what fails.

---

## Part 1 — Retention lifecycle

### 1.1 The table

Scores are 1–10, synthesized across the eight passes. **Observed** means at least one persona lived the stage in the real product; **inferred** means no one could, and the score is a projection from what the live app *says* about the stage plus what the code and decision log say is built. The observer (agent7) gave his own lifecycle numbers; they are shown as the anchor for the stages he lived and as a second opinion for the ones he could only read about.

| Stage | Observed / inferred | Who lived it | Understanding | Motivation | Competition | Social | Emotional | **Return** | Observer's own numbers |
|---|---|---|---|---|---|---|---|---|---|
| **Day 0** (door → card → first league screen) | Observed | organizer, novice, joiner on clean accounts; casual, competitive, skeptic re-enacted after signing out of contaminated accounts; iOS landed already signed in | 3 | 5 | 2 | 3 | 3 | **5** | 5/6/4/4/4/6 (his Day 0 was a returning member landing on a mid-season hero, not a cold joiner — hence higher) |
| **Week 1** (a forming league, first tee a week out) | Observed — as a forming league, which is the real Week 1 for every new league; an *in-season* week 1 was not observable | The Papago Grind ×5 (5 players, first tee Sep 5), Desert Dogs ×1 (1 player) | 4 | 4 | 2 | 4 | 3 | **4** | 5/6/5/4/5/6 |
| **Week 4** (first full month closing) | Observed, read-only | observer in "Who's the bitch?" wk 4/13 (web + iOS), 2 players | 5 | 6 | 5 | 4 | 5 | **6** | 6/6/6/4/5/6 |
| **Mid-season** | Observed, read-only | observer in "Fellas" wk 6/26, 2 players | 6 | 6 | 6 | 4 | 5 | **6** | 6/6/6/4/5/6 |
| **Late season** (seeds locking, Final approaching) | **Inferred** from live copy + a code trace of what would render | observer read the bylaws row and standings captions; validators traced `#statFinal` and the hero | 4 | 5 | 5 | 4 | 5 | **5** | 4/5/5/4/5/5 |
| **Finale** (Cup Final → close → ceremony) | **Inferred** — no completed season existed on any account | code: D66 takeover, D105 race view; spec §14.4 | 3 | 5 | 5 | 4 | 5 | **5** | 3/5/5/4/5/4 |
| **Season + 1 day** | **Inferred** — D41/D66/D68 exist in code; nobody saw them fire | — | 4 | 3 | 3 | 3 | 4 | **4** | 3/3/3/3/3/3 |
| **Season + 30 days** | **Inferred** from the observer's 60-day inbox and the D23/D27 policy | — | 3 | 2 | 2 | 2 | 2 | **2** | 2/2/2/2/2/2 |

The shape is the finding: **a hump in the middle, a cliff at both ends.** Nothing in the audit contradicts the mid-season hump; everything before and after it is either broken, hidden, or unbuilt-on-purpose.

### 1.2 Stage by stage

#### Day 0 — the return is carried by the friend who sent the code, not by the product

**OBSERVATION.**
- The cold door is nine words and two buttons: "Rally your crew. Post real rounds. **Take the cup.**" · [Continue with email] · [I have an invite code] (`skep/02-cold-door.jpg`, `org/01-door.jpg`, `join/01-A-cold-door.jpg`). Nothing below the fold (`cas/10-A01-door-scrolled.jpg`). Every persona's cold answer to "what is a cup / a season / what do I win" was some form of "unknown" (agent4-skeptic.md §Journey A: "The door is a wall with two handles"; agent5-organizer.md: "no 'how it works', no screenshot, no sample").
- The invite landing (`/?join=THEPTCQ5`) adds one line: "You're invited to The Papago Grind. Enter your email and you're in." (`skep/03-join-link.jpg`, `join/02-B-join-link-landing.jpg`). No inviter, no dates, no stake, no roster. The URL is rewritten to `/` immediately.
- After email, code, golfer card and an orientation card, the consent sheet reads "Before you join The Papago Grind · THE FINE PRINT, UP FRONT: BUY-IN $50 / player · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks … [Join — I'm in for $50]" (`join/11-J-after-take-me-in.jpg`). The joiner: "Can you understand what you are joining before accepting? — 3/10."
- The welcome sheet's first bold line is money: "**You're on the pot sheet: $50 buy-in.** The Pro tracks who's paid; money moves between you." (`skep/05-after-verify.jpg`, `cas/15-B03b-welcome-full.jpg`). The skeptic: "The first thing the product tells me after sign-up is that I owe $50. Casey's text did not mention money … this is the single most likely bail point for my persona; a real Sam replies to the group text 'wait, fifty bucks for what?' — and the app cannot answer."
- The one screen that explains the game ("How scoring works") is a link on that sheet or four taps deep behind "▸ LEAGUE RULES & PRO SHOP"; the organizer found it 18 minutes into the wizard "and only because the lock failed and I went digging" (agent5-organizer.md:180).
- **The organizer's Day 0 ends in a false failure.** Both organizers tapped "Lock the bylaws & form the squads" and got "Lock failed. Something went wrong — please try again." on every tap (six and five attempts; `nov/33-lock-fail-toast.jpg`); one learned the league was live only by reloading (`nov/34-reload-home.jpg`, "SEASON LIVE — Rounds count from today"). Orchestrator-verified cause: `index.html:15218` returns `invited: staged.length` after D97 removed `staged`; the seasons insert, `form_squads` RPC and `leagues.phase` update at ~15190–15216 all succeed before the throw. Prod telemetry read by a validator: lock_ok = 1 all-time (2026-07-27), lock_fail = 11 (all 2026-08-29) — **no league has locked successfully since D97 shipped.**
- The skeptic's verdict on continuing at all: "If Casey hadn't texted me, I'd close the tab. The only reason I continue is social obligation."

**INTERPRETATION.** Day-0 return likelihood is a 5 because a friend asked, not because the product earned it. The product's own definition of itself ("Season-long fantasy golf for your regular group … ends in a Cup Final") exists in the meta description and the Guide and on no screen a joiner sees before "I'm in for $50". The organizer — the person who has to bring five friends — gets a product that reports failure at the one tap that matters.

**IMPACT.** The vision's success metric is "join a league in under 30 seconds · understand standings in under 10 seconds · never need a tutorial" (`spec/product-vision-v1.0.md:146–147`). Every tester needed the organizer to explain the game in the parking lot. wouldInvite mean 4.4/10; the joiner: "I could not confidently explain what my friend would be agreeing to, and the app itself gave me nothing to forward except a code."

**RECOMMENDATION.** (1) Fix `index.html:15218` and make the post-commit tail idempotent — once `leagues.phase` has moved, never say "try again"; open the share sheet. (2) Put the Guide's sentence under the door slogan and a league card on the invite landing before the email box (the anon RPC `join_covenant_info` needs Pro name, roster count, dates and the point bands — it returns five bylaw fields today). (3) Reorder the welcome sheet: the game before the money. These are the TOP-1 and TOP-2 fixes in `synthesis-triage.md`; they are prerequisites for everything below.

#### Week 1 — the first promise the product makes is broken

**OBSERVATION.**
- A player's Home leads with the organizer's job: "THE PAPAGO GRIND · FORMING · **7** days to first tee. **5 golfers in.** The bylaws lock at the tee." over a full-width orange **[Lock it in and invite your crew]** (`skep/09-home-full.jpg`, `cas/19-C02b-home-full.jpg`). The CTA at `index.html:10102` has no role check; it opens the Pro's "CREATE YOUR LEAGUE … Lock the bylaws & form the squads" page for a plain member (`skep/50-lock-page.jpg`).
- Beneath it, a threat about a season that has not started: "MONTH CLOSES **in 2 days**" and "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points for every round you're short." (same screenshots). The casual golfer: "the opposite of a reason to open it; it's a reason to feel guilty."
- The post form promised "LEAGUE POINTS THIS ROUND **5**" (`skep/32-pre-post.jpg`), "**12** · You torched your number by 5.0. Sandbagger alert." (`comp/35-preview-74.jpg`). The posted card said only "COUNTS ON YOUR CARD"; standings stayed "0 R · 0 Pts" (`skep/37-standings-after.jpg`, `comp/40-standings-after74.jpg`); tapping a row: "No rounds this season yet — post one and you're on the board." (`comp/41-standings-priya-tap.jpg`). **Six of seven interactive testers hit this** (C-05, SK-09, J-03, A3, N-03, ORG-05). Orchestrator-verified: both organizers' leagues defaulted the first tee to Sat Sep 5; nothing states pre-season rounds do not count while Home shows a month-close countdown. Home says "SEASON LIVE — Rounds count from today" while the Clubhouse says "PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`nov/34-reload-home.jpg` vs `nov/35-clubhouse-1.jpg`).
- The skeptic's plain-language account: "So: I logged a round, got a badge for 'breaking 100', and nothing happened to the competition." (agent4-skeptic.md:195). The casual golfer's: "the app told me 'League points this round: 5' and then didn't give me any."
- Friction on the same loop, orchestrator-verified: a blank date on Post a round fails with "Post failed. That didn't go through — please try again." (real cause: null `played_on` violates NOT NULL; no field is flagged; "Start over" clears the date); the `courses` edge function returned five 502s in one session so "TPC Scottsdale" and "Papago" found nothing while a cached course ("Ken Mc") worked.
- The novice's one-member league: two empty squads named "Squad 1 / Squad 2", "TOP SEED · +10" for a squad with no players, "PROJECTED UNDER A GENEROUS CEILING" over two zeros (`nov/36-clubhouse-full.jpg`) — "Dead, with one bright spot."

**INTERPRETATION.** Week 1 is the week the app most needs to say "nothing counts yet — here is what to do", and instead it hands the member an admin button, a penalty countdown and a points preview it will not pay. The first competitive feedback every new member gets is a lie of omission. D24's honesty rule produced accurate captions ("generous ceiling") rendered as jargon on a screen with no data.

**IMPACT.** Two testers believed the post had failed. rulesClear scored 3–5 on every persona. The competitive golfer: "it showed me zero for three posted rounds without saying why … as shipped I'd play for the skins and shrug at the table." Week-1 return 4 — the lowest observed stage — and it is the stage every new league passes through.

**RECOMMENDATION.** Season-aware preview, posted card and receipt ("Season starts Sat Sep 5 — this round builds your number; no league points yet"); a read-only forming card for players ("Casey locks the bylaws at first tee · squads drawn then · post from Sep 5"); suppress the month-close pill and floor copy until the season is live; one season-state string feeding Home, Clubhouse and the form (TOP-3 and TOP-4 in the triage).

#### Week 4 and mid-season — the product's best stretch, and its ceiling

**OBSERVATION.**
- `obs/04-home-first.jpg`: "FELLAS · WEEK 6 OF 26 · **1st** · — HELD · You lead by **22 points** over **Jade**. · AUG FLOOR 1/2 ▬▬▬ 1 MORE · 2D · MONTH CLOSES **in 2 days**". The observer's 3-second read: "big gold '1st', 'You lead by 22 points over Jade.' — I'm winning, Jade is second." iOS (`ios/01-door.jpg`): "WHO'S THE BITCH? · WEEK 4 OF 14 · **2nd** · — held · 10 points back of the lead."
- The month machinery gives a reason to open the app: "3 days left in August" gradient bar, "Post 1 more round this month — best 4 count, you've posted 1." (`obs/08-club-top.jpg`). Observer Week 4 motivation 6: "floor bar + month-close pill give a reason to open it."
- The board carries a real story: "Galen broke 80 for the first time — a 79. That one goes on the wall." (`obs/05-home-full.jpg`, `ios/01-door.jpg`). The iOS survey: "the narrated story cards … are the best thing in the app."
- The ceiling, in the observer's words after visiting every surface: "Still don't understand … HELD … floor 1/2 … month closes (what closes? what happens?)". Journey E: "What do I need to do to win? **Not answered anywhere.**" The iOS survey: "I'm in 2nd with 9, Galen has 19, and I honestly can't tell you how he got there or how I get more."
- The Board tab contradicts Home on the phone — one line "Your league is live — post the first round" under TODAY while Home shows a round from Aug 23 and "Show earlier · 18" (`ios/04-board.jpg`); on the web the board shows two Aug 27 rounds while Home says one August round posted (`obs/19-sub-Board.jpg` vs `obs/04`). Three different index stories on one account ("▼ 1.1 this season", "Index move ▲ 1.2", "12.2 → 12.6").
- The second league — the one where the observer is losing — was invisible on Home until he opened it in the Clubhouse (`obs/04-home-first.jpg` vs `obs/36-home-earlier.jpg`). Validators: this is decided (D81 one hero slot; D94 rejected the four-quadrant Home); only the toast "Switch groups anytime from Home" (`index.html:17536`) is false. The cost stands.
- Inside a live round, the promised way back is missing: the "Group phones" sheet says "a Continue your round banner is waiting on Home"; it never appears (`cas/73-I06-group-phones.jpg`, A8). Orchestrator-verified: `[live-resume] server query failed: Could not embed because more than one relationship was found for live_rounds and live_round_players` on every Home load after a live round — PostgREST ambiguity (`live_scores` and `game_results` each carry FKs to both tables); the embed at `index.html:7800` needs `live_round_players!live_round_players_live_round_id_fkey`.
- Social: zero replies on any board chat in any league; the only human message in Papago ("Sam 91 at Papago. Casey you owe me a beer for the Grind sign-up.") sat unanswered beside a report flag. The observer received no app email in 60 days other than sign-in codes (Gmail search, 13:46 UTC).

**INTERPRETATION.** Mid-season retention is carried by loss aversion on the floor and by one rival's name in the gap line — not by understanding. That works in a two-player league where the rival is automatic. At eight players nothing on Home picks a rival, and the one product mechanism designed to (D108's weekly clash, pushed 2026-08-28) was on no tester's screen.

**IMPACT.** "Understand standings in under 10 seconds" is met for rank and gap and missed for *what changes them*. The observer's rulesClear 3, stakesMeaningful 3. Week-4/mid-season return 6 is the product's best number and it is a 6.

**RECOMMENDATION.** Keep the hero. Add one line under the gap that says what the next round is worth (D24 computes `needs` per contender; D51's stake line is decided for the post screen and explicitly left OPEN for Home as a named remainder — schedule it). Explain HELD / floor / month-close inline or on tap. Fix the live-resume embed so the banner exists. Ship the clash chip on Home for every live league and verify a row opens on the next tick.

#### Late season — the foreshadow exists in code and is sorted out of view

**OBSERVATION.**
- The Cup Final is mentioned on exactly one live pre-window surface: the collapsed bylaws row "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" behind "▸ LEAGUE RULES & PRO SHOP" on the League sub-tab (`obs/21-bylaws-open.jpg`). The observer: "**This is the ONLY place the app told me the season ends with a 'Cup Final'** … Three taps + one disclosure deep."
- Standings captions read "LOCKED" on both rows, "JERECHO FISCHBECK HAS LOCKED A CUP SEED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (`obs/08-club-top.jpg`, `ios/03-clubhouse.jpg`) with no explanation. iOS: "Both rows carry it, so it cannot distinguish us." "Advance to what? Seats where?"
- The stat-strip line that should foreshadow the Final read "Week closes Sun · 1d" (`obs/09-club-mid.jpg`, `ios/03-clubhouse.jpg`). The reason is in `index.html:9614–9636`: the Cup Final countdown is pushed into a list with the week close and the month close and the winner is chosen by `opts.sort((a,b)=>a.n-b.n || b.pri-a.pri)` — nearest deadline wins. A validator reproduced it with the code's own arithmetic: for Fellas the Cup Final line can render on **1 of 155 pre-window days**.
- "How scoring works" (`index.html:17274–17292`) has four sections — Your number, Every round, What counts, The money — and none about the finish or ties (`obs/22-how-scoring2.jpg`, `comp/29-rules-open2.jpg`). The competitive golfer's rules table: Cup Final confidence **2/10**, ties **1/10** ("Nothing. Not in bylaws, scoring sheet, standings footnote, or the welcome sheet."). The hero's "Level with X. Your next round breaks the tie." (`index.html:10195`) is wrong against spec §14.3, where a ladder decides ties.
- The decision log diagnosed this on 2026-07-15. D4: "the points leader discovers at reset time that the lead 'vanished' — reads as a rug-pull"; prescription "season-long foreshadow … the reset lands as a playoff, not a theft"; tradeoff accepted: "persistent banner real estate". D105 (2026-08-28) records the state as "D4's rug-pull, half-fixed: foreshadow shipped, the race itself never did" — and D105's race view renders only once `status = cup_final`, the exact moment D4 called the rug-pull.

**INTERPRETATION.** A member who has watched a 22-point lead for 22 weeks will learn what it is worth from a bylaws row or not at all. The endgame is engine-complete (`isCupFinal`, `cup_final_race`, `season_scenarios`) and its only plain-English explanation lives in a Pro-only wizard tooltip. This is a hierarchy failure: a sound mechanic, filed under league administration, narrated in engine vocabulary.

**IMPACT.** Late-season return 5. "A member can coast on a lead that decides nothing; the finale arrives unannounced" (triage TOP-5). The observer: "the lead I've watched for 22 weeks may mean nothing and I don't know it."

**RECOMMENDATION.** One endgame sentence wherever the standing is — hero, standings caption, Season tile from lock onward: "Top 2 seed into a 4-week Cup Final from Tue Dec 22 — scored fresh; the leader carries +10" (by structure). Stop sorting the Final against Sunday: keep the operational deadline and add a permanent second caption. Add "The endgame" and "Ties" sections to How scoring works stating §14.3 ("head-to-head months won → best single month → fewest rounds used → a logged coin flip"). Rename or define LOCKED ("SEEDED — a guaranteed place in the Final"), retire "PROJECTED UNDER A GENEROUS CEILING" for member words, fix the level-line copy.

#### Finale — structurally hollow at two players, and nothing previews the ceremony

**OBSERVATION (what the live app says about endings).**
- "Season live · Mon Jul 20 → Mon Jan 18 · 26 wks" — the end is a date in a range (`obs/12-on-the-line.jpg`). "THE RECORD · No silverware yet — every season starts level." (`obs/29-you-full.jpg`, `index.html:11299`). The pot: "$150 · 2 × $75 · **$0 collected** · 2 still owe" six weeks in, with a split "$90 CUP CHAMPS · $38 RUNNER-UP · $23 POINTS KING" (`obs/12-on-the-line.jpg`).
- The observer's Journey F verdict: "**the database reached its final row.** There is no countdown to Dec 22, no 'final starts in N weeks', no bracket/seed graphic, no tiebreak text, no preview of the settlement card, no history. … A two-player league where 'everyone advances' and both players get paid makes the finale structurally hollow, and the app does nothing to dramatise it or to warn the Pro that it will be."
- What is built and unseen: D66's first-open takeover (`csSettlement`, `index.html:11657`; "Run it back — Season 2" at 11756) with champion, margin, tiebreak rung and the viewer's own payout; spec §14.4 "Home becomes the Trophy Room … **Screenshot-shaped by design.**" None of it renders before `complete`, and nothing on a live season previews it.
- D106 (pot = roster, collected = cash, ceremony pays from cash) is **PROPOSED, not built**. Today `close_season` splits stake × ALL members; D106's own text: "A member who never paid still inflates every 'You're owed' line in the ceremony."

**INTERPRETATION.** The finale is the product's namesake and the best-designed beat in the decision log, and the only version of it a member can see today is a bylaws row and a pot nobody has paid into. At n ≤ seats the Final cannot produce drama, and the product neither says so nor points the Pro at the fix (add golfers).

**IMPACT.** Finale return 5 (observer 4). With $0 collected, the ceremony's "you're owed $90" line would be fiction — the exact moment money is supposed to move between friends.

**RECOMMENDATION.** Preview the ceremony during the season (what winning looks like, before it is decided). Build D106 before any league is asked to pay a pass "out of the pot". Flag n ≤ K to the Pro at lock ("With 2 players both of you reach the Final — the season only sets the seed. Add golfers to make the seed race real."). Add a Pro-set payment note and due date to the ledger; render non-Pro payer rows as status, not buttons.

#### Season + 1 day — the best-designed beat, the least evidenced

**OBSERVATION.** Nothing — no tester had one. What the code promises: the hero "Season wrapped · <league> · *Your name goes on the cup.* · Season recap → · [Run it back — Season 2]" (`index.html:10026–10033`, 9926–9928); D68's one email, subject "The Cup goes to <champ> by <gap> — <league>" with the recipient's own payout line (`supabase/functions/season-email/index.ts` ~239–241); D67's career record. D41's own tradeoff line: "V1 mints a NEW league id — continuity by *convention* (the `· S2` name + carried bylaws), not a linked object. True multi-season continuity … 'defending champs', the grudge/margin line … Deferred."

**INTERPRETATION.** The +1-day return is a 4 rather than a 3 only because the email exists and is well aimed at the week the run-it-back decision is made. The title-defense row (Part 2) stays absent by decision.

**IMPACT.** wouldPlayAgain mean 5.75. The observer, asked why he would start another: "the app never told me what winning would have meant."

**RECOMMENDATION.** Watch one real season end (PIGL) before trusting any of this; then build the deferred half of D41 — same league, "defending champs", the margin line on the run-it-back card.

#### Season + 30 days — by policy, nothing reaches a lapsed member

**OBSERVATION.** "No app emails/notifications were received in 60 days" other than sign-in codes (agent7 §Blockers). Push requires "Enable on this device"; beneath the unpressed button the toggles read "Round pings: ON · Chat pings: ON · Season email: ON" (`skep/47-settings-6.jpg`, SK-32). D23: "there are no re-engagement nudges of any kind. Nothing resurfaces." — and a nudge "must name one of the eight emotions … or it doesn't render"; V1 nudges are Home-surfaced chips, never push. D27: the natural cadence is 2–4 opens a week. The email inventory in code: sign-in codes, buddy request ("Priya wants in your crew"), season-end ceremony, cancellation. **No month-close email, no floor-warning email, no weekly-clash email, no "your rival just posted" email, and no league-invite email** (three joiners searched for one).

**INTERPRETATION.** This is a deliberate policy with a deliberate cost. A member who has not opened the app has, by design, no product-given reason to open it — the only off-app touch between the buddy-request email and the season-end email is whatever the group text does on its own.

**IMPACT.** Season+30 return 2 across every dimension, the observer's and this audit's alike.

**RECOMMENDATION.** Keep D23's fence and use it: a month-close podium email (D53's ceremony already composes the content), a floor-at-risk line that names anticipation not shame (self-only, per D23), and the D108 clash open/settle as push on the curated rails it was designed for. Fix the notification toggles so ON means on.

---

## Part 2 — The emotional loop

| Element | Present? | Evidence (SEEN) | Designed answer (MEANT) | Gap |
|---|---|---|---|---|
| **Anticipation** | Partial | "MONTH CLOSES in 2 days", "3 days left in August", "NEXT · FRI · QUINTERO", "Week closes Sun · 1d" (`obs/04`, `obs/08`). Novice: "**The app never tells me when to play.**" iOS: blue "SEASON DATE" dots on every Sunday, unexplained. | D52: "fantasy football's engine is the week-as-episode … Cup Season's unit is the month — too long." D108 built the weekly clash 2026-08-28 (`THE CLASH · A v B · THROUGH SAT`, `index.html:4613–4615`). | Countdowns exist; what happens at zero is never said. The one weekly appointment the product designed was on nobody's screen. |
| **Rivalry** | Present at n=2 only | "You lead by 22 points over Jade", "10 points back of Galen", "RIVALRIES · YOUR RECORD Jade 2–0 · Galen 1–0" (`obs/29-you-full.jpg`), "you lead 1–0" on the tee-sheet row. Competitive (5 players): "**the app itself never picks a rival for me**"; "the only rivalry in my league today is the pride stake I typed myself." | D19 named rivalries; D52/D108 clash pairing "named rivalry > closest gap > least-recently-featured"; D24 magic number. | The record is two taps away on You; on Home it is one name in the gap line. The app has the machinery to choose and announce a rival and did not, for anyone. |
| **Identity** | Present | @handle, 14 ball markers, photo, "Points King / Iron Man" titles, display case, "✦ FOUNDER" pill. iOS: marker name "NO. 2" collides with being 2nd (`ios/06-you.jpg`). | Vision "Identity" stories; D59 marker floor; D102 tags. | Strong, undermined by unearned badges: "Broke 100 · 91 gross" on a first round (five testers); "Broke 90 / Broke 100 both 88 gross". The organizer: "they will be mocked in the group chat." |
| **Progression** | Present | Index 11.3 "▼ 1.1 this season", sparklines, "Personal best. New number to chase.", "number now comes from their scores 12.2 → 12.6". | Auto-handicap engine; D55 sunlight chip. | Trusted less than it should be because three index stories disagree on one account (agent7 issue 20). The competitive golfer on her GHIN 6.4 being replaced by a 3-round number: "alarming." |
| **Stakes** | Weak | "$150 · $0 COLLECTED · 2 still owe" at week 6; WTB "None · Bragging rights"; Papago "$250 · $0 collected · 5 still owe"; joiner: "I still don't know how I'm supposed to pay him." Side-game cash ($60 skins) reaches no ledger (C-28, N-24). | §7 "the ledger is the product"; D39; D106 (proposed). | The pot is a number nobody has paid into, shown with no payment path, and the money that did change hands is not kept. Stakes are stated, not felt. |
| **Bragging rights** | Partial | Stories ("That one goes on the wall"), settlement "MARCO PAYS CASEY $5", "JORDAN PAYS PRIYA $60". No share control on the scorecard sheet (`obs/42-matchplay.jpg`) or on stories; "Share the card" → invisible "Card downloaded". | D30 recap PNG; D57 public pages; D89 settlement card; §13.3 "The recap is the funnel". | The objects are screenshot-worthy; the product does not hand them over at the moment you would brag, and the ones it does hand over gave no visible feedback in this environment. |
| **Unfinished business** | Partial | "1 MORE · 2D" floor bar; "a good weekend back"; casual: the tee sheet "WITH CASEY · 7 DAYS" is the one thing that made him want to play. | D51 stake line — decided, Home surface open. | The only "unfinished" thing the app names is a penalty to avoid, never a gain to chase. |
| **Social pressure** | Weak | Fire reactions, "Message the league…", a flag that is *Report* beside the reaction (SK-19). Rival's floor status invisible; no nudge; zero replies on any chat in any league. | D23 forbids shame; D25 reactions; D20 trash-talk thread. | Pressure has to come from the group text; the app gives it nothing to point at ("Jade owes 2 rounds and $75" is computable and never shown). |
| **Redemption** | Absent | Nothing frames 2nd as a comeback path. "Level with X. Your next round breaks the tie." exists (`index.html:10195`) but nobody was level — and it is wrong against §14.3. | D24 magic number; D105 race view. | The engine exists; the sentence does not reach Home. |
| **Title defense** | Absent | "No silverware yet — every season starts level"; "SEASON I" everywhere; "Cups & events 2 · Played in" (which two? not linked). | D41 — "defending champs" deferred; D67 career record. | Nothing to defend because the product cannot yet say "you won last time". Deferred by decision, not by accident. |
| **A specific nemesis** | Present by accident | Two-player leagues make it automatic. Papago (5 players): "no 'you passed Marcus', no 'Priya is 3 points clear', no head-to-head" (skeptic). | D52 clash pairing; D19 naming. | The moment roster > 2 the nemesis disappears unless the clash chip is on screen. It was not. |
| **Desire to improve** | Present | "Beat your number" framing; index trend; "beat it by 3+ · 12 pts". | §2.2 bands; §5 fairness. | Present, with a fairness doubt the product never addresses: "as a 6.4 with low variance I will 'torch' less often than a 15 … the game structurally favours higher, more volatile handicaps." (competitive) |

**Net:** identity, progression and improvement are real; rivalry and nemesis are real only at n=2; anticipation is a deadline without a consequence; stakes, redemption and title defense are absent on every screen a tester could reach. Of the seven weak or absent rows, five have built-but-unobservable answers, one is proposed (D106), one is pending (D51's Home line).

### 2.1 Three loop findings that are not covered above

**Anticipation without consequence.**
OBSERVATION: "MONTH CLOSES in 2 days" appears on every Home, including a forming league's and (in an earlier run) a league-less Home; the observer, after reading every help surface: "month closes — what closes? what happens?". The only month-close the observer's leagues ever posted was "July closed — Ledger posted · Partial month, floors waived" — the administrative line, because July was a partial edge month. INTERPRETATION: the product's natural episode (the month) ends in bookkeeping for every new league's first close, and the countdown to it never says what it counts down to. IMPACT: the strongest recurring beat is experienced as a threat. RECOMMENDATION: the pill says what closes ("Best 4 lock · floors assessed · podium posts"); D53's podium ships on the first close a league sees, waived floors or not.

**A rival chosen by roster size.**
OBSERVATION: every "who threatens me" answer in the audit was trivially true because both live leagues had two players; in the five-player forming league no persona was given a rival, a gap or a head-to-head. INTERPRETATION: the mid-season hump in Part 1 is partly an artifact of n=2 and will not survive an 8-player PIGL unless the clash (D108) and the named-rivalry affordance (D19, two taps deep) are put on Home. IMPACT: at launch scale the one line carrying mid-season return ("over Jade") has no name in it. RECOMMENDATION: verify D108 opens a row on the next tick and the chip renders on Home and Standings for every live league; surface "name a rivalry" where the gap line is.

**Stakes that live in three places and add up in none.**
OBSERVATION: the pot ($250, $0 collected) is a ledger the Pro edits; pride stakes are "never money"; live-game cash ("JORDAN PAYS PRIYA $60") posts to the board and vanishes from every ledger (`comp/60-pot-after-skins.jpg`: Pot unchanged). INTERPRETATION: "Cup Season keeps the books" is true for the pot and false for the games, and the pot itself has no way to be paid. IMPACT: the skeptic's read — "the pot is a spreadsheet column" — is accurate today. RECOMMENDATION: D106 plus a payment note; archive settlements into the record (N-24's ask).

---

## Part 3 — Journey G: "I just finished a season — why would I start another?"

What each persona actually said, verbatim, with the "I don't know / fun but don't need it" answers kept.

| Persona | The emotional reason to return, in their words | The honest hedge |
|---|---|---|
| **Observer** (agent7, mid-season, two live leagues) | "**To beat Galen** — he's the only name the app made me care about — and only if more of the group is actually in it. The cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant." (4/10) | "If the group stayed at two players, my answer is '**fun, but I don't need the app again.**'" |
| **Skeptic** (agent4) | "If it visibly ran the race for us, $79/year split six ways would be fine." What would keep him: "it's the place the trash talk lives because the scores are already there." | "I'd stay in the group text and let Casey run it; I'd post rounds only because he nags." On what he'd miss immediately: "**nothing** — the season hasn't started, and my 91 lives in 18Birdies too." (3/10) |
| **Competitive** (agent2) | "The live games and the receipts are genuinely good and **I'd use them every Saturday**"; "skins at $5 mattered more to me than the season points did today." | "As shipped I'd play for the skins and shrug at the table." "The only rivalry in my league today is the pride stake I typed myself." (5/10) |
| **Casual** (agent1) | Between rounds: "**Yes, a little, for the feed**: 'Priya broke 80', 'Sam 91 at Papago. Casey you owe me a beer', skins results with scorecards. That's the group chat I already have, with numbers attached." Next round: "The tee sheet ('You SAT SEP 5 · PAPAGO · WITH CASEY · 7 DAYS') and the monthly floor (fear)." "A $5 skins game is a reason to care on hole 14 in December. That's the best part of the app for someone like me." | "The points table doesn't, because I don't understand it yet and it's all zeros." "The 'MONTH CLOSES in 2 days / lose 5 points' banner is the opposite of a reason to open it." (4/10) |
| **Organizer** (agent5) | Side games "matter when out of contention: yes — **this is the best retention lever in the app.**" "The settlement card is the artifact I'd actually screenshot into the group chat — 'MARCO PAYS CASEY $5' is the whole point." wouldPlayAgain 7. | "Fix the lock bug and add a real invite and this is a 7." — i.e. today it is a 3. |
| **Novice** (agent3) | "A $5 skins game with the guys is a reason to play regardless of the table, and the 5-point floor means the round still helps the squad. That is the strongest retention idea in the app, and it is one tap deeper than it should be." What would keep her going: "a visible invite LINK with a '2 invited · 0 joined · 4 needed to tee off' tracker on Home; a countdown that's honest ('7 days to first tee — you need 3 more golfers'); and the round I just posted acknowledged as 'practice — on your card, season starts Sep 5'." | League verdict: "Dead, with one bright spot." (4/10) |
| **Joiner** (agent6) | "Why 'would play again 6': the handicap-normalised bands are a genuinely good idea and the receipt shows the math." | "Why 'would invite 4': I could not confidently explain what my friend would be agreeing to, and the app itself gave me nothing to forward except a code." (3/10) |
| **iOS survey** | "The rank card and the 'broke 80' story are genuinely motivating" (gameplayCompelling 6). | "The organizer will have to explain the rules to you, because the app doesn't." (4/10) |

**Read across the eight:** the reasons to return that testers volunteered are (1) a specific person to beat, (2) a $5 side game, (3) the feed as "group chat with numbers". Nobody named the season, the Cup Final, the pot or a title. The season is what the product is named after and it appears in no persona's answer to "why would I come back".

---

## Part 4 — The five retention questions

Each answer is graded as the testers gave it, then the product change that would move it. Where a validator found the change already decided or deferred, that is named.

### 4.1 Would I come back tomorrow?
**Answer: weak.** "Yes, a little, for the feed" (casual). The only *tomorrow* reason anyone gave was fear of the floor, and the casual golfer called that "a reason to feel guilty". iOS Home on a quiet day: "QUIET SINCE YOUR LAST VISIT · Sun, Aug 23 — Galen set a personal best" (D27 working as designed, and immediately followed by an item, which the survey flagged as contradicting itself).
**Change required.** One line on the hero that names a gain, not a penalty — "Post a 9 by Sunday and you pass Galen" — from D24's `needs` (already computed) via D51's stake line (decided; its Home surface is the named open remainder). The D108 clash chip on Home and Standings for every live league (zero instances observed). The live-resume embed fixed so the "Continue your round" banner exists on the day a round is half-scored.

### 4.2 Would I come back to play another round?
**Answer: medium, from the wrong layer.** "A $5 skins game is a reason to care on hole 14 in December" (casual); "skins at $5 mattered more to me than the season points did today" (competitive); the tee sheet "WITH CASEY · 7 DAYS" (casual). The season gave nobody a reason: "the points table doesn't, because I don't understand it yet and it's all zeros."
**Change required.** The season has to speak at the moment of a round the way the live game does. Post-round epilogue and receipt carry points **and** table movement ("6 pts · Squad 1 now leads by 3"); pre-season rounds say "practice · season starts Sep 5" instead of promising 5 points (six testers); the receipt gains a "League points" line and the index used (spec §16 stops one line short of itself today).

### 4.3 Would I finish the season?
**Answer: weak-to-medium.** The floor will keep people posting — loss aversion works. Nothing keeps them caring: "the season layer is a participation contest whose rules I can't fully find" (competitive, 5/10); "the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it" (observer, late-season return 5).
**Change required.** Put the endgame on the hero and the standings from lock ("Season crowns 2 Cup seeds · Cup starts fresh Dec 22" — D4's own prescription, six weeks old); fix the `#statFinal` sort so Sunday stops beating December; explain "LOCKED", "seed", "scored fresh" where they appear; add "The endgame" and "Ties" to How scoring works from §14.3; one floor sentence that includes D14's automatic bye (Home's "Miss it and your squad loses 5 points" is false for a first miss).

### 4.4 Would I start another season?
**Answer: weak.** wouldPlayAgain across the eight passes: 7, 6, 5, 6, 5, 7, 4, 6 (mean 5.75). The observer's answer is the only one with an emotion in it and it is conditional on roster size: "To beat Galen … and only if more of the group is actually in it."
**Change required (three, in order).** (1) Preview the ceremony during the season — a member should see what winning looks like before it is decided; today D66's takeover is invisible until `complete`. (2) Build D106 so "you're owed" is cash, not roster arithmetic. (3) True multi-season continuity — same league, "defending champs", the margin line — which D41 explicitly deferred; without it "Run it back" mints a fresh `SEASON I` and the title-defense row stays empty. Underneath all three: the invite has to work, because "only if more of the group is in it" is a growth condition, and today the lock reports failure and the link is a code in a 1.5-second toast.

### 4.5 Would I pay again next year?
**Answer: none today.** wouldPay: 5, 4, 3, 5, 3, 5, 2, 3 (mean 3.75). The skeptic: "I'd pay $79 split six ways for THAT, if it were visibly true on day one. Today I've seen the ledger and the formula; I haven't seen the race." The organizer (5): "would pay ~$5/player if the Pro Shop is the price; unknown." Every tester met "CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE" (`index.html:3564`) and "PLAN FREE · PILOT · Cup Season membership lands at launch. Nothing to pay during the pilot." (`index.html:13783`) with no price, no scope and no statement of who pays. The organizer: "the one money question the app does not answer anywhere."
**Change required.** Two things, and the second is bigger. (1) Say the model where the wizard sets the buy-in: D101 (2026-08-27) decided a league-year pass, $59 (≤9) / $89 (10–13) / $109 (14+), first year free, paid by the Pro out of the pot — "call it seven bucks a man". It is built on iOS behind `app_flags.pricing.visible=false` and absent from the web. Validators note the "coming at launch" copy is the decided pilot posture, not a bug; the question testers could not answer (who pays, when, on top of the buy-in?) is still unanswered by that posture. (2) **Nobody in this audit saw the thing they would be paying for run.** The race, the clash, the ceremony, the email, the career record — built, none visible in a forming or two-player league. Monetization readiness is gated on those surfaces, not on Stripe.

---

## Part 5 — Annual subscription test and monetization readiness

### 5.1 The five numbers

| Dimension | /10 | Reasoning (SEEN → READ) |
|---|---|---|
| **Perceived value today** | **4** | What is visible on day one is "a chat, a calendar, a pot ledger, gross scores, a $50 ask, a Pro's lock button" (skeptic) — things the group already has. The differentiators (vs-your-number bands, best-4 cap, floor, receipts, live settle-up) were rated 7–8 by the people who found them, and they are found by digging: the organizer reached the scoring explainer 18 minutes in, by accident. |
| **Recurring value** | **5** | Mid-season the product earns its opens (floor, rival, board). Pre-season and between seasons it earns none. Live games are the strongest recurring hook and are league-independent by D107 (the tee sheet is the free door) — which means the most valuable recurring behaviour is the one the pass does not gate. |
| **Social lock-in** | **3** | The league graph is real (5–16 people who all have to be here) and uncaptured: no invite email exists; the link never displayed as text for any tester (only the never-opening lock share sheet prints it); buddies are a second graph "with nothing to do with leagues" (skeptic, novice); zero replies on any board — the banter still lives in the group text. |
| **Switching cost** | **3** | Pre-season: zero ("my 91 lives in 18Birdies too"). Mid-season: the counting/floor arithmetic ("a formula I'd hate to maintain by hand") and the round history. There is no multi-season record to leave behind — D67 is built and has nothing to aggregate until a season closes. |
| **Annual renewal motivation** | **3** | The renewal moment is designed (D41, D66, D68, D101's "the run-it-back moment goes back to being a celebration") and unproven: no completed season anywhere in the audit, no title to defend, the pot never collected, the observer's 30-day projection 2/10. |

### 5.2 The specific recurring value that could justify payment

The skeptic wrote the sentence unprompted, and it is the product's pitch better than any screen in the product:

> "It runs the whole season so nobody has to be the spreadsheet guy — it scores every round against your own number so the 8 and the 20 are in the same race, it tells you when you're about to miss your two rounds and cost the team five points, it shows who owes the pot and who gets paid at the end, and it's the place the trash talk lives because the scores are already there." — "I'd pay $79 split six ways for THAT, if it were visibly true on day one."

**Every clause of that sentence is a built mechanic. None of it was visible to him on the day he joined.** Clause by clause: the season race (visible only mid-season, only as a gap, never with an ending); vs-your-number scoring (visible on the receipt, contradicted by the sign convention and the pre-season zero); the floor warning (visible as a threat, never as a projection); who owes the pot (visible, with no payment path); the trash talk (three taps deep, oldest-first, with a report flag beside the reaction, zero replies).

### 5.3 "Why wouldn't I just use the group text / a spreadsheet / 18Birdies?"

Condensed from the skeptic's value hunt (agent4-skeptic.md §VALUE HUNT), corroborated by the others.

| What the group does now | Cup Season today | Verdict |
|---|---|---|
| **Group text banter** | The Board: chat + auto-posted rounds + reactions | **Worse** for banter (three taps deep, no threads, report flag beside the reaction, zero replies anywhere); **better** for record ("nobody has to type 'shot 91'") |
| **Spreadsheet standings** | Standings tab | **Same** pre-season ("my row says 0 after I posted; the spreadsheet would at least show the 91"); **better** in-season ("best 4 a month vs your own index is a formula I'd hate to maintain by hand — that is the real spreadsheet-killer, and the app never sells it") |
| **18Birdies score / handicap** | Post a round; auto index after 3 rounds; differential receipt | **Same-ish**: the 20-second post beats hole-by-hole ("better than 18Birdies' course picker, honestly"); but now two handicaps, no GPS, no stats; the receipt explains itself better than 18Birdies does |
| **Venmo** | Pot ledger | **Replaceable**: "the pot ledger (Venmo + a text)" is on his free-tool list |
| **Calendar / tee time in the text** | Tee sheet | **Replaceable** |
| **Nothing** | The rule set applied automatically across any course, with receipts | **Not replaceable** — and "the part the app hides" |

Spec §12 names the defensible assets: "the league graph, season history, commissioner lock-in, system of record for the pot." The audit finds the graph uncaptured (no invite), the history empty (SEASON I everywhere), the commissioner blocked (lock bug), and the system of record disputed by its own screens (owed vs. collected, side-game cash off the books).

### 5.4 What must happen before monetization is pushed

1. **A season has to be seen ending well.** The ceremony (D66), the email (D68), the career record (D67) and the run-it-back card exist; nobody outside the sandbox has watched them fire. The first PIGL close is the real test. Until then every "would pay" number is a guess about a product the tester has not seen.
2. **The race has to be visible for the whole season, not the last week.** Fix the foreshadow sort; show seeds and the magic number on Home in member words; ship the clash chip on every live league and verify a row opens on the next tick.
3. **Pre-season honesty.** Six of seven testers were promised league points that did not exist. A product asking for money cannot open with a broken promise.
4. **The pot has to be true.** D106 (owed vs. collected) before any league is asked to pay a pass "out of the pot" — the pass is paid from money the Pro has, and today the app cannot say how much that is, or how a member should hand it over.
5. **The invite has to work.** An organizer who cannot lock, and cannot send a link, cannot form the league that would pay (ORG-01/02/03, N-01/05).
6. **State the price where the wizard sets the buy-in**, with D101's numbers and payer, on the web as well as the phone. Testers explicitly could not tell whether "membership" would be charged to them, to the Pro, or mid-season.
7. **Then** the focus-group instrument (D56's deck) has real surfaces to test against.

---

## Part 6 — Competitor mental model

Where the loop is genuinely better than what testers compared it to, and where it feels like administrative software — from what they actually said.

| Versus | Where Cup Season's loop is genuinely better (SEEN) | Where it reads as administrative software (SEEN) |
|---|---|---|
| **Group text** | Rounds auto-post with a band phrase; milestone stories ("broke 80 … goes on the wall"); the settlement card names who pays whom; pride stakes are archived ("the one object in the app that reads like our group text" — skeptic). | Chat is tab 2 of a room 3 taps from Home; oldest-first with the compose box under the newest post; the report flag sits beside the reaction; no replies; nothing to forward except a code. "I'd stay in the group text and let Casey run it." |
| **Spreadsheet** | The counting cap, the floor, the bye, "a better round always bumps your worst" — computed live; receipts with the differential formula ("the one screen that shows its work, and it is good"). | Bylaws rendered as a spec sheet ("PRESET Standard · VERIFICATION Attested · COUNTING CAP · §4"); three tables for two players; an unlabeled "R" column; standings that show 0 after a post with no reason given. |
| **18Birdies** | 20-second post with course/tee autofill ("better than 18Birdies' course picker, honestly"); the round means something beyond itself. | No GPS, no stats; a second handicap the golfer did not ask for; an inverted sign convention every golfer misreads (−6.7 = worse). |
| **TheGrint / GHIN** | The spec's own line: "golfer's utility vs league's competition engine" — the league engine is the thing TheGrint does not have, and the audit confirms the engine is liked where found. | "Having [my GHIN 6.4] replaced by a 3-round WHS-lite number is alarming … which number does the league use? mine or the app's?" (competitive). GHIN is "identity, not your number" — a sentence three personas could not parse. The 95% allowance appears in no calculation anyone could find. |
| **Traditional (Tuesday-night) league** | "Play anywhere, any day, any course" — the real differentiator, "stated once, in a guide card at the bottom of the You tab." No fixed tee times, no fixed course. | "The app never tells me when to play"; a Pro who "approves byes", "marks buy-ins", "draws squads", "switches the endgame" — a job description nobody told the novice she was taking. |
| **Fantasy sports** | The framing two testers reached unaided: "It's a fantasy-league-style golf season" (organizer, novice). Best-4 cap = a lineup you do not have to set; the floor = a roster you cannot ghost. | "Worse — no draft, no lineup decisions, no weekly matchups I can see" (skeptic); "Live draft night · Trades & waiver wire · SOON"; the weekly episode (D52's own diagnosis) not on screen. The category the spec names — "fantasy sports where your foursome are the athletes" (§12) — was contradicted by the one tester who compared it to fantasy and found no week. |
| **Ryder-Cup-style event** | Live match play with real strokes ("exactly the sentence golfers argue about on the first tee, and the app writes it for you" — competitive); guests without accounts; group phones. | The Ryder itself was seen only as a card: "⚔ Two teams · weekly vs-index duels · first to the clinch" — "terse to the point of jargon" (iOS). |
| **Season-long friend competitions (the thing they would invent themselves)** | Handicap-normalized bands so "a 97 from me can beat an 84 from Priya" (casual); the floor "so nobody coasts"; a Cup Final. | "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS"; "PROJECTED UNDER A GENEROUS CEILING"; "$0 collected"; a finale that is a bylaws row. |

**READ.** The loop is better *inside a round* (post, receipt, live settle-up) and *inside a month* (floor, cap, month close). It is administrative software *at the edges* — forming a league, reading the rules, understanding the ending, paying the pot — which is exactly where the organizer, the joiner and the skeptic spent their sessions.

### 6.1 What it looks like it is selling, screen by screen

The product's sentence for itself is season-long competition, rivalry with friends, and a recurring tradition (vision: "Cup Season exists to make every round of golf matter because it belongs to a season"; "Not another score tracking app. Not another handicap app."). What a tester sees:

| Surface | What it presents | Category it reads as |
|---|---|---|
| Door | "Rally your crew. Post real rounds. Take the cup." + email + invite code | scorekeeping with a prize — "not specific enough to make a skeptic sign up" |
| Home (member, forming) | Start a league · Start an event · Join a league · **Lock it in and invite your crew** · MONTH CLOSES · floor penalty | league administration |
| Welcome sheet | "You're on the pot sheet: $50 buy-in." first | a money ask — "the single most likely bail point" |
| League tab | Members & invites · Share the season · Squads · ▸ LEAGUE RULES & PRO SHOP · membership "COMING AT LAUNCH" | admin plus an upsell |
| Pot tab | $250 · $0 collected · 5 still owe · buy-in rows · "Post a stake" | a ledger |
| Board | joins, match results, one chat line, reaction + report flag | social golf, thinly |
| ⊕ → LIVE | strokes off the low man, skins riding, "JORDAN PAYS PRIYA $60" | side games — rated 8/10 by two personas |
| Standings (mid-season) | 1st · 22 over Jade · LOCKED · EVERYONE ADVANCES · Points King / Iron Man | season-long competition — the only surface that reads as the category |
| You | index, badges, "No silverware yet", rivalries 2–0 / 1–0, SEASON I | identity plus a record with nothing in it yet |

Two testers wrote the same diagnosis independently: the scoring model is "smart and fair" / "genuinely good", and "the app just doesn't tell you any of that until you dig."

---

## Part 7 — "If Cup Season disappeared tomorrow, what would the user actually miss?"

Answered by the skeptic verbatim (agent4-skeptic.md §"If Cup Season disappeared tomorrow"), corroborated by the observer and the others.

| Question | Answer |
|---|---|
| **What would they miss immediately?** | Pre-season (skeptic): "**nothing** — the season hasn't started, and my 91 lives in 18Birdies too." Mid-season (observer): the number — "1st · You lead by 22 points over Jade" — the floor bar, and Galen's 79 on the wall. Live-round users (competitive, organizer): the settlement card and the strokes line ("Casey gets 9 — the 9 hardest holes"). |
| **What would a group text or spreadsheet replace?** | "The Board, the pot sheet, the stake card, the tee sheet, 'joined the league' notices" (skeptic); plus buddies / find golfers ("we know each other") and the album ("Photos"). |
| **What would another golf app replace?** | "Posting rounds, the handicap index (18Birdies/GHIN do it with more history), course/tee lookup, the scorecard." |
| **What cannot be replaced?** | "The rule set — best-4-a-month vs your own index, the floor, the squad race, the Cup Final 'scored fresh' — automatically applied across any course, and the receipt that shows the math for every point. **That is the product. It is also the part the app hides.**" |
| **What should it become indispensable for?** | The thing only a season-long system of record can be: *the group's competitive memory* — who beat whom, by how much, the margin the cup was won by, the rivalry record, what the pot paid, "defending champs". The vision names it ("Golfers don't just post scores. They build rivalries. Win championships. Create traditions. Relive memories."); D67 and D19 build toward it; no tester could see any of it because every league is `SEASON I` with "No silverware yet". The observer's one emotional hook — "To beat Galen" — is the seed of that memory, and the product gave him no place to keep it. |

---

## Appendix A — What this audit could not observe (method limits, stated honestly)

| Limit | Effect on the findings |
|---|---|
| Headless browser: no native share sheet, clipboard denied, no push permission. | Every share / copy / notification outcome was judged on visible feedback only. "Card downloaded" and "Invite code: THEPTCQ5" are the double-fallback a real phone may never hit; the defects kept are that the fallback is invisible and that no surface prints the join URL as text except the lock share sheet that never opens. |
| No in-season play could be observed — first tee Sep 5 on both new leagues. | Week 1 is judged from a forming league. Counting rounds, month close, floor penalty, bye, squad race and Cup Final were read about, not lived, by six of seven web personas. |
| No finished season on any account. | Finale, Season+1 and Season+30 are inferred from live copy, code and the decision log. Scores there are projections and flagged as such. |
| The owner's two real leagues have exactly two players each. | "Who is my rival", "who threatens me" and "everyone advances" were trivially answered by roster size; the mid-season hump is partly an n=2 artifact. |
| The read-only observer used the owner's real account; DB check confirms 0 rounds, 0 posts written. | Posting, reactions, nudges, shares and settings could not be exercised on a live season. |
| The App Review sandbox was unavailable; the iOS survey saw static landing screens only, no taps or scrolls. | iOS findings are above-the-fold first impressions; the empty Board may be a load-timing artifact. |
| Three accounts (casual, competitive, skeptic) were contaminated by earlier runs; those agents signed out and redid the cold paths. | Day 0 is anchored on the three clean runs; the golfer-card step is cited from the earlier run's screenshots of the same accounts. |
| The weekly clash (D108) and the Cup Final race view (D105) were pushed 2026-08-28/29. | No tester saw either. Treated as "built, unobserved", not "missing". |
| The harness ran the local build at `127.0.0.1:8791`, byte-identical to prod `34d20b6` except for the version stamp. | The `v23 · __CS_VERSION__` placeholder four personas flagged is a local artifact (Netlify stamps the SHA) and is struck from the evidence. |

## Appendix B — Built-but-unobserved retention machinery (for triage)

| Mechanism | Decision | Status per code | Why no tester saw it |
|---|---|---|---|
| Weekly clash chip + posts | D52 / D108 | `week_clashes` engine pushed 2026-08-28; chip at `index.html:4583–4640` | Renders only when a row exists; no row had opened for the audit leagues. |
| Cup Final race view | D105 | `20260828170100_cup_final_race.sql`; client at `index.html:14605` | Only during `status = cup_final`. |
| Season-long foreshadow | D4 | `#statFinal` option at `index.html:9627` | Suppressed by the nearest-deadline sort until the last week (1 of 155 days for Fellas). |
| Seed / magic-number line | D24 | `renderScenarioLine`, `index.html:14802+` | Rendered ("HAS LOCKED A CUP SEED", "EVERYONE ADVANCES") without any explanation of the words. |
| Season-end takeover + per-person payout | D66 | `csSettlement`, `index.html:11657` | No completed season. |
| Season-end email | D68 | `season-email/index.ts` ("The Cup goes to … by …") | No completed season. |
| Career record / titles | D67 | `career_record()` | Nothing to aggregate. |
| Run it back | D41 | `runItBack`, `index.html:14382` | No completed season; new league id; "defending champs" deferred. |
| Month-close podium | D53 | `20260727160000_board_voice.sql` | Both observer leagues' first close was a partial month → administrative line only. |
| Named rivalries | D19 | `openNameRivalry`, `index.html:13471` | Records shown; naming two taps deep; no rival chosen by the app. |
| Pot owed vs. collected | D106 | **PROPOSED** | Ceremony still pays from stake × roster. |
| Personal stake line | D51 | decided; post-screen build pending; Home surface an open remainder | — |
| Pricing surfaces | D56 / D101 | iOS behind `pricing.visible=false`; web copy "COMING AT LAUNCH" | No price seen by anyone. |
| Continue-your-round banner | (live rounds) | live-resume query at `index.html:7800` fails on a PostgREST embed ambiguity | Never rendered for anyone; logged on every Home load after a live round. |

## Appendix C — Persona score sheet (as reported; run 2 shown for re-run personas)

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
| **Mean** | 5.1 | 4.1 | 4.0 | 5.1 | 5.6 | 5.8 | 5.1 | 4.4 | **5.75** | **3.75** | 3.75 |

*sideGames* and *gameplay* are the highest columns; *rules*, *setup* and *pay* the lowest. The mechanic is liked; its legibility, its setup and its price are not trusted.

## Appendix D — Test footprint (for cleanup)

Accounts `jerecho+blind1..6@fischbeck3.com` and `jerecho+blind2x@fischbeck3.com`. Leagues **The Papago Grind** (code `THEPTCQ5`; organizer +blind1; members +blind2/3/4/6) and **Desert Dogs** (code `DESEUU0K`; +blind5, one member). Inside those leagues only: posted rounds, a $5 match-play story, guest "Marco", a skins round with attested cards written to +blind1/2/3 (Casey, Marcus, Jordan) by +blind4's live game, pride stakes, tee-sheet entries and board messages. The observer and iOS survey used the owner's real account read-only; the DB check confirms 0 rounds and 0 posts written by them.

## Appendix E — Claims struck or downgraded in validation (so nobody chases them)

| Claim as reported | Validation outcome | What survives |
|---|---|---|
| `v23 · __CS_VERSION__` on the door "reads as unfinished software" (four personas) | **Struck.** Local unstamped build; prod reads `v23 · <sha>` (CLAUDE.md rule 2). | Nothing. |
| Observer: "0/2 in · 2 still owe" above "[Jade ✓] [Jerecho Fischbeck ✓]" (`obs/12-on-the-line.jpg`) | **Struck as stated.** The check glyph is in the DOM for every row and hidden by `color:transparent` until paid (`index.html` ~485–498); the accessibility text dump exposed it; a human sees empty boxes (`join/55-AH-pot-after-tap.jpg`). | Non-Pro payer rows are `<button>`s whose only behaviour is a 1.5-second toast; no payment note or due date exists in the schema (`buy_ins` has amount/paid/marked_by/marked_at only); screen readers read unpaid rows as paid. |
| "Home shows one league only — stack a row per league" | **Downgraded to a decision.** D81 chose one hero slot; D94 measured and rejected the four-quadrant Home; the Clubhouse chips are the switcher. | The false toast "Switch groups anytime from Home" (`index.html:17536`); the retention cost (the losing league invisible) stands as a decision to revisit, not a bug. |
| "No gap or rival line on Home" | **Overstated.** `heroMyRung` renders "You lead by 22 points over Jade" / "10 points back of Galen" / "You passed X this week". | What is missing is the what-if line (D51's Home remainder) and any app-chosen rival at n > 2 outside the unseen D108 chip. |
| "Membership coming with no price" as a defect | **Downgraded.** "COMING AT LAUNCH · THE PILOT RIDES FREE" is the decided pilot posture (D56/D101: no pricing on the front door, checkout parked to the first anniversary). | D101 fixed the price, payer and unit on 2026-08-27 and the web carries none of it; "who pays, when, on top of the buy-in?" is unanswered by the posture itself. |
| "Share the invite link gives only a code" | **Partly harness.** `shareInvite()` tries `navigator.share`, then clipboard, then the bare-code toast; a real phone gets the OS sheet. | No surface prints the join URL as text with Copy except the lock share sheet, which never opens because of the `staged` bug. |
| "The lock bug stalled seven pilot Pros" | **Misattributed.** The `index.html:10080` comment measured the CTA-less forming hero before D97 introduced the bug. | The bug itself: 11 of 12 lock attempts in prod history failed, all on 2026-08-29; the one success predates D97. |

---

*Companion documents in this folder: `README.md` (start here) · `blind-ux-audit.md` (master report) · `critical-findings.md` · `user-journey-map.md` · `gameplay-loop.md` · `rules-and-mental-model-audit.md` · `issues.json` / `issues.csv` / `issues-counts.json` (`issues-README.md`) · the six `synthesis-*.md` files · `raw/` · `screenshots/`.*
