-- ============================================================================
-- D398 · A week's result replaces its ask — the Ryder board stops keeping a
-- finished week's "is up" line and stops printing the final score twice.
--
-- Owner ruling in chat, 2026-09-29 (Q44 A), D398 amends D296 (OWNER-QUESTIONS
-- Q44 option A; W7-Q27, A2-events-2, B2-events-6).
-- HELD for the owner's db push.
--
-- What the board said (every server post on an event board is kind 'system',
-- written by event_post, and the room prints them all, newest first):
--   * a finished Ryder still read "Week 3 is up. 4 clashes — find yours." for
--     every week that had long since been decided — an ask nobody can answer;
--   * the last week's result ("Fixture Hawks lead 7–5 after week 3. …") and the
--     cup post ("Fixture Hawks take the Ryder 7–5. …"), written in the same
--     resolve_session call, both printed 7–5;
--   * posts written in one call shared one now(), so a week's lines sorted in
--     no particular order against each other.
--
-- The change, four moves, nothing else:
--   1. event_post stamps created_at = clock_timestamp(), so the posts one call
--      writes sort in the order they were written. Body, kind, target and the
--      400-character cap are unchanged. Engine-only, as before: restated
--      revoke from public, anon, authenticated (service_role keeps it).
--   2. resolve_session: when a week closes, that week's "is up" post is
--      deleted just before its result is posted — the result replaces the
--      ask. Only this event's 'system' posts whose body opens with
--      "Week N is up" (D296's spelling) or "Session N is up" (the same
--      sentence before D296 renamed the noun), N being the closing week.
--   3. resolve_session: the cup post drops the score it repeated. The week's
--      result, posted a moment earlier in the same call, already says it
--      ("… lead 7–5 after week 3." / "All square, 6–6 after week 3."), so:
--        "<A> take the <Ryder> 7–5."                  -> "<A> take the <Ryder>."
--        "<A> and <B> share the <Ryder>, 6–6."        -> "<A> and <B> share the <Ryder>."
--        "Level at 6–6 — <A> take the <Ryder> on total PvI."
--                                                     -> "<A> take the <Ryder> on total PvI."
--      The MVP tail (" <name> is MVP at 3-0-0.") is unchanged. Every other
--      line of resolve_session is the 20261012090000 body, verbatim.
--   4. The stored "is up" rows of finished weeks are removed: one idempotent
--      DELETE, event-board 'system' posts only, only the two spellings in (2),
--      only for a session whose status is 'closed' (the week has its result).
--      An open week's ask, every result, cup, roster and Major post, every
--      chat post and every league post are untouched. A deleted post's
--      comments, kudos and reports go with it (their FKs cascade); a server
--      ask carries none in practice.
--
-- generate_pairings is NOT replaced: the ask's own words are D296's and stay.
-- Idempotent: create or replace + a DELETE that matches nothing on a second
-- run; the self-check at the foot raises rather than report success.
-- ============================================================================

-- ---- 1. event_post · the clock, not the transaction -------------------------
create or replace function public.event_post(p_event uuid, p_body text)
returns void language sql security definer set search_path = public as $$
  insert into posts (event_id, kind, body, created_at)
  values (p_event, 'system', left(p_body, 400), clock_timestamp());
$$;
revoke all on function public.event_post(uuid, text) from public, anon, authenticated;   -- engine-only: the Ryder and Major producers call it; service_role keeps it, as today

-- ---- 2 + 3. resolve_session · the result replaces the ask; the cup says the cup
CREATE OR REPLACE FUNCTION public.resolve_session(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_event uuid; v_no int; v_open date; v_close date; v_allow integer; v_rule text; v_def uuid;
  v_ename text;
  dl record; v_apvi numeric; v_bpvi numeric; a_rid uuid; b_rid uuid;
  v_res text; v_ap numeric; v_bp numeric;
  v_pairs integer; m_total numeric;
  v_ta uuid; v_tb uuid; v_na text; v_nb text; pa numeric; pb numeric; sa numeric; sb numeric;
  v_lines text; v_score text; v_win uuid; v_was text;
  mvp_name text; mvp_rec text; v_rung text; v_the text;
begin
  select s.event_id, s.session_no, s.opens_on, s.closes_on, e.allowance, e.draw_rule,
         e.defender_team_id, e.name, e.status
    into v_event, v_no, v_open, v_close, v_allow, v_rule, v_def, v_ename, v_was
    from event_sessions s join events e on e.id = s.event_id
   where s.id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'Only the organizer can do that.';
  end if;
  -- spec R6: idempotent — a re-run on a closed session is a no-op. Without this
  -- a second call re-reads rounds, re-stamps resolved_at, re-posts the session
  -- story and re-runs the clinch, and can RETRO-FLIP an already-decided duel if
  -- a round was voided or posted late (which R10 forbids). settle_major has had
  -- exactly this guard since 20260727160000; the Ryder never got it, and the
  -- function is granted to authenticated with a client button behind it.
  if (select status from event_sessions where id = p_session) = 'closed' then
    return;
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
  -- D398 (Q44 A) · the week's result replaces the week's ask: a closed week's
  -- "is up" post is not a live ask any more, so it leaves the board here
  delete from posts
   where event_id = v_event and kind = 'system'
     and body ~ ('^(Week|Session) ' || v_no || ' is up[:.] ');
  if v_lines is not null then
    perform event_post(v_event,
      v_score || ' after week ' || v_no || '. ' || v_lines || '.');
  end if;

  -- D146 · a settled event is never re-decided. The tick now keeps resolving a
  -- completed event's remaining sessions so the dead rubbers go on the record
  -- (spec R4), which means this block can run again after the cup is won — and
  -- a late swing must not move the winner_team_id that was already awarded.
  if v_was <> 'complete' then
  -- clinch / completion (draw rule from 20260716150000, unchanged)
  select least(
      (select count(*) from event_players where event_id = v_event and team_id = v_ta),
      (select count(*) from event_players where event_id = v_event and team_id = v_tb))
    into v_pairs;
  m_total := v_pairs * (select session_count from events where id = v_event);

  if m_total > 0 and greatest(pa, pb) > m_total/2.0 then
    v_rung := null;                              -- clinched on the sheet
    update events set status='complete', decided_by = v_rung,
      winner_team_id = case when pa > pb then v_ta else v_tb end
      where id = v_event;
  elsif not exists (select 1 from event_sessions where event_id=v_event and status <> 'closed') then
    if pa <> pb then
      v_rung := null;                            -- points alone decided it
      update events set status='complete', decided_by = v_rung,
        winner_team_id = case when pa > pb then v_ta else v_tb end
        where id = v_event;
    else
      if v_rule = 'defender' and v_def is not null then
        update events set status='complete', winner_team_id = v_def where id = v_event;
      elsif v_rule = 'shared' then
        v_rung := 'shared cup';
        update events set status='complete', decided_by = v_rung,
          winner_team_id = null where id = v_event;
      else
        select coalesce(sum(case when ep.team_id = v_ta then x.pvi end),0),
               coalesce(sum(case when ep.team_id = v_tb then x.pvi end),0)
          into sa, sb
          from (
            select a_player as player, a_pvi as pvi from event_duels where event_id = v_event and a_pvi is not null
            union all
            select b_player, b_pvi from event_duels where event_id = v_event and b_pvi is not null
          ) x join event_players ep on ep.id = x.player;
        v_rung := case when sa = sb then 'shared cup' else 'total PvI' end;
        update events set status='complete', decided_by = v_rung,
          winner_team_id = case when sa > sb then v_ta when sb > sa then v_tb else null end
          where id = v_event;
      end if;
    end if;
  end if;

  end if;   -- /D146 settled-event guard

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
    select winner_team_id, decided_by into v_win, v_rung from events where id = v_event;
    -- an event actually called "The Grudge" produced "take the The Grudge"
    v_the := case when v_ename ~* '^the\s' then '' else 'the ' end;
    -- D398 (Q44 A) · the week's result, posted a moment ago in this call,
    -- already says the score ("… lead 7–5 after week 3." / "All square, 6–6
    -- after week 3."), so the cup post says the cup and never repeats it
    perform event_post(v_event,
      case when v_win is null
              then v_na || ' and ' || v_nb || ' share ' || v_the || v_ename || '.'
            -- D146: a tie broken by the draw rule announced a tie AND a winner
            -- in one breath, with no reason. Say which rung decided it.
            when v_rung is not null
              then (case when v_win = v_ta then v_na else v_nb end)
                   || ' take ' || v_the || v_ename || ' on ' || v_rung || '.'
            when v_win = v_ta
              then v_na || ' take ' || v_the || v_ename || '.'
            else v_nb || ' take ' || v_the || v_ename || '.' end
      || coalesce(' ' || firstname(mvp_name) || ' is MVP at ' || mvp_rec || '.', ''));
  end if;
end $function$;
revoke all on function public.resolve_session(p_session uuid) from public, anon;
grant execute on function public.resolve_session(p_session uuid) to authenticated;

-- ---- 4. the stored asks of finished weeks ------------------------------------
delete from public.posts p
 using public.event_sessions s
 where p.event_id is not null
   and p.kind = 'system'
   and s.event_id = p.event_id
   and s.status = 'closed'
   and p.body ~ ('^(Week|Session) ' || s.session_no || ' is up[:.] ');

-- ---- self-enforcing -----------------------------------------------------------
do $chk$
declare v_src text; n int;
begin
  select prosrc into v_src from pg_proc where oid = 'public.event_post(uuid, text)'::regprocedure;
  if strpos(v_src, 'clock_timestamp()') = 0 then
    raise exception '[D398] event_post does not stamp clock_timestamp()';
  end if;
  select prosrc into v_src from pg_proc where oid = 'public.resolve_session(uuid)'::regprocedure;
  if strpos(v_src, $q$' is up[:.] '$q$) = 0 then
    raise exception '[D398] resolve_session does not replace the week''s ask';
  end if;
  if strpos(v_src, $q$'Level at '$q$) > 0 or strpos(v_src, $q$', ' || evhalf(pa) || '–' || evhalf(pb) || '.'$q$) > 0 then
    raise exception '[D398] the cup post still repeats the score';
  end if;
  if strpos(v_src, $q$' take ' || v_the || v_ename || '.'$q$) = 0 or strpos(v_src, $q$' is MVP at '$q$) = 0 then
    raise exception '[D398] the cup post lost its sentence';
  end if;
  if strpos(v_src, $q$' after week '$q$) = 0 or strpos(v_src, $q$'Only the organizer can do that.'$q$) = 0 then
    raise exception '[D398] resolve_session lost a D296 sentence';
  end if;
  select count(*) into n
    from posts p join event_sessions s on s.event_id = p.event_id
   where p.kind = 'system' and s.status = 'closed'
     and p.body ~ ('^(Week|Session) ' || s.session_no || ' is up[:.] ');
  if n > 0 then
    raise exception '[D398] % stored ask(s) of a finished week survived', n;
  end if;
  if exists (select 1 from pg_proc p, aclexplode(p.proacl) a
              where p.oid = 'public.event_post(uuid, text)'::regprocedure
                and a.privilege_type = 'EXECUTE' and (a.grantee = 0 or a.grantee::regrole::text in ('anon','authenticated'))) then
    raise exception '[D398] event_post is callable from a client role';
  end if;
end $chk$;
