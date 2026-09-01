-- ============================================================================
-- Cup Season — a scanned round says so (D187, IOS-028 E9)
--
-- The composer hardcodes source = 'quick' on every post, so a round that came
-- from the scorecard scan is indistinguishable from two typed numbers. Prod at
-- the time of writing: 206 'quick', 5 'live', 0 from a scan — and none ever
-- could, because the value did not exist. `rounds_source_check` was widened to
-- ('quick','live','scan_claim') for the CLAIM path (20260718172300); the
-- poster's OWN scanned round was never given one.
--
-- 'scan' is a provenance label and nothing more. Nothing scores on it:
-- v_rounds_ranked never reads `source`, and the only readers are the
-- `coalesce(source,'app') <> 'sim'` filters in tour_card / share_info, which
-- 'scan' passes exactly as 'quick' does.
-- ============================================================================

alter table public.rounds drop constraint if exists rounds_source_check;
alter table public.rounds add constraint rounds_source_check
  check (source = any (array['quick'::text, 'live'::text, 'scan_claim'::text, 'scan'::text]));

comment on column public.rounds.source is
  'How the round got here: quick (typed) · scan (read off a photo, D187) · live (the tee sheet) · scan_claim (adopted from someone else''s scan).';
