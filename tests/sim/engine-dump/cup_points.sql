-- cup_points(p_pvi numeric) oid=18463
CREATE OR REPLACE FUNCTION public.cup_points(p_pvi numeric)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when p_pvi >= 3  then 12
    when p_pvi >= 1  then 9
    when p_pvi > -1  then 7
    when p_pvi >= -3 then 6
    else 5
  end;
$function$

