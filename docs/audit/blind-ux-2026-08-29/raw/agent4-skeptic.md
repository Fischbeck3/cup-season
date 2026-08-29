# Blind UX audit — Agent 4, the Skeptic ("Sam Kowalski")

**Persona:** Sam Kowalski, Gilbert AZ, ~15 handicap on 18Birdies, plays Western Skies. Group already runs on a group text + shared spreadsheet + 18Birdies. Stance: "Why wouldn't I just keep using what we have?"
**Account:** jerecho+blind6@fischbeck3.com · **Session:** `skep` (iPhone viewport, headless) · **Date:** 2026-08-29
**Invitation:** a text from Casey Ortega: "yo, set us up on Cup Season for the fall — link … code THEPTCQ5" (league "The Papago Grind").
**Email invitation:** NONE addressed to me. Gmail search `"Cup Season" newer_than:6h` returned only sign-in-code mails to other testers and one "Priya wants in your crew" mail addressed to a different tester (`jerecho+blind1`). So the only invite a real Sam has is the text + the code. Nothing in email explained what the app is.

Screenshots live under `../screenshots/skep/` (referred to below by file name).

---

## Timeline

| UTC | Event |
|---|---|
| 15:21:25 | Session started. |
| 15:21:38 | First `goto /` landed on an ALREADY SIGNED-IN home (stale session in the harness profile) showing a league "The Papago Grind · forming", a toast "Your unposted round came back — it's waiting in Post a round" (`01-door.jpg`). Not a real cold start; reset with `/?exit`. |
| 15:22:20 | Cold door, signed out (`02-cold-door.jpg`). |

---

## Journey A — Discovery (signed out, cold)

**Screen:** `02-cold-door.jpg`. A dark screen. An orange icon — a flag on a stand, or maybe a pin flag inside a trophy cup silhouette. Wordmark "C U P  S E A S O N". Three-line tagline, the last in orange:

> "Rally your crew. Post real rounds. **Take the cup.**"

Two buttons: **[Continue with email]** (orange, primary) and **[I have an invite code]** (dark, secondary). Footer: "By continuing you agree to the Terms & Privacy Policy." Then, in grey monospace: **"v23 · __CS_VERSION__"** — a raw, unfilled template placeholder is visible to the user on the very first screen.

Behind the dialog (visible in the accessibility tree, and part of it peeks in the DOM): a header with a magnifier "Find golfers" button, "Around your buddies", "THE BOARD ↗", and a bottom nav "Home / Clubhouse / Post / You". The signed-out user does not see these; the sheet covers them.

Console at cold load (evidence): `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'` — a failed server query on a signed-out cold load, plus a "Multiple GoTrueClient instances detected" warning.

### 3 / 10 / 30 seconds
- **3 seconds:** Golf (the flag), a competition ("cup"), a friends thing ("crew"). Orange-on-black, looks like a sports-betting app.
- **10 seconds:** I can sign in with email or with a code someone gave me. "Post real rounds" — so I type in scores. "Take the cup" — win something. Nothing tells me WHAT the cup is, how long a season is, whether it costs money, or how it differs from 18Birdies.
- **30 seconds:** I could sign up. I could not tell you what I'd be signing up FOR. There is no "how it works", no screenshots, no example, no "learn more". The door is a wall with two handles.

### First answers to the 10 discovery questions (cold, signed out)
1. **What does the app do?** Something like a golf league app where a group of friends posts scores and someone wins a "cup" at the end. That is inferred from three words; the screen never says it.
2. **Primary action?** "Continue with email" — sign up. There is no way to do anything without signing in.
3. **What is a "season"?** Guess: a stretch of months (fall?) where rounds count. Casey's text said "for the fall", so I'm leaning on Casey, not the app.
4. **What is a "league"?** The invite-code button implies you join one. Guess: our group. Not defined.
5. **What is a "cup"?** No idea. A trophy? A pot of money? A final tournament? The screen says "take the cup" like it's obvious.
6. **What am I competing for?** Unknown. "The cup." Bragging rights? Money?
7. **Against whom?** "Your crew" — my buddies, presumably. Whether it's individual or teams, no clue.
8. **How do rounds work?** "Post real rounds" — I type in a score after I play. Whether handicaps apply, whether it needs to be with league members, whether any course counts: unknown.
9. **After a round?** Unknown. Presumably a standings table moves.
10. **What makes this different from just playing golf with friends?** From the door: nothing I can point to. "Rally / post / take" is a slogan, not a mechanism. I already post real rounds to 18Birdies.

**Harsh read of the door's promise:** "Rally your crew. Post real rounds. Take the cup." promises a competition, but it is not specific enough to make a skeptic sign up. It doesn't answer: how long, how scored, how much, what do I win, why not a spreadsheet. If Casey hadn't texted me, I'd close the tab. The only reason I continue is social obligation. The visible `__CS_VERSION__` placeholder reads as "unfinished software" to a skeptic — first impression damage before a single tap.

**USER ASSUMPTION:** "I have an invite code" will take me to a place where I type THEPTCQ5 and land in Casey's league.
**USER ASSUMPTION:** the link in the text will show me the league before I sign in.


## Journey B — Signing up and joining (grudgingly)

| UTC | Event |
|---|---|
| 15:23:19 | Opened Casey's link `/?join=THEPTCQ5` signed out (`03-join-link.jpg`). Same door, email box now revealed, plus one grey monospace line: "You're invited to The Papago Grind. Enter your email and you're in." The "Continue with email" and "I have an invite code" buttons are STILL shown above the email box, which now does nothing useful. |
| 15:23:44 | Typed email, tapped **Go**. Screen: "CODE FROM EMAIL" box + **Verify**, status "Sent to jerecho+blind6@fischbeck3.com. Type the sign-in code from the newest email." and "Resend code (26s)" countdown (`04-after-go.jpg`). |
| 15:23:47 | (Learned later) the code email actually landed 3 s after Go. |
| 15:24–15:26 | I could not find it: Gmail had threaded 20 identical-subject "Your Cup Season sign-in code" mails into one conversation and my searches returned the thread head, not the newest message. I waited ~100 s, then tapped **Resend code** (15:25:37). Status: "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends." then "Fresh code sent to … — the newest email wins." |
| 15:27:15 | Found both codes at the bottom of the thread; typed the newer one (22692497). **The app verified it the instant the 8th digit landed** — my tap on "Verify" reported nothing to tap; the button was already gone. ~3.5 min from Go to signed-in, almost all of it inbox-hunting. |
| 15:27:23 | Signed in. A sheet: **"Welcome to The Papago Grind — THREE THINGS TO KNOW"** (`05-after-verify.jpg`). |

**What the sign-in email says** (verbatim, plain text): "## Your Cup Season sign-in code / *22692497* / Enter this code in the app. It expires in one hour. If you didn't request it, ignore this email." Nothing about the league, the invite, or what Cup Season is. Subject "Your Cup Season sign-in code" (it was the *returning-user* subject; other testers got "Confirm your email address" / "Welcome to Cup Season").

**CAVEAT — the account was not fresh.** Behind the welcome sheet, Home already showed "You 🎉 First round on the card — 91 gross — Papago Golf Course · White · Aug 29" and "🏁 Sam joined the league". A prior run had used this address. So I never saw the *golfer-card / profile* onboarding a brand-new user sees; I also never saw a first "join" confirmation. Everything below is the experience of a user who is already a member. Flagged in `blockers`.

### The welcome sheet (`05-after-verify.jpg`)
Heading "Welcome to The Papago Grind", eyebrow "THREE THINGS TO KNOW" — followed by **four** bold items:
1. "**You're on the pot sheet: $50 buy-in.** The Pro tracks who's paid; money moves between you." (yellow)
2. "**You can't hurt your squad by playing badly.** Only by not playing. Every posted round scores — a rough day is still points on the board."
3. "**Rounds score against your own number.** Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst."
4. "**The pot lives on the books.** Cup Season keeps the tab and shows who owes what; money moves between you."
Then link "How scoring works →", and "**Who else plays with you?** Growing the league isn't the Pro's chore — any member's link works." + button **[Share the invite link]**.

OBSERVATION: The first thing the product tells me after sign-up is that I owe $50. Casey's text did not mention money. The door did not mention money. INTERPRETATION: a skeptic reads this as a bait-and-switch — I was told "set us up for the fall", not "$50 buy-in". IMPACT: this is the single most likely bail point for my persona; a real Sam replies to the group text "wait, fifty bucks for what?" — and the app cannot answer, because the sheet never says what the $50 wins. It says the Pro "tracks who's paid" and "money moves between you", i.e. the app does not even handle the money — which raises the question of what the app is for.

Terms met with no definition: **the Pro**, **squad**, **pot sheet**, **your number**, **the books**.

### "How scoring works" (`06-how-scoring.jpg`, `07-how-scoring-2.jpg`)
Eyebrow "HANDICAPS · CUP POINTS · THE MONEY". Sections:
- **Your number** — "Your handicap index builds from your scores — no typing… WHS-style. It appears once you've posted 3 rounds; until then it shows as building. You (or the Pro) can set a starter to get going sooner… Manual changes are announced to your league so the crew keeps everyone honest."
- **Every round → cup points** — "Every round is scored against your own number — a 22-index beating their number is worth exactly what a 6-index beating theirs is:" then a table: "Torched it · beat it by 3+ · 12 pts / Beat your number · by 1–3 · 9 pts / Played to it · within 1 · 7 pts / A little loose · 1–3 over · 6 pts / Posted anyway · rough day · 5 pts". "The 12-point ceiling caps what a padded number can buy; the 5-point floor means a posted 98 still beats an unposted 82."
- **What counts** — "Your best rounds each month count for your squad… everyone owes a minimum number of rounds a month so nobody coasts. Miss it once and your season bye covers you automatically… the floor bites from the second miss. Your league's exact numbers are in League rules." (not a link)
- **The money** — "The pot is on the books — Cup Season keeps the ledger and shows a settlement card; the money moves between you."

OBSERVATION: This is the ONLY explanation of the game and it is one link deep on a dismissable sheet. It does not say what the cup is, how the season ends, who wins the pot, what a squad is, how many best rounds count, or what the minimum is. The band edges overlap ("by 3+" and "by 1–3" both contain 3; "within 1" and "1–3 over" both contain 1). "Beat it by 3" — three what? Strokes net of handicap, presumably. USER ASSUMPTION: "your number" = my handicap index, and "beat it by 3" = net score three under my handicap-adjusted expectation. ACTUAL PRODUCT BEHAVIOR: unverified at this point.

Skeptic's read: 5 points for a terrible round vs 12 for a great one is a 2.4× spread. Showing up is worth more than playing well. That is a deliberate design (it says so), but it means the "competition" is mostly attendance — which my spreadsheet already tracks.

## Home (signed in) — `08-home-after-close.jpg`, `09-home-full.jpg` (15:29)

Top of screen, above my own league: three grey buttons **[Start a league] [Start an event] [Join a league]**. I am already in a league; these are creation tools, and they are the first thing on my Home.

Hero card: "THE PAPAGO GRIND · FORMING — **7** days — to first tee. **5 golfers in.** *The bylaws lock at the tee.*" A "ROSTER ▬▬▬ 5 IN" progress bar (about 40% full — of what target? never stated). Then a huge orange primary button **[Lock it in and invite your crew]**.
OBSERVATION: I am a member, not the organizer, and the biggest button on my home is "Lock it in". INTERPRETATION: either I can lock Casey's league (alarming) or the button does something else (mislabeled). USER ASSUMPTION: this is the Pro's button shown to everyone by mistake. ACTUAL: tested later (see below).

Three tiles: "LEAGUE — The Papag… — OPEN THE ROOM", "NEXT — Open — PLAN A ROUND", "BOARD — 6 — NEW TODAY". Pill: "MONTH CLOSES **in 2 days**". Grey paragraph: "Monthly floor · **2 rounds a month**. Miss it and your squad loses 5 points for every round you're short. Short months are waived."
OBSERVATION: "Month closes in 2 days" sits next to "7 days to first tee". Do I owe 2 rounds in the 2 remaining days of August, before the season even starts? "Short months are waived" might mean no — but "short month" is undefined (a month with fewer days? a partial month?). A skeptic reads the two lines as a contradiction.

Feed ("Around your buddies · THE BOARD ↗"): "Marcus joined the league", "Match play: Priya def. Casey 2 UP THRU 3 · $5 on the line · SCORECARD ›", "You 🎉 First round on the card · 91 GROSS · Papago Golf Course · White · Aug 29", "Jordan 🎉 First round on the card 97", "Jordan/Sam/Priya joined the league", "Match play: Casey def. Marco 1 UP THRU 3 · $5 on the line", "THIS WEEK: Priya 84 Ken McDonald · Black · Aug 25", "Priya 🔥 Personal best 74 TPC Scottsdale (Champions) · Aug 27".
OBSERVATION: every score in the feed is GROSS. No points, no net, no handicap context, no "what this did to the standings". "First round on the card" — what card? "2 UP THRU 3" — a match that ended after three holes? "$5 on the line" is the only stakes language and it is for side matches I wasn't in. Compared with my group text this is the same information (Priya shot 74) with less banter (no replies visible).

A toast appeared twice: "Your unposted round came back — it's waiting in Post a round". I have no idea what unposted round; it was there before I did anything this session.

## League room — `10-league-room.jpg`, `11-league-room-full.jpg` (15:29:55)

"YOUR GROUPS — [The Papago Grind · HERE]". Card: "The Papago Grind — Squad formation — [Code · THEPTCQ5] — Sat Sep 5 → Sat Jan 2 · 17 wks — THE PRO · CASEY — [Add golfers]". Tab strip: **Standings · Board · Schedule · Pot · Album · League**.

Standings tab: "SQUADS ARE FORMING — **The Pro has the list.** — 5 PLAYERS IN THE POOL — [See the squads] [Share the invite link]". Then "THE INDIVIDUAL RACE · EVERY PLAYER" with three empty tiles "— POINTS KING", "— MOST IMPROVED · NEEDS 2+ ROUNDS", "— IRON MAN", and a table "PLAYER · R · AVG VS INDEX · PTS": Jordan 0 — 0, Casey 0 — 0, Marcus 0 — 0, Priya 0 — 0, Sam 0 — 0. Footnote: "Points King takes 15% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with the squad race — bylaws §4."
OBSERVATION: I have a 91 on the board from today and the table says Sam R=0, Pts=0. Nothing on this screen says "rounds before Sep 5 don't count". INTERPRETATION: a new member's first experience of the standings is "my round didn't count and nobody told me why". "R" is an unlabeled column (rounds?). "Avg vs index" shows "—". "bylaws §4" — a citation to a document I have not been shown.
"The Pro has the list." — reads like a phrase from a game I wasn't taught. Which list? The squad assignments?

Pot tab (`12-tab-Pot.jpg`): "SEASON STAKES — THE POT — **$250** — 5 × $50 · $0 collected · 5 still owe" then three tiles "$150 Cup champs / $63 Runner-up / $38 Points king", then "**Cup Season keeps the books.** Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar." Then "BUY-INS · 0/5 IN" with five rows (Priya, Jordan, Sam, Casey, Marcus) each with an empty checkbox — and each row is a tappable button. Then "THE OTHER STAKES · PRIDE, ON THE BOOKS — [Post a stake] — No stakes on the books. The cookout isn't going to bet itself."
OBSERVATION: This is the first place the prize is stated: $150 to "Cup champs" (plural — so a team), $63 to runner-up, $38 to "Points king". The $ figures do not add to $250 ($251 by rounding). The buy-in rows look tappable by anyone — can I check myself off as paid? (Tested below.)
INTERPRETATION for the skeptic: the app does not move money. It is a ledger. Venmo + a spreadsheet row already does this.

League tab (`13-tab-League.jpg`): "Members & invites · 5 PLAYERS [View]", "Share the season — A public page — the standings so far, no account needed [Link] [✕]", "Squads · LIVE NOW — CAPTAINS READY [View]", a collapsed "▶ LEAGUE RULES & PRO SHOP" whose contents (from the text dump) are: "The bylaws · locked at first tee — STRUCTURE 2 squads · Squad formation Blind draw · PRESET Standard · HANDICAP ALLOWANCE 95% · VERIFICATION Attested · COUNTING CAP Best 4 / mo · PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short · BUY-IN $50 / player · POT SPLIT 60 / 25 / 15 · champ / 2nd / king · SEASON 4 mo · Sat Sep 5 → Sat Jan 2 · 17 wks · CUP FINAL Final 4 weeks · from Sun Dec 6 · scored fresh — [How scoring & handicaps work →]". Then "The Pro Shop — CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE — SOON Custom rules, every dial unlocked · SOON Live draft night with pick timer · SOON Trades & waiver wire · SOON Multi-season history & records — [Coming at launch]".
OBSERVATION: The actual rules of the game are in a collapsed accordion, on the sixth tab, of the room, behind a tile on Home. They are written as a spec sheet ("PRESET Standard", "VERIFICATION Attested", "COUNTING CAP Best 4 / mo", "scored fresh") with no sentences. "Squad formation: Blind draw" and "STRUCTURE 2 squads" is the first time I learn this is a TEAM game with two random teams — nothing on the door, the welcome sheet, or the scoring explainer said so. "CUP FINAL · Final 4 weeks · scored fresh" is the first appearance of what "the cup" might be, and "scored fresh" is not explained.
"Squads · LIVE NOW — CAPTAINS READY" on the League tab contradicts "SQUADS ARE FORMING — The Pro has the list" on the Standings tab, 40 px apart.
The Pro Shop says a paid "membership" is coming and "the pilot rides free" — so there WILL be a subscription on top of the $50 buy-in; no price, no "what's included today".

Schedule tab (`14-tab-Schedule.jpg`): tapping it LEFT the league room and opened a full-screen "← HOME · YOUR GOLF CALENDAR · yours, your buddies', your leagues'" with an AUG 2026 grid, legend "ON THE TEE SHEET · LEAGUE MATE · SEASON DATE", "[Put a round on the tee sheet]", "ON THE TEE SHEET — Nothing on the tee sheet for Aug. Put one up: league mates and buddies see it the moment you do." The other five tabs are in-place; this one navigates away and the tab strip disappears. The season (Sep 5) is not visible on the August grid; no hint to swipe forward. Console: the same `[live-resume] server query failed … live_rounds / live_round_players` warning fired again.

Board tab (`17-tab-Board.jpg`, 15:31): "THE BOARD · ROUNDS LAND HERE AUTOMATICALLY — OPEN ↗". Dated "SAT · AUG 29": "◆ Match play: Casey def. Marco 1 UP THRU 3 · $5 on the line", "◆ Priya joined the league", "◆ Sam joined the league", "◆ Jordan joined the league", a chat bubble "**Sam** 91 at Papago. Casey you owe me a beer for the Grind sign-up." with reaction buttons [🔥] [⚑], "◆ Match play: Priya def. Casey 2 UP THRU 3…", "◆ Marcus joined the league", then an input "Message the league…" + [Send].
OBSERVATION: the Board IS the group text — system events and human messages interleaved, with two reactions. That is the closest thing to my current behavior. But it lives on the second tab of a room three taps from Home; Home shows a read-only summary of it. The prior run's "Sam" posted a message; it has zero replies, so I can't judge whether banter would actually happen here. A "⚑" reaction with no label — what does flagging a message do?

Album tab (`18-tab-Album.jpg`): "The album · every round photo this season — Photos land here when rounds carry them — add one from the Post card." Empty.

"See the squads" (`19-squads.jpg`, `20-squads-full.jpg`, 15:32): a full-screen "FORM SQUADS · BLIND DRAW — **5 in the pool** — THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW". Two cards "Squad 1 · 0 PLAYERS · Empty", "Squad 2 · 0 PLAYERS · Empty". "PLAYER POOL — THE POOL" with five chips (Priya, Jordan, Sam, Casey, Marcus) — every chip and both squad cards are tappable buttons. No back button; no "draw" button; no explanation of who draws or when. USER ASSUMPTION: this is the Pro's admin tool and I'm looking at it by mistake; tapping my name might move me into a squad. NOT TESTED (shared league; I did not want to mutate other testers' state) — but a real member would tap, and nothing on the screen says whether he can. Exit was only via the bottom nav.
"Squad" is now three things at once: a team (2 squads), a formation state ("Squad formation"), and a points target ("your squad loses 5 points").

## You tab — `21-you-full.jpg` (15:33)

Header: cactus avatar, "Sam · @SAM · Member since Aug 2026 · add your GHIN" [⚙]. Big "**15.2** HANDICAP INDEX", "FORM ●" (a lone grey dot, no label). "[💬 Tell us how it's going →]".
"YOUR DISPLAY CASE": "⛳ First round · Posted · '26", "🎯 Broke 100 · 91 gross · '26". "THE RECORD: No silverware yet — every season starts level."
"LIFETIME": Rounds posted 1 · Best vs index **-4.5** "Career best" · Avg vs index **-4.5** "vs your index" · Cups & events **1** "Played in".
"RECENT ROUNDS": "2026-08-29 · PAPAGO GOLF COURSE · WHITE — **91 · 19.7**" with an ✕ ("Delete round"). Then [Post a round]. "YOUR BUDDIES — Find golfers, see who you play with". "THIS SEASON · THE PAPAGO GRIND": Rounds posted **0**, Avg vs index —, Best round —, Index move — "Season to date". "LEAGUE RECORD: The Papago Grind · SEASON I · Squad formation". "HOW IT WORKS": five guide rows — "The four places · Home · Clubhouse · the ⊕ · You", "Leagues vs events · The long game and the short game", "Posting a round · Basic, live, and the scan", "Buddies, invites and claims · Three different links, three jobs", "How scoring works · How rounds become points".

OBSERVATION: "91 · 19.7" — the 19.7 is unlabeled. A 15-handicap knows 19.7 is probably the differential, but the app never says so, and this row is NOT tappable (my tap did nothing; the only control is Delete). There is no way from here to see what the 91 earned. "Best vs index -4.5": I shot 91 with a 15.2 index, on White tees at Papago; how is that 4.5 UNDER my index? Nothing explains the sign convention (negative = good?) or the math. "Broke 100" as a trophy for a 91 is a badge a 15-handicap did not earn. "Cups & events: 1 Played in" — I have played in nothing; the season hasn't started.
The 15.2 index — I (a prior run) must have typed it as a "starter"; the scoring sheet said the index "builds from your scores — no typing", and here it is typed. Where do I enter my 18Birdies 15? The only hint is "add your GHIN", which I don't have.
"How it works" — the real manual — is at the bottom of the profile tab, below lifetime stats. A new member would not find it without scrolling the whole You page.

## The "How it works" guides (You tab, 15:33–15:34) — `23-guide.jpg`…`26-guide.jpg`
- **The four places** — "ONE APP, FOUR ROOMS. Home is everything you're in, one feed… Clubhouse is one league's room: Standings, the Board, the Schedule, the Pot, the Album, the League… The ⊕ in the middle is one door for before, during and after a round… You is your card, your record, your trophies and your buddies. The ⚙ on your card runs everything else."
- **Leagues vs events** — "A league is the long game. A full season — weeks or months, squads or solo, every round you post counts toward a table, and the endgame settles it: a Cup Final or the points table. An event is the short game… the Ryder (two teams, weekly duels), or a Major…"
- **Posting a round** — "After you play: front nine, back nine, pick the course — twenty seconds. It counts on your card and in every league you're in. Scan the card and the app reads it… During: Play now is the shared pencil — match play, Wolf, skins, the settle-up… Before: put a tee time on the sheet."
- **Buddies, invites and claims** — "A buddy is mutual… Nothing to do with leagues or points. An invite link carries a league's code… A claim link hands one round to a guest…"
OBSERVATION: These four cards are the clearest writing in the product and they are the LAST thing on the profile tab. The "Leagues vs events" card is the first sentence anywhere that says what a season is ("a full season — weeks or months… the endgame settles it: a Cup Final or the points table"). That sentence belongs on the door.

## Journey D — First round (15:34:34 →)

The ⊕ / "Post" opens a three-door screen (`27-post-1.jpg`): "GOLF · BEFORE, DURING AND AFTER THE ROUND" — "● LIVE **Play now — score the group live** · Hole-by-hole · match play, Wolf & the settle-up · every complete card posts at the finish. Guests welcome, no account needed." / "**Post a round — after you play** · Gross + tee, 20 seconds · counts on your card and in every league" / "**Plan a tee time — before** · Put a round on the tee sheet…". The LIVE door is visually first and has the orange accent; posting a finished round is second.

Post form (`28-post-form.jpg`): "← GOLF · POST A ROUND · YOUR INDEX 15.2". "COURSE & TEES" search box "Search a course, or type your own" + a chip "[Papago Golf Course · White · 70.1/120]" (my last course). "RATING 72.1 / SLOPE 128" (placeholders). "YOUR CARD [18 holes] [9 holes]". "FRONT 9 GROSS 41 / BACK 9 GROSS 43" placeholders + "How most golfers keep it — 41 out, 43 in. Played just one nine? Fill that side only and it posts at half value, half a round." "DATE 2026-08-29". "[Scan the card] [Add a photo]". "Enter your card to see the score." **[Post round]** "Start over — clear this card". Below: "HOW THIS ROUND SCORES — LEAGUE POINTS THIS ROUND — – — Enter at least one nine. — – GROSS · – VS YOUR INDEX — No league yet? The round still counts on your card — points apply in any league you join." Then "POINT BANDS": "Beat your index by 3+ · 12 / Beat it by 1–3 · 9 / Within a stroke either way · 7 / Over by 1–3 · 6 / Rough day, posted anyway · 5 — Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time."

### The nine questions, answered from the form BEFORE entering anything
1. **How do I know what round I'm playing?** I don't "play a round" in the app — I report one. The form asks for course, tees, two nine-hole totals and a date. There is no notion of a scheduled league round.
2. **Who am I playing?** Nobody. Nothing on the form names an opponent or a squad. The points table on the form says "your squad" but I don't have one yet ("Squads are forming").
3. **What format?** Individual stroke play against my own handicap, inferred from "vs your index" — never stated.
4. **What are the rules?** The five point bands are here (good — this is the best placement of them in the app). Nothing about attestation ("VERIFICATION Attested" in the bylaws — attested by whom? the form asks nobody), or which tees are allowed, or whether a round with non-members counts.
5. **How are handicaps applied?** "YOUR INDEX 15.2" in the header; "vs your index" in the preview. How index + rating + slope turn into "beat it by 3" is not shown. The bylaws' "HANDICAP ALLOWANCE 95%" appears nowhere on this form.
6. **What do I need to enter?** Course, tee (or rating + slope), front 9, back 9, date. Clear.
7. **What counts toward the season?** "Your best 4 each month count toward your squad" (form footer). The season starts Sep 5 and today is Aug 29; the form does NOT say this round will not count for the league. The preview will show "League points this round" regardless.
8. **What counts toward side games?** Nothing here. Side games (match play, Wolf, skins) live behind the LIVE door; this form has no concept of them.
9. **What if something goes wrong?** "Start over — clear this card" before posting. After posting: the You tab has an ✕ "Delete round". No edit. Not stated anywhere on this form.

### Entering the round
- Typing in the course box: the harness's first two attempts to type timed out because the page carries a second, hidden input with the same placeholder (harness artifact, logged in blockers). Typing by label worked; "Ken McDonald" → one result "[Ken Mcdonald Golf Course Tempe, AZ · 7 tees]" (15:36:32). Tapped it → tee list "[‹ Back to courses] Tips 72.3/127 · Black 71.9/125 · Blue 70.4/121 · White 68.7/115 · Red 66.7/107 · White · Women's 74.5/129 · Red · Women's 71.6/122" (`31-tees.jpg`). Picked White; Rating/Slope auto-filled 68.7 / 115. Good — this is better than 18Birdies' course picker, honestly.
- Front 46, Back 45. The button changed to "Gross 91 · 18 holes" and the preview filled in (`32-pre-post.jpg`, 15:37:08):
  > LEAGUE POINTS THIS ROUND — **5** — "Rough one, but posted rounds always score." — **91** GROSS · **-6.7** VS YOUR INDEX — "No league yet? The round still counts on your card — points apply in any league you join."

OBSERVATION: (a) "-6.7 vs your index" — negative means WORSE here (I shot 6.7 over my number). Every golfer reads a negative number as good (under par). The You tab's "Best vs index -4.5 · Career best" uses the same inverted sign. (b) "No league yet?" is shown to a member of a league. (c) "League points this round: 5" is shown for a round that, per the bylaws, is six days before the season — the form promises 5 league points it cannot deliver. (d) "Rough one" for a 91 by a 15-handicap on a 115 slope is fair, but the message tells me I'm at the floor without telling me the threshold: what would I have needed for 6 or 7? (I had to read the bands and guess: within 1–3 over → 6.)
USER ASSUMPTION: this 91 will show up as 5 points for my squad. ACTUAL PRODUCT BEHAVIOR: see after posting.

### Posting (15:38:08 → 15:38:14, one tap, ~6 s)
"Round posted" sheet (`33-posted.jpg`): "KEN MCDONALD GOLF COURSE · WHITE · SAT AUG 29 — **91** — 6.7 over your number — [COUNTS ON YOUR CARD] — [Share the card] (green) — Back to the board". Console at that moment: `Failed to load resource: the server responded with a status of 502 ()` — something server-side failed on the post; nothing was shown to me.
OBSERVATION: The preview promised "LEAGUE POINTS THIS ROUND 5"; the confirmation says nothing about points or the league — only "COUNTS ON YOUR CARD". The two screens, ten seconds apart, tell different stories. At least "6.7 over your number" is now worded in English instead of "-6.7".

**Share the card** (15:38:31): tapping it changed nothing on screen. A hidden `role=status` element read "Card downloaded" (found by inspecting the DOM; it was never visible under the sheet). So "share" = silently save a PNG. On a phone a person would tap it twice, then give up. `navigator.share` is unavailable in this browser, so a real iPhone may get a share sheet — but the fallback gives no visible feedback. Not a screenshot I'd send anyway: it's my 91 with "6.7 over your number" on it.

Back on Home (`35-back-board.jpg`): feed top item "**You** 6.7 over your number — **91** GROSS — Ken Mcdonald Golf Course · White · Aug 29" (the tree reads "9 1 gross" — the digits are split into separate spans, so a screen reader says "nine one"). A new board note appeared meanwhile: "🏁 Jordan v Casey — Loser buys the beers. Loser hosts the cookout" — someone posted a side "stake" (the Pot tab's "Post a stake"). That is the most group-text-like object in the app, and it's rendered as a system line with no way to reply.

**Receipt** — tapping my round card opens "91 gross" (`36-round-receipt.jpg`): "KEN MCDONALD GOLF COURSE · WHITE · 18 HOLES · 2026-08-29 / The course 68.7 / 115 / 91 − 68.7 × 113 ⁄ 115 = **21.9 DIFFERENTIAL** / YOUR NUMBER THAT DAY 15.2 / Against your number **-6.7 — POSTED ANYWAY**".
OBSERVATION: This is the one screen that shows its work, and it is good: the WHS differential formula is right there. But: no points figure (the preview's "5" is gone), no league, no "this counts toward…". The sign is inverted again (-6.7 = worse). "POSTED ANYWAY" is the band name, but nothing links it to "5 pts".

**Standings after posting** (`37-standings-after.jpg`, 15:39:35): Sam still "R 0 · — · Pts 0". My round is on the feed, on my card, but not in the league table — and the table doesn't say why. I know from the bylaws (six taps away) that the season starts Sep 5; a real member would think the post failed.
ACTUAL PRODUCT BEHAVIOR (vs my assumption that the 91 would count as 5 squad points): it counted for nothing in the league. The preview's "LEAGUE POINTS THIS ROUND 5" was wrong for this date.

### Could I explain to a friend what just happened? (verbatim attempt)
"I typed in my 91 from Ken McDonald, front and back, picked the white tees. It told me I was 6.7 over my number, which apparently means I played 6.7 strokes worse than my handicap — it computes a differential like GHIN does. The preview said I'd get 5 league points, which is the minimum you get for just posting. Then it said the round counts on my card and… it doesn't show up in the league standings. I think that's because the season hasn't started, but the app didn't say that. So: I logged a round, got a badge for 'breaking 100', and nothing happened to the competition."
Honest score on "do I understand whether I won or lost / what I earned": I understand I played badly relative to my index. I do not know what I earned (5? 0?) or whether anyone else in the league saw it as anything but "91 gross".

## Social objects and settings (15:41–15:43)

**The full Board** (`42-full-board.jpg`, "THE BOARD ↗" on Home): a sheet "THE BOARD · THE PAPAGO GRIND" listing the same items as the room's Board tab, with the chat composer "Message the league… [Send]" pinned at the bottom. My old message has three controls: [🔥] (accessible name "heater"), [+] "More reactions", [⚑] "Report this post". So the flag is a REPORT button sitting next to the reaction — one slip and I've reported my buddy's trash talk.

**Match-play scorecard** (`45-matchplay2.jpg`, tapping "Match play: Priya def. Casey 2 UP THRU 3 · $5 on the line · SCORECARD ›"): sheet "Scorecard — MATCH PLAY · KEN MCDONALD GOLF COURSE · BLACK — Priya def. Casey 2 up thru 3 · $5 on the line", a hole-by-hole table (Par, SI, Priya 4·5·3, Casey 5·6·4, then dots), "Aug 29 · Gold marks the holes that decided it. **Not every hole was scored — Priya, Casey have gaps.**" (red).
OBSERVATION: This is a real, screenshot-able object — the closest to something I'd drop in the group text. But it is a three-hole "match" declared as a win with "$5 on the line", and the app flags it in red as incomplete while still calling it "def." — so it reads as a test artifact rather than a result. A skeptic notes that side money ($5) is on the board the same day the real pot is "$0 collected".

**Find golfers** (`41-find-golfers.jpg`): a search sheet "Find golfers — Search by name or @handle to add buddies". Buddies are a separate social graph from the league ("Nothing to do with leagues or points"). I already have a league of buddies; a second friends list is a second thing to maintain.

**Card & settings** (`38-settings.jpg` → `47-settings-6.jpg`). "Your card" tab: name, city, home course, 14 "ball marker" icons ("THE SAGUARO, THE ISLAND, THE LIGHTHOUSE… THE THISTLE" — famous holes as avatars; unexplained), photo, handle "moves once / 60 days", "Findable by All / Buddies / Nobody", "GHIN # · optional — A reference on your card — we never resell or verify it", **Handicap index 15.2 [Update index]** — "Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed." "Your leagues: The Papago Grind PLAYER · THEPTCQ5".
"Settings" tab (took FOUR attempts to open — the harness's "Settings" click kept matching the hidden "Card & settings" gear behind the sheet; a real thumb would not have this problem): "Notifications — [Enable on this device] — Round pings: ON · Chat pings: ON · Season email: ON — Moments, reveals, and month closes always come through. Round posts and chat each have their own switch." "Appearance — Charcoal · Light · Match device". "**Membership & billing — PLAN FREE · PILOT — Cup Season membership lands at launch. Nothing to pay during the pilot.**" "Sign out". "Danger zone — Delete my account". "Cup Season · v23 · __CS_VERSION__" (the raw placeholder again). Links "Privacy · Terms · Prize pool".
OBSERVATION: So my 18Birdies 15 CAN be typed in as a "starter", but the field is at the bottom of a settings sheet behind a gear icon, and the scoring explainer told me "no typing". "Round pings ON" — I never enabled notifications on this device; the toggles read ON while the master switch says "Enable on this device" — which is it? "Season email: ON" — no idea what a season email contains. "Membership & billing: FREE · PILOT — membership lands at launch" — the second warning that a subscription is coming, still no price.

## Three deliberate probes (15:45)

1. **"Lock it in and invite your crew"** (Home, as a plain member) → opened a page headed "**CREATE YOUR LEAGUE · LOCKS AT FIRST TEE** — REVIEW THE BYLAWS, THEN LOCK IT IN" listing the bylaws, then "Lock opens the invite link — one link fills the league; anyone can also join later with the league code. Minimum four to tee off." and a full-width orange button **[Lock the bylaws & form the squads]** + [← Back] (`50-lock-page.jpg`). I did NOT press the lock (shared league; other testers). OBSERVATION: a member is shown the organizer's lock screen under the heading "Create your league" for a league he did not create. Whether the server would accept the lock is untested; the exposure alone is a P1, and it explains why a skeptic won't touch the biggest button on Home.
2. **"Share the invite link"** (Standings tab) → nothing visible changed (`51-share-invite.jpg`); a hidden `role=status` element read "Invite code: THEPTCQ5". No link, no share sheet, no visible confirmation. The "link" Casey texted me is not something this button produces.
3. **Tapping my own buy-in row on the Pot tab** → checkbox stayed empty; a hidden status read "The Pro marks buy-ins as money moves between you" — not visible in the screenshot 1.5 s later (`52-pot-after-tap.jpg`). Correct behaviour (a member can't self-mark paid), but the rows look like checkboxes I can tick, and the refusal is invisible.

Also on the Pot tab: the stake someone posted — "🤝 **Loser buys the beers** — Jordan vs Casey · Loser hosts the cookout · on First round of the season · OPEN". This is the one object in the app that reads like our group text.

**Prize pool legal page** (`49-legal-pot.jpg`, `/legal.html#pot`): "CupSeason does not collect, hold, transfer, or distribute money, takes no fee or cut of any prize pool, and is not responsible for league payouts or disputes… If you are unsure whether a money pool is allowed where you live, keep your league to bragging rights." So: confirmed, the pot is a spreadsheet column.

| UTC | End |
|---|---|
| 15:46 | Exploration complete; ~25 minutes signed in. |

---

## VALUE HUNT — what I do today vs what Cup Season does

| What we do now | Cup Season equivalent | Better / same / worse | Notes |
|---|---|---|---|
| **Group text banter** | The Board (chat + auto-posted rounds + 🔥/+ reactions) | **Worse** for banter, **better** for record-keeping | Chat is three taps deep inside a league room; no replies/threads; a "report" flag sits beside the reaction; zero messages from anyone but a prior-me. Auto-posting scores into the same stream IS nice — nobody has to type "shot 91". But my group text has photos, memes, tee-time logistics and 12 people who are already there. |
| **Spreadsheet standings** | Standings tab (individual race) + squad race (not visible yet) | **Same** today, potentially **better** in-season | My row says 0 after I posted. The spreadsheet at least would show the 91. When the season runs, "best 4 a month vs your own index" is a formula I'd hate to maintain by hand — that is the real spreadsheet-killer, and the app never sells it. |
| **18Birdies score/handicap** | Post a round (gross + tee), auto index after 3 rounds, differential receipt | **Same-ish**; posting is faster, handicap is worse | 20-second post beats 18Birdies' hole-by-hole. But I'd now have two handicaps (18Birdies 15.0 vs Cup Season "building"/15.2 starter), no GPS, no stats. The receipt with the differential formula is better than 18Birdies at explaining itself. |
| **Traditional golf league** | Season + bylaws + Pro + pot + Cup Final | **Better in concept** — play anywhere, any day, any course | The "post from anywhere, it counts" idea is the real differentiator vs a Tuesday-night league. It is stated once, in a guide card at the bottom of the You tab. |
| **Fantasy sports** | Squads (blind draw), Points King, Most Improved, Iron Man, trades "coming at launch" | **Worse** — no draft, no lineup decisions, no weekly matchups I can see | The Pro Shop teases "Live draft night", "Trades & waiver wire" as future. Today "squad" = random team; nothing to manage. |
| **Ryder Cup-style event** | "Start an event → the Ryder (two teams, weekly duels)" | **Untested** | Only saw the description. |

**Better loop, or more features?** Today it is more features. The loop that would beat what we have — post a round → see it move a table against my own number → get needled on the board → chase the monthly floor → cup final — exists on paper (bylaws) but I experienced none of it: my round moved nothing, nobody reacted, and the only stakes in view were $5 side bets between other people.

Where it is genuinely differentiated: (1) the scoring model (every round vs your own index, floor for showing up, cap on sandbagging) is smart and fair for a 15 vs an 8; (2) any course, any day; (3) a ledger for the pot that "makes sure nobody argues at the bar." Where it feels like administrative software: bylaws spec sheet, "Attested", "Preset", "§4", a Pro, a pot sheet, buy-in checkboxes, membership & billing.

## SOCIAL OBJECTS — would I screenshot anything?
- **Yes, maybe:** the match-play scorecard sheet (gold holes, "def." line) — if it were a real 18-hole match. The stake card ("Loser buys the beers").
- **No:** "91 · 6.7 over your number" (that's a screenshot of my shame with the math attached); the standings (all zeros); "Round posted" (a download, not a share).
- **Rivalry / drama / movement:** none visible pre-season. No "you passed Marcus", no "Priya is 3 points clear", no head-to-head. Priya's 74 at TPC Scottsdale is in the feed as a number, not as "Priya just torched it for 12".
- **Notifications I'd want:** a buddy posts a round that moves the table; someone talks trash on the board; month-close warning ("you're a round short"); squad draw result; cup-final start. The settings list "Round pings / Chat pings / Season email" and "Moments, reveals, and month closes always come through" — reasonable, but "moments" and "reveals" are undefined.

## MONEY / SUBSCRIPTION
What I understand: $50 buy-in per player, $250 pot, split 60/25/15 to Cup champs / runner-up / Points King. Cup Season "keeps the books"; money moves friend-to-friend (Venmo, presumably); the app takes no cut and does not hold money. A "membership" is coming "at launch"; the pilot is free. No price anywhere.
**If it cost our group $79/year, the recurring value that would justify it, in my words:** "It runs the whole season so nobody has to be the spreadsheet guy — it scores every round against your own number so the 8 and the 20 are in the same race, it tells you when you're about to miss your two rounds and cost the team five points, it shows who owes the pot and who gets paid at the end, and it's the place the trash talk lives because the scores are already there." I'd pay $79 split six ways for THAT, if it were visibly true on day one. Today I've seen the ledger and the formula; I haven't seen the race.
**What I'd replace with a free tool:** the pot ledger (Venmo + a text), the chat (the group text), the calendar/tee sheet (the group text), buddies/find golfers (we know each other), the album (Photos). What I can't replace for free: the scoring engine and the auto-handicap-vs-index season table.

## "If Cup Season disappeared tomorrow, what would I miss?"
- **Immediately:** nothing — the season hasn't started, and my 91 lives in 18Birdies too.
- **What a group text/spreadsheet replaces:** the Board, the pot sheet, the stake card, the tee sheet, "joined the league" notices.
- **What another golf app replaces:** posting rounds, the handicap index (18Birdies/GHIN do it with more history), course/tee lookup, the scorecard.
- **What cannot easily be replaced:** the rule set — best-4-a-month vs your own index, the floor, the squad race, the Cup Final "scored fresh" — automatically applied across any course, and the receipt that shows the math for every point. That is the product. It is also the part the app hides.

---

## Journey A — the 10 questions, re-answered at the end (what changed)
1. **What does the app do?** A season-long golf competition for a friend group: everyone posts real rounds from any course, each round scores 5–12 points against your OWN handicap, your best 4 a month count for a randomly drawn squad, and the season ends in a 4-week "Cup Final". *Changed: completely — none of this was on the door; I assembled it from the welcome sheet, a scoring sheet, a collapsed bylaws accordion and a guide at the bottom of my profile.*
2. **Primary action?** Post a round (the ⊕). *Changed from "sign up".*
3. **Season?** A fixed window (here Sat Sep 5 → Sat Jan 2, 17 weeks) with monthly closes and a final four weeks. *Changed: now specific — but learned from the bylaws, not from any onboarding.*
4. **League?** A named group with a Pro (organizer), bylaws, a pot, two squads, a board. *Changed: yes.*
5. **Cup?** Still uncertain. Best guess: the "Cup Final" — the last four weeks "scored fresh" — whose winners are "Cup champs" and take 60% of the pot. *Nothing in the app defines "the cup" in a sentence.*
6. **Competing for?** $150 to the winning squad (split how? unknown), $63 runner-up, $38 Points King; plus badges/"silverware". *Changed: from "no idea" to "the pot", but how a squad splits $150 is never stated.*
7. **Against whom?** My squad vs the other squad (blind draw), and individually vs everyone for Points King / Most Improved / Iron Man. *Changed: I did not know it was a team game until tab six.*
8. **How do rounds work?** Gross front/back + tee; the app computes a differential vs rating/slope and compares it to my index; 5–12 points; best 4 per month; 2-round monthly floor. *Changed: understood, mostly from the post form.*
9. **After a round?** It posts to the Board and my card, shows a receipt with the differential… and (pre-season) changes nothing in the standings, without saying why. *Changed: I know more and trust it less.*
10. **What makes this different from just playing golf with friends?** A points race where a 15 and a 6 compete fairly, from any course, with a pot ledger and a final. That IS different — and the door says "Rally your crew. Post real rounds. Take the cup."

## 30-second "explain Cup Season to a friend" (VERBATIM)
"It's an app that turns our regular rounds into a season. You join Casey's league, and every time you play — anywhere — you type in your front and back nine and it scores you against your own handicap: 5 points for just posting, up to 12 if you beat your number by three. Your best four rounds a month count for your team — it splits us into two random squads — and if you don't post at least two rounds a month your team loses points. There's a fifty-dollar buy-in it keeps a tab on but doesn't actually collect, and after four months there's a final few weeks that decides who takes the pot. It also has a chat and a scorecard for side bets. Honestly the scoring idea is good; the app just doesn't tell you any of that until you dig."

## PERSONA VERDICT
**Key question:** Does Cup Season provide enough obvious value to justify changing behavior?
**Answer:** Not as presented. The value that would justify switching — a fair, automatic, season-long race against your own number that a spreadsheet can't do — is real but is the LEAST visible thing in the product. What's visible on day one (a chat, a calendar, a pot ledger, gross scores, a $50 ask, a Pro's lock button) is what we already have or don't want. I'd stay in the group text and let Casey run it; I'd post rounds only because he nags. **Score: 3/10.**

## SCORES (1–10)
conceptClear 4 · setupClear 4 · rulesClear 4 · easyToPickUp 6 · gameplayCompelling 4 · stakesMeaningful 5 · sideGamesCompelling 4 · wouldInvite 3 · wouldPay 2 · wouldPlayAgain 4

## GLOSSARY (product terms met, and what I THINK they mean)
| Term | Where seen | What I think it means | Confusing? |
|---|---|---|---|
| Cup / the cup | door, everywhere | The season's trophy / the Cup Final's prize. Never defined. | yes |
| Season | door, bylaws | A dated window (Sep 5 → Jan 2, 17 wks) with monthly closes. | partly |
| League | door, room | A named friend group with bylaws, a Pro, a pot, squads. | no |
| Crew | door, welcome | Your friends / the league's members. | no |
| The Pro | welcome, room | The league organizer (Casey). Sounds like a club professional. | yes |
| Squad | everywhere | A team (2 per league, blind draw) — also used for "formation" state and points target. | yes |
| Squad formation | room header | The pre-season state before squads are drawn. | yes |
| Blind draw | bylaws, squads | Random team assignment by the server ("the hat"). | no |
| The pool | squads screen | The undrafted players. | no |
| Pot / pot sheet / the books | welcome, Pot tab | The buy-in ledger; app tracks, doesn't hold money. | partly |
| Buy-in | welcome, Pot | $50 per player owed to the pot. | no |
| Stake / Post a stake | Pot tab | A side bet between members, recorded on the board ("loser buys the beers"). | partly |
| Your number | welcome, receipt | Your handicap index. | partly |
| Starter (index) | scoring sheet, settings | A typed handicap used until 3 rounds are posted. | partly |
| Differential | receipt | (gross − rating) × 113 / slope. Shown with the formula. | no |
| vs your index / Against your number | everywhere | differential − index; NEGATIVE = worse. | yes (sign) |
| Cup points / league points | scoring sheet, post form | 5–12 per round by band. | no |
| Point bands: Torched it / Beat your number / Played to it / A little loose / Posted anyway | scoring sheet | Names for the 12/9/7/6/5 tiers. Post form uses different wording. | partly |
| Counting cap · Best 4 / mo | bylaws | Only your best four rounds a month score for the squad. | partly |
| Participation floor / Monthly floor | Home, bylaws | Must post 2 rounds a month or squad loses 5 points per missing round. | partly |
| Short months are waived | Home | Partial months (?) don't enforce the floor. "Short" undefined. | yes |
| Season bye | scoring sheet | One free miss of the floor per season. | yes |
| Month closes | Home | End-of-month tally moment. | partly |
| First tee | Home, bylaws | The season start date. | no |
| The bylaws lock at the tee | Home | Rules freeze at season start. | partly |
| Lock it in | Home CTA | Freeze bylaws + draw squads (organizer action). | yes |
| Cup Final · scored fresh | bylaws | Final 4 weeks re-scored from zero(?). | yes |
| Points King / Most Improved / Iron Man | standings | Individual side prizes: most points / index drop / most rounds. | no |
| Preset · Standard | bylaws | A rules template. | yes |
| Verification · Attested | bylaws | Rounds are vouched for by playing partners(?) — never asked of me. | yes |
| Handicap allowance 95% | bylaws | Net scoring uses 95% of handicap — not visible anywhere in scoring. | yes |
| Card / on the card / First round on the card | feed, post, You | Your personal scoring record. "Card" also = profile card, scorecard, settlement card. | yes |
| The Board | Home, room | The league's activity feed + chat. | no |
| Clubhouse | nav | The league room(s). | no |
| The ⊕ | nav, guide | The post/live/plan door. | no |
| Buddies | You, Find golfers | A separate mutual-follow graph, unrelated to leagues. | partly |
| Claim link | guide | A link that gives a guest a round. | partly |
| Tee sheet | Schedule, ⊕ | A calendar of planned tee times. | no |
| Play now / LIVE | ⊕ | Hole-by-hole group scoring with side games (match play, Wolf, skins). | no |
| Wolf / skins / the settle-up | ⊕ | Side-game formats and the money split after. | partly |
| Event / the Ryder / a Major | guide | Short competitions separate from a league. | partly |
| Ball marker (THE SAGUARO…) | settings | Avatar icons named after famous holes. | yes |
| Moments · reveals | notifications | Unknown notification categories. | yes |
| Pro Shop | League tab | Upsell area for future paid features. | partly |
| Membership · pilot | Pro Shop, settings | A coming subscription; currently free. | partly |
| Display case / silverware / The record | You | Badges and trophies. | no |
| Form (●) | You | Unknown — a dot with no value. | yes |
| R (column) | standings | Rounds, probably. | yes |
| 19.7 / 21.9 (unlabeled) | You recent rounds | The differential. | yes |

## CONFUSION DEBT — what the app assumes I already know
1. That this is a TEAM game with two randomly drawn squads (told only in a collapsed accordion).
2. What "the cup" is and how the Cup Final decides the pot.
3. That there is a $50 buy-in before I sign up.
4. That rounds posted before the season's first tee do not count for the league.
5. Who "the Pro" is and what only the Pro can do (lock, mark buy-ins, draw squads).
6. WHS vocabulary: index, differential, rating, slope, 113.
7. That negative "vs index" is bad.
8. What a "month close", "floor", "bye" and "short month" are, and when they apply.
9. What "attested" verification means for me (nobody attested my 91).
10. That "Share" means "download a PNG" and "Share the invite link" means "here is a code".
11. What "squad formation", "The Pro has the list", "scored fresh", "Preset Standard", "moments", "reveals" mean.
12. That the buddies graph is separate from the league.
13. Where the rules live (League tab → accordion) and where the manual lives (bottom of You).
14. That the ⚑ next to 🔥 is "report", not "flag as good".
15. Which of the many "cards" is meant in any given sentence.
16. That "Lock it in and invite your crew" on my Home is not for me.

## ISSUES (full list; severity · category)
See the structured result for the canonical list; the same 35 issues are summarised here.

- **SK-01 · P1 · onboarding** — The door explains nothing beyond a 9-word slogan; no "how it works", no example, no cost, no length. (`02-cold-door.jpg`)
- **SK-02 · P2 · visual-hierarchy** — Raw `__CS_VERSION__` placeholder rendered on the door and in Settings. (`02-cold-door.jpg`, `47-settings-6.jpg`)
- **SK-03 · P1 · monetization** — $50 buy-in first disclosed AFTER sign-up; the invite link pre-sign-in shows only the league name. (`03-join-link.jpg`, `05-after-verify.jpg`)
- **SK-04 · P3 · comprehension** — "THREE THINGS TO KNOW" lists four. (`05-after-verify.jpg`)
- **SK-05 · P1 · rules** — Point-band edges overlap ("by 3+" vs "by 1–3"; "within 1" vs "1–3 over"); post form words them differently. (`06-how-scoring.jpg`, `28-post-form.jpg`)
- **SK-06 · P1 · rules** — Team structure (2 squads, blind draw) never introduced until the collapsed bylaws on tab six. (`13-tab-League.jpg`)
- **SK-07 · P1 · visual-hierarchy** — Member's Home leads with Start/Start/Join buttons and a giant "Lock it in and invite your crew" CTA. (`08-home-after-close.jpg`)
- **SK-08 · P1 · gameplay** — "Lock it in" opens the organizer's "Create your league… Lock the bylaws & form the squads" page for a plain member. (`50-lock-page.jpg`)
- **SK-09 · P1 · gameplay** — Pre-season round: preview promises "LEAGUE POINTS THIS ROUND 5", confirmation says only "counts on your card", standings stay 0, no explanation. (`32-pre-post.jpg`, `33-posted.jpg`, `37-standings-after.jpg`)
- **SK-10 · P1 · comprehension** — "vs your index" sign is inverted (−6.7 = worse; "Best vs index −4.5 · Career best"). (`21-you-full.jpg`, `36-round-receipt.jpg`)
- **SK-11 · P2 · comprehension** — "91 · 19.7" unlabeled on Recent rounds; row not tappable; only Delete. (`21-you-full.jpg`)
- **SK-12 · P2 · comprehension** — "Month closes in 2 days" + "2 rounds a month" floor shown a week before the season; "short months are waived" undefined. (`08-home-after-close.jpg`)
- **SK-13 · P2 · terminology** — Undefined jargon throughout: the Pro, squad, pot sheet, the books, season bye, scored fresh, Attested, Preset Standard, bylaws §4, moments, reveals. (multiple)
- **SK-14 · P2 · navigation** — Schedule tab leaves the league room for a full-screen calendar; tab strip disappears. (`14-tab-Schedule.jpg`)
- **SK-15 · P2 · comprehension** — Standings says "Squads are forming · The Pro has the list"; League tab says "Squads LIVE NOW — CAPTAINS READY". (`10-league-room.jpg`, `13-tab-League.jpg`)
- **SK-16 · P2 · social** — "Share the card" gives no visible feedback; hidden status "Card downloaded". (`34-share-card.jpg`)
- **SK-17 · P2 · social** — "Share the invite link" yields no link and no visible feedback; hidden status "Invite code: THEPTCQ5". (`51-share-invite.jpg`)
- **SK-18 · P2 · gameplay** — "See the squads" shows the admin blind-draw screen with tappable chips/cards to a member; no back, no permission cue. (`19-squads.jpg`)
- **SK-19 · P2 · social** — Report flag ⚑ sits beside 🔥 with no label. (`42-full-board.jpg`)
- **SK-20 · P2 · rules** — The bylaws are a spec sheet in a collapsed accordion on the sixth tab. (`13-tab-League.jpg`)
- **SK-21 · P2 · monetization** — Pot tiles $150/$63/$38 don't sum to $250; "Cup champs" (plural) first hint of a team prize; squad split never stated. (`12-tab-Pot.jpg`)
- **SK-22 · P2 · monetization** — "Membership lands at launch" in two places, no price, no scope. (`13-tab-League.jpg`, `47-settings-6.jpg`)
- **SK-23 · P2 · onboarding** — No path to bring an existing (18Birdies/GHIN) index except a "starter" field buried in settings, after being told "no typing". (`06-how-scoring.jpg`, `38-settings.jpg`)
- **SK-24 · P2 · onboarding** — The five "How it works" guides sit at the bottom of the You tab. (`21-you-full.jpg`)
- **SK-25 · P3 · gameplay** — Match-play results "2 UP THRU 3 · $5" declared a win while flagged red as incomplete. (`45-matchplay2.jpg`)
- **SK-26 · P3 · retention** — Feed shows gross scores only; no points, no table movement. (`09-home-full.jpg`)
- **SK-27 · P3 · comprehension** — "No league yet?" copy shown to a league member on the post form. (`28-post-form.jpg`)
- **SK-28 · P2 · onboarding** — Sign-in email says nothing about the league; identical subjects thread 20+ codes together in Gmail; ~3.5 min to sign in. (Gmail thread `1a04394290f11a7c`, `04-after-go.jpg`)
- **SK-29 · P3 · visual-hierarchy** — "Broke 100" trophy for a 91 by a 15-index; "Cups & events: 1 played in" pre-season. (`21-you-full.jpg`)
- **SK-30 · P3 · navigation** — Join-link door keeps "Continue with email" / "I have an invite code" buttons above the already-revealed email box. (`03-join-link.jpg`)
- **SK-31 · P3 · gameplay** — 502 on post; `[live-resume] server query failed` on every load; "Your unposted round came back" toast on a fresh session. (console)
- **SK-32 · P2 · comprehension** — Notification toggles read ON while "Enable on this device" is unpressed. (`47-settings-6.jpg`)
- **SK-33 · P3 · comprehension** — Standings column "R" unlabeled; "Avg vs index —". (`11-league-room-full.jpg`)
- **SK-34 · P2 · terminology** — "Card" means five different things (your card, on the card, scorecard, settlement card, Post card). (multiple)
- **SK-35 · P2 · retention** — The differentiating loop (round → table movement → needle → floor → final) is invisible pre-season; what's visible duplicates group text + spreadsheet + Venmo. (whole session)
