-- rounds_no_future() oid=20053
CREATE OR REPLACE FUNCTION public.rounds_no_future()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.played_on > current_date + 1 then
    raise exception 'A round date can''t be in the future';
  end if;
  return new;
end $function$

