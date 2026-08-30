import sys, json, re, pathlib
slug = sys.argv[1]; raw = sys.stdin.read()
m = re.search(r'"result": "(.*?)"\n', raw, re.S)
if not m:
    print(f"{slug:14s} FAIL"); print("\n".join("   "+l for l in raw.strip().splitlines()[-8:])); sys.exit(1)
d = json.loads(m.group(1).encode().decode("unicode_escape"))
pathlib.Path("../data-ryder").mkdir(exist_ok=True)
pathlib.Path(f"../data-ryder/{slug}.json").write_text(json.dumps(d, indent=2))
t = d["teams"]; sess = d["sessions"]
closed = sum(1 for s in sess if s["status"] == "closed")
print("%-14s %-9s winner=%-10s %s %s-%s  duels %s/%s resolved  walkovers=%s  sessions closed %d/%d  trophies=%s" % (
    slug, d["status"], str(d["winner"]), "SHARED" if d["shared"] else "",
    t[0]["points"], t[1]["points"], d["duels_resolved"], d["duels_total"],
    d["walkovers"], closed, len(sess), d["trophies"]))
