-- settle_forfeit(p_id uuid, p_winner uuid, p_note text) oid=20464
CREATE OR REPLACE FUNCTION public.settle_forfeit(p_id uuid, p_winner uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record; v_line text; v_w text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such pride bet'; end if;
  if f.status <> 'open' then return; end if;   -- idempotent
  if auth.uid() not in (f.party_a, coalesce(f.party_b, f.party_a))
     and not (f.league_id is not null and is_commissioner(f.league_id)) then
    raise exception 'Only a party (or the Pro) settles a pride bet';
  end if;
  if f.party_b is not null then
    if p_winner is null or p_winner not in (f.party_a, f.party_b) then
      raise exception 'Name the winner — one of the two parties';
    end if;
  else
    if p_winner is null
       or not exists (select 1 from league_members
                       where league_id = f.league_id and profile_id = p_winner) then
      raise exception 'Name who hit it — someone in the crew';
    end if;
  end if;

  update forfeits
     set status = 'settled', winner = p_winner,
         settled_note = nullif(trim(coalesce(p_note,'')),''),
         settled_at = now(), settled_by = auth.uid()
   where id = p_id;

  -- D299 · natural case, and the same shape `create_forfeit`'s line takes.
  -- This line was the money noun in capitals over a golfer's own name, on the
  -- one object in the product that may never carry money; D296 class 4 fixed
  -- the post above it and never reached this one. (The retired literal is
  -- deliberately NOT quoted here — the self-check greps prosrc and a plpgsql
  -- body carries its comments, the trap the note in scrap_forfeit describes.)
  if f.league_id is not null then
    select display_name into v_w from profiles where id = p_winner;
    v_line := 'Pride bet settled: ' || f.name || ' — ' || v_w || ' takes it · ' || f.terms;
    insert into posts (league_id, kind, body) values (f.league_id, 'system', left(v_line,400));
  end if;
end $function$

