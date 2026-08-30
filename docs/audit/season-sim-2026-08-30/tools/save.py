#!/usr/bin/env python3
"""Read a run.sh transcript on stdin, save the result JSON, print one line."""
import sys, json, re, pathlib

slug = sys.argv[1]
raw = sys.stdin.read()
m = re.search(r'"result": "(.*?)"\n', raw, re.S)
if not m:
    print(f"{slug:18s} FAIL")
    print("\n".join("      " + l for l in raw.strip().splitlines()[-6:]))
    sys.exit(1)
d = json.loads(m.group(1).encode().decode("unicode_escape"))
pathlib.Path(__file__).parent.joinpath("..", "data", f"{slug}.json").resolve().write_text(
    json.dumps(d, indent=2))
s, c = d["season"], d["config"]
print("%-18s OK %-8s %-12s %2dp %3dw %-9s champ=%-15s %s-%s lead=%d led_from=%d unchal=%d" % (
    slug, c["structure"], c["finish"], c["players"], c["weeks"], s["status"],
    str(s["champion"])[:15], s["champion_score"], s["runnerup_score"],
    d["lead_changes"], d["led_outright_from_week"], d["weeks_led_unchallenged"]))
