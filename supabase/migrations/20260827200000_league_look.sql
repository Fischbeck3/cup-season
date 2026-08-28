-- ============================================================================
-- D103 (spec/decision-log.md, DECIDED 2026-08-27) — a league can wear a
-- curated look. The Pro picks it; every member's room shows it.
--
--   leagues.look          the look key (tokens.json `looks[].key`) or null =
--                         the calendar. Free text on purpose: the catalogue
--                         lives in tokens.json, not in a Postgres enum, so a
--                         new look is a token change, not a migration.
--   set_league_look()     commissioner only (is_commissioner), UI level —
--                         nothing about scoring is touched.
--   league_looks()        {league_id: look} for the caller's leagues, one
--                         read per session.
--
-- D37: explicit grants to authenticated, explicit revoke from public/anon.
-- ============================================================================

alter table public.leagues
  add column if not exists look text
  check (look is null or look ~ '^[a-z][a-z0-9_]{0,31}$');

create or replace function public.set_league_look(p_league uuid, p_look text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_commissioner(p_league) then
    raise exception 'Only the Pro can dress the room' using errcode = '42501';
  end if;
  update public.leagues set look = nullif(p_look, '') where id = p_league;
end;
$$;

create or replace function public.league_looks()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_object_agg(l.id::text, l.look) filter (where l.look is not null),
    '{}'::jsonb)
  from public.leagues l
  where public.is_league_member(l.id);
$$;

revoke all on function public.set_league_look(uuid, text) from public, anon;
revoke all on function public.league_looks() from public, anon;
grant execute on function public.set_league_look(uuid, text) to authenticated;
grant execute on function public.league_looks() to authenticated;
