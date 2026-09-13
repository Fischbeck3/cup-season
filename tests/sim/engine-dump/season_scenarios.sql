-- season_scenarios(p_season uuid) oid=19725
CREATE OR REPLACE FUNCTION public.season_scenarios(p_season uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; ls record;
  v_level text; v_k int; v_finish text; v_struct text;
  v_seed_end date; v_locked boolean; v_months int; v_cap int;
  v_maxband constant int := 12;   -- "Torched it" band cap (spec §2.2); bonuses off (D7)
  v_rows jsonb; v_meta jsonb;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then raise exception 'not a league member'; end if;
  select * into ls from league_settings where league_id = se.league_id;

  v_finish := coalesce(ls.finish, 'cup_final');
  v_struct := coalesce(ls.structure, 'squads2');
  v_cap    := coalesce(ls.counting_cap, 999);
  v_locked := (se.status = 'cup_final');
  v_seed_end := case when v_finish = 'cup_final' then se.ends_on - 27 else se.ends_on end;

  -- months of contribution still ahead (generous: the current month counts
  -- whole even if half-elapsed — an over-count only widens the ceiling, which
  -- is the safe direction for the honesty rule).
  if v_locked or v_seed_end < current_date then
    v_months := 0;
  else
    v_months := (extract(year from v_seed_end)::int*12 + extract(month from v_seed_end)::int)
              - (extract(year from current_date)::int*12 + extract(month from current_date)::int) + 1;
    if v_months < 0 then v_months := 0; end if;
  end if;

  -- how many advance (K), and at what level
  if v_struct = 'solo' then
    v_level := 'member';
    v_k := case when v_finish = 'points_table' then 1 else 2 end;
  else
    v_level := 'squad';
    if    v_finish = 'points_table' then v_k := 1;
    elsif v_struct = 'squads2'      then v_k := 1;  -- both reach the Final; the race is the #1 seed (+10)
    else  v_k := 2; end if;
  end if;

  with base as (
    select 'squad'::text as level, q.id, q.name,
           coalesce(ss.points,0)::bigint as points,
           greatest(1, count(sm.member_id))::int as roster
    from squads q
    left join v_squad_standings ss on ss.squad_id = q.id and ss.season_id = q.season_id
    left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season and v_level = 'squad'
    group by q.id, q.name, ss.points
    union all
    select 'member'::text, ist.member_id, p.display_name,
           coalesce(ist.points,0)::bigint, 1
    from v_individual_standings ist
    join league_members lm on lm.id = ist.member_id
    join profiles p on p.id = lm.profile_id
    where ist.season_id = p_season and v_level = 'member'
  ),
  finc as (
    select b.*, (b.points + (b.roster * v_months * v_cap * v_maxband)::bigint) as max_final
    from base b
  ),
  scored as (
    select f.*,
      -- K-th best OTHER ceiling: the bar I must clear NOW to lock a seat
      ( select coalesce((array_agg(o.max_final order by o.max_final desc))[v_k], -1)
        from finc o where o.id <> f.id ) as clinch_bar,
      -- K-th best OTHER current total: guaranteed-above bar for elimination
      ( select coalesce((array_agg(o.points order by o.points desc))[v_k], -1)
        from finc o where o.id <> f.id ) as elim_bar,
      rank() over (order by f.points desc) as rnk
    from finc f
  )
  select jsonb_agg(jsonb_build_object(
     'level', s.level, 'id', s.id, 'name', s.name,
     'points', s.points, 'max_final', s.max_final, 'roster', s.roster,
     'rank', s.rnk,
     'clinched',   (s.points > s.clinch_bar),
     'eliminated', (s.elim_bar > s.max_final),
     'needs', case when s.points > s.clinch_bar then 0
                   else greatest(0, s.clinch_bar - s.points + 1) end
   ) order by s.points desc)
  into v_rows from scored s;

  v_meta := jsonb_build_object(
    'finish', v_finish, 'structure', v_struct, 'level', v_level,
    'k', v_k, 'seed_end', v_seed_end, 'months_left', v_months,
    'locked', v_locked, 'cap', v_cap, 'status', se.status, 'ends_on', se.ends_on);

  return jsonb_build_object('meta', v_meta, 'rows', coalesce(v_rows, '[]'::jsonb));
end $function$

