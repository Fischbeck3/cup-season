-- post_round_once(p_request_id uuid, p_payload jsonb, p_hole_scores integer[], p_played_with uuid[]) oid=35648
CREATE OR REPLACE FUNCTION public.post_round_once(p_request_id uuid, p_payload jsonb, p_hole_scores integer[], p_played_with uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_owner uuid := auth.uid();
  v_envelope jsonb;
  v_previous cupseason_private.round_post_receipts%rowtype;
  v_response jsonb;
  v_round uuid;
  v_holes integer;
  v_total integer;
begin
  if v_owner is null then raise exception 'Sign in first'; end if;
  if p_request_id is null or p_payload is null or jsonb_typeof(p_payload) <> 'object'
     or pg_column_size(p_payload) > 16384 then raise exception 'Invalid round request'; end if;
  if p_payload->>'played_on' is null then raise exception 'Played date is required'; end if;
  v_holes := (p_payload->>'holes_played')::integer;
  if v_holes is null or v_holes not in (9,18) then raise exception 'Choose 9 or 18 holes'; end if;
  v_envelope := jsonb_build_object('round', p_payload, 'holes', coalesce(p_hole_scores,'{}'::integer[]),
                                  'played_with', coalesce(p_played_with,'{}'::uuid[]));
  -- Serialize same-account/request races before either invokes post_round.
  perform pg_advisory_xact_lock(hashtextextended(v_owner::text || ':' || p_request_id::text, 0));
  select * into v_previous from cupseason_private.round_post_receipts
    where owner_id = v_owner and request_id = p_request_id;
  if found then
    if v_previous.payload <> v_envelope then raise exception 'This request already has a different scorecard'; end if;
    return v_previous.response;
  end if;
  if cardinality(p_hole_scores) > 0 then
    if array_ndims(p_hole_scores) <> 1 or cardinality(p_hole_scores) <> v_holes
       or exists(select 1 from unnest(p_hole_scores) s where s is null or s < 1 or s > 15)
    then raise exception 'Complete the hole scores before posting'; end if;
    select sum(s) into v_total from unnest(p_hole_scores) s;
    if v_total is distinct from (p_payload->>'gross')::integer then raise exception 'Hole scores do not match gross'; end if;
  end if;
  v_response := public.post_round(
    p_gross := (p_payload->>'gross')::integer, p_rating := (p_payload->>'rating')::numeric,
    p_slope := (p_payload->>'slope')::integer, p_holes_played := v_holes,
    p_nine_rating := (p_payload->>'nine_rating')::numeric, p_course_id := p_payload->>'api_course_id',
    p_course_label := p_payload->>'course_label', p_played_on := (p_payload->>'played_on')::date,
    p_photo_path := p_payload->>'photo_path', p_played_with := coalesce(p_played_with,'{}'::uuid[]));
  v_round := (v_response->'round'->>'id')::uuid;
  if v_round is null then raise exception 'Round acceptance returned no identifier'; end if;
  insert into public.round_holes(round_id, hole_number, strokes)
    select v_round, ordinality::integer, score
      from unnest(coalesce(p_hole_scores,'{}'::integer[])) with ordinality h(score, ordinality);
  insert into cupseason_private.round_post_receipts(owner_id, request_id, payload, response)
    values (v_owner, p_request_id, v_envelope, v_response);
  return v_response;
end;
$function$

