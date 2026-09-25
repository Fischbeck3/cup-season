-- D384 (OWNER-RULED 2026-09-24) · launch audit S4, L-04.
-- A season shorter than six weeks is a points-table season.
--
-- Both clients told a Pro who picked 2–5 weeks that "the points leader at
-- season end wins" (index.html:5168 states the rule), then sent
-- p_finish = cup_final, which lock_league stored. The tick opens the Final at
-- ends_on − 27, so it opened on day 2 at 4 weeks, day 9 at 5 weeks and before
-- the first tee at 2–3 weeks, seeding by coin flip. On the real nightly tick
-- the engine crowned a 10-point coin-flip finalist over a 41-point leader.
--
-- Short = fewer than 42 days first tee to last day inclusive (the clients'
-- six weeks). The rule is enforced by LENGTH at the engine, so it holds for
-- season two too (run_it_back can mint a one-month season under a league whose
-- stored finish is cup_final): close_season plays the Final only when
-- cup_finalists exist, so a season the tick never takes into a Final is
-- crowned by the table.
--
--   1 · enter_cup_final and daily_season_tick skip a short season.
--   2 · lock_league stores points_table for a short first season.
--   3 · set_league_finish refuses the Cup Final for a short current season.
--   4 · seasons already in play (D384 §2): every live short season whose
--       league finish is cup_final becomes a points-table season with a board
--       post; one already in a coin-flip Final returns to active and its
--       finalists are cleared.

-- ── 1 · the engine never takes a short season into a Final ──────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$if (now() at time zone se.timezone)::date < se.ends_on - 27 then return; end if;        -- window not open$a$;
begin
  v_def := pg_get_functiondef('public.enter_cup_final'::regproc);
  if position('[D384]' in v_def) > 0 then
    raise notice '[D384] enter_cup_final already skips a short season';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D384] enter_cup_final anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n'
      || '  if se.ends_on - se.starts_on + 1 < 42 then return; end if;  -- [D384] under six weeks: the table decides');
  end if;
end $patch$;

do $patch$
declare v_def text; v_n integer;
  v_a text := $a$and v_local >= se.ends_on - 27 then$a$;
begin
  v_def := pg_get_functiondef('public.daily_season_tick'::regproc);
  if position('[D384]' in v_def) > 0 then
    raise notice '[D384] daily_season_tick already skips a short season';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D384] daily_season_tick anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$and v_local >= se.ends_on - 27
       and se.ends_on - se.starts_on + 1 >= 42 then  -- [D384] under six weeks: the table decides$b$);
  end if;
end $patch$;

-- ── 2 · lock_league stores what the Pro was told ────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$finish              = coalesce(p_finish, finish),$a$;
begin
  v_def := pg_get_functiondef('public.lock_league'::regproc);
  if position('[D384]' in v_def) > 0 then
    raise notice '[D384] lock_league already stores the table for a short season';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D384] lock_league anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$-- [D384] under six weeks the points table decides, whatever was sent
    finish              = case when v_ends - v_starts + 1 < 42 then 'points_table'
                               else coalesce(p_finish, finish) end,$b$);
  end if;
end $patch$;

-- ── 3 · set_league_finish refuses a Final the season has no room for ───────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  update league_settings set finish = p_finish where league_id = p_league;$a$;
begin
  v_def := pg_get_functiondef('public.set_league_finish'::regproc);
  if position('[D384]' in v_def) > 0 then
    raise notice '[D384] set_league_finish already refuses a short Final';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D384] set_league_finish anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a,
      $b$  -- [D384] a Final needs its four weeks and a regular season to seed from
  if p_finish = 'cup_final' and se.id is not null and se.ends_on - se.starts_on + 1 < 42 then
    raise exception 'A Cup Final needs a season of six weeks or more. This one is decided by the points table.';
  end if;
$b$ || v_a);
  end if;
end $patch$;

-- ── 4 · the seasons already in play (D384 §2) ───────────────────────────────
do $convert$
declare r record; v_n integer := 0; v_final integer := 0;
begin
  for r in
    select s.id, s.league_id, s.status, s.starts_on, s.ends_on
      from seasons s
      join league_settings ls on ls.league_id = s.league_id
     where s.status in ('active', 'cup_final')
       and s.ends_on - s.starts_on + 1 < 42
       and coalesce(ls.finish, 'cup_final') = 'cup_final'
       -- the league's current season only: an older live season under a
       -- league that has moved on is left for the operator
       and s.number = (select max(s2.number) from seasons s2 where s2.league_id = s.league_id)
  loop
    if r.status = 'cup_final' then
      delete from cup_finalists where season_id = r.id;
      update seasons set status = 'active' where id = r.id;
      v_final := v_final + 1;
    end if;
    update league_settings set finish = 'points_table' where league_id = r.league_id;
    insert into posts (league_id, season_id, kind, body)
    values (r.league_id, r.id, 'system',
            'This season runs under six weeks, so the points table decides it: the leader at season end wins. '
            || case when r.status = 'cup_final'
                    then 'The Cup Final seeds drawn for it are cleared, and every point already earned still counts. '
                    else '' end
            || 'A Cup Final needs four weeks of its own and a season to seed it.');
    v_n := v_n + 1;
  end loop;
  raise notice '[D384] % live short season(s) became points-table seasons; % of them left a coin-flip Final', v_n, v_final;
end $convert$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_n integer;
begin
  if position('[D384]' in pg_get_functiondef('public.enter_cup_final'::regproc)) = 0
     or position('[D384]' in pg_get_functiondef('public.daily_season_tick'::regproc)) = 0
     or position('[D384]' in pg_get_functiondef('public.lock_league'::regproc)) = 0
     or position('[D384]' in pg_get_functiondef('public.set_league_finish'::regproc)) = 0 then
    raise exception '[D384] a door still lets a short season into a Final';
  end if;
  select count(*) into v_n
    from seasons s join league_settings ls on ls.league_id = s.league_id
   where s.status in ('active', 'cup_final') and s.ends_on - s.starts_on + 1 < 42
     and coalesce(ls.finish, 'cup_final') = 'cup_final'
     and s.number = (select max(s2.number) from seasons s2 where s2.league_id = s.league_id);
  if v_n > 0 then raise exception '[D384] % live short season(s) still promise a Final', v_n; end if;
  -- earlier fixes in these bodies must survive (D347's literal cap, R18's note, D378's snake refusal)
  if position('counting_cap        = p_counting_cap' in pg_get_functiondef('public.lock_league'::regproc)) = 0
     or position('buy_in_note         = coalesce(v_note, buy_in_note)' in pg_get_functiondef('public.lock_league'::regproc)) = 0
     or position('Squads are drawn or placed by the Pro this season.' in pg_get_functiondef('public.lock_league'::regproc)) = 0 then
    raise exception '[D384] lock_league lost an earlier fix';
  end if;
end $chk$;
