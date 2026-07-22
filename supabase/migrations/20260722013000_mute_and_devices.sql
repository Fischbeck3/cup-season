-- ============================================================================
-- iOS arc W4 + W5 (spec/ios-wrapper-arc.md).
--
-- W4 · MUTE A MEMBER (App Store Guideline 1.2 wants report + block; report
--   ships since 20260718174500, block did not exist). Profile-level mutes,
--   enforced AT THE POLICY: posts_read and comments_read now exclude authors
--   the viewer muted, so every surface that reads those tables — the board,
--   chat, comment threads, realtime inserts (realtime respects RLS) — goes
--   quiet without a single client filter. Honest edge: home_feed() is a
--   definer and still shows a muted member's ROUNDS — scores are facts, not
--   messages; the harassment vectors (chat, comments, board posts) are the
--   policy-covered ones.
--
-- W5 · DEVICE TOKENS (APNs, dormant until the Mac phase). The wrapper's
--   WKWebView cannot receive web push; native tokens land here and the push
--   Edge Function grows an env-gated APNs branch. No client registers yet.
--
-- D37: explicit grants; the sweep discipline (revoke public) on every fn.
-- ============================================================================

-- ---- W4 · mutes ------------------------------------------------------------
create table if not exists public.mutes (
  muter      uuid not null references public.profiles(id) on delete cascade,
  muted      uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (muter, muted),
  constraint mutes_not_self check (muter <> muted)
);
alter table public.mutes enable row level security;
-- no API policies on purpose: writes via set_mute, reads via my_mutes.

create or replace function public.set_mute(p_profile uuid, p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if p_profile = auth.uid() then raise exception 'You cannot mute yourself'; end if;
  if p_on then
    insert into mutes (muter, muted) values (auth.uid(), p_profile)
    on conflict do nothing;
  else
    delete from mutes where muter = auth.uid() and muted = p_profile;
  end if;
end $$;
revoke all on function public.set_mute(uuid, boolean) from public, anon;
grant execute on function public.set_mute(uuid, boolean) to authenticated;

create or replace function public.my_mutes()
returns uuid[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(muted), '{}') from mutes where muter = auth.uid();
$$;
revoke all on function public.my_mutes() from public, anon;
grant execute on function public.my_mutes() to authenticated;

-- the policy is the enforcement point: a muted author's posts vanish for the
-- viewer everywhere posts are read (board, chat, realtime). System posts
-- (member_id null) always pass.
drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select to authenticated
  using (
    ((league_id is not null and is_league_member(league_id))
      or (event_id is not null and (is_event_member(event_id)
                                    or is_event_league_member(event_id))))
    and (member_id is null or not exists (
      select 1 from mutes mu
      join league_members lm on lm.id = posts.member_id
      where mu.muter = auth.uid() and mu.muted = lm.profile_id))
  );

-- comments inherit the parent post's visibility (the posts policy applies
-- inside the subquery), plus their own author-mute check.
drop policy if exists comments_read on public.post_comments;
create policy comments_read on public.post_comments for select to authenticated
  using (
    exists (select 1 from posts p where p.id = post_comments.post_id)
    and not exists (
      select 1 from mutes mu
      join league_members lm on lm.id = post_comments.member_id
      where mu.muter = auth.uid() and mu.muted = lm.profile_id)
  );

-- ---- W5 · device tokens (APNs, dormant) ------------------------------------
create table if not exists public.device_tokens (
  token      text primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform   text not null default 'ios' check (platform in ('ios')),
  created_at timestamptz not null default now()
);
create index if not exists device_tokens_profile_idx on public.device_tokens (profile_id);
alter table public.device_tokens enable row level security;
-- service-role reads (the push fn); writes via the RPC below.

create or replace function public.register_device_token(p_token text, p_platform text default 'ios')
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if coalesce(trim(p_token), '') = '' then raise exception 'empty token'; end if;
  insert into device_tokens (token, profile_id, platform)
  values (left(trim(p_token), 200), auth.uid(), coalesce(p_platform, 'ios'))
  on conflict (token) do update set profile_id = excluded.profile_id, created_at = now();
end $$;
revoke all on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
