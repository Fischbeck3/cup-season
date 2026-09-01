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

**Action.** Batch 1 WRITTEN 2026-08-27 (`supabase/migrations/20260827130000…130400`, libpg-query-parsed, `tests/db-checks.sql` check 12 added); **PUSHED 2026-08-27** (owner-authorised, run from the local session); snapshot refreshed; `Rpc.swift` carries the three new functions. The `close_month` revoke should go first regardless of iOS.

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

---

## IOS-018 · Full web parity on the phone first; the web is rethought after — **P0 · DECIDED 2026-08-27 (owner)**

**Decision.** Supersedes the scope half of IOS-007. The phone builds *everything the web has* — including the wizard's dials and the lock, Pro-assign and the draft board, ledger and pot in full, the founder desk, feedback, reports, the sandbox controls — walked row by row from the IOS-001 parity matrix, in the web's own copy and behaviour. Only after parity is real does the ecosystem question get asked: what the web should be as a standalone product next to the phone (a later decision, not this one).

**Context.** The owner's read of the M0 build: "still like 25% of what it should be." The audit's opinionated "do differently" items (IOS-004) remain valid but are *sequenced after* parity — a native improvement is measured against a working port, not a plan.

**Consequences.** IOS-005's milestones are re-cut as parity waves (see the roadmap amendment); D99's "operating vs authoring" split no longer bounds the phone; `spec/native-arc.md`'s "Owns" table is historical. Nothing in D98/D99 about the backend, the guardrails (no purchase UI, email-OTP-only, immutable rounds, D37 grants) changes.

**Reversibility.** EASY — screens are additive.

**Action.** Proceeding. Logged upstream as D100.

## IOS-019 · The visual pass — depth from ground, not from borders — **P2 · PROCEEDING 2026-08-27**

**Decision.** The parity build (waves 1–6) transplanted the web's card grammar one-to-one and the phone reads flat: every surface is a `bg1` box with a 1px `line`, the hero and a footnote carry the same weight, and iOS 26's glass toolbar clips the wordmark into a "— C" pill. The pass keeps the identity contract (IOS-003 §1: palette, the two metals, three type voices, the spine, the roll) and changes **how surfaces sit**, on four rules:

1. **One hero, one lane, per screen** (IOS-003 §4 "no dashboard grid"). The hero gets **the wash** — a radial of its spine colour at ≤14% opacity from the top-leading corner (ember = live, gold = earned, `pos` = on the tee, dusk = ceremony) — and nothing else on the screen gets one. The Clubhouse's 2×2 stat grid becomes one season strip inside the hero.
2. **Borders retreat, hierarchy comes from ground.** Cards keep `bg1`; the 1px `line` stays on interactive cards only; rows inside a section separate with a hairline, never nest cards in cards. Section heads are the eyebrow plus a hairline rule.
3. **The page header lives in the scroll, not the toolbar.** Home opens on the gradient tick + the serif wordmark + a mono date eyebrow ("THU · AUG 27"); the toolbar keeps only the `+`. Clubhouse and You get the same header shape with the league name / "You".
4. **Panes are a tab strip, not pills.** Mono uppercase labels with an ember underline that slides on the roll; the pills read as filter chips and they are navigation.

The ⊕'s composer is its own decision (IOS-020). Ceremonies, the finish, the settlement and share cards are untouched (they already sit on dusk).

**Context.** Owner, 2026-08-27, on the wave 1–6 build: "improve upon the visuals." Screens read from the simulator signed in to the owner's account.

**Options.** (a) keep the web grammar verbatim — rejected, the phone must not inherit "boxes all the way down" (IOS-004 §"web behaviours the phone must not inherit"); (b) a full re-skin with new colours — rejected, it stops being Cup Season and preflight 15 (palette purity) forbids invented hex; (c) **the four rules above** — chosen: every colour still comes from tokens.json; the wash is a token colour at an opacity.

**Reversibility.** EASY — layout and modifiers, no data, no copy.

**Action.** Proceeding. `CSDesign/Surfaces.swift` adds `CSWash`, `CSPageHeader`, `CSSectionHead`, `CSTabStrip`, `CSHairline`; the screens adopt them.

## IOS-020 · The card — the composer as a scorecard, not a form — **P2 · PROCEEDING 2026-08-27**

**Decision.** "Post a round" keeps every mechanic and every line of web copy (D32 two boxes default, D34 grid opt-in, the even-par guard, `touched`, half-value nines, rating/slope always editable, course memory, scan with the exact soft-failure paths, draft autosave, ceremony → epilogue → partners) and changes its **shape**:

- **The gross is the hero and it is live.** The serif figure (Charter, 64) sits at the top on a dusk wash with the band phrase under it ("beat your number by 2") and a points chip through the open league's lens; it updates as you type. "How this round scores" stops trailing the form (IOS-004 §2).
- **Where** — remembered courses are rows (course · tee · rating/slope), not clipped chips; search sits above them; rating/slope collapse to one mono line ("72.1 / 128") that expands to two fields on tap.
- **Your card** — the 18/9 seg; front and back as two large mono figures with the sum between them; "Enter your card" opens **the scorecard strip**: a real card — Out and In rows of nine cells (hole, par small, score large, coloured by result), tap a cell to select, one big − / + stepper under the strip that advances to the next hole. Eighteen tiny ± pairs go away.
- **Details** — date, photo, scan as pills in one row; the photo preview under them.
- **The bottom bar** — "Post round" pinned in a safe-area inset with the gross line above it, so the tap is always one thumb away on a long card.
- **Point bands** — a "How points work" disclosure, not a table on every open.

**Context.** Owner, 2026-08-27: "create the post score section." The wave-3 composer is a faithful port of `#view-post` and reads as a long web form on the phone (simulator screenshot: memory chips overflow and clip, the preview is below the fold).

**Reversibility.** EASY — same model (`PostRoundModel`, `PostCard`), same RPCs; the view is replaced.

**Action.** Proceeding in `Post/`. The scan confirm surface (the D34 grid's job) is the same strip.

## IOS-021 · Pay-to-play on the phone — the visible model ships, checkout stays on the web — **P1 · RECOMMENDED 2026-08-27**

**Decision (recommended).** Integrate D56 exactly as decided — **visible model, no checkout** — on the phone now: `app_flags.pricing` (the kill switch + bands), the wizard's pot-step pass card, the You-tab membership card (Founding / free season / paid states), the League Room pot pane's Pro card, and the store metadata line "there are no in-app purchases." Close the two open items with a recommendation: **$79 anchor, banded flat $49 / $79 / $99 at ≤9 / 10–13 / 14+, fixed at roster lock; Founding cap 10, numbered.** Checkout, when it opens at the first season-2 "run it back," is **Stripe on cupseason.app** with the phone showing pass status and (while US rules allow) a "Renew at cupseason.app" link — never IAP-first (discovery §6.3).

**Why P1 not P2.** The price point was left to the focus-group script (D56); shipping a number on the phone closes it by default. The owner should confirm the $79 anchor or say "range" (the deck's fallback framing) before the surfaces go live — the flag makes either a one-row change, not a rebuild.

**Context.** Owner, 2026-08-27: "finalize pay to play plan and integrate." No pricing surface was ever built on the web (grep: 0 hits; no `pricing` flag in prod as of today).

**Options.** (a) IAP now — rejected: 15–30% on a $79 desk purchase, App Review exposure, and D56 said checkout waits for season 2; (b) Stripe checkout on the phone now — rejected: same timing argument, plus link-out rules are before SCOTUS; (c) **visible model now, Stripe on the web at season 2** — chosen.

**Reversibility.** EASY — one flag write hides every surface.

**Action.** Plan + surfaces built behind `pricing.visible` (seeded `false` in the migration so nothing shows until the owner flips it). Owner decides: the anchor, and the flip.

**Amended 2026-08-27 (evening) — owner: "build the annual recommendation; look at competitors and reduce 25%."** The unit is now the **league-year** (one pass, every season the league runs in twelve months; first year free), and the bands are set 25% under the per-league comps — Golf League Tracker $119/season (≤365 days), Fantrax premium league $130, MyFantasyLeague ~$110, LeagueLobster $228/yr, League Golfer $10–20/player/yr — giving **$59 ≤9 · $89 10–13 · $109 14+ a year** (≈ $6.50–$7.80 a player a year at every banded roster). Logged upstream as **D101**. The anchor question is closed; the flip stays the owner's.

## IOS-022 · The polish list — **P2 · PROCEEDING 2026-08-27 (owner: "follow your rec for all")**

**Decision.** From the professional review: (1) the empty navigation bar above Home's wordmark goes — `+` moves into the header row; (2) the You hero's marker watermark drops to 10% or gains a label; (3) the ⊕ presents with a rise on the roll and a haptic; (4) the composer's rating/slope row expands only on tap (a picked tee fills it); (5) copy density — every fine-print line appears once per screen; (6) a haptics vocabulary via `sensoryFeedback` on post, tee-off, lead change; (7) the Major's door is hidden behind a flag for v1 (the code stays); (8) the Founder's Desk, feedback ledger and QA surfaces leave the You tab and live behind a long-press on the build line in Settings; (9) a Dynamic Type / VoiceOver pass on the season strip, the scorecard strip and the tab strip; (10) a real light-theme pass. **Reversibility.** EASY. **Action.** Proceeding.

## IOS-023 · Sign in with Apple beside the code — **P1 · DECIDED 2026-08-27 (owner)**

**Decision.** Supersedes the email-OTP-only guardrail (IOS-018's list) for the door only: Apple sign-in is offered as a second door, code-only email stays the first. Client: `SupabaseService.signInWithApple(idToken:nonce:)` through the service (preflight 16 still forbids direct auth calls and any redirect URL); the button renders only when `app_flags.ios.apple_sign_in` is true, so the owner enables it after the Apple portal + Supabase provider are configured. **Why P1.** Apple requires it if any other third-party login ever ships, and the OTP delay is a measured drop-off. **Owner owes:** the Sign in with Apple capability on the App ID, the Services ID/key in Supabase Auth → Providers → Apple, then the flag. **Reversibility.** EASY (flag).

## IOS-024 · Reliability floor — MetricKit, five events, `test-seed` gated — **P2 · PROCEEDING 2026-08-27**

**Decision.** (1) MetricKit crash/hang diagnostics land in `client_events` (fire-and-forget, 4-frame stack kept — the ghost lesson); (2) five product events: `signed_in`, `card_set`, `league_created`, `league_locked`, `round_posted`; (3) `test-seed` requires the caller to be the founder (`profiles.is_founder`) — SEC-H2 closes. **Reversibility.** EASY.

## IOS-025 · Looks on the phone — the resolver, the two pickers, the surfaces — **P2 · PROCEEDING 2026-08-27 (D103a)**

**Decision.** `CSLooks` (generated) + a `LookResolver` in the Kit: `resolve(date:, leaguePhase:, leagueLook:, personal:)` with the D103a precedence. Personal dial in Settings → Appearance ("Palette": Follow the calendar · Fescue only · each look, with its dates). The Pro's dial on the League pane ("Dress the room": Follow the calendar · each look) writing `set_league_look()`; `league_looks()` read once per session. Surfaces: the Home hero and the Clubhouse hero take the resolved look's accent as spine + wash; the ⊕ halo tints; the occasion card and empty states take the motif and eyebrow. Ceremonies, the pot, share cards, the founding tag ignore looks. **Reversibility.** EASY — `none` on both dials is homebase. **Action.** Proceeding.

## IOS-026 · Wave 7 — push that means something — **P2 · PROCEEDING 2026-08-27 (D104)**

**Decision.** The contract is `docs/ios/push-contract.md` (payload keys, categories, badge rule, deep-link table). Backend: the `push` function sends routed APNs payloads with categories and a per-recipient badge, filters mutes and the Pro's `notify_system` curation, and `invite_golfer` fans into `push_nudges`. Phone: `UNNotificationCategory` registration with the three actions, a `PushRouter` (cold start + foreground) landing on the right screen through the `Presenter`, the contextual permission ask with a pre-permission explainer, badge discipline, and the local Ryder reminder. **Owner:** the APNs key (.p8) → `supabase secrets set APNS_P8 APNS_KEY_ID APNS_TEAM_ID` (+ `APNS_SANDBOX=1` only while a tethered dev build is under test — runbook D5), `supabase functions deploy push`, `supabase db push`. **Reversibility.** EASY.

## IOS-027 · TestFlight prep — the four blockers closed, the manifest, the pipeline — **P1 · RECOMMENDED 2026-08-28 (owner: "let's get started on the next item")**

**Decisions (recommended, from the runbook's D1/D3/D4/D6/D9).** D1 iPhone-only — already the build setting (IOS-014). D3 pre-empt the pot — the paragraph is in `docs/ios/app-review-notes.md`. D4 the reviewer lands in a seeded sandbox — `test-seed` gains `target_email` so the founder seeds the reviewer account (`{"action":"seed","target_email":"reviewer@cupseason.app"}`), and the walkthrough is in the notes. D6 money on screen — status only, no link-out; `pricing.visible` stays false for the review build. D9 privacy — `CupSeason/PrivacyInfo.xcprivacy` (no tracking; contact, user content, device id, crash and usage data linked to identity; required-reason APIs: UserDefaults, file timestamps, boot time) and the matching nutrition-label answers.

**Pipeline.** `tools/ios-archive.sh [--upload]` — archive (Release, build number = commit count), export with `apps/ios/ExportOptions.plist` (app-store-connect, automatic signing, team `3F7BK4WVH8`), upload with `altool` and an App Store Connect API key from the environment. Screenshots: the 6.9" set captured from the simulator via the dev hatches.

**Owner owes.** App Store Connect: the app record (name, bundle id `app.cupseason.ios`, SKU) and an API key (Users and Access → Integrations, role App Manager; `ASC_KEY_ID`, `ASC_ISSUER_ID`, the `.p8` under `~/.appstoreconnect/private_keys/`). `supabase functions deploy test-seed` (the target_email change). Unset `APNS_SANDBOX` before the first upload. Then `tools/ios-archive.sh --upload`, internal testing to PIGL.

**Reversibility.** EASY. **Why P1.** The four are the owner's calls; each is closed here with a recommendation and nothing ships until they run the upload.

## IOS-028 · The You tab and the sharing surface — **P1 · RECOMMENDED 2026-09-01 (review only, nothing built)**

**Artifact.** `docs/ios/IOS-028-you-card-and-sharing-audit.md` — a magnifying-glass pass over You / the Tour Card / the ⚙ chain, a full inventory of every shareable artifact on both clients, and production counts (read-only, 2026-09-01).

**What it found.** (A) The You hero's face is 56pt on a screen whose only subject is identity, and it is not a tap target. (B) The ⚙ opens `CardAndSettingsScreen` on the **"Your card"** pane, so a settings button lands on a page whose other half is labelled Settings — true on iOS (`CardAndSettingsScreen.swift:16`) and on the web (`openProfileHub`). (C) Nothing in the app ever offers a photo; the hero prompts for the GHIN instead. (D) The Tour Card cannot be shared and there is no `card` share kind. (E) Every round/settlement share lives only in the epilogue or finish sheet — the receipt and the scorecard have no share on either client. (F) Every PNG share ships as image + caption with **no URL**, and none of the image paths log `artifact_shared`. (G) `?share=` is not a Universal Link and no App Store link exists anywhere in the repo. (H) There is no buddy invite that works without a league.

**The numbers.** 39 profiles / **1 photo**; 211 rounds / **1 photo**; **7 shares ever minted** against 211 rounds; 22 buddy links of which 10 are still pending; **0 scan claims ever**; 4 chat posts in 356 board posts.

**Recommendations (E1–E9 in the artifact), in build order.** E1 a permanent share door on the receipt / scorecard / Tour Card (small, highest return) · E2 every image share carries its link and logs the tap (trivial) · E3 the gear means Settings, the card is reached by touching the card (small) · E4 ask for the photo on the hero, on the face, and at card-gate step 2 (small) · E5 face to 88pt on You, 72pt on the Tour Card (trivial) · E6 a `card` share kind + a public golfer page + a `card` case in `share-preview.ts` (medium) · E7 the card page **is** the buddy invite (medium, reuses E6) · E8 an App Store handoff on the share page + `?share` in the AASA (small, gated on the store listing) · E9 investigate why `scan_claims` is zero (check `app_flags.scan` first).

**Owner's calls.** (1) E3 — the full swap (gear → Settings, hero → card editor) or the minimum fix (gear lands on `pane = 1`)? (2) E6 — does a publicly shared Tour Card show the handicap index? Recommendation: yes, gated on `discoverable`, revocable like every other share. (3) E7 — the card page as the invite (recommended) or a dedicated `?buddy=` token?

**Nothing built.** Rule 1. Each item that changes a mechanic (E6, E7) also needs a `spec/decision-log.md` entry before it ships (rule 5); E1–E5 and E8 are surfaces and tap targets, not mechanics. **Reversibility.** EASY throughout.

## IOS-029 · The three calls from IOS-028 — **DECIDED 2026-09-01 (owner: "B, A, A. Build it!")**

**Call 1 · the gear — Option B, the swap.** The ⚙ opens **Settings** and nothing else; the card editor is reached by **touching the card**. Consequences taken: `CardAndSettingsScreen`'s segmented control retires and the two panes become two routes (`YouRoute.settings`, `YouRoute.card`); `YouHero`'s face goes **56 → 88pt** and becomes a button (photo picker when empty, card editor when set); the hero's anchor line prompts for the **photo** when `photo_path` is null and keeps the GHIN prompt only once a photo exists; an "Edit your card" row sits under the hero as the labelled door. Same swap on the web (`#youProfile` → the settings pane; `#youCard` becomes the card door). **Why B over A:** the minimum fix (`pane = 1`) closes the reported symptom and leaves the face inert and the photo four taps down — 1 profile in 39 has one. **Reversibility.** EASY; the pane code stays until the route is proven.

**Call 2 · the public card — Option A, the number travels.** Logged upstream as **D186**. `index_current` rides the shared card, gated on `discoverable` (`nobody` cannot share at all; `friends` shares the card without the number to a non-buddy). **Why A:** without it the link preview loses its only sentence, which is the failure D77/D78 was built to fix.

**Call 3 · the invite — Option A, the card is the invite.** Logged upstream as **D186**. The public card page carries "Add me on Cup Season" → `share_buddy(p_token)`, authenticated, resolving the token server-side into the existing `friend_request` path. **Why A:** no ninth anon endpoint, no second token table, no second revoke path — and an invite with a face beats an invite with a code.

**Not gated on a call, built in the same pass (IOS-028 E1/E2).** A permanent share door on the round receipt, the scorecard and the Tour Card — sharing stops being a thirty-second window; and every image share carries its link and logs `artifact_shared`, so the path people actually use is both reachable and visible to the funnel. These are surfaces, not mechanics.

**Owner owes (the mutating half — CLAUDE.md deploy discipline).** `supabase db push` (the new migration), then `supabase functions deploy` is **not** needed — the OG rewrite is a Netlify edge function and ships with `git push`. Verify the webhook-free path the usual way: `#obCaption` on cupseason.app should read the new SHA.

**Verification split (rule 6).** The migration, the web client, the edge function and the tests were built and run in the remote session. **The Xcode build, the simulator pass and the device check are the owner's, locally** — a remote session cannot compile Swift or drive a simulator. Preflight's Swift checks (15/16/17) do run here and pass.

## IOS-030 · E8 and E9 closed — the link opens the app, and the scan door gets breadcrumbs — **2026-09-01 (owner: "Now do E8 and E9")**

**E8 (D188) · `?share=` is a Universal Link, and the page knows the app exists.** The AASA gains `share`; `onOpenURL` stores the token and raises `SharedCardSheet`, which renders a shared Tour Card in the SAME `CredentialCard` the owner sees and carries "Add me on Cup Season" → `share_buddy`. Anon-safe: `share_info` is public, so a signed-out phone sees the card and only needs an account for the button; a token stored at the door replays when the golfer card exists.
**The trap, named because it nearly shipped:** the AASA cannot inspect a token, so claiming `?share=` claims all four kinds. `SharedCardRepository.load` answers a three-way enum — `.card` renders natively, `.web` hands round / settlement / recap to their own web page **in `SFSafariViewController`** (never `UIApplication.open`: this app claims the link, so opening it loops), `.dead` is D57's single answer. Without that, three working link types would have started reading "This link is dead".
**The store CTA** rides `door_flags()` (already anon, already one of the twelve) as `app_store_url` — null until the owner sets `app_flags.ios.app_store_url`, blank reads as null, https-only client-side, and iOS user agents only. **Owner owes:** the listing, then `update app_flags set value = value || '{"app_store_url":"…"}'::jsonb where key='ios';`.

**E9 (D187) · the scan is not broken, it is unchosen — and we were blind to which.** Measured, not assumed: the flag is on and uncapped; the button renders (`display: block`, 602px down an 844pt viewport); the Edge Function is 4/4 ok; both clients extract partner rows. **92 composer opens since it shipped, 0 invocations.** So `scan_claims = 0` is a door nobody has opened, not a broken mint. Two real defects fell out of it and are fixed: a scanned round recorded `source: 'quick'` on **both** clients, so scan adoption could never be measured (`rounds_source_check` widened, both composers corrected, with a skew retry on each — the iOS insert sheds `source` first, the web retries on the 23514); and the only scan breadcrumbs fired *after* a completed post, so `scan_tap` / `scan_read` (with the player count) / `scan_unavailable` now bracket the door on both clients. The scan's reason to exist is finally stated at the button, in one line shared verbatim by both clients (`PostScan.groupLine`).
**Deliberately NOT done:** promoting the scan (after a live round with guests, from the board). That is a positioning change, and the honest position is that we do not yet know whether the door is unattractive or the confirm step is too long. The breadcrumbs answer it in weeks; the answer should decide it.

**Verification split (rule 6) unchanged.** Migrations, web and edge function built and run here; **the Xcode build, the simulator pass and a real Universal Link tap are the owner's, locally.** A Universal Link cannot be verified from a Linux sandbox at all — the AASA has to be served from cupseason.app and the app installed on a device.
