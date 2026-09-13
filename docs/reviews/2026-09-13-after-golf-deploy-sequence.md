# The after-golf repair · the canonical deployment manifest — 2026-09-13

**This file is the one executable scope.** An earlier version of it described
one migration in its commands and two in its handoff, which is the contradiction
R5 named. The scope is **two**, and the dry run below must show exactly those
two and nothing else.

Branch `claude/complete-the-week`. **Nothing here has been deployed.**
No deployment happens during the repair pass.

---

## 1 · Production, read at 2026-09-13 during this repair pass

Read-only against project `zddbfcokmvneltrgukzf`.

| Fact | Value |
|---|---|
| Applied migrations | **240** |
| Latest applied | `20261101090000` |
| Pending | exactly **two**: `20261102090000`, `20261103090000` |
| Local migration files | 242 |
| D345 `20261024090000` | **present in migration history** |
| `plan_followups` / `answer_plan_followup(uuid,text,date)` | both exist |
| `home_dispatch` live signature | `(p_days integer DEFAULT 21, p_today date DEFAULT NULL::date) → jsonb` |
| `afterplan:` in the deployed `home_dispatch` body | **yes** |
| `afterplan.v1` in that body | **no — the capability gate is absent** |

**Correcting my own earlier count.** The previous version of this file said 239
applied. That was produced by a `grep -c` over the listing and it miscounted; the
authoritative figure, counted by reading the Remote column, is **240**, and the
review's number is the correct one. Both readings agree on what actually
matters: D345 is applied, the gate is not, and the exposure is live.

**On who applied D345 and when: unknown, and not inferred.** The prior release's
own readback returned 239 with a check reported as `held_d345_applied=false`.
Both observations stand as recorded. Function presence is evidence that it ran;
it is not evidence of who ran it or when, and this file does not claim
otherwise.

---

## 2 · What the two migrations do

| File | What |
|---|---|
| `20261102090000_the_band_waits_for_a_client_that_can_answer.sql` | `home_dispatch` gains `p_caps text[]`; the after-golf band is emitted only to a caller naming `afterplan.v1`; the item gains its plan `context`; `answer_plan_followup` returns a status instead of void |
| `20261103090000_an_invitation_seats_you_the_way_the_door_does.sql` | `respond_invite` seats a Major invitee by the established-number rule the other three doors already use |

Both read the deployed body and patch it with **asserted** replacements that
raise if an anchor is missing. Both carry read-only self-checks that raise
rather than reporting success. Both are idempotent.

**The first one alone stops the live exposure.** With the gate in place and no
client naming the capability, the band disappears from every client in the
field and Home returns to exactly what it was before D345. The shipped
two-argument call still *resolves* — `p_caps` is defaulted — so nothing else
about Home changes; that is asserted by `tests/after-golf-postgres.py`.

---

## 3 · The sequence

### Step 1 — database, alone, first

```sh
supabase migration list --linked            # expect 240 applied, 2 pending
supabase db push --linked --dry-run --skip-vault
supabase db push --linked --skip-vault
```

The dry run must list **exactly** `20261102090000` and `20261103090000`. If it
lists anything else, stop: something else is unrecorded too, and that is the
finding rather than the deploy. The dry run and the real command use the **same
scope and the same flags**; no applied migration is replayed, because nothing
else is pending.

**A gate-only first phase was offered here and is now REMOVED, because it does
not work.** The idea was to push `20261102090000` alone from a staging directory
holding only that file, since `db push` has no per-file selection. Tested on
2026-09-13 against the linked project with a read-only dry run, it fails:

```
LegacyDbPushMissingLocalError:
  Remote migration versions not found in local migrations directory.
```

and the CLI's own suggestion is `supabase migration repair --status reverted`
across **all 240 applied versions**, followed by `db pull`. Following that
suggestion would rewrite the migration ledger of a live database to make it
agree with a directory containing one file. The recipe was written but never
executed; it is removed rather than left as plausible-looking instructions with
a destructive remedy attached to its first failure.

**So there is one phase, and it is Step 1.** The gate ships together with the
seating fix. That is acceptable: the gate is what stops the live exposure, the
second migration is latent-only (production holds no Major and no accepted event
invitation), and both are idempotent and self-checking.

### Step 2 — read the database back, before any client ships

```sh
supabase db query --linked "select p.oid::regprocedure::text as sig
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('home_dispatch','answer_plan_followup','respond_invite')"
```

Expect exactly three rows:

- `home_dispatch(integer,date,text[])` — two rows here means the overload trap
  fired and the migration's own self-check should already have raised; treat it
  as a failed deploy.
- `answer_plan_followup(uuid,text,date)` returning **jsonb**.
- `respond_invite(uuid,boolean)`.

Then confirm the gate and the seating rule are actually in the deployed bodies:

```sh
supabase db query --linked -f tests/db-checks.sql
```

**Check 34 must flip from FAIL to PASS.** It reports the ungated band today.

### Step 3 — refresh the contract from the deployed catalog

Only after Step 2 passes. The refresh query is in the header of
`packages/db/contract.psv`; run it read-only against the deployed database, write
the result to that file, then regenerate:

```sh
node tools/build-db.mjs      # rewrites the generated Rpc.swift from contract.psv
npm run preflight            # checks 10/11 fail if a generated file is stale
```

The snapshot is **already stale independently of this release** and the refresh
will show it: it carries `home_dispatch|p_days integer DEFAULT 21`, missing the
`p_today` that has been live since D345, and it has no `answer_plan_followup`
row at all. Expect those two corrections plus `p_caps`, the new jsonb return,
and any other drift the refresh surfaces. Do not hand-shape the file.

Neither client depends on this refresh to work: `home_dispatch` and
`answer_plan_followup` are hand-declared on both, which preflight 17 tolerates.
The refresh is for the snapshot's accuracy and for the next generated build.

### Step 4 — Safari, after the database is read back

Merge and `git push`; Netlify builds `main`. Verify `#obCaption` reads
`v23 · <sha>` against `git log`, then walk the changed journeys at 390 and 320
with service workers and caches cleared.

### Step 5 — TestFlight, separately

Today's candidate needs **its own source and build identity**; build 835 is the
previous release's artifact and must not be reused. Signing access is the
owner's, and no certificate work belongs to this pass.

---

## 4 · Tracked independently

| Layer | Owed | State |
|---|---|---|
| Database | two migrations above | **pending**, verified locally only |
| Edge Functions | none | nothing owed |
| Safari | the client half of R1–R6 | **unpublished**, awaiting Codex integration |
| TestFlight | a new candidate build | blocked on signing, owner's |

---

## 5 · Rollback

There is no revert migration and there should not be one. The gate **is** the
safe state: a database carrying `20261102090000` with no capable client behaves
exactly like a database without D345, which is where everyone was before. If a
client has to be pulled, pull the client.

`20261103090000` changes who a Major invitation seats. Production holds no Major
and no accepted event invitation, so there is nothing it can have already
changed.

---

## 6 · Evidence behind this sequence

Run on disposable local clusters; no test accepts a remote URL.

- `tests/release-chain-database.py` — the full chain applies, nothing held.
- `tests/after-golf-postgres.py` — the gate (capable, none, empty, unrelated
  token, token among others), the shipped client's own two-argument call still
  resolving and producing no card, the plan context, the three answer statuses,
  and idempotency with one surviving overload.
- `tests/events-consent-database.py` — the Major seating rule by established
  number, the Ryder seat unaffected, and run-it-back's consent behaviour pinned.
- `tests/db-checks.sql` check 34 — reports the ungated band against production
  today and is the post-push gate.
