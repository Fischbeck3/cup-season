-- confirm_round_partner(p_round uuid, p_confirm boolean) oid=34916
CREATE OR REPLACE FUNCTION public.confirm_round_partner(p_round uuid, p_confirm boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_found boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_round is null then raise exception 'Which round?'; end if;

  select true into v_found from round_players
   where round_id = p_round and profile_id = v;

  if not coalesce(v_found, false) then
    -- not an error worth a red screen: the tag may already have been answered
    -- and cleared. The honest answer is the state, not an exception.
    return jsonb_build_object('state', 'none');
  end if;

  if coalesce(p_confirm, true) then
    update round_players set confirmed_at = coalesce(confirmed_at, now())
     where round_id = p_round and profile_id = v;
    return jsonb_build_object('state', 'confirmed');
  else
    -- "I wasn't there" leaves no trace of the claim that they were
    delete from round_players where round_id = p_round and profile_id = v;
    return jsonb_build_object('state', 'removed');
  end if;
end $function$

