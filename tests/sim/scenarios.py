"""The seven scenario families the brief asks for, plus a Monte Carlo.
Each returns (golfers, bylaws, start, end, notes)."""
from __future__ import annotations
from datetime import date, timedelta
from golfers import Golfer
from engine_mirror import Bylaws

def _season(weeks: int, start=date(2026, 3, 1)):     # 2026-03-01 is a Sunday
    return start, start + timedelta(days=7 * weeks - 1)

def S1_frequency():
    """Same ability, different frequency. Cap 3, floor 2."""
    # D205/D58: the engine refuses to start a squad season with fewer than four
    # golfers, so the ladder is four: 1 / 2 / 4 / 7 rounds a month.
    g = [Golfer("Ada",  ability=12.0, sigma=3.5, per_month=2, squad="A"),   # infrequent, at the floor
         Golfer("Bo",   ability=12.0, sigma=3.5, per_month=7, squad="B"),   # frequent
         Golfer("Cy",   ability=12.0, sigma=3.5, per_month=1, squad="C"),   # under the floor
         Golfer("Di",   ability=12.0, sigma=3.5, per_month=4, squad="D")]   # weekly
    return g, Bylaws(), *_season(13), "Same golfer four times; only the frequency differs."

def S2_handicaps():
    """Mixed handicaps and variability; same frequency."""
    g = [Golfer("Lo5",  ability=5.0,  sigma=2.5, per_month=4, squad="A"),
         Golfer("Mid15",ability=15.0, sigma=3.5, per_month=4, squad="B"),
         Golfer("Hi25", ability=25.0, sigma=5.0, per_month=4, squad="C"),
         Golfer("Steady15", ability=15.0, sigma=1.5, per_month=4, squad="D")]
    return g, Bylaws(), *_season(13), "Does PvI banding equalise ability? Does variance pay?"

def S3_squads():
    """Unequal squads, a late join after the 15th, absences, byes."""
    g = [Golfer("A1", 14, 3.5, 4, squad="A"), Golfer("A2", 14, 3.5, 4, squad="A"),
         Golfer("A3", 14, 3.5, 4, squad="A"), Golfer("A4", 14, 3.5, 4, squad="A"),
         Golfer("B1", 14, 3.5, 4, squad="B"), Golfer("B2", 14, 3.5, 4, squad="B"),
         Golfer("B3", 14, 3.5, 4, squad="B"),
         Golfer("C1", 14, 3.5, 4, squad="C"), Golfer("C2", 14, 3.5, 4, squad="C"),
         Golfer("C3late", 14, 3.5, 4, squad="C", join_offset_days=19),      # joins Mar 20 (>= 15th)
         Golfer("C4absent", 14, 3.5, 4, squad="C", absent_months=(2, 3))]    # two months out
    s, e = _season(17)   # 17 weeks: Mar 1 - Jun 27 -> Mar, Apr, May full; Jun partial
    return g, Bylaws(), s, e, "4 vs 3 vs 4-with-holes. Sum-not-average is the structural question."

def S4_penalties():
    """Same rounds under none / deduct / forfeit."""
    g = [Golfer("P1", 14, 3.5, 3, squad="A"), Golfer("P2", 14, 3.5, 1, squad="A"),
         Golfer("Q1", 14, 3.5, 3, squad="B"), Golfer("Q2", 14, 3.5, 3, squad="B")]
    s, e = _season(17)
    return g, Bylaws(), s, e, "P2 is a chronic under-floor golfer. Compare the three penalty dials on identical rounds."

def S5_cup():
    """Four squads, the lock, the fresh window, and a non-finalist's awards."""
    g = []
    for sq, ab in (("A", 12), ("B", 14), ("C", 16), ("D", 18)):
        for i in range(3):
            g.append(Golfer(f"{sq}{i+1}", ab, 3.5, 4, squad=sq))
    g.append(Golfer("D4iron", 18, 3.5, 9, squad="D"))   # plays the most: Iron Man on a bottom squad
    s, e = _season(26)   # 26 weeks: Mar 1 - Aug 29; Final window Aug 2 - Aug 29
    return g, Bylaws(), s, e, "Seeds lock 27 days before the end; the window scores fresh."

def S6_edges():
    """Ties, a late post, a void, a correction."""
    g = [Golfer("T1", 14, 3.5, 4, squad="A"), Golfer("T2", 14, 3.5, 4, squad="A"),
         Golfer("U1", 14, 3.5, 4, squad="B"), Golfer("U2", 14, 3.5, 4, squad="B")]
    s, e = _season(13)
    return g, Bylaws(), s, e, "Engineered after generation: see run.py's edits."

def S7_clash():
    g = [Golfer(n, 14, 3.5, 4, squad=sq) for n, sq in (("K1","A"),("K2","A"),("L1","B"),("L2","B"))]
    return g, Bylaws(), *_season(13), "The clash must never move a squad total."

FAMILIES = {"S1_frequency": S1_frequency, "S2_handicaps": S2_handicaps, "S3_squads": S3_squads,
            "S4_penalties": S4_penalties, "S5_cup": S5_cup, "S6_edges": S6_edges, "S7_clash": S7_clash}

# ---------------------------------------------------------------- S8 · a forced tie, and a pot
from golfers import Round, differential_to_gross
def S8_tie_settle():
    """Deterministic: every round has differential 10.0 against a 10.0 index, so
    every round is 7 points and months are won by ROUND COUNT. A wins Mar+Apr,
    B wins May, the June window is identical -> Cup ties on points and the
    §14.3 ladder decides on months_won. $50 buy-in, nobody pays."""
    g = [Golfer(n, 10.0, 0.0, 0, squad=sq) for n, sq in (("A1","A"),("A2","A"),("B1","B"),("B2","B"),("C1","C"),("C2","C"))]
    s, e = _season(17)   # Mar 1 – Jun 27; lock May 31; window May 31 – Jun 27
    b = Bylaws(); b.buyin_cents = 5000
    return g, b, s, e, "Forced Final tie walked down the ladder; an uncollected pot settled."

def _fixed(name, days):
    out = []
    for d in days:
        out.append(Round(name, d, differential_to_gross(10.0), 10.0, d))
    return out

def S8_rounds(G, start, end):
    from datetime import date, timedelta
    prior = {n: _fixed(n, [start - timedelta(days=4*(i+1)) for i in range(20)]) for n in G}
    D = lambda m, d: date(2026, m, d)
    per = {"A": {3: 3, 4: 3, 5: 2, 6: 2}, "B": {3: 2, 4: 2, 5: 3, 6: 2}, "C": {3: 2, 4: 2, 5: 2, 6: 0}}
    rounds = {}
    for n, g in G.items():
        days = []
        for m, k in per[g.squad].items():
            days += [D(m, 3 + 5 * i) for i in range(k)]
        rounds[n] = _fixed(n, days)
    return prior, rounds

FAMILIES["S8_tie_settle"] = S8_tie_settle
EXPLICIT = {"S8_tie_settle": S8_rounds}
