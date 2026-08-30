#!/usr/bin/env bash
# Season simulator driver.
#   ./run.sh dry  <cfg.json>   apply schema + build + play inside a ROLLBACK
#   ./run.sh live <cfg.json>   the same, committed
# Everything it creates is removable with 00-teardown.sql.
set -euo pipefail
cd "$(dirname "$0")"
MODE="${1:?dry|live}"; CFG="${2:?config json path}"
SLUG="$(basename "$CFG" .json)"
JSON="$(cat "$CFG" | tr -d '\n')"

TAIL="rollback;"
[ "$MODE" = "live" ] && TAIL="commit;"

SQL="begin;
$(cat 10-sim-schema.sql)
$(cat 20-sim-run.sql)
$(cat 30-sim-result.sql)
select sim.build('${SLUG}', \$cfg\$${JSON}\$cfg\$::jsonb) is not null as built;
select sim.play('${SLUG}') as played;
update sim.runs set result = sim.result('${SLUG}') where slug = '${SLUG}';
select jsonb_pretty(result) as result from sim.runs where slug = '${SLUG}';
${TAIL}"

supabase db query --linked "$SQL" --output-format text 2>&1 | tail -200
