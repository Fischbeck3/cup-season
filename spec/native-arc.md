# Native arc — three surfaces, one stack

Decided 2026-08-26 (D98). **Supersedes `spec/ios-wrapper-arc.md` entire** —
the Capacitor wrapper is abandoned, iOS waits for the real app.

The shape is Strava's: one account, one Postgres, three surfaces that each
do the job their screen is good at. What follows is how it gets built, in
what order, and what has to be true before each step starts.

---

## The three surfaces

| Surface | Stack | Owns | State |
|---|---|---|---|
| **Phone** | Expo / React Native | Live scoring, posting a round, the board, push, standings read | **New** |
| **Desktop** | React (rewrite of `index.html`) | Wizard, draft, roster, ledger, month closes, receipts, founder desk, the public claim/join/share pages | **Exists, ships today, gets rewritten** |
| **Watch** | Swift (watchOS) | Scoring during play | **New, last, timing unfixed** |

The rule that keeps them from blurring: **the phone is for the tee box, the
desk is for the league.** A draft on a 6" screen is friction we invented.
Nobody runs a season from a cart path.

### What none of them own

The competition model. `cup_points()`, `score_round()`, `v_rounds_ranked`,
`v_squad_standings`, `close_month()`, the bands, the caps, the floors, the
tiebreak ladder — all Postgres, all already written, all shared by every
surface for free. `cup_points` and `close_month` have **zero** client
references today. No rule gets reimplemented in this arc. That fact is the
whole reason this is affordable.

---

## Phase A · The shared foundation

Before a second client exists, decide what the two of them share. Doing this
after the fact means two clients that drifted for six months.

- **A1 · Design tokens.** `--bg0`, `--bg1`, `--ink`, `--mut`, `--brand`,
  `--gold`, `--pos`, `--neg` and their light/dark pairs already exist as CSS
  custom properties in `index.html`. Extract to one JSON source the web CSS
  and the RN theme both build from.
- **A2 · Generated types.** 103 distinct RPCs. Generate TypeScript from the
  live schema and commit it; typing them once beats typing them twice, and it
  catches the D37 grant class of error at compile time instead of as a silent
  403.
- **A3 · The data layer.** One typed module wrapping the Supabase client, the
  RPC calls, and the skew-retry convention (drop the new field on any error —
  never sniff the message; see the `photo_path` landmine).
- **A4 · Repo shape.** The single-file client becomes one workspace among
  several. Decide now whether that is a monorepo in this repo or separate
  repos — it is cheap today and expensive in three months.

**GATE:** the existing web client consumes A1 and A2 without a visual or
behavioural change. If the shared layer cannot serve the client that already
exists, it will not serve the two that do not.

## Phase B · The phone app (iOS)

Built against the shared layer, not against a copy of it.

- **B1 · Auth.** Supabase email OTP. The `navigator.locks` landmine goes away;
  Keychain session storage arrives in its place.
- **B2 · The round.** Live scoring, the tee sheet games, hole-by-hole. The
  centre of the app and the reason it exists.
- **B3 · Offline parity — its own milestone, with its own tests.** Port
  `window.liveSync` (141 lines: durable queue, LWW by `client_ts`,
  poisoned-write protection, drain-on-resume). Native has better tools for
  this — SQLite, real background tasks — so it is an upgrade, not a
  translation. It is also the highest-risk piece in the arc, because its
  failure mode is losing somebody's card.
- **B4 · The board + realtime.** Note the standing landmine: realtime lives on
  a dedicated client, never the main one.
- **B5 · Push.** APNs through the existing `register_device_token` /
  `unregister_device_token` RPCs — server side is already built and proven.
- **B6 · Standings read + receipts.** Read-only against the views.

**GATE:** a PIGL member plays a full round on the phone app, in a dead zone,
and the card lands complete. Not a demo — a real round.

## Phase C · Android

Same codebase. This phase is almost entirely store and transport work.

- `.well-known/assetlinks.json` — Android's mirror of the AASA, served by
  Netlify the same way. Preflight check 9 grows a sibling.
- FCM alongside APNs in `push/index.ts`.
- **`device_tokens.platform` is `check (platform in ('ios'))`** — a migration
  must widen it or every Android registration fails on the constraint.
- Play listing, data safety form, the separate real-money-gambling
  declaration (same D39 facts, different form).

**GATE:** an Android phone in the crew receives a push from a real board post.

## Phase D · Desktop in React

The web client is live and serving real leagues throughout this arc.

**Rule: parallel build, then cutover. Never an in-place refactor.** A 17,767-line
single-file client cannot be rewritten underneath its users.

Desktop-first this time, because that is what the surface is for: the Pro's
desk deserves a layout designed for a big screen, not a wide phone. The public
pages (`claim_round_info`, `join_covenant_info`, `share_info`,
`league_by_code`, `scan_claim_info` and the three `guest_live_*` endpoints)
must stay fast, linkable and account-less — they are the funnel, and they are
the one part of the rewrite with an SEO and share-preview surface to protect.

**GATE:** every flow in the old client has a home in the new one, verified
against the RPC list, before DNS moves.

## Phase E · Apple Watch

Swift target, talking to the phone app. **After Phase B, timing deliberately
unfixed** — the owner's words were "maybe this month and maybe not."

The one thing Phase B owes Phase E: a **clean round state model**, separable
from view code. If live scoring state is tangled into components, the watch
becomes a re-architecture instead of a target.

Deliberately noted for later, not now: Strava did not win the watch by
building the best watch app — it won by receiving from the watches people
already owned. Golfers wear Garmin Approach watches. Design the round sync so
a Garmin integration can drop in without reshaping anything.

---

## Still open

1. **Repo shape** (A4) — monorepo here, or separate repos.
2. **The dead Capacitor code.** `ios-wrapper/` and the `window.Capacitor`
   branch in `index.html` are now inert. Remove them now, or let the Phase D
   rewrite drop them? Standing bias says now: dead wiring that reads as live
   is exactly the false map D97 came out for.
3. **Expo Updates policy** — what ships over the air versus what forces a
   store build.
4. **D56's trigger** — the visible pricing model was anchored to "iOS
   launch," which is now months out. D98 proposes re-anchoring it to the web
   client; the owner has not ratified that.

## Standing guardrails

- **No purchase UI in any client, ever** — a cross-store rule now, not an iOS
  workaround. Web checkout only. No IAP, no Play Billing, no 3.1.1 fight.
- **Email OTP only.** Adding a third-party login obliges Sign in with Apple.
- **Every new RPC needs its explicit grant** (D37) — the shared type layer
  makes a missing grant visible earlier, it does not make it impossible.
- **Rounds stay immutable.** No client in this arc gets an update path.
- `spec/appstore-runbook.md` still governs submission. Phases 0, 1, 4, 5 and
  all nine decision items hold verbatim; only its Phases 2-3 are rewritten
  for Expo.
