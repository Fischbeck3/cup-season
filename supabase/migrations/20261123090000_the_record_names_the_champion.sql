-- Launch audit S3 · L-03, L-15, L-21 (database half). No mechanic changes:
-- the crown is already stored; this makes every surface read it.
--
-- L-03 · after a Cup Final won by someone other than the table leader, the
-- runner-up's own record read "WON" and the champion's "2ND · 8 back". Both
-- clients sorted the table and never read `seasons.champion_*` (the August
-- season-sim P0: "never infer the champion from the table"). After a
-- squads3/4 Final, native_home's standing ranked a non-finalist 1st.
-- L-15 · tied golfers read different ranks on different surfaces:
-- native_home's `rank() over (order by points desc, display_name)` treats
-- rows as peers only when the WHOLE order ties, so a points tie was broken
-- alphabetically.
-- L-21 · the record showed one row per membership (the current season), so
-- Run it back dropped season one from it.
--
--   1 · `_final_place(season, unit)` — ONE answer to "where did this unit
--       finish": crown-aware on a complete season (champion 1, runner-up 2,
--       then the rest by the table, tie-aware), tie-aware while live. A unit is
--       a member (solo) or a squad (squads).
--   2 · `my_league_record()` — one row per season the caller said yes to,
--       every field both clients print, from `_final_place`.
--   3 · native_home: the standing's `rank` is tie-aware and, on a complete
--       season, the final place; it carries `tied`; the last-season block's
--       `my_rank` is the final place too.

-- ── 1 · where a unit finished ───────────────────────────────────────────────
create or replace function public._final_place(p_season uuid, p_unit uuid)
returns integer
language plpgsql stable security definer set search_path = public
as $$
declare s seasons%rowtype; v_solo boolean; v_champ uuid; v_runner uuid; v_rk integer;
begin
  select * into s from seasons where id = p_season;
  if s.id is null or p_unit is null then return null; end if;
  select (structure = 'solo') into v_solo from league_settings where league_id = s.league_id;

  if s.status <> 'complete' then
    -- live: tie-aware, points only (a tie shares its place)
    if v_solo then
      select rk into v_rk from (select member_id as u, rank() over (order by points desc) as rk
                                  from v_individual_standings where season_id = p_season) t where u = p_unit;
    else
      select rk into v_rk from (select squad_id as u, rank() over (order by points desc) as rk
                                  from v_squad_standings where season_id = p_season) t where u = p_unit;
    end if;
    return v_rk;
  end if;

  -- complete: the crown first (§14.3/§14.4), then the table for everyone else
  v_champ  := case when v_solo then s.champion_member_id else s.champion_squad_id end;
  v_runner := case when v_solo then s.runnerup_member_id else s.runnerup_squad_id end;
  if p_unit = v_champ then return 1; end if;
  if p_unit = v_runner then return case when v_champ is null then 1 else 2 end; end if;
  if v_solo then
    select rk into v_rk from (select member_id as u, rank() over (order by points desc) as rk
                                from v_individual_standings
                               where season_id = p_season
                                 and member_id is distinct from v_champ and member_id is distinct from v_runner) t
     where u = p_unit;
  else
    select rk into v_rk from (select squad_id as u, rank() over (order by points desc) as rk
                                from v_squad_standings
                               where season_id = p_season
                                 and squad_id is distinct from v_champ and squad_id is distinct from v_runner) t
     where u = p_unit;
  end if;
  return v_rk + (case when v_champ is null then 0 else 1 end) + (case when v_runner is null then 0 else 1 end);
end $$;
revoke all on function public._final_place(uuid, uuid) from public, anon, authenticated;

-- ── 2 · the record: one row per season the caller said yes to ──────────────
create or replace function public.my_league_record()
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare v uuid := auth.uid(); v_out jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select coalesce(jsonb_agg(row order by (row->>'starts_on') desc nulls last, row->>'league_name'), '[]'::jsonb)
    into v_out
    from (
      select jsonb_build_object(
        'league_id',   l.id,
        'league_name', l.name,
        'phase',       l.phase,
        'sandbox',     l.sandbox,
        'structure',   ls.structure,
        'season_id',   s.id,
        'number',      s.number,
        'status',      s.status,
        'starts_on',   s.starts_on,
        'ends_on',     s.ends_on,
        'squad_name',  sq.name,
        -- the unit that competes: the golfer (solo) or their squad
        'place',       public._final_place(s.id, case when ls.structure = 'solo' then lm.id else sq.id end),
        'of',          case when ls.structure = 'solo'
                            then (select count(*) from v_individual_standings vi where vi.season_id = s.id)
                            else (select count(*) from squads q where q.season_id = s.id) end,
        -- a shared place on a live table (a finished season's crown is never tied)
        'tied',        s.status <> 'complete' and (
                         case when ls.structure = 'solo'
                              then (select count(*) from v_individual_standings a, v_individual_standings b
                                     where a.season_id = s.id and b.season_id = s.id
                                       and a.member_id = lm.id and b.member_id <> lm.id and a.points = b.points) > 0
                              else (select count(*) from v_squad_standings a, v_squad_standings b
                                     where a.season_id = s.id and b.season_id = s.id
                                       and a.squad_id = sq.id and b.squad_id <> sq.id and a.points = b.points) > 0
                         end),
        'won',         s.status = 'complete' and (
                         case when ls.structure = 'solo' then s.champion_member_id = lm.id
                              else sq.id is not null and s.champion_squad_id = sq.id end),
        'runner_up',   s.status = 'complete' and (
                         case when ls.structure = 'solo' then s.runnerup_member_id = lm.id
                              else sq.id is not null and s.runnerup_squad_id = sq.id end),
        'king',        s.status = 'complete' and s.points_king_member_id = lm.id,
        'points',      (select vi.points from v_individual_standings vi where vi.season_id = s.id and vi.member_id = lm.id)
      ) as row
        from league_members lm
        join leagues l on l.id = lm.league_id
        join league_settings ls on ls.league_id = l.id
        join seasons s on s.league_id = l.id and s.number = any(lm.agreed_seasons)
        left join lateral (select q.id, q.name from squad_members sm join squads q on q.id = sm.squad_id
                            where sm.member_id = lm.id and q.season_id = s.id limit 1) sq on true
       where lm.profile_id = v
    ) t;
  return v_out;
end $$;
revoke all on function public.my_league_record() from public, anon;
grant execute on function public.my_league_record() to authenticated;

-- ── 3 · native_home reads the same answer ───────────────────────────────────
do $patch$
declare v_def text; v_parts text[]; v_a text; v_n integer;
begin
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('[S3]' in v_def) > 0 then
    raise notice '[S3] native_home already reads the crown';
    return;
  end if;

  -- 3a · the rank has its own points-only window (a tie shares its rank), and
  --      each row knows how many share its points
  v_a := E'rank()       over w as rk,\n                   count(*)     over ()  as of_n,';
  v_parts := string_to_array(v_def, v_a);
  if coalesce(array_length(v_parts, 1), 0) <> 3 then
    raise exception '[S3] native_home rank anchor found % times; expected twice', coalesce(array_length(v_parts, 1), 0) - 1;
  end if;
  v_def := v_parts[1]
    || E'rank() over (order by vs.points desc) as rk,  -- [S3] L-15: a tie shares its rank\n'
    || E'                   count(*) over (partition by vs.points) as tie_n,\n'
    || E'                   count(*)     over ()  as of_n,'
    || v_parts[2]
    || E'rank() over (order by vi.points desc) as rk,  -- [S3] L-15: a tie shares its rank\n'
    || E'                   count(*) over (partition by vi.points) as tie_n,\n'
    || E'                   count(*)     over ()  as of_n,'
    || v_parts[3];

  -- 3b · on a complete season the rank IS the final place; `tied` rides along
  v_a := $a$'rank',             st.rk,$a$;
  v_parts := string_to_array(v_def, v_a);
  if coalesce(array_length(v_parts, 1), 0) <> 3 then
    raise exception '[S3] native_home rank key found % times; expected twice', coalesce(array_length(v_parts, 1), 0) - 1;
  end if;
  v_def := v_parts[1]
    || $b$'rank',             case when v_season->>'status' = 'complete'
                                   then public._final_place(v_season_id, st.squad_id) else st.rk end,  -- [S3] L-03
            'tied',             coalesce(v_season->>'status', '') <> 'complete' and st.tie_n > 1,$b$
    || v_parts[2]
    || $b$'rank',             case when v_season->>'status' = 'complete'
                                   then public._final_place(v_season_id, st.member_id) else st.rk end,  -- [S3] L-03
            'tied',             coalesce(v_season->>'status', '') <> 'complete' and st.tie_n > 1,$b$
    || v_parts[3];

  -- 3c · the last season's `my_rank` is where the golfer finished, not the table
  v_a := $a$when v_solo then (select vi2.rk from (
                                   select vi.member_id, rank() over (order by vi.points desc) as rk
                                     from v_individual_standings vi where vi.season_id = s2.id) vi2
                                  where vi2.member_id = m.member_id)$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[S3] native_home my_rank anchor found % times; expected once', v_n; end if;
  v_def := replace(v_def, v_a,
    $b$when v_solo then public._final_place(s2.id, m.member_id)::bigint  -- [S3] L-03$b$);

  execute v_def;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_def text;
begin
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('[S3]' in v_def) = 0 or position('_final_place' in v_def) = 0 then
    raise exception '[S3] native_home does not read the crown';
  end if;
  if position('over w as rk' in v_def) > 0 then
    raise exception '[S3] native_home still breaks a points tie by name';
  end if;
  if has_function_privilege('authenticated', 'public._final_place(uuid, uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.my_league_record()', 'EXECUTE')
     or has_function_privilege('anon', 'public.my_league_record()', 'EXECUTE') then
    raise exception '[S3] a grant is wrong';
  end if;
end $chk$;
