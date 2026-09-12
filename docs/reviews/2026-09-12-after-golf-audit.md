# The after-golf prompt — audit of scheduled rounds → Home dispatch → posted rounds

**2026-09-12 · read-only · `claude/after-golf-audit` at `origin/main` (246b77a).**
Nothing was built. Every claim below was read from source and, where marked
*(prod)*, verified against the linked production database with SELECT only.
Implementation is Codex's on its own branch; this is the contract and the
acceptance bar, not a patch.

This is the deep version of `spec/inbox.md` items **16** (a plan whose day has
passed is never asked about), **28** (nothing ties a posted round to the plan)
and **29** (the live bridge is shallow).

---

## 0 · The finding in one paragraph

**The loop has no closing act, and the reason is one clause.** The deployed
`home_dispatch` considers a plan only inside `play_on between v_today and
v_today + 8` — future only — so the moment a tee time passes the plan leaves
Home and is never mentioned again. Verified against the deployed function, not
the migration file: `position('between v_today and v_today + 8' in
pg_get_functiondef('public.home_dispatch(integer)'))` is true, and
`position('did_you_play' …)` is false. The source is
`supabase/migrations/20261012090000_the_server_says_the_sentence_the_golfer_reads.sql:1277`,
with `v_today date := current_date` at `:772`.

---

## 1 · Who qualifies

### The participant model, as built

| Role | Where it lives | File |
|---|---|---|
| Host | `scheduled_rounds.profile_id` | `20260712150000_declared_rounds_and_roster.sql:21` |
| Tagged | `scheduled_rounds.tagged uuid[]`, host excluded from their own tag list | `20260712170000_tag_your_foursome.sql:12` · `20260718192400_round_object.sql:191` |
| RSVP | `round_rsvp(round_id, profile_id, status)`, `status in ('in','maybe','out')` | `20260718192400_round_object.sql:45` |
| Link-redeemed stranger | `redeem_share` appends the tag **and** the RSVP in one transaction | `20260921100000_the_plan_link.sql` header |
| Visibility (wider than participation) | `can_see_round()` = host **or** tagged **or** accepted friend **or** league mate | `20260718192400_round_object.sql:24` |
| Cancellation | `scratch_round(p_id)` — a hard delete, host only | `20260712150000_declared_rounds_and_roster.sql:78` |

**Two different tagging systems exist and must not be confused.**
`scheduled_rounds.tagged` names people on a **plan**; `round_players`
(`20260910093000_who_was_out_there.sql:31-38`) names people on a **posted
round**, with `claimed_by` and `confirmed_at`. Only the first one is in scope
here. Worth noting for §4: `confirm_round_partner`
(`20260917100000_a_partner_can_answer.sql:78`) **deletes the row on decline**
rather than recording the denial — the same history-erasing shape this audit
rejects for "Didn't play", and a precedent to avoid rather than copy.

### Three facts that decide the predicate

1. **The host is not seated in the table, only in the read.** `declare_round`
   inserts into `scheduled_rounds` and writes **no** `round_rsvp` row
   (`20261012090000…sql:1457`, the current 8-argument definition). `my_schedule`
   papers over it by **synthesising** the host as `status:'in'`, ord 0
   (`20260924093000_a_weekend_has_a_name_and_a_game.sql:207-214`), and a tagged
   golfer with no row is synthesised as `'asked'` — a value that is computed and
   never stored. So the vocabulary a client sees is `in | maybe | out | asked`,
   while the table only ever holds the first three.
   **This decides where the new query reads from.** Against `round_rsvp`
   directly, the host has no row and must be special-cased. Against
   `my_schedule`'s shape, the host arrives as `in` for free. Read from the
   same place the upcoming band reads, and the two bands cannot drift.
   This is inbox item 12, still true. *(prod: 5 plans, 3 RSVP rows, all `in`;
   zero `maybe`, zero `out`.)*
2. **`can_see_round` is the wrong gate.** It admits any league mate and any
   accepted friend. Those people can read the plan; they did not play it.
   Using it would ask a whole league whether they played one person's round.
3. **There is no cancelled state.** `scratch_round(p_id)` is a **hard delete**
   — `delete from scheduled_rounds where id = p_id and profile_id = auth.uid()`
   (`20260712150000_declared_rounds_and_roster.sql:78-84`, never redefined) —
   cascading to `round_rsvp` and `round_comments`. The board post survives with
   `posts.scheduled_round_id` set null
   (`20260902203000_a_booking_knows_its_round.sql:12,33`). So "exclude cancelled" costs nothing: the row is gone. The
   cost is elsewhere and worth stating — **a plan cancelled after its day is
   indistinguishable from one that never existed**, so no prompt, no history,
   no way to tell the two apart later.

### The predicate

Qualify a golfer for a plan when **`sr.profile_id = uid` OR `uid = any(sr.tagged)`**,
and **no** `round_rsvp` row for that pair has `status = 'out'`.

That is deliberately the same shape the existing upcoming band already uses —
`coalesce(e->>'my_rsvp','') <> 'out' and (mine or tagged_me)`
(`20261012090000…sql:1274-1275`) — so the two bands agree about who a plan
belongs to, and there is one rule to change if the owner later rules that
`maybe` should be treated differently from silence.

**`maybe` qualifies.** They may well have played; the prompt's own answers
settle it. Only an explicit `out` is a statement that they were not there.

**One structural constraint, for §5.** `scheduled_rounds` carries a single RLS
policy, `sched_own`, `FOR ALL TO authenticated USING (profile_id = auth.uid())`.
A tagged golfer **cannot read the plan row at all** by direct select; every
non-host read in the product already goes through a SECURITY DEFINER RPC. So
the new read and the new write are both definer by necessity, not by
preference.

---

## 2 · When the prompt appears

### The timezone defect, measured

*(prod, 2026-09-12)* `current_setting('TimeZone')` is **`UTC`**.

| Clock | Source | File |
|---|---|---|
| Server | `v_today date := current_date` → **UTC** | `20261012090000…sql:772`, `20260906090000_the_strip_has_its_own_facts.sql:90` |

`native_home` feeds the band by calling `my_schedule(v_today, v_today + 14)`
(`20261019090000_the_card_knows_where_it_has_been.sql:836-838`) — a
**forward-only** 14-day range. A past plan is therefore absent from the payload
before `home_dispatch` ever filters it, so widening only the `+ 8` clause would
change nothing. **Both ranges have to move.**

| Phone | `CSDate.today(calendar: .current)` → **device local** | `CupSeasonKit/Dates.swift:25` |
| Web | `new Date()` with `getFullYear/getMonth/getDate` → **browser local** | `index.html:12676`, `:16474` |

Phoenix is UTC−7 with no DST, so **from 17:00 to 23:59 local the server already
believes it is tomorrow.** A golfer has no timezone at all: `profiles` carries
none (read from `00000000000000_initial_baseline.sql`); the only timezone column
in the schema is `seasons.timezone`, default `America/Phoenix` (`:1300`), which
does not exist for a leagueless golfer and may differ across two leagues for
everyone else. One migration already does it properly —
`(now() at time zone coalesce(se.timezone,'America/Phoenix'))::date`
(`20260902160000_the_defaults_the_wizard_shows.sql:203`) — so the precedent
exists and Home does not follow it.

**A live bug falls out of this, unrelated to the prompt.** `declare_round`
raises *"Pick a day that has not happened yet"* when
`p_play_on < current_date` (`20260718192400_round_object.sql:188`). After 17:00
Phoenix, `current_date` is tomorrow, so **a golfer cannot schedule a round for
this evening.** Worth its own inbox line whatever happens to the prompt.

### The rule

Same-day is already handled and should stay handled where it is: the live
path's bridge, `LiveRepository.todaysPlan()`
(`CupSeasonKit/Live/LiveRepository.swift:398`), asks *"Your round today · Gold
Canyon"* on the phone's own clock. The after-golf prompt's job is **the day
after**, which is the gap.

Fire when `play_on` is in **`local_today − 3 … local_today − 1`**.

- Three days bounds the nagging and matches the `closing` tier's own sense of
  three days (`:1279`, `case when v_d <= 3`).
- Starting at −1 means the prompt never interrupts play and never argues with
  the live bridge.
- No tee-time arithmetic is needed, so no local *time* has to cross the wire —
  only a local *date*, which is what L-07 already says a date is.

---

## 3 · How a posted round suppresses it

### There is no link to lean on

`rounds` has **no** `scheduled_round_id` and `scheduled_rounds` has no
`round_id`, no `played` flag and no status. The only `scheduled_round_id` in
the schema is on **`posts`** — a booking announcement pointer, stamped by
`declare_round`, and authenticated holds no INSERT privilege on that column
(`20260902210000_a_booking_pointer_is_the_servers.sql:50`). The only join
between plans and rounds anywhere is `my_course_books`, and it aggregates **per
course**, never per round (`20261009093000_the_card_carries_its_yardage.sql:40-55`).
This is inbox item 28, unchanged.

So suppression has to be **inferred**, from these columns only:
`rounds.profile_id`, `rounds.played_on` (`date default current_date not null`,
baseline `:1251`), `rounds.api_course_id`
(`20260714050000_course_cache_reconcile.sql:58`), `rounds.voided`, against
`scheduled_rounds.play_on`, `.course_id`, `.course_label`.

### Course id cannot be required

*(prod, 2026-09-12)* **4 of 5 plans carry a null `course_id`.** A rule that
demands a course match would suppress almost nothing and the prompt would keep
asking golfers about rounds they had already posted. The same nullability is
what inbox item 11 is about.

### The rule

Suppress a plan's prompt for a golfer when that golfer has **any** non-voided
round on the plan's day, unless both sides name a course and the courses
differ:

```
exists (select 1 from rounds r
         where r.profile_id = <golfer>
           and not coalesce(r.voided, false)
           and r.played_on = sr.play_on
           and (sr.course_id is null
                or r.api_course_id is null
                or r.api_course_id = sr.course_id))
```

Read it as: **same day suppresses, unless we have positive evidence it was a
different course.** Absence of a course id is not evidence.

- **Multiple rounds that day:** `exists` — any one matching round suppresses.
  A golfer who played 36 and posted once is not asked twice.
- **Two plans on one day:** each plan is its own key, so both would fire. Cap
  it: **one after-golf item per day**, the plan with the earliest `tee_time`,
  nulls last. Otherwise the same golfer gets two cards about one afternoon.
- **`played_on` is the golfer's own claim**, not a derived instant, so this
  comparison is local-date to local-date and carries no timezone risk.
- **Reconciliation is free.** The prompt is computed per request, so posting
  the round makes it vanish on the next Home load. No state, no cleanup job.

**The real fix is item 28's one nullable column** (`rounds.scheduled_round_id`,
stamped by `post_round` when the composer came through the bridge). It is
**not** a prerequisite — the inference above works today — and it is a mechanic
change that needs its own decision entry first. Name it as the follow-on.

---

## 4 · "Later" and "Didn't play", without rewriting history

### What must not happen

The cheap implementation is to write `round_rsvp.status = 'out'`. **That
rewrites history.** It asserts the golfer was never in, it retroactively
changes `rsvp_in` counts that the plan's own card and every past Home item
quoted, and it is indistinguishable from an RSVP made before the round. The
plan row cannot absorb it either: `scheduled_rounds` has no status column, and
its only lifecycle verb is a hard delete.

### The shape

A separate record of **an answer to a question**, not a change to the plan:

```sql
create table public.plan_followups (
  scheduled_round_id uuid not null references public.scheduled_rounds(id) on delete cascade,
  profile_id         uuid not null references public.profiles(id) on delete cascade,
  answer             text not null check (answer in ('later','didnt_play')),
  snooze_until       date,          -- 'later' only; null for 'didnt_play'
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  primary key (scheduled_round_id, profile_id)
);
```

- **`didnt_play` is terminal.** The prompt never returns for that pair.
- **`later` sets `snooze_until = local_today + 1`.** The prompt returns the
  next day, still inside the three-day window, so it can be deferred at most
  twice before ageing out on its own. Nothing has to expire it.
- **The plan, the RSVP rows and the board are untouched.** Every historical
  figure still reads the way it read.
- Upsert on the primary key so `later` → `didnt_play` replaces cleanly; never
  delete, so the answer survives as the record of having been asked.

### Authorization

Follow `round_rsvp`'s own pattern (`20260718192400_round_object.sql:52-55`):
RLS on, **no insert or update policy at all**, writes through a SECURITY
DEFINER RPC. Read policy is narrower than the RSVP table's, though — this is
the golfer's own answer and nobody else needs it:

```sql
create policy plan_followups_read on public.plan_followups
  for select to authenticated using (profile_id = auth.uid());
```

The write RPC must check the **participation** predicate from §1 (host or
tagged), **not** `can_see_round` — a league mate must not be able to answer for
a round they were never on.

---

## 5 · The smallest shared contract

Three pieces. Two are additive-by-default; one is a new function.

### 5.1 · One defaulted argument on an existing function

```
home_dispatch(p_days integer default 21, p_today date default null)
```

`p_today` is the caller's local calendar date. The server uses
`coalesce(p_today, current_date)` and **clamps it to `current_date − 1 …
current_date + 1`**, so a device with a broken clock cannot mine history or
skip ahead. Both clients already compute this value: `CSDate.today()`
(`Dates.swift:25`) and `index.html:12676`.

Defaulting the new parameter is exactly CLAUDE.md's deploy-skew rule ("new SQL
functions default their added params"), so an old client calling
`home_dispatch(21)` keeps working unchanged. It also fixes the existing
off-by-one in the **upcoming** band as a side effect.

Grants follow D37 verbatim, matching the current lines at
`20261012090000…sql:1454-1455`:

```sql
revoke all on function public.home_dispatch(integer, date) from public, anon;
grant execute on function public.home_dispatch(integer, date) to authenticated;
```

### 5.2 · A new dispatch item family, in the existing item shape

Key `afterplan:<plan_id>`. **No new fields.** The item uses the sixteen keys
the shape already has (`key, tier, band, mods, mod_reason, subject,
human_subject, eyebrow, headline, standfirst, action, route, league_id,
suppress, spine, at` — `20261012090000…sql:1293-1310`).

This is the important compatibility result: **the item renders and routes on
today's shipped builds with zero client changes.**

- `route` is `{"kind":"plan","id":…}`, and `"plan"` is already decoded —
  `HomeDispatch.swift:92`, `case "plan": return id.map(Route.plan)`.
- An unrecognised `tier` decodes to `.opportunity`, the lowest band and
  documented as "the safest place to put a fact this build does not recognise"
  (`HomeDispatch.swift:31-35`).
- An unknown key family "spends nothing, which is the safe answer — an unknown
  item is shown, never silently dropped" (`HomeDispatch.swift:303-307`). Since
  `afterplan` is a different family string from `plan`, it will not claim
  `.myNextRound` off the ME strip (`:316`), which is correct: the strip's NEXT
  slot is about the future and this item is about the past.
- `suppress` is `[]`.
- `action` must be a door that works on **every** build: **"Post this round"**,
  routing to the plan. Later / Didn't play are secondary controls that appear
  only on builds that know the new RPC, so an old build degrades to a single
  working door rather than a dead one.

Suggested band values, consistent with the existing ladder: `tier` `changed`,
`band` 800 — above `coming` (600) because it is a thing that has happened and
is waiting on the golfer, below `closing` (1000) because nothing expires today.

### 5.3 · One new RPC

```
answer_plan_followup(p_plan uuid, p_answer text) returns void
```

SECURITY DEFINER, `set search_path = public`. Raises on: not signed in;
`p_answer` not in `('later','didnt_play')`; the caller not host-or-tagged on
`p_plan`; the plan's `play_on` not in the past. Upserts `plan_followups`,
setting `snooze_until` for `later` only.

```sql
revoke all on function public.answer_plan_followup(uuid, text) from public, anon;
grant execute on function public.answer_plan_followup(uuid, text) to authenticated;
```

The anon surface stays at twelve (L-36/L-45). Nothing here is reachable
signed-out.

### 5.4 · Deployment compatibility matrix

| | Old server | New server |
|---|---|---|
| **Old client** | today's behaviour | new item decodes, renders, routes; single working door; tier falls to `opportunity` if unknown |
| **New client** | `p_today` unknown → PGRST202 / 42883; the web already retries by dropping the arg (`index.html:10100`), **the phone needs the same drop-arg retry added**; no `afterplan` items appear, which is today's behaviour | full behaviour |

The one piece of client work that is not optional is the phone's drop-arg
retry for `p_today`. Everything else degrades on its own.

**One trap on the generated side.** `packages/db/contract.psv` is already stale
— it still lists the dropped 5/6-argument `declare_round` and a 17-column
`my_schedule` against today's 8 and 21. `tools/build-db.mjs` generates
`Rpc.swift` from that file and only functions granted to `authenticated` get a
Swift name, so the compiler enforces D37 off a snapshot that is behind
production. Refresh `contract.psv` **after** the push, never ahead of one
(the rule `ScheduleModels.swift:11-14` already records), and expect the new
`p_today` overload to need a hand-declared call until it is refreshed.

### 5.5 · What the contract deliberately does **not** include

- No `rounds.scheduled_round_id`. It is the better long-term answer (item 28)
  and a separate mechanic decision.
- No new push kind. `push_nudges` already admits `tee_tomorrow`
  (`20260928090000_ten_kinds_of_nudge.sql:41`), the push function routes it
  (`supabase/functions/push/index.ts:128`) and the phone maps it
  (`PushPayload.swift:66`) — and **no function in the repo has ever inserted
  one**. Whether the after-golf moment is also a push is the owner's call, and
  it is a bigger question than the Home card.
- No `profiles.timezone`. `p_today` makes it unnecessary.
- No change to `declare_round`, `set_round_rsvp`, `post_round` or any scoring
  path.

---

## 6 · Acceptance cases

Server cases belong in `tests/db-checks.sql` (65 checks today); client cases in
`HomeDispatchDecodeTests` / `HomeFallbackItemsTests` /
`HomeRankTests`, which already exist.

### Qualification

1. **Host, no RSVP row** — plan yesterday, host never RSVP'd. → prompt appears.
   *(This is the case the current data makes the default: `declare_round`
   writes no RSVP.)*
2. **Tagged golfer, RSVP `in`** → prompt appears.
3. **Tagged golfer, RSVP `maybe`** → prompt appears.
4. **Tagged golfer, RSVP `out`** → no prompt, for that golfer only; the host
   still gets theirs.
5. **League mate who can see the plan but is neither host nor tagged** → no
   prompt. Guards against `can_see_round` creeping in.
6. **Accepted friend of the host, not tagged** → no prompt.
7. **Plan deleted after its day** → no prompt, no error, no orphan row
   (`on delete cascade` on both `round_rsvp` and `plan_followups`).

### Timing

8. **Plan `play_on = local_today`** → no prompt (the live bridge owns today).
9. **Plan `play_on = local_today − 1`** → prompt appears.
10. **Plan `play_on = local_today − 4`** → no prompt (aged out).
11. **Phoenix at 18:00 on the day of play** — `current_date` is already
    tomorrow, `p_today` is today. → **no prompt.** This is the case that fails
    if `p_today` is ignored, and it is the reason the argument exists.
12. **`p_today` two days behind `current_date`** → clamped; behaves as
    `current_date − 1`.
13. **`p_today` omitted entirely (old client)** → falls back to `current_date`;
    no error.

### Suppression

14. **A non-voided round exists with `played_on = play_on`, both course ids
    null** → suppressed.
15. **Round that day with `api_course_id` equal to the plan's `course_id`** →
    suppressed.
16. **Round that day with a *different* non-null `api_course_id`, plan has a
    non-null `course_id`** → **not** suppressed.
17. **Round that day, plan `course_id` null, round `api_course_id` set** →
    suppressed (absence is not evidence).
18. **Two rounds that day, one matching** → suppressed.
19. **Only a voided round that day** → not suppressed.
20. **Two plans on one day, both qualifying** → exactly one item, the earlier
    `tee_time`, nulls last.

### Answers

21. **`later`** → no prompt today; prompt returns tomorrow; `round_rsvp`
    unchanged; the plan's `rsvp_in` count unchanged.
22. **`didnt_play`** → prompt never returns for that pair; `round_rsvp`
    unchanged.
23. **`later` then the round is posted** → suppressed by §3 regardless of the
    followup row.
24. **`answer_plan_followup` called by a league mate who is not host or
    tagged** → raises; no row written.
25. **`answer_plan_followup` on a future plan** → raises.
26. **Bad `p_answer`** → raises; the check constraint is the second line of
    defence, not the first.
27. **A golfer's followup row is invisible to every other golfer**
    (RLS `profile_id = auth.uid()`), asserted with a real second identity, not
    by reading the policy text.

### Contract

28. **Old build decodes an `afterplan` item** — renders, routes to the plan,
    spends no ME-strip fact.
29. **An unknown `tier` on the new item** → `.opportunity`, still rendered.
30. **New client against an old server** → drop-arg retry fires once; Home
    renders; no error toast.

---

## 7 · Production reality, for sizing

*(all read-only, 2026-09-12)*

| | |
|---|---|
| Plans total | 5 |
| Plans in the past | 4 |
| Plans with a null `course_id` | 4 |
| RSVP rows total | 3 — all `in`; zero `maybe`, zero `out` |
| Plans carrying a `name` or a `game` (D240) | 0 |
| Non-voided rounds | 213 |
| Host + date matches between a round and a plan | 3 |

Four of five plans are already past and would be in scope for a backfill the
first time this ships; three of them already have a same-day round and would be
suppressed immediately. **The prompt would fire, today, for approximately one
plan.** That is not an argument against building it — it is an argument for
building the cheap version in the contract above, and for the inbox's own
reading that "plans are unused because nothing ever comes of one."
