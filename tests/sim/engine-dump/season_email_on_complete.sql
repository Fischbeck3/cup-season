CREATE OR REPLACE FUNCTION public.season_email_on_complete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.status = 'complete' and coalesce(old.status,'') <> 'complete'
     and not exists (select 1 from leagues l
                      where l.id = new.league_id and l.sandbox) then
    insert into email_queue (season_id, kind) values (new.id, 'season_recap')
    on conflict (season_id, kind) do nothing;
  end if;
  return new;
end $function$

