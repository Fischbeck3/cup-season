# Live Round Sync + Scoreboard-First Layout — design (D85)

**Date:** 2026-07-28 · **Status:** approved by owner (chat), build authorized
**Supersedes:** gameplay-modes-working.md flag #16 corollary ("one designated
scorekeeper phone is the v1 primary model; everyone's-phone live sync is v2") —
this IS the v2, on schedule, not a conflict. The rest of flag #16 (every state
enterable after the fact, catch-up first) stays binding and shaped this design.

## What it is

Two changes to the tee sheet, shipped together:

1. **Sync** — everyone in the group scores from their own phone. Members join
   from a Home banner; guests join from their existing claim link, mid-round,
   no account. Any player edits any cell (owner's call: the 18Birdies model —
   survives dead phones, keeps flag #16's catch-up rule true). Scores converge
   across phones in real time.
2. **Layout** — the scoreboard moves to the top of the play screen and sticks:
   game status is the hero line ("2UP thru 7" / wolf points / skins carried /
   Sunningdale status), per-player net+gross chips under it. Game detail cards
   leave the main flow into a tap-in sheet. Kills the scroll-bounce between
   entry rows and standings (the owner's actual complaint — not clicks).

## Decisions (owner, this session)

- Sync model: **anyone edits anything** (rejected: own-column-only — breaks
  catch-up when a phone dies; scorekeeper+viewers — she can't input).
- Scope: **members AND guests**, guests via claim token, must be seamless.
- Leaderboard: **game leads, strokes under**; no game → strokes lead.
- Pain diagnosis: scrolling, not clicks. Entry (± model) unchanged.

## Architecture: broadcast-first, RPC-durable (chosen over postgres_changes / polling)

- Transport: Supabase Realtime **broadcast** on `live:<round_id>:<join_code>`,
  on **rtClient** (dedicated client — landmine: never `sb`). Public channel;
  secrecy = unguessable `join_code`. Carries scores + first names only.
  Durable writes always re-auth (session or claim token) — the channel is a
  rumor mill, the DB is the record.
- Why not postgres_changes: anon (guests) can't receive table changes — D37
  gives anon zero relation privileges, by design. Two sync paths = worst of both.
- Why not polling-primary: standings lag kills the moment. Polling survives as
  the reconcile layer.
- Local-first stays the backbone: `state.live` + localStorage snapshot
  (`persistLive`) exactly as today. Sync layers on top. Courses are dead-zone
  country; scoring NEVER blocks on network.

### Data model (new migration)

```
live_scores (
  live_round_id uuid  references live_rounds on delete cascade,
  player_id     uuid  references live_round_players on delete cascade,
  hole          smallint check (hole between 1 and 18),
  strokes       smallint,          -- null = cleared
  client_ts     timestamptz,       -- writer clock, LWW key
  updated_at    timestamptz,       -- server arrival
  updated_by    uuid,              -- league_members.id, null when a guest wrote
  primary key (live_round_id, player_id, hole)
)
-- RLS enabled, NO policies, NO grants — RPC-only access (D37 pattern).
live_rounds + join_code text      -- unguessable channel key, minted at tee-off
live_rounds + game_state jsonb    -- wolf declarations by hole; match/skins/
                                  -- sunningdale derive from scores (sunnCalc)
```

Roster locks at tee-off (unchanged). No mid-round adds in v2.0.

### RPCs (all SECURITY DEFINER, explicit revoke public/anon + precise grants)

Members (`authenticated`); guard = caller's member row is a player in the round
(or is `started_by`):
- `live_set_score(p_live_round, p_player, p_hole, p_strokes, p_client_ts)` —
  upsert, apply only if `p_client_ts` newer than stored (LWW)
- `live_set_wolf(p_live_round, p_hole, p_wolf jsonb, p_client_ts)` — same
  semantics into `game_state->hole`
- `find_my_live_round()` — open live round where caller plays → Home join banner
- `live_state(p_live_round)` — full pull: round, players, scores, game_state

Guests (`anon`, token-keyed — extends the CLAUDE.md anon-endpoint list):
- `guest_live_state(p_token)` — round snapshot + players + scores + game_state
  + own player id + join_code; doubles as join and reconcile pull
- `guest_live_set_score(p_token, p_player, p_hole, p_strokes, p_client_ts)` —
  token must belong to a player of the same round as p_player
- `guest_live_set_wolf(p_token, p_hole, p_wolf, p_client_ts)`

Changed:
- `start_live_round` — also mints + returns `join_code` (create or replace in
  the NEW migration; old clients ignore the extra key — skew-safe)
- `finish_live_round` — `select … for update` row lock so two phones finishing
  concurrently can't double-post (second waits, sees final, gets
  `already_final`). Any member player may finish; guests cannot. Abandon stays
  starter-only.

### Sync protocol (client)

- Tap: apply local → `persistLive()` → broadcast `{t:'score',pid,h,s,cts,by}`
  → enqueue durable RPC in `localStorage` queue `cs.liveq.<id>`; serial flush,
  backoff. Receive: LWW by `cts`, re-render, persist.
- Messages: `score` · `wolf` · `finish` (all phones flip to recap) · presence
  (built-in; "on the sheet" chips). Hole position stays per-phone.
- Reconcile (`live_state`/`guest_live_state`): on SUBSCRIBED, on foreground
  (visibilitychange), after post-reconnect flush. No periodic poll.
- Degradation: broadcast down → RPCs still land, foreground pulls catch others
  up, quiet "sync degraded" chip after repeated subscribe failures. Network
  dead → today's single-phone behavior, queue drains later.
- LWW ties/conflicts: same cell from two offline phones → newest `client_ts`
  wins on reconcile; visible correction acceptable for a friend group.
- Stale flush after finish: writes reject on `status<>'live'`, queue drops.

### Join flows

- Host: setup unchanged → tee off. Live screen gains a Group sheet (players,
  presence, per-guest share link/QR).
- Member: boot calls `find_my_live_round()` → Home banner "Round at <course>
  is live — Join" → pull, subscribe, play. Zero links.
- Guest: the per-player claim link (`/?claim=<token>`) now ALSO works
  mid-round: round open → live scoring page, token IS identity (no name pick),
  scores; round final → today's recap/claim flow. One link, whole lifecycle.
  Guest phone runs anon: no session, rtClient without setAuth.

### Layout (play screen, top to bottom)

1. **Scoreboard block**: game hero line (match/sunningdale: "You 2UP thru 7" ·
   wolf: points · skins: carried · none: "Jade −1 net thru 7") + player chips
   (name · net · gross · thru). Tap → game sheet (ladder, ledger, wolf history,
   full grid).
2. Scroll collapses it to a sticky one-liner (hero + micro chips),
   `position:sticky`, class toggle — no animation-gated visibility (landmine).
3. Hole indicator + dots, one row. Course eyebrow folds into the sticky strip.
4. Entry rows — untouched ± model.
5. Bottom hole-nav banner — unchanged.
Game cards leave the main flow (the scroll destination dies).

### Guards & landmines honored

- Demo: every sync path gated `!state.demo`.
- rtClient dedicated client; subscribe-status breadcrumb kept.
- No anon table grants anywhere; token RPCs fail closed.
- Snapshot version `v` bump + load migration.
- Mixed middot encodings in index.html: anchor edits on ASCII lines.
- Deploy skew: both orders safe (old client never reads join_code; new client
  drops new-field calls on schema-cache errors per existing retry pattern).

### Testing

- `tests/db-checks.sql`: grant assertions for every new function; anon relation
  privileges still zero (checks 2/9 family).
- Browser MCP, local 8791 (serve-marker check first): host tab + second
  context on guest link; score one side, assert other's JS state. No
  screenshots (splash timeout).
- Offline: drop channel, enqueue, reconnect, assert flush + reconcile.
- LWW: same cell, both phones, newest cts wins.
- Concurrency: double-finish returns `already_final` once.

### Acceptance

Jerecho + Jade, real round, PIGL. Host scores some holes, Jade scores her own
and fixes one of his; both leaderboards agree; finish posts once.

## Build notes (deviations from the section above, 2026-07-28)

- `find_my_live_round` was NOT built: `rehydrateLiveRound`'s existing
  RLS-scoped select already surfaces every open round the member plays in, on
  every device — it just learned the `join_code` column (with an any-error
  retry for deploy skew). The member "join banner" IS the existing Continue
  banner; one machine, not two.
- Game cards did NOT move into a tap-in sheet: Wolf's partner/lone buttons are
  a required per-hole ACTION living in those cards, not detail. The sticky
  scoreboard alone kills the scroll-bounce (standings never leave the screen);
  the sheet is future polish if the page still feels long in play.
- Added: a "Group phones" sheet on the live screen — per-guest copy-link (their
  claim link, now a live pencil) and the member instruction (open the app,
  tap Continue).
- `finish_live_round` keeps its existing authorization (starter or any member
  player) with the new row lock; the design's "any member player may finish"
  was already true on the server.

## Non-goals (v2.x candidates)

Mid-round roster adds · guest live-join upgrade to account mid-round · forced
hole-follow ("spectate host's hole") · cross-course sync (explicitly rejected,
gameplay-modes §2.5 line 253).
