-- cup_final_race(p_season uuid) oid=21533
CREATE OR REPLACE FUNCTION public.cup_final_race(p_season uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; cap_n integer; v_solo boolean;
  v_fin jsonb; v_rung text; v_cap_note text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then
    raise exception 'Not a member of this league';
  end if;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n  := coalesce(st.counting_cap, 10000);
  -- D212 · the calendar cap still applies inside the window
  v_cap_note := case when st.counting_cap is not null
                     then 'Best ' || st.counting_cap
                          || ' per calendar month still applies — a round posted before the window can hold a slot.'
                     else null end;

  if not exists (select 1 from cup_finalists where season_id = p_season) then
    return jsonb_build_object(
      'status', 'pending', 'season_status', se.status, 'solo', v_solo,
      'window_start', se.ends_on - 27, 'window_end', se.ends_on, 'cap_n', cap_n,
      'cap_note', v_cap_note,
      'days_left', greatest(0, se.ends_on - current_date),
      'finalists', '[]'::jsonb, 'seed_rung', null);
  end if;

  select jsonb_agg(to_jsonb(f) order by f.seed) into v_fin
    from (
      select cf.seed, cf.head_start, cf.seed_rung, cf.squad_id, cf.member_id,
             coalesce(sq.name, pf.display_name, 'A golfer') as name,
             sq.color,
             coalesce(sum(w.points), 0)                     as window_points,
             count(w.round_id)                              as rounds_used,
             max(w.played_on)                               as last_round_on,
             cf.head_start + coalesce(sum(w.points), 0)     as total,
             coalesce(jsonb_agg(jsonb_build_object(
               'round_id', w.round_id, 'played_on', w.played_on, 'points', w.points,
               'month_rank', w.month_rank, 'pvi', w.pvi, 'holes_played', w.holes_played,
               'member_id', w.member_id, 'golfer', coalesce(wp.display_name, 'A golfer'))
               order by w.played_on desc) filter (where w.round_id is not null), '[]'::jsonb) as rounds
        from cup_finalists cf
        left join squads sq          on sq.id = cf.squad_id
        left join league_members lm  on lm.id = cf.member_id
        left join profiles pf        on pf.id = lm.profile_id
        left join lateral (
          select w.* from _cup_window_rounds(p_season) w
           where w.member_id = cf.member_id
              or w.member_id in (select sm.member_id from squad_members sm where sm.squad_id = cf.squad_id)
        ) w on true
        left join league_members wlm on wlm.id = w.member_id
        left join profiles wp        on wp.id = wlm.profile_id
       where cf.season_id = p_season
       group by cf.id, cf.seed, cf.head_start, cf.seed_rung, cf.squad_id, cf.member_id,
                sq.name, sq.color, pf.display_name
    ) f;

  -- the rung that decided the cut (seed 2 vs the row below) is the story;
  -- seed 1's rung (the +10 race) rides along in its own row
  select seed_rung into v_rung from cup_finalists
   where season_id = p_season and seed_rung is not null
   order by seed desc limit 1;

  return jsonb_build_object(
    'status', case when se.status = 'complete' then 'complete' else 'live' end,
    'season_status', se.status, 'solo', v_solo,
    'window_start', se.ends_on - 27, 'window_end', se.ends_on, 'cap_n', cap_n,
    'cap_note', v_cap_note,
    'days_left', greatest(0, se.ends_on - current_date),
    'finalists', coalesce(v_fin, '[]'::jsonb), 'seed_rung', v_rung);
end $function$

