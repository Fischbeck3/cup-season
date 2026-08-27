-- ============================================================================
-- IOS-021 (docs/ios/DECISIONS.md) executing D56 (spec/decision-log.md) — the
-- visible pricing model, NO checkout. Eng handoff: spec/handoffs/
-- pricing-integration-plan.md §1.
--
-- app_flags gains a row keyed `pricing`. The phone reads it (CupSeasonKit
-- `PricingFlags.load()`) and the three launch surfaces — the wizard's pot-step
-- pass card, the You-tab membership card, the League Room pot pane's Pro card
-- — render from it. Nothing else changes: zero mechanics, no schema for
-- leagues, no checkout, no Stripe (plan §0).
--
-- Seeded with `visible: false` — the plan's seed says true, but IOS-021 says
-- the OWNER flips it after confirming the anchor ("the flag makes either a
-- one-row change, not a rebuild"). Until then every surface renders today's
-- copy. Flip it from the SQL editor, no deploy:
--
--   update app_flags set value = value || '{"visible": true}', updated_at = now()
--    where key = 'pricing';
--
-- Semantics of the value:
--   visible       the kill switch. false → every pricing surface is today's copy.
--   anchor_cents  the headline number ($79); re-point after the focus-group
--                 script closes the price (discovery §1.6).
--   bands         banded flat (discovery §2): first band with roster ≤ max_roster
--                 wins — $49 ≤9 · $79 10–13 · $99 14+. The band fixes at roster
--                 lock; the app only ever quotes ONE number, never the table.
--   season1_free  every league's first season is on us (D56).
--   founding      cap 10, numbered. `ids` maps league uuid → badge number
--                 ({"<uuid>": 1} for PIGL) — seeded EMPTY here; the owner writes
--                 PIGL's id by hand. At ≤10 leagues a flag map beats a schema
--                 change (plan §1).
--
-- Grants: NONE needed, and none added. This is a table read, not an RPC.
-- Verified against 20260718045514_photos_scan_spine.sql:
--   alter table public.app_flags enable row level security;
--   create policy flags_read on public.app_flags for select to authenticated using (true);
-- — `authenticated` reads every row; there is no write policy (writes are
-- SQL-editor / migration only, which is the point); anon holds nothing here
-- (D37), and the front door stays pricing-free (D56 upholds) so anon never
-- needs it. `scan` and `ios` already read through exactly this policy in prod.
--
-- The upsert lets an existing prod value WIN (`excluded || existing`, the
-- 20260827130100 shape): if the owner seeded or flipped `pricing` by hand
-- before this file ran, nothing here un-flips it.
-- ============================================================================

insert into public.app_flags (key, value) values
  ('pricing', '{
    "visible": false,
    "anchor_cents": 7900,
    "bands": [
      { "max_roster": 9,  "cents": 4900 },
      { "max_roster": 13, "cents": 7900 },
      { "max_roster": 99, "cents": 9900 }
    ],
    "season1_free": true,
    "founding": { "cap": 10, "closed": false, "ids": {} }
  }'::jsonb)
on conflict (key) do update
  set value      = excluded.value || public.app_flags.value,
      updated_at = now();
