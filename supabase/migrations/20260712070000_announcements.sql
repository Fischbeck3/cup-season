-- ============================================================================
-- Cup Season — announcements: the Pro speaks, distinct from chat
--
-- Personas doc: "League communication = simple announcements, nothing more."
-- A new posts kind ('announce'), writable only by the commissioner via RPC.
-- Rides the existing board + realtime + push rails; rendered pinned-style
-- in the client. Author excluded from their own push as usual.
-- ============================================================================

alter table public.posts drop constraint posts_kind_check;
alter table public.posts add constraint posts_kind_check
  check (kind = any (array['chat'::text, 'round'::text, 'system'::text, 'announce'::text]));

create or replace function public.announce(p_league uuid, p_body text) returns void
language plpgsql security definer
set search_path = public
as $$
declare v_body text := trim(p_body);
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro announces';
  end if;
  if v_body is null or length(v_body) < 1 or length(v_body) > 280 then
    raise exception 'Announcements are 1-280 characters';
  end if;
  insert into posts (league_id, kind, member_id, body)
  values (p_league, 'announce', my_member_id(p_league), v_body);
end $$;

grant execute on function public.announce(uuid, text) to authenticated;
