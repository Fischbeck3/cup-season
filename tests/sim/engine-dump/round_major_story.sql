-- round_major_story() oid=20238
CREATE OR REPLACE FUNCTION public.round_major_story()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; v_pvi numeric; v_prior numeric; v_lead numeric; v_name text; v_line text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim' or new.holes_played <> 18
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for m in
    select e.id as ev, e.allowance, s.opens_on, s.closes_on,
           ep.id as player_id, ep.exhibition
      from events e
      join event_sessions s on s.event_id = e.id and s.status = 'open'
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status = 'live'
       and new.played_on between s.opens_on and s.closes_on
  loop
    v_pvi := round((new.index_at_post * m.allowance / 100.0) - new.differential, 1);
    select max(round((r.index_at_post * m.allowance / 100.0) - r.differential, 1))
      into v_prior
      from rounds r
     where r.profile_id = new.profile_id and r.id <> new.id
       and r.played_on between m.opens_on and m.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;
    if v_prior is not null and v_pvi <= v_prior then continue; end if;

    select max(pvi) into v_lead from major_board(m.ev)
     where not exhibition and pvi is not null and player_id <> m.player_id;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := coalesce(v_name,'A golfer')
      || case when v_prior is null then ' opens with ' else ' improves to ' end
      || new.gross || ' — ' || lower(mj_vs(v_pvi));
    if m.exhibition then
      v_line := v_line || '. Doesn''t count this year.';
    elsif v_lead is null or v_pvi > v_lead then
      v_line := v_line || '. Takes the lead.';
    elsif v_pvi = v_lead then
      v_line := v_line || '. Ties the lead.';
    else
      v_line := v_line || '. The lead is ' || lower(mj_vs(v_lead)) || '.';
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $function$

