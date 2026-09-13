-- round_refresh_index() oid=19592
CREATE OR REPLACE FUNCTION public.round_refresh_index()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_auto numeric; v_old numeric; v_src text; v_name text;
        v_pid uuid; v_voided boolean;
begin
  -- Y-19 · INSERT reads NEW, DELETE reads OLD; the return value of an AFTER
  -- row trigger is ignored either way.
  if tg_op = 'DELETE' then
    v_pid := old.profile_id; v_voided := old.voided;
  else
    v_pid := new.profile_id; v_voided := new.voided;
  end if;
  if v_voided then return null; end if;
  v_auto := handicap_index(v_pid);                   -- non-null once >= 3 rounds
  if v_auto is null then return null; end if;

  select index_current, index_source, display_name
    into v_old, v_src, v_name from profiles where id = v_pid;

  update profiles set index_current = v_auto, index_source = 'app'
   where id = v_pid;                                  -- scores are the truth

  -- announce ONLY the handoff: scores taking over a manual starter, and only
  -- when the number actually moves. Routine per-round updates stay silent.
  if coalesce(v_src, 'app') in ('self', 'ghin') and v_old is distinct from v_auto then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           coalesce(v_name, 'A golfer') || '''s number now comes from their scores — '
             || coalesce(v_old::text, 'starter') || ' → ' || v_auto
      from league_members lm where lm.profile_id = v_pid;
  end if;
  return null;
end $function$

