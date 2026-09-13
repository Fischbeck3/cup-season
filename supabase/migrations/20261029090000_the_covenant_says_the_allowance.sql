-- D353 · the covenant says the allowance, the whole counting rule and the dates,
-- from the same producer on both doors.
--
-- Two gaps, one migration:
--   1. `join_covenant_info` never carried `handicap_allowance`, so the one rule
--      that decides every points figure (`index × allowance / 100`, D178) was
--      the one rule a joiner could not read before tapping. And `counting_cap`
--      null meant "Unlimited" to the server and "absent" to a client reading a
--      JSON object, so the easiest rule to state could not be stated.
--   2. `join_covenant_for_invite` (20261026090000, unpushed) rebuilt the small
--      anon-shaped object by hand — no roster, no dates, no cap, no split — so
--      the invitation door showed LESS than the code door, on the same league,
--      to the same signed-in golfer.
--
-- The fix: the signed-in block gains `handicap_allowance` and an explicit
-- `every_round_counts` boolean (present, never merely absent), and the invite
-- door DELEGATES to the code door through the invitation it resolves, so the
-- two objects are one object by construction. The anon shape is unchanged key
-- for key, so the signed-out door still shows exactly what it shows today.
-- The league code is still never returned by the invite door.
--
-- Both are same-signature `create or replace`: no overload, no discarded ACL,
-- and the grants are restated anyway (L-04). Not deployed by this change.

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
    -- D353 · the two facts that were missing. `every_round_counts` is a real
    -- boolean so a client can tell Unlimited from "not in the payload".
    'every_round_counts', (ls.counting_cap is null),
    'handicap_allowance', ls.handicap_allowance,
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

revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;

-- The invitation door is the code door, reached through an invitation that is
-- the caller's own and still pending. It never returns the code.
create or replace function public.join_covenant_for_invite(p_invite uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
  select public.join_covenant_info(l.code)
  from member_invites mi
  join leagues l on l.id = mi.league_id
  where mi.id = p_invite
    and mi.profile_id = auth.uid()   -- somebody else's invitation is not a door
    and mi.status = 'pending'
    and l.code is not null
  limit 1;
$function$;

revoke all on function public.join_covenant_for_invite(uuid) from public, anon;
grant execute on function public.join_covenant_for_invite(uuid) to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare v_src text; v_j jsonb; n int;
begin
  select prosrc into v_src from pg_proc
   where proname = 'join_covenant_info' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'D353: join_covenant_info is missing'; end if;
  if position('auth.uid() is null then ''{}''::jsonb' in v_src) = 0 then
    raise exception 'D353: the added facts are not fenced to a signed-in caller — the anon surface would grow';
  end if;
  if position('''handicap_allowance''' in v_src) = 0 or position('''every_round_counts''' in v_src) = 0 then
    raise exception 'D353: the covenant is missing the allowance or the every-round-counts fact';
  end if;
  -- the anon shape is unchanged: an unknown code answers nothing
  select join_covenant_info('__no_such_code__') into v_j;
  if v_j is not null then raise exception 'D353: an unknown code answered something'; end if;

  select prosrc into v_src from pg_proc
   where proname = 'join_covenant_for_invite' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'D353: join_covenant_for_invite is missing'; end if;
  if position('join_covenant_info(l.code)' in v_src) = 0 then
    raise exception 'D353: the invite door must delegate to the code door';
  end if;
  select count(*) into n from pg_proc where proname in ('join_covenant_info', 'join_covenant_for_invite') and pronamespace = 'public'::regnamespace;
  if n <> 2 then raise exception 'D353: expected exactly two covenant functions, found %', n; end if;

  if not has_function_privilege('anon', 'public.join_covenant_info(text)', 'execute') then
    raise exception 'D353: the signed-out door lost its covenant lookup';
  end if;
  if has_function_privilege('anon', 'public.join_covenant_for_invite(uuid)', 'execute') then
    raise exception 'D353: anon must not execute join_covenant_for_invite';
  end if;
  if not has_function_privilege('authenticated', 'public.join_covenant_for_invite(uuid)', 'execute') then
    raise exception 'D353: authenticated must execute join_covenant_for_invite';
  end if;
end $check$;
