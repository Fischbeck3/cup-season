-- ============================================================================
-- Cup Season — the Pro's "League notices" switch (push wave 7 follow-up).
--
-- 20260827210000 gave `leagues.notify_system` (default true) and the `push`
-- function honours it: `system` board posts — floors, month closes, season
-- notices — reach the crew's phones only while it is on. Nothing could turn it
-- off. This is the one door: commissioner only, checked at the database
-- (is_commissioner), never by hiding a toggle. Rounds, chat and the board are
-- untouched by it; each golfer keeps their own notify_rounds / notify_chat.
--
-- No scoring or mechanic change. D37: explicit grants.
-- ============================================================================

create or replace function public.set_league_notify_system(p_league uuid, p_on boolean)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if not is_commissioner(p_league) then raise exception 'Only the Pro sets league notices'; end if;
  update leagues set notify_system = coalesce(p_on, true) where id = p_league;
end $$;
revoke all on function public.set_league_notify_system(uuid, boolean) from public, anon;
grant execute on function public.set_league_notify_system(uuid, boolean) to authenticated;
