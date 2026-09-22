# October launch — course cache and shared-card deployment packet

Updated 2026-09-22 by the Mac verification pass, on
`codex/october-launch-mac-verification`, based on Claude's `4a171f7`.
Nothing in this packet has been deployed by this session.

## What is ready

- `20261116090000_course_cache_atomic.sql` was recovered byte-for-byte from
  local commit `39c8d00` (formerly named `20261111090000`). The remote session
  read production's ledger and function catalog on September 22 and found it
  unapplied/absent. Recheck that evidence immediately before deployment.
- The migration defines the standalone `cache_course_card` RPC; it does not
  patch the functions changed by `20261112` through `20261115`.
- `courses/index.ts` now combines that atomic RPC with the tested numeric
  normalization. Invalid/mismatched/incomplete provider cards cannot replace
  the cache; sparse refreshes preserve tee identity and existing holes.
- `20261117090000_shared_card_consent.sql` fixes the W2 storage boundary:
  owner checks admit both JPEG and PNG, and the owner can list/delete their
  copies. Other owners remain excluded. No new anonymous RPC/table access.
- The web and phone refuse the new round-link path until the existing owner
  predicate recognizes PNG, so shipping a client before the migration cannot
  treat policy-hidden objects as absent.

## Local validation (PostgreSQL 17)

The Mac ran the complete chain: **254 applied, zero skipped**. Course-cache
probes and shared-card storage RLS probes passed. The cache migration was
then reapplied against that same database with a populated cache, preserving
tee identity, holes and role grants. A second clean install is not the
idempotence test.

Reproduce from this checkout, with a fresh local socket/port:

```bash
mkdir -p /private/tmp/cup-season-october-mac-socket
PORT=5493 SOCK=/private/tmp/cup-season-october-mac-socket tests/sim/sandbox/apply.sh
/opt/homebrew/opt/postgresql@17/bin/psql -h /private/tmp/cup-season-october-mac-socket -p 5493 -U postgres -d cupseason -v ON_ERROR_STOP=1 -f tests/course-cache-checks.sql
/opt/homebrew/opt/postgresql@17/bin/psql -h /private/tmp/cup-season-october-mac-socket -p 5493 -U postgres -d cupseason -v ON_ERROR_STOP=1 -f tests/course-cache-reapply.sql
/opt/homebrew/opt/postgresql@17/bin/psql -h /private/tmp/cup-season-october-mac-socket -p 5493 -U postgres -d cupseason -v ON_ERROR_STOP=1 -f tests/shared-card-storage-checks.sql
python3 tests/course-cache-postgres.py
node --experimental-strip-types --test tests/courses-normalize.test.mjs tests/course-provider.test.mjs tests/share-consent-flow.test.mjs
```

`course-cache-postgres.py` creates its own isolated cluster. The three SQL
probe files above are for the local full-chain sandbox only. Never run them
against the linked production project.

## Owner deployment sequence

Use a reviewed checkout containing BOTH migrations and the integrated Edge
function. Read production's ledger and pending files again. If the ledger has
advanced, reconcile the actual pending set before any push; never rename an
applied migration. Deploying either layer requires the owner's authorization.

1. `./tools/ship.sh --dry-run` — inspect the database, Supabase Edge and client
   separately. Two migrations are expected from this Mac pass.
2. `supabase db push` — both the cache RPC and shared-card policies first.
3. `supabase functions deploy courses` — only after the cache RPC exists.
4. Read-only database checks (`tests/db-checks.sql`) and function/policy readback.
5. Authorized merge/client deployment, including Netlify's `share-preview.ts`.
   The Netlify preview function is deployed with the web build, separately from
   the Supabase `courses` function.
6. Verify a course fetch and authenticated share/photo-opt-out/revoke flows on
   the intended release build, including public PNG/JPEG removal. Confirm the
   actual live web stamp. Check `deploy-status` for each layer.

The shared-card policy change and client code are local/sandbox verified;
real Storage API deletion and real-device link sharing remain release checks.
Apple archives, TestFlight distribution, App Review and the two-phone gate
remain separate owner actions. A green local suite is not device proof.
