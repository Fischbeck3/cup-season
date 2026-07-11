-- ============================================================================
-- Cup Season — push notifications, the retention engine
--
-- One table holds browser push subscriptions (a profile can have several:
-- phone + desktop). The board (posts) is the app's nervous system, so a
-- single Database Webhook on posts INSERT -> edge function `push` covers
-- every moment worth pushing: chat, round fan-outs, reveals, month closes.
-- Scope decision (2026-07-11): all board posts push, with a per-user chat
-- mute (profiles.notify_chat) so the noise-averse keep game events only.
-- ============================================================================

alter table public.profiles
  add column if not exists notify_chat boolean not null default true;

create table public.push_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  endpoint   text not null unique,
  p256dh     text not null,
  auth       text not null,
  created_at timestamptz not null default now()
);

alter table public.push_subscriptions enable row level security;

create policy push_own_select on public.push_subscriptions
  for select to authenticated using (profile_id = auth.uid());
create policy push_own_insert on public.push_subscriptions
  for insert to authenticated with check (profile_id = auth.uid());
create policy push_own_update on public.push_subscriptions
  for update to authenticated using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
create policy push_own_delete on public.push_subscriptions
  for delete to authenticated using (profile_id = auth.uid());

create or replace function public.set_notify_chat(p_on boolean) returns void
language sql security definer
set search_path = public
as $$ update profiles set notify_chat = p_on where id = auth.uid(); $$;

grant execute on function public.set_notify_chat(boolean) to authenticated;
