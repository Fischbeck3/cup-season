-- major_leaderboard(p_event uuid) oid=20230
CREATE OR REPLACE FUNCTION public.major_leaderboard(p_event uuid)
 RETURNS TABLE(player_id uuid, profile_id uuid, display_name text, marker text, exhibition boolean, round_id uuid, gross integer, pvi numeric, cards integer, best_posted_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select * from major_board(p_event)
   where is_event_member(p_event) or is_event_league_member(p_event);
$function$

