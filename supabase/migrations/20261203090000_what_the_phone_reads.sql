-- Launch-audit integration (2026-09-24) · the additive payload fields in
-- docs/planning/2026-09-24-native-audit-contract.md (Codex's native branch).
--
--   1 · native_home.memberships[].renewal_status — "pending" | "accepted" | "declined" |
--       "expired", beside `in_season` (D389, 20261128090000). A season-two golfer with a
--       yes on record is accepted; otherwise their latest invitation decides (D389's
--       `lapsed` reads as expired); with no invitation, pending until the first tee and
--       expired after. Season one is accepted. A pending next season opens the covenant;
--       declined or expired never renders as live.
--   2 · join_covenant_info.last_season.my_rank is where the golfer FINISHED (the crown,
--       _final_place — L-03), and the table rank rides along as my_points_rank.
--       (`structure` is already in the payload; nothing is added for anon.)

-- ── 1 · renewal_status ──────────────────────────────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$and (v_season->>'number')::int = any(lmx.agreed_seasons)),$a$;
begin
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('''renewal_status''' in v_def) > 0 then
    raise notice '[contract] native_home already carries renewal_status';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[contract] native_home in_season anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n' || $b$      -- [contract] the season-two answer, for a phone that must never show a no as live
      'renewal_status',    case
        when coalesce((v_season->>'number')::int, 1) <= 1 then 'accepted'
        when exists (select 1 from league_members lmr where lmr.id = m.member_id
                       and (v_season->>'number')::int = any(lmr.agreed_seasons)) then 'accepted'
        else coalesce((select case mi.status when 'pending' then 'pending' when 'declined' then 'declined'
                                             when 'lapsed' then 'expired' else null end
                         from member_invites mi
                        where mi.league_id = m.league_id and mi.profile_id = v
                          and mi.status in ('pending', 'declined', 'lapsed')
                        order by mi.created_at desc limit 1),
                      case when coalesce((v_season->>'kicked_off')::boolean, false)
                             or (v_season->>'days_to_first_tee') is null then 'expired' else 'pending' end)
      end,$b$);
  end if;
end $patch$;

-- ── 2 · the covenant's last season names the place finished ────────────────
do $patch$
declare v_def text; v_n integer; a text; b text; pairs text[][] := array[
  array[$x$          select x.rk, x.n, x.pts
            from (select vi.member_id, vi.points as pts,$x$,
        $x$          select x.rk, x.n, x.pts, x.member_id
            from (select vi.member_id, vi.points as pts,$x$],
  array[$x$jsonb_build_object('number', ps.number, 'my_rank', r.rk, 'of', r.n, 'my_points', r.pts)$x$,
        $x$jsonb_build_object('number', ps.number,
                                'my_rank', coalesce(public._final_place(ps.id, r.member_id), r.rk),  -- [contract] L-03
                                'my_points_rank', r.rk, 'of', r.n, 'my_points', r.pts)$x$]];
  i integer;
begin
  v_def := pg_get_functiondef('public.join_covenant_info'::regproc);
  if position('my_points_rank' in v_def) > 0 then
    raise notice '[contract] join_covenant_info already names the place finished';
    return;
  end if;
  for i in 1 .. array_length(pairs, 1) loop
    a := pairs[i][1]; b := pairs[i][2];
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[contract] join_covenant_info anchor % found % times', i, v_n; end if;
    v_def := replace(v_def, a, b);
  end loop;
  execute v_def;
end $patch$;
-- join_covenant_info is one of the twelve anon endpoints: its grants are restated, unchanged
revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('''renewal_status''' in pg_get_functiondef('public.native_home'::regproc)) = 0
     or position('''in_season''' in pg_get_functiondef('public.native_home'::regproc)) = 0
     or position('[S3]' in pg_get_functiondef('public.native_home'::regproc)) = 0 then
    raise exception '[contract] native_home lost a field';
  end if;
  if position('my_points_rank' in pg_get_functiondef('public.join_covenant_info'::regproc)) = 0
     or not has_function_privilege('anon', 'public.join_covenant_info(text)', 'EXECUTE') then
    raise exception '[contract] join_covenant_info is wrong';
  end if;
end $chk$;
