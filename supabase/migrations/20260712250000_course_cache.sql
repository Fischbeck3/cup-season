-- Course cache — Cup Season owns its course data.
--
-- Courses are looked up through the `courses` Edge Function, which holds the
-- GolfCourseAPI key server-side and upserts each picked course into these
-- tables. After the first lookup, play-time reads hit OUR database, never the
-- third-party API — so we're insulated from its rate limits, downtime, and
-- tier caps, and we accumulate the community course DB the seed strategy
-- calls for (spec §13.1). The API is a seed, not a runtime dependency.
--
-- Writes happen only via the Edge Function (service role, bypasses RLS).
-- Clients may read (for the hole-by-hole stepper, task #12) but never write.

create table if not exists public.courses (
  id          text primary key,          -- GolfCourseAPI course id (as text)
  club_name   text,
  course_name text,
  city        text,
  state       text,
  country     text,
  latitude    double precision,
  longitude   double precision,
  raw         jsonb,                      -- full payload, future-proofing
  cached_at   timestamptz not null default now()
);

create table if not exists public.course_tees (
  id              uuid primary key default gen_random_uuid(),
  course_id       text not null references public.courses(id) on delete cascade,
  gender          text,                   -- 'male' | 'female'
  tee_name        text,
  course_rating   numeric,
  slope_rating    integer,
  bogey_rating    numeric,
  par_total       integer,
  total_yards     integer,
  number_of_holes integer,
  unique (course_id, gender, tee_name)
);
create index if not exists course_tees_course_idx on public.course_tees(course_id);

create table if not exists public.course_holes (
  id          uuid primary key default gen_random_uuid(),
  tee_id      uuid not null references public.course_tees(id) on delete cascade,
  hole_number integer,
  par         integer,
  yardage     integer,
  handicap    integer,                    -- stroke index
  unique (tee_id, hole_number)
);
create index if not exists course_holes_tee_idx on public.course_holes(tee_id);

-- rounds gain an optional link to the cached course (nullable — manual-entry
-- and pre-cache rounds keep working; a purged course leaves the round intact).
alter table public.rounds
  add column if not exists course_id text references public.courses(id) on delete set null;

-- RLS: authenticated users may READ the cache (task #12 hole-by-hole stepper).
-- No write policies — only the Edge Function's service-role client writes.
alter table public.courses      enable row level security;
alter table public.course_tees  enable row level security;
alter table public.course_holes enable row level security;

drop policy if exists courses_read      on public.courses;
drop policy if exists course_tees_read  on public.course_tees;
drop policy if exists course_holes_read on public.course_holes;

create policy courses_read      on public.courses      for select to authenticated using (true);
create policy course_tees_read  on public.course_tees  for select to authenticated using (true);
create policy course_holes_read on public.course_holes for select to authenticated using (true);
