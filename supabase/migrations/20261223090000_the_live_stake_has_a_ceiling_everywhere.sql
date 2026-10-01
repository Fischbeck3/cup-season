-- D402 · the live stake has a ceiling everywhere.
--
-- D192 capped the per-round stake at $200 on the web (`index.html` CS_STAKE_MAX); the
-- phone's live-round field was a free decimal and the server took whatever arrived in
-- live_rounds.game_config (`stake`, or `unit` for the per-point games). D192's own words:
-- "the attribute is the affordance and the clamp is the guarantee" — and a clamp in one
-- client guarantees nothing about another. This trigger is the guarantee.
--
-- What it refuses, on a NEW live round or a CHANGED game_config:
--   · a game_config that is not a JSON object;
--   · a `stake` or a `unit` that is present and is not a plain JSON number from 0 to
--     200 — a string (even "" or "50"), an object, an array, a boolean, a negative or an
--     amount over 200. Absent and JSON null mean "no amount".
-- Each amount is read ON ITS OWN. A malformed sibling never turns an over-limit amount
-- into zero (corrected 2026-10-01 after review: {"stake":1000,"unit":"bad"} had passed,
-- because one bad cast zeroed both). Both clients only ever send numbers; production
-- held no other shape when this was written.
--
-- What it never touches: a round already started — on an UPDATE, an amount whose JSON
-- value did not change is not re-read, so a pre-cap agreement still settles exactly as
-- agreed — game_result, the season buy-in (already CHECKed 0..20000 cents on
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
  k     text;
  v     jsonb;
  amt   numeric;
  v_bad boolean := false;
begin
  if tg_op = 'UPDATE' and new.game_config is not distinct from old.game_config then
    return new;
  end if;
  if new.game_config is null or jsonb_typeof(new.game_config) <> 'object' then
    raise exception using message = 'That game setup can''t be read — start the round again.',
                          hint = 'cs_stake_refused';
  end if;
  -- each amount on its own; an over-limit amount is named first, whatever its sibling holds
  foreach k in array array['stake', 'unit'] loop
    v := new.game_config -> k;
    -- an amount the agreement already carried is not re-read (grandfathered)
    if tg_op = 'UPDATE' and jsonb_typeof(old.game_config) = 'object'
       and v is not distinct from (old.game_config -> k) then
      continue;
    end if;
    if v is null or jsonb_typeof(v) = 'null' then continue; end if;
    if jsonb_typeof(v) <> 'number' then v_bad := true; continue; end if;
    amt := (v #>> '{}')::numeric;
    if amt > 200 then
      raise exception using message = 'Stakes top out at $200 a golfer.', hint = 'cs_stake_refused';
    end if;
    if amt < 0 then v_bad := true; end if;
  end loop;
  if v_bad then
    raise exception using message = 'That stake isn''t an amount — set it again.', hint = 'cs_stake_refused';
  end if;
  return new;
end $$;
revoke all on function public._live_stake_ceiling() from public, anon, authenticated;

drop trigger if exists live_stake_ceiling on public.live_rounds;
create trigger live_stake_ceiling before insert or update of game_config on public.live_rounds
  for each row execute function public._live_stake_ceiling();
