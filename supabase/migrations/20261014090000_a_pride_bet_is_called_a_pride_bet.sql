-- ============================================================================
-- Cup Season — a pride bet is called a pride bet (D299)
--
-- The owner, from his own phone on build 748: *"In the fellas league it says I
-- can 'Post a forfeit' which sounds like a quit game but then it says its like
-- a side bet."* He is right, and the tell had been on the screen for months:
-- the title said "Post a forfeit" and the sentence beneath it opened "A forfeit
-- is a bet for pride" — a definition whose only job was to correct the words
-- above it. In ordinary English and in golf, to forfeit is to CONCEDE. The
-- product used it for a bet a golfer goes out of his way to post, and it uses
-- the word in its ORDINARY sense elsewhere in this same schema: `floor_penalty`
-- is `none | deduct | forfeit`, where forfeiting a month is exactly what the
-- owner thought the button meant.
--
-- D299 renames the NOUN a golfer reads. Both clients ship it in the same
-- commit (D234). This file is the third surface: D296 ruled that the server
-- says the sentence the golfer reads, and three functions still say the old
-- one — including a board post that every league member sees.
--
-- **TWO THINGS THIS FOUND, AND THEY ARE WORSE THAN THE RENAME.**
--
--   1 · `settle_forfeit` and `scrap_forfeit` still say **STAKE** — the word
--       D131 fenced to money on a live game, on the one object in the product
--       that may never carry an amount (`forfeits` has no money column, by a
--       CHECK and by db-check 29). "No such stake", "Only a party (or the Pro)
--       settles a stake", "Settled stakes stand".
--   2 · and they still **SHOUT IT**. `'STAKE SETTLED: ' || upper(f.name) || …
--       || ' TAKES IT · '` and `'STAKE SCRAPPED: ' || upper(f.name)`. D296's
--       class 4 (THE SHOUT) named `create_forfeit`'s board line and fixed it —
--       "STAKE POSTED:" became "Forfeit posted:" — and these two, which are the
--       same generator writing the same ledger, were not in the reader's set.
--       They are the last two shouted system posts in the product.
--
-- Every function below is its LIVE definition (`pg_get_functiondef`, the way
-- 20260831120000 and 20261012090000 were built), re-emitted whole with only the
-- sentences changed. No rule, query, guard, argument or grant moves.
--
-- `forfeits`, `create_forfeit`, `settle_forfeit`, `scrap_forfeit`,
-- `forfeits_one_home`, `forfeits_has_home` and `floor_penalty` KEEP THEIR
-- NAMES. A schema word is not a product word; renaming them would be a data
-- migration in service of a label nobody reads. db-check 29 is untouched.
-- ============================================================================

begin;

-- ---- create_forfeit · the six sentences and the board line -------------------
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
end $function$;

revoke all on function public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text, p_other uuid, p_hangs text, p_event uuid, p_round uuid) from public, anon;
grant execute on function public.create_forfeit(p_league uuid, p_name text, p_terms text, p_kind text, p_other uuid, p_hangs text, p_event uuid, p_round uuid) to authenticated;

-- ---- settle_forfeit · the money noun, and the shout -------------------------
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
end $function$;

revoke all on function public.settle_forfeit(p_id uuid, p_winner uuid, p_note text) from public, anon;
grant execute on function public.settle_forfeit(p_id uuid, p_winner uuid, p_note text) to authenticated;

-- ---- scrap_forfeit · the money noun, and the shout --------------------------
CREATE OR REPLACE FUNCTION public.scrap_forfeit(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such pride bet'; end if;
  if f.status <> 'open' then raise exception 'Settled pride bets stand — the archive keeps them'; end if;
  -- D221 / db-check 22 · a plain inequality against a column is NULL when
  -- either side is null, so the `if` never fires and the guard fails OPEN. The
  -- idiom is `is distinct from`, 20260904173000 already fixed this body, and
  -- copying the 2026-07 original back over it would have reopened it. (The
  -- check greps prosrc, and a plpgsql body carries its comments — so the
  -- forbidden shape may not appear even in a sentence about it.)
  if auth.uid() is distinct from f.created_by
     and not (f.league_id is not null and is_commissioner(f.league_id)) then
    raise exception 'Only the poster (or the Pro) scraps a pride bet';
  end if;
  update forfeits set status = 'scrapped', settled_at = now(), settled_by = auth.uid()
   where id = p_id;
  if f.league_id is not null then
    insert into posts (league_id, kind, body)
    values (f.league_id, 'system', 'Pride bet scrapped: ' || f.name);
  end if;
end $function$;

revoke all on function public.scrap_forfeit(p_id uuid) from public, anon;
grant execute on function public.scrap_forfeit(p_id uuid) to authenticated;

-- ---- the self-check ---------------------------------------------------------
-- Written the way 20261012090000's is: the NEW sentence must be present and the
-- OLD one absent, in the DEPLOYED source, or this migration refuses to land.
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'create_forfeit';
  if strpos(v_src, $q$'Pride bet posted: '$q$) = 0 or strpos(v_src, $q$'Forfeit posted: '$q$) > 0 then
    raise exception '[D299] create_forfeit still writes the old board line'; end if;
  if strpos(v_src, $q$'A pride bet hangs on one thing'$q$) = 0 or strpos(v_src, $q$'A forfeit hangs on one thing'$q$) > 0 then
    raise exception '[D299] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$'Only the crew can post a pride bet here.'$q$) = 0 or strpos(v_src, $q$post a forfeit here$q$) > 0 then
    raise exception '[D299] create_forfeit still says the old sentence'; end if;
  if strpos(v_src, $q$'A pride bet needs a name and terms'$q$) = 0 or strpos(v_src, $q$'A stake needs a name and terms'$q$) > 0 then
    raise exception '[D299] create_forfeit still says the money noun'; end if;
  if strpos(v_src, $q$'Pride bets are between buddies. Add them first'$q$) = 0 or strpos(v_src, $q$Forfeits are between buddies$q$) > 0 then
    raise exception '[D299] create_forfeit still says the old sentence'; end if;

  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'settle_forfeit';
  if strpos(v_src, $q$'Pride bet settled: '$q$) = 0 or strpos(v_src, $q$'STAKE SETTLED: '$q$) > 0 then
    raise exception '[D299] settle_forfeit still shouts the old board line'; end if;
  if strpos(v_src, $q$'No such pride bet'$q$) = 0 or strpos(v_src, $q$'No such stake'$q$) > 0 then
    raise exception '[D299] settle_forfeit still says the money noun'; end if;
  if strpos(v_src, $q$settles a pride bet$q$) = 0 or strpos(v_src, $q$settles a stake$q$) > 0 then
    raise exception '[D299] settle_forfeit still says the money noun'; end if;

  select prosrc into v_src from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'scrap_forfeit';
  if strpos(v_src, $q$'Pride bet scrapped: '$q$) = 0 or strpos(v_src, $q$'STAKE SCRAPPED: '$q$) > 0 then
    raise exception '[D299] scrap_forfeit still shouts the old board line'; end if;
  if strpos(v_src, $q$'No such pride bet'$q$) = 0 or strpos(v_src, $q$'No such stake'$q$) > 0 then
    raise exception '[D299] scrap_forfeit still says the money noun'; end if;
  if strpos(v_src, $q$scraps a pride bet$q$) = 0 or strpos(v_src, $q$scraps a stake$q$) > 0 then
    raise exception '[D299] scrap_forfeit still says the money noun'; end if;
  -- D221 / db-check 22 · the guard that was fixed once must not come back open
  if strpos(v_src, 'is distinct from f.created_by') = 0 then
    raise exception '[D299] scrap_forfeit lost the null-safe guard 20260904173000 installed'; end if;

  -- D64 / D242 · the rule the whole object rests on, re-asserted after three
  -- bodies were re-emitted: terms are PROSE, and there is nowhere to put money.
  if exists (select 1 from information_schema.columns
              where table_schema = 'public' and table_name = 'forfeits'
                and (column_name like '%cent%' or column_name like '%amount%' or column_name like '%money%')) then
    raise exception '[D299] forfeits grew a money column — terms are prose (D64/D242)'; end if;

  raise notice '[D299] the pride bet is called a pride bet — 3 functions, 11 sentences, 3 board lines, 2 of them no longer shouted';
end $chk$;

commit;
