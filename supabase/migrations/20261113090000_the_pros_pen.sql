-- ============================================================================
-- Cup Season · 20261113090000 · the Pro's pen
--
-- D376 (owner-ruled 2026-09-21, "A, built before Oct 1"; entry reserved in
-- docs/planning/2026-09-21-launch-rulings.md until PR #6 merges). Spec §16
-- says adjustments live in a ledger with reasons; D50 says every ruling is a
-- logged entry, visible to the whole league; CLAUDE.md says rounds are
-- immutable. Until now the only writers of `season_adjustments` were the
-- engine — close_month, set_member_bye, the wizard defaults, start_season — so
-- the Pro had a ledger with reasons and no pen. One migration, three parts:
--
--   1. `adjust_points(p_season, p_member, p_delta, p_reason, p_month)` — the
--      commissioner's ruling: a `kind = 'override'` ledger row with a required
--      reason, one natural-case board post (D165), one commissioner_log row.
--      Never a round edit and never a delete (D37, D125, D284); the member is
--      resolved through league_members/seasons, never through squads, which
--      is what kept set_member_bye from working in a solo league.
--   2. `v_individual_standings` learns to read `override` rows keyed by
--      member, so a ruling in a solo league — the only kind real leagues are
--      (D205) — reaches the total, the King and league_pulse. v_squad_standings
--      already sums every squad-keyed row, so one ruling moves both totals and
--      no view counts it twice. Columns are unchanged; every reader keeps
--      reading.
--   3. The Cup Final: the pen refuses while `seasons.status in ('cup_final',
--      'complete')`. `cup_final_race` scores the window fresh and reads no
--      ledger row, so a ruling there would show work the table does not do;
--      the covenant says a ruling in the Final is settled by the crew.
--
-- D43 guard: the redefinition must retro-flip nothing. The check below RAISES
-- if any override row with a member already exists, so the owner looks before
-- a table moves. (No writer has ever produced one; D140 read zero.)
--
-- Spec §9 is amended by the decision entry from "void/edit any round, every
-- override logged" to "adjust the points, in the ledger, with a reason,
-- league-scoped". Round-level void stays with D125 stage 2.
--
-- VERIFY: tests/sim/sandbox/apply.sh; the self-check at the foot; db-check 35
-- after the push. Clients (D234): the desk's Pro sheet beside the Bye button
-- and the phone's MembersSheet — both call this one RPC; `tools/build-db.mjs`
-- carries the contract row.
-- ============================================================================

-- ── D43 guard · nothing already in the ledger may start counting ────────────
do $guard$
declare v_n integer;
begin
  select count(*) into v_n from season_adjustments where kind = 'override' and member_id is not null;
  if v_n > 0 then
    raise exception '[D376] % pre-existing override row(s) carry a member and would begin to count in v_individual_standings — inspect them before this migration runs', v_n;
  end if;
end $guard$;

-- ── 1 · the pen ──────────────────────────────────────────────────────────────
create or replace function public.adjust_points(
  p_season uuid,
  p_member uuid,
  p_delta  integer,
  p_reason text,
  p_month  date default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  se       seasons%rowtype;
  v_league uuid;
  v_me     uuid;
  v_sqid   uuid;
  v_name   text;
  v_mon    date;
  v_reason text;
  v_id     uuid;
  v_total  bigint;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'No such season.'; end if;
  v_league := se.league_id;

  if not is_commissioner(v_league) then
    raise exception 'Only the Pro can make a ruling.';
  end if;
  -- 3 · the Final is scored fresh and reads no ledger row (cup_final_race);
  --     a ruling there would show work the table does not do.
  if se.status in ('cup_final', 'complete') then
    raise exception 'The ledger closed when the Final window opened. A ruling in the Final is settled by the crew.';
  end if;

  if p_delta is null or p_delta = 0 or abs(p_delta) > 50 then
    raise exception 'A ruling moves between 1 and 50 points, up or down.';
  end if;
  v_reason := nullif(btrim(coalesce(p_reason, '')), '');
  if v_reason is null or length(v_reason) < 3 then
    raise exception 'Say why — a ruling carries its reason.';
  end if;
  v_reason := left(v_reason, 240);

  -- the member is seated in THIS league (never resolved through squads — a
  -- solo league has none, which is what kept set_member_bye from working there)
  if not exists (select 1 from league_members lm where lm.id = p_member and lm.league_id = v_league) then
    raise exception 'That golfer is not in this league.';
  end if;

  v_me  := my_member_id(v_league);
  v_mon := date_trunc('month', coalesce(p_month, (now() at time zone se.timezone)::date))::date;
  if v_mon < date_trunc('month', se.starts_on)::date or v_mon > se.ends_on then
    raise exception 'That month is outside this season.';
  end if;

  -- the squad, when there is one, so v_squad_standings sums it too
  select sq.id into v_sqid
    from squads sq join squad_members sm on sm.squad_id = sq.id
   where sm.member_id = p_member and sq.season_id = p_season
   limit 1;
  select p.display_name into v_name
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.id = p_member;

  insert into season_adjustments (season_id, squad_id, member_id, month, kind, points, reason, created_by)
  values (p_season, v_sqid, p_member, v_mon, 'override', p_delta, v_reason, v_me)
  returning id into v_id;

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (v_league, v_me, 'adjust_points',
          jsonb_build_object('adjustment', v_id, 'season', p_season, 'member', p_member,
                             'month', v_mon, 'points', p_delta, 'reason', v_reason));

  -- D50 · visible to the whole league, in the board's natural case (D165)
  insert into posts (league_id, season_id, kind, member_id, body)
  values (v_league, p_season, 'system', v_me,
          'The Pro ruled: ' || coalesce(v_name, 'a member')
          || case when p_delta > 0 then ' +' else ' −' end || abs(p_delta)
          || case when abs(p_delta) = 1 then ' point' else ' points' end
          || ' for ' || to_char(v_mon, 'FMMonth') || ' — ' || v_reason
          || case when right(v_reason, 1) in ('.', '!', '?') then '' else '.' end);

  select points into v_total from v_individual_standings
   where season_id = p_season and member_id = p_member;

  return jsonb_build_object(
    'adjustment_id', v_id, 'season_id', p_season, 'member_id', p_member,
    'points', p_delta, 'month', v_mon, 'reason', v_reason,
    'member_total', v_total, 'squad_id', v_sqid);
end $$;
revoke all on function public.adjust_points(uuid, uuid, integer, text, date) from public, anon;
grant execute on function public.adjust_points(uuid, uuid, integer, text, date) to authenticated;

-- ── 2 · the individual table reads the ledger ────────────────────────────────
-- Same columns, same order, same types as the baseline view (bigint points,
-- bigint rounds_posted); only `override` rows keyed by member are added, so
-- bye / floor rows keep exactly the meaning they have today.
create or replace view public.v_individual_standings with (security_invoker = 'true') as
 with adj as (
   select a.season_id, a.member_id, coalesce(sum(a.points), 0)::bigint as pts
     from public.season_adjustments a
    where a.member_id is not null and a.kind = 'override'
    group by a.season_id, a.member_id
 )
 select lm.id as member_id,
        s.id  as season_id,
        (coalesce(sum(rr.points) filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0::bigint)
         + coalesce(max(adj.pts), 0::bigint)) as points,
        count(rr.round_id) as rounds_posted
   from public.league_members lm
   join public.seasons s          on s.league_id = lm.league_id
   join public.league_settings ls on ls.league_id = lm.league_id
   left join public.v_rounds_ranked rr on rr.member_id = lm.id and rr.season_id = s.id
   left join adj on adj.season_id = s.id and adj.member_id = lm.id
  group by lm.id, s.id;

-- ── self-check (read-only; mutates no row) ───────────────────────────────────
do $chk$
declare v_src text; v_n integer;
begin
  select prosrc into v_src from pg_proc where proname = 'adjust_points' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception '[D376] adjust_points is missing'; end if;
  if v_src not like '%is_commissioner(v_league)%' then raise exception '[D376] the pen is not commissioner-gated'; end if;
  if v_src not like '%''cup_final'', ''complete''%' then raise exception '[D376] the pen does not refuse the Final'; end if;
  if v_src not like '%''override''%' or v_src not like '%commissioner_log%' or v_src not like '%insert into posts%' then
    raise exception '[D376] a ruling must be a ledger row, a log row and a board post';
  end if;
  if v_src like '%delete from rounds%' or v_src like '%update rounds%' then
    raise exception '[D376] the pen must never touch a round (D37, D125, D284)';
  end if;
  if not exists (select 1 from pg_proc p where p.proname = 'adjust_points' and p.pronamespace = 'public'::regnamespace
                    and has_function_privilege('authenticated', p.oid, 'execute')
                    and not has_function_privilege('anon', p.oid, 'execute')) then
    raise exception '[D376] adjust_points is wrongly granted';
  end if;

  -- the view: same shape, reads the ledger, still invoker-secured
  select count(*) into v_n from information_schema.columns
   where table_schema = 'public' and table_name = 'v_individual_standings';
  if v_n <> 4 then raise exception '[D376] v_individual_standings has % columns; expected 4', v_n; end if;
  select pg_get_viewdef('public.v_individual_standings'::regclass) into v_src;
  if v_src not like '%season_adjustments%' or v_src not like '%''override''%' then
    raise exception '[D376] v_individual_standings does not read the ledger';
  end if;
  if not exists (select 1 from pg_class c where c.oid = 'public.v_individual_standings'::regclass
                    and 'security_invoker=true' = any(c.reloptions)) then
    raise exception '[D376] v_individual_standings lost security_invoker';
  end if;
  -- every existing total is unchanged by construction: no override row has a member (the guard above)
  select count(*) into v_n from season_adjustments where kind = 'override' and member_id is not null;
  if v_n <> 0 then raise exception '[D376] % override row(s) appeared during the migration', v_n; end if;
end $chk$;
