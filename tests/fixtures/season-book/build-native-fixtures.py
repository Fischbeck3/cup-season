"""Embed checked synthetic RPC output only inside a DEBUG compilation guard."""
from pathlib import Path
import json, subprocess
root = Path(__file__).resolve().parents[3]
subprocess.run(["node", str(root / "tests/ten-fixtures-build.mjs"), "--check"], check=True)
files = ["squads", "tie", "upcoming", "finished", "home"]
rows = []
for name in files:
    payload = json.loads((root / "tests/fixtures/ten" / f"book-{name}.synthetic.json").read_text())
    payload.pop("_ten", None)
    rows.append('  static let ' + name + ' = #"' + json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + '"#\n')
p = root / "apps/ios/CupSeason/Compete/SeasonBookFixtureJSON.swift"
p.write_text('// Checked synthetic RPC captures; regenerate with tests/fixtures/season-book/build-native-fixtures.py.\n#if DEBUG\nenum SeasonBookFixtureJSON {\n' + ''.join(rows) + '}\n#endif\n')
