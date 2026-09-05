# Reader "first-run" — the first-run experience on the phone, and its web twin

Repo `/Users/fischbeck3/cup-season` at tip `3bba87e` (main, clean). Read-only. Date 2026-09-04. Finding prefix **FR-**.

## How to read this

- **SAW** = read in code at tip, or seen in a screenshot. **INFER** = concluded from code paths without running the app. Every finding says which.
- **The eleven screenshots at `docs/audit/signup-walk-2026-08-31/` are the WEB PWA, not the phone.** Evidence: the door footer reads `v23 · __CS_VERSION__` (the web's `#obCaption`, `index.html:2914`; the phone's door footer reads `v1 · build N`, `DoorView.swift:193`); the golfer card is one long page with Home course / City fields (`index.html:2817–2852`; the phone's card is three steps and has no city/home-course field, `CardGateView.swift:54–58,141`); shot 7 is the D151 crew step, which exists only on the web (`index.html:2859–2878`); shot 8's three tiles LEAGUE/NEXT/BOARD are `renderHomeTiles` (`index.html:11044,11063,11069`). **No screenshot of the phone's first run exists** in the repo or the scratchpad (`scratchpad/ux/shots/` is absent). The phone is described from code.
- The five questions of the brief are referenced as **Q1** what is happening · **Q2** why it matters to me · **Q3** what I can do right now · **Q4** who I am competing with · **Q5** what happens next.
- Prod numbers were read with `supabase db query --linked` (read-only) on 2026-09-04 and are quoted where they matter.

### The answer to the brief's direct question

> After the card and the orientation, what does a brand-new golfer with no friends and no league actually see, and what is the ONE thing the screen asks them to do?

**Phone (SAW code, INFER paint).** They see a notification-permission sheet ("Hear it when it happens · YOUR CARD IS IN") rising over their very first Home, because the ask was queued at card save and drains the moment the tab shell exists (`CardGateView.swift:238`, `MainTabView.swift:330–335,444–447`). Under it, Home is: the wordmark with today's date; a hero card reading **"Your card · 0 of 3 · Three rounds and your index goes live. Nothing else needed."** that is **not tappable and has no button** (`HomeView.swift:801–813` makes the hero a button only with a membership; the "See the table →" foot is likewise gated, `:839–842`); a section head **"Around your buddies · YOUR BUDDIES ↗"**; the sentence **"No rounds from your buddies yet. Post one, or add some buddies."** in which only *add some buddies.* is a link (`HomeView.swift:123–124`); and **"Coming up · THE CALENDAR ↗ · Put a round on the calendar →"** (`UpcomingRoundsSection.swift:33–56`). No lead card (`HomeLead.choose` returns nil with no clash/pulse/standing/milestone, `HomeLead.swift:159–184`), no digest (first visit → nil, `HomeDigest.swift:76`), no Up Next chips (`UpNext.chips` yields nothing without memberships/watch/invites, `ScheduleModels.swift:377–410`), no occasion card on Sep 4 (no window open, `HomeStream.swift:201–229`). **The screen asks nothing.** The action the design intends — post a round — has no door on the page; it lives in the ⊕ tab, where it is the second, quiet row under the ember hero "Play now — score the group" (`PostCoverView.swift:95–102`).

**Web (SAW shot 8 + code).** The same hero **with** a "Post your first round" button (`index.html:11446–11450`), a row of three doors *Join a league · Start a league · Start an event* above it, and three tiles of absences below it (LEAGUE · None yet / NEXT · Open / BOARD · — LEAGUE ONLY). The web asks one thing (post), but frames it under three doors and over three empties.

---

## Section 1 — The map

### 1a. Phone (`apps/ios`)

| # | Screen / sheet / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|---|
| P1 | **Boot · restoring** (`BootingView`, `RootView.swift:26–27`) | cold launch with a session | spinner + eyebrow "Restoring your session" | none | → P8 or P3 |
| P2 | **Door · the Forge** (`ForgeView.swift`, `DoorView.swift:53–59,77–87`) | first launch on a device (once, `cs_forge`) | 2.2 s animation: tracers, the wordmark searing in, the mark; then "Rally your crew. Post real rounds." / "Take the cup." (`ForgeView.swift:161–162`) | none; the email field rises at handoff (~1.8 s) and takes focus | → P3 |
| P3 | **Door · email stage** (`DoorView.swift:91–114`) | rest frame of P2; sign-out; every later launch | eyebrow "Email", field `you@example.com`, button **"Continue with email"**, footnote "One code, no password. Codes come from the newest email.", legal line, `v1 · build N` | Continue with email (or keyboard Go) | → P4; Apple button only if `app_flags.ios.apple_sign_in` (closed in prod, see §5) |
| P4 | **Door · code stage** (`DoorView.swift:116–159`) | after send | eyebrow "The 8 digits", one field (numberPad, `oneTimeCode`), **"Verify"**, "Resend in 30s" / "Resend the code", "Change email", note "Sent to x. Type the 8 digits from the newest email." | typing 8 digits auto-verifies (`:134–138`) | → P5 (new) / P8 (returning); spam hint after 20 s (`:334–341`) |
| P4b | Door · password stage (`:161–180`) | reviewer address only | SecureField "REVIEW PASSWORD" | Sign in | → P8 |
| P4c | **Guest pencil** (`GuestPencilScreen`, `RootView.swift:29–30`, `LiveRoundHost.swift:177–187`) | `/?claim=TOKEN` while signed out | "Your scorecard · NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it." | "Enter your email to keep it" | → P3 with the claim pending |
| P5 | **Card gate · step 1 of 3** (`CardGateView.swift:92–114`) | first sign-in (`needsCard`: marker or handle empty, `Models.swift:246–249`) | 3-segment rail, eyebrow "Your card", **"Who's on the card?"**, "Just a name and a marker to start — this card follows you into every league.", Name "First and last", @handle (auto-derived), "3–20 letters, numbers or _. It changes once every 60 days.", live "@x is available ✓" | **Next** | → P6 |
| P6 | **Card gate · step 2** (`:138–167`) | Next | **"Pick your ball marker"**, "It's your face here until you add a photo — and your stamp on every round after.", 14 named tiles (THE SAGUARO … THE THISTLE), no default; footnote "City and home course live on your card — add them any time from the You tab." | tap a marker, **Next** | → P7; Back |
| P7 | **Card gate · step 3** (`:169–178`) | Next | **"Know your number?"**, "Optional. Your index builds itself at 3 posted rounds; a starter only helps before then.", "Starter index e.g. 12.4", "GHIN (a reference on your card — we never resell or verify it)", footnote about the USGA record | **Save my card** (`set_handle` then `set_profile`, `:232–234`) | → P8 (via `store.reload()`); queues the push ask (`:238`) |
| P8 | **Orientation** (`OrientationScreen.swift`) | first arrival in `.ready` with no membership, no event, no round, and no pending join/claim (`OrientedFlag.take`, `:85–91`); once per device (`cs_oriented`) | **"Four places. / Two ways to play." · "Thirty seconds, then you're in."**; four rows Home / Clubhouse / Post / You with subs; two cards "THE LONG GAME · A league · Months. Every round counts toward a table." / "THE SHORT GAME · An event · A weekend or a few weeks. Its own little trophy."; fine "You can run both at once…"; **then the three league-less doors** (Y-15, `:138`) and their fine line; pinned foot **"Take me in"** + "Reopen this any time from You › ⚙ › How it works." | Take me in (pinned) | → P9; or Join sheet (P14) / wizard cover (P16) / event picker (P17) → each leaves via `leave(how)` (`:209–217`) |
| P9 | **Home · league-less, rung 7** (`HomeView.swift:41–157`; `HomeMode.of`, `Models.swift:305–310`) | Take me in; every later launch | header "Cup Season" + "THU · SEP 4" + `+` menu; hero "Your card · 0 of 3 · Three rounds and your index goes live. Nothing else needed."; "Around your buddies · YOUR BUDDIES ↗"; "No rounds from your buddies yet. Post one, or add some buddies."; "Coming up · THE CALENDAR ↗ · Put a round on the calendar →" | **none on the page** (see FR-01) | tabs; `+` menu (P10); links to People (P18) and Schedule (P19) |
| P9b | Home · league-less, rung 6 (≥3 rounds, no league) | later | hero "Your card · 12.4 · Established. Nobody's seen it yet — you haven't joined a league." (`HomeView.swift:952`) | none (no button) | as P9 |
| P10 | **Push prompt sheet** (`PushPromptSheet`, `PushAsk.swift:76–100`) | drains over first Home when nothing else is presented (`MainTabView.swift:330–335,444–447`) | "Hear it when it happens · YOUR CARD IS IN"; three lines (board/duel/table; buddy request/tee time/invite; "Nothing else. No streaks, no noise, no badge you didn't earn.") | "Turn on notifications" → iOS system dialog | "Not now" (14-day snooze, `PushAskPolicy.swift:20`) |
| P11 | **`+` menu** (`HomeView.swift:178–190`) | header `+` (a11y "Start or join") | Start a league · Start an event · Join with a code · Your golf calendar · Find golfers | — | → P16 / P17 / P14 / P19 / P18 |
| P12 | **Clubhouse · league-less** (`ClubhouseView.swift:79–81,137–157`) | Clubhouse tab | title "Clubhouse"; three doors Join a league · Start a league · Start an event; fine "Post a round — it counts on your card. Leagues score it when you join one."; button "Add golfers" | none dominant | → P14 / P16 / P17 / P18 |
| P13 | **⊕ Post cover** (`PostCoverView.swift:85–116`) | ⊕ tab (presents, selection snaps back, `MainTabView.swift:336–339`) | "Golf · Play one live, post one you just finished, or plan the next"; ember hero **"Play now — score the group"**; quiet rows "Post a round — after you play · Gross + tee, 20 seconds · counts on your card and in every league" and "Plan a tee time — before" | Play now (hero) | Close; → composer (P13b) / tee sheet / declare sheet |
| P13b | **Composer "Post a round"** (`PostRoundScreen.swift`) | Post a round row; every "post" CTA elsewhere lands here directly (`postOnComposer`) | "Course & tees" search, "Recent courses" (empty), "Rating / slope — / — · edit", "Your card" front/back gross, date, "How points work" (collapsed bands + counting line), **"Post round"** | Post round | → ceremony / done |
| P14 | **Join a league sheet** (`JoinLeagueFlow.swift:29–64`) | doors, `+` menu, or a pending `/?join=` after the card (`RootView.swift:43–48`) | "Join a league · I HAVE A LEAGUE CODE", code field (or the preset code), "You're invited to X." once validated, **Join** | Join → `league_by_code` → covenant if staked → `join_league` | Cancel; → P14b / P14c |
| P14b | Covenant sheet (`:125–158`) | a league with a buy-in | "Before you join X · THE FINE PRINT, UP FRONT" rows BUY-IN / PRESET / PARTICIPATION FLOOR / FINISH, pot line | "Join — I'm in for $N" | "Not now" (sheet closes; code stays in P14 only while it is open) |
| P14c | Welcome sheet (`:173–215`) | after join | "Welcome to X · THREE THINGS TO KNOW", stake line, three rules, "How scoring works →", "Who else plays with you?", "Share the invite link" | Share the invite link | dismiss → `onJoined` → Clubhouse tab (`MainTabView.swift:475`) + push ask `.leagueJoined` |
| P15 | Scoring help sheet (`GuideSheets.swift:24–53`) | from P14c or Card & settings | "How scoring works · HANDICAPS · CUP POINTS · THE MONEY" | — | dismiss |
| P16 | **Wizard · name sheet** (`WizardScreen.swift:70–84`; copy `WizardState.swift:375–378`) | Start a league | "Name your league · The banner everything hangs under", field "The Big Slice, The Sunday Cup, Dew Sweepers…", "You can rename it any time before the bylaws lock.", **"Start the league"**, Cancel | Start the league (mints a league row) | → the three-step wizard (another reader's area) |
| P17 | **Event picker** (`EventPickerSheet.swift:21–48`) | Start an event | "Start an event · Short form · its own little trophy"; "The Ryder … LIVE", "Bracket … SOON" (toast "Bracket isn't built yet"), fine "Every event mints a trophy for your display case." | The Ryder | → Ryder setup (`RyderSetupSheet.swift:79–113`: name, two team names, "Search the app or tap a buddy", "Create the event") |
| P18 | **Your buddies** (`PeopleScreen.swift:26–58`) | YOUR BUDDIES ↗, "add some buddies.", Add golfers, Find golfers | requests (none), "Find golfers" search "Search by name or @handle", invite-link row (only if a league with a code exists), buddies, findable-by | search | back |
| P19 | Schedule (`ScheduleScreen`) | THE CALENDAR ↗ / Put a round on the calendar | the calendar | declare a round | back |
| P20 | **You › ⚙ Card & settings › How it works** (`CardAndSettingsScreen.swift:7–8,395–396`; rows `GuideCopy.swift:49–55`) | You tab → gear → Settings pane | five rows: The four places · Leagues vs events · Posting a round · Buddies, invites and claims · How scoring works | open a sheet | dismiss |
| P21 | Must update / Boot failed (`RootView.swift:138–165`) | `min_build` gate (0 in prod) / bootstrap failure | "Update Cup Season …" / "Boot stalled" + Try again + Sign out | Try again | — |

### 1b. Web twin (`index.html`)

| # | Screen / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|---|
| W1 | **Door** (`#obDoor`, `index.html:2790–2816`; shot 1) | cupseason.app signed out | seared wordmark, "Rally your crew. / Post real rounds. / *Take the cup.*", **"Continue with email"**, **"I have a league code"**, Terms line, caption `v23 · <sha>` (`:2914`) | Continue with email | → W2; code box → W2 with the code armed (`:17739–17755`) |
| W2 | Email box → code box (shots 2–3) | Continue / Go | "you@email.com · Go"; then "CODE FROM EMAIL · Verify", status "Sent to x. Type the sign-in code from the newest email.", "Resend code (27s)" | Go / Verify | → W3 (new) / app (returning) |
| W3 | **Golfer card** (`#obProfile`, `:2817–2852`; shots 4–5) | first sign-in | "✓ SIGNED IN · Set up your *golfer card.* · Just a name and a marker to start — this card follows you into every league."; Name on the card; Your handle — how buddies find you (+ 60-day policy line); Home course · optional; City · optional; Handicap index · optional (+ explainer); "+ Add your GHIN number"; Ball marker grid (14); **"Save my card"** | Save my card (`:14940–14987`) | toast "Card saved. Welcome, X." → W4 or W5 |
| W4 | **Orientation** (`#obOrient`, `:2891–2913`; shot 6) | first card save on this device (`cs_oriented`, set on show `:14992–14995`) | "Four places. / *Two ways to play.*", "Thirty seconds, then you're in.", 2×2 grid of places, two "ways" cards, fine line, **"Take me in"**, "Reopen this any time from You › ⚙︎ › How it works." | Take me in | → W5 (`continueAfterCard`, `:15006–15014`) |
| W5 | **Crew step** (`#obCrew`, `:2859–2878`; shot 7) | cold arrivals only, once (`cs_crew`); never with `cs_code`/`cs_claim` | "✓ CARD SAVED · Who are you *playing with?* · Cup Season is a game you play with people you know. Bring them now and your first round already counts for something."; "Got a league code?" box + Join; "A buddy texted you one? This is where it goes."; **"Find your buddies"**; "Start a league instead"; "I'll do this later" | Join (code) → covenant → join; Find your buddies → people picker | every button → `leaveCrewStep(how)` (`:15015–15043`) → W6 |
| W6 | **Home · league-less** (shot 8; `renderHomeStart` `:11086–11146`, `renderHomeHero` `:11439–11475`, `renderHomeTiles` `:11036–11075`) | after W5 / every visit | doors Join a league · Start a league · Start an event; fine "Post a round — it counts on your card. Leagues score it when you join one."; hero "YOUR CARD · Three rounds and your index goes live. *Nothing else needed.* · INDEX 0 OF 3 · **Post your first round**"; tiles LEAGUE None yet / NEXT Open / BOARD —; "Around your buddies" | Post your first round → `#view-record` | tabs |
| W6b | Home rung 6 / rung 5 (`:11453–11475`) | ≥3 rounds / ≥1 buddy | "Established. *Nobody's seen it* — you haven't added a buddy yet." + **Find your buddies**; then "Four makes a league. N more and *your rounds start counting for something.*" + Start a league at 4 | as shown | — |
| W7 | **Clubhouse · league-less** (`#hubLeagueless`, `:3608–3619`) | Clubhouse tab | eyebrow "League play — cup season", **"Start a league"**, "I have a league code" + box, "Add golfers", "Sign out", caption "No code? Any league member can share an invite link." | Start a league | — |
| W8 | **Invite-link door** (`/?join=CODE`, `:17749–17753`, `:20455`) | link, signed out | the door with the email box open and the sentence "Enter your email — X is one step away; you'll review it before you're in." | Go | → code → card → (orientation skipped, `:15008–15010`) → covenant (`resumeAfterProfile` `:20092–20112`) → league |
| W9 | `#obWelcome` "You're *in.*" (`:2879–2886`) | — | — | — | appears unreachable at tip (hidden in `showProfileGate`, never shown by `showWelcome`); see §5 |

---

## Section 2 — The flows

### Flow A · Cold install → first useful Home (phone, no invite)

- **User goal.** "I downloaded this because a friend mentioned it / I saw a post. Let me see what it is and add a round." Time-to-aha should be seconds.
- **Screens and taps (INFER from code; Mail QuickType autofill assumed to work).** Surfaces: Forge/email (P2–P3) → code (P4) → card 1 (P5) → card 2 (P6) → card 3 (P7) → orientation (P8) → Home (P9) → push sheet (P10) [→ iOS permission dialog]. **Eight surfaces before Home is usable, nine if they accept notifications.** Minimum taps: Continue (1) + QuickType code (1) + Next (1) + marker (1) + Next (1) + Save my card (1) + Take me in (1) + Not now (1) = **8 taps**, plus typing an email and a name, plus one app switch to Mail/notification. If autofill does not fire: +8 digits typed. The Forge adds ~1.8 s before the field is usable on the very first launch (`ForgeTimeline.handoff`).
- **What the brief asked for vs what is asked.** Brief: handicap · who you play with · what golf you play → useful home. Current: email · name · @handle · ball marker (required, 14 choices) · starter index + GHIN (optional but a mandatory screen) · an explainer · a permission. **"Who you play with" is never asked on the phone; "what golf you play" is never asked on either client.** Handicap is asked, in insider terms ("Starter index", "GHIN", "USGA record").
- **Current friction.** Three card screens where one question would do; a forced marker choice among golf-course in-jokes; a 60-day handle policy at the moment of signup; the orientation explaining four tabs the user will see in a second; a permission sheet on first paint.
- **Unnecessary complexity.** The card's step 3 exists only for two optional fields. The orientation carries both an explainer and three doors (Y-15), so it is the busiest screen of the walk, and its pinned "Take me in" competes with Join/Start/Start above it.
- **Confusing terminology (exact strings).** "this card follows you into every league." (P5 sub) · "It changes once every 60 days." (P5) · "Pick your ball marker" / "THE POSTAGE STAMP" / "NO. 2" (P6) · "Know your number?" / "Starter index" / "GHIN (a reference on your card — we never resell or verify it)" / "Links your USGA record — that's identity, not your number." (P7) · "Four places. Two ways to play." / "Clubhouse · One league: table, board, pot" / "THE LONG GAME · A league · Months. Every round counts toward a table." / "An event stands alone, or attaches to a league." (P8) · "0 of 3 · Three rounds and your index goes live." (P9) · "A round lands on the board. A duel is closing. The table moves." (P10).
- **Dead ends.** P9's hero: a statement with no door. P9's "Post one," is not a link. The push sheet's "Turn on notifications" for someone with nothing to be notified about.
- **Redundant actions.** Orientation's doors duplicate the `+` menu and the league-less Clubhouse; the orientation's places list duplicates the tab bar the user is about to see.
- **Missing feedback.** After "Save my card" there is no "welcome, NAME" beat on the phone (the web toasts "Card saved. Welcome, X." `:14977`); the next thing seen is a teaching screen. After "Take me in" the reward is a permission sheet.
- **Opportunities for delight.** The Forge is genuinely good; the moment after "Save my card" wants a credential reveal ("Here's your card — now put a round on it"). The marker grid could become "pick your home course's famous hole" with a picture. The first Home could open the composer directly with "Your first round goes here."

### Flow B · Cold signup (web)

- **Surfaces.** Door (W1) → email (W2) → code (W2) → card (W3, one page, 7 fields + grid) → orientation (W4) → crew step (W5) → Home (W6). **Seven surfaces, 7 taps** (Continue, Go, Verify, marker, Save my card, Take me in, I'll do this later) + email, code and name typed; the install nudge follows 3.4 s later (`:19883`).
- **Friction / complexity.** Same explainer; then a genuinely good question (W5) — but it arrives as the *seventh* screen, after the model has been explained, and its instrumentation is dead (FR-09). Two competing "join with a code" moments (door W1 and crew W5) and a third on the Clubhouse (W7).
- **Terminology.** As Flow A plus "Set up your *golfer card.*", "Your handle — how buddies find you", "Pick it now — … and your leagues are told when it does." (`:2828`).
- **Dead ends.** The tiles LEAGUE None yet / BOARD — LEAGUE ONLY are disabled buttons of absence (`:11069`, `disabled` at `:11075`).
- **Missing feedback.** `crew_step_shown/done` and `covenant_declined` never reach the database (FR-09), so nobody knows which door a stranger takes.
- **Delight.** "Who are you playing with? … Bring them now and your first round already counts for something." is the best sentence in the whole walk — it should be the *first* screen after the card, on both clients.

### Flow C · Invite link on the phone (`/?join=CODE`)

- **Goal.** "My buddy sent me a link. Get me into his league."
- **Signed out (INFER).** Universal Link → `onOpenURL` stores the code (`CupSeasonApp.swift:29–35`) → `RootView` shows the plain `DoorView` (`RootView.swift:28–33`). **The door does not mention the invite, the league or the friend** — `DoorView.swift` never reads `JoinIntent`. The web's door says "Enter your email — X is one step away; you'll review it before you're in." (`index.html:17751–17753`). After code + card, `OrientedFlag.take` sees the pending join and skips the orientation (`OrientationScreen.swift:88–89`, D116 §3 — good); `MainTabView.onAppear` reads and **clears** the code, then presents `JoinLeagueFlow(code:)` (`RootView.swift:43–48`), which auto-runs `go()` (`JoinLeagueFlow.swift:49`): "You're invited to X." → covenant if staked → join → welcome → Clubhouse tab.
- **Signed in.** Same from `store.reload()` → `MainTabView.onAppear` fires only if the tab shell re-appears; otherwise the pending join waits for the next appear (see §5, race untested).
- **Dead end.** Covenant "Not now" → `covenant = nil`, the join sheet stays with the code shown and a Join button; **Cancel loses the invite** — `JoinIntent.clear()` already ran at `RootView.swift:43`, and D116 §2's "Invited · X · REVIEW" state exists on neither client (no `cs_invite_declined` anywhere; grep). The joiner must re-open the link or retype the code.
- **Terminology.** "I HAVE A LEAGUE CODE" (sheet sub, `JoinLeagueFlow.swift:33`); "No league with that code — check with your Pro" (`:96`) to someone who has no Pro; covenant rows "PRESET Standard", "PARTICIPATION FLOOR", "FINISH" (`:134–138`); welcome "THREE THINGS TO KNOW" over four bold items (`:181–198`).
- **Delight kept.** The covenant before the join on every phone path; the welcome's three rules; "Share the invite link" on the welcome (`:200–206`).

### Flow D · Invite link on the web

- Door names the league (W8) → code → card (crew step skipped, `:15008–15010`) → covenant in `resumeAfterProfile` (`:20097`) → league. "Not now" keeps the code (D116 §2 half-built: the code stays, `:20105–20109`, the toast says "the invite is still here when you're ready", but no "Invited · REVIEW" card renders — grep `cs_invite_declined` finds nothing). `covenant_declined` telemetry is swallowed (FR-09).

### Flow E · A texted CODE, no link

- **Phone.** No code door on the sign-in screen (Flow A's P3 has only email). The first place a code can go is the orientation's "Join a league" door (P8) or, if the orientation was already spent on this device, the league-less Clubhouse / `+` menu. D151 named this exact gap for the web ("the 'I have a league code' door exists only on the SIGNED-OUT splash") and the web fixed it with the crew step; **the phone has it inverted** — the door has no code entry, and the code entry appears only after signup.
- **Web.** Door → "I have a league code" validates via `league_by_code` before the email round-trip (`:17745–17748`) — good — arms `cs_code`, then the invite path.

### Flow F · Guest claim link (phone, signed out)

- `/?claim=` → `GuestPencilScreen` "Your scorecard · NAME — 84 at COURSE … Enter your email to keep it." → door → card with the gold line "Saving your card attaches the round you're claiming." (`CardGateView.swift:50–52`) → orientation skipped (`OrientedFlag.take`) → `LiveClaimAfterAuth.run` toasts the result (`RootView.swift:45`). This is the one first-run path on the phone that starts from a real object and a real friend; it is the model for the rest.

### Flow G · The smallest useful action — "add my round" from a league-less Home

- **Phone.** Home offers no door (FR-01). Path: ⊕ tab (1) → cover (P13) → "Post a round — after you play" row (2) → composer: course search (type, pick), tee/rating-slope (auto from tee, else "— / — · edit"), front + back gross, date defaults today → "Post round" (3). **Three taps to reach the form, then ~3 fields.** The cover's ember hero is "Play now — score the group" — for a golfer alone after a round it is the wrong loud door (the file's own header says "Post is the 90% case", `PostCoverView.swift:5–7`; D110's addendum made the cover, not the composer, the ⊕'s landing, `:30–35`).
- **The form's copy for a league-less poster.** "How points work" (collapsed) ends with **"Every posted round scores. Your best few each month count toward your squad — a better round always replaces your lowest, in real time."** (`PostRoundScreen.swift:328–330`) — a squad the golfer does not have; same class as D185 §1 on the web.
- **Web.** Hero button "Post your first round" → `switchView('record')` (`:11449–11450`). One tap.

### Flow H · "Who do I play with?" — the buddies path

- **Phone.** First appearance: a footnote link "add some buddies." under an empty feed (P9), and "YOUR BUDDIES ↗" as a section head door; "Find golfers" is inside the `+` menu behind an icon labelled "Start or join"; "Add golfers" on the league-less Clubhouse. All lead to P18, a search box. There is no moment that *asks* the question; there is no contacts/phone-number path (M-002 still open — `PeopleScreen` search is by name/@handle only, and the invite-link row renders only if a league with a code exists, `PeopleScreen.swift:112–120`), so a stranger with no buddies on the app finds nobody and has no link to send.
- **Web.** The crew step asks it (W5), the rung-6 hero asks it again ("Find your buddies"), rung 5 counts toward four ("Four makes a league").

### Flow I · "Start a league" / "Start an event" from nothing

- **Start a league** → name sheet → "Start the league" **mints a league row on a name** (`WizardScreen.swift:68–69` comment, `:88–92`), before anyone is invited — the mechanism behind "six golfers … still sitting in a league of one" (D151). No intent step ("play with friends / run a season / this weekend / beat Jake / money on it"), no Who/When/What-for before the row. Copy: "The banner everything hangs under", "before the bylaws lock" — bylaws at the first screen.
- **Start an event** → picker shows a not-built option ("Bracket · SOON", toast on tap, `EventPickerSheet.swift:27`) → Ryder setup asks an event name, two team names, "Search the app or tap a buddy", and warns "The Ryder starts on a Sunday" — a golfer with zero buddies cannot complete it.

### Flow J · Reopening the orientation

- Phone: You → ⚙ → **Settings pane** → "How it works" (five rows) — the exit line "Reopen this any time from You › ⚙ › How it works." is now accurate on both clients (D185 §3 fixed the web's stale "You › How it works"); the phone draws the gear as an SF Symbol (`OrientationScreen.swift:60–68`). Three levels deep for a first-timer who has never seen You; acceptable as a reference, not as onboarding.

---

## Section 3 — Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. Each names the question(s) damaged.

### FR-01 · P1 · The phone's league-less Home asks nothing — the hero is a fact with no door
- **Observed (SAW code).** `HomeHero` is a `Button` only when `mode.membership?.league_id` exists (`HomeView.swift:801–813`); the "See the table →" foot is gated the same way (`:839–842`). For `.leagueless(rung: 7)` the card renders eyebrow "Your card", figure "0 of 3", line "Three rounds and your index goes live. Nothing else needed." (`:875,895,951`) and nothing else. The empty-feed sentence's only link is *add some buddies.* (`:123–124`). The web's identical hero carries "Post your first round" (`index.html:11449`). Prod: `home_hero_state rung7` has painted 12 times; `home_hero_tap datahpost` has fired twice ever (web; last 2026-08-08).
- **Damages.** Q3 (what can I do now), Q5.
- **Fix.** Make the league-less hero one door to the composer with the button in the card ("Post your first round" / "Post a round"), and make "Post one" a link. Better: on rung 7 open the composer as the first Home, with the hero as its header.

### FR-02 · P1 · The phone never asks "who do you play with?"
- **Observed (SAW).** The D151 crew step is web-only (`index.html:2859–2878`). The phone's orientation carries Join · Start a league · Start an event (`OrientationScreen.swift:137–138`, `LeaguelessDoors.swift:27–31`) and **no buddies door**; the phone's Home has no rung 5 at all (`HomeMode.of` returns only 7 or 6, `Models.swift:308–309`), so "Find your buddies" / "Four makes a league" never render on the phone (web `:11453–11475`). D185's record says "iOS keeps its own gap — no orientation and no crew step — which is P2" (`decision-log.md:5102–5120`, the CONFLICT line); half of that is stale (the orientation exists), the other half is the finding. Prod: 11 of 29 carded golfers have no league and 10 of those have no round.
- **Damages.** Q4 (who am I competing with), Q2.
- **Fix.** Ask it on the phone, once, before the app — with the web's sentence — and make it the intent step of creation ("play with friends" first). A phone-contacts / share-sheet path (not only @handle search) belongs here.

### FR-03 · P1 · The orientation is an explainer slide that teaches the database, not the game
- **Observed (SAW).** "Four places. Two ways to play." · rows naming the four tabs · "THE LONG GAME · A league · Months. Every round counts toward a table." · "THE SHORT GAME · An event · A weekend or a few weeks. Its own little trophy." · "You can run both at once. An event stands alone, or attaches to a league." (`OrientationScreen.swift:46–58`; `index.html:2891–2913`; shot 6). It teaches *league vs event* and *table / board / pot* — the exact vocabulary the brief says a first-timer must not need — to a golfer who has no league, no event, no table, no board and no pot. D82 chose this ("one tap of friction, spent exactly once", `decision-log.md:2856–2873`); the brief's "no explainer slides" is a higher-level ruling and conflicts with it.
- **Damages.** Q1, Q2 (it answers "what is this app's structure", not "what is happening to me").
- **Fix.** Retire the screen; replace with the crew question (FR-02) and let the doors teach themselves (D82's own principle "depth stays AT the doors"). Keep the content under How it works.

### FR-04 · P1 · The door never says what the product is (D117 §1 proposed, unbuilt on both clients)
- **Observed (SAW).** Phone door: wordmark + "Rally your crew. Post real rounds." / "Take the cup." + one button (`ForgeView.swift:161–162`, `DoorView.swift:102`). Web: the same three lines (`index.html:2794`). The one-breath definition lives only in the meta description; M-143 ("8/8 could not define the product's own name") is still open; D117's line and "How it works" link are logged PROPOSED (`decision-log.md:4202–4212`).
- **Damages.** Q1.
- **Fix.** One sentence under the slogan, verbatim from the vision doc, and a signed-out "How it works" one tap away.

### FR-05 · P1 · The notification ask lands on the first Home paint, speaking of boards, duels and tables the golfer does not have
- **Observed (SAW).** `PushAsk.shared.request(.cardSaved)` at `CardGateView.swift:238`; drains in `MainTabView` the moment nothing is presented (`:330–335,444–447`) — i.e. right after "Take me in". Sheet copy: "Hear it when it happens · YOUR CARD IS IN · A round lands on the board. A duel is closing. The table moves. · A buddy request, a tee time, an invite — answered from the lock screen. · Nothing else. No streaks, no noise, no badge you didn't earn." (`PushAsk.swift:76–90`). Policy says "after one of three moments" (`PushAskPolicy.swift:1–6`); for a league-less golfer there is nothing any of those lines can deliver.
- **Damages.** Q5 (anticipation with nothing to anticipate), and the brief's "notifications create anticipation, never manufacture engagement".
- **Fix.** For a golfer with no league and no buddies, defer the ask to `.firstRound` / `.leagueJoined` / a buddy accepted; never over the first Home.

### FR-06 · P1 · The composer tells a league-less first poster their rounds "count toward your squad"
- **Observed (SAW).** `countingLine`: "Every posted round scores. Your best few each month count toward your squad — a better round always replaces your lowest, in real time." when `model.membership` is nil (`PostRoundScreen.swift:328–330`); the bands section renders unconditionally (`:97`). D185 §1 removed the same false squad sentence from the web's Home; the phone's composer still carries one.
- **Damages.** Q2 (why it matters — the sentence is false for them).
- **Fix.** With no membership: "Every posted round counts on your card. Join a league and it scores there too."

### FR-07 · P1 · A friend's invite link opens a door that does not mention the friend or the league (phone)
- **Observed (SAW).** `DoorView.swift` has no reference to `JoinIntent`; `RootView.swift:28–33` renders the plain door for any signed-out state except a claim. The web's door says "Enter your email — X is one step away; you'll review it before you're in." (`index.html:17751–17753`). The phone's first sentence to an invited stranger is the slogan.
- **Damages.** Q1, Q2, Q4 (the one thing they know — a friend asked — is not reflected back).
- **Fix.** Read `JoinIntent.pending()` on the door and render "You're invited to X · enter your email to review it."

### FR-08 · P1 · Declining or cancelling the covenant loses the invite on the phone (D116 §2 unbuilt on both clients)
- **Observed (SAW).** `JoinIntent.clear()` runs when the sheet is scheduled (`RootView.swift:43`), before any join; covenant "Not now" only nils the covenant (`JoinLeagueFlow.swift:51`); Cancel dismisses with nothing kept; no `cs_invite_declined` / "Invited · REVIEW" state in either client (grep). TOP-2's "Not now loses the invite" is half-fixed on the web (code kept, `index.html:20105–20109`) and unfixed on the phone.
- **Damages.** Q5.
- **Fix.** Keep the code until Join is tapped; render a persistent "Invited · X · Review" card on Home and the doors.

### FR-09 · P1 · The web's crew-step and covenant-declined telemetry has never recorded — the D185 guard survives in `qaEvent`
- **Observed (SAW + prod).** `qaEvent` opens `if(state.demo || !window.sb) return;` (`index.html:6900`). `continueAfterCard` and `leaveCrewStep` call `qaEvent('crew_step_shown'|'crew_step_done')` (`:15012,15016`) and `resumeAfterProfile` calls `qaEvent('covenant_declined')` (`:20108`) — all before `showWelcome()` clears `state.demo` (`:19847`). D185 deleted this guard from `growthEvent` only (`decision-log.md:5110–5114`). `client_events` holds **zero** `crew_step_*` and zero `covenant_declined` rows, ever. (`orientation_shown` is emitted only by the phone: 5 rows, all 2026-09-02; `orientation_done`: 0.)
- **Damages.** Every activation / empty-state-engagement metric the brief names is unmeasurable for the one screen built to move them.
- **Fix.** Drop the `state.demo` clause from `qaEvent` as D185 did for `growthEvent`, or emit through `growthEvent`.

### FR-10 · P1 · Signup asks the wrong questions, in the wrong order, for the brief's target
- **Observed (SAW).** Asked: email · name · @handle · marker (required) · starter index · GHIN · then an explainer · then a permission. Not asked: who you play with (phone), what golf you play (both), home course / city (phone — deferred to You, `CardGateView.swift:141`, although D151 §2 moved them into the web card `index.html:2830–2835`; the two clients' cards now disagree). Eight surfaces before Home (Flow A).
- **Damages.** Q2, Q4; activation and time-to-aha.
- **Fix.** Card = name (+ Apple's name pre-filled) and "what do you usually shoot?"; crew question next; marker/handle/GHIN/index detail later, from the card itself. Land in the composer or a Home whose one door is the composer.

### FR-11 · P2 · The marker step is a forced choice among fourteen insider references
- **Observed (SAW).** "Pick your ball marker … THE SAGUARO · THE ISLAND · THE LIGHTHOUSE · THE LONE TREE · THE PEWS · THE DUNES · THE BEVERAGE · THE SHARK · THE AZALEA · THE JUG · THE WEE BRIDGE · NO. 2 · THE POSTAGE STAMP · THE THISTLE" (`CardGateView.swift:146–167`; `CSMarkers.all`; shot 5). Required, no default (`:218`, S1-01); M-139 ("14 tiles with no explanation") still open. D202 made the photo the card's owner and the marker its fallback — yet the fallback is the mandatory step and the photo is never offered here.
- **Damages.** Q2 (a decision with no stake for a stranger).
- **Fix.** Offer the photo first (one tap, camera/library), auto-assign a marker with "change it later"; keep the grid as delight, not as a gate.

### FR-12 · P2 · A required @handle and a 60-day policy at the moment of signup
- **Observed (SAW).** "@handle · 3–20 letters, numbers or _. It changes once every 60 days." (`CardGateView.swift:98–106`); web: "Pick it now — this is how buddies find you. It can be changed later, but only once every 60 days, and your leagues are told when it does." (`index.html:2828`). D151 §5 says the line "stops lying"; it now tells a stranger about league announcements before they have a league. M-140 (handle silently re-derived while typing) remains: `handle = Self.derive(new)` until touched (`:97`).
- **Damages.** Q2.
- **Fix.** Derive silently, show "@x — change it any time" and move the policy to the change flow (D159).

### FR-13 · P2 · "Know your number?" speaks in index / starter / GHIN / USGA
- **Observed (SAW).** "Know your number?" · "Optional. Your index builds itself at 3 posted rounds; a starter only helps before then." · "Starter index" · "GHIN (a reference on your card — we never resell or verify it)" · "Links your USGA record — that's identity, not your number. Your index still comes from your posted scores." (`CardGateView.swift:81,88,171–176`). The brief asks for the handicap question in the golfer's words; the casual golfer has no index and does not know "GHIN".
- **Damages.** Q2.
- **Fix.** "What do you usually shoot?" (a number or "no idea") → derive a starter; GHIN behind "I have a GHIN".

### FR-14 · P2 · The league-less Clubhouse is a menu, not a room
- **Observed (SAW).** Title "Clubhouse"; three doors; fine "Post a round — it counts on your card. Leagues score it when you join one."; "Add golfers" (`ClubhouseView.swift:137–157`). Web: "League play — cup season · Start a league · I have a league code · Add golfers · Sign out" (`index.html:3608–3619`) — the web's version still leads with Start (contradicting D151 §4, applied only to Home's doors `:11121–11128`) and carries a Sign out button in an empty room.
- **Damages.** Q1, Q5 (empty state as failure).
- **Fix.** Make the tab a story ("Nothing on the tee sheet yet — here's what a season looks like") or hide the tab until there is a room; on the web reorder to Join first and drop Sign out.

### FR-15 · P2 · The `+` menu hides "Find golfers" and "Join with a code" behind an icon labelled "Start or join"
- **Observed (SAW).** `HomeView.swift:178–190`: Start a league · Start an event · Join with a code · Your golf calendar · Find golfers, behind a 20-pt `+`. IOS-012 moved the doors out of the lane; for a league-less account the doors *are* the next move (D119 §4 / D136 kept them leading on the web, `index.html:11111–11128`).
- **Damages.** Q3.
- **Fix.** On a league-less Home, surface Join / Find your buddies in the lane; keep the `+` for members.

### FR-16 · P2 · Rung 6 taunts with no door on the phone
- **Observed (SAW).** After three rounds and no league: "Established. Nobody's seen it yet — you haven't joined a league." (`HomeView.swift:952`) with no button; the web's rung 6 offers "Find your buddies" (`index.html:11458–11461`).
- **Damages.** Q3, Q4.
- **Fix.** Button: "Show it to somebody → Find your buddies".

### FR-17 · P2 · The ⊕ cover leads with the group game; the smallest useful action is the quiet second row
- **Observed (SAW).** Ember hero "Play now — score the group" with a four-line sub about Match Play/Wolf/Skins; "Post a round — after you play · Gross + tee, 20 seconds …" is a quiet row (`PostCoverView.swift:95–102`). The file's own header calls posting "the 90% case" (`:5–7`). Three taps from a league-less Home to the form (Flow G).
- **Damages.** Q3; the brief's "Add My Round must be trivial".
- **Fix.** For an account with no live round and no buddies, ⊕ opens on the composer (the pre-D110 rule) with "Play now" as the header link it already has (`PostRoundScreen.swift:119–131`).

### FR-18 · P2 · The App Store listing speaks to the organizer and in mechanics; the first-timer's action is paragraph three
- **Observed (SAW).** Subtitle "Run your golf season"; promo "Season three of the founding league is under way. Draft the crew…"; description opens "Retire the spreadsheet. Run your golf season in your pocket. … Captains draft squads … The Pro sets the bylaws once — squads or solo, the handicap allowance, how many rounds count a month, the endgame — and locks them at first tee." (`docs/ios/app-store-listing.md:21,42–43,47–59`). "Post a round in under a minute" is §3 (`:61–66`); "The Ryder" is used undefined (`:74`). The shot-list leads with Standings and the wizard; the composer is shot 3 (`spec/appstore-launch-kit.md:104–113`). This is the *stranger's* first screen and it front-loads league / season / commissioner / bylaw / allowance / endgame.
- **Damages.** Q1, Q2 for the stranger.
- **Fix.** Lead with the person and the smallest action ("Post the round you just played. Your friends see it. Keep score all season."); move "How a season works" below; shot 1 = a friend's round in the feed.

### FR-19 · P2 · The web's league-less Home is a dashboard of absences
- **Observed (SAW shot 8 + code).** Tiles "LEAGUE · None yet · JOIN OR START", "NEXT · Open · PUT A ROUND ON THE CALENDAR", "BOARD · — · LEAGUE ONLY" (`index.html:11044,11063,11069`; the Board tile is a disabled button `:11075`). Shot 8 also shows the monthly-floor bylaw paragraph under them; at tip that line is gated behind a league (`:12502–12506`, D185 §1) — the shot predates the fix (not re-verified in a browser).
- **Damages.** Q1, Q5; "empty states are opportunities".
- **Fix.** Replace the tiles with the one next step; never render a "LEAGUE ONLY" placeholder to someone without a league.

### FR-20 · P2 · Email-only door in prod; Sign in with Apple is built but flag-closed
- **Observed (SAW + prod).** `DoorAppleButton` renders only when `DoorFlags.appleSignIn` (`DoorView.swift:104–110`); `DoorFlags` "decodes to closed in prod" by its own header (`DoorFlags.swift:9–13`); prod `app_flags.ios` = `{"note":…,"min_build":0}` — no `apple_sign_in` key. Every first run therefore requires an email round-trip and an app switch. D186 records the owner's two outstanding steps (flip + Private Email Relay).
- **Damages.** Activation / time-to-aha.
- **Fix.** Owner's: register the relay domain, set the flag. Then Apple leads on the phone door.

### FR-21 · P2 · A texted code has nowhere to go on the phone until after signup
- **Observed (SAW).** The phone door has no "I have a league code" (`DoorView.swift:91–114`); the first code field is the orientation's Join door (`LeaguelessDoors.swift:28`) or the Clubhouse/`+` menu. The web's door has one and validates before the email round-trip (`index.html:2809,17745–17748`). D151 called the web's inverse of this "the moment a golfer has an account is the moment that door disappears".
- **Damages.** Q3 for the invited-by-text golfer.
- **Fix.** A quiet "Got a code?" on the phone door that validates and arms `JoinIntent` exactly as the web does.

### FR-22 · P2 · The phone's orientation is the busiest screen of signup — explainer + three doors + a pinned exit
- **Observed (SAW).** D82 asked for "one button"; Y-15 added Join · Start a league · Start an event and their fine line beneath the teaching (`OrientationScreen.swift:9–14,137–138`); "Take me in" is pinned in the foot (`:176–191`). Five actions on the one screen whose job was "thirty seconds, then you're in".
- **Damages.** Q3 (which of five?).
- **Fix.** Folded into FR-03's replacement: one question, three answers (I have a code / find my buddies / just me for now).

### FR-23 · P2 · "Start a league" mints a league of one on a name — creation starts from the noun, not from intent
- **Observed (SAW).** Name sheet → "Start the league" creates the row (`WizardScreen.swift:68–69,88–92`), copy "The banner everything hangs under · You can rename it any time before the bylaws lock." (`WizardState.swift:375–378`). No Who / When / What-for step before the row. D151's measurement: six golfers alone in a league they made. (The wizard proper is another reader's; the door and first screen are this one's.)
- **Damages.** Q4, Q5; the brief's intent-first creation.
- **Fix.** Intent first ("play with friends / run a season / this weekend / money on it"), Who before Name, mint on the first invite.

### FR-24 · P2 · "Start an event" from nothing leads to a not-built option and a roster the golfer cannot fill
- **Observed (SAW).** Picker lists "Bracket · Knockout · seeded · last golfer standing · SOON" (tap → toast "Bracket isn't built yet", `EventPickerSheet.swift:27`); Ryder setup needs team names and players from "Search the app or tap a buddy" (`RyderSetupSheet.swift:79–113`). The occasion card "The big team match … Run your own" pushes league-less golfers here every Sep 18–Oct 5 (`HomeStream.swift:208–209`, `HomeView.swift:84–94`).
- **Damages.** Q5 (a dead end dressed as an invitation).
- **Fix.** Hide roadmap rows from a first-timer; gate the occasion on ≥1 buddy; the Ryder door on a league-less account should start with "Who's playing?".

### FR-25 · P2 · The phone card and the web card ask different things (D151 §2 landed on one client)
- **Observed (SAW).** Web card asks Home course and City (`index.html:2830–2835`, saved `:14962–14969`); phone card defers both with "add them any time from the You tab" (`CardGateView.swift:141`) and `set_profile` is called without `p_city`/`p_home` (`:233–234`). Search results render home course (D151 §3) — so a phone-signed-up golfer is a worse search result than a web one.
- **Damages.** Q4 (findability).
- **Fix.** Either ask home course on the phone (one field, optional, with course search) or ask neither at signup and both from the card later — but the same on both.

### FR-26 · P2 · The buddies path has no way to reach someone who is not on the app
- **Observed (SAW).** `PeopleScreen` searches by name/@handle; the invite-link row renders only when a league with a code exists (`PeopleScreen.swift:112–120`; the empty-search sentence says so, `:71–73`). A brand-new golfer with no league has no link to send and no contacts path (M-002 still open). The web crew step's "Find your buddies" has the same floor.
- **Damages.** Q4.
- **Fix.** A personal "play with me" link (a buddy invite, distinct from the league code — the file notes this "would need a decision") and the share sheet from the first Home.

### FR-27 · P3 · "Post one," is prose; "add some buddies." is a link
- **Observed (SAW).** `HomeView.swift:123–124`. The sentence names two actions and links one.
- **Damages.** Q3. **Fix.** Both links, or a button.

### FR-28 · P3 · "Put a round on the calendar" pushes the calendar instead of opening the declare sheet
- **Observed (SAW).** `UpcomingRoundsSection.swift:42–56` → `HomeRoute.schedule`; the `+` menu's "Your golf calendar" is the same door. One extra hop for a first action.
- **Fix.** Open `DeclareRoundSheet` directly (as the ⊕ cover's "Plan a tee time" does, `PostCoverView.swift:101–102,115`).

### FR-29 · P3 · The welcome sheet says "THREE THINGS TO KNOW" over four bold items (M-155 still open)
- **Observed (SAW).** `JoinLeagueFlow.swift:181–198`: three `rule(...)`, a hairline, then "Who else plays with you?".
- **Fix.** "Three rules, one ask." or drop the count.

### FR-30 · P3 · "check with your Pro" to someone who has no Pro
- **Observed (SAW).** `JoinLeagueFlow.swift:96` "No league with that code — check with your Pro"; web `index.html:17748` same. The joiner's Pro is "whoever sent you the code".
- **Fix.** "No league with that code — ask whoever sent it."

### FR-31 · P3 · "league" is used before it is defined, on the second screen of signup
- **Observed (SAW).** "this card follows you into every league." (`CardGateView.swift:86`; `index.html:2821`), "your leagues are told when it does" (`:2828`), "counts on your card and in every league" (`PostCoverView.swift:100`).
- **Fix.** "follows you everywhere you play" until a league exists.

### FR-32 · P3 · Build/version numbers on the first screen a stranger sees
- **Observed (SAW).** Phone "v1 · build N" (`DoorView.swift:193`); web `v23 · <sha>` in prod, the raw placeholder locally (`index.html:2914`; shot 1; M-142). A commit SHA is an operator's diagnostic, not a golfer's.
- **Fix.** Move to Settings; keep the diagnostic behind a long-press.

### FR-33 · P3 · The orientation flag is per device, so a second golfer on the same phone is never oriented
- **Observed (SAW).** `OrientedFlag.take` returns false as soon as `cs_oriented` is set (`OrientationScreen.swift:86–87`); `RootView.swift:63–64`'s comment ("the next golfer on this device is judged fresh") refers to the `orienting` state, not the flag. Rare; noted because the comment reads as a promise the code does not keep. Moot if FR-03 lands.

### FR-34 · P3 · Exit line teaches a three-level path before the user has seen the first level
- **Observed (SAW).** "Reopen this any time from You › ⚙ › How it works." (`OrientationScreen.swift:66–71`); the destination is the *Settings* pane of Card & settings (`CardAndSettingsScreen.swift:395–396`). Accurate now (D185 §3), still a map of a place they have not been.
- **Fix.** "Find this later under How it works." — or nothing.

### FR-35 · P3 · The phone gives no "welcome" beat after the card
- **Observed (SAW).** After `save()` the next paint is the orientation; the web toasts "Card saved. Welcome, X." (`index.html:14977`) and the crew step opens with "✓ CARD SAVED". The phone's `CSHaptic.success()` (`CardGateView.swift:237`) is the only acknowledgement.
- **Fix.** A one-line reveal of the card ("Here's your card, NAME.") before whatever comes next.

### FR-36 · P3 · The web's `#obWelcome` "You're in." block appears unreachable
- **Observed (SAW).** Defined at `index.html:2879–2886`; hidden in `showProfileGate` (`:14874`); no `display='block'` path found for it; `showWelcome()` (`:19843`) does not show it. Dead markup that once was the arrival moment the phone also lacks (FR-35). Not proven dead in a browser.

### FR-37 · P3 · The web crew step and the web Clubhouse disagree on the first door
- **Observed (SAW).** Crew step order: code → Find your buddies → "Start a league instead" → skip (`:2865–2877`, D151 §1); Home doors: Join · Start a league · Start an event (`:11126–11128`, D151 §4); Clubhouse: **Start a league** (bright) → I have a league code → Add golfers (`:3610–3617`). Three orderings of the same three verbs.

### FR-38 · P3 · The push sheet's third line is the best sentence in the ask and the eyebrow undercuts it
- **Observed (SAW).** "Nothing else. No streaks, no noise, no badge you didn't earn." under the eyebrow "YOUR CARD IS IN" (`PushAsk.swift:78,90`). When the ask moves (FR-05), keep that line and lead with the concrete thing it will tell them ("Jake posted a 79").

---

## Section 4 — What already serves the brief (keep)

- **The Forge** (`ForgeView.swift`): a 2.2 s once-per-device ceremony that rests on the live logo, honours Reduce Motion, and hands focus to the email field at handoff (`DoorView.swift:79–82`). Premium, editorial, golf-first — exactly the visual direction.
- **Code-only sign-in done right** (`DoorView.swift:116–159`, `DoorModel`): 8-digit field with `oneTimeCode` autofill, auto-verify on the eighth digit, 30 s resend cooldown, "Change email", the spam pointer after 20 s (`:334–341`), human error copy (`AuthRules.human`), "Signed in, loading…" note, and no navigation from the door — one path in (`:255–257`).
- **The card gate's honesty**: no default marker (S1-01, `:218`), the email-derived name never pre-filled (`:182–186`), Apple's one-shot name captured and consumed once (`DoorAppleButton.swift:51–82`, `CardGateView.swift:193–196`), live handle availability (`:119–136`), the claim thread line "Saving your card attaches the round you're claiming." (`:50–52`), `set_handle` before `set_profile` (`:232–234`).
- **The orientation's mechanics** (not its content): decided once on the way into `.ready`, written on decision so a crash never traps anyone (`OrientedFlag.take`, `OrientationScreen.swift:85–91`), skipped for the invited (D116 §3), skipped for anyone with evidence, "Take me in" pinned above the fold (`:176–191`), telemetry `orientation_shown` / `orientation_done{how}` (`:153,212`).
- **The web crew step's copy** (`index.html:2862–2874`): "Who are you playing with? Cup Season is a game you play with people you know. Bring them now and your first round already counts for something." · "A buddy texted you one? This is where it goes." — the brief's voice, the brief's question. Join validates the code before the email round-trip on the door (`:17745–17748`) and shows the covenant before `join_league` on every web path (`:15027–15031`, `:20095–20097`).
- **The web's rung ladder** (`:11439–11475`): one next-unmet fact, never a chore list — "Three rounds and your index goes live. Nothing else needed." → "Nobody's seen it — you haven't added a buddy yet · Find your buddies" → "Four makes a league. 2 more and your rounds start counting for something." This *is* the brief's funnel (casual → competition), missing only on the phone.
- **The league-less fine line** "Post a round — it counts on your card. Leagues score it when you join one." (`WizardState.swift:465`; `index.html:11130`) and the web's `#phaseSub` "No league yet, your golf still counts" (`:19852`).
- **Join first** among the doors (D151 §4, `LeaguelessDoors.swift:28–30`; `index.html:11122–11128`).
- **The join flow's consent and welcome** (`JoinLeagueFlow.swift`): covenant before join on every phone path (D116 §1); "You're invited to X."; the welcome's three rules that kill the fear at the door (D3) with solo/squad-true wording (D205, `:192`); "Share the invite link" on the welcome (`:200–206`) — growing the league is not the Pro's chore.
- **The guest claim path** (`GuestPencilScreen`, `LiveClaimAfterAuth`): the one first run that begins with a real round and a real friend.
- **Home's honesty**: no fake feed — "No rounds from your buddies yet." (`HomeView.swift:123`); a failed read never paints empty (D220, `:283–288`); the digest waits for a second visit (`HomeDigest.swift:76`); the lead card's resting state is *no card* (`HomeLead.swift:10–12`).
- **The occasion engine** (`HomeStream.swift:187–235`): calendar-driven, per-year dismissable prompts ("Azaleas are blooming somewhere.") — a seed for the living feed between seasons, once gated on what the golfer can actually do.
- **The ⊕ as a verb** (`MainTabView.swift:336–339`): presents and snaps back, with a haptic; the composer's course memory and folded rating/slope (`PostRoundScreen.swift:145–200`); "Post a round — after you play · Gross + tee, 20 seconds".
- **The push ask's policy** (`PushAskPolicy.swift`): never on launch, after a moment, 14-day snooze, and the sentence "Nothing else. No streaks, no noise, no badge you didn't earn."
- **The listing's money and price lines** ("What it costs, plainly. Nothing." · "Cup Season keeps the ledger; the money moves between friends", `app-store-listing.md:82–90`) and the keyword discipline.
- **The invite-link plumbing on the phone**: AASA claims only `/?join=` and `/?claim=` (`CupSeasonApp.swift:28–36`), `growth link_opened` logged on open, the pending join consumed after the card with the covenant in the way.

---

## Section 5 — What I could not determine from reading

1. **How the phone's first run actually looks.** No screenshot or recording of the iOS first run exists; layout, Dynamic Type behaviour, the Forge's timing on device and whether the push sheet visibly covers the first Home were inferred from code, not seen.
2. **Whether iOS Mail's `oneTimeCode` autofill fires for Brevo's template** (subject "Confirm your email address" on first send per M-029) — decides whether Flow A is 8 taps or 16.
3. **Why `orientation_shown` = 5 (all 2026-09-02) with `orientation_done` = 0** in `client_events`: simulator hatch runs (`-cs_dev_open orientation`) that were never exited, or a dropped event on the way out. Not determinable from the rows.
4. **Why `growth_events` holds no `profile_created` node** although 9 profiles were created since 2026-08-25 and both clients now log it (`Growth.swift:53–59`; `index.html:14971–14974`) — either every recent profile predates the deployed fix / came through the seeder, or `log_growth_event` refuses the node. Needs a controlled signup.
5. **Whether the 08-31 screenshot's "Monthly floor …" paragraph still renders at tip** on the web's league-less Home (D185 says gated; not re-shot).
6. **The Supabase `rate_limit_otp` value** (D187's open item) — if still 30/hour project-wide, the door fails silently on the 31st stranger of a launch hour. Not readable from the CLI.
7. **The cold-start Universal Link race on the phone**: `onOpenURL` stores the code and calls `store.reload()`, but `JoinIntent.pending()` is read only in `MainTabView.onAppear` (`RootView.swift:43`) — whether a link tapped while the app is *already* on Home opens the join sheet without a tab change was not tested.
8. **Whether `#obWelcome` ("You're in.") is reachable** on the web (FR-36) — no path found; not proven in a browser.
9. **Time-to-first-Home in seconds** (network, `native_home` payload) and whether the eight surfaces are perceived as short or long by real strangers — the Broken Tee Society cohort's first-run feedback (`feedback` rows) was not read.
10. **Whether Apple sign-in will be on at App Store submission** (owner's flip; D186) — FR-20 assumes prod as read on 2026-09-04.
11. **What the composer's first paint does with an empty course memory on a brand-new account** (whether the search field is focused, whether "Recent courses" head ever renders empty) — read as code only.

---

## Appendix — prod facts used (read-only, 2026-09-04, `supabase db query --linked`)

- `profiles`: 39 total · 29 carded (marker and handle set) · **11 carded with no `league_members` row · 10 of those with no `rounds` row** · 16 carded with ≥1 round · 12 with ≥3 rounds · 9 profiles created since 2026-08-25, none of them league-less.
- `client_events`: `home_hero_state` rung7 ×12 (last 08-30), rung6 ×2, rung5 ×5, forming ×25, season ×34; `home_hero_tap datahpost` ×2 (last 08-08); `orientation_shown` ×5 (all 09-02); `orientation_done` 0; `crew_step_shown` / `crew_step_done` / `covenant_declined` 0 (ever).
- `growth_events`: `link_opened·join` ×1 · `first_round_posted` ×7 · `artifact_shared·join` ×2 · `profile_created` 0.
- `app_flags.ios` = `{"note": "...", "min_build": 0}` — no `apple_sign_in` key.
- `pilot_instrumentation` does not exist as a table (the listing draft's privacy table names it; `client_events` is the sink).
