# Reader · empty states and notifications — Cup Season at tip 3bba87e (2026-09-04)

Finding prefix **EN-**. Read-only. Every line number is as of tip `3bba87e`. "SAW" = read in code or returned by a read-only prod query; "INFER" = a conclusion from what was read, not observed on a device. No device was run; no screenshot was taken.

**Prod reality (SAW, `supabase db query --linked`, 2026-09-04):**

| fact | value |
|---|---|
| `device_tokens` | **1 row, platform `ios-sandbox`** (a Debug build). **Zero `ios` (TestFlight/App Store) tokens.** |
| `push_subscriptions` (web) | 1 |
| `profiles` | 39 (all with real emails); **14 have no league** |
| `profiles.notify_chat / notify_rounds` | all 39 = true/true — nobody has ever touched a toggle |
| `push_nudges` by kind | nudge 11 · request 6 · rsvp 1 · **invite 0** |
| `invites` | **0 rows ever** |
| `posts` by kind | round 224 · moment 85 · system 54 · chat 4 |
| `leagues` | 13; `notify_system=false` on 0 |
| `email_queue` (season recap) | 0 queued, 0 sent — no season has ever completed |
| `cancellation_notices` | 0 |
| `client_events` | `push_prompt_shown` **1** (ever) · `push_prompt_accepted` 0 · `push_prompt_declined` 0 · `push_opened` 7 |
| league membership | 14 members in 1 league · 3 in 2 · 6 in 3 · 2 in 4 |
| round posts per round | a round by a 2-league golfer produces **2 `posts` rows** (one per league) — `round_id 17190ed2…`, `3a6ecb56…` each have 2 posts across 2 leagues |
| webhooks wired | `push_posts` (posts INSERT), `push_nudges_to_push`, `push-friends` (friendships INSERT/UPDATE), `season_email` (email_queue INSERT), `seasons_email_on_complete` |

The headline: **for the shipping product, every notification in this report is theoretical.** No TestFlight phone has registered a device token, the contextual ask has been shown once in the history of the product, and the badge/lock-screen-action machinery has never had a production recipient. Whether the `APNS_*` secrets are even set could not be read (§5).

---

## Section 1 · The map

Columns: screen/state · how reached · what it shows first (exact copy) · primary action / door · exits. "Door: none" means the copy names a next move but nothing on that surface performs it.

### 1a · Phone — boot, door, onboarding

| # | screen · state | how reached | shows first (exact copy) | primary action / door | exits |
|---|---|---|---|---|---|
| B1 | `BootingView` restoring | every cold launch | spinner + eyebrow "Restoring your session" (RootView.swift:27, :127-136) | none | → door / card gate / orientation / tabs / failed |
| B2 | `BootFailedView` | boot RPC failed with nothing on screen (SessionStore.swift:104-119) | eyebrow **"Boot stalled"** (RootView.swift:144) · message = `AuthRules.human(error, fallback: "Could not load your card.")` (SessionStore.swift:118) e.g. "Connection hiccup — check your signal and try again." (AuthRules.swift:69) · `[Try again]` (:146) · `Sign out` (:147) | Try again → `store.reload()` | Try again / Sign out |
| B3 | `MustUpdateView` | `me.minIOSBuild > build` (SessionStore.swift:90-91) | "Update Cup Season" · "This build is behind the season. Grab the newest one from TestFlight or the App Store, then come back." · "needs build N" (RootView.swift:158-161) | **none** — no link, no button | none (dead end by design) |
| B4 | Door · code stage, 20 s idle | code box open and empty for 20 s (DoorView.swift:331-341) | "No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends." (:339) | Resend (30 s cooldown) | type code / back |
| B5 | Door · sending/checking | tap Send / Verify | "Sending your code…" (:237) · "Sent to x@y. Type the 6 digits from the newest email." (:242) · "Checking the code…" (:251) · "Signed in, loading…" (:257) | — | → boot |
| B6 | `OrientationScreen` (once) | first `.ready` with 0 leagues, 0 events, 0 rounds and no pending invite (OrientationScreen.swift:77-85) | "Four places.\nTwo ways to play." · "Thirty seconds, then you're in." (:47-48) · four place rows · "The long game / A league / Months. Every round counts toward a table." · "The short game / An event / A weekend or a few weeks. Its own little trophy." (:55-56) · `LeaguelessDoors` · pinned **"Take me in"** (:57) | Take me in → Home | Take me in / any door |

### 1b · Phone — Home (tab 1)

| # | screen · state | how reached | shows first | door | exits |
|---|---|---|---|---|---|
| H1 | Hero · leagueless, index not yet live (`rung 7`) | 0 memberships, < 3 rounds | title "Your card" (HomeHeroCopy.swift:26) · figure "n of 3" (:46) · line "Three rounds and your index goes live. Nothing else needed." (HomeView.swift:951) | **none on the hero** (INFER: the doors are the header `+` menu, HomeView.swift:178-190: Start a league · Start an event · Join with a code · Your golf calendar · Find golfers) | ⊕ tab |
| H2 | Hero · leagueless, index established | 0 memberships, ≥ 3 rounds | "Established. Nobody's seen it yet — you haven't joined a league." (HomeView.swift:952) | none on the hero (web twin has `[Find your buddies]`, index.html:11459) | `+` menu |
| H3 | Hero · league forming (player) | membership phase setup/draft | "<Pro> is setting the bylaws. You'll see them the moment they lock." / "<Pro> draws the squads before first tee — it's random." (HomeView.swift:962-963) | none (a wait state) | tap → Clubhouse |
| H4 | Hero · league forming (Pro) | as above, `isPro` | "Your league is still forming. Lock the bylaws and the invite link is yours." / "Bylaws locked. Draw the squads when the crew is in." (:958-960) | tap → room | Clubhouse |
| H5 | Hero · preseason | season exists, before `starts_on` | "First tee in N days. Rounds before it build your number." / "Rounds before first tee build your number." (:965-969) | none | Clubhouse |
| H6 | Hero · wrapped | season complete | "The cup's been lifted. Run it back." / "Your name goes on the cup." (:978-980) | Run it back lives in `LeaguelessDoors` (LeaguelessDoors.swift:66-88) | Clubhouse |
| H7 | Occasion card | date window, not dismissed this year (HomeStream.swift:202-225) | six windows, e.g. leagueless-only Dec 27–Jan 15 "A fresh table" · "Nobody's ahead yet." · "A season scores the rounds you're already playing. Nothing changes about how you post." · `[Start a league]` | the card's act | dismiss (per year) |
| H8 | Digest row | fresh rounds/posts since last mark, or a quiet day (HomeDigest.swift:77-99) | "Since you were here" · "2 rounds, a personal best from Diego, and Rosa broke 80." (:94) / "Quiet since your last visit" · "<day> — Rosa broke 80 — 74 at Papago GC" (:98) | tap → receipt | — |
| H9 | Feed · loading | `vm.loading && buckets.isEmpty` | three redacted skeleton rows (HomeView.swift:118-119, :192-194) | — | — |
| H10 | Feed · empty | no buddy rounds, no posts | "No rounds from your buddies yet. Post one, or" + link **"add some buddies."** (HomeView.swift:123-124) | "add some buddies." → `HomeRoute.people`; **"Post one" is not a door** | — |
| H11 | Feed · read FAILED, nothing cached | `r.failed && items.isEmpty` (HomeView.swift:279-288) | **the same H10 sentence** — the comment admits it: "With nothing in hand the empty state is the honest answer" | as H10 | pull to refresh |
| H12 | Coming up · empty | no scheduled rounds | door card "Put a round on the calendar →" (UpcomingRoundsSection.swift:41-54) | → Schedule | — |
| H13 | Invites banner | `my_invites` non-empty | "<title> · <container>" · subline · `[Accept] [Details]`; hidden when empty (InvitesBanner.swift:43) | Accept / Details sheet "Accept & join" / "Decline" | — |
| H14 | Lead (the clash) | `week_clashes` row for me; hidden otherwise (HomeLead.swift) | "The clash · closes today" … | tap | — |

### 1c · Phone — Clubhouse (tab 2)

| # | screen · state | how reached | shows first | door | exits |
|---|---|---|---|---|---|
| C1 | Clubhouse · leagueless | 0 memberships (ClubhouseView.swift:40, :79-80, :136-150) | `LeaguelessDoors` (Start a league · I have an invite code · Start an event · [Run it back]) + fine "Post a round — it counts on your card. Leagues score it when you join one." (WizardState.swift:465) + `[Add golfers]` | the doors | — |
| C2 | League room · error | load failed, nothing loaded | card "The room did not load" · error text · `[Try again]` (LeagueRoomScreen.swift:55-62) | Try again | back |
| C3 | League room · loading | first load | `LeagueHeaderCard(loading: true)` → "Loading the room…" (:63, :164) | — | — |
| C4 | Standings table · empty | 0 teams | **"NO ROUNDS YET."** / **"SQUADS FORM WHEN THE PRO LOCKS — STANDINGS START AT THE FIRST POSTED ROUND."** (solo: "INDIVIDUAL RACE — NO SQUADS." / "STANDINGS START AT THE FIRST POSTED ROUND; TOP 2 MEET IN THE CUP FINAL.") (LeagueCopy.swift:374-377; StandingsTableView.swift:27-34) | **none** | — |
| C5 | The climb · empty | 0 teams | **"THE RACE STARTS WITH THE FIRST POSTED ROUND"** / **"SHARE THE LEAGUE CODE TO FILL THE TEE SHEET"** (ClimbView.swift:20-26) | **none** — names "share the code", offers no share | — |
| C6 | Individual race · empty | 0 rows | `CSEmptyState` ⛳ "The race fills in once your league season is live and rounds land." · `[Post a round]` (IndividualRaceView.swift:41-45) | Post a round | — |
| C7 | Squad receipt · empty | squad with 0 counted rounds | "No rounds posted yet — the squad is waiting on its first counter." (ReceiptSheets.swift:72) | none | dismiss |
| C8 | Player receipt · empty (ANY player) | tap a row with 0 rounds | ⛳ "No rounds this season yet — post one and you're on the board." · `[Post a round]` (ReceiptSheets.swift:97-99) — **not gated on `row.me`** (IndRow has `me`, StandingsMath.swift:62) | Post a round (even on someone else's row) | dismiss |
| C9 | Cup Final race · empty | final window, 0 counting rounds | "No counting rounds in the window yet — the slate is still clean." (CupFinalRaceView.swift:93) | none | — |
| C10 | Pot · $0 league | buy_in 0 | "No buy-ins — this league plays for bragging rights." (PotPane.swift:60) | — | — |
| C11 | Pot · stakes empty | 0 stakes | "No stakes on the books. The cookout isn't going to bet itself." (PotPane.swift:134) | INFER: a "Post a stake" control elsewhere on the pane | — |
| C12 | Album · empty | 0 photos | 📷 "Photos land here when rounds carry them — add one from the Post card." · `[Post a round]` (RoomAlbumPane.swift:18-21) | Post a round | — |
| C13 | Board · loading | first load | `BoardSkeleton` (BoardScreen.swift:50, :56; BoardRows.swift:191-192) | — | — |
| C14 | Board · empty | 0 posts | a **synthetic system row** "<League> is live — post the first round" dated today (BoardStore.swift:105-107) — whatever the league's phase | none | compose |
| C15 | Board · load failed | error with 0 items | toast "Could not load the board." (BoardStore.swift:112); INFER: the list is then blank under the toast (no synthetic row, no retry) | none | back |
| C16 | Schedule · tee sheet empty | month with 0 rounds | "Nothing on the tee sheet for <Month>. Put one up: league mates and buddies see it the moment you do." (ScheduleScreen.swift:235) | none in-line (day tap / + elsewhere) | — |
| C17 | Schedule · week by week empty | in league, 0 snapshots | "Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season." (ScheduleModels.swift:351; ScheduleScreen.swift:268-269) | none | — |
| C18 | Scheduled round sheet · loading | open a round | header sub "LOADING…" · "Loading the round…" (ScheduledRoundSheet.swift:33) | — | — |
| C19 | Scheduled round · RSVP empty | host, no tags | "Just you so far — tag your group." (:67) | tag (+) | — |
| C20 | Scheduled round · comments empty | 0 comments | "No messages yet — kick it off." (:88) | compose field | — |
| C21 | Scheduled round · tag picker empty | 0 candidates | "No one to tag yet. Add buddies from the You tab." (:229) | **none** | dismiss |
| C22 | Declare round · tag empty | 0 candidates | "No one to tag yet. Add buddies from the You tab, or invite the league." (DeclareRoundSheet.swift:69) | none | — |
| C23 | Course search · no match / no tees | query with 0 hits | "No match — type the course, rating and slope by hand." (:237; PostCourseSearchField.swift:33; LiveSetupView.swift:472) · "No rated tees listed — type the rating and slope by hand." (:248; :44; :481) | manual fields | — |
| C24 | Event room · error | load failed | "The room did not load" · err · `[Try again]` (EventRoomScreen.swift:27-33) | Try again | back |
| C25 | Event room · no event | `room == nil`, no error | "No event loaded." (:35) — INFER: a dev/transient state | none | back |
| C26 | Ryder · roster empty | team with 0 players | "No one assigned yet." (RyderRoomView.swift:121) | none for a player | — |
| C27 | Ryder · session unpaired | 0 duels | "Pairings not set." (:165) · organiser only: `[Generate pairings]` (:173-175) | organiser only | — |
| C28 | Major · no cards | 0 cards | "No cards yet — first one takes the clubhouse." (EventMath.swift:385-387; MajorRoomView.swift:133) · per-player "No card" / "No card this time" / "No card · buy-in stays in the pot" (:110-114) | none | — |
| C29 | Event picker · Bracket | tap Bracket | toast **"Bracket isn't built yet"** (EventPickerSheet.swift:27) | none | — |
| C30 | Draft night · error / loading | room load | "The room did not load" · `[Try again]` (DraftNightScreen.swift:40-43) · redacted 120pt block (:46) | Try again | — |
| C31 | Draft · pool empty (pre-draw) | 0 in pool | "Pool is empty. Players appear here as they join with the league code." (DraftFormation.swift:94; DraftNightScreen.swift:134) | none in-line | — |
| C32 | Draft · squads empty | 0 squads | card "Squad formation" · "Waiting on the players" · **"THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND"** (DraftFormation.swift:102-104; DraftNightScreen.swift:210-213) | none | — |
| C33 | Draft · done | pool empty, squads set | "Pool's empty. Every player has a squad." (:115, :223) · "Squads are set / Good luck, everybody / Rosters locked · season opens W1" (:106-108) | Pro: Start | — |

### 1d · Phone — Post (⊕) and Live

| # | screen · state | how reached | shows first | door | exits |
|---|---|---|---|---|---|
| P1 | Post round · no league | `membership == nil` | "No league yet? The round still counts on your card — points apply in any league you join." (PostRoundScreen.swift:436) | (the post itself) | — |
| P2 | Post round · no number | provisional index | "No number yet — this round starts it" (D124; PostRoundScreen.swift:444) | — | — |
| P3 | Hole grid · empty card | tap Post with no holes | sheet "Post as even par?" · "YOU HAVEN'T ENTERED YOUR CARD YET" (PostHoleGrid.swift:296) | Post / back | — |
| P4 | Live setup · no league mates | 0 mates | "No league mates to tap yet — search the app or add a guest below." (LiveSetupView.swift:267) | search / guest | — |
| P5 | Live setup / people pickers · empty query | loaded, empty query | "Type a name or @handle to search — buddies you add appear here." (LiveSetupView.swift:658; PeoplePickerSheet.swift:79; EventStagePicker.swift:38) | search | — |
| P6 | Pickers · search miss | 0 hits | "No golfers found. Invite links still work for everyone else." (LiveSetupView.swift:660; PeoplePickerSheet.swift:81; EventStagePicker.swift:40) | none in-line | — |
| P7 | Live play · guests empty | 0 guests | "No guests in this round." (LivePlayView.swift:476) | — | — |
| P8 | Live finish · nothing | 0 complete cards | "Nothing to post." (LiveFinishViews.swift:49) | done | — |
| P9 | `LiveNowBar` | a live round is open / I am awaited | "LIVE" / "ON THE TEE" + line (LiveNowBar.swift:39-41) | tap → live cover | — |
| P10 | Wizard · loading / missing | open wizard | "Loading the wizard…" (WizardScreen.swift:49) · toast "No league with that id — it may have been deleted." (:238) | — | — |

### 1e · Phone — You (tab 4), People, Settings

| # | screen · state | how reached | shows first | door | exits |
|---|---|---|---|---|---|
| Y1 | You · loading | first load | the record redacted as placeholder bars (YouScreen.swift:167, :190) — never "nothing yet" while reads are out (Y-17) | — | — |
| Y2 | You · no rounds | `noRounds` | ⛳ "No rounds yet — your card fills as you play." · `[Post your first round]` (YouScreen.swift:129-135; Career.swift:168-169) | Post | — |
| Y3 | You · partial failure | any block failed | "Some of your card did not load. [Retry]" (YouScreen.swift:121, :230-232; Career.swift:171-172) · tiles show "—" with sub "Did not load" (YouSections.swift:100-105; Career.swift:175) | Retry | — |
| Y4 | Trophy case · empty | rounds exist, 0 tiles | "No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here." (TrophyMeta.swift:164; TrophyCaseView.swift:38-39) | none | — |
| Y5 | Rivalries | 0 rivalries → section hidden (RivalriesSection.swift:16); sheet with 0 weeks: "No head-to-head weeks yet. A clash counts a week you both post." (Rivalries.swift:110) · loading "Pulling the weeks…" (:104) | `[Name this rivalry]` | — |
| Y6 | Your seasons | no league and no record → group head hidden (D178, YouScreen.swift:175-177) | — | — |
| Y7 | Tour Card sheet · loading / failed | open a card | "LOADING…" · "Pulling the card…" (TourCardSheet.swift:49) · "Could not pull the card — check your signal and try again." `[Try again]` (:44-45) | Try again | — |
| Y8 | Buddies · empty | loaded, 0 buddies | "No buddies yet. Search up top to add them." (PeopleScreen.swift:175-176) | search field | — |
| Y9 | Buddies · search | typing | "Searching…" (:65) · miss: "No golfers found under that name. They may not be on Cup Season yet." / "…The link below works for anyone." (:72-73) | invite link when a code exists | — |
| Y10 | Requests | 0 → hidden (BuddyRequests.swift:74); rows: "@handle · wants to be golf buddies" `[Accept] [✕]` (:77-84) | Accept / Decline | — |
| Y11 | Card & settings · leagues | 0 memberships | "No leagues yet. Start one or join with a code." (CardAndSettingsScreen.swift:413-417) | **none** (text only) | — |
| Y12 | Card & settings · Notifications | ⚙ | eyebrow "Notifications" · pills **"Enable on this device"** / "Disable on this device" · "Round pings: ON" · "Chat pings: ON" · "Season email: ON" (:487-495) · gold line when unconfirmed "This device is on here, but we haven't been able to confirm it with the server. Reopen the app with signal, or tap Disable then Enable." (:501-503) · fine "Moments, reveals, and month closes always come through. Round posts and chat each have their own switch." (:505) | pills | — |
| Y13 | Push toasts | enable/disable | "Notifications on. The board will find you." (PushService.swift:133) · "Notifications blocked: allow them in Settings" (:123) · "Could not get a device token from Apple. Try again." (:124) · "Could not save this device." (:128) · "Notifications off on this device" (:147) | — | — |
| Y14 | Push explainer sheet | after card saved / first round / league joined, stage clear (PushAsk.swift:23-46; MainTabView.swift:330-335, :444-446) | title "Hear it when it happens" · eyebrow "YOUR CARD IS IN" / "FIRST ONE ON THE BOARD" / "YOU'RE ON THE ROSTER" (:76-82) · "A round lands on the board. A duel is closing. The table moves." · "A buddy request, a tee time, an invite — answered from the lock screen." · "Nothing else. No streaks, no noise, no badge you didn't earn." (:88-90) · `[Turn on notifications]` / `Not now` (:94-99); swipe = Not now (:111) | Turn on → system prompt | Not now (14-day snooze, PushAskPolicy.swift:20) |
| Y15 | Feedback / founder desk | ⚙ | "Pulling the numbers…" (FeedbackSheet.swift:179) · "Nothing yet." (:214) | — | — |
| Y16 | Join with code · miss | bad code | "No league with that code — check with your Pro" (JoinLeagueFlow.swift:96) | retype | — |
| Y17 | Toast error buckets | any failed write | "Connection hiccup — check your signal and try again." · "Just updated — give it a second and try again." · "That didn't go through — please try again." · "Something went wrong — please try again." (BoardText.swift:113-125; PeopleModels.swift:151-167) | none (toast) | — |

### 1f · Web PWA (`index.html`) — the same states

| # | state | copy (exact) | door |
|---|---|---|---|
| W1 | boot stalled (10 s watchdog) | **"Boot stalled at [memberships] — network or auth hang"** (:19997) · **"Boot failed at [step]: <raw error>"** (:20068, :20132) | none |
| W2 | Home tile, no league | **"League · None yet · JOIN OR START"** (:11044) | tap → hub |
| W3 | Home hero, 0 buddies | "Established. *Nobody's seen it* — you haven't added a buddy yet." `[Find your buddies]` / "N more and your index is live. *Play anywhere.*" `[Post a round]` (:11455-11459) | yes |
| W4 | Home feed loading / empty | `skeletonRows(3)` (:12136, :11949) · "No rounds from your buddies yet. Post one, or [add some buddies]." (:12147) | link |
| W5 | Clubhouse leagueless (`#hubLeagueless`) | "League play — cup season" · `[Start a league]` `[I have a league code]` `[Add golfers]` `[Sign out]` · "No code? Any league member can share an invite link." (:3608-3620) | yes |
| W6 | Climb / standings empty | "THE RACE STARTS WITH THE FIRST POSTED ROUND / SHARE THE LEAGUE CODE TO FILL THE TEE SHEET" (:4773) · "NO ROUNDS YET. / SQUADS FORM WHEN THE PRO LOCKS — …" (:5078) | none |
| W7 | Board empty | synthetic "<League> is live — post the first round" (:16869) | none |
| W8 | `emptyState()` helper | icon · line · `[cta]` (:12776-12784) — used: You recent "No rounds yet — your card fills as you play." `[Post your first round]` (:12924); player sheet "No rounds this season yet — post one and you're on the board." `[Post a round]` (:13072) | yes |
| W9 | Buddies / leagues / draft / Ryder | "No buddies yet. Search up top to add them." (:15307) · "No leagues yet. Start one or join with a code." (:15764) · "Pool is empty. Players appear here as they join with the league code." (:17053) · "No one yet" (:17044) · "Pool's empty. Every player has a squad." (:6111) · "No one assigned yet." (:14301) | none |
| W10 | Pot pay | "The Pro hasn't posted how to pay yet — ask them in the board." (:7971) | none |
| W11 | Invites banner | "League invite · <name>" / "Ryder invite · <name>" · "from <inviter>" · `[Accept] [Details]`; details: "A season-long league." / **"A Ryder event — two teams, vs-index duels."** (:14552-14575) | yes |
| W12 | Notifications settings | `[Enable on this device] [Round pings: —] [Chat pings: —] [Season email: —]` · "Moments, reveals, and month closes always come through. Round posts and chat each have their own switch." (:15818-15823) | pills |
| W13 | Push toasts | "Notifications on. The board will find you." (:16374, :16395) · "Notifications blocked: allow them in settings" (:16382) · "Push not wired up yet: key pending" (:16377) · "Notifications need the installed app: add to home screen first" (:16379) · "Notifications off on this device" (:16412) | — |
| W14 | Misc | "Still loading — try again in a second" (:10164) · course search `[Try again]` (:7751) · "Photo saved after the next server update — try again tomorrow" (:15918) · founder desk "Nothing yet." (:18031) · `humanError` buckets (:4437-4461) | — |
| W15 | SW notification click | always `url:'/'` → Home (sw.js:73-77, :81-95; push/index.ts:185) | Home only |

### 1g · Notifications — every kind, its trigger, its exact copy, where it lands

Sender: `supabase/functions/push/index.ts`. Title ≤ 80, body ≤ 140, word-boundary clamp (:43-53). `headline()` (:68-84): an authored `push_title` wins, else the row's first sentence is the title and "<league> · <rest>" is the body. Web push payload is always `{title, body, url:'/'}` (:185). APNs adds `thread-id`, `badge` (actionable count), `category` for the three answerable kinds, and `cs` (:231-240).

| # | kind (`cs.kind`) | trigger (server) | recipients & filters | exact copy (title / body) | lands on (phone) | lock-screen actions | brief class |
|---|---|---|---|---|---|---|---|
| N1 | `round` | `posts` INSERT kind=round — one row **per league** the golfer is in (prod: 2 posts per round for 2-league golfers) | league members minus author; `notify_rounds`; mutes (:507-521) | "Jerecho posted 89 at UNM Championship" / "<League>" (SAW body in prod) | round receipt | — | **noise-adjacent**: the vision's "Friend posted", but per league not per friend |
| N2 | `chat` | posts kind=chat (4 ever) | `notify_chat`; mutes | first sentence / "<League> · rest" | Board | — | fine, rare |
| N3 | `announce` | posts kind=announce (📣 by the Pro) | all, always | first sentence / league | Board | — | meaningful |
| N4 | `moment` | posts kind=moment (85 ever; e.g. "Galen broke 80 for the first time" / "<League> · a 79. That one goes on the wall." — contract §1) | all, always | authored | Board | — | **anticipation/meaning** — the best kind here |
| N5 | `system` | posts kind=system (54 ever): "August is in the books. The ledger is posted." · "The monthly goes to Timber. 15 points." · "The clash this week: Galen v Jerecho." · "Galen put a round on the books — Mon Sep 07 · Gold Canyon…" · "<Name> joined the league." · "Rosters locked. The season is live. Post a round." · "Minimum four to tee off — N in so far. Share the invite link." (board_voice_natural_case.sql:965, :1063, :2389; prod bodies) | all, unless `leagues.notify_system=false` (:497-499); no client control found (INFER) | first sentence / league | Board | — | mixed: month close = meaningful; "joined the league" and tee-sheet declarations = feed, not push |
| N6 | `settlement` | system post with `live_round_id` (a live round settled) | all | `posts.push_title` (authored short share string) / league | scorecard | — | meaningful |
| N7 | `event` | event-board post (no `league_id`) | **all `event_players` including the author** (:471-473) | first sentence / event name | event room | — | meaningful; author-ping is a bug |
| N8 | `invite` (CS_INVITE) | `invite_golfer` → push_nudges (push_wave7.sql:76-86) — **0 rows ever** | invitee | "<League or event name>" / **"<First> put you on the tee sheet"** | Home invites banner | `Accept` | meaningful; wrong sentence for a league |
| N9 | `request` (CS_REQUEST) | `friend_request` (push_wave7.sql:116-121) — 6 ever | addressee; mutes | **"<First> wants in your crew"** / "Tap to accept" | Requests | `Accept` · `Decline` | meaningful |
| N10 | `rsvp` (CS_RSVP) | `declare_round` / `retag_round` per newly tagged (…declare_round_posts_and_guards.sql:113-121; …booking….sql:128-136) — 1 ever | tagged | **"<First> put you on the tee sheet"** / "Sat Sep 5 · Encanto GC — in or out?" | scheduled round sheet | `I'm in` · `Can't` | **anticipation** (the brief's "Saturday" shape) |
| N11 | `nudge` (live round) | `start_live_round` per seated member/visitor except starter (board_voice_natural_case.sql:2347-2362) | seated | **"<First> put you on the tee sheet"** / "Live round at <course> — open the app to score it with them" | live round | — | meaningful |
| N12 | `nudge` (Ryder taunt) | `round_duel_nudge` trigger on `rounds` INSERT when opponent is in a pending duel (nudge_payloads.sql:143-152) | the opponent | "<Event name>" / **"Galen posted — +2.3 to beat · 3 days left"** (or "· closes tonight") | event room | — | **the one true anticipation push in the product** — "Jake just passed you" in Ryder form |
| N13 | `nudge` (founder report) | `content_reports` INSERT (the_takedown_path.sql:318-345) | founder only | "A report needs you" / "Someone reported a comment. Open the founder's desk." payload `{report_id, desk}` | **Home** (no desk route: PushPayload.swift:92-95) | — | ops |
| N14 | friend-accept (`request`, no category) | `friendships` UPDATE pending→accepted (:411-419) | the requester | "<First> is in your crew" / "You'll see their rounds now" | **Requests** (:417 routes `request` with `profile_id`) | — | meaningful; lands on an empty list |
| N15 | friend-request **email** | `friendships` INSERT pending (:396-410) via Brevo | addressee | subject "<First> wants in your crew"; body "Hi <First>, **<From> wants in your crew on Cup Season.** Accept and their rounds land in your feed, all season. [Open Cup Season] You're getting this because someone added you on Cup Season. **Manage notifications in your Tour Card.**" (:362-374) | cupseason.app | — | fine; footer wrong |
| N16 | local · duel reminder | `EventRoomModel.load()` → `PushDuelReminder.sync` — only when the room is opened that day; open session closing today, I have not posted, before 18:00 (PushDuelPlan.swift:39-47) | me | "Your duel closes tonight" / "You haven't posted." · subtitle event name (:53-54) | event room | — | **anticipation** — but conditional on opening the app |
| N17 | local · action failed | a lock-screen action threw (PushActions.swift:43-51) | me | "<original title>" / "That one didn't take — open the app." (:28) | — | — | fine |
| N18 | realtime `live_open` | league channel broadcast (not the push function) | app open only | `LiveNowBar` "ON THE TEE · …" | live cover | — | in-app only |
| N19 | email · season recap | `seasons.status → complete` → `email_queue` → `season-email` — **never fired** | every member with `email_prefs.recap` (default on) | subject "The Cup goes to <First> by 12 — <League>" (season-email/index.ts:250-251); body "SEASON COMPLETE / <Champion> / Champion · <League> / 412–388 points / 24 clear of <runner-up> / Runner-up · Points king / Your cut of the pot: $180 · Whoever collected it sends it on. / FINAL TABLE / [See the rounds behind it] / Cup Season keeps the ledger; the money moves between friends. / Turn off season emails" (:60-125) | app root | — | **story** — the one artefact that reads as a season |
| N20 | email · league cancelled | `cancellation_notices` INSERT — never fired | members | subject "<League> is off — your $50 comes back" / "<League> is off" (:209-211); "LEAGUE CANCELLED / <League> has been called off / The season won't be played. Nobody won, and every buy-in comes back. / Your $50 buy-in comes back · Whoever collected it sends it back. / Your rounds stay on your card — all of them." (:158-179) | — | — | meaningful |
| N21 | email · auth OTP | Supabase Auth; `config.toml` shows the default template (no custom `[auth.email.template]`, :219-255) | signer-in | (Supabase default — not in repo) | — | — | transactional |
| — | badge | `actionable_count_of` = pending requests to me + open invites to me + open live rounds I'm on; seen clears (PushBadge.swift:19-40; push-contract §4) | — | — | — | — | good discipline |

**Mute flags / prefs (SAW):** `profiles.notify_rounds`, `profiles.notify_chat` (server-enforced, :507-512; all 39 = true); `mutes` (per author, :150-155, :455-457, :516-520); `leagues.notify_system` (RPC `set_league_notify_system` exists, LeagueRoomModel.swift:31-35; no control string found in either client); `email_prefs.recap` ("Season email" pill; unsubscribe token). Author is never pinged on league posts (:518); is pinged on event posts (:471-473).

**Permission ask (SAW):** never on launch; three moments — `card_saved` (CardGateView.save), `first_round` (EpilogueSheet.onAppear when first ever), `league_joined` (JoinLeagueFlow / InvitesBanner accept / wizard onJoined, MainTabView.swift:475) — shown only when the OS status is `.notDetermined` and "Not now" is ≥ 14 days old; the pending request is consumed whether or not the sheet shows (PushAsk.swift:29-31). Registration on launch re-syncs silently only when already authorized (PushService.swift:95-111).

**What the brief wants that does not exist (SAW: no sender, no post kind, no trigger):**

| brief's example | closest thing today | gap |
|---|---|---|
| "Jake just passed you" | Home hero move chip "▲ up 2" on open (HomeView.swift:930-932); Ryder-only taunt N12 | no rank-change post kind; the vision's own "League lead changed" has no producer |
| "You're 4 points from 2nd" | D130 stake line on Home, "silent by default, Push: none" (decision-log:4337-4341) | in-app only, and only for the clash/floor/seed cases |
| "Saturday's event is filling up" | nothing (invites: 0 ever; RSVP push exists per tag only) | no seat-count or fill push |
| "Mike challenged you" | RSVP tag N10 ("in or out?"); Ryder duel N12 | no challenge object between two golfers |
| "Your season starts in 3 days" | hero "First tee in N days" (HomeView.swift:967), in-app only | no scheduled push; `system` "Rosters locked. The season is live." fires at lock, not at first tee |
| week result / "you won the clash" | system post "The clash this week: Galen v Jerecho." (opening) — the RESULT is a Home lead card, not a post (INFER) | the result is the story; the opening is the schedule |
| "your index just went live" (rung 7 → established) | nothing | the leagueless golfer's one milestone has no sentence |

**How a golfer with no league is ever notified (SAW):** only by another person acting on them — a buddy request (N9 push + N15 email), a buddy accepting (N14), being tagged on a scheduled round (N10), being seated on a live round (N11), or an invite (N8, never yet sent). League posts fan by `league_members` (:485-521), so **a buddy's round never reaches a leagueless golfer's lock screen even though it appears in their Home feed** (cross-league buddies feed). Nothing is ever said about their own golf. 14 of 39 profiles are in this state today.

---

## Section 2 · Flows

### Flow A · First launch → useful Home (goal: "understand in seconds, land somewhere useful")
- **Current friction:** boot shows "Restoring your session" (B1) on a cold launch for an account that has no session — a sentence about a thing that does not exist. A bad signal on the very first launch lands "Boot stalled" (B2) with `Sign out` as the second button. Then the door, the card gate, then the orientation (B6) — a teaching screen the brief explicitly bans ("no explainer slides"), though it is one screen, skippable, and correctly gated on "nothing yet".
- **Unnecessary complexity:** the orientation teaches four nouns and two ways to play before the golfer has done anything; the brief wants handicap / who you play with / what golf you play, then a useful Home.
- **Confusing terminology:** "Boot stalled" (RootView.swift:144); "Restoring your session"; "the long game / the short game"; "Its own little trophy."
- **Dead ends:** B3 `MustUpdateView` has no button; B2's "Sign out" on a network failure throws away the session for a connectivity problem.
- **Missing feedback:** none of the boot states says how long it has been waiting or what to check (the web at least names the step, badly).
- **Delight:** the door's "No code yet? Check spam…" after 20 s is the right instinct; the card gate → push ask ("YOUR CARD IS IN") is the wrong moment (nothing of value has been shown yet — see EN-25).

### Flow B · The leagueless golfer's first week (goal: "play before league")
- **Current friction:** Home hero H1/H2 has no door of its own; its line is a status ("Nobody's seen it yet — you haven't joined a league") that reads as a deficiency, not an invitation. The feed empty line H10 half-links ("Post one" is text). The `+` menu is a five-item list behind a plus glyph. Clubhouse C1 is the doors screen — good — but it is one tab over from where the golfer is told they have nothing.
- **Unnecessary complexity:** between Jul 25 and Sep 17 (today) no occasion card exists (HomeStream.swift:202-214), so a September leagueless Home carries hero + empty feed line + calendar door + nothing seasonal.
- **Terminology:** "your index goes live", "Established.", "Play anywhere.", "counts on your card".
- **Dead ends:** Y11 "No leagues yet. Start one or join with a code." is text; C21/C22 "Add buddies from the You tab." is a route description with no door; the trophy case (Y4) tells a golfer who has posted rounds to "post your first round".
- **Redundant:** the You tab's Y2 and Home's H10 both ask for a first round in different words; C1's line "Post a round — it counts on your card…" and P1 "No league yet? The round still counts on your card…" say the same thing twice on the way to one post.
- **Missing feedback / notifications:** nothing is ever pushed to this golfer about their own golf (index established, a buddy's round, "two more to go"). The feed shows buddies' rounds; the lock screen never does (EN-02).
- **Delight opportunity:** the D124 "No number yet — this round starts it" and the rung-7 "n of 3" progress are the seed of a real first-week story — they just have no voice outside the app.

### Flow C · Member of a forming league opens the Clubhouse (goal: "what is happening, what happens next")
- **Friction:** the first thing under the header is C4 or C5 — two lines of ALL-CAPS mono that describe mechanics ("SQUADS FORM WHEN THE PRO LOCKS", "STANDINGS START AT THE FIRST POSTED ROUND") and give an instruction ("SHARE THE LEAGUE CODE") with no button. The board (C14) says the league "is live — post the first round" while the hero says the Pro is still setting the bylaws.
- **Complexity:** the draft screen's C32 "THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND" is three nouns of machinery.
- **Terminology:** "counter" (C7), "the slate is still clean" (C9), "snapshot writes Sunday night" (C17), "seeds", "roster", "pool".
- **Dead ends:** C4, C5, C7, C9, C17, C26, C27 (player), C31, C32 — none has a door.
- **Missing feedback:** no "N in · K more to tee off" on the empty standings (D120 asked for it); no "invite link" affordance where the copy says to share it.
- **Delight:** C28 "first one takes the clubhouse" and C11 "The cookout isn't going to bet itself." are the voice the rest should have.

### Flow D · Turning notifications on (goal: "hear it when it happens", zero explanation)
- **Friction:** the ask (Y14) fires at three moments only; prod says it has fired once. A golfer who taps "Not now" at card-save is not asked again until they post their first round or join a league; nothing on Home or in the feed ever offers the door. Settings shows "Enable on this device" — enable *what*, on *which* device — beside pings that are already "ON" while nothing is enabled (M-136, still verbatim).
- **Complexity:** four pills + a fine line that names "Moments, reveals, and month closes" — three terms a new golfer has not met.
- **Terminology:** "pings", "reveals", "device", "Season email".
- **Dead ends:** OS-denied → toast "Notifications blocked: allow them in Settings" with no deep link (`UIApplication.openNotificationSettingsURLString` is not used, INFER from PushService.swift:114-134); the `unconfirmed` state's remedy is "Reopen the app with signal, or tap Disable then Enable."
- **Missing feedback:** after "Turn on notifications" the sheet's only reply is a toast; no preview of what the first notification will look like.
- **Delight:** the explainer's three lines are excellent and honest ("no badge you didn't earn"); they belong on Home as an optional door, not only in a 14-day-snoozed sheet.

### Flow E · Receiving and acting on a notification (goal: "one tap, right place")
- **Friction (design):** three different invitations wear one title ("<First> put you on the tee sheet" — N8 league invite, N10 RSVP, N11 live round); stacked under thread `you` they are indistinguishable until the body. N14 friend-accept lands on the Requests list, where the accepted request is not (it was mine). N13 lands Home.
- **Friction (reality):** zero production tokens (EN-01). The seven `push_opened` events are, INFER, the owner's dev phone.
- **Terminology:** "wants in your crew" (push) vs "wants to be golf buddies" (screen, BuddyRequests.swift:77) vs "Buddies" (section) vs "Add golfers" (door).
- **Missing feedback:** a foreground arrival while already on the routed screen still banners with sound (AppDelegate.swift:54 returns `[.banner, .list, .sound]` for every kind — INFER no on-screen check).
- **Delight:** lock-screen `I'm in / Can't`, `Accept / Decline` with no app open is exactly the brief's "smallest useful action"; the badge-is-unseen rule (D179) is right.

### Flow F · Being invited (league · round · live round) (goal: "who I'm competing with, what happens next")
- **Friction:** N8 has never fired (0 invites ever) — league joining is by code/link, so the invite push is theoretical; the copy it would send names the league only in the title and says "tee sheet" for a season-long league. N10 is the best-shaped push in the product ("Sat Sep 5 · Encanto GC — in or out?") and has fired once.
- **Dead ends:** a tagged golfer who is not on the app gets nothing (no SMS/email path for tags; the live-round guest gets a claim link, INFER).
- **Missing:** "filling up", "N in", "closes Friday" — no state-change follow-ups after the first ask.

### Flow G · Season end and cancellation (goal: "seasons read as a story")
- **Friction:** the only story artefact is an email that has never been sent (0 completed seasons). Its CTA "See the rounds behind it" opens the web root, never the phone, never the ceremony. The in-app `SeasonCeremonyView` exists but no push says "the cup's been lifted" (a `system` post may — INFER, `close_season` writes system posts at :474/:506).
- **Terminology:** "Points king", "the ledger", "clear of" — canon, fine.
- **Delight:** the cancellation email's refund-first subject and "Your rounds stay on your card — all of them." are model copy.

### Flow H · Errors and retries (goal: "never a dead end")
- **Friction:** four generic toast buckets (Y17) with no retry; room/event/draft errors have a card with `Try again` (good); the Board's failure is a toast over a blank list (C15); Home's failure with no cache is a social sentence (H11); the web's boot failure is a developer string (W1).
- **Missing feedback:** no offline indicator anywhere; "Connection hiccup" is the only network vocabulary.

### Flow I · The web reference client
- The web carries the banned literal ("League · None yet · JOIN OR START"), raw boot strings, `url:'/'` on every push, "vs-index duels" in the Ryder invite detail (:14570; Q-32 said drop it), and the same caps standings/climb empties. Where the web is ahead: the hero's `[Find your buddies]` / `[Post a round]` CTA on the leagueless card (W3) and the `emptyState()` helper's mandatory door — the phone's `CSEmptyState` makes the door optional (`cta: String? = nil`, Components.swift:158) and most call sites omit it.

---

## Section 3 · Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Damages" names which of the brief's five questions (what is happening · why it matters to me · what I can do now · who I am competing with · what happens next) the state hurts.

**EN-01 · P0 · No production phone has ever registered for push.** SAW: `device_tokens` = 1 row, `platform='ios-sandbox'`; 0 `ios` rows; `push_prompt_shown` = 1 ever, accepted 0, declined 0; `invites` = 0 rows. TestFlight 669 is with external testers. Evidence: prod queries above; PushService.swift:27-31 (platform), PushAsk.swift:29-46. Damages: *what happens next* — for every tester the product is silent between opens. Recommendation: before any redesign, confirm on one TestFlight phone that the ask rises after the first round and that a `platform='ios'` row lands; put a persistent, dismissable "Hear it when it happens" door on Home for any golfer whose OS status is `.notDetermined`.

**EN-02 · P1 · A golfer with no league is never told anything about golf.** SAW: push recipients are `league_members` (push/index.ts:485-521); no buddy-graph fan-out exists; Home's feed IS cross-league buddies (HomeView.swift:104-107, "D218: the lane is cross-league"). 14 of 39 profiles are leagueless. Damages: *who I am competing with*, *what happens next*. Recommendation: fan `round` and `moment` posts by buddies (mutual `friendships`) as well as by league, dedup per recipient; add a first-week sentence for the leagueless golfer's own milestones ("Two more and your number is live", "Your number's live: 14.2").

**EN-03 · P1 · Multi-league members get the same news N times.** SAW: a round posts once per league (prod: 2 posts for one `round_id` across 2 leagues); "August is in the books. The ledger is posted." posts per league (5 of the last 12 posts); `apns-collapse-id` is the post id (:272), which differs per league, so nothing folds; 11 of 25 members are in ≥ 2 leagues. Damages: *why it matters to me* (noise). Recommendation: dedup at `sendTo` by (recipient, round_id | event key) within a window; one month-close push per golfer that names all their leagues.

**EN-04 · P1 · None of the brief's anticipation notifications exist, and neither do the vision's.** SAW: no post kind or trigger for rank change, points-to-next, seat count, challenge, or season-start countdown; D130 stake line is "Push: none" (decision-log:4337-4341); the vision lists "League lead changed. Championship clinched." (product-vision-v1.0.md:123). The only forward-looking pushes are N10 (RSVP), N12 (Ryder taunt) and N16 (local duel reminder). Damages: *what happens next*, *who I am competing with*. Recommendation: generalise N12's shape to leagues — "Galen posted — you're 4 back", "Season opens Saturday", "Week closes tonight — you haven't posted" — as `moment`-class posts with a `push_title`, rate-limited to one per golfer per day.

**EN-05 · P1 · Three invitations, one sentence.** SAW: `invite_golfer` (push_wave7.sql:83), `declare_round`/`retag_round` (:157, :224; later re-creations verbatim) and `start_live_round` (board_voice_natural_case.sql:2352) all title "<First> put you on the tee sheet"; the league invite's body is just the league name. Damages: *what is happening*. Recommendation: one verb per kind — "<First> invited you to <League>" · "<First> is playing Sat Sep 5 at Encanto — in?" · "<First> teed off at <course> — score with them".

**EN-06 · P1 · The duel reminder only exists if you opened the room that day.** SAW: `PushDuelReminder.sync` is called from `EventRoomModel.load()` (push-receiver.md:99-101; PushDuelReminder.swift:14-38); nothing schedules it server-side. Damages: *what happens next* for exactly the golfer who forgot. Recommendation: move the 18:00 "Your duel closes tonight" to the sender (a cron over open sessions), keep the local one as a fallback.

**EN-07 · P1 (web) · The web's boot failure shows developer strings.** SAW: "Boot stalled at [memberships] — network or auth hang" (index.html:19997), "Boot failed at [step]: <raw>" (:20068, :20132). Damages: *what I can do now*. Recommendation: the phone's card (a sentence + Try again) with the step in a dim second line.

**EN-08 · P1 · Standings and climb empties are ALL-CAPS mechanics with no door.** SAW: LeagueCopy.swift:374-377, StandingsTableView.swift:27-34, ClimbView.swift:20-26 (phone); index.html:4773, :5078 (web). "SHARE THE LEAGUE CODE" with no share control; "SQUADS FORM WHEN THE PRO LOCKS". The 2026-08-30 lower-case pass (D-"shouting") fixed SQL, not these. Four of four player personas met this screen (D119). Damages: *what is happening*, *what I can do now*. Recommendation: stage-aware sentence from D120's `leagueStage()` ("3 in · one more to tee off") + the invite sheet as the door; sentence case.

**EN-09 · P1 · The Board's empty row announces "is live" whatever the phase.** SAW: BoardStore.swift:105-107 synthesises "<League> is live — post the first round"; index.html:16869 same. D120 retired that exact phrase for being "pushed regardless of phase" (decision-log:4234-4236). Damages: *what is happening* (contradicts the hero). Recommendation: the board's empty line reads the stage: forming → "The board opens when the bylaws lock"; preseason → "First tee Sat Sep 5 — rounds before it build your number".

**EN-10 · P1 · A network failure on Home reads as "No rounds from your buddies yet."** SAW: HomeView.swift:279-288 (comment: "With nothing in hand the empty state is the honest answer") — it is not honest, it is a social verdict for a connectivity error; and "Post one" in the sentence is not a door (:123). Damages: *what is happening*, *what I can do now*. Recommendation: `r.failed` → "Couldn't reach the board — pull to try again"; make "Post one" open the composer.

**EN-11 · P1 · M-138 is still open: another member's empty receipt tells me to post.** SAW: ReceiptSheets.swift:97-99 renders "No rounds this season yet — post one and you're on the board." + `[Post a round]` without reading `row.me` (StandingsMath.swift:62); web :13072 same. Damages: *who I am competing with* (reads as posting on their behalf). Recommendation: `row.me ? (line, Post) : "Casey hasn't posted this season."` with no CTA, or a "Put a round on the calendar with Casey" door.

**EN-12 · P1 · The notification settings do not explain themselves (M-136 open verbatim).** SAW: CardAndSettingsScreen.swift:487-505; index.html:15818-15823. "Enable on this device" beside "Round pings: ON" while nothing is enabled; "Moments, reveals, and month closes always come through." Damages: *what I can do now*. Recommendation: one switch with a sentence under it ("Notifications: off — you'll hear when a round lands, a duel is closing, or someone puts you on a tee sheet"), the two pings as sub-rows, the email as its own row; when OS-denied, a door to the system settings page.

**EN-13 · P2 · Web notification taps always land Home.** SAW: push/index.ts:185 (`url:'/'`), sw.js:73-77. Damages: *what I can do now*. Recommendation: send the same route the APNs payload carries as a `?open=` URL.

**EN-14 · P2 · Friend-accept lands on the wrong screen.** SAW: push/index.ts:415-418 routes `request` with `profile_id`; `PushRoute.from` maps `.request` → `.requests` (PushPayload.swift:98) — the Requests list shows incoming requests, not my accepted one. Damages: *who I am competing with*. Recommendation: a `buddy` kind → the buddy's Tour Card (`presenter.tourCard = profile_id`).

**EN-15 · P2 · Event posts push to their own author.** SAW: push/index.ts:471-473 ("event rows carry no author column … 'never the author' and mutes cannot apply here"). Damages: noise. Recommendation: carry `profile_id` on event posts (the Ryder taunt already knows the poster).

**EN-16 · P2 · The ask precedes the aha.** SAW: `card_saved` fires in `CardGateView.save()` before Home has ever rendered (push-receiver.md:89); eyebrow "YOUR CARD IS IN" (PushAsk.swift:78); a "Not now" then snoozes 14 days (PushAskPolicy.swift:20) and only another moment re-asks (:29-33). Damages: activation. Recommendation: drop `card_saved`; keep `first_round` and `league_joined`; add `tagged_on_round` and `buddy_accepted` as moments; surface the explainer as a Home door while `.notDetermined`.

**EN-17 · P2 · `MustUpdateView` is a dead end.** SAW: RootView.swift:153-165 — no button to TestFlight or the App Store. Damages: *what I can do now*. Recommendation: one button that opens the store/TestFlight URL.

**EN-18 · P2 · "Boot stalled" + Sign out.** SAW: RootView.swift:144-147; fallback "Could not load your card." (SessionStore.swift:118). Damages: *what is happening*. Recommendation: "Couldn't reach Cup Season" · the human reason · Try again; Sign out only after a second failure, and never as the same-weight button.

**EN-19 · P2 · Terminology drift across one notification.** SAW: push "wants in your crew" (push_wave7.sql:119; push/index.ts:407); screen "wants to be golf buddies" (BuddyRequests.swift:77); section "Buddies"; email footer "Manage notifications in your Tour Card" (push/index.ts:372) — notifications live in Card & settings, not the Tour Card. Damages: *what is happening*. Recommendation: one noun ("buddies") on every rail; fix the footer.

**EN-20 · P2 · Schedule "Week by week" leaks the mechanism.** SAW: "Nothing recorded yet: the first snapshot writes Sunday night, and every week lands here for the season." (ScheduleModels.swift:351). Damages: *what is happening*. Recommendation: "Your first week closes Sunday — every week's result lands here."

**EN-21 · P2 · "Add buddies from the You tab." is a route, not a door.** SAW: ScheduledRoundSheet.swift:229; DeclareRoundSheet.swift:69; buddies are also reached from Home ("YOUR BUDDIES ↗", HomeView.swift:109). Damages: *what I can do now*. Recommendation: an inline "Find golfers" button that opens the people picker in befriend mode.

**EN-22 · P2 · Draft-night empties are machinery in caps.** SAW: "THE BOARD SEEDS FROM YOUR ROSTER ONCE INVITES LAND" (DraftFormation.swift:104); "Pool is empty. Players appear here as they join with the league code." (:94) with no share door. Damages: *what is happening*. Recommendation: "Waiting on the players — 3 in, need 4" + the invite sheet.

**EN-23 · P2 · The leagueless Home hero has no door and frames the state as a deficiency.** SAW: "Established. Nobody's seen it yet — you haven't joined a league." (HomeView.swift:952); no CTA on the hero (INFER — the doors are the `+` menu, :178-190); the web twin carries `[Find your buddies]` (index.html:11459). Damages: *what I can do now*, *why it matters to me*. Recommendation: the hero carries one door that changes with the rung ("Post a round" → "Find your buddies" → "Start a season"), and the line reads as an offer.

**EN-24 · P2 · The Home occasion calendar is dark for eight weeks either side of now.** SAW: windows Mar 28–Apr 13, Jun 8–22, Jul 10–24, Sep 18–Oct 5, Oct 1–Nov 20, Dec 27–Jan 15 (HomeStream.swift:202-214); on 2026-09-04 nothing shows. Damages: *what happens next* for the leagueless. Recommendation: a non-calendar occasion for the leagueless ("Your buddies are playing Saturday" / "Three of you have numbers — that's a league") so Home is never without an invitation.

**EN-25 · P2 · The badge and lock-screen actions have never had a real recipient, and the founder nudge routes Home.** SAW: `push_action` 0 events; N13 payload `{report_id, desk}` → `.home` (PushPayload.swift:92-95). Damages: ops only. Recommendation: a `desk` route; verify actions on a real phone before relying on them in the redesign.

**EN-26 · P2 · Toast-only errors have no retry and four generic buckets.** SAW: BoardText.swift:113-125; PeopleModels.swift:151-167; index.html:4437-4461; "Something went wrong — please try again." is the fallback. Damages: *what I can do now*. Recommendation: every failed write toasts with a `Retry` action; the fallback names the thing that failed ("That round didn't post").

**EN-27 · P2 (web) · The literal banned string.** SAW: "League · None yet · JOIN OR START" (index.html:11044). Damages: *what I can do now*. Recommendation: the tile becomes the door ("Start a season" / "Invited · Review" per A-11).

**EN-28 · P3 · The trophy case contradicts its own gate.** SAW: shown only when rounds exist (YouScreen.swift:129-146) yet says "post your first round" (TrophyMeta.swift:164). Recommendation: "Break 80, take a week, win a Cup Final — it lands here."

**EN-29 · P3 · "Bracket isn't built yet" is a door to nothing in the shipping app.** SAW: EventPickerSheet.swift:27. Recommendation: hide until built.

**EN-30 · P3 · Foreground banners for the screen you are on.** INFER from AppDelegate.swift:48-54 (`[.banner, .list, .sound]` unconditionally). Recommendation: suppress when the routed screen is up.

**EN-31 · P3 · `notify_system` has an RPC and no hand.** SAW: `set_league_notify_system` in Rpc.swift:1768 and LeagueRoomModel.swift:31-35; no control string found in either client (INFER). Recommendation: either a Pro-side switch on the League pane or delete the flag.

**EN-32 · P3 · Season email CTA opens the web root.** SAW: season-email/index.ts:120 (`${APP}/`). Recommendation: a Universal Link to the ceremony (`cupseason.app/?season=<id>`).

**EN-33 · P3 · Settings' "No leagues yet. Start one or join with a code." is text.** SAW: CardAndSettingsScreen.swift:417; index.html:15764. Recommendation: two mini doors.

**EN-34 · P3 · Web Ryder-invite detail still says "vs-index duels".** SAW: index.html:14570 (Q-32 listed it for removal). Recommendation: "Two teams. Weekly duels. First past half the points."

**EN-35 · P3 · "Photo saved after the next server update — try again tomorrow."** SAW: index.html:15918. Recommendation: delete or say what actually happened.

**EN-36 · P3 · `CSEmptyState`'s door is optional and usually omitted.** SAW: Components.swift:151-176 (`cta: String? = nil`); of the empty copy inventoried above, only Y2, C6, C8, C12 pass one; ~25 others use `CSFine`/`Text` with no door. Recommendation: make the door required (a `next: Door` enum), retire bare `CSFine` empties.

---

## Section 4 · What already serves the brief (keep, and build on)

- **The one-line-one-door pattern exists and is right:** `CSEmptyState` (Components.swift:151-176) — "a quiet icon, one line in voice, one next step … Every dead end becomes a next move"; used well at YouScreen.swift:135 (⛳ "No rounds yet — your card fills as you play." · Post your first round), IndividualRaceView.swift:41-45, RoomAlbumPane.swift:18-21; the web's `emptyState()` (index.html:12776-12784) makes the door part of the contract.
- **Doors as the empty state:** UpcomingRoundsSection.swift:41-54 renders "Put a round on the calendar →" instead of "No rounds"; `LeaguelessDoors` (Start a league · I have an invite code · Start an event · Run it back) with "Run it back" as the renewal verb (LeaguelessDoors.swift:66-88).
- **Loading is shape, not spinner:** Home skeleton (HomeView.swift:118-119, :192-194), `BoardSkeleton` (BoardRows.swift:191-192), You's `.redacted(.placeholder)` (YouScreen.swift:167, :190) with the Y-17 rule "never 'nothing yet' while the reads are still out"; "A failed read is not an empty feed" when rounds are cached (HomeView.swift:279-287).
- **Partial failure says so and offers Retry:** "Some of your card did not load. Retry" (YouScreen.swift:230-232); LifetimeTiles "Did not load" subs (YouSections.swift:100-105); TourCardSheet.swift:44-45; the room/event/draft error cards with `Try again`.
- **Structure is hidden over an empty room:** D178's gate on "Your seasons" (YouScreen.swift:175-177), rivalries hidden when empty (RivalriesSection.swift:16), invites/requests hidden when empty.
- **Search-miss is distinguished from list-empty (S3-03):** PeoplePickerSheet.swift:76-82; PeopleScreen.swift:66-73 chooses its sentence by whether an invite link actually exists (D178).
- **Voice where it lands:** "The cookout isn't going to bet itself." (PotPane.swift:134) · "No cards yet — first one takes the clubhouse." (EventMath.swift:386) · "Just you so far — tag your group." / "No messages yet — kick it off." (ScheduledRoundSheet.swift:67, :88) · "The cup's been lifted. Run it back." (HomeView.swift:980) · the occasion cards ("Azaleas are blooming somewhere.", HomeStream.swift:203).
- **The digest** ("Since you were here" / "Quiet since your last visit" resurfacing the best recent round, HomeDigest.swift:77-99) is the living-feed instinct the brief asks for; a quiet day is given a thing, not an apology.
- **Push discipline is largely right on paper:** never on launch, three moments, 14-day snooze, swipe = Not now (PushAskPolicy.swift; PushAsk.swift:111); the explainer's copy ("Nothing else. No streaks, no noise, no badge you didn't earn.", PushAsk.swift:88-90) is brand canon in three lines; badge = actionable only and seen clears it (PushBadge.swift; D179); lock-screen `Accept/Decline`, `I'm in/Can't` (PushPayload.swift:137-143) with a failure line in voice (PushActions.swift:28); author never pinged on league posts; mutes honoured; `notify_rounds`/`notify_chat` server-enforced; `headline()` puts the result in the bold line and skips an empty body rather than sending filler (push/index.ts:58-84, :522-531); BadDeviceToken is retried on the other host, not pruned (:274-313).
- **The Ryder taunt is the brief's notification, already built:** "Galen posted — +2.3 to beat · 3 days left" (nudge_payloads.sql:143-152) — personal, forward-looking, a number to beat, a clock. Generalise it.
- **The RSVP push is the brief's "Saturday" shape:** "Sat Sep 5 · Encanto GC — in or out?" answered from the lock screen.
- **Email copy is finished work:** the recap's subject carries the margin ("The Cup goes to Galen by 12 — PIGL"), "Your cut of the pot: $180 · Whoever collected it sends it on.", the ledger line verbatim; the cancellation's refund-first subject and "Your rounds stay on your card — all of them." (season-email/index.ts:60-125, :158-179, :209-211, :250-251).
- **The `unconfirmed` honesty line** (PushService.swift:35-39; CardAndSettingsScreen.swift:501-503) — the switch does not lie about the server.
- **Orientation is gated on evidence** (OrientationScreen.swift:77-85): a golfer with a league, a round or an invite never sees it.

---

## Section 5 · What could not be determined by reading

1. **Whether the `APNS_*` secrets are set in prod** — function secrets and logs are not readable here; the `[apns]` branch may be dormant (push/index.ts:244). Only a real send proves it.
2. **Whether the single `push_prompt_shown` was a real phone or the DEBUG `-cs_dev_push_prompt` hatch** (PushAsk.swift:40-42, :50) — 1 shown with 0 accepted/declined suggests the simulator.
3. **Whether `BREVO_API_KEY` is set** — the friend-request email (N15) and both season emails are no-ops without it (push/index.ts:334; season-email/index.ts:129).
4. **The Supabase Auth OTP email's actual template and subject** — `config.toml` shows the default; the dashboard may differ. The door's copy assumes "the newest Cup Season email".
5. **On-device rendering:** thread grouping under `you` vs league ids, how three "put you on the tee sheet" titles stack, whether `willPresent` banners on the routed screen, and the Live Activity's lock-screen card (CSRoundActivity.swift) — none was run.
6. **Whether the leagueless Home hero carries a CTA of its own** — read as `line`/`foots` only (HomeView.swift:945-1001); the card body was not fully read.
7. **Whether a `notify_system` control exists anywhere** — grep found only the RPC and the model (Rpc.swift:1768; LeagueRoomModel.swift:31-35).
8. **The Board's exact rendering after a failed load** (C15) — read as toast + no synthetic row; the list's appearance is inferred.
9. **Whether the clash RESULT is ever posted/pushed** — the opening ("The clash this week: …") is a system post in prod; the settlement's surface was not traced.
10. **Whether A-11's web "Invited · Review" tile variant replaced "None yet" in any state** — :11044 is the no-league default at tip.
11. **What the App Store build number's `minIOSBuild` is set to in prod** (`MustUpdateView` reachability) — not queried.
