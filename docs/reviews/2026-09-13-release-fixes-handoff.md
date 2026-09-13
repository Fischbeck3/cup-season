# Release fixes — handoff to Codex, 2026-09-13 (second pass)

Branch: `claude/release-fixes-2026-09-13`, worktree `~/cup-season-release-fixes`.
Baseline: `1ef0dc6`. First pass: `dce0970` · `96657a0` · `589812d` · `f905573`.
Second pass (this document): one further commit on top, fixing the blockers
Codex's independent review of `f905573` found.

**Everything below is built and committed. Nothing is deployed, pushed or
merged.** Six migrations are written and proven on a disposable database only.
Codex owns integration, device/browser QA, the generator run and every live
deployment. Nothing in widget, Live Activity, `CupSeasonApp`'s widget or
Home-link lifecycle, `SessionStore`'s snapshot lifecycle or release tooling was
touched in the second pass.

## What Codex found, and what changed

### P0 · the posting identity could still mint a second round — fixed

The first pass asked `round_post_status` on an edited card and, on NULL,
minted a fresh id and posted at once. NULL does not prove the first request
will never commit; a status read cannot protect against a request that has
not arrived yet, whatever lock it takes. And the "earlier posted" path kept
the edited card with the id cleared, so the next tap duplicated the same golf.

**As built now: one intent, one identity, never rotated by the client.** An
edited card is an AMENDMENT under the same id. `post_round_once` already
serialises two bodies under one id with its advisory lock and receipt — the
first to commit wins, the second is refused ("already has a different
scorecard") and writes nothing. On that refusal the client asks
`round_post_status` which round DID land, finishes the intent with it and
opens that round's receipt; the edit is the existing correction path (delete
the round, post again). A definite server refusal keeps the id and the
corrected card posts under it, so a validation rejection is no dead end;
transport ambiguity keeps the id and replays the same envelope. Only a finished
intent releases the id. There is no plan on either client that mints a second
id for the same intent. `OrdinaryPost.Outcome.staleRequest` is gone.

**Proven with real RPC concurrency** on PostgreSQL 17 against the actual
`post_round_once` (`tests/release-fixes-database.mjs`): a slow first request
with the amendment arriving in flight → one round, amendment refused; the
amendment landing first and the delayed original arriving after → one round,
original refused; the same body twice concurrently → one round, one answer;
a validation refusal → no receipt, the corrected card posts once under the
same id. Client ports are proven in `OrdinaryPostTests` (19 tests): replay,
accepted recovery over an edited card, amendment wins, amendment refused with
a readable / unreadable / null status (all keep the id), partner change as
amendment, definite refusal then correction under the same id, transport vs
verdict, missing function, owner scoping, unreadable pointer, corrupt envelope.

### P0 · records and drafts abandoned an unresolved identity — fixed

- Web `postRequestRead` returns `{unreadable:true}` on a storage read failure
  or a record that cannot be parsed, never deletes it, and `postRequestPlan`
  returns `stop` for it (nothing is sent, the golfer is told). A record with
  an id and no envelope keeps its id (`amend`), never `fresh`.
- Phone `PostRequestStore.read` is three-valued (`none` / `pending` /
  `unreadable`); the composer refuses to post over an unreadable pointer
  rather than mint. `OfflinePostDisk.read` already threw on a corrupt
  envelope; that is now a test.
- Web `postRequestAccepted` reports a write failure instead of swallowing it;
  the composer says so ("don't post it again"). The whole post tail is wrapped
  so the form is cleared and the id released whatever the narration does.
- Web draft: `cs_post_draft.<uid>` with an `owner` field. A legacy unowned
  draft under the old key is offered once out loud (`confirm`) and adopted
  only on a yes; it is never shown to another account and never deleted
  silently; a foreign-owned draft is left alone. A draft behind a pending post
  attempt never ages out (`postDraftDecision`, pure, tested).

### P1 · Home's pulse lacked the month facts — fixed

`20261101090000` patches `native_home`'s four-key pulse object into six keys
by reading the live body from the catalogue and replacing one unique
substring (raises if absent, duplicated, or missing after execute — the D161
pattern). `Me.Pulse` decodes `joined_this_month` / `bye_available`;
`SeasonFacts.footRule` / `monthRow` and `HomeFallbackItems.floorItem` say the
waiver and stand the alarm down only when the row says so; an older payload
changes nothing. `HomeMonthFactsTests` covers Home's own producers. The desk's
Home floor rung reads the same row.

### P1 · a Major invitation titled "Ryder" and accepted without its stake — fixed

`20261031090000` grows `my_invites` with `event_kind` and `buy_in` (DROP +
CREATE, same signature, grants restated, old columns unchanged;
`native_home` embeds the rows verbatim). Both clients: every event
invitation's primary control is **See the terms** — what it is in the
product's own words (a Ryder or a Major), the first tee, the stake above $0
with the ledger line, Accept / Not now; Decline stays one tap. Fail-closed: a
payload that does not say what it is (older server, unknown kind) gets no
terms and no door. Titles come from the event's own kind; an unnamed one is
"Invite". D356 records the contract. No money is handled or moved.

### P1 · the run-it-back guard minted a fresh id — removed

The guard that skipped the durable record whenever a run-it-back was in
progress was inert and wrong: the league's run-it-back is `run_it_back` on
the server (D243) and never comes through this create; `_runItBack` and
`runBack` are set by nothing. There is one record per golfer and it is always
resumed, so a retry never mints a second id. The Ryder / Major rematch
prefills carry no request identity and stay in the inbox.

## Migrations — written, proven on a disposable database, NOT deployed

| File | What |
|---|---|
| `20261027090000_a_post_can_be_asked_about.sql` | `round_post_status(uuid)` — read-only, owner-scoped |
| `20261028090000_one_league_however_many_times_start_is_pressed.sql` | `create_league_once(uuid, text, text)` + private receipts |
| `20261029090000_the_covenant_says_the_allowance.sql` | `join_covenant_info` + `join_covenant_for_invite` |
| `20261030090000_the_pulse_says_who_joined_and_who_has_a_bye.sql` | `league_pulse(uuid)` DROP + CREATE, two columns |
| `20261031090000_an_invitation_says_what_it_is.sql` | `my_invites()` DROP + CREATE, `event_kind` + `buy_in` |
| `20261101090000_home_carries_the_month_facts.sql` | `native_home` pulse object patched in place |

Plus the two from the activation sprint: `20261025090000`, `20261026090000`.
Order matters: `20261030` before `20261101` (the patch reads the new columns).

**Deploy order is load-bearing.** Both clients are fail-closed on a missing
`post_round_once`, `round_post_status`, `create_league_once`,
`join_covenant_for_invite`, and on a `my_invites` row without `event_kind`:
they say the server is not ready and write nothing. `supabase db push` ships
before the Netlify push and the TestFlight build, or shipped clients cannot
post an ordinary round, start a season, or accept any invitation.

## Generated files — owed to the generator

`packages/db/contract.psv` and `Generated/Rpc.swift` are untouched. Hand-declared
in the Kit until the contract refresh: `RoundPostStatusCall`,
`JoinCovenantForInviteCall`, `CreateLeagueOnceCall`, `LeaguePulseCall`,
`MyInvitesCall`. After the push, `node tools/build-db.mjs`.

## Evidence — everything below was actually run, second pass

| Check | Result |
|---|---|
| `CupSeasonKit` full suite, iPhone 17 Pro simulator | **TEST SUCCEEDED** (every suite; new: `OrdinaryPostTests` 19, `EventInviteTermsTests` 4, `HomeMonthFactsTests` 2; `PeopleScheduleTests` re-pinned to the event's own kind) |
| `CupSeason` app build, same destination, after the last edit | **BUILD SUCCEEDED** |
| `CupSeasonTests` (app target), same destination | **TEST SUCCEEDED** |
| `node tests/release-fixes-database.mjs` — disposable PostgreSQL 17.11, all six migrations over the prior producers, **real concurrency** via parallel `psql` connections | **ALL PASS** (nine groups, listed above) |
| `node tests/post-request.test.mjs` | **29 passed, 0 failed** (request plans incl. `stop`/`amend`, draft ownership incl. legacy offer and pending-request no-expiry, event terms, titles) |
| `npm run preflight` | **0 failures, 1 warning** (`acorn / eslint-scope not installed`: the free-identifier check did not run; `npm ci` then rerun) |
| `node tools/web-verify.mjs --url http://127.0.0.1:8794/?exit --widths 1440,390,320` against **this worktree's own server** (`node tools/serve-local.mjs 8794`, new, dev-only) | **PASS** — no horizontal overflow at any width; console clean but for the known GoTrue deprecation warning and the boot log line |
| `node tests/homefold.test.mjs` | **29 passed, 1 failed** — baseline failure at `1ef0dc6`, untouched |

**Environment.** Local Mac session, non-interactive. iOS Simulator, iPhone 17
Pro. PostgreSQL 17.11 in a throwaway data directory; production and the shared
sandbox on port 5470 were never used. Port 8793 was left alone (Codex's).

**Not run, and not counted.** Actual taps on a device through the composer's
amend-and-refuse recovery, the receipt opening after recovery, the Compete
invitations list with a Major, the Home terms sheet, the web's legacy-draft
prompt, the wizard's resume-after-kill; dark and light; AX3; offline; any live
server. These are Codex's integration QA.

## What Codex should rerun and tap

```
cd ~/cup-season-release-fixes
npm ci && npm run preflight
node tests/post-request.test.mjs
node tests/release-fixes-database.mjs
node tools/serve-local.mjs 8794 300 &   # then
node tools/web-verify.mjs --url 'http://127.0.0.1:8794/?exit' --widths 1440,390,320
(cd apps/ios && xcodegen generate)
(cd apps/ios/Packages/CupSeasonKit && xcodebuild test -scheme CupSeasonKit \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
(cd apps/ios && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason \
   -destination 'platform=iOS Simulator,name=iPhone 17 Pro')
```

On a device: post with the network cut mid-call, edit the gross, press Post
(same id; if the first landed, the receipt of THAT round opens and the form is
finished; if not, the edited card posts once); type a bad rating, get refused,
fix it, post (same id, one round); accept a Major invitation from Compete and
from Home and read the stake before the tap; try an event invitation against
a database without `20261031` (no terms, nothing accepted); kill the app
between the create and the lock and reopen "Start a season" (same league, same
choices); a mid-month joiner's Home month row and season page (no figure to
chase, no alarm).

## Remaining constraints, stated plainly

- Deploy order: database first, six migrations, `20261030` before `20261101`.
- The amended-request contract relies on `post_round_once`'s existing lock and
  receipt; no migration changed it. Its refusal is matched on the words
  "different scorecard" on both clients.
- An amendment that is refused loses the golfer's edit by design: the round
  the server holds is the one shown, and a change is a delete-and-repost.
- The Ryder / Major rematch prefills still carry no request identity (inbox).
- `tests/homefold.test.mjs` fails on the baseline (inbox).
- The §14.3 / D212 Final conflict is untouched and stays the owner's.

## Handoff

Branch: `claude/release-fixes-2026-09-13`.
Goal: fix the release blockers Codex found in `f905573`, with proof.
What changed: the amended-request contract on both clients; record and draft durability; Home's pulse facts; the event-invitation terms contract; the run-it-back guard.
Files changed: see the final commit.
Verification run: the table above.
Database deploy owed: eight migrations (`20261025` – `20261101`), **before** any client.
Edge deploy owed: none.
Client deploy owed: `index.html` after the push; the iOS build after `build-db.mjs` and device QA.
Open questions / risks: deploy order; the lost-edit-on-refusal tradeoff; rematch identity; the baseline `homefold` failure; the Final conflict.
Recommended next step: Codex reviews the final commit, taps the journeys above, regenerates the contract after the push, and integrates.
