-- set_member_bye(p_member uuid, p_month date, p_on boolean) oid=19679
CREATE OR REPLACE FUNCTION public.set_member_bye(p_member uuid, p_month date, p_on boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_season uuid; v_league uuid; v_sqid uuid; v_name text; v_mon date;
begin
  v_mon := date_trunc('month', p_month)::date;
  -- resolve the member's active season + squad
  select s.id, s.league_id into v_season, v_league
    from seasons s
    join squads sq on sq.season_id = s.id
    join squad_members sm on sm.squad_id = sq.id
   where sm.member_id = p_member and s.status in ('active','cup_final')
   order by s.number desc limit 1;
  if v_season is null then raise exception 'No active season for that member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro grants a bye'; end if;
  select sq.id into v_sqid from squads sq
    join squad_members sm on sm.squad_id = sq.id
   where sm.member_id = p_member and sq.season_id = v_season limit 1;
  select display_name into v_name from profiles p
    join league_members lm on lm.profile_id = p.id where lm.id = p_member;

  if p_on then
    -- one bye per season: clear any prior bye first (this becomes THE bye)
    delete from season_adjustments where season_id = v_season and member_id = p_member and kind = 'bye';
    insert into season_adjustments (season_id, squad_id, member_id, month, kind, points, reason)
    values (v_season, v_sqid, p_member, v_mon, 'bye', 0, 'Bye granted by the Pro');
    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, v_season, 'system', my_member_id(v_league),
            'The Pro granted '||coalesce(v_name,'a member')||' a bye for '||to_char(v_mon,'FMMonth')||'.');
  else
    delete from season_adjustments where season_id = v_season and member_id = p_member
      and kind = 'bye' and month = v_mon;
    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, v_season, 'system', my_member_id(v_league),
            'The Pro cleared '||coalesce(v_name,'a member')||'''s '||to_char(v_mon,'FMMonth')||' bye.');
  end if;
end $function$

