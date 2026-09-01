-- ============================================================================
-- Cup Season — a cron job failed in production and nothing said so
--
-- `cron.job_run_details`, read 2026-09-01:
--
--   job 4  run_event_sessions  2026-08-30 07:15:00  failed
--   ERROR: column reference "a_pvi" is ambiguous
--
-- The BUG is already gone — `20260830160000_resolve_session_ambiguous_pvi.sql`
-- fixed it later the same day, and prod's `prosrc` no longer contains the
-- ambiguous assignment. What is not gone is the reason nobody knew: **nothing
-- in this repo has ever read `cron.job_run_details`.** The failure was found by
-- an audit, nine days later, by accident.
--
-- The second half is worse than the first. Every cron entry point is a bare
-- `for … loop` with no exception handling, so the loop is one transaction:
-- ONE bad league rolls the batch back for ALL of them. That is survivable for
-- the daily tick, which runs again tomorrow. It is not survivable for
-- `run_month_closes`, which runs at 07:10 on the 1st of the month, has no
-- catch-up and no retry — a single failure permanently loses that month's
-- floor penalties, auto-byes and bonuses for every league in the product.
--
-- This migration does the half that is safe to do in a week with a submission
-- in it: isolation and visibility for `run_event_sessions` — the job that
-- actually failed — plus somewhere for a failure to be seen. **The money
-- paths (`run_month_closes`, the weekly snapshot) are deliberately NOT
-- rewritten here**: changing how a month close handles a partial failure is a
-- decision about the ledger behind real dollars, and it deserves its own pass
-- rather than riding along with an events fix.
-- ============================================================================

create table if not exists public.job_failures (
  id         uuid primary key default gen_random_uuid(),
  job        text not null,
  subject    text,                         -- the row/league/session that failed
  sqlstate   text,
  message    text not null,
  created_at timestamptz not null default now()
);
alter table public.job_failures enable row level security;
-- no policy: this table is read through a SECURITY DEFINER function only, and
-- written by SECURITY DEFINER cron functions. `authenticated` gets nothing.
revoke all on table public.job_failures from public, anon, authenticated;

create index if not exists job_failures_recent_idx
  on public.job_failures (created_at desc);

-- ---- run_event_sessions, per-session isolation ----------------------------
-- Same body as prod on 2026-09-01, with each session's work wrapped. A session
-- that raises now records itself and the loop carries on to the next one,
-- instead of taking every other event down with it.
create or replace function public.run_event_sessions()
returns void language plpgsql security definer set search_path = public as $$
declare s record; v_today date; v_state text; v_msg text;
begin
  for s in
    select es.id, es.opens_on, es.closes_on, es.status, e.tz, e.id as ev, e.kind
      from event_sessions es join events e on e.id = es.event_id
     -- D146: 'complete' included so a clinched event's remaining sessions still
     -- open and resolve for the record (spec R4). resolve_session refuses to
     -- re-decide a settled event, so this cannot move a cup already awarded.
     where e.status in ('setup','live','complete')
     order by es.opens_on
  loop
    begin
      v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
      if s.kind = 'major' then
        if s.status = 'upcoming' and s.closes_on < v_today then
          perform settle_major(s.id);
        elsif s.status = 'upcoming' and s.opens_on <= v_today then
          if (select count(*) from event_players where event_id = s.ev) >= 2 then
            perform open_major(s.id);
          end if;
        elsif s.status = 'open' and s.closes_on = v_today then
          perform major_final_day(s.id);
        elsif s.status = 'open' and s.closes_on < v_today then
          perform settle_major(s.id);
        end if;
      else
        if s.status = 'upcoming' and s.opens_on <= v_today then
          if exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                      where t.event_id = s.ev and t.slot = 0)
             and exists (select 1 from event_players ep join event_teams t on t.id = ep.team_id
                      where t.event_id = s.ev and t.slot = 1) then
            perform generate_pairings(s.id);
          end if;
        elsif s.status = 'open' and s.closes_on < v_today then
          perform resolve_session(s.id);
        end if;
      end if;
    exception when others then
      get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
      insert into job_failures (job, subject, sqlstate, message)
      values ('run_event_sessions', 'session ' || s.id::text, v_state, v_msg);
      -- and keep going: one broken event must not close every other one's day
    end;
  end loop;
end $$;

-- ---- somewhere the founder can SEE it -------------------------------------
-- Reads both books: the ones pg_cron kept (whole-job failures) and the ones the
-- isolated loop above records (per-row failures that no longer fail the job).
create or replace function public.cron_health()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v jsonb;
begin
  if auth.uid() <> founder_id() then
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
end $$;

revoke all on function public.cron_health() from public, anon;
grant execute on function public.cron_health() to authenticated;

do $$
begin
  if (select prosrc from pg_proc p join pg_namespace n on n.oid = p.pronamespace
       where n.nspname='public' and p.proname='run_event_sessions') not like '%job_failures%' then
    raise exception '[cron] run_event_sessions still has no per-session isolation';
  end if;
end $$;
