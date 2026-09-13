-- set_event_team(p_player uuid, p_team uuid) oid=19073
CREATE OR REPLACE FUNCTION public.set_event_team(p_player uuid, p_team uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_event uuid;
begin
  select event_id into v_event from event_players where id = p_player;
  if not is_event_organizer(v_event) then raise exception 'Only the organizer can do that.'; end if;
  update event_players set team_id = p_team where id = p_player;
end $function$

