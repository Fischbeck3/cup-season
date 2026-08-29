# Blind UX audit — Agent 3: Golf League Novice ("Dana Whitfield")

- Persona: 20+ years of golf, ~18 handicap, has NEVER run or joined a golf league. Buddies said "you set it up."
- Account: jerecho+blind5@fischbeck3.com · Session `nov` · App: http://127.0.0.1:8791/ (phone-sized headless browser)
- Screenshots: `../screenshots/nov/`
- Key question: **Can this person create/join a season and understand the rules without outside instruction?**

Blind rules were followed: nothing was learned from any file, spec or source; only from the running screens.

---

## Timeline

| UTC | Event |
|---|---|
| 13:18:42 | Session started, app opened cold (Journey A answers written before any tap) |
| 13:19:35 | Continue with email → email entered → Go (13:19:52) |
| 13:19:51 | Sign-in code email arrived (instant); auto-verified on 8th digit ~13:20:18 |
| 13:20:18 | Golfer card: name, handle (auto-changed to @dana), index 18.2, GHIN peeked, marker |
| 13:21:48 | Save my card → "Four places. Two ways to play." orientation |
| 13:22:35 | Take me in → league-less Home |
| 13:23:09 | Start a league → name sheet (empty-name tap did nothing) |
| 13:24:22 | Named Desert Dogs → wizard step 1 (Pro = me) |
| 13:24:43 | Step 2 competitiveness; (i) read; Customize opened (13:26); buy-in/season stepped (13:29:50) |
| 13:30:52 | Step 3 review: "Minimum four to tee off" first seen |
| 13:31:21 | LOCK tapped → "Lock failed" toast; console `staged is not defined`; 6 attempts incl. Solo retry to 13:33:22 |
| 13:33:37 | Reload → Home says "SEASON LIVE — Rounds count from today" — lock had succeeded on attempt 1 |
| 13:34:06 | Clubhouse: "BEFORE FIRST TEE… practice rounds hit your card, not the season"; code DESEUU0K at page bottom |
| 13:35–13:36 | League tab; rules disclosure; "How scoring works" sheet found (4 taps deep) |
| 13:37 | Members & invites; Share link = 1.5 s toast of the code; Add golfers can't find an email |
| 13:39:56 | Squads › Draw squads → generic "Draw failed" (console had the real reason) |
| 13:40–13:43 | Schedule calendar (Sunday dots = week closes); Pot; Board; Album |
| 13:43:59 | ⊕ door → Post a round form; Q1–Q9 answered from the UI |
| 13:45:59 | Ken McDonald found, White tees autofill 68.7/115 |
| 13:47:11 | 46/45 entered → preview "5 pts · -3.7 vs your index" |
| 13:47:26 | Posted. Card "91 · 3.7 over your number · COUNTS ON YOUR CARD"; 3 stacked dialogs |
| 13:49:03 | Receipt sheet: differential formula shown; no points; no edit/delete |
| 13:49:40 | Standings unchanged: 0 pts, 0 counting rounds |
| 13:50–13:55 | You tab; How-it-works explainers; Card & settings (city/home course saved on 4th attempt) |
| 13:56:03 | LIVE door: set up Papago · White, guest Mike, Skins $2 |
| 13:59:57 | Tee off → live scoring; two holes scored (14:01:48); scrapped (14:02) |
| 14:03 | NEXT tile = calendar; tee-sheet form; Post a stake form (pride, never money) |
| 14:04:22 | Terms page read; return to app shows sign-in door ~8 s (boot stall) then Home |
| 14:05:21 | Session stopped |

---

## JOURNEY A — DISCOVERY (signed out, cold open)

**Screen: the door** — `../screenshots/nov/01-door.jpg`

What is on screen (exact copy): an orange flag-in-cup logo; "CUP SEASON"; three-line tagline "Rally your crew. / Post real rounds. / Take the cup." (last line in orange); orange button **[Continue with email]**; dark button **[I have an invite code]**; "By continuing you agree to the Terms & Privacy Policy."; footer `v23 · __CS_VERSION__`.

- **3 seconds:** Golf (flag), the word "cup", "crew". Two buttons. It is a golf thing for a group.
- **10 seconds:** "Post real rounds" — I will type in scores I actually shot. "Take the cup" — there is a prize/trophy. "Rally your crew" — I am supposed to bring my friends. The invite code button tells me somebody else could have sent me a code, but nobody did, so I'm the one who starts.
- **30 seconds:** I could tap Continue with email. That is the only thing to do. There is no "learn more", no "how it works", no screenshots, no pricing. I have to sign up to learn anything.
- **Noticed:** the footer literally reads `v23 · __CS_VERSION__` — looks like a broken template variable. A non-technical user would not know what it is, but it looks unfinished. (Evidence: 01-door.jpg, bottom.)
- **Terms/Privacy:** As a person told "you set it up," I might glance at Terms to see if money is involved. I did NOT tap them at this point — a real golfer would tap the big orange button. (Revisited later, see below.)

### First honest answers (BEFORE using the app)

1. **What does the app do?** Track golf rounds you actually play, with a group of friends, and somebody wins a "cup" at the end of a "season." Beyond that, no idea.
2. **Primary action?** "Continue with email" — i.e. sign up. In-app, presumably "post a round."
3. **What is a "season"?** Guess: a stretch of time (summer? a few months?) during which rounds count. Not stated anywhere.
4. **What is a "league"?** The word does not appear on the door at all. "Crew" is used instead. I assume a league = my group of friends.
5. **What is a "cup"?** A trophy. Whether it's a real thing, a badge, or money — unknown.
6. **What are you competing for?** "The cup." Bragging rights? Money? Unknown.
7. **Who are you competing against?** "Your crew" — my buddies. Whether it is individual vs individual or teams — unknown.
8. **How do rounds work?** "Post real rounds" — I go play golf anywhere, then type my score in. Whether it's gross, net, stableford, whether the course matters — unknown.
9. **What happens after a round?** Nothing is said. I assume some kind of leaderboard updates.
10. **What makes this different from just playing golf with friends?** Presumably it keeps score across many rounds and crowns a winner. The door does not say.

USER ASSUMPTION: "Rally your crew" means I invite my friends and we're all in one group competing head to head.
ACTUAL PRODUCT BEHAVIOR: (to be determined)

USER ASSUMPTION: "I have an invite code" is for people who were invited by someone else; I don't have one so I ignore it.
ACTUAL PRODUCT BEHAVIOR: (to be determined)

---

## SIGN-UP & ONBOARDING (13:19:35 → 13:21:48 UTC, ~2m15s including email fetch)

**Screen: email entry** — `02-email.jpg`. Tapping **[Continue with email]** reveals an email box (placeholder `you@email.com`) and a **[Go]** button in-place. Fine.

**Screen: code entry** — `03-code-sent.jpg`. After Go (13:19:52): a `CODE FROM EMAIL` box, **[Verify]**, green mono text "Sent to jerecho+blind5@fischbeck3.com. Type the sign-in code from the newest email." and "Resend code (27s)" countdown. The email (subject "Confirm your email address", body "Welcome to Cup Season Your sign-in code: 37554901 ... The code expires in an hour.") arrived at 13:19:51 — effectively instant. Typing the 8 digits auto-submitted (I never got to tap Verify — the harness reported the button gone before my tap landed). Signed in at ~13:20:18. **Nice.** One nit: the email subject says "Confirm your email address" while the screen calls it a "sign-in code" — a small mismatch a nervous user notices when scanning their inbox.

**Screen: golfer card** — `04-after-verify.jpg`, `05-card-2.jpg`, `07-ghin.jpg`, `08-card-filled.jpg`
Copy: "✓ SIGNED IN · Set up your golfer card. · Just a name and a marker to start — this card follows you into every league."
Fields:
- NAME ON THE CARD (placeholder "First name or nickname")
- YOUR HANDLE — HOW BUDDIES FIND YOU (prefilled `@jerechoblind5`, "A starting handle — tap to change it.") — when I typed "Dana" in the name field the handle silently changed itself to `@dana` (I had not touched it). Helpful, but I didn't ask for it and my css attempt to edit the old value failed because it had already changed. "@dana is available ✓" shown in green at the bottom.
- HANDICAP INDEX · OPTIONAL (placeholder "e.g. 12.4"): "Know your index? Enter it as a starting point — otherwise your first three rounds set it, and it keeps adjusting as you play." → I entered 18.2.
  - USER ASSUMPTION: the app will use MY index (18.2) for the season. ACTUAL: the copy says it is only "a starting point" that the app overrides with its own calculation after rounds. So the app runs ITS OWN handicap system. As a 20-year golfer with a GHIN, this raised an eyebrow: whose number wins, mine or the app's? Not explained.
- **[+ Add your GHIN number]** → reveals "GHIN # · e.g. 1234567" with: "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." — I read this three times. "That's identity, not your number" is cryptic. If it does not bring my index in, why would I type it? Left blank.
- BALL MARKER: 14 tiles with small line icons: THE SAGUARO, THE ISLAND, THE LIGHTHOUSE, THE LONE TREE, THE PEWS, THE DUNES, THE BEVERAGE, THE SHARK, THE AZALEA, THE JUG, THE WEE BRIDGE, NO. 2, THE POSTAGE STAMP, THE THISTLE. Nothing says what a "ball marker" does in the app. I assume it is my avatar/icon. Picked THE SAGUARO (I'm in Arizona).
- Footer note: "City and home course live on your card — add them any time from the You tab." So I could NOT enter Ken McDonald here; deferred.
- **[Save my card]** → 13:21:48.

**Screen: "Four places. Two ways to play."** — `09-home-first.jpg` (shown immediately after saving the card)
Copy verbatim: "Thirty seconds, then you're in." · Home — EVERYTHING YOU'RE IN, ONE FEED · Clubhouse — ONE LEAGUE: TABLE, BOARD, POT · The ⊕ — BEFORE, DURING AND AFTER A ROUND · You — YOUR CARD, RECORD AND BUDDIES · THE LONG GAME / A league — MONTHS. EVERY ROUND COUNTS TOWARD A TABLE. · THE SHORT GAME / An event — A WEEKEND OR A FEW WEEKS. ITS OWN LITTLE TROPHY. · "You can run both at once. An event stands alone, or attaches to a league." · **[Take me in]** · "Reopen this any time from You › How it works."

- OBSERVATION: This is the first time the app tells me anything about the concept. "Pot" — so there IS money. "Table" — I guess a standings table. "Board" — no idea (a leaderboard? a message board?). "The ⊕" — a symbol with no name; the tab bar underneath says "Post", so the orientation card and the tab bar call the same thing two different names.
- INTERPRETATION: League = long (months, points toward a table). Event = short (weekend). Good, that distinction lands.
- IMPACT: I still do not know what "cup" means, how points work, or whether "pot" is real money I have to collect. (P1 comprehension — see issues.)

---

## HOME (league-less) — `10-home-empty.jpg`, `11-home-empty-2.jpg` (13:22:35)

Top: three chips **[Start a league] [Start an event] [Join a league]**. Copy: "Post a round — it counts on your card. Leagues score it when you join one." Card "YOUR CARD — Three rounds and your index goes live. **Nothing else needed.** INDEX ●——— 0 OF 3 **[Post your first round]**". Three tiles: LEAGUE / None yet / JOIN OR START · NEXT / Open / PLAN A ROUND · BOARD / — / LEAGUE ONLY. Then: "Monthly floor · **2 rounds a month**. Miss it and your squad loses 5 points for every round you're short. Short months are waived." Then "— AROUND YOUR BUDDIES — No rounds from your buddies yet. Post one, or add some buddies." Bottom bar: HOME · CLUBHOUSE · YOU with a big orange **+** floating button in the middle (the tab bar in the accessibility tree calls it "Post a round").

- OBSERVATION: I typed 18.2 as my index sixty seconds ago; the home card says "INDEX 0 OF 3" and "Three rounds and your index goes live." My number is nowhere. USER ASSUMPTION: my 18.2 was thrown away. ACTUAL: unknown at this point (revisited on the You tab later).
- OBSERVATION: A rule about "Monthly floor", "your squad", "5 points" and "Short months are waived" is shown to a user who has no league, no squad, no points. INTERPRETATION: leaked from the league context. IMPACT: a novice reads "squad" here before the app has ever said what a squad is. (P2 comprehension)
- OBSERVATION: The orange + button physically covers the words "BUDDIES" / "buddies yet" in the AROUND YOUR BUDDIES section at the default scroll position (10-home-empty.jpg). (P3 visual-hierarchy) The same button later covers the wizard's summary sentence (15-wizard-step2.jpg: "Standard: 95% handicap, [+] posted rounds…").
- "NEXT / Open / PLAN A ROUND" — what is "Next"? Next round? Next week? I did not tap it yet.
- "BOARD / — / LEAGUE ONLY" — still no idea what a board is.

---

## JOURNEY C — CREATE A LEAGUE (13:23:09 → …)

### C1. Name sheet — `12-wizard-1.jpg`, `13-wizard-2.jpg`
Tapped **[Start a league]** (1 tap). Bottom sheet: "Name your league — THE BANNER EVERYTHING HANGS UNDER", placeholder "The Big Slice, The Sunday Cup, Dew Sweepers…", note "You can rename it any time before the bylaws lock.", button **[Start the league]**.
- Tapped [Start the league] with the field still empty (my first fill attempt failed): **nothing happened — no message, no shake, no red text** (13-wizard-2.jpg is identical to 12). A person would tap again and wonder if the app is broken. (P2, navigation)
- "bylaws lock" — first appearance of "bylaws" and of "lock". Not defined. What I think it means: the league's rules freeze at some point.
- Named it **Desert Dogs** → [Start the league] (13:24:22). A toast said "Desert Dogs is on the books — set the bylaws" (seen only in the accessibility tree; it had already gone by the time the screenshot fired). So the league now EXISTS before I've set anything, and the button said "Start" when it really meant "Next".

### C2. Wizard step 1 of 3 — `14-wizard-3.jpg`
Header "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE", 3-segment progress bar. LEAGUE NAME "Desert Dogs". "PRO — THAT'S YOU: Dana @dana · you run this league · THE PRO". [Cancel] [Next →].
- "Pro" = me, the organizer. OK, I get it from "you run this league". But the golf word "Pro" already means the club professional; for a beat I thought the app was assigning me a pro.
- "Locks at first tee" — I now think: the settings freeze when the season starts. Still an assumption.
- What I think I'm doing: naming the league and confirming I'm in charge. Consequence clear? Mostly.

### C3. Wizard step 2 — Competitiveness — `15-wizard-step2.jpg`, `17-wizard-step2-info.jpg`
Heading "COMPETITIVENESS — PICK ONCE, ARGUE NEVER" with an (i). Three cards:
- **Casual** — "Honor scores, everything counts" — `100% hcp · honor scores · any course · unlimited counting · no floor`
- **Standard** (pre-checked, orange edge) — "Weekly-golfer fair, light guardrails" — `95% hcp · GHIN rounds · best 4 / mo count · 2-round floor`
- **Cutthroat** — "Tournament-tight, receipts required" — `90% hcp · verified + attested · rated tees · best 4 / mo · 3-round floor`
Summary line: "Standard: 95% handicap, GHIN-posted rounds, your best 4 a month count, post 2 or the squad feels it. The default for a reason." Buttons **[Use these defaults →]** and **[Customize]**, then [← Back] [Next →].
The (i) says: "One pick that bundles the fairness rules: handicap allowance, score verification, and eligible courses. Casual is honor-system beer league, Standard wants GHIN-posted rounds, Cutthroat adds attestation and rated tees. Every individual dial unlocks with Pro Shop."

Terminology I could not resolve from the screen:
- "95% hcp" — I know tournaments sometimes play 95% of handicap but a novice organizer has no idea why 95 vs 100 vs 90, or what it changes for an 18 handicapper (17 strokes? 17.1?).
- "GHIN rounds" — does this mean players must ALSO post to GHIN? Does the app check? Ten minutes ago the golfer card told me GHIN is "identity, not your number". Contradiction in my head. (P1 terminology)
- "best 4 / mo count", "2-round floor", "unlimited counting", "no floor" — compressed jargon. The Customize section eventually explains "counting cap" and "participation floor", but only if you tap Customize.
- "verified + attested", "rated tees", "receipts required" — attested by whom, how? Not explained anywhere I found.
- "the squad feels it" — I still have not been told what a squad is at this point.
- "Pro Shop" — appears twice ("Every individual dial unlocks with Pro Shop", "Live draft night… is on the Pro Shop roadmap"). Sounds like a paid tier. Never defined, never linked. (P2 monetization/terminology)

### C4. Customize (tapped, 1 tap) — `18-wizard-customize.jpg`, `19-wizard-customize-full.jpg`, `20-cust-a.jpg`, `24-cust-top.jpg`
The [Customize] button reveals a long list. **Nothing on the Standard card warned me that these existed** — a person who taps "Use these defaults →" accepts all of the following without seeing them:
- **Buy-in — Per player · $0 = bragging rights — $75** (DEFAULT). (!!!) A $75-per-head stake is the default and it is hidden behind "Customize". As the person told "you set it up," I would have sent my buddies a league with a $75 buy-in without knowing. (P0 monetization/comprehension — see issue list)
- Stepper values by tapping −/+: None → $25 → $50 → $75 → $100 → $150 → $200. **No way to enter $10 or $20.** One tap of − from $75 goes straight to "None".
- **Season length — Weeks or months · ends the same weekday — 6 mo** (DEFAULT). Stepping down: 5 mo, 4 mo, 3 mo, 2 mo, 2 mo (the label read "2 mo" for BOTH "Sat Sep 5 – Sat Nov 14" and "Sat Sep 5 – Sat Oct 31" — the caption changes, the label doesn't). I set 3 mo.
- **First tee — Sat Sep 5 – Sat Dec 5 — [2026-09-05]** date picker. "First tee" = start date. Defaults to next Saturday. Fine, though "first tee" as a label for a date took a second.
- **TEAMS (i): [Solo] [2 Squads] [3 Squads] [4 Squads]** — the highlighted option is **2 Squads**, but the caption underneath reads "**4 squads** · the full cup experience for 8+ players." and then in orange "1 golfer staged — solo fits. Bigger squads open up as more join, by code or invite." Three contradictory signals on one control: highlight says 2, caption says 4, warning says solo. (P1 comprehension/visual-hierarchy). The (i): "How the league is organized. Solo means everyone competes individually: no squads. Squad modes split the league into teams the Pro assigns or draws; more squads want more players (4 squads plays best at 8+)." — THIS is the first definition of "squad" (= team), and it is behind an (i) on an optional Customize panel.
- **HOW TEAMS FILL (i): [Blind draw] [Assign]** — "Blind draw: the server shuffles every joined player into squads and posts the reveal. Argument-proof." (i) adds "Live draft night with picks and a clock is on the Pro Shop roadmap." Clear enough.
- **HOW IT ENDS (i): [Cup Final] [Points table]** — "Cup Final: the last four weeks reset and score fresh — top seeds only, whoever's hottest takes the cup." (i): "Points table crowns whoever leads when the season ends: the whole year is the race, no reset." First time the word "cup" is explained, and it is explained as a *playoff*. "Top seeds only" — how many? Not stated. What happens to non-seeds in those last four weeks? Not stated.
- **THE POT SPLIT (i): [Balanced] [Winner-heavy] [Spread it]** — "Balanced: champ 60% · runner-up 25% · Points King 15%." (i): "…the Points King (best individual all year). The pot lives on the books here — the app keeps the ledger, money moves friend-to-friend." So: the app does NOT collect money; I do. Important, and only visible if you tap an (i) inside Customize. "Points King" — new term.
- **Counting cap (i) — Best N rounds / month — Best 4** — (i): "The core fairness dial. Only your best N rounds each month score for the squad, so the retiree who plays daily can't bury the dad who plays weekly. A better round automatically replaces your worst counter, so posting never stops mattering." Good explanation — the best copy in the wizard.
- **Participation floor (i) — MIN ROUNDS / MONTH · −5 SQD PTS SHORT — 2 / mo** — (i): "The anti-ghosting rule. Every player must post at least this many rounds a month, or the squad takes a penalty: −5 points per round short under Standard rules. One Pro-approved bye month per season covers vacations and injuries." — "bye month" is new, and "Pro-approved" means I'll be adjudicating my friends' vacations. Nobody told me that would be my job.

Decisions I made and why (as a novice):
| Setting | Default | What I chose | Could I have chosen without a league nerd? |
|---|---|---|---|
| Competitiveness preset | Standard | Standard (kept) | Partly — I'd keep the default because I don't understand 95% vs 100% |
| Buy-in | **$75** | $25 | Yes, but ONLY because I opened Customize; otherwise $75 by accident |
| Season length | 6 mo | 3 mo | Yes |
| First tee | 2026-09-05 | kept | Yes |
| Teams | 2 Squads (highlighted) / "4 squads" (caption) | kept 2 Squads | No — I don't know what a Cup Final looks like with 2 squads vs solo, and the control contradicts itself |
| How teams fill | Blind draw | kept | Yes |
| How it ends | Cup Final | kept | No — I can't picture what "top seeds only" means for a 3-person league |
| Pot split | Balanced | kept | Sort of |
| Counting cap | Best 4 | kept | Yes after reading (i) |
| Participation floor | 2 / mo | kept | Yes after reading (i) |


### C5. Wizard step 3 — Review & lock — `28-wizard-step3.jpg`, `29-wizard-step3-top.jpg` (13:30:52)
"Review the bylaws, then lock it in". Table: STRUCTURE 2 squads · Squad formation Blind draw · PRESET Standard · HANDICAP ALLOWANCE 95% · **VERIFICATION Attested** · COUNTING CAP Best 4 / mo · PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short · BUY-IN $25 / player · POT SPLIT 60 / 25 / 15 · champ / 2nd / king · SEASON 3 mo · Sat Sep 5 → Sat Dec 5 · 13 wks · CUP FINAL Final 4 weeks · from Sun Nov 8 · scored fresh.
Footer: "Lock opens the invite link — one link fills the league; anyone can also join later with the league code. **Minimum four to tee off.**" Button **[Lock the bylaws & form the squads]**, [← Back].
- OBSERVATION: "Minimum four to tee off" is revealed on the LAST step. I have three people total. Nothing earlier said four. (P1 rules/onboarding)
- OBSERVATION: VERIFICATION reads "Attested" for the Standard preset, whose card said "GHIN rounds"; the Cutthroat card was the one that said "verified + attested". I cannot tell what will be demanded of my friends when they post. (P2 terminology)
- OBSERVATION: The wizard auto-scrolled so the top of the review table was cut off (28-wizard-step3.jpg starts mid-table); scrolling up was flaky in the harness.
- "form the squads" with one player — I hesitated: am I about to draw teams with just me in them? The copy says "Lock opens the invite link", so I must lock to invite. Catch-22 for a novice: you must commit before you can rally anyone.

### C6. **THE LOCK BUG (P0)** — `30-after-lock.jpg`, `31-lock-retry-immediate.jpg`, `33-lock-fail-toast.jpg`, `34-reload-home.jpg`
- 13:31:21 tapped **[Lock the bylaws & form the squads]**. Screen did not change. A white toast "**Lock failed. Something went wrong — please try again.**" appeared for ~1.5 s (measured: toast opacity 1 → 0 within 1.7 s) at the bottom of the screen and vanished. Console: `[cs] error: Lock failed. staged is not defined`.
- Tapped again ×3 (13:31:52) — same toast, same console error each time.
- Went [← Back], switched Teams to **Solo** (the review then read "STRUCTURE Individual — no squads" but STILL "Squad formation Blind draw", "−5 sqd pts" and the button still said "form the squads"), [Next →], Lock again ×2 — same failure. **6 attempts, ~2 minutes.**
- 13:33:37 reloaded the app (what a person does when an app says "try again" six times). Home now says: "**DESERT DOGS · SEASON LIVE — The season's on. Rounds count from today.** ROSTER ●—— 1 IN · MONTH CLOSES in 2 days". So the lock had in fact SUCCEEDED on the first tap; the app told me it failed, five more times.
- Clubhouse (13:34:06) shows the league with **2 squads** ("Squad 1", "Squad 2", "SQUADS LOCKED") — i.e. the FIRST attempt (2 squads) is what stuck; my later Solo choice was ignored, and I was never told.
- INTERPRETATION: a client-side crash after the server call; user sees a false failure. IMPACT: A novice would either (a) give up ("the app is broken"), (b) hammer the button, or (c) create a second league. It also silently burned "Minimum four to tee off" — the league locked and squads "formed" with one golfer. **Journey C is technically complete but the user experience of completing it is a failure message.**
- Also: Home says "SEASON LIVE — Rounds count from today" while the Clubhouse, 10 seconds later, says "**BEFORE FIRST TEE — First tee Sat Sep 5 — KICKS OFF IN 7 DAYS · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON**". Two screens, opposite statements about whether my rounds count. (P1 comprehension)

---

## CLUBHOUSE — first look — `35-clubhouse-1.jpg`, `36-clubhouse-full.jpg` (13:34:06)
Header: "YOUR GROUPS — [Desert Dogs HERE]". Card: "Desert Dogs · Before first tee — Sat Sep 5 · Sat Sep 5 → Sat Dec 5 · 13 wks · THE PRO · DANA · **Cancel & delete this league** (only possible before the first tee)". Sub-tabs: **Standings · Board · Schedule · Pot · Album · League**.
Standings tab content, top to bottom:
- Orange card "BEFORE FIRST TEE — First tee Sat Sep 5 — KICKS OFF IN 7 DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"
- "SEASON RACE · THE CLIMB" — 01 Squad 1 0 · "TOP SEED · +10" · 02 Squad 2 0 -0 · "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING"
- "STANDINGS" table: SQUAD / TREND / Δ WK / PTS — 01 Squad 1 CAPT. — WK 1 0 0 · 02 Squad 2 CAPT. — WK 1 0 0
- Tiles: SEASON — / 13 First tee Sat Sep 5 · THE POT $25 0/1 buy-ins in · YOUR INDEX 18.2 Season to date · COUNTING ROUNDS 0 / 4 ○○○○ August · your best 4 count
- "NEXT UP · KICKOFF — First tee Sat Sep 5. Practice rounds hit your card, not the season. [Live round]"
- "ON THE LINE $25 — CHAMPS $15 · RUNNER-UP $6 · POINTS KING $4 · $0 COLLECTED →"
- "THE INDIVIDUAL RACE · EVERY PLAYER" — POINTS KING — · MOST IMPROVED · NEEDS 2+ ROUNDS — · IRON MAN — · table PLAYER / R / AVG VS INDEX / PTS: 01 Dana 0 — 0
- "Points King takes 15% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with the squad race — bylaws §4."
- Buttons **[Code · DESEUU0K]** **[Add golfers]**

Reactions:
- **My index 18.2 IS here** ("YOUR INDEX 18.2 · Season to date"). Home said "0 of 3". Same number, two stories.
- "TOP SEED · +10", "TOP 1 ADVANCE", "PROJECTED UNDER A GENEROUS CEILING" — I do not know what any of these mean. +10 what? Why does Squad 1 have +10 with zero rounds? What ceiling? (P1 comprehension)
- "CAPT. —" — squads have captains? Who picks them? Not explained.
- "Δ WK", "WK 1", "TREND" — column headers for a table with no data.
- "COUNTING ROUNDS 0 / 4 · August · your best 4 count" — it is counting AUGUST, but the season starts Sep 5. The tile contradicts the "practice rounds hit your card, not the season" card directly above it.
- "Points King / Most Improved / Iron Man" — three side prizes, explained in one sentence at the bottom. "bylaws §4" — a document I have never been shown.
- The league code **DESEUU0K** is a button at the very bottom of a long page. As the organizer, the invite is the thing I need most, and it is last.
- "Cancel & delete this league (only possible before the first tee)" in red is the third line of the league card — more prominent than the invite.


## CLUBHOUSE › League tab — `37-club-league.jpg`, `38-club-league-full.jpg`, `40-rules-expanded.jpg` (13:35)
Cards: "Members & invites · 1 PLAYER [View]" · "🔗 Share the season · A public page — the standings so far, no account needed [Link] [✕]" · "Squads · Complete · rosters locked [View]" · collapsed disclosure "▶ LEAGUE RULES & PRO SHOP".
Expanding the disclosure shows "The bylaws · locked at first tee" (same table as the wizard review), a button **[Finish: Cup Final — switch to points table]** (so the endgame is NOT locked — "locked at first tee" apparently means "locked in a week"), **[How scoring & handicaps work →]**, and "The Pro Shop — CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE — SOON Custom rules, every dial unlocked · SOON Live draft night with pick timer · SOON Trades & waiver wire · SOON Multi-season history & records · [Coming at launch] (disabled)".
- So "Pro Shop" = a future paid membership. The wizard used the term three times before this definition. As a novice I still don't know whether I will be charged anything for THIS league. "THE PILOT RIDES FREE" — am I "the pilot"? (P2 monetization)

## "How scoring works" sheet — `42-scoring-a.jpg`, `43-scoring-b.jpg` (13:36:19) — **4 taps deep, behind a collapsed disclosure**
Path: Clubhouse → League → expand "League rules & Pro Shop" → "How scoring & handicaps work →". Content (verbatim):
- "YOUR NUMBER — Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted 3 rounds; until then it shows as building. You (or the Pro) can set a starter to get going sooner — but once you have 3 posted rounds, your scores take over. Manual changes are announced to your league so the crew keeps everyone honest."
- "EVERY ROUND → CUP POINTS — Every round is scored against your own number — a 22-index beating their number is worth exactly what a 6-index beating theirs is: Torched it · beat it by 3+ · 12 pts / Beat your number · by 1–3 · 9 pts / Played to it · within 1 · 7 pts / A little loose · 1–3 over · 6 pts / Posted anyway · rough day · 5 pts. The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. You can't hurt your squad by playing badly — only by not playing."
- "WHAT COUNTS — Your best rounds each month count for your squad — a better round always bumps your worst counter — and everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your season bye covers you automatically — life happens; the floor bites from the second miss. Your league's exact numbers are in League rules."
- "THE MONEY — The pot is on the books — Cup Season keeps the ledger and shows a settlement card; the money moves between you."
- This is THE page. It answers points, handicap, floor, bye and money in 250 words. It is not linked from Home, not from onboarding ("Four places"), not from the wizard, and not from the Standings tab where the numbers appear. A novice would find it only by accident. (P1 comprehension/navigation)
- Gap: it never says what "95% handicap allowance" does to "your own number". Does an 18.2 play as 17.3? Where is "beat it by 3" measured — net vs par? Differential vs index? Not stated.

## Members & invites — `44-members.jpg`, `45-share-link.jpg`, `46-add-golfers.jpg`, `47-search-email.jpg`, `48-share-instead.jpg` (13:37)
Sheet "Members & invites — 1 PLAYER · CODE DESEUU0K — Dana · THE PRO · @dana · INDEX 18.2 · [Marker here] — [Add golfers] [Share the invite link]".
- **[Share the invite link]** → a white toast "**Invite code: DESEUU0K**" for ~1.5 s. No link shown, no share sheet in this browser, no "copied" confirmation. I never saw a URL. USER ASSUMPTION: something was copied to my clipboard. ACTUAL: unknown; clipboard read is denied. (P1 social — the single most important organizer action ends in a 1.5-second toast)
- **[Add golfers]** → "Add golfers — INVITED GOLFERS GET A NOTIFICATION AND CHOOSE TO JOIN — [Find golfers by name or @handle]". I typed my friend's email `jerecho+blind6@fischbeck3.com`: "No golfers found. Invite links still work for everyone else." Typed "Mike": same. **There is no way to invite someone by email or phone number.** My two buddies do not have accounts; the only route is the invite link/code I can't see. (P1 social/onboarding)
- **[Share an invite link instead]** → same toast "Invite code: DESEUU0K". Sheet stays open.
- The app never tells me what happens if my friends never join: no "pending" state, no reminder, no "2 invited, 0 joined". There is nothing to track because nothing was sent.

## Squads › View — `52-form-squads.jpg`, `53-after-draw.jpg` (13:39:56)
The League tab card says "Squads · Complete · rosters locked". Tapping [View] opens a full screen "FORM SQUADS · BLIND DRAW — 1 in the pool — THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW — [Draw squads] — Squad 1 · 0 PLAYERS · Empty — Squad 2 · 0 PLAYERS · Empty — PLAYER POOL / THE POOL — [Dana]".
- "Complete · rosters locked" vs "0 players / Empty / Draw squads": the card and the screen disagree. (P1)
- Tapped **[Draw squads]**: toast "**Draw failed. Something went wrong — please try again.**" The console had the real, useful message: `Draw failed. Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.` The user gets the generic one. (P1 — the helpful copy exists and is hidden)
- This screen has no back button; the tab bar has no tab highlighted. I got out by tapping Clubhouse.

## Schedule — `54-tab-Schedule.jpg`, `59-cal-sep.jpg`, `60-cal-day6.jpg` (13:40)
Tapping the Schedule sub-tab leaves the Clubhouse entirely for a page "← HOME — YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES' — THE CALENDAR ← AUG 2026 →" with a month grid, legend "● ON THE TEE SHEET ● LEAGUE MATE ● SEASON DATE", "Tap any day to put a round on the tee sheet.", **[Put a round on the tee sheet]**, "ON THE TEE SHEET — Nothing on the tee sheet for Aug. Put one up: league mates and buddies see it the moment you do." "WEEK BY WEEK — Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season."
- September shows grey dots on Sat 5 and on every Sunday (6, 13, 20, 27). Tapping Sun 6: "Sun Sep 6 — 1 ON THE SHEET — ⛳ Week closes — snapshot recorded — [Put your round on this day]".
- So: the season "week" closes on Sundays; the season starts on a Saturday; therefore week 1 is one day long? Nothing explains this. "Snapshot" is undefined. The dot is counted as "1 ON THE SHEET" though the legend says the sheet is for planned rounds. (P2 comprehension)
- **Does the app tell me when I'm supposed to play? No.** There is no schedule of rounds, no "play by Sunday", no tee times. The calendar is a place to announce a round ("tee sheet") and a list of week-close markers. The only cadence rule is "2 rounds a month", stated on Home.
- "Tee sheet" — I know this phrase from the starter's desk at a course; here it seems to mean "rounds I've announced to buddies". Guessable, not stated.

## Pot — `61-tab-Pot.jpg` (13:42)
"SEASON STAKES — THE POT $25 — 1 × $25 · $0 collected · 1 still owe — $15 Cup champs · $6 Runner-up · $4 Points king — Cup Season keeps the books. Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar. — BUY-INS · 0/1 IN — [Dana ✓] — THE OTHER STAKES · PRIDE, ON THE BOOKS — [Post a stake] — No stakes on the books. The cookout isn't going to bet itself."
- Clear enough about money: the app is a ledger; I collect. The "Dana ✓" button presumably marks me paid; I did not press it.
- "Post a stake" — side bets ledger. Noted for the side-game audit.

## Board — `62-tab-Board.jpg`
"THE BOARD · rounds land here automatically [OPEN ↗] — Today · Aug 29 — ◆ Desert Dogs is live — post the first round — [Message the league…] [📣] [Send]". So the "board" = the league's chat/feed. The name never told me that; the onboarding card said "Clubhouse: table, board, pot" as if I'd know.

## Album — `63-tab-Album.jpg`
"THE ALBUM · every round photo this season — Photos land here when rounds carry them — add one from the Post card." Fine.

---

## JOURNEY D — FIRST ROUND (13:43:59 → …)

### The ⊕ / Post door — `64-post-1.jpg`
Tapping the orange **+** opens a page "GOLF · BEFORE, DURING AND AFTER THE ROUND" with three cards:
1. **● LIVE — Play now — score the group live** — "Hole-by-hole · match play, Wolf & the settle-up · every complete card posts at the finish. Guests welcome, no account needed." →
2. **Post a round — after you play** — "Gross + tee, 20 seconds · counts on your card and in every league" →
3. **Plan a tee time — before** — "Put a round on the tee sheet · your buddies and leagues see it the moment you post" →
- This is the first place side games are named (match play, Wolf, "the settle-up"). Discoverable from the main button — good. "Wolf" is not explained; "the settle-up" presumably = who owes whom.
- "Gross + tee, 20 seconds" — the promise is clear.

### Post form — `65-post-form.jpg` (13:44:30)
"← Golf · **Post a round · your index 18.2**" — COURSE & TEES [Search a course, or type your own] · Rating [72.1] · Slope [128] · YOUR CARD [18 holes] [9 holes] · Front 9 gross [41] · Back 9 gross [43] · "How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round." · Date [2026-08-29] · [Scan the card] [Add a photo] · "Enter your card to see the score." · **[Post round]** · [Start over — clear this card] · "HOW THIS ROUND SCORES — League points this round – · Enter at least one nine. · – Gross · – vs your index · No league yet? The round still counts on your card — points apply in any league you join. · POINT BANDS: Beat your index by 3+ 12 · Beat it by 1–3 9 · Within a stroke either way 7 · Over by 1–3 6 · Rough day, posted anyway 5 · Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time."

Answers BEFORE entering anything, from the UI only:
1. **How do I know what round I'm playing?** I don't — there is no "round 3 of 13" or "week 1". The form asks course, tees, gross, date. The league week/round concept never appears here. The Clubhouse said "SEASON — / 13" and the calendar said weeks close Sunday, so I *infer* a "round" here just means one 18 (or 9) I played, any day.
2. **Who am I playing?** Nobody, apparently. This is me vs my own index ("vs your index"). The squad race is a by-product.
3. **What format?** Stroke play gross, converted to points against my index. Nothing says stroke play but "gross" implies it.
4. **What are the rules?** The point bands are right here on the form — good: 12/9/7/6/5. "Best 4 each month count."
5. **How are handicaps applied?** "vs your index" — my 18.2. Nothing on this form mentions the 95% allowance from the bylaws. USER ASSUMPTION: my round is compared to 18.2. ACTUAL: unknown — the bylaws say 95%.
6. **What do I need to enter?** Course, rating, slope, front 9 gross, back 9 gross, date. Rating and slope are asked as raw numbers with placeholders "72.1"/"128" — a novice-league organizer who has never looked at a scorecard's rating box would be stuck; I know what they are, but I'd have to look them up.
7. **What counts toward the season?** "Every posted round scores. Your best 4 each month count toward your squad". But the Clubhouse said "practice rounds hit your card, not the season" before Sep 5, and Home said "Rounds count from today". The form says nothing about pre-season. Three different answers on three screens.
8. **What counts toward side games?** Nothing here. Side games live on the LIVE door; this form has no relation to them.
9. **What if something goes wrong (wrong score, wrong course)?** "Start over — clear this card" exists BEFORE posting. Nothing says whether a posted round can be edited or deleted.


### Filling the form — `67-course-search.jpg`, `68-tees.jpg`, `71-pre-post2.jpg` (13:45–13:47)
- Typed "Ken McDonald" → one result "**Ken Mcdonald Golf Course** · Tempe, AZ · 7 tees" (2.5 s). Tapped it → tee list: Tips 72.3/127 · Black 71.9/125 · Blue 70.4/121 · White 68.7/115 · Red 66.7/107 · White · Women's 74.5/129 · Red · Women's 71.6/122, plus "‹ Back to courses". Tapped White → the field reads "Ken Mcdonald Golf Course · White" and Rating 68.7 / Slope 115 filled themselves. **This part is excellent** — the scary rating/slope boxes disappear as a problem the moment you pick a real course.
- Entered Front 46 / Back 45. Live preview updated: "**Gross 91 · 18 holes**" on the button row and "HOW THIS ROUND SCORES — LEAGUE POINTS THIS ROUND **5** — Rough one, but posted rounds always score. — **91** GROSS · **-3.7** VS YOUR INDEX".
- OBSERVATION: "**-3.7 vs your index**" next to "Rough one" and 5 points. In golf, minus means under, means good. Here minus apparently means I played 3.7 *worse* than my index (a 91 off 68.7/115 is roughly a 22 differential against an 18.2). USER ASSUMPTION on first read: "I beat my index by 3.7 — why only 5 points?" ACTUAL: the sign convention is inverted from golf. (P1 comprehension)
- OBSERVATION: the line "No league yet? The round still counts on your card — points apply in any league you join." is still showing although I'm in Desert Dogs. (P2)
- No tee-time, no partners, no "who did you play with" — this is a solo scorecard.


### Posted — `72-posted.jpg` (13:47:26, ~3 min from opening the + to posting, 1 attempt, zero errors)
Full-screen card "Round posted": "KEN MCDONALD GOLF COURSE · WHITE · SAT AUG 29 — **91** — 3.7 over your number — [COUNTS ON YOUR CARD] — **[Share the card]** (green) — Back to the board". Behind it, stacked: an "add to home screen" prompt ("Get the full-screen app… [Add] [Not now]") and a second dialog "Welcome to the season ⛳ — 91 at KEN MCDONALD GOLF COURSE · WHITE — 🎉 Your first round is on the board / Welcome to the season — your number and record start here — 🏆 You broke 100 for the first time / Pinned to your card — ⛳ Your first round is on the board / Welcome to the season — [Share a link — no account needed] [Turn off this link] — The page stops working for everyone who has it. You can share a new link anytime."
- The posted card says "**3.7 over your number**" — correct wording; the form had said "-3.7". Same fact, opposite sign, 10 seconds apart.
- **The posted card does not mention points.** The form said 5 points; the celebration says nothing about 5, nothing about my squad, nothing about "counts in the season" vs "practice". "COUNTS ON YOUR CARD" — as a novice I read that as "counted", and only because I had seen the Clubhouse do I know it means "NOT the season".
- "You broke 100 for the first time" — a trophy for a 91 on my first-ever posted round; there is no history, so "for the first time" is true but hollow. Cute, slightly patronising to an 18-handicapper.
- "Your first round is on the board" appears TWICE in the same dialog (🎉 and ⛳ items).
- "[Turn off this link] — The page stops working for everyone who has it." — what link? I never made one. This appears inside a welcome dialog; a novice has no idea which page this kills. (P2)
- Three stacked dialogs (round card → home-screen prompt → welcome/achievements) after one tap. (P2 visual-hierarchy)


### Finding the explanation of the number — `74-home-after-post.jpg`, `77-round-detail.jpg` (13:48–13:49)
Home now shows under "AROUND YOUR BUDDIES · TODAY" a card "You · 🎉 First round on the card · **9 1** GROSS · KEN MCDONALD GOLF COURSE · WHITE · AUG 29". The 91 is drawn as two separate digit tiles; the text layer literally reads "9 1 gross" and the accessibility tree reads "6 3 0 9 2 8 5 1 gross" (a rolling odometer). (P3 visual)
Tapping the card (accessible name "You — 91 at Ken Mcdonald Golf Course · White") opens the receipt sheet "**91 gross** — KEN MCDONALD GOLF COURSE · WHITE · 18 HOLES · 2026-08-29 — The course 68.7 / 115 — 91 − 68.7 × 113 ⁄ 115 = **21.9 DIFFERENTIAL** — YOUR NUMBER THAT DAY 18.2 — Against your number **-3.7 — POSTED ANYWAY**".
- The math is shown — genuinely good, a golfer who knows WHS recognises it. But: (a) the sheet has no "5 points" on it, nothing about the league, the squad, or whether it counted; (b) "-3.7" again with the inverted sign (21.9 − 18.2 = +3.7 worse, shown as −3.7); (c) "POSTED ANYWAY" is the band name — but the form called it "Rough day, posted anyway" and the help sheet called it "Posted anyway · rough day". Three labels for one band. (P2)
- No edit, no delete, no "wrong course" path on the receipt. Only [Close]. Question 9 (what if something goes wrong) has no answer anywhere I could find. (P1 gameplay)

### Post-round answer — Q10: Do I understand whether I won/lost and what I earned?
Partly. I know I shot 91, that it was 3.7 worse than my index, and the FORM told me that is worth 5 points. But after posting, no screen says "5 points" or "counts in Desert Dogs" — and the Clubhouse said pre-Sep-5 rounds don't count for the season while Home says "Rounds count from today." So I earned either 5 points or nothing, and the app will not tell me which. (Checked next in Standings.)

**What I would tell a friend, verbatim:** "I put in my 91 from Ken McDonald, white tees. The app worked out I played about 22 against a rating of 68.7, and since my handicap is 18-ish that's 3 or 4 shots worse than my number, so it's the bottom band — 5 points, which apparently you get just for posting. Whether those 5 points count for anything I honestly can't tell you, because one screen says the season started today and another says nothing counts till next Saturday. And I'm on 'Squad 1' by myself, so I guess I'm winning?"


### Standings after the round — `78-standings-after.jpg` (13:49:40)
Unchanged: "COUNTING ROUNDS 0 / 4 · August · your best 4 count", individual table "01 Dana · R 0 · — · 0 pts". So the round did NOT count for the league — consistent with the Clubhouse's "practice rounds hit your card, not the season", inconsistent with Home's "The season's on. Rounds count from today." and with the form's "LEAGUE POINTS THIS ROUND 5". Verdict on Q10: I earned 0 league points and the app told me 5. (P1 comprehension/gameplay)
- Also "COUNTING ROUNDS 0/4 · August" — the season doesn't start until September, yet the tile is counting August.

### You tab — `79-you-tab.jpg` (13:50:09)
"Dana @dana · Member since Aug 2026 · [add your GHIN] [⚙] — **18.2** Handicap index — FORM — [💬 Tell us how it's going →] — YOUR DISPLAY CASE: No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here. — THE RECORD: No silverware yet — every season starts level. — LIFETIME: Rounds posted 1 · Best vs index **-3.7** Career best · Avg vs index **-3.7** · Cups & events **1** Played in — RECENT ROUNDS: 2026-08-29 · KEN MCDONALD GOLF COURSE · WHITE · 91 · 21.9 — [Post a round] — YOUR BUDDIES [Find golfers, see who you play with] — THIS SEASON · DESERT DOGS: Rounds posted 0 · Avg vs index — · Best round — · Index move — — LEAGUE RECORD: Desert Dogs · SEASON I · **FIRST TEE SUN SEP 5** — HOW IT WORKS: [The four places] [Leagues vs events] [Posting a round · Basic, live, and the scan] [Buddies, invites and claims · Three different links, three jobs] [How scoring works · How rounds become points]".
- "Display case: … post your first round … milestones land here" — I just posted my first round, and the welcome dialog said "You broke 100 · Pinned to your card", yet the display case says "No hardware yet". (P2)
- "Best vs index -3.7 · Career best" — my worst-possible band is labelled career best with a minus sign. Sign inversion strikes again. (P1, same issue)
- "Cups & events · 1 · Played in" — I have played in zero events. (P2)
- "FIRST TEE **SUN** SEP 5" — Sep 5, 2026 is a Saturday, and every other screen says "Sat Sep 5". (P2)
- "How it works" IS here — five explainers including "How scoring works" — as onboarding promised ("Reopen this any time from You › How it works"). A patient novice would find rules here on day one. Still: nothing on Home or Clubhouse points to it.
- The card said "City and home course live on your card — add them any time from the You tab." I see no city/home course on this tab; presumably under ⚙.


### Card & settings (⚙ on You) — `81-settings.jpg` (13:51:44)
Sheet "Card & settings — YOUR CARD IS WHAT YOUR BUDDIES SEE · SETTINGS RUN THE APP — [Your card] [Settings]": Name on the card · **City · Home course** (here they are) · Ball marker grid · "Your photo · the marker always backs it up [Add a photo]" · "Handle · moves once / 60 days" · "Findable by [All] [Buddies] [Nobody]" · "GHIN # · optional — A reference on your card — we never resell or verify it. Leave it blank if you'd rather not." · [Save card] · "Handicap index [18.2] [Update index] — Your index builds automatically from your posted scores (best of your recent rounds, WHS-style) — it appears once you've posted 3. Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed." · "Your leagues · Desert Dogs · PRO · DESEUU0K".
- GHIN copy here ("A reference on your card — we never resell or verify it") is far clearer than the onboarding line ("that's identity, not your number").
- "Handle · moves once / 60 days" — a rule that was not mentioned when the app auto-changed my handle during onboarding.
- Home course/city were never offered during onboarding, are two levels deep, and my first Save (with the fields blank) was accepted silently with "Card saved".

### "How it works" explainers on You (13:52)
- **Buddies, invites and claims — THREE LINKS, THREE JOBS:** "A buddy is mutual — the magnifier up top finds golfers by name or @handle. Buddies see each other's rounds and share a tee sheet. Nothing to do with leagues or points. / An invite link carries a league's code — whoever opens it joins that league. / A claim link hands one round to a guest you played with, so the score lands on their card. No league, no buddy — just the round." — Clear, and it confirms the only way in for a non-user is the invite link I never saw.
- **Posting a round — THE ⊕ · BEFORE, DURING, AFTER:** "After you play: front nine, back nine, pick the course — twenty seconds. It counts on your card and in every league you're in. Scan the card and the app reads it for you, the whole group at once. / During: Play now is the shared pencil — match play, Wolf, skins, the settle-up. Everyone's card posts at the end, attested by the group. / Before: put a tee time on the sheet. Your buddies see it and tap in." — So "attested" (the bylaws' VERIFICATION value) means "the group scored it live together". That definition lives here and nowhere near the bylaws.

- Saving the card took **4 attempts**: the button reads "Save card" until you type, then silently becomes "Save changes"; tapping "Save card" with untouched fields shows a "Card saved" toast although nothing changed. (P3 — harness-visible, but the toast-without-change is real.)

---

## SIDE GAME AUDIT (13:56 →)

### Discovery
- I found side games WITHOUT being told: they are named on the LIVE card of the ⊕ door ("match play, Wolf & the settle-up"), in the You › How it works › "Posting a round" explainer ("match play, Wolf, skins, the settle-up"), and on the Pot tab ("THE OTHER STAKES · PRIDE, ON THE BOOKS · [Post a stake]"). Nothing on Home, in the Clubhouse Standings, or in the wizard mentions them. Discoverable in 2 taps from the + button — decent.

### The LIVE setup screen — `85-live-1.jpg`, `86-live-games.jpg` (13:56:03)
"← GOLF · SET UP THE ROUND — COURSE [Search a course, or type your own] — TEE & RATING — OFF THE SCORECARD [Tee] [Rating] [Slope] — [18 holes] [9 holes] — Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load. [Enter the pars] — THE FOURSOME · 1 / 4 — Dana 18.2 IDX · Open slot TAP A PLAYER BELOW ×3 — TAP TO FILL A SLOT · LEAGUE — No league mates to tap yet — search the app or add a guest below. — [Search the app — add any golfer] — ADD A GUEST [Name] [Index] [Add] — Pick who plays with who under the game — pairings, stakes, the lot. League members post to the season; guests play every game, post nothing, no account needed. Leave index blank for an estimated 18. — GAME FOR THIS ROUND · PICK ONE — [Just score] [Match play] [Wolf] [Skins] [Sunningdale Rules] — Stroke play — your card, your pace. One to four players; post when you're done. — [Tee off →]"
Tapping each game shows a one-line rule and a stake box:
- **Match play**: "Singles (2) or 2v2 net best ball (4). Keep scoring; we tally the match as you go." · "Stake per side · $0 = bragging rights [0]" · "Match play takes 2 (singles) or 4 (2v2 net best ball)."
- **Wolf**: "A round of Wolf — needs four. We run the rotation and the side tally; scores still post." · "Dollars per point · $0 = bragging rights" · "Wolf needs exactly 4 players." — **Wolf is never explained.** If you don't know Wolf, this line tells you nothing (who is the wolf, what's a rotation, what's a point). A 20-year golfer who has never played Wolf — common — is stuck. (P2 rules)
- **Skins**: "Low net takes the hole's skin; ties carry the pot. Two to four players; scores still post." · "Dollars per skin". Clear.
- **Sunningdale Rules**: "Match play, no handicaps — go 2 down and you get a stroke until you climb out. Singles or 2v2. Win a hole while ahead to bank a unit." · "Bank unit". I have never heard of this; the one-liner is OK but "bank a unit" is opaque.
- Nassau — the most common buddy bet in America — is absent.

### What I think they are / how they relate to the season
- They are games-within-a-round for the group you're physically with. "Scores still post" / "League members post to the season; guests play every game, post nothing" tells me the ROUND still feeds the league (via the same points bands), but the GAME result (skins won, match won, dollars) is separate and, per the Pot tab, can be logged as a "stake". USER ASSUMPTION: side-game money has nothing to do with the cup pot. ACTUAL: the Pot tab has "THE OTHER STAKES · pride, on the books" — a ledger for exactly this. So integrated at the ledger level, not at the points level.
- Would they make a round matter when I'm out of contention? Yes — a $5 skins game with the guys is a reason to play regardless of the table, and the 5-point floor means the round still helps the squad. That is the strongest retention idea in the app, and it is one tap deeper than it should be.
- Do they create social interaction? Potentially: "Everyone's card posts at the end, attested by the group" and guests need no account (the guest funnel). With nobody in my league, the foursome slots say "No league mates to tap yet".
- Integrated or bolted on? The setup screen feels like a different product from the season: its own course search (that ALSO asks for rating/slope by hand), its own "foursome" concept, no mention of Desert Dogs anywhere on it. Bolted on, well made.
- Does the app encourage me to set one up? Mildly: the LIVE card is first and orange on the ⊕ door; the Pot tab teases "The cookout isn't going to bet itself." No nudge from Home or the Clubhouse.


### Setting one up — `87-live-ready.jpg`, `89-live-ready.jpg`, `90-live-scoring.jpg` (13:57 → 13:59:57, ~4 min, many harness retries; a human: ~6 taps + typing)
- Course search "Papago" → **the same course listed twice** ("Papago Golf Course · Phoenix, AZ · 13 tees" ×2). (P3) Picked White 70.1/120; the Tee/Rating/Slope boxes filled themselves and the card said "Card loaded: 18-hole pars and stroke index from the course database." Nice.
- "TAP TO FILL A SLOT · LEAGUE — No league mates to tap yet" — with an empty league the foursome is me + guests. Added guest "Mike" with no index → "G Mike · EST 18.0 IDX". Clear.
- Picked **Skins** → extra rule line appeared: "Low net wins the hole's skin; a tie carries it — next hole is worth more. Strokes apply off the low man." Set $2/skin.
- Friction: the guest "Add" button sits next to the persistent "Get the full-screen app… [Add] [✕]" banner, which ALSO says "Add"; my first "Add" tap hit the wrong one and a "Add to the foursome" search sheet opened over the form instead. Two "Add" buttons on one screen. (P2 navigation)
- **[Tee off →]** → live scoring screen: "NO SKINS CLAIMED YET — Dana — · Mike — — Live round · Papago Golf Course · White · 70.1/120 — [Change setup] — ← HOLE 1 · PAR 5 · SI 15 → — Dana 18.2 IDX · 0 STK [−] – [+] — Mike GUEST EST 18.0 IDX · 0 STK [−] – [+] — [Group phones — everyone can score] — [Finish round & post to season] — Scores entered together are auto-attested: the group verifies everyone's round just by playing it. Guests need no account: they play every side game, appear in the settlement, and get a recap text with their scorecard and an invite when you finish. Only league members' rounds post to the season. — [Scrap this round] — SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN YOU — Skins · ties carry the pot — HOLE 1 WORTH 1 SKIN — THRU 0 · LOW NET TAKES IT · $2/SKIN — 0 DANA · 0 MIKE — ROUND SETTLEMENT · LIVE — ALL SQUARE $0".
- This screen finally explains "attested" in context and says exactly what the guest gets. Good. "0 STK" — strokes on this hole, I assume (SI 15 with an 18 index = 1 stroke, yet it shows 0 — so strokes must be "off the low man": both 18, difference 0. That took me a minute to reason out; the app doesn't say it here.)
- "Finish round & post to season" — I'm a week before the first tee, so per the Clubhouse that would NOT post to the season. The button says it will. Same contradiction as the basic post. (P1, same family)


### Scoring two holes — `91-live-h1.jpg`, `92-live-h2.jpg` (14:00–14:01)
- The stepper starts at "–"; the FIRST tap of + sets the hole to par, every further tap adds one. I tapped + six times on a par 5 expecting 6 and got 10; Mike got 9; hole 2 (par 4) five taps each → 8 and 8. Nothing on screen says "first tap = par". (P2 gameplay — a wrong score on hole 1 is the most common live-scoring error, and the receipt/undo path is the − button only.)
- After hole 1: Mike low (9 vs 10) → "1 MIKE" skin. After hole 2 tie → "HOLE 3 WORTH 2 SKINS · THRU 2", "ROUND SETTLEMENT · LIVE — DANA → MIKE $2". The live ledger is instant and readable — this is the best-feeling part of the app. Running totals "18 THRU 2 +9" / "17 THRU 2 +8" are right there.
- Sticky "NO SKINS CLAIMED YET · Dana – · Mike –" bar overlaps the explanatory paragraph beneath it (90-live-scoring.jpg). (P3 visual)
- "0 STK" for both players on SI 15 and SI 17 — correct under "strokes off the low man" with equal indexes, but a novice sees 18-index golfers getting 0 strokes and wonders.

- Sticky header during play: "**MIKE 1 · 2 RIDING** — Dana +9 net · 18 thru 2 — Mike +8 net · 17 thru 2 — 1 ON THE SHEET · SYNCED". "Riding" = skins carried; guessable from context, never defined.
- **[Scrap this round]** is a two-tap confirm: first tap turns the button into red "Tap again to scrap — nothing posts, for anyone". Good pattern, no modal. (`93-scrap-confirm.jpg`)

---

## SCHEDULE / "WEEK" / "ROUND" — what the app means (14:03)
- Home's "NEXT · Open · PLAN A ROUND" tile opens the same calendar as Clubhouse › Schedule (`95-plan-round.jpg`). "Next" therefore means "your next planned tee time", and "Open" means "you haven't planned one" — I read it for twenty minutes as "the next league round is open". (P2 terminology)
- A **"round"** in this app = any 18 or 9 you post, any day, any course. A **"week"** = Sunday-night snapshot boundary (calendar dots), used for "Δ WK"/"WK 1" in standings and for the Cup Final ("last four weeks"). A **"month"** = the unit for the counting cap and the floor. Three different clocks; none of them is explained in one place; the wizard's "Season length · Weeks or months · ends the same weekday" is the only hint that weeks matter.
- **The app never tells me when to play.** No fixture list, no "play by", no reminders visible. The only cadence is "2 rounds a month" (Home) — and the season/week machinery is invisible until the first "snapshot" lands.

## EMPTY-LEAGUE STATE — does it feel dead or alive?
Dead, with one bright spot. Evidence:
- Standings: two empty squads named "Squad 1" / "Squad 2" with "CAPT. —", a "TOP SEED · +10" badge for a squad with no players, a "THE CLIMB" chart of two zeros (`36-clubhouse-full.jpg`).
- Board: one system line "◆ Desert Dogs is live — post the first round" and a chat box for a room of one (`62-tab-Board.jpg`).
- Home: "ROSTER ●—— 1 IN" — the bar is 10% full, and there's no "invite 3 more to tee off" call-to-action next to it, only "add some buddies" (which, per the explainer, has "Nothing to do with leagues").
- Members: the invite is a 1.5-second toast of a code.
- Live round: "No league mates to tap yet".
- Bright spot: the LIVE skins game with a guest, and the guest's promised "recap text with scorecard and an invite" — that is the one mechanic that works with zero members and could pull people in.
What would keep me going: a visible invite LINK with a "2 invited · 0 joined · 4 needed to tee off" tracker on Home; a countdown that's honest ("7 days to first tee — you need 3 more golfers"); and the round I just posted acknowledged as "practice — on your card, season starts Sep 5".


## Tee sheet form & "Post a stake" — `96-teesheet-form.jpg`, `97-stake-form.jpg` (14:03)
- "Put a round on the tee sheet — BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST — Day [2026-09-05] · Tee time · optional · Course [Pebble Beach] · Note · optional [buddies trip, looking for a 4th] — No one to tag yet. Add buddies from the You tab, or invite the league. — [On the tee sheet] — Posts to your leagues' boards: tagged golfers are named. Scratch it any time from the calendar." Simple. Defaults the day to the first tee (Sep 5) — a small, smart nudge.
- After scrapping the live round, the ⊕ door shows no "resume" — the scrap took.
- "Post a stake — **Pride, on the books — never money** — Name it [The Lawn Bet] — The shape: [Loser hosts] [Winner picks the course] [Strokes next time] [Standing bounty] [Name your own] — The terms [Loser hosts the cookout] — Against [The field — first to hit it ▾] — Rides on (optional) [Sunday's duel · first ace · the Cup Final] — [Cancel] [Put it on the books] — Stakes settle on a party's tap and archive into the record. The pot stays money; this never is."
- So my earlier assumption was wrong: "stakes" are NON-money bragging bets. The $2/skin from the live game is "settled between you" and lands nowhere in the app's books. USER ASSUMPTION (before): side-game dollars go on the Pot ledger. ACTUAL: only the buy-in pot is money; skins/match/Wolf cash is shown once in the live "ROUND SETTLEMENT" and then, as far as I can find, gone. (P2 gameplay — the settle-up is the thing buddies argue about at the bar, and the app that "keeps the books" doesn't keep these.)
- "Rides on … the Cup Final" — a pride stake can be attached to season moments. Nice idea, discoverable only from the Pot tab.


## Terms / Privacy (visited at the END, as an organizer worried about money) — `98-terms.jpg` (14:04)
A plain page "Cup Season · Legal" with Privacy Policy, Terms of Service and a **Prize Pool Disclaimer**: "Any prize pool shown in the app is managed entirely by league organizers and participants… CupSeason does not collect, hold, transfer, or distribute money, takes no fee or cut of any prize pool… If you are unsure whether a money pool is allowed where you live, keep your league to bragging rights." — This is the clearest statement of the money model in the whole product, and it lives on the legal page. The wizard's buy-in stepper never links to it. The support contact is a personal email address.
- Coming BACK from the legal page (`← Back to Cup Season` / navigating to the root) dropped me on the **sign-in door** with console `[cs] Boot stalled at [league-data] — network or auth hang` (`99-final-home.jpg`). See below for whether it recovered.

- Recovery: after ~8 s on the door the app landed on Home signed in (`100-boot-stall.jpg`); a second reload did the same ~6 s door-then-home. So every cold open shows a signed-in user the sign-in door for several seconds. (P2 onboarding/retention) Every boot also logs `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` — invisible to the user, but "resume a live round" looks broken server-side.

Session stopped 14:05 UTC. Total time signed-out-door → end: ~47 minutes. League created: **Desert Dogs**, code **DESEUU0K**.

---

## RULES & MENTAL MODEL TABLE (built only from the app)

| Rule | Where I found it | Discover? | Understand? | Predict consequence? | Explain to a friend? | Confidence (1–10) |
|---|---|---|---|---|---|---|
| **How points work** | Post form "POINT BANDS" + You › How it works › How scoring works | Yes (form shows it) | Yes: 12/9/7/6/5 vs your own index | Mostly — but 95% allowance vs "your own number" unresolved, and sign of "vs index" is inverted on 3 screens | Yes | 7 |
| **How I win** | Wizard (i) "How it ends", Clubhouse "TOP 1 ADVANCE", pot split | Only via Customize › (i) | Partly: squads accumulate points; Cup Final last 4 weeks "top seeds only, scored fresh" | No — how many seeds, what non-seeds do, what "+10"/"generous ceiling" mean | Vaguely | 4 |
| **What is a "cup" here** | Wizard "Cup Final" copy; door tagline | Only if you open Customize/(i) | A 4-week playoff at the end of the season (or nothing, if Points table is chosen) | Partly | Partly | 5 |
| **Miss a week** | Nowhere — "week" only exists as a Sunday snapshot | No | No | No | No | 2 |
| **Miss a month** | Home floor line; wizard (i) "participation floor"; scoring sheet | Yes (Home) | Yes: 2 rounds/month or −5 squad pts per round short; first miss covered by a "bye"; "short months waived" | Mostly — "short month" undefined; who approves the bye unclear ("Pro-approved" vs "automatically") | Yes | 7 |
| **How long is the season** | Wizard; Clubhouse "Sat Sep 5 → Sat Dec 5 · 13 wks" | Yes | Yes | Yes | Yes | 9 |
| **What happens at the end** | Pot split + Cup Final copy | Partly | Champ 60 / runner-up 25 / Points King 15 of a pot I collect myself | Partly — "champ" of a 2-squad league is a squad; how does a squad get 60%? | Partly | 5 |
| **Money** | Wizard buy-in stepper; Pot tab; scoring sheet; legal page | Yes, but the $75 default was hidden behind Customize | Yes: app keeps a ledger, money moves friend-to-friend, no fees | Yes | Yes | 8 |
| **Handicaps in scoring** | Golfer card; scoring sheet; receipt | Yes | Mostly: own index, WHS-style differential, starter overridden after 3 rounds | No — the 95% allowance never appears on any round | Mostly | 6 |
| **Do pre-season rounds count** | Clubhouse "practice rounds hit your card, not the season" vs Home "Rounds count from today" vs form "5 pts" | Contradictory | No | No | No | 2 |
| **Minimum players** | Last wizard step only: "Minimum four to tee off" | Late | Yes | No — the league locked with 1 and says "SEASON LIVE" | Sort of | 4 |
| **Squads / captains** | Wizard Customize (i); Standings "CAPT. —" | Behind (i) | Squad = team; captain never explained | No | Partly | 4 |

---

## GLOSSARY (every product term I met, and what I THINK it means)

| Term | Where seen | What I think it means | Confusing? |
|---|---|---|---|
| Cup | door tagline, wizard, standings | The season trophy; also the name of the 4-week end playoff ("Cup Final") | Yes — two meanings |
| Season | everywhere | The N-week league period (mine: Sep 5–Dec 5) | No, once set |
| League | Home, Clubhouse | A group + a season with bylaws; "the long game" | No |
| Event | onboarding, Home "Start an event" | A short competition (weekend/few weeks) with "its own little trophy" | Slightly — never explored what it contains |
| Crew / buddies | door, Home, You | "Buddies" are mutual follows with "nothing to do with leagues or points" | Yes — I assumed crew = league |
| Pro | wizard, Clubhouse | The league organizer (me) | Yes — golf already uses "pro" |
| Pro Shop | wizard (i), League tab | A future paid membership tier | Yes — used 3× before defined |
| Bylaws | name sheet, wizard, League tab | The league's rule settings; "lock at first tee" | Yes — legal word for settings |
| Lock / locked | wizard, Standings "SQUADS LOCKED" | Settings frozen; but endgame still switchable and squads still drawable | Yes — contradicted |
| First tee | wizard, Clubhouse | Season start date | Slightly |
| Squad | Home, wizard, standings | A team of league members | Yes — used on Home before defined |
| Captain (CAPT.) | standings | Someone leading a squad; never explained | Yes |
| Blind draw / Assign | wizard | Random vs Pro-chosen team allocation | No |
| Cup Final vs Points table | wizard | Playoff finish vs whole-season leader finish | Mostly no |
| Top seed / seeds / TOP 1 ADVANCE | standings | Squads that qualify for the Cup Final | Yes — count and mechanism unexplained |
| +10 / generous ceiling / the climb | standings | Some projection about the season race | Yes — meaningless with no data |
| Pot / buy-in / on the books / ledger | wizard, Pot tab | Cash prize pool, tracked but not held by the app | No, after the Pot tab |
| Points King / Most Improved / Iron Man | standings | Individual side prizes (best individual, index drop, most rounds) | Slightly |
| Counting cap / Best 4 / counting rounds | wizard, Clubhouse | Only best N rounds per month score for the squad | No, after (i) |
| Participation floor / floor / 2-round floor | Home, wizard | Minimum rounds/month; penalty −5 squad pts per round short | No, after (i) |
| Bye / bye month | wizard (i), scoring sheet | One forgiven month per season | Slightly — "Pro-approved" vs "automatic" |
| Short months | Home | Presumably partial calendar months at the season edges | Yes — undefined |
| 95% hcp / handicap allowance | wizard, bylaws | Percentage of handicap used — never shown in action | Yes |
| Honor scores / GHIN rounds / verified + attested / rated tees / receipts required | wizard | Escalating verification levels; "attested" = scored live by the group | Yes |
| Index / your number / starter | card, scoring sheet | Handicap index the app computes; a typed one is temporary | Mostly no |
| Differential | receipt | (gross − rating) × 113 / slope | No (for a WHS-aware golfer) |
| vs your index (−3.7) | form, receipt, You tab | Difference between differential and index — with the sign inverted | Yes |
| Bands / Torched it / Beat your number / Played to it / A little loose / Posted anyway / Rough day | scoring sheet, form, receipt | The 5 point tiers — with three different label sets | Slightly |
| Card / your card / golfer card / counts on your card | onboarding, Home, post result | My profile/record, as opposed to the league | Yes — "counts on your card" reads as "counted" |
| Board / the board | onboarding, Home, Clubhouse | The league feed/chat where rounds and system posts land | Yes — undefined until seen |
| Table | onboarding | Standings | Slightly |
| Clubhouse | tab | The league room | No |
| The ⊕ | onboarding | The + button (Post door) | Yes — two names for one thing |
| Tee sheet / on the sheet | calendar, live round | Planned rounds visible to buddies/league; live rounds also count as "on the sheet" | Slightly |
| Snapshot / week closes | calendar | Sunday-night standings capture | Yes |
| Δ WK / WK 1 / Trend | standings | Week-over-week change | Yes (empty) |
| Live round / Play now / shared pencil | ⊕ door | Hole-by-hole group scoring with side games | No |
| Settle-up / round settlement / riding | live round | Who owes whom; "riding" = skins carried | Slightly |
| Wolf / Skins / Sunningdale Rules / Match play | live setup | Side games; Wolf and Sunningdale not explained | Yes (Wolf) |
| Stake / Post a stake / The other stakes | Pot tab | Non-money pride bets on the books | Yes — "stake" usually means money |
| Guest / claim link | live round, explainer | Non-account player; a link that hands them their round | No |
| Invite link vs invite code | wizard, members | Same thing, two words; I only ever saw the code | Yes |
| Ball marker | card | My avatar icon | Slightly |
| Handle | card | @username | No |
| Founding / pilot ("THE PILOT RIDES FREE") | League tab | Early leagues don't pay | Yes — am I the pilot? |
| Display case / hardware / silverware | You | Trophies/badges | No |
| Form (● dot) | You | Some recent-performance indicator | Yes — a lone grey dot |

---

## CONFUSION DEBT (things the app assumed I already knew)

1. What a "league" vs an "event" vs a "crew/buddies" is — before I'd seen any of them.
2. That "squad" means team, and that my league would be split into teams at all.
3. What a "Pro" is (organizer) and everything that job entails (approving byes, collecting money, assigning squads, switching the endgame).
4. What "bylaws" are and what "lock" freezes.
5. Why 95% / 90% / 100% handicap allowances exist and what they do to my rounds.
6. What "GHIN rounds", "attested", "rated tees" require of my friends at post time.
7. How a Cup Final works: how many seeds, what everyone else does in the last 4 weeks, how a squad "wins" the pot.
8. What "+10", "TOP SEED", "generous ceiling", "Δ WK" mean on an empty standings page.
9. That posting before the first tee is "practice" (Clubhouse) — while Home and the form say it counts.
10. That the "vs index" minus sign means WORSE.
11. What "Pro Shop" is (paid tier) — three mentions before one definition.
12. That I must LOCK the league before I can invite anyone, and that the invite is a code shown in a toast.
13. That there is no email/SMS invite; friends must already be on the app or receive my link some other way.
14. That "Minimum four to tee off" is a rule — revealed on the last step and then not enforced.
15. How Wolf and Sunningdale Rules are played.
16. That "stakes" are never money, and that side-game cash is not kept anywhere.
17. What a "week" is (Sunday snapshot) and that the season, weeks and months are three different clocks.
18. What "short months are waived" means.
19. That the first tap on the live score stepper sets par.
20. Where the rules live (You › How it works) — Home and Clubhouse never point there.

---

## JOURNEY A — the 10 questions, re-answered at the END (Δ = what changed)

1. **What does the app do?** Runs a months-long handicap-golf competition among friends: everyone posts real rounds from any course, each round is scored 5–12 points against your own index, points accrue to your squad, and the last 4 weeks are a playoff for a cash pot the organizer collects. Plus live side games with guests. **Δ: from "track rounds, win a cup" to a specific fantasy-league-style mechanic.**
2. **Primary action?** Post a round (the orange +). **Δ: confirmed; but for an organizer the primary action is really "get 3 more people in", and the app doesn't treat it that way.**
3. **Season?** A fixed run of N weeks (mine 13, Sep 5–Dec 5) with monthly caps/floors and a 4-week final. **Δ: from a vague "stretch of time" to exact dates.**
4. **League?** A named group with locked "bylaws", squads, a pot and a board; one league can run many seasons ("SEASON I"). **Δ: I assumed crew = league; the app says buddies are a separate, points-free thing.**
5. **Cup?** The trophy AND the name of the end-of-season playoff ("Cup Final"), optional (the Pro can switch to a points table). **Δ: from "a trophy" to "a playoff format".**
6. **Competing for?** A cash pot (default $75/player!, mine $25) split 60/25/15 champ/runner-up/Points King; plus Most Improved, Iron Man, badges. **Δ: money was invisible on the door; it's central.**
7. **Against whom?** My squad vs the other squad(s); individually vs everyone for Points King. **Δ: I assumed individual head-to-head; it's team-based by default (2 squads).**
8. **How do rounds work?** Gross front/back + course/tee; the app computes a differential vs rating/slope and compares to my index; 5–12 points; best 4 a month count. **Δ: from "type a score" to a precise formula I've seen on a receipt.**
9. **After a round?** Card + celebration + board post; points appear in standings — except before the first tee, when they don't (and the app disagrees with itself about it). **Δ: I now know, but only from contradiction.**
10. **Different from just playing with friends?** Every casual round counts for something months long; bad rounds still score (5-pt floor); nobody can bury you by playing daily (cap); ghosting is penalised (floor); receipts show the math. **Δ: the "why" is now clear — but I learned it from a help sheet four taps deep, not from the product surface.**

---

## 30-SECOND EXPLANATION TO A FRIEND (verbatim)

"Cup Season is a fantasy-league thing for our actual golf. I set up a league, we each throw in twenty-five bucks, and the app splits us into two squads. Then you just go play golf wherever, whenever, and post your score — it works out how you did against your own handicap and gives you five to twelve points, so a bad day still gets you five. Your best four rounds a month count for your squad, and if you don't post at least two a month your squad gets docked. It runs thirteen weeks; the last four weeks are a 'Cup Final' where the top squads start fresh and whoever's hottest wins the pot. There's also a live mode for skins or match play when we're actually out together, and you can drag guys in as guests without them having an account. Honestly, the setup asked me a bunch of stuff I didn't understand and it told me it failed when it hadn't, but once it's running the round-posting part is slick."

---

## PERSONA VERDICT

**Key question: Can this person create/join a season and understand the rules without outside instruction?**
**Answer: Create — yes, barely, and the app told me I had failed. Understand the rules — about half, and only by digging.** A patient novice who opens every (i) and finds You › How it works can reconstruct the scoring and money model. The same novice cannot confidently answer "how do we win the Cup Final", "do this week's rounds count", "what does 95% do", or "how do I get my friends in" — and those are the four questions their buddies will ask first. The single worst moment is a P0: the lock button reports failure six times while the league is in fact live. The single most consequential trap is a $75-per-player default buy-in hidden behind "Customize". **Score: 4/10.**

Scores (1–10): conceptClear 5 · setupClear 4 · rulesClear 5 · easyToPickUp 5 · gameplayCompelling 7 · sideGamesCompelling 7 · stakesMeaningful 6 · wouldInvite 4 · wouldPlayAgain 6 · wouldPay 4.

Why not lower: the round-posting flow (course search → tees → rating/slope autofill → live points preview → receipt with the formula) and the live skins ledger are genuinely good, and the scoring sheet is honest and short. Why not higher: the organizer's path — the persona's whole job — is where the bugs, hidden defaults, contradictions and dead ends are.


---

## ISSUE LIST (severity · category) — each with OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION

**N-01 · P0 · gameplay — "Lock failed" while the lock succeeded.** OBS: 6 taps of [Lock the bylaws & form the squads] each showed the toast "Lock failed. Something went wrong — please try again." (33-lock-fail-toast.jpg); console `[cs] error: Lock failed. staged is not defined`; after reload the league was live (34-reload-home.jpg) with the FIRST attempt's structure (2 squads), not my later Solo choice. INT: client crash after a successful server call. IMPACT: the organizer's single most important action reports failure; novices abandon or duplicate leagues; later choices silently discarded. REC: fix the reference error; on any post-lock exception re-read the league state and show the success screen; never let a "try again" toast fire when the server already committed.

**N-02 · P0 · monetization/comprehension — $75 per player is the hidden default buy-in.** OBS: Step 2 offers [Use these defaults →]; the Buy-in $75 stepper only appears after [Customize] (19-wizard-customize-full.jpg); the Standard card never mentions money. INT: a Pro who trusts "defaults" ships a $75 stake unseen. IMPACT: real money committed without consent; the exact thing the Prize Pool Disclaimer says to avoid. REC: surface buy-in (and season length, teams) ABOVE the fold on step 2 or as its own step, default to $0 = bragging rights, and restate the buy-in in the lock confirmation.

**N-03 · P1 · comprehension — Home and Clubhouse disagree about whether rounds count.** OBS: Home "SEASON LIVE — The season's on. Rounds count from today."; Clubhouse "BEFORE FIRST TEE — practice rounds hit your card, not the season"; the post form promised "LEAGUE POINTS THIS ROUND 5"; standings then showed 0 (34, 35, 71, 78). IMPACT: a novice cannot answer "did that round count?" REC: one season-state string, computed once, used everywhere; the post form and posted card must say "practice · season starts Sep 5" when applicable.

**N-04 · P1 · comprehension — the "vs index" sign is inverted from golf convention.** OBS: form "-3.7 vs your index" with "Rough one"; receipt "Against your number -3.7 — POSTED ANYWAY"; You tab "Best vs index -3.7 · Career best"; posted card correctly says "3.7 over your number" (71, 77, 79, 72). IMPACT: golfers read minus as under par = good; the app means worse. REC: show "+3.7 over" / "−2.1 under" with the word, everywhere; never bare signed numbers.

**N-05 · P1 · social/onboarding — no email/SMS invite; the invite link is never shown.** OBS: [Add golfers] only searches existing accounts ("No golfers found. Invite links still work for everyone else."); [Share the invite link] and [Share an invite link instead] produce a 1.5 s toast "Invite code: DESEUU0K" (45, 47, 48). IMPACT: the persona's job is to get 3 buddies in; the app gives no visible URL, no copy confirmation, no pending/invited state, no reminder path. REC: show the link as selectable text with Copy + native share; offer "invite by email/phone"; show "invited · joined · needed" on Home.

**N-06 · P1 · rules/onboarding — "Minimum four to tee off" appears only on the last step, then isn't enforced.** OBS: step 3 footer (28); the league locked with 1 player and Home says SEASON LIVE, Standings say SQUADS LOCKED. IMPACT: novices with 3 friends learn the constraint after committing; then the app contradicts it. REC: state minimum players on step 1; block lock or show a clear "waiting for 3 more" state.

**N-07 · P1 · comprehension — Teams control contradicts itself.** OBS: "2 Squads" highlighted, caption "4 squads · the full cup experience for 8+ players.", orange note "1 golfer staged — solo fits." (19). IMPACT: can't tell what I'm choosing. REC: caption must describe the selected option; the staged-count hint should recommend, not contradict.

**N-08 · P1 · navigation — the rules live 4 taps deep behind a collapsed disclosure.** OBS: Clubhouse → League → "▶ LEAGUE RULES & PRO SHOP" → [How scoring & handicaps work →] (38, 40, 42); also You › How it works. Nothing on Home, Standings or the wizard links to it. IMPACT: the best explainer in the product is undiscoverable at the moment of confusion. REC: link "How scoring works" from the Standings header, the post form's point bands, and the wizard step 2.

**N-09 · P1 · gameplay — "Draw failed" hides the real reason.** OBS: toast "Draw failed. Something went wrong — please try again."; console "Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first." (53). IMPACT: the helpful sentence exists and the user never sees it. REC: surface server error messages verbatim when they are user-facing.

**N-10 · P1 · comprehension — Squads card says "Complete · rosters locked" while the squads are empty and undrawn.** OBS: League tab card vs Form squads screen "Squad 1 · 0 PLAYERS · Empty" (37, 52). REC: derive the status from the actual roster.

**N-11 · P1 · terminology — verification vocabulary is inconsistent and undefined at decision time.** OBS: Standard = "GHIN rounds" on the card, "VERIFICATION Attested" in the review; Cutthroat = "verified + attested · rated tees"; "attested" is defined only on the live-round screen ("Scores entered together are auto-attested") (15, 28, 90). IMPACT: the Pro can't tell what friends must do to post. REC: one word per level with a one-line definition on the preset card.

**N-12 · P1 · gameplay — no edit/delete path visible from the round receipt or posted card.** OBS: receipt sheet has only [Close] (77); the only delete I found is an unlabeled ✕ on You › Recent rounds (tree name "Delete round"). IMPACT: Q9 "wrong score/course" has no discoverable answer at the point of need. REC: "Wrong? Delete this round" on the receipt and posted card.

**N-13 · P1 · comprehension — standings badges are meaningless with no data.** OBS: "TOP SEED · +10", "TOP 1 ADVANCE · PROJECTED UNDER A GENEROUS CEILING", "CAPT. —", "Δ WK", "WK 1" for two empty squads (36). REC: hide projections until N rounds exist; explain "seed", "advance", "captain" inline.

**N-14 · P2 · terminology — "Pro Shop" used three times before it is defined.** OBS: wizard (i) "Every individual dial unlocks with Pro Shop", "Live draft night… on the Pro Shop roadmap"; defined only on League tab as "CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE" (17, 18, 40). REC: don't reference an undefined tier in the wizard; say "paid membership (coming)".

**N-15 · P2 · comprehension — Home shows league rules ("Monthly floor… your squad loses 5 points") to a user with no league.** (10) REC: hide until in a league.

**N-16 · P2 · comprehension — "Rounds count from today" / "COUNTING ROUNDS 0/4 · August" for a season starting in September.** (34, 36) REC: show the first counting month.

**N-17 · P2 · onboarding — index entered on the golfer card is not reflected on Home ("INDEX 0 OF 3").** OBS: 18.2 typed at 13:21; Home "Three rounds and your index goes live… 0 OF 3"; Clubhouse "YOUR INDEX 18.2" (10, 36). REC: "Starter 18.2 · 0 of 3 rounds until it's yours".

**N-18 · P2 · comprehension — "Cup Final" mechanics under-specified.** OBS: "top seeds only, whoever's hottest takes the cup" is all there is; how many seeds, what others do in the last 4 weeks, how a squad wins 60% — unstated (20). REC: a worked example in the (i).

**N-19 · P2 · monetization — buy-in stepper has no $10/$20 and jumps $75 → None.** (values None/25/50/75/100/150/200) REC: free entry field or $5 steps.

**N-20 · P2 · terminology — "NEXT · Open · PLAN A ROUND" reads as "next league round is open"; it is the calendar.** (10, 95) REC: "TEE SHEET · nothing planned · PLAN ONE".

**N-21 · P2 · comprehension — week/month/season are three clocks, never explained together.** OBS: Sunday "Week closes — snapshot recorded" dots; season starts Saturday; monthly caps/floors; "Δ WK" (59, 60). REC: one "How the calendar works" line on the Schedule page.

**N-22 · P2 · gameplay — live stepper's first tap = par, unannounced.** (91, 92) REC: show "tap + to start at par" or start at par visibly.

**N-23 · P2 · rules — Wolf and Sunningdale Rules are offered without rules.** (86) REC: an (i) with a 3-line how-to for each game.

**N-24 · P2 · gameplay — side-game cash is not kept anywhere; "stakes" are never money.** OBS: live settlement "DANA → MIKE $2" disappears after the round; Pot › Post a stake says "Pride, on the books — never money" (92, 97). REC: archive the settlement to the Pot/record, or say up front that the app won't.

**N-25 · P2 · visual-hierarchy — three stacked dialogs after posting; "Turn off this link" in a welcome dialog; duplicate "Your first round is on the board" rows.** (72, 73) REC: one celebration, share as a secondary action, no destructive link control in a welcome.

**N-26 · P2 · comprehension — "COUNTS ON YOUR CARD" after posting reads as "counted"; no points on the posted card or receipt.** (72, 77) REC: "Practice · on your card · season starts Sep 5" or "5 pts to Squad 1".

**N-27 · P2 · navigation — two "Add" buttons on the live setup (guest Add vs home-screen banner Add); my tap opened the wrong thing.** (85–88) REC: dismiss the banner on task screens; label the guest button "Add guest".

**N-28 · P2 · onboarding/retention — every cold open shows a signed-in user the sign-in door for ~6–8 s ("Boot stalled at [league-data]").** (99, 100, 101) REC: a loading state that isn't the sign-in screen.

**N-29 · P2 · terminology — "Cancel & delete this league" is the most prominent action on the league card; the invite code is the last thing on the page.** (36) REC: swap prominence; put Code + Share at the top until 4 have joined.

**N-30 · P2 · comprehension — GHIN copy on the golfer card ("that's identity, not your number") is cryptic; the settings copy is clear.** (07, 81) REC: reuse the settings wording on the card.

**N-31 · P2 · navigation — empty-name [Start the league] does nothing, silently.** (13) REC: inline validation.

**N-32 · P2 · terminology — "Start the league" opens a 3-step wizard; the league already exists after the name sheet ("Desert Dogs is on the books — set the bylaws").** REC: "Next: set the rules".

**N-33 · P2 · social — "Cups & events · 1 · Played in" on You after zero events; "No hardware yet" right after "You broke 100 · Pinned to your card".** (79) REC: fix the counters.

**N-34 · P3 · visual — the orange + FAB covers text on Home ("AROUND YOUR BUDDIES"), wizard summary, and the live sticky bar overlaps the attest paragraph.** (10, 15, 90) REC: bottom padding on scroll containers.

**N-35 · P3 · visual — "FIRST TEE SUN SEP 5" on You vs "Sat Sep 5" everywhere else; "2 mo" label shown for two different end dates; Papago listed twice in course search; "9 1" odometer digits render as "9 1 gross" in text.** (79, wizard, live search, 74) REC: consistency passes.

**N-36 · P3 · polish — the door footer reads `v23 · __CS_VERSION__`; the sign-in email subject says "Confirm your email address" while the app says "sign-in code".** (01, 03)

**N-37 · P3 · terminology — three label sets for the same point band ("Rough day, posted anyway" / "Posted anyway · rough day" / "POSTED ANYWAY"); "the ⊕" vs "Post"; "invite link" vs "invite code".**

**N-38 · P3 · onboarding — the Save button on Card & settings changes from "Save card" to "Save changes" on first keystroke; "Save card" with no changes still toasts "Card saved".** (81–84)

