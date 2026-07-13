-- Delete an inactive league — the Pro's escape hatch before anything is real.
-- A league is deletable only while it has never gone live: phase 'setup' or
-- 'draft', or phase 'season' whose current season is still at the starter
-- (first tee ahead, never kicked off). Completed leagues are the record book
-- and can never be deleted.
--
-- What deletion removes is the LENS, never the golf: members, squads, seasons,
-- posts, settings, invites, buy-ins all fall via the existing FK cascades from
-- leagues(id). Rounds are profile-owned facts and are untouched.

create or replace function public.delete_league(p_league uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  lg leagues%rowtype;
  se seasons%rowtype;
begin
  select * into lg from leagues where id = p_league;
  if not found then raise exception 'league not found'; end if;
  if not is_commissioner(p_league) then raise exception 'commissioner only'; end if;

  if lg.phase = 'complete' then
    raise exception 'completed seasons are the record book — they cannot be deleted';
  elsif lg.phase not in ('setup','draft') then
    select * into se from seasons
     where league_id = p_league order by number desc limit 1;
    -- a season row that has kicked off, or whose first tee has passed, is live
    if found and (se.kicked_off or se.starts_on <= current_date) then
      raise exception 'the season is under way — a live league cannot be deleted';
    end if;
  end if;

  delete from leagues where id = p_league;
end $$;

revoke all on function public.delete_league(uuid) from public;
grant execute on function public.delete_league(uuid) to authenticated;
