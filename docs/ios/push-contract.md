# The push contract — wave 7 (D104 · IOS-026)

One document both halves build against: the `push` Edge Function (sender) and
the phone (receiver). Web push is untouched — it keeps `{title, body, url:'/'}`
and ignores everything below.

## 1. The APNs payload

```json
{
  "aps": {
    "alert": { "title": "Galen broke 80 for the first time", "body": "Who's the bitch? · a 79. That one goes on the wall." },
    "sound": "default",
    "badge": 2,
    "thread-id": "<league_id | event_id | 'you'>",
    "category": "CS_REQUEST | CS_RSVP | CS_INVITE"        // only when actionable
  },
  "cs": {
    "v": 1,
    "kind": "round | chat | announce | moment | system | settlement | live_open | nudge | invite | request | rsvp | event",
    "league_id": "<uuid>", "post_id": "<uuid>", "round_id": "<uuid>", "live_round_id": "<uuid>",
    "event_id": "<uuid>", "profile_id": "<uuid>", "scheduled_round_id": "<uuid>", "request_id": "<uuid>", "invite_id": "<uuid>"
  }
}
```

- `title`/`body` are the SAME clamped strings web push gets (`headline()` in the
  function) — one voice, two rails.
- Only the ids that exist for that kind are present. `v` is the contract
  version; the phone ignores payloads with a `v` it does not know.
- `thread-id` groups a league's (or an event's) notifications in
  Notification Center; personal ones (requests, invites, nudges) use `you`.
- `badge` is the recipient's **actionable count** at send time (§4), never a
  running total of notifications.

## 2. Where each kind lands (the phone's `PushRouter`)

| `kind` | ids | lands on |
|---|---|---|
| `round` | `round_id`, `league_id` | the round receipt (`presenter.receipt`) |
| `settlement` | `live_round_id`, `league_id` | the scorecard (`presenter.scorecard`) |
| `chat`, `announce`, `moment`, `system` | `league_id`, `post_id` | the league's Board (Clubhouse tab, `ClubRoute.board`) |
| `live_open` | `live_round_id`, `league_id` | the live round (`presenter.showLive`) after `LiveRoundStore.handleLiveOpen` |
| `nudge` | `event_id` (or `live_round_id`) | the event room (`presenter.event`) / the live round |
| `event` | `event_id` | the event room |
| `invite` | `invite_id`, `league_id` | the invites banner on Home (Home tab, top) |
| `request` | `request_id`, `profile_id` | Requests (`HomeRoute.people`) |
| `rsvp` | `scheduled_round_id` | the scheduled round sheet (`presenter.scheduledRound`) |

Cold start: the payload is stashed and routed once `AppState == .ready`.
Foreground: a banner (system) — tapping routes the same way. A payload the
router cannot resolve lands Home, never a blank.

## 3. Categories and actions (answered from the lock screen)

| category | actions | RPC the action calls (the app's own) |
|---|---|---|
| `CS_REQUEST` (buddy request) | `ACCEPT` · `DECLINE` | `friend_respond(...)` — same as the Requests screen |
| `CS_RSVP` (a tee time you're on) | `IN` · `OUT` | `set_round_rsvp(...)` |
| `CS_INVITE` (a league invite) | `ACCEPT` | `respond_invite(...)` / the join path the banner uses |

Actions run in the background (`UNNotificationAction` without
`.foreground`), show a local confirmation in voice on failure ("That one
didn't take — open the app"), and recompute the badge (§4). Decline/Out never
need a second confirmation — the lock screen already asked.

## 4. The badge

Actionable items ONLY: pending buddy requests to me + open league invites to
me + live rounds I am on that are still open. Never chat, never rounds.

- Server: the function computes it per recipient at send time (service
  client, three counts) and puts it in `aps.badge`.
- Phone: `my_actionable_count()` (new RPC, authenticated, `auth.uid()`
  scoped) on foreground and after any action/view of Requests, Invites, or
  the live round → `UNUserNotificationCenter.setBadgeCount`. Seeing the list
  clears it — acting is not required.

## 5. Recipients (server)

1. Never the author.
2. `notify_chat` / `notify_rounds` as today (server-enforced prefs).
3. **Mutes:** drop any recipient who has muted the author
   (`mutes.muter = recipient and mutes.muted = author`).
4. **`system` posts:** delivered only when `leagues.notify_system` is true
   (new column, default `true`; the Pro can curate it off — a setting on the
   League pane later, not in this wave).
5. Invites: `invite_golfer` inserts a `push_nudges` row for the invitee
   (`kind='invite'`, `payload` carrying `invite_id` + `league_id`) → the
   existing `push_nudges` webhook sends it as a `CS_INVITE`.

`push_nudges` gains `kind text not null default 'nudge'` and `payload jsonb
not null default '{}'` so a nudge can route.

## 6. The permission ask (phone)

Never on launch. After one of: the card is saved (card gate), the first round
is posted (the epilogue), a league is joined (the join flow). One explainer
sheet first — three lines in voice, "Turn on notifications" / "Not now" — then
the system prompt. "Not now" is remembered for 14 days. Settings keeps the
manual switch as today.

## 7. The local reminder

For an open Ryder duel whose session closes today and where I have not
posted: a local notification at 18:00 league time — "Your duel closes
tonight. You haven't posted." — scheduled when the event room is opened,
cancelled when the round posts or the session resolves. One per session.

## 8. Owner's steps (in order)

1. Apple Developer → Keys → new key with **Apple Push Notifications service**
   → download `.p8`, note the Key ID. Team ID `3F7BK4WVH8`.
2. `supabase secrets set APNS_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=XXXX APNS_TEAM_ID=3F7BK4WVH8`
   `APNS_SANDBOX` is no longer needed: since 20260828010000 a Debug build registers its token as `ios-sandbox` and the sender routes each token to its own host, so a tethered dev phone and a TestFlight phone receive push side by side. (Setting it still forces everything to the sandbox host.)
3. `supabase db push` (the wave-7 migration), `supabase functions deploy push`.
4. Verify: post a chat line from the web as a second account; the phone shows
   the banner; tapping lands on the Board. `[push] kind=chat recipients=N`
   in the function log; `[apns] sent=1` under it.
