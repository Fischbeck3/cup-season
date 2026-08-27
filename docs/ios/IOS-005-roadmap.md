# IOS-005 · Implementation Roadmap

*2026-08-27 · Phase 1 artifact · status: PROPOSED — sequencing holds under either answer to IOS-006; effort figures assume SwiftUI and shift ~+15% on Expo for the native-extension milestones (Live Activity, widgets) and ~−10% for M0.*

Priority = **product impact × user frequency × technical dependency ÷ effort**. The directive's phases (2 Foundation → 3 Core → 4 Polish → 5 Parity → 6 Native advantage) map onto D98's one-branch-per-milestone scheme; branch names below replace `native/b1…b6`.

---

## 0. Before anything: unblock the two hard dependencies

| | What | Owner | Why first |
|---|---|---|---|
| a | **Signing.** Select Team `3F7BK4WVH8` for `app.cupseason.ios` in Xcode; get any build onto the owner's iPhone. | Owner (one dropdown) + local session | Every later gate is "on your phone". The last attempt failed here, not in the app. |
| b | **Decide IOS-006 / IOS-007** (stack; phone scope). | Owner | M0 scaffolds the wrong thing otherwise. |
| c | **Backend batch 1** (IOS-009 items 10, 6, 1, 3, 8): the `close_month` revoke, `min_ios_build`, `native_home`, `round_holes_of`, `handle_available`. | Migration session + owner `db push` | M0/M1 read them; all additive, web unaffected. |

## 1. Milestones

### M0 · Foundation — `native/m0-foundation` (Phase 2) — **first pass built 2026-08-27, gate pending the device build; see `PHASE-2-M0.md`**
**Builds:** project skeleton (targets: app, `CSDesign` package, tests); `Tokens.swift` + `Rpc.swift` generators in `tools/` with preflight siblings of checks 10/11/14; `SupabaseService` (auth, rpc with skew retry, storage), `RealtimeService` (dedicated client), Keychain session, auth stream; `AppState` machine; the door (Forge once per device, email → 8 digits with autofill, reviewer door); the card gate (3 steps); tab shell with four empty places; `CSDesign` core components; `native_home` repository (with the multi-read fallback until the RPC is pushed); Debug menu; `client_events` telemetry.
**Gate:** sign in on the owner's iPhone with a real code, land on a Home hero showing the **real PIGL standing**, kill the app, relaunch straight to Home from the Keychain. *(This is B1's gate plus one real number.)*
**Effort:** ~6–8 sessions.

### M1 · The season, read — `native/m1-season` (Phase 3: Home · League/season · Social read)
**Builds:** Home in all seven modes (leagueless rungs, forming, preseason, season, cup final, wrapped) with the live-round banner slot, Up Next, digest, stream; Clubhouse standings (sentence, climb, table, individual race, split-flap on open), squad and round receipts, member history; the Board (read, chat, reactions, comments, realtime across memberships); the You card; Tour Card; buddies (search, request, respond); invites banner → Requests screen; league switcher; join by code with the covenant; Universal Links for `?join`.
**Gate:** a PIGL member (not the owner) installs via TestFlight, reads standings that match the web to the point, reacts to a post, and the web sees it.
**Effort:** ~10–12 sessions.

### M2 · Post a round — `native/m2-round` (Phase 3: the golfer's core loop)
**Builds:** the ⊕ cover opening on Post; two boxes; course/tee picker (cache-first + `courses` function); the stepper with pars from `api_course_holes`; scan (VisionKit capture → `scan` function → confirm grid → partner claims); photo; league-lens preview; draft autosave; the finish ceremony + POSTED stamp + haptics; epilogue; share card via `ImageRenderer` + share link; delete round; `post_round` RPC (or the direct insert behind the same repository until it ships). Scheduled rounds: declare, RSVP, comments, weather, Home "next round".
**Gate:** the owner posts a real round from the phone that counts in PIGL, the board post fans out, the receipt on web and phone agree to the decimal.
**Effort:** ~8–10 sessions.

### M3 · The live round — `native/m3-live` (Phase 3: Match experience)
**Builds:** tee sheet setup (3-step: course → foursome with the court → game + stake, strokes preview); `RoundState` + four engines with test vectors captured from the web; `LiveRoundSession` with the SQLite queue, broadcast, presence, reconcile; the scoring screen (sticky game card, per-player stepper rows, swipe between holes, hole dots); wolf prompt sheet; finish sheet + settlement (dusk room, hole strip, transfers) + settlement post; group phones via share sheet / QR; guest pencil via `?claim` Universal Link; visitor rounds; abandon; **Live Activity** (local updates) as the round's lock-screen face.
**Gate:** **D98's gate** — a PIGL member plays a full round on the phone, in a dead zone, and the card lands complete. Not a demo.
**Effort:** ~12–14 sessions (the highest-risk milestone; B3 "offline parity" is inside it with its own tests).

### M4 · Push, inbox, deep links — `native/m4-push` (Phase 3: Notifications)
**Builds:** APNs registration with the contextual ask; the three secrets set (owner); payload routing; categories with actions; badge policy; local "closes tonight"; notification settings; `invite_golfer` push; mute-aware recipients. Requires the backend batch 2 (IOS-009 items 4, 5, 9).
**Gate:** a real board post reaches a PIGL phone as a push that opens the right screen; a buddy request is accepted from the lock screen.
**Effort:** ~4–5 sessions.

### M5 · Events, pot, stats — `native/m5-season-depth` (Phase 3: remainder)
**Builds:** the Ryder room (scoreboard, sessions, duels, targets, taunt opt-in, invites) + "your match this week" on Home; the Major room (leaderboard, field, jug card, run it back); trophy case with the engraver; rivalries with receipts; career record; the three insight surfaces (your number, how you score, where and with whom); the pot (summary, Pro mark-paid, forfeits, ceremony from `season_payouts`, D71 vote); quick-start league creation and event creation (per IOS-007); Pro pocket tools (announce, starter index, bye, endgame dial, make Pro).
**Gate:** a Ryder runs a full session with phone-only participants; a season ceremony renders identically to the recorded payouts.
**Effort:** ~10–12 sessions.

### M6 · Polish + parity audit — `native/m6-polish` (Phases 4–5)
**Builds:** motion pass (ceremonies tuned, the Forge, month seal), haptics pass, Dynamic Type at AX sizes, VoiceOver ordering, reduced motion, light theme, offline read cache, loading/empty/error sweep, performance (cold start < 1s to cached Home), App Store assets from `spec/appstore-runbook.md`. **Parity audit:** the matrix in IOS-001 §3 walked row by row against the web; every ⚠ resolved or logged as a deliberate departure with a decision ID.
**Gate:** TestFlight to all of PIGL; the parity matrix has no unexplained gaps; App Review submitted.
**Effort:** ~6–8 sessions.

### M7 · Native advantage — `native/m7-advantage` (Phase 6)
**Builds, in this order:** widgets (standing · number to beat); push-to-update Live Activity; App Intents ("Post a round", "Start a live round"); App Clip for the guest pencil; then the Watch conversation (D98 Phase E, timing unfixed).
**Gate per item:** used in a real round or a real week by someone other than the owner.
**Effort:** ~3–4 sessions each.

## 2. Sequencing rationale

- **M1 before M2** (read before write): the phone must render the season correctly before it writes into it — receipts are how a wrong write is caught.
- **M2 before M3**: the live round finishes by posting rounds; the post path, ceremony and receipts are its exit.
- **M4 after M3**: push is the re-engagement loop and needs the events it announces to exist on the phone; also it needs the signed dev build M0 unblocks and secrets only the owner can set.
- **Live Activity inside M3, widgets in M7**: the Live Activity *is* the match experience on a phone and shares `RoundState`; widgets need a background-refresh design and earn their place after the core is real.
- **Events/pot/stats in M5**: high value, lower frequency than the loop above, and they lean on M1's components.

## 3. Cross-cutting tracks (run inside every milestone)

- **Tests:** engine vectors (M3), `DeepLinkRouter` (M0+), `call()` skew retry (M0), copy producers (bands/phrases, M2), snapshot tests of the ceremonies (M6).
- **Preflight:** the Swift siblings of checks 10/11/14 land in M0 so `node tests/preflight.mjs` gates every push from day one.
- **Decision log:** every ⚑ in IOS-004 becomes an `IOS-0xx` entry before it is built.
- **End-of-phase artifact** after M0, M3 and M6 (the directive's §23 format).

## 4. What happens to the existing work

- `packages/` (tokens, contract, client rules) stays the shared source of truth under either stack; the Swift generators read from it.
- `apps/mobile/` (Expo B1, uncommitted): **if IOS-006 = SwiftUI**, commit it once on the branch as the record of B1 (it passes preflight), then retire it in the same milestone that M0 replaces it — do not leave two phone clients in the tree. **If Expo**, M0 continues from it (SDK 56 → 57 when Expo Go on the phone allows; `expo-dev-client` for M4).
- `ios-wrapper/` (Capacitor): dead per D98; remove in M0 (native-arc "Still open #2").

## 5. Rough totals

~60–75 local sessions to M6 (TestFlight to PIGL). The single largest risk is M3's offline behaviour; the single largest schedule lever is deciding IOS-006/007 this week so M0 starts on the right foundation.
