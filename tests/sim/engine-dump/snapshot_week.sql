-- snapshot_week(p_season uuid) oid=18420
CREATE OR REPLACE FUNCTION public.snapshot_week(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

  -- D166 · the comeback. FOUND is false when the conflict swallowed the
  -- insert, so a re-run of the same week can never re-tell the story.
  if found then
    perform post_week_comeback(p_season, wk);
  end if;
end $function$

