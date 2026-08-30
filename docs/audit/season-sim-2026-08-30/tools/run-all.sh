#!/usr/bin/env bash
# Run the whole trial matrix and save each result to ../data/<slug>.json
#   ./run-all.sh dry            rehearse every config, commit nothing
#   ./run-all.sh live           commit (footprint removable with 00-teardown.sql)
#   ./run-all.sh live a-2v2-cup only that one
set -uo pipefail
cd "$(dirname "$0")"
MODE="${1:?dry|live}"; shift || true
mkdir -p ../data

CFGS=()
if [ $# -gt 0 ]; then for s in "$@"; do CFGS+=("cfg/$s.json"); done
else for f in cfg/*.json; do CFGS+=("$f"); done; fi

pass=0; fail=0
for f in "${CFGS[@]}"; do
  slug="$(basename "$f" .json)"
  printf '%-18s ' "$slug"
  out="$(./run.sh "$MODE" "$f" 2>&1)"
  if echo "$out" | grep -q '"result"'; then
    echo "$out" | python3 -c "
import sys,json,re,pathlib
raw=sys.stdin.read()
m=re.search(r'\"result\": \"(.*?)\"\n', raw, re.S)
d=json.loads(m.group(1).encode().decode('unicode_escape'))
pathlib.Path('../data/${slug}.json').write_text(json.dumps(d,indent=2))
s=d['season']; c=d['config']
print('OK  %-9s %-12s %2dp %2dw  %-9s champ=%-14s %s-%s  lead_chg=%d clinch=%d' % (
  c['structure'], c['finish'], c['players'], c['weeks'], s['status'],
  str(s['champion'])[:14], s['champion_score'], s['runnerup_score'],
  d['lead_changes'], d['clinch_week']))
"
    pass=$((pass+1))
  else
    echo "FAIL"; echo "$out" | tail -5 | sed 's/^/      /'
    fail=$((fail+1))
  fi
done
echo; echo "passed $pass · failed $fail"
