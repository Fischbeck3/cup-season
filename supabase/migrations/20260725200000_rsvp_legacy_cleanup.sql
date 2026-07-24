-- ============================================================================
-- Cup Season — deep-dive fix, RSVP cleanup (audit b7: finding #3)
--
-- D69 (20260725160000) stopped NEW external RSVPs, but rows written before it
-- remain — a non-tagged league-mate who had set In still shows in round_detail's
-- who's-in list and inflates the "N in" count + my_schedule.rsvp_in. Remove the
-- rows whose responder is neither the round's host nor one of its tagged
-- players, so the read paths match the write rule going forward. Idempotent,
-- and negligible data (pilot only).
-- ============================================================================

delete from public.round_rsvp rr
 using public.scheduled_rounds sr
 where rr.round_id = sr.id
   and rr.profile_id <> sr.profile_id
   and not (rr.profile_id = any(coalesce(sr.tagged, '{}'::uuid[])));
