-- Cup Season — ONE ROUND, ONE NUMBER (D324).
--
-- The owner's own 90 at Gold Canyon read **5.8 over your playing HCP** on Home
-- and **6.3 over your playing HCP** on its own receipt and on the league board.
-- Same round, same day, two numbers, one sentence.
--
-- It was not a lens: a query against production showed the round carries pvi
-- **-6.3 in BOTH leagues** it scores in, with an identical playing index. The
-- two figures come from two different producers computing two different things:
--
--   * `v_rounds_ranked.pvi` = `playing_index - differential`. The league's
--     allowance applied — a PLAYING handicap. The receipt and the board read it.
--   * `home_feed.pvi`       = `index_at_post - differential`. The RAW index.
--
-- Both are glossed by one sentence, and that sentence says "playing HCP".
--
-- ── WHY THE ARITHMETIC MOVES AND NOT THE WORDS ──────────────────────────────
-- The first attempt at this was a copy fix: give Home its own noun. **Preflight
-- caught it and was right to.** R-M ruled the gloss says "playing HCP", and
-- check 42 holds every client to it — it lists *"1.3 over your number"* by name
-- among the phrasings that are RETIRED. Changing the words would have shipped a
-- form a ruling had already refused. The number was the thing that was wrong.
--
-- ── ONE RULE, NOT A FALLBACK ────────────────────────────────────────────────
-- The playing handicap where one exists, the index where it does not. Those are
-- the same rule: no league means no allowance, no allowance means 100%, and at
-- 100% the playing handicap IS the index. So a leagueless golfer's Home is
-- unchanged and now says something true, rather than saying the same thing by
-- accident.
--
-- `min` over the memberships because a golfer in three leagues has three
-- playing handicaps and Home spans all of them. The LOWEST is the strictest —
-- the one that cannot flatter a round — and it is deterministic, which a
-- "whichever league came back first" would not be.
--
-- ── COST, STATED ────────────────────────────────────────────────────────────
-- This is a correlated subquery per feed row against `v_rounds_ranked`, on a
-- read capped at a page of the circle's rounds. The view is already the hot
-- path for every league surface in the product. If it bites, the fix is to
-- join once rather than to go back to two answers.
--
-- The body below is `pg_get_functiondef` from PRODUCTION, read 2026-09-08, with
-- one expression replaced (rule 2: the live definition is the only honest
-- starting point).

begin;

CREATE OR REPLACE FUNCTION public.home_feed(p_days integer DEFAULT 21)
 RETURNS TABLE(round_id uuid, profile_id uuid, golfer text, marker text, handle text, gross integer, pvi numeric, played_on date, created_at timestamp with time zone, course text, is_pr boolean, is_first boolean, is_sub80 boolean, is_me boolean, photo_path text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    -- **D324 · ONE ROUND, ONE NUMBER.** This was
    -- `round(index_at_post - differential, 1)` — the RAW index — while
    -- `v_rounds_ranked.pvi` uses `playing_index`, the league's allowance
    -- applied. Both are rendered through one sentence saying "over your
    -- playing HCP", so the same 90 read 5.8 on Home and 6.3 on its own receipt
    -- and on the board. Same round, same day, two numbers, one label, and the
    -- wrong one on the surface a golfer opens first.
    --
    -- **The gloss is not the thing to change.** R-M ruled the noun is the
    -- playing handicap and preflight fails the build if it drifts; it lists
    -- the "over your number" phrasing among the retired ones. So the
    -- ARITHMETIC comes into line instead.
    --
    -- The playing handicap where one exists, the index where it does not —
    -- **and that is one rule, not a fallback**: no league means no allowance,
    -- no allowance means 100%, and at 100% the playing handicap IS the index.
    -- `min` because a golfer in three leagues has three playing handicaps and
    -- Home spans all of them; the lowest is the strictest, which is the one
    -- that cannot flatter a round.
    case when rk.index_at_post is not null then round(
      coalesce((select min(v.playing_index)
                  from v_rounds_ranked v
                 where v.round_id = rk.id and v.playing_index is not null),
               rk.index_at_post) - rk.differential, 1) end,
    rk.played_on, rk.created_at, rk.course_label,
    (rk.rn > 1 and rk.prior_best is not null and rk.differential < rk.prior_best),
    (rk.rn = 1),
    (rk.gross < 80 and coalesce(rk.prior_sub80, 0) = 0),
    (rk.profile_id = auth.uid()),
    rk.photo_path
  from ranked rk
  join profiles p on p.id = rk.profile_id
  where rk.played_on >= current_date - p_days
  order by rk.created_at desc, rk.id desc
  limit 40;
$function$;


-- ── self-check ──────────────────────────────────────────────────────────────
do $$
declare v_src text;
begin
  select prosrc into v_src from pg_proc where oid = 'public.home_feed(integer)'::regprocedure;
  if v_src is null then
    raise exception '[D324] home_feed is not there to check';
  end if;

  -- the raw-index arithmetic must be GONE as the whole expression
  if v_src like '%round(rk.index_at_post - rk.differential, 1)%' then
    raise exception '[D324] home_feed still measures against the raw index alone';
  end if;
  -- and the playing index must be what it reaches for first
  if v_src not like '%min(v.playing_index)%' then
    raise exception '[D324] home_feed does not read the playing index';
  end if;
  -- the index is still the floor for a golfer with no league
  if v_src not like '%rk.index_at_post) - rk.differential%' then
    raise exception '[D324] home_feed lost the no-league case';
  end if;
end $$;

commit;
