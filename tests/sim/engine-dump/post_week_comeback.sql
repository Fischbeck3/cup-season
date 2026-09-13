-- post_week_comeback(p_season uuid, p_week integer) oid=27433
CREATE OR REPLACE FUNCTION public.post_week_comeback(p_season uuid, p_week integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se       record;
  v_then   integer := p_week - 3;
  v_now    jsonb;
  v_prev   jsonb;
  v_lead   uuid;
  v_prior  uuid;
  v_back   numeric;
  v_name   text;
begin
  if p_week < 4 then return; end if;
  select * into se from seasons where id = p_season;
  if not found then return; end if;

  select standings->'individuals' into v_now
    from standings_snapshots where season_id = p_season and week_no = p_week;
  select standings->'individuals' into v_prev
    from standings_snapshots where season_id = p_season and week_no = v_then;
  -- a missing snapshot is silence, never a guess
  if v_now is null or v_prev is null then return; end if;

  -- who leads now
  select (e->>'member_id')::uuid into v_lead
    from jsonb_array_elements(v_now) e
   order by (e->>'points')::numeric desc limit 1;
  -- who led then, and how far back the current leader was
  select (e->>'member_id')::uuid into v_prior
    from jsonb_array_elements(v_prev) e
   order by (e->>'points')::numeric desc limit 1;
  if v_lead is null or v_prior is null or v_lead = v_prior then return; end if;

  select (select max((e2->>'points')::numeric) from jsonb_array_elements(v_prev) e2)
       - (select (e3->>'points')::numeric from jsonb_array_elements(v_prev) e3
           where (e3->>'member_id')::uuid = v_lead)
    into v_back;
  -- it is only a comeback if there was something to come back from
  if v_back is null or v_back < 15 then return; end if;

  select coalesce(p.display_name, 'A golfer') into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = v_lead;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'moment',
          coalesce(v_name, 'A golfer') || ': ' || round(v_back)
          || ' points back three weeks ago. Top of the table now.');
end $function$

