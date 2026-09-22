-- bootstrap.sql — the Supabase surface Cup Season's migrations assume, as STUBS.
-- Runs once, as superuser `sim`, on an empty `cupseason` database. Never touches prod.
\set ON_ERROR_STOP on

-- ---- roles -----------------------------------------------------------------
-- `postgres` is the role the migrations hand ownership to and the role a real
-- migration runs as; it is made a LOGIN superuser here so apply.sh can run the
-- chain AS postgres (ownership then matches production exactly).
do $$ begin
  if not exists (select 1 from pg_roles where rolname='postgres') then
    create role postgres login superuser createdb createrole bypassrls;
  end if;
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname='supabase_admin') then create role supabase_admin nologin superuser; end if;
  if not exists (select 1 from pg_roles where rolname='authenticator') then create role authenticator nologin; end if;
end $$;
grant anon, authenticated, service_role to authenticator;
grant anon, authenticated, service_role to postgres;

-- ---- extensions ------------------------------------------------------------
create schema if not exists extensions;
create extension if not exists pgcrypto      with schema extensions;
create extension if not exists "uuid-ossp"   with schema extensions;
create extension if not exists pg_trgm       with schema extensions;
create extension if not exists pg_stat_statements with schema extensions;
grant usage on schema extensions to postgres, anon, authenticated, service_role;
grant execute on all functions in schema extensions to postgres, anon, authenticated, service_role;
-- Supabase exposes extension functions on the default search_path (gen_random_uuid,
-- digest, gen_random_bytes ...). Put `extensions` there for every role.
alter database cupseason set search_path = public, extensions;

-- ---- auth ------------------------------------------------------------------
create schema if not exists auth;
create table if not exists auth.users (
  instance_id uuid,
  id uuid primary key default gen_random_uuid(),
  aud text, role text,
  email text, phone text,
  encrypted_password text,
  email_confirmed_at timestamptz, confirmation_sent_at timestamptz,
  invited_at timestamptz, last_sign_in_at timestamptz,
  raw_app_meta_data jsonb, raw_user_meta_data jsonb,
  is_super_admin boolean,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  confirmation_token text, recovery_token text,
  email_change_token_new text, email_change text,
  banned_until timestamptz, deleted_at timestamptz,
  is_anonymous boolean default false
);
create unique index if not exists users_email_idx on auth.users(email);
-- the simulator sets `sim.uid` per statement to impersonate a golfer:
--   select set_config('sim.uid', '<uuid>', true);
create or replace function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('sim.uid', true), '')::uuid $$;
create or replace function auth.role() returns text language sql stable as
  $$ select coalesce(nullif(current_setting('sim.role', true), ''), 'authenticated') $$;
create or replace function auth.jwt() returns jsonb language sql stable as
  $$ select coalesce(nullif(current_setting('sim.jwt', true), ''), '{}')::jsonb $$;
create or replace function auth.email() returns text language sql stable as
  $$ select (select email from auth.users where id = auth.uid()) $$;
grant usage on schema auth to postgres, anon, authenticated, service_role;
grant all on auth.users to postgres, service_role;
grant execute on all functions in schema auth to postgres, anon, authenticated, service_role;

-- ---- storage ---------------------------------------------------------------
create schema if not exists storage;
create table if not exists storage.buckets (
  id text primary key, name text not null, owner uuid, owner_id text,
  public boolean default false,
  avif_autodetection boolean default false,
  file_size_limit bigint, allowed_mime_types text[],
  created_at timestamptz default now(), updated_at timestamptz default now()
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text, owner uuid, owner_id text,
  metadata jsonb, path_tokens text[] generated always as (string_to_array(name, '/')) stored,
  version text, user_metadata jsonb,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  last_accessed_at timestamptz default now()
);
alter table storage.objects enable row level security;
create or replace function storage.foldername(name text) returns text[] language plpgsql immutable as $$
declare _parts text[];
begin
  select string_to_array(name, '/') into _parts;
  return _parts[1:array_length(_parts,1)-1];
end $$;
create or replace function storage.filename(name text) returns text language plpgsql immutable as $$
declare _parts text[];
begin
  select string_to_array(name, '/') into _parts;
  return _parts[array_length(_parts,1)];
end $$;
create or replace function storage.extension(name text) returns text language sql immutable as
  $$ select reverse(split_part(reverse(storage.filename(name)), '.', 1)) $$;
grant usage on schema storage to postgres, anon, authenticated, service_role;
grant all on all tables in schema storage to postgres, service_role;
grant select, insert, update, delete on storage.objects to authenticated;
grant select on storage.buckets to anon, authenticated;
grant execute on all functions in schema storage to postgres, anon, authenticated, service_role;

-- ---- cron (pg_cron stand-in) ----------------------------------------------
-- `create extension pg_cron` is filtered out by apply.sh; the schedule calls land
-- here and are recorded in cron.job so founder-desk views can read them. Nothing
-- ever RUNS on a timer — the simulator calls run_month_closes() etc. itself.
create schema if not exists cron;
create table if not exists cron.job (
  jobid bigserial primary key, schedule text, command text,
  nodename text default 'localhost', nodeport int default 5470,
  database text default 'cupseason', username text default 'postgres',
  active boolean default true, jobname text unique
);
create table if not exists cron.job_run_details (
  jobid bigint, runid bigserial primary key, job_pid int, database text, username text,
  command text, status text, return_message text,
  start_time timestamptz, end_time timestamptz
);
create or replace function cron.schedule(job_name text, schedule text, command text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  insert into cron.job (jobname, schedule, command) values (job_name, schedule, command)
  on conflict (jobname) do update set schedule = excluded.schedule, command = excluded.command
  returning jobid into v;
  return v;
end $$;
create or replace function cron.schedule(schedule text, command text)
returns bigint language plpgsql as $$
declare v bigint;
begin
  insert into cron.job (schedule, command) values (schedule, command) returning jobid into v;
  return v;
end $$;
create or replace function cron.unschedule(job_name text) returns boolean language plpgsql as $$
begin delete from cron.job where jobname = job_name; return found; end $$;
create or replace function cron.unschedule(job_id bigint) returns boolean language plpgsql as $$
begin delete from cron.job where jobid = job_id; return found; end $$;
grant usage on schema cron to postgres;
grant all on all tables in schema cron to postgres;
grant all on all sequences in schema cron to postgres;

-- ---- net (pg_net stand-in; not called by any migration, present for safety) --
create schema if not exists net;
create or replace function net.http_post(url text, body jsonb default '{}'::jsonb, params jsonb default '{}'::jsonb,
                                         headers jsonb default '{"Content-Type":"application/json"}'::jsonb,
                                         timeout_milliseconds int default 5000)
returns bigint language sql as $$ select 0::bigint $$;
create or replace function net.http_get(url text, params jsonb default '{}'::jsonb, headers jsonb default '{}'::jsonb,
                                        timeout_milliseconds int default 5000)
returns bigint language sql as $$ select 0::bigint $$;
grant usage on schema net to postgres;

-- ---- vault (supabase_vault stand-in; `create extension supabase_vault` is filtered) --
create schema if not exists vault;
create table if not exists vault.secrets (
  id uuid primary key default gen_random_uuid(), name text unique, description text default '',
  secret text, key_id uuid, nonce bytea, created_at timestamptz default now(), updated_at timestamptz default now()
);
create or replace view vault.decrypted_secrets as
  select id, name, description, secret, secret as decrypted_secret, key_id, nonce, created_at, updated_at from vault.secrets;
grant usage on schema vault to postgres;

-- ---- supabase_migrations ---------------------------------------------------
create schema if not exists supabase_migrations;
create table if not exists supabase_migrations.schema_migrations (
  version text primary key, name text, statements text[]
);

-- ---- misc Supabase conventions --------------------------------------------
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on schema public to postgres;

-- ---- realtime --------------------------------------------------------------
-- the migrations `alter publication supabase_realtime add table ...`; nothing listens here.
create schema if not exists realtime;
create publication supabase_realtime;
