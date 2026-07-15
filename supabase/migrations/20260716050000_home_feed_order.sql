-- ============================================================================
-- Cup Season — fix: "around the circle" feed ordering
--
-- home_feed() ordered by played_on (a DATE) and returned no post timestamp, so
-- the client could only sort to day granularity — a round posted just now sorted
-- among the day's others by uuid, never rising to the top. Return created_at (the
-- actual post time) and order by it, so newest-posted lands first. Additive: the
-- column set only grows.
-- ============================================================================

create or replace function public.home_feed(p_days integer default 21)
returns table(
  round_id uuid, profile_id uuid, golfer text, marker text, handle text,
  gross integer, pvi numeric, played_on date, created_at timestamptz, course text,
  is_pr boolean, is_first boolean, is_sub80 boolean, is_me boolean)
language sql stable security definer set search_path = public as $$
  with circle as (
    select auth.uid() as pid
    union
    select case when requester = auth.uid() then addressee else requester end
      from friendships
      where status = 'accepted' and (requester = auth.uid() or addressee = auth.uid())
    union
    select lm2.profile_id
      from league_members lm1 join league_members lm2 on lm2.league_id = lm1.league_id
      where lm1.profile_id = auth.uid()
    union
    select ep2.profile_id
      from event_players ep1 join event_players ep2 on ep2.event_id = ep1.event_id
      where ep1.profile_id = auth.uid()
  ),
  ranked as (
    select r.id, r.profile_id, r.gross, r.differential, r.index_at_post,
      r.played_on, r.created_at, r.course_label,
      row_number() over w as rn,
      min(r.differential) over (partition by r.profile_id order by r.played_on, r.id
        rows between unbounded preceding and 1 preceding) as prior_best,
      max(case when r.gross < 80 then 1 else 0 end) over (partition by r.profile_id order by r.played_on, r.id
        rows between unbounded preceding and 1 preceding) as prior_sub80
    from rounds r
    where r.profile_id in (select pid from circle) and r.differential is not null
    window w as (partition by r.profile_id order by r.played_on, r.id)
  )
  select rk.id, rk.profile_id, p.display_name, p.marker, p.handle,
    rk.gross,
    case when rk.index_at_post is not null then round(rk.index_at_post - rk.differential, 1) end,
    rk.played_on, rk.created_at, rk.course_label,
    (rk.rn > 1 and rk.prior_best is not null and rk.differential < rk.prior_best),
    (rk.rn = 1),
    (rk.gross < 80 and coalesce(rk.prior_sub80, 0) = 0),
    (rk.profile_id = auth.uid())
  from ranked rk
  join profiles p on p.id = rk.profile_id
  where rk.played_on >= current_date - p_days
  order by rk.created_at desc, rk.id desc
  limit 40;
$$;

grant execute on function public.home_feed(integer) to authenticated;
