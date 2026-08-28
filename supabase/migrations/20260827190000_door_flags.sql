-- ============================================================================
-- IOS-023 (docs/ios/DECISIONS.md) — the door is signed out, and app_flags is
-- readable by `authenticated` only. `door_flags()` is the one anon-callable
-- window onto the flag row, and it returns exactly one boolean: whether the
-- Sign in with Apple button shows. Nothing else in app_flags leaks through it.
--
-- Anon endpoint № 11 (CLAUDE.md lists the public ones). Fail-closed by
-- construction: a missing row or key reads false.
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
    coalesce((select (value->>'apple_sign_in')::boolean from public.app_flags where key = 'ios'), false)
  );
$$;

revoke all on function public.door_flags() from public;
grant execute on function public.door_flags() to anon, authenticated;
