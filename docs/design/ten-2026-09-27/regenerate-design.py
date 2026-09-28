"""Regenerate the compiled DESIGN.md record; never changes product tokens."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[3]
source = root / "packages/tokens/tokens.json"
body = Path(__file__).with_name("design-system-body.md").read_text()
notice = "<!-- Generated from packages/tokens/tokens.json and docs/ui-overhaul-2026-09-06/UI_SYSTEM.md (read through later decisions); to change the system, change its source and regenerate this record rather than edit it. -->"
(root / "DESIGN.md").write_text(notice + "\n\n---\n" + json.dumps(json.loads(source.read_text()), indent=2) + "\n---\n" + body)
assert json.loads((root / "DESIGN.md").read_text().split("\n---\n", 2)[1]) == json.loads(source.read_text())
print("DESIGN token parity: exact")
