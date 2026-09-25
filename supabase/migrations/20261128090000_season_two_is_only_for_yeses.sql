-- D389 (OWNER-RULED 2026-09-24) · launch audit S11, database half · L-18.
-- Season two is only for yeses, and an invitation to it lapses at its first tee.
--
-- L-18 · season two leaked to people who were not in it: re-up invitations
-- never lapsed; the week's clash paired members who had not said yes to the
-- season (open_week_clash read the whole league); and the settlement post named
-- people who declined or never answered as owing money (close_season's owed
-- list read the whole league). D375 says season two holds only yeses.
--
--   1 · member_invites gains the status 'lapsed'.
--   2 · the tick, at a season's first tee, lapses the pending RE-UP invitations
--       (to golfers already in the league, for season two onward). A Pro's
--       invitation to a new golfer once under way is how a late joiner comes
--       in (D386) and is left alone.
--   3 · open_week_clash pairs, and counts, the season's roster only.
--   4 · the settlement's "still owed" names the season's roster only.

-- ── 1 · a status for an invitation nobody answered in time ──────────────────
do $c$
declare v_name text;
begin
  select conname into v_name from pg_constraint
   where conrelid = 'public.member_invites'::regclass and contype = 'c'
     and pg_get_constraintdef(oid) like '%pending%accepted%declined%';
  if v_name is not null then
    execute format('alter table public.member_invites drop constraint %I', v_name);
  end if;
  alter table public.member_invites add constraint member_invites_status_check
    check (status in ('pending', 'accepted', 'declined', 'lapsed'));
end $c$;

-- ── 2 · the first tee lapses what nobody answered ───────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$      update seasons set kicked_off = true where id = se.id;$a$;
begin
  v_def := pg_get_functiondef('public.daily_season_tick'::regproc);
  if position('[D389]' in v_def) > 0 then
    raise notice '[D389] daily_season_tick already lapses re-up invitations';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D389] tick anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n' || $b$      -- [D389] a re-up invitation lapses at the first tee it was for; a Pro's
      -- invitation to a NEW golfer (the late-joiner door, D386) does not
      if se.number > 1 then
        update member_invites mi set status = 'lapsed'
         where mi.league_id = se.league_id and mi.status = 'pending'
           and exists (select 1 from league_members lm
                        where lm.league_id = se.league_id and lm.profile_id = mi.profile_id);
      end if;$b$);
  end if;
end $patch$;

-- ── 3 · the clash is between people in the season ───────────────────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.open_week_clash'::regproc);
  if position('[D389]' in v_def) > 0 then
    raise notice '[D389] open_week_clash already reads the season roster';
    return;
  end if;
  v_a := E'     where lm.league_id = se.league_id\n  ),\n  feat as';
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D389] clash pairing anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a,
    E'     where lm.league_id = se.league_id\n'
    || E'       and lm.id in (select member_id from _season_roster(p_season))  -- [D389] only the yeses\n'
    || E'  ),\n  feat as');
  v_a := E'   where lm.league_id = se.league_id\n     and lm.suspended_at is null;';
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D389] clash roster-count anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a,
    E'   where lm.league_id = se.league_id\n     and lm.suspended_at is null\n'
    || E'     and lm.id in (select member_id from _season_roster(p_season));  -- [D389]');
  execute v_def;
end $patch$;

-- ── 4 · nobody outside the season is named as owing ─────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := E'     where lm.league_id = se.league_id\n       and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);';
begin
  v_def := pg_get_functiondef('public.close_season'::regproc);
  if position('[D389]' in v_def) > 0 then
    raise notice '[D389] close_season already names only the roster';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D389] owed-list anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      E'     where lm.league_id = se.league_id\n'
      || E'       and lm.id in (select member_id from _season_roster(p_season))  -- [D389] only the yeses owe\n'
      || E'       and not exists (select 1 from buy_ins b where b.season_id = p_season and b.member_id = lm.id and b.paid);');
  end if;
end $patch$;

-- ── 5 · native_home says whether the golfer is IN the current season ────────
-- Both clients built "Live · You're in it" from the league's phase alone. The
-- membership row now carries `in_season` (season one, or a yes on record for
-- the season it describes); the web reads the same fact from agreed_seasons.
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$      'member_id',         m.member_id,$a$;
begin
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('[D389]' in v_def) > 0 then
    raise notice '[D389] native_home already says in_season';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D389] native_home member anchor found % times', v_n; end if;
    execute replace(v_def, v_a, v_a || E'\n' || $b$      -- [D389] L-18 · a season-two surface asks this before saying "you're in it"
      'in_season',         coalesce((v_season->>'number')::int, 1) <= 1
                           or exists (select 1 from league_members lmx where lmx.id = m.member_id
                                        and (v_season->>'number')::int = any(lmx.agreed_seasons)),$b$);
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[D389]' in pg_get_functiondef('public.daily_season_tick'::regproc)) = 0
     or position('[D389]' in pg_get_functiondef('public.open_week_clash'::regproc)) = 0
     or position('[D389]' in pg_get_functiondef('public.close_season'::regproc)) = 0 then
    raise exception '[D389] a season-two surface still reads the whole league';
  end if;
  -- the earlier fixes in these bodies survive
  if position('[D384]' in pg_get_functiondef('public.daily_season_tick'::regproc)) = 0
     or position('[D388]' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('_dollars(' in pg_get_functiondef('public.close_season'::regproc)) = 0 then
    raise exception '[D389] an earlier fix was lost';
  end if;
end $chk$;
