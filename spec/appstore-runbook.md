# App Store runbook — Cup Season v1.0

Growth/Launch lane · 2026-08-26 · the sequence, the owners, and the calls that
still need making. Companion to `spec/ios-wrapper-arc.md` (why the wrapper is
shaped this way) and `spec/appstore-launch-kit.md` (the listing copy itself).
This file is the ORDER; the kit is the CONTENT.

> **Amended 2026-08-26 by D98.** The Capacitor wrapper is abandoned; the phone
> app is Expo / React Native and iOS waits for it. **Phases 0, 1, 4 and 5 and
> all nine decision items below hold verbatim** — the portal work, the listing,
> the reviewer account, the pot posture and the privacy answers are all
> client-agnostic. **Phases 2 and 3 are superseded**: substitute the Expo build
> and device pass from `spec/native-arc.md`. D1 (iPad vs iPhone-only) now also
> governs the RN target.

**Where we are:** Apple Developer enrollment is live (Team ID `3F7BK4WVH8`),
the Mac has arrived, and every Windows-phase item W1–W7 is done. What is left
is three browser sessions in Apple's portals, one Xcode session, a device pass,
and a submission. Nothing in the app itself is blocking.

---

## The critical path

Each phase names its OWNER and its GATE — the observable fact that says the
phase is finished. Do not start a phase whose predecessor's gate is unmet;
every one of these gates exists because skipping it fails silently.

### Phase 0 · Deploy what is already built  · owner: Jerecho

Three deploys, three different systems. They are independent and all three are
needed before the Mac phase means anything.

1. **Client** — merge this branch to `main`. Netlify builds `main`, and Apple
   fetches the AASA from the LIVE domain. Until this merges, Associated Domains
   validation fails in Xcode and you will debug a link bug that is only a
   deploy.
2. **Database** — `supabase db push` (ships `20260826120000_unregister_device_token`).
3. **Edge function** — not needed. `push` is unchanged; only its secrets change,
   in Phase 1.

**GATE:** `curl -s https://cupseason.app/.well-known/apple-app-site-association`
returns the JSON with `3F7BK4WVH8` and a `content-type: application/json`
header. Check the header, not just the body — a wrong content-type is the
classic silent universal-links failure.

### Phase 1 · Apple portals  · owner: Jerecho · no Mac needed

1. **Identifiers → App IDs → `app.cupseason.ios`.** Enable **Push
   Notifications** and **Associated Domains**. The bundle id is frozen at first
   upload, so this is the last moment to change it.
2. **Keys → new key, APNs enabled.** Download the `.p8`. It downloads ONCE,
   ever — put it somewhere you will still have in a year. Then:
   ```
   supabase secrets set \
     APNS_P8="$(cat AuthKey_XXXXXXXXXX.p8)" \
     APNS_KEY_ID=XXXXXXXXXX \
     APNS_TEAM_ID=3F7BK4WVH8
   ```
   The APNs branch in `push/index.ts` is fully env-gated: it is a silent no-op
   until all three exist, and lights up the moment they do. Nothing to deploy.
3. **App Store Connect → new app.** Name, primary language, bundle id, SKU.
   Listing copy comes from `appstore-launch-kit.md` §1 verbatim — it is legal
   copy, not marketing copy, and the D39 pot posture is load-bearing.

**GATE:** the App ID shows both capabilities ticked, and
`supabase secrets list` shows three `APNS_*` names.

### Phase 2 · Xcode · owner: Jerecho + Claude

```
cd ios-wrapper
npm install
npx cap sync ios
open ios/App/App.xcodeproj
```

**Not `pod install`.** Capacitor 8.4.2 wired this project as Swift Package
Manager (`CapApp-SPM/Package.swift`, iOS 15 minimum). There is no Podfile.
Xcode resolves packages on open; give it a minute before the first build.

In Xcode, on the App target:
- **Signing & Capabilities** → team `3F7BK4WVH8`, automatic signing.
- **+ Capability → Push Notifications.** Writes `aps-environment` into a new
  `App.entitlements`.
- **+ Capability → Associated Domains** → `applinks:cupseason.app`.
- Confirm `PRODUCT_BUNDLE_IDENTIFIER` is `app.cupseason.ios`.

**GATE:** a clean build to a real device, and `App.entitlements` exists in the
repo with both entries. Commit it — Xcode creates it locally and it is easy to
leave untracked, which breaks the next machine that builds.

### Phase 3 · Device pass · owner: Jerecho

Everything here is a thing that works in a browser and can still fail in a
WKWebView. Run them on hardware, in this order:

| Check | Passes when | Fails silently as |
|---|---|---|
| Email OTP sign-in | 8-digit code arrives and autofills from Mail | code input capped at 6 |
| **Push** | toggle in Tour Card → iOS permission sheet → a real notification lands | permission granted, no token, nothing ever arrives |
| Universal links | `/?join=` from Messages opens the APP, not Safari | opens Safari (AASA not live, or entitlement missing) |
| **Scorecard scan** | camera opens from the scan button | app crashes at the picker (missing usage string) |
| Round photo | library picker opens and the photo attaches | same crash |
| Safe areas | nothing under the notch or home indicator | — |
| Share sheet | settlement card shares out | — |

Push is the one to test first and hardest — it is the Guideline 4.2 defense and
the piece with the most links in its chain (entitlement → AppDelegate forwarder
→ plugin → RPC → device_tokens row → APNs key → topic).

**GATE:** a notification from a real board post lands on the phone with the app
BACKGROUNDED. Verify the row exists first: `select count(*) from device_tokens`.

### Phase 4 · TestFlight · owner: Jerecho

Archive → upload → TestFlight. **Internal testing** (up to 100 people on your
own team, no beta review, available in minutes) is the right first stop.
**External testing** needs a Beta App Review and is only worth it if PIGL
exceeds the internal seat count — it will not.

**GATE:** three PIGL members on real phones, each having posted a round and
received a push, over at least one full weekend.

### Phase 5 · Submission · owner: Jerecho

- **Screenshots** — 6.9" iPhone is the only mandatory size; App Store Connect
  scales it down for smaller classes. See decision **D1** before you shoot,
  because iPad doubles this job.
- **Privacy nutrition labels** — see **D9**.
- **Age rating** — answer with no gambling flags of any kind. Expected 4+.
  See **D3** for why this question deserves care.
- **App Review notes** — reviewer credentials, plus the pre-emptive answers in
  the Rejection playbook below. Write them BEFORE you are rejected.
- **Export compliance** — already declared in Info.plist
  (`ITSAppUsesNonExemptEncryption = false`, correct for an HTTPS-only app), so
  the upload will stop asking.

---

## Decision tree

Nine calls. Each states the default, what it costs, and a recommendation.
The ones marked **BLOCKING** must be answered before the phase they sit in.

### D1 · iPad, or iPhone-only? **BLOCKING Phase 5** (and shapes Phase 3)

Today `TARGETED_DEVICE_FAMILY = "1,2"` — universal. That is the Capacitor
default, not a decision anyone made.

- **Ship universal** → App Store Connect demands a separate 13" iPad screenshot
  set, and Apple reviews on an iPad. Every layout that was designed for a phone
  gets judged on a 13" canvas. A dark hero and a three-tile home look thin
  stretched that wide; that is a 4.0/2.1 rejection risk, and it is one you
  cannot answer with an appeal, only with work.
- **Ship iPhone-only** (`TARGETED_DEVICE_FAMILY = "1"`) → one screenshot set,
  review happens on a phone, and iPad users still get the phone app. You can
  add iPad in any later release with no store friction.

**Recommendation: iPhone-only for v1.** The product is a phone product — you
post a round standing on a tee box. Nothing is lost and a whole QA surface
disappears. One line in the build settings.

### D2 · Subtitle: brand line, or keyword density?

The kit flags this and leaves it open. Name is `Cup Season: Golf Leagues`.

- `Run your golf season` (20/30) — the brand line from bible §5.
- `Seasons, handicaps & skins` (26/30) — indexes three more search terms.

Name + subtitle + keywords are the only search-indexed fields, and "golf"
already appears in the name, so the brand line spends its characters on
nothing searchable.

**Recommendation: the brand line at launch.** Discovery is not the channel —
the funnel is a claim link from a friend, foursome by foursome. The subtitle is
editable without review, so if organic search ever matters, change it then.

### D3 · The pot: how hard do you pre-empt the gambling question? **BLOCKING Phase 5**

This is the single most likely rejection, and it will arrive as Guideline
5.3.4 (real-money gaming) or a 1.4.3 flag from the age-rating questionnaire.

The facts are on your side and they are already canon: no wagering, no
deposits, no payouts, no contest run by Cup Season, no money moving through the
app. It is a ledger of a friend group's own pot, and D39 retired "never held"
in favour of exactly that framing.

- **Say nothing and answer if asked** → cheaper if it never comes up; a
  rejection costs a full review cycle (days).
- **Pre-empt in App Review notes** → costs a paragraph.

**Recommendation: pre-empt.** Put the D39 posture in the review notes verbatim
and point at the in-app ledger screen by name. A reviewer who reads "pot" with
no context will draw the wrong conclusion, and the appeal is slower than the
paragraph.

### D4 · Reviewer account: what state does the reviewer land in? **BLOCKING Phase 5**

W3 built the hidden password door for `reviewer@cupseason.app`. What has not
been decided is what that account SEES. An empty account is the worst possible
review: a reviewer who lands on "create your first league" cannot evaluate the
app and will reject on 2.1 for incomplete functionality.

Options: seed the reviewer into PIGL (real data, real names — real people's
rounds shown to a stranger), or into the sandbox league (`20260724150000`
built one), or a purpose-made demo league.

**Recommendation: the sandbox league, pre-seeded** with a season in progress,
a populated board, at least one settled game with a settlement card, and
standings that tap through to receipts. Real shape, no real people. Write the
walkthrough into the review notes as numbered steps — reviewers follow them.

### D5 · APNs environment

The `aps-environment` entitlement is `development` for device builds and
`production` for TestFlight and App Store builds; Xcode flips it automatically.
The server side is `APNS_SANDBOX` in Supabase secrets.

**Rule, not a decision:** set `APNS_SANDBOX=1` only while testing a
locally-signed build on a tethered device, and UNSET it before the first
TestFlight upload. A production token against the sandbox host fails as
`BadDeviceToken` — which the sender treats as a dead token and PRUNES, so the
symptom is "push worked yesterday and now silently does not."

### D6 · Does the iOS build show anything about money? **BLOCKING Phase 5**

D56 decided: visible model, no checkout, web only. The app has no purchase UI
and must never grow one — that is what keeps IAP's 30% and Guideline 3.1.1 out
of the conversation entirely.

The residual question is whether the iOS build shows subscription STATUS, and
whether anything links out to a web checkout.

**Recommendation: status only, and no outbound link.** A read-only "Founding
League — free forever" line is fine. A button that opens Safari to a payment
page is the exact pattern 3.1.1 polices; link-out entitlements exist now, but
applying for one to launch a free app is a self-inflicted wound. Season 1 is
free — there is nothing to sell in the binary.

### D7 · If review calls it a repackaged website (Guideline 4.2)

Not a decision to make now — a branch to have ready. The posture is already
built: remote-URL shell PLUS native touches (APNs, universal links, share
sheet, camera).

- **First response: appeal with the list.** Name the native integrations.
  Most 4.2 flags on remote-URL apps resolve here.
- **If it holds: bundle the client** into the shell (`webDir` mode, same
  `index.html`). The arc keeps that door open. The cost is real and permanent —
  every client change then needs a store release, so the "Netlify push ships
  the client" property dies.

**Do not pre-emptively bundle.** Take the appeal first; the remote-URL property
is worth one review cycle to defend.

### D8 · Version and build numbering

`MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1` today.

**Rule:** the iOS version is hand-set and has nothing to do with the web
version. CLAUDE.md's "never hand-edit the version" governs `__CS_VERSION__` in
`index.html`/`sw.js` — the build stamps those with the commit SHA. The two
numbering schemes are unrelated and must not be reconciled. Bump
`CURRENT_PROJECT_VERSION` on every upload; App Store Connect rejects a
duplicate build number.

### D9 · Privacy nutrition labels

Answer from what the app actually collects, and the answers are already
determinable: **Contact Info** (email, name) linked to identity · **User
Content** (photos, rounds, board posts) linked to identity · **Identifiers**
(device token) linked to identity · **Usage Data** (`client_events`,
`pilot_instrumentation`) linked to identity.

**Tracking: NO.** There is no third-party ad SDK, no data broker, no
cross-app tracking. Answering "yes" here triggers the App Tracking
Transparency prompt requirement for nothing.

Course lookups go to GolfCourseAPI through our own Edge Function with the key
held server-side, and results cache into our tables — the third party never
sees a user. That is not a data-collection disclosure.

---

## Rejection playbook

Write these into App Review notes before submitting, not after being rejected.

| If review says | Answer with |
|---|---|
| 5.3.4 real-money gaming | The D39 posture verbatim: no wagering, deposits, payouts, or house-run contest. The app keeps a ledger; money moves between friends. Point at the ledger screen by name. |
| 4.2 minimum functionality | The native list: APNs push, universal links, camera scan, share sheet, offline shell. Then D7. |
| 2.1 incomplete / cannot evaluate | The reviewer credentials and the numbered walkthrough from D4. Usually means the reviewer landed in an empty state. |
| 1.2 UGC safety | `report_content` and `set_mute` both ship and are reachable from the member sheet and any post; terms in `legal.html`. |
| 5.1.1(v) account deletion | In-app, `delete_account` RPC, reachable from the Tour Card — not a support-email flow. |
| 4.8 Sign in with Apple | Not applicable: the only sign-in is email OTP. SiWA is required only alongside a third-party login, and there is none. |

## Verification gates, in one list

Nothing here is optional; each one is a failure that is invisible until later.

1. `node tests/preflight.mjs` → 9/9, before every push in this arc.
2. `tests/db-checks.sql` → after any grant-touching push.
3. Live AASA returns JSON with the real Team ID **and** a JSON content-type.
4. A `device_tokens` row exists for a real phone before believing push works.
5. A backgrounded push lands from a real board post.
6. `APNS_SANDBOX` unset before the first TestFlight upload.
7. `App.entitlements` committed, not left untracked on the Mac.
