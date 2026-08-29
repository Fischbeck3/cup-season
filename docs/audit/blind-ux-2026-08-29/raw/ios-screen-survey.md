# Blind UX audit — iOS screen survey (information hierarchy on the phone)

**Persona:** iOS SCREEN SURVEY — a first-time user looking at the native iPhone app's main screens. I cannot tap; I only land on screens via a developer launch argument and take screenshots. Everything below is what a person would SEE, not what the product intends.
**Account:** jerecho@fischbeck3.com (real account, real league). Look only — no input of any kind was sent to the app.
**Device:** iPhone 17 Pro Max simulator `BC810881-9C30-4EB9-AA83-985D11595AD5`, bundle `app.cupseason.ios`.
**Screenshots:** `../screenshots/ios/`
**Date:** 2026-08-29 (all times UTC; the phone's clock shows 8:2x local).

Blind rules honoured: no source, spec, docs or README opened; no repo grep. Every term below is judged only by what the screen says.

---

## 0. Timeline

| UTC | Event |
|---|---|
| 15:21:28 | Session start; simulator already booted. |
| 15:21:34 | Launched app with `-cs_dev_email jerecho@fischbeck3.com` (the "request a code" step). |
| 15:21:44 | Screenshot `01-door.jpg`. **The app did NOT show a sign-in door.** It landed on a signed-in Home ("Cup Season · Who's the bitch? · 2nd"). A session already existed on this simulator, so no code was requested and the Gmail step was skipped (step c says continue when Home is signed in). Recorded as a deviation, not a blocker. |
| 15:22:07 → 15:23:09 | Launched `clubhouse`, `board`, `schedule`, `you`, `settings`, `people` via `-cs_dev_open`, ~9 s each, screenshots 03–08. |
| 15:23:19 → 15:24:11 | Launched `post`, `postround`, `live`, `wizard`, `events`, screenshots 09–13. |
| 15:24:11 → 15:24:20 | Launched with no args; screenshot `14-home-again.jpg` (identical to 01). |
| 15:27:31 | App terminated. Simulator left booted. |

A stale `02-home.png` from a previous run was deleted so it could not be mistaken for evidence; `01-door.jpg` and `14-home-again.jpg` are this session's Home captures.

---

## 1. Per-screen reads

Format for each: 3-second read · 10-second read · 30-second read · what I still don't understand · the primary user question and whether the screen answers it · what should be dominant · what is unnecessarily prominent · what is buried · every unexplained term · can I see who I'm beating / who's beating me · would I send this to my group.

### 1.1 Home — `01-door.jpg`, `14-home-again.jpg`

Exact copy, top to bottom: `Cup Season` (serif wordmark) · `SAT · AUG 29` · orange `+` · card: `WHO'S THE BITCH? · WEEK 4 OF 14` / `2nd` (huge serif) / pill `— held` / `10 points back of the lead.` / `Partial month · floors waived` · section `AROUND YOUR BUDDIES` with link `THE BOARD ↗` · `QUIET SINCE YOUR LAST VISIT` / `Sun, Aug 23 — Galen set a personal best — 79 at Lone Tree Golf Club · Blue` · section `THIS WEEK` · card: `Galen` / `🔥 Personal best` / `79 gross` / `Lone Tree Golf Club · Blue · Sun, Aug 23` / a `🔥` reaction button · row: checkered-flag icon / `Galen broke 80 for the first time — a 79. That one goes on the wall.` / `Who's the bitch? · Sun, Aug 23` · link `Show earlier · 18` · tab bar `Home · Clubhouse · Post · You` (Post is an orange `+` circle).

- **3 s:** "Cup Season", a big "2nd", a league called "Who's the bitch?", somebody named Galen shot 79.
- **10 s:** I'm in 2nd place in something that is in week 4 of 14. I'm 10 points behind. A buddy set a personal best last Sunday.
- **30 s:** I could tap THE BOARD, the fire reaction, "Show earlier · 18", the `+` (unknown purpose), or the four tabs. I still could not tell you what a "point" is or how to get one.
- **Still don't understand:** what `— held` means; what `floors` are and why they're `waived`; what `Partial month` refers to; what the `+` does; why the section is headed `THIS WEEK` when today is Sat Aug 29 and the card is from Sun Aug 23; why `QUIET SINCE YOUR LAST VISIT` is immediately followed by an item (if it's quiet, what is that?); who is in the lead (not named on this screen).
- **Primary question:** "How am I doing, and what should I do next?" — Half answered. Rank and gap are shown, but there is no next action ("post a round to close the gap"), no leader named, no field size (2nd of how many?).
- **Should be dominant:** the rank card — it is. Good. But "2nd" without "of 2" reads as a podium, and per the Clubhouse there are only two golfers, so I'm actually last.
- **Unnecessarily prominent:** `SAT · AUG 29` (the phone already shows the date); the wordmark band.
- **Buried:** the leader's name; the number of golfers; any explanation of scoring.
- **Unexplained terms:** held, floors, partial month, points, "week 4 of 14" (Clubhouse says 13 — see 1.2).
- **Who I'm beating:** No — only "2nd" and "10 points back of the lead". Nobody is named.
- **Would I send this to my group:** The Galen-79 card is the kind of thing I'd forward, but there is no share affordance, only a fire reaction.

USER ASSUMPTION: "held" means my position didn't change since something. ACTUAL: not stated anywhere on the phone.
USER ASSUMPTION: "floors waived" means some minimum I normally have to hit doesn't apply this month. ACTUAL: not stated; Clubhouse later says "August is a short month — no floor to clear" which supports the guess but never defines "floor".
USER ASSUMPTION: the `+` in the corner posts a round. ACTUAL: the `events` capture (1.11) shows a "Start an event" sheet over Home, so the `+` may open something else. Cannot verify without tapping.

### 1.2 Clubhouse — `03-clubhouse.jpg`

Exact copy: nav title `Who's the bitch?` · swap icon (⇄) top-right · card: `Who's the bitch?` / `Season live` / pill `Code · WHOS84L9` / `WK 4 / 13 · POINTS RACE · STANDARD RULES` / `Mon Aug 3 → Mon Nov 2 · 13 wks · THE PRO · GALEN` / link `Add golfers` · tab strip `STANDINGS BOARD SCHEDULE ALBUM LEAGUE` · tiles: `SEASON W4 / 13 — Week closes Sun · 1d` · `THE POT None — Bragging rights` · `YOUR INDEX 11.3 — Season to date` · `COUNTING ROUNDS 1 / 4 ●○○○ — August · your best 4 count` · progress bar `3 days left in August` · card `NEXT UP · AUGUST` / `August is a short month — no floor to clear. Every round still counts.` / button `Live round` · section `SEASON RACE · THE CLIMB` · row `01 [marker] Galen (LOCKED) 19` · sub-line `10 back of Galen` · row `02 [flag] You · Jerech... (LOCKED) [sparkline] 9` · `EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS` · ghost text bleeding through the tab bar: `Galen lead by 10 · Jerecho Fischbeck a good…`.

- **3 s:** the league name twice, a code, four stat tiles, two names with numbers 19 and 9.
- **10 s:** Galen has 19, I have 9, there are two of us; the pot is nothing; I have 1 of 4 "counting rounds"; August ends in 3 days.
- **30 s:** I could tap the tabs, `Add golfers`, `Live round`, the code pill (copy?), the ⇄ (switch leagues?). I cannot tell what "LOCKED" means for either of us, what "advances" means, or what "THE PRO" is.
- **Still don't understand:** `WK 4 / 13` here vs `WEEK 4 OF 14` on Home; `POINTS RACE`; `STANDARD RULES` (what are they? no link); `THE PRO · GALEN` (is Galen the organizer? a golf pro?); what to do with `Code · WHOS84L9`; why `Add golfers` is offered during a live season; `LOCKED`; `THE CLIMB`; `EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS` (advance to what? seats where?); what `Live round` does inside a "next up" card; why `10 back of Galen` sits under Galen's row rather than mine.
- **Primary question:** "Where do I stand and who do I need to catch?" — YES. This is the one screen that names the leader and the gap. But it is one tab-tap and a full scroll away from Home.
- **Should be dominant:** the standings. They are below the fold, under a header card, four tiles, a progress bar and a "next up" card. The league name is shown three times (nav title, card, and implicitly the code) before the first standings row.
- **Unnecessarily prominent:** the code pill; `Add golfers`; the header card in general (it duplicates the nav title).
- **Buried:** the standings; the fact that there are only two golfers.
- **Unexplained terms:** Points race, Standard rules, The Pro, Counting rounds, floor, The Climb, Locked, Contenders, Seats, Live round, Season to date.
- **Who I'm beating:** Yes — Galen 19, me 9. Clear once you get here.
- **Would I send:** No; there's nothing shareable-looking and the layout is dense.

USER ASSUMPTION: `LOCKED` means I can't change something (my squad? my index?). ACTUAL: unstated. Both rows carry it, so it cannot distinguish us.
USER ASSUMPTION: `10 back of Galen` belongs to my row. ACTUAL: it is drawn under Galen's row (`03-clubhouse.jpg`, y≈1630), before the divider that starts my row.
USER ASSUMPTION: the ⇄ icon switches leagues. ACTUAL: unknown; no label.

### 1.3 The Board — `04-board.jpg`

Exact copy: back chevron · `THE BOARD` (green caps) · divider `TODAY · AUG 29` · one line `◆ Your league is live — post the first round` · composer `Message the league...` · dim `Send` · tab bar with Clubhouse highlighted.

- **3 s:** an empty chat with one system line.
- **10 s:** the league is live and nobody has posted a round.
- **30 s:** I could type a message. That's it.
- **Still don't understand:** why the Board says "post the first round" dated TODAY when Home shows Galen posted a 79 on Aug 23 and offers `Show earlier · 18`. Which league's board is this? There is no league name on the screen.
- **Primary question:** "What's going on in my league?" — NOT answered; the screen says nothing is going on, which contradicts Home.
- **Should be dominant:** the feed of what happened. Instead 85% of the screen is empty.
- **Unnecessarily prominent:** nothing; the screen is bare.
- **Buried:** everything Home already showed me.
- **Unexplained terms:** "Board" (Home calls it `THE BOARD ↗`; Clubhouse has a `BOARD` tab; this pushed screen has its own back button — three ways in, unclear whether they're the same thing).
- **Who I'm beating:** No.
- **Would I send:** No.

USER ASSUMPTION: the board is the league's activity feed. ACTUAL: on this capture it is a nearly empty chat whose only item contradicts the Home feed. Possible causes (cannot verify): the board loaded a different league, the feed loads asynchronously and 9 s wasn't enough, or the board only shows chat and "system" items while rounds live elsewhere. All three are UX failures for a first-time user because nothing on screen explains the emptiness.

### 1.4 Schedule — `05-schedule.jpg`

Exact copy: back chevron · `Your golf calendar` · caps `YOUR GOLF CALENDAR · YOURS, YOUR BUDDIES', YOUR LEAGUES'` · section `IN YOUR CREW'S PLANS` · row `[marker] Galen BUDDY` / `FRI SEP 4 · QUINTERO GOLF AND COUNTRY CLUB · you lead 1–0 · YOU'RE IN · "Major"` / right label `ON THE TEE SHEET` · section `THE CALENDAR` with `← AUG 2026 →` · a month grid whose first row is empty and whose second row begins `6 7 8` under T F S; Sundays 9, 16, 23, 30 carry a blue dot; 29 is ringed in orange; 31 ends the grid · legend `● ON THE TEE SHEET ● LEAGUE MATE ● SEASON DATE` · `Tap any day to put a round on the tee sheet.` · orange CTA `Put a round on the tee sheet` · section `ON THE TEE SHEET` (cut off) · ghost `WEEK BY WEEK` behind the tab bar.

- **3 s:** a calendar, a big orange button, a row about Galen on Sep 4.
- **10 s:** there's a round with Galen on Friday Sep 4 at Quintero; I'm in; something about a "tee sheet".
- **30 s:** I could page months, tap a day, or press the orange button. I'd guess "tee sheet" = the list of rounds we've scheduled.
- **Still don't understand:** what "tee sheet" is (used five times on one screen, never defined); `you lead 1–0` (lead what? a head-to-head with Galen? in what?); `YOU'RE IN` (in the round? in the league?); `"Major"` in quotes (a nickname for the round? a format?); why Sundays have `SEASON DATE` dots (are Sundays special? is that the day rounds are due?); why the grid has an empty first row and no days 1–5 (Aug 1 2026 is a Saturday, so 1 should appear in the top-right and 2–5 on the second row); why the Sep 4 round is in "crew's plans" but the calendar shows August so it isn't visible on the grid.
- **Primary question:** "When am I playing next, and with whom?" — YES for the Sep 4 round, but wrapped in three unexplained tokens.
- **Should be dominant:** the next round. It is, roughly.
- **Unnecessarily prominent:** the caps subtitle repeating the title; the CTA text repeated as a hint line directly above the button.
- **Buried:** the section actually called `ON THE TEE SHEET` is below the fold, under the calendar.
- **Unexplained terms:** tee sheet, crew, buddy, season date, league mate, "you lead 1–0", "you're in", "Major".
- **Who I'm beating:** `you lead 1–0` suggests a head-to-head record vs Galen, but over what is never said.
- **Would I send:** No.

USER ASSUMPTION: "tee sheet" is the app's word for scheduled rounds. ACTUAL: never stated on this screen.
USER ASSUMPTION: days 1–5 are hidden because they're before the season started. ACTUAL: the season card says it started Mon Aug 3, so 3–5 are in-season; and 6–8 (also past) ARE drawn. The missing days look like a rendering defect.

### 1.5 You — `06-you.jpg`

Exact copy: `You` · gear · card: `NO. 2` (caps, top-left) / avatar photo with flag badge / `Jerecho Fischbeck` / pill `✦ FOUNDER` / `@JERECHOFISCHBECK · PHOENIX, AZ · LOOKOUT MOUNTAIN GOLF CLUB` / `GHIN 12828189 · Member since Jul 2026` / `11.3` (gold) `HANDICAP INDEX` / chips `📉 Personal best · '26` `⛳ First round · '26` `🎯 Broke 100 · '26…` / `FORM ●●●●●` (four grey, one orange) · section `YOUR DISPLAY CASE` · tiles `Personal best — Diff 9.3 · '26` · `First round — Posted · '26` · `Broke 100 — 88 gross · '26` · `Broke 90 — 88 gross · '26` · `4-week streak — 4 weeks · '26` · section `THE RECORD` / `No silverware yet — every season starts level.` · section `LIFETIME` (cut off; ghost `rounds posted`).

- **3 s:** my name, my photo, a big gold 11.3, a wall of badges, "NO. 2".
- **10 s:** I'm an 11.3 handicap, I've got five badges, no trophies yet. "NO. 2" — am I ranked 2nd? (I am, per Home.)
- **30 s:** I could open settings (gear), scroll the chip row, scroll down to Lifetime. Nothing here tells me my league standing, my points, or what to do.
- **Still don't understand:** `NO. 2` — on the settings screen it turns out to be the NAME of the selected ball-marker icon, but on this card, next to a person who is literally in 2nd place, it reads as rank; `FOUNDER` (of the app? of the league? a paid tier?); `FORM` dots — what does grey vs orange mean and which end is "now"?; `Diff 9.3`; why `Broke 100` and `Broke 90` both say `88 gross · '26` (one round claims both milestones — reads as a bug or as cheap badges); the difference between `DISPLAY CASE`, `THE RECORD` and `LIFETIME`.
- **Primary question:** "Who am I in this app and how good am I?" — Handicap yes; competitive standing no.
- **Should be dominant:** handicap index and current standing. Index is; standing isn't here at all.
- **Unnecessarily prominent:** the GHIN number (and Settings says this card "is what your buddies see" — so my GHIN number is public to buddies); the FOUNDER pill.
- **Buried:** any competitive context; Lifetime stats.
- **Unexplained terms:** No. 2, Founder, Form, Diff, Display case, The record, silverware, "starts level".
- **Who I'm beating:** No.
- **Would I send:** The card is designed to be shown off (badges, photo), but no share control is visible.

USER ASSUMPTION: `NO. 2` = my rank. ACTUAL: it is the ball-marker's name (`07-settings.jpg`, the selected marker tile is labelled `No. 2`). Coincidence with my actual rank makes this actively misleading today.

### 1.6 Card & settings — `07-settings.jpg`

Exact copy: back chevron · `Card & settings` · caps `YOUR CARD IS WHAT YOUR BUDDIES SEE · SETTINGS RUN THE APP` · segmented `Your card | Settings` · `NAME ON THE CARD` field `Jerecho Fischbeck` · `CITY` `Phoenix, AZ` · `HOME COURSE` `Lookout Mountain G...` · `BALL MARKER` 4×4 grid: `The Saguaro · The Island · The Lighthouse · The Lone Tree · The Pews · The Dunes · The Beverage · The Shark · The Azalea · The Jug · The Wee Bridge · No. 2 (selected, orange) · The Postage Stamp · The Thistle` · `YOUR PHOTO · THE MARKER ALWAYS BACKS IT UP` · avatar + mono buttons `Change photo` `Remove` · `HANDLE · MOVES ONCE / 60 DAYS` field `@jerechofischbeck` · `FINDABLE BY` chips `All (selected) · Buddies · Nobody` · ghost `GHIN … 12828189` behind the tab bar.

- **3 s:** a form; a grid of little icons with odd names.
- **10 s:** this is my profile; I pick an icon ("ball marker"); my photo; my handle; who can find me.
- **30 s:** I could edit any field. I don't see a Save button on this capture (may be below). I don't know what the marker is used for — it appears next to my name in lists, I guess.
- **Still don't understand:** why an avatar is called a "ball marker"; what the names mean (they look like famous golf holes — a casual golfer won't know "The Postage Stamp" or "The Wee Bridge"); `THE MARKER ALWAYS BACKS IT UP` (backs what up?); `MOVES ONCE / 60 DAYS` (I think: can be changed once per 60 days, but the phrasing is odd); whether edits save automatically.
- **Primary question:** "How do I set myself up / change something?" — Mostly yes.
- **Should be dominant:** name, photo, handicap source. Handicap isn't on this segment at all.
- **Unnecessarily prominent:** the marker grid — 14 tiles, the largest element on the screen, for a decoration.
- **Buried:** whatever is on the `Settings` segment (notifications, sign-out?).
- **Unexplained terms:** card, ball marker (in this sense), "backs it up", handle, findable.
- **Who I'm beating:** N/A.
- **Would I send:** N/A.

### 1.7 Your buddies — `08-people.jpg`

Exact copy: back chevron · `Your buddies` · caps `YOUR BUDDIES` · button `Find a golfer` · field `Find golfers by name or @handle` · section `BUDDIES · 6` · rows `Blake @blake · Costa Mesa (BUDDIES)` · `fedor.garrett @fedorgarrett · Plymouth, MA (BUDDIES)` · `Galen @galenfink · Gilbert (BUDDIES)` · `Jade @jade (BUDDIES)` · `lcsimpson12 @lcsimpson12 · Scottsdale, AZ (BUDDIES)` · `Sam Reviewer @reviewer · Phoenix, AZ (BUDDIES)` · section `REQUESTED` · `mmittels15 @mmittels15 · Phoenix (REQUESTED)` · more rows cut off (`Scott Cadotte…`, `zimacasey (REQUESTED)`).

- **3 s:** a contacts list.
- **10 s:** six buddies, a few pending requests.
- **30 s:** I could search for a golfer (two ways, stacked). I can't tell whether the "REQUESTED" people asked me or I asked them, and there's no accept/decline control.
- **Still don't understand:** the difference between the `Find a golfer` button and the search field directly below it; why every row repeats `BUDDIES` in a pill (the section already says it); the direction of `REQUESTED`; what being buddies gets me (handicap comparison? shared calendar? nothing on screen says).
- **Primary question:** "Who are my people and how do I add one?" — Add: yes. Who: names only — no handicap, no league, no record vs me.
- **Should be dominant:** pending requests that need my action (if any). They're at the bottom.
- **Unnecessarily prominent:** the redundant BUDDIES pills; the title repeated in caps.
- **Buried:** requests.
- **Unexplained terms:** buddy, requested (direction), handle.
- **Who I'm beating:** No — no competitive info on any row.
- **Would I send:** No.

### 1.8 Post a round — `09-post.jpg` (and `10-postround.jpg`, identical)

Exact copy: back chevron · `Post a round` · button `Play now` (top-right) · preview card `POST A ROUND · YOUR INDEX 11.3` / a blank grey bar + `gross` / `Enter at least one nine.` / `A preview at 100% of your number — your league's own math scores it on the books.` · section `COURSE & TEES` · field `Search a course, or type your own` · rows `Troon North Golf Course — Pinnacle Course · Gold  72.1 / 142` · `Raven Golf Club-Phoenix · Silver  70.8 / 127` · `Arizona Biltmore Cc — Links · Copper  64.9 / 111` · `Rating / slope  — / —  · edit` · `YOUR CARD` toggle `18 holes (selected, white) | 9 holes` · `FRONT 9 GROSS [41]` `BACK 9 GROSS [43]` `GROSS —` · `Enter your card to see the score.` · orange `Post round` · `Start over — clear this card`.

- **3 s:** a form to enter a score; "41" and "43" already in the boxes.
- **10 s:** pick a course, enter front and back nine, post. The 41/43 are placeholders (they're dim) — but at a glance they look filled in.
- **30 s:** I could search a course, tap a recent course, edit rating/slope, toggle 9/18, type scores, post. I don't know what `Play now` does versus `Post round`. I don't know what date this round is for.
- **Still don't understand:** `A preview at 100% of your number — your league's own math scores it on the books.` (100% of what number? whose math? what books?); `Enter at least one nine.` (I get it — one nine-hole half — but it's an odd sentence to lead with); the unlabeled `72.1 / 142` on the course rows (you learn they're rating/slope only from the row beneath); why the three courses are listed with no "Recent" header; whether `Post round` is enabled — it's fully orange with an empty card; what `Play now` is.
- **Primary question:** "How do I get my score in?" — Yes, mostly. The mechanics are visible.
- **Should be dominant:** the score entry. It's at the bottom, under a preview card that's empty and a course list.
- **Unnecessarily prominent:** the preview card (a big dark box that says nothing until you type); the `Play now` button competing in the nav bar.
- **Buried:** date of the round (not visible on this capture); the score inputs.
- **Unexplained terms:** gross, index, "your number", "on the books", card (as in scorecard), rating/slope.
- **Who I'm beating:** No.
- **Would I send:** No.

USER ASSUMPTION: 41 and 43 are values the app already has. ACTUAL: they are placeholders (grey), but at phone glance they read as entered. A nervous first-timer could believe they've already been scored or could post without noticing the boxes are empty.
USER ASSUMPTION: `Play now` starts live scoring. ACTUAL: unknown from this screen; no caption.

### 1.9 Live — `11-live.jpg`

Exact copy: NO nav bar, no title, no back/close visible · caps `SET UP THE ROUND` · card: `COURSE` field `Search a course, or type your own` · `TEE & RATING — OFF THE SCORECARD` · fields `Tee · Rating · Slope` · toggle `18 holes (selected, orange) | 9 holes` · `Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load.` · mono button `Enter the pars` · card: `THE FOURSOME · 1 / 4` · tile `● Jerecho Fischbeck 11.3 IDX` · three dashed `Open slot — TAP A PLAYER BELOW` · `TAP TO FILL A SLOT · LEAGUE` · `LEAGUE` · chip `● Galen · 9.0` · mono button `👥 Search the app — add any golfer` · `ADD A GUEST` fields `Name · Index` button `Add` · paragraph `Pick who plays with who under the game — pairings, stakes, the lot. League members post to the season; guests play every game, post nothing, no account needed. Leave index blank for an estimated 18.`

- **3 s:** a setup form for a round with four player slots.
- **10 s:** I'm setting up a round with up to four people; I can add Galen or a guest.
- **30 s:** I could fill the course, tee, rating, slope, pars, add players. I do NOT know what this sets up — a live scorecard? a match? a bet? Nothing on screen says "live" or names a game. There is no visible way to leave the screen.
- **Still don't understand:** what the screen is FOR; `the stepper` (a UI widget name leaking into copy); why I'd `Enter the pars` (shouldn't the course know?); `OFF THE SCORECARD` (from the physical card, I think); `under the game — pairings, stakes, the lot` — which game?; `post to the season` vs `post nothing`; `estimated 18` (a default 18 handicap, I think); why `TAP TO FILL A SLOT · LEAGUE` is immediately followed by another header `LEAGUE`.
- **Primary question:** "What am I about to start, and with whom?" — With whom: yes. What: no.
- **Should be dominant:** the name of the game/format being set up and a clear start button. Neither is visible.
- **Unnecessarily prominent:** the par-entry paragraph and button.
- **Buried:** the exit; the game choice (if any).
- **Unexplained terms:** stepper, pars, foursome (fine for golfers), IDX, guest, "the game", stakes, "post to the season", estimated 18.
- **Who I'm beating:** No.
- **Would I send:** No.

Note: the 18/9 toggle here is orange-selected; on Post it's white-selected. Buttons here are monospace; on Post they're sans.

### 1.10 Wizard — `12-wizard.jpg`

Exact copy: `Name your league` · caps `THE BANNER EVERYTHING HANGS UNDER` · field placeholder `The Big Slice, The Sunday Cup, Dew Sweepers...` · `You can rename it any time before the bylaws lock.` · orange `Start the league` · `Cancel` · ~80% of the screen empty.

- **3 s:** one text field and a big orange button.
- **10 s:** name a league and start it.
- **30 s:** type a name, press start. I have no idea what happens next, how many steps there are, what a league needs (people? money? dates?), or what "bylaws lock" means.
- **Still don't understand:** `bylaws lock`; whether "Start the league" creates something real immediately; what a league IS in this app (season? bets? draft?); there's no step indicator.
- **Primary question:** "What am I committing to?" — Not answered.
- **Should be dominant:** a one-line description of what a league is and how long setup takes. Absent.
- **Unnecessarily prominent:** `Start the league` for a step that only sets a name.
- **Buried:** everything after the name.
- **Unexplained terms:** league (as this app means it), bylaws, banner.
- **Who I'm beating:** N/A.
- **Would I send:** N/A.

### 1.11 Events — `13-events.jpg`

Exact copy: a sheet over Home with `Close` · `Start an event` · caps `SHORT FORM · ITS OWN LITTLE TROPHY` · card `⚔ The Ryder — Two teams · weekly vs-index duels · first to the clinch — LIVE` (green outline) · card `🥊 Bracket — Knockout · seeded · last golfer standing — SOON` · `Every event mints a trophy for your display case. More styles land after the pilot.`

- **3 s:** two options, one "LIVE", one "SOON".
- **10 s:** I can start a short competition; one type is available now.
- **30 s:** tap The Ryder, presumably. I can't tell if "LIVE" means available or currently running.
- **Still don't understand:** `vs-index duels`; `first to the clinch`; `LIVE` vs `SOON`; `the pilot` (internal language); `mints`; how an "event" differs from a "league"; why a sheet that shows two cards leaves the bottom 40% empty.
- **Primary question:** "What else can I play?" — Partly; the two blurbs are terse to the point of jargon.
- **Should be dominant:** what The Ryder is in plain words (e.g. "two teams, a week of head-to-head matches").
- **Unnecessarily prominent:** the trophy framing.
- **Buried:** who can start one, who's invited, how long it takes.
- **Unexplained terms:** event, short form, Ryder, vs-index, clinch, bracket, seeded, pilot, display case.
- **Who I'm beating:** No.
- **Would I send:** No.

---

## 2. Cross-cutting observations

### 2.1 Nothing on the phone says what Cup Season is
OBSERVATION: Across 11 screens there is no tagline, no "how points work", no "how a season is won". The most descriptive line on the whole app is the wizard's placeholder examples. INTERPRETATION: the app assumes the organizer explained the game verbally. IMPACT: a first-time invitee lands on "2nd · 10 points back" with no way to learn what a point is. RECOMMENDATION: one tappable line under the rank card ("How points work") and a one-sentence definition on Home for a first session.

### 2.2 The two week counts disagree
OBSERVATION: Home `WEEK 4 OF 14` (`01-door.jpg`); Clubhouse `WK 4 / 13`, `13 wks`, tile `W4 / 13` (`03-clubhouse.jpg`). IMPACT: the single most basic fact about the season is inconsistent between the two most-visited screens; it undermines trust in every other number. RECOMMENDATION: one source; fix whichever is wrong.

### 2.3 The Board contradicts Home
OBSERVATION: Board shows only `Your league is live — post the first round` under `TODAY · AUG 29`; Home shows a round posted Aug 23 plus `Show earlier · 18`. IMPACT: the screen literally called "the board" says the league is empty. RECOMMENDATION: the board must show the same events Home summarises, or the empty-state must explain what it excludes.

### 2.4 Standings line attached to the wrong row
OBSERVATION: `10 back of Galen` sits under `01 Galen` and above the divider that starts `02 You`. IMPACT: the one sentence that tells me my gap reads as though Galen is 10 back of himself. RECOMMENDATION: render the gap line on the viewer's row.

### 2.5 Calendar drops the first five days of August
OBSERVATION: the grid's first row is empty, the second starts at 6 (`05-schedule.jpg`). Aug 1 2026 is a Saturday. IMPACT: looks broken; a user cannot put a round on 1–5. RECOMMENDATION: render every day; dim past days rather than omitting them.

### 2.6 Five different "do a round" entry points, none explained
`Post` tab · `+` on Home · `Play now` on Post · `Live round` on Clubhouse · `Put a round on the tee sheet` on Schedule. A first-timer can't tell posting a past score from starting a live game from scheduling a future round. RECOMMENDATION: one verb per concept (Post a score / Play live / Plan a round) used consistently.

### 2.7 Internal vocabulary leaks everywhere
"floors", "held", "locked", "the climb", "contenders/seats", "tee sheet", "season date", "the stepper", "bylaws lock", "vs-index duels", "the clinch", "the pilot", "mints", "on the books", "your number". None is defined in-app. See glossary.

### 2.8 Visual system
Three type families (serif display, monospace caps, sans body) plus buttons that are monospace on some screens (`Add golfers`, `Change photo`, `Enter the pars`, `Search the app — add any golfer`) and sans on others (`Post round`, `Start the league`, `Find a golfer`). The 18/9 toggle is white-selected on Post and orange-selected on Live. Content ghosts through the translucent tab bar on Clubhouse, Schedule, You, Settings and People (visible as half-readable text at the bottom of each capture) — it looks like a glitch rather than a deliberate blur.

### 2.9 Competition visibility
Only the Clubhouse standings show who I'm beating / who's beating me. Home gives a rank and a gap but no name; You gives no standing at all; Buddies gives no competitive data; Schedule gives a cryptic `you lead 1–0`. For an app whose Home leads with "2nd", the opponent should be one glance away everywhere.

---

## 3. Friction points (ranked)

1. No definition of the game anywhere on the phone (P1, comprehension).
2. Week 4 of 14 vs 4/13 (P1, rules).
3. Board empty vs Home feed (P1, social/navigation).
4. Gap line under the wrong standings row (P1, visual-hierarchy).
5. "tee sheet" ×5, undefined; primary CTA uses it (P1, terminology).
6. Live screen has no title, no exit and no game name (P1, comprehension).
7. Post placeholders 41/43 read as values (P1, gameplay).
8. Post preview copy ("100% of your number… on the books") (P1, comprehension).
9. Calendar missing days 1–5 (P2, visual-hierarchy).
10. "NO. 2" on You card vs actual 2nd place (P2, terminology).
11. LOCKED / held / floors / partial month unexplained (P2, terminology).
12. "10 back of the lead" with no leader named; "2nd" of an unstated 2 (P2, comprehension).
13. THIS WEEK shows Aug 23 on Aug 29; "QUIET SINCE…" followed by an item (P2, comprehension).
14. Schedule row tokens "you lead 1–0 · YOU'RE IN · "Major"" (P2, comprehension).
15. Clubhouse header: POINTS RACE / STANDARD RULES / THE PRO / code / Add golfers (P2, comprehension).
16. COUNTING ROUNDS 1/4 and EVERYONE ADVANCES — rules implied, never stated (P2, rules).
17. Buddies: redundant find controls, redundant pills, REQUESTED direction (P2, social).
18. Ball marker grid — purpose and names unexplained (P2, onboarding).
19. Events blurbs — vs-index, clinch, LIVE/SOON, pilot (P2, terminology).
20. Wizard: single field, "bylaws lock", no step count (P2, onboarding).
21. Five round entry points (P2, navigation).
22. Two routes to Board/Schedule (Clubhouse tabs vs pushed screens with back) (P2, navigation).
23. Broke 100 / Broke 90 both "88 gross" (P3, retention).
24. FORM dots, Diff 9.3, FOUNDER, three trophy sections (P2, comprehension).
25. GHIN number on the buddy-visible card (P3, social/privacy).
26. No share affordance on the shareable moment (P2, social).
27. Type/toggle/button inconsistency; ghosting through tab bar (P3, visual-hierarchy).
28. "Post round" looks enabled with an empty card; "Play now" competes (P2, visual-hierarchy).
29. Course rows' "72.1 / 142" unlabeled; no "Recent" header (P2, visual-hierarchy).
30. Live: "the stepper", "Enter the pars", duplicate LEAGUE header (P2/P3).

---

## 4. Glossary (what I THINK each term means, from the screens alone)

| Term | Where seen | What I think it means | Confusing? |
|---|---|---|---|
| Cup Season | Home wordmark | the app's name; implies a season with a cup at the end | no |
| points / "10 points back" | Home, Clubhouse | a season score; how you earn them is never shown | yes |
| held | Home rank pill `— held` | my position didn't move | yes |
| floors / floors waived / no floor to clear | Home, Clubhouse | a monthly minimum you must hit, not applied in August | yes |
| Partial month | Home | August isn't a full month of the season | yes |
| The Board | Home link, Clubhouse tab, pushed screen | league chat / activity feed | yes (contradicts Home) |
| Week closes Sun | Clubhouse tile | the week's deadline is Sunday | no |
| The Pot / Bragging rights | Clubhouse tile | prize money; here there is none | no |
| Your index / Handicap index | Clubhouse, You, Post | my handicap number | no (golfers know) |
| Counting rounds · your best 4 count | Clubhouse tile | only my best 4 rounds per month score | yes (rule never stated) |
| Points race | Clubhouse header | the season format | yes |
| Standard rules | Clubhouse header | a default ruleset I can't read | yes |
| The Pro · Galen | Clubhouse header | the organizer? | yes |
| Code · WHOS84L9 | Clubhouse header | an invite code (no instruction) | yes |
| Add golfers | Clubhouse header | invite more people | mild |
| Live round | Clubhouse button | start scoring a round now? | yes |
| Season race · The Climb | Clubhouse | the standings table | yes |
| LOCKED | standings rows | something about me/Galen can't change | yes |
| Everyone advances — 2 contenders, 2 seats | Clubhouse | both of us go to a final? | yes |
| tee sheet | Schedule ×5 | the list of scheduled rounds | yes |
| crew / buddy / league mate | Schedule, People | friend-tiers in the app | mild |
| you lead 1–0 | Schedule row | my head-to-head record vs Galen in something | yes |
| YOU'RE IN | Schedule row | I'm confirmed for this round | mild |
| "Major" | Schedule row | a nickname/label for the round | yes |
| Season date (blue dot on Sundays) | Schedule legend | a day that matters to the season — why Sundays? | yes |
| No. 2 | You card, Settings marker | the name of my chosen marker icon; collides with my rank | yes |
| Ball marker | Settings | my avatar icon, named after famous holes | yes |
| Founder | You card | early user? league creator? | yes |
| Form ●●●●● | You card | recent-results trend, colours undefined | yes |
| Diff 9.3 | Display case | a score-vs-course number ("differential"?) | yes |
| Display case / The record / Lifetime | You | badges / trophies / totals — overlap unclear | yes |
| silverware / "every season starts level" | You | trophies; nobody has any yet | mild |
| The marker always backs it up | Settings | the icon shows if the photo doesn't load | yes |
| Handle · moves once / 60 days | Settings | @name, changeable once per 60 days | mild |
| Findable by | Settings | who can search for me | no |
| gross | Post, Home | total strokes | no |
| Enter at least one nine | Post | give a front or back 9 | mild |
| A preview at 100% of your number… on the books | Post | some handicap-allowance maths | yes |
| card / Your card | Post, Live, Settings | scorecard on Post/Live; profile on Settings — same word, two meanings | yes |
| Rating / slope | Post, Live | course difficulty numbers | no (golfers know) |
| Play now | Post nav | start a live round? | yes |
| Set up the round | Live | configure a live game | mild |
| Off the scorecard | Live | copy the tee numbers from the physical card | mild |
| the stepper | Live | a UI control name | yes |
| Enter the pars | Live | type each hole's par | yes (why me?) |
| IDX | Live | index | mild |
| guest | Live | a non-member player | no |
| under the game — pairings, stakes, the lot | Live | which game? never named | yes |
| estimated 18 | Live | default handicap 18 | mild |
| bylaws / bylaws lock | Wizard | the league's rules become fixed at some point | yes |
| The banner everything hangs under | Wizard | the league name | mild |
| event / short form | Events | a mini-competition | mild |
| The Ryder / vs-index duels / first to the clinch | Events | team event; matches judged against handicap; first to win enough | yes |
| Bracket / seeded / last golfer standing | Events | knockout | no |
| LIVE / SOON | Events | available now / not yet | yes (LIVE ambiguous) |
| mints a trophy / the pilot | Events | awards a badge; "pilot" is internal language | yes |

## 5. Confusion debt (things the app assumes I already know)

- What a "point" is and how a round becomes points.
- That only the best N rounds per month count, and that there's a monthly "floor".
- That the season has a fixed number of weeks and what happens at the end ("advances", "seats").
- What "LOCKED" locks.
- That "tee sheet" = scheduled rounds.
- Why Sundays are "season dates".
- What "the board" contains and why it can be empty while Home has 18 items.
- What the ball marker is for and what the hole names refer to.
- What "Founder" confers.
- What "form" dots encode.
- How a live round differs from posting a round, and what game a live round plays.
- What "bylaws" are and when they "lock".
- What "The Ryder" is, and what "vs-index" and "clinch" mean.
- The difference between a league and an event.
- That "card" means scorecard on one screen and profile on another.
- Which league the Board/Schedule pushed screens belong to (no league name on them).

## 6. My 30-second "explain Cup Season to a friend" — VERBATIM, from the phone alone

"It's a golf app where your friend group runs a season — ours is 13 or 14 weeks, the app can't decide. You post your rounds with your handicap, and somehow that turns into points; I'm in 2nd with 9, Galen has 19, and I honestly can't tell you how he got there or how I get more. There's a calendar for planning rounds together — it calls them a 'tee sheet' — and a live-scoring thing where you set up a foursome, but it never says what game you're playing. You collect badges like 'Broke 90' on your profile and pick a little icon named after a famous golf hole. There's a pot, but ours is 'bragging rights'. The organizer will have to explain the rules to you, because the app doesn't."

## 7. Persona verdict

**Question:** As a first-time user looking only at the iPhone app's screens, do they say what Cup Season is and why I should care?
**Answer:** They say that it is competitive (a rank, a gap, a leader), social (buddies, a board, a calendar) and golf-serious (index, rating/slope, gross), and the design is confident and attractive. They do NOT say what the game is, how a round becomes points, how a season ends, or what half the words mean. Standing is answered on exactly one screen. A friend would need the organizer to walk them through it.
**Score:** 4 / 10.

### Scores (1–10)
- conceptClear: 4
- easyToPickUp: 5
- rulesClear: 3
- setupClear: 3 (the wizard capture is one field with "bylaws lock")
- gameplayCompelling: 6 (the rank card and the "broke 80" story are genuinely motivating)
- sideGamesCompelling: 4
- stakesMeaningful: 4 (pot None, "bragging rights"; "seats" undefined)
- wouldInvite: 5
- wouldPay: 3
- wouldPlayAgain: 6

## 8. Blockers / deviations

- The `-cs_dev_email` launch did not present a sign-in door; the simulator already held a session for this account, so the emailed-code flow (steps a–c) was not exercised here. Sign-in UX is therefore not assessed by this persona.
- `post` and `postround` land on the identical screen; I could not observe a distinct "post round" surface.
- Below-the-fold content (Lifetime on You, the `Settings` segment, `ON THE TEE SHEET` and `WEEK BY WEEK` on Schedule, whatever lies beneath `Post round`) was not visible because scrolling is not possible in this persona.
- The Board's emptiness may be a load-timing artefact (9 s wait) — the observation stands, the cause is unverified.

## 9. Screenshot index

| # | Place | Path |
|---|---|---|
| 01 | door (landed on Home) | `…/shots/ios/01-door.jpg` |
| 03 | clubhouse | `…/shots/ios/03-clubhouse.jpg` |
| 04 | board | `…/shots/ios/04-board.jpg` |
| 05 | schedule | `…/shots/ios/05-schedule.jpg` |
| 06 | you | `…/shots/ios/06-you.jpg` |
| 07 | settings | `…/shots/ios/07-settings.jpg` |
| 08 | people | `…/shots/ios/08-people.jpg` |
| 09 | post | `…/shots/ios/09-post.jpg` |
| 10 | postround | `…/shots/ios/10-postround.jpg` |
| 11 | live | `…/shots/ios/11-live.jpg` |
| 12 | wizard | `…/shots/ios/12-wizard.jpg` |
| 13 | events | `…/shots/ios/13-events.jpg` |
| 14 | home (no args) | `…/shots/ios/14-home-again.jpg` |

`…` = `../screenshots/ios`
