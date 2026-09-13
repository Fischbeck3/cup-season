-- plan_day_floor() oid=35673
CREATE OR REPLACE FUNCTION public.plan_day_floor()
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  -- The earliest calendar day a plan may name. The server keeps UTC; the
  -- golfer keeps their own clock; a day of slack is the whole distance
  -- between them. Internal only — no client calls this, so it takes no grant
  -- and `build-db.mjs` will not mint it a Swift name (D37).
  select current_date - 1
$function$

