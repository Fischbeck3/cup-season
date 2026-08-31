-- D165 · the board stops shouting.
--
-- OWNER RULING (2026-08-31): authored SENTENCES — anything a person reads as
-- prose — are written in NATURAL CASE at the generator, in SQL, permanently.
-- ALL-CAPS survives only as typographic furniture that was never a sentence:
-- eyebrows, status chips, data rows ("THRU 14 · +2"), settlement headlines.
--
-- This is not taste. Three findings made it a defect:
--
--  1. `easeCaps()` on the web (index.html:5050) only fires when the WHOLE string
--     is uppercase. Every generator here interpolates something — a name, ' v ',
--     '@handle' — so the guard fails and the entire line ships raw caps anyway.
--  2. `supabase/functions/push/index.ts` has NO lowercasing pass. Every shouted
--     body reaches the lock screen shouting — the surface with the least context
--     and the most people.
--  3. Even when easeCaps DOES fire it destroys proper nouns permanently. The
--     client's own comment says it: no cleverness recovers a proper noun from an
--     all-caps source. `upper(v_course)`, `upper(s.name)` and `upper(name)` were
--     erasing real course, event and squad names on the way into the database.
--
-- It was already proven safe: 20260727160000_board_voice.sql writes its floor
-- branches in natural case and they read best on the board. This finishes it.
--
-- Every body below is the LIVE definition pulled from prod with
-- pg_get_functiondef, patched fragment-by-fragment, and re-emitted whole.
-- CLAUDE.md rule 2: a fix is a NEW migration, never an edit to a shipped one.
--
-- ---------------------------------------------------------------------------
-- BUGS FIXED IN PASSING (found by the voice audit, verified against prod)
--
--  · MOJIBAKE. `finish_live_round` and `start_live_round` carried 10 sequences
--    of double-encoded UTF-8 — U+00E2 U+0080 U+0094 where an em dash belongs,
--    U+00C2 U+00B7 for a middot. Four sat in LIVE COPY, including the live-round
--    push body ("Live round at X <mojibake> open the app to score it") and the
--    halved-match settlement line. No garbled post is on the board yet only
--    because those paths had not fired. All 10 retyped.
--
--  · THE SOLO ROUND ROBIN REPORTED THE WRONG RESULT. `rrResult()` on the web
--    returns no winner and no sides, so every 4-player solo round robin fell
--    into the halved branch: the board read "side A and side B halved the match
--    — no money moves" while the client had already moved real money. The fix
--    is a RESTORATION — 20260727240000_name_resolution.sql wrote a client-story
--    branch and a later create-or-replace chain dropped it.
--
--  · `posts.push_title` STOPPED BEING WRITTEN by the same regression, so
--    settlement pushes lost their titles. Restored.
--
--  · "with pick 0". `make_pick` captured the draft row FOR UPDATE before
--    incrementing current_pick, so every draft's opening pick announced itself
--    as pick zero.
--
--  · "Jerecho take the Cup Final". In a SOLO league the champion is a person,
--    so the season's most-read sentence disagreed with itself. `v_solo` was
--    already in scope.
--
-- Nothing here changes a competition rule. Every fact each post carried before
-- it still carries: the names, the numbers, the consequences.


-- ---- add_event_player --------------------------------------------------
CREATE OR REPLACE FUNCTION public.add_event_player(p_event uuid, p_profile uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_kind text; v_league uuid; v_exh boolean; v_n int; v_name text;
begin
  if not is_event_organizer(p_event) then
    raise exception 'organizer only';
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a session has been scored';
  end if;

  select kind, league_id into v_kind, v_league from events where id = p_event;

  -- D148: consent. A direct add needs a standing relationship; everyone else
  -- goes through invite_golfer, which asks and can be declined.
  if p_profile <> auth.uid()
     and not (v_league is not null and exists (
                select 1 from league_members lm
                 where lm.league_id = v_league and lm.profile_id = p_profile))
     and not exists (
                select 1 from friendships f
                 where f.status = 'accepted'
                   and ((f.requester = auth.uid() and f.addressee = p_profile)
                     or (f.addressee = auth.uid() and f.requester = p_profile)))
  then
    raise exception 'You can add golfers from this league or your buddies list. For anyone else, send an invite so they can accept.';
  end if;

  v_exh := (v_kind = 'major') and not major_contender(p_profile);

  select coalesce(max(seed), 0) + 1 into v_n from event_players where event_id = p_event;

  insert into event_players (event_id, profile_id, seed, exhibition)
  values (p_event, p_profile, v_n, v_exh)
  on conflict (event_id, profile_id) do nothing
  returning id into v_id;

  if v_id is not null and v_kind = 'major' then
    select display_name into v_name from profiles where id = p_profile;
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event, coalesce(v_name,'A golfer') || ' is in. Field of ' || v_n || '.');
  end if;

  return v_id;
end $function$;

-- ---- add_friend_to_league ----------------------------------------------
CREATE OR REPLACE FUNCTION public.add_friend_to_league(p_league uuid, p_profile uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_name text; v_idx numeric; v_member uuid; v_squad text;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro adds players';
  end if;
  -- the probe found the old helper never existed in prod — this is the inline
  -- test the rest of the schema uses (search_golfers, nearby_resolve)
  if not exists (select 1 from friendships f
                  where least(f.requester, f.addressee)    = least(auth.uid(), p_profile)
                    and greatest(f.requester, f.addressee) = greatest(auth.uid(), p_profile)
                    and f.status = 'accepted') then
    raise exception 'Not golf buddies yet — send a request first';
  end if;
  if exists (select 1 from league_members
             where league_id = p_league and profile_id = p_profile) then
    raise exception 'Already in the league';
  end if;
  -- D161 · the Pro vouches, so this door stays open to the halfway turn
  perform _join_gate(p_league, true);

  select display_name, index_current into v_name, v_idx
    from profiles where id = p_profile;

  insert into league_members (league_id, profile_id, role, index_current)
  values (p_league, p_profile, 'player', coalesce(v_idx, 18.0))
  returning id into v_member;

  -- §15 · a joiner after the draw lands on the thinnest squad, and it is said
  v_squad := _late_squad(p_league, v_member);

  insert into posts (league_id, kind, body)
  values (p_league, 'system',
          coalesce(v_name, 'A golfer') || ' is in — the Pro added them. Welcome to the league.'
          || case when v_squad is not null
                  then ' The thinnest squad takes them: ' || v_squad || '.'
                  else '' end);
end $function$;

-- ---- close_month -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_month(p_season uuid, p_month date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare st record; se record; m record; short numeric; delta int;
        winner uuid; is_partial boolean; month_last date; v_name text;
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;

  if exists (select 1 from season_adjustments
             where season_id = p_season and month = p_month
               and kind = 'month_closed' and created_by is null) then
    return;
  end if;

  month_last := (p_month + interval '1 month' - interval '1 day')::date;
  is_partial := (se.starts_on > p_month) or (se.ends_on < month_last);

  -- 1 · floor penalties — now with the auto-bye first-miss forgiveness (D14)
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
      -- a bye already booked for THIS month (Pro pre-grant) skips the member
      where not exists (select 1 from season_adjustments b
                        where b.season_id = p_season and b.member_id = sm.member_id
                          and b.month = p_month and b.kind = 'bye')
        -- D161 · a member who JOINED during this month was only there for part
        -- of it — the partial-month rule, applied per member. No penalty, no
        -- bye spent; the floor bites from their first full month.
        and not exists (select 1 from league_members lm
                        where lm.id = sm.member_id
                          and date_trunc('month',
                                (lm.joined_at at time zone coalesce(se.timezone,'America/Phoenix')))::date
                              = p_month)
      group by sm.squad_id, sm.member_id
    loop
      short := greatest(0, st.participation_floor - m.credits);
      if short > 0 then
        -- has this member spent their ONE season bye yet (any month)?
        if not exists (select 1 from season_adjustments b
                       where b.season_id = p_season and b.member_id = m.member_id
                         and b.kind = 'bye') then
          -- no → the season's bye auto-covers this first miss. Life happens.
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'bye', 0,
                  'Auto-bye — first missed floor. Life happens; the season''s one bye.');
          select display_name into v_name from profiles p
            join league_members lm on lm.profile_id = p.id where lm.id = m.member_id;
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  coalesce(v_name,'A golfer')||'''s one bye covers '
                  ||to_char(p_month,'FMMonth')
                  ||'. No penalty. The floor bites from here.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits||' · bye already used');
          insert into posts (league_id, season_id, kind, member_id, body)
          values (se.league_id, p_season, 'system', m.member_id,
                  coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                  ||' was short on rounds in '||to_char(p_month,'FMMonth')
                  ||'. '||abs(delta)||' points off the squad.');
        else  -- forfeit
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited · bye already used');
            insert into posts (league_id, season_id, kind, member_id, body)
            values (se.league_id, p_season, 'system', m.member_id,
                    coalesce(firstname((select pr.display_name
                              from league_members lm2
                              join profiles pr on pr.id = lm2.profile_id
                             where lm2.id = m.member_id)), 'A golfer')
                    ||' loses '||to_char(p_month,'FMMonth')||' — '||m.counting_pts
                    ||' points, not enough rounds.');
          end if;
        end if;
      end if;
    end loop;
  end if;

  -- 2 · hybrid matchup bonus (unchanged)
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
      select se.league_id, p_season, 'system', 'The monthly goes to '||name||'. 15 points.'
      from squads where id = winner;
    end if;
  end if;

  -- 3 · sentinel + the §14.2 "month closed" board event (unchanged)
  insert into season_adjustments (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial edge month — floors waived'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          to_char(p_month,'FMMonth')||' is in the books. The ledger is posted.'
          || case when is_partial then ' A partial month — floors waived.' else '' end);
end $function$;

-- ---- close_season ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; king uuid;
  v_solo boolean; v_finalists boolean; v_cup boolean;
  cap_n integer; cf_start date;
  c1 record; c2 record;
  v_rung text := null; v_story text; v_score1 text; v_score2 text;
  v_kname text; v_champname text; v_runname text;
  v_money jsonb; v_owed_names text; v_pot_line text;
begin
  select * into se from seasons where id = p_season;
  if se.status = 'complete' then return; end if;              -- idempotent
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (st.structure = 'solo');
  cap_n := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;
  v_finalists := exists (select 1 from cup_finalists where season_id = p_season);
  v_cup := coalesce(st.finish,'cup_final') = 'cup_final' and v_finalists;

  drop table if exists _cont; drop table if exists _ranked;
  create temp table _cont (
    cid uuid, member_id uuid, head numeric default 0
  ) on commit drop;

  if v_cup then
    if v_solo then
      insert into _cont select cf.member_id, cf.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf where cf.season_id = p_season and cf.member_id is not null;
    else
      insert into _cont select cf.squad_id, sm.member_id, coalesce(cf.head_start,0)
        from cup_finalists cf
        join squad_members sm on sm.squad_id = cf.squad_id
       where cf.season_id = p_season and cf.squad_id is not null;
    end if;
  else
    if v_solo then
      insert into _cont select ist.member_id, ist.member_id, 0
        from v_individual_standings ist where ist.season_id = p_season;
    else
      insert into _cont select sm.squad_id, sm.member_id, 0
        from squads s join squad_members sm on sm.squad_id = s.id
       where s.season_id = p_season;
    end if;
  end if;

  create temp table _ranked (
    cid uuid, score numeric, months_won int, best_month numeric,
    rounds_used int, coin double precision
  ) on commit drop;
  insert into _ranked
  with pts as (
    -- D105: in the Final the window score is the SHARED helper — the same rows
    -- cup_final_race() shows the room, so the crown and the race cannot drift.
    select c.cid, max(c.head) + coalesce(sum(w.points), 0) as score
      from _cont c
      left join _cup_window_rounds(p_season) w on w.member_id = c.member_id
     where v_cup
     group by c.cid
    union all
    select c.cid,
           max(c.head) + coalesce(sum(rr.points) filter (where rr.month_rank <= cap_n), 0) as score
      from _cont c
      left join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
     where not v_cup
     group by c.cid
  ),
  months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon,
           sum(rr.points) as mpts
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won
      from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (
    select cid, max(mpts) as best from months group by cid
  ),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _cont c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n
     group by c.cid
  )
  select p.cid, p.score,
         coalesce(w.won,0),
         coalesce(b.best,0),
         coalesce(u.used,0),
         random()
    from pts p
    left join months_won w on w.cid = p.cid
    left join best_month b on b.cid = p.cid
    left join rounds_used u on u.cid = p.cid;

  if not v_cup then
    if v_solo then
      update _ranked r set score = coalesce(
        (select i.points from v_individual_standings i
          where i.season_id = p_season and i.member_id = r.cid), 0);
    else
      update _ranked r set score = coalesce(
        (select s.points from v_squad_standings s
          where s.season_id = p_season and s.squad_id = r.cid), 0);
    end if;
  end if;

  select * into c1 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   limit 1;
  select * into c2 from _ranked
   order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc
   offset 1 limit 1;

  if c2.cid is not null and c1.score = c2.score then
    if c1.months_won <> c2.months_won then v_rung := 'months won';
    elsif c1.best_month <> c2.best_month then v_rung := 'best single month';
    elsif c1.rounds_used <> c2.rounds_used then v_rung := 'fewest rounds used';
    else v_rung := 'coin flip'; end if;
  end if;

  select member_id into king from v_individual_standings
   where season_id = p_season order by points desc nulls last limit 1;

  -- D66: the deciding numbers are STORED, not just narrated
  update seasons set status = 'complete',
    champion_squad_id  = case when not v_solo then c1.cid end,
    champion_member_id = case when v_solo then c1.cid end,
    runnerup_squad_id  = case when not v_solo then c2.cid end,
    runnerup_member_id = case when v_solo then c2.cid end,
    points_king_member_id = king,
    champion_score = c1.score,
    runnerup_score = c2.score,
    tiebreak_rung  = v_rung
    where id = p_season;
  update leagues set phase = 'complete' where id = se.league_id;

  if v_solo then
    select coalesce(p.display_name,'The champion') into v_champname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c1.cid;
    select coalesce(p.display_name,'') into v_runname
      from league_members lm join profiles p on p.id = lm.profile_id where lm.id = c2.cid;
  else
    select name into v_champname from squads where id = c1.cid;
    select name into v_runname from squads where id = c2.cid;
  end if;
  select coalesce(p.display_name,'') into v_kname
    from league_members lm join profiles p on p.id = lm.profile_id where lm.id = king;
  -- (never trim(trailing '.0') — it eats real zeros: '210.0' -> '21')
  v_score1 := case when c1.score = floor(c1.score) then c1.score::int::text else round(c1.score,1)::text end;
  v_score2 := case when c2.cid is null then null
                   when c2.score = floor(c2.score) then c2.score::int::text
                   else round(c2.score,1)::text end;

  -- D66: natural case — proper nouns survive the client's easeCaps intact
  v_story := 'Season complete: ' || coalesce(v_champname,'The champion')
    || case when v_solo then ' takes' else ' take' end
    || case when v_cup then ' the Cup Final' else ' the Cup' end
    || case when v_score2 is not null then ' ' || v_score1 || '–' || v_score2 else '' end
    || case when v_rung is not null then ' · tiebreak: ' || v_rung else '' end
    || case when v_kname <> '' then ' · Points king: ' || v_kname else '' end;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_story);

  -- the trophies, and the money — split from what was COLLECTED (D106)
  perform award_season_trophies(p_season);

  -- the pot line: tracked, never held (§14.4 — the settlement is a post)
  select jsonb_build_object(
           'pot_cents', s.pot_cents, 'collected_cents', s.collected_cents,
           'champ',  coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Cup champion'), 0),
           'runner', coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Runner-up'), 0),
           'king',   coalesce((select sum(cents) from season_payouts where season_id = p_season and reason = 'Points king'), 0))
    into v_money from seasons s where s.id = p_season;
  if coalesce((v_money->>'pot_cents')::bigint, 0) > 0 then
    select string_agg(coalesce(p.display_name, 'A golfer'), ', ' order by p.display_name)
      into v_owed_names
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.league_id = se.league_id
       and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);
    v_pot_line := 'The pot: $' || round((v_money->>'pot_cents')::numeric / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · collected $' || round((v_money->>'collected_cents')::numeric / 100.0);
    end if;
    v_pot_line := v_pot_line
      || ' — champs $'      || round((v_money->>'champ')::numeric  / 100.0)
      || ' · runner-up $'   || round((v_money->>'runner')::numeric / 100.0)
      || ' · points king $' || round((v_money->>'king')::numeric   / 100.0);
    if (v_money->>'collected_cents')::bigint < (v_money->>'pot_cents')::bigint then
      v_pot_line := v_pot_line || ' · still owed: $'
        || round(((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric) / 100.0)
        || coalesce(' (' || v_owed_names || ')', '');
    end if;
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system', v_pot_line || ' · settle between yourselves');
  end if;
end $function$;

-- ---- create_major ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_major(p_name text, p_final_on date, p_days integer DEFAULT 4, p_buy_in numeric DEFAULT 0, p_pot_split text DEFAULT 'places'::text, p_league uuid DEFAULT NULL::uuid, p_tz text DEFAULT NULL::text, p_lineage uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_event uuid; v_name text; v_days integer; v_split text; v_buy numeric;
  v_open date; v_tz text; v_root uuid; v_nth integer; v_def text; v_annual text := '';
begin
  v_name := nullif(trim(coalesce(p_name,'')), '');
  if v_name is null then raise exception 'Name the jug — a Major needs a name'; end if;
  if p_final_on is null or p_final_on < current_date then
    raise exception 'The final day has to be ahead of you';
  end if;
  if p_final_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  v_days  := greatest(2, least(4, coalesce(p_days, 4)));
  v_buy   := coalesce(p_buy_in, 0);
  if v_buy < 0 or v_buy > 100000 then raise exception 'buy-in out of range'; end if;
  v_split := coalesce(p_pot_split, 'places');
  if v_split not in ('places','wta') then raise exception 'pot split must be places or wta'; end if;
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run a Major with it';
  end if;

  -- the chain link: rematch-only, your own history only, majors to majors
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind = 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back a Major you were part of';
    end if;
    v_root := lineage_root(p_lineage);
  end if;

  -- tz: league's active season > creator's device (validated) > Phoenix
  if p_league is not null then
    select timezone into v_tz from seasons
     where league_id = p_league order by number desc limit 1;
  end if;
  if v_tz is null and p_tz is not null then
    begin perform now() at time zone p_tz; v_tz := p_tz;
    exception when others then v_tz := null; end;
  end if;
  v_tz := coalesce(v_tz, 'America/Phoenix');

  v_open := p_final_on - v_days + 1;

  insert into events (name, created_by, league_id, kind, starts_on,
                      session_count, session_weeks, draw_rule, tz,
                      buy_in, pot_split, lineage_id)
  values (v_name, auth.uid(), p_league, 'major', v_open,
          1, 1, 'team_pvi', v_tz, v_buy, v_split, v_root)
  returning id into v_event;

  insert into event_sessions (event_id, session_no, opens_on, closes_on)
  values (v_event, 1, v_open, p_final_on);

  -- the organizer enters the field like anyone (role-blind)
  insert into event_players (event_id, profile_id, role, seed, exhibition)
  values (v_event, auth.uid(), 'player', 0, not major_contender(auth.uid()));

  -- the annual voice: count the chain, name the defender (D61)
  if v_root is not null then
    select count(*) into v_nth from events e
     where e.id = v_root or e.lineage_id = v_root;   -- includes the new one
    select pr.display_name into v_def
      from events e
      join event_major_cards c on c.event_id = e.id and c.rank = 1
      join event_players ep on ep.id = c.player_id
      join profiles pr on pr.id = ep.profile_id
     where (e.id = v_root or e.lineage_id = v_root)
       and e.status = 'complete' and e.id <> v_event
     order by e.starts_on desc limit 1;
    v_annual := 'The ' || lower(nth_up(v_nth)) || ' annual. '
      || coalesce(v_def || ' defends. ', '');
  end if;

  perform major_post(v_event,
    v_annual
    || (select display_name from profiles where id = auth.uid())
    || ' sets ' || v_name || ' — '
    || to_char(v_open, 'Dy Mon DD') || ' → ' || to_char(p_final_on, 'Dy Mon DD')
    || '. Best card takes the jug.'
    || case when v_buy > 0 then ' Buy-in ' || mj_money(v_buy) || '.' else ' Bragging rights.' end);

  return v_event;
end $function$;

-- ---- enter_cup_final ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.enter_cup_final(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; cap_n integer; cf_start date;
  r1 record; r2 record; r3 record; rung1 text; rung2 text; v_post text;
begin
  select * into se from seasons where id = p_season;
  if se.status <> 'active' then return; end if;                 -- idempotent
  if current_date < se.ends_on - 27 then return; end if;        -- window not open

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  cap_n    := coalesce(st.counting_cap, 10000);
  cf_start := se.ends_on - 27;

  -- the contenders: (cid, member, regular-season points from the standings view —
  -- the ledger included, exactly what the table shows the day the seeds lock)
  drop table if exists _sc; drop table if exists _seed;
  create temp table _sc (cid uuid, member_id uuid, score numeric) on commit drop;
  if st.structure = 'solo' then
    insert into _sc
    select i.member_id, i.member_id, coalesce(i.points, 0)
      from v_individual_standings i where i.season_id = p_season;
  else
    insert into _sc
    select vs.squad_id, sm.member_id, coalesce(vs.points, 0)
      from v_squad_standings vs
      left join squad_members sm on sm.squad_id = vs.squad_id
     where vs.season_id = p_season;
  end if;

  -- the §14.3 ladder over the regular season (rounds before the window)
  create temp table _seed (
    cid uuid, score numeric, months_won integer, best_month numeric,
    rounds_used integer, coin double precision, rk integer
  ) on commit drop;
  insert into _seed (cid, score, months_won, best_month, rounds_used, coin)
  with months as (
    select c.cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points) as mpts
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by 1, 2
  ),
  months_won as (
    select m.cid, count(*) as won from months m
     where m.mpts > coalesce((select max(m2.mpts) from months m2
                               where m2.mon = m.mon and m2.cid <> m.cid), -1)
     group by m.cid
  ),
  best_month as (select cid, max(mpts) as best from months group by cid),
  rounds_used as (
    select c.cid, count(rr.*) as used
      from _sc c
      join v_rounds_ranked rr
        on rr.season_id = p_season and rr.member_id = c.member_id
       and rr.month_rank <= cap_n and rr.played_on < cf_start
     group by c.cid
  )
  select c.cid, max(c.score), coalesce(max(w.won), 0), coalesce(max(b.best), 0),
         coalesce(max(u.used), 0), random()
    from _sc c
    left join months_won  w on w.cid = c.cid
    left join best_month  b on b.cid = c.cid
    left join rounds_used u on u.cid = c.cid
   group by c.cid;
  update _seed s set rk = x.rk
    from (select cid, row_number() over (
            order by score desc, months_won desc, best_month desc, rounds_used asc, coin desc) as rk
            from _seed) x
   where x.cid = s.cid;

  select * into r1 from _seed where rk = 1;
  select * into r2 from _seed where rk = 2;
  select * into r3 from _seed where rk = 3;

  -- the rung that separated a seed from the row below it (null = points did)
  if r2.cid is not null and r1.score = r2.score then
    rung1 := case when r1.months_won <> r2.months_won then 'months won'
                  when r1.best_month <> r2.best_month then 'best single month'
                  when r1.rounds_used <> r2.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;
  if r3.cid is not null and r2.cid is not null and r2.score = r3.score then
    rung2 := case when r2.months_won <> r3.months_won then 'months won'
                  when r2.best_month <> r3.best_month then 'best single month'
                  when r2.rounds_used <> r3.rounds_used then 'fewest rounds used'
                  else 'coin flip' end;
  end if;

  if r1.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r1.cid, 1, rung1);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r1.cid, 1, case when st.structure = 'squads2' then 10 else 0 end, rung1);
    end if;
  end if;
  if r2.cid is not null then
    if st.structure = 'solo' then
      insert into cup_finalists (season_id, member_id, seed, seed_rung)
      values (p_season, r2.cid, 2, rung2);
    else
      insert into cup_finalists (season_id, squad_id, seed, head_start, seed_rung)
      values (p_season, r2.cid, 2, 0, rung2);
    end if;
  end if;

  update seasons set status = 'cup_final' where id = p_season;

  v_post := 'The Cup Final is live. Fresh slate, four weeks, seeds locked.'
    || coalesce(' #1 by ' || rung1 || '.', '')
    || coalesce(' #2 by ' || rung2 || '.', '');
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system', v_post);
end $function$;

-- ---- enter_major -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enter_major(p_event uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v record; v_id uuid; v_seed integer; v_exh boolean; v_n integer;
begin
  select e.id, e.kind, e.status, e.league_id into v from events e where e.id = p_event;
  if v.id is null or v.kind <> 'major' then raise exception 'No such Major'; end if;
  if v.status = 'complete' then raise exception 'That one is settled — catch the next Major'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'The horn has sounded — catch the next Major';
  end if;
  if v.league_id is null or not is_league_member(v.league_id) then
    raise exception 'Entry is by invite — ask the organizer';
  end if;

  v_exh := not major_contender(auth.uid());
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed, exhibition)
    values (p_event, auth.uid(), v_seed, v_exh)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  if v_id is not null then
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event,
      (select display_name from profiles where id = auth.uid())
      || ' is in. Field of ' || v_n || '.'
      || case when v_exh then ' Exhibition for now — official by the next one.' else '' end);
  end if;
  return v_id;
end $function$;

-- ---- finish_live_round -------------------------------------------------
CREATE OR REPLACE FUNCTION public.finish_live_round(p_live_round uuid, p_cards jsonb, p_casual boolean DEFAULT false, p_result jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
  v_stake numeric; v_story text;
  v_tz text; v_today date;
begin
  if v is null then raise exception 'Sign in first'; end if;
  -- D85: multi-phone finish — take the row lock so two finishers serialize;
  -- the second sees status='final' below and returns already_final.
  select * into lr from live_rounds where id = p_live_round for update;
  if lr.id is null then raise exception 'No such round'; end if;

  -- D107: the starter is known by profile now (started_by may be null on a
  -- league-less round). Member players may still finish; visitors may not.
  if lr.starter_profile_id is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  -- the league's own calendar day, not the server's UTC one. With no season
  -- (league-less round) the select finds no row and the coalesce falls back
  -- to America/Phoenix (CLAUDE.md default).
  select timezone into v_tz from seasons where id = lr.season_id;
  v_today := (now() at time zone coalesce(nullif(v_tz, ''), 'America/Phoenix'))::date;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_card->'strokes','[]'::jsonb)) x);
    v_n := coalesce(array_length(v_strokes, 1), 0);
    v_holes := null;
    if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then
      v_holes := 18;
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
          and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then
      v_holes := 9;
    end if;

    if v_pl.member_id is null then
      update live_round_players
         set guest_strokes = coalesce(v_card->'strokes', '[]'::jsonb),
             guest_gross = case when v_holes is not null
               then (select sum(s)::int from unnest(v_strokes[1:v_holes]) s) end
       where id = v_pl.id;
      -- D107 (closes the D88 gap): a seated visitor is an app golfer — their
      -- COMPLETE, rated, non-casual card posts to THEIR profile right now,
      -- and the seat is stamped claimed so claim_round can never double-post.
      -- Anything less falls back to the claim-link path exactly as before.
      if v_pl.guest_profile_id is not null and v_pl.claimed_profile is null
         and not p_casual and v_holes is not null
         and v_rating is not null and v_slope is not null
         and not (v_holes = 9 and v_nine is null) then
        v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);
        insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                            played_on, holes_played, gross, rating, slope, nine_rating,
                            source, attested, index_source_at_post, api_course_id, posted_by)
        values (v_pl.guest_profile_id, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
                v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
                'live',
                -- D125 · attested means a playing partner vouched, and the only
                -- evidence of that is this golfer's OWN device having been in
                -- the session. The finisher's card is attested by construction.
                (v_pl.guest_profile_id = v or v_pl.joined_at is not null),
                'app', lr.api_course_id, v)
        returning id into v_round;
        for h in 1..v_holes loop
          if v_strokes[h] is not null then
            insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
          end if;
        end loop;
        update live_round_players set claimed_profile = v_pl.guest_profile_id where id = v_pl.id;
        v_posted := v_posted || jsonb_build_object(
          'name', coalesce(playerlabel(v_pl.guest_profile_id), v_pl.guest_name),
          'gross', v_gross, 'holes', v_holes);
      else
        v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
      end if;
      continue;
    end if;

    select profile_id into v_pid from league_members where id = v_pl.member_id;

    if p_casual then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'casual'); continue;
    end if;
    if v_holes is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'incomplete card'); continue;
    end if;
    if v_rating is null or v_slope is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no course rating'); continue;
    end if;
    if v_holes = 9 and v_nine is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no 9-hole rating'); continue;
    end if;

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post, api_course_id, posted_by)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            v_today, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live',
            -- D125 · same rule for a member's card. This is the exact shape the
            -- audit caught: one phone seating three members and posting three
            -- rounds all stamped attested, with no way for those golfers to
            -- see it happened.
            (v_pid = v or v_pl.joined_at is not null),
            'app', lr.api_course_id, v)
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  if not p_casual and p_result is not null then
    if (p_result->>'game') = 'match' then
      update live_rounds set game_result = p_result where id = p_live_round;
      -- D107: no league → no board (posts.league_id is NOT NULL); the share
      -- card is the story, and each golfer's own round fans via round_to_board.
      if lr.league_id is not null then
        v_stake := coalesce(nullif(p_result->>'stake','')::numeric, 0);
        -- D75: a match VARIANT composes its own story client-side (round robin
        -- carries no winner/status, so the copy below would call it 'side A').
        if nullif(trim(coalesce(p_result->>'story','')), '') is not null then
          v_story := left(p_result->>'story', 200);
        elsif (p_result->>'winner') is null then
          v_story := 'Match play: ' || coalesce(p_result->>'side_a','side A')
                  || ' and ' || coalesce(p_result->>'side_b','side B')
                  || ' halved the match' || case when v_stake > 0 then ' — no money moves' else '' end;
        else
          v_story := coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'The winners')
                  || ' beat '
                  || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
                  || case when coalesce(p_result->>'status','') <> '' then ' ' || lower(p_result->>'status') else '' end
                  || case when v_stake > 0 then '. That''s $' || v_stake || '.' else '.' end;
        end if;
        -- D92: the row now knows which round it settled
        insert into posts (league_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id, 'system', my_member_id(lr.league_id), v_story, p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then
      update live_rounds set game_result = p_result where id = p_live_round;
      if lr.league_id is not null
         and nullif(trim(coalesce(p_result->>'story','')), '') is not null then
        insert into posts (league_id, kind, member_id, body, live_round_id, push_title)
        values (lr.league_id, 'system', my_member_id(lr.league_id),
                left(p_result->>'story', 200), p_live_round,
                nullif(left(trim(coalesce(p_result->>'share','')), 80), ''));
      end if;
    end if;
  end if;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $function$;

-- ---- join_league -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.join_league(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_new uuid; v_name text;
begin
  select id into v_league from leagues where upper(code) = upper(p_code);
  if not found then raise exception 'invalid league code'; end if;
  -- D161 · the code is for assembling the league, not an evergreen entrance
  perform _join_gate(v_league, false);
  insert into league_members (league_id, profile_id)
    values (v_league, auth.uid())
    on conflict (league_id, profile_id) do nothing
    returning id into v_new;
  -- only announce on a genuine join, not a re-tap of a league you're already in
  if v_new is not null then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' joined the league.');
  end if;
  return v_league;
end $function$;

-- ---- major_final_day ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.major_final_day(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; l record; c record; v_line text;
begin
  select es.event_id, e.name into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major' and es.status = 'open';
  if s.event_id is null then return; end if;

  select * into l from major_board(s.event_id)
   where not exhibition and pvi is not null
   order by pvi desc, best_posted_at asc limit 1;

  if l.player_id is null then
    v_line := 'Final day at ' || s.name || '. No cards yet — the jug is there for the taking.';
  else
    select * into c from major_board(s.event_id)
     where not exhibition and pvi is not null and player_id <> l.player_id
     order by pvi desc, best_posted_at asc limit 1;
    v_line := 'Final day at ' || s.name || '. '
      || l.display_name || ' leads at ' || lower(mj_vs(l.pvi))
      || coalesce('. ' || c.display_name || ' '
           || rtrim(rtrim(round(l.pvi - c.pvi, 1)::text,'0'),'.') || ' back.', '.');
  end if;
  perform major_post(s.event_id, v_line);
end $function$;

-- ---- make_pick ---------------------------------------------------------
CREATE OR REPLACE FUNCTION public.make_pick(p_draft uuid, p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
         s.name || ' take ' || firstname(p.display_name)
         || ' with pick ' || (d.current_pick + 1) || '.'
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
    values (se.league_id, d.season_id, 'system', 'Rosters locked. The season is live. Post a round.');
  end if;
end $function$;

-- ---- mark_buy_in -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid;
  v_status text;
  v_stake  integer;
  v_name   text;
  v_paid_n integer;
  v_total  integer;
  v_money  jsonb;
begin
  select league_id, status into v_league, v_status from seasons where id = p_season;
  if v_league is null then raise exception 'No such season'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro marks buy-ins'; end if;
  if not exists (select 1 from league_members where id = p_member and league_id = v_league) then
    raise exception 'Not a member of this league';
  end if;

  select coalesce(buyin_cents, 0) into v_stake from league_settings where league_id = v_league;

  insert into buy_ins (season_id, member_id, amount_cents, paid, marked_by, marked_at)
  values (p_season, p_member, coalesce(v_stake, 0), p_paid, my_member_id(v_league), now())
  on conflict (season_id, member_id) do update
    set paid = excluded.paid,
        marked_by = excluded.marked_by,
        marked_at = excluded.marked_at;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  if v_status = 'complete' then
    -- D106 §4: the ledger is rewritten from the new collected total and the
    -- room is told — the ceremony re-renders from season_payouts
    v_money := recompute_season_payouts(p_season);
    if p_paid and coalesce((v_money->>'collected_cents')::bigint, 0) > 0 then
      insert into posts (league_id, season_id, kind, member_id, body)
      values (v_league, p_season, 'system', my_member_id(v_league),
              v_name || '''s buy-in came in after the final. Payouts updated: champs $'
              || round((v_money->>'champ_cents')::numeric / 100.0)
              || ' · runner-up $'   || round((v_money->>'runner_cents')::numeric / 100.0)
              || ' · points king $' || round((v_money->>'king_cents')::numeric / 100.0));
    end if;
    return;
  end if;

  if p_paid then
    select count(*) filter (where b.paid) into v_paid_n
      from buy_ins b where b.season_id = p_season;
    select count(*) into v_total from league_members where league_id = v_league;

    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, p_season, 'system', my_member_id(v_league),
            v_name || '''s buy-in is in — ' || v_paid_n || '/' || v_total || ' collected.');
  end if;
end $function$;

-- ---- open_major --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.open_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; v_today date; v_n integer; v_days integer;
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.buy_in, e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if auth.uid() is not null and not is_event_organizer(s.event_id) then
    raise exception 'organizer only';
  end if;
  if s.status <> 'upcoming' then return; end if;
  v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
  if s.opens_on > v_today then
    raise exception 'The window opens %', to_char(s.opens_on, 'Dy Mon DD');
  end if;
  select count(*) into v_n from event_players where event_id = s.event_id;
  if v_n < 2 then raise exception 'A Major needs a field — 2 at least'; end if;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = s.event_id and status = 'setup';

  v_days := s.closes_on - s.opens_on + 1;
  perform major_post(s.event_id,
    s.name || ' is live. ' || v_days || ' days, field of ' || v_n
    || '. Best card by ' || to_char(s.closes_on, 'FMDay') || ' night takes the jug.');
end $function$;

-- ---- open_week_clash ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.open_week_clash(p_season uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se       record;
  v_local  date;
  v_wk     integer;
  v_total  integer;
  v_a      uuid;   -- league_members.id
  v_b      uuid;
  v_id     uuid;
  v_a_name text;
  v_b_name text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;
  if v_local < se.starts_on or v_local > se.ends_on then
    return null;                                   -- no clash outside the season
  end if;

  v_total := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  v_wk    := floor((v_local - se.starts_on) / 7)::int + 1;
  if v_wk < 1 or v_wk > v_total then
    return null;
  end if;

  -- idempotent: this week's clash already stands
  select id into v_id from week_clashes
   where season_id = p_season and week_no = v_wk;
  if v_id is not null then
    return v_id;
  end if;

  -- the pairing (see header for the cascade + rotation-guarantee reasoning)
  with mem as (            -- active members: on the roster, not tombstoned
    select lm.id, lm.profile_id, p.display_name
      from league_members lm
      join profiles p on p.id = lm.profile_id and p.deleted_at is null
     where lm.league_id = se.league_id
  ),
  feat as (                -- each member's most recent spotlight week
    select m.id, max(wc.week_no) as last_wk
      from mem m
      join week_clashes wc
        on wc.season_id = p_season
       and (wc.a_member = m.id or wc.b_member = m.id)
     group by m.id
  ),
  stand as (
    select member_id, points from v_individual_standings
     where season_id = p_season
  ),
  pairs as (
    select a.id as a_id, b.id as b_id,
           a.display_name as a_name, b.display_name as b_name,
           greatest(coalesce(fa.last_wk, 0), coalesce(fb.last_wk, 0)) as staleness,
           exists (select 1 from rivalry_names rn
                    where rn.pair_low  = least(a.profile_id, b.profile_id)
                      and rn.pair_high = greatest(a.profile_id, b.profile_id)) as named,
           abs(coalesce(sa.points, 0) - coalesce(sb.points, 0)) as gap
      from mem a
      join mem b on a.id < b.id
      left join feat  fa on fa.id = a.id
      left join feat  fb on fb.id = b.id
      left join stand sa on sa.member_id = a.id
      left join stand sb on sb.member_id = b.id
  )
  select a_id, b_id, a_name, b_name
    into v_a, v_b, v_a_name, v_b_name
    from pairs
   order by staleness asc,        -- rotation guarantee: the most-due pair first
            named desc,           -- then D52's cascade: named rivalry (D21)
            gap asc,              -- → closest table gap
            a_id, b_id            -- → deterministic
   limit 1;

  if v_a is null or v_b is null then
    return null;                                   -- solo league (<2 active) — skip
  end if;

  insert into week_clashes (season_id, week_no, a_member, b_member)
  values (p_season, v_wk, v_a, v_b)
  on conflict (season_id, week_no) do nothing
  returning id into v_id;

  if v_id is null then                             -- lost a race — take the standing row
    select id into v_id from week_clashes
     where season_id = p_season and week_no = v_wk;
    return v_id;
  end if;

  -- the open story (only when this call actually opened the week)
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'The clash this week: ' || firstname(v_a_name) || ' v '
                                 || firstname(v_b_name) || '.');

  return v_id;
end $function$;

-- ---- randomize_squads --------------------------------------------------
CREATE OR REPLACE FUNCTION public.randomize_squads(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; m record;
  sq_n int; total int; pool_n int;
  reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if coalesce(st.draft_type, 'random') <> 'random' then
    raise exception 'This league seats its squads by Pro assign — tap players into squads instead of drawing.';
  end if;

  select count(*) into sq_n from squads where season_id = p_season;
  if sq_n = 0 then raise exception 'no squads — run form_squads first'; end if;

  select count(*) into total from league_members lm where lm.league_id = se.league_id;
  if total < sq_n then
    raise exception 'Not enough golfers to cover every squad — % in, % squads. Share the invite link first.', total, sq_n;
  end if;

  select count(*) into pool_n from league_members lm
  where lm.league_id = se.league_id
    and not exists (select 1 from squad_members x
                    join squads q on q.id = x.squad_id and q.season_id = p_season
                    where x.member_id = lm.id);
  if pool_n = 0 then return; end if;   /* nothing to deal — no story, no captain churn */

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    /* the hat deals to the smallest squad — draws AND redraws stay balanced */
    insert into squad_members (squad_id, member_id)
    select q.id, m.id
    from squads q
    left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id
    order by count(sm.member_id) asc, random()
    limit 1;
  end loop;

  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(q.name||' — '||cnt||' golfer'||case when cnt=1 then '' else 's' end, ' · ')
    into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'The squads are drawn. The hat has spoken. '||coalesce(reveal,''));
end $function$;

-- ---- remove_member -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.remove_member(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid; v_name text;
begin
  select league_id into v_league from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro removes members'; end if;
  if p_member = my_member_id(v_league) then raise exception 'Transfer the Pro role before leaving'; end if;
  if (select phase from leagues where id = v_league) <> 'setup' then
    raise exception 'Members can only be removed during setup — mid-season tools are coming';
  end if;

  select coalesce(p.display_name, 'A member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  update posts set member_id = null where member_id = p_member;
  delete from squad_members where member_id = p_member;
  delete from buy_ins where member_id = p_member;
  delete from league_members where id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, my_member_id(v_league), 'remove_member',
          jsonb_build_object('member', p_member, 'name', v_name));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          v_name || ' left the league.');
end $function$;

-- ---- respond_invite ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.respond_invite(p_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare mi member_invites%rowtype; v_idx numeric; v_name text; v_new uuid; v_squad text;
begin
  select * into mi from member_invites where id = p_id and profile_id = auth.uid();
  if not found then raise exception 'invite not found'; end if;
  if mi.status <> 'pending' then return; end if;

  if p_accept then
    -- D161 · staged by the Pro, so it follows the Pro's window. A decline is
    -- never gated: saying no must always work.
    if mi.league_id is not null then
      perform _join_gate(mi.league_id, true);
    end if;
    select display_name, index_current into v_name, v_idx from profiles where id = auth.uid();
    if mi.league_id is not null then
      insert into league_members (league_id, profile_id, role, index_current)
        values (mi.league_id, auth.uid(), 'player', coalesce(v_idx, 18.0))
        on conflict (league_id, profile_id) do nothing
        returning id into v_new;
      -- D95: only a genuine join is news. Accepting an invite for a league you
      -- already code-joined must not announce you a second time.
      if v_new is not null then
        v_squad := _late_squad(mi.league_id, v_new);
        insert into posts (league_id, kind, body)
          values (mi.league_id, 'system',
                  coalesce(v_name,'A golfer') || ' joined the league.'
                  || case when v_squad is not null
                          then ' The thinnest squad takes them: ' || v_squad || '.'
                          else '' end);
      end if;
    else
      insert into event_players (event_id, profile_id, seed)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0))
        on conflict (event_id, profile_id) do nothing;
    end if;
    update member_invites set status='accepted' where id = p_id;
  else
    update member_invites set status='declined' where id = p_id;
  end if;
end $function$;

-- ---- round_major_story -------------------------------------------------
CREATE OR REPLACE FUNCTION public.round_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; v_pvi numeric; v_prior numeric; v_lead numeric; v_name text; v_line text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim' or new.holes_played <> 18
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for m in
    select e.id as ev, e.allowance, s.opens_on, s.closes_on,
           ep.id as player_id, ep.exhibition
      from events e
      join event_sessions s on s.event_id = e.id and s.status = 'open'
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status = 'live'
       and new.played_on between s.opens_on and s.closes_on
  loop
    v_pvi := round((new.index_at_post * m.allowance / 100.0) - new.differential, 1);
    select max(round((r.index_at_post * m.allowance / 100.0) - r.differential, 1))
      into v_prior
      from rounds r
     where r.profile_id = new.profile_id and r.id <> new.id
       and r.played_on between m.opens_on and m.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;
    if v_prior is not null and v_pvi <= v_prior then continue; end if;

    select max(pvi) into v_lead from major_board(m.ev)
     where not exhibition and pvi is not null and player_id <> m.player_id;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer')
      || case when v_prior is null then ' opens with ' else ' improves to ' end
      || new.gross || ' — ' || lower(mj_vs(v_pvi));
    if m.exhibition then
      v_line := v_line || '. Exhibition.';
    elsif v_lead is null or v_pvi > v_lead then
      v_line := v_line || '. Clubhouse lead.';
    elsif v_pvi = v_lead then
      v_line := v_line || '. Ties the lead.';
    else
      v_line := v_line || '. The lead is ' || lower(mj_vs(v_lead)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$;

-- ---- round_moments -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.round_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v            uuid := new.profile_id;
  v_name       text;
  v_prior_best numeric;
  v_barrier    int  := null;
  v_streak     int  := 0;
  v_first_week boolean := false;
  v_is_first   boolean := false;
  v_thr        int;
  v_moment     text := null;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  select firstname(coalesce(display_name, 'A golfer')) into v_name
    from profiles where id = v;

  -- 1) career barrier (18-hole gross): lowest threshold crossed for the headline
  if new.holes_played = 18 and new.gross is not null then
    if new.gross < 80 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 80
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 80;
    elsif new.gross < 90 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 90
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 90;
    elsif new.gross < 100 and not exists (
      select 1 from rounds where profile_id = v and id <> new.id
        and not voided and holes_played = 18 and gross < 100
        and coalesce(source,'app') <> 'sim') then
      v_barrier := 100;
    end if;
  end if;

  -- 2) personal-best differential (vs every prior round)
  select min(differential) into v_prior_best
    from rounds where profile_id = v and id <> new.id
      and not voided and differential is not null
      and coalesce(source,'app') <> 'sim';

  -- 3) iron-man streak — only when this is the first post of its week
  select count(*) = 0 into v_first_week
    from rounds where profile_id = v and id <> new.id and not voided
      and date_trunc('week', played_on) = date_trunc('week', new.played_on);
  if v_first_week then
    with wks as (
      select distinct date_trunc('week', played_on)::date w
        from rounds
       where profile_id = v and not voided and played_on <= new.played_on
    ), grp as (
      select w, w - (row_number() over (order by w) * interval '7 day') as g
        from wks
    )
    select count(*) into v_streak
      from grp
     where g = (select g from grp order by w desc limit 1);
  end if;

  -- ---- persistent achievements (same detection, permanent home) ----
  v_is_first := not exists (
    select 1 from rounds where profile_id = v and id <> new.id
      and not voided and coalesce(source,'app') <> 'sim');
  if v_is_first then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'first_round', 'First round posted', new.played_on, new.id,
            jsonb_build_object('gross', new.gross))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- barriers for the case: award EVERY threshold newly crossed (not just the headline)
  if new.holes_played = 18 and new.gross is not null then
    foreach v_thr in array array[100, 90, 80] loop
      if new.gross < v_thr and not exists (
        select 1 from rounds where profile_id = v and id <> new.id
          and not voided and holes_played = 18 and gross < v_thr
          and coalesce(source,'app') <> 'sim') then
        insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
        values (v, 'sub_' || v_thr, 'Broke ' || v_thr, new.played_on, new.id,
                jsonb_build_object('gross', new.gross))
        on conflict (profile_id, kind) do nothing;
      end if;
    end loop;
  end if;

  if v_prior_best is not null and new.differential < v_prior_best then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'personal_best', 'Personal best', new.played_on, new.id,
            jsonb_build_object('diff', new.differential))
    on conflict (profile_id, kind) do update
      set earned_on = excluded.earned_on, round_id = excluded.round_id, meta = excluded.meta;
  end if;

  if v_first_week and v_streak in (4, 8, 12) then
    insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
    values (v, 'streak_' || v_streak, v_streak || '-week streak', new.played_on, new.id,
            jsonb_build_object('weeks', v_streak))
    on conflict (profile_id, kind) do nothing;
  end if;

  -- ---- one ephemeral headline (barrier > PB > streak) ----
  if v_barrier is not null then
    v_moment := v_name || ' broke ' || v_barrier
             || ' for the first time — '
             || case when new.gross between 80 and 89 then 'an ' else 'a ' end
             || new.gross || '. That one goes on the wall.';
  elsif v_prior_best is not null and new.differential < v_prior_best then
    v_moment := v_name || ' set a personal best. New number to chase.';
  elsif v_first_week and v_streak >= 4 and v_streak % 4 = 0 then
    v_moment := v_name || ' has posted ' || v_streak
             || ' weeks running. The streak holds.';
  end if;

  if v_moment is null then return new; end if;

  -- round_id rides the post: delete the round, the headline goes with it
  insert into posts (league_id, season_id, kind, round_id, member_id, body)
  select lm.league_id, s.id, 'moment', new.id, lm.id, v_moment
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final')
                  and new.played_on between s.starts_on and s.ends_on
   where lm.profile_id = v;

  return new;
end $function$;

-- ---- round_refresh_index -----------------------------------------------
CREATE OR REPLACE FUNCTION public.round_refresh_index()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_auto numeric; v_old numeric; v_src text; v_name text;
begin
  if new.voided then return new; end if;
  v_auto := handicap_index(new.profile_id);          -- non-null once >= 3 rounds
  if v_auto is null then return new; end if;

  select index_current, index_source, display_name
    into v_old, v_src, v_name from profiles where id = new.profile_id;

  update profiles set index_current = v_auto, index_source = 'app'
   where id = new.profile_id;                          -- scores are the truth

  -- announce ONLY the handoff: scores taking over a manual starter, and only
  -- when the number actually moves. Routine per-round updates stay silent.
  if coalesce(v_src, 'app') in ('self', 'ghin') and v_old is distinct from v_auto then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           coalesce(v_name, 'A golfer') || '''s number now comes from their scores — '
             || coalesce(v_old::text, 'starter') || ' → ' || v_auto
      from league_members lm where lm.profile_id = new.profile_id;
  end if;
  return new;
end $function$;

-- ---- sched_major_story -------------------------------------------------
CREATE OR REPLACE FUNCTION public.sched_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; l record; v_name text; v_line text;
begin
  for m in
    select e.id as ev, ep.id as player_id
      from events e
      join event_sessions s on s.event_id = e.id and s.status in ('upcoming','open')
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status in ('setup','live')
       and new.play_on between s.opens_on and s.closes_on
  loop
    select * into l from major_board(m.ev)
     where not exhibition and pvi is not null
     order by pvi desc, best_posted_at asc limit 1;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer') || ' is down for ' || to_char(new.play_on,'FMDay')
      || coalesce(' at ' || new.course_label, '');
    if l.player_id is null then
      v_line := v_line || '. First card takes the clubhouse.';
    elsif l.player_id = m.player_id then
      v_line := v_line || '. Defending the lead at ' || lower(mj_vs(l.pvi)) || '.';
    else
      v_line := v_line || '. Chasing ' || lower(mj_vs(l.pvi)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$;

-- ---- scrap_forfeit -----------------------------------------------------
CREATE OR REPLACE FUNCTION public.scrap_forfeit(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record;
begin
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then raise exception 'Settled stakes stand — the archive keeps them'; end if;
  if auth.uid() <> f.created_by and not is_commissioner(f.league_id) then
    raise exception 'Only the poster (or the Pro) scraps a stake';
  end if;
  update forfeits set status = 'scrapped', settled_at = now(), settled_by = auth.uid()
   where id = p_id;
  insert into posts (league_id, kind, body)
  values (f.league_id, 'system', 'Stake scrapped: ' || f.name);
end $function$;

-- ---- set_handle --------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_handle(p_handle text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v      text := lower(trim(both from replace(p_handle, '@', '')));
  v_old  text; v_set timestamptz; v_name text;
  v_held uuid;
begin
  -- D159 · a signed-out caller must not reach the guards below, because every
  -- one of them compares against auth.uid() and a NULL comparison is NULL, not
  -- true — the reservation check would silently pass. Caught by a behavioural
  -- test where the probe account resolved to null.
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if v !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'Handles are 3–20 characters: letters, numbers, underscores';
  end if;
  if v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then
    raise exception 'That handle is reserved';
  end if;

  select handle, handle_set_at, display_name into v_old, v_set, v_name
    from profiles where id = auth.uid();
  if v_old is not distinct from v then return; end if;   -- no actual change

  -- D159 · a name someone else gave up is not available. Checked BEFORE the
  -- cooldown so a golfer is told the real reason rather than being made to wait
  -- sixty days for a handle they were never going to get.
  select profile_id into v_held from handle_history where handle = v;
  if v_held is not null and v_held is distinct from auth.uid() then
    raise exception 'That handle belonged to another golfer';
  end if;

  -- cooldown applies only to a genuine change of an existing handle
  if v_old is not null and v_set is not null and v_set > now() - interval '60 days' then
    raise exception 'Your @handle can change once every 60 days — next change on %',
      to_char(v_set + interval '60 days', 'Mon DD');
  end if;

  begin
    update profiles set handle = v, handle_set_at = now() where id = auth.uid();
  exception when unique_violation then
    raise exception 'That handle is taken';
  end;

  -- D159 · the name being left behind is held, and a name being RECLAIMED stops
  -- being held. Both in the same breath as the change itself.
  if v_old is not null then
    insert into handle_history (handle, profile_id) values (v_old, auth.uid())
    on conflict (handle) do update set profile_id = excluded.profile_id,
                                       released_at = excluded.released_at;
  end if;
  delete from handle_history where handle = v and profile_id = auth.uid();

  -- announce a re-handle (first claim stays silent)
  if v_old is not null then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           coalesce(v_name, 'A member') || ' is now @' || v
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $function$;

-- ---- set_league_finish -------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_league_finish(p_league uuid, p_finish text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record;
begin
  if p_finish not in ('points_table','cup_final') then raise exception 'finish must be points_table or cup_final'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro sets the finish'; end if;
  select * into se from seasons where league_id = p_league and status in ('active','cup_final')
   order by number desc limit 1;
  -- once the Final window is open (or entered) the finish is settled — no
  -- retroactive rewrites of a live endgame (spec principle 4: argue never)
  if se.id is not null and (se.status = 'cup_final' or current_date >= se.ends_on - 27) then
    raise exception 'The finish is locked once the final window opens';
  end if;

  update league_settings set finish = p_finish where league_id = p_league;
  insert into posts (league_id, kind, member_id, body)
  values (p_league, 'system', my_member_id(p_league),
          case when p_finish = 'cup_final'
            then 'The Pro set the finish: the Cup Final. Final four weeks, scored fresh, top seeds only.'
            else 'The Pro set the finish: the points table. It crowns the champion outright — no Cup Final.' end);
end $function$;

-- ---- set_member_bye ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_member_bye(p_member uuid, p_month date, p_on boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_season uuid; v_league uuid; v_sqid uuid; v_name text; v_mon date;
begin
  v_mon := date_trunc('month', p_month)::date;
  -- resolve the member's active season + squad
  select s.id, s.league_id into v_season, v_league
    from seasons s
    join squads sq on sq.season_id = s.id
    join squad_members sm on sm.squad_id = sq.id
   where sm.member_id = p_member and s.status in ('active','cup_final')
   order by s.number desc limit 1;
  if v_season is null then raise exception 'No active season for that member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro grants a bye'; end if;
  select sq.id into v_sqid from squads sq
    join squad_members sm on sm.squad_id = sq.id
   where sm.member_id = p_member and sq.season_id = v_season limit 1;
  select display_name into v_name from profiles p
    join league_members lm on lm.profile_id = p.id where lm.id = p_member;

  if p_on then
    -- one bye per season: clear any prior bye first (this becomes THE bye)
    delete from season_adjustments where season_id = v_season and member_id = p_member and kind = 'bye';
    insert into season_adjustments (season_id, squad_id, member_id, month, kind, points, reason)
    values (v_season, v_sqid, p_member, v_mon, 'bye', 0, 'Bye granted by the Pro');
    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, v_season, 'system', my_member_id(v_league),
            'The Pro granted '||coalesce(v_name,'a member')||' a bye for '||to_char(v_mon,'FMMonth')||'.');
  else
    delete from season_adjustments where season_id = v_season and member_id = p_member
      and kind = 'bye' and month = v_mon;
    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, v_season, 'system', my_member_id(v_league),
            'The Pro cleared '||coalesce(v_name,'a member')||'''s '||to_char(v_mon,'FMMonth')||' bye.');
  end if;
end $function$;

-- ---- set_member_index --------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_member_index(p_member uuid, p_index numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_pid uuid; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;
  select league_id, profile_id into v_league, v_pid from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro sets a starter index'; end if;

  -- behavior B: a starter only helps before the engine can compute a number.
  -- Setting one now would post a board line the next round instantly overrides.
  v_auto := handicap_index(v_pid);
  if v_auto is not null then
    raise exception 'Their number comes from their scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select display_name into v_name from profiles where id = v_pid;
  update profiles set index_current = p_index, index_source = 'self' where id = v_pid;

  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          'The Pro set ' || coalesce(v_name, 'a member') || '''s starter index to ' || p_index);
end $function$;

-- ---- set_profile -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_profile(p_name text, p_city text DEFAULT NULL::text, p_home text DEFAULT NULL::text, p_index numeric DEFAULT NULL::numeric, p_marker text DEFAULT NULL::text, p_ghin text DEFAULT NULL::text, p_photo_path text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_old text;
begin
  -- the avatar path is own-prefix by law (mirrors the storage policy)
  if p_photo_path is not null and p_photo_path <> ''
     and p_photo_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'photo path must live under your own prefix';
  end if;

  select display_name into v_old from profiles where id = auth.uid();

  insert into profiles (id, email, display_name, city, home_course, index_current, marker, ghin_number, photo_path)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker,
    nullif(trim(coalesce(p_ghin,'')), ''), nullif(p_photo_path, ''))
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker),
    ghin_number   = case when p_ghin is null then profiles.ghin_number
                         else nullif(trim(p_ghin), '') end,
    photo_path    = case when p_photo_path is null then profiles.photo_path
                         else nullif(p_photo_path, '') end;

  if p_name is not null and v_old is not null and trim(p_name) <> v_old then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           v_old || ' now goes by ' || trim(p_name)
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $function$;

-- ---- settle_forfeit ----------------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_forfeit(p_id uuid, p_winner uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record; v_line text; v_w text;
begin
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then return; end if;   -- idempotent
  if auth.uid() not in (f.party_a, coalesce(f.party_b, f.party_a))
     and not is_commissioner(f.league_id) then
    raise exception 'Only a party (or the Pro) settles a stake';
  end if;
  -- a duel's winner is one of its parties; a bounty pays anyone in the crew
  if f.party_b is not null then
    if p_winner is null or p_winner not in (f.party_a, f.party_b) then
      raise exception 'Name the winner — one of the two parties';
    end if;
  else
    if p_winner is null
       or not exists (select 1 from league_members
                       where league_id = f.league_id and profile_id = p_winner) then
      raise exception 'Name who hit it — someone in the crew';
    end if;
  end if;

  update forfeits
     set status = 'settled', winner = p_winner,
         settled_note = nullif(trim(coalesce(p_note,'')),''),
         settled_at = now(), settled_by = auth.uid()
   where id = p_id;

  select display_name into v_w from profiles where id = p_winner;
  v_line := 'Stake settled: ' || f.name || ' — ' || v_w || ' takes it · ' || f.terms;
  insert into posts (league_id, kind, body) values (f.league_id, 'system', left(v_line,400));
end $function$;

-- ---- settle_major ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s record; p record; t record; f record;
  b_pvi numeric[]; b_rid uuid[]; b_gross integer[]; b_at timestamptz[];
  v_cards integer; v_pot numeric; v_entrants integer;
  v_champ record; v_ru record; v_third record;
  v_share numeric; v_paid numeric := 0; v_places integer;
  v_line text; v_flip text := ''; v_tie text := '';
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.allowance, e.buy_in, e.pot_split, e.league_id,
         e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if s.status = 'closed' then return; end if;          -- idempotent
  if auth.uid() is not null then
    if not is_event_organizer(s.event_id) then raise exception 'organizer only'; end if;
    if s.closes_on >= (now() at time zone coalesce(s.tz,'America/Phoenix'))::date then
      raise exception 'The window runs through % — the horn sounds after', to_char(s.closes_on,'Dy Mon DD');
    end if;
  end if;

  -- freeze every player's card: best + second-best eligible in the window
  for p in select ep.id, ep.profile_id, ep.exhibition
             from event_players ep where ep.event_id = s.event_id
  loop
    select array_agg(x.pvi), array_agg(x.rid), array_agg(x.gross), array_agg(x.at)
      into b_pvi, b_rid, b_gross, b_at
      from (
        select round((r.index_at_post * s.allowance / 100.0) - r.differential, 1) as pvi,
               r.id as rid, r.gross, r.created_at as at
          from rounds r
         where r.profile_id = p.profile_id
           and r.played_on between s.opens_on and s.closes_on
           and not r.voided and coalesce(r.source,'app') <> 'sim'
           and r.holes_played = 18
           and r.index_at_post is not null and r.differential is not null
         order by pvi desc, r.created_at asc, r.id
         limit 2
      ) x;
    select count(*) into v_cards
      from rounds r
     where r.profile_id = p.profile_id
       and r.played_on between s.opens_on and s.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;

    insert into event_major_cards
      (event_id, player_id, round_id, gross, pvi, second_pvi, cards,
       best_posted_at, no_card, exhibition)
    values
      (s.event_id, p.id, b_rid[1], b_gross[1], b_pvi[1], b_pvi[2], v_cards,
       b_at[1], b_pvi[1] is null, p.exhibition)
    on conflict (event_id, player_id) do nothing;
  end loop;

  -- rank the contenders: the countback ladder (D45), coin flip last.
  -- Reset first so a rerun after a mid-settle crash can't strand a stale
  -- rank or prize on a row the fresh ranking no longer pays.
  update event_major_cards set rank = null, prize = 0 where event_id = s.event_id;
  with ranked as (
    select id, pvi, second_pvi, best_posted_at,
           row_number() over (order by pvi desc, second_pvi desc nulls last,
                              best_posted_at asc, random()) as rn
      from event_major_cards
     where event_id = s.event_id and not exhibition and not no_card
  )
  update event_major_cards c set rank = r.rn
    from ranked r where c.id = r.id;

  -- name the rungs that decided anything (receipts on the board)
  for t in
    select a.rank as arank, pa.display_name as aname, pb.display_name as bname,
           (a.second_pvi is not distinct from b.second_pvi
            and a.best_posted_at is not distinct from b.best_posted_at) as flipped
      from event_major_cards a
      join event_major_cards b on b.event_id = a.event_id and b.rank = a.rank + 1
      join event_players epa on epa.id = a.player_id join profiles pa on pa.id = epa.profile_id
      join event_players epb on epb.id = b.player_id join profiles pb on pb.id = epb.profile_id
     where a.event_id = s.event_id and a.pvi = b.pvi and a.rank <= 3
  loop
    if t.flipped then
      v_flip := v_flip || ' Coin flip: ' || t.aname || ' over ' || t.bname || '.';
    elsif t.arank = 1 then
      v_tie := ' On countback.';
    end if;
  end loop;

  -- the pot: contender entrants only (exhibition never buys in, never pays)
  select count(*) into v_entrants
    from event_major_cards where event_id = s.event_id and not exhibition;
  v_pot := s.buy_in * v_entrants;
  select count(*) into v_places
    from event_major_cards where event_id = s.event_id and rank is not null;

  if v_pot > 0 and v_places > 0 then
    if s.pot_split = 'wta' then
      update event_major_cards set prize = v_pot
       where event_id = s.event_id and rank = 1;
    else
      -- 60/25/15; a place the field can't fill rolls up to the champion
      if v_places >= 2 then
        v_share := round(v_pot * 0.25, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 2;
        v_paid := v_paid + v_share;
      end if;
      if v_places >= 3 then
        v_share := round(v_pot * 0.15, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 3;
        v_paid := v_paid + v_share;
      end if;
      update event_major_cards set prize = v_pot - v_paid
       where event_id = s.event_id and rank = 1;
    end if;
  end if;

  update event_sessions set status = 'closed' where id = p_session;

  -- podium reads
  select pr.display_name, c.gross, c.pvi, c.prize into v_champ
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 1;
  select pr.display_name, c.pvi into v_ru
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 2;
  select pr.display_name, c.pvi into v_third
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 3;

  -- completion FIRST (trophy trigger reads the ranked cards), then the story
  update events set status = 'complete' where id = s.event_id;

  if v_champ.display_name is null then
    v_line := s.name || '. '
      || case when exists (select 1 from event_major_cards
                            where event_id = s.event_id and exhibition and not no_card)
              then 'No official cards — the jug stays in the case.'
              else 'No cards posted — the jug stays in the case.' end
      || case when s.buy_in > 0 then ' Buy-ins returned.' else '' end;
  else
    v_line := firstname(v_champ.display_name) || ' takes '
      || case when s.name ~* '^the\s' then '' else 'the ' end || s.name
      || ', ' || lower(mj_vs(v_champ.pvi)) || '.' || v_tie
      || case when v_pot > 0 and s.pot_split = 'wta' then ' And the ' || mj_money(v_pot) || '.'
              when v_pot > 0 then ' ' || mj_money(v_pot) || ' in the pot.'
              else '' end
      || v_flip;
  end if;
  perform major_post(s.event_id, v_line);

  -- the best exhibition run gets its line (never the jug — D44)
  select pr.display_name, c.gross, c.pvi into f
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.exhibition and not c.no_card
   order by c.pvi desc limit 1;
  if f.display_name is not null then
    perform event_post(s.event_id,
      'Exhibition: ' || f.display_name || ' went ' || f.gross || ' (' || lower(mj_vs(f.pvi))
      || '). Official by the next one.');
  end if;
end $function$;

-- ---- settle_week_clash -------------------------------------------------
CREATE OR REPLACE FUNCTION public.settle_week_clash(p_season uuid, p_week integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  wc       record;
  se       record;
  v_cap    integer;
  v_ws     date;                                   -- week window start / end
  v_we     date;
  v_a_best jsonb;
  v_b_best jsonb;
  v_winner uuid;
  v_win_b  jsonb;
  v_name   text;
  v_a_name text;
  v_b_name text;
  v_pvi    numeric;
  v_phrase text;
begin
  select * into wc from week_clashes
   where season_id = p_season and week_no = p_week
   for update;
  if wc.id is null or wc.settled_at is not null then
    return null;                                   -- nothing open here — idempotent
  end if;

  select * into se from seasons where id = p_season;
  select counting_cap into v_cap from league_settings where league_id = se.league_id;
  v_ws := se.starts_on + 7 * (p_week - 1);
  v_we := v_ws + 6;

  -- each side's best band-of-week: highest-points COUNTING round in the window
  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_a_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.a_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  select jsonb_build_object(
           'round_id', rr.round_id, 'played_on', rr.played_on,
           'points', rr.points, 'pvi', rr.pvi,
           'band', case when rr.pvi >= 3  then 'Torched it'
                        when rr.pvi >= 1  then 'Beat your number'
                        when rr.pvi >= -1 then 'Played to it'
                        when rr.pvi >= -3 then 'A little loose'
                        else 'Posted anyway' end)
    into v_b_best
    from v_rounds_ranked rr
   where rr.season_id = p_season and rr.member_id = wc.b_member
     and rr.month_rank <= coalesce(v_cap, 999)
     and rr.played_on between v_ws and v_we
   order by rr.points desc, rr.pvi desc, rr.played_on asc
   limit 1;

  -- the band decides the W; equal bands are ALL SQUARE (D2: named bands, not
  -- raw differential); one side idle is a walkover W; both idle is quiet.
  if v_a_best is null and v_b_best is null then
    v_winner := null;
  elsif v_b_best is null
     or (v_a_best is not null
         and (v_a_best->>'points')::int > (v_b_best->>'points')::int) then
    v_winner := wc.a_member; v_win_b := v_a_best;
  elsif v_a_best is null
     or (v_b_best->>'points')::int > (v_a_best->>'points')::int then
    v_winner := wc.b_member; v_win_b := v_b_best;
  else
    v_winner := null;                              -- both posted, same band
  end if;

  update week_clashes
     set settled_at = now(), winner_member = v_winner,
         a_best = v_a_best, b_best = v_b_best
   where id = wc.id;

  select p.display_name into v_a_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.a_member;
  select p.display_name into v_b_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = wc.b_member;

  if v_winner is not null then
    v_name := case when v_winner = wc.a_member then v_a_name else v_b_name end;
    v_pvi  := (v_win_b->>'pvi')::numeric;
    v_phrase := case
      when v_pvi >= 1  then 'beat their number by ' || to_char(v_pvi, 'FM990.0')
      when v_pvi >= -1 then 'played to their number'
      else to_char(abs(v_pvi), 'FM990.0') || ' over their number' end;
    insert into posts (league_id, season_id, kind, round_id, body)
    values (se.league_id, p_season, 'system', (v_win_b->>'round_id')::uuid,
            firstname(v_name) || ' took the week — ' || v_phrase
            || ' on ' || to_char((v_win_b->>'played_on')::date, 'FMDay') || '.');
  elsif v_a_best is not null or v_b_best is not null then
    insert into posts (league_id, season_id, kind, body)
    values (se.league_id, p_season, 'system',
            'All square in the clash — ' || firstname(v_a_name) || ' v '
                                        || firstname(v_b_name) || '.');
  end if;
  -- both idle: row settled above, no post (D52's honesty rule).

  return jsonb_build_object(
    'week', p_week, 'winner_member', v_winner,
    'a_best', v_a_best, 'b_best', v_b_best);
end $function$;

-- ---- start_draft -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_draft(p_season uuid, p_shuffle boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    'The draft order is set. ' || string_agg(s.name, ' · ' order by array_position(sq, s.id))
  from squads s where s.id = any(sq);

  return d;
end $function$;

-- ---- start_live_round --------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_live_round(p_league uuid DEFAULT NULL::uuid, p_course_id uuid DEFAULT NULL::uuid, p_tee_id uuid DEFAULT NULL::uuid, p_course_label text DEFAULT NULL::text, p_snapshot jsonb DEFAULT NULL::jsonb, p_game text DEFAULT NULL::text, p_players jsonb DEFAULT NULL::jsonb, p_config jsonb DEFAULT '{}'::jsonb, p_api_course_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_member uuid; v_season uuid; v_lr uuid; v_pos int := 0; v_el jsonb;
  v_code text := replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
  v_who text; v_where text; v_title text; v_body text;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_league is not null then
    select id into v_member from league_members where league_id = p_league and profile_id = v;
    if v_member is null then raise exception 'You are not in this league'; end if;
    select id into v_season from seasons
     where league_id = p_league and status in ('active','cup_final')
     order by starts_on desc limit 1;
    if v_season is null then raise exception 'No active season to post into'; end if;
  end if;
  -- D107: without a league, v_member and v_season stay null — the round
  -- belongs to its starter by profile, and there is nothing to post into.

  insert into live_rounds (league_id, season_id, course_id, tee_id, course_label,
                           course_snapshot, game, game_config, status, started_by,
                           starter_profile_id, join_code, api_course_id)
  values (p_league, v_season, p_course_id, p_tee_id,
          coalesce(nullif(trim(p_course_label), ''), 'Course'),
          coalesce(p_snapshot, '{}'::jsonb),
          coalesce(nullif(p_game, ''), 'none'),
          coalesce(p_config, '{}'::jsonb), 'live', v_member, v, v_code,
          nullif(trim(coalesce(p_api_course_id, '')), ''))
  returning id into v_lr;

  for v_el in select * from jsonb_array_elements(coalesce(p_players, '[]'::jsonb)) loop
    if (v_el->>'member_id') is not null then
      if p_league is null then
        raise exception 'No league on this round — seat golfers as guests';
      end if;
      if not exists (
        select 1 from league_members
         where id = (v_el->>'member_id')::uuid and league_id = p_league) then
        raise exception 'A tagged player is not in this league';
      end if;
    end if;
    insert into live_round_players (live_round_id, member_id, guest_name, guest_index,
                                    index_source, position, guest_profile_id)
    values (
      v_lr,
      nullif(v_el->>'member_id','')::uuid,
      nullif(trim(coalesce(v_el->>'guest_name','')), ''),
      nullif(v_el->>'guest_index','')::numeric,
      case when (v_el->>'member_id') is not null then 'member'
           when (v_el->>'guest_index') is not null then 'self' else 'estimated' end,
      v_pos,
      -- D88: only meaningful on a guest row; a member row is already identified
      case when (v_el->>'member_id') is null
           then nullif(v_el->>'guest_profile','')::uuid end);
    v_pos := v_pos + 1;
  end loop;

  -- D86/D88 · the invitation. Members by member_id, visitors by
  -- guest_profile_id; never the starter, never an account-less guest (there is
  -- no one to notify — they have a name and nothing else).
  select split_part(coalesce(playerlabel(v), 'Someone'), ' ', 1) into v_who;
  v_where := coalesce(nullif(trim(p_course_label), ''), 'the course');
  v_title := v_who || ' put you on the tee sheet';
  v_body  := 'Live round at ' || v_where || ' — open the app to score it with them';
  -- wave 7 · routed: the phone opens THIS live round (contract Â§2, `nudge`)
  insert into push_nudges (profile_id, kind, title, body, payload)
  select distinct pr, 'nudge', v_title, v_body,
         jsonb_build_object('live_round_id', v_lr, 'league_id', p_league)
    from (
    select m.profile_id as pr
      from live_round_players p
      join league_members m on m.id = p.member_id
     where p.live_round_id = v_lr and p.member_id is not null
    union
    select p.guest_profile_id
      from live_round_players p
     where p.live_round_id = v_lr and p.guest_profile_id is not null
  ) t where pr is distinct from v;

  return jsonb_build_object('live_round_id', v_lr, 'join_code', v_code, 'players', (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', id, 'member_id', member_id, 'guest_name', guest_name,
             'claim_token', claim_token, 'position', position) order by position), '[]'::jsonb)
      from live_round_players where live_round_id = v_lr));
end $function$;

-- ---- start_season ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% golfer(s) still in the pool — everyone needs a squad before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'Rosters locked. The season is live. Post a round.');
end $function$;

-- ---- transfer_pro ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.transfer_pro(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_league uuid; v_name text; v_me uuid; v_new_profile uuid;
begin
  select league_id, profile_id into v_league, v_new_profile
    from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro hands over the shop'; end if;
  v_me := my_member_id(v_league);
  if p_member = v_me then raise exception 'You already run the shop'; end if;
  if v_new_profile is null then raise exception 'That member has no golfer profile'; end if;

  update league_members set role = 'commissioner' where id = p_member;
  update league_members set role = 'player' where id = v_me;
  -- the column the phone, the create policy and delete_account all read
  update leagues set commissioner_id = v_new_profile where id = v_league;

  select coalesce(p.display_name, 'a member') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, p_member, 'transfer_pro', jsonb_build_object('from', v_me, 'to', p_member));
  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', v_me, 'The Pro role passes to ' || v_name || '.');
end $function$;

-- ---- declare_round (5-arg overload) ----------------------------------------
-- The one shouted generator no auditor found. Two overloads exist, so the
-- replacement names its signature explicitly. It also upper()s the course
-- name and every tagged golfer, destroying proper nouns on the way in.
--
-- FLAGGED, NOT FIXED HERE: both clients call the SIX-arg overload, which
-- posts nothing to the board at all — so a declared round never reaches the
-- league. That is a gap worth its own decision, not a silent change inside a
-- copy migration.
CREATE OR REPLACE FUNCTION public.declare_round(p_play_on date, p_course text, p_note text, p_tagged uuid[] DEFAULT '{}'::uuid[], p_tee time without time zone DEFAULT NULL::time without time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_name   text;
  v_tags   uuid[];
  v_bad    integer;
  v_with   text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then
    raise exception 'Pick a day that has not happened yet';
  end if;
  if p_play_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  if v_note is not null and length(v_note) > 140 then
    raise exception 'Notes cap at 140 characters';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven — it is golf, not a scramble league';
  end if;

  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and league mates'; end if;

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee)
  returning id into v_id;

  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the books — '
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', '')
  from league_members lm
  where lm.profile_id = auth.uid();

  return v_id;
end $function$;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text; v_name text; n int;
begin
  -- 1 · the mojibake is gone from BOTH functions, copy and comments alike
  foreach v_name in array array['finish_live_round','start_live_round'] loop
    select prosrc into v_src from pg_proc
     where proname = v_name and pronamespace = 'public'::regnamespace;
    if v_src like '%' || chr(226)||chr(128)||chr(148) || '%' then
      raise exception 'D165: % still carries a double-encoded em dash', v_name;
    end if;
    if v_src like '%' || chr(194)||chr(183) || '%' then
      raise exception 'D165: % still carries a double-encoded middot', v_name;
    end if;
  end loop;

  -- 2 · the lost 20260727240000 work is back: a client-composed story wins over
  --     the generic branch, and settlement pushes carry titles again
  select prosrc into v_src from pg_proc
   where proname = 'finish_live_round' and pronamespace = 'public'::regnamespace;
  if position('push_title' in v_src) = 0 then
    raise exception 'D165: finish_live_round lost push_title again';
  end if;
  if position('story' in v_src) = 0 then
    raise exception 'D165: the client-story branch is missing — a solo round robin will report a halved match while money moved';
  end if;
  if position(' def. ' in v_src) > 0 then
    raise exception 'D165: def. is back — agate, and its period truncates the push title';
  end if;

  -- 3 · the shouting is gone from the highest-traffic generators
  foreach v_name in array array['join_league','start_season','close_month','enter_cup_final',
                                'randomize_squads','settle_week_clash','remove_member'] loop
    select prosrc into v_src from pg_proc
     where proname = v_name and pronamespace = 'public'::regnamespace;
    if v_src ~ 'JOINED THE LEAGUE|ROSTERS LOCKED|LEDGER POSTED|THE CUP FINAL IS LIVE|LEFT THE LEAGUE' then
      raise exception 'D165: a shouted sentence survived the sweep in %', v_name;
    end if;
  end loop;

  -- 4 · a proper noun is never destroyed on the way into the database
  select count(*) into n from pg_proc
   where pronamespace = 'public'::regnamespace
     and prosrc ~ 'upper\(v_course\)|upper\(s\.name\)';
  if n > 0 then
    raise exception 'D165: % function(s) still upper() a proper noun', n;
  end if;

  -- 5 · D37 · create-or-replace preserves an ACL; prove none opened to anon
  select count(*) into n from pg_proc p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('join_league','finish_live_round','start_live_round','make_pick',
                       'close_season','mark_buy_in','set_handle','transfer_pro')
     and has_function_privilege('anon', p.oid, 'execute');
  if n > 0 then
    raise exception 'D37: % board function(s) became anon-callable', n;
  end if;
end $chk$;
