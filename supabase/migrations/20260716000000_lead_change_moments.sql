-- ============================================================================
-- Cup Season — events engine, checkpoint 2: LEAD-CHANGE MOMENTS
--
-- The squad-race counterpart to ckpt-1's personal moments: "MUDSHARKS MOVED
-- INTO FIRST" the instant a posted round vaults a squad to the top. Doing this
-- CORRECTLY needs a before/after leader — a heuristic ("this round's squad is
-- now #1") false-fires on ties and on the season's first round. So we keep a
-- tiny state row per season and compare.
--
--   season_lead(season_id, squad_id, since): the current record-holding leader.
--   First observation of a strict leader is stored SILENTLY (nobody was "first"
--   before, so "moved into first" would be a lie). Thereafter, a strict
--   overtake by a DIFFERENT squad announces + updates.
--
-- Strictness guard: only fire when the new leader's points strictly exceed
-- second place — a tie at the top (order-by picking one arbitrarily) is not a
-- lead change and must not flap. Squad points only rise on a round INSERT
-- (counting-cap displacement never lowers a total; the adjustments ledger moves
-- on cron, not here), so the before/after at insert time is sound.
--
-- Separate trigger from round_moments(): a lead change is a squad-level event
-- that can co-occur with a personal headline (break 80 AND take first) — both
-- deserve their own post, so they never compete for the single headline slot.
-- ============================================================================

create table if not exists public.season_lead (
  season_id uuid primary key references public.seasons(id) on delete cascade,
  squad_id  uuid references public.squads(id) on delete set null,
  since     timestamptz not null default now()
);
-- system state: written only by the security-definer trigger, read by no client
alter table public.season_lead enable row level security;

create or replace function public.squad_lead_moments() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  r            record;
  v_leader     uuid;
  v_leader_pts numeric;
  v_second_pts numeric;
  v_prior      uuid;
  v_lname      text;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  for r in
    select s.id as season_id, s.league_id
      from league_members lm
      join seasons s on s.league_id = lm.league_id
                    and s.status in ('active', 'cup_final')
                    and new.played_on between s.starts_on and s.ends_on
     where lm.profile_id = new.profile_id
  loop
    -- leader after this round (top by points; squad_id only to make it total)
    select squad_id, points into v_leader, v_leader_pts
      from v_squad_standings
     where season_id = r.season_id
     order by points desc, squad_id
     limit 1;
    if v_leader is null then continue; end if;

    select points into v_second_pts
      from v_squad_standings
     where season_id = r.season_id and squad_id <> v_leader
     order by points desc
     limit 1;

    -- a real, sole leader (nobody tied at the top)
    if v_second_pts is not null and v_leader_pts <= v_second_pts then
      continue;
    end if;

    select squad_id into v_prior from season_lead where season_id = r.season_id;

    if v_prior is null then
      -- first-ever strict leader: record silently, never announce
      insert into season_lead (season_id, squad_id) values (r.season_id, v_leader)
        on conflict (season_id) do update set squad_id = excluded.squad_id, since = now();
      continue;
    end if;

    if v_leader <> v_prior then
      select name into v_lname from squads where id = v_leader;
      insert into posts (league_id, season_id, kind, member_id, body)
      values (r.league_id, r.season_id, 'moment', null,
              upper(coalesce(v_lname, 'A SQUAD')) || ' MOVED INTO FIRST');
      update season_lead set squad_id = v_leader, since = now()
       where season_id = r.season_id;
    end if;
  end loop;

  return new;
end $$;

drop trigger if exists trg_squad_lead_moments on public.rounds;
create trigger trg_squad_lead_moments
  after insert on public.rounds
  for each row execute function public.squad_lead_moments();
