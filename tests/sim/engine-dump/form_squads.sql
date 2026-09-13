-- form_squads(p_season uuid) oid=18482
CREATE OR REPLACE FUNCTION public.form_squads(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; st record; n int; i int;
        names text[] := array['Squad 1','Squad 2','Squad 3','Squad 4'];
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;
  if st.structure = 'solo' then return; end if;
  if exists (select 1 from squads where season_id = p_season) then return; end if;

  n := case st.structure when 'squads2' then 2 when 'squads3' then 3 else 4 end;
  for i in 1..n loop
    insert into squads (season_id, name, color) values (p_season, names[i], i-1);
  end loop;
end $function$

