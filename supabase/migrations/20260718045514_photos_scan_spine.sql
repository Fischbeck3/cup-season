-- ============================================================================
-- Photos arc (#13, D36) — one storage build under all three checkpoints:
--   ckpt 1  round photos     (bucket + rounds.photo_path)
--   ckpt 3  scorecard OCR    (app_flags kill switch + scan_usage cost ledger)
--   stretch foursome claims  (scan_claims + the claim funnel RPCs)
--
-- Cost discipline is structural, not aspirational: the scan Edge Function
-- refuses before it spends — kill switch off, per-golfer daily cap, or global
-- monthly cap all fail CLOSED, and the client degrades to typed front/back
-- entry (the scan is an accelerator, never a dependency). The caps live in
-- app_flags so the Pro can retune or kill scanning from the SQL editor with
-- no deploy.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Storage: one private bucket. Reads are signed-URL only (any signed-in
--    golfer; league-scoping enforced at the UI layer for v1 — documented in
--    spec/photos-arc.md). Writes/deletes are locked to the uploader's own
--    {uid}/ prefix.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('media', 'media', false)
on conflict (id) do nothing;

create policy media_read on storage.objects for select to authenticated
  using (bucket_id = 'media');
create policy media_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy media_delete on storage.objects for delete to authenticated
  using (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------------
-- 2. Rounds carry their photo (facts stay on the round; the board post finds
--    it through round_id like everything else).
-- ---------------------------------------------------------------------------
alter table public.rounds add column if not exists photo_path text;

-- ---------------------------------------------------------------------------
-- 3. Remote-control flags. Readable by the client (it hides the scan button
--    when disabled); writable only from the SQL editor / dashboard.
--    Budget changes and the kill switch are an UPDATE here, never a deploy.
-- ---------------------------------------------------------------------------
create table if not exists public.app_flags (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.app_flags enable row level security;
create policy flags_read on public.app_flags for select to authenticated using (true);

insert into public.app_flags (key, value) values
  ('scan', '{"enabled": true, "daily_per_user": 5, "monthly_global": 400}'::jsonb)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 4. Scan ledger: one row per attempted scan. The Edge Function writes it with
--    the service role; the API roles can't touch it. This is both the cap
--    counter and the accuracy dataset (cells_fixed arrives from the client
--    breadcrumb in client_events; ok=false rows are model/API failures).
-- ---------------------------------------------------------------------------
create table if not exists public.scan_usage (
  id         uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  model      text,
  ok         boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists scan_usage_profile_idx on public.scan_usage (profile_id, created_at);
create index if not exists scan_usage_created_idx on public.scan_usage (created_at);
alter table public.scan_usage enable row level security;
-- no API policies on purpose: service-role only

-- ---------------------------------------------------------------------------
-- 5. Foursome claims (the stretch). A scanned card carries the whole group's
--    rows; the poster mints a claim per partner. Mirrors the live-round guest
--    claim funnel (20260716140000) so /?claim= serves both: the client tries
--    the live claim first, then this one.
--    delete_account safe by construction: created_by CASCADE, claimed SET NULL.
-- ---------------------------------------------------------------------------
create table if not exists public.scan_claims (
  id              uuid primary key default gen_random_uuid(),
  token           uuid not null unique default gen_random_uuid(),
  created_by      uuid not null references public.profiles(id) on delete cascade,
  guest_name      text,
  course_label    text,
  rating          numeric,
  slope           integer,
  played_on       date,
  gross           integer,
  strokes         jsonb,            -- 18-slot int array, 0 = unknown hole
  holes_played    integer not null default 18,
  claimed_profile uuid references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now()
);
alter table public.scan_claims enable row level security;
-- all access flows through the security-definer RPCs below

-- Mint a claim for a partner row. Lightly capped so the endpoint can't be
-- farmed (8/day covers two full foursomes).
create or replace function public.create_scan_claim(
  p_name text, p_gross int, p_strokes jsonb, p_course text,
  p_rating numeric, p_slope int, p_played date, p_holes int default 18
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid := auth.uid(); v_tok uuid;
begin
  if v is null then raise exception 'not signed in'; end if;
  if (select count(*) from scan_claims
       where created_by = v and created_at > now() - interval '24 hours') >= 8 then
    raise exception 'Claim limit reached for today';
  end if;
  insert into scan_claims (created_by, guest_name, course_label, rating, slope,
                           played_on, gross, strokes, holes_played)
  values (v, nullif(trim(coalesce(p_name,'')),''), p_course, p_rating, p_slope,
          p_played, p_gross, coalesce(p_strokes, '[]'::jsonb), coalesce(p_holes, 18))
  returning token into v_tok;
  return v_tok;
end $$;
revoke all on function public.create_scan_claim(text,int,jsonb,text,numeric,int,date,int) from public;
grant execute on function public.create_scan_claim(text,int,jsonb,text,numeric,int,date,int) to authenticated;

-- The door card: what's waiting behind the link (anon-readable by token —
-- the unguessable token IS the authorization, same as claim_round_info).
create or replace function public.scan_claim_info(p_token uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare c record;
begin
  select * into c from scan_claims where token = p_token;
  if c is null then raise exception 'Claim link not recognized'; end if;
  return jsonb_build_object(
    'guest_name', c.guest_name,
    'gross', c.gross,
    'course_label', c.course_label,
    'played_on', c.played_on,
    'claimed', c.claimed_profile is not null);
end $$;
grant execute on function public.scan_claim_info(uuid) to anon, authenticated;

-- The claim: the partner signs in, the row becomes a real round on THEIR
-- profile (scored by the trigger, fanned by round_to_board like any round).
create or replace function public.claim_scan_round(p_token uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  c record; v uuid := auth.uid(); v_round uuid;
  v_strokes int[]; v_nine boolean; i int;
begin
  if v is null then raise exception 'not signed in'; end if;
  select * into c from scan_claims where token = p_token;
  if c is null then raise exception 'Claim link not recognized'; end if;
  if c.claimed_profile is not null then
    if c.claimed_profile = v then
      return jsonb_build_object('claimed', true, 'posted', false, 'already', true);
    end if;
    raise exception 'That card was already claimed';
  end if;
  if c.created_by = v then
    raise exception 'That card belongs to a playing partner — your own round is already posted';
  end if;

  update scan_claims set claimed_profile = v where id = c.id;

  if c.gross is null or c.gross < 18 then
    return jsonb_build_object('claimed', true, 'posted', false);
  end if;

  v_nine := coalesce(c.holes_played, 18) = 9;
  insert into rounds (profile_id, gross, rating, nine_rating, slope, holes_played,
                      played_on, course_label, source)
  values (v, c.gross, c.rating,
          case when v_nine then c.rating / 2 else null end,
          c.slope, coalesce(c.holes_played, 18),
          coalesce(c.played_on, current_date), c.course_label, 'scan_claim')
  returning id into v_round;

  v_strokes := array(select coalesce(nullif(x,'null'),'0')::int
                       from jsonb_array_elements_text(coalesce(c.strokes,'[]'::jsonb)) x);
  if v_strokes is not null then
    for i in 1..least(coalesce(array_length(v_strokes,1),0), 18) loop
      if v_strokes[i] > 0 then
        insert into round_holes (round_id, hole_number, strokes)
        values (v_round, i, v_strokes[i]);
      end if;
    end loop;
  end if;

  return jsonb_build_object('claimed', true, 'posted', true, 'gross', c.gross);
end $$;
revoke all on function public.claim_scan_round(uuid) from public;
grant execute on function public.claim_scan_round(uuid) to authenticated;
