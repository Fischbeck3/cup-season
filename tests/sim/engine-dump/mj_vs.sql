-- mj_vs(n numeric) oid=20225
CREATE OR REPLACE FUNCTION public.mj_vs(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when n is null then 'NO CARD'
    when round(n,1) = 0 then 'LEVEL'
    when n > 0 then rtrim(rtrim(round(n,1)::text,'0'),'.') || ' UNDER'
    else rtrim(rtrim(round(abs(n),1)::text,'0'),'.') || ' OVER'
  end;
$function$

