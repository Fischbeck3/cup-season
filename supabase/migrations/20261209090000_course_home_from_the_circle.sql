-- Cup Season — the Courses front door lists the courses your circle has played
-- (D391 correction, 2026-09-26).
--
-- WHAT IT CORRECTS: the phone's Courses tab shipped as the old offline inventory (courses
-- cached on this device) with the D391 circle section embedded in a course's detail. The
-- approved blend opens on the courses the circle has actually played. This producer is
-- that list; catalogue search and the offline inventory stay where they are, secondary.
--
--   course_home()  — every course with a real posted round in the viewer's circle,
--                    newest first, with truthful counts and up to four faces
--
-- THE SCOPE IS course_page's, EXACTLY: `_social_circle` (me · accepted friends · league
-- mates · event mates), round not void, gross posted, owner not deleted, no mute either
-- way, a non-empty stable api_course_id (matched exactly, as course_page matches it: an
-- id carrying stray whitespace is not a stable id and would open a page that counts
-- none of its rounds, so it is left out rather than silently trimmed). A stranger's round never reaches a row, so a
-- course only a stranger has played is not listed — nothing to infer. No gross, no
-- score, no photo is returned: the list names WHO and WHEN, and the course page (already
-- scoped the same way) is the only place a number appears. Read-only; no table changes.

create or replace function public.course_home()
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare
  v     uuid := auth.uid();
  v_lim constant int := 100;
  v_out jsonb;
begin
  if v is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;

  with rw as (
    select r.api_course_id cid, r.profile_id pid, c.relation rel,
           r.played_on, r.created_at, r.course_label label
      from rounds r
      join public._social_circle(v) c on c.pid = r.profile_id
      join profiles o on o.id = r.profile_id and o.deleted_at is null
     where r.api_course_id <> '' and r.api_course_id = btrim(r.api_course_id)
       and not r.voided and r.gross is not null
       and (r.profile_id = v or not public._social_blocked(v, r.profile_id))
  ),
  per_person as (
    select cid, pid, min(rel) rel, max(played_on) latest
      from rw group by cid, pid
  ),
  -- every eligible course is grouped BEFORE the limit, so courses_total is the truth
  courses as (
    select rw.cid,
           count(*) rounds_total,
           max(rw.played_on) latest,
           (array_agg(rw.label order by rw.played_on desc, rw.created_at desc)
              filter (where nullif(btrim(coalesce(rw.label, '')), '') is not null))[1] label
      from rw group by rw.cid
  ),
  page as (
    select * from courses order by latest desc, cid limit v_lim
  )
  select jsonb_build_object(
    'ok', true,
    'courses', coalesce((select jsonb_agg(jsonb_build_object(
        'api_course_id', pg.cid,
        'name', coalesce(nullif(btrim(coalesce(course_name_of(pg.cid, pg.label), '')), ''), 'Unnamed course'),
        'city', ac.city,
        'state', ac.state,
        'friends_total', (select count(*) from per_person pp where pp.cid = pg.cid and pp.rel = 'friend'),
        'people_total', (select count(*) from per_person pp where pp.cid = pg.cid),
        'rounds_total', pg.rounds_total,
        'latest_played_on', pg.latest,
        -- up to four faces: friends first, then league/event mates, the viewer last;
        -- one face per golfer however many rounds they posted
        'people', (select coalesce(jsonb_agg(jsonb_build_object(
                            'person', public._social_person(f.pid), 'relation', f.rel)
                          order by f.ord, f.latest desc, f.pid), '[]'::jsonb)
                     from (select pp.pid, pp.rel, pp.latest,
                                  case pp.rel when 'friend' then 1 when 'league' then 2
                                              when 'event' then 3 else 9 end ord
                             from per_person pp where pp.cid = pg.cid
                            order by ord, pp.latest desc, pp.pid
                            limit 4) f))
      order by pg.latest desc, pg.cid)
      from page pg left join api_courses ac on ac.id = pg.cid), '[]'::jsonb),
    'courses_total', (select count(*) from courses),
    'limit', v_lim)
    into v_out;

  return v_out;
end $$;

revoke all on function public.course_home() from public, anon;
grant execute on function public.course_home() to authenticated;

do $chk$
begin
  if not has_function_privilege('authenticated', 'public.course_home()', 'EXECUTE')
     or has_function_privilege('anon', 'public.course_home()', 'EXECUTE') then
    raise exception '[D391] course_home grants wrong';
  end if;
end $chk$;
