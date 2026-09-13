#!/usr/bin/env python3
"""The four analyses Codex asked for, each a number rather than an opinion.

  python3 tests/sim/analysis.py d212        # quantify the Final/calendar-cap clash
  python3 tests/sim/analysis.py attempts    # best-N attempt advantage
  python3 tests/sim/analysis.py floor       # the real default floor on a busy golfer
  python3 tests/sim/analysis.py all

Mirror-only and deliberately so: these measure the RULE, over many seasons.
The rule itself was reconciled against the deployed engine (see the report).
"""
from __future__ import annotations
import os, random, statistics, sys
from datetime import date, timedelta
sys.path.insert(0, os.path.dirname(__file__))
from golfers import Golfer, Round, RATING, SLOPE, gross_to_differential, differential_to_gross
import engine_mirror as E

def _rounds(rng, g, days):
    out = []
    for d in days:
        diff = rng.gauss(g.ability, g.sigma)
        gross = differential_to_gross(diff)
        out.append(Round(g.name, d, gross, gross_to_differential(gross), d))
    return out

# ------------------------------------------------------------------ D212
def d212(trials=4000, cap=3):
    """The lock month is split by the window. A round played BEFORE the window
    but in the same calendar month competes for the same `cap` places.

    Measures, per season: P(a window round is displaced by a pre-window round)
    and the squad points lost versus ranking the window on its own.
    Codex's fixture: lock Nov 3, so Nov 1-2 are the pre-window days."""
    print(f"\n== D212 · a pre-window round holding a monthly place  (cap {cap}, {trials} seasons/row)")
    print("   Nov 1-2 are in the lock month but outside the Nov 3-30 Final window.")
    print(f"   {'pre-window rounds':>18} {'window rounds':>14} {'P(displaced)':>13} {'mean pts lost':>14} {'worst':>6}")
    rng = random.Random(11)
    for pre_n in (0, 1, 2):
        for win_n in (2, 3, 4, 6):
            lost, hits = [], 0
            for _ in range(trials):
                g = Golfer("x", 13.0, 3.2, 0)
                pre = _rounds(rng, g, [date(2026, 11, 1 + i) for i in range(pre_n)])
                win = _rounds(rng, g, [date(2026, 11, 5 + 3 * i) for i in range(win_n)])
                idx = 13.0
                def pts(r): return E.band(E.pvi(idx, 95, r.differential))
                # deployed: rank the WHOLE month, keep window rounds inside the cap
                month = sorted(pre + win, key=lambda r: (-pts(r), r.played_on))[:cap]
                deployed = sum(pts(r) for r in month if r.played_on >= date(2026, 11, 3))
                # "scored fresh": rank the window on its own
                fresh = sum(pts(r) for r in sorted(win, key=lambda r: -pts(r))[:cap])
                d = fresh - deployed
                lost.append(d)
                if d > 0: hits += 1
            if pre_n or win_n > cap:
                print(f"   {pre_n:>18} {win_n:>14} {hits/trials:>12.0%} {statistics.mean(lost):>14.2f} {max(lost):>6}")
    print("   Read: with two pre-window rounds and three in the window, a golfer loses")
    print("   points they visibly earned inside the Final window. 'Scored fresh' is not what happens.")

# -------------------------------------------------------------- attempts
def attempts(trials=6000, cap=3):
    """Best-N caps counted VOLUME but not OPPORTUNITY: more attempts raise the
    expected best-N because the max of more draws is higher. Measured across
    three plausible spreads, at identical ability."""
    print(f"\n== Best-{cap} attempt advantage  ({trials} months per cell, ability 13.0, 95%)")
    rng = random.Random(23)
    print(f"   {'sigma':>6} " + "".join(f"{k:>8}" for k in (3,4,5,6,8,10)) + "   <- rounds attempted in the month")
    for sigma in (2.0, 3.2, 5.0):
        row = []
        for k in (3, 4, 5, 6, 8, 10):
            tot = 0
            for _ in range(trials):
                g = Golfer("x", 13.0, sigma, 0)
                rs = _rounds(rng, g, [date(2026, 9, 1 + i) for i in range(k)])
                p = sorted((E.band(E.pvi(13.0, 95, r.differential)) for r in rs), reverse=True)[:cap]
                tot += sum(p)
            row.append(tot / trials)
        base = row[0]
        print(f"   {sigma:>6} " + "".join(f"{v:>8.1f}" for v in row))
        print(f"   {'  +%':>6} " + "".join(f"{100*(v-base)/base:>7.0f}%" for v in row))
    print("   Read: the cap bounds the COUNT, not the CHANCE. Ten attempts beat three by")
    print("   ~20-30% on the same ability, and the wider the golfer's spread the bigger the gap.")

# ----------------------------------------------------------------- floor
def floor(trials=3000):
    """Codex's fixture has no minimum; Standard has floor 2 and -5 a round
    short, with one auto-bye. What does that cost a golfer who can only play
    once a month, over the same Sep 1 - Nov 30 season?"""
    print(f"\n== The real default floor on a busy golfer  ({trials} seasons, Sep 1 - Nov 30)")
    start, end = date(2026, 9, 1), date(2026, 11, 30)
    rng = random.Random(31)
    print(f"   {'rounds/mo':>10} {'no minimum':>12} {'floor 2 / -5':>14} {'cost':>7} {'months penalised':>17}")
    for rate in (1, 2, 3, 5):
        a_tot, b_tot, pens = [], [], []
        for _ in range(trials):
            g = Golfer("busy", 13.0, 3.2, rate, squad="X")
            G = {"busy": g}
            prior = {"busy": [Round("busy", start - timedelta(days=4*(i+1)), 0, 13.0, start) for i in range(20)]}
            from golfers import season_rounds
            rounds = {"busy": season_rounds(rng, g, start, end)}
            for pen, acc in (("none", a_tot), ("deduct", b_tot)):
                b = E.Bylaws(); b.cap = 3; b.floor = 0 if pen == "none" else 2; b.penalty = pen
                sc = E.score_rounds(rounds, prior, b)
                ln = E.close_months(sc, G, start, end, b)
                acc.append(sum(m.per_golfer_points["busy"] + m.penalties.get("busy", 0) for m in ln))
                if pen == "deduct": pens.append(sum(1 for m in ln if "busy" in m.penalties))
        a, bb = statistics.mean(a_tot), statistics.mean(b_tot)
        print(f"   {rate:>10} {a:>12.1f} {bb:>14.1f} {bb-a:>7.1f} {statistics.mean(pens):>17.2f}")
    print("   Read: Sep 1 - Nov 30 has THREE whole calendar months, so the floor assesses")
    print("   all three. One auto-bye covers the first; the rest bite.")

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    if which in ("d212", "all"): d212()
    if which in ("attempts", "all"): attempts()
    if which in ("floor", "all"): floor()
