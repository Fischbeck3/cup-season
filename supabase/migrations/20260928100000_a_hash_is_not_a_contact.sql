-- C-11 · D251 (R-G) · A hash is not a contact.
--
-- THE SENTENCE THE PRODUCT COULD NOT SAY. `search_golfers` matches an exact
-- @handle or an existing relation (L-37), so a golfer who signed in an hour ago
-- cannot find the two friends who are already here. "Three of your friends are
-- already here" is the brief's own line and today it is not a sentence this
-- product can honestly print.
--
-- THE PRIVACY MODEL, IN FOUR CLAUSES, AND EVERY ONE OF THEM IS ENFORCED BELOW.
--
--   1 · THE SALT IS SERVER-SIDE AND NEVER REACHES A CLIENT. It lives in
--       `contact_pepper`, a one-row table with no grant to anybody — not
--       `authenticated`, not `anon`, not even for select — and is read only
--       from inside SECURITY DEFINER functions. `ContactHash.swift` (Kit) and
--       `csContactHash` (web) do NORMALISATION and a plain SHA-256; neither can
--       produce a value this database stores, which is what makes a stolen
--       phone useless against the column.
--
--   2 · WHAT TRAVELS IS A DIGEST, NOT A CONTACT. The client sends
--       `sha256(normalised)` in hex. The server peppers it —
--       `sha256(salt || that digest)` — and compares. So the consent sentence
--       ("We send hashes, never your contacts") is literally true of the wire,
--       and the column is not the thing the client sent either.
--
--   3 · THE COLUMN IS NOT READABLE BY A CLIENT, AND THAT IS DELIBERATE. `profiles`
--       is COLUMN-granted (26 columns to `authenticated`), so a new column is
--       unreadable by default and this file leaves it that way. The plan's file
--       list asked for `grant select (contact_hash) … to authenticated` under
--       L-04; L-04 exists so that a column a client SELECTS does not 42501, and
--       no client selects this one. Granting it would hand every signed-in
--       golfer the peppered digest of everyone's email, which is precisely the
--       offline-matching the RPC's gate exists to prevent. The self-check
--       asserts the column is NOT selectable — the inverse check, on purpose.
--
--   4 · THE RPC ANSWERS ONLY ABOUT KEYS THE CALLER ALREADY HOLDS. That is
--       `nearby_resolve`'s envelope (`20260830250000:84-120`) and it is why
--       D150's "an index of its users wants its own decision" is not reopened:
--       there is no browsable list, no count of near-misses, no "somebody
--       matched". A stranger's contact produces nothing at all. What replaces
--       nearby_resolve's already-a-buddy clause is `search_golfers`' OWN gate
--       (L-37): a golfer who set themselves to friends-only stays hidden here
--       too. A golfer who has hidden themselves is hidden from their own
--       address book.
--
-- WHAT THIS HONESTLY CANNOT DO TODAY, SAID HERE RATHER THAN FOUND LATER.
-- `profiles` has no phone column and this app signs in by email OTP, so the
-- only phone identity in the database is `auth.users.phone`, which is null for
-- every account. Phone normalisation ships on both clients and in the backfill
-- because a contact book is mostly phone numbers and the shape must be right
-- the day a phone identity exists — but today a phone hash matches nothing.
-- D251 already says most matches will return nothing; this is the mechanical
-- reason, and it is why the empty result was specified before the happy path.

-- ---------------------------------------------------------------------------
-- 1 · the pepper — server-side, ungranted, generated once
-- ---------------------------------------------------------------------------
create table if not exists public.contact_pepper (
  only_row boolean primary key default true check (only_row),
  salt     bytea   not null,
  created_at timestamptz not null default now()
);
alter table public.contact_pepper enable row level security;   -- and no policy, ever
revoke all on public.contact_pepper from public, anon, authenticated;

insert into public.contact_pepper (only_row, salt)
select true, extensions.gen_random_bytes(32)
 where not exists (select 1 from public.contact_pepper);

-- ---------------------------------------------------------------------------
-- 2 · the column
-- ---------------------------------------------------------------------------
-- An array because a golfer has more than one contact: the email they signed in
-- with, and (one day) a phone. Never a raw contact; never a reversible digest.
alter table public.profiles add column if not exists contact_hash text[];
create index if not exists profiles_contact_hash_idx on public.profiles using gin (contact_hash);
-- clause 3 above: no grant. Stated as a statement so the intent is in the file.
revoke select (contact_hash) on public.profiles from authenticated, anon;

-- ---------------------------------------------------------------------------
-- 3 · normalisation — ONE definition, and the clients mirror it exactly
-- ---------------------------------------------------------------------------
-- `ContactHashTests` / `tests/app-tests.js` assert the same cases against the
-- same inputs. If this ever changes, three files change together or a golfer's
-- own email stops matching their own row.
-- C-07 · btrim's default strips SPACES only, while both clients trim tabs and
-- newlines too (Swift `.whitespacesAndNewlines`, JS `.trim()`). A tab-padded
-- address hashed differently on the two sides, and a mismatched digest is
-- silent — it simply never matches. The trim set is named here so the three
-- implementations are one contract rather than three close readings.
create or replace function public.cs_normalise_email(p_raw text)
returns text language sql immutable as $fn$
  select nullif(lower(btrim(coalesce(p_raw, ''), E' \t\n\r\f\v')), '')
$fn$;

-- Digits only; a bare 10-digit number is North American and takes a 1; the
-- result is "+" and digits. Fewer than nine digits is a local fragment, not a
-- number anybody can be reached on, and it hashes to nothing rather than to a
-- short string thousands of contact books would collide on. No provider-specific
-- cleverness — a guess about somebody's carrier is a guess about their identity.
create or replace function public.cs_normalise_phone(p_raw text)
returns text language sql immutable as $fn$
  select case
    when d is null or length(d) < 9 then null
    when length(d) = 10 then '+1' || d
    else '+' || d
  end
  from (select nullif(regexp_replace(coalesce(p_raw, ''), '[^0-9]', '', 'g'), '') as d) x
$fn$;

-- The client's half: plain SHA-256 of the normalised value, hex. No salt.
create or replace function public.cs_contact_digest(p_normalised text)
returns text language sql immutable as $fn$
  select case when p_normalised is null or p_normalised = '' then null
              else encode(extensions.digest(convert_to(p_normalised, 'UTF8'), 'sha256'), 'hex') end
$fn$;

-- The server's half: the pepper over the client's digest. Ungranted; reachable
-- only from the definer functions below.
create or replace function public.cs_pepper(p_client_digest text)
returns text language sql stable security definer set search_path = public as $fn$
  select case
    when p_client_digest is null then null
    when p_client_digest !~ '^[0-9a-f]{64}$' then null
    else encode(extensions.digest(cp.salt || decode(p_client_digest, 'hex'), 'sha256'), 'hex')
  end
    from public.contact_pepper cp
   limit 1
$fn$;
revoke all on function public.cs_pepper(text) from public, anon, authenticated;

-- C-13 · L-04's shape is that EVERY new function is revoked from public and
-- anon, not only the ones a client calls. The three transforms above are
-- unsalted and a client can compute them anyway, so this is posture rather
-- than a hole — but posture is what L-04 is, and an ungranted function nobody
-- notices is how the next one ships ungranted on purpose.
revoke all on function public.cs_normalise_email(text) from public, anon;
revoke all on function public.cs_normalise_phone(text) from public, anon;
revoke all on function public.cs_contact_digest(text) from public, anon;

-- ---------------------------------------------------------------------------
-- 4 · keeping a golfer's own row hashed
-- ---------------------------------------------------------------------------
create or replace function public.profile_refresh_contact_hash()
returns trigger language plpgsql security definer set search_path = public as $fn$
declare v_phone text;
begin
  select u.phone into v_phone from auth.users u where u.id = new.id;
  new.contact_hash := (
    select coalesce(array_agg(distinct h), '{}'::text[])
      from (
        select cs_pepper(cs_contact_digest(cs_normalise_email(new.email)))  as h
        union all
        select cs_pepper(cs_contact_digest(cs_normalise_phone(v_phone)))
      ) x
     where h is not null
  );
  return new;
end $fn$;

revoke all on function public.profile_refresh_contact_hash() from public, anon;   -- C-13

drop trigger if exists profile_contact_hash_trg on public.profiles;
create trigger profile_contact_hash_trg
  before insert or update of email on public.profiles
  for each row execute function public.profile_refresh_contact_hash();

-- the backfill. Not a self-check — a migration statement, and the only write to
-- a real row in this file.
update public.profiles p
   set contact_hash = (
     select coalesce(array_agg(distinct h), '{}'::text[])
       from (
         select public.cs_pepper(public.cs_contact_digest(public.cs_normalise_email(p.email))) as h
         union all
         select public.cs_pepper(public.cs_contact_digest(public.cs_normalise_phone(
                  (select u.phone from auth.users u where u.id = p.id))))
       ) x
      where h is not null)
 where p.contact_hash is null;

-- ---------------------------------------------------------------------------
-- 5 · match_contacts — the whole surface, and it answers about nothing else
-- ---------------------------------------------------------------------------
create or replace function public.match_contacts(p_hashes text[])
returns table (
  id uuid, handle text, display_name text, city text, home_course text,
  marker text, index_current numeric, rel text
)
language sql
stable
security definer
set search_path = public
as $fn$
  with me as (select auth.uid() as pid),
  asked as (
    -- the caller's own digests, peppered here. A cap, because a contact book is
    -- a few hundred rows and anything larger is not a contact book.
    select distinct cs_pepper(lower(h)) as h
      from unnest(coalesce(p_hashes, '{}'::text[])) with ordinality as t(h, ord)
     where ord <= 1000
  )
  select pr.id, pr.handle, pr.display_name, pr.city, pr.home_course, pr.marker,
         pr.index_current,
         case when f.status = 'accepted' then 'friend'
              when exists (select 1 from league_members a
                             join league_members b on b.league_id = a.league_id
                            where a.profile_id = pr.id and b.profile_id = (select pid from me))
                   then 'league'
              else 'contact' end
    from profiles pr
    left join friendships f
      on least(f.requester, f.addressee)    = least(pr.id, (select pid from me))
     and greatest(f.requester, f.addressee) = greatest(pr.id, (select pid from me))
   where pr.contact_hash && (select coalesce(array_agg(h), '{}'::text[]) from asked where h is not null)
     and pr.id <> (select pid from me)
     and pr.deleted_at is null
     -- L-37 / D150 · the same gate search_golfers and recent_partners apply.
     -- A golfer who has hidden themselves is hidden from their own address book.
     and (pr.discoverable = 'everyone'
          or (pr.discoverable = 'friends' and f.status = 'accepted'))
   order by pr.display_name
   limit 50;
$fn$;

revoke all on function public.match_contacts(text[]) from public, anon;
grant execute on function public.match_contacts(text[]) to authenticated;

-- ---------------------------------------------------------------------------
-- self-check (L-05 · read-only; the digest cases below touch no row)
-- ---------------------------------------------------------------------------
do $chk$
declare v_src text; v_a text; v_b text;
begin
  -- the normalisation the two clients mirror
  if cs_normalise_email('  Jerecho@Example.COM ') <> 'jerecho@example.com' then
    raise exception 'C-11: email normalisation drifted from the clients';
  end if;
  if cs_normalise_phone('(480) 555-0134') <> '+14805550134' then
    raise exception 'C-11: phone normalisation drifted from the clients';
  end if;
  if cs_normalise_phone('+44 20 7946 0958') <> '+442079460958' then
    raise exception 'C-11: an international number lost its country code';
  end if;
  if cs_normalise_phone('555-0134') is not null then
    raise exception 'C-11: a seven-digit fragment is not a phone number';
  end if;

  -- the client's half is UNSALTED — this is the known SHA-256 of "abc", and it
  -- is the same vector ContactHashTests asserts. If a salt ever crept into the
  -- client's half, this fails and so does the phone.
  if cs_contact_digest('abc') <> 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' then
    raise exception 'C-11: the client-side digest is not plain SHA-256';
  end if;

  -- and the server's half is NOT the client's half
  v_a := cs_contact_digest('jerecho@example.com');
  v_b := cs_pepper(v_a);
  if v_b is null or v_b = v_a then
    raise exception 'C-11: the pepper is not being applied — the column would hold what the wire carries';
  end if;
  if cs_pepper('not-a-digest') is not null then
    raise exception 'C-11: cs_pepper accepted something that is not a digest';
  end if;

  -- the envelope
  select prosrc into v_src from pg_proc
   where proname = 'match_contacts' and pronamespace = 'public'::regnamespace;
  if v_src is null then raise exception 'C-11: match_contacts is missing'; end if;
  if position('discoverable' in v_src) = 0 then
    raise exception 'D251: match_contacts lost L-37''s gate — a hidden golfer would be named';
  end if;
  if position('cs_pepper' in v_src) = 0 then
    raise exception 'D251: match_contacts compares an unpeppered digest';
  end if;

  -- grants
  if has_function_privilege('anon', 'public.match_contacts(text[])', 'execute') then
    raise exception 'D37/L-04: match_contacts is authenticated-only';
  end if;
  if not has_function_privilege('authenticated', 'public.match_contacts(text[])', 'execute') then
    raise exception 'L-04: match_contacts has no grant';
  end if;
  if has_function_privilege('authenticated', 'public.cs_pepper(text)', 'execute') then
    raise exception 'C-11: a client can reach the pepper';
  end if;
  -- C-13 · the three transforms and the trigger are revoked from anon too
  if has_function_privilege('anon', 'public.cs_normalise_email(text)', 'execute')
     or has_function_privilege('anon', 'public.cs_normalise_phone(text)', 'execute')
     or has_function_privilege('anon', 'public.cs_contact_digest(text)', 'execute')
     or has_function_privilege('anon', 'public.profile_refresh_contact_hash()', 'execute') then
    raise exception 'L-04: a new function kept PostgreSQL''s implicit EXECUTE TO PUBLIC';
  end if;
  if has_table_privilege('authenticated', 'public.contact_pepper', 'select') then
    raise exception 'C-11: the salt is readable — it is server-side or it is nothing';
  end if;
  -- clause 3: the column stays unreadable
  if has_column_privilege('authenticated', 'public.profiles', 'contact_hash', 'select') then
    raise exception 'C-11: contact_hash is selectable — every golfer could match everyone offline';
  end if;
end $chk$;
