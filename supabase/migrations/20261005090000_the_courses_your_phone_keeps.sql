-- Cup Season · wave D — THE COURSES YOUR PHONE KEEPS (D261, IOS-041, R-N)
--
-- The owner's own escalation, 2026-09-05: *"I was in the air on airplane mode
-- the other day and wanted to see what the slope/rating and 1st hole was on a
-- course I wanted to play but the app was dead on airplane mode essentially."*
-- Nothing about a course is stored on the phone today — tees, ratings, slopes,
-- pars and stroke indexes are all live reads against `api_course_tees` /
-- `api_course_holes`, so the app is useless without a signal. On a plane, and
-- at most golf courses, which is the larger case.
--
-- The store itself is ON THE DEVICE (`CourseDisk`, the shape `LiveDisk` and
-- `DispatchSnapshot` already use). This function is the one read that fills
-- it: everything the phone is allowed to keep, in ONE round trip, so the fill
-- is a single call on a signal rather than N queries per course.
--
-- WHAT IT RETURNS, and the scope is R-N's exactly: every course on my schedule
-- (mine, or one I am tagged into) and every course I have posted a round at.
-- Nothing else — searching the whole catalogue offline is explicitly not in
-- scope and needs the network, which the client says out loud.
--
-- Ordering is what survives the cap: the next round first, then the most
-- recently played. `p_limit` is DEFAULTED (a client that predates this
-- deployment and one that postdates it both call it correctly) and clamped
-- server-side, because a course is a few kilobytes and a golfer with two
-- hundred of them does not want them all on the phone.
--
-- Security: SECURITY DEFINER over the caller's OWN rows only — `auth.uid()`
-- appears in both halves of the union and there is no argument that could
-- point it at anybody else. The course tables it joins are already readable by
-- `authenticated` (`api_courses_read`, `20260714050000`), so this exposes
-- nothing new; it only saves the round trips. Grants explicit per D37 (L-04):
-- `authenticated` only, never anon — the anon surface stays at twelve (L-45).

begin;

create or replace function public.my_course_books(p_limit integer default 24)
returns jsonb
language sql
stable
security definer
set search_path = public
as $fn$
with plans as (
  select sr.course_id as cid, min(sr.play_on) as next_on
    from scheduled_rounds sr
   where sr.course_id is not null
     and sr.play_on >= current_date
     and (sr.profile_id = auth.uid() or auth.uid() = any(sr.tagged))
   group by sr.course_id
),
played as (
  select r.api_course_id as cid, max(r.played_on) as last_on
    from rounds r
   where r.api_course_id is not null
     and r.profile_id = auth.uid()
     and not coalesce(r.voided, false)
   group by r.api_course_id
),
keys as (
  select coalesce(p.cid, q.cid) as cid, p.next_on, q.last_on
    from plans p
    full outer join played q on q.cid = p.cid
),
ranked as (
  select cid, next_on, last_on
    from keys
   where cid is not null
   order by (next_on is null), next_on asc, last_on desc nulls last, cid
   limit greatest(1, least(coalesce(p_limit, 24), 60))
)
select coalesce(jsonb_agg(book order by ord), '[]'::jsonb)
  from (
    select row_number() over (order by (k.next_on is null), k.next_on asc,
                                       k.last_on desc nulls last, k.cid) as ord,
           jsonb_build_object(
             'id',             c.id,
             'club_name',      c.club_name,
             'course_name',    c.course_name,
             'city',           c.city,
             'state',          c.state,
             'cached_at',      c.cached_at,
             'planned',        (k.next_on is not null),
             'played',         (k.last_on is not null),
             'next_play_on',   k.next_on,
             'last_played_on', k.last_on,
             'tees', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'tee_name',        t.tee_name,
                        'gender',          t.gender,
                        'course_rating',   t.course_rating,
                        'slope_rating',    t.slope_rating,
                        'number_of_holes', t.number_of_holes,
                        'par_total',       t.par_total,
                        'total_yards',     t.total_yards,
                        'holes', coalesce((
                          select jsonb_agg(jsonb_build_object(
                                   'hole', h.hole_number, 'par', h.par, 'si', h.handicap)
                                 order by h.hole_number)
                            from api_course_holes h
                           where h.tee_id = t.id and h.hole_number is not null), '[]'::jsonb))
                      order by t.number_of_holes desc nulls last,
                               t.course_rating desc nulls last, t.tee_name)
                 from api_course_tees t
                where t.course_id = c.id
                  and t.course_rating is not null
                  and t.slope_rating is not null), '[]'::jsonb)
           ) as book
      from ranked k
      join api_courses c on c.id = k.cid
  ) rows;
$fn$;

comment on function public.my_course_books(integer) is
  'R-N/D261 — every course on my schedule or in my posted rounds, with its rated tees and their hole cards, for the phone''s offline store. Caller''s own rows only.';

revoke all on function public.my_course_books(integer) from public, anon;
grant execute on function public.my_course_books(integer) to authenticated;

commit;
