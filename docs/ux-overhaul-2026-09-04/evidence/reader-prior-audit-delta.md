# Reader: prior-audit delta — what the 2026-08-29 blind audit found, and what is still true at tip 3bba87e

Reader id prefix: **PA-**. Date: 2026-09-04. Repo: /Users/fischbeck3/cup-season @ 3bba87e (main, clean). Read-only.

**Method.** I read `docs/audit/blind-ux-2026-08-29/` (README, critical-findings Parts 1–5, synthesis-triage, all 51 P0/P1 rows of `issues.json`, the 12 result rows of `raw/persona-results.json`), `spec/decision-log.md` from "## The blind-audit batch" (D111) to D221, `docs/ios/DECISIONS.md`, and `git log --oneline 34d20b6..HEAD` (80 commits). Then I verified every claimed build in code at tip — `index.html` (20,567 lines), `apps/ios/CupSeason/**` and `apps/ios/Packages/CupSeasonKit/**`, `supabase/migrations` (51 files dated ≥ 2026-08-29), `packages/db/contract.psv` — and ran four read-only prod queries via `supabase db query --linked`. Everything marked SAW is a file:line I read; INFER is my reading of what that means for a user. I did not launch either client.

**Status vocabulary.** FIXED-BUILT = a D-entry exists AND the code at tip does it (cited). RULED-NOT-BUILT = a D-entry exists, the code does not do it (or does only part — noted as PARTIAL with what is missing). OPEN = no ruling owns it. SUPERSEDED = the new brief changes the frame so the ruling as written is the wrong thing to build. "Phone" = the shipping iOS client; "web" = index.html.

---

## Headline (for the orchestrator)

1. **Of the 51 P0/P1 issues: 16 FIXED-BUILT (some with residuals), 19 PARTIAL (ruled, half-built — usually web-only or phone-only), 8 RULED-NOT-BUILT, 7 OPEN (no ruling), 1 SUPERSEDED (harness artifact).** Full table in §3.1.
2. **TOP-2 ("nobody can tell what they are joining") is the least-moved headline.** D115/D116/D117 were ruled 2026-08-29 and the covenant sheet, the invite door and the cold door are byte-for-byte the audit's on BOTH clients (`index.html:17702–17715`; `JoinLeagueFlow.swift:125–141`; `ForgeView.swift:161–162`). A $0 league still gets no decision sheet at all (`index.html:17705`; `JoinLeague.swift:104`).
3. **TOP-5 ("how do I win") moved on the phone and half-moved on the web.** The endgame sentence exists on both (`index.html:6318`; `LeagueCopy.swift:398`) and sits on the phone's hero foot (`HomeView.swift:991`) but on the web only in the climb note (`:4906`); the Season tile still sorts the Cup Final line behind "Week closes" on both clients (`index.html:10803`; `LeagueCopy.swift:293–314`); rules are still a collapsed disclosure on both (`index.html:3822`; `LeaguePane.swift:100–110`); the scoring help has no ENDGAME or TIES section on either (`index.html:19768–19796`; `GuideCopy.swift:118–138`).
4. **The lock is fixed and nobody has used it.** Prod `client_events` since 2026-08-29 holds zero `lock_attempt` / `lock_ok` / `lock_fail` rows (one `league_create`, one `league_created`). The one activation-blocking P0 is repaired in code and unproven in use.
5. **The "$75 nobody chose" is fixed at the default (`buyin_cents DEFAULT 0`, prod verified) but 5 of the 6 season-phase leagues in prod still carry $75, 0 of 13 leagues have a payment note, and the buy-in row is still behind "Customize" on both clients** — D113's "seen, not buried" half is unbuilt.
6. **The phone has moved past the web on Home (D121 rows, D126 hero foot, D129 owe line, D130 leader-by-name, D176 lead card) and behind it on money (Pot pane does not show the Pro's payment terms), placeholders (`72.1`/`128` still read as values), decline persistence (`RootView.swift:43` clears the invite on appear), and the invite sheet (native ShareLink only).**
7. **What the personas actually formed as a mental model (8/8): "a fantasy-league-style season for my golf group; every round vs my own number → 5–12 points; best 4 a month; 2 a month or the squad is docked; two blind-drawn squads; a pot split 60/25/15; a four-week 'Cup Final, scored fresh' that I cannot explain."** Six of eight explanations end with the organizer as the tutorial. That model is the brief's enemy: it is the database's model (league → bylaws → squads → season → final), learned by digging, not the brief's (ME → NOW → COMPETE).

---

## Section 1 — The map: every surface the prior audit's P0/P1 findings touch, as it stands at tip

Web = `index.html` @3bba87e; phone = `apps/ios`. "First" = what the eye lands on first.

| Screen / sheet / state | Client | How reached | What it shows first (SAW) | Primary action | Exits |
|---|---|---|---|---|---|
| Cold door | web | signed-out boot | Wordmark; h1 "Rally your crew. Post real rounds. *Take the cup.*" (`:2794`); the one-sentence definition lives only in `<meta description>` (`:22`) | Continue with email / I have an invite code | none (Terms/Privacy) |
| Cold door | phone | `RootView` signed-out | "Rally your crew. Post real rounds." + italic "Take the cup." (`ForgeView.swift:161–162`) | email / code | none |
| Invite-link door (`?join=CODE`) | web | link | "You're invited to {name}. Sign in to review the league before you join." (`:20372`, `:20456`); fallback when the name lookup fails: "You're invited. Enter your email and you're in." (`:20460`) | email | none |
| Join-by-code sheet | web | door "I have an invite code" / Clubhouse `#wCodeGo` | code box; after lookup: "Enter your email — {name} is one step away; you'll review it before you're in." (`:17752`) | Continue | close |
| Covenant ("Before you join …") | web | every signed-in `join_league` path (6 call sites `:15029, :17757, :17924, :19904, :20033, :20097`) | eyebrow "THE FINE PRINT, UP FRONT"; rows BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH; "Join — I'm in for $N" / "Not now" (`:17702–17715`). **Skipped entirely when buy-in = 0** (`:17705`) | Join | Not now (code kept `:20033–20036`; Home then shows "LEAGUE · None yet · JOIN OR START" `:11044`) |
| CovenantSheet | phone | `JoinLeagueFlow` | same four rows (`JoinLeagueFlow.swift:135–138`); skipped when `buyinCents == 0` (`JoinLeague.swift:104`) | Join | Not now → `vm.covenant = nil` (`:51`); pending intent already cleared on appear (`RootView.swift:43`) |
| Orientation ("Four places. Two ways to play.") | phone | after golfer card, first time | Home/Clubhouse/Post/You + "A league — Months. Every round counts toward a table." / "An event" (`OrientationScreen.swift:46–58`); skipped for nobody (D116(3) not built) | Take me in | — |
| Wizard step 0 / 1 / 2 | web | Home doors, hero CTA (Pro only, `:4520–4527` gate) | step 1: three preset cards as token strings ("100% hcp · honor scores · any course · unlimited counting · no floor" `:3502`), "Use these defaults →" (`:3516`), Customize → `#wizDials` with Buy-in "None" (`:3518–3521`); step 2 "Review the bylaws, then lock it in" + "Lock the bylaws & form the squads" (`:3582–3585`, solo variant `:13842`) | Lock | Cancel (server-refused for non-Pro; client gate now bounces first) |
| Wizard | phone | LeaguelessDoors / menu | same three panes; buy-in inside the collapsed dials (`WizardSteps.swift:61, 110–114`); preset line identical (`WizardState.swift:68`) | Lock (→ `lock_league`, `WizardService.swift:117`) | — |
| Lock celebration / Invite sheet | web | after lock; every share control | URL as selectable mono text; Copy link · Copy a message to send · Share… · "Or read them the league code" (`:16217–16243`) | Copy link | close |
| Lock share | phone | after lock | "You're invited to {name} on Cup Season" + native `ShareLink` + Add golfers (`WizardLockShareSheet.swift:42–56`) | Share | Done |
| Home hero — forming/drawing/preseason | web | signed-in Home | role × stage cell: Pro "Name your league / Lock it in and invite your crew / Share the invite link / Draw the squads / Plan a round"; member "{Pro} is setting the bylaws…" + CTA "Plan a round", sub "Post a round" (`:11395–11440`) | cell CTA | — |
| Home hero — forming/preseason | phone | Home | `line` matrix by `m.isPro` and `m.phase` (`HomeView.swift:957–968`) | — (hero opens the table, D218) | — |
| Home hero — season | web | Home | "{pos}{ord}" + gapLine ("You lead by 22 points over Jade." / "10 back of Galen" / "Level with X. Months won breaks the tie.") + floor foot ("Sep floor 1/2 · 1 more · 3d") (`:11298–11312`, `heroFloorFoot`) — **no endgame line** | — | — |
| Home hero — season | phone | Home | `HomeHeroCopy.line` ("12 back of Galen · 9 – 21"), caption "2nd of 2", feet: rule · endgame · money · owe (`HomeView.swift:969–998`; `HomeHeroCopy.swift:46–92, 154, 230–231`) | hero → table | — |
| Home — other leagues rows | phone only | Home | `HomeLeagueRows` under the hero (`HomeView.swift:79`) | tap → re-render around that league | — |
| Home — doors | web | Home, league-less or member | league-less: "Join a league" leads, "Start a league" (`:11122–11127`); member: one quiet "Start something else…" (`:11113–11119`) | — | — |
| Home tile LEAGUE | web | Home | "None yet · JOIN OR START" when league-less (`:11044`) — also after a declined invite | → Clubhouse | — |
| Clubhouse room header | web | Clubhouse | `#phaseSub` from `STAGE_LABEL` (`:6219`, `:13905–13907`); kickoff hero "KICKS OFF IN N DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:13916`); squads row sub "LIVE NOW — CAPTAINS READY" in draft (`:13922`) | segments | Home |
| Clubhouse room header | phone | Clubhouse tab (paged per league, D203) | "{span} · THE PRO · {NAME}" (`LeagueRoomScreen.swift:183`) — "the Pro" undefined; `phaseSub` "SETUP · LOCK THE BYLAWS TO OPEN INVITES" (`LeagueCopy.swift:233`), squadsSub "LIVE NOW — CAPTAINS READY" (`:263`), kickoff "SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:271`) | segments | — |
| Standings / the climb | web | Clubhouse › Standings | chrome (header card, tiles, segmented control) then the climb; badge `IN` (`:4858`); caption "EVERYONE ADVANCES — n CONTENDERS, K SEATS" / "NOBODY TO RACE YET" + endgame sentence (`:4904–4906`) | row → member sheet | — |
| Standings | phone | Clubhouse › Standings | forming: "Squads are forming · The Pro has the list." (`StandingsPane.swift:54`); gap on the viewer's row (`StandingsMath.swift:307–310`); IN/OUT (`:393`); "EVERYONE ADVANCES" (`:421`); "SEEDS LOCKED" (`:458`); NEXT UP card with bare "Live round" mini (`StandingsPane.swift:320`) | — | — |
| Season tile ("Season · W6/26") | both | Clubhouse | nearest-deadline sort: `opts.sort((a,b)=>a.n-b.n || b.pri-a.pri)` (`:10803`; phone `LeagueCopy.swift:293–314`) — Cup Final line loses to "Week closes" | — | — |
| League pane | web | Clubhouse › League | Members & invites · Share the season · Squads · **`<details class="hubmore league-only">` "League rules"** (`:3822`) → bylaws table + "How scoring & handicaps work" (`:19828`) | — | — |
| League pane | phone | Clubhouse › League | same order; `DisclosureGroup("League rules")` (`LeaguePane.swift:100–110`) → `BylawsCard` with one mini "How scoring & handicaps work →" (`BylawsCard.swift:46`) | — | — |
| How scoring works sheet | both | League rules panel; ⚙ Card & settings › How it works; welcome sheet | sections: Your number · Every round → cup points · What counts · The money (`:19768–19796`; `GuideCopy.swift:118–138`). **No ENDGAME, no TIES, no THE SQUAD.** | — | close |
| Pot pane | web | Clubhouse › Pot | "$N on the books · $M collected"; Pro's terms row from `buy_in_note` / `buy_in_due_on` (`:7962–7963`, edit sheet `:6296`); "Post a stake" for forfeits (`:3807`); "Cup champs" (`:3789`) | — | — |
| Pot pane | phone | Clubhouse › Pot | trio tiles ("Cup champs" `PotPane.swift:45`); member rows are Buttons; non-Pro tap → toast "The Pro marks buy-ins as the money moves between friends" (`:89, :100`); **no payment terms rendered**; "Post a stake" (`:133, :189`) | — | — |
| Post a round form | web | ⊕ / Post | course → tee → Rating/Slope placeholders "—" (`:3376–3377`); "How this round scores" panel with `seasonNote('long')` (`:3442–3451`, `:7045–7049`); preview at the league's allowance (`pviFor` `:6179`, `:7005`) | Post round | Start over (date kept, `:7575–7582`) |
| Post a round | phone | Post tab (cover → card) | Rating/Slope placeholders **"72.1" / "128"** (`PostRoundScreen.swift:194–195`); preview at allowance (`PostCard.swift:226–255`); DatePicker (`:491`) | Post round | — |
| Posted card / epilogue | both | after post | band phrase + `seasonNote('short')` uppercased, fallback "COUNTS ON YOUR CARD" (`:6856–6859`; `PostEpilogue.swift:132–163`) | share | close |
| Round receipt | web | feed / You | math rows incl. "Playing number" when the allowance moved the figure (`≈:13116`), "No number yet — this round starts it (n of 3)" (`:13133`), Points (`≈:13141`); **no delete, no "Entered by"** | — | close |
| Round receipt | phone | feed / You | same rows (`ReceiptSeed.swift:145, 178`); "Attested · PLAYED WITH THE GROUP" (`:207`); no delete, no "Entered by" | — | close |
| You › Recent rounds ✕ | web | You | unlabeled ✕ → native `confirm('Delete this round? …')` (`:12919, :12930`) | delete | — |
| You › Recent rounds | phone | You | two-tap inline confirm "Sure? Delete this round" (`YouSections.swift:160–164`) | delete | — |
| Card & settings › Handicap | both | ⚙ | "Your index builds automatically … Set it here to seed a starter; once you have 3 rounds your scores take over." (`:15809`; `CardAndSettingsScreen.swift:404`); Findable by All/Buddies/Nobody, default All (`:16039`; `:356`) | — | — |
| Add golfers / people picker | both | League › Members; You › buddies | name/@handle search; a stranger row gets [Add] (`:15718`); phone tags rel but gates nothing (`PeoplePickerSheet.swift:98`) | Add | close |
| Live setup | phone | ⊕ Play now | title "Play now", eyebrow "Set up the round" (`LiveSetupView.swift:27, 51`); Close in the host (`LiveRoundHost.swift:44, 55`); copy "Pick who plays with who under the game — pairings, stakes, the lot…" (`:139–140`); game rule shown only when the seat count is legal, else "Wolf needs exactly 4 players." (`LiveCopy.swift:288–294`) | Tee off | Close (round keeps running) |
| Live round | web | ⊕ Play now | "Scrap this round" arms then confirms on second tap (`:10680–10690`) | Finish | scrap |
| Board | both | Clubhouse › Board (pushed on phone from either stack, `MainTabView.swift:149–182`) | web header "The board · rounds land here automatically" (`:3655`); phone title "The board" (`BoardScreen.swift:41`) | post | back |
| Schedule / calendar | web | Clubhouse segment → `view-schedule` full screen | back link "← Clubhouse" when opened from the room (`:4548–4557`, `:3174`) | plan | back |
| Schedule | phone | pushed route from Home or Clubhouse | month grid (`ScheduleScreen.swift:116–129`) | plan | back |
| Install nudge | web | earned moments | "Add Cup Season to your home screen — it stays signed in, and opens full screen." (`:3997–4006`) | Add to Home Screen | Not now |

---

## Section 2 — Flows the prior audit walked, as they stand at tip

### 2.1 Organizer: create a league and get it running (Journey C)
- **User goal.** "I want to run a season for six friends" — the brief's "run a season" intent.
- **Current friction (SAW).** Three steps still ask the database's questions before the human's: competitiveness preset (token strings, `:3502`), then Customize → 8 dials, then "Review the bylaws, then lock it in" (`:3582`). The lock is now one RPC (`lock_league`, `:17316`; `WizardService.swift:117`) and the celebration opens the invite sheet with the URL as text (`:16256–16290` → `:16217`). The Pro's Home hero walks them through name → lock → share → draw → plan (`:11395–11405`).
- **Unnecessary complexity.** The wizard is still bylaws-first: preset → allowance → verification → counting cap → floor → structure → draft type → finish → payouts. The brief's intent-first door ("we're playing this weekend" / "run a season" / "we want money on it") does not exist; every organizer passes the same three panes.
- **Confusing terminology (exact strings).** "100% hcp · honor scores · any course · unlimited counting · no floor" (`:3502`; `WizardState.swift:68`); "Lock the bylaws & form the squads" (`:3585`; `WizardState.swift:416`); "Lock opens the invite link — one link fills the league. The code works until first tee, or until you close the roster. Squads need four to tee off; solo tees off at two." (`WizardState.swift:414`); "4 squads · the full cup experience for 8+ players." (`:3542`, `WizardState.swift:29`); "Pro — that's you" (`:3487`).
- **Dead ends.** None hard: the lock cannot lie post-commit (Q-01 split). A solo Pro may still lock alone and land in `season` at one member (D205 accepted this).
- **Redundant actions.** Buy-in is still a dial inside Customize on both clients (`:3518–3521`; `WizardSteps.swift:110–114`) — D113 ruled it above "Use these defaults →"; a money crew opens Customize to find it, and a bragging-rights crew never learns money was a choice.
- **Missing feedback.** Prod has recorded no lock attempt since the fix (0 `lock_attempt`/`lock_ok`/`lock_fail` rows since 2026-08-29); the D111 "lock health" alert has nothing to measure.
- **Delight opportunities.** The lock celebration already knows the seat math ("N in — K more fills the squads"); it could be the moment the season gets a name, a date and a first rivalry instead of a bylaws receipt.

### 2.2 Organizer: invite the five friends
- **User goal.** Get five specific people in without writing instructions.
- **Current friction.** Web: `openInviteSheet` — URL as text, Copy link, Copy a message to send, Share…, "Or read them the league code" (`:16217–16243`); `inviteMessage` names the Pro, first tee, stake/"No buy-in — bragging rights", and the one-line pitch (`:16202–16216`). Phone: native `ShareLink` with `WizardCopy.inviteText` (`WizardLockShareSheet.swift:49`) — I did not find a URL-as-text or Copy-message control on the phone.
- **Unnecessary complexity.** Invites reach account-holders by @handle only through the picker; a stranger with a matching name still shows [Add] (`:15718`; `PeoplePickerSheet.swift:98`) — D118 unbuilt.
- **Terminology.** "One link fills the league" (`:16221`); "Add golfers" (`WizardLockShareSheet.swift:56`).
- **Dead ends.** Contact invites (email/SMS) were declined by ruling (D136 Q-07: "not scheduled … revisit only if a real Pro asks"). The brief names *friend connection* as a success metric; this ruling is the one most at odds with it.
- **Missing feedback.** Pending/joined state per invitee exists only as the roster count; no "Marcus opened the link" beat (the `growth_events` funnel records `link_opened` since D185).
- **Delight.** The Copy-message text is good voice; it could carry the roster so far ("Casey, Priya and Marcus are in").

### 2.3 Joiner: open the link, decide, join (Journey "Join") — the least-moved flow
- **User goal.** Know what I am joining before I say yes to $50.
- **Current friction (SAW, both clients).** Door: one line, "You're invited to {name}. Sign in to review the league before you join." (`:20372`). After email → 8-digit code → golfer card → (phone: orientation) → the covenant: four rows BUY-IN / PRESET / PARTICIPATION FLOOR / FINISH and "Join — I'm in for $50" (`:17710–17716`; `JoinLeagueFlow.swift:135–141`). `join_covenant_info` still returns name · buyin · preset · floor · finish · structure (contract.psv:166; last touched by `20260901220000` for the buy-in only) — no Pro, no roster count, no dates, no bands, no split, no payment path. **A $0 league shows no sheet at all** (`:17705`; `JoinLeague.swift:104`), so a bragging-rights joiner consents to nothing and learns the floor and the squads later.
- **Unnecessary complexity.** The phone still shows the D82 orientation to invitees (D116(3) unbuilt); the web fallback door line still promises "Enter your email and you're in." when the name lookup fails (`:20460`).
- **Terminology.** "PRESET · Standard" (untappable, undefined, `:17711`); "on the pot sheet" (`:17710`); "FINISH · Cup Final · final 4 weeks" (`:17713`); "THE FINE PRINT, UP FRONT" (`:17708`).
- **Dead ends.** "Not now": web keeps `cs_code` (`:20033–20036`) but Home renders "LEAGUE · None yet · JOIN OR START" (`:11044`) — there is no "Invited · {league} · REVIEW" card, so the kept code is invisible; phone clears the intent on appear (`RootView.swift:43`) and the sheet's `onNo` just closes (`JoinLeagueFlow.swift:51`) — the invite is lost exactly as the audit saw.
- **Redundant actions.** Consent is now on every signed-in join path (six `covenantGate` call sites) — the S3-01 hole the audit found is closed.
- **Missing feedback.** Nothing before the OTP says who runs it or how many are in; the covenant never says how the $50 is paid ("due before first tee · the Pro has posted how to pay" — D129(4) — not built).
- **Delight.** Every fact the joiner wants is in the database one join away (D115's own point). The invite could be the product's best artifact: roster faces, first tee, the stake, one sentence of rules.

### 2.4 Member: the first day in a league (Journey "Post-join", TOP-3)
- **User goal.** "What do I do now, and is this my job?"
- **Current friction (SAW).** Fixed on both clients: `switchView('wizard')` bounces a non-Pro with "Only the Pro edits the bylaws" (`:4520–4527`); the hero names the Pro and the date and offers "Plan a round" + "Post a round" (`:11408–11440`; `HomeView.swift:957–968`); the Start/Start/Join doors collapse to "Start something else…" for members (`:11113–11119`).
- **Unnecessary complexity.** The member still meets six stage words across the app that D120 retired and the code kept: "The Pro has the list." (`:3676`; `StandingsPane.swift:54`), "SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" (`:13916`; `LeagueCopy.swift:271`), "LIVE NOW — CAPTAINS READY" (`:13922`; `LeagueCopy.swift:263`), "Complete · rosters locked" (`:13923`), "OPENS AFTER SETTINGS LOCK" (`:13921`), "SETUP · LOCK THE BYLAWS TO OPEN INVITES" (`LeagueCopy.swift:233`). "Captains" has no referent in a blind-draw league.
- **Terminology.** "the Pro" is still undefined at first contact on the phone: "{span} · THE PRO · GALEN" (`LeagueRoomScreen.swift:183`); D132 ruled a definition in the orientation, the covenant's WHO row and the chip — none built.
- **Dead ends.** None.
- **Missing feedback.** The member's "Plan a round" lands on a calendar; nothing on the first day says which squad they will be in or who else is in (roster is a Clubhouse tab).
- **Delight.** The drawing-stage cell already says "{Pro} draws the squads before first tee — it's random." — the draw could be an event with a countdown and a reveal.

### 2.5 Member: post the first round and understand what it did (Journey D, TOP-4)
- **User goal.** Post in 20 seconds and know what I earned.
- **Current friction (SAW).** The season-window sentence is one producer on both clients and reaches the form panel, the posted card and the empty note (`seasonNote` `:6268`, used `:6858, :7045, :7049`; `LeagueCopy.seasonNote` `:206`, `PostEpilogue.swift:132`). The preview scores at the league's allowance (`pviFor` `:6179`; `PostCalc.pvi` `PostCard.swift:226`). Band edges are half-open and match `cup_points` (`pointsFor` Q-20; `CSBands`). The no-number first round is named ("No number yet — this round starts it (1 of 3)", `:13133`; `ReceiptSeed.swift:145`). The receipt prints "Playing number" when the allowance moved the figure (`≈:13116`; `ReceiptSeed.swift:178`).
- **Unnecessary complexity.** The web's "How this round scores" panel still carries the static "No league yet? The round still counts on your card — points apply in any league you join." (`:3451`) until `recalc` overwrites it (`:7045`) — a flash of the old lie on first paint (INFER).
- **Terminology (still shipping).** Signed bare numbers via `sgn()` at `:5011` (squad receipt "−2.6 vs index · 9 PTS"), `:13020–13021` (member sheet "Avg/Best"), `:13054` (standings "AVG VS INDEX" coloured by sign), `:13070` (history "BUMPED"), `:14254, :14260` (clash rows) — the inverted-sign complaint 7 of 8 testers logged survives on five web surfaces. Phone: "+2.4 vs your playing number" (`YouSections.swift:185`) — signed but labelled. "COUNTS ON YOUR CARD" remains the fallback verdict (`:6859`; `PostEpilogue.swift:163`).
- **Dead ends.** Fix a wrong score: web still the unlabeled ✕ on You with a native `confirm` and no undo (`:12919, :12930`); phone an inline two-tap (`YouSections.swift:160–164`); neither receipt offers delete or "post it again". No D-entry owns this (OPEN).
- **Redundant / contradictory numbers.** `home_feed` still computes pvi at 100% (`20260723090000_home_feed_photo.sql:18`; `contract.psv:157` has no `p_league`), while the receipt and standings use the 95% lens — D123's server half is unbuilt, so the "one round, two numbers" the observer saw (Home card 3.3 vs receipt 2.6) can still occur on both clients wherever the feed row is drawn from `home_feed`.
- **Missing feedback.** Phone placeholders "72.1"/"128" still read as filled values (`PostRoundScreen.swift:194–195`); the web's are "—" (`:3376–3377`).
- **Delight.** The band phrases ("You torched your number by 5.0. Sandbagger alert.") are the best voice in the product; the posted card could carry "counts #2 in September" everywhere it already knows it (phone does: "COUNTS FOR THE PINES", `PostEpilogue.swift:158`).

### 2.6 Everyone: "how do we win?" (Journey E/F, TOP-5)
- **User goal.** Know what the lead is worth, what the Final is, how ties break — without the Pro.
- **Current friction (SAW).** One producer for the endgame sentence on both clients (`endgameLine` `:6318`; `LeagueCopy.endgame` `:398–413`) with the +10 correctly squads2-only and "Level on points? Months won breaks it." Placement: phone hero foot (`HomeView.swift:991` → `footEndgame`); web climb note (`:4906`) only. The web hero's season branch renders gap + floor foot and **no endgame** (`:11298–11312`). The Season tile on both clients still picks the nearest deadline (`:10803`; `LeagueCopy.swift:293–314`) so "Cup Final · Dec 22 · 115d" loses to "Week closes Sun" on almost every day — the exact mechanism the validators reproduced. IN replaces LOCKED (`:4858`; `StandingsMath.swift:393`); "EVERYONE ADVANCES — 2 CONTENDERS, 2 SEATS" still prints (`:4904`; `StandingsMath.swift:421`); "SEEDS LOCKED" / "HAS LOCKED THE TOP SEED" remain on the phone (`:458, :467`). D127's "With 2 of you, both reach the Final — the season only decides who starts +10" was not found on either client.
- **Unnecessary complexity.** Rules remain league administration: `<details class="hubmore league-only">` (`:3822`), `DisclosureGroup("League rules")` (`LeaguePane.swift:100–110`) — D128 "Rules are a place, not a disclosure" is unbuilt on both; the scoring help has four sections and no ENDGAME / TIES / THE SQUAD (`:19768–19796`; `GuideCopy.swift:118–138`); bylaw rows are still static text (no `.byrow` handler found).
- **Terminology.** "scored fresh" (`:6337`; `LeagueCopy.swift:150, 413`) still undefined by a tap; "seed" defined only inside the sentence; "Cup champs" (`:3789`; `PotPane.swift:45`).
- **Dead ends.** Ties for Points King: "a tie stands as a shared crown" is the ruling (D136) and the ladder is unbuilt (D212(3)); nothing on screen says either.
- **Missing feedback.** No "this round matters because" line on either client — `homeStakeLine()` (D130) is explicitly unbuilt; the phone has the lead card and clash beats (D176), the web has neither.
- **Delight.** The Final is the product's name; a countdown pinned on every standings surface is one sort-rule away on both clients.

### 2.7 Everyone: pay the pot (Money, TOP-5)
- **User goal.** Know how much, to whom, how, by when.
- **Current friction (SAW).** Web: the Pro sets a note + due date (`openBuyInTerms` `:6296`; `set_buy_in_terms` in `20260830040000`); the Pot pane renders it (`:7962–7963`). Phone: the Home owe line reads "You still owe $75 · Venmo @casey" or "· ask the Pro how to pay — money moves between you" (`HomeHeroCopy.swift:230–231`), but the Pot pane does not render the terms and non-Pro rows are still Buttons that toast "The Pro marks buy-ins as the money moves between friends" (`PotPane.swift:89, :100`). Prod: 0 of 13 leagues have a note; 5 of 6 season leagues sit at $75.
- **Terminology.** "on the books" (money) beside "Post a stake · Pride, on the books — never money" (`:3807`; `PotPane.swift:189`) — D131's stake→forfeit rename is unbuilt on both; one noun, opposite meanings, adjacent.
- **Dead ends.** The covenant never says "due before first tee · the Pro has posted how to pay" (D129(4), unbuilt both).
- **Missing feedback.** A member cannot nudge the Pro; the Pro's own row reads "Your own $75 isn't marked in yet" on the phone (built) and nothing on the web (INFER).

### 2.8 Everyone: play a live side game (Journey G)
- **User goal.** Score Saturday's match/skins/Wolf with guests and settle.
- **Current friction (SAW).** Phone: title + Close (D173, `LiveRoundHost.swift:44, 55`); web: two-tap scrap (`:10680`). Game rules still render only when the seat count is legal (`LiveCopy.swift:288–294`: "Wolf needs exactly 4 players." otherwise) — D133 unbuilt; no "Side games settle between you… never touch season points" sentence found on either client; no `GAME_RULES` table on the web.
- **Terminology.** "Pick who plays with who under the game — pairings, stakes, the lot." (`LiveSetupView.swift:139–140`); "Enter the pars" (`:107`); "Leave index blank for an estimated 18."
- **Dead ends.** None new.
- **Missing feedback.** Attestation now reads the fact (attested only when the golfer's own phone joined, `20260830280000`); the recourse "That was me / That wasn't me" and "Entered by Priya" are unbuilt on both clients — a golfer whose 103 lands on their card still cannot see who typed it.
- **Delight.** The season never points at the live round except the bare "Live round" mini in NEXT UP (`StandingsPane.swift:320`; web `:3454`-era) — D134's six placements are unbuilt; the most-praised layer is still found only through ⊕.

### 2.9 Existing member: come back mid-season (Journey E, retention)
- **User goal.** A reason to open the app between rounds.
- **Current friction (SAW).** Phone: leader by name with the score (`HomeHeroCopy.line`), "2nd of 2", rows for other leagues (`HomeView.swift:79`), lead card with clash beats (D176). Web: gap line + floor foot; no other-league row (D121 "the web row is still owed"); no lead card; hero move chip "— HELD" untappable.
- **Terminology.** "— HELD", "Sep floor 1/2 · 1 more · 3d" (`heroFloorFoot`) — no tap-to-explain on the web; phone words are plainer ("Month floor 2/4 · 2 more", `HomeHeroCopy.swift:153`).
- **Missing feedback.** The what-if / stake line (D130) — unbuilt; rival's floor state — unbuilt; board posts still carry no played date (no D-entry; unverified in code).

### 2.10 iOS first look (the phone survey's eleven screens)
- Fixed: season length one source (`Models.swift:277–281` → `LeagueDates.totalWeeks`); gap line on the viewer's row; Live has a title and Close; leader named and field sized ("2nd of 2"); the "preview at 100%" caption gone.
- Still true: nothing on Home is a door to "how points work" (no scoring-help route in `HomeView.swift`); "the Pro" undefined (`LeagueRoomScreen.swift:183`); the board's relation to Home not re-verified; rating/slope placeholders still values.

---

## Section 3 — Findings

### 3.1 Status table — every P0/P1 issue, TOP-1..5, and the seven zero-instruction reasons

Columns: status · ruling · evidence at tip (web / phone) · phone has the same defect? · brief note.

| id | sev | short title | status | ruling | web evidence (SAW) | phone evidence (SAW) | phone same defect? | brief |
|---|---|---|---|---|---|---|---|---|
| M-001 | P0 | Lock throws after commit | **FIXED-BUILT** | D111, Q-01 | `lockBylaws` → `lock_league` `:17316–17356`; commit/celebration split at the `#lockBtn` handler (`:17766+`); migration `20260829220000` | `WizardService.swift:117` → `lock_league` | never had the crash; non-atomic port replaced | unproven in prod (0 lock events since 08-29) |
| M-002 | P0 | No invite by email/SMS | **RULED-NOT-BUILT** (declined) | D114, D136 Q-07 | link + `inviteMessage` only (`:16202–16243`) | `ShareLink` only (`WizardLockShareSheet.swift:49`) | yes | SUPERSEDED-in-spirit: brief metric "friend connection" |
| M-004 | P0 | Hidden $75 default | **PARTIAL** | D113, D196, D206 | default 0 (`20260901220000:64`, prod-verified); `#stakeVal` "None" `:3521`; **still inside `#wizDials` behind Customize `:3518`** | `stake: 0` default (`WizardState.swift:101`); **inside the collapsed dials** (`WizardSteps.swift:110–114`) | yes (placement) | prod: 5/6 season leagues at $75 |
| M-023 | P0 | Covenant withholds roster/Pro/dates/scoring/pay | **RULED-NOT-BUILT** | D115, D136 | four rows unchanged `:17710–17716`; `join_covenant_info` not extended (contract.psv:166; last migration `20260901220000`) | four rows `JoinLeagueFlow.swift:135–138`; `Covenant` has 5 fields (`JoinLeague.swift:57–61`) | yes | core of the brief's "who I am competing with" |
| M-030 | P0 | Members get the Pro's lock button | **FIXED-BUILT** | D119, Q-10 | `switchView` gate `:4520–4527`; role × stage matrix `:11395–11410` | `HomeView.swift:957–968` | no (fixed) | — |
| M-040 | P0 | Pre-season points promised, 0 delivered | **FIXED-BUILT** (residual) | D122, D120 | `seasonNote` `:6268`, used `:6858, :7045, :7049` | `LeagueCopy.seasonNote` `:206`; `PostEpilogue.swift:132` | no (fixed) | residual: kickoff string `:13916` / `LeagueCopy.swift:271` is a second phrase family |
| M-159 | P0 | Blank date → "try again" | **FIXED-BUILT** | Q-21 | `resetPostComposer` `:7575–7582`; `humanError` `:4458`; `:7180` | DatePicker cannot be blank (`PostRoundScreen.swift:491`) | n/a | — |
| M-003 | P1 | Link never displayed | **FIXED-BUILT** (web) / PARTIAL (phone) | D114 | `openInviteSheet` `:16217–16243`; all controls route there (`shareInvite` `:16244`) | native sheet only; no URL-as-text/Copy message seen | partly | — |
| M-006 | P1 | Lock described five ways | **PARTIAL** | D160, D161, D180, D205 | "Forming — the rules aren't locked in yet" (D160); `lockButtonText` still "Lock the bylaws & form the squads" `:13842` | `inviteNote` "Lock opens the invite link…" `:414`; `lockButton` `:416` | yes | — |
| M-007 | P1 | Minimum four revealed last, unenforced | **FIXED-BUILT** (reframed) | D205 | every minimum from `STRUCT_MIN` (`:13821` note) | `structMin` (`WizardState.swift:24, 413–414`) | no | solo may still lock at 1 by ruling |
| M-008 | P1 | Teams control caption/hint contradict | **OPEN** | — | `#structNote` default "4 squads · the full cup experience for 8+" `:3542`; map `:13662` | `WizardState.swift:29`, hint `:174–177` "solo fits" | yes | unverified whether caption binds on paint |
| M-009 | P1 | No worked examples (3-v-4, seed, +10, 60%) | **RULED-NOT-BUILT** | D126, D127 | `endgameLine` explains +10 for squads2 (`:6333`); D127 Pro-at-lock line not found | `LeagueCopy.endgame` `:398`; D127 line not found | yes | — |
| M-010 | P1 | Preset cards are jargon tokens | **OPEN** | (D160 touched help only; D183 removed "Pro Shop") | `:3502` "100% hcp · honor scores · any course · unlimited counting · no floor" | `WizardState.swift:68` identical | yes | — |
| M-011 | P1 | Verification vocabulary (GHIN/attested/verified) | **OPEN** | — | card `:3502`; bylaws "VERIFICATION Attested" | `LeagueCopy.verif` `:24` ("Post what you'd post to GHIN") | yes | — |
| M-017 | P1 | Generic errors mask server sentences | **FIXED-BUILT** | Q-09 | `humanError` allowlist `:4449–4450`; clipboard branch `:4453` | `JoinService.joinError` (`JoinLeagueFlow.swift:115`), `roomError` | mostly | — |
| M-018 | P1 | Install banner covers ⊕ | **OPEN** (placement) | D186 (copy only) | copy `:3997–4006`; position not re-verified | n/a | n/a | — |
| M-019 | P1 | Strangers addable; Findable All default | **RULED-NOT-BUILT** | D118 (A) | `rel==='none'` → [Add] `:15718`; default 'everyone' `:16039` | `PeoplePickerSheet.swift:98` no gate; `CardAndSettingsScreen.swift:356` | yes | prod: 24 profiles on the default |
| M-024 | P1 | Landing copy "Enter your email and you're in" | **FIXED-BUILT** (one fallback left) | Q-15 | `:17752–17753`, `:20372`, `:20456`; fallback `:20460` still says it | not verified | — | — |
| M-025 | P1 | "Not now" drops the invite | **PARTIAL** (web) / **RULED-NOT-BUILT** (phone) | D116 | code kept `:20033–20036, :20097–20106`; **no "Invited · REVIEW" card** — tile `:11044` "None yet" | `RootView.swift:43` clears on appear; `onNo` closes `:51` | yes | — |
| M-026 | P1 | "PRESET Standard" undefined | **RULED-NOT-BUILT** | D115(3) | `:17711` static | `JoinLeagueFlow.swift:136` static | yes | — |
| M-031 | P1 | You tab opens the wizard | **SUPERSEDED** (harness artifact) | validators | wizard gate makes it impossible `:4520` | n/a | no | — |
| M-033 | P1 | Member Home leads with Start/Start/Join | **FIXED-BUILT** | D119(4), D151 | `:11113–11127` | `LeaguelessDoors` league-less only; menu "Start a league" `HomeView.swift:180` | no | brief: "play before league" — the league-less doors still lead with Join/Start a league, not "Add my round" |
| M-041 | P1 | Five-way league status | **PARTIAL** | D120 | `STAGE_LABEL` `:6219`, `leagueStage` `:6227`; **retired strings still rendered** `:3676, :13916, :13921–13923` | `Stage.label` `LeagueCopy.swift:179–184`; **retired strings** `:233, :263, :271`; `StandingsPane.swift:54` | yes | — |
| M-044 | P1 | Posted card/receipt lack points/status | **FIXED-BUILT** | D122, D123, D124, D209 | card `:6856–6859`; receipt Points `≈:13141`, Playing number `≈:13116`, no-number `:13133` | `PostEpilogue.swift:132–163`; `ReceiptSeed.swift:145, 178` | no | — |
| M-045 | P1 | Sign inversion (minus = worse) | **PARTIAL** | D123 ("retire sgn") | `vsPhrase` on card/feed; `sgn()` still `:5011, :13020, :13021, :13054, :13070, :14254, :14260` | signed float with label "vs your playing number" (`YouSections.swift:185`, `Career.swift:134`) | partly | — |
| M-046 | P1 | Band unit / overlapping edges / three wordings | **PARTIAL** | Q-20, D123(4), D210 | half-open `pointsFor` (≈`:6185–6197`); unit stated in help `:19789`; no single `BANDS` constant found | `CSBands` one source | mostly fixed | — |
| M-047 | P1 | One round, two numbers (100% vs 95%) | **PARTIAL** | D123, D174, D178, D209 | preview at allowance `:7005`; **`home_feed` still 100%** (`20260723090000:18`; contract.psv:157 no `p_league`) | preview at allowance `PostCard.swift:226`; You at lens (D209) | yes where `home_feed` is read | — |
| M-051 | P1 | Starter vs GHIN precedence unstated | **OPEN** | — (D196 is GHIN privacy) | `:15809` unchanged | `CardAndSettingsScreen.swift:404` unchanged | yes | — |
| M-054 | P1 | Rules four taps deep behind a disclosure | **RULED-NOT-BUILT** | D128 | `<details class="hubmore league-only">` `:3822`; help linked from welcome `:19808`, settings `:16000`, guide `:15860`, rules panel `:19828` — not from hero/form/standings | `DisclosureGroup("League rules")` `LeaguePane.swift:100–110`; one mini `BylawsCard.swift:46` | yes | — |
| M-055 | P1 | Endgame invisible (Cup Final, seeds, LOCKED, advances) | **PARTIAL** | D126, D127, D136 | `endgameLine` `:6318`; placed on climb note `:4906` only; hero season branch has no endgame `:11298–11312`; Season tile sort unchanged `:10803`; IN `:4858`; "EVERYONE ADVANCES" `:4904` | `LeagueCopy.endgame` `:398`; hero foot `HomeView.swift:991`; deadline sort unchanged `LeagueCopy.swift:293–314`; "EVERYONE ADVANCES" `StandingsMath.swift:421`; "SEEDS LOCKED" `:458` | partly (tile sort, caption) | — |
| M-056 | P1 | No tiebreak anywhere | **PARTIAL** | Q-26, D126, D136, D212 | hero "Months won breaks the tie." (`:11520`-area); endgame line; no TIES help section; King ladder unbuilt | tiebreak in `endgame` `:402`; no TIES section | yes (help) | — |
| M-057 | P1 | Floor explained four ways | **FIXED-BUILT** | Q-27, D140 | `floorSentence` `:6360`, used `:12506, :12555`; help `:19772–19781` | `GuideCopy.swift:104–108`; `footRule` | no | wizard (i) not re-verified |
| M-058 | P1 | Team game never introduced | **PARTIAL** | D115, D119, D120 | drawing cell "{Pro} draws the squads — it's random." `:11421`; covenant has no structure row | `HomeView.swift:960`; covenant none | yes (covenant) | — |
| M-059 | P1 | HELD / AUG FLOOR / MONTH CLOSES undefined, untappable | **RULED-NOT-BUILT** | D126 ("every rendering taps") | `heroFloorFoot` untappable; "— HELD" chip | `footRule` plainer words `HomeHeroCopy.swift:153`; untappable | yes | — |
| M-070 | P1 | Schedule leaves the room; iOS duplicate routes | **PARTIAL** (web) / **FIXED-BUILT** (phone) | Q-12, IOS-011 | back link returns to Clubhouse `:4548–4557`; still a full-screen view `:3862` | pushed routes only (`MainTabView.swift:84–85, 149–182`) | no | — |
| M-072 | P1 | Home shows one league | **FIXED-BUILT** (phone) / **RULED-NOT-BUILT** (web) | D121 | no row on web ("still owed") | `HomeLeagueRows` `HomeView.swift:79` | no | brief: living feed across leagues |
| M-076 | P1 | Rating/slope placeholders; −79.0; tee not required | **PARTIAL** | Q-22/23 | placeholders "—" `:3376–3377`; sanity gate; recents/tee-required not re-verified | placeholders **"72.1"/"128"** `PostRoundScreen.swift:194–195`; `vsIsSane` `PostEpilogue.swift:199` | yes (placeholders) | — |
| M-080 | P1 | No correction path on the receipt | **OPEN** | — | ✕ on You + native confirm `:12919, :12930`; receipt has no delete | inline two-tap `YouSections.swift:160–164`; receipt none | yes (receipt) | — |
| M-084 | P1 | Board contradicts Home | **PARTIAL / unverified** | D120 (stage-aware empty line), D165 | header "rounds land here automatically" `:3655`; `round_to_board` exists | title "The board" `BoardScreen.swift:41`; synthetic "post the first round" string not found | unverified | — |
| M-085 | P1 | live-resume embed fails; banner never appears | **FIXED-BUILT** | Q-09, D200 | FK-qualified embed `:8764`; banner `:8838`; `20260902140000` | D169–D172 (iOS discovery query) | no | — |
| M-090 | P1 | "Scrap this round" dead | **FIXED-BUILT** | D141 | two-tap arm `:10680–10690` → `abandon_live_round` | not re-verified | — | state variance not re-tested |
| M-093 | P1 | One phone attests four cards; no dispute | **PARTIAL** | D125, D125a | migration `20260830280000` (attested only when own phone joined; `posted_by`); no "That wasn't me" / "Entered by" strings | `ReceiptSeed.swift:207` "Attested · PLAYED WITH THE GROUP"; no recourse | yes (recourse) | — |
| M-102 | P1 | iOS Live: no title/exit/game name | **FIXED-BUILT** (copy residual) | D173, D110 | n/a | Close `LiveRoundHost.swift:44, 55`; title `LiveSetupView.swift:51`; copy `:139–140`, "Enter the pars" `:107` | — | — |
| M-110 | P1 | Pot: no payee/method/deadline; fake rows | **PARTIAL** | D129 | terms editable + rendered `:6296, :7962`; covenant "due before first tee" not built | Home owe line `HomeHeroCopy.swift:230–231`; **Pot pane shows no terms; non-Pro rows still Buttons** `PotPane.swift:89, :100` | yes (pane) | prod: 0 notes set |
| M-120 | P1 | Board dates ≠ standings counts | **OPEN** | — | not verified | not verified | — | — |
| M-123 | P1 | No rival / gap / what-if | **PARTIAL** | D130, D176, D108 | gap line; no stake line; no lead card | leader by name + score (`HomeHeroCopy.swift:46–78`); lead card + clash beats (D176); `homeStakeLine` unbuilt | partly | — |
| M-129 | P1 | Race below the fold; iOS gap on wrong row | **PARTIAL** | (gap: D-note in `StandingsMath.swift:307–310`) | chrome above the climb unchanged (`#hubHeader` `:3623`) | gap fixed `:307–310`; chrome unchanged | yes (chrome) | — |
| M-143 | P1 | Cold door explains nothing | **RULED-NOT-BUILT** | D117 (PROPOSED — owner's call) | `:2794` slogan only; sentence only in `<meta>` `:22`; no "How it works" on the door | `ForgeView.swift:161–162` | yes | SUPERSEDED-in-frame: brief wants seconds-to-understanding |
| M-144 | P1 | iOS never defines the game; leader unnamed | **PARTIAL** | D130, D117(3), D178 | n/a | leader + "2nd of 2" (`HomeHeroCopy.swift:46–92`); **no "How points work" door on Home**; orientation defines league/event only (`OrientationScreen.swift:55–56`) | — | — |
| M-145 | P1 | iOS 14 vs 13 weeks | **FIXED-BUILT** | (iOS P1 list) | n/a | `Models.swift:277–281` → `LeagueDates.totalWeeks` | — | — |
| M-160 | P1 | Course search 502s silent | **FIXED-BUILT** (web) | Q-24 | `:7750` "Course search is down — type the course, rating and slope by hand." | `PostCourseSearchField` not verified | — | — |

**TOP-1..5 and the seven zero-instruction reasons**

| item | status at tip | what is left |
|---|---|---|
| TOP-1 organizer cannot finish | **FIXED-BUILT** (lock, invite sheet, $0 default) with residuals | buy-in row still behind Customize (both); contact invites declined; phone invite sheet is ShareLink-only; **no lock event in prod since the fix** |
| TOP-2 nobody can tell what they are joining | **RULED-NOT-BUILT** (both clients) | D115 richer RPC + league card on the door + decision sheet; D116 "Invited · REVIEW" card (web) and decline persistence (phone) and skip-orientation (phone); D117 door sentence + How it works. Only "consent on every path" (web) and "code survives Not now" (web) are built |
| TOP-3 members handed the Pro's controls | **FIXED-BUILT** (both) | D120's retired stage strings still ship on both; "the Pro" undefined on the phone header |
| TOP-4 first round contradicts itself | **FIXED-BUILT** core (both) | `sgn()` sites on the web; `home_feed` at 100%; no delete on the receipt; phone placeholders; "COUNTS ON YOUR CARD" fallback |
| TOP-5 how do I win / pay | **PARTIAL** | web hero has no endgame foot; Season tile sort on both; rules a disclosure on both; no ENDGAME/TIES help; phone Pot pane has no terms; stake line unbuilt; 0 pay notes in prod |
| ZI-1 setup cannot complete | FIXED-BUILT (unproven in prod) | — |
| ZI-2 friends cannot be invited from the app | PARTIAL | link + message yes; contact invite declined; phone has no Copy message |
| ZI-3 friend cannot tell what they are joining | **OPEN in effect** (ruled, unbuilt) | D115/D116/D117 |
| ZI-4 Home hands members the lock button | FIXED-BUILT | — |
| ZI-5 first round promises points, delivers 0 | FIXED-BUILT | residuals above |
| ZI-6 nobody can answer "how do we win" | PARTIAL | sentence exists; placement + rules place + help sections missing |
| ZI-7 money nobody knows how to settle | PARTIAL | web Pot terms built; phone pane not; covenant line not; 0 notes set |

### 3.2 Still-open P0/P1 items, with phone status (the redesign's inheritance)

Ranked by damage to the brief's five questions (what is happening · why it matters to me · what I can do right now · who I am competing with · what happens next).

1. **M-023 / M-026 / M-058 / M-024-fallback — the joiner decides blind (P0).** Both clients. Damages *who I am competing with* and *why it matters to me* at the highest-value moment. Ruled D115/D136; unbuilt.
2. **M-025 — a declined invite is still a loss on the phone; on the web it is kept but invisible (P1).** Phone identical to the audit (`RootView.swift:43`). Damages *what I can do right now*.
3. **M-143 — the door is a slogan (P1, both).** D117 is PROPOSED, not decided. Damages *what is happening* for every stranger.
4. **M-054 / M-055 / M-056 / M-059 — the win condition is a sentence with too few homes; rules are still admin (P1, both).** Damages *what happens next*. D126/D128 half-built.
5. **M-110 — the pot has terms on the web and none on the phone; nobody in prod has set any (P1).** Damages *why it matters to me*.
6. **M-041 — six retired stage words still print on both clients (P1).** Damages *what is happening*.
7. **M-047 / M-045 — a round can still show two numbers (feed at 100%), and five web surfaces still print signed bare numbers (P1).** Damages *why it matters to me* (trust in the table).
8. **M-004 placement — buy-in still behind Customize (P0 residual, both).** Damages *what I can do right now* for money crews and honesty for the rest.
9. **M-019 — strangers addable; 24 profiles findable by all (P1, both).** Damages *who I am competing with* (privacy of a friend group).
10. **M-072 (web) — one league on Home (P1).** Phone fixed. Damages *what is happening*.
11. **M-123 — no "this round matters because" (P1, both).** Damages *why it matters to me* between rounds.
12. **M-093 recourse — "that wasn't me" (P1, both).** Damages trust.
13. **M-080 — fix-a-wrong-score from the receipt (P1, both, OPEN).** Damages *what I can do right now* at the point of need.
14. **M-076 (phone) — placeholders as values (P1).** Web fixed.
15. **M-010 / M-011 / M-008 / M-009 / M-006 — wizard copy (P1, both, mostly OPEN).** Damages *what is happening* for the organizer.
16. **M-051 — starter vs GHIN precedence (P1, both, OPEN).**
17. **M-002 — contact invites (P0, declined).** Reopen under the brief's friend-connection metric.
18. **M-129 chrome / M-120 board dates / M-018 banner — unverified or open polish (P1).**

### 3.3 The five most instructive persona quotes

1. **Skeptic (run 2, verdict, `persona-results.json`):** "The value that would justify switching — a fair, automatic, season-long race against your own number that a spreadsheet can't do, from any course, with a pot ledger and a final — is real but is the LEAST visible thing in the product. What's visible on day one (a chat, a calendar, a pot ledger, gross scores, a $50 ask, a Pro's lock button on my Home) is what we already have or don't want." — and, discovery Q10: "Every casual round becomes fair league points, the money is tracked, and the season has an ending — this sentence belongs on the door." *(The door still does not say it: `:2794`, `ForgeView.swift:161`.)*
2. **Casual (run 1, explain-it-to-a-friend):** "…the only way to let your team down is not playing. … Honestly the app doesn't explain most of that — Casey had to." *(Six of eight 30-second explanations end with the organizer as the tutorial.)*
3. **Mid-season observer (verdict + finale):** "To beat Galen — he's the only name the app made me care about … The cup final is a line in the bylaws, the pot was never collected, and the app never told me what winning would have meant." On the finale: "The database reached its final row." *(The name is now on the phone hero; the finale is still one sentence on a climb note on the web and a tile that hides it on both.)*
4. **New joiner (first signed-in screen, 3s/10s/30s):** "30s: I could open the room, plan a round, read the feed — I could not tell what I was supposed to do, and the only obvious button looked like the organizer's job." And the 30-second explanation's last line: "The catch is the app doesn't move money — Casey keeps a tab, and I still don't know how I'm supposed to pay him." *(The first is fixed on both clients; the second is fixed on the web Pot pane only and set by nobody in prod.)*
5. **Competitive (run 2, verdict):** "It never gives me a rival, a gap to the leader, or a 'this round matters because' line; the only rivalry in my league today is the pride stake I typed myself. … as shipped I'd play for the skins and shrug at the table." *(Rival and gap: phone yes, web partly; "this round matters because": neither — D130 unbuilt.)*

Runner-up, because it names the mental-model gap exactly — **League novice, discovery Q10 (after):** "Every casual round counts for months; bad rounds still score (5-pt floor); daily players can't bury weekly ones (cap); ghosting penalised (floor); receipts show the math — learned from a help sheet four taps deep, not the product surface."

### 3.4 What the ten discovery questions say about the mental model users form

From the eight interactive result rows (BEFORE = cold door; AFTER = end of session). This is the best evidence of the model the product actually teaches.

| Q | BEFORE (7/7 web personas) | AFTER | Where they learned it |
|---|---|---|---|
| 1 What does it do | "golf thing for a group; someone takes the cup" (from nine words) | "months-long league; every real round anywhere scores 5–12 vs my own handicap; best 4/month for a squad; pot; live side games" | assembled from welcome sheet, scoring sheet, bylaws accordion, You › How it works |
| 2 Primary action | "Continue with email" | "Post a round via the ⊕" — but the member's biggest button was the Pro's | Home |
| 3 What a season is | "a stretch of time; length unknown" | "Sat Sep 5 → Sat Jan 2 · 17 wks; monthly caps/floors; last 4 weeks a 'Cup Final · scored fresh'" | bylaws table only |
| 4 What a league is | "my friend group" | "group + Pro + code + bylaws + pot + two blind-drawn squads + a board" | Clubhouse tabs |
| 5 What the cup is | "a trophy" | **still fuzzy for 6 of 7** ("used for the whole season, the last-4-week Final, the champs, trophy icons, and 'Cups & events'") | never defined |
| 6 Competing for | "the cup / bragging rights; money unknown" | "$250 pot 60/25/15 + Points King / Most Improved / Iron Man + trophies" | Pot tab only |
| 7 Against whom | "my crew" | "my squad vs the other squad (a surprise for 4 of 7), everyone for Points King, my foursome for side games" | tab six of the room |
| 8 How rounds work | "type a score" | "front/back gross + tee → differential vs index → 5–12 band; best 4; 2/month floor" — **fully learned by all** | the post form |
| 9 After a round | "a leaderboard moves" | "a card, a receipt with math, a feed item — and 0 in the table with no sentence why" | trial and error |
| 10 Different from golf with friends | "can't tell" | "a fair points race across handicaps from any course, a pot ledger, a season with an ending — the least visible thing in the product" | help sheet, four taps deep |

**INFER — the model that forms.** Users reconstruct the *database*: league → Pro → bylaws → squads → season window → month caps/floors → Cup Final → pot split. They never form the brief's model (ME → NOW → COMPETE). Two things they never resolve: what "the cup" is, and whether *this* round counted. Two things they resolve only by asking Casey: how to win, and how to pay. Five of eight reach for "fantasy league" as the analogy — the product's own name does not carry it.

### 3.5 Numbered findings (PA-)

Severity here is against the *new brief* at tip, not the old audit's. Each names the file:line at 3bba87e and which of the five questions it damages.

**PA-001 · The joiner's decision sheet is the audit's, on both clients — P0.** `covenantGate` renders BUY-IN / PRESET / FLOOR / FINISH and "Join — I'm in for $N" (`index.html:17710–17716`); `CovenantSheet` the same four rows (`JoinLeagueFlow.swift:135–141`); `join_covenant_info` still returns six keys (`contract.psv:166`). No Pro, no roster count, no dates, no bands, no split, no pay path. Damages *who I am competing with* and *why it matters to me* at the highest-bail moment. Recommendation: build D115 as ruled (richer RPC, league card above the email box, decision sheet) — or, under the brief, replace the covenant with an invite artifact (faces · first tee · one rules sentence · the stake) that the joiner sees *before* the OTP.

**PA-002 · A $0 league gets no consent and no teaching at all — P0.** `if(!info || !Number(info.buyin_cents)) return true;` (`index.html:17705`); `guard let c = Covenant(info), c.buyinCents > 0 else { return nil }` (`JoinLeague.swift:104`). D136 ruled "a $0 league DOES get a decision sheet"; unbuilt both. Damages *what is happening* for every bragging-rights joiner (prod: all 6 setup leagues are $0). Recommendation: one sheet for every join, stake row optional.

**PA-003 · "Not now" still loses the invite on the phone; on the web it is kept where nobody can see it — P1.** `RootView.swift:43` `.onAppear { … JoinIntent.clear() }`; `JoinLeagueFlow.swift:51` `onNo: { vm.covenant = nil }`. Web keeps `cs_code` (`:20033–20036`) but the LEAGUE tile prints "None yet · JOIN OR START" (`:11044`); D116's "Invited · {league} · REVIEW" card is on neither client. Damages *what I can do right now*. Recommendation: a pending-invite card on Home (both), pre-filled code, cleared only on join or "Not interested".

**PA-004 · The door is a slogan on both clients; the one-sentence definition exists only in `<meta>` — P1.** `index.html:22` vs `:2794`; `ForgeView.swift:161–162`. D117 is PROPOSED, never decided. Damages *what is happening* for every stranger (D185 says the next arrivals are strangers). Recommendation: under the brief this is not a copy amendment to D83 — the door should be the first "living" surface (a real feed preview or a one-tap "how it works"), and the sentence is the floor.

**PA-005 · The invitee still sees the orientation before the covenant on the phone — P2.** D116(3) unbuilt (`OrientationScreen.swift` has no `viaInvite` skip; `RootView.swift:43` handles the intent independently). Damages *what I can do right now* (one more screen). Recommendation: skip for invitees as ruled; or fold the four-noun teaching into the invite card.

**PA-006 · The endgame sentence has one home on the web and the Season tile hides it on both — P1.** Web: `endgameLine` only at the climb note (`:4906`); hero season branch renders `me.gapLine, heroFloorFoot()` with no endgame (`:11298–11312`). Both: `opts.sort((a,b)=>a.n-b.n || b.pri-a.pri)` (`:10803`; `LeagueCopy.swift:314`) — "Cup Final · … · 115d" (pri 2) loses to "Week closes … · 3d" (pri 0) on every day the week-close is nearer, i.e. almost all of them. D126 ruled three homes and "the week/month closes keep the slot only within 1 day of firing". Damages *what happens next*. Recommendation: pin the Cup Final line; add the endgame foot to the web hero.

**PA-007 · Rules are still an admin disclosure on both clients, and the help has no ENDGAME / TIES / THE SQUAD — P1.** `<details class="hubmore league-only">` (`index.html:3822`); `DisclosureGroup("League rules")` (`LeaguePane.swift:100–110`); `openScoringHelp` sections at `:19768–19796`; `GuideCopy.scoring` at `:118–138`. Bylaw rows are static. D128 unbuilt. Damages *what happens next* and *what is happening*. Recommendation: under the brief, rules are not a Clubhouse sub-pane at all — they are the one sentence on the season's cover ("How this season is won") with the receipt behind it.

**PA-008 · Six retired stage words still print — P1.** Web `:3676` "The Pro has the list.", `:13916` "KICKS OFF IN N DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON", `:13921` "OPENS AFTER SETTINGS LOCK", `:13922` "LIVE NOW — CAPTAINS READY", `:13923` "Complete · rosters locked"; phone `LeagueCopy.swift:233` "SETUP · LOCK THE BYLAWS TO OPEN INVITES", `:263` "LIVE NOW — CAPTAINS READY", `:271` the kickoff line, `StandingsPane.swift:54` "Squads are forming · The Pro has the list." D120 built the producer (`STAGE_LABEL`) and left the consumers. Damages *what is happening*. Recommendation: delete the literals; every stage word from the producer (a preflight lint would have caught these — D131 asked for one).

**PA-009 · The buy-in is a choice the organizer still has to go looking for — P1.** `#stakeVal` "None" inside `#wizDials` (`index.html:3518–3521`, `display:none` until Customize); `WizardSteps.swift:110–114` inside `dials` (`showDials`). D113 ruled it above "Use these defaults →". Prod: default 0 verified; 5 of 6 season leagues at $75; 0 pay notes. Damages *what I can do right now* (the brief's "we want money on it" intent). Recommendation: money is an intent question, not a dial — ask it once, plainly, before the presets.

**PA-010 · The phone's Pot pane has no payment terms and its member rows are still buttons that toast — P1.** `PotPane.swift:89` toast "The Pro marks buy-ins as the money moves between friends"; `:100` `Button` for every row; no `buy_in_note` read anywhere in `CupSeason/League/PotPane.swift`. The Home owe line is built (`HomeHeroCopy.swift:230–231`) so the phone says "Venmo @casey" on Home and nothing on the sheet that is about money. Damages *why it matters to me*. Recommendation: render the terms row and status rows as D129 ruled.

**PA-011 · The covenant never says how or when the $50 is paid — P1 (both).** D129(4) "$50 · due before first tee · the Pro has posted how to pay" — no `has_pay_note` / `buy_in_due_on` on `join_covenant_info` (contract.psv:166), no such row in `covenantGate` or `CovenantSheet`. Damages *why it matters to me*.

**PA-012 · One round can still show two numbers — P1 (both).** `home_feed(p_days)` (`contract.psv:157`) computes `pvi` at 100% (`20260723090000_home_feed_photo.sql:18`); the standings view and receipts use the league allowance. D123's `home_feed(p_days, p_league)` / `lens` field is unbuilt. Damages *why it matters to me* (trust). Recommendation: the lens on the server, one number per round.

**PA-013 · Signed bare numbers survive on five web surfaces — P1 (web); labelled but signed on the phone — P3.** `sgn()` at `index.html:5011, :13020, :13021, :13054, :13070, :14254, :14260` ("AVG VS INDEX −4.0" in red for a leader). D123 ruled "retire `sgn()`". Damages *why it matters to me*. Recommendation: words, never a sign, per `vsShort`/`vsPhrase` which already exist (`:6353, :6374`).

**PA-014 · "COUNTS ON YOUR CARD" is still the fallback verdict on both clients; "Post a stake" and "Cup champs" survive — P2.** `index.html:6859`, `:3807`, `:3789`; `PostEpilogue.swift:163`, `PotPane.swift:45, :133, :189`. D131's noun assignments (stake → forfeit; "card" never for the record; "Cup champs" → "the winning squad") unbuilt. Damages *what is happening*.

**PA-015 · "the Pro" is still undefined at first contact on the phone — P2.** `LeagueRoomScreen.swift:183` "{span} · THE PRO · GALEN"; no definition in `OrientationScreen.swift`; covenant has no WHO row. D132 ruled three definitions; none built. Three of eight personas read it as the club professional. Damages *who I am competing with*.

**PA-016 · Strangers are still addable from the picker; 24 prod profiles are findable by all — P1 (both).** `index.html:15718` (`rel==='none'` → [Add]); `PeoplePickerSheet.swift:98`; default 'everyone' `:16039` / `CardAndSettingsScreen.swift:356`. D118 unbuilt. Damages *who I am competing with* (the brief's COMMUNITY is real friends).

**PA-017 · Contact invites were declined; the brief's friend-connection metric wants them back — P1 (both).** D114/D136 Q-07. `inviteMessage` (`:16202`) is a good message with no sender. Recommendation: reopen; at minimum, "Add friends by phone contact" as a first-class COMMUNITY action.

**PA-018 · The phone's invite sheet is a native ShareLink only — P2.** `WizardLockShareSheet.swift:42–56`. D114 said the phone "adds Copy message and the seat line only"; I found neither. Damages *what I can do right now* for a Pro who wants to paste into a group text.

**PA-019 · Fixing a wrong score is still a hidden ✕ with a native confirm (web) and absent from the receipt (both) — P1.** `index.html:12919, :12930`; `YouSections.swift:160–164`; no delete in `ReceiptSeed.swift` / `roundCardBody`. No D-entry (OPEN). Damages *what I can do right now* at the point of need. Recommendation: "Delete and post it again" on the receipt, app-styled, with D50's sentence.

**PA-020 · A 103 someone else typed still lands on your card with no name and no recourse — P1 (both).** `20260830280000` records `posted_by` and honest `attested`; no "Entered by …" or "That wasn't me" string on either client (`ReceiptSeed.swift:207` prints "Attested · PLAYED WITH THE GROUP" only when true; unconfirmed rounds show nothing that says who typed them). D125 stage 2 unbuilt. Damages trust in *what is happening*.

**PA-021 · "This round matters because" exists in three engines and reaches no Home — P1 (both).** D130 `homeStakeLine()` unbuilt (its own note); `native_home()` v2 carries `leader_name` but not `clash`/`needs` (`20260902200000:266–268`). Web has no lead card (D176 is phone-only). Damages *why it matters to me* between rounds — the retention loop.

**PA-022 · The web Home shows one league — P1 (web).** D121 "the web row is still owed"; no `HomeLeagueRow` equivalent in `index.html`. Phone: `HomeView.swift:79`. Damages *what is happening*.

**PA-023 · Wizard copy is the audit's — P1 (both).** Preset cards `index.html:3502` / `WizardState.swift:68`; "Lock the bylaws & form the squads" `:3585` / `:416`; `inviteNote` `:414`; structure caption default `:3542` / `:29`; "Pro — that's you" `:3487`. M-006/M-008/M-010/M-011 mostly OPEN. Damages *what is happening* for the organizer. Recommendation: under the brief the wizard is replaced by intent → Who → When → What for → Customize; these strings should not be polished, they should go.

**PA-024 · Starter vs GHIN precedence still unstated — P1 (both).** `index.html:15809`; `CardAndSettingsScreen.swift:404`. OPEN. Damages *why it matters to me* for the serious golfer (the competitive persona's "my 6.4 will be overwritten").

**PA-025 · Phone rating/slope placeholders still read as values — P1 (phone).** `PostRoundScreen.swift:194–195` "72.1" / "128"; web is "—" (`:3376–3377`). Damages *what I can do right now* (the casual golfer posts nonsense or stalls).

**PA-026 · Side-game rules still hide behind their own precondition — P2 (both).** `LiveCopy.swift:288–294` ("Wolf needs exactly 4 players." instead of the rule); no `GAME_RULES` (i) on the web; no "side games never touch season points" sentence found. D133 unbuilt. Damages *what is happening* for the layer everyone liked.

**PA-027 · The season never points at the live round — P2 (both).** D134's six placements unbuilt; the only pointer is the bare "Live round" mini in NEXT UP (`StandingsPane.swift:320`). Damages *what I can do right now*.

**PA-028 · "How points work" is not a door on the phone's Home — P2.** No scoring-help route in `HomeView.swift`; reachable only via Clubhouse › League › disclosure › mini, or ⚙ › How it works. Damages *what is happening* for the invitee the iOS survey modelled.

**PA-029 · "— HELD" and the floor foot are untappable on both — P3.** `heroMyRung` move chip; `heroFloorFoot`; `HomeHeroCopy.footRule`. D126 "every rendering taps" unbuilt for these. Damages *what is happening*.

**PA-030 · The web landing keeps one lying fallback — P3.** `index.html:20460` "You're invited. Enter your email and you're in." when `league_by_code` returns nothing. Damages *what happens next*.

**PA-031 · "Scored fresh" is still undefined by any tap on either client — P2.** `index.html:6337`; `LeagueCopy.swift:150, :413`; `:17713` covenant. Damages *what happens next*.

**PA-032 · The lock is fixed and unproven — P2 (process).** Prod `client_events` since 2026-08-29: `post_open` 30, `home_hero_state` 16, `signed_in` 12, `client_error` 8, `orientation_shown` 5, `push_opened` 3, `round_posted` 1, `post_submit` 1, `league_create` 1, `league_created` 1 — no `lock_attempt`/`lock_ok`/`lock_fail`, no `invite_open`, no `covenant_declined`. D111's "alert when lock_fail > lock_ok" has had nothing to alert on. Not a UX defect; a caution for the redesign's success metrics (activation cannot yet be read from prod).

**PA-033 · Seven of the audit's P1s were never ruled — P2 (bookkeeping).** M-008, M-010, M-011 (wizard copy), M-051 (index precedence), M-080 (receipt correction), M-120 (board dates), M-018 (banner placement) carry no D-entry. The redesign should own them explicitly rather than inherit them silently.

### 3.6 Where the new brief SUPERSEDES the old rulings (do not build these as written)

- **D83/D117 (the door "sells with its own splash" + one sentence):** the brief wants a stranger to *understand within seconds*; a slogan plus one line is the floor, not the design. Reframe the door as the first living surface.
- **D81/D94/D121 (one hero, one lane, a compact row per other league):** the brief's Home is a living feed across everything I am in; the "one authoritative surface per question" rule fights "never an empty dashboard between seasons". Keep the honesty rules (D23 self-only money, D27 no empty hero), drop the single-league hero as an axiom.
- **D119 (role × stage matrix on the hero):** correct as a fix, but it hard-codes the database's stages (setup/draft/preseason/season/final/complete) as the user's reality. The brief wants NOW (what is happening) not PHASE (what state the row is in).
- **D115 (the covenant as the decision sheet):** the brief wants the *invite* to sell and the join to be one tap; a longer consent sheet after sign-in is the wrong place for the roster and the dates — they belong on the link preview and the pre-OTP door.
- **D128 (rules are a place inside the Clubhouse's League pane):** the brief's destinations are ME/NOW/COMPETE/COMMUNITY/HISTORY; "League pane" is the database's noun. The endgame sentence and the floor sentence are the season's cover copy, not a pane.
- **D136 Q-07 (contact invites not scheduled):** conflicts with the brief's friend-connection metric and the "I want to beat Jake" intent.
- **D151/D119(4) (Join a league leads; Start a league; Start something else…):** the brief says play before league — the smallest useful action is "Add my round", and creation starts from intent, not from "Start a league".
- **D132 ("the Pro" stays):** compatible, but the brief forbids commissioner mechanics being required for understanding — the definition must be a by-product of seeing a person's name on the invite, not a glossary entry.

---

## Section 4 — What already serves the brief well (keep list)

- **The lock cannot lie.** `lock_league` (`20260829220000`; `index.html:17316`; `WizardService.swift:117`) + the commit/celebration split (Q-01). One tap, one transaction, idempotent.
- **The invite sheet on the web.** URL as text, Copy link, Copy a message, Share…, the code as a last resort (`:16217–16243`); the message is in the product's voice and carries the pitch (`:16202–16216`). Reuse it for the brief's "invite from intent".
- **Role × stage Home cells that name a person and a date.** "{Pro} is setting the bylaws. You'll see them the moment they lock." / "{Pro} draws the squads before first tee — it's random." (`:11416–11421`; `HomeView.swift:957–968`). Keep the voice; change the frame.
- **The season-window phrase family.** "Practice — the season starts Sat Sep 5. This round builds your number; it earns league points from then on." (`seasonNote` `:6268`; `LeagueCopy.seasonNote` `:206`) — one sentence, three surfaces, both clients.
- **One PvI producer in the composer.** `pviFor` (`:6179`) and `PostCalc.pvi` (`PostCard.swift:226`) with half-open edges matching `cup_points`; the receipt's "Playing number" row (`≈:13116`; `ReceiptSeed.swift:178`); the honest first-round line "No number yet — this round starts it (1 of 3)".
- **The endgame and floor producers.** `endgameLine` / `LeagueCopy.endgame` (structure-aware, +10 only where the engine pays it, tiebreak named) and `floorSentence` (solo-aware, bye included). The words are right; only the homes are missing.
- **The phone's Home foot and owe line.** rule · endgame · money · owe (`HomeView.swift:986–998`; `HomeHeroCopy.swift:154, 230–231`) — self-only money, D23 respected, plain words ("Month floor 2/4 · 2 more").
- **Leader by name with the score.** "10 back of Galen · 9 – 19", "2nd of 2" (`HomeHeroCopy.swift:46–92`; `native_home()` v2 `20260902200000:266–268`). This is the brief's "who I am competing with" in one line.
- **The phone's other-league rows and lead card** (D121, D176): the living-feed instinct already exists on the phone.
- **Consent on every join path** (six `covenantGate` sites) and **the join window** (`20260830300000`: code closes at first tee, Pro's door to halfway) — the mechanics are honest even where the sheet is thin.
- **Honest attestation on the server** (`20260830280000`): the fact is recorded; only the recourse is missing.
- **`humanError`'s allowlist** (`:4449–4450`): server sentences written for golfers reach golfers.
- **The band phrases and the scoring help's first two sections** ("You can't hurt your squad by playing badly — only by not playing."; "a 22-index beating their number is worth exactly what a 6-index beating theirs is") — every persona praised them; they belong on the door, not four taps deep.
- **The live scorer, guest play, settlement card, course → tee → rating/slope autofill** — praised by every persona and untouched by the redesign's problems; D152 landscape card and D155 Live Activity extend them.
- **Default-honesty migrations since the audit**: buy-in 0, season 13 weeks/points/squads2 (`20260902160000`), hybrid retired, first-tee horn restored (D204), solo minimum 2 (D205).

---

## Section 5 — What I could not determine from reading

1. **Whether a real Pro has locked a league since the fix.** Prod `client_events` holds no lock telemetry since 2026-08-29; TestFlight 669 testers may lock via the phone (`league_created` 1) but the web's `lock_ok` has not fired. Activation is unmeasured.
2. **Whether the install banner still overlaps the ⊕** (M-018) — copy changed (D186); geometry not re-verified without rendering.
3. **Whether the wizard's Teams caption binds to the selection on first paint** (M-008) — a `STRUCT_NOTES` map exists (`:13662`) but the static default (`:3542`) may still flash.
4. **The phone lock-share sheet's full contents** (D114 claims Copy message + seat line) — grep found `ShareLink` and "Add golfers" only; I did not render it.
5. **Whether board posts carry the played date** (M-120) — no D-entry; `board_voice_natural_case.sql` did not show a played-date change.
6. **Whether the web Board shows posted rounds now** (M-084) — `round_to_board` exists; the audit's case was pre-season rounds and I did not trace the season-window condition in `round_to_board`.
7. **Whether "Scrap this round" behaves in every live state** (M-090) — the two-tap arm is wired; the state variance the audit saw was not reproduced by reading.
8. **Whether the welcome sheet ("THREE THINGS TO KNOW", `:19804`) now names the squads and the draw** (M-058) — not read in full.
9. **The wizard (i) for the floor still saying "Pro-approved bye"** (M-057 residual) — not re-read.
10. **iOS `PostCourseSearchField`'s failure message** (M-160 on the phone).
11. **Whether the iOS Board names its league and what its empty state says** — `BoardScreen.swift:41` title "The board"; the old synthetic line was not found, the replacement not confirmed.
12. **Whether the web's `recalc()` guards the preview on rating+slope** (M-076 web) — the sanity gate exists for the ceremony; the panel path not traced.
13. **Which client the owner's testers used for the `home_hero_state` events** (16 rows) — no platform prop inspected.
14. **D116's `cs_invite_declined` on the web** — the code stays in `cs_code` (not a separate declined key); whether `boot()` could auto-join from it again after a later sign-in was not traced past `:20033`.
15. **The real-device rendering of any of this** — I read code only; no screenshots, no simulator.

---

*Sources read: `docs/audit/blind-ux-2026-08-29/{README.md, critical-findings.md, synthesis-triage.md, issues.json, issues-README.md, issues-counts.json, raw/persona-results.json}`; `spec/decision-log.md:4123–5700`; `docs/ios/DECISIONS.md`; `git log 34d20b6..HEAD`; `index.html`; `apps/ios/CupSeason/**`, `apps/ios/Packages/CupSeasonKit/**`; `supabase/migrations/2026083*..2026090*`; `packages/db/contract.psv`; four read-only `supabase db query --linked` calls (client_events, leagues × league_settings, information_schema.columns, profiles).*
