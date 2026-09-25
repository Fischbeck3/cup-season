-- Launch-audit integration I6 (2026-09-24) · L-17 · the Cup Final names its own seeds.
--
-- Once a Final opened, season_scenarios still recomputed "clinched" / "eliminated" from
-- the LIVE table — which by then includes window rounds — so it could print seeds the
-- engine never drew ("SEEDS SET — SQUAD 1 · SQUAD 3"); and season_story went on
-- narrating the full-season race (leader, runner-up, gap) as if it still decided anything.
-- The seeds were drawn and stored in cup_finalists the moment the window opened
-- (enter_cup_final); every Final surface reads them from there.
--
--   1 · season_scenarios: when the Final is locked (in play, or finished with
--       finalists), a row is clinched iff it is a finalist, carries its `seed`, and nobody
--       "needs" points; meta carries the drawn `seeds` in order. `rank` stays the points
--       rank — the approved distinction between a seed and a final position is kept.
--   2 · season_story's `final` facts, once locked: `locked`, the drawn `seeds` (seed,
--       name, head start, the rung that separated them) and the `race` — cup_final_race,
--       the same window arithmetic the crown uses (D105) — so the story can speak about the
--       Final and not the old table. `still_live` is the finalists.

-- ── 1 · season_scenarios ────────────────────────────────────────────────────
create or replace function public.season_scenarios(p_season uuid)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to 'public'
as $function$
declare
  se record; ls record;
  v_level text; v_k int; v_finish text; v_struct text;
  v_seed_end date; v_locked boolean; v_months int; v_cap int;
  v_maxband constant int := 12;   -- "Torched it" band cap (spec §2.2); bonuses off (D7)
  v_rows jsonb; v_meta jsonb; v_seeds jsonb;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then return null; end if;
  if not is_league_member(se.league_id) then raise exception 'not a league member'; end if;
  select * into ls from league_settings where league_id = se.league_id;

  v_finish := coalesce(ls.finish, 'cup_final');
  v_struct := coalesce(ls.structure, 'squads2');
  v_cap    := coalesce(ls.counting_cap, 999);
  -- [I6] L-17 · locked once the seeds are drawn: in the Final, or finished with finalists
  v_locked := (se.status = 'cup_final')
           or (se.status = 'complete' and exists (select 1 from cup_finalists cf where cf.season_id = p_season));
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
    select b.*, (b.points + (b.roster * v_months * v_cap * v_maxband)::bigint) as max_final,
           -- [I6] the drawn seed, when there is one
           (select cf.seed from cup_finalists cf
             where cf.season_id = p_season and (cf.squad_id = b.id or cf.member_id = b.id)) as seed
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
     'seed', s.seed,
     -- [I6] once the seeds are drawn, a finalist is clinched and everyone else is out
     'clinched',   case when v_locked then s.seed is not null else (s.points > s.clinch_bar) end,
     'eliminated', case when v_locked then s.seed is null else (s.elim_bar > s.max_final) end,
     'needs', case when v_locked or s.points > s.clinch_bar then 0
                   else greatest(0, s.clinch_bar - s.points + 1) end
   ) order by s.points desc)
  into v_rows from scored s;

  select coalesce(jsonb_agg(jsonb_build_object(
           'seed', cf.seed, 'id', coalesce(cf.squad_id, cf.member_id),
           'name', coalesce(q.name, p.display_name), 'head_start', cf.head_start, 'rung', cf.seed_rung)
           order by cf.seed), '[]'::jsonb)
    into v_seeds
    from cup_finalists cf
    left join squads q on q.id = cf.squad_id
    left join league_members lm on lm.id = cf.member_id
    left join profiles p on p.id = lm.profile_id
   where cf.season_id = p_season;

  v_meta := jsonb_build_object(
    'finish', v_finish, 'structure', v_struct, 'level', v_level,
    'k', v_k, 'seed_end', v_seed_end, 'months_left', v_months,
    'locked', v_locked, 'cap', v_cap, 'status', se.status, 'ends_on', se.ends_on,
    'seeds', v_seeds);

  return jsonb_build_object('meta', v_meta, 'rows', coalesce(v_rows, '[]'::jsonb));
end $function$;

-- ── 2 · season_story's Final speaks about the Final ─────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := E'                      ''seats'',      2,\n                      ''still_live'', v_live,';
begin
  v_def := pg_get_functiondef('public.season_story'::regproc);
  if position('[I6]' in v_def) > 0 then
    raise notice '[I6] season_story already names the Final''s seeds';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[I6] season_story final anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || $b$
                      -- [I6] L-17 · once the seeds are drawn the story is the Final's, not the old table's
                      'locked',     coalesce((v_scen->'meta'->>'locked')::boolean, false),
                      'seeds',      coalesce(v_scen->'meta'->'seeds', '[]'::jsonb),
                      'race',       case when coalesce((v_scen->'meta'->>'locked')::boolean, false)
                                         then cup_final_race(se.id) end,$b$);
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[I6]' in pg_get_functiondef('public.season_scenarios'::regproc)) = 0
     or position('[I6]' in pg_get_functiondef('public.season_story'::regproc)) = 0 then
    raise exception '[I6] a Final surface still reads the live table for its seeds';
  end if;
end $chk$;
