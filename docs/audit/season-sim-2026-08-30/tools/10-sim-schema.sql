-- ============================================================================
-- Season simulator — the harness.  Lives in its own schema so it can never
-- collide with the app's RPC surface or the D37 grant discipline in `public`.
--
-- FIDELITY RULES (the whole point — a sim that builds leagues differently than
-- the app tests nothing):
--   · leagues are born through create_league() and lock_league(), called with
--     the commissioner's own identity via request.jwt.claims, so is_commissioner()
--     and the §15 phase-from-stored-structure law both really run.
--   · rounds are DIRECT INSERTS into public.rounds — which is exactly what the
--     client does (index.html:6830); the score_round trigger fills
--     index_at_post/differential/season_id.
--   · the endgame is driven by calling the engine's own functions in the order
--     the daily tick would have reached them, because the tick keys off the real
--     current_date and cannot be fast-forwarded:
--         weeks 1..N-4  ->  close_month per elapsed month
--         enter_cup_final()   <- seeds lock on REGULAR-SEASON standings only
--         final 4 weeks
--         close_season()
--     Inserting the whole season and then ticking would leak the finale into
--     the seeding, which is not what a real league experiences.
--
-- Randomness is deterministic: derived from hashtext(seed) so a run is exactly
-- reproducible across sessions.  No random(), no setseed().
-- ============================================================================

create schema if not exists sim;
revoke all on schema sim from public, anon, authenticated;

create table if not exists sim.runs (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  cfg         jsonb not null,
  league_id   uuid,
  season_id   uuid,
  created_at  timestamptz not null default now(),
  result      jsonb
);

create table if not exists sim.actors (
  run_id     uuid references sim.runs(id) on delete cascade,
  seat       int  not null,
  profile_id uuid,
  name       text not null,
  archetype  text not null,
  skill      numeric not null,   -- mean differential they truly play to
  vol        numeric not null,   -- sd of that differential
  freq       numeric not null,   -- expected rounds per week
  trend      numeric not null,   -- skill drift per week (negative = improving)
  primary key (run_id, seat)
);

-- standings after each simulated week: the lead-change / excitement record
create table if not exists sim.timeline (
  run_id    uuid references sim.runs(id) on delete cascade,
  week      int  not null,
  level     text not null,          -- 'squad' | 'member'
  entity_id uuid not null,
  label     text,
  points    numeric,
  rank      int
);
create index if not exists timeline_run_week on sim.timeline(run_id, week);

-- ---- deterministic randomness ----------------------------------------------
create or replace function sim.u(p_seed text) returns numeric
language sql immutable as $fn$
  select ((abs(hashtext(p_seed)) % 1000003)::numeric + 0.5) / 1000003.0;
$fn$;

create or replace function sim.norm(p_seed text) returns numeric
language sql immutable as $fn$
  select (sqrt(-2 * ln(sim.u(p_seed || ':a'))) * cos(2 * pi() * sim.u(p_seed || ':b')))::numeric;
$fn$;

-- ---- act as a given profile (so the real RPCs run their real identity checks)
create or replace function sim.as_user(p_uid uuid) returns void
language plpgsql as $fn$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
end $fn$;

-- ---- a cast member -----------------------------------------------------------
-- Normally a real but never-loginable auth user on the unroutable sim domain.
--
-- p_email overrides that with a routable address, which makes the seat an
-- OBSERVER: a human can sign in to it with an email code and see the simulated
-- league from the inside.  That is the only way to screenshot the product from
-- a player's perspective, because the sim cast can never log in by construction.
-- An observer is still a full member of the cast — they post rounds like anyone
-- else, so the standings they are looking at are honest.
create or replace function sim.actor(
  p_run uuid, p_seat int, p_name text, p_archetype text,
  p_skill numeric, p_vol numeric, p_freq numeric, p_trend numeric,
  p_marker text, p_index numeric, p_email text default null
) returns uuid
language plpgsql as $fn$
declare v_uid uuid; v_email text; v_slug text;
begin
  select slug into v_slug from sim.runs where id = p_run;
  v_email := coalesce(nullif(btrim(p_email), ''),
                      's' || p_seat || '-' || v_slug || '@sim.cupseason.test');
  select id into v_uid from auth.users where email = v_email;

  if v_uid is null then
    v_uid := gen_random_uuid();
    insert into auth.users
      (instance_id, id, aud, role, email, encrypted_password,
       email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
       created_at, updated_at,
       confirmation_token, recovery_token, email_change_token_new, email_change)
    values
      ('00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated',
       v_email, '', now(),
       '{"provider":"email","providers":["email"]}'::jsonb,
       jsonb_build_object('display_name', p_name),
       now(), now(), '', '', '', '');
  end if;

  -- discoverable='nobody' so the cast can never surface to a real user
  update profiles
     set display_name = p_name, marker = p_marker, index_current = p_index,
         index_source = 'self', discoverable = 'nobody', city = 'Tempe, AZ'
   where id = v_uid;

  insert into sim.actors (run_id, seat, profile_id, name, archetype, skill, vol, freq, trend)
  values (p_run, p_seat, v_uid, p_name, p_archetype, p_skill, p_vol, p_freq, p_trend)
  on conflict (run_id, seat) do update set profile_id = excluded.profile_id;

  return v_uid;
end $fn$;
