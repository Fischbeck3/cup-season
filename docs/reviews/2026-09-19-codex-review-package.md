# Review package for Codex — 2026-09-19

Prepared at the owner's request. Nothing here is deployed: two migrations are
written, validated in isolation and **not pushed**; the web is not promoted;
no build was made. Every claim below names the command or file behind it.

---

## 1 · Branch, commit, PR

| | |
|---|---|
| Branch | `claude/pilot-readiness-2026-09-15` |
| PR | **#6**, open, base `main`, mergeable |
| Head to review | the branch tip — *"The claim journey, walked: a claimed card belongs to its claimer"*. A commit cannot name its own hash, so read the tip of the branch; PR #6 tracks it. |
| Previous head | `0ff0b28` — pre-launch audit |
| Branch point | `99fb052` (tip of `claude/phone-fixes-2026-09-15`) |
| Working tree | clean |

Commits in review, newest first:

```
(tip)    The claim journey, walked: a claimed card belongs to its claimer
0ff0b28   Pre-launch audit: the grades, and the four things it caught
a9c9e57   A schedule note is a door: the booking it names opens on both clients
fb2add2   Release record: build 934 uploaded, in the internal Owner group
34ab244   Release record: 20261106090000 and 20261107090000 applied to production
1aac23a   Pilot readiness: the authorization harness, the pilot record, telemetry, the scorecard
```

Pending database work, exactly (`supabase db push --linked --dry-run`):

```
20261109090000_truncate_is_not_a_client_verb.sql
20261110090000_a_claimed_card_belongs_to_its_claimer.sql
```

---

## 2 · Excessive privileges — full inventory

### Correction to the request's premise

The audit reported db-check 23 as *"8 such grant(s)"*. That is **eight grant
entries across two tables**, not eight tables. Verified by enumerating every
table in `public` with any grant to a client role beyond SELECT/INSERT/UPDATE/
DELETE:

```sql
select c.relname, a.grantee::regrole::text, array_agg(a.privilege_type order by a.privilege_type)
  from pg_class c, aclexplode(c.relacl) a
 where c.relnamespace = 'public'::regnamespace and c.relkind = 'r'
   and a.grantee::regrole::text in ('anon','authenticated','public')
   and a.privilege_type not in ('SELECT','INSERT','UPDATE','DELETE')
 group by c.oid, c.relname, a.grantee;
```

Result on production, 2026-09-19: **2 rows, 2 distinct tables.** Every other
table in the schema is clean.

### The inventory

| Table | Role | Excess privileges | Intended grants | RLS | Data held |
|---|---|---|---|---|---|
| `pilot_cohort_members` | `authenticated` | TRUNCATE, REFERENCES, TRIGGER, MAINTAIN | SELECT, INSERT, UPDATE, DELETE | on, founder-only policy | which golfer is in which pilot cohort |
| `pilot_sessions` | `authenticated` | TRUNCATE, REFERENCES, TRIGGER, MAINTAIN | SELECT, INSERT, UPDATE, DELETE | on, founder-only policy | when the founder assisted a group, and notes |

`anon` holds nothing on either table. No other role is affected.

### Exposure, stated plainly

- **What was reachable:** row security governs SELECT/INSERT/UPDATE/DELETE and
  **does not govern TRUNCATE or TRIGGER**. So any signed-in account could have
  emptied either table, or attached a trigger to it. Reads and row-level writes
  were correctly confined to the founder throughout — that half held.
- **What was NOT reachable:** no round, score, league, season, profile, post or
  claim table was affected. Both tables are founder-only measurement records
  created three days ago; they carry no gameplay data and nothing a golfer sees.
- **Window:** created by `20261106090000`, applied to production 2026-09-15;
  detected by db-check 23 during the pre-launch audit 2026-09-18. Roughly three
  days, on a database with 33 accounts, all owner or friends.
- **Evidence of exploitation:** none. Both tables hold **0 rows**, and
  `pg_stat_user_tables` records **0 updates and 0 deletes** on either.
- **Severity:** low in consequence, high in class. Nothing was lost; the same
  mistake on a scoring table would not have been low.

### Root cause

`20261106090000` wrote an explicit `grant select, insert, update, delete`. It
did not revoke first. Production's `pg_default_acl` hands `arwdDxtm` to
`authenticated` on every newly created table, so the explicit grant was
**added on top of** a full default grant rather than replacing it. `CLAUDE.md`
warns about this exact trap — the D37 default-privilege flip binds to the
`postgres` role, and the migration runner is not always it — and I did not
apply the warning when adding the tables. That is mine.

### Corrective migration

`supabase/migrations/20261109090000_truncate_is_not_a_client_verb.sql`:

```sql
revoke all on table public.pilot_cohort_members from public, anon, authenticated;
revoke all on table public.pilot_sessions        from public, anon, authenticated;
grant select, insert, update, delete on table public.pilot_cohort_members to authenticated;
grant select, insert, update, delete on table public.pilot_sessions        to authenticated;
```

with a self-check that raises if any excess client grant remains, or if the
founder-only policies vanished. Validated on the full-chain sandbox: excess
grants drop to 0 and `tests/pilot/pilot-record.py` still proves founder-only
access at 13 PASS. **Not pushed.**

### Prevention of recurrence

Three layers, two of which are new:

1. **After the fact (existed, worked):** db-check 23 is the tripwire and is
   what caught this. It runs read-only against production.
2. **Before the push (new):** preflight **check 50 · "a new table states its
   own grants"** fails any migration that creates a table in `public` without
   a `revoke` on it. It is deliberately **forward-only** from `20261109000000`,
   because applied migrations are immutable (rule 2) and linting history would
   report 64 untouchable tables. Proven to trip: a probe migration creating a
   table with only a grant makes preflight exit 1 naming the file and table;
   removing the probe returns it to exit 0.
3. **Written down (new):** the migration's own header states the rule — revoke
   first, then grant the exact list — so the next table's author reads it where
   they will be working.

---

## 3 · Compete test expectations — original vs revised

### Why they changed

Both suites had been **red since the Scoreboard (F11) landed** and were not in
F11's run list. That is a coverage-discipline miss on my side: I changed the
rendering contract and did not run the two suites that assert it. They were
asserting the pre-Scoreboard shape, in which every season rendered as a
`.peerrow`.

### The approved contract they now encode

From the owner-approved option 2 · Scoreboard (F11, recorded in D367 and the
audit): **the season being played leads the Compete tab as one broad ember
band; every other season stays an ordinary quiet row.** The band must carry
every fact the plain row carried, and must say the rank exactly once.

### `tests/compete-start-browser.js`

| | |
|---|---|
| Original | `check(document.querySelectorAll('#cmpList .peerrow').length===2, 'the two seasons did not render')` |
| Revised | `check(document.querySelectorAll('#cmpList .cband').length===1, 'F11: the lead season is not a band')`<br>`check(document.querySelectorAll('#cmpList .peerrow').length===1, 'the other season did not render as a row')` |

Same two seasons; the assertion now names which renders as which.

### `tests/compete-rows-browser.js`

| | Original (league A, the lead) | Revised |
|---|---|---|
| standing | `text(A,'.ps')==='2nd of 2 · 14 pts · 3 behind Jade'` | `btext('.cband-fig')==='2nd'` **and** `btext('.cband-note')==='14 pts · 3 behind Jade'` |
| week | `text(A,'.pe')==='In season · Week 8 of 26'` | folded into `btext('.cband-meta')` |
| status | `text(A,'.pt')==='The clash closes today'` | folded into `btext('.cband-meta')==='In season · Week 8 of 26 · The clash closes today'` |
| state | *(did not exist)* | `btext('.cband-state')==='Live'` |
| count | `.peerrow` length `===4` | `.peerrow` length `===3` **and** `.cband` length `===1` |

Leagues B, C and D keep **every original assertion unchanged**, including the
two that matter most — a league with no facts invents none, and a missing rank
is never rendered as first.

### Two product defects these revisions exposed

Rewriting the expectations against the contract, rather than against what the
code happened to emit, surfaced two real faults in the **web** band, both now
fixed in the same commit:

1. **The rank was said twice** — the band drew the figure (`2nd`) and the sub
   line still began `2nd of 2 · `. The figure now carries the rank and the
   note's leading rank clause is folded out. (LINT-19's one-place rule.)
2. **The lead season lost its status line** — `The clash closes today` was
   dropped when a season was promoted to the band. The meta line now carries
   eyebrow and status together.

The **native** band was checked for the same two faults and has neither: its
row model folds status into the sub line already, so no change was made there.
An attempted native edit was reverted for that reason.

---

## 4 · Guest-claim walkthrough

New harness: `tests/pilot/claim-walkthrough.py` — the real functions on the
full-chain sandbox with row security on, reporting the five stages separately
so a failure names where the journey dies. **24 PASS · 0 FAIL.**

### Stage 1 · Link delivery — PASS

The seat carries a claim token from the start, and `finish_live_round` returns
each guest's token **and name** so the host knows whose link is whose.
**Delivery is manual by design:** the host copies the link and sends it by text
or chat. The product sends no email or SMS, so there is no delivery channel to
fail — and none to measure.

### Stage 2 · Opening (signed out) — PASS, with the dead end named

A valid token shows the card signed out: guest name, gross, holes, course,
date, claimed-flag. It leaks no email, profile id or token — the returned keys
are exactly `claimed, course_label, game, game_result, gross, guest_name,
holes_scored, played_on`. An invalid token shows nothing. An unfinished or
abandoned round's token shows nothing, correctly refusing to leak a live card.

**The dead end.** `claim_round_info` returns NULL for an unfinished round; the
web then tries `scan_claim_info`, also null; the golfer lands on the ordinary
signed-out door **with no explanation of why their link did nothing.** This is
not hypothetical — see the production numbers below.

### Stage 3 · Authentication — PASS

`claim_round` is refused signed out at the **grant** (`anon` holds no execute),
which is a stronger boundary than a message. The clients never call it signed
out: the door shows the card, takes the email code, and claims once a session
exists. The card stays readable throughout, so a newcomer sees what they are
signing up for before they sign up.

*(My first version of this assertion expected a friendly "Sign in" string and
failed. The assertion was wrong, not the product; it now asserts the grant.)*

### Stage 4 · Claim completion — PASS

The newcomer claims; exactly one round posts to their record (0 → 1). Claiming
again answers `already` and posts nothing twice. A second golfer is refused
with "already claimed". The link afterwards reports itself claimed rather than
inviting again.

### Stage 5 · Finding the resulting round — **FAILED, then fixed**

The claimer can read their round row, open its receipt, and read its 18 holes;
the round carries the guest's real gross and points back at the live round; an
unrelated golfer still cannot read it.

**But the receipt's birdie/eagle tally reported `known:false`** — silently
blank on a round whose pars were verified.

Cause, traced: `_live_participant`, the test behind the READ policies on
`live_rounds`, `live_round_players` and `game_results`, recognises a seat by
`starter_profile_id` or `guest_profile_id` and **never by `claimed_profile`**.
The golfer who claimed the card remained a stranger to the round they played
in, so `round_tally` (security invoker, by design) could not read the snapshot
that proves the pars. Same family as `20261107090000`, one table further along.

Fix: `20261110090000_a_claimed_card_belongs_to_its_claimer.sql` adds one
disjunct — `or p.claimed_profile = auth.uid()`. Read-only in effect: all three
dependent policies are SELECT (`pg_policy.polcmd = 'r'`), and no function calls
the helper. The migration self-checks both facts and raises if a non-SELECT
policy ever starts using it.

Scope verified after the fix, as restricted roles:

| Actor | live round | seats | write a score |
|---|---|---|---|
| the claimer | 1 row | 3 rows | refused |
| an unrelated golfer | 0 rows | 0 rows | refused |
| anon | permission denied | permission denied | refused |

### What production says about this journey

| Fact | Count |
|---|---|
| Guest seats ever minted with a claim token | 70 |
| …in rounds that were **abandoned or never finished** | **55** |
| …in rounds that reached `final` | 15 |
| …of those, with a gross actually recorded | 3 |
| Claimed | 1 |
| Rounds that had guests | 33 (23 abandoned, 10 final) |
| Distinct hosts who ever seated a guest | 3 |

**This corrects the audit's own diagnosis.** The audit graded the growth loop
D on "1 of 29 claimed" and implied the claim journey was broken. The journey
works — 24 of 24 on the walkthrough once the tally defect is fixed. The real
finding is upstream: **79% of guest seats are in rounds that never finished**,
so no claim card was ever minted and every one of those links is the stage-2
dead end. The low claim count is mostly a live-round completion problem, not a
claim problem. The three finished-with-a-gross cards yielded one claim, which
at that sample size says nothing either way.

### What is owed, and not done here

- The dead end is **not fixed** — it needs a decision on what an unclaimable
  link should say ("this round was never finished; ask whoever organised it"),
  and that is product copy touching a signed-out surface. Filed, not written.
- Why 23 rounds were abandoned is **not established**. Three hosts, two months,
  and some are certainly my own test starts from this week. Worth separating
  before drawing a conclusion.
- No physical-device pass on any of this.

---

## 5 · Verification run for this package

Exit codes preserved; nothing inferred from filtered output.

| Check | Result |
|---|---|
| `tests/pilot/claim-walkthrough.py` | 24 PASS · 0 FAIL · exit 0 |
| `tests/pilot/authz-flow.py` | 72 PASS · 0 FAIL · 2 NOT VERIFIED · exit 0 |
| `tests/pilot/pilot-record.py` | 13 PASS · exit 0 |
| `npm run preflight` (incl. new check 50) | exit 0 |
| Preflight check 50 tripwire probe | fails as designed, then clears |
| Kit / app-target suites | 1224 in 198 suites · 100 in 19 suites · exit 0 |
| Web suites (8, incl. both repaired Compete) | all PASS · exit 0 |
| `tests/homefold.test.mjs` | exit 0 |
| Both pending migrations on the full-chain sandbox | apply clean, self-checks pass |

## 6 · Questions for Codex

1. Is the `_live_participant` widening correctly scoped, or should the claimer's
   visibility be narrower than the full live round — for example the seats and
   snapshot but not `game_results`?
2. Should preflight check 50 also require `enable row level security` on a newly
   created table, or is that over-reach for a lint?
3. The stage-2 dead end: is a signed-out explanation the right answer, or should
   an unclaimable link be prevented earlier — for example by not offering a link
   for a round that was never finished?
