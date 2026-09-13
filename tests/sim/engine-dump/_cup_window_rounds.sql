-- _cup_window_rounds(p_season uuid) oid=21532
CREATE OR REPLACE FUNCTION public._cup_window_rounds(p_season uuid)
 RETURNS TABLE(member_id uuid, round_id uuid, profile_id uuid, played_on date, points integer, month_rank bigint, pvi numeric, holes_played integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select rr.member_id, rr.round_id, rr.profile_id, rr.played_on,
         rr.points::integer, rr.month_rank, rr.pvi, rr.holes_played
    from public.v_rounds_ranked rr
    join public.seasons se on se.id = rr.season_id
    join public.league_settings ls on ls.league_id = se.league_id
   where rr.season_id = p_season
     and rr.month_rank <= coalesce(ls.counting_cap, 10000)
     and rr.played_on between se.ends_on - 27 and se.ends_on
$function$

