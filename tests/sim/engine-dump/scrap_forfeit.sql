-- scrap_forfeit(p_id uuid) oid=20465
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
end $function$

