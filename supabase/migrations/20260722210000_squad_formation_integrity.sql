-- ============================================================================
-- Cup Season — squad formation integrity (setup-QA S4-01 / S4-02, batch A)
--
-- The prod fresh-account walk caught the draw engine accepting degenerate
-- formations:
--   · randomize_squads dealt round-robin from i=0 on EVERY call, so a redraw
--     appended new joiners starting at Squad 1 — 2 players / 2 squads landed
--     2–0 with Squad 2 empty, and the pool emptied with no recovery.
--   · It ran with 1 golfer in the league (1–0 "draw").
--   · It ran on Pro-assign leagues (draft_type never checked) — the assign
--     bylaw was unenforceable server-side.
--   · start_season only checked for unassigned members, so a 2–0 formation
--     (or a 2-golfer league) could go live under "minimum four to tee off."
--   · Reveal copy: "1 JOES".
--
-- Fixes: each unassigned golfer now deals into the CURRENTLY SMALLEST squad
-- (ties shuffled), so draws and redraws always balance; the draw refuses
-- non-random formations and leagues that can't cover their squads; the season
-- won't start with an empty squad or fewer than four golfers; the reveal
-- counts GOLFER/GOLFERS. Client copy for the new errors is humanError's job.
-- ============================================================================

create or replace function public.randomize_squads(p_season uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare
  se record; st record; m record;
  sq_n int; total int; pool_n int;
  reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if coalesce(st.draft_type, 'random') <> 'random' then
    raise exception 'This league seats its squads by Pro assign — tap players into squads instead of drawing.';
  end if;

  select count(*) into sq_n from squads where season_id = p_season;
  if sq_n = 0 then raise exception 'no squads — run form_squads first'; end if;

  select count(*) into total from league_members lm where lm.league_id = se.league_id;
  if total < sq_n then
    raise exception 'Not enough golfers to cover every squad — % in, % squads. Share the invite link first.', total, sq_n;
  end if;

  select count(*) into pool_n from league_members lm
  where lm.league_id = se.league_id
    and not exists (select 1 from squad_members x
                    join squads q on q.id = x.squad_id and q.season_id = p_season
                    where x.member_id = lm.id);
  if pool_n = 0 then return; end if;   /* nothing to deal — no story, no captain churn */

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    /* the hat deals to the smallest squad — draws AND redraws stay balanced */
    insert into squad_members (squad_id, member_id)
    select q.id, m.id
    from squads q
    left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id
    order by count(sm.member_id) asc, random()
    limit 1;
  end loop;

  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(upper(q.name)||' — '||cnt||' GOLFER'||case when cnt=1 then '' else 'S' end, ' · ')
    into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'SQUADS DRAWN — THE HAT HAS SPOKEN. '||coalesce(reveal,''));
end $$;

create or replace function public.start_season(p_season uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% golfer(s) still in the pool — everyone needs a squad before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'ROSTERS LOCKED — THE SEASON IS LIVE. POST A ROUND.');
end $$;

-- assign_player (found live once the client finally rendered the assign UI):
-- its commissioner_log insert omitted actor_id, which is NOT NULL — every
-- assign died on the constraint. The engine was unreachable client-side until
-- this batch (draftType was never rehydrated), so it had never run in prod.
create or replace function public.assign_player(p_squad uuid, p_member uuid) returns void
language plpgsql security definer
set search_path = public
as $$
declare se record;
begin
  select s.* into se from seasons s
  join squads q on q.season_id = s.id where q.id = p_squad;
  if se.id is null then raise exception 'no such squad'; end if;
  if not is_commissioner(se.league_id) then raise exception 'commissioner only'; end if;

  -- moving a player: clear any prior seat this season, then seat them
  delete from squad_members sm using squads q
  where q.id = sm.squad_id and q.season_id = se.id and sm.member_id = p_member;
  insert into squad_members (squad_id, member_id) values (p_squad, p_member);

  insert into commissioner_log (league_id, actor_id, action, detail)
  values (se.league_id, my_member_id(se.league_id), 'assign_player',
          jsonb_build_object('squad', p_squad, 'member', p_member));
end $$;

-- D37 discipline: functions (re)created after the default-privilege flip can
-- pick up PUBLIC execute depending on the runner — strip and re-grant.
revoke all on function public.randomize_squads(uuid) from public, anon;
revoke all on function public.start_season(uuid) from public, anon;
revoke all on function public.assign_player(uuid, uuid) from public, anon;
grant execute on function public.randomize_squads(uuid) to authenticated, service_role;
grant execute on function public.start_season(uuid) to authenticated, service_role;
grant execute on function public.assign_player(uuid, uuid) to authenticated;
