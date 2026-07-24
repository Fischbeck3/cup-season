-- ============================================================================
-- Cup Season — deep-dive fixes, email batch (audit b7: findings #1, #14)
--
-- #14  A sandbox season reaches 'complete' via the crowning (the whole point of
--      the rehearsal), and the completion trigger had no sandbox guard — so a
--      sandbox run queued a real recap email to the founder's real alias. The
--      "a sandbox league can mail no one" invariant was false. Fence the
--      trigger on leagues.sandbox: no queue row is ever created for a sandbox
--      close.
--
-- #1   email_prefs rows are created lazily (only when a member opens the
--      profile hub), so most recipients had NO row and season_email_payload's
--      left join handed them a NULL token — an email with no working
--      unsubscribe link. A bare COALESCE(token, gen_random_uuid()) can't fix it:
--      email_unsubscribe matches a PERSISTED token. So the payload now backfills
--      a real email_prefs row (default recap=true) for every league member
--      before building the list, and becomes volatile to do so.
-- ============================================================================

-- ---- #14: sandbox close never queues an email ------------------------------
create or replace function public.season_email_on_complete()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and coalesce(old.status,'') <> 'complete'
     and not exists (select 1 from leagues l
                      where l.id = new.league_id and l.sandbox) then
    insert into email_queue (season_id, kind) values (new.id, 'season_recap')
    on conflict (season_id, kind) do nothing;
  end if;
  return new;
end $$;
revoke all on function public.season_email_on_complete() from public, anon, authenticated;
-- trigger definition unchanged; the function body is what the trigger runs.

-- ---- #1: every recipient gets a persisted unsubscribe token ----------------
create or replace function public.season_email_payload(p_season uuid)
returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare se seasons%rowtype; v_league text; v_champ text; v_run text; v_king text;
        v_rows jsonb; v_to jsonb; v_solo boolean; st league_settings%rowtype;
begin
  select * into se from seasons where id = p_season and status = 'complete';
  if se.id is null then return null; end if;
  select name into v_league from leagues where id = se.league_id;
  select * into st from league_settings where league_id = se.league_id;
  v_solo := (coalesce(st.structure,'') = 'solo');

  -- #1: ensure a persisted prefs row (hence a real token) for every member
  -- BEFORE building the list. Idempotent; default recap=true keeps everyone
  -- opted in unless they've turned it off.
  insert into email_prefs (profile_id)
    select lm.profile_id from league_members lm where lm.league_id = se.league_id
  on conflict (profile_id) do nothing;

  if v_solo then
    select p.display_name into v_champ from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.champion_member_id;
    select p.display_name into v_run from league_members lm
      join profiles p on p.id = lm.profile_id where lm.id = se.runnerup_member_id;
  else
    select name into v_champ from squads where id = se.champion_squad_id;
    select name into v_run   from squads where id = se.runnerup_squad_id;
  end if;
  select p.display_name into v_king from league_members lm
    join profiles p on p.id = lm.profile_id where lm.id = se.points_king_member_id;

  if v_solo then
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select p.display_name as name, vi.points from v_individual_standings vi
              join league_members lm on lm.id = vi.member_id
              join profiles p on p.id = lm.profile_id
             where vi.season_id = p_season order by vi.points desc limit 5) q;
  else
    select coalesce(jsonb_agg(jsonb_build_object('name', q.name, 'points', q.points)
             order by q.points desc), '[]'::jsonb) into v_rows
      from (select s.name, vs.points from v_squad_standings vs
              join squads s on s.id = vs.squad_id
             where vs.season_id = p_season order by vs.points desc limit 5) q;
  end if;

  -- recipients: real addresses only, still opted in, with their own money line
  select coalesce(jsonb_agg(jsonb_build_object(
           'email', t.email, 'name', t.display_name,
           'token', t.token, 'cents', t.cents)), '[]'::jsonb)
    into v_to
    from (
      select p.email, p.display_name,
             ep.token,
             coalesce((select sum(sp.cents) from season_payouts sp
                        where sp.season_id = p_season and sp.profile_id = p.id), 0) as cents
        from league_members lm
        join profiles p on p.id = lm.profile_id
        left join email_prefs ep on ep.profile_id = p.id
       where lm.league_id = se.league_id
         and p.email is not null
         and p.email <> ''
         and p.email not like '%@cupseason.invalid'
         and p.email not like '%@sandbox.cupseason.test'
         and coalesce(ep.recap, true)
    ) t;

  return jsonb_build_object(
    'season_id', p_season, 'league', v_league,
    'champion', coalesce(v_champ,'The champion'), 'runner_up', v_run,
    'points_king', v_king,
    'champion_score', se.champion_score, 'runnerup_score', se.runnerup_score,
    'tiebreak', se.tiebreak_rung,
    'starts_on', to_char(se.starts_on,'YYYY-MM-DD'),
    'ends_on',   to_char(se.ends_on,'YYYY-MM-DD'),
    'rows', v_rows, 'recipients', v_to);
end $$;
revoke all on function public.season_email_payload(uuid) from public, anon, authenticated;
grant execute on function public.season_email_payload(uuid) to service_role;
