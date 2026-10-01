-- D402 · the live stake has a ceiling everywhere.
--
-- D192 capped the per-round stake at $200 on the web (`index.html` CS_STAKE_MAX); the
-- phone's live-round field was a free decimal and the server took whatever arrived in
-- live_rounds.game_config (`stake`, or `unit` for the per-point games). D192's own words:
-- "the attribute is the affordance and the clamp is the guarantee" — and a clamp in one
-- client guarantees nothing about another. This trigger is the guarantee.
--
-- What it refuses: a NEW live round, or a CHANGED game_config, whose stake or unit is
-- above 200. What it never touches: a round already started (its config is not
-- re-checked when it finishes, so a pre-cap agreement can still be settled exactly as
-- agreed), game_result, the season buy-in (already CHECKed 0..20000 cents on
-- league_settings, D113), event buy-ins, or any ledger amount. Nothing is clamped or
-- rewritten: a refused write is refused, with a sentence the clients pass through.
--
-- The cap describes the product (D192: "a statement about what this product is for");
-- it does not settle any legal classification, and no copy should say it does.

create or replace function public._live_stake_ceiling()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_new numeric;
  v_old numeric;
begin
  begin
    v_new := greatest(coalesce((new.game_config ->> 'stake')::numeric, 0),
                      coalesce((new.game_config ->> 'unit')::numeric, 0));
  exception when others then
    v_new := 0;   -- a non-numeric stake is no stake; never refuse a round over a shape
  end;
  if tg_op = 'UPDATE' then
    begin
      v_old := greatest(coalesce((old.game_config ->> 'stake')::numeric, 0),
                        coalesce((old.game_config ->> 'unit')::numeric, 0));
    exception when others then
      v_old := null;
    end;
    if v_new is not distinct from v_old then return new; end if;
  end if;
  if v_new > 200 then
    raise exception 'Stakes top out at $200 a golfer.';
  end if;
  return new;
end $$;
revoke all on function public._live_stake_ceiling() from public, anon, authenticated;

drop trigger if exists live_stake_ceiling on public.live_rounds;
create trigger live_stake_ceiling before insert or update of game_config on public.live_rounds
  for each row execute function public._live_stake_ceiling();
