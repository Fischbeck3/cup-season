# The course-cache fix (D370): recovery, placement, validation, deployment

**2026-09-22, remote session on `claude/october-launch`.** The one owed
database and edge item before October 1, prepared here for the Mac and the
owner. Nothing in this file was deployed.

## 1 · What production says — read, not remembered

| Question | Answer | How |
|---|---|---|
| Is `20261111090000_course_cache_atomic` applied? | **CONFIRMED UNAPPLIED.** The ledger runs `20261109`, `20261110`, `20261112`, `20261113`, `20261114`, `20261115`; no `20261111` row. | `select version from supabase_migrations.schema_migrations where version >= '20261109'` on the linked project, read-only, 2026-09-22 |
| Does the atomic course-cache RPC exist in production? | **CONFIRMED ABSENT.** The only `public` functions matching `%course%` are `course_key`, `course_name_of`, `course_rating`, `course_rating_is_mine`, `my_course_books`, `my_course_ratings`, `rate_course`, `unrate_course`. | `pg_proc` joined to `pg_namespace`, read-only, same hour |
| Is the file in the repository, on any remote branch? | **CONFIRMED ABSENT.** No ref carries a `supabase/migrations/20261111*` path after `git fetch --prune`. | `git log --all -- 'supabase/migrations/20261111*'` |
| Where is it? | Codex's local branch `codex/live-scoring-moments-2026-09-19`, commit `39c8d00`, in `/Users/fischbeck3/cup-season-integrations` — local and unpushed on 2026-09-19 (`docs/reviews/2026-09-19-claude-review-of-codex-integrations.md`). | The review; not re-verified from here |

Why `deploy-status` could not answer the first question: it subtracts the
ledger from the local files, so a version applied remotely with no local file
reads as *clean*. The ledger was read directly instead.

## 2 · Recovery and placement (Mac, before any push)

The file has run nowhere but a sandbox, so it may be renamed; it sorts before
four migrations production already carries, so it **must** be renamed to keep
file order equal to applied order (an unrenamed push would be out of order and
the CLI would refuse it or demand its include-all flag — the rename is the
answer, not the flag). Rule 2 forbids editing a migration that has run in
production; this one has not.

```bash
# in the october-launch worktree, on the Mac
SRC=/Users/fischbeck3/cup-season-integrations
git -C "$SRC" show 39c8d00 --stat                                   # confirm the two files it carries
git -C "$SRC" show 39c8d00:supabase/migrations/20261111090000_course_cache_atomic.sql \
  > supabase/migrations/20261116090000_course_cache_atomic.sql      # an unused timestamp after 20261115
git -C "$SRC" show 39c8d00:supabase/functions/courses/index.ts > /tmp/courses-codex.ts
diff /tmp/courses-codex.ts supabase/functions/courses/index.ts     # Codex's RPC call vs this branch's coercion — merge by hand, keep both
git -C "$SRC" show 39c8d00 --name-only | grep tests/ && \
  git -C "$SRC" show 39c8d00:tests/course-cache-postgres.py > tests/course-cache-postgres.py   # Codex's probes, if the commit carries them
```

Before validating, read the migration's body once for the in-place patch
pattern (`pg_get_functiondef` → replace → execute). If it patches any function
that `20261112`–`20261115` also patched, it must be rebased on the live text
first; say which functions in the handoff. The review of 2026-09-19 found it
self-contained (the course-cache tables and one RPC), so this is expected to be
a no-op check.

## 3 · Validation on the sandbox chain (Mac, PG17)

```bash
tests/sim/sandbox/apply.sh                     # the full chain: 252 on main + the renamed file = 253, 0 skipped
python3 tests/course-cache-postgres.py         # Codex's probes against the sandbox (port from the harness)
tests/sim/sandbox/apply.sh                     # a second run: idempotent, notices only
```

What "validated" means here: the chain applies in **the applied order** (the
renamed file last), the probes pass, and the second run raises nothing. A
"dry-run" against the linked project is never validation (CLAUDE.md, first
landmine — the wrapper applies it).

The coercion on this branch (`supabase/functions/courses/index.ts`,
`flattenTees` and the course coordinates): every rating, slope, par, yardage,
hole count and coordinate the provider sends is coerced to a finite number or
null before it reaches SQL, so a malformed field skips a value rather than
failing the whole course permanently under the RPC's strict casts. It is
independent of Codex's RPC call and merges beside it.

## 4 · The deployment, in this order — the owner's, from a checkout carrying every file

```bash
./tools/ship.sh --dry-run                       # database: one owed (20261116…); edge: courses stale; client: clean
supabase db push                                # 1 · the migration first — the RPC must exist before the function calls it
supabase functions deploy courses               # 2 · the function second, carrying Codex's RPC call AND the coercion
psql "$PROD_RO" -f tests/db-checks.sql          # 3 · 37 of 37 (read-only role)
node tools/deploy-status.mjs                    # 4 · every layer clean
```

Read back, read-only, after step 1: the RPC is in `pg_proc`; after step 2: a
course detail fetch from the phone or the desk returns tees (a course not yet
in `api_courses`) — that is the moment the old function would have 502'd on
the missing RPC had the order been reversed.

## 5 · Status ladder

| Step | State |
|---|---|
| Ledger read; RPC absence confirmed | **done, 2026-09-22** |
| File recovered into the tree under `20261116090000` | owed — Mac, from Codex's workspace |
| Coercion in `flattenTees` | **implemented on this branch**; not run (no Deno here); the function is not redeployed |
| Sandbox chain + probes + repeat run | owed — Mac (PG17) |
| `db push` → `functions deploy courses` → db-checks → deploy-status | owed — owner, in that order |
