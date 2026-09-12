# After-golf contract — follow-up review

**2026-09-12 · read-only against production · `claude/after-golf-audit`.**
Answers the five checkpoints in `2026-09-12-tandem-work.md`. It **corrects two
things** in `2026-09-12-after-golf-audit.md`: one of them would have taken Home
down for every shipped client, and the other would have shipped a button that
lies. Both were found by doing what the checkpoint asked rather than by
reasoning from the first report.

Evidence marked **OBSERVED** was run. PostgreSQL behaviour was proven on a
throwaway local PostgreSQL 17 cluster created in the session scratchpad and
deleted afterwards — **production was never written to**, and no local cluster
of the owner's was touched.

Nothing here is a frozen contract. §4 separates what the code forces from what
the owner has to rule.

---

## 1 · The defaulted argument does **not** replace the old function — it breaks every caller

### What I proposed, and why it was wrong

The first report said: add `p_today date default null` to `home_dispatch`, and
cited CLAUDE.md's rule that "new SQL functions default their added params — so
neither order breaks a live user." That rule is about **replacing** a function.
Written as an addition it creates an **overload**, and PostgreSQL then cannot
choose between them.

### OBSERVED — PostgreSQL 17, both functions present

```
create function home_dispatch(p_days integer default 21) …           -- the shipped one
create function home_dispatch(p_days integer default 21,
                              p_today date default null) …           -- the proposed one
```

| Caller | Result |
|---|---|
| `home_dispatch(21)` — positional | `ERROR: function home_dispatch(integer) is not unique` |
| `home_dispatch(p_days => 21)` — the named form PostgREST sends | `ERROR: function home_dispatch(p_days => integer) is not unique` |
| `home_dispatch()` | `ERROR: function home_dispatch() is not unique` |
| `home_dispatch(p_days => 21, p_today => current_date)` | works |

**Every shipped client calls the first or second form.** The migration would
have broken Home for all of them the moment it ran, on both clients, with no
client change able to prevent it and no skew-retry able to catch it — the
retry fires on "function not found", and this is "not unique".

Production currently holds exactly one overloaded name in `public`
(`score_round`, a trigger function beside a callable), so there is no precedent
that would have caught this by analogy.

### OBSERVED — the safe strategy

Drop the old signature and create the new one **in the same migration**. Supabase
runs a migration file in a transaction, so there is no window in which neither
exists. This is the repo's own precedent — `drop function if exists
public.my_schedule(date, date);` immediately before the recreate at
`20260718192400_round_object.sql:207`.

```sql
drop function if exists public.home_dispatch(integer);
create or replace function public.home_dispatch(p_days integer default 21,
                                                p_today date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$ … $$;
```

After that, **all four caller shapes above return the new function.** One
function exists, so PostgREST has nothing to resolve.

### OBSERVED — and the grants do not survive the drop

| | `proacl` |
|---|---|
| before `drop` | `=X/…, …=X/…, authenticated=X/…` |
| after `drop` + `create or replace` | **default — no explicit grant** |

Under D37's revoked default privileges, "default" means **no access**. The
migration must re-issue both lines or the RPC silently 403s in production,
which CLAUDE.md already names as the most common cause of exactly that
symptom:

```sql
revoke all on function public.home_dispatch(integer, date) from public, anon;
grant execute on function public.home_dispatch(integer, date) to authenticated;
```

### Consequence for `contract.psv` and `Rpc.swift`

`tools/build-db.mjs` generates `Rpc.swift` from `packages/db/contract.psv`,
which is **already stale** (it still lists the dropped 5/6-argument
`declare_round` against today's 8). The signature change must be refreshed
there **after** the push, per the rule recorded at `ScheduleModels.swift:11-14`,
or the phone's generated call will not match.

---

## 2 · The write needs the same local day, from one shared helper

The first report's `answer_plan_followup(p_plan, p_answer)` carried no date, so
neither its `snooze_until` nor its past-day validation could agree with the
read. Corrected signature:

```
answer_plan_followup(p_plan uuid, p_answer text, p_today date default null)
```

**One helper, called by both**, so they cannot drift:

```sql
create or replace function public.cs_local_day(p_today date)
returns date language sql stable as $$
  select least(greatest(coalesce(p_today, current_date), current_date - 1),
               current_date + 1)
$$;
```

**`stable`, not `immutable`** — it reads `current_date`. (My scratch test
declared it `immutable` and PostgreSQL accepted it, which is exactly the
mistake that would let the planner fold a stale day into a cached plan.)

OBSERVED behaviour:

| `p_today` | returns |
|---|---|
| `null` (old client) | `current_date` |
| today | today |
| yesterday (the Phoenix evening case) | yesterday |
| tomorrow | tomorrow |
| a week back | clamped to `current_date - 1` |
| a year forward | clamped to `current_date + 1` |

Then:

- **Read**, in `home_dispatch`: `v_day date := cs_local_day(p_today)`; the
  window is `v_day - 3 … v_day - 1`; a snoozed plan is admitted only when
  `f.snooze_until is null or f.snooze_until <= v_day`.
- **Write**: `snooze_until := cs_local_day(p_today) + 1` for `later`, null for
  `didnt_play`; past-day validation is `sr.play_on < cs_local_day(p_today)`.

**Walked through, 6pm Phoenix on the day of play.** UTC is already the next
day, so `current_date` is Sep 13 while the golfer's day is Sep 12. The clamp
range is Sep 12…Sep 14, so `p_today = Sep 12` is accepted. `play_on = Sep 12`
is not `< Sep 12`, so **the plan cannot be answered on the day it was played** —
which is correct, because that day belongs to the live bridge. Tapping *Later*
the next morning sets `snooze_until = Sep 14`; the read on Sep 14 admits it
again. Read and write stay consistent because they clamp against the same
`current_date` in the same request.

---

## 3 · "Post this round" does not reach a posting flow — OBSERVED on both clients

### Where `{kind:'plan'}` actually goes

| Client | Destination | Can you post from there? |
|---|---|---|
| Phone | `presenter.scheduledRound = id` → `ScheduledRoundSheet` (`HomeView.swift:481`, `HomeFacts.swift:76`) | **No.** Its controls are Send *(a comment)*, Cancel round, I'm in / Maybe / Can't make it, Save the group (`ScheduledRoundSheet.swift:200,214,433,438,444,609`). The one "Could not post." string at `:563` is the comment failing. |
| Web | `case 'plan': return id ? ()=>switchView('schedule') : null` (`index.html:16517`) | **No — and the id is discarded.** It opens the schedule **list**, not the plan. |

So the proposed label would have been untrue on the phone and doubly untrue on
the web.

### The truthful, compatible answer

`action: "Add my round"`, `route: {"kind":"composer"}`.

- Phone: `case .composer: presenter.postOnComposer = true; presenter.showPost = true`
  (`HomeView.swift:476`) — the same door "Add my round" already opens from
  Home, Golfers (`GolfersScreen.swift:125`) and the person page
  (`PersonPage.swift:361`).
- Web: `case 'composer': return ()=>switchView('post')` (`index.html:16514`).
- The copy is **established, not invented**: the clash items already ship
  `action:'Add my round', route:{kind:'composer'}` (`index.html:16596-16597,
  16632`).

### The limitation this leaves, stated plainly

`composer` carries no id, so **the composer opens empty** and the golfer
retypes the course and the date. `PostRoundModel` holds a `ScheduleService`
(`:48`) but uses it only for `cacheCourse` after a tee is picked (`:152`) — it
never reads a plan. That is inbox item 29, unchanged.

### The upgrade path, and the trap in it

A prefilled composer must **not** be a new route kind. `Route.make` returns nil
for an unknown kind, and G1 — the fence — states that "an item with no door …
does not render" (`HomeDispatch.swift:73-75, 334-335`). A new kind would make
the whole item **silently vanish** on every build shipped today.

The compatible way is the field that already exists: keep
`{"kind":"composer", "pane":"<plan-uuid>"}`. `RouteSpec` already decodes
`kind`, `id` and `pane` (`HomeDispatch.swift:152`), and
`case "composer": return .composer` ignores `pane` — so an old build opens a
plain composer and a new build can prefill from it. Degrades to the truthful
behaviour rather than to nothing.

---

## 4 · What the code forces, and what the owner must rule

### Technical conclusions — not choices

| | Because |
|---|---|
| Both date ranges must move, not one | `native_home` feeds the band from `my_schedule(v_today, v_today + 14)`, forward-only, before `home_dispatch` filters to `+8` |
| `can_see_round` cannot be the gate | it admits every league mate and accepted friend |
| The host must be handled explicitly | `declare_round` writes no `round_rsvp` row; `my_schedule` synthesises `in` |
| Cancellation needs no handling | `scratch_round` hard-deletes and cascades |
| Both new functions are SECURITY DEFINER | `sched_own` RLS lets only the host select the plan row |
| Drop-and-recreate, never an overload | §1, OBSERVED |
| `composer`, never `plan` | §3, OBSERVED |
| Re-issue grants in the same migration | §1, OBSERVED |

### Owner rulings — genuine product choices

1. **The window length.** Three days is a guess that matches the `closing`
   tier's own sense of three days. One day is less naggy and loses a golfer who
   posts on Monday; a week keeps asking about a Tuesday nobody cares about.
2. **Whether `maybe` and unanswered qualify.** The stored vocabulary is
   `in | maybe | out`; `my_schedule` also synthesises `asked` for a tagged
   golfer who never answered. Asking everyone who did not say `out` is the
   widest reading and the one that matches the existing upcoming band. Asking
   only `in` is the narrowest and would, today, ask almost nobody — production
   holds three RSVP rows, all `in`, zero `maybe`, zero `out`.
3. **One prompt per day.** Two plans on one day currently produce two items.
   Capping to the earlier tee time is a judgement about nagging, not a
   correctness rule.
4. **Same-day suppression when course identity is missing.** Below.

### The two-rounds-in-one-day tradeoff, without overstating it

**There is no link between a posted round and a plan.** `rounds` has no
`scheduled_round_id`; `scheduled_rounds` has no `round_id`. Any same-day match
is a **heuristic, not an established link**, and it should not be described as
one in code comments, copy, or the decision entry.

The ambiguity is not hypothetical. Four of five production plans carry a null
`course_id`, so for most plans the only available evidence is the date.

| Rule | Fails when | Cost |
|---|---|---|
| **Same day suppresses** (proposed) | a golfer plays the planned round at course A *and* another round at course B the same day, and the plan has no `course_id` | the prompt is **never shown** for a round that was genuinely planned and genuinely played |
| **Require a course match** | the plan has no `course_id` — 4 of 5 today | the golfer is asked to post a round **they already posted** |

Neither is correct; they trade a missed prompt against a duplicate ask. My
recommendation is to prefer the **missed prompt**, because being asked to post
a round you have already posted contradicts the product's own "truth before
tone" rule in a way the golfer can see, while a missing prompt looks like
today's behaviour. **It is the owner's call, and it should be written into the
decision entry as a chosen error, not as a match.**

The ambiguity disappears entirely with inbox item 28's one nullable column.
Until then, no code should imply the link is known.

---

## 5 · Exact payloads, authorization, matrix, acceptance

### 5.1 · The dispatch item

```json
{
  "key":           "afterplan:9f8db84a-166c-4900-b196-ea2c5459e369",
  "tier":          "changed",
  "band":          800,
  "mods":          0,
  "mod_reason":    "none",
  "subject":       "you",
  "human_subject": true,
  "eyebrow":       "SAT · OAK QUARRY GOLF CLUB",
  "headline":      "You had a round on Saturday.",
  "standfirst":    "Nothing posted yet.",
  "action":        "Add my round",
  "route":         { "kind": "composer" },
  "league_id":     null,
  "suppress":      [],
  "spine":         "ember",
  "at":            "2026-09-12"
}
```

Sixteen keys, all of which the shipped decoder already reads. `subject` is
`"you"` for the host and the tagged golfer alike — the prompt is always about
the reader, so `human_subject` is true and the item is eligible for the G2
lead slot.

### 5.2 · The write

Request `answer_plan_followup(p_plan, p_answer, p_today)`; returns `void`.
Raises, in this order:

| Condition | Message |
|---|---|
| `auth.uid()` null | `Sign in first` |
| `p_answer not in ('later','didnt_play')` | `That is not an answer` |
| plan absent | `That round is not on the schedule` |
| caller neither `sr.profile_id` nor `= any(sr.tagged)` | `Only the people on this round can answer` |
| `sr.play_on >= cs_local_day(p_today)` | `That round has not happened yet` |

### 5.3 · Authorization cases

| Caller | Expected |
|---|---|
| Host | writes |
| Tagged golfer | writes |
| Tagged golfer whose RSVP is `out` | writes (they may still answer "didn't play"; the read already excludes them, so it is inert) |
| League mate, not tagged | raises — **must not** fall back to `can_see_round` |
| Accepted friend, not tagged | raises |
| Signed-out / `anon` | no grant; the anon surface stays at twelve (L-36/L-45) |
| Any golfer reading another's row | zero rows — RLS `profile_id = auth.uid()`, asserted with a real second identity rather than by reading the policy |

### 5.4 · Old/new combinations

| | Old server (no `p_today`, no item) | New server |
|---|---|---|
| **Old client** (sends `p_days` only) | today's behaviour | **works.** One function exists after the drop-and-recreate, `p_today` defaults to null → `current_date`. The item decodes, renders, and "Add my round" opens the composer. Only the timezone correctness is missing, which is today's state. |
| **New client** (sends `p_days` + `p_today`) | `PGRST202` / `42883`; the web already drops the argument and retries (`index.html:10100`); **the phone needs the same retry added**. No items appear, which is today's behaviour. | full behaviour |

The single non-optional client change is the phone's drop-argument retry.

### 5.5 · Acceptance cases added by this review

The first report's thirty stand. These eleven are new, and the first three are
the ones that would have caught the defects above.

31. **Both functions present** → every existing caller shape errors `is not
    unique`. This is the regression test for the migration strategy; it must be
    impossible to reach this state.
32. **After the migration**, `home_dispatch(21)`, `home_dispatch(p_days => 21)`
    and `home_dispatch()` all return the new function. Assert the count of
    `pg_proc` rows named `home_dispatch` is exactly **1**.
33. **After the migration**, `has_function_privilege('authenticated',
    'public.home_dispatch(integer,date)', 'execute')` is true, and the same for
    `answer_plan_followup`. Catches the dropped ACL.
34. `cs_local_day` is declared `stable`, not `immutable`.
35. `cs_local_day(current_date - 7)` returns `current_date - 1`.
36. **6pm Phoenix on the day of play**: the prompt does not appear, and
    `answer_plan_followup` on that plan raises.
37. **Later at 6pm Phoenix, read the next morning** → the prompt returns once,
    not twice.
38. The item's `route.kind` is `composer` and its `action` is `Add my round`
    — asserted as a literal, so no one can change it to `plan` without the test
    failing.
39. **An old build decodes the item** → renders, and the door opens the
    composer, not the schedule.
40. **A route kind the build does not know** → the item is dropped by G1. This
    documents why a new kind is not an option.
41. `contract.psv` lists `home_dispatch` with two arguments after the refresh,
    and `Rpc.swift` regenerates without a hand edit.

---

## Handoff

- **Branch and commit:** `claude/after-golf-audit`, this commit.
- **Goal / owned files:** review only. `docs/reviews/2026-09-12-after-golf-contract-review.md` (new), a correction banner on `2026-09-12-after-golf-audit.md`, one `spec/inbox.md` entry. No application code, no migration, no generated file.
- **Built or reviewed:** reviewed. Two corrections to my own earlier proposal, both OBSERVED rather than reasoned.
- **Verification:** PostgreSQL 17 overload resolution, drop-and-recreate, ACL loss and the clamp helper proven on a throwaway local cluster, created and deleted in the session scratchpad. Client destinations traced in source on both clients. Production read with SELECT only. `npm run preflight` clean. No application tests were run because no application code changed.
- **Findings still open:** the four owner rulings in §4; the phone's drop-argument retry; `contract.psv` staleness; whether the prefilled composer (`pane`) is in scope.
- **Database deploy owed:** none. No migration written.
- **Edge deploy owed:** none.
- **Client / TestFlight deploy owed:** none from this branch. TestFlight remains held.
- **Next owner and bounded task:** owner, for the four §4 rulings. Codex keeps the Home regression fixes.
