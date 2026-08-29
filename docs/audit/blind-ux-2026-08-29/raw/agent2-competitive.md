# Blind UX audit — Agent 2, Competitive Golfer ("Priya Nair")

Persona: Priya Nair, Scottsdale AZ, home course TPC Scottsdale (Champions), 6.4 index, 60+ rounds/yr, knows match play / skins / nassau / wolf. Key question: **does Cup Season feel strategically compelling enough to care about all season?**
Account: jerecho+blind4@fischbeck3.com · Session: `comp` · Browser: phone-sized headless (390px wide), local build `v23 · __CS_VERSION__`.
Invitation: text from Casey Ortega with link `?join=THEPTCQ5` (league "The Papago Grind"). No invitation EMAIL to my address existed (Gmail search "Cup Season" newer_than:6h, filtered to my address: only sign-in-code emails).

Screenshot root: `../screenshots/comp/`

## Caveat on state (blocker-level honesty)

When I opened the app at 15:21 UTC the browser profile was ALREADY SIGNED IN as this account, and the account already carried a completed profile (Priya, @priya, 6.4), membership in The Papago Grind, and two posted rounds (74 @ TPC Scottsdale Champions dated Aug 27; 84 @ Ken McDonald Black dated Aug 25) — evidently from an earlier run of this persona about an hour before (Gmail shows a "Confirm your email address" code to my address at 14:14Z and a "Priya wants in your crew" email to Casey at 14:21Z). I signed out through the app (You → ⚙ → Settings → Sign out; 4 attempts to get the Settings tab to switch, see Issues) and re-did the cold open and the invite-link entry signed-out, then signed back in. Journeys that depend on a virgin account (golfer card, first-ever round) are therefore partly re-enacted; where the prior state contaminates a finding I say so.

## Timeline (UTC)

- 15:21:25 session start; 15:21:32 first load → already signed in (shot `01-door.jpg`).
- 15:25:49 signed out via ⚙ → Settings → "Sign out" (shots `02`–`09`).
- 15:26:05 cold door, signed out (`10-cold-door.jpg`).
- 15:26:15 opened invite link `?join=THEPTCQ5` signed out (`11-join-link.jpg`).
- 15:26:40 entered email, pressed Go → code screen (`12-code-entry.jpg`). Email arrived 15:26:42 (2 s). (My own inbox search failed to surface it for ~3 min because Gmail thread-collapsed it — I pressed "Resend code" at 15:29:14; fresh code arrived 15:29:15.)
- 15:30:15 typed the 8-digit code; the app verified as soon as the last digit was typed (the "Verify" button was gone before I could tap it). 15:30:24 signed in → Home + "Welcome to The Papago Grind · THREE THINGS TO KNOW" sheet (`13-after-verify.jpg`).
- 15:30:40 tapped "How scoring works →" in the welcome sheet (`14-scoring-works.jpg`, full: `15-scoring-full.jpg`, scrolled: `16-scoring-scrolled.jpg`).
- 15:32:17 tapped the big orange "Lock it in and invite your crew" on Home → landed in "CREATE YOUR LEAGUE · LOCKS AT FIRST TEE / REVIEW THE BYLAWS, THEN LOCK IT IN" with a "Lock the bylaws & form the squads" button (`19-lock-tap.jpg`); "← Back" went to the wizard's "Competitiveness — pick once, argue never" step (`20-league-room.jpg`). I am a PLAYER; the Pro is Casey.
- 15:33 League room via the "League · The Papago Grind · OPEN THE ROOM" tile (`21-league-room.jpg`): tabs Standings / Board / Schedule / Pot / Album / League; "SQUADS ARE FORMING · The Pro has the list · 5 PLAYERS IN THE POOL · [See the squads]"; individual race table (Player / R / Avg vs index / Pts) all zeros.
- 15:34 "See the squads" → "FORM SQUADS · BLIND DRAW · 5 in the pool · THE HAT SHUFFLES SERVER-SIDE — NOBODY RIGS THE DRAW", two empty squad cards and five tappable player chips, no back control (`22-squads.jpg`).
- 15:35 League tab (`24-league-tab.jpg`, rules expanded: `29-rules-open2.jpg`), Pot tab (`25-pot-tab.jpg`), Schedule (`26-schedule-tab.jpg` — it is a separate "Your golf calendar" page, not a tab), Members & invites sheet (`27-members.jpg`), Board tab (`30-board-tab.jpg`), match-play scorecard sheet (`32-matchplay-card.jpg`).
- 15:38:16 ⊕ / "Post" → "GOLF · BEFORE, DURING AND AFTER THE ROUND" door with three cards: LIVE "Play now — score the group live" / "Post a round — after you play" / "Plan a tee time — before" (`33-post-door.jpg`).
- 15:38:40 "Post a round — after you play" form (`34-post-form.jpg`): "POST A ROUND · YOUR INDEX 6.4", course search + two recent-course chips, Rating/Slope, 18/9 holes, Front 9 / Back 9 gross, Date (pre-filled 2026-08-25 from an old draft — the app had toasted "Your unposted round came back — it's waiting in Post a round" on every screen), Scan the card / Add a photo, "How this round scores" live preview + Point bands table.
- 15:39 entered 37/37 at TPC Scottsdale (Champions) 72.4/133 → preview "LEAGUE POINTS THIS ROUND 12 · You torched your number by 5.0. Sandbagger alert. · 74 GROSS · +5.0 VS YOUR INDEX" (`35-preview-74.jpg`).
- 15:39–15:40 deleted the two rounds left by the earlier run (You → Recent rounds → "Delete round" ×2; the confirm is a native browser confirm() "Delete this round? It leaves your card and any league standings it counted toward."). Display-case badges "Broke 100 / Broke 90 / Broke 80 · 74 gross" SURVIVED the deletion with Lifetime "Rounds posted 0" (`37-delete-confirm.jpg`).
- 15:40:44 set date 2026-08-27, "Post round" → 15:40:54 result sheet "TPC SCOTTSDALE (CHAMPIONS) · THU AUG 27 · 74 · beat your number by 5.0 · COUNTS ON YOUR CARD · [Share the card] [Back to the board]" stacked with a second sheet "Welcome to the season ⛳ · 74 at TPC SCOTTSDALE (CHAMPIONS) · Your first round is on the board · [Share a link — no account needed] [Turn off this link]" (`38-posted-74.jpg`, `39-share-card.jpg`). "Share the card" produced no visible feedback.
- 15:41 Standings after the 74: Priya "0 R · — · 0 Pts"; tapping my row → sheet "Priya · 0 ROUNDS · 0 PTS · No rounds this season yet — post one and you're on the board." (`40-standings-after74.jpg`, `41-standings-priya-tap.jpg`).
- 15:42:52 "Start over — clear this card" wiped the recent-course chips; with no course selected the preview computed "84 GROSS · -77.6 VS YOUR INDEX · 5 pts" (`42-preview-84.jpg`). Searched "Ken McDonald" → one result "Ken Mcdonald Golf Course Tempe, AZ · 7 tees" → tee list (`44-tee-picker.jpg`) → Black 71.9/125 → preview "5 · Rough one, but posted rounds always score. · 84 · -4.5 vs your index" (`45-preview-84b.jpg`).
- 15:44:03 "Post round" → 15:44:08 "KEN MCDONALD GOLF COURSE · BLACK · TUE AUG 25 · 84 · 4.5 over your number · COUNTS ON YOUR CARD" (`46-posted-84.jpg`).
- 15:45 Round receipts from the board cards: "84 gross · KEN MCDONALD GOLF COURSE · BLACK · 18 HOLES · 2026-08-25 · The course 71.9 / 125 · 84 − 71.9 × 113 ⁄ 125 = 10.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 6.4 · Against your number -4.5 — POSTED ANYWAY" (`47-round-84-detail.jpg`); the 74's receipt reads "+5.0 — TORCHED IT" (`48-round-74-detail.jpg`). Neither receipt shows a points number or says whether the league counted it.
- 15:45:30 Tapped the You tab from Home → landed in "CREATE YOUR LEAGUE · REVIEW THE BYLAWS" wizard AGAIN (`49-you-after.jpg`). Reproduced: Home → You = wizard; Clubhouse → You = profile.
- 15:46 You page after two rounds (`50-you-after2.jpg`): index still 6.4, FORM two dots (grey, orange) unexplained, Lifetime "Rounds posted 2 · Best vs index +5.0 · Avg vs index +0.3 · Cups & events 1 Played in", This season · The Papago Grind "Rounds posted 0". Read the three "How it works" sheets (Leagues vs events; The four places; Buddies, invites and claims).
- 15:46:44 ⊕ → LIVE "Play now — score the group live" → "SET UP THE ROUND" (`51-live-setup.jpg`): course search, tee/rating/slope, 18/9, "Enter the pars", THE FOURSOME 1/4 with league chips "Jordan · 18.0 / Sam · 15.2 / Casey · 14.2 / Marcus · 12.0", "Search the app — add any golfer", Add a guest (Name/Index), and "GAME FOR THIS ROUND · PICK ONE: Just score / Match play / Wolf / Skins / Sunningdale Rules".
- 15:47–15:48 Papago search returned the same course TWICE ("Papago Golf Course Phoenix, AZ · 13 tees" ×2); picked Blue 72/125; added Casey, Marcus, Jordan; read all four game blurbs (Match play: "Singles (2) or 2v2 net best ball (4)… Priya + Casey vs Marcus + Jordan · net best ball · Strokes off the low man (Priya): Casey gets 9 — the 9 hardest holes · Marcus gets 6: holes 3, 6, 9, 16, 17, 18 · Jordan gets 13"; Wolf: "needs four… wolf tees last, picks a partner after any drive — or goes lone for 3. Last two holes (17–18): last place is the wolf"; Sunningdale: "no handicaps — go 2 down and you get a stroke until you climb out"; Skins: "Low net takes the hole's skin; ties carry the pot… Strokes apply off the low man"). Set "Dollars per skin" = 5 (`52-live-skins-setup.jpg`).
- 15:48:54 "Tee off →" → live scorer (`53-live-hole1.jpg`): HOLE 1 · PAR 5 · SI 15, four rows with −/+ steppers and "0 STK / 9 STK / 6 STK / 13 STK", "Group phones — everyone can score", "Finish round & post to season", "Scrap this round", side-game panel "SKINS · HOLE 1 WORTH 1 SKIN · THRU 0 · LOW NET TAKES IT · $5/SKIN", "ROUND SETTLEMENT · LIVE · ALL SQUARE $0". Status toast: "On the tee, good luck everybody".
- 15:50:08–15:54:56 scored all 18 holes with the steppers (first tap opens at par; then ±). Priya 78 (+6), Casey 93, Marcus 89, Jordan 103. Skins ran live: after hole 1 "CASEY → PRIYA $5 · MARCUS → PRIYA $5 · JORDAN → PRIYA $5"; after 9 "MARCUS 5 · PRIYA 1 · CASEY 1 · 3 RIDING … HOLE 10 WORTH 3 SKINS"; after 18 "PRIYA 7 · MARCUS 6 · CASEY 3 … DONE · 2 SKINS DIED CARRIED … JORDAN → PRIYA $60 · JORDAN → MARCUS $20 · CASEY → MARCUS $20" (`54-live-hole1.jpg`, `55-live-hole9.jpg`, `56-live-hole18.jpg`).
- 15:55:24 "Finish round & post to season" → sheet "Finish the round · ONE FINISH — EVERY MEMBER'S CARD POSTS · Complete cards post to the season, attested by the group. A partial card is skipped, not lost. [Post 4 cards to the season] [This one was casual — post nothing]" (`57-live-finish.jpg`). Console logged two "Failed to load resource: 502" errors at this moment.
- 15:55:53 "Post 4 cards to the season" → 15:56:00 "Round posted · 4 CARDS TO THE SEASON · 💰 Priya took 7 skins and $60 · JORDAN PAYS PRIYA $60 · JORDAN PAYS MARCUS $20 · CASEY PAYS MARCUS $20 · SETTLE UP · 1 THRU 18 18 PRIYA · ⛳ Priya · 78 POSTED · 18 HOLES · ✓ ATTESTED (×4) · [Share the card] [Share the settlement — no account needed] [Revoke a shared link]" (`58-live-posted.jpg`).
- 15:56 Home board after the live round (`59-home-after-skins.jpg`): cards "You · Beat your number by 1.0 · 78 gross · Papago Golf Course · Blue", "Jordan · Played to their number · 103 gross", "Casey 🎉 First round on the card · 93", "Marcus 🎉 First round on the card · 89", and a league card "Priya took 7 skins and $60 · Priya 7, Casey 3, Marcus 6 · $5 a skin · 2 carried died · SCORECARD ›". Pot tab (`60-pot-after-skins.jpg`): pot unchanged ($250 · $0 collected), "THE OTHER STAKES · PRIDE, ON THE BOOKS" lists only "Loser buys the beers · Jordan vs Casey"; the $60 skins settlement is NOT on the books anywhere in the Pot tab.
- 15:57 Standings still all zeros for everyone (five posted rounds today between us); Casey's row sheet: "0 ROUNDS · 0 PTS · No rounds this season yet".
- 15:57–15:58 "Post a stake" sheet (`61-post-stake.jpg`): "PRIDE, ON THE BOOKS — NEVER MONEY · Name it · The shape (Loser hosts / Winner picks the course / Strokes next time / Standing bounty / Name your own) · The terms · Against (The field — first to hit it / Jordan / Sam / Casey / Marcus) · Rides on (optional)". Posted "Low net of September · Priya vs Casey · Loser gives 2 a side next time · rides on Best net round in September" → appears in Pot tab with [Settle] [✕] (`62-stake-filled.jpg`, `63-stake-posted.jpg`).
- 15:58 Board tab now shows "◆ Priya v Casey — Low net of September. Loser gives 2 a side next time" next to "◆ Priya took 7 skins and $60 …". Find golfers (magnifier) → "Casey @casey · Phoenix, AZ · Requested" (a buddy request from the earlier run) and an unrelated "zimacasey @zimacasey · Nashville [Add]"; a result row is not tappable — no profile, no head-to-head (`67-find-casey3.jpg`).
- 16:00 ⊕ → "Plan a tee time — before" → sheet "Put a round on the tee sheet · BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST · Day (defaulted 2026-09-05) · Tee time · optional · Course (placeholder "Pebble Beach") · Note · optional · Tag your group · 0 tagged [Jordan] [Sam] [Casey] [Marcus] · [On the tee sheet]" (`68-plan-tee.jpg`). Posted Sat Sep 5 07:30 Papago, tagged Casey + Marcus → status "On the tee sheet: your group is named on the boards" (`72-tee-posted2.jpg`). Console: another "Failed to load resource: 502".

## JOURNEY A — DISCOVERY (signed out, cold)

Door (`10-cold-door.jpg`): orange flag-in-cup mark, "CUP SEASON", "Rally your crew. Post real rounds. **Take the cup.**", buttons "Continue with email" / "I have an invite code", "By continuing you agree to the Terms & Privacy Policy.", "v23 · __CS_VERSION__" (a raw template placeholder is visible on the sign-in screen).

- **3 seconds:** a golf app; something about a "cup"; you post rounds. Dark, confident, looks like a real product.
- **10 seconds:** three verbs — rally, post, take. It is social ("crew") and competitive ("take the cup"). I do not know what the cup is, how long a season is, or whether money is involved. I have no idea what "real rounds" means (GHIN? attested? photos?).
- **30 seconds:** I can either sign in with email or enter an invite code. There is nothing else to do; no "how it works", no screenshots, no preview of a league. Everything I know comes from the tagline. I did NOT open Terms/Privacy — no golfer would at this point.

Invite link opened signed out (`11-join-link.jpg`): same door, plus an email field and the line "You're invited to The Papago Grind. Enter your email and you're in." The URL bar dropped the `?join=` code immediately. The invite tells me nothing about the league: not who is in it, not the stakes, not when it starts, not the format. A real invitee would have to ask Casey "so what is this?".

### First answers (before signing in)
1. **What does the app do?** Tracks golf rounds with friends and turns them into some kind of competition for a "cup". 
2. **Primary action?** "Continue with email" — i.e. sign up. After that, presumably "post a round".
3. **Season?** Guess: a period of weeks/months during which posted rounds count. Nothing on screen says.
4. **League?** Guess: my friend group. The invite calls it "The Papago Grind". No definition.
5. **Cup?** Unknown. A trophy at the end of the season? Could be a match-play playoff. Zero information.
6. **Competing for?** Unknown — "the cup". Money? Bragging rights? Unknown.
7. **Against whom?** Presumably the people Casey invited. Unknown whether it is individual or team.
8. **How do rounds work?** Guess: I enter a score after I play. "Post real rounds" hints at verification, but nothing says how.
9. **After a round?** Unknown. Probably points.
10. **Different from just playing with friends?** From the door alone: it keeps score over time and there is a cup. That's it.

## Sign-up / join (returning account)
- Email → Go: code screen (`12-code-entry.jpg`) "Sent to jerecho+blind4@fischbeck3.com. Type the sign-in code from the newest email." with "Resend code (26s)" cool-down. The email arrived in 2 s. Typing the eighth digit verified automatically (no need to tap "Verify"). Good.
- Signed in straight to Home with the sheet "Welcome to The Papago Grind · THREE THINGS TO KNOW" — which lists FOUR bold items (`13-after-verify.jpg`): "You're on the pot sheet: $50 buy-in." / "You can't hurt your squad by playing badly." / "Rounds score against your own number." / "The pot lives on the books." + "How scoring works →" + "Share the invite link". This sheet appeared even though the account had already joined earlier — fine, but it is the first time I learn that (a) there is a $50 buy-in, (b) there are "squads", (c) a "Pro". None of that was in the invite.
- The app never asked for my index during this (re-)entry; the earlier run's golfer card had stored 6.4. The card (⚙ → Your card) shows City and Home course EMPTY even though the persona has both — either the card never asked or the fields were skipped; the profile also shows "add your GHIN" and the card says "GHIN # · optional · A reference on your card — we never resell or verify it."
- Index handling: "Handicap index 6.4 · Update index · Your index builds automatically from your posted scores (best of your recent rounds, WHS-style) — it appears once you've posted 3. Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed." — so my 6.4 is a "starter" that will be overwritten by the app's own calculation after 3 rounds. As a golfer with a real GHIN 6.4 built on 20 scores, having it replaced by a 3-round WHS-lite number is alarming and it is not explained how the two coexist (which number does the league use? mine or the app's?).
- 16:01 Home now shows the tile "NEXT · SAT 07:30 · PAPAGO GOLF COURSE" and the line "Next round Papago Golf Course · in 7 days · Buddy's playing Jordan · sat" (`73-home-after-tee2.jpg`). "Start an event" sheet: "⚔️ The Ryder · Two teams · weekly vs-index duels · first to the clinch · LIVE / 🥊 Bracket · Knockout · seeded · last golfer standing · SOON / 🏆 A Major · A championship window · best card takes the jug · LIVE · Every event mints a trophy for your display case." (`75-start-event.jpg`).
- 16:03 `/legal.html#pot` "Prize Pool Disclaimer": "Any prize pool shown in the app is managed entirely by league organizers and participants… CupSeason does not collect, hold, transfer, or distribute money, takes no fee or cut…". Session stopped 16:03:22 UTC (≈42 min in app).

## RULES HUNT (from the app only)

Sources found: the welcome sheet ("THREE THINGS TO KNOW"), the "How scoring works" sheet (reachable from the welcome sheet, the You page "How it works" list, the ⚙ card, and the League tab), the Point-bands table on the Post-a-round form, the bylaws table (League tab → collapsed "▶ LEAGUE RULES & PRO SHOP"), the Standings footnote, and the round receipts.

| Rule | What the app says (verbatim) | Discoverable? | Understandable? | Can I predict the outcome? | Could I explain it? | Confidence |
|---|---|---|---|---|---|---|
| How points are earned | "Every round is scored against your own number… Torched it · beat it by 3+ · 12 pts / Beat your number · by 1–3 · 9 pts / Played to it · within 1 · 7 pts / A little loose · 1–3 over · 6 pts / Posted anyway · rough day · 5 pts" | Yes (3 places) | Mostly — but "by 3" of WHAT is never defined. The receipt reveals it is index − differential (74 at 72.4/133 → 1.4 differential → "+5.0"), not strokes vs course handicap. | Yes, once I reverse-engineered the receipt; a normal golfer would assume strokes. | Yes | 7 |
| Good vs great round | 74 (+5.0) = 12 pts; 78 (+1.0) = 9 pts (board says "Beat your number by 1.0"); 84 (−4.5) = 5 pts. Difference between a career round and a bad day = 7 pts. | Yes | Yes | Yes | Yes | 8 |
| Does volume matter? | "Your best rounds each month count for your squad — a better round always bumps your worst counter"; bylaws "COUNTING CAP Best 4 / mo"; form: "Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time." | Yes | Yes | Partly — nothing says whether the individual "Pts" column is capped too, or how "Iron Man" (most rounds) interacts with the cap. | Mostly | 6 |
| Cap | "Best 4 / mo" — the word "cap" only appears as "COUNTING CAP" in the bylaws table. | Yes | Yes | Yes | Yes | 8 |
| Floor | Home: "Monthly floor · 2 rounds a month. Miss it and your squad loses 5 points for every round you're short. Short months are waived."; bylaws "PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short"; scoring sheet: "Miss it once and your season bye covers you automatically — life happens; the floor bites from the second miss." | Yes | Yes, but three different phrasings and the "bye" only appears in one of them. | Yes | Yes | 7 |
| "Cup" / final / endgame | Bylaws: "CUP FINAL · Final 4 weeks · from Sun Dec 6 · scored fresh"; Pot: "$150 Cup champs / $63 Runner-up / $38 Points king"; "Leagues vs events" sheet: "the endgame settles it: a Cup Final or the points table." | Barely | **No.** "Scored fresh" is never defined. Who plays the Cup Final? Both squads? Do the first 13 weeks matter at all if the final 4 are "scored fresh"? Is "Cup champs" a squad or a person? | No | No | 2 |
| Ties | Nothing. Not in bylaws, scoring sheet, standings footnote, or the welcome sheet. | **No** | — | No | No | 1 |
| Handicap application | "Rounds score against your own number"; bylaws "HANDICAP ALLOWANCE 95%"; index rules: "builds automatically… appears once you've posted 3… Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced… crew-policed." Live games: "Strokes off the low man (Priya): Casey gets 9 — the 9 hardest holes…" | Yes | Partly. The 95% allowance never shows up in any calculation I saw (preview, receipt, live strokes). Which number the league uses — my real 6.4 or the app's 3-round number — is not stated. | No (can't tell where 95% applies) | Partly | 4 |
| Sandbagging | "The 12-point ceiling caps what a padded number can buy"; "Manual changes are announced to your league so the crew keeps everyone honest"; "VERIFICATION Attested"; live: "Scores entered together are auto-attested: the group verifies everyone's round just by playing it." | Yes | Yes | Partly: a padded starter index still buys 12 pts per round for three rounds until the auto-index takes over; one phone can post + attest four cards (I did). | Yes | 5 |
| Optimal strategy (my reading) | Post every round (5-pt floor beats nothing); play at least 2 a month; post 4+ so the best 4 count; the ceiling is 12 so consistency of "beat by 3+" matters more than a career low; as a 6.4 with low variance I will "torch" less often than a 15 — so the game structurally favours higher, more volatile handicaps; the Cup Final being "scored fresh" implies the regular season is only for seeding (guess). | — | — | Low — because Cup Final and tiebreaks are undefined I cannot plan December. | Partly | 4 |

Where a number is shown, does it show its work?
- Round card on the board → receipt sheet: "84 − 71.9 × 113 ⁄ 125 → 10.9 DIFFERENTIAL · YOUR NUMBER THAT DAY 6.4 · Against your number -4.5 — POSTED ANYWAY". **Yes** — best moment of the audit. But no points number on the receipt and no "counts for The Papago Grind: no (season starts Sep 5)".
- Standings "0 · — · 0" → "Priya · 0 ROUNDS · 0 PTS · No rounds this season yet" — shows nothing and contradicts the three rounds I just posted.
- Pot "$150 / $63 / $38" — not tappable; the arithmetic ($251 on a $250 pot) is wrong by a dollar of rounding and nobody says whether "Cup champs $150" is split across a squad.
- Bylaw rows — not tappable. "Attested", "scored fresh", "king" have no explanation.
- Skins "JORDAN → PRIYA $60" — netted; no per-skin breakdown (7 skins won × $15 − 9 skins lost × $5 = $60; I had to do it myself).

## JOURNEY D — FIRST ROUND (post-round form)

Before entering anything (`34-post-form.jpg`):
1. **How do I know what round I'm playing?** I don't. There is no "Week 1 / September" framing, no fixture; it is a blank card with a date field pre-filled from an old draft (2026-08-25).
2. **Who am I playing?** Nobody. The after-the-fact form is solo. (The LIVE door is where you pick a foursome.)
3. **What format?** Implicit stroke play against my own index. The form header says "POST A ROUND · YOUR INDEX 6.4".
4. **What are the rules?** The Point-bands table sits under the form — good. "Your best 4 each month count toward your squad" — good.
5. **How are handicaps applied?** "vs your index" in the preview; the 95% allowance in the bylaws is nowhere.
6. **What do I need to enter?** Course (search / recent chips), tee (rating & slope), 18 or 9 holes, Front 9 gross, Back 9 gross, date; optional scan / photo.
7. **What counts toward the season?** "Gross + tee, 20 seconds · counts on your card and in every league" — which turned out to be untrue for the league this week.
8. **What counts toward side games?** Nothing here; side games only exist in the LIVE flow.
9. **If something goes wrong?** "Start over — clear this card" before posting. After posting: only "Delete round" on the You page (native confirm "It leaves your card and any league standings it counted toward"). No edit.
10. **Do I understand what I earned?** Preview: "LEAGUE POINTS THIS ROUND 12 · You torched your number by 5.0. Sandbagger alert." Result: "74 · beat your number by 5.0 · COUNTS ON YOUR CARD". Standings: 0. So: no.

Good round vs bad round: 74 → "+5.0 · TORCHED IT" (12 in preview); 84 → "-4.5 · POSTED ANYWAY" (5 in preview). The band table lets me plan (a 3-shot cushion is worth 12; anything worse than 3 over is 5) — but the app never shows the points on the receipt or the board card, and the league shows zero for both, so I could not verify a single point actually landing.

What I would tell a friend about what just happened (verbatim): "I posted a 74 from the Champions course, rating 72.4 slope 133. The app worked out a 1.4 differential, compared it to my 6.4 and said I beat my number by 5.0 — top band, 'torched it', which the form said is 12 points. Then the result screen just said 'counts on your card', and the league standings still show me at zero, so as far as I can tell it earned nothing for the league — I think because the season hasn't started, but nothing in the app says that. The 84 was 4.5 over, 'posted anyway', 5 points on paper, also zero in the standings."

## SIDE-GAME AUDIT
- **Discoverable?** Yes, but only through the ⊕ → "LIVE · Play now — score the group live · Hole-by-hole · match play, Wolf & the settle-up". Also visible passively as board cards ("Match play: Priya def. Casey 2 UP THRU 3 · $5 on the line").
- **What they are:** Match play (singles or 2v2 net best ball, stake per side), Wolf (rotation, $/point), Skins (low net, carry-overs, $/skin), Sunningdale Rules (no handicaps, 2-down stroke), or "Just score". One game per round.
- **How they work:** the setup blurb is excellent and specific ("Strokes off the low man (Priya): Casey gets 9 — the 9 hardest holes · Marcus gets 6: holes 3, 6, 9, 16, 17, 18"). The live panel updates every hole ("HOLE 10 WORTH 3 SKINS · THRU 9 … JORDAN → MARCUS $35"). Settlement is netted and posted to the board.
- **Effect on the season:** none on points; every complete card auto-posts to the season ("ONE FINISH — EVERY MEMBER'S CARD POSTS"). Nothing on the board card links the side game to standings.
- **Would a round matter when out of contention?** Yes — this is the mechanic that would keep me playing: skins at $5 mattered more to me than the season points did today.
- **Social?** Yes: settlement card, "Share the settlement — no account needed", guests get "a recap text with their scorecard and an invite".
- **Integrated or bolted on?** Integrated in the flow (one door, scores post), but the money is NOT on the "books": the Pot tab still says $0 and lists only pride stakes; the $60 lives only as a board card. So "Cup Season keeps the books" is true for the pot and false for the games.
- **Does the app encourage setting one up?** Weakly — the ⊕ door's LIVE card is first and orange-dotted; the tee-sheet form has no "game" field; Home has no "put a game on Saturday" nudge.
- **Friction:** course search returned the same course twice; 13 tees to scroll; scoring is one tap to open at par then ± (fast). "Finish round" needed a second decision ("Post 4 cards to the season" vs "This one was casual — post nothing"). Two 502 errors in the console at finish.
- **Setup with league members:** trivial — chips for Jordan/Sam/Casey/Marcus are right there. Results were visible on the league board within seconds ("Priya took 7 skins and $60 · Priya 7, Casey 3, Marcus 6 · $5 a skin · 2 carried died · SCORECARD ›").

## RIVALRY
- Can I see who I am beating and by how much? Only the flat standings table (Player / R / Avg vs index / Pts), all zeros today. No head-to-head, no "you vs Casey" record, no gap-to-leader, no per-player page (tapping a row gives "0 ROUNDS · 0 PTS · No rounds this season yet"). Find golfers shows "Casey @casey · Phoenix, AZ · Requested" and nothing else.
- "Next round matters because…" signal: none. The Home tile says "NEXT · SAT 07:30 · PAPAGO GOLF COURSE" and "Buddy's playing Jordan · sat", the floor pill says "Month closes in 2 days" — but nothing says "post one more to lock your 4th counter" or "Casey is 3 points ahead".
- Something that would make me want to beat a specific person: the pride stake I posted ("Priya v Casey — Low net of September. Loser gives 2 a side next time") and the match-play card. Those are user-created; the app itself never picks a rival for me.

## STRATEGIC VERDICT (competitive golfer)
What would keep me for a season: the live side games (skins/match/Wolf with real strokes and a settlement card), the receipts that show the differential math, the squad floor that makes teammates nag each other, and a real Cup Final if I understood it. What's missing: any explanation of the Cup Final / tiebreaks / what "scored fresh" means; a head-to-head or gap-to-leader view; honesty about when a round counts (pre-season rounds silently count for nothing); a visible role for the 95% allowance; a reason for a 6.4 to believe the 12/9/7/6/5 bands aren't rigged for 20-handicaps; and any strategic depth beyond "post every round". Right now the best-4-a-month + 5-point floor means the season is a participation contest with a variance bonus — fine for a social group, thin for someone who plays 60 rounds a year and wants to out-think people.

## JOURNEY A — RE-ANSWERED AT THE END (what changed)
1. **App:** a season-long friends league: you post real rounds, each scores 5–12 points against your own handicap, best 4 a month count for your squad, plus a live scorer for skins/match play/Wolf that settles the money and posts the cards. *(Changed: completely.)*
2. **Primary action:** Post a round — the orange ⊕ in the middle of the nav. *(Same guess, now confirmed.)*
3. **Season:** a fixed window ("Sat Sep 5 → Sat Jan 2 · 17 wks") whose months are the scoring units (best 4 / floor 2 per month), ending in a 4-week "Cup Final". *(Changed.)*
4. **League:** a group with a "Pro" (Casey), locked "bylaws", two blind-drawn "squads", a pot and a board. *(Changed.)*
5. **Cup:** still fuzzy — the "Cup Final" is the last four weeks "scored fresh", and "Cup champs" take 60 % of the pot; I assume the squad that wins the final four weeks. *(Barely changed — this is the app's name and I still can't define it.)*
6. **Competing for:** a $250 pot split "60 / 25 / 15 · champ / 2nd / king" ($150 / $63 / $38), trophies for the display case, pride stakes. *(Changed.)*
7. **Against whom:** my squad vs the other squad; individually everyone for "Points King / Most Improved / Iron Man"; and whoever I play in side games. *(Changed.)*
8. **Rounds:** gross + tee (rating/slope) + date → differential → band vs my index; 9 holes post at half value; or score live with attestation; or scan the card. *(Changed.)*
9. **After a round:** a band ("torched it"), a board card, badges, a share card; supposedly points and best-4 counting once the season starts; my index gets recomputed after 3 rounds. *(Changed.)*
10. **Different from just playing with friends:** a standing table with a participation floor, a money ledger, and the live games settling themselves. *(Changed.)*

## 30-SECOND EXPLANATION (verbatim)
"Cup Season is a season-long golf league app for your friend group. Everyone posts their real rounds from wherever they play, and each round scores 5 to 12 points based on how you did against your own handicap — beat your number by three and you get 12, a bad day still gets 5, so the only way to hurt your team is not to play. Your best four rounds a month count for your squad, you owe at least two a month, and there's a $50 buy-in that pays the winning squad, the runner-up and the top individual points scorer. The last four weeks are a 'Cup Final' that's scored fresh — I honestly don't know what that means yet. On the course you can run skins, match play, Wolf or Sunningdale live in the app and it settles the money hole by hole."

## PERSONA VERDICT
**Does Cup Season feel strategically compelling enough to care about all season?** Not yet — 5/10. The live games and the receipts are genuinely good and I'd use them every Saturday; the season layer is a participation contest with rules I can't fully find (Cup Final, ties, allowance), it shows me zero for three posted rounds without saying why, and it never gives me a rival or a "this round matters because" line.

Scores (1–10): concept clear 6 · setup clear 5 · rules clear 4 · easy to pick up 7 · gameplay compelling 5 · side games compelling 8 · stakes meaningful 5 · would invite 6 · would pay 5 · would play again 7.

## USER ASSUMPTION / ACTUAL PRODUCT BEHAVIOR pairs
- USER ASSUMPTION: the invite link would show me the league (who's in, the stakes, when it starts) before asking for my email. / ACTUAL: the door only says "You're invited to The Papago Grind. Enter your email and you're in." The $50 buy-in is disclosed after joining.
- USER ASSUMPTION: the big orange "Lock it in and invite your crew" on my Home is something I (a player) am supposed to do. / ACTUAL: it opens the Pro's "Create your league" wizard ending in "Lock the bylaws & form the squads"; the Pro is Casey.
- USER ASSUMPTION: the "You" tab shows my card. / ACTUAL: from Home it opens the half-finished "Create your league" wizard; from Clubhouse it shows my card.
- USER ASSUMPTION: "LEAGUE POINTS THIS ROUND 12" means the league gets 12 points when I post. / ACTUAL: "COUNTS ON YOUR CARD"; standings 0; "No rounds this season yet".
- USER ASSUMPTION: "beat it by 3+" means three strokes under my course handicap. / ACTUAL: it is index minus differential (1.4 vs 6.4 = 5.0), a slope-adjusted number.
- USER ASSUMPTION: "+5.0 vs your index" is 5 over. / ACTUAL: + means better (green); −4.5 means worse (red).
- USER ASSUMPTION: "HANDICAP ALLOWANCE 95%" reduces the strokes I give in live games or the number I'm scored against. / ACTUAL: no visible calculation applies it (live strokes looked like 100 % off the low man; season preview used the raw 6.4).
- USER ASSUMPTION: "Month closes in 2 days" and the floor warning mean I owe two rounds by Aug 31. / ACTUAL: the season starts Sep 5; the August "month" is apparently irrelevant.
- USER ASSUMPTION: "Squads LIVE NOW — CAPTAINS READY" means squads exist. / ACTUAL: "Squads are forming · The Pro has the list"; both squads empty; no captains.
- USER ASSUMPTION: "See the squads" shows me the two teams. / ACTUAL: opens the Pro's "Form squads · blind draw" tool with tappable player chips and no back button.
- USER ASSUMPTION: the skins money would land on "the books" with the pot. / ACTUAL: Pot tab unchanged; the $60 exists only as a board card.
- USER ASSUMPTION: "Cup champs $150" is what I win. / ACTUAL: unknown — probably a squad share; never stated.
- USER ASSUMPTION: "Share the card" opens a share sheet or copies a link. / ACTUAL: nothing visible happened.
- USER ASSUMPTION: deleting a round removes what it earned. / ACTUAL: the "Broke 80 / 90 / 100 · 74 gross" badges stayed after the 74 was deleted.
- USER ASSUMPTION: "Schedule" is a tab in the league room. / ACTUAL: it navigates to a separate calendar page with a "← HOME" link.

## GLOSSARY (product terms met, what I think they mean, confusing?)
- **Cup / Cup Final** — the last four weeks of the season, "scored fresh"; champions take 60 % of the pot. *Confusing* (never defined).
- **Season** — a fixed window (Sep 5 → Jan 2, 17 weeks) with monthly caps/floors. Clear once inside.
- **League** — a friend group with a Pro, bylaws, squads, pot and board. Clear.
- **Squad** — one of two blind-drawn teams. Clear-ish; formation unexplained to players.
- **The Pro** — the league organizer (Casey). Clear from context; never defined.
- **Bylaws** — the locked rule set (structure, allowance, cap, floor, buy-in, split, dates). Clear as a table, opaque row by row.
- **Preset · Casual / Standard / Cutthroat** — rule bundles. Seen only inside the wizard I shouldn't have been in.
- **Handicap allowance 95 %** — presumably the % of course handicap used somewhere. *Confusing* (never applied visibly).
- **Verification · Attested** — rounds vouched for by the group ("auto-attested" when scored live). *Confusing* as a bylaw value.
- **Counting cap · Best 4 / mo** — only your best four rounds a month count for the squad. Clear.
- **Participation floor · 2 / mo · −5 sqd pts / round short** — post at least two a month or the squad loses 5 per missing round. Clear.
- **Season bye** — the first missed floor is forgiven. Clear, but only in one sheet.
- **Short months are waived** — partial months don't have a floor. Clear-ish.
- **Pot / on the books / pot sheet** — the buy-in ledger the app tracks but never holds. Clear.
- **Pot split · champ / 2nd / king** — 60/25/15. "king" = Points King. *Confusing* abbreviation.
- **Points King / Most Improved / Iron Man** — individual side races (most points / index drop since Week 1 / most rounds). Clear from the footnote.
- **Torched it / Beat your number / Played to it / A little loose / Posted anyway** — the five point bands (12/9/7/6/5). Clear.
- **Your number** — your handicap index. Clear.
- **Differential** — (gross − rating) × 113 / slope. Clear on the receipt.
- **Starter (index) / building** — a manual index that the app overwrites after 3 rounds. *Confusing* for someone with a real GHIN.
- **Board** — the league feed (rounds, joins, stakes, results, chat). Clear.
- **Clubhouse** — one league's room (Standings/Board/Schedule/Pot/Album/League). Clear.
- **The ⊕** — the Post button: before / during / after a round. Clear after the "four places" sheet.
- **Tee sheet** — planned rounds on a calendar, visible to buddies and league. Clear.
- **Stake (pride, on the books)** — a non-money bet between members ("Loser hosts", "Strokes next time"…). Clear.
- **Buddy / invite link / claim link** — mutual follow / league join link / hand a round to a guest. Clear from the sheet; "claim" unclear elsewhere.
- **Event · The Ryder / A Major / Bracket** — short-form competitions with their own trophy. Clear-ish.
- **Live round / Group phones / Scrap this round** — hole-by-hole scorer; multi-phone scoring; abandon. Clear.
- **Skins · carried / died** — tie carries to the next hole; unclaimed at 18 "died". "2 SKINS DIED CARRIED" is *confusing* wording.
- **Off the low man** — strokes are the difference from the lowest course handicap in the group. Clear.
- **Sunningdale Rules** — no handicaps; 2 down earns a stroke. Clear from the blurb.
- **Wolf** — rotation game; explained in the blurb. Clear.
- **Blind draw / Form squads / The hat** — random squad assignment. *Confusing* when shown to a player as an editable screen.
- **Display case / The record / silverware** — badges and trophies. Clear.
- **FORM (two dots)** — unexplained on the card. *Confusing.*
- **R** (standings column) — probably rounds. *Confusing* (unlabeled).
- **Avg vs index / Index move** — average of "vs your number"; change in index since week 1. Clear-ish.
- **Month closes** — the monthly cap/floor assessment. Clear-ish, but wrong month shown.
- **Ball marker** — the avatar icon (The Saguaro…). Clear.
- **GHIN #** — optional reference; "we never resell or verify it". Clear.
- **Scored fresh** — *unknown*.
- **Marco** (board: "Casey def. Marco") — unknown person; not in the member list (Marcus is). *Confusing.*

## CONFUSION DEBT (things the app assumes I already know)
1. What a "cup" is and how the Cup Final works / who plays it / what "scored fresh" means.
2. How ties are broken anywhere (standings, Points King, skins, match play).
3. Where the 95 % handicap allowance applies.
4. Whether the league scores against my real index or the app's 3-round number, and what happens on the switch.
5. That rounds before the season's first tee (Sep 5) count for nothing in the league.
6. Which month the "Month closes in 2 days" pill refers to and why it shows before the season.
7. What "Attested" verification actually requires (a second phone? a tap? nothing?).
8. That "Cup champs $150" is (probably) split across a squad.
9. What "the Pro" can and cannot do, and that players see the Pro's buttons.
10. How squads are drawn, when, and whether I can influence it.
11. What the "R" column and the "FORM" dots are.
12. That side-game money is "settled between you" and never reaches the pot ledger.
13. That "Share the card" needs a device share sheet.
14. That the differential, not strokes, drives "beat by X".
15. Why a 6.4 and a 22 get the same 12 for "beat by 3+" when the 22's spread is twice as wide.

## ISSUES (OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION)
See the structured list returned with this report (ids C-01 … C-38); each carries the screenshot evidence named above. Highest-impact, in my order: C-05 (pre-season rounds show 12 pts then land as zero with no explanation), C-03/C-04 (a player gets the Pro's lock CTA and the You tab is hijacked by the wizard), C-12/C-11 (Cup Final and ties undefined), C-07/C-26 (what "beat by 3" is and where 95 % goes), C-29 (one phone posts and attests four cards), C-33 (no rivalry surface), C-10 (bands favour high-variance handicaps), C-28 (side-game money off the books).
