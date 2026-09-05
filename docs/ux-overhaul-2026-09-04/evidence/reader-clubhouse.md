# Reader "clubhouse" — the Clubhouse tab and the league room

Blind-ish first-principles read of the iOS Clubhouse tab (`apps/ios/CupSeason/Clubhouse`, `League/*`, `Board/*`, `Schedule/*`, `Rounds/AlbumScreen.swift`) and the Kit behind it, at tip `3bba87e`, 2026-09-04. Finding ids `CH-`. Line numbers are as of tip. **SAW** = read in code or a screenshot; **INFER** = deduced; **PROD** = read-only `supabase db query --linked` on 2026-09-04.

Screens read: `apps/ios/Screenshots/6.9/02-clubhouse.png` (dark; seed league "Sunset Match" in Cup Final), `03-board.png` (its board), `01-home.png` (its Home, for the duplication map), `scratchpad/ux/shots/00-launch-default.png` (light Home on the owner's real data, Sep 4).

Prod ground truth used below (PROD, 2026-09-04): `posts` by kind — round 224 (178 in the last 30 days), moment 85 (44), system 54 (25), **chat 4 (all four in the last 30 days)**. `post_kudos` 5. `post_comments` 0. `forfeits` 0. `scheduled_rounds` 4. Rounds with a photo: 1 of 212. `week_clashes` 8. `buy_ins` 36 (28 paid). Profiles 39, onboarded (marker+handle) 29. Leagues: 5 seeded (Winter Circuit 9, Sandbox 8 complete, Ridgeline Cup 8, Sunset Match 6 cup_final, Fairway Society 5 solo), 2 real (Who's the bitch? 2 members solo $0 cap 4; Fellas 2 members solo $75 cap 4), and **six one-member "My Cup" rows stuck in `setup`** — six founders who opened the wizard and never locked (INFER from the rows; each of their Clubhouse tabs shows the setup checklist of CH-12).

---

## Section 1 — The map

Every screen, sheet and state in the area. "Reached" is the door; "First" is what the eye meets; "Primary" is the one action; "Exits" are every door out.

### 1a. The tab and its shell

| Screen / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|
| **Clubhouse tab, league-less** (`ClubhouseView.leagueless` :137-157) | Tab bar "Clubhouse" (flag) with no memberships | Nav title "Clubhouse"; `RunItBackCard` if a wrapped league exists; three equal doors "Join a league" · "Start a league" · "Start an event" (`LeaguelessDoors.swift:24-28`, `WizardState.swift:462-464`); fine "Post a round — it counts on your card. Leagues score it when you join one." (`:465`); a fourth full-width "Add golfers" (`ClubhouseView:145-150`) | none is primary — four peers | Join sheet (`JoinLeagueFlow`), wizard cover (`WizardScreen`), event picker (`presenter.showEventPicker`), People (`HomeRoute.people`) |
| **Clubhouse tab, one league** (`ClubhouseView` :60-62) | Tab bar | `EventChips` strip (if any events) then the room (below) | (the room's) | (the room's) |
| **Clubhouse tab, ≥2 leagues — paged** (D203; `ClubhouseView` :45-59) | Tab bar | 5-pt dot row above the events strip ("League 2 of 3" to VoiceOver only, `:118-134`); nav title = league in hand; toolbar glyph `arrow.left.arrow.right` opens a Menu of leagues (`:66-78`) | swipe / menu | swipe writes `store.preferredLeague` (`:110-114`); everything else = the room's |
| **Clubhouse pushed from Home** (`HomeRoute.league`, `.pot` — `MainTabView.swift:160-165, 195-200`) | Home hero tap ("See the table →"), Home league row, Home "You still owe" line (lands on Pot pane) | The one league, un-paged; menu still present if ≥2 leagues (`ClubhouseView:66`) | (the room's) | back |
| **Room — loading** (`LeagueRoomScreen` :64-65) | any | Hero skeleton "Loading the room…" (`:164`); no tabs, no panes until loaded | — | — |
| **Room — failed** (`:56-63`) | any | Card "The room did not load" + server text + "Try again" | Try again | back |
| **Room — loaded** (`:67-80`) | any | `LeagueHeaderCard` hero → `CancelBanner` → `CSTabStrip` (Standings · Board · Schedule · Pot · Album · League; Pot hidden at $0, `:127`) → the pane | the pane's | Board and Schedule are *doors* not panes (`:133-134`): tapping them pushes a screen and the strip's selection never lands |
| **Hero** (`LeagueHeaderCard` :148-212) | top of the room | League name (serif) · phase word (`LeagueCopy.phaseHeader`) · code chip = share sheet (hidden in setup, `:170-177`) · phaseSub eyebrow e.g. "CUP FINAL · WK 23 / 24 · FRESH SLATE · STANDARD RULES" (`:180`) · "Sun Mar 22 → Sat Sep 5 · 24 wks · THE PRO · SAM WHITLOCK" (`:183`) · "Add golfers" link (`:187-190`) · Pro-only red "Cancel this league" / "Cancel & delete this league" + note (`:192-207`) | Add golfers | People picker (`presenter.inviteTo` → `PeoplePickerSheet`, `MainTabView:357-361`); share sheet; cancel/delete sheets |
| **Cancel banner** (`CancelBanner` :230-260) | a cancel request is open | "The Pro wants to cancel X." + refund + "The season won't be played; nobody won and every buy-in comes back. Your rounds stay on your card." | Approve / Decline (member) · Call it off (Pro) | `links.leagueGone()` reloads |
| **Event chips** (`EventChips.swift:24-43`) | above the room when the golfer has/can enter events | Capsules "NAME · Ryder · Live" / "· Major · Enter the field" (`EventMath.swift:431-433`) | tap → event room | `presenter.event` |

### 1b. The six panes

| Pane / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|
| **Standings — setup** (`StandingsPane.setupChecklist` :32-47) | phase `setup` (only the Pro can be here — nobody can join before lock, D161) | "League setup · three steps to first tee"; rows "Season settings — The stakes, the rules, the format" [Continue] · "Invite the crew — One link fills the league — it opens the moment you lock" [At lock] · "Squad formation — Unlocks when settings lock" [Locked]; eyebrow "JOINS OPEN AT THE LOCK · 1 OF 4 IN — 3 SEATS OPEN" (`LeagueCopy.seatFill` :245-250) | Continue → wizard | wizard cover; hero's delete link |
| **Standings — draft** (`.draftHero` :53-71) | phase `draft` | PhaseHero "Squads are forming / The Pro has the list. / 1 PLAYER IN THE POOL · 3 SEATS OPEN"; "Form the squads" (Pro) or "See the squads" (member); "Share the invite link"; after 48 h quiet: "Joins have gone quiet — a nudge in the group chat usually does it." | Form/See the squads | draw cover (`presenter.draft`), share sheet |
| **Standings — before first tee** (`seasonBody`, `c.atStarter` :84-86) | locked, `today < starts_on` | PhaseHero "Before first tee / First tee Wed Sep 30 / KICKS OFF IN N DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" then the whole live-season body below it (strip, next-up, on-the-line, climb, table, race) with empty tables | — | as live |
| **Standings — live** (:92-125) | phase `season` | `RoomSeasonStrip` (Season W5 / 13 · The pot $150 · Your index 10.9 · Counting rounds 1 / 4 with dot meter) → `PressMeter` bar "26 days left in September" → `NextCard` "NEXT UP · SEPTEMBER · Post 3 more rounds this month — best 4 count, you've posted 1." [Live round] → "On the line $150 · CHAMPS $90 · RUNNER-UP $38 · POINTS KING $23 →" (stake>0) → head "Season race · the climb" → `ClimbView` → head "Standings" → `ClashCard` → `StandingsTableView` (story line, table, cut line, scenario line) → head "The individual race · every player" → `IndividualRaceView` (trio + table + fine) → foot: "Code · XXXX" chip + "Add golfers" | none — the pane is a read | rows → receipts (sheets); On the line → Pot pane; Live round → Post cover HUB; code chip → share sheet; Add golfers → People picker |
| **Standings — Cup Final** (:89-91, :100-104) | `seasons.status = cup_final` | PhaseHero "Cup Final / Four weeks, scored fresh. / FRESH SLATE · 8 DAYS LEFT · WHOEVER'S HOTTEST TAKES THE CUP", then strip, next-up, on-the-line, climb, then "The Cup Final" `CupFinalRaceView` (seed rows) over "The regular season — final" table, race | — | finalist row → `FinalistReceiptSheet` |
| **Standings — wrapped** (`wrappedHero` :129-143) | `status = complete` | Gold card "Season wrapped / {champ} / took the Cup Final / 112–98.5" [See how it ended] [Run it back — Season 2] — followed by the SAME live body (strip, next-up, climb, table, race; only `PressMeter` is gated) | Run it back | ceremony sheet; `presenter.runBack` |
| **Board** (door → `BoardScreen`) | strip "Board"; Home fold line "THE BOARD ↗"; push route `.board` | Title "THE BOARD / SUNSET MATCH"; "Earlier" loader; 📌 pinned Pro announcement; "SINCE YOU WERE HERE" digest on a quiet day; date separators; rows: round story cards, ✦ moments, ◆ system notes (a live-settlement note is a door "›" to the scorecard), chat rows; composer "Message the league…" [📣 Pro] [Send] pinned bottom | Send a message | back; name → Tour Card; card → receipt; ⚑ → report sheet; 📣 → announce sheet; system door → `ScorecardSheet` |
| **Board — empty** (`BoardStore:105-108`) | no posts | one synthetic ◆ "{League} is live — post the first round" under "Today · Sep 4" — no door | — | — |
| **Schedule** (door → `ScheduleScreen`, league-agnostic, `ScheduleScreen.swift:22-29`) | strip "Schedule"; Home "THE CALENDAR ↗"; push route `.schedule` | Title "Your golf calendar"; eyebrow "Your golf calendar · yours, your buddies', your leagues'"; "In your crew's plans" rows (BUDDY / LEAGUE MATE, [I'm in]); "The calendar" month grid with three-colour dots + legend "ON THE TEE SHEET · LEAGUE MATE · SEASON DATE"; "Tap any day to put a round on the tee sheet."; [Put a round on the tee sheet]; "On the tee sheet" list; "Week by week" snapshot lines (only when the *preferred* league is live) | Put a round on the tee sheet | day sheet, declare sheet, round sheet, retag sheet; back |
| **Pot** (`PotPane` :20-69) | strip "Pot" (hidden at $0); Home owe line (`HomeRoute.pot`); On the line card | Head "Season stakes"; gold card "The pot / $450 / 6 × $75 · $375 collected · 1 still owe"; trio band "$270 Cup champs · $113 Runner-up · $68 Points king"; (flag-hidden `PotPassCard` "League pass · Pro only"); head "Buy-ins · 5/6 in"; one row per member with a ✓ (dim when unpaid); "The other stakes · pride, on the books" [Post a stake]; "No stakes on the books. The cookout isn't going to bet itself." | Pro: tap a name to mark paid. Member: nothing | forfeit create/settle sheets |
| **Pot — $0 league** | — | The tab is hidden (D70). If reached via `HomeRoute.pot` (guarded on Home, INFER unreachable): "The pot / None / Bragging rights · no money in play", trio "—", "No buy-ins — this league plays for bragging rights." | — | — |
| **Album** (`RoomAlbumPane` :14-52) | strip "Album" | "The album · every round photo this season"; "Opening the album…" then a 3-col grid by month, or `CSEmptyState` 📷 "Photos land here when rounds carry them — add one from the Post card." [Post a round] | Post a round → Post cover HUB | tile → round receipt |
| **Album (pushed `AlbumScreen`)** (`ClubRoute.album`) | **unreachable** — `MainTabView` declares the destination (`:153, :182`) but nothing appends `.album` (SAW: grep found no appender) | "Album" title, same grid, `RoundReceiptSheet` | — | — |
| **League** (`LeaguePane` :62-118) | strip "League" | Head "League"; rows: "Members & invites · N players" [View] · "Share the season · A public page — the standings so far, no account needed" [Link] [✕ / Sure? Turn it off] · "ROSTER OPEN · 5 IN / Works until you close it, or until first tee — Sun Mar 22." [Roster's set / Reopen] (Pro) · "Squads · Complete · rosters locked" [View] · `LookRoomSection` "Dress the room" · "League notices" toggle (Pro) or a bell line (member) · DisclosureGroup "League rules" → "The bylaws · locked at first tee" + `BylawsCard` + (Pro) finish dial + "How scoring & handicaps work →" | none | Members sheet; share sheet; draw cover; scoring help sheet |

### 1c. The sheets

| Sheet | From | Shows | Primary | Exits |
|---|---|---|---|---|
| **SquadReceiptSheet** (`ReceiptSheets.swift:10-86`) | squad row (table / climb) | "{Squad} / CAPT. X · N PLAYERS · N PTS"; math rows "Counting rounds", ledger lines "Aug · Dave · 1 round short of the floor −5", "Total"; "Trend" sparkline; "Who built it" player rows "N ROUNDS · AVG vs index +1.2"; fine "Squad points = everyone's counting rounds + the ledger…" | tap a player | → MemberHistorySheet (replaces) |
| **MemberHistorySheet** (`:88-133`) | player row / solo rung / squad receipt | "{Name} / N ROUNDS · N PTS"; rows "AUG 12 · 9 HOLES · BUMPED — +1.2 vs index · 9 PTS"; fine "Bumped rounds still happened…"; [Tour Card]; empty ⛳ "No rounds this season yet — post one and you're on the board." [Post a round] | row → receipt | Tour Card; Post cover hub |
| **FinalistReceiptSheet** (`CupFinalRaceView.swift:70-122`) | Cup Final row | "SEED 1 · 42 PTS IN THE FINAL"; "Head start · top seed +10", "Window rounds · scored fresh", "Seeded by", "Total in the Final"; server `cap_note`; "The rounds" list; fine "Only rounds inside the four-week window count here…" | row → receipt | — |
| **ScoringHelpSheet** (`GuideSheets.swift:24-54`) | BylawsCard "How scoring & handicaps work →" (4 taps deep) | the one scoring guide (`GuideCopy.scoring`) | — | — |
| **SeasonCeremonyView** (`SeasonCeremonyView.swift`) | auto once per member 400 ms after a complete room loads (`LeagueRoomScreen:94-97`); "See how it ended" | Dusk sheet "The Cup Final / Season complete / {champ} / took the Cup Final / 112–98.5 / by 13.5 / decided on {rung}"; "Runner-up", "Points king"; "You're owed $270 — Cup champion"; "The pot — $450 · collected $375" [PREVIEW when client math]; rows; "Still owed to the pot"; the ledger line verbatim; [Run it back — Season 2] [Close] | Run it back | — |
| **MembersSheet** (`MembersSheet.swift`) | League pane "View" | "Members & invites / 6 PLAYERS · CODE TSTSUN"; rows face · name · "THE PRO" · "@handle · INDEX 12.4 · SQUAD"; me: [Marker here]; Pro tools under others: [Set index] [Remove / Bye] [Make Pro] (two-tap arms, reason shown while armed); "Invites out ✉ x@y · WAITING"; [Add golfers] (Pro); [Share the invite link] | Add golfers | face → Tour Card; SetIndexSheet; People picker; share sheet |
| **SetIndexSheet** (`:161-185`) | Members "Set index" | "Starter index / A NUMBER TO START FROM"; "A starting number for X. Once they post 3 rounds, their own scores take over." | Set the index | — |
| **ForfeitCreateSheet** (`PotPane.swift:171-227`) | Pot "Post a stake" | "Post a stake / Pride, on the books — never money"; Name it · The shape (Loser hosts / Winner picks the course / Strokes next time / Standing bounty / Name your own) · The terms · Against (The field — first to hit it / a member) · Rides on (optional) | Put it on the books | — |
| **ForfeitSettleSheet** (`:251-281`) | Pot row "Settle" | "Settle the stake"; "Who took it?" pills; "A line for the archive (optional)" | a name | — |
| **CancelLeagueSheet** (`LeaguePane.swift:194-226`) | hero danger link (in season) | "Cancel {name}? / THE SEASON IS UNDER WAY"; fine; red "Start the cancellation"; "Keep it" | Keep it (quiet) vs red | — |
| **DeleteLeagueSheet** (`:229-266`) | hero danger link (pre-tee) | "Delete {name}? / ONLY POSSIBLE BEFORE THE FIRST TEE" or "THIS TAKES EVERYONE'S SEAT" + typed-name gate | Delete | — |
| **AnnounceSheet** (`BoardSheets.swift:13-62`) | Board 📣 (Pro) | "📣 FROM THE PRO"; field; "N / 280"; [Announce] | Announce | Cancel |
| **ReportSheet** (`:64-121`) | Board ⚑ | "KEEPS THE BOARDS CLEAN"; "What's wrong with it? Your note goes to the founder desk with the post."; Spam / Harassment / Not their round / Something else; field | Send the report | Cancel |
| **ScorecardSheet** (`ScorecardSheet.swift`) | a ◆ settlement row with a live round | "Scorecard"; eyebrow + story; hole grid (sideways scroll); footer | — | Close |
| **Day sheet** (`ScheduleScreen.swift:172-203`) | calendar cell with items | "{Sat Sep 12} / 2 ON THE SHEET"; rows; league rows "⛳ Week closes — snapshot recorded"; [Put your round on this day] | Put your round | round sheet; declare |
| **DeclareRoundSheet** (`DeclareRoundSheet.swift`) | calendar CTA / empty cell / "I'm in" | "Put a round on the tee sheet / BUDDIES & LEAGUE MATES SEE IT THE MOMENT YOU POST" (or "Get in on it / YOUR ROUND POSTS AND SCORES ON ITS OWN — YOU BOTH SHOW ON THE DAY"); Day · Tee time · optional · Course · Note · optional · Tag your group | On the tee sheet / I'm in | Cancel |
| **ScheduledRoundSheet** (`ScheduledRoundSheet.swift`) | any round row | "{Sat Sep 12} / 7:40a tee"; course + meta + place; tee chip, weather chip; note; rivalry line "◇ you lead 1–0 · one more round."; "Who's in · 2 in" rows with pills; [I'm in] [Maybe] [Can't]; "On the board" comments + "Say something to the group…" [Send]; owner: [Edit group] [Cancel round / Sure? Cancel it] | I'm in | Done; name → Tour Card; retag sheet |

### 1d. Doors out of the room (complete)

Share sheet (code chip ×3 places, "Share the invite link" ×2, "Share the season") · People picker ("Add golfers" ×3 places) · Wizard cover ("Continue" in setup) · Draw cover ("Form/See the squads", League "Squads · View") · Post cover **hub** ("Live round", every "Post a round") · Board screen · Schedule screen (global) · Tour Card (member face, chat name, story-card name, "Tour Card" button) · Round receipt (every points figure, album tile, clash side) · Scorecard sheet (settlement rows) · Event room (chips) · Run it back (`presenter.runBack`) · Ceremony · Cancel/Delete · `leagueGone` → reload → league-less doors.

---

## Section 2 — The flows

### F1. "Open the Clubhouse and know where I stand" (member, season live)
- **Goal:** where am I, who's winning, what's next, what can I do — in one glance.
- **Current friction (SAW, 02-clubhouse.png + `StandingsPane.swift:82-111`):** the first screen is hero (name, phase, code, rules meta, dates, Pro, Add golfers) → tab strip → phase hero → four-stat strip → next-up → on-the-line. **My rank is not on the first screen.** The climb ("You · Name") is the seventh block; the story sentence ("Scorpions lead by 12 · Coyotes a good weekend back") is under the ninth. Home, one tab to the left, opens on "2nd" in hero type (01-home.png). The tab that is *named* for the league is the one that does not say where I am.
- **Unnecessary complexity:** six panes for one league; two of the six (Board, Schedule) are not panes; the strip needs a horizontal scroll to reach the sixth (02-clubhouse.png shows "LEAGUE" clipped at the right edge; `Surfaces.swift:228, 256`).
- **Terminology (exact):** "CUP FINAL · WK 23 / 24 · FRESH SLATE · STANDARD RULES" (`LeagueCopy.phaseSub` :237); "THE PRO · SAM WHITLOCK" (`LeagueRoomScreen:183`, no definition — D132's chip definition is not built, SAW grep); "Counting rounds · 3 rounds · August · every round counts" (`StandingsPane:198-213`); "Season race · the climb" (`:98`); "The individual race · every player" (`:110`); "Δ Wk" (`StandingsTableView:64`); "Avg vs index" (`IndividualRaceView:52`); "PROJECTED — SETTLED WHEN THE SEASON CLOSES" (`:30`); "Cut line · top 2 advance" (`StandingsTableView:39`); "SEEDS LOCKED — … INTO THE CUP FINAL" (`StandingsMath` ScenarioLine :458-459).
- **Dead ends:** none hard; but "NEXT UP · AUGUST" ends in a button "Live round" that opens the ⊕ hub, not a live round (`ClubhouseView:171` → `postOnComposer=false; showPost=true` → `PostCoverView:95-101` three doors).
- **Redundant:** the same fact said 3-4 times (CH-07, CH-08, CH-09, CH-53); "Add golfers" and the code chip appear at the head and the foot of the same pane (`LeagueRoomScreen:170-190`, `StandingsPane:112-125`).
- **Missing feedback:** nothing says the pane was refreshed; `.refreshable` exists (`LeagueRoomScreen:89`) but the strip's figures don't announce change except the rank flip.
- **Delight opportunities:** the story sentence and the climb's "12 ahead of you — the top seed" voice are the best writing in the room and are buried; put them first. The rank-up haptic (`ClubhouseView:97-102`) is a good instinct — pair it with a visible "▲ up 1 since Sunday" at the top.

### F2. "Switch to my other league"
- **Goal:** see the other room.
- **Friction:** discovery = five 5-pt dots (`ClubhouseView:118-134`) + an unlabeled ⇄ glyph (`:75`); Home's league rows (`HomeView.swift:1015-1072`) are a clearer switcher than the Clubhouse's own. Swiping also silently rewrites `store.preferredLeague` (`:110-114`) so Home re-lenses behind your back (D203 intends this).
- **Terminology:** none.
- **Dead ends:** pushed-in room (from Home) is un-paged but the menu remains (`:66-78`) — two behaviours for one screen.
- **Missing feedback:** no league name inside the page besides the hero (title changes, dots don't say which).
- **Delight:** a swipe that moves a whole room is fun; a one-line "You're 2nd here · 1st in Fellas" strip would make the second league a *reason* to swipe.

### F3. "Read the board / say something / react / comment / announce / report"
- **Goal:** feel the group.
- **Friction (SAW 03-board.png, PROD):** three consecutive `RoundStoryCard`s from the same golfer, each with a four-chip reaction bar (🔥 · + · ⚑ · 💬); the whole visible screen is Priya's April rounds; one moment; one system line; one chat line. PROD: **4 chat posts, 5 reactions, 0 comments in the product's life** against 224 round posts. The board is a ledger with a composer stapled to the bottom; the only human voice in prod is the seed script's "Floor is 2 rounds this month. No excuses."
- **Complexity:** two chats exist — the Board and the per-round "On the board" thread inside `ScheduledRoundSheet:86-103`; comments on round posts are a third thread (`ReactionBar:144-171`, "Talk your talk…").
- **Terminology:** "87 GROSS · POSTED ANYWAY" (`BoardLogic.grossLine` :62-70) beside a raw "-4.9" chip (`CSBands.pviChip` :92-94, `RoundStoryCard:77-83`) — the band and the differential on one line; "COUNTING #5 THIS MONTH" (`BoardLogic:44-46`); "Grand Canyon University GC · 18 holes · 2026-04-12" — ISO date (`BoardLogic.courseLine` :77 prints `r.playedOn` raw; SAW in 03-board.png); "◆ Sunset Match is live — say hello on the board"; "📌 FROM THE PRO"; composer "Message the league…"; report "KEEPS THE BOARDS CLEAN … goes to the founder desk".
- **Dead ends:** the empty board's synthetic line "{League} is live — post the first round" (`BoardStore:106-107`) has no door; the announce sheet is Pro-only and the 📣 is a bare emoji button.
- **Redundant:** the same round is a card here, a row on Home's lane, and a line in Home's digest.
- **Missing feedback:** a sent chat is echoed then replaced silently (good); a failed reaction reverts with a toast (good); nothing tells the sender anyone read it.
- **Delight:** the moment rows ("✦ Priya set a personal best. New number to chase.") are the voice the whole board should have; group a golfer's week ("Priya · 3 rounds this week · best 80 at Papago") and let the card wall breathe.

### F4. "Check the pot / find out how to pay / mark a buy-in"
- **Goal (member):** how much, to whom, how, by when. **Goal (Pro):** who has paid.
- **Friction (SAW):** `PotPane` shows the two numbers (D106) and a member row list whose rows are `Button`s that only toast "The Pro marks buy-ins as the money moves between friends" (`PotPane:86-97`). **The Pro's pay note and due date (D129, migration `20260830040000_buy_in_terms.sql:22-23,33-60`) never reach the pane**: `LeagueRoomModel`'s settings select omits `buy_in_note`/`buy_in_due_on` (`LeagueRoomModel.swift:197`), `LeagueRoom.Settings` has no field for them (`LeagueRoomRows.swift:30-62`), and `PotPane` has zero references (grep 0/0/0). Home's owe line *does* say "Venmo @casey · by Sat Sep 5" (`HomeHeroCopy.swift:225-237`) and links to this pane (`HomeRoute.pot`) — which then does not repeat the instruction.
- **Complexity:** the trio "Cup champs · Runner-up · Points king" (`:45-47`) is a projection with rounding drift ($450 → 270 + 113 + 68 = $451; `PotMath.trioDollars` :25-28 rounds each; prior audit M-111 still open); a flag-hidden pricing card sits between the trio and the buy-ins (`:52-56`).
- **Terminology:** "Season stakes" (head) vs "The other stakes · pride, on the books" (`:133`) vs "Post a stake · Pride, on the books — never money" (`:189`) — D131 ruled *stake* = money on a live game and pride bets = *forfeits*, "the books" = money; the pane still says the opposite. "Buy-ins · 5/6 in"; "✓" dim glyph unlabeled to the eye (a11y label only, `:116`).
- **Dead ends:** a member has no action at all on the Pot pane except pride bets (0 in prod, ever).
- **Missing feedback:** Pro marking a buy-in: haptic only, no line "Marked — $75 in from Galen"; no board post from the phone path (the server may post — not verified).
- **Delight:** the ceremony's "You're owed $270 — Cup champion" (`SeasonCeremonyView:42-43`) is the emotional payoff; the season-long pane could carry a version ("If it ended today: you'd take $270").

### F5. "Post / settle a pride bet"
- **Goal:** put "loser hosts the cookout" on the record.
- **Friction:** a five-field sheet (Name it · The shape · The terms · Against · Rides on) for a one-sentence bet; the "shape" pills prefill the terms and the name stays blank (placeholder "The Lawn Bet"). PROD: 0 forfeits ever.
- **Terminology:** "Post a stake", "Put it on the books", "Stakes settle on a party's tap and archive into the record. The pot stays money; this never is." (`PotPane:223`) — the last sentence exists *because* the noun is wrong.
- **Dead ends:** none. **Redundant:** name + terms + shape overlap.
- **Delight:** the empty line "The cookout isn't going to bet itself." (`:134`) is the right voice; make the whole thing one line: "Loser hosts · you v Galen · rides on the Cup Final" [Put it on the record].

### F6. "Plan a round with the crew" (Schedule)
- **Goal:** "we're playing Saturday — who's in?"
- **Friction (SAW):** the room's "Schedule" tab pushes a global "Your golf calendar" (`ScheduleScreen.swift:48`) — the league name, chips and strip are gone (prior audit M-070, still exactly so on the phone); the grid is a month calendar with three dot colours and a legend; the CTA is below the grid; "Week by week" (league snapshot lines) sits at the very bottom and only for the *preferred* league (`:336`), not the league whose tab you tapped. PROD: 4 scheduled rounds ever.
- **Complexity:** Declare sheet = Day · Tee time (toggle) · Course (two-stage search) · Note · Tag chips (cap 7) — reasonable, but reached 3 taps deep from the room.
- **Terminology:** "tee sheet" ×9 on one screen ("Put a round on the tee sheet", "ON THE TEE SHEET", "Nothing on the tee sheet for September…"), "In your crew's plans", "SEASON DATE" (legend, unexplained), "Week closes — snapshot recorded" (day sheet), `WeekLine.empty` "…the first snapshot writes **Sunday night**…" (`ScheduleModels.swift:351`, hard-coded weekday against §14.0/M-17), "BUDDY" / "LEAGUE MATE" / "YOU'RE IN" caps tags.
- **Dead ends:** a past day with nothing is disabled (`:148`); fine.
- **Redundant:** Home already has "Coming up" + "THE CALENDAR ↗" + Up Next chips (`UpcomingRoundsSection.swift:33-54`); the Schedule *door* in the room adds nothing league-specific.
- **Missing feedback:** after declaring, the sheet dismisses and the calendar reloads; the toast "On the tee sheet: the boards know" is good.
- **Delight:** `ScheduledRoundSheet`'s weather chip and rivalry line "◇ you lead 1–0 · one more round." (`:60-63`) are exactly the anticipation the brief asks for; they are three sheets deep.

### F7. "See the album"
- **Goal:** relive.
- **Friction:** a sixth tab for a feature with **1 photo in 212 rounds** (PROD); the empty state names "the Post card" (D131 retired "card" in that sense); "Post a round" opens the ⊕ hub, not the composer, and not the photo step.
- **Dead ends:** the pushed `AlbumScreen` is unreachable (no `ClubRoute.album` appender — SAW).
- **Delight:** a photo as the *hero's ground* for the week (the `RoundStoryCard` already does this with the dusk scrim, `:103-117`) would make one photo matter more than a grid.

### F8. "Run the league" (the Pro)
- **Goal:** invite, mark money, set the finish, curate notices, cancel.
- **Friction:** the tools are scattered: Add golfers (hero, Standings foot, Members sheet), buy-ins (Pot), finish dial (inside the "League rules" disclosure, `BylawsCard:33-44`), roster door (League pane), notices (League pane), look (League pane), cancel/delete (hero), announce (Board 📣), member tools (Members sheet pills "Set index · Bye · Make Pro" under every row, `MembersSheet:82-101`).
- **Terminology:** "Roster's set" / "Sure? The link stops working" (`LeaguePane:40`), "Reopen", "Finish: Cup Final — switch to points table" (`LeagueCopy.finishDial` :158-163), "Bye" / "Sure? Bye for Sep", "Make Pro" / "Sure? Hand it off", "Starter index / A NUMBER TO START FROM", "League notices — Floors, closes and season notices reach the crew's phones".
- **Dead ends:** the Members sheet's "Remove" exists only in setup (`:84`) — in season a Pro cannot remove anyone from the phone; "Bye" writes and dismisses with no visible state change on the row.
- **Redundant:** three "Add golfers"; two invite-link buttons; "Squads · View" (League pane) and "See the squads" (draft hero) open the same cover.
- **Missing feedback:** `setMemberBye` does not refresh the model (`LeagueRoomModel:456-458` = `127+329`); the toast is the only proof.
- **Delight:** the two-tap arm with the reason shown while armed (`MembersSheet:103-105`) is genuinely good — no alerts anywhere in the room.

### F9. "From setup to first tee" (the pre-season room)
- **Goal (founder):** get the crew in and start. **Goal (joiner):** understand what I joined.
- **Friction (SAW):** setup = a three-row checklist whose only live control is "Continue" (`StandingsPane:35-36`) and whose other two rows say "At lock" / "Locked" — a form describing a form. PROD: six one-member leagues parked in `setup`. Draft = "Squads are forming / The Pro has the list. / 1 PLAYER IN THE POOL · 3 SEATS OPEN" (prior audit M-021, verbatim still). Before first tee = a kickoff hero, then the *entire* live-season body with empty tables: "NO ROUNDS YET." / "SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND." (`LeagueCopy.standingsEmpty` :374-377, ALL CAPS, no door), "THE RACE STARTS WITH THE FIRST POSTED ROUND / SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" (`ClimbView:22-23`), trio "— / — / —", "The race fills in once your league season is live and rounds land." (`IndividualRaceView:43`).
- **Terminology:** "Squad formation" row shows in a *solo* league's checklist (`StandingsPane:41`, no `solo` guard) and in the bylaws ("Squad formation · Blind draw", `LeagueCopy.bylawsRows` :134, no guard — prior audit M-130); "SQUADS LOCKED" in the kickoff eyebrow for solo (`LeagueCopy.kickoff` :271); "tee sheet" for the roster (`ClimbView:23`, D131 says tee sheet = calendar).
- **Dead ends:** a joiner in `draft` gets "See the squads" → the Pro's draw screen (prior audit M-032).
- **Missing feedback:** who has joined since I last looked — the members count is in the eyebrow only.
- **Delight:** "Joins have gone quiet — a nudge in the group chat usually does it." (`StandingsPane:67`) — the right voice, the wrong place (it should be the *first* line, with a share button beside it).

### F10. "The season ends"
- **Goal:** the memory; the payout; what's next.
- **Friction:** the ceremony fires once (good), then the room is the same dashboard with a gold card on top — strip, next-up ("September is covered…"), climb, table, race all still render for a finished season (`StandingsPane:92-111` gate only `PressMeter`). No history: the League pane has no past seasons, the Album is "this season", and "Run it back" replaces the league's stage rather than archiving it.
- **Terminology:** "took the Cup Final" vs "took the Cup" (`:135`); "decided on {rung}" (`SeasonCeremonyView:31`); "PREVIEW" (`:55`).
- **Dead ends:** "The result posts once the season closes." (`:73`) if the ceremony opens before `season_payouts` exist.
- **Delight:** the ceremony is the best screen in the area; give it a permanent door ("The record") and a share card.

### F11. "I have no league" (the league-less Clubhouse)
- **Goal (brief):** funnel casual play → competition.
- **Friction:** four peer buttons ("Join a league", "Start a league", "Start an event", "Add golfers") under a bare "Clubhouse" title, with a fine line telling you to go post a round somewhere else (`WizardState.swift:465`). No intent framing ("play with friends" / "run a season" / "we're playing this weekend" / "beat Jake"). Prior audit M-158 ("Sign out" as a primary) is fixed — no sign-out here now.
- **Delight:** the `RunItBackCard` at the top when a wrapped league exists (`LeaguelessDoors:23-24`) is the right idea for the *returning* golfer.

### F12. "Tap a name — why is that the number?" (§16 receipts)
- **Goal:** trust the points.
- **Friction:** low — every points figure opens a sheet. The chain squad → member → receipt → Tour Card replaces sheets (dismiss then present) so back navigation is lost. The member sheet for *another* golfer with no rounds says "post one and you're on the board" + "Post a round" (`ReceiptSheets:98-99`; prior audit M-138 still exactly so).
- **Terminology:** "BUMPED", "AVG vs index", "+1.2 vs index · 9 PTS", "the ledger", "Bonuses & penalties · the ledger".
- **Delight:** the ledger rows with reasons ("Aug · Dave · 1 round short of the floor") are exactly "everything shows its work".

### F13. "The Cup Final" read
- **Goal:** who's hot, how long left, am I in it.
- **Friction:** four statements of "Cup Final" on the first screen (CH-07); the race block is *below* strip + next-up + on-the-line + climb (`StandingsPane:100-104`); the seed rows read "STARTS +10 · TOP SEED · WINDOW 24 PTS · 3 ROUNDS OF 4" in caps (`CupFinalRaceView:44-46`).
- **Delight:** "Whoever's hottest takes the cup" is the sentence; lead with the two names and the gap.

---

## Section 3 — Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Damages" names the brief's five questions: **WHAT** (what is happening) · **WHY-ME** (why it matters to me) · **NOW** (what I can do right now) · **WHO** (who I compete with) · **NEXT** (what happens next).

### CH-01 · The room's first screen answers none of the five questions — my rank is below the fold — **P0**
- **Observed (SAW 02-clubhouse.png; `StandingsPane.swift:82-111`):** order is hero → strip → phase hero → four stats → "NEXT UP · AUGUST · August is covered — 3 rounds counting…" → "ON THE LINE". The viewer's place ("You · Coyotes") first appears in `ClimbView` after the seventh block; the story sentence after the ninth. Home shows "2nd" in hero type (01-home.png). The tab named for the league is the one surface that does not say where I am.
- **Evidence:** `StandingsPane.swift:92-99` (strip, meter, next, on-the-line before the climb); `ClimbView.swift:58` ("You · \(name)"); `StandingsTableView.swift:22` (story line under the table head).
- **Damages:** WHY-ME, WHO, WHAT.
- **Recommendation:** open the room on the story: rank + gap + who's above/below + the one sentence, then the clock, then everything else.

### CH-02 · The Board is a ledger with a composer, not a living feed — **P1**
- **Observed (PROD; SAW 03-board.png):** 224 round posts, 85 moments, 54 system, **4 chat, 5 reactions, 0 comments** — all-time. The screen renders one full `RoundStoryCard` per round with a 4-chip `ReactionBar` under every card (`BoardScreen.swift:80`, `BoardRows.swift:206-224`, `ReactionBar.swift:33-67`); three consecutive cards from one golfer fill the screenshot. The empty board is a synthetic system line with no door (`BoardStore.swift:105-108`).
- **Damages:** WHAT, WHO, NOW (nothing invites a reply).
- **Recommendation:** group a golfer's rounds per week into one story row; make moments and clashes the headline rows; one quick reaction on the row, the tray on hold; put a prompt in the composer that changes with the beat ("Galen just took the week — say something").

### CH-03 · The Pot pane cannot say how money gets paid — D129's terms never reach it — **P1**
- **Observed (SAW):** `set_buy_in_terms` and `league_settings.buy_in_note / buy_in_due_on` exist (`supabase/migrations/20260830040000_buy_in_terms.sql:22-23,33-60`) and `Me.Membership.buy_in.note/due_on` are decoded for Home (`Models.swift:102-115`), but `LeagueRoomModel.swift:197` selects neither column, `LeagueRoom.Settings` (`LeagueRoomRows.swift:30-62`) has no field, and `PotPane.swift` has no reference (grep 0). A member's row tap toasts "The Pro marks buy-ins as the money moves between friends" (`PotPane.swift:89`). Home's owe line (`HomeHeroCopy.swift:225-237`) says "Venmo @casey · by Sat Sep 5" and links to this pane, which then falls silent.
- **Damages:** NOW, NEXT (for the Pro: how the pot fills).
- **Recommendation:** render the terms at the top of the pane ("Pay Sam · Venmo @sam · by Sat Sep 5"; Pro sees "Edit"); member rows become status rows; the Pro's collector line "$375 of $450 in · 1 owes".

### CH-04 · "Schedule" is a tab that leaves the league — **P1**
- **Observed (SAW):** `links.openSchedule()` pushes `ClubRoute.schedule` → `ScheduleScreen(links:)` with **no league id** (`MainTabView.swift:152,181`; `ScheduleScreen.swift:22-29`); title "Your golf calendar"; "Week by week" reads the *preferred* league (`:336`), not the tapped one. Prior audit M-070 is unchanged on the phone.
- **Damages:** WHAT (which league am I in now?), NEXT.
- **Recommendation:** either a real league pane ("This week: Galen v you · Week closes Sat · Galen's playing Papago Sat 7:40") or drop the tab and put the calendar on Home/⊕ where it already lives.

### CH-05 · Two of six "tabs" are doors — the strip lies about its own model — **P1**
- **Observed (SAW):** `roomTabs` intercepts `.board` and `.schedule` and navigates instead of selecting (`LeagueRoomScreen.swift:129-137`); `CSTabStrip` animates an underline to the tapped item (`Surfaces.swift:233`) that is then never the selection. `RoomRouter` refuses both (`RoomBits.swift:215`).
- **Damages:** NOW.
- **Recommendation:** tabs are panes; doors are rows or buttons. Four panes at most.

### CH-06 · Six tabs do not fit; the sixth is clipped with no affordance — **P2**
- **Observed (SAW 02-clubhouse.png):** "LEAGUE" is cut at the right edge on a 6.9" screen at default type; the strip is a horizontal `ScrollView` (`Surfaces.swift:228`) whose own comment says "a tab is never clipped, only off to the right" (`:256`).
- **Damages:** NOW.
- **Recommendation:** ≤4 panes, or a segmented control that wraps.

### CH-07 · "Cup Final" is stated four times on one screen — **P1**
- **Observed (SAW 02-clubhouse.png):** hero phase line "Cup Final" (`LeagueRoomScreen.swift:164` ← `LeagueCopy.phaseHeader` :225-228); hero eyebrow "CUP FINAL · WK 23 / 24 · FRESH SLATE · STANDARD RULES" (`:180` ← `phaseSub` :237); PhaseHero "CUP FINAL / Four weeks, scored fresh. / FRESH SLATE · 8 DAYS LEFT · WHOEVER'S HOTTEST TAKES THE CUP" (`StandingsPane.swift:89-91`); strip "CUP FINAL LIVE · 8 days left" (`:189-190` ← `deadline` :296-299). "Fresh slate" twice, "8 days left" twice.
- **Damages:** WHAT (noise), brand law "one fact, one place" (D201).
- **Recommendation:** one phase line in the hero; the PhaseHero becomes the room's opening story; the strip drops the deadline it already said.

### CH-08 · The room duplicates Home almost line for line — **P1**
- **Observed (SAW, 00-launch-default.png v. code):**

| Fact | Home | Room |
|---|---|---|
| my rank, gap, move | hero "2nd of 2 · — held · 4 back of Galen · 15 – 19" (`HomeView.swift:793-1000`, `HomeHeroCopy.swift:46-93`) | climb rung + gap + voice (`ClimbView`), table row (`StandingsTableView:72-127`), race row (`IndividualRaceView:60-96`) |
| week N of M | hero eyebrow "week 5 of 13"; league row "Week 7 of 26" (`HomeLeagueRow.swift:61-70`) | hero eyebrow "Wk 23 / 24"; strip "W23 / 24" |
| counting rule + month clock | foot "Best 4 rounds a month count · 1 posted · 26 days left in September" (`HomeHeroCopy.footRule` :154-166) | strip "Counting rounds 1 / 4" + dot meter + "September · your best 4 count"; `PressMeter` "26 days left in September"; `NextCard` "Post 3 more rounds this month — best 4 count, you've posted 1."; bylaws "COUNTING CAP Best 4 / mo" |
| endgame | foot endgame sentence (`footEndgame` :183-187) | PhaseHero, cut line, climb note "TOP 2 ADVANCE TO THE CUP FINAL", scenario line, bylaws "CUP FINAL" row, deadline "Cup Final · Tue Oct 6 · 32d" |
| money | foot "$150 on the books · $0 collected"; owe line (`footMoney` :196-207, `owe` :225-237) | strip "The pot $150 · 1/2 buy-ins in"; "On the line" card; Pot hero; ceremony |
| the clash | `HomeLeadCard` clash (`HomeLeadCard.swift:34,74,83`) | `ClashCard` in Standings (`StandingsPane.swift:332-400`) |
| next round | Up Next chip + "Coming up" card (`UpcomingRoundsSection.swift`) | Schedule door |
| league notes | folded line → board (D217) | Board |

- **Damages:** WHAT (two surfaces, one question — D93/D94), and it makes the Clubhouse feel like a dashboard *behind* the story.
- **Recommendation:** decide what the room owns that Home does not (the full table, the receipts, the money sheet, the members, the record) and strip the rest.

### CH-09 · The viewer appears three times in one pane (climb, table, race) — **P2**
- **Observed (SAW):** `StandingsPane.swift:98-111` renders `ClimbView`, `StandingsTableView` and `IndividualRaceView` back to back; in a solo league all three list the same people in the same order (`StandingsMath.soloTeams` :145-148 ← `indRows`). Prior audit M-129, unchanged.
- **Damages:** WHO (which list is the race?).
- **Recommendation:** one race per structure: solo = the climb *is* the table; squads = climb of squads, then "your squad" receipt.

### CH-10 · The hero is a settings card, not a story — **P1**
- **Observed (SAW 02-clubhouse.png; `LeagueRoomScreen.swift:157-210`):** name · phase word · code chip · "CUP FINAL · WK 23 / 24 · FRESH SLATE · STANDARD RULES" · "Sun Mar 22 → Sat Sep 5 · 24 wks · THE PRO · SAM WHITLOCK" · "Add golfers" (mono, `dawn` link colour) · (Pro) red "Cancel this league" + "(the season is under way — a pot needs every member to approve)". "STANDARD RULES" is undefined (prior audit M-026, open); "THE PRO" is undefined — D132's ruled chip "THE PRO · GALEN · runs the league" is not built (SAW: grep "runs the league" = 0 hits).
- **Damages:** WHAT, WHY-ME; brand ("admin aesthetics").
- **Recommendation:** hero = league name + the sentence of the week ("Galen leads by 4. Week closes Saturday.") + one door. Dates, rules, Pro, code belong on the League pane.

### CH-11 · The danger zone lives in the hero — **P2**
- **Observed (SAW):** for the Pro, "Cancel & delete this league" / "Cancel this league" in `neg` red plus its note is the hero's last line in every non-complete phase (`LeagueRoomScreen.swift:192-207`). Prior audit M-022, unchanged on the phone.
- **Damages:** WHAT (the most destructive act sits beside the most-read line).
- **Recommendation:** bottom of the League pane, under a disclosure.

### CH-12 · Setup is a checklist about a form, and six founders are parked on it — **P1**
- **Observed (SAW; PROD):** `setupChecklist` (`StandingsPane.swift:32-47`): "League setup · three steps to first tee" → "Season settings — The stakes, the rules, the format [Continue]" · "Invite the crew — One link fills the league — it opens the moment you lock [At lock]" · "Squad formation — Unlocks when settings lock [Locked]" · "JOINS OPEN AT THE LOCK · 1 OF 4 IN — 3 SEATS OPEN". Six real "My Cup" leagues sit in `setup` with one member each (PROD).
- **Damages:** NOW, NEXT (activation).
- **Recommendation:** an intent screen, not a checklist: "Who's playing? · When? · What for?" with the invite link *first* (D161 says the code opens at lock — so lock on the founder's behalf with defaults and let them customise).

### CH-13 · Draft room is the Pro's screen shown to a member — **P2**
- **Observed (SAW):** "Squads are forming / The Pro has the list. / 1 PLAYER IN THE POOL · 3 SEATS OPEN" (`StandingsPane.swift:54-55`, `LeagueCopy.draftPoolSub` :253-256); member CTA "See the squads" → `presenter.draft` = the draw cover (`ClubhouseView.swift:167`; prior audit M-021/M-032, both still so).
- **Damages:** NEXT (what happens to me, when).
- **Recommendation:** member copy = "Sam draws the squads before first tee — random. You'll get a push." and no draw door.

### CH-14 · Solo leagues still hear "squad" — **P2**
- **Observed (SAW):** setup row "Squad formation" has no `solo` guard (`StandingsPane.swift:41`); bylaws row "Squad formation · Blind draw" has none (`LeagueCopy.bylawsRows` :134); kickoff eyebrow "SQUADS LOCKED" (`kickoff` :271); race fine "All three run in parallel with the squad race — see How scoring works." (`IndividualRaceView.swift:99`) — and "see How scoring works" is text, not a link. Both real prod leagues are solo. Prior audit M-130 partially open.
- **Damages:** WHAT.
- **Recommendation:** structure-aware producers for all four; make "How scoring works" a door.

### CH-15 · Empty states are ALL-CAPS failure lines with no door — **P2**
- **Observed (SAW):** "NO ROUNDS YET." / "SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND." (`LeagueCopy.standingsEmpty` :374-377 via `StandingsTableView.swift:27-34`); "THE RACE STARTS WITH THE FIRST POSTED ROUND" / "SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" (`ClimbView.swift:22-23`, no button, and "tee sheet" misused per D131); trio "— / — / —" (`IndividualRaceView.swift:33-36`). Only the race's `CSEmptyState` carries a CTA (`:43-44`).
- **Damages:** NOW.
- **Recommendation:** one empty state per pane, sentence case, ending in the one move ("Nobody's posted. Be first — Post a round").

### CH-16 · "Live round" and every "Post a round" in the room open the ⊕ hub, not what they say — **P2**
- **Observed (SAW):** `links.openRecord` = `p.postOnComposer = false; p.showPost = true` (`ClubhouseView.swift:171`) → `PostCoverView` opens on the three-door hub "Play now — score the group / Post a round — after you play / Plan a tee time — before" (`PostCoverView.swift:40,95-101`). Callers: `NextCard` "Live round" (`StandingsPane.swift:320`), album empty "Post a round" (`RoomAlbumPane.swift:21`), race empty (`IndividualRaceView.swift:44`), member history empty (`ReceiptSheets.swift:99`). The `NextCard` is about the counting cap, not about a live round (prior audit M-153).
- **Damages:** NOW (a promise, then a menu).
- **Recommendation:** `openRecord(.live)` / `.post` / `.plan` — land on the named door; or drop the button from a card that is not about it.

### CH-17 · The season strip is a four-KPI dashboard — **P2**
- **Observed (SAW 02-clubhouse.png; `RoomSeasonStrip` `StandingsPane.swift:173-244`):** "SEASON W23 / 24 · CUP FINAL LIVE · 8 days left" · "THE POT $450 · 5/6 buy-ins in" · "YOUR INDEX 10.9 · ▼ 1.5 this season" · "COUNTING ROUNDS 3 rounds · August · every round counts" — four mono figures with sub-lines. IOS-019 rule 1 turned the 2×2 grid into a strip; it is still a stat row, and "Your index" is not the league's story (prior audit M-121: index told three ways).
- **Damages:** brand ("no SaaS dashboards"), WHY-ME.
- **Recommendation:** fold week + clock into the hero sentence; money to the On-the-line card; index to You; counting to the next-up line.

### CH-18 · Board cards print the ISO date — **P2**
- **Observed (SAW 03-board.png):** "Grand Canyon University GC · 18 holes · 2026-04-12" — `BoardLogic.courseLine` (`BoardLogic.swift:75-78`) appends `r.playedOn` raw. Prior audit M-083 fixed elsewhere (`MemberHistorySheet` uses `LeagueDates.monDay`), not here.
- **Damages:** WHAT (reads as a database row).
- **Recommendation:** `BoardText.shortDate` / "Sat · Apr 12"; better, drop the date from the card — the separator already says it.

### CH-19 · The PvI chip is a raw number beside the named band — **P2**
- **Observed (SAW 03-board.png):** "87 GROSS · POSTED ANYWAY" and a red chip "-4.9" (`RoundStoryCard.swift:77-83`, `CSBands.pviChip` :92-94). Brand canon §3: "Named bands, never math jargon"; prior audit M-045 (minus reads as worse, which it is, but the unit is unnamed).
- **Damages:** WHAT.
- **Recommendation:** the band *is* the chip; the number lives on the receipt.

### CH-20 · Same golfer, three cards in a row, four chips each — the wall — **P2**
- **Observed (SAW 03-board.png):** three Priya cards (Apr 12, 17, 22) with ~180 pt of chrome each; a moment row between; the `LazyVStack` has no grouping (`BoardScreen.swift:65-83`; `BoardRowsList` :189-225).
- **Damages:** WHAT, WHO.
- **Recommendation:** collapse a golfer's consecutive rounds into one row ("Priya · 3 rounds this week · best 80 at Papago · 9 pts") that expands.

### CH-21 · The board is two things (feed + chat) and says so in three vocabularies — **P2**
- **Observed (SAW):** toolbar "THE BOARD / SUNSET MATCH" (`BoardScreen.swift:44-52`), title "The board" (`:41`), composer "Message the league…" (`:101`), synthetic "…is live — post the first round" (`BoardStore.swift:107`), Home fold "league notes" (D217), Guide "the Board (chat and round posts)" (`Cup-Season-Guide.md:84`). Prior audit M-156 open.
- **Damages:** WHAT.
- **Recommendation:** one noun and one metaphor — the group chat where the league's own lines also land (the way iMessage shows "X joined").

### CH-22 · The report flag is a peer of the reactions — **P3**
- **Observed (SAW):** "🔥 · + · ⚑ · 💬" in one `FlowRow` (`ReactionBar.swift:33-67`); the flag has the same capsule (`:39-48`). Prior audit M-137 open.
- **Recommendation:** report under a long-press / "…" menu.

### CH-23 · The compact board is dead code — the room has no board preview at all — **P2**
- **Observed (SAW):** `LeagueRoomScreen.swift:73` renders `EmptyView()` for `.board`; `BoardCompactList` (`BoardScreen.swift:151-185`) has no caller (grep). The league's most alive content (rounds, moments) is not on the room's first screen in any form.
- **Damages:** WHAT.
- **Recommendation:** either delete it or use it — three latest lines under the hero with "The board ›".

### CH-24 · Member rows on the Pot pane are buttons that do nothing but scold — **P1**
- **Observed (SAW):** every row is a `Button` (`PotPane.swift:99-118`); for a member the action toasts "The Pro marks buy-ins as the money moves between friends" (`:89`); the ✓ is `dim` at 50% opacity when unpaid (`:106`) — a disabled-looking control that is the *state*. Prior audit M-110/M-111 open.
- **Damages:** NOW.
- **Recommendation:** status rows ("Paid ✓" / "Not yet") for everyone; a button only for the Pro, labelled "Mark paid".

### CH-25 · The payout trio rounds to $451 on $450 — **P2**
- **Observed (SAW):** `PotMath.trioDollars` (`PotMath.swift:25-28`) rounds each share (270 + 113 + 68 = 451) while `settlementCents` (`:31-36`) makes the champion absorb; the pane shows the former (`PotPane.swift:23,45-47`), the ceremony the latter. Prior audit M-111 open.
- **Damages:** WHAT (trust in money).
- **Recommendation:** one splitter for both surfaces; label the trio "if it ended today".

### CH-26 · Pride bets still say "stake" and "the books" — D131 unapplied on the phone — **P2**
- **Observed (SAW):** "The other stakes · pride, on the books" / "Post a stake" (`PotPane.swift:133`), "No stakes on the books…" (`:134`), sheet "Post a stake / Pride, on the books — never money" (`:189`), "Put it on the books" (`:210`), "The pot stays money; this never is." (`:223`). D131 ruled forfeits/"the record", books = money. PROD: 0 forfeits ever.
- **Damages:** WHAT (the money pane says "not money" twice).
- **Recommendation:** "Forfeits · pride, never money" · "Post a forfeit" · "Put it on the record".

### CH-27 · The League pane is a settings list — the bylaws are four taps deep — **P2**
- **Observed (SAW):** rows Members & invites · Share the season · ROSTER OPEN · Squads · Dress the room · League notices · disclosure "League rules" → BylawsCard → "How scoring & handicaps work →" (`LeaguePane.swift:62-118`, `BylawsCard.swift:46`). Prior audit M-054/M-055 (TOP-5) unchanged on the phone: Clubhouse → LEAGUE → League rules → link.
- **Damages:** WHAT (how do we win?).
- **Recommendation:** the endgame sentence and the counting rule belong on the room's first screen (they are already on Home's hero foot); the bylaws card is the record, one tap from the hero's phase line.

### CH-28 · The bylaws speak schema — **P2**
- **Observed (SAW):** "STRUCTURE 2 squads" · "Squad formation Blind draw" · "PRESET Standard" · "HANDICAP ALLOWANCE 95%" · "VERIFICATION Post what you'd post to GHIN" · "COUNTING CAP Best 4 / mo" · "PARTICIPATION FLOOR 2 / mo · −5 sqd pts / round short" · "BUY-IN $75 / player" · "POT SPLIT 60 / 25 / 15 · champ / 2nd / king" (`LeagueCopy.bylawsRows` :131-155). "sqd pts" is an abbreviation of an abbreviation. Prior audit M-060 open.
- **Damages:** WHAT.
- **Recommendation:** five sentences ("Best 4 rounds a month count. Post at least 2 or your squad gives back 5 a round. …"), the table behind "the fine print".

### CH-29 · Nothing in the room ever says "you" first — **P2**
- **Observed (SAW):** the viewer is highlighted by a `bg2` tint on their rung/row (`ClimbView.swift:84`, `IndividualRaceView.swift:88`) and "You · Name" (`ClimbView:58`); the hero, strip and phase hero are about the league. The only second-person sentence above the climb is `NextCard`'s cap line.
- **Damages:** WHY-ME.
- **Recommendation:** the hero's second line is always about the viewer ("You're 2nd · 4 back of Galen · a good weekend closes it").

### CH-30 · "Add golfers" ×3 and the code chip ×3 in one room — **P2**
- **Observed (SAW):** hero link (`LeagueRoomScreen.swift:187-190`) + hero chip (`:170-177`); Standings foot chip + "Add golfers" mini (`StandingsPane.swift:112-125`); Members sheet "Add golfers" + "Share the invite link" + "CODE X" in the sub (`MembersSheet.swift:25,37-45`).
- **Damages:** NOW (which one?).
- **Recommendation:** one invite door in the hero while the roster is open (`RosterDoor.isOpen`), none after.

### CH-31 · Another member's empty history invites *me* to post — **P2**
- **Observed (SAW):** `MemberHistorySheet` for a golfer with no rounds: "No rounds this season yet — post one and you're on the board." + "Post a round" (`ReceiptSheets.swift:98-99`), regardless of whose sheet it is. Prior audit M-138 unchanged.
- **Recommendation:** "Galen hasn't posted yet." — no CTA; for the viewer's own sheet, keep it.

### CH-32 · A sixth tab for one photo — **P2**
- **Observed (SAW; PROD):** `.album` is a full pane (`RoomPane` `RoomBits.swift:224`); 1 of 212 rounds carries a photo; empty copy "Photos land here when rounds carry them — add one from the Post card." (`RoomAlbumPane.swift:20`; "Post card" is D131-retired "card"); the pushed `AlbumScreen` is unreachable (no `ClubRoute.album` appender).
- **Damages:** NOW (a tab that is always empty is a failure state with a label).
- **Recommendation:** photos ride the story cards and the wrapped-season record; no Album tab until a league has ten.

### CH-33 · The wrapped season keeps the live dashboard under its gold card — **P2**
- **Observed (SAW):** `StandingsPane.swift:88-111` shows `wrappedHero` then `RoomSeasonStrip` (week = total, "Season complete · settled"), `NextCard` ("October is covered…" — a month the season is not in), "On the line", climb, table, race; only `PressMeter` is gated (`:94`). The League pane has no past seasons; "Run it back" (`:140`) replaces rather than archives.
- **Damages:** NEXT (what now?), HISTORY (brief's fifth layer).
- **Recommendation:** a wrapped room is a record page: champion, the table as it finished, the ceremony's rows, the album, "Season 2 →".

### CH-34 · The Cup Final race sits below four blocks that are not the race — **P2**
- **Observed (SAW):** strip → `NextCard` → on-the-line → "Season race · the climb" → then "The Cup Final" (`StandingsPane.swift:92-104`).
- **Damages:** WHAT, WHO.
- **Recommendation:** in the Final, the two seeds and the gap are the hero.

### CH-35 · The league-less Clubhouse is four peer buttons, no intent — **P1**
- **Observed (SAW):** "Join a league / Start a league / Start an event" + "Add golfers" + "Post a round — it counts on your card. Leagues score it when you join one." (`ClubhouseView.swift:137-157`, `LeaguelessDoors.swift:24-32`, `WizardState.swift:462-465`). Title "Clubhouse". No "play with friends / run a season / this weekend / beat Jake".
- **Damages:** NOW, NEXT (activation, competition creation).
- **Recommendation:** intent cards with a sentence each; the smallest one first ("We're playing Saturday → put it on the sheet"), "Start a season" last.

### CH-36 · The switcher is invisible: 5-pt dots and an unlabeled ⇄ — **P2**
- **Observed (SAW):** `dots()` 5×5 pt at 20-70% ink (`ClubhouseView.swift:118-134`); toolbar `Image(systemName: "arrow.left.arrow.right")` with no label (`:75`; prior audit M-153). Home's `HomeLeagueRows` (`HomeView.swift:1015-1072`) is the switcher people will actually use.
- **Damages:** WHO (my other crew exists?).
- **Recommendation:** a league chip row under the title (name · your rank) — the web's chips, which the Guide still describes (`Cup-Season-Guide.md:84-86` "Switch groups with the chips up top").

### CH-37 · Events are a chip strip bolted above the league room — **P3**
- **Observed (SAW):** `EventChips` (`ClubhouseView.swift:87-89`, `EventChips.swift:24-43`) render "NAME · Ryder · Live" / "· Major · Enter the field" capsules above whatever league is in hand, ordered by the open league's attachment (`:49-56`). Two competition types, one tab, two grammars.
- **Damages:** WHAT.
- **Recommendation:** events are competitions — list them with leagues in one "your competitions" switcher.

### CH-38 · "NEXT UP" is about the cap, not about what's next — **P2**
- **Observed (SAW):** `LeagueCopy.nextUp` (`:355-365`): "Next up · September — Post 3 more rounds this month — best 4 count, you've posted 1." / "September is covered — 3 rounds counting. A better one always replaces your lowest." The card wears the room's live spine (`StandingsPane.swift:313`) and a "Live round" button.
- **Damages:** NEXT.
- **Recommendation:** "Next" = the clash through Saturday, your booked round, the month close — the Up Next chips Home already computes (`ScheduleModels.swift:374-407`).

### CH-39 · The month clock is told three times — **P3**
- **Observed (SAW):** `PressMeter` "26 days left in September" (`StandingsPane.swift:283-302`), `deadline` "Month closes Oct 1 · floors assessed" in the strip (`LeagueCopy.deadline` :307), `NextCard` month sentence; Home's foot says it again.
- **Recommendation:** one clock line.

### CH-40 · The climb's empty line sends people to "the tee sheet" for a roster — **P3**
- **Observed (SAW):** "SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" (`ClimbView.swift:23`); D131: tee sheet = the calendar.
- **Recommendation:** "Share the code — the crew fills the table."

### CH-41 · Week-by-week empty copy hard-codes "Sunday night" — **P3**
- **Observed (SAW):** `WeekLine.empty` "Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season." (`ScheduleModels.swift:351`); §14.0/M-17: the week closes on the season's own weekday. Fellas closes Tuesdays (starts_on 2026-07-20 = Monday → week ends Sunday; WTB starts Monday 2026-08-03 → Sunday) — fine today, wrong for any Saturday-start league (Sunset Match starts Sunday → closes Saturday).
- **Recommendation:** derive from `starts_on`.

### CH-42 · Room loading shows a hero skeleton and nothing else — **P3**
- **Observed (SAW):** `!model.loaded` → `LeagueHeaderCard(loading: true)` only (`LeagueRoomScreen.swift:64-65`); no strip, no pane placeholder (the board has a proper `BoardSkeleton`, `BoardRows.swift:192-211`).
- **Recommendation:** skeleton the first pane too.

### CH-43 · Sheets replace sheets — the receipt chain loses its way back — **P3**
- **Observed (SAW):** `MembersSheet` face → `dismiss(); links.openTourCard` (`MembersSheet.swift:60`); `MemberHistorySheet` row → `dismiss(); links.openReceipt` (`ReceiptSheets.swift:104`); `SquadReceiptSheet` → `router.open(.member)` swaps the sheet (`:51`). Coming back means re-finding the row.
- **Recommendation:** a `NavigationStack` inside the receipt sheet.

### CH-44 · The individual race's fine print promises a link that is text — **P3**
- **Observed (SAW):** "…All three run in parallel with the squad race — see How scoring works." (`IndividualRaceView.swift:99`) — `RoomFine`, not a button; the sheet is four taps away (CH-27).
- **Recommendation:** make it the door.

### CH-45 · The story line's "a good weekend back" has no number — **P3**
- **Observed (SAW):** `StandingsMath.story` (`:239`) says "a good weekend back" for margins ≤ 15 and "N back" above; the rung under it prints the exact gap. Fine as voice; but Home says "4 back of Galen · 15 – 19" so the two disagree in register.
- **Recommendation:** keep the voice, add the figure once ("4 back — a good weekend closes it").

### CH-46 · The Cup Final seed rows are caps meta — **P3**
- **Observed (SAW):** "STARTS +10 · TOP SEED · WINDOW 24 PTS · 3 ROUNDS OF 4" (`CupFinalRaceView.swift:44-46`); eyebrow "· 8 DAYS LEFT · SEEDED BY POINTS".
- **Recommendation:** "Scorpions · 34 in the window (+10 head start) · 3 of 4 rounds used".

### CH-47 · The Members sheet is the Pro's console shown to everyone — **P3**
- **Observed (SAW):** for the Pro, three pills under every other member ("Set index · Bye · Make Pro", `MembersSheet.swift:82-101`); "Marker here" on my row with no explanation (`:74`; prior audit M-139); "@handle · INDEX 12.4 · SQUAD" sub or "GOLFER" (`:53-55,69`).
- **Recommendation:** tools behind a per-row "…"; the sheet is the crew's faces.

### CH-48 · "Share the season" carries a revoke arm beside a link that may not exist — **P3**
- **Observed (SAW):** `LeaguePane.swift:69-84` renders "Link" and "✕ / Sure? Turn it off" together; `revokeSeasonShare` mints a token to revoke it (`LeagueRoomModel.swift:538-542`).
- **Recommendation:** the ✕ appears only after a link was made.

### CH-49 · League notices / Dress the room / roster door are settings in the middle of the crew list — **P3**
- **Observed (SAW):** `LeaguePane.swift:29-49, 95, 98` interleave the roster handle, look picker and push toggle between "Members & invites" and "League rules".
- **Recommendation:** a "Settings" group at the foot for the Pro; members see the crew and the rules.

### CH-50 · The `Δ Wk` column and "WK 1" placeholder — **P3**
- **Observed (SAW):** header "Δ Wk" (`StandingsTableView.swift:64`), cell "WK 1" until a snapshot exists (`:107`); prior audit M-122.
- **Recommendation:** "This week +10" as the row's sub, no column.

### CH-51 · The room's `openRecord` doors all hit the Post *hub* even when the intent is "Live" — (see CH-16) — **P3**
- Covered by CH-16; noted so the Album and race CTAs are not fixed without the `NextCard`.

### CH-52 · The paged room silently re-lenses Home — **P3**
- **Observed (SAW):** swiping sets `store.preferredLeague` (`ClubhouseView.swift:110-114`); Home's hero, lead card and Up Next follow (D203 intent). A golfer peeking at their second league comes back to a different Home.
- **Recommendation:** keep the pages; write the preference only on a deliberate act (menu pick, tap into the room).

### CH-53 · Three "the pot" surfaces disagree on the verb — **P3**
- **Observed (SAW):** strip "5/6 buy-ins in"; Pot hero "$375 collected · 1 still owe"; head "Buy-ins · 5/6 in"; row a11y "buy-in in / not in"; Home "$450 on the books · $375 collected · 1 still owe". Four phrasings of one ledger state.
- **Recommendation:** one sentence producer for the pot's status.

### CH-54 · No rivalry in the room — **P2**
- **Observed (SAW):** `RivalryTag` renders only on the calendar and the round sheet (`ScheduleScreen.swift:98`, `ScheduledRoundSheet.swift:60-63`); the standings has the clash (`ClashCard`) and nothing else head-to-head; `my_rivalries` is never read by `LeagueRoomModel`. Prior audit M-123 partially addressed by D108.
- **Damages:** WHO.
- **Recommendation:** "You v Galen · you lead 3–1 this season" under the climb; the clash card already has the shape.

### CH-55 · The board's pinned announcement is the only thing a Pro can say and it is a bare 📣 — **P3**
- **Observed (SAW):** 📣 emoji button (`BoardScreen.swift:115-123`), sheet "📣 FROM THE PRO" (`BoardSheets.swift:26`); no Pro announcement in prod is distinguishable from the 4 chats (kind `announce` did not appear in the by-kind query — 0 rows).
- **Recommendation:** "Announce" as a labelled action in the composer's menu.

### CH-56 · The Pot tab hides at $0 but the strip still says "THE POT · None · Bragging rights" — **P3**
- **Observed (SAW):** `RoomSeasonStrip` column (`StandingsPane.swift:191-193`); prior audit M-161.
- **Recommendation:** drop the column at $0 (D70's spirit).

---

## Section 4 — What already serves the brief (keep)

- **The story sentence over the table** — "Scorpions lead by 12 · Coyotes a good weekend back." / "Dead heat — …" (`StandingsMath.swift:233-240`, `StandingsTableView.swift:141-159`). Story, not table. Promote it.
- **The climb** — a you-centred window with the cut drawn across, "12 ahead of you — the top seed", "Galen, 4 behind you", IN/OUT badges, and "··· 3 more ···" whose padding grows with distance (`StandingsMath.swift` ClimbVoice :311-326, `items` :340-407; `ClimbView.swift:104-109`). This is the room's best idea.
- **The scenario line that never invents a clinch** (`ScenarioLine.parts` :452-477) and the climb note that refuses "EVERYONE ADVANCES" for a hollow field (`ClimbMath.note` :410-427).
- **Every points figure opens the rounds behind it** (§16): squad receipt with ledger *reasons* ("Aug · Dave · 1 round short of the floor"), member history with BUMPED, finalist receipt with head start + window (`ReceiptSheets.swift`, `CupFinalRaceView.swift:70-122`).
- **The ceremony** — once per member, 400 ms after the data (`LeagueRoomScreen.swift:94-97`), server rows preferred, "PREVIEW" when not, "You're owed $270 — Cup champion", "Still owed to the pot" by name, the ledger line verbatim (`SeasonCeremonyView.swift`). The one screen that is a memory.
- **The rank-up haptic, once, only for the room in hand** (`ClubhouseView.swift:97-102`) and the split-flap rank on a fresh load (`StandingsTableView.swift:185-245`, reduced-motion aware).
- **The clash card mid-week** — best-so-far picked exactly as the settle picks (`ClashMath.bestSoFar`, `WeekClash.swift:59-74`), named bands in third person, each side a receipt door (`StandingsPane.swift:332-400`).
- **D70 at $0** — the Pot tab and On-the-line vanish (`LeagueRoomScreen.swift:127`, `StandingsPane.swift:97`).
- **The code is hidden in setup** (D161, `LeagueRoomScreen.swift:170`) and the roster door reads the same three facts the server gates on (`RosterDoor.swift:46-83`).
- **No alerts** — every consequential act is a two-tap arm with its reason shown while armed (`RoomBits.swift:39-66`, `MembersSheet.swift:85-105`, `LeaguePane.swift:40`).
- **The cancel banner** tells the member their refund and that their rounds stay (`LeagueRoomScreen.swift:241-243`).
- **Board plumbing** — optimistic writes that revert with a toast (`BoardStore.swift:231-297`), realtime on a dedicated client (`LeagueRealtime.swift`), the "SINCE YOU WERE HERE" digest on a quiet day (`BoardLogic.swift:94-104`), settlement rows that open the scorecard (`BoardRows.swift:78-116`), `easeCaps` turning server caps into sentences (`BoardText.swift:38-54`), the moment rows' voice ("✦ Priya set a personal best. New number to chase.").
- **The photo as ground** on a story card, dusk scrim, marker medallion (`RoundStoryCard.swift:103-126`).
- **Money in two numbers, never blended** (D106: `PotPane.swift:34-36`, `LeagueRoomModel.swift:150-168`).
- **`HomeRoute.pot` lands on the Pot pane** (`RoomRouter.init`, `RoomBits.swift:209-218`); push → board clears the stack first (`MainTabView.swift:419-423`); `openLeague` is one function (`:451-458`).
- **Voice where it exists:** "Joins have gone quiet — a nudge in the group chat usually does it." (`StandingsPane.swift:67`); "The cookout isn't going to bet itself." (`PotPane.swift:134`); "Bumped rounds still happened — a better round took their monthly slot." (`ReceiptSheets.swift:125`); "Whoever's hottest takes the cup."
- **Accessibility discipline** throughout — `A11yStack`, combined elements, hints on every door, the strip wraps 2×2 at accessibility sizes (`PolishWrapRow`).
- **Schedule anticipation pieces** — weather chip, "◇ you lead 1–0 · one more round.", "I'm in" from a buddy's plan, "Get in on it" (`ScheduledRoundSheet.swift:55-63`, `ScheduleScreen.swift:82-83`, `DeclareRoundSheet.swift:38-40`).
- **`RunItBackCard`** at the top of the league-less Clubhouse for a wrapped league (`LeaguelessDoors.swift:23-24`).

---

## Section 5 — What I could not determine from reading

- **How the setup / draft / before-first-tee / wrapped rooms actually render** — the only room screenshots are a seed league in Cup Final and its board; the phase branches are read from code only. The 6.9" clip of "LEAGUE" (CH-06) is one device at one type size.
- **Whether `EventChips` ever show for a real user** — no events row was queried; the chip strip's effect on the room's first screen is INFER.
- **What the Post cover does when arriving from the room with a live round already open** (`LiveNowBar`) — not read.
- **Whether the server posts a board line when the Pro marks a buy-in** (CH-03's feedback note) — the RPC body was not read.
- **`PeoplePickerSheet` (Add golfers)** — its content and whether it explains the code/link split (prior audit M-002/M-003) — outside my files.
- **The draw cover (`presenter.draft`) as seen by a member** — outside my files; the M-032 claim is carried from the prior audit and the door is verified.
- **The web's `#view-hub`** — I did not open `index.html`; parity claims are limited to strings the Swift comments cite.
- **Push copy for board events** and whether the four prod chat posts are the seed script's or humans' (INFER: seed — three of four leagues with a chat post are seeds; the fourth is Winter Circuit, also seeded).
- **Whether `BoardStore.pageSize` 120 + "Earlier" ever loads on a real league** (Ridgeline 124 posts is a seed) — no real league exceeds 19 posts.
- **Load cost of the paged neighbours** (D203 tradeoff) — not measured.
- **Whether `HomeRoute.pot` can reach a $0 league** (CH table 1b) — Home guards the owe line at stake > 0; the pot route from elsewhere was not traced.
