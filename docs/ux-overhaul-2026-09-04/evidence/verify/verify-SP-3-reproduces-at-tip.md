# Verify · SP-3 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

Verdict: **HOLDS** in the shipping phone client, with eleven amendments to the evidence lines (none of them reverses the structural claim).

## What I SAW (phone first)

**Doors are nouns; six placements.**
- `apps/ios/CupSeason/Wizard/LeaguelessDoors.swift:28-30` — `door(WizardCopy.joinLeague)`, `door(WizardCopy.startLeague)`, `door(WizardCopy.startEvent)`; strings at `WizardState.swift:462-464` "Start a league" · "Start an event" · "Join a league". `:29` "Start a league" opens `WizardScreen(existingLeagueId: nil)` (`:34-40`).
- Placements: `Onboarding/OrientationScreen.swift:138`, `Clubhouse/ClubhouseView.swift:140` (only when `memberships.isEmpty`, `:40/:80`), `Settings/CardAndSettingsScreen.swift:412` and `:529`, `Home/HomeView.swift:178-190` (Menu: "Start a league" · "Start an event" · "Join with a code" · "Your golf calendar" · "Find golfers" — five mixed items), `HomeView.swift:88` (occasion card `go` → wizard or event picker). Six.
- Post cover: `Post/PostCoverView.swift:95-102` "Play now — score the group" · "Post a round — after you play" · "Plan a tee time — before".
- Web: `index.html:11086-11130` `renderHomeStart` — same three; a member in a league gets "Start something else…" (`:11115-11119`, D119(4)/D136). The phone never collapses: the plus menu is a permanent header control.

**Minting on a name, invite five screens away.**
- `Wizard/WizardScreen.swift:51-55` `leagueId == nil` → `nameSheet`; `:252-268` `create()` calls `svc.createLeague(name:)` → `Rpc.create_league(p_name:p_code:)` (`Generated/Rpc.swift:298-308`; `WizardService.swift:52-56` mints the code from the name). The row exists before any dial.
- Screens: name sheet → step 0 (name + Pro chip, `WizardSteps.swift:11-41`, the creator only) → step 1 (presets + Customize) → step 2 (review) → `WizardLockShareSheet` (`WizardScreen.swift:61-65`, presented only when `model.share` is set inside `lock()` `:290`). `roster` is `svc.memberCount(id)` = 1 (`:247`). Nothing before the share sheet asks who is in. Step-0 Cancel = `deleteLeague` (`:296-303`; copy `WizardState.swift:430` "Cancel this league? … discards it completely").
- Setup room checklist `League/StandingsPane.swift:32-47`: "League setup · three steps to first tee" · "Season settings — The stakes, the rules, the format" · "Invite the crew — One link fills the league — it opens the moment you lock" · "Squad formation — Unlocks when settings lock".

**Presets are the dials' vocabulary.**
- `WizardState.swift:66-73` the three lines verbatim ("95% hcp · post what you'd post to GHIN · best 3 / mo count · 2-round floor"); `:101` `preset: Int = 1` (Standard pre-selected). Help paragraphs `:387,397,399,401,403,405,407` — SEVEN, not six (preset · teams · fill · ends · pot · cap · floor); (i) buttons at `WizardSteps.swift:57,132,141,146,150,156,158`.
- `WizardSteps.swift:58-61` the three cards, the summary, the verification note, THEN "Use these defaults →".
- Review rows `League/LeagueCopy.swift:131-155`: STRUCTURE · Squad formation · PRESET · HANDICAP ALLOWANCE · VERIFICATION · COUNTING CAP · PARTICIPATION FLOOR ("/ mo · deduct/forfeit") · BUY-IN · POT SPLIT · SEASON · CUP FINAL/FINISH.

**Defaults that do not fit a founder.**
- `WizardState.swift:102` `structure: "squads2"`; `:171-179` `structFitLine` → "1 golfer staged — solo fits…". `WizardSteps.swift:133-139` the seg dims non-fitting options but pre-selects 2 Squads.
- Buy-in: `WizardSteps.swift:74` `if model.showDials { dials }`; `:112-114` buy-in is the first row inside. Web `index.html:3516-3523` `#wizDials display:none` holds the buy-in row. `WizardState.swift:101` `stake: Int = 0`.
- First tee: `WizardState.swift:147-154` `defaultStart` = next Saturday, "never today". `:414` `inviteNote` "Lock opens the invite link … The code works until first tee, or until you close the roster." Server `supabase/migrations/20260831190000_roster_door.sql` `_join_gate`: before `starts_on` open; on/after it the code refuses unless the league was locked ON/after first tee (7-day floor, D180). Locked Friday for a Saturday tee = a one-day code. 

**Money.**
- `WizardState.swift:17` `stakes = [0, 25, 50, 75, 100, 150, 200]`; `:126` `stepStake` walks that ladder only. $20 is impossible for the season buy-in.
- `Live/LiveModels.swift:71-78` four stake labels ("Stake per side" · "Dollars per point" · "Bank unit" · "Dollars per skin"); live stake is free text (`LiveSetupView.swift:296`).
- `League/PotPane.swift:189` `SheetFrame("Post a stake", sub: "Pride, on the books — never money")` → `create_forfeit(p_terms text)` (`Rpc.swift:278-296`).
- RPC money shapes: `create_league` carries NO money (`Rpc.swift:298-308`); the buy-in enters at `lock_league p_buyin_cents integer default 0` (`20260902163000_the_first_tee_horn.sql:121`); `create_major p_buy_in Double` (`Rpc.swift:310-330`; Major door flag-hidden, `Events/EventPickerSheet.swift:2-3,28-30`); `start_live_round p_config` JSON (`Rpc.swift:1930-1954`, nine optional args); `create_event` (Ryder) has no money and seven required args (`Rpc.swift:250-276`).

**"Saturday" carries no game or stake; Play now cannot be staged.**
- `Schedule/DeclareRoundSheet.swift:42-74` Day · Tee time · Course · Note · Tag your group; `Rpc.declare_round` (`Rpc.swift:398-416`) `p_play_on, p_course, p_note, p_tagged?, p_tee?, p_course_id?` — no game, no stake.
- `Live/LiveSetupView.swift:24-35` order: plan bridge → course → foursome → game → nearby → "Tee off →". A "2v2 teams / Everyone for themselves" seg exists (`:122-124`) but inside the foursome card and only once a teamable game is picked in the card BELOW it. `LiveRoundStore.swift:472-487` `teeOff()` flips `stage = .live` and calls `start_live_round` in one go; `persist()` (`:625-628`) saves only `state.active && state.lr != nil`, so a staged foursome is never kept. The plan bridge loads only `play_on == today` (`LiveRepository.swift:355-359`) and carries course label + tagged names, no game (`LiveRoundStore.swift:407-420`).

**Run it back = the wizard again, to every member.**
- `LeaguelessDoors.swift:92-110` → `WizardScreen(existingLeagueId: nil, runBack:)`; `WizardRunBack` is name + bylaws only (`WizardScreen.swift:27-31`); `create()` mints a new league + code (`:258-259`). The roster is not carried.
- The gold button every member sees is `StandingsPane.swift:140` (`CSButton("Run it back — Season 2", style: .gold)` gated only on `links.runItBack`, which `ClubhouseView.swift:172` sets for every membership, Pro or not) and `SeasonCeremonyView.swift:67`; host sheet `MainTabView.swift:381-386`. `LeaguelessDoors.swift:23` also has no Pro gate but is unreachable for a member (`ClubhouseView.swift:40`, `CardAndSettingsScreen.swift:446`).

**Prod (read-only, `supabase db query --linked`, 2026-09-04).**
- leagues: setup 6 (all with exactly 1 member) · season 6 · complete 1 → 6 of 13.
- client_events: league_create 2 · lock_attempt 1 · lock_ok 1 · invite_open 1 (lock_blocked 0).
- live_rounds: abandoned 21 · final 5 (26).
- forfeits: 0.
- league_settings.buyin_cents: season 5×7500 + 1×0; complete 1×5000; setup 6×0. buy_in_note: 0 of 13.

## Amendments to the statement / evidence
1. Seven (i) paragraphs, not six.
2. WB-22 "web pre-selects 4 Squads" is the static markup only (`index.html:3540` `class="on"`); runtime state is `structure:'squads2'` (`index.html:4083`). Both clients default to 2 squads.
3. "D113 unbuilt" is stale by half: the $0-default half was built as D196 (2026-09-01) and enforced by `20260902160000_the_defaults_the_wizard_shows.sql:306-324`; prod's six setup leagues are at 0. Only D113's placement half (buy-in row above "Use these defaults →") is unbuilt on both clients.
4. "first tee tomorrow" is the Friday case; the rule is next Saturday, never today. "Code dies at first tee" holds for a league locked before first tee; D180 gives a 7-day floor only when locked on/after it.
5. "$20 impossible" applies to the season buy-in ladder; a live game stake and the (hidden) Major buy-in are free text.
6. "Four money vocabularies" → say: no money on create_league or create_event; cents at lock_league; dollars-double on create_major; a JSON stake with four per-game labels on start_live_round; text terms on create_forfeit.
7. "no 'vs'" → "no opponent-first entry; the 2v2 seg appears inside the foursome card only after a teamable game is chosen below it."
8. Plan bridge: day-of only, course + tagged names, no game (not "course-only", not "a day late").
9. "every creation door … no intent" is true of the league wizard and the Post cover; the Ryder and Major sheets DO stage players before Create (`RyderSetupSheet.swift:103-105,116-118`; `MajorSetupSheet.swift:95,108`) — though after name · teams · sessions · cadence · date.
10. Persona B's gold button: cite `StandingsPane.swift:140` / `SeasonCeremonyView.swift:67` / `ClubhouseView.swift:172`, not `LeaguelessDoors.swift:23`.
11. "PotPane.swift:189 'Post a stake · never money'" is a compression of title "Post a stake" + sub "Pride, on the books — never money".
12. The ~48/~75 term counts are reader CJ's estimate (`reader-create-and-join.md:95`), not recounted here.
