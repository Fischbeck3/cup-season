-- Looser golfer search (pilot feedback, 2026-07-17). A pilot user couldn't
-- find his buddy: the handle + display name start "Mm" (email-derived), so
-- "Mi" and "Ma" legitimately matched nothing — and the one query that WOULD
-- have matched, a single "M", was dropped by the 2-character floor (here and
-- in the client). Three loosenings, identical privacy gates:
--
--   1. one-character queries are allowed — at league scale a letter should
--      pull the shortlist, not silence
--   2. handle matches SUBSTRING, not prefix — "fedor" finds @gfedor
--   3. ordering makes short queries useful instead of noisy:
--      buddies → shared-league mates → handle-prefix hits → name A–Z
--
-- Signature and result shape unchanged → deploy-skew-safe in both orders
-- (old client + new fn: fine; new client + old fn: 1-char queries return
-- empty until this pushes, which renders as "no golfers found", never an
-- error). discoverable / tombstone / self-exclusion gates carried verbatim
-- from 20260715210000.

create or replace function public.search_golfers(p_q text)
returns table (profile_id uuid, handle text, display_name text, city text,
               home_course text, marker text, index_current numeric, rel text)
language sql stable security definer set search_path = public as $$
  select p.id, p.handle, p.display_name, p.city, p.home_course, p.marker,
         p.index_current,
    case
      when f.status = 'accepted' then 'friend'
      when f.status = 'pending' and f.requester = auth.uid() then 'requested'
      when f.status = 'pending' then 'incoming'
      else 'none' end
  from profiles p
  left join friendships f
    on least(f.requester, f.addressee)    = least(p.id, auth.uid())
   and greatest(f.requester, f.addressee) = greatest(p.id, auth.uid())
  where p.id <> auth.uid()
    and p.deleted_at is null
    and length(trim(p_q)) >= 1
    and (p.handle ilike '%' || replace(trim(p_q), '@', '') || '%'
         or p.display_name ilike '%' || trim(p_q) || '%')
    and (p.discoverable = 'everyone'
         or (p.discoverable = 'friends' and f.status = 'accepted'))
  -- IS NOT DISTINCT FROM: f.status is NULL for strangers, and a bare
  -- `(f.status = 'accepted') desc` would sort those NULLs FIRST — strangers
  -- above buddies, the exact inversion of the point.
  order by (f.status is not distinct from 'accepted') desc,
           exists (select 1 from league_members a
                     join league_members b on b.league_id = a.league_id
                    where a.profile_id = p.id
                      and b.profile_id = auth.uid()) desc,
           (p.handle ilike replace(trim(p_q), '@', '') || '%') desc,
           p.display_name
  limit 10;
$$;
