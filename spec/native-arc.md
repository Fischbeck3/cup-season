> **AMENDED 2026-08-27 by D99.** The phone is **Swift / SwiftUI** (`apps/ios/`),
> not Expo; its scope is the golfer's whole life plus the Pro's pocket tools
> (IOS-007); milestones follow `docs/ios/IOS-005-roadmap.md` (M0–M7), not the
> `native/b1…b6` branches below. Phase C (Android) is re-opened as a Year-2
> question. Phase A, the standing guardrails, and every product decision here
> hold. The Phase B/C sections are kept as the record of D98.

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

- **A1 · Design tokens — DONE.** 34 tokens across 11 groups extracted from
  `index.html` (D76 rationale comments preserved) into
  `packages/tokens/tokens.json`, which generates `tokens.css` and `tokens.ts`.
  One deviation from the original plan, made deliberately: the live
  `index.html` is *verified against* the JSON rather than *built from* it.
  It is a single-file PWA whose deploy pipeline has no build step, and putting
  one in front of a client serving real leagues buys nothing that preflight
  check 10 does not already guarantee — which is that a token cannot differ
  between the JSON and the client, in either theme, in either direction.
  Phase D's React client imports the generated files directly.
- **A2 · The RPC contract — DONE.** `packages/db/contract.psv` is a verbatim
  `pg_proc` snapshot (169 rows, refresh query in its header); it generates
  `packages/db/rpc.ts` — 155 callable functions as typed `{args, returns}`,
  triggers excluded, overloads collapsed to the widest signature, and the ten
  anon-reachable endpoints named as a list. Verified by negative test: a wrong
  arg name, a wrong arg type, an unknown RPC name and a missing required arg
  are each rejected by `tsc --strict`, and valid usage compiles.
  Full table/view row types still want `supabase gen types typescript` from
  the Mac — the CLI is not in the sandbox — and are not blocking Phase B.
- **A3 · The data layer — DONE.** `packages/db/client.ts`, dependency-free by
  design (it takes a structural view of a Supabase client rather than importing
  one, so three surfaces can upgrade supabase-js on different days). It encodes
  the rules this codebase already paid for, rather than documenting them:
  skew-retry that fires on ANY error and never sniffs the message (the
  `photo_path` 42501 never named its column), realtime bound to a dedicated
  client, `deferAuthWork` so no auth call runs synchronously inside
  `onAuthStateChange`, and `localDate`/`isoDate` so no calendar date is ever
  built through `new Date('YYYY-MM-DD')`.
- **A4 · Repo shape — DECIDED.** Monorepo in this repo, under `packages/`.
  The root `package.json` is deliberately deferred to Phase B: Netlify runs an
  automatic dependency install when it detects a root manifest, and this site
  has no dependencies. Every tool stays zero-dependency Node, as
  `tests/preflight.mjs` already was. See `packages/README.md`.

**GATE — MET 2026-08-26.** The existing web client is byte-unchanged: Phase A
added files and preflight checks and edited `index.html` not at all, so there
is no visual or behavioural change to verify away. Preflight is 11/11 with one
deliberate warning (`unregister_device_token` is in a migration and not yet in
prod — check 11 catching a real owed `db push` on its first run). Checks 10 and
11 were each negative-tested against the failure they exist to catch. If the shared layer cannot serve the client that already
exists, it will not serve the two that do not.

## How the work is organised

**Where sessions run.** Native work is local — Claude Code on the Mac, which
can run Expo, drive a simulator, read the actual crash and build to a phone.
Remote sessions keep migrations, specs, decisions and the web client. See
CLAUDE.md rule 6 for the one-branch-one-machine rule that follows from having
two clones of this repo.

**One branch per milestone, not one per phase.** A single `native` branch for
all of Phase B becomes a months-long diff that cannot be reviewed or reverted
and drifts from main the whole time. Instead:

```
native/b1-scaffold    boots · real palette · real sign-in
native/b2-round       live scoring, the tee sheet
native/b3-offline     the liveSync port
native/b4-board       feed + realtime
native/b5-push        APNs through the existing RPCs
native/b6-standings   read + receipts
```

Each is cut from `main` and merged back the moment its gate passes.

**Merging native code to main early is safe here**, which is not true of most
projects. `stamp-version.sh` is a strict allowlist: Netlify publishes
`index.html`, `legal.html`, `sw.js`, the manifest, the icons, `brand/` and the
AASA, and nothing else. `apps/mobile/` is invisible to the website. So main
stays the single source of truth with no risk to the live site, and there is no
reason to hold native work on a long-lived integration branch.

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

**B1 has its own brief:** `spec/native-b1-brief.md` — written to be the first
thing the local session reads, so it starts from decisions already made.

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
