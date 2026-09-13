-- award_season_trophies(p_season uuid) oid=19676
CREATE OR REPLACE FUNCTION public.award_season_trophies(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; lg_name text; yr int;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if not found then return; end if;
  select name into lg_name from leagues where id = se.league_id;
  yr := extract(year from se.ends_on)::int;

  -- champion(s)
  if se.champion_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.champion_squad_id
      on conflict do nothing;
  elsif se.champion_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Champion', 'winner', se.league_id, yr
        from league_members lm where lm.id = se.champion_member_id
      on conflict do nothing;
  end if;

  -- runner(s)-up
  if se.runnerup_squad_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from squad_members sm join league_members lm on lm.id = sm.member_id
       where sm.squad_id = se.runnerup_squad_id
      on conflict do nothing;
  elsif se.runnerup_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Runner-up', 'runner_up', se.league_id, yr
        from league_members lm where lm.id = se.runnerup_member_id
      on conflict do nothing;
  end if;

  -- the Points King
  if se.points_king_member_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, league_id, season_year)
      select lm.profile_id, 'league', lg_name, 'Points King', 'points_king', se.league_id, yr
        from league_members lm where lm.id = se.points_king_member_id
      on conflict do nothing;
  end if;

  -- D67 → D106: what it paid, recorded once, in cents — from what was COLLECTED
  perform recompute_season_payouts(p_season);
end $function$

