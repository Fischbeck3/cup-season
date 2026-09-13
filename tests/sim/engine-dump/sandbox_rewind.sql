-- sandbox_rewind(p_league uuid, p_weeks integer) oid=20471
CREATE OR REPLACE FUNCTION public.sandbox_rewind(p_league uuid, p_weeks integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se seasons%rowtype; v_len integer;
begin
  perform assert_sandbox(p_league, true);
  if p_weeks < 1 or p_weeks > 52 then raise exception '1 to 52 weeks'; end if;
  select * into se from seasons where league_id = p_league
   order by number desc limit 1;
  if se.id is null then raise exception 'no season yet — lock the league first'; end if;

  v_len := se.ends_on - se.starts_on;
  update seasons
     set starts_on = current_date - (p_weeks * 7),
         ends_on   = (current_date - (p_weeks * 7)) + v_len
   where id = se.id;

  return jsonb_build_object(
    'week_now', p_weeks + 1,
    'starts_on', current_date - (p_weeks * 7),
    'ends_on', (current_date - (p_weeks * 7)) + v_len,
    'cup_window_opens', (current_date - (p_weeks * 7)) + v_len - 27);
end $function$

