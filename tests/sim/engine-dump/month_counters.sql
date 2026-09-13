-- month_counters(p_member uuid, p_season uuid, p_cap integer, p_on date) oid=35059
CREATE OR REPLACE FUNCTION public.month_counters(p_member uuid DEFAULT NULL::uuid, p_season uuid DEFAULT NULL::uuid, p_cap integer DEFAULT NULL::integer, p_on date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with c as (
    select vr.points
      from v_rounds_ranked vr
     where p_member is not null and p_season is not null
       and vr.member_id = p_member
       and vr.season_id = p_season
       and date_trunc('month', vr.played_on) = date_trunc('month', coalesce(p_on, current_date))
       and (p_cap is null or p_cap <= 0 or vr.month_rank <= p_cap)
  )
  select jsonb_build_object(
    'cap',   p_cap,
    'used',  (select count(*)::int from c),
    'worst', (select min(points) from c),
    'month', to_char(coalesce(p_on, current_date), 'YYYY-MM'))
$function$

