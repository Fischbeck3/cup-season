-- R23 · D247 · A starter is not a typed number — the argument, and only the argument.
--
-- WHAT THIS FILE IS FOR. `set_profile` hard-codes nothing about the source of a
-- number today: it writes `index_current` and leaves `index_source` alone, and
-- the sibling setters (`set_index`, `set_member_index`) stamp `'self'`. D247
-- asks onboarding to ask "What do you usually shoot?" in bands and record the
-- answer as a STARTER — a fourth `index_source` value.
--
-- WHAT THIS FILE DELIBERATELY DOES NOT DO, AND WHY THAT IS AN OWNER RULING
-- RATHER THAN A GAP. C-13's fourth `index_source` value, the two sibling CHECK
-- audits, the widening of `round_refresh_index`'s handover clause, and every
-- new write to `profiles.index_current` are NOT here. `score_round` takes
-- `index_at_post` from caller → `profiles.index_current` → `handicap_index_asof`
-- → this round's own differential, so a band-derived figure in `index_current`
-- would SCORE rounds one, two and three. That is D124's option (ii), which
-- D124 — an OWNER RULING of 2026-08-29 — considered and declined in terms
-- ("seeding the starter from round one (ii) is not built"). Only the owner may
-- overturn an owner ruling.
--
-- SO THE STARTER SHIPS IN ITS DECLINED FORM: client-side only. Both clients
-- hold the band's figure locally, the ME strip renders `STARTER 13` so it is
-- never dressed as an established index (L-14), it never reaches `profiles`,
-- and `score_round` reaches its own-differential fallback exactly as D124
-- intended. R23's defaulted argument ships anyway, so the flip — the day the
-- owner rules it — is one line on each client and one migration.
--
-- CLAUDE.md:77-80 · the argument DEFAULTS, so a client that ships before this
-- migration calls the seven-argument function and a client that ships after it
-- sends nothing. Both write the same row.

-- Adding a defaulted parameter OVERLOADS rather than replaces, so the 7-arg
-- form is dropped first — exactly as `20260723150000_identity_photos.sql`
-- dropped the 6-arg form when the photo path arrived.
drop function if exists public.set_profile(text, text, text, numeric, text, text, text);

create or replace function public.set_profile(
  p_name text, p_city text default null, p_home text default null,
  p_index numeric default null, p_marker text default null, p_ghin text default null,
  p_photo_path text default null,
  -- R23. Null means "do not touch the source", which is every call in the
  -- field today and every call either client makes after this lands.
  p_index_source text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_old text; v_src text := nullif(btrim(coalesce(p_index_source, '')), '');
begin
  -- the avatar path is own-prefix by law (mirrors the storage policy)
  if p_photo_path is not null and p_photo_path <> ''
     and p_photo_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'photo path must live under your own prefix';
  end if;

  -- R23's refusal, and it is the load-bearing half of this file. The sibling
  -- CHECKs admit self / app / ghin (`initial_baseline.sql:1065, :1267`).
  -- 'starter' is C-13 and C-13 is NOT in this migration, so a caller who sends
  -- it is told so plainly rather than having the value silently dropped —
  -- a silently ignored source is how a client comes to believe it wrote one.
  if v_src is not null and v_src not in ('self', 'app', 'ghin') then
    raise exception 'index_source must be self, app or ghin (a starter is client-side until D124 is reopened)';
  end if;

  select display_name into v_old from profiles where id = auth.uid();

  insert into profiles (id, email, display_name, city, home_course, index_current, marker, ghin_number, photo_path, index_source)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker,
    nullif(trim(coalesce(p_ghin,'')), ''), nullif(p_photo_path, ''), v_src)
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker),
    ghin_number   = case when p_ghin is null then profiles.ghin_number
                         else nullif(trim(p_ghin), '') end,
    photo_path    = case when p_photo_path is null then profiles.photo_path
                         else nullif(p_photo_path, '') end,
    index_source  = coalesce(v_src, profiles.index_source);

  if p_name is not null and v_old is not null and trim(p_name) <> v_old then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(v_old) || ' NOW GOES BY ' || upper(trim(p_name))
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $$;
revoke all on function public.set_profile(text, text, text, numeric, text, text, text, text) from public, anon;
grant execute on function public.set_profile(text, text, text, numeric, text, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- D247 · the four dormant columns, dropped
-- ---------------------------------------------------------------------------
-- `card_quote`, `the_miss`, `walk_ride`, `beverage` have never been written by
-- either client and hold 0 of 39 values in production. D247 drops them because
-- they are the standing temptation to ask a fourth onboarding question — and
-- the third question ("what kind of golf do you play?") is ruled INFERRED, from
-- the buddy count, the arrival path and the first round. No `play_style` column
-- is added; if the inference is ever measured wrong, that is one migration.
alter table public.profiles drop column if exists card_quote;
alter table public.profiles drop column if exists the_miss;
alter table public.profiles drop column if exists walk_ride;
alter table public.profiles drop column if exists beverage;

-- ---------------------------------------------------------------------------
-- self-check (L-05 · read-only)
-- ---------------------------------------------------------------------------
do $chk$
declare v_src text; v_col text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'set_profile' and pronamespace = 'public'::regnamespace and pronargs = 8;
  if v_src is null then raise exception 'R23: set_profile(8) is missing'; end if;

  -- the 7-arg form must be GONE, or PostgREST has two candidates and picks by
  -- the keys sent — which is how a defaulted argument becomes a silent no-op
  if exists (select 1 from pg_proc
              where proname = 'set_profile' and pronamespace = 'public'::regnamespace and pronargs = 7) then
    raise exception 'R23: the 7-argument set_profile survived the drop — the overload would shadow it';
  end if;

  if position('starter' in v_src) = 0 then
    raise exception 'R23: the refusal that keeps C-13 out of this file is missing';
  end if;

  -- C-13 IS NOT HERE, and this check is what keeps it out: the sibling CHECKs
  -- must still admit exactly three values. A future migration that adds
  -- 'starter' is welcome to — it will have D124 reopened in its header.
  if exists (
    select 1 from pg_constraint
     where conrelid = 'public.profiles'::regclass and contype = 'c'
       and pg_get_constraintdef(oid) ilike '%index_source%'
       and pg_get_constraintdef(oid) ilike '%starter%') then
    raise exception 'C-13 landed in R23''s file — D124 is an owner ruling and only the owner reopens it';
  end if;

  foreach v_col in array array['card_quote','the_miss','walk_ride','beverage'] loop
    if exists (select 1 from information_schema.columns
                where table_schema='public' and table_name='profiles' and column_name = v_col) then
      raise exception 'D247: profiles.% survived the drop', v_col;
    end if;
  end loop;

  if has_function_privilege('anon', 'public.set_profile(text,text,text,numeric,text,text,text,text)', 'execute') then
    raise exception 'D37/L-04: set_profile is authenticated-only';
  end if;
  if not has_function_privilege('authenticated', 'public.set_profile(text,text,text,numeric,text,text,text,text)', 'execute') then
    raise exception 'L-04: set_profile has no grant — the card gate would 42501';
  end if;
end $chk$;
