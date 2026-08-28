# Reliability floor — IOS-024

What the phone writes into `client_events`, where the five product events
fire, how to read a crash row, and the one deploy the owner runs.

## One writer

`apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Telemetry.swift` —
`CSTelemetry.event(_ name, _ props)`. Fire-and-forget (`Task.detached`,
utility priority), never throws, never blocks the caller, and a burst of the
same name + props inside **2 s** writes one row (`TelemetryDedupe`).
`PostService.event` and `WizardService.track` still exist with their event
names (`post_open`, `post_submit`, `league_create`, `lock_ok`, …) and delegate
here; there is no other insert into `client_events` on the phone.

The row is the web's row — `qaEvent` at index.html 6100 — so the founder's
desk (web `renderFounderDesk`, phone `FeedbackSheet`) reads phone rows like web
rows:

| column       | value                                              |
|--------------|----------------------------------------------------|
| `event`      | the name (≤ 64 chars, table check)                 |
| `props`      | jsonb, see shapes below                            |
| `profile_id` | defaults to `auth.uid()` server-side               |
| `created_at` | `now()`                                            |

**Blind spot, kept on purpose:** the insert is RLS'd to `authenticated`
(`ce_insert_own`, migration `20260717153000`). A signed-out phone writes
nothing, exactly like a signed-out web tab (CLAUDE.md, the CLOSED 2026-07-27
paragraph). The Door's failures before sign-in are therefore not in this
table. No PII rides in `props` — no emails, names or handles, ever.

## Crashes and hangs — MetricKit

`apps/ios/CupSeason/MetricsSubscriber.swift`, registered in
`AppDelegate.application(_:didFinishLaunchingWithOptions:)`. MetricKit hands
the app its own crash and hang diagnostics on the **next launch**, at most
once a day, so a crash row is delayed by up to a day and is written by the
launch after the crash (a signed-in one — see the blind spot above).

Why there is no `NSSetUncaughtExceptionHandler` and no "top-level Task error
hook": a Swift trap (`fatalError`, force-unwrapped nil, out-of-bounds) is a
SIGTRAP/SIGILL, not an NSException, so the handler never sees it; even for a
real ObjC exception it runs on a dying process where an async insert cannot
complete; and an unhandled error in a `Task` is that task's result, not a
process event — Swift has no global hook for it. MetricKit is the crash
source.

Row shapes (`event = 'client_error'`, matching the web's `kind/msg/stack`):

```json
{"kind":"crash","msg":"crash: signal 11 (SIGSEGV)","signal":11,"exception":1,
 "exception_code":0,"exception_name":"NSRangeException","exception_class":"NSArray",
 "termination":"...","stack":"CupSeason+0x1a2b4 <- CupSeason+0x9f00 <- libswiftCore+0x3c10 <- CupSeason+0x1200",
 "build":14,"os":"iPhone OS 18.6 (22G86)","device":"iPhone15,2"}

{"kind":"hang","msg":"hang: 3.2s on the main thread","duration_s":3.2,
 "stack":"CupSeason+0x… <- …","build":14,"os":"…","device":"…"}
```

`stack` is the four innermost frames of the attributed thread, innermost
first, `Binary+0xoffset`, capped at 400 chars — the web's `trace()` shape.
On-device frames are never symbolicated; the binary name and the offset into
its text segment are what `atos -o CupSeason.app.dSYM/... -l <load> <addr>`
wants, with the dSYM of the build named in `build`. `build` is the build the
crash came **from** (`MXMetaData.applicationBuildVersion`), which may be older
than the one reporting it. The optional keys (`signal`, `exception`,
`exception_code`, `exception_name`, `exception_class`, `termination`) are
present only when MetricKit supplied them. `composedMessage` is deliberately
not stored — it can carry object descriptions.

Reading crashes from the SQL editor (bypasses RLS):

```sql
select created_at, profile_id,
       props->>'kind' as kind, props->>'msg' as msg,
       props->>'build' as build, props->>'os' as os,
       props->>'stack' as stack
from public.client_events
where event = 'client_error' and props->>'kind' in ('crash','hang')
order by created_at desc
limit 50;
```

All client errors, phone and web together (the web's rows have `kind` of
`error` / `rejection` and a `step`):

```sql
select created_at, props->>'kind' as kind, left(props->>'msg', 120) as msg, props->>'stack' as stack
from public.client_events where event = 'client_error' order by created_at desc limit 100;
```

## The five product events

Props are exactly `{build, league_id?}` — `build` is the reporting app's
`CFBundleVersion` (0 when unstamped: tests, previews), `league_id` a
lowercase uuid when there is one.

| event            | fires at                                                                                                    | file |
|------------------|-------------------------------------------------------------------------------------------------------------|------|
| `signed_in`      | the first `.ready` after a `SIGNED_IN` auth event — never on an `INITIAL_SESSION` Keychain restore. If the sign-in lands on the card gate first, it fires on the `.ready` that follows `card_set`. | `CupSeasonKit/SessionStore.swift` (`signInPending`) |
| `card_set`       | the card gate's `set_profile` succeeded                                                                     | `CupSeason/Onboarding/CardGateView.swift` `save()` |
| `league_created` | `create_league` returned an id (`league_id`)                                                                | `CupSeasonKit/Wizard/WizardService.swift` `createLeague` |
| `league_locked`  | the lock's fourth write (`leagues.phase`) succeeded (`league_id`)                                            | `CupSeasonKit/Wizard/WizardService.swift` `lock` |
| `round_posted`   | the `rounds` insert returned an id — before holes/photo, which are garnish. No `league_id`: a round belongs to a profile and fans out to every league. | `CupSeasonKit/Post/PostService.swift` `insert` |

Funnel query:

```sql
select event, count(*) filter (where created_at > now() - interval '7 days') as last_7d, count(*) as total
from public.client_events
where event in ('signed_in','card_set','league_created','league_locked','round_posted')
group by event order by array_position(array['signed_in','card_set','league_created','league_locked','round_posted'], event);
```

## `test-seed` is founder-only (SEC-H2 closed)

`supabase/functions/test-seed/index.ts`: after the JWT check the function
reads `profiles.is_founder` for the caller with the service client and answers
`403 {"error":"founder only"}` to anyone else. Every invocation logs one line
— `[test-seed] caller=<uuid> action=<seed|reset> allowed=<true|false>` (or
`caller=none … reason=not-signed-in`) — so in the function's logs a denied
call, an allowed call and a misrouted call all read differently.

**Not deployed by the build.** The owner ships it from the repo root:

```
supabase functions deploy test-seed
```

Verify afterwards from a non-founder account: `POST {action:"reset"}` must
return 403 and the log line must say `allowed=false`.

## Tests

`apps/ios/Packages/CupSeasonKit/Tests/CupSeasonKitTests/TelemetryTests.swift`
— the dedupe window (2 s, key-order independence, pruning) and the call-stack
walk (four innermost frames, attributed thread, heaviest fork, garbage in →
empty stack, the 400-char cap). Both are pure; nothing touches the network.
