-- Cup Season — a course page names who of yours has played it, and its best by the
-- circle it was read from (D391 §4–5).
--
-- WHAT IT REPLACES ON THE PHONE: CoursePage.swift read `rounds` directly — league mates
-- and me only (never an accepted buddy), capped at the latest 60, and printed the
-- minimum of that page as a best. The minimum of an arbitrary recent page is not a best
-- of anything. This producer reads the whole eligible set on the server.
--
--   course_page(p_course_id, p_tee, p_holes)  — who played, dated histories, the circle
--                                               best with its source round(s), filters
--   posted_rounds_social(p_rounds uuid[])     — the comment door + course door for any feed
--
-- THE SCOPE IS THE CIRCLE and it is labelled so: "Your circle best", never a course
-- record. No existing consent publishes a stranger's gross app-wide (`discoverable` is a
-- search gate; no round carries an audience). Best = same api_course_id, same KNOWN tee
-- (_round_tee, never guessed), same hole count, not void, owner not deleted, no mute
-- either way. Ties are shared and every holder's round is returned.
-- Nines are never compared (no side is recorded); they stay in history. (D391 amended.) Gross only — no
-- scoring rule, points figure or band moves.

create index if not exists rounds_api_course_played
  on public.rounds (api_course_id, played_on desc) where api_course_id is not null and not voided;

create or replace function public.course_page(p_course_id text, p_tee text default null,
                                              p_holes integer default null)
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare
  v        uuid := auth.uid();
  v_course text := nullif(btrim(coalesce(p_course_id, '')), '');
  v_rows   jsonb;
  v_holes  int;
  v_tee    text;
  v_tee_nm text;
  v_meta   jsonb;
  v_out    jsonb;
begin
  if v is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if v_course is null then return jsonb_build_object('ok', false, 'reason', 'no_course'); end if;

  select jsonb_build_object('api_course_id', ac.id,
           'name', course_name_of(ac.id, null),
           'city', ac.city, 'state', ac.state, 'country', ac.country)
    into v_meta from api_courses ac where ac.id = v_course;

  -- every round at this course the viewer may see (no cap: the best reads all of them)
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', r.id, 'pid', r.profile_id, 'rel', c.relation, 'gross', r.gross,
           'holes', r.holes_played, 'played_on', r.played_on, 'created_at', r.created_at,
           'photo', r.photo_path is not null, 'label', r.course_label,
           'tee_key', t.tee_key, 'tee_name', t.tee_name, 'gender', t.gender,
           'rating', r.rating, 'slope', r.slope)), '[]'::jsonb)
    into v_rows
    from rounds r
    join public._social_circle(v) c on c.pid = r.profile_id
    join profiles o on o.id = r.profile_id and o.deleted_at is null
    left join lateral public._round_tee(r.api_course_id, r.course_label, r.rating, r.slope) t on true
   where r.api_course_id = v_course and not r.voided and r.gross is not null
     and (r.profile_id = v or not public._social_blocked(v, r.profile_id));

  if v_meta is null then
    -- a course whose cache row is gone still has a name on its rounds
    v_meta := jsonb_build_object('api_course_id', v_course,
      'name', (select course_name_of(v_course, x->>'label') from jsonb_array_elements(v_rows) x limit 1),
      'city', null, 'state', null, 'country', null);
  end if;

  -- the selection: a valid ask wins; otherwise 18 when any eighteen is known, and the
  -- tee with the most known rounds there (ties → most recent, then key)
  v_holes := case when p_holes in (9, 18) then p_holes
                  when exists (select 1 from jsonb_array_elements(v_rows) x
                                where x->>'tee_key' is not null and (x->>'holes')::int = 18) then 18
                  when exists (select 1 from jsonb_array_elements(v_rows) x
                                where x->>'tee_key' is not null and (x->>'holes')::int = 9) then 9
                  else 18 end;
  if p_tee is not null and exists (select 1 from jsonb_array_elements(v_rows) x where x->>'tee_key' = p_tee) then
    v_tee := p_tee;
  else
    select x->>'tee_key' into v_tee
      from jsonb_array_elements(v_rows) x
     where x->>'tee_key' is not null
     group by x->>'tee_key'
     order by count(*) filter (where (x->>'holes')::int = v_holes) desc,
              max(x->>'played_on') desc, x->>'tee_key'
     limit 1;
  end if;
  select min(x->>'tee_name') into v_tee_nm from jsonb_array_elements(v_rows) x where x->>'tee_key' = v_tee;

  with rw as (
    select (x->>'id')::uuid id, (x->>'pid')::uuid pid, x->>'rel' rel, (x->>'gross')::int gross,
           (x->>'holes')::int holes, (x->>'played_on')::date played_on,
           (x->>'created_at')::timestamptz created_at, (x->>'photo')::boolean photo,
           x->>'tee_key' tee_key, x->>'tee_name' tee_name, x->>'gender' gender,
           (x->>'rating')::numeric rating, (x->>'slope')::int slope,
           (x->>'tee_key' is not null and x->>'tee_key' = v_tee and (x->>'holes')::int = v_holes) sel,
           -- D391 (amended) · ELIGIBLE for a best: in the selection AND eighteen holes.
           -- No round records WHICH nine was played (quick posts carry no holes, and
           -- both clients number a nine's hole rows 1..9 whichever side it was), so a
           -- front 34 and a back 34 are not comparable; nines stay in history only.
           (x->>'tee_key' is not null and x->>'tee_key' = v_tee and (x->>'holes')::int = v_holes
            and v_holes = 18) elig
      from jsonb_array_elements(v_rows) x
  ),
  best as (select min(gross) g, count(*) n from rw where elig),
  holders as (
    select coalesce(jsonb_agg(jsonb_build_object('round_id', rw.id,
                      'person', public._social_person(rw.pid), 'played_on', rw.played_on)
                    order by rw.played_on, rw.created_at, rw.id), '[]'::jsonb) j,
           count(*) n
      from rw, best where rw.elig and rw.gross = best.g
  ),
  mine as (
    select (select jsonb_build_object('gross', m.gross, 'round_id', m.id, 'played_on', m.played_on)
              from rw m where m.elig and m.pid = v
             order by m.gross, m.played_on, m.created_at limit 1) j,
           (select count(*) from rw m where m.elig and m.pid = v) n
  ),
  people as (
    select rw.pid, min(rw.rel) rel, count(*) total, max(rw.played_on) latest,
           (select jsonb_build_object('gross', b.gross, 'round_id', b.id, 'played_on', b.played_on)
              from rw b where b.pid = rw.pid and b.elig
             order by b.gross, b.played_on, b.created_at limit 1) best_sel,
           (select min(b.gross) from rw b where b.pid = rw.pid and b.elig) best_g,
           (select coalesce(jsonb_agg(jsonb_build_object(
                     'round_id', h.id, 'played_on', h.played_on, 'gross', h.gross, 'holes', h.holes,
                     'tee_key', h.tee_key, 'tee_name', h.tee_name, 'has_photo', h.photo,
                     'in_selection', h.sel) order by h.played_on desc, h.created_at desc), '[]'::jsonb)
              from (select * from rw h0 where h0.pid = rw.pid
                     order by h0.played_on desc, h0.created_at desc limit 30) h) hist
      from rw group by rw.pid
  ),
  tees as (
    select coalesce(jsonb_agg(jsonb_build_object('key', t.tee_key, 'name', t.nm, 'gender', t.g,
                      'rating', t.rating, 'slope', t.slope, 'rounds', t.n)
                    order by t.n desc, t.nm, t.tee_key), '[]'::jsonb) j
      from (select tee_key, min(tee_name) nm,
                   case when count(distinct coalesce(gender, '')) = 1 then min(gender) end g,
                   min(rating) rating, min(slope) slope, count(*) n
              from rw where tee_key is not null group by tee_key) t
  )
  select jsonb_build_object(
    'ok', true,
    'course', v_meta,
    'scope', jsonb_build_object('key', 'circle', 'label', 'Your circle',
               'best_label', 'Your circle best',
               'note', 'From your rounds, your friends'' rounds and the rounds of the golfers in your seasons, Ryders and Majors. Not an official course record.'),
    'selection', jsonb_build_object('tee_key', v_tee, 'tee_name', v_tee_nm, 'holes', v_holes),
    'tees', (select j from tees),
    'holes_options', (select coalesce(jsonb_agg(jsonb_build_object('holes', h, 'rounds',
                         (select count(*) from rw where rw.tee_key = v_tee and rw.holes = h)) order by h desc), '[]'::jsonb)
                        from unnest(array[18, 9]) h
                       where exists (select 1 from rw where rw.tee_key = v_tee and rw.holes = h)),
    'unknown_tee_rounds', (select count(*) from rw where tee_key is null),
    -- D391 (amended) · why `best` is null when it is null for a reason other than
    -- "nobody has one yet": a nine has no side on record, so it has no best.
    'best_unavailable', case when v_holes = 9 then 'nine_side_unrecorded' end,
    'best', (select case when best.n = 0 then null else jsonb_build_object(
                'gross', best.g, 'tied', holders.n > 1, 'eligible_rounds', best.n,
                'holders', holders.j) end from best, holders),
    'my_best', (select case when mine.j is null then null
                            else mine.j || jsonb_build_object('rounds', mine.n) end from mine),
    'people_total', (select count(*) from people),
    'people', (select coalesce(jsonb_agg(jsonb_build_object(
                 'person', public._social_person(pe.pid), 'relation', pe.rel,
                 'rounds_total', pe.total, 'latest_played_on', pe.latest,
                 'best_in_selection', pe.best_sel, 'rounds', pe.hist)
               order by pe.best_g nulls last, pp.display_name, pe.pid), '[]'::jsonb)
                 from people pe join profiles pp on pp.id = pe.pid))
    into v_out;

  return v_out;
end $$;

-- The comment door + course door for any feed of posted rounds.
create or replace function public.posted_rounds_social(p_rounds uuid[])
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare v uuid := auth.uid(); v_out jsonb;
begin
  if v is null then return jsonb_build_object('items', '[]'::jsonb); end if;
  with ids as (
    select distinct x.id from unnest(coalesce(p_rounds, '{}'::uuid[])) x(id) limit 60
  ),
  circle as (select * from public._social_circle(v)),
  vis as (
    select r.* from rounds r join ids on ids.id = r.id
     where public._posted_round_visible(v, r.id)
  ),
  at_course as (
    select r.api_course_id, r.profile_id, max(r.played_on) last_on, min(c.relation) rel
      from rounds r
      join circle c on c.pid = r.profile_id
      join profiles o on o.id = r.profile_id and o.deleted_at is null
     where r.api_course_id in (select api_course_id from vis where api_course_id is not null)
       and not r.voided
       and (r.profile_id = v or not public._social_blocked(v, r.profile_id))
     group by r.api_course_id, r.profile_id
  )
  select jsonb_build_object('items', coalesce(jsonb_agg(jsonb_build_object(
      'round_id', vr.id,
      'comment_count', (select count(*) from public._round_thread_rows(vr.id)),
      'can_comment', true,
      'thread_state', coalesce((select s.state from round_thread_states s
                                 where s.profile_id = v and s.round_id = vr.id), 'none'),
      'course', case when vr.api_course_id is null then null else jsonb_build_object(
          'api_course_id', vr.api_course_id,
          'name', course_name_of(vr.api_course_id, vr.course_label),
          'circle_golfers', (select count(*) from at_course a where a.api_course_id = vr.api_course_id),
          'faces', (select coalesce(jsonb_agg(public._social_person(f.profile_id)
                                              order by (f.rel = 'friend') desc, f.last_on desc, f.profile_id), '[]'::jsonb)
                      from (select * from at_course a
                             where a.api_course_id = vr.api_course_id and a.profile_id <> v
                             order by (a.rel = 'friend') desc, a.last_on desc, a.profile_id
                             limit 3) f)) end)), '[]'::jsonb))
    into v_out
    from vis vr;
  return v_out;
end $$;

revoke all on function public.course_page(text, text, integer)   from public, anon;
revoke all on function public.posted_rounds_social(uuid[])       from public, anon;
grant execute on function public.course_page(text, text, integer) to authenticated;
grant execute on function public.posted_rounds_social(uuid[])     to authenticated;

do $chk$
begin
  if not has_function_privilege('authenticated', 'public.course_page(text,text,integer)', 'EXECUTE')
     or has_function_privilege('anon', 'public.course_page(text,text,integer)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.posted_rounds_social(uuid[])', 'EXECUTE')
     or has_function_privilege('anon', 'public.posted_rounds_social(uuid[])', 'EXECUTE') then
    raise exception '[D391] course grants wrong';
  end if;
end $chk$;
