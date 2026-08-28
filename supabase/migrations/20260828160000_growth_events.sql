-- ============================================================================
-- Cup Season — the growth funnel, measured (spec/claim-loop-instrumentation.md;
-- GTM experiment №1 "prereq for everything"; launch review 2026-08-28 pass 2)
--
--   artifact_shared → link_opened → claim_started → profile_created → first_round_posted
--
-- The loop has WORKED since v23.157 (guest claim) and has never been counted:
-- `client_events` is RLS'd to `authenticated` (ce_insert_own), so the one edge
-- the whole Year-1 plan bets on — a NON-user opening a shared link — was
-- invisible by construction. This file adds the one table, the one writer, and
-- the durable attribution the spec asks for, and nothing else (no dashboards,
-- no third-party analytics, no pixels — spec §"out of scope").
--
--   growth_events        append-only. ZERO relation privileges for anon and
--                        authenticated (CLAUDE.md: anon holds none in public;
--                        the client never touches rows). Read by the founder
--                        from the SQL editor / service role only.
--   log_growth_event()   SECURITY DEFINER, the only writer. Callable by anon
--                        AND authenticated — the 12th anon endpoint, and it
--                        is FAIL-CLOSED the way the other eleven are:
--                          · signed-out may log ONLY `link_opened`, and only
--                            when the token resolves to a real share / claim /
--                            join row. Otherwise it returns void — the SAME
--                            void — so it is not an oracle for token guessing
--                            (never raises, never says "not found").
--                          · ≤20 rows per token per hour; beyond that, silent.
--                          · props are capped (512 chars) and stripped of the
--                            obvious PII keys; policy on both clients is that
--                            no email / name / handle ever rides in props.
--                          · `first_round_posted` is decided HERE (rounds
--                            count), not trusted from the client.
--                          · `profile_created` writes the attribution columns
--                            once (came_via_* null → set), never overwrites.
--   profiles.came_via_*  spec §2 — "which artifact created this profile",
--                        durable, so the weekly read needs no event archaeology.
--                        LANDMINE (CLAUDE.md, check 9): the profiles column-
--                        grant list is frozen — the new columns are granted
--                        below or every select naming them fails 42501.
--   v_growth_funnel      spec §5 — by week × kind × league, one row per node.
--                        No grants: founder/service-role read only.
--
-- Deploy skew: the new RPC's args all default; both clients call it
-- fire-and-forget and swallow a missing function, so either deploy order is
-- safe. D37 discipline: explicit revoke from public, explicit grants.
-- ============================================================================

-- ---- the table --------------------------------------------------------------
create table if not exists public.growth_events (
  id         bigint generated always as identity primary key,
  at         timestamptz not null default now(),
  node       text not null check (node in
               ('artifact_shared','link_opened','claim_started','profile_created','first_round_posted')),
  kind       text check (kind in ('share','claim','join','recap','settlement')),
  token      text,
  league_id  uuid,
  actor      uuid,
  props      jsonb not null default '{}'::jsonb
);
comment on table public.growth_events is
  'Append-only growth funnel (spec/claim-loop-instrumentation.md). Written only by log_growth_event(); no client privileges.';

create index if not exists growth_events_token_at_idx on public.growth_events (token, at desc);
create index if not exists growth_events_at_idx       on public.growth_events (at desc);

alter table public.growth_events enable row level security;
-- no policies on purpose; belt and suspenders for the API roles
revoke all on table public.growth_events from public, anon, authenticated;

-- ---- durable attribution on the profile (spec §2) -------------------------
alter table public.profiles
  add column if not exists came_via_kind  text check (came_via_kind in ('share','claim','join','recap','settlement')),
  add column if not exists came_via_token text;

-- the frozen column-grant list (20260721214500 seal; check 9)
grant select (came_via_kind, came_via_token) on public.profiles to authenticated;

-- ---- the one writer ---------------------------------------------------------
create or replace function public.log_growth_event(
  p_node   text,
  p_kind   text  default null,
  p_token  text  default null,
  p_props  jsonb default '{}'::jsonb,
  p_league uuid  default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid    uuid := auth.uid();
  v_tok    text := nullif(trim(coalesce(p_token, '')), '');
  v_kind   text := case when p_kind in ('share','claim','join','recap','settlement') then p_kind end;
  v_league uuid := p_league;
  v_props  jsonb;
  v_is_uuid boolean;
begin
  -- unknown node: silent no-op (never an error a probe could read)
  if p_node is null or p_node not in
     ('artifact_shared','link_opened','claim_started','profile_created','first_round_posted') then
    return;
  end if;

  v_is_uuid := v_tok ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

  -- a join code always attributes to its league (both roles)
  if v_kind = 'join' and v_tok is not null and v_league is null then
    select id into v_league from leagues where code = upper(v_tok) limit 1;
  end if;

  if v_uid is null then
    -- signed-out: ONLY a real link being opened
    if p_node <> 'link_opened' or v_tok is null then return; end if;
    if v_kind = 'join' then
      if v_league is null then return; end if;
    elsif v_kind = 'claim' then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from scan_claims        where token       = v_tok::uuid)
     and not exists (select 1 from live_round_players where claim_token = v_tok::uuid) then
        return;
      end if;
    elsif v_kind in ('share','recap','settlement') then
      if not v_is_uuid then return; end if;
      if not exists (select 1 from shares where token = v_tok::uuid and not revoked) then return; end if;
    else
      return;   -- anon with no kind: nothing to attribute, nothing to log
    end if;
  else
    -- signed-in: the server decides the facts it can
    if p_node = 'first_round_posted'
       and (select count(*) from rounds where profile_id = v_uid) > 1 then
      return;
    end if;
    if p_node = 'profile_created' and v_kind is not null then
      update profiles
         set came_via_kind = v_kind, came_via_token = v_tok
       where id = v_uid and came_via_kind is null;
    end if;
  end if;

  -- ≤20 rows per token per hour
  if v_tok is not null and (
       select count(*) from growth_events
        where token = v_tok and at > now() - interval '1 hour') >= 20 then
    return;
  end if;

  -- props: never PII, never big
  v_props := coalesce(p_props, '{}'::jsonb);
  if jsonb_typeof(v_props) <> 'object' then v_props := '{}'::jsonb; end if;
  v_props := v_props - 'email' - 'name' - 'handle' - 'display_name' - 'phone';
  if length(v_props::text) > 512 then v_props := '{}'::jsonb; end if;

  insert into growth_events (node, kind, token, league_id, actor, props)
  values (p_node, v_kind, v_tok, v_league, v_uid, v_props);
exception when others then
  -- a breadcrumb never breaks a post, a share, or a door
  return;
end $$;

revoke all on function public.log_growth_event(text, text, text, jsonb, uuid) from public;
grant execute on function public.log_growth_event(text, text, text, jsonb, uuid) to anon, authenticated;

-- ---- the weekly read (spec §5) ---------------------------------------------
create or replace view public.v_growth_funnel as
  select date_trunc('week', at)::date as week,
         kind,
         league_id,
         count(*) filter (where node = 'artifact_shared')    as shared,
         count(*) filter (where node = 'link_opened')        as opened,
         count(*) filter (where node = 'claim_started')      as claim_started,
         count(*) filter (where node = 'profile_created')    as profiles,
         count(*) filter (where node = 'first_round_posted') as first_rounds
    from public.growth_events
   group by 1, 2, 3
   order by 1 desc, 2, 3;
revoke all on public.v_growth_funnel from public, anon, authenticated;

-- ---- self-enforcing: fail the push rather than ship a hole ----------------
do $$
begin
  if has_table_privilege('anon', 'public.growth_events', 'select, insert, update, delete')
  or has_table_privilege('authenticated', 'public.growth_events', 'select, insert, update, delete') then
    raise exception 'growth_events: an API role still holds a relation privilege';
  end if;
  if has_table_privilege('anon', 'public.v_growth_funnel', 'select')
  or has_table_privilege('authenticated', 'public.v_growth_funnel', 'select') then
    raise exception 'v_growth_funnel: an API role can read it';
  end if;
  if not has_function_privilege('anon', 'public.log_growth_event(text, text, text, jsonb, uuid)', 'execute')
  or not has_function_privilege('authenticated', 'public.log_growth_event(text, text, text, jsonb, uuid)', 'execute') then
    raise exception 'log_growth_event: missing execute grant';
  end if;
  if not has_column_privilege('authenticated', 'public.profiles', 'came_via_kind', 'select')
  or not has_column_privilege('authenticated', 'public.profiles', 'came_via_token', 'select') then
    raise exception 'profiles.came_via_*: column select not granted (check 9 would fail)';
  end if;
end $$;
