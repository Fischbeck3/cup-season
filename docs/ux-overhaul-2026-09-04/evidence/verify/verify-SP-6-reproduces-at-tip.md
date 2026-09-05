# Verify SP-6 · lens "reproduces-at-tip" · tip 3bba87e · 2026-09-04

Verdict: **HOLDS** (with corrections below). Every behavioural claim was opened in the shipping phone client first, then the web; prod facts re-queried read-only via `supabase db query --linked`.

## 1 · The phone's first run (cold) — SAW

| Claim | Evidence at tip | Status |
|---|---|---|
| Door is email-only, no league-code door | `DoorView.swift:33-37` stages are `email/code/password` only; `emailStage` `:91-114`; `codeStage` `:116-159`. No field reads a league code. Web has "I have a league code" + `#joinCode` at `index.html:2811-2814`. | confirmed |
| 8-digit code | `DoorView.swift:118,137` (`AuthRules.otpLength`, auto-verify on completion) | confirmed |
| Card = three steps, marker required with no default, handle required | `CardGateView.swift:54-58` (steps 0/1/2), `:3` "required, no default", `:210-218` (name+handle regex gate, `guard marker != nil`), `:225-234` save = `set_handle` then `set_profile`. Gate condition `Models.swift:244-249` `needsCard` = marker OR handle empty; `SessionStore.swift:92-93`. | confirmed |
| Fourteen in-joke markers | 14 `CSMarker(key:)` in CSDesign | confirmed |
| "changes once every 60 days" / "Know your number? · Starter index · GHIN · USGA record" | `CardGateView.swift:106`, `:81`, `:171-176` | confirmed |
| Orientation "Four places. Two ways to play." + three doors + pinned "Take me in" | `OrientationScreen.swift:46-56` copy; `:138` `LeaguelessDoors` (three doors `LeaguelessDoors.swift:28-30`); `:143,176-191` pinned foot. Shown from `RootView.swift:37-40,62-70` via `OrientedFlag.take` `OrientationScreen.swift:85-91` — only when memberships, events and rounds are all empty and no join/claim intent is pending. | confirmed |
| Push ask over the very first Home | `CardGateView.swift:238` `PushAsk.shared.request(.cardSaved)` → `MainTabView.swift:330` `.task(id: ask.pending) { await drainAsk() }`, `:335` `.sheet(item: $ask.presented)`; `drainAsk` `:444-446`; `PushAskPolicy.swift:29-33` fires on any undetermined status. The orientation is shown INSTEAD of `MainTabView` (`RootView.swift:37-42`), so the drain runs the moment the tabs first mount. Sheet copy "A round lands on the board. A duel is closing. The table moves." `PushAsk.swift:88`. | confirmed |
| Never asks who you play with (phone) | `OrientationScreen.swift:9-13` "the phone has no crew step"; no equivalent of web `#obCrew` `index.html:2859-2878` anywhere in `apps/ios`. | confirmed |
| Never asks what golf you play (either client) | `contract.psv:274` `set_profile(p_name, p_city, p_home, p_index, p_marker, p_ghin, p_photo_path)`; grep for any golf-style field in both clients: none. | confirmed |
| Sign in with Apple built but flag-closed | `DoorView.swift:104-110` renders only if `flags.appleSignIn`; `DoorFlags.swift:43-50` fails closed; prod `app_flags.ios = {"min_build":0,"note":…}` — no `apple_sign_in` key (queried 2026-09-04). `door_flags` RPC exists (`contract.psv:130`) but returns no such key. | confirmed |

Surface count (Forge/email → code → card ×3 → orientation → Home → push sheet = 8) is the reader's count (FR §2) and matches the code path above.

## 2 · The invited joiner (phone) — SAW

- **Link stored only by `onOpenURL`**: `CupSeasonApp.swift:35` is the only `JoinIntent.store` call site (grep). No Smart App Banner `app-argument` in `index.html`, no `NSUserActivity` handler. → an App Store "Open" after a fresh install carries no code. (INFER: by construction; not runtime-tested.)
- **Door and card never read `JoinIntent`**: `RootView.swift:28-33` (`.signedOut` checks only `ClaimIntent`), `DoorView.swift` and `CardGateView.swift` contain no `JoinIntent` reference (grep: only `RootView:43`, `OrientationScreen:88`, `JoinLeagueFlow:109`, `Growth.swift:56`).
- **Orientation IS skipped for the invitee** (`OrientationScreen.swift:88-89`) — D116 §3 built on the phone. First acknowledgement of the invite is the sheet over an already-painted Home: `RootView.swift:43` `onAppear { pendingJoin = j.code; JoinIntent.clear() }` → `:46-48` `JoinLeagueFlow(code:)` → auto `go()` `JoinLeagueFlow.swift:49` → "You're invited to X." `:41`.
- **Covenant = four rows**: `JoinLeagueFlow.swift:135-138` BUY-IN · PRESET · PARTICIPATION FLOOR · FINISH; `Covenant.init` reads only name/buyin_cents/preset/floor/finish `JoinLeague.swift:67-74`; `$0 → nil` `:104` (web `index.html:17705`). The live RPC `join_covenant_info` (`20260830300000_join_window.sql:236-256`, NOT redefined by `20260901220000` — that file only mentions it in a comment) returns name, buyin_cents, preset, floor, finish, **structure, has_pay_note, buy_in_due_on, phase**. Pro, roster, dates are absent from the RPC (D115 unbuilt); the pay path (`has_pay_note`/`buy_in_due_on`) is returned and discarded by both clients (web renders the same four rows `:17706-17712`).
- **"Not now"**: `JoinLeagueFlow.swift:51` `onNo: { vm.covenant = nil }` → back to the "Join a league" sheet with the code preset, the invite line and a Join button (`:34-42`); Join re-runs `go()` and re-raises the covenant. **Cancel/swipe** (`:48`, `RootView.swift:46` `sheet(item:)` → nil) loses it because `JoinIntent.clear()` already ran at `RootView.swift:43`. No "Invited · REVIEW" state anywhere (grep `Invited`/`cs_invite_declined`: none in either client).
- **Home one-tap Accept without covenant**: `InvitesBanner.swift:53` Accept → `:84-90` `respond` → `respondInvite` → membership; server `respond_invite` (`20260830300000:187-205`) inserts `league_members` after `_join_gate` only — no stake disclosure on this path. `InvitesBanner` sits on Home `HomeView.swift:50`.
- **Welcome**: `JoinLeagueFlow.swift:181-207` — "THREE THINGS TO KNOW", "Who else plays with you? Growing the league isn't the Pro's chore — any member's link works." + ShareLink; no roster, no Done (dismiss = drag `:213`; `onDismiss` fires `onJoined` `:53`).
- INFER (not runtime-tested): on an invited first run both the `.cardSaved` push ask and RootView's join sheet are queued on the same first Home; `drainAsk` checks `presenter.anythingUp` (`Presenter.swift:43-46`) which does NOT include RootView's own `pendingJoin` sheet, so the two race for the one presentation slot.

## 3 · The web at tip — SAW

- Door has a code box (`:2811-2814`); the link path surfaces the league on the door at boot: `safeBoot` `index.html:20452-20461` "You're invited to {name}. Sign in to review the league before you join." (typed-code path `:17751-17753`).
- Orientation is shown to invitees too (`:14980-14983` — gated only on `cs_oriented`); only the crew step skips them (`:15006-15010`). So D116 §3 is built on the phone, not the web ("half-built" is correct).
- Crew step `#obCrew` `:2859-2878` is D151's step, wired at `continueAfterCard` `:15006-15015`; telemetry via `qaEvent` `:6898-6903` (no-ops when `!window.sb`; `window.sb = sb` at `:14786`).
- Decline keeps the code (`:20033-20036`, `:20105-20110`, toast "the invite is still here when you're ready") but Home renders "League · None yet · JOIN OR START" (`:11043-11044`); the kept code re-fires the same covenant at the next `boot()` (`:20026-20031`). A loop, not a REVIEW state.

## 4 · Prod (read-only, 2026-09-04)

- `client_events`: orientation_shown **5** (all 2026-09-02), orientation_done **0**, covenant_declined **0**, crew_step_shown/done **0**, push_prompt_shown **1** (2026-08-28), push_prompt_declined 0.
- `app_flags.ios` = `{min_build: 0, note: …}` — no `apple_sign_in`.
- Profiles with marker AND handle: **29**; of those **11** have no `league_members` row; **10** of those 11 have no `rounds` row. (Test/sandbox aliases not excluded.)
- INFER: "shown 5 / done 0" cannot be read as "nobody took a door" — the five may be the DEBUG hatch `-cs_dev_open orientation` (`OrientationScreen.swift:98-104`), or `leave()`'s insert may be lost when `done()` swaps the view; the counts alone do not say.

## 5 · Decision status (SAW in spec/decision-log.md)

- D115 `:4182` — RPC lacks pro/roster/dates at tip → unbuilt. D116 `:4192` — §1 built on phone (every path gates on stake except InvitesBanner), §2 unbuilt both, §3 built phone only. D117 `:4202` "PROPOSED — owner's call" → unbuilt. D151 `:4588` — crew step built web only. D136 Q-07 `:4422` "Contact invites: **not scheduled**" (not "declined").
