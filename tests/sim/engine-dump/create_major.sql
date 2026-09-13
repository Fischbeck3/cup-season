-- create_major(p_name text, p_final_on date, p_days integer, p_buy_in numeric, p_pot_split text, p_league uuid, p_tz text, p_lineage uuid) oid=20407
CREATE OR REPLACE FUNCTION public.create_major(p_name text, p_final_on date, p_days integer DEFAULT 4, p_buy_in numeric DEFAULT 0, p_pot_split text DEFAULT 'places'::text, p_league uuid DEFAULT NULL::uuid, p_tz text DEFAULT NULL::text, p_lineage uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_event uuid; v_name text; v_days integer; v_split text; v_buy numeric;
  v_open date; v_tz text; v_root uuid; v_nth integer; v_def text; v_annual text := '';
begin
  v_name := nullif(trim(coalesce(p_name,'')), '');
  if v_name is null then raise exception 'Name the jug — a Major needs a name'; end if;
  if p_final_on is null or p_final_on < current_date then
    raise exception 'The final day has to be ahead of you';
  end if;
  if p_final_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  v_days  := greatest(2, least(4, coalesce(p_days, 4)));
  v_buy   := coalesce(p_buy_in, 0);
  if v_buy < 0 or v_buy > 100000 then raise exception 'buy-in out of range'; end if;
  v_split := coalesce(p_pot_split, 'places');
  if v_split not in ('places','wta') then raise exception 'pot split must be places or wta'; end if;
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run a Major with it';
  end if;

  -- the chain link: rematch-only, your own history only, majors to majors
  if p_lineage is not null then
    if not exists (select 1 from events e
                    where e.id = p_lineage and e.kind = 'major'
                      and (e.created_by = auth.uid() or is_event_member(e.id))) then
      raise exception 'You can only run back a Major you were part of';
    end if;
    v_root := lineage_root(p_lineage);
  end if;

  -- tz: league's active season > creator's device (validated) > Phoenix
  if p_league is not null then
    select timezone into v_tz from seasons
     where league_id = p_league order by number desc limit 1;
  end if;
  if v_tz is null and p_tz is not null then
    begin perform now() at time zone p_tz; v_tz := p_tz;
    exception when others then v_tz := null; end;
  end if;
  v_tz := coalesce(v_tz, 'America/Phoenix');

  v_open := p_final_on - v_days + 1;

  insert into events (name, created_by, league_id, kind, starts_on,
                      session_count, session_weeks, draw_rule, tz,
                      buy_in, pot_split, lineage_id)
  values (v_name, auth.uid(), p_league, 'major', v_open,
          1, 1, 'team_pvi', v_tz, v_buy, v_split, v_root)
  returning id into v_event;

  insert into event_sessions (event_id, session_no, opens_on, closes_on)
  values (v_event, 1, v_open, p_final_on);

  -- the organizer enters the field like anyone (role-blind)
  insert into event_players (event_id, profile_id, role, seed, exhibition)
  values (v_event, auth.uid(), 'player', 0, not major_contender(auth.uid()));

  -- the annual voice: count the chain, name the defender (D61)
  if v_root is not null then
    select count(*) into v_nth from events e
     where e.id = v_root or e.lineage_id = v_root;   -- includes the new one
    select pr.display_name into v_def
      from events e
      join event_major_cards c on c.event_id = e.id and c.rank = 1
      join event_players ep on ep.id = c.player_id
      join profiles pr on pr.id = ep.profile_id
     where (e.id = v_root or e.lineage_id = v_root)
       and e.status = 'complete' and e.id <> v_event
     order by e.starts_on desc limit 1;
    v_annual := 'The ' || lower(nth_up(v_nth)) || ' annual. '
      || coalesce(v_def || ' defends. ', '');
  end if;

  perform major_post(v_event,
    v_annual
    || (select display_name from profiles where id = auth.uid())
    || ' sets ' || v_name || ' — '
    || to_char(v_open, 'Dy Mon DD') || ' → ' || to_char(p_final_on, 'Dy Mon DD')
    || '. Best card takes the jug.'
    || case when v_buy > 0 then ' Buy-in ' || mj_money(v_buy) || '.' else ' Bragging rights.' end);

  return v_event;
end $function$

