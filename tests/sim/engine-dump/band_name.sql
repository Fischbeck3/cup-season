-- band_name(p_pvi numeric) oid=35044
CREATE OR REPLACE FUNCTION public.band_name(p_pvi numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when p_pvi is null then null
    when p_pvi >= 3  then 'Torched it'
    when p_pvi >= 1  then 'Beat your number'
    when p_pvi > -1  then 'Played to it'      -- Q-20: half-open, matching cup_points
    when p_pvi >= -3 then 'A little loose'
    else 'Posted anyway'
  end;
$function$

