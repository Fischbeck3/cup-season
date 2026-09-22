-- The course provider is external; replacing a cached card is one transaction.
-- Only the courses Edge Function's service role can write this cache.
create or replace function public.cache_course_card(p_course jsonb, p_tees jsonb)
returns text language plpgsql security definer set search_path = public, pg_temp as $$
declare
  cid text := p_course->>'id';
  te jsonb;
  tid uuid;
  hole jsonb;
begin
  if nullif(cid, '') is null or jsonb_typeof(p_tees) is distinct from 'array'
     or jsonb_array_length(p_tees) = 0 then
    raise exception 'Course card is incomplete';
  end if;
  -- Serializes refreshes of the same course, including the first insert.
  perform pg_advisory_xact_lock(hashtextextended('course-cache:' || cid, 0));
  insert into api_courses(id, club_name, course_name, city, state, country, latitude, longitude, raw, cached_at)
  values(cid, p_course->>'club_name', p_course->>'course_name', p_course#>>'{location,city}',
    p_course#>>'{location,state}', p_course#>>'{location,country}',
    (p_course#>>'{location,latitude}')::double precision, (p_course#>>'{location,longitude}')::double precision,
    p_course, now())
  on conflict(id) do update set club_name=excluded.club_name, course_name=excluded.course_name,
    city=excluded.city, state=excluded.state, country=excluded.country, latitude=excluded.latitude,
    longitude=excluded.longitude, raw=excluded.raw, cached_at=excluded.cached_at;
  for te in select value from jsonb_array_elements(p_tees) loop
    if nullif(btrim(te->>'tee_name'), '') is null or coalesce(te->>'gender','') not in ('male','female')
      or jsonb_typeof(te->'holes') is distinct from 'array' then
      raise exception 'Invalid tee card';
    end if;
    insert into api_course_tees(course_id, gender, tee_name, course_rating, slope_rating,
      bogey_rating, par_total, total_yards, number_of_holes)
    values(cid, te->>'gender', te->>'tee_name', (te->>'course_rating')::numeric,
      (te->>'slope_rating')::integer, (te->>'bogey_rating')::numeric, (te->>'par_total')::integer,
      (te->>'total_yards')::integer, (te->>'number_of_holes')::integer)
    on conflict(course_id, gender, tee_name) do update set course_rating=excluded.course_rating,
      slope_rating=excluded.slope_rating, bogey_rating=excluded.bogey_rating, par_total=excluded.par_total,
      total_yards=excluded.total_yards, number_of_holes=excluded.number_of_holes
    returning id into tid;
    -- A sparse provider response must not erase the card already kept.
    if jsonb_array_length(te->'holes') > 0 then
      delete from api_course_holes where tee_id=tid;
      for hole in select value from jsonb_array_elements(te->'holes') loop
        if (hole->>'hole_number')::integer not between 1 and 18 or hole->>'hole_number' is null then
          raise exception 'Invalid hole number';
        end if;
        insert into api_course_holes(tee_id,hole_number,par,yardage,handicap)
        values(tid,(hole->>'hole_number')::integer,(hole->>'par')::integer,
          (hole->>'yardage')::integer,(hole->>'handicap')::integer);
      end loop;
    end if;
  end loop;
  -- Retain unreturned tees: absence in a provider response does not prove removal.
  return cid;
end;
$$;
revoke all on function public.cache_course_card(jsonb,jsonb) from public, anon, authenticated;
grant execute on function public.cache_course_card(jsonb,jsonb) to service_role;
