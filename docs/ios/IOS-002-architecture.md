# IOS-002 · Native iOS Architecture

*2026-08-27 · Phase 1 artifact · status: PROPOSED — blocked on one P0 (IOS-006, the stack). Everything in §2–§12 is stack-neutral or written for the recommended stack with the alternative mapped in §13.*

Evidence: `docs/ios/audit/07-backend-map.md` (every table, RPC, trigger, cron, webhook, gap), `08-web-ia-design.md` (navigation as built), `09-ios-state-and-canon.md` (the existing scaffold; the Expo-vs-Swift assessment), `04-live-games-ryder.md` (the round state model).

---

## 0. The one decision this document waits on — IOS-006 (P0)

D98 (2026-08-26) chose **Expo / React Native** for the phone, reasoning from "Android from the same codebase" and "one language across three surfaces." The directive of 2026-08-27 asks for a native app **in Xcode** with Swift concurrency, Live Activities, widgets, Dynamic Type and haptics used intentionally. Both cannot be true; the repo's own evidence (audit 09 §9) is laid out in `DECISIONS.md` IOS-006 with a recommendation. Nothing below reopens the *product* decisions of D98 (three surfaces, the phone is for the tee box, no purchase UI, email-OTP-only); only the phone's implementation language is in question.

What is true regardless of the answer: the competition model lives entirely in Postgres, the phone is a typed shell over ~40 of 156 RPCs, and the first engineering step is identical — **a signed build on the owner's iPhone** (the last `expo run:ios` failed on "No profiles for 'app.cupseason.ios'… Automatic signing is disabled"; Team ID `3F7BK4WVH8` exists and just needs selecting).

## 1. Layers

```
┌────────────────────────────────────────────────────────────┐
│ UI          SwiftUI views · design-system components        │
│             (CSTokens, CSCard, CSStat, CSEyebrow, CSSheet…) │
├────────────────────────────────────────────────────────────┤
│ Features    Home · Clubhouse · Post · Play · Board · You ·  │
│             Events · Pot · Stats · Onboarding · Settings    │
│             each = View + ViewModel(@Observable) + Route    │
├────────────────────────────────────────────────────────────┤
│ Domain      AppState machine · RoundState (the live round)  │
│             Game engines (pure) · Copy (bands, phrases)     │
│             Models (Codable, generated from the contract)   │
├────────────────────────────────────────────────────────────┤
│ Data        SupabaseService (auth · rpc · storage)          │
│             RealtimeService (dedicated client)              │
│             Repositories (Home, League, Round, Board, …)    │
│             Cache (SQLite) · OutboundQueue (SQLite)         │
├────────────────────────────────────────────────────────────┤
│ Platform    PushService · DeepLinkRouter · LiveActivity ·   │
│             Haptics · Keychain · Background tasks · Photos  │
└────────────────────────────────────────────────────────────┘
```

Rules that hold across layers:
- **Nothing authoritative is computed on the phone.** Points, index, standings, pot, settlement rows, eligibility are read from the views/RPCs. The phone *previews* (the post composer) and *labels* the preview as such.
- **Domain has no Supabase import.** ViewModels depend on repository protocols; repositories depend on `SupabaseService`. Engines and copy are pure and tested.
- **RoundState is separable from views** (the debt Phase B owes the Watch and the Live Activity, D98 Phase E): a `Codable`, `@Observable` model that the round screen, the Live Activity, and later the Watch all render.

## 2. Navigation

Canon: the four places (D82) — **Home · Clubhouse · ⊕ · You**. Tab order and names do not change.

```
TabView
├─ Home        NavigationStack → Schedule, RoundDetail (scheduled), Event room, Round receipt,
│                                 Tour Card, Requests/Inbox, Notifications settings
├─ Clubhouse   NavigationStack → Standings (root, league switcher in the toolbar) → Board,
│                                 Squad receipt, Member history, Pot, Members, Album, Bylaws,
│                                 Event rooms (Ryder / Major), Draft night (read-only reveal)
├─ ⊕           fullScreenCover with its own NavigationStack
│                Post (root — the 90% case) · Play (tee sheet) · Plan (declare a round)
└─ You         NavigationStack → Your card, Buddies, Rivalries, Trophy case, Stats,
                                 Settings, Legal (SFSafariViewController), Delete account
```

- **Objects are pushed** (Tour Card, round receipt, scorecard, members, squad receipt). **Actions are sheets** with detents (RSVP, set the pars, name the rivalry, announce, report). The web's single global `#sheet` with body replacement is not reproduced.
- **A live round in progress** owns the ⊕ cover: opening ⊕ resumes it; Home shows the resume banner; the Live Activity deep-links to it.
- **Route enum** (`enum Route: Hashable`) is the single vocabulary for pushes, deep links, push notifications and widgets: `.league(id)`, `.board(league)`, `.round(id)`, `.scorecard(liveRound)`, `.liveRound(id)`, `.event(id)`, `.tourCard(profile)`, `.requests`, `.post`, `.claim(token)`, `.join(code)`.

## 3. The app state machine

The web encodes this in `renderHomeHero` + `body.noleague` + `state.demo` + `phase` + `role`; the audit found the `.league-only` gate was inert for weeks because the gates were implicit. Native makes it one enum, derived from one bootstrap read:

```
AppState
  .restoring                       // Keychain → session
  .signedOut                       // the door
  .cardGate(profile)               // marker OR handle missing (never "row exists")
  .ready(Me)                       // everything else

Me { profile, memberships[], events[], invites, liveRound?, todayRounds[], flags }
Membership { league, role, season: SeasonPhase, pulse }
SeasonPhase = .forming | .preseason | .season(week, of) | .cupFinal(weeksLeft) | .wrapped
HomeMode (derived) = .leagueless(rung 7|6|5) | .forming | .preseason | .season | .cupFinal | .wrapped
```

- `SeasonPhase` is **derived, not read from one column**: the web routes on `leagues.phase` while the engine routes on `seasons.status`, and nothing keeps them in step (audit 02 §5). Native computes `.season` from `phase='season' AND today ≥ starts_on`, `.cupFinal` from `seasons.status='cup_final'` + `cup_finalists` (never from date arithmetic, which is what the web does), `.wrapped` from `status='complete'`, and renders the Trophy Room from the stored `champion_*`/`tiebreak_rung` columns (D66), never re-derived.
- `Me` comes from **one RPC on cold start** (`native_home()`, IOS-009) instead of the web's ~10 reads. Until that RPC ships, the repository assembles the same shape from the existing calls behind the same interface.
- `SIGNED_IN` / `SIGNED_OUT` from the auth stream drive transitions; there is no reload-as-navigation.
- Demo mode does not exist on the phone. App Review sees the reviewer account, not a diorama.
- An `app_flags.min_ios_build` check on boot (G15) gates a forced-update screen.

## 4. Home architecture

One lane, one hero, dispatched on `HomeMode` (D81), with the slot order changed for the phone (IOS-004 #1):

1. `LiveRoundBanner` (resume / invite face, D86)
2. `HomeHero` — the standing MOVE (rank, ▲▼—, gap sentence, floor foot); wrapped → Trophy Room hero; forming → days-to-tee + roster CTA; leagueless → rungs 7/6/5
3. `MatchThisWeekCard` — only when a Ryder session is open for me (`event_duels` + `event_session_targets`)
4. `NextRoundCard` — `my_schedule` today/next
5. `UpNextChips` — invites, buddy's playing, needs you, month closes
6. `Digest` — "since you were here" (seen cursor — server-side if IOS-009's cursor lands, else per-device)
7. `HomeStream` — rounds from the circle + non-chat posts across all memberships, bucketed Today / This week / Earlier, paginated
8. `+` in the toolbar → Start a league (quick-start, IOS-007) · Start an event · Join with a code

Every hero paint and CTA tap logs `home_hero_state` / `home_hero_tap` to `client_events` with `platform:'ios'`, exactly as the web does — "does the empty space incite?" stays empirical.

## 5. League / season structure (Clubhouse)

- Root = **Standings** for the current league (switcher in the toolbar lists leagues + events, like `renderClubGroups`). The standings sentence leads; the climb; the table; the individual race as a segment; receipts pushed.
- **Board** is a pushed screen with a keyboard-anchored list, composer at the bottom, Pro announce as a sheet. Reactions via context menu (six emoji), comments on round posts only.
- **Pot** — `PotSummary` (server, cents), buy-in list with Pro mark-paid, the forfeit ledger (never dollars), the ceremony rendered from `season_payouts`.
- **Members** — roster with markers, per-league marker override, Pro pocket tools (set starter index, bye, make Pro; remove is setup-only by server rule).
- **Schedule** — the calendar (cross-league, D93) is reachable from both Home and Clubhouse.
- **Bylaws** — read-only card + the endgame dial for the Pro (`set_league_finish`).
- **Draft night** — the blind-draw reveal is read-only on the phone; the pick clock is desk (D98).
- Phase-dispatched empty states port verbatim ("NO ROUNDS YET. SQUADS FORM WHEN THE PRO LOCKS…").

## 6. Match architecture (the round)

Cup Season's "match" is one of four objects (audit 04 §1) and only two are live on a phone: the **tee-sheet game** and an **open Ryder duel**. The architecture is built around the first.

```
RoundState (@Observable, Codable)
  liveRoundId, leagueId, joinCode, course snapshot (pars, SI, rating, slope, holes)
  players[4] (member | guest(token) | visitor), pairing, mode
  game: .none | .match | .wolf | .skins | .sunningdale, config, stake
  scores[player][hole] with client_ts, wolf picks[hole] with client_ts
  hole cursor, sync status (queued n, last flush)

GameEngine (pure, one per game): (RoundState) -> GameView   // status line, ledger, hole cells, closeout
GameResult envelope: identical to the web's `gameResult()` shape — the server branches on it

LiveRoundSession (actor)
  ├─ local writes → RoundState + SQLite queue (durable, LWW by client_ts, poison-drop after N)
  ├─ Realtime broadcast on `live-<id>-<joinCode>` (rumor, never truth) + presence
  ├─ flush → live_set_score / live_set_wolf (batched when IOS-009's live_set_scores lands)
  ├─ reconcile ← live_state on foreground / subscribe
  └─ finish → finish_live_round(cards, casual, result) → settlement
```

- Engines are ported from `index.html` with the **existing Sunningdale test vectors** and new vectors for match/wolf/skins recorded from the web's functions before porting.
- The Live Activity renders `RoundState` → `ActivityAttributes.ContentState` (status line, hole, skins riding, wolf, sync). Push-to-update via APNs `liveactivity` is a later addition; local updates suffice while the app is foreground/background.
- Offline is a first-class state, not an error: the scoreboard shows "2 queued", the queue drains on `BGAppRefresh` and foreground.

## 7. Social architecture

- `BoardRepository` — page by `(league, before)`, incremental realtime insert on **all** memberships (one channel per league, filtered), kudos/comments debounced 250ms as on web, mutes enforced by RLS (no client filtering).
- `HomeStreamRepository` — `home_feed` + posts across memberships until `home_stream` exists.
- `PeopleRepository` — buddies (`my_friends`, `friend_request`, `friend_respond`, `search_golfers`), Tour Card, mute, report, rivalries.
- `Requests` (inbox) — invites + buddy requests + open live rounds; this is the app badge's only source.
- Sharing — `ShareCardRenderer` (`ImageRenderer` of SwiftUI views for the recap/settlement/jug cards) + `create_share` links, one `UIActivityViewController` with image + text + URL.

## 8. Profile / stats

- `MeRepository` — profile, card edits (`set_profile`/`set_handle` ordering rules from audit 01 §5), index (`set_index`, refusal shown as information), photo (native crop → `{uid}/avatar.jpg` upsert), discoverability, notification flags, theme (device-local), delete account.
- `StatsRepository` — `tour_card`, `career_record`, `my_achievements`, `my_trophies`, `my_rivalries`, rounds with `index_at_post` history, `round_holes` (needs the read RPC) × `api_course_holes`.
- Insight views compute *presentation* (trend, distribution) from server facts; nothing they compute is written back.

## 9. Notifications

- Registration: after the first meaningful moment (card saved / first post / joined), a pre-permission screen in voice, then `UNUserNotificationCenter` → `register_device_token(token, 'ios')`; re-register silently on every signed-in launch (APNs re-issues tokens); `unregister_device_token` on sign-out.
- Server: the `push` function's APNs branch is complete and env-gated (`APNS_P8/KEY_ID/TEAM_ID`). Payload today has no routing data — IOS-009 adds `kind`, ids and a `category`.
- Categories with actions: `BUDDY_REQUEST` (Accept / Decline → `friend_respond`), `INVITE` (Accept → `respond_invite`), `RSVP` (In / Out → `set_round_rsvp`), `LIVE_ROUND` (Open the pencil), default (open route).
- Badge = count of actionable items only (requests + invites + open live rounds). Never chat.
- Local notifications: "session closes tonight" for an open Ryder duel without a posted round.
- Preferences: the same three server flags (`notify_rounds`, `notify_chat`, per-event `notify_target`) + a future `notify_league_events`.

## 10. Deep links

- **Universal Links** — the AASA already maps `/?claim=*` and `/?join=*` to `3F7BK4WVH8.app.cupseason.ios`. The app consumes both exactly as the web does (store intent → after auth + card → `claim_round`/`claim_scan_round` or `covenantGate` → `join_league`). A still-live claim opens the guest pencil (D87).
- `?share=` is deliberately **not** claimed (strangers should get the web card); `?unsub=` stays web.
- **Push routes** → `Route`; **widget / Live Activity taps** → `Route`; custom scheme `cupseason://` mirrors the same routes for Shortcuts.
- `DeepLinkRouter` is the only place that turns a URL or payload into a `Route`; it is unit-tested.

## 11. Shared UI (the design system package)

`CSDesign` (a local Swift package):
- `CSTokens` — **generated** from `packages/tokens/tokens.json` by a new emitter in `tools/build-tokens.mjs` (`Tokens.swift`), checked by preflight the same way `tokens.css`/`tokens.ts` are (check 10 grows a Swift sibling). Both themes; `dim`-as-text maps to `mut` (IOS-003 §2.2).
- Type: text styles per IOS-003 §2.1; Plex Mono bundled; Charter system.
- Components: `CSCard(spine:)`, `CSStat`, `CSEyebrow`, `CSButton(.primary/.quiet/.gold)`, `CSSeg`, `CSField`, `CSToast`, `CSEmptyState`, `CSSkeleton`, `CSMarker`, `CSFace`, `CSHoleStrip`, `CSBandLine`, `CSStanding`, ceremonies (`Stamp`, `Finish`, `SplitFlap`, `Engraver`, `Seal`), `Forge`.
- Haptics: `CSHaptic` with the vocabulary in IOS-003 §2.8.

## 12. Supabase / data architecture

- **Client:** `supabase-swift` (official; OTP `signInWithOTP`/`verifyOTP`, `rpc`, Realtime v2, Keychain session storage built in). Two clients: one for auth+data, one **dedicated to realtime** (the CHANNEL_ERROR landmine holds in any SDK); forward the token on every auth event.
- **Contract:** `packages/db/contract.psv` → a generated `Rpc.swift` (`enum Rpc` with `Codable` arg/return structs for the ~40 phone RPCs; the generator is an addition to `tools/build-db.mjs`, and preflight check 11 gains a Swift sibling). The shared-layer *rules* are re-encoded once in Swift, ~100 lines: `requestEmailCode(email)` with no options bag; `OTP_LENGTH = 8`; auth handlers deferred; `call(_:args:skewOptional:)` that retries **on any error** by dropping optional args; `localDate`/`isoDate` — no `Date(iso)` parsing of calendar dates anywhere.
- **Reads:** direct PostgREST selects on the views (`v_squad_standings`, `v_individual_standings`, `v_rounds_ranked`) and RLS-scoped tables are fine from supabase-swift; RPCs for everything else. Every RPC the phone calls must have its grant (D37) — preflight check 14's Swift sibling asserts it.
- **Writes:** RPCs only, except the policy-allowed direct writes the web uses (chat post, kudos, comments) until IOS-009's `post_round()` replaces the direct `rounds` insert.
- **Storage:** private `media` (signed URLs, 1h, cached and refreshed on foreground); public `shared` for share copies.
- **Cache:** SQLite (GRDB) — last-known `Me`, standings, board pages, schedule; the outbound queue for the live round. Cold launch renders the cache first.
- **Skew:** a native build cannot be redeployed by `git push`; a missing RPC is a **version mismatch to surface**, never a silent downgrade (audit 06 §9.12). The `min_ios_build` flag closes the loop.
- **Telemetry:** `client_events` with `props.platform='ios'` and `props.build`; `client_error` keeps the 4-frame stack + boot step convention.
- **Environments:** one backend (prod); the founder's sandbox league (D65) is the rehearsal space; a Debug menu (build-flagged) replaces `?debug` / `?exit` / `?forge`.

## 13. If IOS-006 lands on Expo / React Native instead

The product architecture (§2–§10) is unchanged. Mapping: SwiftUI → RN + expo-router (tabs + stacks + modal); `@Observable` → Zustand/MobX-style store; `CSDesign` → the existing `theme.ts` + RN components; `Rpc.swift` → the existing `packages/db/rpc.ts` and `client.ts`/`auth.ts` (already written and preflight-checked); GRDB → expo-sqlite; Live Activity / widgets → a Swift extension target via a config plugin + an App Group bridge from JS (this is the piece that argues for Swift); APNs → expo-notifications on a dev build (Expo Go cannot); the B1 scaffold in `apps/mobile/` continues (SDK 56, Hermes regression pending SDK 57).

## 14. Backend changes this architecture asks for (→ IOS-009)

| # | Change | Why | Size |
|---|---|---|---|
| 1 | `native_home()` bootstrap RPC | One round trip on cold start; the `Me` shape in §3 | M |
| 2 | `post_round(p_… , p_holes int[], p_photo_path)` → `{round_id, epilogue}` | Replaces the direct insert; writes holes transactionally; fixes `season_id`/`index_source_at_post` debt | M |
| 3 | `round_holes_of(p_round)` read RPC | Holes of quick-posted/scanned rounds are unreadable today | S |
| 4 | APNs payload: `kind`, ids, `category`, badge | Routing and actions | S (Edge Function) |
| 5 | `invite_golfer` → `push_nudges` fan-out; mute-aware recipients; system-post curation flag | Promised notifications that never send; mutes that don't mute pushes | S–M |
| 6 | `app_flags.min_ios_build` | Forced update | XS |
| 7 | `live_set_scores(jsonb)` batch + idempotent `finish_live_round` | Drain-on-resume | M |
| 8 | `handle_available(p_handle)` | Availability is inferred from a filtered search today | XS |
| 9 | `event_players.notify_board` | Per-event mute | XS |
| 10 | **Security:** `revoke execute on close_month from anon, authenticated` (+ vestigial trigger/award grants) | Any signed-in user can close a month early today (audit 06 §9.1) | XS — ship first |
| 11 | Widen `device_tokens.platform` before Android | Constraint is `('ios')` | XS |

All additive; the web client is unaffected by every one of them; each is a `db push` the owner runs (CLAUDE.md deploy discipline).
