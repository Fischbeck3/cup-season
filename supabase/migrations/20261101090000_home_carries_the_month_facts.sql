-- D354 (amended) · Home carries the two month facts too.
--
-- `league_pulse` says `joined_this_month` and `bye_available` since
-- 20261030090000, but `native_home` builds the membership's `pulse` object by
-- naming four keys, so the Home month row could still show a mid-month joiner
-- a minimum `close_month` will waive. The season page said the truth and Home
-- did not; one screen contradicting another is exactly L-32's forbidden shape.
--
-- `native_home` is a 40 KB function that depends on the whole schema, so it is
-- patched the way D161 patched `close_month` (20260830300000): the live body is
-- read back from the catalogue, ONE unique substring — the four-key pulse
-- object — is replaced with the six-key one, and the result is executed. The
-- patch RAISES if the substring is absent or appears more than once, so a body
-- that has moved cannot be half-patched, and it raises if the executed body
-- does not carry the new keys. Nothing else in the function changes. Grants
-- survive a `create or replace` (which is what `pg_get_functiondef` emits) and
-- are restated anyway.
--
-- Old client: reads the four keys it knows and ignores the rest. Old server
-- (this patch not applied): the client decodes nil for both and claims neither.
-- Not deployed by this change.

do $patch$
declare v_def text; v_n int;
begin
  select pg_get_functiondef(oid) into v_def from pg_proc
   where proname = 'native_home' and pronamespace = 'public'::regnamespace;
  if v_def is null then raise exception 'D354: native_home is missing'; end if;

  -- exactly one four-key pulse object to patch
  select (length(v_def) - length(replace(v_def, $old$'partial',  lp.partial)$old$, ''))) / length($old$'partial',  lp.partial)$old$) into v_n;
  if v_n <> 1 then
    raise exception 'D354: expected exactly one pulse object in native_home, found % — the live body moved', v_n;
  end if;

  v_def := replace(v_def,
    $old$'partial',  lp.partial)$old$,
    $new$'partial',  lp.partial,
          -- D354 · the same two facts the season page reads, off the same row
          'joined_this_month', lp.joined_this_month,
          'bye_available', lp.bye_available)$new$);

  execute v_def;

  select count(*) into v_n from pg_proc
   where proname = 'native_home' and pronamespace = 'public'::regnamespace
     and prosrc like '%''joined_this_month'', lp.joined_this_month%'
     and prosrc like '%''bye_available'', lp.bye_available%';
  if v_n <> 1 then raise exception 'D354: native_home does not carry the month facts after the patch'; end if;
end $patch$;

revoke all on function public.native_home() from public, anon;
grant execute on function public.native_home() to authenticated;

do $check$
begin
  if has_function_privilege('anon', 'public.native_home()', 'execute') then
    raise exception 'D354: anon must not execute native_home';
  end if;
  if not has_function_privilege('authenticated', 'public.native_home()', 'execute') then
    raise exception 'D354: authenticated must execute native_home';
  end if;
end $check$;
