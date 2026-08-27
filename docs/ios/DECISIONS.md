# iOS decision log

Sequential IDs, never reused. IOS-001…005 are the five founding artifacts (documents); decisions proper start at IOS-006. A decision is never overwritten — new information gets a new entry that references the old one. Product-mechanic decisions still ALSO go in `spec/decision-log.md` (CLAUDE.md rule 5); this log is the iOS build's own record and cross-references D-numbers.

Priority: **P0** must decide, work stops · **P1** recommendation given, pauses if it substantially changes the experience · **P2** documented, proceeding.

Format per entry: ID · date · priority · decision · options · recommendation · final choice · rationale · files/features affected.

---

## Founding artifacts

| ID | Date | Artifact | File |
|---|---|---|---|
| IOS-001 | 2026-08-27 | Full Product & Feature Audit (+ parity matrix) | `IOS-001-audit.md`, evidence in `audit/` |
| IOS-002 | 2026-08-27 | Native iOS Architecture | `IOS-002-architecture.md` |
| IOS-003 | 2026-08-27 | iOS Design Direction | `IOS-003-design-direction.md` |
| IOS-004 | 2026-08-27 | Web → iOS Opportunity Map | `IOS-004-opportunity-map.md` |
| IOS-005 | 2026-08-27 | Implementation Roadmap | `IOS-005-roadmap.md` |

---

## IOS-006 · The phone's stack: SwiftUI/Xcode or Expo/React Native — **P0 · DECIDED 2026-08-27: SwiftUI**

**Final choice (owner, 2026-08-27):** Option 1, SwiftUI in Xcode. Logged upstream as D99 in `spec/decision-log.md`. Consequences taken: `apps/ios/` is the phone; `apps/mobile/` (Expo B1) is retired in M0 per IOS-017; Android is not from this codebase (D98 Phase C is re-opened, not scheduled); `packages/` stays the shared source and gains Swift emitters.

*2026-08-27. Reopens the implementation half of D98; does not touch its product half.*

**Decision.** Build the phone in Swift/SwiftUI (Xcode), or continue the Expo/React Native app D98 chose on 2026-08-26.

**Context.** D98 picked Expo for "Android from the same codebase" (Phase C) and "one language family across three surfaces" (Phase D's React desktop). The 2026-08-27 directive asks for a native iOS app in Xcode with Live Activities, widgets, Dynamic Type, haptics and Swift concurrency. The B1 Expo scaffold exists (uncommitted, ~600 lines, preflight-clean, SDK 56 pinned to the phone's Expo Go, a Hermes memory regression pending SDK 57) but its gate — a real sign-in on the owner's iPhone — is not evidenced; the one attempt to build to the phone failed on code signing, not on the app. Full analysis: `audit/09-ios-state-and-canon.md` §9.

**Current web behaviour.** N/A (the web client is unaffected either way).

**Options.**
1. **SwiftUI / Xcode.** One toolchain (Xcode + SPM + supabase-swift). Live Activities, widgets, Watch, App Intents are first-class and share one `RoundState` model with no JS↔Swift bridge. Dynamic Type and haptics are the real system, not approximations. Costs: Android is *not* from this codebase (a Year-2 decision, or a separate RN/Kotlin app); the desktop React rewrite shares only `packages/` (tokens, contract), not components; two small generators (Tokens.swift, Rpc.swift) and ~100 lines of re-encoded rules; the Expo scaffold is retired.
2. **Expo / React Native** (D98 as decided). Reuses `packages/db` and `theme.ts` directly; Android nearly free; possible component sharing with the React desktop. Costs: Live Activities/widgets/Watch still require Swift extension targets inside an Expo-managed Xcode project plus an App Group bridge for round state — the part most likely to break on each SDK upgrade, on a project already downgraded to SDK 56; a dev client + signing for push anyway; Dynamic Type is scaling, not text-style semantics.
3. **Hybrid: Expo now, Swift for extensions later.** This is option 2 with the cost deferred, not removed.

**Recommendation.** Option 1, SwiftUI — *if* the reasons for a native app are the ones D98 itself gave (a live match on the lock screen, scoring on a watch) and Android is a Year-2 question. Option 2 — *if* Android in Phase C and shared React UI with the desktop rewrite are near-term commitments. The repo's evidence leans to 1: D98's justification is native-only surface area; `gtm-year1.md`, the App Store runbook and CLAUDE.md plan only for iPhones; the phone's scope is deliberately ~10–15 screens; the Expo hours so far went to toolchain friction.

**Tradeoffs.** Gain (1): the headline features without a bridge; fewer moving parts for a solo builder; the signing step becomes a dropdown. Give up (1): D98's Android benefit; the ~600-line scaffold (the ideas survive — Keychain sessions are built in, `theme.ts` becomes generated Swift).

**Reversibility.** HARD after M1 (either way). EASY today.

**Action.** Waiting for the owner. IOS-002 is written for option 1 with option 2 mapped in its §13; IOS-005's sequencing holds under both. **Independent of the answer, the first engineering task is identical: set the team in Xcode and get a signed build onto the owner's iPhone.**

**Files/features affected.** Everything under `apps/`; `tools/build-tokens.mjs`, `tools/build-db.mjs` (new emitters); `tests/preflight.mjs` checks 12–14; `spec/native-arc.md` Phase B/C wording; D98 needs a follow-up entry in `spec/decision-log.md` whichever way this goes.

---

## IOS-007 · What the phone owns: the D98 split vs the directive's definition of done — **P0 · DECIDED 2026-08-27: Option 2**

**Final choice (owner, 2026-08-27):** Option 2 as recommended — the golfer's whole life plus the Pro's pocket tools (quick-start creation, draw, start, mark-paid, bye, starter index, endgame dial, announce, invite, D71 vote); authoring (full wizard dials, lock, assign, overrides, founder dashboard) stays on the desk. Logged upstream in D99.

*2026-08-27.*

**Decision.** How much of the league-running surface lives on the phone.

**Context.** D98 says the phone is for the tee box (scoring, posting, board, push, standings read) and the desk owns the wizard, draft, roster, ledger, month closes, receipts and founder desk. The directive's Definition of Done says a real user must be able to *create or join a competition, track the pot, manage participation* and lists admin/moderation among audited features. Audit 06 §10 evaluated D98's "desk work" claim screen by screen: the wizard (twelve dials) and the draft pick clock are genuinely desk; the **pot read and mark-paid are phone-first** (money changes hands in the parking lot); the ceremony is phone-first; bye/starter-index are phone-worthy; overrides, report resolution, `app_flags`, the sandbox are desk.

**Current web behaviour.** Everything is on one surface; the wizard is a 3-step form with a "Customize" disclosure holding ~12 dials; the pot pane is one number, three tiles and a tap-to-mark list.

**Options.**
1. **D98 verbatim.** Phone never creates a league, never shows the pot pane, no Pro tools. Fails the directive's DoD on "create a competition" and "track the pot".
2. **Golfer's whole life + Pro's pocket tools (recommended).** Phone: join (covenant), **quick-start** league creation (name · preset · stake — three fields; the "Customize" dials stay desk with a hand-off link), create Ryder/Major (their sheets are small), **the blind draw and "Start the season"** (single RPCs with server validation; audit 02 §8 calls the draw "the league's one appointment moment" — a phone moment by D54's own reasoning), pot summary + Pro mark-paid + forfeits + ceremony from `season_payouts` + D71 vote, Pro pocket tools (announce, starter index, bye, endgame dial, make Pro, invite), draft **reveal** read-only. Desk: full wizard dials, the lock sequence (five client writes today — should become one RPC before any phone touches it), Pro assign (desk-first, phone fallback), the pick clock, ledger overrides, report resolution, flags, sandbox, founder dashboard (field note stays on phone). Audit 02's summary of the honest split: *authoring* (wizard, lock, assign, overrides) on the desk; *operating* (draw, start, bye, buy-in, finish dial) plus *reading everything* on the phone.
3. **Full parity.** Port the wizard dials and draft board to the phone. Contradicts D98's principle argument ("a draft on a 6" screen is friction we invented") and Persona 1 being a desktop user.

**Recommendation.** Option 2. It meets every line of the DoD with real backend data and keeps D98's principle intact.

**Tradeoffs.** Gain: the phone is complete for Persona 2 and useful for Persona 1 between sessions. Give up: a phone Pro cannot customise bylaws beyond the preset without the desk.

**Reversibility.** EASY (additive screens).

**Action.** Waiting for the owner. The uncontested core (M0–M3) does not depend on this; M5 does.

**Affects.** IOS-005 M5; `spec/native-arc.md` "Owns" table; `spec/decision-log.md` (D98 follow-up).

---

## IOS-008 · What "match" and "next opponent" mean on the phone — **P1 · PROCEEDING WITH RECOMMENDATION**

*2026-08-27.*

**Decision.** How Home treats "next match / opponent / match approaching" language from the directive.

**Context.** Cup Season's season has **no fixture list**: squads accumulate points from any posted round; Format B (monthly H2H) was retired by D48; even the Cup Final pairs nobody. Exactly four objects can honestly be called a match (audit 04 §1): the tee-sheet game (created on the first tee, never scheduled), the **Ryder duel** (the only scheduled head-to-head, and Home never shows it today), the Major (no opponent), and the retroactive weekly clash. D12 fixes the nouns.

**Options.** (1) Add a generic "next opponent" slot — empty for ~90% of users, invents a mechanic the product rejected. (2) **Home leads with the live-round banner, then the standing, then "your match this week" *only* when a Ryder session is open, then "your next round" (scheduled rounds).** (3) Build D52's weekly clash spotlight (owner-approved, unbuilt) to give every league member a weekly "vs" — needs a table, posts and settle logic.

**Recommendation.** (2). (3) is a real product option and is parked as a question, not designed around.

**Reversibility.** EASY.

**Action.** Proceeding with (2). Flag if the owner wants (3) in scope.

**Affects.** IOS-002 §4, IOS-004 #1, M1/M5.

---

## IOS-009 · Backend additions for the native client — **P1 · PROCEEDING (additive, owner runs `db push`)**

*2026-08-27.*

**Decision.** Ship eleven small, additive backend changes the phone needs (IOS-002 §14): `close_month` revoke (security), `min_ios_build` flag, `native_home()`, `post_round()`, `round_holes_of()`, `handle_available()`, APNs payload routing + categories, `invite_golfer` push fan-out, mute-aware push recipients, `event_players.notify_board`, `live_set_scores` batch + idempotent finish, `device_tokens.platform` widening.

**Context.** None changes web behaviour; each fixes a debt the audit found (the direct `rounds` insert; unreadable `round_holes`; `url:'/'` on every push; a promised invite notification that never sends; a month close any member can trigger).

**Options.** Ship in two batches ahead of M0 and M4 (recommended) · ship lazily per milestone · never (phone mirrors the web's client-side fan-out).

**Recommendation.** Two batches. Batch 1 (before M0): items 10, 6, 1, 3, 8. Batch 2 (before M4): 4, 5, 9, 7. Item 11 before Android.

**Reversibility.** EASY (new migrations; D37 grant discipline; `contract.psv` refreshed after each push).

**Action.** Batch 1 WRITTEN 2026-08-27 (`supabase/migrations/20260827130000…130400`, libpg-query-parsed, `tests/db-checks.sql` check 12 added); awaiting the owner's `supabase db push` and a `contract.psv` refresh. The `close_month` revoke should go first regardless of iOS.

**Affects.** `supabase/migrations/`, `supabase/functions/push`, `packages/db/contract.psv`, `tests/db-checks.sql`.

---

## IOS-010 · Sign in with Apple — **P2 · DOCUMENTED, NOT BUILDING**

*2026-08-27.* Email-OTP-only keeps SIWA optional under App Store 4.8 (D98 guardrail; `spec/native-arc.md`); adding any third-party login makes SIWA mandatory. The phone keeps the reviewer door (`reviewer@cupseason.app` password path) for App Review. Reconsider only if a social login is ever added.

## IOS-011 · Navigation contract — **P1 · PROCEEDING**

*2026-08-27.* Four tabs Home · Clubhouse · ⊕ · You (D82 canon, unchanged); `NavigationStack` per tab; ⊕ is a full-screen cover opening **on the post form**; objects pushed, actions as sheets with detents; the Board is its own screen. Rejected: a fifth tab; the ⊕ as a menu page; the six-segment Clubhouse control. Details IOS-002 §2.

## IOS-012 · Home slot order on the phone — **P1 · PROCEEDING**

*2026-08-27.* Hero first; the "make something" doors leave the lane for a `+` in the toolbar (reverses D94's placement for the phone only; D94's own tradeoff line predicted this). Web Home is untouched.

## IOS-013 · `dim` text contrast — **P2 · PROCEEDING**

*2026-08-27.* Text the web sets in `dim` (≈3.1:1, fails AA) renders in `mut` on iOS; `dim` stays for hairlines and dots. No token change; preflight check 10 untouched. Owner may instead lift the token itself (affects web) — flagged in IOS-003 §2.2.

## IOS-014 · iPad — **P1 · PROCEEDING UNLESS OVERRULED**

*2026-08-27.* Out of scope for v1 (`supportsTablet: false`); the desktop surface is the big-screen product (D98).

## IOS-015 · Founder/QA surfaces on the phone — **P2 · PROCEEDING**

*2026-08-27.* Phone keeps: feedback, report, mute, delete account, founder **field note**. Phone drops: founder dashboard, report resolution, sandbox, `?debug`/`?exit`/`?forge` (a build-flagged Debug menu replaces them). `test-seed` is not founder-gated (audit 06 §9.9) — fix before a public build (folded into IOS-009 batch 2).

## IOS-016 · "Best" means the lowest differential — **P2 · PROCEEDING**

*2026-08-27.* The web says "best" for max PvI on You and min differential on the Tour Card. iOS uses one definition (lowest differential, matching `tour_card`) and labels PvI figures as "vs your number".

## IOS-017 · The Expo B1 scaffold — **P2 · PROCEEDING**

*2026-08-27.* Commit the scaffold on `native/b1-scaffold` as the record of B1 (it passes preflight 14/14) regardless of IOS-006; if IOS-006 = SwiftUI, retire `apps/mobile/` in M0 when its replacement boots. `ios-wrapper/` (Capacitor, dead per D98) is removed in M0. **Status:** the replacement boots (`apps/ios`, 2026-08-27); removal of `apps/mobile/` and `ios-wrapper/` waits on the owner's commit so the record exists first.

---

## Open questions surfaced by the audit (not yet decisions)

Owner-facing questions that fell out of the nine slices, collected so nothing is lost. Each becomes an `IOS-0xx` when it is picked up.

- `transfer_pro` never updates `leagues.commissioner_id`; `delete_account` and `leagues_read` key on it — the original creator can never leave, the new Pro can leave and strand the league (audit 02 §7.2). Server fix; decide which column is "the Pro".
- Two lifecycle columns with no lockstep: a league stuck in `draft` still gets month closes, a Cup Final and a crown (audit 02 §7.3). Gate the engine on `phase`, or make `start_season` the thing that activates the season?
- No server event at first tee (`kicked_off` is dead, audit 02 §7.4) — restore the post + push in the tick, or local notification only?
- Solo leagues are offered floors that never fire (audit 02 §7.12) — assess them or hide the dial?
- Late joiners score retroactively and `join_league` has no phase gate (audit 02 §7.5) — keep, or build §14.1 proration?
- Weekly clash spotlight (D52) — build it, or leave the phone without a season-side weekly "vs"? (audit 04 Q2)
- `played_on` for live finishes is stamped in UTC (`current_date`) — Saturday-evening rounds can land on Sunday and miss a Ryder/Major window (audit 04 §7.4). Server fix.
- Clinch orphans later Ryder sessions (audit 04 §7.1) — is "remaining duels resolve for the record" still wanted?
- Ryder buy-in/settlement thin version (§R12.4) — build or keep the Ryder $0?
- Pot arithmetic: `stake × roster` (what is owed, incl. unpaid and tombstoned) vs `sum(paid)` — needs a decision-log line before it goes into a store listing (audit 06 §9.3/§9.7).
- Points override tool with mandatory reason (spec §9 promise) vs revoking `adj_write` (audit 06 §9.10).
- Server-side seen cursor (cross-device unread) vs per-device (audit 05 Q8).
- Band edge at PvI = −1.0: server 6, client 7 (audit 03 §5.2) — pick the server's rule.
- `set_profile` cannot clear city/home course (audit 01 Q2) — bug or intended.
- Guest identity on native: App Clip for the account-less pencil (IOS-004 #12) — scope.
