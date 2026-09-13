-- major_final_day(p_session uuid) oid=20235
CREATE OR REPLACE FUNCTION public.major_final_day(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; l record; c record; v_line text;
begin
  select es.event_id, e.name into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major' and es.status = 'open';
  if s.event_id is null then return; end if;

  select * into l from major_board(s.event_id)
   where not exhibition and pvi is not null
   order by pvi desc, best_posted_at asc limit 1;

  if l.player_id is null then
    v_line := 'Final day at ' || s.name || '. No cards yet — the jug is there for the taking.';
  else
    select * into c from major_board(s.event_id)
     where not exhibition and pvi is not null and player_id <> l.player_id
     order by pvi desc, best_posted_at asc limit 1;
    v_line := 'Final day at ' || s.name || '. '
      || l.display_name || ' leads at ' || lower(mj_vs(l.pvi))
      || coalesce('. ' || c.display_name || ' '
           || rtrim(rtrim(round(l.pvi - c.pvi, 1)::text,'0'),'.') || ' back.', '.');
  end if;
  perform major_post(s.event_id, v_line);
end $function$

