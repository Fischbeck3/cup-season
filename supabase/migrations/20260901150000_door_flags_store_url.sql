-- ============================================================================
-- Cup Season — the door knows where the app lives (D188, IOS-028 E8)
--
-- Every share link the phone mints lands a stranger on the web PWA, and
-- nothing on that page has ever mentioned that an iPhone app exists —
-- `grep -r "apps.apple.com"` over the whole repo returned nothing. The share
-- page is ANON, and `app_flags` is readable only by `authenticated` (policy
-- flags_read), so the URL cannot come from a table read there.
--
-- door_flags() is already the anon door's one flag endpoint (IOS-023) and one
-- of the twelve public functions. It grows a key rather than the anon surface
-- growing a thirteenth: `app_store_url`, null until the owner sets it, so the
-- CTA cannot appear before there is a listing to point at.
--
--   update app_flags set value = value || '{"app_store_url":"https://apps.apple.com/app/id..."}'::jsonb
--    where key = 'ios';
--
-- Reversibility: set it back to null and the button disappears everywhere.
-- ============================================================================

create or replace function public.door_flags()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'apple_sign_in',
    coalesce((select (value->>'apple_sign_in')::boolean from public.app_flags where key = 'ios'), false),
    -- D188: null until a listing exists. Every consumer treats absent as "no
    -- app to send them to" and shows nothing, so a half-configured flag can
    -- never render a dead App Store link into somebody's group thread.
    'app_store_url',
    nullif(trim(coalesce((select value->>'app_store_url' from public.app_flags where key = 'ios'), '')), '')
  );
$$;

-- D37: same grants, restated — the default-privilege flip binds to `postgres`,
-- not every migration runner, so a re-created function can pick up PUBLIC.
revoke all on function public.door_flags() from public;
grant execute on function public.door_flags() to anon, authenticated;
