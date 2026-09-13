-- delete_round(p_round uuid) oid=19471
CREATE OR REPLACE FUNCTION public.delete_round(p_round uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_path text;
begin
  select photo_path into v_path from rounds
   where id = p_round and profile_id = auth.uid();

  delete from rounds where id = p_round and profile_id = auth.uid();
  if not found then raise exception 'not your round to delete'; end if;

  if v_path is not null and v_path <> '' then
  -- D303 · **THE PLATFORM FORBIDS THIS AND THE STATEMENT USED TO KILL THE
  -- WHOLE CALL.** `delete from storage.objects` raises
  -- `42501 Direct deletion from storage tables is not allowed. Use the
  -- Storage API instead.`, so this function raised instead of doing its job.
  -- The reference is the load-bearing half and it survives; the object is
  -- reclaimed by the caller through the Storage API, or left as an orphan.
  begin
  delete from storage.objects where bucket_id = 'media' and name = v_path;
  exception when others then
    null;   -- an orphan is a cost; a function that cannot run is a defect
  end;

  end if;
end $function$

