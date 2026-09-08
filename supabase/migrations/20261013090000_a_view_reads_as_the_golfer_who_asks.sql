-- v_rounds_ranked reads as the golfer who asks, not as its owner.
-- 20260914090000 re-created this view with `create or replace view`, which
-- silently discards reloptions, and stripped security_invoker for the second
-- time — the first was D197, fixed by 20260902140000. Restore it, and leave a
-- check behind so a third time raises here instead of leaking quietly.
-- Safe: rounds_read is `own OR shares a league`, and every reader of this view
-- (index.html:23981, :24024, :26594) is already scoped to their own season or
-- their own id.
begin;

alter view public.v_rounds_ranked set (security_invoker = true);

do $chk$
begin
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'v_rounds_ranked'
      and 'security_invoker=true' = any (c.reloptions)
  ) then
    raise exception 'v_rounds_ranked is not invoker-mode — every golfer can read every round';
  end if;
end $chk$;

commit;
