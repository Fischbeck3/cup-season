-- ============================================================================
-- The Major — standalone championship on the event rails (D42–D46,
-- gameplay-modes §10). One weekend, every card on one board, one name on the
-- jug.
--
--   • events.kind='major' (no CHECK to alter — additive). No teams; the whole
--     field on one leaderboard. League-attachable exactly like the Ryder.
--   • The window is ONE event_sessions row: opens_on = final_on − days + 1,
--     closes_on = final_on (2–4 days, wizard defaults Thu→Sun). The daily
--     tick (run_event_sessions) opens it, narrates the final day, settles it.
--   • Scoring (D43): your BEST eligible card in the window — 18 holes, never
--     voided, never sim — by PvI at the event allowance off index_at_post.
--     No band ceiling. Board grammar speaks UNDER/OVER in words (PvI +4.2 =
--     "4.2 UNDER" — golf's red number, no sign-symbol ambiguity vs the
--     Ryder's +/− chips).
--   • Field line (D44): contend requires an ESTABLISHED engine index at
--     add-time — handicap_index() non-null is the engine's own definition,
--     and the starter guard (20260716120000) already blocks manual sets once
--     established, so a contender cannot carry a padded number. Everyone else
--     enters as EXHIBITION: on the board, never paid, official by the next
--     Major. Late entry until the horn.
--   • Ties (D45): countback — best card → second-best card (any beats none)
--     → earliest-posted best card → coin flip, logged to the board.
--   • Ceremony (D46): champion-only hardware (trophies kind 'major'),
--     completion story dual-homed to the league board when attached, pot per
--     D39 (ledger; places 60/25/15 with unclaimed shares rolling to the
--     champion, or winner-take-all).
--   • Spectator reads: an event attached to a league is the league's event —
--     read policies widen so crew members can see the field before entering
--     (enter_major is the self-serve door for attached majors).
--
-- D37 law: every client-called RPC gets an explicit grant; engine-only
-- functions are revoked from the API roles. Settled cards never retro-flip
-- (§R10 mirror); the live board is a definer read because rounds RLS is
-- owner-only (event_session_targets precedent).
-- ============================================================================

-- ---- schema: two columns on events, one flag on players, the cards table ---
alter table public.events
  add column if not exists buy_in    numeric not null default 0,
  add column if not exists pot_split text    not null default 'places';

alter table public.event_players
  add column if not exists exhibition boolean not null default false;

-- The Major's analog of event_duels: one frozen row per player at settle.
-- round_id is the §16 receipt; second_pvi/best_posted_at are the countback
-- rungs' receipts; rank is placement among CONTENDERS (exhibition and
-- no-card rows carry null rank).
create table if not exists public.event_major_cards (
  id             uuid primary key default gen_random_uuid(),
  event_id       uuid not null references public.events(id) on delete cascade,
  player_id      uuid not null references public.event_players(id) on delete cascade,
  round_id       uuid references public.rounds(id) on delete set null,
  gross          integer,
  pvi            numeric,
  second_pvi     numeric,
  cards          integer not null default 0,
  best_posted_at timestamptz,
  no_card        boolean not null default false,
  exhibition     boolean not null default false,
  rank           integer,
  prize          numeric not null default 0,
  resolved_at    timestamptz not null default now(),
  unique (event_id, player_id)
);
create index if not exists event_major_cards_event_idx
  on public.event_major_cards(event_id);

-- ---- spectator reads: an attached event is visible to its league ------------
create or replace function public.is_event_league_member(p_event uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from events e
                  where e.id = p_event and e.league_id is not null
                    and is_league_member(e.league_id));
$$;

drop policy if exists events_read on public.events;
create policy events_read on public.events for select to authenticated
  using (is_event_member(id) or created_by = auth.uid()
         or (league_id is not null and is_league_member(league_id)));

drop policy if exists event_players_read on public.event_players;
create policy event_players_read on public.event_players for select to authenticated
  using (is_event_member(event_id) or is_event_league_member(event_id));

drop policy if exists event_sessions_read on public.event_sessions;
create policy event_sessions_read on public.event_sessions for select to authenticated
  using (is_event_member(event_id) or is_event_league_member(event_id));

drop policy if exists event_duels_read on public.event_duels;
create policy event_duels_read on public.event_duels for select to authenticated
  using (is_event_member(event_id) or is_event_league_member(event_id));

-- the event board too: a crew member weighing entry should see the window's
-- story, not a dark room (the marquee beats are dual-homed, but card and
-- entry stories are event-board-only)
drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select to authenticated
  using ((league_id is not null and is_league_member(league_id))
      or (event_id is not null and (is_event_member(event_id)
                                    or is_event_league_member(event_id))));

alter table public.event_major_cards enable row level security;
drop policy if exists event_major_cards_read on public.event_major_cards;
create policy event_major_cards_read on public.event_major_cards for select to authenticated
  using (is_event_member(event_id) or is_event_league_member(event_id));
-- writes only via settle_major (definer); no insert/update policies.
grant select on public.event_major_cards to authenticated;

-- ---- voice helpers ----------------------------------------------------------
-- PvI in the Major's spoken grammar: +4.2 → "4.2 UNDER", −1.0 → "1 OVER".
create or replace function public.mj_vs(n numeric) returns text
language sql immutable as $$
  select case
    when n is null then 'NO CARD'
    when round(n,1) = 0 then 'LEVEL'
    when n > 0 then rtrim(rtrim(round(n,1)::text,'0'),'.') || ' UNDER'
    else rtrim(rtrim(round(abs(n),1)::text,'0'),'.') || ' OVER'
  end;
$$;

create or replace function public.mj_money(n numeric) returns text
language sql immutable as $$
  select '$' || rtrim(rtrim(round(n,2)::text,'0'),'.');
$$;

-- The engine's own establishment line: ≥3 real differentials. The starter
-- guard already refuses manual sets once this is non-null, so "established"
-- and "engine-derived" are the same fact.
create or replace function public.major_contender(p_profile uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select handicap_index(p_profile) is not null;
$$;

-- Dual-home marquee post: the event board, plus the league board when
-- attached (posts_home_check allows both ids; posts_read unions the readers).
create or replace function public.major_post(p_event uuid, p_body text)
returns void language sql security definer set search_path = public as $$
  insert into posts (league_id, event_id, kind, body)
  select e.league_id, e.id, 'system', left(p_body, 400)
    from events e where e.id = p_event;
$$;

-- ---- the live board (internal; ungated) -------------------------------------
-- One row per entered player: best eligible card in the window so far.
-- Ungated because the tick and triggers (auth.uid() null) read it; the
-- client goes through major_leaderboard below.
create or replace function public.major_board(p_event uuid)
returns table(player_id uuid, profile_id uuid, display_name text, marker text,
              exhibition boolean, round_id uuid, gross integer, pvi numeric,
              cards integer, best_posted_at timestamptz)
language sql stable security definer set search_path = public as $$
  select ep.id, ep.profile_id, pr.display_name, pr.marker, ep.exhibition,
         b.rid, b.gross, b.pvi, coalesce(b.cards, 0), b.posted_at
    from event_players ep
    join profiles pr on pr.id = ep.profile_id
    join events e on e.id = ep.event_id
    join event_sessions s on s.event_id = e.id and s.session_no = 1
    left join lateral (
      select r.id as rid, r.gross,
             round((r.index_at_post * e.allowance / 100.0) - r.differential, 1) as pvi,
             r.created_at as posted_at,
             count(*) over () as cards
        from rounds r
       where r.profile_id = ep.profile_id
         and r.played_on between s.opens_on and s.closes_on
         and not r.voided and coalesce(r.source,'app') <> 'sim'
         and r.holes_played = 18
         and r.index_at_post is not null and r.differential is not null
       order by pvi desc, r.created_at asc, r.id
       limit 1
    ) b on true
   where ep.event_id = p_event
   order by b.pvi desc nulls last, pr.display_name;
$$;

-- the client-facing read: member- or attached-league-gated
create or replace function public.major_leaderboard(p_event uuid)
returns table(player_id uuid, profile_id uuid, display_name text, marker text,
              exhibition boolean, round_id uuid, gross integer, pvi numeric,
              cards integer, best_posted_at timestamptz)
language sql stable security definer set search_path = public as $$
  select * from major_board(p_event)
   where is_event_member(p_event) or is_event_league_member(p_event);
$$;

-- ---- create_major -----------------------------------------------------------
create or replace function public.create_major(
  p_name text, p_final_on date, p_days integer default 4,
  p_buy_in numeric default 0, p_pot_split text default 'places',
  p_league uuid default null, p_tz text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_event uuid; v_name text; v_days integer; v_split text; v_buy numeric;
  v_open date; v_tz text;
begin
  v_name := nullif(trim(coalesce(p_name,'')), '');
  if v_name is null then raise exception 'Name the jug — a Major needs a name'; end if;
  if p_final_on is null or p_final_on < current_date then
    raise exception 'The final day has to be ahead of you';
  end if;
  if p_final_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  v_days  := greatest(2, least(4, coalesce(p_days, 4)));
  v_buy   := coalesce(p_buy_in, 0);
  if v_buy < 0 or v_buy > 100000 then raise exception 'buy-in out of range'; end if;
  v_split := coalesce(p_pot_split, 'places');
  if v_split not in ('places','wta') then raise exception 'pot split must be places or wta'; end if;
  if p_league is not null and not is_league_member(p_league) then
    raise exception 'you must be in the league to run a Major with it';
  end if;

  -- tz: league's active season > creator's device (validated) > Phoenix
  if p_league is not null then
    select timezone into v_tz from seasons
     where league_id = p_league order by number desc limit 1;
  end if;
  if v_tz is null and p_tz is not null then
    begin perform now() at time zone p_tz; v_tz := p_tz;
    exception when others then v_tz := null; end;
  end if;
  v_tz := coalesce(v_tz, 'America/Phoenix');

  v_open := p_final_on - v_days + 1;

  insert into events (name, created_by, league_id, kind, starts_on,
                      session_count, session_weeks, draw_rule, tz,
                      buy_in, pot_split)
  values (v_name, auth.uid(), p_league, 'major', v_open,
          1, 1, 'team_pvi', v_tz, v_buy, v_split)
  returning id into v_event;

  insert into event_sessions (event_id, session_no, opens_on, closes_on)
  values (v_event, 1, v_open, p_final_on);

  -- the organizer enters the field like anyone (role-blind)
  insert into event_players (event_id, profile_id, role, seed, exhibition)
  values (v_event, auth.uid(), 'player', 0, not major_contender(auth.uid()));

  -- the announce beat (league board too when attached)
  perform major_post(v_event,
    upper((select display_name from profiles where id = auth.uid()))
    || ' SET ' || upper(v_name) || ' — '
    || upper(to_char(v_open, 'Dy Mon DD')) || ' → ' || upper(to_char(p_final_on, 'Dy Mon DD'))
    || ' · BEST CARD TAKES THE JUG'
    || case when v_buy > 0 then ' · BUY-IN ' || mj_money(v_buy) else ' · BRAGGING RIGHTS' end);

  return v_event;
end $$;

-- ---- entering the field -----------------------------------------------------
-- Organizer add (existing RPC, now kind-aware): sets the exhibition flag for
-- majors and posts the entry. Roster guard unchanged — "a scored session
-- locks the roster" means, for a Major, entries close at settle: late entry
-- until the horn (D44).
create or replace function public.add_event_player(p_event uuid, p_profile uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_seed integer; v_kind text; v_exh boolean; v_n integer;
begin
  if not is_event_organizer(p_event) then raise exception 'organizer only'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'Roster locks once a session has been scored';
  end if;
  select kind into v_kind from events where id = p_event;
  v_exh := (v_kind = 'major') and not major_contender(p_profile);
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed, exhibition)
    values (p_event, p_profile, v_seed, v_exh)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  if v_id is not null and v_kind = 'major' then
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event,
      upper((select display_name from profiles where id = p_profile))
      || ' ENTERS THE FIELD (' || v_n || ')'
      || case when v_exh then ' · EXHIBITION — OFFICIAL BY THE NEXT ONE' else '' end);
  end if;
  return v_id;
end $$;

-- Self-serve entry for league-attached majors: any crew member walks in.
create or replace function public.enter_major(p_event uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v record; v_id uuid; v_seed integer; v_exh boolean; v_n integer;
begin
  select e.id, e.kind, e.status, e.league_id into v from events e where e.id = p_event;
  if v.id is null or v.kind <> 'major' then raise exception 'No such Major'; end if;
  if v.status = 'complete' then raise exception 'That one is settled — catch the next Major'; end if;
  if exists (select 1 from event_sessions where event_id = p_event and status = 'closed') then
    raise exception 'The horn has sounded — catch the next Major';
  end if;
  if v.league_id is null or not is_league_member(v.league_id) then
    raise exception 'Entry is by invite — ask the organizer';
  end if;

  v_exh := not major_contender(auth.uid());
  select coalesce(max(seed),0)+1 into v_seed from event_players where event_id = p_event;
  insert into event_players (event_id, profile_id, seed, exhibition)
    values (p_event, auth.uid(), v_seed, v_exh)
    on conflict (event_id, profile_id) do nothing
    returning id into v_id;
  if v_id is not null then
    select count(*) into v_n from event_players where event_id = p_event;
    perform event_post(p_event,
      upper((select display_name from profiles where id = auth.uid()))
      || ' ENTERS THE FIELD (' || v_n || ')'
      || case when v_exh then ' · EXHIBITION — OFFICIAL BY THE NEXT ONE' else '' end);
  end if;
  return v_id;
end $$;

-- ---- open / final day / settle ----------------------------------------------
create or replace function public.open_major(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare s record; v_today date; v_n integer; v_days integer;
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.buy_in, e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if auth.uid() is not null and not is_event_organizer(s.event_id) then
    raise exception 'organizer only';
  end if;
  if s.status <> 'upcoming' then return; end if;
  v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
  if s.opens_on > v_today then
    raise exception 'The window opens %', to_char(s.opens_on, 'Dy Mon DD');
  end if;
  select count(*) into v_n from event_players where event_id = s.event_id;
  if v_n < 2 then raise exception 'A Major needs a field — 2 at least'; end if;

  update event_sessions set status = 'open' where id = p_session;
  update events set status = 'live' where id = s.event_id and status = 'setup';

  v_days := s.closes_on - s.opens_on + 1;
  perform major_post(s.event_id,
    upper(s.name) || ' IS LIVE — ' || v_days || ' DAYS, FIELD OF ' || v_n
    || ' · BEST CARD BY ' || upper(to_char(s.closes_on, 'Dy')) || ' NIGHT TAKES THE JUG');
end $$;

-- the tick narrates the last day (cron-only; no grant)
create or replace function public.major_final_day(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare s record; l record; c record; v_line text;
begin
  select es.event_id, e.name into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major' and es.status = 'open';
  if s.event_id is null then return; end if;

  select * into l from major_board(s.event_id)
   where not exhibition and pvi is not null
   order by pvi desc, best_posted_at asc limit 1;

  if l.player_id is null then
    v_line := 'FINAL DAY AT ' || upper(s.name) || ' — NO CARDS YET. THE JUG IS THERE FOR THE TAKING';
  else
    select * into c from major_board(s.event_id)
     where not exhibition and pvi is not null and player_id <> l.player_id
     order by pvi desc, best_posted_at asc limit 1;
    v_line := 'FINAL DAY AT ' || upper(s.name) || ' — '
      || upper(l.display_name) || ' LEADS AT ' || mj_vs(l.pvi)
      || coalesce(' · ' || upper(c.display_name) || ' '
           || rtrim(rtrim(round(l.pvi - c.pvi, 1)::text,'0'),'.') || ' BACK', '');
  end if;
  perform major_post(s.event_id, v_line);
end $$;

create or replace function public.settle_major(p_session uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  s record; p record; t record; f record;
  b_pvi numeric[]; b_rid uuid[]; b_gross integer[]; b_at timestamptz[];
  v_cards integer; v_pot numeric; v_entrants integer;
  v_champ record; v_ru record; v_third record;
  v_share numeric; v_paid numeric := 0; v_places integer;
  v_line text; v_flip text := ''; v_tie text := '';
begin
  select es.id, es.event_id, es.opens_on, es.closes_on, es.status,
         e.name, e.tz, e.allowance, e.buy_in, e.pot_split, e.league_id,
         e.status as estatus
    into s
    from event_sessions es join events e on e.id = es.event_id
   where es.id = p_session and e.kind = 'major';
  if s.id is null then raise exception 'No such Major window'; end if;
  if s.status = 'closed' then return; end if;          -- idempotent
  if auth.uid() is not null then
    if not is_event_organizer(s.event_id) then raise exception 'organizer only'; end if;
    if s.closes_on >= (now() at time zone coalesce(s.tz,'America/Phoenix'))::date then
      raise exception 'The window runs through % — the horn sounds after', to_char(s.closes_on,'Dy Mon DD');
    end if;
  end if;

  -- freeze every player's card: best + second-best eligible in the window
  for p in select ep.id, ep.profile_id, ep.exhibition
             from event_players ep where ep.event_id = s.event_id
  loop
    select array_agg(x.pvi), array_agg(x.rid), array_agg(x.gross), array_agg(x.at)
      into b_pvi, b_rid, b_gross, b_at
      from (
        select round((r.index_at_post * s.allowance / 100.0) - r.differential, 1) as pvi,
               r.id as rid, r.gross, r.created_at as at
          from rounds r
         where r.profile_id = p.profile_id
           and r.played_on between s.opens_on and s.closes_on
           and not r.voided and coalesce(r.source,'app') <> 'sim'
           and r.holes_played = 18
           and r.index_at_post is not null and r.differential is not null
         order by pvi desc, r.created_at asc, r.id
         limit 2
      ) x;
    select count(*) into v_cards
      from rounds r
     where r.profile_id = p.profile_id
       and r.played_on between s.opens_on and s.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;

    insert into event_major_cards
      (event_id, player_id, round_id, gross, pvi, second_pvi, cards,
       best_posted_at, no_card, exhibition)
    values
      (s.event_id, p.id, b_rid[1], b_gross[1], b_pvi[1], b_pvi[2], v_cards,
       b_at[1], b_pvi[1] is null, p.exhibition)
    on conflict (event_id, player_id) do nothing;
  end loop;

  -- rank the contenders: the countback ladder (D45), coin flip last.
  -- Reset first so a rerun after a mid-settle crash can't strand a stale
  -- rank or prize on a row the fresh ranking no longer pays.
  update event_major_cards set rank = null, prize = 0 where event_id = s.event_id;
  with ranked as (
    select id, pvi, second_pvi, best_posted_at,
           row_number() over (order by pvi desc, second_pvi desc nulls last,
                              best_posted_at asc, random()) as rn
      from event_major_cards
     where event_id = s.event_id and not exhibition and not no_card
  )
  update event_major_cards c set rank = r.rn
    from ranked r where c.id = r.id;

  -- name the rungs that decided anything (receipts on the board)
  for t in
    select a.rank as arank, pa.display_name as aname, pb.display_name as bname,
           (a.second_pvi is not distinct from b.second_pvi
            and a.best_posted_at is not distinct from b.best_posted_at) as flipped
      from event_major_cards a
      join event_major_cards b on b.event_id = a.event_id and b.rank = a.rank + 1
      join event_players epa on epa.id = a.player_id join profiles pa on pa.id = epa.profile_id
      join event_players epb on epb.id = b.player_id join profiles pb on pb.id = epb.profile_id
     where a.event_id = s.event_id and a.pvi = b.pvi and a.rank <= 3
  loop
    if t.flipped then
      v_flip := v_flip || ' · COIN FLIP: ' || upper(t.aname) || ' OVER ' || upper(t.bname);
    elsif t.arank = 1 then
      v_tie := ' (ON COUNTBACK)';
    end if;
  end loop;

  -- the pot: contender entrants only (exhibition never buys in, never pays)
  select count(*) into v_entrants
    from event_major_cards where event_id = s.event_id and not exhibition;
  v_pot := s.buy_in * v_entrants;
  select count(*) into v_places
    from event_major_cards where event_id = s.event_id and rank is not null;

  if v_pot > 0 and v_places > 0 then
    if s.pot_split = 'wta' then
      update event_major_cards set prize = v_pot
       where event_id = s.event_id and rank = 1;
    else
      -- 60/25/15; a place the field can't fill rolls up to the champion
      if v_places >= 2 then
        v_share := round(v_pot * 0.25, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 2;
        v_paid := v_paid + v_share;
      end if;
      if v_places >= 3 then
        v_share := round(v_pot * 0.15, 2);
        update event_major_cards set prize = v_share
         where event_id = s.event_id and rank = 3;
        v_paid := v_paid + v_share;
      end if;
      update event_major_cards set prize = v_pot - v_paid
       where event_id = s.event_id and rank = 1;
    end if;
  end if;

  update event_sessions set status = 'closed' where id = p_session;

  -- podium reads
  select pr.display_name, c.gross, c.pvi, c.prize into v_champ
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 1;
  select pr.display_name, c.pvi into v_ru
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 2;
  select pr.display_name, c.pvi into v_third
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.rank = 3;

  -- completion FIRST (trophy trigger reads the ranked cards), then the story
  update events set status = 'complete' where id = s.event_id;

  if v_champ.display_name is null then
    v_line := upper(s.name) || ': '
      || case when exists (select 1 from event_major_cards
                            where event_id = s.event_id and exhibition and not no_card)
              then 'NO OFFICIAL CARDS — THE JUG STAYS IN THE CASE'
              else 'NO CARDS POSTED — THE JUG STAYS IN THE CASE' end
      || case when s.buy_in > 0 then ' · BUY-INS RETURNED' else '' end;
  else
    v_line := upper(s.name) || ' — CHAMPION: ' || upper(v_champ.display_name)
      || ' (' || v_champ.gross || ', ' || mj_vs(v_champ.pvi) || ')' || v_tie
      || coalesce(' · RUNNER-UP: ' || upper(v_ru.display_name) || ' ' || mj_vs(v_ru.pvi), '')
      || coalesce(' · THIRD: ' || upper(v_third.display_name) || ' ' || mj_vs(v_third.pvi), '')
      || case when v_pot > 0 then ' · POT ' || mj_money(v_pot)
              || case when s.pot_split = 'wta' then ' — WINNER TAKES IT'
                      else '' end
         else '' end
      || v_flip;
  end if;
  perform major_post(s.event_id, v_line);

  -- the best exhibition run gets its line (never the jug — D44)
  select pr.display_name, c.gross, c.pvi into f
    from event_major_cards c
    join event_players ep on ep.id = c.player_id join profiles pr on pr.id = ep.profile_id
   where c.event_id = s.event_id and c.exhibition and not c.no_card
   order by c.pvi desc limit 1;
  if f.display_name is not null then
    perform event_post(s.event_id,
      'EXHIBITION: ' || upper(f.display_name) || ' WENT ' || f.gross || ' (' || mj_vs(f.pvi)
      || ') — OFFICIAL BY THE NEXT ONE');
  end if;
end $$;

-- ---- trophies: the award branches on kind -----------------------------------
create or replace function public.award_event_trophies(p_event uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v record; v_champ uuid;
begin
  select kind, winner_team_id, name into v
    from events where id = p_event and status = 'complete';
  if not found then return; end if;

  if v.kind = 'major' then
    select ep.profile_id into v_champ
      from event_major_cards c join event_players ep on ep.id = c.player_id
     where c.event_id = p_event and c.rank = 1;
    if v_champ is not null then
      insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      values (v_champ, 'major', v.name, 'Major champion', 'winner', p_event,
              extract(year from current_date)::int)
      on conflict do nothing;
    end if;
    return;
  end if;

  -- the Ryder paths, unchanged (winner team / shared cup)
  if v.winner_team_id is not null then
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder', 'winner', p_event,
             extract(year from current_date)::int
        from event_players ep where ep.team_id = v.winner_team_id
      on conflict do nothing;
  else
    insert into trophies (profile_id, kind, title, subtitle, placement, event_id, season_year)
      select ep.profile_id, 'ryder', v.name, 'The Ryder · shared', 'shared', p_event,
             extract(year from current_date)::int
        from event_players ep where ep.team_id is not null
      on conflict do nothing;
  end if;
end $$;

-- ---- the tick learns the Major ----------------------------------------------
create or replace function public.run_event_sessions()
returns void language plpgsql security definer set search_path = public as $$
declare s record; v_today date;
begin
  for s in
    select es.id, es.opens_on, es.closes_on, es.status, e.tz, e.id as ev, e.kind
      from event_sessions es join events e on e.id = es.event_id
     where e.status in ('setup','live')
     order by es.opens_on
  loop
    v_today := (now() at time zone coalesce(s.tz,'America/Phoenix'))::date;
    if s.kind = 'major' then
      if s.status = 'upcoming' and s.closes_on < v_today then
        perform settle_major(s.id);            -- never-opened window past its horn
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
  end loop;
end $$;

-- ---- the window narrates itself ---------------------------------------------
-- A card lands: first card / improvement stories with clubhouse-lead context.
-- Worse re-attempts stay quiet (kind). Exhibition cards never take the lead.
create or replace function public.round_major_story() returns trigger
language plpgsql security definer set search_path = public as $$
declare m record; v_pvi numeric; v_prior numeric; v_lead numeric; v_name text; v_line text;
begin
  if new.voided or coalesce(new.source,'app') = 'sim' or new.holes_played <> 18
     or new.index_at_post is null or new.differential is null then
    return new;
  end if;
  for m in
    select e.id as ev, e.allowance, s.opens_on, s.closes_on,
           ep.id as player_id, ep.exhibition
      from events e
      join event_sessions s on s.event_id = e.id and s.status = 'open'
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status = 'live'
       and new.played_on between s.opens_on and s.closes_on
  loop
    v_pvi := round((new.index_at_post * m.allowance / 100.0) - new.differential, 1);
    select max(round((r.index_at_post * m.allowance / 100.0) - r.differential, 1))
      into v_prior
      from rounds r
     where r.profile_id = new.profile_id and r.id <> new.id
       and r.played_on between m.opens_on and m.closes_on
       and not r.voided and coalesce(r.source,'app') <> 'sim'
       and r.holes_played = 18
       and r.index_at_post is not null and r.differential is not null;
    if v_prior is not null and v_pvi <= v_prior then continue; end if;

    select max(pvi) into v_lead from major_board(m.ev)
     where not exhibition and pvi is not null and player_id <> m.player_id;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := upper(coalesce(v_name,'A GOLFER'))
      || case when v_prior is null then ' OPENS WITH ' else ' IMPROVES TO ' end
      || new.gross || ' — ' || mj_vs(v_pvi);
    if m.exhibition then
      v_line := v_line || ' (EXHIBITION)';
    elsif v_lead is null or v_pvi > v_lead then
      v_line := v_line || ' · TAKES THE CLUBHOUSE LEAD';
    elsif v_pvi = v_lead then
      v_line := v_line || ' · TIES THE LEAD';
    else
      v_line := v_line || ' · LEADER AT ' || mj_vs(v_lead);
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $$;
drop trigger if exists round_major_story_trg on public.rounds;
create trigger round_major_story_trg after insert on public.rounds
  for each row execute function public.round_major_story();

-- A round booked inside the window: the chase is a story (the owner's beat).
create or replace function public.sched_major_story() returns trigger
language plpgsql security definer set search_path = public as $$
declare m record; l record; v_name text; v_line text;
begin
  for m in
    select e.id as ev, ep.id as player_id
      from events e
      join event_sessions s on s.event_id = e.id and s.status in ('upcoming','open')
      join event_players ep on ep.event_id = e.id and ep.profile_id = new.profile_id
     where e.kind = 'major' and e.status in ('setup','live')
       and new.play_on between s.opens_on and s.closes_on
  loop
    select * into l from major_board(m.ev)
     where not exhibition and pvi is not null
     order by pvi desc, best_posted_at asc limit 1;
    select display_name into v_name from profiles where id = new.profile_id;

    v_line := upper(coalesce(v_name,'A GOLFER')) || ' BOOKED ' || upper(to_char(new.play_on,'Dy'))
      || coalesce(' AT ' || upper(new.course_label), '');
    if l.player_id is null then
      v_line := v_line || ' — FIRST CARD TAKES THE CLUBHOUSE';
    elsif l.player_id = m.player_id then
      v_line := v_line || ' — DEFENDING THE LEAD AT ' || mj_vs(l.pvi);
    else
      v_line := v_line || ' — CHASING ' || mj_vs(l.pvi);
    end if;
    perform event_post(m.ev, v_line);
  end loop;
  return new;
end $$;
drop trigger if exists sched_major_story_trg on public.scheduled_rounds;
create trigger sched_major_story_trg after insert on public.scheduled_rounds
  for each row execute function public.sched_major_story();

-- ---- invites learn the field line -------------------------------------------
-- respond_invite inserted event_players raw: an un-established invitee would
-- land as a contender, and an accept after the horn (or after a scored Ryder
-- session — §R10's roster lock, previously unguarded here) slipped into a
-- settled event. Kind-aware now; league path unchanged.
create or replace function public.respond_invite(p_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
declare mi member_invites%rowtype; v_idx numeric; v_name text;
        v_kind text; v_exh boolean; v_n integer;
begin
  select * into mi from member_invites where id = p_id and profile_id = auth.uid();
  if not found then raise exception 'invite not found'; end if;
  if mi.status <> 'pending' then return; end if;

  if p_accept then
    select display_name, index_current into v_name, v_idx from profiles where id = auth.uid();
    if mi.league_id is not null then
      insert into league_members (league_id, profile_id, role, index_current)
        values (mi.league_id, auth.uid(), 'player', coalesce(v_idx, 18.0))
        on conflict (league_id, profile_id) do nothing;
      insert into posts (league_id, kind, body)
        values (mi.league_id, 'system', upper(coalesce(v_name,'A golfer')) || ' JOINED THE LEAGUE');
    else
      select kind into v_kind from events where id = mi.event_id;
      if exists (select 1 from event_sessions
                  where event_id = mi.event_id and status = 'closed') then
        -- a raise rolls the txn back, so don't bother flipping the invite —
        -- it stays pending and the client surfaces this message
        raise exception 'That one has been scored — catch the next one';
      end if;
      v_exh := (v_kind = 'major') and not major_contender(auth.uid());
      insert into event_players (event_id, profile_id, seed, exhibition)
        values (mi.event_id, auth.uid(),
                coalesce((select max(seed)+1 from event_players where event_id=mi.event_id), 0),
                v_exh)
        on conflict (event_id, profile_id) do nothing;
      if v_kind = 'major' then
        select count(*) into v_n from event_players where event_id = mi.event_id;
        perform event_post(mi.event_id,
          upper(coalesce(v_name,'A GOLFER')) || ' ENTERS THE FIELD (' || v_n || ')'
          || case when v_exh then ' · EXHIBITION — OFFICIAL BY THE NEXT ONE' else '' end);
      end if;
    end if;
    update member_invites set status='accepted' where id = p_id;
  else
    update member_invites set status='declined' where id = p_id;
  end if;
end $$;
-- (grant already stands on this signature from 20260713180000)

-- ---- grants (D37: explicit or it 403s) --------------------------------------
revoke all on function public.create_major(text,date,integer,numeric,text,uuid,text) from public, anon, authenticated;
grant execute on function public.create_major(text,date,integer,numeric,text,uuid,text) to authenticated;

revoke all on function public.enter_major(uuid) from public, anon, authenticated;
grant execute on function public.enter_major(uuid) to authenticated;

revoke all on function public.major_leaderboard(uuid) from public, anon, authenticated;
grant execute on function public.major_leaderboard(uuid) to authenticated;

-- organizer recovery paths (human callers gated inside)
revoke all on function public.open_major(uuid) from public, anon, authenticated;
grant execute on function public.open_major(uuid) to authenticated;
revoke all on function public.settle_major(uuid) from public, anon, authenticated;
grant execute on function public.settle_major(uuid) to authenticated;

revoke all on function public.is_event_league_member(uuid) from public, anon, authenticated;
grant execute on function public.is_event_league_member(uuid) to authenticated;  -- used by RLS policies

-- engine-internal: never client-callable
revoke all on function public.major_board(uuid)      from public, anon, authenticated;
revoke all on function public.major_final_day(uuid)  from public, anon, authenticated;
revoke all on function public.major_post(uuid,text)  from public, anon, authenticated;
revoke all on function public.major_contender(uuid)  from public, anon, authenticated;
revoke all on function public.mj_vs(numeric)         from public, anon, authenticated;
revoke all on function public.mj_money(numeric)      from public, anon, authenticated;
revoke all on function public.round_major_story()    from public, anon, authenticated;
revoke all on function public.sched_major_story()    from public, anon, authenticated;
