# The push receiver — wave 7, phone side (D104 · IOS-026)

The phone's half of `push-contract.md`. The sender (the `push` Edge Function)
is built against the same contract; the key names here are its, verbatim.

## Where things live

| File | What |
|---|---|
| `Packages/CupSeasonKit/…/Push/PushPayload.swift` | pure: `PushPayload` (the `cs` object + `aps.category`), `PushKind`, `PushRoute.from`, `PushCategory`, `PushActionCall.resolve` / `.run` |
| `Packages/CupSeasonKit/…/Push/PushBadge.swift` | `my_actionable_count()` (hand-declared `RpcCall`) → `setBadgeCount`; fail closed |
| `Packages/CupSeasonKit/…/Push/PushAskPolicy.swift` | pure: the three reasons, the 14-day snooze, `shouldAsk` |
| `Packages/CupSeasonKit/…/Push/PushDuelPlan.swift` | pure: the room → schedule/cancel plan for the 18:00 reminder |
| `CupSeason/AppDelegate.swift` | `UNUserNotificationCenterDelegate`: `willPresent` (banner + list + sound, no badge), `didReceive` (tap → router · action → RPC), launch-options stash, category registration |
| `CupSeason/Push/PushRouter.swift` | `@MainActor @Observable`, one `pending: PushRoute?` |
| `CupSeason/Push/PushActions.swift` | `PushCategories.register()`, `PushActionRunner.run` (RPC → failure line → badge) |
| `CupSeason/Push/PushAsk.swift` | the ask coordinator + `PushPromptSheet` |
| `CupSeason/Push/PushDuelReminder.swift` | the plan → `UNCalendarNotificationTrigger`s; `cancelAll()` on a posted round |
| `CupSeason/Push/PushDev.swift` | DEBUG launch arguments (below) |
| `CupSeason/Main/MainTabView.swift` | drains the router (`apply(_:)`), the badge triggers, the ask's stage rule |
| `CupSeason/Main/Presenter.swift` | `anythingUp` / `dismissAll()` |
| `supabase/migrations/20260827210000_my_actionable_count.sql` | the badge RPC (see "the migration" below) |
| `Packages/CupSeasonKit/Tests/CupSeasonKitTests/PushTests.swift` | 11 tests: every kind → route, missing ids → Home, unknown `v` → nil, the action map, the snooze, the reminder plan |

## The route table, as built

`PushRoute.from(payload)` then `MainTabView.apply(route)`. Anything already on
stage comes down first (`presenter.dismissAll()`, 450 ms for the curtain),
except for `.live`, which is its own cover.

| `kind` | needs | `PushRoute` | what `apply` does |
|---|---|---|---|
| `round` | `round_id` | `.receipt(id)` | `presenter.receipt = id` |
| `settlement` | `live_round_id` | `.scorecard(id)` | `presenter.scorecard = id` |
| `chat` `announce` `moment` `system` | `league_id` | `.board(league)` | `store.preferredLeague = league`; Clubhouse tab; `clubPath = [ClubRoute.board(league)]` |
| `live_open` | `live_round_id` | `.live(id)` | `LiveRoundStore.shared.handleLiveOpen(lr:)` then `presenter.showLive = true` |
| `nudge` | `event_id` → else `live_round_id` | `.event(id)` / `.live(id)` | as above |
| `event` | `event_id` | `.event(id)` | `presenter.event = id` |
| `invite` | — | `.invites` | Home tab, path cleared (the banner is at the top) |
| `request` | — | `.requests` | Home tab; `homePath = [HomeRoute.people]` |
| `rsvp` | `scheduled_round_id` | `.scheduledRound(id)` | `presenter.scheduledRound = id` |
| any kind, id missing · unknown kind | — | `.home` | Home tab, path cleared |
| no `cs` · `v != 1` | — | (payload nil) → `.home` | same; telemetry says `kind: unreadable` |

Cold start: `didFinishLaunchingWithOptions[.remoteNotification]` →
`PushRouter.shared.open(userInfo:)`; the route waits in `pending` until
`MainTabView` exists (`AppState.ready`) and its `.task(id: router.pending)`
drains it. Foreground: the system banner shows; the tap takes the same path.
The local duel reminder carries `{v:1, kind:"event", event_id}` so it lands
in the room through the same table.

## The three lock-screen actions

| category | action | `PushActionCall` | RPC (the screen's own) |
|---|---|---|---|
| `CS_REQUEST` | `ACCEPT` | `.friendRespond(id: request_id, accept: true)` | `friend_respond(p_id, p_accept)` via `PeopleService.respond` |
| `CS_REQUEST` | `DECLINE` | `.friendRespond(id: request_id, accept: false)` | `friend_respond(p_id, p_accept)` |
| `CS_RSVP` | `IN` | `.roundRsvp(round: scheduled_round_id, status: "in")` | `set_round_rsvp(p_round, p_status)` via `ScheduleService.rsvp` |
| `CS_RSVP` | `OUT` | `.roundRsvp(round: scheduled_round_id, status: "out")` | `set_round_rsvp(p_round, p_status)` |
| `CS_INVITE` | `ACCEPT` | `.respondInvite(id: invite_id, accept: true)` | `respond_invite(p_id, p_accept)` via `PeopleService.respondInvite` |

Buttons wear "Accept" / "Decline" and "I’m in" / "Can’t". No `.foreground`
option — the app stays down. On a thrown error a local notification lands
with the original title and "That one didn’t take — open the app." Every
action ends with `PushBadge.refresh()`. Telemetry: `push_action {kind, ok}`.

## The badge

`PushBadge.refresh()` calls `my_actionable_count()` and sets the count; an
error (no session, RPC missing, offline) leaves the badge untouched. Called:

- `scenePhase == .active` (MainTabView)
- after `PeopleScreen` paints (the Requests list is on it)
- after `InvitesCount.load()` (the Home banner)
- when `presenter.showLive` flips either way (a live round opened or finished)
- after every lock-screen action

`willPresent` never bumps the badge from the payload; `aps.badge` from the
sender is the same count computed server-side.

## The contextual ask — trigger points

`PushAsk.shared.request(reason)` at the moment; `MainTabView` presents when
`presenter.anythingUp == false` and no route is pending (`drainAsk()`, also
re-tried 500 ms after any sheet or cover comes down).

| reason | where the request fires |
|---|---|
| `card_saved` | `CardGateView.save()` after the successful `set_profile` — Home is not up yet, so the sheet rises once the tab shell appears |
| `first_round` | `EpilogueSheet.onAppear` when `show.firstEver` — rises after the epilogue and the composer are down |
| `league_joined` | `JoinLeagueFlow` (the welcome sheet's dismiss, both hosts), `InvitesBanner` accept of a league invite, the wizard's `onJoined` |

The sheet shows only when the system status is `.notDetermined` and no
"Not now" is younger than 14 days (`cs_push_ask_declined_at`). A swipe-down
counts as "Not now". "Turn on notifications" runs `PushService.enable()` —
the same door Settings uses — and toasts its reply. Never on launch.
Telemetry: `push_prompt_shown / accepted / declined {reason}`.

## The duel reminder

`EventRoomModel.load()` → `PushDuelReminder.sync(room:)` → `PushDuelPlan.make`.
For each session of the room: open, `closes_on == today` in the event's
`tz` (default `America/Phoenix`), I am a side of a pending duel in it and my
side has no round, and 18:00 has not passed → one request `duel-<session_id>`
at 18:00 that day (`UNCalendarNotificationTrigger`, the event's time zone).
Every other session's identifier is removed. `EpilogueSheet.onAppear` removes
every `duel-*` request (one card serves every open session; the next room
load re-plans). Majors never schedule. Copy: "Your duel closes tonight" /
"You haven’t posted." with the event name as the subtitle.

## Testing without APNs (simulator)

The build is installed on the simulator; launch with arguments:

```
UDID=9C09C054-0AF9-42EE-830E-0E0EDBA7D87D
xcrun simctl launch --console $UDID app.cupseason.ios -cs_dev_push_ids      # prints real ids to feed below
xcrun simctl launch $UDID app.cupseason.ios -cs_dev_push_prompt             # the explainer sheet
xcrun simctl launch $UDID app.cupseason.ios -cs_dev_push '{"v":1,"kind":"chat","league_id":"<uuid>"}'
xcrun simctl launch $UDID app.cupseason.ios -cs_dev_push '{"v":1,"kind":"round","round_id":"<uuid>"}'
xcrun simctl launch $UDID app.cupseason.ios -cs_dev_push '{"v":1,"kind":"request","request_id":"<uuid>"}'
```

`-cs_dev_push` takes the `cs` object (with an optional `category`) or a
whole `{aps, cs}` payload and routes it two seconds after the session is
ready, exactly as a tap would. End to end through `UNUserNotificationCenter`:

```
cat > payload.apns <<'EOF'
{ "Simulator Target Bundle": "app.cupseason.ios",
  "aps": { "alert": { "title": "PIGL", "body": "a line on the board" }, "sound": "default", "thread-id": "<league_id>" },
  "cs": { "v": 1, "kind": "chat", "league_id": "<league_id>" } }
EOF
xcrun simctl launch $UDID app.cupseason.ios -cs_dev_push_autoopen
xcrun simctl push $UDID app.cupseason.ios payload.apns
```

The banner shows (`willPresent`); a simulator cannot be tapped from a
script, so `-cs_dev_push_autoopen` routes a foreground arrival as if it had
been. A real device tap exercises `didReceive` — same router. Lock-screen
actions cannot be driven in the simulator either; `PushActionTests` prove
the mapping and `PushActionCall.run` is the screens' own service calls.

## The migration

`20260827210000_my_actionable_count.sql` creates the badge RPC (pending
requests to me + pending invites to me + open live rounds I am seated on or
started or am a guest of), `security definer`, granted to `authenticated`,
revoked from `public, anon`. Preflight 17 holds the hand-declared call to
that grant. If the sender's wave-7 migration also creates it, keep one — both
are `create or replace` with the same signature, so the order is harmless,
but one file is the rule. After `supabase db push`, refresh the snapshot
(`packages/db/contract.psv`) and `node tools/build-db.mjs`; `Rpc.swift` then
carries `my_actionable_count` and `PushBadgeCountCall` can go.

## What the owner must do (contract §8)

1. Apple Developer → Keys → new key with Apple Push Notifications service →
   `.p8` + Key ID. Team `3F7BK4WVH8`.
2. `supabase secrets set APNS_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=XXXX APNS_TEAM_ID=3F7BK4WVH8`
   (+ `APNS_SANDBOX=1` only while a tethered dev build is under test).
3. `supabase db push` (this migration + the sender's), `supabase functions deploy push`.
4. On a real phone: turn notifications on from the ask or Settings; post a
   chat line from the web as a second account; the banner shows; tapping
   lands on the Board. A buddy request from the web shows Accept / Decline
   on the lock screen.

## Left open

- The explainer's eyebrow per reason and the three lines are first copy —
  read them aloud once before TestFlight.
- `nudge` with neither `event_id` nor `live_round_id` lands Home (the
  contract lists both as optional; the sender should always send one).
- The badge is not decremented locally on an action; it is recomputed from
  the server, so an offline action leaves the old number until the next
  foreground.
