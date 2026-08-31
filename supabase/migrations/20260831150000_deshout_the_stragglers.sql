-- D174 · the six posts that beat the de-shouting by a few hours.
--
-- `open_week_clash` ran on the cron at 07:20Z on 2026-08-30 and wrote six
-- "THIS WEEK: X v Y — THE CLASH" lines. D165 de-shouted the generator later the
-- same day, so no NEW post shouts — but these six are already on the board, two
-- of them in the owner's real leagues, and the weekly idempotency guard pins
-- them at the top for about a week.
--
-- `easeCaps()` on the client cannot rescue them: it guards on
-- `s === s.toUpperCase()`, and the interpolated lowercase " v " breaks that
-- equality, so the whole line ships raw. That is the same reason D165 moved the
-- casing to the generator in the first place.
--
-- This is a one-time repair of rows already written. It is narrow by
-- construction: only 'system' posts, only the clash shape, only ones written
-- before D165 landed. It does not touch any other post, and it is idempotent —
-- re-running it matches nothing.

update public.posts
   set body = 'This week: ' || initcap(lower(substring(body from 'THIS WEEK: (.+) v ')))
              || ' v ' || initcap(lower(substring(body from ' v (.+) — THE CLASH')))
              || '.'
 where kind = 'system'
   and body like 'THIS WEEK: % v % — THE CLASH'
   and created_at < timestamptz '2026-08-31 00:00:00+00';

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare n int;
begin
  select count(*) into n from posts
   where kind = 'system' and body like 'THIS WEEK:%THE CLASH';
  if n > 0 then
    raise exception 'D174: % shouted clash post(s) survived the backfill', n;
  end if;

  -- and the repair must have produced readable sentences, not empty scaffolding
  select count(*) into n from posts
   where body like 'This week: % v %.' and body !~ 'This week:  v ';
  if n = 0 then
    raise notice 'D174: no clash posts to repair — nothing to do';
  end if;
end $chk$;
