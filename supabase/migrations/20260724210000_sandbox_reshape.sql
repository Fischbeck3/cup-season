-- ============================================================================
-- Cup Season — D65 follow-up: the length dial (sandbox_reshape)
--
-- sandbox_rewind SLIDES a season, preserving its length. That is the right
-- default, but it cannot rehearse the machinery that only whole calendar
-- months trigger: participation floors, the auto-bye that forgives the first
-- miss, and the deduction that lands on the second. A 6-week season slid far
-- enough to contain a whole month also lands its end date past the grace
-- window — the season crowns itself before a floor is ever assessed.
--
-- reshape sets BOTH ends: starts_on = today − p_back weeks, and the season
-- runs p_long weeks from there. Whole months inside the window then close as
-- FULL months (floors live) instead of partial ones (floors waived, §14.0).
--
-- Sandbox-only, founder-only, same gate as the rest of the D65 family. The
-- guard rails are deliberate: 1..52 weeks back, 2..52 weeks long — enough to
-- reach any rehearsal shape, not enough to fat-finger a season into 1970.
-- ============================================================================

create or replace function public.sandbox_reshape(
  p_league uuid, p_back integer, p_long integer)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare se seasons%rowtype; v_start date; v_end date; v_whole text[];
        m date;
begin
  perform assert_sandbox(p_league, true);
  if p_back < 1 or p_back > 52 then raise exception 'back: 1 to 52 weeks'; end if;
  if p_long < 2 or p_long > 52 then raise exception 'long: 2 to 52 weeks'; end if;

  select * into se from seasons where league_id = p_league
   order by number desc limit 1;
  if se.id is null then raise exception 'no season yet — lock the league first'; end if;

  v_start := current_date - (p_back * 7);
  v_end   := v_start + (p_long * 7) - 1;

  update seasons set starts_on = v_start, ends_on = v_end where id = se.id;

  -- which calendar months sit WHOLLY inside the window? those are the ones
  -- whose close assesses floors — the point of reshaping at all
  v_whole := '{}';
  m := date_trunc('month', v_start)::date;
  while m <= v_end loop
    if m >= v_start and (m + interval '1 month')::date - 1 <= v_end then
      v_whole := v_whole || to_char(m, 'YYYY-MM');
    end if;
    m := (m + interval '1 month')::date;
  end loop;

  return jsonb_build_object(
    'starts_on', v_start, 'ends_on', v_end,
    'weeks', p_long,
    'whole_months', v_whole,
    'cup_window_opens', v_end - 27,
    'note', case when array_length(v_whole,1) is null
                 then 'no whole month inside — floors stay waived'
                 else 'floors live in: ' || array_to_string(v_whole, ', ') end);
end $$;

revoke all on function public.sandbox_reshape(uuid, integer, integer) from public, anon;
grant execute on function public.sandbox_reshape(uuid, integer, integer) to authenticated;
