# Persona D — Casey, the organiser · "Get six friends into a season"

**Who I am.** Casey, 46, Phoenix. I run the Saturday game for six friends. I keep a Google Sheet, I collect $50 a head for a season pot, I text the group on Thursday nights. Two of the six (Dev and Marcus) already have Cup Season. I installed it, signed in with my email, and made my "golfer card" (name, @handle, city, home course, ball marker — I picked The Saguaro). It is Friday, Sep 4, 2026, about 7pm.

**How this walk was done.** Blind. I did not read any spec, decision log, guide or prior audit. I used only (a) the screenshots in the two audit folders and the scratchpad, and (b) the iPhone SwiftUI source, followed from `RootView` → `MainTabView` → each screen's state branches → the copy constants in `CupSeasonKit`, treating what the views render for someone in *my* state as what I see. Where the screenshots are older than the code (the Aug-31 signup walk shows a Home with three door buttons; today's `HomeView` no longer has them) I trusted the code, and I say so at that point. Comments in the source were never treated as UI. One caveat: the repo's `CLAUDE.md` was injected into my context by the harness; I ignored it for this walk and nothing below relies on it.

Starting state per the code: `SessionStore.state == .ready`, `me.memberships == []`, `me.events == []`, `profile.rounds_count == 0`, no pending join/claim. `OrientedFlag.take` therefore returns true → I get the orientation screen once, then Home.

---

## The walk

### Screen 0 · Orientation (`OrientationScreen`) — 0 taps so far

Dark card, the CUP SEASON wordmark, then:

> **Four places.**
> **Two ways to play.**
> Thirty seconds, then you're in.

Four rows with tab icons: **Home** — "Everything you're in, one feed" · **Clubhouse** — "One league: table, board, pot" · **Post** (an orange ⊕) — "Before, during and after a round" · **You** — "Your card, record and buddies".

Two side-by-side cards: **THE LONG GAME / A league** — "Months. Every round counts toward a table." and **THE SHORT GAME / An event** — "A weekend or a few weeks. Its own little trophy." Under them: "You can run both at once. An event stands alone, or attaches to a league."

Then (per `LeaguelessDoors`, which the current code puts on this screen — the Aug-31 screenshot `6-orientation.png` predates it and shows tiles only) three quiet buttons across: **Join a league · Start a league · Start an event**, and a grey line: "Post a round — it counts on your card. Leagues score it when you join one."

Pinned at the foot: an orange **Take me in** button, and "Reopen this any time from You › ⚙ › How it works."

*What I think:* OK — "a league" is me: months, a table, a pot. "An event" is a weekend thing. Good, that's one sentence and I got it. "Table" I read as standings. "Pot" — they said the word, good, I have a pot. I *see* "Start a league" right here and I'm tempted, but I want to look at the thing before I commit six people's money to it. I tap **Take me in**. (Tap 1.)

*Hesitation:* none, but I note: the one useful button for me was on a screen I'm told I'll never see again.

### Screen 1 · Home, league-less (`HomeView`, `HomeMode.leagueless(rung: 7)`) — 1 tap, ~1 screen

This is the FIRST HOME. What the code renders for me, top to bottom:

- Header: **Cup Season** (serif wordmark) · `FRI · SEP 4` · an orange **+** at the right (it's a menu — nothing on it says so).
- No invites banner (I have none). No buddy requests. No live-round banner. No lead card (no league).
- **The hero** (`HomeHero`, leagueless rung 7, not tappable — no `push` because no league):
  > YOUR CARD
  > **0 of 3**
  > Three rounds and your index goes live. Nothing else needed.
- No other-league rows. No occasion card (Sep 4 is outside every `Occasion` window). No "Up Next" chips (no rounds, no invites, no memberships → `chips` is empty and the strip hides).
- Section head **AROUND YOUR BUDDIES** with **YOUR BUDDIES ↗** on the right.
- Feed: three grey skeleton bars for a moment, then: "No rounds from your buddies yet. Post one, or **add some buddies.**"
- **COMING UP** · **THE CALENDAR ↗**, and a row "Put a round on the calendar →".
- Tab bar: **Home · Clubhouse · ⊕ Post · You**.

*What I think:* "Your card — 0 of 3 — three rounds and your index goes live." So the app wants me to post three rounds. That's not what I came for. Where's "make a league"? The three buttons I saw ten seconds ago are gone. The Aug-31 screenshot (`8-home-league-less.png`) shows a Home with **Join a league / Start a league / Start an event** buttons right under the header and a tile "LEAGUE · None yet · JOIN OR START" — the current code has removed all of that from Home; `HomeView` says the doors "live in the header's +". So on the Home I actually get, starting a league is a small orange plus sign.

I scroll. Nothing. I go back up. The **+**. It's the only thing that looks like "make". I tap it. (Tap 2.) ~20 seconds spent on this screen looking for the door.

### Screen 2 · The + menu — 2 taps

A system menu drops down (accessibility label "Start or join"):

- 🏳 **Start a league**
- 🏆 **Start an event**
- 🔑 **Join with a code**
- 📅 **Your golf calendar**
- 🔍 **Find golfers**

*What I think:* there it is. Also "Find golfers" — I'll want that for Dev and Marcus. **Start a league.** (Tap 3.) `presenter.wizard = .init(existingLeagueId: nil)` → a full-screen cover.

### Screen 3 · "Name your league" (`WizardScreen.nameSheet`) — 3 taps · confirmed by `11-wizard.png`

> **Name your league**
> THE BANNER EVERYTHING HANGS UNDER
> [ The Big Slice, The Sunday Cup, Dew Sweepers… ]
> You can rename it any time before the bylaws lock.
> **[ Start the league ]**
> [ Cancel ]

*Words I don't know:* **bylaws**. Bylaws lock? I'm guessing "rules". I type **Saturday Money**. Tap **Start the league**. (Tap 4 + typing.)

Behind the scenes (`WizardModel.create` → `create_league`) a league row now exists on the server with a code minted from my name (four letters + four characters — something like `SATU7K2Q`). A toast: "Saturday Money is on the books — set the bylaws". *"On the books"* — fine, it's saved. I have made exactly one decision and something exists, though nothing I can hand to anyone yet.

### Screen 4 · Wizard step 1 of 3 — name + the Pro (`WizardNameStep`) — 4 taps

Top: "Create your league — set the rules once, lock them in" and three little dots (first lit). A card:

> LEAGUE NAME
> [ Saturday Money ]
> PRO — THAT'S YOU
> (my saguaro marker) **Casey** · @casey · you run this league · **THE PRO**

Bottom: **Cancel** · **Next →**.

*Words:* **Pro** / **THE PRO**. They tell me in the same breath ("that's you", "you run this league"), so: commissioner. OK. I already typed the name; this screen is asking me to look at it again. **Next →** (Tap 5.)

### Screen 5 · Wizard step 2 of 3 — "How serious is your league?" (`WizardPresetStep`) — 5 taps

This is the big one. Top to bottom:

> **HOW SERIOUS IS YOUR LEAGUE?** ⓘ

Three cards (Standard has a ✓ — it's the default):

- **Casual** — "Honor scores, everything counts" — `100% hcp · honor scores · any course · unlimited counting · no floor`
- **Standard ✓** — "Weekly-golfer fair, light guardrails" — `95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor`
- **Cutthroat** — "Tournament-tight, receipts required" — `90% hcp · attested where you can · rated tees · best 2 / mo · 3-round floor`

Grey lines: "Standard: 95% handicap, post what you'd post to GHIN, your best 3 a month count, post 2 or the squad feels it. The default for a reason." and "Verification is a norm the league holds, not a filter the engine applies."

An orange button: **Use these defaults →**. A pill: **Customize ⌄**.

Then a card **YOUR LEAGUE SO FAR**:
> (a little flag drawing) **Saturday Money** · Forming — the rules aren't locked in yet
> SQUADS ● ● `2 SQUADS · BLIND DRAW`
> ENDGAME (Cup Final) (Points table)
> THE POT **Bragging rights** `$0 STAKE`
> SEASON ▭ ▭ ▭ ▮ FINAL 4 · `3 mo`
> Turn the dials — the bylaws fill in here. Everything locks at the first tee.

Bottom: **← Back** · **Next →**.

*Words I don't know, in order met:* **hcp** (handicap, I assume — but "95% hcp"? we play full handicap), **floor** ("2-round floor" — a minimum? the ⓘ later says so), **counting** ("best 3 / mo count" — only three rounds a month count? that's new), **GHIN** (I know this one — the official handicap thing; half my guys don't have one), **attested**, **rated tees**, **squads** (teams — we don't do teams), **blind draw**, **Cup Final**, **Points table**, **stake**, **Endgame**, **the squad feels it**.

*What I think:* "Standard" reads fine. But two things are wrong for me and both are hidden: (1) the pot says **Bragging rights · $0 STAKE** and I collect $50; (2) it says **2 SQUADS · BLIND DRAW** and we play every man for himself. The big orange button says "Use these defaults →". If I'm in a hurry I press it and I've made a two-team league with no money. I press **Customize ⌄** instead. (Tap 6.)

The dials unfold (`dials`):

1. **Buy-in** — "Per player · $0 = bragging rights" — **None** [−][+]
2. **Season length** — "Weeks or months · ends the same weekday" — **3 mo** [−][+]
3. **First tee** — "Sat Sep 5 – Sat Dec 5" — a date picker showing **Sep 5, 2026**
4. **TEAMS** ⓘ — pills: Solo · **2 Squads** · 3 Squads · 4 Squads — and 2/3/4 Squads are *dimmed to 40%* (`WizardDials.fits` says they don't fit a roster of 1), including the one that's selected. Under it: "2 squads · fits 4–7 players. Both squads reach the Cup Final; the regular-season leader carries a +10 head start." and in amber: "1 golfer staged — solo fits. Bigger squads open up as more join, by code or invite."
5. **HOW TEAMS FILL** ⓘ — **Blind draw** · Assign — "Blind draw: the server shuffles every joined player into squads and posts the reveal. Argument-proof."
6. **HOW IT ENDS** ⓘ — **Cup Final** · Points table — "Cup Final: the last four weeks reset and score fresh — top seeds only, whoever's hottest takes the cup."
7. **THE POT SPLIT** ⓘ — **Balanced** · Winner-heavy · Spread it — "Balanced: champ 60% · runner-up 25% · Points King 15%."
8. **Counting cap** ⓘ — "Best N rounds / month" — **Best 3** [−][+]
9. **Participation floor** ⓘ — "MIN ROUNDS / MONTH · −5 SQD PTS SHORT" — **2 / mo** [−][+]

*What I do:*
- Buy-in: **+**, **+** → `$25` → `$50`. (Taps 7, 8.) The portrait above changes to THE POT **$50** with a three-segment bar and "$50 / player · 1 in so far · 60/25/15". *$50?* Oh — it's multiplying by the one person in the league, me. My pot is $300. It'll get there, I suppose.
- Season length: 3 months, Sep to Dec. Actually fine for a fall season. Leave it.
- First tee: **Sat Sep 5** — that's *tomorrow*, and we do play Saturdays. Looks right. Leave it. *(This is the mistake. See Screen 9.)*
- Teams: the selected option is greyed out and the amber line says "solo fits". We don't do teams. I tap **Solo**. (Tap 9.) Note changes to "Individual · every player for himself — works at any size (2+). No squads; top 2 players meet in the Cup Final in the final four weeks." Portrait: `SOLO · EVERY PLAYER`. "Top 2 meet in the Cup Final" — I don't fully get it but it sounds like playoffs. The "How teams fill" row is still there, still says Blind draw, now meaningless.
- How it ends / pot split / counting cap / floor: I read the ⓘ for **floor** ("The anti-ghosting rule. Every player must post at least this many rounds a month, or the squad takes a penalty: −5 points per round short under Standard rules. One Pro-approved bye month per season covers vacations and injuries.") — "the squad takes a penalty" in a league with no squads. I leave all four alone because I don't know enough to change them.

**Next →** (Tap 10.)

*Where I hesitate:* the ⓘ buttons. Every one of them opens a paragraph, and every paragraph is written for someone who has already run one of these. I opened two and stopped.

### Screen 6 · Wizard step 3 of 3 — Review (`WizardReviewStep`) — 10 taps

> **REVIEW THE BYLAWS, THEN LOCK IT IN**
> STRUCTURE — Individual — no squads
> Squad formation — Blind draw
> PRESET — Standard
> HANDICAP ALLOWANCE — 95%
> VERIFICATION — Post what you'd post to GHIN
> COUNTING CAP — Best 3 / mo
> PARTICIPATION FLOOR — 2 / mo · −5 sqd pts / round short
> BUY-IN — $50 / player
> POT SPLIT — 60 / 25 / 15 · champ / 2nd / king
> SEASON — 3 mo · Sat Sep 5 → Sat Dec 5 · 13 wks
> CUP FINAL — Final 4 weeks · from Sun Nov 8 · scored fresh
>
> Lock opens the invite link — one link fills the league. The code works until first tee, or until you close the roster. Squads need four to tee off; solo tees off at two.
>
> **[ Lock the bylaws ]**
> [ ← Back ]

*What I think:* "Squad formation — Blind draw" in a league with no squads, and "−5 sqd pts" — ghosts of the default I just turned off. "**king**" — Points King, a third prize I didn't ask for; 15% of my pot is going to someone I haven't defined. The line I *should* have read: "The code works until first tee." First tee is tomorrow. I read it as boilerplate and did not connect the two. **Lock the bylaws.** (Tap 11.) Haptic, toast "Bylaws locked".

`lock_league` runs once with every dial; the server returns `phase: season` (solo → no draft) and the season dates. Then the share sheet rises.

### Screen 7 · "Bylaws locked ⛳" (`WizardLockShareSheet`) — 11 taps

> **Bylaws locked ⛳**
> ONE LINK FILLS THE LEAGUE
> First tee Sat Sep 5 — every golfer you add posts from day one.
> ┌ You're invited to **Saturday Money** on Cup Season
> │ cupseason.app/?join=SATU7K2Q ┘
> **[ Share the invite link ]**
> [ Add golfers ]
> [ Later — it lives in the league room ]

*What I think:* **This is the moment I wanted.** A link, a pre-written text, one button. I tap **Share the invite link** (Tap 12) → the iOS share sheet → Messages → our group thread → send. (Taps 13–15.) Six people get: "You're invited to Saturday Money on Cup Season" + the link.

Then **Add golfers** (Tap 16) → `PeoplePickerSheet` in invite mode:

> **Add golfers**
> INVITED GOLFERS GET A NOTIFICATION AND CHOOSE TO JOIN
> [ Find golfers by name or @handle ]
> Type a name or @handle to search — buddies you add appear here.
> [ Share an invite link instead ]
> Done

I type "Dev" → a row: saguaro-ish marker, **Dev Patel** · @devp · Phoenix · **Add** → tap → **Added ✓** (Tap 17). "Marcus" → **Add** → **Added ✓** (Tap 18). I try "Tony" — "No golfers found. Invite links still work for everyone else." Right, Tony doesn't have it. **Done** (Tap 19).

Back on the locked sheet: **Later — it lives in the league room** (Tap 20). The sheet's `onDismiss` fires `onLocked` → the tab bar flips me to **Clubhouse**.

### Screen 8 · Clubhouse — the Saturday Money room (`ClubhouseView` → `LeagueRoomScreen`, phase season, `atStarter`) — 20 taps

The top of the screen has **no title** (with one league the paged Clubhouse passes `titled: false` and never sets `.navigationTitle` — the bar is blank; the name is in the card below, so I don't notice much). The hero card:

> **Saturday Money**
> Before first tee — Sat Sep 5 `Code · SATU7K2Q`
> BEFORE FIRST TEE · SAT SEP 5 · 1 DAY
> Sat Sep 5 → Sat Dec 5 · 13 wks · THE PRO · CASEY
> Add golfers   Cancel & delete this league
> (only possible before the first tee)

Tab strip: **STANDINGS** · BOARD · SCHEDULE · POT · ALBUM · LEAGUE.

STANDINGS pane: a phase card "BEFORE FIRST TEE / **First tee Sat Sep 5** / KICKS OFF IN 1 DAY · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON". Then the season strip (SEASON — / THE POT $50 / YOUR INDEX — "Building your number" / COUNTING ROUNDS 0/3), a "NEXT UP · KICKOFF — First tee Sat Sep 5. Practice rounds hit your card, not the season." card, ON THE LINE "CHAMPS $30 · RUNNER-UP $13 · POINTS KING $8" (of a $50 pot — one member), then "SEASON RACE · THE CLIMB", **Standings** — "INDIVIDUAL RACE — NO SQUADS. STANDINGS START AT THE FIRST POSTED ROUND; TOP 2 MEET IN THE CUP FINAL."

*What I think:* "SQUADS LOCKED" — I don't have squads. "Practice rounds hit your card, not the season" — I get it: anything before tomorrow doesn't count. "$30 / $13 / $8" — the app is dividing a $50 pot. It'll fix itself when they join. Where do I see who's joined? I tap **LEAGUE** (Tap 21).

### Screen 9 · LEAGUE pane (`LeaguePane`) — 21 taps

> LEAGUE
> 🏳 **Members & invites** · 1 player · [View]
> 🔗 **Share the season** · A public page — the standings so far, no account needed · [Link] [✕]
> 🚪 **ROSTER OPEN · 1 IN** · Works until you close it, or until first tee — Sat Sep 5. · [Roster's set]
> 👥 **Squads** · Individual league — no squads · [View]
> 🔔 **League notices** · Floors, closes and season notices reach the crew's phones · (toggle)
> ▸ LEAGUE RULES

*What I think:* **"Works until … first tee — Sat Sep 5."** Wait. *Tomorrow?* The link I just texted six people stops working tomorrow? Four of them don't have the app; they have to install it, do the email code, fill in a card, and join — tonight. I read "Roster's set" as a button that closes it *sooner*, so I don't touch it. I look for where to change the first tee: the hero says "Cancel & delete this league (only possible before the first tee)". The bylaws are locked. There is no "edit". My choices as far as the screen tells me: delete the whole thing and redo it with Sep 12, or text everybody "DOWNLOAD IT TONIGHT". Nothing on this screen says what happens to a link after it closes (the code's `RosterDoor.closedByTime` line — "The link has closed. Add anyone yourself until the halfway turn." — and a **Reopen** button would appear *tomorrow*, but I can't see the future and "the halfway turn" is another word I'd have to learn).

**This is where I'm genuinely stuck.** In real life: I text the group "Cup Season — tap the link and get in TONIGHT, it closes at first tee (which is tomorrow, don't ask)", and I tap **View** on Members & invites (Tap 22):

> **Members & invites** · 1 PLAYER · CODE SATU7K2Q
> (saguaro) **Casey** THE PRO · @CASEY · [Marker here]
> INVITES OUT
> ✉ dev… · WAITING
> ✉ marcus… · WAITING
> [Add golfers]
> [Share the invite link]

So "how do I know when everyone is in" = come back here and count to 6, or watch "ROSTER OPEN · N IN" on the LEAGUE pane. Nothing on screen promises I'll be *told* when someone joins (there's a "League notices" switch for "floors, closes and season notices" — a join isn't listed).

---

## What the friends see

**Dev and Marcus (have the app, got an in-app invite):** on their Home, under the header, a bordered row (`InvitesBanner`): "**League invite · Saturday Money** / from Casey · [Accept] [Details]". Also an "Up Next" chip "NEEDS YOU · 1 invite". **Details** → sheet: "League invite / SATURDAY MONEY / A season-long league. Invited by Casey / [Accept & join] [Decline]". **Accept** → toast "Joined ✓" → their Home re-renders around Saturday Money. *Nowhere in that path is the $50 mentioned* — `respondInvite` goes straight to the join; the covenant and welcome sheets belong only to the code/link path. The first Dev hears of money is his Home hero's foot line: "You still owe $50 · ask the Pro how to pay — money moves between you". If instead Dev taps my *text link*, he gets `JoinLeagueFlow` with the code pre-filled → "You're invited to Saturday Money." → the covenant sheet "**Before you join Saturday Money** / THE FINE PRINT, UP FRONT / BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH / [Join…] [Not now]" → "Joined Saturday Money" → the welcome sheet "**Welcome to Saturday Money** / THREE THINGS TO KNOW / You're on the pot sheet: $50 buy-in. The Pro tracks who's paid. / You can't hurt your standing by playing badly… / Rounds score against your own number… / The pot lives on the books… / How scoring works → / Who else plays with you? … any member's link works. / [Share the invite link]". That path is genuinely good.

**Tony, Raj, Ben, Luis (no app):** the link opens `cupseason.app/?join=SATU7K2Q` — a web page I can't see from here. If they go to the App Store instead: the door "**Rally your crew. Post real rounds. Take the cup.** / [Continue with email] / [I have a league code]" (`1-door.png`, `15-door.png`) → email → "One code, no password. Codes come from the newest email." → the golfer card (name, @handle, city, home course, optional index, GHIN, pick a ball marker, **Save my card**) → because a join is pending they skip the orientation → the same covenant → welcome. That is: install, email, code-from-email, a six-field card, a fine-print sheet, a welcome sheet. Maybe five minutes each, if they do it tonight.

---

## The five questions — at the FIRST Home (Screen 1)

| # | Question | Answered? | Time / taps | Evidence on screen |
|---|---|---|---|---|
| 1 | What is happening? | **Partly.** I can tell nothing is happening and that the app thinks I'm here to build a handicap. | ~5 s, 0 taps | Hero: "YOUR CARD · 0 of 3 · Three rounds and your index goes live. Nothing else needed." Feed: "No rounds from your buddies yet." |
| 2 | Why does it matter to me? | **No.** Nothing on Home says why a league — or this app — matters to a guy with a spreadsheet and a pot. The orientation card a screen earlier did ("Months. Every round counts toward a table."). | — | Home carries no league sentence at all when you have no league. |
| 3 | What can I do right now? | **Partly.** Visible: post a round (⊕ tab), add buddies, put a round on the calendar. Hidden: start a league — a bare **+** in the header that opens a menu. | ~20 s, 1 tap to discover | "+" (label "Start or join" only for VoiceOver); the Aug-31 screenshot shows the doors as buttons on Home — they're gone from today's Home. |
| 4 | Who am I competing with? | **Yes (honestly: nobody).** | 2 s | "AROUND YOUR BUDDIES — No rounds from your buddies yet. Post one, or add some buddies." |
| 5 | What happens next? | **No.** The only "next" offered is three rounds for an index. Not "invite your crew", not "start a season". | — | "Three rounds and your index goes live. Nothing else needed." |

Time from first Home to a texted invite link: about 3 minutes, 15 taps, 7 screens, if you know to look at the "+" and to open "Customize". Time to *six friends in a season*: unknowable from my side — it depends on four installs by tomorrow.

---

## Explain it to a friend (30 seconds)

"It's a league app for our Saturday game — you post your scores, it handicaps everyone off real rounds, keeps a table for the season and tracks who's paid into the pot; I set it up once, texted you a link, and if you're in by Saturday every round you post counts toward a cup in December."

---

## Glossary — every word I didn't know, at the moment I met it

| Word | Where | What I guessed |
|---|---|---|
| **table** | Orientation: "every round counts toward a table" | standings |
| **the ⊕ / Post** | Orientation, tab bar | post a score |
| **index** | Home hero: "your index goes live" | handicap index (the card said "Handicap index") |
| **bylaws** | Name sheet: "before the bylaws lock" | the rules — never defined |
| **Pro / THE PRO** | Wizard step 1 | commissioner (they say "that's you" — ok) |
| **hcp** · **95% hcp** | Preset cards | handicap; why 95%? |
| **floor** · **2-round floor** | Preset cards | minimum rounds a month (the ⓘ later confirms) |
| **counting** · **best 3 / mo count** | Preset cards | only three rounds a month score |
| **GHIN** | Preset cards | the official handicap service (I know it; half my group doesn't have one) |
| **attested** · **rated tees** | Cutthroat card | someone signed your card; official tees |
| **squads** · **2 SQUADS** | Portrait, Teams dial | teams |
| **blind draw** | Portrait, Teams dial | random teams |
| **Cup Final** · **Points table** | Endgame chips | playoffs vs. straight standings |
| **stake** · **$0 STAKE** | Portrait | buy-in |
| **Endgame** | Portrait | how it ends |
| **staged** · "1 golfer staged" | Teams fit line | joined? signed up? |
| **the squad feels it** | Preset summary | a team penalty — in a league with no teams |
| **Points King** · **king** | Pot split, review | a third prize I didn't know I was offering |
| **−5 SQD PTS SHORT** | Floor dial label | squad points, minus five |
| **first tee** | First-tee dial, review, everywhere after | season start date — and, it turns out, the day the invite link dies |
| **lock / locked** | Review button, hero | final — no editing after |
| **the roster** · **close the roster** · **Roster's set** | Review fine print, League pane | the member list; the button that turns the link off |
| **the halfway turn** | (would appear on the League pane after the link closes) | mid-season? |
| **the league room** | "Later — it lives in the league room" | the Clubhouse tab |
| **scored fresh** | Review: "Final 4 weeks · scored fresh" | the last month restarts from zero |
| **Squad formation — Blind draw** | Review row, in a *solo* league | a leftover |
| **practice rounds hit your card, not the season** | Standings phase card | rounds before Saturday don't count |
| **on the books** | Toast, pot copy | recorded |
| **Marker here** | Members sheet | my ball-marker icon for this league |
| **Share the season · a public page** | League pane | a read-only web page of standings |
| **League notices** | League pane | push notifications for league stuff |
| **the Ryder** · **Bracket** | Start-an-event sheet (seen in `12-events.png`, not on my path) | team match / knockout |

---

## The ten most confusing moments

1. **Home · "YOUR CARD · 0 of 3 · Three rounds and your index goes live. Nothing else needed."** — I thought: this app is about handicaps, not leagues. I needed: a visible "Start a league / Join a league" on the league-less Home (they were there on Aug 31; they are now a menu behind a bare "+").

2. **Home · the orange "+"** — I thought: add a score? I needed: a word. "Start" or "New league" — anything but a glyph whose only label is for VoiceOver.

3. **Wizard step 2 · "Use these defaults →" (big orange) above "Customize ⌄" (small pill)** — I thought: press the orange one. I needed: the defaults *shown* before I accept them — specifically "$0 · bragging rights" and "2 squads · blind draw", the two that were wrong for me, are only legible in the portrait card *below* the fold.

4. **Wizard step 2 · Teams: "2 Squads" is selected and greyed out at the same time; "1 golfer staged — solo fits"** — I thought: is it picked or not? what's "staged"? I needed: the dimming to mean one thing, and the default to fit a roster of one (or the wizard to ask "teams or individual?" plainly, first).

5. **Wizard step 2 · portrait "THE POT $50 · $50 / player · 1 in so far"** — I thought: it's showing me the wrong pot. I needed: "$50 × 6 = $300 once six are in" or simply "per player".

6. **Review · "Squad formation — Blind draw" / "PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short" in an "Individual — no squads" league** — I thought: did Solo take? I needed: solo leagues to drop squad rows and squad penalties from the review.

7. **Review · "The code works until first tee, or until you close the roster."** with SEASON "Sat Sep 5 → …" two lines up — I thought: boilerplate. I needed: "Your invite link works until **tomorrow, Sat Sep 5**" — or a first-tee default that isn't the very next day, or a link that outlives the first tee.

8. **League pane · "ROSTER OPEN · 1 IN · Works until you close it, or until first tee — Sat Sep 5." + a button "Roster's set"** — I thought: tomorrow?! and don't touch that button. I needed: an "edit first tee" or "extend the link" right there, and a sentence saying what happens after it closes.

9. **Standings · "KICKS OFF IN 1 DAY · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON"** — I thought: what squads? and "hit your card"? I needed: solo copy, and "count for your handicap, not the league".

10. **Add golfers → Dev accepts from his Home banner and never sees the $50** — I thought (when Dev texted "what's this cost?"): I told the app $50. I needed: the in-app invite's Accept to show the same fine-print sheet the link shows.

Honourable mentions: the ⓘ paragraphs are written for a second-time Pro ("Deciding this before anyone tees off is what keeps October friendly"); "Points King" takes 15% of my pot by default; the Clubhouse title bar is blank with one league; "Later — it lives in the league room" names a room I've never heard of; nothing tells me I'll be notified when someone joins.

---

## Verdict on the goal — "Get six friends into a season"

**Can I do it without learning the whole product?** Mostly, with two real hazards.

*What worked:* once I found the "+", the wizard is three steps; the name → lock → share flow ends on exactly the thing an organiser wants (a link and a pre-written text); "Add golfers" finds the two who have the app in seconds; the friends' link path (fine print → welcome → "the Pro tracks who's paid") is better than my spreadsheet.

*What didn't:* (1) the league-less Home hides the door; (2) my two must-haves — $50 and no teams — are both non-default and both behind "Customize"; (3) the default first tee is *tomorrow* and the invite link is tied to it, so the four friends without the app have ~24 hours to install, verify email, build a card and join, and I only learn this after locking, when the only fix on screen is "Cancel & delete this league"; (4) "is everyone in?" is a count I go and fetch (Members & invites, or "ROSTER OPEN · N IN"), not something that comes to me; (5) a friend who accepts the in-app invite from the banner is never shown the buy-in.

**Decisions before anything existed:** 1 to get a row on the server (the name). 12 decision points before anything *shareable* existed: name · preset · buy-in · season length · first tee · teams · how teams fill · how it ends · pot split · counting cap · floor · lock — of which I actively made 3 (name, $50, Solo) and accepted 9 defaults, two of them (first tee, Points King) I would not have accepted had I understood them.

**Score: 5 / 10.** I got a link into the group chat in three minutes; whether six friends end up in the season depends on a deadline the app set for me and told me about after the fact.

---

## The "oh, that's actually cool" moment

**"Bylaws locked ⛳ — One link fills the league"**, with the text already written ("You're invited to Saturday Money on Cup Season") and the share sheet one tap away. That, and — when Dev told me what he saw — the fine-print sheet before joining ("BUY-IN $50 … [Not now]") and "You're on the pot sheet: $50 buy-in. The Pro tracks who's paid." The app is going to do the nagging for me. That's the part my spreadsheet never did.

---

## Tap / screen log

| # | Screen | Tap |
|---|---|---|
| 0 | Orientation | — |
| 1 | Orientation | Take me in |
| 2 | Home (league-less) | + |
| 3 | + menu | Start a league |
| 4 | Name your league | type "Saturday Money" · Start the league |
| 5 | Wizard 1/3 | Next → |
| 6 | Wizard 2/3 | Customize |
| 7–8 | Wizard 2/3 | Buy-in + + ($50) |
| 9 | Wizard 2/3 | Teams: Solo |
| 10 | Wizard 2/3 | Next → |
| 11 | Wizard 3/3 | Lock the bylaws |
| 12–15 | Bylaws locked ⛳ | Share the invite link → Messages → group → Send |
| 16–19 | Add golfers | search Dev · Add · search Marcus · Add · Done |
| 20 | Bylaws locked ⛳ | Later — it lives in the league room |
| — | Clubhouse (auto) | — |
| 21 | Clubhouse | LEAGUE |
| 22 | League pane | Members & invites · View |

22 taps, 11 screens, one league, one link sent, two in-app invites out, zero friends in yet, and a deadline of tomorrow I didn't choose.
