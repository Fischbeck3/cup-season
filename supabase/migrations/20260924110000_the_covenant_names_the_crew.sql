-- ============================================================================
-- D225 (R9) · The covenant names the crew, the clock and what the money buys
--
-- L-12: every join passes the covenant. The screen exists on all three paths,
-- but it can only say what the payload gives it, and the payload gives it five
-- things: a name, a stake, a preset, the FLOOR and the finish. So the covenant
-- cannot say when the season starts, how long it runs, that BEST THREE A MONTH
-- COUNT (the payload returns the floor, which is the other number), who else is
-- in, or what $50 buys — which is the question two persona walks asked out loud
-- and could not get answered before tapping Join.
--
-- SIX FACTS ARE ADDED, and every one of them is READ, never assumed:
--   1. roster{count, names[6], markers[6], pro_name}   — WHO comes before the money
--   2. starts_on                                        — when the first tee is
--   3. weeks                                            — how long it runs
--   4. counting_cap                                     — "best three a month count"
--   5. split{champion, runner_up, points_king}          — what the stake buys (above $0 only)
--   6. pay{has_note, due_on}                            — that there is somewhere to send it
--
-- Facts 5 and 6 are league_settings' OWN figures, printed rather than assumed
-- (L-01, L-10): the split trio is the Pro's chosen payout, and `has_note` is a
-- BOOLEAN and a DATE — never the note itself, which is D129's own fail-closed
-- rule and is not weakened here.
--
-- SIGNED-IN CALLERS ONLY, ANON SIGNATURE UNCHANGED, FAIL-CLOSED.
-- `join_covenant_info` is `anon,auth` (contract.psv:166) and one of L-45's
-- twelve anon endpoints. None of the six may ride the anon path: the roster is
-- other people's names and markers, and a token-free code lookup is not the
-- place to hand them out. `auth.uid() is null` returns EXACTLY the payload the
-- function returns today, key for key, so the signed-out door is unchanged and
-- the anon surface stays at twelve.
-- ============================================================================

create or replace function public.join_covenant_info(p_code text)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure,
    -- D129, fail-closed: a boolean and a date, never the note itself
    'has_pay_note', (ls.buy_in_note is not null),
    'buy_in_due_on', ls.buy_in_due_on,
    -- D161/D112 · so the door can say where the league stands before the OTP
    'phase',       l.phase)
  || case when auth.uid() is null then '{}'::jsonb else jsonb_build_object(
    -- R9 · the six, for a SIGNED-IN caller only.
    'roster', (
      select jsonb_build_object(
        'count',    (select count(*)::int from league_members m where m.league_id = l.id and m.left_at is null),
        'pro_name', (select p.display_name from league_members m2
                       join profiles p on p.id = m2.profile_id
                      where m2.league_id = l.id and m2.role = 'commissioner' and m2.left_at is null limit 1),
        'names',    coalesce((select jsonb_agg(x.display_name order by x.ord) from (
                      select p.display_name, m3.joined_at as ord
                        from league_members m3 join profiles p on p.id = m3.profile_id
                       where m3.league_id = l.id and m3.role <> 'commissioner' and m3.left_at is null
                       order by m3.joined_at limit 6) x), '[]'::jsonb),
        'markers',  coalesce((select jsonb_agg(x.marker order by x.ord) from (
                      select p.marker, m4.joined_at as ord
                        from league_members m4 join profiles p on p.id = m4.profile_id
                       where m4.league_id = l.id and m4.role <> 'commissioner' and m4.left_at is null
                       order by m4.joined_at limit 6) x), '[]'::jsonb))),
    'starts_on',     s.starts_on,
    'ends_on',       s.ends_on,
    'weeks',         case when s.starts_on is null or s.ends_on is null then null
                          else greatest(1, round((s.ends_on - s.starts_on + 1) / 7.0)::int) end,
    'counting_cap',  ls.counting_cap,
    'split', case when coalesce(ls.buyin_cents, 0) > 0
                  then jsonb_build_object('champion',   ls.payout_champ,
                                          'runner_up',  ls.payout_runnerup,
                                          'points_king', ls.payout_king)
                  else null end,
    'pay', jsonb_build_object('has_note', (ls.buy_in_note is not null),
                              'due_on',   ls.buy_in_due_on))
  end
  from leagues l
  join league_settings ls on ls.league_id = l.id
  left join lateral (select sn.starts_on, sn.ends_on from seasons sn
                      where sn.league_id = l.id order by sn.number desc limit 1) s on true
  where upper(l.code) = upper(p_code)
  limit 1;
$function$;

-- The grants are RESTATED rather than assumed (L-04): this function is one of
-- L-45's twelve and its anon grant is deliberate and unchanged.
revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;

-- ── self-check (L-05: read-only, never mutates a real row) ─────────────────
do $chk$
declare v_src text; v_j jsonb;
begin
  select prosrc into v_src from pg_proc
   where proname='join_covenant_info' and pronamespace='public'::regnamespace;
  if v_src is null then raise exception 'R9: join_covenant_info is missing'; end if;
  if position('auth.uid() is null then ''{}''::jsonb' in v_src) = 0 then
    raise exception 'R9: the six added facts are not fenced to a signed-in caller — the anon surface would grow';
  end if;
  if position('''roster''' in v_src) = 0 or position('''starts_on''' in v_src) = 0
     or position('''weeks''' in v_src) = 0 or position('''counting_cap''' in v_src) = 0
     or position('''split''' in v_src) = 0 or position('''pay''' in v_src) = 0 then
    raise exception 'R9: the covenant is missing one of the six added facts';
  end if;

  -- The anon shape is unchanged, key for key. auth.uid() is null in a
  -- migration, so this call IS the anon path.
  select join_covenant_info('__no_such_code__') into v_j;
  if v_j is not null then
    raise exception 'R9: an unknown code answered something';
  end if;

  if not has_function_privilege('anon','public.join_covenant_info(text)','execute') then
    raise exception 'R9: the signed-out door lost its covenant lookup';
  end if;
  if not has_function_privilege('authenticated','public.join_covenant_info(text)','execute') then
    raise exception 'R9: join_covenant_info is not granted to authenticated';
  end if;
end $chk$;
