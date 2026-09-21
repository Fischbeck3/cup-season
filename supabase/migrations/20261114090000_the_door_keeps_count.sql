-- ============================================================================
-- Cup Season · 20261114090000 · the door keeps count
--
-- D371 (owner-ruled 2026-09-21: the door is public on October 1) carried this
-- in its own cost line — the anon surface has no throttle of its own beyond
-- Supabase's platform limits, and a public door is what makes that matter.
-- This is the smallest honest version, scoped to the two anon endpoints whose
-- input can be guessed or spammed:
--
--   · league_by_code — a code is short and a name comes back; 60 lookups per
--     ten minutes per caller is more than any real join and far under an
--     enumeration.
--   · log_growth_event — a signed-out write; 120 per hour per caller on top of
--     the per-token cap it already carries. Its own `exception when others
--     then return` swallows the refusal, which is right: a breadcrumb never
--     breaks a door.
--
-- Token-keyed endpoints (claim_round_info, scan_claim_info, share_info, the
-- guest_live_* trio, email_unsubscribe) are left alone: their input is an
-- unguessable UUID and D57 already makes every dead token answer the same.
-- join_covenant_info is code-keyed but `language sql`; gating it means
-- rewriting it, which is a separate, reviewed change if the pilot shows need.
--
-- THE KEY is a hash of the forwarded address the API gateway supplies in
-- `request.headers` (x-forwarded-for, else x-real-ip). It is never stored in
-- clear. When there is NO request context — psql, cron, the sandbox harness,
-- a gateway that does not forward the address — the gate does nothing: a
-- limiter that cannot identify a caller must never close the door on all of
-- them. The gate also never raises anything but its own refusal; any other
-- error inside it is swallowed and the call proceeds.
--
-- The table lives in `cupseason_private` (the 20261021090000 precedent): no
-- client role can read or write it, RLS is on with no policies, and rows older
-- than a day are pruned opportunistically from inside the gate.
--
-- VERIFY: tests/sim/sandbox/apply.sh (the gate is a no-op there — no request
-- context — so the harness's calls pass unchanged); after the push, one real
-- PostgREST call to league_by_code from a phone confirms the header is seen
-- (a 61st call in ten minutes is refused; a row appears in door_attempts).
-- ============================================================================

create schema if not exists cupseason_private;
revoke all on schema cupseason_private from public, anon, authenticated;

create table if not exists cupseason_private.door_attempts (
  scope text        not null,
  key   text        not null,   -- md5 of the forwarded address; never the address
  at    timestamptz not null default now()
);
create index if not exists door_attempts_scope_key_at
  on cupseason_private.door_attempts (scope, key, at);
-- CC-52 / preflight 50: a new table states its own grants — revoke, then none.
revoke all on cupseason_private.door_attempts from public, anon, authenticated;
alter table cupseason_private.door_attempts enable row level security;

-- ── the gate ─────────────────────────────────────────────────────────────────
create or replace function public._door_gate(p_scope text, p_limit integer, p_window interval)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_hdr text; v_ip text; v_key text; v_n integer;
begin
  begin
    v_hdr := current_setting('request.headers', true);
  exception when others then
    v_hdr := null;
  end;
  if v_hdr is null or v_hdr = '' then return; end if;          -- no request context: nothing to key on
  v_ip := nullif(btrim(split_part(coalesce(v_hdr::jsonb ->> 'x-forwarded-for',
                                            v_hdr::jsonb ->> 'x-real-ip', ''), ',', 1)), '');
  if v_ip is null then return; end if;                          -- gateway did not forward it
  v_key := md5(v_ip);

  select count(*) into v_n
    from cupseason_private.door_attempts
   where scope = p_scope and key = v_key and at > now() - p_window;
  if v_n >= p_limit then
    raise exception using errcode = 'P0429',
      message = 'Too many tries from here. Give it a few minutes.';
  end if;

  insert into cupseason_private.door_attempts (scope, key) values (p_scope, v_key);
  if random() < 0.02 then
    delete from cupseason_private.door_attempts where at < now() - interval '1 day';
  end if;
exception
  when sqlstate 'P0429' then raise;                             -- our own refusal is the one thing that escapes
  when others then return;                                      -- a broken limiter never closes the door
end $$;
revoke all on function public._door_gate(text, integer, interval) from public, anon, authenticated;

-- ── league_by_code, counted ──────────────────────────────────────────────────
-- The body is the same one line; plpgsql so the gate can run first. It was
-- `stable`; a counted door is not, and both clients call it through POST.
create or replace function public.league_by_code(p_code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  perform _door_gate('league_by_code', 60, interval '10 minutes');
  return (select name from leagues where upper(code) = upper(p_code) limit 1);
end $$;
revoke all on function public.league_by_code(text) from public;
grant execute on function public.league_by_code(text) to anon, authenticated;

-- ── log_growth_event, counted ────────────────────────────────────────────────
-- Patched in place from the live definition (20261102090000's pattern): the
-- gate is the first statement after `begin`; the function's own catch-all
-- turns a refusal into the silent no-op it already is for every other error.
do $patch$
declare v_def text; v_new text; v_oid oid; v_n integer;
begin
  select count(*) into v_n from pg_proc where proname = 'log_growth_event' and pronamespace = 'public'::regnamespace;
  if v_n <> 1 then raise exception '[D371] log_growth_event has % definitions; expected one', v_n; end if;
  select oid into v_oid from pg_proc where proname = 'log_growth_event' and pronamespace = 'public'::regnamespace;
  v_def := pg_get_functiondef(v_oid);
  if position('_door_gate(' in v_def) > 0 then
    raise notice '[D371] log_growth_event already counts'; return;
  end if;
  if position('begin
  -- unknown node: silent no-op (never an error a probe could read)' in v_def) = 0 then
    raise exception '[D371] log_growth_event: the opening lines were not found';
  end if;
  v_new := replace(v_def,
    'begin
  -- unknown node: silent no-op (never an error a probe could read)',
    'begin
  perform _door_gate(''growth'', 120, interval ''1 hour'');   -- D371 · a public door keeps count
  -- unknown node: silent no-op (never an error a probe could read)');
  if position('exception when others then' in v_new) = 0 then
    raise exception '[D371] log_growth_event lost its catch-all; a refusal would break a door';
  end if;
  execute v_new;
end $patch$;

-- ── self-check (read-only; mutates no row) ───────────────────────────────────
do $chk$
declare v_src text;
begin
  if to_regclass('cupseason_private.door_attempts') is null then
    raise exception '[D371] door_attempts is missing';
  end if;
  if has_any_column_privilege('anon', 'cupseason_private.door_attempts', 'SELECT')
     or has_any_column_privilege('authenticated', 'cupseason_private.door_attempts', 'SELECT')
     or has_table_privilege('authenticated', 'cupseason_private.door_attempts', 'INSERT')
     or has_table_privilege('authenticated', 'cupseason_private.door_attempts', 'TRUNCATE') then
    raise exception '[D371] a client role can reach door_attempts';
  end if;
  if not exists (select 1 from pg_class where oid = 'cupseason_private.door_attempts'::regclass and relrowsecurity) then
    raise exception '[D371] door_attempts has RLS off';
  end if;
  if exists (select 1 from pg_proc p where p.proname = '_door_gate' and p.pronamespace = 'public'::regnamespace
                and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))) then
    raise exception '[D371] _door_gate is reachable by a client role';
  end if;
  select prosrc into v_src from pg_proc where proname = 'league_by_code' and pronamespace = 'public'::regnamespace;
  if v_src not like '%_door_gate(%' or v_src not like '%upper(code) = upper(p_code)%' then
    raise exception '[D371] league_by_code is not counted, or lost its lookup';
  end if;
  if not exists (select 1 from pg_proc p where p.proname = 'league_by_code' and p.pronamespace = 'public'::regnamespace
                    and has_function_privilege('anon', p.oid, 'execute')
                    and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D371] league_by_code lost a grant (the anon surface is exactly twelve)';
  end if;
  select prosrc into v_src from pg_proc where proname = 'log_growth_event' and pronamespace = 'public'::regnamespace;
  if v_src not like '%_door_gate(%' or v_src not like '%exception when others then%' or v_src not like '%>= 20 then%' then
    raise exception '[D371] log_growth_event: gate missing, catch-all missing, or the per-token cap was lost';
  end if;
end $chk$;
