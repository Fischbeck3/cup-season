# iOS wrapper arc — Capacitor shell to the App Store (target mid-Aug)

*Decisions settled with the owner 2026-07-21: Capacitor wrapper built in this
repo · remote-URL mode (the shell loads cupseason.app, so client updates keep
riding Netlify pushes with no store re-release) · APNs push ships in v1 (it is
also the Guideline 4.2 defense) · a hidden password path for one reviewer
account · mute-a-member ships before submission (Guideline 1.2 wants
report + block; report_content exists, block does not).*

## Hardware reality

No Mac until ~early August. Work splits cleanly:

**Windows-now (this repo, immediately):**
- W1 · Scaffold `ios-wrapper/` — its own package.json (the app itself stays
  single-file; nothing node-ish leaks to the root), Capacitor core + CLI,
  `capacitor.config` in remote-URL mode, ios platform files generated.
- W2 · Universal links plumbing — `/.well-known/apple-app-site-association`
  served by Netlify (allowlist + JSON content-type header) so `/?claim` and
  `/?join` links open the app once the Team ID lands. Placeholder Team ID
  until Apple enrollment completes.
- W3 · Reviewer door — `signInWithPassword` path for exactly one
  `reviewer@cupseason.app` account (client branch, ~20 lines, invisible
  unless that email is entered; credentials go in App Review notes).
- W4 · Mute a member — `muted_members` (or profile-level mutes) migration +
  RPC + client filter on board/comment renders + a "Mute" row on the member
  sheet. Small, D37 grants, unblocks Guideline 1.2.
- W5 · APNs dormant plumbing — `device_tokens` table + `push` Edge Function
  branch (APNs HTTP/2 via token auth) behind a flag; wrapper registers
  tokens once it exists. Web push (VAPID) keeps serving installed-PWA users.
- W6 · Native asset prep — icon/splash source PNGs from `brand/` sized for
  `@capacitor/assets`, run when the platform exists.
- W7 · Apple Developer enrollment — the OWNER starts this NOW ($99, takes
  days, no Mac needed). Team ID unlocks W2's real AASA.

**Mac-later (~2-3 days once it arrives):**
- M1 · `npm install` + `npx cap sync ios`, Xcode build, signing, push
  entitlement + APNs key. **NOT `pod install`** — Capacitor 8.4.2 wired this
  project as SPM (`CapApp-SPM/Package.swift`, iOS 15 min). There is no Podfile
  and CocoaPods is not in the loop; Xcode resolves the packages on open.
- M2 · Device pass: OTP autofill, camera scan, universal links, share sheet,
  safe areas, the entry choreography on real hardware.
- M3 · TestFlight to the crew (PIGL = the beta cohort).
- M4 · App Store submission: screenshots per device class, privacy nutrition
  labels (email, name, city, photos, usage events), age rating, support URL,
  the kit's listing copy (D39 pot posture verbatim), reviewer credentials.

## Status — 2026-08-26

**W7 is DONE.** Team ID `3F7BK4WVH8`; the AASA carries it (and moved to the
modern `appIDs` + `components` form — the legacy `paths` form it shipped with
cannot match a query string, and every link this app routes is query-carried).
W1–W6 all stand. Preflight check 9 now asserts the AASA so a placeholder Team
ID can never pass green again.

**W5 was only half built** and now is whole: the server side (device_tokens,
`register_device_token`, the APNs sender) shipped in `20260722013000`, but
nothing on the device ever produced a token. Added since: the
`@capacitor/push-notifications` plugin, the two AppDelegate forwarders the
plugin needs (it does not swizzle them — without both, the JS `registration`
event never fires and nothing errors), the client's native branch on the
existing Notifications toggle, a boot-time token refresh, and
`unregister_device_token` (`20260826120000`) so "Disable on this device"
has something to call.

Remaining before submission: the Mac phase M1–M4, the three portal steps
(App ID + capabilities, APNs key → secrets, App Store Connect record), and
the decision items in `spec/appstore-runbook.md`.

## Standing guardrails

- Remote-URL wrapper + native touches (APNs, share sheet, haptics, universal
  links) is the 4.2 posture; if review balks, fallback = bundle the
  single-file client INTO the shell (same index.html, webDir mode) — keep
  that door open, no store re-release promise then.
- No purchase UI in the app ever (D56: web checkout only, iOS shows status)
  — no IAP 30%, no 3.1.1 fight.
- Bundle id `app.cupseason.ios` — changeable only until first upload.
- tests/preflight.mjs + db-checks.sql run before every push in this arc.

## Sequence

W1+W2 scaffold (today) → W3 reviewer door → W4 mute → W5 APNs plumbing →
[Mac arrives] → M1-M4. Owner parallel-tracks W7 enrollment immediately.
