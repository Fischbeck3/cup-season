#!/usr/bin/env bash
# Cup Season · UI-test review world on the DISPOSABLE LOCAL stack.
#
#   ./seed.sh                      # uses ~/.cache/cs-readiness-stack
#   CS_STACK_WORKDIR=<dir> ./seed.sh
#
# Creates (if absent) one fictional test golfer and seven fictional bots through
# the LOCAL auth admin API, then applies world.sql as the local postgres role.
# Idempotent: re-running changes nothing. Refuses any host but 127.0.0.1/localhost.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
workdir="${CS_STACK_WORKDIR:-$HOME/.cache/cs-readiness-stack}"
GOLFER="${CS_UITEST_GOLFER:-rc-uitest-golfer@example.invalid}"
BOTS=""
for i in 1 2 3 4 5 6 7; do BOTS="${BOTS:+$BOTS,}rc-uitest-bot$i@example.invalid"; done

env_file="$(mktemp)"; trap 'rm -f "$env_file"' EXIT
supabase status --workdir "$workdir" -o env 2>/dev/null > "$env_file"
# shellcheck disable=SC1090
source "$env_file"
case "$API_URL" in http://127.0.0.1:*|http://localhost:*) ;; *) echo "refusing: API_URL is not local ($API_URL)" >&2; exit 2;; esac
case "$DB_URL" in *@127.0.0.1:*|*@localhost:*) ;; *) echo "refusing: DB_URL is not local" >&2; exit 2;; esac

make_user() {  # $1 email — created confirmed, no password (sign-in is the emailed code)
  local email="$1" have
  have="$(psql "$DB_URL" -Atc "select count(*) from auth.users where lower(email) = lower('$email')")"
  if [ "$have" = "0" ]; then
    curl -sf -X POST "$API_URL/auth/v1/admin/users" \
      -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" -H "Content-Type: application/json" \
      -d "{\"email\":\"$email\",\"email_confirm\":true}" > /dev/null
    echo "created $email"
  else
    echo "exists  $email"
  fi
}

make_user "$GOLFER"
IFS=',' read -ra bot_list <<< "$BOTS"
for b in "${bot_list[@]}"; do make_user "$b"; done

psql "$DB_URL" -v ON_ERROR_STOP=1 -q \
  -c "select set_config('rcui.golfer', '$GOLFER', false), set_config('rcui.bots', '$BOTS', false)" \
  -f "$here/world.sql" > /dev/null
psql "$DB_URL" -v ON_ERROR_STOP=1 -At <<SQL
select 'golfer: ' || p.display_name || ' · ' || p.handle || ' · rounds ' ||
       (select count(*) from rounds r where r.profile_id = p.id) || ' · leagues ' ||
       (select count(*) from league_members m where m.profile_id = p.id)
  from profiles p join auth.users u on u.id = p.id where lower(u.email) = lower('$GOLFER');
select 'course 100: ' || count(distinct t.id) || ' tees, ' || count(h.id) || ' holes'
  from api_course_tees t left join api_course_holes h on h.tee_id = t.id where t.course_id = '100';
SQL
