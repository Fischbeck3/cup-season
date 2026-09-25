-- D382 (OWNER-RULED 2026-09-24) · launch audit S1, L-01.
-- The record book has one door.
--
-- Every legitimate change to a season, its ledger, its squads, its pot and the
-- Pro's log runs through a SECURITY DEFINER RPC that checks, logs and posts.
-- The baseline left the older doors open beside them: seven RLS write policies
-- keyed only on is_commissioner(), and authenticated/anon holding
-- INSERT/UPDATE/DELETE on every table (00000000000000_initial_baseline.sql
-- :1981 :2006 :2014 :2156 :2305 :2333 :2349, grants :2746–:2904). With her own
-- session and the public key a Pro could PATCH or DELETE a completed season,
-- reopen it for the tick to re-crown, insert reason-less ledger rows (the
-- month_closed sentinel among them), rewrite squads and buy-ins, change the
-- league's phase or Pro, and write log lines in her own name.
--
-- No shipped client uses those doors: iOS only reads these tables, and the
-- web's one use (the pre-D111 lock fallback) is deleted in the same change.
-- Definer functions run as their owner and are unaffected by the revokes.
--
-- Also here: assign_player gets its phase rule (D382 §2). It checked only that
-- the caller was the Pro, so one call inside a Cup Final changed who
-- close_season crowned, and it would seat a member of another league.
--
-- SELECT is left exactly as it is. leagues keeps INSERT (leagues_create binds
-- the row to its creator; creation runs through create_league_once).
-- league_settings is untouched: settings_write already refuses once locked_at
-- is set, and the wizard writes the bylaws only through lock_league.

-- ── 1 · the doors ───────────────────────────────────────────────────────────
drop policy if exists seasons_write  on public.seasons;
drop policy if exists adj_write      on public.season_adjustments;
drop policy if exists squads_write   on public.squads;
drop policy if exists squadm_write   on public.squad_members;
drop policy if exists buyins_write   on public.buy_ins;
drop policy if exists leagues_update on public.leagues;
drop policy if exists clog_add       on public.commissioner_log;

revoke insert, update, delete on table
  public.seasons, public.season_adjustments, public.squads,
  public.squad_members, public.buy_ins, public.commissioner_log
  from authenticated, anon;
revoke update, delete on table public.leagues from authenticated, anon;

-- ── 2 · assign_player: a seat moves only before the start ──────────────────
-- Built on 20261012090000's body (the D296 wording 'Only the Pro can do that.'
-- is kept; that migration's self-check pins it).
CREATE OR REPLACE FUNCTION public.assign_player(p_squad uuid, p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; v_started boolean; v_seated boolean;
begin
  select s.* into se from seasons s
  join squads q on q.season_id = s.id where q.id = p_squad;
  if se.id is null then raise exception 'no such squad'; end if;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;

  -- D382 · the squads a Final was drawn from are the squads it is played by
  if se.status in ('cup_final', 'complete') then
    raise exception 'The squads are set for good: this season is in its Final or finished.';
  end if;
  if not exists (select 1 from league_members
                  where id = p_member and league_id = se.league_id) then
    raise exception 'That golfer isn''t in this league.';
  end if;

  v_started := se.kicked_off
            or (now() at time zone coalesce(se.timezone, 'America/Phoenix'))::date >= se.starts_on;
  v_seated := exists (select 1 from squad_members sm join squads q on q.id = sm.squad_id
                       where q.season_id = se.id and sm.member_id = p_member);
  -- D382 · once the season is under way, a seat is given, never moved
  if v_started and v_seated then
    raise exception 'The season has started, so squads are set. You can seat a golfer who has no squad yet.';
  end if;

  -- moving a player (before the start only): clear any prior seat, then seat them
  delete from squad_members sm using squads q
  where q.id = sm.squad_id and q.season_id = se.id and sm.member_id = p_member;
  insert into squad_members (squad_id, member_id) values (p_squad, p_member);

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (se.league_id, my_member_id(se.league_id), 'assign_player',
          jsonb_build_object('squad', p_squad, 'member', p_member, 'started', v_started));
end $function$;
revoke all on function public.assign_player(p_squad uuid, p_member uuid) from public, anon;
grant execute on function public.assign_player(p_squad uuid, p_member uuid) to authenticated;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_bad text; v_src text;
begin
  select string_agg(format('%s:%s:%s', c.relname, a.grantee::regrole, a.privilege_type), ', ')
    into v_bad
    from pg_class c, lateral aclexplode(c.relacl) a
   where c.oid in ('public.seasons'::regclass, 'public.season_adjustments'::regclass,
                   'public.squads'::regclass, 'public.squad_members'::regclass,
                   'public.buy_ins'::regclass, 'public.commissioner_log'::regclass,
                   'public.leagues'::regclass)
     and a.grantee <> 0
     and a.grantee::regrole::text in ('authenticated', 'anon')
     and a.privilege_type in ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
     and not (c.relname = 'leagues' and a.privilege_type = 'INSERT');
  if v_bad is not null then
    raise exception '[D382] a client role still writes the record book: %', left(v_bad, 400);
  end if;

  select string_agg(format('%s.%s', tablename, policyname), ', ') into v_bad
    from pg_policies
   where schemaname = 'public'
     and tablename in ('seasons', 'season_adjustments', 'squads', 'squad_members',
                       'buy_ins', 'commissioner_log', 'leagues')
     and cmd <> 'SELECT'
     and not (tablename = 'leagues' and cmd = 'INSERT');
  if v_bad is not null then
    raise exception '[D382] a write policy survives: %', v_bad;
  end if;

  -- the reads the clients depend on must survive
  if not has_table_privilege('authenticated', 'public.seasons', 'SELECT')
     or not has_table_privilege('authenticated', 'public.squad_members', 'SELECT')
     or not has_table_privilege('authenticated', 'public.season_adjustments', 'SELECT') then
    raise exception '[D382] a read the clients need was lost';
  end if;
  if not has_table_privilege('authenticated', 'public.leagues', 'INSERT') then
    raise exception '[D382] leagues lost INSERT, which this migration never meant to touch';
  end if;

  select prosrc into v_src from pg_proc
   where pronamespace = 'public'::regnamespace and proname = 'assign_player';
  if strpos(v_src, 'Only the Pro can do that.') = 0
     or strpos(v_src, $q$se.status in ('cup_final', 'complete')$q$) = 0
     or strpos(v_src, 'v_started and v_seated') = 0 then
    raise exception '[D382] assign_player lost its phase rule or the D296 wording';
  end if;
end $chk$;
