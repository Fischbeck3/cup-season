-- ============================================================================
-- Cup Season — suspend: the safety half of "remove", without the ledger half
--
-- OWNER'S RULING, 2026-09-01. `remove_member` refuses outside `phase='setup'`,
-- and the ship audit filed that as an App Store 1.2 gap. On inspection it is
-- not one: Apple's 1.2 asks for a report path, a block, and the developer able
-- to act, and after D188 all three exist. What was actually missing is the
-- thing a Pro needs when someone in a RUNNING league becomes a problem.
--
-- "Remove" is four questions wearing one name — does their squad play short or
-- get a sub; do their already-scored rounds vanish (and every other golfer's
-- standings silently move) or stay; is their pot share paid, owed or forfeit;
-- does their board history survive. Every one of those rewrites a competition
-- and a ledger, and §16 says the record shows its work and is never mutated.
--
-- So the two are split. SUSPEND is the safety action: reversible, attributed,
-- forward-only, and it touches nothing already scored and nothing in the pot.
-- REMOVE keeps its `setup`-phase gate, where rewriting a squad is harmless
-- because no round has been played into it yet.
--
-- What suspension does, precisely:
--   * they cannot post to the board or comment on a post in that league
--   * rounds they post AFTER the suspension do not score into that league
--     (they still score in every other league, and in their own record —
--     a suspension is a fact about one room, not about a golfer)
--   * everything already scored stays exactly where it is, so nobody else's
--     standings, receipts or pot math move by one point
--   * they can still READ the league. Suspension is not exile, and a
--     league-mate who cannot see what was said about them cannot appeal it.
--   * it is undone with one call, and the row records who did it and why.
--
-- The forward-only cut is `r.created_at < lm.suspended_at`, NOT a live filter
-- on membership. A live filter would erase their past rounds from the
-- standings the moment the Pro clicked, which is the exact thing §16 forbids
-- and the exact thing that would make a Pro's moderation decision look like
-- score-tampering to everyone else in the league.
--
-- The clause has to live in `v_rounds_ranked` rather than in a write guard,
-- because the view fans every round into every league the profile belongs to:
-- a suspended golfer posting a round in ANOTHER league would otherwise still
-- score into this one, and no write policy here could see it.
-- ============================================================================

alter table public.league_members add column if not exists suspended_at   timestamptz;
alter table public.league_members add column if not exists suspended_by   uuid references public.profiles(id);
alter table public.league_members add column if not exists suspend_reason text;

-- the column seal (D37) froze profiles' grant list; league_members is granted
-- wholesale, but be explicit rather than assume.
grant select (suspended_at, suspended_by, suspend_reason) on public.league_members to authenticated;

create index if not exists league_members_suspended_idx
  on public.league_members (league_id) where suspended_at is not null;

create or replace function public.is_suspended(p_league uuid)
returns boolean language sql stable security definer set search_path = public as $fn$
  select exists (
    select 1 from league_members
     where league_id = p_league
       and profile_id = auth.uid()
       and suspended_at is not null);
$fn$;
revoke all on function public.is_suspended(uuid) from public, anon;
grant execute on function public.is_suspended(uuid) to authenticated;

-- ---- the two write surfaces a suspended member loses ----------------------
-- Both are prod's exact WITH CHECK expressions with one conjunct appended.
-- `my_member_id()` is deliberately NOT the place for this: thirteen functions
-- call it, including read paths, and returning null there would take a
-- suspended golfer's own view of the league away as a side effect.
drop policy if exists posts_chat on public.posts;
create policy posts_chat on public.posts for insert with check (
  kind = 'chat'::text
  AND member_id = my_member_id(league_id)
  AND NOT is_suspended(league_id)
);

drop policy if exists comments_add on public.post_comments;
create policy comments_add on public.post_comments for insert with check (
  member_id = (SELECT my_member_id(p.league_id) FROM posts p WHERE p.id = post_comments.post_id)
  AND NOT is_suspended((SELECT p.league_id FROM posts p WHERE p.id = post_comments.post_id))
);

-- ---- the scoring lens -----------------------------------------------------
create or replace view public.v_rounds_ranked as
WITH scored AS (
         SELECT lm.id AS member_id,
            s.id AS season_id,
            r.id AS round_id,
            r.profile_id,
            r.played_on,
            r.holes_played,
            r.source,
            r.attested,
            r.differential,
            r.index_at_post,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0, 1) AS playing_index,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1) AS pvi,
                CASE
                    WHEN r.holes_played = 9 THEN ceil(cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))::numeric / 2::numeric)::integer
                    ELSE cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))
                END AS points,
                CASE
                    WHEN r.holes_played = 9 THEN 0.5
                    ELSE 1.0
                END AS floor_credit
           FROM rounds r
             JOIN league_members lm ON lm.profile_id = r.profile_id
             JOIN league_settings ls ON ls.league_id = lm.league_id
             JOIN seasons s ON s.league_id = lm.league_id AND (s.status = ANY (ARRAY['active'::text, 'cup_final'::text, 'complete'::text])) AND r.played_on >= s.starts_on AND r.played_on <= s.ends_on
          WHERE NOT r.voided AND (ls.sim_rounds_allowed OR COALESCE(r.source, 'app'::text) <> 'sim'::text) AND (ls.nine_hole_allowed OR r.holes_played = 18)
            AND (lm.suspended_at IS NULL OR r.created_at < lm.suspended_at)
        )
 SELECT member_id,
    season_id,
    round_id,
    profile_id,
    played_on,
    holes_played,
    source,
    attested,
    differential,
    index_at_post,
    playing_index,
    pvi,
    points,
    floor_credit,
    row_number() OVER (PARTITION BY member_id, season_id, (date_trunc('month'::text, played_on::timestamp with time zone)) ORDER BY points DESC, pvi DESC, played_on DESC) AS month_rank
   FROM scored;

-- ---- who may suspend, and of whom -----------------------------------------
create or replace function public.suspend_member(p_member uuid, p_reason text default null)
returns void language plpgsql security definer set search_path = public as $fn$
declare v_league uuid; v_role text; v_profile uuid;
begin
  select league_id, role, profile_id into v_league, v_role, v_profile
    from league_members where id = p_member;
  if not found then raise exception 'no such member'; end if;

  if auth.uid() <> founder_id() and not is_commissioner(v_league) then
    raise exception 'Only the Pro of this league can suspend someone in it';
  end if;
  if v_profile = auth.uid() then
    raise exception 'You cannot suspend yourself';
  end if;
  -- a Pro cannot suspend another Pro; that is a founder-level call, because
  -- two commissioners suspending each other is a league with no adult in it.
  if v_role = 'commissioner' and auth.uid() <> founder_id() then
    raise exception 'A Pro cannot suspend another Pro — contact Cup Season';
  end if;

  update league_members
     set suspended_at   = coalesce(suspended_at, now()),
         suspended_by   = auth.uid(),
         suspend_reason = left(coalesce(p_reason,''), 500)
   where id = p_member;
end $fn$;

create or replace function public.unsuspend_member(p_member uuid)
returns void language plpgsql security definer set search_path = public as $fn$
declare v_league uuid;
begin
  select league_id into v_league from league_members where id = p_member;
  if not found then raise exception 'no such member'; end if;
  if auth.uid() <> founder_id() and not is_commissioner(v_league) then
    raise exception 'Only the Pro of this league can lift a suspension in it';
  end if;
  update league_members
     set suspended_at = null, suspended_by = null, suspend_reason = null
   where id = p_member;
end $fn$;

revoke all on function public.suspend_member(uuid, text) from public, anon;
revoke all on function public.unsuspend_member(uuid)     from public, anon;
grant execute on function public.suspend_member(uuid, text) to authenticated;
grant execute on function public.unsuspend_member(uuid)     to authenticated;

-- ---- self-enforcing -------------------------------------------------------
do $$
begin
  if pg_get_viewdef('public.v_rounds_ranked'::regclass, true) not like '%suspended_at%' then
    raise exception '[suspend] the scoring view does not honour a suspension';
  end if;
  if (select pg_get_expr(polwithcheck, polrelid) from pg_policy pol
        join pg_class c on c.oid = pol.polrelid
       where c.relname = 'posts' and pol.polname = 'posts_chat') not like '%is_suspended%' then
    raise exception '[suspend] a suspended member can still post to the board';
  end if;
  if (select pg_get_expr(polwithcheck, polrelid) from pg_policy pol
        join pg_class c on c.oid = pol.polrelid
       where c.relname = 'post_comments' and pol.polname = 'comments_add') not like '%is_suspended%' then
    raise exception '[suspend] a suspended member can still comment';
  end if;
end $$;
