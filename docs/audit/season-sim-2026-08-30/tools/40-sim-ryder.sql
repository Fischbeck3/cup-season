-- ============================================================================
-- Ryder simulator — whole events against the real engine.
--
-- Same fidelity rules as the season sim:
--   · the event is born through the real create_event() called as the organiser
--     (so the Sunday-start rule, the tz resolution and the auto-captain all
--     really run), and players join through add_event_player/set_event_team.
--   · rounds are direct inserts into public.rounds, exactly as the client does.
--   · each session is opened by the engine's own generate_pairings() and closed
--     by its own resolve_session(), in the order run_event_sessions() would
--     reach them:
--         session upcoming + window open  -> generate_pairings
--         session open     + window past  -> resolve_session
--     run_event_sessions() itself is NOT called: it loops every event in the
--     database and would reach into real ones.
--
-- A duel is won by the better pvi (index_at_post × allowance/100 − differential)
-- among rounds played inside that session's window; both sides missing halves it,
-- one side missing is a walkover. So "who showed up" is a first-class outcome
-- here in a way it never is in the season — which is the thing worth measuring.
-- ============================================================================

create table if not exists sim.events (
  run_id   uuid references sim.runs(id) on delete cascade,
  event_id uuid,
  primary key (run_id)
);

-- ---- build ------------------------------------------------------------------
create or replace function sim.ryder(p_slug text, p_cfg jsonb) returns uuid
language plpgsql as $fn$
declare
  v_run uuid; v_event uuid; v_org uuid; v_uid uuid;
  v_ta uuid; v_tb uuid; c jsonb; i int;
  v_sessions int; v_weeks int; v_start date; v_pid uuid;
begin
  insert into sim.runs (slug, cfg) values (p_slug, p_cfg)
  on conflict (slug) do update set cfg = excluded.cfg
  returning id into v_run;

  v_sessions := coalesce((p_cfg->>'sessions')::int, 4);
  v_weeks    := coalesce((p_cfg->>'session_weeks')::int, 1);

  -- seat 0 is the organiser, and create_event makes them captain of team A
  c := p_cfg->'cast'->0;
  v_org := sim.actor(v_run, 0, c->>'name', c->>'archetype',
                     (c->>'skill')::numeric, (c->>'vol')::numeric,
                     (c->>'freq')::numeric, coalesce((c->>'trend')::numeric, 0),
                     coalesce(c->>'marker','saguaro'), (c->>'index')::numeric,
                     c->>'email');

  -- the whole event must be in the past so every window can open AND close.
  -- create_event refuses a non-Sunday start ("sessions run Sun to Sat"), so
  -- walk back to the Sunday on or before the required date.
  v_start := current_date - (v_sessions * v_weeks * 7) - 3;
  v_start := v_start - extract(dow from v_start)::int;   -- dow 0 = Sunday

  perform sim.as_user(v_org);
  v_event := public.create_event(
    p_cfg->>'name', v_start, v_sessions, v_weeks,
    coalesce(p_cfg->>'draw_rule','team_pvi'),
    coalesce(p_cfg->>'team_a','Reds'), coalesce(p_cfg->>'team_b','Blues'),
    null, 'America/Phoenix', null);

  insert into sim.events (run_id, event_id) values (v_run, v_event)
  on conflict (run_id) do update set event_id = excluded.event_id;
  update sim.runs set league_id = null where id = v_run;

  select id into v_ta from public.event_teams where event_id = v_event and slot = 0;
  select id into v_tb from public.event_teams where event_id = v_event and slot = 1;

  -- the rest of the cast: even seats to A, odd to B
  for i in 1 .. jsonb_array_length(p_cfg->'cast') - 1 loop
    c := p_cfg->'cast'->i;
    v_uid := sim.actor(v_run, i, c->>'name', c->>'archetype',
                       (c->>'skill')::numeric, (c->>'vol')::numeric,
                       (c->>'freq')::numeric, coalesce((c->>'trend')::numeric, 0),
                       coalesce(c->>'marker','shark'), (c->>'index')::numeric,
                       c->>'email');
    -- D148: an organiser may only add a league-mate or a buddy. A standalone
    -- event has no league, so the cast are the organiser's buddies — which is
    -- what they would really be. This is the sim obeying the new consent gate,
    -- not working around it: anyone else has to be invited and accept.
    insert into public.friendships (requester, addressee, status, responded_at)
    values (v_org, v_uid, 'accepted', now())
    on conflict do nothing;

    perform sim.as_user(v_org);
    perform public.add_event_player(v_event, v_uid);
    select id into v_pid from public.event_players
     where event_id = v_event and profile_id = v_uid;
    perform public.set_event_team(v_pid, case when i % 2 = 0 then v_ta else v_tb end);
  end loop;

  return v_run;
end $fn$;

-- ---- play the whole event ----------------------------------------------------
create or replace function sim.ryder_play(p_slug text) returns jsonb
language plpgsql as $fn$
declare
  v_run uuid; v_event uuid; v_cfg jsonb; s record; a record;
  v_n int := 0; v_paired int; k int; v_cnt int;
  v_diff numeric; v_gross int; v_rating numeric; v_slope int; v_course text;
  v_seed text; v_pick int; v_day date;
begin
  select r.id, r.cfg, e.event_id into v_run, v_cfg, v_event
    from sim.runs r join sim.events e on e.run_id = r.id where r.slug = p_slug;

  for s in select * from public.event_sessions
            where event_id = v_event order by session_no loop
    -- D146: the tick now scans 'complete' too, so a clinched event's remaining
    -- sessions still open and resolve for the record. resolve_session refuses
    -- to re-decide a settled event, so the cup cannot move. Before D146 the
    -- loop exited here and the rest of the calendar was stranded.

    -- the tick's first arm: the window has opened and both sides have players
    perform sim.as_user((select profile_id from sim.actors where run_id = v_run and seat = 0));
    v_paired := public.generate_pairings(s.id);

    -- everybody plays their week (or does not — a no-show is a walkover)
    for a in select * from sim.actors where run_id = v_run order by seat loop
      v_seed := p_slug || ':' || a.seat || ':' || s.session_no;
      v_cnt := floor(a.freq)::int;
      if sim.u(v_seed || ':n') < (a.freq - floor(a.freq)) then v_cnt := v_cnt + 1; end if;

      for k in 1 .. greatest(v_cnt, 0) loop
        v_pick := 1 + floor(sim.u(v_seed || ':c' || k) * 5)::int;
        select c.label, c.rating, c.slope into v_course, v_rating, v_slope
          from (values ('Papago Golf Club', 72.1, 128), ('Encanto 18', 68.9, 117),
                       ('Aguila Golf Course', 71.4, 124), ('Dobson Ranch GC', 70.2, 121),
                       ('Grayhawk — Talon', 73.4, 135)) as c(label, rating, slope)
         offset (v_pick - 1) limit 1;
        v_diff  := greatest(-4, least(45, a.skill + sim.norm(v_seed || ':d' || k) * a.vol));
        v_gross := greatest(61, least(140, round(v_rating + v_diff * v_slope / 113.0)::int));
        v_day   := s.opens_on + floor(sim.u(v_seed || ':day' || k) * (s.closes_on - s.opens_on + 1))::int;
        if v_day > current_date then v_day := current_date; end if;

        insert into public.rounds (profile_id, gross, rating, slope, course_label,
                                   played_on, holes_played, source)
        values (a.profile_id, v_gross, v_rating, v_slope, v_course, v_day, 18, 'quick');
        v_n := v_n + 1;
      end loop;
    end loop;

    -- the tick's second arm: the window has passed
    perform sim.as_user((select profile_id from sim.actors where run_id = v_run and seat = 0));
    perform public.resolve_session(s.id);
  end loop;

  perform public.award_event_trophies(v_event);

  return jsonb_build_object('slug', p_slug, 'rounds', v_n,
                            'status', (select status from public.events where id = v_event));
end $fn$;

-- ---- the result --------------------------------------------------------------
create or replace function sim.ryder_result(p_slug text) returns jsonb
language plpgsql as $fn$
declare v_run uuid; v_event uuid; e public.events%rowtype; v_cfg jsonb;
begin
  select r.id, r.cfg, ev.event_id into v_run, v_cfg, v_event
    from sim.runs r join sim.events ev on ev.run_id = r.id where r.slug = p_slug;
  select * into e from public.events where id = v_event;

  return jsonb_build_object(
    'slug', p_slug,
    'config', jsonb_build_object('sessions', e.session_count, 'session_weeks', e.session_weeks,
                                 'draw_rule', e.draw_rule, 'allowance', e.allowance,
                                 'players', jsonb_array_length(v_cfg->'cast')),
    'status', e.status,
    'winner', (select name from public.event_teams where id = e.winner_team_id),
    'shared', (e.status = 'complete' and e.winner_team_id is null),
    'teams', (select jsonb_agg(jsonb_build_object(
                'name', t.name, 'slot', t.slot,
                'points', coalesce((select sum(points) from public.v_event_scoreboard v
                                     where v.event_id = v_event and v.team_id = t.id), 0),
                'players', (select count(*) from public.event_players p where p.team_id = t.id))
                order by t.slot)
              from public.event_teams t where t.event_id = v_event),
    'sessions', (select jsonb_agg(jsonb_build_object(
                   'no', s.session_no, 'status', s.status,
                   'opens_on', s.opens_on, 'closes_on', s.closes_on,
                   'duels', (select count(*) from public.event_duels d where d.session_id = s.id),
                   'results', (select jsonb_object_agg(res, n) from
                                (select d.result res, count(*) n from public.event_duels d
                                  where d.session_id = s.id group by d.result) z))
                   order by s.session_no)
                 from public.event_sessions s where s.event_id = v_event),
    'duels_total', (select count(*) from public.event_duels where event_id = v_event),
    'duels_resolved', (select count(*) from public.event_duels
                        where event_id = v_event and resolved_at is not null),
    'walkovers', (select count(*) from public.event_duels d
                   where d.event_id = v_event
                     and ((d.a_pvi is null) <> (d.b_pvi is null))),
    'halved_empty', (select count(*) from public.event_duels d
                      where d.event_id = v_event and d.result = 'halve'
                        and d.a_pvi is null and d.b_pvi is null),
    'trophies', (select count(*) from public.trophies where event_id = v_event),
    'posts', (select count(*) from public.posts p join public.events ev2 on ev2.id = v_event
               where p.league_id is not distinct from ev2.league_id
                 and p.created_at >= ev2.created_at)
  );
end $fn$;
