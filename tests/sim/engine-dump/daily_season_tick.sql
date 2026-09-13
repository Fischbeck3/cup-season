-- daily_season_tick() oid=18451
CREATE OR REPLACE FUNCTION public.daily_season_tick()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; v_finish text; v_local date; wcr record;
        v_floor integer; v_struct text; v_pen text;
        v_state text; v_msg text;
begin
  -- live rounds die on their own now: 24h after start, an unfinished round is
  -- abandoned — resume and join surfaces go dark server-side, not just client.
  update live_rounds
     set status = 'abandoned', finished_at = coalesce(finished_at, now())
   where status in ('setup', 'live')
     and started_at < now() - interval '24 hours';

  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- D193 · one league's bad day is its own. Every other cron entry point
    -- already isolates per subject; this one ran six live seasons in a single
    -- transaction, so a season that raised rolled back the whole tick and left
    -- no trace in job_failures — the job simply failed. The busiest days of the
    -- year for this loop are 2026-09-07 (five leagues roll their week at once)
    -- and 2026-09-08 (close_season runs on Sunset Match for the first time in
    -- the product's life), which is what made this worth fixing now.
    begin
    -- D204 · the first-tee horn: first tick on/after the first tee, league-
    -- local, once ever (the sentinel is the idempotence, as the original was).
    v_local := (now() at time zone se.timezone)::date;
    if se.status = 'active' and not se.kicked_off and v_local >= se.starts_on then
      update seasons set kicked_off = true where id = se.id;
      select participation_floor, structure, floor_penalty
        into v_floor, v_struct, v_pen
        from league_settings where league_id = se.league_id;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, se.id, 'system',
              'The season is live. Week 1 — rounds count from here.'
              || case when coalesce(v_floor, 0) > 0 and coalesce(v_struct, 'solo') <> 'solo'
                      then ' Post ' || v_floor || ' round' || case when v_floor = 1 then '' else 's' end
                           || ' a month'
                           || case when v_pen in ('deduct', 'forfeit')
                                   then ' — miss once and your bye covers it.'
                                   else '.' end
                      else '' end);
    end if;

    select finish into v_finish from league_settings where league_id = se.league_id;
    if se.status = 'active' and coalesce(v_finish,'cup_final') = 'cup_final'
       and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;

    -- D108: the weekly clash rides the tick. On the league's local date,
    -- settle every opened clash whose window has fully passed (the week-
    -- rollover detection — settles week N−1 on the increment, and self-heals
    -- across missed ticks and the season's final week), then open the current
    -- week's clash (which is also the first-run catch-up for live seasons).
    v_local := (now() at time zone se.timezone)::date;
    for wcr in
      select wc.week_no from week_clashes wc
       where wc.season_id = se.id and wc.settled_at is null
         and (se.starts_on + 7 * (wc.week_no - 1) + 6) < v_local
       order by wc.week_no
    loop
      perform settle_week_clash(se.id, wcr.week_no);
    end loop;
    perform open_week_clash(se.id);   -- no-ops outside the season / solo leagues
    -- D176 · and on the window's last day, say so. Runs AFTER the open so a
    -- one-week season's clash is opened and called on the same tick.
    perform clash_last_call(se.id);
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('daily_season_tick', 'season ' || se.id::text, v_state, v_msg);
      -- and on to the next league. A season that cannot tick must not stop
      -- anybody else's week from opening.
    end;
  end loop;
end $function$

