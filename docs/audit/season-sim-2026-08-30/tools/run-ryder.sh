#!/usr/bin/env bash
# Ryder simulator driver.
#   ./run-ryder.sh dry  cfg-ryder/<slug>.json   rehearse inside a ROLLBACK
#   ./run-ryder.sh live cfg-ryder/<slug>.json   commit
# Applies the fixed resolve_session first, because the shipped one cannot run.
set -euo pipefail
cd "$(dirname "$0")"
MODE="${1:?dry|live}"; CFG="${2:?config json path}"
SLUG="$(basename "$CFG" .json)"
JSON="$(cat "$CFG" | tr -d '\n')"

TAIL="rollback;"
[ "$MODE" = "live" ] && TAIL="commit;"

SQL="begin;
$(cat ../../../../supabase/migrations/20260830160000_resolve_session_ambiguous_pvi.sql)
$(cat ../../../../supabase/migrations/20260830170000_shared_cup_trophy_scope.sql)
$(cat ../../../../supabase/migrations/20260830190000_ryder_dials.sql)
$(cat ../../../../supabase/migrations/20260830200000_event_teams_rls_and_consent.sql)
$(cat ../../../../supabase/migrations/20260830210000_ryder_decided_by.sql)
$(cat 10-sim-schema.sql)
$(cat 40-sim-ryder.sql)
select sim.ryder('${SLUG}', \$cfg\$${JSON}\$cfg\$::jsonb) is not null as built;
select sim.ryder_play('${SLUG}') as played;
select jsonb_pretty(sim.ryder_result('${SLUG}')) as result;
${TAIL}"

supabase db query --linked "$SQL" --output-format text 2>&1 | tail -160
