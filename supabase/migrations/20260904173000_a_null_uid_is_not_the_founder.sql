-- D188/D193 (amended) · a null uid is not the founder, the owner, or you.
--
-- `if auth.uid() <> founder_id() then raise ...` does not fail closed. When
-- either side is NULL the comparison is NULL, the `if` never fires, and the
-- guard is simply skipped. Proven read-only against prod on 2026-09-04:
-- `select public.cron_health() is not null` and
-- `select public.moderation_queue() is not null` both returned true in a
-- session where `auth.uid() is null` was also true — neither raised.
--
-- Nine functions carried the idiom, six of which WRITE. Seven compare against
-- `founder_id()`; a loose-ends sweep found those, and this migration's own
-- self-check — which looks for `auth.uid() <>` against ANYTHING, not just the
-- founder — found the two the sweep missed:
--
--   scrap_forfeit    `if auth.uid() <> f.created_by and not is_commissioner(...)`
--   set_round_rsvp   `if auth.uid() <> v_owner`
--
-- Those two are the sharper pair, because the NULL can come from the RIGHT
-- side as well: a forfeit whose `created_by` has been tombstoned compares
-- against NULL, so the guard opens for every authenticated caller, no missing
-- JWT required. The founder seven are latent by comparison — anon holds
-- EXECUTE on none of them and every authenticated JWT carries a sub claim.
--
-- `founder_desk` and `founder_note` already used `is distinct from`; this makes
-- the other nine match the two that were already right.
--
-- Each body below is prod's own `pg_get_functiondef` output, read 2026-09-04,
-- with ONE mechanical substitution applied and nothing else:
--   auth.uid() <> X   ->   auth.uid() is distinct from X
-- Occurrences fixed: cron_health 1, hide_content 1, moderation_queue 1, resolve_report 1, scrap_forfeit 1, set_round_rsvp 1, suspend_member 2, unhide_content 1, unsuspend_member 1.

CREATE OR REPLACE FUNCTION public.cron_health()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v jsonb;
begin
  if auth.uid() is distinct from founder_id() then
    raise exception 'the desk is the founder''s';
  end if;
  select jsonb_build_object(
    'jobs', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'job', j.jobname, 'schedule', j.schedule, 'active', j.active,
        'last_run', d.start_time, 'last_status', d.status,
        'last_message', left(coalesce(d.return_message,''), 200)
      ) order by j.jobid), '[]'::jsonb)
      from cron.job j
      left join lateral (
        select start_time, status, return_message from cron.job_run_details r
         where r.jobid = j.jobid order by r.start_time desc limit 1
      ) d on true
    ),
    'recent_job_failures', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'job', jobid, 'at', start_time, 'message', left(coalesce(return_message,''), 200)
      ) order by start_time desc), '[]'::jsonb)
      from cron.job_run_details
      where status <> 'succeeded' and start_time > now() - interval '30 days'
    ),
    'recent_row_failures', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'job', job, 'subject', subject, 'sqlstate', sqlstate,
        'message', left(message, 200), 'at', created_at
      ) order by created_at desc), '[]'::jsonb)
      from (select * from job_failures
             where created_at > now() - interval '30 days'
             order by created_at desc limit 50) f
    )
  ) into v;
  return v;
end $function$;

CREATE OR REPLACE FUNCTION public.hide_content(p_kind text, p_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    if auth.uid() is distinct from founder_id() and v_league is null then
      raise exception 'Only the founder, or a Pro of a league this golfer plays in, can take this down';
    end if;
    update round_comments set hidden_at = now(), hidden_by = auth.uid(),
                              hidden_reason = left(coalesce(p_reason,''), 500)
     where id = p_id;
  else
    raise exception 'unknown kind: %', p_kind;
  end if;
end $function$;

CREATE OR REPLACE FUNCTION public.moderation_queue()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v jsonb;
begin
  if auth.uid() is distinct from founder_id() then
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
end $function$;

CREATE OR REPLACE FUNCTION public.resolve_report(p_report uuid, p_resolution text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is distinct from founder_id() then
    raise exception 'Reports are resolved at the founder''s desk';
  end if;
  update content_reports
     set resolved    = true,
         resolved_at = now(),
         resolved_by = auth.uid(),
         resolution  = left(coalesce(p_resolution,''), 500)
   where id = p_report;
  if not found then raise exception 'no such report'; end if;
end $function$;

CREATE OR REPLACE FUNCTION public.scrap_forfeit(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare f record;
begin
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then raise exception 'Settled stakes stand — the archive keeps them'; end if;
  if auth.uid() is distinct from f.created_by and not is_commissioner(f.league_id) then
    raise exception 'Only the poster (or the Pro) scraps a stake';
  end if;
  update forfeits set status = 'scrapped', settled_at = now(), settled_by = auth.uid()
   where id = p_id;
  insert into posts (league_id, kind, body)
  values (f.league_id, 'system', 'Stake scrapped: ' || f.name);
end $function$;

CREATE OR REPLACE FUNCTION public.set_round_rsvp(p_round uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_owner uuid; v_tagged uuid[];
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_status not in ('in','maybe','out') then raise exception 'bad status'; end if;

  select profile_id, tagged into v_owner, v_tagged
    from scheduled_rounds where id = p_round;
  if v_owner is null then raise exception 'No such round'; end if;

  -- D69: only the host and the players they tagged may RSVP. Visibility is
  -- unchanged (can_see_round still lets league-mates SEE the round) — this
  -- guards the write alone.
  if auth.uid() is distinct from v_owner
     and not (auth.uid() = any(coalesce(v_tagged, '{}'::uuid[]))) then
    raise exception 'Only the host and tagged players can RSVP to this round';
  end if;

  insert into round_rsvp (round_id, profile_id, status)
  values (p_round, auth.uid(), p_status)
  on conflict (round_id, profile_id) do update
    set status = excluded.status, updated_at = now();
end $function$;

CREATE OR REPLACE FUNCTION public.suspend_member(p_member uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid; v_role text; v_profile uuid;
begin
  select league_id, role, profile_id into v_league, v_role, v_profile
    from league_members where id = p_member;
  if not found then raise exception 'no such member'; end if;

  if auth.uid() is distinct from founder_id() and not is_commissioner(v_league) then
    raise exception 'Only the Pro of this league can suspend someone in it';
  end if;
  if v_profile = auth.uid() then
    raise exception 'You cannot suspend yourself';
  end if;
  -- a Pro cannot suspend another Pro; that is a founder-level call, because
  -- two commissioners suspending each other is a league with no adult in it.
  if v_role = 'commissioner' and auth.uid() is distinct from founder_id() then
    raise exception 'A Pro cannot suspend another Pro — contact Cup Season';
  end if;

  update league_members
     set suspended_at   = coalesce(suspended_at, now()),
         suspended_by   = auth.uid(),
         suspend_reason = left(coalesce(p_reason,''), 500)
   where id = p_member;
end $function$;

CREATE OR REPLACE FUNCTION public.unhide_content(p_kind text, p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    if auth.uid() is distinct from founder_id() then raise exception 'not yours to restore'; end if;
    update round_comments set hidden_at = null, hidden_by = null, hidden_reason = null where id = p_id;
  else
    raise exception 'unknown kind: %', p_kind;
  end if;
end $function$;

CREATE OR REPLACE FUNCTION public.unsuspend_member(p_member uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_league uuid;
begin
  select league_id into v_league from league_members where id = p_member;
  if not found then raise exception 'no such member'; end if;
  if auth.uid() is distinct from founder_id() and not is_commissioner(v_league) then
    raise exception 'Only the Pro of this league can lift a suspension in it';
  end if;
  update league_members
     set suspended_at = null, suspended_by = null, suspend_reason = null
   where id = p_member;
end $function$;

-- ── D37 · re-assert the grants rather than trusting what replace kept ──────
revoke all on function public.cron_health() from public, anon;
grant execute on function public.cron_health() to authenticated;
revoke all on function public.hide_content(text,uuid,text) from public, anon;
grant execute on function public.hide_content(text,uuid,text) to authenticated;
revoke all on function public.moderation_queue() from public, anon;
grant execute on function public.moderation_queue() to authenticated;
revoke all on function public.resolve_report(uuid,text) from public, anon;
grant execute on function public.resolve_report(uuid,text) to authenticated;
revoke all on function public.scrap_forfeit(uuid) from public, anon;
grant execute on function public.scrap_forfeit(uuid) to authenticated;
revoke all on function public.set_round_rsvp(uuid,text) from public, anon;
grant execute on function public.set_round_rsvp(uuid,text) to authenticated;
revoke all on function public.suspend_member(uuid,text) from public, anon;
grant execute on function public.suspend_member(uuid,text) to authenticated;
revoke all on function public.unhide_content(text,uuid) from public, anon;
grant execute on function public.unhide_content(text,uuid) to authenticated;
revoke all on function public.unsuspend_member(uuid) from public, anon;
grant execute on function public.unsuspend_member(uuid) to authenticated;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_bad text;
begin
  -- The idiom may not come back anywhere in public, by any route. This is the
  -- check that found scrap_forfeit and set_round_rsvp; keep it broad.
  select string_agg(p.proname, ', ' order by p.proname) into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.prosrc ~ 'auth\.uid\(\)\s*(<>|!=)';
  if v_bad is not null then
    raise exception 'a null uid still passes a guard in: % — use `is distinct from`', v_bad;
  end if;

  select string_agg(p.proname, ', ' order by p.proname) into v_bad
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('cron_health','moderation_queue','hide_content','unhide_content',
                       'resolve_report','suspend_member','unsuspend_member',
                       'scrap_forfeit','set_round_rsvp')
     and not has_function_privilege('authenticated', p.oid, 'EXECUTE');
  if v_bad is not null then
    raise exception 'these lost their grant to authenticated: %', v_bad;
  end if;

  raise notice 'nine guards now fail closed; all nine still granted to authenticated';
end $chk$;
