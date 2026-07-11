-- ============================================================================
-- Cup Season — fix form_squads color type (first CLI-managed migration)
--
-- Migration 007 made squads.color an integer palette index (0-3, check
-- constrained; the client owns the hex palette). form_squads() was never
-- updated and still inserted pre-007 text hex codes, so every league lock
-- failed with: column "color" is of type integer but expression is of type
-- text. Squads now get color = i-1, which maps 1:1 onto the client palette
-- (SQHEX: blue, orange, violet, teal) in the order the old array used.
-- ============================================================================

create or replace function public.form_squads(p_season uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare se record; st record; n int; i int;
        names text[] := array['Squad 1','Squad 2','Squad 3','Squad 4'];
begin
  select * into se from seasons where id = p_season;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;
  if st.structure = 'solo' then return; end if;
  if exists (select 1 from squads where season_id = p_season) then return; end if;

  n := case st.structure when 'squads2' then 2 when 'squads3' then 3 else 4 end;
  for i in 1..n loop
    insert into squads (season_id, name, color) values (p_season, names[i], i-1);
  end loop;
end $$;
