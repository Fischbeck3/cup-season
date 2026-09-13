-- evhalf(n numeric) oid=19635
CREATE OR REPLACE FUNCTION public.evhalf(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when n - floor(n) >= 0.5
    then floor(n)::int::text || '½' else floor(n)::int::text end;
$function$

