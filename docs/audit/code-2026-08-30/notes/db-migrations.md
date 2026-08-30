# Slice: `supabase/migrations/` (138 files) — line-by-line audit, 2026-08-30

## What I actually read

1. **Line by line, the two written this session** (`git log --oneline 34d20b6..HEAD`
   confirms these are the only two migrations in the session's commits):
   - `20260829220000_lock_league.sql` (136 lines, D111, commit `47b1cda`)
   - `20260830040000_buy_in_terms.sql` (93 lines, D129, commit `d41d2b7`)
2. **Every migration from 2026-08-20 onward**, in full or in the load-bearing
   function bodies: `20260826120000_unregister_device_token`,
   `20260827130000_close_month_revoke`, `20260827130100_ios_flags`,
   `20260827130200_handle_available`, `20260827130300_round_holes_of`,
   `20260827130400_native_home`, `20260827160000_pricing_flag`,
   `20260827170000_pricing_annual`, `20260827180000_founding_members`,
   `20260827190000_door_flags`, `20260827200000_league_look`,
   `20260827210000_push_wave7`, `20260828010000_device_token_env`,
   `20260828020000_register_device_token_platform`,
   `20260828030000_set_league_notify`, `20260828040000_nudge_payloads`,
   `20260828150000_profiles_server_owned`,
   `20260828150100_live_tables_participant_scoped`,
   `20260828150200_transfer_pro_and_live_played_on`,
   `20260828160000_growth_events`, `20260828170000_pot_two_numbers`,
   `20260828170100_cup_final_race`, `20260829090000_leagueless_live_rounds`,
   `20260829091000_weekly_clash`.
3. **Grep-driven sweeps across all 138**, cross-checked against the LIVE
   database with `supabase db query --linked` (read-only SELECTs only).
   Supporting reads outside the slice, for evidence: `v_rounds_ranked` /
   `cup_points` in the baseline, `index.html`'s `bandName`/`lockBylaws`/
   `openBuyInTerms`/`loadWatchList`, `spec/spec-v1.0.md` §15/§16,
   `spec/decision-log.md` D52/D88/D107.

## What the live database says (the sweeps that came back CLEAN)

These are worth recording as *verified*, because CLAUDE.md's own lesson is that
a grant assertion is worth nothing until something checks it.

| Sweep | Result |
|---|---|
| SECURITY DEFINER functions with no `set search_path` | **0** |
| Functions `anon` can EXECUTE | **exactly the 12** CLAUDE.md documents |
| Relations in `public` with any `anon` privilege | **0** (D37 holds) |
| The 107 RPCs `index.html` calls vs. `authenticated` EXECUTE | **all 107 granted** |
| Views granted to `authenticated` with RLS off | 4, and **all 4 carry `security_invoker=true`** (`v_event_scoreboard`'s flip is in `20260725210000`, so a rebuild-from-migrations reproduces it) |
| Definer functions `authenticated` can call with **no** identity check | 24 hits, of which 12 are the anon token endpoints, 8 are trigger functions (not PostgREST-reachable), 3 are founder-gated via `assert_sandbox` — **and one is a real hole** (below) |
| `20260829220000` / `20260830040000` applied in prod | **yes** (`schema_migrations` top row is `20260830040000`) |
| Leagues with no `league_settings` row | **0 of 18** |

## `lock_league` — the four questions the brief asked

**Atomic?** Yes. One plpgsql body = one transaction: settings UPDATE, season
INSERT, `form_squads`, `leagues.phase` UPDATE all commit or none do. The
failure mode it was written to kill — four client writes with a client-side
exception between them — is genuinely gone.

**Idempotent?** Yes on the live path. The `locked_at is not null` guard returns
the standing season and phase. I traced the concurrent double-tap too: T2's
UPDATE blocks on T1's row lock, and under READ COMMITTED T2's subsequent
`select … from seasons where number = 1` sees T1's committed row, so no second
season is minted and `form_squads`'s `if exists (select 1 from squads …)` early
return holds. The one thing T2 *does* do is rewrite the bylaws (see O-2).

**Can a non-Pro reach it?** No. `is_commissioner(p_league)` is checked in the
body before any write, and the grant is `authenticated` only with the explicit
`revoke … from public, anon` (verified live).

**Can a caller drive the league into a state §15 forbids?** No — and this is the
part that is genuinely well built. §15's rule is "season can't start with
unassigned members", and the prod casualty was `structure=squads2` +
`phase=season` + two empty squads. `lock_league` derives the phase from the
**stored** structure (`v_settings.structure`, not `p_structure`), so a
mis-sent structure cannot produce that pair. Every free-text bylaw is
CHECK-constrained at the table (`league_settings_structure_check`,
`_preset_check`, `_verification_check`, `_season_format_check`,
`_floor_penalty_check`, `_handicap_allowance_check`, `draft_type_valid`,
`finish_check`) and the payout split is guarded by `payout_sums_100` — so a
hostile payload raises and rolls back rather than landing a bad league. I
looked specifically for a missing payout-sum check and it is there.

Two real gaps remain, neither reachable today: the settings UPDATE never checks
`FOUND` (B-11 / O-1), and `coalesce(p_counting_cap, counting_cap)` makes "no
cap" unrepresentable through the RPC (B-11).

## `set_buy_in_terms` / `join_covenant_info`

Clean. The commissioner gate is in the body; the 140-char cap is enforced
server-side, not just in the input's `maxlength`; `join_covenant_info` correctly
keeps its `jsonb` return type (a `create or replace` cannot change one) and
exposes only `has_pay_note` + `buy_in_due_on` to anon, never the note — which is
the right call, since a league code travels. One latent footgun: both
parameters default null and both are written unconditionally, so any future
caller that saves the note alone silently erases the due date (O-4).

## The findings, in order of what would hurt

**B-1 · `season_email_payload` is granted to `authenticated`.**
`20260727240000_name_resolution.sql:123–124` re-granted a service-role-only
function that two earlier migrations had explicitly revoked from
`authenticated`. It is SECURITY DEFINER, has no caller check at all, and its
`recipients` array is `{email, name, token, cents}` for every member of the
league. `profiles.email` is column-sealed precisely so members cannot read each
other's addresses; this function walks straight past that seal. The `token` is
worse than the email — `email_unsubscribe(uuid)` is anon-callable, so a
harvested token lets you unsubscribe your league-mates. Live ACL confirmed:
`authenticated=X/postgres`, `prosecdef=true`.

**B-2 · `declare_round` and `retag_round` disagree about who you may tag.**
`retag_round` caps the array at 7 and rejects anyone who is not a buddy or a
league mate. `declare_round`, which creates the same `tagged` array and fans the
same `push_nudges`, has neither check — and `p_course` has no length cap (only
`p_note` does). One RPC call ⇒ a push notification carrying attacker-authored
text to every profile id you can name. Two functions, one rule, and they
disagree.

**B-3 · Anyone can post a scoring round onto a stranger's profile.**
`start_live_round` accepts `guest_profile` as raw text→uuid with no
relationship check; `finish_live_round` then inserts a `rounds` row with
`profile_id = guest_profile_id`, `attested = true`. Rounds are immutable (§16);
the round feeds their WHS-lite index and fans to their leagues' boards. D107 §4
*decided* the auto-post, and I am not calling that a bug — the bug is that
D107 assumed the seated golfer was someone you seated by @handle or buddy, and
nothing enforces it. `search_golfers` hands any signed-in user the profile id of
any `discoverable = 'everyone'` golfer.

**B-4/B-5/B-10 · The UTC-midnight landmine, three live instances.**
I confirmed against prod: `current_setting('TimeZone')` is `UTC`, and at the
moment of the audit `current_date` = `2026-08-30` while
`(now() at time zone 'America/Phoenix')::date` = `2026-08-29`. So for seven
hours a day, every `current_date` in a league-facing expression is tomorrow:
- `native_home()` builds the phone's tee sheet from `my_schedule(current_date, +14)`
  while the web builds the identical window from the browser's local date —
  today's round disappears from the phone at 17:00 Phoenix;
- `league_pulse()` buckets floor credits by `date_trunc('month', current_date)`
  — on the last evening of a month the floor surface reads the *next* month's
  (empty) credits, exactly when a member is checking whether they made it;
- `declare_round` rejects `p_play_on < current_date`, so after 17:00 Phoenix you
  cannot schedule a round for tonight.
The codebase already knows the right idiom — `settle_week_clash`,
`open_week_clash` and `finish_live_round` all use
`(now() at time zone se.timezone)::date`. `cup_final_race.days_left`,
`enter_cup_final`'s window guard and `round_duel_nudge`'s "closes tonight" carry
the same skew at lower stakes.

**B-6/B-7 · The weekly clash's band ladder is a third copy of a rule that has
two producers already.** `settle_week_clash` decides the W on `points` but
labels the receipt from a hand-rolled pvi ladder. `v_rounds_ranked` halves
`points` for a 9-hole round and does **not** halve `pvi`, so two rounds can
carry the identical band label and different points: an 18-hole +1.5 is 9
points, a 9-hole +1.5 is `ceil(9/2)` = 5. The board then announces
"X TOOK THE WEEK" between two cards that both read "Beat your number" — the
exact thing the migration's own header promises cannot happen ("equal bands are
ALL SQUARE"). Separately the ladder's `pvi >= -1` boundary contradicts
`cup_points`'s `pvi > -1`; the client's `bandName` was fixed to the half-open
form *this session* (Q-20, `index.html:5805`), so the new SQL shipped the bug
the client had just removed.

**B-8 · A member can author a `kind='system'` board post.**
`finish_live_round`'s match branch concatenates `p_result->>'side_a'`,
`side_b` and `status` — raw caller text, no length cap — into `posts.body`,
while the wolf/skins branch on the very next line does `left(story, 200)`.
`posts.body` has no CHECK. The client escapes post bodies (`esc()` at
`index.html:12994`), so this is spoofing and spam, not XSS.

**B-9 · `transfer_pro` logs the wrong actor.** `actor_id = p_member` — the
person who *received* the shop. Every other `commissioner_log` insert in the
repo passes `my_member_id(...)`. The `detail` json still carries `from`/`to`, so
the truth is recoverable, but a filter on "what did this Pro do" attributes the
handover to the wrong person.

## Opportunities

- **O-1** `lock_league`'s settings UPDATE never checks `FOUND`. With no
  `league_settings` row the UPDATE matches nothing, `v_settings` goes all-NULL,
  `locked_at` is never written, `v_settings.structure <> 'solo'` evaluates NULL
  (so `form_squads` is skipped), and the function returns
  `already_locked: false, phase: 'draft'` — reporting success over a half-lock,
  the precise failure class it exists to kill, and not idempotent on retry
  because `locked_at` never landed. Zero of 18 prod leagues can reach this
  today; one `if not found then raise` makes it unreachable forever.
- **O-2** `lock_league` reads `locked_at` without `for update`. Two overlapping
  calls both see NULL and both write the bylaws, so the second overwrites an
  already-locked league — past the `settings_write` policy's
  `locked_at IS NULL` rule. `select … for update` on the settings row closes it.
- **O-3** `native_home()` wraps 14 sub-reads in `exception when others`. The
  profile one is the dangerous one: a 42501 from the frozen profiles
  column-grant list becomes `profile: null`, and the phone's own contract says
  that means "show the card gate". The next profiles column added and read here
  without `grant select (col)` re-onboards every phone user *silently* — the
  photo_path incident with the error removed. Catch `no_data_found` there, or
  let 42501 through.
- **O-4** `set_buy_in_terms` writes both columns unconditionally from two
  null-defaulted parameters; a caller that saves only the note erases the date.
- **O-5** One producer for the band ladder. `cup_points(pvi)` owns the points;
  a sibling `band_name(pvi)` in SQL, generated into the client and Swift the way
  `Markers.swift` and `Rpc.swift` already are, would have made B-6 and B-7
  impossible. Three copies exist today (`cup_points`, `index.html:5802`,
  `settle_week_clash` ×2).
- **O-6** `log_growth_event`'s "≤20 rows per token per hour" fence is inside
  `if v_tok is not null`. A signed-in caller passing no token is unlimited.

## What I could not assess

- The ~110 migrations before 2026-08-20 were covered only by the grep sweeps
  and the live-database checks above, not read line by line. The sweeps were
  chosen for the landmine classes the brief names (grants, `search_path`,
  anon reach, `current_date`, swallowing handlers, `security_invoker`), so a
  logic bug in an older migration that none of those patterns touch would not
  have surfaced.
- I did not execute any RPC. Every "an attacker can" claim is read from the
  function body plus a live ACL/constraint check, never from an actual call.
- `push` / `season_email` Edge Function behaviour (whether a `push_nudges` row
  actually reaches a device) is outside this slice; B-2's severity assumes the
  webhook is wired as CLAUDE.md describes.
