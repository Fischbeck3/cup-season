-- ============================================================================
-- D141 · sandbox_scrap could not scrap a league that had closed a month
--
-- The D65 version deletes the league first, on the stated assumption that the
-- cascade "clears every no-action member_id reference before the users go".
-- That does not hold. Fourteen tables reference public.league_members with
-- ON DELETE NO ACTION, and seasons itself carries champion/runnerup/points_king
-- pointers at members and squads. The moment a sandbox league closes a month
-- with a floor penalty — i.e. the moment it becomes a season worth looking at —
-- season_adjustments holds a member_id, and the delete fails with
--
--   23503: update or delete on table "league_members" violates foreign key
--          constraint "season_adjustments_member_id_fkey"
--
-- Found by the season simulation study (2026-08-30), which hit exactly this
-- while tearing down its own footprint.
--
-- The fix clears children in dependency order, then the league graph, then the
-- bots. Behaviour is otherwise identical: same signature, same founder gate,
-- same sandbox-flag refusal, same return shape.
-- ============================================================================

create or replace function public.sandbox_scrap(p_league uuid)
returns jsonb
language plpgsql security definer set search_path = public as $fn$
declare v_bots uuid[]; v_n integer; v_seasons uuid[];
begin
  perform assert_sandbox(p_league, true);

  select coalesce(array_agg(p.id), '{}') into v_bots
    from league_members lm join profiles p on p.id = lm.profile_id
   where lm.league_id = p_league
     and p.email like '%@sandbox.cupseason.test';

  select coalesce(array_agg(s.id), '{}') into v_seasons
    from seasons s where s.league_id = p_league;

  -- 1. the seasons' own pointers at members and squads
  update seasons
     set champion_member_id = null, runnerup_member_id = null,
         points_king_member_id = null, champion_squad_id = null,
         runnerup_squad_id = null
   where id = any(v_seasons);

  -- 2. every child that references league_members / seasons / squads
  delete from season_adjustments   where season_id = any(v_seasons);
  delete from season_payouts       where season_id = any(v_seasons);
  delete from standings_snapshots  where season_id = any(v_seasons);
  delete from week_clashes         where season_id = any(v_seasons);
  delete from cup_finalists        where season_id = any(v_seasons);
  delete from buy_ins              where season_id = any(v_seasons);
  delete from season_lead          where season_id = any(v_seasons);

  delete from post_comments where post_id in
         (select id from posts where league_id = p_league);
  delete from posts            where league_id = p_league;
  delete from commissioner_log where league_id = p_league;
  delete from trophies         where league_id = p_league;
  delete from scheduled_rounds where league_id = p_league;
  delete from events           where league_id = p_league;
  delete from member_invites   where league_id = p_league;
  delete from feedback where member_id in
         (select id from league_members where league_id = p_league);

  -- 3. the league graph (seasons, league_members, squads, squad_members cascade)
  delete from leagues where id = p_league;

  -- 4. the bots: auth.users -> profiles cascade takes their rounds with them
  delete from auth.users where id = any(v_bots);
  get diagnostics v_n = row_count;

  return jsonb_build_object('scrapped', true, 'bots_removed', v_n);
end $fn$;

-- D37: grants are explicit, and every new function revokes the ambient ones first
revoke all on function public.sandbox_scrap(uuid) from public, anon;
grant execute on function public.sandbox_scrap(uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'sandbox_scrap' and pronamespace = 'public'::regnamespace;
  if position('season_adjustments' in v_src) = 0 then
    raise exception 'D141: sandbox_scrap does not clear season_adjustments — the FK will still block it';
  end if;
  if position('champion_member_id' in v_src) = 0 then
    raise exception 'D141: sandbox_scrap does not clear the season champion pointers';
  end if;
  if has_function_privilege('anon', 'public.sandbox_scrap(uuid)', 'execute') then
    raise exception 'D141: anon can execute sandbox_scrap';
  end if;
end $$;
