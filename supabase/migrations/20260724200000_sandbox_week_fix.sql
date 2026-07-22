-- ============================================================================
-- Cup Season — D65 fix: sandbox_week's day offset (date + bigint)
--
-- Caught on the first live run: `row_number() over (...)` is BIGINT, and it
-- fed the play-day offset — `v_start + ((b.rn * 2 + v_week) % 7)` — so Postgres
-- looked for `date + bigint` and found nothing. Every call failed before a
-- single round posted. Cast the row number to integer at the source.
-- ============================================================================

create or replace function public.sandbox_week(p_league uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  se seasons%rowtype;
  v_week integer; v_start date; v_day date;
  b record; v_diff numeric; v_gross integer; v_n integer := 0;
  v_rating numeric; v_slope integer; v_course text; v_pick integer;
begin
  perform assert_sandbox(p_league, true);
  select * into se from seasons where league_id = p_league
   and status in ('active','cup_final') order by number desc limit 1;
  if se.id is null then raise exception 'no active season'; end if;

  select coalesce(max(floor((r.played_on - se.starts_on) / 7)) + 1, 0)::integer
    into v_week
    from rounds r
    join profiles p on p.id = r.profile_id
   where p.email like '%@sandbox.cupseason.test'
     and r.played_on between se.starts_on and se.ends_on
     and r.profile_id in (select profile_id from league_members where league_id = p_league);

  v_start := se.starts_on + (v_week * 7);
  if v_start > current_date then
    raise exception 'the bots are caught up — rewind deeper or play on';
  end if;

  for b in
    select lm.profile_id, coalesce(p.index_current, lm.index_current, 15) as idx,
           (row_number() over (order by lm.joined_at))::integer as rn
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.league_id = p_league
       and p.email like '%@sandbox.cupseason.test'
  loop
    continue when b.rn > 3 and random() > 0.8;

    v_pick := 1 + floor(random() * 5)::integer;
    select c.label, c.rating, c.slope into v_course, v_rating, v_slope
      from (values ('Papago Golf Club', 72.1, 128), ('Encanto 18', 68.9, 117),
                   ('Aguila Golf Course', 71.4, 124), ('Dobson Ranch GC', 70.2, 121),
                   ('Grayhawk — Talon', 73.4, 135)) as c(label, rating, slope)
     offset (v_pick - 1) limit 1;

    v_diff  := greatest(-3, b.idx + (random() * 7 - 3.5));
    v_gross := greatest(61, least(140, round(v_rating + v_diff * v_slope / 113.0)::integer));
    v_day   := least(v_start + ((b.rn * 2 + v_week) % 7), current_date);

    insert into rounds (profile_id, gross, rating, slope, course_label,
                        played_on, holes_played, source)
    values (b.profile_id, v_gross, v_rating, v_slope, v_course, v_day, 18, 'quick');
    v_n := v_n + 1;
  end loop;

  return jsonb_build_object('week', v_week + 1, 'rounds_posted', v_n,
                            'week_of', v_start);
end $$;

revoke all on function public.sandbox_week(uuid) from public, anon;
grant execute on function public.sandbox_week(uuid) to authenticated;
