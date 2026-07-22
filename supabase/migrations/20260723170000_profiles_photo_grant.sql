-- ============================================================================
-- HOTFIX — profiles.photo_path was unreadable (boot fell to the card gate)
--
-- The email seal (20260721214500) revoked table-level SELECT on profiles and
-- granted an EXPLICIT column list — frozen at that day's columns. photo_path
-- (20260723150000) was never granted, so every authenticated select naming it
-- failed 42501 "permission denied for table profiles" — a message that does
-- NOT contain the column name, so the client's photo_path-shaped skew retry
-- never fired: CS.profile loaded null, boot gated on the golfer card, league
-- loads failed the same way and the app read as demo mode (pilot, 2026-07-23).
--
-- Law going forward (now in CLAUDE.md): a SEALED table's column grants are
-- FROZEN — every migration adding a column to profiles must grant SELECT on
-- it to authenticated in the same file. db-checks check 9 now asserts every
-- non-email profiles column is readable, not just that email is sealed.
-- ============================================================================

grant select (photo_path) on public.profiles to authenticated;
