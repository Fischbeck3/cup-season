# Reader: post-and-play (the ⊕ and playing golf) — PP-

Repo tip 3bba87e · read 2026-09-04 · read-only. Line numbers are as of tip. Everything marked SAW was read in the Swift/SQL/HTML at tip or in the one screenshot (`apps/ios/Screenshots/6.9/04-post.png`, Sep 1, shows pre-D178 hero copy). Everything marked INFERRED is a consequence I traced through the code but did not run on a device. Prod figures come from read-only `supabase db query --linked` on 2026-09-04 and are small-n (39 profiles, 23 posters, 212 rounds of which 199 have `played_on < created_at` — most of the record is seeded, so the telemetry is thin and I say so where it matters).

Scope read: `apps/ios/CupSeason/Post/*`, `Live/*`, `Rounds/*`, `Schedule/DeclareRoundSheet.swift`, `Main/MainTabView.swift`, `RootView.swift`; Kit `Post/{PostCard,PostService,PostEpilogue}`, `Live/{LiveCopy,LiveModels,LiveRepository,LiveResult,LiveClaim,LiveRehydrate,LiveDisk}`, `Rounds/{ReceiptSeed,RoundCopy,RoundsRepository}`, `Board/CSBands`, `League/LeagueCopy`; migrations `20260829090000_leagueless_live_rounds`, `20260716210000_named_rivalries` (round_epilogue), `20260902173000` (score_round), `20260718173100` (rounds check constraints); index.html `#view-record`, `#view-play`, `#view-post`, the Q-22 recalc guard (6985–7000) and `#backToSetup` (10348); decision-log D34/D36/D107/D110/D122/D124/D125a/D131/D133/D134; the prior audit's issues.csv rows for this area.

---

## Section 1 — The map

Every screen, sheet and state in the area. "Reached" lists every real door I found in code (not just the intended one).

| # | Screen / sheet / state | How reached | What it shows FIRST | Primary action | Exits |
|---|---|---|---|---|---|
| 1 | **⊕ cover** `PostCoverView` (fullScreenCover, NavigationStack) | ⊕ tab tap (`MainTabView.swift:338` — selection snaps back, haptic) · Clubhouse "record door" `ClubhouseView.swift:171` · `-cs_dev_open post` | `CSPageHeader("Golf", sub: "Play one live, post one you just finished, or plan the next")` then three rows: LIVE hero "Play now — score the group" (ember, breathing dot), "Post a round — after you play / Gross + tee, 20 seconds · counts on your card and in every league", "Plan a tee time — before / Put a round on the tee sheet · your buddies and leagues see it the moment you post" (`PostCoverView.swift:90–102`) | Tap a row | "Close" toolbar (`:114`); hero → closes cover, opens `LiveRoundHost` (`:97`); Post → pushes composer; Plan → sheet |
| 2 | **Composer** `PostRoundScreen` | Cover row 2 · Home lead card `.clash`/`.floor` (`HomeView.swift:165–169`, `postOnComposer = true`) · You empty state "Post your first round" (`YouScreen.swift:138`, `YouLinks.postRound`) · `postround` dev link. From a CTA the stack is seeded with `.post` so the cover sits *behind* (`PostCoverView.swift:82`) | Dusk hero card: eyebrow "Post a round · your index 10.9" / "…your index builds at 3 rounds" (`PostRoundModel.swift:64–66`), big "—"/gross, "18 holes", sentence "Enter at least one nine to see the points." (`PostCard.swift:209`), fine "A preview — your league's own math scores it on the books." (`PostRoundScreen.swift:434`) and, with no league, "No league yet? The round still counts on your card — points apply in any league you join." (`:436`). Then COURSE & TEES field, Recent courses rows, "Rating / slope — / — · edit", YOUR CARD + 18/9 seg, FRONT 9 GROSS / BACK 9 GROSS / GROSS, fine "How most golfers keep it — 41 out, 43 in…", "Enter your card", DETAILS pills (date · Scan the card · Add a photo), folded "How points work" | Bottom bar: gross line + **Post round** + "Start over — clear this card" (`:372–389`) | Back chevron → cover (even when the golfer never saw it); "● Play now" toolbar → `onDone(); links.openLive()` (`:117–129`); Post → ceremony |
| 3 | Course dropdown `PostCourseSearchField` (two stages) | Typing ≥3 chars in the course field (320 ms debounce) | Course rows "Papago Golf Course · Phoenix, AZ · 13 tees"; empty: "No match — type the course, rating and slope by hand." | Pick course → tee list ("‹ Back to courses", tee rows "Blue · 71.2/128"); pick tee → label "Papago Golf Course · Blue", rating/slope filled, toast "Tees set — rating and slope filled", real pars loaded async (`PostRoundModel.swift:105–116`) | Tee pick hides dropdown; typing again unstamps `courseId` (`PostCourseSearchField.swift:25`) |
| 4 | Recent courses rows | Own last 30 labelled rounds, 3 unique (`PostService.swift:26–38`); shown only while the field is empty | "Papago GC — 72 / 126" (mono, unlabeled) | Tap → fills course + rating + slope, toast "Course filled: just the gross and the date" | — |
| 5 | Rating/slope fold | "edit" on the "Rating / slope" row (`PostRoundScreen.swift:175–199`) | Two fields RATING "72.1" / SLOPE "128" | Type | "done" |
| 6 | Scorecard strip `PostScorecardStrip` (holes mode) | "Enter your card" (`PostRoundScreen.swift:260–275`) · a scan | OUT/IN rows of cells "1 / 4 / P4", one big −/+ stepper "HOLE 1 · PAR 4", "Next hole →", fine "Each hole starts on par — tap to adjust only what you didn't.", "Set the pars →", "Front & back" / "Scrap the scan — type front & back instead" | Tap cell, −/+ | "Front & back" back to two boxes |
| 7 | **Set the pars** `PostParsSheet` | "Set the pars →" | "Set the pars · PAPAGO · PARS ONLY", two nine-digit fields "453453543", Total par, fine "Nine digits a side, 3–6…" | Done (rejects with toast "Nine digits a side, 3 through 6") | Cancel |
| 8 | **Post as even par?** `PostEvenParSheet` | Post with the grid untouched (`PostRoundModel.swift:202`) | "YOU HAVEN'T ENTERED YOUR CARD YET · Each hole is still on par, so this would post an even-par 72 — and it counts on your card and in every league." | "Enter my card" / "Post even par anyway" | — |
| 9 | Date sheet `PostDateSheet` | Date pill | Graphical calendar, "THE DAY YOU PLAYED", max = tomorrow (`:491`) | Done | swipe |
| 10 | Photo / Scan capture | "Add a photo" / "Scan the card" pills → camera (`PostCameraPicker`) or library; scan only when `app_flags.scan` enabled (prod: enabled, 5/day) | System camera | Shoot | Cancel |
| 11 | **Whose card is this?** `PostScanPickSheet` | A scan that read >1 player | "TAP YOUR ROW" · "Player 2 · 84 GROSS · 18/18 HOLES READ" · fine "After you post, your partners' rows can be sent to them as claim links." | Tap row → strip as confirm surface, toast "Card read — N holes I couldn't make out are set to par" | swipe |
| 12 | **Finish ceremony** `FinishCeremonyView` (fullScreenCover, dusk, 2.55 s stagger) | Successful insert (`PostRoundModel.swift:247–252`) | "PAPAGO · SAT AUG 22" eyebrow, ball rolls into cup, serif gross, band sentence, points line in gold only when earned ("+9 PTS · COUNTS FOR THE PINES") else the D122 note ("PRACTICE · SEASON STARTS SAT SEP 5") or "ON YOUR CARD" / "COUNTS ON YOUR CARD" (`PostEpilogue.swift:159–166`) | **Share the card** (recap PNG + caption) | "Back to the board" → dismisses → epilogue / partners / close (`PostRoundScreen.swift:136`) |
| 13 | **Epilogue** `EpilogueSheet` (medium) | After the ceremony when `round_epilogue` returns rows, or always on the first-ever round (`PostRoundModel.swift:263–271`) | Title "Your round" / "Welcome to the season ⛳"; sub "84 AT PAPAGO"; rows: band + pts + "counts #2 this month", milestones ("You broke 90 for the first time"), rivalry ("You lead Jade 3–1 all-time"), first-round welcome | "Share a link — no account needed" (`create_share`), "Turn off this link" | swipe → `onDone` closes the whole cover |
| 14 | **Send their rounds** `PostPartnersSheet` | After a scan that carried other rows | "ONE SCAN, THE WHOLE GROUP", per-row "Copy link" / share | Copy → `create_scan_claim` | swipe → close |
| 15 | Share sheet `PostShareSheet` | Ceremony/epilogue buttons | UIActivity | — | — |
| 16 | **Round receipt** `RoundReceiptSheet` | Home feed, You recent rounds, board, milestone lead card, push `.receipt` — **never from the post flow itself** (`PostLinks.openReceipt` is wired at `MainTabView.swift:391` and used nowhere in `Post/*`) | "84 gross" / "PAPAGO GC · 18 HOLES · 2026-08-22" (ISO date, `ReceiptSeed.swift:78–81`); photo; rows: The course "71.2 / 128" · Your number that day · Playing number · "84 − 71.2 × 113 ⁄ 128 = 11.3 VS COURSE" · "Against your playing number +2.4 — BEAT YOUR NUMBER" · Points · This month COUNTING #2 · Nine holes HALF VALUE · Attested · Played with · "See the scorecard" | (none; read) | swipe |
| 17 | Scorecard `ScorecardSheet` | Receipt "See the scorecard" (live rounds only) | HOLE/OUT/IN/TOT table, story line | — | Close |
| 18 | Album `AlbumScreen` | Clubhouse/Home route | League photo grid; empty "Photos land here when rounds carry them — add one from the Post card." | Tap → receipt | back |
| 19 | **Plan a tee time** `DeclareRoundSheet` | Cover row 3 (`PostCoverView.swift:115`) · You "Stage it" (`YouSections.swift:32`) · schedule | "Put a round on the tee sheet" / "BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST"; Day (defaults next Saturday), Tee time · optional (7:40), Course ("Pebble Beach"), Note ("buddies trip, looking for a 4th"), Tag your group chips or "No one to tag yet. Add buddies from the You tab, or invite the league." | **On the tee sheet** → toast "On the tee sheet: the boards know" | Cancel |
| 20 | **Live host** `LiveRoundHost` (fullScreenCover, may rotate) | Cover hero · composer "Play now" · Clubhouse "Play now" · `LiveNowBar` · Home `LiveResumeBanner` · push `.live` · Dynamic Island tap · nearby accept → auto-open (`MainTabView.swift:275–279`) | `LiveSetupView` when no round is live, `LivePlayView` when one is | — | "Close" (setup: nothing to abandon; live: round keeps running, bar brings you back `LiveRoundHost.swift:40–48`) |
| 21 | **Set up the round** `LiveSetupView` (nav title "Play now") | above | Eyebrow "Set up the round"; optional gold plan bridge "On your tee sheet today · Papago / Load the course and your group into the tee sheet · Load it →"; **Course card** (search field, "Tee & rating — off the scorecard" → Tee / Rating / Slope, 18/9 seg, note "Standard par-72 card. The stepper opens on each hole's par — pick your course above and the real pars load.", "Enter the pars"); **Foursome card** ("The foursome · 1 / 4", 2v2/solo seg when four, slots "Open slot · TAP A PLAYER BELOW", chip groups You / Nearby / You play with / League / Buddies / Guests with "NAME · 12.4" and ASK on nearby, "Search the app — add any golfer", Add a guest Name + Index + Add, 40-word fine print); **Game card** ("Game for this round · pick one": Just score · Match play · Wolf · Skins · Sunningdale Rules, note for the picked game, stake field "Stake per side · $0 = bragging rights", strokes preview); **Nearby card** ("Who's on this tee" toggle + Bluetooth paragraph) | **Tee off →** (toast "On the tee, good luck everybody"; refusals as toasts "Wolf needs exactly 4") | Close |
| 22 | Course card sheet `LiveCardSheet` | "Enter the pars" | "Course card · PAPAGO · PARS ONLY", two nine-digit fields, fine "…Strokes fall by hole order; exact stroke index arrives with the course database." | Save the card → toast "Card saved: every league gets it from here" | Close |
| 23 | Add to the foursome `LiveRosterPickerSheet` | "Search the app — add any golfer" | Buddies list; "Find golfers by name or @handle" | Add (lands as a non-posting "buddy" chip) | Done |
| 24 | Nearby invite alert | Another phone's ASK (`LiveRoundHost.swift:229–241`, on the tab shell and on setup) | "Join this round? · Jerecho wants you in a round at Papago · Match play." | **Join** → toast "You're in — waiting for Jerecho to tee off", bar "ON THE TEE · Waiting for Jerecho to tee off"; **Not me** | — |
| 25 | **Live round** `LivePlayView` (portrait HOLE) | Tee off, resume, invite | Scoreboard band: hero ("ALL TO PLAY" / "GALEN LEADS · -2 NET THRU 3" / "ALL SQUARE" / "JADE +3 · …"), chips "Galen · +1 net · 40 thru 9", sync badge "3 on the sheet · synced" / "Solo pencil · scores live on this phone"; eyebrow "Live round · Papago · Blue · 71.2/128" + "Change setup"; HOLE 4 / "PAR 4 · SI 7"; dots; player rows "Galen · 12.4 IDX · 3 STK · 40 THRU 9 · +4 · [− 5 +]"; "Side games · tracked live, settled between friends"; game cards; "Round settlement · live"; "Group phones — everyone can score"; finish status line + **Finish round** / **Finish round & post to season**; first-score teaching paragraph; "Scrap this round" (two-tap) | −/+ per player | Close (round continues) · Change setup |
| 26 | Live round CARD view `LiveCardView` / landscape HOLE | Rotate, HOLE/CARD toggle | Full 18-column card, SI row only when real, ledger strip | Tap a hole number → jump | Rotate back |
| 27 | Group phones `LiveGroupSheet` | "Group phones — everyone can score" | "EVERYONE SCORES · IT ALL SYNCS" + "League members just open the app — a **Continue your round** banner is waiting on Home…"; per-guest Copy / share "Your pencil for today's round on Cup Season" | Copy link | swipe |
| 28 | **Finish the round** `LiveFinishSheet` | Finish button | "ONE FINISH — EVERY CARD POSTS TO ITS GOLFER" (league-less) / "…EVERY MEMBER'S CARD POSTS"; intro "Complete cards post to the season, attested by the group; 2 guests get a recap to claim. A partial card is skipped, not lost."; red warning "Jade — missing holes 3, 7. That card won't post — go back and fill in, or finish without." | **Post 3 cards to the season** / "Finish — no complete member card to post"; quiet "This one was casual — post nothing" | swipe |
| 29 | **Recap** `LiveRecapSheet` (dusk, large) | After finish | "Round posted" / "Casual — nothing posted" · "3 CARDS TO THE SEASON"; result row (icon · "Galen & Jade def. …" · money); hole strip + legend + highlight chips ("WON 3 STRAIGHT · 4-6"); posted rows "Galen · 84 · POSTED · 18 HOLES · ✓ ATTESTED"; skipped rows; guest rows "GUEST RECAP — SHARE THE LINK · Copy" | **Share the card** (settlement PNG) · "Share the settlement — no account needed" · "Revoke a shared link" | swipe → lands on an **empty Set up the round** (`LiveRoundHost.swift:49–57`, `LiveRoundStore.swift:784`) |
| 30 | Top bar `LiveNowBar` | Any tab while a round is live or an accepted invite waits | "● LIVE · Papago · Hole 5 →" / "ON THE TEE · Waiting for Jerecho to tee off" | Tap → host | hides while host is up |
| 31 | Home banner `LiveResumeBanner` | Home while live | "Continue your round / PAPAGO · MATCH PLAY / HOLE 5 · THRU 4 →" or "Jerecho put you on the tee sheet … JUST TEED OFF · NOTHING SCORED YET · JOIN" | Tap → host | — |
| 32 | Live Activity / Dynamic Island | Tee off (`LiveActivityHost.start`) | Course · HOLE n · THRU · game line; goes stale at 45 min | Tap → host | ends on finish/scrap/setup |
| 33 | **Guest pencil** `GuestPencilScreen` (signed-out `/?claim=`) | Universal link on a phone with no session (`RootView.swift:28–32`) | "Finding your card" → `LivePlayView` pencil (no toolbar, no close) while live; after: door "Your scorecard · Ed — 84 at Papago, Sat Aug 22. Enter your email to keep it." / "That card is already on a record." / "That scorecard link has expired…" | **Enter your email to keep it** → DoorView → card gate → claim (`ClaimFlow.consume`, toast "Claimed ✓ — your 84 is on your card") | — |
| 34 | Toasts (2.6 s, `SliceComponents.swift:26`) carrying outcomes | many | "Post failed. That didn't go through — please try again." · "Photo didn't stick — posting the round without it" · "Tees set — rating and slope filled" · "Card cleared" · "Foursome is full: remove someone first" · "Asked Jade" · "No answer — ask them to open the tee sheet" · "Round finished from another phone — the cards posted" · "Round scrapped — nothing posted" · "Your unposted round came back — it's waiting in Post a round" | — | vanish |

**Tap/field counts (SAW, counted from the code paths):**

- *Quick post, returning golfer (course memory, index known):* ⊕ (1) → "Post a round" row (2) → recent-course row (3) → Front 9 field (4) + 2 digits → Back 9 field (5) + 2 digits → Post round (6) → ~2.6 s ceremony → "Back to the board" (7) → epilogue swipe (8, when rows exist). **3 fields, 6 taps to submit, 8 to be back where you were.**
- *Quick post, first time at a course:* ⊕ (1) → Post (2) → course field (3) + ≥3 chars + 320 ms → course row (4) → tee row (5) → F9 (6) → B9 (7) → Post (8) → Back (9) → epilogue swipe (10). **Concepts met before Post:** gross, front/back, 18/9, tee, rating, slope, index, "your number", points, bands, league, squad, "card" (five senses).
- *From You's empty state:* "Post your first round" (1) → composer directly (2 taps fewer).
- *Course not found / typed by hand:* + "edit" (1) + Rating (1) + Slope (1) and two numbers a casual golfer does not know — and today the post then fails at the server (PP-01).
- *Play now, alone, no league:* ⊕ (1) → Play now (2) → Tee off (3). You are pre-seated (`LiveRoundStore.swift:165`), "Just score" is the default, rating/slope fall to 72/113 silently, the par-72 template stands in. **3 taps to a live round** — the best number in the area.
- *Play now with three league mates and money:* ⊕ → Play now → 3 chips → Match play → stake field + digits → (optionally the court) → Tee off: **≈8 taps + 1 typed number**, across ~20 named concepts (listed in PP-04).
- *Measured (prod `client_events`, 2026-09-04):* `post_open` 109 (8 golfers), `post_submit` 24 (5 golfers) — **median 39 s, mean 47 s, p90 76 s** from open to submit; modes used: `total` and `holes`; `scan_post` 1; `scan_claim_minted` 0. The cover promises "20 seconds" (`PostCoverView.swift:100`); the vision promises under 60 s (`spec/product-vision-v1.0.md:146`). Median meets the vision; p90 does not; nothing meets the cover.

---

## Section 2 — Flows

### Flow A · Post a round (quick)
- **User goal:** "I shot 84 at Papago today. Put it on my record and see what it did." (Brief: course, score, opponents, optional game — done.)
- **Current friction (SAW):** the composer asks, in order, for a course *and a tee* (two dropdown stages), rating/slope (filled by the tee, otherwise a folded row the golfer must know to open), 18 vs 9, and the gross split into two nines. There is no single "score" box. Course memory (3 rows) shortens this only for a returning golfer. Date defaults to today (good). Post is one tap, then a 2.5 s ceremony, then a second sheet (epilogue), then the whole cover closes to whatever tab was underneath.
- **Unnecessary complexity:** tee selection is mandatory in practice because it is the only thing that fills rating/slope; the "Rating / slope — / — · edit" row is the app's way of saying "we need two numbers off the scorecard" without saying it (`PostRoundScreen.swift:175–191`). The 18/9 seg, "Enter your card", the pars sheet, the even-par guard and the "How points work" table are all on the same scroll as the two numbers that matter. The hero's third line is a preview disclaimer ("A preview — your league's own math scores it on the books.") that a first-timer cannot parse.
- **Confusing terminology (exact strings):** "Gross + tee, 20 seconds · counts on your card and in every league" (`PostCoverView.swift:100`) · "Post a round · your index builds at 3 rounds" (`PostRoundModel.swift:65`) · "-0.4 vs your index" (`PostRoundScreen.swift:428`) beside "Played to your number" (`CSBands.vsPhrase`) — two names for one figure on one card · "Rating / slope" · "Your card" (the scorecard section, `:226`) vs "counts on your card" (the record, `:436`, `:453`) vs "Start over — clear this card" (the form, `:382`) vs "Scan the card" (paper, `:296`) vs "Share the card" (the artifact, `PostEpilogue.swift:167`) — five senses of "card" on one screen and its ceremony; D131 assigned one owner each and this area does not carry it · "9 holes · half value" (`PostCard.swift:202`) while the Guide says "Nine holes is a real round, not eighteen with blanks" (`Cup-Season-Guide.md:96`) · "How points work … count toward your squad" (`PostRoundScreen.swift:330`) shown to golfers with no squad or no league · "A preview — your league's own math scores it on the books." shown with no league (`:434`).
- **Dead ends (INFERRED from code):** a course typed by hand (or a search hit with "No rated tees listed") leaves rating 0; the preview still prints a points figure and a wild "-73.6 vs your index", Post stays enabled, and the insert dies on the `rounds` check constraint (rating 25–90, `20260718173100_security_hardening_medium.sql:58`) → toast "Post failed. That didn't go through — please try again." (`PeopleModels.swift:160–161`) with nothing highlighted. The web closed this as Q-22 (`index.html:6989–6999` — "Pick a tee — or type the rating and slope — to see the points."); the phone did not (`PostCard.swift:235–262` has no rating guard). See PP-01.
- **Redundant actions:** the cover is an extra tap for the 90 % case (D110 addendum made it always show); a golfer coming from You/Home's CTA gets a back chevron into a cover they never opened (`PostCoverView.swift:82`). The ceremony's "Back to the board" + the epilogue's swipe are two dismissals for one moment.
- **Missing feedback:** rating required — never said. Post failure — a 2.6 s toast. After posting: no door to the receipt of the round just posted (`PostLinks.openReceipt` unused in `Post/*`), so "what did that do to my standing" is answered only by closing everything and finding the feed.
- **Opportunities for delight (keep + extend):** the live gross hero with the band sentence and `contentTransition(.numericText())` is already a scorecard, not a form; the ceremony's ball-into-cup + `.success` haptic is the best moment in the app; the draft that survives an app kill (`PostDraft`, 24 h) and its toast are quietly excellent. A camera-first "snap the card" door and a "who did you play with" chip row would finish the brief's sentence.

### Flow B · Hole-by-hole and the scan
- **Goal:** "I want my card in, hole by hole" / "read the paper card for me."
- **Friction:** "Enter your card" is a small brand-text link under the two boxes (`PostRoundScreen.swift:271`); the strip then needs the pars set by hand through a nine-digit string ("453453543") unless a tee was picked. The scan is a pill among Date/Add a photo, gated by a flag (prod: on), used once in the life of the product (`scan_post` n=1; 0 claims minted; `scan_claims` 0 rows).
- **Complexity:** the even-par guard sheet ("Post as even par? YOU HAVEN'T ENTERED YOUR CARD YET") is a modal for a rare mistake — correct, but it is the third sheet a first-timer can meet on one screen.
- **Terminology:** "Set the pars →", "Nine digits a side, 3–6", "exact stroke index arrives with the course database" (`PostHoleGrid.swift:243`) — course-database talk on a golfer surface. Scan: "Card read — 2 holes I couldn't make out are set to par" is good voice.
- **Dead ends:** none; the scan degrades to typed entry on every failure (`PostRoundModel.swift:150–159`).
- **Missing feedback:** the strip's unread cells (warm dashed hairline) are subtle on a dark ground; VoiceOver says it, sighted eyes may not.
- **Delight:** one big stepper for the whole card with haptics; "Next hole →" wraps OUT into IN. Keep.

### Flow C · After the post (ceremony → epilogue → close)
- **Goal:** "Tell me what that round meant, let me show my friends, and tell me what to do next."
- **Friction (SAW):** the ceremony answers the first two (band sentence, points line, Share the card). The epilogue adds milestones/rivalry rows and a link. Then it *closes* — the cover dismisses to the tab underneath (`PostRoundScreen.swift:136–140` → `onDone`). There is no third act.
- **Unnecessary complexity:** the epilogue carries "Turn off this link" + a two-line fine print about revocation on the first-ever round (`EpilogueSheet.swift:37–41`) — an admin control at the peak moment.
- **Terminology (exact):** "COUNTS ON YOUR CARD" (`PostEpilogue.swift:163`) and "ON YOUR CARD" (`LeagueCopy.noLeagueNoteShort`, uppercased at `:162`) — the string the prior audit found *every* tester misread, ruled retired by D131, still the fallback here · "Welcome to the season ⛳" as the epilogue title for a golfer with **no season** (`PostEpilogue.swift:93`, reached via `firstEver` at `PostRoundModel.swift:265–271`) with the row "Your first round is on the board — Welcome to the season — your number and record start here" (`:88`) · "Back to the board" (`:168`) on a button that dismisses to Home/You/Clubhouse, never a board.
- **Dead ends:** the whole flow is one. Nothing offers "make the next one count" — join a league, start one, plan the next round, challenge the buddy you played with, or even open the receipt. `PostLinks.openPeople` and `openReceipt` are wired by the shell (`MainTabView.swift:390–392`) and never called by any Post view (grep: zero uses in `Post/*`). The vision's funnel (casual → competition → recurring) has no rung here.
- **Redundant:** `firstEver` inserts a "Your first round is on the board" row *and* the server's `first_round` achievement (awarded to all 23 posters in prod) renders "Your first round is on the board / Welcome to the season" through `achievements[]` (`PostEpilogue.swift:55, 74–89`) → two rows saying the same thing on the first-ever epilogue (INFERRED: depends on `round_moments` firing before `round_epilogue` is read; the award count says it does).
- **Missing feedback:** the D124 provisional case: the hero correctly refuses a signed figure with no number (`PostRoundScreen.swift:424–425`), but the ceremony and the shared PNG do not — see PP-03.
- **Delight:** the stagger, the gold-only-when-earned rule, the D122 "PRACTICE · SEASON STARTS SAT SEP 5" line, the milestone rows that name a feeling ("That one goes on the wall"). Keep all of it; add the next act.

### Flow D · Play now — setting up a live round
- **Goal:** "We're on the first tee. Get us scoring." Or: "It's just me today."
- **Friction (SAW):** one scroll of four cards and ~20 concepts before "Tee off →" (`LiveSetupView.swift:24–34`). Solo is three taps — excellent. A group is fine *if* the mates are in the league or buddies; otherwise it is search-the-app or a guest with a name and an index.
- **Unnecessary complexity for a first setup:** Tee / Rating / Slope fields exposed by default (`:94–103`) with silent 72/113 fallbacks (`LiveModels.swift:201–202`) — the fields look required and are not; "Enter the pars" nine-digit sheet; the 2v2/solo seg and the drag-to-swap court; six chip groups (You / Nearby / You play with / League / Buddies / Guests, `:199–206`); guest Index field; five games including Sunningdale Rules; four differently-named stake units ("Stake per side" / "Dollars per point" / "Bank unit" / "Dollars per skin", `LiveModels.swift:71–79`); the Bluetooth card with a 40-word privacy paragraph (`:167–184`). The brief's "Who? When? What are we playing for?" with a Customize fold is exactly the shape this screen is not.
- **Terminology (exact):** "Set up the round" · "Tee & rating — off the scorecard" · "The foursome · 1 / 4" · "Open slot · TAP A PLAYER BELOW" · "Pick who plays with who under the game — pairings, stakes, the lot. Every complete card posts to its golfer at the finish; account-less guests play every game, post nothing. Leave index blank for an estimated 18." (`:139`) · "League members post to the season; guests play every game, post nothing, no account needed." (`:140`) — false for an app golfer added by search in a league round: `finish_live_round` posts a complete card for any seated `guest_profile_id` (`20260829090000_leagueless_live_rounds.sql:194–214`) · "EST 18.0 IDX", "B"/"G" letters on chips (`:326–330`) · "Just score" · "Sunningdale Rules" · "Stake per side · $0 = bragging rights" · "Strokes off the low man (Galen) · estimated card — no real stroke index" (`LiveCopy.swift:319`) · "Who's on this tee" · "On your tee sheet today · Load the course and your group into the tee sheet" (`:67–68`) — D131 assigned "tee sheet" to the calendar; here it names the live scorer.
- **Dead ends:** none hard; refusals are toasts ("Wolf needs exactly 4", "Foursome is full: remove someone first", "Give your guest a name"). The seat rule per game is visible only after picking the game and only when money is on (`LiveCopy.preview` returns nil for `.score`, `:284`); D133 ruled an always-visible seat line and an (i) per game — not on the phone.
- **Redundant:** the plan bridge's "Load it →" plus the same course search below it; "Search the app — add any golfer" plus "Bring your group — search the app" (league-less empty state, `:265`).
- **Missing feedback:** blank rating/slope → nothing says "we'll use 72/113"; the standard-card note talks about pars, not rating. An "ASKING…" chip gives up after 20 s with a toast (`LiveRoundStore.swift:234–238`) — good, but the toast is 2.6 s.
- **Delight:** the nearby handshake ("a NEARBY chip asks; every other chip adds", `:229–239`), the tee-off `.impact` haptic + "On the tee, good luck everybody", the strokes preview in plain sentences ("**Jade** gets 3: holes 2, 7, 11"). Keep.

### Flow E · Scoring live and the side games
- **Goal:** "Enter our scores fast, know where the match stands, never lose the round."
- **Friction:** fine on the phone that started it: one big −/+ per player, hole arrows, dots, side-game cards *above* the finish block (D153). Portrait needs a scroll for four players + games; landscape fixes it.
- **Complexity:** the first-score teaching paragraph (`LivePlayView.swift:91`, ~60 words) sits under the finish button; the Wolf card's four pick buttons; "Round settlement · live" ledger rows in dusk.
- **Terminology (exact):** "Solo pencil · scores live on this phone" (`LiveCopy.swift:254`) — "pencil" is the codebase's word · "12.4 IDX · 3 STK", "SELF 12.0 IDX", "EST 18.0 IDX" (`LiveCopy.swift:186`) · "PAR 4 · SI 7" (`:195`) · "Live round · Papago · Blue · 71.2/128" (`LiveModels.swift:305`) · "THRU 9 · STROKES OFF LOW MAN (GALEN) · $5 A SIDE · EST. CARD" (`LiveCopy.swift:53`) · "DORMIE" · "Scores entered together are auto-attested: the group verifies everyone's round just by playing it … Only league members' rounds post to the season." (`LivePlayView.swift:91`) — stale on both halves: D125a made attestation a fact (own phone joined), and D107 posts every app golfer's complete card in a league-less round · "Finish round & post to season" (`:419`) in a league-less round whose sheet then says "each to its golfer".
- **Dead ends (INFERRED):** "Change setup" (`LivePlayView.swift:66`, `LiveRoundStore.swift:578–581`) drops the in-memory round to setup and leaves the session but never abandons the server round and never removes the disk snapshot; "Tee off" again starts a *new* server round (`:492`, `s.lr = nil`). The old row stays `live` for everyone else (their bar/banner still point at it), and `LiveRehydrator.run` is local-first over `disk.snapshots().first` (`LiveRehydrate.swift:223–232`) so on the next launch the *old* snapshot can resume ahead of the new one. The web does the same (`index.html:10348–10352`), so this is inherited, not a port bug. Prod: 21 abandoned / 5 final live rounds — the graveyard is real even without this.
- **Missing feedback:** "Round finished from another phone — the cards posted" is a 2.6 s toast that ends the round for a visitor with no recap (`LiveRoundStore.swift:710–713`).
- **Delight:** the scoreboard hero speaks the game's own sentence; the hole-done `.impact`; skins carry-heat pulse; the Dynamic Island. Keep.

### Flow F · Finish → recap → share
- **Goal:** "Settle it, post it, brag."
- **Friction:** finish sheet → recap sheet → swipe → **an empty "Set up the round" screen** with a Close button (`LiveRoundHost.swift:49–57`, `LiveRoundStore.swift:784–787`). The posted rows ("Galen · 84 · POSTED · 18 HOLES · ✓ ATTESTED") are not tappable — `LiveRecapSheet` takes no links, `LiveLinks.openReceipt` is never used by it — so the golfer cannot open their own receipt from the recap.
- **Terminology:** "Complete cards post to the season, attested by the group" for a one-player Just-score round (`LiveCopy.swift:507`); "✓ ATTESTED" on every posted row regardless of the D125a fact (`LiveFinishViews.swift:75` prints it unconditionally); "This one was casual — post nothing" is good.
- **Dead ends:** the recap has no "what next" either — no rematch, no "put it on the tee sheet for next Saturday", no "start a season with these four".
- **Delight:** the hole strip and highlight chips ("WON 3 STRAIGHT · 4-6", "CLOSED OUT ON 15"); the settlement PNG; guest recap links per row. Keep.

### Flow G · The guest pencil and the claim
- **Goal (guest):** "Score my own card on my phone; keep it afterwards if I want."
- **Friction:** the link lands a signed-out phone straight in `LivePlayView` (no toolbar, `LiveRoundHost.swift:142`) — right for a pencil. After the round: the door card's single sentence is the best first line in the product ("Ed — 84 at Papago, Sat Aug 22. Enter your email to keep it.").
- **Terminology:** "Your pencil for today's round on Cup Season" (share message, `LivePlayView.swift:492`); "No account needed — the link is their pencil now and their recap after" (`:485`) — "pencil" again.
- **Dead ends:** a guest who declines the email keeps nothing — by design (D107 "never an unwanted account").
- **Prod:** 29 guest seats, 1 claimed seat, 0 claim links logged in `growth_events` — the funnel exists and has not moved.

### Flow H · Plan a tee time
- **Goal:** "Saturday, Papago, 7:40 — who's in?"
- **Friction:** small; day/time/course/note/tags/CTA on one sheet.
- **Terminology (exact):** "BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST" (`DeclareRoundSheet.swift:39`) — "post" is the round verb one row up on the cover · "On the tee sheet: the boards know" · "Posts to your leagues' boards: tagged golfers are named. Scratch it any time from the calendar." (`:80`) — three nouns (tee sheet, boards, calendar) for where it goes · league-less with no buddies: "No one to tag yet. Add buddies from the You tab, or invite the league." (`:69`) — there is no league to invite.
- **Dead ends:** none; but nothing connects the plan to the live door on the day except the setup's plan bridge (D134 placements are elsewhere).
- **Prod:** 4 planned rounds ever.

### Flow I · Reading a round (receipt)
- **Goal:** "What did that 84 do?"
- **Friction:** the verdict row ("Against your playing number +2.4 — BEAT YOUR NUMBER") is right; the arithmetic rows above it ("84 − 71.2 × 113 ⁄ 128 = 11.3 VS COURSE", "Your number that day", "Playing number") are §16 show-your-work at the top of the sheet rather than folded under it.
- **Terminology:** "PAPAGO GC · 18 HOLES · 2026-08-22" — an ISO date in the subtitle (`ReceiptSeed.swift:78–81`); M-083 asked for one human date and the ceremony already has one ("SAT AUG 22").
- **Delight:** instant open from cache, photo with marker medallion, "Played with …", "See the scorecard". Keep.

---

## Section 3 — Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Damages" names the brief's five questions: **WHAT** is happening · **WHY** it matters to me · **NOW** what can I do · **WHO** am I competing with · **NEXT** what happens.

**PP-01 · A course typed by hand cannot be posted, and nothing says why** — **P0** (INFERRED from code + constraint; not run)
- Observed: `PostCalc.preview` scores a blank rating as 0 (`PostCard.swift:238–244`: `card.ratingValue` → 0, `slope` → 113) and returns a full preview; the hero prints "5 pts · Sunset Match" and "-73.6 vs your index"; `tapPost` only guards `preview != nil` (`PostRoundModel.swift:201`); the insert carries `rating: 0` (`PostCard.swift:298`) and hits `check (rating between 25 and 90)` (`20260718173100_security_hardening_medium.sql:58`, NOT VALID — still enforced on new rows); the two skew retries drop course id and photo, then throw (`PostService.swift:70–81`); the golfer sees "Post failed. That didn't go through — please try again." (`PeopleModels.swift:160–161`) for 2.6 s. The rating row reads "Rating / slope — / — · edit" and never says required (`PostRoundScreen.swift:175–191`). The web fixed exactly this as Q-22 (`index.html:6989–6999`); prod shows 0 rating-less rounds, consistent with the constraint doing the refusing.
- Damages: NOW, WHY.
- Recommend: mirror Q-22 on the phone — with a gross and no rating, the hero says "Pick a tee — or type the rating and slope — to see the score" and Post is disabled; better, let a course-only post go through with the course's default tee (or 72/113, badged) so a casual golfer never learns the words rating/slope on their first post.

**PP-02 · There is no "make the next one count" — the post flow ends in a close** — **P1** (SAW)
- Observed: ceremony buttons are "Share the card" and "Back to the board" (`FinishCeremonyView.swift:55–64`); the epilogue's are "Share the card"/"Share a link — no account needed"/"Turn off this link" (`EpilogueSheet.swift:32–42`); then `onDone` dismisses the cover (`PostRoundScreen.swift:136–140`). `PostLinks.openPeople` and `openReceipt` are wired (`MainTabView.swift:390–392`) and used nowhere in `Post/*`. A league-less golfer's whole nudge is one line of fine print on the composer ("No league yet? The round still counts on your card — points apply in any league you join.", `PostRoundScreen.swift:436`) and "ON YOUR CARD" on the ceremony. Prod: 14 of 39 profiles have no league; 1 has posted.
- Damages: NEXT, WHO.
- Recommend: a third act after the ceremony keyed to state — no league: "Want this to count for something? Start a season with your group / Join one with a code / Put next Saturday on the tee sheet"; in a league: "See where it put you" (the receipt / standings) + "Challenge Jade to next week's clash"; always: "Who did you play with?" chips (see PP-05).

**PP-03 · The ceremony and the shared card assert "beat your number by 5.8" for a golfer with no number** — **P1** (INFERRED, code read)
- Observed: `PostCalc.preview` computes `vs` against `fallbackIndex = 18` even when `provisional` (`PostCard.swift:236–246`); the hero hides it (`PostRoundScreen.swift:424–425`), but `submit()` passes `vs: preview.vs` into the ceremony (`PostRoundModel.swift:247`), whose `band` is `vsPhrase(vs)` whenever `|vs| ≤ 30` (`PostEpilogue.swift:155`, `PostCard.swift:266–269`) and whose `recap` carries `pvi: vs` onto the 1080×1350 PNG as "BEAT THEIR NUMBER" (`PostEpilogue.swift:172`, `RecapCardView.swift:43–44`). D124 ruled "nothing derived from [the blind 18] reaches a screen"; `PostCard.swift:212–216` says the same. Prod has 0 `index_provisional` rounds so far, so no tester has seen it yet — it is waiting for the first starter-less golfer.
- Damages: WHY (a false verdict at the peak moment, and on the artifact that leaves the app).
- Recommend: when `preview.provisional`, pass `vs: nil` and `points: nil` to the ceremony and put "FIRST ROUND · SETS YOUR NUMBER" on the points line; the recap badge becomes "FIRST ROUND ON THE BOARD".

**PP-04 · The live setup is a settings page, not a "who / when / what are we playing for" sheet** — **P1** (SAW)
- Observed: four cards, one scroll, ~20 named concepts before "Tee off →" (`LiveSetupView.swift:24–34`): course, tee, rating, slope, 18/9, "Enter the pars", the foursome, 2v2 vs everyone, the court, six chip groups, search the app, guest name + index + "estimated 18", five games, four stake nouns, strokes off the low man, estimated stroke index, "Who's on this tee" + Bluetooth. Tee/Rating/Slope are visible on every setup (`:94–103`) with silent 72/113 fallbacks the golfer is never told about (`LiveModels.swift:201–202`). No "Customize" fold exists.
- Damages: NOW, WHAT.
- Recommend: three questions in order — **Who's playing?** (chips + "add a name"), **What game?** (Just score default; Match play / Wolf / Skins as three cards with a one-line how-to and the seat rule always visible per D133), **Anything on it?** ($0 default) — then Tee off; course/tee/rating/pars/nearby/2v2 pairing behind "Customize" with the course search prefilled from the plan bridge or last round.

**PP-05 · The quick post has no "who did you play with" — the brief's "opponents" field does not exist** — **P1** (SAW)
- Observed: `PostCard` carries course, nines, rating, slope, date, photo (`PostCard.swift:47–55`); `PostPayload` has no partner field (`:278–289`); "Played with" on the receipt exists only for live rounds (`ReceiptSeed.swift:208`). The only partner path is the scan's claim links (`PostPartnersSheet`, 0 minted in prod).
- Damages: WHO, NEXT (no rivalry, no clash, no "challenge" can hang off a typed round).
- Recommend: an optional "Played with" chip row (buddies, recent partners, league mates — the same `recent_partners` the tee sheet uses) on the composer; a tagged partner gets a "Jerecho posted an 84 with you — post yours?" nudge, which is the cheapest competition-creation loop in the product.

**PP-06 · "Total only" is impossible — and typing the 18-hole total into Front 9 silently posts a nine** — **P1** (INFERRED from `inputs`)
- Observed: the card is "Front 9 gross / Back 9 gross" only (`PostRoundScreen.swift:257–259`); `PostCard.inputs` with side 18 and `b9` empty returns `(84, 0)` (`PostCard.swift:68–70`) and `preview` treats any single nine as a 9-hole round at half value (`:250–261`), so an "84" in the front box previews "84 · 9 holes · half value" and posts as `holes_played: 9`, `nine_rating = rating/2` (`:297–303`). The fine print assumes everyone keeps nines ("How most golfers keep it — 41 out, 43 in", `:269`).
- Damages: NOW (the golfer who knows "I shot 84" has no honest box), WHAT.
- Recommend: one **Score** box first ("84"), with "split it into nines" as the optional fold; keep the 9-hole seg for real nines; refuse (or ask) when a single box carries a plausible 18-hole total on an 18-hole card.

**PP-07 · D131's noun rulings are not in this area: "counts on your card" and "tee sheet" for the live scorer still ship** — **P1** (SAW)
- Observed strings at tip: "counts on your card and in every league" (`PostCoverView.swift:100`); "The round still counts on your card" (`PostRoundScreen.swift:436`); chip "counts on your card" (`:453`); "it counts on your card and in every league" (`PostHoleGrid.swift:297`); "COUNTS ON YOUR CARD" fallback (`PostEpilogue.swift:163`); "On your card" (`LeagueCopy.swift:223`) uppercased on the ceremony. "Tee sheet" for the live round: plan bridge (`LiveSetupView.swift:67–68`), "put you on the tee sheet" (`LiveCopy.swift:274`, `LiveRehydrate.swift:231, 275`), "ask them to open the tee sheet" (`LiveRoundStore.swift:246`), composer toolbar hint (`PostRoundScreen.swift:128`). "Card" unqualified: 37 user-facing strings in the area. The prior audit found *every* tester read "COUNTS ON YOUR CARD" as "counted" (M-061; D131 ruling).
- Damages: WHY, WHAT.
- Recommend: build D131 here — "posts to your rounds — every league you're in reads it"; the live scorer is "a live round"; "card" only for the golfer card; the hole-by-hole thing is "the scorecard"; the artifact is "the recap"/"the settlement".

**PP-08 · "Change setup" mid-round orphans the server round and can resurrect the wrong one** — **P1** (INFERRED; inherited from the web)
- Observed: `backToSetup()` sets `stage = .setup; active = false` and leaves the session (`LiveRoundStore.swift:578–581`); no `repo.abandon`, no `disk.removeSnapshot`. `teeOff()` then creates a new server round (`:492`, `:541`). The abandoned `lr` stays `status = 'live'` for every other participant (their `LiveNowBar`/banner/push still point at it), and `LiveRehydrator.run` resumes `disk.snapshots().first` (`LiveRehydrate.swift:223–232`) with no ordering, so a relaunch may reopen the old round. `index.html:10348–10352` does the same. Prod `live_rounds`: 21 abandoned, 5 final, 0 live — the graveyard is normal; this path adds silent ones.
- Damages: WHAT (two "live" rounds in the group), NEXT.
- Recommend: "Change setup" either edits the running round in place (course/game only) or abandons it explicitly ("Scrap and set up again"); remove the old snapshot; order snapshot resume by `ts`.

**PP-09 · The teaching copy on the live round contradicts two built mechanics** — **P2** (SAW)
- Observed: "Scores entered together are auto-attested: the group verifies everyone's round just by playing it … Only league members' rounds post to the season." (`LivePlayView.swift:91`). D125a: attested = the golfer's own phone joined (`20260829090000…` + D125a); D107: in a league-less round every app golfer's complete card posts (`LiveCopy.swift:485–486`). The recap prints "✓ ATTESTED" on every posted row unconditionally (`LiveFinishViews.swift:75`). The finish button says "Finish round & post to season" for league-less rounds (`LivePlayView.swift:419`) while the sheet says "each to its golfer" (`LiveCopy.swift:510`). The foursome fine print in a league round says "guests play every game, post nothing" (`LiveSetupView.swift:140`) though an app golfer added by search does post.
- Damages: WHY, WHAT.
- Recommend: one state-keyed sentence, once: "Complete cards post to each golfer's record{ and score in their leagues}. Guests without the app get a link to keep theirs." Drop "auto-attested"; print ATTESTED only when the payload says so.

**PP-10 · Finishing a live round lands on an empty "Set up the round" screen; posted cards are not tappable** — **P2** (SAW)
- Observed: `finish()` sets `stage = .setup` and shows the recap as a sheet (`LiveRoundStore.swift:784–785`); `LiveRoundHost` therefore renders `LiveSetupView` under it (`LiveRoundHost.swift:49–57`); `LiveRecapSheet(data:store:)` has no links and its posted rows are plain `checkRow`s (`LiveFinishViews.swift:74–76`).
- Damages: NEXT, WHY.
- Recommend: on recap dismiss call `links.done()`; make each posted row open its receipt; add "Same four next Saturday?" (declare with tags prefilled) and, league-less, "Turn this group into a season".

**PP-11 · D133 (teach every game before the seats fill; say once what side games never touch) is not on the phone** — **P2** (SAW)
- Observed: the game card shows one `note` for the picked game (`LiveSetupView.swift:292`, `LiveModels.swift:35–43`); the seat rule appears only inside `LiveCopy.preview` (money games only, `LiveCopy.swift:284–299`) or as a tee-off toast (`LiveModels.swift:85–93`); no (i); "Bank unit" never defined; no "side games never touch season points" on setup (the play view's eyebrow says "settled between friends", `LivePlayView.swift:81`).
- Damages: WHAT, WHY.
- Recommend: build D133's three lines per game + the seat rule as a visible chip ("Wolf · exactly 4"), and the one sentence on the setup and the recap.

**PP-12 · "Welcome to the season ⛳" greets a golfer with no season; the first-round row can print twice** — **P2** (SAW + INFERRED)
- Observed: `PostEpilogue.title(firstEver:)` → "Welcome to the season ⛳" and the inserted row's sub "Welcome to the season — your number and record start here" (`PostEpilogue.swift:88, 93`) regardless of membership; the server's `first_round` achievement (23 awarded in prod) renders as "Your first round is on the board / Welcome to the season" via `achievements[]` (`:55, 74–77`), so the first-ever epilogue can carry both rows.
- Damages: WHAT.
- Recommend: title "Your first round" with a state-keyed sub ("It starts your number" / "Welcome to {league}"); dedupe `first_round` against `firstEver`.

**PP-13 · Two names for one figure on one card: "vs your index" vs "your number"** — **P2** (SAW)
- Observed: chip "-0.4 vs your index" (`PostRoundScreen.swift:428`) under the sentence "Played to your number" (`CSBands.vsPhrase`); eyebrow "your index 10.9"; receipt "Against your playing number"; brand canon: one fact, one place.
- Damages: WHY.
- Recommend: "your number" everywhere on golfer surfaces; "index" only on the card/settings where it is edited.

**PP-14 · Wrong-state fine print on the composer** — **P2** (SAW)
- Observed: "A preview — your league's own math scores it on the books." for a golfer with no league (`PostRoundScreen.swift:434`, unconditional); "Every posted round scores. Your best few each month count toward your squad…" (`:329–332`) for solo-structure leagues and league-less golfers (M-130 remains); the whole "How points work" table renders league-less.
- Damages: WHY, WHAT.
- Recommend: key on `membership` and structure; league-less: hide the bands and say "This round builds your number. Points appear when it scores in a league."

**PP-15 · Recent-course rows print unlabeled "72 / 126"** — **P2** (SAW, screenshot + `PostRoundScreen.swift:158–166`)
- Observed: mono figures with no label until the "Rating / slope" row beneath; M-150 still open visually (a11y label exists).
- Damages: WHAT.
- Recommend: drop the figures from the row (they fill on tap and the toast says so) or label them "71.2 / 128 · rating / slope".

**PP-16 · The nearby (Bluetooth) card sits on every setup with a 40-word privacy paragraph** — **P2** (SAW `LiveSetupView.swift:167–184`)
- Damages: NOW (one more thing to read before Tee off).
- Recommend: fold it under Customize / the "add a golfer" door as one toggle line; the paragraph moves to the first-enable moment.

**PP-17 · Guest add asks for an "Index"** — **P2** (SAW `LiveSetupView.swift:129–137`, `:139` "Leave index blank for an estimated 18.")
- Damages: NOW, WHO (a casual golfer does not know their buddy's index; "estimated 18" is jargon).
- Recommend: name only; strokes appear as "Ed plays off 18 until he posts" behind Customize.

**PP-18 · The scan — "the fastest way to post" (D36) — is a pill under Details, used once** — **P2** opportunity (SAW `PostRoundScreen.swift:284–297`; prod `scan_post` n=1, flag on)
- Damages: NOW.
- Recommend: camera as a first-class door on the cover ("Snap the card") and as the composer hero's secondary action; the flag stays the gate.

**PP-19 · The toast is the only feedback for outcomes that matter** — **P2** (SAW `SliceComponents.swift:26`, 2.6 s)
- Observed: "Post failed…", "Photo didn't stick — posting the round without it", "Round finished from another phone — the cards posted", "No answer — ask them to open the tee sheet", "That round was scrapped" all vanish in 2.6 s with no persistent state.
- Damages: WHAT, NEXT.
- Recommend: inline error on the composer (field highlighted); a persistent row on the setup for a failed ask; a recap for the visitor whose round ended elsewhere.

**PP-20 · The composer's nav bar offers a different moment ("● Play now") with no caption** — **P3** (SAW `PostRoundScreen.swift:117–129`; M-150)
- Recommend: keep the door on the cover; the composer's bar carries only Close/back.

**PP-21 · Back from a CTA-opened composer lands on a cover the golfer never saw** — **P3** (SAW `PostCoverView.swift:82`; `HomeView.swift:165–169`, `YouScreen.swift:138`)
- Recommend: when `startOnComposer`, present the composer as the root with Close.

**PP-22 · "Back to the board" does not go to a board** — **P3** (SAW `PostEpilogue.swift:168`; `PostRoundScreen.swift:136`)
- Recommend: "Done" — or make it true (open the board/receipt).

**PP-23 · "Start over — clear this card" is a permanent bottom-bar row under Post** — **P3** (SAW `PostRoundScreen.swift:380–384`)
- Recommend: move to the nav bar overflow or show only when the card is non-blank.

**PP-24 · "9 holes · half value · half a round" vs the Guide's "a real round"** — **P3** (SAW `PostCard.swift:202`, `PostRoundScreen.swift:269`, `ReceiptSeed.swift:206`; `Cup-Season-Guide.md:96`)
- Recommend: one sentence: "A nine counts — it's worth half the points of an eighteen."

**PP-25 · ISO dates on the receipt subtitle** — **P3** (SAW `ReceiptSeed.swift:78–81`; ceremony uses "SAT AUG 22")
- Recommend: `PostCeremony.when` everywhere.

**PP-26 · The receipt leads with the arithmetic** — **P3** (SAW `ReceiptSeed.swift:160–189`)
- Recommend: verdict + points first; "How this was scored" folds the rating/slope/differential rows.

**PP-27 · "Pencil" leaks from the codebase** — **P3** (SAW `LiveCopy.swift:254` "Solo pencil · scores live on this phone"; `LivePlayView.swift:485, 492`)
- Recommend: "Scoring on this phone"; "the link is their scorecard".

**PP-28 · Golf-engine abbreviations on the hole view** — **P3** (SAW `LiveCopy.swift:186, 195`; `LiveSlotChip` `:330`)
- Observed: "12.4 IDX · 3 STK", "EST 18.0 IDX", "SELF", "PAR 4 · SI 7", "EST. CARD", "B"/"G".
- Recommend: "3 strokes" as the gold dots already say; "SI" → "hardest 7th" or drop; "EST" → "est." with a word.

**PP-29 · The live eyebrow prints rating/slope** — **P3** (SAW `LiveModels.swift:301–306` "Live round · Papago · Blue · 71.2/128")
- Recommend: course · tee only; the numbers live under Customize.

**PP-30 · "Join this round?" offers Join / Not me — no plain "No thanks"** — **P3** (SAW `LiveRoundHost.swift:229–241`; D158 rationale noted)
- Recommend: three answers: Join · Not today · Not me.

**PP-31 · Plan sheet nouns: "the moment you post", "tee sheet", "boards", "calendar"** — **P3** (SAW `DeclareRoundSheet.swift:38–39, 80, 151`; `PostCoverView.swift:102`)
- Recommend: "Your buddies and leagues see it right away"; one noun for the destination.

**PP-32 · League-less plan sheet says "invite the league"** — **P3** (SAW `DeclareRoundSheet.swift:69`)
- Recommend: key on `leagueId`: "Add buddies from You to tag them."

**PP-33 · Group phones sheet: "League members just open the app — a Continue your round banner is waiting on Home" + "Sync is off for this round (it started before the update)"** — **P3** (SAW `LivePlayView.swift:473`)
- Recommend: "Anyone in the round opens the app — the LIVE bar brings them in"; drop the update sentence.

**PP-34 · Solo scoreboard says "YOU LEADS"** — **P3** (SAW `LiveCopy.swift:229–236`, one player)
- Recommend: single seat → "+2 NET THRU 3".

**PP-35 · The even-par guard's copy repeats "counts on your card and in every league"** — **P3** (SAW `PostHoleGrid.swift:297`) — folds into PP-07.

**PP-36 · "Enter the pars" / "Set the pars" nine-digit strings** — **P3** (SAW `LiveSetupView.swift:577–634`, `PostHoleGrid.swift:217–285`)
- Recommend: keep behind Customize; a tee pick already fills it.

**PP-37 · The date sheet allows tomorrow** — **P3** (SAW `PostRoundScreen.swift:491`)
- Recommend: cap at today (timezone slack server-side).

**PP-38 · The epilogue carries "Turn off this link" + revocation fine print on the first-ever round** — **P3** (SAW `EpilogueSheet.swift:37–41`)
- Recommend: revoke lives on the receipt/share management, not the moment.

**PP-39 · The cover's "20 seconds" is not what the product measures** — **P3** (SAW `PostCoverView.swift:100`; prod median 39 s, p90 76 s, n=24)
- Recommend: say nothing numeric, or say what is true ("front nine, back nine, done").

---

## Section 4 — What already serves the brief (keep)

- **Three-tense cover with LIVE leading** (`PostCoverView.swift:90–102`; D110): one sentence, three doors, the live door wears ember and breathes. The ⊕ as a verb that snaps back (`MainTabView.swift:338`).
- **Solo "Play now" in three taps**: You pre-seated (`LiveRoundStore.swift:165`), "Just score" default (`LiveModels.swift:87`), silent course fallbacks — a league-less golfer can score a round alone or with strangers and it posts to their record (`LiveCopy.swift:485–511`; `20260829090000_leagueless_live_rounds.sql:194–214`). D107 is built and prod has league-less rounds.
- **The composer is a scorecard, not a form**: live gross hero with `numericText` transitions, the band sentence, points/vs chips (`PostRoundScreen.swift:405–460`); course memory (`PostService.swift:26–38`); a tee pick fills rating/slope *and* real pars, a 9-hole tee flips the side (`PostRoundModel.swift:105–116`, `PostCard.swift:146–170`).
- **The provisional hero is honest**: no number → "No number yet — this round starts it" and "21.5 vs course", never a signed figure (`PostRoundScreen.swift:424–425`, `PostCard.swift:181–204`).
- **The draft survives an app kill** (24 h, `PostCard.swift:366–385`, `PostRoundModel.swift:174–196`) with a human toast.
- **Degrade, never dead-end**: photo upload failure posts the round anyway (`PostRoundModel.swift:218–221`); scan failures fall to typed entry with named toasts (`:147–160`, `PostCard.swift:459–463`); course search never hides silently (`CourseSearchModel.run`, `DeclareRoundSheet.swift:330–343`).
- **The ceremony**: dusk, 2.5 s stagger, ball-into-cup, `.success` haptic, gold only when points are real, the D122 note that says *why* a round did not score for the league (`FinishCeremonyView.swift`, `PostEpilogue.swift:157–166`, `PostCard.swift:468–493`).
- **The epilogue names feelings, not stats** (`PostEpilogue.swift:47–56`: "That one goes on the wall", "Iron man doesn't take weeks off") and speaks the rivalry ("You lead Jade 3–1 all-time · your clash this week counted", `:78–85`).
- **The recap PNG obeys D2**: gross, third-person band, course/date/points, one badge, no index/differential/league (`RecapCardView.swift:1–8, 41–50`).
- **The live round follows you**: `LiveNowBar` on every tab (`LiveNowBar.swift`), the Home banner, the Live Activity that goes stale honestly at 45 min (`LiveActivityHost.swift:33–45`), Close that never ends the round (`LiveRoundHost.swift:27–48`).
- **The nearby handshake asks on the other phone** and gives up out loud after 20 s (`LiveRoundStore.swift:222–247`); the invite alert follows the app (`LiveRoundHost.swift:206–241`).
- **The scoreboard speaks the game's sentence** ("ALL SQUARE", "HOLE 7 WORTH 3 SKINS", "GALEN IS THE WOLF · COMEBACK", `LiveCopy.swift:28–130, 211–249`); side games sit above the finish block (D153).
- **Finish is neutral and stateful**: "ALL 18 IN · 4 CARDS READY" / "JADE'S CARD IS SHORT" / "THRU 9 · 4 CARDS READY IF YOU STOP HERE" (`LiveCopy.swift:448–479`), and the sheet names the missing holes and offers "This one was casual — post nothing" (`:481–512`).
- **Two-tap scrap that disarms itself** (`LivePlayView.swift:426–445`: "Tap again to scrap — nothing posts, for anyone").
- **Landscape reads the card** (`LiveCardView.swift`; D152), stroke pips only when the SI is real (`:100–105`).
- **The recap's hole strip and highlights** ("WON 3 STRAIGHT · 4-6", "CLOSED OUT ON 15", `LiveResult.swift:58–72`), guest recap links per row (`LiveFinishViews.swift:80–89`).
- **The guest door's first sentence** ("Ed — 84 at Papago, Sat Aug 22. Enter your email to keep it.", `LiveClaim.swift:50–63`) and token-is-identity pencil with no account (`LiveRoundHost.swift:123–192`).
- **The receipt opens instantly from cache and shows its work** (`RoundReceiptSheet.swift:82–96`, `ReceiptSeed.swift:152–211`), including the D124 sentence and D209's playing number.
- **Voice moments worth protecting**: "On the tee, good luck everybody" (`LiveRoundStore.swift:571`), "Card read — 2 holes I couldn't make out are set to par", "Your unposted round came back — it's waiting in Post a round", "They're still out there — your card lands here when the round finishes" (`LiveClaim.swift:95`).

---

## Section 5 — What I could not determine from reading

- **PP-01 on a device**: I traced blank rating → 0 → check constraint → generic toast in code and SQL; I did not run it. Prod's 0 rating-less rounds is consistent with the constraint refusing, not proof of the UI path.
- **PP-12's duplicate row**: depends on `round_moments` awarding `first_round` before `round_epilogue` is read in the same post; the 23/23 award count says the trigger fires, the timing I did not test.
- **PP-08 on two phones**: the orphan/resurrection is a code read of `backToSetup`, `teeOff`, `persist` and `LiveRehydrator`; I did not reproduce the second phone's view.
- **Timings are thin**: 24 submits from 5 golfers; 199 of 212 rounds are backdated/seeded. The 39 s median is the only real number and it is small-n.
- **What Home shows after a post** (league-less or not) and D134's six placements (Standings/League tab/Next tile) belong to other readers; I only confirmed `HomeView.swift:165–169` opens the composer and `HomeView.swift:58` hosts the resume banner.
- **Push after a post / tee-off** (`push_nudges`, the D104 ask after the first round at `EpilogueSheet.swift:54`) — not read beyond the call sites.
- **The Dynamic Island's rendering** — the widget extension target was not read; only `LiveActivityHost` and `CSRoundActivity`.
- **`LiveEngines` correctness** (match/wolf/skins/Sunningdale arithmetic) — out of scope; I audited the words, not the math.
- **Whether `index_provisional` is being set in prod** — 0 rows carry it; either no starter-less golfer has posted since the D124 migration or it is not applied. Memory notes say D221's four migrations are unapplied; I did not check which.
- **The web's current state for each finding** — spot-checked only Q-22 (fixed there, not here) and `#backToSetup` (same behaviour). IOS-018 says the web is the reference; on PP-01 the phone is behind it.
- **Accessibility at the accessibility sizes and VoiceOver order** — labels exist throughout; I did not run the reader.
