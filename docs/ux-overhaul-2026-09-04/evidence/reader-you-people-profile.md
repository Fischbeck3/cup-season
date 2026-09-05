# Reader · you-people-profile — identity, social graph, settings, pricing (YP-)

Repo tip 3bba87e · read 2026-09-04 · read-only. Line numbers are as of tip.
Scope: `apps/ios/CupSeason/{You,People,Settings,Pricing,Looks}/*`, the Kit's `You/*`, `People/*`, `Settings/*`, `Pricing/PricingFlags.swift`, the migrations behind `my_rivalries`, `rivalry_weeks`, `tour_card`, `search_golfers`, `my_friends`, `last_round_with`, `respond_invite`, `achievements`; the routing in `Main/MainTabView.swift`; the four named screenshots plus the scratchpad shots; the prior blind audit's 22 You/People/Settings issues re-checked against tip.

**Evidence conventions.** SAW = read in code or a screenshot at tip. INFER = a conclusion drawn from what was read. PROD = a read-only aggregate run via `supabase db query --linked` on 2026-09-04 (no PII pulled; counts only).

**Screenshot caveat (SAW).** All four named screenshots predate tip. `apps/ios/Screenshots/6.9/05-you.png` and `06-settings.png` (Sep 1) show "Member since Aug 2026", "YOUR DISPLAY CASE", "THE RECORD · No silverware yet", "LIFETIME", "YOUR PHOTO · THE MARKER ALWAYS BACKS IT UP", "HANDLE · MOVES ONCE / 60 DAYS" — every one of those strings is retired at tip (`TourCard.established` "est.", `CSSectionHead("Display case")`, `"All time"`, the D174 marker caption, `"Handle · 60-day lock"`). `docs/audit/signup-walk-2026-08-31/9-you.png` and `10-card-and-settings.png` are the WEB (the "Tell us how it's going" chip on You, "PLAN FREE · PILOT", the ⊕ FAB), not the phone. So the shots are evidence of what shipped/was submitted, and the code is evidence of tip; where they differ I say which I am citing. Finding YP-41 is about that gap itself.

**Prod snapshot (PROD, counts only).** 39 live profiles · 1 with a photo · 4 with a GHIN · 9 with a home course · 16 with zero rounds · 19 with ≥3 rounds (index established) · 19 engine-owned indexes, 9 manual · 14 profiles in no league, 11 in two or more · 13 leagues · 12 accepted buddy pairs + 12 pending; 12 profiles have at least one buddy · discoverable: 24 everyone / 0 buddies-only / 15 nobody · 0 named rivalries · 65 rivalry pairs across 331 clash-weeks by `my_rivalries`' own logic; 20 profiles carry a rivalry · 8 `week_clashes`, 2 settled · 111 achievements · 1 mute · 1 device token in `device_tokens` · 0 rows in `feedback` · `app_flags.pricing.visible = false`, `founding.ids = {}`.

Three of those numbers shape everything below: **16 of 39 cards are empty, 14 of 39 golfers are in no league, and one phone in the book can receive a push.**

---

## 1 · The map

| # | Screen / sheet / state | How reached | What it shows first | Primary action | Exits |
|---|---|---|---|---|---|
| 1 | **You** (`YouScreen`) — loaded, league, rounds | 4th tab; push route `you`; dev `-cs_dev_open you` | `CSPageHeader("You")` + ⚙; hero (photo/crest, name, `@handle · city · home course`, `est. Aug 2026 · add your GHIN` or `GHIN n · est.`, marker caption, index in gold or `n of 3`, trophy chips, FORM dots + key); then the `Your buddies` door row | none — the page is reading; the only door above the record is `Your buddies` (`YouScreen.swift:96-103`) | ⚙ → Card & settings; buddies door; LRW `Stage it`; trophy tile → receipt; recent round row → receipt (× arms delete); rivalry row → Tour Card; `Every season` row → Clubhouse; empty state CTA → composer |
| 1a | You — loading | first paint | header/hero/buddies door render from `store.me`; record blocks are `.redacted(.placeholder)` (`YouScreen.swift:167,190`) | — | — |
| 1b | You — partial load | any block read failed | one footnote line `Some of your card did not load. Retry` (`:121,228-238`) | Retry | — |
| 1c | You — no rounds (16/39 in prod) | `career.rounds == 0` | hero with `0 of 3 · HANDICAP INDEX` + `Building your number — your index appears at 3 posted rounds`; `Your golf` head; (case only if hardware); `⛳ No rounds yet — your card fills as you play.` + `Post your first round` (`:130-138`) | Post your first round | composer |
| 1d | You — league-less | no memberships | as 1/1c but no `Your seasons` head, no season strip, no rivalries (`:175-184`) | — | — |
| 2 | **Your buddies** (`PeopleScreen`) | You door; Home `YOUR BUDDIES ↗`, `add some buddies.`, ⊕ menu `Find golfers`, Up-next chip; Clubhouse league-less `Add golfers`; Post cover `openPeople`; push route `people` | `Requests · n` (if any) → `Find golfers` search field → results → `Send an invite link` row (only if a league has a code) → `Buddies · n` / `No buddies yet. Search up top to add them.` → `Requested` → `Findable by` All/Buddies/Nobody | search; Accept/× on a request | Person row → Tour Card; share sheet |
| 3 | **Tour Card** (`TourCardSheet`) — another golfer | any name in the app (23 call sites incl. Board, Standings members, Schedule, Live, Ryder/Major, People, Rivalries) | `Tour Card · @HANDLE`; `CredentialCard` (photo/crest, name, founding tag, `@handle · city · est.`, index or `n of 3`, ≤3 trophy chips + `+N more`, FORM + key); `VS YOU · 3–2 · YOU LEAD` chip (only with clash history); `Report photo` (if photo); `Add buddy` / `Accept buddy request` / tag `Buddies`/`Requested`; `Career · vs their playing number` (Rounds/Best round/Avg/Home course/GHIN); `Recent rounds` (5 rows, `85 GROSS · PAPAGO GC · VS COURSE 7.8`); `🔇 Mute — hide their posts from your boards` | Add buddy | VS YOU chip → Rivalry sheet; swipe down |
| 3a | Tour Card — own card | tap own name; dev `tourcard` | `Your Tour Card · THIS IS HOW YOUR BUDDIES SEE YOU`; same card, no buddy action, no mute, no VS chip | none | — |
| 3b | Tour Card — PRIVATE | server `visible:false` | `Tour Card · PRIVATE` · `This golfer keeps their card private, or you don't share a league yet.` (`TourCardSheet.swift:38`) | none | — |
| 3c | Tour Card — could not load / loading | error / in flight | `COULD NOT LOAD · Could not pull the card — check your signal and try again. · Try again` / `LOADING… · Pulling the card…` | Try again | — |
| 4 | **You vs NAME** (`RivalrySheet`) | VS YOU chip on a Tour Card; epilogue does NOT open it | title `You vs Galen`, sub `3–2 · WEEKLY CLASH · BETTER ROUND VS YOUR PLAYING NUMBER TAKES THE WEEK`; gold `“THE GRUDGE”` if named (but see YP-05); week cards `WK OF JUL 6 · WON · YOU +1.2 · GALEN −0.4 · BEST ROUND VS YOUR PLAYING NUMBER THAT WEEK`; `Name this rivalry` / `Rename “…”` | Name this rivalry | naming sheet |
| 5 | **Name the rivalry** (`NameRivalrySheet`) | from 4 | `Name the rivalry · YOU VS GALEN`; help line; field (`The Grudge`, 40 chars); `Name it` / `Save the name` / `Clear the name` | Name it | dismiss |
| 6 | **Card & settings** (`CardAndSettingsScreen`) | You ⚙; `add your GHIN` (lands on GHIN field, card pane); push route `settings` | eyebrow `What your buddies see` / `How the app runs`; segmented `Your card` / `Settings` | — | back |
| 6a | Your card pane (`CardEditorPane`) | pane 0 | `NAME ON THE CARD` · `CITY` · `HOME COURSE` · `BALL MARKER` (14 tiles + caption) · `YOUR PHOTO` (face + `Add a photo`/`Change photo`/`Remove`) · `HANDLE · 60-DAY LOCK` · `FINDABLE BY` All/Buddies/Nobody · `GHIN # · OPTIONAL` · `Save card`/`Save changes` · `HANDICAP INDEX` (engine line + `How scoring works →`, or field + `Update index`) · `YOUR LEAGUES` (`Name  PRO · CODE`) or the league-less doors | Save card | `@handle` change → native alert; guide sheet |
| 6b | Settings pane (`SettingsPane`) | pane 1 | `NOTIFICATIONS` (4 pills + footnote) · `APPEARANCE` (segmented) · `PALETTE` (13 rows) · `MEMBERSHIP` (`PLAN · FREE` stub) · (league-less doors) · `How it works` (5 rows) · `Privacy · Terms · Prize pool` · `Sign out` · `DANGER ZONE` `Delete my account` (two-step) · `Cup Season · v1 · build n` (long-press → Developer) | Sign out (only full-width button) | guide sheets; legal links; sign-out; delete |
| 6c | Developer section | 1-s long press on the build line | `Developer`: `📈 Open the desk` / `✏️ Field note` (founder) · `💬 Tell us how it's going` (everyone) | feedback | sheets |
| 7 | **Tell us how it's going** (`FeedbackSheet`) | 6c; `links.openFeedback` (unwired on You at tip) | eyebrow, 4 category pills, editor, `Send`, `Goes straight to Jerecho…` | Send | Close |
| 8 | **Field note** / **Founder's desk** | 6c (founder) | note editor / stat grid + lists | Save note / read | Close |
| 9 | Guide sheets ×4 + **How scoring works** | 6b `How it works`; card pane link; welcome sheet; league room | `The four places` · `Leagues vs events` · `Posting a round` · `Buddies, invites and claims` · scoring (bands card) | read | dismiss |
| 10 | **Add golfers** picker (`PeoplePickerSheet`) | wizard lock-share, Ryder/Major rooms, `presenter.inviteTo` (Clubhouse "Add golfers" for a Pro) | `Add golfers · Invited golfers get a notification and choose to join` (or `Search the app or your buddies`); search field; buddies listed when empty; `Add` / `In` / `Added ✓`; `Share an invite link instead` | Add | Done |
| 11 | **Buddy requests** (`BuddyRequests`) | Home (top, no head) and People (`Requests · n`) | `NAME ✦ Founder · @handle · wants to be golf buddies` · `Accept` · `×` | Accept | row → Tour Card |
| 12 | **Invites banner** (`InvitesBanner`) + Details | Home top | `League invite · PIGL` / `Ryder invite · Desert Ryder` · `from Galen · first tee 2026-09-12` · `Accept` · `Details` | Accept | Details sheet → `Accept & join` / `Decline` |
| 13 | **Join a league** (`JoinLeagueFlow`) → **Covenant** → **Welcome** | Home ⊕ menu `Join with a code`; league-less doors; universal link | `Join a league · I HAVE A LEAGUE CODE` · field · `Join`; then `Before you join PIGL · THE FINE PRINT, UP FRONT` (BUY-IN / PRESET / PARTICIPATION FLOOR / FINISH) · `Join — I'm in for $50` / `Not now`; then `Welcome to PIGL · THREE THINGS TO KNOW` + `Share the invite link` | Join | Clubhouse (onJoined) |
| 14 | **Last round with** card | You, under the buddies door, threshold-fired | `You and **Cole** — last card together 14 months ago.` · `3 rounds shared · one tap stages a Saturday` · `Stage it` · `Later` | Stage it | declare sheet prefilled |
| 15 | **Display case** (`TrophyCaseView`) | You | dusk-ground grid of tiles (`🏆 The Sunday Cup · Champion · '26`, `🔥 Broke 80 · 79 gross · '26`); empty: `No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here.` | tile → receipt (milestones only) | receipt |
| 16 | **Rivalries · all leagues** (`RivalriesSection`) | You, under `This season · League` | rows: marker, gold name if christened, `Galen`, `3 weeks head-to-head · Ryder duels 2–1`, `3–2` + `YOU LEAD`, `→` | row → **Tour Card** (not the rivalry) | Tour Card |
| 17 | **Every season** (`LeagueRecordView`) | You, last | `⚑ PIGL · SEASON II · 3RD OF 12 · 41 PTS →` | row → Clubhouse room | Clubhouse |
| 18 | **Membership** (`MembershipCard`) | Settings | flag off (prod): `PLAN  FREE` · `Everything is free — every league, every event, every round. No trial, nothing to enter.`; flag on: per-league Founding badge / `Year 1 — This year is free` chips / paid line + `Your golfer profile is free forever.` | none (nothing tappable) | — |
| 19 | **League pass** cards (`PricingPassCard` wizard stakes step; `PotPassCard` pot pane, Pro) | flag on only | `The league pass · One pass, the whole league… $89 · ≈ $7.40 a player…` + `✓ Your first year is free.` / `League pass · Pro only · Year 1 — free. ~~$89~~` | none | — |
| 20 | **Palette** dial (`LookPaletteDial`) | Settings | `Follow the calendar` · `Fescue only` · 9 calendar looks · `Turned on by the season` · 2 disabled phase looks | pick | — |
| 21 | **Dress the room** (`LookRoomSection`) | League pane (Pro) | disclosure `Dress the room · Calendar` | pick | — |

Routing facts (SAW): the You stack owns three routes — `.people`, `.settings`, `.addGhin` (`MainTabView.swift:88, 212-224`); the Tour Card, feedback, desk, note, and the invite picker are app-level sheets (`:340-359`); `youLinks.openFeedback` exists but nothing on You calls it at tip (`YouLinks.swift:12`, `YouScreen.swift` — no reference).

**Where the social graph actually changes a screen (SAW, exhaustive for the app):**
1. Tour Card visibility — accepted buddy OR shared league OR shared event OR `discoverable='everyone'` (`20260902180000:75-86`).
2. `search_golfers` — a `discoverable='friends'` profile is returned only to accepted buddies; ordering buddies → league mates → handle-prefix → name (`20260717194623:36-50`).
3. Home's `home_feed` circle = buddies ∪ league mates (`20260723090000:26-30`); Home labels it "Around your buddies" (`HomeView.swift:108`).
4. Schedule watch list `In your crew's plans`: `BUDDY` vs `LEAGUE MATE` tag (`ScheduleScreen.swift:77,210`); `declare_round` tag guard "buddies and league mates" (D178).
5. Live setup roster and Event stage picker seed from `my_friends` (`LiveSetupView.swift:690`, `EventStagePicker.swift:56`); the invite picker's empty state lists buddies (`PeoplePickerSheet.swift:119-121`).
6. Up-next chip `Needs you · n` counts requests (`UpNextChips.swift:88-95`); the app badge (`PushBadge`) counts them.
7. `last_round_with` — NOT the graph: live-round partners and scan claims only (`20260724110000:20-60`).
8. Rivalries — NOT the graph: shared-league co-posting weeks (`20260716010000:27-34`). A buddy who shares no league is never a rival.

**What a profile tells, own vs Jake's (SAW):** own You = identity + index + milestones + FORM + case + all-time stats + last 5 rounds + season strip + rivalries + season list. Jake's Tour Card = identity + index + ≤3 milestones (achievements only — no cups/crowns, `20260902180000:133-136`) + FORM + weekly-clash W-L-T chip + career (rounds/best/avg) + home course + GHIN + last 5 rounds + mute. **Not on Jake's card:** which leagues/seasons you share, rounds played together, the rivalry's name, his season hardware, "you've both played" (the server emits `courses` and `shared_courses` — migration tail keys `'courses'`, `'shared_courses'`; `TourCard.parse` reads neither, `TourCard.swift:93-126`; the web renders `You've both played` at `index.html:15553`).

---

## 2 · Flows

### F1 · "Who am I here and how am I doing?" (open You)
- **Goal:** see myself, my standing, my people, what's next.
- **Friction (SAW):** the page is three screens of record under two group heads; standing (`Every season`) is the last section; `Rivalries` sits below a four-row stats strip (`YouScreen.swift:117-190`). For 16/39 golfers the record is one empty line and a Post button.
- **Unnecessary complexity:** two stat panels with identical row names (`Rounds posted`, `Best vs your playing number`, `Avg vs your playing number`) differing only by head (`All time` / `This season · PIGL`), each with a scope sub (`across 4 counting rounds`) (`YouSections.swift:99-105, 234-237`).
- **Terminology (quoted):** `Handicap index` ✓ golf; `Best vs your playing number`, `Avg vs your playing number`, `across 4 counting rounds`, `No counting rounds yet`, `Index move ▲ 1.2 · SEASON TO DATE`, `Needs 2 rounds this season`, `Leagues & events · PLAYED IN`, `Building your number`, `SEASON II · 3RD OF 12 · 41 PTS`, `Rivalries · all leagues`, `FORM`. "Playing number" and "counting rounds" are the engine's words (allowance, counting cap).
- **Dead ends:** `+N more in the case` chip expands in place (fine); `Leagues & events · Played in 2` is a figure with no door (M-135 still open).
- **Redundant:** `Your buddies` door + Home's `YOUR BUDDIES ↗` + ⊕ `Find golfers` all open the same screen (fine as doors, but the You door's sub is the only one that says anything).
- **Missing feedback:** the buddies door never says how many buddies you have or who they are (`:99-101` only counts requests).
- **Delight opportunities:** the hero is already the best object in the app; FORM with a key and the trophy engraving (`TrophyTileView` needle cover) are real moments. A streak tag `3 STRAIGHT UNDER` exists in the model (`FormRow.tag`) — is it rendered on You? `FormRowView` is CSDesign's; not verified.

### F2 · "Look at Jake" (Tour Card)
- **Goal:** the brief's example — record, head-to-head, recent rounds, seasons together, a reason to needle him.
- **Friction:** the card opens as a sheet from any name (good), but the story stops at a W-L-T chip that only exists if you have co-posted weeks in a shared season (`20260902180000:151-169`). No shared leagues, no rounds together, no rivalry name, no hardware.
- **Complexity:** `Career · vs their playing number` eyebrow + `Best round` / `Avg` rows + `Lower is better against the course; against their number, + is better.` fallback line (`TourCardSheet.swift:108-122`) — the lens machinery leaks.
- **Terminology:** `VS YOU · 3–2 · YOU LEAD` (what is 3–2 of?), `85 GROSS · PAPAGO GC · VS COURSE 7.8` (a raw differential figure), `Add buddy`, `Buddies`, `Requested`, `Accept buddy request`, `🔇 Mute — hide their posts from your boards`, `Report photo` / `Sure? Report this photo` / `Reported — the founder desk sees it`.
- **Dead ends:** `PRIVATE` card has no `Add buddy` (the one act that would open it); own card has no share.
- **Redundant:** own Tour Card repeats the You hero with a different frame (`THIS IS HOW YOUR BUDDIES SEE YOU`).
- **Missing feedback:** after `Add buddy` the toast says `Request sent` and the button becomes a `Requested` tag; nothing says what Jake sees next.
- **Delight:** the VS chip is the seed of the whole brief — a christened rivalry name in gold on the chip, "you've both played Papago", "4 seasons together" would make this the JAKE screen.

### F3 · Find and add a buddy
- **Goal:** connect a friend in seconds.
- **Friction:** entry is a door on the fourth tab or a ⊕-menu item; onboarding on the phone never asks "who do you play with?" (`OrientationScreen.swift:9-12,137` — the web's crew step is not ported; the shot `7-crew-step.png` is the WEB).
- **Complexity:** search is good (1 letter, buddies first, 350 ms). But "Findable by Buddies" makes you unfindable to any NEW friend (`20260712010000:83-84`: `friends` mode returns you only to already-accepted buddies) — the label promises the opposite.
- **Terminology:** `Find golfers`, `Search by name or @handle`, `No golfers found under that name. They may not be on Cup Season yet.`, `Add` / `Accept` / `Buddies` / `Requested` / `Wants to add you`, `Findable by · All · Buddies · Nobody`, `Who can find you in search. Invite links always work.`
- **Dead ends:** a league-less golfer who searches and finds nobody gets a sentence and no door (`PeopleScreen.swift:71-73, 112-129`: the invite row renders only when a membership carries a code). Strangers in the invite picker get a plain `Add` (D118's "Not a buddy / exact @handle" rule is not built on either client — grep finds no such string).
- **Redundant:** `Findable by` on People AND on the card pane (`CardAndSettingsScreen.swift:353-368`).
- **Missing feedback:** `Requested` section is inert — no withdraw; no unfriend anywhere (`unfriend` RPC exists and is granted, `20260712010000:120-124,144`; zero app or web references).
- **Delight:** `friend_request` auto-accepts when the other side asked first (`Golf buddies ✓` instantly) — a nice touch already there.

### F4 · Answer a request or an invite
- **Goal:** say yes to a person.
- **Friction:** none for buddy requests — top of Home and People, `Accept` / `×`, `Golf buddies ✓`. Good (D177).
- **Invites:** `League invite · PIGL · from Galen · Accept · Details` — one tap joins. `respond_invite` inserts into `league_members` with no covenant (`20260830300000_join_window.sql` respond_invite body: insert at ~line 207, no buy-in check), and `InvitesBanner.respond` goes straight to `openLeague` (`InvitesBanner.swift:84-90`) — no Welcome sheet, so the `You're on the pot sheet: $50 buy-in` line (`JoinLeagueFlow.swift:186`) is never shown on this path.
- **Terminology:** `Ryder invite`, `first tee 2026-09-12` (raw ISO), `A Ryder event — two teams, vs-index duels.` (`PeopleModels.swift:129-141`).

### F5 · Invite someone not on the app
- **Goal:** bring a friend in.
- **Current:** only a LEAGUE join link (`Send an invite link · PIGL · WORKS FOR ANYONE, ACCOUNT OR NOT`), via ShareLink with `WizardCopy.inviteText`; multi-league → Menu. No person-level invite (D177: "a buddy-invite link is a different mechanic and would need a decision"). D136 Q-07 declined contact invites.
- **Dead end:** league-less golfer → no link at all (see F3).

### F6 · Rivalry — see it, read the receipts, name it
- **Goal:** "I want to beat Jake."
- **Path (SAW):** You › Rivalries row → Tour Card → `VS YOU` chip → You vs Galen sheet → `Name this rivalry` → naming sheet. Four surfaces to name it; the You row that shows the gold name opens the card, not the sheet (`RivalriesSection.swift:26`).
- **Data (SAW):** a rivalry exists only when both of you posted a ranked round in the same ISO week of a shared season (`20260716010000:27-53`), or from Ryder duels. Naming requires that history (`20260716210000:47-50`). 0 named rivalries in prod; 20 of 39 profiles carry one; 65 pairs exist.
- **Two verdict rules:** `my_rivalries` compares raw `max(pvi)` per ISO Monday week (`:36, 56-59`); the weekly clash keys to the league's first-tee weekday window and decides by BAND (`20260829091000:33-42, 136-142`). The card's `3–2` and the board's clash results can disagree for the same pair.
- **Terminology:** `3 weeks head-to-head`, `Ryder duels 2–1`, `WK OF JUL 6`, `WON / LOST / HALVED`, `YOU +1.2 · GALEN −0.4`, `BEST ROUND VS YOUR PLAYING NUMBER THAT WEEK`, `No head-to-head weeks yet. A clash counts a week you both post.`
- **Missing feedback:** the epilogue tells you a clash counted (`PostEpilogue.swift:78-83`) but does not open the rivalry; the name you gave is not shown on the chip.
- **Delight:** `Give it a name your crew would actually say — “The Grudge,” “Border War.”` is the right voice; the mechanic just needs a front door.

### F7 · Edit my card
- **Goal:** name, photo, marker, handle, city/home course, GHIN, index.
- **Friction:** one long form; the 14-tile marker grid is the tallest block and sits above the photo (`CardAndSettingsScreen.swift:292-333`); photo uploads immediately while text needs `Save card` (two commit models on one form); the handle change raises a native `.alert` with four sentences (`:68-79`) in an app whose IOS-003 §4 bans alerts (every other confirm is a two-tap arm).
- **Terminology:** `NAME ON THE CARD`, `BALL MARKER · Your icon on the board and in the standings — add a photo and it rides in the corner of your card.` ✓, `HANDLE · 60-DAY LOCK`, `FINDABLE BY`, `GHIN # · OPTIONAL · A reference on your card — we never resell or verify it.`, `Save card` ↔ `Save changes`, `Your number is the engine's now · 12.4`, `It builds from your posted scores (best of your recent rounds, WHS-style) and moves as you post.`, `Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed.`, `Index looks off: expected -10 to 54`, `Index updated to 12.4, posted to your league boards`.
- **Dead ends:** `Your leagues · PIGL  PRO · THEPTCQ5` rows are inert (`:419-427`).
- **Missing feedback:** `Save card` with nothing changed toasts `Card saved` (M-141 still open, `:380`).

### F8 · Settings
- **Goal:** notifications, look, account.
- **Count (SAW):** Settings pane = 4 notification pills + footnote, 3-way appearance, a 13-row palette dial, membership stub, (3 league-less doors), 5 guide rows, 3 legal links, Sign out, Delete (2-step), build line (+3 developer rows) ≈ **33 controls**; card pane ≈ **26** (3 text fields, 14 marker tiles, photo 2–3, handle, 3 findable, GHIN, save, index field+button, guide link, N league rows). Roughly 60 controls behind one ⚙.
- **Belongs elsewhere:** Palette (a decor pick, 13 rows → one row + sheet, or the Looks belong with the Clubhouse room it dresses); `How it works` (help, not settings — it is also reachable from the welcome and the room); `Your leagues` (the Clubhouse); the index editor (the You hero owns the number); `Findable by` (People owns reach); the membership stub (nothing to show while free).
- **Terminology:** `Round pings: ON`, `Chat pings: ON`, `Season email: ON`, `Enable on this device`, `Moments, reveals, and month closes always come through.`, `Danger zone`, `Prize pool` (legal link), `Cup Season · v1 · build 669`.
- **Missing feedback:** pills read `ON` while the device has no token (1 token in prod; `SettingsPane:488-496` reads `vm.notifyRounds`, not `push.enabled`) — M-136 still open.

### F9 · Feedback and the founder's desk
- **Goal (tester):** tell the owner something.
- **Path:** Settings › scroll to the last line › press and hold 1 s › `Tell us how it's going`. `feedback` has 0 rows in prod. The web shows a visible chip on You (`index.html:3053`). `YouLinks.openFeedback` is wired by the shell (`MainTabView.swift:492`) but unused by `YouScreen`.

### F10 · Join a league by code
- **Goal:** get in.
- **Friction:** small; `league_by_code` → covenant (fails closed) → join → welcome. The covenant rows `BUY-IN · $50 / player · on the pot sheet`, `PRESET · Standard`, `PARTICIPATION FLOOR · 2 rounds / mo`, `FINISH · Cup Final · final 4 weeks` (`JoinLeague.swift:79-87`) are the wizard's dials read back; "preset" and "floor" are the mechanics the brief says a joiner must not need.
- **Terminology:** `I HAVE A LEAGUE CODE`, `No league with that code — check with your Pro` (a first-timer has no "Pro"), `Join — I'm in for $50`, `THE FINE PRINT, UP FRONT`, `THREE THINGS TO KNOW`, `You're on the pot sheet`.
- **Delight:** the Welcome's three rules and `Who else plays with you? … any member's link works.` + share button are exactly the brief's "funnel casual → recurring".

### F11 · Pricing appears
- **SAW:** three cards, one flag, `visible=false` in prod, `founding.ids={}`. `MembershipCard` under Settings › Membership (stub today), `PricingPassCard` inside the wizard's stakes step, `PotPassCard` on the pot pane for the Pro. Nothing is tappable; nothing gates a feature; no paywall exists. D183 parks the question at 1,000 golfers. The only place a price could ever sit inside a value flow is the wizard card (mid-creation) — dormant.
- **Copy at rest:** `PLAN · FREE · Everything is free — every league, every event, every round. No trial, nothing to enter.` (`MembershipCard.swift:42-45`) — durable and true (D183).

### F12 · Last round with
- **Goal:** a reunion nudge that never reads as guilt (D63).
- **SAW:** `You and **Cole** — last card together 14 months ago.` · `3 rounds shared · one tap stages a Saturday` · `Stage it` / `Later`; 90-day device-local quiet. Fires only off final live rounds and scan claims (`20260724110000:24-45`) — a Saturday foursome that posts from the tee sheet but never scores live never qualifies. `Stage it` prefills next Saturday regardless of the pair's habits.

---

## 3 · Findings

Five-question key — **Q1** what is happening · **Q2** why it matters to me · **Q3** what I can do right now · **Q4** who I am competing with · **Q5** what happens next.

**YP-01 · A league-less golfer cannot invite anyone, anywhere — P0.** SAW: `inviteLink` renders only when `shareables` (memberships with a code) is non-empty (`PeopleScreen.swift:112-129, 167-169`); the empty-search line for that golfer is `No golfers found under that name. They may not be on Cup Season yet.` with no door (`:71-73`); the picker's `Share an invite link instead` needs a league too (`PeoplePickerSheet.swift:50-60`). PROD: 14 of 39 golfers are in no league. Damages Q3, Q4 and the brief's "friend connection" metric on the largest new-user class. → A person-level invite (share your card / "play with me" link) that lands on the app and pre-stages a buddy request; the league link stays for leagues.

**YP-02 · "I want to beat Jake" has no verb — rivalries are a by-product, never an intent — P1.** SAW: a rivalry exists only when both posted a ranked round in the same ISO week of a shared season, or a Ryder duel resolved (`20260716010000:27-53`, `20260716210000:111-124`); naming requires that history (`:47-50`). A buddy in no shared league is never a rival; nothing lets you name a target. PROD: 0 named rivalries; 20/39 profiles carry one at all. Damages Q4, Q5. → "Challenge a friend" as a first-class object (the brief's COMPETE), with the clash record as its receipts; naming allowed before history (a name is intent, the record is proof).

**YP-03 · Jake's Tour Card does not tell his story with you — P1.** SAW: the card renders identity, index, ≤3 milestone chips, FORM, a W-L-T chip, career averages, home course, GHIN, five rounds, mute (`TourCardSheet.swift:65-139`). It does not show shared leagues/seasons, rounds together, his season hardware (`trophies` = achievements only, `20260902180000:133-136`), or "you've both played" — the server emits `courses` and `shared_courses` and the phone discards both (`TourCard.swift:93-126`; the web renders `You've both played`, `index.html:15461,15553`). Damages Q4, Q2. → Card = the relationship: seasons together, head-to-head, the rivalry's name, both-played courses, his cups; own stats second.

**YP-04 · The rivalry row opens the wrong thing, and the receipts are three taps deep — P1.** SAW: `RivalriesSection` row → `openTourCard` (`RivalriesSection.swift:26`); the weeks and `Name this rivalry` are reachable only via the card's `VS YOU` chip (`TourCardSheet.swift:81-86`). Damages Q4, Q5. → Row opens the rivalry; the rivalry sheet carries the card door, not the reverse.

**YP-05 · A christened rivalry loses its name on the Tour Card path — P2.** SAW: the chip's `RivalryLine` is built with `rivalryName: nil, lead: .even` (`TourCardSheet.swift:83-84`); `RivalrySheet.currentName` starts nil and is only refreshed after the naming sheet closes (`RivalriesSection.swift:87-90, 143-148`); `VsChip` never shows the name. The You row shows it in gold, then its tap discards it. Damages Q4. → Pass the `my_rivalries` row through; put the name on the chip ("THE GRUDGE · 3–2 · YOU LEAD").

**YP-06 · The phone never asks "who do you play with?" — P1 (cross-area: onboarding).** SAW: `OrientationScreen.swift:9-12,137` — "the phone has no crew step, so the league-less doors sit here"; the buddies funnel starts on a door on the fourth tab. The `7-crew-step.png` shot is the web. Damages Q4 at minute one. → Ask it at the card gate (handle already required), with the search and the invite from YP-01.

**YP-07 · You is record-first; standing, rivals and "next" are at the bottom or absent — P1.** SAW: order is hero → buddies door → LRW → `Your golf` (case, all-time, recent) → `Your seasons` (strip, rivalries, seasons) (`YouScreen.swift:86-190`); a league-less You has no competitive content at all (`:175-184`). Prior audit 3.19 "should dominate: index + league record + rivalries" — rivalries and standing are still last. Damages Q1, Q4, Q5. → ME = card + standing + rivals + next round; the archive (all-time, every season) below a fold or behind a `Record` door.

**YP-08 · The empty card (16/39 in prod) says "not yet" and offers one verb — P1.** SAW: `⛳ No rounds yet — your card fills as you play.` + `Post your first round` (`YouScreen.swift:138`, `Career.swift:168-169`); the buddies door sub reads `Find golfers, see who you play with` whether you have 0 or 12 buddies (`:99-101`); no people, no next round, no league on the page. Damages Q3, Q4. → The empty You is an invitation: who you play with (faces), a round to plan, a league to join — before a stat that is a dash.

**YP-09 · Your buddies is a flat list, not the COMMUNITY the brief names — P1.** SAW: sections Requests / search / Buddies / Requested / Findable (`PeopleScreen.swift:31-47`); rows are marker + `@handle · City` (`PeopleModels.swift:68-71`, `Links.swift:166` — marker only, never the photo); no league mates, no recent opponents, no "played 3 rounds together", no rankings. Damages Q4. → People = your circle grouped by relationship (buddies · league mates · recent playing partners) with one line of shared history each.

**YP-10 · Strangers get a plain `Add` in the invite picker — D118 is not built — P1.** SAW: `PeoplePickerSheet.action` invite mode → `In` / `Added ✓` / `CSMini("Add")` for every hit (`:90-99`); no "Not a buddy" or exact-handle rule exists in either client (grep: zero hits); `discoverable` defaults `everyone` (`20260712010000:16`). PROD: 24/39 discoverable to everyone. Damages Q4 (and the money-league consent posture). → Build D118 A: non-buddies addable only on exact `@handle`, labelled.

**YP-11 · "Findable by · Buddies" means "findable by nobody new" — P2.** SAW: `search_golfers` returns a `friends`-mode profile only when `f.status='accepted'` (`20260712010000:83-84`, unchanged in `20260717194623:39-40`); the label promises buddies can find you but a new friend cannot become one. PROD: 0 profiles use it. Damages Q3. → Either "Buddies and league mates" semantics, or drop the middle option.

**YP-12 · Home's one-tap `Accept` on a league invite joins a stake league with no covenant — P1 (cross-area: join).** SAW: `respond_invite` inserts the member directly (`20260830300000_join_window.sql`, respond_invite body); `InvitesBanner.respond` → `openLeague` with no Welcome sheet (`InvitesBanner.swift:84-90`), so the `You're on the pot sheet: $50 buy-in` sentence (`JoinLeagueFlow.swift:186`) is never shown on this path; the `Details` sheet says `A season-long league. Invited by Galen` — no number (`PeopleModels.swift:137-141`). Damages Q2, Q5. → The banner's Accept runs the same covenant/welcome as the code door.

**YP-13 · Notification pills read `ON` while the device is off — P2 (prior M-136, still open).** SAW: `pill("Round pings: \(vm.notifyRounds ? "ON" : "OFF")")` reads the profile flag, not `push.enabled` (`CardAndSettingsScreen.swift:488-496`); `Enable on this device` is a pill among pills; the footnote names `Moments, reveals, and month closes` — none defined on screen. PROD: 1 device token for 39 profiles. Damages Q5 (the brief's "notifications create anticipation" cannot start). → One switch, then preferences that disable until it is on; name the categories in the golfer's words.

**YP-14 · The Tour Card prints a raw differential next to a course name — P2.** SAW: `"VS COURSE " + differential` (`TourCardSheet.swift:127-129`) while the same round on You reads `+2.4 vs your playing number` (`YouSections.swift:186-193`); brand canon §3: named bands, never math jargon. Damages Q2. → One figure per round on both surfaces, the band name or the signed "vs number".

**YP-15 · One round mints two "Broke N" milestones and the case reads padded — P2 (prior M-079, by design at tip).** SAW: `-- award EVERY threshold newly crossed (not just the headline)` (`20260716020000_achievements.sql:150-161`); the App Store shot `05-you.png` shows `Broke 100 · 80 gross` beside `Broke 90 · 80 gross`. Damages Q2 (the first celebration reads as the app not knowing you). → Headline threshold per round; the lower ones implied.

**YP-16 · The hero's largest glyph on an empty card is a fraction — P2.** SAW: `0 of 3` in `CSFont.hero` under `HANDICAP INDEX` (`YouHero.swift:78-85`, `Career.establishing`), shot `9-you.png` (web, same design). Damages Q1 for the first-time user ("0 of 3 what?"). → Lead with a golf fact you already have (home course, buddies, next round); the meter as a footnote until it is a number.

**YP-17 · "Card" means five things — P2 (prior M-061, still open).** SAW: the profile (`What your buddies see`, `Card & settings`), the record (`your card fills as you play`, `Rounds on the card`), the Tour Card, shared rounds (`last card together`, `3 rounds shared`), the scorecard (`Scan the card`), the card gate. Damages Q1. → "Profile"/"Tour Card" for the person, "record" for the log, "scorecard" always explicit.

**YP-18 · Settings is a 33-control drawer with a 13-row paint chart in the middle — P2.** SAW: `SettingsPane` (`CardAndSettingsScreen.swift:485-609`): Palette dial = calendar + Fescue + 9 looks + 2 disabled (`LookRows.swift:20-33`, `Looks.swift:42-43`) sits above Membership, How it works, legal, Sign out, Delete. Damages Q3 (the settings a golfer needs — notifications, account — are buried under decor). → One `Look` row → sheet; help out of settings; membership hidden while free.

**YP-19 · The card pane is five kinds of thing under one Save — P2.** SAW: identity (name, photo, marker), reach (handle, findable), reference (GHIN), the engine (index editor + `How scoring works →`), and an inert `Your leagues` list (`:283-441`); photo commits immediately, text on `Save card`; `Save card`/`Save changes` label flip and a no-op `Card saved` toast (`:380`, M-141 open). Damages Q3. → Identity only; index on the hero; leagues in the Clubhouse; reach in People.

**YP-20 · Index copy speaks for the engine — P2.** SAW: `Your number is the engine's now · 12.4`, `It builds from your posted scores (best of your recent rounds, WHS-style) and moves as you post.`, `Set it here to seed a starter; once you have 3 rounds your scores take over. Changes are announced on your league boards, crew-policed.` (`:390-405`); "crew" was retired by D80. Damages Q2. → "Your index comes from your rounds. Have one already? Enter it to start; after three rounds yours takes over."

**YP-21 · Stats vocabulary on You is the engine's — P2.** SAW: `Best vs your playing number`, `Avg vs your playing number`, `across 4 counting rounds`, `No counting rounds yet`, `Index move`, `Leagues & events · PLAYED IN`, `Rivalries · all leagues` (`Career.swift:134-168`, `YouSections.swift`). Damages Q2 — a first-timer must understand allowance and the counting cap to read the page. → Show bands and streaks ("beat your number 4 of your last 5"), not means over a lens.

**YP-22 · The rivalry record and the weekly clash disagree by construction — P2.** SAW: `my_rivalries` uses `date_trunc('week')` (ISO Monday) and raw `pvi` ties (`20260716010000:36, 56-59`); `settle_week_clash` uses the league's first-tee window and the BAND (`20260829091000:33-42, 136-142`). One pair can be `3–2` on the card and have lost the only clash the board ever announced. Damages Q4 (trust). → One week and one verdict rule; the clash becomes a facet of the rivalry.

**YP-23 · Rivalry copy is a mechanic in capitals — P2 (prior M-127, partly open).** SAW: `3 weeks head-to-head · Ryder duels 2–1`, `WK OF JUL 6 · WON · YOU +1.2 · GALEN −0.4 · BEST ROUND VS YOUR PLAYING NUMBER THAT WEEK`, `WEEKLY CLASH · BETTER ROUND VS YOUR PLAYING NUMBER TAKES THE WEEK` (`Rivalries.swift:33-36, 108-110`). Damages Q2. → "Week of Jul 6 — you took it, 78 to his 84" (gross plus the band word).

**YP-24 · The PRIVATE card is a dead end with no Add buddy — P2.** SAW: `This golfer keeps their card private, or you don't share a league yet.` and nothing else (`TourCardSheet.swift:37-38`); buddying is the act that would open it (`20260902180000:77-78`). Damages Q3. → Keep the buddy action on a private card; say "Add them as a buddy and you'll see it."

**YP-25 · No way to remove a buddy or withdraw a request — P2.** SAW: `unfriend` RPC granted and unused (`20260712010000:120-124,144`; zero references in `apps/ios` and `index.html`); the `Requested` section renders inert rows (`PeopleScreen.swift:185-194`). Damages Q3. → A quiet `Remove` on the Tour Card; a `Withdraw` on Requested.

**YP-26 · GHIN sits on the buddy-visible card — P2 (prior M-151, open).** SAW: `MathRow(label: "GHIN", value: g)` on any visible Tour Card (`TourCardSheet.swift:114`) and `GHIN 1234567 · est.` on the hero anchor (`YouScreen.swift:256-257`); the settings copy says only `A reference on your card — we never resell or verify it.` PROD: 4/39 have one. → Owner-only, or an explicit "show my GHIN" choice.

**YP-27 · Feedback is behind a one-second long press on the build line — P2.** SAW: `.onLongPressGesture(minimumDuration: 1)` on `Cup Season · v1 · build n` reveals `Tell us how it's going` (`CardAndSettingsScreen.swift:590-607`); `YouLinks.openFeedback` is wired (`MainTabView.swift:492`) and never rendered on You. PROD: 0 rows in `feedback` with build 669 in external testers' hands. → A visible door for testers (the web's chip, `index.html:3053`), removable at launch.

**YP-28 · The handle change is the app's one native alert, and the label is a lock — P2.** SAW: `.alert("Change your @handle?")` with four sentences (`:68-79`); label `Handle · 60-day lock` (`:348`); IOS-003 §4 "never an alert" governs every other confirm. Damages Q5 (the consequence list is right, the vessel is wrong). → The two-tap arm the app already uses, with the same four lines.

**YP-29 · Covenant rows read the wizard's dials back — P2.** SAW: `PRESET · Standard`, `PARTICIPATION FLOOR · 2 rounds / mo`, `FINISH · Cup Final · final 4 weeks` (`JoinLeague.swift:81-85`, `JoinLeagueFlow.swift:135-138`). Damages Q2 — the brief says a joiner needs none of preset/floor/finish. → Money, dates, who, and one sentence on how it ends; the dials behind `League rules`.

**YP-30 · "Check with your Pro" to someone who has no Pro — P3.** SAW: `No league with that code — check with your Pro` (`JoinLeagueFlow.swift:96`), `JoinService.joinError` (`JoinLeague.swift:116`). → "…ask whoever sent it."

**YP-31 · Raw ISO dates in the invite banner — P3 (prior M-083, partly open).** SAW: `first tee 2026-09-12` (`PeopleModels.swift:131-141`). → `Sat Sep 12`.

**YP-32 · The People rows never show a face — P3.** SAW: `RoomLineRow` → `CSFace(marker:size:)` with no `photoURL` (`Links.swift:166`); `MembersSheet` passes avatars (`MembersSheet.swift:61`). PROD: 1 photo in the book, so low today. → Same face component everywhere.

**YP-33 · `Findable by` lives in two places — P3.** SAW: People foot (`PeopleScreen.swift:201-212`) and the card pane (`CardAndSettingsScreen.swift:353-368`), two chromes. Brand canon "one fact, one place". → People only.

**YP-34 · `Your leagues · PRO · CODE` rows are inert and print the join code under identity — P3.** SAW: `CardAndSettingsScreen.swift:419-427`. → Drop, or make them doors to the room.

**YP-35 · Rivalries are gated on having a league though the read is league-independent — P3.** SAW: `if league != nil { … RivalriesSection }` (`YouScreen.swift:180-184`) vs `my_rivalries()` (no league arg, includes Ryder duels). → Gate on the rows.

**YP-36 · Own Tour Card cannot be shared — P3.** SAW: `p.isMe` hides the buddy action and offers nothing else (`TourCardSheet.swift:89`); the brief's marketing is shareable artifacts. → Share sheet on the own card (image + link).

**YP-37 · Mute closes the sheet and wears emoji — P3.** SAW: `dismiss()` inside `toggleMute` (`:200`), labels `🔇 Mute — hide their posts from your boards` / `🔈 Unmute — show their posts again` (`:134`). → Stay on the card; text label.

**YP-38 · Two empty-case sentences across the clients — P3.** SAW: phone `No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here.` (`TrophyMeta.swift:164`) vs web (D160) `The case is empty — for now. Cups, crowns and event wins hang here when you take them.` (`9-you.png`). → One string, one owner.

**YP-39 · `Last round with` fires only off live rounds and scan claims — P3.** SAW: `20260724110000:24-45` (no tee-sheet or shared-week evidence); copy `last card together`, `one tap stages a Saturday`, `Stage it` (`LastRoundWith.swift:29-32`, `YouSections.swift:32-33`). → Count tagged tee-sheet rounds; "Plan a round with Cole".

**YP-40 · "Around your buddies" is buddies plus league mates — P3.** SAW: `home_feed` circle (`20260723090000:26-30`) vs the head `Around your buddies` (`HomeView.swift:108`) and the empty line `No rounds from your buddies yet…`. The user's mental model of "buddies" and the app's are not the same set. → "Your circle" or say both.

**YP-41 · The App Store screenshots show a build that tip has moved past — P2 (process).** SAW: `05-you.png`/`06-settings.png` carry six retired strings (listed at the top). Either the shots are stale for submission or build 669 is; I could not tell which. → Reshoot from the submitted build; keep the shot set in the ship checklist.

**YP-42 · `Danger zone`, `Round pings`, `Chat pings`, `Prize pool` — P3.** SAW: `CardAndSettingsScreen.swift:492-493, 549, 555`. SaaS/console words in the one screen that is meant to be the golfer's own. → "Notifications about rounds / chat"; "If you leave"; "The pot" (legal).

**YP-43 · Milestone `Personal best` wears 📉 and reads `7.8 vs course` — P3 (prior M-135 partly open).** SAW: `TrophyMeta.swift:52, 70`. → An up-and-to-the-right glyph; "best round yet · 79".

**YP-44 · The buddies door does not report the buddy count — P3.** SAW: sub is either `Find golfers, see who you play with` or `n requests waiting` (`YouScreen.swift:99-101`); `reqs` loads only requests. → "12 buddies · 1 request".

**YP-45 · `Add golfers` is the title of both picker modes — P3.** SAW: `PeoplePickerSheet.swift:31-36` (`Search the app or your buddies` / `Invited golfers get a notification and choose to join`). → "Add buddies" vs "Invite to PIGL".

**YP-46 · The marker grid outranks the photograph on the identity form — P3.** SAW: 14 tiles then `YOUR PHOTO` (`CardAndSettingsScreen.swift:292-333`), while D202 gives the photo the card. PROD: 1 photo in 39. → Photo first, marker second.

**YP-47 · `PeopleModel.respond` is dead code kept "deliberately" — P3 (implementation).** SAW: `PeopleScreen.swift:291-305`. → Delete on the next sweep, as the comment itself says.

**YP-48 · The wizard is the one place a price can ever sit inside a creation flow — P3 (dormant).** SAW: `PricingPassCard` mounts on the stakes step (`PricingPassCard.swift:24-47`); flag off in prod, D183 parks it. No interruption of value today; noting where it would land if flipped. → When it returns, after the lock, never mid-form.

**YP-49 · Founding tags are undefined for the people who see them — P3.** SAW: `✦ Founder` / `✦ Founding member` on rows, cards and the hero (`FoundingTag.swift`, `PeopleScreen.swift:239`); no explanation anywhere in the app. → A one-line meaning on tap.

**YP-50 · Notification permission is asked as a device toggle in Settings — P2 (cross-area: notifications).** SAW: `PushAsk` fires on `cardSaved`, `firstRound`, `leagueJoined` (`PushAsk.swift:78-80`) — three good moments — but the Settings surface is `Enable on this device` → `Notifications on. The board will find you.` (`PushService.swift:133`). PROD: 1 token. Damages Q5. → Ask at the first moment that creates anticipation (a buddy accepted, a round planned), in the golfer's words; Settings only as the fallback.

---

## 4 · What already serves the brief (keep)

- **Every name is a door.** The Tour Card opens from 23 call sites (`grep openTourCard`, Board/Standings/Schedule/Live/Ryder/Major/People/Rivalries) as one sheet (`MainTabView.swift:340`). Q4's plumbing exists.
- **The hero object.** Photo owns the card, marker is the crest when there is none (`CredentialFace.swift`), gold index only once earned (`YouHero.swift:80`), trophy chips with an in-place `+N more` / `Show fewer` (`:116-123`), FORM with its key sentence (`Career.swift:187-208`). Premium, golf-first, no card-in-card (IOS-019).
- **Buddy requests reach you where you are** — one renderer, two homes, `Accept` / `×`, `Golf buddies ✓`, mutual intent auto-accepts (`BuddyRequests.swift`, `20260712010000:97-103`).
- **Search is right**: one letter, buddies → league mates → handle → name, 350 ms debounce, 10 rows (`20260717194623`, `PeopleScreen.swift:271-279`).
- **The buddies door sits directly under the hero** and reports `n requests waiting` (D176/D177, `YouScreen.swift:96-103`).
- **Loading honesty**: placeholder bars, one `Retry` line, a failed block says `Did not load` rather than "not yet" (`YouScreen.swift:121, 167`, `YouSections.swift:99-105`).
- **The trophy engraving** — a new tile takes its name behind a gold needle once (`TrophyCaseView.swift:86-97, 109-113`) — a real moment, reduce-motion aware.
- **The rivalry naming voice**: `Give it a name your crew would actually say — “The Grudge,” “Border War.” Either of you can change it later.` (`Rivalries.swift:111`); the misuse valve (either side renames/clears) is the right mechanic.
- **The Welcome sheet** — three rules, `How scoring works →`, `Who else plays with you? … any member's link works.` + share (`JoinLeagueFlow.swift:181-207`): the funnel the brief describes, already written.
- **The invite link names its league** and works for anyone; multi-league becomes a menu (`PeopleScreen.swift:112-129`).
- **Handle safety** — abandoned handles are held, reclaimable by you, four consequences stated before the change (D159; `20260830290000`).
- **Delete account copy** tells the truth about what stays (`CardAndSettingsScreen.swift:568`); the two-step arm with a VoiceOver announcement.
- **Pricing never interrupts value**: one flag, three inert cards, `visible=false`, a durable free line (`MembershipCard.swift:42-45`, D183); the pot fine print keeps the pass and the pot in separate sentences (`PotPassCard.swift:50-58`).
- **Deleted rounds keep standings whole** ("Former member", `delete_round`), and the You delete is a two-tap arm in a line, not an alert (`YouSections.swift:151-170`).
- **`Last round with`** is threshold-only, in-app only, never streak grammar (D63 held; `LastRoundWith.swift`).
- **The developer/founder tooling is out of the golfer's way** (`PolishDeveloperSection`) — the correct instinct even though it swallowed the feedback door (YP-27).

---

## 5 · What I could not determine from reading

- **Which build the App Store screenshots came from**, and whether TestFlight 669 carries tip's You copy or the screenshots' (YP-41). Only a device or the archive's build number answers it.
- **Whether `FormRowView` renders the streak tag** (`FormRow.tag` = `3 STRAIGHT UNDER`) on You/the card — the view lives in CSDesign and I did not read it.
- **How the badge count (`PushBadge`) composes** requests + invites, and whether a buddy request push actually lands (the `friendships` webhook is "where wired", `20260827210000:96`; one device token in prod means it has effectively never been exercised on iOS).
- **Whether D118 was consciously deferred or dropped** — the decision is logged as recommended, no build note exists, no string exists in either client.
- **The web's You/People at tip** — I read only the strings I needed (`index.html:3053, 15461, 15553`); IOS-018 names the web as reference but the phone has moved past it on this tab, and I did not map the web's current state.
- **How many of the 65 rivalry pairs a real user would recognise as rivals** — the read-only query mirrors `my_rivalries` but I did not sample who they are.
- **Whether the epilogue's `Your clash this week counted` line links anywhere** (`PostEpilogue.swift:78-83` builds copy; the sheet is another reader's).
- **The 15 `discoverable='nobody'` profiles** — test accounts or real golfers who opted out; the count alone does not say which, and it changes how much YP-11 matters.
- **Whether `Stage it` on the reunion card can address a partner who is in no shared league** (declare's tag guard is "buddies and league mates"; a scan-claim partner may be neither).
