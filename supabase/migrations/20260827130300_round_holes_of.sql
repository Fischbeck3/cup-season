-- ============================================================================
-- IOS-009 batch 1 (docs/ios/DECISIONS.md) · item 3 — round_holes_of()
--
-- The rholes_read policy (baseline) gates round_holes on
-- rounds.season_id → seasons.league_id → is_league_member(), and
-- rounds.season_id is NULL on every server-side insert (live finalize, scan
-- claim, sandbox — 20260729120000 records the debt, audit 03 §7.6). So under
-- RLS the hole-by-hole of most posted rounds is unreadable, even by the golfer
-- who played it. round_card() carries its own guard for the same reason; this
-- is the same guard, returning just the holes.
--
-- Contract:
--   * Visibility predicate is IDENTICAL to round_card (20260729180000): the
--     caller owns the round, or shares a league with the owner. round_card
--     has no event-mate clause, so neither does this.
--   * Rows ordered by hole_number. Empty when there are no holes OR the
--     caller may not see the round — deliberately indistinguishable, so the
--     function never confirms a round id exists.
--   * Signed-out → empty.
--
-- Additive: the web reads holes through round_card / share_info. D37 below.
-- ============================================================================

create or replace function public.round_holes_of(p_round uuid)
returns table (hole_number integer, strokes integer)
language sql stable security definer set search_path = public as $$
  select rh.hole_number, rh.strokes
    from round_holes rh
    join rounds r on r.id = rh.round_id
   where rh.round_id = p_round
     and auth.uid() is not null
     and (
       r.profile_id = auth.uid()
       or exists (
         select 1
           from league_members a
           join league_members b on b.league_id = a.league_id
          where a.profile_id = auth.uid()
            and b.profile_id = r.profile_id)
     )
   order by rh.hole_number;
$$;

revoke all on function public.round_holes_of(uuid) from public, anon;
grant execute on function public.round_holes_of(uuid) to authenticated;
