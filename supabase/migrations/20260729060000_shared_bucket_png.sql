-- ============================================================================
-- Cup Season — D89: the settlement card can actually travel
--
-- THE BUG, measured in prod 2026-07-29. A settled match shared as a link
-- previewed with the generic brand image instead of its own settlement card.
-- The title was right ("Jerecho Fischbeck def. Jade 4&3" — the edge function
-- did its job); the picture was the fallback. Cause: the `shared` bucket was
-- created with allowed_mime_types = {image/jpeg}, and the settlement card is a
-- PNG. Every upload since D78 was rejected at the bucket.
--
-- It failed INVISIBLY by design-in-depth, which is why it survived: the client
-- catches the upload error and logs "link ships card-less" (best effort, never
-- blocks the share), and the edge function HEADs the object and falls back to
-- the brand image rather than pointing a scraper at a 404. Three deliberate
-- safety nets, each working, adding up to a feature that had never once
-- succeeded — `storage.objects` for this bucket was EMPTY all-time.
--
-- The card is flat-colour type on a dark ground: PNG is the right encoding
-- (JPEG rings the letterforms), so the bucket learns PNG rather than the card
-- being downgraded to fit the bucket.
--
-- Lesson worth keeping: an upload path whose every failure is swallowed needs
-- something that FAILS LOUDLY once — a check, a test, or a probe. The photo
-- path shipped .jpg and worked, which made the shared bucket look healthy.
-- ============================================================================

update storage.buckets
   set allowed_mime_types = array['image/jpeg','image/png']
 where id = 'shared';

do $$
declare v text[];
begin
  select allowed_mime_types into v from storage.buckets where id = 'shared';
  if v is null or not ('image/png' = any(v)) then
    raise exception 'shared bucket still refuses image/png — settlement cards cannot travel';
  end if;
end $$;
