-- trg_event_complete() oid=19165
CREATE OR REPLACE FUNCTION public.trg_event_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.status = 'complete' and (old.status is distinct from 'complete') then
    perform award_event_trophies(new.id);
  end if;
  return new;
end $function$

