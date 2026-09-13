-- handicap_index_asof(p_profile uuid, p_before_date date, p_before_id uuid) oid=19590
CREATE OR REPLACE FUNCTION public.handicap_index_asof(p_profile uuid, p_before_date date, p_before_id uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with d as (
    select r.differential
      from rounds r
     where r.profile_id = p_profile and not r.voided
       and coalesce(r.source,'app') <> 'sim' and r.differential is not null
       and (p_before_date is null or (r.played_on, r.id) < (p_before_date, p_before_id))
     order by r.played_on desc, r.id desc
     limit 20
  ),
  cnt as (select count(*)::int c from d),
  params as (
    select c,
      case when c<3 then 0 when c<=5 then 1 when c<=8 then 2 when c<=11 then 3
           when c<=14 then 4 when c<=16 then 5 when c=17 then 6 when c=18 then 7
           else 8 end as m,
      case when c=3 then 2.0 when c=4 then 1.0 when c=6 then 1.0
           when c in (9,10,11) then 1.0 else 0 end as adj
      from cnt
  ),
  best as (
    select differential, row_number() over (order by differential asc) rn from d
  )
  select case when (select c from cnt) < 3 then null
    else round(avg(differential) filter (where rn <= (select m from params))
               - (select adj from params), 1) end
    from best;
$function$

