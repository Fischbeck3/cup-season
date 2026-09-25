-- D386 (OWNER-RULED 2026-09-24) · launch audit S7, L-07 + L-32.
-- A late joiner gets a seat: from the day they are seated, on the thinnest squad.
--
-- L-07 · a golfer who joined a squad league by code after the squads were set
-- sat on no squad all season: join_league never called _late_squad, and the
-- phone's formation screen hides the pool once the season starts.
-- L-32 · respond_invite's _late_squad gated on `active`, which lock_league
-- sets at the lock, so draft-phase invitees were seated before the draw and
-- the "rigging-proof" hat never dealt them.
--
--   1 · squad_members.seated_at: null for a seat made at formation (counts the
--       whole season, as today); stamped for a seat made once under way.
--   2 · v_squad_standings counts a member's rounds for the squad only from the
--       seat (D386 §2, not retroactive). A round a finished season's book kept
--       after its deletion has no rounds row and still counts, as it did.
--   3 · _late_squad seats only once the league is in season and the season is
--       active (not during a Final: D382 holds the Final's squads), picks the
--       thinnest squad with a coin toss among equally thin ones and says so,
--       and stamps the seat.
--   4 · join_league seats a genuine join and a season-two yes (respond_invite
--       already did).
--   5 · assign_player's under-way seating (D382 §2) stamps the seat too.
--   6 · members already sitting unseated in a live squads season are seated
--       now, from today, each with a board post.
--
-- Known limit, stated: the tie ladder's month scores (D388) and the Final's
-- window read members' rounds directly; a late joiner's pre-seat rounds are
-- outside the Final's window by construction (the seat happens before the
-- Final), but can enter a regular-season month score used only to break an
-- exact tie. Logged in spec/inbox.md.

-- ── 1 · when a seat was taken ───────────────────────────────────────────────
alter table public.squad_members add column if not exists seated_at timestamptz;

-- ── 2 · the squad counts a member from the seat ─────────────────────────────
create or replace view public.v_squad_standings with (security_invoker = 'true') as
 with rp as (
   select sq.season_id,
          sq.id as squad_id,
          coalesce(sum(rr.points) filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0::bigint) as pts
     from public.squads sq
     join public.seasons se on se.id = sq.season_id
     join public.league_settings ls on ls.league_id = se.league_id
     left join public.squad_members sm on sm.squad_id = sq.id
     left join public.v_rounds_ranked rr on rr.member_id = sm.member_id and rr.season_id = sq.season_id
          -- [D386] a late seat counts forward only
          and (sm.seated_at is null
               or not exists (select 1 from public.rounds r0 where r0.id = rr.round_id and r0.created_at < sm.seated_at))
    group by sq.season_id, sq.id, ls.counting_cap
 ), adj as (
   select season_adjustments.season_id,
          season_adjustments.squad_id,
          coalesce(sum(season_adjustments.points), 0::bigint) as pts
     from public.season_adjustments
    where season_adjustments.squad_id is not null
    group by season_adjustments.season_id, season_adjustments.squad_id
 )
 select rp.season_id,
        rp.squad_id,
        rp.pts + coalesce(adj.pts, 0::bigint) as points
   from rp
   left join adj on adj.season_id = rp.season_id and adj.squad_id = rp.squad_id;

-- ── 3 · the thinnest squad, by coin between equals, only once under way ────
create or replace function public._late_squad(p_league uuid, p_member uuid)
returns text
language plpgsql security definer set search_path = public
as $function$
declare v_season uuid; v_squad uuid; v_name text; v_thin integer; v_ties text[];
begin
  -- [D386] L-32: before the draw a joiner stays loose for the hat
  if (select phase from leagues where id = p_league) is distinct from 'season' then return null; end if;
  -- D382: a Final's squads are the squads it was drawn from
  select s.id into v_season from seasons s
   where s.league_id = p_league and s.status = 'active'
   order by s.starts_on desc limit 1;
  if v_season is null then return null; end if;
  if exists (select 1 from squad_members sm join squads q on q.id = sm.squad_id
              where q.season_id = v_season and sm.member_id = p_member) then return null; end if;

  select min(n) into v_thin from (
    select count(sm.member_id) as n from squads sq left join squad_members sm on sm.squad_id = sq.id
     where sq.season_id = v_season group by sq.id) t;
  if v_thin is null then return null; end if;
  select array_agg(sq.name order by sq.name) into v_ties from squads sq
   where sq.season_id = v_season
     and (select count(*) from squad_members sm where sm.squad_id = sq.id) = v_thin;
  -- a logged coin between equally thin squads (D386 §1)
  select sq.id, sq.name into v_squad, v_name from squads sq
   where sq.season_id = v_season
     and (select count(*) from squad_members sm where sm.squad_id = sq.id) = v_thin
   order by random() limit 1;

  insert into squad_members (squad_id, member_id, seated_at) values (v_squad, p_member, now())
  on conflict do nothing;
  return v_name || case when coalesce(array_length(v_ties, 1), 0) > 1
                        then ' (a coin toss between ' || array_to_string(v_ties, ' and ') || ')' else '' end;
end $function$;
revoke all on function public._late_squad(uuid, uuid) from public, anon, authenticated;

-- ── 4 · join_league seats a genuine join and a season-two yes ───────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.join_league'::regproc);
  if position('[D386]' in v_def) > 0 then
    raise notice '[D386] join_league already seats';
    return;
  end if;
  v_def := replace(v_def, 'declare v_league uuid; v_new uuid; v_name text;',
                          'declare v_league uuid; v_new uuid; v_name text; v_squad text;');
  v_a := $a$  if v_new is null and _agree_to_season(v_league, auth.uid()) then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in for season '
              || (select max(number) from seasons where league_id = v_league) || '.');
  end if;$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D386] join_league re-up anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a, $b$  if v_new is null and _agree_to_season(v_league, auth.uid()) then
    select display_name into v_name from profiles where id = auth.uid();
    -- [D386] under way, the yes takes a seat on the thinnest squad
    v_squad := _late_squad(v_league, (select lm.id from league_members lm
                                       where lm.league_id = v_league and lm.profile_id = auth.uid()));
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in for season '
              || (select max(number) from seasons where league_id = v_league) || '.'
              || case when v_squad is not null then ' The thinnest squad takes them: ' || v_squad || '.' else '' end);
  end if;$b$);

  v_a := $a$  if v_new is not null then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in.');
  end if;$a$;
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n <> 1 then raise exception '[D386] join_league join anchor found % times', v_n; end if;
  v_def := replace(v_def, v_a, $b$  if v_new is not null then
    select display_name into v_name from profiles where id = auth.uid();
    -- [D386] L-07: a code join after the squads are set takes a seat
    v_squad := _late_squad(v_league, v_new);
    insert into posts (league_id, kind, body)
      values (v_league, 'system', coalesce(v_name,'A golfer') || ' is in.'
              || case when v_squad is not null then ' The thinnest squad takes them: ' || v_squad || '.' else '' end);
  end if;$b$);
  execute v_def;
end $patch$;

-- ── 5 · assign_player stamps an under-way seat ──────────────────────────────
do $patch$
declare v_def text; v_n integer;
  v_a text := $a$  insert into squad_members (squad_id, member_id) values (p_squad, p_member);$a$;
begin
  v_def := pg_get_functiondef('public.assign_player'::regproc);
  if position('seated_at' in v_def) > 0 then
    raise notice '[D386] assign_player already stamps the seat';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D386] assign_player anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      $b$  insert into squad_members (squad_id, member_id, seated_at)   -- [D386] counts forward from an under-way seat
  values (p_squad, p_member, case when v_started then now() end);$b$);
  end if;
end $patch$;

-- ── 6 · the ones already waiting ────────────────────────────────────────────
do $seat$
declare r record; v_squad text; v_n integer := 0;
begin
  for r in
    select lm.id as member_id, lm.league_id, coalesce(p.display_name, 'A golfer') as who
      from league_members lm
      join leagues l on l.id = lm.league_id and l.phase = 'season'
      join league_settings ls on ls.league_id = l.id and ls.structure <> 'solo'
      join seasons s on s.league_id = l.id and s.status = 'active'
                    and s.number = any(lm.agreed_seasons)
      left join profiles p on p.id = lm.profile_id
     where lm.left_at is null and lm.suspended_at is null
       and exists (select 1 from squads q where q.season_id = s.id)
       and not exists (select 1 from squad_members sm join squads q on q.id = sm.squad_id
                        where q.season_id = s.id and sm.member_id = lm.id)
  loop
    v_squad := _late_squad(r.league_id, r.member_id);
    if v_squad is not null then
      insert into posts (league_id, kind, body)
      values (r.league_id, 'system', r.who || ' joined after the squads were set and now has a seat: '
              || v_squad || '. Rounds count for the squad from today.');
      v_n := v_n + 1;
    end if;
  end loop;
  raise notice '[D386] % waiting late joiner(s) seated', v_n;
end $seat$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[D386]' in pg_get_functiondef('public.join_league'::regproc)) = 0
     or position('[D386]' in pg_get_functiondef('public._late_squad'::regproc)) = 0
     or position('seated_at' in pg_get_functiondef('public.assign_player'::regproc)) = 0
     or position('seated_at' in pg_get_viewdef('public.v_squad_standings'::regclass)) = 0 then
    raise exception '[D386] a door still leaves a late joiner unseated or counts backwards';
  end if;
  if not exists (select 1 from pg_class where oid = 'public.v_squad_standings'::regclass
                   and 'security_invoker=true' = any(reloptions)) then
    raise exception '[D386] v_squad_standings lost security_invoker';
  end if;
  if has_function_privilege('authenticated', 'public._late_squad(uuid, uuid)', 'EXECUTE') then
    raise exception '[D386] _late_squad is reachable by a client';
  end if;
  -- D375 / D161 survive in join_league
  if position('_join_gate(v_league, false)' in pg_get_functiondef('public.join_league'::regproc)) = 0 then
    raise exception '[D386] join_league lost its gate';
  end if;
end $chk$;
