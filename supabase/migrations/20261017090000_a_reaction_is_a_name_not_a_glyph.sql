-- Cup Season — A REACTION IS A NAME, NOT A GLYPH (D309).
--
-- The six emoji retire and four drawn tokens take their place: `azalea`
-- (flowers) · `jug` (cheers) · `eagle` (the eagle) · `rake` (sandbagger). Two
-- of the four were already drawn — the Azalea and the Jug are markers #9 and
-- #10 of the fourteen — and the set stops at four on purpose: it covers praise,
-- celebration, the number and the accusation, and covers neither momentum nor
-- a pure jab. Four right beats six with two nobody chose.
--
-- ── THE COLUMN KEEPS ITS NAME, AND THAT IS DELIBERATE ────────────────────────
-- `post_kudos.emoji` now holds a NAME. Renaming it to `token` would be more
-- honest and it is NOT done, because the rename would make an older installed
-- build's write FAIL outright (it names `emoji` in the insert), where leaving
-- the column makes that build write a token nobody recognises — which the
-- clients drop rather than draw. **Degraded beats broken during a deploy
-- window.** `char_length(emoji) <= 8` already admits every new key.
--
-- ── WHAT HAPPENS TO THE HISTORY, STATED ─────────────────────────────────────
-- Six rows exist in production and that is the entire history of the feature:
-- five `🔥` and one `⛳`. They fold to `azalea`. Five of the six were heaters
-- and the azalea takes the heater's seat as the one-thumb token, so it is the
-- same gesture — but this DOES rewrite six rows, and the entry says so rather
-- than calling it a migration of format.
--
-- ── THE COLLISION THIS COULD HAVE HAD ───────────────────────────────────────
-- `emoji` is part of the primary key `(post_id, profile_id, emoji)`, so folding
-- two rows by one person on one post onto one key would violate it. A check ran
-- against production before this was written and found none. **The fold does
-- not depend on that**: it deletes the losers first, keeping the oldest row per
-- (post, person), so the migration is correct on a database where the check
-- would have failed — which is every database that is not the one I looked at.

begin;

-- 1 · drop the duplicates a fold would collide on, oldest kept. On production
--     this deletes nothing; on any other database it is the difference between
--     a migration and an outage.
with ranked as (
  select ctid,
         row_number() over (
           partition by post_id, coalesce(profile_id::text, 'm:' || member_id::text)
           order by created_at asc nulls last, ctid asc
         ) as seat
    from public.post_kudos
   where emoji is null or emoji not in ('azalea', 'jug', 'eagle', 'rake')
)
delete from public.post_kudos k
 using ranked r
 where k.ctid = r.ctid and r.seat > 1;

-- 2 · every surviving legacy row becomes the quick token.
update public.post_kudos
   set emoji = 'azalea'
 where emoji is null or emoji not in ('azalea', 'jug', 'eagle', 'rake');

-- 3 · the column default stamped '🔥' — the glyph that no longer exists. It is
--     the value a write with no emoji lands on, which is exactly the trap the
--     D25 correction recorded: a skew fallback retried without `emoji` and the
--     default silently turned a 🦅 into a 🔥. The default must be a real token.
alter table public.post_kudos alter column emoji set default 'azalea';

-- ── self-check ──────────────────────────────────────────────────────────────
-- Every predicate below names a string that EXISTS. Six of these were written
-- once quoting substrings that were never in the object they tested, and passed
-- vacuously; each one here was simulated against the live definition first.
do $$
declare v_bad int; v_default text;
begin
  select count(*) into v_bad
    from public.post_kudos
   where emoji is null or emoji not in ('azalea', 'jug', 'eagle', 'rake');
  if v_bad > 0 then
    raise exception '[D309] % reaction row(s) still carry a retired key', v_bad;
  end if;

  select pg_get_expr(d.adbin, d.adrelid) into v_default
    from pg_attrdef d
    join pg_attribute a on a.attrelid = d.adrelid and a.attnum = d.adnum
   where d.adrelid = 'public.post_kudos'::regclass and a.attname = 'emoji';
  if v_default is null or v_default not like '%azalea%' then
    raise exception '[D309] post_kudos.emoji default is % — a write with no token would stamp a retired glyph', coalesce(v_default, 'NULL');
  end if;

  -- the fold must not have broken the key it was folding onto
  if exists (
    select 1 from public.post_kudos
     group by post_id, coalesce(profile_id::text, 'm:' || member_id::text), emoji
    having count(*) > 1
  ) then
    raise exception '[D309] the fold produced a duplicate (post, person, token)';
  end if;
end $$;

commit;
