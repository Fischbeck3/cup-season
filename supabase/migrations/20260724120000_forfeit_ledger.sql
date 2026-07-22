-- ============================================================================
-- The Forfeit Ledger — stakes past money (D64, blue-sky #3 unparked).
--
--   • A forfeit is a NAMED non-money stake with pot-grade rigor: name, terms,
--     parties, what it hangs on, settled-by, date. It never settles anything
--     itself (the D21 composition rule) — v1 settles are always a party's
--     confirm tap; the auto-hook onto duel/match results is the fast-follow.
--   • League-scoped (the crew container). party_b null = a standing bounty
--     against the field ("first ace: steak dinner from everyone").
--   • NO money column exists ON PURPOSE. Terms are prose. Nothing here may
--     ever render as dollars, convert to the pot, or grow a numeric amount —
--     that line is the store-review posture as much as taste (D39/D64).
--   • Board gets the story on post + settle + scrap (nothing moves silently,
--     §16). Settled forfeits archive into the rivalry read by pair.
--   • D37: RLS read for the crew; writes only through the RPCs below.
-- ============================================================================

create table if not exists public.forfeits (
  id           uuid primary key default gen_random_uuid(),
  league_id    uuid not null references public.leagues(id) on delete cascade,
  name         text not null,
  terms        text not null,
  kind         text not null default 'custom',
  party_a      uuid not null references public.profiles(id) on delete cascade,
  party_b      uuid references public.profiles(id) on delete cascade,
  hangs_on     text,
  status       text not null default 'open',
  winner       uuid references public.profiles(id) on delete set null,
  settled_note text,
  created_by   uuid not null references public.profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  settled_at   timestamptz,
  settled_by   uuid references public.profiles(id) on delete set null,
  constraint forfeits_kind_check
    check (kind in ('hosts','course_pick','strokes','bounty','custom')),
  constraint forfeits_status_check
    check (status in ('open','settled','scrapped')),
  constraint forfeits_name_len check (char_length(name) between 2 and 60),
  constraint forfeits_terms_len check (char_length(terms) between 2 and 200),
  constraint forfeits_parties check (party_b is null or party_b <> party_a)
);
create index if not exists forfeits_league_idx on public.forfeits(league_id, status);
create index if not exists forfeits_pair_idx on public.forfeits(party_a, party_b);

alter table public.forfeits enable row level security;
drop policy if exists forfeits_read on public.forfeits;
create policy forfeits_read on public.forfeits for select to authenticated
  using (is_league_member(league_id));
-- writes only via the RPCs (definer); no insert/update/delete policies.
grant select on public.forfeits to authenticated;

-- ---- post a stake -----------------------------------------------------------
create or replace function public.create_forfeit(
  p_league uuid, p_name text, p_terms text,
  p_kind text default 'custom', p_other uuid default null, p_hangs text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_name text; v_terms text; v_a text; v_b text;
begin
  if not is_league_member(p_league) then raise exception 'crew only'; end if;
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
    if not exists (select 1 from league_members
                    where league_id = p_league and profile_id = p_other) then
      raise exception 'The other side has to be in the crew';
    end if;
  end if;

  insert into forfeits (league_id, name, terms, kind, party_a, party_b, hangs_on, created_by)
  values (p_league, left(v_name,60), left(v_terms,200), coalesce(p_kind,'custom'),
          auth.uid(), p_other, nullif(trim(coalesce(p_hangs,'')),''), auth.uid())
  returning id into v_id;

  select upper(display_name) into v_a from profiles where id = auth.uid();
  select upper(display_name) into v_b from profiles where id = p_other;
  insert into posts (league_id, kind, body)
  values (p_league, 'system',
    'STAKE POSTED: ' || upper(v_name)
    || case when v_b is not null then ' — ' || v_a || ' VS ' || v_b
            else ' — ' || v_a || ' VS THE FIELD' end
    || ' · ' || v_terms);
  return v_id;
end $$;

-- ---- settle it (a party's tap; the Pro is the D50 backstop) -----------------
create or replace function public.settle_forfeit(
  p_id uuid, p_winner uuid default null, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare f record; v_line text; v_w text;
begin
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then return; end if;   -- idempotent
  if auth.uid() not in (f.party_a, coalesce(f.party_b, f.party_a))
     and not is_commissioner(f.league_id) then
    raise exception 'Only a party (or the Pro) settles a stake';
  end if;
  -- a duel's winner is one of its parties; a bounty pays anyone in the crew
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

  select upper(display_name) into v_w from profiles where id = p_winner;
  v_line := 'STAKE SETTLED: ' || upper(f.name) || ' — ' || v_w || ' TAKES IT · ' || f.terms;
  insert into posts (league_id, kind, body) values (f.league_id, 'system', left(v_line,400));
end $$;

-- ---- scrap it (creator or the Pro, only while open; the board hears it) -----
create or replace function public.scrap_forfeit(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare f record;
begin
  select * into f from forfeits where id = p_id;
  if f.id is null then raise exception 'No such stake'; end if;
  if f.status <> 'open' then raise exception 'Settled stakes stand — the archive keeps them'; end if;
  if auth.uid() <> f.created_by and not is_commissioner(f.league_id) then
    raise exception 'Only the poster (or the Pro) scraps a stake';
  end if;
  update forfeits set status = 'scrapped', settled_at = now(), settled_by = auth.uid()
   where id = p_id;
  insert into posts (league_id, kind, body)
  values (f.league_id, 'system', 'STAKE SCRAPPED: ' || upper(f.name));
end $$;

-- ---- grants (D37) -----------------------------------------------------------
revoke all on function public.create_forfeit(uuid,text,text,text,uuid,text) from public, anon, authenticated;
grant execute on function public.create_forfeit(uuid,text,text,text,uuid,text) to authenticated;
revoke all on function public.settle_forfeit(uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.settle_forfeit(uuid,uuid,text) to authenticated;
revoke all on function public.scrap_forfeit(uuid) from public, anon, authenticated;
grant execute on function public.scrap_forfeit(uuid) to authenticated;
