-- Cup Season · the visual pass — THE OFFLINE CARD CARRIES ITS YARDAGE
-- (D290, `VISUAL_PASS` §2 / §4, `BUILD_REPORT` §4.2's own filed note)
--
-- ONE COLUMN, AND IT IS THE DIFFERENCE BETWEEN TWO CLIENTS DRAWING THE SAME
-- COURSE AS TWO SHAPES. `api_course_holes` has carried `yardage` since
-- `20260714050000:49-52`; `my_course_books` selects `hole_number`, `par` and
-- `handicap` and stops there. So the phone's offline card draws **height by
-- par** — eleven of eighteen bars identical — while the desk, which reads
-- `api_course_holes` directly, draws **height by yardage**. `CSDrawnCard`'s
-- own `hasYardage` flag exists to tell the truth about which picture you are
-- looking at, and `Course.swift` files the cause in its header (D-2).
--
-- `VISUAL_PASS` §4 asks a planned round to "highlight holes if we have that
-- info", and the fact a golfer actually wants the night before is the three
-- lowest stroke indexes **with their yardages**: `PAR 5 · 604 · SI 1`. Without
-- this column the phone can print the par and the stroke index and not the
-- length, which is the one number that says whether the 4th is reachable.
--
-- NOTHING ELSE CHANGES. Same name, same signature, same security, same
-- ordering, same cap — `create or replace` and one more key in one
-- `jsonb_build_object`. The clients read `yards` where it is present and fall
-- back to par where it is not, which is what they already do for a tee cached
-- before its card was; so a client older than this file ignores the key, and a
-- client newer than it draws the weaker-but-real picture until the push. No
-- deploy order breaks a live user.
--
-- D37 · the grant is re-issued with the replace, because a `create or replace`
-- keeps the existing grants and a future `drop` would not — and this file
-- would rather be explicit than rely on which of the two it is.

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
                                   'hole', h.hole_number, 'par', h.par, 'si', h.handicap,
                                   -- D290 · the one new key. `yards` rather
                                   -- than `yardage`, because that is what both
                                   -- clients' hole types already call it.
                                   'yards', h.yardage)
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
  'R-N/D261/D290 — every course on my schedule or in my posted rounds, with its rated tees and their hole cards (par, stroke index AND yardage), for the phone''s offline store. Caller''s own rows only.';

revoke all on function public.my_course_books(integer) from public, anon;
grant execute on function public.my_course_books(integer) to authenticated;

commit;

-- L-05 · reads only
do $check$
declare n integer;
begin
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'my_course_books'
     and has_function_privilege('authenticated', p.oid, 'EXECUTE');
  if n <> 1 then
    raise exception 'my_course_books: expected one function executable by authenticated, found %', n;
  end if;
  if has_function_privilege('anon', 'public.my_course_books(integer)', 'EXECUTE') then
    raise exception 'my_course_books is executable by anon; the anon surface is twelve and this is not one';
  end if;
  if not exists (select 1 from information_schema.columns
                  where table_schema='public' and table_name='api_course_holes' and column_name='yardage') then
    raise exception 'api_course_holes.yardage does not exist; the book has nothing to carry';
  end if;
end $check$;
