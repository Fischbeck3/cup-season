-- D194 (amended) · the reviewer address cannot receive mail either.
--
-- D194 stopped five hard bounces armed for 2026-09-08 07:20 UTC by teaching
-- `is_undeliverable()` about RFC 2606 reserved TLDs, which covered the five
-- `seed+botN@cupseason.test` bots. A sweep on 2026-09-04 found the count was
-- cut to one, not to zero. The survivor is `reviewer@cupseason.app`.
--
-- It bounces for the same reason the bots do — nothing can receive mail there:
--
--   dig MX cupseason.app  -> no MX record at all (DNS is Netlify/nsone)
--   implicit MX therefore falls back to the A records, 52.52.192.191 /
--   13.52.188.95, which are Netlify's web front end
--   nc -z 52.52.192.191 25 -> refused; no SMTP listener exists
--
-- (Verified 2026-09-04. The only mail-ish TXT on the domain is Brevo's
-- verification code; there is no SPF record — a separate, still-open item.)
--
-- The trigger: season cd194498 (TSTSUN "Sunset Match") is status=cup_final,
-- ends_on 2026-09-05, grace_hours 48, so `close_season` fires on the first
-- daily tick past 2026-09-08 07:00 UTC — the 07:20 tick. `leagues.sandbox` is
-- false for it, and `season_email_on_complete` only skips sandbox leagues, so
-- the row reaches email_queue, the AFTER INSERT trigger posts to the
-- season-email function, and Brevo takes a hard bounce against the sending
-- reputation of the only domain this product sends from.
--
-- This does NOT touch how the reviewer signs in. App Review does not use the
-- emailed code: `reviewer@cupseason.app` is the one address the door answers
-- with a password field (DoorView.swift:4, `passwordStage`), which is exactly
-- why an address with no mailbox has been workable up to now. is_undeliverable
-- is read by product mail only — `season_email_payload` and
-- `cancel_league_now` — never by auth.
--
-- Named, not pattern-matched: the honest general rule is "the domain has no
-- MX", and a migration cannot see DNS. If cupseason.app is ever given a
-- mailbox, delete this one clause and the bots stay covered.

create or replace function public.is_undeliverable(p_email text)
returns boolean
language sql
immutable
set search_path to 'public'
as $fn$
  select p_email is null
      or btrim(p_email) = ''
      or lower(btrim(p_email)) ~ '\.(test|example|invalid|localhost)$'
      or lower(btrim(p_email)) = 'reviewer@cupseason.app';
$fn$;

-- D37 · re-assert the posture rather than trusting what `replace` preserved.
revoke all on function public.is_undeliverable(text) from public, anon;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_left int;
begin
  if not public.is_undeliverable('reviewer@cupseason.app') then
    raise exception 'is_undeliverable: the reviewer address is still deliverable — the Sep 8 bounce is still armed';
  end if;
  if not public.is_undeliverable('seed+bot0@cupseason.test') then
    raise exception 'is_undeliverable: D194''s reserved-TLD rule was lost in the rewrite';
  end if;
  if public.is_undeliverable('jerechofischbeck@gmail.com') then
    raise exception 'is_undeliverable: a real address is being treated as undeliverable — this would silence live mail';
  end if;

  select count(*) into v_left
    from public.league_members lm
    join public.profiles p on p.id = lm.profile_id
    join public.leagues l on l.id = lm.league_id
   where l.code = 'TSTSUN'
     and not public.is_undeliverable(p.email);
  raise notice 'TSTSUN deliverable recipients remaining: %', v_left;
end $chk$;
