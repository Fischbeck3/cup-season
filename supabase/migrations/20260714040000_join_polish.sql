-- Join-flow polish (from the two-account UX audit).
--
-- 1) league_by_code: validate an invite code BEFORE the email round-trip, so a
--    typo'd code fails at entry ("no league with that code") instead of after
--    the most expensive step in the funnel. Callable pre-auth (anon) — a code
--    is already a shareable invite token, so returning the league name for a
--    valid one leaks nothing the code doesn't. (Enumeration is low-value — a
--    name only; rate-limiting anon RPCs is tracked with the courses-fn guard.)
--
-- 2) join_league now announces on the board, matching respond_invite — so a
--    code-join and an invite-accept both post "X JOINED THE LEAGUE" (before,
--    code-joins were silent and nobody in the league was told).

create or replace function public.league_by_code(p_code text)
returns text language sql stable security definer set search_path = public as $$
  select name from leagues where upper(code) = upper(p_code) limit 1;
$$;
revoke all on function public.league_by_code(text) from public;
grant execute on function public.league_by_code(text) to anon, authenticated;

create or replace function public.join_league(p_code text) returns uuid
  language plpgsql security definer set search_path to 'public' as $$
declare v_league uuid; v_new uuid; v_name text;
begin
  select id into v_league from leagues where upper(code) = upper(p_code);
  if not found then raise exception 'invalid league code'; end if;
  insert into league_members (league_id, profile_id)
    values (v_league, auth.uid())
    on conflict (league_id, profile_id) do nothing
    returning id into v_new;
  -- only announce on a genuine join, not a re-tap of a league you're already in
  if v_new is not null then
    select display_name into v_name from profiles where id = auth.uid();
    insert into posts (league_id, kind, body)
      values (v_league, 'system', upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE');
  end if;
  return v_league;
end $$;
