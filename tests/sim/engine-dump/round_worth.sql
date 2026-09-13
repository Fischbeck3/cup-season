-- round_worth(p_cap integer, p_used integer, p_worst numeric) oid=35058
CREATE OR REPLACE FUNCTION public.round_worth(p_cap integer DEFAULT NULL::integer, p_used integer DEFAULT NULL::integer, p_worst numeric DEFAULT NULL::numeric)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select case
    -- uncapped, or a slot still open: the round ADDS its points
    when p_cap is null or p_cap <= 0 or coalesce(p_used, 0) < p_cap
      then cup_points(3)::numeric
    -- full, and the counter it would bump is unknown: no honest answer
    when p_worst is null then null
    -- full: the round BUMPS the worst counter
    else cup_points(3)::numeric - p_worst
  end
$function$

