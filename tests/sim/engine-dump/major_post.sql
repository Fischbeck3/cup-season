-- major_post(p_event uuid, p_body text) oid=20228
CREATE OR REPLACE FUNCTION public.major_post(p_event uuid, p_body text)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  insert into posts (league_id, event_id, kind, body)
  select e.league_id, e.id, 'system', left(p_body, 400)
    from events e where e.id = p_event;
$function$

