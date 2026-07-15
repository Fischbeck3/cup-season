-- Let a golfer delete their OWN round — a mis-post correction, not a league
-- edit. Rounds are otherwise immutable (spec §16), so this is deliberately
-- narrow: you can only remove a round that belongs to you.
--
-- FK cascades do the cleanup: round_holes, posts (posts.round_id ON DELETE
-- CASCADE), and attestations all drop with the round, and the standings views
-- (v_rounds_ranked / v_squad_standings) recompute automatically since they read
-- straight from `rounds`. Closed-month floor credits live in the separate
-- season_adjustments ledger keyed to member+month, not to a specific round, so
-- deleting a round never rewrites a closed month — a mis-post is normally
-- deleted the same day it's entered, well before any close.

create or replace function public.delete_round(p_round uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from rounds where id = p_round and profile_id = auth.uid();
  if not found then raise exception 'not your round to delete'; end if;
end $$;

revoke all on function public.delete_round(uuid) from public;
grant execute on function public.delete_round(uuid) to authenticated;
