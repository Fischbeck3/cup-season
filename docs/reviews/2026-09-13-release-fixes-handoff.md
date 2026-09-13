# Release fixes — handoff to Codex, 2026-09-13

Branch: `claude/release-fixes-2026-09-13`, worktree `~/cup-season-release-fixes`.
Baseline: `1ef0dc6` (Codex's merge of the planning docs `2f51b45` with the
activation handoff `b5b1bab`). Packet: the six Codex review findings in the
session brief, each reproduced on this branch before it was fixed.

**Everything below is built and committed. Nothing is deployed, pushed or
merged.** Four migrations are written and proven on a disposable database only.
Codex owns integration, device/browser QA, the generator run and every live
deployment.

## The commits

| Commit | Checkpoint |
|---|---|
| `dce0970` | Posting · one ordinary round, and the guarantees the first cut broke (finding 1) |
| `96657a0` | Joining and setup · the terms on every door, and one league per Start (findings 2, 3, 5) |
| `589812d` | Month · the pulse says who joined this month and who still has a bye (finding 4) |
| final | this handoff, the inbox, and the run-it-back guard on both clients (finding 6's one bounded fix) |

## Decisions

`D350` amended to BUILT · `D351` amended to BUILT · `D353` covenant contract
(new) · `D354` pulse contract (new) · `D355` create identity (new). All in
`spec/decision-log.md`, each stating identity, ownership, replay, conflicting
body, old client, old server and grants **before** the wiring. The §14.3 /
D212 Final conflict stays flagged in D346 and is untouched: nothing here
touches `enter_cup_final`, `v_rounds_ranked`, `cup_points` or `close_season`.

## Finding by finding

### 1 · Ordinary posting idempotency — fixed, both clients

Reproduced on the phone: `pending.payload = payload` replaced the frozen
payload on retry; `try?` swallowed the disk read and write; accepted recovery
cleared `ordinaryRequest` and left the card; `PostDraft.isFresh` aged a sent
draft out after 24h. On the web: one unowned `cs_post_request` key with no
envelope; the payload recomputed on retry; the accepted early-return cleared
the key and left the form.

Built:
- `OrdinaryPost.run` (Kit, `Post/OrdinaryPost.swift`) with every port injected:
  read → finished? → same card? replay verbatim : ask `round_post_status` →
  fresh? upload, freeze, **save before the call** → post → record acceptance.
  `PostRequestStore` keeps the id owner-scoped outside the draft.
- `PostRoundModel.submit` uses it; `finishAccepted` / `clearAfterAccepted` is
  the one place the form is put down (normal post and recovery alike). Account
  switch is named, not silent. "Start over" no longer clears the id.
- Web: `postRequestKey(uid)`, the frozen envelope on the record, pure
  `postRequestPlan` (finish / replay / resolve / fresh), `round_post_status`
  on resolve, one `clearPostComposerAfterPost`, no write → no network.
- **The old-server fallback is removed on both clients.** A missing
  `post_round_once` / `round_post_status` is told to the golfer; the draft and
  the id stay; nothing routes through `post_round` or a direct insert.

### 2 · Invitation terms on every door — fixed, both clients

Reproduced: `InvitesBanner` rendered by nothing; `openTerms` read
`leagues.code` (refused to an invitee); "Not now" wrote `declined`; Home's
"See the terms" opened a season page the invitee cannot read; the web's
`covenantGateForInvite` returned `'skew'` on a null answer and then accepted;
a warm `?join=` link did nothing until a cold start.

Built: `JoinService.covenantForInvite` (terms / not a door / not available,
by invitation id; `covenantForLeague` deleted); the list on **Compete** with
"See the terms" · "Decline"; `InviteTermsSheet` from Home carrying the
invitation id parsed from the item key (`HomeDispatch.HomeInviteKey`);
fail-closed on a missing function on both clients; "Joined ✓" only on
membership proof (the container arriving); `.csJoinCodePending` + the
identity-keyed task in `RootView`, gated on `pendingJoin == nil`.

### 3 · The covenant discloses the allowance and the whole rule — fixed

`20261029090000`: `handicap_allowance` and a real `every_round_counts` in the
signed-in block; `join_covenant_for_invite` delegates to the code door. Both
clients: "… best three a month count, two a month keeps you in, 95 percent of
your index." / "every round counts". Dates and finish were already said. Anon
shape unchanged, proven by the migration's self-check and the database test.

### 4 · Join-month waiver and auto-bye — exposed, not inferred

`20261030090000`: `league_pulse` gains `joined_this_month` and `bye_available`,
computed exactly as `close_month` decides them. `close_month` untouched.
Both clients say the waiver only off the row and name the bye only while a
minimum is owed; an older payload claims neither. **Product choice
surfaced:** the bye is a season bye (one, any month); a per-month variant
would be its own decision. **Honest gap:** `native_home`'s `pulse` object does
not carry the two facts, so Home's month row stays silent on them; the season
page and the desk carry them. In the inbox.

### 5 · Ambiguous create — durable identity and server replay

`20261028090000`: `create_league_once(p_request_id, p_name, p_code)` wraps
`create_league` unchanged with an advisory lock and a private receipt; replay
returns the original league with `replayed: true`; a conflicting body mints
nothing; a refusal leaves no receipt. Phone: `PendingCreate` (owner-scoped,
`WizardDials` now `Codable` — explicit Unlimited, off-ladder exact cap, chosen
squads, pay note, invitees all survive), written before the create, cleared
only on lock or an out-loud discard (the wizard's close asks). Web: the same
record per golfer. No fallback to `create_league`.

### 6 · Events and Run it back — audited, one bounded fix

Read `enter_major`, the event arm of `respond_invite`, `major_contender`,
`MajorRoomView`'s primary, `RunItBackCard` and both web run-backs. Entry is
gated (no entry after the horn or on a settled Major; league members only
for attached Majors), eligibility is the established index (exhibition
otherwise), results rank contenders only. Run it back is role-gated (D243).
One bounded fix landed: a run-it-back on either client no longer resumes an
unrelated unfinished create (it mints its own request). Two findings are in
the inbox, not built: a Major invitation is titled "Ryder invite" and its
Accept shows no buy-in (`my_invites` carries neither the event kind nor the
stake — a contract, not a copy fix), and the rematch prefills live in memory
only.

## Migrations — written, proven on a disposable database, NOT deployed

| File | What |
|---|---|
| `20261027090000_a_post_can_be_asked_about.sql` | `round_post_status(uuid)` — read-only, owner-scoped, execute to `authenticated` |
| `20261028090000_one_league_however_many_times_start_is_pressed.sql` | `create_league_once(uuid, text, text)` + private receipts |
| `20261029090000_the_covenant_says_the_allowance.sql` | `join_covenant_info` + `join_covenant_for_invite` (same signatures, grants restated) |
| `20261030090000_the_pulse_says_who_joined_and_who_has_a_bye.sql` | `league_pulse(uuid)` DROP + CREATE with two more columns, grants restated |

Plus the two from the activation sprint, still undeployed: `20261025090000`,
`20261026090000`.

**Deploy order matters now, and this is the one thing that changed posture.**
Both clients are fail-closed on a missing `post_round_once`,
`round_post_status`, `create_league_once` and `join_covenant_for_invite`: they
say the server is not ready and write nothing, rather than falling back to a
function that cannot deduplicate. So `supabase db push` ships **before** the
Netlify push and the TestFlight build. A client shipped first cannot post an
ordinary round, start a season, or accept a league invitation until the push
lands — by design, and Codex owns verifying the order at release.

## Generated files — owed to the generator, not hand-edited

`packages/db/contract.psv` and `Generated/Rpc.swift` are untouched. Four
calls are hand-declared in the Kit while the migrations await their contract
refresh (the documented exception preflight 17 tolerates and still checks
grants on): `RoundPostStatusCall`, `JoinCovenantForInviteCall`,
`CreateLeagueOnceCall`, `LeaguePulseCall`. After the push, `node
tools/build-db.mjs` regenerates; `LeagueRoomModel.pulse` is typed on the
hand-declared `LeaguePulseRow` and can move to `Rpc.league_pulse.Row` then.

## Evidence — everything below was actually run

| Check | Result |
|---|---|
| `CupSeasonKit` full suite, iPhone 17 Pro simulator (`xcodebuild test -scheme CupSeasonKit`) | **TEST SUCCEEDED**, every suite green, including the new `OrdinaryPostTests` (14), `CovenantAllowanceTests` (3), `PendingCreateTests` (3), `InviteLandedTests` (1), `MonthWaiverCopyTests` (5) |
| `CupSeasonTests` (app target), same destination | **TEST SUCCEEDED** |
| `CupSeason` app build, same destination, after the final edit | **BUILD SUCCEEDED** (XcodeGen regenerated first) |
| `node tests/release-fixes-database.mjs` — disposable PostgreSQL 17.11 (`initdb` in a temp dir, port 55438), all four migrations applied in order over the prior covenant/pulse/idempotent-rounds producers | **ALL PASS** — status null before / verbatim after / owner-scoped / never posts / anon refused · create replay = same league / conflicting body mints nothing / owner-scoped / refusal leaves no receipt / receipts private · covenant allowance + cap + every_round_counts + dates + weeks / invite door == code door / anon unchanged / no code · pulse joined_this_month + bye_available / old columns intact / grants restated |
| `node tests/post-request.test.mjs` | **13 passed, 0 failed** |
| `npm run preflight` | **0 failures, 2 warnings** — `rpc pending deploy: round_post_status` (expected, owed) and `acorn / eslint-scope not installed` (the free-identifier check did not run; `npm ci` then rerun) |
| `node tools/web-verify.mjs --widths 1440,390,320` | reported no horizontal overflow at any width and 0 console messages — **but see the caveat below** |
| `node tests/homefold.test.mjs` | **29 passed, 1 failed** — the failure ("Up next" vs "Coming up") is on the baseline `1ef0dc6`, untouched here, in the inbox |

**Environment actually used.** Local Mac session, non-interactive. iOS
Simulator, iPhone 17 Pro. PostgreSQL 17.11 from `/opt/homebrew/opt/postgresql@17`
in a throwaway data directory; production and the shared sandbox on port 5470
were never used (the sandbox needed an approval this session could not give).

**Web-verify caveat, stated plainly.** The walk loaded `127.0.0.1:8791` and
passed, but this session's own static server could not be started (it needed
an approval), so something else was serving that port and I could not confirm
it was this branch's `index.html`. Treat the browser walk as **not verified
here**; rerun it from this worktree with `python -m http.server 8791` before
trusting it.

**Not run, and not counted.** Actual taps on a device or simulator through the
composer's retry, the Compete invitations list, the Home terms door, the wizard's
resume-after-kill and the discard dialog; dark and light; AX3; an offline run;
the desk in a real browser with service workers cleared; and any live server.
These are Codex's independent integration QA and they are why this handoff
does not call the fixes verified end to end.

## What Codex should rerun

```
cd ~/cup-season-release-fixes
npm ci && npm run preflight
node tests/post-request.test.mjs
node tests/release-fixes-database.mjs
python -m http.server 8791 &   # then
node tools/web-verify.mjs --url 'http://127.0.0.1:8791/?exit' --widths 1440,390,320
(cd apps/ios && xcodegen generate)
(cd apps/ios/Packages/CupSeasonKit && xcodebuild test -scheme CupSeasonKit \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
(cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
```

Then, on a device, the four journeys the tests cannot tap: post with the
network cut mid-call and press Post again (one round, same id); accept an
invitation from Home and from Compete, decline one, and try both against a
database without `join_covenant_for_invite` (nothing accepted); kill the app
between the create and the lock, reopen "Start a season" (same league, same
choices, the X asks); and a mid-month joiner's season page (no figure to chase).

## Handoff

Branch: `claude/release-fixes-2026-09-13`.
Goal: build the six validated review findings and ship them behind Codex's integration.
What changed: see the four commits above.
Files changed: 31 across the three checkpoints (`git diff --stat 1ef0dc6 HEAD`), plus this document, the inbox and the run-it-back guard in the final commit.
Verification run: the table above, exactly as stated.
Database deploy owed: six migrations (`20261025` – `20261030`), **before** any client.
Edge deploy owed: none.
Client deploy owed: `index.html` on the normal Netlify path after the push; the iOS build after `build-db.mjs` and Codex's device QA.
Open questions / risks: deploy order is now load-bearing; `native_home` pulse gap; the Major-invitation contract; the baseline `homefold` failure; the §14.3 / D212 Final conflict (owner).
Recommended next step: Codex reviews the exact commits, runs the device journeys, regenerates the contract after the push, and integrates.
