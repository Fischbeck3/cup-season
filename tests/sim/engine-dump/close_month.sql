-- close_month(p_season uuid, p_month date) oid=18256
CREATE OR REPLACE FUNCTION public.close_month(p_season uuid, p_month date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare st record; se record; m record; short numeric; delta int;
        is_partial boolean; month_last date; v_name text;
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
                  'Auto-bye — the first missed month. Life happens; the season''s one bye.');
          select display_name into v_name from profiles p
            join league_members lm on lm.profile_id = p.id where lm.id = m.member_id;
          insert into posts (league_id, season_id, kind, body)
          values (se.league_id, p_season, 'system',
                  coalesce(v_name,'A golfer')||'''s one bye covers '
                  ||to_char(p_month,'FMMonth')
                  ||'. No penalty. The minimum counts from here.');
        elsif st.floor_penalty = 'deduct' then
          delta := -5 * ceil(short);
          insert into season_adjustments
            (season_id, squad_id, member_id, month, kind, points, reason)
          values (p_season, m.squad_id, m.member_id, p_month, 'floor_penalty', delta,
                  to_char(p_month,'FMMonth')||' — '||st.participation_floor||' a month, posted '||m.credits||'. The bye was already used.');
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
                    to_char(p_month,'FMMonth')||'''s rounds are struck — the minimum wasn''t met. '
                    ||'Posted '||m.credits||' of '||st.participation_floor||', and the bye was already used.');
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

  -- 2 · (D206) the hybrid monthly (+15 to the head-to-head winner) lived
  --     here. Retired: no monthly is paid to a format nobody can choose.

  -- 3 · sentinel + the §14.2 "month closed" board event (unchanged)
  insert into season_adjustments (season_id, month, kind, points, reason)
  values (p_season, p_month, 'month_closed', 0,
          case when is_partial then 'Partial month — no minimum'
               else 'Month closed' end);
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          to_char(p_month,'FMMonth')||' is in the books. The ledger is posted.'
          || case when is_partial then ' A partial month — no minimum.' else '' end);
end $function$

