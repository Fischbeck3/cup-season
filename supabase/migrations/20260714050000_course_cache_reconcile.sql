-- Course cache, reconciled (audit finding).
--
-- The 2026-07-12 course_cache migration silently no-op'd: a legacy `courses`
-- table (uuid ids, old community-card system) already existed, so its
-- create-if-not-exists / add-column-if-not-exists built nothing, the Edge
-- Function's upserts (GolfCourseAPI *text* ids) failed against uuid columns,
-- and rounds carrying a text course id blew up the insert. Fresh names sidestep
-- the collision; the legacy tables are left untouched.
--
-- rounds.api_course_id is a SOFT reference (no FK): a round must never fail
-- because its course hasn't finished caching (the cache upsert is async on
-- tee-pick). Future features (hole-by-hole stepper, course cards) join
-- rounds.api_course_id = api_courses.id when the row exists.
--
-- After this: `supabase functions deploy courses` (the fn now writes api_*),
-- then prove it: `select count(*) from api_courses` > 0 after one course pick.

create table if not exists public.api_courses (
  id          text primary key,          -- GolfCourseAPI course id (text)
  club_name   text,
  course_name text,
  city        text,
  state       text,
  country     text,
  latitude    double precision,
  longitude   double precision,
  raw         jsonb,
  cached_at   timestamptz not null default now()
);

create table if not exists public.api_course_tees (
  id              uuid primary key default gen_random_uuid(),
  course_id       text not null references public.api_courses(id) on delete cascade,
  gender          text,
  tee_name        text,
  course_rating   numeric,
  slope_rating    integer,
  bogey_rating    numeric,
  par_total       integer,
  total_yards     integer,
  number_of_holes integer,
  unique (course_id, gender, tee_name)
);
create index if not exists api_course_tees_course_idx on public.api_course_tees(course_id);

create table if not exists public.api_course_holes (
  id          uuid primary key default gen_random_uuid(),
  tee_id      uuid not null references public.api_course_tees(id) on delete cascade,
  hole_number integer,
  par         integer,
  yardage     integer,
  handicap    integer,
  unique (tee_id, hole_number)
);
create index if not exists api_course_holes_tee_idx on public.api_course_holes(tee_id);

-- soft link only — no FK, so a round never depends on cache timing
alter table public.rounds add column if not exists api_course_id text;

alter table public.api_courses      enable row level security;
alter table public.api_course_tees  enable row level security;
alter table public.api_course_holes enable row level security;

drop policy if exists api_courses_read      on public.api_courses;
drop policy if exists api_course_tees_read  on public.api_course_tees;
drop policy if exists api_course_holes_read on public.api_course_holes;

-- authenticated read (hole-by-hole stepper, course cards); only the Edge
-- Function's service-role client writes.
create policy api_courses_read      on public.api_courses      for select to authenticated using (true);
create policy api_course_tees_read  on public.api_course_tees  for select to authenticated using (true);
create policy api_course_holes_read on public.api_course_holes for select to authenticated using (true);
