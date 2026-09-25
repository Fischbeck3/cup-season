-- D387 (OWNER-RULED 2026-09-24) · launch audit S10, database half · L-12 + L-14.
-- The receipt explains each league's verdict with that league's own number, and
-- Home names the champion.
--
-- L-12 · round_card's scalars fell back to `index_at_post − differential`
-- (a 100% allowance) whenever the round had no single lens, so for a golfer
-- in two leagues the receipt said "+2.5" while the engine, Home and the band
-- used the league's playing index ("by 2.0") — seen on the owner's own rounds
-- on 986. D387: with a league in context the scalars are that league's (as
-- before); with none, they are the lenses' own number (the lower when leagues
-- differ: D324's rule), never a number no league scored. Only a round in no
-- league at all keeps the golfer's own index − differential.
--
-- L-14 · Home never named the champion after a crown. native_home's
-- last-season block joined `league_members.squad_id`, a column that does not
-- exist (the error was swallowed, so every squad league's block was null), and
-- excluded the season that had just finished, which is the only one Home has
-- to name the morning after. It now joins through squad_members, includes the
-- just-finished season, and carries the runner-up, the Points King and the pot.

-- ── 1 · round_card: the number a league scored ──────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  v_pvi := coalesce((v_lens->>'pvi')::numeric, r.index_at_post - r.differential);$a$;
begin
  v_def := pg_get_functiondef('public.round_card'::regproc);
  if position('[D387]' in v_def) > 0 then
    raise notice '[D387] round_card already reads the lens number';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D387] round_card anchor found % times', v_n; end if;
    execute replace(v_def, v_a, $b$  -- [D387] the lens's own number: the explicit league's; with none, the
  -- lenses' (the lower when leagues differ, D324); only a round in no league
  -- falls back to the golfer's own index − differential
  v_pvi := coalesce((v_lens->>'pvi')::numeric,
                    (select min((c->>'pvi')::numeric) from jsonb_array_elements(v_contrib) c),
                    r.index_at_post - r.differential);$b$);
  end if;
end $patch$;

-- ── 2 · native_home: the season that just finished names its champion ──────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('[D387]' in v_def) > 0 then
    raise notice '[D387] native_home already names the champion';
    return;
  end if;

  v_a := $a$                            else exists (select 1 from squads sq8
                                          join league_members lm9 on lm9.squad_id = sq8.id
                                         where sq8.id = s2.champion_squad_id
                                           and lm9.profile_id = v)$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D387] champion_is_me anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a, $b$                            else exists (select 1 from squad_members sm8   -- [D387] L-14: the seat, not a column that never existed
                                          join league_members lm9 on lm9.id = sm8.member_id
                                         where sm8.squad_id = s2.champion_squad_id
                                           and lm9.profile_id = v)$b$);

  v_a := $a$        'of',             case
                            when v_solo then (select count(*)::int from v_individual_standings vi
                                               where vi.season_id = s2.id)
                            else null::int
                          end)
      into v_last$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D387] last-season tail anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a, $b$        'of',             case
                            when v_solo then (select count(*)::int from v_individual_standings vi
                                               where vi.season_id = s2.id)
                            else null::int
                          end,
        -- [D387] L-14 · the rest of the Trophy Room's facts (§14.4)
        'season_id',      s2.id,
        'runner_up_name', case
                            when v_solo then (select firstname(p9.display_name) from league_members lm10
                                                join profiles p9 on p9.id = lm10.profile_id
                                               where lm10.id = s2.runnerup_member_id)
                            else (select sq9.name from squads sq9 where sq9.id = s2.runnerup_squad_id)
                          end,
        'king_name',      (select firstname(p10.display_name) from league_members lm11
                             join profiles p10 on p10.id = lm11.profile_id
                            where lm11.id = s2.points_king_member_id),
        'king_is_me',     exists (select 1 from league_members lm12
                                   where lm12.id = s2.points_king_member_id and lm12.profile_id = v),
        'pot_cents',      s2.pot_cents,
        'collected_cents', s2.collected_cents)
      into v_last$b$);

  v_a := $a$        and (v_season_id is null or s2.id <> v_season_id)$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D387] current-season exclusion anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a,
    $b$        -- [D387] L-14 · the season that just finished is the one Home names$b$);

  execute v_def;
end $patch$;

-- ── 3 · the settlement post says the ledger's money (L-29, D387) ────────────
-- close_season printed each share rounded to whole dollars ($90 + $38 + $23 on
-- a $150 pot) while the ledger (recompute_season_payouts) is right to the cent.
-- The post now prints the ledger's amounts: whole dollars when whole, cents
-- when not.
create or replace function public._dollars(p_cents numeric)
returns text language sql immutable set search_path = public
as $$ select case when p_cents is null then '0'
                  when p_cents % 100 = 0 then (p_cents / 100)::bigint::text
                  else to_char(p_cents / 100.0, 'FM999999990.00') end $$;
revoke all on function public._dollars(numeric) from public, anon, authenticated;

do $patch$
declare v_def text; v_n integer; a text; b text; pairs text[][] := array[
  array[$x$round((v_money->>'pot_cents')::numeric / 100.0)$x$,       $x$_dollars((v_money->>'pot_cents')::numeric)$x$],
  array[$x$round((v_money->>'collected_cents')::numeric / 100.0)$x$, $x$_dollars((v_money->>'collected_cents')::numeric)$x$],
  array[$x$round((v_money->>'champ')::numeric  / 100.0)$x$,          $x$_dollars((v_money->>'champ')::numeric)$x$],
  array[$x$round((v_money->>'runner')::numeric / 100.0)$x$,          $x$_dollars((v_money->>'runner')::numeric)$x$],
  array[$x$round((v_money->>'king')::numeric   / 100.0)$x$,          $x$_dollars((v_money->>'king')::numeric)$x$],
  array[$x$round(((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric) / 100.0)$x$,
        $x$_dollars((v_money->>'pot_cents')::numeric - (v_money->>'collected_cents')::numeric)$x$]];
  i integer;
begin
  v_def := pg_get_functiondef('public.close_season'::regproc);
  if position('_dollars(' in v_def) > 0 then
    raise notice '[D387] close_season already prints the ledger''s money';
    return;
  end if;
  for i in 1 .. array_length(pairs, 1) loop
    a := pairs[i][1]; b := pairs[i][2];
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[D387] settlement anchor % found % times', i, v_n; end if;
    v_def := replace(v_def, a, b);
  end loop;
  execute v_def;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_def text;
begin
  if position('[D387]' in pg_get_functiondef('public.round_card'::regproc)) = 0 then
    raise exception '[D387] round_card still explains with a number no league scored';
  end if;
  v_def := pg_get_functiondef('public.native_home'::regproc);
  if position('lm9.squad_id' in v_def) > 0 then
    raise exception '[D387] native_home still joins a column that does not exist';
  end if;
  if position('[D387]' in v_def) = 0 or position('[S3]' in v_def) = 0 then
    raise exception '[D387] native_home lost this fix or S3''s';
  end if;
  if position('/ 100.0)' in pg_get_functiondef('public.close_season'::regproc)) > 0 then
    raise exception '[D387] the settlement post still rounds the money';
  end if;
  if position('[D388]' in pg_get_functiondef('public.close_season'::regproc)) = 0 then
    raise exception '[D387] close_season lost D388';
  end if;
end $chk$;
