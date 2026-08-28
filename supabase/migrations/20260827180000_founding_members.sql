-- ============================================================================
-- D102 (spec/decision-log.md) — Founder and Founding Member: two earned tags
-- on the GOLFER (the league-level Founding badge is D56's, separate).
--
--   profiles.founding_member   hand-picked by the owner in the SQL editor;
--                              never self-service, no RPC writes it.
--   founding_ids()             {founder: uuid|null, members: [uuid…]} — one
--                              read per session; the phone tags a name
--                              wherever it appears. founder_id() (anon, the
--                              web's badge) is untouched and stays the
--                              deploy-skew fallback.
--
-- Landmine (CLAUDE.md): the profiles column-grant list is FROZEN — a new
-- column MUST be granted here or every select naming it fails 42501.
-- D37: explicit grant to authenticated, explicit revoke from public/anon.
-- ============================================================================

alter table public.profiles
  add column if not exists founding_member boolean not null default false;

grant select (founding_member) on public.profiles to authenticated;

create or replace function public.founding_ids()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'founder', (select id from public.profiles where is_founder and deleted_at is null limit 1),
    'members', coalesce(
      (select jsonb_agg(id order by created_at)
         from public.profiles
        where founding_member and deleted_at is null),
      '[]'::jsonb)
  );
$$;

revoke all on function public.founding_ids() from public, anon;
grant execute on function public.founding_ids() to authenticated;

-- The owner tags friends from the SQL editor, e.g.
--   update public.profiles set founding_member = true where handle in ('galen', 'ed');
