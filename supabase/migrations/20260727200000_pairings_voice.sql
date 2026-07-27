-- ============================================================================
-- Cup Season — D77: the Ryder pairings post stops broadcasting the whole sheet
--
-- generate_pairings posted the ENTIRE pairing table to every player:
--
--   SESSION 1 PAIRINGS: JERECHO FISCHBECK VS WILL PETERSON · ISAAK NGUYEN VS
--   JADE ROBINSON · MIKE TORRES VS DAN REYES
--
-- Each player cares about exactly one line — their own — so the one fact that
-- matters ("you're on Will") is buried among everyone else's, and this post is
-- also a push body: on a lock screen it is a wall of upper-cased legal names.
--
--   -> Session 1 is up: Jerecho v Will, Isaak v Jade, Mike v Dan.
--   -> Session 1 is up. 6 duels on the sheet — find yours.   (when it is long)
--
-- The threshold is 3 pairs: below it the sheet fits and naming it is friendly;
-- above it a list nobody reads becomes a count and a nudge.
--
-- Same method as 20260727160000: live definition pulled with supabase db dump,
-- patched by script, each replacement asserted to match exactly once. Only the
-- copy differs. Grants restated per D37.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."generate_pairings"("p_session" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_event uuid; v_no int; v_team_a uuid; v_team_b uuid; v_pairs integer; i integer;
  a_ids uuid[]; b_ids uuid[]; v_lines text;
begin
  select event_id, session_no into v_event, v_no from event_sessions where id = p_session;
  if auth.uid() is not null and not is_event_organizer(v_event) then
    raise exception 'organizer only';
  end if;

  select id into v_team_a from event_teams where event_id = v_event and slot = 0;
  select id into v_team_b from event_teams where event_id = v_event and slot = 1;

  select array_agg(id order by benched_count, seed) into a_ids
    from event_players where event_id = v_event and team_id = v_team_a;
  select array_agg(id order by benched_count, seed) into b_ids
    from event_players where event_id = v_event and team_id = v_team_b;

  v_pairs := least(coalesce(array_length(a_ids,1),0), coalesce(array_length(b_ids,1),0));
  if v_pairs = 0 then return 0; end if;   /* S5-01: an empty side pairs nobody — touch nothing */

  delete from event_duels where session_id = p_session;
  for i in 1..v_pairs loop
    insert into event_duels (event_id, session_id, a_player, b_player)
      values (v_event, p_session, a_ids[i], b_ids[i]);
  end loop;

  for i in (v_pairs+1)..coalesce(array_length(a_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = a_ids[i];
  end loop;
  for i in (v_pairs+1)..coalesce(array_length(b_ids,1),0) loop
    update event_players set benched_count = benched_count + 1 where id = b_ids[i];
  end loop;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = v_event and status = 'setup';

  select string_agg(firstname(pa.display_name) || ' v ' || firstname(pb.display_name), ', ')
    into v_lines
    from event_duels d
    join event_players ea on ea.id = d.a_player join profiles pa on pa.id = ea.profile_id
    join event_players eb on eb.id = d.b_player join profiles pb on pb.id = eb.profile_id
   where d.session_id = p_session;
  perform event_post(v_event,
    case when v_pairs <= 3
         then 'Session ' || v_no || ' is up: ' || v_lines || '.'
         else 'Session ' || v_no || ' is up. ' || v_pairs
              || ' duels on the sheet — find yours.' end);
  return v_pairs;
end $$;
revoke all on function public.generate_pairings(uuid) from public, anon;
grant execute on function public.generate_pairings(uuid) to authenticated;
