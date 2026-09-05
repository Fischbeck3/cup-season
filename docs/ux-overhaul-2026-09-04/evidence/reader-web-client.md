# Reader "web-client" — index.html as a product surface, and its divergence from the phone

Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (2026-09-04). Read-only. Every line number is index.html unless a path is given. **SAW** = read in code or in prod (read-only `supabase db query --linked`); **INFER** = a consequence I reason to but did not run. I did not load the page in a browser; nothing here is a screenshot.

Prod facts read on 2026-09-04 (non-sandbox rows only):
- Real leagues by structure × phase: `solo/season 3 · squads2/season 2 · squads2/setup 6 · squads4/season 1`. **3 of the 6 in-season leagues are SOLO.**
- Golfers by number of non-complete leagues they hold: `1 league: 6 · 2: 3 · 3: 6 · 4: 2`. **11 of 17 active golfers hold two or more leagues.**
- `client_events`, last 30 days: golfers who fired a **web-only** event name (`home_hero_state`, `post_open`, `home_hero_tap`, `league_create` — all `qaEvent` names, `:6898`): **8**. Golfers who fired a **phone-only** name (`signed_in`, `push_opened`, `push_prompt_shown`, `orientation_shown` — `Telemetry.swift:27-31`, `PushRouter.swift:23,32`): **5**. Both: 4. Last 14 days: `home_hero_state` 28 rows / 6 golfers (web); `signed_in` 14 / 5 (phone). Note `CSTelemetry.event` does NOT stamp `platform` (`Telemetry.swift:41-48`), so `props->>'platform'` is useless for attribution; the split above is by event NAME.
- `rounds`, last 60 days: 207 `source='quick'` from 22 golfers, 5 `source='live'` (last 2026-07-29). No column says which client posted.

---

## Section 1 · The map

### 1a · Shell, boot and the door

| Screen / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|
| **Door** `#onboard` (`:2726-2832`) | signed-out boot (`boot()` `:19994-20003`: no session → return, door stays) | Forge animation + seared wordmark; h1 *"Rally your crew. Post real rounds. Take the cup."* (`:2810`); two fiction wings on desktop ≥1100px: "Rounds hitting the board" (MARCUS/DANA/RAY… `+9 PTS`, `:4284-4300`) and "The season, live · Month 4 of 6 · every point has a receipt" (`:2917-2923`) | `Continue with email` (`:2813`) → email → 6-digit code | `I have a league code` (`:2825`) → code → email; Terms/Privacy links |
| **Golfer card** `#obProfile` (`:2833-2871`) | after first sign-in when `profile.marker` or `handle` missing (`:20008-20015`) | "Set up your golfer card." | `Save my card` (`:2866`) | none (gate) |
| **Crew step** `#obCrew` (`:2868-2889`, D151) | after card, cold arrivals only (`continueAfterCard` `:15009-15020`; skipped if `cs_code`/`cs_claim`/`cs_crew`) | "Who are you playing with?" | `Join` (code box) · `Find your buddies` · `Start a league instead` · `I'll do this later` (`:15021-15043`) | each leaves to `resumeAfterProfile()` |
| **Orientation** `#obOrient` (`:2891-2913`, D82) | after card when `cs_oriented` unset (`:14979-14982`); reopenable from You › ⚙ › How it works | "Four places. Two ways to play." four tiles + long game / short game | `Take me in` (`:2911`) | → `continueAfterCard()` |
| **Welcome** `#obWelcome` (`:2890-2896`) | (largely vestigial; `showWelcome` `:19843` is the league-less SHELL, not this) | "You're in." | — | — |
| **League-less shell** (`body.noleague`, `showWelcome` `:19843-19880`) | signed in, zero memberships | Home with the ladder hero + three doors; Clubhouse collapsed to `#hubLeagueless` | see Home | tabs |
| **Boot failure** | any throw in `boot()` | `authStatus('Boot failed at [step]…')` on the door (`:20068`); 8 s watchdog prints "Boot stalled at [step] — network or auth hang" (`:19995-19999`) | — | reload |
| **Guest pencil** (`enterGuestLive` `:9010+`) | `?claim=` link mid-round | the live tee sheet, no account | score | claim after finish |
| **Demo** (`state.demo:true` `:4083`) | the default until `showWelcome`/`resetToBlank`/`enterGuestLive` flip it (`:19847, :13581, :9024`) | nothing user-facing since D83 retired the demo season; the door's wings are the only fiction left (`:4278-4281`) | — | — |

### 1b · Navigation chrome

| Element | Where | Items (order) | Notes |
|---|---|---|---|
| Mobile tab bar `nav.tabbar` (`:3908-3913`) | bottom, <960px | Home · Clubhouse · **Post** (centre circle, `aria-label="Post a round"`, `data-v="record"`) · You | matches the phone's four (`MainTabView.swift:128,170,205,209,223`) |
| Desktop sidebar `aside.side` (`:2931-2949`) | ≥960px (`@media(min-width:960px)` `:126`) | Home · **Post a round** · Clubhouse · You + foot `#sideLeague` / `#sideMeta` | **order and label differ from the tab bar** (Post second, labelled "Post a round" for a page titled "Golf — play one live, post one you just finished, or plan the next" `:3198`) |
| Header `.hdr` (`:2955-2986`) | top | 🔍 "Find golfers" (`#hdrSearch` `:2958`) · hidden league name/phase (`:2966-2969`) · logo (home) | the phone puts the wordmark in the scroll and Find golfers in the Home `+` menu (`HomeView.swift:47,183-184`) |
| `switchView(v)` (`:4512-4590`) | every navigation | aliases: `feed→home`, `cal→schedule`, `pot→hub+setRoomSeg('pot')`, `board→openBoardFull()` dialog; gates: wizard Pro-only (`:4522-4530`), draft after lock (`:4538`) | per-view renders fire on entry (`:4563-4589`) |

### 1c · Views (`section.view`)

| View | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|
| **view-home** (`:2992-3031`; lane `renderHomeHub` `:12439-12460`) | tab; boot | `#resumeBanner` (live round) → `#homeRequests` → `#homeStart` doors (`:11086-11145`: league-less = Join a league · Start a league · Start an event + *"Post a round — it counts on your card. Leagues score it when you join one."*; member = *"Start something else…"* link) → `#homeLead` (D176 ladder `:12212-12278`) → `#homeHero` (`:11198-11474`) → `#homeTiles` League · Next · Board (`:11036-11083`) → `#homeOccasion` → `#homeUpNext` chips (`:12297-12333`) → `#homePulse` floor fine-print → head *"Around your buddies · THE BOARD ↗"* (`:3024`) → digest → feed | hero CTA (state-dependent) | tiles, chips, feed cards → receipt |
| **view-hub** (Clubhouse, `:3604-3846`) | tab; `data-go="hub"` | `#hubLeagueless` when no league (Start a league · I have a league code · Add golfers · **Sign out** `:3608-3620`); otherwise `#clubGroups` chip switcher (`renderClubGroups` `:11011-11030`) → `#hubHeader` (name, code, span, THE PRO, Add golfers, delete link) → `#cancelBanner` → six-segment `#roomSeg` Standings · Board · Schedule · Pot · Album · League (`:3642-3649`) | segment | Schedule segment routes OUT to view-schedule (`setRoomSeg` comment `:3776-3779`) |
| — room-standings (`:3664-3777`) | default segment | `#homeSetup` 3-step checklist (setup) / `#homeDraft` phasehero (draft) / `#homeSeason`: kickoff hero, live banner, 4 stat tiles (Season W/n, The pot, Your index, Counting rounds `:3695-3700`), press meter, next card, "On the line" pot button, the climb + standings (cup race, clash, story, table, scenario line), individual race (Points King · Most Improved · Iron Man) | — | `#roomFooter` (join code + Add golfers once live) |
| — room-board (`:3651-3662`) | segment | the league feed + composer; `OPEN ↗` → `#boardFull` dialog (`:3900-3906`, `openBoardFull` `:5978`) | Send | close |
| — room-pot (`:3785-3814`) | segment; `data-go="pot"` | The pot / payouts trio / ledger line (`CS_LEDGER` `:4418`) / How to pay / Buy-ins list / D64 "The other stakes · pride, on the books · Post a stake" | mark paid (Pro) | — |
| — room-league (`:3816-3836`) | segment | Members & invites · Roster door (D180) · Share the season (public page) · Squads → draft · `<details>` League rules (bylaws, "How scoring & handicaps work →") | View | — |
| — room-album (`:3841-3845`) | segment | round photos grid | — | — |
| **view-record** (⊕ "Golf", `:3196-3217`) | Post tab | eyebrow *"Golf — play one live, post one you just finished, or plan the next"*; three option cards: LIVE *"Play now — score the group"* (real copy `gateLiveRound` `:4631-4641`), *"Post a round — after you play"*, *"Plan a tee time — before"* | Play now | → view-play / view-post / declare sheet |
| **view-post** (`:3361-3474`) | from view-record | eyebrow *"Post a round · your index 12.4"* (updated `:16615-16616`); course+tees search, rating/slope, 18/9 seg, front/back gross, date, photo/scan row, live gross line, `Post round`; right column "How this round scores" calc + "Point bands" table (`:3455-3461`, verbatim with phone per D210/Q-20) | Post round | `← Golf`; "Start over" |
| **view-play** (tee sheet, `:3219-3359`) | Play now; `#liveBanner`; `?claim=` | `#playSetup`: course/tee/rating/slope, 18/9, pars sheet, the foursome (league chips, app search, guest by name), game seg (Just score · Match play · Wolf · Skins · Sunningdale Rules `:3266-3272`), stake ≤ $200, `Tee off →` → `#playLive`: sticky scoreboard, hole card, HOLE/CARD toggle (≥740px), side-game cards, `Finish round & post to season`, `Scrap this round` | Tee off / Finish | `← Golf`; Change setup |
| **view-wizard** (`:3476-3602`) | `#wCreate` (hub), Home doors, hero CTA, `runItBack`; Pro-only gate `:4522-4530` | eyebrow *"Create your league — set the rules once, lock them in"*; step 0 name + "Pro — that's you"; step 1 three presets (Casual / Standard / Cutthroat) + `Use these defaults →` + `Customize` → ~12 dials (buy-in, length, first tee, Teams, How teams fill, How it ends, pot split, counting cap, participation floor); step 2 bylaws review + `Lock the bylaws & form the squads` (`lockBylaws` `:17316` → `lock_league` RPC `:17328`, client fallback `:17361+`) ; desktop aside "Your league so far" | Lock | Cancel / Back / Next; after lock → `openLockShare` (invite link) |
| **view-draft** (`:3171-3194`, `renderFormation` `:17002+`) | Squads row; hero CTA "Draw the squads"; gated on lock (`:4538`) | eyebrow "Form squads · blind draw / Pro assign"; pool + squads; Pro: `Draw squads` / `Start the season →`; member: *"The Pro forms the squads… You'll see them here the moment they're set."* | Draw / Start | `← Clubhouse` |
| **view-event** (`:3165-3168`, `renderEvent` `:14153`) | switcher chip `data-cgev`, `openEvent` `:18606`, invites | Ryder scoreboard (A–B tally to clinch, sessions, duels, rosters) or Major room; *"No event loaded."* if none | — | `← Home` |
| **Event picker** sheet (`openEventPicker` `:17891-17911`) | Start an event | The Ryder (LIVE) · Bracket (SOON) · A Major (LIVE); *"Every event mints a trophy for your display case."* | pick | → `openRyderSetup` `:18614` (name, Team A/B, sessions, cadence, "First tee (a Sunday)", attach to a league, add players) / `openMajorSetup` `:18721` (Name the jug, final day, window, buy-in, pot pays, run it with a league, add golfers) |
| **view-schedule** (`:3862-3898`, `renderCalendar` `:14001+`) | Next tile, chips, hub segment, plan card | eyebrow *"Your golf calendar · yours, your buddies', your leagues'"*; crew's plans; month grid with legend (ON THE TEE SHEET · LEAGUE MATE · SEASON DATE); `Put a round on the tee sheet` (`openDeclareSheet` `:19395`); "On the tee sheet" list; "Week by week" archive (league only, `:14113-14134`) | declare | `← Home` or `← Clubhouse` (`:4547-4555`) |
| **view-people** (`:3849-3860`, `renderCrewPeople` `:15246-15335`) | You › Your buddies; Needs-you chip; crew step "Find your buddies" (via picker) | requests → Find golfers search → Send an invite link (league code) → Buddies list | Add / Accept | `← You` |
| **view-stats** (You, `:3034-3163`) | tab | credential card (`#youCard`) with ⚙; "💬 Tell us how it's going"; Founder's desk (owner only); Your buddies door; last-round-with card; YOUR GOLF: Display case, All time, Recent rounds; YOUR SEASONS: This season, Rivalries · all leagues, Every season (`renderLeagueRecord` `:10920+`) | ⚙ Card & settings | — |
| **Card & settings** sheet (`:15769+`) | ⚙ | Your card (name, city, home course, marker, photo, handle, Findable by, GHIN) · Handicap index · How scoring works → · Your leagues · Notifications · Appearance (Charcoal / Light / Match device) · Membership (PLAN FREE) · Sign out; the D82 guide sheets (`GUIDE` `:15046-15070`) | Save card | close |
| **Covenant** sheet (`covenantGate` `:17702-17740`) | any join with a buy-in | *"Before you join X · THE FINE PRINT, UP FRONT"*: BUY-IN / PRESET / FLOOR / FINISH + ledger line | `Join — I'm in for $N` | `Not now` (code kept) |
| **League welcome** sheet (`openLeagueWelcome` `:19800-19830`) | after any join | "THREE THINGS TO KNOW" + `Share the invite link` | share | close |
| **Join** sheet (`openJoinSheet` `:17913-17945`) | Join a league door | code box | Join | close |
| **Feedback** sheet (`openFeedback` `:17950+`) | You chip | four category chips + textarea | Send | close |

---

## Section 2 · Flows

### F1 · First arrival (door → card → crew → orientation → Home)
- **Goal:** get in, be useful within seconds.
- **Friction:** four screens before Home (email, code, card, crew, orientation = five taps minimum). The card asks seven things (name, handle, home course, city, index, GHIN, ball marker `:2839-2864`) with the handle's 60-day lock explained in a sentence a stranger cannot evaluate (`:2843`). The orientation (D82) is a single explainer slide — the brief says none.
- **Unnecessary complexity:** two ways to enter a code before the app exists (door `#obJoin` `:2825` and the crew step `#obCrewCode` `:2879`); the crew step then offers a *third* door, "Start a league instead" (`:2887`).
- **Terminology:** *"Set up your golfer card."*, *"Ball marker · This is your icon on the board and in the standings"* (`:2861-2862`) — "board" and "standings" are undefined at this point. *"Four places. Two ways to play."* (`:2894`) teaches the database (league vs event) in the first minute, exactly what the brief forbids.
- **Dead ends:** a boot failure lands on the DOOR with *"Boot failed at [memberships]: …"* (`:20068`), an engineering string as UX (IOS-004 §"must not inherit" names this).
- **Redundant:** the orientation's four tiles and the guide sheet "The four places" are the same content twice (`:2897-2901`, `:15047-15052`).
- **Missing feedback:** after "Save my card" the toast *"Card saved. Welcome, {name}."* fires and the orientation appears on top (`:14976-14982`) — the welcome is under the explainer.
- **Delight:** the crew step's question *"Who are you playing with?"* is exactly the brief's onboarding question — keep it, lose the slide.

### F2 · Join a league (code or link)
- **Goal:** land in a friend's league knowing what it costs.
- **Friction:** the covenant only appears when `buyin_cents > 0` (`:17705`); a $0 league gets no preview at all — the joiner still cannot see "what am I joining" (TOP-2 residue). Signed-out, the code is validated before email (`league_by_code` `:17748-17752`) — good — but a decline keeps `cs_code` forever, so every later boot re-shows the covenant (`:20029-20035`).
- **Terminology:** *"PRESET · Standard"*, *"PARTICIPATION FLOOR · 2 rounds / mo"*, *"FINISH · Cup Final · final 4 weeks"* (`:17709-17713`) — wizard nouns handed to a person who did not build the league.
- **Dead ends:** none (the X/backdrop settle the promise, `:17727-17739`).
- **Feedback:** *"Joined X"* toast + the welcome sheet; the welcome ends on *"Share the invite link"* — good.
- **Delight:** *"You can't hurt your standing by playing badly. Only by not playing."* (`:19805`) is the best sentence in the join flow.

### F3 · Start a league (wizard → lock → share)
- **Goal:** get friends into a season with money on it, fast.
- **Friction:** the fast path exists (`Use these defaults →` `:3516`) but the page is still a three-step form with dots; step 0 has one field and a decorative "Pro — that's you" chip (`:3486-3493`); step 2's lock button says *"Lock the bylaws & form the squads"* (`:3583`) even for a solo league (nothing to form).
- **Complexity:** Customize opens ~12 dials (`:3518-3577`); the "Teams" seg defaults to **4 Squads** (`:3541`, `class="on"`) while `STRUCT_MIN` says that needs 8+ golfers and the wizard's own `renderStructFit` dims it (`:13680-13690`); a first-time Pro alone in the league is defaulted to the one structure that cannot start.
- **Terminology:** *"bylaws"*, *"Blind draw"*, *"Cup Final · Points table"*, *"Points King"*, *"Counting cap"*, *"Participation floor · MIN ROUNDS / MONTH · −5 SQD PTS SHORT"* (`:3568`) — every noun the brief says a first-timer must not need.
- **Dead ends:** a non-Pro who reaches `wizard` is bounced with *"Only the Pro edits the bylaws"* (`:4527`) — correct, but "Pro" is undefined for a member.
- **Redundant:** the desktop aside "Your league so far" restates the dials (`:3593-3597`) and step 2 restates them again.
- **Feedback:** `#lockErr` inline + the share screen after lock (`openLockShare`) — good (TOP-1 fixed by D111).
- **Delight:** the counting-cap (i) copy (`:3563`) is genuinely good teaching — behind a tap, where it belongs.

### F4 · Start an event (Ryder / Major)
- **Goal:** "we're playing this weekend" / "two teams".
- **Friction:** the picker is intent-shaped (good) but each setup sheet is a dense form: Ryder asks name, Team A, Team B, sessions, cadence, first tee, league, players (`:18614+`); Major asks name, final day, window, buy-in, pot split, league, golfers (`:18721+`).
- **Terminology:** *"vs-index duels · first to the clinch"*, *"Sessions"*, *"Cadence"* (`:18614`); *"Name the jug"*; *"exhibition"*.
- **Dead ends:** Bracket → toast *"Bracket isn't built yet"* (`:17909`) — a SOON row that is a toast.
- **Feedback:** the event lands as a switcher chip + view-event.

### F5 · Post a round (⊕ → Post)
- **Goal:** the smallest useful action.
- **Friction:** two screens (the "Golf" chooser `:3196-3217`, then the form). The form is a two-column desktop grid; on mobile the "How this round scores" panel and the bands table trail below the button (`:3438-3464`) — the phone moved the gross to a live hero (IOS-020). Course search, rating and slope are asked before the score.
- **Terminology:** *"Rating"*, *"Slope"* (`:3376-3377`); *"Post a round · your index 12.4"*; bands *"Torched it · beat it by 3 or more · 12"*.
- **Dead ends:** none; "Start over — clear this card" exists (`:3434`).
- **Feedback:** live gross line (`:3428`), ceremony → epilogue; `stampPosted('POSTED ✓')` (`:7385`).
- **Delight:** *"How most golfers keep it — 41 out, 43 in."* (`:3409`).

### F6 · Live round (tee sheet)
- **Goal:** score the group, settle, post everyone.
- **Friction:** setup card asks rating/slope/tee/pars before anyone can tee off (`:3227-3240`); five game modes in one seg (`:3266-3272`); the finish fine print is 60 words (`:3353`).
- **Terminology:** *"auto-attested"*, *"Sunningdale Rules"*, *"lone wolf plays for 3"*, *"STROKES OFF LOW MAN"*.
- **Dead ends:** the resume banner (`:8840`) returns you — good.
- **Feedback:** `#finishStatus` aria-live.

### F7 · Plan a tee time (declare)
- **Goal:** "we're playing Saturday".
- **Friction:** Day, tee time, course, note, tag group (`:19395+`) — fine; but the empty tag state says *"No one to tag yet. Add buddies from the You tab, or invite the league."* — two detours from a sheet that should just post.
- **Feedback:** *"Posts to your leagues' boards: tagged golfers are named."* — clear.

### F8 · Home (the lane)
- **Goal:** ME → NOW → what next, in seconds.
- **Friction:** twelve slots in fixed order (`:12439-12460`); for a member the FIRST slot is still `#homeStart` (collapsed to a "Start something else…" link `:11113`) above the lead card — the "make something" row sits above "what today is asking" (IOS-012 moved it to a `+` on the phone; the web was declared untouched). Three tiles (League · Next · Board) sit between the hero and the chips, each a door, each restating the hero (`:11036-11083`).
- **Complexity:** the hero is a 275-line role × stage matrix (`:11198-11474`); the lane has no per-league row, so a golfer in three leagues (6 of 17 in prod) sees one league and a toast promising a switch that Home does not have (`:20066`).
- **Terminology:** *"floor"* (`heroFloorFoot` `:11165-11197`: "Sep floor 1.5/2 · 0.5 more · 3d"), *"seed"*, *"Squads next"*, *"The bylaws lock at the tee."*, *"THE BOARD ↗"*.
- **Dead ends:** the Board tile is `disabled` for the league-less (*"Board · — · LEAGUE ONLY"* `:11061`) — a dead tile on the first screen after signup.
- **Redundant:** the floor is stated three times on one Home: hero foot (count), `#homePulse` fine print (rule, `:12508-12510`), and the lead card when ≤3 days (`:12250-12256`).
- **Missing feedback:** the hero says nothing when standings have not loaded (`:11311` returns empty) — the feed leads with no explanation.
- **Delight:** the league-less ladder (`:11422-11473`: *"Three rounds and your index goes live. Nothing else needed."*, *"Four makes a league."*) is the brief's "empty states are opportunities", already built.

### F9 · Clubhouse
- **Goal:** who's winning, what's on the line, what's next.
- **Friction:** six segments behind one tab (`:3642-3649`); the standings pane alone stacks a live banner, four stat tiles, a press meter, a next card, an "On the line" button, the climb, the cup race, the clash, the story, the table, the scenario line and the individual race (`:3684-3768`) — the SaaS dashboard the brief names. Switching leagues is a horizontal chip strip (`:3622`) the phone replaced with swipe paging (D203).
- **Terminology:** *"Counting rounds 3 / 4 · This month · best 4 count"*, *"Points King · Most Improved · Iron Man"*, *"−5 SQD PTS"*, *"Squad formation"* (`:14635`), *"THE PRO · JERECHO"*.
- **Dead ends:** Schedule segment leaves the room to view-schedule whose back link may say `← Home` (`:4547-4555`) depending on `_schedFrom`.
- **Redundant:** the join code renders in the header AND the room footer (moved nodes `:3771-3774`); "Add golfers" in the header AND the League pane AND the league-less shell.

### F10 · You
- **Goal:** my golf, my record.
- **Friction:** the page is read-only history with one door (buddies) and the ⚙; everything editable is a 30-row sheet (`:15769+`) that also holds the app's manual, notifications, theme and the plan.
- **Terminology:** *"Display case"*, *"Best vs your playing number"*, *"Rivalries · all leagues"*, *"Every season · SEASON I · WK 18 / 36 · 3RD OF 7"*.
- **Dead ends:** "Founder's desk" renders for one account (`:3056`); "💬 Tell us how it's going" is a pilot chip on a shipping product (`:3052`).

### F11 · Buddies
- **Goal:** find the people I play with.
- **Friction:** search lives in three places — header 🔍 (`:2958`, opens the picker), view-people inline (`:15255`), and the crew step's "Find your buddies" (opens the picker). The invite link offered here is a LEAGUE code (`:15275-15276`), so a league-less golfer has no link to send.
- **Feedback:** *"Golf buddies ✓"* / *"Request sent"* toasts (`:15316`).

### F12 · Schedule / archive
- **Goal:** what's next, for me and mine.
- **Friction:** month grid + list + week-by-week archive on one page; the archive prints *"WK n · X LED · BY 3"* rows for squad leagues and, for solo leagues, bare *"WK n"* rows (see WB-06).
- **Terminology:** *"SEASON DATE"* legend dot; *"Nothing recorded yet: the first snapshot writes Sunday night"* (`:14119`) — Sunday is wrong for any league whose first tee is not a Sunday (D213 says weeks close on the league's own day; `weekCloseDate` `:10784`).


---

## Section 2b · THE DIVERGENCE TABLE — phone vs web at tip 3bba87e

Legend: **P** = phone has it (`apps/ios`), **W** = web has it (`index.html`). Ruling column names the D/IOS entry that made the split. All "SAW" unless marked.

| # | Surface | Phone (SAW) | Web (SAW) | Ruling / status |
|---|---|---|---|---|
| 1 | **Home hero · tiebreak sentence** | `HomeHeroCopy.level()` prints *"Level with Galen · 14 – 14."* and the rule is said ONCE, in the endgame foot (`LeagueCopy.endgame`: *"Level on points? Months won breaks it."*) — `HomeHeroCopy.swift:84-88`, `LeagueCopy.swift:402` | `heroMyRung` prints *"Level with X. Months won breaks the tie."* (`:11520`); the web hero has NO endgame foot (branch 3 passes only `me.gapLine, heroFloorFoot()` `:11308-11310`); the web's own producer says it in different words — *"Level on points? Months won breaks it."* (`endgameLine` `:6328, :6337`) — but only on the Clubhouse climb note (`:4906`). Two wordings of one law across the web; D201's fixed-phrase rule broken. | D130 build note (`decision-log.md:4334`): "the web hero still repeats it … a web task". D126 (three homes for the endgame): the web has ONE (climb note); the Season tile still runs the nearest-deadline sort (`:10784-10799`), so the Final line loses to "Week closes" on every day but the last. |
| 2 | **`upcomingFromSchedule` (D219 axes)** | `plans` = `(mine != false OR tagged_me) AND my_rsvp != 'out'` (`ScheduleModels.swift:388-389`); tagged rounds become the "Next round" chip and the card's eyebrow WITH YOU | `if(r.mine === false) return;` and never reads `tagged_me`/`my_rsvp` (`:10985-10986`) — drops rounds booked WITH you, keeps your own declined booking. The Next TILE (`:11048-11052`) has NO mine filter at all: `src` is `watchAll` (buddies' + league mates' rounds), so the tile can name a BUDDY's round as "Next" while the chip below it names a different one (INFER — same data, two filters). | D219 (`decision-log.md:5670`): "a web task under this entry". |
| 3 | **"posted" credits noun** | `HomeLeadCopy.floorLine`: *"You're 0.5 short of the floor. One round covers it."* (`HomeLead.swift:232-235`) — never says how many were "posted" | `#nextTxt`: *"Post 1.5 more rounds this month — best 3 count, you've posted 2.5."* (`:10869-10877`, `fmtN` `:10763` prints tenths). `credits` are counting credits (a nine = 0.5), so "you've posted 2.5" prints a fraction of a round as a count of rounds. | D201 (one fact, one place) · brand canon (never engine nouns). Memory flags it; confirmed. |
| 4 | **D121 second-league row** | `HomeLeagueRows` under the hero: one row per OTHER league, tap re-renders Home around it (`HomeView.swift:79-82, 1015+`) | Absent. Other leagues exist only as Clubhouse chips (`renderClubGroups` `:11011-11030`); boot still toasts *"Switch groups anytime from Home"* (`:20066`) — false on the web. 11 of 17 active golfers hold 2+ leagues (prod). | D121: "The web row is still owed" (`decision-log.md:4243`). |
| 5 | **Season-archive "Week by week" for SOLO leagues** | (no equivalent strip on the phone Schedule that I found — INFER) | `renderCalendar` reads `sn.standings.squads` only (`:14125`); `snapshot_week` writes `squads` from `v_squad_standings` (empty for solo) and `individuals` separately (`the_moments.sql:786-795`). For a solo league every row renders as bare *"WK n"* with no leader, no gap, no points. Everywhere else the web already branches `solo ? individuals : squads` (`:4660, :5093, :11498`). 3 of 6 in-season leagues are solo (prod). | Unruled; memory flags it. |
| 6 | **Week number — three (four) formulas** | `LeagueDates.totalWeeks = max(1, ceil((e−s)/7))`, `currentWeek = floor(since/7)+1` clamped (`LeagueDates.swift:31-41`) | (a) `totalWeeks()`/`currentWeek()` identical to the phone (`:13637-13644`); (b) `window.seasonWeeks = max(2, round((e−s+1d)/7d))` (`:16819`); (c) the hero's `wkNow = floor((now−s)/7)+1` clamped to (b), not to (a) (`:11304-11305`). Server: `snapshot_week` `total_wk = ceil((e−s+1)/7)`, `wk = floor((today−s)/7)` — COMPLETED weeks, no +1 (`the_moments.sql:781-782`); the file's own header records that `open_week_clash` uses `floor(…)+1` and "on the same day they disagree by one" (`:36-40`). | One fact, four producers. The archive strip prints `snapshot_week`'s `wk` as "WK n" beside a hero that prints (c). |
| 7 | **Cross-league feed head door** | *"YOUR BUDDIES ↗"* → `HomeRoute.people` (`HomeView.swift:108-111`) | *"Around your buddies · THE BOARD ↗"* → one league's board dialog (`:3024`, gated `:12440-12444`) | D218 (`:5660`) built phone-only. |
| 8 | **Hero as a door** | the whole hero is a `NavigationLink` to STANDINGS with *See the table →* | `heroCard` is a `div` with CTA buttons only (`:11159-11164`); no route to the table from the hero | D218. |
| 9 | **System rows on Home (D217 fold)** | `FeedNotesRow`: `kind=system` rows fold to one line per league per bucket with a board door (`HomeView.swift:724-770`) | every `homePosts` row renders as its own `postRow` card (`:12141-12145`, `:11800-11822`) | D217 (`:5650`) built phone-only. |
| 10 | **Booking rows know their round (D219 doors)** | select carries `round_id` + `scheduled_round_id`; rows open receipt / schedule sheet; booking hidden when already a calendar card | `postRow` opens only on `live_round_id` (`:11818-11820`); no `round_id`/`scheduled_round_id` read | D219 tradeoffs: "The web's booking row keeps rendering the server string". |
| 11 | **Lead card · clash yields (D216) and first-week sentence (D207)** | `HomeLead.choose` yields when both sides nil and >1 day left; first week of a two-person season shows *"It's the two of you — every week is the clash."* | rung 1 fires whenever `home_clash` returns a row (`:12214-12216`); no yield, no first-week sentence | D216 (`:5640`) built phone-only. |
| 12 | **Hero · leader by name with totals at n=2 (D130), the owe line (D129), the endgame foot (D126)** | *"10 back of Galen · 9 – 19"*, *"You still owe $50 · Venmo @casey · by Sat Sep 5"* (`OweAction` `HomeView.swift:1003`), endgame foot | web names the neighbour (`:11510-11523`) but never the totals; no owe line on Home (only pot pane `:7941-7956`); no endgame foot | D126/D129/D130 build notes. |
| 13 | **Home doors placement** | "make something" doors live in the header `+` menu (`HomeView.swift:47,183-184`); Home opens on the lead card / hero | `#homeStart` is the FIRST slot (`:3017`, `:11086-11145`): three doors league-less, a "Start something else…" link for members | IOS-012: "reverses D94's placement for the phone only. Web Home is untouched." |
| 14 | **Home tiles (League · Next · Board)** | none (no `HomeTiles` in `apps/ios`) | `renderHomeTiles` `:11036-11083` | D94 kept on web; phone never ported them. |
| 15 | **Upcoming rounds cards on Home** | `UpcomingRoundsSection` at the foot (`HomeView.swift:133`) | `renderHomeRounds` is a no-op — no `#homeRounds` element exists (`:12356-12372`, grep for `id="homeRounds"` returns nothing); only the Next tile + chip remain | D94 retired the list on web; the phone rebuilt it. |
| 16 | **Clubhouse switching** | swipe paging with dots (`ClubhouseView.swift:118-134`, D203) | horizontal chip strip (`:3622`, `:11011-11030`); the guide sheet deliberately diverges (`:15040-15045`, Y-05) | D203 (`:5511`). |
| 17 | **Stage word in the Clubhouse header** | one producer (`LeagueCopy` stage) | `#hhPhase` hand-derives *"Squad formation"* (`:14635`) while `STAGE_LABEL.drawing = 'Squads drawing'` (`:13893+`) — the exact bypass D201's "third pattern" records | D120/D201. |
| 18 | **Onboarding · crew step** | none: `RootView` goes signedOut → cardGate → (orientation) → tabs (`RootView.swift:25-47`); the league-less doors ride under the orientation instead (`OrientationScreen.swift:9-11,137-138`) | D151 crew step (`:2868-2889`, `:15009-15043`) | D151 built web-only; "the web puts the crew step right after the card… the phone has no crew step" (`OrientationScreen.swift:9-11`). |
| 19 | **Golfer card fields** | name, @handle, starter index, GHIN; *"City and home course live on your card — add them any time from the You tab."* (`CardGateView.swift:94-106,141,171-175`); no marker pick | name, handle, home course, city, index, GHIN, ball marker (`:2839-2864`) | D151 §2 ruled city + home course INTO the card; the phone still defers them. |
| 20 | **Door** | email code · password door (reviewer) · Sign in with Apple (flag, IOS-023) · terms (`DoorView.swift:93-193`); no league-code entry on the door | email code · *"I have a league code"* (`:2825`) · terms; no Apple; fiction wings (`:4284-4300`) | IOS-004 lists "the demo diorama" as a thing the phone must not inherit; the wings are the last of it. |
| 21 | **⊕ Post** | full-screen cover "Golf" with the same three rows (`PostCoverView.swift:90-102`); composer is a scorecard with the gross as a live hero (IOS-020) | `view-record` page → `view-post` two-column form with the calc panel trailing (`:3361-3474`) | IOS-011/IOS-020. |
| 22 | **Boot failure** | `.failed` → BootFailedView *"Boot stalled"* + Try again / Sign out; D220: a failed REFRESH keeps the screen | `authStatus('Boot failed at [step]…')` on the door (`:20068`); the 8 s watchdog string (`:19995-19999`) | IOS-004 "the 8s boot watchdog string as UX" — still web UX. |
| 23 | **Looks / theme** | IOS-025 looks + "Dress the room" | Charcoal · Light · Match device (`:15769+` Appearance) | phone-only. |
| 24 | **Pricing surfaces** | `MembershipCard` in settings, `PotPassCard` on the pot pane (flag-gated) (`CardAndSettingsScreen.swift:522`, `PotPane.swift:53`) | "Membership · PLAN FREE" row; Pro Shop teaser deleted (D183 `:3828`) | D183 parked; IOS-021 says checkout stays on the web — but the web has no checkout either. |
| 25 | **Push / live** | APNs + PushRouter + badge + contextual ask (D104), Live Activities (D155), Nearby (D168) | web push via `pushManager` (`:16361-16385`) + a Capacitor-shell APNs branch (`:16314-16322`) for a wrapper CLAUDE.md:303 says D99 retired | phone-only features; dead shell code on web. |
| 26 | **Desk-only surfaces** | wizard has the dials too (`WizardSteps.swift` carries Customize, 1 hit) | desktop sidebar, two-column grids (`@media(min-width:960px)` `:126,227,364,436,476,511`), wizard aside, draft grid, `?debug` error bar (`:3916-3925`), keyboard a11y stamping (`:4593-4614`) | IOS-018 ported everything; the desk is the only thing the web alone offers. |
| 27 | **League-less Clubhouse** | LeaguelessDoors (Join · Start a league · Start an event) + Add golfers (`ClubhouseView.swift:137-150`) | Start a league · I have a league code · Add golfers · **Sign out** (`:3608-3620`) — Join is second, Sign out is on a tab | D151 §4 reordered Home's doors (Join first, `:11114-11119`) but not the Clubhouse's. |
| 28 | **Orientation** | same copy (`OrientationScreen.swift:46-58`) + doors | same copy (`:2891-2913`) | D82 parity — both still an explainer slide. |
| 29 | **Guide sheets, bands, welcome, ledger line** | `GuideCopy.sheets`, `CSBands`, `LeagueWelcomeSheet`, `CS_LEDGER` twin | `GUIDE` `:15046-15070` (verbatim by design), bands `:3455-3461` (D210), `openLeagueWelcome` `:19800` (D205), `CS_LEDGER` `:4418` | parity held where a shared producer or fixture exists (`tests/fixtures/endgame.json` for `endgameLine`/`LeagueCopy.endgame`). |

---

## Section 3 · Findings (prefix WB-)

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Damages" names the brief's five questions: **Q1** what is happening · **Q2** why it matters to me · **Q3** what I can do now · **Q4** who I'm competing with · **Q5** what happens next.

**WB-01 · The web is still called the behavioural reference while the phone has the newer behaviour on Home — P0.** CLAUDE.md:302 and IOS-018 (`DECISIONS.md:179`) say the web is the reference; D121, D126, D129, D130, D216, D217, D218, D219 are all built phone-first with "the web is owed" notes (`decision-log.md:4243, 4334, 5640-5677`). Two clients now answer Q1–Q5 differently for the same golfer on the same day. Damages all five. **Rec:** rule it (Section 6): flip the reference to the phone + Kit producers; treat every "web owed" note as a tracked parity debt or an explicit non-goal.

**WB-02 · No second-league row on the web, and boot promises one — P1.** `renderHomeHero` renders the loaded league only; boot toasts *"Switch groups anytime from Home"* (`:20066`) but Home has no switcher (chips are on the Clubhouse `:3622`). 11 of 17 active golfers hold 2+ leagues (prod). Damages Q1, Q4. **Rec:** port `HomeLeagueRows` (data already in `native_home()`, D121 says no migration) or delete the toast.

**WB-03 · `upcomingFromSchedule` wrong on both D219 axes; the Next tile uses a third filter — P1.** `:10985-10986` drops `mine===false` (so a round booked WITH you never becomes "Next round") and ignores `my_rsvp` (a declined own booking stays "Next"). The Next tile (`:11048-11052`) filters nothing but the date over `watchAll`, so it can promote a buddy's round as yours (INFER). Damages Q3, Q5. **Rec:** one `plans()` producer mirroring `ScheduleModels.swift:388-389`, used by the tile, the chip and `renderUpNext`.

**WB-04 · The tiebreak law is said in two wordings on the web, and on the hero where the phone struck it — P2.** *"Months won breaks the tie."* (`:11520`) vs *"Level on points? Months won breaks it."* (`:6328, :6337`). Damages Q5. **Rec:** hero says *"Level with X · 14 – 14."*; add the endgame foot from `endgameLine()` (the producer already exists, `:6318`, fixture-tested) so the rule lives once.

**WB-05 · "you've posted 2.5" — credits printed as rounds — P2.** `:10877` with `fmtN` `:10763`. A nine is half a credit (`:3409` says so on the post form). Damages Q2. **Rec:** adopt the phone's floor sentence (*"You're 0.5 short of the floor. One round covers it."*) or say "counting"; never "posted" for credits.

**WB-06 · Week-by-week archive prints empty "WK n" rows for solo leagues — P2 (P1 for the 3 live solo leagues).** `:14125` reads `standings.squads` only. Damages Q1, Q4. **Rec:** `solo ? individuals : squads` with `member_id`, as `:4660`, `:5093`, `:11498` already do; or drop the strip (the phone has no equivalent).

**WB-07 · Four week-number formulas — P2.** `:13637-13644` (matches `LeagueDates.swift`), `:16819` (`max(2, round(...))`), `:11304-11305` (hero clamps to `:16819`), `snapshot_week` (`floor`, no +1, `ceil(+1)` total). The hero can say "week 3 of 13" while the tile says "W3 / 12" and the archive's last row says "WK 2". Damages Q1, Q5. **Rec:** one producer (`totalWeeks`/`currentWeek`) for every client label; the server prints no week number (it already avoids it, `the_moments.sql:36-40`).

**WB-08 · "THE BOARD ↗" hangs on a cross-league head and the hero is not a door — P2.** `:3024`, `:11159-11164`. D218 ruled and built the fix on the phone. Damages Q3. **Rec:** head door → buddies; hero → standings.

**WB-09 · System posts render as cards, one each, on Home — P2.** `:12141-12145` + `:11800-11822`; a two-league member reads every clash/booking sentence twice (D217's finding). Damages Q1 (noise drowns the human rounds). **Rec:** port the fold, or hide `kind=system` from the Home lane on web and keep them on the board.

**WB-10 · Booking and moment rows have no door — P2.** `postRow` only opens on `live_round_id` (`:11818`). §16 "every line taps to its receipt". Damages Q3. **Rec:** read `round_id`/`scheduled_round_id` (already in the payload since D219's migration).

**WB-11 · The clash card never yields — P2.** `:12214-12216`. In a two-person league it says "Nothing posted / Nothing posted" above your own standing every idle week (D216's evidence). Damages Q2. **Rec:** port `HomeClash.yields` + the first-week sentence.

**WB-12 · Home opens on "make something" for members — P2.** `#homeStart` is slot one (`:3017`); IOS-012 moved the doors to a `+` on the phone and explicitly left the web. Damages Q1 (the first pixel is not what's happening). **Rec:** move the doors under the `+`/header on web too; league-less keeps the row (it IS the next move).

**WB-13 · Three tiles restate the hero and one is dead — P2.** `:11036-11083`; Board tile `disabled` with *"LEAGUE ONLY"* for the league-less (`:11061`). Damages Q3 (a door that says it is not a door). **Rec:** retire the tiles (the phone did) and let the Next chip and the hero be the doors; never render a disabled tile on the first screen after signup.

**WB-14 · The floor is stated three times on one Home — P3.** hero foot (`:11165-11197`), pulse fine print (`:12508-12510`), lead card (`:12250-12256`). Damages Q2 (repetition reads as nagging). **Rec:** one place (the lead card when it matters, the hero foot otherwise).

**WB-15 · The Clubhouse header hand-derives "Squad formation" — P3.** `:14635` vs `STAGE_LABEL.drawing='Squads drawing'`; the phone reads one producer. Damages Q1. **Rec:** `STAGE_LABEL[leagueStage()]`.

**WB-16 · The web's Season tile buries the endgame under "Week closes" — P2.** nearest-deadline sort `:10784-10799`; the Final line (115 d out) never wins. D126 ruled a pinned countdown and built it on the phone hero. Damages Q5 (the one thing a season is FOR is invisible until the last week). **Rec:** pin the endgame line; let week/month closes take the slot only within a day.

**WB-17 · Onboarding is longer on the web (crew step) and shallower on the phone (no crew step) — P1.** Web: door → card (7 fields) → crew → orientation → Home. Phone: door → card (4 fields, defers city/home course against D151 §2) → orientation with doors → Home. Neither asks "what golf do you play" (the brief's third question). Damages Q3 on first open. **Rec:** one onboarding: ask handicap + who you play with (the crew step's question) inside the card flow; delete the explainer slide on both; the phone takes the crew step or the web drops it — not both.

**WB-18 · The door still runs a fiction diorama and the "league code" door exists only signed-out — P2.** `:4284-4300` (MARCUS +9 PTS), `:2825`. IOS-004 forbids the phone inheriting the diorama; D151 recorded that the code door vanishes the moment a golfer has an account (the crew step patched that). Damages Q4 (fictional competitors on the first screen). **Rec:** kill the wings; make code entry a permanent door (Home doors + Clubhouse already have it — fine; the DOOR need not).

**WB-19 · Sidebar ≠ tab bar — P3.** Sidebar order Home · Post a round · Clubhouse · You (`:2931-2946`); tab bar Home · Clubhouse · Post · You (`:3908-3913`); the sidebar label promises a form and lands on the "Golf" chooser (`:3198`). Damages Q3 on desktop. **Rec:** same four, same order, same word.

**WB-20 · "Sign out" lives on the league-less Clubhouse — P3.** `:3618`. A tab that says Clubhouse offers to leave the app. **Rec:** settings only.

**WB-21 · The Clubhouse is the dashboard the brief forbids — P1.** Standings pane: 4 stat tiles + press meter + next card + On the line + climb + cup race + clash + story + table + scenario + individual race + roomFooter (`:3684-3777`), behind a six-segment control (`:3642-3649`) IOS-011 explicitly rejected for the phone. Damages Q1, Q4 (who's winning is item nine). **Rec:** (the Clubhouse reader's area) — from the web side: the standings table and the endgame sentence lead; everything else folds.

**WB-22 · Wizard defaults to 4 Squads for a league of one — P2.** `:3541` `class="on"` on `squads4`; `STRUCT_MIN.squads4 = 8` (`:13675`); `renderStructFit` dims it (`:13680-13690`) but the default stays. Damages Q3 (the Pro's first choice is the one that cannot start). **Rec:** default to solo (D205: solo tees off at two) and offer squads when the roster can fill them.

**WB-23 · The join covenant is skipped for $0 leagues — P2.** `covenantGate` returns true when `buyin_cents` is 0 (`:17705`); the joiner sees no preview at all. TOP-2's "nobody can tell what they are joining" survives for free leagues (most first leagues). Damages Q1, Q4. **Rec:** always show name · Pro · roster count · first tee · format; money is one row of it, not the gate.

**WB-24 · Buddy search in three places; the only invite link is a league code — P2.** `:2958`, `:15255`, crew step; `:15275-15276`. A league-less golfer cannot invite a friend. Damages Q4 (the brief's friend-connection metric). **Rec:** a buddy invite link (needs a decision; the code comment says so `:15264-15266`); one search entry.

**WB-25 · Post asks course/rating/slope before the score; the calc panel trails — P2.** `:3366-3377`, `:3438-3464`. The smallest useful action is not the first field. Damages Q3. **Rec:** adopt IOS-020's shape (gross first, live) on web or accept the web as the desk form.

**WB-26 · Event creation is forms, not intent — P2.** Ryder `:18614+` (8 fields incl. "Cadence", "First tee (a Sunday)"), Major `:18721+` (7 fields). The picker (`:17891`) is intent-shaped; the sheets are not. Damages Q3. **Rec:** Who? When? What for? then Customize.

**WB-27 · "Nothing recorded yet: the first snapshot writes Sunday night" — P3.** `:14119`; weeks close on the league's own day (D213, `weekCloseDate` `:10784`). Damages Q5. **Rec:** derive the weekday.

**WB-28 · `.league-only` comment is stale — P3 (docs).** `renderHomeHub` says the class "has no CSS rule" (`:12440-12444`) but `body.noleague .league-only{display:none}` exists (`:1986`). Not user-facing; misleads the next editor. **Rec:** fix the comment.

**WB-29 · Dead Capacitor-shell branch — P3 (code health).** `:16314-16322`, `:20022, :20116`: the wrapper CLAUDE.md:303 retired. **Rec:** delete with the ruling.

**WB-30 · Feedback chip and Founder's desk on the You page of a shipping product — P3.** `:3052`, `:3056-3064`. **Rec:** feedback into settings; desk behind the founder gate only (it is, but still occupies markup and a section head).

**WB-31 · The orientation is an explainer slide on both clients — P2.** `:2891-2913`, `OrientationScreen.swift:46-58`; "Four places. Two ways to play." teaches league vs event before the golfer has posted a round. Damages Q3 (delays the first action). **Rec:** delete; the doors teach themselves (D82's own claim).

**WB-32 · Terminology density on first screens — P1 (cross-cutting).** Exact strings a first-timer meets before posting a round: *"bylaws"* (`:3479, :3583`), *"Blind draw"* (`:3551`), *"Points King"* (`:3560, :3760`), *"Counting cap"* (`:3562`), *"Participation floor · MIN ROUNDS / MONTH · −5 SQD PTS SHORT"* (`:3568`), *"floor 1.5/2"* (`:11195`), *"seed"* (`:11293`), *"Cup Final · final 4 wks"* (`:3697`), *"Iron Man"* (`:3762`), *"PRESET · Standard"* (`:17710`), *"Squads next"* (`:11423`). Damages Q2, Q5. **Rec:** the redesign's vocabulary pass must be a shared table (Kit + web), not per-surface strings — D201's own diagnosis (`decision-log.md:5449`).

---

## Section 4 · What already serves the brief (keep list)

1. **The crew step's question** — *"Who are you playing with?"* with the code box first, buddies second, league last (`:2874-2889`, D151). This IS the brief's onboarding question; it exists only on the web.
2. **Join leads the doors** — `Join a league · Start a league · Start an event` (`:11114-11119`, D151 §4), with *"Post a round — it counts on your card. Leagues score it when you join one."* (`:11121`): "play before league" in one line.
3. **The league-less ladder hero** — rung 7/6/5 (`:11427-11457`): *"Three rounds and your index goes live. Nothing else needed."*, *"Established. Nobody's seen it — you haven't added a buddy yet."*, *"Four makes a league. You have 3."* Empty states as opportunities, one next-unmet fact, never a chore list — the comment at `:11421` says exactly that.
4. **The lead card ladder** (`:12212-12278`, D176): fixed order, one card, NO card as the resting state — "what today is asking" above "where you stand". The phone kept it and refined it (D216); the shape is right.
5. **The occasion engine** (`:11534-11566`): the calendar's own drama (azaleas, the oldest one, the big team match) with no data required — anticipation without manufactured engagement.
6. **The fast path in the wizard** — one preset + `Use these defaults →` + `Customize` (`:3499-3517`): the brief's progressive disclosure already built; the (i) copy for the counting cap (`:3563`) is the best teaching in the product.
7. **The event picker is intent-shaped** (`:17891-17911`) and every event "mints a trophy for your display case".
8. **The covenant before the money** (`:17702-17740`) — the stake is never a surprise, and the sheet settles on every dismissal.
9. **The welcome's first sentence** — *"You can't hurt your standing by playing badly. Only by not playing."* (`:19805`) and the ledger line verbatim from one constant (`CS_LEDGER` `:4418`, painted into every `[data-ledger]` `:4419-4423`).
10. **Shared producers that held parity** — `endgameLine()` ↔ `LeagueCopy.endgame` on one fixture (`tests/fixtures/endgame.json`, D126 note), `GUIDE` ↔ `GuideCopy.sheets` (Y-05), the bands table (D210/Q-20), `csLeadLabel` ↔ `RivalryCopy.leadLabel` (`:15339`). Where a producer is shared, the two clients say the same thing; where it is bypassed they drift (D201 `:5449`). This is the mechanism a two-client redesign must run on.
11. **The resume banner and the guest pencil** — an in-progress round is the first thing on Home (`:12445`); a guest scores without an account and claims later (`:9010+`).
12. **`switchView` as the one choke point** (`:4512-4590`) — role gates (Pro-only wizard), stage gates, alias routes and per-view renders in one function; the redesign can re-map the IA here without touching renderers.
13. **Accessibility discipline** — the `.tap` stamping observer (`:4593-4614`), `aria-live` on statuses, `prefers-reduced-motion` guards.
14. **`localDate` and the calendar-day rule** (`:13620`) — the UTC-midnight landmine is handled once; `LeagueDates.swift` cites the same lines.

---

## Section 5 · What I could not determine from reading

- **Rendered behaviour.** I did not open the page; every "first thing shown" is the DOM order plus the render functions, not a screenshot. The fold on a phone-width viewport (how much of the twelve-slot lane is above it) is unmeasured.
- **Which client posts the rounds.** `rounds.source` is `quick|live`; nothing records the client. The web/phone usage split above is inferred from event NAMES, and `qaEvent` is suppressed while `state.demo` is true (`:6900`), so early-boot web events are under-counted (D185 records the same trap for growth events).
- **Whether the Next tile actually mis-promotes a buddy's round** (WB-03's INFER): `watchAll` rows' shape (`mine`, `tagged_me`) is set in module code I did not trace; the tile's filter is the fact.
- **Whether the phone Schedule has any equivalent of the "Week by week" archive** (divergence #5's phone column).
- **The prod state of D221's four migrations** — the memory says unapplied; not relevant to this area, not verified here.
- **The Capacitor shell** — `window.Capacitor` branches remain (`:16314-16322`); whether any installed wrapper still runs is unknowable from the repo.
- **Who the 8 web golfers of the last 30 days are** — I did not join to profiles (PII rule); the memory says every trace since Sep 2 is the owner or the reviewer, but `home_hero_state` from 6 distinct golfers in the last 14 days says otherwise for the web.

---

## Section 6 · The ruling the memory flags: reference, secondary, or frozen?

### What the evidence says
1. **The reference has already flipped in fact.** Since 2026-09-02 every Home ruling was built phone-first with the web "owed" (D121, D126, D129, D130, D216, D217, D218, D219 — eight entries, one wave). The phone reads copy from Kit producers with tests (`HomeHeroCopy`, `HomeLeadCopy`, `LeagueCopy`) while the web hand-assembles strings beside producers it has (`:11520` vs `:6328`; `:14635` vs `STAGE_LABEL`). D201's diagnosis — "where a producer exists and is bypassed, the copy is wrong; not one exception" — is a statement about the web's architecture (`decision-log.md:5449`).
2. **The web is still where the real golfers are, today.** 8 golfers fired web-only event names in 30 days (6 in 14) against 5 phone-only (the memory says those are the owner and the reviewer); 207 rounds posted by 22 golfers in 60 days, client unknown. Build 669 is with a Friends group nobody has signed into (memory, 2026-09-04). Freezing the web at tip would freeze the surface most players use, with WB-02/03/05/06 live on it.
3. **The web is the only desk.** Sidebar and two-column layouts (`:126, :227, :364, :436, :476, :511`), the wizard aside, the draft grid, the founder desk, the public season page, the `?debug` bar — IOS-007's "authoring stays on the desk" was never reversed for the desk, only extended to the phone (IOS-018).
4. **Cost structure.** index.html is one 20,567-line file with a classic/module boundary that has produced real bugs (F-007 `:6904-6908`; CLAUDE.md:107). Every IA change is a hand-edit in a DOM whose renderers are addressed by id (`#homeStart`, `#homeHero`, `#roomSeg`…). The phone's screens are typed routes (`HomeRoute`, `ClubRoute`, `YouRoute`, `MainTabView.swift:83-88`) over Kit models. Building the brief twice means building it once in Swift and once in this file.

### Recommendation (evidence-based)
**Make the web SECONDARY now — a companion/desk surface — and stop calling it the behavioural reference; freeze its OPERATING surfaces only once the phone is measurably where the golfers are.** Concretely:

- **Flip the reference (a one-line ruling, D-numbered).** The phone + `CupSeasonKit` producers + shared fixtures are the behavioural reference for operating surfaces (Home, Post, Live, Join, the Clubhouse read). CLAUDE.md:302 and IOS-018's last sentence ("what the web should be… a later decision") get their answer.
- **The web keeps three jobs:** (a) **the desk** — the wizard's full dials and lock, Pro assign, the draft grid, ledger/receipts, the public season page, the founder desk (IOS-007's authoring list, unchanged); (b) **the door for the account-less** — the guest pencil, `?join=`/`?claim=` links, the covenant (links land in a browser first); (c) **the interim operating surface** for the 8-ish golfers on it, held at *contract parity* (same RPC payloads, same shared copy tables) but NOT at *IA parity*.
- **Parity contract, not parity IA.** Every "web task / web owed" note in the log becomes one of two things: a shared-producer port (cheap: `endgameLine`, `plans()`, `STAGE_LABEL`, floor sentence — WB-03/04/05/07/15, roughly a day) or an explicit non-goal (WB-09/10/11/13 — the fold, the doors, the yield; the phone's Home shape is not owed to the web). WB-02 (the second-league row) and WB-06 (solo archive) are worth porting because they are wrong facts, not missing shape.
- **Freeze trigger, measured not declared:** when golfers firing phone-only names exceed those firing web-only names for two consecutive weeks (both queries above are one line), the web's operating surfaces freeze: no new Home/Post/Live IA on web; bugs that state a false fact still get fixed; desk surfaces keep evolving.
- **What a phone redesign costs the web under each option:**
  - *Reference (status quo):* every brief-level change (new tab model, intent-first creation, living feed) is built twice; the second build lands in a file with no typed routes, and the D215–D220 wave already shows the actual outcome — eight phone builds, zero web builds, and a divergence table of 29 rows in two days. Estimated cost: the whole redesign again, minus nothing.
  - *Secondary (recommended):* the redesign costs the web only its shared producers (copy tables, RPC shapes like `native_home()` v2, `plans()`), plus the desk screens that change (the wizard if creation becomes intent-first — that IS a desk screen). The operating web keeps today's IA; the ~8 golfers on it lose nothing they have. Estimated cost: producers + the wizard, a fraction of the phone build.
  - *Frozen now:* zero build cost, but WB-02/03/05/06 stay live for the majority of today's real users through the App Store gap, and the door/guest/desk jobs still need the file maintained — a freeze that is not a freeze.
- **One condition on "secondary":** the web must stop asserting things the phone no longer asserts. The four false-fact findings (WB-02 toast, WB-03 next round, WB-05 credits, WB-06 archive) are the price of keeping it up at all; the rest are shape and can wait for the freeze.
