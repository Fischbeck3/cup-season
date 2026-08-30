#!/usr/bin/env python3
"""Aggregate the simulated seasons. Independent of the analysis agents."""
import json, glob, pathlib, collections, statistics as st

D = pathlib.Path(__file__).parent / ".." / "data"
runs = {}
for f in sorted(D.glob("*.json")):
    runs[f.stem] = json.loads(f.read_text())

def fam(slug):
    return slug.rsplit("-r", 1)[0] if "-r" in slug else slug

fams = collections.defaultdict(list)
for s, d in runs.items():
    fams[fam(s)].append(d)

print(f"{len(runs)} seasons, {len(fams)} configs\n")

# ---------- 1. is it decided early? ----------
print("=" * 108)
print("COMPETITIVE SHAPE  (points-table race; cup leagues also settle a separate Cup Final)")
print("=" * 108)
hdr = "%-17s %-8s %-12s %3s %4s | %5s %6s %7s %8s %7s" % (
    "config", "struct", "finish", "p", "wks", "leads", "ledFr", "unchal", "margin%", "wire")
print(hdr); print("-" * 108)
for k in sorted(fams):
    rs = fams[k]; c = rs[0]["config"]
    lead = st.mean(r["lead_changes"] for r in rs)
    ledf = st.mean(r["led_outright_from_week"] for r in rs)
    unch = st.mean(r["weeks_led_unchallenged"] for r in rs)
    mp   = [r["margin_pct"] for r in rs if r.get("margin_pct") is not None]
    wire = sum(1 for r in rs if r["led_outright_from_week"] <= 1)
    print("%-17s %-8s %-12s %3d %4d | %5.1f %6.1f %7.1f %8s %4d/%d" % (
        k, c["structure"], c["finish"], c["players"], c["weeks"],
        lead, ledf, unch, ("%.0f" % st.mean(mp)) if mp else "-", wire, len(rs)))

# ---------- 2. what does a point mean? ----------
print()
print("=" * 108)
print("BAND SPREAD  (every counting round, by the band it scored)")
print("=" * 108)
ORDER = ["05_rough", "06_loose", "07_played_to", "09_beat", "12_torched"]
LABEL = {"05_rough": "5 rough day", "06_loose": "6 a bit loose",
         "07_played_to": "7 played to it", "09_beat": "9 beat it", "12_torched": "12 torched"}
tot = collections.Counter()
for d in runs.values():
    for b, n in (d.get("bands") or {}).items():
        tot[b] += n
T = sum(tot.values())
print("%-17s %8s %7s" % ("band", "rounds", "share"))
print("-" * 34)
for b in ORDER:
    print("%-17s %8d %6.1f%%" % (LABEL[b], tot[b], 100 * tot[b] / T))
print("%-17s %8d" % ("TOTAL", T))
print("\nbottom two bands (5+6): %.1f%%   top two (9+12): %.1f%%" % (
    100 * (tot["05_rough"] + tot["06_loose"]) / T,
    100 * (tot["09_beat"] + tot["12_torched"]) / T))

print("\nby counting_cap:")
bycap = collections.defaultdict(collections.Counter)
for d in runs.values():
    bycap[d["config"]["counting_cap"]].update(d.get("bands") or {})
for cap in sorted(bycap):
    c = bycap[cap]; n = sum(c.values())
    print("  cap=%-2s n=%-5d  low(5-6)=%4.1f%%  high(9-12)=%4.1f%%" % (
        cap, n, 100*(c["05_rough"]+c["06_loose"])/n, 100*(c["09_beat"]+c["12_torched"])/n))

print("\nby allowance:")
byal = collections.defaultdict(collections.Counter)
for d in runs.values():
    byal[d["config"]["allowance"]].update(d.get("bands") or {})
for a in sorted(byal):
    c = byal[a]; n = sum(c.values())
    print("  allow=%-4s n=%-5d low(5-6)=%4.1f%%  high(9-12)=%4.1f%%" % (
        a, n, 100*(c["05_rough"]+c["06_loose"])/n, 100*(c["09_beat"]+c["12_torched"])/n))

# ---------- 3. the handicap engine ----------
print()
print("=" * 108)
print("WHAT THE INDEX ENGINE DOES TO A GOLFER'S NUMBER")
print("=" * 108)
drift = []
for d in runs.values():
    for m in d.get("members") or []:
        if m.get("index_end") is not None and m.get("rounds", 0) >= 3:
            drift.append((m["true_skill"], float(m["index_end"]), m["rounds"], m["archetype"]))
if drift:
    print("golfers with 3+ rounds: %d" % len(drift))
    print("mean true skill %.1f -> mean index the engine settled on %.1f  (mean move %.1f)" % (
        st.mean(x[0] for x in drift), st.mean(x[1] for x in drift),
        st.mean(x[1] - x[0] for x in drift)))
    by = collections.defaultdict(list)
    for tsk, ie, n, a in drift:
        by[a].append(ie - tsk)
    print("\n%-13s %6s %9s" % ("archetype", "n", "mean move"))
    for a in sorted(by, key=lambda a: st.mean(by[a])):
        print("%-13s %6d %9.1f" % (a, len(by[a]), st.mean(by[a])))

# ---------- 4. does playing well separate you? ----------
print()
print("=" * 108)
print("DOES PLAYING WELL SEPARATE YOU, OR DOES POSTING?")
print("=" * 108)
print("Within each league: spread of points-per-round vs spread of rounds posted.")
pprs, rnds = [], []
for s, d in runs.items():
    ms = [m for m in (d.get("members") or []) if m.get("ppr") and m.get("counting", 0) >= 3]
    if len(ms) < 4: continue
    p = [float(m["ppr"]) for m in ms]; r = [m["counting"] for m in ms]
    pprs.append((max(p) - min(p)) / st.mean(p))
    rnds.append((max(r) - min(r)) / st.mean(r))
print("mean within-league relative spread in points-per-round : %.1f%%" % (100*st.mean(pprs)))
print("mean within-league relative spread in rounds counted    : %.1f%%" % (100*st.mean(rnds)))
print("-> the bigger number is what actually decides the table")

# correlation of season points with ppr vs with rounds
import math
def corr(xs, ys):
    n=len(xs); mx=st.mean(xs); my=st.mean(ys)
    num=sum((x-mx)*(y-my) for x,y in zip(xs,ys))
    den=math.sqrt(sum((x-mx)**2 for x in xs)*sum((y-my)**2 for y in ys))
    return num/den if den else float('nan')
P,R,PT = [],[],[]
for d in runs.values():
    for m in d.get("members") or []:
        if m.get("ppr") and m.get("points") is not None and m.get("counting",0)>=3:
            P.append(float(m["ppr"])); R.append(m["counting"]); PT.append(m["points"])
print("\ncorrelation of season points with points-per-round : r = %+.2f" % corr(P, PT))
print("correlation of season points with rounds counted   : r = %+.2f" % corr(R, PT))

# ---------- 5. the floor ----------
print()
print("=" * 108)
print("THE PARTICIPATION FLOOR")
print("=" * 108)
kinds = collections.Counter(); seasons_with_penalty = 0; nowhole = []
for s, d in runs.items():
    ks = collections.Counter()
    for a in d.get("adjustments") or []:
        ks[a["kind"]] += a["n"]
    kinds.update(ks)
    if ks["floor_penalty"] or ks["floor_forfeit"]:
        seasons_with_penalty += 1
    months = d.get("months") or []
    if not any(m["whole"] and m["closed"] for m in months):
        nowhole.append((s, d["config"]["weeks"], len(months)))
print("adjustment rows across all %d seasons: %s" % (len(runs), dict(kinds)))
print("seasons where any floor penalty fired: %d / %d" % (seasons_with_penalty, len(runs)))
print("seasons where NO whole calendar month ever closed (floor never assessed): %d" % len(nowhole))
for s, w, nm in nowhole:
    print("    %-20s %2d weeks, %d calendar months touched" % (s, w, nm))

ghosts = []
for s, d in runs.items():
    for m in d.get("members") or []:
        if m["archetype"] in ("ghost", "lurker"):
            ghosts.append((s, m["archetype"], m["rounds"], m["points"], d["config"]["structure"]))
print("\nghost/lurker seats: %d" % len(ghosts))
print("  mean rounds posted %.1f, mean season points %.0f" % (
    st.mean(g[2] for g in ghosts), st.mean(g[3] for g in ghosts)))
print("  seats that posted ZERO rounds all season: %d" % sum(1 for g in ghosts if g[2] == 0))

# ---------- 6. the finish ----------
print()
print("=" * 108)
print("THE FINISH")
print("=" * 108)
cup = {s: d for s, d in runs.items() if d["config"]["finish"] == "cup_final"
       and d["season"]["status"] == "complete"}
pts = {s: d for s, d in runs.items() if d["config"]["finish"] == "points_table"
       and d["season"]["status"] == "complete"}
flip = sum(1 for d in cup.values() if d.get("cup_flipped_result"))
print("cup_final seasons completed: %d — the Cup Final crowned someone other than the" % len(cup))
print("   regular-season #1 seed in %d of them (%.0f%%)" % (flip, 100*flip/max(len(cup),1)))
hs = sum(1 for d in cup.values() if d.get("head_start_decisive"))
print("the squads2 +10 head start alone decided: %d" % hs)
kd = sum(1 for d in cup.values()
         if d["season"].get("points_king") and d["season"].get("champion")
         and str(d["season"]["points_king"]) not in str(d["season"]["champion"]))
print("\nchampion score vs runner-up, by endgame:")
for nm, grp in (("cup_final", cup), ("points_table", pts)):
    if not grp: continue
    sc = [(float(d["season"]["champion_score"]), float(d["season"]["runnerup_score"]))
          for d in grp.values() if d["season"]["champion_score"] is not None]
    if sc:
        print("  %-13s mean winning number %6.0f, runner-up %6.0f, mean gap %5.0f (%4.1f%%)" % (
            nm, st.mean(a for a,b in sc), st.mean(b for a,b in sc),
            st.mean(a-b for a,b in sc), 100*st.mean((a-b)/a for a,b in sc if a)))
rungs = collections.Counter(d["season"].get("tiebreak_rung") for d in runs.values())
print("\ntiebreak rung used to separate 1st and 2nd: %s" % dict(rungs))
