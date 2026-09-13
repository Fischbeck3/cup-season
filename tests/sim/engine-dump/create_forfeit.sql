-- create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text, p_other uuid, p_hangs text, p_event uuid, p_round uuid) oid=34973
CREATE OR REPLACE FUNCTION public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text DEFAULT 'custom'::text, p_other uuid DEFAULT NULL::uuid, p_hangs text DEFAULT NULL::text, p_event uuid DEFAULT NULL::uuid, p_round uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_name text; v_terms text; v_a text; v_b text; v_homes int;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;

  v_homes := (case when p_league is not null then 1 else 0 end)
           + (case when p_event  is not null then 1 else 0 end)
           + (case when p_round  is not null then 1 else 0 end);
  if v_homes > 1 then raise exception 'A pride bet hangs on one thing'; end if;
  if v_homes = 0 and p_other is null then
    raise exception 'Say who it is with, or what it hangs on';
  end if;

  -- "a shared season, a shared moment, a shared plan, or accepted buddies"
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'Only the crew can post a pride bet here.';
  end if;
  if p_event is not null and not is_event_member(p_event) then
    raise exception 'You have to be in it to put something on it';
  end if;
  if p_round is not null and not exists (
       select 1 from scheduled_rounds sr
        where sr.id = p_round
          and (sr.profile_id = auth.uid() or auth.uid() = any(sr.tagged))) then
    raise exception 'You have to be on the round to put something on it';
  end if;

  v_name  := nullif(trim(coalesce(p_name,'')),'');
  v_terms := nullif(trim(coalesce(p_terms,'')),'');
  if v_name is null or v_terms is null then
    raise exception 'A pride bet needs a name and terms';
  end if;
  if coalesce(p_kind,'custom') not in ('hosts','course_pick','strokes','bounty','custom') then
    raise exception 'Unknown kind';
  end if;
  if p_other is not null then
    if p_other = auth.uid() then raise exception 'You can''t bet against yourself'; end if;
    if p_league is not null then
      if not exists (select 1 from league_members
                      where league_id = p_league and profile_id = p_other) then
        raise exception 'The other side has to be in the crew';
      end if;
    elsif p_event is not null then
      if not exists (select 1 from event_players
                      where event_id = p_event and profile_id = p_other) then
        raise exception 'The other side has to be in it';
      end if;
    elsif p_round is not null then
      if not exists (select 1 from scheduled_rounds sr
                      where sr.id = p_round
                        and (sr.profile_id = p_other or p_other = any(sr.tagged))) then
        raise exception 'The other side has to be on the round';
      end if;
    else
      -- no container at all: buddies only, the same consent rule an RSVP uses (D69)
      if not exists (select 1 from friendships f
                      where f.status = 'accepted'
                        and ((f.requester = auth.uid() and f.addressee = p_other)
                          or (f.addressee = auth.uid() and f.requester = p_other))) then
        raise exception 'Pride bets are between buddies. Add them first';
      end if;
    end if;
  end if;

  insert into forfeits (league_id, event_id, scheduled_round_id, name, terms, kind,
                        party_a, party_b, hangs_on, created_by)
  values (p_league, p_event, p_round, left(v_name,60), left(v_terms,200),
          coalesce(p_kind,'custom'), auth.uid(), p_other,
          nullif(trim(coalesce(p_hangs,'')),''), auth.uid())
  returning id into v_id;

  -- The board post is written only where there IS a board. A pride bet between
  -- two buddies with no season tells nobody but the two of them (L-22).
  if p_league is not null then
    select display_name into v_a from profiles where id = auth.uid();
    select display_name into v_b from profiles where id = p_other;
    insert into posts (league_id, kind, body)
    values (p_league, 'system',
      'Pride bet posted: ' || v_name
      || case when v_b is not null then ' — ' || v_a || ' v ' || v_b
              else ' — ' || v_a || ' v the field' end
      || ' · ' || v_terms);
  end if;
  return v_id;
end $function$

