-- scratch_round(p_id uuid) oid=18879
CREATE OR REPLACE FUNCTION public.scratch_round(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  delete from scheduled_rounds where id = p_id and profile_id = auth.uid();
end $function$

