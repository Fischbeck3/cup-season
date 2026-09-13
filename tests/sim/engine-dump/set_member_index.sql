-- set_member_index(p_member uuid, p_index numeric) oid=19598
CREATE OR REPLACE FUNCTION public.set_member_index(p_member uuid, p_index numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_pid uuid; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'Index looks off — anywhere from -10 to 54.';
  end if;
  select league_id, profile_id into v_league, v_pid from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro sets a starter index'; end if;

  -- behavior B: a starter only helps before the engine can compute a number.
  -- Setting one now would post a board line the next round instantly overrides.
  v_auto := handicap_index(v_pid);
  if v_auto is not null then
    raise exception 'Their number comes from their scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select display_name into v_name from profiles where id = v_pid;
  update profiles set index_current = p_index, index_source = 'self' where id = v_pid;

  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          'The Pro set ' || coalesce(v_name, 'a member') || '''s starter index to ' || p_index);
end $function$

