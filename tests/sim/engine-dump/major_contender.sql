-- major_contender(p_profile uuid) oid=20227
CREATE OR REPLACE FUNCTION public.major_contender(p_profile uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select handicap_index(p_profile) is not null;
$function$

