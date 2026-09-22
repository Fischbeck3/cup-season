-- Cup Season — a claimed card belongs to its claimer (claim walkthrough, 2026-09-19).
--
-- WRITTEN AND VALIDATED IN ISOLATION. NOT PUSHED. The owner pushes it.
--
-- Found by walking the guest-claim journey stage by stage against the real
-- functions with row security on (`tests/pilot/claim-walkthrough.py`, stage 5).
--
-- An account-less golfer is seated as a guest, plays, and later claims their
-- card with a new account. `claim_round` correctly sets
-- `live_round_players.claimed_profile` and posts the round to them. But
-- `_live_participant` — the test behind the READ policies on `live_rounds`,
-- `live_round_players` and `game_results` — recognises a seat only by
-- `starter_profile_id` or `guest_profile_id`. It never looked at
-- `claimed_profile`. So the person whose card it now is remained a stranger
-- to the round they played in:
--
--   · `round_tally` (security invoker, by design) could not read the live
--     round's snapshot, so the claimed round's receipt reported
--     `known:false` — no birdie or eagle tally — with no explanation. Same
--     family as 20261107090000, one table further along.
--   · the scorecard and the settlement of their own round were unreadable.
--
-- The fix is one more disjunct. It is READ-ONLY in effect: the three policies
-- that use this helper are all SELECT (verified: `pg_policy.polcmd = 'r'` for
-- `live_read`, `livep_read`, `gamer_read`), and no other function calls it.
-- It widens visibility to exactly one person — the one holding the card the
-- server already assigned to them. Nothing else changes: no score, no point,
-- no post, no grant.

create or replace function public._live_participant(p_live_round uuid)
returns boolean
language sql
stable security definer
set search_path to 'public'
as $function$
  select exists (
    select 1 from live_rounds lr
     where lr.id = p_live_round
       and ( lr.starter_profile_id = auth.uid()
             or exists (select 1 from live_round_players p
                         where p.live_round_id = lr.id
                           and ( p.guest_profile_id = auth.uid()
                                 -- the golfer who CLAIMED this seat's card is a
                                 -- participant of the round it came from
                                 or p.claimed_profile = auth.uid() )) ));
$function$;

do $chk$
begin
  if position('claimed_profile = auth.uid()' in pg_get_functiondef('public._live_participant'::regproc)) = 0 then
    raise exception 'check: the claimer is still not a participant';
  end if;
  -- the three policies that lean on it must still be SELECT-only
  if exists (select 1 from pg_policy p
              where pg_get_expr(p.polqual, p.polrelid) like '%_live_participant%'
                and p.polcmd <> 'r') then
    raise exception 'check: _live_participant now gates a non-SELECT policy — widening it would grant writes';
  end if;
end
$chk$;
