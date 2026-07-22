-- ============================================================================
-- Cup Season — D60a: league names stay home (share payload tightening)
--
-- Pilot: a round share carried the league's name onto the public page —
-- league names are in-joke space ("Who's the bitch?"), the public page is
-- not. Rule: the artifact shows only what it is ABOUT. Round → the golfer
-- (league dropped). Settlement → the game (league dropped). Recap → the
-- league's own season (name stays; the sharer shares the league knowingly).
-- Curated at the SOURCE: share_info stops returning 'league' on the round
-- and settlement branches — the anon page never receives it. Skew-safe both
-- directions (client conditionals already guard the key's absence).
-- ============================================================================

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
  v_photo boolean := false;
begin
  if p_token is null then return null; end if;
  select * into sh from shares where token = p_token;
  -- every dead path answers the same: null (D57)
  if sh.token is null or sh.revoked then return null; end if;

  if sh.kind = 'round' then
    select * into r from rounds where id = sh.ref_id and not voided;
    if r.id is null then return null; end if;
    select display_name, marker into v_name, v_marker from profiles where id = r.profile_id;
    if r.season_id is not null then
      select rr.pvi, rr.points into v_pvi, v_points
        from v_rounds_ranked rr
       where rr.round_id = r.id and rr.season_id = r.season_id limit 1;
    end if;
    select exists (select 1 from storage.objects o
                    where o.bucket_id = 'shared'
                      and o.name = sh.token::text || '.jpg') into v_photo;
    -- D60a: no 'league' key — the round is about the golfer
    return jsonb_build_object(
      'kind','round',
      'name', coalesce(v_name,'A golfer'), 'marker', v_marker,
      'gross', r.gross, 'holes', r.holes_played,
      'course', r.course_label, 'played_on', to_char(r.played_on,'YYYY-MM-DD'),
      'pvi', v_pvi, 'points', v_points,
      'photo', v_photo);

  elsif sh.kind = 'settlement' then
    select * into lr from live_rounds where id = sh.ref_id and status = 'final';
    if lr.id is null then return null; end if;
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
    -- D60a: no 'league' key — the settlement is about the game
    return jsonb_build_object(
      'kind','settlement', 'game', lr.game,
      'course', lr.course_label,
      'played_on', to_char(coalesce(lr.finished_at, lr.started_at),'YYYY-MM-DD'),
      'result', v_res, 'players', v_players);

  elsif sh.kind = 'recap' then
    select * into s from seasons where id = sh.ref_id;
    if s.id is null then return null; end if;
    -- the recap IS the league's season — the name stays, shared knowingly
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
revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;
