#!/bin/bash
# apply.sh — rebuild the ISOLATED Cup Season simulation cluster from scratch.
#   initdb → start (port 5470, socket /tmp) → createdb cupseason → bootstrap.sql
#   → supabase/migrations/*.sql in filename order (as role postgres, ON_ERROR_STOP).
# Never touches production. Never calls the supabase CLI.
set -euo pipefail
PGBIN=/opt/homebrew/opt/postgresql@17/bin
SIM="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${REPO:-/Users/fischbeck3/cup-season-gameplay}"
MIG="$REPO/supabase/migrations"
PGDATA="$SIM/pgdata"
PORT=5470
SOCK=/tmp
DB=cupseason
LOG="$SIM/apply.log"
export PGHOST=$SOCK PGPORT=$PORT

# skipped.txt: lines of "<migration filename>  # reason"; blank/comment lines ignored
SKIP_FILE="$SIM/skipped.txt"

if [ -f "$PGDATA/postmaster.pid" ]; then
  "$PGBIN/pg_ctl" -D "$PGDATA" -m fast stop >/dev/null 2>&1 || true
fi
rm -rf "$PGDATA"
"$PGBIN/initdb" -D "$PGDATA" -U sim -A trust -E UTF8 --locale=C >/dev/null
cat >> "$PGDATA/postgresql.conf" <<CONF
port = $PORT
unix_socket_directories = '$SOCK'
listen_addresses = '127.0.0.1'
shared_preload_libraries = 'pg_stat_statements'
max_connections = 50
log_min_messages = warning
wal_level = logical
CONF
"$PGBIN/pg_ctl" -D "$PGDATA" -l "$SIM/postgres.log" -w start >/dev/null
"$PGBIN/psql" -U sim -d postgres -v ON_ERROR_STOP=1 -q -c "create database $DB" 
"$PGBIN/psql" -U sim -d $DB -v ON_ERROR_STOP=1 -q -f "$SIM/bootstrap.sql"

: > "$LOG"
applied=0; skipped=0
for f in $(ls "$MIG"/*.sql | sort); do
  base=$(basename "$f")
  if [ -f "$SKIP_FILE" ] && grep -qE "^$base\b" "$SKIP_FILE"; then
    echo "SKIP  $base" | tee -a "$LOG"; skipped=$((skipped+1)); continue
  fi
  # Filtered stream (the file on disk is never edited): extensions this local
  # cluster does not have are turned into no-ops; their surface is stubbed in bootstrap.sql.
  if ! sed -E \
      -e 's/^[[:space:]]*CREATE EXTENSION IF NOT EXISTS "supabase_vault".*$/-- [sim] supabase_vault stubbed in bootstrap.sql/I' \
      -e 's/^[[:space:]]*create extension if not exists pg_cron[[:space:]]*;.*$/-- [sim] pg_cron stubbed in bootstrap.sql/I' \
      -e 's/^[[:space:]]*create extension if not exists pg_net[[:space:]]*;.*$/-- [sim] pg_net stubbed in bootstrap.sql/I' \
      "$f" | "$PGBIN/psql" -U postgres -d $DB -v ON_ERROR_STOP=1 -q -X --single-transaction >>"$LOG" 2>&1; then
    echo "FAIL  $base  (see $LOG)"; tail -5 "$LOG"; exit 1
  fi
  "$PGBIN/psql" -U postgres -d $DB -q -X -c "insert into supabase_migrations.schema_migrations(version,name) values ('${base%%_*}', '${base#*_}') on conflict do nothing" >/dev/null
  echo "OK    $base" >> "$LOG"; applied=$((applied+1))
done
"$PGBIN/psql" -U postgres -d $DB -v ON_ERROR_STOP=1 -q -X -f "$SIM/post.sql"
echo "applied=$applied skipped=$skipped" | tee -a "$LOG"
"$PGBIN/psql" -U postgres -d $DB -X -c "select count(*) as public_functions from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'"
