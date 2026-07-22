-- ============================================================================
-- The founder's desk — a hidden admin surface for the owner only.
--
-- Two RPCs, both gated IN-BODY on auth.uid() = founder_id() (identity is
-- checked at the database, never by hiding a button — CLAUDE.md law):
--   founder_note(p_body)  quick field notes into the same pilot_feedback
--                         ledger the crew's feedback lands in (category
--                         'founder', so the SQL-editor review reads one list)
--   founder_desk()        one jsonb snapshot: accounts (total + newest),
--                         activity counts, latest client_events, latest
--                         feedback — the "who's here / what's breaking /
--                         what are they saying" pulse in a single call.
--
-- D37 discipline: explicit grant execute to authenticated (the gate inside
-- refuses everyone but the founder). Nothing here is granted to anon.
-- ============================================================================

-- pilot_feedback grows a 'founder' category for desk notes
alter table public.pilot_feedback drop constraint if exists pilot_feedback_category_check;
alter table public.pilot_feedback add constraint pilot_feedback_category_check
  check (category in ('confusing','friction','idea','bug','other','founder'));

create or replace function public.founder_note(p_body text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'not yours';
  end if;
  if coalesce(trim(p_body), '') = '' then raise exception 'empty note'; end if;
  insert into public.pilot_feedback (category, body, context)
    values ('founder', left(p_body, 4000), jsonb_build_object('source','founder_desk'))
    returning id into v_id;
  return v_id;
end $$;
revoke all on function public.founder_note(text) from public;
grant execute on function public.founder_note(text) to authenticated;

create or replace function public.founder_desk()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare out jsonb;
begin
  if auth.uid() is null or auth.uid() is distinct from founder_id() then
    raise exception 'not yours';
  end if;
  select jsonb_build_object(
    'profiles_total', (select count(*) from profiles where deleted_at is null),
    'profiles_new_7d', (select count(*) from profiles
                        where created_at > now() - interval '7 days' and deleted_at is null),
    'newest', (select coalesce(jsonb_agg(jsonb_build_object(
                 'name', p.display_name, 'city', p.city,
                 'marker', p.marker is not null,
                 'at', p.created_at) order by p.created_at desc), '[]'::jsonb)
               from (select display_name, city, marker, created_at, deleted_at
                     from profiles where deleted_at is null
                     order by created_at desc limit 12) p),
    'rounds_total', (select count(*) from rounds),
    'rounds_7d', (select count(*) from rounds
                  where created_at > now() - interval '7 days'),
    'leagues', (select count(*) from leagues),
    'events', (select count(*) from events),
    'live_open', (select count(*) from live_rounds where status = 'open'),
    'posts_7d', (select count(*) from posts
                 where created_at > now() - interval '7 days'),
    'client_events', (select coalesce(jsonb_agg(jsonb_build_object(
                        'event', e.event, 'props', e.props,
                        'who', coalesce(pr.display_name, '?'),
                        'at', e.created_at) order by e.created_at desc), '[]'::jsonb)
                      from (select * from client_events
                            order by created_at desc limit 30) e
                      left join profiles pr on pr.id = e.profile_id),
    'feedback', (select coalesce(jsonb_agg(jsonb_build_object(
                   'cat', f.category, 'body', f.body,
                   'who', coalesce(pr.display_name, '?'),
                   'at', f.created_at) order by f.created_at desc), '[]'::jsonb)
                 from (select * from pilot_feedback
                       order by created_at desc limit 20) f
                 left join profiles pr on pr.id = f.profile_id)
  ) into out;
  return out;
end $$;
revoke all on function public.founder_desk() from public;
grant execute on function public.founder_desk() to authenticated;
