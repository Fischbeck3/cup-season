-- D412 · a Major's buy-in has the same $200 ceiling as every other money field.
--
-- WHAT. `create_major` refused a buy-in only outside 0..100000 (the range check
-- 20260831120000 carried forward from the Major's first body). This moves the
-- top of that range to 200, the number D113, D192 and D402 already hold for the
-- season buy-in (the league_settings CHECK, 0..20000 cents) and the live-round
-- stake (the live_stake_ceiling trigger). Dollars here, as `events.buy_in` and
-- `mj_money()` have always been. Nothing else in the function moves.
--
-- WHY. D412 extends D192 and D402 to the one money field they missed. The 1.0
-- review notes told App Review that buy-ins go "up to $200"; for a Major that
-- was untrue. D192: "A cap is not a rule about what friends may bet. It is a
-- statement about what this product is for."
--
-- HOW IT IS WRITTEN. The D393 method (20261210090000): the LIVE body is read
-- with pg_get_functiondef, one asserted anchor is replaced, and the result is
-- executed. A retyped body would silently roll back the [D393] reach gate and
-- the stage-D write gate (20261112090000, `is_active_member`), which exist in
-- no single migration file. The anchor must appear exactly once or this
-- raises; a body that already carries [D412] is left alone with a notice, so
-- a second run is a no-op. The self-check at the foot refuses to finish unless
-- the new ceiling, [D393] and the stage-D gate are all in the live body.
--
-- WHAT IT NEVER TOUCHES. No existing event is read or rewritten: only a NEW
-- Major is refused above $200 (production held none above $200 on 2026-10-12).
-- The refusal keeps its words, 'buy-in out of range', so that nothing else
-- moves; the tests pin them. No client matches on them (see DEPLOY SKEW). The
-- signature is unchanged, so no overload appears and the generated Rpc.swift
-- and packages/db/contract.psv do not move.
--
-- DEPLOY SKEW. Either order is safe. A build that predates the clamp (2206 and
-- earlier, or a stale web tab) sending more than $200 is refused with the
-- existing 'buy-in out of range' exception, and no Major is made. Both clients
-- hand that exception to humanError: it is on neither allowlist and opens in
-- lowercase, so the golfer reads "Could not set the Major. Something went
-- wrong — please try again.", which does not name the ceiling. A new client
-- against an older server never sends more than $200, so it never meets the
-- old range.
--
-- VERIFY on a disposable cluster, never the linked project:
--   node tests/major-buy-in-database.mjs
-- (tests/db/a-majors-buy-in-has-the-same-ceiling.sql and db-check 62 run there).

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$if v_buy < 0 or v_buy > 100000 then raise exception 'buy-in out of range'; end if;$a$;
begin
  v_def := pg_get_functiondef('public.create_major(text,date,integer,numeric,text,uuid,text,uuid)'::regprocedure);
  if position('[D412]' in v_def) > 0 then
    raise notice '[D412] create_major already holds the $200 ceiling';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D412] create_major anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$if v_buy < 0 or v_buy > 200 then raise exception 'buy-in out of range'; end if;  -- [D412] the $200 ceiling (D192, D402)$b$);
  end if;
end $patch$;

-- the live body holds the ceiling, and the gates the patch had to keep
do $check$
declare v_def text := pg_get_functiondef('public.create_major(text,date,integer,numeric,text,uuid,text,uuid)'::regprocedure);
begin
  if position('[D412]' in v_def) = 0 or position('v_buy > 200 then' in v_def) = 0 or position('100000' in v_def) > 0 then
    raise exception '[D412] self-check: create_major does not hold the $200 ceiling';
  end if;
  if position('[D393]' in v_def) = 0 or position('_reach_gate(' in v_def) = 0 then
    raise exception '[D412] self-check: create_major lost its [D393] reach gate';
  end if;
  if position('is_active_member(p_league)' in v_def) = 0 or position('is_league_member(' in v_def) > 0 then
    raise exception '[D412] self-check: create_major lost its stage-D write gate (is_active_member)';
  end if;
  if position('''buy-in out of range''' in v_def) = 0 then
    raise exception '[D412] self-check: the refusal''s words changed (D412 keeps them; the tests pin them)';
  end if;
end $check$;

-- executing the definition keeps the ACL; restated anyway, as every function
-- migration must (D37).
revoke execute on function public.create_major(text,date,integer,numeric,text,uuid,text,uuid) from public, anon;
grant execute on function public.create_major(text,date,integer,numeric,text,uuid,text,uuid) to authenticated;
