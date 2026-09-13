-- score_round() oid=18462
CREATE OR REPLACE FUNCTION public.score_round()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- differential first (index-independent)
  if new.holes_played = 9 and new.nine_rating is not null then
    new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;

  -- index snapshot: caller-provided > standing index > engine(prior rounds) >
  -- this round's own differential (first-round provisional). NEVER a blind 18.
  if new.index_at_post is null then
    select index_current into new.index_at_post from profiles where id = new.profile_id;
  end if;
  if new.index_at_post is null then
    new.index_at_post := handicap_index_asof(new.profile_id, new.played_on, new.id);
  end if;
  new.index_provisional := (new.index_at_post is null);   -- D124 (i): the fallback fired
  new.index_at_post := coalesce(new.index_at_post, new.differential);

  return new;
end $function$

