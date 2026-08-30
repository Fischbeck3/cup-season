-- ============================================================================
-- D148 · the attached league could not watch, and the roster asked nobody
--
-- 1. THE BLIND SPECTATOR. `20260720193000_the_major.sql` widened events,
--    event_players, event_sessions, event_duels and posts so an attached
--    league's members can follow an event they have not entered. `event_teams`
--    was left on its original `using (is_event_member(event_id))` and never
--    revisited. So a league-mate sees the event, the field, the sessions and
--    every duel — and ZERO team rows. loadEvent reads event_teams directly and
--    renderEvent falls back to placeholders, so what they actually get is a
--    0-0 scoreboard between "Team A" and "Team B". The attach is sold as
--    "borrow its crew and its board"; the crew was shown an empty game.
--
--    The policy now matches its four siblings exactly.
--
-- 2. THE ROSTER ASKED NOBODY. add_event_player is organizer-gated but takes any
--    profile uuid in the database — no invitation, no shared league, no
--    consent. Every other door in the product asks first: invite_golfer +
--    respond_invite is a real accept/decline, enter_major requires league
--    membership, and the league join covenant is enforced on all five join
--    paths. The client's picker only offers friends and league-mates, but the
--    RPC is the fence and it had none.
--
--    An organizer may now add someone only if there is an existing relationship
--    to draw on: the event's attached league (they are already in the room),
--    an accepted friendship, or themselves. Anyone else goes through
--    invite_golfer, which is exactly the door that already exists and already
--    asks. The error names the alternative rather than just refusing.
-- ============================================================================

-- ---- 1. the spectator sees the teams ---------------------------------------
drop policy if exists event_teams_read on public.event_teams;
create policy event_teams_read on public.event_teams
  for select to authenticated
  using (is_event_member(event_id) or is_event_league_member(event_id));

-- ---- 2. the roster asks first ----------------------------------------------
create or replace function public.add_event_player(p_event uuid, p_profile uuid)
returns uuid
language plpgsql security definer set search_path = public as $fn$
declare v_id uuid; v_kind text; v_league uuid; v_exh boolean; v_n int; v_name text;
begin
  if not is_event_organizer(p_event) then
    raise exception 'organizer only';
  end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a session has been scored';
  end if;

  select kind, league_id into v_kind, v_league from events where id = p_event;

  -- D148: consent. A direct add needs a standing relationship; everyone else
  -- goes through invite_golfer, which asks and can be declined.
  if p_profile <> auth.uid()
     and not (v_league is not null and exists (
                select 1 from league_members lm
                 where lm.league_id = v_league and lm.profile_id = p_profile))
     and not exists (
                select 1 from friendships f
                 where f.status = 'accepted'
                   and ((f.requester = auth.uid() and f.addressee = p_profile)
                     or (f.addressee = auth.uid() and f.requester = p_profile)))
  then
    raise exception 'You can add golfers from this league or your buddies list. For anyone else, send an invite so they can accept.';
  end if;

  v_exh := (v_kind = 'major') and not major_contender(p_profile);

  select coalesce(max(seed), 0) + 1 into v_n from event_players where event_id = p_event;

  insert into event_players (event_id, profile_id, seed, exhibition)
  values (p_event, p_profile, v_n, v_exh)
  on conflict (event_id, profile_id) do nothing
  returning id into v_id;

  if v_id is not null and v_kind = 'major' then
    select display_name into v_name from profiles where id = p_profile;
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event, upper(coalesce(v_name,'A golfer')) || ' ENTERS THE FIELD (' || v_n || ')');
  end if;

  return v_id;
end $fn$;

revoke all on function public.add_event_player(uuid, uuid) from public, anon;
grant execute on function public.add_event_player(uuid, uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_qual text; v_src text;
begin
  select pg_get_expr(polqual, polrelid) into v_qual
    from pg_policy where polrelid = 'public.event_teams'::regclass and polname = 'event_teams_read';
  if v_qual is null or position('is_event_league_member' in v_qual) = 0 then
    raise exception 'D148: event_teams is still narrower than its siblings';
  end if;
  select prosrc into v_src from pg_proc
   where proname = 'add_event_player' and pronamespace = 'public'::regnamespace;
  if position('friendships' in v_src) = 0 then
    raise exception 'D148: add_event_player still adds anyone without consent';
  end if;
  if has_function_privilege('anon', 'public.add_event_player(uuid,uuid)', 'execute') then
    raise exception 'D148: anon can execute add_event_player';
  end if;
end $chk$;
