-- D180 · the roster has a door, and the Pro holds the handle.
--
-- THE BUG, measured before it was theorised: five of the seven locked leagues
-- in production were born with a DEAD join code. Fellas locked 2026-07-20 with
-- a first tee of 2026-07-20 — its code has never worked, not once.
--
-- D161 wrote the window as [lock, first tee) on the assumption that lock comes
-- BEFORE first tee. It never handled lock >= first tee. So the lock screen said
-- "Lock opens the invite link" and, for the majority of real leagues, lock
-- CLOSED it. The app handed the Pro a link and invalidated it in the same
-- action. (An earlier attempt at this shipped a WARNING at lock. That explained
-- the incoherence instead of removing it, and made the app argue with the Pro
-- about a choice the app had made badly. It is deleted in the same commit.)
--
-- The second half, which nobody had named: THERE WAS NO WAY TO CLOSE A CODE.
-- No rotate, no close, nothing in the schema. A league that filled on day one
-- with a first tee a month out had a live link for a month, screenshots and
-- all, and its Pro could do nothing about it.
--
-- So the door gets a handle and two guarantees:
--
--   opens    at lock
--   closes   when the PRO closes it — or at first tee if they never do
--   floor    a league locked ON OR AFTER its first tee gets a week regardless,
--            so a link is never born dead
--
-- The floor is a backstop, not a rule the Pro has to learn: it exists only so
-- that "lock opens the invite link" is true in every case. It does NOT widen
-- the window for a league that locked before first tee — that behaviour is
-- D161's ruling and is untouched.
--
-- NAMING, deliberately: this is "the roster", not "tee it up". The season still
-- starts on `seasons.starts_on`, which drives week numbers, clash windows,
-- month closes and the Cup Final trigger (ends_on - 27). Conflating "the roster
-- is closed" with "the season begins" is the two-concepts-one-date mistake that
-- caused this bug; a button called "Tee it up" that closed a roster would
-- repeat it.

alter table public.league_settings
  add column if not exists roster_closed_at timestamptz;

comment on column public.league_settings.roster_closed_at is
  'D180 · when the Pro closed the roster. Non-null = the join CODE stops working; the Pro can still add people until the halfway turn. Null = open (subject to first tee and the lock floor).';

-- ---- the gate, with the door and the floor ---------------------------------
create or replace function public._join_gate(p_league uuid, p_via_pro boolean)
returns void
language plpgsql
stable
security definer
set search_path = public
as $fn$
declare
  v_phase text; v_name text;
  v_starts date; v_ends date; v_tz text;
  v_today date; v_half date;
  v_closed timestamptz; v_locked timestamptz;
begin
  select phase, name into v_phase, v_name from leagues where id = p_league;
  if v_phase = 'setup' then
    raise exception '% isn''t open yet — the Pro is still locking in the rules. Try again once they have.', coalesce(v_name, 'That league');
  end if;
  if v_phase = 'complete' then
    raise exception 'That season is finished — ask the Pro to run it back.';
  end if;

  select ls.roster_closed_at, ls.locked_at into v_closed, v_locked
    from league_settings ls where ls.league_id = p_league;

  -- D180 · the Pro's explicit close beats every date rule. It stops the CODE
  -- only: the Pro's own door stays open to the halfway turn below.
  if v_closed is not null and not p_via_pro then
    raise exception 'The roster''s closed for this season — ask the Pro to add you. You''re welcome on the tee sheet meanwhile.';
  end if;

  select s.starts_on, s.ends_on, coalesce(s.timezone, 'America/Phoenix')
    into v_starts, v_ends, v_tz
    from seasons s
   where s.league_id = p_league and s.status in ('active', 'cup_final')
   order by s.starts_on desc limit 1;
  if v_starts is null then return; end if;   -- no live season: the open window

  v_today := (now() at time zone v_tz)::date;
  if v_today < v_starts then return; end if;  -- before first tee: open to all

  -- D180 · THE FLOOR. A league locked on or after its own first tee had a
  -- zero-length window — the link was dead the instant it was created. Give it
  -- a week from lock, and only it: a league locked before first tee already had
  -- a real window and keeps exactly the one D161 ruled.
  if v_locked is not null
     and (v_locked at time zone v_tz)::date >= v_starts
     and v_today <= (v_locked at time zone v_tz)::date + 7 then
    return;
  end if;

  if not p_via_pro then
    raise exception 'The season''s underway — ask the Pro to add you. You''re welcome on the tee sheet meanwhile.';
  end if;

  v_half := v_starts + ((v_ends - v_starts) / 2);
  if v_today > v_half then
    raise exception 'Past the halfway turn — the roster''s set for this season. They''re welcome on the tee sheet, and in the next one the moment you run it back.';
  end if;
end $fn$;

revoke all on function public._join_gate(uuid, boolean) from public, anon, authenticated;

-- ---- the handle -------------------------------------------------------------
-- The Pro closes the roster when the crew is in, and can reopen it. Both are
-- board events: the roster is one of the season's terms (D112's covenant), so
-- changing it is not a private setting.
create or replace function public.close_roster(p_league uuid, p_open boolean default false)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $fn$
declare v_at timestamptz; v_n int; v_me uuid;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro sets the roster';
  end if;

  v_at := case when p_open then null else now() end;
  update league_settings set roster_closed_at = v_at where league_id = p_league;

  select count(*) into v_n from league_members where league_id = p_league;
  v_me := my_member_id(p_league);

  insert into posts (league_id, kind, member_id, body)
  values (p_league, 'system', v_me,
          case when p_open
               then 'The roster is open again — the invite link works.'
               else 'The roster is set. ' || v_n || ' in.' end);

  return v_at;
end $fn$;

revoke execute on function public.close_roster(uuid, boolean) from public, anon;
grant execute on function public.close_roster(uuid, boolean) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare
  v_lg uuid; v_season uuid; v_msg text; v_ok boolean;
begin
  -- D37
  if not has_function_privilege('authenticated', 'public.close_roster(uuid, boolean)', 'execute') then
    raise exception 'D37: close_roster is not executable by authenticated';
  end if;
  if has_function_privilege('anon', 'public.close_roster(uuid, boolean)', 'execute') then
    raise exception 'D37: close_roster is reachable by anon';
  end if;

  -- BEHAVIOURAL · the floor. Fellas is the real case: locked 2026-07-20, first
  -- tee 2026-07-20. Rebuild that shape and prove the code lives.
  select l.id into v_lg from leagues l
    join league_settings ls on ls.league_id = l.id
    join seasons s on s.league_id = l.id and s.status in ('active','cup_final')
   where ls.locked_at is not null limit 1;
  if v_lg is null then
    raise notice 'D180: no locked league with a live season — behavioural check skipped';
    return;
  end if;

  -- born-dead shape: lock today, first tee today
  update league_settings set locked_at = now(), roster_closed_at = null where league_id = v_lg;
  update seasons set starts_on = current_date where league_id = v_lg and status in ('active','cup_final');
  begin
    perform _join_gate(v_lg, false);
    v_ok := true;
  exception when others then v_ok := false; v_msg := SQLERRM;
  end;
  if not v_ok then
    raise exception 'D180: the floor did not hold — a link locked on its own first tee is still dead (%)', v_msg;
  end if;

  -- and eight days later it is properly closed again
  update league_settings set locked_at = now() - interval '8 days' where league_id = v_lg;
  update seasons set starts_on = current_date - 8 where league_id = v_lg and status in ('active','cup_final');
  begin
    perform _join_gate(v_lg, false);
    v_ok := true;
  exception when others then v_ok := false;
  end;
  if v_ok then
    raise exception 'D180: the floor never expires — the window is now unbounded';
  end if;

  -- BEHAVIOURAL · the Pro's close beats an otherwise-open window
  update league_settings set locked_at = now(), roster_closed_at = now() where league_id = v_lg;
  update seasons set starts_on = current_date + 30 where league_id = v_lg and status in ('active','cup_final');
  begin
    perform _join_gate(v_lg, false);
    v_ok := true;
  exception when others then v_ok := false; v_msg := SQLERRM;
  end;
  if v_ok then
    raise exception 'D180: a closed roster still admitted a code join';
  end if;
  if v_msg not like '%roster''s closed%' then
    raise exception 'D180: the closed-roster refusal says the wrong thing: %', v_msg;
  end if;

  -- but the PRO still gets through a closed roster
  begin
    perform _join_gate(v_lg, true);
    v_ok := true;
  exception when others then v_ok := false; v_msg := SQLERRM;
  end;
  if not v_ok then
    raise exception 'D180: a closed roster locked the PRO out too (%)', v_msg;
  end if;
end $chk$;
