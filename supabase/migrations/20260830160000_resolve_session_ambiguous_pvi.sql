-- ============================================================================
-- D144 · resolve_session has never resolved a duel — two stacked ambiguities
--
-- The Ryder's session resolver cannot run. TWO plpgsql/SQL name collisions sit
-- in the same function, and the second is only reachable once the first is
-- cleared, so a static read finds one and an execution finds both.
--
--   1. `update event_duels set ... a_pvi = a_pvi, b_pvi = b_pvi`
--      The right-hand side is meant to be the plpgsql variable; the left-hand
--      side is the column. Postgres raises
--          42702: column reference "a_pvi" is ambiguous
--      The same shape makes the shared-cup tie-break branch unrunnable — it
--      reads `a_pvi is not null` in a subquery over event_duels.
--
--   2. The duel loop declares `d record`, while the session-story and MVP
--      queries further down the SAME function alias event_duels as `d`, so
--      every `d.a_player` there is ambiguous between record and alias:
--          42702: column reference "d.a_player" is ambiguous
--
-- Both have been present since the Ryder shipped (20260713120000) and survived
-- all three rewrites (20260716150000, 20260716160000, 20260727180000), so this
-- path has NEVER worked in production.
--
-- Evidence (2026-08-30): cron `run_event_sessions` FAILED that morning at
-- 07:15 UTC on collision 1, and the only live event ("The Grudge") holds a
-- session that opened 2026-08-23 and cannot close. The six duels that look
-- resolved are seed fixtures — each has a NULL a_round and all six carry the
-- same resolved_at second as the event's own creation, so none came from this
-- function.
--
-- BASE: this is 20260727180000_ryder_session_voice.sql's body — the live
-- definition, verified by md5(prosrc) = 2ff31454ea8a7ca5b83d8cc3b953aaf1 —
-- with THIRTEEN lines changed, every one a rename (a_pvi/b_pvi -> v_apvi/
-- v_bpvi, d -> dl inside the duel loop). The board voice from 20260727160000
-- and 20260727180000 is preserved exactly. The SQL aliases further down are
-- left alone; they become unambiguous once no plpgsql name shadows them.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."resolve_session"("p_session" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_event uuid; v_no int; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  v_ename text;
  dl record; v_apvi numeric; v_bpvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; v_na text; v_nb text; pa numeric; pb numeric; sa numeric; sb numeric;
  v_lines text; v_score text; v_win uuid; v_was text;
  mvp_name text; mvp_rec text;
begin
  select s.event_id, s.session_no, s.opens_on, s.closes_on, e.allowance, e.draw_rule,
         e.defender_team_id, e.name, e.status
    into v_event, v_no, v_open, v_close, v_allow, v_rule, v_def, v_ename, v_was
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  for dl in select * from event_duels where session_id = p_session loop
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into a_rid, v_apvi
      from rounds r join event_players ep on ep.id = dl.a_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;
    select r.id, (r.index_at_post * v_allow / 100.0) - r.differential
      into b_rid, v_bpvi
      from rounds r join event_players ep on ep.id = dl.b_player
     where r.profile_id = ep.profile_id and r.played_on between v_open and v_close
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.index_at_post is not null and r.differential is not null
     order by (r.index_at_post * v_allow / 100.0) - r.differential desc nulls last
     limit 1;

    if v_apvi is null and v_bpvi is null then
      v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    elsif v_bpvi is null then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif v_apvi is null then v_res := 'b'; v_ap := 0; v_bp := 1;
    elsif v_apvi > v_bpvi then v_res := 'a'; v_ap := 1; v_bp := 0;
    elsif v_bpvi > v_apvi then v_res := 'b'; v_ap := 0; v_bp := 1;
    else v_res := 'halve'; v_ap := 0.5; v_bp := 0.5;
    end if;

    update event_duels
       set a_round = a_rid, b_round = b_rid, a_pvi = v_apvi, b_pvi = v_bpvi,
           a_points = v_ap, b_points = v_bp, result = v_res, resolved_at = now()
     where id = dl.id;
  end loop;

  update event_sessions set status = 'closed' where id = p_session;

  select id, name into v_ta, v_na from event_teams where event_id = v_event and slot = 0;
  select id, name into v_tb, v_nb from event_teams where event_id = v_event and slot = 1;
  select coalesce(sum(points),0) into pa from v_event_scoreboard where event_id = v_event and team_id = v_ta;
  select coalesce(sum(points),0) into pb from v_event_scoreboard where event_id = v_event and team_id = v_tb;

  -- the session story: every duel line + the running scoreline
  select string_agg(line, ' · ') into v_lines from (
    select case d.result
        when 'a' then firstname(pa2.display_name) || ' beat ' || firstname(pb2.display_name)
              || coalesce(' by ' || round(abs(d.a_pvi - d.b_pvi), 1), '')
        when 'b' then firstname(pb2.display_name) || ' beat ' || firstname(pa2.display_name)
              || coalesce(' by ' || round(abs(d.b_pvi - d.a_pvi), 1), '')
        else firstname(pa2.display_name) || ' and ' || firstname(pb2.display_name) || ' halved'
      end as line
      from event_duels d
      join event_players ea on ea.id = d.a_player join profiles pa2 on pa2.id = ea.profile_id
      join event_players eb on eb.id = d.b_player join profiles pb2 on pb2.id = eb.profile_id
     where d.session_id = p_session
     order by d.id
  ) x;
  v_score := case when pa = pb then 'All square, ' || evhalf(pa) || '–' || evhalf(pb)
                  when pa > pb then v_na || ' lead ' || evhalf(pa) || '–' || evhalf(pb)
                  else v_nb || ' lead ' || evhalf(pb) || '–' || evhalf(pa) end;
  if v_lines is not null then
    perform event_post(v_event,
      v_score || ' after session ' || v_no || '. ' || v_lines || '.');
  end if;

  -- clinch / completion (draw rule from 20260716150000, unchanged)
  select least(
      (select count(*) from event_players where event_id = v_event and team_id = v_ta),
      (select count(*) from event_players where event_id = v_event and team_id = v_tb))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  if m_total > 0 and greatest(pa, pb) > m_total/2.0 then
    update events set status='complete',
      winner_team_id = case when pa > pb then v_ta else v_tb end
      where id = v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    if pa <> pb then
      update events set status='complete',
        winner_team_id = case when pa > pb then v_ta else v_tb end
        where id = v_event;
    else
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        update events set status='complete', winner_team_id = null where id = v_event;
      else
        select coalesce(sum(case when ep.team_id = v_ta then x.pvi end),0),
               coalesce(sum(case when ep.team_id = v_tb then x.pvi end),0)
          into sa, sb
          from (
            select a_player as player, a_pvi as pvi from event_duels where event_id = v_event and a_pvi is not null
            union all
            select b_player, b_pvi from event_duels where event_id = v_event and b_pvi is not null
          ) x join event_players ep on ep.id = x.player;
        update events set status='complete',
          winner_team_id = case when sa > sb then v_ta when sb > sa then v_tb else null end
          where id = v_event;
      end if;
    end if;
  end if;

  -- completion story: the cup + the MVP (best record, tiebreak total PvI)
  if v_was <> 'complete' and (select status from events where id = v_event) = 'complete' then
    select pr.display_name, s.w || '-' || s.l || '-' || s.h
      into mvp_name, mvp_rec
      from (
        select ep.profile_id,
          count(*) filter (where (d.a_player=ep.id and d.result='a') or (d.b_player=ep.id and d.result='b')) w,
          count(*) filter (where (d.a_player=ep.id and d.result='b') or (d.b_player=ep.id and d.result='a')) l,
          count(*) filter (where d.result='halve') h,
          coalesce(sum(case when d.a_player=ep.id then d.a_pvi when d.b_player=ep.id then d.b_pvi end),0) tot
        from event_players ep
        join event_duels d on d.event_id = ep.event_id
             and (d.a_player = ep.id or d.b_player = ep.id) and d.result <> 'pending'
        where ep.event_id = v_event
        group by ep.id, ep.profile_id
        order by w desc, tot desc limit 1
      ) s join profiles pr on pr.id = s.profile_id;
    select winner_team_id into v_win from events where id = v_event;
    perform event_post(v_event,
      case when v_win is null
              then v_na || ' and ' || v_nb || ' share the ' || v_ename
                   || ', ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            when v_win = v_ta
              then v_na || ' take the ' || v_ename || ' ' || evhalf(pa) || '–' || evhalf(pb) || '.'
            else v_nb || ' take the ' || v_ename || ' ' || evhalf(pb) || '–' || evhalf(pa) || '.' end
      || coalesce(' ' || firstname(mvp_name) || ' is MVP at ' || mvp_rec || '.', ''));
  end if;
end $$;

-- D37: explicit grants (the tick calls it; an organizer may resolve by hand)
revoke all on function public.resolve_session(uuid) from public, anon;
grant execute on function public.resolve_session(uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'resolve_session' and pronamespace = 'public'::regnamespace;
  if position('a_pvi = a_pvi' in v_src) > 0 or position('b_pvi = b_pvi' in v_src) > 0 then
    raise exception 'D144: resolve_session still self-assigns an ambiguous pvi';
  end if;
  if position('v_apvi' in v_src) = 0 or position('for dl in' in v_src) = 0 then
    raise exception 'D144: resolve_session is not the de-shadowed version';
  end if;
  -- the board voice this is built on must still be here
  if position('after session' in v_src) = 0 then
    raise exception 'D144: the 20260727180000 session voice was lost — wrong base';
  end if;
end $chk$;
