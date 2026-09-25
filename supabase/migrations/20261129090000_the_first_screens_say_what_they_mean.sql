-- Launch audit S12, database half · L-28 + L-23 (the solo floor). No mechanic
-- changes: both make an existing rule true on the surfaces that state it.
--
-- L-28 · a 9-hole round was announced as "Under 80 for the first time" on the
-- golfer's Home and in a buddy's lead: home_stories' milestone (which
-- home_dispatch reads) compared the gross with 80 whatever the holes played.
-- The trophy case already required 18 holes; the story now does too, for the
-- milestone and for the "never before" window behind it.
--
-- L-23 (floor half) · both clients sent a participation floor for SOLO
-- seasons, and the covenant then promised a minimum the engine never assesses
-- in an individual season ("No team penalty in an individual season"). The
-- clients now send 0 for solo; lock_league stores 0 for solo whatever arrives.

-- ── 1 · "Under 80" means eighteen holes ─────────────────────────────────────
do $patch$
declare v_def text; v_n integer; a text; b text; pairs text[][] := array[
  array[$x$select r.id, r.profile_id, r.gross, r.differential, r.index_at_post,$x$,
        $x$select r.id, r.profile_id, r.gross, r.differential, r.index_at_post, r.holes_played,  -- [S12] L-28$x$],
  array[$x$max(case when r.gross < 80 then 1 else 0 end)$x$,
        $x$max(case when r.gross < 80 and r.holes_played = 18 then 1 else 0 end)$x$],
  array[$x$(rk.gross < 80 and coalesce(rk.prior_sub80, 0) = 0),$x$,
        $x$(rk.gross < 80 and rk.holes_played = 18 and coalesce(rk.prior_sub80, 0) = 0),$x$]];
  i integer;
begin
  v_def := pg_get_functiondef('public.home_stories'::regproc);
  if position('[S12]' in v_def) > 0 then
    raise notice '[S12] home_stories already requires eighteen holes';
    return;
  end if;
  for i in 1 .. array_length(pairs, 1) loop
    a := pairs[i][1]; b := pairs[i][2];
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[S12] home_stories anchor % found % times', i, v_n; end if;
    v_def := replace(v_def, a, b);
  end loop;
  execute v_def;
end $patch$;

-- ── 2 · a solo season has no floor to promise ───────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$    participation_floor = coalesce(p_participation_floor, participation_floor),$a$;
begin
  v_def := pg_get_functiondef('public.lock_league'::regproc);
  if position('[S12]' in v_def) > 0 then
    raise notice '[S12] lock_league already stores no floor for solo';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[S12] lock_league floor anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      $b$    -- [S12] L-23 · an individual season assesses no minimum, so none is promised
    participation_floor = case when coalesce(p_structure, structure) = 'solo' then 0
                               else coalesce(p_participation_floor, participation_floor) end,$b$);
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[S12]' in pg_get_functiondef('public.home_stories'::regproc)) = 0
     or position('[S12]' in pg_get_functiondef('public.lock_league'::regproc)) = 0 then
    raise exception '[S12] a first-screen producer still says what is not so';
  end if;
  -- the earlier fixes in lock_league survive (D384, D347, R18, D378)
  if position('[D384]' in pg_get_functiondef('public.lock_league'::regproc)) = 0
     or position('counting_cap        = p_counting_cap' in pg_get_functiondef('public.lock_league'::regproc)) = 0 then
    raise exception '[S12] lock_league lost an earlier fix';
  end if;
end $chk$;
