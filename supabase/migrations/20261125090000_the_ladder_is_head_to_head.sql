-- D388 (OWNER-RULED 2026-09-24) · launch audit S9, L-11 + L-29 (one coin).
-- Ties are broken by §14.3's ladder everywhere, with floor penalties counted
-- in their month.
--
-- §14.3: "h2h months won → best single month → fewest rounds used → logged
-- coin flip". §3.3: "Squad month = Σ counting-round points − penalties". The
-- engine counted a month as won when a contender beat the WHOLE FIELD, not the
-- contenders it was tied with, and summed counting points only. It decided
-- squads3/4 seeds and crowns, solo seeds and points-table crowns with 3+
-- golfers, and the Points King in every league with 3+ members (L-11). And the
-- champion and Points King ladders drew independent coins, so one tie could
-- be flipped two ways (L-29: champion ≠ King 19/40).
--
-- The ladder's order is untouched; its first two rungs now read a month score
-- that is §3.3's (squads: counting points plus that month's floor_penalty and
-- floor_forfeit rows, which are stored negative; individuals: counting points,
-- as there is no individual penalty), and "months won" means months in which
-- the contender scored strictly more than every contender TIED WITH IT on
-- points (head to head; with three or more tied, highest among them). This is
-- computed after each ladder's scores are final, because close_season's
-- points-table branch replaces the score with the standings after the insert.
-- One coin per contender per close is shared by the champion and King ladders.
--
-- Patched from the LIVE bodies by anchor, each anchor asserted once.

-- ── 1 · close_season: the crown ladder and the King ladder ──────────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.close_season'::regproc);
  if position('[D388]' in v_def) > 0 then
    raise notice '[D388] close_season already reads the head-to-head ladder';
  else
    -- 1a · before the crown is read: month scores, h2h months won, one coin
    v_a := E'  select * into c1 from _ranked\n';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D388] close_season crown anchor found % times', v_n; end if;
    v_def := replace(v_def, v_a, $b$  -- [D388] §14.3/§3.3: the month score and head-to-head months won, read
  -- after the scores are final; one coin per contender for this close
  drop table if exists _mon; drop table if exists _coin;
  create temp table _mon on commit drop as
    select cid, mon, sum(mpts)::numeric as mpts from (
      select c.cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points)::numeric as mpts
        from _cont c
        join v_rounds_ranked rr on rr.season_id = p_season and rr.member_id = c.member_id
                               and rr.month_rank <= cap_n
       group by 1, 2
      union all
      select a.squad_id, date_trunc('month', a.month)::date, sum(a.points)::numeric
        from season_adjustments a
       where not v_solo and a.season_id = p_season and a.kind in ('floor_penalty', 'floor_forfeit')
         and a.squad_id in (select cid from _cont)
       group by 1, 2
    ) x group by 1, 2;
  update _ranked r set
    months_won = (select count(*) from _mon m
                   where m.cid = r.cid
                     and exists (select 1 from _ranked t where t.score = r.score and t.cid <> r.cid)
                     and m.mpts > coalesce((select max(m2.mpts) from _mon m2 join _ranked t2 on t2.cid = m2.cid
                                            where m2.mon = m.mon and t2.score = r.score and t2.cid <> r.cid), 0)),
    best_month = coalesce((select max(m.mpts) from _mon m where m.cid = r.cid), 0);
  create temp table _coin (id uuid primary key, coin double precision) on commit drop;
  insert into _coin select cid, coin from _ranked on conflict do nothing;

$b$ || v_a);

    -- 1b · the King: individual month scores, h2h among the tied, the shared coin
    v_a := E'  select * into k1 from _king\n';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D388] close_season king anchor found % times', v_n; end if;
    v_def := replace(v_def, v_a, $b$  -- [D388] the King on the same head-to-head ladder, and the SAME coin as the
  -- crown where the same golfer stands in both (L-29: one coin per tie)
  drop table if exists _kmon;
  create temp table _kmon on commit drop as
    select rr.member_id as cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points)::numeric as mpts
      from v_rounds_ranked rr
     where rr.season_id = p_season and rr.month_rank <= cap_n
     group by 1, 2;
  update _king k set
    months_won = (select count(*) from _kmon m
                   where m.cid = k.member_id
                     and exists (select 1 from _king t where t.score = k.score and t.member_id <> k.member_id)
                     and m.mpts > coalesce((select max(m2.mpts) from _kmon m2 join _king t2 on t2.member_id = m2.cid
                                            where m2.mon = m.mon and t2.score = k.score and t2.member_id <> k.member_id), 0)),
    best_month = coalesce((select max(m.mpts) from _kmon m where m.cid = k.member_id), 0);
  insert into _coin select member_id, coin from _king on conflict do nothing;
  update _king k set coin = c.coin from _coin c where c.id = k.member_id;

$b$ || v_a);
    execute v_def;
  end if;
end $patch$;

-- ── 2 · enter_cup_final: the seeds ──────────────────────────────────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.enter_cup_final'::regproc);
  if position('[D388]' in v_def) > 0 then
    raise notice '[D388] enter_cup_final already reads the head-to-head ladder';
  else
    v_a := E'  update _seed s set rk = x.rk\n';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D388] enter_cup_final anchor found % times', v_n; end if;
    v_def := replace(v_def, v_a, $b$  -- [D388] §14.3/§3.3 over the regular season: month scores net of that
  -- month's floor penalties (squads), months won head to head among the tied
  drop table if exists _smon;
  create temp table _smon on commit drop as
    select cid, mon, sum(mpts)::numeric as mpts from (
      select c.cid, date_trunc('month', rr.played_on)::date as mon, sum(rr.points)::numeric as mpts
        from _sc c
        join v_rounds_ranked rr on rr.season_id = p_season and rr.member_id = c.member_id
                               and rr.month_rank <= cap_n and rr.played_on < cf_start
       group by 1, 2
      union all
      select a.squad_id, date_trunc('month', a.month)::date, sum(a.points)::numeric
        from season_adjustments a
       where st.structure <> 'solo' and a.season_id = p_season
         and a.kind in ('floor_penalty', 'floor_forfeit') and a.month < cf_start
         and a.squad_id in (select cid from _sc)
       group by 1, 2
    ) x group by 1, 2;
  update _seed s set
    months_won = (select count(*) from _smon m
                   where m.cid = s.cid
                     and exists (select 1 from _seed t where t.score = s.score and t.cid <> s.cid)
                     and m.mpts > coalesce((select max(m2.mpts) from _smon m2 join _seed t2 on t2.cid = m2.cid
                                            where m2.mon = m.mon and t2.score = s.score and t2.cid <> s.cid), 0)),
    best_month = coalesce((select max(m.mpts) from _smon m where m.cid = s.cid), 0);

$b$ || v_a);
    execute v_def;
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[D388]' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('_coin' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('[D388]' in pg_get_functiondef('public.enter_cup_final'::regproc)) = 0 then
    raise exception '[D388] a ladder still counts months against the whole field';
  end if;
  -- earlier fixes in these bodies survive (D105's shared window, D384's length guard)
  if position('_cup_window_rounds(p_season)' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('[D384]' in pg_get_functiondef('public.enter_cup_final'::regproc)) = 0 then
    raise exception '[D388] an earlier fix was lost';
  end if;
end $chk$;
