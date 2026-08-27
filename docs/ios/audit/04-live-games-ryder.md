# Audit 04 — Everything live and head-to-head

Scope: the Tee Sheet (Match Play, Wolf, Skins, Sunningdale Rules, round-robin/solo modes), guest claim links, the Ryder, the Major, scheduled rounds, and every other "match-shaped" object in Cup Season. Read-only audit of `/Users/fischbeck3/cup-season` at branch `native/b1-scaffold` (2026-08-27). All line numbers are `index.html` unless a file is named.

---

## 1. What a "match" IS in Cup Season (definitive)

**The core loop has no scheduled head-to-head.** A season is squads accumulating points from *any* posted round, anywhere, on the golfer's own schedule (spec §1–§4, §14). There is no fixture list, no "who you play next," no `opponent` column on any season table. Spec §4 Format B ("Head-to-Head: monthly matchups") was **retired by D48** (`spec/spec-v1.0.md:126`; the remaining trace is demo ledger seed data at `index.html:11423-11424`, `kind:'matchup_bonus'`). The only squad-vs-squad object in the season is the **Cup Final** — two seeded squads in `cup_finalists` (baseline `00000000000000_initial_baseline.sql:969-978`) racing on fresh points for the final 4 weeks (`cupFinalStart()` 11778, `isCupFinal()` 11779-11783, hero branch 9864-9873). Even that is not "a match": nobody is paired; both squads just keep posting rounds.

D12 (`spec/decision-log.md:181-190`) fixes the user-facing noun set: **Match** = on-course, **Rivalry** = lifetime record (faceted), **Ryder** = the event product; "duel" and "event" are schema words only, and "a Ryder duel is *your match this week*."

So there are exactly **four things** that can honestly be called a match, and they are different objects:

| # | Object | Table | Scheduled in advance? | "Next opponent" concept? | Where it lives |
|---|---|---|---|---|---|
| A | **Tee-sheet game** (Match Play / Wolf / Skins / Sunningdale) | `live_rounds` + `live_round_players` + `live_scores`; result frozen in `live_rounds.game_result` | **No.** Created on the first tee by tapping "Tee off" (8902). A `scheduled_rounds` row can *prefill* it (D-batch-3 #19; `renderPlanBridge` 8349-8375) but is never the parent of record. | Opponents = the foursome in the round; sides are picked at tee-off (`courtTeams()` 7253, `MTEAMS`). | Play view `#playSetup` / `#playLive` (HTML 2960-3095) |
| B | **Ryder duel** (`event_duels`) | `events(kind='ryder')` → `event_sessions` → `event_duels` | **Yes — the only scheduled h2h in the product.** Sessions are dated Sun→Sat at create (`create_event`, migration `20260713120000_ryder_events.sql:170-178`); pairings are generated when a session opens (`generate_pairings`, tick `run_event_sessions`). | **Yes, but only inside the event.** `event_duels.a_player/b_player` for an `open` session IS your opponent this week; `event_session_targets()` gives the number to beat. **Home never shows it** — see §8. | Event room `renderEvent()` 12197-12356 |
| C | **Major** (`events(kind='major')`) | one `event_sessions` window + `event_major_cards` at settle | **Yes** — a dated 2–4 day window. | **No opponent.** Everyone vs the field vs their own number (D43). | `renderMajorRoom()` 12374-12529 |
| D | **Weekly clash / rivalry** | none — computed by `my_rivalries()` / `rivalry_weeks()` (migration `20260716010000_rivalries.sql`, faceted in `20260716160000_ryder_slice3.sql:606-680`) | **No** (implicit: any ISO week you and a shared-league mate both post). D52's *spotlighted* weekly clash with board posts is **decided, not built** (no migration mentions spotlight/weekly_clash). | Retroactive only — "vs Jake 14–9". | You tab `renderRivalries()` 13215-13242, `openRivalrySheet()` 13244-13264 |

Also on the books but not a match: **personal stakes** (D51 — `openStakeCreate/openStakeSettle` 10968-11010, "Pride, on the books — never money", `party_a/party_b`) — no `stake_*` RPC exists in `packages/db/contract.psv`, so this is client-scaffold only; and **scheduled rounds** (`scheduled_rounds`, `my_schedule`, RSVP/comments/weather — `spec/scheduled-rounds-arc.md`, built) which are *plans to play*, not competitions.

**Consequence for the iOS home screen:** "match approaching" is only ever true in two cases — (1) you are in a Ryder whose session is `open`/`upcoming` and you have a pending `event_duels` row, or (2) a live round you are rostered in is `status='live'` (the resume/invite banner, `renderResumeBanner()` 7710-7735, D86). Everything else on Home is "your next *round*" (scheduled_rounds), not "your next *opponent*." A native Home that leads with "vs. X" would be inventing a mechanic the product deliberately does not have (D12, D48, product-vision principle: "posted rounds ARE the gameplay", `spec/ryder-v1.md` hierarchy line).

---

## 2. Screens & states inventory per mode

### 2.1 Tee sheet — setup (`#playSetup`, HTML 2960-3037; `renderPlay()` 8380-8384 setup branch)

- **Plan bridge** (`renderPlanBridge` 8349-8375): if `watchAll` has a round of mine dated today → gold card "On your tee sheet today · Load it →" prefills course + tagged names (names not in `ROSTER` are named so you can add them). Hidden in demo/signed-out.
- **Course block**: `#lrCourse` search (`attachCourseSearch` 6729), `#lrTee`, `#lrRate`, `#lrSlope`, **`#lrHoles` 18/9 seg** (D73: auto-9 when a 9-hole tee is picked), `#editCard` "Enter the pars". SI comes from the course DB or is *estimated* (`estimateSI()` 7199-7205, `SIEST` flag surfaces as "estimated card" everywhere strokes show).
- **The foursome** (`renderRoster()` 8720-8807): 4 slots (`sel[]` indices into `ROSTER`), pick lists grouped You / League / Buddies / Guests; `#rosterFind` = app-wide People Picker (adds any golfer as `guest:true, buddy:true, pid`), `#gAdd` guest-by-name (+optional index; blank = estimated 18.0, 8808-8817). Empty state: "No league mates to tap yet — search the app or add a guest below." (8799-8803). Max 4 ("Foursome is full").
- **The court** (D75 pairing pick, `renderCourt` 7268-7296 + `courtDrag` 7297-…): with 4 players + a team game, slots become two team zones; drag or tap-tap to swap; `state.live.pairing` ∈ {0,1,2} over `PAIRINGS` (7252). A **mode seg** "2v2 teams / Everyone for themselves" appears (8728-8739) → `state.live.mode='solo'`.
- **Game seg** `#gameSeg` (HTML 3022-3028; handler 8888-8899): Just score · Match play · Wolf · Skins · Sunningdale Rules, each with a one-line `#gameNote`.
- **Stake + strokes preview** (`renderMatchPrev` 8660-8719): stake label varies per game (per side / per point / per skin / bank unit; `$0 = bragging rights`); Match preview lists "Strokes off the low man (NAME): X gets N: holes …" from SI; Wolf/Skins/Sunningdale show a rules line; wrong player count shows the constraint sentence.
- **Tee off** (8902-9006): validation (score ≥1 · match/sunningdale 2 or 4 · skins 2–4 · wolf exactly 4, D16 hard-cut 3-player); shuffles wolf order client-side (8933-8935); builds `snap` (rating, slope, `nine_rating`, holes, pars, si, label, tee) and `cfg` per game (8962-8975); `start_live_round` with skew retry dropping `p_config` (8983-8986); stores `lr`, `join_code`, `pmap`, guest claim tokens; `liveAnnounceOpen()` broadcasts `live_open` on the league channel (14841). Error → toast + back to setup. Demo mode skips the server entirely.

### 2.2 Tee sheet — live (`#playLive`, HTML 3039-3094; `renderPlay()` 8386-8589)

- **Scoreboard** (D85, `renderScoreboard` 8604-8654): sticky `#sbHero` (game status line), `#sbChips` (per player: `+N net · gross thru N`, `.lead`, presence dot `.lv`), `#sbSub` sync line (`liveSyncBadge` 7862-7870: "Solo pencil · scores live on this phone" / "N on the sheet · synced|K queued").
- **Hole header**: `#holePrev/#holeNext`, `HOLE n`, `PAR p · SI s`, `#holeDots` (9 or 18).
- **Player rows** (8409-8441): name, GUEST tag, **stroke dots** for this hole (`strokeOn` 7232-7236 for handicap games; positional `sunnStrokesAt` / `sunnSoloStrokesAt` for Sunningdale), sub-line `IDX · STK` or `NO HCP · STRAIGHT UP`, running `gross THRU n / ±par`, and a `− value +` stepper. First tap seeds **par** (8437) — the "adjust only deviations" stepper (batch-3 copy note). Every edit stamps a write clock and broadcasts (`liveMarkScore` 7751-7757).
- **Game cards** (right column): `#matchCard` (match & sunningdale — teams line, `#matchStatus` e.g. `TEAM A 2 UP · DORMIE` / `TEAM A WIN 3&2` / round-robin ladder `NAME 2-1 · …` / solo-Sunningdale `NAME 3 · …`, `#matchMeta` with THRU, low man, stake, EST. CARD, bank holder, "GET N NEXT"), `#wolfCard` (`#wolfWho` "X IS THE WOLF · COMEBACK", `#wolfMeta` tee order + $/pt, `#wolfBtns` `+ NAME` ×3 / `LONE WOLF` / `CLEAR` — 8523-8543, `#wolfTally`), `#skinsCard` (`HOLE n WORTH k SKINS` with `.carryhot` pulse at ≥2 riding, `#skinsTally`), `#settleCard` live minimized transfers (`settleRows` 8337-8343: "A → B $x", "ALL SQUARE", "BRAGGING POINTS — NO MONEY ON IT").
- **Buttons**: `#groupShareBtn` "Group phones — everyone can score" → sheet listing guest claim links to copy (9317-9331); `#finishBtn`; `#discardBtn` two-tap "Scrap this round" (9332-9364; broadcasts `gone`, calls `abandon_live_round`, queues on failure — `PENDA_KEY` 7589-7602); `#backToSetup`.
- **Guest / visitor face** (8579-8586): a token-guest (`state.liveGuest`) or a known visitor (`state.live.visitor`) sees NO finish/scrap/setup/group buttons; account-less guests get `body.guestlive` kiosk (7931).
- **Live banner** on Home (`renderLiveBanner` 8854-8880 — league-scoped; `renderResumeBanner` 7710-7735 — Home): two faces: "Continue your round · HOLE n · THRU t" or, for someone else's round, "X put you on the tee sheet · JUST TEED OFF · NOTHING SCORED YET · JOIN" (D86).
- **Remote end** (`liveRoundEndedRemotely` 7821-7856): another phone finished/scrapped → toast + reset; signed-in visitor auto-claims (`claimPendingRound`); kiosk guest reloads into the claim door.
- **Loading/resume** (`rehydrateLiveRound` 7604-7706): local snapshot first (`readLiveSnapshots`, `applyLiveSnapshot`), then server `live_rounds` (member RLS) + `my_visitor_rounds()` (D88), ignores rounds >2 days old and queued-abandon ids; reconciles the join code.

### 2.3 Tee sheet — finish & recap

- **Finish sheet** (`finishRealLiveRound` 9109-9177): "ONE FINISH — EVERY MEMBER'S CARD POSTS"; mirrors the server completeness rule (18 or clean front-9) and **names missing holes** per open card (S6-01); primary "Post N cards to the season" or "Finish — no complete member card to post"; secondary "This one was casual — post nothing" (batch-3 #14 gate). Calls `finish_live_round` with `p_result = gameResult()` (9100-9108), skew-retry without `p_result`.
- **Recap sheet** (`showLiveRecap` 9178-9308, `.room-dusk`): settlement row first — team-match row (`⚔️ A def. B 3&2` + money line "LOSER PAYS WINNER $10 · SETTLE UP" / "ALL SQUARE — NO MONEY MOVES" / "BRAGGING RIGHTS ONLY" / Sunningdale "SIDE TAKES THE BANK - $N"), or ledger-game row (🐺/💰/⚔️ with `share` headline + transfers "A PAYS B $x · …"); then the **D78 hole strip** (`renderHoleStrip` 8045-8071) + `holeHighlights` chips ("WON 4 STRAIGHT · 5-8", "CLOSED OUT ON 16"); then per-card rows `⛳ NAME · 84 · POSTED · 18 HOLES · ✓ ATTESTED`, `— NAME · NOT POSTED · INCOMPLETE CARD|CASUAL|NO COURSE RATING|NO 9-HOLE RATING`, `🎟️ GUEST · GUEST RECAP — SHARE THE LINK [Copy]` (`/?claim=<token>`); then "Share the card" (PNG via `drawSettlementCard` 5727 / `shareSettlementCard` 5839), "Share the settlement — no account needed" (`csShareLink('settlement', lrId, …)` 9300 → D57 public page), "Revoke a shared link".
- **Board story**: written server-side in `finish_live_round` (see §5) as a `posts` row kind `system`; D92 makes the settlement post open the scorecard via `live_round_card()` (10339).

### 2.4 Guest claim funnel (`/?claim=<token>`)

- Entry (17583-17587): query param → `localStorage.cs_claim`, URL cleaned.
- Boot branches (`safeBoot` 17664-17729):
  1. Signed-out + round `live` → `guest_live_state` → **guest pencil** (`enterGuestLive` 7881-7941): kiosk, own card, no account.
  2. Signed-in (not in that league) + round live + no active round of my own → same pencil, keeps the whole app (D87).
  3. Signed-out + finished → door copy "NAME — 84 at COURSE, Sat Jul 25. Enter your email to keep it." (`claim_round_info` then `scan_claim_info` fallback). Claimed token → dropped silently; dead token → "That scorecard link has expired or was already claimed…" (F3).
- After auth + golfer card (`claimPendingRound` 17588-17632): `claim_round` → fallback `claim_scan_round`; "still live" keeps the token (D86) with toast "They're still out there — your card lands here when the round finishes"; success toasts "Claimed ✓ — your 84 is on your card" / "…the card was incomplete, so nothing posted" / "already on your card".
- Second source: **scan partner rows** (`create_scan_claim` at 6671, photos arc) mint the same link shape.

### 2.5 The Ryder — event room (`#eventBody`, `renderEvent()` 12197-12356)

- Header: event name + status chip (`Forming` / `Live · wk k/N` / `NAME TAKES THE CUP` / `SHARED — BOTH NAMES ON IT`).
- **Scoreboard card**: `A 6½ – 4½ B` (`evHalf`), clinch line `FIRST TO 9½ · A NEEDS 3 · B NEEDS 5` or `FINAL · a–b`.
- Series line (D62 lineage, 12232-12250): "THE 3RD RYDER · BLUE LEADS THE SERIES 2–1 · RED DEFENDS"; "Run it back" button when complete (`ryderRunBack`).
- Rule sentence (12257-12259) — everyone sees how it scores.
- **Taunt toggle** (12265-12267): "🔔 Duel taunts: OFF — ping me when my opponent posts" ↔ ON (`set_event_notify`).
- Organizer-only: "Invite players" (People Picker → `invite_golfer`), **Unassigned** list with `→ Team A / → Team B` (`set_event_team`), per-session "Generate pairings" / "Score this session".
- **Sessions** (newest first once any closed, else oldest first — S5-02): `SESSION n · JUL 6–JUL 12 · OPEN`, duel rows `A vs|def.|halved B` with PvI chip `+2.1 / −0.4`; in an open session the chip shows the **number to beat** from `event_session_targets` (`—` = not posted yet) and animates `.pvrise` when it changes (C10); nag line "Still to post: X, Y · 3d left | closes tonight"; empty: "Pairings not set."
- Rosters per team with W-L-H and CAPTAIN tag; "No one assigned yet."
- **The board**: last 30 `posts` where `event_id = id` (engine posts only — pairings, session results, completion).
- Entry points: Clubhouse chips (`renderClubGroups` 9664-9677: "NAME · Ryder · Live|Forming|Final|Enter the field"), switcher rows (15483-15484), `openEventPicker` (15293-15312: Ryder LIVE · Bracket SOON · Major LIVE), invites banner (`renderNotifications` 12596-12616: "Ryder invite · from X · first tee YYYY-MM-DD").
- **Create sheet** (`openRyderSetup` 15914-16017): name, Team A/B names, sessions 3–6, cadence weekly / every 2 wks, first tee (a Sunday, `nextSundayISO`), attach-to-league select, staged invitees, "How it plays" card; `create_event` with skew retries dropping `p_lineage` then `p_tz`.
- Loading: `loadEvent` 15833-15905 (6 parallel selects + `major_leaderboard`/`event_lineage`/`event_session_targets` per open session, each try/catch). No spinner; room renders "No event loaded." until `CS_EVENT` is set (12200).

### 2.6 The Major — championship room (`renderMajorRoom` 12374-12529)

Header + status chip (`FORMING · OPENS JUL 10` / `LIVE · 2D LEFT` / `THE FINAL DAY` / `AWAITING THE HORN` / `NAME TAKES THE JUG` / `SETTLED — NO CARDS`); card `🏆 A MAJOR · 4 DAYS · JUL 9–JUL 12 · FIELD OF 8 (2 EXHIBITION) · BUY-IN $20 · POT $120 · 60/25/15 | WINNER TAKES ALL | BRAGGING RIGHTS`; lineage line "THE 2ND ANNUAL · MARCUS DEFENDS"; "Enter the field" (league members, pre-horn); organizer: Invite golfers, "Open the window now" (needs 2), "Sound the horn — settle" (after the final day), Scrap; **leaderboard** (`#n` / `EX` / `—` rows: `NAME · 82 · 2 cards · 4.2 UNDER`, tap → `openRoundSheet(round_id)` receipt), "Yet to card"; after settle: "Final — every card counts" with prizes, Exhibition, No card ("buy-in stays in the pot"), "Share the jug 🏆" (`drawMajorCard` 12533-12572 canvas), "Run it back — same jug, next year"; champions roll; fine-print card; the board. Create sheet `openMajorSetup` 16021-16140 (name the jug, final day, 2/3/4-day window, buy-in, split, league, invitees).

### 2.7 Rivalries (You tab)

`renderRivalries` 13215-13242: rows "NAME · N weeks head-to-head · Ryder duels 3–2" with `W–L(–T)` colored up/down/even; hidden when empty. `openRivalrySheet` 13244-13264: per-week rows "WK OF JUL 6 · WON · YOU +1.2 · THEM −0.4 · BEST ROUND VS INDEX THAT WEEK", "No head-to-head weeks yet…"; name/rename the rivalry (`set_rivalry_name`).

---

## 3. RPC table

Signatures are verbatim from `packages/db/contract.psv` (pg_proc snapshot). "Role": auth = `authenticated`, anon+auth = the public token endpoints, none = engine-only (revoked from API roles; cron/trigger callers).

### 3.1 Tee sheet

| RPC | Args | Returns | Role | Defined in (latest body) | Notes |
|---|---|---|---|---|---|
| `start_live_round` | `p_league, p_course_id, p_tee_id, p_course_label, p_snapshot jsonb, p_game, p_players jsonb, p_config jsonb default '{}'` | `{live_round_id, join_code, players[{id,member_id,guest_name,claim_token,position}]}` | auth | `20260728220000_visitor_rounds.sql:43` (bodies: `20260716080000` spine → `…130000` +config → `20260728120000` +join_code → `…180000` +push_nudges fan → `…220000` +guest_profile) | Requires an active/cup_final season; member players must belong to THIS league; guests carry `guest_name/guest_index/guest_profile`; inserts one `push_nudges` per member player except starter (D86) and known guests (D88). |
| `finish_live_round` | `p_live_round, p_cards jsonb [{player_id, strokes[18]}], p_casual bool default false, p_result jsonb default null` | `{posted[], guests[{name,claim_token}], skipped[{name,reason}], casual}` or `{already_final}` | auth | `20260729120000_scorecard.sql:72` (chain: `…080000` → `…130000` match → `…140000` wolf/skins/guest cards → `20260725220000` sunningdale + natural case → `20260726120000` client story override → `20260728120000` row lock) | Starter or member player only. Member cards → `rounds` (`source='live'`, `attested=true`, `index_source_at_post='app'`, `played_on=current_date`) + `round_holes`; guest cards → `live_round_players.guest_strokes/guest_gross`; `p_result` stored in `live_rounds.game_result` and posted to the LEAGUE board unless casual. |
| `abandon_live_round` | `p_live_round` | `{gone|already_final|abandoned|…}` | auth | `20260717050000_abandon_live_round.sql:22` | status → `'abandoned'`; never on `final`. |
| `live_set_score` | `p_live_round, p_player, p_hole, p_strokes, p_client_ts` | void | auth | `20260728120000_live_sync.sql:135` | LWW upsert into `live_scores` (1..15, null = delete); guard `_live_member_can` (player, starter, or known guest — `20260728220000:123`). |
| `live_set_wolf` | `p_live_round, p_hole, p_wolf jsonb, p_client_ts` | void | auth | `…120000:173` | LWW into `live_rounds.game_state.h<n> = {v, cts}`. |
| `live_state` | `p_live_round` | `{round{…,game_state,join_code}, players[], scores[{player_id,hole,strokes,cts}]}` | auth | `…120000:226` | The reconcile pull. |
| `guest_live_state` / `guest_live_set_score` / `guest_live_set_wolf` | `p_token …` | same shapes (+`me`) | **anon+auth** | `20260728180000_round_invite.sql` (token AND `member_id is null` guard, D86) | Token is the whole authorization; fail-closed. |
| `live_round_card` | `p_live_round` | `{round{…,game_result}, players[{name,guest,index,strokes[18]}]}` | auth | `20260729120000_scorecard.sql:204` | Read for the settlement post / share page; player, known guest, or league member. |
| `my_visitor_rounds` | — | jsonb[] of live rounds where I am a known guest | auth | `20260728220000:142` | D88 door for cross-league visitors. |

### 3.2 Claim funnel

| RPC | Args | Returns | Role | Migration |
|---|---|---|---|---|
| `claim_round_info` | `p_token` | `{guest_name, gross, holes_scored, course_label, played_on, game, game_result, claimed}` or null | anon+auth | `20260716140000_wolf_skins_claim.sql` |
| `claim_round` | `p_token` | `{claimed, posted, gross?, holes?, already?}` | auth | same; raises "Round is still live — claim after the finish" |
| `scan_claim_info` / `claim_scan_round` / `create_scan_claim` | see contract | door info / `{claimed, posted, gross}` / token | anon+auth / auth / auth (8 per 24h cap) | `20260718045514_photos_scan_spine.sql:100-200` |

### 3.3 The Ryder / events

| RPC | Args | Returns | Role | Migration | Notes |
|---|---|---|---|---|---|
| `create_event` | `p_name, p_starts_on, p_sessions, p_session_weeks, p_draw_rule, p_team_a, p_team_b, p_league=null, p_tz=null, p_lineage=null` | event uuid | auth | `20260724100000_lineage_rail.sql:177` (base `20260713120000`, tz/Sunday rule `20260716150000`) | Must start on a Sunday; sessions 1..26 (UI offers 3–6); creator = Team A captain; tz = league season > device > Phoenix. |
| `add_event_player` | `p_event, p_profile` | player uuid | auth | `20260720193000_the_major.sql:258` | Organizer only; refuses once any session closed; majors set `exhibition`. |
| `set_event_team` | `p_player, p_team` | void | auth | `20260713120000` | Organizer only. |
| `invite_golfer` / `my_invites` / `respond_invite` | see contract | — | auth | `20260713180000`, kind-aware in `the_major.sql:719` | Consent-based add; accept after a scored session raises. |
| `generate_pairings` | `p_session` | pairs int | auth (cron when `auth.uid()` null) | `ryder_slice3.sql:354` | least-benched then seed; deletes+rewrites the session's duels; benches surplus; session→open, event→live; posts "SESSION n PAIRINGS: …". |
| `resolve_session` | `p_session` | void | auth/cron | `20260727180000_ryder_session_voice.sql:325` | See §5.4. |
| `event_session_targets` | `p_session` | `(duel_id, a_pvi, b_pvi)` | auth (member-gated) | `20260716150000:280` | Live best PvI per side of an OPEN session. |
| `set_event_notify` | `p_event, p_on` | void | auth | `ryder_slice3.sql:595` | `event_players.notify_target`. |
| `run_event_sessions` | — | void | none (pg_cron `15 7 * * *`) | `the_major.sql:586` | Opens/resolves Ryder sessions, opens/narrates/settles Majors. |
| `award_event_trophies` / `trg_event_complete` | — | — | none | `the_major.sql:548` | Trigger on `events` update → `trophies` rows. |
| `event_post` / `major_post` | `p_event, p_body` | void | none | slice3 / major | Board writers (400-char cap). |
| `delete_event` | `p_event` | void | auth | `20260720214500_delete_event.sql` | Organizer, never complete/scored; deletes trophies explicitly. |
| `event_lineage` / `lineage_root` | `p_event` | chain rows | auth / none | `lineage_rail.sql:41-80` | Rematch-only chains (D61/D62). |
| `my_rivalries` | — | opponent rows with clash W-L-T + duel W-L-H + `rivalry_name` | auth | `20260716210000_named_rivalries.sql` (facets from slice3) | |
| `rivalry_weeks` / `set_rivalry_name` | `p_opponent[, p_name]` | rows / void | auth | `rivalries.sql:75`, `named_rivalries.sql` | |
| `my_trophies` | — | rows | auth | `20260713200000_trophies.sql:37` | |

### 3.4 The Major

| RPC | Args | Returns | Role | Notes |
|---|---|---|---|---|
| `create_major` | `p_name, p_final_on, p_days=4, p_buy_in=0, p_pot_split='places', p_league=null, p_tz=null, p_lineage=null` | uuid | auth | 2–4 days, final ≥ today, ≤ 365 out; organizer enters as a player; announce post dual-homed. |
| `enter_major` | `p_event` | player uuid | auth | League-attached self-serve entry until the horn. |
| `major_leaderboard` | `p_event` | rows (best eligible card so far) | auth | wraps engine-only `major_board`. |
| `open_major` / `settle_major` | `p_session` | void | auth (organizer) / cron | settle refuses humans before `closes_on` has passed. |
| `major_final_day`, `major_contender`, `mj_vs`, `mj_money`, `round_major_story` (trigger on `rounds`), `sched_major_story` (trigger on `scheduled_rounds`) | — | — | none | Narration. |

### 3.5 Scheduled rounds (context)

`declare_round` (**two overloads** live — with/without `p_course_id`; PostgREST resolves by named args), `scratch_round`, `retag_round`, `my_schedule(p_from,p_to)` (returns `rsvp_in, my_rsvp, comment_n, course_id`), `set_round_rsvp` (owner/tagged only, D69), `add_round_comment`. `weather` Edge Function. All auth.

---

## 4. Data model

### 4.1 Live rounds
- **`live_rounds`** (baseline 1140-1156 + later columns): `league_id`, `season_id` (must exist — a league without an active season cannot tee off), `course_id/tee_id` (client always sends null today, 8977), `course_label`, `course_snapshot jsonb` `{rating, slope, nine_rating, holes, pars[18], si[18], label, tee}`, `game` ∈ none|match|wolf|skins|sunningdale, `game_config jsonb` (match: `{stake, side_a[], side_b[], si_estimated}` or `{stake, mode:'solo', si_estimated}`; wolf: `{stake, order[names], si_estimated}`; skins: `{stake, si_estimated}`; sunningdale: `{unit, side_a, side_b}` / `{unit, mode:'solo'}`), `game_result jsonb` (the finished `gameResult()` envelope — see §5), `game_state jsonb` (wolf picks `{h5:{v:{mode,partner},cts}}`), `status` ∈ setup|live|final|abandoned, `started_by` = **league_members.id** (fixed by `20260716090000`), `join_code` (64 hex, the broadcast channel key), `started_at/finished_at`. RLS read = `is_league_member(league_id)`.
- **`live_round_players`**: `member_id` (league_members) XOR `guest_name`; `guest_index numeric(4,1)`, `index_source` ∈ member|self|estimated, `position` 0..3, `claim_token uuid` (defaulted on EVERY row — landmine, §7), `guest_strokes jsonb`, `guest_gross`, `claimed_profile`, `guest_profile_id` (D88).
- **`live_scores`** (baseline, revived D85): PK `(player_id, hole_number)`, `strokes 1..15`, `client_ts`, `updated_at`, `updated_by`. RPC-only (no policies, grants revoked).
- **`rounds.live_round_id`** links a posted card back to its sheet; `rounds.source='live'`, `attested=true`.
- **`game_results`** (baseline 1032-1037: `live_round_id, player_id, points, amount_cents`) — **dead**: never written; the per-hole ledger the spec sketched (`game_ledger`, §3.4) was never built; the ledger lives inside `game_result.holes` (D78 envelope) instead.
- Cron: `daily_season_tick` auto-abandons `setup/live` rounds 24h after start (`20260722100000:153-165`).

### 4.2 Claims
- `live_round_players.claim_token` (tee sheet) and **`scan_claims`** (`token, created_by, guest_name, course_label, rating, slope, played_on, gross, strokes jsonb, holes_played, claimed_profile`).

### 4.3 Events (the Ryder + the Major share one spine)
- **`events`**: `name, created_by (profile), league_id nullable (on delete set null), kind` ('ryder'|'major', no CHECK), `status` setup|live|complete, `starts_on`, `session_count 1..26`, `session_weeks 1..4`, `draw_rule` team_pvi|defender|shared, `defender_team_id` (column only — never set by any code), `allowance int=100`, `winner_team_id`, `tz`, `buy_in`, `pot_split` places|wta, `lineage_id` (root event, rematch-only).
- **`event_teams`**: `slot 0|1, name, color int, captain_player_id`. Empty for majors.
- **`event_players`**: `profile_id, team_id nullable, role` captain|player, `seed`, `benched_count`, `notify_target bool`, `exhibition bool`. `unique(event_id, profile_id)`.
- **`event_sessions`**: `session_no, opens_on, closes_on, status` upcoming|open|closed, `weight numeric=1` (never read).
- **`event_duels`**: `session_id, a_player, b_player, a_round/b_round (→rounds, receipts), a_pvi, b_pvi, a_points, b_points, result` pending|a|b|halve, `resolved_at`.
- **`event_major_cards`**: frozen at settle — `player_id, round_id, gross, pvi, second_pvi, cards, best_posted_at, no_card, exhibition, rank, prize`.
- **`v_event_scoreboard`** view: `(event_id, team_id, points)` summing `a_points/b_points` by player team.
- **`posts.event_id`** (nullable; `league_id` became nullable; `posts_home_check` requires one) — event board rail; `posts_read` unions league members, event members, attached-league members.
- **`push_nudges`** (`profile_id, title, body`) — one row = one push to one profile via the second Database Webhook → `push` Edge Function (`supabase/functions/push/index.ts:265-274`). Written by `round_duel_nudge` trigger (opt-in taunt), `start_live_round` (D86/D88 doorbell). No per-user off switch for the doorbell.
- **`trophies`**: `kind` ryder|league|major|bracket, `title, subtitle, placement` winner|shared|…, `event_id`, `season_year`; unique per (event, profile). Read = own only.
- RLS helpers: `is_event_member`, `is_event_organizer`, `is_event_league_member` (spectator reads for attached events, `the_major.sql:71-107`).

### 4.4 Rivalries
No table. `my_rivalries()` computes weekly clashes from `v_rounds_ranked` grouped by `date_trunc('week', played_on)` (ISO Monday-start — not the league's Sunday week, §7) across shared seasons, plus the duels facet from `event_duels`. `rivalry_names` table from `named_rivalries`.

---

## 5. Rules & settlement math per mode

All engines are **client-side JavaScript in the classic block**; the server stores whatever `gameResult()` sends and posts its story. Only Sunningdale has tests (`tests/sunningdale.test.mjs`, extracted by brace-matching from index.html).

### 5.1 Common
- Course handicap `CH = round(index × slope ÷ 113)`, halved for a 9-hole sheet (`recomputeStrokes` 7221-7228, D73). Strokes given = `CH − min(CH)` ("off the low man"). Allocation `strokeOn(pi,h) = floor(stk/H) + (SI[h] ≤ stk % H ? 1 : 0)` (7232-7236) — wraps past 18. SI = course card or `estimateSI()` hardest-par-first (flagged EST).
- `netOf(pi,h) = gross − strokeOn` (7945). `holeDone(h)` = every player has a score (7944).
- Guests use self-declared or estimated 18.0 index; they play every game but never post.
- **Stake locked at tee-off**, `$0` = bragging rights. Every ledger game sums to zero; transfers are minimized greedily (`settleTransfers` 8320-8336: sort creditors/debtors desc, pair off).

### 5.2 Match Play (`matchCalc` 7947-7966, `matchResult` 9015-9046)
- Singles or 2v2 **net best ball**; per hole `min(net)` per side; a<b → side A wins the hole; ties halve. Ladder `a−b`; **closes out** when `lead > holes remaining` (`closed={winner, lead, rem}` → status `3&2`); **dormie** flagged in the status line (8468). Unfinished: `N UP THRU t`; level: `HALVED`.
- Money: flat stake per side, loser pays winner; halved = nothing.
- Envelope: `{game:'match', winner:'0'|'1'|null, status, a, b, thru, stake, side_a, side_b, holes:{mode:'sides',cells['a'|'b'|'h'],played,closed,hot,legend}, story, share}`.
- **Round robin** (D75, `rrCalc/rrRecords/rrResult` 8235-8284): 4 players, 6 simultaneous singles, none close out; per-player `w-l-h`; settlement `pts = w − l` × stake through `settleTransfers` (D79). Envelope `{game:'match', mode:'solo', players[], pairs[], transfers[]}`.

### 5.3 Wolf (`wolfAt` 7973-7980, `wolfPointsThrough` 7986-8008, `wolfResult` 9049-9075)
- Exactly 4. Order shuffled client-side at tee-off and locked. Wolf on hole h = `order[h % 4]` for holes 1..H−2; the **last two holes go to current last place** (comeback rule, batch-2 #10). Tee order shown with the wolf last.
- Pick per hole: `{mode:'partner', partner}` or `{mode:'lone'}`; CLEAR to undo (batch-3 #16 catch-up — any hole re-enterable; irrevocable-pass is NOT enforced, no drive-by-drive prompt exists).
- Scoring per completed hole with a pick: side = wolf(+partner); `min(net)` each side. Partnered win: side +1 each, opp −1 each; lone win: wolf +3, others −1; lone loss: wolf −3, others +1; halve 0. **Carries OFF, blind wolf OFF** (dials never built). A hole with no pick scores nothing.
- Money = pts × $/pt; minimized transfers.
- Envelope `{game:'wolf', stake, players[{name,pts}], transfers[], holes:{mode:'wolf', cells 'w'|'o'|'h'|null}, story, share}`.

### 5.4 Skins (`skinsCalc` 8095-8113, `skinsResult` 9076-9099)
- 2–4 players; lowest **net** alone takes `carry` skins; tie → `carry++` (D9 carry-over). Carried skins **die at the last hole** (18 or 9). Net-zero ledger: `pts[i] = won[i]×n − total_won`; money = pts × $/skin (a skin vs 3 players = 3 units).
- Envelope `{game:'skins', stake, thru, carried_died, players[{name,skins,pts}], transfers[], holes:{mode:'players', cells idx|'c'}}`.

### 5.5 Sunningdale Rules (D74/D75; `sunnEngine` 8122-8141 pure, `sunnSoloEngine` 8150-8178 pure)
- **No handicaps.** Entering a hole, the trailing side gets `max(0, deficit − 1)` strokes on that hole (every hole, not once). Best ball per side; closeout as match play.
- **Bank**: signed integer; a hole won while strictly ahead after winning → bank +1 for A (−1 for B); a qualifying win by the other side pulls one back through zero. Money = |bank| × unit, holder takes it.
- **Solo** (4 players, house extension): strokes = `max(0, leader − you − 1)`; outright low net wins the hole; bank has a single owner; every other player owes `units × unit`.

### 5.6 Ryder duel (`resolve_session`, `20260727180000_ryder_session_voice.sql:325-475`)
- Eligible round: `played_on` within `[opens_on, closes_on]`, `not voided`, `source <> 'sim'`, `index_at_post` and `differential` non-null (9-holes count; the differential normalizes). **`pvi = index_at_post × allowance/100 − differential`**, best per player.
- a>b → a wins (1/0); tie → halve (½/½); one idle → poster wins; **both idle → halve** (batch-2 #11).
- `m_total = min(rosterA, rosterB) × session_count`; **clinch** the moment `max(pa,pb) > m_total/2` (event → complete, remaining sessions never open — see §7). All sessions closed and level → `draw_rule`: `team_pvi` (higher summed duel PvI; dead-even → shared/null), `defender` (needs `defender_team_id`, never populated), `shared` (winner null → both teams engrave).
- MVP = most duel wins, tiebreak total PvI; named in the completion post only (no pot cut, no trophy).
- Posts (natural case, D77): "Blue lead 4½–3½ after session 2. Jerecho beat Will by 3.4, Jade beat Isaak, Mike and Dan halved." / "Blue take the Grudge 10–8. Logan is MVP at 3-0-0."
- Pot: `events.buy_in` exists for majors only; **the Ryder has no buy-in field in the UI and no settlement card** (§R12.4 "thin version" was not built for the Ryder; §9).

### 5.7 Major (`settle_major`, `the_major.sql:373-545`)
- Eligible: **18-hole** only, not voided/sim, PvI at 100% off `index_at_post`; best card = score, second-best = countback; no band ceiling.
- Contender = `handicap_index(profile) is not null` at add/enter time (≥3 real differentials); else **exhibition** — on the board, never ranks or pays.
- Rank: `pvi desc, second_pvi desc nulls last, best_posted_at asc, random()` (logged coin flip "COIN FLIP: A OVER B").
- Pot = buy_in × contender entrants; `places` = 25% to #2, 15% to #3, remainder (60%+unfilled) to #1; `wta` all to #1. No-card contenders' buy-ins stay in the pot ("BUY-INS RETURNED" only when nobody carded).
- Trophy: one `trophies(kind='major', placement='winner')` for rank 1.

### 5.8 Weekly clash (rivalries)
Per shared season, per ISO week where both posted: better max PvI wins the week; W/L/T lifetime; duels facet added, never blended (batch-3 #18).

---

## 6. Lifecycle / state machines

### 6.1 Live round
```
(setup, client-only; state.live.stage='setup')
   └─ Tee off ─► start_live_round ─► live_rounds.status='live'  [+push_nudges to roster, +league broadcast live_open]
        ├─ scoring: state.live.scores[pi][h] (localStorage cs.live.<lr>) ⇄ broadcast live-<lr>-<code> ⇄ live_scores (LWW by client_ts)
        ├─ wolf picks: state.live.wolf[h] ⇄ live_rounds.game_state
        ├─ Finish ─► finish_live_round(p_cards, p_casual, p_result) ─► 'final'  → rounds+round_holes (members), guest cards saved, game_result stored, board post; broadcast {t:'finish'}
        ├─ Scrap  ─► abandon_live_round ─► 'abandoned' (queued locally on failure); broadcast {t:'gone'}
        └─ 24h sweep (daily_season_tick) ─► 'abandoned'
```
Client `state.live` shape (8937-8940): `{stage, active, game, stake, wolfOrder, holes, rating9, pairing, mode, hole, scores[4][18], wolf[18], scts, wcts, code, lr, league_id, pmap, guestTokens, mine, host, visitor}`; `state.liveGuest={token, me, signedIn}`.

Resume precedence (`rehydrateLiveRound`): in-memory active round > local snapshot (v≥2, not in `cs.pendingAbandons`) > server `live_rounds` (member) ∪ `my_visitor_rounds()`; rounds older than 2 days ignored.

### 6.2 Guest token
`minted at start_live_round` → (round live) **pencil** via `guest_live_*` → (round final) **door** via `claim_round_info` → auth + golfer card → `claim_round` → `claimed_profile` set; card posts to the new profile if complete+rated (`played_on = finished_at::date`). Token survives a "still live" refusal; dropped on any other failure or when already claimed.

### 6.3 Ryder
```
events.status: setup ──(first generate_pairings)──► live ──(clinch | all sessions closed)──► complete ──trigger──► trophies
event_sessions.status: upcoming ──(tick: opens_on ≤ today(tz) AND both teams non-empty | organizer tap)──► open ──(tick: closes_on < today | organizer "Score this session")──► closed
event_duels.result: pending ──resolve_session──► a | b | halve   (never retro-flips)
```
Roster: adds allowed until any session is `closed` (§R10); team reassignment any time (no guard once live — §7). Invites: `member_invites` pending → accept inserts `event_players` (unassigned, seed last).

### 6.4 Major
`setup` → tick/organizer `open_major` (needs ≥2 entered, `opens_on ≤ today`) → `live` → tick posts `major_final_day` on `closes_on` → tick `settle_major` the morning after (`closes_on < today`), or a never-opened window past its horn settles straight from `setup` → `complete` → trophy. Entry (invite / `enter_major`) allowed until the session is closed.

### 6.5 Tick timing
pg_cron `run_event_sessions` at `15 7 * * *` UTC (~00:15 Phoenix) evaluates `today` in each event's `tz`. Sessions therefore open/close at the tick, not at midnight local — a Saturday-night round posted at 00:10 Sunday local is still inside the window because `played_on` is a date.

---

## 7. Edge cases & landmines

1. **Clinch kills later sessions without opening them.** `resolve_session` flips `complete` on clinch; `run_event_sessions` only iterates events in `setup|live`, so remaining sessions stay `upcoming` forever and their duels are never resolved — §R4 says "remaining duels still resolve for the record." The room shows them as "Pairings not set." Native must not assume every session has duels.
2. **`defender` draw rule is a dead path**: `events.defender_team_id` is never written (lineage/run-it-back does not set it), so a `defender` event with a dead-even finish falls to the `v_def is not null` check and… does nothing (no `else` — event stays `live` with all sessions closed). The UI only ever sends `team_pvi` (15988).
3. **The tie-break `team_pvi` sums signed PvI** including negatives, and a player with no round contributes 0 — a team that sat out scores better than a team that posted badly.
4. **Session windows are `played_on` dates evaluated in event tz, but `finish_live_round` stamps `played_on = current_date` in the DB session's tz (UTC)**. A tee-sheet round finished after 5pm Phoenix on a Saturday lands on Sunday UTC — outside a Sat-closing Ryder session / Major window. Quick-posted rounds carry the user's chosen date; live ones don't.
5. **`my_rivalries` weeks are ISO (Monday-start) via `date_trunc('week')`**; the season week is Sunday→Saturday (§14.0). The rivalry sheet's "WK OF …" label and the Ryder session windows disagree by one day on Sundays.
6. **`live_round_players.claim_token` defaults on every row, including members.** The D86 guard (`member_id is null`) on the guest RPCs is the only thing keeping a member row un-pencilable by token; `claim_round_info/claim_round` already had it. Keep that predicate in any native re-implementation.
7. **Two `declare_round` overloads coexist** (contract.psv) — a positional call is ambiguous; always pass named args (the web does).
8. **Wolf order is a client `Math.random()` shuffle** stored as names in `game_config.order` — resolved back to indices by name match (`enterGuestLive` 7910). Two players with the same display name break wolf order and side reconstruction for late joiners. Same for `side_a/side_b`.
9. **`game_results` table is dead**; the hole ledger lives in `game_result.holes` (D78 envelope). Any "receipts" surface must read the JSONB.
10. **Push doorbell has no mute** (D86 tradeoff): every rostered member gets a push at tee-off; `notify_rounds/notify_chat` don't gate `push_nudges`.
11. **Event pushes fan to ALL event players for every event post** (push/index.ts:277-291) — a 6-a-side Ryder gets a push per pairing post, per session result, per Major card story. No per-user event mute.
12. **Roster locking is asymmetric**: adds refuse after a closed session, but `set_event_team` has no such guard — an organizer can move a player between teams mid-event, changing `v_event_scoreboard` retroactively (points follow `event_players.team_id` at read time, not at resolve time).
13. **`event_sessions.weight`** exists and is never read; `allowance` is always 100 (no UI).
14. **Ryder `starts_on` must be a Sunday** server-side (raises); the create sheet defaults to next Sunday but the date input is free — the error string is the only guard.
15. **Sync channel is a "rumor mill"**: broadcast payloads carry first names + scores on a channel keyed only by the unguessable `join_code`; durable writes re-auth. Acceptable per D85, but a native client must never treat broadcast as truth — LWW against `live_scores` on reconcile.
16. **Guest kiosk is one-way** (`body.guestlive` removed only by reload, 7930); signed-in visitors deliberately keep the app (D87).
17. **A finished sheet posts member cards with `played_on = current_date`** and `index_source_at_post='app'` — the engine resolves the index; a member with no established index still posts (the 20260716100000 engine change removed the "no index set" skip).
18. **Live rounds require an active season** — a league in `setup`/`complete` cannot use the tee sheet at all ("No active season to post into"). Standalone crews without a league have **no tee sheet**; the Ryder/Major do not offer live scoring.
19. **`live_rounds.course_id/tee_id` are always null from the client** (8977); the snapshot is the only course fact. `live_round_card` and share pages can't link to `api_courses`.
20. **Skew retries match on `/function|schema cache/`** — a genuine "function raised" error containing the word "function" triggers a retry without the newest arg (harmless but confusing).
21. **`event_post` caps at 400 chars** — D77 reordered the session post so the scoreline survives truncation; a 13-a-side session still truncates duel lines.

---

## 8. Web-specific / clunky things native should do differently (opinionated)

**Must remain intact (rules, not UI):**
- The engine math in §5 exactly — including the comeback wolf rule, carries-off/blind-off, skins dying at the last hole, Sunningdale `deficit−1` every hole and the bank's single-owner walk, round-robin `w−l` settlement, 9-hole halved CH. Port `sunnEngine`/`sunnSoloEngine` with the existing test vectors (`tests/sunningdale.test.mjs`) and write the same style of pure tests for match/wolf/skins (the web has none).
- The `game_result` envelope shape (`{game, mode?, winner, status, side_a/side_b | players, transfers, holes:{n,played,mode,cells,closed,hot,legend}, story, share, stake|unit, bank}`) — the server branches on `game` and `story`, the share page and D92 scorecard read `holes`. Changing it orphans every settled round.
- The finish gate (post / casual), per-player completeness rule (18 or clean front 9), guests never post, `p_result` omitted on casual.
- LWW-by-writer-clock sync semantics and "anyone edits any cell" (D85 write model, flag #16 catch-up). Every game state must be enterable after the fact — no native flow may lock a hole behind a real-time prompt.
- Token-is-identity for guests; the `member_id is null` guard; the still-live claim keeps the token.
- Ryder: Sunday sessions, both-idle halve, clinch = `floor(M/2)+½`, number-to-beat shown unconditionally, push opt-in only.
- Everything shows its work: every duel chip → the two rounds; every Major row → the card; every settlement → the hole strip.

**Do differently:**
1. **Home must not fake a fixture.** Lead with the *live round banner* when one exists (invite face vs resume face, D86), then "your next round" (scheduled_rounds), then — only if in a live Ryder — a **"your match this week"** card (D12's phrase) built from the open session's `event_duels` row + `event_session_targets`: opponent, their number to beat, days left, your best so far. The web never surfaces this on Home (only inside the event room, §2.5); it is the single highest-value native addition and needs no schema. Do not build a generic "next opponent" slot that is empty for the 90% of users not in a Ryder.
2. **On-course entry is a stepper built for a thumb on a moving cart.** The web's `− n +` per player per hole with par pre-seeded is right in principle; native should make one hole one screen, big par-relative chips (−2…+3), swipe between holes, haptic tick per stroke, a distinct haptic for "hole complete," and auto-advance when `holeDone`. Keep the strip of hole dots as the progress spine.
3. **Live Activity / Dynamic Island** for a live round: match status line (`2 UP · DORMIE`), skins riding, wolf "YOU'RE THE WOLF · HOLE 12," sync state. The web's sticky scoreboard (D85) is the design brief for what the Live Activity shows. Deep-link back into the current hole.
4. **Wolf decision UX** should become a prompt sheet at hole start ("Danny drove — Take Danny / Pass"), *advisory* live and always overridable with the CLEAR/back path (flag #16). Don't enforce irrevocable pass.
5. **Offline-first is non-negotiable on a golf course**: the web queues RPCs in localStorage (`cs.liveq.<lr>`, 300-cap) and reconciles on visibility. Native: SQLite/Core Data queue, background flush, and the same "poisoned write drops after N tries" rule (14815-14817). Present sync state honestly ("2 queued").
6. **Guest joining**: replace "copy the link and text it" with Share Sheet + **NFC/AirDrop/QR** of `/?claim=<token>` from the group sheet; the token contract is unchanged. A native guest with the app should land on the pencil via Universal Link, not a kiosk.
7. **Tee-off should be a 3-step sheet** (course → players → game+stake) with the court as a drag-to-swap board; keep the strokes preview as the confirmation ("Danny gets 3: holes 2, 7, 11") — it is the first-tee argument settled and users read it.
8. **Settlement**: the recap should render natively (hole strip, transfers, POSTED/NOT POSTED rows) and share the PNG via UIActivityViewController with the `share` string as text; keep "no account needed" public link (D57) as a second action.
9. **Event rooms**: the Ryder scoreboard is already the right information architecture; native gains push categories (**taunts opt-in stays**, but add per-event mute for engine posts — a schema addition `event_players.notify_board`) and a local notification "session closes tonight — you haven't posted."
10. **Kill the classic/module `window.*` bridge assumptions**: `liveSync`, `enterGuestLive`, `renderEvent`, `claimPendingRound` are bridged globals; native gets one state store. Also drop the demo diorama (`ROSTER` seed, 7206-7214) from the live path.
11. **Time**: compute `played_on` for a finished sheet in the league/event tz on device and pass it explicitly if the RPC ever grows a `p_played_on` (it doesn't today — §7.4 is a server fix, log it).

---

## 9. Built vs specced-unbuilt

| Item | Status | Evidence |
|---|---|---|
| Match Play singles / 2v2 net best ball, closeout, dormie, stake per side, board story | **Built** | 7947-7966, 9015-9046, migration `20260716130000` |
| Match Play round robin (4-way solo) | Built (D75) | 8235-8284 |
| Wolf rotation + comeback + lone/partner ledger + $/pt | Built | 7973-8011; carries / blind wolf / loss cap **dials unbuilt** (batch-2 #10 "later toggles") |
| 3-player Wolf ("pig") | Hard-cut (D16) | 8907 exactly-4 |
| Skins with carry-over | Built (D9) | 8095-8113 |
| Sunningdale Rules 1v1/2v2 + bank; solo variant | Built (D74/D75), tested | 8122-8178, `tests/sunningdale.test.mjs` |
| Nassau / presses / Colonel Dallmeyer | Unbuilt (roadmap) | spec §13.2, D74 "not shipped" |
| One-phone scorekeeper → everyone's phone sync, guest pencil | Built (D85–D88) | `20260728120000/180000/220000` |
| Match-play milestone posts to the board mid-round ("3UP thru 12") | Unbuilt | gameplay-modes §2.3 ⚑ / 7b implementer default; only the finish posts |
| `game_ledger` flat table | Unbuilt; JSONB `holes` envelope instead (D78) | `game_results` dead |
| Guest claim (tee sheet + scan partner) | Built | `20260716140000`, `20260718045514` |
| Plan → tee sheet prefill (declared round parent) | Built | 8349-8375 |
| Scheduled rounds: detail sheet, RSVP, comments, course, weather, Home cards | Built (all 6 stages) | `spec/scheduled-rounds-arc.md` STATUS |
| Ryder: create, roster, auto-seed pairings, bench rotation, resolve, clinch, draw rules, tick, targets, opt-in taunt, MVP, trophies, event board, lineage series | Built | migrations `20260713120000` → `20260727180000` |
| Ryder pot / buy-in / settlement card (§R12.4 thin version) | **Unbuilt for the Ryder** (`buy_in` column exists but only the Major writes it; no Ryder settlement card) | `create_event` ignores buy-in; room shows none |
| Ryder captains-pick draft, blind envelopes, fourball sessions, live-day finale, session weighting UI, MVP pot cut, recurring defense (`defender_team_id`) | Unbuilt (§R11) | column-only |
| Ryder "your match this week" on Home | Unbuilt | no Home reference to `event_duels` |
| Major: create, field line, exhibition, window tick, narration triggers, countback, pot 60/25/15|wta, trophy, jug card, annual lineage | Built (D42–D46, D61) | `20260720193000`, `20260724100000` |
| Major playoff window, runner-up hardware, 9-hole dial, order-of-merit, earned champion's marker | Unbuilt (§10.8) | — |
| Bracket event | **Unbuilt** (IA only; picker says SOON) | 15298-15300, `trophies.kind 'bracket'` reserved |
| Weekly clash spotlight (D52: one pairing per league per week, board posts) | **Decided, unbuilt** | no migration; only the retro `my_rivalries` clash record exists |
| Rivalry record (faceted, named) | Built | `rivalries.sql`, `named_rivalries.sql`, slice3 |
| Personal stakes (D51) | Client sheet only, **no RPC** | 10968-11010; nothing in contract.psv |
| The Callout (public number-to-beat with auto-settle) | Parked | gameplay-modes §11 |
| 2-player rivalry season | Parked | §11 |
| Season Format B monthly matchups / Format C hybrid +15 | Retired (D48) | spec §4 note |

---

## 10. Open questions

1. **Home semantics for iOS**: confirm with the owner that "match approaching" maps to (a) live-round banner and (b) open Ryder duel only — and that a golfer in neither state sees "your next round," not an empty opponent slot. (D12 supports this; the directive's wording does not come from this product.)
2. **Should native ship the D52 weekly clash?** It is the one *season-side* h2h with an anticipation loop and would give every league member a weekly "vs" — but it is owner-approved and unbuilt, and requires a spotlight table + posts + settle. Decide before designing Home around it.
3. **Clinch-then-orphaned sessions (§7.1)**: is "remaining duels resolve for the record" (§R4) still wanted? It changes the tick and the room.
4. **`played_on` for live finishes (§7.4)**: should `finish_live_round` grow `p_played_on` (device-local date) or compute in league tz server-side? Affects Ryder/Major eligibility on Saturday-evening rounds.
5. **Ryder buy-in/settlement**: build the §R12.4 thin version (tracked number + settlement card) now that the Major has the pattern, or keep the Ryder $0 forever?
6. **Push categories for native**: one `push_nudges` stream today (taunt + doorbell) with no mute; APNs categories need a decision on per-event/per-round mutes and whether Live Activities replace the doorbell push for members already in-app.
7. **Guest identity on native**: Universal Link `/?claim=` lands where? App Clip for the account-less guest pencil is the natural iOS answer; confirm scope.
8. **Tee sheet without a league season**: standalone Ryder/Major crews have no live scoring today. Should native allow a league-less live round (rounds belong to profiles; only the board post and `season_id` NOT NULL block it)?
9. **Hole-ledger receipts**: keep the JSONB `game_result.holes` as canon, or finally build `game_ledger` so receipts are queryable across rounds (rivalry facets for match play/wolf per batch-3 #18 are still unbuilt — `my_rivalries` has no tee-sheet facet)?
10. **Duplicate display names** break `game_config` name→index mapping (§7.8); should `game_config` store `live_round_players.id`s (a migration) before native re-implements the reconstruction?
