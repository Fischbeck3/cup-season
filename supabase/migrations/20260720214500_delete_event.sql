-- ============================================================================
-- delete_event — the organizer's escape hatch (the events analog of
-- delete_league).
--
-- Leagues have had a scrap path since 20260712230000; events never did. A Major
-- or Ryder created with a typo'd name, the wrong final day, or the wrong league
-- attach was PERMANENT: it posts board stories, it nags the field, and at the
-- horn it mints hardware into a real display case.
--
-- Posture mirrors delete_league exactly — this scraps a mistake, it never
-- erases history:
--   • organizer only (created_by, via is_event_organizer)
--   • refuses once the event is `complete`
--   • refuses once ANY session has been scored (results are facts, §R10)
--
-- The trophies FK is ON DELETE SET NULL, so a bare `delete from events` would
-- leave orphaned trophy rows sitting in golfers' cases pointing at nothing —
-- untraceable hardware, a §16 violation. They are deleted explicitly here.
-- Everything else (event_players, event_teams, event_sessions, event_duels,
-- event_major_cards, posts, member_invites) is ON DELETE CASCADE and goes with
-- the row.
-- ============================================================================

create or replace function public.delete_event(p_event uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v record;
begin
  select id, status, kind, name into v from events where id = p_event;
  if v.id is null then raise exception 'No such event'; end if;
  if not is_event_organizer(p_event) then
    raise exception 'Only the organizer can scrap an event';
  end if;
  if v.status = 'complete' then
    raise exception 'That one is in the books — a settled % is history, not a draft',
      case when v.kind = 'major' then 'Major' else 'event' end;
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'A session has already been scored — this one stays on the record';
  end if;

  -- explicit: the trophies FK is SET NULL, so these would orphan (see header)
  delete from trophies where event_id = p_event;
  delete from events where id = p_event;
end $$;

revoke all on function public.delete_event(uuid) from public, anon, authenticated;
grant execute on function public.delete_event(uuid) to authenticated;
