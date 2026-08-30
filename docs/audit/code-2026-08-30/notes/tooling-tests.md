# Slice: tooling & tests

`tests/preflight.mjs` · `tests/db-checks.sql` · `tests/app-tests.js` · `tools/*.mjs` ·
`tools/ship.sh` · `stamp-version.sh` · `netlify.toml` · `sw.js` ·
`manifest.webmanifest` · `legal.html`

Read in full (2,240 lines), plus the files they read: `packages/tokens/tokens.json`,
`packages/db/contract.psv`, `tests/fixtures/no-undef-staged.js`, `.claude/settings.json`,
`.well-known/apple-app-site-association`, `.gitignore`, `package.json`, `brand/`.
Everything was verified by RUNNING it: `node tests/preflight.mjs`, `./tools/ship.sh
--dry-run`, `node tools/deploy-status.mjs --hook`, `supabase db query --linked -f
tests/db-checks.sql` (read-only), plus targeted read-only SELECTs against prod.

Current state: preflight **PASS, 0 failures, 1 warning**. db-checks: **17 checks,
2 FAIL** (15 lock health, 16 formation invariant), no query errors.

---

## The short version

The suite is unusually good — every check is a paid-for lesson and most of them carry
their own history in a comment. What it does *not* do is test itself. Nine of the
twenty preflight checks and three of the seventeen db-checks have a false negative I
could construct, and in three cases I could construct one that is **live in prod right
now**. The pattern is consistent: a check is written against the shape of the one bug
that caused it, and the shape next door goes unseen.

Three findings are worth acting on today because they are not hypothetical:

1. **db-checks 16 reports 1 league; prod has 3 more it structurally cannot see, plus
   4 more of the case its own failure message names.** Verified by query.
2. **db-checks 3's hand-typed array has drifted from the client — 8 RPCs unchecked**,
   three of them added in this session's commits.
3. **preflight check 11 is telling you to `db push` something that is already in
   prod**, in the same `ship.sh` run where `deploy-status` correctly says the database
   is clean. The real state is a stale `packages/db/contract.psv`, which nothing checks.

---

## preflight.mjs, check by check

**1 · version placeholders.** Correct and cheap. Counts only; a placeholder moved to
the wrong line still passes, but the substitution failing is caught by
`stamp-version.sh:51` at build time, so the layering is fine.

**2 · rpc grant coverage.** Role-blind, revoke-blind, comment-blind. The regex is
`grant (all|execute) on function <name>` with no `to <role>` clause, so
`grant execute on function foo() to service_role;` satisfies it, a later
`revoke execute … from authenticated` does not unsatisfy it, and the same text inside a
`--` comment counts. I scanned the corpus: no live instance of any of the three
(every grant in `supabase/migrations/` today names `authenticated` or `anon`, and the
revoke/re-grant pairs are the safe idiom). Latent.

**3 · window.* bridge coverage.** Two over-excusals, both of which defeat the check's
own purpose.
- Line 66 adds every classic top-level `let`/`const` to `assigned`. Those are **not**
  window properties. `const CS = {…}` at classic top level + `window.CS.league`
  elsewhere = PASS + runtime TypeError.
- The function-declaration regex is `^\s*(?:async\s+)?function` — leading whitespace
  allowed — so it also collects **nested** function declarations. I counted **34**
  names that are only ever declared inside another function (`toast`, `refresh`,
  `start`, `stop`, `kill`, `show`, `trace`, …). A `window.toast(…)` in an `onclick=`
  string would pass this check and be `undefined` at runtime.
  No live instance today (I checked all 194 bridged names), but the 14 inline
  `onclick="window.X(…)"` handlers in the file are exactly the code this check is the
  only defence for.

**4 · sw shell within dist allowlist.** Works — its continuation-aware regex reads both
lines of the `cp`. Note it would *false-FAIL* if a SHELL entry ever moved under
`cp -r brand`, since `cpLine` deliberately excludes `-r` lines.

**5 · OTP maxlength.** Requires `one-time-code` and `maxlength` in the same tag.
`el.maxLength = 6` in JS, or a bare `<input inputmode="numeric" maxlength="6">`, is
invisible. No live instance.

**6 · script blocks parse.** Correct, and the tmpdir `.js`/`.mjs` split is right
(the repo root's `"type": "module"` doesn't reach `os.tmpdir()`). Two coverage holes
shared with 3 and 18: the tag regex only matches bare `<script>` and
`<script type="module">` — **any** added attribute silently removes a block from all
three checks — and blocks under 100 characters are skipped outright.

**7 · esc() sink heuristic.** Honestly labelled a WARN, but narrower than it looks: it
is a **single-line** regex (`[^\n]*$`), and **24 of the file's 188 `innerHTML`
assignments open a template literal that continues on later lines**. Everything past
line 1 of those is invisible, as is the very common `el.innerHTML = builtString`. The
field list (`name|title|body|display_name|city|label`) also omits `note`, `msg`,
`handle`, `reason`, `comment`. I ran a widened version: one hit, `p.marker` routed
through `mkr()`, which is safe. No live XSS found — the coverage is the finding.

**8 · dist allowlist files exist.** **Broken.** `^cp (?!-r).*$` is line-anchored and
the allowlist `cp` spans two lines with a backslash continuation, so the check only
sees the first line. It reports "5 files"; the allowlist has **9**.
`icon-192.png`, `icon-512.png`, `icon-512-maskable.png` and `og-image.png` are never
existence-checked. Ironic detail: check 4, ten lines above, already has a
continuation-aware `cpLine` — this check just doesn't use it.

**9 · AASA.** Genuinely good. Cross-checks the Team ID shape, the bundle id against
`apps/ios/project.yml`, the modern `appIDs`+`components` form, a query matcher on every
component, and the copy into `dist/`. I verified the live file satisfies all five.

**10 · design tokens single-source.** Holds `index.html` to `tokens.json` in both
directions. It does **not** cover `legal.html`, which is the repo's other shipped HTML
page — see the legal.html section below.

**11 · rpc exists in database.** Right now this WARNs *"owe a db push:
`set_buy_in_terms`"*. That is wrong. `20260830040000_buy_in_terms.sql` is applied in
prod, `set_buy_in_terms(p_league uuid, p_note text, p_due_on date)` exists, and
`has_function_privilege('authenticated', …)` is true — all verified by query. What is
actually stale is `packages/db/contract.psv`, the hand-refreshed snapshot the check
reads as "prod". Two consequences:
- `ship.sh` prints preflight's "owe a db push" and `deploy-status`'s "138 migrations
  applied, none pending" **in the same run**, ten lines apart.
- Nothing detects a stale `contract.psv` — and `Rpc.swift`, the artefact that makes
  D37 "enforced by the compiler", is generated from it. The phone currently has no
  `Rpc.set_buy_in_terms` for a function that is live and granted.
  `deploy-status.mjs` already knows the real answer; preflight could ask it.

**12–17 · the two phones.** Well-constructed. 15's rule (a hex outside `Generated/` is
legal only if the same hex appears in `index.html`) is a genuinely clever way to say
"convert, never invent". 16's `exempt` flag correctly scopes the auth exemption to the
two auth-home files. No findings.

**18 · free identifiers (the `staged` lint).** The best new check here — acorn +
eslint-scope, a self-test fixture that fails loudly if the checker stops working, and a
WARN (never a PASS) when the dev deps are absent. One structural blind spot, and it is
the important one: **`bridged` exempts every `window.X =` name globally, for every
block.** I demonstrated it — scanning a classic block containing
`function onLockTap(){ return lockBylaws(); }` and
`function other(){ return neverDeclaredAnywhere(); }` reports only
`neverDeclaredAnywhere`. `lockBylaws` is module-scoped and reachable *only* as
`window.lockBylaws`; a classic block calling it bare is a guaranteed ReferenceError,
and it is one of **181** names silently exempted this way. That is the classic↔module
landmine CLAUDE.md leads with. Two smaller ones: a `typeof X` anywhere in a block
exempts X for the whole block (documented, deliberate), and free identifiers inside
`onclick="…"` strings are string literals to acorn (check 3 is the only cover there —
see check 3's over-excusals).

**19 · join paths carry consent.** Currently correct: 5 `join_league` calls at
16065/16232/18048/18180/18243, each preceded by an awaited, result-checked
`covenantGate()` at 16064/16231/18046/18173/18237. But the check is
`gates >= joins` — a **count**, not a pairing. Deleting the gate on the invite-link
boot path and adding two calls anywhere else still passes. It also only matches
single-quoted `rpc('join_league'`, and a `covenantGate(` inside a comment inflates the
gate count.

**20 · stage vocabulary shared.** The tables agree (6 stages, verified by eye). Two
issues: it gates on `existsSync(LeagueCopy.swift)`, not on `apps/ios/`, so **renaming
or moving that one file makes the check print "apps/ios absent — skipped" and PASS**
while `apps/ios` sits right there — unlike checks 12–17, which gate on the directory.
And it compares only the six label *strings*; the two derivations (`leagueStage(m)` on
the web, `LeagueCopy.stage(_ c: RoomClock)` on the phone) are still two implementations
of one rule and can disagree about which stage a league is in while agreeing on what to
call it.

---

## db-checks.sql

Ran clean end to end (no 42703-style whole-query error — the 2026-07-28 lesson holds).

**Check 16 · formation invariant — misses more than it catches.** Verified live:

| | count |
|---|---|
| what check 16 reports | **1** |
| leagues in `phase='season'` with **zero** squads | **3** |
| leagues in `phase='season'` with a member in no squad | **4** |

`join squads q on q.season_id = s.id` is an inner join, so a league that never formed
any squad produces no row and cannot be counted — and that is a *worse* §15 violation
than an empty squad. The `having` clause never looks at `league_members` at all, yet
the failure message reads *"…with an empty squad **or an unseated member**"*. The
check states two invariants and evaluates neither of the two extra cases.
(Some of these rows may be the audit footprint the header says is unwiped; the
structural blindness is independent of that.)

**Check 3 · authenticated RPC grants — drifted.** The array holds **108** names while
the header and the PASS string both say 105. Eight RPCs the web client calls are not in
it:

    cup_final_race · guest_live_set_score · guest_live_set_wolf · guest_live_state
    lock_league · log_growth_event · set_buy_in_terms · unregister_device_token

Three of those (`lock_league`, `set_buy_in_terms`, `cup_final_race`) were added by
this session's commits — i.e. the newest RPCs, the ones most likely to have missed a
grant, are the ones the check is blind to. All eight *are* granted today (verified),
so this is a missing guard rather than a live 403. Nine names in the array are
phone-only and no longer called by the web client, which is deliberate (IOS-009).

**Check 3 has no `extra` half.** Check 2 asserts anon can execute *exactly* twelve
functions — missing **and** unexpected. Check 3 only asserts "these are granted", so a
function accidentally granted to `authenticated` is invisible unless it is one of the
three names hardcoded in check 12. That is precisely how `close_month`'s grant crept
back via `20260727160000:341` — the incident check 12's own comment describes. A
denylist of three was built where check 2's allowlist shape was already sitting in the
same file.

**Check 15 · lock health.** Correct, and currently FAILing honestly: *"11 lock_fail(s)
carrying a JavaScript reference error in 7d — a shipped bug: staged is not defined"*.
That is true — this session's fix is committed but the client is not deployed. Two
notes: the ratio arm (`attempts >= 3 and fails > oks`) would have stayed silent through
much of the real D97 incident (1 ok vs 11 fail spread over 25 days ≈ 0.4/day, i.e. ~3
attempts per 7-day window); and the `js_errs` arm watches only `lock_fail`. The same
post-commit JS throw on `start_season`, `form_squads` or `create_league` is unwatched.
`client_events` already stores a 4-frame stack for every uncaught error — a generic
"any `client_events` row in 7d whose `msg` names a reference error" check would cover
the whole class instead of one flow.

**Check 2 / 3 / 12 overload blindness.** All three match on `proname` only, so a second
overload of an allowlisted name granted to `anon` is not "extra", and one granted
overload satisfies "missing" for every signature. Narrow, latent.

**Check 6** proves `relrowsecurity` is on, not that the policies are restrictive — a
`using (true)` policy passes. **Check 11** covers `relkind='v'` only; a materialized
view granted to `authenticated` would be missed (there are none today).
**Check 14**'s policy branch isn't schema-scoped. All minor.

---

## app-tests.js

Good tests — the band suite (lines 41–52) sweeps −6.00…+6.00 in 0.01 steps and pins
`bandName` to `pointsFor`, which is exactly the right shape for the Q-20 disagreement,
and `db-checks 17` pins the engine to the same boundary. All nine globals it calls
(`esc`, `localDate`, `durMonths`, `bandName`, `vsPhrase`, `pointsFor`, `fmtIdx`,
`humanError`, `csOdo`) are classic-block declarations, and the two lock functions are
module-scoped but bridged at `index.html:16159`. Verified.

**The lock block's assertions never reach the summary.** Lines 92–113 are async; the
summary and the return value are computed synchronously at lines 115–117. The two
`t()` calls inside `.then` push into `R` afterwards. So `{ total, failures }` — the
thing a browser-MCP driver or a QA script actually reads — **cannot fail on the lock
test**. The comment at line 111 notes the lines "print after the summary" but not that
they don't count. Given this block exists specifically to catch the Q-01 regression
that ran 25 days, a silent-pass harness is the wrong failure mode.

Smaller: the `.catch` at 106 is named "share sheet opens without throwing" but also
catches throws from inside the `.then`, mislabelling an assertion failure; the fake
`CS.league = {id:'l1', name:'Test Cup'}` and `state.demo = false` stay installed until
the promise settles, and forever if it never does; and `t('csOdo: same value is a
no-op', el.dataset.odo, '$600')` would pass whether or not csOdo actually no-ops.
`t()`'s `JSON.stringify` fallback also treats `NaN` as equal to `null`.

---

## deploy-status.mjs / ship.sh

The `migration list` parser is **correct** — I checked the raw bytes of the 2.116 text
output: no leading pipe, so `cols[0]=Local, cols[1]=Remote` is right. The
`--output-format text` fix is load-bearing and present.

**`client()` counts untracked files as owed, and the Stop hook fires on them.**
`git status --porcelain` includes `??` entries. Running the hook right now:

    {"systemMessage":"Deploys owed — client: 1 uncommitted change.  Run ./tools/ship.sh"}

…for an untracked `docs/audit/code-2026-08-30/` directory. Nothing is owed. This repo
generates audit/notes directories as a matter of routine, so the hook that is supposed
to be "silent unless something is genuinely owed" will speak on most sessions — the
exact tune-out failure the file's own comment at line 137 warns about.

**`ship.sh` inherits it and refuses the client push entirely.** Line 88's
`[[ -n "$(git status --porcelain)" ]]` blocks the push for an untracked scratch file,
prints RED "commit them first", and exits 0. Untracked files have no bearing on what
Netlify builds. `--untracked-files=no` (or scoping to the served files) is the fix.

**`client()` can report `clean` because it could not look** — contradicting the header's
"a false all-clear is worse than no answer". `run()` swallows every git failure into
`null`; if `origin/<branch>` doesn't exist (a never-pushed branch), `unpushed` is
`null` and simply contributes nothing. `origin/main...HEAD` is also never `fetch`ed, so
a stale local `origin/main` inflates "N commits not on main" indefinitely.

**ship.sh's refusal paths, one by one.** Preflight → hard `exit 1`, correct. Database
`owed` → typed `push` confirmation, correct. Database `unknown` → RED warning but
**continues** to the client push. Functions `unknown` → **nothing at all**; only
`maybe` is handled, so the asymmetry with the database branch is unexplained. Dirty
tree → refuses the client but exits 0. And `have()` returns 1 both when the state
doesn't match *and* when the JSON fails to parse, so a malformed `--json` would skip
all three sections and print "done" (unreachable today — `set -e` aborts the assignment
if the tool crashes — but the conflation is there).

Minor: `--json` drops `functions.command` (a function value, `JSON.stringify` elides
it); `deploy-status` runs twice per ship (four network round-trips); the Stop hook's
30 s timeout is under the tool's 8+20+20 s worst case, and a kill is indistinguishable
from silence because of the `|| true`.

`build-db.mjs` / `build-markers.mjs` / `build-tokens.mjs` are sound. One silent hole:
`build-tokens.mjs:74` defines a colour as `/^#[0-9a-f]{6}$/i`, so a token written `#fff`
or `#rrggbbaa` is dropped from `CSPalette`/`Tokens.swift` without a word. Check 10
compares index.html↔tokens.json and generated↔generated; neither notices the phone is
missing a colour. `build-db.mjs:47` and `:214` both index a regex match without a null
guard, so an unusual `pg_get_function_arguments` shape (an unnamed or `INOUT` arg)
crashes — and under preflight's `--check` that surfaces as the misleading
"rpc.ts is stale". Overload collapse (`:67`) picks the widest by **arg count**, so two
same-arity overloads resolve by file order.

---

## The published surface

**`stamp-version.sh:40` — `cp -r brand "$DIST/brand"` publishes an internal design
sub-project.** 36 files: `brand/README.md` (internal brand strategy and decision
history), and all of `brand/ember-logo-system/` — `package.json`, `package-lock.json`,
`tsconfig.json`, `src/*.ts`, `test/*.test.ts`, `.gitignore`, `masters/**/*.svg` and a
`contact-sheet.html` that will render as a page at `cupseason.app/brand/…`. Nothing in
`index.html` or `legal.html` references `brand/` at runtime — the only occurrence is a
comment at `index.html:13`. This is a miniature of the leak OPS-C7 closed, in the file
whose header says *"Nothing else can ever be served"*, and preflight check 8
deliberately skips `cp -r` lines so nothing validates it.

**No secrets or third-party PII.** I grepped every served file for service-role keys,
Stripe keys, `ANTHROPIC_API_KEY`, Brevo/`xkeysib`, VAPID and JWTs: clean. Every email
address in the 663 tracked files is the owner's own or a `+blind` test alias.
`.gitignore` correctly quarantines root-level `*.sql` dumps, `.env`, and
`node_modules/` (0 tracked files under it, verified).

**Headers and CSP.** The five security headers are all safe to enforce. I traced every
origin the app can reach and the Report-Only CSP would survive being flipped to
enforcing today: the only cross-origin script is
`import … from 'https://esm.sh/@supabase/supabase-js@2'` (allowed); fonts are exactly
one Google Fonts family (`style-src` + `font-src` cover it); no `eval`, no
`new Function`, no `new Worker`, no `importScripts`, no `<iframe>`, no `<form>`; the
five `URL.createObjectURL` sites are two `img.src` (covered by `img-src blob:`) and
three `<a download>` blob links, which no directive here blocks. Two latent traps:
`font-src` omits `'self'`, so the day Plex Mono is self-hosted (which `tools/fonts/`
in .gitignore anticipates) enforcement breaks it silently; and `media-src` /
`manifest-src` are only covered by `default-src 'self'`, so any Supabase-hosted audio
or video would break.

**sw.js.** The SHELL is a strict subset of the allowlist (verified). The
network-first-navigations / cache-first-assets split is right, and the
`url.pathname === '/'` guard on the shell write is a real fix for a real bug. Two
notes. `install` chains `skipWaiting()` **after** `addAll(SHELL)` — `addAll` is
all-or-nothing, so one 404 among the five rejects the install and the new worker never
takes over (it self-heals on the next visit once the asset returns, and navigations
stay network-first meanwhile, so it degrades to "the SW silently stops updating"
rather than a broken app). And any successful `/` navigation is cached as the offline
shell, including `/?share=TOKEN` responses that the `share-preview` edge function has
rewritten with per-token OG tags — harmless today because it only touches `<meta>`.

**legal.html is off the design system.** Its dark palette is a different colour family
from the app's: `--bg:#0C0D0F` and `--panel:#17191C` against `tokens.json`'s
`bg0 #0B1410` / `bg1 #131D17` (and `--gold:#FF5A2E` is the `hot` heat token, not
`gold #D8B25A`). `tokens.json`'s own note on `bg0` reads *"converges meta/favicon/legal"*
— `index.html:6` and the manifest's `theme_color` did converge on `#0B1410`; legal.html
did not. A golfer tapping Privacy from the dark app crosses a visible seam.
Preflight check 10 reads only `index.html`, so the repo's other shipped page is
unchecked. Its inline theme script is also still commented *"the light-first app"*,
which D76 retired.

---

## What I could not assess

- Whether `supabase functions list`'s timestamp column is UTC. `deploy-status.mjs:88`
  appends `Z`; if the CLI prints local time, every function reads ~7 h stale in
  Phoenix. It is explicitly advisory and it currently reports "none look stale", so I
  left it alone rather than call a deploy against prod.
- Runtime behaviour of `app-tests.js` — it needs a served app and a browser, and this
  audit is read-only. The reasoning above is from the source and from confirming every
  global it names exists at the right scope.
- Whether the 3 zero-squad and 4 unseated-member leagues in check 16's blind spot are
  real leagues or the blind-audit footprint the header says is unwiped. The structural
  gap holds either way.
