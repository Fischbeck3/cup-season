# Blind UX audit — Agent 7: Retention / Mid-season Observer

**Persona:** member of a friend group whose season has been running for weeks. Opens the app with no prior context.
**Account:** jerecho@fischbeck3.com (existing account, real league) — STRICT READ-ONLY.
**Session:** `obs` (phone-sized headless browser at http://127.0.0.1:8791/).
**Date:** 2026-08-29. All timestamps UTC.

Screenshots: `../screenshots/obs/`

---

## Timeline

| Time (UTC) | Event |
|---|---|
| 13:18:42 | Session started. |
| 13:18:5x | Door loaded. `01-door.jpg`. Copy: "CUP SEASON — Rally your crew. Post real rounds. **Take the cup.**" Buttons: **[Continue with email]** (orange), **[I have an invite code]**. Footer: "By continuing you agree to the Terms & Privacy Policy." and a raw `v23 · __CS_VERSION__` string. |
| 13:19:0x | Tapped "Continue with email" → an email field with placeholder `you@email.com` and a **Go** button appeared inline under the button. `02-email.jpg` |
| 13:19:23 | Filled email, tapped **Go**. Screen: a second field `CODE FROM EMAIL` + **Verify**, green monospace status "Sent to jerecho@fischbeck3.com. Type the sign-in code from the newest email.", and "Resend code (26s)" countdown. `03-code-entry.jpg` |
| 13:20:05 | No email. (Other testers' brand-new addresses at the same domain received "Confirm your email address" mails within ~30 s of their requests — 13:19:51, 13:20:52.) |
| 13:21:03 | Tapped **Resend code**. Status: "Fresh code sent to jerecho@fischbeck3.com — the newest email wins." |
| 13:23:09 | Still no email. Console: only a deprecation warning from the auth library. |
| 13:25:16 | Tapped **Go** a third time. "Sent to jerecho@fischbeck3.com…" again. |
| 13:26:12 | Still nothing addressed to this account. The last email this address ever received from the app was 2026-08-28 11:20 UTC. |
| 13:29–13:31 | **CORRECTION.** The codes HAD arrived — at 13:19:25, 13:21:04 and 13:25:17, i.e. ~2 s after each request. My mail-search tool was truncating the long existing thread to its first five messages; fetching the thread directly showed all sixteen. The app's delivery was instant; the 12-minute delay was entirely my tooling. Recording it honestly so nobody chases a phantom email bug. (What a REAL user would experience: code within seconds.) |
| 13:31:57 | Typed the 8-digit code. The field auto-submitted on the 8th digit — my "Verify" tap found nothing to tap because the button had already gone. Page reloaded signed-in. |
| 13:32:06 | **Home** loaded. `04-home-first.jpg`, `05-home-full.jpg`. Sign-in total, as a user would feel it: ~30 s (email → code → in). |

---

## Screen: HOME (signed in, first view) — `04-home-first.jpg` / `05-home-full.jpg`

Exact copy top to bottom:
- Header: search icon (accessible name "Find golfers"), "Cup Season" wordmark.
- Three equal pills: **[Start a league] [Start an event] [Join a league]**
- Hero card (gold left rule): `FELLAS · WEEK 6 OF 26` · huge gold **1st** · pill `— HELD` · "You lead by **22 points** over **Jade**." · divider · `AUG FLOOR 1/2 ▬▬▬▬░░░ 1 MORE · 2D`
- Three tiles: `LEAGUE / 1st / FELLAS` · `NEXT / FRI / QUINTERO GOLF …` · `BOARD / Open / THE LEAGUE`
- Pill: `MONTH CLOSES in 2 days`
- Section: `— AROUND YOUR BUDDIES` … `THE BOARD ↗`
- `THIS WEEK` → one round card: **Galen** · 🔥 Personal best · **79** GROSS · `LONE TREE GOLF CLUB · BLUE · AUG 23`, with a 🔥 reaction button and a "More reactions" button. The orange **+** floating button physically overlaps this card's course line ("LONE TREE GOLF CLUB [+] · AUG 23").
- Story row (checkered flag): "Galen broke 80 for the first time — a 79. That one goes on the wall." `WHO'S THE BITCH? · AUG 24`
- `SHOW EARLIER · 18`
- Bottom nav: HOME · CLUBHOUSE · (+ = "Post a round") · YOU
- Hidden status text in the accessibility tree: "Switch groups anytime from Home" — nothing visible on Home looks like a group switcher.

**3 s:** big gold "1st", "You lead by 22 points over Jade." — I'm winning, Jade is second.
**10 s:** it's week 6 of 26 in a league called Fellas; something called a "floor" for August is 1/2 and I have 2 days; a month "closes" in 2 days; next round Friday at Quintero; Galen shot a personal best 79.
**30 s:** I can tap the League tile, the Next tile, the Board tile, the board link, the round card, the 🔥, and the + to post. I can also start/join leagues (why are these the FIRST thing on a mid-season member's home?).
**Still don't understand after exploration (to be revisited):** "HELD" (held what — position? a hold on me?), "floor 1/2", "month closes" (what closes? what happens?), why the board story is signed "Who's the bitch?" — a second league, apparently, that is not represented anywhere in the hero/tiles.

USER ASSUMPTION: "HELD" means I held 1st place from last week (no movement).
ACTUAL PRODUCT BEHAVIOR: unknown yet — no tooltip, not tappable in the tree.

USER ASSUMPTION: "AUG FLOOR 1/2 · 1 MORE · 2D" means I must post 2 rounds in August, I have 1, and 2 days remain.
ACTUAL PRODUCT BEHAVIOR: unknown yet — no explanation on Home of what happens if I don't.

USER ASSUMPTION: I'm in two leagues ("Fellas" and "Who's the bitch?") because board stories carry both names.
ACTUAL PRODUCT BEHAVIOR: Home shows only Fellas; no visible switcher.

Console at boot (not visible to a user, but recorded): `[live-resume] server query failed: Could not embed because more than one relationship was found for 'live_rounds' and 'live_round_players'`, plus two auth-library warnings ("Multiple GoTrueClient instances detected").

## Screen: CLUBHOUSE › Fellas › Standings — `06-league-tile.jpg`, `07-league-full.jpg`, `08-club-top.jpg`, `09-club-mid.jpg`
(reached at 13:33:13 with 1 tap from Home's "League 1st FELLAS" tile; the CLUBHOUSE tab lit up — so the tile and the tab are the same place)

Exact copy, top to bottom:
- `— YOUR GROUPS` chips: **Fellas / HERE** (green outline) · **Who's the bitch? / IN SEASON**
- Card: **Fellas** · Season live · `Mon Jul 20 → Mon Jan 18 · 26 wks` · `THE PRO · JADE`
- Segmented control: **Standings** · Board · Schedule · Pot · Album · League
- Thin gradient bar, right-aligned red label `3 days left in August`
- `— SEASON RACE · THE CLIMB` → list: `01 [flag icon] Jerecho F… [sparkline] LOCKED 32` / `02 [icon] Jade LOCKED 10` with sub-line "Jade 22 behind you" → caption `EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS` (the + button sits on top of "2 CONTENDERS")
- `— STANDINGS` · "Jerecho Fischbeck lead by 22 · Jade 22 back." Table `PLAYER · TREND · Δ WK · PTS`: `01– Jerecho Fischbeck 6 ROUNDS [line] +10 32` / `02– Jade 2 ROUNDS [flat line] 0 10`
- Caption `JERECHO FISCHBECK HAS LOCKED A CUP SEED`
- 2×2 tiles: `SEASON W6 / 26 · Week closes Sun · 1d` · `THE POT $150 · 0/2 buy-ins in` · `YOUR INDEX 11.3 · ▼ 1.1 this season` (green) · `COUNTING ROUNDS 1 / 4 · ●○○○ · August · your best 4 count`
- Orange-rule card `NEXT UP · AUGUST` "Post 1 more round this month — best 4 count, you've posted 1." with a **[Live round]** button
- Gold card `ON THE LINE $150` "CHAMPS $90 · RUNNER-UP $38 · POINTS KING $23 · $0 COLLECTED →"
- `— THE INDIVIDUAL RACE · EVERY PLAYER` three tiles: `Jerecho · POINTS KING · 32 PTS` · `— · MOST IMPROVED · NEEDS 2+ ROUNDS` · `Jerecho · IRON MAN · 6 RDS`; table `PLAYER · R · AVG VS INDEX · PTS`: `01 Jerecho Fischbeck 6 -4.0 32` / `02 Jade 2 -13.8 10` (both red)
- Footnote: "Points King takes 15% of the pot at season's end. Most Improved is index drop since Week 1; Iron Man is most rounds posted. All three run in parallel with the squad race — bylaws §4."
- Buttons: **[Code · MYCUUVMM] [Add golfers]**

**3 s:** the group chips, "Fellas · Season live", the segmented control. The race itself is below the fold on a phone.
**10 s:** two names, I'm 01 with 32 and LOCKED, Jade 02 with 10 and LOCKED. "Everyone advances."
**30 s:** pot is $150, nobody has paid, I'm 11.3, I need 1 more round in August, I'm Points King and Iron Man.
**Still don't understand:** what "LOCKED" locks (a "cup seed" — what is a cup seed?); "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" (advances to what?); why "AVG VS INDEX" is negative and red for both of us while my rounds "beat my number"; "bylaws §4" (a document I cannot find); "Δ WK +10" (points gained this week? my last round was Aug 16, two weeks ago); why the "squad race" is mentioned in an "Individual — no squads" league; why "0/2 buy-ins in" is shown while nothing on this screen says what to do about it.

USER ASSUMPTION: "LOCKED" = my place in the standings can't change.
ACTUAL PRODUCT BEHAVIOR: the caption says I "locked a cup seed" — apparently a seat in a later "cup"; the standings themselves remain live.

USER ASSUMPTION: "Avg vs index -4.0" means I'm averaging 4 better than my index (golf convention: minus = under).
ACTUAL PRODUCT BEHAVIOR (from the receipt + explainer, see below): minus = WORSE than index. The sign is the opposite of what a golfer reads.

**Receipt sheet** (tap on my row, 13:34:21) — `10-my-row.jpg`: "Jerecho Fischbeck · 6 ROUNDS · 32 PTS" then six lines `2026-08-16 +2.6 vs index · 9 PTS / 2026-07-29 -5.1 vs index · 5 PTS / 2026-07-26 -14.0 vs index · 5 PTS / 2026-07-24 · 9 HOLES · BUMPED -6.2 vs index · 3 PTS / 2026-07-24 -1.2 vs index · 6 PTS / 2026-07-20 +0.0 vs index · 7 PTS` and "Bumped rounds still happened — a better round took their monthly slot. A better round always bumps your worst counter." No courses, no gross scores, no total line; I had to add 9+5+5+6+7 myself to check that 32 excludes the bumped 3. ISO dates (`2026-07-24`) in a sheet whose sibling screens say "Jul 24".

## Screen: CLUBHOUSE › Fellas › Pot — `12-on-the-line.jpg` (reached by tapping the "On the line" card; it switched the segmented control to Pot rather than opening a sheet)
"SEASON STAKES · The pot **$150** · 2 × $75 · $0 collected · 2 still owe · $90 Cup champs · $38 Runner-up · $23 Points king · Cup Season keeps the books. Buy-ins and payouts move friend-to-friend. We just make sure nobody argues at the bar. · Buy-ins · 0/2 in · **[Jade ✓] [Jerecho Fischbeck ✓]** · The other stakes · pride, on the books · **[Post a stake]** · No stakes on the books. The cookout isn't going to bet itself."
- "0/2 in" and "2 still owe" sit directly above two names with ✓ marks. I read the ✓ as "paid". Did not tap (they are buttons; tapping might mark a payment).

## Screen: "Schedule" — `13-sub-Schedule.jpg` (13:35:44)
Tapping the **Schedule** segment did NOT stay in the Clubhouse: it navigated to a full screen "YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES'" with a `← HOME` link and no way back to the Fellas Clubhouse except the bottom tab.
- `IN YOUR CREW'S PLANS`: card "**Galen** BUDDY · FRI SEP 4 · QUINTERO GOLF AND COUNTRY CLUB · you lead 1–0 · YOU'RE IN · "Major" · ON THE TEE SHEET"
- Month grid AUG 2026 with dots on 1, 2, 3, 9, 16, 23, 29, 30, 31; legend `● ON THE TEE SHEET ● LEAGUE MATE ● SEASON DATE` — the three dot colours are nearly indistinguishable on the dark grid.
- "Tap any day to put a round on the tee sheet." + big orange **[Put a round on the tee sheet]**
- `ON THE TEE SHEET` "Nothing on the tee sheet for Aug. Put one up: league mates and buddies see it the moment you do." (but the Sep 4 plan above IS "on the tee sheet")
- `WEEK BY WEEK` a card listing `WK 4 / WK 3 / WK 2 / WK 1` with nothing beside them — four empty rows; we're in week 6.
USER ASSUMPTION: "you lead 1–0" is my head-to-head record against Galen. "Major" is a nickname for the game. Galen is a "BUDDY" not a league mate.
ACTUAL PRODUCT BEHAVIOR: unexplained on this screen.

## Screen: CLUBHOUSE › Fellas › Album — `17-sub-Album.jpg`
"THE ALBUM · EVERY ROUND PHOTO THIS SEASON · Photos land here when rounds carry them — add one from the Post card." Empty.

## Screen: CLUBHOUSE › Fellas › League — `18-sub-League.jpg`, `21-bylaws-open.jpg`
- "Members & invites · 2 PLAYERS [View]" · "🔗 Share the season · A public page — the standings so far, no account needed [Link] [✕]" · "Squads · Individual league — no squads [View]"
- Collapsed disclosure `▸ LEAGUE RULES & PRO SHOP` (the bylaws are hidden until you find and tap this). Opened: "THE BYLAWS · LOCKED AT FIRST TEE": `STRUCTURE Individual — no squads · Squad formation Blind draw · PRESET Standard · HANDICAP ALLOWANCE 95% · VERIFICATION Attested · COUNTING CAP Best 4 / mo · PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short · BUY-IN $75 / player · POT SPLIT 60 / 25 / 15 · champ / 2nd / king · SEASON 6 mo · Mon Jul 20 → Mon Jan 18 · 26 wks · CUP FINAL Final 4 weeks · from Tue Dec 22 · scored fresh` → **[How scoring & handicaps work →]**
- "THE PRO SHOP · CUP SEASON MEMBERSHIP · COMING AT LAUNCH · THE PILOT RIDES FREE · SOON Custom rules, every dial unlocked · SOON Live draft night with pick timer · SOON Trades & waiver wire · SOON Multi-season history & records · [Coming at launch]"
- **This is the ONLY place the app told me the season ends with a "Cup Final · final 4 weeks · scored fresh."** Home says "You lead by 22 points." Nowhere on Home or Standings does it say that lead is (apparently) a seed and the trophy is decided in a fresh four-week final. Three taps + one disclosure deep. Rules failure for the core question "what do I need to do to win?"
- "Squad formation · Blind draw" printed for a league that says "no squads" twice.
- "−5 sqd pts / round short" — abbreviation, and "sqd" in a no-squad league.

**"How scoring works" sheet** — `22-how-scoring2.jpg` (13:38): sections "YOUR NUMBER", "EVERY ROUND → CUP POINTS", "WHAT COUNTS", "THE MONEY". Bands: "Torched it · beat it by 3+ · 12 pts / Beat your number · by 1–3 · 9 pts / Played to it · within 1 · 7 pts / A little loose · 1–3 over · 6 pts / Posted anyway · rough day · 5 pts". "Miss it once and your season bye covers you automatically — life happens; the floor bites from the second miss." "The pot is on the books — Cup Season keeps the ledger and shows a settlement card; the money moves between you."
- Says nothing about the Cup Final, seeds, "locked", or tiebreaks.
- Talks about "your squad" four times; this league has no squads.
- CONTRADICTION: Home's card for my Aug 16 round says "Beat your number by 3.3" — by this table that is "Torched it · 12 pts". The receipt says the same round is "+2.6 vs index · 9 PTS". Two numbers, two bands, one round.

**Members & invites sheet** — `23-members.jpg`: "2 PLAYERS · CODE MYCUUVMM · Jade · THE PRO @jade · INDEX 10.0 · Jerecho Fischbeck @jerechofischbeck · INDEX 11.3 · [Marker here] [Share the invite link]".

## Screen: CLUBHOUSE › Fellas › Board — `19-sub-Board.jpg`
Header "THE BOARD · ROUNDS LAND HERE AUTOMATICALLY · OPEN ↗". Day-grouped feed, oldest first (Jul 20 at the top, Aug 27 at the bottom) with a "Message the league…" box + **Send** at the bottom.
Entries (verbatim): `◆ Jerecho Fischbeck joined the league` · `◆ JERECHO FISCHBECK IS NOW @jerechofischbeck` · `Jerecho Fischbeck posted 35 gross · 9 holes · Palo Verde Gc · Back · Diff 17.8` · `◆ Jerecho Fischbeck's number now comes from their scores — 12.2 → 12.6` · `Jerecho Fischbeck posted 90 gross · Arizona Biltmore Cc — Links · Copper · Diff 25.6` · `Jade posted 86 gross · … · Diff 21.5` (🔥 1) · `✦ Jade broke 90 for the first time — 86 gross` · `◆ Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units` · `Jerecho posted 90 at Raven Golf Club-Phoenix · Silver.` · `Jade posted 99 at Raven Golf Club-Phoenix · Silver.` · `◆ July closed — Ledger posted · Partial month, floors waived` · `Jerecho posted 85 at Troon North Golf Course — Pinnacle Course · Gold.` · `✦ Jerecho set a personal best. New number to chase.` · `Jerecho posted 83 at Cave Creek GC.` · `Jerecho posted 85 at Encanto GC.` Each round row has 🔥 / + / ⚑ / 💬 buttons.
- **DATA CONTRADICTION:** the board shows me posting **83 at Cave Creek and 85 at Encanto on Thu Aug 27**, but Standings says "you've posted 1" this month, Home says "AUG FLOOR 1/2 · 1 MORE", and my receipt's newest round is Aug 16. Either the two Aug 27 rounds don't count (no reason shown) or the standings are stale. A member would not know which.
- Date drift: board says the Raven round was "Tue · Jul 28"; the receipt lists it as 2026-07-29.
- Two post formats for the same event type ("posted 90 gross · … · Diff 25.6" vs "posted 90 at … · Silver.").
- "Sunningdale", "bank", "6 units", "Will & Isaak" (not members), "Ledger", "floors waived", "Diff" — all undefined.
- Oldest-first ordering means the newest news is at the bottom, under the compose box.

## Timeline (continued)

| Time (UTC) | Event |
|---|---|
| 13:40:13 | Tapped the "Who's the bitch?" group chip. The segmented control stayed on "League" (carried over from Fellas); no Pot segment exists here. `24-wtb-standings.jpg` (actually its League tab), `27-wtb-League.jpg` |
| 13:40:21 | WTB › Board `25-wtb-Board.jpg`. 13:40:56 WTB › Standings `28-wtb-standings2.jpg` — I'm **2nd, "10 back of Galen"**, "Galen lead by 10 · Jerecho Fischbeck a good weekend back." |
| 13:41:25 | **You** tab `29-you-full.jpg`. |
| 13:41:53–13:42:13 | "How it works" cards: The four places `30-…png`, Leagues vs events `31-…png`, Buddies, invites and claims `32-…png`. |
| 13:42:56 | Home › **Next FRI** tile → the same global calendar screen as "Schedule" (`34-next-tile.jpg`). |
| 13:43:10 | Home › **Board Open** tile → a "League board" sheet for **Who's the bitch?** — and Home's hero had silently become "Who's the bitch? · week 4 of 13 · 2nd — HELD · 10 points back of Galen." (`35-board-tile.jpg`) |
| 13:43:23 | Home › "SHOW EARLIER · 18" expanded (`36-home-earlier.jpg`). 13:43:34 Galen's 79 round card sheet (`37-round-card.jpg`). |
| 13:44:13 | ⊕ → "GOLF · BEFORE, DURING AND AFTER THE ROUND" menu (`38-composer.jpg`); the "Post a round" form's first screen was also seen (`40-settings.jpg` — mis-labelled file; nothing typed, nothing posted). |
| 13:44:24 | 🔍 "Find golfers" sheet (`39-search.jpg`). |
| 13:45:11 | You › ⚙ "Card & settings" (read only; nothing changed) `41-settings2.jpg`. |
| 13:45:28 | Match play scorecard sheet `42-matchplay.jpg`; 13:45:45 Sunningdale scorecard `43-sunningdale.jpg`. |
| 13:46:29 | Clubhouse › Fellas › Jade's receipt `44-jade-row.jpg`: "2 ROUNDS · 10 PTS · 2026-07-29 -15.6 vs index · 5 PTS · 2026-07-26 -12.0 vs index · 5 PTS". Home hero back to Fellas (it follows the last group opened in the Clubhouse). |
| 13:47:26 | Home › "THE BOARD ↗" → "League board · FELLAS" sheet (`45-the-board-link.jpg`), rounds carry band + counting slot ("POSTED ANYWAY · BUMPED — OUTSIDE THE BEST 4 THIS MONTH -6.2 3 PTS"). |
| 13:47:39 | Navigated to `/?exit` → door (`46-signed-out.jpg`). Session stopped 13:47:49. Total ~29 min, ~12 of which were my mail-tool detour. |

---

## Screen: HOME after visiting the second league — `35-board-tile.jpg` context, `36-home-earlier.jpg`
Hero now: `WHO'S THE BITCH? · WEEK 4 OF 13` · **2nd** · `— HELD` · "**10 points** back of **Galen**." Tiles: `LEAGUE 2nd WHO'S THE BITC…` · `NEXT FRI QUINTERO GOLF …` · `BOARD Open THE LEAGUE` · `MONTH CLOSES in 2 days`. The August-floor bar that Fellas showed is absent here even though this league's bylaws carry the same 2/mo floor and I've posted 1.
- The feed ("AROUND YOUR BUDDIES") is cross-league and mixes both leagues' stories, each signed with its league name ("Jerecho set a personal best. New number to chase. FELLAS · AUG 16" then the same sentence again signed "WHO'S THE BITCH? · AUG 16" — duplicated story).
- Feed items after "Show earlier": Sam Reviewer 88 (Papago, "1.9 over their number"), Sam Reviewer 91, Galen 83 ("3.0 over their number"), **You · Beat your number by 3.3 · 85 · Troon North**, Galen 91 ("6.8 over"), "Galen's number now comes from their scores — 11.1 → 9.9", fedor.garrett 🔥 Personal best 75 (Atlantic Country Club — a buddy, not a league mate), two "July closed — Ledger posted · Partial month, floors waived" (one per league), "Match play: Jerecho Fischbeck def. Jade 4&3 · SCORECARD ›", joins, "JERECHO FISCHBECK IS NOW @jerechofischbeck", "Sunningdale: … SCORECARD ›", "Jade broke 90 for the first time — 86 gross".
USER ASSUMPTION: Home is "everything I'm in" (the app's own How-it-works says so).
ACTUAL PRODUCT BEHAVIOR: the hero shows exactly one league — the last one I opened in the Clubhouse. There is no switcher on Home; the hidden status text "Switch groups anytime from Home" is not true of anything visible.

## Screen: YOU — `29-you-full.jpg`
Card: photo, "Jerecho Fischbeck @jerechofischbeck · Phoenix, AZ · Lookout Mountain Golf Club · GHIN 12828189 · Member since Jul 2026", ⚙, big **11.3 HANDICAP INDEX**, `FORM ●●●●●` (five dots, last orange — unexplained), **[💬 Tell us how it's going →]**.
- `FOUNDER'S DESK` **[✏️ Field note] [📈 Open the desk]** "Notes land in the feedback ledger · the desk shows signups, activity, errors, feedback." (admin tooling on a member's profile — this account is evidently the app's founder; a normal member would presumably not see it, so I did not open it.)
- `YOUR DISPLAY CASE`: 📉 Personal best · Diff 9.3 · '26 · ⛳ First round · 🎯 Broke 100 · 88 gross · 🎯 Broke 90 · 88 gross · 📈 4-week streak. (A "Personal best" badge with a 📉 down-chart icon reads as a slump.)
- `THE RECORD` "No silverware yet — every season starts level."
- `LIFETIME`: Rounds posted 17 · Best vs index +3.3 · Avg vs index -1.6 · Cups & events 2 "Played in" (which two? not linked).
- `RECENT ROUNDS` (ISO dates, gross · diff, each with an ✕ = "Delete round"): 2026-08-16 Troon North 85 · 10.3 / 2026-07-29 Raven 90 · 17.1 / 2026-07-26 Biltmore 90 · 25.6 / 2026-07-24 Palo Verde 9 · 35 · 17.8 / 2026-07-24 Encanto GC 85 · 13. **[Post a round]**
- `YOUR BUDDIES` → Find golfers. `RIVALRIES · YOUR RECORD`: **Jade · 2 weeks head-to-head · 2–0** · **Galen · 1 week head-to-head · 1–0**.
- `THIS SEASON · WHO'S THE BITCH?` (changes to FELLAS after I reopened Fellas): Rounds posted 1 · Avg vs index +2.6 · Best round +2.6 · Index move —. With Fellas: 6 · -4.0 · +2.6 · **Index move ▲ 1.2** (green).
- `LEAGUE RECORD`: Fellas SEASON I · 1ST OF 2 · 32 PTS · Who's the bitch? SEASON I · 2ND OF 2 · 9 PTS.
- `HOW IT WORKS` five cards.
Three stories of one index: Standings tile "▼ 1.1 this season" (green), You "Index move ▲ 1.2" (green), board "12.2 → 12.6". Lifetime "Best vs index +3.3" vs "Best round +2.6 vs index · season" for the same Aug 16 round.

**Card & settings** (`41-settings2.jpg`, read-only): Your card / Settings toggle; name, city, home course, 14 ball-marker buttons ("NO. 2" pressed), photo, handle "moves once / 60 days", "Findable by All/Buddies/Nobody", GHIN # optional, **Save card**; Handicap index spinbutton + **Update index** ("Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed."); "Your leagues · Fellas PLAYER · MYCUUVMM · Who's the bitch? PLAYER · WHOS84L9".

## Screen: ⊕ composer, first screen — `38-composer.jpg`, form `40-settings.jpg`
Menu "GOLF · BEFORE, DURING AND AFTER THE ROUND": **● LIVE Play now — score the group live** (Hole-by-hole · match play, Wolf & the settle-up · every complete card posts at the finish. Guests welcome, no account needed.) · **Post a round — after you play** (Gross + tee, 20 seconds · counts on your card and in every league) · **Plan a tee time — before**. The form: course search with three recent courses (rating/slope shown), RATING / SLOPE boxes, YOUR CARD 18 holes / 9 holes, FRONT 9 GROSS / BACK 9 GROSS, DATE 08/29/2026, **Scan the card**, **Add a photo**, "Enter your card to see the score.", **Post round**, "Start over — clear this card". Below: `HOW THIS ROUND SCORES · LEAGUE POINTS THIS ROUND — Enter at least one nine.` "No league yet? The round still counts on your card — points apply in any league you join." and `POINT BANDS` (Beat your index by 3+ · 12 / Beat it by 1–3 · 9 / Within a stroke either way · 7 / Over by 1–3 · 6 / Rough day, posted anyway · 5) "Every posted round scores. Your best 4 each month count toward your squad — a better round always replaces your lowest, in real time." Nothing entered, nothing posted.

## Screen: Find golfers — `39-search.jpg`
"Search by name or @handle to add buddies" + six suggestions (Blake · Costa Mesa, fedor.garrett · Plymouth MA, Galen · Gilbert, Jade, lcsimpson12 · Scottsdale, Sam Reviewer · Phoenix).

## Screen: Scorecard sheets — `42-matchplay.jpg`, `43-sunningdale.jpg`
Match play: "MATCH PLAY · RAVEN GOLF CLUB-PHOENIX · SILVER · Jerecho Fischbeck def. Jade 4&3", hole-by-hole with Par and SI rows, gold-highlighted holes, "Jul 29 · Gold marks the holes that decided it. Every hole scored." Jade has a grey "G" tag (guest?). Sunningdale: four players, Will & Isaak tagged "G". These are the best-looking objects in the app — and they have no share/export control.

## Screen: League board sheet (from Home tiles) — `35-board-tile.jpg`, `45-the-board-link.jpg`
Per-round cards here are far richer than the Clubhouse board: "Galen · Lone Tree Golf Club · Blue… · 83 GROSS · POSTED ANYWAY · COUNTING #2 THIS MONTH · [-3.5] · 5 PTS" with 🔥 / + / ⚑ / 💬. Same feed, oldest first, compose box pinned at the bottom.

---

## JOURNEY E — MID-SEASON (answers from the app only)

| Question | Answer | Taps / time | Digging? |
|---|---|---|---|
| Who is winning? | Fellas: **me** ("1st · You lead by 22 points over Jade") — 0 taps, ~3 s. Who's the bitch?: **Galen** (19 to my 9) — but Home did not show this league at all until I opened it in the Clubhouse. | 0 / 3 s (Fellas); 3 taps, ~1 min (WTB) | Fellas no; WTB **yes** |
| How far behind am I? | Fellas: not behind. WTB: "10 points back of Galen" / "a good weekend back". | 3 taps | **yes** |
| Biggest threat? | Jade (the only other Fellas player); Galen (the only other WTB player). The app says "Jade 22 behind you" — it never says who threatens me; with two players it's trivial. | 0–3 taps | no (trivial) |
| Who am I ahead of? | Jade. | 0 | no |
| Rounds / weeks remaining? | "WEEK 6 OF 26" → 20 weeks, arithmetic mine; end date "Mon Jan 18" in Clubhouse. **Rounds remaining: never stated** — only "1 more" for the August floor and "best 4 count". | 0–1 tap | partly |
| What do I need to do to win? | **Not answered anywhere.** Home: "1 more" round in 2 days (to avoid a penalty, not to win). Bylaws (League › collapsed disclosure): "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" — so the 22-point lead is apparently a seed, and "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS". What the final is (4 weeks of points? a match?) and how a tie breaks: nowhere. | 4 taps + a disclosure, ~5 min | **yes — and still unanswered** |
| If I win my next round? | Not projected. From the band table (4 taps deep): +12 at most → 44. No "if you post X you…" line anywhere. | 4 taps | **yes** |
| If I lose? | Can't lose points by playing: "Posted anyway · rough day · 5 pts". You lose only by NOT playing: "−5 sqd pts / round short", first miss forgiven by a "season bye". | 4 taps | **yes** |
| Side games? | "THE INDIVIDUAL RACE": Points King (15% of pot), Most Improved, Iron Man. Live games on the board: Match play, "Sunningdale" (with "bank … 6 units"), and the composer promises Wolf & settle-up. A "Major" with Galen on Sep 4. "Rivalries · your record" on You. | 1 tap + scroll; 2 taps for You | partly |
| Which am I winning? | Fellas: Points King + Iron Man (Most Improved "needs 2+ rounds"). WTB: Galen holds all three. Head-to-head: 2–0 vs Jade, 1–0 vs Galen. | 1–2 taps | no |
| Money / stakes? | Fellas: $150 pot = 2 × $75, **$0 collected**, split $90 / $38 / $23 (champs / runner-up / points king). WTB: "None · Bragging rights". Home shows no money at all. | 1 tap + scroll | partly |
| Who to talk trash to? | Galen — he's 10 up on me, just broke 80 ("That one goes on the wall"), I lead him 1–0, and we play Friday. Jade — 22 down, 0 rounds in August, still hasn't paid. The app's closest surface is "Rivalries · your record" on You; no taunt/nudge/share control exists on any of these. | 2 taps | partly |

## JOURNEY F — SEASON FINALE
No finished league on this account (both are "SEASON I", both live). What the app says about the end:
- Bylaws line: "CUP FINAL · Final 4 weeks · from Tue Dec 22 · scored fresh" (Fellas) / "from Tue Oct 6" (WTB). Behind a collapsed disclosure.
- "Leagues vs events" explainer: "the endgame settles it: a Cup Final or the points table."
- Standings captions: "LOCKED", "HAS LOCKED A CUP SEED", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS".
- Pot: "$90 Cup champs · $38 Runner-up · $23 Points king". "Cup Season keeps the books … shows a settlement card; the money moves between you."
- You: "THE RECORD · No silverware yet — every season starts level." Display-case badges are milestones (Broke 90, streak), not trophies.
- Season card: "Season live · Mon Jul 20 → Mon Jan 18 · 26 wks" — the end is a date in a range.
Verdict: **"the database reached its final row."** There is no countdown to Dec 22, no "final starts in N weeks", no bracket/seed graphic, no tiebreak text, no preview of the settlement card, no history. The only emotional language about endings is a bylaws row. A two-player league where "everyone advances" and both players get paid makes the finale structurally hollow, and the app does nothing to dramatise it or to warn the Pro that it will be.

## JOURNEY G — NEXT SEASON
Honest answer: **the only thing that would make me start another is a specific friend — Galen.** The app gave me one live grudge (he's 10 up, he just broke 80, I lead him 1–0 head-to-head, we play Friday). Nothing else pulls: the pot was never collected, the "Cup Final" is a line I had to dig for, there is no title to defend ("No silverware yet"), no "almost won" narrative, no tradition (SEASON I everywhere), no redemption framing. If the group stayed at two players, my answer is "fun, but I don't need the app again."

## EMOTIONAL LOOP
| Element | Present? | Evidence |
|---|---|---|
| Anticipation | Partial | "MONTH CLOSES in 2 days", "3 days left in August" bar, "NEXT FRI QUINTERO", "Week closes Sun · 1d". But what happens at close is never said. |
| Rivalry | Present | "You lead by 22 points over Jade", "10 points back of Galen", "Rivalries · your record 2–0 / 1–0", "you lead 1–0" on the Sep 4 plan. |
| Identity | Present | @handle, ball marker (14 choices), photo, "Points King / Iron Man" titles, display case. |
| Progression | Present | Index 11.3 with trend, sparklines, "Personal best. New number to chase.", "number now comes from their scores". |
| Stakes | Weak | "$150 · $0 COLLECTED · 2 still owe" six weeks in; WTB "bragging rights"; no penalty projection. |
| Bragging rights | Partial | Board stories ("broke 80 for the first time — That one goes on the wall") exist but have no share; they're signed with the league name, which reads oddly. |
| Unfinished business | Partial | "1 more" round for the floor; "a good weekend back". |
| Social pressure | Weak | Only 🔥 reactions and a "Message the league…" box; can't see whether a rival owes rounds/money; no nudge; no notifications received (0 non-code emails in 60 days). |
| Redemption | Absent | Nothing frames being 2nd as a comeback path. |
| Title defense | Absent | "No silverware yet"; SEASON I; no history. |
| Specific nemesis | Present (by accident) | Two-player leagues make it automatic; the Rivalries list names them. |
| Desire to improve | Present | "Beat your number" framing, index trend, personal-best stories. |

## COMPETITION VISIBILITY
- **Home:** immediately shows who I'm beating/who beats me — for ONE league. The other league (where I'm losing) is invisible until I visit it. Nothing says what changes my position.
- **Standings:** yes for the two names; three redundant tables (the climb, the standings table, the individual table) for two people. Rival's floor status hidden. "What I need to do" absent.
- **Round results (board/round card):** good — band + points + counting slot per round.
- **League page:** admin (members, share, squads, bylaws, Pro Shop upsell) — competition absent by design.
- **You:** "League record 1ST OF 2 / 2ND OF 2" and rivalries — decent, two taps away.
Flag: Home's top third is admin ("Start a league / Start an event / Join a league"); the Schedule screen is scorekeeping/planning; the finale is invisible.

## SOCIAL PRESSURE TEST
Would I send any screen to the group? The **match-play scorecard with gold holes** and the **"79 gross" round card with the differential math** — yes, as screenshots. The **"Galen broke 80 … That one goes on the wall"** story — yes. But: none of them has a share/export control; the only sharing surfaces are the league invite link and a "Share the season" public standings page buried in League. No settlement card was visible for the pot. No notification reached my inbox in 60 days apart from sign-in codes. The app creates screenshot-worthy objects but no social objects that leave it on their own.

## INFORMATION HIERARCHY
**Home** — 3 s: gold "1st", "You lead by 22 points over Jade". 10 s: week 6/26, floor 1/2, month closes, next round Friday, Galen's 79. 30 s: tiles, feed, reactions, post. Still don't understand: HELD, floor, what close does, why one league only. Primary question "where do I stand and what's next?" — answered for one league. Should dominate: my standing in BOTH leagues + the one thing to do this week. Unnecessarily prominent: Start/Start/Join pills. Buried: the second league, money owed, the Cup Final.
**Standings (Clubhouse)** — 3 s: chips + season card + segmented control (the race is below the fold). 10 s: two names, 32 vs 10, LOCKED. 30 s: tiles, floor prompt, pot, titles. Still: LOCKED/seed/advances, Δ Wk, sign of vs-index, §4. Primary question "who's winning and by how much?" — yes. Should dominate: the race + the gap + what changes it. Unnecessarily prominent: the season card and chips; three tables for two people. Buried: what the season ends with.
**Board** — 3 s: "rounds land here automatically", Jul 20 join post. 10 s: it's a chronological log, oldest first. 30 s: react, comment, scorecards. Still: Diff, ledger, floors waived, Sunningdale/units. Primary question "what just happened?" — newest is at the bottom. Should dominate: newest first. Buried: the newest post.
**Round card / receipt** — 3 s: "79 gross". 10 s: course rating/slope, differential math, "+1.4 — BEAT THEIR NUMBER", 9 points, counting #1. Excellent. The player receipt (dates + vs index + PTS) is the weak sibling: no course, no gross, no sum.
**League page** — 3 s: Members / Share / Squads rows. 10 s: it's admin. 30 s: the bylaws behind a disclosure; Pro Shop upsell. Still: allowance, attested, sqd. Should dominate: the rules that decide the winner. Buried: exactly those.
**You** — 3 s: face, 11.3. 10 s: founder tools (!), badges. 30 s: lifetime, recent rounds, rivalries, league record. Still: FORM dots, 📉 on "Personal best", "Cups & events 2". Should dominate: league record + rivalries. Unnecessarily prominent: Founder's desk, feedback prompt.
**Schedule/calendar** — 3 s: calendar grid. 10 s: Galen Sep 4 "Major". 30 s: put a round on the tee sheet. Still: "you lead 1–0", empty "Week by week", legend colours. Primary question "when do I play next and with whom?" — partly.
**Trophies** — no trophy screen exists; "display case" + "No silverware yet".

## RETENTION LIFECYCLE (understanding / motivation / competition / social / emotional / return; 1–10)
- Day 0: 5 / 6 / 4 / 4 / 4 / 6 — the Home hero is a strong first read, but the vocabulary starts immediately.
- Week 1: 5 / 6 / 5 / 4 / 5 / 6
- Week 4: 6 / 6 / 6 / 4 / 5 / 6 — floor bar + month-close pill give a reason to open it.
- Mid-season (now): 6 / 6 / 6 / 4 / 5 / 6
- Late season: 4 / 5 / 5 / 4 / 5 / 5 — the Cup Final arrives unannounced; the lead I've watched for 22 weeks may mean nothing and I don't know it.
- Finale: 3 / 5 / 5 / 4 / 5 / 4 — no dramatisation visible anywhere.
- Season + 1 day: 3 / 3 / 3 / 3 / 3 / 3 — "No silverware yet"; no recap object seen.
- Season + 30 days: 2 / 2 / 2 / 2 / 2 / 2 — nothing in the inbox, nothing to defend.

## 30-SECOND EXPLANATION (verbatim)
"Cup Season is an app for a season-long golf league with your friends. Everyone posts their real rounds from wherever they play, and each round scores points against your own handicap — beat your number and you get more points, have a rough day and you still get five just for posting. Your best four rounds a month count and you owe at least two a month or you lose points. Points stack up over a 26-week season; there's a pot, a leaderboard, and side titles like Points King and Iron Man. Apparently the last four weeks are a 'Cup Final' that's scored fresh, but I only found that in the fine print — I honestly can't tell you how the winner is decided."

## PERSONA VERDICT
**Q: "I just finished a season — why would I start another?"**
**A:** "To beat Galen — he's the only name the app made me care about — and only if more of the group is actually in it. The cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant." **Score: 4/10.**

## SCORES (1–10)
conceptClear 7 · easyToPickUp 6 · gameplayCompelling 5 · rulesClear 3 · setupClear n/a (existing account) · sideGamesCompelling 5 · stakesMeaningful 3 · wouldInvite 5 · wouldPay 3 · wouldPlayAgain 5

## GLOSSARY (what I THINK each term means)
HELD (position unchanged since last week? — unexplained, not tappable) · Floor / "Aug floor 1/2" (minimum rounds per month, 2) · Counting rounds 1/4 / counting cap / "best 4 count" (only your best 4 rounds a month score) · Bumped (a round pushed out of the best-4 by a better one — explained inline, fine) · Month closes / "Ledger posted" (month-end accounting; consequences unstated) · LOCKED / "cup seed" (a guaranteed place in the Cup Final) · Cup Final · "scored fresh" (the last 4 weeks decide the title from zero — bylaws only) · The Pro (the league organiser — sounds like a club pro) · Your number (your handicap index, or "number that day") · "vs index" +/− (strokes better/worse than index; PLUS is good — opposite of golf's minus-is-good) · Diff / Differential (the WHS score differential) · Points King / Most Improved / Iron Man (side titles) · Squad / "sqd pts" (teams — this league has none) · Season bye (one forgiven missed floor) · Buddy (mutual follow, separate from leagues) · Tee sheet (planned tee times) · Major / The Ryder (event types) · Sunningdale / bank / units (a live betting game and its tally) · 4&3, 3&2 (match-play margins — fine) · Heater 🔥 (reaction) · Attested (someone vouches for scores?) · Handicap allowance 95% (share of handicap used) · Δ Wk (points change this week?) · Trend (sparkline of points) · Claim link (hands a round to a guest) · The climb (the ranked race list) · Founder's desk (admin tools) · Ball marker (avatar icon) · Live round (hole-by-hole group scoring) · "you lead 1–0" / "2 weeks head-to-head" (rivalry record; "weeks" unexplained) · FORM ●●●●● (recent-form dots; unexplained) · "Cups & events 2 · Played in" (which two?).

## CONFUSION DEBT (things the app assumes I already know)
what a floor is and what missing it costs · what HELD means · that the season ends in a fresh 4-week Cup Final and what a seed is · how the pot gets collected and who chases it · that board dates are posting dates, not play dates · the sign convention of "vs index" · what "the Pro" is · number vs index vs "number that day" · that Home shows one league and how to switch · what Δ Wk measures · squad vocabulary in a no-squad league · live-game formats (Sunningdale, Wolf, Skins), "bank", "units" · what an event / Major / Ryder is · what "Attested" asks of me · "bylaws §4" · what "month closes" does · whether a rival's missing rounds will cost them · that "Schedule" leaves the Clubhouse · why "Beat your number by 3.3" and "+2.6 vs index" are the same round.

## ISSUES (OBSERVATION / INTERPRETATION / IMPACT / RECOMMENDATION) — see the structured result for the full ranked list; the highlights:
1. **P1 rules** — The Cup Final ("final 4 weeks · scored fresh") is only in League › collapsed bylaws (`21-bylaws-open.jpg`); Home/Standings sell a 22-point lead that may not decide anything. Put the endgame on the hero and the standings.
2. **P1 comprehension** — Board shows two Aug 27 rounds (83 Cave Creek, 85 Encanto) while Home/Standings say 1 August round and You lists Encanto 85 as 2026-07-24 (`19-sub-Board.jpg`, `29-you-full.jpg`). Label board dates as "posted" and show the played date; keep counts consistent.
3. **P1 comprehension** — One round, two numbers: "Beat your number by 3.3" (Home) vs "+2.6 vs index · 9 PTS" (receipt); by the band table 3.3 would be 12 pts (`04-home-first.jpg`, `10-my-row.jpg`, `22-how-scoring2.jpg`). Use one measure everywhere.
4. **P1 navigation/retention** — Home hero shows one league, whichever I last opened in the Clubhouse; the league where I'm losing was invisible (`04-home-first.jpg` vs `36-home-earlier.jpg`). Show every league's standing on Home.
5. **P1 terminology** — "HELD", "AUG FLOOR 1/2 · 1 MORE · 2D", "MONTH CLOSES in 2 days" unexplained on Home (`04-home-first.jpg`). One-line explanations or tap-to-explain.
6. **P1 visual-hierarchy** — "Start a league / Start an event / Join a league" are the first thing a mid-season member sees (`05-home-full.jpg`). Demote for members with a live season.
7. **P1 navigation** — "Schedule" segment exits the Clubhouse to a global calendar with a "← Home" link (`13-sub-Schedule.jpg`). Keep it in the Clubhouse or label it as a door out.
8. **P2 visual** — The ⊕ button overlaps text on every screen (`08-club-top.jpg`, `09-club-mid.jpg`, `13-sub-Schedule.jpg`, `19-sub-Board.jpg`). Add bottom padding / hide on scroll.
9. **P2 monetization** — Pot: "0/2 in · 2 still owe" above "[Jade ✓] [Jerecho Fischbeck ✓]" (`12-on-the-line.jpg`). Distinguish "owes" from "paid"; show a nudge path.
10. **P2 rules** — Squad vocabulary ("Squad formation · Blind draw", "−5 sqd pts", "your squad" ×4, "count toward your squad") in an "Individual — no squads" league; "Points King takes 15% of the pot" in a no-pot league (`21-bylaws-open.jpg`, `22-how-scoring2.jpg`, `28-wtb-standings2.jpg`, `40-settings.jpg`).
11. **P2 terminology** — "vs index" sign convention inverts golf intuition; receipt has no colour cue (`10-my-row.jpg`, `44-jade-row.jpg`).
12. **P2 comprehension** — Player receipt lists dates + vs-index + PTS only (no course, gross, sum; ISO dates) (`10-my-row.jpg`).
13. **P2 rules** — "LOCKED", "cup seed", "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" undefined; vacuous with two players (`08-club-top.jpg`).
14. **P2 terminology** — Board jargon: "Diff 17.8", "Ledger posted · floors waived", "Sunningdale", "bank … 6 units", "number now comes from their scores" (`19-sub-Board.jpg`).
15. **P2 navigation/social** — Clubhouse board is oldest-first with the newest post under the compose box (`19-sub-Board.jpg`).
16. **P2 gameplay** — Rival's floor/penalty status invisible; no projection of "if you post / if Jade doesn't" (`07-league-full.jpg`, `44-jade-row.jpg`).
17. **P2 retention** — No countdown/explanation of the finale anywhere except bylaws; "No silverware yet"; no history (`21-bylaws-open.jpg`, `29-you-full.jpg`).
18. **P2 social** — No share/export on scorecards, round cards, or stories; the only shares are invite link and a buried public standings page (`42-matchplay.jpg`, `37-round-card.jpg`).
19. **P2 retention** — No emails/notifications besides sign-in codes in 60 days; month-close and floor deadlines never reach the inbox (Gmail search, 13:46).
20. **P2 comprehension** — Index-change contradictions: "▼ 1.1 this season" vs "Index move ▲ 1.2" vs "12.2 → 12.6" (`09-club-mid.jpg`, `29-you-full.jpg`, `19-sub-Board.jpg`).
21. **P2 comprehension** — "Δ Wk +10" though my last round was two weeks earlier (`07-league-full.jpg`).
22. **P2 comprehension** — Calendar "Week by week" card lists WK 4…WK 1 / WK 2…WK 1 with no content; "Nothing on the tee sheet for Aug" beside an "ON THE TEE SHEET" card (`13-sub-Schedule.jpg`, `34-next-tile.jpg`).
23. **P2 terminology** — "you lead 1–0", "2 weeks head-to-head", "Major", "BUDDY" unexplained on the plan card and Rivalries list (`13-sub-Schedule.jpg`, `29-you-full.jpg`).
24. **P2 comprehension** — Cross-league leakage: "Match play: Jerecho def. Jade 4&3" on the Who's the bitch? board (Jade isn't in it); Will & Isaak on the Fellas board; the same personal-best story posted twice on Home (`25-wtb-Board.jpg`, `36-home-earlier.jpg`).
25. **P2 visual-hierarchy** — Three tables for two players on Standings; the race sits below the fold under chips + season card + segmented control (`07-league-full.jpg`).
26. **P3 visual** — Raw "v23 · __CS_VERSION__" on the door (`01-door.jpg`).
27. **P3 terminology** — Story text runs into the league signature: "That one goes on the wall. Who's the bitch? · Aug 24" (`05-home-full.jpg`).
28. **P3 terminology** — Composer says "No league yet? The round still counts on your card" to a two-league member (`40-settings.jpg`).
29. **P3 visual** — Date formats: 2026-08-23 (sheets) vs Aug 23 (cards) vs 08/29/2026 (composer) (`37-round-card.jpg`, `40-settings.jpg`).
30. **P3 visual** — "Personal best" badge with a 📉 icon; "FORM ●●●●●" dots unexplained; "Cups & events 2" not linked (`29-you-full.jpg`).
31. **P3 onboarding** — "Founder's desk" admin block on the You tab of this account (`29-you-full.jpg`) — persona-specific, but for this member it pushes the record and rivalries down the page.
32. **P2 monetization** — "$0 COLLECTED" six weeks into a $75-buy-in season with no member-facing reminder or "who owes" path beyond the Pot page (`12-on-the-line.jpg`).

## Blockers
- No finished season on this account → Journey F judged only from what the live app says about endings.
- Strict read-only → could not test posting, reactions, comments, nudges, live rounds, tee-sheet posting, share links, settings changes.
- No app emails/notifications were received in 60 days, so "notifications worth opening" could not be evaluated positively.
- Both leagues have exactly two players, which flattens every "biggest threat / who am I ahead of" question and makes "everyone advances" trivially true.
- ~12 minutes of the session were lost to my mail-search tool truncating a long thread — not an app defect (codes arrived in ~2 s).
