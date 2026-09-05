-- ============================================================================
-- D242 · A forfeit can exist between two golfers with no season (C-5)
--
-- A forfeit is T-02's noun: the ONE way an optional stake is expressed in this
-- product. It required a league, so "loser buys" between two buddies who share
-- no season was inexpressible — and the only thing the app could offer instead
-- was a thirteen-week season for a Saturday bet.
--
-- THE RULE THIS FILE RESTATES, IN THE WORDS THE ORIGINAL USED
-- (20260724120000_forfeit_ledger.sql:10-13):
--
--     NO money column exists ON PURPOSE. Terms are prose. Nothing here may
--     ever render as dollars, convert to the pot, or grow a numeric amount —
--     that line is the store-review posture as much as taste (D39/D64).
--
-- It is restated because this file widens the table, and a widening is exactly
-- when a rule gets quietly dropped. `tests/db-checks.sql` gains the tripwire.
--
-- WHAT CHANGES
--   1. `league_id` becomes nullable; `event_id` and `scheduled_round_id` are
--      added; a CHECK requires AT MOST ONE container, and a second CHECK
--      requires a container OR a named opponent — the fourth home the draft
--      did not name, and the one the callout's own stake needs (D237).
--   2. `forfeits_read` moves with the write. It was `is_league_member(league_id)`
--      and a null league_id makes that null, which reads as FALSE — so the
--      widened writer would have inserted rows nobody could ever see.
--   3. `create_forfeit`'s "crew only" becomes "a shared season, a shared
--      moment, a shared plan, or accepted buddies", with p_event and p_round
--      DEFAULTED (CLAUDE.md:77-80 — the owner deploys the database and the
--      client separately, and either order must render an honest screen).
--   4. The board post is written only where there IS a board — a league.
--      A buddy forfeit has no crew to tell and tells nobody (L-22).
--
-- 0 rows in prod, which makes this the safest migration in the set.
-- This file runs BEFORE the callout's, because R19 records a callout's stake
-- through the widened `create_forfeit` and a migration may not depend on one
-- that has not run.
-- ============================================================================

-- ── 1 · the columns and the two CHECKs ──────────────────────────────────────
alter table public.forfeits alter column league_id drop not null;
alter table public.forfeits
  add column if not exists event_id            uuid references public.events(id) on delete cascade,
  add column if not exists scheduled_round_id  uuid references public.scheduled_rounds(id) on delete cascade;

create index if not exists forfeits_event_idx on public.forfeits(event_id) where event_id is not null;
create index if not exists forfeits_round_idx on public.forfeits(scheduled_round_id) where scheduled_round_id is not null;

alter table public.forfeits drop constraint if exists forfeits_one_home;
alter table public.forfeits add constraint forfeits_one_home check (
  (case when league_id is not null then 1 else 0 end)
+ (case when event_id is not null then 1 else 0 end)
+ (case when scheduled_round_id is not null then 1 else 0 end) <= 1);

alter table public.forfeits drop constraint if exists forfeits_has_home;
alter table public.forfeits add constraint forfeits_has_home check (
  league_id is not null or event_id is not null
  or scheduled_round_id is not null or party_b is not null);

-- ── 2 · the read moves with the write ───────────────────────────────────────
drop policy if exists forfeits_read on public.forfeits;
create policy forfeits_read on public.forfeits for select to authenticated
  using (
       (league_id is not null and is_league_member(league_id))
    or (event_id  is not null and is_event_member(event_id))
    or (scheduled_round_id is not null and exists (
          select 1 from scheduled_rounds sr
           where sr.id = forfeits.scheduled_round_id
             and (sr.profile_id = auth.uid() or auth.uid() = any(sr.tagged))))
    or auth.uid() in (party_a, party_b)
  );

-- ── 3 · create_forfeit, widened ─────────────────────────────────────────────
-- Body = 20260724120000_forfeit_ledger.sql:52-89, verbatim but for the
-- eligibility gate, the home arguments and the board post's own guard.
--
-- The 6-arg shape is DROPPED, not kept beside it: two functions of the same
-- name whose first three arguments are the only required ones are ambiguous,
-- and `create_forfeit(a,b,c)` would raise "function is not unique" rather than
-- doing anything. Skew is safe without it — PostgREST resolves by ARGUMENT
-- NAME, so a shipped client sending the six it knows lands on this one with
-- p_event and p_round defaulted, which is a league forfeit, which is what it
-- does today.
drop function if exists public.create_forfeit(uuid,text,text,text,uuid,text);

create or replace function public.create_forfeit(
  p_league uuid, p_name text, p_terms text,
  p_kind text default 'custom', p_other uuid default null, p_hangs text default null,
  p_event uuid default null, p_round uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_name text; v_terms text; v_a text; v_b text; v_homes int;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;

  v_homes := (case when p_league is not null then 1 else 0 end)
           + (case when p_event  is not null then 1 else 0 end)
           + (case when p_round  is not null then 1 else 0 end);
  if v_homes > 1 then raise exception 'A forfeit hangs on one thing'; end if;
  if v_homes = 0 and p_other is null then
    raise exception 'Say who it is with, or what it hangs on';
  end if;

  -- "a shared season, a shared moment, a shared plan, or accepted buddies"
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'crew only';
  end if;
  if p_event is not null and not is_event_member(p_event) then
    raise exception 'You have to be in it to put something on it';
  end if;
  if p_round is not null and not exists (
       select 1 from scheduled_rounds sr
        where sr.id = p_round
          and (sr.profile_id = auth.uid() or auth.uid() = any(sr.tagged))) then
    raise exception 'You have to be on the round to put something on it';
  end if;

  v_name  := nullif(trim(coalesce(p_name,'')),'');
  v_terms := nullif(trim(coalesce(p_terms,'')),'');
  if v_name is null or v_terms is null then
    raise exception 'A stake needs a name and terms';
  end if;
  if coalesce(p_kind,'custom') not in ('hosts','course_pick','strokes','bounty','custom') then
    raise exception 'unknown stake kind';
  end if;
  if p_other is not null then
    if p_other = auth.uid() then raise exception 'You can''t stake against yourself'; end if;
    if p_league is not null then
      if not exists (select 1 from league_members
                      where league_id = p_league and profile_id = p_other) then
        raise exception 'The other side has to be in the crew';
      end if;
    elsif p_event is not null then
      if not exists (select 1 from event_players
                      where event_id = p_event and profile_id = p_other) then
        raise exception 'The other side has to be in it';
      end if;
    elsif p_round is not null then
      if not exists (select 1 from scheduled_rounds sr
                      where sr.id = p_round
                        and (sr.profile_id = p_other or p_other = any(sr.tagged))) then
        raise exception 'The other side has to be on the round';
      end if;
    else
      -- no container at all: buddies only, the same consent rule an RSVP uses (D69)
      if not exists (select 1 from friendships f
                      where f.status = 'accepted'
                        and ((f.requester = auth.uid() and f.addressee = p_other)
                          or (f.addressee = auth.uid() and f.requester = p_other))) then
        raise exception 'Forfeits are between buddies. Add them first';
      end if;
    end if;
  end if;

  insert into forfeits (league_id, event_id, scheduled_round_id, name, terms, kind,
                        party_a, party_b, hangs_on, created_by)
  values (p_league, p_event, p_round, left(v_name,60), left(v_terms,200),
          coalesce(p_kind,'custom'), auth.uid(), p_other,
          nullif(trim(coalesce(p_hangs,'')),''), auth.uid())
  returning id into v_id;

  -- The board post is written only where there IS a board. A forfeit between
  -- two buddies with no season tells nobody but the two of them (L-22).
  if p_league is not null then
    select upper(display_name) into v_a from profiles where id = auth.uid();
    select upper(display_name) into v_b from profiles where id = p_other;
    insert into posts (league_id, kind, body)
    values (p_league, 'system',
      'STAKE POSTED: ' || upper(v_name)
      || case when v_b is not null then ' — ' || v_a || ' VS ' || v_b
              else ' — ' || v_a || ' VS THE FIELD' end
      || ' · ' || v_terms);
  end if;
  return v_id;
end $$;

revoke all on function public.create_forfeit(uuid,text,text,text,uuid,text,uuid,uuid) from public, anon;
grant execute on function public.create_forfeit(uuid,text,text,text,uuid,text,uuid,uuid) to authenticated;

-- ── 4 · settle_forfeit / scrap_forfeit lose their league assumption ─────────
create or replace function public.settle_forfeit(
  p_id uuid, p_winner uuid default null, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare f record; v_line text; v_w text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then return; end if;   -- idempotent
  if auth.uid() not in (f.party_a, coalesce(f.party_b, f.party_a))
     and not (f.league_id is not null and is_commissioner(f.league_id)) then
    raise exception 'Only a party (or the Pro) settles a stake';
  end if;
  if f.party_b is not null then
    if p_winner is null or p_winner not in (f.party_a, f.party_b) then
      raise exception 'Name the winner — one of the two parties';
    end if;
  else
    if p_winner is null
       or not exists (select 1 from league_members
                       where league_id = f.league_id and profile_id = p_winner) then
      raise exception 'Name who hit it — someone in the crew';
    end if;
  end if;

  update forfeits
     set status = 'settled', winner = p_winner,
         settled_note = nullif(trim(coalesce(p_note,'')),''),
         settled_at = now(), settled_by = auth.uid()
   where id = p_id;

  if f.league_id is not null then
    select upper(display_name) into v_w from profiles where id = p_winner;
    v_line := 'STAKE SETTLED: ' || upper(f.name) || ' — ' || v_w || ' TAKES IT · ' || f.terms;
    insert into posts (league_id, kind, body) values (f.league_id, 'system', left(v_line,400));
  end if;
end $$;

create or replace function public.scrap_forfeit(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare f record;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then raise exception 'Settled stakes stand — the archive keeps them'; end if;
  -- D221 / db-check 22 · a plain inequality against a column is NULL when
  -- either side is null, so the `if` never fires and the guard fails OPEN. The
  -- idiom is `is distinct from`, 20260904173000 already fixed this body, and
  -- copying the 2026-07 original back over it would have reopened it. (The
  -- check greps prosrc, and a plpgsql body carries its comments — so the
  -- forbidden shape may not appear even in a sentence about it.)
  if auth.uid() is distinct from f.created_by
     and not (f.league_id is not null and is_commissioner(f.league_id)) then
    raise exception 'Only the poster (or the Pro) scraps a stake';
  end if;
  update forfeits set status = 'scrapped', settled_at = now(), settled_by = auth.uid()
   where id = p_id;
  if f.league_id is not null then
    insert into posts (league_id, kind, body)
    values (f.league_id, 'system', 'STAKE SCRAPPED: ' || upper(f.name));
  end if;
end $$;

revoke all on function public.settle_forfeit(uuid,uuid,text) from public, anon;
grant execute on function public.settle_forfeit(uuid,uuid,text) to authenticated;
revoke all on function public.scrap_forfeit(uuid) from public, anon;
grant execute on function public.scrap_forfeit(uuid) to authenticated;

-- ── 5 · self-check (L-05: read-only, never mutates a real row) ──────────────
do $chk$
declare v_n int; v_src text;
begin
  -- the no-money-column rule, enforced rather than quoted
  select count(*) into v_n
    from information_schema.columns
   where table_schema = 'public' and table_name = 'forfeits'
     and (column_name ~* '(cents|amount|dollars|stake|price|money)');
  if v_n > 0 then
    raise exception 'D242: forfeits grew a money column — terms are prose (20260724120000:10-13)';
  end if;

  -- exactly one home, expressed as at-most-one container plus a home requirement
  if not exists (select 1 from pg_constraint
                  where conname = 'forfeits_one_home'
                    and conrelid = 'public.forfeits'::regclass) then
    raise exception 'D242: forfeits_one_home is missing';
  end if;
  if not exists (select 1 from pg_constraint
                  where conname = 'forfeits_has_home'
                    and conrelid = 'public.forfeits'::regclass) then
    raise exception 'D242: forfeits_has_home is missing';
  end if;

  -- the read moved with the write
  select qual::text into v_src from pg_policies
   where schemaname = 'public' and tablename = 'forfeits' and policyname = 'forfeits_read';
  if v_src is null or position('event_id' in v_src) = 0
     or position('scheduled_round_id' in v_src) = 0 or position('party_b' in v_src) = 0 then
    raise exception 'D242: forfeits_read still only knows about a league';
  end if;

  -- the widened writer takes both new homes, defaulted
  select prosrc into v_src from pg_proc
   where proname = 'create_forfeit' and pronamespace = 'public'::regnamespace
     and pronargs = 8;
  if v_src is null then raise exception 'D242: create_forfeit(8) is missing'; end if;
  if position('Forfeits are between buddies' in v_src) = 0 then
    raise exception 'D242: create_forfeit still refuses two buddies with no season';
  end if;
end $chk$;
