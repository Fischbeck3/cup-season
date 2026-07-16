# Cup Season — Deploy Runbook (v23.173)

**Cut:** 2026-07-16 · GROWTH/LAUNCH lane · supersedes `deploy-runbook-v23.163`.

## State at this cut (verified, not assumed)

| Layer | State | Action |
|---|---|---|
| **Client** (`index.html`/`sw.js`) | **v23.173 LIVE** on Netlify — confirmed off `cupseason.app` `#obCaption`, not cache. `HEAD == origin/main`. | **None.** No unpushed client commits. |
| **`push` Edge Function** | Last changed **v23.159** (Ryder slice 3); deployed at the v23.163 deploy. No pending migration touches it. | **Verify-only** (see G0). Do NOT redeploy blindly. |
| **`push_nudges` INSERT webhook** | Created at v23.163 (twin of the `posts` webhook, same `x-push-secret`). | **Verify-only** (G0). |
| **pg_cron** | 4 jobs confirmed active at v23.163: `cs-daily-tick`, `cs-month-close`, `cs-week-snapshot`, `run_event_sessions`. No pending migration adds a job. | **Verify-only** (G0). |
| **Database migrations** | Remote current through `20260716180000_auto_bye` (v23.163). **4 migrations pending.** | **`supabase db push`** — the one real open item (G1). |

**Pending migrations** (landed after the v23.163 deploy):

| # | File | Ships (client version) | Adds |
|---|---|---|---|
| 1 | `20260716190000_moment_voice.sql` | v-db | storyteller voice on `round_moments()` trigger (`create or replace`) |
| 2 | `20260716200000_post_round_peak.sql` | v23.164 | `round_epilogue(uuid)`, `squad_lead_moments()` trigger |
| 3 | `20260716210000_named_rivalries.sql` | v23.165 | `rivalry_names` table, `set_rivalry_name`, `my_rivalries`, `round_epilogue` (re-grant) |
| 4 | `20260716224500_season_scenarios.sql` | v23.169 | `season_scenarios(uuid)` — clinch/scenario math |

**Why this is the launch gate, not a nicety:** the live **v23.173** client already
calls `season_scenarios`, `my_rivalries`, `set_rivalry_name`, and `round_epilogue`.
Every call is wrapped in try/catch, so prod does **not** crash — but three features
are **silently dark right now**: the season-clinch/scenario line, named rivalries,
and the post-round epilogue sheet. `db push` turns them on.

**Safety scan (done):** all 4 are additive — `create ... if not exists`,
`create or replace`, every new RPC has `grant execute ... to authenticated`. The
only DROP is a guarded `drop function if exists my_rivalries()` (return-type swap,
not the RLS-policy-teardown landmine). No column/table drops, no destructive DDL.

---

## The ordered run (USER runs all `supabase`/`git` commands — sandbox can't)

> **GOTCHA (cost time before):** run these **one at a time**. Pasting the block as
> one chunk lets `supabase db push`'s `Y/n` prompt swallow the following lines.

### G0 — Pre-flight verify (no side effects, ~1 min)

```powershell
cd C:\Users\17203\Downloads\cup-season
supabase migration list
```
Confirms Local vs Remote. **Expect Remote current through `20260716180000` and the 4
above showing Local-only.** If Remote already lists any of the 4, someone pushed
since — `db push` in G1 will simply skip them (idempotent), no harm.

```powershell
supabase functions list
```
Confirm `push` is **deployed**. (It's current as of v23.159 — only redeploy if this
shows it missing/undeployed.)

**Dashboard (eyeball, no command):** Database → Webhooks → confirm the
`push_nudges` INSERT → `push` fn hook exists. Database → Extensions/Cron → confirm
the 4 jobs (`cs-daily-tick`, `cs-month-close`, `cs-week-snapshot`,
`run_event_sessions`) are active. Both were verified at v23.163; this is a re-confirm.

### G1 — Push the database (the one real change)

```powershell
supabase db push
```
Applies the 4 pending migrations. **When it lists the migrations and prompts `Y/n`,
read the list — it must be exactly the 4 above — then `Y`.** Adds `rivalry_names`,
the `round_epilogue` / `season_scenarios` / `my_rivalries` / `set_rivalry_name` RPCs,
and the storyteller-voice trigger. Additive; safe; no client redeploy needed.

### G2 — Post-push verify (confirm the dark features lit up)

```powershell
supabase migration list
```
All 4 now show Remote. Then, in the app (live PWA, signed in to a real league):
- Open a league in an active season → the **scenario/clinch line** should render
  (was blank pre-push).
- Open the **rivalries** surface → named rivalries load; naming one persists.
- Post a round → the **post-round epilogue** sheet appears over Home.

No client action, no `git push` — the client is already v23.173 live.

---

## Then: the timed five-gate QA walkthrough

Deploy gate (F1 in `spec/prelaunch-qa-2026-07-13.md`) is **clear** once G1/G2 pass.
Run the timed human walkthrough per that spec — **on the installed PWA**, with a
**stopwatch**, **fresh `you+t1@gmail.com` plus-aliases** per run, golfer un-coached
(hesitation IS the finding). The five gates + targets:

1. **Profile created** < 2:00 — email → code lands → golfer card → Save.
2. **League joined** < 0:30 — code, then repeat via invite link (auto-join).
3. **Round posted** < 1:00 — hole-by-hole grid (watch: does the tester read the live
   "Gross NN" line, or post an accidental even-par? — F2), then the "Just the total"
   escape hatch, then a no-match course typed by hand.
4. **Standings understood** < 0:10 — "Who's winning, what do they need for the cup?"
   Test **both** endgames (Cup-Final vs points-table, 008 dial). Now also probe the
   **scenario line** just lit up in G2.
5. **Zero tutorial** — any "what do I do here?" spot is the top fix. New surfaces:
   Match/Wolf/Skins tee-off, the Ryder scoreboard, wizard endgame/pot, handicap
   "establishing."

Also (untimed, launch-blocking): OTP arrives ~30s code-only; add-to-home-screen;
`papago` course search returns tees live; realtime cross-device; light-mode + thumb.

Log findings in `spec/prelaunch-qa-2026-07-13.md` → Findings log.
