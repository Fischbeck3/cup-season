-- Launch audit S6, database half · L-09 + L-27. No mechanic changes, so no
-- decision entry: these make two existing rules true.
--
-- L-09 · claim_round and claim_scan_round read the seat with a plain SELECT and
-- then UPDATE it with no guard, so two claims of one card inside ~5 ms both
-- posted: duplicate attested rounds and a member's standing doubled (30/30 same
-- golfer, 20/20 two golfers, 10/10 scan on the sandbox). The migration that
-- introduced claim_round says it "can never double-post"; D-log L2971 gave
-- finish_live_round a row lock for the same reason. The seat read now takes the
-- row lock (`for update`), so the second claim waits, then sees the first
-- claim's profile and answers `already` or refuses. The audit measured 0/52
-- duplicates with this change.
--
-- L-27 · signed-out guest_live_state returned the whole round for a finished or
-- claimed link: every player's hole-by-hole strokes, members' names and indexes,
-- the join code. Both clients read only `round.status` outside a live round
-- (index.html's claim gate, LiveClaim.gate), so the full state is now returned
-- only while the round is live and the seat is unclaimed; otherwise the answer
-- is `{round:{id,status}, me}`.

-- ── 1 · one card, one claim ─────────────────────────────────────────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.claim_round'::regproc);
  if position('[S6]' in v_def) = 0 then
    v_a := $a$select * into v_pl from live_round_players where claim_token = p_token and member_id is null;$a$;
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[S6] claim_round anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      $b$select * into v_pl from live_round_players where claim_token = p_token and member_id is null
     for update;  -- [S6] L-09: the seat is locked, so a second claim waits and sees the first$b$);
  end if;

  v_def := pg_get_functiondef('public.claim_scan_round'::regproc);
  if position('[S6]' in v_def) = 0 then
    v_a := $a$select * into c from scan_claims where token = p_token;$a$;
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[S6] claim_scan_round anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      $b$select * into c from scan_claims where token = p_token
     for update;  -- [S6] L-09: the partner row is locked, so a second claim waits and sees the first$b$);
  end if;
end $patch$;

-- ── 2 · a finished or claimed link shows its status, not the round ─────────
create or replace function public.guest_live_state(p_token uuid)
returns jsonb
language plpgsql stable security definer set search_path = public
as $function$
declare v_pl live_round_players%rowtype; v_status text;
begin
  select * into v_pl from live_round_players
   where claim_token = p_token and member_id is null;
  if v_pl.id is null then raise exception 'No such round'; end if;
  select status into v_status from live_rounds where id = v_pl.live_round_id;
  -- [S6] L-27: the whole round only for the pencil it exists to serve
  if v_status is distinct from 'live' or v_pl.claimed_profile is not null then
    return jsonb_build_object('round', jsonb_build_object('id', v_pl.live_round_id, 'status', v_status),
                              'me', v_pl.id);
  end if;
  return _live_state_of(v_pl.live_round_id) || jsonb_build_object('me', v_pl.id);
end $function$;
-- anon keeps it: one of the twelve public endpoints (D86); grants restated
revoke all on function public.guest_live_state(uuid) from public;
grant execute on function public.guest_live_state(uuid) to anon, authenticated;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('for update' in pg_get_functiondef('public.claim_round'::regproc)) = 0
     or position('for update' in pg_get_functiondef('public.claim_scan_round'::regproc)) = 0 then
    raise exception '[S6] a claim still reads its seat without a lock';
  end if;
  if position('[S6]' in pg_get_functiondef('public.guest_live_state'::regproc)) = 0 then
    raise exception '[S6] guest_live_state still returns a finished round';
  end if;
  if not has_function_privilege('anon', 'public.guest_live_state(uuid)', 'EXECUTE') then
    raise exception '[S6] guest_live_state lost its anon grant';
  end if;
end $chk$;
