# CLAUDE.md — Cup Season

Season-long fantasy golf for real friend groups. Captains draft squads, everyone
posts real handicapped rounds from anywhere, points accumulate across months, a
Cup Final settles it. The pot is tracked, never held. Live at cupseason.app.

**Owner:** Jerecho (Tempe, AZ) — runs PIGL, the beta league; ~12 index.
**Spec:** `spec/spec-v1.0.md` is the source of truth for every rule. Cite
sections (§2.2, §14.0) when making competition-model decisions.

---

## Working protocol (non-negotiable)

1. **Talk first.** Design decisions accumulate in a punch list. Code is written
   only on an explicit "build it."
2. **One batched version per checkpoint.** Client versions are `v23.NN` shown in
   the sign-in caption — bump it every build. Migrations are numbered `NNN.sql`
   and never edited after they've run in production; fixes get a new number.
3. **Design passes and structural builds ride separately.** (Learned during the
   auth arc: the splash-art pass was pulled while debugging, restored after.)
4. **Everything shows its work.** Spec §16 — no points figure without a path to
   the rounds that produced it. Server posts league events to the board;
   adjustments live in a ledger with reasons; rounds are never mutated.

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
- **Course data:** mScorecard / golfapi.io (CSV import preferred); community
  card templates are the seed strategy (spec §13.1).

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

- Deploy: Netlify (drag `index.html` or CLI once repo is linked).
- Migrations: run in Supabase SQL Editor today; move to
  `supabase db push` once CLI is linked. 001–005 predate this repo — recover
  from saved SQL snippets / prior chats before deleting anything in dashboard.
- pg_cron: NOT yet enabled. When enabling, use migration 006's commented block
  (`run_month_closes`, `run_week_snapshots`, `daily_season_tick`), not m003's.

## State as of v23.32 / migration 007

**Working end-to-end:** email-code auth → golfer card gate → league-less home
(My Golf quick post + recent rounds) → create league → wizard (Blind draw /
Assign) → lock (creates squads via `form_squads`) → join by code → blind draw
(`randomize_squads`, server shuffle, board reveal) / tap-assign → start season
→ quick post writes `rounds`, server scores, board fans out → standings + feed
read the views, realtime on `posts`.

**Still demo/local (honest edges):** deep-stats page, season chart (needs
`standings_snapshots` history), pot screen, board chat *composing* (reading is
real), live rounds & side games (Wolf), attestation taps.

## Punch list (near-term, in rough priority)

1. Wizard: pot/payout-split controls (006 columns exist), darkened prefill on
   league name + commissioner email (auto-fill from session).
2. Commissioner tools: grant bye, void round (ledger + log exist server-side).
3. Board chat composing via `posts` insert.
4. Pot/buy-ins UI on `buy_ins`.
5. Index self-edit (visible in feed — socially policed).
6. Attestation tap on quick posts.
7. Migration 008: fresh-slate Cup Final crowning + §14.3 tiebreak ladder
   (seeds already captured by 006). Design pass needed first.
8. Ball-marker full set (~24 archetype SVGs — named for shapes, never real
   courses: trademark landmine). Starter 8 shipped.
9. Demo diorama: align to Sunday-season model (cosmetic, low priority).
10. PWA manifest + service worker before telling PIGL "add to home screen."
11. Open spec question: hybrid +15 in partial edge months (§14.0 waives floors
    only — decide in spec v1.1).

## Roadmap tiers (spec §11, §15)

Free covers full seasons. Commissioner Pro ($40/season): custom dials, live
draft w/ clock (snake + live draft are schema-ready, UI retired to roadmap),
trades, multi-season history. Verified League ($12/player): GHIN integrity
layer — additive by design, app-computed index is the permanent fallback.
Never resell the Handicap Index (the TheGrint lesson). Clubs/B2B deferred
until two real leagues ask to play each other (§17).
