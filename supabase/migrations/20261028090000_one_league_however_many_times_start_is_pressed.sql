-- D355 · one league, however many times Start is pressed.
--
-- `create_league(p_name, p_code)` mints a league row, a commissioner seat and
-- a settings row with no request identity. The wizard retains a created league
-- for an in-session retry (D346), but an AMBIGUOUS create — a response lost to
-- a timeout, an app killed between the create and the lock — leaves the golfer
-- with no id and a "Start a season" door that mints a second league beside
-- the first. The open item is named in the 2026-09-13 activation handoff (#1).
--
-- This is the same discipline `post_round_once` keeps (20261021090000): a
-- private receipt per (owner, request), an advisory lock so two concurrent
-- taps serialise, and a replay that returns the ORIGINAL answer. It wraps the
-- existing `create_league` unchanged, so every default the wizard shows
-- (D206) is still written by the one function that writes it.
--
-- Conflicting body: a replay whose name or code differs returns the STORED
-- league (with `replayed: true`) and mints nothing — the response carries the
-- league's actual name, so nothing is misreported, and the name is the lock's
-- to set (`lock_league(p_name)`), not the create's to argue about.
--
-- Old client: unaffected, it calls `create_league`. Old server: the call fails
-- PGRST202/42883 and each client is FAIL-CLOSED — it says the server is not
-- ready and mints nothing, rather than falling back to a function that cannot
-- deduplicate. Grants: execute to `authenticated` only. Not deployed by this change.

create schema if not exists cupseason_private;
revoke all on schema cupseason_private from public, anon, authenticated;

create table if not exists cupseason_private.league_create_receipts (
  owner_id   uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  payload    jsonb not null,
  response   jsonb not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, request_id)
);
-- Deliberately no league FK: a league the Pro later deletes must not turn a
-- stale retry into a fresh one. The receipt says what was answered.
alter table cupseason_private.league_create_receipts enable row level security;
revoke all on cupseason_private.league_create_receipts from public, anon, authenticated;

create or replace function public.create_league_once(p_request_id uuid, p_name text, p_code text)
returns json
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_owner uuid := auth.uid();
  v_previous cupseason_private.league_create_receipts%rowtype;
  v_response json;
begin
  if v_owner is null then raise exception 'Sign in first'; end if;
  if p_request_id is null then raise exception 'Invalid league request'; end if;
  -- serialise same-account/request races before either reaches create_league
  perform pg_advisory_xact_lock(hashtextextended(v_owner::text || ':league:' || p_request_id::text, 0));
  select * into v_previous from cupseason_private.league_create_receipts
   where owner_id = v_owner and request_id = p_request_id;
  if found then
    return (v_previous.response || jsonb_build_object('replayed', true))::json;
  end if;
  v_response := public.create_league(p_name, p_code);
  insert into cupseason_private.league_create_receipts (owner_id, request_id, payload, response)
  values (v_owner, p_request_id, jsonb_build_object('name', p_name, 'code', p_code), v_response::jsonb);
  return v_response;
end;
$$;

revoke all on function public.create_league_once(uuid, text, text) from public, anon;
grant execute on function public.create_league_once(uuid, text, text) to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare n int;
begin
  select count(*) into n from pg_proc
   where proname = 'create_league_once' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'create_league_once must resolve to exactly one function, found %', n; end if;
  select count(*) into n from pg_proc
   where proname = 'create_league' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'create_league must still resolve to exactly one function, found %', n; end if;
  if has_function_privilege('anon', 'public.create_league_once(uuid, text, text)', 'execute') then
    raise exception 'anon must not execute create_league_once';
  end if;
  if not has_function_privilege('authenticated', 'public.create_league_once(uuid, text, text)', 'execute') then
    raise exception 'authenticated must execute create_league_once';
  end if;
  if has_table_privilege('authenticated', 'cupseason_private.league_create_receipts', 'SELECT') then
    raise exception 'league_create_receipts must not be readable by authenticated';
  end if;
end $check$;
