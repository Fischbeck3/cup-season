-- mj_money(n numeric) oid=20226
CREATE OR REPLACE FUNCTION public.mj_money(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select '$' || rtrim(rtrim(round(n,2)::text,'0'),'.');
$function$

