# Theme 1 — The organizer's path: lock, invite, buy-in

*Remediation plan for TOP-1 (blind UX audit 2026-08-29). Every file:line below
was re-verified against the working tree at `34d20b6` (== HEAD, == prod).
This is a plan: no product file, migration, spec or decision-log line was
edited. Decision drafts are PROPOSED; the owner logs them before anything
in (b) that depends on them is built (CLAUDE.md rule 1 and rule 5).*

**Audit issues closed here:** M-001, M-002, M-003, M-004, M-005, M-006, M-007,
M-008, M-017, M-018, M-019 (proposal only), M-020, M-022 (partial), M-027
(partial). Hard defects Appendix A #1, #6, #7, #8, #11, #14, #22.

**What is true today, in one paragraph.** `lockBylaws()` (`index.html:15122–15218`)
performs four direct table writes and one RPC in sequence — `league_settings`
update with `locked_at` (`:15127–15149`, skew retry `:15150–15161`), a dead
`invites` insert (`:15163–15170`; `state.emails` is permanently `['']` since
A-W2, `#emailSlots` is not in the markup), `seasons` reuse-or-insert
(`:15183–15196`), `form_squads` (`:15203`), `leagues` phase+name update
(`:15211`) — then throws `ReferenceError: staged is not defined` at `:15218`
(`invited: staged.length`, the return line D97 `1fd47e1` left behind). The
click handler (`:15471–15506`) catches it at `:15502`, fires `lock_fail`
(`:15503`), and `humanError` (`:4106–4118`, default branch `:4117`) narrates a
committed lock as "Lock failed. Something went wrong — please try again."
`openLockShare` (`:14135–14167`, called only at `:15501`) — the one surface
that prints `cupseason.app/?join=CODE` as text — never opens. A retap re-runs
the settings write (RLS `settings_write`, baseline `:2313`, silently matches
zero rows once `locked_at` is set) and the phase write (`leagues_update`,
baseline `:2156`, no lock guard) with `nextPhase` from *local* state
(`:15207`), which is how Desert Dogs became `structure=squads2 · phase=season ·
two empty squads`. Prod `client_events`: `lock_ok` 1 all-time (2026-07-27),
`lock_fail` 11 (all 2026-08-29, all `staged is not defined`). The phone
(`WizardService.swift:109–146`) ports the same five-write sequence without the
crash. Buy-in: `league_settings.buyin_cents DEFAULT 7500 NOT NULL` (baseline
`:1082`), `create_league` inserts the bare default (baseline `:237`),
`#stakeVal` is static `$75` markup (`:3263`) that `resetWizard()`
(`:14088–14097`) never re-renders after zeroing `state.stake`, and
`applyBylaws()` (`:14349–14351`) reloads 7500 on any re-entry. `#installNudge`
(`:3726`, `bottom:76px; z-index:60`) sits over the ⊕ tee
(`.tab[data-v="record"]`, `:2040–2045`, `bottom:calc(64px + safe-area);
z-index:26`). "Draw squads" (`:14884–14890`) and every other RPC caller lose
the server's own sentence in `humanError`. `Cup-Season-Guide.md:106–107` still
promises "or invite by email".

---

## (a) DECISIONS NEEDED

Numbering continues from D110 (`spec/decision-log.md:4090`). Four PROPOSED
entries. Everything else in this plan restores a decision already logged and
needs no new entry — each such item names the decision it restores.

### D111 · PROPOSED — The lock is one server transaction: `lock_league`
*(Mechanics + implementation, level 4–6. Enforces CLAUDE.md "writes with game
consequences go through security-definer RPCs" and D40's "members join a
locked league" at the database. Talk first.)*
- **Current mechanic:** "Lock" is four client writes plus one RPC, in the
  client's order, with no transaction, no idempotency and the next phase
  derived from local `state.structure` (`index.html:15122–15218`;
  `WizardService.swift:109–146`). `join_league`
  (`20260714040000_join_polish.sql:21`) and `respond_invite`
  (`20260713180000_member_invites.sql`) accept members in phase `setup`.
- **Problem:** a client exception after the commit narrates success as
  failure (M-001); a retap after a partial lock rewrites bylaws-adjacent
  rows non-idempotently and can leave `phase=season` with empty squads, a
  state spec §15 forbids (Desert Dogs, prod, 2026-08-29); the phone carries
  the same hazard on a second codebase; D40 decided "members can only join
  a locked league" but the server never enforced it, so a friend can land
  in an unconfigured league and read the $75 nobody chose (TOP-1 root-cause
  lens; setup-QA S3-01).
- **Recommendation:** one SECURITY DEFINER `lock_league(p_league uuid,
  p_bylaws jsonb default '{}')` returning jsonb — bylaws + `locked_at`,
  season 1 reuse-or-insert, `form_squads`, phase **from the stored
  structure** (`solo → season`, otherwise `draft`, exactly today's rule),
  all in one transaction; idempotent: when `locked_at` is already set it
  rewrites nothing and returns the current `{phase, season_id, starts_on,
  ends_on, code, already_locked:true}` (finishing a partial lock whose phase
  is still `setup`); plain-English raises; D37 revoke/grant pair. Both
  clients call it; the direct writes go. Second migration, after both clients
  are live: `leagues_update` and `settings_write` policies dropped — phase
  and bylaws are written only by RPCs (`lock_league`, `start_season`,
  `set_league_finish`, `close_season`, `transfer_pro`, …). Third component:
  `join_league` and `respond_invite` refuse `phase = 'setup'` with "This
  league is still being set up — the Pro opens the door when the bylaws
  lock." (restores D40 at the layer D37 says identity is checked).
- **Principle served:** Principle #2 (Low Friction — the lock is one tap and
  cannot lie); spec §8 / §15 as invariants not sentences (D58's own
  reasoning); CLAUDE.md architecture rule; D40.
- **Benefit:** the crash class becomes impossible to reach after a commit;
  retaps are safe on both clients; one implementation, one bug surface
  (D100 parity at the RPC, not in two ports); no pre-lock covenant.
- **Tradeoffs:** a migration and two client builds for a bug that a
  one-line fix hides today (the one-liner ships first, separately — rule 3).
  Pre-lock joins stop working; `switcherChip` says "Setup — invites open"
  (`index.html:15512`, and again at `:12874`) and the members sheet offers "Remove" in `setup`
  (`:17164`) — both copy that a D40 restoration retires.
- **CONFLICT (named):** D40 vs the shipped `switcherChip` copy and
  `join_league`'s missing guard — D40 wins. A-W2's "minimum-four enforced at
  first tee, not create" stands: the lock is allowed at one member. D58
  exempts `solo` from the min-4 gate (`start_season`,
  `20260722210000:96`), so `solo → season` at lock is kept as-is — whether a
  solo league should wait for a roster is an open question (f-3), not
  decided here.

### D112 · PROPOSED — Buy-in defaults to $0 at every layer
*(Money model, level 4, with a spec conflict. Supersedes §7's default.)*
- **Current mechanic:** spec §7 "Buy-in $25–$200 (default $75)";
  `league_settings.buyin_cents DEFAULT 7500 NOT NULL` (baseline `:1082`);
  `create_league` inserts the default (baseline `:237`); the wizard's
  `#stakeVal` markup reads `$75` (`index.html:3263`) behind "Customize";
  `resetWizard()` zeroes `state.stake` (`:14094`, setup-QA S2-03) but never
  re-renders; `applyBylaws()` reloads 7500 on re-entry (`:14351`);
  `join_covenant_info` serves it to any pre-lock joiner
  (`20260722211500:29`).
- **Problem:** two of two organizers met a $75 stake they never chose
  (M-004, novice P0); prod holds seven unlocked leagues at 7500; the label
  and the state disagree in-session ("one tap of − from $75 goes straight to
  None" is state 0 behind a stale label); D46 said "$0 bragging rights is
  first-class and the default … surfaced so it's seen, not buried" and the
  schema never followed.
- **Recommendation:** migration `alter table league_settings alter column
  buyin_cents set default 0` + `create_league` inserting an explicit 0;
  `#stakeVal` markup "None"; `resetWizard()` calls `renderSetup()` and
  `renderPot()`; the buy-in row moves from `#wizDials` to above "Use these
  defaults →" so the money line is on the fold (D46's "seen, not buried");
  amend spec §7 to "Buy-in $0 by default (bragging rights); $25–$200 when
  money's in play". Backfilling the seven unlocked prod leagues is the
  owner's call (open question f-1).
- **Principle served:** D46 (money is a choice, not a default); D39 (ledger
  language); Principle #2.
- **Benefit:** no covenant ever asks a friend for money the Pro did not
  choose; the label, the state and the row agree on every path.
- **Tradeoffs:** money crews take one more tap; the pot ritual is undersold
  for them (D46 accepted this). One dial leaves the single Customize
  disclosure.
- **CONFLICT (named):** spec §7 "default $75" vs D46 "$0 default" — D46
  wins, §7 amended. A-W3's "everything else behind Customize" vs D46's "seen,
  not buried" — D46 wins for this one row.

### D113 · PROPOSED — The invite is an artifact: URL as text, Copy link, Copy message, on every share control
*(IA, level 3. Extends A-W2 / D40 / D97 — finishes the secondary surfaces
link-first inviting never got. Contact invites stay deferred.)*
- **Current:** `openLockShare` (`index.html:14135–14167`) is the only surface
  that prints the join URL as text and is reachable only from the lock's
  success path; every other share control — `#draftShare` (`:3419`/`:14172`),
  the `.copycode` chip (`:3366`/`:12926`), Members `#msShare` (`:17178`),
  the covenant `#cvShare` (`:17306`), Add golfers' "Share an invite link
  instead" (`:16617`) — calls `shareInvite()` (`:14114–14129`), whose last
  fallback is a 2.4-s toast with the bare code. `Cup-Season-Guide.md:107`
  claims invite-by-email; nothing sends one (`invites` has no consumer;
  `push` and `season-email` are the only Brevo callers).
- **Problem:** 7 of 7 web personas never saw a link (headless caveat noted:
  a phone gets the OS share sheet first — the desk, where the wizard lives
  per IOS-007, is where share/clipboard are least reliable); the Pro cannot
  paste anything into a group text; the Guide is a false map (D97's own
  principle); no surface says "N in · need K".
- **Recommendation:** promote `openLockShare` to `openInviteSheet(L)`: the
  URL as selectable mono text; **Share…** (OS sheet when present); **Copy
  link**; **Copy message** — prewritten: league, the Pro, first tee, "$50 a
  player" or "bragging rights, no buy-in", the link, the covenant's three
  things to know (`:17296–17300`); the seat line "N in · K more to tee off";
  a Pro-only "Preview what they'll see" (M-020). Every share control routes
  here after the OS sheet is unavailable or fails; a clipboard failure reads
  "Copy didn't work — long-press the link", never "sign in again". Contact
  invites (email/SMS) are **not** built by this entry; the Guide is corrected
  to the link-first design; a Brevo-backed mailer is its own future decision
  (the transactional path exists in `supabase/functions/push/index.ts:290–303`).
- **Principle served:** Principle #2 (the computer writes the message);
  GTM `spec/gtm-year1.md:97–99` ("make the invite carry a preview"); D97 (no
  false map); D57's artifact posture.
- **Benefit:** the five friends can be invited from the app without the
  organizer composing instructions; the funnel's first edge
  (`artifact_shared → link_opened`, 20260828160000) becomes measurable for
  every share control, not one.
- **Tradeoffs:** one more sheet on the phone where the OS sheet already
  works (the phone keeps ShareLink first; the sheet adds Copy message only).
- **CONFLICT:** none upward; refines A-W2's IA without reversing it.

### D114 · PROPOSED — Strangers in the invite picker: exact handle or a buddy
*(Social-graph mechanic, level 4. The Findable default flip is offered as
option B and left to the owner.)*
- **Current:** `profiles.discoverable` defaults to `'everyone'`
  (`20260712010000_social_graph.sql:16`, rationale "hub valve one tap
  away"); `search_golfers` returns any discoverable profile on a one-letter
  query (`index.html:13398`, pilot: "M must find @mm…"); the invite picker
  (`openInvitePicker`, `:16604–16619`) lists strangers with [Add]; the Card
  shows "Findable by: All" selected (`:13741–13745`).
- **Problem:** an organizer searching a friend's handle got two strangers
  with [Add] (M-019) — an invite to a league with a pot can reach someone
  who has never met the Pro; the invitee's consent (`invite_golfer` →
  accept/decline) protects the invitee, not the picker's intent.
- **Recommendation (A, recommended):** in invite mode, rows with
  `rel==='none'` are labelled "Not a buddy" and are addable only on an exact
  `@handle` match; name search lists buddies and request-able golfers as
  today. Default stays `'everyone'`. **Option B:** flip the default to
  `'friends'` for new profiles (existing rows untouched) — a stronger privacy
  posture that makes "find my friend by name" fail until they buddy up.
- **Principle served:** Principle #3 (real friends); D23's no-shaming fence;
  the consent posture of `20260713180000` ("decision B").
- **Benefit:** no accidental stranger invites; the founder's discoverability
  (D102 tags) unaffected.
- **Tradeoffs:** one more step to invite a golfer you know by name but not
  handle. Option B trades friend discovery for privacy.
- **CONFLICT (named):** the migration's own rationale "discoverable defaults
  to 'everyone'" (level 6 comment, not a logged decision) vs the audit's
  finding — A keeps it; B overrides it.

### Restorations (no new decision)
| Change | Restores |
|---|---|
| `:15218` fix; commit/celebration split; inline lock error | D40 ("openLockShare fires the instant you lock"), D97 ("keep every live part") |
| Home hero branches on `phase` (locked-and-alone → Share) | D96 ("names the step that is ACTUALLY blocking") |
| RPC messages pass through `humanError` verbatim; Draw disabled with the reason | D58 ("Client copy for the new errors is humanError's job"); F-003's intent |
| Clipboard failures are not auth failures | F-003 |
| `Cup-Season-Guide.md:107` drops "or invite by email" | D97 ("the codebase should not describe a feature it does not have") |
| `#structNote` follows state; "staged" copy retired | D97 |
| Install nudge off the ⊕ | Fogg retiming note at `:12936–12942` (earned moment, never in the way) |
| Lock vocabulary ("lock now, season starts at first tee") | D40 — **after** D111's join gate is decided (see T1-14) |

---

## (b) WORK ITEMS

Effort: S ≤ 2 h · M ≤ 1 day · L multi-day. Deploys are the owner's
(`supabase db push` / `functions deploy` / `git push` / iOS build).

### T1-01 · The lock succeeds and says so (client, same-day)
- **Layer:** client · **Files:** `index.html:15218`; `:15487–15506` (handler); `:3326` (markup after `#lockBtn`)
- **Change:** return `{ nextPhase }` at `:15218` (drop `invited`/`emails`; drop `(invited||0) + (emails||0)` at `:15501`). Split the handler: try A = `await lockBylaws()`; try B = the success tail (`lock_ok`, `loadMemberships`, `switchView('home')`, toast, `openLockShare(nextPhase)`) — an exception in B fires `qaEvent('lock_ui_fail', {msg, stack4})` and never toasts "Lock failed". In catch A, re-read `leagues.phase` and `league_settings.locked_at` for `CS.league.id`; if `locked_at` is set, run the success tail with the server's phase; otherwise render a persistent `<p class="fine" id="lockErr" role="alert">` under `#lockBtn` with the `humanError` text and keep the toast. Add `window.lockBylaws = lockBylaws` and `window.openLockShare = openLockShare` (QA bridges, like `window.state` at `:3799`) so T1-03 can reach them.
- **dependsOn:** — · **effort:** S · **deployNeeds:** client push
- **verification:** local serve, clear SW + caches, `?exit`, sign in, Start a league → name → Next → Next → Lock: the "Bylaws locked ⛳" sheet opens on the first tap; `client_events` gains `lock_ok`; retap the Home CTA → no "Lock failed" (until T1-10, the sheet opens again via the re-read path). Console clean. T1-03's case passes.
- **risk:** none on the DB. The re-read path must derive `nextPhase` from the server row, not `state.structure`.
- **issues:** M-001

### T1-02 · A no-undef pass in preflight (tooling)
- **Layer:** tooling · **Files:** `tests/preflight.mjs` (new check 18 after `:446`; `:95–114` is the `node --check` it complements); new root `package.json` (private; devDependencies `acorn`, `eslint-scope`; `node_modules/` gitignored); `tools/ship.sh` (an `npm ci --ignore-scripts` line before preflight when `node_modules` is absent)
- **Change:** parse each `<script>` block with acorn (`sourceType` classic vs module, `ecmaVersion: 'latest'`), analyse with eslint-scope, and fail on any `through` reference (unresolved identifier) that is not (a) declared at top level in any classic block (classic `function`/`var`/`let`/`const` are global to the module block at runtime — check 3 already covers the *timing* landmine), (b) in a browser-globals allowlist (extend check 3's `BUILTINS` set with `document`, `window`, `console`, `Promise`, `JSON`, `Math`, `Date`, `URL`, `Intl`, `Blob`, `FormData`, `Image`, `MutationObserver`, `IntersectionObserver`, `AbortController`, `TextEncoder`, `Symbol`, `Proxy`, `Reflect`, `Map`, `Set`, `WeakMap`, `Error`, `TypeError`, `RegExp`, `Array`, `Object`, `Number`, `String`, `Boolean`, `parseInt`, `parseFloat`, `isNaN`, `isFinite`, `encodeURIComponent`, `decodeURIComponent`, `atob`, `btoa`, `undefined`, `NaN`, `Infinity`, `globalThis`, `self`, `HTMLElement`, `Node`, `Event`, `CustomEvent`, `KeyboardEvent`, `DOMParser`, `XMLSerializer`, `ResizeObserver`, `OffscreenCanvas`, `ImageBitmap`, `createImageBitmap`, `FileReader`, `Audio`, `webkitAudioContext`, `AudioContext`, `Response`, `Request`, `Headers`, `ReadableStream`, `BroadcastChannel`, `MessageChannel`, `Worker`, `ServiceWorkerRegistration`, `PushSubscription`, `Uint8Array`, `ArrayBuffer`, `DataView`, `WebSocket`, `EventSource`, `Element`, `NodeList`, `HTMLInputElement`, `HTMLCanvasElement`, `CanvasRenderingContext2D`, `getSelection`, `escape`, `unescape`), or (c) inside a `typeof X` guard (skip references whose parent is a `UnaryExpression` with `operator === 'typeof'`). Print `name @ line` (offset by the block's start line in `index.html`). Degrade to `WARN no-undef skipped — npm ci` when `acorn` is not resolvable, so a remote session without `node_modules` never false-fails.
- **dependsOn:** — · **effort:** M (the allowlist will need one tuning pass) · **deployNeeds:** none
- **verification:** run at HEAD before T1-01: exactly one finding — `staged @ index.html:15218`; after T1-01: zero; `node tests/preflight.mjs` still 17 PASS + the new line.
- **risk:** false positives from globals set on `window` by name and read bare elsewhere (`CS`, `sb`, `PILOT`, `MARKERS`) — those are top-level declarations in some block, so (a) covers them; the first run tells.
- **issues:** M-001 (second occurrence of the F-007 class)

### T1-03 · An app-tests case: `lockBylaws` resolves and the share sheet renders
- **Layer:** tooling · **Files:** `tests/app-tests.js` (append after the `csOdo` block, `:44–56`)
- **Change:** stub `window.sb` with a chainable fake (`from().update().eq()` → `{error:null}`; `from().select().eq().eq().maybeSingle()` → `{data:null}`; `from().insert().select().single()` → `{data:{id:'s1', starts_on, ends_on}}`; `rpc()` → `{data:null, error:null}`), set `CS.league = {id:'l1', name:'Test', code:'TESTCODE'}`, `state.demo=false`, `state.structure='squads2'`, `state.emails=['']`; assert `await window.lockBylaws()` resolves with `nextPhase:'draft'`; after T1-06, assert the fake's `rpc` was called with `('lock_league', {p_league:'l1', p_bylaws:{…}})` and no `from('league_settings').update` happened. Then `await window.openLockShare('draft')` and assert `document.querySelector('.sheet .mono')?.textContent` contains `cupseason.app/?join=TESTCODE`. Restore `window.sb` in `finally`.
- **dependsOn:** T1-01 · **effort:** S · **deployNeeds:** none
- **verification:** paste into the console of the local serve per the file header; the summary line reads PASS.
- **risk:** the suite header says read-only/pure — this case touches DOM and `state`; keep it last and self-cleaning.
- **issues:** M-001

### T1-04 · `lock_league` — the lock as one transaction (db-migration + rpc)
- **Layer:** db-migration · **Files:** new `supabase/migrations/<YYYYMMDDHHMMSS>_lock_league.sql`; `packages/db/contract.psv` (refresh per its header query, read-only); `tools/build-db.mjs` re-run (regenerates `packages/db/rpc.ts` and `Rpc.swift`); `tests/db-checks.sql:56–72` (append `lock_league` to check 3's array, count 105 → 106)
- **Change:** `create or replace function public.lock_league(p_league uuid, p_bylaws jsonb default '{}'::jsonb) returns jsonb language plpgsql security definer set search_path = public`. Body: `select * into lg from leagues where id = p_league for update`; `if not found` → 'no such league'; `if not is_commissioner(p_league)` → 'commissioner only'; `if lg.phase = 'complete'` → 'this season is in the record book'. `select * into st from league_settings where league_id = p_league for update`. **If `st.locked_at is not null`** (retap / partial lock): do not touch bylaws; ensure season 1 exists (reuse); `perform form_squads(se.id)` when `st.structure <> 'solo'` (it short-circuits on existing squads, `20260711130000:23`); if `lg.phase = 'setup'` finish the job (`phase := case when st.structure='solo' then 'season' else 'draft' end`); return `jsonb_build_object('phase', …, 'season_id', se.id, 'starts_on', se.starts_on, 'ends_on', se.ends_on, 'code', lg.code, 'already_locked', true)`. **Else** (first lock): read the whitelisted keys from `p_bylaws` with `coalesce(nullif(p_bylaws->>'k','')::type, st.k)` — `preset, handicap_allowance, verification, counting_cap (null = unlimited: honour an explicit JSON null), participation_floor, floor_penalty, season_format, structure, buyin_cents, season_months, draft_type, finish, payout_champ, payout_runnerup, payout_king`; validate `buyin_cents >= 0`, `payout_* sum = 100`, `season_months between 3 and 12` (baseline `:1098`), `structure in ('solo','squads2','squads3','squads4')`; `update league_settings set … , locked_at = now()`; season 1: `insert into seasons (league_id, number, starts_on, ends_on) values (p_league, 1, coalesce((p_bylaws->>'starts_on')::date, current_date), coalesce((p_bylaws->>'ends_on')::date, current_date + 26*7)) on conflict (league_id, number) do nothing` (unique at baseline `:1616`), then select it; `perform form_squads(se.id)` unless solo; `update leagues set phase = case when structure='solo' then 'season' else 'draft' end, name = coalesce(nullif(trim(p_bylaws->>'name'),''), lg.name) where id = p_league`; return the same jsonb with `already_locked:false`. `revoke all on function public.lock_league(uuid, jsonb) from public, anon; grant execute on function public.lock_league(uuid, jsonb) to authenticated;`. Header comment records D111 and the audit's Desert Dogs row.
- **dependsOn:** D111 · **effort:** M · **deployNeeds:** db push (owner: `supabase db push`, then refresh the snapshot and commit `contract.psv` + generated files)
- **verification:** `supabase db query --linked "begin; … rollback;"` on a scratch league as the owner: call twice — the second returns `already_locked:true` and `league_settings.xmin` is unchanged; call on a `squads2` league whose `p_bylaws.structure='solo'` after lock → phase stays `draft` (stored structure wins); `tests/db-checks.sql` checks 3 and 12 PASS (client-callable, not engine); `node tests/preflight.mjs` check 2/11/14/17 PASS after the snapshot refresh.
- **risk:** D37 grants (the revoke/grant pair is in the file; check 2/3 catch a miss). Deploy skew: safe in both orders — the client (T1-06) falls back to the legacy sequence on the "could not find the function" class, and the RPC defaults `p_bylaws`. Data: none mutated by the migration.
- **issues:** M-001, M-017 (structural), M-007 (§8 as a gate stays D58's), Appendix A #14

### T1-05 · Joins wait for the lock (db-migration, D40 at the database)
- **Layer:** db-migration · **Files:** new `supabase/migrations/<…>_join_waits_for_lock.sql` (`create or replace` of `join_league(text)` from `20260714040000:21` and `respond_invite` from `20260713180000`; re-issue their revoke/grant pairs)
- **Change:** both raise `'This league is still being set up — the Pro opens the door when the bylaws lock.'` when `leagues.phase = 'setup'` (and `'This league has wrapped — ask the Pro to run it back.'` on `complete`). `league_by_code` and `join_covenant_info` (anon) unchanged — the door may still name the league; only the join refuses. Client: no change needed once T1-11's pass-through ships (the sentence reaches the golfer verbatim under "Could not join."). `switcherChip` `:15512` and `:12874` copy → "Setup — not open yet"; members sheet `:17164` keeps "Remove" (a pre-lock member can only be the Pro now, so the button hides itself).
- **dependsOn:** D111, T1-11 · **effort:** S · **deployNeeds:** db push
- **verification:** `begin; set role authenticated; set request.jwt.claim.sub …; select join_league('<setup-league code>'); rollback;` raises the sentence; a `draft`-phase join still succeeds; `tests/db-checks.sql` check 3 PASS.
- **risk:** iOS `JoinLeagueFlow` must show the raised sentence (T1-12). Any pilot Pro who shared a pre-lock link sees friends refused — the sentence says why and the Pro's fix is the lock.
- **issues:** M-020 (the covenant can no longer show an unlocked stake), TOP-1 root-cause "pre-lock covenant"

### T1-06 · `lockBylaws()` calls `lock_league` (client)
- **Layer:** client · **Files:** `index.html:15122–15218`; `:15494–15501`
- **Change:** build `p_bylaws` from state exactly as the update payload at `:15127–15144` does today, plus `starts_on`/`ends_on` (`iso(seasonStartDate())`, `iso(seasonEndDate())`, `:7241–7249`) and `name`; `const { data, error } = await sb.rpc('lock_league', { p_league: CS.league.id, p_bylaws })`; on the function-missing error class (`/could not find the function|schema cache|no function matches/`, the skew regex `humanError` already knows at `:4113`) call `lockBylawsLegacy()` — today's sequence moved verbatim into a function that T1-08 deletes. Apply the result: `CS.season = {id, starts_on, ends_on, number:1}`, `state.seasonStart/End`, `state.phase = data.phase`, `CS.league.phase = data.phase`, `CS.league.name`, the two name spans, `renderPhase()`; return `{ nextPhase: data.phase, alreadyLocked: !!data.already_locked }`. Delete the dead `invites` insert (`:15163–15170`) and the `emails` variable (`:15124`) — D97 dead machinery. In the handler, `already_locked` skips the "Bylaws locked" toast and opens the sheet straight away.
- **dependsOn:** T1-04 (either deploy order is safe) · **effort:** M · **deployNeeds:** client push
- **verification:** T1-03's RPC assertion; local serve against prod after the db push: lock → sheet; reload → Home hero (T1-10) → Share; a second `lock_league` call from the console returns `already_locked:true`. Console clean.
- **risk:** deploy skew handled by the legacy fallback; remove the fallback in T1-08's session once `deploy-status.mjs` shows the migration live.
- **issues:** M-001, M-017

### T1-07 · The phone locks through `lock_league` (ios)
- **Layer:** ios · **Files:** `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/WizardService.swift:109–146` (`lock`), `:1–17` (header comment); `apps/ios/CupSeason/Wizard/WizardScreen.swift:272–294` (`lock()`), `:143–153` (handler); `Generated/Rpc.swift` (regenerated by `tools/build-db.mjs` — never hand-edited); `Packages/CupSeasonKit/Tests/CupSeasonKitTests/WizardTests.swift:143` (payload test)
- **Change:** `WizardService.lock` becomes one `svc.call(Rpc.lock_league(p_league:, p_bylaws:))` with `WizardLockPayload(dials, lockedAt:)` re-shaped to the jsonb keys (drop `locked_at`, add `starts_on`, `ends_on`, `name`); `Locked` is built from the returned jsonb; the `SeasonInsert`/`LeaguePhase` structs and the five writes go. `WizardScreen.lock()`: on `.failed`, re-read `svc.league(id)` and `svc.bylaws(id)`; if `locked_at` is set, treat as `.locked` (same split as T1-01). Track `lock_fail` (new `Event` case) with the message on the failure path (`:293`).
- **dependsOn:** T1-04 + snapshot refresh (Rpc.swift needs the grant to mint the name — the compiler enforces D37) · **effort:** M · **deployNeeds:** iOS build (TestFlight)
- **verification:** `cd apps/ios && xcodegen generate && xcodebuild test -project CupSeason.xcodeproj -scheme CupSeason -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` — WizardTests: payload → `p_bylaws` keys; simulator via the dev hatch (memory: `ios-sim-dev-hatch.md`): create → lock → `WizardLockShareSheet` appears; a second lock returns `already_locked` and still shows the sheet. Preflight 15–17 PASS.
- **risk:** the phone has no legacy fallback once T1-08 drops the policies — sequence T1-08 after this build is on TestFlight.
- **issues:** M-001 (iOS parity), Appendix A #1 "WizardService ports the same sequence"

### T1-08 · Phase and bylaws are RPC-only (db-migration, follow-up)
- **Layer:** db-migration · **Files:** new `supabase/migrations/<…>_leagues_rpc_only.sql`; `tests/db-checks.sql:73–82` (check 4 "dead policies stay dead" gains `leagues_update` and `settings_write`); `index.html` (delete `lockBylawsLegacy`)
- **Change:** `drop policy if exists leagues_update on public.leagues; drop policy if exists settings_write on public.league_settings;` — the only direct writers were the two lock paths (`index.html:15211`, `WizardService.swift:141`; grep confirms no other `from('leagues').update` / `from('league_settings').update` on either client). Every other mutation is already a definer RPC (`start_season`, `set_league_finish`, `set_league_look`, `set_league_notify_system`, `transfer_pro`, `delete_league`, `close_season`, D71's cancel trio).
- **dependsOn:** T1-06 live on Netlify AND T1-07 on TestFlight/App Store · **effort:** S · **deployNeeds:** db push + client push (the fallback deletion)
- **verification:** `tests/db-checks.sql` check 4 PASS; as `authenticated` in a `begin … rollback` block, `update leagues set phase='season'` affects 0 rows; the web lock still works (through the RPC).
- **risk:** an old cached client (SW) locking after this push fails at the settings write with an RLS error — `humanError` reads "Please sign in again."; the window is the SW update cycle; T1-01's re-read path shows nothing committed (correct). Acceptable; note it in the handoff.
- **issues:** M-001 (root cause: "leagues_update has no lock guard")

### T1-09 · The invite sheet on every share control (client)
- **Layer:** client · **Files:** `index.html:14135–14167` (`openLockShare` → `openInviteSheet`), `:14114–14129` (`shareInvite`), `:14172–14175` (`#draftShare`), `:12926–12933` (`.copycode`), `:17178`/`:17180` (`#msShare`), `:17306`/`:17310` (`#cvShare`), `:16617` (picker footer), `:3407–3411` (`#homeSetup` — delete the `display:none` checklist; the sheet is the checklist)
- **Change:** `openInviteSheet(L, opts)`: header "Invite the crew" (or "Bylaws locked ⛳" when `opts.justLocked`); the seat line from today's math (`:14145–14154`, count fresh per S2-04) phrased "N in · K more to tee off" / "N in — enough for the squads"; a card with `You're invited to <b>{name}</b> on Cup Season` and `<span class="mono" id="invUrl" style="user-select:all">cupseason.app/?join=CODE</span>`; buttons: **Share…** (only when `navigator.share`), **Copy link**, **Copy message**, and for the Pro "Preview what they'll see" (opens the covenant sheet read-only via `covenantGate`'s renderer — M-020). The message: `You're invited to {league} on Cup Season — {Pro display_name} is running it. First tee {WD MOS D}. {"$N a player, on the books" | "Bragging rights — no buy-in"}. Join: https://cupseason.app/?join=CODE\n\nThree things to know: you can't hurt your squad by playing badly, only by not playing · rounds score against your own number · the pot lives on the books, money moves between you.` Copy uses `navigator.clipboard.writeText` and on failure sets an inline line "Copy didn't work — long-press the link to copy it" (never a toast, never `humanError`). `shareInvite()` keeps the OS sheet first (validator caveat: a real phone gets it) and on `AbortError` returns; when `navigator.share` is absent or throws otherwise → `openInviteSheet(L)`. All five call sites above route to `shareInvite()` unchanged, so the sheet is the universal fallback; the bare-code toast is deleted. Fire `qaEvent('invite_open', {from})` on open and `qaEvent('invite_copy', {what:'link'|'message'})` on copy; `growthEvent('artifact_shared','join',code,…)` stays on Share and now also fires on Copy link.
- **dependsOn:** D113, T1-01 · **effort:** M · **deployNeeds:** client push
- **verification:** browser MCP on the local serve with clipboard denied: tap each of the five controls → `document.querySelector('#invUrl').textContent` contains `/?join=`; "Copy message" with clipboard granted → the pasted text names league, Pro, date, money line, link; `client_events` has `invite_open{from}`; `growth_events` has `artifact_shared kind=join` per copy. Re-run the organizer persona's P1 step (org/38, org/40, org/44 frames).
- **risk:** none on the DB. Keep `openLockShare` as a one-line alias for the D96 hero comment references until T1-10 lands.
- **issues:** M-002 (link-first answer), M-003, M-020, M-022 (the tracker sentence), M-027 (the sheet says "league code" once)

### T1-10 · The Home hero knows a locked league (client)
- **Layer:** client · **Files:** `index.html:10072–10116` (forming branch), `:10101–10102` (CTA)
- **Change:** `const phase = window.CS.league?.phase; const locked = phase && phase !== 'setup'; const isPro = window.CS.member?.role === 'commissioner';` — cells: `setup && unnamed && isPro` → "Name your league" (today); `setup && named && isPro` → "Lock it in and invite your crew" (today); `locked && n <= 1` → line "<b>Just you so far.</b> <em>One link fills the league.</em>" CTA "Share the invite link" → `shareInvite()`; `locked && n > 1 && n < STRUCT_MIN[state.structure]` → "N in · K more to tee off" CTA "Share the invite link"; `locked && n >= min && isPro && phase==='draft'` → CTA "Form the squads" → `switchView('draft')`; `!isPro` → no lock CTA ever from this branch (a one-line guard here; the full role × stage matrix, member verbs and the `switchView('wizard')` gate are Theme 3's — this item only stops handing members the lock). `starter` (`:10076`) stays `phase==='season'`.
- **dependsOn:** T1-01 (works with `openLockShare` today; T1-09 makes the CTA's target the sheet) · **effort:** S · **deployNeeds:** client push
- **verification:** after a lock, reload Home as the Pro: the hero reads Share, not Lock (the org/35 frame); as a member of a draft league: no lock CTA. `home_hero_state` still fires `forming`; add `locked:true` to its props.
- **risk:** Theme 3 will refactor this branch into `leagueStage()`; keep this diff minimal and commented so it folds in.
- **issues:** M-001 (attempts 4–6), M-022, M-030 (guard only)

### T1-11 · Errors say what the server said (client copy)
- **Layer:** client / copy · **Files:** `index.html:4106–4118` (`humanError`), `:14884–14890` (Draw), `:6052` and `:6836` (share/claim copy catches — separate link creation from copying)
- **Change:** in `humanError`, before the jargon branches: (1) an explicit allowlist of our RPCs' sentences — `/^(Not enough golfers|Minimum four to tee off|.* still in the pool|.* is empty — draw again|This league (is still being set up|has wrapped)|Only the Pro|This league seats its squads by Pro assign)/` → return verbatim under the prefix; `commissioner only` → "Only the Pro can do that."; (2) a shape rule as the backstop — a message that starts with a capital letter, is 12–200 chars, contains a space and matches none of the Postgres/PostgREST regexes (`violates|constraint|null value|duplicate key|permission denied|row-level|schema cache|does not exist|jwt|not-null|invalid input|syntax error|relation|column|function`) passes verbatim; (3) exclude the Clipboard API from the auth branch (`/writetext|clipboard/` → "Copy didn't work — the link is on screen to copy by hand."). Draw: when `CS.members.length < CS.squads.length`, render `#fmDraw` disabled with the fine line "1 in · need 2 to cover the squads — share the invite link" instead of waiting for the server to say it (`:14863`). The `:6052`/`:6836` catches: create the token first in its own try (RPC errors → `humanError`), then copy in a second try whose failure renders the URL inline.
- **dependsOn:** — · **effort:** S · **deployNeeds:** client push
- **verification:** `tests/app-tests.js` cases: `humanError({message:'Not enough golfers to cover every squad — 1 in, 2 squads. Share the invite link first.'},'Draw failed.')` returns the sentence with the prefix; `humanError({message:"Failed to execute 'writeText' on 'Clipboard': Write permission denied"})` does not contain "sign in"; `humanError({message:'new row violates row-level security policy'})` still humanised (existing case). Blind re-run of nov/53 (Draw alone) shows the server's sentence.
- **risk:** the shape rule could pass a Postgres message that happens to read like prose — the regex list is the fence; add any leak to the jargon list, never loosen the allowlist.
- **issues:** M-017, Appendix A #6, #7

### T1-12 · `HumanError` parity on the phone (ios)
- **Layer:** ios · **Files:** `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/People/PeopleModels.swift:145–170`; a kit test in `PeopleScheduleTests.swift`
- **Change:** the same allowlist + shape rule + `commissioner only` mapping as T1-11 (no clipboard branch — the phone uses `ShareLink`/`UIPasteboard`); T1-05's join refusal and T1-04's raises reach `JoinLeagueFlow`, `StandingsPane` Draw and `WizardScreen` verbatim.
- **dependsOn:** T1-11 (copy parity) · **effort:** S · **deployNeeds:** iOS build
- **verification:** kit tests for the three strings above; `xcodebuild test`.
- **risk:** none.
- **issues:** M-017

### T1-13 · Buy-in is $0 and on the fold (db-migration + client + ios + spec)
- **Layer:** db-migration · client · ios · spec · **Files:** new `supabase/migrations/<…>_buyin_default_zero.sql` (baseline `:1082`, `create_league` baseline `:218–245`); `index.html:3263` (`#stakeVal`), `:3255–3265` (row placement), `:14088–14097` (`resetWizard`), `:12024` (`#structFit` "staged"), `:12034` + `:7213` (`#structNote` in `syncWizSegs`/`renderSetup`), `:3281–3283` (Teams markup default `4 Squads .on` vs `state.structure:'squads2'` at `:3794`); `apps/ios/CupSeason/Wizard/WizardSteps.swift:111` (row placement); `spec/spec-v1.0.md:157` (§7)
- **Change:** migration: `alter table public.league_settings alter column buyin_cents set default 0;` + `create or replace function public.create_league(text, text)` inserting `league_settings (league_id, buyin_cents) values (v_league.id, 0)` with its revoke/grant pair re-issued; an owner-gated backfill as a commented block (`update league_settings set buyin_cents = 0 where locked_at is null and buyin_cents = 7500; -- 7 rows expected`) that ships uncommented only on the owner's yes (f-1). Client: `#stakeVal` markup "None"; move the buy-in `.setrow` (`:3261–3265`) above `#wizFastPath` (`:3258`) with the D39 fine line "The pot lives on the books — money moves between you"; `resetWizard()` calls `renderSetup(); renderPot();`; `syncWizSegs()` sets `#structNote` from `STRUCT_NOTES[state.structure]` and marks the matching `#structSeg` button `.on` so the caption and the highlight agree on first paint; `#structFit` (`:12024`) → "N golfer(s) in — solo or up to K squads fit. Bigger squads open up as more join." iOS: the buy-in row rendered above the preset cards' fast path (parity of placement; `WizardDials.stake` already defaults 0 at `WizardState.swift:92`; the DB default fix closes the phone's reload path via `MeRepository`/`LeagueRoomModel`). Spec: §7 amended per D112.
- **dependsOn:** D112 · **effort:** M (db S · client S · iOS S · spec S) · **deployNeeds:** db push + client push + iOS build
- **verification:** new league, Customize collapsed: the buy-in row is visible reading "None"; reload mid-wizard → still "None" (`applyBylaws` loads 0); `select column_default from information_schema.columns where table_name='league_settings' and column_name='buyin_cents'` → `0` (add as `tests/db-checks.sql` check 5's sibling); `join_covenant_info('<new code>')` → `buyin_cents: 0`; nov/19 frame re-run shows None; iOS WizardTests `stakeText` at default == "None".
- **risk:** deploy skew (client first): the label reads None from state, a reload before the db push shows 7500 for a few hours — today's behaviour, not a regression. Data migration only on the owner's yes.
- **issues:** M-004, M-005 (the ladder stays; a numeric field is a later polish), M-008, Appendix A #11, #22

### T1-14 · One lock vocabulary and an honest Guide (copy)
- **Layer:** copy · **Files:** `Cup-Season-Guide.md:106–107`; `index.html:3325` (`#inviteNote`), `:3326` (`#lockBtn`), `:3222` (eyebrow), `:3557` (League tab eyebrow), `:12076`, `:17423`, `:15512` + `:12874` (`switcherChip` and the room subtitle), `:3273` (Teams (i) — add the minimum); `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/WizardState.swift:245`, `:341`, `:385–386`, `:400–401` and `apps/ios/CupSeason/League/LeaguePane.swift:60`
- **Change:** **Now (no decision):** Guide → "Name it, set the buy-in, the season length, the format and the endgame, then Lock it — the invite link opens the moment you lock. Golfers already on Cup Season can be added by name or @handle; everyone else joins with the link or the league code." **After D111 (join gate decided):** `#lockBtn` "Lock the bylaws & open the league"; `#inviteNote` "Locking publishes the bylaws and opens the invite link — one link fills the league, and anyone can join with the league code until the squads are drawn. Four golfers to tee off: invite first, draw when the crew is in."; eyebrow `:3222` "Create your league · the bylaws lock now, the season starts at first tee"; `:3557` "The bylaws · locked {date}"; `:12076` "Forming · bylaws locked"; `:17423` "You can rename it any time before you lock."; Teams (i) `:3273` gains "Four golfers minimum to tee off; more can join by code after you lock." iOS: the same strings — `WizardState.swift:245` ("Forming · locks at first tee"), `:341` (the eyebrow), `:385–386` (`inviteNote`, `lockButton`) and `LeaguePane.swift:60` ("The bylaws · locked at first tee"). If the owner amends D40 instead (invites open in setup), the same anchors flip to "invites are open now; the bylaws lock at …" — the anchors are the deliverable either way.
- **dependsOn:** Guide half: — · lock-vocabulary half: D111 · **effort:** S · **deployNeeds:** client push + iOS build (copy only); the Guide is a repo doc, not served (`stamp-version.sh` allowlist)
- **verification:** grep the four strings on both clients; the in-app GUIDE `buddies` sheet (`index.html:13231–13235`) already describes link-first inviting correctly — confirm, no change.
- **risk:** none.
- **issues:** M-002 (Guide), M-006, M-007, M-014 (the "Start the league" button on the name sheet is Theme 3/IA — not touched here)

### T1-15 · The install nudge never covers the ⊕ (client)
- **Layer:** client · **Files:** `index.html:3726–3729` (markup), `:12936–12958` (JS), `:2040–2045` (the tee's CSS, read-only reference)
- **Change:** the nudge becomes a top banner: `top: calc(env(safe-area-inset-top) + 8px); bottom: auto` (or, if the header must stay clear, `bottom: calc(64px + env(safe-area-inset-bottom) + 72px)` — above the tee's 56-px circle) with `z-index: 24` (below the tab bar's 25 and the tee's 26); `show()` (`:12948`) refuses while `document.querySelector('.view.active')?.id` is one of `view-play`, `view-record`, `view-wizard`, `view-draft` and `switchView` hides it on entering those; `#nudgeGo` text "Add to Home Screen" so it never sits beside the guest "Add" reading the same.
- **dependsOn:** — · **effort:** S · **deployNeeds:** client push
- **verification:** browser MCP: with the nudge shown, `document.elementFromPoint` at the tee's centre returns `.tab[data-v="record"]`; on Live setup the nudge is absent.
- **risk:** none.
- **issues:** M-018, Appendix A #8

### T1-16 · Lock health is watched (telemetry + tooling)
- **Layer:** telemetry / tooling · **Files:** `tests/db-checks.sql` (new check 15 after `:281`'s check 14); `tools/deploy-status.mjs` (a "funnel" line when the CLI is present) or a sibling `tools/funnel-status.mjs` invoked by `tools/ship.sh` preflight; `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Wizard/WizardService.swift:28` (`Event` gains `lock_fail`) and `WizardScreen.swift:293`
- **Change:** check 15 "lock funnel healthy": over the last 7 days in `client_events`, FAIL when `count(event='lock_fail') > count(event='lock_ok')` or when any `lock_fail` carries `props->>'msg' ~* 'is not defined|undefined|null is not'` (a client crash, not a server refusal); the detail column prints the top three messages. `deploy-status.mjs`: with the CLI, `supabase db query --linked --output-format text "select event, count(*) from client_events where event in ('lock_attempt','lock_ok','lock_fail','invite_open','invite_copy') and created_at > now() - interval '7 days' group by 1"` rendered as one line; WARN when `lock_fail > lock_ok`; `unknown` without the CLI (never `clean`). iOS: the phone's lock failures become visible (today it tracks attempt/blocked/ok only).
- **dependsOn:** — (T1-07 for the iOS half) · **effort:** S · **deployNeeds:** none (tooling); iOS build for the event
- **verification:** run `tests/db-checks.sql` before the audit cleanup → check 15 FAIL naming `staged is not defined`; after cleanup + T1-01 live + one real lock → PASS. The Stop hook prints the funnel line only when something is off.
- **risk:** `client_events` is insert-only for the API roles — both readers run as postgres (SQL editor / linked CLI), as the pilot views do.
- **issues:** M-001 ("alert when lock_fail > lock_ok")

### T1-17 · Strangers in the invite picker (client + ios, D114)
- **Layer:** client · ios · **Files:** `index.html:13351–13410` (`psRow`/`psSearch`), `:16604–16619` (`openInvitePicker`), the People Picker's invite-mode renderer (`:13680–13700`); `apps/ios/CupSeason/People/PeoplePickerSheet.swift`; optionally `20260712010000` default (option B: a new migration `alter column discoverable set default 'friends'`)
- **Change (option A):** in `mode:'invite'`, rows with `rel==='none'` render the tag "Not a buddy" and an [Add] that is enabled only when the query equals the row's `@handle` exactly; the sub-line reads "Type their exact @handle to invite someone who isn't a buddy yet." The Card's "Findable by" (`:13741–13745`) is untouched. iOS `PeoplePickerSheet` mirrors the tag and the exact-handle rule. Option B adds the default flip for new profiles only.
- **dependsOn:** D114 · **effort:** M · **deployNeeds:** client push + iOS build (+ db push for option B)
- **verification:** search a stranger's first letter in invite mode → no enabled [Add]; type the exact handle → [Add] enabled; `invite_golfer` still refuses non-Pros (`20260713180000`).
- **risk:** none on grants; option B is a data-default change only.
- **issues:** M-019

---

## (c) QUICK WINS — no decision, this week

T1-01 · T1-02 · T1-03 · T1-10 · T1-11 · T1-12 · T1-14 (Guide half) · T1-15 ·
T1-16. Ship order: T1-01 first and alone (rule 3: the crash fix rides with
nothing else), then T1-02/T1-03 as the regression fence, then the rest as one
client push. Together they turn "0 of 2 organizers saw a success state" into
a working lock with a visible link (`openLockShare` already prints the URL —
it just has to open), honest Draw/share errors, and a ⊕ that takes the tap.

---

## (d) PARITY (D100 — nothing ships on the web alone)

| Web item | Phone | Note |
|---|---|---|
| T1-01 crash + split | T1-07's `.failed` re-read | The phone has no crash; the split is the parity. |
| T1-04 / T1-06 `lock_league` | T1-07 | Same RPC, generated `Rpc.swift`; the five writes go on both. |
| T1-05 join gate | T1-12 shows the sentence in `JoinLeagueFlow` | Server-side; the phone needs only the copy pass-through. |
| T1-08 policies | none | Server-side; sequence after the TestFlight build with T1-07. |
| T1-09 invite sheet | `WizardLockShareSheet.swift` already prints the URL as selectable text + `ShareLink` + Add golfers; add **Copy message** (`UIPasteboard`, the same prewritten text from a shared `WizardCopy.inviteMessage(...)`) and the seat line to it and to `MembersSheet.swift:38–43`; the room chip / Standings / covenant / picker `ShareLink`s (`LeagueRoomScreen.swift:157–163`, `StandingsPane.swift:58–66, 115–121`, `JoinLeagueFlow.swift:189–193`, `PeoplePickerSheet.swift:50–58`) stay OS-sheet-first (a phone gets it) | S — one `inviteMessage` in `WizardState.swift` beside `inviteText` (`:415`). |
| T1-10 hero branch | `HomeView.swift:566–568`: the forming line gates on `isPro` but not on phase and the phone hero has no CTA; add the `draft`-and-alone line ("Just you so far. One link fills the league.") and a `ShareLink` row under the hero in `.forming` when `league.phase != "setup"` | S. |
| T1-11 errors | T1-12 | — |
| T1-13 buy-in | `WizardSteps.swift:111` row placement; default already 0 | S; the DB default closes the reload path for both. |
| T1-14 copy | `WizardCopy` strings `WizardState.swift:385–386, 400–401` | S. |
| T1-15 install nudge | **web-only by nature** (no install banner on the phone) | — |
| T1-16 telemetry | `lock_fail` event on the phone | S. |
| T1-17 picker | `PeoplePickerSheet.swift` | M. |

Native work runs locally (CLAUDE.md rule 6); the iOS items are one local
session after the db push and snapshot refresh.

---

## (e) MEASUREMENT

**Events (existing unless marked new).** `client_events` (`20260717153000`,
`profile_id/event/props`): `league_create{named}` · `lock_attempt` ·
`lock_blocked{reason}` · `lock_ok{next_phase}` · `lock_fail{msg}` (web today;
iOS new, T1-16) · **new** `lock_ui_fail{msg,stack4}` (T1-01) · `invite_open{sent}`
→ `{from}` (T1-09) · **new** `invite_copy{what}` (T1-09) · `home_hero_state{state}`
+ `{locked}` (T1-10) · `home_hero_tap{cta}`. `growth_events`
(`20260828160000`, founder-read via `v_growth_funnel` by `kind='join'`):
`artifact_shared` (every share/copy) → `link_opened` (`index.html:17820`
signed-out, fail-closed) → `profile_created` → `first_round_posted`.

**Proof the fix worked (first 20 real locks after T1-01 is live).**
1. `lock_ok / lock_attempt ≥ 0.95` and zero `lock_fail` whose msg matches
   `is not defined` (check 15 green).
2. `invite_open / lock_ok = 1.0` (the sheet opens on every lock).
3. `artifact_shared(kind=join) / lock_ok ≥ 1` within the session, and
   `invite_copy` non-zero on desktop sessions (the desk had no path before).
4. `link_opened(kind=join) / artifact_shared(kind=join) > 0` within 24 h for
   at least one real league — the edge the GTM plan bets on.
5. Zero `league_settings` rows created after T1-13 with `buyin_cents = 7500`
   and `locked_at is null`; `join_covenant_info` on a fresh league returns 0.
6. After T1-04: no `leagues` row with `phase='season'` and an empty squad
   (`tests/db-checks.sql` check 8's sibling, one query).

**Acceptance — blind persona re-run.** Journey C (create) for the A5
organizer and A3 novice briefs on a fresh `jerecho+blind7@` account against
prod after the client push: the first Lock tap yields the share sheet with
the URL on screen; "Copy message" pastes a complete invite; Draw alone shows
the server's sentence and a disabled Draw with the reason; the buy-in row is
visible reading "None" before Customize; Home after reload says "Share the
invite link", never "Lock it in". Target: the organizer's own estimate
("fix the lock bug and add a real invite and this is a 7") — `setupClear`
4 → ≥ 7, `wouldInvite` 4 → ≥ 6. Then Journey D for the A6 joiner opening
that link — the join must be refused until the lock (T1-05) and never show
$75.

---

## (f) OPEN QUESTIONS for the owner

1. **D112 backfill.** Zero `buyin_cents` on the seven unlocked July leagues
   (all 7500, none chosen)? It is a prod data mutation; the migration ships
   the statement commented unless you say yes.
2. **D111's join gate.** Enforce D40 at the server (joins refused in
   `setup`) — the plan's recommendation — or amend D40 to "invites open at
   creation" (then T1-14's copy flips the other way and `join_covenant_info`
   must hide the stake until lock)? One of the two; the copy cannot be
   honest with neither.
3. **Solo leagues at lock.** Today (and in `lock_league` as drafted) a solo
   league goes straight to `season`, so a one-person league reads "SEASON
   LIVE"; D58 exempts solo from min-4 while spec §8 says "min 4 players" and
   `STRUCT_MIN.solo = 2`. Keep, or hold solo at `draft` until two (or four)
   golfers are in? A mechanic change either way — a separate D-entry if you
   change it.
4. **D114 A or B.** Exact-handle for non-buddies only (A), or also flip the
   Findable default to Buddies for new profiles (B)?
5. **Contact invites.** Defer email/SMS invites to a future decision (this
   plan), or schedule it now? The Brevo transactional call exists in `push`
   (`index.ts:290–303`); a mailer needs a consumer for `invites` (or
   `member_invites`), a consent posture and a rate cap — roughly M–L.
6. **Buy-in above Customize.** D46 says "seen, not buried"; A-W3 says one
   disclosure. Moving one row is the plan's read of D46 — confirm.
7. **Sequencing T1-08.** Dropping `leagues_update`/`settings_write` waits
   for the TestFlight build carrying T1-07; say when that build is out and
   the follow-up migration ships after.

---

## Appendix — line anchors verified at HEAD (`34d20b6`)

`index.html`: 2040–2045 (⊕ tee CSS) · 3222 · 3255–3265 · 3263 · 3273 ·
3281–3284 · 3325–3326 · 3366 · 3407–3411 · 3419 · 3557 · 3726–3729 ·
3793–3794 · 3809 · 4106–4118 · 6052 · 6230–6253 · 6836 · 7213 · 7225–7249 ·
7262–7263 · 9993 · 10072–10116 · 10101–10102 · 12024 · 12034 · 12076 ·
12905–12933 · 12936–12958 · 13351–13410 · 13398 · 13402 · 13693 ·
13741–13745 · 14088–14097 · 14114–14129 · 14135–14167 · 14172–14175 ·
14349–14351 · 14863 · 14884–14903 · 15122–15218 · 15127–15149 · 15150–15161 ·
15163–15170 · 15183–15196 · 15203 · 15207 · 15211 · 15218 · 15471–15506 ·
12874 · 15512 · 16604–16619 · 17140–17180 · 17296–17310 · 17423 · 17820.
Migrations: baseline 218–245, 1043–1051, 1082, 1098, 1115, 1616, 2156,
2313 · `20260711130000` (form_squads, :23) · `20260712010000:16` ·
`20260712230000` · `20260713180000` · `20260714040000:21` ·
`20260717153000:19` · `20260722210000:23–125` · `20260722211500:29–44` ·
`20260828160000`. Edge functions: `push/index.ts:290–322`,
`season-email/index.ts:1–20`. Tests: `tests/preflight.mjs` (17 checks;
:95–114, :222–246), `tests/app-tests.js` (61 lines), `tests/db-checks.sql`
(:34–72, :73–82, :281). iOS: `WizardService.swift:1–17, 28, 109–146` ·
`WizardScreen.swift:61–63, 143–153, 272–294` · `WizardState.swift:17, 92,
122–123, 245, 341, 385–418` · `WizardLockShareSheet.swift` · `WizardSteps.swift:111` ·
`PeopleModels.swift:145–170` · `HomeView.swift:566–568` ·
`LeagueRoomScreen.swift:157–163` · `StandingsPane.swift:58–66, 115–121` ·
`MembersSheet.swift:38–43` · `PeoplePickerSheet.swift:50–58` ·
`JoinLeagueFlow.swift:189–193` · `LeagueRoomModel.swift:530–535`.
Docs: `Cup-Season-Guide.md:106–107` · `spec/spec-v1.0.md:157` (§7), `:161–186`
(§8), `:256–261` (§15) · `spec/decision-log.md` D40 (:1139), D46 (:1333),
D58 (:1767), D96 (:3422), D97 (:3461), D100 (:3633), D110 (:4090) ·
`spec/setup-qa-findings.md:51–66` · `spec/design-review-2026-07-20.md:198–199`
· `spec/gtm-year1.md:97–99` · `docs/ios/DECISIONS.md` IOS-007 (:52), IOS-024
(:249).
