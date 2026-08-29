# Blind UX audit — Agent 6: New player joining an existing league

**Persona:** Marcus Bell, Chandler AZ, ~12 handicap, home course Bear Creek Golf Complex. Zero context about the league. A friend (Casey Ortega) texted a link + code for "The Papago Grind".
**Account:** jerecho+blind2@fischbeck3.com · **Session:** `join` · **Date:** 2026-08-29
**Key question:** "Can you understand what you are joining before accepting?"
**Screenshots:** `../screenshots/join/`

All observations come from the running app only (http://127.0.0.1:8791/). No source, docs or spec were read.

---

## 0. The invitation itself

- **Text from Casey:** a link `…/?join=THEPTCQ5`, a code `THEPTCQ5`, the league name "The Papago Grind". Nothing else.
- **Email invitation:** searched Gmail for `"Cup Season" newer_than:6h` at 15:22Z. There was **no invitation email addressed to me** (jerecho+blind2). The only invite-style email in the mailbox was "Priya wants in your crew" addressed to a different tester — its body: *"Hi Casey, Priya wants in your crew on Cup Season. Accept and their rounds land in your feed, all season. Open Cup Season"* — which is a "buddy" request, not a league invite, and explains nothing about a league.
- So the ONLY thing I knew before opening the app: a league name and a code.

## 1. Timeline (UTC)

| Time | Event |
|---|---|
| 15:21:26 | Session started |
| 15:21:36 | Cold open of the app, signed out (Journey A) — `01-A-cold-door.jpg` |
| 15:22:08 | Opened the invite link `/?join=THEPTCQ5` — `02-B-join-link-landing.jpg`. URL immediately rewritten to `/` (the `?join=` disappears from the address bar) |
| 15:22:33 | Tapped "I have an invite code" — `03-C-invite-code-tap.jpg` |
| 15:22:53 | Typed code, tapped Join — `04-D-after-code-join.jpg` |
| 15:23:18 | Typed email, tapped Go |
| 15:23:20 | Code email arrived (2 s) — subject "Confirm your email address" |
| 15:23:51 | Pasted code — the app signed me in on paste without my tapping Verify — `06-F-after-verify.jpg` (golfer card) |
| 15:24:49–15:25:04 | Filled golfer card (name, index 12, marker THE SAGUARO), Save — `09-H-card-filled.jpg`, `10-I-after-save.jpg` ("Four places. Two ways to play.") |
| 15:25:19 | "Take me in" → **first time the league is described**: "Before you join The Papago Grind — THE FINE PRINT, UP FRONT" — `11-J-after-take-me-in.jpg` |
| 15:25:50 | Tapped "Not now" to look around first → league-less Home, invite gone from view — `12-K-not-now.jpg` |
| 15:26:12 | "Join a league" → empty "Join with a code" sheet (code not pre-filled) — `13-L-join-a-league.jpg` |
| 15:27:26 | Re-typed code, Join → fine-print sheet again — `15-M-rejoin-sheet.jpg` |
| 15:27:46 | Tapped "Join — I'm in for $50" |
| 15:27:50 | **Joined.** "Welcome to The Papago Grind · THREE THINGS TO KNOW" — `16-N-after-join.jpg`, `17-N-after-join-full.jpg` |
| 15:28:18 | "How scoring works →" — `18-O-how-scoring.jpg`, `19-O-how-scoring-full.jpg` |

**Elapsed from opening the link to being a member: 5 min 42 s** (15:22:08 → 15:27:50), of which ~1.5 min was my deliberate "Not now" detour. Without the detour: ~4 min, 11 taps + 4 text fields + one trip to email.

| 15:29:16 | Member Home — `20-P-home-member.jpg`, `21-P-home-member-full.jpg` |
| 15:29:50 | "OPEN THE ROOM" → Clubhouse / Standings — `22-Q-clubhouse.jpg`, `23-Q-clubhouse-full.jpg` |
| 15:30:25 | Schedule tab → left the Clubhouse entirely for "Your golf calendar" — `24-R-tab-Schedule.jpg` |
| 15:31:20–15:32 | Pot / League / Album / Board tabs — `29-R-tab-Pot.jpg`, `30-R-tab-League.jpg`, `31-R-tab-Album.jpg`, `32-R-tab-Board.jpg` |
| 15:32:55 | "See the squads" — `33-S-see-squads.jpg` |
| 15:33:33 | Members & invites — `35-T-members.jpg`; tapping my own chip on the squads screen did nothing (`34-T-chip-marcus.jpg`) |
| 15:34:44 | Code chip → only a toast "Invite code: THEPTCQ5" (`37-T-code-chip.jpg`); Casey's standings row → sheet with "Post a round" (`38-T-casey-row.jpg`) |

| 15:35:41 | Home CTA "Lock it in and invite your crew" → the ORGANIZER'S league-creation review step with a live "Lock the bylaws & form the squads" button (`39-U-lock-it-in.jpg`); "← Back" went one step deeper into the creation wizard ("Competitiveness — pick once, argue never") |
| 15:36:19 | "+" → "Golf · before, during and after the round" (three doors) — `40-V-plus.jpg` |
| 15:36:42 | "Post a round — after you play" → form — `41-W-post-form.jpg` |
| 15:37:41 | Typed "Papago" → two identical suggestions (`43-X-course-search.jpg`); first attempt to pick one logged a 502 in the console and showed no tees; second tap worked → 13 tees (`45-Y-tees2.jpg`) |
| 15:38:47 | White tees, 43 + 44 → preview "League points this round 5 · Rough one, but posted rounds always score · 87 GROSS · -3.9 VS YOUR INDEX" (`46-Z-preview.jpg`) |
| 15:39:14 | "Post round" → two stacked sheets: "Round posted" (87 · "3.9 over your number" · COUNTS ON YOUR CARD) and "Welcome to the season ⛳" with three trophies — `47-AA-posted.jpg`, `48-AA-posted-viewport.jpg` |

| 15:39:59 | "Share the card" → toast "Card downloaded" (`49-AB-share-card.jpg`) |
| 15:40:24 | Standings after posting: Marcus still `0 R · 0 Pts`; my own row's sheet says "No rounds this season yet — post one and you're on the board." (`51-AD-standings-after.jpg`, `52-AE-marcus-row.jpg`) |
| 15:41:29 | Feed card → receipt sheet "87 gross" with the differential math (`53-AF-receipt.jpg`); **"You" tab rendered the league-creation wizard instead of my profile** (`54-AG-you.jpg`); Pot row tap → toast "The Pro marks buy-ins as money moves between you" (`55-AH-pot-after-tap.jpg`) |
| 15:42:40 | Reproduced: Home → You = wizard again. "← Back" ×2 reached "League name · Pro — that's you · Marcus @marcus · you run this league THE PRO" (`56-AI-you-escape.jpg`) |
| 15:43:24 | "Cancel" → confirm "Cancel this league? It hasn't started, so this discards it completely." → server 400, console `[cs] error: Could not discard. commissioner only`, toast "Could not discard. Something went wrong — please try again." Only then did "You" show my real card (`57-AJ-you-real.jpg`) |

---

## 2. Journey A — Discovery (signed out, cold open)

Screen: `01-A-cold-door.jpg`. Copy on screen, verbatim: "CUP SEASON · Rally your crew. Post real rounds. Take the cup. · [Continue with email] · [I have an invite code] · By continuing you agree to the Terms & Privacy Policy. · v23 · __CS_VERSION__".

**3 seconds:** an orange flag logo, "CUP SEASON", a three-line slogan, one big orange button. Golf, friends, something you can win.
**10 seconds:** "Post real rounds" implies I log scores; "Take the cup" implies a prize; "I have an invite code" implies groups are private. Nothing tells me whether it is fantasy golf, a handicap tracker, a betting app or a league manager.
**30 seconds:** I could sign in with email or enter a code. That is all I could do. There is no "how it works", no example, no screenshot, no pricing, no mention of money. The footer shows a raw template placeholder `v23 · __CS_VERSION__` (I noticed it because it looks broken).

Honest first answers (cold, signed out):
1. *What does the app do?* — Lets a group of golfing friends post their rounds and compete for a "cup". How, unknown.
2. *Primary action?* — "Continue with email" (sign in). As an invitee, "I have an invite code".
3. *What is a "season"?* — Guess: a stretch of months during which rounds count. Not stated anywhere on the door.
4. *What is a "league"?* — The word does not appear on the door at all (only "crew" and "invite code"). I assume a group of friends.
5. *What is a "cup"?* — A trophy for whoever wins the season. Not stated.
6. *Competing for?* — "the cup". Money? Unknown.
7. *Against whom?* — "your crew". Unknown whether individuals or teams.
8. *How do rounds work?* — "Post real rounds" — I assume I type my score after playing. Unknown whether hole-by-hole.
9. *After a round?* — Unknown.
10. *Different from just playing golf with friends?* — Presumably a running score/standings across many rounds. The door does not say.

I did not tap Terms/Privacy — a friend sent me here, so I would not.

## 3. Before joining — could I understand what I was joining?

Everything visible before I committed (invite text, link landing `02-B-join-link-landing.jpg`, code screen `03-C-invite-code-tap.jpg`, `04-D-after-code-join.jpg`, sign-in `05-E-after-go.jpg`, golfer card `06-F-after-verify.jpg`, orientation `10-I-after-save.jpg`, fine-print sheet `11-J-after-take-me-in.jpg`):

| Question | Verdict | Exact copy that answered it (or didn't) |
|---|---|---|
| What am I joining? | **Partially** — only at the very last step | Link landing: "You're invited to The Papago Grind. Enter your email and you're in." Fine-print sheet (after sign-in + card + orientation): "Before you join The Papago Grind · THE FINE PRINT, UP FRONT". Nothing says what kind of thing a league is until the "Four places. Two ways to play." card: "A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE." |
| Who is participating? | **Not answered** before commit | No names, no count, no "Casey invited you" anywhere before the $50 button. The roster (Priya, Jordan, Sam, Casey, Marcus) only appears after joining, in Clubhouse. |
| What the season looks like | **Partially** | Fine print: "FINISH · Cup Final · final 4 weeks". No start date, no end date, no length before commit. (After joining: "Sat Sep 5 → Sat Jan 2 · 17 wks".) |
| The rules | **Not answered** | Fine print: "PRESET · Standard" — undefined. No scoring explanation before commit. The point bands only appear post-join in "How scoring works". |
| Stakes / money | **Answered (amount), not answered (mechanics)** | "BUY-IN · $50 / player · on the pot sheet" and "Joining puts you on the pot sheet for $50. Cup Season keeps the tab; money moves between you." Who do I pay, how, by when, and what can I win — none of it before commit. |
| How long it lasts | **Not answered** before commit | Only "final 4 weeks" of something of unknown length. |
| Commitment expected | **Partially** | "PARTICIPATION FLOOR · 2 rounds / mo". What happens if I miss it is not on the sheet (three different explanations appear later, see issues). |

**The landing copy actively contradicts the flow.** "Enter your email and you're in." / "you'll join The Papago Grind the moment your sign-in code lands." — but in fact after sign-in there was a golfer card, an orientation card and then a consent sheet with a $50 commitment. Good that the consent exists; bad that the door promises instant membership and the consent sheet withholds the roster and dates.

USER ASSUMPTION: opening the friend's link would show me the league (who's in, what it costs, when it runs) before asking for anything. / ACTUAL PRODUCT BEHAVIOR: the link shows one sentence, demands email + code, a profile, an orientation, and only then a four-line fine print with no people and no dates.

USER ASSUMPTION: "I have an invite code" and the link are two different things. / ACTUAL: they are the same code; tapping the button while on the link landing shows a "LEAGUE CODE" box while the status line still says "Enter your email and you're in" (`03-C-invite-code-tap.jpg`).

USER ASSUMPTION: "Not now" on the fine print means "let me look around, I'll decide in a minute." / ACTUAL: the invite vanishes from view; Home shows "LEAGUE · None yet · JOIN OR START"; the "Join with a code" sheet is empty and I had to retype the code (`12-K-not-now.jpg`, `13-L-join-a-league.jpg`). The accessibility tree carried a status "Not joined — use code THEPTCQ5 whenever you're ready" that never appeared on screen in my screenshots.

## 4. During joining — friction log (timed)

| # | Moment | Copy / evidence | Reaction |
|---|---|---|---|
| 1 | Link landing shows the same door plus one line | "You're invited to The Papago Grind. Enter your email and you're in." (`02-B`) | Who's in it? What is it? I have a code too — do I need it? |
| 2 | Tapped "I have an invite code" | Field says "LEAGUE CODE"; status still says "Enter your email and you're in" (`03-C`) | Two names for one thing; contradictory instruction |
| 3 | Entered code, tapped Join | Code row stays, email row appears below: "Enter your email — you'll join The Papago Grind the moment your sign-in code lands." (`04-D`) | Am I joined already? "the moment your code lands" sounds automatic |
| 4 | Tapped Go | A THIRD row appears (CODE FROM EMAIL + Verify) under the other two; "Sent to … Type the sign-in code from the newest email." is below the fold (`05-E`) | Cluttered; I had to scroll to learn what happened |
| 5 | Email | Subject "Confirm your email address", body "Welcome to Cup Season · Your sign-in code: 73603342 · Type it on the sign-in screen. The code expires in an hour." Arrived in 2 s | Nothing about the league; "confirm your email" reads like a generic account, not an invitation |
| 6 | Pasted code | App signed me in without my tapping Verify; landed on "Set up your golfer card." (`06-F`) | Fine, but The Papago Grind is not mentioned — did the join happen? |
| 7 | Golfer card | "Ball marker" grid: THE SAGUARO, THE ISLAND, THE POSTAGE STAMP… (`07-G`). "Just a name and a marker to start" | What is a marker for? Why a famous hole? No hint it's my avatar |
| 8 | "Four places. Two ways to play." | "Home · Clubhouse · The ⊕ · You"; "A league · MONTHS…"; "An event · A WEEKEND OR A FEW WEEKS" (`10-I`) | First definition of "league" — three screens in |
| 9 | Fine print | "BUY-IN $50 / player · on the pot sheet · PRESET Standard · PARTICIPATION FLOOR 2 rounds / mo · FINISH Cup Final · final 4 weeks" (`11-J`) | $50 with no roster, no dates, "Standard" undefined, "pot sheet" undefined |
| 10 | "Not now" | Invite gone; Home says "LEAGUE None yet" (`12-K`) | Did I just decline Casey? |
| 11 | "Join a league" → empty "LEAGUE CODE" box (`13-L`) | Retyped the code | The app knew my code (hidden status) and made me type it again |
| 12 | "Join — I'm in for $50" | Welcome sheet: "THREE THINGS TO KNOW" with four bold items (`16-N`, `17-N`) | "Squad", "The Pro", "your number", "the board" — all new |

Total: from link open to member = 5 m 42 s; 13 taps, 4 text fields, one email round-trip, one code typed twice.

## 5. Immediately after joining — "What do I do now?"

Screen `20-P-home-member.jpg`. **Not obvious.** The hero card is "THE PAPAGO GRIND · FORMING · 7 days to first tee. 5 golfers in. The bylaws lock at the tee." with one huge orange button: **"Lock it in and invite your crew"**. As a person who just accepted a friend's invite, that button reads as somebody else's job, and "lock" sounds irreversible. Below it: "LEAGUE The Papag… OPEN THE ROOM", "NEXT Open PLAN A ROUND", "BOARD 6 NEW TODAY", "MONTH CLOSES in 2 days", the floor sentence, and a feed. There is no "post a round" or "here's what to do this week" for a member — the only posting entry is the unlabeled "+" circle over the nav bar.

What I tried, in order: (1) OPEN THE ROOM → Clubhouse (useful: dates, Pro, roster). (2) Each tab. (3) "See the squads". (4) Members. (5) **"Lock it in and invite your crew"** → organizer wizard (see issue 02). (6) "+" → post a round.

USER ASSUMPTION: the big orange button on my Home is the thing I'm supposed to do. / ACTUAL: it launches "CREATE YOUR LEAGUE · Review the bylaws, then lock it in" with a live "Lock the bylaws & form the squads" button, pre-filled with The Papago Grind's bylaws; "← Back" walks *deeper* into the creation wizard ("Competitiveness — pick once, argue never", then "League name · Pro — that's you · Marcus @marcus · you run this league THE PRO"); "Cancel" asks "Cancel this league? It hasn't started, so this discards it completely." and then fails with "Could not discard. Something went wrong — please try again." (console: `commissioner only`). While that wizard was open, the **You** tab showed the wizard instead of my card, twice.

## 6. The joiner's questions — answered from the app only (with tap counts)

| Question | Answer I could find | Where | Taps from Home |
|---|---|---|---|
| What does the league mean? | "A league · MONTHS. EVERY ROUND COUNTS TOWARD A TABLE." and Clubhouse: "Sat Sep 5 → Sat Jan 2 · 17 wks · THE PRO · CASEY" | orientation card; Clubhouse header | 1 (OPEN THE ROOM) |
| What am I competing for? | "THE POT $250 · 5 × $50" → "$150 Cup champs · $63 Runner-up · $38 Points king"; plus "Points King / Most Improved / Iron Man" | Clubhouse › Pot; Standings | 2 |
| Who am I competing against? | Priya, Jordan, Sam, Casey (THE PRO) — but "2 squads · Blind draw" and both squads are "Empty", so I don't know my team or my opponents | Members & invites; See the squads | 3 |
| How does scoring work? | Bands: "Torched it · beat it by 3+ · 12 pts … Posted anyway · rough day · 5 pts"; "best 4 / mo" | How scoring works sheet; Post form | 1–2 |
| How do I win? | Inferred only: squad with most points; "Cup Final · final 4 weeks · scored fresh" is never explained | League › bylaws | 3 (tab + expand disclosure) |
| What does each round mean? | "Every posted round scores"; 5–12 pts vs my own number | Post form | 1 |
| What if I miss a round? | Three versions: Home "your squad loses 5 points for every round you're short. Short months are waived."; scoring sheet "Miss it once and your season bye covers you automatically… the floor bites from the second miss"; bylaws "2 / mo · −5 sqd pts / round short" | Home; scoring sheet; bylaws | 0–3 |
| What happens at the end? | "CUP FINAL Final 4 weeks · from Sun Dec 6 · scored fresh"; pot split 60/25/15 | League › bylaws; Pot | 3 |
| Is there money involved? | Yes — $50 buy-in, $250 pot, "Cup Season keeps the books. Buy-ins and payouts move friend-to-friend." How/when/to whom to pay: **never stated** | fine print; Pot | 0–2 |
| What do I need to do next? | **Not stated.** Best guess from "7 days to first tee": wait for Sep 5, then post 2+ rounds a month | Home hero | — |

## 7. Journey D — first round

Entry: "+" (bottom centre) → "Golf · before, during and after the round" → "Post a round — after you play · Gross + tee, 20 seconds · counts on your card and in every league" (`40-V-plus.jpg`) → form (`41-W-post-form.jpg`).

Answers from the UI **before** entering anything:
1. *How do I know what round I'm playing?* — Not answered. No round number, no week, no "this counts for The Papago Grind". Header: "POST A ROUND · YOUR INDEX 12.0".
2. *Who am I playing?* — Nobody. It is a solo score entry.
3. *Format?* — Gross stroke play scored against my own index (point bands shown on the form).
4. *Rules?* — Partial: point bands + "Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time."
5. *How are handicaps applied?* — "vs your index" only. The bylaws' "HANDICAP ALLOWANCE 95%" never appears on the form.
6. *What do I need to enter?* — Course & tees, Rating, Slope, 18/9 holes, Front 9 gross, Back 9 gross, Date. Rating/Slope auto-filled once I picked a tee.
7. *What counts toward the season?* — **Unclear.** Form says "No league yet? The round still counts on your card — points apply in any league you join." even though I'm in a league. Nothing says the season starts Sep 5.
8. *Side games?* — Not mentioned on the form. (The LIVE door mentions "match play, Wolf & the settle-up".)
9. *If something goes wrong?* — Before posting: "Start over — clear this card". After posting: the You tab's recent-round row has an "×" — no copy says what it does.

Entering it: typed "Papago" → two identical "Papago Golf Course · Phoenix, AZ · 13 tees" rows (`43-X`); the first tap logged a 502 and showed no tees; a second tap listed 13 tees (`45-Y-tees2`). Picked White (70.1/120), 43 + 44. Preview (`46-Z-preview.jpg`): "LEAGUE POINTS THIS ROUND · 5 · Rough one, but posted rounds always score. · 87 GROSS · -3.9 VS YOUR INDEX (in red)".

Posted (`47-AA`, `48-AA-posted-viewport.jpg`): two sheets stacked — "PAPAGO GOLF COURSE · WHITE · SAT AUG 29 · 87 · 3.9 over your number · COUNTS ON YOUR CARD · [Share the card] · Back to the board" and behind it "Welcome to the season ⛳ · 🎉 Your first round is on the board · 🏆 You broke 90 for the first time · 🏆 You broke 100 for the first time · ⛳ Your first round is on the board · [Share a link — no account needed] · [Turn off this link] · The page stops working for everyone who has it." plus a "Get the full-screen app" banner.

10. *Do I understand whether I won or lost / what I earned?* — Partly. I understand 87 was 3.9 worse than my number and that is the bottom band. I do **not** know whether I earned the 5 points the preview promised: Standings still show "Marcus · 0 · — · 0"; my row's sheet says "No rounds this season yet — post one and you're on the board."; the You tab says "THIS SEASON · THE PAPAGO GRIND · ROUNDS POSTED 0" while "LIFETIME · Rounds posted 1". The receipt (`53-AF-receipt.jpg`) shows the math — "87 − 70.1 × 113 ⁄ 120 · 15.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 12.0 · Against your number -3.9 — POSTED ANYWAY" — but no points line and no "counts from Sep 5".

Sign confusion: preview "-3.9 vs your index" (red), result "3.9 over your number", receipt "-3.9 — POSTED ANYWAY". A golfer reads minus as *under* (good). Three surfaces, two conventions.

**Explanation to a friend, verbatim:** "I shot 87 at Papago off the whites. The app took the 70.1 rating and 120 slope, said that's a 15.9 differential, compared it to my 12.0 and told me I was 3.9 over my number, which is the bottom band — 'posted anyway', worth 5 points. But then the standings say I've got zero rounds and zero points this season, so I honestly can't tell you whether those 5 points went anywhere. I think it's because the season doesn't start till the 5th, but nothing on the screen said that."

## 8. The other members / my friend's standing

Standings (`51-AD-standings-after.jpg`): every row "0 · — · 0", including Sam, Jordan and Priya whose rounds are in the feed today. Casey's row → a sheet with "0 ROUNDS · 0 PTS · No rounds this season yet — post one and you're on the board. · [Post a round]" — no index, no profile, and a button that looks like it posts for Casey. Members & invites (`35-T-members.jpg`) is the only place with a number to compare: Priya 6.4, Sam 15.2, Casey 14.2, me 12.0, Jordan none. **I cannot tell who is beating whom.** The feed shows gross scores (91, 97, 84, 74) but the app scores against each person's number, so gross tells me nothing about points.

Would I send a screen to the group chat? The 87 "Share the card" image, maybe (it says "3.9 over your number" — mildly embarrassing but shareable). The standings, no — all zeros. The Pot page, no — "$0 collected · 5 still owe" would just start an argument about who pays whom, which is exactly what the page claims to prevent.

## 9. Journey A questions re-answered at the end (what changed)

1. *What does the app do?* — Runs a months-long golf league between friends: everyone posts real rounds, each round is scored against your own handicap into points, points stack for your squad, and a pot pays out at the end. **(changed: much fuller)**
2. *Primary action?* — For a member: post rounds (via the unlabeled "+"). The Home screen still says "Lock it in and invite your crew". **(changed, but the UI still disagrees)**
3. *Season?* — A fixed date range: "Sat Sep 5 → Sat Jan 2 · 17 wks", "4 mo", with monthly caps/floors and a "Cup Final" in the last four weeks. **(changed)**
4. *League?* — The group + its bylaws + its pot; "one league's room" is the Clubhouse. **(changed)**
5. *Cup?* — Still not defined anywhere; I infer it's the season trophy ("Cup champs", "Cup Final"). **(unchanged: inferred)**
6. *Competing for?* — $250 pot: 60% champs / 25% runner-up / 15% Points King; trophies. **(changed)**
7. *Against whom?* — Two blind-drawn squads of the five of us; I don't know mine yet. **(changed, partially)**
8. *How do rounds work?* — Gross + tees + date after you play; app computes differential vs index; bands 5–12 pts; best 4/month count. **(changed)**
9. *After a round?* — A card (87, "3.9 over your number"), trophies, a feed post, a receipt with the math. Whether it counted for the league: unknown. **(changed, with a hole)**
10. *Different from golf with friends?* — Handicap-normalised points so a 15 and a 6 compete evenly, a running table, a pot on the books. **(changed)**

## 10. Glossary (product terms met, what I THINK they mean)

| Term | Where | What I think it means | Confusing? |
|---|---|---|---|
| Cup / Take the cup / Cup champs | door, Pot | the season trophy / winning squad | yes — never defined |
| Season | everywhere | Sep 5 → Jan 2 date range | no (once in Clubhouse) |
| League | orientation card | a group with bylaws and a pot, runs months | no after orientation |
| Event | orientation card | short competition, weekend or weeks | mildly |
| Crew | door, welcome | your buddies / league members | no |
| Invite code / League code / Code | door, sheets | the same 8-char code | yes — three names |
| Golfer card / Your card | onboarding, You | my profile + record | no |
| Handle | golfer card | @username | no |
| Ball marker / Marker | golfer card, members | an avatar icon named after a famous hole | yes — never explained |
| GHIN | golfer card | official US handicap number | no (golfer knows) but why optional here? |
| Index / your number | scoring | handicap index | mostly no; "number" vs "index" used interchangeably |
| Starter | scoring sheet | a manual index until 3 rounds | mildly |
| The Pro | many | the league organizer (Casey) | yes at first |
| Squad | many | one of two teams in the league | yes — no one says which is mine |
| Blind draw | bylaws, squads | random team assignment, server-side | mildly |
| Bylaws | League tab | the league's rule settings | mildly; "bylaws §4" cited, no §4 exists |
| Preset · Standard | fine print, bylaws | a rules bundle | yes — undefined |
| Handicap allowance 95% | bylaws | portion of handicap used | yes — never applied visibly |
| Verification · Attested | bylaws | someone vouches for scores? | yes |
| Counting cap · Best 4 / mo | bylaws | only best 4 rounds count | no after scoring sheet |
| Participation floor | fine print, Home | minimum 2 rounds/month | no; penalty explained 3 ways |
| Season bye | scoring sheet | one free miss | yes — only place it appears |
| Cup points / points / pts | scoring | 5–12 per round | no |
| Bands (Torched it… Posted anyway) | scoring | tiers vs your number | no |
| Counter | scoring sheet | a round that counts toward the cap | yes |
| Cup Final · scored fresh | bylaws | last 4 weeks restart scoring? | yes |
| Points King / Most Improved / Iron Man | standings | individual side prizes | mildly |
| Pot / pot sheet / the tab / the books | many | ledger of who owes/paid | yes — four names |
| Buy-in | fine print | $50 entry | no |
| Stake / Post a stake | Pot | a side bet "on the books" | yes |
| The Board | many | the league feed/chat | mildly (also "Board 6 NEW TODAY") |
| The table | orientation | the standings | mildly |
| Tee sheet | Schedule, ⊕ | planned tee times | yes |
| Live / Wolf / settle-up / Skins | ⊕ LIVE | on-course side games | yes for Wolf |
| Differential | receipt | (gross − rating) × 113 / slope | no for a golfer |
| Form | You tab | recent trend dot | yes — a grey dot, no label |
| Display case / hardware / silverware | You tab | trophies | mildly |
| Forming / Squad formation / Lock / first tee | Home, Clubhouse | pre-season state until Sep 5 | yes — "lock" unexplained |
| Album | Clubhouse | round photos | no |
| Claim / claims | You › How it works | unknown | yes |
| Pro Shop / The pilot rides free | League tab | paid tier coming; current users free | yes — "pilot" undefined |

## 11. Confusion debt (things the app assumes I already know)

1. That a league has a "Pro" and that I am not one — and therefore that "Lock it in", "Add golfers", "Share the invite link", "Turn off this link", buy-in checkboxes are not mine to press.
2. That rounds before "first tee" (Sep 5) do not score for the league, and that the "5 league points" preview was hypothetical.
3. What a "squad" is, that there are two, and that I will be assigned one by a draw someone else triggers.
4. What "Standard" preset means and what the other presets would have changed.
5. How and to whom to pay the $50, and that the "pot sheet" is a ledger the Pro edits.
6. That "your number" = "your index" = "handicap index", and that a negative "vs index" is bad.
7. Which of the three floor-penalty explanations is true.
8. What "Cup Final · scored fresh" does to my accumulated points.
9. That "ball marker" is an avatar and that famous-hole names are decorative.
10. What "Attested" verification requires of me.
11. That "the board" is both the chat and the feed, and "board" on Home counts new items.
12. What "Iron Man", "Points King", "Most Improved" pay (only Points King's 15% is stated).
13. What "bylaws §4" refers to.
14. That "Share the invite link" shows a toast with a code, not a link.
15. That the "×" on my recent round deletes it (unlabeled).

## 12. 30-second "explain Cup Season to a friend" — VERBATIM

"Cup Season is an app where a group of golf buddies runs a season — ours is 17 weeks, September 5th to January 2nd. Everyone puts $50 in a pot, you get split into two squads by a blind draw, and every round you play anywhere counts: you post your gross score and tees, and the app scores it against your own handicap, so a 15 beating his number gets the same points as a 6 beating hers. Your best four rounds a month count for your squad, you owe at least two rounds a month, and the last four weeks are a 'Cup Final' that's scored fresh. The winning squad takes 60% of the pot, second 25%, and the top individual 15%. The catch is the app doesn't move money — Casey keeps a tab, and I still don't know how I'm supposed to pay him."

## 13. Persona verdict

**"Can you understand what you are joining before accepting?" — 3 / 10.** Before the $50 button I knew: the league's name, that it costs $50 "on the pot sheet", "Standard" (undefined), 2 rounds a month, and that it ends with a "Cup Final". I did not know who was in it (not even that Casey ran it), when it started or ended, how scoring worked, or how money moved. Every one of those answers exists in the app — but only *after* joining, spread across Clubhouse tabs and a collapsed "LEAGUE RULES & PRO SHOP" disclosure. The consent sheet is the right idea with the wrong contents.

**Scores (1–10):** concept clear 5 · setup clear 4 · rules clear 5 · gameplay compelling 6 · side games compelling 4 · stakes meaningful 6 · easy to pick up 4 · would play again 6 · would invite 4 · would pay 5.

Why "would play again 6": the handicap-normalised bands are a genuinely good idea and the receipt shows the math. Why "would invite 4": I could not confidently explain what my friend would be agreeing to, and the app itself gave me nothing to forward except a code.

## 14. Issues (severity · category · evidence)

| ID | Sev | Cat | Finding | Evidence |
|---|---|---|---|---|
| J-01 | P0 | onboarding | The join consent sheet withholds everything a person needs to decide: no roster, no organizer name, no dates, no scoring, no payment path — only "$50 / player · on the pot sheet", "PRESET Standard", "2 rounds / mo", "Cup Final · final 4 weeks". All of it exists post-join. | `11-J-after-take-me-in.jpg`, `22-Q-clubhouse.jpg` |
| J-02 | P0 | navigation | A plain member's Home hero CTA "Lock it in and invite your crew" opens the organizer's create-league wizard ("CREATE YOUR LEAGUE · Review the bylaws, then lock it in" with a live "Lock the bylaws & form the squads"). "← Back" goes deeper; "Cancel" prompts "Cancel this league? … discards it completely" and fails with a generic error; while the wizard is open the You tab renders the wizard. | `39-U-lock-it-in.jpg`, `56-AI-you-escape.jpg`, `54-AG-you.jpg`, console `commissioner only` |
| J-03 | P0 | gameplay | First round: preview promised "LEAGUE POINTS THIS ROUND 5"; result says "COUNTS ON YOUR CARD"; Standings/You/my row say 0 rounds this season and "No rounds this season yet — post one and you're on the board." Nothing says pre-season rounds don't count. | `46-Z-preview.jpg`, `47-AA-posted.jpg`, `51-AD-standings-after.jpg`, `52-AE-marcus-row.jpg`, `57-AJ-you-real.jpg` |
| J-04 | P1 | terminology | Sign convention flips: "-3.9 VS YOUR INDEX" (red), then "3.9 over your number", then receipt "Against your number -3.9 — POSTED ANYWAY". A golfer reads minus as under. | `46-Z-preview.jpg`, `48-AA-posted-viewport.jpg`, `53-AF-receipt.jpg` |
| J-05 | P1 | onboarding | Link landing promises "Enter your email and you're in." / "you'll join … the moment your sign-in code lands" but the real flow is sign-in → golfer card → orientation → $50 consent. | `02-B-join-link-landing.jpg`, `04-D-after-code-join.jpg`, `11-J` |
| J-06 | P1 | retention | "Not now" on the consent sheet drops the invite: Home says "LEAGUE None yet", the Join sheet is empty and the code must be retyped; the only trace is an accessibility status never seen on screen. | `12-K-not-now.jpg`, `13-L-join-a-league.jpg` |
| J-07 | P1 | comprehension | "PRESET · Standard" appears on the consent sheet, bylaws and wizard and is defined nowhere. | `11-J`, `30-R-tab-League.jpg` |
| J-08 | P1 | rules | Three inconsistent explanations of the participation floor: Home "Miss it and your squad loses 5 points for every round you're short. Short months are waived."; scoring sheet "Miss it once and your season bye covers you automatically… the floor bites from the second miss"; bylaws "2 / mo · −5 sqd pts / round short". | `20-P-home-member.jpg`, `19-O-how-scoring-full.jpg`, `30-R-tab-League.jpg` |
| J-09 | P1 | social | "Squad" is never defined and I never learn mine. Standings says "SQUADS ARE FORMING · The Pro has the list." while the League tab says "Squads · LIVE NOW — CAPTAINS READY"; the squads screen shows both "Empty". | `22-Q-clubhouse.jpg`, `30-R-tab-League.jpg`, `33-S-see-squads.jpg` |
| J-10 | P1 | monetization | How to pay the $50 (to whom, how, by when) is never stated; Pot shows "$0 collected · 5 still owe"; the buy-in rows look like checkboxes but tapping only toasts "The Pro marks buy-ins as money moves between you". | `29-R-tab-Pot.jpg`, `55-AH-pot-after-tap.jpg` |
| J-11 | P1 | gameplay | Feed shows league mates' rounds today (Sam 91, Jordan 97, Priya 84/74 "First round on the card") but Standings shows every player at 0 R / 0 Pts; no copy connects this to "7 days to first tee". | `21-P-home-member-full.jpg`, `23-Q-clubhouse-full.jpg` |
| J-12 | P1 | navigation | The Clubhouse "Schedule" tab leaves the Clubhouse for a full-page calendar whose only exit is "← HOME"; the tab strip disappears. | `24-R-tab-Schedule.jpg` |
| J-13 | P1 | social | No invitation email was sent to the invitee; the only email was subject "Confirm your email address" / body "Welcome to Cup Season · Your sign-in code…" — nothing about the league or the friend. | Gmail search 15:22Z (no message to jerecho+blind2 besides sign-in codes) |
| J-14 | P2 | visual-hierarchy | Sign-in door stacks three input rows (code+Join, email+Go, CODE FROM EMAIL+Verify) under two big buttons; the "Sent to … Type the sign-in code" status sits below the fold. | `05-E-after-go.jpg` |
| J-15 | P2 | terminology | The same code is "invite code" (button), "LEAGUE CODE" (field), "Invite code: THEPTCQ5" (toast), "Code · THEPTCQ5" (chip). | `03-C`, `13-L`, `37-T-code-chip.jpg` |
| J-16 | P2 | comprehension | Welcome sheet titled "THREE THINGS TO KNOW" lists four bold items, two of which are the pot; the scoring sheet says "Your league's exact numbers are in League rules" with no link. | `17-N-after-join-full.jpg`, `19-O-how-scoring-full.jpg` |
| J-17 | P2 | onboarding | "Ball marker" is a required-feeling grid of 14 famous-hole nicknames with no explanation that it is an avatar; all five members display the same cactus; members list shows an unexplained "Marker here" button. | `07-G-card-markers.jpg`, `35-T-members.jpg` |
| J-18 | P2 | gameplay | Post form says "No league yet? The round still counts on your card — points apply in any league you join." to a member of a league. | `41-W-post-form.jpg` |
| J-19 | P2 | navigation | "See the squads" page has no back control; the player chips look tappable and do nothing. | `33-S-see-squads.jpg`, `34-T-chip-marcus.jpg` |
| J-20 | P2 | social | Tapping a league mate's standings row opens a sheet whose only action is "Post a round" (reads as posting for them); no index, no profile, no record. | `38-T-casey-row.jpg` |
| J-21 | P2 | comprehension | One 87 mints two trophies ("You broke 90 for the first time", "You broke 100 for the first time") and a duplicated "Your first round is on the board"; sheet says "Pinned to your card" but the You tab display case says "No hardware yet… post your first round". | `47-AA-posted.jpg`, `57-AJ-you-real.jpg` |
| J-22 | P2 | gameplay | Course search returns two identical "Papago Golf Course · Phoenix, AZ · 13 tees"; the first pick logged a 502 and showed no tees, the second worked. | `43-X-course-search.jpg`, console at 15:38:01 |
| J-23 | P2 | terminology | Undefined jargon cluster on the bylaws: "HANDICAP ALLOWANCE 95%" (never applied on the form), "VERIFICATION Attested", "Cup Final · scored fresh", "COUNTING CAP", "bylaws §4" (no §4 anywhere), "THE PILOT RIDES FREE". | `30-R-tab-League.jpg`, `23-Q-clubhouse-full.jpg` |
| J-24 | P2 | social | Board shows "Match play: Casey def. Marco 1 UP THRU 3" but Marco is not in the 5-player member list; Home says "5 golfers in" while six names appear in the feed. | `21-P-home-member-full.jpg`, `35-T-members.jpg` |
| J-25 | P2 | visual-hierarchy | After posting, two sheets stack ("Round posted" over "Welcome to the season ⛳") plus an add-to-home-screen banner; the celebration sheet carries "Turn off this link · The page stops working for everyone who has it" with no link shown. | `47-AA-posted.jpg`, `48-AA-posted-viewport.jpg` |
| J-26 | P2 | onboarding | Member Home is dominated by organizer/growth actions ("Join a league" highlighted, "Add golfers", "Share the invite link", "Lock it in"); no member-facing "what to do next"; posting lives behind an unlabeled "+". | `20-P-home-member.jpg` |
| J-27 | P2 | social | "Share the invite link" (Standings, Members, welcome) produced only a toast "Invite code: THEPTCQ5" — no link, no copy confirmation (headless caveat). | `60-AK-share-invite2.jpg` |
| J-28 | P2 | comprehension | Date formats mix ISO "2026-08-29" (receipt, recent rounds) with "Sat Aug 29"/"Aug 29" elsewhere; unlabeled "×" on the recent-round row. | `53-AF-receipt.jpg`, `57-AJ-you-real.jpg` |
| J-29 | P2 | navigation | The invite URL `?join=THEPTCQ5` is rewritten to `/` on load; the invite context survives only in memory until sign-in. | `url` output at 15:22:08 |
| J-30 | P3 | visual-hierarchy | Raw template placeholder "v23 · __CS_VERSION__" visible on the door. | `01-A-cold-door.jpg` |
| J-31 | P3 | navigation | Help ("How it works" ×5) only lives at the bottom of the You tab; the orientation card says "Reopen this any time from You › How it works". | `57-AJ-you-real.jpg` |
| J-32 | P3 | comprehension | Console on join: "[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'" — invisible to the user but a real error at the moment of joining. | console at 15:27:49 |


## 15. Blockers / caveats

- Headless browser: "Share the card" reported "Card downloaded" and "Share the invite link" only produced a toast; a real phone's share sheet may differ.
- Full-page screenshots overlay the sticky nav bar and the "+" button mid-page; I did not count those overlaps as bugs.
- I did not press "Lock the bylaws & form the squads" (would have mutated my friend's league). The harness auto-accepted the "Cancel this league?" confirm; the server refused.
- No email invitation was ever sent to my address, so the "what does the email say" question is answered by its absence.
- I never played the LIVE door or "Plan a tee time".
