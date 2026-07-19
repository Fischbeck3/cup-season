-- ============================================================================
-- Security hardening — medium (audit 2026-07-18, spec/launch-audit-2026-07-18.md).
-- Companion to 20260718172300 (launch blockers). Everything here is verified
-- non-breaking: a new read policy that fails to a broken image (never a crash),
-- CHECKs added NOT VALID (existing pilot rows are never re-validated), policy
-- drops on mostly-dead tables, and one FK on-delete change.
--
-- Note: this migration creates a function AFTER 20260718172300 flipped the
-- default privileges, so it must (and does) grant execute explicitly — exactly
-- the discipline that flip enforces.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- M3 · media bucket was readable by EVERY authenticated user (media_read
--   USING bucket_id='media') — any signed-in user could enumerate + download
--   every round photo and scanned scorecard app-wide. Scope reads to people you
--   actually share a connection with: yourself, a league-mate, or an accepted
--   friend. Signed-URL minting for anyone else fails to a broken image, not an
--   error. Own-prefix write/delete (from the photos migration) is unchanged.
-- ---------------------------------------------------------------------------
create or replace function public.can_see_media(p_owner text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare o uuid;
begin
  if p_owner is null then return false; end if;
  if p_owner = auth.uid()::text then return true; end if;     -- own media
  begin o := p_owner::uuid; exception when others then return false; end;
  if exists (select 1 from league_members a
             join league_members b on b.league_id = a.league_id
             where a.profile_id = auth.uid() and b.profile_id = o) then
    return true;                                              -- a league-mate's
  end if;
  if exists (select 1 from friendships f
             where f.status = 'accepted'
               and ((f.requester = auth.uid() and f.addressee = o)
                 or (f.requester = o and f.addressee = auth.uid()))) then
    return true;                                              -- an accepted friend's
  end if;
  return false;
end $$;
revoke all on function public.can_see_media(text) from public;
grant execute on function public.can_see_media(text) to authenticated;

drop policy if exists media_read on storage.objects;
create policy media_read on storage.objects for select to authenticated
  using (bucket_id = 'media' and public.can_see_media((storage.foldername(name))[1]));

-- ---------------------------------------------------------------------------
-- M7 · Round facts had no sanity bounds — slope = 1 yields a differential in
--   the hundreds. Add generous WHS-range CHECKs, NOT VALID so existing rows are
--   never re-validated (only new inserts/updates are checked). Rating stays the
--   18-hole course rating even for 9-hole rounds (nine_rating carries the half),
--   so 25–90 is safe headroom. (The played_on future-bound needs a trigger —
--   current_date isn't immutable enough for a CHECK — and is deferred; see the
--   handoff.)
-- ---------------------------------------------------------------------------
alter table public.rounds add constraint rounds_rating_sane
  check (rating between 25 and 90) not valid;
alter table public.rounds add constraint rounds_slope_sane
  check (slope between 55 and 155) not valid;

-- ---------------------------------------------------------------------------
-- M1 (#27) · The courses Edge Function calls a PAID third-party API with no
--   caller check and no cap — anyone holding the public anon key could drain
--   the GolfCourseAPI quota. The function gains a real user gate (below); this
--   is its cost ledger + cap, mirroring scan_usage. Service-role only (no API
--   policy), and the cap is retunable from the SQL editor via app_flags.
-- ---------------------------------------------------------------------------
create table if not exists public.courses_usage (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  action     text,
  created_at timestamptz not null default now()
);
create index if not exists courses_usage_idx on public.courses_usage (profile_id, created_at);
alter table public.courses_usage enable row level security;   -- service-role only, like scan_usage

insert into public.app_flags (key, value) values
  ('courses', '{"daily_per_user": 150}'::jsonb)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- L3 · Legacy course-write policies let any authenticated user add tees/holes
--   to anyone's course (source='manual'). Live course data moved to the
--   read-only api_* tables (service-role writes) long ago; these legacy tables
--   are near-dead FK targets. Drop the poisoning surface.
-- ---------------------------------------------------------------------------
drop policy if exists "courses_add" on public.courses;
drop policy if exists "courses_edit" on public.courses;
drop policy if exists "tees_add"   on public.course_tees;
drop policy if exists "holes_add"  on public.course_holes;

-- ---------------------------------------------------------------------------
-- L6 · rounds.season_id was ON DELETE CASCADE — deleting a league could delete
--   rounds carrying that season_id ("never the golf" says otherwise). Repoint
--   to SET NULL: a departed league leaves the round as a personal round.
--   (delete_league is already setup-only-guarded, so the blast radius is small;
--   this closes the legacy path.)
-- ---------------------------------------------------------------------------
alter table public.rounds drop constraint if exists rounds_season_id_fkey;
alter table public.rounds add constraint rounds_season_id_fkey
  foreign key (season_id) references public.seasons(id) on delete set null;
