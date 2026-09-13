# Stubs in the Cup Season simulation cluster

Cluster: PostgreSQL 17, `/opt/homebrew/opt/postgresql@17/bin`, port 5470, socket `/tmp`,
superuser `sim` (trust), database `cupseason`. Data dir `pgdata/` next to this file.
Rebuild from scratch: `./apply.sh`. Connect: `psql -h /tmp -p 5470 -U postgres cupseason`.
Nothing here reaches the linked Supabase project.

## Filtered lines (apply.sh sed, on the psql stream — migration files never edited)
| Migration | Line | Why |
|---|---|---|
| 00000000000000_initial_baseline.sql | `CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault"` | extension not shipped with Homebrew PG; no migration calls `vault.*` — schema stubbed |
| 20260712110000_enable_cron_spine.sql | `create extension if not exists pg_cron;` | pg_cron not installed; `cron.*` stubbed (below) |
| (none yet) | `create extension if not exists pg_net;` | pattern present defensively; no migration has it |

## bootstrap.sql (runs before the chain, as `sim`)
- Roles: `postgres` (LOGIN superuser, bypassrls — the chain is applied AS postgres so
  `OWNER TO "postgres"` and the SECURITY DEFINER functions match prod ownership),
  `anon`, `authenticated`, `service_role` (bypassrls), `supabase_admin`, `authenticator`. All NOLOGIN except postgres/sim.
  Note: prod's `postgres` is NOT a superuser; here it is, so RLS is bypassed when you run as postgres.
  Impersonate a golfer with `set_config('sim.uid', '<uuid>', false)`; in-body `auth.uid()` checks then behave as prod.
  To exercise RLS itself, `set role authenticated` first.
- Extensions in schema `extensions`: pgcrypto, uuid-ossp, pg_trgm, pg_stat_statements (all real, from contrib).
  `alter database cupseason set search_path = public, extensions` so `gen_random_uuid()`/`digest()`/`gen_random_bytes()` resolve as on Supabase.
- `auth.users` — full column set the migrations touch (id, email, phone, role, aud, instance_id, encrypted_password,
  email_confirmed_at, confirmation_sent_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change, banned_until, ...). Unique index on email.
- `auth.uid()` → `nullif(current_setting('sim.uid',true),'')::uuid`; `auth.role()` → `sim.role` or 'authenticated';
  `auth.jwt()` → `sim.jwt` or '{}'; `auth.email()` → email of auth.uid().
- `storage.buckets` (id, name, public, file_size_limit, allowed_mime_types, ...), `storage.objects`
  (id, bucket_id, name, owner, owner_id, metadata, path_tokens generated, ...), RLS enabled on objects so the 5 real
  storage policies from the migrations attach; `storage.foldername/filename/extension(text)`.
  No object is ever actually stored — the table is just rows.
- `cron.schedule(name, schedule, command)` / `(schedule, command)` → INSERT into a stub `cron.job` table (returns jobid);
  `cron.unschedule(name|jobid)` → DELETE. `cron.job_run_details` exists (empty) so the founder-desk RPCs that read it compile.
  NOTHING RUNS ON A TIMER. The simulator must call `run_month_closes()`, `run_week_snapshots()`, `daily_season_tick()`,
  `run_event_sessions()` itself at the moments the schedule would (07:10 UTC on the 1st, 07:10 Sundays, 07:20 daily, 07:15 daily).
- `net.http_post(url, body, params, headers, timeout_milliseconds)` / `net.http_get(...)` → return 0, do nothing. Not called by any migration.
- `vault.secrets` table + `vault.decrypted_secrets` view (plaintext). Not called by any migration.
- `supabase_migrations.schema_migrations(version, name, statements)` — apply.sh records each applied file.
- Publication `supabase_realtime` (baseline does `ALTER PUBLICATION ... ADD TABLE`); wal_level=logical to keep it quiet. No subscriber.

## post.sql (runs after the chain)
- Trigger `on_auth_user_created AFTER INSERT ON auth.users → public.handle_new_user()`. In prod this trigger was
  created outside the migrations (dashboard); the migrations only define the function and call it "the m001 signup trigger".
  Verified: inserting an auth.users row mints the profile.

## Behaviour differences to keep in mind when simulating
- `postgres` is superuser → RLS/GRANTs are not enforced for the caller unless you `set role`. In-body guards on
  `auth.uid()`, `is_commissioner()`, `founder_id()` DO run as in prod.
- Migrations that `begin; ... commit;` themselves emit "there is already a transaction in progress" warnings under
  psql --single-transaction; harmless, everything commits.
- No email/push/http side effects exist; anything that would have gone out via pg_net or an edge function is a no-op.
