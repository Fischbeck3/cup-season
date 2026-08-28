-- ============================================================================
-- IOS-026 follow-up — a device token carries its APNs environment.
--
-- A Debug build on a tethered phone holds a SANDBOX token; a TestFlight or
-- App Store build holds a PRODUCTION token. Apple runs two hosts and a token
-- sent to the wrong one comes back BadDeviceToken — which the sender treats as
-- dead and PRUNES (runbook D5). Until now one global secret (APNS_SANDBOX)
-- chose the host for everyone, so a dev phone and a TestFlight phone could not
-- both receive push. Now the phone registers `ios-sandbox` from a Debug build
-- and `ios` otherwise, and the sender routes each token to its own host.
-- register_device_token() is unchanged — it already takes p_platform.
-- ============================================================================

alter table public.device_tokens drop constraint if exists device_tokens_platform_check;
alter table public.device_tokens
  add constraint device_tokens_platform_check check (platform in ('ios', 'ios-sandbox'));
