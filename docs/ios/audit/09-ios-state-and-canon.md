# 09 · iOS state and product canon — audit (read-only, 2026-08-27)

Repo: `/Users/fischbeck3/cup-season`, branch `native/b1-scaffold` (== `main` == `origin/main` at `e0bd5a9`).
Every path below is absolute under that root unless stated.

---

## (1) What exists for iOS today: the Expo B1 scaffold and the shared layer

### 1a · `apps/mobile/` — the Expo / React Native scaffold (UNCOMMITTED)

**Status in git:** the entire `apps/` tree is untracked (`?? apps/`). So are
`packages/db/auth.ts`, `packages/db/package.json`, `packages/tokens/package.json`;
`packages/db/index.ts` and `tests/preflight.mjs` are modified. Nothing of B1 has
been committed. The branch `native/b1-scaffold` has zero commits over `main`.

**Stack (`apps/mobile/package.json`):** `expo ~56.0.20`, `react-native 0.85.3`,
`react 19.2.3`, `expo-router ~56.2.19`, `expo-secure-store`, `expo-linking`,
`expo-font`, `expo-status-bar`, `expo-constants`, `react-native-reanimated 4.3.1`
(exact), `react-native-worklets 0.8.3` (exact), gesture-handler, safe-area-context,
screens, `react-native-url-polyfill`, `@supabase/supabase-js ^2.112.4`;
TypeScript `~6.0.3`; `overrides.react-dom = 19.2.3`. Scripts: `expo start`,
`expo run:ios`, `expo run:android`, `expo start --web`.

**Why SDK 56, not 57** (`apps/mobile/AGENTS.md`): Expo Go on the App Store runs
exactly one SDK; the owner's phone had a Go that rejected SDK 57 with "Project is
incompatible with this version of Expo Go" (confirmed in
`apps/mobile/.expo/dev/logs/start.log` at 2026-08-27 05:31 MST, first init was
`57.0.19` on 08-26 20:00). The project was pinned DOWN to 56 to match the phone.
Cost noted in the same file: SDK 56 ships Hermes V1 `250829098.0.10` with a known
memory regression (fix in `.16`, arriving with SDK 57 / RN 0.86.2). `npx expo-doctor`
run today: **21/22**, only the Hermes note failing. Other pins that "each cost a
round-trip": reanimated/worklets pinned exact to `bundledNativeModules.json`;
`react-dom` override to stop an ERESOLVE on a web-only peer; `expo-font` direct
so `expo-symbols`' loose peer resolves to the SDK 56 copy; `newArchEnabled` is not
a valid key on this SDK (new arch always on).

**`app.json`:** name "Cup Season", slug `cup-season`, `scheme: cupseason`,
`userInterfaceStyle: dark`, portrait, `ios.bundleIdentifier: app.cupseason.ios`,
`ios.supportsTablet: false` (this is runbook D1 "iPhone-only" already applied),
`android.package: app.cupseason.android` with adaptive icon set, plugins:
expo-router, expo-secure-store, expo-status-bar, expo-font. No
`associatedDomains`, no push entitlement, no EAS project id, no `expo-updates`.

**`metro.config.js`:** `watchFolders = [repo/packages]`,
`resolver.nodeModulesPaths = [apps/mobile/node_modules]`,
`extraNodeModules = { '@cs/tokens' → packages/tokens, '@cs/db' → packages/db }`.
Explicitly NO root `package.json` (A4: Netlify auto-installs when it sees a root
manifest; the site has no deps). `disableHierarchicalLookup` was tried and
removed — it broke `@expo/metro-runtime` nested under `expo-router/node_modules`.
`tsconfig.json` mirrors the aliases with `paths` and includes `../../packages/**/*.ts`;
`strict: true`. `tsc --noEmit` passes clean today.

**Screens (`app/`):**
- `_layout.tsx` — SafeAreaProvider › SessionProvider › StatusBar(light) › expo-router
  `Stack` (headerless, fade, `contentStyle.backgroundColor = t.color.bg0`).
- `index.tsx` — the sign-in door. Email → `requestEmailCode()` → 8-digit code
  → `verifyEmailCode()`. Uses `textContentType="oneTimeCode"`, `autoComplete="sms-otp"`,
  `keyboardType="number-pad"`, auto-submits on `isCompleteCode(code)`. No navigation
  on success by design: SessionProvider hears SIGNED_IN and `<Redirect href="/home">`
  fires. Every string/colour comes from tokens; fonts from `t.font.serif/mono`.
- `home.tsx` — "B1's whole gate": reads ONE RPC, `tour_card`, through the typed
  `call(supabase, 'tour_card', { p_profile })`, renders INDEX / ROUNDS / BEST stat
  tiles, marker, city, an error card, a Sign out button, and the caption "B1 is the
  scaffold: it boots, it wears the palette, and it signs you in." Comment lists what
  is deliberately absent (scoring, board, push, standings, tee sheet) and what will
  never be on a phone (wizard, draft board, ledger, founder desk — D98).

**Infrastructure (`src/`):**
- `config.ts` — `SUPABASE_URL = https://zddbfcokmvneltrgukzf.supabase.co` and the
  `sb_publishable_…` key inline, with the argument that they're already public in
  `index.html` and anon holds zero relation privileges (D37).
- `supabase.ts` — ONE `createClient` with `storage: secureStorage`,
  `persistSession`, `autoRefreshToken`, `detectSessionInUrl: false`, and deliberately
  NO `lock` option (deprecated in installed auth-js). `AppState` listener starts/stops
  `auth.startAutoRefresh()` on active/background. Comment reserves a SECOND client for
  realtime in B4 (the CHANNEL_ERROR landmine).
- `secure-store.ts` — Keychain session storage, **chunked at 1536 bytes** under
  expo-secure-store's documented 2048-byte ceiling (`K → "N"`, `K.0..N-1`), with
  `AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY` (readable in a pocket for background refresh /
  B5 push; never iCloud-synced). Torn sets read as null → signed out (chosen failure).
- `session.tsx` — `SessionProvider` with `{ session, ready }`; `currentSession()`
  then `onAuth()` (handler deferred to a microtask — the deadlock landmine).
- `theme.ts` — CONVERTS the 34 CSS-shaped tokens to RN (`"16px"`→16, font stacks
  intersected with `PLATFORM_FAMILIES` ios: Menlo/Charter/Georgia/Palatino, CSS
  box-shadow → `shadow*`/`elevation` with stated approximations). It "converts, never
  invents": no literal colour anywhere; `useTheme()` is a constant returning the dark
  build (no picker yet). Preflight check 12 enforces zero hex/rgba in `apps/mobile`.

**Native project:** `apps/mobile/ios/` exists locally (gitignored via `/ios`), generated
by `expo prebuild` on 08-27 06:51: `CupSeason.xcworkspace`, Pods installed, Podfile
deployment target `16.4`, Hermes, `CupSeason.entitlements` is an EMPTY dict,
`PRODUCT_BUNDLE_IDENTIFIER = app.cupseason.ios`, **no `DEVELOPMENT_TEAM`** in the
pbxproj, `PrivacyInfo.xcprivacy` present. See §8 for the build attempt.

**Preflight additions (uncommitted diff to `tests/preflight.mjs`):** checks 12–14 —
"native palette purity" (no colour literal outside tokens), "native otp discipline"
(no `emailRedirectTo`, no direct `signInWithOtp/verifyOtp/onAuthStateChange`, no
`maxLength 6`), "native rpc grants" (every `call(_, 'name')` must have a
`grant execute` in migrations; raw `.rpc(` outside `src/supabase.ts` fails). All
14 checks PASS today: "1 phone RPCs, all granted, none raw".

### 1b · `packages/` — what the shared layer offers a native client

`packages/README.md`: D98 Phase A. Source of truth → generated → guarded:
`tokens/tokens.json` → `tokens.css`,`tokens.ts` (check 10); `db/contract.psv` →
`db/rpc.ts` (check 11); `db/client.ts` hand-written (tsc --strict). Never hand-edit
generated files; `node tools/build-tokens.mjs` / `node tools/build-db.mjs` (both
`--check`). The live `index.html` does NOT import tokens.css — it is *verified
against* tokens.json rather than built from it.

- **`tokens/tokens.ts`** — `ThemeName = 'dark'|'light'`, 34 `tokenNames` (bg0..bg2,
  line/line2, ink/mut/dim, pos/neg/gold/brand/pine/dawn/focus, warm/hot/fire/cool,
  sq0–sq3, glow, grad, r/rc/rs, sans/mono/serif, roll, shadow-rest/lift), both
  themes as string maps, `defaultTheme = 'dark'` (D76 Charcoal). Values are
  CSS-shaped strings (hence the phone's `theme.ts` converter).
- **`db/contract.psv`** — verbatim `pg_proc` snapshot (`name|args|returns|security|
  grants`), 196 lines, with the read-only refresh query in the header; refreshed
  2026-08-26 after `20260826120000` pushed.
- **`db/rpc.ts`** — GENERATED: `Json` type, `anonCallable` (10 names:
  claim_round_info, email_unsubscribe, founder_id, guest_live_set_score,
  guest_live_set_wolf, guest_live_state, join_covenant_info, league_by_code,
  scan_claim_info, share_info), and `interface Rpc` with **156 functions** typed as
  `{args, returns}` (e.g. `start_live_round`, `live_set_score`, `finish_live_round`,
  `home_feed` row type, `register_device_token(p_token, p_platform?)`,
  `unregister_device_token`, `tour_card`, `round_card`, `my_schedule`, …).
- **`db/client.ts`** — dependency-free (structural `PostgrestLike`), `call()` with
  **deploy-skew retry on ANY error** (drop `skewOptional` args and retry once),
  `RpcError`, `rpcClient()`, `bindRealtimeAuth()` for the dedicated realtime client,
  `deferAuthWork()` (microtask), `localDate()`/`isoDate()` (the UTC-midnight trap).
- **`db/auth.ts`** (new, uncommitted) — structural `AuthLike`; `OTP_LENGTH = 8`;
  `normalizeCode`, `isCompleteCode`, `normalizeEmail`, `looksLikeEmail`;
  `requestEmailCode(client, email)` — signature takes an email and NOTHING else so
  `emailRedirectTo` is unrepresentable; `verifyEmailCode` (type `'email'`),
  `currentSession`, `signOut`, `onAuth` (deferred), `humanAuthError`.
- **`db/index.ts`** — re-exports rpc types, `anonCallable`, client, auth.

**What is proven vs. not:** typecheck and preflight prove the *contract*; the
scaffold proves *design intent*. Nothing in the repo proves a phone completed the
OTP round-trip (see §8). Full table/view row types (`supabase gen types`) are still
absent per `native-arc.md` A2.

---

## (2) `ios-wrapper/` and `spec/ios-wrapper-arc.md` — the abandoned Capacitor shell

`spec/ios-wrapper-arc.md` header: "**SUPERSEDED 2026-08-26 by D98 and
`spec/native-arc.md`.** The Capacitor wrapper is abandoned… Do not build from this
file." Kept because the portal work (Team ID, App ID, APNs key, AASA,
`device_tokens` + RPCs) carries into the native arc.

**What it was (decided with the owner 2026-07-21):** a Capacitor 8.4.2 shell in
**remote-URL mode** — `ios-wrapper/capacitor.config.json`: `appId app.cupseason.ios`,
`server.url https://cupseason.app`, `allowNavigation [cupseason.app, *.supabase.co]`,
`ios.backgroundColor #0A0E0C`; `www/index.html` is a one-line stub. Dependencies:
`@capacitor/{core,cli,ios} ^8.4.2`, `@capacitor/push-notifications ^8.1.2`,
`@capacitor/assets`. Wired as SPM (`CapApp-SPM/Package.swift`), iOS 15 min, no
Podfile. `AppDelegate.swift` adds the two APNs forwarders the plugin needs
(`didRegisterForRemoteNotificationsWithDeviceToken` → NotificationCenter) and the
universal-link `continue userActivity` proxy. `Info.plist` has camera + photo usage
strings and `ITSAppUsesNonExemptEncryption=false`. Work items W1–W7 all shipped
(scaffold, AASA, reviewer door, mute, APNs plumbing, native assets, Apple enrollment).
Commits: `b562a59`, `101c61f`, `f7b8f27`, `4236bfb`.

**Why abandoned (D98 "Problem", `spec/decision-log.md:3500-3517`):**
(a) *the wrapper's ceiling is permanent* — watch scoring and a live match on the lock
screen are structurally unreachable from a WKWebView; (b) *its best argument was
already spent* — offline scoring was solved in the web client by D85's
`window.liveSync` (durable localStorage queue, LWW by client clock, poisoned-write
protection, drain-on-resume), so native would rebuild, not improve; (c) *the surfaces
were never named* — the web client is really a desktop app (draft 117 client refs,
roster 97, wizard 56, ledger 49; 13 breakpoints at 960px, 1120px container).
Accepted cost: "iOS slips from days to months… PIGL gets no app icon this season."

**Dead code still live in the repo:** `ios-wrapper/` (tracked), and the
`window.Capacitor` branch in `index.html` (~13983–14040: `nativePush()`,
`apnsToken(P)`, `cs_apns_token`, the Notifications toggle's native branch). Also the
W3 reviewer door at `index.html:15015-15032` (`sb.auth.signInWithPassword` for
exactly one `reviewer@cupseason.app`, gated by `CS.reviewerMode`) — that one is
client-agnostic and D98 says it survives. `native-arc.md` "Still open #2" says the
standing bias is to remove the dead wiring now ("dead wiring that reads as live is
exactly the false map D97 came out for").

---

## (3) The three-surfaces decision: `native-arc.md`, `native-b1-brief.md`, `desktop-arc.md`, D98

### D98 (`spec/decision-log.md:3493-3578`, 2026-08-26, owner decision, level 5-6)
"The Strava shape — three surfaces, one account, one Postgres":
1. **Phone — Expo / React Native, iOS first, then Android from the same codebase.**
   Owns "what happens standing on a tee box": live scoring, posting a round, the
   board, push, standings read. NOT the wizard or draft board.
2. **Desktop — the web client, rewritten in React shortly after iOS ships.** Owns
   the Pro's desk: wizard, draft, roster, ledger, month closes, deep standings,
   receipts, founder desk; keeps the ten `anon` endpoints for claim/join/share.
3. **Apple Watch — Swift, after the phone app, timing unfixed.** Scoring during play,
   designed for in the phone's round state model.

Principles cited: #1 Golf First, #2 Low Friction; Persona 1 (Commissioner) is a
desktop user, Persona 2 (Competitive Weekend Golfer) is phone + watch.
Stated benefits of the tech choice: the two features that justify native become
reachable; "Android arrives from the same codebase rather than as a third rewrite";
"the whole stack lands on one language and one framework family, which for a solo
builder is the difference between three clients and three copies of the same
client." What survives: Team ID, App ID, bundle id, APNs key/secrets, ASC record,
AASA, `device_tokens` + RPCs, check 9, reviewer door, mute, report, account
deletion, all runbook decisions. Named CONFLICT: D56 anchored pricing to "iOS launch";
proposed re-anchor to the web client — owner has NOT ratified (native-arc "Still open #4").

### `spec/native-arc.md` — the phase plan
- **Phase A (DONE, gate met 2026-08-26):** A1 tokens, A2 RPC contract, A3 data
  layer, A4 monorepo without root manifest. Web client byte-unchanged.
- **Phase B (iOS), one branch per milestone:** `native/b1-scaffold` (boots · real
  palette · real sign-in) → `b2-round` (live scoring, tee sheet, hole-by-hole — "the
  centre of the app and the reason it exists") → `b3-offline` (port `window.liveSync`,
  "highest-risk piece… its failure mode is losing somebody's card"; SQLite + real
  background tasks) → `b4-board` (feed + realtime on a dedicated client) → `b5-push`
  (APNs through existing RPCs; needs a dev build, Expo Go cannot do iOS push) →
  `b6-standings` (read + receipts). **Gate:** a PIGL member plays a full round on the
  phone in a dead zone and the card lands complete.
- **Phase C (Android):** same codebase; `assetlinks.json`, FCM alongside APNs in
  `push/index.ts`, widen `device_tokens.platform check (platform in ('ios'))`
  (`supabase/migrations/20260722013000_mute_and_devices.sql:85`), Play listing +
  gambling declaration. Gate: an Android phone receives a push from a real post.
- **Phase D (Desktop in React):** parallel build then cutover, never in-place;
  desktop-first layout; public pages stay fast/linkable/account-less. Gate: every
  old flow has a home, verified against the RPC list, before DNS moves.
- **Phase E (Watch):** Swift target; Phase B owes it a clean round state model
  separable from view code; design round sync so Garmin can drop in later.
- **Guardrails:** no purchase UI in any client; **email OTP only** ("adding a
  third-party login obliges Sign in with Apple"); explicit grants; rounds immutable.
- **Still open:** dead Capacitor code removal; Expo Updates OTA policy; D56 trigger.

### `spec/native-b1-brief.md`
Local-only work (remote can't run Expo/simulator/phone). B1 = "an Expo app that
boots, wears the real palette, and signs a real person in. Nothing else."
**Gate: "You sign in on your own iPhone, in Expo Go, with a real email code, and
land on a screen wearing the Charcoal palette."** Decisions not to reopen: Expo/RN
TypeScript; `apps/mobile/`; no root package.json; import the shared layer from day
one. "Xcode: B1 does not need it… B5 does."

### `spec/desktop-arc.md`
Predates D98 (2026-07-19/20) but defines what the desktop surface is FOR: the Pro
evaluates on a big screen ("convince, then start"); signed-in desktop today is "a
stretched phone" (232px sidebar + 1120px column). Stage 3 named the big-screen shell
order: wizard → Home (feed + right rail) → League Room (standings + board). The door
is ONE screen; the story lives in the welcome tour. Voice canon: "your number," "the
Pro," no prices on the door, D39 ledger language.

---

## (4) App Store readiness facts (`spec/appstore-launch-kit.md`, `spec/appstore-runbook.md`)

| Fact | Value / source |
|---|---|
| Team ID | `3F7BK4WVH8` (enrolled 2026-08-26; runbook, D98, AASA) |
| Bundle id | `app.cupseason.ios` — "frozen at first upload" (runbook Phase 1) |
| AASA | `/.well-known/apple-app-site-association`, modern `appIDs` + `components` form matching `?claim=*` and `?join=*`; copied to dist by `stamp-version.sh:44`; JSON content-type header in `netlify.toml:49`; preflight check 9 asserts the Team ID |
| APNs | server side built and env-gated in `supabase/functions/push/index.ts:126-173` (`APNS_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`, optional `APNS_TOPIC` default bundle id, `APNS_SANDBOX`); dead tokens pruned. Portal steps (App ID capabilities, .p8 key → secrets, ASC record) are runbook Phase 1 — status unknown from the repo |
| device tokens | `device_tokens` table (`platform in ('ios')` only), `register_device_token`, `unregister_device_token` (`20260826120000`) |
| Listing | Name "Cup Season: Golf Leagues" (24/30); subtitle "Run your golf season"; keywords string; category Sports; age rating 4+ with NO gambling flags; full description drafted; What's New copy |
| Review notes | §5 paste-ready text: no wagering/deposits/payouts/IAP; email OTP; reviewer creds `{demo account email}` TBD |
| Reviewer account | W3 password door built (`reviewer@cupseason.app`); runbook D4 recommends seeding it into the sandbox league — NOT decided |
| Screenshots | 6.9" (1320×2868) only mandatory; 8-shot list; warning that the demo diorama uses real PIGL names |
| Privacy labels | D9: Contact Info, User Content, Identifiers (device token), Usage Data — all linked to identity; Tracking: NO |
| Device family | D1 recommends iPhone-only → already `supportsTablet: false` in `app.json` |
| Money | D6: status only, no outbound checkout link; no IAP ever (D56) |
| Export compliance | `ITSAppUsesNonExemptEncryption=false` (was in the wrapper's Info.plist; must be re-declared in the Expo app — not present in `app.json` today) |
| Version | D8: iOS `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` hand-set, unrelated to `__CS_VERSION__` |
| Rejection playbook | 5.3.4, 4.2, 2.1, 1.2 (`report_content` + `set_mute`), 5.1.1(v) (`delete_account`), 4.8 SiWA "not applicable" |

Runbook amendment (2026-08-26): Phases 0, 1, 4, 5 and all nine decisions hold;
Phases 2–3 (Capacitor/Xcode + WKWebView device pass) superseded by the Expo build.
The kit's launch-day plan targeted Tue Aug 18 / Wed Aug 19 — now moot.

---

## (5) The product canon a native app must serve

- **`spec/product-vision-v1.0.md`** — Vision: "the operating system for amateur
  golf leagues… make every round of golf matter because it belongs to a season."
  **Five principles:** 1 Golf First · 2 Low Friction Wins · 3 Real Golf · 4 Memory >
  Statistics · 5 The App Should Feel Alive. **Five-question filter:** reduce friction?
  strengthen the season? create memories? encourage return? happen automatically
  from data we already collect? **Cup Season Test:** "If this feature disappeared
  tomorrow, would golfers miss it because it made their golf life richer, or because
  it was another stat they occasionally glanced at?" Success metrics: profile <2 min,
  join <30 s, **post a round <60 s**, understand standings <10 s, never need a
  tutorial. Features to reject: anything requiring extra tracking during play
  (shots, GPS, putts, GIR…). Notifications: "only meaningful ones… No spam."
- **`spec/home-arc.md`** (D81/D82) — Home is a state machine with ONE hero slot
  dispatched on league state (record → seed → standing move → countdown → four-makes-
  a-league → established → three-rounds), an occasion card, "Around your buddies"
  feed, "Upcoming golf" rows. Data sources listed with `window.*` names — a phone Home
  needs the same facts via RPC (`season_scenarios`, `league_pulse`, `my_friends`,
  `my_schedule`, `home_feed`, `career_record`).
- **`spec/session-tracks.md`** — five lanes (Gameplay · UX · Social · Growth/Launch
  · Business); routing rule "Gameplay builds the rule · UX makes it legible · Social
  makes it sticky · Growth gets it in front of people · Business decides why."
- **`spec/blue-sky-dossier.md`** — 16 ranked ideas (Belt, Last Round With, Forfeit
  Ledger, Shoebox, In Memoriam, Gallery, Summit, Gauntlet, Sunday Paper, Marker
  Provenance, Almanac, Pilgrimage, Clubhouse Shelf, Solstice, Lines, Amateur Number).
  Phone-relevant constraint stated in #6: "the pocket principle — the phone spends 4
  hours in a pocket and 40 seconds in a hand… never buzz mid-hole."
- **`spec/gtm-year1.md`** — "We do not acquire golfers. We acquire leagues, one Pro
  at a time." North star: Active Recurring Leagues. Organic engine = invite link,
  settlement card with claim link ("the guest-claim wedge… the single best
  acquisition surface we own"), season recap. Lifecycle push table §9; "every message
  must be true to this golfer's league this week, or it doesn't send." Beachhead:
  standing buddy leagues in Phoenix/Scottsdale.
- **`spec/pricing-arc.md`** / D56 — visible model, no checkout; season pass paid
  by the Pro from the pot ($49–99), golfer free forever, Founding Leagues free
  forever, charge at season-2 "run it back"; Apple posture memo (anti-steering rules)
  is a deliverable. No pricing on the door.

Implication for the phone: the phone is Persona 2's surface — post in <60 s, live
scoring, the board, meaningful push, standings read with receipts (§16) — and must
never carry a purchase UI, never reintroduce links in email auth, never show a price
on the door.

---

## (6) Decision-log entries touching iOS / native / phone / mobile / push / Apple / App Store

Grep of `spec/decision-log.md` (99 entries) for iOS|native|phone|mobile|push|APNs|
Apple|App Store|widget|Capacitor|Expo|TestFlight, mapped to entries. No entry
mentions "widget" or "Live Activity". "push" hits that are `git push`/`db push`
noise are excluded below.

| ID | One line |
|---|---|
| D23 | Nudge policy — push is curated by kind + per-user mutes; V1 nudges are HOME-SURFACED chips only, never push; push escalation is a Year-2 decision |
| D25 | Reactions & comments become real (client-side `feed[fi].cm.push` array replaced by a migration) |
| D30 | Round Recap Card — shared via the native share sheet on mobile |
| D31 | The Climb's finish — anything push-shaped is D23's fence |
| D43 | Championship window — stories ride the existing curated push webhook; no new push class |
| D52 | Weekly clash — push rides curated rails, opt-in |
| **D56** | Pricing unparked — visible model **at iOS launch**, checkout at season 2; no IAP; the trigger D98 proposes to re-anchor to web |
| D63 | Last Round With — a "longing" nudge, threshold-fired, never scheduled |
| D68 | Season-end email — "push exists but…" the ceremony is email; same webhook shape as push |
| D74 | Sunningdale — iOS data detectors parse `Word:` at the head of a share message as a URI (share-copy landmine) |
| D76 | Charcoal — triggered by the App Store home-screen exploration (2026-07-26): the identity goes dark |
| D77 | Settlement artifact — result outranks names in share-sheet body AND the push body (`push_title`) |
| D78 | Settlement becomes an artifact — evidence "lived only on the phone that kept score" |
| D80 | "Buddies" — the push says "wants in your crew" |
| D81 | Home state machine — mobile `order:-1` rail flip removed |
| **D85** | Everyone's phone scores the live round (sync v2) — `liveSync`, LWW by `client_ts`, durable queue; the offline argument D98 cites |
| **D86** | The tee sheet calls you to it — `start_live_round` inserts a `push_nudges` row → APNs/web push; realtime arrival |
| D87 | The pencil is for the golfer — `.guestlive` kiosk for a phone with no account |
| D88 | The visitor gets a doorbell and a door — `push_nudges` to a known guest; "four phones that all get told" |
| D94 | Home leads with the doors — mobile fold ordering |
| **D98** | The wrapper comes out — three named surfaces, one React stack (full text in §3) |

Not in the log at all: the original 2026-07-21 Capacitor decision (D98 notes this
gap explicitly), APNs server build (`20260722013000`, only in the wrapper arc doc),
and anything about widgets, Live Activities, haptics, Dynamic Type, or Sign in with
Apple.

---

## (7) Sign in with Apple / OAuth — the Supabase auth provider situation

- **Not configured anywhere in the repo.** `supabase/config.toml:322-332` has the
  boilerplate `[auth.external.apple] enabled = false, client_id = ""` (local-dev
  config only; the hosted project's providers are dashboard-side and not in git).
- **No client code** calls `signInWithOAuth` / `signInWithIdToken` / any provider.
  The only non-OTP auth call in the whole repo is the reviewer door's
  `sb.auth.signInWithPassword` at `index.html:15025`.
- **Canon says stay that way:** `native-arc.md:202` "Email OTP only. Adding a
  third-party login obliges Sign in with Apple"; runbook rejection row 4.8 "SiWA…
  required only alongside a third-party login, and there is none"; D98 upholds
  "email-OTP-only sign-in, which is what keeps Sign in with Apple optional."
- **Consequence if that ever changes:** SiWA needs the App ID capability, a
  Services ID + key in the Apple portal, the provider enabled in the Supabase
  dashboard, and (on RN) `expo-apple-authentication` → `signInWithIdToken`; on
  SwiftUI it is `SignInWithAppleButton` + the same `signInWithIdToken`. Nothing of
  that exists.
- No `apple` mention in any migration; `profiles.email` is NOT NULL and set from
  `auth.users` by `set_profile()` — Apple's "hide my email" relay addresses would
  work but would land in `profiles.email` as `@privaterelay.appleid.com`.

---

## (8) State of the B1 gate — committed vs. not, and what actually ran

**Committed (main = origin/main = native/b1-scaffold = `e0bd5a9`, 2026-08-27):**
`6fe82ae` D98 docs · `313b064` Phase A shared layer · `8d6e024` three-layer deploy
prompt · `a8fe348` RPC snapshot refresh · `e0bd5a9` branch scheme + B1 brief.
The `claude/apple-dev-account-setup-i3v8wm` branch tip is `8d6e024` (behind main).

**Not committed (working tree):** the whole `apps/mobile/` scaffold (21 files +
lockfile + assets), `packages/db/auth.ts`, the two `packages/*/package.json`, the
`export * from './auth'` line in `packages/db/index.ts`, and preflight checks 12–14.
No stash. `native/b1-scaffold` has no upstream and no commits of its own.

**What the local logs show ran (all times MST, from `apps/mobile/.expo/`):**
1. 08-26 20:00 — `expo start` on SDK 57 (`57.0.19`); also a web `expo export`.
2. 08-27 05:31 — a phone's Expo Go hit the dev server and was refused: "Project is
   incompatible with this version of Expo Go."
3. 08-27 06:45 — `expo run:ios` targeting a **physical device**
   (`-destination id=00008130-000A1590362A001C`) → **BUILD FAILED**: "No profiles for
   'app.cupseason.ios' were found… Automatic signing is disabled" (no
   `DEVELOPMENT_TEAM` in the generated pbxproj). Pods/prebuild completed at 06:51.
4. 08-27 07:15 and 07:29 — after downgrading to SDK 56 (`56.1.24` CLI), Metro
   bundled `platform: ios` in dev mode twice — Metro only bundles on a client request,
   so Expo Go on the phone did pull the SDK-56 bundle at least twice.
   `devices.json` is empty (that file tracks dev-client devices, not Expo Go).

**Verdict:** the gate ("sign in on your own iPhone, in Expo Go, with a real email
code, and land on a Charcoal screen") is **not evidenced in the repo**. The bundle
demonstrably reached the phone; whether the OTP round-trip and `tour_card` render
succeeded is not recorded anywhere (no commit, no note in AGENTS.md, no
`client_events` — the phone app has no telemetry yet). The dev-build path (needed
for B5 push, universal links, and any of Live Activities/widgets) is blocked on
signing until a team is set in Xcode / `expo run:ios` is run with the Team ID.

---

## (9) Engineering assessment — Expo/React Native vs. Swift/SwiftUI, for this product and this team

Framing facts that both sides have to respect:
- The competition model lives entirely in Postgres (`cup_points`, `score_round`,
  `v_rounds_ranked`, `close_month`, the live-round RPCs). Either client is a thin
  typed shell over 156 RPCs. Neither choice reimplements a rule.
- The one piece of *client* logic worth porting is `liveSync` (~100 lines at
  `index.html:14732-14835`: durable queue, LWW by `client_ts`, poison protection,
  drain-on-resume). B3 says it should become SQLite + real background tasks anyway.
- The owner is solo, builds with Claude Code, wants Live Activities, widgets,
  haptics, Dynamic Type, and has a Watch in the plan. D98 commits to Android (C)
  and a React desktop rewrite (D) sharing `packages/`.
- The builder's own mobile-native hours so far: Capacitor (5 weeks, thrown away) and
  ~12 hours of Expo (SDK downgrade, dependency pinning, a failed signing build, an
  Expo Go bundle). Neither is a data point in favour of either stack; both are data
  points about how much friction the environment itself generates.

### The case for staying on Expo / React Native

1. **`packages/` is already the RN shape.** `tokens.ts`, `rpc.ts`, `client.ts`,
   `auth.ts` are TypeScript with structural Supabase types; the phone imports them
   via Metro aliases today and preflight checks 12–14 enforce that it keeps doing so.
   A Swift app cannot import any of it — it needs a Swift mirror of the tokens (easy,
   generate it from `tokens.json`), a Swift mirror of the RPC contract (generate from
   `contract.psv` — feasible, but the generator is new work), and a re-implementation
   of the skew retry, OTP rules, and date helpers in Swift (small, but the whole point
   of Phase A was to write those rules once).
2. **Phase C (Android) is nearly free on RN and is a second app on Swift.** D98's
   stated benefit — "Android arrives from the same codebase rather than as a third
   rewrite" — is real. `app.json` already carries `android.package` and adaptive
   icons. On Swift, Android is either never, or Kotlin, or a later RN app anyway.
   Whether Android matters in Year 1 is a business question (gtm-year1 never mentions
   Android; the beachhead crew is PIGL on iPhones — CLAUDE.md and the runbook talk
   only about iPhones), but D98 chose it deliberately.
3. **Phase D (React desktop) shares components, not just packages.** A round card, a
   standings row, a receipt drawer written once in React can be reused on desktop
   with `react-native-web` or at least share hooks and data code. Swift shares nothing
   with the desktop rewrite.
4. **Claude Code's leverage is higher in TypeScript/React.** The existing 17,767-line
   client, every spec, every landmine comment, and preflight are JS/TS. A native
   session can grep the web client for how a screen behaves and port it. Swift work
   loses that adjacency and also loses `node tests/preflight.mjs` as the gate (checks
   12–14 walk `.ts/.tsx`; a Swift tree would need new checks in a new language).
5. **The four wanted iOS features are reachable from Expo, with caveats:**
   - *Haptics* — `expo-haptics`, trivial.
   - *Dynamic Type* — RN `Text` supports `allowFontScaling` (default on) and
     `maxFontSizeMultiplier`; but true text-style semantics (`.headline`,
     `.body`) and `@ScaledMetric` for spacing are not native — you get scaling,
     not the full system.
   - *Widgets and Live Activities* — **must be written in Swift/WidgetKit
     regardless of stack.** On Expo this means a config plugin adding a widget
     extension target (community modules such as `expo-widgets`/`react-native-widget-
     extension`/`expo-live-activity`, or a hand-rolled Expo Module with a
     WidgetKit target), Expo prebuild owning the Xcode project, and App Groups for
     shared state. It works, it is done in production apps, and it is the part of an
     Expo project most likely to break on each SDK upgrade — and this project is
     already on a downgraded SDK with a known Hermes regression and a pending
     56→57 upgrade.
6. **Expo Go got a bundle onto the phone in one morning with no signing.** The
   B1 gate was designed around that property; a Swift app cannot run at all without
   the signing step that just failed.
7. **OTA updates** (`expo-updates`, "Still open #3") let JS fixes ship without a
   store release — the property the Capacitor plan valued. Swift has no equivalent.

### The case for switching to Swift / SwiftUI in Xcode

1. **Everything that justified abandoning the wrapper is native-only.** D98's
   own reasons for going native were "scoring on a watch during the round, and a
   live match on the lock screen." Both are Swift: the Watch app is Swift by D98's
   plan; Live Activities are ActivityKit + WidgetKit + SwiftUI; widgets are WidgetKit
   + SwiftUI. On Expo, the RN layer becomes the *host* for the Swift code that
   delivers the headline features, and the state the Live Activity / widget / Watch
   needs (the round state model that B2 must design "separable from view code")
   has to cross a JS↔Swift bridge (App Group + a native module). On SwiftUI that
   state is one `Observable` model shared by the app, the widget extension, and the
   Watch via WatchConnectivity — no bridge, one language, one debugger.
2. **The phone's scope is small and well-bounded.** D98 keeps the wizard, draft,
   roster, ledger, month closes, founder desk OFF the phone. What's left — sign-in,
   Home hero/feed, post a round (stepper), live scoring for three games, the board
   with realtime, push, standings read + receipts — is roughly 10–15 screens over
   ~30 of the 156 RPCs. That is a size where "write it twice" (Swift phone, React
   desktop) is a real option, and where the shared-component argument for RN is
   weakest: the desktop wizard/draft/ledger screens have no phone twin anyway.
3. **Fewer moving parts for a solo builder.** The scaffold already carries
   `metro.config.js` workarounds, exact-pinned reanimated/worklets, a `react-dom`
   override for a package the phone never loads, an SDK downgrade to match Expo Go,
   a Hermes regression waiting on SDK 57, CocoaPods, prebuild, Hermes, the new
   architecture, and expo-router — and B5/widgets will add a dev client, EAS or
   local signing, config plugins, and an extension target. SwiftUI + Xcode +
   supabase-swift (official SDK: auth OTP `signInWithOTP`/`verifyOTP`, `rpc()`,
   Realtime v2, Keychain session storage built in) is one toolchain, one package
   manager (SPM), one upgrade cadence (yearly, with Xcode), and the signing problem
   that just failed is solved by picking a team in a dropdown.
4. **The iOS-native affordances the owner asked for are first-class, not
   approximations.** Dynamic Type via text styles and `@ScaledMetric`; haptics via
   `.sensoryFeedback`; `textContentType(.oneTimeCode)`; Keychain; App Intents;
   Live Activities with `ActivityKit` and push-to-update via APNs (the existing
   `push` Edge Function can send Live Activity pushes with a `liveactivity` push type
   — a small extension of `push/index.ts:146-173`); background tasks for B3's drain-
   on-resume; SwiftData/GRDB for the durable queue; `NavigationStack` deep links
   for the AASA `?claim=`/`?join=` routes. `theme.ts`'s admitted approximations
   (shadow radius halved, elevation invented) disappear.
5. **The shared layer is cheap to mirror because it is already generated.**
   `tools/build-tokens.mjs` emits CSS and TS from `tokens.json`; adding a
   `Tokens.swift` emitter is an afternoon. `contract.psv` → a Swift `enum Rpc` with
   `Codable` arg structs is a bigger generator but the same idea, and preflight can
   check the Swift artifact the same way check 10/11 check the TS ones. The four
   rules in `auth.ts`/`client.ts` (8 digits, no redirect, defer auth work, skew
   retry) are ~100 lines in Swift. What does NOT transfer: nothing else — because
   nothing else exists yet.
6. **Watch (Phase E) stops being a second project.** On RN the Watch is a Swift
   target bolted to an Expo-managed Xcode project (config-plugin territory again);
   on SwiftUI it is a second target in the same workspace sharing the same model
   package. Garmin (D98's aside) is the same either way — a server-side integration.
7. **Claude Code works well in Swift too**, and the local-session rule already
   makes native work Mac-only with Xcode installed ("that download is already
   running"). The web client stays the reference for *behaviour* regardless of the
   phone's language.

### What each path actually costs from here

- **Stay on Expo:** ~0 rework now. Real costs arrive at B5 (dev client + signing
  — the failed build is that step), at "widgets/Live Activities" (a Swift
  extension target inside an Expo project + a bridge for round state), at every SDK
  upgrade (56→57 is already owed), and at the Watch. Android and desktop reuse are
  the payoff — real only if Phase C and D happen on the timeline D98 implies.
- **Switch to SwiftUI:** throw away ~600 lines of scaffold (the ideas survive —
  chunked Keychain is built in, `theme.ts` becomes generated Swift), write two small
  generators (tokens, RPC contract), re-encode four rules, and re-derive the B1
  gate as "TestFlight/dev build on your iPhone" (signing first). Android becomes
  "not from this codebase" — an explicit reversal of one D98 benefit and a
  decision-log entry. Desktop rewrite shares only `packages/` (tokens/contract),
  not components — which is roughly what it would share anyway given the surface
  split.

### The honest bottom line
Expo is the *right* choice if the roadmap really is phone → Android → React desktop
sharing UI, and Live Activities/widgets/Watch are "nice, later." SwiftUI is the
*right* choice if the reason for a native app is the reason D98 gave — watch scoring
and a live match on the lock screen — and Android is a Year-2 question rather than
Phase C. The repo's own evidence leans toward the second reading: D98's stated
justification is native-only surface area, the gtm/runbook/CLAUDE.md never plan for
Android users, the phone's scope is deliberately small, and the Expo scaffold has
already spent most of its hours on toolchain friction rather than product. Either
way, the first thing to fix is identical: set the team in Xcode and get a signed
build onto the owner's iPhone — the gate B1 was written to prove.
