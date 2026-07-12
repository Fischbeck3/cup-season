-- ============================================================================
-- Cup Season — add_friend_to_league(): one-tap buddy adds in the wizard
--
-- The Pro can place accepted golf buddies straight into a league — no email,
-- no code. Guardrails at the database: caller must be the league's
-- commissioner, the friendship must be accepted, no duplicates. The add
-- posts a system line to the board, which rides the existing push webhook —
-- so the buddy's pocket buzzes with the welcome.
-- ============================================================================

create or replace function public.add_friend_to_league(p_league uuid, p_profile uuid)
returns void
language plpgsql security definer
set search_path = public
as $$
declare v_name text; v_idx numeric;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro adds players';
  end if;
  if not are_friends(auth.uid(), p_profile) then
    raise exception 'Not golf buddies yet — send a request first';
  end if;
  if exists (select 1 from league_members
             where league_id = p_league and profile_id = p_profile) then
    raise exception 'Already in the league';
  end if;

  select display_name, index_current into v_name, v_idx
    from profiles where id = p_profile;

  insert into league_members (league_id, profile_id, role, index_current)
  values (p_league, p_profile, 'player', coalesce(v_idx, 18.0));

  insert into posts (league_id, kind, body)
  values (p_league, 'system',
          upper(coalesce(v_name, 'A GOLFER')) || ' WAS ADDED BY THE PRO — WELCOME TO THE LEAGUE');
end $$;

grant execute on function public.add_friend_to_league(uuid, uuid) to authenticated;
