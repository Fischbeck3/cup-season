# The after-golf repair · exact deployment sequence — 2026-09-13

Branch `claude/complete-the-week`, from `origin/main` at `8fdf516`.
Do **not** run a blanket `supabase db push` for this. The sequence is below and
the reason is the first section.

---

## 1 · The premise this sprint was given is wrong, and it matters

The packet says D345 is held and asks for a sequence that "excludes the unsafe
original deployment path". **The unsafe path already ran.** Verified read-only
against production on 2026-09-13:

| Check | Result |
|---|---|
| `supabase migration list --linked` | 239 rows, every Local matching its Remote, **including `20261024090000`** |
| live `home_dispatch` signature | `home_dispatch(integer, date)` — D345's two-argument shape |
| `plan_followups` table | present |
| `answer_plan_followup` function | present |
| `afterplan:` in the deployed `home_dispatch` body | **true** |
| deployed body vs the migration file | **byte-identical**, 43,441 characters each |

So nothing drifted. The hold did not hold. The release review's line "held D345
false" records the check returning false; it reads as though the hold was
honoured, and it was not.

**What that means for real golfers.** The band's only gate is `p_today is not
null`, and the shipped Safari client sends `p_today`. Live exposure at the time
of writing:

| Fact | Value |
|---|---|
| plans in the band's window (`today-3` … `today-1`) | 1 |
| golfers on it (host + tagged) | 4 |
| course named on it | none |
| rounds posted by the host that day | 0, so nothing suppresses the card |
| answers recorded in `plan_followups`, ever | 0, because no client can record one |

Those golfers see a card whose only door opens a blank composer dated **today**
rather than the day they played, and no control that makes it go away.

---

## 2 · The fix, and why the database goes first

`20261102090000_the_band_waits_for_a_client_that_can_answer.sql`

Applying this migration **alone**, with no client change, removes the band from
every client in the field: the band now requires a caller to name
`afterplan.v1`, and nothing in the field does. Home returns to exactly what it
was before D345. That is the correct emergency behaviour, and it is why the
database goes first rather than waiting for a client.

The band comes back only for a build that declares the capability, which is the
same build that implements the two answers and the date prefill.

The migration also gives the item its plan `context` and makes
`answer_plan_followup` return a status instead of void.

**It is idempotent.** A second run finds the gate already present and does
nothing. That is deliberate: this repository has now had two migrations reach
production outside the ledger, and a migration that can be run twice without
harm is the cheap insurance.

---

## 3 · The sequence

**Step 1 — database, alone, first.** From the repo root:

```
supabase migration list --linked            # expect 239 rows, latest 20261101090000
supabase db push --include-all --dry-run    # expect exactly ONE pending: 20261102090000
supabase db push
```

The dry run must list `20261102090000` and nothing else. If it lists anything
else, stop: something else is unrecorded too, and that is the finding, not the
deploy.

**Step 2 — read the database back, before any client ships.**

```
supabase db query --linked "select p.oid::regprocedure::text as sig
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname in ('home_dispatch','answer_plan_followup')"
```

Expect exactly two rows: `home_dispatch(integer,date,text[])` and
`answer_plan_followup(uuid,text,date)`. If `home_dispatch` returns two rows, the
overload trap has fired and the migration's own self-check should already have
raised — treat that as a failed deploy.

Then confirm the band is dark for the shipped client:

```
supabase db query --linked "select position('afterplan.v1' in pg_get_functiondef(oid)) > 0 as gated
  from pg_proc where proname = 'home_dispatch' and pronamespace = 'public'::regnamespace"
```

**Step 3 — the client, after the database is read back.** `git push` the branch
once merged; Netlify builds `main`. Confirm with `#obCaption` reading
`v23 · <sha>` against `git log`.

**Step 4 — native.** No separate step. The native half ships with whatever build
follows; until then the phone declares nothing and sees no band, which is the
same honest state as today.

**Nothing else is owed.** No Edge Function, no secret, no `contract.psv`
regeneration is required for this to be safe — `answer_plan_followup` is
hand-declared on both clients exactly as `home_dispatch` already is, and the
contract refresh should be taken from the pushed database in its own pass.

---

## 4 · Rollback

There is no revert migration and there should not be one: the gate is the safe
state. If the client half has to be pulled, pull the client — the database with
this migration and no capable client behaves exactly like a database without
D345, which is where everyone was before.

---

## 5 · Evidence behind the sequence

Run on a disposable local PostgreSQL cluster by `tests/after-golf-postgres.py`,
which applies D345 and then this migration and exercises the real functions:

- every original D345 case still passes — eligibility, the window, RSVP `out`,
  suppression by a same-day round, the voided-round exception, the different-course
  exception, one item per day, Later's snooze, Didn't play's terminality, RLS
  isolation and the anon denial;
- **the gate**: a capable client sees the band; `null`, an empty list and an
  unrelated token all get nothing; the token is found among others; and the
  shipped client's own call — a day with no capabilities — produces no card;
- **the context**: the plan id, the day played, the raw course label, and a null
  course id where the plan names no catalogue course;
- **the status**: a recorded Later says it applied and carries the server's
  snooze date; Didn't play applies and does not snooze; a stale Later afterwards
  reports `terminal` and writes nothing; a plan that is not yours and a plan that
  does not exist both answer `not_available`;
- **idempotency**: re-applying the migration is a no-op and `home_dispatch`
  still resolves to exactly one function.
