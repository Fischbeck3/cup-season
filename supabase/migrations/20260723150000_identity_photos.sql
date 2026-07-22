-- ============================================================================
-- Cup Season — photos arc 2, ckpt 2: identity (D59, the D36 reversal)
--
--   profiles.photo_path      avatar in the EXISTING private media bucket
--                            ({uid}/avatar.jpg — own-prefix policies already
--                            gate writes; signed-in reads; 8MB/image caps)
--   league_members.marker    per-league marker override (self-set)
--   set_profile              gains DEFAULTED p_photo_path (null=keep,
--                            ''=clear) — skew-safe both directions
--   set_league_marker        new self-only RPC
--   content_reports          widens to profile-photo reports (kind + target;
--                            post_id goes nullable)
--   report_content           4-arg replace (old 2-arg calls still bind)
--   founder_desk             gains the reports pane — the report table gets
--                            its first reader; also fixes live_open counting
--                            a status ('open') that live_rounds never had
-- ============================================================================

alter table public.profiles add column if not exists photo_path text;
alter table public.league_members add column if not exists marker text;

-- ---- set_profile: photo rides the same upsert (null keeps, '' clears) ------
-- Adding a defaulted param would OVERLOAD, not replace — drop the 6-arg first.
drop function if exists public.set_profile(text, text, text, numeric, text, text);
create or replace function public.set_profile(
  p_name text, p_city text default null, p_home text default null,
  p_index numeric default null, p_marker text default null, p_ghin text default null,
  p_photo_path text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_old text;
begin
  -- the avatar path is own-prefix by law (mirrors the storage policy)
  if p_photo_path is not null and p_photo_path <> ''
     and p_photo_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'photo path must live under your own prefix';
  end if;

  select display_name into v_old from profiles where id = auth.uid();

  insert into profiles (id, email, display_name, city, home_course, index_current, marker, ghin_number, photo_path)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker,
    nullif(trim(coalesce(p_ghin,'')), ''), nullif(p_photo_path, ''))
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker),
    ghin_number   = case when p_ghin is null then profiles.ghin_number
                         else nullif(trim(p_ghin), '') end,
    photo_path    = case when p_photo_path is null then profiles.photo_path
                         else nullif(p_photo_path, '') end;

  if p_name is not null and v_old is not null and trim(p_name) <> v_old then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(v_old) || ' NOW GOES BY ' || upper(trim(p_name))
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $$;
revoke all on function public.set_profile(text, text, text, numeric, text, text, text) from public, anon;
grant execute on function public.set_profile(text, text, text, numeric, text, text, text) to authenticated;

-- ---- per-league marker: yours to change, this league only ------------------
create or replace function public.set_league_marker(p_league uuid, p_marker text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_marker is not null and length(p_marker) > 24 then
    raise exception 'that is not a marker';
  end if;
  update league_members set marker = nullif(p_marker, '')
   where league_id = p_league and profile_id = auth.uid();
  if not found then raise exception 'not your league'; end if;
end $$;
revoke all on function public.set_league_marker(uuid, text) from public, anon;
grant execute on function public.set_league_marker(uuid, text) to authenticated;

-- ---- content reports learn about profile photos ----------------------------
alter table public.content_reports add column if not exists kind text not null default 'post';
alter table public.content_reports add column if not exists profile_id uuid references public.profiles(id) on delete cascade;
alter table public.content_reports alter column post_id drop not null;
alter table public.content_reports drop constraint if exists content_reports_target;
alter table public.content_reports add constraint content_reports_target
  check (post_id is not null or profile_id is not null);
-- (post_id, reporter) unique carries the post path; photo reports need their own
create unique index if not exists content_reports_photo_uni
  on public.content_reports (profile_id, reporter) where kind = 'profile_photo';

drop function if exists public.report_content(uuid, text);
create or replace function public.report_content(
  p_post uuid default null, p_reason text default null,
  p_kind text default 'post', p_profile uuid default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_kind = 'profile_photo' then
    if p_profile is null then raise exception 'nothing to report'; end if;
    -- same fence the Tour Card uses: you can report what you can see
    if not exists (
      select 1 from league_members a
        join league_members b on b.league_id = a.league_id
       where a.profile_id = auth.uid() and b.profile_id = p_profile
    ) and not exists (
      select 1 from friendships f
       where f.status = 'accepted'
         and ((f.requester = auth.uid() and f.addressee = p_profile)
           or (f.addressee = auth.uid() and f.requester = p_profile))
    ) and not exists (
      select 1 from event_players ea
        join event_players eb on eb.event_id = ea.event_id
       where ea.profile_id = auth.uid() and eb.profile_id = p_profile
    ) then
      raise exception 'You can only report golfers you share a league, event, or friendship with';
    end if;
    insert into content_reports (post_id, reporter, reason, kind, profile_id)
    values (null, auth.uid(), left(coalesce(p_reason,'profile photo'), 500), 'profile_photo', p_profile)
    on conflict (profile_id, reporter) where kind = 'profile_photo'
    do update set reason = excluded.reason, created_at = now();
    return;
  end if;

  if p_post is null then raise exception 'nothing to report'; end if;
  if not exists (
    select 1 from posts p join league_members lm on lm.league_id = p.league_id
     where p.id = p_post and lm.profile_id = auth.uid()
  ) then
    raise exception 'You can only report posts in your own leagues';
  end if;
  insert into content_reports (post_id, reporter, reason, kind)
  values (p_post, auth.uid(), left(coalesce(p_reason,''), 500), 'post')
  on conflict (post_id, reporter)
  do update set reason = excluded.reason, created_at = now();
end $$;
revoke all on function public.report_content(uuid, text, text, uuid) from public, anon;
grant execute on function public.report_content(uuid, text, text, uuid) to authenticated;

-- ---- founder desk: the reports pane (first reader) + live_open fix ---------
create or replace function public.founder_desk()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare out jsonb;
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'not yours';
  end if;
  select jsonb_build_object(
    'profiles_total', (select count(*) from profiles where deleted_at is null),
    'profiles_new_7d', (select count(*) from profiles
                        where created_at > now() - interval '7 days' and deleted_at is null),
    'newest', (select coalesce(jsonb_agg(jsonb_build_object(
                 'name', p.display_name, 'city', p.city,
                 'marker', p.marker is not null,
                 'at', p.created_at) order by p.created_at desc), '[]'::jsonb)
               from (select display_name, city, marker, created_at, deleted_at
                     from profiles where deleted_at is null
                     order by created_at desc limit 12) p),
    'rounds_total', (select count(*) from rounds),
    'rounds_7d', (select count(*) from rounds
                  where created_at > now() - interval '7 days'),
    'leagues', (select count(*) from leagues),
    'events', (select count(*) from events),
    -- live_rounds has no 'open' status; count what is actually on the course
    'live_open', (select count(*) from live_rounds where status in ('setup','live')),
    'posts_7d', (select count(*) from posts
                 where created_at > now() - interval '7 days'),
    'client_events', (select coalesce(jsonb_agg(jsonb_build_object(
                        'event', e.event, 'props', e.props,
                        'who', coalesce(pr.display_name, '?'),
                        'at', e.created_at) order by e.created_at desc), '[]'::jsonb)
                      from (select * from client_events
                            order by created_at desc limit 30) e
                      left join profiles pr on pr.id = e.profile_id),
    'feedback', (select coalesce(jsonb_agg(jsonb_build_object(
                   'cat', f.category, 'body', f.body,
                   'who', coalesce(pr.display_name, '?'),
                   'at', f.created_at) order by f.created_at desc), '[]'::jsonb)
                 from (select * from pilot_feedback
                       order by created_at desc limit 20) f
                 left join profiles pr on pr.id = f.profile_id),
    'reports', (select coalesce(jsonb_agg(jsonb_build_object(
                  'kind', r.kind, 'reason', r.reason, 'resolved', r.resolved,
                  'who', coalesce(rep.display_name, '?'),
                  'target', coalesce(tp.display_name, left(r.post_id::text, 8)),
                  'at', r.created_at) order by r.created_at desc), '[]'::jsonb)
                from (select * from content_reports
                      order by created_at desc limit 15) r
                left join profiles rep on rep.id = r.reporter
                left join profiles tp on tp.id = r.profile_id)
  ) into out;
  return out;
end $$;
revoke all on function public.founder_desk() from public, anon;
grant execute on function public.founder_desk() to authenticated;
