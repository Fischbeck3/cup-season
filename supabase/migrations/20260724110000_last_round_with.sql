-- ============================================================================
-- Last Round With — the reunion whisper (D63, blue-sky #2 unparked).
--
--   • ONE read: the richest lapsed partnership — the friend you shared the
--     most cards with whose last shared card is ≥ 12 months old (and the
--     history is real: ≥ 3 shared cards). Both thresholds are the D63
--     build-go resolution, hardcoded on purpose — a dial would invite
--     engagement-tuning, and this surface must never be tuned.
--   • "Shared a card" = posted-round-grade facts only, already captured:
--     the same FINAL tee-sheet round (live_round_players, member pairs) and
--     a claimed scorecard scan (scan_claims created_by ↔ claimed_profile).
--     scheduled_rounds.tagged is a plan, not a card — excluded.
--   • Definer read: rounds/live RLS is owner/league-scoped; the whisper only
--     ever returns a partner you factually played with. No new data capture,
--     no push class (D23: the emotion is longing — in-app only, threshold
--     only, one name at a time; dismiss is device-local in v1).
-- ============================================================================

create or replace function public.last_round_with()
returns table(profile_id uuid, display_name text, marker text,
              last_on date, shared_cards integer)
language sql stable security definer set search_path = public as $$
  with me as (select auth.uid() as uid),
  live_pairs as (
    select lm2.profile_id as partner, lr.started_at::date as d
      from live_rounds lr
      join live_round_players a on a.live_round_id = lr.id
      join league_members lm1 on lm1.id = a.member_id
      join live_round_players b on b.live_round_id = lr.id and b.id <> a.id
      join league_members lm2 on lm2.id = b.member_id
      cross join me
     where lr.status = 'final'
       and lm1.profile_id = me.uid
       and lm2.profile_id is not null
       and lm2.profile_id <> me.uid
  ),
  scan_pairs as (
    select case when sc.created_by = me.uid then sc.claimed_profile
                else sc.created_by end as partner,
           coalesce(sc.played_on, sc.created_at::date) as d
      from scan_claims sc cross join me
     where sc.claimed_profile is not null
       and sc.claimed_profile <> sc.created_by
       and me.uid in (sc.created_by, sc.claimed_profile)
  ),
  agg as (
    select partner, max(d) as last_on, count(*)::int as n
      from (select * from live_pairs union all select * from scan_pairs) p
     where partner is not null
     group by partner
  )
  select a.partner, pr.display_name, pr.marker, a.last_on, a.n
    from agg a
    join profiles pr on pr.id = a.partner
   where a.n >= 3
     and a.last_on <= current_date - interval '12 months'
   order by a.n desc, a.last_on asc
   limit 1;
$$;

-- D37: explicit, and public/anon never see it
revoke all on function public.last_round_with() from public, anon, authenticated;
grant execute on function public.last_round_with() to authenticated;
