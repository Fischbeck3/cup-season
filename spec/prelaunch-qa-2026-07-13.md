# Cup Season — Pre-launch QA (success-metrics walkthrough)

Task #14. Run this **on the installed PWA** (add to home screen first), with a
**stopwatch**, using **fresh plus-alias emails** (`you+t1@gmail.com`,
`you+t2@…`) so each run is a true first-timer. One tester reads the clock; the
golfer never gets coached — if they hesitate, that hesitation IS the finding.

Structural audit (v23.78, 2026-07-13) passed all five flows on code-read + demo
drive. This is the timed confirmation the audit can't fake.

**Structural re-audit (v23.163, 2026-07-16)** — after the big build-out
(translation pass, handicap engine, tee sheet, the Ryder, wizard rebuild,
hole-by-hole posting). All five gates render clean on demo drive. Three
material changes since v23.78, folded into the gates below:
- **Gate 3 changed shape:** posting is now **hole-by-hole by default** (a
  par-prefilled grid), with gross-only as a flagged escape hatch. The 60s test
  now measures the grid, not the two-number form.
- **Gate 4 forks:** the endgame is a bylaw dial (008) — Cup-Final leagues show
  "Cup line · top 2 advance," points-table leagues crown the leader outright.
  Test both readings.
- **Gate 5 has new surfaces:** live games (Match / Wolf / Skins), the Ryder,
  the endgame dial — none existed at v23.78. Probe each for "what do I do here?"

**⚠ The real launch gate is DEPLOY, not the flows** — see the findings log:
a stack of migrations + the push function + a webhook are pending; nothing
works end-to-end in prod until they ship.

---

## The five gates

Mark each run. A miss is a friction fix, not a fail to argue with.

### 1. Profile created — target < 2:00
- [ ] Land on sign-in → enter email → **code arrives** (note seconds; Brevo/Gmail lag is the risk)
- [ ] Enter code → golfer card
- [ ] Fill name, accept the suggested @handle, pick a marker → **Save my card**
- [ ] Landed in the clubhouse. **Time: ____** (target < 2:00)
- Watch for: did the code land fast? Did they understand the handle? Did the index field stall them (it's optional — did they know that)?

### 2. League joined — target < 0:30
- [ ] From clubhouse, find **Start or join a league** → enter the code
- [ ] Landed in the league. **Time: ____** (target < 0:30)
- [ ] Repeat via **invite link** (paste a real invite URL) → auto-join. **Time: ____**
- Watch for: was "join" findable without hunting? Did the link auto-join or dead-end?

### 3. Round posted — target < 1:00  *(reshaped AGAIN by D32, 2026-07-17)*
- [ ] Post tab → **Course** (type real course → pick course → pick tee; rating/slope autofill) + date
- [ ] **Front & back (the default, D32):** two boxes — "41 out, 43 in" → the
      Gross line reads right → **Post round**. **Time: ____** (target < 1:00)
- [ ] **The full card (opt-in):** switch to **Hole by hole** — the grid opens on
      par, adjust the holes you didn't par, post. **Time: ____** (expected
      slower; that's fine — it's the receipt, not the fast path)
- [ ] **No course match:** type a course not in the DB → type rating/slope by hand → post. Still under a minute?
- Watch for: does front/back read instantly as "how I already keep score," or
  do they hunt for per-hole entry? Course search speed, tee-list clarity,
  whether the autofill was trusted. On the full card: the untouched-grid
  **soft block** ("Post as even par?") now intercepts a rushed post — if a
  tester hits it, note whether the sheet read as help or as friction.
- Note: gate 3 is also **passively measured on every real post** — see
  "Tracking the gates during the pilot" below. The stopwatch run validates the
  first-timer experience; the passive layer validates the cohort.

### 4. Standings understood — target < 0:10
- [ ] Open the league standings cold. Ask: **"Who's winning, and what do they need to do to take the cup?"**
- [ ] Answered correctly in **____ seconds** (target < 0:10)
- Watch for: the storytelling line ("leads by 25 · 25 back") should answer it
  before they read the table. **Test BOTH endgames** (008 dial): a Cup-Final
  league ("Cup line · top 2 advance," +10 head-start) AND a points-table league
  (leader crowned outright — is that obvious, or do they expect a playoff?).
- [ ] A round card reads right: "84 · beat your number by 0.6 → 7 pts" — no
  "PvI"/"differential" leaks. Tapping a points figure opens the rounds behind it.

### 5. Zero tutorial
- [ ] Did the tester ask "what do I do here?" at any screen? **Where: ____________**
- Every such spot is the highest-value fix.
- **New v23.163 surfaces to probe** (none existed at the last audit):
  - **Tee off → pick a game** (Match / Wolf / Skins): does the strokes preview
    ("Danny gets 3: holes 2, 7, 14") and the settlement recap explain themselves?
  - **The Ryder** scoreboard: is "First to 9½," the duel chips, and "Duel taunts:
    OFF" self-evident?
  - **Wizard** endgame + pot-split choices, the roster-fit dimming, the fine-print disclosure.
  - **Handicap "establishing"**: a new golfer sees "2 of 3 · Building your number"
    — reassuring or confusing?

---

## Also verify (not timed, but launch-blocking)
- [ ] **OTP email**: arrives within ~30s, code-only (no link), works on first entry. Test a fresh address AND a repeat sign-in.
- [ ] **Add to home screen**: install prompt works; the app opens full-screen with the current icon.
- [ ] **Course search live**: `papago` returns tees on the real PWA (confirms the Edge Function + secret in prod).
- [ ] **Realtime**: post from one device, watch it land on another without refresh.
- [ ] **Light mode + one-handed**: run gate 3 in light mode and thumb-only.

## Tracking the gates during the pilot (added 2026-07-17, D33)

With PIGL live, every member's first week IS a gate run — captured passively
instead of with a stopwatch. Migration `20260717153000_pilot_instrumentation`
ships the layer; the client fires four breadcrumbs (`post_open`, `post_submit`,
`post_mode_switch`, `post_even_par_confirmed`) into `client_events`.
Demo mode never emits; failures are swallowed; deploy-skew-safe (a missing
table just drops the breadcrumb, never the post).

**Weekly ritual (Mondays, SQL editor — both views are operator-only, revoked
from the API roles):**

```sql
-- Gates 1–2 + days-to-first-round, per member
select * from v_pilot_gates order by signed_up_at;

-- Gate 3 + the D32 mode mix
select mode, count(*) posts,
       percentile_cont(0.5) within group (order by secs) as median_secs
from v_post_timings group by mode;

-- Friction signals: hatch reversals + deliberate even-pars
select event, count(*) from client_events
where event in ('post_mode_switch','post_even_par_confirmed')
group by event;
```

Pass thresholds become **cohort medians**, not one tester's run: gate 1 median
< 2:00, gate 2 median < 0:30, gate 3 median < 1:00. `otp_seconds` isolates the
Brevo lag inside gate 1. A NULL `card_saved_at` means someone stalled ON the
golfer card — itself a finding.

**Gates 4–5 stay human.** Comprehension can't be logged: ask each member
"who's winning and what do they need?" casually in the group chat the first
time they open standings (< 10s to a right answer = pass), and route every
"what do I do here?" to `pilot_feedback` (already live in-app). Each Monday:
add a dated entry below; every finding becomes a fix commit or an explicit
waive.

## Findings log
_(date · gate · what stalled · fix)_

### 2026-07-17 · pre-pilot state
- **DB wiped for the pilot** (keeper: jerecho@fischbeck3.com; backup
  `pre_pilot_backup_2026-07-17.sql`, restorable). The gate views will see only
  true pilot cohort data from here.
- **Gate 3 reshaped by D32:** front & back is now the default post; the timed
  script above is updated. The old 60s-on-the-grid measurement is obsolete.
- **F2 upgraded:** the untouched-grid soft block shipped; deliberate even-par
  posts now emit `post_even_par_confirmed`, so F2 is measured, not guessed.
- **F1 residue — still unconfirmed in prod** (two minutes in the dashboard
  before the crew shows up): the `push` Edge Function deploy, the
  `push_nudges` webhook, and **pg_cron enabled** (without it, month-closes and
  the Ryder tick silently never fire — that would poison pilot data in week 1).

### 2026-07-16 · structural re-audit (v23.163) — findings

**F1 · THE launch gate: deploy state (blocking, not a flow finding).** A large
stack shipped this session and is only live once pushed. Before ANY timed run,
confirm prod is current:
- `supabase db push` — migrations `20260716080000` … `20260716180000` (live-round
  spine, handicap engine + starter guard, match/wolf/skins, Ryder v2 + slice 3,
  endgame dial 008, auto-bye). The handicap-engine backfill + the crowning logic
  only exist after this.
- `git push` — client through v23.163 (Netlify). Diagnostic: cupseason.app
  `#obCaption` should read **v23.163**.
- `supabase functions deploy push` — event-post fan-out + the duel-taunt branch.
- Dashboard: a **Database Webhook on `push_nudges` INSERT → push fn** (same
  `x-push-secret` as the posts webhook). Without it, duel taunts never fire.
- pg_cron: `run_event_sessions` (Ryder tick) self-schedules only if pg_cron is
  enabled — confirm, or the Ryder won't auto-open/resolve sessions.

**F2 · Gate 3 first-timer risk (watch in the timed run).** Hole-by-hole is now
the default and the grid opens on par. A tester who taps "Post" without
adjusting posts an accidental even-par. Safeguard shipped: the live "Gross NN"
line. If a real tester misses it, the fix is to make that line louder (or block
the post when the grid is untouched). Flagged, not yet a defect.

**F3 · Boot console noise (pre-existing, own task).** Every fresh boot throws
two caught async rejections ("reading 'n'") and logs "[boot] no session" 20+
times (onAuthStateChange likely firing repeatedly). Not user-visible (errbar is
`?debug`-gated), but clear both before launch — a repeated boot is a
battery/perf smell on mobile. Spawned as its own task.

**F4 · Passed clean on demo drive:** onboarding ("You're in."), the post grid
(par→72, adjust, floor-at-1, 9-hole half-value, escape hatch), storytelling
standings ("leads by 25 · 25 back"), named-band round cards, scoring-help
disclaimer, the Ryder scoreboard, wizard endgame/pot/fine-print. No new
structural friction from the build-out.

**Still un-run: the timed human walkthrough** (F1 must clear first). The five
gates above are the script; this re-audit only confirms the structure the
stopwatch will measure.
