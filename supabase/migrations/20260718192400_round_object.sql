-- ============================================================================
-- The scheduled round becomes a first-class object (spec/scheduled-rounds-arc.md,
-- D38). Stages 1–3 schema + the RPCs the detail sheet reads/writes, plus a
-- weather cache (Stage 5) and course/league links (Stage 1). Weather + course
-- info degrade gracefully client-side when absent — never a blank panel.
--
-- Additive + deploy-skew-safe: new columns default null, new RPCs are called
-- with fallbacks, and the client hides a section until its data exists.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Stage 1 · the round carries a course link (for real course info + weather)
-- and an optional league (retires the shared_league proxy from D38 later).
-- Course info stays optional: a typed course_label always works.
-- ---------------------------------------------------------------------------
alter table public.scheduled_rounds add column if not exists course_id text references public.api_courses(id) on delete set null;
alter table public.scheduled_rounds add column if not exists league_id uuid references public.leagues(id) on delete set null;

-- ---------------------------------------------------------------------------
-- Visibility helper: who can see (and therefore RSVP to / comment on) a round.
-- Mirrors my_schedule's WHERE exactly — owner, tagged, an accepted friend, or a
-- league-mate. One definer function so the RPCs below all agree.
-- ---------------------------------------------------------------------------
create or replace function public.can_see_round(p_round uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from scheduled_rounds sr
    where sr.id = p_round and (
      sr.profile_id = auth.uid()
      or auth.uid() = any(sr.tagged)
      or exists (select 1 from friendships f where f.status = 'accepted'
                 and ((f.requester = auth.uid() and f.addressee = sr.profile_id)
                   or (f.addressee = auth.uid() and f.requester = sr.profile_id)))
      or exists (select 1 from league_members a
                 join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = sr.profile_id)
    ));
$$;
revoke all on function public.can_see_round(uuid) from public;
grant execute on function public.can_see_round(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Stage 2 · RSVP. One row per (round, golfer). Writes flow through the RPC.
-- ---------------------------------------------------------------------------
create table if not exists public.round_rsvp (
  round_id   uuid not null references public.scheduled_rounds(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  status     text not null check (status in ('in','maybe','out')),
  updated_at timestamptz not null default now(),
  primary key (round_id, profile_id)
);
alter table public.round_rsvp enable row level security;
create policy round_rsvp_read on public.round_rsvp for select to authenticated
  using (public.can_see_round(round_id));
-- writes are RPC-only (security definer); no insert/update policy on purpose.

create or replace function public.set_round_rsvp(p_round uuid, p_status text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_status not in ('in','maybe','out') then raise exception 'bad status'; end if;
  if not can_see_round(p_round) then raise exception 'You can only RSVP to rounds you can see'; end if;
  insert into round_rsvp (round_id, profile_id, status)
  values (p_round, auth.uid(), p_status)
  on conflict (round_id, profile_id) do update set status = excluded.status, updated_at = now();
end $$;
revoke all on function public.set_round_rsvp(uuid, text) from public;
grant execute on function public.set_round_rsvp(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Stage 3 · comments (the round's own mini board).
-- ---------------------------------------------------------------------------
create table if not exists public.round_comments (
  id         uuid primary key default gen_random_uuid(),
  round_id   uuid not null references public.scheduled_rounds(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now()
);
create index if not exists round_comments_idx on public.round_comments (round_id, created_at);
alter table public.round_comments enable row level security;
create policy round_comments_read on public.round_comments for select to authenticated
  using (public.can_see_round(round_id));
create policy round_comments_del on public.round_comments for delete to authenticated
  using (profile_id = auth.uid());   -- delete your own

create or replace function public.add_round_comment(p_round uuid, p_body text) returns void
language plpgsql security definer set search_path = public as $$
declare v_body text := nullif(trim(coalesce(p_body,'')), '');
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if v_body is null then raise exception 'Say something first'; end if;
  if length(v_body) > 500 then raise exception 'Keep it under 500 characters'; end if;
  if not can_see_round(p_round) then raise exception 'You can only post on rounds you can see'; end if;
  insert into round_comments (round_id, profile_id, body) values (p_round, auth.uid(), v_body);
end $$;
revoke all on function public.add_round_comment(uuid, text) from public;
grant execute on function public.add_round_comment(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Stage 5 · weather cache. The `weather` Edge Function fetches Open-Meteo
-- (keyless) and upserts here so a busy day's sheet doesn't refetch. Read-only
-- to clients; the function writes with the service role.
-- ---------------------------------------------------------------------------
create table if not exists public.weather_cache (
  course_id  text,
  play_on    date not null,
  lat        double precision,
  lon        double precision,
  payload    jsonb,               -- {temp_hi, temp_lo, code, wind, summary}
  fetched_at timestamptz not null default now(),
  primary key (course_id, play_on)
);
alter table public.weather_cache enable row level security;
create policy weather_read on public.weather_cache for select to authenticated using (true);
-- writes are service-role only (the Edge Function).

-- ---------------------------------------------------------------------------
-- The detail sheet's single data source: the round + course (if linked) + the
-- RSVP list + comments, in one call. can_see_round gates it. Returns null-ish
-- course when unlinked so the client shows the typed label (never blank).
-- ---------------------------------------------------------------------------
create or replace function public.round_detail(p_round uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare r record; v jsonb;
begin
  if not can_see_round(p_round) then raise exception 'Round not found'; end if;
  select sr.*, p.display_name owner_name, p.marker owner_marker
    into r from scheduled_rounds sr join profiles p on p.id = sr.profile_id
   where sr.id = p_round;

  v := jsonb_build_object(
    'id', r.id, 'profile_id', r.profile_id, 'owner_name', r.owner_name,
    'owner_marker', r.owner_marker, 'mine', r.profile_id = auth.uid(),
    'play_on', r.play_on, 'tee_time', r.tee_time, 'note', r.note,
    'course_label', r.course_label, 'course_id', r.course_id, 'league_id', r.league_id,
    'my_rsvp', (select status from round_rsvp where round_id = r.id and profile_id = auth.uid()),
    -- course info from the cache, if linked (a representative tee's rating/slope/par)
    'course', (
      select jsonb_build_object('name', coalesce(c.club_name, c.course_name), 'city', c.city,
               'state', c.state, 'lat', c.latitude, 'lon', c.longitude,
               'rating', t.course_rating, 'slope', t.slope_rating, 'par', t.par_total,
               'tee', t.tee_name)
        from api_courses c
        left join lateral (select * from api_course_tees where course_id = c.id
                           order by number_of_holes desc nulls last, par_total desc nulls last limit 1) t on true
       where c.id = r.course_id),
    -- RSVP: everyone tagged plus anyone who responded, with their status
    'rsvp', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'profile_id', x.pid, 'name', pp.display_name, 'marker', pp.marker,
               'status', rr.status) order by (x.pid = r.profile_id) desc, pp.display_name), '[]'::jsonb)
        from (
          select r.profile_id pid
          union select unnest(coalesce(r.tagged,'{}'::uuid[]))
          union select profile_id from round_rsvp where round_id = r.id
        ) x
        join profiles pp on pp.id = x.pid
        left join round_rsvp rr on rr.round_id = r.id and rr.profile_id = x.pid),
    -- comments, oldest first
    'comments', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'name', pp.display_name, 'marker', pp.marker, 'body', rc.body,
               'mine', rc.profile_id = auth.uid(), 'at', rc.created_at) order by rc.created_at), '[]'::jsonb)
        from round_comments rc join profiles pp on pp.id = rc.profile_id
       where rc.round_id = r.id)
  );
  return v;
end $$;
revoke all on function public.round_detail(uuid) from public;
grant execute on function public.round_detail(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- declare_round gains p_course_id (link a picked course). Same body as
-- 20260715230000 otherwise; the client sends the id when the golfer picks a
-- real course, null when they free-type.
-- ---------------------------------------------------------------------------
create or replace function public.declare_round(
  p_play_on date, p_course text, p_note text,
  p_tagged uuid[] default '{}', p_tee time default null, p_course_id text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid; v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note text := nullif(trim(coalesce(p_note,'')), ''); v_tags uuid[];
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then raise exception 'Pick a day that has not happened yet'; end if;
  if p_play_on > current_date + 365 then raise exception 'One year out is far enough'; end if;
  if v_note is not null and length(v_note) > 140 then raise exception 'Notes cap at 140 characters'; end if;
  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged,'{}')) t(pid) where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee, nullif(trim(coalesce(p_course_id,'')),''))
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.declare_round(date,text,text,uuid[],time,text) from public;
grant execute on function public.declare_round(date,text,text,uuid[],time,text) to authenticated;

-- ---------------------------------------------------------------------------
-- my_schedule gains card glances: course_id, how many are IN, my RSVP, and a
-- comment count — so calendar rows and Home cards can show life without the
-- full detail call. Same visibility WHERE as before.
-- ---------------------------------------------------------------------------
drop function if exists public.my_schedule(date, date);
create or replace function public.my_schedule(p_from date, p_to date)
returns table (
  id uuid, profile_id uuid, display_name text, marker text,
  play_on date, course_label text, note text, tee_time time,
  mine boolean, is_friend boolean, shared_league boolean,
  tagged_names text[], tagged_me boolean,
  course_id text, rsvp_in integer, my_rsvp text, comment_n integer
)
language sql stable security definer set search_path = public as $$
  select sr.id, sr.profile_id, p.display_name, p.marker,
         sr.play_on, sr.course_label, sr.note, sr.tee_time,
         sr.profile_id = auth.uid() as mine,
         exists (select 1 from friendships f where f.status='accepted'
                  and ((f.requester=auth.uid() and f.addressee=sr.profile_id)
                    or (f.addressee=auth.uid() and f.requester=sr.profile_id))) as is_friend,
         exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
                  where a.profile_id=auth.uid() and b.profile_id=sr.profile_id
                    and sr.profile_id <> auth.uid()) as shared_league,
         (select array_agg(p2.display_name order by p2.display_name)
            from profiles p2 where p2.id = any(sr.tagged)) as tagged_names,
         auth.uid() = any(sr.tagged) as tagged_me,
         sr.course_id,
         (select count(*)::int from round_rsvp where round_id = sr.id and status = 'in') as rsvp_in,
         (select status from round_rsvp where round_id = sr.id and profile_id = auth.uid()) as my_rsvp,
         (select count(*)::int from round_comments where round_id = sr.id) as comment_n
    from scheduled_rounds sr
    join profiles p on p.id = sr.profile_id
   where sr.play_on between p_from and p_to
     and ( sr.profile_id = auth.uid()
        or auth.uid() = any(sr.tagged)
        or exists (select 1 from friendships f where f.status='accepted'
                    and ((f.requester=auth.uid() and f.addressee=sr.profile_id)
                      or (f.addressee=auth.uid() and f.requester=sr.profile_id)))
        or exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
                    where a.profile_id=auth.uid() and b.profile_id=sr.profile_id) )
   order by sr.play_on, sr.tee_time nulls last, sr.created_at;
$$;
grant execute on function public.my_schedule(date, date) to authenticated;
