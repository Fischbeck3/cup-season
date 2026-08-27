# Phase 2 · M0 Foundation — status artifact

*2026-08-27 · first pass complete on the Mac · branch `native/b1-scaffold` (all uncommitted)*

## Completed

- **Decisions:** IOS-006 = SwiftUI, IOS-007 = option 2 (owner, 2026-08-27); D99 in `spec/decision-log.md`; `spec/native-arc.md` amended.
- **Project:** `apps/ios/` — XcodeGen manifest (`project.yml` → `CupSeason.xcodeproj`, gitignored), app target `app.cupseason.ios` with Team `3F7BK4WVH8`, iPhone-only, iOS 17+, Swift 6 strict concurrency, associated domains (`cupseason.app`) + APNs entitlements, `cupseason://` scheme, IBM Plex Mono bundled (OFL), app icon.
- **Packages:** `CSDesign` (theme plumbing, Dynamic-Type typography, SVG-path parser with arcs, markers/faces, card/button/field/stat/empty-state/note/haptics) and `CupSeasonKit` (config, the encoded auth rules, `SupabaseService` with two clients and the skew retry, `Me` models, derived `SeasonPhase`/`HomeMode`, `SessionStore` state machine, `MeRepository` with the pre-push fallback).
- **Generators (packages/ stays the source):** `tools/build-tokens.mjs` → `Tokens.swift`; `tools/build-db.mjs` → `Rpc.swift` (133 client-callable functions; ungranted functions have no Swift name); new `tools/build-markers.mjs` → `Markers.swift` (14 glyphs verbatim from `index.html`).
- **Preflight:** checks 15–17 (Swift palette purity — a hex literal is allowed only if `index.html` renders the same hex; OTP discipline; RPC grants incl. hand-declared calls); check 10 now also holds `Markers.swift`. **17/17 PASS.**
- **Screens:** the door (email → 8 digits with autofill, resend cooldown, reviewer door, status line in voice), the card gate (name+handle → marker grid → index/GHIN; `set_handle` then `set_profile`), the four-tab shell, Home with the lifecycle-dispatched hero and the three tiles, Clubhouse (leagues + standing, tap to lead Home), the ⊕ cover (honest M2 hand-off to the web), You (card, appearance Charcoal/Light/Match device, two-tap sign out, legal, build line), boot-failed and must-update states.
- **Backend batch 1 (IOS-009), written, not pushed:** `20260827130000_close_month_revoke`, `…130100_ios_flags`, `…130200_handle_available`, `…130300_round_holes_of`, `…130400_native_home`; `tests/db-checks.sql` gains check 12.

## Verified

- `xcodebuild build` for iPhone 17 Pro simulator: **BUILD SUCCEEDED**.
- `xcodebuild test`: **12/12** — CSDesign (4: all 14 markers parse on the 24-grid, the Azalea's arc dot centres at (12,12), unknown key → saguaro, 34 tokens/radii/stacks), CupSeasonKit (7: 8-digit codes, email shape, "newest email" mapping, calendar dates never via UTC, Cup Final from `seasons.status`, draft-with-active-season is forming, week numbering, copy producers), app smoke (1).
- Launched on the simulator: the door renders in Charcoal — Charter wordmark, Plex Mono eyebrow, ember primary, `focus` ring on the live field (screenshot taken 2026-08-27 08:30).
- `node tests/preflight.mjs` 17/17; `--check` on all three generators clean.
- Migrations parsed with libpg-query (52 statements in `native_home`), not executed — no local Postgres.

## Remaining (M0 gate not yet met)

- **The gate:** sign in on the owner's iPhone with a real code → Home hero shows the real PIGL standing → kill, relaunch straight to Home from the Keychain. Needs a device build: open `apps/ios/CupSeason.xcodeproj`, Signing & Capabilities → Team `3F7BK4WVH8` (already in the project; automatic signing should register the App ID's associated-domains and push capabilities — if it refuses, untick those two capabilities for the first build), plug in, run.
- **`db push` of batch 1** (owner): `./tools/ship.sh` → confirm `push` → refresh `contract.psv` with the query in its header → `node tools/build-db.mjs` (moves `native_home`/`handle_available`/`round_holes_of` into `Rpc.swift`; the hand-declared `NativeHomeCall` in `MeRepository.swift` is then replaced) → run `tests/db-checks.sql`, expect checks 3 and 12 to pass. Until then the app uses the fallback bootstrap (7 reads) and Home has no `prev_rank`/`pulse`.
- Not in this pass: the Forge animation (M6), the leagueless rung 5 (buddy count needs `native_home`), the `handle_available` live check on the card (RPC not yet in the contract), the Debug menu, `client_events` telemetry, offline cache.
- `apps/mobile/` (Expo B1) and `ios-wrapper/` removed (IOS-017) — the B1 record is the commit before D99's.

## Decisions made

IOS-006, IOS-007 (final); IOS-011/012/013/014/015/016/017 proceeding; D99.

## New decisions needed

None blocking M0. Two came out of the migration work for the owner's awareness: `handle_available` mirrors `set_handle` in stripping every `@` (not just a leading one); `native_home` returns `profile.index_engine` alongside `index_current` so the hero can show the engine's number when a starter is stale.

## Recommended next step

1. Owner: device build + sign-in (the gate), then `db push` batch 1 + snapshot refresh.
2. Then M1 (`native/m1-season`): Home's remaining slots against `native_home`, standings with the sentence/climb/split-flap, the Board with realtime, receipts, buddies, invites, Universal Links for `?join`.
