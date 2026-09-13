-- score_round(p_gross integer, p_rating numeric, p_slope integer, p_nine_rating numeric, p_index numeric, p_allowance integer, p_holes integer) oid=17871
CREATE OR REPLACE FUNCTION public.score_round(p_gross integer, p_rating numeric, p_slope integer, p_nine_rating numeric, p_index numeric, p_allowance integer, p_holes integer)
 RETURNS TABLE(o_diff numeric, o_pvi numeric, o_points integer)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare v_diff numeric; v_pvi numeric; v_pts int;
begin
  if p_holes = 9 then
    v_diff := ((p_gross - coalesce(p_nine_rating, p_rating/2)) * 113.0 / p_slope) * 2;
  else
    v_diff := (p_gross - p_rating) * 113.0 / p_slope;
  end if;
  v_pvi := (p_index * p_allowance / 100.0) - v_diff;
  v_pts := case
    when v_pvi >= 3  then 12
    when v_pvi >= 1  then 9
    when v_pvi >= -1 then 7
    when v_pvi >= -3 then 6
    else 5 end;
  if p_holes = 9 then v_pts := ceil(v_pts / 2.0); end if;
  return query select round(v_diff,1), round(v_pvi,1), v_pts;
end $function$

