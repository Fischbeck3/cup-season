-- ============================================================================
-- Decision D14 — the season's bye AUTO-applies to the first missed floor
--
-- The floor exists so nobody ghosts (spec design principle 1) — but punishing
-- the golfer who quietly misses one month turns guilt into churn (pre-mortem
-- cause #2). The bye already exists in the spec; this only changes its GRANT
-- mechanism: instead of waiting on the Pro, a member's ONE season bye fires
-- automatically the first month they'd breach the floor, with welcome-back
-- framing. Floors bite from the SECOND breach — the ghost-deterrent survives.
-- The Pro can still pre-grant (a known vacation) or revoke via set_member_bye.
--
-- Named tension (logged, not a contradiction): softening enforcement tugs
-- against principle 1. Resolution — it's the season's EXISTING one bye, now
-- self-serving; strategic bye-hoarding disappears (minor, arguably good).
--
-- close_month is replaced whole (baseline function); only the floor-penalty
-- loop changes — partial-month waiver, hybrid +15, and the month_closed
-- sentinel are carried over verbatim.
-- ============================================================================

create or replace function public.close_month(p_season uuid, p_month date) returns void
language plpgsql security definer set search_path = public as $$
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
                  upper(coalesce(v_name,'A GOLFER'))||'''S BYE KICKED IN FOR '
                  ||upper(to_char(p_month,'FMMonth'))
                  ||' — LIFE HAPPENS, NO PENALTY. THE FLOOR BITES FROM HERE.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  'Floor '||st.participation_floor||'/mo — posted '||m.credits||' · bye already used');
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  'FLOOR MISSED — '||abs(delta)||' PTS OFF THE BOARD');
        else  -- forfeit
          if m.counting_pts > 0 then
            insert into season_adjustments
              (season_id, squad_id, member_id, month, kind, points, reason)
            values (p_season, m.squad_id, m.member_id, p_month, 'floor_forfeit',
                    -m.counting_pts,
                    'Floor '||st.participation_floor||'/mo — posted '||m.credits
                    ||' · month forfeited · bye already used');
            insert into posts (league_id, season_id, kind, body)
            values (se.league_id, p_season, 'system',
                    'MONTH FORFEITED — '||m.counting_pts||' PTS STRUCK');
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
      select se.league_id, p_season, 'system', upper(name)||' TAKE THE MONTHLY +15'
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
          upper(to_char(p_month,'FMMonth'))||' CLOSED — LEDGER POSTED'
          || case when is_partial then ' · PARTIAL MONTH, FLOORS WAIVED' else '' end);
end $$;

-- ---- the Pro's manual grant/revoke (D14: "the Pro can still grant/revoke") --
-- Pre-grant a known absence, or revoke an auto-bye that shouldn't have fired.
-- One bye per member per season stays the invariant (revoke frees it again).
create or replace function public.set_member_bye(p_member uuid, p_month date, p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
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
            'THE PRO GRANTED '||upper(coalesce(v_name,'A MEMBER'))||' A BYE FOR '||upper(to_char(v_mon,'FMMonth')));
  else
    delete from season_adjustments where season_id = v_season and member_id = p_member
      and kind = 'bye' and month = v_mon;
    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, v_season, 'system', my_member_id(v_league),
            'THE PRO CLEARED '||upper(coalesce(v_name,'A MEMBER'))||'''S '||upper(to_char(v_mon,'FMMonth'))||' BYE');
  end if;
end $$;
grant execute on function public.set_member_bye(uuid, date, boolean) to authenticated;
