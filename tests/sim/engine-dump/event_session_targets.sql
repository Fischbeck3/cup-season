-- event_session_targets(p_session uuid) oid=19625
CREATE OR REPLACE FUNCTION public.event_session_targets(p_session uuid)
 RETURNS TABLE(duel_id uuid, a_pvi numeric, b_pvi numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select d.id,
    (select (r.index_at_post * e.allowance / 100.0) - r.differential
       from rounds r join event_players ep on ep.id = d.a_player
      where r.profile_id = ep.profile_id and r.played_on between s.opens_on and s.closes_on
        and not r.voided and coalesce(r.source,'app') <> 'sim'
        and r.index_at_post is not null and r.differential is not null
      order by 1 desc nulls last limit 1),
    (select (r.index_at_post * e.allowance / 100.0) - r.differential
       from rounds r join event_players ep on ep.id = d.b_player
      where r.profile_id = ep.profile_id and r.played_on between s.opens_on and s.closes_on
        and not r.voided and coalesce(r.source,'app') <> 'sim'
        and r.index_at_post is not null and r.differential is not null
      order by 1 desc nulls last limit 1)
  from event_duels d
  join event_sessions s on s.id = d.session_id
  join events e on e.id = s.event_id
  where d.session_id = p_session and s.status = 'open'
    and is_event_member(s.event_id);
$function$

