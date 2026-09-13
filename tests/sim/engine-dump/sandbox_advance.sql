-- sandbox_advance(p_league uuid) oid=20473
CREATE OR REPLACE FUNCTION public.sandbox_advance(p_league uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se seasons%rowtype; m date; v_closed integer := 0; v_status text;
begin
  perform assert_sandbox(p_league, true);
  select * into se from seasons where league_id = p_league
   order by number desc limit 1;
  if se.id is null then raise exception 'no season yet'; end if;

  -- close every fully-elapsed month (close_month is sentinel-idempotent)
  m := date_trunc('month', se.starts_on)::date;
  while m <= se.ends_on and (m + interval '1 month')::date - 1 < current_date loop
    perform close_month(se.id, m);
    v_closed := v_closed + 1;
    m := (m + interval '1 month')::date;
  end loop;

  perform snapshot_week(se.id);      -- on-conflict-do-nothing inside
  perform daily_season_tick();       -- the same law every league lives under

  select status into v_status from seasons where id = se.id;
  return jsonb_build_object('months_touched', v_closed, 'season_status', v_status);
end $function$

