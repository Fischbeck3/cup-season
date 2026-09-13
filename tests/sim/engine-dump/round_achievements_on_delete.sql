-- round_achievements_on_delete() oid=29033
CREATE OR REPLACE FUNCTION public.round_achievements_on_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_when = 'BEFORE' then
    delete from achievements where round_id = old.id;
    return old;
  end if;
  perform rederive_achievements(old.profile_id);
  return null;
end $function$

