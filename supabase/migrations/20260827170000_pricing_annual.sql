-- ============================================================================
-- D101 (spec/decision-log.md) amending D56 / IOS-021 — the league pass is a
-- YEAR, priced 25% under the per-league comps.
--
-- Rewrites the `pricing` row seeded by 20260827160000:
--   unit             "year" — one pass covers every season the league runs in
--                    twelve months (the Ryder and Majors included).
--   anchor_cents     8900 — Golf League Tracker $119, Fantrax $130, MFL ~$110,
--                    LeagueLobster $228/yr → median ≈ $120, less 25%.
--   bands            $59 ≤9 · $89 10–13 · $109 14+ — fixed at the first roster
--                    lock of the year; the app quotes ONE number, never the table.
--   first_year_free  every league's first year is on us (replaces season1_free,
--                    which is removed; the phone still reads the old key if a
--                    hand-written value carries it).
--   visible          PRESERVED from the existing row (the owner's kill switch —
--                    this file never flips it either way; a fresh install seeds
--                    false, as before).
--   founding         PRESERVED from the existing row (PIGL's badge number, if
--                    the owner has written it).
--
-- Grants: none needed, none added — a table read through `flags_read`
-- (authenticated, using(true); 20260718045514). See 20260827160000.
-- ============================================================================

insert into public.app_flags (key, value) values
  ('pricing', '{
    "visible": false,
    "unit": "year",
    "anchor_cents": 8900,
    "bands": [
      { "max_roster": 9,  "cents": 5900 },
      { "max_roster": 13, "cents": 8900 },
      { "max_roster": 99, "cents": 10900 }
    ],
    "first_year_free": true,
    "founding": { "cap": 10, "closed": false, "ids": {} }
  }'::jsonb)
on conflict (key) do update
  set value = (
        (public.app_flags.value || excluded.value)                 -- the new unit and numbers win …
        || jsonb_build_object(
             'visible',  coalesce(public.app_flags.value->'visible',  'false'::jsonb),   -- … but the switch …
             'founding', coalesce(public.app_flags.value->'founding', excluded.value->'founding'))  -- … and the badges stay the owner's
      ) - 'season1_free',
      updated_at = now();
