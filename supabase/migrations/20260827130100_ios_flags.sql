-- ============================================================================
-- IOS-009 batch 1 (docs/ios/DECISIONS.md) · item 10 — the iOS build gate
--
-- app_flags gains a row keyed `ios`. The phone reads it on boot (also folded
-- into native_home().flags.ios, 20260827130400) and compares its own build
-- number — CFBundleVersion, the integer EAS stamps as ios.buildNumber — to
-- `min_build`. Below it, the app shows a forced-update screen that opens the
-- App Store and offers nothing else; at or above it, boot continues. This is
-- the native counterpart of the web client's stamped SHA + service worker
-- (audit 07 G15): an App Store build cannot self-update, so the server has
-- to be able to retire one.
--
-- Semantics of the row:
--   min_build  integer, 0 = nothing retired yet. Raise it from the SQL editor
--              (`update app_flags set value = value || '{"min_build": 42}',
--               updated_at = now() where key = 'ios'`) — no deploy, no push.
--   note       free text for the human at the wheel; the phone never shows it.
--
-- app_flags is readable by authenticated via `flags_read` (using (true)) and
-- has no write policy — writes are SQL-editor / migration only, which is the
-- point. Additive: the web client never reads this key.
--
-- The upsert lets an existing prod value WIN (`excluded || existing`), so if
-- the owner raised min_build by hand before this file ran, nothing lowers it.
-- ============================================================================

insert into public.app_flags (key, value) values
  ('ios', '{"min_build": 0, "note": "Raise min_build to retire every iOS build below it; the phone shows a forced-update screen. 0 = no gate."}'::jsonb)
on conflict (key) do update
  set value      = excluded.value || public.app_flags.value,
      updated_at = now();
