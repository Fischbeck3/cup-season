#!/bin/bash
# A new, isolated cluster per run. Never use a linked or shared database.
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$repo"
book_root="$(mktemp -d /private/tmp/cs-season-book-final-XXXXXX)"
export PGDATA="$book_root/pgdata" SOCK="$book_root/sock" SIM_LOG="$book_root/apply.log"
export PORT="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"
export PGBIN=/opt/homebrew/opt/postgresql@17/bin
mkdir -p "$SOCK"
trap 'if [ -f "$PGDATA/postmaster.pid" ]; then "$PGBIN/pg_ctl" -D "$PGDATA" -m fast stop >/dev/null; fi' EXIT
printf 'Local test evidence: %s\n' "$book_root"
bash tests/sim/sandbox/apply.sh > "$book_root/bootstrap-output.log" 2>&1
"$PGBIN/psql" -X -q -h "$SOCK" -p "$PORT" -U postgres -d cupseason -v ON_ERROR_STOP=1 --single-transaction -f tests/fixtures/season-book/seed.sql
# Re-applying the new function/patch must be harmless.
"$PGBIN/psql" -X -q -h "$SOCK" -p "$PORT" -U postgres -d cupseason -v ON_ERROR_STOP=1 --single-transaction -f supabase/migrations/20261118090000_the_book.sql
python3 tests/fixtures/season-book/verify.py --socket "$SOCK" --port "$PORT"
