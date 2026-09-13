CREATE OR REPLACE FUNCTION public.my_side_games(p_limit integer DEFAULT 20)
 RETURNS TABLE(live_round_id uuid, played_on date, game text, course_label text, players text[], story text, status text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with seats as (
    select lp.live_round_id,
           coalesce(lp.claimed_profile, lp.guest_profile_id, lm.profile_id) pid,
           coalesce(lp.guest_name, p.display_name) nm
      from live_round_players lp
      left join league_members lm on lm.id = lp.member_id
      left join profiles p on p.id = coalesce(lp.claimed_profile, lp.guest_profile_id, lm.profile_id)
  ),
  mine as (select distinct s.live_round_id from seats s where s.pid = auth.uid())
  select lr.id,
         coalesce(lr.finished_at::date, lr.started_at::date),
         lr.game,
         lr.course_label,
         (select array_agg(distinct s.nm) from seats s
           where s.live_round_id = lr.id and s.nm is not null
             and s.pid is distinct from auth.uid()),
         -- the SERVER's own settled sentence, written at finish. No verdict is
         -- derived here: `game_result.winner` is a side index and the sides are
         -- free text, so a derived W-L would be a name match dressed as a fact.
         nullif(lr.game_result->>'story', ''),
         nullif(lr.game_result->>'status', '')
    from live_rounds lr
   where auth.uid() is not null
     and lr.id in (select live_round_id from mine)
     and lr.status = 'final'
   order by coalesce(lr.finished_at, lr.started_at) desc
   limit greatest(coalesce(p_limit, 20), 1);
$function$

