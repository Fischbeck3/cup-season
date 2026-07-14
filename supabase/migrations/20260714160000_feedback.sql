-- Pilot feedback capture. Replaces the "report a bug" Google Form with an
-- in-app sheet, so the note arrives already tagged with WHERE the friction
-- happened (screen, league, version, device) — the one thing a Form can't see.
--
-- Framed for friction/confusion/ideas, not just breakage: category is a soft
-- hint, body is the signal. Writes go through a security-definer RPC under
-- auth.uid() (never a direct insert) so identity is set at the database.

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  category text not null default 'other'
    check (category in ('confusing','friction','idea','bug','other')),
  body text not null check (length(trim(body)) > 0),
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

-- A golfer can read back their own notes (the sheet confirms "sent"); the owner
-- reads everything via the service role in the SQL editor (bypasses RLS).
drop policy if exists feedback_own_select on public.feedback;
create policy feedback_own_select on public.feedback
  for select using (profile_id = auth.uid());

-- No direct-insert policy on purpose: all writes funnel through the RPC below.

create or replace function public.submit_feedback(
  p_category text, p_body text, p_context jsonb default '{}'::jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_cat text;
begin
  if auth.uid() is null then raise exception 'sign in to send feedback'; end if;
  if coalesce(trim(p_body), '') = '' then raise exception 'empty feedback'; end if;
  v_cat := lower(coalesce(nullif(trim(p_category), ''), 'other'));
  if v_cat not in ('confusing','friction','idea','bug','other') then v_cat := 'other'; end if;
  insert into public.feedback (category, body, context)
    values (v_cat, left(p_body, 4000), coalesce(p_context, '{}'::jsonb))
    returning id into v_id;
  return v_id;
end $$;

revoke all on function public.submit_feedback(text, text, jsonb) from public;
grant execute on function public.submit_feedback(text, text, jsonb) to authenticated;
