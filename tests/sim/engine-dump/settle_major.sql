-- settle_major(p_session uuid) oid=20236
CREATE OR REPLACE FUNCTION public.settle_major(p_session uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s record; p record; t record; f record;
  b_pvi numeric[]; b_rid uuid[]; b_gross integer[]; b_at timestamptz[];
  v_cards integer; v_pot numeric; v_entrants integer;
  v_champ record; v_ru record; v_third record;
  v_share numeric; v_paid numeric := 0; v_places integer;
  v_line text; v_flip text := ''; v_tie text := '';
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.allowance, e.buy_in, e.pot_split, e.league_id,
         e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if s.status = 'closed' then return; end if;          -- idempotent
  if auth.uid() is not null then
    if not is_event_organizer(s.event_id) then raise exception 'Only the organizer can do that.'; end if;
    if s.closes_on >= (now() at time zone coalesce(s.tz,'America/Phoenix'))::date then
      raise exception 'The window runs through % — the horn sounds after', to_char(s.closes_on,'Dy Mon DD');
    end if;
  end if;

  -- freeze every player's card: best + second-best eligible in the window
  for p in select ep.id, ep.profile_id, ep.exhibition
             from event_players ep where ep.event_id = s.event_id
  loop
    select array_agg(x.pvi), array_agg(x.rid), array_agg(x.gross), array_agg(x.at)
      into b_pvi, b_rid, b_gross, b_at
      from (
        select round((r.index_at_post * s.allowance / 100.0) - r.differential, 1) as pvi,
               r.id as rid, r.gross, r.created_at as at
          from rounds r
         where r.profile_id = p.profile_id
           and r.played_on between s.opens_on and s.closes_on
           and not r.voided and coalesce(r.source,'app') <> 'sim'
           and r.holes_played = 18
           and r.index_at_post is not null and r.differential is not null
         order by pvi desc, r.created_at asc, r.id
         limit 2
      ) x;
    select count(*) into v_cards
      from rounds r
     where r.profile_id = p.profile_id
       and r.played_on between s.opens_on and s.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;

    insert into event_major_cards
      (event_id, player_id, round_id, gross, pvi, second_pvi, cards,
       best_posted_at, no_card, exhibition)
    values
      (s.event_id, p.id, b_rid[1], b_gross[1], b_pvi[1], b_pvi[2], v_cards,
       b_at[1], b_pvi[1] is null, p.exhibition)
    on conflict (event_id, player_id) do nothing;
  end loop;

  -- rank the contenders: the countback ladder (D45), coin flip last.
  -- Reset first so a rerun after a mid-settle crash can't strand a stale
  -- rank or prize on a row the fresh ranking no longer pays.
  update event_major_cards set rank = null, prize = 0 where event_id = s.event_id;
  with ranked as (
    select id, pvi, second_pvi, best_posted_at,
           row_number() over (order by pvi desc, second_pvi desc nulls last,
                              best_posted_at asc, random()) as rn
      from event_major_cards
     where event_id = s.event_id and not exhibition and not no_card
  )
  update event_major_cards c set rank = r.rn
    from ranked r where c.id = r.id;

  -- name the rungs that decided anything (receipts on the board)
  for t in
    select a.rank as arank, pa.display_name as aname, pb.display_name as bname,
           (a.second_pvi is not distinct from b.second_pvi
            and a.best_posted_at is not distinct from b.best_posted_at) as flipped
      from event_major_cards a
      join event_major_cards b on b.event_id = a.event_id and b.rank = a.rank + 1
      join event_players epa on epa.id = a.player_id join profiles pa on pa.id = epa.profile_id
      join event_players epb on epb.id = b.player_id join profiles pb on pb.id = epb.profile_id
     where a.event_id = s.event_id and a.pvi = b.pvi and a.rank <= 3
  loop
    if t.flipped then
      v_flip := v_flip || ' Coin flip: ' || t.aname || ' over ' || t.bname || '.';
    elsif t.arank = 1 then
      v_tie := ' On countback.';
    end if;
  end loop;

  -- the pot: contender entrants only (exhibition never buys in, never pays)
  select count(*) into v_entrants
    from event_major_cards where event_id = s.event_id and not exhibition;
  v_pot := s.buy_in * v_entrants;
  select count(*) into v_places
    from event_major_cards where event_id = s.event_id and rank is not null;

  if v_pot > 0 and v_places > 0 then
    if s.pot_split = 'wta' then
      update event_major_cards set prize = v_pot
       where event_id = s.event_id and rank = 1;
    else
      -- 60/25/15; a place the field can't fill rolls up to the champion
      if v_places >= 2 then
        v_share := round(v_pot * 0.25, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 2;
        v_paid := v_paid + v_share;
      end if;
      if v_places >= 3 then
        v_share := round(v_pot * 0.15, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 3;
        v_paid := v_paid + v_share;
      end if;
      update event_major_cards set prize = v_pot - v_paid
       where event_id = s.event_id and rank = 1;
    end if;
  end if;

  update event_sessions set status = 'closed' where id = p_session;

  -- podium reads
  select pr.display_name, c.gross, c.pvi, c.prize into v_champ
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 1;
  select pr.display_name, c.pvi into v_ru
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 2;
  select pr.display_name, c.pvi into v_third
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 3;

  -- completion FIRST (trophy trigger reads the ranked cards), then the story
  update events set status = 'complete' where id = s.event_id;

  if v_champ.display_name is null then
    v_line := s.name || '. '
      || case when exists (select 1 from event_major_cards
                            where event_id = s.event_id and exhibition and not no_card)
              then 'No official cards — the jug stays in the case.'
              else 'No cards posted — the jug stays in the case.' end
      || case when s.buy_in > 0 then ' Buy-ins returned.' else '' end;
  else
    v_line := firstname(v_champ.display_name) || ' takes '
      || case when s.name ~* '^the\s' then '' else 'the ' end || s.name
      || ', ' || lower(mj_vs(v_champ.pvi)) || '.' || v_tie
      || case when v_pot > 0 and s.pot_split = 'wta' then ' And the ' || mj_money(v_pot) || '.'
              when v_pot > 0 then ' ' || mj_money(v_pot) || ' in the pot.'
              else '' end
      || v_flip;
  end if;
  perform major_post(s.event_id, v_line);

  -- the best exhibition run gets its line (never the jug — D44)
  select pr.display_name, c.gross, c.pvi into f
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.exhibition and not c.no_card
   order by c.pvi desc limit 1;
  if f.display_name is not null then
    perform event_post(s.event_id,
      'Not counting this year: ' || f.display_name || ' went ' || f.gross || ' (' || lower(mj_vs(f.pvi))
      || '). Official by the next one.');
  end if;
end $function$

