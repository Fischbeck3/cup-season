# Reader · data-layer — what the backend can already tell a user

Finding-id prefix **DL-**. Repo `/Users/fischbeck3/cup-season` at tip `3bba87e`, read 2026-09-04. Read-only throughout; the only prod access was two `supabase db query --linked` count queries (never a write). Line numbers are as of tip. **SAW** = read in code or returned by prod; **INFER** = my reading of what that implies.

Method. (1) Inventoried every `create function / view / table` across the 185 migrations and diffed against `packages/db/contract.psv` (the prod snapshot of signatures + grants). (2) For each surface the brief names, read the LATEST definition (a function is redefined many times; the file cited is the one that wins at tip). (3) Grepped every call site in `apps/ios` (`Rpc.<name>(`) and `index.html` (`rpc('<name>'`) and the direct table reads both clients make. (4) Counted rows in prod to say whether a computable surface is also *populated*.

Two numbers frame everything below (SAW, `contract.psv:1-3`, `Generated/Rpc.swift:1-3`): the database exposes **198 functions, 159 granted to a client role, 12 reachable by anon**. The phone can only name what is granted — `Rpc.swift` is generated from the contract, so an ungranted function does not compile (D37 enforced at build time).

---

## 0 · The prod snapshot the redesign is designing against (read-only, 2026-09-04)

| Table / fact | Rows | Table / fact | Rows |
|---|---:|---|---:|
| profiles (live / deleted) | 39 / 0 | rounds (not voided) | 212 |
| profiles with a handle | 29 | rounds in the last 21 days | 14 |
| profiles with an index | 28 | rounds with **no** `v_rounds_ranked` row (outside any season window / no league) | 26 |
| profiles with a home course | 9 | rounds with a photo / with holes | 1 / 6 |
| profiles with a photo | 1 | profiles with ≥ 1 round / ≥ 5 rounds | 23 / 17 |
| `discoverable` everyone / nobody | 24 / 15 | golfer with rounds and no league | 1 |
| friendships accepted / pending | 12 / 12 | friend pairs with **no shared league** | 6 |
| friend pairs where both have rounds | 10 | pairs of league-mates (any shared league) | 66 |
| leagues (setup / season / complete / sandbox) | 13 (6 / 6 / 1 / 1) | league_members / in ≥ 2 leagues | 46 / 11 |
| seasons active / cup_final / complete | 5 / 1 / 1 | solo-structure leagues | 3 |
| posts total (round / moment / system / chat) | 367 (224 / 85 / 54 / 4) | posts in last 21 days (moments) | 249 (44) |
| post_kudos / post_comments | 5 / 0 | standings_snapshots (seasons covered, max week) | 13 (6, wk 23) |
| week_clashes (open / settled / settled with a winner) | 8 (6 / 2 / **0**) | rivalry_names | **0** |
| trophies / achievements | 8 / 111 | achievements by kind: first_round 23 · sub_100 23 · sub_90 22 · personal_best 20 · streak_4 13 · sub_80 9 · streak_8 1 | |
| scheduled_rounds (future / tagged) | 4 (1 / 3) | round_rsvp / round_comments | 1 / 1 |
| live_rounds by status: abandoned / final / open now | 21 / 5 / 0 | by game: none 13 · match 9 · sunningdale 4 · wolf 0 · skins 0 | |
| live_rounds with no league (D107) | 6 | live_round_players / `game_results` rows | 63 / **0** |
| events (ryder complete) / event_duels / major cards | 1 / 9 / 0 | forfeits | **0** |
| buy_ins (paid) | 36 (28) | season_payouts | **0** |
| device_tokens / push_subscriptions | **1 / 1** | push_nudges by kind: nudge 11 · request 6 · rsvp 1 · invite 0 | |
| growth_events / client_events | 10 / 273 | shares / scan_claims / mutes | 7 / 0 / 1 |
| member_invites pending | 0 | seasons: days left min / max | 0 / 161 |

INFER from this table alone: the social graph exists (12 friendships, 6 of them across no league), the competition history exists inside leagues (224 round posts, 85 moments, 13 snapshots), and every *between-friends* mechanic the brief wants is either empty (0 forfeits, 0 rivalry names, 0 clash winners, 0 game_results) or has no table at all. The push rail reaches exactly one phone.

---

## Section 1 · The map

### 1a · Which screen consumes which data (screen · how reached · what it shows first · primary action · exits)

| Screen (phone unless noted) | Reached | What it shows first (and the data behind it) | Primary action | Exits |
|---|---|---|---|---|
| **Home** (`HomeView.swift:23`) | Tab 1 / cold start | `HomeLeadCard` (clash rung from `home_clash`, :71) → `HomeHero` (standing from `native_home.memberships[].standing`, :74) → `HomeLeagueRows` (:79) → `OccasionCard` (client calendar, :86) → `UpNextChips` (:96) → digest (:116) → feed buckets (`home_feed` rounds + league `posts`, :129) → `UpcomingRoundsSection` (`native_home.upcoming_rounds`, :133) | Post (centre tab) | league room, people, schedule, receipt, Tour Card |
| **Home** (web `view-home`) | tab | `loadHome` `index.html:19231` — `home_feed` (:19241) + `my_friends` (:19297); hero from `renderPulse`/heroCard (:11305) | ⊕ Post | hub, stats, people, schedule |
| **Clubhouse / League room** (`LeagueRoomModel.swift`) | Tab 2 | direct reads of `v_squad_standings`, `v_rounds_ranked`, `v_individual_standings`, `standings_snapshots`, `buy_ins`, `season_payouts` (:207-218); `league_pulse` (:347); `week_clashes` table (:365); `season_scenarios` (:375); `forfeits` (:385) | Board / standings | board, pot, album, event room |
| **Clubhouse** (web `view-hub`) | tab | `loadPulse` :12560, `loadHomeClash` :12188, `loadScenarios` :16948 (→ `#scenarioLine`), `cup_final_race` :16756, `loadStakes` :18936 | board | standings, stakes, pot |
| **You** (`YouScreen.swift:47`) | Tab 4 | `YouHero` (:249, profile from `native_home.profile`) → `LastRoundWithCard` (`last_round_with`, :106) → Display case (`my_trophies` + `my_achievements`, :136) → `CareerRecordView` (`career_record`, :145) → All time `LifetimeTiles` (`tour_card(me).career`, :153) → Recent rounds (:156) → This season strip (:181) → **Rivalries · all leagues** (`my_rivalries`, :183) → Every season (:188) | open a round receipt | Tour Card sheet, receipt, settings, people |
| **You** (web `view-stats`) | tab | `loadTrophies` :19082 (`my_trophies`, `my_achievements`), `loadCareerRecord` :19095, `renderRivalries` :15346 → `#youRivals`, `loadLastRoundWith` :18902 | — | rivalry sheet, tour card |
| **Tour Card sheet** (`TourCardSheet.swift`; kit `TourCard.swift:253`) | any name tap | `tour_card(p_profile)`: profile · career (rounds, best, avg_pvi, best_pvi, avg_vs_index) · trophies · recent 5 · **vs_you** (W-L-T) · courses · shared_courses; rivalry receipts via `rivalry_weeks` (:287); name it via `set_rivalry_name` (:292) | Add buddy (`friend_request`) | — |
| **People** (`PeopleScreen.swift:11`; web `view-people`) | Home → people; You → people | "Find golfers" (`search_golfers`, `PeopleService.swift:43`) → requests (`my_friends` partition, :47) → buddies → "Findable by" (`set_discoverable`) | search / accept | invite link |
| **Schedule / tee sheet** (`ScheduleScreen.swift:13`; web `view-schedule`) | Home → schedule; Clubhouse → schedule | "On the tee sheet" (`my_schedule`, `ScheduleService.swift:19`) → "In your crew's plans" → grid → "Week by week" (`standings_snapshots` direct read, :70) | Declare a round (`declare_round`, :45) | round sheet (`round_detail`, :35; RSVP :50) |
| **Live setup / play** (`LiveSetupView.swift`; web `view-play`) | Post cover → play live | seat picker from `my_friends`, `search_golfers`, `recent_partners` (`LiveRepository.swift:328`), `nearby_resolve` (:342) | start (`start_live_round`) → finish (`finish_live_round`, :188) | scorecard, receipt |
| **Post cover / epilogue** (`PostService.swift`; web `view-post`) | centre tab | after insert: `round_epilogue` (points, month_rank, achievements earned, rivals touched) | Done | receipt (`round_card`) |
| **Event room** (`EventsRepository.swift`; web `view-event`) | Home events row | `events`/`event_sessions`/`event_duels` (RLS reads), `event_session_targets`, `major_leaderboard`, `event_lineage` | post a round | — |
| **Push landing** (`PushRouter`, `docs/ios/push-contract.md:38-48`) | notification tap | 12 kinds → receipt / scorecard / board / live / event / invites banner / requests / round sheet | act from lock screen (accept / in-out) | Home fallback |

INFER: nine screens read from ~30 RPCs and ~20 direct table reads; **Home alone is three reads on the phone** (`native_home`, `home_feed`, raw `posts`) plus one (`home_clash`) per lead league, and the web does the same with more (`my_friends` inside `loadHome`).

### 1b · The inventory — every surface the brief named

Legend for *Grants*: `auth` = authenticated, `anon` = anonymous, `none` = engine/cron/service only (no client can call it). *Scope* = whose data the caller gets back.

#### A · The Home aggregate

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `native_home` | `() → jsonb` (`contract.psv:205`; body `20260902200000`) | `profile{id, display_name, handle, marker, city, home_course, index_current, index_engine, index_source, photo_path, rounds_count, member_since, is_founder}` (:135-150) · `memberships[]{league_id, name, code, phase, sandbox, role, member_id, marker, commissioner_name, settings{structure, preset, counting_cap, participation_floor, floor_penalty, handicap_allowance, buyin_cents, payout_*, finish, locked_at}, season{id, number, starts_on, ends_on, status, timezone, grace_hours, champion_*, points_king_member_id, tiebreak_rung}, squad{id,name,color}, standing{rank, of, points, leader_squad_id/leader_member_id, leader_points, gap_to_leader, gap_to_next, leader_name, runner_up_name, runner_up_points, prev_rank, seed, finalists}, pulse{credits, floor, at_floor, partial}, buy_in{paid, note, due_on, players, paid_count, collected_cents}, roster, members}` (:265-303, :342, :391-460) · `invites[]` (`my_invites`) · `live_round` · `upcoming_rounds[]` = `my_schedule(today, today+14)` (:532) · `events[]` (setup/live I play in or organise) · `open_duels[]` (Ryder, with the number to beat) · `flags{ios, scan}` · `generated_at` (:598-606) | auth (:609) | me + every league I am in | `MeRepository.swift:3-12` (one round trip, typed `Me`) | not called — web composes from many reads |

What it does **not** carry (SAW by absence): any friend data, any feed row, a week number, days-to-first-tee / days-left, the name of the golfer directly above me when I am 3rd or worse, my last round date, any streak, any prior-season summary.

#### B · The feed

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `home_feed` | `(p_days int = 21) → table` (`contract.psv:157`; body `20260723090000_home_feed_photo.sql:15-63`) | per round: `round_id, profile_id, golfer, marker, handle, gross, pvi, played_on, created_at, course, is_pr, is_first, is_sub80, is_me, photo_path`; **circle = me ∪ accepted friends ∪ every league-mate ∪ every event co-player** (:22-35); milestone flags computed by window over the golfer's whole history (:37-46); `pvi = index_at_post − differential` at **100 %** (:51); window `played_on ≥ today − p_days` (:60); **`limit 40`** (:62) | auth (:67) | the circle's rounds | `HomeStream.swift:125` (with `p_days: 21`); rendered by `FeedRoundCard` `HomeView.swift:492` using `CSBands.vsPhrase(r.pvi)` (:523-525) | `loadHome` `index.html:19241` |
| `posts` (table, direct read) | `posts(id, league_id, season_id, event_id, kind, member_id, round_id, live_round_id, push_title, scheduled_round_id, body, created_at)` (baseline `:1196-1205`; `event_id` `20260716160000:26-28`; `live_round_id` `20260729120000:33`; `push_title` `20260727240000:37`; `scheduled_round_id` `20260902203000:34`) | `kind ∈ {chat, round, system, announce, moment}` (`20260715234500:32-35`); **`posts_home_check`: league_id or event_id NOT NULL** (`20260716160000:27-28`) — a post is always homed in a league or an event, never on a person | RLS read: league member / event member / attached league (`20260720193000:98-101`) | my leagues' boards | `HomeStream.swift:150-160` reads `kind ∉ {chat, round}`, `limit 20`, my leagues only | 7 `from('posts')` sites |
| `round_to_board` (trigger) | `() → trigger` (`contract.psv:236`; body `20260727160000_board_voice.sql:56-76`) | on rounds insert: one `kind='round'` post **per league whose active season window contains `played_on`**: "Galen posted 84 at Encanto." (:63-68) — nothing is written for a golfer with no league or a round outside every window | trigger | league boards | via posts | via posts |
| `round_moments` (trigger) | `20260716020000:73-200` (re-created in `20260727160000`, `20260831130000`) | barrier (broke 100/90/80 first time), personal-best differential, iron-man weekly streak (4/8/12) → one `kind='moment'` post per league (:185-192) **and** a row in `achievements` (profile-level, :146-176) | trigger | league boards + my achievements | — | — |
| `squad_lead_moments` (trigger) | `20260716000000:33-101` | "MUDSHARKS MOVED INTO FIRST" when a strict new leader appears; state in `season_lead(season_id, squad_id, since)` (:26-30); solo leagues: lead-change moments added in `20260831160000` | trigger | league board | — | — |
| `post_week_comeback` | `(p_season, p_week) → void` (`20260831130000:44-104`) | from two snapshots three weeks apart, "≥ 15 back three weeks ago, top now" — refuses to print a week number (:37-38) | auth (granted, but only the tick calls it) | league board | — | — |
| `event_post` / `major_post` | `(p_event, p_body) → void` (`contract.psv:135, 185`) | engine narration into an event's board (`20260716160000:45-48`) | **none** | event board | — | — |

#### C · The social graph

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `friendships` (table) | `(id, requester, addressee, status ∈ {pending, accepted}, created_at, responded_at)`, one row per unordered pair (`20260712010000:19-33`) | RLS: own rows only | — | — | — | — |
| `search_golfers` | `(p_q text) → table(profile_id, handle, display_name, city, home_course, marker, index_current, rel)` (`contract.psv:254`; body `20260717194623:19-52`) | substring on handle or name; **hides `discoverable='nobody'` and `friends`-only strangers** (:39-40); buddies first, league-mates second (:44-48); `limit 10` | auth | anyone findable | `PeopleService.swift:43`; `LiveSetupView.swift` | `psSearch` :15243 |
| `friend_request` / `friend_respond` / `unfriend` | `(p_profile) → text ('requested'|'friend')`; `(p_id, p_accept)`; `(p_profile)` (`contract.psv:145-146, 293`; `20260712010000:89-124`; push in `20260827210000`) | mutual intent = instant buddies (:100-102); a decline deletes the row so a fresh ask stays possible | auth | pair | `PeopleService.swift:52`; `TourCard.swift` | :15126 |
| `my_friends` | `() → table(friendship_id, profile_id, handle, display_name, city, marker, index_current, status, incoming)` (`contract.psv:197`; `20260715210000:81-93`) | **carries each friend's `index_current`** (:85) — the only cross-friend number any client holds | auth | my pairs | `PeopleService.swift:47`; `ScheduleService`; `LiveSetupView` | 4 sites incl. `loadHome` :19297 |
| `recent_partners` | `(p_limit = 12) → table(id, handle, display_name, city, home_course, marker, index_current, rel, last_played, rounds_together)` (`contract.psv:214`; `20260830250000:17-73`) | golfers I shared a **live-round seat** with (:31-48), same discoverable gate as search (:68-69) | auth | my seats | `LiveRepository.swift:328` (seat picker only) | `markRegulars` :8469 |
| `nearby_resolve` | `(p_profiles uuid[]) → table(...)` (`20260830250000:84-120`) | of ids handed over Bluetooth, only buddies / league-mates (:99-110) | auth | — | `LiveRepository.swift:342` | — |
| `last_round_with` | `() → table(profile_id, display_name, marker, last_on, shared_cards)` (`contract.psv:168`; `20260724110000`) | the richest lapsed partnership: ≥ 3 shared cards, last ≥ 12 months ago (:55-56) | auth | me | `YouRepository.swift:119` | :18908 |
| `my_invites` / `respond_invite` | `() → table(id, kind, container_id, container_name, inviter, starts_on, created_at)` (`20260713180000:67-84`) | pending league/event invites | auth | me | `PeopleService.swift:76`; Home banner | :… |
| `tour_card` visibility gate | `20260902180000:74-84` | visible if me, accepted friend, shares a league, shares an event, or `discoverable='everyone'` | — | — | — | — |

INFER: friendship changes exactly four things — the Home feed circle, tee-sheet visibility/tagging, Tour Card visibility, and league-invite picking. It changes **nothing competitive**: no record, no ranking, no clash, no stake can exist between two buddies who share no league.

#### D · Rivalries and head-to-head

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `my_rivalries` | `() → table(opponent, display_name, handle, marker, wins, losses, ties, meetings, lead, duel_wins, duel_losses, duel_halves, rivalry_name)` (`contract.psv:201`; body `20260716210000:66-146`) | facet 1: for every **season I share with the opponent**, each ISO week both posted → higher best `v_rounds_ranked.pvi` takes the week (:76-110); facet 2: settled Ryder `event_duels` (:118-128); unioned, ≥ 1 meeting; the pair's christened name (:137-139) | auth | me vs league-mates / duel opponents | `YouRepository.swift:84` → `RivalriesSection.swift` ("Rivalries · all leagues", :21); `RivalryTags.swift` | `renderRivalries` :15351; `ensureRivals` :18428 |
| `rivalry_weeks` | `(p_opponent) → table(wk, my_pvi, opp_pvi, winner ∈ {me, them, halve})` (`20260716010000:75-104`) | the receipts, newest first (:101) | auth | pair | `TourCard.swift:287` → `RivalrySheet` | `openRivalrySheet` :15386 |
| `rivalry_names` + `set_rivalry_name` | `(pair_low, pair_high, name, named_by, named_at)`; `(p_opponent, p_name) → void` (`20260716210000:19-63`) | either rival names/renames/clears; **requires history** (:49-51); 0 rows in prod | auth | pair | `TourCard.swift:292` | :… |
| `tour_card.vs_you` | inside `tour_card` (`20260902180000:151-170`) | the SAME shared-season weekly computation, restated (a second implementation) | auth | pair | Tour Card sheet | `openTourCard` :15449 |
| `week_clashes` (table) | `(id, season_id, week_no, a_member, b_member, opened_at, settled_at, winner_member, a_best, b_best)` (`20260829091000:82-110`) | the engine's one spotlighted pairing per league-week; `a_best/b_best` = the counting round receipts | RLS read: league member; writes engine-only | league | `LeagueRoomModel.swift:365` (direct) | 1 site |
| `open_week_clash` | `(p_season) → uuid` (`contract.psv:210`; latest `20260902170000:45-214`) | pairing cascade: named rivalry → closest table gap → least-recently-featured (rotation) (`20260829091000:20-40`); board post "Best round of the week takes it" (`20260831160000` D176); silent when a two-person league idles (`20260902170000` D207) | **none** (tick) | league | — | — |
| `clash_last_call` | `(p_season) → uuid` (`20260902170000:222`) | final-day post, only if someone has played | none | league | — | — |
| `settle_week_clash` | `(p_season, p_week) → jsonb` (`20260902170000:329-473`) | best band-of-week per side (band via `cup_points`, :368-373), walkover if one idle, ALL SQUARE if equal bands; post "Galen took the week — beat their number by 3.1 on Thursday." (:434-435); rivalry-heat post at 3 and 5 straight (:437-449) | none | league | — | — |
| `home_clash` | `(p_league) → jsonb {week_no, ends_on, days_left, closes_today, them_name, them_marker, mine{round_id, played_on, points, pvi, gross}, theirs{…}, rivalry}` (`20260831160000:471-567`) | **null unless the caller is IN this week's clash** (:468-469) | auth | me | `HomeStream.swift:116` → `HomeLeadCard` | `loadHomeClash` :12188 |
| `forfeits` + `create_forfeit` / `settle_forfeit` / `scrap_forfeit` | table `(league_id, name, terms, kind ∈ {hosts, course_pick, strokes, bounty, custom}, party_a, party_b?, hangs_on, status, winner, settled_*)` (`20260724120000:18-45`); RPCs `contract.psv:115, 277` | **league-scoped**: `is_league_member` and "the other side has to be in the crew" (:60-70); **no money column on purpose** (:10-13); 0 rows in prod | auth | league | `LeagueRoomModel.swift:385` | `loadStakes` :18936 |

#### E · History, career, hardware

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `trophies` + `my_trophies` | table `(profile_id, kind ∈ {ryder, league, major, bracket}, title, subtitle, placement ∈ {winner, runner_up, points_king}, event_id, league_id, season_year, earned_on)` (`20260713200000:10-30`); `() → table(id, kind, title, subtitle, placement, season_year, earned_on)` (:37-45) | minted only at season/event completion; 8 rows | auth (:76) | me | `YouRepository.swift:78` → `TrophyCaseView` | `loadTrophies` :19084 |
| `achievements` + `my_achievements` | table `(profile_id, kind, label, earned_on, round_id, meta)` **`unique (profile_id, kind)`** (`20260716020000:23-33`); `() → table(kind, label, earned_on, meta, round_id)` (`20260902173000:199-213`) | kinds: `first_round`, `sub_100/90/80`, `personal_best` (evolves — the row is overwritten, :168-170), `streak_4/8/12` (forward-only, :174); `round_id` is the receipt; re-derived on round delete (`rederive_achievements`) | auth | me | `YouRepository.swift:114` | :19086 |
| `career_record` | `() → jsonb {cups, runner_ups, crowns, majors, events, trophies, earnings_cents, seasons_done, leagues}` (`20260725190000:138-163`) | `earnings_cents` = exact sum of `season_payouts` (:155); **`seasons_done` = count of seasons that PAID me** (:156-158), not seasons completed | auth | me | `YouRepository.swift:80` → `CareerRecordView` | :19098 |
| `season_payouts` (table) | `(season_id, profile_id, cents, reason)` (`20260725100000:17-24`); written by `award_season_trophies` at close | 0 rows in prod (the one complete season predates D67) | RLS read: league member | league | `LeagueRoomModel.swift:218` | 1 site |
| `tour_card` | `(p_profile) → jsonb {visible, profile{…, is_me}, career{rounds, best (min differential), avg_vs_index (100 %), avg_pvi (allowance lens), best_pvi}, trophies[] (= achievements, not the trophies table), recent[5]{played_on, course_label, gross, differential, holes_played, beat}, vs_you{wins, losses, ties}, courses[]{name, rounds, last_played}, shared_courses[]{name, mine, theirs}}` (`20260902180000:63-220`) | one lens (D209), sim excluded, one row per round | auth | any visible golfer | `TourCard.swift:253`; `LifetimeTiles` on You (self) | :15449 |
| `standings_snapshots` + `snapshot_week` | table `(season_id, week_no, captured_at, standings jsonb{squads[], individuals[]})` (baseline `:1335-1341`); `(p_season) → void` (baseline `:739-767`), run by `run_week_snapshots` (Sunday cron, baseline `:648`) | week = `least(total, floor((today − starts_on)/7.0))` (:749-750) | none | league | `ScheduleService.swift:70` ("Week by week"); `LeagueRoomModel.swift:211`; `native_home` prev_rank (`20260902200000:312-342`) | 1 site |
| `season_lead` (table) | `(season_id, squad_id, since)` (`20260716000000:26-30`) | engine state for lead-change posts; **no client read** | none | — | — | — |
| `event_lineage` | `(p_event) → table(event_id, name, kind, status, starts_on, year, is_current, champion, champ_gross, champ_pvi, winner_slot, winner_team, winner_shared)` (`contract.psv:134`) | the yearly line of a named event (Major/Ryder history) | auth | event | `EventsRepository` | 1 site |
| `season_email_payload` | `(p_season) → jsonb {league, champion, runner_up, points_king, champion_score, runnerup_score, tiebreak, starts_on, ends_on, rows[5]{name, points}, recipients[]{email, name, token, cents}}` (`20260725180000:37-115`) | the ceremony, for the inbox | **service_role only** (:114-115) | league | — | — |

#### F · The season engine (scoring, standings, projections)

| Object | Definition | Key facts | Grants | Consumers |
|---|---|---|---|---|
| `rounds` (table) | baseline `:1244-1270` + `api_course_id`, `photo_path`, `posted_by`, `index_provisional` (`20260902173000:239-243`) | `gross, rating, slope, nine_rating, holes_played ∈ {9,18}, played_on, index_at_post, differential, source ∈ {quick, live}, attested, voided, index_source_at_post ∈ {self, app, ghin}`; differential = `(gross − rating) × 113 / slope` (`20260716100000:75-79`); insert grant is column-sealed (`20260902173000:228-231`) | RLS owner-only read; definer RPCs for everyone else | every scoring surface |
| `v_rounds_ranked` (view) | `20260902100000:85-131` | one row per (round × league-season window); `playing_index = index × allowance/100`; **`pvi = playing_index − differential`** (:98); `points = cup_points(pvi)` (nines halved, :100-101); `floor_credit`; `month_rank` per member-month by points (:127-130); excludes voided, sim (unless allowed), nines (unless allowed), rounds after suspension | security_invoker; read directly by both clients | standings, clash, rivalries, tour_card lens, `home_clash`, `round_card` |
| `v_individual_standings` / `v_squad_standings` | baseline `:1396-1409`, `:1411-1440` | `points = Σ points where month_rank ≤ counting_cap`, `rounds_posted`; squads add `season_adjustments` (floor penalties) | invoker; direct reads | `native_home.standing`, room, scenarios, snapshots |
| `cup_points` | `(p_pvi) → int` baseline `:247-257`: ≥3→12 · ≥1→9 · >−1→7 · ≥−3→6 · else 5 | the five bands; **granted to anon + auth** (baseline `:2587-2588`) | anon, auth | `Rpc.cup_points` generated; band NAMES hand-copied in `20260902170000:368-373`, `CSBands.swift:20-23, 43-46`, `index.html:6198` |
| `handicap_index` / `handicap_index_asof` | `(p_profile) → numeric`; `(p_profile, p_before_date, p_before_id) → numeric` (`20260716100000:29-66`) | WHS-lite over the best of the last 20 differentials, establishes at 3 rounds (:40-52); `round_refresh_index` keeps `profiles.index_current` unless `index_source ∈ {self, ghin}` (:95-105) | auth | `native_home.profile.index_engine` (`20260902200000:145`) |
| `league_pulse` | `(p_league) → table(profile_id, display_name, marker, credits, floor, at_floor, is_me, partial)` (`20260722211500:46-89`) | this calendar month's floor credits per member vs `participation_floor` | auth | `native_home.pulse` (me only); `LeagueRoomModel.swift:347`; `loadPulse` :12560 |
| `season_scenarios` | `(p_season) → jsonb {meta{finish, structure, level, k, seed_end, months_left, locked, cap, status, ends_on}, rows[]{level, id, name, points, max_final, roster, rank, clinched, eliminated, needs}}` (`20260716224500:25-119`) | D24 honesty rule: ceiling = `roster × months_left × cap × 12` (:86); `needs` = points to lock a seat | auth | `LeagueRoomModel.swift:375`; `loadScenarios` :16948 |
| `cup_final_race` | `(p_season) → jsonb {status, season_status, solo, window_start, window_end, cap_n, days_left, finalists[]{seed, head_start, seed_rung, name, color, window_points, rounds_used, last_round_on, total, rounds[]}}` (`20260828170100:61-…`) | the Final as a field of two with receipts | auth | `CupFinalRaceView.swift`; :16756 |
| `standings movement` | — | **no per-round rank delta exists anywhere**; `prev_rank` is the last Sunday snapshot (`20260902200000:312-342`) | — | — |
| `daily_season_tick` | baseline `:263-281`, re-created `20260829091000` (+ clash beats), `20260902163000` (first-tee horn) | opens the Final at `ends_on − 27`, closes at `ends_on + 1 + grace`; opens/settles clashes on the league's local date | none (cron) | — |

#### G · The tee sheet (schedule, RSVP, declare)

| Function | Signature → returns | Key payload | Grants | Scope | Phone | Web |
|---|---|---|---|---|---|---|
| `scheduled_rounds` (table) | `(id, profile_id, play_on, course_label, note, tagged uuid[], tee_time, course_id, league_id)` (`20260712150000:21-28` + later columns) | profile-level plan, not a league fact | RLS: owner; social reads via RPC | — | — | — |
| `my_schedule` | `(p_from, p_to) → table(id, profile_id, display_name, marker, play_on, course_label, note, tee_time, mine, is_friend, shared_league, tagged_names[], tagged_me, course_id, rsvp_in, my_rsvp, comment_n)` (`20260718192400:208-245`) | visible if mine / tagged / accepted friend / league-mate (:236-242) — **already friend-scoped** | auth | my circle's plans | `ScheduleService.swift:19`; `native_home.upcoming_rounds` (14 days) | :18391, :18413 |
| `declare_round` | `(p_play_on, p_course, p_note, p_tagged[] = {}, p_tee = null, p_course_id = null) → uuid` (`20260902203000:46-144`; 5-arg twin kept for skew :146) | ≤ 7 tags (:86-88); **tags only buddies or league-mates** (:89-100); one `system` post per league I am in (:115-125); a `push_nudges` `rsvp` row per tagged golfer: "Galen put you on the tee sheet · Sat Sep 6 · Papago — in or out?" (:127-136) | auth | me → my leagues + tagged | `ScheduleService.swift:45` | :19436 |
| `round_rsvp` + `set_round_rsvp` | `(round_id, profile_id, status ∈ {in, maybe, out})` (`20260718192400:45-58`); `(p_round, p_status)` (:60-70) | anyone who can see the round may RSVP (`can_see_round` :22-38) | auth | round | `ScheduleService.swift:50`; lock-screen `CS_RSVP` | :… |
| `round_comments` + `add_round_comment` | (`20260718192400:73-100`) | the round's own mini board; 1 row in prod | auth | round | `ScheduleService` | :… |
| `round_detail` | `(p_round) → jsonb {id, profile_id, owner_name, owner_marker, mine, play_on, tee_time, note, course_label, course_id, league_id, my_rsvp, course{…}, weather, rsvps[], comments[]}` (`20260718192400:123-…`) | one call for the sheet; weather from `weather_cache` (edge fn) | auth | round | `ScheduleService.swift:35` | :19463 |

#### H · Events (the Ryder, the Major)

| Object | Definition | Key facts | Grants |
|---|---|---|---|
| `events` | `(name, created_by, league_id?, kind ∈ {ryder, major}, status ∈ {setup, live, complete}, starts_on, session_count, session_weeks, draw_rule, allowance, winner_team_id, buy_in, pot_split)` (`20260713120000:12-31`; `20260720193000:39-41`) | may attach to a league (crew + board) or stand alone; **`create_event` needs 7 args, `create_major` needs `final_on, days, buy_in, pot_split`** (`contract.psv:114, 117`) | RLS: member / creator / attached league; `create_*` auth |
| `event_teams`, `event_players`, `event_sessions`, `event_duels` | `20260713120000:33-80` | duels = best PvI in the session window, `result ∈ {pending, a, b, halve}`; `exhibition` flag for players without an established index (D44) | RLS as above |
| `event_major_cards` | `20260720193000:50-63` | frozen placement rows at settle (countback receipts) | RLS |
| `event_session_targets` | `(p_session) → table(duel_id, a_pvi, b_pvi)` | the number to beat, read into `native_home.open_duels` | auth |
| `major_leaderboard` / `major_board` | `(p_event) → table(player_id, profile_id, display_name, marker, exhibition, round_id, gross, pvi, cards, best_posted_at)` | the live board (`major_board` is engine-only) | auth / none |

In prod: **one** event ever (a completed Ryder, 9 duels), zero Majors.

#### I · Live rounds and side games

| Object | Definition | Key facts | Grants | Phone | Web |
|---|---|---|---|---|---|
| `live_rounds` | baseline `:1140-1157`; `league_id`, `season_id`, `started_by` nullable + `starter_profile_id` (`20260829090000:67-72`, D107); `game ∈ {none, match, wolf, skins, sunningdale}` (`20260725220000:24`); `game_config`, `game_result jsonb`, `status ∈ {setup, live, final, abandoned}`, `course_snapshot`, `join_code`, `api_course_id` | a live game needs **no league** since D107 | RLS: league member or participant | `LiveRepository` | `view-play` |
| `live_round_players` | baseline `:1122-1135` + `guest_profile_id`, `claimed_profile` | seats: member / app buddy / guest (claim token) | column-sealed | | |
| `game_results` (table) | baseline `:1032-1037` `(live_round_id, player_id, points, amount_cents)` | **0 rows in prod — dead table**; results are written as JSON into `live_rounds.game_result` (`20260830260000:148, 170`) | RLS | — | — |
| `start_live_round` | `(p_league = null, p_course_id, p_tee_id, p_course_label, p_snapshot, p_game, p_players, p_config, p_api_course_id) → jsonb` (`contract.psv:284`) | leagueless path seats starter + guests + app golfers | auth | `LiveRepository` | :10317-10325 |
| `finish_live_round` | `(p_live_round, p_cards, p_casual = false, p_result = null) → jsonb {posted[], guests[], skipped[], casual}` (`20260830260000:17-181`) | posts one `rounds` row per complete card (unless `p_casual`, :86, :114); side-game settlement story to the league board **only when `league_id` is set** — a leagueless game's story lives only in the share card (`20260829090000:38-39`) | auth | `LiveRepository.swift:188` | :10499 |
| `live_state` / `guest_live_state` / `live_set_score` / `live_set_wolf` / `live_join` / `abandon_live_round` / `my_visitor_rounds` / `live_round_card` | `contract.psv:174-178, 204` | multi-phone sync; the settled scorecard (`live_round_card`) | auth / anon for guest | | |
| `claim_round`, `claim_scan_round`, `create_scan_claim`, `scan_claim_info`, `create_share`, `share_info` | `contract.psv:105-107, 118, 119, 248, 280` | the guest→profile claim loop; share kinds `round, settlement, recap` (`20260722190000:25`) | auth / anon | | |

#### J · The books (money)

| Object | Definition | Key facts |
|---|---|---|
| `buy_ins` | baseline `:885-892` `(season_id, member_id, amount_cents, paid, marked_by, marked_at)`; `mark_buy_in`, `set_buy_in_terms` (`contract.psv:188, 258`) | 36 rows, 28 paid; surfaced as parts on `native_home.buy_in` (D106) |
| `season_payouts` | above | 0 rows |
| `league_settings.buyin_cents / payout_champ / payout_runnerup / payout_king` | baseline `:1073-1103` | defaults now $0 (D113) |
| `events.buy_in / pot_split` | `20260720193000:39-41` | Major pot |

#### K · Telemetry, growth, push

| Object | Definition | Key facts | Grants |
|---|---|---|---|
| `growth_events` + `log_growth_event` | table `(at, node ∈ {artifact_shared, link_opened, claim_started, profile_created, first_round_posted}, kind ∈ {share, claim, join, recap, settlement}, token, league_id, actor, props)` (`20260828160000:48-60`); RPC `(p_node, p_kind, p_token, p_props, p_league)` (:78-…); `v_growth_funnel` (:164) | fail-closed for anon; 10 rows | anon + auth write; nobody reads via API |
| `client_events` | `(profile_id, event ≤ 64 chars, props, created_at)` (`20260717153000:19-35`); `v_pilot_gates` (signup → card → league → first round, :45-76), `v_post_timings` (:78-90) | 273 rows; insert-only for the golfer, operator-read; **no app-open / session event**, so WAU/MAU, D7/D30 are not derivable from it | insert own |
| `device_tokens` + `register_device_token` | `(token, profile_id, platform='ios')` (`20260722013000:82-96`) | **1 row in prod** | auth |
| `push_subscriptions` (web push) | `20260711170000:15` | 1 row | |
| `push_nudges` | `(profile_id, kind ∈ {nudge, invite, request, rsvp}, title, body, payload)` (`20260827210000`) | personal notifications; 18 rows | engine writes |
| The push function | `supabase/functions/push/index.ts`; kinds `round, chat, announce, moment, system, settlement, live_open, nudge, invite, request, rsvp, event` (:100-103); a `system` post with `live_round_id` becomes `settlement` (:142-147); recipients for board posts = **league members minus author, minus muters, honouring `notify_chat / notify_rounds / notify_system`** (:492-540); badge = `actionable_count_of` = pending requests + open invites + open live rounds (`docs/ios/push-contract.md:67-83`) | | |
| Landing table | `docs/ios/push-contract.md:38-48` | 12 kinds → receipt / scorecard / board / live / event / invites banner / requests / round sheet | |
| `my_actionable_count` / `mark_actionable_seen` | `contract.psv:196, 187` | the badge and its "I looked" marker | auth (`PushBadge.swift:21, 38`) |

---

## Section 2 · The flows, as data journeys

### F1 · Post a round → what the server derives → who is told
- **Goal.** "Add my round" is the smallest useful action; the brief wants it trivial and story-producing.
- **What happens (SAW).** Client inserts into `rounds` (column-sealed grant, `20260902173000:228-231`). `score_round` trigger sets differential and the index snapshot (`20260716100000:69-92`); `round_refresh_index` moves my number; `round_to_board` writes one "Galen posted 84 at Encanto." per league whose season window holds the date (`20260727160000:61-70`); `round_moments` writes barrier / PB / streak moments to those same boards **and** to `achievements` (`20260716020000:138-176, 192-198`); `squad_lead_moments` writes a lead-change moment; the posts webhook pushes `round` to league-mates (`push/index.ts:492-540`); `round_epilogue(p_round)` gives the poster points, month_rank, achievements and rivals touched (`20260716210000:150-214`).
- **Friction.** A golfer with no league — or a round outside every window (26 of 212 rounds in prod, 12 %) — produces **no post anywhere**; the only trace friends can see is the `home_feed` row (rounds only, 21 days, 40 rows). Their milestones land in `achievements` but never as a story.
- **Unnecessary complexity.** Three lenses on one round: the board says gross; `home_feed` says `index_at_post − differential` (100 %, `20260723090000:51`); the receipt (`round_card`) and the standings say the allowance-lens `v_rounds_ranked.pvi` (`20260902100000:98`). D123 ordered `home_feed(p_days, p_league)` to return the lens and it was never built (`contract.psv:157` still shows one argument).
- **Confusing terminology (exact strings).** `'Personal best'` with `meta.diff` (a differential, the number the brand canon forbids on user surfaces, `20260716020000:166-167`); `'DIFF '` was retired from the board in `20260727160000` but survives in `achievements.meta`.
- **Dead ends.** `round_epilogue` returns `null` for a round posted under `p_casual` (there is no `rounds` row) — the side-game player never gets an epilogue.
- **Missing feedback.** No rank-before / rank-after (see DL-06). No "you moved past Jake". No "3 straight under 85".
- **Delight available today.** `home_feed.is_pr / is_first / is_sub80` are computed per row by window functions over the golfer's whole history (`20260723090000:37-46`) — a friend's "first round on the card" and "broke 80 — first time" ride the feed already; the phone prints them (`HomeStream.swift:165-167`).

### F2 · Open Home → what a golfer can be told in one screen
- **Goal.** WHAT'S HAPPENING · WHO'S WINNING · WHAT'S NEXT · WHAT CAN I DO, in seconds.
- **What happens (SAW).** Phone: `native_home()` (me + leagues + invites + live + 14-day tee sheet + events + duels) → `home_feed(21)` + a raw `posts` read for my leagues (`HomeStream.swift:125-126, 150-160`) → `home_clash(league)` for the lead league (:116). Web: `loadHome` calls `home_feed` and `my_friends` and composes the hero from client state (`index.html:19231-19300, 11300-11308`).
- **Friction.** Four round-trips for the phone's first paint; the feed is a client-side merge of two differently-shaped sources with a 48-hour dedupe window (`HomeFeedFold.swift:98`); the occasion engine (Masters week etc.) is a hard-coded client calendar (`HomeStream.swift:187-260`).
- **What Home cannot say (SAW by absence).** Who among my friends is playing well; where I rank among friends; who is directly above me (only the leader and the runner-up are named, `20260902200000:266-267, 302-303`); the week number (client-derived, three ways — Section 3, DL-05); days to first tee / days left (client-derived, `Models.swift:270-281`, `index.html:11263`); my last round date; any streak; last season's result.
- **Dead ends.** A golfer with no league and no friends gets `memberships: []`, an empty feed, and `HomeStream.failed == false` — the "empty vs unreadable" distinction exists (`HomeStream.swift:99-101`) but there is no data to fill an *opportunity* state beyond the calendar occasion.
- **Delight available today.** `native_home.standing` already names the leader and the runner-up in the board's voice (`firstname()`), carries `gap_to_next` for everyone and `prev_rank` from the last snapshot; `buy_in` arrives as parts (D106); `open_duels` carries the number to beat; `upcoming_rounds` carries `is_friend`, `tagged_me`, `rsvp_in`.

### F3 · Find a friend → what changes
- **Goal.** Friend connection is a success metric; "who I am competing with" is one of the five questions.
- **What happens (SAW).** `search_golfers` (substring, 10 rows, hides 15 of 39 profiles who set `discoverable='nobody'`) → `friend_request` → push `request` via `push_nudges` (6 rows in prod) → `friend_respond` (lock-screen `CS_REQUEST`).
- **After acceptance, what the data now allows.** Their rounds in my `home_feed`; their plans in `my_schedule`; I may tag them on a tee sheet; their Tour Card opens (`tour_card` gate `:77-79`); I may add them to a league I am the Pro of (`add_friend_to_league`).
- **What it does not allow.** No record (`my_rivalries` needs a shared season, `20260716210000:76-83`); no clash (engine, league-only); no stake (`create_forfeit` needs a crew, `20260724120000:60-70`); no ranking; no challenge. Six of the twelve accepted friendships in prod are exactly this case (no shared league).
- **Confusing terminology.** `rel ∈ {friend, requested, incoming, none}` on search rows vs `status ∈ {pending, accepted}` + `incoming` on `my_friends` — two vocabularies for one relationship (`20260717194623:25-29`; `20260715210000:85-86`).
- **Delight available today.** `my_friends` returns every friend's `index_current` — a friends-by-handicap board is one client sort away (see A-3).

### F4 · The head-to-head record
- **Goal.** "You've beaten Mike 3 of the last 5."
- **What exists (SAW).** For a **league-mate**: `rivalry_weeks(opponent)` returns every shared-season week both posted, newest first, with `winner` (`20260716010000:75-104`) — "3 of the last 5" is `take 5, count me`. `my_rivalries` summarises W-L-T + Ryder duels; the pair may christen it (`set_rivalry_name`, 0 names in prod). `tour_card.vs_you` restates the same W-L-T (`20260902180000:151-170`). `week_clashes.winner_member` is the engine's spotlighted verdict (0 winners in prod: 6 open, 2 settled quiet).
- **What does not exist.** Any meeting outside a shared season window: two buddies who play the same course the same day (posted rounds) — not a meeting; a shared live round with a match-play result (`live_rounds.game_result`) — not a meeting; a Sunningdale/Wolf/Skins settlement — not a meeting. The original design note promised these as "additional facets" (`20260716010000:12-16`); none was built.
- **One fact, three implementations.** The weekly-clash W-L-T is computed in `my_rivalries` (:76-110), `rivalry_weeks` (:75-104) and `tour_card` (:151-170) separately.

### F5 · The week loop (anticipation → verdict)
- **Goal.** Season as a story; the week as an episode (D52).
- **What happens (SAW).** The daily tick opens one clash per league-week (`open_week_clash`), posts "Best round of the week takes it", warns on the last day (`clash_last_call`), settles by band (`settle_week_clash`), posts "Galen took the week — beat their number by 3.1 on Thursday." and, at 3 and 5 straight, a heat line. Only the two golfers named see it on Home (`home_clash` returns null for everyone else, `20260831160000:468-469`).
- **Friction.** Everyone else's Home has no week hook at all. Prod: 8 clashes, all from two-person solo leagues, 0 decided.
- **Confusing terminology.** The band names are hand-copied in five migrations and two clients; the `−1.0` edge already drifted once (`CSBands.swift:10-12`).
- **One-fact hazard.** The week number — see DL-05.

### F6 · The season arc (standings → projections → close → hardware → mail)
- **What exists (SAW).** Live standings (views), Sunday snapshots (13 rows), `season_scenarios` (clinched / eliminated / `needs`, D24 honesty ceiling), `cup_final_race` (the Final with receipts), `close_season` → `award_season_trophies` → `trophies` + `season_payouts` → `season_email_payload` → the recap email (service-role only).
- **Friction.** No "story" read exists: the timeline of lead changes, comebacks, clash verdicts and moments for a season must be reassembled from `posts.moment`, `week_clashes`, `standings_snapshots` and `season_lead` (the last has no client read). `career_record.seasons_done` counts paying seasons only (`20260725190000:156-158`) — a $0 league's alumni have a career of zero seasons.
- **Missing feedback.** A member who finished 3rd last season has that fact in `standings_snapshots`/`trophies` but nowhere in `native_home`.

### F7 · The tee sheet (plans, RSVPs, "who's playing this weekend")
- **What exists (SAW).** `declare_round` with tags (consent-gated), a board post per league, an `rsvp` push to the tagged, `my_schedule` with `is_friend / shared_league / tagged_me / rsvp_in / my_rsvp`, `round_detail` with weather. `native_home.upcoming_rounds` already carries 14 days of the circle's plans.
- **Friction.** 4 declared rounds in the product's life, 1 in the future — the anticipation surface is data-starved, not data-blocked. There is no inference from habit ("you usually play Saturdays") and no "we're playing this weekend" object with identity (a tee sheet row is one golfer's plan with tags, not an event).

### F8 · Live rounds and side games
- **What exists (SAW).** Any signed-in golfer can start Match / Wolf / Skins / Sunningdale with buddies, guests and nearby phones, no league needed (D107, `20260829090000`); finish posts each card as a round and stores the settlement in `live_rounds.game_result` JSON; a leagueless game's story exists only as a share card (:38-39).
- **Friction.** `game_results` (the relational table) is dead (0 rows); no RPC returns "my match-play record" or "Wolf money with Jake"; `recent_partners` counts rounds together but never who won. 21 of 26 live rounds were abandoned.

### F9 · Notifications
- **What exists (SAW).** A routed, actionable, mute-aware push contract with 12 kinds and a badge that counts only actionable items (D104/D179). Recipients of `round`/`moment`/`system` are league members. Personal kinds: `invite`, `request`, `rsvp`, `nudge` (Ryder duel).
- **Friction.** A friend who is not a league-mate is never told I posted (no `posts` row exists for them to be a recipient of). There is no kind for "a friend broke 80", "your clash opened", "you moved to 2nd", "Jake challenged you". One device token in prod means the whole rail is unproven at scale.

### F10 · What the product measures about itself
- `client_events` (post_open / post_submit / post_mode_switch…), `v_pilot_gates` (signup→card→league→first round), `growth_events` (share→claim→profile→first round). **No app-open or view event exists**, so activation, time-to-aha (beyond first round), WAU/MAU, D7/D30 and empty-state engagement are not computable from the schema; `auth.users.last_sign_in_at` is the only proxy (INFER).

---

## Section 3 · Findings

Severity: P0 blocks a goal · P1 major · P2 minor · P3 polish. "Damages" names which of the brief's five questions (what is happening / why it matters to me / what can I do now / who am I competing with / what happens next) the gap hurts.

**DL-01 · P0 · There is no friend-to-friend competition object.** SAW: `friendships` is a visibility relation (`20260712010000:19-33`); the only pair-wise competitive rows are `week_clashes` (engine-picked, league-only, `20260829091000:82-110`), `event_duels` (Ryder, `20260713120000:67-80`) and `forfeits` (crew-only, `20260724120000:60-70`); `posts_home_check` forbids a post that is not in a league or an event (`20260716160000:27-28`). "Jake challenged you" has no table to live in and no push kind (`push/index.ts:100-103`). Damages: what can I do now · who am I competing with. Recommend: a `challenges` table + decision-log entry (Section C-1).

**DL-02 · P1 · "You're #4 among your friends" has no server read.** SAW: no function joins `friendships` to `rounds` or `v_rounds_ranked`; `my_friends` exposes only `index_current` (`20260715210000:85`). Computable by index client-side today; by form (30-day avg PvI) only via a new RPC. Damages: why it matters to me · who am I competing with. Recommend: `friends_board()` (Section B-1); a decision on whether ranking friends by handicap is a surface the canon allows outside a league.

**DL-03 · P1 · The Home feed is rounds-only and the posts read is league-only, so a friend's milestones never reach a golfer who shares no league with them.** SAW: `home_feed` returns rounds (`20260723090000:15-20`) for the whole circle; moments are written only to league boards (`20260716020000:192-198`); the phone reads posts `in("league_id", myLeagues)` (`HomeStream.swift:153`). For 6 of 12 friendships in prod there is no league to share. Damages: what is happening. Recommend: one `home_stories()` union across the circle (Section B-3).

**DL-04 · P1 · One round, two PvI lenses on the same phone screen.** SAW: `home_feed.pvi = index_at_post − differential` (100 %, `20260723090000:51`) is rendered as a band phrase (`HomeView.swift:524-525` via `CSBands.vsPhrase`); the receipt's `round_card.pvi` and every standings figure use `index_at_post × allowance/100 − differential` (`20260902100000:98`). Under the prod-wide 95 % allowance a 13-index golfer's feed line and receipt differ by ~0.7 and can straddle a band. D123 ruled the fix (`home_feed(p_days, p_league)`) on 2026-08-29; `contract.psv:157` shows it unbuilt. Damages: why it matters to me (the number does not close). Recommend: build D123's server half; until then the feed should print gross only.

**DL-05 · P1 · The week number is produced by three server formulas and three client formulas.** SAW: `snapshot_week`: `least(total, floor((today − starts_on)/7.0))` (baseline `:749-750`) — week 1 begins on day 7; `open_week_clash`/`home_clash`/`settle`: `floor((local − starts_on)/7) + 1` (`20260902170000:80`; `20260831160000:511-519`) — week 1 begins on day 0; `sandbox_week`: `max(floor((played_on − starts_on)/7)) + 1` (`20260724200000:24`); web: `Math.floor(Math.round((today − s)/864e5)/7)` (0-based close, `index.html:8111`) and `Math.floor((now − seasonS())/6048e5) + 1` (1-based, `:11305`), plus `Math.ceil` weeks-left (`:11263`); phone: `floor(days/7)+1` and `totalWeeks = ceil(days/7)` (`LeagueDates.swift:31-41`) vs server `ceil((end − start + 1)/7.0)` (`20260902170000:79`). The moments migration itself refuses to print a week number because of this (`20260831130000:20-21, 37-38`). `native_home` carries none. Damages: what happens next (the same board can say "week 5" and "week 4"). Recommend: `native_home.season` gains `week_no`, `weeks_total`, `week_ends_on` from the clash formula; `snapshot_week` adopts it (decision-log, mechanic level); both clients delete their arithmetic.

**DL-06 · P1 · "Movement since your last round" is not computable from any read.** SAW: `standing.prev_rank` is the last Sunday snapshot's rank (`20260902200000:312-342`); `round_epilogue` returns `points` and `month_rank` for the round, not a standing before/after (`20260716210000:150-214`); `season_lead` is squad-only engine state with no client read (`20260716000000:26-30`). Damages: why it matters to me. Recommend: extend `round_epilogue` with `rank_before`, `rank_after`, `passed[]` computed by re-ranking `v_individual_standings`/`v_squad_standings` with the round excluded (Section B-5).

**DL-07 · P1 · The closest competitor is named only for the top two.** SAW: `standing.leader_name`, `runner_up_name`, `runner_up_points` (`20260902200000:266-267, 302-303`); `gap_to_next` is a number with no name for rank ≥ 3. "Win this week and you move to 2nd" needs the row above me and the band ceiling (12). Damages: what happens next. Recommend: add `next_up{name, points}` (and `next_down`) to `standing` — same window query, one more `lag()`.

**DL-08 · P1 · Streaks exist only as forward-only, once-ever weekly "iron man" badges.** SAW: `achievements` is `unique (profile_id, kind)` (`20260716020000:32`), so `streak_4` can be earned once in a career (13 rows in prod); detection is consecutive *weeks with a round* (:120-135), never consecutive scores ("3 straight under 85") or consecutive beat-your-number rounds; nothing is exposed as a *current* streak. Damages: why it matters to me. Recommend: `my_streaks()` over `rounds` (Section B-4); a `streaks` table or dropping the unique constraint for streak kinds (Section C-5).

**DL-09 · P1 · Head-to-head outside a shared league season does not exist, in three separate implementations of the same rule.** SAW: `my_rivalries` (`20260716210000:76-110`), `rivalry_weeks` (`20260716010000:75-104`) and `tour_card.vs_you` (`20260902180000:151-170`) all join `shared seasons` over `v_rounds_ranked`; live-round results (`live_rounds.game_result`), same-day same-course posted rounds, and `week_clashes.winner_member` are never counted. Damages: who am I competing with. Recommend: one `head_to_head(p_opponent)` with named facets (Section B-2) and a decision on what a casual meeting is (Section C-2).

**DL-10 · P2 · "3 friends playing this weekend" is computable and empty.** SAW: `my_schedule` carries `is_friend` and `play_on` (`20260718192400:217-243`) and rides `native_home.upcoming_rounds` (`20260902200000:532`); prod holds 4 declared rounds ever, 1 future. Damages: what happens next. Recommend: keep the read; the redesign's job is to make declaring trivial (pre-fill from habit, from a live-round start, from an RSVP).

**DL-11 · P1 · Season anticipation numbers are client-derived, twice.** SAW: `native_home.season` carries `starts_on / ends_on / status` only; days-to-first-tee, days-left, the Final window (`ends_on − 27`) are computed in `Models.swift:270-281`, `LeagueDates.swift:43-44`, `index.html:11263`; `cup_final_race.days_left` exists only once the Final opens. Damages: what happens next. Recommend: `season.days_to_first_tee`, `days_left`, `final_opens_on`, `phase_label` on `native_home` (Section B-6).

**DL-12 · P2 · Notifications cannot reach a friend, only a league.** SAW: board-post recipients are league members (`push/index.ts:492-540`); personal kinds are `invite / request / rsvp / nudge` (`20260827210000`); no kind for a friend's round, a clash opening, a rank change. One device token in prod. Damages: what is happening (between sessions). Recommend: a `friend_round` / `challenge` / `clash_open` kind on `push_nudges`; treat the single token as "unproven at scale" in every plan.

**DL-13 · P2 · The personal-best row is overwritten, so the history of PBs is lost.** SAW: `on conflict (profile_id, kind) do update set earned_on, round_id, meta` (`20260716020000:168-170`); the board keeps the moment post but the case keeps only the latest. Damages: why it matters to me (Memory > Statistics, vision principle 4). Recommend: an append-only `milestones` log or keep `personal_best` rows keyed by round.

**DL-14 · P2 · `career_record.seasons_done` counts seasons that paid the golfer, not seasons completed.** SAW: `20260725190000:156-158`; with 0 `season_payouts` in prod every golfer's career shows 0 seasons and $0. Damages: why it matters to me (HISTORY). Recommend: `seasons_done` from `seasons.status='complete'` joined to membership; keep `seasons_paid` beside it.

**DL-15 · P2 · Every money "history" surface renders zero.** SAW: `season_payouts` = 0 rows; `earnings_cents` sums it; the one complete season closed before D67 existed. Damages: HISTORY. Recommend: a one-time backfill decision (or an honest "before the ledger" label) before any career/earnings surface ships.

**DL-16 · P2 · 38 % of the base is invisible to search.** SAW: 15 of 39 profiles have `discoverable='nobody'`; `search_golfers` excludes them (`20260717194623:39-40`); `recent_partners` applies the same gate (`20260830250000:68-69`); `tour_card` shows them only to friends/league-mates (`20260902180000:77-83`). INFER: the default was `everyone` (`20260712010000:16`), so 15 golfers chose to hide, or were tombstoned test accounts — I could not tell which. Damages: who am I competing with (COMMUNITY). Recommend: measure before designing "find your friends"; consider a `friends-of-friends` tier.

**DL-17 · P2 · "Who I play with" is only known from live-round seats.** SAW: `recent_partners` reads `live_round_players` (`20260830250000:31-48`); `last_round_with` reads seats + scan claims (`20260724110000:24-52`); the finish migration records that same-course-same-day inference "refused" on the data (`20260830260000:9-11`). Prod: 63 seats, 5 finals. Damages: who am I competing with. Recommend: capture "played with" at post time (tag the group on a quick post, the tee-sheet's `tagged` already exists) rather than infer it.

**DL-18 · P2 · A golfer with no league has no story home.** SAW: `posts_home_check` (`20260716160000:27-28`); `round_moments` inserts posts only via `league_members` (`20260716020000:192-198`); `finish_live_round` skips the board when `league_id` is null (`20260829090000:38-39`). Their `achievements` rows exist (profile-level). Damages: what is happening (the funnel's first rung is silent). Recommend: either a profile-homed post (schema, Section C-4) or synthesise the feed from `achievements` + `home_feed` flags (Section B-3).

**DL-19 · P2 · Side-game results are JSON on the round, and the relational table is dead.** SAW: `game_results` 0 rows (baseline `:1032-1037`); `update live_rounds set game_result = p_result` (`20260830260000:148, 170`); no RPC aggregates it. Damages: who am I competing with (side games). Recommend: `my_side_games()` over `live_rounds.game_result` + `live_round_players` (Section B-7), or repopulate `game_results` at finish.

**DL-20 · P2 · Pride stakes cannot ride a friend challenge.** SAW: `create_forfeit` requires `is_league_member` and a crew-mate opponent (`20260724120000:60-70`); 0 forfeits in prod. Damages: what can I do now ("we want money/pride on it"). Recommend: let a forfeit hang on a `challenge` (Section C-1).

**DL-21 · P3 · Four dormant personality columns on `profiles`.** SAW: `card_quote, the_miss, walk_ride, beverage` (baseline `:1222-1225`); no reference in `index.html`, `apps/ios` or any later migration. Damages: none today. Recommend: reuse or drop; they are candidates for the onboarding's "what golf you play".

**DL-22 · P2 · Onboarding captures name / city / home course / index / marker / photo — nothing about who you play with or what golf you play.** SAW: `set_profile(p_name, p_city, p_home, p_index, p_marker, p_ghin, p_photo_path)` (`contract.psv:274`); `came_via_kind/token` attribution exists (`20260828160000:71-72`); home course set on 9 of 39 profiles. Damages: what can I do now (the first Home). Recommend: the brief's three onboarding questions map to `index_current` (exists), a first `friend_request`/contact match (needs a contacts-hash lookup — new RPC, Section B-9) and a play-style field (Section C-6).

**DL-23 · P1 · Home is assembled from four reads and two client-side merge algorithms.** SAW: `native_home` + `home_feed` + raw `posts` + `home_clash` (`HomeStream.swift:116-141, 150-160`; `MeRepository.swift:3-12`); dedupe/bucketing in `HomeFeedFold.swift`; the web repeats it differently (`index.html:19231-19300`). Damages: what is happening (latency, skew retries, two products that disagree). Recommend: `home_stories()` returns typed, ranked, deduplicated items; `native_home` v3 embeds it or the phone calls two RPCs, never a raw table.

**DL-24 · P2 · The feed and the trophy case disagree on which milestones exist.** SAW: `home_feed` flags `is_pr, is_first, is_sub80` only (`20260723090000:47-56`); `achievements` also holds `sub_100`, `sub_90`, `streak_*`. Damages: what is happening. Recommend: derive feed flags from `achievements.round_id` (one source) instead of re-windowing history per call.

**DL-25 · P2 · Season history depends on a Sunday cron nobody watches from the client.** SAW: `run_week_snapshots` (baseline `:648`); 13 snapshots over 6 seasons, max week 23; `post_week_comeback` bails silently on a missing snapshot (`20260831130000:65-66`); `job_failures` exists (`20260901180000:32`) but is operator-only. Damages: what happens next (the "Week by week" strip has holes). Recommend: snapshot on the clash formula from the daily tick (same day-keying as D213 names), not the Sunday cron.

**DL-26 · P3 · The five band names are copied in seven places.** SAW: `20260902170000:368-373`, `20260829091000:261-264`, `20260831130000:663-666`, `20260831120000:2167-2170`, `20260831160000:354`, `CSBands.swift:43-46`, `index.html:6198`; `cup_points` itself is granted to anon (baseline `:2587`). Damages: none yet; the `−1.0` edge already drifted once (`CSBands.swift:10-12`). Recommend: a `band_name(p_pvi)` SQL function beside `cup_points`, returned on every payload that carries a `pvi`.

**DL-27 · P2 · Home does not know when I last played.** SAW: `native_home.profile` carries `rounds_count` (`20260902200000:148`) but no `last_round_on`; `league_pulse` is month- and league-scoped. Damages: what can I do now (the nudge to post). Recommend: `profile.last_round_on`, `days_since` — one `max(played_on)`.

**DL-28 · P2 · `my_rivalries` requires a league but says "all leagues".** SAW: the phone head reads "Rivalries · all leagues" (`RivalriesSection.swift:21`); the function's `shared` CTE is league-mates only (`20260716210000:76-83`). A buddy is never a rival. Damages: who am I competing with. Recommend: rename the head to what it is until B-2 lands, then "Rivalries".

**DL-29 · P2 · An event with identity needs seven arguments.** SAW: `create_event(p_name, p_starts_on, p_sessions, p_session_weeks, p_draw_rule, p_team_a, p_team_b, …)`, `create_major(p_name, p_final_on, p_days, p_buy_in, p_pot_split, …)` (`contract.psv:114, 117`); one event in the product's life. Damages: what can I do now ("we're playing this weekend"). Recommend: a lightweight `outing` shape (date, course, who) that can *become* a Major or a Ryder (Section C-3).

**DL-30 · P3 · The success metrics the brief names are not measurable from the schema.** SAW: `client_events` has post-composer breadcrumbs only (`20260717153000:19-35`, `v_post_timings :78-90`); `growth_events` has five funnel nodes (`20260828160000:51-52`); no open/view event. Damages: none for the user; blocks the redesign's own scorecard. Recommend: `app_open`, `home_empty_state_seen`, `empty_state_cta_tapped` client events (client-only change; the table already accepts any event ≤ 64 chars).

**DL-31 · P2 · Last season is absent from Home.** SAW: `native_home.memberships[].season` is the active/latest season only (`20260902200000:201-215`); "you finished 3rd, Galen won" lives in `trophies` and `standings_snapshots`. Damages: why it matters to me (season repeat). Recommend: `membership.last_season{number, my_rank, of, champion_name, ended_on}` on `native_home`.

**DL-32 · P2 · The reunion whisper cannot fire for anyone yet.** SAW: `last_round_with` needs ≥ 3 shared cards and ≥ 12 months since (`20260724110000:55-56`); the oldest live round is weeks old. Damages: none; it occupies the top of You (`YouScreen.swift:106`) for nothing. Recommend: keep, but design You without depending on it until 2027.

**DL-33 · P3 · `event_post`, `major_post`, `season_lead`, `season_email_payload`, `snapshot_week`, `open_week_clash`, `settle_week_clash` are engine-only.** SAW: `contract.psv:135, 185, 210, 256, 279, 281` = `none`. Damages: none — this is correct (D37) — but the redesign must not plan a client read of any of them without a granted twin (as `home_clash` is to the clash).

---

## Section 4 · What already serves the brief well (keep)

1. **`native_home()` as one typed round trip** with leader/runner-up names in the board's voice, `gap_to_next`, `prev_rank`, the books as parts, the D207 headcount, the Final's locked seed (`20260902200000:265-303, 342, 430-460`). The hero copy on the phone already says "10 back of Galen" (`HomeHeroCopy.swift:42-62`).
2. **`home_feed`'s circle is already every buddy, league-mate and event co-player** (`20260723090000:22-35`) with per-row milestone flags and photo — the brief's "friend activity across ALL buddies" is true for rounds today.
3. **`my_schedule` is already friend-aware** (`is_friend`, `shared_league`, `tagged_me`, `rsvp_in`, `my_rsvp`, `20260718192400:217-232`) and rides `native_home` for 14 days.
4. **`declare_round`'s consent + push** (tag only buddies/league-mates, RSVP from the lock screen, `20260902203000:89-136`).
5. **`my_rivalries` + `rivalry_weeks` + `rivalry_names`** — a faceted, receipted, nameable record (`20260716210000`, `20260716010000`); the phone renders facets and the christened name in gold (`RivalriesSection.swift:29-31`).
6. **`tour_card.shared_courses` and `courses`** (D150) — "what the two of you have both played" is exactly the rivalry texture the brief wants (`20260902180000:171-208`).
7. **`achievements` with `round_id` receipts, re-derived on delete** (`20260902173000`), and `trophies` minted only by completion.
8. **`season_payouts` recorded as fact at close, never recomputed** (`20260725100000:9-14`), and the ledger line as one constant per client (`spec/brand-canon.md:64-72`).
9. **`season_scenarios`' honesty rule** (never a false "clinched", `20260716224500:10-16`) and **`cup_final_race`** with round receipts.
10. **The weekly clash engine**: pairing cascade with a rotation guarantee, quiet when idle, band-decided, receipted (`20260829091000:20-56`; `20260902170000`).
11. **`home_clash`** as the model for "engine fact → granted, caller-scoped read" (`20260831160000:468-567`).
12. **Leagueless live rounds (D107)** — the free door already exists in the data (`20260829090000`), with `recent_partners` and `nearby_resolve` under the same disclosure envelope as search (`20260830250000:1-15`).
13. **Forfeits with no money column** (`20260724120000:10-13`) — pride stakes with pot-grade rigor, ready to be re-homed.
14. **The push contract**: routed kinds, lock-screen actions, an actionable-only badge with a seen marker (`docs/ios/push-contract.md`; `20260831180000`).
15. **`growth_events` fail-closed for anon** (`20260828160000:18-33`) and `came_via_*` attribution on the profile.
16. **The handicap engine** — the number emerges from play, never a blind 18 (`20260716100000`), and `index_provisional` is marked (D124).
17. **`v_rounds_ranked` as the single scoring lens** (D122/D123 on the server side) and `tour_card` collapsed to one lens (D209).
18. **D37 grant discipline made structural**: `contract.psv` + generated `Rpc.swift` (159 of 198) — the redesign can trust that what the phone can name is what the server grants.
19. **Round posts already speak in the Gentleman's voice**: "Galen posted 84 at Encanto." (`20260727160000:63-68`), and the clash settle: "took the week — beat their number by 3.1 on Thursday." (`20260902170000:428-435`).

---

## Section A / B / C · What the redesign can lean on, and what it must ask for

### A · Computable TODAY with no schema change (existing RPC or a client-side pass over data a client can already read)

| Desired surface | Verdict | How (SAW) | Caveat |
|---|---|---|---|
| Friend activity feed across ALL buddies | **Yes for rounds** | `home_feed(21)`: circle = friends ∪ league-mates ∪ event co-players (`20260723090000:22-35`) | rounds only, 40 rows, 21 days, 100 % lens (DL-04); moments/plans/verdicts not included (DL-03) |
| "You've beaten Mike 3 of the last 5" | **Yes, for a league-mate** | `rivalry_weeks(mike)` newest-first → take 5, count `winner='me'` (`20260716010000:101`) | none for a buddy without a shared season (DL-09) |
| "You're #4 among your friends" | **By handicap, client-side** | `my_friends().index_current` + my `native_home.profile.index_current` → sort (`20260715210000:85`) | by form / points: no (DL-02); privacy decision needed |
| Streaks "3 straight under 85" | **Self only, client-side** | own `rounds` are RLS-readable (both clients read `rounds` directly: `LeagueRoomModel.swift:411`, 10 web sites) → consecutive-run over `played_on` | friends' rounds are not readable beyond `home_feed`'s 21 days (DL-08) |
| "3 friends playing this weekend" | **Yes** | `native_home.upcoming_rounds` / `my_schedule(from,to)` filter `is_friend && play_on ∈ weekend` (`20260718192400:220-222`) | 1 future row in prod (DL-10) |
| "Jake challenged you" | **No** | — | DL-01 (C-1) |
| Predictions | **Yes, inside a league** | `season_scenarios` (`clinched`, `eliminated`, `needs`, `max_final`) under the D24 honesty rule; `cup_final_race` in the Final | never a probability; the canon forbids a guess (`20260716224500:10-16`) |
| Season countdown | **Yes, client-side** | `native_home.season.starts_on/ends_on/status`; Final = `ends_on − 27` (`LeagueDates.swift:43-44`) | server key would end the drift (DL-11) |
| Movement since last round | **No** | `prev_rank` is the last Sunday snapshot (`20260902200000:312-342`) | DL-06 (B-5) |
| Closest competitor + gap | **Yes for the leader and rank 2; gap-only for rank ≥ 3** | `standing.runner_up_name/points`, `gap_to_next` (`20260902200000:265-267`) | DL-07 (B-6) |
| "Win this week and you move to 2nd" | **Client-side, inside a league** | `v_individual_standings` (both clients read it: `LeagueRoomModel.swift:215`, web ×2) + `cup_points` ceiling 12 → "one Torched-it round passes {name}" | needs the row above me by name (B-6); must obey D24's ceiling wording |
| Head-to-head from shared rounds outside a league | **No** | no read joins two golfers' rounds outside a season window | DL-09 (B-2 + C-2) |
| Career records | **Yes** | `tour_card.career` (rounds, best, avg_pvi, best_pvi, avg_vs_index), `courses`, `my_trophies`, `my_achievements`, `career_record`, `event_lineage` | `seasons_done`/earnings are 0 for everyone (DL-14/15); no lowest-gross, per-course best, PB history (DL-13) |
| Who I play with | **Partly** | `recent_partners` (live seats), `my_schedule.tagged_names` | seats only (DL-17) |
| Who's winning (my league) | **Yes** | `standing.rank/of/leader_name/gap_to_leader`, standings views | — |
| The pot | **Yes** | `buy_in{players, paid_count, collected_cents, paid, note, due_on}` (D106/D129) | — |
| What's next in my event | **Yes** | `native_home.open_duels` with `my_pvi/their_pvi`, `events[]` | — |

### B · Needs a NEW RPC over existing tables (no schema change; a migration + contract refresh + `Rpc.swift` regeneration)

1. **`friends_board()`** → `table(profile_id, display_name, marker, index_current, index_engine, rounds_30d, avg_pvi_30d, best_pvi_30d, last_round_on, rank_by_index, rank_by_form, is_me)`. Tables: `friendships` (accepted, either direction) ∪ me → `profiles` → `rounds` (not voided, not sim, `played_on ≥ today − 30`) with `pvi = index_at_post − differential` (100 %, labelled; no league lens exists between friends). Security definer; the `discoverable` gate does not apply (they accepted). Answers DL-02.
2. **`head_to_head(p_opponent)`** → `jsonb{facets: {season_weeks{w,l,t, weeks[]}, same_day_rounds{w,l,t, days[]}, live_games{w,l,t, games[]}, clashes{w,l}, duels{w,l,h}}, last_five[], rivalry_name}`. Tables: existing `rivalry_weeks` logic; `rounds r1 join rounds r2 on r2.played_on = r1.played_on and course_key(...) equal` (higher 100 %-PvI wins); `live_rounds.game_result` + `live_round_players` (winner by the JSON the settle already writes); `week_clashes.winner_member`; `event_duels`. Replaces the three copies in DL-09 with one and becomes what `my_rivalries`, `tour_card.vs_you` and the epilogue read. Requires the C-2 decision on what a casual meeting is.
3. **`home_stories(p_days = 21, p_league = null)`** → one typed stream: `{kind ∈ {round, milestone, plan, clash_open, clash_verdict, lead_change, trophy, invite}, at, who{profile_id, name, marker, is_me, is_friend}, league{id,name}?, round_id?, scheduled_round_id?, post_id?, headline, sub, pvi_lens, band}`. Tables: `rounds` (the `home_feed` circle) with the D123 lens when `p_league`; `achievements` (profile-level — this is how a leagueless friend's "broke 90" reaches me, DL-18); `scheduled_rounds` (via `my_schedule`'s predicate); `week_clashes` (my leagues); `posts.moment/system` (my leagues); `trophies` (circle). Server-side ordering and dedupe end the two client merge algorithms (DL-23) and the flag disagreement (DL-24).
4. **`my_streaks()`** → `jsonb{under_85: n, under_90: n, beat_number: n (cup_points ≥ 9), weeks_in_a_row: n, current_since: date}` over own `rounds` ordered by `played_on, id`; optionally `streaks_of(p_profile)` under the `tour_card` gate. Answers DL-08 without touching `achievements`.
5. **`round_epilogue` extension** → add `rank_before, rank_after, of, passed[]{name}, gap_to_next_after` by ranking `v_individual_standings`/`v_squad_standings` with and without `p_round`'s points (subtract the round's `points` where `month_rank ≤ cap`; recompute the displaced round if the cap moved). Answers DL-06.
6. **`native_home` v3 keys** (additive, optional on the client as v2 was): `season.week_no, weeks_total, week_ends_on, days_to_first_tee, days_left, final_opens_on`; `standing.next_up{name, points}, next_down{name, points}`; `profile.last_round_on, days_since_round`; `membership.last_season{number, my_rank, of, champion_name, ended_on}` (from `standings_snapshots` last week + `seasons.champion_*`); `clash` (the `home_clash` object inlined). Answers DL-05, DL-07, DL-11, DL-27, DL-31.
7. **`my_side_games()`** → `table(live_round_id, played_on, game, course_label, players[], my_result, cents)` from `live_rounds.game_result` + `live_round_players` (seats → profiles) for `status='final'`. Answers DL-19.
8. **`season_story(p_season)`** → ordered `jsonb[]` from `standings_snapshots` (rank per week), `posts.moment` + `system` with `round_id`/`live_round_id`, `week_clashes` (open/settle), `season_lead` (needs a granted read or is folded here), `cup_finalists`, `trophies`. "The season as a story" without a new table.
9. **`match_contacts(p_hashes text[])`** → `table(profile_id, handle, display_name, rel)` for salted SHA-256 of normalised emails/phones; needs a `profiles.contact_hash` column (so strictly C), but the onboarding's "who do you play with" has no other data source; the `nearby_resolve` envelope (`20260830250000:84-120`) is the privacy model to copy.
10. **`band_name(p_pvi)`** beside `cup_points` (DL-26), returned wherever a payload carries `pvi`.
11. **Build D123's server half** as ruled: `home_feed(p_days, p_league default null)` + `round_card(p_round, p_league default null)` (DL-04) — or let B-3 supersede `home_feed`.

### C · Needs NEW tables or a new mechanic — and therefore a decision-log entry

1. **`challenges` — the friend-to-friend competition object (DL-01, DL-20).** `challenges(id, challenger, challengee, kind ∈ {best_round_window, beat_your_number, live_match, first_to_break}, opens_on, closes_on, course_key?, forfeit_id?, status ∈ {open, accepted, declined, live, settled, expired}, winner, receipts jsonb{a_round_id, b_round_id, live_round_id}, settled_at)`; settle from `rounds` inside the window (the clash's own band rule) or from a `live_rounds.game_result`; a `push_nudges` kind `challenge` with category `CS_CHALLENGE` (`ACCEPT / DECLINE`); forfeits gain `challenge_id` and lose the crew-only check. Decision points the log must rule: (a) does a challenge count toward `head_to_head`? (b) can a challenge exist inside a league week beside the engine's clash (D52 says one spotlight per league-week — a challenge is the *players'* spotlight, so it should be allowed and not posted to the board twice)? (c) stakes: pride only (D64's line) or the books? (d) who may be challenged: buddies only (the `declare_round` consent rule, `20260902203000:89-100`).
2. **What a casual "meeting" is (DL-09).** A mechanic ruling before B-2 can count same-day rounds: same `course_key` and `played_on`? Any same day? Only when tagged together (`scheduled_rounds.tagged`, `rounds` has no `played_with` column — a `round_players`/`played_with uuid[]` column is the honest capture, and it is the same capture DL-17 needs). Under D1/D2 the verdict is by band, not raw differential.
3. **An `outing` — the lightweight event with identity (DL-29).** `outings(id, name, play_on, course_key, host, tagged[], league_id?, becomes_event_id?)`, or promote `scheduled_rounds` to carry `name` and `is_outing` and let a Major/Ryder be created *from* it. Rulings: is an outing an `events.kind`? does it get a board (posts home) or a comment thread (`round_comments` already exists per scheduled round)?
4. **A story home for a golfer without a league (DL-18).** Either relax `posts_home_check` to allow `profile_id` as a home (posts RLS then needs the `tour_card` visibility predicate), or rule that the feed synthesises leagueless stories from `achievements` (B-3) and never writes a post. The second needs no schema; the first lets friends react (`post_kudos`) to a leagueless milestone.
5. **Repeatable streaks (DL-08).** Drop `unique (profile_id, kind)` for `streak_*` kinds (or a `streaks(profile_id, kind, length, started_on, ended_on, current)` table maintained by `round_moments`) and rule that a streak badge is a memory, not a one-time badge.
6. **Onboarding fields (DL-22).** `profiles.play_style` / `plays_per_month` / `usual_day` (or reuse the four dormant columns, DL-21) and `contact_hash` for B-9; rule what is asked, what is inferred (vision principle 2: "can the computer infer it instead?").
7. **A `groups`/`crew` without a league (COMMUNITY).** Today "the crew" *is* `league_members`. A friend group that plays together but never runs a season has no container; `recent_partners` is the only inference. Rule whether a league in `setup` phase with $0 and no season *is* that container (it nearly is: `leagues.phase='setup'`, 6 in prod) or whether a lighter `crews` table is warranted.
8. **One week producer (DL-05).** Mechanic-level ruling: the clash formula (`floor((local − starts_on)/7)+1`, `weeks_total = ceil((end − start + 1)/7)`) is the week; `snapshot_week` and both clients adopt it; `standings_snapshots.week_no` history is re-labelled or the off-by-one is documented.
9. **Ranking friends at all (DL-02).** The vision lists "rivalries, streaks, Hall of Fame, league records" under future features and rejects nothing here; but a handicap ladder among friends is a surface the canon has not ruled on ("bands never differentials" applies to the number shown). Rule the display: by index (a number golfers already share), by band-of-form, or by record — and whether `discoverable='nobody'` hides a golfer from their own friends' board (it should not; they accepted).

### The one-fact-many-places hazards (named)

| Fact | Places | Evidence |
|---|---|---|
| **The week number** | `snapshot_week` (0-based, day-7 start) · `open_week_clash`/`home_clash`/`settle` (1-based) · `sandbox_week` (1-based) · web `weekCloseDate` (0-based) · web hero (1-based, `+1`) · web weeks-left (`Math.ceil`) · phone `LeagueDates.currentWeek` (1-based) with `totalWeeks = ceil(days/7)` vs server `ceil((days+1)/7)` | baseline `:749-750`; `20260902170000:79-80`; `20260724200000:24`; `index.html:8111, 11305, 11263`; `LeagueDates.swift:31-41`; the engine's own admission `20260831130000:20-21, 37-38` |
| **PvI** | `v_rounds_ranked` (allowance) · `home_feed` (100 %) · `tour_card.avg_vs_index` (100 %, labelled) · `tour_card.recent.beat` (100 %, `20260902180000:143-146`) · `friends`-level comparisons (none) | `20260902100000:98`; `20260723090000:51`; `20260902180000:109-126, 143` |
| **The band names** | seven copies (server ×5, phone, web) | DL-26 |
| **The head-to-head W-L-T** | `my_rivalries` · `rivalry_weeks` · `tour_card.vs_you` | DL-09 |
| **The headcount** | `native_home.roster` (living, unsuspended) vs `members` (every row) vs `buy_in.players` (every row) — deliberately three, documented | `20260902200000:61-67` |
| **`seasons_done`** | `career_record` (paid seasons) vs You's "Every season" (`LeagueRecordView`, from `seasons` + membership) | `20260725190000:156-158`; `YouScreen.swift:188` |
| **The clash window** | server `starts_on + 7·(week−1) … +6` and phone `ClashMath.window` — the same expression, copied | `20260831160000:518-519`; `WeekClash.swift:48-54` |
| **Days-to / days-left** | phone `Models.swift:270-281`, web `index.html:11263`, server only in `cup_final_race.days_left` and `home_clash.days_left` | DL-11 |

---

## Section 5 · What I could not determine from reading

1. **Why 15 of 39 profiles are `discoverable='nobody'`** — chosen, or test/tombstone accounts (`deleted_at` is null on all 39). A one-line prod query on `email like '%sandbox%'` would tell; I did not run it because the counts query was already two statements and the answer changes only DL-16's severity.
2. **Whether the four unapplied D221 migrations** the session memory names (one dated Sep 8) touch any function in this inventory. I inventoried the repo at tip; `contract.psv`'s last note is 2026-09-02 (214 functions) while the generated `Rpc.swift` says 159 of 198 — the contract file's own count and the generator's count differ, and I could not tell which is stale without a prod `pg_proc` read (allowed, but not needed for the findings).
3. **Payload sizes and latency** of `native_home` for a golfer in several leagues (it loops memberships and calls `league_pulse`, `my_schedule`, `my_invites`, `my_visitor_rounds` inside) — no timing data exists (`client_events` has none for Home).
4. **Whether the posts webhook and the `push_nudges` webhook are wired in prod** — `device_tokens = 1` and `push_nudges = 18` suggest the rail has fired for one phone, but the function logs are not readable from the repo.
5. **The exact JSON shape of `live_rounds.game_result`** per game (I read the settle branches that write it, `20260830260000:146-171`, not a sample row) — B-7's column list is INFER.
6. **`my_visitor_rounds`, `live_round_card`, `round_detail`'s full key lists** — read partially; not load-bearing for any finding.
7. **Whether the web at tip is what is deployed** — the web line numbers are from `index.html` at `3bba87e`; the prior audit's line numbers (`@34d20b6`) no longer match, which is why I re-derived every citation.
8. **Realtime**: `LeagueRealtime.swift` exists in the Kit; I did not trace which tables are subscribed, so "the feed updates live" is unverified either way.
9. **The cron schedule** (`cs-week-snapshot` Sunday-only per D213; the daily tick's hour) — named in the decision log, not readable in migrations I opened.
