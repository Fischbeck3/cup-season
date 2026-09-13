-- major_board(p_event uuid) oid=20229
CREATE OR REPLACE FUNCTION public.major_board(p_event uuid)
 RETURNS TABLE(player_id uuid, profile_id uuid, display_name text, marker text, exhibition boolean, round_id uuid, gross integer, pvi numeric, cards integer, best_posted_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select ep.id, ep.profile_id, pr.display_name, pr.marker, ep.exhibition,
         b.rid, b.gross, b.pvi, coalesce(b.cards, 0), b.posted_at
    from event_players ep
    join profiles pr on pr.id = ep.profile_id
    join events e on e.id = ep.event_id
    join event_sessions s on s.event_id = e.id and s.session_no = 1
    left join lateral (
      select r.id as rid, r.gross,
             round((r.index_at_post * e.allowance / 100.0) - r.differential, 1) as pvi,
             r.created_at as posted_at,
             count(*) over () as cards
        from rounds r
       where r.profile_id = ep.profile_id
         and r.played_on between s.opens_on and s.closes_on
         and not r.voided and coalesce(r.source,'app') <> 'sim'
         and r.holes_played = 18
         and r.index_at_post is not null and r.differential is not null
       order by pvi desc, r.created_at asc, r.id
       limit 1
    ) b on true
   where ep.event_id = p_event
   order by b.pvi desc nulls last, pr.display_name;
$function$

