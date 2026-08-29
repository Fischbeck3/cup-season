# Blind UX audit — Agent 1, Casual Golfer ("Jordan Reyes")

**Persona:** Jordan Reyes, Mesa AZ. Plays 10–20 rounds a year, shoots ~95–100, no official handicap, home course Dobson Ranch. Never been in a formal league; fuzzy on what a "handicap index" is.
**Account:** jerecho+blind3@fischbeck3.com · handle @jordan · display name "Jordan"
**League joined:** The Papago Grind (code THEPTCQ5, organizer "Casey · THE PRO")
**Session:** harness session `cas`, iPhone viewport, app at http://127.0.0.1:8791/
**Screenshots:** `../screenshots/cas/` (all paths below are relative to that folder)
**Key question:** *Can a normal golfer understand this without becoming a golf-league nerd?*

> Important caveat on method. This account had an earlier, interrupted run of the same persona about an hour before (harness screenshots `01-A01-cold-door.jpg` … `65-J02-share-invite.jpg`, sign-up code email to my address at 14:14:18Z). When my browser session opened at 15:21Z the app was **already signed in**, already a member, and already had a 97 posted. To run Journey A honestly I found Sign out through the app's own UI, did the cold discovery signed out, then signed back in. Sign-up screens (golfer card) could not be re-seen on an existing account, so for that step I cite the earlier run's screenshots of this same account. Everything else below is my own fresh pass.

---

## 1. Timeline (UTC, 2026-08-29)

| Time | What happened | Evidence |
|---|---|---|
| 15:21:26 | Session started. App opened **already signed in** on Home ("The Papago Grind · forming"), plus a toast "Your unposted round came back — it's waiting in Post a round". | `01-door.jpg` |
| 15:22 | Tapped the **You** tab from Home → landed on "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE / Review the bylaws, then lock it in" with a button "Lock the bylaws & form the squads". (Reproduced 3/3 later, see issue A1.) | `02-R01-you-tab.jpg` |
| 15:23 | Tapped You again (from that screen) → real You tab. Found ⚙ → "Card & settings" sheet (Your card / Settings). | `03-R02-you-tab.jpg`, `04-R03-settings.jpg`, `05-R03b-card-full.jpg`, `08-R04-settings-tab.jpg` |
| 15:25:50 | Settings → **Sign out**. Cold door. | `09-R05-after-signout.jpg` |
| 15:25–15:26 | **Journey A** answered from the cold door (section 2). | `09-R05-after-signout.jpg`, `10-A01-door-scrolled.jpg` |
| 15:26:26 | Opened the invite link `http://127.0.0.1:8791/?join=THEPTCQ5` signed out. | `11-A02-join-link-cold.jpg` |
| 15:26:47 | Typed email, pressed **Go**. | `12-B01-after-go.jpg` |
| 15:26:50 | Code email actually arrived (3 s). My mail tool's thread cap hid it, so at 15:27:57 I pressed **Resend code**; second email at 15:27:58. | Gmail thread `1a04394290f11a7c`, `13-B02-after-resend.jpg` |
| 15:28:57 | Typed the 8-digit code; it **auto-submitted** without pressing Verify. Signed in ~15:29:00. "Welcome to The Papago Grind · THREE THINGS TO KNOW" sheet. | `14-B03-after-verify.jpg`, `15-B03b-welcome-full.jpg` |
| 15:29 | Tapped "How scoring works →" from the welcome sheet. | `16-C01-how-scoring.jpg`, `17-C01b-how-scoring-full.jpg` |
| 15:30 | Home, signed in. | `18-C02-home.jpg`, `19-C02b-home-full.jpg` |
| 15:30:32 | Clubhouse: Standings, "See the squads", Pot, League, Schedule, Board, Album, Members & invites. | `20`–`36` |
| 15:35 | Pot → tapped my own buy-in row → toast "The Pro marks buy-ins as money moves between you". | `37-E03-pot-after-tap.jpg` |
| 15:36:24 | Pot → "Post a stake" → posted "Loser buys the beers · Jordan vs Casey". | `38-E04-post-stake.jpg`, `40-E06-stake-posted.jpg` |
| 15:37:18 | ⊕ button → "GOLF · BEFORE, DURING AND AFTER THE ROUND" menu. | `41-F01-plus-menu.jpg` |
| 15:37:50 | "Post a round — after you play" form. Answered Journey D questions 1–9 from the UI (section 5). | `42-F02-post-form.jpg` |
| 15:38–15:42 | Course search "Ken McDonald" → picked the course → tee list; typed 49/48 **before** picking a tee: tee list vanished, Rating/Slope stayed blank, preview said **"-79.0 vs your index"**. Re-did search, picked White (68.7/115): preview "5 pts · Rough one · -9.8 vs your index". Tapping -9.8 did nothing. | `44`, `46`, `48-F06-scores-entered.jpg`, `51-F08-tee-white-picked.jpg`, `52-F09-tap-vsindex.jpg` |
| 15:43:10–15:43:17 | **Post round** (7 s). Sheet: "97 · 9.8 over your number · COUNTS ON YOUR CARD". Console: three `502` resource errors. "Share the card" → toast "Card downloaded". | `53-G01-after-post.jpg`, `54-G02-share-card.jpg` |
| 15:44 | Tapped my new round on Home → receipt: "97 − 68.7 × 113 ⁄ 115 = 27.8 DIFFERENTIAL · Your number that day 27.8 · Against your number +0.0 — PLAYED TO IT". | `56-G04-round-receipt.jpg` |
| 15:45 | Clubhouse Standings: everyone still **0 R · 0 Pts** including me. You tab: "2 of 3 Handicap index", Lifetime rounds 2, **This season · Rounds posted 0**. | `57-H01-standings-after.jpg`, `58-H02-you-after.jpg` |
| 15:46 | You tab → tapped the tiny ✕ next to the Ken McDonald round. Native browser confirm ("Delete this round? It leaves your card and any league standings it counted toward.") — my harness auto-accepted it. Round deleted, toast "Round deleted". | `61-H05-tap-x.jpg`, console `[dialog:confirm]` |
| 15:47–15:49 | Read all five "How it works" cards. | `62`–`67-H07-hiw2.jpg` |
| 15:49 | ⊕ → "Play now — score the group live" → Set up the round; tapped each game chip. | `68-I01-live-start.jpg`, `69-I02-games.jpg` |
| 15:50–15:51:24 | Papago · White, added Casey, Match play, $5 a side → "Tee off →" (6 s). Live screen, hole 1. | `70-I03-setup-done.jpg`, `71-I04-live.jpg` |
| 15:52 | Scored hole 1 (my stepper registered 5; Casey's taps did not register), "Group phones" sheet, hole 2, "Finish round & post to season" → "Finish the round" sheet. | `72`, `73-I06-group-phones.jpg`, `75-I08-finish-attempt.jpg` |
| 15:53–15:54 | **"Scrap this round" does nothing** — Playwright click, JS click, no confirm, no state change, no console error (`#discardBtn`). | `76-I09-scrap.jpg`, `77-I10-after-scrap.jpg`, `93-L03-scrap-test.jpg` |
| 15:55 | ⊕ → "Plan a tee time — before" → posted Sat Sep 5 · Papago · tagged Casey → toast "On the tee sheet: your group is named on the boards". | `78-J01-plan-tee.jpg`, `81-J02-tee-posted.jpg` |
| 15:56 | Clubhouse "Share the invite link" → only a toast **"Invite code: THEPTCQ5"**. Magnifier → "Find golfers" sheet. | `82-J03-share-invite.jpg`, `83-J04-find-golfers.jpg` |
| 15:57 | Board now shows "Priya took 7 skins and $60 · Priya 7, Casey 3, Marcus 6 · $5 a skin"; Home feed shows **"You · Played to your number · 103 gross · Papago · Blue"** — a round I never entered. "Start an event" sheet peeked. | `85-K02-start-event.jpg`, `86-K03-103-receipt.jpg`, `87-K04-scorecard.jpg` |
| 15:58 | Schedule → Sep: "You SAT SEP 5 · PAPAGO GOLF COURSE · WITH CASEY · 'Opening day — who's in?' · 7 DAYS". | `89-K06-schedule-sep.jpg` |
| 15:59 | Reproduced: Home → You = league wizard (3/3); Clubhouse → You = real You tab. | `90-K07-home-then-you.jpg` |
| 16:00 | ⊕ → Play now resumes the abandoned live round; Home never shows the promised "Continue your round" banner (console: `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'`). Session stopped 16:01. | `91-L01-play-now-again.jpg`, `92-L02-final-home.jpg` |

---

## 2. Journey A — Discovery (signed out, cold)

Screen: `09-R05-after-signout.jpg` (identical to the earlier cold open `01-A01-cold-door.jpg`). Nothing below the fold (`10-A01-door-scrolled.jpg`).

Exact copy on the door: orange flag icon · **CUP SEASON** · "Rally your crew. Post real rounds. *Take the cup.*" · [Continue with email] · [I have an invite code] · "By continuing you agree to the Terms & Privacy Policy." · "v23 · __CS_VERSION__".

**3 seconds:** a golf-ish flag, the name, three punchy lines, two buttons. It's a golf thing for a group ("crew"), you post scores, there's a cup to win.
**10 seconds:** "Post real rounds" tells me I type in scores from actual golf, not a video game. "Take the cup" says somebody wins something. No idea how, how long, or whether money is involved.
**30 seconds:** The only things I can *do* are sign in with email or enter an invite code. There is no "how it works", no screenshots, no preview. I would not tap Terms/Privacy (nobody does); I noticed the raw "__CS_VERSION__" string, which looks like a bug to a normal person.

Honest first answers:
1. **What does the app do?** Lets a group of golf friends compete against each other over some stretch of time by posting their real scores; someone "takes the cup".
2. **Primary action?** "Continue with email" (sign up / sign in). Secondary: "I have an invite code".
3. **What is a "season"?** Not defined anywhere on the door. Guess: a few months during which your rounds count.
4. **What is a "league"?** The word doesn't appear on the door. Guess: your group of friends.
5. **What is a "cup"?** The trophy/prize for winning. Real trophy, cash, or bragging rights — unknown.
6. **Competing for?** "The cup". Money isn't mentioned.
7. **Against whom?** "Your crew" — friends.
8. **How do rounds work?** "Post real rounds" — you enter scores after you play. How, and whether anyone checks, unknown.
9. **After a round?** Unknown. Presumably a leaderboard moves.
10. **Different from just playing with friends?** Apparently a running tally and a cup at the end. That is all the door says.

**Invite link, cold** (`11-A02-join-link-cold.jpg`): the same door plus an email box and the line "You're invited to The Papago Grind. Enter your email and you're in." The URL is rewritten to `/` immediately. Nothing about who invited me, when it starts, or that it costs $50. Both "Continue with email" and "I have an invite code" buttons stay on screen above the email box, which made me wonder whether I still needed to press one of them.

**Invitation email:** searched Gmail for "Cup Season" newer_than:6h — there was **no invitation email addressed to me**. The only invitation-style email in the inbox was "Priya wants in your crew" sent to a different tester (blind1). My invitation existed only as the text-message link/code.

---

## 3. Sign-up / sign-in

- Door → email → **Go** → "Sent to jerecho+blind3@fischbeck3.com. Type the sign-in code from the newest email." with a "Resend code (26s)" countdown (`12-B01-after-go.jpg`). The code box placeholder is "CODE FROM EMAIL". Real latency was ~3 s (email timestamps 15:26:47 → 15:26:50). The code auto-submitted on the 8th digit — the Verify button never needed pressing. Nice, but nothing on screen says it will do that.
- Subject lines were "Confirm your email address" (first-ever) and "Your Cup Season sign-in code" (returning). Body: "Your sign-in code: 17178101. Type it on the sign-in screen. The code expires in an hour."

**Golfer card (from the earlier run of this same account, `05-B03-golfer-card-full.jpg`, `06-B04-card-scroll1.jpg`, `08-B06-ghin-tapped.jpg`):**
"✓ SIGNED IN · Set up your **golfer card.** Just a name and a marker to start — this card follows you into every league."
- NAME ON THE CARD ("First name or nickname") — clear.
- YOUR HANDLE — HOW BUDDIES FIND YOU, prefilled "@jerechoblind3", "A starting handle — tap to change it." — fine, though "buddies" is a new concept already.
- HANDICAP INDEX · OPTIONAL, placeholder "e.g. 12.4", help: "Know your index? Enter it as a starting point — otherwise your first three rounds set it, and it keeps adjusting as you play." **What I did as Jordan: left it blank.** I don't have an index. I shoot around 95–100; I honestly didn't know if I should type "25" or nothing. The help text saved me — "otherwise your first three rounds set it" — that is the single best sentence in onboarding.
- "+ Add your GHIN number" → "GHIN # · e.g. 1234567 — Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." I don't know what GHIN is. "That's identity, not your number" is confusing to someone who doesn't know either term. Left blank.
- BALL MARKER: 14 tiles (THE SAGUARO, THE ISLAND, THE LIGHTHOUSE, THE LONE TREE, THE PEWS, THE DUNES, THE BEVERAGE, THE SHARK, THE AZALEA, THE JUG, THE WEE BRIDGE, NO. 2, THE POSTAGE STAMP, THE THISTLE). No explanation of what a marker is for (it's your avatar). Picked THE SAGUARO because Arizona. Fun, but I had to guess its purpose.
- "City and home course live on your card — add them any time from the You tab." then **Save my card**.
- After save: "Four places. Two ways to play. Thirty seconds, then you're in." — Home / Clubhouse / The ⊕ / You, and "THE LONG GAME · A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE." vs "THE SHORT GAME · An event · A WEEKEND OR A FEW WEEKS. ITS OWN LITTLE TROPHY." → **Take me in** (`10-B08-after-save.jpg`). This is the first time "league" and "season-ish" are defined. Good screen; it comes *after* I've committed.

**Before joining any league (earlier run, same account):** "Before you join The Papago Grind · THE FINE PRINT, UP FRONT: BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks. Joining puts you on the pot sheet for $50. Cup Season keeps the tab; money moves between you. [Join — I'm in for $50] [Not now]" (`11-C01-after-take-me-in.jpg`). This is the **first mention of money**, after account creation. "Not now" → league-less Home: "Post a round — it counts on your card. Leagues score it when you join one. YOUR CARD · Three rounds and your index goes live. Nothing else needed. INDEX 0 OF 3 [Post your first round] · LEAGUE None yet · NEXT Open · BOARD — LEAGUE ONLY" and, oddly, **"Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points…"** even with no league (`12-C02-not-now-home.jpg`). Clubhouse with no league = four buttons (Start a league / I have an invite code / Add golfers / Sign out) (`13-C03-clubhouse-noleague.jpg`). So what the app offers a golfer with no league is: post rounds to build an index, add buddies, plan tee times. It's stated ("it counts on your card"), but "card" is doing a lot of work for a word nobody defined.

**Settings (this run, `08-R04-settings-tab.jpg`):** Notifications (Enable on this device, Round pings ON, Chat pings ON, Season email ON), Appearance (Charcoal / Light / Match device), "Membership & billing · PLAN FREE · PILOT · Cup Season membership lands at launch. Nothing to pay during the pilot.", Sign out, Danger zone → Delete my account, Privacy · Terms · Prize pool.

---

## 4. Joining / after joining

Signing in through the invite link → "Welcome to The Papago Grind · THREE THINGS TO KNOW" (`15-B03b-welcome-full.jpg`):
1. "**You're on the pot sheet: $50 buy-in.** The Pro tracks who's paid; money moves between you."
2. "**You can't hurt your squad by playing badly.** Only by not playing. Every posted round scores — a rough day is still points on the board."
3. "**Rounds score against your own number.** Beat your handicap and it's a big day, whatever you shot. Your best rounds each month count; a better round always bumps your worst."
4. "**The pot lives on the books.** Cup Season keeps the tab and shows who owes what; money moves between you."
"How scoring works →" · "Who else plays with you? Growing the league isn't the Pro's chore — any member's link works." · [Share the invite link]

USER ASSUMPTION: "three things" means three. ACTUAL: four paragraphs.
USER ASSUMPTION: "The Pro" is a golf pro at a course. ACTUAL (learned in Clubhouse): it's the league organizer, Casey.
USER ASSUMPTION: "squad" = the whole league. ACTUAL: the league is split into 2 squads by a blind draw; I'm not in one yet.
USER ASSUMPTION: "your own number" = my score. ACTUAL: my handicap index, which I don't have yet.

Money: I owe $50 to somebody, somehow. Nothing says how to pay, to whom, or by when. The Pot tab later says "$0 collected · 5 still owe" and the rows look like checkboxes I can tick — I tried, and got "The Pro marks buy-ins as money moves between you" (`37-E03-pot-after-tap.jpg`). So: pay Casey cash/Venmo and hope he ticks the box.

**"What do I do now?"** — Not obvious. Home (`19-C02b-home-full.jpg`) leads with a hero card "THE PAPAGO GRIND · FORMING · **7 days** to first tee. 5 golfers in. The bylaws lock at the tee." and a big orange **"Lock it in and invite your crew"**. As a player, that reads as an instruction to me, and it opens a league-creation wizard ending in "Lock the bylaws & form the squads" — which I obviously must not press. Below: "LEAGUE The Papag… OPEN THE ROOM · NEXT Open PLAN A ROUND · BOARD 6 NEW TODAY", then "MONTH CLOSES in 2 days" and the monthly-floor warning. The season hasn't started, yet a month is "closing" in 2 days and I'm warned about losing 5 points. The honest answer to "what do I do now" from the UI is "wait 7 days", but the UI never says that; it shouts "Lock it in" and "Month closes".

---

## 5. Journey D — First (well, second) round

Answered from `42-F02-post-form.jpg` **before** typing anything:
1. **How do I know what round I'm playing?** I don't — there's no notion of "the round you're supposed to play". You just post any round you played. Whether it counts for the season (which starts Sep 5) is not stated.
2. **Who am I playing?** Nobody. This is me alone with my gross score.
3. **What format?** Stroke play, front nine + back nine gross. "18 holes / 9 holes" toggle.
4. **What are the rules?** The "POINT BANDS" box: Beat your index by 3+ = 12, Beat it by 1–3 = 9, Within a stroke either way = 7, Over by 1–3 = 6, Rough day, posted anyway = 5. "Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time."
5. **How are handicaps applied?** "vs your index" — but I have no index (You tab says "1 of 3"). What happens then is not said.
6. **What do I need to enter?** Course (search), tee, Rating and Slope (numbers I have never typed in my life — the placeholders 72.1 / 128 looked filled in), Front 9 gross, Back 9 gross, Date; optional "Scan the card" / "Add a photo".
7. **What counts toward the season?** "Your best 4 each month count toward your squad." Nothing about the season not having started.
8. **What counts toward side games?** Nothing on this form.
9. **If something goes wrong?** "Start over — clear this card" before posting. After posting: nothing on the form or the receipt; I later found a tiny ✕ on the You tab that deletes a round.

Posting (front 49, back 48 at Ken McDonald, White):
- Typing "Ken McDonald" → hit "Ken Mcdonald Golf Course · Tempe, AZ · 7 tees" → tee list (Tips 72.3/127 … White 68.7/115 …) (`46-F04-course-picked.jpg`). Because I typed my nines first, the tee list vanished, Rating/Slope stayed empty, and the preview read **"League points this round 5 · Rough one, but posted rounds always score · 97 GROSS · -79.0 VS YOUR INDEX"** in red (`48-F06-scores-entered.jpg`). "Post round" was still enabled. Took me 4 attempts to get the course + tee picked so Rating/Slope filled (68.7 / 115). Toast: "Tees set — rating and slope filled".
- With tee set, preview: "5 · Rough one, but posted rounds always score · 97 · **-9.8** vs your index" (`51-F08-tee-white-picked.jpg`). Tapping the -9.8 did nothing.
- Also on the form while I *am* in a league: "No league yet? The round still counts on your card — points apply in any league you join."
- **Post round** → 7 s → sheet "KEN MCDONALD GOLF COURSE · WHITE · SAT AUG 29 · **97** · **9.8 over your number** · COUNTS ON YOUR CARD · [Share the card] [Back to the board]" (`53-G01-after-post.jpg`). No points, no standings movement, no "this is pre-season". Console logged three 502s during the post. "Share the card" → "Card downloaded".
- Receipt (`56-G04-round-receipt.jpg`): "97 gross · The course 68.7 / 115 · 97 − 68.7 × 113 ⁄ 115 = **27.8 DIFFERENTIAL** · YOUR NUMBER THAT DAY 27.8 · Against your number **+0.0 — PLAYED TO IT**".

10. **Do I understand whether I won or lost / what I earned?** No. The same round was described three ways in four minutes: "-9.8 vs your index" (form, red, minus sign), "9.8 over your number" (posted card), "+0.0 — PLAYED TO IT" (receipt). The preview promised "League points this round 5"; the Standings then showed me at 0 rounds / 0 points and the You tab said "This season · Rounds posted 0". So I earned… nothing, and nothing told me why.

**Verbatim — what I'd tell a friend right after posting:**
> "I typed in my 49 and 48 at Ken McDonald and it said I got 5 points for a rough day, and that I was minus 9.8 against my index, which I don't have. Then the card said I was 9.8 *over* my number, and the receipt said I played *to* my number, plus zero. The standings still say I have zero rounds and zero points. So I think it went on my 'card' but not in the league, maybe because the league starts next Saturday? It didn't say."

**What my round did to the standings, in plain language (verbatim):**
> "Nothing. Everyone in The Papago Grind is on 0 rounds and 0 points, me included, before and after. My guess is rounds before Sep 5 don't count, but the app told me 'League points this round: 5' and then didn't give me any."

Deleting the round: on the You tab each recent round has a tiny ✕ ("Delete this round"). A native browser confirm appears: "Delete this round? It leaves your card and any league standings it counted toward." After that: toast "Round deleted", no undo (`61-H05-tap-x.jpg`). There is no delete/fix on the receipt or the posted card, where a person would look first.

**Bonus — a round I never played appeared on my card.** At 15:57 the Home feed showed "**You** · Played to your number · **103** gross · Papago Golf Course · Blue · Aug 29". Receipt: "…28.0 DIFFERENTIAL · Your number that day 28.0 · Against your number +0.0 — PLAYED TO IT · Attested PLAYED WITH THE GROUP · Played with Casey, Marcus, Priya · [See the scorecard]" (`86-K03-103-receipt.jpg`, `87-K04-scorecard.jpg` shows a full hole-by-hole 51/52). Another member had run a live skins game, put "Jordan" in the foursome, and finished it. I got no notification, no "confirm this was you", and my index counter moved. To a casual golfer this is alarming: someone else can put a 103 on my record.

---

## 6. Side game audit

**Discoverability:** Side games are not mentioned on Home's hero, in the welcome sheet, or in How scoring works. I found them (a) as feed items — "Match play: Priya def. Casey 2 UP THRU 3 · $5 on the line · SCORECARD ›", "Priya took 7 skins and $60"; (b) behind the ⊕ → "LIVE · Play now — score the group live · Hole-by-hole · match play, Wolf & the settle-up…" (`41-F01-plus-menu.jpg`); (c) in the Pot tab as "THE OTHER STAKES · PRIDE, ON THE BOOKS · [Post a stake]". So: discoverable if you explore, not surfaced.

**What I think they are:** bets between people in the same foursome, tracked hole-by-hole on one phone while you play, with a dollar amount that "settles between you" (the app doesn't move money).

**The list (from "Set up the round", `68-I01-live-start.jpg`, `69-I02-games.jpg`):**
- **Just score** — "Stroke play — your card, your pace. One to four players; post when you're done."
- **Match play** — "Singles (2) or 2v2 net best ball (4). Keep scoring; we tally the match as you go." + "Stake per side · $0 = bragging rights".
- **Wolf** — "A round of Wolf — needs four. We run the rotation and the side tally; scores still post." + "Dollars per point". I don't know how Wolf is played and the app doesn't say.
- **Skins** — "Low net takes the hole's skin; ties carry the pot. Two to four players; scores still post." + "Dollars per skin". Roughly understandable.
- **Sunningdale Rules** — "Match play, no handicaps — go 2 down and you get a stroke until you climb out. Singles or 2v2. Win a hole while ahead to bank a unit." + "Bank unit". Never heard of it; the sentence helps a little.

**Setting one up (did it):** picked Papago · White (search results listed "Papago Golf Course · Phoenix, AZ · 13 tees" **twice**), tapped "Casey · 14.2", chose Match play, typed $5. The app said "Jordan vs Casey · Strokes off the low man (Casey): Jordan gets 4: holes 3, 6, 16, 18" — I was given "EST 18.0 IDX" out of nowhere (I have no index; 18 is apparently a default) and that estimate decided the strokes. "Tee off →" took 6 s → live screen: "ALL SQUARE · Jordan — / Casey — · HOLE 1 · PAR 5 · SI 15 · [−] – [+] steppers · Group phones — everyone can score · Finish round & post to season · Scrap this round · SIDE GAMES · TRACKED LIVE, SETTLED BETWEEN YOU · MATCH PLAY · SINGLES · JORDAN VS CASEY · ALL SQUARE · THRU 0 · STROKES OFF LOW MAN (CASEY) · $5 A SIDE" (`71-I04-live.jpg`).
- Scoring: my stepper worked ("5 THRU 1 · +0"); Casey's + taps in the same burst did not register (harness timing, low confidence as a product bug).
- "Group phones" sheet: "League members just open the app — a Continue your round banner is waiting on Home. Any phone can fix any score; the newest edit wins. No guests in this round." **The banner never appeared on Home** (console: live-resume server query failed). The round *is* resumable via ⊕ → Play now.
- "Finish round & post to season" with 1 hole filled → sheet "ONE FINISH — EVERY MEMBER'S CARD POSTS … Jordan — missing holes 2, 3, 4, 5, 6 +12 more · Casey — missing holes 1, 2, 3, 4, 5 +13 more. Those cards won't post — go back and fill in, or finish without." with two buttons **"Finish — no complete member card to post"** and **"This one was casual — post nothing"** — I genuinely cannot tell the difference (`75-I08-finish-attempt.jpg`).
- **"Scrap this round" is dead.** Tapped it three ways; nothing happens, no confirm, no toast (`93-L03-scrap-test.jpg`). The half-started match vs Casey is still sitting there.

**Pride stakes (Pot tab):** "Post a stake · PRIDE, ON THE BOOKS — NEVER MONEY · Name it (The Lawn Bet) · The shape: Loser hosts / Winner picks the course / Strokes next time / Standing bounty / Name your own · The terms (prefilled 'Loser hosts the cookout') · Against: The field — first to hit it / Priya / Sam / Casey / Marcus · Rides on (optional) · [Put it on the books] · Stakes settle on a party's tap and archive into the record. The pot stays money; this never is." I posted "Loser buys the beers" vs Casey; the card came out "Loser buys the beers · Jordan vs Casey · **Loser hosts the cookout** · rides on First round of the season · [Settle] [✕]" because the prefilled terms stayed. Toast "Stake posted — the board heard it" and it did show on the Board (`40-E06-stake-posted.jpg`). Fun, social, low-stakes. But "Settle" is a button I can press by myself on a bet with Casey — who wins?

**Do they affect the season?** As far as the UI says: no. "Scores still post" / "every complete card posts at the finish" means the *gross score* from a live game goes onto your card (and therefore the season); the match/skins result itself is only "settled between you" and posted to the board. That relationship is never spelled out in one sentence.
**Would they make a round matter when out of contention?** Yes — a $5 skins game is a reason to care on hole 14 in December. That's the best part of the app for someone like me.
**Social interaction?** Yes: feed items with scorecards, chat on the Board ("Casey you owe me a beer"), reactions 🔥 ⚑, stakes.
**Integrated or bolted on?** Half and half. The live game is well integrated at the moment of play (one screen, strokes computed, settlement text). But nothing on Home, the welcome sheet or the how-scoring sheet ever says "side games exist"; the live door is one of three items behind a plus button; and the Home hero is about locking bylaws.
**Does the app encourage setting one up?** Mildly: "Play now" is first in the ⊕ list with a LIVE dot; the tee-sheet post tags players. Nothing on the Home hero.
**Friction:** course + tee must be re-picked (no "use my last course"); dead Scrap; ambiguous finish buttons; estimated index silently assigned; duplicate course results; the game rules are one sentence each with no "how do I play Wolf?".

---

## 7. Would I open this between rounds?

- **Yes, a little**, for the feed: "Priya broke 80", "Sam 91 at Papago. Casey you owe me a beer", skins results with scorecards. That's the group chat I already have, with numbers attached. The "MONTH CLOSES in 2 days / lose 5 points" banner is the opposite of a reason to open it; it's a reason to feel guilty.
- **Does anything make me want to play my next round?** The tee sheet ("You SAT SEP 5 · PAPAGO · WITH CASEY · 7 DAYS") and the monthly floor (fear). The points table doesn't, because I don't understand it yet and it's all zeros.
- **Would I send a screen to the group?** The posted-round card ("97 · 9.8 over your number") — no, it makes me look bad and the sentence is odd. The skins scorecard — yes. The "Share the invite link" button only gave me a toast "Invite code: THEPTCQ5", so I couldn't actually send the link anywhere from the app.

---

## 8. Journey A re-answered at the end (what changed)

1. **What does the app do?** A season-long points competition for a golf group: each posted round is scored against your own handicap into 5–12 points, best 4 per month count for your *squad*, plus live side games (match play/skins/Wolf) and a tracked money pot. *(Changed: now I know it's squads, monthly, points-by-band.)*
2. **Primary action?** Post a round after you play (⊕). *(Changed from "sign up".)*
3. **Season?** A fixed window — here Sat Sep 5 → Sat Jan 2, 17 weeks, 4 months, with the last 4 weeks a "Cup Final · scored fresh" whatever that means. *(Changed: it has dates; still don't know what "scored fresh" does.)*
4. **League?** A named group (The Papago Grind) with a code, an organizer ("the Pro"), bylaws, a pot and 2 squads. *(Changed.)*
5. **Cup?** Still unclear. "Cup champs" get $150 of the $250 pot; there is a "Cup Final · final 4 weeks". Is the cup the squad prize or the season? *(Not resolved.)*
6. **Competing for?** $250 pot: $150 Cup champs / $63 Runner-up / $38 Points king; trophies for a "display case". *(Changed: money.)*
7. **Against whom?** My squad vs the other squad (squad race) AND every individual (Points King / Most Improved / Iron Man). *(Changed.)*
8. **Rounds?** Post front/back gross + course/tee; the app computes a "differential" and a band (12/9/7/6/5). Or score live hole-by-hole with the group. *(Changed.)*
9. **After a round?** A card with gross and "X over your number", a receipt with a formula, a feed item. Points/standings did not move for me. *(Changed; still don't know when they will.)*
10. **Different from playing with friends?** Everything is written down: a table, a pot ledger, bets on the board, an index that builds from your scores. *(Changed.)*

---

## 9. 30-second explanation to a friend (verbatim)

> "It's an app for our golf group. Casey set up a 'league' for the fall — four months. Everybody chips in fifty bucks into a pot the app keeps track of, but you still pay Casey directly. It splits us into two squads by random draw. Every time you play, you type in your front and back nine and the app turns it into points — five to twelve — based on how you did against your own handicap, which it works out for you after three rounds, so a 97 from me can beat an 84 from Priya. Your best four rounds a month count for your squad, and if you don't post at least two a month your squad loses points. There's also a live scorecard thing where you can play match play or skins for five bucks while you're out there, and it posts the scores for you. At the end there's some kind of Cup Final and the pot gets split. I still don't totally get how the squad points and the individual points fit together, and I'm not sure my rounds this week even count."

---

## 10. Persona verdict

**Question:** Can a normal golfer understand this without becoming a golf-league nerd?
**Answer:** Halfway. Posting a score is genuinely easy once you find the ⊕ and don't touch the Rating/Slope boxes. Understanding what the score *did* is not: the same round was called -9.8, 9.8 over, and +0.0 played-to-it; my points were promised (5) and then not awarded, with no sentence saying "the season starts Sep 5". The vocabulary — the Pro, squad, pot sheet, bylaws, floor, counting cap, differential, Cup Final scored fresh, Points King, SI, net best ball, Sunningdale — is never defined where you meet it, and the biggest button on my Home is the organizer's job. I'd need Casey to explain half of it in the parking lot.
**Score: 4/10.**

| Score | 1–10 |
|---|---|
| conceptClear | 5 |
| setupClear | 5 |
| rulesClear | 3 |
| gameplayCompelling | 5 |
| easyToPickUp | 4 |
| stakesMeaningful | 6 |
| sideGamesCompelling | 6 |
| wouldInvite | 4 |
| wouldPay | 3 |
| wouldPlayAgain | 5 |

---

## 11. Glossary (what I *think* each term means; ✱ = still confusing)

| Term | Where seen | What I think it means |
|---|---|---|
| Season | League card "Sat Sep 5 → Sat Jan 2 · 17 wks" | The dated window when rounds count. |
| League | Everywhere | A named friend group with an organizer, rules, a pot, squads. |
| Cup ✱ | Door "Take the cup", Pot "$150 Cup champs", bylaws "CUP FINAL · Final 4 weeks · scored fresh" | The main prize; unclear whether it's the squad race or the whole season. |
| Cup Final · scored fresh ✱ | Bylaws | Last 4 weeks are a separate contest? "Scored fresh" undefined. |
| Squad ✱ | Welcome, Standings, Form squads | One of two teams the league is split into by blind draw. I'm in neither yet. |
| The Pro ✱ | Welcome, Members ("Casey · THE PRO") | The organizer. Sounds like a course professional. |
| Pot / pot sheet | Welcome, Pot tab | The $250 of buy-ins the app tracks but does not hold. |
| Buy-in | Fine print, Pot | $50 per player, paid to the Pro somehow. |
| Bylaws ✱ | Home hero, League tab | The league's rule settings; "lock at the tee" = fixed on first day. |
| Handicap index / "your number" ✱ | You tab "2 of 3", scoring sheet | A number computed from my last rounds; "builds at 3 rounds". |
| Rating / Slope ✱ | Post form | Course difficulty numbers the tee pick fills in. I would never know them myself. |
| Differential ✱ | Receipt "97 − 68.7 × 113 ⁄ 115 = 27.8" | Some course-adjusted score. Formula shown, meaning not. |
| Cup points / point bands | Post form, How scoring | 12/9/7/6/5 per round depending on how you did vs your number. |
| Counting cap · Best 4 / mo | Bylaws | Only your best 4 rounds per month count for the squad. |
| Participation floor / Monthly floor | Home, bylaws | Post ≥2 rounds a month or your squad loses 5 points per missing round. |
| Season bye ✱ | How scoring | First missed floor is forgiven, apparently. |
| Points King / Most Improved / Iron Man | Standings | Individual side prizes; Points King gets 15% of the pot. |
| Event ✱ | Home "Start an event", How it works | A short competition (weekend/few weeks) with its own trophy: The Ryder, A Major, Bracket (SOON). |
| The Ryder / A Major / Bracket ✱ | Start an event sheet | Event formats; only one line each. |
| Match play · 2 UP THRU 3 | Feed, live | Hole-by-hole win/loss vs one person; "2 up through 3 holes". |
| Skins | Feed, live | Low net score on a hole wins that hole's money; ties carry over. |
| Wolf ✱ | Live setup | A 4-player game with a rotation; not explained. |
| Sunningdale Rules ✱ | Live setup | A match-play variant; one sentence. |
| Net best ball ✱ | Match play description | 2v2 format; undefined. |
| Strokes off the low man ✱ | Live setup | The better player gives strokes to the worse on listed holes. |
| SI ✱ | Live hole header "PAR 5 · SI 15" | Stroke index? Undefined. |
| EST 18.0 IDX ✱ | Live setup | An index the app guessed for me. |
| Attested ✱ | Bylaws "VERIFICATION Attested", receipt | Scores are trusted because the group entered them together. |
| Handicap allowance 95% ✱ | Bylaws | Undefined. |
| Stake (pride) | Pot tab | A non-money bet written on the board. |
| Tee sheet | ⊕, Schedule | A shared calendar of planned rounds. |
| The Board | Clubhouse tab | The league's feed + chat. |
| Clubhouse | Nav | One league's room. |
| The ⊕ | Nav / How it works | The plus button: post / play live / plan. |
| Buddies | You tab, search | Mutual follows; see each other's rounds; unrelated to leagues. |
| Invite link vs claim link ✱ | How it works | Invite = join league; claim = give a guest their round. |
| Marker / ball marker | Golfer card, "Marker here" | Your avatar icon. "Marker here" button in Members unclear. |
| Handle | Card | @name. |
| GHIN ✱ | Card | Some official golf ID; "identity, not your number". |
| Pro Shop | League tab | Paid features "coming at launch". |
| Card ("your card") ✱ | Everywhere ("counts on your card") | My profile/record? Also a scorecard. Two meanings. |
| Crew-policed ✱ | Settings index text | The league sees manual index changes. |

---

## 12. Confusion debt (things the app assumes I already know)

1. What a handicap index is, that it can be "built", and that a score is judged against it rather than par.
2. What course Rating and Slope are, and that the tee choice supplies them.
3. What a "differential" is and why 113 appears in a formula.
4. That the league is split into squads, that squad points ≠ my points, and that I'll be drawn into one later.
5. That "the Pro" is a person in my group, not a golf professional.
6. That rounds posted before the season's first tee don't count (never stated; inferred from zeros).
7. What "bylaws lock at the tee" means and that it is not my job.
8. What "Cup Final · scored fresh" means for the standings.
9. How to actually pay the $50 and who confirms it.
10. What Wolf, Sunningdale Rules, net best ball, skins carry-over and "strokes off the low man" are.
11. That "SI" is a stroke index and which holes I get strokes on, and why.
12. That the app will estimate my index as 18.0 in live games.
13. That any league member can add me to a live round and post a score to my card.
14. That "card" means my profile/record in "counts on your card" but the scorecard in "Scan the card".
15. That the "Continue your round" banner exists (it doesn't appear) and that ⊕ → Play now resumes a round.
16. That a month "closes" and floors apply even though the season hasn't started.
17. What an "event", "The Ryder", "A Major" are relative to my league.
18. What GHIN is.
19. Why my second round is labelled "First round on the card" and my first became "Personal best".
20. What "Marker here" does in the Members list.

---

## 13. USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR pairs (collected)

- **UA:** The door will tell me what a season is / what I win. **APB:** Only "Rally your crew. Post real rounds. Take the cup."
- **UA:** Opening Casey's link = joined. **APB:** Door + "Enter your email and you're in"; the $50 fine print and covenant come after sign-in.
- **UA:** "THREE THINGS TO KNOW" = three. **APB:** Four.
- **UA:** "Lock it in and invite your crew" is something I should do. **APB:** It opens the league-creation wizard's final "Lock the bylaws & form the squads" step; I'm a PLAYER.
- **UA:** Tapping the YOU tab opens my profile. **APB:** From Home it opens the league wizard (3/3); from Clubhouse it opens my profile.
- **UA:** "Month closes in 2 days" means I need 2 rounds in the next 2 days. **APB:** Unknown; season hasn't started.
- **UA:** Rating 72.1 / Slope 128 are filled in. **APB:** Placeholders; blank until a tee is picked; the form computed "-79.0 vs your index" with them blank.
- **UA:** "-9.8 vs your index" means I was 9.8 *better* (minus = good in golf). **APB:** Posted card says "9.8 over your number"; receipt says "+0.0 — PLAYED TO IT".
- **UA:** "League points this round 5" = I will get 5 points. **APB:** Standings 0 R / 0 Pts; You tab "This season · Rounds posted 0".
- **UA:** "The board · rounds land here automatically" — my round will be on the league Board. **APB:** Board showed joins, match plays and chat; my round only on Home's feed.
- **UA:** The Pot checkboxes are for me to tick when I've paid. **APB:** "The Pro marks buy-ins as money moves between you."
- **UA:** "Squads LIVE NOW — CAPTAINS READY" means squads are set. **APB:** "Squads are forming · The Pro has the list"; both squads "Empty".
- **UA:** "See the squads" is a sheet I can close. **APB:** Full screen with no back control; tapping squads/names does nothing.
- **UA:** "Schedule" is a Clubhouse tab like the others. **APB:** Navigates to a separate "YOUR GOLF CALENDAR" page with "← HOME".
- **UA:** "Share the invite link" opens a share sheet with a link. **APB:** Toast "Invite code: THEPTCQ5".
- **UA:** "Scrap this round" abandons the live round (with a confirm). **APB:** Nothing happens.
- **UA:** "A Continue your round banner is waiting on Home." **APB:** No banner; console reports the live-resume query failing.
- **UA:** Only I can put scores on my card. **APB:** A 103 "Attested · PLAYED WITH THE GROUP" landed on my card from someone else's live game.
- **UA:** Deleting a round would be on the round's receipt. **APB:** Only a tiny ✕ on the You tab; native confirm; no undo.
- **UA:** "Finish — no complete member card to post" and "This one was casual — post nothing" do different things. **APB:** Unknown; I could not tell them apart.
- **UA:** My name in the stake ("Loser buys the beers") is the bet. **APB:** The prefilled "Loser hosts the cookout" terms were posted alongside it.

---

## 14. Issues

Format: ID · severity · category · screen — OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION · evidence.

**A1 · P1 · navigation · Home → You tab.** OBS: From Home, tapping the bottom-nav "You" button opened "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE / Review the bylaws, then lock it in … [Lock the bylaws & form the squads] [← Back]" three times out of three (15:22, 15:58, 15:59). From Clubhouse the same button opens my profile. INT: a stale wizard state is being restored, or the tab routes wrong when Home is active. IMPACT: a player is one tap from an organizer-only action and cannot reach their own profile from Home. REC: fix the route; never show the lock step to non-organizers. EV: `02-R01-you-tab.jpg`, `90-K07-home-then-you.jpg`, repro log 15:59.

**A2 · P1 · rules · Home hero.** OBS: As a PLAYER (Settings → "Your leagues · The Papago Grind PLAYER") the Home hero's only button is "Lock it in and invite your crew" with "The bylaws lock at the tee." INT: organizer CTA shown to everyone. IMPACT: I don't know what "locking" is, whether it's my job, or what I should actually do this week. REC: player-specific hero ("First tee Sat Sep 5 · squads drawn by Casey · post rounds from Sep 5"). EV: `19-C02b-home-full.jpg`.

**A3 · P1 · comprehension · Post form → standings.** OBS: Form preview "League points this round 5"; posted card "COUNTS ON YOUR CARD"; Standings 0 R / 0 Pts for me; You tab "This season · Rounds posted 0". Nothing says pre-season rounds don't count. INT: season starts Sep 5; rounds before it only feed the index. IMPACT: the first thing the app promised me (5 points) didn't happen and I had to infer why. REC: on the form and the posted card, say "Season starts Sat Sep 5 — this round builds your index, no league points yet." EV: `51-F08-tee-white-picked.jpg`, `53-G01-after-post.jpg`, `57-H01-standings-after.jpg`, `58-H02-you-after.jpg`.

**A4 · P1 · terminology · Post form / posted card / receipt.** OBS: One round: "-9.8 vs your index" (red, form), "9.8 over your number" (card), "Against your number +0.0 — PLAYED TO IT" (receipt). INT: the form compares to a provisional index, the receipt to a number recomputed after the round. IMPACT: three verdicts; sign convention flips; "PLAYED TO IT" for every early round. REC: one number, one sign convention, one label; with <3 rounds say "no number yet — building (2 of 3)". EV: `51-F08`, `53-G01`, `56-G04-round-receipt.jpg`.

**A5 · P1 · visual-hierarchy · Post form.** OBS: Rating/Slope placeholders "72.1 / 128" render like values; typing the nines closes the tee list; with blank rating/slope the preview shows "-79.0 vs your index" and Post round stays enabled. Took 4 attempts to get a tee selected. INT: tee selection is the only sane way to fill those, but nothing forces it. IMPACT: a casual golfer will post rounds with no rating/slope or be baffled by -79.0. REC: hide rating/slope until a tee is picked; require a tee; empty-state text instead of "-79.0". EV: `48-F06-scores-entered.jpg`, `42-F02-post-form.jpg`.

**A6 · P1 · gameplay · Live round.** OBS: "Scrap this round" (`#discardBtn`, enabled) does nothing on click — no confirm, no toast, no state change, no console error; tested via UI click and JS click. IMPACT: a wrong setup can't be abandoned; my half-started $5 match vs Casey persists. REC: wire the handler with a confirm. EV: `93-L03-scrap-test.jpg`, `77-I10-after-scrap.jpg`.

**A7 · P1 · social/gameplay · Home feed / receipt.** OBS: "You · Played to your number · 103 gross · Papago · Blue" appeared on my card from another member's skins game ("Attested · PLAYED WITH THE GROUP · Played with Casey, Marcus, Priya"); no notification, no confirmation; my index count moved. INT: group attestation by design. IMPACT: to a normal golfer, someone else just wrote a 103 on my record; trust and consent problem; no obvious way to dispute except the ✕ on the You tab. REC: notify + "That was me / That wasn't me" on rounds you didn't enter yourself. EV: `85-K02-start-event.jpg` (feed), `86-K03-103-receipt.jpg`, `87-K04-scorecard.jpg`.

**A8 · P1 · gameplay · Home / live resume.** OBS: "Group phones" sheet says "a Continue your round banner is waiting on Home"; no banner ever appeared; console: `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'`. Round is only resumable by ⊕ → Play now. IMPACT: on-course, the promised way back to the scorecard is missing. REC: fix the query; show the banner. EV: `73-I06-group-phones.jpg`, console log 15:21/15:29/15:59.

**A9 · P2 · rules · Home.** OBS: "MONTH CLOSES in 2 days" and "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points for every round you're short" shown 7 days before first tee (and on the earlier run's no-league Home). IMPACT: guilt/threat with no season running; casual golfer thinks they're already behind. REC: suppress floor/month-close copy until the season starts and the player is in a squad. EV: `19-C02b-home-full.jpg`, `12-C02-not-now-home.jpg` (earlier run).

**A10 · P2 · terminology · Welcome / League tab / Standings.** OBS: Undefined at point of use: "the Pro", "squad", "pot sheet", "bylaws", "HANDICAP ALLOWANCE 95%", "VERIFICATION Attested", "COUNTING CAP", "PARTICIPATION FLOOR", "scored fresh", "bylaws §4", "Points King", "Iron Man", "differential", "SI", "WHS-style", "net best ball", "strokes off the low man", "Sunningdale Rules", "crew-policed". IMPACT: the organizer must translate. REC: tap-to-define glossary chips; plain-English secondary lines. EV: `15-B03b-welcome-full.jpg`, `27-D05-tab-league.jpg`, `21-D01b-clubhouse-full.jpg`, `70-I03-setup-done.jpg`.

**A11 · P2 · comprehension · Welcome sheet.** OBS: "THREE THINGS TO KNOW" lists four bold items. IMPACT: small, but it's the first thing a joiner reads and it's wrong. EV: `15-B03b-welcome-full.jpg`.

**A12 · P2 · rules · Standings vs League tab vs Form squads.** OBS: Standings "SQUADS ARE FORMING · The Pro has the list."; League tab "Squads LIVE NOW — CAPTAINS READY [View]"; Form squads screen: Squad 1 Empty, Squad 2 Empty, "5 in the pool". IMPACT: contradictory status; "captains" never mentioned elsewhere. REC: one status string. EV: `21-D01b`, `27-D05-tab-league.jpg`, `22-D02-see-squads.jpg`.

**A13 · P2 · navigation · See the squads.** OBS: Opens a full "FORM SQUADS · BLIND DRAW" screen with no back control; tapping Squad cards or names does nothing; copy "THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW". IMPACT: dead end with developer language. REC: read-only sheet with close, plain copy ("Casey draws the squads at first tee; it's random"). EV: `22-D02-see-squads.jpg`, `23-D03-tap-squad1.jpg`.

**A14 · P2 · navigation · Clubhouse tabs.** OBS: Five tabs switch content in place; "Schedule" navigates away to a separate calendar page ("← HOME"), losing the Clubhouse chrome. IMPACT: disorienting; had to use the bottom nav to return. EV: `28-D05-tab-schedule.jpg`.

**A15 · P2 · monetization · Pot tab.** OBS: "$250 · 5 × $50 · $0 collected · 5 still owe"; five rows with checkbox-looking controls; tapping mine → "The Pro marks buy-ins as money moves between you". Nowhere: how to pay, to whom, by when. IMPACT: money question left to a text thread. REC: "Pay Casey $50 (Venmo @…) — he'll tick you off here"; make rows non-interactive for players. EV: `25-D04b-pot-full.jpg`, `37-E03-pot-after-tap.jpg`.

**A16 · P2 · comprehension · Board tab.** OBS: Header "THE BOARD · ROUNDS LAND HERE AUTOMATICALLY" but neither of my posted rounds nor Sam's/Marcus's appear on the league Board (they're on Home's "Around your buddies"). IMPACT: contradicts its own header. EV: `33-D07-tab-board.jpg` vs `19-C02b-home-full.jpg`.

**A17 · P2 · visual-hierarchy · Home feed.** OBS: After my second round: new one labelled "🎉 First round on the card" and gross rendered "9 7"; the earlier 97 relabelled "🔥 Personal best"; summary line "…You's first round…". IMPACT: wrong badges and grammar on my own items. EV: `53-G01-after-post.jpg` (text), `55-G03-back-to-board.jpg`.

**A18 · P2 · comprehension · Posted-round card & receipt.** OBS: Card shows only gross + "9.8 over your number" + "COUNTS ON YOUR CARD"; receipt has the formula but no points, no band name, no "what this did to the table"; the -9.8 figure on the form isn't tappable. IMPACT: I can't answer "what did I earn". REC: card = points band + points + season status; every number taps to its receipt. EV: `53-G01`, `56-G04`, `52-F09-tap-vsindex.jpg`.

**A19 · P2 · comprehension · Receipt.** OBS: "97 − 68.7 × 113 ⁄ 115 = 27.8 DIFFERENTIAL · YOUR NUMBER THAT DAY 27.8 · Against your number +0.0 — PLAYED TO IT" (same pattern on the 103: 28.0 / 28.0 / +0.0). IMPACT: circular for a new golfer; "played to it" is guaranteed. REC: explain 113; for <3 rounds show "building your number (2 of 3)". EV: `56-G04`, `86-K03-103-receipt.jpg`.

**A20 · P2 · gameplay · Live "Finish the round" sheet.** OBS: Two buttons "Finish — no complete member card to post" and "This one was casual — post nothing" with no visible difference. IMPACT: on the 18th green nobody will know which to press. REC: one primary ("Finish · nothing posts") plus "Keep scoring". EV: `75-I08-finish-attempt.jpg`.

**A21 · P2 · gameplay · Live setup.** OBS: I'm shown as "Jordan · EST 18.0 IDX" and the match strokes ("Jordan gets 4: holes 3, 6, 16, 18") derive from that estimate; no explanation of where 18.0 comes from or how to change it. IMPACT: $5 match decided by a silent default. REC: "No index yet — we're using 18.0; tap to adjust". EV: `68-I01-live-start.jpg`, `70-I03-setup-done.jpg`.

**A22 · P2 · social · Share the invite link.** OBS: Every "Share the invite link" button (welcome sheet, Standings, Members) produced only a toast "Invite code: THEPTCQ5"; no link shown, no share sheet in this environment. IMPACT: I could not send an invite from the app. REC: show the URL with copy/share. EV: `82-J03-share-invite.jpg`.

**A23 · P2 · onboarding · Invite link door.** OBS: "You're invited to The Papago Grind. Enter your email and you're in." — no inviter, dates, or the $50 until after account creation ("Before you join… Join — I'm in for $50"). IMPACT: money surprise after commitment. REC: show league, dates, buy-in on the door. EV: `11-A02-join-link-cold.jpg`, `11-C01-after-take-me-in.jpg` (earlier run).

**A24 · P2 · comprehension · Post form.** OBS: "No league yet? The round still counts on your card — points apply in any league you join." shown while I'm a member of The Papago Grind. IMPACT: makes me doubt I'm actually in the league. EV: `42-F02-post-form.jpg`.

**A25 · P3 · gameplay · Live setup course search.** OBS: "Papago Golf Course · Phoenix, AZ · 13 tees" listed twice. EV: live setup text 15:50.

**A26 · P2 · gameplay · You tab delete.** OBS: Only place to remove a round is a tiny ✕ on the You tab (not on the card/receipt); native browser confirm "Delete this round? It leaves your card and any league standings it counted toward."; no undo. IMPACT: hard to find when you need it, easy to hit by accident once found. REC: "Fix / delete" on the receipt with an in-app confirm and undo toast. EV: `61-H05-tap-x.jpg`, console `[dialog:confirm]`.

**A27 · P3 · onboarding · Door after invite link.** OBS: "Continue with email" and "I have an invite code" remain above the auto-opened email box. IMPACT: momentary "do I still need to press these?". EV: `11-A02-join-link-cold.jpg`, `12-B01-after-go.jpg`.

**A28 · P2 · retention · Post round / Home.** OBS: Console "Failed to load resource: the server responded with a status of 502" ×3 during Post round (15:43) and ×3 again at 15:59. IMPACT: unknown user-facing effect; something server-side is failing on core paths. EV: console log.

**A29 · P2 · comprehension · Door.** OBS: No how-it-works, preview, cost, or duration before sign-in; raw "__CS_VERSION__" visible. IMPACT: nothing to decide on except trust in the friend. EV: `09-R05-after-signout.jpg`.

**A30 · P2 · rules · Pride stake card.** OBS: Either party sees a "Settle" button; "Stakes settle on a party's tap"; the prefilled terms "Loser hosts the cookout" posted under my differently-named bet. IMPACT: who won, and who decides, is unclear; easy to post a bet you didn't mean. REC: clear terms field; settle picks a winner and asks the other party. EV: `38-E04-post-stake.jpg`, `40-E06-stake-posted.jpg`.

**A31 · P3 · terminology · Members & invites.** OBS: A "Marker here" button next to my own row; others show "INDEX 6.4" etc., mine shows nothing. IMPACT: unclear action; unclear why I have no index shown ("building" would help). EV: `35-E01-members.jpg`.

**A32 · P2 · monetization · Settings / League tab.** OBS: "PLAN FREE · PILOT · Cup Season membership lands at launch. Nothing to pay during the pilot." and "Pro Shop … COMING AT LAUNCH". No price; relationship between "membership" and the $50 buy-in never stated. IMPACT: I don't know if I'll be asked to pay the app on top of the pot. EV: `08-R04-settings-tab.jpg`, `27-D05-tab-league.jpg`.

**A33 · P3 · comprehension · Start an event.** OBS: "⚔️ The Ryder · Two teams · weekly vs-index duels · first to the clinch LIVE", "🥊 Bracket SOON", "🏆 A Major · A championship window · best card takes the jug LIVE". IMPACT: jargon; no relation to my league explained. EV: `85-K02-start-event.jpg`.

**A34 · P2 · comprehension · Home top row.** OBS: "Start a league / Start an event / Join a league" persists on Home for a member, with "Join a league" highlighted. IMPACT: suggests I haven't joined. EV: `19-C02b-home-full.jpg`.

**A35 · P3 · gameplay · Live scoring steppers.** OBS: In a burst of taps, Jordan's + registered (5) but Casey's five + taps registered nothing (Casey "–"). Low confidence (automation timing) but worth a look. EV: `74-I07-live-viewport.jpg`.

**A36 · P2 · comprehension · Live round / side games.** OBS: Nothing in one place states that side games don't affect season points while the gross score does; "Scores still post" / "every complete card posts at the finish" are the only hints. IMPACT: I couldn't answer "does winning the match matter for the Cup". EV: `69-I02-games.jpg`, `71-I04-live.jpg`.

---

## 15. Blockers / caveats

- Account was pre-existing from an interrupted earlier run; sign-up screens are cited from that run's screenshots of the same account.
- The harness auto-accepts native confirm dialogs, so the round delete confirm was accepted without my seeing it (confirmed via console `[dialog:confirm]`).
- Headless browser: "Share the card" / "Share the invite link" could not show a native share sheet; only the toasts were observable.
- Another tester's live game wrote a 103 to this account mid-test (documented as A7 rather than filtered out).
- Stepper burst-taps for the second player may have been dropped by automation timing (A35 low confidence).
