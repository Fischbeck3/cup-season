# CLAUDE.md — Cup Season

Season-long fantasy golf for real friend groups. Captains draft squads, everyone
posts real handicapped rounds from anywhere, points accumulate across months, and
the endgame settles it — a four-week Cup Final or the points table, the Pro's
dial. The pot is tracked, never held. Live at cupseason.app.

**Owner:** Jerecho (Tempe, AZ) — runs PIGL, the beta league; ~12 index.
**Spec:** `spec/spec-v1.0.md` is the source of truth for every rule. Cite
sections (§2.2, §14.0) when making competition-model decisions.

---

## Working protocol (non-negotiable)

1. **Talk first.** Design decisions are logged (see rule 5). Code is written
   only on an explicit "build it."
2. **One batched version per checkpoint.** Every client build bumps BOTH the
   sign-in caption (`#obCaption span:last-child`, `v23.NN`) AND `sw.js`'s
   `VERSION` — together, or the service worker serves a stale shell. Migrations
   are timestamp-named (`YYYYMMDDHHMMSS_slug.sql`) and never edited after they
   run in production; a fix is a NEW migration (a function change is
   `create or replace` in that new file).
3. **Design passes and structural builds ride separately.** (Learned during the
   auth arc: the splash-art pass was pulled while debugging, restored after.)
4. **Everything shows its work.** Spec §16 — no points figure without a path to
   the rounds that produced it. Server posts league events to the board;
   adjustments live in a ledger with reasons; rounds are never mutated.
5. **Log every mechanic change.** Any change to a competition/gameplay mechanic
   gets an entry in `spec/decision-log.md` (hierarchy-of-truth format: current
   mechanic · problem · recommendation · principle served · benefit · tradeoffs,
   + a named CONFLICT line if it collides with a higher level) BEFORE it's built.
   The hierarchy: vision → principles → IA → mechanics → UI → implementation;
   lower levels never silently contradict higher ones.

## Deploy & verify discipline (non-negotiable)

- **Two deploys, always separate.** `supabase db push` ships the DATABASE
  (migrations); `git push` ships the CLIENT (`index.html`/`sw.js` → Netlify).
  They are independent — conflating them cost 14 undeployed client versions
  early on. Claude's sandbox CANNOT run `supabase` (db push / functions deploy /
  secrets) — the USER runs those; state the exact commands in the handoff.
  Diagnostic for "is it live": cupseason.app's `#obCaption` version vs `git log`.
  A change touching both layers needs BOTH pushes; a pure-migration change needs
  no client bump, a pure-client change needs no db push.
- **Deploy-skew safety.** Netlify may serve a new client before its migration
  is pushed (or vice-versa). New RPC args / columns get a client-side retry that
  drops the new field on the "column/function/schema cache" error, and new SQL
  functions default their added params — so neither order breaks a live user.
- **Verify before commit** (when the change is observable in the browser). Serve
  locally (`python -m http.server 8791`), drive the changed flow with the
  browser MCP (`?exit` to reset auth; `javascript_tool` for state — screenshots
  time out on the splash animation), and CLEAR the SW + caches first
  (`getRegistrations().unregister()` + `caches.delete`) or you test a stale
  build. Console must be clean but for the one known pre-existing boot rejection.
- **index.html has MIXED middot encodings** — some template strings carry the
  literal escape `·`, others the real UTF-8 `·`. An Edit that fails "string
  not found" on a middot-containing line usually means the wrong form; anchor on
  adjacent ASCII-only lines instead of fighting it (`cat -A` reveals which).

## Architecture

- **Client:** single-file PWA (`index.html`), dark UI, deployed on Netlify.
  Three script blocks: two classic, one `type="module"` (Supabase client, auth,
  data layer). **Classic ↔ module boundary is a landmine** — module top-level
  names are NOT visible to classic scripts; bridge explicitly via `window.*`
  (see `window.CS`, `window.sb`, `window.renderFormation`). The classic boot
  render chain runs BEFORE the deferred module executes — guard any classic
  reference to module exports with `window.X?.` existence checks.
  A future split into real modules is welcome; preserve the boot semantics.
- **Backend:** Supabase (Postgres + Auth + Realtime). All auth flows through
  helper functions `is_league_member()`, `is_commissioner()`, `my_member_id()`.
  Writes with game consequences go through security-definer RPCs, never direct
  inserts (identity is checked at the database, not by hiding a button).
- **Email:** Brevo SMTP behind Supabase auth. **Code-only OTP templates** —
  both "Magic Link" and "Confirm signup" templates render `{{ .Token }}` and
  contain NO `{{ .ConfirmationURL }}`.
- **DNS:** Porkbun + Netlify. **Payments:** Stripe, parked until launch.
- **Course data:** GolfCourseAPI via the `courses` Edge Function (key held
  server-side); results cached into our own `api_courses`/`api_course_tees`/
  `api_course_holes` tables so play-time reads never hit the third party. Live
  and verified in prod. Per-hole par + handicap (SI) are cached on tee pick.

### Data model in one breath (post-007, profile-first)

Profiles are global (name, city, home course, index, ball marker). **Rounds
belong to profiles** and store only facts: gross, rating, slope, date,
`index_at_post` snapshot, differential (computed by `score_round()` trigger).
Leagues are lenses: `v_rounds_ranked` fans each round into every league the
profile belongs to and scores it through that league's bylaws (allowance %,
eligibility, `cup_points()` bands, counting cap `month_rank`, `floor_credit`).
`v_squad_standings` = counting rounds + `season_adjustments` ledger. The board
(`posts`) is the social spine; `round_to_board()` fans round posts to all
member leagues. `close_month()` (cron) assesses floors/bonuses into the ledger,
idempotent via a `month_closed` sentinel. Cup Final = final 4 weeks scored
fresh; seeds lock in `cup_finalists` when the daily tick flips
`seasons.status → cup_final` at `ends_on − 27`.

### Season shape (spec §14.0)

Seasons start on a **Sunday**, end on a **Saturday**, N months snapped to whole
weeks. Caps/floors are calendar-month machinery; **floors are waived in partial
edge months** (blanket rule, decided). League timezone default
`America/Phoenix` (no DST). Month closes run on the 1st ~00:10 local.

## Landmines (each cost real debugging time — do not relearn)

- **Gmail's link scanner consumes single-use magic-link tokens** before the
  user clicks. Never reintroduce links or `emailRedirectTo`; code-only OTP.
- **Never call Supabase auth methods synchronously inside `onAuthStateChange`**
  — internal auth lock deadlocks with zero error output.
- **`navigator.locks` is origin-wide** — zombie tabs block new ones. Test in
  clean tabs; `/?exit` URL hatch resets.
- **Supabase issues 8-digit OTPs** — no `maxlength="6"` on code inputs, ever.
- **`new Date('YYYY-MM-DD')` parses as UTC midnight** — renders the previous
  day in Phoenix. Always use `localDate()` / manual `y,m-1,d` construction.
  Same for writing: build ISO strings by hand, never `toISOString().slice()`.
- **The m001 signup trigger auto-creates profiles rows** with `display_name`
  derived from the email and a NOT NULL `email` column. Gate onboarding on
  `marker` (only the golfer card sets it). `set_profile()` supplies email from
  `auth.users` itself — never assume the row exists or doesn't.
- **Postgres drops fail on dependent RLS policies** (e.g. `rholes_add` on
  `round_holes` referenced `rounds.member_id`). Tear down policies before
  column drops; recreate replacements after.
- **`verifyOtp` success → `window.location.replace`** for a clean reload; boot
  runs the signed-in path from fresh state. Keep the 8s watchdog, `bootStep`
  breadcrumbs, and the persistent `#errbar` — they have paid for themselves
  repeatedly (most recently surfacing the set_profile NOT NULL error).
- **Demo mode is a diorama** — gate every real-data path with `!state.demo`;
  demo dates are relative (`dAgo`, `M3`) so it never reads stale.
- **Realtime channels live on a DEDICATED client (`rtClient`), not `sb`.**
  Channel joins on the main client fail with `CHANNEL_ERROR — transport
  failure` (verified: raw socket + fresh-client subscribes passed on the same
  machine/token while the app's channel failed; suspected auth-event/join
  race on the busy client). Don't move subscriptions back to `sb`; forward
  tokens to `rtClient.realtime.setAuth` on auth state changes. Also:
  `posts` must stay in the `supabase_realtime` publication, and keep the
  subscribe-status breadcrumb — silent CHANNEL_ERROR cost a full session.
- **A missing `window.*` bridge fails SILENTLY as demo mode.** Classic-side
  guards like `if(window.sb)` don't error when the module never exported the
  name — they quietly take the demo/local path. `window.sb` was missing until
  v23.39; every classic-side DB write (chat, quick post) local-echoed and
  looked exactly like "not saving." When classic code references `window.X`,
  grep for the `window.X =` assignment in the module before trusting it.

## Environments & commands

- **Supabase CLI is linked** (ref `zddbfcokmvneltrgukzf`, repo on GitHub +
  Netlify). Migrations ship via `supabase db push`; Edge Functions via
  `supabase functions deploy <name>`. Use `supabase db dump`, NOT `db pull`.
  The USER runs all of these (sandbox can't) — see Deploy discipline.
- Client: `git push` → Netlify auto-build.
- pg_cron: the cron jobs (`run_month_closes`, `run_week_snapshots`,
  `daily_season_tick`, `run_event_sessions`) self-schedule inside their
  migrations when the extension exists. Confirm pg_cron is enabled in prod, or
  month-closes / week-snapshots / the Ryder tick won't fire.
- **Push:** a Database Webhook on `posts` INSERT → the `push` Edge Function
  (curated by kind + per-user mute flags); a SECOND webhook on `push_nudges`
  INSERT → the same function drives the Ryder duel-taunt opt-in. Both use the
  `x-push-secret` header. Secrets (VAPID, PUSH_WEBHOOK_SECRET, BREVO) live in
  Supabase secrets, NEVER in migrations or chat.

## State as of v23.163 / migrations through `20260716180000`

**Live & working end-to-end** (all real, not demo): email-code auth → golfer
card → league-less home → create league via the rebuilt **wizard** (roster-aware
structure, endgame dial, pot split, fine-print disclosure) → lock → join by code
/ invite link (with the join covenant) → blind draw / assign → season. Posting:
the **hole-by-hole stepper is default** (par-prefilled grid, writes
`round_holes`), gross-only is the escape hatch. Scoring: the **auto-handicap
engine** derives the index from scores (WHS-lite, establishes at 3 rounds; a
manual index is a starter that scores overtake); round cards speak the **named
bands** ("beat your number by X"), never PvI/differential; **receipts** tap from
any points figure. **Tee sheet** live: Match Play (strokes off the low man,
ladder, settlement), Wolf (rotation + comeback + net-zero ledger), Skins
(carry-over) — each posts a board story + settlement card; **guest claim links**
attach a round to a new golfer. **The Ryder** (standalone events) runs
end-to-end: create → roster → sessions self-open/resolve on the tick →
scoreboard, number-to-beat chips, opt-in taunts, MVP + shared trophies, rivalry
duels facet. **Endgame** is a bylaw dial (008): Cup Final OR points-table
crowning, §14.3 tiebreak ladder, trophies + pot settlement post. **Auto-bye**
forgives the first missed floor. Storytelling standings, moments, trophy case,
role-aware Home, curated push — all live.

**Honest edges / not yet done:** photos (own arc, deferred a sprint) · the
captains-pick + snake-draft *engines* (wizard shows the built two + roster-fit
guidance; server-side draft engines unbuilt) · a pre-existing boot-time async
rejection ("reading 'n'") + repeated boot (own task, in progress) · the TIMED
pre-launch QA run (needs prod deployed + human testers — see
`spec/prelaunch-qa-2026-07-13.md`).

**Near-term work lives in the task list, not here** — this file stays
architecture + rules. For "what's next," read the tasks; for "why a mechanic is
the way it is," read `spec/decision-log.md`.

## Monetization (REVISED 2026-07-12 — supersedes spec §6/§11 tiers)

**One general membership.** The Verified League tier is DEAD; GHIN is an
optional reference field on the golfer card, never a paid verification
product. A "Pro" layer for advanced features may come later — until decided,
assume a single catch-all subscription. Never resell the Handicap Index
(the TheGrint lesson). Clubs/B2B deferred until two real leagues ask to
play each other (§17).

**Pricing (PARKED pending focus groups, 2026-07-15):** working model is a
per-league **season pass** paid by the Pro out of the pot (~$49–99/season ≈
$5–8/player — priced against the pot, not against other apps); individual
identity + handicap free forever; live games lean free (the guest-claim funnel).
Decided: **"Founding League" badges** — PIGL + the first ~5–10 leagues free
forever. Open: price point, season-1-free scope, whether the Ryder is ever paid.
Stripe stays parked. Marketing = shareable artifacts (claim link, settlement
card, season recap), foursome-by-foursome, no paid acquisition.

**Product canon:** `spec/product-vision-v1.0.md` (the five principles, the
five-question filter, the Cup Season Test) governs feature decisions
alongside spec-v1.0. `spec/gameplay-modes-working.md` holds the mode designs
with ⚑ decision flags.
