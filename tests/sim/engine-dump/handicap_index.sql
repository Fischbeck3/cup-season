-- handicap_index(p_profile uuid) oid=19591
CREATE OR REPLACE FUNCTION public.handicap_index(p_profile uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.handicap_index_asof(p_profile, null, null);
$function$

