-- ============================================================================
-- register_device_token(): a re-registration also updates `platform`.
-- 20260828010000 introduced `ios-sandbox` for Debug builds, but the upsert's
-- on-conflict branch only refreshed profile_id/created_at, so a phone that
-- moved from a TestFlight build to a Debug build (or back) kept its old
-- environment and Apple rejected the push. Same signature, same grants.
-- ============================================================================

create or replace function public.register_device_token(p_token text, p_platform text default 'ios')
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if coalesce(trim(p_token), '') = '' then raise exception 'empty token'; end if;
  insert into device_tokens (token, profile_id, platform)
  values (left(trim(p_token), 200), auth.uid(), coalesce(p_platform, 'ios'))
  on conflict (token) do update
    set profile_id = excluded.profile_id,
        platform   = excluded.platform,
        created_at = now();
end $$;
revoke all on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
