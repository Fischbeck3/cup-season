# The push sender — wave 7 (D104 · IOS-026)

The server half of `docs/ios/push-contract.md`. The phone half is built
against the contract, not against this file; nothing here changes a key name.

## What changed

**Migration `20260827210000_push_wave7.sql`**

| # | Change | Why |
|---|---|---|
| 1 | `push_nudges.kind` (`nudge` default; `invite`/`request`/`rsvp`) + `push_nudges.payload jsonb` | one row = one recipient stays; the row now says what it is and carries the ids the phone routes on |
| 2 | `leagues.notify_system boolean default true` | the Pro's curation flag for `system` board posts (contract §5.4); nothing reads it off yet |
| 3 | `invite_golfer` — verbatim + a `push_nudges` row for the invitee (`kind='invite'`, title = league/event name, body "`<First> put you on the tee sheet`", payload `{invite_id, league_id}` or `{invite_id, event_id}`) | it promised a notification since 20260713180000 and sent none |
| 4 | `friend_request` — verbatim + a `push_nudges` row for the addressee (`kind='request'`, "`<First> wants in your crew`" / "Tap to accept", payload `{request_id, profile_id}`) | the request push now carries `request_id` + `CS_REQUEST`; the function's `friendships` webhook branch keeps the **email only**, so a request pushes once whether or not that webhook is wired (the audit could not confirm it) |
| 5 | `declare_round` / `retag_round` — verbatim + a `push_nudges` row per **newly** tagged golfer (`kind='rsvp'`, "`<First> put you on the tee sheet`" / "`Sat Sep 5 · Encanto GC — in or out?`", payload `{scheduled_round_id, profile_id}`) | tagging is the invitation to a scheduled round (D69: only the host and the tagged may RSVP) and it rang no doorbell |
| 6 | `actionable_count_of(p_profile)` (service_role only) + `my_actionable_count()` (authenticated) | ONE definition of "actionable" — pending requests to me + open invites to me + live rounds I am on that are `setup`/`live` — used by both the badge and the phone |

Every `create or replace` is the latest definition copied verbatim (source
cited above each one in the file) plus the marked `D104` lines. Grants are
re-stated per D37. No scoring or mechanic change.

**`supabase/functions/push/index.ts`**

- `sendTo(profileIds, title, body, route)` — the web-push payload is unchanged
  (`{title, body, url:'/'}`); `route` is APNs-only.
- `sendApns` builds the contract's payload: `aps.alert` (the same clamped
  strings), `aps.sound`, `aps["thread-id"]` (`league_id` | `event_id` |
  `you`), `aps.badge` (the recipient's actionable count, one
  `actionable_count_of` call per distinct recipient), `aps.category` only for
  the three actionable kinds, and `cs` (`v:1`, `kind`, only the ids that
  exist). Header `apns-collapse-id` = the post / nudge id so a webhook retry
  folds instead of doubling. `apns-push-type` stays `alert`.
- Recipients (contract §5): never the author; `notify_chat`/`notify_rounds`
  as before; anyone who muted the author is dropped (`mutes.muted = author`,
  one query); a plain `system` post exits `curated-off` when
  `leagues.notify_system` is false. A `system` post that carries
  `live_round_id` is the **settlement** (D92) — routed as `settlement`, never
  curated off.
- `push_nudges` path reads `kind` + `payload`: `invite` → `CS_INVITE`,
  `request` → `CS_REQUEST`, `rsvp` → `CS_RSVP`, anything else → `nudge` with
  `event_id`/`live_round_id`/`league_id` from the payload when present. All
  thread as `you`. A nudge whose payload names an author (`profile_id`) is
  dropped with exit `muted` if the recipient muted them.
- `posts` path maps `posts.kind` → `cs.kind` verbatim (`round`, `chat`,
  `announce`, `moment`, `system`; `system`+`live_round_id` → `settlement`) with
  `league_id`, `post_id`, and `round_id` / `live_round_id` when the row has
  them. Event posts route as `event` with `event_id` + `post_id`.
- `live_open` is a realtime broadcast on the league channel today, not a
  post — it never reaches this function and is left alone.
- New named exits: `curated-off`, `muted`. Every send logs one line with
  kind and recipient count; APNs logs kind / thread / category / tokens /
  sent / pruned. Ids only in logs, no names or emails.

## Owner's commands (in order)

```sh
# 1. the APNs key — once (contract §8, Team ID 3F7BK4WVH8)
supabase secrets set APNS_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=XXXX APNS_TEAM_ID=3F7BK4WVH8
# only while a tethered dev build is under test — unset before TestFlight (runbook D5):
supabase secrets set APNS_SANDBOX=1
supabase secrets unset APNS_SANDBOX

# 2. the database, then the function (either order is skew-safe: the function
#    sends without a badge and treats a missing notify_system as on until the
#    migration lands; the migration's nudges send as plain nudges until the
#    function lands)
supabase db push
supabase functions deploy push --no-verify-jwt
```

Then refresh the RPC snapshot (`packages/db/contract.psv`) and the generated
Swift so `Rpc.my_actionable_count` exists for the phone.

## Reading the log for one send

A chat line posted from the web by a second account, with one phone
registered, reads top to bottom:

```
[push] invoked table=posts type=INSERT kind=chat
[push] kind=chat cs=chat recipients=3 muted=0
[push] kind=chat recipients=3 web sent=1 pruned=0
[apns] kind=chat thread=<league_id> category=- tokens=1 sent=1 pruned=0
[push] exit reason=sent {"kind":"chat","recipients":3}
```

- `recipients=` is after the author, the `notify_*` prefs and mutes are
  applied; `muted=` is how many roster members were dropped for muting the
  author.
- `web sent=` counts web-push subscriptions; `tokens=` / `sent=` under
  `[apns]` count device tokens. `pruned=` are dead endpoints removed.
- No `[apns]` line at all means the `APNS_*` secrets are not set (the branch
  is dormant). `[apns] kind=… no device tokens` means nobody on the recipient
  list has registered a phone.
- `[apns] badge unavailable profile=<id> msg=…` means `actionable_count_of`
  could not be called — the function deployed before the migration; the push
  still went, without a badge.
- An invite reads `[push] invoked table=push_nudges … kind=invite` →
  `[push] kind=invite recipients=1` → `[apns] kind=invite thread=you
  category=CS_INVITE …`.
- Exits that are not `sent` and what they mean: `curated-off` (the Pro turned
  system posts off for that league), `muted` (the one recipient muted the
  author), `empty-body`, `no-league-or-event`, `friendship-no-op`, `no-record`.

## Not in this wave (recorded so it is findable)

- `start_live_round`'s D86/D88 "put you on the tee sheet" nudge and the Ryder
  taunt (20260716160000) insert no `payload` yet, so they route as `nudge`
  with no ids and land Home. Adding `kind, payload` to those two inserts
  (`live_round_id` + `league_id`; `event_id`) is a one-line change each, in a
  new migration that copies the latest bodies (`20260728220000_visitor_rounds.sql`,
  `20260716160000_ryder_slice3.sql`).
- The `friendships` webhook: if it is wired, buddy requests now email from it
  and push from `push_nudges`; if it is not, they push and do not email.
  Verify with `pg_get_triggerdef` (mask `x-push-secret`) per the CLAUDE.md
  landmine.
