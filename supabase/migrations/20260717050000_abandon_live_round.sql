-- ============================================================================
-- Cup Season — live-round discard (pilot feedback, 2026-07-17)
--
-- "Live round needs a discard button." A scrapped round previously had no
-- exit: the local snapshot + the open live_rounds row meant the Continue
-- banner followed you forever, and a client-only clear would be resurrected
-- by the server sweep on the next boot (rehydrateLiveRound step 2).
--
--   abandon_live_round() — any player in the round (or its starter) can close
--   it as 'abandoned'. Nothing posts, no board story, no rounds rows — the
--   round simply never happened. Idempotent; a 'final' round can NOT be
--   abandoned (posted scores are never destroyed).
--
-- Auth mirrors finish_live_round: security definer, starter-or-player check.
-- ============================================================================

-- widen the status vocabulary: a live round can be scrapped mid-play
alter table live_rounds drop constraint if exists live_rounds_status_check;
alter table live_rounds add constraint live_rounds_status_check
  check (status = any (array['setup'::text, 'live'::text, 'final'::text, 'abandoned'::text]));

create or replace function public.abandon_live_round(p_live_round uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype;
  v_starter uuid;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then return jsonb_build_object('gone', true); end if;

  select profile_id into v_starter from league_members where id = lr.started_by;
  if v_starter is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;

  if lr.status = 'final' then
    return jsonb_build_object('already_final', true);
  end if;
  if lr.status = 'abandoned' then
    return jsonb_build_object('abandoned', true);
  end if;

  update live_rounds set status = 'abandoned', finished_at = now()
   where id = p_live_round;
  return jsonb_build_object('abandoned', true);
end $$;

grant execute on function public.abandon_live_round(uuid) to authenticated;
