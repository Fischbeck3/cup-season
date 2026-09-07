-- Cup Season · the UI overhaul, wave 4 — WHAT YOUR GOLFERS THINK OF A COURSE
-- (D272 / IOS-048, `BRIEF.md` §12, `docs/ui-overhaul-2026-09-06/surfaces/course.md` §7.1–§7.2)
--
-- ***THIS FILE HAS NOT BEEN RUN. IT IS WRITTEN AND NOT PUSHED.*** The overhaul
-- is a client-side wave and the client that ships with it degrades to the
-- not-rated state — a full-size unfilled star rail and
-- `NOT RATED · THE FIRST RATING SETS THE NUMBER` — on every course, because
-- neither function below exists in production. Nothing on the phone or the
-- desk waits on it, nothing 403s a golfer, and nothing draws a number it does
-- not have. The owner runs `supabase db push` when they want the feature.
--
-- WHAT §12 ASKS FOR, AND WHAT IT IS NOT. A course carries a rating out of
-- five, in half stars, from the golfers who have played it. It is **an average
-- of opinions**, which is why the design spends no champagne on it: gold means
-- a thing that was WON, and nobody earns a course's rating. The number's
-- weight comes from its size and its rule.
--
-- THREE NUMBERS AND TWO COUNTS, RETURNED TOGETHER, because the design draws
-- them on one shared rule and a block drawn from three reads can render three
-- different seconds of the same afternoon:
--
--   * the community's mean and how many ratings it is over;
--   * the mean and the count **among golfers this viewer can see** — buddies,
--     league mates and event field mates, which is `can_see_profile_board`'s
--     own set minus the `discoverable = 'everyone'` stranger branch. A
--     stranger is a Cup Season golfer, not one of YOUR golfers, and the two
--     figures sit 90pt apart on the same rule where the difference has to
--     mean something;
--   * the viewer's own, or null. **Null, never zero** (L-44): the design's
--     third slot renders `NOT YOURS YET` as its label and never a dash.
--
-- THE COURSE KEY IS `api_courses.id`, the GolfCourseAPI text id the round, the
-- plan and the phone's own course book all already carry (`20260714050000`).
-- It is a SOFT reference for the same reason `rounds.api_course_id` is: a
-- rating must never fail because the catalogue row has not been cached yet.
--
-- D37 · GRANTS ARE EXPLICIT. Default privileges no longer auto-grant EXECUTE,
-- so each of the three functions carries its own
-- `grant execute … to authenticated`, and none of them is granted to `anon` —
-- the anon surface stays at twelve. A new RPC that "silently 403s in prod" is
-- almost always a missing grant, and that is the one failure this file is
-- most likely to have if a line is dropped from it.
--
-- SKEW, both directions. Client before database (the state this wave ships
-- in): `course_rating` does not exist, the read fails, and both clients draw
-- the unrated rail — no dead door, no empty band, no error. Database before
-- client: the table sits unread and the two writes are never called. Every
-- argument is required rather than defaulted because a rating with no course
-- is not a rating, and both clients pass both.
--
-- L-05 · the self-check at the bottom READS ONLY. It touches no row.

-- ---------------------------------------------------------------------------
-- 1 · the table — one opinion per golfer per course
-- ---------------------------------------------------------------------------

create table if not exists public.course_ratings (
  id             uuid primary key default gen_random_uuid(),
  -- `api_courses.id`. SOFT — no foreign key — for the same reason
  -- `rounds.api_course_id` is soft: a rating must never fail because the
  -- catalogue row has not been cached on this database yet.
  api_course_id  text not null,
  profile_id     uuid not null references public.profiles(id) on delete cascade,
  -- half stars, 0.5 … 5.0. The check is arithmetic rather than an enum so the
  -- constraint says what the control says: the rail steps by a half.
  stars          numeric(2,1) not null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint course_ratings_range check (stars >= 0.5 and stars <= 5.0),
  constraint course_ratings_half  check ((stars * 2) = floor(stars * 2)),
  constraint course_ratings_course_len check (char_length(btrim(api_course_id)) between 1 and 64),
  constraint course_ratings_one_per_golfer unique (api_course_id, profile_id)
);

comment on table public.course_ratings is
  'D272/IOS-048 — one golfer''s rating of one course, in half stars. An average of opinions: never an earned figure, and never gold in either client.';
comment on column public.course_ratings.api_course_id is
  'api_courses.id — GolfCourseAPI''s text id, the key the round, the plan and the phone''s course book already carry. Soft by design.';
comment on column public.course_ratings.stars is
  'Half stars, 0.5 … 5.0. The constraint is the control: the rail steps by a half and so does the column.';

create index if not exists course_ratings_course_idx
  on public.course_ratings (api_course_id, profile_id);
create index if not exists course_ratings_profile_idx
  on public.course_ratings (profile_id);

-- The `bag_items` / `mutes` shape: RLS on, NO api policies, and no grant to
-- either role. Reads go through `course_rating`, writes through `rate_course`
-- and `unrate_course`, all three SECURITY DEFINER — identity is checked at the
-- database, never by hiding a button.
alter table public.course_ratings enable row level security;
revoke all on public.course_ratings from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2 · the aggregate — three numbers and two counts, in one read
-- ---------------------------------------------------------------------------

create or replace function public.course_rating(p_course_id text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v          uuid := auth.uid();
  v_id       text := btrim(coalesce(p_course_id, ''));
  v_all      numeric; v_all_n integer;
  v_mine     numeric;
  v_theirs   numeric; v_theirs_n integer;
begin
  if v is null or v_id = '' then
    return jsonb_build_object('course_id', v_id, 'rated', false);
  end if;

  select round(avg(cr.stars) * 2) / 2, count(*)
    into v_all, v_all_n
    from course_ratings cr
   where cr.api_course_id = v_id;

  select cr.stars into v_mine
    from course_ratings cr
   where cr.api_course_id = v_id and cr.profile_id = v;

  -- YOUR golfers: buddies, league mates, event field mates. NOT the
  -- `discoverable = 'everyone'` branch of `can_see_profile_board` — a stranger
  -- who happens to be visible is a Cup Season golfer and not one of yours, and
  -- these two figures sit on one rule where the difference has to mean
  -- something. Yourself is excluded: your own rating is the third slot.
  select round(avg(cr.stars) * 2) / 2, count(*)
    into v_theirs, v_theirs_n
    from course_ratings cr
   where cr.api_course_id = v_id
     and cr.profile_id <> v
     and (
       exists (select 1 from friendships f where f.status = 'accepted'
                and ((f.requester = v and f.addressee = cr.profile_id)
                  or (f.addressee = v and f.requester = cr.profile_id)))
       or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
                   where a.profile_id = v and b.profile_id = cr.profile_id)
       or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
                   where a.profile_id = v and b.profile_id = cr.profile_id)
     );

  -- Every figure is null rather than zero when nothing produced it (L-44).
  -- `rated` is the one boolean both clients branch on: false draws the
  -- full-size unfilled rail and `NOT RATED · THE FIRST RATING SETS THE NUMBER`.
  return jsonb_build_object(
    'course_id',   v_id,
    'rated',       coalesce(v_all_n, 0) > 0,
    'stars',       v_all,
    'count',       coalesce(v_all_n, 0),
    'friends',     v_theirs,
    'friends_count', coalesce(v_theirs_n, 0),
    'mine',        v_mine);
end $fn$;

comment on function public.course_rating(text) is
  'D272/IOS-048 — a course''s rating: the community''s mean and count, your golfers'' mean and count, and your own. Null figures, never zeroes.';

revoke all on function public.course_rating(text) from public, anon;
grant execute on function public.course_rating(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · the writes — upsert one opinion, or take it back
-- ---------------------------------------------------------------------------

create or replace function public.rate_course(p_course_id text, p_stars numeric)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $fn$
declare
  v     uuid := auth.uid();
  v_id  text := btrim(coalesce(p_course_id, ''));
  v_s   numeric := round(coalesce(p_stars, 0) * 2) / 2;
begin
  if v is null then raise exception 'sign in to rate a course'; end if;
  if v_id = '' then raise exception 'a rating needs a course'; end if;
  -- The control cannot send an out-of-range value, so a clamp here would be a
  -- guess about a caller that is wrong. It is refused instead, in the
  -- product's own voice, because the sentence a golfer reads matters more than
  -- the code they do not.
  if v_s < 0.5 or v_s > 5.0 then raise exception 'a rating is half a star to five'; end if;

  insert into course_ratings (api_course_id, profile_id, stars)
  values (v_id, v, v_s)
  on conflict (api_course_id, profile_id)
  do update set stars = excluded.stars, updated_at = now();

  -- The write returns the READ, so the client re-tallies from the server's own
  -- arithmetic rather than adding one to a number it was holding. One read,
  -- one write, one round trip.
  return public.course_rating(v_id);
end $fn$;

comment on function public.rate_course(text, numeric) is
  'D272/IOS-048 — set the caller''s rating of a course, in half stars. Returns the aggregate, so the client never does the arithmetic itself.';

revoke all on function public.rate_course(text, numeric) from public, anon;
grant execute on function public.rate_course(text, numeric) to authenticated;

create or replace function public.unrate_course(p_course_id text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $fn$
declare
  v     uuid := auth.uid();
  v_id  text := btrim(coalesce(p_course_id, ''));
begin
  if v is null then raise exception 'sign in to rate a course'; end if;
  if v_id = '' then raise exception 'a rating needs a course'; end if;

  delete from course_ratings cr where cr.api_course_id = v_id and cr.profile_id = v;

  return public.course_rating(v_id);
end $fn$;

comment on function public.unrate_course(text) is
  'D272/IOS-048 — take the caller''s rating off a course. Idempotent; returns the aggregate.';

revoke all on function public.unrate_course(text) from public, anon;
grant execute on function public.unrate_course(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 4 · the self-check — reads only (L-05)
-- ---------------------------------------------------------------------------
do $check$
declare n integer;
begin
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('course_rating', 'rate_course', 'unrate_course');
  if n <> 3 then
    raise exception 'course ratings: expected three functions, found %', n;
  end if;

  -- D37, and the failure this check exists for: a function granted to nobody
  -- is a feature that 403s in production with no message worth reading.
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('course_rating', 'rate_course', 'unrate_course')
     and has_function_privilege('authenticated', p.oid, 'EXECUTE');
  if n <> 3 then
    raise exception 'course ratings: % of 3 functions are executable by authenticated', n;
  end if;

  -- And never by anon. The anon surface is twelve endpoints and this is not
  -- one of them.
  select count(*) into n
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public'
     and p.proname in ('course_rating', 'rate_course', 'unrate_course')
     and has_function_privilege('anon', p.oid, 'EXECUTE');
  if n <> 0 then
    raise exception 'course ratings: % function(s) are executable by anon', n;
  end if;

  if has_any_column_privilege('anon', 'public.course_ratings', 'SELECT')
     or has_any_column_privilege('authenticated', 'public.course_ratings', 'SELECT') then
    raise exception 'course_ratings is readable off the table; it must be read through course_rating()';
  end if;
end $check$;
