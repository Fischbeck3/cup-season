-- ============================================================================
-- Public-launch UGC safety (audit 2026-07-18 follow-on). Additive and safe:
-- a new report table + RPC, storage upload limits, and a future-date guard on
-- rounds. Nothing here changes existing behavior for honest users.
--
-- Note: report_content is created AFTER the default-privilege flip
-- (20260718172300), so it grants execute explicitly — per the CLAUDE.md rule.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Content reports — when signups open to strangers, the boards need a "report"
-- path. One row per (post, reporter); writes flow through the RPC; reads are
-- service-role/dashboard only (a founder review UI is a follow-up).
-- ---------------------------------------------------------------------------
create table if not exists public.content_reports (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  reporter   uuid not null references public.profiles(id) on delete cascade,
  reason     text,
  resolved   boolean not null default false,
  created_at timestamptz not null default now(),
  unique (post_id, reporter)
);
create index if not exists content_reports_open_idx on public.content_reports (resolved, created_at);
alter table public.content_reports enable row level security;
-- no API policies on purpose: the RPC is the only writer, service role reads.

create or replace function public.report_content(p_post uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); v_league uuid;
begin
  if v is null then raise exception 'not signed in'; end if;
  select league_id into v_league from posts where id = p_post;
  if v_league is null then raise exception 'That post no longer exists'; end if;
  if not is_league_member(v_league) then
    raise exception 'You can only report posts in your own leagues';
  end if;
  insert into content_reports (post_id, reporter, reason)
  values (p_post, v, nullif(trim(coalesce(p_reason, '')), ''))
  on conflict (post_id, reporter)
    do update set reason = excluded.reason, created_at = now(), resolved = false;
end $$;
revoke all on function public.report_content(uuid, text) from public;
grant execute on function public.report_content(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Storage upload limits on the media bucket. The client already compresses to
-- JPEG well under this; the cap + MIME allowlist stop a hostile user from
-- uploading huge or non-image files directly with their token. (Project-wide
-- default was 50 MiB with no type restriction.)
-- ---------------------------------------------------------------------------
update storage.buckets
   set file_size_limit = 8388608,                                    -- 8 MB
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
 where id = 'media';

-- ---------------------------------------------------------------------------
-- Round dates can't be in the future (the M7 remainder — a CHECK can't use
-- current_date, so it's a trigger). +1 day of slack absorbs timezone edges
-- (Phoenix "today" vs UTC). Fires on the definer write paths too, which is
-- correct — nobody should post a round dated next week.
-- ---------------------------------------------------------------------------
create or replace function public.rounds_no_future() returns trigger
language plpgsql set search_path = public as $$
begin
  if new.played_on > current_date + 1 then
    raise exception 'A round date can''t be in the future';
  end if;
  return new;
end $$;
drop trigger if exists rounds_no_future_trg on public.rounds;
create trigger rounds_no_future_trg before insert or update on public.rounds
  for each row execute function public.rounds_no_future();
