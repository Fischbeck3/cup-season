-- ============================================================================
-- D187 · One number, everywhere — the allowance the receipt never showed.
--
-- The engine pays round(index * allowance/100 - differential, 1); allowance is
-- 95 under the Standard preset. Two server functions disagreed with it:
--
--   1. home_feed published round(index_at_post - differential, 1) — 100%, no
--      allowance. This is the important one: because that value is NOT NULL,
--      every client-side fallback was skipped, so Home, the digest and any
--      receipt opened from Home rendered a figure the engine never paid — and
--      where the ~0.6 shift crosses a band edge (cup_points is half-open at
--      >=3 / >=1 / >-1 / >=-3), the wrong BAND NAME too. Same class as D174's
--      composer bug; D178 measured it on the phone at 71 of 289 real rounds.
--
--   2. round_card fell back to the same 100% expression for a round with no
--      rank row, so the instant view and the enriched view could disagree.
--
-- round_card already SELECTED rr.playing_index and returned it; no client ever
-- read it (grep -c playing_index index.html -> 0). It now also carries the
-- allowance so the receipt can show the middle step, and both fallbacks apply
-- it. playing_index - differential == pvi exactly (both round to 1dp and
-- rounds.differential is numeric(5,1), so the rounding is translation-
-- invariant by multiples of 0.1) — which is what lets the card close by hand.
--
-- EXPRESSION CHANGES ONLY. No column is added to either function, so
-- `create or replace` is legal — the 42P13 drop-first landmine documented at
-- 20260723090000:8-11 applies to changing the RETURN TYPE, which this does not.
--
-- Deliberately unchanged: loadCareer / tour_card lifetime figures stay at 100%.
-- They are global cross-league numbers with no league lens, as the comment at
-- 20260716060000:75 already declares.
-- ============================================================================

-- ---------------------------------------------------------------- home_feed
-- The pvi comes from the engine's own view. The 100% expression survives only
-- as the fallback for a round that belongs to no season at all (nothing in
-- v_rounds_ranked), which is the pre-existing league-less behaviour.
create or replace function public.home_feed(p_days integer default 21)
returns table(
  round_id uuid, profile_id uuid, golfer text, marker text, handle text,
  gross integer, pvi numeric, played_on date, created_at timestamptz, course text,
  is_pr boolean, is_first boolean, is_sub80 boolean, is_me boolean,
  photo_path text)
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
      r.played_on, r.created_at, r.course_label, r.photo_path,
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
    -- D187: the engine's figure, not a second implementation of it.
    coalesce(eng.pvi,
             case when rk.index_at_post is not null
                  then round(rk.index_at_post - rk.differential, 1) end),
    rk.played_on, rk.created_at, rk.course_label,
    (rk.rn > 1 and rk.prior_best is not null and rk.differential < rk.prior_best),
    (rk.rn = 1),
    (rk.gross < 80 and coalesce(rk.prior_sub80, 0) = 0),
    (rk.profile_id = auth.uid()),
    rk.photo_path
  from ranked rk
  join profiles p on p.id = rk.profile_id
  left join lateral (
    select rr.pvi from v_rounds_ranked rr
     where rr.round_id = rk.id
     order by rr.month_rank limit 1) eng on true
  where rk.played_on >= current_date - p_days
  order by rk.created_at desc, rk.id desc
  limit 40;
$$;

revoke all on function public.home_feed(integer) from public, anon;
grant execute on function public.home_feed(integer) to authenticated;

-- --------------------------------------------------------------- round_card
-- Body taken VERBATIM from 20260729180000 and transformed programmatically —
-- three marked D187 edits and nothing else. Hand-retyping it first dropped
-- 'golfer' and 'is_mine' from the payload and rewrote the played_with
-- subquery, which is exactly how a rebuild-on-top reopens a closed bug.
create or replace function public.round_card(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  r rounds%rowtype;
  v_rank record;
  v_mates jsonb;
  v_allow numeric;   -- D187
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into r from rounds where id = p_round;
  if r.id is null then raise exception 'No such round'; end if;

  -- yours, or posted by someone you share a league with
  if r.profile_id is distinct from v and not exists (
    select 1 from league_members a
      join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = r.profile_id)
  then raise exception 'That round is not yours to read'; end if;

  -- the scoring lens: points and where it lands in the month's counting cap
  -- D187: also take the allowance the engine actually paid at, so the receipt
  -- can show the middle step (index x allowance = playing index).
  select rr.points, rr.month_rank, rr.playing_index, rr.pvi, ls.counting_cap,
         ls.handicap_allowance
    into v_rank
    from v_rounds_ranked rr
    join league_members lm on lm.id = rr.member_id
    join league_settings ls on ls.league_id = lm.league_id
   where rr.round_id = r.id and lm.profile_id = r.profile_id
   order by rr.month_rank limit 1;

  -- D187: a round with no rank row still needs an allowance to show its work.
  -- Use a league the poster and the viewer BOTH belong to — the same relation
  -- the read gate above already established. 100 when the poster has no league,
  -- which keeps a league-less round reading exactly as it did.
  v_allow := coalesce(v_rank.handicap_allowance, (
    select ls.handicap_allowance
      from league_members a
      join league_members b on b.league_id = a.league_id
      join league_settings ls on ls.league_id = a.league_id
     where a.profile_id = v and b.profile_id = r.profile_id
     order by b.joined_at limit 1), 100);

  -- who was there: the live round's roster when there was one, else the
  -- attestation names the finish recorded
  select coalesce(jsonb_agg(distinct nm), '[]'::jsonb) into v_mates from (
    select coalesce(pr.display_name, lp.guest_name) as nm
      from live_round_players lp
      left join league_members m on m.id = lp.member_id
      left join profiles pr on pr.id = m.profile_id
     where r.live_round_id is not null and lp.live_round_id = r.live_round_id
    union
    select a.attested_by from attestations a where a.round_id = r.id
  ) t where nm is not null and nm <> coalesce((select display_name from profiles where id = r.profile_id), '');

  return jsonb_build_object(
    'id', r.id,
    'gross', r.gross,
    'holes_played', r.holes_played,
    'played_on', r.played_on,
    'course_label', r.course_label,
    'rating', r.rating,
    'slope', r.slope,
    'nine_rating', r.nine_rating,
    'differential', r.differential,
    'index_at_post', r.index_at_post,
    -- D187: the allowance ships so the receipt can render the middle step,
    -- and BOTH fallbacks now apply it. They computed at 100% while the engine
    -- paid at 95%, so an unranked round showed a figure — and sometimes a band
    -- name — the table never paid.
    'handicap_allowance', v_allow,
    'ranked', (v_rank.pvi is not null),
    'playing_index', coalesce(v_rank.playing_index,
                              round(r.index_at_post * v_allow / 100.0, 1)),
    'pvi', coalesce(v_rank.pvi,
                    round(r.index_at_post * v_allow / 100.0 - r.differential, 1)),
    'points', v_rank.points,
    'month_rank', v_rank.month_rank,
    'counting_cap', v_rank.counting_cap,
    'source', r.source,
    'attested', r.attested,
    'photo_path', r.photo_path,
    'live_round_id', r.live_round_id,
    'profile_id', r.profile_id,
    'golfer', (select display_name from profiles where id = r.profile_id),
    'is_mine', (r.profile_id = v),
    'played_with', v_mates);
end $$;

revoke all on function public.round_card(uuid) from public, anon;
grant execute on function public.round_card(uuid) to authenticated;

-- Self-enforcing: a future rebuild that drops the allowance reopens D187.
do $chk$
begin
  if position('handicap_allowance' in pg_get_functiondef('public.round_card(uuid)'::regprocedure)) = 0 then
    raise exception 'D187: round_card lost handicap_allowance';
  end if;
  if position('v_rounds_ranked' in pg_get_functiondef('public.home_feed(integer)'::regprocedure)) = 0 then
    raise exception 'D187: home_feed is computing pvi itself again';
  end if;
end $chk$;
