-- D159 · a handle you give up is not given away.
--
-- `set_handle` already enforced format, a reserved-word list, uniqueness, a
-- 60-day cooldown and a system post to every league. What it did not do is the
-- thing the cooldown cannot: the moment you move off `@jerecho`, that name is
-- free and anyone may take it. A cooldown slows the GOLFER down, not the person
-- taking the name they left — and here the handle is how buddies find each
-- other (D118) and how a golfer is named in a money game.
--
-- So: one row per abandoned handle, and the handle is the key. A released name
-- is held permanently rather than recycled — at this scale the storage is
-- nothing, and "your old name can never become someone else" is a promise that
-- needs no clock to explain. Reclaiming your OWN old handle is always allowed;
-- it was yours.
--
-- Body of set_handle = the LIVE definition, verbatim, with the reservation
-- checks added. CLAUDE.md: never edit a migration that has run.

create table if not exists public.handle_history (
  handle      text primary key,
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  released_at timestamptz not null default now()
);

comment on table public.handle_history is
  'D159 · handles their owner has moved off. The handle is the primary key, so a '
  'released name is permanently reserved and set_handle refuses it to anyone '
  'else. The owner may always reclaim their own, which deletes the row.';

create index if not exists handle_history_profile_idx
  on public.handle_history (profile_id, released_at desc);

alter table public.handle_history enable row level security;
-- No policies, by design: this is read through SECURITY DEFINER functions only.
-- D37 — authenticated holds no relation privileges here.
revoke all on table public.handle_history from public, anon, authenticated;

-- ---- set_handle: refuse someone else's old name, allow reclaiming your own --
create or replace function public.set_handle(p_handle text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v      text := lower(trim(both from replace(p_handle, '@', '')));
  v_old  text; v_set timestamptz; v_name text;
  v_held uuid;
begin
  -- D159 · a signed-out caller must not reach the guards below, because every
  -- one of them compares against auth.uid() and a NULL comparison is NULL, not
  -- true — the reservation check would silently pass. Caught by a behavioural
  -- test where the probe account resolved to null.
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if v !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'Handles are 3–20 characters: letters, numbers, underscores';
  end if;
  if v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then
    raise exception 'That handle is reserved';
  end if;

  select handle, handle_set_at, display_name into v_old, v_set, v_name
    from profiles where id = auth.uid();
  if v_old is not distinct from v then return; end if;   -- no actual change

  -- D159 · a name someone else gave up is not available. Checked BEFORE the
  -- cooldown so a golfer is told the real reason rather than being made to wait
  -- sixty days for a handle they were never going to get.
  select profile_id into v_held from handle_history where handle = v;
  if v_held is not null and v_held is distinct from auth.uid() then
    raise exception 'That handle belonged to another golfer';
  end if;

  -- cooldown applies only to a genuine change of an existing handle
  if v_old is not null and v_set is not null and v_set > now() - interval '60 days' then
    raise exception 'Your @handle can change once every 60 days — next change on %',
      to_char(v_set + interval '60 days', 'Mon DD');
  end if;

  begin
    update profiles set handle = v, handle_set_at = now() where id = auth.uid();
  exception when unique_violation then
    raise exception 'That handle is taken';
  end;

  -- D159 · the name being left behind is held, and a name being RECLAIMED stops
  -- being held. Both in the same breath as the change itself.
  if v_old is not null then
    insert into handle_history (handle, profile_id) values (v_old, auth.uid())
    on conflict (handle) do update set profile_id = excluded.profile_id,
                                       released_at = excluded.released_at;
  end if;
  delete from handle_history where handle = v and profile_id = auth.uid();

  -- announce a re-handle (first claim stays silent)
  if v_old is not null then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(coalesce(v_name, 'A member')) || ' IS NOW @' || v
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $function$;

revoke all on function public.set_handle(text) from public, anon;
grant execute on function public.set_handle(text) to authenticated;

-- ---- handle_available: the live check the card already makes ---------------
-- The card checks a handle as it is typed. It must now answer "held by someone
-- else" too, or the golfer types a green-ticked name and is refused on save.
-- Body = the LIVE definition with ONE clause added; the auth.uid() null guard
-- and the lower(p.handle) comparison are its, not mine.
create or replace function public.handle_available(p_handle text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $fn$
  with n as (
    select lower(trim(both from replace(coalesce(p_handle, ''), '@', ''))) as v
  )
  select case
    when auth.uid() is null then false
    when n.v !~ '^[a-z0-9_]{3,20}$' then false
    when n.v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then false
    else not exists (
      select 1 from profiles p
       where lower(p.handle) = n.v
         and p.id <> auth.uid())
      -- D159 · and not held by someone who moved off it. Your own old handle
      -- stays available to you, so reclaiming it still ticks green.
      and not exists (
      select 1 from handle_history h
       where h.handle = n.v
         and h.profile_id <> auth.uid())
  end
  from n;
$fn$;

revoke all on function public.handle_available(text) from public, anon;
grant execute on function public.handle_available(text) to authenticated;

-- ---- the owner's own correction ---------------------------------------------
-- Requested directly: jerechofischbeck → jerecho. `set_handle` would refuse it
-- (handle_set_at 2026-07-22, inside the 60-day window), so it is done here —
-- guarded, idempotent, and writing the history row so the old handle is held
-- exactly as any other would be. A prod data change rides a migration rather
-- than a console so a human pushes it and it lands in the record.
do $fix$
declare v_id uuid;
begin
  select id into v_id from profiles where handle = 'jerechofischbeck';
  if v_id is null then
    raise notice 'D159: jerechofischbeck not present — already renamed, nothing to do';
    return;
  end if;
  if exists (select 1 from profiles where handle = 'jerecho') then
    raise notice 'D159: jerecho is taken — owner rename skipped, handled by hand';
    return;
  end if;
  update profiles set handle = 'jerecho', handle_set_at = now() where id = v_id;
  insert into handle_history (handle, profile_id) values ('jerechofischbeck', v_id)
  on conflict (handle) do nothing;
  -- no league announcement: this is a correction of a derived handle, not a
  -- golfer changing their name on the group
end $fix$;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname = 'set_handle' and pronamespace = 'public'::regnamespace;

  if position('handle_history' in v_src) = 0 then
    raise exception 'D159: set_handle no longer reserves an abandoned handle';
  end if;
  if position('belonged to another golfer' in v_src) = 0 then
    raise exception 'D159: set_handle would hand out someone else''s old name';
  end if;
  -- everything set_handle did before must still be there
  if position('60 days' in v_src) = 0 or position('IS NOW @' in v_src) = 0
     or position('That handle is taken' in v_src) = 0 then
    raise exception 'D159: built on the wrong body — a rule is missing';
  end if;

  if has_function_privilege('anon', 'public.set_handle(text)', 'execute')
     or has_function_privilege('anon', 'public.handle_available(text)', 'execute') then
    raise exception 'D37: these are authenticated-only';
  end if;
  if has_table_privilege('authenticated', 'public.handle_history', 'select') then
    raise exception 'D37: handle_history is read through definers only';
  end if;
end $chk$;
