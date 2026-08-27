# 07 · Cup Season backend map (for the native iOS client)

Audit date 2026-08-27 · repo `/Users/fischbeck3/cup-season` · branch `native/b1-scaffold`.
Sources: 113 migrations under `supabase/migrations/`, 6 Edge Functions under
`supabase/functions/`, `packages/db/contract.psv` (pg_proc snapshot refreshed
2026-08-26), `packages/db/{client,auth,rpc}.ts`, `tests/db-checks.sql`,
`tests/preflight.mjs`, `supabase/config.toml`, `spec/native-arc.md`,
`spec/decision-log.md` (D98).

**Live-introspection caveat.** The Supabase MCP server available to this
session ("Supabase Casa") is linked to a *different* project
(`dloqhozuxrmgmwmibfbx`, a "casadata"/"casa-photos" schema), not Cup Season's
`zddbfcokmvneltrgukzf`. Every `list_tables` / `execute_sql` / `list_edge_functions`
call returned that other project, so nothing below was verified against the live
Cup Season database. Everything is derived from the migrations and the
`contract.psv` snapshot (which *is* a verbatim dump of prod `pg_proc`, taken
2026-08-26). Where the live state matters and cannot be read from the repo
(Database Webhooks, the auth dashboard config, secrets), it is marked
**[dashboard — not in repo]**.

Conventions: `→` means FK; `[N]` cites a migration by its timestamp prefix
(`00000000000000` = the baseline dump). Column lists are the *current* shape:
baseline columns plus every later `add column`.

---

## 1. Tables and views

### 1.1 Identity

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `profiles` | `id uuid PK (= auth.users.id)`, `display_name text NN`, `email text NN` (**SEALED**: no API role may select it), `ghin_number text`, `created_at`, `city`, `home_course`, `index_current numeric`, `marker text`, `card_quote`, `the_miss`, `walk_ride`, `beverage`, `notify_chat bool NN dflt true`, `handle text` (unique lower, `^[a-z0-9_]{3,20}$`), `discoverable text NN dflt 'everyone'` (`everyone|friends|nobody`), `deleted_at timestamptz`, `is_founder bool NN dflt false`, `notify_rounds bool NN dflt true`, `handle_set_at timestamptz`, `index_source text` (`self|app|ghin`), `photo_path text` (`{uid}/avatar.jpg` in `media`) | The global golfer. Auto-created by `handle_new_user` at signup with `display_name` derived from the email; onboarding is gated on `marker`. | baseline, 20260711170000, 20260712010000, 20260714200000, 20260714220000, 20260716030000, 20260716070000, 20260716100000, 20260723150000 |
| `friendships` | `id PK`, `requester → profiles`, `addressee → profiles`, `status` (`pending|accepted`), `created_at`, `responded_at`; `requester <> addressee` | The friend graph; a webhook on INSERT/UPDATE drives friend-request push + email. | 20260712010000 |
| `mutes` | `muter → profiles`, `muted → profiles`, `created_at`; PK (muter, muted) | Profile-level block. Enforced inside `posts_read` / `comments_read` policies, so realtime and the board go quiet with no client filter. No policies (definer-only). | 20260722013000 |
| `rivalry_names` | `pair_low`, `pair_high` (both → profiles, `pair_low < pair_high`), `name`, `named_by`, `named_at` | A named head-to-head rivalry. | 20260716210000 |
| `achievements` | `id PK`, `profile_id → profiles`, `kind`, `label`, `earned_on date`, `round_id → rounds (set null)` (the receipt), `meta jsonb`, `created_at`; unique (profile_id, kind) | Career one-time achievements (first round, sub-80…). Read via `my_achievements()`. | 20260716020000 |
| `trophies` | `id PK`, `profile_id → profiles`, `kind` (`ryder|league|major|event`), `title`, `subtitle`, `placement` (`winner|runner_up|points_king|…`), `event_id → events (set null)`, `league_id → leagues (set null)`, `season_year int`, `earned_on`, `created_at` | The trophy case; minted by `award_season_trophies` / `award_event_trophies`. `trophies_read` (own rows) + `my_trophies()`. | 20260713200000 |
| `push_subscriptions` | `id PK`, `profile_id → profiles`, `endpoint text unique`, `p256dh`, `auth`, `created_at` | **Web Push (VAPID)** subscriptions for the PWA. Own-row RLS (select/insert/update/delete). | 20260711170000 |
| `device_tokens` | `token text PK`, `profile_id → profiles`, `platform text NN dflt 'ios'` **`check (platform in ('ios'))`**, `created_at` | **APNs** device tokens for the native app. RLS enabled with NO policies: service-role reads (push fn), writes only via `register_device_token` / `unregister_device_token`. | 20260722013000, 20260826120000 |
| `email_prefs` | `profile_id PK → profiles`, `recap bool NN dflt true`, `token uuid NN` (unsubscribe token), `updated_at` | Season-recap email consent. Definer-only (no client reach). | 20260725140000 |
| `content_reports` | `id PK`, `post_id → posts` (nullable since 20260723150000), `reporter → profiles`, `reason`, `resolved bool`, `created_at`, `kind text NN dflt 'post'` (`post|profile_photo`), `profile_id → profiles`; `check (post_id is not null or profile_id is not null)` | UGC reports (App Store 1.2). Written by `report_content`; read on the founder desk. | 20260718174500, 20260723150000 |
| `shares` | `token uuid PK`, `kind` (`round|settlement|recap`), `ref_id uuid`, `created_by → profiles`, `revoked bool`, `created_at` | Public share links (D57). Table revoked from all API roles; only `create_share` / `revoke_share` / `share_info` touch it. | 20260722190000 |

### 1.2 Leagues and seasons

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `leagues` | `id PK`, `name`, `code text` (join code, case-insensitive), `phase` (`setup|draft|season|complete`), `commissioner_id → profiles`, `created_at`, `sandbox bool NN dflt false` | The league container. | baseline, 20260724170000 |
| `league_settings` | `league_id PK → leagues`, `preset` (`casual|standard|cutthroat|custom`), `handicap_allowance int` (90/95/100), `verification` (`honor|attested|ghin`), `counting_cap int`, `participation_floor int` (0–4), `floor_penalty` (`none|deduct|forfeit`), `season_format` (`points|h2h|hybrid`), `buyin_cents int dflt 7500`, `season_months int` (3–12), `sim_rounds_allowed bool`, `nine_hole_allowed bool`, `locked_at`, `structure` (`solo|squads2|squads3|squads4`), `draft_type` (`random|assign|snake|live`), `payout_champ/payout_runnerup/payout_king int` (sum 100), `finish text NN dflt 'cup_final'` (`points_table|cup_final`) | The bylaws. Writable by the Pro only while `locked_at is null`. | baseline, 20260716170000 |
| `league_members` | `id PK`, `league_id → leagues`, `profile_id → profiles`, `role` (`commissioner|captain|player`), `index_current numeric(4,1) dflt 18`, `index_source` (`self|app|ghin`), `joined_at`, `marker text` (per-league override) | Membership row; `my_member_id()` returns its id. The `members_self` UPDATE policy was DROPPED (self-promotion hole). | baseline, 20260718172300, 20260723150000 |
| `seasons` | `id PK`, `league_id → leagues`, `number int`, `starts_on date`, `ends_on date`, `status` (`active|cup_final|complete`), `timezone dflt 'America/Phoenix'`, `grace_hours int dflt 48`, `champion_squad_id`, `points_king_member_id`, `kicked_off bool`, `champion_member_id → league_members`, `runnerup_squad_id → squads`, `runnerup_member_id → league_members`, `champion_score numeric`, `runnerup_score numeric`, `tiebreak_rung text` | One season per league run; the daily tick flips status. | baseline, 20260712130000, 20260716170000, 20260724230000 |
| `squads` | `id PK`, `season_id → seasons`, `name`, `color int` (0–3 palette index), `captain_member_id → league_members (set null)` | Squads within a season. | baseline, 20260711210000 |
| `squad_members` | `squad_id`, `member_id`, `drafted_round int`, `pick_number int` | Seat assignments. | baseline |
| `drafts` | `id PK`, `season_id`, `type` (`snake|assign|live`), `status` (`pending|live|complete`), `rounds_count`, `pick_seconds`, `order_squads uuid[]`, `current_pick int`, `started_at`, `completed_at` | Draft state (snake/captains engines are only partly built — spec "honest edges"). In the realtime publication. | baseline |
| `draft_picks` | `id PK`, `draft_id`, `pick_number`, `round_number`, `squad_id`, `member_id`, `picked_by`, `via_override bool`, `created_at` | Pick log. In the realtime publication. | baseline |
| `cup_finalists` | `id PK`, `season_id`, `squad_id`/`member_id` (one NN), `seed int`, `head_start int`, `locked_at` | Seeds locked when status flips to `cup_final` at `ends_on − 27`. | baseline |
| `season_adjustments` | `id PK`, `season_id`, `squad_id`, `member_id`, `month date`, `kind` (`floor_penalty|floor_forfeit|matchup_bonus|bye|override|month_closed`), `points int`, `reason`, `created_by`, `created_at` | The ledger (§16): floors, byes, overrides, and the `month_closed` idempotency sentinel. | baseline, 20260718172300 |
| `standings_snapshots` | `id PK`, `season_id`, `week_no int`, `captured_at`, `standings jsonb` | Weekly standings snapshot from cron (`snapshot_week`). | baseline |
| `season_lead` | `season_id PK → seasons`, `squad_id → squads (set null)`, `since` | Who leads now (for lead-change moments). | 20260716000000 |
| `invites` | `id PK`, `league_id`, `email`, `token uuid`, `status` (`sent|accepted`), `created_at` | Legacy email invites (commissioner-only policy). Superseded by `member_invites`. | baseline |
| `member_invites` | `id PK`, `league_id → leagues` XOR `event_id → events`, `profile_id → profiles` (invitee), `invited_by → profiles`, `status` (`pending|accepted|declined`), `created_at` | In-app invites to a league or an event. | 20260713180000 |
| `commissioner_log` | `id PK`, `league_id`, `actor_id`, `action`, `detail jsonb`, `created_at` | Pro action audit trail. | baseline |
| `league_cancellations` | `league_id PK → leagues`, `requested_by`, `requested_at` | An open cancel request (D71). Definer-only. | 20260726100000 |
| `cancellation_votes` | `league_id`, `member_id`, `voted_at`; PK (league_id, member_id) | Unanimity votes for a money league's cancellation. Definer-only. | 20260726100000 |
| `cancellation_notices` | `id PK`, `payload jsonb` (`{league, recipients:[{email,name,cents}]}`), `created_at`, `sent_at`, `error` | Self-contained email snapshot written BEFORE the league is deleted; a webhook on INSERT → `season-email`. | 20260726100000 |

### 1.3 Rounds and scoring

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `rounds` | `id PK`, `season_id → seasons (set null)`, `live_round_id`, `course_id uuid` (legacy), `tee_id uuid`, `course_label text NN`, `played_on date NN`, `holes_played` (9/18), `gross int` (18–200), `rating numeric(4,1)` (25–90, NOT VALID), `slope int` (55–155, NOT VALID), `nine_rating`, `index_at_post numeric(4,1) NN`, `differential numeric(5,1)`, `source` (`quick|live|scan_claim`), `attested bool`, `voided bool`, `created_at`, `index_source_at_post` (`self|app|ghin`), `profile_id → profiles`, `api_course_id text` (soft ref to `api_courses`), `photo_path text` (`{uid}/…` in `media`) | **Profile-owned facts, immutable** (§16). `score_round()` trigger computes `differential` and snapshots the index. Owner may INSERT (policy) and delete via `delete_round()`; `rounds_owner_update` was DROPPED. Future dates rejected by trigger. | baseline, 20260714050000, 20260718045514, 20260718172300, 20260718173100, 20260718174500 |
| `round_holes` | `round_id`, `hole_number` (1–18), `strokes` (1–15) | Hole-by-hole strokes for a posted round. | baseline |
| `attestations` | `round_id`, `attested_by text`, `is_member bool`, `created_at` | Attestation record (largely dormant). | baseline |
| `scheduled_rounds` | `id PK`, `profile_id → profiles`, `play_on date`, `course_label`, `note`, `created_at`, `tagged uuid[]`, `tee_time time`, `course_id text → api_courses (set null)`, `league_id → leagues (set null)` | The tee sheet: declared future rounds. Owner-only policy `sched_own`; reads via `my_schedule()` / `round_detail()`. | 20260712150000, 20260712170000, 20260715230000, 20260718192400 |
| `round_rsvp` | `round_id → scheduled_rounds`, `profile_id`, `status` (`in|maybe|out`), `updated_at`; PK (round_id, profile_id) | RSVPs; write restricted to owner + tagged (D69). | 20260718192400, 20260725160000 |
| `round_comments` | `id PK`, `round_id → scheduled_rounds`, `profile_id`, `body`, `created_at` | Comments on a scheduled round. | 20260718192400 |
| `scan_claims` | `id PK`, `token uuid unique`, `created_by → profiles`, `guest_name`, `course_label`, `rating`, `slope`, `played_on`, `gross`, `strokes jsonb` (18-slot), `holes_played`, `claimed_profile → profiles`, `created_at` | A partner row minted from a scanned scorecard; `/?claim=` link. No policies (definer RPCs). | 20260718045514 |
| `api_courses` | `id text PK` (GolfCourseAPI id), `club_name`, `course_name`, `city`, `state`, `country`, `latitude`, `longitude`, `raw jsonb`, `cached_at` | The course cache written by the `courses` Edge Function. Read `using (true)` for authenticated. | 20260714050000 |
| `api_course_tees` | `id PK`, `course_id → api_courses`, `gender`, `tee_name`, `course_rating`, `slope_rating`, `bogey_rating`, `par_total`, `total_yards`, `number_of_holes`; unique (course_id, gender, tee_name) | Cached tees. | 20260714050000 |
| `api_course_holes` | `id PK`, `tee_id → api_course_tees`, `hole_number`, `par`, `yardage`, `handicap` (stroke index); unique (tee_id, hole_number) | Cached per-hole par + SI. | 20260714050000 |
| `courses` / `course_tees` / `course_holes` | Legacy uuid-keyed schema from the baseline (`courses.id uuid`, `external_id int`, `lat/lng`, `source api|manual`, `verified`, `created_by`; tees carry front/back rating+slope, `holes_count`; holes carry `stroke_index`). | **Legacy.** The 20260712250000 `create table if not exists` no-op'd against these, which is why the `api_*` tables exist (20260714050000). `live_rounds.course_id/tee_id` and `rounds.course_id/tee_id` still reference this uuid schema. Do not build on them. | baseline, 20260712250000 |
| `weather_cache` | `course_id text`, `play_on date`, `lat`, `lon`, `payload jsonb`, `fetched_at`; PK (course_id, play_on) | Open-Meteo cache written by the `weather` Edge Function. Read `using (true)`. | 20260718192400 |

### 1.4 Live games and events

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `live_rounds` | `id PK`, `league_id NN`, `season_id NN`, `course_id uuid`, `tee_id uuid`, `course_label NN`, `course_snapshot jsonb NN`, `game` (`none|match|wolf|skins|sunningdale`), `game_config jsonb` (dflt `{"lone_multiplier":3,"wolf_value_cents":200}`), `status` (`setup|live|final|abandoned`), `started_by → league_members`, `started_at`, `finished_at`, `game_result jsonb`, `join_code text` (unguessable broadcast-channel key), `game_state jsonb` (per-hole wolf declarations `h1..h18` with `cts`) | A tee-sheet round in progress. RLS `is_league_member(league_id)`. Auto-abandoned 24h after start by the daily tick. In the realtime publication. | baseline, 20260716130000, 20260716140000, 20260717050000, 20260725220000, 20260728120000 |
| `live_round_players` | `id PK`, `live_round_id`, `member_id → league_members` (null for guests), `guest_name`, `guest_index numeric(4,1)`, `index_source` (`member|self|estimated`), `position int` (0–3), `claim_token uuid` (**the guest's whole authorization**), `guest_strokes jsonb`, `guest_gross int`, `claimed_profile → profiles`, `guest_profile_id → profiles` (D88 known visitor) | Seats in a live round. In the realtime publication. | baseline, 20260716140000, 20260728220000 |
| `live_scores` | `live_round_id`, `player_id`, `hole_number` (1–18), `strokes` (1–15), `client_ts timestamptz`, `updated_at`, `updated_by → league_members` | Per-hole strokes during play; LWW by `client_ts`. **Table privileges REVOKED from authenticated** (20260728120000) — reads/writes only via `live_state` / `live_set_score` / guest RPCs; realtime `postgres_changes` on it delivers nothing (no read policy). Transport is Realtime **broadcast** on the `join_code` channel. | baseline, 20260728120000 |
| `game_results` | `live_round_id`, `player_id`, `points int`, `amount_cents int` | Per-player settlement of a live game. | baseline |
| `events` | `id PK`, `name`, `created_by → profiles`, `league_id → leagues (set null)`, `kind` (`ryder|major`), `status` (`setup|live|complete`), `starts_on`, `session_count` (1–26), `session_weeks` (1–4), `draw_rule` (`team_pvi|defender|shared`), `defender_team_id`, `allowance int dflt 100`, `winner_team_id`, `created_at`, `tz text dflt 'America/Phoenix'`, `buy_in numeric`, `pot_split text dflt 'places'`, `lineage_id → events (set null)` | The Ryder (team duels) and the Major (stroke-play window). | 20260713120000, 20260713160000, 20260716150000, 20260720193000, 20260724100000 |
| `event_teams` | `id PK`, `event_id`, `slot` (0/1), `name`, `color int`, `captain_player_id`; unique (event_id, slot) | The two benches. | 20260713120000 |
| `event_players` | `id PK`, `event_id`, `profile_id`, `team_id → event_teams (set null)`, `role` (`captain|player`), `seed int`, `benched_count int`, `created_at`, `notify_target bool` (opt-in taunts), `exhibition bool` (Major: unestablished index) | Event roster. | 20260713120000, 20260716150000, 20260720193000 |
| `event_sessions` | `id PK`, `event_id`, `session_no`, `opens_on`, `closes_on`, `status` (`upcoming|open|closed`), `weight numeric` | Session windows; opened/resolved by `run_event_sessions` cron. | 20260713120000 |
| `event_duels` | `id PK`, `event_id`, `session_id`, `a_player`/`b_player → event_players`, `a_round`/`b_round → rounds`, `a_pvi`/`b_pvi`, `a_points`/`b_points`, `result` (`pending|a|b|halve`), `resolved_at` | Singles pairings inside a session. | 20260713120000 |
| `event_major_cards` | `id PK`, `event_id`, `player_id → event_players`, `round_id → rounds`, `gross`, `pvi`, `second_pvi`, `cards int`, `best_posted_at`, `no_card bool`, `exhibition bool`, `rank int`, `prize numeric`, `resolved_at`; unique (event_id, player_id) | Settled Major leaderboard rows. Read policy for members/attached league. | 20260720193000 |

### 1.5 Social

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `posts` | `id PK`, `league_id → leagues` (nullable since 20260716160000), `season_id`, `kind` (`chat|round|system|announce|moment`), `member_id → league_members`, `round_id → rounds (cascade)`, `body`, `created_at`, `event_id → events (cascade)`, `push_title text` (authored lock-screen title for settlements), `live_round_id uuid` (the sheet behind a settlement post); `check (league_id is not null or event_id is not null)` | The board — the social spine. INSERT of `kind='chat'` allowed by policy (`member_id = my_member_id(league_id)`); every other kind is written by triggers/RPCs. A webhook on INSERT → `push`. In the realtime publication. | baseline, 20260712070000, 20260715234500, 20260716160000, 20260727240000, 20260729120000 |
| `post_comments` | `id PK`, `post_id`, `member_id`, `body`, `created_at` | Comments; policy-inherit post visibility + author-mute check. Realtime. | baseline, 20260722013000 |
| `post_kudos` | `post_id`, `member_id`, `emoji text dflt '🔥'`, `created_at` | Reactions. Realtime. | baseline, 20260716230000, 20260717010000 |
| `push_nudges` | `id PK`, `profile_id → profiles`, `title`, `body`, `created_at` | One row = one personalised push to one profile (Ryder taunts, D86 tee-sheet invites). No policies; a webhook on INSERT → `push`. | 20260716160000, 20260728180000 |
| `feedback` | `id PK`, `league_id`, `member_id`, `body`, `screen`, `created_at` | Legacy per-league feedback (member read/add policies). Superseded by `pilot_feedback`. | baseline |

### 1.6 Money (a tracked ledger — the app moves nothing, D39)

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `buy_ins` | `season_id`, `member_id`, `amount_cents int`, `paid bool`, `marked_by`, `marked_at` | Who has paid the pot. Pro marks via `mark_buy_in`. | baseline, 20260712130000 |
| `season_payouts` | `season_id`, `profile_id`, `cents int`, `reason text`, `created_at`; PK (season_id, profile_id, reason) | Recorded payout per seat at season close (penny-exact split). `payouts_read` policy (own rows); feeds `career_record`. | 20260725100000, 20260725190000 |
| `forfeits` | `id PK`, `league_id`, `name` (2–60), `terms` (2–200), `kind` (`hosts|course_pick|strokes|bounty|custom`), `party_a`, `party_b`, `hangs_on`, `status` (`open|settled|scrapped`), `winner`, `settled_note`, `created_by`, `created_at`, `settled_at`, `settled_by` | Side stakes between members (D50). `forfeits_read` for league members. | 20260724120000 |

### 1.7 Ops / instrumentation

| Table | Columns | Purpose | Migrations |
|---|---|---|---|
| `app_flags` | `key text PK`, `value jsonb`, `updated_at` | Remote-control flags, readable by authenticated (`flags_read using (true)`), writable only from the SQL editor. Seeded keys: `scan` = `{"enabled":true,"daily_per_user":5,"monthly_global":400}`; `courses` = `{"daily_per_user":150}`. | 20260718045514, 20260718173100 |
| `scan_usage` | `id PK`, `profile_id`, `model`, `ok bool`, `created_at` | Scan cost ledger + cap counter (service-role writes). | 20260718045514 |
| `courses_usage` | `id PK`, `profile_id`, `action`, `created_at` | Course-lookup rate-limit ledger (service-role writes). | 20260718173100 |
| `client_events` | `id PK`, `profile_id dflt auth.uid()`, `event text (≤64)`, `props jsonb`, `created_at` | Client telemetry; `ce_insert_own` policy (authenticated INSERT only — signed-out sessions are invisible). | 20260717153000 |
| `pilot_feedback` | `id PK`, `profile_id dflt auth.uid()`, `category` (`confusing|friction|idea|bug|other|founder`), `body`, `context jsonb`, `created_at` | In-app feedback via `submit_feedback` / `founder_note`. | 20260714160000, 20260721191500 |
| `email_queue` | `id PK`, `season_id → seasons`, `kind dflt 'season_recap'`, `created_at`, `sent_at`, `error`; unique (season_id, kind) | Season-recap outbox; trigger on `seasons` inserts, webhook on INSERT → `season-email`. Definer-only. | 20260725140000 |

### 1.8 Views (all `security_invoker = true` where API-reachable; check 11 enforces it)

| View | Purpose | Reachable by | Migration |
|---|---|---|---|
| `v_rounds_ranked` | Fans every round into every league its profile belongs to and scores it through that league's bylaws: `playing_index`, `pvi`, `points` (`cup_points()`, halved for 9 holes), `floor_credit` (0.5/1.0), `month_rank` (counting-cap window). Filters `voided`, sim rounds, 9-hole per bylaws, season date window. | authenticated (RLS of base tables applies) | baseline |
| `v_individual_standings` | Per member per season: counting points (`month_rank <= counting_cap`) + `rounds_posted`. | authenticated | baseline |
| `v_squad_standings` | Per squad per season: counting rounds + `season_adjustments` ledger. | authenticated | baseline |
| `v_event_scoreboard` | Team points = sum of its players' duel points, both sides. | authenticated (flipped to invoker 20260725210000) | 20260713120000, 20260725210000 |
| `v_pilot_gates` | Signup→card→join→first-round funnel timings (joins `auth.users`). | **revoked** from anon+authenticated (SQL editor only) | 20260717153000 |
| `v_post_timings` | Post-composer timings from `client_events`. | **revoked** | 20260717153000 |

---

## 2. RPC catalogue (from `packages/db/contract.psv`, 2026-08-26 prod snapshot)

156 callable functions in `public` (155 names; `declare_round` has two overloads). Grants column is the **live** `proacl` from the snapshot: `auth` = authenticated, `anon,auth` = both, `none` = neither API role (cron / trigger / internal / service_role only). Every client-called RPC must carry an explicit `grant execute … to authenticated` (D37, 20260718172300); the 10 anon endpoints are asserted by `tests/db-checks.sql` check 2 and exported as `anonCallable` in `packages/db/rpc.ts`. Migration column = the file holding the *current* body.

### 2.1 Identity / profile

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `set_profile` | `p_name text, p_city, p_home, p_index numeric, p_marker, p_ghin, p_photo_path` (all defaulted) | void | auth | Upsert the golfer card (supplies `email` from `auth.users` itself; `photo_path` must be under `{uid}/`). | 20260723150000 |
| `set_handle` | `p_handle text` | void | auth | Set/rename the handle (3–20 `[a-z0-9_]`, reserved list, rate-limited, announced). | 20260716070000 |
| `set_index` | `p_index numeric` | void | auth | Manual starter index (−10..54); refused once the engine has ≥3 rounds. | 20260716120000 |
| `set_discoverable` | `p_mode text` | void | auth | `everyone|friends|nobody`. | 20260712010000 |
| `set_notify_chat` / `set_notify_rounds` | `p_on bool` | void | auth | Push mute flags for chat / round posts. | 20260711170000, 20260716030000 |
| `set_email_recap` | `p_on bool default null` | boolean | auth | Read (null) or set the season-recap email consent. | 20260725140000 |
| `email_unsubscribe` | `p_token uuid` | boolean | **anon,auth** | One-way unsubscribe by token; always returns true. | 20260725140000 |
| `set_mute` | `p_profile uuid, p_on bool` | void | auth | Block/unblock a profile. | 20260722013000 |
| `my_mutes` | — | uuid[] | auth | The caller's muted profile ids. | 20260722013000 |
| `register_device_token` | `p_token text, p_platform text default 'ios'` | void | auth | Upsert an APNs token for the caller (200-char cap). | 20260722013000 |
| `unregister_device_token` | `p_token text` | void | auth | Delete the caller's own token. | 20260826120000 |
| `delete_account` | — | void | auth | Tombstone the profile (scrubs name/handle/city/GHIN); refuses if the caller runs a league with other players. | 20260718172300 |
| `tour_card` | `p_profile uuid` | jsonb | auth | Another golfer's card (visible to self, friends, league-mates, event-mates): profile, career, trophies, recent rounds with `beat`, head-to-head. | 20260726190000 |
| `career_record` | — | jsonb | auth | Cups, runner-ups, crowns, majors, trophies, earnings, seasons paid. | 20260725190000 |
| `my_achievements` | — | table(kind,label,earned_on,meta) | auth | Career achievements. | 20260716020000 |
| `my_trophies` | — | table(id,kind,title,subtitle,placement,season_year,earned_on) | auth | Trophy case, newest first. | 20260713200000 |
| `handicap_index` | `p_profile uuid` | numeric | auth | WHS-lite index from the last 20 differentials (null until 3 rounds). | 20260716100000 |
| `handicap_index_asof` | `p_profile, p_before_date, p_before_id` | numeric | auth | Same, as of a given round. | 20260716100000 |
| `founder_id` | — | uuid | **anon,auth** | The founder's profile id (client badges it). | 20260714220000 |
| `founder_desk` | — | jsonb | auth (founder-gated in body) | Ops dashboard: signups, newest, reports, feedback, live rounds. | 20260723150000 |
| `founder_note` | `p_body text` | uuid | auth (founder-gated) | Founder writes a note into `pilot_feedback`. | 20260721191500 |
| `firstname` | `p text` | text | auth | IMMUTABLE first-name helper ("Someone" fallback). | 20260727160000 |
| `playerlabel` | `p_profile uuid` | text | auth | Display-name helper. | 20260716080000 |
| `handle_new_user` | trigger | trigger | auth (grant is vestigial) | `auth.users` INSERT → creates the `profiles` row. **The trigger itself is not in any migration** (pre-repo m001, lives on `auth.users`). | baseline |
| `tag_founder` | trigger | trigger | auth (vestigial) | Marks `is_founder` on the owner's email. | 20260714220000 |

### 2.2 Social graph

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `search_golfers` | `p_q text` | table(profile_id,handle,display_name,city,home_course,marker,index_current,rel) | auth | Find golfers by name/handle honouring `discoverable`; `rel` = `friend|requested|incoming|none`. | 20260717194623 |
| `friend_request` | `p_profile uuid` | text | auth | Request (or auto-accept a mutual one); returns `friend|requested`. | 20260712010000 |
| `friend_respond` | `p_id uuid, p_accept bool` | void | auth | Accept or delete a pending request. | 20260712010000 |
| `unfriend` | `p_profile uuid` | void | auth | Remove the friendship. | 20260712010000 |
| `my_friends` | — | table(friendship_id,profile_id,handle,display_name,city,marker,index_current,status,incoming) | auth | Friend list incl. pending. | 20260715210000 |
| `my_rivalries` | — | table(opponent,display_name,handle,marker,wins,losses,ties,meetings,lead,duel_wins,duel_losses,duel_halves,rivalry_name) | auth | Weekly-clash + Ryder-duel record vs each shared-league opponent. | 20260716210000 |
| `rivalry_weeks` | `p_opponent uuid` | table(wk,my_pvi,opp_pvi,winner) | auth | The receipts behind a rivalry. | 20260716010000 |
| `set_rivalry_name` | `p_opponent uuid, p_name text` | void | auth | Name/clear a rivalry (history required). | 20260716210000 |
| `last_round_with` | — | table(profile_id,display_name,marker,last_on,shared_cards) | auth | The richest lapsed partnership (≥3 shared cards, ≥12 months). | 20260724110000 |
| `report_content` | `p_post uuid, p_reason, p_kind default 'post', p_profile` | void | auth | Report a post or a profile photo. | 20260723150000 |

### 2.3 Leagues / seasons / roster

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `create_league` | `p_name text, p_code text` | json | auth | Create league + commissioner membership + settings. | baseline |
| `league_by_code` | `p_code text` | text | **anon,auth** | League name for a join code (pre-auth validation). | 20260714040000 |
| `join_covenant_info` | `p_code text` | jsonb | **anon,auth** | The join covenant face: name, buy-in, preset, floor, finish, structure. | 20260722211500 |
| `join_league` | `p_code text` | uuid | auth | Join by code; posts "X JOINED THE LEAGUE". | 20260714040000 |
| `invite_golfer` | `p_league uuid, p_event uuid, p_profile uuid` | uuid | auth | Pro/organizer invites an app golfer to exactly one container. | 20260713180000 |
| `respond_invite` | `p_id uuid, p_accept bool` | void | auth | Accept/decline a `member_invites` row. | 20260729180000 |
| `my_invites` | — | table(id,kind,container_id,container_name,inviter,starts_on,created_at) | auth | Pending invites for the banner. | 20260713180000 |
| `add_friend_to_league` | `p_league uuid, p_profile uuid` | void | auth | Pro seats an accepted friend directly. | 20260712050000 |
| `remove_member` | `p_member uuid` | void | auth | Pro removes a member (setup phase only). | 20260712150000 |
| `transfer_pro` | `p_member uuid` | void | auth | Hand the commissioner role over. | 20260712150000 |
| `set_member_index` | `p_member uuid, p_index numeric` | void | auth | Pro sets a starter index (refused once engine-established). | 20260716120000 |
| `set_member_bye` | `p_member uuid, p_month date, p_on bool` | void | auth | Pro grants/revokes a floor bye. | 20260716180000 |
| `set_league_marker` | `p_league uuid, p_marker text` | void | auth | Per-league ball-marker override. | 20260723150000 |
| `set_league_finish` | `p_league uuid, p_finish text` | void | auth | Endgame dial `points_table|cup_final` (locked once the final window opens). | 20260716170000 |
| `form_squads` | `p_season uuid` | void | auth | Create N empty squads per structure. | 20260711130000 |
| `randomize_squads` | `p_season uuid` | void | auth | Blind draw into the smallest squad (random draft_type only). | 20260722210000 |
| `assign_player` | `p_squad uuid, p_member uuid` | void | auth | Pro seats a player (assign draft_type). | 20260722210000 |
| `start_draft` | `p_season uuid, p_shuffle bool default true` | uuid | auth | Open a draft (snake/live engines only partly built). | baseline |
| `make_pick` | `p_draft uuid, p_member uuid` | void | auth | Draft pick. | 20260727160000 |
| `undo_pick` | `p_draft uuid` | void | auth | Commissioner undoes the last pick. | baseline |
| `start_season` | `p_season uuid` | void | auth | Lock + go live (≥4 golfers, no empty squad). | 20260722210000 |
| `mark_buy_in` | `p_season uuid, p_member uuid, p_paid bool` | void | auth | Pro marks a buy-in paid; posts the tally. | 20260712130000 |
| `announce` | `p_league uuid, p_body text` | void | auth | Pro announcement (1–280 chars). | 20260712070000 |
| `league_pulse` | `p_league uuid` | table(profile_id,display_name,marker,credits,floor,at_floor,is_me,partial) | auth | This month's floor gauge per member. | 20260722211500 |
| `season_scenarios` | `p_season uuid` | jsonb | auth | Clinch/elimination/seed race (generous ceiling, D24). | 20260716224500 |
| `delete_league` | `p_league uuid` | void | auth | Pro scraps a never-live league. | 20260712230000 |
| `request_league_cancel` | `p_league uuid` | text | auth | Free league → cancels now; money league → opens a unanimous vote. | 20260726100000 |
| `vote_league_cancel` | `p_league uuid, p_approve bool` | text | auth | Member vote; any decline kills the request. | 20260726100000 |
| `withdraw_league_cancel` | `p_league uuid` | text | auth | Pro withdraws the request. | 20260726100000 |
| `league_cancel_status` | `p_league uuid` | jsonb | auth | Consent-screen state. | 20260726100000 |
| `cancel_league_now` | `p_league uuid` | void | none | Internal: snapshot → notice → cascade delete. | 20260726100000 |
| `is_league_member` / `is_commissioner` / `my_member_id` | `p_league uuid` | boolean / boolean / uuid | auth | The three RLS helpers (must stay executable by authenticated or every policy fails). | baseline |
| `create_forfeit` | `p_league, p_name, p_terms, p_kind default 'custom', p_other, p_hangs` | uuid | auth | Post a side stake. | 20260727160000 |
| `settle_forfeit` | `p_id, p_winner default null, p_note default null` | void | auth | A party (or the Pro) settles it. | 20260724120000 |
| `scrap_forfeit` | `p_id uuid` | void | auth | Creator/Pro scraps an open stake. | 20260724120000 |

### 2.4 Season engine (cron / internal — NOT client-callable)

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `run_month_closes` | — | void | none | Cron: `close_month` for every active season. | baseline |
| `close_month` | `p_season uuid, p_month date` | void | **auth** (grant survives from baseline; body is idempotent and season-scoped — see gap G9) | Assess floors/bonuses/byes into the ledger; `month_closed` sentinel. | 20260727160000 |
| `run_week_snapshots` / `snapshot_week` | — / `p_season uuid` | void | none | Cron: weekly `standings_snapshots`. | baseline |
| `daily_season_tick` | — | void | none | Cron: abandon 24h-old live rounds; enter cup final at `ends_on − 27`; close season after grace. | 20260722100000 |
| `enter_cup_final` | `p_season uuid` | void | none | Lock `cup_finalists` seeds, flip status. | baseline |
| `close_season` | `p_season uuid` | void | none | Crown champion/runner-up/king, tiebreak ladder, trophies, payouts, story post. | 20260724230000 |
| `award_season_trophies` | `p_season uuid` | void | none | Mint league trophies + `season_payouts`. | 20260725190000 |
| `cup_points` | `p_pvi numeric` | integer | auth | IMMUTABLE band table: ≥3→12, ≥1→9, >−1→7, ≥−3→6, else 5. | baseline |
| `score_round` (trigger) | — | trigger | auth (vestigial) | BEFORE INSERT on rounds: differential + index snapshot (never a blind 18). | 20260716100000 |
| `score_round` (fn) | `p_gross,p_rating,p_slope,p_nine_rating,p_index,p_allowance,p_holes` | table(o_diff,o_pvi,o_points) | auth | Pure scoring calc for previews. | baseline |
| `round_to_board` / `round_moments` / `squad_lead_moments` / `round_refresh_index` / `round_duel_nudge` / `round_major_story` / `rounds_no_future` / `sched_major_story` / `trg_event_complete` / `season_email_on_complete` | triggers | trigger | mixed (vestigial) | See §3. | — |

### 2.5 Rounds, tee sheet, scanning, sharing

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `declare_round` | `p_play_on date, p_course text, p_note text, p_tagged uuid[] default '{}', p_tee time default null, p_course_id text default null` (+ an older 5-arg overload) | uuid | auth | Put a future round on the tee sheet (≤7 tags, ≤1 year out). | 20260718192400 |
| `retag_round` | `p_id uuid, p_tagged uuid[]` | void | auth | Owner edits tags on a future round. | 20260712190000 |
| `scratch_round` | `p_id uuid` | void | auth | Owner deletes a scheduled round. | 20260712150000 |
| `my_schedule` | `p_from date, p_to date` | table(id,profile_id,display_name,marker,play_on,course_label,note,tee_time,mine,is_friend,shared_league,tagged_names,tagged_me,course_id,rsvp_in,my_rsvp,comment_n) | auth | Everything on the books the caller may see. | 20260718192400 |
| `round_detail` | `p_round uuid` | jsonb | auth | One scheduled round with RSVPs, comments, `tagged_me`. | 20260725160000 |
| `set_round_rsvp` | `p_round uuid, p_status text` | void | auth | `in|maybe|out` — owner + tagged only (D69). | 20260725160000 |
| `add_round_comment` | `p_round uuid, p_body text` | void | auth | ≤500 chars, visibility via `can_see_round`. | 20260718192400 |
| `can_see_round` | `p_round uuid` | boolean | auth | Owner / tagged / accepted friend / league-mate. | 20260718192400 |
| `can_see_media` | `p_owner text` | boolean | auth | Storage read predicate: self / league-mate / friend. | 20260718173100 |
| `delete_round` | `p_round uuid` | void | auth | Owner deletes a posted round (the only mutation path). | 20260715170000 |
| `round_card` | `p_round uuid` | jsonb | auth | A posted round's sheet: holes, rank, mates (own or league-mate). | 20260729180000 |
| `round_epilogue` | `p_round uuid` | jsonb | auth | Post-round peak: points, rank, achievements, rivalry lines. | 20260716210000 |
| `home_feed` | `p_days int default 21` | table(round_id,profile_id,golfer,marker,handle,gross,pvi,played_on,created_at,course,is_pr,is_first,is_sub80,is_me,photo_path) | auth | **The only cross-league feed RPC**: recent rounds from the caller's circle (self + friends + league-mates), with PR/first/sub-80 flags. Not a "what next" surface. | 20260723090000 |
| `create_scan_claim` | `p_name, p_gross, p_strokes jsonb, p_course, p_rating, p_slope, p_played, p_holes default 18` | uuid | auth | Mint a `/?claim=` for a scanned partner row (8/day cap). | 20260718045514 |
| `scan_claim_info` | `p_token uuid` | jsonb | **anon,auth** | The door card for a scan claim. | 20260718045514 |
| `claim_scan_round` | `p_token uuid` | jsonb | auth | Adopt the scanned row as a real round. | 20260718045514 |
| `claim_round_info` | `p_token uuid` | jsonb | **anon,auth** | Door card for a live-round guest claim (final rounds only). | 20260716140000 |
| `claim_round` | `p_token uuid` | jsonb | auth | Adopt the guest card as a real, attested round. | 20260716140000 |
| `create_share` | `p_kind text, p_ref uuid` | uuid | auth | Mint a public share token (`round|settlement|recap`, ownership-checked). | 20260722190000 |
| `revoke_share` | `p_token uuid` | boolean | auth | Delete the `shared/{token}.jpg` copy, then revoke. | 20260723210000 |
| `share_info` | `p_token uuid` | jsonb | **anon,auth** | Public payload for a share page (no ids, no league names). | 20260727120000 |

### 2.6 Live rounds (the tee sheet in play)

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `start_live_round` | `p_league uuid, p_course_id uuid, p_tee_id uuid, p_course_label text, p_snapshot jsonb, p_game text, p_players jsonb, p_config jsonb default '{}'` | jsonb | auth | Create the round + seats, mint `join_code`, one `push_nudges` row per member player. | 20260728220000 |
| `live_state` | `p_live_round uuid` | jsonb | auth | The reconcile pull: round, players, scores, game_state (member/visitor). | 20260728120000 |
| `live_set_score` | `p_live_round, p_player, p_hole int, p_strokes int, p_client_ts timestamptz` | void | auth | LWW per-hole write (member pencil). | 20260728120000 |
| `live_set_wolf` | `p_live_round, p_hole int, p_wolf jsonb, p_client_ts` | void | auth | LWW wolf declaration into `game_state.hN`. | 20260728120000 |
| `guest_live_state` / `guest_live_set_score` / `guest_live_set_wolf` | `p_token uuid, …` | jsonb / void / void | **anon,auth** | The same trio keyed by a GUEST row's `claim_token` (never a member's). | 20260728180000 |
| `finish_live_round` | `p_live_round uuid, p_cards jsonb, p_casual bool default false, p_result jsonb default null` | jsonb | auth | Post the cards as real rounds, settle the game, board story + settlement post. | 20260729120000 |
| `abandon_live_round` | `p_live_round uuid` | jsonb | auth | Starter/player abandons. | 20260717050000 |
| `live_round_card` | `p_live_round uuid` | jsonb | auth | The finished sheet (players or league-mates). | 20260729120000 |
| `my_visitor_rounds` | — | jsonb | auth | Rounds the caller is a known guest in (RLS can't show them). | 20260728220000 |
| `_live_member_can` / `_live_state_of` | `p_live_round uuid` | boolean / jsonb | none | Internal guards/builders. | 20260728220000, 20260728120000 |

### 2.7 Events (the Ryder, the Major)

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `create_event` | `p_name, p_starts_on date, p_sessions int, p_session_weeks int, p_draw_rule, p_team_a, p_team_b, p_league default null, p_tz default null, p_lineage default null` | uuid | auth | A Ryder (must start Sunday). | 20260724100000 |
| `create_major` | `p_name, p_final_on date, p_days default 4, p_buy_in default 0, p_pot_split default 'places', p_league, p_tz, p_lineage` | uuid | auth | A Major window. | 20260724100000 |
| `add_event_player` / `set_event_team` / `invite_golfer` | … | uuid / void / uuid | auth | Organizer roster tools. | 20260720193000, 20260713120000 |
| `enter_major` | `p_event uuid` | uuid | auth | Self-serve entry for league-attached Majors. | 20260720193000 |
| `set_event_notify` | `p_event uuid, p_on bool` | void | auth | Opt in to duel taunts. | 20260716160000 |
| `generate_pairings` / `resolve_session` / `open_major` / `settle_major` | `p_session uuid` | int / void / void / void | auth (organizer-gated; cron passes with null uid) | Session lifecycle. | 20260727200000, 20260727180000, 20260720193000, 20260727160000 |
| `event_session_targets` | `p_session uuid` | table(duel_id,a_pvi,b_pvi) | auth | The number to beat in open duels. | 20260716150000 |
| `major_leaderboard` | `p_event uuid` | table(player_id,profile_id,display_name,marker,exhibition,round_id,gross,pvi,cards,best_posted_at) | auth | Gated live board. | 20260720193000 |
| `event_lineage` | `p_event uuid` | table(event_id,name,kind,status,starts_on,year,is_current,champion,champ_gross,champ_pvi,winner_slot,winner_team,winner_shared) | auth | The chain of editions. | 20260724100000 |
| `delete_event` | `p_event uuid` | void | auth | Organizer scraps an unscored event. | 20260720214500 |
| `is_event_member` / `is_event_organizer` / `is_event_league_member` | `p_event uuid` | boolean | auth | RLS helpers. | 20260713120000, 20260720193000 |
| `award_event_trophies` | `p_event uuid` | void | auth (vestigial) | Mint event trophies. | 20260720193000 |
| `run_event_sessions`, `major_board`, `major_contender`, `major_final_day`, `major_post`, `event_post`, `lineage_root`, `mj_money`, `mj_vs`, `nth_up`, `evhalf` | … | … | none / auth (helpers) | Cron tick + internal voice/board helpers. | 20260720193000, 20260716160000, 20260724100000 |

### 2.8 Ops / founder sandbox / email

| Function | Args | Returns | Grant | Purpose | Migration |
|---|---|---|---|---|---|
| `submit_feedback` | `p_category, p_body, p_context jsonb default '{}'` | uuid | auth | In-app feedback. | 20260714160000 |
| `sandbox_find` / `sandbox_arm` / `sandbox_week` / `sandbox_advance` / `sandbox_rewind` / `sandbox_reshape` / `sandbox_scrap` | `p_league …` | jsonb/uuid | auth (**founder-only in body**) | D65 rehearsal league with bots and a time dial. | 20260724170000 … 20260724210000 |
| `assert_sandbox` | `p_league, p_need_flag` | void | none | Shared founder gate. | 20260724170000 |
| `season_email_payload` | `p_season uuid` | jsonb | auth (service_role uses it) | Composes the recap email facts + per-recipient token. | 20260727240000 |
| `mark_email_sent` / `mark_cancellation_sent` | `p_id uuid, p_error default null` | void | none (service_role only) | The sender marks its work done. | 20260725140000, 20260726100000 |

---

## 3. Triggers

All on `public` unless noted. Every trigger function is SECURITY DEFINER except `rounds_no_future` (invoker).

| Trigger | Table / timing | Function | What it does | Migration |
|---|---|---|---|---|
| `rounds_before_insert` | `rounds` BEFORE INSERT | `score_round()` | Fills `profile_id`, computes `differential` (9-hole doubled), snapshots `index_at_post` from caller → profile → engine → own differential; never a blind 18. | 20260711190000 (repoint), body 20260716100000 |
| `rounds_no_future_trg` | `rounds` BEFORE INSERT/UPDATE | `rounds_no_future()` | Rejects `played_on > current_date + 1`. | 20260718174500 |
| `rounds_after_insert` | `rounds` AFTER INSERT | `round_to_board()` | Fans a `kind='round'` post to every league the profile belongs to ("Jerecho posted 92 at Encanto GC."). | baseline, body 20260727160000 |
| `trg_round_moments` | `rounds` AFTER INSERT | `round_moments()` | PR / first-round / barrier / streak "moment" posts + achievements. | 20260715234500, body 20260727160000 |
| `trg_squad_lead_moments` | `rounds` AFTER INSERT | `squad_lead_moments()` | Lead-change moments; maintains `season_lead`. | 20260716000000, body 20260716200000 |
| `round_refresh_index_trg` | `rounds` AFTER INSERT | `round_refresh_index()` | Recomputes `profiles.index_current` from scores; announces the handoff from a manual starter. | 20260716100000, body 20260716120000 |
| `round_duel_nudge_trg` | `rounds` AFTER INSERT | `round_duel_nudge()` | Opt-in Ryder taunt: inserts `push_nudges` for the opponent. | 20260716160000 |
| `round_major_story_trg` | `rounds` AFTER INSERT | `round_major_story()` | Major-window narration (first card / improvement / clubhouse lead). | 20260720193000 |
| `sched_major_story_trg` | `scheduled_rounds` AFTER INSERT | `sched_major_story()` | "Booked inside the window" story. | 20260720193000 |
| `event_complete_award` | `events` AFTER UPDATE | `trg_event_complete()` | On status → complete, `award_event_trophies`. | 20260713200000, body 20260716160000 |
| `seasons_email_on_complete` | `seasons` AFTER UPDATE OF status | `season_email_on_complete()` | On → complete (non-sandbox), enqueue `email_queue (season_recap)`. | 20260725140000, body 20260725180000 |
| `trg_tag_founder` | `profiles` BEFORE INSERT/UPDATE OF email | `tag_founder()` | Sets `is_founder` for the owner's email. | 20260714220000 |
| *(auth schema)* `on_auth_user_created` (name presumed) | `auth.users` AFTER INSERT | `handle_new_user()` | Creates the `profiles` row. **Not in any migration** — pre-repo, dashboard-created. | baseline (function only) |

Dropped: `rounds_before_insert → rounds_compute()` (replaced 20260711190000).

---

## 4. pg_cron jobs

`pg_cron` is created in 20260712110000 (`create extension if not exists pg_cron`). Schedules are UTC; Phoenix has no DST. `tests/db-checks.sql` check 1 asserts ≥4 active jobs.

| Job name | Schedule (UTC) | Phoenix | Command | Migration |
|---|---|---|---|---|
| `cs-month-close` | `10 7 1 * *` | 1st @ 00:10 | `select public.run_month_closes()` | 20260712110000 |
| `cs-week-snapshot` | `10 7 * * 0` | Sun @ 00:10 | `select public.run_week_snapshots()` | 20260712110000 |
| `cs-daily-tick` | `20 7 * * *` | daily @ 00:20 | `select public.daily_season_tick()` | 20260712110000 |
| `run_event_sessions` | `15 7 * * *` | daily @ 00:15 | `select public.run_event_sessions()` | 20260716150000 |

Cron runs as `postgres`; every engine function has EXECUTE revoked from anon/authenticated (20260718172300 C3), so `auth.uid() is null` inside them means "cron", which is what the organizer guards in `generate_pairings` / `resolve_session` / `open_major` rely on.

---

## 5. Database Webhooks **[dashboard — not in repo]**

Webhooks are created in the Supabase dashboard, never in migrations; they cannot be verified from this session (wrong MCP project). CLAUDE.md's rule: verify the TARGET from `pg_trigger` (`pg_get_triggerdef`, masking `x-push-secret`). Expected set, from the Edge Function headers and migration ops notes:

| Table · event | Target Edge Function | Auth | Source of truth |
|---|---|---|---|
| `posts` INSERT | `push` | header `x-push-secret` | `push/index.ts` header; 20260711170000 |
| `friendships` INSERT, UPDATE | `push` | `x-push-secret` | `push/index.ts` header; 20260712010000 |
| `push_nudges` INSERT | `push` | `x-push-secret` | 20260716160000 ops note; 20260728180000 |
| `email_queue` INSERT | `season-email` | `x-push-secret` | `season-email/index.ts`; 20260725140000 |
| `cancellation_notices` INSERT | `season-email` | `x-push-secret` | 20260726100000; `season-email/index.ts` D71 branch |

Landmine on record: the `season_email` hook was once created pointing at `push`, which answered 200 `ok` to the unknown payload. Both functions now log every invocation and never return a bare `ok`.

---

## 6. Edge Functions (`supabase/functions/*`)

All are Deno; `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` are auto-provided. Deploy with `supabase functions deploy <name>` (owner runs it).

| Function | Trigger | Auth | Inputs | Outputs | Secrets | Notes |
|---|---|---|---|---|---|---|
| `courses` | client POST | platform `verify_jwt` **plus** `auth.getUser()` (rejects the bare anon key) | `{action:"search", q}` (≥3 chars) or `{action:"cache", id}` | `{courses:[{id,club_name,course_name,city,state,tees:[…no holes]}]}` / `{ok,id,from_cache?}`; errors `{error}` 400/401/429/502 | `GOLFCOURSE_API_KEY` | Per-user daily cap from `app_flags.courses.daily_per_user` (150) via `courses_usage`. Serve-always, background refresh after 180d. Writes `api_courses/_tees/_holes` with service role. |
| `weather` | client POST | JWT + `getUser()` | `{lat?, lon?, date:'YYYY-MM-DD', course_id?}` | `{ok:true, weather:{hi,lo,wind,summary,icon}}` or `{unavailable:true, reason}` (always 200 soft) | none (Open-Meteo is keyless) | 16-day window; 6h cache in `weather_cache`; resolves lat/lon from `api_courses` by `course_id`. |
| `scan` | client POST | JWT + `getUser()` | `{image: base64 or data-URI (1KB–8MB), media_type?}` | `{ok:true, scan:{course_name,date,par_row[18],players:[{name,holes[18],total,holes_sum,holes_read}]}}` or `{unavailable:true, reason}` (200) | `ANTHROPIC_API_KEY` | Model `claude-opus-4-8`, structured outputs. Fail-closed caps from `app_flags.scan` (kill switch, 5/day/user, 400/month global) reserved in `scan_usage` before spending. |
| `push` | Database Webhooks (posts / friendships / push_nudges) | `x-push-secret == PUSH_WEBHOOK_SECRET`; deployed `--no-verify-jwt` | webhook body `{type, table, record, old_record}` | `{ok, reason, …}` — reasons: `sent`, `no-record` (400), `friendship-no-op`, `empty-body`, `no-league-or-event` | `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`, `PUSH_WEBHOOK_SECRET`; optional `BREVO_API_KEY`, `BREVO_SENDER`; **APNs (dormant until set): `APNS_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID`, optional `APNS_TOPIC` (dflt `app.cupseason.ios`), `APNS_SANDBOX=1`** | Recipients: league members minus author, filtered by `notify_chat` (chat) / `notify_rounds` (round); event posts → event players; nudges → one profile. Sends Web Push to `push_subscriptions` (prunes 404/410) **then APNs to `device_tokens`** (ES256 JWT cached 45 min; prunes 410/BadDeviceToken/Unregistered). Payload `{aps:{alert:{title,body},sound:'default'}}` — no `url`/deep-link data, no badge, no `apns-collapse-id`. Web payload `url:'/'` hardcoded. Friend requests also email via Brevo. |
| `season-email` | Database Webhooks (email_queue / cancellation_notices) | `x-push-secret`; `--no-verify-jwt` | `{record}` (or bare row) | `{sent, failed}` / `{cancelled:true,…}` | `PUSH_WEBHOOK_SECRET`, `BREVO_API_KEY`; optional `BREVO_SENDER`, `APP_URL` | Calls `season_email_payload` (service role), sends one HTML email per recipient with `/?unsub=<token>`, then `mark_email_sent` / `mark_cancellation_sent`. |
| `test-seed` | POST (QA tool) | JWT + `getUser()` | `{action:"seed"|"reset"}` | `{ok, removed…}` / seed summary | none beyond auto | Builds/tears down a test world for the CALLER: 8 bots `@cupseason.test`, 4 leagues, rounds, friends, a Ryder. Uses `auth.admin.listUsers`. Not a product surface. |

**Not deployed / not in repo:** nothing Cup Season-specific exists beyond these six. (The MCP's `list_edge_functions` showed `bright-responder` and `casa-outbox` — those belong to the other project.)

---

## 7. RLS pattern summary

**Helpers (all SECURITY DEFINER, `search_path = public`, granted to authenticated):** `is_league_member(p_league)`, `is_commissioner(p_league)`, `my_member_id(p_league)`, `is_event_member(p_event)`, `is_event_organizer(p_event)`, `is_event_league_member(p_event)`, `can_see_round(p_round)`, `can_see_media(p_owner text)`. Policies are evaluated as the querying role, so these MUST stay executable by authenticated (20260721214500 re-grants every `is_*`/`can_*`/`my_*` pattern-wide) — a missed helper grant breaks every SELECT behind its policy.

**Posture (D37, 20260718172300 → 20260727220000):**
- `anon` holds **zero relation privileges** in `public` (tables, views, sequences, columns, default ACLs). It reaches the database only through the **10 anon SECURITY DEFINER endpoints**: `claim_round_info`, `scan_claim_info`, `league_by_code`, `founder_id`, `share_info`, `join_covenant_info`, `email_unsubscribe`, `guest_live_state`, `guest_live_set_score`, `guest_live_set_wolf`. (CLAUDE.md still says "seven" — the guest trio was added in 20260728120000; `db-checks.sql` check 2 and `rpc.ts` `anonCallable` say ten.) The seal migration (20260727220000) RAISES if any relation still carries an anon/PUBLIC grant.
- `authenticated` keeps the baseline `GRANT ALL ON TABLE` on the 32 baseline tables (RLS filters rows), plus explicit `grant select` on `trophies`, `event_major_cards`, `forfeits`, `season_payouts`, `v_event_scoreboard`, and column-wise on `profiles`.
- **`profiles.email` is sealed**: table-level SELECT revoked, then SELECT granted per column for every column except `email` (20260721214500). **Any new `profiles` column needs its own `grant select (col)`** or every select naming it fails 42501 (check 9). Clients read the email from the auth session, never the table.
- Default privileges no longer auto-grant EXECUTE to anon/authenticated (`alter default privileges for role postgres … revoke execute on functions`), so every new client RPC needs `revoke all … from public, anon; grant execute … to authenticated`. A function that "silently 403s" (PostgREST 404/403 on `/rpc/name`) is almost always a missing grant.
- **Writes with game consequences go through SECURITY DEFINER RPCs.** The only direct client writes still allowed by policy: `rounds` INSERT (own `profile_id`), `round_holes` INSERT (own round), `posts` INSERT of `kind='chat'` (own member), `post_comments` INSERT, `post_kudos` ALL, `client_events` INSERT, `push_subscriptions` own-row CRUD, `scheduled_rounds` own-row (`sched_own`), `league_settings` UPDATE by the Pro while unlocked, `leagues` INSERT/UPDATE by commissioner, plus a few legacy tables (`invites`, `feedback`, `commissioner_log`, `buy_ins`, `squads`, `squad_members`, `drafts`, `season_adjustments` INSERT by commissioner). Killed and never to return: `members_self` (self-promotion) and `rounds_owner_update` (rounds are immutable).
- **Read-policy shapes:** league-scoped (`is_league_member(league_id)`: leagues, seasons, settings, members, posts, live_rounds, buy_ins, squads, adjustments, commissioner_log); event-scoped (`is_event_member or is_event_league_member`); profiles readable to self, league-mates and event-mates (the `profiles_read using (true)` policy was dropped); rounds readable to owner + league-mates; own-row (trophies, push_subscriptions, pilot_feedback, season_payouts); `using (true)` for reference data (`api_courses/_tees/_holes`, legacy `courses/*`, `app_flags`, `weather_cache`).
- **Mutes are enforced in the policy**: `posts_read` and `comments_read` exclude authors the viewer muted (20260722013000), so realtime inserts are filtered too.
- **RLS enabled with NO policies (definer-only tables):** `mutes`, `device_tokens`, `email_prefs`, `email_queue`, `shares`, `push_nudges`, `scan_claims`, `scan_usage`, `courses_usage`, `content_reports`, `achievements`, `season_lead`, `league_cancellations`, `cancellation_votes`, `cancellation_notices`, `member_invites` (read policies only), `live_scores` (privileges revoked outright).
- **Views** reachable by an API role must be `security_invoker` (check 11; 20260725210000 closed the last one).

---

## 8. Storage buckets and path conventions

| Bucket | Public | Limits | Paths | Policies | Migration |
|---|---|---|---|---|---|
| `media` | **private** | 8 MB; `image/jpeg`, `image/png`, `image/webp` | `{auth.uid()}/…` — round photos (`rounds.photo_path`), scorecard scans, and the avatar at `{uid}/avatar.jpg` (`profiles.photo_path`) | `media_read`: authenticated AND `can_see_media(first folder)` (self / league-mate / accepted friend); `media_insert` / `media_delete`: own prefix only. Reads are **signed URLs** minted client-side; a non-visible path fails to a broken image, not an error. | 20260718045514, 20260718173100, 20260718174500, 20260723150000 |
| `shared` | **public** | 2 MB; `image/jpeg`, `image/png` | flat `shared/{share token}.jpg` (photo copy) / `.png` (settlement card) — the token is the only id in the URL (D57) | `shared_copy_insert`: only onto your own live token's name; `shared_copy_delete`: your own token's copy; `revoke_share()` deletes the copy server-side. Anyone can GET the public URL. | 20260723210000, 20260729060000 |

`storage.objects` policies are the only storage-schema objects in the migrations; there is no `storage.buckets` policy work beyond the two inserts/updates above.

---

## 9. Realtime

Publication `supabase_realtime` (baseline + 20260711210000): `draft_picks`, `drafts`, `live_round_players`, `live_rounds`, `live_scores`, `post_comments`, `post_kudos`, `posts`.

- `posts` must stay in the publication (chat / board updates depend on it). `postgres_changes` respects RLS, so muted authors never arrive.
- `live_scores` is in the publication but delivers nothing to `authenticated` (table privileges revoked, no read policy — 20260728120000). Live scoring sync is **Realtime broadcast** on a channel named by `live_rounds.join_code` (an unguessable 64-hex string returned by `start_live_round`) + the `live_set_*` RPCs + `live_state` reconcile. Guests without an account use the same broadcast plus the `guest_live_*` RPCs keyed by `claim_token`.
- **Client rule (landmine):** channels live on a DEDICATED Supabase client (`rtClient`), never the one serving queries and auth; forward tokens via `bindRealtimeAuth(rt)(accessToken)` on every auth change (`packages/db/client.ts`). Keep a subscribe-status breadcrumb — `CHANNEL_ERROR — transport failure` on the busy client is the documented failure.

---

## 10. Deploy skew and the retry rule

Two deploys, independent: `supabase db push` (database) and `git push` (web client via Netlify); a native build is a third, slower cadence (App Store), which makes skew the norm rather than the exception.

- **Server side:** new RPC params default (`… default null`), new columns are nullable, and functions are written so the old client + new DB and new client + old DB both stay whole (e.g. `share_info` `holes`, `tour_card` `beat`, `search_golfers` 1-char).
- **Client side:** `packages/db/client.ts` `call(db, fn, args, { skewOptional: [...] })` — if the first call fails **for any reason** and any `skewOptional` arg was supplied, drop those args and retry once; a second failure throws `RpcError` (`fn`, `cause`, `droppedArgs`). **Never sniff the message**: the `photo_path` column-grant miss surfaced as 42501 "permission denied for table profiles" with no column named.
- Which args are skew-optional: any arg with a SQL default added after the function first shipped (e.g. `declare_round.p_course_id`, `set_profile.p_photo_path`, `create_event.p_lineage`, `report_content.p_kind/p_profile`, `start_live_round.p_config`, `finish_live_round.p_casual/p_result`). `packages/db/rpc.ts` marks them `?`.
- Preflight check 11 compares client RPC names to `contract.psv`; a name present in a migration but not the snapshot is a WARN = "you owe a `db push`". Refresh `contract.psv` after every function-touching push (query in its header), then `node tools/build-db.mjs` to regenerate `rpc.ts`.
- A native client should treat **PostgREST 404 on `/rpc/<name>`** ("function not found in schema cache") and **403/42501** identically: drop optional args, retry once, then surface. Store nothing derived from a failed first call.

---

## 11. Auth configuration facts

- **Email OTP, code-only.** `signInWithOtp({ email })` with NO `emailRedirectTo`; `verifyOtp({ email, token, type: 'email' })`. `packages/db/auth.ts` makes the link path unrepresentable (`requestEmailCode(client, email)` takes nothing else). Reason: Gmail's link scanner consumes single-use magic-link tokens before the user clicks.
- **Codes are 8 digits** in production (`OTP_LENGTH = 8`; never a `maxLength=6` input — preflight checks 5 and 13). Note: `supabase/config.toml` says `[auth.email] otp_length = 6`, but that file only configures a LOCAL stack; prod is set in the dashboard **[dashboard — not in repo]** and CLAUDE.md/auth.ts/preflight all assert 8. Resending invalidates the older code (the #1 "invalid code" cause; `humanAuthError` maps it).
- **SMTP: Brevo** behind Supabase Auth. Both "Magic Link" and "Confirm signup" templates render `{{ .Token }}` and contain NO `{{ .ConfirmationURL }}` **[dashboard]**. Local config: `enable_confirmations = false`, `double_confirm_changes = true`, `email_sent` rate limit 2/h (local only).
- **Signup trigger** (`handle_new_user`) auto-creates the `profiles` row with `display_name` from the email; gate onboarding on `profiles.marker`.
- **Providers:** `[auth.external.apple] enabled = false`; no OAuth of any kind; anonymous sign-ins off; MFA off. Spec guardrail (`spec/native-arc.md`): "Email OTP only. Adding a third-party login obliges Sign in with Apple." — email-OTP-only is what keeps Sign in with Apple optional under App Store 4.8.
- **Tokens:** `jwt_expiry = 3600`, refresh-token rotation ON with 10s reuse interval (local; assume the same in prod). Native app: Keychain storage (chunked, `AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY`), `detectSessionInUrl: false`, no custom `lock`, `startAutoRefresh()`/`stopAutoRefresh()` bound to `AppState` (`apps/mobile/src/supabase.ts`).
- **Never call a Supabase auth method synchronously inside `onAuthStateChange`** — wrap in `deferAuthWork` / use `onAuth()`.
- The publishable key is public (`sb_publishable_UoORp_…`, `apps/mobile/src/config.ts`); project URL `https://zddbfcokmvneltrgukzf.supabase.co`.
- Reviewer door: a hidden `signInWithPassword` path for one `reviewer@cupseason.app` account exists in the web client (ios-wrapper W3, survives D98); nothing server-side beyond a normal auth user.
- Universal links: `.well-known/apple-app-site-association` carries Team ID `3F7BK4WVH8`, bundle `app.cupseason.ios`, components for `/?claim=` and `/?join=` (query-scoped); served by Netlify; preflight check 9.

---

## 12. Backend gaps for iOS (honest assessment)

| # | Gap | Status today | What is needed | Severity |
|---|---|---|---|---|
| **G1** | **APNs sender** | **Built, dormant.** `push/index.ts` has a complete APNs HTTP/2 branch (token-auth ES256 JWT, sandbox switch, dead-token pruning) that is a silent no-op until `APNS_P8`, `APNS_KEY_ID`, `APNS_TEAM_ID` secrets exist. `device_tokens` + `register_device_token` / `unregister_device_token` are in prod. | Set the three secrets (B5). The APNs payload carries **no deep-link data, no badge, no `apns-collapse-id`, no `subtitle`, no `thread-id`, no `interruption-level`**; every push sounds `default`. Add a `data`/`url` field and a `kind` so the app can route (the web push also hardcodes `url:'/'`). `spec/share-copy-audit-2026-07-27.md` already proposes `subtitle` + gated sound. | Medium (works, but every notification lands on Home) |
| **G2** | **Push registration lifecycle** | `register_device_token` upserts by token and re-points it to the caller — good for a shared device. No `last_seen`, no per-token mute, no way to list the caller's own tokens. | Fine for B5 as-is. Consider a `platform in ('ios','android')` widening before Phase C (constraint is `('ios')` only). | Low |
| **G3** | **Sign in with Apple** | Not configured (`apple.enabled=false`), and deliberately so: email-OTP-only keeps SIWA optional under App Store 4.8. | Nothing — unless a social login is ever added, in which case SIWA becomes mandatory. Keep `requestEmailCode`'s signature as the guard. | None (decision) |
| **G4** | **A "home" / "what should this user do next" RPC** | **Does not exist.** `home_feed()` is a recent-rounds feed across the caller's circle. The web client assembles Home from ~10 reads: `my_invites`, `my_schedule`, `league_pulse`, `league_cancel_status`, `my_visitor_rounds`, live-round resume (RLS on `live_rounds`), `season_scenarios`, `home_feed`, `last_round_with`, plus direct table reads of `leagues/seasons/league_settings/league_members` and the standings views. There is no server-side notion of "your leagues + their phase + your role + the one action that matters". | A `native_home()` (or `me_bootstrap()`) definer RPC returning: profile (marker gate), leagues with phase/role/season status/days-to-final, pending invites count, live round to resume, today's scheduled rounds, floor status, unread-ish board counters. One round trip on cold start; the phone should not replay the web client's fan-out. | **High** for B1–B4 |
| **G5** | **Board / chat read API** | Reads are direct PostgREST selects on `posts` (+ `post_comments`, `post_kudos`) under RLS, joined client-side with `league_members`/`profiles` for names; there is no paginated `board(p_league, before, limit)` RPC and no unread cursor. Chat INSERT is a direct table insert. | Direct selects work from supabase-js on RN; a paginated RPC would cut joins. Not blocking. | Low–Medium |
| **G6** | **Standings read** | Views `v_squad_standings` / `v_individual_standings` / `v_rounds_ranked` are selectable by authenticated under RLS; receipts come from `round_card` / `round_epilogue`. No RPC wraps "standings for league X with names/markers". | Direct view selects are fine (B6). | Low |
| **G7** | **Course picking on the phone** | `courses` Edge Function is JWT+user-gated and rate-limited; `api_course_*` tables readable. `start_live_round` takes `p_course_id uuid, p_tee_id uuid` typed against the **legacy uuid `courses`** schema while the cache uses **text ids** (`api_courses.id`) — the web client passes nulls and puts everything in `p_snapshot jsonb` + `p_course_label`. | Mirror the web: send `course_snapshot` (par/SI/rating/slope per tee) and `api_course_id` text; treat the uuid params as vestigial. Document in `rpc.ts`. | Low (works, confusing) |
| **G8** | **Offline / background sync primitives** | LWW by `client_ts` is supported server-side (`live_set_score`, `live_set_wolf`, guest trio) and `live_state` returns a full reconcile payload. No batch endpoint: one RPC per hole per player. No idempotency key on `finish_live_round`. | Add `live_set_scores(jsonb[])` batch upsert for drain-on-resume (B3) and make `finish_live_round` idempotent per `(live_round_id)` (it locks the row but a retried call after a timeout is unverified). | Medium (B3 is the highest-risk milestone) |
| **G9** | **Grant hygiene the phone will inherit** | `close_month(uuid,date)` still shows `auth` in the live snapshot despite the 20260718172300 revoke (a later `create or replace` in 20260727160000 re-granted or the sweep loop re-granted it). Body is idempotent and season-scoped, but any member could trigger an early close of the previous month for a season they know the id of. Also several trigger functions and `award_event_trophies` carry vestigial `auth` execute grants. | A tiny migration: `revoke execute on function public.close_month(uuid,date) from anon, authenticated;` and the same for trigger/award functions; add them to check 3's expectations. Not an iOS blocker but the native client makes the surface easier to poke. | Medium (security tidy) |
| **G10** | **Photo upload from native** | Storage policies are prefix-based (`{uid}/…`) and work with any Supabase client; reads need signed URLs (private `media`). No image-resize/transform on the server; the web client compresses to JPEG before upload. | Compress on device (expo-image-manipulator) to stay under 8 MB/2 MB; mint signed URLs per render. `scan` accepts base64 ≤8 MB. | Low |
| **G11** | **Webhooks unverifiable from the repo** | The five Database Webhooks live only in the dashboard. | Before B5, run the `pg_get_triggerdef` check from CLAUDE.md against prod and record the result in the arc doc. | Low (process) |
| **G12** | **Telemetry blind spots** | `client_events` insert is authenticated-only; there is no error-reporting endpoint for a native crash, and no `app_version`/`platform` column convention. | Add `props.platform='ios'`, `props.build` by convention; consider a `client_errors` RPC or accept `client_events(event='error')`. | Low |
| **G13** | **Anon count drift in docs** | CLAUDE.md says "seven anon endpoints"; prod, `db-checks.sql` and `rpc.ts` say ten (guest live trio). | Update CLAUDE.md. | Doc |
| **G14** | **`declare_round` overload** | Two overloads exist in prod (5-arg legacy + 6-arg). Calling with named JSON args resolves fine; a positional caller could hit ambiguity. | Drop the 5-arg overload in a migration once the web client no longer needs it. | Low |
| **G15** | **No server "app version gate"** | Nothing tells an old native build it must update (the web client self-updates via the SW + stamped SHA). | An `app_flags.min_ios_build` key read on boot (table is already `flags_read using (true)`). Trivial, do it before TestFlight. | Medium (App Store reality) |

What the backend already has that iOS can use unchanged: the entire RPC surface (typed in `packages/db/rpc.ts`), auth/OTP through `packages/db/auth.ts`, storage policies, realtime broadcast for live rounds, `device_tokens` + APNs sender, `share_info` / claim / join funnels (anon), the season engine, and every trigger-driven board/story/achievement path (a round posted from the phone fans out identically).
