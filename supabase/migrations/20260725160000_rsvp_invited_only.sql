-- ============================================================================
-- Cup Season — D69: RSVP is for the invited (visibility stays, write narrows)
--
-- A scheduled round stays visible to the whole league (can_see_round is
-- UNCHANGED — the "see where your crew is playing" loop survives). What changes
-- is the WRITE: set_round_rsvp restricts In/Maybe/Out to the owner and the
-- players they TAGGED. A pilot found RSVP-ing to an uninvited round confusing —
-- and rightly, since tee times are booked at the COURSE, not here, so an RSVP
-- from someone you didn't invite is noise. Reverses tee-sheet arc Stage 2
-- ("league-mates who can see it may RSVP") — logged as D69, not a silent drift.
--
-- Owner + tagged are already a subset of can_see_round's four grants, so this
-- is strictly tighter; the old can_see_round check is replaced by the narrower
-- owner-or-tagged guard. Existing non-tagged RSVP rows are left as-is
-- (write-forward; negligible data).
-- ============================================================================

create or replace function public.set_round_rsvp(p_round uuid, p_status text)
returns void
language plpgsql security definer set search_path = public as $$
declare v_owner uuid; v_tagged uuid[];
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_status not in ('in','maybe','out') then raise exception 'bad status'; end if;

  select profile_id, tagged into v_owner, v_tagged
    from scheduled_rounds where id = p_round;
  if v_owner is null then raise exception 'No such round'; end if;

  -- D69: only the host and the players they tagged may RSVP. Visibility is
  -- unchanged (can_see_round still lets league-mates SEE the round) — this
  -- guards the write alone.
  if auth.uid() <> v_owner
     and not (auth.uid() = any(coalesce(v_tagged, '{}'::uuid[]))) then
    raise exception 'Only the host and tagged players can RSVP to this round';
  end if;

  insert into round_rsvp (round_id, profile_id, status)
  values (p_round, auth.uid(), p_status)
  on conflict (round_id, profile_id) do update
    set status = excluded.status, updated_at = now();
end $$;

revoke all on function public.set_round_rsvp(uuid, text) from public, anon;
grant execute on function public.set_round_rsvp(uuid, text) to authenticated;

-- ---- round_detail learns to say whether YOU are tagged --------------------
-- The client needs an honest "may I RSVP" signal to match the new write rule:
-- show the In/Maybe/Can't controls only when the round is mine or I'm tagged.
-- `mine` already exists; add `tagged_me`. Everything else is byte-for-byte the
-- prod body (visibility via can_see_round unchanged).
create or replace function public.round_detail(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare r record; v jsonb;
begin
  if not can_see_round(p_round) then raise exception 'Round not found'; end if;
  select sr.*, p.display_name owner_name, p.marker owner_marker
    into r from scheduled_rounds sr join profiles p on p.id = sr.profile_id
   where sr.id = p_round;

  v := jsonb_build_object(
    'id', r.id, 'profile_id', r.profile_id, 'owner_name', r.owner_name,
    'owner_marker', r.owner_marker, 'mine', r.profile_id = auth.uid(),
    -- D69: is the viewer one of the tagged players? (drives the RSVP controls)
    'tagged_me', auth.uid() = any(coalesce(r.tagged, '{}'::uuid[])),
    'play_on', r.play_on, 'tee_time', r.tee_time, 'note', r.note,
    'course_label', r.course_label, 'course_id', r.course_id, 'league_id', r.league_id,
    'my_rsvp', (select status from round_rsvp where round_id = r.id and profile_id = auth.uid()),
    'course', (
      select jsonb_build_object('name', coalesce(c.club_name, c.course_name), 'city', c.city,
               'state', c.state, 'lat', c.latitude, 'lon', c.longitude,
               'rating', t.course_rating, 'slope', t.slope_rating, 'par', t.par_total,
               'tee', t.tee_name)
        from api_courses c
        left join lateral (select * from api_course_tees where course_id = c.id
                           order by number_of_holes desc nulls last, par_total desc nulls last limit 1) t on true
       where c.id = r.course_id),
    'rsvp', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'profile_id', x.pid, 'name', pp.display_name, 'marker', pp.marker,
               'status', rr.status) order by (x.pid = r.profile_id) desc, pp.display_name), '[]'::jsonb)
        from (
          select r.profile_id pid
          union select unnest(coalesce(r.tagged,'{}'::uuid[]))
          union select profile_id from round_rsvp where round_id = r.id
        ) x
        join profiles pp on pp.id = x.pid
        left join round_rsvp rr on rr.round_id = r.id and rr.profile_id = x.pid),
    'comments', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'name', pp.display_name, 'marker', pp.marker, 'body', rc.body,
               'mine', rc.profile_id = auth.uid(), 'at', rc.created_at) order by rc.created_at), '[]'::jsonb)
        from round_comments rc join profiles pp on pp.id = rc.profile_id
       where rc.round_id = r.id)
  );
  return v;
end $$;

revoke all on function public.round_detail(uuid) from public, anon;
grant execute on function public.round_detail(uuid) to authenticated;
