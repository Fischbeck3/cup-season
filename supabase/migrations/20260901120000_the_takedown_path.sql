-- ============================================================================
-- Cup Season — a report that reaches somebody, and content that can come down
--
-- Found by the ship audit (2026-08-31) as S5 and re-verified against prod on
-- 2026-09-01 before a line of this was written:
--
--   * `posts` carries exactly TWO policies — `posts_read` (r) and `posts_chat`
--     (a). There is no UPDATE policy and no DELETE policy, so **nobody can
--     remove a post through the API. Not a Pro. Not the founder.** The only
--     takedown that has ever existed is the SQL editor.
--   * `report_content()` writes to `content_reports`. Its only reader is
--     `founder_desk()`, which renders rows with no actions. `content_reports`
--     has a `resolved` boolean and nothing in the database can set it.
--   * No trigger fires on `content_reports`, so **a report notifies nobody**.
--   * `report_content` branches on `p_kind` and accepts only 'post' and
--     'profile_photo' — comment text is unreportable.
--   * `round_comments_read` is `can_see_round(round_id)` and NOTHING ELSE:
--     the mute filter that `posts_read` and `comments_read` both carry is
--     absent, so a muted golfer still writes on your round's card.
--
-- That last one is worth saying plainly: Mute is the product's answer to "this
-- person is bothering me", and on one surface it silently did nothing.
--
-- This is also App Store Guideline 1.2, which is a hard reject: an app with
-- user-generated content needs a report path, a block, AND the ability to act.
-- Two of the three existed.
--
-- WHAT THIS DOES NOT DO, deliberately: it does not eject a member from a
-- running league. `remove_member` still refuses outside `setup`, and widening
-- it is a COMPETITION-MECHANIC change — what happens to their squad, their
-- posted rounds, the points they have already scored, and their share of the
-- pot — which under the working protocol needs its own decision entry before
-- it is built, not a paragraph inside a safety migration. Guideline 1.2 asks
-- for blocking (set_mute, which exists and now works everywhere) and for the
-- developer to be able to act on content (this migration). Ejection is a
-- product question, and it is logged as one.
-- ============================================================================

-- ---- 1 · somewhere to record that a thing came down ------------------------
alter table public.posts           add column if not exists hidden_at     timestamptz;
alter table public.posts           add column if not exists hidden_by     uuid references public.profiles(id);
alter table public.posts           add column if not exists hidden_reason text;
alter table public.post_comments   add column if not exists hidden_at     timestamptz;
alter table public.post_comments   add column if not exists hidden_by     uuid references public.profiles(id);
alter table public.post_comments   add column if not exists hidden_reason text;
alter table public.round_comments  add column if not exists hidden_at     timestamptz;
alter table public.round_comments  add column if not exists hidden_by     uuid references public.profiles(id);
alter table public.round_comments  add column if not exists hidden_reason text;

-- a report can now be closed, and say how
alter table public.content_reports add column if not exists resolved_at timestamptz;
alter table public.content_reports add column if not exists resolved_by uuid references public.profiles(id);
alter table public.content_reports add column if not exists resolution  text;
alter table public.content_reports add column if not exists comment_id  uuid;

create index if not exists content_reports_open_idx
  on public.content_reports (created_at desc) where resolved_at is null;
create index if not exists posts_hidden_idx
  on public.posts (league_id) where hidden_at is not null;

-- ---- 2 · hidden content leaves the read path ------------------------------
-- Each policy below is the EXACT expression read out of pg_policy on
-- 2026-09-01, with the new clause appended. Nothing else is changed; a
-- rewritten read policy is how a board goes blank for everyone at once.
drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select using (
  (((league_id IS NOT NULL) AND is_league_member(league_id))
    OR ((event_id IS NOT NULL) AND (is_event_member(event_id) OR is_event_league_member(event_id))))
  AND ((member_id IS NULL) OR (NOT (EXISTS (
        SELECT 1 FROM (mutes mu JOIN league_members lm ON ((lm.id = posts.member_id)))
         WHERE ((mu.muter = auth.uid()) AND (mu.muted = lm.profile_id))))))
  AND hidden_at IS NULL
);

drop policy if exists comments_read on public.post_comments;
create policy comments_read on public.post_comments for select using (
  (EXISTS (SELECT 1 FROM posts p WHERE (p.id = post_comments.post_id)))
  AND (NOT (EXISTS (
        SELECT 1 FROM (mutes mu JOIN league_members lm ON ((lm.id = post_comments.member_id)))
         WHERE ((mu.muter = auth.uid()) AND (mu.muted = lm.profile_id)))))
  AND hidden_at IS NULL
);

-- round_comments gains BOTH the takedown filter and the mute filter it never
-- had. `round_comments.profile_id` is a profile, not a league member, so the
-- mute test is direct rather than joined through league_members.
drop policy if exists round_comments_read on public.round_comments;
create policy round_comments_read on public.round_comments for select using (
  can_see_round(round_id)
  AND hidden_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM mutes mu
     WHERE mu.muter = auth.uid() AND mu.muted = round_comments.profile_id)
);

-- ---- 3 · who may take something down --------------------------------------
-- The founder, anywhere; a Pro, inside their own league. A Pro cannot reach
-- another league's board, and neither can moderate a golfer's own round photo
-- into existence — hiding is the only power granted here, and it is reversible
-- and attributed.
create or replace function public.moderator_can(p_league uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() = founder_id()
      or (p_league is not null and is_commissioner(p_league));
$$;

create or replace function public.hide_content(
  p_kind text, p_id uuid, p_reason text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_league uuid;
begin
  if p_id is null then raise exception 'nothing to hide'; end if;

  if p_kind = 'post' then
    select league_id into v_league from posts where id = p_id;
    if not found then raise exception 'no such post'; end if;
    if not moderator_can(v_league) then
      raise exception 'Only the Pro of this league or the founder can take a post down';
    end if;
    update posts set hidden_at = now(), hidden_by = auth.uid(),
                     hidden_reason = left(coalesce(p_reason,''), 500)
     where id = p_id;

  elsif p_kind = 'comment' then
    select p.league_id into v_league
      from post_comments c join posts p on p.id = c.post_id where c.id = p_id;
    if not found then raise exception 'no such comment'; end if;
    if not moderator_can(v_league) then
      raise exception 'Only the Pro of this league or the founder can take a comment down';
    end if;
    update post_comments set hidden_at = now(), hidden_by = auth.uid(),
                             hidden_reason = left(coalesce(p_reason,''), 500)
     where id = p_id;

  elsif p_kind = 'round_comment' then
    -- a round comment hangs off a ROUND, which may be read by league-mates of
    -- any league the poster belongs to; the founder always may, and a Pro may
    -- when the round's owner is in a league they run.
    select lm.league_id into v_league
      from round_comments rc
      join rounds r          on r.id = rc.round_id
      join league_members lm on lm.profile_id = r.profile_id
     where rc.id = p_id and is_commissioner(lm.league_id)
     limit 1;
    if auth.uid() <> founder_id() and v_league is null then
      raise exception 'Only the founder, or a Pro of a league this golfer plays in, can take this down';
    end if;
    update round_comments set hidden_at = now(), hidden_by = auth.uid(),
                              hidden_reason = left(coalesce(p_reason,''), 500)
     where id = p_id;
  else
    raise exception 'unknown kind: %', p_kind;
  end if;
end $$;

create or replace function public.unhide_content(p_kind text, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_league uuid;
begin
  if p_kind = 'post' then
    select league_id into v_league from posts where id = p_id;
    if not moderator_can(v_league) then raise exception 'not yours to restore'; end if;
    update posts set hidden_at = null, hidden_by = null, hidden_reason = null where id = p_id;
  elsif p_kind = 'comment' then
    select p.league_id into v_league from post_comments c join posts p on p.id = c.post_id where c.id = p_id;
    if not moderator_can(v_league) then raise exception 'not yours to restore'; end if;
    update post_comments set hidden_at = null, hidden_by = null, hidden_reason = null where id = p_id;
  elsif p_kind = 'round_comment' then
    if auth.uid() <> founder_id() then raise exception 'not yours to restore'; end if;
    update round_comments set hidden_at = null, hidden_by = null, hidden_reason = null where id = p_id;
  else
    raise exception 'unknown kind: %', p_kind;
  end if;
end $$;

-- ---- 4 · a report can be closed -------------------------------------------
create or replace function public.resolve_report(
  p_report uuid, p_resolution text default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() <> founder_id() then
    raise exception 'Reports are resolved at the founder''s desk';
  end if;
  update content_reports
     set resolved    = true,
         resolved_at = now(),
         resolved_by = auth.uid(),
         resolution  = left(coalesce(p_resolution,''), 500)
   where id = p_report;
  if not found then raise exception 'no such report'; end if;
end $$;

-- ---- 5 · the queue the desk reads -----------------------------------------
-- Returns each OPEN report with enough of the content to judge it without
-- leaving the desk, and the ids the actions need. Founder only; it crosses
-- every league by design, which is exactly why nobody else may call it.
create or replace function public.moderation_queue()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v jsonb;
begin
  if auth.uid() <> founder_id() then
    raise exception 'the desk is the founder''s';
  end if;
  select coalesce(jsonb_agg(x order by x->>'created_at' desc), '[]'::jsonb) into v
  from (
    select jsonb_build_object(
      'id',          cr.id,
      'kind',        cr.kind,
      'reason',      cr.reason,
      'created_at',  cr.created_at,
      'reporter',    (select display_name from profiles where id = cr.reporter),
      'post_id',     cr.post_id,
      'comment_id',  cr.comment_id,
      'profile_id',  cr.profile_id,
      'league',      (select l.name from leagues l where l.id = p.league_id),
      'league_id',   p.league_id,
      'author',      (select pr.display_name from league_members lm
                        join profiles pr on pr.id = lm.profile_id
                       where lm.id = p.member_id),
      'body',        left(coalesce(p.body, ''), 400),
      'already_hidden', (p.hidden_at is not null)
    ) as x
    from content_reports cr
    left join posts p on p.id = cr.post_id
    where cr.resolved_at is null and coalesce(cr.resolved, false) = false
  ) s;
  return v;
end $$;

-- ---- 6 · comments become reportable ---------------------------------------
-- The old four-argument function is DROPPED rather than left beside the new
-- one. PostgREST calls RPCs with NAMED arguments, and a four-name call would
-- match both `report_content(uuid,text,text,uuid)` and
-- `report_content(uuid,text,text,uuid,uuid)`-with-a-default — Postgres answers
-- "function is not unique" and the report button breaks for everyone. One
-- function, with `p_comment` defaulted, serves the old client unchanged: this
-- is the deploy-skew rule in CLAUDE.md, satisfied by arity rather than by a
-- retry. (Nothing else in the database calls it.)
drop function if exists public.report_content(uuid, text, text, uuid);

create or replace function public.report_content(
  p_post uuid default null, p_reason text default null,
  p_kind text default 'post', p_profile uuid default null,
  p_comment uuid default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_ok boolean;
begin
  if p_kind = 'profile_photo' then
    if p_profile is null then raise exception 'nothing to report'; end if;
    if not exists (
      select 1 from league_members a
        join league_members b on b.league_id = a.league_id
       where a.profile_id = auth.uid() and b.profile_id = p_profile
    ) and not exists (
      select 1 from friendships f
       where f.status = 'accepted'
         and ((f.requester = auth.uid() and f.addressee = p_profile)
           or (f.addressee = auth.uid() and f.requester = p_profile))
    ) and not exists (
      select 1 from event_players ea
        join event_players eb on eb.event_id = ea.event_id
       where ea.profile_id = auth.uid() and eb.profile_id = p_profile
    ) then
      raise exception 'You can only report golfers you share a league, event, or friendship with';
    end if;
    insert into content_reports (post_id, reporter, reason, kind, profile_id)
    values (null, auth.uid(), left(coalesce(p_reason,'profile photo'), 500), 'profile_photo', p_profile)
    on conflict (profile_id, reporter) where kind = 'profile_photo'
    do update set reason = excluded.reason, created_at = now();
    return;
  end if;

  -- NEW: comment text, on a board post or on a round card. You may report what
  -- you can see, which is the same fence every other branch uses.
  if p_kind in ('comment','round_comment') then
    if p_comment is null then raise exception 'nothing to report'; end if;
    if p_kind = 'comment' then
      select exists (
        select 1 from post_comments c join posts p on p.id = c.post_id
         where c.id = p_comment and is_league_member(p.league_id)) into v_ok;
    else
      select exists (
        select 1 from round_comments rc where rc.id = p_comment
           and can_see_round(rc.round_id)) into v_ok;
    end if;
    if not v_ok then raise exception 'You can only report comments you can see'; end if;
    insert into content_reports (post_id, comment_id, reporter, reason, kind)
    values (null, p_comment, auth.uid(), left(coalesce(p_reason,''), 500), p_kind);
    return;
  end if;

  if p_post is null then raise exception 'nothing to report'; end if;
  if not exists (
    select 1 from posts p join league_members lm on lm.league_id = p.league_id
     where p.id = p_post and lm.profile_id = auth.uid()
  ) then
    raise exception 'You can only report posts in your own leagues';
  end if;
  insert into content_reports (post_id, reporter, reason, kind)
  values (p_post, auth.uid(), left(coalesce(p_reason,''), 500), 'post')
  on conflict (post_id, reporter)
  do update set reason = excluded.reason, created_at = now();
end $$;

-- ---- 7 · the report wakes somebody ----------------------------------------
-- It rides push_nudges, the one-row-one-recipient path that already reaches a
-- phone (D104), rather than a new channel nobody has ever exercised. kind stays
-- 'nudge' on purpose: the push function's kind union is a deployed constant,
-- and a migration must not depend on an edge-function deploy landing first.
-- A dedicated 'report' kind that deep-links to the desk is a follow-up.
-- Fail-open by construction: a report is never lost because a nudge failed.
create or replace function public.notify_founder_of_report()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_founder uuid; v_what text;
begin
  begin
    v_founder := founder_id();
    if v_founder is null or v_founder = new.reporter then return new; end if;
    v_what := case new.kind
                when 'profile_photo' then 'a profile photo'
                when 'comment'       then 'a comment'
                when 'round_comment' then 'a comment on a round'
                else 'a post' end;
    insert into push_nudges (profile_id, title, body, kind, payload)
    values (v_founder,
            'A report needs you',
            'Someone reported ' || v_what || '. Open the founder''s desk.',
            'nudge',
            jsonb_build_object('report_id', new.id, 'desk', true));
  exception when others then
    null;   -- never let the notification fail the report
  end;
  return new;
end $$;

drop trigger if exists trg_report_wakes_founder on public.content_reports;
create trigger trg_report_wakes_founder
  after insert on public.content_reports
  for each row execute function public.notify_founder_of_report();

-- ---- 8 · grants (D37: nothing is granted by default) -----------------------
revoke all on function public.moderator_can(uuid)                       from public, anon, authenticated;
revoke all on function public.hide_content(text, uuid, text)            from public, anon;
revoke all on function public.unhide_content(text, uuid)                from public, anon;
revoke all on function public.resolve_report(uuid, text)                from public, anon;
revoke all on function public.moderation_queue()                        from public, anon;
revoke all on function public.report_content(uuid, text, text, uuid, uuid) from public, anon;
revoke all on function public.notify_founder_of_report()                from public, anon, authenticated;

grant execute on function public.hide_content(text, uuid, text)            to authenticated;
grant execute on function public.unhide_content(text, uuid)                to authenticated;
grant execute on function public.resolve_report(uuid, text)                to authenticated;
grant execute on function public.moderation_queue()                        to authenticated;
grant execute on function public.report_content(uuid, text, text, uuid, uuid) to authenticated;

-- ---- 9 · self-enforcing, like D37's sweep ---------------------------------
do $$
declare n int;
begin
  -- the three read paths must all filter hidden content
  select count(*) into n
    from pg_policy pol join pg_class c on c.oid = pol.polrelid
   where c.relname in ('posts','post_comments','round_comments')
     and pol.polcmd = 'r'
     and pg_get_expr(pol.polqual, pol.polrelid) like '%hidden_at%';
  if n <> 3 then
    raise exception '[takedown] % of 3 read policies filter hidden content', n;
  end if;

  -- the mute filter must be on round_comments now, not just the other two
  if (select pg_get_expr(pol.polqual, pol.polrelid)
        from pg_policy pol join pg_class c on c.oid = pol.polrelid
       where c.relname = 'round_comments' and pol.polcmd = 'r') not like '%mutes%' then
    raise exception '[takedown] round_comments_read still has no mute filter';
  end if;
end $$;
