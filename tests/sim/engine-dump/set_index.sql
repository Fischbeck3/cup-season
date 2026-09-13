-- set_index(p_index numeric) oid=18640
CREATE OR REPLACE FUNCTION public.set_index(p_index numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_old numeric; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'Index looks off — anywhere from -10 to 54.';
  end if;

  v_auto := handicap_index(auth.uid());
  if v_auto is not null then
    raise exception 'Your number comes from your scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select index_current, display_name into v_old, v_name from profiles where id = auth.uid();
  if not found then raise exception 'no profile'; end if;

  update profiles set index_current = p_index, index_source = 'self' where id = auth.uid();
  if v_old is not distinct from p_index then return; end if;

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || case when v_old is null
           then ' set their index to ' || p_index
           else ' adjusted their index ' || v_old || ' → ' || p_index end
    from league_members lm where lm.profile_id = auth.uid();
end $function$

