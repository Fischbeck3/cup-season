# Persona A — Tyler, the new golfer. A blind walk through Cup Season (iPhone)

**Who I am.** Tyler, 31, Scottsdale. I play most Saturdays with the same three guys, shoot around 90, no official handicap. We run everything on a group text and settle with Venmo. A buddy mentioned "CupSeason" once. It is Friday, September 4, 2026, about 5 pm.

**What I want.** "I want to play a golf competition with my three friends this Saturday." No invite code. Nobody I know is on the app.

**How this walk was done.** I read only what a person in my seat could: the App Store listing (`docs/ios/app-store-listing.md`, including the six 6.9" store screenshots), the screenshots in the two audit folders, and the SwiftUI view code — read only to learn what would be on screen for a signed-in, league-less, round-less golfer on a Friday in September. Comments in code were never treated as UI. A `CLAUDE.md` was auto-surfaced by the tooling at the start of the session; I set it aside and did not use it. Where a screenshot showed the web app rather than the phone (the `signup-walk` door and card shots carry `v23 · __CS_VERSION__` and an "I have a league code" button the phone does not have), I trusted the phone's code and the phone's own screenshots.

Tap counts below count taps only; typing is free. "Screen" counts full-screen changes and sheets.

---

## Part 0 · The App Store listing (before I install)

**Name:** "Cup Season". **Subtitle:** "Run your golf season".

**Promo line:** "Season three of the founding league is under way. Draft the crew, post real rounds, and race a season-long cup with standings that show their work."

What I think: "Season three of the founding league" — is this someone's private club? "Draft the crew" — fantasy football vibes. "Season-long cup" — I want one Saturday, not a season.

**Description, the parts I actually read:**
- "Retire the spreadsheet. Run your golf season in your pocket." — I don't have a spreadsheet. I have a group text.
- "Captains draft squads, everyone posts real rounds from any course, points pile up month after month, and the season ends the way a season should: with a Cup." — okay, it's a fantasy-league thing for golf.
- "The Pro sets the bylaws once — squads or solo, the handicap allowance, how many rounds count a month, the endgame — and locks them at first tee." — *the Pro? bylaws? allowance? endgame?* Four words I don't own, one sentence.
- "Post a round in under a minute… Your number comes from the scores you actually post — no self-reported vanity handicaps." — good, I don't have a handicap.
- "**The live round.** Put your group on the tee sheet and score Match Play, Wolf, or Skins hole by hole, on one phone or four. Strokes come off automatically, the ladder updates as you walk, and the settlement card at the end says who won what. Played a guest? One link makes their round theirs for good." — **This paragraph is the one I care about.** Skins with the boys, phone in the cart, it tells us who owes what. That's my Saturday.
- "What it costs, plainly. Nothing." — good.
- "The money, plainly: Cup Season keeps the ledger; the money moves between friends — not through the app." — fine, that's Venmo.

**The six screenshots:** a Home with "SUNSET MATCH · CUP FINAL / 2nd / Four weeks, scored fresh. Whoever's hottest takes the cup. 2 left. / Month floor met · 3/2"; a Clubhouse with "$450" pot and "5/6 buy-ins in"; a Board with "80 GROSS · BEAT THEIR NUMBER · COUNTING #1 THIS MONTH · 9 PTS"; "Post a round · YOUR INDEX 10.9 / 84 / Played to your number / 7 pts · Sunset Match"; a "You" card with "10.9 HANDICAP INDEX" and a display case; "Card & settings" with a grid of ball markers. Not one screenshot shows a foursome playing skins. Everything shown is a months-long league with money in a pot.

**Expectation going in:** this is a fantasy-league app for a golf crew that already runs one; somewhere inside is a live skins/match-play scorer that works for my Saturday. I install it for that paragraph. Time on the listing: ~90 seconds. Taps: 2 (Get, Open).

---

## Part 1 · The door (screen 1)

Light background, the orange flag-and-swoosh crest animates in, then the wordmark "Cup Season", an orange rule, and:

> "Rally your crew. Post real rounds. *Take the cup.*"

Under that: an eyebrow "EMAIL", a field "you@example.com", an orange button "Continue with email", and a footnote: "One code, no password. Codes come from the newest email." Then "By continuing you agree to the Terms & Privacy Policy." and "v1 · build 1".

No Sign in with Apple (the phone code has one behind a flag, and the flag reads closed when signed out — so I don't see it). No "I have a league code" on the phone; the web shot has one, the phone doesn't. I have no code anyway.

What I think: fine, email it is. "Codes come from the newest email" is odd phrasing — I'll find out why in a second. "Take the cup" — again, a cup; I just want Saturday.

Tap "Continue with email". (Taps so far: 3. ~20 s.)

## Part 2 · The code (screen 2)

The email stage slides away; a green note appears: "Sent to tyler…@gmail.com. Type the 8 digits from the newest email." Eyebrow "THE 8 DIGITS", a big centered code field, a "Verify" button, "Resend in 30s" and "Change email". A toast "Code sent".

I switch to Mail, the code arrives, iOS offers it above the keyboard, I tap it, and the field auto-verifies at 8 digits — "Checking the code…" then "Signed in, loading…", a little haptic.

What I think: eight digits is a lot, but the phone typed it for me. Now I understand "newest email" — if I hit resend, only the newest one works. Fair. (~60 s including the Mail round trip. Taps: 5.)

## Part 3 · The golfer card (screens 3–5)

A three-segment progress rail at the top. Eyebrow "Your card". Title: **"Who's on the card?"** Sub: "Just a name and a marker to start — this card follows you into every league."

**Step 1.** "NAME" field "First and last". "@HANDLE" field — as I type "Tyler Brooks" it auto-fills "tylerbrooks"; "3–20 letters, numbers or _. It changes once every 60 days." Then "Checking @tylerbrooks…" → "@tylerbrooks is available ✓". Button "Next".

What I think: a handle, like Venmo. "Changes once every 60 days" makes me pause — am I committing to something? I keep the default. (Tap 6.)

**Step 2.** Title **"Pick your ball marker"**. Sub: "It's your face here until you add a photo — and your stamp on every round after." A 4×4 grid of little line icons with names: THE SAGUARO · THE ISLAND · THE LIGHTHOUSE · THE LONE TREE · THE PEWS · THE DUNES · THE BEVERAGE · THE SHARK · THE AZALEA · THE JUG · THE WEE BRIDGE · NO. 2 · THE POSTAGE STAMP · THE THISTLE. Footnote: "City and home course live on your card — add them any time from the You tab." No default is selected; "Next" without picking says "Pick your ball marker — it's your face here."

What I think: I don't know what most of these are (the Pews? the Postage Stamp?). It's cute. I'm from Scottsdale — Saguaro. (Taps 7–8.)

**Step 3.** Title **"Know your number?"** Sub: "Optional. Your index builds itself at 3 posted rounds; a starter only helps before then." Fields: "STARTER INDEX · e.g. 12.4" and "GHIN (a reference on your card — we never resell or verify it) · GHIN # · e.g. 1234567", footnote "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." Button **"Save my card"**.

What I think: I don't have an index. I don't have a GHIN. I don't know what "index" means precisely — I shoot around 90. "Builds itself at 3 posted rounds" — so I have to post three rounds before I have a number. I leave both blank and save. (Tap 9. Card total ~75 s.)

## Part 4 · Orientation (screen 6)

A page titled in two lines: **"Four places. / Two ways to play."** Sub: "Thirty seconds, then you're in."

Four rows with the tab-bar icons:
- 🏠 **Home** — "Everything you're in, one feed"
- ⚑ **Clubhouse** — "One league: table, board, pot"
- ⊕ **Post** — "Before, during and after a round"
- 🪪 **You** — "Your card, record and buddies"

Two cards side by side:
- "THE LONG GAME" / **A league** / "Months. Every round counts toward a table."
- "THE SHORT GAME" / **An event** / "A weekend or a few weeks. Its own little trophy."

Fine print: "You can run both at once. An event stands alone, or attaches to a league."

Then three quiet doors in a row: **"Join a league" · "Start a league" · "Start an event"**, with a line under them: "Post a round — it counts on your card. Leagues score it when you join one."

Pinned at the bottom: orange **"Take me in"**, and "Reopen this any time from You › ⚙ › How it works."

**Where I hesitate — this is the first real fork.** I want *one Saturday round with three guys*. The two ways to play are "Months" and "A weekend or a few weeks". Neither is one round. "Start an event" sounds closest ("a weekend"). "Start a league" sounds like the fantasy thing from the listing. "Join a league" — I have no code. I'm not going to commit to either on a screen that says "thirty seconds, then you're in", so I tap **"Take me in"**. (Tap 10. ~25 s.)

I also notice: "Post — Before, during and after a round" is the only line that talks about *a round*, and it's a tab, not a way to play.

---

## Part 5 · The FIRST HOME (screen 7) — what I actually see

Top: a short orange dash, the wordmark **"Cup Season"**, on the right a mono eyebrow **"FRI · SEP 4"** and a small orange **"+"**.

No banners. Then the one hero card:

> **YOUR CARD**
> **0 of 3**
> "Three rounds and your index goes live. Nothing else needed."

No footer lines, no arrow, not tappable.

Below it, nothing — no chips, no league rows, no seasonal card (the calendar-window cards don't fire on Sep 4).

Then a section head: **"AROUND YOUR BUDDIES"** with a link on the right **"YOUR BUDDIES ↗"**, a hairline, and one sentence:

> "No rounds from your buddies yet. Post one, or **add some buddies.**"

Then **"COMING UP"** with **"THE CALENDAR ↗"**, a hairline, and a bordered row: 📅 **"Put a round on the calendar →"**.

Bottom tab bar: **Home · Clubhouse · ⊕ Post · You**.

**What I think, honestly:** Where did the three doors go? They were on the previous screen. The biggest thing on my Home is a progress bar toward a handicap I didn't ask for. "Nothing else needed" — needed for *what*? My goal isn't on this screen anywhere. The only verbs are "Post one", "add some buddies", and "Put a round on the calendar". The "+" is 20 points wide and unlabeled.

A sheet rises over Home a beat later (screen 8): **"Hear it when it happens"** / "YOUR CARD IS IN" / three lines: "A round lands on the board. A duel is closing. The table moves." · "A buddy request, a tee time, an invite — answered from the lock screen." · "Nothing else. No streaks, no noise, no badge you didn't earn." Buttons "Turn on notifications" / "Not now". I tap "Not now" — I'll turn it on once I know what a duel is. (Tap 11.)

Time from Get to first Home: ~4.5 minutes. Taps: 10 to reach it, 11 with the notification sheet dismissed.

### The five questions, answered *at this first Home*

| # | Question | Answered? | Time / taps | On-screen evidence |
|---|---|---|---|---|
| 1 | What is happening? | **Partly.** I understand that I have zero of three rounds toward "my index". I do not understand what state the *app* is in for me — there's no "you're not in anything yet" sentence. | ~3 s, 0 taps | "YOUR CARD · 0 of 3 · Three rounds and your index goes live. Nothing else needed." |
| 2 | Why does it matter to me? | **No.** Nothing says why an index matters or what having a card gets me. "Nothing else needed" implies I'm done, which is the opposite of how I feel. | — | Same card; no other sentence on Home explains stakes or purpose. |
| 3 | What can I do right now? | **Partly.** Three quiet verbs: "Post one", "add some buddies", "Put a round on the calendar". The competition doors (Start a league / event, Join) are hidden behind an unlabeled "+" — I found them only by poking it. | ~15 s to read, 1 tap to discover the + menu | "No rounds from your buddies yet. Post one, or add some buddies." · "Put a round on the calendar →" · "+" → "Start a league · Start an event · Join with a code · Your golf calendar · Find golfers" |
| 4 | Who am I competing with? | **No.** Nobody. Home says so. | 0 taps | "No rounds from your buddies yet." |
| 5 | What happens next? | **No.** The only "next" is a progress bar to 3 rounds. Nothing points at Saturday, at a game, or at inviting anyone. | — | "0 of 3" is the only forward-looking element. |

---

## Part 6 · Exploring from Home (Friday night, still trying to set up Saturday)

### 6a · The "+" (screen 9, tap 12)
A system menu: **"Start a league" · "Start an event" · "Join with a code" · "Your golf calendar" · "Find golfers"**. Okay — there they are. I close it to check the other tabs first.

### 6b · Clubhouse tab (screen 10, tap 13)
Title "Clubhouse". The same three doors (Join a league · Start a league · Start an event), the same line "Post a round — it counts on your card. Leagues score it when you join one.", and a fourth button **"Add golfers"**. That's the whole screen. Nothing explains what a Clubhouse is beyond the orientation's "One league: table, board, pot".

### 6c · You tab (screen 11, tap 14)
"You" with a ⚙. A hero card with my Saguaro, "Tyler Brooks", "@TYLERBROOKS", "est. Sep 2026 · add your GHIN", **"—" / HANDICAP INDEX**, "FORM ○○○○○". A row "Your buddies — Find golfers, see who you play with →". Then "YOUR GOLF" and an empty state: ⛳ "No rounds yet — your card fills as you play." with a button "Post your first round". Nothing about seasons (that whole group hides for a league-less golfer).

### 6d · Post (⊕) — the cover (screen 12, tap 15)
This is the one that changes my night. A full-screen page: **"Golf"** — "Play one live, post one you just finished, or plan the next". Three rows:

- ● LIVE **"Play now — score the group"** — "Everyone scores from their own phone — Match Play, Wolf or Skins — and it settles up at the end. Friends without the app just play; their card is waiting when they want it." →
- **"Post a round — after you play"** — "Gross + tee, 20 seconds · counts on your card and in every league" →
- **"Plan a tee time — before"** — "Put a round on the tee sheet · your buddies and leagues see it the moment you post" →

**"Oh — that's actually cool."** "Friends without the app just play." That's my three guys. That's Saturday. It was behind the tab whose orientation line was "Before, during and after a round" — nothing on Home pointed here, and the store listing put it fourth.

I tap **"Play now — score the group"** to see what it wants (screen 13, tap 16). Title "Play now". Eyebrow "SET UP THE ROUND".

- Card **COURSE**: "Search a course, or type your own". "TEE & RATING — OFF THE SCORECARD": Tee / Rating / Slope fields. "18 holes | 9 holes". "Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load." A pill "Enter the pars".
- Card **THE FOURSOME · 1 / 4**: a chip "● You · EST 18.0 IDX" and three dashed "Open slot · TAP A PLAYER BELOW". "TAP TO FILL A SLOT". Under it, since I have no one: a pill "👥 Bring your group — search the app" and another "👥 Search the app — add any golfer". "ADD A GUEST": Name / Index / Add. Fine print: "Pick who plays with who under the game — pairings, stakes, the lot. Every complete card posts to its golfer at the finish; account-less guests play every game, post nothing. Leave index blank for an estimated 18."
- Card **GAME FOR THIS ROUND · PICK ONE**: pills **Just score · Match play · Wolf · Skins · Sunningdale Rules**. Tapping Skins: "Low net takes the hole's skin; ties carry the pot. Two to four players; scores still post." A field "DOLLARS PER SKIN · $0 = BRAGGING RIGHTS" and a preview "Low net wins the hole's skin; a tie carries it — next hole is worth more. Strokes apply off the low man."
- Card **"Who's on this tee"** — "Fill the foursome from the phones next to you", a toggle, "Bluetooth only — never your location…"
- Orange **"Tee off →"**.

What I think: I get it now. Saturday morning I type the course, add "Danny / Chuck / Gary" as guests (index blank = "estimated 18"; they're 90s golfers too), pick Skins at $5, tee off, and hand them a link. "EST 18.0 IDX" on my own chip — I don't know what that means for me; I assume it's a placeholder because I have no number. *But it's Friday.* I tap **Close** — nothing is saved (before tee-off there's no round). So I cannot set Saturday up tonight from here. This screen is for standing on the first tee.

I never learn tonight what "strokes off the low man" will do to four guys who all "estimate 18" — presumably nothing. That's fine but I'm guessing.

### 6e · "Plan a tee time — before" (screen 14, tap 17)
Sheet **"Put a round on the tee sheet"** / "BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST". Day defaults to **Sat Sep 5** — nice. "Tee time · optional / Set a tee time". "Course" → "Pebble Beach" placeholder. "Note · optional / buddies trip, looking for a 4th". Then: **"No one to tag yet. Add buddies from the You tab, or invite the league."** Button "On the tee sheet". Fine: "Posts to your leagues' boards: tagged golfers are named."

What I think: I could put Saturday on my own calendar, but it posts to boards I don't have, for buddies I don't have. It's a note to myself. I cancel.

---

## Part 7 · The path I actually take Friday night: "Start a league" (because it's the only door that hands me an invite)

From the "+": **"Start a league"** (screen 15, tap 18).

**Name sheet.** "Name your league" / "THE BANNER EVERYTHING HANGS UNDER". Placeholder "The Big Slice, The Sunday Cup, Dew Sweepers…". "You can rename it any time before the bylaws lock." Buttons **"Start the league"** / "Cancel". I type "Saturday Boys", tap Start. Toast: "Saturday Boys is on the books — set the bylaws". (Tap 19.)

**Step 1 of 3.** Eyebrow "Create your league — set the rules once, lock them in". Three dots. Card: "LEAGUE NAME" (filled), "PRO — THAT'S YOU": my Saguaro, "Tyler Brooks", "@tylerbrooks · you run this league", tag "THE PRO". Buttons "Cancel" / **"Next →"**. (Tap 20.)

What I think: "Bylaws." "The Pro." I'm the Pro. Sure.

**Step 2 of 3 — "How serious is your league?"** with an ⓘ. Three cards:
- **Casual** — "Honor scores, everything counts" — "100% hcp · honor scores · any course · unlimited counting · no floor"
- **Standard ✓** — "Weekly-golfer fair, light guardrails" — "95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor"
- **Cutthroat** — "Tournament-tight, receipts required" — "90% hcp · attested where you can · rated tees · best 2 / mo · 3-round floor"

Under them: "Standard: 95% handicap, post what you'd post to GHIN, your best 3 a month count, post 2 or the squad feels it. The default for a reason." and "Verification is a norm the league holds, not a filter the engine applies." Then an orange **"Use these defaults →"** and a pill **"Customize ⌄"**.

Then a card **"YOUR LEAGUE SO FAR"**: a little flag, "Saturday Boys" / "Forming — the rules aren't locked in yet". Rows: **SQUADS** "●● 2 SQUADS · BLIND DRAW" · **ENDGAME** [Cup Final] [Points table] · **THE POT** "Bragging rights · $0 STAKE" · **SEASON** three outlined month blocks, an orange "FINAL 4" block, "13 wks". Fine: "Turn the dials — the bylaws fill in here. Everything locks at the first tee."

**Where I hesitate hard.** "hcp"? "best 3 / mo count"? "2-round floor"? "post 2 or the squad feels it"? I read the three cards twice and still can't tell what changes on Saturday between Casual and Standard. And the portrait tells me what I've apparently agreed to without touching anything: **two squads, a blind draw, thirteen weeks, a "Final 4".** I wanted one Saturday. I open "Customize" to look for "one day": the dials are **Buy-in** ("Per player · $0 = bragging rights", −/+ in $25 steps), **Season length** ("Weeks or months · ends the same weekday", "13 wks" −/+; the shortest it goes is 2 wks), **First tee** ("Pick any day" — a date picker, default **Sat Sep 5**, with "Sat Sep 5 – Sat Dec 5" under it), **TEAMS** [Solo · 2 Squads · 3 Squads · 4 Squads] with "2 squads · fits 4–7 players. Both squads reach the Cup Final; the regular-season leader carries a +10 head start." and, in amber, "1 golfer staged — solo fits. Bigger squads open up as more join, by code or invite.", **HOW TEAMS FILL** [Blind draw · Assign], **HOW IT ENDS** [Cup Final · Points table], **THE POT SPLIT** [Balanced · Winner-heavy · Spread it], **Counting cap** ("Best N rounds / month"), **Participation floor** ("MIN ROUNDS / MONTH · −5 SQD PTS SHORT").

There is no dial for "one round". The minimum is two weeks. I set Buy-in to $25 (so we're playing for something), leave everything else, and tap **"Use these defaults →"**. (Taps ~24.)

**Step 3 of 3 — "Review the bylaws, then lock it in".** A card of rows:
STRUCTURE **2 Squads** · SQUAD FORMATION **Blind draw** · PRESET **Standard** · HANDICAP ALLOWANCE **95%** · VERIFICATION **(the Standard line)** · COUNTING CAP **Best 3 / mo** · PARTICIPATION FLOOR **2 / mo · deduct** · BUY-IN **$25 / player** · POT SPLIT **60 / 25 / 15 · champ / 2nd / king** · SEASON **13 wks · Sat Sep 5 – Sat Dec 5** · CUP FINAL **Final 4 weeks · from Sat Nov 7 · scored fresh**.

Fine print: "Lock opens the invite link — one link fills the league. The code works until first tee, or until you close the roster. Squads need four to tee off; solo tees off at two."

Button: **"Lock the bylaws & form the squads"**. (Tap 25.)

What I think: "king"? "scored fresh"? "deduct"? And — wait — "The code works until first tee", and first tee is **tomorrow**. So my link dies tomorrow? If Chuck installs this Saturday morning in the parking lot, is he out? I'm not sure, and there's nobody to ask. I lock anyway, because the invite is the thing I came for.

Toast "Bylaws locked", a haptic, and a sheet (screen 16):

> **Bylaws locked ⛳** / "One link fills the league"
> "1 in so far — 3 more fills 2 squads, and the draw runs when the crew is in."
> [ You're invited to **Saturday Boys** on Cup Season · `cupseason.app/?join=SATU4K7Q` ]
> **Share the invite link** · Add golfers · Later — it lives in the league room

I tap **"Share the invite link"** → the system share sheet → Messages → our group text. (Taps 26–28.) **Text sent: "yo download Cup Season and hit this link before tomorrow, I set up a thing for Saturday cupseason.app/?join=SATU4K7Q"**

Then "Later — it lives in the league room" (tap 29). The app switches me to the Clubhouse (screen 17):

> **Saturday Boys** — "Squads drawing" — chip "Code · SATU4K7Q"
> "SQUADS DRAWING · ROSTERS PENDING"
> "Sat Sep 5 – Sat Dec 5 · THE PRO · TYLER BROOKS"
> "Add golfers" · red "Cancel & delete this league" "(only possible before the first tee)"

And Home now leads with: **"SATURDAY BOYS · SQUADS DRAWING" / "1d" / "Bylaws locked. Draw the squads when the crew is in."**

**Where I stall.** I am now the Pro of a 13-week, two-squad, $25-a-head league that starts tomorrow, with a blind draw I apparently have to run ("Draw the squads when the crew is in") once three guys who don't have the app finish an 8-digit email code, a three-step card with a ball-marker quiz, and a join-code sheet — by tomorrow. And I *still* don't know what Saturday's round is worth: the review said "Best 3 / mo", "95%", "Cup Final from Nov 7", but nothing said "Saturday: you post your score, it scores against a number you don't have yet." The thing I actually wanted — skins with the boys, phone in the cart — lives in "Play now", which works without any of this, but can only be started at the course.

**What I do in real life:** I leave the league standing (the group text has the link), and Saturday morning on the first tee I open ⊕ → Play now, add the three of them as guests, pick Skins at $5, tee off, and share their "pencil" links from "Group phones — everyone can score". If they joined the league overnight, great; if not, the skins game still works. I'd text a friend: "the skins thing is legit, the league thing is a whole season, don't worry about it."

---

## 30-second explain-it-to-a-friend

"Cup Season is a fantasy-league app for a golf crew: somebody sets up a months-long 'season' with squads and a pot, everyone posts their real scores, and the scores turn into points against your own handicap. Buried under the plus button in the middle there's also a live scorer for skins, match play and Wolf that works for one round with anyone, even guys without the app — that part is what you and I would actually use on a Saturday; the season part is for a group that plays all year."

---

## Glossary — every word I didn't own at the moment I met it

| Word / phrase | Where | What I thought it meant then |
|---|---|---|
| "the cup" / "Take the cup" | door, listing | A trophy? Whose? |
| "crew" | door, listing | My friends, I guess. |
| "Post real rounds" / "post a round" | door, everywhere | Enter a score after playing. (Turned out right.) |
| "Season three of the founding league" | promo | Someone else's private league. |
| "the Pro" | listing, wizard | A golf pro? No — apparently me, the organizer. |
| "bylaws" | listing, wizard | Legal-sounding word for league settings. |
| "handicap allowance" / "95% hcp" | listing, wizard | No idea what a percent of a handicap does. |
| "endgame" | listing, wizard | How it ends? |
| "index" / "handicap index" / "your number" | card, Home, You | My handicap, which I don't have. Three names for one thing. |
| "GHIN" | card | A golf ID number I don't have. |
| "starter index" | card | A guess at my handicap to start with. |
| "ball marker" | card | My avatar icon. Named after golf-course things I mostly can't place (the Pews? No. 2?). |
| "@handle" | card | Username. |
| "the card" / "your card" / "golfer card" | card, Home, You | My profile. But "card" also means scorecard in "Enter your card" and "every complete card posts". |
| "Clubhouse" | orientation, tab | A league's room. |
| "table" / "the table" | orientation, listing | Standings. |
| "board" / "the board" | orientation, screenshots | A league chat/feed. |
| "pot" / "on the books" | orientation, wizard | The money; "on the books" = tracked, not held. |
| "event" / "the short game" | orientation | Something shorter than a league but still "a weekend or a few weeks". |
| "the Ryder" | listing, event picker | A two-team thing; "weekly vs-index duels · first to the clinch" — no idea. |
| "Bracket · SOON" | event picker | Not built. |
| "tee sheet" | Post cover, live | The app's word for a planned or in-progress round. |
| "squads" / "2 Squads" | wizard | Teams. |
| "blind draw" | wizard | Random teams. |
| "Casual / Standard / Cutthroat" | wizard | Three rule bundles; couldn't tell what changes on Saturday. |
| "counting cap" / "best 3 / mo" | wizard | Only three rounds a month count. Why? |
| "participation floor" / "2-round floor" / "−5 SQD PTS SHORT" | wizard | A minimum with a penalty. |
| "attested" / "verification" | wizard | Someone vouches for your score? |
| "Cup Final · scored fresh" | wizard, screenshots | A playoff where earlier points reset. |
| "Points table" | wizard | No playoff. |
| "Points King" / "king" | wizard | Best individual? (Only guessed from "champ / 2nd / king".) |
| "Balanced / Winner-heavy / Spread it" | wizard | Payout splits. |
| "first tee" | wizard, Clubhouse | The season's start date — not a tee time. |
| "roster" / "close the roster" | wizard fine print | The member list; closing it kills the code. |
| "Squads drawing · rosters pending" | Clubhouse | Waiting on people, then random teams. |
| "1d" | Home hero after lock | One day to first tee. |
| "EST 18.0 IDX" | live setup | A made-up handicap for someone without one. |
| "Just score / Match play / Wolf / Skins / Sunningdale Rules" | live setup | Games. I know skins and match play. Wolf vaguely. Sunningdale, no. |
| "Low net" / "strokes off the low man" | live setup | Handicap math I trust the app to do. |
| "net best ball" / "2v2" | live setup | Team format. |
| "settles up" / "settlement card" | listing, Post cover | Who owes what. |
| "guest" / "pencil" / "claim link" / "recap" | live | A friend without the app; the link they score/see from. |
| "buddies" | Home, You | In-app friends (separate from league mates, separate from guests). |
| "rating / slope" / "SI" | live setup | Course numbers off the scorecard; SI = no idea. |
| "duel" / "The table moves" | notification sheet | Something in a league I'm not in. |
| "Founder" | store screenshot | A badge. |

---

## The ten most confusing moments

| # | Screen | Copy (verbatim) | What I thought | What I needed |
|---|---|---|---|---|
| 1 | Orientation | "THE LONG GAME · A league · Months." / "THE SHORT GAME · An event · A weekend or a few weeks." | Neither is "one Saturday with three guys". Which door is mine? | A third line: "**One round** — Play now, from ⊕, with anyone." |
| 2 | First Home | "YOUR CARD · 0 of 3 · Three rounds and your index goes live. Nothing else needed." | Needed for *what*? Where did the doors from the last screen go? | The Start/Join/Event doors on Home for a league-less golfer, or the hero asking "What are you here to do Saturday?" |
| 3 | First Home | The unlabeled orange "+" | Decoration. | A labeled "Start or join" — the menu inside it is exactly what I was looking for. |
| 4 | Post cover | "Play now — score the group … Friends without the app just play" | This is the thing! Then: Close saves nothing, so I can't set up tomorrow tonight. | "Come back on the tee — this takes two minutes when you're there." Or let me stage the foursome and game now. |
| 5 | Wizard step 2 | "95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor" | Abbreviation soup. Couldn't tell what changes for us. | One sentence per preset in plain words, or a "for Saturday, this changes nothing" reassurance. |
| 6 | Wizard portrait | "●● 2 SQUADS · BLIND DRAW" · "13 wks" · "FINAL 4" | I've apparently committed to a thirteen-week two-team season by naming it. | A "how long / how many" question up front; a "one round" or "one weekend" option. |
| 7 | Wizard fine print | "The code works until first tee, or until you close the roster." with first tee = tomorrow | So my link dies tomorrow morning? If Chuck installs at the course, is he out? | An explicit "Link works until Sat Sep 5" *and* a warning that a first tee tomorrow gives friends 14 hours. |
| 8 | Lock share | "1 in so far — 3 more fills 2 squads, and the draw runs when the crew is in." | Who runs the draw? Me? Where? What happens if only two guys join by Saturday? | "You'll draw the squads from the Clubhouse once all four are in; until then, rounds still count on your card." |
| 9 | Clubhouse after lock / Home | "SQUADS DRAWING · ROSTERS PENDING" · "1d · Bylaws locked. Draw the squads when the crew is in." | Same sentence twice, still no verb I can tap; and nothing says what Saturday's round is *worth*. | "Saturday: post your score, it scores against your number — you don't have one yet, so [what happens]." |
| 10 | Live setup | "You · EST 18.0 IDX" and "Leave index blank for an estimated 18" | Is 18 good? Bad? Does it change the skins math among four guys who all get 18? | "Everyone without a number gets 18 — so between you four it's straight up." |

Honorable mentions: "Pick your ball marker — it's your face here" with fourteen unexplained names · "It changes once every 60 days" on a handle I didn't choose · the notification sheet's "A duel is closing. The table moves." to a golfer in no league · "Put a round on the tee sheet" offering to post to "your leagues' boards" when I have none · "Add golfers" on an empty Clubhouse.

---

## Verdict on the goal question

*"Can you figure out how to make Saturday's round a competition, invite your three friends, and know what you'd be playing for — without anyone explaining the app?"*

- **Make Saturday a competition:** Half. I found the live skins/match-play scorer by exploring the ⊕, and it is genuinely right for us — but nothing on the listing's front, the orientation, or Home routes a "Saturday guy" to it, and it can't be set up the night before. The door the app *does* offer on Friday ("Start a league") makes Saturday the first day of a thirteen-week season.
- **Invite my three friends:** Yes, eventually — a real link after ~28 taps, via a league I didn't want, with a code that (per the fine print) stops working at tomorrow's "first tee". Guest links for the live game exist but only appear after tee-off.
- **Know what I'd be playing for:** No. "$25 / player", "60 / 25 / 15 · champ / 2nd / king", "Best 3 / mo", "Cup Final from Sat Nov 7" — I can read the numbers; I cannot say what my Saturday score will earn, or how, since I have no "number". In the live game I'd be playing for "$5 a skin", which I understood instantly.

**Score: 4 / 10.** The right tool for my exact goal is in the app and is the best thing in it; the app's front door, orientation and Home all point a first-timer at the wrong tool, in a vocabulary he doesn't have, on a timeline (a season starting tomorrow) that punishes the honest attempt.

**Where I stalled:** the Clubhouse after locking — "Squads drawing · rosters pending", a link in the group text, three friends who haven't installed, and no sentence telling me what Saturday's round will be worth or what I do if only two of them show up in the app.

**The "oh, that's actually cool" moment:** the ⊕ cover — "Play now — score the group … Friends without the app just play; their card is waiting when they want it." And then, in the setup, the "Add a guest: Name · Index · Add" row with "Leave index blank for an estimated 18": I could type Danny, Chuck, Gary and go. That is the whole product for a guy like me, and it took fifteen taps of wandering to find it.
