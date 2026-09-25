#!/bin/bash
# Launch-audit repair verification (2026-09-24). A NEW isolated PostgreSQL 17 cluster per
# run: the full repository migration chain (a fresh install), the Book fixture seed, the
# Book's own verification, a REAPPLY of every repair migration (idempotence), then the
# repair scenarios. Never a linked or shared database; never the Supabase CLI.
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
root="$(mktemp -d /private/tmp/cs-season-book-launch-repair-XXXXXX)"
export PGDATA="$root/pgdata" SOCK="$root/sock" SIM_LOG="$root/apply.log"
export PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
export PGBIN=/opt/homebrew/opt/postgresql@17/bin
mkdir -p "$SOCK"
trap 'if [ -f "$PGDATA/postmaster.pid" ]; then "$PGBIN/pg_ctl" -D "$PGDATA" -m fast stop >/dev/null; fi' EXIT
printf 'Local test evidence: %s\n' "$root"
bash tests/sim/sandbox/apply.sh > "$root/bootstrap-output.log" 2>&1
printf 'fresh install: %s migrations\n' "$(ls supabase/migrations/*.sql | wc -l | tr -d ' ')"
psql_() { "$PGBIN/psql" -X -q -h "$SOCK" -p "$PORT" -U postgres -d cupseason -v ON_ERROR_STOP=1 "$@"; }
psql_ --single-transaction -f tests/fixtures/season-book/seed.sql
python3 tests/fixtures/season-book/verify.py --socket "$SOCK" --port "$PORT" | tail -1
# Reapply: every repair migration a second time must be harmless (each patch is guarded).
for f in supabase/migrations/*.sql; do
  v="$(basename "$f" | cut -d_ -f1)"
  # the repair migrations are exactly those after the applied Book (20261118090000)
  [ "$v" -gt 20261118090000 ] || continue
  psql_ --single-transaction -f "$f" > "$root/reapply-$(basename "$f").log" 2>&1 || { echo "REAPPLY FAILED: $f"; tail -5 "$root/reapply-$(basename "$f").log"; exit 1; }
done
echo "reapply: every repair migration applied a second time without error"
python3 tests/fixtures/launch-repair/verify.py --socket "$SOCK" --port "$PORT"
