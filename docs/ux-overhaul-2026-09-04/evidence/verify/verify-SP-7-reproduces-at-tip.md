# Verify SP-7 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

**Verdict: HOLDS.** Every load-bearing claim reproduces in the shipping phone client at tip; the web mirrors it. Nine evidence details need amending (Section 3). Read-only prod queries (`supabase db query --linked`) confirmed the two data-layer claims the statement depends on.

Everything under SAW was read in the file at tip; INFER is marked.

## 1. What I tried to refute, and what the code does

### 1.1 The four tabs and the frozen names — SAW
- `MainTabView.swift:128` `enum Tab: Hashable { case home, clubhouse, post, you }`; labels "Home" `:165`, "Clubhouse" `:202`, "Post" `:209`, "You" `:226`. File header `:1` "the four places (D82, IOS-011): Home · Clubhouse · ⊕ · You."
- `IOS-002-architecture.md:47` "Canon: the four places (D82) — Home · Clubhouse · ⊕ · You. Tab order and names do not change."
- `decision-log.md:13-15` level 3 = "the IA blueprint (four questions; Home / Clubhouse / ⊕ / You — IA P5 retired the Crew tab …)"; `:20-21` "Changes at level N require only level-N authority unless they leak upward."
- `spec/handoffs/ia-blueprint.html:168` "🏆 Compete — Where do I stand?"; `:169` the ⊕ slot is "Golf — I'm playing"; `:175` "'Compete' is the clear choice; 'Cups' is the on-brand alternative". `decision-log.md:175` (D11) '"Clubhouse" retires from copy.' The Crew→Clubhouse change is credited to "IA P5" (`decision-log.md:14`, `:2749-2751`), which in the blueprint is "P5 · Retire the People tab" (`ia-blueprint.html:347`) — a blueprint phase, not a D-entry, and it never names "Clubhouse". CC-04's "no entry records the rename" stands.
- Web: `index.html:3909-3912` tabbar Home · Clubhouse · Post (`data-v="record"`, aria-label "Post a round") · You.

### 1.2 Clubhouse = one leagues row's room — SAW
- `MainTabView.swift:174` `ClubhouseView(leagueId: store.preferredLeague, paged: true, …)`; `ClubhouseView.swift:1-2` "the Clubhouse tab: the league room for the open league (IOS-002 §5)"; `:40` renders `leagueless` doors when `me.memberships.isEmpty` (title "Clubhouse", `:155`).
- Per page: `EventChips` above `LeagueRoomScreen` (`ClubhouseView.swift:86-93`). Dots `:47`/`:118-134` + swipe pager `:48-54`; toolbar `arrow.left.arrow.right` menu `:67-77`.
- Six panes: `RoomBits.swift:223-226` `enum RoomPane … standings, board, schedule, pot, album, league`. Board/Schedule intercepted as doors: `LeagueRoomScreen.swift:129-137` (`case .board: links.openBoard(); case .schedule: links.openSchedule()`); the pane switch renders `EmptyView()` for both `:73-74`. Pot hidden at $0 `:127`.
- Schedule leaves the league: `ClubRoute.schedule → ScheduleScreen(links:)` with no league id (`MainTabView.swift:152, 181`); `ScheduleScreen.swift:34` "Your golf calendar · yours, your buddies', your leagues'"; `:336` week lines read the *preferred* league (`cur?.phase == "season"`).
- Strip: `CSDesign/Surfaces.swift:220-259` `CSTabStrip` is `ScrollView(.horizontal, showsIndicators: false)`; `:256` comment "a tab is never clipped, only off to the right".
- `HomeRoute.league` / `openLeague` land on Standings: `MainTabView.swift:152-156` (`ClubhouseView(leagueId:)` with default `pane: .standings`, `ClubhouseView.swift:29`), `:454-458` `openLeague` sets `preferredLeague`, clears `clubPath`, `tab = .clubhouse`. `HomeView.swift:789-808` the whole hero is one door "Opens the table".

### 1.3 The hero is the row — SAW
`LeagueRoomScreen.swift:157-210` (`LeagueHeaderCard`): name `:161` · `LeagueCopy.phaseHeader` `:164` · code chip as ShareLink `:170-177` (hidden in setup, D161) · `phaseSub` uppercased `:180-181` · `"\(spanText) · THE PRO · \(proName)"` `:183` · "Add golfers" `:187-189` · danger link `:192-201` **only when `model.isPro && !model.isComplete`** · its note `:204-207`.
- Strings (`Kit/League/LeagueCopy.swift`): `phaseSub` `:231-240` = "SETUP · LOCK THE BYLAWS TO OPEN INVITES" / "Squads drawing · rosters pending" / "BEFORE FIRST TEE · <date> · N DAYS" / "CUP FINAL · Wk N / M · fresh slate · <preset> rules" / "Wk N / M · <format> · <preset> rules". `danger` `:275-280` = "Cancel & delete this league" (pre-tee) / "Cancel this league". `kickoff` `:269-272` = "KICKS OFF IN N DAYS · SQUADS LOCKED · PRACTICE ROUNDS HIT YOUR CARD, NOT THE SEASON" with **no solo branch** (Persona E's "SQUADS LOCKED in a solo league" reproduces).
- Web twin: `index.html:3623-3635` `#hubHeader` name · phase · "Code · SNDYCUP" · span · "THE PRO · JERECHO" · "Add golfers" · "Cancel & delete this league".

### 1.4 Rank is below the fold; the pane is a KPI dashboard — SAW
- `StandingsPane.swift:20-27` dispatches on `model.clock.phase` (setup checklist / draft hero / season body). Season body `:82-126`: [PhaseHero at starter `:84-87`] [wrappedHero `:88`] [Cup Final PhaseHero `:89-91`] → `RoomSeasonStrip` `:93` → `PressMeter` (mid-season) `:94` → `NextCard` `:96` → `onTheLine` (stake>0) `:97` → head "Season race · the climb" `:98` → `ClimbView` `:99` → Standings head/table `:106-109` → "The individual race · every player" `:110-111` → code chip + Add golfers footer `:112-125` (live only).
- Nothing above `ClimbView` carries the viewer's rank: the strip's four columns are Season / The pot / Your index / Counting rounds (`:189-215`); the hero has no rank (`phaseHeader` `:225-228`). Rank first appears at `ClimbView.swift:58` `"You · \(r.team.name)"`, then again in the table and the race (three lists, `StandingsPane.swift:98-111`).
- Four-KPI strip `RoomSeasonStrip` `:173-244`, with the header comment claiming "Not a grid of tiles (IOS-003 §4)" — `IOS-003-design-direction.md:146-148` "Do not … a dashboard grid of KPI tiles (one hero, one lane)".
- Duplication with Home (CH-08) reproduces: Home hero eyebrow "week N of M" (`HomeView.swift:886`), figure = ordinal rank `:903`, `foots` = rule · endgame · money `:988-992`, owe `:995-999`, lead card (clash) `:70-72`, `UpNextChips` `:96-103`, folded notes `:724-770`; the room repeats week (`StandingsPane.swift:189`), rule (`:198-214`, `PressMeter`, `NextCard`), endgame (PhaseHero, cut line), money (`:191-193`, `onTheLine`), clash (`ClashCard` `:332-400`), notes (Board door).

### 1.5 Season as schema phase, no arc — SAW (+ PROD)
- Setup checklist for everyone, member sees "THE PRO" as the trailing label (`StandingsPane.swift:32-47`, `:36`). Draft: one `PhaseHero("Squads are forming", "The Pro has the list.")` for both roles; only the button differs — "Form the squads" / "See the squads" (`:53-58`).
- Wrapped: `if model.isComplete { wrappedHero }` (`:88`, `:129-143` "Season wrapped · <champ> · took the Cup · score · See how it ended · Run it back — Season 2") and then the live body continues: strip (`LeagueCopy.deadline` `:294` "Season complete · settled"), `NextCard` (`nextUp` `:355-365` has **no done branch** — "Post N more rounds this month …" / "<Month> is covered — …"), on the line, climb, table, race. Persona B's three-line contradiction reproduces from code.
- `LeaguePane.swift:1-2, 65-110`: Members & invites · Share the season · Squads · League rules & Pro · notices · cancellation. No past seasons, no archive.
- `native_home` (`20260902200000_the_hero_names_the_leader.sql:95`, `:199-217`): per membership, ONE `season` — "active/cup_final first, else the latest" (`order by (s.status in ('active','cup_final')) desc, s.starts_on desc limit 1`). Carries `champion_squad_id/champion_member_id` but no rank-at-close, no champion name, and never a prior season beside a live one.
- Home: `HomeMode.pool` (`Kit/Models.swift:300-303`) drops every wrapped league whenever any live league exists ("a wrapped league beside a live one is the Clubhouse's, not Home's"). When ALL are wrapped, the hero reads "<name> · season wrapped" · ordinal · "Your name goes on the cup." / "The cup's been lifted. Run it back." (`HomeView.swift:889, 903, 979-981`), no foots (`:990`), no champion name, and its one door is the table (`:803`). "Run it back" is a sentence here; the button lives only in the room (`StandingsPane.swift:140`).
- No `season_story` / `last_season` read exists anywhere (grep over migrations, functions, both clients: zero hits).
- `career_record.seasons_done` = `count(distinct season_id) from season_payouts` (`20260725190000_payout_penny_fixes.sql:156-158`; latest definition — only `20260725100000` precedes it). **PROD (read-only, 2026-09-04): `season_payouts` = 0 rows; seasons = 7 (6 active/cup_final, 1 complete); leagues = 13 (1 complete); events = 1.** So `seasons_done` and `earnings_cents` are 0 for every profile at tip.

### 1.6 Events — SAW (+ PROD)
- Chips above whichever league: `ClubhouseView.swift:87-89`; `EventChips.swift:24-43`. `EventsRepository.myEvents` (`:150-164`) appends every non-complete event attached to any of my leagues as `mine: false`; `EventCopy.chipSub` (`Kit/Events/EventMath.swift:431-433`) prints `"Ryder · Enter the field"` for a non-mine Ryder. The contract has `enter_major` (`contract.psv:133`) and no Ryder join RPC; `RyderRoomView.swift` has no enter/join affordance (only the organizer's "Add golfers" `:145`; "Enter the field" exists only in `MajorRoomView.swift:60`).
- Major gate: `EventPickerSheet.swift:17-18, 28-30, 38` renders the Major row only if `EventFlags.majorEnabled()`; `EventFlags.swift:17-19` requires `app_flags.ios.value.major == true`. **PROD: `app_flags` key `ios` = `{min_build: 0, note: …}` — no `major` key → door shut.** Meanwhile `HomeStream.swift:205` occasion "Set the Major" `go: .event` → `presenter.showEventPicker` (`HomeView.swift:88`).
- Invites: `PeopleModels.swift:115` `startsOn: String?`; `:129` `title = isLeague ? "League invite" : "Ryder invite"`; `:131-134` "from X · first tee \(d)" raw. `create_event` needs 7 positional args + 3 defaulted (`contract.psv:114`). Home reads neither `events` nor `open_duels` (grep of `CupSeason/Home` and `Kit/Home`: zero hits).

### 1.7 The ⊕, orientation, People, You, web — SAW
- Tab "Post" (`MainTabView.swift:209`) → `CSPageHeader("Golf", sub: "Play one live, post one you just finished, or plan the next")` (`PostCoverView.swift:90`) → ember hero "Play now — score the group" (`:95-98`), then "Post a round — after you play" (`:99`), "Plan a tee time — before" (`:101`).
- `OrientationScreen.swift:49-56`: places Home/Clubhouse ("One league: table, board, pot")/Post/You; "The long game · A league" / "The short game · An event".
- `PeopleScreen.swift:26-50`: requests → "Find golfers" field → results → invite link → buddies → requested → findable. Flat.
- `YouScreen.swift:86-190`: hero (card meta, index, rounds, form — `:242-270`) → buddies door → last-round-with → "Your golf" (display case, all time, recent rounds) → "Your seasons" (season strip, rivalries, every season) last.
- Web room: six segments `index.html:3643-3649`; `#room-standings` stacks kickoff hero, live banner, 4 stats, press meter, next card, on the line, climb, cup race, clash, standings, individual trip, ind table, fine, footer (`:3684-3772`); "Your groups" chip strip `:3621-3622`.

## 2. Attempts to refute that failed
- "Maybe the hero already carries rank" — no: `phaseHeader`/`phaseSub` are phase-only (`LeagueCopy.swift:225-240`); rank enters at `ClimbView.swift:58`.
- "Maybe Home shows last season" — only when no live league exists (`Models.swift:300-303`), and then without a name or recap (`HomeView.swift:979-981`).
- "Maybe Board/Schedule are real panes now" — no: `LeagueRoomScreen.swift:73-74, 133-134`.
- "Maybe the Major flag is on" — PROD says no key.
- "Maybe seasons_done is fine in practice" — PROD: 0 payout rows, 1 complete season.
- "Maybe a Ryder has a join path" — contract has only `enter_major`; `RyderRoomView` has none.

## 3. Corrections to the statement / evidence
1. **`native_home.season` is "active/cup_final first, else the latest"** (`20260902200000:199-217`), not "the active season only". The consequence is sharper than stated: a league whose only season is complete reaches Home as `.wrapped`, but `HomeMode.pool` (`Models.swift:300-303`) hides it the moment any live league exists; even when shown, the wrapped hero is an ordinal and one sentence with no champion name, no recap door and no Run-it-back button (`HomeView.swift:889-981`). Replace "no recap, archive or last season on Home" with that.
2. **The "Cancel" link in the hero is Pro-only and hidden once complete** (`LeagueRoomScreen.swift:192`); a member's hero ends at "Add golfers". Persona D (the Pro) saw it; A/B/C/E cannot. The code chip is hidden during setup (`:170`).
3. **"my rank is the seventh block"** is fixture-specific. Above `ClimbView` sit: dots (multi-league), event chips (if any), hero, tab strip, PhaseHero (starter / final / wrapped), season strip, press meter (mid-season), next card, on-the-line (stake>0), climb head. Say "sixth to ninth block depending on phase, stake and league count; never above the strip".
4. **"the sixth clips"** → "the sixth scrolls off-screen with no indicator" (`Surfaces.swift:228, 256`: horizontal ScrollView, `showsIndicators: false`).
5. **"three switchers on one screen"** → "three navigation systems" (SV-13's wording): swipe+dots and the toolbar menu switch leagues (`ClubhouseView.swift:47-54, 67-77`); the pane strip is the third system, not a league switcher.
6. **"draft is the Pro's screen shown to a member"** — same `PhaseHero` and sentence "The Pro has the list." for both, but the button already differs ("See the squads", S3-04, `StandingsPane.swift:58`) and opens a read-only draw. Keep the finding; note the partial mitigation.
7. **"WK 23 / 24 · FRESH SLATE · STANDARD RULES"** is the Cup Final variant of `phaseSub` (`LeagueCopy.swift:237`); mid-season reads "Wk N / M · <format> · <preset> rules" (`:238`), uppercased by `.textCase(.uppercase)` at `LeagueRoomScreen.swift:181`.
8. **`why_structural` cites "season_story" as something to reuse** — it does not exist (grep zero); `my_rivalries`, `career_record`, `trophies`, `tour_card.career` do. Amend to "a new `season_story`/`last_season` read".
9. **The ⊕ drift is the tab label, not the cover:** the blueprint's slot was "Golf — I'm playing" (`ia-blueprint.html:169`), which is the cover's title; "Post" is what shipped on the bar (`MainTabView.swift:209`; web `index.html:3911` with aria-label "Post a round"). Add to CC-05/TM-03.
10. Add the prod figures the argument leans on: 13 leagues · 7 seasons (6 live, 1 complete) · 1 event · 0 `season_payouts` rows · `app_flags.ios` without `major` (2026-09-04, read-only).

## 4. INFER (not verified)
- The exact climb note string "TOP 2 ADVANCE TO THE CUP FINAL" (Persona B/CH-08) — the cut line exists (`ClimbView.swift:2-3`) but I did not read the note's copy.
- Screenshot-only observations (which block is literally "below the fold" on a 6.9" screen) — I reasoned from view order, not pixels.
