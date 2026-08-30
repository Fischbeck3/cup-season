# idx-13-module-b — `index.html` 15400–18706 (module block, second half)

**Read:** every line of 15400–18706, plus the call sites and definitions needed to
judge them: the door markup (2640–2705), `#hubLeagueless` (3358–3376), `state`
init (3816), `esc` (4123), `enterApp`/`backToDoor` (4173–4184), the wizard gate
(4208–4226), `growthEvent` (6513–6520), `seasonStartDate`/`isoOf` (7600–7620),
`openSheet`/`closeSheet` + the three dismiss paths (12218–12246), `renderEmails`
(12596–12622), `renderNotifications` invite rows (13240–13264),
`showProfileGate` (13539–13560), the golfer-card save → `resumeAfterProfile`
handoff (13630–13663), `openLockShare` (14633–14670), `enterLeague` (14897–15080),
`loadStandingsAndFeed` (15100+). Server side: `20260829220000_lock_league.sql`,
`20260830040000_buy_in_terms.sql`, `20260828160000_growth_events.sql`,
`20260713180000_member_invites.sql`.

**Session code in this slice** (34d20b6..HEAD): `lockBylaws`'s `lockViaRpc` +
skew fallback, the `#lockBtn` three-outcome handler, `lockErr`/`lockedPhase`,
`openEmailBox`'s Q-18 back-button, the `#obJoin` Q-18 branch, `covenantGate` on
`#wCodeGo` / `boot()` / `resumeAfterProfile()`, the Q-15 copy on the join door
and `?join=`, `switcherChip` → `stageLabel`. Reviewed hardest.

---

## What holds up

- **`lockBylaws`'s RPC-vs-fallback split is correct.** The fallback regex
  (`schema cache|could not find the|does not exist|no function matches`) does
  *not* match `lock_league`'s two real refusals — `That league no longer exists.`
  and `Only the Pro can lock the bylaws.` — so a genuine 403 reaches the golfer
  instead of being retried through the weaker path. A network failure after a
  committed transaction produces `Failed to fetch`, which also misses the regex,
  throws, and lands in the `lockedPhase()` recovery. **No double-write path
  found**: `lock_league` is one transaction, and the fallback's own writes are
  each idempotent (`update ... locked_at`, reuse-season, `form_squads`).
- The Q-01 three-outcome `#lockBtn` handler (commit / celebration / server probe)
  is genuinely right, and `lockedPhase()`'s `phase !== 'setup'` probe cannot
  false-positive for a member because `switchView('wizard')` bounces non-Pros.
- The five `join_league` call sites all pass `covenantGate` now. (A **sixth**
  join path was missed — see B-04.)
- `bootResolved` / `booting` make `safeBoot` genuinely idempotent across
  INITIAL_SESSION + the 3s fallback + SIGNED_IN.
- The `isoOf()`-not-`iso` TDZ note in `lockViaRpc` is accurate: `isoOf` is a
  classic-block top-level function declaration (7614) and therefore visible to
  the module; the `const iso` at 15752 really would have been in TDZ.
- `renderShareView`, `covenantGate`, `openMembersSheet`, `renderWatchList`,
  `renderRoundSheet`, `openFounderDesk` and `renderAlbum` all escape their
  user-supplied strings. One sibling in the same file does not (B-02).

---

## Bugs

### B-01 (P1) `covenantGate` never resolves when its sheet is dismissed — boot hangs forever
`index.html:16032-16043`. The promise resolves only from `#covJoin` and
`#covNo`. The sheet has three other dismiss paths, all global and all live:
`#shClose` (12242), a backdrop tap (12243), and `Escape` (12246). Each calls
`closeSheet()` and leaves the promise pending forever.

The worst consumer is `boot()` at 18173. A signed-in golfer with a pending
`cs_code` for a league with a buy-in reloads the app; the covenant sheet opens;
they tap the X. `await covenantGate(pend)` never settles, so `boot()` never
reaches `showWelcome()` / `enterLeague()`, its `finally` never runs, the 8s
watchdog fires `Boot stalled at [memberships]`, and `safeBoot`'s `finally` never
clears `booting` — so no later `safeBoot` can run either. The onboarding overlay
is still up (only `enterApp()` hides it), so the user sits on the splash. It
reproduces on every reload, because the D116 change deliberately *keeps* the
code on decline. `resumeAfterProfile()` (18240) and `#orGo` (13662) have the
same shape for a brand-new invited signup.

**Fix:** resolve `false` on dismissal — e.g. wire the promise to a one-shot
`closeSheet` observer, or add `res(false)` to `#shClose`/backdrop/Escape via a
`window._sheetOnClose` hook set by `covenantGate`.

### B-02 (P1) Stored XSS: the league switcher renders an event name unescaped
`index.html:16388`. `row('__event:'+e.id, icon, e.name, …)` and `row` inserts
`title` raw: `<div class="tt"><b>${title}</b>…`. Every sibling in the same
function escapes (`esc(m.league.name)` 16383, `esc(i.container_name)` 16392).
`create_event` (`20260713120000_ryder_events.sql:157`) stores `p_name` verbatim.
`loadMyEvents` (16700-ish) pulls *attached* events for every league you are in
(`.in('league_id', lids).neq('status','complete')`), so any league member can
name a Ryder/Major with markup that executes in every other member's page when
they tap the header to open the switcher. The CSP is Report-Only, so nothing
blocks it, and the Supabase session lives in `localStorage` on the same origin.

### B-03 (P2) The growth funnel's first three nodes can never fire
`index.html:18326, 18497, 18523, 18640`. `growthEvent` (6515) opens with
`if(state.demo || !window.sb) return;`. `state.demo` is initialised **true**
(3816) and is only flipped false by `resetToBlank()` (12374, reached via
`createLeague`/`enterLeague`), `showWelcome()` (17998) and `enterGuestLive`
(8421). The `?share=` / `?join=` / `?claim=` blocks run at **module evaluation**,
before any boot — `state.demo` is unconditionally `true` there — so all three
`link_opened` calls are no-ops for *every* visitor, signed in or out. A
signed-out visitor never flips the flag at all, so `claim_started` (18640) and
`profile_created` (13638, cross-range) are dropped too. A `?share=` view sets
`_csShareView` and is terminal, so the share card — the artifact the GTM plan
runs on — logs nothing, ever.
`20260828160000_growth_events.sql` exists specifically because "a NON-user
opening a shared link was invisible by construction" and grants
`log_growth_event` to `anon` for it; the client guard makes that grant
unreachable. The funnel table will read zeros and be interpreted as "nobody
opens links."
**Fix:** `growthEvent` should gate on `!window.sb` only (the RPC is already
fail-closed and anon-safe), or the three hatch call sites should call
`sb.rpc('log_growth_event', …)` directly.

### B-04 (P2) Accepting an invite joins a paid league with no covenant and no disclosure
`index.html:17249-17259`. `window.respondInvite` fires `respond_invite`
directly. That function (`20260713180000_member_invites.sql`) inserts into
`league_members` — it is a real join. The three call sites (13251, 13260, 16428)
show no stake: the notification row says "League invite · <name>", the Details
sheet says only "A season-long league.", and the success path is a bare
`toast('Joined ✓')` — no `enterLeague`, so not even `openLeagueWelcome`'s
post-join `$X buy-in` line runs. Q-14/D116 ruled consent belongs on *every*
join path and fixed five; this is the sixth. It also walks around D112
(no join before the bylaws lock), which `join_league` enforces.

### B-05 (P2) The sign-in door dead-ends: "I have a league code" hides the email door with no way back
`index.html:16002-16013`. The Q-18 handler does
`const em = $('#obEmail'); if(em) em.style.display = 'none'; const bk = $('#obBack'); if(bk) bk.style.display = '';`
— but `#obBack` does not exist in the markup (2647-2666); it is created only
inside `openEmailBox` (15834-15848). On a cold load, tapping "I have a league
code" hides "Continue with email" and shows the code box with **no Back
control**. A golfer who taps it by mistake, or who has no code, cannot reach
sign-in without reloading the page; `backToDoor()` (4183) does not restore the
`display` either. The only escape is to type a code and submit it (which calls
`openEmailBox` and mints the button).
Secondary: `openEmailBox` re-anchors `#emailbox` on every call
(`afterEl.insertAdjacentElement('afterend', box)`) but inserts `#obBack` only
once, `beforebegin` the box's *then-current* position — so after a re-anchor the
Back button is stranded at the previous spot.

### B-06 (P3) A stale `cs_code_name` names the wrong league on the door
`index.html:18490-18513` + `18592-18598`. The `?join=` block writes `cs_code`
synchronously but only overwrites `cs_code_name` inside the async
`league_by_code` `.then()`. Open an invite link for league A while signed out
and decline (D116 now *keeps* both keys), then open an invite link for league B:
`safeBoot` reads `cs_code = B` and `cs_code_name = "Alpha"` and shows
"You're invited to Alpha. Sign in to review the league before you join." When
the RPC resolves, the warm-up guard `/^You're invited\. /` matches only the
*generic* line, so the named-but-wrong line is never corrected. The golfer is
told they are joining Alpha and joins Bravo.
**Fix:** `localStorage.removeItem('cs_code_name')` in the same statement that
sets `cs_code` at 18494.

### B-07 (P3) "Resend code" survives the Back button
`index.html:15839-15847`. The Back handler closes the three boxes and restores
the two doors but never re-hides `#obResend`, which `startResendCooldown()` set
to `display:block`. After Back the door shows "Continue with email", "I have a
league code" **and** a stray "Resend code" that still fires a real OTP send to
`CS.pendingEmail`. (The `#obJoin` handler at 16010 remembers to hide it; Back
does not.)

### B-08 (P3, a11y) The only escape from the code door is a sub-44px text link
`index.html:15837` + CSS `1879-1882`. `back.className = 'cs-tskip'`, and
`.cs-tskip` is `display:block; margin:12px auto 0; background:none; border:none;
font-size:12.5px; color:var(--dim); text-decoration:underline` — no padding, no
min-height. The hit box is roughly 45×16 CSS px, well under the 44×44 floor, in
`--dim`, and it is the sole way back from an opened branch (B-05).

### B-09 (P2, perf) Every board post — chat included — triggers a full standings + Home reload
`index.html:15455-15462`. The `posts` INSERT handler calls
`loadStandingsAndFeed()` **and** `loadHome()` with no coalescing, on a filter
that is `league_id` only (chat is `kind='chat'` in `posts`).
`loadStandingsAndFeed` is `v_squad_standings` + `cup_final_race` +
`week_clashes` + the board feed; `loadHome` is ~8 more queries plus a batched
storage-signing call. A four-person chat burst therefore fans out to dozens of
round-trips per open client. The fix pattern is four lines above: `nudgeSocial`
already coalesces kudos/comments into one refresh at 250ms.

### B-10 (P2) `liveSync.flush()` can silently discard a golfer's scores
`index.html:15563`:
`if(/not live|final|No such|not in this|function|schema cache/i.test(r.error.message||'')){ q.shift(); … }`
The intent is "permanently un-landable → drop". But `function` also matches
PostgREST's 42501 `permission denied for function live_set_score` — exactly the
D37 landmine CLAUDE.md says a new RPC hits ("A new RPC that silently 403s in
prod is almost always a missing grant"), and this session touched the live
tables (`20260828150100_live_tables_participant_scoped.sql`). In that state the
broadcast still paints every hole on every phone while the durable queue throws
each write away — the round finishes and the database has no scores. Match the
skew shapes (`schema cache`, `Could not find the function`) and the explicit
server refusals; never drop on a bare `function`, and never on 42501.

### B-11 (P3) The public share card's tab title says "at null"
`index.html:18380` (`document.title = \`${info.name} — ${info.gross} at ${info.course} · Cup Season\``)
and `18424` (`\`${GAME[info.game] || 'Settlement'} at ${info.course} · Cup Season\``).
Both card *bodies* guard the same value (`info.course || 'A ROUND'` at 18406,
`String(info.course || '')` at 18468), so the author knew it is nullable — a
round posted without a course label gives every recipient a browser tab reading
"MATCH PLAY at null · Cup Season". This is the one page strangers see.

### B-12 (P3) `CS.reviewerMode` is sticky for the session
`index.html:15960-15968`. Typing `reviewer@cupseason.app` sets
`CS.reviewerMode = true`, turns `#obCodeIn` into a password field and strips its
`inputmode`/`maxlength`. Nothing ever sets it back to `false` — the normal
`#obEmailGo` branch (15970+) doesn't, and neither does Back. An App Review
tester who types the review address and then switches to a normal address is
stuck: the code box still says "REVIEW PASSWORD", auto-submit is disabled
(15905), and `#obCodeGo` calls `signInWithPassword` against the *new* email
(15869 reads `CS.pendingEmail`, which the normal branch does update).

### B-13 (P3, low confidence) `backToDoor()` on SIGNED_OUT can reveal an empty overlay
`index.html:18697` calls `backToDoor()`, which only un-hides `#onboard`
(4183). `showProfileGate()` (13539-13544) sets `#obDoor`, `#obCaption` and
`.ob-hero` to `display:none`, and the card-save path (13640) hides `#obProfile`
without restoring them. If SIGNED_OUT arrives in a tab that ran the profile gate
without a reload — a cross-tab sign-out, or a refresh-token failure — the
overlay comes back with nothing in it. The asymmetry's root is
`showProfileGate`/`backToDoor` (outside this slice); the SIGNED_OUT handler is
where it surfaces.

### B-14 (P3, low confidence) Unguarded `localStorage` writes on the join door
`index.html:16057-16058`. `localStorage.setItem('cs_code', code)` sits outside
any try/catch, unlike every other `localStorage` access in this module
(15493, 17158, 18205, 18221, 18496, 18521, 18601…). In a webview configured to
block site data, the throw escapes as an unhandled rejection and the email box
never opens — the join door does nothing at all. `safeBoot`'s
`localStorage.getItem('cs_code')` (18592) has the same gap, though it fires
after the boot has completed.

---

## Opportunities

### O-01 The covenant ignores the payment terms this session's own migration added for it
`20260830040000_buy_in_terms.sql` extends `join_covenant_info` with
`has_pay_note` and `buy_in_due_on`, and its header states "The covenant learns
THAT the Pro has posted terms". `covenantGate` (16033-16040) renders neither —
`grep has_pay_note index.html` returns nothing. The one screen that discloses
money before a golfer commits still cannot say "due Sep 15" or "the Pro has
posted how to pay". Server shipped, client didn't.

### O-02 ~50 lines of unreachable invite-email machinery in `lockBylaws`
`index.html:15696` (`let emails = state.emails.filter(…)`), `15735-15744`
(the `invites` insert + its error toast), and the `emails` half of the return
value. `state.emails` is only ever written by `renderEmails` (12609-12617),
which early-returns because `#emailSlots` was deleted from the wizard ("A-W2"),
so the filter is always `[]`. Deleting it removes the file's only remaining
direct `insert` into `invites` and one of the last `state.emails` readers.

### O-03 `hideWelcome()` is not the inverse of `showWelcome()`
`index.html:18027-18033` restores `#obDoor` / `#obWelcome` / `#obCaption`;
`showWelcome()` (17994) touches none of them — it adds `body.noleague` and calls
`enterApp()`. `#obWelcome` is never shown anywhere in the file (only hidden, at
13541 and 18028), so `hideWelcome`'s two call sites (16238 in `openJoinSheet`,
18053 in `#wCodeGo`) mutate an element that is permanently invisible. Two
functions with paired names and unrelated jobs is exactly the "two
implementations of one rule" shape the audit brief names.

### O-04 `?join=` consumes the query string before `?claim=` reads it
`index.html:18496` calls `history.replaceState(null, '', pathname)`; the
`?claim=` block (18519) then reads `window.location.search`, which is already
empty. A URL carrying both is silently reduced to the join. Reading both params
once, at the top, before any `replaceState`, removes the ordering coupling.

### O-05 `openLeagueWelcome`'s buy-in line can land in someone else's sheet
`index.html:17966-17977`. `loadBylaws(...).then(…)` does
`document.getElementById('shBody')?.insertAdjacentHTML('afterbegin', …)` with no
check that the welcome sheet is still the open one. Close it fast and open
another during the round-trip and "You're on the pot sheet: $X buy-in." is
prepended to an unrelated sheet. Capture the sheet identity (or read the bylaws
before `openSheet`) instead.

### O-06 `openMembersSheet` prints an invite email unescaped
`index.html:17832`: `<div class="fine">✉ ${i.email} · WAITING</div>`. Only the
Pro can read `invites` for their own league and O-02 shows nothing can write to
it any more, so this is latent rather than live — but it should be `esc(i.email)`
if the table is ever revived.

---

## Not reported (checked, and deliberate or fine)

- `covenantGate` failing **open** when `join_covenant_info` errors — documented
  skew behaviour (setup-QA S3-01); the post-join welcome discloses the pot.
- The `#lockBtn` "ask the server, not the exception" recovery reporting
  `lock_ok` for an already-locked league: that is `lock_league`'s stated
  idempotency contract.
- The demo-mode gates (`state.demo`) that no user path can set true: CLAUDE.md
  D83 says the flag stays as the write-guard on purpose. (B-03 is a *different*
  problem — the flag's **default**, not its guards.)
- `FIRST TEE SUN …` at 17519 hardcodes Sunday against §14.0 v1.1's flexible
  weekday — real, but the line is `loadLeagueRecord`, outside this slice's
  range boundary decisions; noted here so it is not lost.
- `lock_league` leaving a league in `phase='draft'` with no squads when
  `league_settings` has no row (the `update … returning into v_settings` finds
  nothing, `v_settings.structure <> 'solo'` is NULL, `form_squads` is skipped):
  a real hole, but its root is the migration, not this slice.
