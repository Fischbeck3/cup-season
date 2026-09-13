-- award_event_trophies(p_event uuid) oid=19164
CREATE OR REPLACE FUNCTION public.award_event_trophies(p_event uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v record; v_champ uuid;
begin
  select kind, winner_team_id, name into v
    from events where id = p_event and status = 'complete';
  if not found then return; end if;

  if v.kind = 'major' then
    select ep.profile_id into v_champ
      from event_major_cards c join event_players ep on ep.id = c.player_id
     where c.event_id = p_event and c.rank = 1;
    if v_champ is not null then
      insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      values (v_champ, 'major', v.name, 'Major champion', 'winner', p_event,
              extract(year from current_date)::int)
      on conflict do nothing;
    end if;
    return;
  end if;

  -- the Ryder paths. BOTH are now scoped to this event.
  if v.winner_team_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder', 'winner', p_event,
             extract(year from current_date)::int
        from event_players ep
       where ep.event_id = p_event
         and ep.team_id = v.winner_team_id
      on conflict do nothing;
  else
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder · shared', 'shared', p_event,
             extract(year from current_date)::int
        from event_players ep
       where ep.event_id = p_event
         and ep.team_id is not null
      on conflict do nothing;
  end if;
end $function$

