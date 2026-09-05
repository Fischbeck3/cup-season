# Verify SP-9 · lens "reproduces-at-tip" · 2026-09-04 · tip 3bba87e

Verdict: **holds = true**, with corrections. The behaviour is in the shipping phone
and in the web. Prod is at migration parity with tip (`supabase migration list
--linked`: every local file has a remote row, including the four dated 2026-09-04),
so the SQL read here is what runs.

## What I SAW (phone first, then web)

### 1. The notification graph is the league graph
- `supabase/functions/push/index.ts:485-521` — a league board post's recipients are
  `league_members` of `record.league_id`, minus the author (`m.id !== record.member_id`),
  minus `notify_chat`/`notify_rounds` opt-outs, minus muters. No read of `friendships`
  anywhere in the fan-out. The only `friendships` branch (`:344-375`) is the request
  EMAIL and the accept ping ("<First> is in your crew"), one recipient each.
- `posts_home_check` (`20260716160000_ryder_slice3.sql:27-29`) requires
  `league_id is not null or event_id is not null` — a leagueless golfer's round has
  nowhere to post, so it never reaches the webhook.
- Prod (read-only): 39 profiles, **14 leagueless**, 25 members, **11 in ≥ 2 leagues**,
  12 accepted buddy pairs; only **2** of the 14 leagueless golfers have any buddy.

### 2. The kinds
- `push/index.ts:100-103` `CsKind` = round · chat · announce · moment · system ·
  settlement · live_open · nudge · invite · request · rsvp · event. The phone mirrors
  it: `PushPayload.swift:14-16`. `push_nudges.kind` check (`push_wave7.sql:36-37`):
  nudge / invite / request / rsvp. No rank-change, points-to-next, seat-count,
  challenge or season-start kind.
- Every `push_nudges` inserter at tip (11 files): invite_golfer, friend_request,
  declare_round / retag_round (rsvp), start_live_round (nudge), round_duel_nudge
  (the Ryder taunt, nudge). Prod: 18 rows — 11 nudge, 6 request, 1 rsvp, 0 invite.

### 3. N copies for a multi-league golfer
- A round posts once per league (prod: two `round_id`s each with 2 posts in 2 leagues);
  "<Month> is in the books. The ledger is posted." posts per league
  (`run_month_closes` loops leagues; prod: 1 per league across 2 leagues in the last
  10 days). `apns-collapse-id` = `record.id` (`index.ts:272` sets the header; the league
  branch passes `collapseId: record.id` at `:517`) and `thread-id` = `league_id`
  (`:131`, `:267`), so the copies neither fold nor group.

### 4. One sentence, three invitations
- "<First> put you on the tee sheet": `invite_golfer` (`push_wave7.sql:83`), the live
  `declare_round` (`20260902203000_a_booking_knows_its_round.sql:134`),
  `start_live_round` (`20260831120000_board_voice_natural_case.sql:2348-2352`).

### 5. The local duel reminder
- `PushDuelReminder.sync` is called only from `EventRoomModel.load()`
  (`EventRoomModel.swift:44`); `EventRoomModel` is built only by
  `EventRoomScreen.swift:16`; `PushDuelPlan.make` schedules only when
  `s.closes_on == today` (`PushDuelPlan.swift:39`). `cancelAll` on post
  (`EpilogueSheet.swift:55`). So it exists only if you opened the room on closing day.

### 6. The ask
- Requested at `CardGateView.swift:238` (`PushAsk.shared.request(.cardSaved)`), also
  at `EpilogueSheet.swift:54` (first round) and five `leagueJoined` sites.
  Presented by the tab shell: `MainTabView.swift:330` (`.task(id: ask.pending)`),
  `:444-447` (`drainAsk` → `presentIfDue`). Boot: `.cardGate` → `.ready` →
  `OrientationScreen` when `OrientedFlag.take` → `MainTabView` (`RootView.swift:34-42, 69`).
  Copy `PushAsk.swift:86-90` ("A round lands on the board. A duel is closing. The table
  moves."); "Not now" snoozes 14 d (`PushAskPolicy.swift:20`); swipe-down = declined
  (`PushAsk.swift:111`). Persona A: "A sheet rises over Home a beat later."
- Settings: `CardAndSettingsScreen.swift:488-496` — "Round pings: ON" reads
  `vm.notifyRounds` (a profile pref) beside a separate "Enable on this device" pill;
  nothing ties the two.

### 7. The rail in production
- `device_tokens`: 1 row, `ios-sandbox`; 0 `ios` (build 669 is Release → registers
  `ios`, `PushService.swift:27-31`). `push_subscriptions`: 1. `client_events`:
  `push_prompt_shown` 1 (2026-08-28), no `push_prompt_accepted`/`declined` rows,
  `push_opened` 7. `invites`: 0. `member_invites`: 2 (Jul 20/27, accepted — before wave
  7, hence no invite nudge ever). `email_queue`: 0. `leagues.notify_system=false`: 0/13.

### 8. Canon
- D23 `spec/decision-log.md:398-407`: "V1 nudges are HOME-SURFACED chips only, never
  push … Push escalation is a Year-2 decision with its own entry." D130 `:4337`
  "Push: none." Vision `product-vision-v1.0.md:123-125`. D104 `:3799-3819`.

### 9. Web
- Same webhook and fan-out; payload `{title, body, url:'/'}` (`index.ts:205`);
  `enablePush()` only from the Settings pill (`index.html:16090`, `16363-16390`); no
  contextual ask; no local reminder; pills at `index.html:15818-15823`. Strict subset.

## Corrections (the statement over-claims in four places)

A. **"the clash's result … never a push (HM-34)" is wrong on the push half.**
   `settle_week_clash` inserts a `system` post with `league_id`
   (`20260902170000_the_clash_stops_repeating_itself.sql:432-435`); `push/index.ts:485-521`
   fans `system` league-wide (member_id is null, so even the winner is included;
   `notify_system` is on for all 13 leagues). It pushes as "Galen took the week — beat
   their number by 3.2 on Saturday." with the league name beneath. HM-34 itself claims
   only the Home fold. Prod: 0 "took the week" posts yet (first clash opened 08-31).
   Amend to: the result is league-wide board news, never a personal "you took the
   week" / "Marcus took it" kind to the two duellists.

B. **"no server producer exists for … countdowns" — three day-of producers exist.**
   `clash_last_call` ("The clash closes today. Galen leads it. One round to change
   that.", `20260902170000:299-318`, `system`); the D204 first-tee horn in
   `daily_season_tick` ("The season is live. Week 1 — counting rounds start now.",
   `20260902163000_the_first_tee_horn.sql:49-67`, `system`); `lock_league` ("Bylaws
   locked. First tee Wed Sep 30 …", `:217-219`); the Major's `major_final_day`
   (`the_major.sql:346-370`). All ride `cs-daily-tick` at `20 7 * * *` UTC
   (`enable_cron_spine.sql:24`) = **00:20 America/Phoenix** (every prod season's tz), so
   each is a league-wide midnight push, not a personal, well-timed one. None is a
   countdown ("in three days"); none has fired in prod yet. Amend to: "no countdown
   and no personal producer; the day-of beats that exist are league-wide `system`
   posts fired at 00:20 local."

C. **"the vision's 'League lead changed…' has no producer" — the squad half exists.**
   `post_round_peak.sql:126-159` posts "Sandbaggers just snatched first from
   Mudsharks." as a `moment` (always delivered); prod: 15 such posts across 3 leagues.
   What has no producer: an INDIVIDUAL lead change / "you moved past Jake"
   (`season_lead` is squad-only, DL-06); "Championship clinched" (`season_scenarios`
   computes `clinched`, `20260716224500:104`, nothing posts it). "Milestone reached"
   exists (PBs, barriers, streaks — 44 moments in 30 d).

D. **Ask timing.** Replace "fires in CardGateView.save() before Home has rendered" with
   "is requested at card save (`CardGateView.swift:238`) and presented by the tab shell
   (`MainTabView.swift:330, 444-447`) over the first Home a beat after it renders,
   before anything on it has been read."

Additions that strengthen it:
- The Ryder taunt (`round_duel_nudge`, `ryder_slice3.sql:388-424`; opt-in
  `event_players.notify_target`, toggle `RyderRoomView.swift:79`) already carries the
  exact shape the brief wants — "<Name> posted — +2.3 to beat · 3 days left / closes
  tonight" — and is the template that never generalised to leagues.
- D23's own two V1 Home chips ("haven't played together in 47 days", "iron-man streak
  needs a round by Sunday") are not on the phone's Home either (no match in
  `HomeView.swift` / `HomeHeroCopy.swift`), so both halves of D23's fence are empty.
- Friendship fan-out alone would reach 2 of the 14 leagueless golfers today; the fix
  needs the buddy graph to grow with it.
- The `member_invites` rows show the invite rail (`invite_golfer` → invite nudge) has
  never emitted in prod.
