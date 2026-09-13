CREATE OR REPLACE FUNCTION public.set_league_finish(p_league uuid, p_finish text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record;
begin
  if p_finish not in ('points_table','cup_final') then raise exception 'finish must be points_table or cup_final'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro sets the finish'; end if;
  select * into se from seasons where league_id = p_league and status in ('active','cup_final')
   order by number desc limit 1;
  -- once the Final window is open (or entered) the finish is settled — no
  -- retroactive rewrites of a live endgame (spec principle 4: argue never)
  if se.id is not null and (se.status = 'cup_final' or current_date >= se.ends_on - 27) then
    raise exception 'The finish is locked once the final window opens';
  end if;

  update league_settings set finish = p_finish where league_id = p_league;
  insert into posts (league_id, kind, member_id, body)
  values (p_league, 'system', my_member_id(p_league),
          case when p_finish = 'cup_final'
            then 'The Pro set the finish: the Cup Final. Final four weeks, scored fresh, top seeds only.'
            else 'The Pro set the finish: the points table. It crowns the champion outright — no Cup Final.' end);
end $function$

