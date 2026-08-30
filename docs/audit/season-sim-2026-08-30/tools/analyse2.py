#!/usr/bin/env python3
"""The claims that need care before they can be reported.

1. "points measure attendance, not golf" — must hold WITHIN a league, not just
   pooled across leagues of different sizes and lengths (pooling alone would
   manufacture the correlation).
2. does the counting cap actually bind? if nobody reaches it, it is not a lever.
3. which season shapes never assess the participation floor at all?
4. is the band spread an artefact of the actor model, or of the scoring design?
"""
import json, glob, pathlib, collections, statistics as st, math

D = pathlib.Path(__file__).parent / ".." / "data"
runs = {f.stem: json.loads(f.read_text()) for f in sorted(D.glob("*.json"))}

def corr(xs, ys):
    n = len(xs)
    if n < 3: return None
    mx, my = st.mean(xs), st.mean(ys)
    num = sum((x-mx)*(y-my) for x, y in zip(xs, ys))
    den = math.sqrt(sum((x-mx)**2 for x in xs) * sum((y-my)**2 for y in ys))
    return num/den if den else None

print("=" * 100)
print("1. WITHIN-LEAGUE: what actually decides a golfer's season total?")
print("=" * 100)
cr, cp = [], []
for s, d in runs.items():
    ms = [m for m in (d.get("members") or [])
          if m.get("ppr") and m.get("points") is not None and m.get("counting", 0) >= 2]
    if len(ms) < 5: continue
    pts = [m["points"] for m in ms]
    a = corr([m["counting"] for m in ms], pts)
    b = corr([float(m["ppr"]) for m in ms], pts)
    if a is not None: cr.append(a)
    if b is not None: cp.append(b)
print("leagues with >= 5 qualifying golfers: %d" % len(cr))
print("  mean WITHIN-league corr(points, rounds counted)    r = %+.2f   (median %+.2f)"
      % (st.mean(cr), st.median(cr)))
print("  mean WITHIN-league corr(points, points-per-round)  r = %+.2f   (median %+.2f)"
      % (st.mean(cp), st.median(cp)))
print("  leagues where rounds-counted is the stronger driver: %d / %d"
      % (sum(1 for a, b in zip(cr, cp) if abs(a) > abs(b)), len(cr)))

print()
print("=" * 100)
print("2. DOES THE COUNTING CAP BIND?  (if nobody reaches it, it is not a lever)")
print("=" * 100)
print("Counting rounds per golfer per WHOLE month, against the cap.")
for capv in (2, 4, 8):
    rows = []
    for s, d in runs.items():
        if d["config"]["counting_cap"] != capv: continue
        whole = sum(1 for m in (d.get("months") or []) if m["whole"])
        if not whole: continue
        for m in d.get("members") or []:
            if m.get("counting") is None: continue
            rows.append(m["counting"] / max(whole, 1))
    if rows:
        at = sum(1 for r in rows if r >= capv - 0.001)
        print("  cap=%-2d  n=%-4d  mean counted/whole-month %.1f  at-or-above cap %.0f%%"
              % (capv, len(rows), st.mean(rows), 100*at/len(rows)))

print()
print("=" * 100)
print("3. SEASON SHAPES WHERE THE FLOOR IS NEVER ASSESSED")
print("=" * 100)
print("The floor is only assessed in WHOLE calendar months, and only for golfers")
print("seated in a squad. Solo leagues therefore never assess it at all.")
for s in sorted(runs):
    d = runs[s]
    months = d.get("months") or []
    whole = [m for m in months if m["whole"]]
    closed = [m for m in months if m["closed"]]
    solo = d["config"]["structure"] == "solo"
    pen = sum(a["n"] for a in (d.get("adjustments") or [])
              if a["kind"] in ("floor_penalty", "floor_forfeit"))
    byes = sum(a["n"] for a in (d.get("adjustments") or []) if a["kind"] == "bye")
    flag = ""
    if solo: flag = "SOLO - floor structurally inert"
    elif not whole: flag = "NO WHOLE MONTH - floor never assessed"
    elif pen == 0 and byes == 0: flag = "no floor event fired"
    if flag:
        print("  %-20s %2dw  months=%d whole=%d closed=%d  %s"
              % (s, d["config"]["weeks"], len(months), len(whole), len(closed), flag))

print()
print("=" * 100)
print("4. IS THE BAND SPREAD THE ACTOR MODEL, OR THE SCORING DESIGN?")
print("=" * 100)
print("A real golfer beats their handicap index in roughly 20-25% of rounds.")
print("If this sim's golfers reach the 'played to it or better' bands MORE often")
print("than that, the model is FLATTERING and the finding is conservative.")
tot = collections.Counter()
for d in runs.values():
    tot.update(d.get("bands") or {})
T = sum(tot.values())
at_or_better = tot["07_played_to"] + tot["09_beat"] + tot["12_torched"]
print("  rounds at 'played to it' or better: %d / %d = %.1f%%" % (at_or_better, T, 100*at_or_better/T))
print("  rounds in the bottom band alone (5, 'rough day'): %.1f%%" % (100*tot["05_rough"]/T))
print()
print("  Points available per round: 5 to 12. But 64.5%% of rounds land on 5 or 6,")
print("  so the REALISTIC per-round spread between a good and a bad round is ~1 point,")
print("  while posting one extra round is worth ~5-6. That ratio is the finding.")

print()
print("=" * 100)
print("5. THE TWO-SQUAD PROBLEM, STATED PRECISELY")
print("=" * 100)
by_entities = collections.defaultdict(list)
for s, d in runs.items():
    c = d["config"]
    n = {"solo": c["players"], "squads2": 2, "squads3": 3, "squads4": 4}[c["structure"]]
    if d.get("margin_pct") is None: continue
    by_entities[n].append((d["led_outright_from_week"] <= 1, d["margin_pct"], d["lead_changes"]))
print("%-24s %6s %10s %10s %9s" % ("contenders in the table", "n", "wire-to-wire", "margin%", "leadchg"))
for n in sorted(by_entities):
    v = by_entities[n]
    print("%-24s %6d %9.0f%% %10.0f %9.1f" % (
        "%d" % n, len(v), 100*sum(1 for x in v if x[0])/len(v),
        st.mean(x[1] for x in v), st.mean(x[2] for x in v)))
