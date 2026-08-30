-- ============================================================================
-- Season simulator — the measurement layer.
--
-- Everything here answers one of two owner questions:
--   "is the play sound?"      — band spread, dead weight, whether posting
--                               matters more than playing, whether the floor
--                               fires on the people it was written for
--   "is the finish exciting?" — lead changes, when it was mathematically over,
--                               and whether the Cup Final actually decided it
--
-- The honesty rule from D24 applies to the read side too: `clinch_week` is the
-- first week after which the eventual winner was never caught IN THIS RUN.
-- That is hindsight, not the engine's own generous clinch math — it is the
-- right measure for "when did the season stop being interesting", but it must
-- never be quoted as what the app would have told a player at the time.
-- ============================================================================

create or replace function sim.result(p_slug text) returns jsonb
language plpgsql as $fn$
declare
  v_run uuid; v_league uuid; v_season uuid; v_cfg jsonb;
  se public.seasons%rowtype; st public.league_settings%rowtype;
  v_level text; v_weeks int; v_cap int;
  v_final jsonb; v_winner uuid; v_lead_changes int; v_clinch int;
  v_seeds jsonb; v_members jsonb; v_adj jsonb; v_pot jsonb;
  v_bands jsonb; v_months jsonb; v_cup jsonb; v_champ_label text;
  v_margin numeric; v_top numeric; v_second numeric;
  v_reg_leader uuid; v_cup_flipped boolean; v_head_decisive boolean := false;
begin
  select id, league_id, season_id, cfg into v_run, v_league, v_season, v_cfg
    from sim.runs where slug = p_slug;
  select * into se from public.seasons where id = v_season;
  select * into st from public.league_settings where league_id = v_league;
  v_level := case when st.structure = 'solo' then 'member' else 'squad' end;
  v_weeks := (v_cfg->>'weeks')::int;
  v_cap   := coalesce(st.counting_cap, 999);

  -- ---- the points table as it finished ------------------------------------
  select jsonb_agg(jsonb_build_object('label', label, 'points', points, 'rank', rank)
                   order by rank)
    into v_final
    from sim.timeline where run_id = v_run and week = v_weeks and level = v_level;

  select entity_id, points into v_winner, v_top
    from sim.timeline where run_id = v_run and week = v_weeks and level = v_level
   order by rank, entity_id limit 1;
  select points into v_second
    from sim.timeline where run_id = v_run and week = v_weeks and level = v_level
     and entity_id <> v_winner order by rank, entity_id limit 1;
  v_margin := coalesce(v_top, 0) - coalesce(v_second, 0);

  -- ---- lead changes across the season -------------------------------------
  with leaders as (
    select week, entity_id, row_number() over (partition by week order by rank, entity_id) rn
      from sim.timeline where run_id = v_run and level = v_level
  ), l as (select week, entity_id from leaders where rn = 1)
  select count(*) into v_lead_changes
    from (select entity_id, lag(entity_id) over (order by week) prev from l) x
   where prev is not null and prev is distinct from entity_id;

  -- ---- from which week did the eventual points leader never drop again? ---
  -- Only the WINNER's own rank history answers this.  Scanning every entity's
  -- rows always returns the final week, because some other entity is always
  -- off the top — the first version of this metric did exactly that and
  -- reported every season as decided on the last day.
  select coalesce(max(week), 0) + 1 into v_clinch
    from sim.timeline t
   where t.run_id = v_run and t.level = v_level
     and t.entity_id = v_winner and t.rank > 1;

  -- ---- BAND SPREAD: does a point mean golf, or does it mean attendance? ----
  -- Every counting round in the season, bucketed by the band it scored.
  select jsonb_object_agg(band, n order by band)
    into v_bands
    from (select case rr.points when 12 then '12_torched' when 9 then '09_beat'
                                when 7 then '07_played_to' when 6 then '06_loose'
                                when 5 then '05_rough' else 'other_'||rr.points end as band,
                 count(*) n
            from public.v_rounds_ranked rr
           where rr.season_id = v_season and rr.month_rank <= v_cap
           group by 1) z;

  -- ---- the Cup Final: seeds, window points, and whether +10 decided it ----
  select jsonb_agg(jsonb_build_object(
           'seed', cf.seed, 'head_start', cf.head_start, 'seed_rung', cf.seed_rung,
           'label', coalesce(q.name, p.display_name)) order by cf.seed)
    into v_seeds
    from public.cup_finalists cf
    left join public.squads q on q.id = cf.squad_id
    left join public.league_members lm on lm.id = cf.member_id
    left join public.profiles p on p.id = lm.profile_id
   where cf.season_id = v_season;

  if exists (select 1 from public.cup_finalists where season_id = v_season) then
    -- points each finalist actually scored inside the 28-day window
    select jsonb_agg(jsonb_build_object('label', label, 'seed', seed,
             'head_start', head_start, 'window_points', wp, 'total', head_start + wp)
             order by seed)
      into v_cup
      from (
        select cf.seed, cf.head_start,
               coalesce(q.name, p.display_name) as label,
               coalesce((select sum(w.points) from public._cup_window_rounds(v_season) w
                          where w.member_id in (
                            select case when st.structure = 'solo' then cf.member_id
                                   else sm.member_id end
                              from public.squad_members sm
                             where (st.structure <> 'solo' and sm.squad_id = cf.squad_id)
                                or (st.structure = 'solo' and sm.member_id = cf.member_id)
                            union select cf.member_id where st.structure = 'solo')), 0) as wp
          from public.cup_finalists cf
          left join public.squads q on q.id = cf.squad_id
          left join public.league_members lm on lm.id = cf.member_id
          left join public.profiles p on p.id = lm.profile_id
         where cf.season_id = v_season) z;

    -- would the crown have changed with no head start?
    select (min(total) filter (where seed = 1) > min(total) filter (where seed = 2))
       and (min(total - head_start) filter (where seed = 1)
            <= min(total - head_start) filter (where seed = 2))
      into v_head_decisive
      from jsonb_to_recordset(v_cup) as t(seed int, head_start numeric, total numeric);
  end if;

  select coalesce(cf.squad_id, cf.member_id) into v_reg_leader
    from public.cup_finalists cf where cf.season_id = v_season order by cf.seed limit 1;
  v_cup_flipped := (v_reg_leader is not null
                    and coalesce(se.champion_squad_id, se.champion_member_id) is not null
                    and v_reg_leader is distinct from coalesce(se.champion_squad_id, se.champion_member_id));

  select coalesce(q.name, p.display_name) into v_champ_label
    from public.seasons s
    left join public.squads q on q.id = s.champion_squad_id
    left join public.league_members lm on lm.id = s.champion_member_id
    left join public.profiles p on p.id = lm.profile_id
   where s.id = v_season;

  -- ---- who played, who didn't, and what it cost ---------------------------
  select jsonb_agg(jsonb_build_object(
           'name', p.display_name, 'archetype', a.archetype,
           'true_skill', a.skill, 'index_start', (v_cfg->'cast'->(a.seat)->>'index')::numeric,
           'index_end', p.index_current,
           'rounds', (select count(*) from public.rounds r
                       where r.profile_id = a.profile_id
                         and r.played_on between se.starts_on and se.ends_on),
           'counting', (select count(*) from public.v_rounds_ranked vr
                         where vr.member_id = lm.id and vr.season_id = v_season
                           and vr.month_rank <= v_cap),
           'points', (select s.points from public.v_individual_standings s
                       where s.member_id = lm.id and s.season_id = v_season),
           'ppr', (select round(s.points::numeric / nullif((select count(*) from public.v_rounds_ranked vr
                         where vr.member_id = lm.id and vr.season_id = v_season
                           and vr.month_rank <= v_cap), 0), 2)
                     from public.v_individual_standings s
                    where s.member_id = lm.id and s.season_id = v_season),
           'seated', exists (select 1 from public.squad_members sm
                              join public.squads q2 on q2.id = sm.squad_id
                             where sm.member_id = lm.id and q2.season_id = v_season))
           order by p.display_name)
    into v_members
    from sim.actors a
    join public.profiles p on p.id = a.profile_id
    join public.league_members lm on lm.profile_id = a.profile_id and lm.league_id = v_league
   where a.run_id = v_run;

  -- ---- what the month closes actually did ---------------------------------
  select jsonb_agg(jsonb_build_object('month', month, 'kind', kind, 'n', n,
                                      'total', total, 'reason', reason) order by month, kind)
    into v_adj
    from (select month, kind, count(*) n, sum(points) total, min(reason) reason
            from public.season_adjustments where season_id = v_season
           group by month, kind) z;

  -- which calendar months the season covered, and which were whole
  select jsonb_agg(jsonb_build_object('month', m,
           'whole', (m >= date_trunc('month', se.starts_on)::date
                     and (m + interval '1 month')::date - 1 <= se.ends_on
                     and se.starts_on <= m),
           'closed', exists (select 1 from public.season_adjustments sa
                              where sa.season_id = v_season and sa.month = m
                                and sa.kind = 'month_closed')) order by m)
    into v_months
    from generate_series(date_trunc('month', se.starts_on)::date,
                         date_trunc('month', se.ends_on)::date, interval '1 month') m;

  v_pot := jsonb_build_object('pot_cents', se.pot_cents,
                              'collected_cents', se.collected_cents,
                              'buyin_cents', st.buyin_cents,
                              'split', jsonb_build_array(st.payout_champ, st.payout_runnerup, st.payout_king),
                              'payouts', (select jsonb_agg(jsonb_build_object(
                                            'who', p.display_name, 'cents', sp.cents, 'reason', sp.reason))
                                            from public.season_payouts sp
                                            join public.profiles p on p.id = sp.profile_id
                                           where sp.season_id = v_season));

  return jsonb_build_object(
    'slug', p_slug,
    'config', jsonb_build_object(
       'structure', st.structure, 'finish', st.finish, 'weeks', v_weeks,
       'players', jsonb_array_length(v_cfg->'cast'),
       'allowance', st.handicap_allowance, 'counting_cap', st.counting_cap,
       'floor', st.participation_floor, 'floor_penalty', st.floor_penalty,
       'season_format', st.season_format, 'season_months_stored', st.season_months),
    'season', jsonb_build_object('status', se.status, 'starts_on', se.starts_on,
       'ends_on', se.ends_on, 'tiebreak_rung', se.tiebreak_rung,
       'champion', v_champ_label,
       'champion_score', se.champion_score, 'runnerup_score', se.runnerup_score,
       'points_king', (select p.display_name from public.league_members lm
                         join public.profiles p on p.id = lm.profile_id
                        where lm.id = se.points_king_member_id)),
    'points_table_final', v_final,
    'points_margin', v_margin,
    'lead_changes', v_lead_changes,
    'margin_pct', case when coalesce(v_top,0) > 0
                       then round(100.0 * v_margin / v_top, 1) else null end,
    'led_outright_from_week', v_clinch,
    'weeks', v_weeks,
    'weeks_led_unchallenged', greatest(v_weeks - v_clinch + 1, 0),
    'wire_to_wire', (v_clinch <= 1),
    'bands', v_bands,
    'cup_seeds', v_seeds,
    'cup_table', v_cup,
    'cup_flipped_result', v_cup_flipped,
    'head_start_decisive', v_head_decisive,
    'members', v_members,
    'months', v_months,
    'adjustments', v_adj,
    'pot', v_pot,
    'board_posts', (select count(*) from public.posts where league_id = v_league),
    'snapshots', (select count(*) from public.standings_snapshots where season_id = v_season)
  );
end $fn$;
