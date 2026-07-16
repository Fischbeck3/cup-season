-- ============================================================================
-- Cup Season — starter-index guards + the engine-handoff announcement
--
-- Behind a real confusion (the Pro set a member's starter to 14; the card then
-- showed the engine's computed number, and the board still read "set to 14" —
-- two numbers, no bridge). Under behavior B a manual index is a STARTER that
-- only fills the gap before 3 posted rounds; once the engine can compute a
-- number from scores, the scores own it. So:
--
--   1. set_member_index / set_index REFUSE to set a starter for a golfer who is
--      already established (handicap_index() non-null, >= 3 rounds). No doomed
--      value, no misleading board post — the Pro/golfer is told the number now
--      comes from scores.
--   2. round_refresh_index ANNOUNCES the one-time handoff — the first time
--      scores take over a manual starter (index_source self/ghin -> app). This
--      is the moment that made "set to 14" and "-1.7" disagree; announcing it
--      keeps the board honest. Per-round auto updates stay SILENT (no spam).
--
-- Pure function replacements; the round_refresh_index trigger stays bound
-- (CREATE OR REPLACE keeps the existing binding from 20260716100000).
-- ============================================================================

-- 1a. the Pro's starter tool -------------------------------------------------
create or replace function public.set_member_index(p_member uuid, p_index numeric)
returns void language plpgsql security definer set search_path = public as $$
declare v_league uuid; v_pid uuid; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;
  select league_id, profile_id into v_league, v_pid from league_members where id = p_member;
  if v_league is null then raise exception 'No such member'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro sets a starter index'; end if;

  -- behavior B: a starter only helps before the engine can compute a number.
  -- Setting one now would post a board line the next round instantly overrides.
  v_auto := handicap_index(v_pid);
  if v_auto is not null then
    raise exception 'Their number comes from their scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select display_name into v_name from profiles where id = v_pid;
  update profiles set index_current = p_index, index_source = 'self' where id = v_pid;

  insert into posts (league_id, kind, member_id, body)
  values (v_league, 'system', my_member_id(v_league),
          'THE PRO SET ' || upper(coalesce(v_name, 'A MEMBER')) || '''S STARTER INDEX TO ' || p_index);
end $$;
grant execute on function public.set_member_index(uuid, numeric) to authenticated;

-- 1b. the golfer's own set ---------------------------------------------------
create or replace function public.set_index(p_index numeric) returns void
language plpgsql security definer set search_path = public as $$
declare v_old numeric; v_name text; v_auto numeric;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;

  v_auto := handicap_index(auth.uid());
  if v_auto is not null then
    raise exception 'Your number comes from your scores now (%). A starter only helps before 3 posted rounds.', v_auto;
  end if;

  select index_current, display_name into v_old, v_name from profiles where id = auth.uid();
  if not found then raise exception 'no profile'; end if;

  update profiles set index_current = p_index, index_source = 'self' where id = auth.uid();
  if v_old is not distinct from p_index then return; end if;

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || case when v_old is null
           then ' set their index to ' || p_index
           else ' adjusted their index ' || v_old || ' → ' || p_index end
    from league_members lm where lm.profile_id = auth.uid();
end $$;
grant execute on function public.set_index(numeric) to authenticated;

-- 2. keep index_current fresh from scores + announce the handoff -------------
create or replace function public.round_refresh_index() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_auto numeric; v_old numeric; v_src text; v_name text;
begin
  if new.voided then return new; end if;
  v_auto := handicap_index(new.profile_id);          -- non-null once >= 3 rounds
  if v_auto is null then return new; end if;

  select index_current, index_source, display_name
    into v_old, v_src, v_name from profiles where id = new.profile_id;

  update profiles set index_current = v_auto, index_source = 'app'
   where id = new.profile_id;                          -- scores are the truth

  -- announce ONLY the handoff: scores taking over a manual starter, and only
  -- when the number actually moves. Routine per-round updates stay silent.
  if coalesce(v_src, 'app') in ('self', 'ghin') and v_old is distinct from v_auto then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(coalesce(v_name, 'A GOLFER')) || '''S NUMBER NOW COMES FROM THEIR SCORES — '
             || coalesce(v_old::text, 'STARTER') || ' → ' || v_auto
      from league_members lm where lm.profile_id = new.profile_id;
  end if;
  return new;
end $$;
