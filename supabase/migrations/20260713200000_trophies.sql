-- Trophies — the display case. A permanent, cross-league ledger of hardware:
-- league Cup Finals, Ryder cups, and (later) Majors and Brackets all mint a
-- row here for each winner. This is the reward layer that gives every event
-- stakes beyond the moment — a career, not a fixture.
--
-- Trophies are earned by completion events, never inserted by the client.
-- Ryder events mint via a trigger on events.status → 'complete'. League Cup
-- Finals will mint from the 008 crowning when it lands (call award_* there).

create table if not exists public.trophies (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  kind        text not null,                    -- 'ryder' | 'league' | 'major' | 'bracket'
  title       text not null,                    -- the competition name, e.g. "The Grudge"
  subtitle    text,                             -- e.g. "The Ryder", "Champion"
  placement   text not null default 'winner',   -- 'winner' | 'runner_up' | 'points_king' …
  event_id    uuid references public.events(id)  on delete set null,
  league_id   uuid references public.leagues(id) on delete set null,
  season_year integer,
  earned_on   date not null default current_date,
  created_at  timestamptz not null default now()
);
create index if not exists trophies_profile_idx on public.trophies(profile_id, earned_on desc);
-- a golfer wins at most one trophy per event / per league-season-placement
create unique index if not exists trophies_event_uq
  on public.trophies(event_id, profile_id) where event_id is not null;
create unique index if not exists trophies_league_uq
  on public.trophies(league_id, profile_id, placement, season_year) where league_id is not null;

alter table public.trophies enable row level security;
drop policy if exists trophies_read on public.trophies;
-- your own case (the You tab). Viewing another golfer's case is a later RPC.
create policy trophies_read on public.trophies for select to authenticated
  using (profile_id = auth.uid());

-- ---- my display case, newest first ----
create or replace function public.my_trophies()
returns table(id uuid, kind text, title text, subtitle text, placement text,
              season_year integer, earned_on date)
language sql stable security definer set search_path = public as $$
  select id, kind, title, subtitle, placement, season_year, earned_on
  from trophies where profile_id = auth.uid()
  order by earned_on desc, created_at desc;
$$;

-- ---- mint trophies for a completed event's winning team ----
create or replace function public.award_event_trophies(p_event uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_win uuid; v_name text;
begin
  select winner_team_id, name into v_win, v_name
    from events where id = p_event and status = 'complete';
  if v_win is null then return; end if;
  insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
    select ep.profile_id, 'ryder', v_name, 'The Ryder', 'winner', p_event,
           extract(year from current_date)::int
      from event_players ep
     where ep.team_id = v_win
    on conflict do nothing;
end $$;

-- ---- trigger: any path that completes an event mints its trophies ----
create or replace function public.trg_event_complete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and new.winner_team_id is not null
     and (old.status is distinct from 'complete') then
    perform award_event_trophies(new.id);
  end if;
  return new;
end $$;
drop trigger if exists event_complete_award on public.events;
create trigger event_complete_award after update on public.events
  for each row execute function public.trg_event_complete();

grant execute on function public.my_trophies() to authenticated;
grant select on public.trophies to authenticated;
