


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."assign_player"("p_squad" "uuid", "p_member" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record;
begin
  select s.* into se from seasons s
  join squads q on q.season_id = s.id where q.id = p_squad;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  -- moving a player: clear any prior seat this season, then seat them
  delete from squad_members sm using squads q
  where q.id = sm.squad_id and q.season_id = se.id and sm.member_id = p_member;
  insert into squad_members (squad_id, member_id) values (p_squad, p_member);

  insert into commissioner_log (league_id, action, detail)
  values (se.league_id, 'assign_player',
          jsonb_build_object('squad', p_squad, 'member', p_member));
end $$;


ALTER FUNCTION "public"."assign_player"("p_squad" "uuid", "p_member" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare st record; se record; m record; short numeric; delta int;
        winner uuid; best int;
        is_partial boolean;
        month_last date;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  -- CHANGE 2c · idempotence now keys on a month_closed sentinel, so a month
  -- with zero penalties and no hybrid bonus still closes exactly once.
  if exists (select 1 from season_adjustments
             where season_id = p_season and month = p_month
               and kind = 'month_closed' and created_by is null) then
    return;
  end if;

  -- CHANGE 2a · blanket partial-month detection (spec §14.0):
  -- a month is partial if the season starts after its 1st, or ends before
  -- its last day. Floors are WAIVED for everyone in partial edge months —
  -- the same grace late joiners get.
  month_last := (p_month + interval '1 month' - interval '1 day')::date;
  is_partial := (se.starts_on > p_month) or (se.ends_on < month_last);

  -- 1 · floor penalties — deduct AND forfeit (CHANGE 2b), skipped when waived
  if st.participation_floor > 0
     and st.floor_penalty in ('deduct','forfeit')
     and not is_partial then
    for m in
      select sm.squad_id, sm.member_id,
             coalesce(sum(rr.floor_credit),0) as credits,
             coalesce(sum(rr.points)
               filter (where rr.month_rank <= coalesce(st.counting_cap,999)),0)
               as counting_pts
      from squad_members sm
      join squads s on s.id = sm.squad_id and s.season_id = p_season
      left join v_rounds_ranked rr
        on rr.member_id = sm.member_id
       and rr.season_id = p_season
       and date_trunc('month', rr.played_on) = p_month
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
      group by sm.squad_id, sm.member_id
    loop
      short := greatest(0, st.participation_floor - m.credits);
      if short > 0 then
        if st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits);
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  'FLOOR MISSED — '||abs(delta)||' PTS OFF THE BOARD');
        else  -- forfeit: negate the month's counting points (§3.2 Cutthroat)
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited');
            insert into posts (league_id, season_id, kind, body)
            values (se.league_id, p_season, 'system',
                    'MONTH FORFEITED — '||m.counting_pts||' PTS STRUCK');
          end if;
        end if;
      end if;
    end loop;
  end if;

  -- 2 · hybrid matchup bonus (unchanged from m003)
  -- NOTE: still awarded in partial edge months — §14.0 only waives floors.
  -- Flagged as a spec question; revisit in v1.1 / migration 007 if desired.
  if st.season_format = 'hybrid' then
    select s.id into winner
    from squads s
    left join squad_members sm on sm.squad_id = s.id
    left join v_rounds_ranked rr
      on rr.member_id = sm.member_id and rr.season_id = p_season
     and date_trunc('month', rr.played_on) = p_month
     and rr.month_rank <= coalesce(st.counting_cap, 999)
    where s.season_id = p_season
    group by s.id
    order by coalesce(sum(rr.points),0) desc
    limit 1;
    if winner is not null then
      insert into season_adjustments
        (season_id, squad_id, month, kind, points, reason)
      values (p_season, winner, p_month, 'matchup_bonus', 15,
              'Monthly head-to-head winner');
      insert into posts (league_id, season_id, kind, body)
      select se.league_id, p_season, 'system',
             upper(name)||' TAKE THE MONTHLY +15'
      from squads where id = winner;
    end if;
  end if;

  -- 3 · CHANGE 2c · sentinel + the §14.2 "month closed" board event
  insert into season_adjustments
    (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial edge month — floors waived'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          upper(to_char(p_month,'FMMonth'))||' CLOSED — LEDGER POSTED'
          || case when is_partial then ' · PARTIAL MONTH, FLOORS WAIVED' else '' end);
end $$;


ALTER FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."close_season"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; champ uuid; king uuid;
begin
  select * into se from seasons where id = p_season;

  select squad_id into champ from v_squad_standings
    where season_id = p_season order by points desc limit 1;
  select member_id into king from v_individual_standings
    where season_id = p_season order by points desc nulls last limit 1;

  update seasons set status = 'complete',
    champion_squad_id = champ, points_king_member_id = king
    where id = p_season;
  update leagues set phase = 'complete' where id = se.league_id;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'SEASON COMPLETE — THE CUP HAS A HOME. TROPHY ROOM IS OPEN.');
end $$;


ALTER FUNCTION "public"."close_season"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_league"("p_name" "text", "p_code" "text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare v_league leagues; v_member league_members;
begin
  begin
    insert into profiles (id) values (auth.uid()) on conflict do nothing;
  exception when others then null;  -- profile may exist or have required cols; FK is what matters
  end;

  insert into leagues (name, code, commissioner_id, phase)
  values (p_name, p_code, auth.uid(), 'setup')
  returning * into v_league;

  insert into league_members (league_id, profile_id, role)
  values (v_league.id, auth.uid(), 'commissioner')
  returning * into v_member;

  insert into league_settings (league_id) values (v_league.id);

  return json_build_object('league', row_to_json(v_league),
                           'member', row_to_json(v_member));
end $$;


ALTER FUNCTION "public"."create_league"("p_name" "text", "p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cup_points"("p_pvi" numeric) RETURNS integer
    LANGUAGE "sql" IMMUTABLE
    AS $$
  select case
    when p_pvi >= 3  then 12
    when p_pvi >= 1  then 9
    when p_pvi > -1  then 7
    when p_pvi >= -3 then 6
    else 5
  end;
$$;


ALTER FUNCTION "public"."cup_points"("p_pvi" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."daily_season_tick"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- open the Cup Final window at ends_on − 27 (a Sunday, seasons end Saturday)
    if se.status = 'active' and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    -- grace-aware season close: final day + 48h (seasons.grace_hours), local tz
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;
  end loop;
end $$;


ALTER FUNCTION "public"."daily_season_tick"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."enter_cup_final"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; st record; n integer := 0; r record;
begin
  select * into se from seasons where id = p_season;
  if se.status <> 'active' then return; end if;                 -- idempotent
  if current_date < se.ends_on - 27 then return; end if;        -- window not open

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  if st.structure = 'solo' then
    for r in select member_id from v_individual_standings
             where season_id = p_season
             order by points desc nulls last limit 2
    loop
      n := n + 1;
      insert into cup_finalists (season_id, member_id, seed)
      values (p_season, r.member_id, n);
    end loop;
  else
    for r in select squad_id from v_squad_standings
             where season_id = p_season
             order by points desc limit 2
    loop
      n := n + 1;
      insert into cup_finalists (season_id, squad_id, seed, head_start)
      values (p_season, r.squad_id, n,
              case when st.structure = 'squads2' and n = 1 then 10 else 0 end);
    end loop;
  end if;

  update seasons set status = 'cup_final' where id = p_season;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'THE CUP FINAL IS LIVE — FRESH SLATE, FOUR WEEKS. SEEDS ARE LOCKED.');
end $$;


ALTER FUNCTION "public"."enter_cup_final"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."finish_live_round"("p_live_round" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare lr record; pl record; v_gross int; v_round uuid;
        v_settings record; v_member record; v_names text[];
begin
  select * into lr from live_rounds where id = p_live_round and status = 'live';
  if not found then raise exception 'live round not found or not live'; end if;

  select ls.* into v_settings
    from league_settings ls where ls.league_id = lr.league_id;

  select array_agg(coalesce(p.display_name, lp.guest_name)) into v_names
    from live_round_players lp
    left join league_members m on m.id = lp.member_id
    left join profiles p on p.id = m.profile_id
    where lp.live_round_id = p_live_round;

  for pl in select * from live_round_players where live_round_id = p_live_round loop
    if pl.member_id is null then continue; end if;   -- guests never post

    select coalesce(sum(strokes),0) into v_gross
      from live_scores where player_id = pl.id;
    if v_gross = 0 then continue; end if;

    select * into v_member from league_members where id = pl.member_id;

    insert into rounds (season_id, member_id, live_round_id, course_id, tee_id,
                        course_label, holes_played, gross, rating, slope,
                        index_at_post, allowance_at_post, source, attested)
    values (lr.season_id, pl.member_id, lr.id, lr.course_id, lr.tee_id,
            lr.course_label, 18, v_gross,
            (lr.course_snapshot->>'rating')::numeric,
            (lr.course_snapshot->>'slope')::int,
            v_member.index_current, v_settings.handicap_allowance,
            'live', true)
    returning id into v_round;

    insert into round_holes (round_id, hole_number, strokes)
      select v_round, hole_number, strokes
      from live_scores where player_id = pl.id;

    insert into attestations (round_id, attested_by, is_member)
      select v_round, unnest(v_names), true
      on conflict do nothing;
  end loop;

  update live_rounds set status = 'final', finished_at = now()
    where id = p_live_round;
end $$;


ALTER FUNCTION "public"."finish_live_round"("p_live_round" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."form_squads"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; st record; n int; i int;
        names text[] := array['Squad 1','Squad 2','Squad 3','Squad 4'];
        colors text[] := array['#57A8FF','#FB8B4B','#A78BFA','#2FD3BE'];
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;
  if st.structure = 'solo' then return; end if;
  if exists (select 1 from squads where season_id = p_season) then return; end if;

  n := case st.structure when 'squads2' then 2 when 'squads3' then 3 else 4 end;
  for i in 1..n loop
    insert into squads (season_id, name, color) values (p_season, names[i], colors[i]);
  end loop;
end $$;


ALTER FUNCTION "public"."form_squads"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into profiles (id, display_name, email)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)),
          new.email);
  return new;
end $$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_commissioner"("p_league" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ select exists (select 1 from league_members
                  where league_id = p_league and profile_id = auth.uid()
                    and role = 'commissioner'); $$;


ALTER FUNCTION "public"."is_commissioner"("p_league" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_league_member"("p_league" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ select exists (select 1 from league_members
                  where league_id = p_league and profile_id = auth.uid()); $$;


ALTER FUNCTION "public"."is_league_member"("p_league" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."join_league"("p_code" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare v_league uuid;
begin
  select id into v_league from leagues where upper(code) = upper(p_code);
  if not found then raise exception 'invalid league code'; end if;
  insert into league_members (league_id, profile_id)
  values (v_league, auth.uid())
  on conflict (league_id, profile_id) do nothing;
  return v_league;
end $$;


ALTER FUNCTION "public"."join_league"("p_code" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare d record; se record; n_sq int; rd int; idx int;
        squad uuid; me uuid; is_c boolean; cap uuid;
begin
  select * into d from drafts where id = p_draft for update;
  if d.status <> 'live' then raise exception 'draft is not live'; end if;
  select * into se from seasons where id = d.season_id;

  me   := my_member_id(se.league_id);
  is_c := is_commissioner(se.league_id);
  if me is null then raise exception 'not a league member'; end if;

  n_sq := array_length(d.order_squads, 1);
  rd   := (d.current_pick / n_sq) + 1;                      -- 1-indexed round
  idx  := d.current_pick % n_sq;
  -- snake: even rounds reverse
  if rd % 2 = 0 then idx := n_sq - 1 - idx; end if;
  squad := d.order_squads[idx + 1];

  select captain_member_id into cap from squads where id = squad;
  if not is_c and cap is distinct from me then
    raise exception 'not your pick';
  end if;

  if d.current_pick >= n_sq * d.rounds_count then
    raise exception 'draft is full';
  end if;

  insert into draft_picks
    (draft_id, pick_number, round_number, squad_id, member_id, picked_by, via_override)
  values (p_draft, d.current_pick, rd, squad, p_member, me, is_c and cap is distinct from me);

  insert into squad_members (squad_id, member_id, drafted_round, pick_number)
  values (squad, p_member, rd, d.current_pick);

  update drafts set current_pick = current_pick + 1 where id = p_draft;

  insert into posts (league_id, season_id, kind, body)
  select se.league_id, d.season_id, 'system',
         upper(s.name) || ' DRAFTS ' || upper(p.display_name) ||
         ' · R' || rd || 'P' || (idx + 1)
  from squads s, league_members lm join profiles p on p.id = lm.profile_id
  where s.id = squad and lm.id = p_member;

  if is_c and cap is distinct from me then
    insert into commissioner_log (league_id, actor_id, action, detail)
    values (se.league_id, me, 'draft_pick_override',
            jsonb_build_object('squad', squad, 'member', p_member));
  end if;

  -- last pick closes the draft and opens the season
  if (select current_pick from drafts where id = p_draft) >= n_sq * d.rounds_count then
    update drafts  set status = 'complete', completed_at = now() where id = p_draft;
    update leagues set phase = 'season' where id = se.league_id;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, d.season_id, 'system', 'ROSTERS LOCKED — THE SEASON IS LIVE');
  end if;
end $$;


ALTER FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."my_member_id"("p_league" "uuid") RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$ select id from league_members
   where league_id = p_league and profile_id = auth.uid(); $$;


ALTER FUNCTION "public"."my_member_id"("p_league" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."randomize_squads"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; sq uuid[]; m record; i int := 0; reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  select array_agg(id order by name) into sq from squads where season_id = p_season;
  if sq is null then raise exception 'no squads — run form_squads first'; end if;

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    insert into squad_members (squad_id, member_id)
    values (sq[(i % array_length(sq,1)) + 1], m.id);
    i := i + 1;
  end loop;

  -- default captains: first member of each captainless squad
  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(upper(q.name)||' — '||cnt||' JOES', ' · ') into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'SQUADS DRAWN — THE HAT HAS SPOKEN. '||coalesce(reveal,''));
end $$;


ALTER FUNCTION "public"."randomize_squads"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."round_to_board"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into posts (league_id, season_id, kind, body)
  select lm.league_id, s.id, 'round',
         upper(coalesce(p.display_name, 'A MEMBER'))
         || ' POSTED ' || new.gross || ' GROSS'
         || case when new.holes_played = 9 then ' · 9 HOLES' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' · ' || upper(new.course_label) else '' end
         || ' · DIFF ' || new.differential
  from league_members lm
  join profiles p on p.id = new.profile_id
  join seasons s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;
  return new;
end $$;


ALTER FUNCTION "public"."round_to_board"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rounds_compute"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare s record;
begin
  select * into s from score_round(
    new.gross, new.rating, new.slope, new.nine_rating,
    new.index_at_post, new.allowance_at_post, new.holes_played);
  new.differential := s.o_diff;
  new.pvi          := s.o_pvi;
  new.points       := s.o_points;
  return new;
end $$;


ALTER FUNCTION "public"."rounds_compute"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."run_month_closes"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- close the month that just ended (job runs on the 1st, local ~00:10)
    perform close_month(se.id,
      (date_trunc('month', current_date) - interval '1 month')::date);
  end loop;
end $$;


ALTER FUNCTION "public"."run_month_closes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."run_week_snapshots"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    perform snapshot_week(se.id);
  end loop;
end $$;


ALTER FUNCTION "public"."run_week_snapshots"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."score_round"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- snapshot the index this round was posted under (§16 receipts)
  if new.index_at_post is null then
    select index_current into new.index_at_post
    from profiles where id = new.profile_id;
  end if;
  new.index_at_post := coalesce(new.index_at_post, 18);

  -- differential: (adjusted gross − rating) × 113 ÷ slope (§2.1)
  -- 9-hole: score vs nine_rating, ×2 to an 18-hole-equivalent differential
  if new.holes_played = 9 and new.nine_rating is not null then
    new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;
  return new;
end $$;


ALTER FUNCTION "public"."score_round"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."score_round"("p_gross" integer, "p_rating" numeric, "p_slope" integer, "p_nine_rating" numeric, "p_index" numeric, "p_allowance" integer, "p_holes" integer) RETURNS TABLE("o_diff" numeric, "o_pvi" numeric, "o_points" integer)
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
declare v_diff numeric; v_pvi numeric; v_pts int;
begin
  if p_holes = 9 then
    v_diff := ((p_gross - coalesce(p_nine_rating, p_rating/2)) * 113.0 / p_slope) * 2;
  else
    v_diff := (p_gross - p_rating) * 113.0 / p_slope;
  end if;
  v_pvi := (p_index * p_allowance / 100.0) - v_diff;
  v_pts := case
    when v_pvi >= 3  then 12
    when v_pvi >= 1  then 9
    when v_pvi >= -1 then 7
    when v_pvi >= -3 then 6
    else 5 end;
  if p_holes = 9 then v_pts := ceil(v_pts / 2.0); end if;
  return query select round(v_diff,1), round(v_pvi,1), v_pts;
end $$;


ALTER FUNCTION "public"."score_round"("p_gross" integer, "p_rating" numeric, "p_slope" integer, "p_nine_rating" numeric, "p_index" numeric, "p_allowance" integer, "p_holes" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_profile"("p_name" "text", "p_city" "text" DEFAULT NULL::"text", "p_home" "text" DEFAULT NULL::"text", "p_index" numeric DEFAULT NULL::numeric, "p_marker" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into profiles (id, email, display_name, city, home_course, index_current, marker)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker)
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker);
end $$;


ALTER FUNCTION "public"."set_profile"("p_name" "text", "p_city" "text", "p_home" "text", "p_index" numeric, "p_marker" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."snapshot_week"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; wk integer; total_wk integer; payload jsonb;
begin
  select * into se from seasons where id = p_season;
  if se.status not in ('active','cup_final') then return; end if;
  if current_date <= se.starts_on then return; end if;

  total_wk := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  wk := least(total_wk, floor((current_date - se.starts_on) / 7.0));
  if wk < 1 then return; end if;

  payload := jsonb_build_object(
    'squads', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_squad_standings
              where season_id = p_season order by points desc) t), '[]'::jsonb),
    'individuals', coalesce((
        select jsonb_agg(to_jsonb(t))
        from (select * from v_individual_standings
              where season_id = p_season order by points desc nulls last) t), '[]'::jsonb)
  );

  insert into standings_snapshots (season_id, week_no, standings)
  values (p_season, wk, payload)
  on conflict (season_id, week_no) do nothing;
end $$;


ALTER FUNCTION "public"."snapshot_week"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_draft"("p_season" "uuid", "p_shuffle" boolean DEFAULT true) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; sq uuid[]; d uuid;
begin
  select * into se from seasons where id = p_season;
  if not is_commissioner(se.league_id) then
    raise exception 'only the commissioner starts the draft';
  end if;

  select array_agg(id order by case when p_shuffle then random() else 0 end)
    into sq from squads where season_id = p_season;
  if array_length(sq,1) is null then raise exception 'no squads'; end if;

  insert into drafts (season_id, type, status, order_squads, started_at)
  select p_season, ls.draft_type, 'live', sq, now()
  from league_settings ls where ls.league_id = se.league_id
  on conflict (season_id) do update
    set order_squads = excluded.order_squads, status = 'live', started_at = now()
  returning id into d;

  insert into posts (league_id, season_id, kind, body)
  select se.league_id, p_season, 'system',
    'DRAFT ORDER SET — ' || string_agg(upper(s.name), ' · ' order by array_position(sq, s.id))
  from squads s where s.id = any(sq);

  return d;
end $$;


ALTER FUNCTION "public"."start_draft"("p_season" "uuid", "p_shuffle" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_season"("p_season" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare se record; st record; loose int;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  if st.structure <> 'solo' then
    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% member(s) unassigned — every Joe needs a squad', loose;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'ROSTERS LOCKED — THE SEASON IS LIVE. POST A ROUND.');
end $$;


ALTER FUNCTION "public"."start_season"("p_season" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."undo_pick"("p_draft" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare d record; se record; last record;
begin
  select * into d from drafts where id = p_draft for update;
  select * into se from seasons where id = d.season_id;
  if not is_commissioner(se.league_id) then
    raise exception 'only the commissioner can undo a pick';
  end if;

  select * into last from draft_picks
    where draft_id = p_draft order by pick_number desc limit 1;
  if not found then return; end if;

  delete from squad_members
    where squad_id = last.squad_id and member_id = last.member_id;
  delete from draft_picks where id = last.id;
  update drafts set current_pick = last.pick_number, status = 'live',
                    completed_at = null where id = p_draft;
  update leagues set phase = 'draft' where id = se.league_id;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (se.league_id, my_member_id(se.league_id), 'draft_pick_undo',
          jsonb_build_object('pick', last.pick_number, 'member', last.member_id));
end $$;


ALTER FUNCTION "public"."undo_pick"("p_draft" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."attestations" (
    "round_id" "uuid" NOT NULL,
    "attested_by" "text" NOT NULL,
    "is_member" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."attestations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."buy_ins" (
    "season_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "amount_cents" integer NOT NULL,
    "paid" boolean DEFAULT false NOT NULL,
    "marked_by" "uuid",
    "marked_at" timestamp with time zone
);


ALTER TABLE "public"."buy_ins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commissioner_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "actor_id" "uuid" NOT NULL,
    "action" "text" NOT NULL,
    "detail" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."commissioner_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."course_holes" (
    "tee_id" "uuid" NOT NULL,
    "hole_number" integer NOT NULL,
    "par" integer NOT NULL,
    "yardage" integer,
    "stroke_index" integer,
    CONSTRAINT "course_holes_hole_number_check" CHECK ((("hole_number" >= 1) AND ("hole_number" <= 18))),
    CONSTRAINT "course_holes_par_check" CHECK ((("par" >= 3) AND ("par" <= 6))),
    CONSTRAINT "course_holes_stroke_index_check" CHECK ((("stroke_index" >= 1) AND ("stroke_index" <= 18)))
);


ALTER TABLE "public"."course_holes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."course_tees" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "course_id" "uuid" NOT NULL,
    "tee_name" "text" NOT NULL,
    "gender" "text",
    "course_rating" numeric(4,1) NOT NULL,
    "slope_rating" integer NOT NULL,
    "front_rating" numeric(4,1),
    "front_slope" integer,
    "back_rating" numeric(4,1),
    "back_slope" integer,
    "par_total" integer,
    "total_yards" integer,
    "holes_count" integer DEFAULT 18 NOT NULL,
    CONSTRAINT "course_tees_gender_check" CHECK (("gender" = ANY (ARRAY['male'::"text", 'female'::"text"]))),
    CONSTRAINT "course_tees_holes_count_check" CHECK (("holes_count" = ANY (ARRAY[9, 18])))
);


ALTER TABLE "public"."course_tees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."courses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "external_id" integer,
    "club_name" "text" NOT NULL,
    "course_name" "text",
    "city" "text",
    "state" "text",
    "country" "text",
    "lat" double precision,
    "lng" double precision,
    "source" "text" DEFAULT 'manual'::"text" NOT NULL,
    "verified" boolean DEFAULT false NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "courses_source_check" CHECK (("source" = ANY (ARRAY['api'::"text", 'manual'::"text"])))
);


ALTER TABLE "public"."courses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cup_finalists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid" NOT NULL,
    "squad_id" "uuid",
    "member_id" "uuid",
    "seed" integer NOT NULL,
    "head_start" integer DEFAULT 0 NOT NULL,
    "locked_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cup_finalists_check" CHECK ((("squad_id" IS NOT NULL) OR ("member_id" IS NOT NULL)))
);


ALTER TABLE "public"."cup_finalists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."draft_picks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "pick_number" integer NOT NULL,
    "round_number" integer NOT NULL,
    "squad_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "picked_by" "uuid" NOT NULL,
    "via_override" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."draft_picks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."drafts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid" NOT NULL,
    "type" "text" DEFAULT 'snake'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "rounds_count" integer DEFAULT 3 NOT NULL,
    "pick_seconds" integer,
    "order_squads" "uuid"[] DEFAULT '{}'::"uuid"[] NOT NULL,
    "current_pick" integer DEFAULT 0 NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    CONSTRAINT "drafts_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'live'::"text", 'complete'::"text"]))),
    CONSTRAINT "drafts_type_check" CHECK (("type" = ANY (ARRAY['snake'::"text", 'assign'::"text", 'live'::"text"])))
);


ALTER TABLE "public"."drafts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid",
    "member_id" "uuid",
    "body" "text" NOT NULL,
    "screen" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."game_results" (
    "live_round_id" "uuid" NOT NULL,
    "player_id" "uuid" NOT NULL,
    "points" integer DEFAULT 0 NOT NULL,
    "amount_cents" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."game_results" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "token" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "status" "text" DEFAULT 'sent'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "invites_status_check" CHECK (("status" = ANY (ARRAY['sent'::"text", 'accepted'::"text"])))
);


ALTER TABLE "public"."invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."league_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'player'::"text" NOT NULL,
    "index_current" numeric(4,1) DEFAULT 18.0 NOT NULL,
    "index_source" "text" DEFAULT 'self'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "league_members_index_source_check" CHECK (("index_source" = ANY (ARRAY['self'::"text", 'app'::"text", 'ghin'::"text"]))),
    CONSTRAINT "league_members_role_check" CHECK (("role" = ANY (ARRAY['commissioner'::"text", 'captain'::"text", 'player'::"text"])))
);


ALTER TABLE "public"."league_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."league_settings" (
    "league_id" "uuid" NOT NULL,
    "preset" "text" DEFAULT 'standard'::"text" NOT NULL,
    "handicap_allowance" integer DEFAULT 95 NOT NULL,
    "verification" "text" DEFAULT 'attested'::"text" NOT NULL,
    "counting_cap" integer,
    "participation_floor" integer DEFAULT 2 NOT NULL,
    "floor_penalty" "text" DEFAULT 'deduct'::"text" NOT NULL,
    "season_format" "text" DEFAULT 'hybrid'::"text" NOT NULL,
    "buyin_cents" integer DEFAULT 7500 NOT NULL,
    "season_months" integer DEFAULT 9 NOT NULL,
    "sim_rounds_allowed" boolean DEFAULT true NOT NULL,
    "nine_hole_allowed" boolean DEFAULT true NOT NULL,
    "locked_at" timestamp with time zone,
    "structure" "text" DEFAULT 'squads4'::"text" NOT NULL,
    "draft_type" "text" DEFAULT 'random'::"text" NOT NULL,
    "payout_champ" integer DEFAULT 60 NOT NULL,
    "payout_runnerup" integer DEFAULT 25 NOT NULL,
    "payout_king" integer DEFAULT 15 NOT NULL,
    CONSTRAINT "draft_type_valid" CHECK (("draft_type" = ANY (ARRAY['random'::"text", 'assign'::"text", 'snake'::"text", 'live'::"text"]))),
    CONSTRAINT "league_settings_floor_penalty_check" CHECK (("floor_penalty" = ANY (ARRAY['none'::"text", 'deduct'::"text", 'forfeit'::"text"]))),
    CONSTRAINT "league_settings_handicap_allowance_check" CHECK (("handicap_allowance" = ANY (ARRAY[90, 95, 100]))),
    CONSTRAINT "league_settings_participation_floor_check" CHECK ((("participation_floor" >= 0) AND ("participation_floor" <= 4))),
    CONSTRAINT "league_settings_preset_check" CHECK (("preset" = ANY (ARRAY['casual'::"text", 'standard'::"text", 'cutthroat'::"text", 'custom'::"text"]))),
    CONSTRAINT "league_settings_season_format_check" CHECK (("season_format" = ANY (ARRAY['points'::"text", 'h2h'::"text", 'hybrid'::"text"]))),
    CONSTRAINT "league_settings_season_months_check" CHECK ((("season_months" >= 3) AND ("season_months" <= 12))),
    CONSTRAINT "league_settings_structure_check" CHECK (("structure" = ANY (ARRAY['solo'::"text", 'squads2'::"text", 'squads3'::"text", 'squads4'::"text"]))),
    CONSTRAINT "league_settings_verification_check" CHECK (("verification" = ANY (ARRAY['honor'::"text", 'attested'::"text", 'ghin'::"text"]))),
    CONSTRAINT "payout_sums_100" CHECK (((("payout_champ" + "payout_runnerup") + "payout_king") = 100))
);


ALTER TABLE "public"."league_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."leagues" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "code" "text" NOT NULL,
    "phase" "text" DEFAULT 'setup'::"text" NOT NULL,
    "commissioner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "leagues_phase_check" CHECK (("phase" = ANY (ARRAY['setup'::"text", 'draft'::"text", 'season'::"text", 'complete'::"text"])))
);


ALTER TABLE "public"."leagues" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."live_round_players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "live_round_id" "uuid" NOT NULL,
    "member_id" "uuid",
    "guest_name" "text",
    "guest_index" numeric(4,1),
    "index_source" "text" DEFAULT 'member'::"text" NOT NULL,
    "position" integer NOT NULL,
    "claim_token" "uuid" DEFAULT "gen_random_uuid"(),
    CONSTRAINT "live_round_players_check" CHECK ((("member_id" IS NOT NULL) OR ("guest_name" IS NOT NULL))),
    CONSTRAINT "live_round_players_index_source_check" CHECK (("index_source" = ANY (ARRAY['member'::"text", 'self'::"text", 'estimated'::"text"]))),
    CONSTRAINT "live_round_players_position_check" CHECK ((("position" >= 0) AND ("position" <= 3)))
);


ALTER TABLE "public"."live_round_players" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."live_rounds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "season_id" "uuid" NOT NULL,
    "course_id" "uuid",
    "tee_id" "uuid",
    "course_label" "text" NOT NULL,
    "course_snapshot" "jsonb" NOT NULL,
    "game" "text" DEFAULT 'match'::"text" NOT NULL,
    "game_config" "jsonb" DEFAULT '{"lone_multiplier": 3, "wolf_value_cents": 200}'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'setup'::"text" NOT NULL,
    "started_by" "uuid" NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "finished_at" timestamp with time zone,
    CONSTRAINT "live_rounds_game_check" CHECK (("game" = ANY (ARRAY['none'::"text", 'match'::"text", 'wolf'::"text"]))),
    CONSTRAINT "live_rounds_status_check" CHECK (("status" = ANY (ARRAY['setup'::"text", 'live'::"text", 'final'::"text"])))
);


ALTER TABLE "public"."live_rounds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."live_scores" (
    "live_round_id" "uuid" NOT NULL,
    "player_id" "uuid" NOT NULL,
    "hole_number" integer NOT NULL,
    "strokes" integer NOT NULL,
    CONSTRAINT "live_scores_hole_number_check" CHECK ((("hole_number" >= 1) AND ("hole_number" <= 18))),
    CONSTRAINT "live_scores_strokes_check" CHECK ((("strokes" >= 1) AND ("strokes" <= 15)))
);


ALTER TABLE "public"."live_scores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "body" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."post_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_kudos" (
    "post_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL
);


ALTER TABLE "public"."post_kudos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "season_id" "uuid",
    "kind" "text" NOT NULL,
    "member_id" "uuid",
    "round_id" "uuid",
    "body" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "posts_kind_check" CHECK (("kind" = ANY (ARRAY['chat'::"text", 'round'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "ghin_number" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "city" "text",
    "home_course" "text",
    "index_current" numeric,
    "marker" "text",
    "card_quote" "text",
    "the_miss" "text",
    "walk_ride" "text",
    "beverage" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."round_holes" (
    "round_id" "uuid" NOT NULL,
    "hole_number" integer NOT NULL,
    "strokes" integer NOT NULL,
    CONSTRAINT "round_holes_hole_number_check" CHECK ((("hole_number" >= 1) AND ("hole_number" <= 18))),
    CONSTRAINT "round_holes_strokes_check" CHECK ((("strokes" >= 1) AND ("strokes" <= 15)))
);


ALTER TABLE "public"."round_holes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rounds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid",
    "live_round_id" "uuid",
    "course_id" "uuid",
    "tee_id" "uuid",
    "course_label" "text" NOT NULL,
    "played_on" "date" DEFAULT CURRENT_DATE NOT NULL,
    "holes_played" integer DEFAULT 18 NOT NULL,
    "gross" integer NOT NULL,
    "rating" numeric(4,1) NOT NULL,
    "slope" integer NOT NULL,
    "nine_rating" numeric(4,1),
    "index_at_post" numeric(4,1) NOT NULL,
    "differential" numeric(5,1),
    "source" "text" DEFAULT 'quick'::"text" NOT NULL,
    "attested" boolean DEFAULT false NOT NULL,
    "voided" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "index_source_at_post" "text" DEFAULT 'self'::"text" NOT NULL,
    "profile_id" "uuid",
    CONSTRAINT "rounds_gross_check" CHECK ((("gross" >= 18) AND ("gross" <= 200))),
    CONSTRAINT "rounds_holes_played_check" CHECK (("holes_played" = ANY (ARRAY[9, 18]))),
    CONSTRAINT "rounds_index_source_at_post_check" CHECK (("index_source_at_post" = ANY (ARRAY['self'::"text", 'app'::"text", 'ghin'::"text"]))),
    CONSTRAINT "rounds_source_check" CHECK (("source" = ANY (ARRAY['quick'::"text", 'live'::"text"])))
);


ALTER TABLE "public"."rounds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."season_adjustments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid" NOT NULL,
    "squad_id" "uuid",
    "member_id" "uuid",
    "month" "date" NOT NULL,
    "kind" "text" NOT NULL,
    "points" integer DEFAULT 0 NOT NULL,
    "reason" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "season_adjustments_kind_check" CHECK (("kind" = ANY (ARRAY['floor_penalty'::"text", 'matchup_bonus'::"text", 'bye'::"text", 'override'::"text"])))
);


ALTER TABLE "public"."season_adjustments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."seasons" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "league_id" "uuid" NOT NULL,
    "number" integer DEFAULT 1 NOT NULL,
    "starts_on" "date" NOT NULL,
    "ends_on" "date" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "timezone" "text" DEFAULT 'America/Phoenix'::"text" NOT NULL,
    "grace_hours" integer DEFAULT 48 NOT NULL,
    "champion_squad_id" "uuid",
    "points_king_member_id" "uuid",
    CONSTRAINT "seasons_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cup_final'::"text", 'complete'::"text"])))
);


ALTER TABLE "public"."seasons" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."squad_members" (
    "squad_id" "uuid" NOT NULL,
    "member_id" "uuid" NOT NULL,
    "drafted_round" integer,
    "pick_number" integer
);


ALTER TABLE "public"."squad_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."squads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "color" integer DEFAULT 0 NOT NULL,
    "captain_member_id" "uuid",
    CONSTRAINT "squads_color_check" CHECK ((("color" >= 0) AND ("color" <= 3)))
);


ALTER TABLE "public"."squads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."standings_snapshots" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "season_id" "uuid" NOT NULL,
    "week_no" integer NOT NULL,
    "captured_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "standings" "jsonb" NOT NULL
);


ALTER TABLE "public"."standings_snapshots" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_rounds_ranked" WITH ("security_invoker"='true') AS
 WITH "scored" AS (
         SELECT "lm"."id" AS "member_id",
            "s"."id" AS "season_id",
            "r"."id" AS "round_id",
            "r"."profile_id",
            "r"."played_on",
            "r"."holes_played",
            "r"."source",
            "r"."attested",
            "r"."differential",
            "r"."index_at_post",
            "round"((("r"."index_at_post" * ("ls"."handicap_allowance")::numeric) / 100.0), 1) AS "playing_index",
            "round"(((("r"."index_at_post" * ("ls"."handicap_allowance")::numeric) / 100.0) - "r"."differential"), 1) AS "pvi",
                CASE
                    WHEN ("r"."holes_played" = 9) THEN ("ceil"((("public"."cup_points"("round"(((("r"."index_at_post" * ("ls"."handicap_allowance")::numeric) / 100.0) - "r"."differential"), 1)))::numeric / (2)::numeric)))::integer
                    ELSE "public"."cup_points"("round"(((("r"."index_at_post" * ("ls"."handicap_allowance")::numeric) / 100.0) - "r"."differential"), 1))
                END AS "points",
                CASE
                    WHEN ("r"."holes_played" = 9) THEN 0.5
                    ELSE 1.0
                END AS "floor_credit"
           FROM ((("public"."rounds" "r"
             JOIN "public"."league_members" "lm" ON (("lm"."profile_id" = "r"."profile_id")))
             JOIN "public"."league_settings" "ls" ON (("ls"."league_id" = "lm"."league_id")))
             JOIN "public"."seasons" "s" ON ((("s"."league_id" = "lm"."league_id") AND ("s"."status" = ANY (ARRAY['active'::"text", 'cup_final'::"text", 'complete'::"text"])) AND (("r"."played_on" >= "s"."starts_on") AND ("r"."played_on" <= "s"."ends_on")))))
          WHERE ((NOT "r"."voided") AND ("ls"."sim_rounds_allowed" OR (COALESCE("r"."source", 'app'::"text") <> 'sim'::"text")) AND ("ls"."nine_hole_allowed" OR ("r"."holes_played" = 18)))
        )
 SELECT "member_id",
    "season_id",
    "round_id",
    "profile_id",
    "played_on",
    "holes_played",
    "source",
    "attested",
    "differential",
    "index_at_post",
    "playing_index",
    "pvi",
    "points",
    "floor_credit",
    "row_number"() OVER (PARTITION BY "member_id", "season_id", ("date_trunc"('month'::"text", ("played_on")::timestamp with time zone)) ORDER BY "points" DESC, "pvi" DESC, "played_on" DESC) AS "month_rank"
   FROM "scored";


ALTER VIEW "public"."v_rounds_ranked" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_individual_standings" WITH ("security_invoker"='true') AS
 SELECT "lm"."id" AS "member_id",
    "s"."id" AS "season_id",
    COALESCE("sum"("rr"."points") FILTER (WHERE ("rr"."month_rank" <= COALESCE("ls"."counting_cap", 999))), (0)::bigint) AS "points",
    "count"("rr"."round_id") AS "rounds_posted"
   FROM ((("public"."league_members" "lm"
     JOIN "public"."seasons" "s" ON (("s"."league_id" = "lm"."league_id")))
     JOIN "public"."league_settings" "ls" ON (("ls"."league_id" = "lm"."league_id")))
     LEFT JOIN "public"."v_rounds_ranked" "rr" ON ((("rr"."member_id" = "lm"."id") AND ("rr"."season_id" = "s"."id"))))
  GROUP BY "lm"."id", "s"."id";


ALTER VIEW "public"."v_individual_standings" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_squad_standings" WITH ("security_invoker"='true') AS
 WITH "rp" AS (
         SELECT "sq"."season_id",
            "sq"."id" AS "squad_id",
            COALESCE("sum"("rr"."points") FILTER (WHERE ("rr"."month_rank" <= COALESCE("ls"."counting_cap", 999))), (0)::bigint) AS "pts"
           FROM (((("public"."squads" "sq"
             JOIN "public"."seasons" "se" ON (("se"."id" = "sq"."season_id")))
             JOIN "public"."league_settings" "ls" ON (("ls"."league_id" = "se"."league_id")))
             LEFT JOIN "public"."squad_members" "sm" ON (("sm"."squad_id" = "sq"."id")))
             LEFT JOIN "public"."v_rounds_ranked" "rr" ON ((("rr"."member_id" = "sm"."member_id") AND ("rr"."season_id" = "sq"."season_id"))))
          GROUP BY "sq"."season_id", "sq"."id", "ls"."counting_cap"
        ), "adj" AS (
         SELECT "season_adjustments"."season_id",
            "season_adjustments"."squad_id",
            COALESCE("sum"("season_adjustments"."points"), (0)::bigint) AS "pts"
           FROM "public"."season_adjustments"
          WHERE ("season_adjustments"."squad_id" IS NOT NULL)
          GROUP BY "season_adjustments"."season_id", "season_adjustments"."squad_id"
        )
 SELECT "rp"."season_id",
    "rp"."squad_id",
    ("rp"."pts" + COALESCE("adj"."pts", (0)::bigint)) AS "points"
   FROM ("rp"
     LEFT JOIN "adj" ON ((("adj"."season_id" = "rp"."season_id") AND ("adj"."squad_id" = "rp"."squad_id"))));


ALTER VIEW "public"."v_squad_standings" OWNER TO "postgres";


ALTER TABLE ONLY "public"."attestations"
    ADD CONSTRAINT "attestations_pkey" PRIMARY KEY ("round_id", "attested_by");



ALTER TABLE ONLY "public"."buy_ins"
    ADD CONSTRAINT "buy_ins_pkey" PRIMARY KEY ("season_id", "member_id");



ALTER TABLE ONLY "public"."commissioner_log"
    ADD CONSTRAINT "commissioner_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."course_holes"
    ADD CONSTRAINT "course_holes_pkey" PRIMARY KEY ("tee_id", "hole_number");



ALTER TABLE ONLY "public"."course_tees"
    ADD CONSTRAINT "course_tees_course_id_tee_name_gender_key" UNIQUE ("course_id", "tee_name", "gender");



ALTER TABLE ONLY "public"."course_tees"
    ADD CONSTRAINT "course_tees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "courses_external_id_key" UNIQUE ("external_id");



ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "courses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cup_finalists"
    ADD CONSTRAINT "cup_finalists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cup_finalists"
    ADD CONSTRAINT "cup_finalists_season_id_seed_key" UNIQUE ("season_id", "seed");



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_draft_id_member_id_key" UNIQUE ("draft_id", "member_id");



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_draft_id_pick_number_key" UNIQUE ("draft_id", "pick_number");



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drafts"
    ADD CONSTRAINT "drafts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drafts"
    ADD CONSTRAINT "drafts_season_id_key" UNIQUE ("season_id");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."game_results"
    ADD CONSTRAINT "game_results_pkey" PRIMARY KEY ("live_round_id", "player_id");



ALTER TABLE ONLY "public"."invites"
    ADD CONSTRAINT "invites_league_id_email_key" UNIQUE ("league_id", "email");



ALTER TABLE ONLY "public"."invites"
    ADD CONSTRAINT "invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."league_members"
    ADD CONSTRAINT "league_members_league_id_profile_id_key" UNIQUE ("league_id", "profile_id");



ALTER TABLE ONLY "public"."league_members"
    ADD CONSTRAINT "league_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."league_settings"
    ADD CONSTRAINT "league_settings_pkey" PRIMARY KEY ("league_id");



ALTER TABLE ONLY "public"."leagues"
    ADD CONSTRAINT "leagues_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."leagues"
    ADD CONSTRAINT "leagues_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."live_round_players"
    ADD CONSTRAINT "live_round_players_live_round_id_position_key" UNIQUE ("live_round_id", "position");



ALTER TABLE ONLY "public"."live_round_players"
    ADD CONSTRAINT "live_round_players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."live_scores"
    ADD CONSTRAINT "live_scores_pkey" PRIMARY KEY ("player_id", "hole_number");



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_kudos"
    ADD CONSTRAINT "post_kudos_pkey" PRIMARY KEY ("post_id", "member_id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."round_holes"
    ADD CONSTRAINT "round_holes_pkey" PRIMARY KEY ("round_id", "hole_number");



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."season_adjustments"
    ADD CONSTRAINT "season_adjustments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_league_id_number_key" UNIQUE ("league_id", "number");



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."squad_members"
    ADD CONSTRAINT "squad_members_pkey" PRIMARY KEY ("squad_id", "member_id");



ALTER TABLE ONLY "public"."squads"
    ADD CONSTRAINT "squads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."standings_snapshots"
    ADD CONSTRAINT "standings_snapshots_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."standings_snapshots"
    ADD CONSTRAINT "standings_snapshots_season_id_week_no_key" UNIQUE ("season_id", "week_no");



CREATE INDEX "league_members_profile" ON "public"."league_members" USING "btree" ("profile_id");



CREATE INDEX "posts_league_created" ON "public"."posts" USING "btree" ("league_id", "created_at");



CREATE UNIQUE INDEX "squad_members_one_per_season" ON "public"."squad_members" USING "btree" ("member_id", "squad_id");



CREATE OR REPLACE TRIGGER "rounds_after_insert" AFTER INSERT ON "public"."rounds" FOR EACH ROW EXECUTE FUNCTION "public"."round_to_board"();



CREATE OR REPLACE TRIGGER "rounds_before_insert" BEFORE INSERT ON "public"."rounds" FOR EACH ROW EXECUTE FUNCTION "public"."rounds_compute"();



ALTER TABLE ONLY "public"."attestations"
    ADD CONSTRAINT "attestations_round_id_fkey" FOREIGN KEY ("round_id") REFERENCES "public"."rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buy_ins"
    ADD CONSTRAINT "buy_ins_marked_by_fkey" FOREIGN KEY ("marked_by") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."buy_ins"
    ADD CONSTRAINT "buy_ins_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."buy_ins"
    ADD CONSTRAINT "buy_ins_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."commissioner_log"
    ADD CONSTRAINT "commissioner_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."commissioner_log"
    ADD CONSTRAINT "commissioner_log_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."course_holes"
    ADD CONSTRAINT "course_holes_tee_id_fkey" FOREIGN KEY ("tee_id") REFERENCES "public"."course_tees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."course_tees"
    ADD CONSTRAINT "course_tees_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "courses_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."cup_finalists"
    ADD CONSTRAINT "cup_finalists_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cup_finalists"
    ADD CONSTRAINT "cup_finalists_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cup_finalists"
    ADD CONSTRAINT "cup_finalists_squad_id_fkey" FOREIGN KEY ("squad_id") REFERENCES "public"."squads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "public"."drafts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_picked_by_fkey" FOREIGN KEY ("picked_by") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."draft_picks"
    ADD CONSTRAINT "draft_picks_squad_id_fkey" FOREIGN KEY ("squad_id") REFERENCES "public"."squads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."drafts"
    ADD CONSTRAINT "drafts_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."game_results"
    ADD CONSTRAINT "game_results_live_round_id_fkey" FOREIGN KEY ("live_round_id") REFERENCES "public"."live_rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."game_results"
    ADD CONSTRAINT "game_results_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."live_round_players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invites"
    ADD CONSTRAINT "invites_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."league_members"
    ADD CONSTRAINT "league_members_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."league_members"
    ADD CONSTRAINT "league_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."league_settings"
    ADD CONSTRAINT "league_settings_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."leagues"
    ADD CONSTRAINT "leagues_commissioner_id_fkey" FOREIGN KEY ("commissioner_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."live_round_players"
    ADD CONSTRAINT "live_round_players_live_round_id_fkey" FOREIGN KEY ("live_round_id") REFERENCES "public"."live_rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_round_players"
    ADD CONSTRAINT "live_round_players_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_started_by_fkey" FOREIGN KEY ("started_by") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."live_rounds"
    ADD CONSTRAINT "live_rounds_tee_id_fkey" FOREIGN KEY ("tee_id") REFERENCES "public"."course_tees"("id");



ALTER TABLE ONLY "public"."live_scores"
    ADD CONSTRAINT "live_scores_live_round_id_fkey" FOREIGN KEY ("live_round_id") REFERENCES "public"."live_rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."live_scores"
    ADD CONSTRAINT "live_scores_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."live_round_players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_kudos"
    ADD CONSTRAINT "post_kudos_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_kudos"
    ADD CONSTRAINT "post_kudos_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_round_id_fkey" FOREIGN KEY ("round_id") REFERENCES "public"."rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."round_holes"
    ADD CONSTRAINT "round_holes_round_id_fkey" FOREIGN KEY ("round_id") REFERENCES "public"."rounds"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id");



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_live_fk" FOREIGN KEY ("live_round_id") REFERENCES "public"."live_rounds"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."rounds"
    ADD CONSTRAINT "rounds_tee_id_fkey" FOREIGN KEY ("tee_id") REFERENCES "public"."course_tees"("id");



ALTER TABLE ONLY "public"."season_adjustments"
    ADD CONSTRAINT "season_adjustments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."season_adjustments"
    ADD CONSTRAINT "season_adjustments_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."season_adjustments"
    ADD CONSTRAINT "season_adjustments_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."season_adjustments"
    ADD CONSTRAINT "season_adjustments_squad_id_fkey" FOREIGN KEY ("squad_id") REFERENCES "public"."squads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_champion_squad_id_fkey" FOREIGN KEY ("champion_squad_id") REFERENCES "public"."squads"("id");



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_league_id_fkey" FOREIGN KEY ("league_id") REFERENCES "public"."leagues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."seasons"
    ADD CONSTRAINT "seasons_points_king_member_id_fkey" FOREIGN KEY ("points_king_member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."squad_members"
    ADD CONSTRAINT "squad_members_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."league_members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."squad_members"
    ADD CONSTRAINT "squad_members_squad_id_fkey" FOREIGN KEY ("squad_id") REFERENCES "public"."squads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."squads"
    ADD CONSTRAINT "squads_captain_member_id_fkey" FOREIGN KEY ("captain_member_id") REFERENCES "public"."league_members"("id");



ALTER TABLE ONLY "public"."squads"
    ADD CONSTRAINT "squads_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."standings_snapshots"
    ADD CONSTRAINT "standings_snapshots_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE CASCADE;



CREATE POLICY "adj_read" ON "public"."season_adjustments" FOR SELECT TO "authenticated" USING ("public"."is_league_member"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "season_adjustments"."season_id"))));



CREATE POLICY "adj_write" ON "public"."season_adjustments" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "season_adjustments"."season_id"))));



CREATE POLICY "attest_read" ON "public"."attestations" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."rounds" "r"
     JOIN "public"."seasons" "se" ON (("se"."id" = "r"."season_id")))
  WHERE (("r"."id" = "attestations"."round_id") AND "public"."is_league_member"("se"."league_id")))));



ALTER TABLE "public"."attestations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."buy_ins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "buyins_read" ON "public"."buy_ins" FOR SELECT TO "authenticated" USING ("public"."is_league_member"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "buy_ins"."season_id"))));



CREATE POLICY "buyins_write" ON "public"."buy_ins" TO "authenticated" USING ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "buy_ins"."season_id")))) WITH CHECK ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "buy_ins"."season_id"))));



CREATE POLICY "clog_add" ON "public"."commissioner_log" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_commissioner"("league_id"));



CREATE POLICY "clog_read" ON "public"."commissioner_log" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



CREATE POLICY "comments_add" ON "public"."post_comments" FOR INSERT TO "authenticated" WITH CHECK (("member_id" = ( SELECT "public"."my_member_id"("p"."league_id") AS "my_member_id"
   FROM "public"."posts" "p"
  WHERE ("p"."id" = "post_comments"."post_id"))));



CREATE POLICY "comments_read" ON "public"."post_comments" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."posts" "p"
  WHERE (("p"."id" = "post_comments"."post_id") AND "public"."is_league_member"("p"."league_id")))));



ALTER TABLE "public"."commissioner_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."course_holes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."course_tees" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."courses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "courses_add" ON "public"."courses" FOR INSERT TO "authenticated" WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "courses_edit" ON "public"."courses" FOR UPDATE TO "authenticated" USING (("created_by" = "auth"."uid"()));



CREATE POLICY "courses_read" ON "public"."courses" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."cup_finalists" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."draft_picks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."drafts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "drafts_read" ON "public"."drafts" FOR SELECT TO "authenticated" USING ("public"."is_league_member"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "drafts"."season_id"))));



CREATE POLICY "drafts_write" ON "public"."drafts" TO "authenticated" USING ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "drafts"."season_id")))) WITH CHECK ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "drafts"."season_id"))));



CREATE POLICY "fb_add" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_league_member"("league_id"));



CREATE POLICY "fb_read" ON "public"."feedback" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "finalists_member_read" ON "public"."cup_finalists" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."seasons" "se"
  WHERE (("se"."id" = "cup_finalists"."season_id") AND "public"."is_league_member"("se"."league_id")))));



ALTER TABLE "public"."game_results" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gamer_all" ON "public"."game_results" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "game_results"."live_round_id") AND "public"."is_league_member"("lr"."league_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "game_results"."live_round_id") AND "public"."is_league_member"("lr"."league_id")))));



CREATE POLICY "holes_add" ON "public"."course_holes" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."course_tees" "t"
     JOIN "public"."courses" "c" ON (("c"."id" = "t"."course_id")))
  WHERE (("t"."id" = "course_holes"."tee_id") AND (("c"."created_by" = "auth"."uid"()) OR ("c"."source" = 'manual'::"text"))))));



CREATE POLICY "holes_read" ON "public"."course_holes" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."invites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "invites_all" ON "public"."invites" TO "authenticated" USING ("public"."is_commissioner"("league_id")) WITH CHECK ("public"."is_commissioner"("league_id"));



CREATE POLICY "kudos_all" ON "public"."post_kudos" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."posts" "p"
  WHERE (("p"."id" = "post_kudos"."post_id") AND "public"."is_league_member"("p"."league_id"))))) WITH CHECK (("member_id" = ( SELECT "public"."my_member_id"("p"."league_id") AS "my_member_id"
   FROM "public"."posts" "p"
  WHERE ("p"."id" = "post_kudos"."post_id"))));



ALTER TABLE "public"."league_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."league_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."leagues" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "leagues_create" ON "public"."leagues" FOR INSERT TO "authenticated" WITH CHECK (("commissioner_id" = "auth"."uid"()));



CREATE POLICY "leagues_owner_read" ON "public"."leagues" FOR SELECT TO "authenticated" USING (("commissioner_id" = "auth"."uid"()));



CREATE POLICY "leagues_read" ON "public"."leagues" FOR SELECT TO "authenticated" USING (("public"."is_league_member"("id") OR ("commissioner_id" = "auth"."uid"())));



CREATE POLICY "leagues_update" ON "public"."leagues" FOR UPDATE TO "authenticated" USING ("public"."is_commissioner"("id"));



CREATE POLICY "live_read" ON "public"."live_rounds" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



ALTER TABLE "public"."live_round_players" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."live_rounds" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."live_scores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "live_write" ON "public"."live_rounds" TO "authenticated" USING ("public"."is_league_member"("league_id")) WITH CHECK ("public"."is_league_member"("league_id"));



CREATE POLICY "livep_all" ON "public"."live_round_players" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "live_round_players"."live_round_id") AND "public"."is_league_member"("lr"."league_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "live_round_players"."live_round_id") AND "public"."is_league_member"("lr"."league_id")))));



CREATE POLICY "lives_all" ON "public"."live_scores" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "live_scores"."live_round_id") AND "public"."is_league_member"("lr"."league_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."live_rounds" "lr"
  WHERE (("lr"."id" = "live_scores"."live_round_id") AND "public"."is_league_member"("lr"."league_id")))));



CREATE POLICY "member_bootstrap" ON "public"."league_members" FOR INSERT TO "authenticated" WITH CHECK ((("profile_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."leagues" "l"
  WHERE (("l"."id" = "league_members"."league_id") AND ("l"."commissioner_id" = "auth"."uid"()))))));



CREATE POLICY "members_read" ON "public"."league_members" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



CREATE POLICY "members_self" ON "public"."league_members" FOR UPDATE TO "authenticated" USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "picks_none" ON "public"."draft_picks" FOR INSERT TO "authenticated" WITH CHECK (false);



CREATE POLICY "picks_read" ON "public"."draft_picks" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."drafts" "d"
     JOIN "public"."seasons" "se" ON (("se"."id" = "d"."season_id")))
  WHERE (("d"."id" = "draft_picks"."draft_id") AND "public"."is_league_member"("se"."league_id")))));



ALTER TABLE "public"."post_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_kudos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "posts_chat" ON "public"."posts" FOR INSERT TO "authenticated" WITH CHECK ((("kind" = 'chat'::"text") AND ("member_id" = "public"."my_member_id"("league_id"))));



CREATE POLICY "posts_read" ON "public"."posts" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_league_read" ON "public"."profiles" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."league_members" "a"
     JOIN "public"."league_members" "b" ON (("b"."league_id" = "a"."league_id")))
  WHERE (("a"."profile_id" = "auth"."uid"()) AND ("b"."profile_id" = "profiles"."id")))));



CREATE POLICY "profiles_read" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "profiles_self_select" ON "public"."profiles" FOR SELECT USING (("id" = "auth"."uid"()));



CREATE POLICY "profiles_self_update" ON "public"."profiles" FOR UPDATE USING (("id" = "auth"."uid"()));



CREATE POLICY "profiles_write" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "rholes_add" ON "public"."round_holes" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."rounds" "r"
  WHERE (("r"."id" = "round_holes"."round_id") AND ("r"."profile_id" = "auth"."uid"())))));



CREATE POLICY "rholes_read" ON "public"."round_holes" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."rounds" "r"
     JOIN "public"."seasons" "se" ON (("se"."id" = "r"."season_id")))
  WHERE (("r"."id" = "round_holes"."round_id") AND "public"."is_league_member"("se"."league_id")))));



ALTER TABLE "public"."round_holes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rounds" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "rounds_owner_insert" ON "public"."rounds" FOR INSERT WITH CHECK (("profile_id" = "auth"."uid"()));



CREATE POLICY "rounds_owner_update" ON "public"."rounds" FOR UPDATE USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "rounds_read" ON "public"."rounds" FOR SELECT USING ((("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM ("public"."league_members" "a"
     JOIN "public"."league_members" "b" ON (("b"."league_id" = "a"."league_id")))
  WHERE (("a"."profile_id" = "auth"."uid"()) AND ("b"."profile_id" = "rounds"."profile_id"))))));



ALTER TABLE "public"."season_adjustments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."seasons" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "seasons_read" ON "public"."seasons" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



CREATE POLICY "seasons_write" ON "public"."seasons" TO "authenticated" USING ("public"."is_commissioner"("league_id")) WITH CHECK ("public"."is_commissioner"("league_id"));



CREATE POLICY "settings_read" ON "public"."league_settings" FOR SELECT TO "authenticated" USING ("public"."is_league_member"("league_id"));



CREATE POLICY "settings_write" ON "public"."league_settings" TO "authenticated" USING (("public"."is_commissioner"("league_id") AND ("locked_at" IS NULL))) WITH CHECK ("public"."is_commissioner"("league_id"));



CREATE POLICY "snapshots_member_read" ON "public"."standings_snapshots" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."seasons" "se"
  WHERE (("se"."id" = "standings_snapshots"."season_id") AND "public"."is_league_member"("se"."league_id")))));



ALTER TABLE "public"."squad_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "squadm_read" ON "public"."squad_members" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."squads" "s"
     JOIN "public"."seasons" "se" ON (("se"."id" = "s"."season_id")))
  WHERE (("s"."id" = "squad_members"."squad_id") AND "public"."is_league_member"("se"."league_id")))));



CREATE POLICY "squadm_write" ON "public"."squad_members" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."squads" "s"
     JOIN "public"."seasons" "se" ON (("se"."id" = "s"."season_id")))
  WHERE (("s"."id" = "squad_members"."squad_id") AND "public"."is_commissioner"("se"."league_id")))));



ALTER TABLE "public"."squads" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "squads_read" ON "public"."squads" FOR SELECT TO "authenticated" USING ("public"."is_league_member"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "squads"."season_id"))));



CREATE POLICY "squads_write" ON "public"."squads" TO "authenticated" USING ("public"."is_commissioner"(( SELECT "seasons"."league_id"
   FROM "public"."seasons"
  WHERE ("seasons"."id" = "squads"."season_id"))));



ALTER TABLE "public"."standings_snapshots" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tees_add" ON "public"."course_tees" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."courses" "c"
  WHERE (("c"."id" = "course_tees"."course_id") AND (("c"."created_by" = "auth"."uid"()) OR ("c"."source" = 'manual'::"text"))))));



CREATE POLICY "tees_read" ON "public"."course_tees" FOR SELECT TO "authenticated" USING (true);





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."draft_picks";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."drafts";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."live_round_players";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."live_rounds";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."live_scores";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."post_comments";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."post_kudos";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."posts";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";






















































































































































GRANT ALL ON FUNCTION "public"."assign_player"("p_squad" "uuid", "p_member" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."assign_player"("p_squad" "uuid", "p_member" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."assign_player"("p_squad" "uuid", "p_member" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_month"("p_season" "uuid", "p_month" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."close_season"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."close_season"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_season"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_league"("p_name" "text", "p_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_league"("p_name" "text", "p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_league"("p_name" "text", "p_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."cup_points"("p_pvi" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."cup_points"("p_pvi" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cup_points"("p_pvi" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."daily_season_tick"() TO "anon";
GRANT ALL ON FUNCTION "public"."daily_season_tick"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."daily_season_tick"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enter_cup_final"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."enter_cup_final"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."enter_cup_final"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."finish_live_round"("p_live_round" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."finish_live_round"("p_live_round" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."finish_live_round"("p_live_round" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."form_squads"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."form_squads"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."form_squads"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_commissioner"("p_league" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_commissioner"("p_league" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_commissioner"("p_league" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_league_member"("p_league" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_league_member"("p_league" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_league_member"("p_league" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."join_league"("p_code" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."join_league"("p_code" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_league"("p_code" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."make_pick"("p_draft" "uuid", "p_member" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."my_member_id"("p_league" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."my_member_id"("p_league" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."my_member_id"("p_league" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."randomize_squads"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."randomize_squads"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."randomize_squads"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."round_to_board"() TO "anon";
GRANT ALL ON FUNCTION "public"."round_to_board"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."round_to_board"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rounds_compute"() TO "anon";
GRANT ALL ON FUNCTION "public"."rounds_compute"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rounds_compute"() TO "service_role";



GRANT ALL ON FUNCTION "public"."run_month_closes"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_month_closes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_month_closes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."run_week_snapshots"() TO "anon";
GRANT ALL ON FUNCTION "public"."run_week_snapshots"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."run_week_snapshots"() TO "service_role";



GRANT ALL ON FUNCTION "public"."score_round"() TO "anon";
GRANT ALL ON FUNCTION "public"."score_round"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."score_round"() TO "service_role";



GRANT ALL ON FUNCTION "public"."score_round"("p_gross" integer, "p_rating" numeric, "p_slope" integer, "p_nine_rating" numeric, "p_index" numeric, "p_allowance" integer, "p_holes" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."score_round"("p_gross" integer, "p_rating" numeric, "p_slope" integer, "p_nine_rating" numeric, "p_index" numeric, "p_allowance" integer, "p_holes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."score_round"("p_gross" integer, "p_rating" numeric, "p_slope" integer, "p_nine_rating" numeric, "p_index" numeric, "p_allowance" integer, "p_holes" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_profile"("p_name" "text", "p_city" "text", "p_home" "text", "p_index" numeric, "p_marker" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_profile"("p_name" "text", "p_city" "text", "p_home" "text", "p_index" numeric, "p_marker" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_profile"("p_name" "text", "p_city" "text", "p_home" "text", "p_index" numeric, "p_marker" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."snapshot_week"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."snapshot_week"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."snapshot_week"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."start_draft"("p_season" "uuid", "p_shuffle" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."start_draft"("p_season" "uuid", "p_shuffle" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_draft"("p_season" "uuid", "p_shuffle" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."start_season"("p_season" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."start_season"("p_season" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_season"("p_season" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."undo_pick"("p_draft" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."undo_pick"("p_draft" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."undo_pick"("p_draft" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."attestations" TO "anon";
GRANT ALL ON TABLE "public"."attestations" TO "authenticated";
GRANT ALL ON TABLE "public"."attestations" TO "service_role";



GRANT ALL ON TABLE "public"."buy_ins" TO "anon";
GRANT ALL ON TABLE "public"."buy_ins" TO "authenticated";
GRANT ALL ON TABLE "public"."buy_ins" TO "service_role";



GRANT ALL ON TABLE "public"."commissioner_log" TO "anon";
GRANT ALL ON TABLE "public"."commissioner_log" TO "authenticated";
GRANT ALL ON TABLE "public"."commissioner_log" TO "service_role";



GRANT ALL ON TABLE "public"."course_holes" TO "anon";
GRANT ALL ON TABLE "public"."course_holes" TO "authenticated";
GRANT ALL ON TABLE "public"."course_holes" TO "service_role";



GRANT ALL ON TABLE "public"."course_tees" TO "anon";
GRANT ALL ON TABLE "public"."course_tees" TO "authenticated";
GRANT ALL ON TABLE "public"."course_tees" TO "service_role";



GRANT ALL ON TABLE "public"."courses" TO "anon";
GRANT ALL ON TABLE "public"."courses" TO "authenticated";
GRANT ALL ON TABLE "public"."courses" TO "service_role";



GRANT ALL ON TABLE "public"."cup_finalists" TO "anon";
GRANT ALL ON TABLE "public"."cup_finalists" TO "authenticated";
GRANT ALL ON TABLE "public"."cup_finalists" TO "service_role";



GRANT ALL ON TABLE "public"."draft_picks" TO "anon";
GRANT ALL ON TABLE "public"."draft_picks" TO "authenticated";
GRANT ALL ON TABLE "public"."draft_picks" TO "service_role";



GRANT ALL ON TABLE "public"."drafts" TO "anon";
GRANT ALL ON TABLE "public"."drafts" TO "authenticated";
GRANT ALL ON TABLE "public"."drafts" TO "service_role";



GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";



GRANT ALL ON TABLE "public"."game_results" TO "anon";
GRANT ALL ON TABLE "public"."game_results" TO "authenticated";
GRANT ALL ON TABLE "public"."game_results" TO "service_role";



GRANT ALL ON TABLE "public"."invites" TO "anon";
GRANT ALL ON TABLE "public"."invites" TO "authenticated";
GRANT ALL ON TABLE "public"."invites" TO "service_role";



GRANT ALL ON TABLE "public"."league_members" TO "anon";
GRANT ALL ON TABLE "public"."league_members" TO "authenticated";
GRANT ALL ON TABLE "public"."league_members" TO "service_role";



GRANT ALL ON TABLE "public"."league_settings" TO "anon";
GRANT ALL ON TABLE "public"."league_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."league_settings" TO "service_role";



GRANT ALL ON TABLE "public"."leagues" TO "anon";
GRANT ALL ON TABLE "public"."leagues" TO "authenticated";
GRANT ALL ON TABLE "public"."leagues" TO "service_role";



GRANT ALL ON TABLE "public"."live_round_players" TO "anon";
GRANT ALL ON TABLE "public"."live_round_players" TO "authenticated";
GRANT ALL ON TABLE "public"."live_round_players" TO "service_role";



GRANT ALL ON TABLE "public"."live_rounds" TO "anon";
GRANT ALL ON TABLE "public"."live_rounds" TO "authenticated";
GRANT ALL ON TABLE "public"."live_rounds" TO "service_role";



GRANT ALL ON TABLE "public"."live_scores" TO "anon";
GRANT ALL ON TABLE "public"."live_scores" TO "authenticated";
GRANT ALL ON TABLE "public"."live_scores" TO "service_role";



GRANT ALL ON TABLE "public"."post_comments" TO "anon";
GRANT ALL ON TABLE "public"."post_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."post_comments" TO "service_role";



GRANT ALL ON TABLE "public"."post_kudos" TO "anon";
GRANT ALL ON TABLE "public"."post_kudos" TO "authenticated";
GRANT ALL ON TABLE "public"."post_kudos" TO "service_role";



GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."round_holes" TO "anon";
GRANT ALL ON TABLE "public"."round_holes" TO "authenticated";
GRANT ALL ON TABLE "public"."round_holes" TO "service_role";



GRANT ALL ON TABLE "public"."rounds" TO "anon";
GRANT ALL ON TABLE "public"."rounds" TO "authenticated";
GRANT ALL ON TABLE "public"."rounds" TO "service_role";



GRANT ALL ON TABLE "public"."season_adjustments" TO "anon";
GRANT ALL ON TABLE "public"."season_adjustments" TO "authenticated";
GRANT ALL ON TABLE "public"."season_adjustments" TO "service_role";



GRANT ALL ON TABLE "public"."seasons" TO "anon";
GRANT ALL ON TABLE "public"."seasons" TO "authenticated";
GRANT ALL ON TABLE "public"."seasons" TO "service_role";



GRANT ALL ON TABLE "public"."squad_members" TO "anon";
GRANT ALL ON TABLE "public"."squad_members" TO "authenticated";
GRANT ALL ON TABLE "public"."squad_members" TO "service_role";



GRANT ALL ON TABLE "public"."squads" TO "anon";
GRANT ALL ON TABLE "public"."squads" TO "authenticated";
GRANT ALL ON TABLE "public"."squads" TO "service_role";



GRANT ALL ON TABLE "public"."standings_snapshots" TO "anon";
GRANT ALL ON TABLE "public"."standings_snapshots" TO "authenticated";
GRANT ALL ON TABLE "public"."standings_snapshots" TO "service_role";



GRANT ALL ON TABLE "public"."v_rounds_ranked" TO "anon";
GRANT ALL ON TABLE "public"."v_rounds_ranked" TO "authenticated";
GRANT ALL ON TABLE "public"."v_rounds_ranked" TO "service_role";



GRANT ALL ON TABLE "public"."v_individual_standings" TO "anon";
GRANT ALL ON TABLE "public"."v_individual_standings" TO "authenticated";
GRANT ALL ON TABLE "public"."v_individual_standings" TO "service_role";



GRANT ALL ON TABLE "public"."v_squad_standings" TO "anon";
GRANT ALL ON TABLE "public"."v_squad_standings" TO "authenticated";
GRANT ALL ON TABLE "public"."v_squad_standings" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































