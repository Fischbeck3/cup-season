-- Founder badge. Marks the founder's profile, keyed to their EMAIL so it
-- auto-applies the moment they sign in fresh (survives wipes) — no manual step.
-- One founder today; the trigger just matches an address.

alter table public.profiles add column if not exists is_founder boolean not null default false;

-- apply now if the row already exists
update public.profiles set is_founder = true
  where lower(email) = 'jerecho@fischbeck3.com' and is_founder = false;

-- and auto-apply on the m001 signup insert (email is set there) or any email change
create or replace function public.tag_founder() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if lower(coalesce(new.email, '')) = 'jerecho@fischbeck3.com' then
    new.is_founder := true;
  end if;
  return new;
end $$;

drop trigger if exists trg_tag_founder on public.profiles;
create trigger trg_tag_founder before insert or update of email on public.profiles
  for each row execute function public.tag_founder();

-- the client badges any name whose profile id matches this (no PII returned)
create or replace function public.founder_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from public.profiles where is_founder limit 1;
$$;
grant execute on function public.founder_id() to anon, authenticated;
