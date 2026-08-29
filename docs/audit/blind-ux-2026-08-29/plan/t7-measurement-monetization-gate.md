# T7 — Measurement, the re-audit gate, monetization prerequisites (+ housekeeping)

*Remediation plan for takeaway 7 of the blind UX audit (2026-08-29), plus the audit's own housekeeping. Every file:line below was re-checked against the working tree at `34d20b6` (== prod, == HEAD). This document is a PLAN — no product file, migration, spec or decision-log line has been edited.*

**What this theme owns.** (i) The instrumentation that proves the other six themes' fixes worked, where each event fires, the views that read them, and the one alert that would have caught TOP-1 in a day instead of 25. (ii) The re-audit gate: which blind persona journeys re-run after each remediation phase, the pass criteria, who runs it, and the harness as a repo tool. (iii) Monetization prerequisites: blind-ux-audit §9's seven "must happen first" items as a checklist with a metric behind each, gating the `app_flags.pricing.visible` flip and D101's season-pass checkout. (iv) Housekeeping: the prod test-footprint wipe (corrected SQL, cascades, RESTRICT FKs, a hard deadline), whether/how to commit `docs/audit`, preflight additions (no-undef lint, the lock test, an event registry, a no-PII check), the "season-start lint", and where the harness lives.

**What this theme does not own.** The fixes themselves. T7 measures TOP-1…TOP-5; it does not build `lock_league` (T1), the invite artifact (T1/T2), the member Home (T3), the pre-season rule (T4), the endgame surfaces (T5) or the pot path / D101 copy (T6). Where an event has to fire from a surface another theme is building, the name and the props are defined here so the two land compatible.

---

## 0. Baseline — what exists today (verified)

**Two tables, two writers, one desk.**

| Layer | What | Where | Notes |
|---|---|---|---|
| `client_events` | signed-in breadcrumbs, `{profile_id default auth.uid(), event ≤64, props jsonb, created_at}`; RLS `ce_insert_own` (INSERT only, `authenticated`); unreadable via API; cascades with the profile | `supabase/migrations/20260717153000_pilot_instrumentation.sql:19–37` (D33) | Signed-out sessions are blind here by design. |
| `qaEvent(event, props)` | the web writer — fire-and-forget insert, demo never emits, failures swallowed; bridged as `window.qaEvent` for the module block | `index.html:6225–6238` | Module-block callers must use `window.qaEvent?.()` (classic↔module boundary). |
| `CSTelemetry.event(name, props)` | the phone's one writer into `client_events`, 2-second dedupe; five IOS-024 product events `signed_in · card_set · league_created · league_locked · round_posted` | `apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Telemetry.swift:20–56`; `docs/ios/reliability.md:93–113` | **Drift already exists:** the web fires `league_create` / `lock_ok`, the phone fires `league_created` / `league_locked` for the same moments. `WizardService.Event` (`Wizard/WizardService.swift:28`) mirrors the web's five wizard names, so the phone writes BOTH vocabularies. |
| `growth_events` | the anon-safe funnel, five nodes `artifact_shared → link_opened → claim_started → profile_created → first_round_posted`, kinds `share/claim/join/recap/settlement`; zero relation privileges for API roles; written only by `log_growth_event()` (fail-closed, ≤20 rows/token/hour, PII keys stripped); `v_growth_funnel` week × kind × league, founder/service-role read only | `supabase/migrations/20260828160000_growth_events.sql` | The join funnel is ALREADY instrumented end to end on both clients: `artifact_shared(join)` at `index.html:14119` and five iOS tap sites; `link_opened(join)` at `:17820` / `CupSeasonApp.swift:30`; `profile_created` at `:13186` / `CardGateView.swift:227`. What it cannot see is the accept itself (the `join_league` success) — that is a fact in `league_members.joined_at`, not an event. |
| `growthEvent(node, kind, token, props, league)` | the web growth writer | `index.html:6246–6254` | |
| `CSGrowth.log(...)` | the phone growth writer | `Growth.swift:23–66` | |
| `founder_desk()` | one jsonb snapshot: counts, newest cards, **client_events · last 30**, feedback, reports; founder-gated by `founder_id()` | `supabase/migrations/20260721191500_founder_desk.sql:39–83`; render `index.html:15668–15705`; iOS `apps/ios/CupSeason/Settings/FeedbackSheet.swift:150–166` | No funnel arithmetic — the desk shows the last 30 raw rows, which is how eleven `lock_fail` rows in two minutes read as noise. |
| `v_pilot_gates`, `v_post_timings` | gates 1–3 per member (signup → card → first league → first round; post composer seconds) | `20260717153000:44–90` | Founder-only; still the right source for time-to-first-round. |

**The web's current event vocabulary** (every `qaEvent(` / `qaEvent?.(` in `index.html`): `client_error` (:3686, :3695) · `post_open` (:4179) · `content_reported` (:4985) · `home_hero_tap`, `home_hero_state` (:9999–10000) · `home_occasion_tap` (:10260, :10271) · `post_mode_switch` (:6404) · `post_even_par_confirmed` (:6475) · `round_holes_fail` (:6548) · `post_submit` (:6554) · `invite_open` (:14139, inside `openLockShare`) · `league_create` (:15109) · `lock_attempt` (:15476) · `lock_blocked` (:15481) · `lock_ok` (:15495) · `lock_fail` (:15503).

**The lock funnel as it stands.** `#lockBtn` handler `index.html:15471–15506`: `lock_attempt` → `lockBylaws()` (`:15122–15219`, four committed writes at `:15127–15149`, `:15189–15196`, `:15203`, `:15211`) → throw at `:15218` (`staged.length`) → catch → `lock_fail {msg}`. `lock_ok` and `openLockShare` (`:15495–15501`) are unreachable. Prod (validators, read-only): `lock_ok` = 1 all-time (2026-07-27, pre-D97), `lock_attempt` = 12, `lock_fail` = 11 (all 2026-08-29, both audit organizers), `invite_open` = 1. The comment at `:14137–14138` — *"lock_ok without invite_open means the Pro locked and never shared"* — was the right question with nobody reading the answer. That is the whole case for (i).

**The season clock the housekeeping has to beat.** `lockBylaws` inserts `seasons` with `status` defaulting to `'active'` (`:15189–15196`; baseline `seasons_status_check`), so both audit leagues — The Papago Grind (`draft`, squads undrawn) and Desert Dogs (`season`, two empty squads, one member) — are picked up by `daily_season_tick()` (`20260829091000_weekly_clash.sql`, iterating `status in ('active','cup_final')`; kickoff branch inherited from `20260712130000:71–77`). pg_cron `cs-daily-tick` runs at **07:20 UTC daily** (`20260712110000_enable_cron_spine.sql:24`). On **2026-09-05 07:20 UTC** both leagues kick off (`kicked_off = true`, a "THE SEASON IS LIVE — WEEK 1" board post), the Sunday snapshot follows at 07:10 UTC on the 6th, and the D108 clash opens on the next tick. After kickoff, `delete_league` (`20260712230000:25–33`) refuses both. **The wipe (T7-14) has a deadline: before 2026-09-05 07:20 UTC.** (The README's line that `delete_league` *already* refuses Desert Dogs is not what the code says — it refuses once `kicked_off` or `starts_on <= current_date`, i.e. from Sep 5. Moot: the wipe is direct SQL.)

---

## (a) Decisions needed

Numbering: the log ends at **D110** (+ addendum, 2026-08-29). The entry below is written as **D111**; if another theme's entry is merged first, renumber at merge — the id in this document is provisional.

### D111 · The monetization gate — the pass becomes visible on evidence, not on a date — PROPOSED (talk first)
*(BUSINESS level (1–2). Refines D56 / IOS-021 / D101. Sources: blind-ux-audit §9; `app_flags.pricing` seeded `visible:false` by `20260827160000_pricing_flag.sql` and re-seeded by `20260827170000_pricing_annual.sql` (D101: `unit:"year"`, `$59/$89/$109`, `first_year_free`); the flip is a one-line SQL update (`docs/ios/pricing-surfaces.md:46`).)*

- **Current mechanic:** the visible pricing model exists on the phone behind `app_flags.pricing.visible = false`; the web has no pricing surface at all (`index.html` reads `app_flags` only for `scan`, `:6734`). IOS-021's trigger for the flip is *"the owner flips it after confirming the anchor"*; D101's trigger for checkout is *"the first real anniversary"*. Nothing else gates either.
- **Problem (audit):** twelve blind result rows put *would pay for another year* at a median **3.5/10** (range 2–5); the skeptic's own $79 justification is a sentence made entirely of built mechanics none of which he saw on the day he joined (§9). §9 lists seven things that must be true before pushing monetization; none of them is a condition anywhere in the product or the ops docs. A flip on the owner's judgement alone would put a price in front of the exact organizer who cannot lock a league today.
- **Recommendation:** the flip (and, later, D101's checkout) is gated by an **eight-item checklist, each item evidenced by a named metric from the funnel views this theme builds** (T7-12 has the table): (1) a real season has ended well — one league `complete` with `season_payouts` and its ceremony opened by ≥ half its members; (2) the race is visible all season — `endgame_seen` per member per month ≥ 1 and a `week_clashes` row on the next tick; (3) pre-season honesty — the T4 re-audit passes and `v_preseason_exposure` shows no league whose members posted pre-season rounds under a points promise; (4) the pot is true — D106 live, `collected = pot` for PIGL at close, a payment note set on ≥ 1 real league; (5) the invite works — `v_lock_health` 30-day `lock_fail = 0` with ≥ 3 `lock_ok`, and invite→accept ≥ 60% on ≥ 3 real leagues (GTM §1's roster-lock rate); (6) the price is stated where the buy-in is set, on both clients; (7) D56's focus-group deck has been run against those real surfaces (≥ 6 Pros) and the re-audit's *would pay* median is ≥ 5; (8) `pricing.founding.ids` names PIGL so no founding league is ever shown a price. Only then `update app_flags set value = value || '{"visible": true}'`. `tests/db-checks.sql` gains a guard (T7-13) so `visible:true` cannot precede (1) and (8) by accident. Stripe stays parked per D101.
- **Principle served:** "charge after proven value" (`spec/gtm-year1.md` §11, product-vision "Real Golf / Low Friction"); D56's own "the flag makes it a one-row change, not a rebuild" — the change should be a one-row change *made for a reason the numbers can show*; §16 applied to ourselves (D33's precedent: the verdict shows its work).
- **Benefit:** the price lands on a product that has demonstrated the sentence it is selling; the owner has a dashboard answer to "are we ready" instead of a feeling; a founding league cannot be surprised.
- **Tradeoffs:** delays revenue until at least one real season closes (PIGL's first close is the earliest date); eight conditions is a lot of process for a one-person company — mitigated by making every item a row on the founder desk and a `db-checks` line, not a meeting.
- **CONFLICT:** none upward. Amends IOS-021's trigger sentence ("after confirming the anchor" → "after the gate is green and the anchor is confirmed"); D101's dates and numbers untouched; D56's deck becomes gate item 7 rather than a prerequisite to build the surfaces.

### No new decision needed (and which decision each restores or extends)

| Change | Why no entry | Rides under |
|---|---|---|
| New `client_events` names (`invite_shared`, `covenant_seen`, `covenant_declined`, `covenant_skipped`, `joined`, `rules_open`, `endgame_seen`, `pot_mark`, `pot_mark_denied`, `post_submit.preseason`) | Same table, same privacy stance (timings, booleans, league ids and league codes — never a name, email or handle), same lossy-by-design posture. Observation, not a mechanic. | D33 (pilot instrumentation) · the 2026-08-28 growth instrumentation (`spec/claim-loop-instrumentation.md`) |
| Funnel / lock-health / pre-season views, `founder_desk()` v2 | Operator-only reads, revoked from API roles, the pattern `v_pilot_gates` and `v_growth_funnel` already set. | D33 · 20260721191500 (founder desk) · D37 grants discipline |
| The lock-health alert as a `push_nudges` row to the founder | Uses the existing nudge rail; founder-only recipient. | D104 (push that means something) · `20260716160000_ryder_slice3.sql` (`push_nudges`) |
| Preflight checks 18–20, `tests/rpc-smoke.sql`, `db-checks` 15–17 | Tooling. | CLAUDE.md "every check is a lesson the codebase already paid for" |
| The re-audit gate | QA process — belongs in `spec/prelaunch-qa-2026-07-13.md` as a sixth gate, not in the mechanics log. | `spec/prelaunch-qa-2026-07-13.md` §"The five gates" (D33 made gates 1–3 passive; gate 6 is the zero-instruction test, run blind) |
| Harness moved to `tools/blind/` | Tooling. | — |
| The test-footprint wipe | Ops. | CLAUDE.md deploy discipline (the owner runs mutating SQL) |

### D112 · (sketch, ONLY if the owner wants the default changed) The first tee defaults to a date the crew can reach
The "season-start lint" question in the brief: *is the default first tee (a week out) D-decided?* **No.** `defaultStart()` (`index.html:7237–7240`) returns the next upcoming Saturday (1–7 days out) with the comment "a natural first tee"; the only record is setup-QA **S2-01** (`spec/setup-qa-findings.md:43`), which flagged the Saturday default as a *bug against §14.0's Sunday start* — and §14.0 v1.1 then dropped the Sunday snap (flexible first-tee weekday; CLAUDE.md "Season shape"), which made the Saturday legal without ever deciding the horizon. D43 decides the *Major's* default (next Sunday), not the league's. So the 1–7-day pre-season window that made six of six audit first rounds score zero (TOP-4) is an accident of a comment, not a decision. T7 does not propose changing it — that is T4's mechanic territory and an owner call (open question 4). If the owner wants it changed, the entry reads: *current* next Saturday · *problem* every new league's first week is pre-season by construction and no surface says so · *recommendation* default = the Saturday ≥ 7 days out, with the wizard showing "first tee in N days — rounds before it build your number" · *principle* Low Friction, §14.0 · *tradeoff* the draw window gets longer · *CONFLICT* none (D40's "rules lock at first tee" unchanged). Until then T7 **measures** the exposure (`v_preseason_exposure`, T7-02) rather than changing the default.

---

## (b) Work items

Effort: S ≤ 2h · M ≤ 1 day · L multi-day. Deploys are the owner's (`./tools/ship.sh`; `supabase db push` confirmed by typing `push`). Migration filenames below use `YYYYMMDDHHMMSS_slug.sql` — stamp the real timestamp at creation, never edit after it runs.

### T7-01 · Web funnel events — the seven moments the audit could not count
- **Layer:** client (`index.html`) · **Effort:** S · **Issues:** M-001, M-003, M-017, M-023, M-025, M-110, M-040, M-055, M-054
- **Change.** Add `qaEvent` calls (module block: `window.qaEvent?.()`) at the moments below; props carry league ids, league codes and booleans only — never a name, email or handle (D33 stance; `log_growth_event` strips PII keys, `client_events` does not, so the discipline is the caller's).
  1. `invite_shared {via, league_id}` in `shareInvite()` (`:14114–14128`): `via:'share'` after `navigator.share` resolves (`:14121`), `via:'clipboard'` after `writeText` (`:14126`), `via:'toast'` in the double-fallback catch (`:14127`). The existing `growthEvent('artifact_shared','join',…)` at `:14119` stays (it is the cross-boundary node; this is the outcome).
  2. `covenant_seen {code, buyin}` after `openSheet` renders in `covenantGate()` (`:15428`); `covenant_declined {code}` in the `#covNo` handler (`:15438`); `covenant_skipped {code, reason:'no_info'|'no_stake'}` on the early `return true` (`:15425`) — this is the S3-01 hole TOP-2 names, counted.
  3. `joined {via, league_id}` after every successful `join_league`: `:15460` (`via:'door'`), `:15576` (`'welcome'`), `:17388` (`'switcher'`), `:17511` (`'boot'` — the path that skips the covenant, Appendix A #15), `:17569` (`'resume'`). One line each; the helper consolidation belongs to T2's covenant work, which will also route `:17511` through `covenantGate` — T2 must keep the `via` prop.
  4. `rules_open {phase}` at the top of `openScoringHelp()` (`:17274`).
  5. `endgame_seen {phase, n}` once per session when `renderCupRace()` (`:4537`) renders real data (dedupe with a `window.__endgameSeen` flag like `home_hero_state` at `:10000`). Pre-final there is no endgame surface today (TOP-5); **T5 fires `endgame_open {from}` from the sentence/receipt it adds** — name reserved here.
  6. `pot_mark {paid, league_id}` after `mark_buy_in` succeeds (`:7172–7175`); `pot_mark_denied {league_id}` in the `!isPro` branch (`:7168`) — M-110's fake-button confusion, counted directly.
  7. `post_submit` (`:6554`) gains `preseason: (CS.season?.starts_on && $('#inDate').value < CS.season.starts_on) || false` and `phase: state.phase`. (The truth of pre-season is computed server-side in `v_preseason_exposure`; the prop is the client's belief, which is exactly what T4 changes.)
- **dependsOn:** — (T7-06's registry should land in the same PR so the names are checked). **deployNeeds:** client push. **risk:** none functional (breadcrumbs swallow); the only landmine is calling `qaEvent` by bare name from the module block — use `window.qaEvent?.()` (F-007 family).
- **Verification.** Local serve, `?exit`, SW cleared; drive door → invite → covenant → join → post → pot tap; `select event, props from client_events where profile_id = '<me>' order by created_at desc limit 20` via `supabase db query --linked` shows the seven names with the props above; console clean.

### T7-02 · The funnel views, the lock-health view, the pre-season exposure view, `founder_desk()` v2
- **Layer:** db-migration · **Effort:** M · **Issues:** M-001 (alert), M-040 (exposure), takeaway 7
- **Files:** `supabase/migrations/YYYYMMDDHHMMSS_funnel_views.sql` (new; `create or replace function public.founder_desk()` lives here — never edit `20260721191500`).
- **Change.**
  - `v_lock_health` — per day for the last 30 days plus an all-time row: `lock_attempt`, `lock_blocked`, `lock_ok`, `lock_fail`, `invite_open`, `invite_shared`, distinct profiles, top `props->>'msg'` for failures, and `fail_gt_ok boolean`. Source `client_events` only.
  - `v_activation_funnel` — week × league (facts first, breadcrumbs second, §16): `created` (`leagues.created_at`), `locked` (`league_settings.locked_at`), `invites_shared` / `links_opened` (`growth_events` kind `join` by `league_id`), `covenants_seen` / `declined` / `skipped` (`client_events` by `props->>'code'` → `leagues.code`), `joined` (`league_members.joined_at`, `role <> 'commissioner'`), `first_round_7d` (members with a `rounds` row within 7 days of `joined_at`), `preseason_rounds` (rounds by members with `played_on < seasons.starts_on`), `pot_marked` (`buy_ins.paid`), `complete` (`seasons.status = 'complete'`). Rates in the desk, not the view.
  - `v_preseason_exposure` — the season-start lint: one row per league not `complete`: `code`, `phase`, `structure`, `members`, `locked_at`, `starts_on`, `days_to_first_tee`, `preseason_rounds` (as above), `empty_squads` (squads with zero `squad_members` — the Desert Dogs class), `forbidden_state` (`phase='season' and (empty_squads > 0 or members < 4)`).
  - `founder_desk()` v2 — same shape plus `funnel_7d` (the funnel columns summed over 7 days), `lock_health` (7-day totals + `fail_gt_ok` + top msg), `preseason` (`count(*) where days_to_first_tee > 0`, `sum(preseason_rounds)`, `count(*) where forbidden_state`), `growth_7d` (from `v_growth_funnel`). Keep the founder gate; re-state `revoke all … from public; grant execute … to authenticated` (D37).
  - All three views: `revoke all on … from public, anon, authenticated` (the `v_growth_funnel` precedent); no `security_invoker` needed because no API role can read them (db-checks 11 scopes to readable views). End with a `do $$` self-check that RAISES if any API role can select any of the three (the growth_events precedent — a grant claim is worth nothing until something fails on it).
- **dependsOn:** T7-01 for the new names (views tolerate their absence — zero rows). **deployNeeds:** db push; then `node tools/build-db.mjs` is NOT needed (`founder_desk` signature unchanged) — confirm with preflight check 11. **risk:** deploy-skew safe (the client reads keys with `?? 0`); RLS/grants per D37 (self-check enforces).
- **Verification.** `supabase db query --linked "select * from v_lock_health order by day desc limit 3"` returns the audit's 11/12 rows on 2026-08-29 *if run before the wipe*; `select * from v_preseason_exposure` lists THEPTCQ5 and DESEUU0K with `forbidden_state = true` for Desert Dogs; `select founder_desk()` as the founder returns the new keys; `tests/db-checks.sql` check 11 still PASS.

### T7-03 · Founder desk reads the funnel (web)
- **Layer:** client · **Effort:** S · **Issues:** M-001, takeaway 7
- **Files:** `index.html:15668–15705` (`window.openFounderDesk`).
- **Change.** Under the stats grid add three eyebrow sections: **"Funnel · 7d"** as `stat()` tiles (created → locked → shared → opened → covenant → joined → first round; growth: shared → opened → claimed → profiles → first rounds); **"Lock health · 7d"** one `.check` line `ok N · fail M · blocked B` with the 🐞 glyph and the top failure message when `lock_health.fail_gt_ok`; **"Season start"** one line `N leagues waiting on first tee · M pre-season rounds · K in a state §15 forbids`. Keep the raw "Client events · last 30" list below.
- **dependsOn:** T7-02 (renders `?? 0` before it lands). **deployNeeds:** client push. **risk:** none (founder-only surface; `esc()` every string).
- **Verification.** Open Settings → Founder's desk on the owner's account; the three sections render; on a pre-T7-02 database they read zeros, never throw.

### T7-04 · The alert — `lock_fail > lock_ok` pages the founder
- **Layer:** db-migration (+ verify the `push` edge function) · **Effort:** M · **Issues:** M-001 (the 25-day blind spot)
- **Files:** `supabase/migrations/YYYYMMDDHHMMSS_lock_health_alert.sql` (new): `lock_health_alert()` SECURITY DEFINER, execute revoked from `public, anon, authenticated` (engine discipline, db-checks 12), scheduled `cron.schedule('cs-lock-health', '30 7 * * *', $$select public.lock_health_alert()$$)` inside `do $$ if exists (select 1 from pg_extension where extname='pg_cron') …` like the other jobs. Body: over the last 24 h, if `lock_fail > lock_ok` and `lock_attempt >= 2`, insert one `push_nudges (profile_id := founder_id(), title := 'Lock health', body := format('%s lock failures vs %s ok in 24h — top: %s', …))`; idempotent per day via a `pilot_feedback`/`founder` note or a `where not exists` on today's nudge. The existing `push_nudges` INSERT webhook → `push` edge function delivers it.
- **dependsOn:** T7-02 (`v_lock_health`). **deployNeeds:** db push; **no functions deploy unless** the `push` function's nudge branch rejects a non-Ryder title — verify first (`supabase/functions/push`, the `push_nudges` path from `20260716160000_ryder_slice3.sql`), and remember the D68 lesson: read the webhook target from `pg_trigger`, not the dashboard. **risk:** the founder has no device token → the nudge is a silent row (acceptable; the desk still shows it); if the push function returns a bare `ok` on an unrecognised payload the misroute is invisible — log the invocation.
- **Verification.** `begin; insert into client_events … 'lock_fail' ×3 as the owner; select lock_health_alert(); select * from push_nudges order by created_at desc limit 1; rollback;` via `db query --linked`; `select jobname from cron.job where jobname='cs-lock-health'` (db-checks 1 counts it).

### T7-05 · iOS telemetry parity — same names, same props
- **Layer:** ios · **Effort:** S–M · **Issues:** parity (D100), M-145 (evidence), takeaway 7
- **Files / change.**
  - `invite_shared {via:'share'}` beside every `CSGrowth.log(.artifactShared, kind:"join", …)`: `Wizard/WizardLockShareSheet.swift:48`, `League/LeagueRoomScreen.swift:162`, `League/MembersSheet.swift:44`, `League/StandingsPane.swift:65,120` (the phone always has the OS share sheet, so `via` is `'share'`; a copy control logs `'clipboard'`).
  - `covenant_seen {code, buyin}` when the sheet is presented (`People/JoinLeagueFlow.swift:48`), `covenant_declined {code}` in `onNo` (`:49`), `covenant_skipped {code, reason}` when `joins.covenant(c)` returns nil and `join()` runs (`:97–98` — the phone FAILS CLOSED, so `reason:'no_stake'` is the only case).
  - `joined {via:'door', league_id}` after `joins.join(c)` returns (`JoinLeagueFlow.swift:107`), and `via:'link'` when the join came from a stored `JoinIntent`.
  - `rules_open` in `LeagueRoomScreen.swift:94` (`case .scoringHelp`) or at `BylawsCard.swift:46`'s tap.
  - `pot_mark {paid, league_id}` after `Rpc.mark_buy_in` (`League/LeagueRoomModel.swift:423`); `pot_mark_denied` wherever the phone refuses a member tap.
  - `post_submit` gains `preseason` and `phase` (`PostEpilogue.swift:219` names it; the call site in `PostService`/the composer adds the props).
  - **Resolve the existing drift** (open question 2): either the phone stops emitting `league_created`/`league_locked` in favour of the web's `league_create`/`lock_ok`, or `docs/ios/reliability.md:93–113` and `WizardService.Event` are declared the canonical pair and the web adopts them. T7-06's registry makes the choice mechanical; recommended: **web names win** (they have prod history), the phone's five IOS-024 names stay for `signed_in`, `card_set`, `round_posted` and drop the two duplicates.
- **dependsOn:** T7-01 (names), T7-06 (registry). **deployNeeds:** iOS build (TestFlight). **risk:** `CSTelemetry`'s 2-second dedupe folds a double tap — fine.
- **Verification.** Sim: sign in via the dev hatch, join a league by code, open scoring help, mark a buy-in as the Pro; `select event, props from client_events where props->>'build' is not null order by created_at desc limit 10` shows the names byte-identical to the web's; preflight 18 PASS.

### T7-06 · The event registry + preflight check 18 (no unknown event names on either client)
- **Layer:** tooling · **Effort:** S · **Issues:** parity; the `league_create`/`league_created` drift
- **Files:** `packages/telemetry/events.json` (new, hand-maintained: `{name, table:"client_events"|"growth_events", fires:"web:fn / ios:file", props:[…], since:"T7-01"}`); `tests/preflight.mjs` (append after check 17, before the summary at `:449`).
- **Change.** Check 18 extracts every `qaEvent(\s*'name'` / `qaEvent\?\.\(\s*'name'` from `index.html` and every `CSTelemetry.event("name"`, `WizardService.Event` case raw value, `PostEvent` constant and `CSTelemetry.Product` raw value from `apps/ios` (skip `Generated/`), and every `growthEvent('node'` / `CSGrowth.log(.node` against the five growth nodes; FAIL on any name absent from the registry, and WARN on a registry name no client emits (dead vocabulary — the `invite_open` lesson in reverse). Regex-only, no parser, same style as checks 12–17.
- **dependsOn:** —. **deployNeeds:** none (the Stop hook and `ship.sh` run preflight). **risk:** none.
- **Verification.** `node tests/preflight.mjs` → `PASS event registry — N web · M ios names, all registered`; temporarily misspell one call → FAIL naming the file:line.

### T7-07 · Preflight check 19 — the free-identifier lint (`node --check` is blind to `staged`)
- **Layer:** tooling · **Effort:** M · **Issues:** M-001 (Appendix A #1; second occurrence after F-007 `memName`)
- **Files:** `package.json` (new at root — `devDependencies: { acorn, eslint-scope }`; `node_modules/` is already ignored); `tests/preflight.mjs` check 19; `tests/fixtures/no-undef-staged.js` (new).
- **Change.** Reuse check 6's block extraction (`:96–113`: four blocks — classic at `index.html:2484`, `:3651`, `:3742`; module at `:12981`). For each block: `acorn.parse(src, {ecmaVersion:'latest', sourceType})`, `eslintScope.analyze(ast, {ecmaVersion: 2024, sourceType})`, collect `globalScope.through` (references no scope resolved). Subtract: (1) the union of every classic block's global-scope `variables` (functions, `var/let/const/class` at top level — classic blocks share one global scope); (2) every `window.NAME =` / `globalThis.NAME =` assignment anywhere in the file (the explicit bridges, e.g. `window.qaEvent`, `window.CS`, `window.sb`); (3) a browser allowlist (`window, document, navigator, localStorage, sessionStorage, fetch, URL, URLSearchParams, crypto, Intl, setTimeout, clearTimeout, setInterval, clearInterval, requestAnimationFrame, console, Promise, JSON, Math, Date, Number, String, Array, Object, Map, Set, WeakMap, Blob, File, FileReader, Image, Audio, MutationObserver, IntersectionObserver, ResizeObserver, Notification, PushManager, caches, indexedDB, matchMedia, getComputedStyle, history, location, screen, performance, structuredClone, CustomEvent, Event, AbortController, TextEncoder, TextDecoder, atob, btoa, alert, confirm, prompt, HTMLElement, Element, Node, NodeList, DOMParser, ImageCapture, BarcodeDetector, ShareData, self, globalThis`) plus the module's imports (`createClient` from `esm.sh` at `:12982`). Report the remainder as `block N:line name`; FAIL on any. When `acorn` cannot be imported (a remote session with no `npm install`) print `~ WARN free-identifier lint — deps not installed (npm install)` — never PASS. **Self-test first:** the check lints `tests/fixtures/no-undef-staged.js` (`function lockBylaws(){ const emails=[]; return { emails: emails.length, invited: staged.length }; }`) and FAILS ITSELF if the fixture passes — the "grant assertion is worth nothing until something fails on it" lesson, applied to the linter.
- **dependsOn:** —. **deployNeeds:** none; `npm install` once on the Mac. **risk:** false positives from the `typeof X !== 'undefined'` guards the file uses deliberately (`:14140–14141` `STRUCT_MIN`) — `eslint-scope` still reports `typeof` operands as through-references; treat `typeof` operands as allowed (walk `UnaryExpression{operator:'typeof'}` and drop those names).
- **Verification.** On HEAD before T1's fix: `X FAIL free identifiers — block 4:<line of :15218> staged`. After T1: PASS. Inject `return foo.bar` anywhere → FAIL.

### T7-08 · The lock test — `tests/rpc-smoke.sql`, rollback-wrapped, run against the linked database
- **Layer:** tooling · **Effort:** M · **Issues:** M-001, M-017, Appendix A #14 (solo bypasses min-4), Desert Dogs' state
- **Files:** `tests/rpc-smoke.sql` (new); `tools/ship.sh` gains an optional step that prints the command.
- **Change.** One transaction, ends in `rollback`, run as `supabase db query --linked "$(cat tests/rpc-smoke.sql)"`: `set local role authenticated; select set_config('request.jwt.claims', '{"sub":"<founder uuid>","role":"authenticated"}', true);` then `create_league` → **`lock_league`** (T1's RPC) → assert `leagues.phase` matches the stored structure (`draft` for squads, `season` only for solo with ≥ 4 members — D58's gate), `league_settings.locked_at not null`, `count(squads) = structure`; call `lock_league` again → assert nothing changed (idempotent); `set_config` to a second profile → `join_covenant_info` non-null → `join_league` → assert a `league_members` row; `rollback`. Every assertion `raise exception` on failure so the CLI exits non-zero. The honest statement: **the current client-orchestrated lock cannot be tested from SQL** (it is four direct writes from the browser, `index.html:15127–15211`), and `tests/app-tests.js` cannot reach `lockBylaws` (module-scoped, not a classic global). The lock test arrives with the RPC; until then T7-07 is the guard.
- **dependsOn:** T1's `lock_league` migration (decision-log entry first, per §11.1). **deployNeeds:** none (read-only transaction; verify on first run that the linked `postgres` role may `set role authenticated` — Supabase grants it; if not, run as postgres and call `auth.uid()`-free assertions). **risk:** a forgotten `rollback` mutates prod — the file's last line is `rollback;` and the runbook says never edit it.
- **Verification.** The script prints `lock smoke: PASS` and the CLI exits 0; comment out the idempotence branch in a scratch copy of `lock_league` inside the transaction → FAIL.

### T7-09 · The harness becomes a repo tool — `tools/blind/`
- **Layer:** tooling · **Effort:** M · **Issues:** M-031 (harness artifact), M-142 (the unstamped caption blind testers saw), README "How the audit was run"
- **Files (new):** `tools/blind/bx.mjs`, `tools/blind/README-agent.md`, `tools/blind/score18.sh`, `tools/blind/tag.js`, `tools/blind/package.json` (`playwright` only — the root `package.json` from T7-07 must NOT carry Playwright's 18 MB + browser download), `tools/blind/.gitignore` (`node_modules/ sessions/ shots/ txt/ http.log`), `tools/blind/personas/{organizer,novice,joiner,casual,competitive,skeptic,observer,ios-survey}.md`, `tools/blind/RUNBOOK.md`.
- **Source:** the harness is in this session's scratchpad at `/private/tmp/claude-501/-Users-fischbeck3-cup-season/8472110b-9333-460b-8c1c-e243ac7cb2f3/scratchpad/harness/` (`bx.mjs` 221 lines, `README-agent.md`, `score18.sh`, `tag.js`; `shots/` 205 MB and `sessions/` 75 MB stay behind). **Copy it before the scratchpad is reaped** — the earlier session's copy (`368fdc84…`) is already gone.
- **Change.** (1) `bx.mjs` click resolution (`loc()` `:119–127`, `click` `:180–187`): try `getByRole('button', {name, exact:true})` then `getByRole('link', …)` **before** the substring `getByText`, so "You" can never resolve to "Lock it in and invite **You**r crew" again (M-031). (2) Personas: reconstruct each brief from the raw report headers (`raw/agent*.md` lines 1–6: persona, handicap, home course, key question), the journey list (`raw/persona-results.json` → `journeysCovered`), the ten discovery questions (`discoveryAnswers` keys `1_what_app_does … 10_…`, asked cold and at the end), the ten scores (`scores` keys), the 30-second explanation, glossary, confusion debt, verdict — and the result-row JSON schema so a re-run produces a row `tools/merge_issues.py` can ingest. (3) RUNBOOK: serve the **stamped** build (`COMMIT_REF=$(git rev-parse --short HEAD) bash ./stamp-version.sh && python -m http.server 8791 --directory dist`) so testers read `v23 · <sha>` like prod, not `__CS_VERSION__` (M-142 closed without touching the placeholder lines — rule 2); fresh dated aliases `jerecho+blind<N>-<yyyymmdd>@`; `/?exit` + SW/caches cleared per session; the Gmail code query; one persona per session name; stop every daemon; then T7-11's footprint + wipe.
- **dependsOn:** —. **deployNeeds:** none. **risk:** none to prod; Playwright's Chromium download is per machine.
- **Verification.** `cd tools/blind && npm install && npx playwright install chromium && node bx.mjs start smoke && node bx.mjs smoke goto http://127.0.0.1:8791/ && node bx.mjs smoke click "role=button name=Continue with email" && node bx.mjs smoke stop` round-trips; `node bx.mjs smoke click You` on a forming-league Home resolves to the tab, not the hero.

### T7-10 · Gate 6 — the zero-instruction test, run blind (`spec/prelaunch-qa-2026-07-13.md`)
- **Layer:** spec · **Effort:** S · **Issues:** blind-ux-audit §14 (all seven sub-answers), takeaway 7
- **Change.** Append "### 6. Zero-instruction — run blind" after gate 5 (`:74–86`): the question (§14 verbatim), the phase table in section (e) below (which personas re-run after which theme, the pass criteria, the fresh-account rule, the wipe), the scoring rule (each re-run persona's key-question score ≥ 6 — from 3–5 today — and the phase's sub-answers flipped to YES with the evidence frame named), and "who runs it": the owner starts the local stamped serve and the harness (Gmail codes need the owner's inbox), a Claude session drives the personas as subagents exactly as 2026-08-29 did, the owner reads the `critical-findings`-shaped output; **one evening per phase**, four phases. Cross-link from `docs/audit/blind-ux-2026-08-29/README.md` "How the audit was run".
- **dependsOn:** T7-09. **deployNeeds:** none. **risk:** none.
- **Verification.** The doc exists; the first phase-A run produces a `persona-results.json` row that `tools/merge_issues.py --review` ingests.

### T7-11 · `tools/blind/footprint.sql` + `tools/blind/wipe.sql` — every re-run cleans up after itself
- **Layer:** tooling · **Effort:** S · **Issues:** README "Test footprint and cleanup"
- **Change.** `footprint.sql` (read-only): given an alias pattern (`jerecho+blind%-<date>@`) and league codes, list what the run wrote (profiles, leagues by phase, rounds, posts, live rounds, growth/client events) and RAISE if any blind profile is commissioner of a league outside the list or has rounds fanned into a non-audit league. `wipe.sql`: Appendix A's corrected SQL with `:prefix` / `:codes` at the top, ending in `rollback;` — the runbook's rule is "run as written, read the counts, change the last line to `commit;`". Both run via `supabase db query --linked "$(cat …)"`, owner at the wheel.
- **dependsOn:** —. **deployNeeds:** none. **risk:** the wipe is prod-mutating by design; the `rollback` default and the footprint RAISE are the two safeties.
- **Verification.** Dry-run on the current audit footprint returns the counts in Appendix A; commit; the four assert selects return 0.

### T7-12 · D111 in the log + the gate checklist as a living doc
- **Layer:** spec · **Effort:** S · **Issues:** §9 (all seven), M-012, M-110, M-133, M-124
- **Files:** `spec/decision-log.md` (D111 as drafted above, after the D110 addendum); `spec/pricing-arc.md` gains "## The gate (D111)" — or a new `docs/ops/monetization-gate.md` if the owner prefers ops docs out of spec/ — with this table:

| # | §9 item | Evidence / metric | Source | Green when |
|---|---|---|---|---|
| 1 | A season ends well | ≥ 1 real league `seasons.status='complete'` with `season_payouts` rows; ceremony opened | `seasons`, `season_payouts`, `endgame_seen{phase:'complete'}` per member | PIGL's first close; ≥ 50% of its members fire `endgame_seen` within 7 days; D68 email delivered (its log) |
| 2 | The race is visible all season | members see the endgame monthly; the clash opens | `endgame_seen` / `endgame_open` (T5), `week_clashes` | ≥ 1 per active member per month over a full month; a `week_clashes` row within 1 tick of each week rollover |
| 3 | Pre-season honesty | no promise of points before first tee | `v_preseason_exposure`; re-audit Phase B | Phase B sub-answer 5 = YES; `post_submit.preseason=true` rows carry no `client_error` in the same session |
| 4 | The pot is true | D106 live; a payment path stated | `buy_ins`, `seasons.pot_cents/collected_cents`, T6's `buy_in_note/due_on`, `pot_mark_denied` | PIGL `collected = pot` at close; note set on ≥ 1 real league; `pot_mark_denied` → 0 after status rows ship |
| 5 | The invite works | locks succeed; invites convert | `v_lock_health`, `v_activation_funnel` | 30-day `lock_fail = 0` with ≥ 3 `lock_ok`; `joined / links_opened` ≥ 60% on ≥ 3 real leagues |
| 6 | Price stated where the buy-in is set | D101 sentence on web wizard money step + iOS cards | copy + re-audit Phase C | Skeptic re-run can state payer, price, "first year free" unprompted |
| 7 | Focus-group instrument run | D56's deck against the real surfaces | `spec/focus-group-plan.md`, `spec/pricing-discovery-2026-07.md` §5 | ≥ 6 Pros; re-audit *would pay* median ≥ 5 |
| 8 | Founding leagues seeded | PIGL never sees a price | `app_flags.pricing.founding.ids` | non-empty; db-checks 15 PASS |

- **dependsOn:** owner ruling on D111. **deployNeeds:** none. **risk:** none.
- **Verification.** The entry exists in hierarchy-of-truth format; the doc's eight rows each name a view or event that T7-02 provides.

### T7-13 · `tests/db-checks.sql` checks 15–17 — the gate guard, lock health, the §15 invariant
- **Layer:** tooling · **Effort:** S · **Issues:** D111, M-001, Appendix A #14, Desert Dogs
- **Change** (append three `union all` rows before the final `select * from checks`, `:307`; same PASS/FAIL shape as check 8, `:123–142`):
  - **15 · monetization gate** — FAIL if `app_flags.pricing->>'visible' = 'true'` while (`pricing->'founding'->'ids' = '{}'` OR no `seasons` row is `complete` with a `season_payouts` row). Detail: "visible requires a founding id and one settled season (D111)".
  - **16 · lock health** — FAIL if, over the last 7 days, `lock_fail > lock_ok` and `lock_attempt >= 3`; detail prints the counts and the top message. (This would have failed on 2026-08-29 — and on every day since 2026-08-04 that anyone tapped the button.)
  - **17 · §15 formation invariant** — FAIL if any league has `phase = 'season'` and (a squad in its latest season with zero `squad_members`, or fewer than 4 `league_members` while `structure <> 'solo'`, or any member unassigned in a squads structure). Detail lists the codes. Desert Dogs fails this today; after T7-14 it passes; after T1's `lock_league` it can never fail again.
- **dependsOn:** T7-02 (16 can read `v_lock_health`; or inline the count). **deployNeeds:** none (paste into the SQL editor / `db query --linked`). **risk:** none (read-only).
- **Verification.** Run the suite before the wipe: 17 FAIL naming DESEUU0K, 16 FAIL (11 > 1); after the wipe: 17 PASS; after T1 + a real lock: 16 PASS.

### T7-14 · The wipe — before 2026-09-05 07:20 UTC
- **Layer:** ops (owner runs it) · **Effort:** S · **Issues:** README "Test footprint", Appendix B, Desert Dogs' §15-forbidden state
- **Change.** Run Appendix A below exactly as written (it ends in `rollback`), read the counts, change the last line to `commit;`, run again. Export the lock evidence first if it should survive (it cascades with the profiles): `select event, props, created_at from client_events where profile_id in (select id from profiles where email like 'jerecho+blind%@fischbeck3.com') order by created_at` → keep the output in the audit folder as `raw/client_events-lock.csv` (PII-free: event, props, timestamp).
- **Why the date.** See §0: the daily tick kicks both leagues off at 07:20 UTC on Sep 5 (`kicked_off = true` + a board post), the Sunday snapshot runs at 07:10 UTC on the 6th, the clash opens on the next tick, and `delete_league` refuses from then on. Direct SQL still works after — but the leagues would by then have generated posts, snapshots and clash rows that also need deleting (they cascade, so the SQL is the same; the risk is a kickoff push to any blind device token — there are none).
- **What the README got wrong, corrected in Appendix A.** (1) Three NO-ACTION FKs to `profiles` it does not null: `live_round_players.claimed_profile` (`20260716140000:23`) and `live_round_players.guest_profile_id` (`20260728220000:34`) — safe only if every seat sits in one of the two leagues (they cascade through `live_rounds`); a D107 league-less round seated by a blind profile would block step 3, so the script nulls them. (2) `growth_events.actor` has no FK — orphan rows survive (PII-free; the script deletes them for tidiness before the ids vanish). (3) `leagues.commissioner_id` is NOT NULL NO ACTION (baseline `:1791`) — the script asserts no third league has a blind commissioner. (4) `delete_league` does not refuse Desert Dogs yet (see §0).
- **dependsOn:** T7-02 + T7-13 run once BEFORE (to see the views/checks catch the real state), then the wipe. **deployNeeds:** none — `supabase db query --linked` from the Mac. **risk:** prod-mutating; the `rollback` default, the counts, and the `like 'jerecho+blind%'` pattern (which cannot match the owner's `jerecho@`) are the safeties. The owner's own account wrote nothing (README: 0 rounds, 0 posts).
- **Verification.** The four trailing selects return 0; `select count(*) from leagues where code in ('THEPTCQ5','DESEUU0K')` = 0; the owner's Crew list shows no `+blind` name; db-checks 17 PASS.

### T7-15 · Committing `docs/audit` — the repo is public
- **Layer:** docs / tooling · **Effort:** S · **Issues:** README file index; M-163 (its raw report quotes sign-in codes)
- **Facts.** `docs/audit/` is **untracked** (`git status`: `?? docs/audit/`). The repo is public (`.gitignore:8–11`). The folder is 101 MB: `screenshots/` 99 MB (self-ignored by `screenshots/.gitignore`), `raw/` 1.4 MB, deliverables + dataset + tools ≈ 1 MB. **PII in the text:** 22 files carry `@fischbeck3.com` addresses (the seven `+blind` aliases and the owner's real account as the observer); five raw reports quote 8-digit sign-in codes (expired, but they are sign-in codes in a public repo); the observer's report and frames name the owner's real leagues and friends by first name. No keys, JWTs or secrets were found (`grep` for `eyJ…`, `sb_secret`, `service_role`, `password`: none).
- **Change (recommended).** (1) **Never commit `raw/` or `screenshots/`** — add `docs/audit/**/raw/` and `docs/audit/**/screenshots/` to the root `.gitignore`; archive both as a zip to the owner's private storage (they are the evidence; the deliverables cite them by relative path, which the README already explains). (2) **Redact, then commit** the seven deliverables, `issues.{json,csv}`, `issues-counts.json`, `issues-README.md`, the six `synthesis-*.md`, `tools/`, and `plan/`: `jerecho+blind(\d+x?)@fischbeck3\.com` → `tester-$1@example.test`, `jerecho@fischbeck3\.com` → `<owner account>`, the observer's real first names → `<member A>`/`<member B>` (owner's call — first names in a golf league are low-risk but they are private individuals), `\bcode:? \*?\d{8}\b` → `code ********`. Run `tools/merge_issues.py` after redaction so the dataset regenerates consistently. (3) **Preflight check 20 — no PII in tracked docs:** FAIL if any tracked file under `docs/` or `spec/` matches `[A-Za-z0-9._%+-]+@fischbeck3\.com` or `\b\d{8}\b` within 20 chars of "code". Alternative if the owner prefers zero exposure: keep the whole folder untracked and commit only `plan/` — at the cost of the issue ids the plans cite having no tracked source.
- **dependsOn:** owner ruling (open question 1). **deployNeeds:** `git push` only; `stamp-version.sh`'s dist allowlist never serves `docs/` (OPS-C7), so nothing here reaches Netlify. **risk:** a public-history leak is permanent — redact BEFORE the first commit, not after.
- **Verification.** `git grep -n '@fischbeck3.com' -- docs spec` returns nothing; preflight 20 PASS; `git check-ignore docs/audit/blind-ux-2026-08-29/raw/agent1-casual.md` prints the path.

---

## (c) Quick wins — no decision needed, shippable this week

| Id | What | Effort | Deploy |
|---|---|---|---|
| **T7-14** | The wipe (deadline Sep 5 07:20 UTC) — run T7-02/T7-13 first if they are ready, otherwise wipe anyway | S | owner SQL |
| **T7-09** | Copy the harness out of the scratchpad into `tools/blind/` before it is reaped; fix the click resolver | M | none |
| **T7-01** | The seven web events | S | client push |
| **T7-06** | Event registry + preflight 18 | S | none |
| **T7-07** | Free-identifier lint + fixture (would fail on HEAD today — that is the point) | M | none |
| **T7-13** | db-checks 15–17 | S | none |
| **T7-02 + T7-03** | Views + desk (one migration, one client section) | M + S | db push + client push, either order |
| **T7-15** | `.gitignore` for `raw/`/`screenshots/`, redaction pass, preflight 20 — after open question 1 is answered | S | git push |

Not this week: T7-04 (verify the push function's nudge path first), T7-05 (rides the next iOS build), T7-08 (waits for T1's `lock_league`), T7-10/T7-12 (one owner ruling each).

---

## (d) Parity (D100 — nothing ships on the web alone)

| Item | Web | iOS | Note |
|---|---|---|---|
| T7-01 events | `index.html` | **T7-05** (same names, same props; files listed there) | T7-06 fails the push if the vocabularies drift |
| T7-02 views / `founder_desk()` v2 | server | server — one RPC serves both | `Rpc.swift` unchanged (signature same); `FeedbackSheet.swift` reads the new keys in **T7-05** (`section("Funnel · 7d", …)` beside `:157`) |
| T7-03 desk render | `:15668–15705` | `FeedbackSheet.swift:150–166` | in T7-05 |
| T7-04 alert | server (push_nudges → push function) | the founder's phone receives it via APNs (D104 rail) | no client code |
| T7-06 registry | web names scanned | iOS names scanned | the registry is the shared source (`packages/` is the shared source per CLAUDE.md "The phone") |
| T7-07 lint | web only by nature | Swift has the compiler | web-only, permanently |
| T7-08 rpc smoke | server | server (the phone's `WizardService.lock` will call the same `lock_league`) | T1 must port `WizardService.swift:109–135` to the RPC too |
| T7-09 harness | web (Playwright, iPhone viewport) | the iOS survey used the dev launch hatch, no taps; a real tap-path re-run needs a simulator driver — **iOS re-audit stays screen-survey-only until the owner wants an XCUITest driver** (open question 3) | web-first until then |
| T7-13 db-checks | server | server | — |
| T7-15 docs | — | — | — |

---

## (e) Measurement — the event set, where it reads, and the acceptance runs

### The vocabulary after T7 (registry `packages/telemetry/events.json`)

| Event | Table | Fires (web / iOS) | Props | Proves |
|---|---|---|---|---|
| `league_create` | client_events | `:15109` / `WizardService.createLeague` | `named` | top of funnel |
| `lock_attempt` · `lock_blocked` · `lock_ok` · `lock_fail` | client_events | `:15476–15503` / `WizardService.lock` | `reason` · `next_phase` · `msg` | **TOP-1** — T1's fix: `lock_fail` → 0, `lock_ok` ≥ 1 per real lock |
| `invite_open` | client_events | `:14139` (`openLockShare`) / `WizardLockShareSheet` | `sent` | the share sheet opens after every lock (`lock_ok − invite_open ≈ 0`) |
| `invite_shared` (new) | client_events | `shareInvite` `:14121/14126/14127` / five tap sites | `via` (`share`/`clipboard`/`toast`), `league_id` | **TOP-1/M-003** — `via:'toast'` share → 0 after the URL-as-text sheet |
| `artifact_shared(join)` · `link_opened(join)` · `profile_created(join)` | growth_events | existing | token = league code | invite → open → profile, incl. signed-out opens |
| `covenant_seen` · `covenant_declined` · `covenant_skipped` (new) | client_events | `:15425–15438` / `JoinLeagueFlow:48–49,97` | `code`, `buyin`, `reason` | **TOP-2** — after T2: `skipped` → 0 on the boot path; `declined / seen` is the honest decline rate |
| `joined` (new) | client_events | five `join_league` sites / `JoinLeagueFlow:107` | `via`, `league_id` | invite → accept (cross-check `league_members.joined_at`) |
| `home_hero_state` · `home_hero_tap` | client_events | `:9999–10000` | `state`, `cta` | **TOP-3** — after T3: members never see `state:'forming-pro'`; a member `cta` exists |
| `post_open` · `post_submit` (+ `preseason`, `phase`) | client_events | `:4179`, `:6554` / `PostEvent` | mode, secs, gross, holes, `preseason` | **TOP-4** — T4: `preseason:true` posts carry the practice line (re-audit checks the copy; the prop counts the exposure) |
| `first_round_posted` | growth_events | `:6552` / `PostService` | — | activation |
| `rules_open` (new) | client_events | `:17274` / `LeagueRoomScreen:94` | `phase` | **TOP-5 / M-054** — after T5: rules opened by ≥ 50% of members in week 1 (today: reachable four taps deep) |
| `endgame_seen` (new) · `endgame_open` (T5) | client_events | `:4537` / T5's surface | `phase`, `from` | **TOP-5** — every active member monthly |
| `pot_mark` · `pot_mark_denied` (new) | client_events | `:7168–7175` / `LeagueRoomModel:423` | `paid`, `league_id` | **TOP-5 / M-110** — after T6: `denied` → 0; `pot_mark` before first tee on real leagues |
| `client_error` | client_events | `:3686/3695` / MetricKit | kind, msg, 4-frame stack, step | the ghost lesson — keep the stack |

Facts the views read without any event (§16 — the record beats the breadcrumb): `leagues.created_at`, `league_settings.locked_at`, `league_members.joined_at`, `rounds.played_on` vs `seasons.starts_on`, `buy_ins.paid`, `seasons.status`, `season_payouts`, `week_clashes`, `squads`/`squad_members`.

### The re-audit gate — phases, personas, pass criteria (goes into `spec/prelaunch-qa-2026-07-13.md` as gate 6)

| Phase | After | Re-run (fresh dated aliases; contaminated accounts are the run-2 lesson) | Journeys | Pass criteria (§14 sub-answers → YES; key-question score ≥ 6) | Telemetry check |
|---|---|---|---|---|---|
| **A · activation** | T1 (lock / invite / hard defects A#1–8) + T3 (member Home) | **Organizer (A5)** + **New joiner (A6)** | A, B, C, then A6's D via the organizer's link | (1) the first lock tap opens the share sheet with the URL as selectable text, zero "Lock failed" toasts; (2) the joiner receives a link the organizer produced in-app without typing a code; (3) the joiner reads Pro, roster, dates, buy-in, payment path before "I'm in"; (4) the member's Home shows a member verb and no lock/delete control; setup score ≥ 6 | `v_lock_health` for the run: `lock_ok = 1, lock_fail = 0, invite_open = 1`; `covenant_seen = 1`, `joined{via:'door'} = 1`, `home_hero_state` never `forming-pro` on the joiner |
| **B · the loop** | T4 (first round truth) + T5 (rules / endgame) | **Casual (A1)** + **Competitive (A2)**, cold | D, E (on a league whose first tee is ≥ 7 days out — the default) | (5) the posted card + receipt say practice/pre-season or give N pts with a path; the two say the same number; minus never reads as good (words, D1); (6) "how do we win" answered from Home/Standings within two taps: Cup Final, seeds, ties; rulesClear ≥ 6, conceptClear ≥ 6, gameplayCompelling ≥ 6 | `post_submit{preseason:true}` = 1 per persona with no `client_error` in-session; `rules_open ≥ 1`, `endgame_open ≥ 1` per persona |
| **C · money** | T6 (pot path, $0 default, D101 sentence) | **Skeptic (A4)** + **Observer (A7)** on PIGL after its first month close (or first ceremony) | E, F, G + Money | (7) the Pot tab answers who/how/when; no $75 appears anywhere a Pro did not type it; the skeptic can state payer + price + "first year free"; wouldPay ≥ 5, wouldInvite ≥ 6 | `pot_mark_denied = 0`; `v_activation_funnel.pot_marked` on PIGL; `endgame_seen{phase:'complete'}` on the observer |
| **D · full** | before the D111 flip | all seven + the iOS survey (real tap path if a driver exists, else the launch hatch) | A–G | §14 answer flips to **YES**; median of the ten scores ≥ 6; *would pay* median ≥ 5 | the eight gate rows green |

Who: owner (serve + Gmail + wipe) and one Claude session (personas as subagents, synthesis, the merge script) — one evening per phase. Cost stated honestly: four evenings across the remediation, plus the wipe after each.

---

## (f) Open questions for the owner

1. **Public-repo posture for `docs/audit`.** Redact-and-commit the deliverables (recommended, T7-15) or keep the whole folder untracked and commit `plan/` only? And: keep the observer's real first names in the observer report, or replace them?
2. **Which telemetry names are canonical where the two clients already differ** — the web's `league_create` / `lock_ok` (prod history) or the phone's IOS-024 `league_created` / `league_locked`? T7-05 recommends the web's; the registry enforces whichever you pick.
3. **The alert channel.** Founder-desk line only (T7-02/03, zero risk) or the daily `push_nudges` page (T7-04, needs the push function verified for a non-Ryder nudge)? And is a simulator driver for iOS re-audits worth building now, or does the iOS gate stay a screen survey until App Review is back?
4. **The first-tee default** (D112 sketch). Keep "next Saturday, 1–7 days out" (`index.html:7237`) and let T4's practice-round copy carry it, or move the default to ≥ 7 days / today? No decision covers it; S2-01 only flagged the weekday.
5. **Gate thresholds** in D111: invite→accept ≥ 60% (from GTM §1's roster-lock rate), `lock_fail = 0` over 30 days, ≥ 6 Pros in the focus group, re-audit *would pay* ≥ 5 — accept, or set your own?
6. **The wipe date.** It must run before **2026-09-05 07:20 UTC**; the audit's `client_events` lock evidence cascades away with the profiles — export it (T7-14) or let it go?
7. **Where the gate checklist lives** — `spec/pricing-arc.md` (with the pricing canon) or a new `docs/ops/` folder (with the deploy runbooks)?

---

## Appendix A — The wipe, corrected (`tools/blind/wipe.sql` v1; the audit footprint hard-coded)

Dry-run exactly as written (ends in `rollback`), read every count, then change the last line to `commit;`. Run from the Mac: `supabase db query --linked "$(cat wipe.sql)"`. Deadline: **before 2026-09-05 07:20 UTC** (§0).

```sql
begin;

-- 0 · what is about to go (read the counts before you commit)
select email, created_at from auth.users where email like 'jerecho+blind%@fischbeck3.com';          -- expect 7 (blind1..6 + blind2x)
select code, name, phase from public.leagues where code in ('THEPTCQ5','DESEUU0K');                     -- expect 2
select l.code from public.leagues l
  join public.profiles p on p.id = l.commissioner_id
 where p.email like 'jerecho+blind%@fischbeck3.com' and l.code not in ('THEPTCQ5','DESEUU0K');         -- MUST be 0 rows (commissioner_id is NOT NULL, NO ACTION — baseline:1791)

-- 0b · optional: keep the lock evidence (cascades away with the profiles in step 3)
select e.event, e.props, e.created_at
  from public.client_events e join public.profiles p on p.id = e.profile_id
 where p.email like 'jerecho+blind%@fischbeck3.com' order by e.created_at;                            -- lock_attempt 12 · lock_fail 11 (2026-08-29 13:32–13:34 UTC)

-- 1 · NO-ACTION references to the test profiles that would block step 3
--     (the README's three, plus the two live-round columns it missed and the FK-less growth rows)
update public.courses set created_by = null
 where created_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');   -- baseline:1706, NO ACTION
delete from public.member_invites
 where invited_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');   -- 20260713180000:14, NOT NULL, NO ACTION
delete from public.events
 where created_by in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com');   -- 20260713120000:15, NOT NULL, NO ACTION (event children cascade)
update public.live_round_players set claimed_profile = null
 where claimed_profile in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com'); -- 20260716140000:23, NO ACTION
update public.live_round_players set guest_profile_id = null
 where guest_profile_id in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com'); -- 20260728220000:34, NO ACTION
delete from public.growth_events
 where actor in (select id from public.profiles where email like 'jerecho+blind%@fischbeck3.com')
    or league_id in (select id from public.leagues where code in ('THEPTCQ5','DESEUU0K'));               -- no FK → would orphan (PII-free) — tidy before the ids vanish

-- 2 · the two audit leagues. ON DELETE CASCADE (verified in the baseline + later files):
--     league_members (1776) · league_settings (1786) · seasons (1941) → squads (1966) → squad_members (1951),
--     cup_finalists (1716), season_adjustments (1926), buy_ins (1681), rounds.season_id (1906), standings_snapshots (1971),
--     week_clashes (20260829091000:84), career_record (20260725100000:18), season_email (20260725140000:34) ·
--     posts (1861) → post_comments (1846), post_kudos (1856), content_reports (20260718174500:17) ·
--     live_rounds (1811) → live_round_players (1796; guest "Marco" rides here), live_scores (1831), game_results (1761) ·
--     forfeits — the pride stakes (20260724120000:20) · commissioner_log (1691) · invites (1771) · feedback (1751) ·
--     league_cancellation rows (20260726100000:19,28). SET NULL: scheduled_rounds.league_id, trophies.league_id, events.league_id.
--     NO-ACTION children (posts.member_id, live_rounds.started_by, buy_ins.marked_by, season_adjustments.*_by) are all
--     inside the same cascade tree, so the statement-end check passes.
delete from public.leagues where code in ('THEPTCQ5','DESEUU0K');

-- 3 · the seven accounts. profiles_id_fkey is ON DELETE CASCADE (baseline:1881) → profiles → rounds (1901) → round_holes (1886),
--     scheduled_rounds + round invites/rsvps (20260712150000, 20260718192400), buddies (20260712010000), device tokens & mutes
--     (20260722013000), push_subscriptions/push_nudges, photos & scan_claims.created_by (20260718045514), shares (20260722190000),
--     forfeits.party_* (20260724120000), named_rivalries, achievements, feedback, content_reports, client_events (20260717153000:22),
--     live_rounds.starter_profile_id — D107 league-less rounds (20260829090000:73). Supabase's own auth.identities/sessions cascade.
delete from auth.users where email like 'jerecho+blind%@fischbeck3.com';

-- 4 · nothing should remain
select count(*) as profiles_left from public.profiles where email like 'jerecho+blind%@fischbeck3.com';   -- 0
select count(*) as leagues_left  from public.leagues  where code in ('THEPTCQ5','DESEUU0K');              -- 0
select count(*) as guests_left   from public.live_round_players where guest_name = 'Marco';               -- 0 (baseline:1126 guest_name)
select count(*) as orphan_growth from public.growth_events
 where league_id is not null and not exists (select 1 from public.leagues l where l.id = growth_events.league_id); -- 0

rollback;   -- → commit; once every count reads right
```

After commit: `tests/db-checks.sql` check 8 (orphans) and, once T7-13 lands, 17 (§15 invariant) both PASS; the owner's Crew list carries no `+blind` name (a pending buddy request from Priya cascaded with her profile).

## Appendix B — View sketches (for T7-02; final SQL in the migration)

```sql
-- v_lock_health: one row per day (30d) + 'all' — client_events only
select coalesce(to_char(created_at at time zone 'America/Phoenix','YYYY-MM-DD'),'all') as day,
       count(*) filter (where event='lock_attempt') as attempts,
       count(*) filter (where event='lock_blocked') as blocked,
       count(*) filter (where event='lock_ok')      as ok,
       count(*) filter (where event='lock_fail')    as fail,
       count(*) filter (where event='invite_open')  as invite_open,
       count(*) filter (where event='invite_shared') as invite_shared,
       count(distinct profile_id) filter (where event like 'lock_%') as pros,
       (count(*) filter (where event='lock_fail')) > (count(*) filter (where event='lock_ok')) as fail_gt_ok,
       mode() within group (order by props->>'msg') filter (where event='lock_fail') as top_fail_msg
  from public.client_events
 where event in ('lock_attempt','lock_blocked','lock_ok','lock_fail','invite_open','invite_shared')
 group by rollup (1) …;   -- 30-day window on the daily rows; the rollup row is all-time

-- v_preseason_exposure: the season-start lint
select l.code, l.phase, ls.structure, ls.locked_at, s.starts_on,
       (s.starts_on - current_date) as days_to_first_tee,
       (select count(*) from league_members m where m.league_id = l.id) as members,
       (select count(*) from rounds r join league_members m on m.profile_id = r.profile_id
         where m.league_id = l.id and r.played_on < s.starts_on and r.created_at >= ls.locked_at) as preseason_rounds,
       (select count(*) from squads q where q.season_id = s.id
           and not exists (select 1 from squad_members sm where sm.squad_id = q.id)) as empty_squads
  from leagues l join league_settings ls on ls.league_id = l.id
  left join lateral (select * from seasons where league_id = l.id order by number desc limit 1) s on true
 where l.phase <> 'complete';
-- forbidden_state := phase='season' and (empty_squads > 0 or (structure <> 'solo' and members < 4))
```

All three: `revoke all on public.<view> from public, anon, authenticated;` and the closing `do $$ … raise exception … $$` guard.

## Appendix C — Preflight check 19, the algorithm in ten lines

1. Extract the four `<script>` blocks as check 6 does (`tests/preflight.mjs:96–113`).
2. For each block: `acorn.parse` (`ecmaVersion:'latest'`, `sourceType: module ? 'module' : 'script'`), `eslintScope.analyze` with the same options.
3. `unresolved = globalScope.through.map(r => r.identifier.name)`; drop names that are `typeof` operands.
4. `declared = ∪ classic blocks' globalScope.variables` (the classic blocks share the page's global scope) ∪ `/\b(?:window|globalThis)\.([A-Za-z_$][\w$]*)\s*=/g` matches over the whole file ∪ the browser allowlist ∪ the module's `ImportDeclaration` bindings.
5. `hits = unresolved − declared`, printed as `block N:line name` (line from `acorn`'s `locations:true`).
6. Self-test: the same routine over `tests/fixtures/no-undef-staged.js` must yield exactly `staged`, or the check FAILS itself.
7. No `acorn` → `WARN` (never PASS); `ship.sh` prints the `npm install` line.

## Appendix D — Cross-theme handshakes (names T7 reserves for other themes)

| Theme | What it must emit / keep | Why |
|---|---|---|
| T1 (lock / invite) | keep `lock_attempt/ok/fail/blocked` and `invite_open` in the `lock_league` client path; `openInviteSheet` fires `invite_shared{via}` on each control; the RPC's user-written errors surface in `lock_fail.msg` untouched | T7-02/T7-13 read them |
| T2 (covenant) | keep `covenant_seen/declined/skipped` and `joined{via}` when `join_league` is consolidated; the boot path (`:17511`) must fire `covenant_seen` before `joined` | gate row 5 |
| T3 (member Home) | `home_hero_state{state}` gains the role×stage tag; a member CTA fires `home_hero_tap{cta}` | Phase A check |
| T4 (first round) | `post_submit.preseason` stays; the practice line's presence is the re-audit's job | gate row 3 |
| T5 (rules / endgame) | `endgame_open{from}`, `rules_open{phase}` from the new surfaces | gate row 2 |
| T6 (money) | `pot_mark`/`pot_mark_denied`; `buy_in_note`/`buy_in_due_on` columns readable by the funnel view | gate row 4 |

---

*Companion: `../README.md` (how the audit was run · the cleanup SQL this plan corrects) · `../blind-ux-audit.md` §9 (monetization readiness), §11.4 (preflight / alert / harness lines), §14 (the zero-instruction test), Appendix A (hard defects) · `../critical-findings.md` Part 2 §2.1, Part 5 · `../issues.json` (M-001, M-003, M-004, M-012, M-017, M-023, M-025, M-031, M-040, M-054, M-055, M-110, M-133, M-142, M-163) · `../raw/synthesis-and-validation-results.json` (TOP-1 validators: the `lock_fail > lock_ok` alert, the no-undef lint, the app-tests case, the harness click fix).*
