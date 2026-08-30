-- D154 + D156 · who you actually play with, and who is standing next to you.
--
-- Two read-only lookups, both deliberately held to the SAME disclosure envelope
-- as `search_golfers` (id, handle, display_name, city, home_course, marker,
-- index_current, rel) under the SAME `discoverable` gate. Neither widens what
-- any golfer can see about another; they narrow WHO is returned:
--
--   recent_partners()  — profiles you have shared a live round with.
--   nearby_resolve()   — of a list of profile ids you already hold, only the
--                        ones that are already your buddy or your league mate.
--
-- D37: explicit revoke + grant. Neither is anon-callable; both are `authenticated`.

-- ---------------------------------------------------------------------------
-- D154 · recent_partners
-- ---------------------------------------------------------------------------
create or replace function public.recent_partners(p_limit int default 12)
returns table (
  id uuid, handle text, display_name text, city text, home_course text,
  marker text, index_current numeric, rel text,
  last_played timestamptz, rounds_together int
)
language sql
stable
security definer
set search_path = public
as $fn$
  with me as (select auth.uid() as pid),
  /* every live round I was seated in — as a member, as an app buddy, or as a
     guest who later claimed the card. A round I merely started but was not
     seated in is not a round I played. */
  seat as (
    select p.live_round_id,
           coalesce(lm.profile_id, p.guest_profile_id, p.claimed_profile) as pid
      from live_round_players p
      left join league_members lm on lm.id = p.member_id
  ),
  mine as (
    select s.live_round_id from seat s where s.pid = (select pid from me)
  ),
  partners as (
    select s.pid,
           max(lr.started_at)          as last_played,
           count(distinct s.live_round_id)::int as rounds_together
      from seat s
      join mine m  on m.live_round_id = s.live_round_id
      join live_rounds lr on lr.id = s.live_round_id
     where s.pid is not null
       and s.pid <> (select pid from me)
     group by s.pid
  )
  select pr.id, pr.handle, pr.display_name, pr.city, pr.home_course, pr.marker,
         pr.index_current,
         case
           when f.status = 'accepted' then 'friend'
           when f.status = 'pending' and f.requester = (select pid from me) then 'requested'
           when f.status = 'pending' then 'incoming'
           else 'none' end,
         t.last_played, t.rounds_together
    from partners t
    join profiles pr on pr.id = t.pid
    left join friendships f
      on least(f.requester, f.addressee)    = least(pr.id, (select pid from me))
     and greatest(f.requester, f.addressee) = greatest(pr.id, (select pid from me))
   where pr.deleted_at is null
     /* the same gate search_golfers applies — a golfer who has hidden
        themselves stays hidden here too, and is added as a guest as before */
     and (pr.discoverable = 'everyone'
          or (pr.discoverable = 'friends' and f.status = 'accepted'))
   order by t.last_played desc, t.rounds_together desc, pr.display_name
   limit greatest(1, least(coalesce(p_limit, 12), 50));
$fn$;

revoke all on function public.recent_partners(int) from public, anon;
grant execute on function public.recent_partners(int) to authenticated;

-- ---------------------------------------------------------------------------
-- D156 · nearby_resolve — a nearby phone is a HINT, not an identity
-- ---------------------------------------------------------------------------
-- Takes profile ids handed over a local Bluetooth session and returns rows ONLY
-- for the ones that are already a buddy or a league mate. A stranger's phone
-- produces nothing at all — not a name, not a count, not "someone is nearby".
-- It cannot enumerate: the caller must already hold the uuid.
create or replace function public.nearby_resolve(p_profiles uuid[])
returns table (
  id uuid, handle text, display_name text, city text, home_course text,
  marker text, index_current numeric, rel text
)
language sql
stable
security definer
set search_path = public
as $fn$
  with me as (select auth.uid() as pid)
  select pr.id, pr.handle, pr.display_name, pr.city, pr.home_course, pr.marker,
         pr.index_current,
         case when f.status = 'accepted' then 'friend' else 'league' end
    from profiles pr
    left join friendships f
      on least(f.requester, f.addressee)    = least(pr.id, (select pid from me))
     and greatest(f.requester, f.addressee) = greatest(pr.id, (select pid from me))
   where pr.id = any(coalesce(p_profiles, '{}'::uuid[]))
     and pr.id <> (select pid from me)
     and pr.deleted_at is null
     and (
       f.status = 'accepted'
       or exists (
         select 1 from league_members a
           join league_members b on b.league_id = a.league_id
          where a.profile_id = pr.id
            and b.profile_id = (select pid from me)
       )
     )
   limit 16;   -- a foursome's worth of tees, not a room scan
$fn$;

revoke all on function public.nearby_resolve(uuid[]) from public, anon;
grant execute on function public.nearby_resolve(uuid[]) to authenticated;

-- ---- self-enforcing -------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'recent_partners' and pronamespace = 'public'::regnamespace;
  if position('discoverable' in v_src) = 0 then
    raise exception 'D154: recent_partners lost the discoverable gate';
  end if;

  select prosrc into v_src from pg_proc
   where proname = 'nearby_resolve' and pronamespace = 'public'::regnamespace;
  if position('friendships' in v_src) = 0 or position('league_members' in v_src) = 0 then
    raise exception 'D156: nearby_resolve would name a stranger';
  end if;

  -- D37: neither may be reachable by anon
  if has_function_privilege('anon', 'public.recent_partners(int)', 'execute')
     or has_function_privilege('anon', 'public.nearby_resolve(uuid[])', 'execute') then
    raise exception 'D37: these are authenticated-only';
  end if;
end $chk$;
