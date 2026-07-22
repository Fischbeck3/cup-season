-- ============================================================================
-- Cup Season — public share pages (shareability arc · decision D57)
--
-- A tokened, revocable window onto ONE artifact: a round, a game settlement,
-- or a season recap. The token is the only access path (unguessable uuid pk;
-- ids never appear in share URLs). Minting is lazy — no share row exists until
-- a golfer chooses "Share a link" (the golfer publishes, the app never does).
--
--   shares                       — definer-only ledger (RLS on, NO policies)
--   create_share(kind, ref)      — authenticated; verifies the caller owns or
--                                  played the artifact; re-mint returns the
--                                  existing live token (one artifact, one link)
--   revoke_share(token)          — creator only; kills an escaped link
--   share_info(token)            — THE ONE NEW ANON ENDPOINT (D37 list 4 → 5).
--                                  Curated jsonb snapshot; FAIL-CLOSED: unknown,
--                                  revoked, wrong-kind, voided, unfinished all
--                                  return the same NULL — nothing to enumerate.
--
-- D37 discipline: explicit grants below; tests/db-checks.sql check 2 (anon
-- literal list) and check 3 (authenticated list) updated in the same commit.
-- ============================================================================

create table public.shares (
  token      uuid primary key default gen_random_uuid(),
  kind       text not null check (kind in ('round','settlement','recap')),
  ref_id     uuid not null,
  created_by uuid not null references public.profiles(id) on delete cascade,
  revoked    boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.shares enable row level security;
-- no policies on purpose: the client never touches rows; RPCs below are the
-- only path. Belt and suspenders for the API roles:
revoke all on table public.shares from public, anon, authenticated;

-- one LIVE link per artifact per sharer (revoked rows don't block a re-mint)
create unique index shares_one_live
  on public.shares (kind, ref_id, created_by) where not revoked;

-- ---- mint (lazy, ownership-checked) -----------------------------------------
create or replace function public.create_share(p_kind text, p_ref uuid)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_tok uuid;
  v_ok boolean := false;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_kind not in ('round','settlement','recap') or p_ref is null then
    raise exception 'Nothing to share';
  end if;

  if p_kind = 'round' then
    -- your own posted, unvoided round
    select true into v_ok from rounds
     where id = p_ref and profile_id = v and not voided;
  elsif p_kind = 'settlement' then
    -- a finished live round you started or played in (finish_live_round's check)
    select true into v_ok from live_rounds lr
     where lr.id = p_ref and lr.status = 'final'
       and ( exists (select 1 from league_members m
                      where m.id = lr.started_by and m.profile_id = v)
          or exists (select 1 from live_round_players p
                      join league_members m on m.id = p.member_id
                     where p.live_round_id = lr.id and m.profile_id = v) );
  elsif p_kind = 'recap' then
    -- a season in a league you belong to
    select true into v_ok from seasons s
     join league_members m on m.league_id = s.league_id and m.profile_id = v
     where s.id = p_ref limit 1;
  end if;

  if v_ok is not true then raise exception 'Nothing to share'; end if;

  select token into v_tok from shares
   where kind = p_kind and ref_id = p_ref and created_by = v and not revoked;
  if v_tok is not null then return v_tok; end if;

  begin
    insert into shares (kind, ref_id, created_by)
    values (p_kind, p_ref, v) returning token into v_tok;
  exception when unique_violation then
    select token into v_tok from shares
     where kind = p_kind and ref_id = p_ref and created_by = v and not revoked;
  end;
  return v_tok;
end $$;

-- ---- revoke (creator only) --------------------------------------------------
create or replace function public.revoke_share(p_token uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first'; end if;
  update shares set revoked = true
   where token = p_token and created_by = v and not revoked;
  return found;
end $$;

-- ---- the public window (fail-closed) ----------------------------------------
create or replace function public.share_info(p_token uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  sh shares%rowtype;
  r  rounds%rowtype;
  lr live_rounds%rowtype;
  s  seasons%rowtype;
  v_name text; v_marker text; v_league text;
  v_pvi numeric; v_points int;
  v_res jsonb; v_players jsonb; v_rows jsonb;
  v_champ text; v_king text; v_no int;
begin
  if p_token is null then return null; end if;
  select * into sh from shares where token = p_token;
  -- every dead path answers the same: null. A bad link, a revoked link, and a
  -- since-voided artifact are indistinguishable from outside (D57).
  if sh.token is null or sh.revoked then return null; end if;

  if sh.kind = 'round' then
    select * into r from rounds where id = sh.ref_id and not voided;
    if r.id is null then return null; end if;
    select display_name, marker into v_name, v_marker from profiles where id = r.profile_id;
    if r.season_id is not null then
      select rr.pvi, rr.points into v_pvi, v_points
        from v_rounds_ranked rr
       where rr.round_id = r.id and rr.season_id = r.season_id limit 1;
      select l.name into v_league
        from seasons se join leagues l on l.id = se.league_id
       where se.id = r.season_id;
    end if;
    return jsonb_build_object(
      'kind','round',
      'name', coalesce(v_name,'A golfer'), 'marker', v_marker,
      'gross', r.gross, 'holes', r.holes_played,
      'course', r.course_label, 'played_on', to_char(r.played_on,'YYYY-MM-DD'),
      'pvi', v_pvi, 'points', v_points, 'league', v_league);

  elsif sh.kind = 'settlement' then
    select * into lr from live_rounds where id = sh.ref_id and status = 'final';
    if lr.id is null then return null; end if;
    select l.name into v_league from leagues l where l.id = lr.league_id;
    -- curated result: named keys only, never the raw jsonb pass-through
    v_res := (select jsonb_strip_nulls(jsonb_build_object(
      'side_a', lr.game_result->>'side_a', 'side_b', lr.game_result->>'side_b',
      'status', lr.game_result->>'status', 'winner', lr.game_result->>'winner',
      'stake',  lr.game_result->>'stake',  'story',  lr.game_result->>'story',
      'transfers', lr.game_result->'transfers')));
    select coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object(
             'name', coalesce(pr.display_name, p.guest_name, 'A golfer'),
             'gross', coalesce(rd.gross, p.guest_gross)))
             order by p.position), '[]'::jsonb)
      into v_players
      from live_round_players p
      left join league_members m on m.id = p.member_id
      left join profiles pr on pr.id = m.profile_id
      left join lateral (select max(gross) as gross from rounds
                          where live_round_id = lr.id and profile_id = m.profile_id) rd on true
     where p.live_round_id = lr.id;
    return jsonb_build_object(
      'kind','settlement', 'game', lr.game,
      'course', lr.course_label,
      'played_on', to_char(coalesce(lr.finished_at, lr.started_at),'YYYY-MM-DD'),
      'league', v_league, 'result', v_res, 'players', v_players);

  elsif sh.kind = 'recap' then
    select * into s from seasons where id = sh.ref_id;
    if s.id is null then return null; end if;
    select l.name into v_league from leagues l where l.id = s.league_id;
    select count(*)::int into v_no from squads where season_id = s.id;
    if v_no > 0 then
      select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points) order by q.points desc), '[]'::jsonb)
        into v_rows
        from (select sq.name, vs.points from v_squad_standings vs
                join squads sq on sq.id = vs.squad_id
               where vs.season_id = s.id
               order by vs.points desc limit 5) q;
    else
      select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points) order by q.points desc), '[]'::jsonb)
        into v_rows
        from (select pr.display_name as name, vi.points from v_individual_standings vi
                join league_members m on m.id = vi.member_id
                join profiles pr on pr.id = m.profile_id
               where vi.season_id = s.id
               order by vi.points desc limit 5) q;
    end if;
    if s.champion_squad_id is not null then
      select name into v_champ from squads where id = s.champion_squad_id;
    end if;
    if s.points_king_member_id is not null then
      select pr.display_name into v_king
        from league_members m join profiles pr on pr.id = m.profile_id
       where m.id = s.points_king_member_id;
    end if;
    return jsonb_strip_nulls(jsonb_build_object(
      'kind','recap', 'league', v_league,
      'starts_on', to_char(s.starts_on,'YYYY-MM-DD'),
      'ends_on', to_char(s.ends_on,'YYYY-MM-DD'),
      'status', s.status, 'rows', v_rows,
      'champion', v_champ, 'points_king', v_king));
  end if;

  return null;
end $$;

-- ---- grants: explicit, D37 (default privileges no longer auto-grant, and the
-- migration runner may not be the postgres role — revoke PUBLIC by hand) ------
revoke all on function public.create_share(text, uuid) from public, anon;
revoke all on function public.revoke_share(uuid) from public, anon;
revoke all on function public.share_info(uuid) from public;
grant execute on function public.create_share(text, uuid) to authenticated;
grant execute on function public.revoke_share(uuid) to authenticated;
grant execute on function public.share_info(uuid) to anon, authenticated;
