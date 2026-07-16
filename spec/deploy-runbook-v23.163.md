# Cup Season — Launch Deploy Runbook (v23.163 / migrations …080000–180000)

Clears QA finding **F1** (the real launch gate). The USER runs every
`supabase`/`git` command; the sandbox can't. Do the steps **in order** — the
ordering is chosen so a live user never hits a half-deployed state.

**Golden rule of ordering: DATABASE first, CLIENT last.** The new client calls
new RPCs (handicap engine, match/wolf/skins, endgame crowning). Deploy-skew is
guarded both directions (client drops new fields on a schema-cache error; new
SQL params default), so no order *breaks* — but DB-first means the new shell
never runs against RPCs that don't exist yet. Push/webhook/cron sit in the
middle; they're independent of the client shell.

Sequence: **① db push → ② functions deploy push → ③ push_nudges webhook →
④ git push (client) → ⑤ confirm pg_cron.**

---

## ① `supabase db push` — the migration stack

Applies every pending `20260716xxxxxx` migration in timestamp order. The target
set F1 names is `080000`…`180000`, but a few earlier same-day ones
(`147/151/152/155/157`) are also pending in prod — `db push` will list and apply
them all. That's expected; let it.

```powershell
cd C:\Users\17203\Downloads\cup-season
supabase db push
```

What lands (by file):
- `080000` live-round spine — `start_live_round` / `finish_live_round`
- `090000` live-round `started_by` fix
- `100000` handicap engine — `handicap_index`, `handicap_index_asof`,
  `round_refresh_index`, `set_index`; **runs the one-time index backfill**
- `110000` starter-seed + Pro `set_member_index`
- `120000` index starter guard
- `130000` match play result (finish/start extend)
- `140000` wolf/skins + guest `claim_round` / `claim_round_info`
- `150000` Ryder v2 gaps — `run_event_sessions` (self-schedules the tick),
  `resolve_session`, `generate_pairings`, `create_event`, `add_event_player`
- `160000` Ryder slice 3 — `push_nudges` **table + trigger**,
  `award_event_trophies`, `event_post`, `my_rivalries`, `round_duel_nudge`
- `170000` endgame dial 008 — `set_league_finish`, `close_season` (crowning),
  `award_season_trophies`, `daily_season_tick`
- `180000` auto-bye — `close_month`, `set_member_bye`

**Ordering hazards — checked, none blocking:**
- `run_event_sessions`' cron self-schedule (`150000`) is guarded on pg_cron
  existing; the extension is created back in `20260712110000`, which applies
  first. One push, correct order. ✓
- `close_season` / `daily_season_tick` in `170000` supersede prior versions via
  `create or replace` — no drop/recreate gap. ✓
- No column drop with a dependent RLS policy in this stack (the landmine that
  bit `round_holes`). ✓

### Verify ① (run in the SQL editor, all read-only)

```sql
-- 1. migration history caught up (expect 080000…180000 present)
select version from supabase_migrations.schema_migrations
where version >= '20260716080000' order by version;

-- 2. the new RPCs exist
select proname from pg_proc
where proname in ('start_live_round','finish_live_round','handicap_index',
  'round_refresh_index','set_index','claim_round','run_event_sessions',
  'resolve_session','close_season','set_league_finish','set_member_bye',
  'round_duel_nudge','award_season_trophies')
order by proname;         -- expect all 13

-- 3. the handicap backfill actually ran (no golfer left on a silent default)
--    adjust column name if index_source differs; expect established rows > 0
select count(*) filter (where index_source is not null) as sourced,
       count(*) as total from profiles;

-- 4. push_nudges table + trigger live
select to_regclass('public.push_nudges');                 -- not null
select tgname from pg_trigger where tgname = 'round_duel_nudge_trg';

-- 5. endgame dial column present on the season/league bylaws
--    (finish mode: cup_final vs points_table) — confirm set_league_finish target
select proname, pronargs from pg_proc where proname = 'set_league_finish';
```

If `db push` errors mid-stack, STOP — do not git push. A partial migration
history with a new client live is the one state worth avoiding. Fix forward
with a NEW migration (never edit a pushed file).

---

## ② `supabase functions deploy push`

The fn already carries the `push_nudges` branch and the `x-push-secret` check —
redeploy so prod runs the current build (event fan-out + duel-taunt branch).

```powershell
supabase functions deploy push --no-verify-jwt
```

`--no-verify-jwt` is required — the fn authenticates by shared secret, not JWT
(see `functions/push/index.ts:5`).

### Verify ②
- `supabase functions list` shows `push` with a fresh "updated" timestamp.
- Confirm the secret the webhooks use is set (do NOT print its value):
  ```powershell
  supabase secrets list        # expect PUSH_WEBHOOK_SECRET, VAPID_*, BREVO_*
  ```
- Smoke the EXISTING posts path: post a round in prod → a push fires and
  Function Logs show a non-nudge invocation. (Confirms deploy didn't regress.)

---

## ③ Database Webhook on `push_nudges` INSERT → the push fn

Dashboard → **Database → Webhooks → Create a new hook**. This is the piece the
migration can't create. Without it, duel taunts never fire.

- **Name:** `push_nudges_to_push`
- **Table:** `public.push_nudges`
- **Events:** `INSERT` only
- **Type:** Supabase Edge Function → `push` (or HTTP POST to the function URL)
- **HTTP Headers:** add `x-push-secret` = *the same value as* `PUSH_WEBHOOK_SECRET`
  (identical to the existing `posts` INSERT webhook — copy that hook's header).
- Method `POST`, default timeout.

Mirror the existing `posts` webhook's config exactly except the table/name.

### Verify ③
- Two webhooks now listed: the original `posts` INSERT hook and the new
  `push_nudges` INSERT hook, both **enabled**.
- Live test: run a Ryder duel round that should taunt (or, once, insert a test
  row: `insert into push_nudges(profile_id,title,body) values (<a real
  profile_id>,'test','test');` then delete it). Function Logs should show
  `[push] kind=nudge` (`index.ts:135`). A 401 in logs = header/secret mismatch.

---

## ④ `git push` — client v23.163 → Netlify

Ships the client shell. 4 commits ahead of `origin/main`; all at/above v23.163.
No migration files land here that ① didn't already handle.

```powershell
cd C:\Users\17203\Downloads\cup-season
git push origin main
```

(Local `main` already contains v23.163 — `55616e3`. If your working checkout is
on a `claude/*` branch, still push `main`: `git push origin main`.)

### Verify ④
- Netlify dashboard: build for the new commit **Published**.
- **The diagnostic:** open cupseason.app → the sign-in caption `#obCaption` reads
  **v23.163**. If it still says v23.162, the client didn't deploy (or the SW is
  serving the stale shell).
- **Force the PWA past its SW cache** on every test device: pull-to-refresh, or
  re-add to home screen. `sw.js` `VERSION` is bumped to `v23.163`, so a hard
  reload re-caches — but installed instances hold the old shell until they do.

---

## ⑤ Confirm pg_cron (the self-scheduling jobs)

The month-close, week-snapshot, daily-tick, and Ryder-tick jobs only exist if
pg_cron is enabled. `db push` runs `create extension if not exists pg_cron`, but
if the project never had it permitted, that line no-ops/errs and the tick
silently never schedules.

### Verify ⑤ (SQL editor)
```sql
select * from pg_extension where extname = 'pg_cron';   -- expect one row
select jobname, schedule, active from cron.job order by jobname;
-- expect: cs-daily-tick, cs-month-close, cs-week-snapshot, run_event_sessions
```
If `run_event_sessions` is missing but pg_cron exists, re-run its scheduler once:
```sql
select cron.schedule('run_event_sessions','15 7 * * *',
                     'select public.run_event_sessions()');
```
If pg_cron itself is absent: Dashboard → Database → Extensions → enable
`pg_cron`, then re-run the schedule blocks from `enable_cron_spine` +
`ryder_v2_gaps`.

---

## Post-deploy gate

Prod is launch-ready for the timed walkthrough when ALL are true:
- [ ] `db push` applied through `20260716180000`; the 13 RPCs resolve; backfill ran
- [ ] `push` fn redeployed; secret present; posts-push still fires
- [ ] Both webhooks (`posts`, `push_nudges`) enabled; nudge logs `kind=nudge`
- [ ] cupseason.app `#obCaption` = **v23.163**; PWA reinstalled past SW cache
- [ ] pg_cron present; 4 cron jobs listed & active

Only then run `spec/prelaunch-qa-2026-07-13.md` (the five timed gates).
</content>
