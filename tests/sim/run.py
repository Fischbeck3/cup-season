#!/usr/bin/env python3
"""Run the season simulations.

  python3 tests/sim/run.py                 # every family, mirror engine, seed 7
  python3 tests/sim/run.py S2_handicaps    # one family
  python3 tests/sim/run.py --mc 300        # Monte Carlo on S1/S2/S3 over 300 seeds
  python3 tests/sim/run.py --engine real   # drive the sandbox (engine_real.py)

Writes tests/sim/results/<family>.json and prints tables. stdlib only.
"""
from __future__ import annotations
import json, os, random, sys, copy
from collections import defaultdict
from dataclasses import asdict
from datetime import date, timedelta
sys.path.insert(0, os.path.dirname(__file__))
from golfers import Golfer, Round, history, season_rounds
import engine_mirror as E
from engine_real import Real
from scenarios import FAMILIES, EXPLICIT

OUT = os.path.join(os.path.dirname(__file__), "results"); os.makedirs(OUT, exist_ok=True)

def build(family, seed):
    rng = random.Random(seed)
    golfers, bylaws, start, end, note = FAMILIES[family]()
    G = {g.name: g for g in golfers}
    nsq = len({g.squad for g in golfers})
    bylaws.structure = {1: "solo", 2: "squads2", 3: "squads3"}.get(nsq, "squads4")   # same rule as engine_real
    if family in EXPLICIT:
        prior, rounds = EXPLICIT[family](G, start, end)
    else:
        prior = {g.name: history(rng, g, start) for g in golfers}
        rounds = {g.name: season_rounds(rng, g, start, end) for g in golfers}
    return G, bylaws, start, end, note, prior, rounds

def run_mirror(G, bylaws, start, end, prior, rounds):
    scored = E.score_rounds(rounds, prior, bylaws)
    lines = E.close_months(scored, G, start, end, bylaws)
    table = E.squad_table(lines, G)
    cup = E.cup_final(scored, G, lines, start, end, bylaws)
    clash = E.weekly_clash(scored, G, start, bylaws.weeks)
    return scored, lines, table, cup, clash

def per_golfer(scored, lines):
    out = {}
    for g, ss in scored.items():
        cnt = [s for s in ss if s.counting]
        pen = sum(ml.penalties.get(g, 0) for ml in lines)
        out[g] = {"rounds": len([s for s in ss if not s.r.voided]), "counting": len(cnt),
                  "points": sum(s.points for s in cnt), "penalties": pen,
                  "avg_pvi": round(sum(s.pvi for s in ss if s.pvi is not None)/max(1,len([s for s in ss if s.pvi is not None])),2),
                  "ability": None, "index_start": ss[0].index_at_post if ss else None, "index_end": ss[-1].index_at_post if ss else None,
                  "bands": {b: sum(1 for s in ss if s.points == b) for b in (12,9,7,6,5)}}
    return out

def print_table(title, rows, cols):
    print(f"\n== {title}")
    w = [max(len(str(c)), *(len(str(r.get(c, ""))) for r in rows)) for c in cols]
    print("  " + "  ".join(str(c).ljust(x) for c, x in zip(cols, w)))
    for r in rows: print("  " + "  ".join(str(r.get(c, "")).ljust(x) for c, x in zip(cols, w)))

def report(family, seed, G, bylaws, start, end, note, scored, lines, table, cup, clash, extra=None):
    print(f"\n#### {family}  (seed {seed}) — {note}")
    print(f"   season {start} → {end} · {bylaws.weeks} wk · cap {bylaws.cap} · floor {bylaws.floor} ({bylaws.penalty}) · allowance {bylaws.allowance}%")
    pg = per_golfer(scored, lines)
    rows = [{"golfer": g, "squad": G[g].squad, **{**v, "ability": G[g].ability}, "bands": " ".join(f"{k}:{n}" for k, n in v["bands"].items() if n)} for g, v in pg.items()]
    print_table("golfers", rows, ["golfer","squad","ability","index_start","index_end","avg_pvi","rounds","counting","points","penalties","bands"])
    mrows = [{"month": ml.month, "from": ml.a, "to": ml.b, "partial": ml.partial,
              "points": {g: p for g, p in ml.per_golfer_points.items()},
              "penalties": ml.penalties, "byes": sorted(ml.byes_used), "forfeits": sorted(ml.forfeits)} for ml in lines]
    for r in mrows: print(f"   month {r['month']} {r['from']}→{r['to']}{' PARTIAL(waived)' if r['partial'] else ''}: pts {r['points']} pen {r['penalties']} byes {r['byes']} forfeits {r['forfeits']}")
    print("   squad table:", dict(sorted(table.items(), key=lambda kv: -kv[1])))
    print(f"   CUP: seeds {cup.seeds} locked {cup.lock_on}, window {cup.window[0]}→{cup.window[1]}, window pts {cup.final_points}, champion {cup.champion}"
          + (f" via {cup.tiebreak_used}" if cup.tiebreak_used else ""))
    wins = defaultdict(int)
    for c in clash:
        if c["winner"]: wins[c["winner"]] += 1
    print(f"   CLASH record (W): {dict(wins)}  — squad table unchanged by it: {table == E.squad_table(lines, G)}")
    if extra: print("   " + "\n   ".join(extra))
    with open(os.path.join(OUT, f"{family}.json"), "w") as f:
        json.dump({"family": family, "seed": seed, "note": note, "bylaws": asdict(bylaws),
                   "season": [str(start), str(end)], "golfers": pg, "months": [{**r, "from": str(r["from"]), "to": str(r["to"])} for r in mrows],
                   "squads": table, "cup": {**asdict(cup), "lock_on": str(cup.lock_on), "window": [str(x) for x in cup.window]},
                   "clash_wins": dict(wins), "extra": extra or [], "assumptions": E.assumptions()}, f, indent=1, default=str)

def edits_for_S6(G, rounds, prior, start, end, bylaws):
    """Engineer the edge cases on top of generated rounds; returns notes."""
    notes = []
    # (a) a LATE POST: T1's first March round is posted 12 days after it was played
    r = min(rounds["T1"], key=lambda r: r.played_on); r.posted_on = r.played_on + timedelta(days=12)
    notes.append(f"late post: T1 played {r.played_on}, posted {r.posted_on} — counts for the month PLAYED (7-day wall unenforced, spec §9)")
    # (b) a VOID: U1's best round is voided after posting
    scored0 = E.score_rounds(rounds, prior, bylaws)
    best = max(scored0["U1"], key=lambda s: s.points); best.r.voided = True
    notes.append(f"void: U1's {best.r.played_on} ({best.points} pts, diff {best.r.differential}) voided — leaves standings AND the index history")
    # (c) a CORRECTION: T2's worst round gross was mistyped 10 high; corrected = void + repost same day
    worst = max(rounds["T2"], key=lambda r: r.gross)
    fixed = Round(worst.golfer, worst.played_on, worst.gross - 10, round(worst.differential - 10*113/128, 1), worst.played_on)
    worst.voided = True; rounds["T2"].append(fixed)
    notes.append(f"correction: T2's {worst.played_on} gross {worst.gross} → {fixed.gross}; the old round is voided, a new fact is posted (rounds are never mutated)")
    return notes

def force_tie_S6(scored, G, lines, start, end, bylaws):
    """Make the two squads tie in the Final window by trimming points, then walk the ladder."""
    cup = E.cup_final(scored, G, lines, start, end, bylaws)
    return cup


def run_real(fam, seed, G, bylaws, start, end, prior, rounds, edits=None):
    """Replay the same generated rounds through the sandbox and read the engine's answers."""
    squads = sorted({g.squad for g in G.values()})
    R = Real(f"{fam}-{seed}").setup(G, bylaws, start, end, squads)
    # everything in the order it would have been posted
    todo = []
    for n in G:
        for r in prior.get(n, []): todo.append((r.played_on, r.played_on, n, r))
        for r in rounds.get(n, []): todo.append((r.posted_on, r.played_on, n, r))
    todo.sort(key=lambda t: (t[0], t[1]))
    ids = {}
    joined = set()
    for posted, played, n, r in todo:
        if n in R.late and n not in joined and played >= start + timedelta(days=G[n].join_offset_days):
            R.late_join(n, G[n], start + timedelta(days=G[n].join_offset_days)); joined.add(n)
        ids[id(r)] = R.post(n, r)
    for n, rs in rounds.items():
        for r in rs:
            if r.voided and ids.get(id(r)): R.delete(n, ids[id(r)])
    R.close_months(); R.finish()
    return R.read()

def compare(fam, table, pg, cup, real):
    print(f"\n== REAL ENGINE vs MIRROR · {fam}")
    diffs = []
    for s in sorted(set(table) | set(real["squads"])):
        m, r = table.get(s, 0), real["squads"].get(s, 0)
        flag = "" if m == r else "  <-- DIFF"
        print(f"   squad {s}: mirror {m:4}  real {r:4}{flag}")
        if m != r: diffs.append(("squad", s, m, r))
    for g in sorted(pg):
        m = pg[g]["points"] + pg[g]["penalties"]; rc = real["counting"].get(g, {})
        r = rc.get("counting_points")
        mp, rp = pg[g]["avg_pvi"], rc.get("avg_pvi")
        flag = "" if r == pg[g]["points"] else "  <-- DIFF"
        print(f"   {g:10} counting pts mirror {pg[g]['points']:4} real {r if r is not None else '?':>4}   avg_pvi mirror {mp:6} real {rp if rp is not None else '?':>6}{flag}")
        if r is not None and r != pg[g]["points"]: diffs.append(("golfer", g, pg[g]["points"], r))
    print(f"   adjustments (real): {real['adjustments']}")
    print(f"   cup (real): finalists {real['cup_finalists']} champion {real['season']['champion']} score {real['season']['champion_score']} rung {real['season']['tiebreak_rung']!r}")
    print(f"   cup (mirror): seeds {cup.seeds} champion {cup.champion} window pts {cup.final_points}" + (f" via {cup.tiebreak_used}" if cup.tiebreak_used else ""))
    if real.get("payouts") is not None: print(f"   settlement (real): pot/collected {real.get('pot')}  payouts {real['payouts']}")
    return diffs

def monte_carlo(families, n):
    print(f"\n#### Monte Carlo · {n} seeds")
    for fam in families:
        wins = defaultdict(int); pts = defaultdict(list); pen = defaultdict(int); floor_hits = defaultdict(int)
        for seed in range(n):
            G, bylaws, start, end, note, prior, rounds = build(fam, seed)
            scored, lines, table, cup, clash = run_mirror(G, bylaws, start, end, prior, rounds)
            top = max(table, key=lambda s: table[s]); wins[top] += 1
            for g, v in per_golfer(scored, lines).items():
                pts[g].append(v["points"]); pen[g] += v["penalties"]
                floor_hits[g] += sum(1 for ml in lines if g in ml.penalties or g in ml.byes_used or g in ml.forfeits)
        print(f"\n  {fam}: P(squad wins) over {n} seeds = " + ", ".join(f"{s}:{w/n:.2f}" for s, w in sorted(wins.items())))
        for g in pts:
            arr = sorted(pts[g]); mean = sum(arr)/n; sd = (sum((x-mean)**2 for x in arr)/n) ** .5
            print(f"    {g:10} season pts mean {mean:6.1f} sd {sd:5.1f}  p10 {arr[n//10]:4}  p90 {arr[9*n//10]:4}   floor events/season {floor_hits[g]/n:.2f}  total penalties {pen[g]/n:6.1f}")

if __name__ == "__main__":
    args = sys.argv[1:]
    seed = 7
    if "--mc" in args:
        n = int(args[args.index("--mc") + 1]); monte_carlo(["S1_frequency", "S2_handicaps", "S3_squads"], n); sys.exit(0)
    fams = [a for a in args if a in FAMILIES] or list(FAMILIES)
    for fam in fams:
        G, bylaws, start, end, note, prior, rounds = build(fam, seed)
        extra = None
        if fam == "S4_penalties":
            for pen in ("none", "deduct", "forfeit"):
                b2 = copy.copy(bylaws); b2.penalty = pen
                scored, lines, table, cup, clash = run_mirror(G, b2, start, end, prior, copy.deepcopy(rounds))
                print(f"\n   --- penalty = {pen}: squad table {dict(sorted(table.items()))}  penalties {[ {g:p for g,p in ml.penalties.items()} for ml in lines if ml.penalties]}  forfeits {[sorted(ml.forfeits) for ml in lines if ml.forfeits]}")
            continue
        if fam == "S6_edges":
            extra = edits_for_S6(G, rounds, prior, start, end, bylaws)
        scored, lines, table, cup, clash = run_mirror(G, bylaws, start, end, prior, rounds)
        report(fam, seed, G, bylaws, start, end, note, scored, lines, table, cup, clash, extra)
        if "--engine" in args and args[args.index("--engine") + 1] == "real":
            real = run_real(fam, seed, G, bylaws, start, end, prior, rounds)
            diffs = compare(fam, table, per_golfer(scored, lines), cup, real)
            with open(os.path.join(OUT, f"{fam}.real.json"), "w") as f: json.dump({"real": real, "diffs": diffs}, f, indent=1, default=str)
