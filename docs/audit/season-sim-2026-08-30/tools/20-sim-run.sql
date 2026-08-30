-- ============================================================================
-- Season simulator — build / play / finish.
--
-- sim.build(slug, cfg)  creates the league through the real RPCs and seats the cast
-- sim.play(slug)        posts every week's rounds, closes months, runs the endgame
-- sim.result(slug)      the outcome record the report is written from
--
-- cfg shape:
--   { "name": "...", "structure": "squads2|squads3|squads4|solo",
--     "finish": "cup_final|points_table", "weeks": 12, "allowance": 95,
--     "counting_cap": 4, "floor": 2, "floor_penalty": "deduct|bye",
--     "buyin_cents": 5000, "payout": [60,25,15], "seed": "s1",
--     "cast": [ {"name","skill","vol","freq","trend","archetype","marker","index"} ] }
-- ============================================================================

-- ---- build ------------------------------------------------------------------
create or replace function sim.build(p_slug text, p_cfg jsonb) returns uuid
language plpgsql as $fn$
declare
  v_run uuid; v_league uuid; v_season uuid; v_pro uuid;
  c jsonb; i int; v_weeks int; v_ends date; v_starts date;
  v_code text; v_payout jsonb; v_uid uuid;
begin
  insert into sim.runs (slug, cfg) values (p_slug, p_cfg)
  on conflict (slug) do update set cfg = excluded.cfg
  returning id into v_run;

  -- seat 0 is the Pro, and the Pro plays (the realistic friend-league case)
  c := p_cfg->'cast'->0;
  v_pro := sim.actor(v_run, 0, c->>'name', c->>'archetype',
                     (c->>'skill')::numeric, (c->>'vol')::numeric,
                     (c->>'freq')::numeric, coalesce((c->>'trend')::numeric, 0),
                     coalesce(c->>'marker','saguaro'), (c->>'index')::numeric,
                     c->>'email');

  -- the league is born the way the app makes one
  perform sim.as_user(v_pro);
  v_code := upper(left(replace(p_slug,'-',''), 4) || left(md5(p_slug), 2));
  v_league := ((public.create_league(p_cfg->>'name', v_code))->'league'->>'id')::uuid;
  update sim.runs set league_id = v_league where id = v_run;
  update public.leagues set sandbox = true where id = v_league;

  -- the rest of the cast joins
  for i in 1 .. jsonb_array_length(p_cfg->'cast') - 1 loop
    c := p_cfg->'cast'->i;
    v_uid := sim.actor(v_run, i, c->>'name', c->>'archetype',
                       (c->>'skill')::numeric, (c->>'vol')::numeric,
                       (c->>'freq')::numeric, coalesce((c->>'trend')::numeric, 0),
                       coalesce(c->>'marker','shark'), (c->>'index')::numeric,
                       c->>'email');
    insert into public.league_members (league_id, profile_id, role, index_current, index_source)
    values (v_league, v_uid, 'player', (c->>'index')::numeric, 'self')
    on conflict do nothing;
  end loop;

  -- bylaws locked by the Pro, through the real function (identity really checked)
  -- Where in its life should this league be when we look at it?
  --   complete  : the whole season is behind us (the crowning is observable)
  --   cup_final : the 28-day window is open right now
  --   mid       : an ordinary week in the middle of a live season
  v_weeks  := (p_cfg->>'weeks')::int;
  case coalesce(p_cfg->>'phase_target', 'complete')
    when 'cup_final' then v_ends := current_date + 13;   -- ends_on-27 already passed
    when 'mid'       then v_ends := current_date + (v_weeks * 7 / 2);
    -- far enough back that close_season's real gate has passed:
    -- (ends_on + 1 day) in league tz + grace_hours (48) must be in the past
    else                  v_ends := current_date - 5;
  end case;
  v_starts := v_ends - (v_weeks * 7 - 1);
  v_payout := coalesce(p_cfg->'payout', '[60,25,15]'::jsonb);

  perform sim.as_user(v_pro);
  perform public.lock_league(
    v_league, p_cfg->>'name', 'standard',
    (p_cfg->>'allowance')::int, 'attested',
    (p_cfg->>'counting_cap')::int, (p_cfg->>'floor')::int,
    p_cfg->>'floor_penalty', coalesce(p_cfg->>'season_format','points'), p_cfg->>'structure',
    coalesce((p_cfg->>'buyin_cents')::int, 0),
    greatest(3, least(12, round(v_weeks / 4.345)::int)), 'random', p_cfg->>'finish',
    (v_payout->>0)::int, (v_payout->>1)::int, (v_payout->>2)::int,
    v_starts, v_ends);

  select id into v_season from public.seasons where league_id = v_league and number = 1;
  update sim.runs set season_id = v_season where id = v_run;

  -- the draw, then the tee-off.  start_season is the gate a real league passes
  -- (>= 4 golfers, nobody left in the pool, no empty squad) and the only thing
  -- that moves phase draft -> season.  Solo leagues are already in 'season'.
  if p_cfg->>'structure' <> 'solo' then
    perform public.randomize_squads(v_season);
    perform public.start_season(v_season);
  end if;

  -- Buy-ins: without a paid row the pot settles to nothing and every run
  -- reports "still owed", which would hide the settlement path entirely.
  if coalesce((p_cfg->>'buyins_paid')::boolean, false) and coalesce((p_cfg->>'buyin_cents')::int,0) > 0 then
    insert into public.buy_ins (season_id, member_id, amount_cents, paid, marked_at)
    select v_season, lm.id, (p_cfg->>'buyin_cents')::int, true, now()
      from public.league_members lm where lm.league_id = v_league
    on conflict do nothing;
  end if;

  return v_run;
end $fn$;

-- ---- one week of golf --------------------------------------------------------
create or replace function sim.week(p_run uuid, p_week int) returns int
language plpgsql as $fn$
declare
  se public.seasons%rowtype; a record;
  v_start date; v_day date; v_n int := 0; k int; v_cnt int;
  v_diff numeric; v_gross int; v_rating numeric; v_slope int; v_course text;
  v_seed text; v_pick int; v_slug text;
begin
  select s.* into se from public.seasons s
    join sim.runs r on r.season_id = s.id where r.id = p_run;
  select slug into v_slug from sim.runs where id = p_run;
  v_start := se.starts_on + ((p_week - 1) * 7);

  for a in select * from sim.actors where run_id = p_run order by seat loop
    v_seed := v_slug || ':' || a.seat || ':' || p_week;

    -- how many rounds this week: floor(freq) plus the fractional chance
    v_cnt := floor(a.freq)::int;
    if sim.u(v_seed || ':n') < (a.freq - floor(a.freq)) then v_cnt := v_cnt + 1; end if;

    for k in 1 .. greatest(v_cnt, 0) loop
      v_pick := 1 + floor(sim.u(v_seed || ':c' || k) * 5)::int;
      select c.label, c.rating, c.slope into v_course, v_rating, v_slope
        from (values ('Papago Golf Club', 72.1, 128), ('Encanto 18', 68.9, 117),
                     ('Aguila Golf Course', 71.4, 124), ('Dobson Ranch GC', 70.2, 121),
                     ('Grayhawk — Talon', 73.4, 135)) as c(label, rating, slope)
       offset (v_pick - 1) limit 1;

      v_diff  := a.skill + a.trend * p_week + sim.norm(v_seed || ':d' || k) * a.vol;
      v_diff  := greatest(-4, least(45, v_diff));
      v_gross := greatest(61, least(140, round(v_rating + v_diff * v_slope / 113.0)::int));
      v_day   := v_start + floor(sim.u(v_seed || ':day' || k) * 7)::int;
      if v_day > se.ends_on then v_day := se.ends_on; end if;
      if v_day > current_date then v_day := current_date; end if;

      insert into public.rounds (profile_id, gross, rating, slope, course_label,
                                 played_on, holes_played, source)
      values (a.profile_id, v_gross, v_rating, v_slope, v_course, v_day, 18, 'quick');
      v_n := v_n + 1;
    end loop;
  end loop;

  return v_n;
end $fn$;

-- ---- record the standings after week w --------------------------------------
create or replace function sim.snap(p_run uuid, p_week int) returns void
language plpgsql as $fn$
declare v_season uuid; v_struct text; v_league uuid;
begin
  select r.season_id, r.league_id into v_season, v_league from sim.runs r where r.id = p_run;
  select structure into v_struct from public.league_settings where league_id = v_league;

  delete from sim.timeline where run_id = p_run and week = p_week;

  -- Write the app's OWN week history too, in snapshot_week's exact payload
  -- shape, so momentum/history surfaces render real data in the screenshot
  -- pass.  snapshot_week itself cannot be used: it derives week_no from
  -- current_date, so every call inside one real day would collide on the
  -- unique (season_id, week_no) and do nothing.
  delete from public.standings_snapshots where season_id = v_season and week_no = p_week;
  insert into public.standings_snapshots (season_id, week_no, standings)
  values (v_season, p_week, jsonb_build_object(
    'squads', coalesce((select jsonb_agg(to_jsonb(t)) from
        (select * from public.v_squad_standings where season_id = v_season order by points desc) t), '[]'::jsonb),
    'individuals', coalesce((select jsonb_agg(to_jsonb(t)) from
        (select * from public.v_individual_standings where season_id = v_season order by points desc nulls last) t), '[]'::jsonb)));

  if v_struct = 'solo' then
    insert into sim.timeline (run_id, week, level, entity_id, label, points, rank)
    select p_run, p_week, 'member', s.member_id,
           p.display_name, s.points,
           rank() over (order by s.points desc)
      from public.v_individual_standings s
      join public.league_members lm on lm.id = s.member_id
      join public.profiles p on p.id = lm.profile_id
     where s.season_id = v_season;
  else
    insert into sim.timeline (run_id, week, level, entity_id, label, points, rank)
    select p_run, p_week, 'squad', s.squad_id, q.name, s.points,
           rank() over (order by s.points desc)
      from public.v_squad_standings s
      join public.squads q on q.id = s.squad_id
     where s.season_id = v_season;

    insert into sim.timeline (run_id, week, level, entity_id, label, points, rank)
    select p_run, p_week, 'member', s.member_id, p.display_name, s.points,
           rank() over (order by s.points desc)
      from public.v_individual_standings s
      join public.league_members lm on lm.id = s.member_id
      join public.profiles p on p.id = lm.profile_id
     where s.season_id = v_season;
  end if;
end $fn$;

-- ---- the whole season, in the engine's own order ----------------------------
create or replace function sim.play(p_slug text) returns jsonb
language plpgsql as $fn$
declare
  v_run uuid; se public.seasons%rowtype; v_cfg jsonb;
  v_weeks int; v_reg int; w int; m date; v_rounds int := 0; v_played int;
  v_week_end date; v_cupped boolean := false; v_finish text;
begin
  select id, cfg into v_run, v_cfg from sim.runs where slug = p_slug;
  select s.* into se from public.seasons s join sim.runs r on r.season_id = s.id where r.id = v_run;

  v_weeks  := (v_cfg->>'weeks')::int;
  v_finish := v_cfg->>'finish';
  -- the Cup Final is the last 4 weeks (ends_on − 27); the points table has none
  v_reg    := case when v_finish = 'cup_final' then greatest(1, v_weeks - 4) else v_weeks end;

  -- a live league has only played the weeks that have actually begun
  v_played := least(v_weeks, greatest(0, floor((current_date - se.starts_on) / 7.0)::int + 1));

  for w in 1 .. v_played loop
    v_rounds := v_rounds + sim.week(v_run, w);
    v_week_end := se.starts_on + (w * 7) - 1;

    -- close each calendar month once all of its rounds exist
    m := date_trunc('month', se.starts_on)::date;
    while m <= se.ends_on loop
      if (m + interval '1 month')::date - 1 <= v_week_end then
        perform public.close_month(se.id, m);
      end if;
      m := (m + interval '1 month')::date;
    end loop;

    -- seeds lock on the REGULAR season only — before the final four are played
    if not v_cupped and v_finish = 'cup_final' and w = v_reg then
      perform public.enter_cup_final(se.id);
      v_cupped := true;
    end if;

    perform sim.snap(v_run, w);
  end loop;

  -- The same two gates daily_season_tick applies — but evaluated for THIS
  -- season only.  daily_season_tick() loops every active season in the
  -- database, so calling it here would reach into real leagues and close
  -- their seasons.  The law is copied; the blast radius is not.
  select * into se from public.seasons where id = se.id;
  if se.status = 'active' and v_finish = 'cup_final'
     and current_date >= se.ends_on - 27 then
    perform public.enter_cup_final(se.id);
    select * into se from public.seasons where id = se.id;
  end if;
  if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
              + make_interval(hours => se.grace_hours)) then
    perform public.close_season(se.id);
  end if;

  return jsonb_build_object('slug', p_slug, 'weeks', v_weeks,
                            'weeks_played', v_played,
                            'regular_weeks', v_reg, 'rounds', v_rounds,
                            'status', (select status from public.seasons where id = se.id));
end $fn$;
