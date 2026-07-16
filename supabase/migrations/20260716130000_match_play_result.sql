-- ============================================================================
-- Cup Season — tee sheet checkpoint 2: Match Play becomes REAL (spec §13.2, §2)
--
-- Checkpoint 1 posted everyone's card; the match itself lived and died on the
-- phone. This makes the game persist:
--   • live_rounds.game_config — declared at tee-off (stake, sides). Facts about
--     the game, snapshotted like the course is.
--   • live_rounds.game_result — written at finish (ladder result, winner,
--     stake). The settlement card's receipt.
--   • finish_live_round posts the match story to the board ("MATCH PLAY:
--     MARCUS & TREY DEF. JERECHO & COLE 3&2 · $10 ON THE LINE") — the league
--     hears about the game, not just four gross scores. Casual finishes stay
--     traceless: no result stored, no board post (batch-3 #14).
--
-- Signature changes (p_config / p_result, both defaulted) require DROP+CREATE;
-- the defaults keep any not-yet-refreshed client calling the old named-arg
-- sets working through the deploy window.
-- ============================================================================

alter table public.live_rounds add column if not exists game_config jsonb;
alter table public.live_rounds add column if not exists game_result jsonb;

-- ---- start_live_round: + p_config (stake, sides) ---------------------------
drop function if exists public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb);
create or replace function public.start_live_round(
  p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text,
  p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb default '{}'
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select id into v_member from league_members where league_id = p_league and profile_id = v;
  if v_member is null then raise exception 'You are not in this league'; end if;
  select id into v_season from seasons
   where league_id = p_league and status in ('active','cup_final')
   order by starts_on desc limit 1;
  if v_season is null then raise exception 'No active season to post into'; end if;

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member)
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null and not exists (
      select 1 from league_members
       where id = (v_el->>'member_id')::uuid and league_id = p_league) then
      raise exception 'A tagged player is not in this league';
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index, index_source, position)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos);
    v_pos := v_pos + 1;
  end loop;

  return jsonb_build_object('live_round_id', v_lr, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $$;
grant execute on function public.start_live_round(uuid, uuid, uuid, text, jsonb, text, jsonb, jsonb) to authenticated;

-- ---- finish_live_round: + p_result (ladder outcome) + the board story ------
-- Base body = 20260716100000 (engine resolves index; started_by is a member id).
drop function if exists public.finish_live_round(uuid, jsonb, boolean);
create or replace function public.finish_live_round(
  p_live_round uuid, p_cards jsonb, p_casual boolean default false,
  p_result jsonb default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype; v_starter uuid;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
  v_stake numeric; v_story text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then raise exception 'No such round'; end if;

  select profile_id into v_starter from league_members where id = lr.started_by;
  if v_starter is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    if v_pl.member_id is null then
      v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
      continue;
    end if;

    select profile_id into v_pid from league_members where id = v_pl.member_id;

    v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_card->'strokes','[]'::jsonb)) x);
    v_n := coalesce(array_length(v_strokes, 1), 0);
    v_holes := null;
    if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then
      v_holes := 18;
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
          and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then
      v_holes := 9;
    end if;

    if p_casual then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'casual'); continue;
    end if;
    if v_holes is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'incomplete card'); continue;
    end if;
    if v_rating is null or v_slope is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no course rating'); continue;
    end if;
    if v_holes = 9 and v_nine is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no 9-hole rating'); continue;
    end if;

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    -- index_at_post omitted → score_round() resolves it via the engine
    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            current_date, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app')
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  -- the game's outcome: stored + told to the league. Casual = traceless.
  if not p_casual and p_result is not null and (p_result->>'game') = 'match' then
    update live_rounds set game_result = p_result where id = p_live_round;
    v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
    if (p_result->>'winner') is null then
      v_story := 'MATCH PLAY: ' || upper(coalesce(p_result->>'side_a','SIDE A'))
              || ' AND ' || upper(coalesce(p_result->>'side_b','SIDE B'))
              || ' HALVED THE MATCH' || case when v_stake > 0 then ' — NO MONEY MOVES' else '' end;
    else
      v_story := 'MATCH PLAY: '
              || upper(coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'WINNERS'))
              || ' DEF. '
              || upper(coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'THE OTHER SIDE'))
              || ' ' || upper(coalesce(p_result->>'status',''))
              || case when v_stake > 0 then ' · $' || v_stake || ' ON THE LINE' else '' end;
    end if;
    insert into posts (league_id, kind, member_id, body)
    values (lr.league_id, 'system', my_member_id(lr.league_id), v_story);
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $$;
grant execute on function public.finish_live_round(uuid, jsonb, boolean, jsonb) to authenticated;
