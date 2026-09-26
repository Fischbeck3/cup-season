-- Cup Season — a posted round keeps one conversation, and a reply finds its golfer (D391).
--
-- THE DISTINCTION THIS FILE PRESERVES: `round_comments` / `add_round_comment` belong
-- to SCHEDULED rounds (round_comments.round_id → scheduled_rounds). They are not
-- touched. Posted-round conversation has always lived on the round's BOARD POST in
-- `post_comments` — one thread per league the round fanned into, keyed to
-- `league_members`, so a buddy outside the league could never answer and a
-- person-homed round (D238) could take no comment at all.
--
-- WHAT CHANGES, ALL ADDITIVE:
--   1 · `post_comments` is EXTENDED, not duplicated: a round-keyed row (round_id set,
--       post_id null) carries its author profile, the comment it answers, the root it
--       hangs under and the client's idempotency key. The legacy board policy keys on
--       post_id, so these rows are invisible to direct selects and to Realtime; they are
--       read only through the definer RPCs below. Legacy board rows are unchanged and
--       keep their league-only visibility.
--   2 · per-thread follow / mute, and three notification switches.
--   3 · `social_notifications` — persistent, one per recipient per comment, RPC-only.
--   4 · the RPCs (contract: docs/planning/2026-09-25-d391-social-course-contract.md):
--       posted_round_thread · add_posted_round_comment ·
--       remove_posted_round_comment · set_round_thread_state · social_notify_prefs ·
--       set_social_notify_prefs · my_notifications · notification_badge ·
--       mark_notifications_read.
--   5 · moderation reaches the new rows: report_content / hide_content /
--       unhide_content / moderation_queue are PATCHED at an anchor (the D-contract
--       pattern), never re-created whole, so nothing else in them moves.
--   6 · push rides push_nudges (kind 'comment') and is DARK behind
--       app_flags.social_comment_push until the phone can route it (D248's order).
--
-- L-03: every write is a definer RPC. L-04: every client-called function is revoked
-- from public/anon and granted to authenticated only; helpers are granted to nobody.
-- No competition mechanic, scoring rule or identity field changes.

-- ─────────────────────────────────────────────── 1 · post_comments, extended
alter table public.post_comments
  add column if not exists round_id   uuid references public.rounds(id)        on delete cascade,
  add column if not exists profile_id uuid references public.profiles(id)      on delete cascade,
  add column if not exists parent_id  uuid references public.post_comments(id) on delete set null,
  add column if not exists root_id    uuid references public.post_comments(id) on delete set null,
  add column if not exists client_id  uuid;

alter table public.post_comments alter column post_id   drop not null;
alter table public.post_comments alter column member_id drop not null;

alter table public.post_comments drop constraint if exists post_comments_home_check;
alter table public.post_comments add constraint post_comments_home_check
  check (post_id is not null or round_id is not null);
-- a round row has an author and no post; a board row stays flat (no reply graph a
-- league-only thread could leak through)
alter table public.post_comments drop constraint if exists post_comments_shape_check;
alter table public.post_comments add constraint post_comments_shape_check
  check (
    (round_id is null or (post_id is null and profile_id is not null))
    and (post_id is null or (parent_id is null and root_id is null))
  );
-- legacy rows are left alone (a hide on an old long comment must still work)
alter table public.post_comments drop constraint if exists post_comments_round_body_len;
alter table public.post_comments add constraint post_comments_round_body_len
  check (round_id is null or char_length(body) between 1 and 500);

create index if not exists post_comments_round_idx
  on public.post_comments (round_id, created_at) where round_id is not null;
create unique index if not exists post_comments_client_uni
  on public.post_comments (profile_id, client_id) where client_id is not null;
create index if not exists post_comments_author_recent
  on public.post_comments (profile_id, created_at) where round_id is not null;

comment on column public.post_comments.round_id is
  'D391 · a posted-round conversation row (post_id null). Read only through posted_round_thread.';

-- ─────────────────────────────────────────────── 2 · thread state + prefs
create table if not exists public.round_thread_states (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  round_id   uuid not null references public.rounds(id)   on delete cascade,
  state      text not null check (state in ('following', 'muted')),
  updated_at timestamptz not null default now(),
  primary key (profile_id, round_id)
);
create index if not exists round_thread_states_following
  on public.round_thread_states (round_id) where state = 'following';

create table if not exists public.social_notify_prefs (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  own_round  boolean not null default true,
  replies    boolean not null default true,
  followed   boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────── 3 · notifications
create table if not exists public.social_notifications (
  id         uuid primary key default gen_random_uuid(),
  recipient  uuid not null references public.profiles(id)      on delete cascade,
  actor      uuid not null references public.profiles(id)      on delete cascade,
  kind       text not null check (kind in ('reply', 'own_round', 'followed')),
  round_id   uuid not null references public.rounds(id)        on delete cascade,
  comment_id uuid not null references public.post_comments(id) on delete cascade,
  created_at timestamptz not null default now(),
  read_at    timestamptz,
  unique (recipient, comment_id),
  check (recipient <> actor)
);
create index if not exists social_notifications_inbox
  on public.social_notifications (recipient, created_at desc);
create index if not exists social_notifications_unread
  on public.social_notifications (recipient) where read_at is null;

-- RPC-only: RLS on, no policies, no grants (anon holds nothing in public — D37)
alter table public.round_thread_states  enable row level security;
alter table public.social_notify_prefs  enable row level security;
alter table public.social_notifications enable row level security;
revoke all on table public.round_thread_states  from public, anon, authenticated;
revoke all on table public.social_notify_prefs  from public, anon, authenticated;
revoke all on table public.social_notifications from public, anon, authenticated;

-- the dark switch for the lock-screen half (the in-app half is always on)
insert into public.app_flags (key, value)
values ('social_comment_push', '{"enabled": false, "note": "D391 · flip once the phone routes kind=comment (PushKind) and the push Edge function carrying it is deployed."}'::jsonb)
on conflict (key) do nothing;

-- push_nudges learns the kind; the list is the live one plus 'comment'
alter table public.push_nudges drop constraint if exists push_nudges_kind_check;
alter table public.push_nudges add constraint push_nudges_kind_check
  check (kind = any (array['nudge','invite','request','rsvp','callout','rank_change',
    'clash_pressure','clash_verdict','index_live','tee_tomorrow','season_countdown',
    'friend_round','seat_open','season_cancel','comment']));

-- ─────────────────────────────────────────────── 4 · helpers (granted to nobody)

-- The circle, verbatim from home_feed / post_round: me · accepted buddies (either
-- direction) · league mates · event mates. `discoverable` is deliberately absent —
-- it is the search gate, not consent to publish a score (D245 clause 4, D391 §2).
create or replace function public._social_circle(p_viewer uuid)
returns table (pid uuid, relation text)
language sql stable security definer set search_path to 'public'
as $$
  select s.pid, (array_agg(s.rel order by s.pri))[1]
    from (
      select p_viewer as pid, 'me'::text as rel, 0 as pri
      union all
      select case when f.requester = p_viewer then f.addressee else f.requester end, 'friend', 1
        from friendships f
       where f.status = 'accepted' and (f.requester = p_viewer or f.addressee = p_viewer)
      union all
      select b.profile_id, 'league', 2
        from league_members a join league_members b on b.league_id = a.league_id
       where a.profile_id = p_viewer and b.profile_id is not null
      union all
      select b.profile_id, 'event', 3
        from event_players a join event_players b on b.event_id = a.event_id
       where a.profile_id = p_viewer and b.profile_id is not null
    ) s
   where p_viewer is not null and s.pid is not null
   group by s.pid;
$$;

-- `mutes` is the product's block. For these surfaces it cuts BOTH ways.
create or replace function public._social_blocked(p_a uuid, p_b uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select p_a is not null and p_b is not null and p_a <> p_b and exists (
    select 1 from mutes m
     where (m.muter = p_a and m.muted = p_b) or (m.muter = p_b and m.muted = p_a));
$$;

create or replace function public._social_in_circle(p_viewer uuid, p_other uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select p_viewer is not null and p_other is not null and (
       p_viewer = p_other
    or exists (select 1 from friendships f where f.status = 'accepted'
                 and ((f.requester = p_viewer and f.addressee = p_other)
                   or (f.addressee = p_viewer and f.requester = p_other)))
    or exists (select 1 from league_members a join league_members b on b.league_id = a.league_id
                where a.profile_id = p_viewer and b.profile_id = p_other)
    or exists (select 1 from event_players a join event_players b on b.event_id = a.event_id
                where a.profile_id = p_viewer and b.profile_id = p_other));
$$;

-- A posted round R is visible to V: R exists, not void, owner not deleted, owner in
-- V's circle, and no mute either way. Invisible and non-existent are the same answer.
create or replace function public._posted_round_visible(p_viewer uuid, p_round uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select exists (
    select 1
      from rounds r
      join profiles o on o.id = r.profile_id and o.deleted_at is null
     where r.id = p_round and not r.voided and p_viewer is not null
       and (r.profile_id = p_viewer
            or (public._social_in_circle(p_viewer, r.profile_id)
                and not public._social_blocked(p_viewer, r.profile_id))));
$$;

create or replace function public._social_person(p_profile uuid)
returns jsonb
language sql stable security definer set search_path to 'public'
as $$
  select jsonb_build_object('id', p.id, 'name', p.display_name,
                            'marker', p.marker, 'handle', p.handle)
    from profiles p where p.id = p_profile and p.deleted_at is null;
$$;

-- A round's tee, NEVER INVENTED (L-44). `rounds` has no tee column. The tee is known
-- only when the round's api course has cached tees at exactly its (rating, slope) and
-- the match is unambiguous: the tee the picker's label names after its last " · "
-- among those candidates, else the single distinct tee name among them.
create or replace function public._round_tee(p_api_course text, p_label text,
                                              p_rating numeric, p_slope integer)
returns table (tee_key text, tee_name text, gender text)
language sql stable security definer set search_path to 'public'
as $$
  with cand as (
    select btrim(t.tee_name) as nm, t.gender
      from api_course_tees t
     where p_api_course is not null
       and t.course_id = p_api_course
       and t.course_rating = p_rating and t.slope_rating = p_slope
       and nullif(btrim(t.tee_name), '') is not null
  ),
  suffix as (
    select lower(btrim(regexp_replace(p_label, '^.* · ', ''))) as s
     where position(' · ' in coalesce(p_label, '')) > 0
  ),
  named as (select * from cand where lower(cand.nm) = (select s from suffix)),
  chosen as (
    select * from named
    union all
    select * from cand
     where not exists (select 1 from named)
       and (select count(distinct lower(nm)) from cand) = 1
  )
  select lower(min(c.nm)) || '@' || (p_rating::numeric(4,1))::text || '/' || p_slope::text,
         min(c.nm),
         case when count(distinct coalesce(c.gender, '')) = 1 then min(c.gender) end
    from chosen c
  having count(*) > 0;
$$;

-- The rows of one posted round's conversation that the CALLER may read: round-keyed
-- rows plus legacy board comments on that round's posts in leagues the caller is in.
-- Hidden rows, hidden posts, deleted authors and mutes either way are excluded.
create or replace function public._round_thread_rows(p_round uuid)
returns table (id uuid, parent_id uuid, root_id uuid, author uuid, body text,
               created_at timestamptz, origin text)
language sql stable security definer set search_path to 'public'
as $$
  select x.id, x.parent_id, x.root_id, x.author, x.body, x.created_at, x.origin
    from (
      select c.id, c.parent_id, c.root_id, c.profile_id as author, c.body, c.created_at,
             'round'::text as origin
        from post_comments c
       where c.round_id = p_round and c.post_id is null and c.hidden_at is null
      union all
      select c.id, null::uuid, null::uuid, lm.profile_id, c.body, c.created_at, 'board'
        from posts p
        join post_comments c  on c.post_id = p.id
        join league_members lm on lm.id = c.member_id
       where p.round_id = p_round and p.hidden_at is null and c.hidden_at is null
         and p.league_id is not null and is_league_member(p.league_id)
    ) x
    join profiles a on a.id = x.author and a.deleted_at is null
   where not public._social_blocked(auth.uid(), x.author);
$$;

revoke all on function public._social_circle(uuid)                        from public, anon, authenticated;
revoke all on function public._social_blocked(uuid, uuid)                 from public, anon, authenticated;
revoke all on function public._social_in_circle(uuid, uuid)               from public, anon, authenticated;
revoke all on function public._posted_round_visible(uuid, uuid)           from public, anon, authenticated;
revoke all on function public._social_person(uuid)                        from public, anon, authenticated;
revoke all on function public._round_tee(text, text, numeric, integer)    from public, anon, authenticated;
revoke all on function public._round_thread_rows(uuid)                    from public, anon, authenticated;

-- ─────────────────────────────────────────────── 5 · the thread read
create or replace function public._round_comment_json(p_id uuid)
returns jsonb
language sql stable security definer set search_path to 'public'
as $$
  select jsonb_build_object(
    'id', t.id, 'round_id', c.round_id_eff,
    'parent_id', t.parent_id, 'root_id', t.root_id,
    'reply_to', (select jsonb_build_object('id', pt.id, 'name', pp.display_name)
                   from public._round_thread_rows(c.round_id_eff) pt
                   join profiles pp on pp.id = pt.author
                  where pt.id = t.parent_id and pt.origin = 'round'),
    'author', public._social_person(t.author),
    'body', t.body, 'created_at', t.created_at, 'origin', t.origin,
    'is_mine', t.author = auth.uid(),
    'can_reply', t.origin = 'round')
  from (select coalesce(pc.round_id, po.round_id) as round_id_eff
          from post_comments pc left join posts po on po.id = pc.post_id
         where pc.id = p_id) c
  join lateral public._round_thread_rows(c.round_id_eff) t on t.id = p_id;
$$;
revoke all on function public._round_comment_json(uuid) from public, anon, authenticated;

create or replace function public.posted_round_thread(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare
  v uuid := auth.uid();
  r record;
  v_state text;
  v_rows jsonb;
  v_count int;
  v_tee record;
  v_prefs jsonb;
begin
  if v is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  if p_round is null or not public._posted_round_visible(v, p_round) then
    return jsonb_build_object('ok', false, 'reason', 'not_visible');
  end if;

  select * into r from rounds where id = p_round;
  select * into v_tee from public._round_tee(r.api_course_id, r.course_label, r.rating, r.slope);
  select s.state into v_state from round_thread_states s where s.profile_id = v and s.round_id = p_round;

  select count(*)::int into v_count from public._round_thread_rows(p_round);
  select coalesce(jsonb_agg(j order by (j->>'created_at')::timestamptz, j->>'id'), '[]'::jsonb) into v_rows
    from (
      select jsonb_build_object(
               'id', t.id, 'round_id', p_round,
               'parent_id', t.parent_id, 'root_id', t.root_id,
               'reply_to', (select jsonb_build_object('id', pt.id, 'name', pp.display_name)
                              from public._round_thread_rows(p_round) pt
                              join profiles pp on pp.id = pt.author
                             where pt.id = t.parent_id and pt.origin = 'round'),
               'author', public._social_person(t.author),
               'body', t.body, 'created_at', t.created_at, 'origin', t.origin,
               'is_mine', t.author = v,
               'can_reply', t.origin = 'round') as j
        from public._round_thread_rows(p_round) t
       order by t.created_at, t.id
       limit 200
    ) s;

  select jsonb_build_object('own_round', coalesce(sp.own_round, true),
                            'replies',   coalesce(sp.replies, true),
                            'followed',  coalesce(sp.followed, true))
    into v_prefs
    from (select 1) one left join social_notify_prefs sp on sp.profile_id = v;

  return jsonb_build_object(
    'ok', true,
    'round', jsonb_build_object(
      'id', r.id, 'owner', public._social_person(r.profile_id), 'is_mine', r.profile_id = v,
      'gross', r.gross, 'holes', r.holes_played, 'played_on', r.played_on,
      'course', jsonb_build_object(
        'api_course_id', r.api_course_id,
        'name', course_name_of(r.api_course_id, r.course_label),
        'label', r.course_label,
        'tee_name', v_tee.tee_name, 'tee_key', v_tee.tee_key),
      'photo_path', r.photo_path),
    'can_comment', true,
    'comment_block_reason', null,
    'thread', jsonb_build_object('state', coalesce(v_state, 'none'),
                                 'following', coalesce(v_state = 'following', false),
                                 'muted', coalesce(v_state = 'muted', false)),
    'notify_prefs', v_prefs,
    'count', v_count,
    'comments', v_rows);
end $$;

-- ─────────────────────────────────────────────── 6 · the write
create or replace function public.add_posted_round_comment(
  p_round uuid, p_body text, p_parent uuid default null, p_client_id uuid default null)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare
  v        uuid := auth.uid();
  v_body   text := nullif(btrim(coalesce(p_body, '')), '');
  v_owner  uuid;
  v_parent record;
  v_parent_author uuid;
  v_root   uuid;
  v_id     uuid;
  v_old    record;
  v_count  int;
  v_push   boolean;
  n        record;
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  if v_body is null then raise exception 'Say something first' using errcode = '22023'; end if;
  if char_length(v_body) > 500 then raise exception 'Keep it under 500 characters' using errcode = '22023'; end if;

  -- replay first: a retry of a comment that already landed answers with that comment,
  -- even if the round has since gone out of reach, and never notifies twice
  if p_client_id is not null then
    select * into v_old from post_comments where profile_id = v and client_id = p_client_id;
    if found then
      if v_old.round_id is distinct from p_round or v_old.body is distinct from v_body
         or v_old.parent_id is distinct from p_parent then
        raise exception 'That comment was already sent differently' using errcode = '22023';
      end if;
      select count(*)::int into v_count from public._round_thread_rows(p_round);
      return jsonb_build_object('ok', true, 'replayed', true,
        'comment', public._round_comment_json(v_old.id), 'count', v_count);
    end if;
  end if;

  if not public._posted_round_visible(v, p_round)
     or exists (select 1 from profiles where id = v and deleted_at is not null) then
    raise exception 'You can only comment on rounds you can see' using errcode = '42501';
  end if;
  select profile_id into v_owner from rounds where id = p_round;

  if p_parent is not null then
    select t.id, t.root_id, t.author into v_parent
      from public._round_thread_rows(p_round) t
     where t.id = p_parent and t.origin = 'round';
    if not found then raise exception 'That reply lost its comment' using errcode = '22023'; end if;
    v_root := coalesce(v_parent.root_id, v_parent.id);
    v_parent_author := v_parent.author;
  end if;

  if (select count(*) from post_comments
       where profile_id = v and round_id is not null
         and created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'Easy — try again in a minute' using errcode = 'P0001';
  end if;

  insert into post_comments (round_id, profile_id, parent_id, root_id, client_id, body)
  values (p_round, v, p_parent, v_root, p_client_id, v_body)
  on conflict (profile_id, client_id) where client_id is not null do nothing
  returning id into v_id;

  if v_id is null then
    -- a concurrent twin won the race; answer with it (same checks as the replay)
    select * into v_old from post_comments where profile_id = v and client_id = p_client_id;
    if v_old.round_id is distinct from p_round or v_old.body is distinct from v_body
       or v_old.parent_id is distinct from p_parent then
      raise exception 'That comment was already sent differently' using errcode = '22023';
    end if;
    select count(*)::int into v_count from public._round_thread_rows(p_round);
    return jsonb_build_object('ok', true, 'replayed', true,
      'comment', public._round_comment_json(v_old.id), 'count', v_count);
  end if;

  -- the fan-out: preferences filter first, then one row per recipient by priority
  -- reply > own_round > followed. Never the actor; never through a thread mute, a
  -- mute either way, or to someone who cannot see the round.
  v_push := coalesce((select (value->>'enabled')::boolean from app_flags
                       where key = 'social_comment_push'), false);
  for n in
    with cand as (
      select v_parent_author as pid, 'reply'::text as kind, 1 as pri
       where v_parent_author is not null
      union all
      select v_owner, 'own_round', 2
      union all
      select s.profile_id, 'followed', 3
        from round_thread_states s where s.round_id = p_round and s.state = 'following'
    ),
    allowed as (
      select c.pid, c.kind, c.pri
        from cand c
        join profiles pr on pr.id = c.pid and pr.deleted_at is null
        left join social_notify_prefs sp on sp.profile_id = c.pid
       where c.pid is not null and c.pid <> v
         and case c.kind when 'reply'     then coalesce(sp.replies, true)
                         when 'own_round' then coalesce(sp.own_round, true)
                         else coalesce(sp.followed, true) end
         and not exists (select 1 from round_thread_states m
                          where m.profile_id = c.pid and m.round_id = p_round and m.state = 'muted')
         and not public._social_blocked(c.pid, v)
         and public._posted_round_visible(c.pid, p_round)
    ),
    pick as (
      select distinct on (a.pid) a.pid, a.kind from allowed a order by a.pid, a.pri
    )
    insert into social_notifications (recipient, actor, kind, round_id, comment_id)
    select pk.pid, v, pk.kind, p_round, v_id from pick pk
    on conflict (recipient, comment_id) do nothing
    returning id, recipient, kind
  loop
    if v_push then
      insert into push_nudges (profile_id, kind, title, body, payload)
      values (n.recipient, 'comment',
              firstname(coalesce((select display_name from profiles where id = v), 'Someone'))
                || case n.kind when 'reply' then ' replied to your comment'
                               when 'own_round' then ' commented on your round'
                               else ' commented in a conversation you follow' end,
              left(v_body, 140),
              jsonb_build_object('round_id', p_round, 'comment_id', v_id,
                                 'notification_id', n.id, 'profile_id', v));
    end if;
  end loop;

  select count(*)::int into v_count from public._round_thread_rows(p_round);
  return jsonb_build_object('ok', true, 'replayed', false,
    'comment', public._round_comment_json(v_id), 'count', v_count);
end $$;

create or replace function public.remove_posted_round_comment(p_comment uuid)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  update post_comments
     set hidden_at = now(), hidden_by = v, hidden_reason = 'author_removed'
   where id = p_comment and profile_id = v and round_id is not null and post_id is null
     and hidden_at is null;
  if not found and not exists (select 1 from post_comments where id = p_comment and profile_id = v
                                 and round_id is not null and hidden_at is not null) then
    raise exception 'Only your own comment can be removed' using errcode = '42501';
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- ─────────────────────────────────────────────── 7 · follow / mute, preferences
create or replace function public.set_round_thread_state(p_round uuid, p_state text)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  if p_state is null or p_state not in ('following', 'muted', 'none') then
    raise exception 'Unknown conversation setting' using errcode = '22023';
  end if;
  if not public._posted_round_visible(v, p_round) then
    raise exception 'You can only follow rounds you can see' using errcode = '42501';
  end if;
  if p_state = 'none' then
    delete from round_thread_states where profile_id = v and round_id = p_round;
  else
    insert into round_thread_states (profile_id, round_id, state)
    values (v, p_round, p_state)
    on conflict (profile_id, round_id) do update set state = excluded.state, updated_at = now();
  end if;
  return jsonb_build_object('ok', true, 'state', p_state);
end $$;

create or replace function public.social_notify_prefs()
returns jsonb
language sql stable security definer set search_path to 'public'
as $$
  select jsonb_build_object('own_round', coalesce(sp.own_round, true),
                            'replies',   coalesce(sp.replies, true),
                            'followed',  coalesce(sp.followed, true))
    from (select 1) one left join social_notify_prefs sp on sp.profile_id = auth.uid();
$$;

create or replace function public.set_social_notify_prefs(
  p_own_round boolean default null, p_replies boolean default null, p_followed boolean default null)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  insert into social_notify_prefs (profile_id, own_round, replies, followed)
  values (v, coalesce(p_own_round, true), coalesce(p_replies, true), coalesce(p_followed, true))
  on conflict (profile_id) do update set
    own_round  = coalesce(p_own_round, social_notify_prefs.own_round),
    replies    = coalesce(p_replies,   social_notify_prefs.replies),
    followed   = coalesce(p_followed,  social_notify_prefs.followed),
    updated_at = now();
  return public.social_notify_prefs();
end $$;

-- ─────────────────────────────────────────────── 8 · the inbox
-- What a recipient may still read: the comment is still in the thread they can see
-- (not hidden/removed, author not deleted, no mute either way), and the round is
-- still visible to them. Everything else drops out and is not counted as unread.
create or replace function public._notification_live(p_recipient uuid, p_round uuid,
                                                     p_comment uuid, p_actor uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select public._posted_round_visible(p_recipient, p_round)
     and not public._social_blocked(p_recipient, p_actor)
     and exists (select 1 from post_comments c
                   join profiles a on a.id = c.profile_id and a.deleted_at is null
                  where c.id = p_comment and c.hidden_at is null);
$$;
revoke all on function public._notification_live(uuid, uuid, uuid, uuid) from public, anon, authenticated;

create or replace function public.notification_badge()
returns jsonb
language sql stable security definer set search_path to 'public'
as $$
  select jsonb_build_object('unread', count(*)::int)
    from social_notifications n
   where n.recipient = auth.uid() and n.read_at is null
     and public._notification_live(n.recipient, n.round_id, n.comment_id, n.actor);
$$;

create or replace function public.my_notifications(p_before timestamptz default null,
                                                   p_limit integer default 30)
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare
  v uuid := auth.uid();
  v_lim int := least(greatest(coalesce(p_limit, 30), 1), 50);
  v_items jsonb; v_n int;
begin
  if v is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  with page as (
    select n.*
      from social_notifications n
     where n.recipient = v
       and (p_before is null or n.created_at < p_before)
       and public._notification_live(v, n.round_id, n.comment_id, n.actor)
     order by n.created_at desc, n.id desc
     limit v_lim + 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', pg.id, 'kind', pg.kind, 'created_at', pg.created_at,
           'read', pg.read_at is not null, 'read_at', pg.read_at,
           'actor', public._social_person(pg.actor),
           'round_id', pg.round_id, 'comment_id', pg.comment_id,
           'excerpt', left(c.body, 140),
           'course_name', course_name_of(r.api_course_id, r.course_label),
           'round_owner_name', o.display_name,
           'link', jsonb_build_object('kind', 'round_comment', 'round_id', pg.round_id,
                                      'comment_id', pg.comment_id,
                                      'web', '/?round=' || pg.round_id || '&comment=' || pg.comment_id))
           order by pg.created_at desc, pg.id desc) filter (where pg.rn <= v_lim), '[]'::jsonb),
         count(*)
    into v_items, v_n
    from (select page.*, row_number() over (order by page.created_at desc, page.id desc) rn from page) pg
    join post_comments c on c.id = pg.comment_id
    join rounds r on r.id = pg.round_id
    join profiles o on o.id = r.profile_id;

  return jsonb_build_object(
    'ok', true,
    'unread', (public.notification_badge()->>'unread')::int,
    'items', v_items,
    'next_before', case when v_n > v_lim
                        then (select min((i->>'created_at')::timestamptz) from jsonb_array_elements(v_items) i)
                        end);
end $$;

create or replace function public.mark_notifications_read(p_ids uuid[] default null,
                                                          p_all boolean default false)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  update social_notifications
     set read_at = now()
   where recipient = v and read_at is null
     and (coalesce(p_all, false) or id = any(coalesce(p_ids, '{}'::uuid[])));
  return jsonb_build_object('ok', true, 'unread', (public.notification_badge()->>'unread')::int);
end $$;

-- ─────────────────────────────────────────────── grants (L-04)
revoke all on function public.posted_round_thread(uuid)                            from public, anon;
revoke all on function public.add_posted_round_comment(uuid, text, uuid, uuid)     from public, anon;
revoke all on function public.remove_posted_round_comment(uuid)                    from public, anon;
revoke all on function public.set_round_thread_state(uuid, text)                   from public, anon;
revoke all on function public.social_notify_prefs()                                from public, anon;
revoke all on function public.set_social_notify_prefs(boolean, boolean, boolean)   from public, anon;
revoke all on function public.notification_badge()                                 from public, anon;
revoke all on function public.my_notifications(timestamptz, integer)               from public, anon;
revoke all on function public.mark_notifications_read(uuid[], boolean)             from public, anon;
grant execute on function public.posted_round_thread(uuid)                          to authenticated;
grant execute on function public.add_posted_round_comment(uuid, text, uuid, uuid)   to authenticated;
grant execute on function public.remove_posted_round_comment(uuid)                  to authenticated;
grant execute on function public.set_round_thread_state(uuid, text)                 to authenticated;
grant execute on function public.social_notify_prefs()                              to authenticated;
grant execute on function public.set_social_notify_prefs(boolean, boolean, boolean) to authenticated;
grant execute on function public.notification_badge()                               to authenticated;
grant execute on function public.my_notifications(timestamptz, integer)             to authenticated;
grant execute on function public.mark_notifications_read(uuid[], boolean)           to authenticated;

-- ─────────────────────────────────────────────── 9 · moderation reaches the new rows
-- A PRE-EXISTING DEFECT, found by this file's test: `content_reports_target` demands a
-- post or a profile, but report_content's comment branches (board 'comment' and
-- scheduled 'round_comment', since 20260901120000) insert neither — only comment_id —
-- so every comment report has failed with 23514 since it shipped. Widening the check
-- to accept a comment target repairs those two and lets the round-thread branch land.
alter table public.content_reports drop constraint if exists content_reports_target;
alter table public.content_reports add constraint content_reports_target
  check (post_id is not null or profile_id is not null or comment_id is not null);

-- Each existing function is PATCHED at one anchor, asserted to occur exactly once.
do $patch$
declare v_def text; v_n int; a text; b text;
begin
  -- report_content: a round-thread comment may be reported by anyone who can see it
  v_def := pg_get_functiondef('public.report_content(uuid,text,text,uuid,uuid)'::regprocedure);
  if position('[D391]' in v_def) = 0 then
    a := $a$  if p_kind in ('comment','round_comment') then$a$;
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[D391] report_content anchor found % times', v_n; end if;
    b := $b$  -- [D391] a posted-round conversation row (post_id null): the fence is the round
  if p_kind = 'comment' and p_comment is not null
     and exists (select 1 from post_comments pc where pc.id = p_comment
                  and pc.post_id is null and pc.round_id is not null) then
    if not exists (select 1 from public._round_thread_rows(
                     (select pc.round_id from post_comments pc where pc.id = p_comment)) t
                    where t.id = p_comment)
       or not public._posted_round_visible(auth.uid(),
                (select pc.round_id from post_comments pc where pc.id = p_comment)) then
      raise exception 'You can only report comments you can see';
    end if;
    insert into content_reports (post_id, comment_id, reporter, reason, kind)
    values (null, p_comment, auth.uid(), left(coalesce(p_reason,''), 500), 'comment');
    return;
  end if;

$b$ || a;
    execute replace(v_def, a, b);
  end if;

  -- hide_content: founder, or a Pro of any league the round's owner plays in
  v_def := pg_get_functiondef('public.hide_content(text,uuid,text)'::regprocedure);
  if position('[D391]' in v_def) = 0 then
    a := $a$  elsif p_kind = 'comment' then$a$;
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[D391] hide_content anchor found % times', v_n; end if;
    b := $b$  elsif p_kind = 'comment' and exists (select 1 from post_comments pc where pc.id = p_id
                                               and pc.post_id is null and pc.round_id is not null) then
    -- [D391] a posted-round conversation row hangs off the ROUND, not a board post
    select lm.league_id into v_league
      from post_comments pc
      join rounds r          on r.id = pc.round_id
      join league_members lm on lm.profile_id = r.profile_id
     where pc.id = p_id and is_commissioner(lm.league_id)
     limit 1;
    if auth.uid() is distinct from founder_id() and v_league is null then
      raise exception 'Only the founder, or a Pro of a league this golfer plays in, can take this down';
    end if;
    update post_comments set hidden_at = now(), hidden_by = auth.uid(),
                             hidden_reason = left(coalesce(p_reason,''), 500)
     where id = p_id;

$b$ || a;
    execute replace(v_def, a, b);
  end if;

  -- unhide_content: the founder restores a round-thread comment
  v_def := pg_get_functiondef('public.unhide_content(text,uuid)'::regprocedure);
  if position('[D391]' in v_def) = 0 then
    a := $a$  elsif p_kind = 'comment' then$a$;
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[D391] unhide_content anchor found % times', v_n; end if;
    b := $b$  elsif p_kind = 'comment' and exists (select 1 from post_comments pc where pc.id = p_id
                                               and pc.post_id is null and pc.round_id is not null) then
    -- [D391] round-thread rows: founder only
    if auth.uid() is distinct from founder_id() then raise exception 'not yours to restore'; end if;
    update post_comments set hidden_at = null, hidden_by = null, hidden_reason = null where id = p_id;
$b$ || a;
    execute replace(v_def, a, b);
  end if;

  -- moderation_queue: the desk can read what a comment report is about
  v_def := pg_get_functiondef('public.moderation_queue()'::regprocedure);
  if position('[D391]' in v_def) = 0 then
    a := $a$'already_hidden', (p.hidden_at is not null)$a$;
    v_n := (length(v_def) - length(replace(v_def, a, ''))) / length(a);
    if v_n <> 1 then raise exception '[D391] moderation_queue anchor found % times', v_n; end if;
    b := a || $b$,
      -- [D391] what a comment report is about (board and round-thread rows alike)
      'comment_body',     (select left(c.body, 400) from post_comments c
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      'comment_author',   (select pr.display_name from post_comments c
                             left join league_members lm on lm.id = c.member_id
                             join profiles pr on pr.id = coalesce(c.profile_id, lm.profile_id)
                            where cr.kind = 'comment' and c.id = cr.comment_id),
      'comment_round_id', (select coalesce(c.round_id, pp.round_id) from post_comments c
                             left join posts pp on pp.id = c.post_id
                            where cr.kind = 'comment' and c.id = cr.comment_id)$b$;
    execute replace(v_def, a, b);
  end if;
end $patch$;

-- ─────────────────────────────────────────────── self-check (read-only)
do $chk$
declare f text;
begin
  foreach f in array array[
    'public.posted_round_thread(uuid)', 'public.add_posted_round_comment(uuid,text,uuid,uuid)',
    'public.remove_posted_round_comment(uuid)', 'public.set_round_thread_state(uuid,text)',
    'public.social_notify_prefs()', 'public.set_social_notify_prefs(boolean,boolean,boolean)',
    'public.notification_badge()', 'public.my_notifications(timestamptz,integer)',
    'public.mark_notifications_read(uuid[],boolean)'] loop
    if not has_function_privilege('authenticated', f, 'EXECUTE')
       or has_function_privilege('anon', f, 'EXECUTE') then
      raise exception '[D391] grant wrong on %', f;
    end if;
  end loop;
  foreach f in array array['public._social_circle(uuid)', 'public._posted_round_visible(uuid,uuid)',
    'public._round_thread_rows(uuid)', 'public._round_tee(text,text,numeric,integer)'] loop
    if has_function_privilege('authenticated', f, 'EXECUTE') or has_function_privilege('anon', f, 'EXECUTE') then
      raise exception '[D391] helper % is callable by a client', f;
    end if;
  end loop;
  if has_table_privilege('authenticated', 'public.social_notifications', 'SELECT')
     or has_table_privilege('anon', 'public.social_notifications', 'SELECT') then
    raise exception '[D391] social_notifications is directly readable';
  end if;
  if position('[D391]' in pg_get_functiondef('public.report_content(uuid,text,text,uuid,uuid)'::regprocedure)) = 0
     or position('[D391]' in pg_get_functiondef('public.hide_content(text,uuid,text)'::regprocedure)) = 0
     or position('[D391]' in pg_get_functiondef('public.unhide_content(text,uuid)'::regprocedure)) = 0
     or position('[D391]' in pg_get_functiondef('public.moderation_queue()'::regprocedure)) = 0 then
    raise exception '[D391] a moderation patch did not land';
  end if;
end $chk$;
