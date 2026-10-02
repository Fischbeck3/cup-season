-- Cup Season — comments live in line under the round they are on (D405).
--
-- Additive, on top of D391 (20261207090000, 20261208090000). No competition mechanic, score,
-- points figure or identity field moves. Four functions are re-created with the SAME
-- signatures (so no overload can appear and the generated Rpc.swift does not change) and one
-- check constraint widens.
--
--   1 · round_thread_states.state learns 'replies' — "tell me about replies to me, not every
--       comment", chosen ON PURPOSE. The absence of a row is still "no setting".
--   2 · set_round_thread_state accepts 'replies'.
--   3 · add_posted_round_comment — commenting is joining the conversation. A commenter who
--       has NO setting on the round and does not own it is recorded as 'following', so the
--       banter comes back to them. A mute, or a choice made on purpose, is never overridden
--       (ON CONFLICT DO NOTHING); a replayed retry changes nothing; the round's owner is
--       left alone (own_round already tells them). The comment push (dark behind
--       app_flags.social_comment_push) names the round the way the in-app notice does (without the course).
--   4 · posted_rounds_social gains `latest` — the newest visible comment, so a wire can show
--       the banter before anyone taps. Count and latest come from ONE read of the thread.
--   5 · my_notifications gains `round_is_mine`, so "Blake replied to you on your round" and
--       "Blake replied to you on Theo's round" are told apart without comparing names.
--
-- The deploy-skew rule: every client falls back when a key is absent (`latest` → the count
-- alone; `round_is_mine` → the older sentence), and a 'replies' write to a server without this
-- file is refused with 22023 and the client says "That setting did not save."
-- L-04: every function is re-issued revoke-from-public/anon and grant-to-authenticated.

-- ─────────────────────────────────────────────── 1 · the state learns 'replies'
-- the original constraint was unnamed in the DDL; find it by what it checks, then re-add it
do $c$
declare c record;
begin
  for c in select conname from pg_constraint
            where conrelid = 'public.round_thread_states'::regclass and contype = 'c'
              and pg_get_constraintdef(oid) ilike '%following%'
  loop
    execute format('alter table public.round_thread_states drop constraint %I', c.conname);
  end loop;
  alter table public.round_thread_states
    add constraint round_thread_states_state_check check (state in ('following', 'replies', 'muted'));
end $c$;

-- ─────────────────────────────────────────────── 2 · the setting
create or replace function public.set_round_thread_state(p_round uuid, p_state text)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare v uuid := auth.uid();
begin
  if v is null then raise exception 'Sign in first' using errcode = '42501'; end if;
  if p_state is null or p_state not in ('following', 'replies', 'muted', 'none') then
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

-- ─────────────────────────────────────────────── 3 · the write
create or replace function public.add_posted_round_comment(
  p_round uuid, p_body text, p_parent uuid default null, p_client_id uuid default null)
returns jsonb
language plpgsql volatile security definer set search_path to 'public'
as $$
declare
  v        uuid := auth.uid();
  v_body   text := nullif(btrim(coalesce(p_body, '')), '');
  v_owner  uuid;
  v_owner_first text;
  v_parent record;
  v_parent_author uuid;
  v_root   uuid;
  v_id     uuid;
  v_old    record;
  v_count  int;
  v_push   boolean;
  v_apos   text := chr(8217);
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
  select r.profile_id, firstname(o.display_name)
    into v_owner, v_owner_first
    from rounds r join profiles o on o.id = r.profile_id
   where r.id = p_round;

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

  -- D405 · commenting is joining the conversation: the commenter hears what follows. Only
  -- a golfer with NO setting on this round, and who does not own it (own_round already
  -- tells the owner). A mute, or a setting chosen on purpose, stays exactly as it is.
  if v is distinct from v_owner then
    insert into round_thread_states (profile_id, round_id, state)
    values (v, p_round, 'following')
    on conflict (profile_id, round_id) do nothing;
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
      -- the in-app notice's three sentences (D405), never "a conversation you follow". The title has no room
      -- for the course (the push guard cuts a title at 80 characters, mid-word), so it says whose round, not where;
      -- and a golfer who asked for every comment on their OWN round (own_round off) hears "your round".
      insert into push_nudges (profile_id, kind, title, body, payload)
      values (n.recipient, 'comment',
              firstname(coalesce((select display_name from profiles where id = v), 'Someone'))
                || case n.kind
                     when 'reply' then ' replied to you on '
                                       || case when v_owner = n.recipient then 'your round'
                                               else v_owner_first || v_apos || 's round' end
                     when 'own_round' then ' commented on your round'
                     else ' commented on '
                          || case when v_owner = n.recipient then 'your round'
                                  else v_owner_first || v_apos || 's round' end end,
              left(v_body, 140),
              jsonb_build_object('round_id', p_round, 'comment_id', v_id,
                                 'notification_id', n.id, 'profile_id', v));
    end if;
  end loop;

  select count(*)::int into v_count from public._round_thread_rows(p_round);
  return jsonb_build_object('ok', true, 'replayed', false,
    'comment', public._round_comment_json(v_id), 'count', v_count);
end $$;

-- ─────────────────────────────────────────────── 4 · the doors' read: count + the newest comment
-- one read of the thread per round gives both; the body is cut at 140 characters (a line
-- under the card — the receipt and the in-line thread carry the whole comment)
create or replace function public.posted_rounds_social(p_rounds uuid[])
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare v uuid := auth.uid(); v_out jsonb;
begin
  if v is null then return jsonb_build_object('items', '[]'::jsonb); end if;
  with ids as (
    select distinct x.id from unnest(coalesce(p_rounds, '{}'::uuid[])) x(id) limit 60
  ),
  circle as (select * from public._social_circle(v)),
  vis as (
    select r.* from rounds r join ids on ids.id = r.id
     where public._posted_round_visible(v, r.id)
  ),
  at_course as (
    select r.api_course_id, r.profile_id, max(r.played_on) last_on, min(c.relation) rel
      from rounds r
      join circle c on c.pid = r.profile_id
      join profiles o on o.id = r.profile_id and o.deleted_at is null
     where r.api_course_id in (select api_course_id from vis where api_course_id is not null)
       and not r.voided
       and (r.profile_id = v or not public._social_blocked(v, r.profile_id))
     group by r.api_course_id, r.profile_id
  )
  select jsonb_build_object('items', coalesce(jsonb_agg(jsonb_build_object(
      'round_id', vr.id,
      'comment_count', th.n,
      'latest', case when th.last_id is null then null else jsonb_build_object(
          'id', th.last_id,
          'author', public._social_person(th.last_author),
          'body', th.last_body,
          'created_at', th.last_at) end,
      'can_comment', true,
      'thread_state', coalesce((select s.state from round_thread_states s
                                 where s.profile_id = v and s.round_id = vr.id), 'none'),
      'course', case when vr.api_course_id is null then null else jsonb_build_object(
          'api_course_id', vr.api_course_id,
          'name', course_name_of(vr.api_course_id, vr.course_label),
          'circle_golfers', (select count(*) from at_course a where a.api_course_id = vr.api_course_id),
          'faces', (select coalesce(jsonb_agg(public._social_person(f.profile_id)
                                              order by (f.rel = 'friend') desc, f.last_on desc, f.profile_id), '[]'::jsonb)
                      from (select * from at_course a
                             where a.api_course_id = vr.api_course_id and a.profile_id <> v
                             order by (a.rel = 'friend') desc, a.last_on desc, a.profile_id
                             limit 3) f)) end)), '[]'::jsonb))
    into v_out
    from vis vr
    cross join lateral (
      select count(*)::int as n,
             (array_agg(t.id order by t.created_at desc, t.id desc))[1]            as last_id,
             (array_agg(t.author order by t.created_at desc, t.id desc))[1]        as last_author,
             (array_agg(left(t.body, 140) order by t.created_at desc, t.id desc))[1] as last_body,
             (array_agg(t.created_at order by t.created_at desc, t.id desc))[1]    as last_at
        from public._round_thread_rows(vr.id) t
    ) th;
  return v_out;
end $$;

-- ─────────────────────────────────────────────── 5 · the inbox says whose round it is
create or replace function public.my_notifications(p_before timestamptz default null,
                                                   p_limit integer default 30,
                                                   p_before_id uuid default null)
returns jsonb
language plpgsql stable security definer set search_path to 'public'
as $$
declare
  v uuid := auth.uid();
  v_lim int := least(greatest(coalesce(p_limit, 30), 1), 50);
  v_items jsonb; v_more boolean; v_last_at timestamptz; v_last_id uuid;
begin
  if v is null then return jsonb_build_object('ok', false, 'reason', 'signed_out'); end if;
  with page as (
    select n.*
      from social_notifications n
     where n.recipient = v
       and (p_before is null
            or (p_before_id is null and n.created_at < p_before)
            or (p_before_id is not null and (n.created_at, n.id) < (p_before, p_before_id)))
       and public._notification_live(v, n.round_id, n.comment_id, n.actor)
     order by n.created_at desc, n.id desc
     limit v_lim + 1
  ),
  pg as (select page.*, row_number() over (order by page.created_at desc, page.id desc) rn from page)
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', pg.id, 'kind', pg.kind, 'created_at', pg.created_at,
           'read', pg.read_at is not null, 'read_at', pg.read_at,
           'actor', public._social_person(pg.actor),
           'round_id', pg.round_id, 'comment_id', pg.comment_id,
           'excerpt', left(c.body, 140),
           'course_name', course_name_of(r.api_course_id, r.course_label),
           'round_owner_name', o.display_name,
           'round_is_mine', r.profile_id = v,
           'link', jsonb_build_object('kind', 'round_comment', 'round_id', pg.round_id,
                                      'comment_id', pg.comment_id,
                                      'web', '/?round=' || pg.round_id || '&comment=' || pg.comment_id))
           order by pg.created_at desc, pg.id desc) filter (where pg.rn <= v_lim), '[]'::jsonb),
         bool_or(pg.rn > v_lim),
         (array_agg(pg.created_at order by pg.rn desc) filter (where pg.rn <= v_lim))[1],
         (array_agg(pg.id order by pg.rn desc) filter (where pg.rn <= v_lim))[1]
    into v_items, v_more, v_last_at, v_last_id
    from pg
    join post_comments c on c.id = pg.comment_id
    join rounds r on r.id = pg.round_id
    join profiles o on o.id = r.profile_id;

  return jsonb_build_object(
    'ok', true,
    'unread', (public.notification_badge()->>'unread')::int,
    'items', v_items,
    'next_before',    case when coalesce(v_more, false) then v_last_at end,
    'next_before_id', case when coalesce(v_more, false) then v_last_id end);
end $$;

-- ─────────────────────────────────────────────── 6 · grants, explicit (D37) + self-check
revoke all on function public.set_round_thread_state(uuid, text)                      from public, anon;
revoke all on function public.add_posted_round_comment(uuid, text, uuid, uuid)        from public, anon;
revoke all on function public.posted_rounds_social(uuid[])                            from public, anon;
revoke all on function public.my_notifications(timestamptz, integer, uuid)            from public, anon;
grant execute on function public.set_round_thread_state(uuid, text)                   to authenticated;
grant execute on function public.add_posted_round_comment(uuid, text, uuid, uuid)     to authenticated;
grant execute on function public.posted_rounds_social(uuid[])                         to authenticated;
grant execute on function public.my_notifications(timestamptz, integer, uuid)         to authenticated;

do $chk$
declare f text;
begin
  foreach f in array array[
    'public.set_round_thread_state(uuid,text)', 'public.add_posted_round_comment(uuid,text,uuid,uuid)',
    'public.posted_rounds_social(uuid[])', 'public.my_notifications(timestamptz,integer,uuid)'] loop
    if not has_function_privilege('authenticated', f, 'EXECUTE')
       or has_function_privilege('anon', f, 'EXECUTE') then
      raise exception '[D405] grant wrong on %', f;
    end if;
  end loop;
  -- no overload may exist beside the four (a defaulted signature change would leave one)
  if (select count(*) from pg_proc p join pg_namespace s on s.oid = p.pronamespace
       where s.nspname = 'public'
         and p.proname in ('set_round_thread_state', 'add_posted_round_comment',
                           'posted_rounds_social', 'my_notifications')) <> 4 then
    raise exception '[D405] an overload appeared';
  end if;
  if not exists (select 1 from pg_constraint
                  where conrelid = 'public.round_thread_states'::regclass and contype = 'c'
                    and pg_get_constraintdef(oid) like '%replies%') then
    raise exception '[D405] the thread-state check does not know replies';
  end if;
end $chk$;
