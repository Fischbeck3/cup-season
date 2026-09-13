-- D350 (BUILT 2026-09-13) · a post can be asked about without being made.
--
-- `post_round_once` (20261021090000) answers "post this, once" and keeps a
-- receipt per (owner, request). What neither client could do was ask "did my
-- earlier request land?" WITHOUT sending it again — and that question is the
-- only honest way out of the one state D350 refused to paper over: a request
-- whose response was lost, followed by a golfer who then EDITED the card. A
-- replay would post the old card; a fresh id would risk two rounds. Reading
-- the receipt decides it: landed → the old form is finished and the edited
-- card is a new round; not landed → the old id is released and the edited
-- card posts under a new one.
--
-- Read-only. Returns the stored response verbatim, or null. The owner is
-- `auth.uid()` and never an argument, so one golfer cannot read another's
-- receipts. Execute to `authenticated` only. Not deployed by this change.

create or replace function public.round_post_status(p_request_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select r.response
    from cupseason_private.round_post_receipts r
   where r.owner_id = auth.uid()
     and r.request_id = p_request_id
   limit 1
$$;

revoke all on function public.round_post_status(uuid) from public, anon;
grant execute on function public.round_post_status(uuid) to authenticated;

-- Read-only self-check. Raises rather than reporting success.
do $check$
declare n int;
begin
  select count(*) into n from pg_proc
   where proname = 'round_post_status' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'round_post_status must resolve to exactly one function, found %', n; end if;

  select count(*) into n from pg_proc
   where proname = 'post_round_once' and pronamespace = 'public'::regnamespace;
  if n <> 1 then raise exception 'post_round_once must exist before it can be asked about, found %', n; end if;

  if has_function_privilege('anon', 'public.round_post_status(uuid)', 'execute') then
    raise exception 'anon must not execute round_post_status';
  end if;
  if not has_function_privilege('authenticated', 'public.round_post_status(uuid)', 'execute') then
    raise exception 'authenticated must execute round_post_status';
  end if;
  -- the receipt table stays private: the function is the only reader
  if has_table_privilege('authenticated', 'cupseason_private.round_post_receipts', 'SELECT') then
    raise exception 'round_post_receipts must not be readable by authenticated';
  end if;
end $check$;
