# Blind UX audit — Agent 5: Organizer / Commissioner ("Casey Ortega")

Persona: the one person in a group of seven friends who is willing to set up and run a competitive golf season. ~30 rounds/year, ~14 handicap, home course Papago Golf Course, Phoenix AZ.
Account: jerecho+blind1@fischbeck3.com. Session: `org` (iPhone viewport, headless).
Key question: **Is creating and running a season simple enough that one person will actually do it?**

All screenshots live under `../screenshots/org/`.

---

## Timeline

- 13:18:42 UTC — session started, app opened cold at http://127.0.0.1:8791/

---

## JOURNEY A — DISCOVERY (signed out, cold)

Screen: `01-door.jpg`. Copy on screen, verbatim:

> C U P   S E A S O N
> Rally your crew. / Post real rounds. / **Take the cup.**
> [Continue with email]  [I have an invite code]
> By continuing you agree to the Terms & Privacy Policy.
> v23 · __CS_VERSION__

**3 seconds:** Orange flag-in-a-hole logo, big serif wordmark, three-line slogan, one orange button. Definitely golf. "Take the cup" means there's a trophy.
**10 seconds:** "Post real rounds" — I'll be entering my actual scores. "Rally your crew" — I bring my friends. "Cup" — some kind of championship. Two ways in: email, or an invite code (so someone else can invite me into something).
**30 seconds:** I can tap "Continue with email" to start. I can't do anything else. There is no "how it works", no screenshot, no sample, no "what is a season". The bottom line `v23 · __CS_VERSION__` looks like a developer placeholder that leaked — small trust ding for an organizer about to ask six friends to sign up.

Tapped **[I have an invite code]** (1 tap): reveals a field with placeholder `LEAGUE CODE` and a `[Join]` button (`03-invite-code-door.jpg`). The button says "invite code", the field says "LEAGUE CODE" — I assume they are the same thing. So there are "leagues", and they have codes.

Tapped **[Terms]** (1 tap): nothing visibly happened in my view. It's a `target=_blank` link to `/legal.html#terms`, so on a phone it opens a new tab — fine, though the tap gave no feedback in the app. I opened it (`04-legal.jpg`). Notable: the *Prize Pool Disclaimer* tells me more about what the product is than the door does: "CupSeason is a golf league management app for private groups who play real, handicapped golf together … CupSeason does not collect, hold, transfer, or distribute money, takes no fee or cut of any prize pool". As an organizer this is important information (I now know money is between us, not via the app) and I only found it in the legal fine print.

### Cold answers to the 10 discovery questions

1. **What does the app do?** Lets a group of golf friends compete over a stretch of time by entering their real scores. Somebody "takes the cup" at the end.
2. **Primary action?** "Continue with email" — sign up. After that, presumably "post a round".
3. **What is a "season"?** Guess: a multi-week/multi-month window during which rounds count. No idea of the length or who decides it.
4. **What is a "league"?** Guess: my group of friends. The invite-code field calls it "LEAGUE CODE" so a league is the thing you join with a code.
5. **What is a "cup"?** Guess: the trophy/championship at the end of the season. Could also be a playoff. Unknown.
6. **Competing for?** "The cup". Bragging rights? Money? Nothing on the door says money; the legal page says prize pools exist but are handled by us.
7. **Against whom?** My crew / my league. Maybe teams? Unknown.
8. **How do rounds work?** "Post real rounds" — I play golf anywhere and type in my score afterwards. Whether it's gross/net/handicapped is not stated (legal page says "handicapped golf").
9. **After a round?** Unknown. Presumably I get points or move on a leaderboard.
10. **Different from just playing with friends?** It keeps a running score across many rounds and crowns a winner. That's the pitch I infer; nothing on screen says it.

USER ASSUMPTION: "invite code" and "LEAGUE CODE" are the same thing.
USER ASSUMPTION: the app is free (nothing says otherwise).
USER ASSUMPTION: "the cup" is a trophy at the end of a season.

---

## JOURNEY B — SIGN UP / ONBOARDING

- 13:20:32 tapped **[Continue with email]** → an email field (`you@email.com`) + `[Go]` appear inline under the button (`05-email-step.jpg`).
- 13:20:53 tapped **[Go]** → field `CODE FROM EMAIL` + `[Verify]` + "Sent to jerecho+blind1@fischbeck3.com. Type the sign-in code from the newest email." + `Resend code (26s)` (`06-code-step.jpg`).
- Email arrived **within ~1 second** (Gmail stamp 13:20:52). Subject: "Confirm your email address". Body snippet: "Welcome to Cup Season Your sign-in code: 20470124 Type it on the sign-in screen. The code expires in an hour."
- Typing the 8-digit code **auto-submitted** — the `[Verify]` button was gone before I could tap it. Fine, but the visible affordance (Verify) and the behaviour (auto-verify) disagree. Time from Go to signed-in: ~30s, all of it me reading email.
- No password, ever. Good.

### Golfer card (`07-after-verify.jpg`, `09-golfer-card-2.jpg`)
Header: "✓ SIGNED IN · Set up your **golfer card.** Just a name and a marker to start — this card follows you into every league."
Fields, in order, with what I thought each meant:
1. `NAME ON THE CARD` (placeholder "First name or nickname") — obvious.
2. `YOUR HANDLE — HOW BUDDIES FIND YOU`, prefilled `@jerechoblind1` (derived from my email). "A starting handle — tap to change it." When I typed "Casey" the handle **silently changed itself to `@casey`** ("@casey is available ✓"). Helpful, but nothing told me it would follow the name; I noticed only because I was reading the text dump.
3. `HANDICAP INDEX · OPTIONAL` (placeholder "e.g. 12.4"): "Know your index? Enter it as a starting point — otherwise your first three rounds set it, and it keeps adjusting as you play." I entered 14.2. USER ASSUMPTION: my 14.2 is my handicap in this app. ACTUAL: the next screen (Home) said `INDEX 0 OF 3 · Three rounds and your index goes live.` — so the app treats what I typed as provisional and will replace it with its own number. I would not have known that from the card.
4. `[+ Add your GHIN number]` → reveals `GHIN # · e.g. 1234567` with "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." I skipped it. Term recorded: the app's index ≠ GHIN index.
5. `BALL MARKER` — 14 tiles: THE SAGUARO, THE ISLAND, THE LIGHTHOUSE, THE LONE TREE, THE PEWS, THE DUNES, THE BEVERAGE, THE SHARK, THE AZALEA, THE JUG, THE WEE BRIDGE, NO. 2, THE POSTAGE STAMP, THE THISTLE. I understood these as an avatar/icon (famous-hole nicknames). "Ball marker" is a cute name for "avatar" but nothing says that; a less golf-literate friend might think it's asking what physical marker they use.
6. "City and home course live on your card — add them any time from the You tab." — I wanted to set Papago as my home course here; deferred to a tab I haven't seen yet.
Tapped **[Save my card]** (13:22:49). 5 taps + 2 fields total.

### "Four places. Two ways to play." (`12-after-card.jpg`)
Interstitial: "Thirty seconds, then you're in." Four tiles — **Home** "everything you're in, one feed" · **Clubhouse** "one league: table, board, pot" · **The ⊕** "before, during and after a round" · **You** "your card, record and buddies". Then **THE LONG GAME — A league**: "Months. Every round counts toward a table." and **THE SHORT GAME — An event**: "A weekend or a few weeks. Its own little trophy." "You can run both at once. An event stands alone, or attaches to a league." `[Take me in]` · "Reopen this any time from You › How it works."
- This is the app's only orientation screen and it is decent. But: the words **season** and **cup** — the app's own name — are not defined anywhere on it. New terms introduced without definition: *table*, *board*, *pot*, *event*.

### Home, no league (`14-home-empty-full.jpg`)
- Top: `[Start a league] [Start an event] [Join a league]`. Then "Post a round — it counts on your card. Leagues score it when you join one."
- `YOUR CARD — Three rounds and your index goes live. Nothing else needed. INDEX ●——— 0 OF 3 [Post your first round]`.
- Three tiles: `LEAGUE None yet / JOIN OR START` · `NEXT Open / PLAN A ROUND` · `BOARD — / LEAGUE ONLY`.
- Then, with NO league: "**Monthly floor · 2 rounds a month.** Miss it and your squad loses 5 points for every round you're short. Short months are waived." — a rule about a "squad" I don't have, in a league I haven't made. Terms: *floor*, *squad*, *short months*.
- "AROUND YOUR BUDDIES — No rounds from your buddies yet. Post one, or add some buddies."
- Bottom nav: HOME · (floating orange ⊕) · CLUBHOUSE · YOU. The ⊕ is not labelled; the interstitial called it "The ⊕".

---

## JOURNEY C — CREATE A LEAGUE (for me + 6 friends)

**13:23:43** tapped `[Start a league]` (1 tap from Home).

### Sheet: "Name your league" (`15-wizard-1.jpg`)
"THE BANNER EVERYTHING HANGS UNDER" · placeholder "The Big Slice, The Sunday Cup, Dew Sweepers…" · "You can rename it any time before the bylaws lock." · `[Start the league]`.
- Term: **bylaws** (never defined; I inferred "the rules"). Term: **lock**.
- Tapped `[Start the league]` with the field empty (my harness fill had failed): **nothing happened at all** — no error, no shake, no hint. 1 wasted tap.
- Entered "The Papago Grind" → `[Start the league]` (13:24:55). A toast I only caught in the accessibility tree: "The Papago Grind is on the books — set the bylaws". So the league is **created at this moment**, before I've decided anything.

### Wizard step 1/3 (`17-wizard-3.jpg`)
Header: "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE". `LEAGUE NAME` (prefilled) · `PRO — THAT'S YOU: Casey @casey · you run this league — THE PRO`. `[Cancel] [Next →]`.
- Term: **the Pro** = the organizer (me). I got it from context; a friend would not.
- "LOCKS AT FIRST TEE" — I read this as "settings freeze on the season's first day (Sep 5)". Keep this in mind; it collides with what comes later.

### Wizard step 2/3 — "COMPETITIVENESS — PICK ONCE, ARGUE NEVER" (`18-wizard-step2.jpg`, `19-comp-info.jpg`)
Three preset cards, Standard pre-checked:
- **Casual** "Honor scores, everything counts" — `100% hcp · honor scores · any course · unlimited counting · no floor`
- **Standard** "Weekly-golfer fair, light guardrails" — `95% hcp · GHIN rounds · best 4 / mo count · 2-round floor`
- **Cutthroat** "Tournament-tight, receipts required" — `90% hcp · verified + attested · rated tees · best 4 / mo · 3-round floor`
Below: "Standard: 95% handicap, GHIN-posted rounds, your best 4 a month count, post 2 or the squad feels it. The default for a reason." `[Use these defaults →]` · `[Customize ˅]` · `[← Back] [Next →]`.
- The shorthand is dense: *hcp*, *honor scores*, *GHIN rounds*, *counting*, *floor*, *attested*, *rated tees* — seven jargon items in three lines, none defined on the card.
- My real question as organizer: "GHIN rounds" — does Standard mean my buddies without a GHIN can't post? I skipped GHIN on my own card two minutes ago. The (i) explainer (accessible name "About competitiveness presets") says: "One pick that bundles the fairness rules: handicap allowance, score verification, and eligible courses. Casual is honor-system beer league, Standard wants GHIN-posted rounds, Cutthroat adds attestation and rated tees. Every individual dial unlocks with Pro Shop." — it repeats the question rather than answering it, and introduces **Pro Shop** (sounds like a paid tier) even though a `[Customize]` button sits right there.
- Layout bug: the floating ⊕ button physically covers the explanatory sentence ("Standard: 95% handicap, [⊕]osted rounds…") at phone width (`19-comp-info.jpg`).
- The tapped (i) gave no visual feedback that it was a toggle; I had to read the tree to confirm it expanded.

### Customize (the real decisions) (`21-customize-open.jpg`, `22-cust-buyin.jpg`, `23-cust-teams.jpg`, `26-customize-all-info.jpg`)
Opening `[Customize]` reveals **nine** more decisions that "Use these defaults" would have silently made for me:
| Dial | Default | What I understood | Consequence clear? |
|---|---|---|---|
| **Buy-in** "Per player · $0 = bragging rights" | **$75** | money each friend owes | **No.** A $75 default hidden behind "Customize" means an organizer who taps "Use these defaults" has committed six friends to $75 each without seeing it. Steps are None/$25/$50/$75/$100/$150/$200 (mapped by tapping). |
| **Season length** "Weeks or months · ends the same weekday" | 6 mo | how long | Yes; − steps 6→5→4 mo, dates recompute live ("Sat Sep 5 – Sat Jan 2"). |
| **First tee** | 2026-09-05 (a week out) | start date | Yes. |
| **Teams** (i) | 2 Squads | individual vs teams | Partly — see below. |
| **How teams fill** (i) | Blind draw / Assign | who picks teams | Yes after the (i). "Live draft night … is on the Pro Shop roadmap." |
| **How it ends** (i) | Cup Final / Points table | how the champ is decided | Half. "Cup Final: the last four weeks reset and score fresh — top seeds only, whoever's hottest takes the cup." What is a *seed*? Top how many? |
| **The pot split** (i) | Balanced 60/25/15 · Winner-heavy · Spread it | who gets the money | "champ / runner-up / **Points King**" — Points King is defined only inside the (i): "best individual all year". Also the (i) is where the app finally says: "The pot lives on the books here — the app keeps the ledger, money moves friend-to-friend." That sentence belongs next to the buy-in dial. |
| **Counting cap** (i) | Best 4 rounds/month | fairness cap | Yes, good explainer ("the retiree who plays daily can't bury the dad who plays weekly"). |
| **Participation floor** (i) | 2/mo · "−5 SQD PTS SHORT" | minimum rounds | Yes after (i): "One Pro-approved bye month per season covers vacations and injuries." — **bye** is a new mechanic that appears only here. |

Teams sub-copy per option (read by tapping each): Solo "Individual · every player for himself — works at any size (4+). No squads; top 2 players meet in the Cup Final in the final four weeks." · 2 Squads "fits 4–7 players. Both squads reach the Cup Final; the regular-season leader carries a +10 head start." · 3 Squads "fits 6+. Cut line after 2nd: top 2 advance." · 4 Squads "the full cup experience for 8+ players." Plus a persistent orange line: "1 golfer staged — solo fits. Bigger squads open up as more join, by code or invite."
- Term: **staged** (= joined but not locked?). Never defined.
- With 7 players, 2 squads = 3 v 4. Nothing says how uneven squads are scored. USER ASSUMPTION: some averaging. ACTUAL: unknown from the UI.
- "+10 head start" — 10 of what? I now assume "points", but I still don't know how a round becomes points.
- The helper line under the segmented control showed "4 squads · …" while "2 Squads" was the highlighted option (before I touched it) — the description and the selection disagreed on first paint.

My choices: Standard · **$50** buy-in · **4 mo** (Sat Sep 5 → Sat Jan 2, 17 wks) · 2 Squads · Blind draw · Cup Final · Balanced · Best 4 · floor 2/mo. Time in step 2 including reading every (i): ~7 minutes (13:24:55 → 13:31:44).

### Wizard step 3/3 — "REVIEW THE BYLAWS, THEN LOCK IT IN" (`30-wizard-step3.jpg`)
Summary table: STRUCTURE 2 squads · Squad formation Blind draw · PRESET Standard · HANDICAP ALLOWANCE 95% · **VERIFICATION Attested** · COUNTING CAP Best 4 / mo · PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short · BUY-IN $50 / player · POT SPLIT 60 / 25 / 15 · champ / 2nd / king · SEASON 4 mo · Sat Sep 5 → Sat Jan 2 · 17 wks · CUP FINAL Final 4 weeks · from Sun Dec 6 · scored fresh.
"Lock opens the invite link — one link fills the league; anyone can also join later with the league code. Minimum four to tee off." `[Lock the bylaws & form the squads]` `[← Back]`.
- **"VERIFICATION Attested"** — I never chose "attested". Step 2 said Standard = "GHIN rounds"; Cutthroat = "verified + attested". The review uses a third vocabulary. As the Pro I now cannot tell my friends what verification rule we're under.
- **Lock paradox.** The button says "form the squads" but "Roster 1 in" — I'm the only one here. The copy says the invite link only opens AFTER lock. And the header still says "LOCKS AT FIRST TEE". Three different lock moments in one screen. USER ASSUMPTION: tapping this will blind-draw squads with one player and freeze the rules before anyone joins. ACTUAL: (see below — it never succeeded, so unknown.)
- "Minimum four to tee off" — new constraint surfaced only on the last screen.

### 13:32:14 — LOCK FAILS (P0)
Tapped `[Lock the bylaws & form the squads]`. **Nothing visible changed** (`31-after-lock.jpg`). The only feedback was a status-region message I found in the accessibility tree: "Lock failed. Something went wrong — please try again." Console: `[cs] error: Lock failed. staged is not defined`.
Attempts: (1) tap again → same; (2) ← Back → Next → Lock → same; (3) navigated to Clubhouse — **the Clubhouse tab shows no league at all** ("League play — cup season · [Start a league] [I have an invite code] [Add golfers] [Sign out]"), while Home shows "THE PAPAGO GRIND · FORMING · 7 days · Just you so far. Lock the bylaws and the invite link is yours. ROSTER 1 IN [Lock it in and invite your crew]" (`34-clubhouse-after-failed-lock.jpg`, `35-home-after-failed-lock.jpg`); (4) Home → "Lock it in and invite your crew" → review step (choices preserved) → Lock → same error; (5) full page reload → same.
(6) reload → Home → "Lock it in and invite your crew" → Lock → same `staged is not defined`. **Six attempts over 3 minutes; the primary setup path is broken.** From the user's chair: the big orange button does nothing.

### 13:36:30 — The league "room" (found by accident)
Tapping the Home tile `LEAGUE The Papago Grind — OPEN THE ROOM` opens a screen the Clubhouse tab did not (`37-league-room-forming.jpg`):
"YOUR GROUPS [The Papago Grind — HERE] · **The Papago Grind** · Squad formation · `[Code · THEPTCQ5]` · Sat Sep 5 → Sat Jan 2 · 17 wks · THE PRO · CASEY · `[Add golfers]` · Cancel & delete this league (only possible before the first tee)".
Sub-tabs: `Standings · Board · Schedule · Pot · Album · League`. Standings shows: "SQUADS ARE FORMING — **The Pro has the list.** 1 PLAYER IN THE POOL · 3 SEATS OPEN · `[Form the squads]` · `[Share the invite link]`", then "THE INDIVIDUAL RACE · EVERY PLAYER — Points King / Most Improved · needs 2+ rounds / Iron Man", a table `PLAYER · R · AVG VS INDEX · PTS` with me at 0, and "Points King takes 15% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with the squad race — bylaws §4."
- **The league code exists before the lock**: `THEPTCQ5`. The wizard told me "Lock opens the invite link" — untrue, or at least the code is already here. I only found it because the lock failed and I went looking.
- "3 SEATS OPEN" — I have six friends coming. The number seems to be about the minimum-four rule, but it reads as a capacity of 4. USER ASSUMPTION: my league holds 4 players. ACTUAL: unknown; 2 squads "fits 4–7" per step 2.
- "The Pro has the list." — what list? No list is shown.
- "bylaws §4" — a citation to a document I have not been shown. Where are the bylaws?
- Terms: *pool*, *seats*, *Points King*, *Most Improved*, *Iron Man*, *R* (column), *Avg vs index*.
- 13:37 tapped `[Share the invite link]` → the only result was a status message "Invite code: THEPTCQ5" (found in the tree). No link, no share sheet, no "copied" confirmation on screen (`38-share-invite.jpg`). The button says *link*; it gives a *code*.
- Tapped `[Code · THEPTCQ5]` chip → same status "Invite code: THEPTCQ5"; no visible feedback (`40-code-chip.jpg`). (My headless browser reports `navigator.share` undefined and clipboard read denied, so a real phone may get a share sheet — but the *visible* fallback is a code, not a link, and no "Copied" ever appears on screen.) The DOM contains the template `https://cupseason.app/?join=` — so a link like `https://cupseason.app/?join=THEPTCQ5` probably exists, but the app never displayed it to me.

### 13:38 — `[Add golfers]` (`41-add-golfers.jpg`)
Sheet: "Add golfers — INVITED GOLFERS GET A NOTIFICATION AND CHOOSE TO JOIN · [Find golfers by name or @handle] · Type a name or @handle to search — buddies you add appear here. · [Share an invite link instead]".
- **There is no way to invite by email or phone.** Typing `jerecho+blind2@fischbeck3.com` → "No golfers found. Invite links still work for everyone else." (`42-add-golfers-email.jpg`). My six friends have no accounts; this sheet cannot reach them.
- Typing `@jerecho` returned two people I do not know — "Jerecho Fischbeck ✦ Founder @jerechofischbeck · Phoenix, AZ" and "jerechosb @jerechofischbeck1" — each with an `[Add]` button (`43-add-golfers-search.jpg`). So the search is a global directory of every user, and I can drop strangers into my private money league. Social/privacy concern both ways.
- `[Share an invite link instead]` → the same "Invite code: THEPTCQ5" status. Sheet stays open. (`44-share-link-instead.jpg`)
- Net: **the invitation an organizer needs — "send this to my six friends" — is a code to be relayed by hand.** The app never showed me a message to paste, a link to copy, or an email/SMS path.

### League sub-tab (`45-league-tab.jpg`)
"LEAGUE — Members & invites · 1 PLAYER [View] · 🔗 Share the season · A public page — the standings so far, no account needed [Link] [✕] · Squads · **LIVE NOW — CAPTAINS READY** [View] · ▶ LEAGUE RULES & PRO SHOP (collapsed)".
- "Squads · LIVE NOW — CAPTAINS READY" while the Standings tab says "Squads are forming". Two statuses for the same thing on adjacent tabs; neither is true (no squads exist).
- Expanding "League rules & Pro Shop" shows "The bylaws · locked at first tee" + the same review table + `[How scoring & handicaps work →]`, then "The Pro Shop · CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE · SOON Custom rules, every dial unlocked · SOON Live draft night with pick timer · SOON Trades & waiver wire · SOON Multi-season history & records · [Coming at launch]". So "Pro Shop" = a future paid membership; "the pilot rides free" — am I "the pilot"? Unclear who pays what, when.
- **This collapsed panel is the only place the league's rules are written for my friends.** "The bylaws · locked at first tee" — a third statement of when locking happens (wizard button said lock now; Home says lock now; this says first tee).

### 13:41 — "How scoring works" (League tab → expand "League rules & Pro Shop" → `[How scoring & handicaps work →]`) (`49-scoring-help2.jpg`)
Verbatim, because it is the single most important text in the app and it is four taps deep:
> **HANDICAPS · CUP POINTS · THE MONEY**
> **Your number** — Your handicap index builds from your scores — no typing. Every round measures how you played against the course's difficulty (rating & slope), and your best recent rounds set your number, WHS-style. It appears once you've posted 3 rounds; until then it shows as building. You (or the Pro) can set a starter to get going sooner — but once you have 3 posted rounds, your scores take over. Manual changes are announced to your league so the crew keeps everyone honest.
> **Every round → cup points** — Every round is scored against your own number — a 22-index beating their number is worth exactly what a 6-index beating theirs is: Torched it · beat it by 3+ · **12 pts** / Beat your number · by 1–3 · **9 pts** / Played to it · within 1 · **7 pts** / A little loose · 1–3 over · **6 pts** / Posted anyway · rough day · **5 pts**. The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82. You can't hurt your squad by playing badly — only by not playing.
> **What counts** — Your best rounds each month count for your squad — a better round always bumps your worst counter — and everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your season bye covers you automatically — life happens; the floor bites from the second miss. Your league's exact numbers are in League rules.
> **The money** — The pot is on the books — Cup Season keeps the ledger and shows a settlement card; the money moves between you.

- This finally answers "how does a round become points" and "what happens if I miss a week". It is excellent copy. **It is not linked from the wizard, from Home, from the onboarding interstitial, or from the Standings tab.** I found it 18 minutes after starting the wizard, and only because the lock failed and I went digging.
- Still unanswered here: how squad points are compared when squads are uneven (3 v 4); what "seeds" are; how the "+10 head start" works; what the 95% "handicap allowance" does to my number; what "Attested" verification asks of a player when posting.

### Members & invites (League tab → View) (`50-members-view.jpg`)
"1 PLAYER · CODE THEPTCQ5 · Casey · THE PRO @casey · **INDEX 14.2** · [Marker here] · [Add golfers] · [Share the invite link]".
- Here my index is 14.2; on Home it is "0 OF 3 — building". Two truths about the same number, one screen apart.

### Squads → View (`51-squads-view.jpg`)
Full-screen "FORM SQUADS · BLIND DRAW — **1 in the pool** — THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW — [Draw squads] — Squad 1 · 0 PLAYERS · Empty — Squad 2 · 0 PLAYERS · Empty — PLAYER POOL / THE POOL — [Casey]".
- **No back, close, or done control.** The only exits are the bottom nav tabs. (Same for the wizard: Cancel exists on step 1 only.)
- The League tab labelled this "LIVE NOW — CAPTAINS READY". There are no captains anywhere on this screen.

### 13:42 — `[Draw squads]` on the Form-squads screen
Status shown to user: "Draw failed. Something went wrong — please try again." Console: `Draw failed. Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.` — **the server wrote a perfect, actionable error and the UI replaced it with a generic one.** (`53-draw-squads-tap.jpg`)

### Pot tab (`54-tab-Pot.jpg`)
"SEASON STAKES — THE POT **$50** — 1 × $50 · $0 collected · 1 still owe — $30 CUP CHAMPS · $13 RUNNER-UP · $8 POINTS KING — **Cup Season keeps the books.** Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar. — BUY-INS · 0/1 IN — [Casey ☐] — THE OTHER STAKES · PRIDE, ON THE BOOKS — [Post a stake] — No stakes on the books. The cookout isn't going to bet itself."
- Money model is clear here (ledger only, friends pay each other). This is the sentence the buy-in dial in the wizard needed.
- $30 + $13 + $8 = $51 on a $50 pot (rounding shown as truth).
- "$30 CUP CHAMPS" (plural) for a 2-squad league: does the whole winning squad split $30? For 7 people at $50 = $350, champs get $210 for a squad of 3 or 4 — the app never says how a squad payout is divided among its members.
- The ☐ next to my name appears to be "mark as paid" for the Pro. Nothing labels it.
- "Post a stake" — side bets on the books; term *stake* vs *pot* vs *buy-in* — three money words on one screen.

### Schedule tab (`55-tab-Schedule.jpg`)
Tapping "Schedule" inside the league room **navigates out of the room** to a global page: "← HOME · YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES' · THE CALENDAR ← AUG 2026 → · legend: ON THE TEE SHEET / LEAGUE MATE / SEASON DATE · [Put a round on the tee sheet] · ON THE TEE SHEET — Nothing on the tee sheet for Aug. Put one up: league mates and buddies see it the moment you do." The back link goes to Home, not to the league. Term: *tee sheet* (= planned rounds, I think).

### Board tab (`58-tab-Board2.jpg`)
"The board · rounds land here automatically · [OPEN ↗] · Today · Aug 29 · ◆ **The Papago Grind is live** — post the first round · [Message the league…] [📣] [Send]".
- The league is described as *forming* (Home), *Squad formation* (room header), *LIVE NOW — CAPTAINS READY* (League tab), and *live* (Board) — four statuses for one unlocked, one-member league. As the Pro I cannot tell my friends what state we are in.
- The board is a chat + feed. "📣" is unexplained (I guess: announce/pin).

### 13:44 — "Share the season" → `[Link]` (League tab)
Status: "**Could not make the link. Please sign in again.**" I am signed in (I just created a league). Second broken share path in five minutes. (`60-season-share-tap.jpg`)

### Step 4 of the brief — "with nobody having joined yet, what does the app tell you to do next?"
- Home: "Just you so far. Lock the bylaws and the invite link is yours. ROSTER ● 1 IN [Lock it in and invite your crew]" — clear instruction, but the button leads to a step that fails every time.
- Room/Standings: "SQUADS ARE FORMING — The Pro has the list. 1 PLAYER IN THE POOL · 3 SEATS OPEN [Form the squads] [Share the invite link]" — the first button fails (with a hidden helpful reason), the second yields a code.
- **What a friend sees when they join: the app never shows me.** There is no preview of the join screen, no invite message text, and Members & invites lists only me. I would have to text six people "download Cup Season, tap 'I have an invite code', type THEPTCQ5" and hope.

---

## JOURNEY D — FIRST ROUND

13:45:14 tapped the floating ⊕ (accessible name "Post a round"). It opens a full screen "GOLF · BEFORE, DURING AND AFTER THE ROUND" with three cards (`61-post-sheet.jpg`):
1. "● LIVE — **Play now — score the group live** — Hole-by-hole · match play, Wolf & the settle-up · every complete card posts at the finish. Guests welcome, no account needed. →"
2. "**Post a round — after you play** — Gross + tee, 20 seconds · counts on your card and in every league →"
3. "**Plan a tee time — before** — Put a round on the tee sheet · your buddies and leagues see it the moment you post →"
- Good: this is the first screen that made the before/during/after model click. "Side games" are discoverable here (match play, Wolf, settle-up) without being told.
- Terms: *Wolf*, *settle-up*, *tee sheet*, *card* (my golfer card vs a scorecard — "every complete card posts" means scorecard; "counts on your card" means profile).

### Answers BEFORE entering anything (from the UI only)
1. *How do I know what round I'm playing?* I don't — there is no "this week's round". The league is "every round counts"; I just post whatever I played.
2. *Who am I playing?* Nobody in particular. Season = me vs my own number, summed for my squad. (Learned from the scoring explainer, not from this screen.)
3. *What format?* Stroke play vs my handicap, banded into 5/6/7/9/12 points. Unstated on this screen.
4. *What are the rules?* League tab → collapsed panel → link. Not from here.
5. *How are handicaps applied?* "95% allowance" per bylaws; what that does to my 14.2 is never shown.
6. *What do I need to enter?* "Gross + tee, 20 seconds" — so a total score and which tees.
7. *What counts toward the season?* "counts on your card and in every league" — so every posted round counts (subject to best-4/month, which is not mentioned here).
8. *What counts toward side games?* Unknown; presumably only the LIVE door.
9. *If something goes wrong?* Unknown; no mention of edit/delete anywhere yet.

### Post a round form (`62-post-round-form.jpg`)
"← GOLF · POST A ROUND · YOUR INDEX 14.2 · COURSE & TEES [Search a course, or type your own] · RATING [72.1] · SLOPE [128] · YOUR CARD [18 holes | 9 holes] · FRONT 9 GROSS [41] · BACK 9 GROSS [43] · 'How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round.' · DATE [08/29/2026] · [Scan the card] [Add a photo] · 'Enter your card to see the score.' [Post round] · Start over — clear this card · HOW THIS ROUND SCORES — LEAGUE POINTS THIS ROUND — Enter at least one nine. — GROSS / VS YOUR INDEX — 'No league yet? The round still counts on your card — points apply in any league you join.' · POINT BANDS: Beat your index by 3+ 12 / Beat it by 1–3 9 / Within a stroke either way 7 / Over by 1–3 6 / Rough day, posted anyway 5 · 'Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time.'"
- **This is the best screen in the app.** The point bands and the best-4 rule are right where the score is entered. My earlier Journey-D questions 3, 6, 7 are answered here.
- "No league yet?" is shown even though I have a league — because it is not locked/started, I assume. USER ASSUMPTION: this round will count for The Papago Grind. ACTUAL: (see after posting).
- The index shown here is 14.2 (my typed starter); Home still says "0 of 3".
- Course search "Papago" returned **two identical rows** "Papago Golf Course · Phoenix, AZ · 13 tees" (`65-course-search3.jpg`). No way to tell them apart.
- Tee picker: 13 tees, each "Colour · Rating · Slope" (`67-tees2.jpg`). Good.
- Correction to an earlier finding: the console shows the "Share the season" failure was `Failed to execute 'writeText' on 'Clipboard': Write permission denied` — a clipboard permission problem in my browser — yet the app told me "Please sign in again." Wrong diagnosis shown to the user.

### Entering the score (`68-round-filled.jpg`)
Picked Papago → White (70.1/120); rating & slope auto-filled ("Tees set — rating and slope filled" status). Typed 44 / 43. Live panel updated instantly: "Gross 87 · 18 holes" → "LEAGUE POINTS THIS ROUND **6** — A little loose, still cash in the bank. — **87** GROSS · **-1.7** VS YOUR INDEX".
- **Sign confusion (P1).** A golfer reads "-1.7 vs your index" as *beat it by 1.7* (lower is better in golf). The band says "A little loose" = *over* by 1–3. The result sheet a moment later says "1.7 over your number" — positive. Same number, two signs, two screens.
- Also: my index is 14.2 and the bylaws say 95% allowance; the panel gives no hint whether -1.7 is against 14.2 or 13.5. I cannot reproduce the number by hand from what is on screen.

### 13:49:03 — Posted (`69-after-post.jpg`)
Result sheet: "PAPAGO GOLF COURSE · WHITE · SAT AUG 29 — **87** — 1.7 over your number — COUNTS ON YOUR CARD — [Share the card] [Back to the board]" + an "Add to home screen" nudge + "Welcome to the season ⛳ · 87 at PAPAGO GOLF COURSE · WHITE · 🎉 Your first round is on the board — Welcome to the season — your number and record start here · 🏆 **You broke 90 for the first time** · Pinned to your card · 🏆 **You broke 100 for the first time** · Pinned to your card · ⛳ Your first round is on the board — Welcome to the season · [Share a link — no account needed] [Turn off this link] · The page stops working for everyone who has it."
- The sheet says "COUNTS ON YOUR CARD" and never mentions the **6 league points** I was just shown. So: did it count for The Papago Grind or not? USER ASSUMPTION: yes, 6 points. ACTUAL: unclear — see Standings check below.
- "You broke 90 / broke 100 for the first time" on the first round ever entered: to a 14-handicap these are not achievements; they read as the app not knowing me, and they will be mocked in the group chat. "Your first round is on the board" is listed twice.
- Two share buttons in one sheet ("Share the card", "Share a link — no account needed") and a "Turn off this link" for a link I never asked for.

### Home after the round (`70-home-after-round.jpg`) and the receipt (`71-round-detail.jpg`)
- Home now shows a chip "Month closes in 2 days" and a board card "You 🎉 First round on the card · 87 gross · Papago Golf Course · White · Aug 29". (The accessibility tree reads the animated score as "5 2 9 8 8 4 1 7 gross" — an odometer effect that a screen reader will read as garbage.)
- Tapping the card opens the receipt: "**87 gross** · PAPAGO GOLF COURSE · WHITE · 18 HOLES · 2026-08-29 · The course 70.1 / 120 · 87 − 70.1 × 113 ⁄ 120 → **15.9 DIFFERENTIAL** · YOUR NUMBER THAT DAY 14.2 · Against your number **-1.7 — A LITTLE LOOSE**".
- This is the "show its work" moment and it mostly works: I can see the formula. Remaining gaps: (a) the league points (6) are not on the receipt; (b) the sign is still negative for "over"; (c) date is raw ISO while everywhere else says "Sat Aug 29"; (d) nothing about the 95% allowance; (e) **no edit, delete, or "report a mistake" control anywhere on the receipt.**

### "Could you explain to a friend exactly what just happened?" — verbatim attempt
"I shot 87 from the whites at Papago. The app turned that into a 15.9 differential — that's the 87 minus the course rating, scaled by slope. My number is 14.2, so I was about 1.7 worse than my number, which the app calls 'a little loose'. That's worth 6 points for my squad — 12 is the max if you crush your number, 5 is the floor for just posting. Only my best four rounds a month count." — I could say that, but only because I read the scoring explainer and the receipt. I could NOT tell them whether the app used 14.2 or 95% of it, why the receipt says minus 1.7 when I was over, or whether this round counted for The Papago Grind since the league isn't locked and the sheet said "counts on your card" only.

### Did the round count? (`72-standings-after-round.jpg`, `73-you-tab.jpg`)
- Standings: "01 Casey · R 0 · Avg vs index — · Pts **0**". You tab: "This season · The Papago Grind · Rounds posted **0** · Avg vs index — · Best round — · Index move —".
- **The post form showed "LEAGUE POINTS THIS ROUND 6" and the round produced 0 league points.** The season starts Sep 5; today is Aug 29. Nothing on the post form, the result sheet, or the receipt said "this is before your season — it will not count". The only hint was "No league yet?" in grey on the form — which was wrong (I have a league) and which I read as boilerplate. (P1 comprehension)
- You tab header: "Casey @casey · Member since Aug 2026 · [add your GHIN] [⚙] · **14.2 Handicap index** · FORM". Display case: "No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here." — yet the post sheet five minutes ago said two trophies were "Pinned to your card". Lifetime: "Rounds posted 1 · Best vs index **-1.7 · Career best** · Avg vs index -1.7 · **Cups & events 1 · Played in**" (I have played in zero). Recent rounds: "2026-08-29 · PAPAGO GOLF COURSE · WHITE 87 · 15.9".
- "How it works" list on You: The four places · Leagues vs events · Posting a round · Buddies, invites and claims ("Three different links, three jobs") · How scoring works. Good that it exists; nothing on Home or in the wizard points here.

---

## MISTAKES — correcting things

### Correcting a posted score
- The receipt sheet (tap the round on the board) has **no edit or delete**. The only correction control in the whole app is a small "✕" at the right of the row under "RECENT ROUNDS" on the You tab (accessible name "Delete round", tooltip "Delete this round").
- 13:55 tapped it once. Status: "**Round deleted**". **No confirmation dialog, no undo.** (`76-delete-confirm.jpg`) One accidental tap erases a round. For a money league where "rounds are never mutated" is presumably a principle, a one-tap silent delete is the wrong shape.
- There is no "edit" at all — a wrong score means delete and re-post; a wrong date or course, same. Nothing tells you that.
- After deletion: "ROUNDS POSTED 0 · BEST VS INDEX — · CUPS & EVENTS **1** · Played in" — the "played in 1" persists although I have played in nothing.

### Card & settings (You → ⚙ "Card & settings") (`77-card-settings.jpg`)
"Your card is what your buddies see · settings run the app · [Your card | Settings] · Name on the card · City · Home course · Ball marker (14) · Your photo · the marker always backs it up · [Add a photo] · Handle · **moves once / 60 days** · Findable by [All | Buddies | Nobody] · GHIN # · optional — 'A reference on your card — we never resell or verify it.' · [Save card] · Handicap index [14.2] [Update index] — 'Your index builds automatically from your posted scores … it appears once you've posted 3. Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed.' · [How scoring works →] · Your leagues: The Papago Grind · PRO · THEPTCQ5".
- "Handle · moves once / 60 days" — a lock I was not told about when the handle silently changed itself to @casey during onboarding.
- "Findable by: All" is the default — which is why strangers showed up in my Add-golfers search, and why my friends will show up in strangers' searches.
- Filled City "Phoenix, AZ" and Home course "Papago Golf Course" (free-text, no course search here, unlike the post form) → the button relabels from "Save card" to "Save changes" → "Card saved". Fine.
- Settings segment (`80-settings-segment2.jpg`): Notifications (Enable on this device · Round pings ON · Chat pings ON · Season email ON), Appearance (Charcoal / Light / Match device), **Membership & billing — PLAN FREE · PILOT — "Cup Season membership lands at launch. Nothing to pay during the pilot."**, Sign out, Danger zone → Delete my account, then "v23 · __CS_VERSION__" and Privacy · Terms · Prize pool links.
- So: the app is free "during the pilot" and a membership "lands at launch". As the organizer asking six friends to commit $50 each for four months, I cannot tell whether we will be charged mid-season, who pays (me? each player?), or how much. This is the one money question the app does not answer anywhere.

### Changing a league setting after creation
- Route found: Home → "Lock it in and invite your crew" → review → "← Back" → step 2 (`81-edit-back-step2.jpg`). It works, but it is the *creation wizard* re-entered, not an "edit league" screen; nothing on the League tab or the room offers "edit bylaws". The Customize panel re-opens collapsed, so my $50 / 4-month choices are invisible until I expand it, while "Use these defaults →" is the big orange button.
- There is no "edit name" either, despite "You can rename it any time before the bylaws lock" — the name field on step 1 is the only place, and step 1 is unreachable from Home's shortcut (it lands on step 3; Back goes to step 2; Back again to step 1 — three taps, undiscoverable).
- Tapped "Use these defaults →" from the re-entered step 2: the review still showed BUY-IN $50 · SEASON 4 mo — my customizations survived. Good outcome, misleading label: the button does not "use the defaults", it just advances.

---

## SIDE GAME AUDIT
- 13:55 — **The "Get the full-screen app: add Cup Season to your home screen" banner sits exactly on top of the floating ⊕** (`84-live-door2.jpg`; `document.elementFromPoint` at the ⊕'s centre returns the banner). Two taps on the ⊕ did nothing until I found the banner's "Not now". A new user who ignores the banner cannot reach Post / Live / Plan at all. (P1 navigation)

### Discovery
- Side games were discoverable without being told: the ⊕ → "● LIVE — Play now — score the group live — Hole-by-hole · match play, Wolf & the settle-up". Nothing on Home, in the wizard, or in the league room mentions them; the Pot tab's "Post a stake" is the only other hint.

### LIVE door → "Set up the round" (`85-live-door3.jpg`)
"← Golf · Set up the round · COURSE [Search a course, or type your own] · Tee & rating — off the scorecard [Tee][Rating][Slope] · [18 holes|9 holes] · 'Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load.' [Enter the pars] · THE FOURSOME · 1 / 4 — Casey 14.2 IDX — Open slot ×3 'TAP A PLAYER BELOW' · Tap to fill a slot · league — 'No league mates to tap yet — search the app or add a guest below.' [Search the app — add any golfer] · Add a guest [Name][Index] [Add] — 'Pick who plays with who under the game — pairings, stakes, the lot. League members post to the season; guests play every game, post nothing, no account needed. Leave index blank for an estimated 18.' · GAME FOR THIS ROUND · PICK ONE — [Just score] [Match play] [Wolf] [Skins] [Sunningdale Rules] — 'Stroke play — your card, your pace. One to four players; post when you're done.' [Tee off →]"
- Clear sentence on how side games relate to the season: "League members post to the season; guests play every game, post nothing." So a live round doubles as a season post for members. Good.
- "Sunningdale Rules" — I have no idea what that is; no (i).

### The games (descriptions appear only after you select each one)
- **Match play**: "Singles (2) or 2v2 net best ball (4). Keep scoring; we tally the match as you go." · STAKE PER SIDE · $0 = BRAGGING RIGHTS · "Match play takes 2 (singles) or 4 (2v2 net best ball)."
- **Wolf**: "A round of Wolf — needs four. We run the rotation and the side tally; scores still post." · DOLLARS PER POINT · $0 = BRAGGING RIGHTS · "Wolf needs exactly 4 players."
- **Skins**: "Low net takes the hole's skin; ties carry the pot. Two to four players; scores still post." · DOLLARS PER SKIN · $0 = BRAGGING RIGHTS.
- **Sunningdale Rules**: "Match play, no handicaps — go 2 down and you get a stroke until you climb out. Singles or 2v2. Win a hole while ahead to bank a unit." · BANK UNIT · $0 = BRAGGING RIGHTS.
- What I think they are: on-course bets for the group I'm actually playing with, scored hole by hole by the app, settled at the end, separate from the season. "scores still post" = the round also counts for the season. **They do not affect the season standings** as far as any copy says — which is the right answer to "would a round matter when I'm out of contention": yes, via the side bet, not via the table.
- Social: they need real playing partners in the same group; the app lets me add league mates (none yet), search any golfer in the app, or add a guest by name + index with no account. That is well thought out for a real foursome.
- Integration: feels integrated (same ⊕, same post-to-season), but the *season* screens never point here — the Pot tab says "Post a stake · The cookout isn't going to bet itself" and never links to Live games; nothing in the wizard or league room says "your buddies can run match play / Wolf / skins inside the season".
- Friction so far: the guest "Add" with an empty Name did nothing and said nothing (2nd silent no-op of the session); the Wolf/Match-play player-count rules only appear after selecting; no (i) for Sunningdale.
- Terms: *net best ball*, *skin*, *carry*, *bank a unit*, *side tally*.

### Setting one up (`87-live-matchplay-setup.jpg`)
- Added guest "Marco" (index 18) → "THE FOURSOME · 2 / 4 — Casey 14.2 IDX — G Marco 18.0 IDX". Selected **Match play** → "Stake per side · $0 = bragging rights [0]" and a strokes line: "**Casey vs Marco · Strokes off the low man (Casey) · estimated card — no real stroke index: Marco gets 4: holes 4, 9, 13, 18.**" — this is exactly the sentence golfers argue about on the first tee, and the app writes it for you. Best copy in the side-game flow.
- Friction: my programmatic guest-add also opened an "Add to the foursome — LEAGUE MATES AND BUDDIES ARE BELOW — SEARCH ANYONE ON THE APP" sheet on top of the form; the sheet again lets me search every user in the app.
- "estimated card — no real stroke index" until a course is chosen: honest, but the phrase *stroke index* is jargon for most weekend golfers.

> **Correction to the deletion finding above.** The console later showed `[dialog:confirm] Delete this round? It leaves your card and any league standings it counted toward.` — so a native browser confirm() *did* fire on the ✕ and my harness auto-accepted it. There is a confirmation; there is still no undo, and the confirmation is a bare browser dialog rather than the app's own sheet. Severity downgraded to P3.

### Live scoring (`88-live-scoring.jpg`) — 14:01:55
"← Golf · **ALL SQUARE** · Casey — · Marco — · Live round · Papago Golf Course · White · 70.1/120 · [Change setup] · [←] HOLE 1 · PAR 5 · SI 15 [→] · Casey 14.2 IDX · 0 STK [−] – [+] · Marco GUEST SELF 18.0 IDX · 4 STK [−] – [+] · [Group phones — everyone can score] · [Finish round & post to season] · 'Scores entered together are **auto-attested**: the group verifies everyone's round just by playing it. Guests need no account: they play every side game, appear in the settlement, and get a recap text with their scorecard and an invite when you finish. Only league members' rounds post to the season.' · [Scrap this round] · SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN YOU · Match play · singles · Casey vs Marco · ALL SQUARE · THRU 0 · STROKES OFF LOW MAN (CASEY) · $5 A SIDE".
- This paragraph is where "Attested" (the mystery word from the bylaws review) is finally explained — on the live scoring screen, after the round has started. It should be on the wizard.
- With Papago chosen the strokes moved from "holes 4, 9, 13, 18 (estimated)" to "holes 3, 6, 16, 18" and the card said "Card loaded: 18-hole pars and stroke index from the course database." Good.
- "Group phones — everyone can score" suggests my partners can score from their own phones; unclear how (QR? link?) until tapped.
- Scoring: the +/− stepper's first tap lands on par (I expected "1"), then ±1 — consistent with "the stepper opens on each hole's par", but the first tap surprised me (`89-live-hole3.jpg`). The tally is live: "CASEY 1 UP · THRU 3" and each row shows running "14 THRU 3 +1".
- **Group phones** (`90-group-phones.jpg`): "EVERYONE SCORES · IT ALL SYNCS — League members just open the app — a *Continue your round* banner is waiting on Home. Any phone can fix any score; the newest edit wins. — Marco · No account needed — the link is their pencil now and their recap after · [Copy link]". Clear and social. Status after tee-off: "On the tee, good luck everybody".
- "Copy link" for Marco → status "Copy failed — try again" (clipboard denied in my browser; the message is at least honest this time).
- 14:03:55 tapped **Finish round & post to season** with 3 of 18 holes filled → a proper dialog (`91-finish-attempt.jpg`): "**Finish the round · ONE FINISH — EVERY MEMBER'S CARD POSTS** — Complete cards post to the season, attested by the group; 1 guest gets a recap to claim. A partial card is skipped, not lost. — Casey — missing holes 4, 5, 6, 7, 8 +10 more · Marco — missing holes 4, 5, 6, 7, 8 +10 more. Those cards won't post — go back and fill in, or finish without. — [Finish — no complete member card to post] [This one was casual — post nothing]". This is the clearest "what happens if something is wrong" moment in the app — the live flow handles mistakes far better than the basic post flow does.
- 14:04:25 tapped "Finish — no complete member card to post" → settlement sheet (`92-settlement.jpg`): "**Round posted** · 0 CARDS TO THE SEASON · ⚔️ **Casey def. Marco · 1 UP THRU 3 · MARCO PAYS CASEY $5 · SETTLE UP** · 1 THRU 3 · Casey — NOT POSTED · INCOMPLETE CARD · 🎟️ Marco · GUEST RECAP — SHARE THE LINK [Copy] · [Share the card] [Share the settlement — no account needed] [Revoke a shared link]".
- The settlement card is the artifact I'd actually screenshot into the group chat — "MARCO PAYS CASEY $5" is the whole point. Contradiction: headline "Round posted" over "0 CARDS TO THE SEASON · NOT POSTED".
- Three share buttons plus a revoke on one sheet; I still could not see any link text in this browser.

### After the live round
- Board tab: "Sat · Aug 29 · ◆ **Match play: Casey def. Marco 1 UP THRU 3 · $5 on the line**" (`93-board-after-live.jpg`). Side games do post to the league board — this is the social hook, and it works without configuration.
- Pot tab → "The other stakes · pride, on the books" stayed empty; the $5 match is not a "stake". `[Post a stake]` (`94-post-stake.jpg`): "Pride, on the books — never money · Name it [The Lawn Bet] · The shape: [Loser hosts] [Winner picks the course] [Strokes next time] [Standing bounty] [Name your own] · The terms [Loser hosts the cookout] · Against: The field — first to hit it · Rides on (optional) [Sunday's duel · first ace · the Cup Final] · [Cancel] [Put it on the books] · 'Stakes settle on a party's tap and archive into the record. The pot stays money; this never is.'" — charming, but now there are four money-adjacent nouns (buy-in, pot, stake-per-side, stake) with different rules each, and the Pot tab's "Post a stake" explicitly *cannot* be money while the side game's "stake per side" explicitly *is*.

### Side-game verdict
Discoverable: yes (via ⊕ → LIVE), though nothing in the season UI points there. Understood: yes, after selecting each. Affect the season: no (rounds still post; bets settle between players). Matter when out of contention: yes — this is the best retention lever in the app. Social: strong (guest links, group phones, board story, settlement card). Integrated vs bolted on: integrated in the ⊕ and board, bolted on relative to the league room (no mention on Standings/Pot/League). Encouragement to set one up: none — no prompt, no "try a match this Saturday". Friction: guest add via empty Name is a silent no-op; clipboard-dependent share buttons fail with terse messages; player-count rules appear only after selecting a game.

---

## RULES FOR MY FRIENDS (step 8)
Where the league's rules live: Clubhouse → league room → **League** sub-tab → expand "▶ LEAGUE RULES & PRO SHOP" → bylaws table → `[How scoring & handicaps work →]`. Also You → How it works → "How scoring works" (the generic version).
- **"How do I win?"** — A friend could piece it together: best-4-a-month rounds score 5–12 points against your own number, squads total them, both squads reach a 4-week Cup Final scored fresh with a +10 head start for the regular-season leader, champ squad takes 60% of the pot. It takes four screens and two vocabularies ("Attested" vs "GHIN rounds", "Cup Final: top seeds only" vs "Both squads reach the Cup Final"). Nothing says how a squad of 3 is compared to a squad of 4.
- **"What happens if I miss a week?"** — Nothing, per se; the rule is monthly: post 2 rounds a month or the squad loses 5 points per round short, with one automatic bye month. That is stated on Home (in the weird no-league state), on the wizard (i), and in the scoring explainer. A friend who only opens the room would see "PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short" and could guess.
- Verdict: the rules exist in writing, are mostly good, and are hidden behind a collapsed panel on the last sub-tab. **I would still have to explain them verbally**, mostly to reconcile the contradictions.

## MONEY (step 9)
Buy-in set at $50 (from a hidden $75 default). What I understand: the app keeps a ledger ("Cup Season keeps the books"), nobody pays the app, I tick a box per player when they've paid me, payouts are 60/25/15 to champ / runner-up / Points King, money "moves friend-to-friend". What I don't: how a squad splits its 60%; why the split shows $51 on $50; whether the "membership" that "lands at launch" will be charged to me or to each player mid-season; how the pot interacts with side-game stakes (it doesn't, but I had to infer that).

### What a friend sees (opened `/?join=THEPTCQ5` myself, 14:05:53) (`95-join-link-view.jpg`)
Sheet: "**Welcome to The Papago Grind · THREE THINGS TO KNOW** — You're on the pot sheet: $50 buy-in. The Pro tracks who's paid; money moves between you. — You can't hurt your squad by playing badly. Only by not playing. Every posted round scores — a rough day is still points on the board. — Rounds score against your own number. Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst. — The pot lives on the books. Cup Season keeps the tab and shows who owes what; money moves between you. — [How scoring works →] — Who else plays with you? Growing the league isn't the Pro's chore — any member's link works. [Share the invite link]".
- This is a good join covenant (four bullets under a "three things" heading). **The Pro is never shown it** — I found it by typing the URL. An organizer needs to know what their friends will be told, especially about money.
- Side status on return: "Your unposted round came back — it's waiting in Post a round" — the app resurrected my abandoned live card somewhere; I did not go looking.
- Console on this load: `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` — a server-side query error on every Home load after a live round (seen twice).

Session stopped 14:06 UTC. Total elapsed as a user: ~48 minutes, of which ~9 minutes were the wizard and ~6 minutes were retrying a lock that never worked.

---

## JOURNEY A — RE-ANSWERED AT THE END (changes marked ▲)

1. **What does the app do?** ▲ Runs a months-long golf league among friends where every real round you post anywhere is scored against your own handicap into 5–12 points, best-4-a-month count for your squad, ending in a 4-week "Cup Final"; keeps a money ledger; also runs on-course side games (match play, Wolf, skins, Sunningdale) with guests and a settlement card; and short "events". Cold guess was directionally right but missed squads, points, the Final, side games and events entirely.
2. **Primary action?** ▲ Post a round (the ⊕). The door said "Continue with email"; Home said "Post your first round"; as an organizer my primary action was "Start a league", which then dead-ended at Lock.
3. **A "season"?** ▲ A league's competition window — N months from a "first tee" date to an end date (mine: 4 mo · Sat Sep 5 → Sat Jan 2 · 17 wks), with calendar-month scoring caps/floors and the last 4 weeks as the Cup Final. Never defined in one place; assembled from the wizard.
4. **A "league"?** ▲ The group + its bylaws + its pot + its board; created by "the Pro"; joined by code (THEPTCQ5) or link; has squads. Also called "your groups" and "the room" in places.
5. **A "cup"?** ▲ Still fuzzy. "Take the cup" (door), "Cup Final" (last 4 weeks), "Cup champs" (60% of pot), "the full cup experience" (4 squads), "Cups & events · 1 · played in" (You tab). I now think "cup" = the season championship; the app also uses it as a count of leagues I'm in.
6. **Competing for?** ▲ The pot (60/25/15), trophies in a "display case", "Points King / Most Improved / Iron Man" side titles, and bragging rights; side games for $ per side.
7. **Against whom?** ▲ Two squads (blind-drawn) for the cup; every individual for Points King; my playing partners for side games. Unchanged: my friends.
8. **How do rounds work?** ▲ Post gross front/back + tee (rating/slope) after any round, or score live hole-by-hole; the app computes a differential vs rating/slope, compares to my index, bands it into points. Guests can play live without accounts.
9. **After a round?** ▲ A result sheet, badges, a board story, a receipt with the formula, points to my squad *if the season has started* (mine hadn't — the form still showed "6 points").
10. **Different from playing with friends?** ▲ Every round you play anywhere counts toward a table for months; you can't hurt your squad by playing badly, only by not posting; the app referees handicaps, strokes, side bets and money so nobody argues. That is a real pitch — and the door doesn't make it.

## 30-SECOND EXPLANATION TO A FRIEND (verbatim)
"It's a fantasy-league-style golf season for our group. We're split into two squads by a blind draw. Every real round you play — anywhere, any course — you post your score and the app scores it against your own handicap: crush your number and it's 12 points, play to it and it's 7, even a bad day is 5 as long as you post. Your best four rounds a month count for your squad, and you have to post at least two a month or the squad loses points. It runs four months, then the last four weeks are a fresh 'Cup Final' and the hot squad takes the cup. Fifty bucks in, the app keeps the tab, winners split it 60/25/15 and we pay each other. And when we actually play together you can run match play or Wolf in it and it tells you who owes who at the end."

## PERSONA VERDICT
**Is creating and running a season simple enough that one person will actually do it?** — **Not today: 3/10.** The wizard is genuinely well-designed (one preset, dials behind Customize, a review table, explainers on every dial), and would take a motivated organizer ~10 minutes. But the single button that completes it failed six times with a JavaScript error and no visible message; the invite path that "opens on lock" was actually already open and I found it by accident; there is no way to invite six friends by email/SMS, only a code to relay by hand and a search of strangers; the league's status is described four different ways; the money default was $75 hidden behind "Customize"; and the rules my friends need are four taps deep behind a collapsed panel. Fix the lock bug and the invite-by-contact gap and this becomes a 7.

## GLOSSARY (as understood from the UI only)
| Term | Where seen | What I think it means | Confusing? |
|---|---|---|---|
| Cup / the cup | door, wizard, pot, You tab | the season championship; also used as a count of leagues | yes |
| Season | wizard, You tab | the league's competition window (N months from first tee) | partly |
| League | everywhere | the group + bylaws + pot + board; created by a Pro | no |
| Event | interstitial, Home | a short standalone competition ("a weekend or a few weeks") | partly — never opened |
| The Pro | wizard, room | the organizer/commissioner (me) | partly |
| Pro Shop | wizard (i), League tab | a future paid membership that unlocks custom dials, draft night | yes |
| Bylaws | wizard, room | the league's rule settings | partly |
| Lock / locks at first tee | wizard, Home, League tab | freezing the bylaws — at tap-time or at first tee, both claimed | yes |
| First tee | wizard | season start date | no |
| Squad | wizard, Home, standings | a team within the league | no |
| Staged / pool / seats | wizard, standings | players who have joined but not yet been drawn into squads | yes |
| Blind draw / Assign | wizard | random vs Pro-chosen squads | no |
| Cup Final | wizard | last 4 weeks, scored fresh, "top seeds" | partly |
| Seed | wizard | ? ranking entering the Final | yes |
| Points table | wizard | alternative ending: leader at season end wins | no |
| Points King / Most Improved / Iron Man | standings, pot | individual side titles (best individual / index drop / most rounds) | partly |
| Counting cap / Best 4 | wizard, post form | only best N rounds per month count | no (after (i)) |
| Participation floor / floor | Home, wizard | minimum rounds per month, −5 squad pts per round short | partly |
| Bye | wizard (i), scoring | one forgiven floor miss per season | partly |
| Short months | Home | ? partial calendar months where the floor is waived | yes |
| hcp / handicap allowance 95% | wizard | percent of your index used — effect never shown | yes |
| GHIN rounds / verified / attested / Attested | wizard, review, live | verification rule; "attested" = scored together in the group | yes |
| Rated tees | wizard | tees with an official rating/slope | partly |
| Index / your number | card, post form | the app's own handicap index, from posted scores; a typed value is only a "starter" | partly |
| Differential | receipt | (gross − rating) × 113 / slope | no (formula shown) |
| vs your index / -1.7 | post form, receipt | strokes better/worse than index — sign convention inverted vs golf | yes |
| Point bands (Torched it … Posted anyway) | scoring, post form | 12/9/7/6/5 points by margin vs index | no |
| The board | interstitial, room | league feed + chat | partly |
| Table | interstitial | standings | partly |
| Pot / buy-in / stake / stake per side | wizard, pot, live | pot = season money ledger; stake (Pot tab) = non-money pride bet; stake per side = side-game money | yes |
| Settle up / settlement | live | who pays whom after side games | no |
| Tee sheet | schedule, ⊕ | planned upcoming rounds | partly |
| Card / your card / the card | onboarding, post, live | profile ("golfer card") AND scorecard | yes |
| Ball marker | onboarding | avatar icon | partly |
| Handle | onboarding | @username; "moves once / 60 days" | no |
| Buddies | Home, You | followed golfers | no |
| Guest / claim | live | non-account player who gets a recap link to claim | partly |
| Wolf / Skins / Sunningdale Rules / net best ball | live | side-game formats | Sunningdale yes |
| Stroke index / SI | live | hole difficulty ranking for strokes | partly |
| Group phones | live | multi-phone scoring | no |
| Moments / reveals / month closes | settings | notification categories — never seen | yes |

## CONFUSION DEBT — things the app assumed I already knew
1. That "league", "season", "cup" and "event" are four different nouns with different lifetimes.
2. What a round is worth (points) — needed before the wizard, shown after it.
3. That squads exist and that I'd be choosing a team structure for seven people.
4. What "lock" freezes and when (three answers).
5. That the index I typed is provisional and the app will compute its own.
6. Golf-handicap vocabulary: differential, slope, rating, stroke index, 95% allowance, attested, rated tees.
7. That "GHIN rounds" under Standard does not actually require GHIN.
8. What "seeds", "+10 head start", "cut line after 2nd" mean for the Final.
9. How uneven squads (3 v 4) are scored.
10. That a round posted before the first tee gives 0 league points despite the form saying 6.
11. That the invite is a code, that friends must download the app and tap "I have an invite code", and what they'll be told when they do.
12. That "Findable by: All" is on by default and lets anyone in the app add me to their league.
13. Who pays for "membership" and when.
14. That "-1.7" means over, not under.
15. That side games exist, live under the ⊕, and don't touch the season table.
16. That the rules live under League tab → a collapsed panel.
17. That "Use these defaults" means "Next".
18. What "Sunningdale Rules", "Wolf" and "net best ball" are.
19. That the ✕ on a round deletes it (with only a browser confirm).
20. That the install banner has to be dismissed before the ⊕ works.

---

## ISSUES REGISTER (OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION)

| # | Sev | Cat | Screen | Finding | Evidence |
|---|---|---|---|---|---|
| ORG-01 | **P0** | gameplay | Wizard step 3 / Home | "Lock the bylaws & form the squads" fails every time with console `Lock failed. staged is not defined`; the only user-facing signal is a transient status "Lock failed. Something went wrong — please try again." Six attempts incl. reload, two entry points. The organizer cannot complete setup. **Rec:** fix the reference error; render errors inline under the button, not as a vanishing toast; make Lock idempotent and re-testable. | 31–33, 36; console |
| ORG-02 | **P0** | onboarding | Add golfers | No way to invite by email or phone; search only finds existing users; an email typed in returns "No golfers found." Six friends without accounts cannot be invited from the app. **Rec:** email/SMS invite with a prewritten message containing the link + code; show the organizer the message. | 41–44 |
| ORG-03 | **P1** | navigation | Add golfers / Share | "Share the invite link" and "Share an invite link instead" only produce a status "Invite code: THEPTCQ5"; no link text, no copied-confirmation on screen; the `?join=` URL is never shown. **Rec:** always display the link and code with a visible Copy + prewritten share text; don't depend on navigator.share/clipboard silently. | 38–40 |
| ORG-04 | **P1** | rules | Wizard step 2 | Buy-in defaults to **$75/player** and is hidden behind "Customize"; "Use these defaults →" is the primary button. An organizer can commit friends to $75 without seeing it. **Rec:** surface buy-in (and season length/first tee) above the fold, default to $0/bragging rights, confirm money on the review. | 21–22, 27 |
| ORG-05 | **P1** | comprehension | Post a round / Standings | Form shows "LEAGUE POINTS THIS ROUND 6", round yields 0 league points because the season hasn't started; nothing says so. **Rec:** when the round date is outside any season, replace the points panel with "Season starts Sep 5 — this counts on your card only." | 68, 72, 73 |
| ORG-06 | **P1** | terminology | Post form / receipt | "-1.7 vs your index" for a round *over* the index; result sheet says "1.7 over your number"; receipt says "-1.7 — A LITTLE LOOSE". Golfers read negative as better. **Rec:** one convention, spelled out: "+1.7 over" / "−1.7 under", and show which index (95%?) was used. | 68, 69, 71 |
| ORG-07 | **P1** | rules | Wizard step 3 / League tab | Verification shown as "Attested" though Standard preset said "GHIN rounds"; "attested" is only explained on the live scoring screen. Organizer can't state the verification rule. **Rec:** one vocabulary across preset → review → bylaws; define attested inline. | 30, 45, 88 |
| ORG-08 | **P1** | comprehension | Wizard / Home / League tab | "Lock" happens at three different moments in copy: "LOCKS AT FIRST TEE" (header), "Lock the bylaws & form the squads" (button, now), "You can rename it any time before the bylaws lock", "The bylaws · locked at first tee". Plus "Lock opens the invite link" while the code already exists. **Rec:** separate "publish/open invites" from "lock at first tee"; say which is which. | 15, 17, 30, 45 |
| ORG-09 | **P1** | navigation | Home / everywhere | The "Get the full-screen app" banner sits exactly over the floating ⊕; taps on the primary action do nothing until "Not now". **Rec:** never overlay the FAB; place the install nudge in Settings or above the nav. | 84; elementFromPoint |
| ORG-10 | **P1** | comprehension | Home / room / League / Board | Same unlocked, one-member league is "forming", "Squad formation", "LIVE NOW — CAPTAINS READY", and "is live". **Rec:** one state machine, one label, shown identically everywhere. | 35, 37, 45, 58 |
| ORG-11 | **P1** | rules | League tab | The league's rules for friends are behind Clubhouse → room → League sub-tab → collapsed "▶ LEAGUE RULES & PRO SHOP" → link. Not linked from the wizard, Home, Standings, or the join covenant's first screen. **Rec:** "Rules" as a first-class sub-tab; link "How scoring works" from the wizard's step 2 and from Home's rules chip. | 45, 48, 49 |
| ORG-12 | **P1** | gameplay | Form squads | "Draw squads" shows "Draw failed. Something went wrong — please try again." while the server message was "Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first." **Rec:** surface server messages verbatim. | 53; console |
| ORG-13 | **P1** | comprehension | Wizard step 2 | Seven jargon items per preset card (hcp, honor scores, GHIN rounds, counting, floor, attested, rated tees) with no inline definitions; the (i) repeats them and adds "Pro Shop". **Rec:** plain-English one-liners per preset; define each token on tap. | 18–20 |
| ORG-14 | **P1** | rules | Wizard Teams / Cup Final | For 7 players the app suggests 2 squads (3 v 4) but never says how uneven squads are scored, what "seeds" are, what "+10 head start" is, or how a squad splits its 60%. **Rec:** a worked example ("with 7 players: …") under the Teams picker and in the pot split. | 23, 28 |
| ORG-15 | **P1** | social | Add golfers / Add to the foursome | Global user directory: searching "@jerecho" surfaced two strangers with "Add" buttons; "Findable by: All" is the default. **Rec:** default Findable to Buddies; require handle exact-match for strangers; label results by relationship. | 43, 77 |
| ORG-16 | **P2** | comprehension | Golfer card / Home / Members | Typed index 14.2 is shown as "INDEX 0 OF 3 — building" on Home, "14.2" on Members/You/post form. **Rec:** one representation: "14.2 (starter) · 0 of 3 rounds". | 14, 50, 73 |
| ORG-17 | **P2** | monetization | Wizard (i) / League tab / Settings | "Pro Shop" and "membership lands at launch · the pilot rides free" — who pays, how much, and whether it starts mid-season is never stated. **Rec:** a one-line pricing promise in the wizard's money step. | 20, 45, 80 |
| ORG-18 | **P2** | navigation | Room → Schedule | The Schedule sub-tab leaves the league room for a global calendar whose back link is "← HOME". **Rec:** in-room schedule, or back-to-league. | 55 |
| ORG-19 | **P2** | navigation | Form squads / wizard | No back/close on the Form-squads screen and wizard steps 2–3 (Cancel only on step 1). **Rec:** persistent back/close. | 51 |
| ORG-20 | **P2** | comprehension | Standings | "1 PLAYER IN THE POOL · 3 SEATS OPEN" reads as capacity 4 for a league meant for 7; "The Pro has the list." references no list. **Rec:** "1 in · need 4 to tee off · room for up to N". | 37 |
| ORG-21 | **P2** | gameplay | Post result sheet | First round ever earns "You broke 90 for the first time" and "You broke 100 for the first time"; "Your first round is on the board" twice; You tab then says "No hardware yet". **Rec:** suppress threshold badges until a baseline exists; dedupe. | 69, 73 |
| ORG-22 | **P2** | comprehension | Post form | "No league yet? The round still counts on your card…" shown to a user who has a league. | 62 |
| ORG-23 | **P2** | comprehension | Home (no league) | Monthly-floor rule about "your squad" shown before any league exists. **Rec:** hide until in a league. | 14 |
| ORG-24 | **P2** | terminology | Pot / Live / Wizard | Four money nouns (buy-in, pot, stake per side, stake) with different rules; Pot's "Post a stake" is "never money" while a side game's "stake" is money. **Rec:** rename pride bets ("Wager of pride" / "Bounty"); explain on the Pot tab that side-game cash settles off-ledger. | 54, 87, 94 |
| ORG-25 | **P2** | visual-hierarchy | Wizard step 2 / customize | The floating ⊕ overlaps explanatory copy at phone width ("Standard: 95% handicap, [⊕]osted rounds…"). | 19, 22 |
| ORG-26 | **P2** | comprehension | League tab share | "Share the season → Link" failed with "Could not make the link. Please sign in again." when the real cause was clipboard permission. **Rec:** honest errors; show the URL as text. | 60; console |
| ORG-27 | **P2** | comprehension | Settlement / Live | Settlement headline "Round posted" over "0 CARDS TO THE SEASON · NOT POSTED". | 92 |
| ORG-28 | **P2** | onboarding | Join covenant | The Pro is never shown what invitees see ("Welcome to The Papago Grind · THREE THINGS TO KNOW" — four bullets). **Rec:** "Preview what your friends will see" on the invite sheet; fix the count. | 95 |
| ORG-29 | **P3** | onboarding | Golfer card | Handle silently follows the name ("@jerechoblind1" → "@casey"); later "moves once / 60 days". | 07, 11, 77 |
| ORG-30 | **P3** | comprehension | Name sheet / Add guest | Empty-name "Start the league" and empty-name guest "Add" do nothing silently. | 16 |
| ORG-31 | **P3** | visual-hierarchy | Door / Settings | "v23 · __CS_VERSION__" placeholder visible on the sign-in door and in Settings. | 01, 80 |
| ORG-32 | **P3** | comprehension | Pot | $30 + $13 + $8 = $51 shown on a $50 pot; "Cup champs" for a squad with no per-member split shown. | 54 |
| ORG-33 | **P3** | comprehension | Course search | "Papago Golf Course · Phoenix, AZ · 13 tees" listed twice, identical. | 65 |
| ORG-34 | **P3** | comprehension | You tab | "CUPS & EVENTS 1 · Played in" for a user who has played in none; survives round deletion. | 73, 76 |
| ORG-35 | **P3** | gameplay | You → Recent rounds | Only correction path is a small ✕ (native confirm, no undo, no edit). **Rec:** an in-app confirm sheet with "This leaves your card and league standings", plus edit-by-repost guidance. | 76; console dialog |
| ORG-36 | **P3** | terminology | Wizard step 2 | "Use these defaults →" advances without resetting customizations — the label is wrong in the safe direction. | 82 |
| ORG-37 | **P3** | comprehension | Receipt | Date rendered as "2026-08-29" while everywhere else says "Sat Aug 29"; league points absent from receipt. | 71 |
| ORG-38 | **P3** | gameplay | Live scoring | Score stepper's first tap lands on par, not 1; unexplained on the stepper. | 89 |
| ORG-39 | **P3** | comprehension | Live setup | "Sunningdale Rules" offered with no (i) until selected; player-count rules appear only after selecting. | 85, 87 |
| ORG-40 | **P3** | onboarding | Door | Terms/Privacy open a new tab with no in-app feedback; the Prize Pool Disclaimer explains the product's money model better than the app does. | 02, 04 |

## SCORES (1–10)
- Concept clear: **5** (clear by the end, not at the door)
- Setup clear: **4** (well-designed wizard, three lock moments, hidden money default)
- Rules clear: **5** (excellent copy, buried; inconsistent vocabulary)
- Easy to pick up: **4** (broken lock, covered ⊕, invite gap)
- Gameplay compelling: **7** (bands, best-4, can't-hurt-by-playing-badly, Cup Final)
- Side games compelling: **8** (strokes line, live tally, settlement card, guests)
- Stakes meaningful: **6** (pot ledger clear; membership unknown)
- Would invite: **4** (not until Lock works and I can send a link)
- Would play again: **7**
- Would pay: **5** (would pay ~$5/player if the Pro Shop is the price; unknown)

## BLOCKERS
- Lock the bylaws / form the squads (JS error `staged is not defined`) — could not complete league setup; squads never formed; Cup-Final/standings-with-squads never observed.
- No email invite path — could not invite the six friends from the app; only the code THEPTCQ5 and the (unseen) link `https://cupseason.app/?join=THEPTCQ5` could be relayed.
- Clipboard/share disabled in the headless browser — could not read any "Copy link"/share payloads; share text never observed.
- Season had not started (first tee Sep 5) — could not observe a round scoring into the league table.
- Single account (blind rule) — a friend's join experience was observed only by opening the join URL myself.
