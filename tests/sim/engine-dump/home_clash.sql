-- home_clash(p_league uuid) oid=27504
CREATE OR REPLACE FUNCTION public.home_clash(p_league uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_me     uuid;
  se       record;
  wc       record;
  v_local  date;
  v_ws     date;
  v_we     date;
  v_cap    integer;
  v_them   uuid;
  v_mine   jsonb;
  v_theirs jsonb;
  v_name   text;
  v_marker text;
begin
  if not is_league_member(p_league) then
    return null;
  end if;
  v_me := my_member_id(p_league);
  if v_me is null then
    return null;
  end if;

  select * into se from seasons
   where league_id = p_league and status in ('active','cup_final')
   order by starts_on desc limit 1;
  if se.id is null then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;

  select * into wc from week_clashes
   where season_id = se.id and settled_at is null
     and (a_member = v_me or b_member = v_me)
     and (se.starts_on + 7 * (week_no - 1)) <= v_local
     and (se.starts_on + 7 * (week_no - 1) + 6) >= v_local
   order by week_no desc limit 1;
  if wc.id is null then
    return null;
  end if;

  v_ws   := se.starts_on + 7 * (wc.week_no - 1);
  v_we   := v_ws + 6;
  v_them := case when wc.a_member = v_me then wc.b_member else wc.a_member end;

  select counting_cap into v_cap from league_settings where league_id = p_league;

  -- `v_rounds_ranked` carries no gross (it is the SCORING lens), so the round
  -- itself supplies the number a golfer recognises on a card.
  select jsonb_build_object('round_id', rr.round_id, 'played_on', rr.played_on,
                            'points', rr.points, 'pvi', rr.pvi, 'gross', r.gross)
    into v_mine
    from v_rounds_ranked rr
    join rounds r on r.id = rr.round_id
   where rr.season_id = se.id and rr.member_id = v_me
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select jsonb_build_object('round_id', rr.round_id, 'played_on', rr.played_on,
                            'points', rr.points, 'pvi', rr.pvi, 'gross', r.gross)
    into v_theirs
    from v_rounds_ranked rr
    join rounds r on r.id = rr.round_id
   where rr.season_id = se.id and rr.member_id = v_them
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc limit 1;

  select p.display_name, coalesce(lm.marker, p.marker) into v_name, v_marker
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = v_them;

  return jsonb_build_object(
    'week_no',      wc.week_no,
    'ends_on',      v_we,
    'days_left',    (v_we - v_local),
    'closes_today', (v_we = v_local),
    'them_name',    v_name,
    'them_marker',  v_marker,
    'mine',         v_mine,
    'theirs',       v_theirs,
    'rivalry',      (select rn.name from rivalry_names rn
                      join league_members la on la.id = wc.a_member
                      join league_members lb on lb.id = wc.b_member
                     where rn.pair_low  = least(la.profile_id, lb.profile_id)
                       and rn.pair_high = greatest(la.profile_id, lb.profile_id)));
end $function$

