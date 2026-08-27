-- ============================================================================
-- IOS-009 batch 1 (docs/ios/DECISIONS.md) · item 6 — handle_available()
--
-- The web infers "is this @handle free?" from search_golfers, which honours
-- `discoverable` — so a handle held by a `nobody` profile reads as available
-- until set_handle's unique_violation says otherwise. The phone gets a direct
-- yes/no instead, so the handle field can validate as the golfer types.
--
-- Contract:
--   * Normalisation mirrors set_handle (20260716070000) EXACTLY: strip every
--     '@' (set_handle uses replace(), not a leading-only strip), trim, lower.
--   * true  ⇔ well-formed (^[a-z0-9_]{3,20}$, not reserved) AND (unclaimed OR
--             already the caller's own).
--   * false otherwise — a malformed or reserved string is false, never an
--     exception, so the client has one code path.
--   * Never leaks WHO holds a handle: a boolean is the whole answer, and the
--     lookup ignores `discoverable` on purpose (that was the bug).
--   * Signed-out (auth.uid() null) → false; the function is authenticated-only
--     anyway.
--   * Comparison is on lower(handle), the same expression as the unique
--     index profiles_handle_key (20260712010000), so what this says is free
--     is exactly what set_handle will accept — modulo a race the client
--     handles by still catching set_handle's "That handle is taken".
--
-- Additive: no web caller. D37 grant discipline below.
-- ============================================================================

create or replace function public.handle_available(p_handle text)
returns boolean
language sql stable security definer set search_path = public as $$
  with n as (
    select lower(trim(both from replace(coalesce(p_handle, ''), '@', ''))) as v
  )
  select case
    when auth.uid() is null then false
    when n.v !~ '^[a-z0-9_]{3,20}$' then false
    when n.v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then false
    else not exists (
      select 1 from profiles p
       where lower(p.handle) = n.v
         and p.id <> auth.uid())
  end
  from n;
$$;

revoke all on function public.handle_available(text) from public, anon;
grant execute on function public.handle_available(text) to authenticated;
