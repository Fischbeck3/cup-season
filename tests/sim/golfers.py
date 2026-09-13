"""Cup Season season simulation — golfer and round generation.

Engine-independent. Produces a deterministic list of posted rounds for a
season from a seeded RNG, so every scenario is reproducible from its seed.

ASSUMPTIONS (synthetic; not evidence of real-world fairness):
- A golfer has a true expected differential (`ability`) and a round-to-round
  standard deviation (`sigma`). Real amateurs vary ~3–4 strokes per round.
- Rounds are drawn independently. No form, weather, course-difficulty or
  learning effects. This is the biggest simplification.
- Frequency is rounds per calendar month, jittered by ±1, never below 0.
- A golfer's INDEX is derived by the engine (mirror or real) from their
  posted differentials; it is not set here. We seed each golfer with a
  history of `history_n` prior rounds so the season starts with an
  established index unless the scenario says otherwise.
"""
from __future__ import annotations
import random
from dataclasses import dataclass, field
from datetime import date, timedelta

RATING, SLOPE = 71.2, 128          # one rated course for every round (APPROX)

@dataclass
class Golfer:
    name: str
    ability: float          # expected differential
    sigma: float            # per-round SD of the differential
    per_month: float        # expected rounds per calendar month
    history_n: int = 20     # prior rounds seeded before the season
    join_offset_days: int = 0   # >0 = late join, days after starts_on
    absent_months: tuple = ()   # month numbers (1-based) with zero rounds
    squad: str = ""
    id: str = ""

@dataclass
class Round:
    golfer: str
    played_on: date
    gross: int
    differential: float
    posted_on: date         # for late-post scenarios; == played_on by default
    voided: bool = False

def differential_to_gross(diff: float) -> int:
    # Differential = (gross - rating) * 113 / slope  =>  gross = diff*slope/113 + rating
    return int(round(diff * SLOPE / 113.0 + RATING))

def gross_to_differential(gross: int) -> float:
    from decimal import Decimal, ROUND_HALF_UP
    return float(Decimal(repr((gross - RATING) * 113.0 / SLOPE)).quantize(Decimal('0.1'), rounding=ROUND_HALF_UP))

def draw_round(rng: random.Random, g: Golfer, on: date) -> Round:
    d = rng.gauss(g.ability, g.sigma)
    gross = differential_to_gross(d)
    return Round(g.name, on, gross, gross_to_differential(gross), on)

def history(rng: random.Random, g: Golfer, before: date) -> list[Round]:
    """Prior rounds, one every ~4 days back from `before`, so the index is
    established (>= 3) or full (20) at season start."""
    out = []
    for i in range(g.history_n):
        on = before - timedelta(days=4 * (i + 1) + rng.randint(0, 2))
        out.append(draw_round(rng, g, on))
    return sorted(out, key=lambda r: r.played_on)

def month_days(start: date, end: date):
    """Yield (month_index_1based, first_day, last_day) for each calendar
    month the season touches, clipped to the season."""
    cur = date(start.year, start.month, 1)
    i = 1
    while cur <= end:
        nxt = date(cur.year + (cur.month // 12), (cur.month % 12) + 1, 1)
        yield i, max(cur, start), min(nxt - timedelta(days=1), end)
        cur = nxt; i += 1

def season_rounds(rng: random.Random, g: Golfer, start: date, end: date) -> list[Round]:
    out = []
    first = start + timedelta(days=g.join_offset_days)
    for mi, a, b in month_days(start, end):
        if mi in g.absent_months: continue
        lo = max(a, first)
        if lo > b: continue
        span = (b - lo).days + 1
        frac = span / ((b - a).days + 1)          # partial month => fewer rounds
        n = max(0, int(round(rng.gauss(g.per_month * frac, 0.8))))
        days = sorted(rng.sample(range(span), min(n, span))) if span > 0 else []
        for d in days:
            out.append(draw_round(rng, g, lo + timedelta(days=d)))
    return out
