-- ============================================================================
-- D145 · a shared Ryder cup engraved every event player in the database
--
-- award_event_trophies' shared-cup branch selects the field like this:
--
--     from event_players ep where ep.team_id is not null
--
-- with no `ep.event_id = p_event`. So when a Ryder ends level — either by
-- draw_rule 'shared', or by 'team_pvi' when the two sides' total PvI is also
-- level — it mints a trophy titled with THAT event's name for every player of
-- every event anywhere in the database who happens to be seated on a team.
--
-- The winner branch escapes only by accident: `ep.team_id = v.winner_team_id`
-- is implicitly scoped because team ids are unique per event. The scope is
-- restored explicitly there too, so the next edit cannot reintroduce this.
--
-- Found by the Ryder simulation (2026-08-30): a two-player event that ended
-- level produced EIGHT trophies — its own two players plus the six players of
-- the unrelated live event "The Grudge". `trophies` RLS is
-- `profile_id = auth.uid()`, so each of those strangers would see, in their own
-- trophy case, a cup for an event they were never in.
--
-- Depends on D144 (20260830160000): before that fix resolve_session could not
-- complete an event at all, so this branch had never run in production. There
-- are no bad rows to clean up — `select count(*) from trophies where kind =
-- 'ryder'` is 0 — and the migration asserts that rather than assuming it.
-- ============================================================================

create or replace function public.award_event_trophies(p_event uuid)
returns void language plpgsql security definer set search_path = public as $fn$
declare v record; v_champ uuid;
begin
  select kind, winner_team_id, name into v
    from events where id = p_event and status = 'complete';
  if not found then return; end if;

  if v.kind = 'major' then
    select ep.profile_id into v_champ
      from event_major_cards c join event_players ep on ep.id = c.player_id
     where c.event_id = p_event and c.rank = 1;
    if v_champ is not null then
      insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      values (v_champ, 'major', v.name, 'Major champion', 'winner', p_event,
              extract(year from current_date)::int)
      on conflict do nothing;
    end if;
    return;
  end if;

  -- the Ryder paths. BOTH are now scoped to this event.
  if v.winner_team_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder', 'winner', p_event,
             extract(year from current_date)::int
        from event_players ep
       where ep.event_id = p_event
         and ep.team_id = v.winner_team_id
      on conflict do nothing;
  else
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder · shared', 'shared', p_event,
             extract(year from current_date)::int
        from event_players ep
       where ep.event_id = p_event
         and ep.team_id is not null
      on conflict do nothing;
  end if;
end $fn$;

-- D37: engine-only — the completion trigger calls it, no client may
revoke all on function public.award_event_trophies(uuid) from public, anon, authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text; v_bad bigint;
begin
  select prosrc into v_src from pg_proc
   where proname = 'award_event_trophies' and pronamespace = 'public'::regnamespace;
  -- both Ryder branches must name the event
  if (length(v_src) - length(replace(v_src, 'ep.event_id = p_event', ''))) / length('ep.event_id = p_event') < 2 then
    raise exception 'D145: a Ryder trophy branch is still unscoped';
  end if;
  if has_function_privilege('authenticated', 'public.award_event_trophies(uuid)', 'execute') then
    raise exception 'D145: award_event_trophies is client-callable';
  end if;
  -- nothing to clean: the shared branch had never run (D144 blocked completion)
  select count(*) into v_bad from trophies t
   where t.kind = 'ryder' and t.event_id is not null
     and not exists (select 1 from event_players ep
                      where ep.event_id = t.event_id and ep.profile_id = t.profile_id);
  if v_bad > 0 then
    raise exception 'D145: % misattributed ryder trophies exist — clean them before this ships', v_bad;
  end if;
end $chk$;
